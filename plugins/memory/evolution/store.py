"""SQLite store for the local Evolution memory provider."""

from __future__ import annotations

import json
import re
import sqlite3
import threading
from pathlib import Path
from typing import Any


_TOKEN_RE = re.compile(r"[A-Za-z0-9_]+|[\u4e00-\u9fff]+")
_ENTITY_RE = re.compile(r"\b[A-Z][A-Za-z0-9_]*(?:\s+[A-Z][A-Za-z0-9_]*)*\b")
_QUOTED_RE = re.compile(r'"([^"]+)"|\'([^\']+)\'')

_SCHEMA = """
CREATE TABLE IF NOT EXISTS episodes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL DEFAULT '',
    user_content TEXT NOT NULL DEFAULT '',
    assistant_content TEXT NOT NULL DEFAULT '',
    metadata_json TEXT NOT NULL DEFAULT '{}',
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS memories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    kind TEXT NOT NULL,
    content TEXT NOT NULL,
    content_key TEXT NOT NULL UNIQUE,
    source TEXT NOT NULL DEFAULT '',
    scope TEXT NOT NULL DEFAULT 'workspace',
    confidence REAL NOT NULL DEFAULT 0.6,
    session_id TEXT NOT NULL DEFAULT '',
    episode_id INTEGER REFERENCES episodes(id),
    metadata_json TEXT NOT NULL DEFAULT '{}',
    retrieval_count INTEGER NOT NULL DEFAULT 0,
    helpful_count INTEGER NOT NULL DEFAULT 0,
    unhelpful_count INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TEXT,
    delete_reason TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS entities (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS relations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    source_entity_id INTEGER NOT NULL REFERENCES entities(id),
    target_entity_id INTEGER NOT NULL REFERENCES entities(id),
    relation TEXT NOT NULL DEFAULT 'related_to',
    memory_id INTEGER NOT NULL REFERENCES memories(id),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(source_entity_id, target_entity_id, relation, memory_id)
);

CREATE TABLE IF NOT EXISTS feedback (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    memory_id INTEGER NOT NULL REFERENCES memories(id),
    rating TEXT NOT NULL,
    note TEXT NOT NULL DEFAULT '',
    old_confidence REAL NOT NULL,
    new_confidence REAL NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS retrieval_events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    query TEXT NOT NULL,
    memory_ids_json TEXT NOT NULL DEFAULT '[]',
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE VIRTUAL TABLE IF NOT EXISTS memories_fts
    USING fts5(content, kind, source, scope, content=memories, content_rowid=id);

CREATE TRIGGER IF NOT EXISTS memories_ai AFTER INSERT ON memories BEGIN
    INSERT INTO memories_fts(rowid, content, kind, source, scope)
    VALUES (new.id, new.content, new.kind, new.source, new.scope);
END;

CREATE TRIGGER IF NOT EXISTS memories_ad AFTER DELETE ON memories BEGIN
    INSERT INTO memories_fts(memories_fts, rowid, content, kind, source, scope)
    VALUES ('delete', old.id, old.content, old.kind, old.source, old.scope);
END;

CREATE TRIGGER IF NOT EXISTS memories_au AFTER UPDATE ON memories BEGIN
    INSERT INTO memories_fts(memories_fts, rowid, content, kind, source, scope)
    VALUES ('delete', old.id, old.content, old.kind, old.source, old.scope);
    INSERT INTO memories_fts(rowid, content, kind, source, scope)
    VALUES (new.id, new.content, new.kind, new.source, new.scope);
END;

CREATE INDEX IF NOT EXISTS idx_memories_kind ON memories(kind);
CREATE INDEX IF NOT EXISTS idx_memories_scope ON memories(scope);
CREATE INDEX IF NOT EXISTS idx_memories_confidence ON memories(confidence DESC);
CREATE INDEX IF NOT EXISTS idx_memories_deleted ON memories(deleted_at);

CREATE TABLE IF NOT EXISTS expressions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    situation TEXT NOT NULL,
    style TEXT NOT NULL,
    context_list_json TEXT NOT NULL DEFAULT '[]',
    count INTEGER NOT NULL DEFAULT 1,
    checked INTEGER NOT NULL DEFAULT 0,
    rejected INTEGER NOT NULL DEFAULT 0,
    source TEXT NOT NULL DEFAULT '',
    scope TEXT NOT NULL DEFAULT 'workspace',
    session_id TEXT NOT NULL DEFAULT '',
    deleted_at TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_expressions_scope ON expressions(scope);
CREATE INDEX IF NOT EXISTS idx_expressions_count ON expressions(count DESC);
CREATE INDEX IF NOT EXISTS idx_expressions_updated ON expressions(updated_at DESC);
"""


