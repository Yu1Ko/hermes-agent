---
name: mile-graphrag
description: MiLe 知识管理系统 — GraphRAG 知识图谱 + 后台反思/评价/整合 Agent 的完整使用手册。触发场景：对话涉及 MiLe 的知识图谱、实体搜索、记忆合并、后台 agent、cron job 管理；或需要对图谱做维护（提取实体、建索引、查社区摘要）。
---

# MiLe Knowledge Management System

完整的知识自进化系统。由两层组成：**GraphRAG 知识图谱**（结构化存储+语义搜索）和 **后台 Agent**（反思/评价/整合，每日 cron 自动运行）。

## 自动任务输出协议

后台任务、cron、reflect/evaluate/consolidate、知识整理这类场景，经常会带 `[SILENT]` 或“无新内容则静默”的要求。遇到这种指令时，不要按普通聊天补话

如果本轮没有实际新增的记忆、评价、错误、文件改动或用户要求的任务结果，就只输出 `[SILENT]`

如果有结果，就只输出这次任务的结果。不要输出泛泛的 reflection 摘要，不要复述系统说明，不要把历史报告当成本轮产物，也不要为了显得完整而加“本次任务完成”之类空话

判断顺序是：先看是否有静默标记，再看是否真的有新结果，最后才决定输出报告还是 `[SILENT]`

## 架构

```
mile-knowledge/              # 根目录 (/root/.hermes/mile-knowledge/)
├── graphrag/                # GraphRAG 知识图谱 (650 行)
│   ├── graph.py             # NetworkX 有向图：增删查改+pickle 持久化
│   ├── extractor.py         # DeepSeek API 实体/关系提取
│   ├── indexer.py           # Louvain 社区检测 + embedding API 语义搜索
│   ├── embedding.py         # Embedding API 封装（mnapi.com, 批量编码+余弦相似度）
│   ├── config.py            # 自动读 ~/.hermes/.env（含 embedding API 配置）
│   └── cli.py               # 6 子命令入口 (python -m graphrag <cmd>)
├── agents/                  # 后台 Cron Agent + 模型 fallback
│   ├── _model.py            # V4Flash → DeepSeek 官网自动 fallback
│   ├── reflect.py           # 反思循环 — 每日 03:00
│   ├── evaluate.py          # 评价体系 — 每日 04:00
│   ├── critic.py            # 实时拦截器 (Layer 1)
│   ├── consolidate.py       # 整合器   — 每日 05:00
│   └── optimize.py          # Prompt 自动进化 (Layer 4)
├── data/                    # 持久化数据
│   ├── graph.pkl            # NetworkX 图快照
│   ├── embeddings.npz       # 实体向量索引
│   ├── communities.json     # 社区检测+摘要结果
│   ├── daily_eval_*.json    # 每日评价报告
│   └── eval_trend.json      # 趋势数据
└── requirements.txt         # Python 依赖
```

详见 `references/system-architecture.md`。

当用户询问知识系统架构、后台 agent、GraphRAG 数据流，或要求生成架构可视化时，不要只引用文档或只给生成文件路径。先在对话里用短句讲清楚 L1-L4 的关系：实时拦截先挡明显错误，evaluate/reflect 把失败沉淀成案例库，consolidate 只升级高质量记忆，optimize 再根据重复案例提出 prompt 修改。需要图示时可以直接给一个迷你 Mermaid 或 ASCII 数据流图，详细图再放到文件里

Embedding 模型替代方案（低配服务器曾因 420MB 模型下载宕机，三种替代方案已评估）详见 `references/embedding-migration.md`。

## 实时质量系统（Layer 1-3）

在三层质量架构之上，evaluate/reflect/consolidate 被扩展为闭环。

### Layer 1: 实时拦截 (critic.py + case_library.json) ✅ 已接入

`agents/critic.py` — 轻量回复检查器，已通过 gateway hook 接入对话链路。Hook 目录：`~/.hermes/hooks/critic-intercept/`（HOOK.yaml + handler.py），在 `agent:end` 事件触发。接入后用法：

