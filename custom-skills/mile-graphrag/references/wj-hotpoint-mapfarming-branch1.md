# WJ 热力图分支1去重（MapFarming）

## 背景

WJ 热力图有两套采集方案：
- **HotPointRunMapOneDepth**：网格遍历，每格固定 4 方向各 1 条数据
- **MapFarming / MapFarming2**：自定义路径边走边采，每格可能踩到十几次

分支 1（每格只留性能最差）对 MapFarming 才是真正有意义的地方。

## 四大版本概览

MapFarming 在 WJ 项目中有四个版本，按复杂度递增：

| # | 版本 | 行数 | 数据源 | Process 策略 | Key | 追踪结构 |
|---|------|------|--------|-------------|-----|---------|
| 1 | **分支2（全量保留）** | 215 | GetHotPointReader | `table.insert` 全部追加 | `(centerX,1000000,centerY)` | GridPointData |
| 2 | **分支1（FPS去重）** | 227 | GetHotPointReader | FPS 更低替换，每格1条 | `(centerX,1000000,centerY)` | GridPointData |
| 3 | **模板版（CompareConfig）** | 349 | GetHotPointReader | IsBetterRecord 通用比较 | nIndex（数字） | 内联（Data[nIndex]） |
| 4 | **最终版（Perfeye）** | 554 | GetPerfData | FPS更低替换+GridTracker | `(nX,1000000,nY)` 实际坐标 | GridTracker |

版本1→2→3→4 功能递增：全留→单字段去重→可配置去重→完整工程化。

---

## 各版本数据结构

⚠️ **最核心的坑：不同版本的相机格式不同，导致 StringSplit(",") 后数据列偏移量完全不同。**

### 模板版 & 分支2（GetHotPointReader，结构化）

```lua
-- RecordData() 返回 table（模板版）/ 字符串（分支2）
-- 相机串: "(0.00, 0.00, 0.00),"  -- 有尾逗号！Split 多一个空元素
-- 数据列:  setpass, drawcall, drawbatch, 0(vertices), triangles, memory, fps, ms, cmd
```

**所有 GetHotPointReader 版本（分支1/2、模板版）的 CSV 列偏移完全一致：**

StringSplit(",") 结果 (1-indexed):
| parts[1-3] | parts[4] | parts[5] | parts[6] | parts[7] | parts[8] | parts[9] | parts[10] | parts[11] |
|------------|----------|----------|----------|----------|----------|----------|-----------|-----------|
| 相机 | (空) | setpass | drawcall | drawbatch | 0 | triangles | memory | **fps** | ms |

- **FPS = parts[10]**，**Ms = parts[11]**
- 模板版的 RecordData 返回 table 直接 `.fps`，不需要解析字符串

### 最终版（GetPerfData，554行）

```lua
-- RecordData() 返回 table，FormatRecordString() 序列化
-- 相机串: "(0.00, 90.00, 0.00)"  -- 无尾逗号！
-- 数据列:  Drawcall, DrawTriangles, Memory, FPS, LogicFps, Ms, cmd
```

StringSplit(",") 结果 (1-indexed):
| parts[1-3] | parts[4] | parts[5] | parts[6] | parts[7] | parts[8] | parts[9] | parts[10] |
|------------|----------|----------|----------|----------|----------|----------|-----------|
| 相机 | Drawcall | DrawTriangles | Memory | **FPS** | LogicFps | Ms | cmd |

**最终版 Process() 直接用 `tbRecord.FPS`（从 table 读，不解析字符串）。**

### HotPointRunMapOneDepth（参照）

```lua
-- 相机串有尾逗号（与 GetHotPointReader 版本相同）
-- 数据列: setpass, drawcall, drawbatch, 0, triangles, memory, fps, ms, cmd
-- StringSplit 后: parts[9]=memory, parts[10]=fps, parts[11]=ms
```
原版去重用 `parts[9]`（Memory），变量名误写为 `nMs` 但实际比的是显存。

---

## 各版本去重逻辑详解

