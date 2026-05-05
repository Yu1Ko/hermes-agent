"""
AgentSpace platform adapter for WPS 数字员工开发平台.

Connects to AgentSpace WebSocket Gateway for inbound/outbound messaging.
Uses wps_sid cookie for authentication, with AES-256-GCM encrypted token support.

Config in config.yaml:
    platforms:
      agentspace:
        enabled: true
        extra:
          app_id: "your-app-id"           # optional, or env AGENTSPACE_APP_ID
          accounts:
            default:
              token: "encrypted_wps_sid"   # AES-256-GCM encrypted, or plain wps_sid
              device_uuid: "..."
              device_name: "MiLe"
"""

from __future__ import annotations

import asyncio
import json
import logging
import os
import time
from datetime import datetime, timezone
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

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

DEFAULT_WS_URL = "wss://agentspace.wps.cn/v7/devhub/ws/openClaw/chat"
HEARTBEAT_INTERVAL = 10  # seconds
RECONNECT_FIXED_PHASE_MS = 10 * 60 * 1000  # 10 min of fixed-interval reconnects
RECONNECT_FIXED_INTERVAL_MS = 20_000  # 20s in fixed phase
RECONNECT_BASE_MS = 5_000  # base for exponential backoff
RECONNECT_MAX_MS = 60 * 60 * 1000  # max 1 hour
RECONNECT_GIVE_UP_MS = 7 * 24 * 60 * 60 * 1000  # 7 days
FATAL_ERROR_CODES = {
    "USER_NO_APP_PERMISSION",
    "USER_NO_OPENCLAW_PERMISSION",
    "OPENCLAW_NOT_CONFIGURED",
    "NOT_OPENCLAW_APP",
    "NOT_LOGIN",
}

# ---------------------------------------------------------------------------
# Requirement check
# ---------------------------------------------------------------------------


def check_agentspace_requirements() -> bool:
    """Check if AgentSpace runtime dependencies are available."""
    return AIOHTTP_AVAILABLE


# ---------------------------------------------------------------------------
# Crypto helpers (minimal AES-256-GCM decryption for wps_sid tokens)
# ---------------------------------------------------------------------------

def _derive_key(source: str, salt: bytes) -> bytes:
    """Derive a 32-byte AES key via scrypt."""
    import hashlib
    return hashlib.scrypt(
        source.encode("utf-8"), salt=salt, n=16384, r=8, p=1, dklen=32
    )


def _decrypt_wps_sid(encrypted: str, app_id: Optional[str] = None) -> str:
    """Decrypt an AES-256-GCM encrypted wps_sid token.

    Format: hex_salt:hex_iv:hex_auth_tag:hex_ciphertext
    """
    from cryptography.hazmat.primitives.ciphers.aead import AESGCM

    default_source = "openclaw_agentspace"
    source = app_id if app_id else default_source

    parts = encrypted.split(":")
    if len(parts) != 4:
        # Not encrypted — return as plain text
        return encrypted

    try:
        salt = bytes.fromhex(parts[0])
        iv = bytes.fromhex(parts[1])
        auth_tag = bytes.fromhex(parts[2])
        ciphertext = bytes.fromhex(parts[3])

        key = _derive_key(source, salt)
        aesgcm = AESGCM(key)
        plaintext = aesgcm.decrypt(iv, ciphertext + auth_tag, None)
        return plaintext.decode("utf-8")
    except Exception as e:
        logger.warning("Failed to decrypt wps_sid: %s", e)
        return encrypted  # fall back to plain text


# ---------------------------------------------------------------------------
# AgentSpaceAdapter
# ---------------------------------------------------------------------------


