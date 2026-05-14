# Embedding 迁移：sentence-transformers → mnapi.com API

## 背景

MiLe 知识管理系统原使用 `sentence-transformers` 的 `paraphrase-multilingual-MiniLM-L12-v2`（420MB）做语义搜索、记忆合并相似度、案例库检索。本机硬件/网络约束：

| 约束 | 详情 |
|------|------|
| 内存 | 1.6GB RAM，无 swap，可用仅 ~115MB |
| 网络 | HuggingFace / hf-mirror 从本机不可达 |
| 历史 | 加载 420MB 模型曾两次导致服务器宕机 |

## 三方案评估

| 维度 | 方案1 TF-IDF | 方案2 小本地模型 | **方案3 mnapi API（最终采用）** |
|------|-------------|----------------|------|
| 服务器负担 | 零 | 需下载 80MB（网络不可达） | 零 |
| 外部依赖 | sklearn（已有） | HF 下载（不通） | 网络 + API |
| 语义精度 | 中等 | 高 | 最高 |
| 延迟 | 零 | 零 | ~5s/批（5条实体） |
| 费用 | 免费 | 免费 | 微量（~133 tokens/批） |
| 稳定性 | 最高 | 依赖下载 | 依赖第三方 API |

方案二因 HuggingFace 不可达而排除。方案三语义精度最优，当前系统规模极小（0实体/2记忆/5案例），API 延迟和费用可忽略。

## 采用端点

- **Base URL**: `https://api.mnapi.com/v1`
- **模型**: `text-embedding-3-small`（1536维）
- **认证**: Bearer token（`sk-t45Ng...`）
- **Billing**: 软限额 $100M，基本无限

可用模型（已验证）：
- `text-embedding-3-small` ✅ 1536维
- `text-embedding-3-large` ✅ 3072维
- `text-embedding-ada-002` ✅ 1536维
- `text-embedding-v1`（阿里）❌ 无可用渠道

## 实施改动

### 新增文件
- `graphrag/embedding.py` — 统一 API 封装，`embed_texts()` + `cosine_similarity()`

### 修改文件
| 文件 | 改动 |
|------|------|
| `graphrag/config.py` | 删除 `EMBEDDING_MODEL`，新增 `EMBEDDING_API_KEY/BASE/MODEL` |
| `graphrag/indexer.py` | `QueryEngine` 去掉 `SentenceTransformer`，改用 `embed_texts()` |
| `agents/consolidate.py` | 去掉 pairwise 编码，改为一次批量编码所有候选后本地算相似度 |
| `agents/critic.py` | `_find_similar_cases` 批量编码 query+cases，一次 API 调用 |
| `requirements.txt` | 去掉 `sentence-transformers`，加 `requests` |
| `graphrag/__init__.py` | 更新导出列表 |

### 环境变量（`~/.hermes/.env`）
```bash
EMBEDDING_API_KEY=sk-t45NgCeHR8JdBplmOFWkbD9RExY8TThuPrl7yFu1IDCOf05E
EMBEDDING_API_BASE=https://api.mnapi.com/v1
EMBEDDING_API_MODEL=text-embedding-3-small
```

### 清理
- 删除 `~/.cache/huggingface/`（释放 460MB）

## 测试结果（2026-05-04）

```
=== 1. embedding 模块 ===
编码 3 条，维度 1536
相似度: MiLe=0.614, QQ=0.232, DeepSeek=0.125

=== 2. 索引构建 ===
索引进完，5 个实体

=== 3. 语义搜索 ===
  「MiLe 是谁」→ ['MiLe(0.52)', 'DeepSeek(0.24)', 'QQ Bot(0.22)']
  「QQ 怎么发消息」→ ['QQ Bot(0.50)', 'MiLe(0.30)', 'DeepSeek(0.21)']
  「用什么语言模型」→ ['GraphRAG(0.39)', 'MiLe(0.37)', 'QQ Bot(0.31)']

=== consolidate --dry-run ===
2 候选正确处理，正确识别 1 条待提升记忆（3 项高优先级建议）

=== critic ===
正确识别"只总结不执行"问题
```

## 关键注意事项

1. **不要重装 sentence-transformers**：HuggingFace 不可达 + 内存不足，装了也用不了
2. **embed_texts 支持批量**：一次最多 100 条文本，减少 API 调用次数
3. **consolidate 已优化**：原来是 O(N²) 次 API 调用（每对比较各编码一次），现在一次批量编码全量候选后本地算相似度
4. **搜索延迟**：单次查询需 ~5s（1 次 API 调用），对非实时场景可接受

## GitHub Push 注意事项

本环境无 `gh` CLI、无 SSH key、无 credential helper。

### Token 类型差异（已验证）

| Token 类型 | git push | REST API | 说明 |
|-----------|----------|----------|------|
| **经典 PAT** (`ghp_*`) | ✅ `https://TOKEN@github.com` 直接推 | ✅ | 推荐，最省事 |
| **精细 PAT** (`github_pat_*`) | ❌ 即使有 Contents:RW 也被拒 403 | ✅ | git-over-HTTP 不通，只能 REST API 做 blob/tree/commit/ref |

### 推送命令

```bash
# 经典 token 直接嵌入 URL（最可靠）
git push "https://ghp_XXXXXXXXXXXXXXXXXX@github.com/Yu1Ko/hermes-agent.git" main

# 恢复 clean URL 避免 token 泄露到 git config
git remote set-url yu1ko https://github.com/Yu1Ko/hermes-agent.git
```

### 精细 token 的 REST API 替代方案

如果只有精细 token，可以用 GitHub REST API 分步推送（创建 blob → tree → commit → update ref），但步骤繁琐。建议直接用经典 token 或配 SSH key。

### 本机 remote 配置

```
origin   → https://github.com/NousResearch/hermes-agent.git (上游)
upstream → https://github.com/NousResearch/hermes-agent.git (fetch)
yu1ko    → https://github.com/Yu1Ko/hermes-agent.git       (用户的 fork)
```
