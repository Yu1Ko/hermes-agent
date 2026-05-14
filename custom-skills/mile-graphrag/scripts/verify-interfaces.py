#!/usr/bin/env python3
"""MiLe 知识系统接口验证脚本 — 检查所有组件的导入和基础功能。

用法:
  python3 scripts/verify-interfaces.py          # 全部检查
  python3 scripts/verify-interfaces.py --quick  # 仅导入检查（不调 API）
"""

import sys
from pathlib import Path

MILE_KNOWLEDGE = Path.home() / ".hermes" / "mile-knowledge"
sys.path.insert(0, str(MILE_KNOWLEDGE))

RED = "\033[91m"
GREEN = "\033[92m"
YELLOW = "\033[93m"
END = "\033[0m"


def ok(msg: str) -> None:
    print(f"  {GREEN}✓{END} {msg}")


def warn(msg: str) -> None:
    print(f"  {YELLOW}⚠{END} {msg}")


def fail(msg: str) -> None:
    print(f"  {RED}✗{END} {msg}")


# ── GraphRAG 核心 ──────────────────────────────────────────

def check_config():
    """检查配置加载"""
    from graphrag.config import (
        DEEPSEEK_MODEL,
        DEEPSEEK_API_KEY,
        EMBEDDING_API_MODEL,
        EMBEDDING_API_BASE,
    )
    if not DEEPSEEK_API_KEY:
        fail("DEEPSEEK_API_KEY 未设置")
    else:
        ok(f"DeepSeek model={DEEPSEEK_MODEL} key=已加载")
    ok(f"Embedding: {EMBEDDING_API_MODEL} @ {EMBEDDING_API_BASE}")


def check_graph():
    """检查知识图谱"""
    from graphrag.config import GRAPH_PATH
    from graphrag.graph import GraphManager

    g = GraphManager()
    if not GRAPH_PATH.exists():
        warn("graph.pkl 不存在，跳过")
        return

    g.load(str(GRAPH_PATH))
    s = g.get_stats()
    ok(f"entities={s['num_entities']} relations={s['num_relations']} types={s['entity_types']}")


def check_embedding():
    """检查 embedding API"""
    from graphrag.embedding import embed_texts

    v = embed_texts(["健康检查"])
    if v.shape[1] == 1536:
        ok(f"embedding dims={v.shape}")
    else:
        warn(f"embedding dims={v.shape} (预期 1536)")


def check_extractor():
    """检查抽取器"""
    from graphrag.extractor import EntityRelationExtractor

    ext = EntityRelationExtractor()
    ok(f"extractor model={ext.model}")


def check_indexer():
    """检查索引器"""
    from graphrag.config import GRAPH_PATH
    from graphrag.graph import GraphManager
    from graphrag.indexer import CommunityIndexer

    g = GraphManager()
    if GRAPH_PATH.exists():
        g.load(str(GRAPH_PATH))
    idx = CommunityIndexer(g)
    ok(f"indexer entities={len(idx.gm.get_all_entities())}")


def check_cli_search():
    """检查 CLI search"""
    import subprocess
    import json

    r = subprocess.run(
        ["python3", "-m", "graphrag", "search", "test", "--top-k", "1"],
        capture_output=True, text=True, cwd=str(MILE_KNOWLEDGE),
    )
    if r.returncode == 0:
        results = json.loads(r.stdout)
        ok(f"CLI search: {len(results)} results")
    else:
        fail(f"CLI search 失败: {r.stderr[:200]}")


# ── Session Reader ─────────────────────────────────────────

def check_session_reader():
    """检查会话读取"""
    from session_reader import get_recent_conversations

    convs = get_recent_conversations(hours=24)
    ok(f"24h sessions={len(convs)}")


# ── 后台 Agent ─────────────────────────────────────────────

def check_agents():
    """检查 agent 导入"""
    from agents.reflect import main as _r
    from agents.evaluate import main as _e
    from agents.consolidate import main as _c
    from agents.critic import check_reply, _load_case_library
    from agents.optimize import main as _o

    cases = _load_case_library()
    ok(f"agents import OK (reflect/evaluate/consolidate/critic/optimize)")
    ok(f"case library: {len(cases)} cases")


# ── Hermes 工具 ────────────────────────────────────────────

def check_graphrag_tool():
    """检查 graphrag_search 工具"""
    import sys as _sys
    _sys.path.insert(0, str(Path("/usr/local/lib/hermes-agent")))
    try:
        from tools.graphrag_search import check_requirements

        ok(f"graphrag_search tool available={check_requirements()}")
    except ImportError:
        warn("graphrag_search tool 不在标准路径，跳过")


# ── Hook / 拦截器 ──────────────────────────────────────────

def check_hook():
    """检查 critic 拦截器 hook"""
    hook_dir = Path.home() / ".hermes" / "hooks" / "critic-intercept"
    hook_yaml = hook_dir / "HOOK.yaml"
    handler_py = hook_dir / "handler.py"

    if hook_yaml.exists() and handler_py.exists():
        content = handler_py.read_text()
        if 'context.get("user_message") or context.get("message"' in content:
            ok("critic hook 已接线，key 兼容性 OK")
        else:
            warn("critic hook 已接线但 handler 可能有 key 名 bug")
    else:
        warn("critic hook 未找到")


# ── 入口 ───────────────────────────────────────────────────

def main():
    import argparse

    parser = argparse.ArgumentParser(description="MiLe 知识系统接口验证")
    parser.add_argument("--quick", action="store_true", help="仅检查导入（不调 API）")
    args = parser.parse_args()

    print("MiLe Knowledge System — Interface Verification\n")

    checks = [
        ("Config", check_config),
        ("Graph", check_graph),
        ("Embedding", check_embedding),
        ("Extractor", check_extractor),
        ("Indexer", check_indexer),
        ("CLI Search", check_cli_search) if not args.quick else None,
        ("Session Reader", check_session_reader),
        ("Agents", check_agents),
        ("GraphRAG Tool", check_graphrag_tool),
        ("Critic Hook", check_hook),
    ]

    for name, fn in checks:
        if fn is None:
            continue
        print(f"[{name}]")
        try:
            fn()
        except Exception as exc:
            fail(f"{type(exc).__name__}: {exc}")


if __name__ == "__main__":
    main()
