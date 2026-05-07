# MiLe Knowledge System — Full Architecture

## File Map

```
/root/.hermes/
├── mile-knowledge/                   # 知识管理系统根目录
│   ├── graphrag/                     # GraphRAG 知识图谱（650 行 Python）
│   │   ├── __init__.py               # 惰性导入（__getattr__）
│   │   ├── __main__.py               # python -m graphrag 入口
│   │   ├── graph.py                  # GraphManager：NetworkX 有向图
│   │   ├── extractor.py              # EntityRelationExtractor：DeepSeek 实体提取
│   │   ├── indexer.py                # CommunityIndexer + QueryEngine：Louvain + 语义搜索
│   │   ├── config.py                 # API key/model 配置 + Layer 4 预留
│   │   └── cli.py                    # 6 子命令（extract/index/search/stats/neighbors/list）
│   ├── agents/                       # 后台 Agent（1300+ 行 Python）
│   │   ├── __init__.py
│   │   ├── reflect.py                # 反思循环（每日 03:00）
│   │   ├── evaluate.py               # 评价体系 + 案例提取（每日 04:00）
│   │   ├── consolidate.py            # 整合器 + 评分过滤（每日 05:00）
│   │   ├── critic.py                 # 实时拦截器（Layer 1，6检查项，gateway hook 调用）
│   │   └── optimize.py               # L4 自动 Prompt 进化（daily cron）
│   ├── session_reader.py             # state.db → 对话内容读取器
│   ├── data/                         # 持久化数据
│   │   ├── graph.pkl                 # NetworkX 图快照
│   │   ├── embeddings.npz            # 实体向量索引
│   │   ├── communities.json          # 社区检测+摘要
│   │   ├── daily_eval_*.json         # 每日评价报告
│   │   ├── eval_trend.json           # 趋势数据（90 天滑动窗口）
│   │   ├── case_library.json         # Layer 2 案例库
│   │   └── archived/                 # Layer 3 低分记忆归档
│   ├── requirements.txt
│   └── README.md
├── skills/mile-graphrag/SKILL.md     # 本 skill
├── skills/konata-default-persona/    # MiLe 人格基底
├── sessions/*.jsonl                  # 会话元数据（非对话内容）
├── state.db                          # SQLite：真实对话历史 + 会话元数据
├── evolution_memory/                 # 候选记忆条目
├── memories/                         # 已升级的正式记忆
└── config.yaml                       # Hermes 配置
```

## 数据流

```
用户对话 → state.db (SQLite)
                ↓
         session_reader.py (get_recent_conversations)
                ↓
     ┌─────────┼─────────┐
     ↓         ↓         ↓
  reflect   evaluate   critic (实时)
     ↓         ↓         ↓
 evolution  daily_eval  pass/fail
 _memory    + case_lib
     ↓         ↓
 consolidate ← eval scores (Layer 3 过滤)
     ↓
  memories/
  + graphrag (GraphRAG)
```

## 关键依赖

- `networkx>=3.0` — 图谱存储
- `openai>=2.0` — DeepSeek/mnapi API 调用
- `httpx` — L4 optimizer 的纯 HTTP 客户端（无 SDK 依赖）
- `python-louvain` — 社区检测
- `numpy` — 向量计算

## 数据源重要说明

**`~/.hermes/sessions/*.jsonl` 是元数据，不是对话内容。**
文件格式为单行 JSON，字段：`session_id`, `platform`, `chat_type`, `input_tokens`, `output_tokens` 等。

**真实对话内容在 `~/.hermes/state.db`（SQLite）。**
`sessions` 表存会话元数据，`messages` 表存 role/content/timestamp。

`session_reader.py` 用 `sqlite3` 只读连接 state.db，按 `started_at` 过滤最近 N 小时会话，然后读 `messages` 表中 `role IN ('user', 'assistant')` 的消息。

## 自我进化循环

```
每日 03:00 reflect    → evolution_memory + case_library
每日 04:00 evaluate   → daily_eval + case_library  
每日 05:00 consolidate → memories + graphrag + archived
每日 06:00 optimize   → Layer 4 Prompt 进化建议 (optimization_report.json)

每次 gateway 回复     → critic check (if case_library has entries)
```

## 验证全部通过的命令

```bash
cd /root/.hermes/mile-knowledge

# GraphRAG
python3 -c "from graphrag.graph import GraphManager; g = GraphManager(); g.add_entity('test'); print(g.get_stats())"
python3 -c "from graphrag.config import DEEPSEEK_MODEL; print(DEEPSEEK_MODEL)"
python3 -m graphrag stats

# Session reader
python3 -c "from session_reader import get_recent_conversations; c = get_recent_conversations(24); print(len(c))"

# Agents
python3 agents/reflect.py --help
python3 agents/evaluate.py --help
python3 agents/consolidate.py --help
python3 agents/critic.py --user-msg "test" --bot-reply "test"

# Imports
python3 -c "from agents.critic import check_reply; print('critic OK')"
python3 -c "from agents.evaluate import extract_case_from_session; print('evaluate OK')"
```
