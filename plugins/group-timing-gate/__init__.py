"""
Group Timing Gate — MiLe 群聊节奏控制插件

MaiBot 同款 Timing Gate 机制，适配 Hermes 架构。
通过 pre_gateway_dispatch hook 在 agent 被调用前拦截群聊消息，
根据近期聊天活跃度判断 MiLe 是否应该发言。

逻辑分层：
  层1（规则预筛）：冷场(<3条/5min) → 直接放行；极热(>15条/5min) → 直接静默
  层2（LLM Timing Gate）：中间地带 → 调用 Groq 轻量模型判断，类似 MaiBot 的 timing gate prompt
  层3（兜底）：Groq 调用失败 → 退化为简单规则

模型：Groq 免费层 llama-4-scout-17b-16e-instruct（速度快、零成本）
"""

from __future__ import annotations

import logging
import os
import threading
import time
from collections import defaultdict
from typing import Any, Dict, List, Optional, Tuple

logger = logging.getLogger("plugins.group_timing_gate")

# ---------------------------------------------------------------------------
# Per-group message buffer: chat_id → [(timestamp, user_name, message_text), ...]
# ---------------------------------------------------------------------------
_msg_buffer: Dict[str, List[Tuple[float, str, str]]] = defaultdict(list)
_buffer_lock = threading.Lock()

# 配置常量
ACTIVITY_WINDOW = 300        # 5 分钟窗口
MAX_BUFFER_SIZE = 30         # 每组最多保留条数
COLD_THRESHOLD = 3           # 低于此数：冷场，直接放行
HOT_THRESHOLD = 15           # 高于此数：极热，直接静默（跳过 LLM 调用）
RECENT_CONTEXT_COUNT = 5     # 喂给 timing gate 的最近消息条数

GROQ_MODEL = "meta-llama/llama-4-scout-17b-16e-instruct"
GROQ_BASE_URL = "https://api.groq.com/openai/v1"
GATE_TIMEOUT = 8             # timing gate 调用超时（秒）
GATE_MAX_TOKENS = 30         # gate 只需输出一个词


def _get_api_key() -> str:
    """获取 Groq API key，优先 GROQ_API_KEY，fallback CRITIC_API_KEY"""
    return os.getenv("GROQ_API_KEY") or os.getenv("CRITIC_API_KEY", "")


def _gc_buffer(chat_id: str, now: float) -> None:
    """清理超出时间窗口的旧消息"""
    cutoff = now - ACTIVITY_WINDOW
    with _buffer_lock:
        _msg_buffer[chat_id] = [
            entry for entry in _msg_buffer[chat_id]
            if entry[0] > cutoff
        ][-MAX_BUFFER_SIZE:]


def _record(chat_id: str, user_name: str, text: str) -> int:
    """记录一条消息，返回窗口内消息总数"""
    now = time.time()
    with _buffer_lock:
        _gc_buffer(chat_id, now)
        preview = (text or "")[:80]
        _msg_buffer[chat_id].append((now, user_name or "unknown", preview))
        # 防泄漏：保持 buffer 在 MAX_BUFFER_SIZE 内
        if len(_msg_buffer[chat_id]) > MAX_BUFFER_SIZE:
            _msg_buffer[chat_id] = _msg_buffer[chat_id][-MAX_BUFFER_SIZE:]
        return len(_msg_buffer[chat_id])


def _recent_snapshot(chat_id: str) -> List[Tuple[float, str, str]]:
    """获取最近消息快照（线程安全）"""
    with _buffer_lock:
        return list(_msg_buffer.get(chat_id, []))


def _build_gate_prompt(
    recent_count: int,
    recent_msgs: List[Tuple[float, str, str]],
    bot_name: str = "MiLe",
) -> str:
    """构建 Timing Gate prompt，模仿 MaiBot 的 maisaka_timing_gate.prompt"""

    # 构建最近消息的文本
    context_lines = []
    for ts, name, text in recent_msgs[-RECENT_CONTEXT_COUNT:]:
        context_lines.append(f"[{name}] {text}")
    context_str = "\n".join(context_lines) if context_lines else "（无最近消息）"

    return f"""判断 {bot_name}（群聊成员）现在是否应该发言。当前5分钟内 {recent_count} 条消息：

{context_str}

规则：活跃且与{bot_name}无关→no_reply；冷场或有人找{bot_name}→continue

输出格式：只输出 continue 或 no_reply，不要其他文字。"""


