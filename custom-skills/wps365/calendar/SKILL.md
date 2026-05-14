---
name: wps365-calendar
description: 日历与日程 - 创建/查询/修改/删除日历和日程，忙闲查询，参与者管理，会议室管理。
---

# 日历与日程

WPS 365 日历管理：日历增删改查、日程增删改查、忙闲查询、参与者和会议室管理。

## 快速开始

```bash
export WPS_SID="your_sid"
cd ~/.hermes/skills/wps365
```

## Commands

### 日历管理

```bash
# 列出日历
python calendar/run.py list-calendars

# 查看日历详情
python calendar/run.py get-calendar <calendar_id>

# 创建日历
python calendar/run.py create-calendar --title "标题" --color "#FF0000FF" [--desc "描述"]

# 修改日历
python calendar/run.py update-calendar <calendar_id> [--title 标题] [--color 颜色] [--desc 描述]

# 删除日历
python calendar/run.py delete-calendar <calendar_id>
```

### 日程管理

```bash
# 列出日程（时间区间不超过31天）
python calendar/run.py list-events <calendar_id> --start "开始ISO" --end "结束ISO"

# 查看日程详情
python calendar/run.py get-event <calendar_id> <event_id>

# 创建日程
python calendar/run.py create-event <calendar_id> \
  --start "开始ISO" --end "结束ISO" \
  [--title "标题"] [--desc "描述"] [--location "地点"] \
  [--attach file_id ...] [--attendees "user_id1,user_id2"]

# 修改日程
python calendar/run.py update-event <calendar_id> <event_id> \
  [--title 标题] [--desc 描述] [--start ISO] [--end ISO] \
  [--location "地点"] [--attach file_id ...] \
  [--attendees "user_id1,user_id2"] [--remove-attendees "user_id1"]

# 删除日程
python calendar/run.py delete-event <calendar_id> <event_id>
```

### 忙闲查询

```bash
python calendar/run.py free-busy --user-ids "user_id1,user_id2" \
  --start "开始ISO" --end "结束ISO" [--room-ids "room_id1"]
```

## 示例

```bash
# 创建日程并邀请参与者
python calendar/run.py create-event primary \
  --start "2026-03-04T14:00:00+08:00" \
  --end "2026-03-04T15:00:00+08:00" \
  --title "项目评审" --attendees "user_id1,user_id2"

# 查询未来7天忙闲
python calendar/run.py free-busy --user-ids "user_id1" \
  --start "2026-03-04T00:00:00+08:00" \
  --end "2026-03-11T00:00:00+08:00"
```

## 注意事项

- **时间格式重要**：必须带时区后缀（`Z` 或 `+08:00`），禁止无后缀写法，否则东8区会偏差约8小时
- 主日历 calendar_id 可使用 `primary`
- 忙闲查询区间不超过 7 天
- 日程列表区间不超过 31 天
- 创建日程时参与者为可选，创建后可通过 update-event 管理
- 输出格式：Markdown 摘要 + 完整 JSON
