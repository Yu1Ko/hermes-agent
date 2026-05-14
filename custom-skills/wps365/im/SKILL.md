---
name: wps365-im
description: 聊天消息 - 会话管理、历史消息、发送文本/富文本/云文档/图片/卡片消息，全局消息搜索，撤回消息。
---

# 聊天消息（IM）

WPS 365 即时通讯管理：会话列表、历史消息、发送消息、全局搜索、消息撤回。

## 快速开始

```bash
export WPS_SID="your_sid"
cd ~/.hermes/skills/wps365
```

## Commands

### 会话管理

```bash
# 会话列表
python im/run.py list [--page-size 50]

# 最近会话（带未读数）
python im/run.py recent [--filter-unread] [--filter-mention-me]

# 搜索会话
python im/run.py search "关键字"

# 会话详情
python im/run.py get <chat_id>
```

### 消息管理

```bash
# 历史消息
python im/run.py history <chat_id> [--start-time ISO] [--end-time ISO]

# 全局搜索消息
python im/run.py search-messages --keyword "关键字" \
  [--chat-ids "id1,id2"] [--sender-ids "id1,id2"] \
  [--start-time ISO] [--end-time ISO] \
  [--msg-types "text,file,image"]

# 发送文本消息（默认 Markdown）
python im/run.py send <chat_id> "**你好**，这是消息"
# 纯文本
python im/run.py send <chat_id> "纯文本" --plain

# 发送富文本
python im/run.py send <chat_id> --type rich_text --rich-text '<json>'

# 发送云文档
python im/run.py send <chat_id> --type file \
  --file '{"type":"cloud","cloud":{"id":"<link_id>","link_url":"<url>","link_id":"<link_id>"}}'

# 发送图片
python im/run.py send <chat_id> --type image --image-key '<json>'

# 发送卡片消息
python im/run.py send <chat_id> --type card --card '<json>'

# @某人（正文用闭合标签，--mention 传 user_id）
python im/run.py send <chat_id> "请 <at id=\"1\">张三</at> 查收" --mention <user_id>
# @所有人
python im/run.py send <chat_id> "通知：<at id=\"1\">所有人</at>" --mention all

# 撤回消息
python im/run.py recall <chat_id> <message_id>
```

## 示例

```bash
# 发送 Markdown 会议提醒
python im/run.py send 123456 "## 会议提醒\n\n**时间**：周二 15:00\n\n请准时参加。"

# 发送云文档到群聊
python im/run.py send 123456 --type file \
  --file '{"type":"cloud","cloud":{"id":"xxx","link_url":"https://kdocs.cn/l/xxx","link_id":"xxx"}}'

# 全局搜索关键字
python im/run.py search-messages --keyword "需求" --start-time "2026-01-01T00:00:00Z"
```

## 注意事项

- 发送云文档时 `cloud.id` 必须使用 link_id（非 file_id）
- 消息类型：text（默认 Markdown）、rich_text、file、image、card
- @某人时正文需用闭合标签格式 `<at id="1">展示名</at>`
- 输出格式：Markdown 摘要 + 完整 JSON
