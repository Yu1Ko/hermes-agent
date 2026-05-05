"""
Agentspace Platform Adapter for Hermes Agent.

Connects to WPS Agentspace (agentspace.wps.cn) via WebSocket.
Handles authentication, heartbeat, message relay, and reconnection.

Configuration in config.yaml::

    platforms:
      agentspace:
        enabled: true
        extra:
          wps_sid: "<your wps_sid token>"
          app_id: ""                 # optional custom app_id
          device_uuid: ""            # auto-generated if empty
          device_name: "Hermes"      # display name

Or encrypted token format (preferred)::

    platforms:
      agentspace:
        enabled: true
        extra:
          token: "<encrypted wps_sid>"
          app_id: ""
"""

from __future__ import annotations

import asyncio
import json
import logging
import random
import time
import uuid
from typing import Any, Dict, Optional

import aiohttp

from gateway.config import PlatformConfig, Platform
from gateway.platforms.base import (
    BasePlatformAdapter,
    MessageEvent,
    MessageType,
    SendResult,
)
from gateway.session import SessionSource

from .constants import (
    CONNECT_TIMEOUT,
    DEFAULT_WS_URL,
    EVENT_ERROR,
    EVENT_INIT,
    EVENT_MESSAGE,
    EVENT_PING,
    FATAL_ERROR_CODES,
    HEARTBEAT_INTERVAL,
    ORIGIN,
    RECONNECT_BASE,
    RECONNECT_FIXED_INTERVAL,
    RECONNECT_FIXED_PHASE_SEC,
    RECONNECT_GIVE_UP,
    RECONNECT_MAX,
    WS_URL_BASE,
)
from .crypto import decrypt_wps_sid

logger = logging.getLogger(__name__)


# ── Adapter class ─────────────────────────────────────────────────────────


