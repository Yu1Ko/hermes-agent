# 低 RAM 服务器上 CDP Proxy 的已知问题

## 症状

- CDP Proxy 进程在运行但 HTTP 请求全部超时
- `curl http://localhost:3456/targets` 卡死
- Edge 的 9222 调试端口无响应
- `start-edge-cdp.sh` 脚本可能也超时挂起

## 根因

Edge headless 在 < 2GB RAM 环境下极易被 OOM killer 杀死或无法正常启动。服务器有 1.6GB RAM 且无 swap，Edge 一启动就会吃光内存然后崩溃。

## 处理方式

1. 先检查内存：`free -h`
2. 清理缓存：`echo 3 > /proc/sys/vm/drop_caches`（root）
3. 杀掉残留进程：`pkill -9 -f microsoft-edge`
4. 重启 CDP Proxy：`node ~/.hermes/skills/web-access/scripts/cdp-proxy.mjs &`
5. 验证：等待 5 秒后 `curl -s --max-time 3 http://localhost:3456/targets`
6. 如果仍然超时 → 内存不够，CDP 不可用，降级回答

## 降级方案

CDP 不可用时，web-access 的搜索备选：
- Jina Reader：`curl "https://r.jina.ai/<url>"` — 轻量，适合已知 URL
- 直接 curl + 解析 — 很多站点会反爬
- 明告诉用户"服务器网络条件有限，搜不了，凭记忆回答"

2026-05-07：在 1.6GB 服务器上，Edge CDP + CDP Proxy 完全不可用。Jina 对 Bing 搜索结果页的解析也不稳定。最可靠的方案是用户自己在本地浏览器搜索，然后把链接或内容贴过来。
