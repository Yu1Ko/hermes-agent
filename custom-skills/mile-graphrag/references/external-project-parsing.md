# 外部项目解析为知识图谱工作流

## 适用场景
用户提供一个大型项目（代码库、文档集、聊天记录），要求解析为可导出的知识图谱。

## 完整三板斧

三个互补系统覆盖不同检索需求：

```
项目文件
  ├─→ SQLite FTS5 全文索引 → 关键词搜代码（秒级，不需 LLM）
  ├─→ 静态结构分析 → 模块/依赖/API 清单（正则提取，不需 LLM）
  └─→ GraphRAG 知识图谱 → 语义搜索 + 关系网络（LLM 提取）
```

## FTS5 全文索引（Layer 0：代码搜索）

对于 Lua/Python/JS 等源码项目，先建 FTS5 索引，让用户能按关键词直接搜到目标代码：

```python
import sqlite3, os, re

conn = sqlite3.connect("code_fts.db")
conn.execute("CREATE VIRTUAL TABLE IF NOT EXISTS files USING fts5(path, name, content)")
conn.execute("CREATE TABLE IF NOT EXISTS meta (path TEXT PRIMARY KEY, name TEXT, apis_used TEXT, line_count INTEGER)")

for root, dirs, files in os.walk(source_dir):
    for f in files:
        if f.endswith('.lua'):  # or .py, .js, etc.
            fpath = os.path.join(root, f)
            with open(fpath, 'r', errors='ignore') as fh:
                content = fh.read()
            conn.execute("INSERT INTO files VALUES (?, ?, ?)", (relpath, f.replace('.lua',''), content))
            # 提取 API 调用（大写开头.方法名 模式）
            apis = set(re.findall(r'(\w+\.\w+)', content))
            game_apis = [a for a in apis if a[0].isupper() and not a.startswith('self.')]
            conn.execute("INSERT INTO meta VALUES (?, ?, ?, ?)", 
                        (relpath, f.replace('.lua',''), ','.join(list(game_apis)[:50]), content.count('\n')))
conn.commit()
```

搜索示例：
```python
rows = conn.execute(
    "SELECT path, snippet(files, 2, '**', '**', '...', 20) FROM files WHERE files MATCH ? LIMIT 5",
    ('背包',)
).fetchall()
```

## 分层策略

### Layer 1: 静态分析（不用 LLM）
用 Python/正则提取项目结构信息，包括：
- 文件/目录结构 → 模块列表
- 导入/注册语句 → 模块间依赖（如 Lua 的 `LoginMgr.Log("ModuleName", "ModuleName imported")`）
- API 导出声明（如 `XxxApi = {}`）→ 对外接口
- 数据文件引用（如 `LoadRunMapFile("xxx.tab")`）→ 数据依赖
- 配置文件 → 配置依赖

目标：拿到"不需要语义理解"的结构信息，同时识别领域分组。

### Layer 2: LLM 语义提取（仅喂结构化摘要）

**关键坑：单次文本超过 ~200 字就可能触发 JSON 解析失败。**
extractor 的 warning `Failed to parse JSON from response` 表示 DeepSeek API 返回的 JSON 被截断，fallback 到空结果 `{"entities": [], "relations": []}`。

**正确的分段策略**：每段 130-200 字符，用自然段落描述，不用列表/表格式。分 5-7 段独立调用 extract：

```bash
cd /root/.hermes/mile-knowledge
python3 -m graphrag extract --file /tmp/chunk_0.txt
python3 -m graphrag extract --file /tmp/chunk_1.txt
# ...依次执行
python3 -m graphrag stats  # 验证实体数是否增长
```

如果某段 stats 没变化（实体数未增加），说明该段文本格式有问题或与已有实体重复，调整重试。

### Layer 3: 索引 + 导出

```bash
python3 -m graphrag index       # 社区检测+向量索引，timeout≥180s
python3 -m graphrag export --output project_graph.json
```

