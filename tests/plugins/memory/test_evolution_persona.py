"""Tests for person profile storage in EvolutionMemoryStore."""
import tempfile
from pathlib import Path

import pytest

from plugins.memory.evolution.store import EvolutionMemoryStore


@pytest.fixture
def store():
    with tempfile.TemporaryDirectory() as td:
        db = Path(td) / "test.db"
        s = EvolutionMemoryStore(db)
        # Seed some social memories for aggregation
        s.upsert_memory(
            kind="social", content="Prefers concise answers",
            source="test", scope="user", confidence=0.9, session_id="s1",
        )
        s.upsert_memory(
            kind="social", content="Works late at night",
            source="test", scope="user", confidence=0.7, session_id="s1",
        )
        yield s
        s.close()


class TestPersonProfileUpsert:
    def test_creates_new_profile(self, store):
        result = store.upsert_person_profile(
            person_id="user_abc",
            person_name="Alice",
            aliases=["Alice", "alice_wang"],
            memory_traits=["likes concise answers", "night owl"],
            profile_text="Alice is a night owl who prefers concise answers.",
        )
        assert result["updated"] is True

    def test_idempotent_update(self, store):
        store.upsert_person_profile(person_id="u1", person_name="First")
        store.upsert_person_profile(person_id="u1", person_name="Second")
        profile = store.get_person_profile("u1", force_refresh=True)
        assert profile["person_name"] == "Second"

    def test_empty_person_id_raises(self, store):
        with pytest.raises(ValueError):
            store.upsert_person_profile(person_id="")


class TestPersonProfileGet:
    def test_get_existing_profile(self, store):
        store.upsert_person_profile(
            person_id="u1", person_name="Bob",
            profile_text="Bob is a Python developer.",
        )
        profile = store.get_person_profile("u1")
        assert profile is not None
        assert profile["person_name"] == "Bob"
        assert "aliases" in profile
        assert "memory_traits" in profile

    def test_get_nonexistent_returns_none(self, store):
        assert store.get_person_profile("nonexistent") is None

    def test_profile_within_ttl_returns_fresh(self, store):
        store.upsert_person_profile(
            person_id="u1", person_name="Bob", profile_text="Cached", ttl_seconds=3600,
        )
        profile = store.get_person_profile("u1")
        assert profile is not None
        assert isinstance(profile.get("aliases"), list)
        assert isinstance(profile.get("memory_traits"), list)


class TestAggregatePersonProfile:
    def test_aggregates_from_social_memories(self, store):
        result = store.aggregate_person_profile("user_abc")
        assert result["person_id"] == "user_abc"
        assert len(result["traits"]) >= 2
        assert any("concise" in t.lower() for t in result["traits"])

    def test_aggregate_stores_profile(self, store):
        store.aggregate_person_profile("user_abc")
        cached = store.get_person_profile("user_abc")
        assert cached is not None
        assert cached["profile_text"] != ""

    def test_aggregate_empty_person_id(self, store):
        result = store.aggregate_person_profile("")
        assert result["profile_text"] == ""
