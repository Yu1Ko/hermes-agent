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

from openai import OpenAI

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] optimize: %(message)s",
)
logger = logging.getLogger("optimize")

DATA_DIR = Path(__file__).resolve().parent.parent / "data"
CASE_LIBRARY_PATH = DATA_DIR / "case_library.json"
REPORT_PATH = DATA_DIR / "optimization_report.json"

DEFAULT_THRESHOLD = 10

ANALYSIS_PROMPT = """你是一个 AI Prompt 优化专家。以下是同一类错误场景下累积的多个失败案例。
每个案例包含 AI 的错误回复（bad）和正确的做法（good）。

请分析：

1. **根因**：SOUL.md 或 System Prompt 中哪个描述不够清晰、缺少约束、或有歧义，导致这个错误反复出现？
2. **修改建议**：给出具体的 SOUL.md 修改方案，以 old_string → new_string 格式呈现。
3. **优先级**：high / medium / low

用中文回复，返回 JSON（不要其他文字）：

{{
  "root_cause": "根因分析（中文）",
  "suggestions": [
    {{
      "section": "SOUL.md 中需要修改的段落名（如 角色定义 / 行为约束 / 工具使用规则）",
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


def _get_client() -> OpenAI | None:
    _load_env()
    api_key = os.environ.get("PROMPT_OPT_API_KEY", "")
    if not api_key:
        logger.error("PROMPT_OPT_API_KEY not set. Cannot call optimisation model.")
        return None
    base_url = os.environ.get("PROMPT_OPT_BASE_URL", "https://ai.centos.hk/v1")
    model = os.environ.get("PROMPT_OPT_MODEL", "claude-opus-4-7")
    return OpenAI(api_key=api_key, base_url=base_url), model


def analyze(scenarios: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """For each scenario reaching threshold, call the optimisation model for analysis.

    Returns a list of analysis result dicts.
    """
    pair = _get_client()
    if pair is None:
        return []
    client, model = pair

    results = []
    for entry in scenarios:
        scenario = entry["scenario"]
        cases = entry["cases"]
        logger.info("Analysing scenario [%s] with %d cases...", scenario, len(cases))

        cases_text = _format_cases(cases)
        prompt = ANALYSIS_PROMPT.format(cases=cases_text)

        try:
            response = client.chat.completions.create(
                model=model,
                messages=[
                    {"role": "system", "content": "你是一个 AI Prompt 优化专家。用中文回复，只返回 JSON。"},
                    {"role": "user", "content": prompt},
                ],
                temperature=0.2,
                max_tokens=4096,
            )
            raw = response.choices[0].message.content or ""
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