def _clamp_confidence(value: float) -> float:
    return max(0.0, min(1.0, float(value)))


def _json_dumps(value: dict[str, Any] | None) -> str:
    return json.dumps(value or {}, ensure_ascii=False, sort_keys=True)


def _content_key(kind: str, scope: str, content: str) -> str:
    normalized = " ".join(content.strip().lower().split())
    return f"{kind.strip().lower()}:{scope.strip().lower()}:{normalized}"


def _expression_key(situation: str, style: str) -> str:
    """Normalize situation+style into a dedup key."""
    sit = " ".join((situation or "").strip().lower().split())
    sty = " ".join((style or "").strip().lower().split())
    return f"{sit}|||{sty}"


def _fts_query(query: str) -> str:
    tokens = _TOKEN_RE.findall(query or "")
    return " AND ".join(tokens)


class EvolutionMemoryStore:
    """Profile-scoped SQLite storage for lightweight long-term memory."""

    def __init__(self, db_path: str | Path) -> None:
        self.db_path = Path(db_path).expanduser()
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        self._lock = threading.RLock()
        self._conn = sqlite3.connect(
            str(self.db_path),
            check_same_thread=False,
            timeout=10.0,
        )
        self._conn.row_factory = sqlite3.Row
        self._init_db()

    def _init_db(self) -> None:
        with self._lock:
            self._conn.execute("PRAGMA journal_mode=WAL")
            self._conn.executescript(_SCHEMA)
            self._conn.commit()

    def record_episode(
        self,
        *,
        session_id: str,
        user_content: str,
        assistant_content: str,
        metadata: dict[str, Any] | None = None,
    ) -> int:
        with self._lock:
            cur = self._conn.execute(
                """
                INSERT INTO episodes (session_id, user_content, assistant_content, metadata_json)
                VALUES (?, ?, ?, ?)
                """,
                (session_id or "", user_content or "", assistant_content or "", _json_dumps(metadata)),
            )
            self._conn.commit()
            return int(cur.lastrowid)

    def upsert_memory(
        self,
        *,
        kind: str,
        content: str,
        source: str,
        scope: str,
        confidence: float = 0.6,
        session_id: str = "",
        episode_id: int | None = None,
        metadata: dict[str, Any] | None = None,
        restore_deleted: bool = False,
    ) -> int:
        content = content.strip()
        if not content:
            raise ValueError("content must not be empty")
        kind = (kind or "semantic").strip().lower()
        scope = (scope or "workspace").strip().lower()
        key = _content_key(kind, scope, content)
        confidence = _clamp_confidence(confidence)

        with self._lock:
            existing = self._conn.execute(
                "SELECT id, deleted_at FROM memories WHERE content_key = ?",
                (key,),
            ).fetchone()
            if existing is not None:
                memory_id = int(existing["id"])
                if existing["deleted_at"] is not None and not restore_deleted:
                    return memory_id
                should_restore = 1 if restore_deleted else 0
                self._conn.execute(
                    """
                    UPDATE memories
                    SET content = ?,
                        source = ?,
                        confidence = MAX(confidence, ?),
                        session_id = COALESCE(NULLIF(?, ''), session_id),
                        episode_id = COALESCE(?, episode_id),
                        metadata_json = ?,
                        updated_at = CURRENT_TIMESTAMP,
                        deleted_at = CASE WHEN ? THEN NULL ELSE deleted_at END,
                        delete_reason = CASE WHEN ? THEN '' ELSE delete_reason END
                    WHERE id = ?
                    """,
                    (
                        content,
                        source or "",
                        confidence,
                        session_id or "",
                        episode_id,
                        _json_dumps(metadata),
                        should_restore,
                        should_restore,
                        memory_id,
                    ),
                )
                self._conn.commit()
                self._link_entities(memory_id, content)
                return memory_id

            cur = self._conn.execute(
                """
                INSERT INTO memories (
                    kind, content, content_key, source, scope, confidence,
                    session_id, episode_id, metadata_json, deleted_at, delete_reason
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NULL, '')
                RETURNING id
                """,
                (
                    kind,
                    content,
                    key,
                    source or "",
                    scope,
                    confidence,
                    session_id or "",
                    episode_id,
                    _json_dumps(metadata),
                ),
            )
            row = cur.fetchone()
            self._conn.commit()
            memory_id = int(row["id"])
            self._link_entities(memory_id, content)
            return memory_id

    def search(
        self,
        query: str,
        *,
        kind: str | None = None,
        scope: str | None = None,
        min_confidence: float = 0.0,
        limit: int = 5,
    ) -> list[dict[str, Any]]:
        fts = _fts_query(query)
        if not fts:
            return []
        limit = max(1, min(int(limit or 5), 50))

        clauses = ["m.deleted_at IS NULL", "m.confidence >= ?"]
        params: list[Any] = [fts, _clamp_confidence(min_confidence)]
        if kind:
            clauses.append("m.kind = ?")
            params.append(kind)
        if scope:
            clauses.append("m.scope = ?")
            params.append(scope)
        params.append(limit)

        sql = f"""
            SELECT m.id, m.kind, m.content, m.source, m.scope, m.confidence,
                   m.session_id, m.episode_id, m.metadata_json, m.retrieval_count,
                   m.helpful_count, m.unhelpful_count, m.created_at, m.updated_at
            FROM memories m
            JOIN memories_fts fts ON fts.rowid = m.id
            WHERE memories_fts MATCH ?
              AND {' AND '.join(clauses)}
            ORDER BY fts.rank, m.confidence DESC, m.updated_at DESC
            LIMIT ?
        """

        with self._lock:
            try:
                rows = self._conn.execute(sql, params).fetchall()
            except sqlite3.OperationalError:
                rows = self._fallback_like_search(
                    query,
                    kind=kind,
                    scope=scope,
                    min_confidence=min_confidence,
                    limit=limit,
                )
            results = [self._row_to_memory(row) for row in rows]
            self._record_retrieval(query, [item["id"] for item in results])
            return results

    def record_feedback(self, memory_id: int, *, rating: str, note: str = "") -> dict[str, Any]:
        rating = (rating or "").strip().lower()
        if rating not in {"helpful", "unhelpful"}:
            raise ValueError("rating must be 'helpful' or 'unhelpful'")

        with self._lock:
            row = self._conn.execute(
                "SELECT id, confidence, helpful_count, unhelpful_count FROM memories WHERE id = ?",
                (int(memory_id),),
            ).fetchone()
            if row is None:
                raise KeyError(f"memory_id {memory_id} not found")

            old_confidence = float(row["confidence"])
            delta = 0.08 if rating == "helpful" else -0.15
            new_confidence = _clamp_confidence(old_confidence + delta)
            helpful_delta = 1 if rating == "helpful" else 0
            unhelpful_delta = 1 if rating == "unhelpful" else 0
            self._conn.execute(
                """
                UPDATE memories
                SET confidence = ?,
                    helpful_count = helpful_count + ?,
                    unhelpful_count = unhelpful_count + ?,
                    updated_at = CURRENT_TIMESTAMP
                WHERE id = ?
                """,
                (new_confidence, helpful_delta, unhelpful_delta, int(memory_id)),
            )
            self._conn.execute(
                """
                INSERT INTO feedback (memory_id, rating, note, old_confidence, new_confidence)
                VALUES (?, ?, ?, ?, ?)
                """,
                (int(memory_id), rating, note or "", old_confidence, new_confidence),
            )
            self._conn.commit()
            return {
                "memory_id": int(memory_id),
                "rating": rating,
                "old_confidence": old_confidence,
                "new_confidence": new_confidence,
            }

    def soft_delete(self, memory_id: int, *, reason: str = "") -> bool:
        with self._lock:
            cur = self._conn.execute(
                """
                UPDATE memories
                SET deleted_at = CURRENT_TIMESTAMP,
                    delete_reason = ?,
                    updated_at = CURRENT_TIMESTAMP
                WHERE id = ? AND deleted_at IS NULL
                """,
                (reason or "", int(memory_id)),
            )
            self._conn.commit()
            return cur.rowcount > 0

    def stats(self) -> dict[str, int]:
        with self._lock:
            episodes = self._conn.execute("SELECT COUNT(*) FROM episodes").fetchone()[0]
            active = self._conn.execute(
                "SELECT COUNT(*) FROM memories WHERE deleted_at IS NULL"
            ).fetchone()[0]
            deleted = self._conn.execute(
                "SELECT COUNT(*) FROM memories WHERE deleted_at IS NOT NULL"
            ).fetchone()[0]
            entities = self._conn.execute("SELECT COUNT(*) FROM entities").fetchone()[0]
            relations = self._conn.execute("SELECT COUNT(*) FROM relations").fetchone()[0]
            return {
                "episodes": int(episodes),
                "active_memories": int(active),
                "deleted_memories": int(deleted),
                "entities": int(entities),
                "relations": int(relations),
            }

    def recent(
        self,
        *,
        min_confidence: float = 0.0,
        limit: int = 5,
        kinds: tuple[str, ...] = ("social", "procedural", "semantic"),
    ) -> list[dict[str, Any]]:
        limit = max(1, min(int(limit or 5), 50))
        placeholders = ",".join("?" * len(kinds))
        params: list[Any] = [*kinds, _clamp_confidence(min_confidence), limit]
        with self._lock:
            rows = self._conn.execute(
                f"""
                SELECT id, kind, content, source, scope, confidence,
                       session_id, episode_id, metadata_json, retrieval_count,
                       helpful_count, unhelpful_count, created_at, updated_at
                FROM memories
                WHERE kind IN ({placeholders})
                  AND deleted_at IS NULL
                  AND confidence >= ?
                ORDER BY confidence DESC, updated_at DESC
                LIMIT ?
                """,
                params,
            ).fetchall()
            return [self._row_to_memory(row) for row in rows]

    def upsert_expression(
        self,
        *,
        situation: str,
        style: str,
        source: str = "",
        scope: str = "workspace",
        session_id: str = "",
        similarity_threshold: float = 0.72,
    ) -> dict[str, Any]:
        """Insert or merge an expression. Returns dict with id, merged, similarity."""
        import difflib

        situation = " ".join((situation or "").split())
        style = " ".join((style or "").split())
        if not situation or not style:
            raise ValueError("situation and style must not be empty")
        if len(situation) > 80 or len(style) > 80:
            raise ValueError("situation and style must be <= 80 chars")

        with self._lock:
            existing = self._conn.execute(
                "SELECT id, situation, style, context_list_json, count FROM expressions WHERE scope = ?",
                (scope or "workspace",),
            ).fetchall()

            best_id: int | None = None
            best_sim = 0.0
            for row in existing:
                sim = difflib.SequenceMatcher(None, situation, row["situation"]).ratio()
                if sim > similarity_threshold and sim > best_sim:
                    best_sim = sim
                    best_id = int(row["id"])

            if best_id is not None and best_sim >= similarity_threshold:
                # Merge: append context, bump count
                contexts = json.loads(
                    self._conn.execute(
                        "SELECT context_list_json FROM expressions WHERE id = ?", (best_id,)
                    ).fetchone()["context_list_json"] or "[]"
                )
                if situation not in contexts:
                    contexts.append(situation)
                self._conn.execute(
                    """
                    UPDATE expressions
                    SET context_list_json = ?,
                        count = count + 1,
                        checked = 0,
                        updated_at = CURRENT_TIMESTAMP
                    WHERE id = ?
                    """,
                    (json.dumps(contexts, ensure_ascii=False), best_id),
                )
                self._conn.commit()
                return {"id": best_id, "merged": True, "similarity": round(best_sim, 4)}

            # New record
            contexts = [situation]
            cur = self._conn.execute(
                """
                INSERT INTO expressions (situation, style, context_list_json, source, scope, session_id)
                VALUES (?, ?, ?, ?, ?, ?)
                RETURNING id
                """,
                (
                    situation,
                    style,
                    json.dumps(contexts, ensure_ascii=False),
                    source or "",
                    scope or "workspace",
                    session_id or "",
                ),
            )
            row = cur.fetchone()
            self._conn.commit()
            return {"id": int(row["id"]), "merged": False, "similarity": 1.0}

    def list_expressions(
        self,
        *,
        scope: str | None = None,
        min_count: int = 1,
        exclude_rejected: bool = True,
        limit: int = 10,
    ) -> list[dict[str, Any]]:
        limit = max(1, min(int(limit or 10), 30))
        clauses = ["deleted_at IS NULL"]
        params: list[Any] = []
        if scope:
            clauses.append("scope = ?")
            params.append(scope)
        if min_count > 1:
            clauses.append("count >= ?")
            params.append(min_count)
        if exclude_rejected:
            clauses.append("rejected = 0")
        params.append(limit)

        with self._lock:
            rows = self._conn.execute(
                f"""
                SELECT id, situation, style, context_list_json, count, checked, rejected,
                       source, scope, session_id, created_at, updated_at
                FROM expressions
                WHERE {' AND '.join(clauses)}
                ORDER BY count DESC, updated_at DESC
                LIMIT ?
                """,
                params,
            ).fetchall()
            return [dict(row) for row in rows]

    def search_expressions(
        self,
        query: str,
        *,
        scope: str | None = None,
        exclude_rejected: bool = True,
        limit: int = 5,
    ) -> list[dict[str, Any]]:
        """Search expressions by situation text (simple LIKE)."""
        query_norm = " ".join((query or "").strip().split())
        if not query_norm:
            return []
        limit = max(1, min(int(limit or 5), 15))

        clauses = ["situation LIKE ?", "deleted_at IS NULL"]
        params: list[Any] = [f"%{query_norm}%"]
        if scope:
            clauses.append("scope = ?")
            params.append(scope)
        if exclude_rejected:
            clauses.append("rejected = 0")
        params.append(limit)

        with self._lock:
            rows = self._conn.execute(
                f"""
                SELECT id, situation, style, context_list_json, count, checked, rejected,
                       source, scope, updated_at
                FROM expressions
                WHERE {' AND '.join(clauses)}
                ORDER BY count DESC, updated_at DESC
                LIMIT ?
                """,
                params,
            ).fetchall()
            return [dict(row) for row in rows]

    def check_expression(self, expression_id: int, *, suitable: bool) -> dict[str, Any]:
        with self._lock:
            row = self._conn.execute(
                "SELECT id, checked, rejected FROM expressions WHERE id = ?", (int(expression_id),)
            ).fetchone()
            if row is None:
                raise KeyError(f"expression_id {expression_id} not found")
            self._conn.execute(
                """
                UPDATE expressions
                SET checked = 1, rejected = ?, updated_at = CURRENT_TIMESTAMP
                WHERE id = ?
                """,
                (0 if suitable else 1, int(expression_id)),
            )
            self._conn.commit()
            return {"id": int(expression_id), "checked": True, "rejected": not suitable}

    def forget_expression(self, expression_id: int) -> bool:
        with self._lock:
            cur = self._conn.execute(
                "UPDATE expressions SET deleted_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP WHERE id = ? AND deleted_at IS NULL",
                (int(expression_id),),
            )
            self._conn.commit()
            return cur.rowcount > 0

    def close(self) -> None:
        with self._lock:
            self._conn.close()

    def _fallback_like_search(
        self,
        query: str,
        *,
        kind: str | None,
        scope: str | None,
        min_confidence: float,
        limit: int,
    ) -> list[sqlite3.Row]:
        terms = _TOKEN_RE.findall(query or "")
        if not terms:
            return []
        clauses = ["deleted_at IS NULL", "confidence >= ?"]
        params: list[Any] = [_clamp_confidence(min_confidence)]
        for term in terms:
            clauses.append("content LIKE ?")
            params.append(f"%{term}%")
        if kind:
            clauses.append("kind = ?")
            params.append(kind)
        if scope:
            clauses.append("scope = ?")
            params.append(scope)
        params.append(limit)
        return self._conn.execute(
            f"""
            SELECT id, kind, content, source, scope, confidence,
                   session_id, episode_id, metadata_json, retrieval_count,
                   helpful_count, unhelpful_count, created_at, updated_at
            FROM memories
            WHERE {' AND '.join(clauses)}
            ORDER BY confidence DESC, updated_at DESC
            LIMIT ?
            """,
            params,
        ).fetchall()

    def _record_retrieval(self, query: str, memory_ids: list[int]) -> None:
        if memory_ids:
            placeholders = ",".join("?" * len(memory_ids))
            self._conn.execute(
                f"UPDATE memories SET retrieval_count = retrieval_count + 1 WHERE id IN ({placeholders})",
                memory_ids,
            )
        self._conn.execute(
            "INSERT INTO retrieval_events (query, memory_ids_json) VALUES (?, ?)",
            (query or "", json.dumps(memory_ids)),
        )
        self._conn.commit()

    def _link_entities(self, memory_id: int, content: str) -> None:
        entities = self._extract_entities(content)
        if not entities:
            return
        entity_ids = [self._upsert_entity(name) for name in entities]
        for source, target in zip(entity_ids, entity_ids[1:]):
            self._conn.execute(
                """
                INSERT OR IGNORE INTO relations
                    (source_entity_id, target_entity_id, relation, memory_id)
                VALUES (?, ?, 'related_to', ?)
                """,
                (source, target, memory_id),
            )
        self._conn.commit()

    def _upsert_entity(self, name: str) -> int:
        self._conn.execute("INSERT OR IGNORE INTO entities (name) VALUES (?)", (name,))
        row = self._conn.execute("SELECT id FROM entities WHERE name = ?", (name,)).fetchone()
        return int(row["id"])

    @staticmethod
    def _extract_entities(content: str) -> list[str]:
        seen: set[str] = set()
        entities: list[str] = []

        def add(value: str) -> None:
            name = " ".join(value.strip().split())
            key = name.lower()
            if name and len(name) > 1 and key not in seen:
                seen.add(key)
                entities.append(name)

        for match in _ENTITY_RE.finditer(content):
            add(match.group(0))
        for match in _QUOTED_RE.finditer(content):
            add(match.group(1) or match.group(2) or "")
        return entities[:12]

    @staticmethod
    def _row_to_memory(row: sqlite3.Row) -> dict[str, Any]:
        item = dict(row)
        try:
            item["metadata"] = json.loads(item.pop("metadata_json") or "{}")
        except json.JSONDecodeError:
            item["metadata"] = {}
        return item
