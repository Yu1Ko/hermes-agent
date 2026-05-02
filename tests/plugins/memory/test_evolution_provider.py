import json

from agent.memory_manager import MemoryManager
from plugins.memory import discover_memory_providers, load_memory_provider
from plugins.memory.evolution import EvolutionMemoryProvider
from plugins.memory.evolution.store import EvolutionMemoryStore


def test_store_records_episodes_and_searchable_memories(tmp_path):
    store = EvolutionMemoryStore(tmp_path / "memory.db")

    episode_id = store.record_episode(
        session_id="session-1",
        user_content="I prefer concise Chinese replies.",
        assistant_content="好的，我会保持简洁。",
        metadata={"platform": "cli", "user_id": "u-1"},
    )
    memory_id = store.upsert_memory(
        kind="social",
        content="The user prefers concise Chinese replies.",
        source="rule:preference",
        scope="user",
        confidence=0.72,
        session_id="session-1",
        episode_id=episode_id,
    )

    assert episode_id > 0
    assert memory_id > 0
    assert store.stats()["episodes"] == 1
    assert store.stats()["active_memories"] == 1

    results = store.search("concise Chinese", limit=5)
    assert [item["id"] for item in results] == [memory_id]
    assert results[0]["kind"] == "social"
    assert results[0]["confidence"] == 0.72


def test_store_feedback_adjusts_confidence_and_delete_hides_memory(tmp_path):
    store = EvolutionMemoryStore(tmp_path / "memory.db")
    memory_id = store.upsert_memory(
        kind="semantic",
        content="The project uses SQLite for local memory.",
        source="manual",
        scope="workspace",
        confidence=0.5,
    )

    helpful = store.record_feedback(memory_id, rating="helpful", note="used successfully")
    assert helpful["new_confidence"] > helpful["old_confidence"]

    unhelpful = store.record_feedback(memory_id, rating="unhelpful")
    assert unhelpful["new_confidence"] < helpful["new_confidence"]

    assert store.soft_delete(memory_id, reason="user requested deletion")
    assert store.search("SQLite local memory") == []
    assert store.stats()["deleted_memories"] == 1


def test_store_upsert_does_not_revive_soft_deleted_memory_by_default(tmp_path):
    store = EvolutionMemoryStore(tmp_path / "memory.db")
    memory_id = store.upsert_memory(
        kind="semantic",
        content="The user used obsolete formatter X.",
        source="manual",
        scope="user",
        confidence=0.8,
    )
    assert store.soft_delete(memory_id, reason="incorrect")

    duplicate_id = store.upsert_memory(
        kind="semantic",
        content="The user used obsolete formatter X.",
        source="rule:preference",
        scope="user",
        confidence=0.9,
    )

    assert duplicate_id == memory_id
    assert store.search("obsolete formatter") == []
    assert store.stats()["deleted_memories"] == 1


def test_provider_sync_turn_extracts_lightweight_memory(tmp_path):
    provider = EvolutionMemoryProvider()
    provider.initialize(session_id="session-1", hermes_home=str(tmp_path), platform="cli")

    provider.sync_turn(
        "I prefer short answers and my default editor is VS Code.",
        "Got it.",
        session_id="session-1",
    )

    stats = provider._store.stats()
    assert stats["episodes"] == 1
    assert stats["active_memories"] >= 1

    context = provider.prefetch("How should you answer me?", session_id="session-1")
    assert "Evolution Memory" in context
    assert "prefer short answers" in context


def test_provider_initialize_without_hermes_home_uses_active_profile_home(tmp_path, monkeypatch):
    hermes_home = tmp_path / "hermes-home"
    monkeypatch.setenv("HERMES_HOME", str(hermes_home))

    provider = EvolutionMemoryProvider()
    provider.initialize(session_id="session-1")

    assert provider._store.db_path == hermes_home / "evolution_memory" / "memory.db"


def test_provider_session_switch_updates_cached_session_id(tmp_path):
    provider = EvolutionMemoryProvider()
    provider.initialize(session_id="old-session", hermes_home=str(tmp_path), platform="cli")

    provider.on_session_switch("new-session", reset=True, user_id="u-2")
    added = json.loads(provider.handle_tool_call(
        "evolution_memory",
        {"action": "add", "content": "New session fact", "scope": "session"},
    ))

    results = provider._store.search("New session fact")
    assert added["success"] is True
    assert results[0]["session_id"] == "new-session"


def test_provider_mirrors_builtin_memory_writes_with_metadata(tmp_path):
    provider = EvolutionMemoryProvider()
    provider.initialize(session_id="session-1", hermes_home=str(tmp_path), platform="telegram")

    provider.on_memory_write(
        "add",
        "user",
        "The user wants simplified Chinese responses.",
        metadata={"session_id": "session-1", "write_origin": "assistant_tool"},
    )

    results = provider._store.search("simplified Chinese responses")
    assert len(results) == 1
    assert results[0]["kind"] == "social"
    assert results[0]["scope"] == "user"
    assert results[0]["source"] == "builtin:user:add"


def test_provider_tool_handles_add_search_feedback_delete_and_stats(tmp_path):
    provider = EvolutionMemoryProvider()
    provider.initialize(session_id="session-1", hermes_home=str(tmp_path), platform="cli")

    added = json.loads(provider.handle_tool_call(
        "evolution_memory",
        {
            "action": "add",
            "kind": "procedural",
            "content": "Use scripts/run_tests.sh for Hermes tests.",
            "scope": "workspace",
        },
    ))
    assert added["success"] is True
    memory_id = added["memory_id"]

    found = json.loads(provider.handle_tool_call(
        "evolution_memory",
        {"action": "search", "query": "Hermes tests"},
    ))
    assert found["count"] == 1
    assert found["results"][0]["id"] == memory_id

    feedback = json.loads(provider.handle_tool_call(
        "evolution_memory",
        {"action": "feedback", "memory_id": memory_id, "rating": "helpful"},
    ))
    assert feedback["success"] is True
    assert feedback["new_confidence"] > feedback["old_confidence"]

    deleted = json.loads(provider.handle_tool_call(
        "evolution_memory",
        {"action": "delete", "memory_id": memory_id, "reason": "obsolete"},
    ))
    assert deleted == {"success": True, "deleted": True}

    stats = json.loads(provider.handle_tool_call("evolution_memory", {"action": "stats"}))
    assert stats["stats"]["deleted_memories"] == 1


def test_provider_prefetch_ignores_soft_deleted_memories(tmp_path):
    provider = EvolutionMemoryProvider()
    provider.initialize(session_id="session-1", hermes_home=str(tmp_path), platform="cli")
    memory_id = provider._store.upsert_memory(
        kind="semantic",
        content="The user likes obsolete formatter X.",
        source="manual",
        scope="user",
        confidence=0.8,
    )

    assert "obsolete formatter" in provider.prefetch("formatter", session_id="session-1")
    provider._store.soft_delete(memory_id, reason="incorrect")
    assert provider.prefetch("formatter", session_id="session-1") == ""


def test_evolution_provider_is_discoverable_and_manager_routable():
    provider_names = {name for name, _, _ in discover_memory_providers()}
    assert "evolution" in provider_names

    provider = load_memory_provider("evolution")
    assert provider is not None
    assert provider.name == "evolution"
    assert provider.is_available()

    manager = MemoryManager()
    manager.add_provider(provider)
    assert manager.has_tool("evolution_memory")
