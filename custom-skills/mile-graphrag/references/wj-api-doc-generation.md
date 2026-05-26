# WJ 项目知识图谱构建流程

## 项目概况
剑网3无界自动化测试系统。301M zip → 593M 解压，12216 文件（5713 lua，其余 tab/ini/py）。

## 目录结构
```
Interface/        # 66 个自动化测试模块（Lua）
task_controller/  # Python 调度总控
RunTab/           # 跑图数据表 (.tab)
完整的/Lua/       # 游戏客户端 UI 源码（5700+ 文件，104 子目录）
```

## 两阶段提取流程

### 阶段一：静态扫描（无 LLM）
1. 扫描 Interface/ 下所有子目录，提取：
   - 模块名（从 `LoginMgr.Log("ModuleName", ...)`）
   - API 导出（`XxxApi = {}`）
   - 数据依赖（`LoadRunMapFile(...)` 中的 .tab 文件）
   - 文件大小、行数
2. 按领域分组：登录（5）、跑图（12）、副本（2）、任务（12）、UI遍历（9）、PvP（1）、经济（4）、装备（1）、技能（3）、性能（4）、杂项（13）
3. 输出：JSON modules_scan.json

### 阶段二：LLM 语义提取
1. 将静态扫描结果编成自然语言摘要
2. **分小段**（100-300 字符/段）喂入 `python3 -m graphrag extract --file`
3. 长文本会导致 DeepSeek API 返回 JSON 解析失败（静默丢失实体）
4. 每次提取后 `python3 -m graphrag stats` 验证 num_entities 增加

### 阶段三：索引构建
```bash
python3 -m graphrag index        # 社区检测 + 向量索引
python3 -m graphrag export --output graph.json  # 导出 JSON
```

## FTS5 源码索引
```python
# 对 完整的/Lua/ 建 FTS5
CREATE VIRTUAL TABLE ui_files USING fts5(path, name, content);
# 搜索示例
SELECT path, snippet(ui_files, 1, '>>', '<<', '...', 40) FROM ui_files WHERE ui_files MATCH '背包';
```

## 导出格式
```json
{
  "nodes": [{"id": "模块名", "type": "technology", "description": "..."}],
  "edges": [{"source": "模块名", "target": "依赖", "relation": "depends_on"}],
  "stats": {"num_entities": 218, "num_relations": 201}
}
```

## 领域映射表
| 领域 | 模块数 | 关键模块 |
|------|--------|---------|
| 登录 | 5 | AutoLogin, LoginCreateRole, LoginFace, LoginChangeFace, LoginResizeWindow |
| 跑图 | 12 | BasicRunMap, CustomRunMap系列(3), HotPointRunMap系列(4), RecordPath, WalkExterior(2), BasicRunMapRobot |
| 副本 | 2 | Dungeons(DungeonApi), WorldBoss |
| 任务 | 12 | MainTask, DaoxiangchunTask(2), SectTask系列(3), WuXiangLou系列(2), YiLiChun, Stability(2), TotalTask |
| UI遍历 | 9 | AllUITraversal, UITraversal/UITest/UITrl, ChatTraversal, ShopErgodic系列(3)(ShopCameraApi), StudioTraversal |
| PvP | 1 | ArenaPvP |
| 经济 | 6 | Fabric, Mining, MapFarming, AwardGatherView, BaseTrade, EquipmentEnchant |
| 技能 | 6 | FlySkill, LightSkill, SkillRelease, HangUpFight, PlayerAuto, RobotControl |
| 性能 | 4 | GetPerfData(Perfeye SDK), ManualCollectData, RagDollTest, RecurrentDump |
| 杂项 | 13 | SearchPanel(框架核心), BakingModel, CloakSociety, Displacement, Randomstore, SwitchMap, SwitchRobot, TaskRead, Test |

## 已知坑
- extract 长文本 → JSON 解析失败 → 实体数为 0 → 用 100-300 字小段
- 社区摘要 32 个需要 ~90s，index 命令超时设 180s
- FTS5 db 25MB，打包后 6.7M tar.gz
- 图谱导出 JSON 约 75KB，便携
