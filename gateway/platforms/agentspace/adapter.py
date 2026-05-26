"""
AgentSpace (WPS 数字员工) platform adapter.

WebSocket-based connection to WPS AgentSpace platform.
Protocol: wss://agentspace.wps.cn/v7/devhub/ws/{app_id}/chat
Auth: Cookie wps_sid=<token> + Origin header
"""

from __future__ import annotations

import asyncio
import json
import logging
import os
import time
import uuid
from typing import Any, Dict, Optional

try:
    import aiohttp
    AIOHTTP_AVAILABLE = True
except ImportError:
    AIOHTTP_AVAILABLE = False
    aiohttp = None

from gateway.config import Platform, PlatformConfig
from gateway.platforms.base import (
    BasePlatformAdapter,
    MessageEvent,
    MessageType,
    SendResult,
)

logger = logging.getLogger(__name__)

# ── Constants ────────────────────────────────────────────────────────────────
DEFAULT_WS_URL = "wss://agentspace.wps.cn/v7/devhub/ws/{app_id}/chat"
DEFAULT_ORIGIN = "https://agentspace.wps.cn"
HEARTBEAT_INTERVAL = 10  # seconds
HEARTBEAT_MAX_FAILURES = 3  # consecutive failures before reconnect
RECONNECT_DELAY_BASE = 20.0  # seconds (fixed for first 10 min)
RECONNECT_DELAY_MAX = 3600.0  # 1 hour max
RECONNECT_GIVE_UP = 7 * 24 * 3600  # 7 days

# Server-sent fatal errors (connection should not retry)
FATAL_ERROR_CODES = frozenset({
    "USER_NO_APP_PERMISSION",
    "USER_NO_OPENCLAW_PERMISSION",
    "OPENCLAW_NOT_CONFIGURED",
    "NOT_OPENCLAW_APP",
    "NOT_LOGIN",
})


# ── Requirement check ────────────────────────────────────────────────────────
def check_agentspace_requirements() -> bool:
    return AIOHTTP_AVAILABLE


