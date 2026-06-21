---
name: wps365-dbsheet
description: 多维表 - 获取Schema、增删改查记录、创建数据表与视图，管理多维表数据。需配合 Drive 创建 .dbt 文件使用。
---

# 多维表（DbSheet）

WPS 365 多维表管理：获取表结构、列举/检索/创建/更新/删除记录、创建数据表和视图。

## 快速开始

```bash
export WPS_SID="your_sid"
cd ~/.hermes/skills/wps365
```

## Commands

```bash
# 获取 Schema
python dbsheet/run.py schema <file_id>

# 列举记录
python dbsheet/run.py list-records <file_id> <sheet_id> [--page-size 20] [--filter '<json>']

# 检索记录
python dbsheet/run.py get-record <file_id> <sheet_id> <record_id>
python dbsheet/run.py search-records <file_id> <sheet_id> <record_id1> <record_id2>

# 创建记录
python dbsheet/run.py create-records <file_id> <sheet_id> \
  --json '[{"字段名":"值","字段名2":123}]'

# 更新记录
python dbsheet/run.py update-records <file_id> <sheet_id> \
  --json '[{"id":"recXXX","fields_value":{"字段名":"新值"}}]'

# 删除记录
python dbsheet/run.py delete-records <file_id> <sheet_id> <record_id1> <record_id2>

# 删除空记录（新建多维表建议先执行）
python dbsheet/run.py delete-empty-records <file_id> <sheet_id>

# 创建数据表
python dbsheet/run.py create-sheet <file_id> --json \
  '{"name":"表名","fields":[{"name":"标题","field_type":"MultiLineText"}],"views":[{"name":"表格视图","view_type":"Grid"}]}'

# 创建视图
python dbsheet/run.py create-view <file_id> <sheet_id> --name "视图名" --type Grid
```

## 完整流程示例

```bash
# 1. 在云盘创建 .dbt 文件
python drive/run.py create 反馈管理.dbt
# 记录返回的 file_id

# 2. 查看 Schema
python dbsheet/run.py schema <file_id>

# 3. 清理空记录（重要！新建表后会预留空行）
python dbsheet/run.py delete-empty-records <file_id> 1

# 4. 添加数据
python dbsheet/run.py create-records <file_id> 1 \
  --json '[{"名称":"测试","数量":10,"日期":"2026-03-11"}]'

# 5. 验证
python dbsheet/run.py list-records <file_id> 1
```

## 字段类型

| 创建记录时 | 创建数据表时 (field_type) |
|-----------|-------------------------|
| text | MultiLineText |
| number | Number |
| date | Date |
| singleSelect | SingleSelect |
| multiSelect | MultiSelect |

## 注意事项

- 新建多维表用 Drive 的 `create 文件名.dbt` 获取 file_id
- sheet_id 从 schema 的 `sheets[].id` 获取（通常为 1）
- 新建 .dbt 后建议先执行 `delete-empty-records` 清理空记录
- 字段名必须完全匹配（区分大小写）
- 创建数据表时字段用 `field_type` 属性，非 `type`
- 需要应用开通多维表权限
- 输出格式：Markdown 摘要 + 完整 JSON
