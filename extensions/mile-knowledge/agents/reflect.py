#!/usr/bin/env python3
"""Reflection loop — analyses recent sessions for patterns and lessons.

Runs daily. Reads recent sessions from state.db, identifies:
- What MiLe was corrected on
- Where behaviour was inconsistent
- Improvement items

Results are written to evolution_memory and key entities extracted into GraphRAG.
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
    format="%(asctime)s [%(levelname)s] reflect: %(message)s",
)
logger = logging.getLogger("reflect")

EVOLUTION_DIR = Path.home() / ".hermes" / "evolution_memory"

REFLECTION_PROMPT = """你是一个 AI 反思分析师。分析以下对话记录，找出：

1. **被纠正的错误**：用户指出了哪些错误或不当回复？
2. **表现不稳定**：哪些场景下 AI 表现不稳定或前后不一致？
3. **改进项**：有什么具体可改进的地方？

返回 JSON 格式（不要其他文字）：
{
  "corrections": [
    {"scenario": "场景描述", "what_went_wrong": "什么地方不对", "lesson": "学到的教训"}
  ],
  "instabilities": [
    {"context": "上下文", "issue": "不稳定点", "impact": "影响"}
  ],
  "improvement_items": [
    {"area": "领域", "suggestion": "改进建议", "priority": "high|medium|low"}
  ],
  "summary": "一段中文总结"
}
"""


def _load_env() -> None:
    """Ensure DEEPSEEK_API_KEY is available."""
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


def read_conversations(hours: int = 24) -> str:
    """Concatenate recent conversation contents into one text blob for analysis."""
    conversations = get_recent_conversations(hours=hours)
    if not conversations:
        return ""

    chunks: list[str] = []
    for conv in conversations:
        lines = []
        for m in conv["messages"]:
            lines.append(f"[{m['role']}]: {m['content']}")
        text = "\n".join(lines)
        if len(text) > 4000:
            text = text[:4000] + "\n... [truncated]"
        chunks.append(f"--- Session: {conv['session_id']} ---\n{text}")

    logger.info("Loaded %d conversations from state.db.", len(conversations))
    return "\n\n".join(chunks)


def analyse_with_deepseek(text: str) -> dict[str, Any]:
    """Send the combined session text to DeepSeek for reflection analysis."""
    api_key = os.environ.get("DEEPSEEK_API_KEY", "")
    if not api_key:
        logger.error("DEEPSEEK_API_KEY not set. Cannot run reflection.")
        return {"corrections": [], "instabilities": [], "improvement_items": [], "summary": ""}
    from openai import OpenAI

    base_url = os.environ.get("DEEPSEEK_BASE_URL", "https://api.deepseek.com/v1")
    model = os.environ.get("DEEPSEEK_MODEL", "deepseek-v4-flash")
    client = OpenAI(api_key=api_key, base_url=base_url)

    try:
        response = client.chat.completions.create(
            model=model,
            messages=[
                {"role": "system", "content": REFLECTION_PROMPT},
                {"role": "user", "content": text[:12000]},
            ],
            temperature=0.2,
            max_tokens=4096,
        )
        raw = response.choices[0].message.content or ""
        return _parse_json(raw)
    except Exception:
        logger.exception("DeepSeek API call failed.")
        return {"corrections": [], "instabilities": [], "improvement_items": [], "summary": ""}


def _parse_json(raw: str) -> dict[str, Any]:
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
        logger.warning("Failed to parse reflection JSON.")
        return {"corrections": [], "instabilities": [], "improvement_items": [], "summary": raw[:500]}


def save_to_evolution_memory(report: dict[str, Any], dry_run: bool = False) -> Path | None:
    """Write the reflection report to evolution_memory directory."""
    ts = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    filename = f"reflect_{ts}.json"
    filepath = EVOLUTION_DIR / filename

    payload = {
        "type": "reflection",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "report": report,
    }

    if dry_run:
        logger.info("[DRY-RUN] Would write to %s:\n%s", filepath,
                     json.dumps(payload, ensure_ascii=False, indent=2))
        return None

    EVOLUTION_DIR.mkdir(parents=True, exist_ok=True)
    filepath.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    logger.info("Reflection saved to %s.", filepath)
    return filepath


def update_graphrag(report: dict[str, Any], dry_run: bool = False) -> None:
    """Extract key entities from the reflection and add them to GraphRAG."""
    try:
        from graphrag.config import GRAPH_PATH
        from graphrag.graph import GraphManager
        from graphrag.extractor import EntityRelationExtractor
    except ImportError:
        logger.warning("graphrag package not available — skipping graph update.")
        return

    gm = GraphManager()
    if GRAPH_PATH.exists():
        gm.load(GRAPH_PATH)

    extractor = EntityRelationExtractor()
    text = json.dumps(report.get("improvement_items", []) + report.get("corrections", []),
                      ensure_ascii=False)
    if not text.strip():
        return

    if dry_run:
        logger.info("[DRY-RUN] Would extract entities from reflection report.")
        return

    result = extractor.extract(text)
    for ent in result.get("entities", []):
        gm.add_entity(
            ent["name"],
            type=ent.get("type", "concept"),
            description=ent.get("description", ""),
            confidence=ent.get("confidence", 1.0),
            source="reflection",
        )
    for rel in result.get("relations", []):
        gm.add_relation(
            rel["src"], rel["dst"],
            rel.get("relation_type", "related_to"),
            description=rel.get("description", ""),
            confidence=rel.get("confidence", 1.0),
            source="reflection",
        )
    gm.save(GRAPH_PATH)
    logger.info("Graph updated with reflection entities.")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="MiLe Reflection Loop — daily session analysis")
    parser.add_argument("--hours", type=int, default=24,
                        help="Hours back to scan (default: 24)")
    parser.add_argument("--dry-run", action="store_true",
                        help="Analyse but do not write any files")
    parser.add_argument("--no-graph", action="store_true",
                        help="Skip GraphRAG update")
    args = parser.parse_args()

    _load_env()
    logger.info("Starting reflection analysis (dry-run=%s)...", args.dry_run)

    text = read_conversations(hours=args.hours)
    if not text:
        logger.warning("No recent conversations found. Exiting.")
        return

    report = analyse_with_deepseek(text)

    save_to_evolution_memory(report, dry_run=args.dry_run)

    if not args.no_graph and not args.dry_run:
        update_graphrag(report, dry_run=args.dry_run)

    # Extract failure cases from high-priority improvement items
    if not args.dry_run:
        from pathlib import Path as _P
        _data_dir = _P(__file__).resolve().parent.parent / "data"
        _case_path = _data_dir / "case_library.json"
        case_library = []
        if _case_path.exists():
            try:
                case_library = json.loads(_case_path.read_text(encoding="utf-8"))
            except (json.JSONDecodeError, OSError):
                pass
        seen = {(c.get("scenario", ""), c.get("bad", "")) for c in case_library}
        new_cases = 0
        for item in report.get("improvement_items", []):
            if item.get("priority") != "high":
                continue
            case = {
                "scenario": item.get("area", ""),
                "bad": item.get("suggestion", ""),
                "good": "",
                "trigger_keywords": [],
                "source": "reflect",
                "session_id": "",
                "created_at": datetime.now(timezone.utc).isoformat(),
            }
            key = (case["scenario"], case["bad"])
            if key not in seen and case["scenario"]:
                case_library.append(case)
                seen.add(key)
                new_cases += 1
        if new_cases:
            _data_dir.mkdir(parents=True, exist_ok=True)
            _case_path.write_text(json.dumps(case_library, ensure_ascii=False, indent=2), encoding="utf-8")
            logger.info("Added %d reflect cases to library.", new_cases)

    # Print summary to stdout
    print(json.dumps(report, ensure_ascii=False, indent=2))
    logger.info("Reflection complete.")


if __name__ == "__main__":
    main()
