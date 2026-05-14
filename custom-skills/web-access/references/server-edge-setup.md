# 服务器上通过 Edge 启用 CDP Proxy

当 Hermes Agent 运行在无 GUI 的 Linux 服务器上时，可安装 Microsoft Edge 并开启 headless CDP 模式，替代用户本地 Chrome。

## 适用环境

- Ubuntu 24.04 x86_64（已验证）
- 其他支持 Microsoft Edge .deb 的 Debian/Ubuntu 发行版

## 安装 Edge

```bash
# 添加 Microsoft 仓库
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | \
  gpg --dearmor -o /usr/share/keyrings/microsoft-edge.gpg

echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-edge.gpg] https://packages.microsoft.com/repos/edge stable main' \
  | tee /etc/apt/sources.list.d/microsoft-edge.list

apt-get update && apt-get install -y microsoft-edge-stable
```

## 启动 Edge headless CDP

```bash
microsoft-edge-stable \
  --headless=new \
  --remote-debugging-port=9222 \
  --no-sandbox \
  --disable-gpu \
  --user-data-dir=/tmp/edge-cdp
```

- `--no-sandbox` 在 root/Docker 环境下必需
- `--user-data-dir=/tmp/edge-cdp` 隔离数据目录，避免污染用户配置

## 关键坑：UUID WebSocket 路径

Edge（以及部分新版 Chrome）的 CDP WebSocket URL **必须带 UUID**：

```
ws://127.0.0.1:9222/devtools/browser/<uuid>
```

而 CDP Proxy 默认使用通用路径 `ws://127.0.0.1:9222/devtools/browser`，会导致连接失败，报错：
```
Received network error or non-101 status code.
```

### 解决方案：伪造 DevToolsActivePort 文件

CDP Proxy 在连接前会先查找 `~/.config/google-chrome/DevToolsActivePort`（Linux 路径）。创建一个指向正确 UUID 路径的文件即可：

```bash
UUID=$(curl -s http://127.0.0.1:9222/json/version | \
  python3 -c "import sys,json; u=json.load(sys.stdin)['webSocketDebuggerUrl']; print(u.split('/devtools/browser/')[1])")

mkdir -p ~/.config/google-chrome
printf "9222\n/devtools/browser/${UUID}\n" > ~/.config/google-chrome/DevToolsActivePort
```

**注意**：Edge 每次重启 UUID 都会变化，需要重新生成此文件。见 `scripts/start-edge-cdp.sh` 一键脚本。

## 启动 CDP Proxy

```bash
node ~/.hermes/skills/web-access/scripts/cdp-proxy.mjs
```

## 验证

```bash
# 健康检查
curl -s http://127.0.0.1:3456/health
# 应返回 "connected":true

# 列出 tabs
curl -s http://127.0.0.1:3456/targets

# eval 测试
TAB_ID=$(curl -s http://127.0.0.1:3456/targets | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['targetId'])")
curl -s -X POST "http://127.0.0.1:3456/eval?target=$TAB_ID" -d "'hello'"
# 应返回 {"value":"hello"}
```

## 已知问题

- `/navigate` 的 `waitForLoad` 在 headless Edge 上可能超时（但页面实际已加载），后续 eval 仍可正常读取 DOM
- `/new` 创建 tab 时同样受 `waitForLoad` 超时影响，建议用 `about:blank` 创建后再手动 navigate
