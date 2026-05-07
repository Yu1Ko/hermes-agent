# WJ 热力图分支1实现（MapFarming）

## 背景

WJ 热力图有两套采集方案：
- **HotPointRunMapOneDepth**：网格遍历，每格固定 4 方向各 1 条数据
- **MapFarming / CustomRunMap**：自定义路径边走边采，每格可能踩到十几次

分支 1（每格只留性能最差）对 HotPointRunMapOneDepth 意义不大（本来就只有 4 条），对 MapFarming 才是真正有意义的地方。

## MapFarming.Process() 修复

文件：`Interface/MapFarming/MapFarming.lua`

原逻辑问题：
1. 比较字段用错了——比的是 Memory（index 8），应该比 Ms 帧耗时（index 10）
2. 坐标 key 漂移——同格不同时机算出的中心坐标可能差一点，导致旧 key 删不掉

修复后逻辑（已写入）：
```lua
function MapFarming.Process()
    -- 解析 Ms（帧耗时，越大越差）
    local parts = SearchPanel.StringSplit(strData, ",")
    local nCurMs = tonumber(parts[10]) or 0

    if MapFarming.GridPointData[szIndex] then
        -- 同格已有数据，比 Ms，只有更差才替换
        local prevParts = SearchPanel.StringSplit(prevEntries[1], ",")
        local nPrevMs = tonumber(prevParts[10]) or 0
        if nCurMs > nPrevMs then
            MapFarming.Data.performanceData[szPrevKey] = nil
            MapFarming.Data.performanceData[szKey] = {strData}
            MapFarming.GridPointData[szIndex] = szKey
        end
        -- 否则保留旧数据，丢弃当前
    else
        MapFarming.Data.performanceData[szKey] = {strData}
        MapFarming.GridPointData[szIndex] = szKey
    end
end
```

## CaseHotPointMap.py 两套方案（正交配置）

- **RunType**：1=高空raycast(防房顶) / 2=Z归零(跑地宫)
- **DedupType**：0=保留全部 / 1=每格只留最差
- **sdk**：3=关NPC/阴影/doodad / 4=多关植被
- 触发条件：CaseHotPointMap.py + tab里调了 MapFarming.Start()

## 数据格式

`performanceData` key: `"(centerX,1000000,centerY)"`
条目: `"(0.00, angle, 0.00),SetPassCall,DrawCall,DrawBatch,Vertices,Triangles,Memory,Fps,Ms,CMD"`
Ms 在 split(",") 后的 index 10（0-based）
