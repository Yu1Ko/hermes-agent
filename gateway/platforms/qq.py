"""NapCat/OneBot QQ adapter for Hermes Gateway.

The implementation lives in gateway/platforms/qq_napcat/ so the QQ adapter
is versioned together with the Hermes core without external package deps.
"""

from gateway.platforms.qq_napcat import (  # noqa: F401
    NapCatClient,
    NapCatQQAdapter,
    QQBridgeError,
    QQEventSource,
    check_qq_requirements,
)
