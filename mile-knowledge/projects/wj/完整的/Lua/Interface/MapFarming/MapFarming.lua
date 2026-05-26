
MapFarming = {}
MapFarming.Data ={["performanceData"]={}}
MapFarming.GridPointData={}


local max_x = 131000   
local max_y = 131000   
local grid_count = 10000
local cell_width = 0
local cell_height = 0

-- 获取地图
function MapFarming.GetMapMax(a,b)
    max_x,max_y,_ = a,b
    cell_width = max_x / grid_count
    cell_height = max_y / grid_count
end

-- 获取某行某列的格子的范围（左上和右下）
function MapFarming.get_grid_rect(row, col)
    -- row, col 从1开始，分别代表第几行、第几列
    local x0 = (col - 1) * cell_width
    local y0 = (row - 1) * cell_height
    local x1 = col * cell_width
    local y1 = row * cell_height
    return {x0=x0, y0=y0, x1=x1, y1=y1}
end

-- 判断一个点(x, y)属于哪一行哪一列,第几个格子
function MapFarming.point_to_grid(x, y)
    print(cell_width,cell_height)
    local col = math.floor(x / cell_width) + 1
    local row = math.floor(y / cell_height) + 1
    if col > grid_count then col = grid_count end
    if row > grid_count then row = grid_count end
    local num_cols = math.ceil(max_x / grid_count)
    local index =  (row - 1) * num_cols + col
    return index,row, col
end


-- 获取指定行、列格子的中心点坐标
function MapFarming.get_grid_center(row, col)
    -- row, col 从1开始
    local x = math.floor((col - 0.5) * cell_width)
    local y = math.floor((row - 0.5) * cell_height)
    return x, y
end

-- 自定义数据比对
-- 数据检测分析处理 
function MapFarming.Process()
    local player = GetClientPlayer()
    local nRecordX = player.nX
    local nRecordY = player.nY
    local nIndex,nRow,nCol =  MapFarming.point_to_grid(nRecordX, nRecordY) -- 行 列
    local nCenterX,nCenterY=MapFarming.get_grid_center(nRow, nCol)
    local strData = MapFarming.RecordData() -- 当前数据
    local szIndex=tostring(nIndex)
    local szKey=string.format("(%d,%d,%d)",nCenterX,1000000,nCenterY)
    -- 是否存在值
    if MapFarming.GridPointData[szIndex] then
        -- 进行数据比对
        -- 目前是根据面数进行比对
        local tbData = SearchPanel.StringSplit(strData,",") -- 分割提取面数
        local OriginalData  = SearchPanel.StringSplit(MapFarming.Data.performanceData[MapFarming.GridPointData[szIndex]][1],",") -- 原数据分割提取面数
        -- 如果当前面数
        if tonumber(tbData[8]) > tonumber(OriginalData[8]) then
            print(MapFarming.GridPointData[szIndex])
            MapFarming.Data.performanceData[MapFarming.GridPointData[szIndex]] = {} --清除原数据
            MapFarming.Data.performanceData[szKey]={}
            table.insert(MapFarming.Data.performanceData[szKey],strData)
            MapFarming.GridPointData[szIndex] = szKey -- 存入格子表
        end
    else
        MapFarming.Data.performanceData[szKey]={}
        -- 直接存入
        table.insert(MapFarming.Data.performanceData[szKey],strData)
        MapFarming.GridPointData[szIndex] = szKey -- 存入格子表
    end
end


local list_CameraStatue = {
	[1] = "1083, 1, 1.570, -0.217",	--东
	[2] = "1083, 1, 3.140, -0.217",	--西
	[3] = "1083, 1, 4.710, -0.217",	--南
	[4] = "1083, 1, 6.280, -0.217"	--北
}

for key, value in pairs(MapFarming.get_grid_rect(52, 59)) do print(key, value) end

-- 获取当前数据
function MapFarming.RecordData()
    local player=GetClientPlayer()
    local szKeyGM=string.format("(%d,%d,%d)",player.nX,player.nY,player.nZ)
    local szKeyGM3dPos = string.format("(%d,%d,%d)",Scene_GameWorldPositionToScenePosition(player.nX,player.nZ,player.nY))
    -- 提取当前的数据
    local info=GetHotPointReader().GetFrameDataInfo()
    -- 记录的数据
    local nSetPassCall=info.setPass    --setPassCall
    local nDrawcall = info.DrawCallCnt    --drawCall
    local nDrawBatch = info.DrawBatchCnt    --drawbatch  DrawBatchCnt
    local nVertices=0    --顶点数
    local nTriangles=info.FaceCnt --面数
    local nMemory=info.vulkanMemory --内存
    local fps=info.FPS    --FPS
    local ms=1000/fps-1000/fps%0.1  --帧耗时
    local szCMD = string.format('SendGMCommand("player.SetPosition%s;player.BirdFlyTo%s");Camera_SetRTParams(%s);print%s;',szKeyGM,szKeyGM,list_CameraStatue[1]:sub(6, -1),szKeyGM3dPos)
    local szCamerInfo = string.format("(0.00, 0.00, 0.00),")
    local szInfo=szCamerInfo..string.format("%d,%d,%d,%d,%d,%d,%d,%0.1f,%s",nSetPassCall,nDrawcall,nDrawBatch,nVertices,nTriangles,nMemory,fps,ms,szCMD)
    return szInfo
