---
name: wps365-meeting
description: 会议管理 - 创建/查询/修改/取消在线会议，管理参会人，查询会议室层级与日程会议室。
---

# 会议管理

WPS 365 在线会议管理：创建预约会议、查询详情、参会人管理、会议室资源查询。

## 快速开始

```bash
export WPS_SID="your_sid"
cd ~/.hermes/skills/wps365
```

## Commands

### 会议管理

```bash
# 创建会议
python meeting/run.py create --subject "主题" \
  --start "开始ISO" --end "结束ISO" \
  [--participants "user_id1,user_id2"] \
  [--join-permission anyone|company_users|only_invitee]

# 查询会议详情
python meeting/run.py get <meeting_id>

# 按时间范围列出会议
python meeting/run.py list --start "开始ISO" --end "结束ISO"

# 修改会议
python meeting/run.py update <meeting_id> \
  [--subject "新主题"] [--start "新开始ISO" --end "新结束ISO"]

# 取消会议
python meeting/run.py cancel <meeting_id>
```

### 参会人管理

```bash
# 参会人列表
python meeting/run.py list-participants <meeting_id>

# 邀请参会人
python meeting/run.py add-participants <meeting_id> --ids "user_id1,user_id2"

# 移除参会人
python meeting/run.py remove-participants <meeting_id> --ids "user_id1"
```

### 会议室管理

```bash
# 会议室层级列表
python meeting/run.py list-room-levels [--room-level-id ID] [--page-size N]

# 某日程的会议室列表
python meeting/run.py list-event-rooms <calendar_id> <event_id>
```

## 示例

```bash
# 创建会议并邀请参会人
python meeting/run.py create --subject "项目评审" \
  --start "2026-03-04T14:00:00+08:00" \
  --end "2026-03-04T15:00:00+08:00" \
  --participants "user_id1,user_id2"

# 查看未来一周会议
python meeting/run.py list \
  --start "2026-03-01T00:00:00+08:00" \
  --end "2026-03-07T00:00:00+08:00"
```

## 注意事项

- **时间格式重要**：必须带时区后缀（`Z` 或 `+08:00`），禁止无后缀写法，否则东8区会偏差约8小时
- 返回信息包含：meeting_id、join_url（入会链接）、meeting_code（入会码）、meeting_number（会议号）
- 创建会议后可获取入会链接和入会码
- 输出格式：Markdown 摘要 + 完整 JSON
