# WJ 自动化知识包

## 文件
- `wj_knowledge_graph.json` — 218 实体 201 关系，含模块结构、游戏 UI、API
- `wj_ui_fts.db` — 2114 个游戏 UI 源码 FTS5 全文索引
- `wj_search.py` — 本地搜索工具

## 使用

```bash
# 本地搜索（需要 Python3 + sqlite3，无需安装依赖）
python wj_search.py --all "背包操作"
python wj_search.py --fts "SkillPanel"
python wj_search.py --graph "副本自动化"

# 喂给 Claude Code 当上下文
claude -p "参考 wj_knowledge_graph.json 和 wj_ui_fts.db，帮我写一个自动采集草药的模块"
```

## 知识图谱结构
- nodes: id, type(entity/technology/concept), description
- edges: source, target, relation(is_a/depends_on/created_by/related_to)
- stats: 节点数、边数、密度
