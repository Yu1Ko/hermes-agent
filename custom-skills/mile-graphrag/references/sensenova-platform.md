# SenseNova Platform — Model Quirks & Endpoints

SenseNova (商汤) token endpoint: `https://token.sensenova.cn/v1`

文档: https://platform.sensenova.cn/docs

## 可用模型

| Model ID | 用途 | 接口 | 限额 | 注意 |
|----------|------|------|------|------|
| `deepseek-v4-flash` | 对话 | `POST /v1/chat/completions` | 150次/5h | 正常 OpenAI 格式，支持思考模式 |
| `sensenova-6.7-flash-lite` | 对话+多模态 | `POST /v1/chat/completions` | 1500次/5h | 256K上下文/64K输出；**默认reasoning模式，必须设`reasoning_effort:none`**；视觉已测试通过 | **免费** |
| `sensenova-u1-fast` | 信息图生成 | `POST /v1/images/generations` | 1500次/5h | **不走 chat completions！** | **免费** |

## Critical Pitfalls

### 1. flash-lite 只出 reasoning 不出 content

**症状**：调用 `sensenova-6.7-flash-lite` 后，`choices[0].message.content` 为空，`reasoning` 字段有大量思考过程文本。

**原因**：模型默认启用思考模式，所有 token 被 reasoning 消耗（`finish_reason: "length"`）。

**修复**：请求中加 `"reasoning_effort": "none"`。

```bash
# ❌ 不工作
{"model":"sensenova-6.7-flash-lite","messages":[...]}

# ✅ 正常工作
{"model":"sensenova-6.7-flash-lite","messages":[...],"reasoning_effort":"none"}
```

### 2. U1 Fast 报 "model is not found"

**症状**：`POST /v1/chat/completions` 返回 404 `model is not found`。

**原因**：U1 Fast **不是对话模型**，是图像生成模型。接口是 `/v1/images/generations`。

**正确调用**：

```bash
curl https://token.sensenova.cn/v1/images/generations \
  -H "Authorization: Bearer {key}" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "sensenova-u1-fast",
    "prompt": "...详细的图像描述...",
    "size": "2752x1536",
    "n": 1
  }'
```

**支持的尺寸**（11 种）：
- `1664x2496` (2:3) / `2496x1664` (3:2)
- `1760x2368` (3:4) / `2368x1760` (4:3)
- `1824x2272` (4:5) / `2272x1824` (5:4)
- `2048x2048` (1:1)
- `2752x1536` (16:9) / `1536x2752` (9:16)
- `3072x1376` (21:9) / `1344x3136` (9:21)

**响应格式**：
```json
{"created": 1713167890, "data": [{"url": "https://cdn.sensenova.dev/gen/..."}]}
```

**限制**：prompt 最大 4096 tokens。仅输出图片，不支持图像输入。

**CDN URL 有效期**：返回的签名 URL 有效期为 1 小时（`X-Amz-Expires=3600`）。超时后返回 AccessDenied。需要时重新生成。图片下载到本地后无此限制。

**已生成示例**：`/tmp/mile-rescue-infographic.png` (2752×1536, 3.9MB)，主题为「MiLe 服务器自救指南」。

### 3. Hermes 内置 vision_analyze 工具不支持图片

**症状**：调用 `vision_analyze` 工具时返回 `unknown variant image_url`。

**原因**：`vision_analyze` 使用主模型（deepseek-v4-pro，`provider: deepseek`），该模型不支持图片输入。

**修复**：直接用 sensenova-6.7-flash-lite + `reasoning_effort: "none"` 的 curl 调用读图。支持 `data:image/png;base64,...` 和远程 URL 两种图片格式。大图（>500KB）需先压缩或使用远程 URL 避免 base64 过大。

### 5. QQ 服务器无法拉取 S3 签名 URL

**症状**：用 `url` 参数调 QQ Bot 文件上传 API 时返回 850026「富媒体文件下载失败」。

**原因**：SenseNova 返回的图片 URL 是 AWS S3 签名链接，QQ 服务器无法解析或签名不兼容。

**修复**：用 `file_data`（base64）直传，或先将图片转存到公网可直达的 CDN。

## 端点切换记录

2026-05-08：后台 agent (reflect/evaluate/consolidate/critic) 的 v4-flash 调用从 `api.deepseek.com` 切换到 `token.sensenova.cn`。

- `DEEPSEEK_API_KEY` → SenseNova token (`sk-1Yp...`)
- `DEEPSEEK_BASE_URL` → `https://token.sensenova.cn/v1`
- `DEEPSEEK_MODEL` → `deepseek-v4-flash`（不变）

⚠️ **注意 clash**：主 Hermes 模型的 `provider: deepseek` 也读 `DEEPSEEK_API_KEY`，但 `config.yaml` 中 `model.base_url` 仍然是 `api.deepseek.com`。如果 gateway 重启后发现主模型断连，说明 config 层的 base_url 覆盖了 env 的 base_url 但 API key 仍来自 env——需检查此组合是否兼容。