```python
from agents.critic import check_reply
result = check_reply(user_message, bot_reply, case_library)
# → {"pass": True} 或 {"pass": False, "reason": "...", "fix_hint": "..."}
```

- 检查十一项：未按明确指令执行（不只做文字说明，也不替代执行）、上下文污染、分段忘记拆/机械分段、句尾违规、文档化输出、空泛机制化建议、未验证本地环境就下结论、故障反馈空泛化、无请求时挂下一步钩子、静默协议违背（有[SILENT]要求时无关输出即判失败）、只给文件路径不解释
- 从 `data/case_library.json` 检索相似历史失败案例作为 few-shot
- 使用独立模型配置（`CRITIC_API_KEY/BASE/MODEL` 环境变量），未设置时 fallback 到 `DEEPSEEK_*`（当前指向 SenseNova `token.sensenova.cn/v1`）。SenseNova 模型 quirks 见 `references/sensenova-platform.md`
- API 故障时默认放行（fail-open）
- CLI: `python3 agents/critic.py --user-msg "..." --bot-reply "..."`
- **Hook 接入详情**：见 `references/critic-gateway-hook.md`

⚠️ **已知坑**：handler.py 中 context key 名必须匹配 gateway run.py 传递的字段名。gateway 传的是 `message`（不是 `user_message`），bot 回复 key 是 `response`（不是 `assistant_message`）。key 名不匹配会导致 `user_msg` 恒为空、所有请求静默跳过。当前 handler.py 已用 `context.get("user_message") or context.get("message", "")` 兼容两种写法。

### Layer 2: 案例库自动构建 (evaluate + reflect → case_library)

- `evaluate.py` 评分完成后对每个低分会话（accuracy<5 或 consistency<5）调 API 提取失败案例卡，写入 `data/case_library.json`
- `reflect.py` 将高优先级 improvement_items 也写入案例库
- 案例卡格式：`{scenario, bad, good, trigger_keywords, source, session_id, created_at}`
- (scenario, bad) 组合去重
- `--dry-run` 模式下不写案例库

### Layer 3: 知识过滤 (consolidate --min-score)

- `consolidate.py` 新增 `--min-score` 参数（默认 7.0）
- 从 `data/daily_eval_*.json` 读取来源会话的评分
- 评分 < min-score 的记忆条目移至 `data/archived/` 而非升级

### Layer 4: 自动 Prompt 进化 (optimize.py)

`agents/optimize.py` — 当 `data/case_library.json` 中同一 scenario 累积 ≥3 条案例时触发（从 10 降到 3，提高响应速度）：

```bash
python3 agents/optimize.py --scan        # 扫描案例库
python3 agents/optimize.py --dry-run     # 分析但不写报告
python3 agents/optimize.py               # 完整执行 → optimization_report.json
python3 agents/optimize.py --threshold 1 # 强制低门槛触发（调试用）
```

- **当前 API 格式：OpenAI Chat Completions（非 streaming）**
  - `POST {base_url}/chat/completions`
  - 使用 `max_completion_tokens`（非 `max_tokens`）——部分端点强制要求
  - 不传 `temperature`（oaipro 仅支持默认值 1.0）
  - 响应解析：`body["choices"][0]["message"]["content"]`
  - 纯 httpx 实现，无 OpenAI SDK 依赖
- **ANALYSIS_PROMPT 已包含「更像人说话」原则**：
  - 优化后的提示词应让 AI 避免机器感强的结构化模板和分点列表
  - 改用自然对话流，像朋友聊天一样把信息揉进句子里
  - 遇到「禁止列点」类错误时，不是简单加禁令，而是示范什么才算像人说话
