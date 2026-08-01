"""Model client helpers — V4Flash → DeepSeek official fallback."""

import os
import logging

logger = logging.getLogger(__name__)

FALLBACK_BASE_URL = "https://api.deepseek.com/v1"
FALLBACK_MODEL = "deepseek-v4-flash"


def _build_openai_client():
    """Return (client, model) for the primary endpoint (V4Flash or DEEPSEEK)."""
    from openai import OpenAI

    api_key = os.environ.get("V4FLASH_API_KEY") or os.environ.get("DEEPSEEK_API_KEY", "")
    base_url = os.environ.get("V4FLASH_BASE_URL") or os.environ.get("DEEPSEEK_BASE_URL", FALLBACK_BASE_URL)
    model = os.environ.get("V4FLASH_MODEL") or os.environ.get("DEEPSEEK_MODEL", FALLBACK_MODEL)
    return OpenAI(api_key=api_key, base_url=base_url), model


def _needs_fallback():
    """True when V4Flash points to a non-DeepSeek endpoint (e.g. SenseNova)."""
    v4 = os.environ.get("V4FLASH_BASE_URL", "")
    return bool(v4) and "api.deepseek.com" not in v4


def call_llm(messages, temperature=0.2, max_tokens=4096):
    """Send a chat completion request through the primary endpoint.

    On failure, if V4Flash is a non-DeepSeek provider (SenseNova etc.),
    automatically retry through the official DeepSeek API.

    Returns the raw response text or None on failure.
    """
    from openai import OpenAI

    client, model = _build_openai_client()

    def _invoke(_client, _model):
        resp = _client.chat.completions.create(
            model=_model,
            messages=messages,
            temperature=temperature,
            max_tokens=max_tokens,
        )
        return resp.choices[0].message.content or ""

    try:
        return _invoke(client, model)
    except Exception:
        if not _needs_fallback():
            logger.exception("LLM call failed (no fallback configured).")
            return None

        logger.warning("Primary endpoint failed, trying DeepSeek official …")
        fallback_key = os.environ.get("DEEPSEEK_API_KEY", "")
        if not fallback_key:
            logger.error("DEEPSEEK_API_KEY not set — cannot fallback.")
            return None

        try:
            fb_client = OpenAI(api_key=fallback_key, base_url=FALLBACK_BASE_URL)
            return _invoke(fb_client, FALLBACK_MODEL)
        except Exception:
            logger.exception("Fallback also failed.")
            return None