### 版本1：分支2（全量保留）

```lua
-- Process(): 只做 table.insert，不做任何比对
if not MapFarming.Data.performanceData[szKey] then
    MapFarming.Data.performanceData[szKey] = {}
end
table.insert(MapFarming.Data.performanceData[szKey], strData)
MapFarming.GridPointData[szIndex] = szKey
```

### 版本2：分支1（FPS去重，最小实现）

```lua
-- Process(): 复用 GridPointData 做格子层去重
if MapFarming.GridPointData[szIndex] then
    local szPrevKey = MapFarming.GridPointData[szIndex]
    local prevParts = SearchPanel.StringSplit(
        MapFarming.Data.performanceData[szPrevKey][1], ",")
    local curParts = SearchPanel.StringSplit(strData, ",")
    local nPrevFps = tonumber(prevParts[10]) or 0
    local nCurFps = tonumber(curParts[10]) or 0
    if nCurFps >= nPrevFps then
        return  -- FPS 没更低，跳过
    end
    MapFarming.Data.performanceData[szPrevKey] = nil
end
MapFarming.Data.performanceData[szKey] = {strData}
MapFarming.GridPointData[szIndex] = szKey
```

**性能判定**：FPS 越低 = 越卡 = 性能越差。用 `<` 比较，每格只保留 FPS 最低的那条。

### 版本3：模板版（CompareConfig 可配置）

```lua
-- CompareConfig 默认 fps/min（分支1策略），可随时切换
MapFarming.CompareConfig = {
    compareField = "fps",  -- 或 "ms", "triangles", "drawCall" 等 8 个字段
    compareMode = "min"     -- "max" 或 "min"
}

-- Process(): 用 nIndex 做 key，IsBetterRecord 做通用比较
local oldData = MapFarming.Data.performanceData[nIndex]
if not oldData or MapFarming.IsBetterRecord(tbRecord, oldData.record) then
    MapFarming.Data.performanceData[nIndex] = {
        index = nIndex, row = nRow, col = nCol,
        centerX = nCenterX, centerY = nCenterY,
        record = tbRecord
    }
end
```

**优势**：不需要 GridPointData/GridTracker，nIndex 本身即去重 key。
**切换策略**：`MapFarming.SetCompareRule("triangles", "max")` 回到原版策略。
**数据格式**：结构化 table → JsonEncode，不是 CSV 字符串。

### 版本4：最终版（Perfeye + GridTracker）

```lua
-- GridTracker 存格子级别元数据
MapFarming.GridTracker[nIndex] = { posKey = szKey, record = tbRecord }

-- Process(): GridTracker 追踪 + 完整工程化
if oldTracker then
    if not MapFarming.IsBetterRecord(tbRecord, oldTracker.record) then
        return true
    end
    if oldTracker.posKey ~= szKey then
        MapFarming.Data.performanceData[oldTracker.posKey] = nil
    end
end
```

**额外功能**：SampleDistance 节流、SampleIntervalMS 采样间隔、截图标记、DebugPrints、Perfeye 集成。

---

## 用户澄清：坐标点的含义

用户确认「坐标点」指网格行列坐标（row, col），如 13,10 这种几十以内的值，**不是**世界坐标（131000 级别）。nIndex 就是 (row, col) 的一对一映射，模板版用 nIndex 做 key 等价于按网格去重。

---

## 最小改动模式

当需要在现有版本上仅做最小改动实现分支1（FPS 去重）时，有两种典型场景：

### 场景A：分支2 → 分支1（加 EnableDedup 开关）

分支2 是「全量追加」版本（215行），已有 `GridPointData` 追踪。最小改动仅需：

**顶部加一行：**
```lua
MapFarming.EnableDedup = true  -- true=FPS去重，false=全量追加
```

