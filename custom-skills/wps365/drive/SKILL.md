---
name: wps365-drive
description: 云文档 - 文件创建/上传/更新/列表/详情/下载，文档内容读取与写入，搜索、标签、收藏、回收站、分享管理。
---

# 云文档管理

WPS 365 云文档 Drive：文件流转、内容处理、检索发现、组织管理、分享与回收站。

## 快速开始

```bash
export WPS_SID="your_sid"
cd ~/.hermes/skills/wps365
```

## Commands

### 文件流转

```bash
# 创建云文档（支持 .otl、.dbt 等）
python drive/run.py create 文件名.dbt [--path "目录"] [--drive private] [--on-conflict rename]

# 上传文件（.md 自动上传为智能文档）
python drive/run.py upload /path/to/file.md [--drive private] [--path "目录"]

# 更新已有文件
python drive/run.py update <file_id|link_id> /path/to/file.docx [--drive private]

# 文件列表
python drive/run.py list [--drive private] [--parent root] [--page-size 20] [--all]

# 文件详情
python drive/run.py get <file_id|link_id> [--drive private]

# 下载文件
python drive/run.py download <file_id|link_id>
```

### 文档内容处理

```bash
# 读取文档为 Markdown（支持 .otl、.docx、.pdf）
python drive/run.py read <file_id|link_id> [--format markdown] [--raw]

# 将 Markdown 写入文档
python drive/run.py write <file_id|link_id> \
  --content "# 标题\n内容" | --file /path/to/content.md \
  [--mode overwrite|append] [--template template.docx]
```

### 搜索与发现

```bash
# 搜索文档
python drive/run.py search "关键词" [--type all] [--scope all] [--page-size 20]

# 最近文档
python drive/run.py latest [--page-size 20] [--with-link]

# 链接解析（link_id → file_id/drive_id）
python drive/run.py link-meta <link_id>
```

### 文件管理操作

```bash
# 新建文件夹
python drive/run.py create "文件夹名" --drive <drive_id> --parent-id <parent_id> --file-type folder

# 复制/移动/重命名/另存为
python drive/run.py file-copy <src_drive_id> <file_id> --dst-drive-id <dst> --dst-parent-id <dst_parent>
python drive/run.py file-move <src_drive_id> <file_id> --dst-drive-id <dst> --dst-parent-id <dst_parent>
python drive/run.py file-rename <drive_id> <file_id> --dst-name "新名称.docx"
python drive/run.py file-save-as <drive_id> <file_id> --dst-drive-id <dst> --dst-parent-id <dst_parent> --name "副本.docx"

# 重名检查
python drive/run.py file-check-name <drive_id> <parent_id> --name "文件名.docx"
```

### 收藏与标签

```bash
# 收藏
python drive/run.py star [--page-size 20]
python drive/run.py star-add-items --objects "file_id1,file_id2"
python drive/run.py star-remove-items --objects "file_id1"

# 标签
python drive/run.py tags --label-type custom [--page-size 20]
python drive/run.py tag-create --name "标签名"
python drive/run.py tag-add-objects <label_id> --objects "file_id1,file_id2"
python drive/run.py tag-remove-objects <label_id> --objects "file_id2"
```

### 回收站与分享

```bash
# 回收站
python drive/run.py deleted-list [--page-size 20]
python drive/run.py deleted-restore <file_id>

# 分享
python drive/run.py file-open-link <drive_id> <file_id> --scope anyone
python drive/run.py file-close-link <drive_id> <file_id> --mode pause
```

## 示例

```bash
# 上传 .md 文件为智能文档
python drive/run.py upload /path/to/report.md

# 读取文档内容
python drive/run.py read <file_id>

# 将内容写入智能文档
python drive/run.py write <file_id> --content "# 新内容\n\n正文..."

# 上传 .docx 并发送到 IM
# 1. 上传获取 link_id
python drive/run.py upload /path/to/doc.docx
# 2. 使用 link_id 发送云文档消息
```

## 注意事项

- **云盘 ID**：`private`（我的云文档）、`roaming`（漫游箱）、`special`（团队云文档）
- 读取（read/extract）：支持 .otl、.docx、.pdf；不支持 .pptx
- 写入（write）：支持 .otl（插入）、.docx（转换+覆盖）、.pdf（转换+覆盖）
- .md 文件上传时自动转为智能文档（.otl）
- link_id 可用于 IM 发送云文档消息
- 输出格式：Markdown 摘要 + 完整 JSON；read/extract 默认仅输出正文
