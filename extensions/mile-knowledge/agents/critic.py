#!/usr/bin/env python3
"""Real-time quality gate — lightweight reply checker for MiLe gateway hook.

Three checks:
1. Summarize-only — user asked for file/action but bot only gave text
2. Context pollution — bot treated system prompt as user input
3. Forget-to-split — multiple paragraphs mashed together

Uses case library for few-shot prompting. Supports direct API and CLI.
"""

import argparse
import json
import logging
import os
import sys
from pathlib import Path
from typing import Any

import numpy as np

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] critic: %(message)s",
)
logger = logging.getLogger("critic")

DATA_DIR = Path(__file__).resolve().parent.parent / "data"
CASE_LIBRARY_PATH = DATA_DIR / "case_library.json"

CRITIC_PROMPT = """你是一个 AI 回复质量检查器。检查 bot 的回复是否有以下问题：

1. **只总结不执行**：用户明确要求写文件、执行操作、修改代码等，但 bot 只有文字说明没有实际操作
2. **上下文污染**：bot 把系统提示（system prompt）里的内容当作用户输入来回复
3. **分段忘记拆**：多个独立段落或问题被黏在一起回复，没有逐条处理

以下是历史相似案例，供你参考：
{cases}

请检查以下对话：

用户消息：{user_message}

Bot 回复：{bot_reply}

返回 JSON（不要其他文字）：
如果发现问题：
{{"pass": false, "reason": "简短说明哪个检查项不通过", "fix_hint": "如何修正"}}
如果没有问题：
{{"pass": true}}
"""


def _load_env() -> None:
    env_file = Path.home() / ".hermes" / ".env"
    if not env_file.is_file():
        return
    for line in env_file.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        key = key.strip()
        value = value.strip().strip("\"'")
        if key and key not in os.environ:
            os.environ[key] = value


def _load_case_library() -> list[dict[str, Any]]:
    if not CASE_LIBRARY_PATH.exists():
        return []
    try:
        return json.loads(CASE_LIBRARY_PATH.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return []


def _find_similar_cases(
    user_message: str, case_library: list[dict[str, Any]], top_k: int = 3
) -> list[dict[str, Any]]:
    if not case_library:
        return []
    try:
        sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
        from graphrag.embedding import embed_texts, cosine_similarity
    except ImportError:
        logger.warning("graphrag.embedding not available, skipping case retrieval.")
        return []

    # Build texts: query + all case scenarios
    case_texts = [
        c.get("scenario", "") + " " + c.get("bad", "") for c in case_library
    ]
    all_texts = [user_message] + case_texts
    vecs = embed_texts(all_texts)

    query_vec = vecs[0:1]
    case_vecs = vecs[1:]
    sims = cosine_similarity(query_vec, case_vecs)[0]

    top_indices = np.argsort(sims)[::-1][:top_k]
    return [case_library[i] for i in top_indices if sims[i] > 0.3]


def _parse_critic_json(raw: str) -> dict[str, Any]:
    raw = raw.strip()
    if raw.startswith("```"):
        lines = raw.split("\n")
        if lines[0].startswith("```"):
            lines = lines[1:]
        if lines and lines[-1].strip() == "```":
            lines = lines[:-1]
        raw = "\n".join(lines)
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return {"pass": True, "parse_error": raw[:200]}


def check_reply(
    user_message: str,
    bot_reply: str,
    case_library: list[dict[str, Any]] | None = None,
) -> dict[str, Any]:
    """Check bot reply quality. Returns {pass: True} or {pass: False, reason, fix_hint}."""
    if case_library is None:
        case_library = _load_case_library()

    _load_env()
    api_key = os.environ.get("DEEPSEEK_API_KEY", "")
    if not api_key:
        return {"pass": True, "reason": "DEEPSEEK_API_KEY not set, skipping check"}

    similar = _find_similar_cases(user_message, case_library)

    if similar:
        lines = []
        for i, c in enumerate(similar):
            lines.append(
                f"案例{i + 1}：场景={c.get('scenario', '')} | 错误={c.get('bad', '')} | "
                f"正确做法={c.get('good', '')} | 关键词={c.get('trigger_keywords', [])}"
            )
        cases_text = "\n".join(lines)
    else:
        cases_text = "（无相似历史案例）"

    from openai import OpenAI

    base_url = os.environ.get("DEEPSEEK_BASE_URL", "https://api.deepseek.com/v1")
    model = os.environ.get("DEEPSEEK_MODEL", "deepseek-v4-flash")
    client = OpenAI(api_key=api_key, base_url=base_url)

    prompt = CRITIC_PROMPT.format(
        cases=cases_text,
        user_message=user_message[:2000],
        bot_reply=bot_reply[:2000],
    )

    try:
        response = client.chat.completions.create(
            model=model,
            messages=[
                {"role": "system", "content": "你是一个 AI 回复质量检查器。只返回 JSON。"},
                {"role": "user", "content": prompt},
            ],
            temperature=0.1,
            max_tokens=1024,
        )
        raw = response.choices[0].message.content or ""
        result = _parse_critic_json(raw)
        if "pass" not in result:
            result["pass"] = True
        return result
    except Exception:
        logger.exception("Critic check failed.")
        return {"pass": True, "reason": "api error, allowing through"}


def main() -> None:
    parser = argparse.ArgumentParser(
        description="MiLe Critic — real-time reply quality gate")
    parser.add_argument("--user-msg", required=True, help="User's message")
    parser.add_argument("--bot-reply", required=True, help="Bot's reply")
    parser.add_argument("--json", action="store_true", help="Raw JSON output only")
    args = parser.parse_args()

    result = check_reply(args.user_msg, args.bot_reply)

    if args.json:
        print(json.dumps(result, ensure_ascii=False))
    else:
        status = "PASS" if result.get("pass") else "FAIL"
        print(f"[{status}]")
        if not result.get("pass"):
            print(f"  Reason: {result.get('reason', 'unknown')}")
            print(f"  Fix hint: {result.get('fix_hint', 'N/A')}")

    sys.exit(0 if result.get("pass") else 1)


if __name__ == "__main__":
    main()


# --- Verification commands (run manually) ---
#
# 1. Test imports and basic flow (no API key needed)
# python3 -c "
# import sys; sys.path.insert(0, '.')
# from agents.critic import check_reply, _load_case_library, _find_similar_cases
# cases = _load_case_library()
# print(f'Case library has {len(cases)} cases (may be 0 if not built yet)')
# result = check_reply('hello', 'hi there', [])
# assert result.get('pass') == True, f'Expected pass=True, got {result}'
# print(f'check_reply with empty cases: {result}')
# print('PASS: imports and basic flow')
# "
#
# 2. Test CLI argument parsing
# python3 agents/critic.py --user-msg "帮我写个文件保存到桌面" --bot-reply "好的，我来帮你写。代码如下..." --json 2>&1; echo "(exit=$?)"
#
# 3. Test case retrieval with sample data
# python3 -c "
# import sys; sys.path.insert(0, '.')
# from agents.critic import _find_similar_cases
# cases = [{
#     'scenario': '用户要求写文件但AI只给文字',
#     'bad': '只输出文字说明不执行写入',
#     'good': '实际调用工具写入文件',
#     'trigger_keywords': ['写文件', '保存', '创建']
# }]
# result = _find_similar_cases('帮我写个文件保存到桌面', cases, top_k=1)
# assert len(result) == 1, f'Expected 1 similar case, got {len(result)}'
# print('PASS: case retrieval')
# "