end

function MapFarming.JudgeArrive(nPlayerX,nPlayerY,nTargetX,nTargetY)
    local nVectorX=nTargetX-nPlayerX
    local nVectorY=nTargetY-nPlayerY
    -- print(nPlayerX,nPlayerY,nTargetX,nTargetY)
    -- print(nVectorX*nVectorX+nVectorY*nVectorY >=1000)
    if nVectorX*nVectorX+nVectorY*nVectorY >=1000 then
        return true
    else
        return false
    end
end

local nTargetX = 0
local nTargetY = 0

function MapFarming.InitData()
    local player = GetClientPlayer()
    local nX = player.nX
    local nY = player.nY
    nTargetX = nX
    nTargetY = nY
end


-- 每一秒 检测距离每过1000 更新下数据表
function MapFarming.FrameUpdate()
    local player = GetClientPlayer()
    local nX = player.nX
    local nY = player.nY
    if MapFarming.JudgeArrive(nX,nY,nTargetX,nTargetY) then
        MapFarming.Process()
        print("--------------------运行更新中--------------------")
        nTargetX = nX
        nTargetY = nY  -- 更新点位
        print("--------------------完成更新--------------------")
    end
end

function MapFarming.SetNullData(nX,nY)
    -- body
    local szKey=string.format("(%d,%d,%d)",nX,1000000,nY)
    if not MapFarming.Data.performanceData[szKey] then
        MapFarming.Data.performanceData[szKey]={}
    end
    local szInfo="(0.00, 0.00, 0.00),0,0,0,0,0,0,0,0,testGM"
    table.insert(MapFarming.Data.performanceData[szKey],szInfo)
end




-- 插件开始
function MapFarming.Start()
    -- 初始化
    MapFarming.nStepSize = 10000
    MapFarming.IsRun = false
    MapFarming.nMaxX = 0	--设置地图最大X
    MapFarming.nMaxY = 0	--设置地图最大Y
    MapFarming.nMaxZ = 0	--设置地图最大Z
    MapFarming.nMinX = 0	--设置地图最小X
    MapFarming.nMinY = 0	--设置地图最小Y
    MapFarming.nMinZ = 0	--设置地图最小Z
    local tbSleepType={
        NextPointSleep=1,
        CameraRotationSleep=2,
        CullSleep=3
    }
    local tbSleepTime={
        [tbSleepType.NextPointSleep]=1,
        [tbSleepType.CameraRotationSleep]=1,
        [tbSleepType.CullSleep]=0.5
    }
    local player = GetClientPlayer()
    local scene = player.GetScene()
    local szFileName=tostring(scene.dwMapID)

    file=io.open(SearchPanel.szCurrentInterfacePath..szFileName,"w")
    if file then
        local nX,nY,nZ=scene.GetXYZMax()
        local szContent=string.format("%d|%d\n",nX,nY)
        local nMaxX=nX-nX%MapFarming.nStepSize
        local nMaxY=nY-nY%MapFarming.nStepSize
        --起点不为左下角
        MapFarming.SetNullData(0,0)
        --终点不为右上角
        MapFarming.SetNullData(nMaxX,nMaxY)
        szContent=szContent..string.format("%d|%d,%d|%d\n",0,0,nMaxX,nMaxY)
        MapFarming.GetMapMax(nMaxX,nMaxY)
        --szContent=szContent..string.format("%d|%d,%d|%d\n",MapFarming.nMinX,MapFarming.nMinY,nRecordX,MapFarming.nRecordY)
        szContent=szContent..string.format("%d|%d\n",tbSleepTime[tbSleepType.NextPointSleep],tbSleepTime[tbSleepType.CameraRotationSleep])
        szContent=szContent..string.format("%d",MapFarming.nStepSize)
        file:write(szContent)
        file:close()
    end
    -- 记录第一个坐标
    MapFarming.InitData()
    Timer.AddCycle(MapFarming,1,function ()
        MapFarming.FrameUpdate()
    end)
end

-- 数据生成
function MapFarming.GenerateData()
    local szRet=JsonEncode(MapFarming.Data)
	local file=io.open(SearchPanel.szCurrentInterfacePath.."Data.json","w")
	file:write(szRet)
	file:close()
end
