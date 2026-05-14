"""GraphRAG semantic search tool — query MiLe's knowledge graph.

Requires ~/.hermes/mile-knowledge/graphrag/ to be functional
(NetworkX graph + sentence-transformers embeddings index).
"""

import json
import os
import subprocess
import sys
from pathlib import Path

from tools.registry import registry

MILE_KNOWLEDGE = Path.home() / ".hermes" / "mile-knowledge"
GRAPH_DATA = MILE_KNOWLEDGE / "data" / "graph.pkl"


def check_requirements() -> bool:
    """Tool is available if the knowledge graph data exists."""
    return GRAPH_DATA.exists()


def graphrag_search(
    query: str,
    top_k: int = 5,
    task_id: str | None = None,
) -> str:
    """Run semantic search against MiLe's knowledge graph."""
    if not MILE_KNOWLEDGE.is_dir():
        return json.dumps({"error": "mile-knowledge directory not found"})

    if not GRAPH_DATA.exists():
        return json.dumps({
            "error": "graph.pkl not found — run 'python -m graphrag index' first",
            "results": [],
        })

    python = sys.executable or "python3"

    try:
        result = subprocess.run(
            [python, "-m", "graphrag", "search", query, "--top-k", str(top_k)],
            capture_output=True,
            text=True,
            timeout=30,
            cwd=str(MILE_KNOWLEDGE),
        )
        if result.returncode != 0:
            return json.dumps({
                "error": f"graphrag search failed (exit {result.returncode})",
                "stderr": result.stderr[:500],
            })
        return result.stdout.strip()
    except subprocess.TimeoutExpired:
        return json.dumps({"error": "graphrag search timed out"})
    except FileNotFoundError:
        return json.dumps({"error": f"python not found: {python}"})
    except Exception as exc:
        return json.dumps({"error": str(exc)})


GRAPH_SEARCH_SCHEMA = {
    "name": "graphrag_search",
    "description": (
        "Search MiLe's knowledge graph for entities semantically related "
        "to a query. The graph stores facts about MiLe's personality, "
        "users, technical systems, and past lessons. "
        "Use this when you need to recall connected knowledge — "
        "relationships between entities, community summaries, or "
        "semantically similar concepts that keyword search would miss.\n\n"
        "Returns ranked results with entity names, similarity scores, "
        "descriptions, and types."
    ),
    "parameters": {
        "type": "object",
        "properties": {
            "query": {
                "type": "string",
                "description": "Natural-language search query (e.g. 'MiLe 的分段规则', 'QQ Bot 配置')",
            },
            "top_k": {
                "type": "integer",
                "description": "Number of results to return (default: 5, max: 10)",
                "default": 5,
                "minimum": 1,
                "maximum": 10,
            },
        },
        "required": ["query"],
    },
}


registry.register(
    name="graphrag_search",
    toolset="graphrag",
    schema=GRAPH_SEARCH_SCHEMA,
    handler=lambda args, **kw: graphrag_search(
        query=args.get("query", ""),
        top_k=args.get("top_k", 5),
        task_id=kw.get("task_id"),
    ),
    check_fn=check_requirements,
    requires_env=[],
    emoji="🔍",
)
