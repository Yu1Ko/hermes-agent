#!/usr/bin/env python3
"""Memory consolidation — merges similar evolution entries, promotes high-confidence ones.

Runs daily. Scans ~/.hermes/evolution_memory/ for candidate entries:
- Similarity > 0.7 → merge (keep the newest, aggregate notes)
- 30+ days stale → demote / archive
- High-confidence items → promote to ~/.hermes/memories/ (MEMORY.md format)
- Syncs relevant entities back into GraphRAG.
"""

import argparse
import json
import logging
import os
import sys
from datetime import datetime, timezone, timedelta
from pathlib import Path
from typing import Any

import numpy as np

# Will be imported lazily when needed
_embed_texts = None
_cosine_similarity = None


def _get_embed_funcs():
    """Lazy-load embedding helpers ( avoids import at module level for CLI --help )."""
    global _embed_texts, _cosine_similarity
    if _embed_texts is None:
        sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
        from graphrag.embedding import embed_texts as et, cosine_similarity as cs
        _embed_texts = et
        _cosine_similarity = cs
    return _embed_texts, _cosine_similarity


def compute_similarity_vec(vecs: np.ndarray, i: int, j: int) -> float:
    """Compute cosine similarity between pre-computed vectors i and j."""
    cs = _cosine_similarity
    if cs is None:
        _, cs = _get_embed_funcs()
    a = vecs[i:i+1]
    b = vecs[j:j+1]
    return float(cs(a, b)[0][0])

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] consolidate: %(message)s",
)
logger = logging.getLogger("consolidate")

EVOLUTION_DIR = Path.home() / ".hermes" / "evolution_memory"
MEMORIES_DIR = Path.home() / ".hermes" / "memories"
DATA_DIR = Path(__file__).resolve().parent.parent / "data"


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


def load_candidates() -> list[dict[str, Any]]:
    """Load all JSON files from evolution_memory as candidates."""
    if not EVOLUTION_DIR.is_dir():
        logger.warning("evolution_memory directory does not exist.")
        return []
    candidates: list[dict[str, Any]] = []
    for f in sorted(EVOLUTION_DIR.iterdir()):
        if not f.is_file() or f.suffix != ".json":
            continue
        try:
            data = json.loads(f.read_text(encoding="utf-8"))
            data["_file"] = str(f)
            data["_name"] = f.name
            candidates.append(data)
        except (json.JSONDecodeError, OSError):
            logger.warning("Could not parse %s.", f)
    logger.info("Loaded %d evolution candidates.", len(candidates))
    return candidates


def compute_similarity(
    a: dict[str, Any], b: dict[str, Any], _model: Any = None
) -> float:
    """Deprecated — kept for signature compatibility. Use compute_similarity_vec."""
    raise NotImplementedError("Use compute_similarity_vec with pre-computed vectors")


def merge_candidates(candidates: list[dict[str, Any]], threshold: float = 0.7) -> dict[str, Any]:
    """Group and merge similar candidates using embedding API."""
    embed_fn, _ = _get_embed_funcs()

    # Batch-encode all candidate texts at once
    texts: list[str] = []
    for c in candidates:
        texts.append(json.dumps(c.get("report", c), ensure_ascii=False, default=str))

    if texts:
        vecs = embed_fn(texts)
    else:
        vecs = np.empty((0, 0))

    kept: list[dict[str, Any]] = []
    merged: list[dict[str, Any]] = []
    stale: list[dict[str, Any]] = []
    promoted: list[dict[str, Any]] = []

    stale_cutoff = datetime.now() - timedelta(days=30)

    # Track merge groups by similarity
    used = set()

    for i, cand in enumerate(candidates):
        if i in used:
            continue
        group = [cand]
        for j in range(i + 1, len(candidates)):
            if j in used:
                continue
            sim = compute_similarity_vec(vecs, i, j)
            if sim > threshold:
                group.append(candidates[j])
                used.add(j)
                logger.info("Merging %s ⇔ %s (similarity=%.3f)", cand.get("_name"), candidates[j].get("_name"), sim)

        if len(group) > 1:
            # Merge: keep newest, aggregate
            newest = max(group, key=lambda g: g.get("timestamp", ""))
            newest["_merged_from"] = [g.get("_name") for g in group if g is not newest]
            merged.append(newest)
        else:
            kept.append(cand)

    # Identify stale items
    for cand in kept:
        ts_str = cand.get("timestamp", "")
        try:
            ts = datetime.fromisoformat(ts_str)
            if ts < stale_cutoff:
                stale.append(cand)
            else:
                pass  # stays in kept
        except (ValueError, TypeError):
            pass

    kept = [c for c in kept if c not in stale]

    # Promote high-confidence items
    for cand in kept + merged:
        report = cand.get("report", {})
        improvements = report.get("improvement_items", [])
        if improvements:
            # Items with high priority = candidate for promotion
            high_priority = [item for item in improvements if item.get("priority") == "high"]
            if high_priority:
                promoted.append({
                    "source": cand.get("_name", "unknown"),
                    "items": high_priority,
                    "summary": report.get("summary", ""),
                })

    return {
        "kept": len(kept),
        "merged": len(merged),
        "stale": len(stale),
        "promoted": len(promoted),
        "merged_details": [m.get("_name") for m in merged],
        "stale_details": [s.get("_name") for s in stale],
        "promoted_items": promoted,
    }