# ── Adapter ──────────────────────────────────────────────────────────────────
class AgentSpaceAdapter(BasePlatformAdapter):
    """WebSocket adapter for WPS AgentSpace platform."""

    def __init__(self, config: PlatformConfig, platform: Platform):
        super().__init__(config, platform)

        # Load account config
        extra = getattr(config, "extra", {}) or {}
        accounts = extra.get("accounts", {})
        default_account = accounts.get("default", {}) if accounts else {}

        self._app_id = extra.get("app_id", "") or os.getenv("AGENTSPACE_APP_ID", "")
        self._ws_url = extra.get("ws_url", DEFAULT_WS_URL).format(app_id=self._app_id or "openClaw")
        self._origin = extra.get("origin", DEFAULT_ORIGIN)

        # Credentials
        self._wps_sid = default_account.get("wps_sid", "") or os.getenv("WPS_SID", "")
        self._token = default_account.get("token", "")  # AES-256-GCM encrypted (future)

        self._device_uuid = default_account.get("device_uuid", "")
        self._device_name = default_account.get("device_name", "MiLe")
        self._account_id = "default"
        self._accounts = accounts

        # State
        self._ws: Optional[aiohttp.ClientWebSocketResponse] = None
        self._session: Optional[aiohttp.ClientSession] = None
        self._listen_task: Optional[asyncio.Task] = None
        self._heartbeat_task: Optional[asyncio.Task] = None
        self._connecting = False
        self._reconnecting = False
        self._heartbeat_failures = 0
        self._latest_session_id: Optional[str] = None
        self._reconnect_count = 0
        self._first_connect_time: float = 0.0

    @property
    def _log_tag(self) -> str:
        return f"AgentSpace:{self._account_id}"

    # ── connect / disconnect ─────────────────────────────────────────────

    async def connect(self) -> bool:
        """Connect to WPS AgentSpace WebSocket."""
        if not AIOHTTP_AVAILABLE:
            logger.error("%s: aiohttp not available", self._log_tag)
            return False

        if not self._wps_sid:
            logger.error("%s: no wps_sid configured", self._log_tag)
            return False

        if self._connecting:
            logger.warning("%s: connect already in progress", self._log_tag)
            return False

        self._connecting = True
        try:
            success = await self._connect_ws()
            if success:
                self._mark_connected()
                # Start listen loop as separate task
                self._listen_task = asyncio.create_task(self._message_loop())
                self._heartbeat_task = asyncio.create_task(self._heartbeat_loop())
                self._first_connect_time = time.time()
                logger.info("%s: connected (device_uuid=%s)", self._log_tag, self._device_uuid)
            return success
        finally:
            self._connecting = False

    async def _connect_ws(self) -> bool:
        """Establish WebSocket connection and complete handshake. Does NOT enter message loop."""
        # Close old session
        if self._session and not self._session.closed:
            await self._session.close()
        if self._ws and not self._ws.closed:
            await self._ws.close()

        self._session = aiohttp.ClientSession()

        headers = {
            "Origin": self._origin,
            "User-Agent": "Hermes-AgentSpace/1.0",
        }
        cookie_value = f"wps_sid={self._wps_sid}"
        headers["Cookie"] = cookie_value

        try:
            self._ws = await self._session.ws_connect(
                self._ws_url,
                headers=headers,
                heartbeat=None,  # we handle heartbeat ourselves
                timeout=30,
            )
        except Exception as e:
            logger.error("%s: WS connect failed: %s", self._log_tag, e)
            return False

        # Send init
        init_data = {
            "timestamp": int(time.time() * 1000),
            "device_uuid": self._device_uuid,
            "device_name": self._device_name,
            "device_type": "openclaw",
        }
        if self._latest_session_id:
            init_data["session_id"] = self._latest_session_id

        await self._send_event("init", init_data)

        # Wait for init response (max 10s)
        try:
            init_msg = await asyncio.wait_for(self._ws.receive(), timeout=10)
            if init_msg.type == aiohttp.WSMsgType.TEXT:
                init_data_resp = json.loads(init_msg.data)
                event = init_data_resp.get("event", "")
                data = init_data_resp.get("data", {})

                if event == "error":
                    error_code = data.get("code", "")
                    error_msg = data.get("message", "")
                    logger.error("%s: init error: code=%s msg=%s", self._log_tag, error_code, error_msg)
                    if error_code in FATAL_ERROR_CODES:
                        self._fatal_error_code = error_code
                        self._fatal_error_message = error_msg
                        self._fatal_error_retryable = False
                    return False

                # Store device_uuid from server
                server_uuid = data.get("device_uuid", "")
                if server_uuid:
                    self._device_uuid = server_uuid
                    # Write back to account config
                    if self._account_id in self._accounts:
                        self._accounts[self._account_id]["device_uuid"] = server_uuid
                    logger.info("%s: server assigned device_uuid=%s", self._log_tag, server_uuid)

                # Store session_id for resumption
                session_id = data.get("session_id", "")
                if session_id:
                    self._latest_session_id = session_id
        except asyncio.TimeoutError:
            logger.warning("%s: init response timeout", self._log_tag)
        except Exception as e:
            logger.warning("%s: init response error: %s", self._log_tag, e)

        return True

    async def disconnect(self) -> None:
        """Close WebSocket and cleanup."""
        self._running = False

        for task in [self._heartbeat_task, self._listen_task]:
            if task and not task.done():
                task.cancel()
                try:
                    await task
                except asyncio.CancelledError:
                    pass

        if self._ws and not self._ws.closed:
            await self._ws.close()
        if self._session and not self._session.closed:
            await self._session.close()

        self._ws = None
        self._session = None
        self._heartbeat_task = None
        self._listen_task = None

    # ── message loop ──────────────────────────────────────────────────────

    async def _message_loop(self) -> None:
        """Read messages from WebSocket and dispatch."""
        while self._running and self._ws and not self._ws.closed:
            try:
                msg = await self._ws.receive()
            except asyncio.CancelledError:
                break
            except Exception as e:
                if self._running:
                    logger.error("%s: message receive error: %s", self._log_tag, e)
                break

            if msg.type == aiohttp.WSMsgType.TEXT:
                await self._handle_text_message(msg.data)
            elif msg.type == aiohttp.WSMsgType.CLOSE:
                logger.info("%s: WS close frame received (code=%s)", self._log_tag, msg.data)
                break
            elif msg.type == aiohttp.WSMsgType.CLOSED:
                logger.info("%s: WS closed", self._log_tag)
                break
            elif msg.type == aiohttp.WSMsgType.ERROR:
                logger.error("%s: WS error: %s", self._log_tag, self._ws.exception())
                break

        # Connection lost — schedule reconnect
        if self._running:
            await self._schedule_reconnect()

    async def _handle_text_message(self, raw: str) -> None:
        """Parse and dispatch an inbound text message."""
        try:
            parsed = json.loads(raw)
        except json.JSONDecodeError:
            logger.warning("%s: invalid JSON: %s", self._log_tag, raw[:200])
            return

        event = parsed.get("event", "")
        data = parsed.get("data", {})

        logger.info("%s: <<< %s", self._log_tag, json.dumps(parsed, ensure_ascii=False))

        if event == "ping":
            # Respond with pong to keep connection alive
            await self._send_event("pong", {
                "timestamp": int(time.time() * 1000),
                "device_uuid": self._device_uuid,
            })
            return

        if event == "pong":
            # Server pong — reset heartbeat failures
            self._heartbeat_failures = 0
            return

        if event == "error":
            error_code = data.get("code", "")
            error_msg = data.get("message", "")
            logger.error("%s: server error: code=%s msg=%s", self._log_tag, error_code, error_msg)
            if error_code in FATAL_ERROR_CODES:
                self._fatal_error_code = error_code
                self._fatal_error_message = error_msg
                self._fatal_error_retryable = False
                await self.disconnect()
            return

        if event == "init_resp":
            # Already handled in _connect_ws
            return

        if event == "message":
            await self._handle_message_event(data)
            return

        logger.debug("%s: unhandled event=%s keys=%s", self._log_tag, event, list(data.keys()))

    async def _handle_message_event(self, data: Dict[str, Any]) -> None:
        """Handle an inbound message event from AgentSpace."""
        content = data.get("content", "")
        if not content:
            content_list = data.get("content_list", [])
            for item in content_list:
                if item.get("type") == "text":
                    content = item.get("text", "")
                    break

        if not content:
            return

        # Use xzim.account_id as stable user identifier
        xzim = data.get("xzim", {}) or {}
        account_id = str(xzim.get("account_id", "")) if xzim else ""
        chat_id = account_id or data.get("chat_id", data.get("session_id", "default"))

        event = MessageEvent(
            platform=self.platform,
            chat_id=chat_id,
            user_id=account_id or chat_id,
            text=content,
            message_type=MessageType.TEXT,
            raw=data,
        )

        await self.handle_message(event)

    # ── heartbeat ─────────────────────────────────────────────────────────

    async def _heartbeat_loop(self) -> None:
        """Send periodic heartbeat pings to keep WS alive."""
        while self._running and self._ws and not self._ws.closed:
            await asyncio.sleep(HEARTBEAT_INTERVAL)
            if not self._running or not self._ws or self._ws.closed:
                break

            try:
                await self._send_event("ping", {
                    "timestamp": int(time.time() * 1000),
                    "device_uuid": self._device_uuid,
                })
                self._heartbeat_failures = 0
            except Exception as e:
                self._heartbeat_failures += 1
                logger.warning("%s: heartbeat failed (%d/%d): %s",
                               self._log_tag, self._heartbeat_failures, HEARTBEAT_MAX_FAILURES, e)

                if self._heartbeat_failures >= HEARTBEAT_MAX_FAILURES:
                    logger.error("%s: heartbeat dead — triggering reconnect", self._log_tag)
                    # Force close to trigger reconnect
                    if self._ws and not self._ws.closed:
                        await self._ws.close()
                    if not self._reconnecting:
                        await self._schedule_reconnect()
                    break

    # ── reconnect ──────────────────────────────────────────────────────────

    async def _schedule_reconnect(self) -> None:
        """Schedule reconnection after connection loss."""
        if self._reconnecting:
            return

        self._reconnecting = True
        try:
            # Cancel old listen/heartbeat tasks
            for task in [self._listen_task, self._heartbeat_task]:
                if task and not task.done():
                    task.cancel()

            while self._running:
                self._reconnect_count += 1

                # Give up after 7 days
                elapsed = time.time() - self._first_connect_time if self._first_connect_time else 0
                if elapsed > RECONNECT_GIVE_UP:
                    logger.error("%s: reconnect give-up after %d days", self._log_tag, RECONNECT_GIVE_UP // 86400)
                    break

                # Fixed 20s for first 10 min, then exponential backoff
                if self._reconnect_count <= 30:  # 30 * 20s = 10 min
                    delay = RECONNECT_DELAY_BASE
                else:
                    delay = min(RECONNECT_DELAY_BASE * (2 ** (self._reconnect_count - 30)), RECONNECT_DELAY_MAX)

                logger.info("%s: reconnect #%d in %.1fs", self._log_tag, self._reconnect_count, delay)
                await asyncio.sleep(delay)

                if not self._running:
                    break

                if await self._connect_ws():
                    self._mark_connected()
                    self._reconnect_count = 0
                    self._heartbeat_failures = 0
                    self._listen_task = asyncio.create_task(self._message_loop())
                    self._heartbeat_task = asyncio.create_task(self._heartbeat_loop())
                    logger.info("%s: reconnected", self._log_tag)
                    break
        finally:
            self._reconnecting = False

    # ── send ───────────────────────────────────────────────────────────────

    async def _send_event(self, event: str, data: Dict[str, Any]) -> None:
        """Send a JSON event over WebSocket."""
        if not self._ws or self._ws.closed:
            raise ConnectionError("WebSocket not connected")
        payload = json.dumps({"event": event, "data": data}, ensure_ascii=False)
        await self._ws.send_str(payload)

    async def send(
        self,
        chat_id: str,
        content: str,
        reply_to_message_id: Optional[str] = None,
        **kwargs,
    ) -> SendResult:
        """Send a text message to the AgentSpace chat."""
        event_data = {
            "content": content,
            "timestamp": int(time.time() * 1000),
            "device_uuid": self._device_uuid,
        }
        if reply_to_message_id:
            event_data["reply_to"] = reply_to_message_id

        try:
            await self._send_event("message_response", event_data)
            logger.debug("%s: >>> %s", self._log_tag, content[:100])
            msg_id = str(uuid.uuid4())
            return SendResult(success=True, message_id=msg_id)
        except Exception as e:
            logger.error("%s: send failed: %s", self._log_tag, e)
            return SendResult(success=False, error=str(e))

    async def send_image(
        self,
        chat_id: str,
        image_path: str,
        caption: Optional[str] = None,
        **kwargs,
    ) -> SendResult:
        """Send an image — AgentSpace doesn't support native image upload via WS.
        Falls back to a text message with file path."""
        msg = caption or f"[图片: {image_path}]"
        return await self.send(chat_id, msg)

    # ── metadata ───────────────────────────────────────────────────────────

    @staticmethod
    def platform_name() -> str:
        return "agentspace"

    @staticmethod
    def display_name() -> str:
        return "AgentSpace (WPS 数字员工)"
