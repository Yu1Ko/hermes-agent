"""从 Hermes state.db 读取会话对话内容。"""

import sqlite3
import time
from pathlib import Path
from typing import Any

STATE_DB = Path.home() / ".hermes" / "state.db"


def get_recent_conversations(hours: int = 24) -> list[dict[str, Any]]:
    """返回最近 N 小时的会话对话内容列表。

    每条包含：session_id, messages（list of {role, content}），created_at
    """
    cutoff = time.time() - hours * 3600
    db_uri = f"file:{STATE_DB}?mode=ro"

    conn = sqlite3.connect(db_uri, uri=True, timeout=5)
    conn.row_factory = sqlite3.Row
    try:
        rows = conn.execute(
            "SELECT id, started_at FROM sessions WHERE started_at >= ? ORDER BY started_at DESC",
            (cutoff,),
        ).fetchall()

        result: list[dict[str, Any]] = []
        for row in rows:
            session_id = row["id"]
            msgs = conn.execute(
                "SELECT role, content, timestamp FROM messages "
                "WHERE session_id = ? AND role IN ('user', 'assistant') "
                "ORDER BY timestamp ASC",
                (session_id,),
            ).fetchall()

            messages = [
                {"role": m["role"], "content": m["content"] or ""} for m in msgs
            ]

            if messages:
                result.append({
                    "session_id": session_id,
                    "messages": messages,
                    "created_at": row["started_at"],
                })

        return result
    finally:
        conn.close()
