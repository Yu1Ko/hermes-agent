# KSheet 文件处理

WPS ksheet（.ksheet）本质是 xlsx 格式（OOXML），可以通过 drive API 下载后本地操作再上传。

## 读取流程

```bash
# 1. 下载文件（需要 WPS_SID cookie 认证下载 URL）
cd ~/.hermes/skills/wps365
python3 drive/run.py download <file_id>
# 返回下载链接 → curl -H "Cookie: wps_sid=$WPS_SID" -o /tmp/file.xlsx <url>

# 2. 修复 openpyxl 兼容性（DataValidation id 属性不支持）
python3 -c "
import zipfile, os, xml.etree.ElementTree as ET
tmpdir = '/tmp/ksheet_extract'
with zipfile.ZipFile('/tmp/file.xlsx') as zf: zf.extractall(tmpdir)
ns = {'s': 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}
for f in os.listdir(os.path.join(tmpdir, 'xl', 'worksheets')):
    if f.endswith('.xml'):
        tree = ET.parse(os.path.join(tmpdir, 'xl', 'worksheets', f))
        for dv in tree.getroot().findall('.//s:dataValidations', ns):
            tree.getroot().remove(dv)
        tree.write(os.path.join(tmpdir, 'xl', 'worksheets', f), xml_declaration=True, encoding='UTF-8')
with zipfile.ZipFile('/tmp/file_fixed.xlsx', 'w', zipfile.ZIP_DEFLATED) as zf:
    for root, dirs, files in os.walk(tmpdir):
        for fn in files:
            zf.write(os.path.join(root, fn), os.path.relpath(os.path.join(root, fn), tmpdir))
"

# 3. 加载并操作
python3 -c "import openpyxl; wb = openpyxl.load_workbook('/tmp/file_fixed.xlsx'); ..."
```

## 关键陷阱

1. **dbsheet API 不管 ksheet**：ksheet 是普通表格不是多维表，`dbsheet/run.py schema` 返回 `"sheets": []`。必须用 `drive/run.py download` 下载。

2. **下载链接需要认证**：`drive/run.py download` 返回的 URL 直接 curl 会返回 `{"result":"userNotLogin"}`，必须带 `Cookie: wps_sid=$WPS_SID`。

3. **openpyxl DataValidation 兼容性**：较新 xlsx 格式的 DataValidation 元素带 `id` 属性，openpyxl 3.1.5 不支持。需要先通过 zipfile+XML 剥离 DataValidation 元素。

4. **合并单元格**：ksheet 有大量合并单元格（如 571 个），用 `ws.insert_rows()` 插入行时会自动移位合并区域，比手动逐格移位安全。

5. **多步终端操作必须一次 save**：跨多个 terminal 调用修改 xlsx 时，如果在最后一个脚本才 save，之前脚本的修改会丢失。所有修改放在一个 Python 脚本里，末尾一次 `wb.save()`。
