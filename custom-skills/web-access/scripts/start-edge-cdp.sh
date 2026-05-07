#!/bin/bash
# Edge + CDP Proxy 一键启动脚本
# 适用场景：无桌面的服务器环境，用 headless Edge 替代本地 Chrome

set -e

EDGE_BIN="/usr/bin/microsoft-edge-stable"
CDP_PORT="${CDP_PORT:-9222}"
PROXY_SCRIPT="$HOME/.hermes/skills/web-access/scripts/cdp-proxy.mjs"
PORT_FILE="$HOME/.config/google-chrome/DevToolsActivePort"
EDGE_DATA="/tmp/edge-cdp"

echo "=== MiLe Web-Access 启动 ==="

# 1. 杀掉旧 Edge CDP 进程
OLD_PID=$(pgrep -f "microsoft-edge.*remote-debugging-port=${CDP_PORT}" 2>/dev/null || true)
if [ -n "$OLD_PID" ]; then
    echo "[1/5] 关闭旧 Edge 进程 (PID: $OLD_PID)..."
    kill -9 $OLD_PID 2>/dev/null || true
    sleep 1
else
    echo "[1/5] 没有旧 Edge 进程"
fi

# 2. 杀掉旧 CDP Proxy
OLD_PROXY=$(pgrep -f "cdp-proxy.mjs" 2>/dev/null || true)
if [ -n "$OLD_PROXY" ]; then
    echo "      关闭旧 CDP Proxy (PID: $OLD_PROXY)..."
    kill -9 $OLD_PROXY 2>/dev/null || true
    sleep 1
fi

# 3. 启动 headless Edge
echo "[2/5] 启动 Edge headless..."
nohup "$EDGE_BIN" \
    --headless=new \
    --remote-debugging-port="${CDP_PORT}" \
    --no-sandbox \
    --disable-gpu \
    --disable-dev-shm-usage \
    --user-data-dir="$EDGE_DATA" \
    > /tmp/edge-cdp.log 2>&1 &

# 4. 等待 Edge 就绪
echo "[3/5] 等待 Edge CDP 就绪..."
for i in $(seq 1 20); do
    if curl -s "http://127.0.0.1:${CDP_PORT}/json/version" > /tmp/edge-version.json 2>/dev/null; then
        echo "      Edge 已就绪"
        break
    fi
    sleep 1
done

if [ $i -eq 20 ]; then
    echo "❌ Edge 启动超时，请检查 /tmp/edge-cdp.log"
    exit 1
fi

# 5. 提取 WebSocket UUID 并写入 DevToolsActivePort
echo "[4/5] 配置 DevToolsActivePort..."
UUID=$(python3 -c "
import json
with open('/tmp/edge-version.json') as f:
    d = json.load(f)
u = d['webSocketDebuggerUrl']
print(u.split('/devtools/browser/')[1])
")
mkdir -p "$(dirname "$PORT_FILE")"
printf "%s\n/devtools/browser/%s\n" "${CDP_PORT}" "${UUID}" > "$PORT_FILE"
echo "      端口: ${CDP_PORT}, UUID: ${UUID}"

# 6. 启动 CDP Proxy
echo "[5/5] 启动 CDP Proxy..."
nohup node "$PROXY_SCRIPT" > /tmp/cdp-proxy.log 2>&1 &

sleep 2
# 验证
if curl -s http://127.0.0.1:3456/health | python3 -c "import sys,json; d=json.load(sys.stdin); sys.exit(0 if d.get('connected') else 1)" 2>/dev/null; then
    echo ""
    echo "✅ Web-Access 就绪！"
    echo "   Edge:    http://127.0.0.1:${CDP_PORT}"
    echo "   Proxy:   http://127.0.0.1:3456"
else
    echo "⚠️  Proxy 启动但未连接，检查 /tmp/cdp-proxy.log"
fi
