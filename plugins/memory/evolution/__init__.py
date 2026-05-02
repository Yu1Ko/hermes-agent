"""Local lightweight long-term memory provider for Hermes."""

from __future__ import annotations

import json
import logging
import importlib
import re
from pathlib import Path
from typing import Any

from agent.memory_provider import MemoryProvider
from hermes_cli.config import cfg_get
from tools.registry import tool_error

from .store import EvolutionMemoryStore

logger = logging.getLogger(__name__)


EVOLUTION_MEMORY_SCHEMA = {
    "name": "evolution_memory",
    "description": (
        "Local structured long-term memory with lightweight episode capture, "
        "fact extraction, confidence feedback, and deletion governance. "
        "Use it for durable preferences, project facts, procedural lessons, "
        "and social interaction style that should improve future conversations."
    ),
    "parameters": {
        "type": "object",
        "properties": {
            "action": {
                "type": "string",
                "enum": ["add", "search", "feedback", "delete", "stats"],
            },
            "content": {"type": "string", "description": "Memory content for add."},
            "query": {"type": "string", "description": "Search query."},
            "kind": {
                "type": "string",
                "enum": ["episodic", "semantic", "procedural", "social"],
                "description": "Memory layer. Defaults to semantic.",
            },
            "scope": {
                "type": "string",
                "enum": ["user", "workspace", "session", "global"],
                "description": "Memory scope. Defaults to workspace.",
            },
            "confidence": {
                "type": "number",
                "description": "Initial confidence from 0.0 to 1.0.",
            },
            "memory_id": {"type": "integer", "description": "Memory id for feedback/delete."},
            "rating": {
                "type": "string",
                "enum": ["helpful", "unhelpful"],
                "description": "Feedback rating.",
            },
            "reason": {"type": "string", "description": "Deletion reason."},
            "note": {"type": "string", "description": "Optional feedback note."},
            "limit": {"type": "integer", "description": "Maximum search results."},
        },
        "required": ["action"],
    },
}


_PREFERENCE_RE = re.compile(
    r"\b(?:I|i)\s+(?:prefer|like|love|want|need|always|usually|never)\b|"
    r"\bmy\s+(?:default|preferred|favorite)\b",
    re.IGNORECASE,
)
_PROJECT_RE = re.compile(
    r"\b(?:we\s+(?:decided|agreed|chose)|project\s+(?:uses|needs|requires)|"
    r"repo\s+(?:uses|needs|requires))\b",
    re.IGNORECASE,
)
_PROCEDURAL_RE = re.compile(
    r"\b(?:use|run|remember to|workflow|tests?|commands?|scripts?/)\b",
    re.IGNORECASE,
)
_SOCIAL_RE = re.compile(
    r"\b(?:tone|style|reply|answer|language|Chinese|English|concise|verbose|short)\b",
    re.IGNORECASE,
)


def _load_plugin_config() -> dict[str, Any]:
    from hermes_constants import get_hermes_home

    config_path = get_hermes_home() / "config.yaml"
    if not config_path.exists():
        return {}
    try:
        yaml = importlib.import_module("yaml")
        data = yaml.safe_load(config_path.read_text(encoding="utf-8")) or {}
        return cfg_get(data, "plugins", "evolution", default={}) or {}
    except Exception:
        return {}


def _clip(text: str, limit: int = 500) -> str:
    text = " ".join((text or "").split())
    if len(text) <= limit:
        return text
    return text[: limit - 1].rstrip() + "..."


