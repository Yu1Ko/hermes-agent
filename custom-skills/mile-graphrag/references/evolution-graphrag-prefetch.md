# Evolution + GraphRAG Prefetch 集成

打通 evolution memory 的 FTS5 搜索和 GraphRAG 的语义搜索，形成双线混合召回。

## 架构

```
每轮对话 → evolution.prefetch(query)
├── FTS5 关键词搜索 (EvolutionMemoryStore.search)
│   └── 31 条记忆 → "## Evolution Memory" 块
├── GraphRAG 语义搜索 (graphrag_prefetch_block)
│   └── 21 实体 → "## Knowledge Graph (GraphRAG)" 块
├── 表达式匹配 (search_expressions)
└── 人物画像注入 (get_person_profile)
```

## 数据灌图（从 evolution memories 提取实体）

```bash
# 1. 导出 evolution 记忆为文本
python3 -c "
import sqlite3
db = sqlite3.connect('~/.hermes/evolution_memory/memory.db')
rows = db.execute('SELECT content FROM memories WHERE deleted_at IS NULL').fetchall()
text = '\n'.join(r[0] for r in rows)
with open('/tmp/evo_memories.txt', 'w') as f: f.write(text)
print(f'导出 {len(rows)} 条')
"

# 2. 提取实体（调 DeepSeek API 抽骨架）
cd /root/.hermes/mile-knowledge
python3 -m graphrag extract --file /tmp/evo_memories.txt
# → 示例输出: 21 entities, 16 relations (从 31 条记忆)

# 3. 建向量索引 + 社区检测
python3 -m graphrag index
# → 8 communities, 21 entity vectors

# 4. 验证
python3 -m graphrag search "泉此方" --top-k 3
```

## 完整启用流程（从零到跑通）

```bash
# 1. 开开关
hermes config set plugins.evolution.enable_graphrag_prefetch true

# 2. 图谱必须有数据（见上方"数据灌图"）

# 3. 更新 evolution provider 注释（去掉过时的 420MB 警告）
# 编辑 /usr/local/lib/hermes-agent/plugins/memory/evolution/__init__.py
# 第 319-320 行：改为 "uses embedding API (mnapi.com) — no local model needed"

# 4. 清 pycache + 重启
find /usr/local/lib/hermes-agent/plugins/memory/evolution/ -name __pycache__ -exec rm -rf {} +
pkill -9 -f 'hermes gateway'
/usr/local/bin/hermes --skills konata-default-persona,mile-graphrag gateway run
```

## 测试

```bash
cd /root/.hermes/mile-knowledge
python3 -c "
from graphrag.lightweight_search import graphrag_prefetch_block
print(graphrag_prefetch_block('MiLe 的性格', top_k=3))
"
```

预期返回类似：
```
## Knowledge Graph (GraphRAG)
- **泉此方** (score=0.64): 《幸运星》主角，御宅族...
- **傲娇式友情** (score=0.55): ...
- **konata-persona** (score=0.53): ...
```

## 对比 OpenClaw

| 维度 | OpenClaw | MiLe (现在) |
|------|----------|------------|
| 搜索方式 | FTS5 + 向量混合（同存储） | FTS5 + API 向量（双存储） |
| 触发时机 | before_prompt_build 阻断 | prefetch hook |
| 结果注入 | 隐藏上下文 / NONE | 多块拼接 |
| 记忆载体 | Markdown 文件 | SQLite + 知识图谱 |

核心差异已缩小：MiLe 现在有双线召回能力，缺失的主要是 Memory Flush（压缩前保存）。

## 注意事项

- **图谱为空时 GraphRAG prefetch 静默跳过**（不会报错或影响 FTS 结果）
- **修改 evolution provider 代码后必须清 `__pycache__`**，否则旧 .pyc 生效
- **Gateway 启动必须带 `--skills mile-graphrag`**，否则 graphrag 模块不可导入
- embedding API 需要网络可达（mnapi.com），断网时 prefetch 不会崩溃但 GraphRAG 块为空
