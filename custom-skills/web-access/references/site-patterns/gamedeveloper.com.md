---
domain: gamedeveloper.com
aliases: [Game Developer, Gamasutra]
updated: 2026-05-06
---
## 平台特征
- 游戏开发行业媒体，前身为 Gamasutra，内容涵盖游戏设计、开发、商业
- JS 渲染页面，静态 curl 拿到的是空壳
- **Cloudflare 反爬保护**：CDP 浏览器打开会触发 "Performing security verification" 页面，无法绕过
- 需要真实用户浏览器 + 完整 Cookie/会话态才可正常访问

## 有效模式
- CDP 浏览器直接访问 → **不可行**，会触发 Cloudflare 验证
- 备选：用户在自己 Chrome 中手动打开页面后，通过 CDP 操作已有 tab（携带用户完整会话态）
- 备选：Jina reader (`r.jina.ai/https://www.gamedeveloper.com/...`) 可能绕过，但未经此环境验证

## 已知陷阱
- **2026-05-06**：CDP `new?url=` 直接打开任何 gamedeveloper.com 页面都会触发 Cloudflare 安全验证，无法获取实际内容
- 不要反复重试——Cloudflare 验证不是偶发性的，是结构化拦截
