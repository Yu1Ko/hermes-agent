"""Tests for expression storage in EvolutionMemoryStore."""
import tempfile
from pathlib import Path

import pytest

from plugins.memory.evolution.store import EvolutionMemoryStore


@pytest.fixture
def store():
    with tempfile.TemporaryDirectory() as td:
        db = Path(td) / "test.db"
        s = EvolutionMemoryStore(db)
        yield s
        s.close()


class TestExpressionUpsert:
    def test_new_expression_creates_record(self, store):
        result = store.upsert_expression(
            situation="expressing surprise",
            style="use 'whoa'",
        )
        assert result["merged"] is False
        assert result["id"] > 0

    def test_similar_situation_dedup_merges(self, store):
        result1 = store.upsert_expression(
            situation="expressing surprise",
            style="use 'whoa'",
        )
        result2 = store.upsert_expression(
            situation="expressing shock and surprise",
            style="use 'whoa'",
            similarity_threshold=0.5,
        )
        assert result2["merged"] is True
        assert result2["id"] == result1["id"]

    def test_different_situations_dont_merge(self, store):
        store.upsert_expression(situation="expressing surprise", style="use 'wow'")
        result = store.upsert_expression(situation="expressing gratitude", style="use 'thanks'")
        assert result["merged"] is False

    def test_empty_input_raises(self, store):
        with pytest.raises(ValueError):
            store.upsert_expression(situation="", style="something")
        with pytest.raises(ValueError):
            store.upsert_expression(situation="something", style="")


class TestExpressionList:
    def test_lists_by_count_desc(self, store):
        store.upsert_expression(situation="expressing surprise", style="x")
        store.upsert_expression(situation="expressing thanks", style="y")
        store.upsert_expression(
            situation="expressing surprise and shock", style="x", similarity_threshold=0.5,
        )
        results = store.list_expressions(limit=10)
        assert len(results) >= 1
        a_expr = [r for r in results if r["style"] == "x"]
        assert len(a_expr) == 1
        assert a_expr[0]["count"] >= 2

    def test_excludes_rejected_by_default(self, store):
        store.upsert_expression(situation="a", style="x")
        expr_id = store.list_expressions(limit=1)[0]["id"]
        store.check_expression(expr_id, suitable=False)
        results = store.list_expressions(limit=10)
        assert all(r["rejected"] == 0 for r in results)

    def test_respects_scope_filter(self, store):
        store.upsert_expression(situation="a", style="x", scope="workspace")
        store.upsert_expression(situation="b", style="y", scope="user")
        results = store.list_expressions(scope="user", limit=10)
        assert all(r["scope"] == "user" for r in results)


class TestExpressionSearch:
    def test_search_finds_by_situation(self, store):
        store.upsert_expression(situation="expressing strong agreement", style="use +1")
        results = store.search_expressions("agreement")
        assert len(results) >= 1
        assert any("agreement" in r["situation"] for r in results)

    def test_search_empty_query_returns_empty(self, store):
        store.upsert_expression(situation="a", style="x")
        assert store.search_expressions("") == []


class TestExpressionCheck:
    def test_check_marks_suitable(self, store):
        store.upsert_expression(situation="a", style="x")
        eid = store.list_expressions(limit=1)[0]["id"]
        result = store.check_expression(eid, suitable=True)
        assert result["checked"] is True
        assert result["rejected"] is False

    def test_check_marks_rejected(self, store):
        store.upsert_expression(situation="a", style="x")
        eid = store.list_expressions(limit=1)[0]["id"]
        result = store.check_expression(eid, suitable=False)
        assert result["rejected"] is True

    def test_check_nonexistent_raises(self, store):
        with pytest.raises(KeyError):
            store.check_expression(9999, suitable=True)


class TestExpressionForget:
    def test_forget_excludes_from_list(self, store):
        store.upsert_expression(situation="a", style="x")
        eid = store.list_expressions(limit=1)[0]["id"]
        assert store.forget_expression(eid) is True
        assert len(store.list_expressions(limit=10)) == 0

    def test_forget_already_deleted_returns_false(self, store):
        store.upsert_expression(situation="a", style="x")
        eid = store.list_expressions(limit=1)[0]["id"]
        store.forget_expression(eid)
        assert store.forget_expression(eid) is False
