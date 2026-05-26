---
name: wps365
description: WPS 365 V7 API 工具集，集成通讯录、日历、会议、云文档、多维表、IM 等能力。包含 contacts、user-current、calendar、meeting、drive、dbsheet、im 七个子技能。
---

# WPS 365 工具集

基于 WPS 365 V7 API 封装的命令行工具集，帮助你快速完成企业协作任务。

## 快速开始

```bash
# 设置认证
export WPS_SID="你的WPS_SID值"

# 进入技能目录
cd ~/.hermes/skills/wps365
```

## 子技能概览

| 子技能 | 目录 | 功能 |
|--------|------|------|
| contacts | contacts/ | 通讯录搜索 - 按姓名查找用户 |
| user-current | user-current/ | 当前用户 - 查询登录身份 |
| calendar | calendar/ | 日历与日程 - 增删改查、忙闲查询 |
| meeting | meeting/ | 会议管理 - 创建/查询/管理参会人 |
| drive | drive/ | 云文档 - 上传/读写/搜索/管理 (⚠️ .otl/.ksheet 不可回读，只能写入；.otl write --overwrite 不会真正覆盖，用 update 替换) |
| dbsheet | dbsheet/ | 多维表 - Schema/记录增删改查 |
| im | im/ | 聊天消息 - 会话/消息/搜索 |

## 常见场景

### 创建会议并邀请参会人

```bash
# 1. 查找参会人
python contacts/run.py search "张三"

# 2. 查询忙闲
python calendar/run.py free-busy --user-ids "user_id" \
  --start "2026-03-04T00:00:00+08:00" --end "2026-03-04T23:59:59+08:00"

# 3. 创建会议
python meeting/run.py create --subject "项目评审" \
  --start "2026-03-04T14:00:00+08:00" \
  --end "2026-03-04T15:00:00+08:00" \
  --participants "user_id1,user_id2"
```

### 新建多维表并写入数据

```bash
# 1. 创建 .dbt 文件
python drive/run.py create 反馈管理.dbt

# 2. 创建数据表
python dbsheet/run.py create-sheet <file_id> --json \
  '{"name":"反馈","fields":[{"name":"问题","field_type":"MultiLineText"}],"views":[{"name":"表格视图","view_type":"Grid"}]}'

# 3. 写入数据
python dbsheet/run.py create-records <file_id> <sheet_id> \
  --json '[{"问题":"示例反馈"}]'
```

### 发送云文档到群聊

```bash
# 1. 上传文档（记录返回的 link_id）
python drive/run.py upload /path/to/doc.docx

# 2. 发送到群聊
python im/run.py send <chat_id> --type file \
  --file '{"type":"cloud","cloud":{"id":"<link_id>","link_url":"<link_url>","link_id":"<link_id>"}}'
```

## 时间格式与时区

所有涉及时间的参数必须使用带时区的 ISO 8601 格式，禁止无后缀写法。

- 推荐：`2026-03-04T14:00:00+08:00`（东8区）或 `2026-03-04T06:00:00Z`（UTC）
- 禁止：`2026-03-04T14:00:00`（无时区后缀，会被当作 UTC，东8区偏差约8小时）

## KSheet 处理

**ksheet 不是多维表，dbsheet API 无法读取。** 需要通过 drive API 下载为 xlsx、本地操作、再上传。详见 `references/ksheet-handling.md`——包含下载认证、openpyxl 兼容性修复、合并单元格处理等关键步骤。

## 错误处理

| 错误 | 原因 | 解决方案 |
|------|------|----------|
| 缺少 wps_sid | 未设置环境变量 | `export WPS_SID=xxx` |
| 401/403 | 凭证无效/过期 | 重新获取 wps_sid |
| 时间区间超限 | 超出接口限制 | 缩小查询范围 |
| .otl/.ksheet 读取出错 | API 不支持回读这两种格式 | **无 API 通路**，请用户手动复制内容到对话。详见 references/wps-otl-pitfalls.md |

## 获取帮助

```bash
# 查看具体子命令帮助
python <skill>/run.py --help
python <skill>/run.py <子命令> --help

# 查看子技能文档
cat <skill>/SKILL.md
```
