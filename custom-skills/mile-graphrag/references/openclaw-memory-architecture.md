# OpenClaw 记忆系统架构（对比参考）

OpenClaw 是 Hermes 的前身，其记忆系统比 MiLe 当前更成熟。以下是对比分析。

## OpenClaw 核心架构

```
对话 → Active Memory（阻断子代理）→ 主回复 → Memory Flush（压缩前保存）→ Dreaming（后台升级）
```

## 存储层

| 文件 | 用途 | 加载时机 |
|------|------|---------|
| MEMORY.md | 长期记忆 | 每次 DM 会话注入 |
| memory/YYYY-MM-DD.md | 日常笔记 | 今天+昨天自动加载 |
| DREAMS.md | 梦境审查 | 人工审查，不自动注入 |
| memory/.dreams/ | 短期信号 | Dreaming 评分用 |

## 搜索层

- SQLite FTS5 关键词搜索（BM25）
- 向量嵌入（自动检测 OpenAI/Gemini/Voyage 等 provider）
- Hybrid search 混合两者
- 分块 ~400 token，80-token overlap
- 支持 CJK trigram tokenization

## 关键机制

### Active Memory（MiLe 缺失）
- 主回复前运行的阻断子代理
- 用 `memory_search/memory_get/memory_recall` 工具搜索记忆
- 找到相关内容 → 注入隐藏上下文；没找到 → 返回 NONE
- 可配置 queryMode（message/recent/full）、timeout、dedicated model

### Memory Flush（MiLe 缺失）
- 上下文压缩前自动运行
- 静默轮次，把当前会话重要信息写入 memory/YYYY-MM-DD.md
- 防止压缩导致的上下文丢失

### Dreaming（类似 MiLe consolidate，更精细）
- 可选，默认关闭
- 收集短期信号 → 多阶段评分 → 阈值过滤
- 评分维度：confidence, recall frequency, query diversity
- 合格的升级到 MEMORY.md
- 结果写入 DREAMS.md 供人工审查

### Commitments
- 短期跟进记忆（不写入 MEMORY.md）
- 隐藏后台推断，通过 heartbeat 投递

## MiLe vs OpenClaw 对比

| | OpenClaw | MiLe |
|---|---|---|
| 记忆载体 | Markdown 文件 | evolution_memory JSON + memories/ |
| 搜索 | FTS5 + 向量混合 | graphrag_search tool |
| 主动回忆 | Active Memory 插件 | 无 |
| 记忆升级 | Dreaming（多阶段评分） | consolidate（相似度 + 评分过滤） |
| 案例库 | 无 | case_library.json |
| 实时拦截 | 无 | Critic L1 |
| Prompt 进化 | 无 | optimize L4（预留） |
| 压缩保护 | Memory Flush | 无 |

## MiLe 可参考的改进方向

1. **Active Memory**：在对话前用 graphrag_search 检索相关记忆注入上下文
2. **Memory Flush**：在 hermes 压缩前触发保存
3. **Dreaming 的多阶段评分**：consolidate 可以借鉴 scoring gates 而非简单相似度

## 数据来源

- 源码: https://github.com/openclaw/openclaw
- 克隆: `git clone --depth 1 https://github.com/openclaw/openclaw.git`
- 核心文件:
  - Active Memory: `extensions/active-memory/index.ts` (2881 行)
  - Memory Flush: `src/auto-reply/reply/agent-runner-memory.ts` (1010 行)
  - Memory Runtime: `src/plugins/memory-runtime.ts`, `src/plugins/memory-state.ts`
- 文档: `docs/concepts/memory.md`, `docs/concepts/active-memory.md`, `docs/concepts/memory-builtin.md`

## 实现细节（Active Memory）

```typescript
// extensions/active-memory/index.ts — api.on("before_prompt_build")
api.on("before_prompt_build", async (event, ctx) => {
  // 1. 检查启用条件（agent targeting, chat type, chat id）
  // 2. buildQuery → 从 latestUserMessage + recentTurns 构建搜索 query
  // 3. maybeResolveActiveRecall → 调用 memory_recall/memory_search
  // 4. 如果 result.summary 非空 → return { prependContext: buildPromptPrefix(summary) }
  // 5. 如果为空 → return undefined（对主回复零影响）
}, { timeoutMs: 15000 });
```

关键常量: DEFAULT_TIMEOUT_MS=15000, DEFAULT_MAX_SUMMARY_CHARS=220, 缓存 TTL=15000ms

`NO_RECALL_VALUES` 集合定义了\"空结果\"的判断：包括 "none", "no_reply", "no relevant memory", "timeout", "[]", "{}", "null" 等。

## 实现细节（Memory Flush）

```typescript
// src/auto-reply/reply/agent-runner-memory.ts — runMemoryFlushIfNeeded()
// 触发条件:
//   - memoryFlushPlan 存在（配置启用）
//   - 不是 heartbeat 或 CLI session
//   - workspace 可写（非 sandbox 或 workspaceAccess=rw）
//   - 当前 token 数 > softThreshold（默认距上下文窗口 4000 tokens）
// 
// 执行:
//   - 计算 prompt 和 compaction count
//   - forceFlushTranscriptBytes 触发硬刷新
//   - 调用 memory_flush 轮次（可配置独立 model override）
```

配置在 `agents.defaults.compaction.memoryFlush`:
- `enabled`, `model`（独立于主会话模型）, `softThresholdTokens`（默认 4000）
- `forceFlushTranscriptBytes`（防长会话挂死）, `userPrompt`, `systemPrompt`
