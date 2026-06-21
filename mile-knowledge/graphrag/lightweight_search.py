"""Lightweight graphrag search for evolution provider prefetch.

Caches the QueryEngine so embedding vectors persist in memory,"
not on every prefetch call (~every turn of every session).
"""

import logging
from pathlib import Path
from typing import Any

logger = logging.getLogger("graphrag.lightweight")

_engine: Any = None  # lazily initialized QueryEngine


def _init_engine() -> Any:
    """Initialize the cached QueryEngine. Called once at first search."""
    from graphrag.config import GRAPH_PATH
    from graphrag.graph import GraphManager
    from graphrag.indexer import QueryEngine

    gm = GraphManager()
    if GRAPH_PATH.exists():
        gm.load(GRAPH_PATH)
    else:
        logger.info("GraphRAG graph not found at %s, search disabled.", GRAPH_PATH)
        return None

    engine = QueryEngine(gm)
    if not engine.load_index():
        logger.info("GraphRAG index not built yet, search disabled.")
        return None

    logger.info("GraphRAG lightweight search engine initialized.")
    return engine


def graphrag_search(query: str, top_k: int = 3) -> list[dict[str, Any]]:
    """Search graphrag knowledge graph with caching.

    Returns list of {name, score, description, type} or empty list on failure.
    """
    global _engine
    if _engine is None:
        _engine = _init_engine()
    if _engine is None:
        return []

    try:
        return _engine.semantic_search(query, top_k=top_k)
    except Exception as exc:
        logger.debug("GraphRAG search failed: %s", exc)
        return []


def graphrag_prefetch_block(query: str, top_k: int = 3) -> str:
    """Return a formatted markdown block for injection into system prompt.

    Returns empty string if no results or graph unavailable.
    """
    results = graphrag_search(query, top_k=top_k)
    if not results:
        return ""

    lines = ["## Knowledge Graph (GraphRAG)"]
    for r in results:
        score = r.get("score", 0)
        name = r.get("name", "?")
        desc = r.get("description", "")
        lines.append(f"- **{name}** (score={score:.2f}): {desc}")

    return "\n".join(lines)
