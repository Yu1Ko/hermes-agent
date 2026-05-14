#!/usr/bin/env python3
"""WJ 知识图谱 & UI 代码搜索工具
用法: python wj_search.py <查询词>
     python wj_search.py --fts "BagView"    # FTS5 搜源码
     python wj_search.py --graph "背包操作"   # 语义搜知识图谱
     python wj_search.py --all "副本"         # 两者都搜
"""

import sys, json, sqlite3, os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
GRAPH_PATH = os.path.join(SCRIPT_DIR, "wj_knowledge_graph.json")
FTS_PATH = os.path.join(SCRIPT_DIR, "wj_ui_fts.db")

def search_graph(query, top_k=8):
    """线性搜索知识图谱（本地无需 embedding API）"""
    with open(GRAPH_PATH, encoding="utf-8") as f:
        data = json.load(f)
    
    # Simple keyword match + score
    results = []
    for node in data["nodes"]:
        score = 0
        text = (node.get("id","") + " " + node.get("description","")).lower()
        for word in query.lower().split():
            if word in text:
                score += 1
        if score > 0:
            results.append((score, node))
    
    results.sort(key=lambda x: -x[0])
    for score, node in results[:top_k]:
        t = node.get("type", "?")
        print(f"  [{t}] {node['id']}: {node.get('description','')}")
    
    # Show relevant edges
    print(f"\n  相关关系:")
    node_ids = {n["id"] for _, n in results[:top_k]}
    shown = 0
    for edge in data["edges"]:
        if (edge["source"] in node_ids or edge["target"] in node_ids) and shown < 10:
            print(f"    {edge['source']} --[{edge.get('relation','?')}]--> {edge['target']}")
            shown += 1

def search_fts(query, limit=8):
    """FTS5 全文搜索 UI 源码"""
    conn = sqlite3.connect(FTS_PATH)
    rows = conn.execute(
        "SELECT path, snippet(ui_files, 1, '>>', '<<', '...', 40) "
        "FROM ui_files WHERE ui_files MATCH ? LIMIT ?",
        (query, limit)
    ).fetchall()
    conn.close()
    
    for path, snippet in rows:
        print(f"  📄 {path}")
        print(f"     {snippet[:150]}")
        print()

def search_all(query):
    print(f"=== 知识图谱: {query} ===\n")
    search_graph(query)
    print(f"\n=== UI 源码: {query} ===\n")
    search_fts(query)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    
    mode = "--all"
    query_idx = 1
    if sys.argv[1] in ("--fts", "--graph", "--all"):
        mode = sys.argv[1]
        query_idx = 2
    
    query = " ".join(sys.argv[query_idx:])
    
    if mode == "--fts":
        search_fts(query)
    elif mode == "--graph":
        search_graph(query)
    else:
        search_all(query)
