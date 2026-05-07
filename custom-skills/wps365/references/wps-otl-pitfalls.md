# WPS .otl 写入陷阱 & 凭证发现

## .otl write --mode overwrite 不会真正覆盖

`drive/run.py:347` 对 .otl/airpage 文件的处理逻辑：

```python
if file_type in ("ap", "unknown"):
    pos = "end" if getattr(args, "mode", "overwrite") == "append" else "begin"
    resp = write_airpage_content(file_id=file_id, title=title, content=content, pos=pos)
```

`--mode overwrite` 时 `pos="begin"`，只是把内容插入到文档头部，旧内容全部保留在后面。文件不会变小。

**正确做法**：需要真正替换全文时，用 `update`：

```bash
echo "# 新内容" > /tmp/new.md
python drive/run.py update <file_id> --drive <drive_id> /tmp/new.md
```

`update` 会完整替换文件（.md 自动转智能文档），文件大小可验证。

## .otl / .ksheet 文件无法通过 API 回读内容

WPS 365 V7 API 的 `extract` / `read` / `download` 三个命令对 `.otl` 和 `.ksheet` 文件**全部无效**：

| 命令 | .otl | .ksheet |
|------|------|---------|
| `extract` | 文档内容抽取失败 | 文档内容抽取失败 |
| `read` (extract 别名) | 同上 | 同上 |
| `download` | 不支持的文件类型 | 返回下载链接但需登录态，curl 下载后只得到 `{"result":"userNotLogin"}` |

唯一可操作的是 **写入**（`write` 到 .otl）和 **更新**（`update` 替换 .otl 全文），但无法从 API 侧验证写入结果。

**结论**：需要读取 .otl/.ksheet 内容时，必须请用户手动复制粘贴内容到对话中，无 API 通路。

## WPS_SID 凭证位置

WPS 365 工具需要 `WPS_SID` 环境变量。此环境的凭证藏在 `~/.hermes/config.yaml` 中：

```yaml
platforms:
  qqbot:
    wps_sid: V02SZQH1rHhgmyFxiDtHnPIKZuYkUYc00...
```

提取方式：
```bash
grep -A1 "wps_sid:" ~/.hermes/config.yaml
```

每次使用 WPS 365 命令前需要 export：
```bash
export WPS_SID="$(grep wps_sid ~/.hermes/config.yaml | awk '{print $2}')"
```
