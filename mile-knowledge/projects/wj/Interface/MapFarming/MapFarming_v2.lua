MapFarming = {}
MapFarming.Data = { ["performanceData"] = {} }
MapFarming.GridPointData = {}   -- szIndex → szKey 映射（分支1）
MapFarming.GridTracker = {}     -- szIndex → {posKey, ms} 去重追踪（最终版）
MapFarming.DEBUG = false

-- 网格配置
MapFarming.nStepSize = 10000
MapFarming.max_x = 131000
MapFarming.max_y = 131000
MapFarming.grid_cols = 1
MapFarming.grid_rows = 1
MapFarming.cell_width = MapFarming.nStepSize
MapFarming.cell_height = MapFarming.nStepSize

-- 采样移动阈值（单位距离）
MapFarming.SampleDistance = 1000

-- 记录保留策略
-- compareField 可选：
-- "triangles", "fps", "drawCall", "drawBatch", "memory", "setPass", "ms", "vertices"
-- compareMode 可选：
-- "max"：保留字段值更大的记录
-- "min"：保留字段值更小的记录
--
-- 分支1 默认：每格只保留 FPS 最低的 = 性能最差的那条
MapFarming.CompareConfig = {
    compareField = "fps",
    compareMode = "min"
}

-- 上次采样点
MapFarming.nTargetX = 0
MapFarming.nTargetY = 0

local list_CameraStatue = {
    [1] = "1083, 1, 1.570, -0.217", -- 东
    [2] = "1083, 1, 3.140, -0.217", -- 西
    [3] = "1083, 1, 4.710, -0.217", -- 南
    [4] = "1083, 1, 6.280, -0.217"  -- 北
}

local function DebugPrint(...)
    if MapFarming.DEBUG then
        print(...)
    end
end

-- 设置比较规则
function MapFarming.SetCompareRule(fieldName, mode)
    local validFields = {
        triangles = true,
        fps = true,
        drawCall = true,
        drawBatch = true,
        memory = true,
        setPass = true,
        ms = true,
        vertices = true
    }

    local validModes = {
        max = true,
        min = true
    }

    if validFields[fieldName] then
        MapFarming.CompareConfig.compareField = fieldName
    else
        print("MapFarming.SetCompareRule invalid field:", tostring(fieldName))
    end

    if validModes[mode] then
        MapFarming.CompareConfig.compareMode = mode
    else
        print("MapFarming.SetCompareRule invalid mode:", tostring(mode))
    end
end

-- 获取当前比较字段
function MapFarming.GetCompareField()
    return MapFarming.CompareConfig.compareField
end

-- 获取当前比较模式
function MapFarming.GetCompareMode()
    return MapFarming.CompareConfig.compareMode
end

-- 判断新记录是否优于旧记录
function MapFarming.IsBetterRecord(newRecord, oldRecord)
    if not newRecord then
        return false
    end

    if not oldRecord then
        return true
    end

    local field = MapFarming.CompareConfig.compareField
    local mode = MapFarming.CompareConfig.compareMode

    local newValue = tonumber(newRecord[field]) or 0
    local oldValue = tonumber(oldRecord[field]) or 0

    if mode == "max" then
        return newValue > oldValue
    elseif mode == "min" then
        return newValue < oldValue
    end

    return false
end

-- 获取地图范围，并按步长计算网格
function MapFarming.GetMapMax(a, b)
    MapFarming.max_x = a
    MapFarming.max_y = b
    MapFarming.cell_width = MapFarming.nStepSize
    MapFarming.cell_height = MapFarming.nStepSize
    MapFarming.grid_cols = math.max(1, math.ceil(MapFarming.max_x / MapFarming.cell_width))
    MapFarming.grid_rows = math.max(1, math.ceil(MapFarming.max_y / MapFarming.cell_height))
end

-- 获取某行某列格子的范围（左上和右下）
function MapFarming.get_grid_rect(row, col)
    local x0 = (col - 1) * MapFarming.cell_width
    local y0 = (row - 1) * MapFarming.cell_height
    local x1 = math.min(col * MapFarming.cell_width, MapFarming.max_x)
    local y1 = math.min(row * MapFarming.cell_height, MapFarming.max_y)
    return { x0 = x0, y0 = y0, x1 = x1, y1 = y1 }
end

-- 判断一个点(x, y)属于哪一行哪一列，以及格子索引
function MapFarming.point_to_grid(x, y)
    local col = math.floor(x / MapFarming.cell_width) + 1
    local row = math.floor(y / MapFarming.cell_height) + 1

    if col < 1 then col = 1 end
    if row < 1 then row = 1 end
    if col > MapFarming.grid_cols then col = MapFarming.grid_cols end
    if row > MapFarming.grid_rows then row = MapFarming.grid_rows end

    local index = (row - 1) * MapFarming.grid_cols + col
    return index, row, col