- 多端点格式切换注意事项见 `references/l4-api-formats.md`（Anthropic/OpenAI/SSE streaming 模式差异）
- 完整操作手册（端点配置、后台运行、输出缓冲、建议应用流程）见 `references/l4-optimization-workflow.md`
- **主力端点（当前在用）**：`https://api.oaipro.com/v1`，模型 `gpt-5.5`
  - API key: `sk-7xhacj4k3Ji2wiFZBBQW1kwdQ7K9hdmxginAS6278rAC3rytRDdh`
  - 限制：不支持 `thinking` 参数、`temperature` 仅默认值 1.0、必须用 `max_completion_tokens`
  - 非 streaming 响应，~20-30s/场景
  - 环境变量：`PROMPT_OPT_BASE_URL=https://api.oaipro.com/v1` `PROMPT_OPT_MODEL=gpt-5.5`
- **备选端点**：
  - `https://api.deepseek.com/anthropic` — 原生 Anthropic Messages API，模型 `deepseek-v4-pro`。key `sk-57e6bd1a654c4aa2bca6858cfed62c43`。支持 thinking 但会消耗 token。代码需切回 Anthropic 格式（`/messages` 端点 + `x-api-key` 头 + system 顶层字段）
  - `https://ai.centos.hk/v1` — **不可用**（硬 User-Agent 白名单，拒绝所有常见客户端。showdoc 文档需登录权限无法读取）
- 分析时自动读取上述文件全文作为上下文，输出带 `target_file`、`section`、`old_string`、`new_string` 的精确修改建议。这里的“精确”只有一个标准：`old_string` 必须是当前文件里能直接搜索到的连续原文，`new_string` 必须是可以直接替换进去的完整改文。

禁止只写“建立自动分段机制”“建立输出前自动分段机制”“默认口语化短句”“加强约束”“避免长段落”这类抽象方案。看到自己想写这种话时，必须当场转换成具体文件修改，例如把 SOUL.md 或 konata-default-persona/SKILL.md 里现有的分段规则整段复制到 `old_string`，再在 `new_string` 里补入更明确的触发条件、反例和示范句。

如果一时找不到可替换原文，不要用“待定位”糊弄；优先选择最接近的现有段落作为锚点，通过“在该段后新增……”的方式给出可执行替换文本。Prompt 优化任务的交付物不是优化理念，而是补丁
  - `~/.hermes/SOUL.md` — 灵魂/人格定义
  - `~/.hermes/skills/konata-default-persona/SKILL.md` — 泉此方内核人格
  - `~/.hermes/skills/mile-graphrag/SKILL.md` — 知识系统操作指令
  - `agents/critic.py` — 拦截器自身的 CRITIC_PROMPT

## 依赖与安装

```bash
cd /root/.hermes/mile-knowledge
pip install --break-system-packages -r requirements.txt
```

核心依赖：`networkx`, `openai`, `python-louvain`, `requests`, `numpy`。

Embedding 已切换为 mnapi.com API（方案三），不再需要 `sentence-transformers`。详见 `references/embedding-migration.md`。

DeepSeek API key 从 `~/.hermes/.env` 自动加载（`DEEPSEEK_API_KEY`），无需手动 export。

## 模型配置

**Agent 任务默认使用 `deepseek-v4-flash`**（更轻量，适合非对话批处理）。通过环境变量覆盖。

### 环境变量优先级（reflect.py / evaluate.py）

```python
api_key = os.environ.get("V4FLASH_API_KEY") or os.environ.get("DEEPSEEK_API_KEY", "")
base_url = os.environ.get("V4FLASH_BASE_URL") or os.environ.get("DEEPSEEK_BASE_URL", "https://api.deepseek.com/v1")
model    = os.environ.get("V4FLASH_MODEL")    or os.environ.get("DEEPSEEK_MODEL", "deepseek-v4-flash")
```

**优先级**：`V4FLASH_*` > `DEEPSEEK_*` > 代码默认值。

**为什么有 V4FLASH_***：`DEEPSEEK_API_KEY` 被主 Hermes 模型（deepseek-v4-pro，config.yaml `provider: deepseek`）和后台 agent **共享**。如果直接改 `DEEPSEEK_API_KEY` 切换到其他端点（如 SenseNova），主模型也会断开，导致 gateway 无响应（俗称"自杀"）。`V4FLASH_*` 变量提供独立的 agent 端点，不影响主模型。

