"""CLI entry point for MiLe GraphRAG.  Usage: python -m graphrag <command>"""

import argparse
import json
import logging
import sys

from graphrag.config import GRAPH_PATH
from graphrag.graph import GraphManager

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("graphrag.cli")


def cmd_extract(args: argparse.Namespace) -> None:
    """Extract entities from stdin or file and add them to the graph."""
    from graphrag.extractor import EntityRelationExtractor
    extractor = EntityRelationExtractor()
    gm = GraphManager()
    if GRAPH_PATH.exists():
        gm.load(GRAPH_PATH)

    sources: list[tuple[str, str]] = []
    if args.file:
        text = args.file.read()
        sources.append((text, args.file.name))
    if args.text:
        sources.append((args.text, "cli-arg"))
    if not args.file and not args.text:
        text = sys.stdin.read()
        if text.strip():
            sources.append((text, "stdin"))

    if not sources:
        logger.error("No input provided. Use --file, --text, or pipe via stdin.")
        sys.exit(1)

    for text, source in sources:
        result = extractor.extract(text)
        for ent in result.get("entities", []):
            gm.add_entity(
                ent["name"],
                type=ent.get("type", "entity"),
                description=ent.get("description", ""),
                confidence=ent.get("confidence", 1.0),
                source=source,
            )
        for rel in result.get("relations", []):
            gm.add_relation(
                rel["src"],
                rel["dst"],
                rel.get("relation_type", "related_to"),
                description=rel.get("description", ""),
                confidence=rel.get("confidence", 1.0),
                source=source,
            )
        print(json.dumps(result, ensure_ascii=False, indent=2))

    gm.save(GRAPH_PATH)
    logger.info("Graph saved with %d entities, %d relations.",
                gm.graph.number_of_nodes(), gm.graph.number_of_edges())


def cmd_index(args: argparse.Namespace) -> None:
    """Run community detection, summarisation, and build vector index."""
    from graphrag.indexer import CommunityIndexer, QueryEngine
    gm = GraphManager()
    if GRAPH_PATH.exists():
        gm.load(GRAPH_PATH)
    else:
        logger.warning("No graph found at %s — starting with empty graph.", GRAPH_PATH)

    indexer = CommunityIndexer(gm)
    communities = indexer.summarise_all()
    print(json.dumps(communities, ensure_ascii=False, indent=2))

    engine = QueryEngine(gm)
    engine.build_index()
    logger.info("Vector index built.")


def cmd_search(args: argparse.Namespace) -> None:
    """Semantic search over entities."""
    from graphrag.indexer import QueryEngine
    gm = GraphManager()
    if GRAPH_PATH.exists():
        gm.load(GRAPH_PATH)
    else:
        logger.warning("No graph found — search may return empty results.")

    engine = QueryEngine(gm)
    results = engine.semantic_search(args.query, top_k=args.top_k)
    print(json.dumps(results, ensure_ascii=False, indent=2))


def cmd_stats(args: argparse.Namespace) -> None:
    """Print graph statistics."""
    gm = GraphManager()
    if GRAPH_PATH.exists():
        gm.load(GRAPH_PATH)
    print(json.dumps(gm.get_stats(), ensure_ascii=False, indent=2))


def cmd_neighbors(args: argparse.Namespace) -> None:
    """Query neighbours of an entity."""
    gm = GraphManager()
    if GRAPH_PATH.exists():
        gm.load(GRAPH_PATH)
    result = gm.get_neighbors(args.entity, depth=args.depth)
    print(json.dumps(result, ensure_ascii=False, indent=2))


def cmd_list(args: argparse.Namespace) -> None:
    """List all entities or filter by type."""
    gm = GraphManager()
    if GRAPH_PATH.exists():
        gm.load(GRAPH_PATH)
    entities = gm.get_all_entities()
    if args.type:
        entities = [e for e in entities if e.get("type") == args.type]
    for e in entities:
        print(f"{e['name']}  [{e.get('type', 'entity')}]  {e.get('description', '')}")


def cmd_export(args: argparse.Namespace) -> None:
    """Export the full knowledge graph as portable JSON."""
    gm = GraphManager()
    if GRAPH_PATH.exists():
        gm.load(GRAPH_PATH)
    graph = gm.graph
    nodes = []
    for n, attrs in graph.nodes(data=True):
        node = {"id": n}
        node.update({k: v for k, v in attrs.items()})
        nodes.append(node)
    edges = []
    for u, v, attrs in graph.edges(data=True):
        edge = {"source": u, "target": v, "relation": attrs.get("relation_type", "related_to")}
        edges.append(edge)
    output = {"nodes": nodes, "edges": edges, "stats": gm.get_stats()}
    out_path = args.output
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(output, f, ensure_ascii=False, indent=2)
    print(f"Graph exported to {out_path}: {len(nodes)} nodes, {len(edges)} edges")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="MiLe GraphRAG — knowledge graph CLI",
        prog="python -m graphrag",
    )
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("extract", help="Extract entities/relations from text")
    p.add_argument("--file", type=argparse.FileType("r"), help="Input file")
    p.add_argument("--text", help="Direct text input")
    p.set_defaults(func=cmd_extract)

    p = sub.add_parser("index", help="Community detection + vector index build")
    p.set_defaults(func=cmd_index)

    p = sub.add_parser("search", help="Semantic search over entities")
    p.add_argument("query", help="Search query")
    p.add_argument("--top-k", type=int, default=5, help="Number of results")
    p.set_defaults(func=cmd_search)

    p = sub.add_parser("stats", help="Show graph statistics")
    p.set_defaults(func=cmd_stats)

    p = sub.add_parser("neighbors", help="Query entity neighbors")
    p.add_argument("entity", help="Entity name")
    p.add_argument("--depth", type=int, default=1, help="Hop depth")
    p.set_defaults(func=cmd_neighbors)

    p = sub.add_parser("list", help="List entities")
    p.add_argument("--type", help="Filter by entity type")
    p.set_defaults(func=cmd_list)

    p = sub.add_parser("export", help="Export graph to JSON")
    p.add_argument("--output", default="graph_export.json", help="Output file path")
    p.set_defaults(func=cmd_export)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
