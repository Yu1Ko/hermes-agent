---
domain: indienova.com
aliases: [Indienova, 独立游戏]
updated: 2026-05-06
---
## 平台特征
- 中文独立游戏社区，内容以游戏设计分析、开发经验、 indie 资讯为主
- 静态 HTML 页面，CDP eval 可直接提取正文（`querySelector("article, .article-content")` → `innerText`）
- 无需登录即可阅读大部分内容
- 无已知反爬机制，CDP 浏览器访问无问题

## 有效模式
- **游戏设计分析专栏**：`https://indienova.com/column/33` —「让人眼前一亮的游戏设计」系列，每篇以一个具体游戏的单个机制为切入点做深度分析，质量极高
- **专栏 URL 模式**：`https://indienova.com/column/{id}` — 直接用 `/new` 打开即可
- **文章内容提取**：用 `/eval` 执行 `document.querySelector("article, .article-content").innerText` 即可拿到全文
- **首页导航提取**：用 `/eval` 遍历 `document.querySelectorAll("a")` 按关键词过滤（设计、机制、系统、玩法等）可快速发现相关文章

## 已知陷阱
- 首页 `/new` 打开后，文章条目可能不在标准 `<article>` 标签中，需要 fallback 用 `a` 标签遍历提取链接。首页提取文章列表时不要只依赖语义标签
- 部分外部链接（微博等）会经过 `indienova.com/link/?target=...` 跳转，提取 `href` 时注意解码