**Process() 的 63-70 行替换为：**
```lua
if MapFarming.EnableDedup then
    -- FPS 去重：每格只留 FPS 最低
    if MapFarming.GridPointData[szIndex] then
        local szPrevKey = MapFarming.GridPointData[szIndex]
        local prevParts = SearchPanel.StringSplit(
            MapFarming.Data.performanceData[szPrevKey][1], ",")
        local curParts = SearchPanel.StringSplit(strData, ",")
        local nPrevFps = tonumber(prevParts[10]) or 0
        local nCurFps = tonumber(curParts[10]) or 0
        if nCurFps >= nPrevFps then
            return  -- FPS 没更低，跳过
        end
        MapFarming.Data.performanceData[szPrevKey] = nil
    end
    MapFarming.Data.performanceData[szKey] = {strData}
    MapFarming.GridPointData[szIndex] = szKey
else
    -- 原逻辑：全量追加
    if not MapFarming.Data.performanceData[szKey] then
        MapFarming.Data.performanceData[szKey] = {}
    end
    table.insert(MapFarming.Data.performanceData[szKey], strData)
    MapFarming.GridPointData[szIndex] = szKey
end
```

**改动量**：+1行顶部变量，Process 函数体内替换一处。不需要加任何新函数或新结构。

### 场景B：最终版 → 网格中心坐标 key

最终版用玩家实际坐标 `(nX, 1000000, nY)` 做 key，同格多次采样产生不同 key（靠 GridTracker 兜底去重）。改为网格中心坐标 key 仅需三处变动：

```lua
-- 原：先算 key 再算网格
-- local szPosKey = MapFarming.MakePositionKey(nRecordX, nRecordY)
-- ...
-- local nIndex, _, _ = MapFarming.point_to_grid(nRecordX, nRecordY)

-- 改：先算网格，key 用网格中心坐标
local nIndex, nRow, nCol = MapFarming.point_to_grid(nRecordX, nRecordY)
local nCenterX, nCenterY = MapFarming.get_grid_center(nRow, nCol)
local szPosKey = MapFarming.MakePositionKey(nCenterX, nCenterY)
```

改动后同格所有采样共享一个 key，性能数据直接反映该格的最差帧。

---

## 数据源不兼容坑

**最终版（554行）使用 `GetPerfData.GetLastStatResult()`，而分支1/2/模板版使用 `GetHotPointReader().GetFrameDataInfo()`。**

如果最终版放到没有 Perfeye SDK 的游戏里：
- `RecordData()` 返回 `nil`
- `Process()` 直接 `return false`
- `FrameUpdate()` 不更新目标坐标
- **结果：一条数据都跑不出来**

适配方法：将 `RecordData()` 里的数据源从 `GetPerfData` 换为 `GetHotPointReader`，同时调整 `FormatRecordString()` 的输出列顺序。

此坑在本次会话中实际踩中并定位。**排查症状**：插件启动正常、日志无报错、但 Data.json 始终为空。

---

## 迭代记录

| 版本 | 列索引 | 比较方向 | 问题 |
|------|--------|----------|------|
| 初版 | parts[10] 读 FPS | `>` 取最大值 | FPS 高=流畅，取了最好的那条，反了 |
| 尝试修正1 | parts[11] 读 Ms | `>` | Ms 是 `SampleCount` 不是帧耗时，列错了 |
| 尝试修正2 | parts[9] 读 Memory | `>` | 用户纠正：应该比 FPS 不是 Memory |
| **最终版** | **parts[10] 读 FPS** | **`<` 取最小值** | ✓ 每格保留帧率最低（最卡）的数据 |

## CaseHotPointMap.py 两套方案（正交配置）

- **RunType**：1=高空raycast(防房顶) / 2=Z归零(跑地宫)
- **DedupType**：0=保留全部 / 1=每格只留最差
- **sdk**：3=关NPC/阴影/doodad / 4=多关植被

## CaseHotPointMap.py 两套方案（正交配置）

- **RunType**：1=高空raycast(防房顶) / 2=Z归零(跑地宫)
- **DedupType**：0=保留全部 / 1=每格只留最差
- **sdk**：3=关NPC/阴影/doodad / 4=多关植被
