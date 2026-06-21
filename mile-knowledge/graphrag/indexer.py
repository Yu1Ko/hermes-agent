"""Community detection, summarisation, and semantic search."""

import json
import logging
from typing import Any

import community as community_louvain  # python-louvain
import networkx as nx
import numpy as np

from graphrag.config import (
    DEEPSEEK_API_KEY,
    DEEPSEEK_BASE_URL,
    DEEPSEEK_MODEL,
    COMMUNITIES_PATH,
    EMBEDDINGS_PATH,
)
from graphrag.embedding import embed_texts, cosine_similarity
from graphrag.graph import GraphManager

logger = logging.getLogger(__name__)


class CommunityIndexer:
    """Detects communities in the graph and generates summaries via DeepSeek."""

    def __init__(self, graph_manager: GraphManager) -> None:
        self.gm = graph_manager
        if DEEPSEEK_API_KEY:
            from openai import OpenAI

            self.llm = OpenAI(api_key=DEEPSEEK_API_KEY, base_url=DEEPSEEK_BASE_URL)
        else:
            self.llm = None

    def detect_communities(self) -> dict[int, list[str]]:
        """Run Louvain community detection. Returns {community_id: [node_names]}."""
        if self.gm.graph.number_of_nodes() == 0:
            logger.warning("Graph is empty — skipping community detection.")
            return {}
        undirected = self.gm.graph.to_undirected()
        partition = community_louvain.best_partition(undirected)
        communities: dict[int, list[str]] = {}
        for node, comm_id in partition.items():
            communities.setdefault(comm_id, []).append(node)
        logger.info("Detected %d communities.", len(communities))
        return communities

    def _summarise_community(self, comm_id: int, nodes: list[str]) -> dict[str, Any]:
        """Generate a text summary for one community."""
        entity_descriptions: list[str] = []
        for name in nodes:
            attrs = self.gm.query_entity(name)
            if attrs:
                entity_descriptions.append(
                    f"- {name} ({attrs.get('type', 'entity')}): {attrs.get('description', '无描述')}"
                )

        if not self.llm:
            return {
                "community_id": comm_id,
                "size": len(nodes),
                "members": nodes,
                "summary": "; ".join(nodes),
            }

        prompt = f"""社区中有以下实体，请用 2-3 句中文总结这个社区的主题和关联：

实体列表：
{chr(10).join(entity_descriptions)}

请直接返回总结文字，不要 JSON。"""

        try:
            response = self.llm.chat.completions.create(
                model=DEEPSEEK_MODEL,
                messages=[{"role": "user", "content": prompt}],
                temperature=0.3,
                max_tokens=512,
            )
            summary = response.choices[0].message.content.strip()
        except Exception:
            logger.exception("Failed to summarise community %d.", comm_id)
            summary = f"Community {comm_id}: {len(nodes)} entities"

        return {
            "community_id": comm_id,
            "size": len(nodes),
            "members": nodes,
            "summary": summary,
        }

    def summarise_all(self) -> list[dict[str, Any]]:
        """Detect communities and summarise each one."""
        communities = self.detect_communities()
        results: list[dict[str, Any]] = []
        for comm_id, nodes in communities.items():
            logger.info(
                "Summarising community %d (%d entities)...", comm_id, len(nodes)
            )
            results.append(self._summarise_community(comm_id, nodes))
        self._save_communities(results)
        return results

    def _save_communities(self, data: list[dict[str, Any]]) -> None:
        COMMUNITIES_PATH.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
        logger.info("Community summaries saved to %s.", COMMUNITIES_PATH)


class QueryEngine:
    """Semantic search over entities using embedding API."""

    def __init__(self, graph_manager: GraphManager) -> None:
        self.gm = graph_manager
        self._entity_names: list[str] = []
        self._embeddings: np.ndarray | None = None

    def build_index(self) -> None:
        """Encode all entity descriptions via API into a vector index."""
        entities = self.gm.get_all_entities()
        if not entities:
            logger.warning("No entities to index.")
            self._entity_names = []
            self._embeddings = None
            return
        descriptions = [
            f"{e['name']}: {e.get('description', '')}" for e in entities
        ]
        self._entity_names = [e["name"] for e in entities]
        self._embeddings = embed_texts(descriptions)
        self._save_embeddings()
        logger.info("Index built with %d entity vectors.", len(self._entity_names))

    def _save_embeddings(self) -> None:
        if self._embeddings is None:
            return
        np.savez(
            EMBEDDINGS_PATH,
            embeddings=self._embeddings,
            names=np.array(self._entity_names, dtype=object),
        )

    def load_index(self) -> bool:
        """Load cached embeddings. Returns True if successful."""
        if not EMBEDDINGS_PATH.exists():
            logger.info("No cached embeddings found at %s.", EMBEDDINGS_PATH)
            return False
        data = np.load(EMBEDDINGS_PATH, allow_pickle=True)
        self._embeddings = data["embeddings"]
        self._entity_names = list(data["names"])
        logger.info("Loaded %d cached embeddings.", len(self._entity_names))
        return True

    def semantic_search(self, query: str, top_k: int = 5) -> list[dict[str, Any]]:
        """Return top_k entities ranked by cosine similarity to query."""
        if self._embeddings is None:
            if not self.load_index():
                return []
        assert self._embeddings is not None
        query_vec = embed_texts([query])
        scores = cosine_similarity(query_vec, self._embeddings)[0]
        top_indices = np.argsort(scores)[::-1][:top_k]

        results: list[dict[str, Any]] = []
        for idx in top_indices:
            if scores[idx] <= 0:
                continue
            name = self._entity_names[idx]
            entity = self.gm.query_entity(name)
            results.append(
                {
                    "name": name,
                    "score": float(scores[idx]),
                    "description": entity.get("description", "") if entity else "",
                    "type": entity.get("type", "entity") if entity else "entity",
                }
            )
        return results
