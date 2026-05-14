# MiLe Knowledge Management System

基于 GraphRAG + 后台 Agent 的知识管理系统，运行在 Hermes Agent 平台上。

## 架构

```
mile-knowledge/
├── graphrag/            # 知识图谱 + 语义搜索
│   ├── graph.py         # NetworkX 图操作
│   ├── extractor.py     # DeepSeek API 实体/关系提取
│   ├── indexer.py       # Louvain 社区检测 + 向量索引
│   ├── config.py        # 配置 (API key, 模型, 路径)
│   └── cli.py           # CLI 入口
├── agents/              # 后台 Cron Agent
│   ├── reflect.py       # 每日反思循环
│   ├── evaluate.py      # 每日对话质量评价
│   └── consolidate.py   # 记忆合并与升级
├── data/                # 持久化数据 (图/向量/报告)
└── requirements.txt
```

## 安装

```bash
pip install -r requirements.txt
```

需要设置 DeepSeek API key（从 `~/.hermes/.env` 自动读取或手动 export）：

```bash
export DEEPSEEK_API_KEY=sk-...
```

## GraphRAG CLI

```bash
# 从文本提取实体和关系
echo "MiLe 是一个二次元风格的 AI 助手" | python -m graphrag extract

# 从文件提取
python -m graphrag extract --file some_notes.txt

# 社区检测 + 向量索引构建
python -m graphrag index

# 语义搜索
python -m graphrag search "MiLe 的性格"

# 图统计
python -m graphrag stats

# 实体邻居查询
python -m graphrag neighbors "MiLe"

# 列出所有实体
python -m graphrag list --type concept
```

## 后台 Agent

三个脚本每天运行一次（Hermes cron job）：

```bash
# 反思循环 — 分析最近会话，提取改进项
python agents/reflect.py --dry-run

# 评价体系 — 给对话打分，追踪趋势
python agents/evaluate.py --dry-run

# 整合器 — 合并相似记忆，升级高信心条目
python agents/consolidate.py --dry-run
```

去掉 `--dry-run` 即可实际写入文件。

也可作为 Python 模块运行：

```bash
python -m agents.reflect --dry-run
python -m agents.evaluate --dry-run
python -m agents.consolidate --dry-run
```
