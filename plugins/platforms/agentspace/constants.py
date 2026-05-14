"""
Agentspace configuration constants.

WebSocket URLs, timeouts, event types for the WPS Agentspace platform.
"""

# ── WebSocket endpoints ──────────────────────────────────────────────────
# Default WebSocket URL for openClaw apps
DEFAULT_WS_URL = "wss://agentspace.wps.cn/v7/devhub/ws/openClaw/chat"

# Base for app-specific WebSocket URLs: wss://agentspace.wps.cn/v7/devhub/ws/{app_id}/chat
WS_URL_BASE = "wss://agentspace.wps.cn/v7/devhub/ws"

# HTTP origin derived from WebSocket URL
ORIGIN = "https://agentspace.wps.cn"

# ── Agentspace API endpoints ─────────────────────────────────────────────
LOGIN_URL = "https://agentspace.wps.cn/v7/devhub/users/login_url"
TOKEN_URL = "https://agentspace.wps.cn/v7/devhub/users/user_token"
CURRENT_USER_URL = "https://agentspace.wps.cn/v7/devhub/users/current"

# ── Timing constants ─────────────────────────────────────────────────────
# WebSocket connection timeout (seconds)
CONNECT_TIMEOUT = 30

# Heartbeat interval (seconds) — server disconnects after 60s of inactivity
HEARTBEAT_INTERVAL = 10

# Reconnect: fixed interval (seconds) for the first 10 minutes
RECONNECT_FIXED_PHASE_SEC = 600  # 10 minutes
RECONNECT_FIXED_INTERVAL = 20  # seconds

# Reconnect: exponential backoff after 10 minutes
RECONNECT_BASE = 5
RECONNECT_MAX = 3600  # 1 hour
RECONNECT_GIVE_UP = 7 * 24 * 3600  # 7 days

# ── Event types ──────────────────────────────────────────────────────────
EVENT_INIT = "init"
EVENT_PING = "ping"
EVENT_MESSAGE = "message"
EVENT_ERROR = "error"

# ── Fatal error codes (do not reconnect) ─────────────────────────────────
FATAL_ERROR_CODES = [
    "USER_NO_APP_PERMISSION",
    "USER_NO_OPENCLAW_PERMISSION",
    "OPENCLAW_NOT_CONFIGURED",
    "NOT_OPENCLAW_APP",
    "NOT_LOGIN",
]
