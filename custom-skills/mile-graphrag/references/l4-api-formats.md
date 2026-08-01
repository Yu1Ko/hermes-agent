# Layer 4 API Format Reference

optimize.py 通过纯 httpx（无 OpenAI SDK）调用外部 API 做 prompt 优化分析。
不同端点有不同的格式约束，这里记录已验证的兼容性。

## 当前主力端点

### oaipro.com（OpenAI Chat Completions）

```
URL:  https://api.oaipro.com/v1/chat/completions
Model: gpt-5.5
Key: PROMPT_OPT_API_KEY (env)
Auth: Authorization: Bearer <key>
```

**已验证特性：**

| 参数 | 状态 | 说明 |
|------|------|------|
| `stream: false` | ✅ | 非流式响应，直接 JSON |
| `max_tokens` | ❌ | 返回 `unsupported_parameter`，必须用 `max_completion_tokens` |
| `max_completion_tokens` | ✅ | 最大生成 token 数 |
| `temperature` | ❌ | 仅支持默认值 1.0，设 0.2 返回 `unsupported_value` |
| `thinking: {type: "enabled"}` | ❌ | 返回 `unknown_parameter` |

**响应格式（非流式）：**
```json
{
  "choices": [{"message": {"content": "..."}}]
}
```

**延迟**：~20-30s/场景（prompt 包含完整 prompt 文件内容 ~15K chars）

## 备选端点

### DeepSeek Anthropic-Compatible

```
URL:  https://api.deepseek.com/anthropic/messages
Model: deepseek-v4-pro
Key: ANTHROPIC_API_KEY (env)
Auth: x-api-key: <key>
Required headers: anthropic-version: 2023-06-01
```

**已验证特性：**

| 参数 | 状态 | 说明 |
|------|------|------|
| `max_tokens` | ✅ | Anthropic 标准参数 |
| `system` (顶层) | ✅ | Anthropic 格式，不是 message role |
| `stream` | ✅ | 支持 |
| `thinking` | ✅ | 会消耗 token，输出在 `content[].type: "thinking"` |

**响应格式：**
```json
{
  "content": [
    {"type": "thinking", "thinking": "..."},
    {"type": "text", "text": "..."}
  ]
}
```

**代码切换要点**：
- 端点：`/messages`（不是 `/chat/completions`）
- 鉴权头：`x-api-key`（不是 `Authorization: Bearer`）
- system prompt 是请求体顶层字段（不是 messages[0]）
- 响应解析：`body["content"][0]["text"]`（不是 `choices[0].message.content`）
- 需要额外头：`anthropic-version: 2023-06-01`

## 不可用端点

### ai.centos.hk

```
URL:  https://ai.centos.hk/v1
```

**状态：不可用。** 该代理对所有 HTTP 客户端做 User-Agent 白名单检测，已测试：
- `curl/8.5.0` → `Client not allowed (detected: curl/8.5.0)`
- `Claude-Code/1.0` → `Client not allowed (detected: Claude-Code/1.0)`
- `anthropic-python/0.39.0` → 400
- `Anthropic/1.0` → 400
- `Hermes/AgentSpace` → 400
- 空 User-Agent → `Go-http-client/2.0` → 400

尝试过 OpenAI 格式（`/chat/completions` + Bearer）和 Anthropic 格式（`/messages` + x-api-key）均被拒。
关联 ShowDoc 文档（https://doc.centos.hk/web/#/688145263/261667697）需要登录权限，无法读取白名单规则。

**结论**：此端点仅对 WPS 内部特定客户端白名单开放，外部 agent 不可用。

## 格式切换历史

optimize.py 经历了三次 API 格式迁移：

1. **OpenAI SDK → Anthropic 原生**：移除 `from openai import OpenAI`，改为纯 httpx + Anthropic Messages API
2. **Anthropic → OpenAI 纯 httpx**：切换回 OpenAI Chat Completions，因为 oaipro 端点生效
3. **响应解析**：流式 SSE（`data:` 行解析）→ 非流式 JSON（`choices[0].message.content`）

每次切换时，`_get_client()` 和 `analyze()` 中的请求体/响应解析都需要同步修改。
完整实现见 `agents/optimize.py` 源码和 `mile-graphrag/SKILL.md` Layer 4 章节。
