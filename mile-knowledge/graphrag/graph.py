"""GraphManager — NetworkX-backed knowledge graph operations."""

import pickle
import logging
from datetime import datetime, timezone
from typing import Any

import networkx as nx

logger = logging.getLogger(__name__)


class GraphManager:
    """Encapsulates a NetworkX DiGraph for entity-relation knowledge storage."""

    def __init__(self) -> None:
        self.graph = nx.DiGraph()

    # -- mutation -----------------------------------------------------------

    def add_entity(self, name: str, **attrs: Any) -> str:
        """Add or update a node. Returns the node name."""
        defaults: dict[str, Any] = {
            "type": "entity",
            "description": "",
            "confidence": 1.0,
            "source": "manual",
            "created_at": datetime.now(timezone.utc).isoformat(),
        }
        defaults.update(attrs)
        self.graph.add_node(name, **defaults)
        logger.debug("Entity %s added/updated.", name)
        return name

    def add_relation(
        self, src: str, dst: str, relation_type: str, **attrs: Any
    ) -> tuple[str, str, str]:
        """Add or update a directed edge. Returns (src, dst, relation_type)."""
        defaults: dict[str, Any] = {
            "description": "",
            "confidence": 1.0,
            "source": "manual",
            "created_at": datetime.now(timezone.utc).isoformat(),
        }
        defaults.update(attrs)
        self.graph.add_edge(src, dst, relation_type=relation_type, **defaults)
        logger.debug("Relation %s -[%s]-> %s added.", src, relation_type, dst)
        return src, dst, relation_type

    # -- query --------------------------------------------------------------

    def query_entity(self, name: str) -> dict[str, Any] | None:
        """Return node attributes, or None if the entity doesn't exist."""
        if name not in self.graph:
            return None
        return dict(self.graph.nodes[name])

    def get_neighbors(self, name: str, depth: int = 1) -> dict[str, Any]:
        """Return neighbours up to *depth* hops with edge data."""
        if name not in self.graph:
            return {"entity": name, "neighbors": [], "error": "not found"}
        result: dict[str, Any] = {"entity": name, "neighbors": []}
        for n in self.graph.neighbors(name):
            edge_data = self.graph.get_edge_data(name, n)
            result["neighbors"].append({"node": n, "edge": edge_data})
        return result

    def search_by_type(self, entity_type: str) -> list[str]:
        """Return all entity names of a given type."""
        return [
            n
            for n, attrs in self.graph.nodes(data=True)
            if attrs.get("type") == entity_type
        ]

    def get_all_entities(self) -> list[dict[str, Any]]:
        """Return all entities with their attributes."""
        return [
            {"name": n, **attrs} for n, attrs in self.graph.nodes(data=True)
        ]

    def get_all_relations(self) -> list[dict[str, Any]]:
        """Return all relations with their attributes."""
        return [
            {"src": u, "dst": v, **data}
            for u, v, data in self.graph.edges(data=True)
        ]

    def get_stats(self) -> dict[str, Any]:
        """Return basic graph statistics."""
        return {
            "num_entities": self.graph.number_of_nodes(),
            "num_relations": self.graph.number_of_edges(),
            "density": self.graph.number_of_nodes()
            and round(
                self.graph.number_of_edges()
                / self.graph.number_of_nodes(),
                4,
            )
            or 0,
            "entity_types": list(
                {attrs.get("type", "entity") for _, attrs in self.graph.nodes(data=True)}
            ),
        }

    # -- persistence --------------------------------------------------------

    def save(self, path: str) -> None:
        """Pickle the graph to *path*."""
        with open(path, "wb") as f:
            pickle.dump(self.graph, f)
        logger.info("Graph saved to %s.", path)

    def load(self, path: str) -> None:
        """Load a pickled graph from *path*."""
        with open(path, "rb") as f:
            self.graph = pickle.load(f)
        logger.info("Graph loaded from %s (%d nodes, %d edges).",
                    path, self.graph.number_of_nodes(), self.graph.number_of_edges())