class AgentspaceAdapter(BasePlatformAdapter):
    """WebSocket adapter for WPS Agentspace platform."""

    SUPPORTS_MESSAGE_EDITING = False  # QQ-style: no edit support
    SUPPORTS_TYPING_INDICATOR = False

    def __init__(self, config: PlatformConfig, platform: Platform):
        super().__init__(config, platform)
        extra = getattr(config, "extra", {}) or {}

        # Resolve wps_sid: prefer encrypted token, fall back to plaintext
        self._app_id = extra.get("app_id", "") or ""
        token = extra.get("token", "")
        wps_sid_plain = extra.get("wps_sid", "")
        if token:
            try:
                self._wps_sid = decrypt_wps_sid(token, self._app_id)
                logger.info("[Agentspace] Decrypted wps_sid from token")
            except Exception as e:
                logger.warning("[Agentspace] Failed to decrypt token, trying plain wps_sid: %s", e)
                self._wps_sid = wps_sid_plain
        else:
            self._wps_sid = wps_sid_plain

        self._device_uuid = extra.get("device_uuid", "") or str(uuid.uuid4())
        self._device_name = extra.get("device_name", "") or "Hermes"
        self._ws_url = self._build_ws_url()

        # Runtime state
        self._ws: Optional[aiohttp.ClientWebSocketResponse] = None
        self._session: Optional[aiohttp.ClientSession] = None
        self._heartbeat_task: Optional[asyncio.Task] = None
        self._reconnect_task: Optional[asyncio.Task] = None
        self._reconnect_attempt = 0
        self._backoff_attempt = 0
        self._reconnect_started_at = 0.0
        self._permanent_close = False

    # ── URL builder ──────────────────────────────────────────────────────

    def _build_ws_url(self) -> str:
        if self._app_id:
            return f"{WS_URL_BASE}/{self._app_id}/chat"
        return DEFAULT_WS_URL

    # ── Connection ───────────────────────────────────────────────────────

    async def connect(self) -> bool:
        """Establish WebSocket connection to Agentspace."""
        if not self._wps_sid:
            logger.error("[Agentspace] Cannot connect: wps_sid not configured")
            self._fatal_error_message = "wps_sid not configured"
            self._fatal_error_code = "NO_WPS_SID"
            self._fatal_error_retryable = False
            return False

        logger.info("[Agentspace] Connecting to %s", self._ws_url)

        try:
            await self._connect_ws()
            self._mark_connected()
            logger.info("[Agentspace] Connected successfully")
            return True
        except Exception as e:
            logger.error("[Agentspace] Connection failed: %s", e)
            return False

    async def _connect_ws(self) -> None:
        """Create WebSocket and perform init handshake."""
        self._session = aiohttp.ClientSession()
        ws = await self._session.ws_connect(
            self._ws_url,
            headers={
                "Cookie": f"wps_sid={self._wps_sid}",
                "Origin": ORIGIN,
                "User-Agent": "Hermes/Agentspace",
            },
            timeout=aiohttp.ClientTimeout(total=CONNECT_TIMEOUT),
        )
        self._ws = ws

        # Send init
        await self._send_json(EVENT_INIT, {
            "timestamp": int(time.time() * 1000),
            "device_uuid": self._device_uuid,
            "device_name": self._device_name,
        })

        # Start heartbeat
        self._heartbeat_task = asyncio.create_task(self._heartbeat_loop())

        # Start message receiver
        asyncio.create_task(self._receive_loop())

    # ── Heartbeat ────────────────────────────────────────────────────────

    async def _heartbeat_loop(self) -> None:
        """Send ping every HEARTBEAT_INTERVAL seconds."""
        while self._running:
            try:
                await asyncio.sleep(HEARTBEAT_INTERVAL)
                if not self._running or not self._ws:
                    break
                if self._ws.closed:
                    break
                await self._send_json(EVENT_PING, {
                    "device_uuid": self._device_uuid,
                    "device_name": self._device_name,
                    "timestamp": int(time.time() * 1000),
                })
            except asyncio.CancelledError:
                break
            except Exception:
                pass

    # ── Receive ──────────────────────────────────────────────────────────

    async def _receive_loop(self) -> None:
        """Receive and dispatch WebSocket messages."""
        while self._running and self._ws:
            try:
                msg = await self._ws.receive()

                if msg.type == aiohttp.WSMsgType.TEXT:
                    await self._handle_raw(msg.data)
                elif msg.type == aiohttp.WSMsgType.CLOSED:
                    logger.info("[Agentspace] WebSocket closed by server")
                    break
                elif msg.type == aiohttp.WSMsgType.ERROR:
                    logger.error("[Agentspace] WebSocket error: %s", self._ws.exception())
                    break
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error("[Agentspace] Receive error: %s", e)
                break

        # Connection lost — schedule reconnect
        if self._running and not self._permanent_close:
            self._schedule_reconnect("close")

    async def _handle_raw(self, raw: str) -> None:
        """Parse and dispatch a raw JSON message from the server."""
        try:
            msg = json.loads(raw)
        except json.JSONDecodeError:
            return

        event = msg.get("event", "")
        data = msg.get("data", {})

        if event == EVENT_INIT:
            server_device_uuid = data.get("device_uuid", "")
            if server_device_uuid and not self._device_uuid:
                self._device_uuid = server_device_uuid
                logger.info("[Agentspace] Received device_uuid from server: %s", server_device_uuid)

        elif event == EVENT_ERROR:
            code = data.get("code", "")
            if code in FATAL_ERROR_CODES:
                logger.error("[Agentspace] Fatal error: %s", code)
                self._permanent_close = True
                self._fatal_error_code = code
                self._fatal_error_message = f"Server returned fatal error: {code}"
                self._fatal_error_retryable = False
                await self._close_ws()
            else:
                logger.warning("[Agentspace] Server error: %s", code)

        elif event == EVENT_MESSAGE:
            role = data.get("role", "user")
            content = data.get("content", "")
            if not content:
                return
            chat_id = data.get("chat_id", "default")
            session_id = data.get("session_id", "") or chat_id
            message_id = data.get("message_id", "")

            logger.info(
                "[Agentspace] Inbound: role=%s chat=%s content=%s",
                role, chat_id, content[:80],
            )

            # Build MessageEvent and dispatch
            msg_event = MessageEvent(
                platform="agentspace",
                chat_id=chat_id,
                chat_name=f"Agentspace:{chat_id}",
                chat_type="direct",
                user_id=chat_id,
                user_name=role,
                text=content,
                message_id=message_id,
                message_type=MessageType.TEXT,
                timestamp=int(time.time()),
                raw_payload={"session_id": session_id},
            )
            if self._message_handler:
                try:
                    await self._message_handler(msg_event)
                except Exception as e:
                    logger.error("[Agentspace] Message handler error: %s", e)

    # ── Send ─────────────────────────────────────────────────────────────

    async def send(self, chat_id: str, message: str, **kwargs) -> SendResult:
        """Send a text message to Agentspace."""
        if not self._ws or self._ws.closed:
            logger.warning("[Agentspace] Cannot send: WebSocket not connected")
            return SendResult(success=False, message_id="")

        try:
            session_id = kwargs.get("session_id", "")
            message_id = kwargs.get("message_id", "")

            await self._send_json(EVENT_MESSAGE, {
                "role": "assistant",
                "type": "answer",
                "content": message,
                "session_id": session_id or "",
                "chat_id": chat_id,
                "message_id": message_id or "",
                "timestamp": int(time.time() * 1000),
                "device_uuid": self._device_uuid,
                "device_name": self._device_name,
            })
            return SendResult(success=True, message_id=message_id or f"sent_{int(time.time())}")
        except Exception as e:
            logger.error("[Agentspace] Send error: %s", e)
            return SendResult(success=False, message_id="")

    async def _send_json(self, event: str, data: Dict[str, Any]) -> None:
        """Send a JSON-formatted event over WebSocket."""
        if not self._ws or self._ws.closed:
            return
        payload = json.dumps({"event": event, "data": data}, ensure_ascii=False)
        await self._ws.send_str(payload)

    # ── Reconnection ─────────────────────────────────────────────────────

    def _schedule_reconnect(self, reason: str) -> None:
        """Schedule a reconnection attempt."""
        if not self._running or self._permanent_close:
            return

        now = time.time()
        if not self._reconnect_started_at:
            self._reconnect_started_at = now

        elapsed = now - self._reconnect_started_at
        if elapsed >= RECONNECT_GIVE_UP:
            logger.warning("[Agentspace] Giving up after 7 days of reconnection attempts")
            self._permanent_close = True
            return

        self._reconnect_attempt += 1
        delay = self._get_backoff_delay()

        logger.info(
            "[Agentspace] Scheduling reconnect #%d in %.1fs (reason: %s)",
            self._reconnect_attempt, delay, reason,
        )

        if self._reconnect_task and not self._reconnect_task.done():
            self._reconnect_task.cancel()
        self._reconnect_task = asyncio.create_task(self._do_reconnect(delay))

    def _get_backoff_delay(self) -> float:
        """Calculate reconnection delay with jitter."""
        elapsed = time.time() - self._reconnect_started_at

        if elapsed < RECONNECT_FIXED_PHASE_SEC:
            return RECONNECT_FIXED_INTERVAL

        self._backoff_attempt += 1
        delay = min(
            RECONNECT_BASE * (2 ** self._backoff_attempt),
            RECONNECT_MAX,
        )
        # ±20% jitter
        jitter = 0.8 + random.random() * 0.4
        return delay * jitter

    async def _do_reconnect(self, delay: float) -> None:
        """Wait and then reconnect."""
        try:
            await asyncio.sleep(delay)
            if not self._running or self._permanent_close:
                return
            logger.info("[Agentspace] Attempting reconnect...")
            await self._close_ws()
            await self._connect_ws()
            logger.info("[Agentspace] Reconnected successfully")
            self._reconnect_attempt = 0
            self._backoff_attempt = 0
            self._reconnect_started_at = 0
        except asyncio.CancelledError:
            pass
        except Exception as e:
            logger.error("[Agentspace] Reconnect failed: %s", e)

    # ── Cleanup ──────────────────────────────────────────────────────────

    async def _close_ws(self) -> None:
        """Clean up WebSocket and heartbeat."""
        if self._heartbeat_task and not self._heartbeat_task.done():
            self._heartbeat_task.cancel()
            self._heartbeat_task = None

        if self._ws and not self._ws.closed:
            try:
                await self._ws.close()
            except Exception:
                pass

        if self._session and not self._session.closed:
            try:
                await self._session.close()
            except Exception:
                pass

        self._ws = None
        self._session = None

    async def disconnect(self) -> None:
        """Disconnect from Agentspace."""
        self._running = False
        self._permanent_close = True

        if self._reconnect_task and not self._reconnect_task.done():
            self._reconnect_task.cancel()
            self._reconnect_task = None

        await self._close_ws()
        logger.info("[Agentspace] Disconnected")

    # ── Platform info ────────────────────────────────────────────────────

    async def get_chat_info(self, chat_id: str) -> Dict[str, Any]:
        """Get information about a chat."""
        return {
            "name": f"Agentspace:{chat_id}",
            "type": "direct",
            "id": chat_id,
        }

    def get_source_info(self, chat_id: str, user_name: str = "") -> SessionSource:
        """Build SessionSource for routing."""
        return SessionSource(
            platform="agentspace",
            chat_id=chat_id,
            chat_name=f"Agentspace:{chat_id}",
            chat_type="direct",
            user_id=chat_id,
            user_name=user_name or "Agentspace User",
        )


# ── Plugin registration ──────────────────────────────────────────────────


def check_requirements() -> bool:
    """Check if aiohttp is available."""
    try:
        import aiohttp  # noqa: F401
        return True
    except ImportError:
        return False


def register(ctx):
    """Register the Agentspace adapter with the Hermes gateway.

    Called by the plugin loader when the plugin is enabled.
    """
    ctx.register_platform(
        name="agentspace",
        label="Agentspace (数字员工开发平台)",
        adapter_factory=lambda cfg: AgentspaceAdapter(cfg, cfg.platform),
        check_fn=check_requirements,
        required_env=[],
        install_hint="pip install aiohttp",
        emoji="🔗",
        platform_hint="WPS 数字员工开发平台。用户通过 agentspace.wps.cn 连接。",
        blurb="WPS 数字员工开发平台，通过 WebSocket 连接。",
    )

    logger.info("[Agentspace] Platform registered")
