#!/usr/bin/env python3
"""Evaluation system — scores conversation quality and tracks trends.

Runs daily. Reads recent sessions from state.db, scores each on:
- Accuracy (1-10)
- Expression consistency (1-10)
- Response speed (1-10)

Tracks trends vs. previous day. Two consecutive days of decline → WARNING.
Outputs daily JSON to data/daily_eval_{date}.json, maintains data/eval_trend.json.
"""

import argparse
import json
import logging
import os
import sys
from datetime import datetime, timezone, timedelta
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).parent.parent))
from session_reader import get_recent_conversations

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] evaluate: %(message)s",
)
logger = logging.getLogger("evaluate")

DATA_DIR = Path(__file__).resolve().parent.parent / "data"

EVAL_PROMPT = """你是一个 AI 对话质量评估分析师。对以下对话记录进行评分。

评分维度（1-10 分）：
- accuracy: 回答的准确性，是否事实正确
- consistency: 表达风格是否一致，是否贴合角色
- responsiveness: 回复是否及时、切题

返回 JSON 格式（不要其他文字）：
{
  "accuracy": 8,
  "consistency": 7,
  "responsiveness": 9,
  "notes": "简短中文点评"
}
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


def _format_conversation(messages: list[dict[str, Any]]) -> str:
    lines = []
    for m in messages:
        lines.append(f"[{m['role']}]: {m['content']}")
    text = "\n".join(lines)
    if len(text) > 4000:
        text = text[:4000] + "\n... [truncated]"
    return text


def evaluate_session(session_id: str, messages: list[dict[str, Any]]) -> dict[str, Any]:
    """Score a single session using DeepSeek."""
    api_key = os.environ.get("DEEPSEEK_API_KEY", "")
    if not api_key:
        return {"accuracy": 0, "consistency": 0, "responsiveness": 0,
                "notes": "DEEPSEEK_API_KEY not set"}

    content = _format_conversation(messages)

    from openai import OpenAI

    base_url = os.environ.get("DEEPSEEK_BASE_URL", "https://api.deepseek.com/v1")
    model = os.environ.get("DEEPSEEK_MODEL", "deepseek-v4-flash")
    client = OpenAI(api_key=api_key, base_url=base_url)

    try:
        response = client.chat.completions.create(
            model=model,
            messages=[
                {"role": "system", "content": EVAL_PROMPT},
                {"role": "user", "content": content},
            ],
            temperature=0.1,
            max_tokens=1024,
        )
        raw = response.choices[0].message.content or ""
        return _parse_eval_json(raw)
    except Exception:
        logger.exception("Evaluation failed for %s.", session_id)
        return {"accuracy": 0, "consistency": 0, "responsiveness": 0, "notes": "api error"}


def _parse_eval_json(raw: str) -> dict[str, Any]:
    raw = raw.strip()
    if raw.startswith("```"):
        lines = raw.split("\n")
        if lines[0].startswith("```"):
            lines = lines[1:]
        if lines and lines[-1].strip() == "```":
            lines = lines[:-1]
        raw = "\n".join(lines)
    try:
        data = json.loads(raw)
        return {
            "accuracy": int(data.get("accuracy", 0)),
            "consistency": int(data.get("consistency", 0)),
            "responsiveness": int(data.get("responsiveness", 0)),
            "notes": data.get("notes", ""),
        }
    except (json.JSONDecodeError, ValueError):
        return {"accuracy": 0, "consistency": 0, "responsiveness": 0, "notes": raw[:200]}


def aggregate_scores(scores: list[dict[str, Any]]) -> dict[str, Any]:
    """Average scores across all sessions."""
    if not scores:
        return {"accuracy": 0, "consistency": 0, "responsiveness": 0}
    n = 0
    totals = {"accuracy": 0, "consistency": 0, "responsiveness": 0}
    for s in scores:
        for k in totals:
            totals[k] += s.get(k, 0)
        n += 1
    return {k: round(v / n, 2) for k, v in totals.items()}


def load_trend() -> dict[str, Any]:
    """Load the trend file. Returns empty dict if not found."""
    trend_path = DATA_DIR / "eval_trend.json"
    if not trend_path.exists():
        return {"daily_scores": [], "warnings": []}
    try:
        return json.loads(trend_path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return {"daily_scores": [], "warnings": []}


def detect_warnings(
    trend: dict[str, Any], today_scores: dict[str, Any], date_str: str
) -> list[str]:
    """Check if any metric declined two days in a row."""
    warnings: list[str] = []
    history = trend.get("daily_scores", [])
    if len(history) < 2:
        return warnings
    yesterday = history[-1]
    day_before = history[-2]

    for metric in ("accuracy", "consistency", "responsiveness"):
        t_val = today_scores.get(metric, 0)
        y_val = yesterday.get(metric, 0)
        d_val = day_before.get(metric, 0)
        if y_val < d_val and t_val < y_val:
            msg = (
                f"WARNING [{date_str}]: {metric} declined two consecutive days "
                f"({d_val} → {y_val} → {t_val})"
            )
            warnings.append(msg)
            logger.warning(msg)
    return warnings


def extract_case_from_session(
    session_id: str, messages: list[dict], scores: dict
) -> dict | None:
    """Extract a failure case card from a low-scoring session. Returns None if not needed."""
    acc = scores.get("accuracy", 10)
    con = scores.get("consistency", 10)
    if acc >= 5 and con >= 5:
        return None
    _load_env()
    from openai import OpenAI
    api_key = os.environ.get("DEEPSEEK_API_KEY", "")
    if not api_key:
        return None
    base_url = os.environ.get("DEEPSEEK_BASE_URL", "https://api.deepseek.com/v1")
    model = os.environ.get("DEEPSEEK_MODEL", "deepseek-v4-flash")
    client = OpenAI(api_key=api_key, base_url=base_url)
    dialog = "\n".join(
        f"{m['role']}: {m['content'][:500]}" for m in messages[-10:]
    )
    prompt = (
        "从以下低分对话中提取一个失败案例卡。\n"
        f"对话内容:\n{dialog[:3000]}\n"
        f"评分：准确性={acc}，一致性={con}\n"
        "返回 JSON（不要其他文字）：\n"
        '{"scenario": "场景简述", "bad": "AI做错了什么", "good": "正确做法", "trigger_keywords": ["关键词"]}\n'
        "如果无法提取有意义的案例，返回空字段。"
    )
    try:
        response = client.chat.completions.create(
            model=model,
            messages=[{"role": "user", "content": prompt}],
            temperature=0.1,
            max_tokens=512,
        )
        raw = response.choices[0].message.content or ""
        raw = raw.strip()
        if raw.startswith("```"):
            raw = raw.split("\n", 1)[-1].rsplit("```", 1)[0]
        data = json.loads(raw)
        if not data.get("scenario"):
            return None
        return {
            "scenario": data["scenario"],
            "bad": data["bad"],
            "good": data["good"],
            "trigger_keywords": data.get("trigger_keywords", []),
            "source": "evaluate",
            "session_id": session_id,
            "created_at": datetime.now(timezone.utc).isoformat(),
        }
    except Exception:
        logger.exception("Failed to extract case from session %s", session_id)
        return None


def _load_case_library() -> list[dict]:
    path = DATA_DIR / "case_library.json"
    if not path.exists():
        return []
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return []


def _save_case_library(cases: list[dict]) -> None:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    path = DATA_DIR / "case_library.json"
    path.write_text(json.dumps(cases, ensure_ascii=False, indent=2), encoding="utf-8")
    logger.info("Case library saved (%d cases).", len(cases))


def main() -> None:
    parser = argparse.ArgumentParser(
        description="MiLe Evaluation System — daily conversation scoring")
    parser.add_argument("--hours", type=int, default=24,
                        help="Hours back to scan (default: 24)")
    parser.add_argument("--dry-run", action="store_true",
                        help="Evaluate but don't write files")
    args = parser.parse_args()

    _load_env()
    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    logger.info("Starting evaluation for %s (dry-run=%s)...", today, args.dry_run)

    conversations = get_recent_conversations(hours=args.hours)
    if not conversations:
        logger.warning("No recent conversations found.")
        return

    scores = []
    for i, conv in enumerate(conversations):
        sid = conv["session_id"]
        logger.info("Evaluating session %d/%d: %s", i + 1, len(conversations), sid)
        score = evaluate_session(sid, conv["messages"])
        score["session"] = sid
        scores.append(score)

    today_scores = aggregate_scores(scores)
    logger.info("Daily aggregate: %s", json.dumps(today_scores))

    trend = load_trend()
    trend.setdefault("daily_scores", [])

    # Append today's score
    entry = {"date": today, **today_scores}
    trend["daily_scores"].append(entry)

    # Keep last 90 days
    if len(trend["daily_scores"]) > 90:
        trend["daily_scores"] = trend["daily_scores"][-90:]

    # Detect warnings
    new_warnings = detect_warnings(trend, today_scores, today)
    trend.setdefault("warnings", [])
    trend["warnings"].extend(new_warnings)

    # Write outputs
    output = {
        "date": today,
        "scores": today_scores,
        "per_session": scores,
        "warnings": new_warnings,
        "num_sessions": len(scores),
    }

    if not args.dry_run:
        DATA_DIR.mkdir(parents=True, exist_ok=True)
        daily_path = DATA_DIR / f"daily_eval_{today}.json"
        daily_path.write_text(json.dumps(output, ensure_ascii=False, indent=2),
                              encoding="utf-8")
        trend_path = DATA_DIR / "eval_trend.json"
        trend_path.write_text(json.dumps(trend, ensure_ascii=False, indent=2),
                              encoding="utf-8")
        logger.info("Daily evaluation saved to %s.", daily_path)

        # Extract failure cases from low-scoring sessions
        case_library = _load_case_library()
        seen = {(c.get("scenario", ""), c.get("bad", "")) for c in case_library}
        new_cases = 0
        for s in scores:
            if s.get("accuracy", 10) >= 5 and s.get("consistency", 10) >= 5:
                continue
            sid = s["session"]
            conv = next((c for c in conversations if c["session_id"] == sid), None)
            if not conv:
                continue
            case = extract_case_from_session(sid, conv["messages"], s)
            if case:
                key = (case["scenario"], case["bad"])
                if key not in seen:
                    case_library.append(case)
                    seen.add(key)
                    new_cases += 1
        if new_cases:
            _save_case_library(case_library)
            logger.info("Added %d new failure cases to library.", new_cases)

    print(json.dumps(output, ensure_ascii=False, indent=2))
    logger.info("Evaluation complete.")


if __name__ == "__main__":
    main()