```bash
# ~/.hermes/.env 中的配置示例
V4FLASH_API_KEY=sk-xxx                        # SenseNova 或其他代理端点
V4FLASH_BASE_URL=https://token.sensenova.cn/v1
V4FLASH_MODEL=deepseek-v4-flash

DEEPSEEK_API_KEY=sk-original-key              # 保持不动，供主模型使用
DEEPSEEK_BASE_URL=https://api.deepseek.com
DEEPSEEK_MODEL=deepseek-v4-flash
```

`consolidate.py` 通过 `graphrag/embedding.py` 调 mnapi.com API 做相似度计算，不依赖本地模型。

`critic.py` 使用独立环境变量（`CRITIC_API_KEY/BASE/MODEL`），未设置时 fallback 到 `DEEPSEEK_*`。当前 `DEEPSEEK_*` 已指向 SenseNova token 端点（`token.sensenova.cn/v1`），未单独设 `CRITIC_*` 的 critic 会自动走 SenseNova 上的 `deepseek-v4-flash`。

SenseNova 平台各模型的接口路径、quirks 和 pitfall 详见 `references/sensenova-platform.md`。

### V4Flash → DeepSeek 官网自动 Fallback

`agents/_model.py` 提供 `call_llm()` 统一入口，reflect.py 和 evaluate.py 的所有 OpenAI 调用都走它：

```python
from agents._model import call_llm

raw = call_llm(
    messages=[{"role": "system", "content": prompt}, {"role": "user", "content": text}],
    temperature=0.2,
    max_tokens=4096,
)
```

**Fallback 逻辑**：
1. 优先用 `V4FLASH_*` 环境变量指定的端点（当前是 SenseNova `token.sensenova.cn/v1`）
2. 如果 `V4FLASH_BASE_URL` 不是 `api.deepseek.com`（即走的是第三方代理），且调用失败，自动切到 DeepSeek 官网（`https://api.deepseek.com/v1` + `DEEPSEEK_API_KEY` + `deepseek-v4-flash`）
3. 如果一开始就是 DeepSeek 官网，失败不重试（避免无意义循环）

需要 fallback 的三个调用点已全部接入：`reflect.py` 的 `analyse_with_deepseek`、`evaluate.py` 的 `evaluate_session` 和 `extract_case_from_session`

## GraphRAG CLI

```bash
cd /root/.hermes/mile-knowledge

# 从文本提取实体和关系（写入 graph.pkl）
echo "MiLe 是一个二次元风格的 AI 助手" | python3 -m graphrag extract
python3 -m graphrag extract --file some_notes.txt

# 社区检测 + 向量索引构建（必须先有实体才能跑）
python3 -m graphrag index

# 语义搜索
python3 -m graphrag search "MiLe 的分段规则" --top-k 5

# 图统计
python3 -m graphrag stats

# 实体邻居查询
python3 -m graphrag neighbors "MiLe"

# 列出所有实体（可按 type 过滤）
python3 -m graphrag list --type concept

# 导出图谱为可移植 JSON
python3 -m graphrag export --output my_graph.json
```

## 后台 Agent

三个脚本每天通过 Hermes cron job 自动运行。也可手动 `--dry-run` 测试：

```bash
cd /root/.hermes/mile-knowledge

python3 agents/reflect.py --dry-run       # 反思循环
python3 agents/evaluate.py --dry-run      # 评价体系
python3 agents/consolidate.py --dry-run   # 整合器
```

去掉 `--dry-run` 实际写入。`--hours N` 控制扫描多少小时内会话。

### reflect.py — 反思循环
扫描 ~/.hermes/sessions/ 最近 24h 的对话，用 DeepSeek 分析：
- 被纠正了哪些错误
- 哪些场景表现不稳定
- 输出改进项 → 写入 evolution_memory + GraphRAG