end

-- 获取指定行、列格子的中心点坐标
function MapFarming.get_grid_center(row, col)
    local x = math.floor((col - 0.5) * MapFarming.cell_width)
    local y = math.floor((row - 0.5) * MapFarming.cell_height)

    if x > MapFarming.max_x then x = MapFarming.max_x end
    if y > MapFarming.max_y then y = MapFarming.max_y end

    return x, y
end

-- 生成位置 key（分支1 格式：网格中心坐标）
function MapFarming.MakePositionKey(nX, nY)
    return string.format("(%d,%d,%d)", nX, 1000000, nY)
end

-- 获取当前数据（结构化）
function MapFarming.RecordData()
    local player = GetClientPlayer()
    local szKeyGM = string.format("(%d,%d,%d)", player.nX, player.nY, player.nZ)
    local szKeyGM3dPos = string.format("(%d,%d,%d)",
        Scene_GameWorldPositionToScenePosition(player.nX, player.nZ, player.nY))

    local info = GetHotPointReader().GetFrameDataInfo()

    local nSetPassCall = info.setPass or 0
    local nDrawcall = info.DrawCallCnt or 0
    local nDrawBatch = info.DrawBatchCnt or 0
    local nVertices = 0
    local nTriangles = info.FaceCnt or 0
    local nMemory = info.vulkanMemory or 0
    local fps = info.FPS or 0

    local ms = 0
    if fps > 0 then
        ms = math.floor((1000 / fps) * 10) / 10
    end

    local szCMD = string.format(
        'SendGMCommand("player.SetPosition%s;player.BirdFlyTo%s");Camera_SetRTParams(%s);print%s;',
        szKeyGM,
        szKeyGM,
        list_CameraStatue[1]:sub(6, -1),
        szKeyGM3dPos
    )

    return {
        camera = { 0.00, 0.00, 0.00 },
        setPass = nSetPassCall,
        drawCall = nDrawcall,
        drawBatch = nDrawBatch,
        vertices = nVertices,
        triangles = nTriangles,
        memory = nMemory,
        fps = fps,
        ms = ms,
        cmd = szCMD
    }
end

-- 将结构化数据转为 CSV 字符串（分支1 兼容格式）
function MapFarming.FormatRecordString(tbRecord)
    if not tbRecord then
        return nil
    end

    local szCameraInfo = string.format("(%.2f, %.2f, %.2f),",
        tbRecord.camera[1] or 0,
        tbRecord.camera[2] or 0,
        tbRecord.camera[3] or 0)

    return szCameraInfo .. string.format("%d,%d,%d,%d,%d,%d,%d,%.1f,%s",
        tbRecord.setPass or 0,
        tbRecord.drawCall or 0,
        tbRecord.drawBatch or 0,
        tbRecord.vertices or 0,
        tbRecord.triangles or 0,
        tbRecord.memory or 0,
        tbRecord.fps or 0,
        tbRecord.ms or 0,
        tbRecord.cmd or "")
end

-- 处理当前点数据
-- 分支1 策略：每个格子只保留 FPS 最低（性能最差）的一条
-- 参考最终版的 GridTracker 做格子级去重追踪
function MapFarming.Process()
    local player = GetClientPlayer()
    local nRecordX = player.nX
    local nRecordY = player.nY

    local nIndex, nRow, nCol = MapFarming.point_to_grid(nRecordX, nRecordY)
    local nCenterX, nCenterY = MapFarming.get_grid_center(nRow, nCol)
    local tbRecord = MapFarming.RecordData()

    local szKey = MapFarming.MakePositionKey(nCenterX, nCenterY)

    -- 查 GridTracker：这个格子之前有没有记录
    local oldTracker = MapFarming.GridTracker[nIndex]

    if oldTracker then
        -- 用 CompareConfig 判断当前记录是否比旧记录"更好"
        if not MapFarming.IsBetterRecord(tbRecord, oldTracker.record) then
            DebugPrint("Skip grid", nIndex)
            return true
        end

        -- 当前更差，替换。先清掉旧的 key
        if oldTracker.posKey ~= szKey then
            MapFarming.Data.performanceData[oldTracker.posKey] = nil
        end
    else
        -- 第一次进这个格子，记录 GridPointData 的 szIndex → szKey 映射
        MapFarming.GridPointData[tostring(nIndex)] = szKey
    end

    -- 更新 GridTracker
    MapFarming.GridTracker[nIndex] = {
        posKey = szKey,
        record = tbRecord
    }

    -- 转 CSV 字符串存入（分支1 格式：每个 key 只存一条）
    local szRecord = MapFarming.FormatRecordString(tbRecord)
    MapFarming.Data.performanceData[szKey] = { szRecord }

    DebugPrint("save grid", nIndex, "key:", szKey)
    return true
end

