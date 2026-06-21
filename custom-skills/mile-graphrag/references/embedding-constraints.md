# Embedding 方案约束与替代

> 2026-05-04 — 本服务器无法使用 sentence-transformers 本地模型。

## 硬件约束

- **RAM**: 1.6GB 总量，空闲通常 < 200MB
- **Swap**: 无
- **结论**: 任何 > 100MB 的模型加载即超时/OOM

## 网络约束

- **HuggingFace** (huggingface.co): curl 超时不可达
- **hf-mirror.com**: 同样超时
- **modelscope.cn**: 未测试但大概率同理
- **结论**: 无法从外部下载新模型

## 当前可用 embedding 方案

### 方案一：TF-IDF（本地）

- 依赖：`sklearn.feature_extraction.text.TfidfVectorizer`（已有）
- 零下载、零额外内存、零网络
- 精度：关键词级别语义匹配，对实体名/描述的场景够用
- 需改动文件：`graphrag/indexer.py`, `agents/consolidate.py`, `agents/critic.py`, `graphrag/config.py`

### 方案三：mnapi.com API（远程）

API 端点验证结果（2026-05-04）：

| 模型 | 维度 | 状态 |
|------|------|------|
| `text-embedding-3-small` | 1536 | ✅ 可用 |
| `text-embedding-3-large` | 3072 | ✅ 可用 |
| `text-embedding-ada-002` | 1536 | ✅ 可用 |
| `text-embedding-v1` (阿里) | - | ❌ 无可用渠道 |

- **Base URL**: `https://api.mnapi.com/v1`
- **API Key**: 用户提供的 sk-t45NgCe...（账户 soft_limit = $100M，无额度限制）
- **格式**: OpenAI 兼容（`/v1/embeddings` 端点）
- **费用**: 未知（网站被 Cloudflare 保护，定价页不可达），但 embedding token 量极小，预计 < $0.01/月
- **需改动文件**: 同上四文件，但改为 HTTP API 调用而非本地模型

## 推荐

当前图谱规模极小（0 实体），**先用方案一（TF-IDF）快速让系统跑起来**。后续如果需要更强语义精度，切换到方案三的 API 调用成本很低——两者共享相同的调用接口抽象。