### evaluate.py — 评价体系
对每段会话打三个分（准确性/表达一致性/响应速度，1-10），对比昨日趋势。连续两天某指标下降 → WARNING。报告存 `data/daily_eval_{date}.json`。

### consolidate.py — 整合器
扫描 ~/.hermes/evolution_memory/ 的候选条目：
- 相似度 > 0.7 → 合并
- 30 天未更新 → 降级/归档
- 高信心条目 → 升级到 ~/.hermes/memories/

## Cron 时间表

| 时间 | Job ID | 名称 | 做什么 |
|------|--------|------|--------|
| 03:00 | `40727aa575a0` | mile-reflect | 反思循环 |
| 04:00 | `ae97c2adbbda` | mile-evaluate | 评价体系 |
| 05:00 | `07e44ac329c9` | mile-consolidate | 整合器 |

用 `cronjob(action='list')` 查看状态，`cronjob(action='pause'|'resume'|'remove')` 管理。

## graphrag_search 工具

在 Hermes 中注册为 `graphrag_search` 工具（`tools/graphrag_search.py`），toolset 名 `graphrag`（可在 `toolsets.py` 中独立开关）。工具通过 `subprocess` 调 `python3 -m graphrag search`。

**前置条件**：`data/graph.pkl` 存在（由 `python3 -m graphrag extract` 或后台 agent 创建）。`check_requirements()` 以该文件存在为判断依据。

## Active Memory 集成（Evolution + GraphRAG Prefetch）

每轮对话前，evolution provider 的 `prefetch()` hook 会同时查询 GraphRAG 知识图谱做语义搜索，与 FTS5 关键词搜索形成双线召回。结果以 `## Knowledge Graph (GraphRAG)` 块注入上下文。

**启用**：`hermes config set plugins.evolution.enable_graphrag_prefetch true`

完整集成步骤、测试方法、与 OpenClaw 对比分析见 `references/evolution-graphrag-prefetch.md`。

**前置条件**：图谱已灌数据 + 向量索引已构建 + gateway 已重启。修改 evolution provider 代码或 embedding 配置后需清理 `__pycache__` 再重启。

## 初始化图谱

图谱初始为空。首次使用前需要灌入实体：

```bash
cd /root/.hermes/mile-knowledge

# 方式一：从 MEMORY.md 提取
python3 -m graphrag extract --file ~/.hermes/memories/*.md

# 方式二：手动喂文本
echo "MiLe 性格基于 konata-default-persona，默认中文，分段回复通过 terminal(true) 实现。" | python3 -m graphrag extract

# 构建索引
python3 -m graphrag index
```

`python3 -m graphrag index` 同时运行社区检测 + 向量索引构建。

## 实体类型 & 关系类型

定义在 `extractor.py` 的 extraction prompt 中：

| 实体类型 | 说明 |
|---------|------|
| entity | 具体人物、角色 |
| concept | 抽象概念、想法 |
| event | 发生过的事件 |
| technology | 技术、工具、框架 |

| 关系类型 | 说明 |
|---------|------|
| is_a | 子类/实例 |
| depends_on | 依赖 |
| created_by | 创建关系 |
| related_to | 一般关联 |
| contradicts | 矛盾 |
| extends | 扩展/继承 |

## 验证命令

```bash
cd /root/.hermes/mile-knowledge

# 图存储
python3 -c "from graphrag.graph import GraphManager; g = GraphManager(); g.add_entity('test'); print(g.get_stats())"

# 配置
python3 -c "from graphrag.config import DEEPSEEK_MODEL; print(DEEPSEEK_MODEL)"

# CLI stats（无依赖可跑）
python3 -m graphrag stats

# Agent --help
python3 agents/reflect.py --help
python3 agents/evaluate.py --help
python3 agents/consolidate.py --help

# 全系统接口一键验证（推荐）
python3 scripts/verify-interfaces.py          # 全部检查
python3 scripts/verify-interfaces.py --quick  # 仅导入检查（不调 API）
```

## Pitfalls

