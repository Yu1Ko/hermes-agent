---
name: wps365-contacts
description: 通讯录搜索 - 按姓名搜索企业通讯录，获取用户ID。用于查找企业内部用户信息。
---

# 通讯录搜索

在 WPS 365 企业通讯录中按姓名搜索用户，支持模糊匹配，同名用户会全部返回。

## 快速开始

```bash
export WPS_SID="your_sid"
cd ~/.hermes/skills/wps365
```

## Commands

```bash
# 搜索用户（同名返回多条）
python contacts/run.py search "姓名"
# 或
python contacts/run.py search --keyword "姓名"
```

## 返回字段

| 字段 | 说明 |
|------|------|
| user_id | 用户唯一标识，可用于日程参与者、会议邀请 |
| name | 用户姓名 |
| department | 所属部门 |
| email | 邮箱地址 |
| phone | 手机号 |
| position | 职位 |
| avatar_url | 头像URL |
| status | 用户状态 |

## 示例

```bash
python contacts/run.py search "张三"

# 输出 Markdown 摘要 + 完整 JSON
# 找到 N 个用户，列出姓名、用户ID、部门、邮箱
```

## 注意事项

- 需要先设置环境变量 WPS_SID
- 搜索支持模糊匹配
- 获取的 user_id 可用于日历日程和会议等场景
- 输出格式：Markdown 摘要 + 完整 JSON