class EvolutionMemoryProvider(MemoryProvider):
    """Hermes-native local memory evolution provider."""

    def __init__(self, config: dict[str, Any] | None = None) -> None:
        self._config = config or _load_plugin_config()
        self._store: EvolutionMemoryStore | None = None
        self._session_id = ""
        self._platform = ""
        self._metadata: dict[str, Any] = {}
        self._max_prefetch = int(self._config.get("max_prefetch", 5))
        self._min_confidence = float(self._config.get("min_confidence", 0.2))

    @property
    def name(self) -> str:
        return "evolution"

    def is_available(self) -> bool:
        return True

    def initialize(self, session_id: str, **kwargs) -> None:
        raw_hermes_home = kwargs.get("hermes_home")
        if raw_hermes_home:
            hermes_home = Path(raw_hermes_home)
        else:
            from hermes_constants import get_hermes_home

            hermes_home = get_hermes_home()

        db_path = self._config.get("db_path") or str(
            hermes_home / "evolution_memory" / "memory.db"
        )
        if isinstance(db_path, str):
            db_path = db_path.replace("$HERMES_HOME", str(hermes_home))
            db_path = db_path.replace("${HERMES_HOME}", str(hermes_home))

        self._store = EvolutionMemoryStore(db_path)
        self._session_id = session_id or ""
        self._platform = kwargs.get("platform", "")
        self._metadata = {
            key: value
            for key, value in kwargs.items()
            if key
            in {
                "platform",
                "agent_context",
                "agent_identity",
                "agent_workspace",
                "parent_session_id",
                "user_id",
                "user_name",
                "chat_id",
                "chat_name",
                "chat_type",
                "thread_id",
                "gateway_session_key",
                "session_title",
            }
            and value
        }

    def get_config_schema(self) -> list[dict[str, Any]]:
        from hermes_constants import display_hermes_home

        return [
            {
                "key": "db_path",
                "description": "SQLite database path",
                "default": f"{display_hermes_home()}/evolution_memory/memory.db",
            },
            {
                "key": "max_prefetch",
                "description": "Maximum memories injected before each turn",
                "default": "5",
            },
            {
                "key": "min_confidence",
                "description": "Minimum confidence for automatic recall",
                "default": "0.2",
            },
        ]

    def save_config(self, values: dict[str, Any], hermes_home: str) -> None:
        config_path = Path(hermes_home) / "config.yaml"
        try:
            yaml = importlib.import_module("yaml")
            existing = {}
            if config_path.exists():
                existing = yaml.safe_load(config_path.read_text(encoding="utf-8")) or {}
            existing.setdefault("plugins", {})
            existing["plugins"]["evolution"] = values
            config_path.write_text(yaml.safe_dump(existing, sort_keys=False), encoding="utf-8")
        except Exception as exc:
            logger.debug("Evolution memory save_config failed: %s", exc)

    def system_prompt_block(self) -> str:
        return (
            "# Evolution Memory\n"
            "Active local long-term memory. It stores episodes, stable facts, "
            "procedural lessons, social preferences, confidence feedback, and deletions. "
            "Use evolution_memory for explicit add/search/feedback/delete operations."
        )

    def prefetch(self, query: str, *, session_id: str = "") -> str:
        if not self._store or not query:
            return ""
        try:
            results = self._store.search(
                query,
                min_confidence=self._min_confidence,
                limit=self._max_prefetch,
            )
            if not results:
                results = self._store.recent(
                    min_confidence=max(self._min_confidence, 0.5),
                    limit=min(self._max_prefetch, 3),
                    kinds=("social", "procedural"),
                )
        except Exception as exc:
            logger.debug("Evolution memory prefetch failed: %s", exc)
            return ""
        if not results:
            return ""

        lines = ["## Evolution Memory"]
        for item in results:
            confidence = float(item.get("confidence", 0.0))
            kind = item.get("kind", "semantic")
            lines.append(f"- [{kind} {confidence:.2f}] {item.get('content', '')}")
        return "\n".join(lines)

    def sync_turn(self, user_content: str, assistant_content: str, *, session_id: str = "") -> None:
        if not self._store or not user_content:
            return
        sid = session_id or self._session_id
        try:
            episode_id = self._store.record_episode(
                session_id=sid,
                user_content=user_content,
                assistant_content=assistant_content or "",
                metadata=self._metadata,
            )
            for memory in self._extract_memories(user_content):
                self._store.upsert_memory(
                    session_id=sid,
                    episode_id=episode_id,
                    metadata=self._metadata,
                    **memory,
                )
        except Exception as exc:
            logger.debug("Evolution memory sync_turn failed: %s", exc)

    def on_session_end(self, messages: list[dict[str, Any]]) -> None:
        if not self._store or not messages:
            return
        for message in messages:
            if message.get("role") != "user":
                continue
            content = message.get("content", "")
            if not isinstance(content, str):
                continue
            for memory in self._extract_memories(content, source_prefix="session_end"):
                try:
                    self._store.upsert_memory(
                        session_id=self._session_id,
                        metadata=self._metadata,
                        **memory,
                    )
                except Exception:
                    pass

    def on_pre_compress(self, messages: list[dict[str, Any]]) -> str:
        if not self._store or not messages:
            return ""
        captured = 0
        for message in messages:
            if message.get("role") != "user":
                continue
            content = message.get("content", "")
            if not isinstance(content, str):
                continue
            for memory in self._extract_memories(content, source_prefix="pre_compress"):
                try:
                    self._store.upsert_memory(
                        session_id=self._session_id,
                        metadata=self._metadata,
                        **memory,
                    )
                    captured += 1
                except Exception:
                    pass
        if not captured:
            return ""
        return f"Evolution Memory captured {captured} durable item(s) before compression."

    def on_memory_write(
        self,
        action: str,
        target: str,
        content: str,
        metadata: dict[str, Any] | None = None,
    ) -> None:
        if not self._store or action not in {"add", "replace"} or not content:
            return
        scope = "user" if target == "user" else "workspace"
        kind = "social" if target == "user" else "semantic"
        try:
            self._store.upsert_memory(
                kind=kind,
                content=_clip(content),
                source=f"builtin:{target}:{action}",
                scope=scope,
                confidence=0.78,
                session_id=(metadata or {}).get("session_id", self._session_id),
                metadata=metadata or {},
            )
        except Exception as exc:
            logger.debug("Evolution memory write mirror failed: %s", exc)

    def on_delegation(
        self,
        task: str,
        result: str,
        *,
        child_session_id: str = "",
        **kwargs,
    ) -> None:
        if not self._store or not task or not result:
            return
        try:
            self._store.upsert_memory(
                kind="procedural",
                content=_clip(f"Delegated task outcome: {task} => {result}", 700),
                source="delegation",
                scope="workspace",
                confidence=0.55,
                session_id=self._session_id,
                metadata={"child_session_id": child_session_id, **kwargs},
            )
        except Exception as exc:
            logger.debug("Evolution delegation memory failed: %s", exc)

    def get_tool_schemas(self) -> list[dict[str, Any]]:
        return [EVOLUTION_MEMORY_SCHEMA]

    def handle_tool_call(self, tool_name: str, args: dict[str, Any], **kwargs) -> str:
        if tool_name != "evolution_memory":
            return tool_error(f"Unknown tool: {tool_name}")
        if not self._store:
            return tool_error("Evolution memory is not initialized.")

        action = args.get("action", "")
        try:
            if action == "add":
                content = args.get("content", "")
                if not content:
                    return tool_error("content is required for add")
                memory_id = self._store.upsert_memory(
                    kind=args.get("kind", "semantic"),
                    content=_clip(content, 1000),
                    source="tool:add",
                    scope=args.get("scope", "workspace"),
                    confidence=float(args.get("confidence", 0.65)),
                    session_id=self._session_id,
                    metadata={"tool": "evolution_memory"},
                    restore_deleted=True,
                )
                return json.dumps({"success": True, "memory_id": memory_id})

            if action == "search":
                query = args.get("query", "")
                if not query:
                    return tool_error("query is required for search")
                results = self._store.search(
                    query,
                    kind=args.get("kind"),
                    scope=args.get("scope"),
                    min_confidence=float(args.get("min_confidence", 0.0)),
                    limit=int(args.get("limit", self._max_prefetch)),
                )
                return json.dumps({"success": True, "results": results, "count": len(results)}, ensure_ascii=False)

            if action == "feedback":
                memory_id = int(args["memory_id"])
                result = self._store.record_feedback(
                    memory_id,
                    rating=args.get("rating", ""),
                    note=args.get("note", ""),
                )
                result["success"] = True
                return json.dumps(result)

            if action == "delete":
                memory_id = int(args["memory_id"])
                deleted = self._store.soft_delete(memory_id, reason=args.get("reason", ""))
                return json.dumps({"success": True, "deleted": deleted})

            if action == "stats":
                return json.dumps({"success": True, "stats": self._store.stats()})

            return tool_error(f"Unknown action: {action}")
        except KeyError as exc:
            return tool_error(f"Missing required argument: {exc}")
        except Exception as exc:
            return tool_error(str(exc))

    def shutdown(self) -> None:
        if self._store:
            try:
                self._store.close()
            finally:
                self._store = None

    def on_session_switch(
        self,
        new_session_id: str,
        *,
        parent_session_id: str = "",
        reset: bool = False,
        **kwargs,
    ) -> None:
        if not new_session_id:
            return
        self._session_id = new_session_id
        if parent_session_id:
            self._metadata["parent_session_id"] = parent_session_id
        for key, value in kwargs.items():
            if value:
                self._metadata[key] = value

    def _extract_memories(
        self,
        text: str,
        *,
        source_prefix: str = "rule",
    ) -> list[dict[str, Any]]:
        content = _clip(text)
        if len(content) < 8:
            return []

        memories: list[dict[str, Any]] = []
        if _PREFERENCE_RE.search(content):
            kind = "social" if _SOCIAL_RE.search(content) else "semantic"
            scope = "user" if kind == "social" else "workspace"
            memories.append({
                "kind": kind,
                "content": f"User preference: {content}",
                "source": f"{source_prefix}:preference",
                "scope": scope,
                "confidence": 0.68,
            })
        if _PROJECT_RE.search(content):
            memories.append({
                "kind": "semantic",
                "content": f"Project fact or decision: {content}",
                "source": f"{source_prefix}:project",
                "scope": "workspace",
                "confidence": 0.64,
            })
        if _PROCEDURAL_RE.search(content) and not _PREFERENCE_RE.search(content):
            memories.append({
                "kind": "procedural",
                "content": f"Procedural lesson: {content}",
                "source": f"{source_prefix}:procedural",
                "scope": "workspace",
                "confidence": 0.58,
            })
        return memories


def register(ctx) -> None:
    ctx.register_memory_provider(EvolutionMemoryProvider())