输出格式：
```json
{
  "nodes": [{"id": "...", "type": "technology", "description": "...", "confidence": 0.95}],
  "edges": [{"source": "A", "target": "B", "relation": "depends_on", "description": "..."}],
  "stats": {"num_entities": 218, "num_relations": 201, "density": 0.91}
}
```

## 用户实体桥接

如果项目实体和系统已有实体（如 MiLe）完全隔离（零交叉边），可以在 profile 摘要中加入创建者信息，让提取器生成 `created_by` 关系来桥接两个域：

```
Yu1ko 是 MiLe 的创建者和最高权限用户。Yu1ko 也是 WJ 自动化测试系统的核心开发者。
```

提取后图谱会自动生成 MiLe→Yu1ko 和 WJ→Yu1ko 两条边，Yu1ko 成为跨域桥接点。

## 实战案例：剑网3自动化测试插件（WJ）

> **补充工作流**：从图谱生成 fumadocs MDX 文档（带真实 API 签名）→ `references/wj-api-doc-generation.md`

- 原始：301MB zip → 593MB 解压，12216 文件，5713 个 lua 文件
- FTS5 索引：2114 个 UI 文件入 SQLite，搜"背包""SkillPanel"秒出代码
- 静态分析：66 个测试模块，分 10 个领域（跑图/副本/任务/UI遍历/PvP/经济/技能/性能/登录/杂项）
- **API 提取**：506 个 Lua 函数签名（纯正则，不需 LLM）→ 按领域生成 11 个 MDX 文档
- LLM 提取：7 段 UI 摘要（每段 97-161 字符）+ 5 段系统摘要（每段 260-350 字符），首次 5 段成功、然后 UI 7 段成功
- 结果：218 实体，201 关系，32+ 语义社区
- 用户桥接：Yu1ko 实体连接了 MiLe 和 WJ 两个域
- 导出：`python3 -m graphrag export --output wj_knowledge_graph.json`

- 原始：301MB zip → 593MB 解压，12216 文件，5713 个 lua 文件
- FTS5 索引：2114 个 UI 文件入 SQLite，搜"背包""SkillPanel"秒出代码
- 静态分析：66 个测试模块，分 10 个领域（跑图/副本/任务/UI遍历/PvP/经济/技能/性能/登录/杂项）
- LLM 提取：7 段 UI 摘要（每段 97-161 字符）+ 5 段系统摘要（每段 260-350 字符），首次 5 段成功、然后 UI 7 段成功
- 结果：218 实体，201 关系，32+ 语义社区
- 用户桥接：Yu1ko 实体连接了 MiLe 和 WJ 两个域
- 导出：`python3 -m graphrag export --output wj_knowledge_graph.json`

## Pitfalls

1. **单段文本 >200 字 → JSON 解析失败**：`Failed to parse JSON from response` → 拆成更小段重试
2. **Edge 属性名是 `relation_type`**：导出时用 `attrs.get("relation_type")`，不是 `attrs.get("type")`
3. **不要一次全量 LLM 提取**：5000+ 文件时先跑 FTS5 + 静态分析，LLM 只做语义理解补位
4. **index 命令 timeout 要设 180s+**：32 个社区各调一次 API 摘要，总耗时 2-3 分钟
5. **提取文本要用自然段落**：列表/表格式文本更容易触发 JSON 截断，改成叙述性短句
6. **stats 不变 = 该段未生效**：每段 extract 后立即 `python3 -m graphrag stats` 确认实体数增长
7. **background_process_notifications=all 可能生成旁路消息**：未确认但高度可疑——tar/打包等后台进程完成通知可能被平台转成模板式消息，绕过 agent 管道和 critic 拦截器。症状：用户看到\"文件已打包，路径为：xxx\"类结构化通知，但 gateway.log 和会话记录中无痕迹。临时对策：`hermes config set background_process_notifications errors` 或设为 `none`
