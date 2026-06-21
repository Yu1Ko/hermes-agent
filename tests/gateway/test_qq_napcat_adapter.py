"""Tests for the native NapCat/OneBot QQ adapter."""

import asyncio

from gateway.config import PlatformConfig
from gateway.platforms.qq_napcat import NapCatQQAdapter


def _make_adapter(**extra):
    return NapCatQQAdapter(PlatformConfig(enabled=True, extra=extra))


def test_split_outbound_text_returns_original_without_marker():
    assert NapCatQQAdapter._split_outbound_text("hello\nworld") == ["hello\nworld"]


def test_split_outbound_text_splits_explicit_marker_and_ignores_empty_chunks():
    assert NapCatQQAdapter._split_outbound_text(" first <<<QQ_SPLIT>>>  second  <<<QQ_SPLIT>>> ") == [
        "first",
        "second",
    ]


def test_split_outbound_text_accepts_control_marker_alias():
    assert NapCatQQAdapter._split_outbound_text("one␞QQ_SPLIT␞two") == ["one", "two"]


def test_send_without_marker_calls_napcat_once(monkeypatch):
    adapter = _make_adapter()
    calls = []

    def fake_send_text(source, text):
        calls.append((source.user_id, source.group_id, text))
        return {"data": {"message_id": len(calls)}}

    monkeypatch.setattr(adapter._client, "send_text", fake_send_text)

    result = asyncio.run(adapter.send("private:user-1", "hello\nworld"))

    assert result.success is True
    assert result.message_id == "1"
    assert calls == [("user-1", None, "hello\nworld")]


def test_send_with_marker_calls_napcat_for_each_part(monkeypatch):
    adapter = _make_adapter()
    calls = []

    def fake_send_text(source, text):
        calls.append((source.user_id, source.group_id, text))
        return {"data": {"message_id": len(calls)}}

    monkeypatch.setattr(adapter._client, "send_text", fake_send_text)

    result = asyncio.run(adapter.send("group:group-1", "one<<<QQ_SPLIT>>>two<<<QQ_SPLIT>>>three"))

    assert result.success is True
    assert result.message_id == "3"
    assert calls == [
        ("", "group-1", "one"),
        ("", "group-1", "two"),
        ("", "group-1", "three"),
    ]
    assert len(result.raw_response["parts"]) == 3
