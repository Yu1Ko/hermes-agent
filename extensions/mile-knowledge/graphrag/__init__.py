"""MiLe GraphRAG — knowledge graph construction, indexing, and search."""

# Lazy imports — heavy deps (sentence-transformers, openai, etc.) are only loaded
# when needed, so base modules like graph.py work without all dependencies installed.


def __getattr__(name: str):
    if name == "GraphManager":
        from graphrag.graph import GraphManager
        return GraphManager
    if name == "EntityRelationExtractor":
        from graphrag.extractor import EntityRelationExtractor
        return EntityRelationExtractor
    if name == "CommunityIndexer":
        from graphrag.indexer import CommunityIndexer
        return CommunityIndexer
    if name == "QueryEngine":
        from graphrag.indexer import QueryEngine
        return QueryEngine
    if name in ("DEEPSEEK_API_KEY", "DEEPSEEK_BASE_URL", "DEEPSEEK_MODEL",
                "EMBEDDING_API_KEY", "EMBEDDING_API_BASE", "EMBEDDING_API_MODEL", "DATA_DIR"):
        from graphrag import config
        return getattr(config, name)
    raise AttributeError(f"module 'graphrag' has no attribute {name!r}")


__all__ = [
    "GraphManager",
    "EntityRelationExtractor",
    "CommunityIndexer",
    "QueryEngine",
    "DEEPSEEK_API_KEY",
    "DEEPSEEK_BASE_URL",
    "DEEPSEEK_MODEL",
    "EMBEDDING_API_KEY",
    "EMBEDDING_API_BASE",
    "EMBEDDING_API_MODEL",
    "DATA_DIR",
]
