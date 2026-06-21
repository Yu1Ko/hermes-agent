# web-access 在 Hermes Agent 环境下的适配

## 环境差异

web-access 原本为 Claude Code 设计。在 Hermes Agent 中，以下概念需要转换：

| Claude Code 概念 | Hermes 对应 |
|-----------------|------------|
| `${CLAUDE_SKILL_DIR}` | `~/.hermes/skills/web-access/` |
| `/eval` (slash command) | `browser_snapshot` 或 terminal: `curl http://localhost:3456/eval` |
| `/click` | `browser_click` 或 terminal: `curl http://localhost:3456/click` |
| `/scroll` | `browser_scroll` 或 terminal: `curl http://localhost:3456/scroll` |
| WebSearch 工具 | Hermes 内置 `web_search` |
| WebFetch 工具 | Hermes 内置 `web_fetch` |
| delegate_task (子 Agent) | Hermes 内置 `delegate_task` |

## CDP Proxy 使用

CDP Proxy 脚本（`scripts/cdp-proxy.mjs`）是跨平台的，在 Hermes 中**完全可用**。启动方式相同：

```bash
node ~/.hermes/skills/web-access/scripts/cdp-proxy.mjs
```

通过 curl 调用 HTTP API 的方式在 Hermes 中同样有效（使用 `terminal` 工具）。

## 联网工具优先级

CDP Proxy（直连本地浏览器）能力最强、限制最少，**优先使用**。Hermes 原生 `browser_*` 工具作为兜底。

| 场景 | 优先使用 |
|------|---------|
| 所有网页浏览、动态页面、交互操作 | **CDP Proxy**（`curl localhost:3456/...`） |
| 需要登录态、反爬站点 | **CDP Proxy**（edge/chrome 天然携带登录态） |
| 服务器无浏览器可用 | Hermes `browser_*` 工具（Browserbase 兜底） |
| 轻量信息提取 | `web_search` + `web_fetch` |

注意：CDP Proxy 和 Hermes `browser_*` 同时存在时，**优先走 CDP Proxy**，因为它是真实浏览器实例，反爬能力更强。

## 服务器 Edge CDP 部署

本环境已部署 Microsoft Edge headless + CDP Proxy。启动方式：

```bash
bash ~/.hermes/skills/web-access/scripts/start-edge-cdp.sh
```

脚本自动完成：杀旧进程 → 启动 Edge headless (port 9222) → 提取 WebSocket UUID 写入 `DevToolsActivePort` 文件 → 启动 CDP Proxy (port 3456) → 验证连接。

**关键细节**：
- Edge 的 CDP WebSocket 需要 UUID 路径（如 `/devtools/browser/xxx-xxx`），但 CDP Proxy 默认用通用路径 `/devtools/browser` 连不上
- 解决：Edge 启动后从 `/json/version` 提取 UUID，写入 `~/.config/google-chrome/DevToolsActivePort`，Proxy 会自动读取
- Edge 每次重启 UUID 会变，所以要用脚本自动化

| 组件 | 地址 |
|------|------|
| Edge CDP | `http://127.0.0.1:9222` |
| CDP Proxy | `http://127.0.0.1:3456` |
| Proxy 日志 | `/tmp/cdp-proxy.log` |
| Edge 日志 | `/tmp/edge-cdp.log` |

**桌面环境**：使用用户本地 Chrome/Chromium。检测方式：

```bash
node ~/.hermes/skills/web-access/scripts/check-deps.mjs
```

## 安装注意事项

`hermes skills install https://...` 需要交互式确认（选择 category + Confirm [y/N]），在非交互环境下会卡住。

**Workaround**：手动下载文件到 `~/.hermes/skills/web-access/`：
```bash
mkdir -p ~/.hermes/skills/web-access/scripts
curl -sL https://raw.githubusercontent.com/eze-is/web-access/main/SKILL.md -o ~/.hermes/skills/web-access/SKILL.md
curl -sLO https://raw.githubusercontent.com/eze-is/web-access/main/scripts/cdp-proxy.mjs -O ~/.hermes/skills/web-access/scripts/
# ... 其他 scripts ...
```