def write_memories(promoted_items: list[dict[str, Any]], dry_run: bool = False) -> list[Path]:
    """Write promoted items to ~/.hermes/memories/ in MEMORY.md format."""
    MEMORIES_DIR.mkdir(parents=True, exist_ok=True)
    written: list[Path] = []

    for entry in promoted_items:
        for item in entry.get("items", []):
            area = item.get("area", "general").replace(" ", "_").lower()
            suggestion = item.get("suggestion", "No details")
            filename = f"mi_learned_{area}.md"

            content = f"""---
name: {area}
description: MiLe learned insight about {area}
type: project
---

**From:** {entry.get('source', 'unknown')}
**Priority:** {item.get('priority', 'medium')}

{suggestion}
"""
            path = MEMORIES_DIR / filename
            if not dry_run:
                path.write_text(content, encoding="utf-8")
                logger.info("Promoted memory → %s", path)
            else:
                logger.info("[DRY-RUN] Would write memory → %s", path)
            written.append(path)

    return written


def update_graphrag(result: dict[str, Any], dry_run: bool = False) -> None:
    """Update GraphRAG with consolidated entities."""
    try:
        from graphrag.config import GRAPH_PATH
        from graphrag.graph import GraphManager
        from graphrag.extractor import EntityRelationExtractor
    except ImportError:
        logger.warning("graphrag package not available.")
        return

    gm = GraphManager()
    if GRAPH_PATH.exists():
        gm.load(GRAPH_PATH)

    extractor = EntityRelationExtractor()
    text = json.dumps(result.get("promoted_items", []), ensure_ascii=False, default=str)

    if not text.strip() or text == "[]":
        return

    if dry_run:
        logger.info("[DRY-RUN] Would update GraphRAG with consolidated entities.")
        return

    extracted = extractor.extract(text)
    for ent in extracted.get("entities", []):
        gm.add_entity(
            ent["name"],
            type=ent.get("type", "concept"),
            description=ent.get("description", ""),
            confidence=ent.get("confidence", 1.0),
            source="consolidation",
        )
    for rel in extracted.get("relations", []):
        gm.add_relation(
            rel["src"], rel["dst"],
            rel.get("relation_type", "related_to"),
            description=rel.get("description", ""),
            confidence=rel.get("confidence", 1.0),
            source="consolidation",
        )
    gm.save(GRAPH_PATH)
    logger.info("Graph updated with consolidation entities.")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="MiLe Memory Consolidation — merge, demote, promote")
    parser.add_argument("--threshold", type=float, default=0.7,
                        help="Similarity threshold for merging (default: 0.7)")
    parser.add_argument("--dry-run", action="store_true",
                        help="Analyse but do not write files")
    parser.add_argument("--no-graph", action="store_true",
                        help="Skip GraphRAG update")
    parser.add_argument("--min-score", type=float, default=7.0,
                        help="Minimum evaluation score for memory promotion (default: 7)")
    args = parser.parse_args()

    _load_env()
    logger.info("Starting consolidation (dry-run=%s, threshold=%.2f)...",
                args.dry_run, args.threshold)

    candidates = load_candidates()
    if not candidates:
        logger.warning("No evolution candidates found.")
        return

    # Filter by eval score: read daily_eval reports and check source session scores
    if not args.dry_run:
        _eval_dir = DATA_DIR
        _archived_dir = _eval_dir / "archived"
        _archived_dir.mkdir(parents=True, exist_ok=True)
        _eval_files = sorted(_eval_dir.glob("daily_eval_*.json"))
        _session_scores: dict[str, float] = {}
        for _ef in _eval_files[-7:]:  # last 7 days
            try:
                _ed = json.loads(_ef.read_text(encoding="utf-8"))
                for _s in _ed.get("per_session", []):
                    sid = _s.get("session", "")
                    avg = (_s.get("accuracy", 0) + _s.get("consistency", 0) + _s.get("responsiveness", 0)) / 3
                    _session_scores[sid] = avg
            except (json.JSONDecodeError, OSError):
                pass
        _passed = []
        _archived_count = 0
        for c in candidates:
            sid = c.get("session_id", "")
            if sid and _session_scores.get(sid, 10) < args.min_score:
                _archived_dir.mkdir(parents=True, exist_ok=True)
                (_archived_dir / f"{sid}.json").write_text(
                    json.dumps(c, ensure_ascii=False, indent=2, default=str), encoding="utf-8")
                _archived_count += 1
                continue
            _passed.append(c)
        if _archived_count:
            logger.info("Archived %d low-score candidates (min_score=%.1f).", _archived_count, args.min_score)
        candidates = _passed

    result = merge_candidates(candidates, threshold=args.threshold)

    write_memories(result.get("promoted_items", []), dry_run=args.dry_run)

    if not args.no_graph and not args.dry_run:
        update_graphrag(result)

    print(json.dumps(result, ensure_ascii=False, indent=2, default=str))
    logger.info("Consolidation complete. kept=%d merged=%d stale=%d promoted=%d",
                result["kept"], result["merged"], result["stale"], result["promoted"])


if __name__ == "__main__":
    main()