1. **`python` vs `python3`**：此环境没有 `python` 命令，必须用 `python3`。
2. **`__init__.py` 惰性导入**：graphrag 的 `__init__.py` 使用 `__getattr__` 惰性加载，直接 `import graphrag` 不会触发重依赖导入——只有实际使用时才加载 openai 等。embedding 模块通过 API 调用，无本地模型加载延迟。
3. **依赖安装需 `--break-system-packages`**：Debian 的 pip 默认拒绝系统级安装，必须加此标志。
4. **sentence-transformers 已移除（方案三生效）**：本机 RAM 1.6GB 无 swap，420MB 模型加载即 OOM；HuggingFace / hf-mirror 不可达。**已切换为 mnapi.com API**（`text-embedding-3-small`，1536维）。配置在 `~/.hermes/.env` 的 `EMBEDDING_API_KEY/BASE/MODEL`。HuggingFace 缓存已清理（释放 460MB）。不要尝试重装 sentence-transformers 或切换本地模型。
5. **图谱数据为空时 search 返回空**：`graphrag_search` 工具会返回 graph.pkl not found 错误；index 命令在空图上也能跑但社区检测无意义。
6. **cron job 需要 gateway 在线**：三个 cron job 由 Hermes 调度器管理，gateway 需保持运行。
7. **Gateway 需预加载此 skill**：启动命令 `hermes --skills konata-default-persona,mile-graphrag gateway run`，确保 skill 在每轮对话上下文中。
8. **模型默认值三处同步**：改默认模型时要同时更新 `graphrag/config.py`、`agents/reflect.py`、`agents/evaluate.py` 三处 fallback。建议用 `DEEPSEEK_MODEL` 环境变量统一覆盖。
10. **Agent 数据源是 state.db 不是 sessions 目录**：`reflect.py` 和 `evaluate.py` 通过 `session_reader.py` 从 `~/.hermes/state.db`（SQLite）读取真实对话内容。`~/.hermes/sessions/*.jsonl` 只存元数据（session_id, platform, token counts），不可用作分析。详见 `references/system-architecture.md`。
11. **Agent 脚本的 sys.path**：`session_reader.py` 在父目录，`reflect.py` 和 `evaluate.py` 开头有 `sys.path.insert(0, str(Path(__file__).parent.parent))`——修改导入路径时别删掉这行。
12. **分段回复 (terminal(true)) 是工具调用**
13. **OpenClaw 记忆架构可作参考**：研究结论已记录在 `references/openclaw-memory-architecture.md`，用于未来改进 MiLe 的记忆系统。核心差异：OpenClaw 有 Active Memory（阻断式预检索）和 Memory Flush（压缩前保存），MiLe 缺这两项。GraphRAG + evolution prefetch 打通后搜索层已对齐，详见 `references/evolution-graphrag-prefetch.md`。
14. **Evolution 代码修改后清缓存**：修改 `/usr/local/lib/hermes-agent/plugins/memory/evolution/__init__.py` 后，必须 `find ... -name __pycache__ -exec rm -rf {} +` 清缓存再重启 gateway，否则改动不生效。
14b. **mnapi API 端点必须用 `https://api.mnapi.com/v1`**：`www.mnapi.com` 有 Cloudflare 防护，返回 403 + JS Challenge 页面。所有 OpenAI-compatible 调用（embedding、critic chat completions）都要走 `api.mnapi.com/v1` 路径。env 中设 `CRITIC_API_BASE=https://api.mnapi.com/v1`，不是 `www`。
15. **GitHub push 凭据**：hermes-agent 使用 HTTPS remote。本环境无 `gh` CLI、无 SSH key。**经典 PAT (`ghp_*`)** 用 `https://TOKEN@github.com` 格式直接推送即可。**精细 PAT (`github_pat_*`)** 即使有 Contents:RW 权限也常被 git-over-HTTP 拒 403（只能 REST API 推）。详见 `references/embedding-migration.md`。
17. **L4 优化代理（ai.centos.hk）有严格的客户端白名单，不可用**：该代理检测 HTTP User-Agent，拒绝所有常见客户端（curl、httpx、Claude-Code、anthropic-python、Hermes/AgentSpace 等均被拒）。showdoc 文档需登录权限无法读取。**对策**：已切换至 `https://api.oaipro.com/v1`（OpenAI 格式，模型 gpt-5.5）。备选方案 `https://api.deepseek.com/anthropic`（Anthropic 格式，模型 deepseek-v4-pro）也验证可通。详见 Layer 4 章节的端点配置。
19. **optimize.py 后台运行时输出严重缓冲**：`python3 -u agents/optimize.py ...` 在 `terminal(background=true)` 执行时，`process log` 始终为空（即使加了 `-u`）。**解决方法**：将输出重定向到临时文件，然后 tail 读取——`python3 -u agents/optimize.py ... > /tmp/opt_result.txt 2>&1`。用 `grep -c "Analysis complete" /tmp/opt_result.txt` 跟踪进度。
20. **extract 命令长文本会 JSON 解析失败**：当 `--file` 传入的文本超过约 1000 字符时，DeepSeek API 返回的 JSON 可能被截断或格式错误，导致 extractor 静默返回空实体（graph 不变）。**对策**：将长文本拆成 100-300 字符的小段分批喂入。验证方法：跑完后 `python3 -m graphrag stats` 看 num_entities 是否增加。
16. **Cron job 的 `deliver: origin` 可能投递到错误的平台**：cron job 创建时会快照当前的 delivery 上下文（platform + chat_id）。如果创建时上下文不对（如在 CLI 或错误的频道创建），后续运行会投递到错误目标。症状：`last_status: error` + `delivery error: QQBot send failed: 400 ... 频道不存在`。修复：用 `cronjob(action='update', job_id='...', deliver='origin')` 更新 cron job，重置 delivery 上下文。下次运行时会用新的上下文投递。
19. **Edge 属性名是 `relation_type` 不是 `type`**：`graph.py` 的 `add_relation()` 方法用 `relation_type=` 关键字存入 edge 属性。读取时用 `attrs.get("relation_type", "related_to")`，不是 `attrs.get("type")`。写 JSON 导出器时用错属性名会导致所有边显示为 "?"。
20. **外部项目解析工作流**：大型代码库/文档集的解析策略——两层处理（静态分析→LLM 语义提取）、分段投喂避免 JSON 解析失败、导出可移植格式。详见 `references/external-project-parsing.md`。**MDX 文档生成**：从解析出的 API 数据生成 fumadocs 可渲染文档 → `references/wj-api-doc-generation.md`。**WJ 测试用例编写**：RunMap.tab 驱动模式的标准写法、命令格式参考、Lua 模板 → `references/wj-test-case-authoring.md`。**WJ 插件自动启动**：RunMap 命令解析器模式、Timer.AddFrameCycle 注册时机、依赖加载链、RobotDeathLoop 案例 → `references/wj-plugin-architecture.md`。
21. **Critic 拦截器仅在 agent 回复管道生效**：Hook 挂载在 `~/.hermes/hooks/critic-intercept/`，在 `agent:end` 事件触发。系统级自动生成的消息（如后台进程通知、平台适配器生成的下载指引）不经过此 hook，不会被 critic 检查。当用户质疑某条消息格式违规但未被拦截时，先判断消息是否走了 agent 回复通道。**可疑来源**：`background_process_notifications: all` 配置会在 tar/打包等后台进程完成时发送通知，可能被平台转成模板式结构化消息。症状：gateway/agent 日志无此消息痕迹。对策：`hermes config set background_process_notifications errors` 或 `none`。
22. **WJ RobotDeathLoop 坑**：① 操作对象是服务端机器人（`RobotControl.CMD`），不要用 `GetClientPlayer()` 或 `player:IsDead()` 读玩家状态。② 顺序是"复活→自杀"，别反过来。③ `Timer.AddCycle(10秒)` 就够了，别换成帧计数器过度设计。详见 `references/wj-plugin-architecture.md`。
23. **WJ 插件不自启是缺 RunMap 解析器**：所有 WJ 插件必须带模块级的 RunMap.tab 加载 + `Timer.AddFrameCycle` 命令解析器，否则 `Start()` 永不被调用。标准模板见 `references/wj-plugin-architecture.md`。
24. **HotPointMap 分支1去重架构**：不同插件版本的数据格式不同，StringSplit(",") 后的列偏移量因相机格式（有无尾逗号）而变。MapFarming2 比较 FPS（parts[10]），`<` 取最低帧率。详见 `references/wj-hotpoint-mapfarming-branch1.md`。
24b. **MapFarming.lua 三版对比**：原版（面数去重）→ 分支1（Ms去重）→ 分支2（全量保留不去重）。三个版本只改 `Process()`，其余一致。分支2 最简单但数据量大，依赖热力图平台端排序。⚠️ MapFarming.lua 和 MapFarming2.lua 的 `StringSplit` 列偏移不同（`parts[10]` 在一者是 Ms、在另一者是 FPS），不可混用。详见 `references/wj-mapfarming-branch-comparison.md`。
25. **WJ 用户偏好极简改动**：做功能开关时优先改 .lua 默认值或 .tab 硬编码，不要另建目录、不要改 .py 加 changeStrInFile 管道。用户明确拒绝过"另建 HotPointRunMapOneDepthB1 目录 + Interface.ini 条目"的方案。
26. **代码备份到 GitHub**：本地备份已准备（7828 文件，360M，已排除 Perfeye/日志/APK），但 push 步骤未执行。GitHub fork `https://github.com/Yu1Ko/hermes-agent` 当前仅含上游代码 + 少量本地提交（agentspace、graphrag tool），不含 custom-skills/ 和 mile-knowledge/。推送需要 Classic PAT (`ghp_*`)，精细 PAT 会 403。完整流程 + 排除规则见 `references/code-backup.md`。
27. **切换后台 agent 端点时不要直接改 DEEPSEEK_API_KEY**：`DEEPSEEK_API_KEY` 被两个消费者共享——主 Hermes 模型（config.yaml `provider: deepseek`，用于实时对话）和后台 agent（reflect.py / evaluate.py，用于批量分析）。直接改成其他端点（如 SenseNova）会导致主模型断开、gateway 无响应。**正确做法**：新增 `V4FLASH_API_KEY` / `V4FLASH_BASE_URL` / `V4FLASH_MODEL` 环境变量，agent 代码优先读 `V4FLASH_*`，未设置才回退到 `DEEPSEEK_*`。详见「模型配置」章节。
28. **WJ MapFarming CSV 列偏移：GetHotPointReader vs GetPerfData**：两个数据源的 CSV 格式完全不同。GetHotPointReader 版本（分支1/2、模板版）相机串有尾逗号 `"(0.00, 0.00, 0.00),"` → Split 后 FPS=parts[10]、Ms=parts[11]。GetPerfData 版本（最终版）相机串无尾逗号 → FPS=parts[7]。用错列索引会拿到完全错误的数据。完整版本对照见 `references/wj-hotpoint-mapfarming-branch1.md`。
29. **WJ 最小改动原则**：用户对公用文件偏好最小改动。模板版的 nIndex 去重 + CompareConfig 切换策略是最小实现——不需要 GridTracker、不需要 GridPointData、不需要改 key 格式。分支2 版本的最小分支1化只需改 Process() 里 6 行，复用已有 GridPointData。不要为单一策略添加新结构。
30. **SenseNova (token.sensenova.cn) 端点不稳定**：商汤代理偶尔不可用（可能导致 evaluate/reflect 空跑）。`agents/_model.py` 已内置自动 fallback 到 DeepSeek 官网。症状：cron evaluate 全部返回 0 分且 notes=api error。验证方法：`curl https://token.sensenova.cn/v1/models -H "Authorization: Bearer $V4FLASH_API_KEY"`。如果通但还是失败，检查 `V4FLASH_BASE_URL` 是否正确设置。
