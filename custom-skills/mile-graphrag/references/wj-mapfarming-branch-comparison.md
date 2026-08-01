# WJ MapFarming 全版本对比

`MapFarming.lua` 在 WJ 项目中有多个版本，核心差异在 `Process()` 的去重策略和数据源 API。

## 版本总览

| # | 版本 | 数据源 | Process 策略 | key 格式 | 数据格式 |
|---|------|--------|-------------|---------|---------|
| 0 | 原版 | GetHotPointReader | 面数去重 (triangles max) | `"(nCenterX,1000000,nCenterY)"` | CSV 字符串 |
| 1 | 分支1 (Ms) | GetHotPointReader | Ms 去重 (Ms max) | `"(nCenterX,1000000,nCenterY)"` | CSV 字符串 |
| 2 | 分支2 (全量) | GetHotPointReader | 不做去重，table.insert | `"(nCenterX,1000000,nCenterY)"` | CSV 字符串 |
| 3 | 模板版 | GetHotPointReader | CompareConfig 可配置去重 | nIndex (数字) | 结构化 Lua table |
| 4 | 最终版 (GetPerfData) | GetPerfData.GetLastStatResult | FPS 去重，GridTracker | `"(nX,1000000,nY)"` 玩家坐标 | 结构化→CSV |
| 5 | 最终版 (GetHotPointReader) | GetHotPointReader | FPS 去重，GridTracker | `"(nX,1000000,nY)"` 玩家坐标 | 结构化→CSV |

## 各版本 Process() 核心逻辑

### 版本 0-2：同一代码基底，只改 Process()

三个版本共用同样的 `point_to_grid` / `get_grid_center` / `RecordData` / `GridPointData` 结构。key 统一用 `"(nCenterX, 1000000, nCenterY)"` 网格中心坐标。

**RecordData 返回格式** (CSV 字符串)：
```
"(0.00, 0.00, 0.00),setPass,drawCall,drawBatch,vertices,triangles,memory,fps,ms,cmd"
```
StringSplit(",") 后：parts[1-3]=camera 三值, parts[4]=setPass, ..., parts[10]=fps, parts[11]=ms

⚠️ 相机串 `"(0.00, 0.00, 0.00),"` 有尾逗号，Split 后会产生一个独立元素，列偏移从 4 开始而非 1。

### 版本 3：模板版（CompareConfig 可配置）

```lua
MapFarming.CompareConfig = {
    compareField = "triangles",  -- 默认按面数
    compareMode = "max"          -- 保留最大值
}
```

`RecordData()` 返回结构化 table `{camera, setPass, drawCall, ..., fps, ms, cmd}`。
`IsBetterRecord(new, old)` 根据 CompareConfig 判断。
`Process()` 用 `nIndex` 做 key（不是坐标字符串），`Data.performanceData[nIndex] = {index, row, col, centerX, centerY, record}`。

**灵活性**：`SetCompareRule("fps", "min")` 一键切到 FPS 最低去重。支持 8 字段 × 2 模式 = 16 种组合。

**最小改动到分支1**：只改 CompareConfig 两行 → `compareField = "fps"` / `compareMode = "min"`。其他原封不动。

### 版本 4-5：最终版（不同数据源）

两个版本结构相同，区别仅 RecordData 数据源：
- 版本 4（旧最终版）：`GetPerfData.GetLastStatResult()` → 返回 `{Drawcall, DrawTriangles, Memory, FPS, LogicFps, Ms, SampleCount}`
- 版本 5（新最终版）：`GetHotPointReader().GetFrameDataInfo()` → 返回同版本 0-3

**版本 4 放在用 GetHotPointReader 的游戏里完全跑不出数据**——`GetPerfData` 不存在，`RecordData()` 返回 nil，`Process()` 立即 `return false`，`FrameUpdate()` 不更新 `nTargetX/nTargetY`。额外差异：`RunMapResultPath` 写死 `"c:\\hotpointdata\\"` 而非 `SearchPanel.szCurrentInterfacePath`。

版本 5 将数据源切回 `GetHotPointReader`，路径改为 `SearchPanel.szCurrentInterfacePath`，兼容该游戏的 API。

**两个版本的 Process() 都用 `GridTracker[nIndex]` 做格子级去重**，但 key 是玩家实际坐标 `"(nRecordX, 1000000, nRecordY)"` 而非网格中心坐标。同格多次采样会产生不同 key，靠 GridTracker 兜底。

**改到网格中心坐标 key**：Process() 里加两行——
```lua
local nIndex, nRow, nCol = MapFarming.point_to_grid(nRecordX, nRecordY)
local nCenterX, nCenterY = MapFarming.get_grid_center(nRow, nCol)
local szPosKey = MapFarming.MakePositionKey(nCenterX, nCenterY)  -- was nRecordX, nRecordY
```

## EnableDedup 开关模式（分支2 最简改法）

从分支2（全量追加）到分支1（FPS 去重）的最小改动：不引入新结构，复用已有 `GridPointData`。

```lua
-- 顶部加一行
MapFarming.EnableDedup = true

-- Process() 里包 if/else
if MapFarming.EnableDedup then
    if MapFarming.GridPointData[szIndex] then
        -- 比 FPS，parts[10]，nCurFps < nPrevFps 才替换
        ...
    end
    MapFarming.Data.performanceData[szKey] = {strData}
    MapFarming.GridPointData[szIndex] = szKey
else
    -- 原样 table.insert 全量追加
    ...
end
```

默认开启去重，`EnableDedup = false` 回到全量模式。

## 关键 pitfall

- **不同版本的 StringSplit 列偏移不可混用**：MapFarming.lua（相机尾逗号）和 MapFarming2.lua（无尾逗号）的列索引差 1
- **最终版 4 的 GetPerfData 仅存在于特定游戏**：放到其他游戏就是空壳
- **用户偏好极简改动**：能不改的别改，能复用的别新建，能用现有 GridPointData 就别加 GridTracker
- **最小分支1化 = 只改 CompareConfig 或只改 Process() 6 行**