def _call_gate(prompt: str) -> str:
    """调用 Groq timing gate，返回 'continue' 或 'no_reply'"""
    api_key = _get_api_key()
    if not api_key:
        logger.warning("No Groq API key available, falling back to rule")
        return "rule_fallback"

    try:
        from openai import OpenAI
        client = OpenAI(api_key=api_key, base_url=GROQ_BASE_URL, timeout=GATE_TIMEOUT)
        response = client.chat.completions.create(
            model=GROQ_MODEL,
            messages=[{"role": "user", "content": prompt}],
            max_tokens=GATE_MAX_TOKENS,
            temperature=0,
        )
        result = response.choices[0].message.content.strip().lower()
        logger.debug("Timing gate response: %r", result)
        # 兼容模型输出完整句子的情况：检查关键词
        if "no_reply" in result or "no" == result:
            return "no_reply"
        if "continue" in result:
            return "continue"
        # 如果没匹配到关键词，默认返回 continue（宁可多说不少说）
        logger.debug("Timing gate ambiguous response, defaulting to continue: %r", result)
        return "continue"
    except Exception as exc:
        logger.debug("Timing gate call failed: %s", exc)
        return "rule_fallback"


def _rule_based_decision(recent_count: int) -> str:
    """规则兜底：纯数字判断"""
    if recent_count <= COLD_THRESHOLD:
        return "continue"
    if recent_count >= HOT_THRESHOLD:
        return "no_reply"
    # 中间地带：偏保守，6条以上就倾向于沉默
    if recent_count >= 6:
        return "no_reply"
    return "continue"


# ---------------------------------------------------------------------------
# Hook callback
# ---------------------------------------------------------------------------

def _on_pre_gateway_dispatch(
    event=None,
    gateway=None,
    session_store=None,
    **kwargs,
) -> Optional[Dict[str, str]]:
    """
    pre_gateway_dispatch hook。
    返回 {"action": "skip"} 来阻止 agent 处理此消息。
    返回 None 则正常放行。
    """
    if event is None:
        return None

    source = getattr(event, "source", None)
    if source is None:
        return None

    # 只处理群聊
    chat_type = getattr(source, "chat_type", "dm")
    if chat_type not in ("group", "forum"):
        return None

    chat_id = getattr(source, "chat_id", "") or "unknown"
    user_name = getattr(source, "user_name", "") or "unknown"
    text = getattr(event, "text", "") or ""

    # 跳过命令消息（/new, /reset 等）
    if text.startswith("/"):
        return None

    # 记录消息并获取窗口内总数
    recent_count = _record(chat_id, user_name, text)

    # 层1：规则预筛
    if recent_count <= COLD_THRESHOLD:
        # 冷场，直接放行让 MiLe 多说
        logger.debug(
            "group=%s cold(%d msgs/5min) → allow",
            chat_id, recent_count,
        )
        return None

    if recent_count >= HOT_THRESHOLD:
        # 极热，直接静默省一次 LLM 调用
        logger.debug(
            "group=%s hot(%d msgs/5min) → skip (rule)",
            chat_id, recent_count,
        )
        return {
            "action": "skip",
            "reason": f"timing_gate: group active ({recent_count} msgs/5min)",
        }

    # 层2：LLM Timing Gate
    recent_msgs = _recent_snapshot(chat_id)
    gate_prompt = _build_gate_prompt(recent_count, recent_msgs)
    decision = _call_gate(gate_prompt)

    # 层3：兜底
    if decision == "rule_fallback":
        decision = _rule_based_decision(recent_count)

    if decision == "no_reply":
        logger.info(
            "group=%s active(%d msgs/5min) gate=%s → skip",
            chat_id, recent_count, decision,
        )
        return {
            "action": "skip",
            "reason": f"timing_gate: {decision} ({recent_count} msgs/5min)",
        }

    logger.debug(
        "group=%s moderate(%d msgs/5min) gate=%s → allow",
        chat_id, recent_count, decision,
    )
    return None


# ---------------------------------------------------------------------------
# Plugin registration
# ---------------------------------------------------------------------------

def register(ctx) -> None:
    ctx.register_hook("pre_gateway_dispatch", _on_pre_gateway_dispatch)
    logger.info("group-timing-gate plugin registered (pre_gateway_dispatch hook)")
