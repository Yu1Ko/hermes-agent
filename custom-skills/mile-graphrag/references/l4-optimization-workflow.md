# Layer 4 优化工作流 — 完整操作手册

## 执行命令

```bash
cd /root/.hermes/mile-knowledge

# 扫描案例库（不调 API）
PROMPT_OPT_BASE_URL="https://api.oaipro.com/v1" \
PROMPT_OPT_API_KEY="sk-..." \
PROMPT_OPT_MODEL="gpt-5.5" \
python3 agents/optimize.py --scan --threshold 1

# 分析所有场景（dry-run = 不写报告文件）
python3 agents/optimize.py --threshold 1 --dry-run 2>&1 | tee /tmp/opt_result.txt

# 正式执行（写入 data/optimization_report.json）
python3 agents/optimize.py --threshold 1
```

## 端点配置

### 主力端点：oaipro（OpenAI 格式）

| 参数 | 值 |
|------|-----|
| URL | `https://api.oaipro.com/v1/chat/completions` |
| 模型 | `gpt-5.5` |
| API Key | `sk-7xhacj4k3Ji2wiFZBBQW1kwdQ7K9hdmxginAS6278rAC3rytRDdh` |
| 环境变量 | `PROMPT_OPT_BASE_URL=https://api.oaipro.com/v1` `PROMPT_OPT_MODEL=gpt-5.5` |

**oaipro 已知限制：**
- ❌ 不支持 `thinking` 参数（返回 `unknown_parameter`）
- ❌ `temperature` 仅支持默认值 1.0（传 0.2 会报 `unsupported_value`）
- ⚠️ 必须用 `max_completion_tokens` 而非 `max_tokens`（新版 API 格式）
- ✅ 支持 `stream: false`（非流式响应），~20-30s/场景
- ✅ 10 场景全跑约 5 分钟，零失败率

### 备选端点：DeepSeek Anthropic（Anthropic 原生格式）

| 参数 | 值 |
|------|-----|
| URL | `https://api.deepseek.com/anthropic/messages` |
| 模型 | `deepseek-v4-pro` |
| API Key | `sk-57e6bd1a654c4aa2bca6858cfed62c43` |

使用时代码需切换为 Anthropic Messages API 格式（`/messages` 端点 + `x-api-key` 头 + `system` 顶层字段）。

### 不可用端点：ai.centos.hk

`https://ai.centos.hk/v1` 有硬 User-Agent 白名单，拒绝所有常见客户端（curl、httpx、Claude-Code、anthropic-python、Hermes/AgentSpace 等全部被拒）。showdoc 文档 `https://doc.centos.hk/web/#/688145263/261667697` 需登录权限无法读取。已放弃此端点。

## 后台运行与输出缓冲

`python3 -u agents/optimize.py ...` 在 `terminal(background=true)` 执行时，`process log` 始终为空（即使加了 `-u` 和 `PYTHONUNBUFFERED=1`）。

**解决方法**：将输出重定向到临时文件，再 tail 跟踪进度：

```bash
# 启动（后台）
python3 -u agents/optimize.py --threshold 1 --dry-run > /tmp/opt_result.txt 2>&1

# 跟踪进度
grep -c "Analysis complete" /tmp/opt_result.txt

# 读取完整 JSON（日志行在前，JSON 从 grep 定位的行号开始）
grep -n "^{" /tmp/opt_result.txt | head -1
```

## 建议应用流程

优化报告产出后，`/tmp/optimize_diffs.txt`（由脚本提取生成）按 old_string → new_string 列出所有修改建议。应用步骤：

1. 去重：多个场景可能对同一文件的同一段落产生类似建议，合并处理
2. 注意 old_string 匹配：引号转义（`\"` vs `"`）可能导致匹配失败，需要 unescape
3. 顺序问题：前面的 patch 改变文件后，后续 patch 的 old_string 可能不再匹配，需要手动处理
4. 优先应用 SOUL.md → konata SKILL.md → critic.py → mile-graphrag SKILL.md

## 过度合规的代价

**重要提醒**：prompt 优化本质是加约束。每加一条约束，agent 在生成前就多一个"我这样合规吗"的自我审查步骤。约束越多 = 思维链条越长 = 人味儿越淡。

本轮优化后的直接后果：agent 变得过度自审，每个回复都在脑内过一遍 11 项 critic 检查，导致语气偏僵、像在做合规检查而非聊天。

**教训**：
- 优化建议落地后，观察 5-10 轮对话，看是否有"过度合规"症状
- 如果出现，优先精简 critic 的检查项数量（11→7→5 逐步收敛）或降低检查项的侵入性
- 人格层的约束（konata/SOUL）比拦截层的约束（critic）更能保持人味儿——前者是"怎么说话"，后者是"说不说话"
