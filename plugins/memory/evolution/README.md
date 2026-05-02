# Evolution Memory Provider

`evolution` is a local SQLite memory provider for lightweight long-term learning in Hermes.
It records completed turns as episodes, extracts conservative durable memories, recalls
matching context with SQLite FTS, and tracks confidence, feedback, and soft deletion.

Enable it with:

```yaml
memory:
  provider: evolution
```

Optional provider settings live under `plugins.evolution` in `config.yaml`:

```yaml
plugins:
  evolution:
    db_path: "$HERMES_HOME/evolution_memory/memory.db"
    max_prefetch: 5
    min_confidence: 0.2
```

The provider intentionally avoids external APIs, embeddings, graph ranking, and LLM-based
extraction. It is meant as a rollback-friendly first step toward layered memory:
episodic, semantic, procedural, and social.

## Tool

`evolution_memory` supports:

- `add`: add a memory with `content`, optional `kind`, `scope`, and `confidence`
- `search`: search memories with `query`
- `feedback`: mark a memory `helpful` or `unhelpful`
- `delete`: soft-delete a memory by `memory_id`
- `stats`: show episode, memory, entity, and relation counts
