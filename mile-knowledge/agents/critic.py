#!/usr/bin/env python3
"""Real-time quality gate — lightweight reply checker for MiLe gateway hook.

Five checks:
1. Summarize-only — user asked for file/action but bot only gave text
2. Context pollution — bot treated system prompt as user input
3. Forget-to-split — multiple paragraphs mashed together
4. Trailing period — reply ends with 。 (forbidden by persona)
5. Document-style output — casual chat written like a tutorial/report

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

1. **未按明确指令执行**：用户明确要求写文件、执行操作、修改代码、运行某条命令、或设置某个默认行为时，bot 没有完成用户点名的动作。包括两种失败：一是只有文字说明没有实际操作；二是 bot 做了别的事，比如擅自去查配置、看状态、分析环境、改成自己的排查流程，却没有执行用户指定的命令或确认指定的默认行为
2. **上下文污染**：bot 把系统提示（system prompt）里的内容当作用户输入来回复，比如把人格设定、分段规则、禁止项等当成"用户说了XXX"来回应
3. **分段忘记拆 / 机械分段**：多个独立话题、段落、或逻辑块被黏在一条消息里回复，算失败。即使 bot 使用了 `terminal(command='true')`，如果只是把表格、清单、标题式段落机械切开，每条仍然塞了多个意思，或读起来像文档切片而不是聊天，也算失败。MiLe 的规则是：通过网关（QQ/AgentSpace）回复时，每 1 个主要意思、最多 2 个轻相关意思就要拆成独立消息
4. **句尾违规**：回复末尾出现了中文句号（。）。MiLe 的人格设定明确禁止句尾加句号，问号和感叹号除外
5. **文档化输出**：在用户没有明确要求表格、清单、JSON、Markdown 或步骤列表时，回复被写成结构化教程、菜谱式列举、表格、多级标题、汇报风格、SEO 风格总结，或大量使用分段标题、数字编号、加粗列表等，而不是像朋友聊天一样自然流动，算失败。尤其在 QQ/AgentSpace 这类网关场景中，正确做法是先把信息改成口语短句，再用 `terminal(command='true')` 按意思拆开
6. **空泛机制化建议**：用户要求修改 prompt、写 old_string/new_string、执行具体优化时，bot 只说"建立机制""加强约束""默认使用某风格""避免某问题"这类原则，或只给"优先使用某 API""改用某库解析"这类运行策略，却没有给出可直接替换的原文和改文。判定标准：回复里必须有明确的 `target_file`、`section`、`old_string`、`new_string`；`old_string` 必须是可搜索的原文，不能是概括性描述。即使方向正确也算失败
7. **未验证本地环境就下结论**：用户询问本地文件、浏览器、系统资源、运行环境、路径、端口、网络连通性时，bot 没用工具检查也不声明假设，却直接断言当前环境状态。把未确认信息说成事实就算失败
8. **故障反馈空泛化**：用户报告"没回复""消息没收到""没发出来""机器人没反应"等网关故障时，bot 只给"检查连接状态、消息路由、事件循环"这类排查清单，没有先道歉、补发内容或询问是哪条没收到。这种运维报告式回复算失败
9. **无请求时挂下一步钩子**：用户只是陈述、吐槽、闲聊、确认信息，或没明确要求建议/执行/继续推进时，bot 结尾习惯性追加"要不要我…""要跑吗""要不要推进""我可以继续帮你…"等征询，或自动列选项、问下一步。关键建议可直接说一句；不关键的事应自然收尾
10. **静默协议违背**：用户消息含 `[SILENT]`、`静默`、cron/定时任务等静默要求时，bot 在没有实际新结果的情况下输出了总结、reflection 摘要、寒暄或无关内容。正确输出：没新结果仅 `[SILENT]`；有新结果只输出任务报告本身
11. **只给文件路径不解释**：用户要求生成 HTML、图片、文档、可视化、架构图、流程图时，bot 只回复"已生成，路径是..."，没在对话中说明核心内容。架构/流程类任务必须在聊天里补简短文字说明、ASCII 或 Mermaid 图

以下是历史相似案例，供你参考：
{cases}

请检查以下对话：

用户消息：{user_message}

Bot 回复：{bot_reply}

返回 JSON（不要其他文字）：
如果发现问题：
{{"pass": false, "reason": "简短说明哪个检查项不通过（写编号即可，如'检查3：...'）", "fix_hint": "如何修正。检查1→回到用户点名的命令直接执行，不许用查配置替代。检查3/5→先把表格/清单改成口语短句再用terminal(true)拆开。检查6→补齐 target_file/section/old_string/new_string，old_string要可搜索原文。检查7→先用工具确认现场或重写为假设口吻。检查8→先道歉并补发/重说内容，不许给排查清单。检查9→删结尾钩子，自然收尾。检查10→没新结果只输出[SILENT]，有新结果删寒暄只留报告。检查11→在路径外补2-4句核心说明，架构类补ASCII/Mermaid图"}}
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
    api_key = os.environ.get("CRITIC_API_KEY") or os.environ.get("DEEPSEEK_API_KEY", "")
    if not api_key:
        return {"pass": True, "reason": "CRITIC_API_KEY not set, skipping check"}

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

    base_url = os.environ.get("CRITIC_API_BASE") or os.environ.get("DEEPSEEK_BASE_URL", "https://api.deepseek.com/v1")
    model = os.environ.get("CRITIC_MODEL") or os.environ.get("DEEPSEEK_MODEL", "deepseek-v4-flash")
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


def rewrite_reply(
    user_message: str,
    bot_reply: str,
    fix_hint: str,
) -> str | None:
    """Rewrite a flagged reply based on the fix_hint. Returns None on failure."""
    _load_env()
    api_key = os.environ.get("CRITIC_API_KEY") or os.environ.get("DEEPSEEK_API_KEY", "")
    if not api_key:
        return None

    from openai import OpenAI

    base_url = os.environ.get("CRITIC_API_BASE") or os.environ.get("DEEPSEEK_BASE_URL", "https://api.deepseek.com/v1")
    model = os.environ.get("CRITIC_MODEL") or os.environ.get("DEEPSEEK_MODEL", "deepseek-v4-flash")
    client = OpenAI(api_key=api_key, base_url=base_url)

    rewrite_prompt = f"""用户的消息是：
{user_message[:1500]}

AI 原本的回复是：
{bot_reply[:2000]}

质量检查发现以下问题，需要修正：
{fix_hint}

请直接输出修正后的完整回复文本（不要加任何解释，不要加引号包裹）"""

    try:
        response = client.chat.completions.create(
            model=model,
            messages=[
                {"role": "system", "content": "你是一个 AI 回复重写器。直接输出修正后的文本，不加解释。"},
                {"role": "user", "content": rewrite_prompt},
            ],
            temperature=0.2,
            max_tokens=4096,
        )
        rewritten = (response.choices[0].message.content or "").strip()
        # Strip markdown code fences if the model wrapped it
        if rewritten.startswith("```"):
            lines = rewritten.split("\n")
            if len(lines) > 1 and lines[-1].strip() == "```":
                rewritten = "\n".join(lines[1:-1])
        return rewritten if rewritten else None
    except Exception:
        logger.exception("Rewrite failed.")
        return None


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
