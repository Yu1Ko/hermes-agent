#!/usr/bin/env python3
"""Layer 4: Auto Prompt Evolution — analyses error clusters in case_library.json
and generates SOUL.md modification suggestions via claude-opus-4-7.

When a scenario accumulates >= 10 failure cases, the optimiser composes a prompt
with all bad/good examples and asks the model to identify unclear prompt
instructions that cause the recurring error, then propose concrete edits.
"""

import argparse
import json
import logging
import os
import sys
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).parent.parent))

import httpx

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] optimize: %(message)s",
)
logger = logging.getLogger("optimize")

DATA_DIR = Path(__file__).resolve().parent.parent / "data"
CASE_LIBRARY_PATH = DATA_DIR / "case_library.json"
REPORT_PATH = DATA_DIR / "optimization_report.json"

DEFAULT_THRESHOLD = 3

# Prompt files that the optimiser can suggest edits for
PROMPT_FILES = [
    Path.home() / ".hermes" / "SOUL.md",
    Path.home() / ".hermes" / "skills" / "konata-default-persona" / "SKILL.md",
    Path.home() / ".hermes" / "skills" / "mile-graphrag" / "SKILL.md",
    Path(__file__).resolve().parent / "critic.py",
]

ANALYSIS_PROMPT = """你是一个 AI Prompt 优化专家。以下是同一类错误场景下累积的多个失败案例。
每个案例包含 AI 的错误回复（bad）和正确的做法（good）。

错误根源可能出在以下几个提示词文件中（不只 SOUL.md）：

- **SOUL.md** — MiLe 的灵魂/人格定义，角色行为约束
- **konata-default-persona SKILL.md** — 泉此方内核人格的完整规范（三段层：底层操作系统/决策启发式/表达通道）
- **critic.py CRITIC_PROMPT** — 拦截器自身的质量检查 prompt，如果描述不够具体会导致漏检
- **mile-graphrag SKILL.md** — MiLe 知识管理系统的使用手册，包含分段规则、回复风格约束等操作指令

在分析当前案例集时，这些文件都可能被读取并作为上下文。请在建议中引用具体的文件名和段落。

**核心原则：优化后的提示词应让 AI 更像人一样说话。** 具体意味着：
- 避免机器感强的结构化模板、分点列表、信息密度过高的长段落
- 改用自然对话流，像朋友聊天一样把信息揉进句子里，而不是摊成提纲
- 遇到"禁止列点"类错误时，不是简单加上"不要用列表"的禁令——而是要示范什么才算"像人说话"，并规定改法
- English prompts 也要避免 robotic / SEO-style phrasing，改用 conversational flow

请分析：

1. **根因**：上述哪个（或哪些）文件中的描述不够清晰、缺少约束、或有歧义，导致这个错误反复出现？
2. **修改建议**：给出具体的修改方案，以 old_string → new_string 格式呈现。明确标注 target_file（文件路径）。
3. **优先级**：high / medium / low

用中文回复，返回 JSON（不要其他文字）：

{{
  "root_cause": "根因分析（中文）",
  "suggestions": [
    {{
      "target_file": "文件路径（如 ~/.hermes/skills/konata-default-persona/SKILL.md）",
      "section": "需要修改的段落名",
      "old_string": "当前原文（如果知道的话，不知道就填 '待定位'）",
      "new_string": "建议改成什么",
      "reason": "为什么这样改（中文）",
      "priority": "high|medium|low"
    }}
  ],
  "summary": "一句话总结（中文）"
}}

以下是失败案例：

{cases}
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


def scan(threshold: int = DEFAULT_THRESHOLD) -> list[dict[str, Any]]:
    """Scan case_library.json and return scenarios reaching the threshold.

    Returns a list of dicts with keys: scenario, count, cases (list of dicts).
    """
    case_library = _load_case_library()
    if not case_library:
        logger.info("Case library is empty. Nothing to scan.")
        return []

    clusters: dict[str, list[dict]] = defaultdict(list)
    for case in case_library:
        scenario = case.get("scenario", "").strip()
        if scenario:
            clusters[scenario].append(case)

    results = []
    for scenario, cases in sorted(clusters.items()):
        count = len(cases)
        if count >= threshold:
            results.append({
                "scenario": scenario,
                "count": count,
                "cases": cases,
            })
            logger.info("Scenario [%s] has %d cases (threshold=%d).", scenario, count, threshold)

    logger.info("Scan complete: %d scenarios reach threshold out of %d total.",
                len(results), len(clusters))
    return results


def _format_cases(cases: list[dict[str, Any]]) -> str:
    lines = []
    for i, c in enumerate(cases):
        bad = c.get("bad", "")
        good = c.get("good", "")
        lines.append(f"案例 {i + 1}：")
        lines.append(f"  错误回复: {bad}")
        lines.append(f"  正确做法: {good}")
        lines.append("")
    return "\n".join(lines)


def _load_prompt_files() -> str:
    """Read all tracked prompt files and return them as formatted context."""
    blocks: list[str] = []
    for pf in PROMPT_FILES:
        if pf.is_file():
            content = pf.read_text(encoding="utf-8")
            # Trim very long files to avoid blowing the prompt
            if len(content) > 6000:
                content = content[:6000] + "\n... (truncated)"
            blocks.append(f"### {pf}\n```\n{content}\n```")
        else:
            blocks.append(f"### {pf}\n（文件不存在）")
    return "\n\n".join(blocks)


def _parse_analysis_json(raw: str) -> dict[str, Any]:
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
        return {
            "root_cause": "",
            "suggestions": [],
            "summary": raw[:500],
        }


def _get_client() -> tuple[httpx.Client, str] | None:
    """Return (httpx_client, model_name) for OpenAI-compatible API calls."""
    _load_env()
    api_key = os.environ.get("PROMPT_OPT_API_KEY", "")
    if not api_key:
        logger.error("PROMPT_OPT_API_KEY not set. Cannot call optimisation model.")
        return None
    model = os.environ.get("PROMPT_OPT_MODEL", "gpt-5.5")
    http_client = httpx.Client(
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        timeout=httpx.Timeout(120.0),
    )
    return http_client, model


def analyze(scenarios: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """For each scenario reaching threshold, call the optimisation model for analysis.

    Returns a list of analysis result dicts.
    """
    pair = _get_client()
    if pair is None:
        return []
    client, model = pair

    base_url = os.environ.get("PROMPT_OPT_BASE_URL", "https://ai.centos.hk/v1")

    results = []
    for entry in scenarios:
        scenario = entry["scenario"]
        cases = entry["cases"]
        logger.info("Analysing scenario [%s] with %d cases...", scenario, len(cases))

        cases_text = _format_cases(cases)
        files_text = _load_prompt_files()
        prompt = ANALYSIS_PROMPT.format(cases=cases_text)

        # Inject current prompt file contents as reference
        full_prompt = (
            "以下是当前所有提示词文件的完整内容，供你参考以给出精确的 old_string 建议：\n\n"
            + files_text
            + "\n\n---\n\n"
            + prompt
        )

        try:
            resp = client.post(
                f"{base_url.rstrip('/')}/chat/completions",
                json={
                    "model": model,
                    "max_completion_tokens": 4096,
                    "stream": False,
                    "messages": [
                        {"role": "system", "content": "你是一个 AI Prompt 优化专家。用中文回复，只返回 JSON。"},
                        {"role": "user", "content": full_prompt},
                    ],
                },
            )
            resp.raise_for_status()
            body = resp.json()
            raw = body.get("choices", [{}])[0].get("message", {}).get("content", "")

            if not raw:
                logger.warning("Empty response for scenario [%s].", scenario)

            analysis = _parse_analysis_json(raw)
            analysis["scenario"] = scenario
            analysis["case_count"] = len(cases)
            analysis["analyzed_at"] = datetime.now(timezone.utc).isoformat()
            results.append(analysis)
            logger.info("Analysis complete for [%s]: %d suggestions.",
                        scenario, len(analysis.get("suggestions", [])))
        except Exception:
            logger.exception("Analysis failed for scenario [%s].", scenario)
            results.append({
                "scenario": scenario,
                "case_count": len(cases),
                "root_cause": "",
                "suggestions": [],
                "summary": "API error — analysis failed",
                "analyzed_at": datetime.now(timezone.utc).isoformat(),
            })

    return results


def _save_report(report: dict[str, Any], dry_run: bool = False) -> None:
    if dry_run:
        logger.info("[DRY-RUN] Would write report to %s.", REPORT_PATH)
        return
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text(
        json.dumps(report, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    logger.info("Report saved to %s.", REPORT_PATH)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="MiLe Optimiser — Layer 4 Auto Prompt Evolution")
    parser.add_argument("--scan", action="store_true",
                        help="Scan case library and report clusters (no API call)")
    parser.add_argument("--dry-run", action="store_true",
                        help="Analyse but do not write report file")
    parser.add_argument("--threshold", type=int, default=DEFAULT_THRESHOLD,
                        help=f"Min cases per scenario to trigger analysis (default: {DEFAULT_THRESHOLD})")
    args = parser.parse_args()

    _load_env()

    scenarios = scan(threshold=args.threshold)

    if not scenarios:
        report = {
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "threshold": args.threshold,
            "scenarios_analyzed": 0,
            "results": [],
            "note": "No scenarios reached the threshold." if _load_case_library() else "Case library is empty.",
        }
        print(json.dumps(report, ensure_ascii=False, indent=2))
        return

    if args.scan:
        summary = [
            {"scenario": s["scenario"], "count": s["count"]}
            for s in scenarios
        ]
        print(json.dumps(summary, ensure_ascii=False, indent=2))
        return

    results = analyze(scenarios)

    report = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "threshold": args.threshold,
        "scenarios_analyzed": len(results),
        "source": str(CASE_LIBRARY_PATH),
        "results": results,
    }

    _save_report(report, dry_run=args.dry_run)
    print(json.dumps(report, ensure_ascii=False, indent=2))
    logger.info("Optimisation complete. %d scenarios analysed.", len(results))


if __name__ == "__main__":
    main()