-- 判断是否达到采样距离
function MapFarming.ShouldSample(nPlayerX, nPlayerY, nTargetX, nTargetY)
    local dx = nTargetX - nPlayerX
    local dy = nTargetY - nPlayerY
    return (dx * dx + dy * dy) >= (MapFarming.SampleDistance * MapFarming.SampleDistance)
end

function MapFarming.InitData()
    local player = GetClientPlayer()
    MapFarming.nTargetX = player.nX
    MapFarming.nTargetY = player.nY
end

-- 每秒检测一次，移动超过阈值就更新数据
function MapFarming.FrameUpdate()
    local player = GetClientPlayer()
    local nX = player.nX
    local nY = player.nY

    if MapFarming.ShouldSample(nX, nY, MapFarming.nTargetX, MapFarming.nTargetY) then
        MapFarming.Process()
        DebugPrint("--------------------运行更新中--------------------")
        MapFarming.nTargetX = nX
        MapFarming.nTargetY = nY
        DebugPrint("--------------------完成更新--------------------")
    end
end

-- 写入一个空白占位数据
function MapFarming.SetNullData(nX, nY)
    local index, row, col = MapFarming.point_to_grid(nX, nY)
    local centerX, centerY = MapFarming.get_grid_center(row, col)
    local szKey = MapFarming.MakePositionKey(centerX, centerY)

    if not MapFarming.Data.performanceData[szKey] then
        local tbDummy = {
            camera = { 0.00, 0.00, 0.00 },
            setPass = 0,
            drawCall = 0,
            drawBatch = 0,
            vertices = 0,
            triangles = 0,
            memory = 0,
            fps = 0,
            ms = 0,
            cmd = "testGM"
        }
        local szRecord = MapFarming.FormatRecordString(tbDummy)
        MapFarming.Data.performanceData[szKey] = { szRecord }

        -- 也初始化 GridTracker 和 GridPointData
        MapFarming.GridTracker[index] = {
            posKey = szKey,
            record = tbDummy
        }
        MapFarming.GridPointData[tostring(index)] = szKey
    end
end

-- 插件开始
function MapFarming.Start()
    -- 初始化
    MapFarming.IsRun = false
    MapFarming.nMaxX = 0
    MapFarming.nMaxY = 0
    MapFarming.nMaxZ = 0
    MapFarming.nMinX = 0
    MapFarming.nMinY = 0
    MapFarming.nMinZ = 0

    -- 复位追踪结构
    MapFarming.GridTracker = {}
    MapFarming.GridPointData = {}
    MapFarming.Data = { ["performanceData"] = {} }

    local tbSleepType = {
        NextPointSleep = 1,
        CameraRotationSleep = 2,
        CullSleep = 3
    }
    local tbSleepTime = {
        [tbSleepType.NextPointSleep] = 1,
        [tbSleepType.CameraRotationSleep] = 1,
        [tbSleepType.CullSleep] = 0.5
    }

    local player = GetClientPlayer()
    local scene = player.GetScene()
    local szFileName = tostring(scene.dwMapID)

    local file = io.open(SearchPanel.szCurrentInterfacePath .. szFileName, "w")
    if file then
        local nX, nY, nZ = scene.GetXYZMax()
        local szContent = string.format("%d|%d\n", nX, nY)

        local nMaxX = nX - nX % MapFarming.nStepSize
        local nMaxY = nY - nY % MapFarming.nStepSize

        MapFarming.nMaxX = nMaxX
        MapFarming.nMaxY = nMaxY
        MapFarming.nMaxZ = nZ
        --地图大小设置
        MapFarming.max_x, MapFarming.max_y, _ = GetClientPlayer().GetScene().GetXYZMax()
        -- 初始化网格
        MapFarming.GetMapMax(nMaxX, nMaxY)

        -- 起点不为左下角
        MapFarming.SetNullData(0, 0)
        -- 终点不为右上角
        MapFarming.SetNullData(nMaxX, nMaxY)

        szContent = szContent .. string.format("%d|%d,%d|%d\n", 0, 0, nMaxX, nMaxY)
        szContent = szContent ..
        string.format("%d|%d\n", tbSleepTime[tbSleepType.NextPointSleep], tbSleepTime[tbSleepType.CameraRotationSleep])
        szContent = szContent .. string.format("%d", MapFarming.nStepSize)

        file:write(szContent)
        file:close()
    end

    -- 初始化第一个采样点
    MapFarming.InitData()

    Timer.AddCycle(MapFarming, 1, function()
        MapFarming.FrameUpdate()
    end)
end

-- 数据生成
function MapFarming.GenerateData()
    local szRet = JsonEncode(MapFarming.Data)
    local file = io.open(SearchPanel.szCurrentInterfacePath .. "Data.json", "w")
    if file then
        file:write(szRet)
        file:close()
    end
end