class AgentSpaceAdapter(BasePlatformAdapter):
    """AgentSpace WebSocket adapter for WPS 数字员工开发平台."""

    SUPPORTS_MESSAGE_EDITING = False
    MAX_MESSAGE_LENGTH = 4000

    @property
    def _log_tag(self) -> str:
        return f"AgentSpace:{self._account_id}"

    def __init__(self, config: PlatformConfig):
        super().__init__(config, Platform.AGENTSPACE)

        extra = config.extra or {}
        self._app_id = str(extra.get("app_id") or os.getenv("AGENTSPACE_APP_ID", "")).strip()
        self._accounts = extra.get("accounts", {}) or {}
        self._account_id = extra.get("_account_id", "default")

        # Resolve account config
        account = self._accounts.get(self._account_id, {})
        self._token = str(account.get("token") or os.getenv("AGENTSPACE_TOKEN", "")).strip()
        self._wps_sid_raw = str(account.get("wps_sid") or os.getenv("WPS_SID", "")).strip()
        self._device_uuid = str(account.get("device_uuid", "")).strip()
        self._device_name = str(account.get("device_name", "MiLe")).strip()

        # Resolve wps_sid: prefer encrypted token, fall back to plain
        wps_sid = ""
        if self._token:
            wps_sid = _decrypt_wps_sid(self._token, self._app_id)
        if not wps_sid and self._wps_sid_raw:
            wps_sid = self._wps_sid_raw
        self._wps_sid = wps_sid

        # WebSocket URL
        if self._app_id:
            self._ws_url = f"wss://agentspace.wps.cn/v7/devhub/ws/{self._app_id}/chat"
        else:
            self._ws_url = DEFAULT_WS_URL

        # Connection state
        self._session: Optional[aiohttp.ClientSession] = None
        self._ws: Optional[aiohttp.ClientWebSocketResponse] = None
        self._listen_task: Optional[asyncio.Task] = None
        self._heartbeat_task: Optional[asyncio.Task] = None
        self._reconnect_task: Optional[asyncio.Task] = None
        self._running = False
        self._permanent_close = False
        self._connecting = False  # Guard against overlapping connects
        self._reconnecting = False  # Guard against overlapping reconnect schedules

        # Reconnection tracking
        self._reconnect_attempts = 0
        self._backoff_attempts = 0
        self._reconnect_started_at: float = 0

        # Heartbeat health tracking
        self._heartbeat_failures = 0
        self._max_heartbeat_failures = 3  # trigger reconnect after this many consecutive failures

        # Inbound message context cache
        self._latest_chat_id: Optional[str] = None
        self._latest_session_id: Optional[str] = None
        self._latest_message_id: Optional[str] = None

    # ------------------------------------------------------------------
    # connect / disconnect
    # ------------------------------------------------------------------

    async def connect(self) -> bool:
        if not self._wps_sid:
            logger.error("%s: wps_sid not configured", self._log_tag)
            return False

        self._running = True
        self._permanent_close = False
        try:
            await self._connect_ws()
        except Exception as e:
            logger.error("%s: initial connection failed: %s", self._log_tag, e)
            self._running = False
            return False

        self._listen_task = asyncio.create_task(self._message_loop())
        logger.info("%s: connected to %s", self._log_tag, self._ws_url)
        return True

    async def disconnect(self):
        self._running = False
        self._permanent_close = True

        if self._heartbeat_task:
            self._heartbeat_task.cancel()
            self._heartbeat_task = None
        if self._listen_task:
            self._listen_task.cancel()
            self._listen_task = None

        await self._close_ws()
        logger.info("%s: disconnected", self._log_tag)

    # ------------------------------------------------------------------
    # Core WebSocket
    # ------------------------------------------------------------------

    async def _connect_ws(self):
        """Create WebSocket, send init, start heartbeat.
        
        Returns after establishing the connection; does NOT enter the message loop.
        The caller must start _message_loop() separately.
        """
        if self._connecting:
            logger.debug("%s: connect already in progress, skipping", self._log_tag)
            return
        self._connecting = True
        try:
            if self._session is None or self._session.closed:
                self._session = aiohttp.ClientSession()

            # Connect
            origin = self._resolve_origin()
            headers = {
                "Cookie": f"wps_sid={self._wps_sid}",
                "Origin": origin,
                "User-Agent": "Hermes/AgentSpace",
            }
            self._ws = await self._session.ws_connect(self._ws_url, headers=headers)
            logger.info("%s: WebSocket opened", self._log_tag)

            # Send init — include session_id on reconnect for session resumption
            init_data = {
                "timestamp": int(time.time() * 1000),
                "device_uuid": self._device_uuid,
                "device_name": self._device_name,
                "device_type": "openclaw",
            }
            if self._latest_session_id:
                init_data["session_id"] = self._latest_session_id
            await self._send_event("init", init_data)

            # Start heartbeat
            if self._heartbeat_task:
                self._heartbeat_task.cancel()
                self._heartbeat_task = None
            self._heartbeat_task = asyncio.create_task(self._heartbeat_loop())

            # Reset reconnect state on successful connection
            self._reconnect_attempts = 0
            self._backoff_attempts = 0
            self._reconnect_started_at = 0
        finally:
            self._connecting = False

    async def _message_loop(self):
        """Read messages from WebSocket until closed."""
        if not self._ws or self._ws.closed:
            logger.debug("%s: _message_loop: no active WS, exiting", self._log_tag)
            return
        try:
            async for msg in self._ws:
                if msg.type == aiohttp.WSMsgType.TEXT:
                    try:
                        await self._handle_text_message(msg.data)
                    except Exception as e:
                        logger.error("%s: message handler error: %s", self._log_tag, e)
                elif msg.type == aiohttp.WSMsgType.CLOSED:
                    logger.info("%s: WS closed by server", self._log_tag)
                    break
                elif msg.type == aiohttp.WSMsgType.CLOSE:
                    logger.info("%s: WS close frame received (code=%s)", self._log_tag, msg.data)
                    break
                elif msg.type == aiohttp.WSMsgType.ERROR:
                    logger.error("%s: WS error", self._log_tag)
                    break
        except asyncio.CancelledError:
            pass
        except Exception as e:
            logger.error("%s: message loop error: %s", self._log_tag, e)

        # Cleanup and maybe reconnect
        await self._on_close()

    async def _handle_text_message(self, raw: str):
        """Parse JSON and dispatch inbound messages."""
        try:
            parsed = json.loads(raw)
        except json.JSONDecodeError:
            logger.debug("%s: unparseable message: %s", self._log_tag, raw[:200])
            return

        logger.debug("%s: <<< %s", self._log_tag, json.dumps(parsed, ensure_ascii=False)[:500])

        event = parsed.get("event", "")
        data = parsed.get("data", {})
        logger.debug("%s: event=%s keys=%s", self._log_tag, repr(event), list(data.keys())[:5])

        if event == "init":
            # Server may assign device_uuid and/or return session_id
            server_uuid = data.get("device_uuid")
            if server_uuid:
                self._device_uuid = server_uuid
                # Persist to account config so it survives adapter restarts
                if self._account_id in self._accounts:
                    self._accounts[self._account_id]["device_uuid"] = server_uuid
                logger.info("%s: server assigned device_uuid=%s", self._log_tag, server_uuid)
            server_session_id = data.get("session_id")
            if server_session_id:
                self._latest_session_id = server_session_id
                logger.info("%s: server returned session_id=%s", self._log_tag, server_session_id)
        elif event == "error":
            code = data.get("code", "")
            if code in FATAL_ERROR_CODES:
                logger.error("%s: fatal error code=%s, disconnecting permanently", self._log_tag, code)
                self._permanent_close = True
            else:
                logger.warning("%s: server error code=%s", self._log_tag, code)
        elif event == "ping":
            # Respond to server ping with pong to keep connection alive
            logger.debug("%s: server ping received, sending pong", self._log_tag)
            try:
                await self._send_event("pong", {
                    "timestamp": int(time.time() * 1000),
                    "device_uuid": self._device_uuid,
                    "device_name": self._device_name,
                })
            except Exception:
                pass
        elif event == "message":
            role = data.get("role", "user")
            content = data.get("content", "")
            logger.debug("%s: role=%s content_len=%d", self._log_tag, role, len(content))
            # Skip echoed assistant messages to prevent loop
            if role == "assistant":
                logger.debug("%s: skipping echoed assistant message", self._log_tag)
                return
            if not content:
                logger.debug("%s: empty content, skipping", self._log_tag)
                return

            chat_id = data.get("chat_id", data.get("session_id", "default"))
            message_id = data.get("message_id", "")
            session_id = data.get("session_id", "")

            # Cache context for outbound
            self._latest_chat_id = chat_id
            self._latest_session_id = session_id
            self._latest_message_id = message_id

            # Build MessageEvent and dispatch
            event_obj = MessageEvent(
                source=self.build_source(
                    chat_id=chat_id,
                    user_id=chat_id,
                    chat_type="direct",
                ),
                text=content,
                message_type=MessageType.TEXT,
                raw_message=data,
                message_id=message_id,
            )
            await self.handle_message(event_obj)
            logger.debug("%s: message dispatched chat=%s", self._log_tag, chat_id)

        else:
            logger.debug("%s: unhandled event=%s", self._log_tag, repr(event))

    async def _on_close(self):
        """Handle WebSocket close, restart loop if not permanent."""
        if self._heartbeat_task:
            self._heartbeat_task.cancel()
            self._heartbeat_task = None

        if self._ws and not self._ws.closed:
            await self._ws.close()
        self._ws = None

        if not self._permanent_close:
            await self._schedule_reconnect()

    async def _schedule_reconnect(self):
        """Schedule reconnection with backoff."""
        if not self._running or self._permanent_close:
            return
        if self._reconnecting:
            logger.debug("%s: reconnect already scheduled, skipping", self._log_tag)
            return
        self._reconnecting = True

        try:
            if self._reconnect_started_at == 0:
                self._reconnect_started_at = time.time() * 1000

            elapsed = time.time() * 1000 - self._reconnect_started_at
            if elapsed >= RECONNECT_GIVE_UP_MS:
                logger.warning("%s: reconnect stopped after 7 days", self._log_tag)
                self._permanent_close = True
                return

            self._reconnect_attempts += 1

            # Calculate delay
            if elapsed < RECONNECT_FIXED_PHASE_MS:
                delay = RECONNECT_FIXED_INTERVAL_MS / 1000
            else:
                self._backoff_attempts += 1
                delay = min(RECONNECT_BASE_MS * (2 ** (self._backoff_attempts - 1)), RECONNECT_MAX_MS) / 1000
                delay *= 0.8 + (__import__("random").random() * 0.4)  # ±20% jitter

            logger.info(
                "%s: reconnect #%d in %.1fs",
                self._log_tag, self._reconnect_attempts, delay,
            )
            await asyncio.sleep(delay)

            # Actually reconnect
            if not self._running or self._permanent_close:
                return
            try:
                await self._connect_ws()
                if self._listen_task and not self._listen_task.done():
                    self._listen_task.cancel()
                self._listen_task = asyncio.create_task(self._message_loop())
            except Exception as e:
                logger.error("%s: reconnect failed: %s", self._log_tag, e)
                self._reconnecting = False
                await self._schedule_reconnect()
                return
        finally:
            self._reconnecting = False

    async def _close_ws(self):
        """Force close WebSocket."""
        if self._ws and not self._ws.closed:
            await self._ws.close()
        self._ws = None
        if self._session and not self._session.closed:
            await self._session.close()
            self._session = None

    # ------------------------------------------------------------------
    # Heartbeat
    # ------------------------------------------------------------------

    async def _heartbeat_loop(self):
        """Send ping every HEARTBEAT_INTERVAL seconds.

        Tracks consecutive failures and triggers reconnection when the
        WebSocket appears half-open (e.g. idle timeout on server side).
        """
        while self._running and not self._permanent_close:
            try:
                await asyncio.sleep(HEARTBEAT_INTERVAL)
                if self._ws and not self._ws.closed:
                    ok = await self._send_event("ping", {
                        "timestamp": int(time.time() * 1000),
                        "device_uuid": self._device_uuid,
                        "device_name": self._device_name,
                    })
                    if ok:
                        self._heartbeat_failures = 0
                        logger.debug("%s: heartbeat ping ok", self._log_tag)
                    else:
                        self._heartbeat_failures += 1
                        logger.warning(
                            "%s: heartbeat ping failed (%d/%d consecutive)",
                            self._log_tag, self._heartbeat_failures, self._max_heartbeat_failures,
                        )
                        if self._heartbeat_failures >= self._max_heartbeat_failures:
                            logger.warning(
                                "%s: %d consecutive heartbeat failures, triggering reconnect",
                                self._log_tag, self._heartbeat_failures,
                            )
                            self._heartbeat_failures = 0
                            # Force close and reconnect
                            await self._close_ws()
                            if not self._permanent_close:
                                await self._schedule_reconnect()
                            break
            except asyncio.CancelledError:
                break
            except Exception as e:
                self._heartbeat_failures += 1
                logger.error(
                    "%s: heartbeat error (%d/%d): %s",
                    self._log_tag, self._heartbeat_failures, self._max_heartbeat_failures, e,
                )
                if self._heartbeat_failures >= self._max_heartbeat_failures:
                    logger.warning(
                        "%s: %d consecutive heartbeat errors, triggering reconnect",
                        self._log_tag, self._heartbeat_failures,
                    )
                    self._heartbeat_failures = 0
                    # Force close and reconnect
                    await self._close_ws()
                    if not self._permanent_close:
                        await self._schedule_reconnect()
                    break

    # ------------------------------------------------------------------
    # Outbound messaging
    # ------------------------------------------------------------------

    async def _send_event(self, event: str, data: dict) -> bool:
        """Send a JSON event over WebSocket."""
        if not self._ws or self._ws.closed:
            logger.debug("%s: _send_event skipped (ws closed) event=%s", self._log_tag, event)
            return False
        try:
            payload = json.dumps({"event": event, "data": data})
            await self._ws.send_str(payload)
            return True
        except Exception as e:
            logger.error("%s: send error event=%s: %s", self._log_tag, event, e)
            return False

    async def send(self, chat_id: str, content: str, **kwargs) -> SendResult:
        """Send text message to AgentSpace."""
        if not content:
            return SendResult(success=False, error="empty message")

        chat_id = chat_id or self._latest_chat_id or "default"

        try:
            success = await self._send_event("message", {
                "role": "assistant",
                "type": "answer",
                "content": content,
                "chat_id": chat_id,
                "session_id": self._latest_session_id or "",
                "message_id": self._latest_message_id or "",
                "timestamp": int(time.time() * 1000),
                "device_uuid": self._device_uuid,
                "device_name": self._device_name,
            })
            return SendResult(
                success=success,
                message_id=self._latest_message_id or f"sent_{int(time.time())}",
            )
        except Exception as e:
            return SendResult(success=False, error=str(e))

    def send_typing(self, chat_id: str):
        """Not supported by AgentSpace protocol."""
        pass

    async def send_image(self, chat_id: str, image_url: str, caption: str = "") -> SendResult:
        """Not supported by AgentSpace protocol — send as text instead."""
        text = caption or ""
        if image_url:
            text = f"{text}\n{image_url}".strip()
        return await self.send(chat_id, text)

    def get_chat_info(self, chat_id: str) -> dict:
        return {
            "name": f"AgentSpace:{chat_id}",
            "type": "direct",
            "chat_id": chat_id,
        }

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------

    def _resolve_origin(self) -> str:
        try:
            from urllib.parse import urlparse
            parsed = urlparse(self._ws_url)
            scheme = "https" if parsed.scheme == "wss" else "http"
            return f"{scheme}://{parsed.hostname}"
        except Exception:
            return "https://agentspace.wps.cn"
