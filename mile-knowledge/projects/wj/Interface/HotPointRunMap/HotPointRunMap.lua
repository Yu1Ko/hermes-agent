
LOG.INFO("HotPointRunMap imported")
--require("KQcHotSpotGather")

local HotPointRunMap = {}
local list_RunMapTime = {}
local list_RunMapCMD = {}
-- local waitLoad = tonumber(50)

HotPointRunMap.bSwitch = true

--步长 64个单位 == 0.125米，0.125*40=5米
HotPointRunMap.StepSize = 1280

HotPointRunMap.IsRun = false
HotPointRunMap.MaxX = 10000	--设置地图最大X
HotPointRunMap.MaxY = 20000	--设置地图最大Y
HotPointRunMap.MaxZ = 1075000	--设置地图最大Z
HotPointRunMap.MinX = 2000	--设置地图最小X
HotPointRunMap.MinY = 8000	--设置地图最小Y
HotPointRunMap.MinZ = 1050000	--设置地图最小Z

-- 设置热力图地图最大和最小XYZ
function HotPointRunMapMax(MaxX,MaxY,MaxZ)
	HotPointRunMap.MaxX = MaxX	--设置地图最大X
	HotPointRunMap.MaxY = MaxY	--设置地图最大Y
	HotPointRunMap.MaxZ = MaxZ	--设置地图最大Z
end

-- 设置热力图地图最大和最小XYZ
function HotPointRunMapMin(MinX,MinY,MinZ)
	HotPointRunMap.MinX = MinX	--设置地图最大X
	HotPointRunMap.MinY = MinY	--设置地图最大Y
	HotPointRunMap.MinZ = MinZ	--设置地图最大Z
end

-- 信息采集
local nNextCameraTime = 3
local nNextPosTime=5*nNextCameraTime + 1
local nCurrentTime=GetTickCount()
local bCanRecordPos=nil
local bInitRecord=true
SearchPanel.RemoveFile(SearchPanel.szCurrentInterfacePath.."Data.json")   --移除存储数据文件
SearchPanel.RemoveFile(SearchPanel.szCurrentInterfacePath.."posList.db")   --移除存储数据文件
SearchPanel.RemoveFile(SearchPanel.szRunMapResultPath.."BeginRunMap")
SearchPanel.RemoveFile(SearchPanel.szRunMapResultPath.."HotPoint_Start")
SearchPanel.RemoveFile(SearchPanel.szRunMapResultPath.."HotPoint_Stop")
local szFilePath=SearchPanel.szCurrentInterfacePath.."HotPointRunMap.ini"
local iniFile = Ini.Open(szFilePath)
local stepSize = iniFile:ReadString("HotPointRunMap", "StepSize", "")
local nextCameraTime = iniFile:ReadString("HotPointRunMap", "NextCameraTime", "")
local nextPosTime = iniFile:ReadString("HotPointRunMap", "NextPosTime", "")
HotPointRunMap.StepSize = tonumber(stepSize)/0.125
nNextCameraTime=tonumber(nextCameraTime)
nNextPosTime=tonumber(nextPosTime)

local tbRunMapData=SearchPanel.LoadRunMapFile(SearchPanel.szCurrentInterfacePath.."RunMap.tab",2)
list_RunMapCMD=tbRunMapData[1]
list_RunMapTime=tbRunMapData[2]

LOG.INFO('nextCameraTime:'..nextCameraTime..'\tnextPosTime:'..nextPosTime..'\tstepSize:'..stepSize)

local recordX = 0
local recordY = 0
local recordZ = 0

local isFinishFlag = false



-- 游戏内信息采集函数
local szKey=nil
local szKeyGM=nil
local tbHotPointData={["performanceData"]={}}
local nRotationIndex=0
local angle = {} --角度
HotPointRunMap.list_CameraStatue = {
	[0] = "2000, 1, 1.570, -0.217",	--东
	[1] = "2000, 1, 3.140, -0.217",	--西
	[2] = "2000, 1, 4.710, -0.217",	--南
	[3] = "2000, 1, 6.280, -0.217"	--北
}
local function RotationCamera()
	local szCmd = HotPointRunMap.list_CameraStatue[nRotationIndex]
	LOG.INFO("[LiBG] SetCameraStatus	:"..szCmd)
	angle = SearchPanel.StringSplit(szCmd,",")
	SetCameraStatus(angle[1],angle[2],angle[3],angle[4])
end

local function GetPlayerInfo()
	-- 角色朝向（东南西北）
	if bInitRecord then				--初始化记录数据
		--XGame 需要将Y和Z对调
		szKey=string.format("(%d,%d,%d)",recordX,recordZ,recordY)
		szKeyGM=string.format("(%d,%d,%d)",recordX,recordY,recordZ)
        LOG.INFO(szKey)
		bInitRecord=false
	end
	
	if nRotationIndex == 4 then		--四向转完成
		bCanRecordPos=false			--关闭记录
		nRotationIndex=0
		bInitRecord=true			--开启记录初始化
		return
	end
	RotationCamera()				--转向
	
    if not tbHotPointData.performanceData[szKey] then
        tbHotPointData.performanceData[szKey]={}
    end
	
    local fCameraToObjectEyeScale,fYaw ,fPitch = Camera_GetRTParams()
    local _, fMaxCameraDistance = Camera_GetParams()
    local trueCamereDistance = fMaxCameraDistance * fCameraToObjectEyeScale
    -- fCameraToObjectEyeScale 滚轮比例
    -- fYaw 水平角
    -- fPitch 俯仰角
    -- trueCamereDistance 实d:\VSCode\Microsoft VS Code Insiders\resources\app\out\vs\code\electron-sandbox\workbench\workbench.html际距离
    --local szCamerInfo=string.format("(%0.3f,%0.3f,%0.3f),",fCameraToObjectEyeScale,fYaw,fPitch)
    local szCamerInfo=string.format("(0.00, %0.2f, 0.00),",nRotationIndex*90)
	local info=GetHotPointReader().GetFrameDataInfo()
    local nSetPassCall=info.setPass    --setPassCall
    local nDrawcall = info.DrawCallCnt    --drawCall
    local nVertices=0    --顶点数
    local nTriangles=info.FaceCnt --面数
    local nMemory=info.vulkanMemory --内存
    local fps=info.FPS    --FPS
    local ms=1000/fps-1000/fps%0.1  --帧耗时
	local szCMD=string.format('/cmd SendGMCommand("player.SetPosition%s;player.BirdFlyTo%s");Camera_SetRTParams(%s)',szKeyGM,szKeyGM,HotPointRunMap.list_CameraStatue[nRotationIndex]:sub(6, -1))
    local szInfo=szCamerInfo..string.format("%d,%d,%d,%d,%d,%d,%0.1f,%s",nSetPassCall,nDrawcall,nVertices,nTriangles,nMemory,fps,ms,szCMD)
    table.insert(tbHotPointData.performanceData[szKey],szInfo)
    LOG.INFO("PlayerInfp:"..szKey..":  "..szInfo)
    nRotationIndex=nRotationIndex+1
end


--判断目标点是否在设定的边界内
function HotPointRunMap.IsValidPos(x,y,z)
	if x >= HotPointRunMap.MinX and x < HotPointRunMap.MaxX then
		if y >= HotPointRunMap.MinY and y < HotPointRunMap.MaxY then
			if z >= HotPointRunMap.MinZ and z <= HotPointRunMap.MaxZ then
				return true
			end
		end
	end
	return false
end

-- 单X轴坐标点合法性和可用性验证
function HotPointRunMap.X(nStep)
	local hotPointReader = GetHotPointReader()
	local player = GetClientPlayer()
	local scene = player.GetScene()
	local dwMapID = player.GetMapID()
	-- 设置角色为坐标轴中点，以角色所在位置对坐标增加 nStep 距离为目标点
	local x,y,z = recordX,recordY,recordZ
	x = x + nStep
	LOG.INFO(string.format("[LiBG] Next (%d,%d,%d)", x,y,z))
	
	-- 验证合法性，若不合法直接跳过这个点
	if HotPointRunMap.IsValidPos(x,y,z) then
		local r0, r1 = hotPointReader.IsVisible(dwMapID,recordX,recordY,recordZ, x,y,z)	--判断是否能够到达目标点  player.nX,player.nY-->x,y,z
		--LOG.INFO(" X [LiBG] hotPointReader ", r0, r1)
        if r0 then
			if r1 then
				local r,id,visible,visit = KQcHotSpotGather.LuaGetPosVisibleInfo(x,y,z)	--记录中是否有这个点，是则跳过
				if not r then
					KQcHotSpotGather.LuaAddPosition(x,y,z,1,0)
					--LOG.INFO(string.format("[LiBG] LuaAddPosition(%d,%d,%d)", x,y,z))						--数据库中不存在这个点 
					return true
				end
				--LOG.INFO(string.format("[LiBG] X skip 1111 (%d,%d,%d)=>(%d,%d,%d)", player.nX,player.nY,player.nZ, x,y,z))	--数据库中存在这个点 跳过
				return false
			end
			--LOG.INFO(string.format("[LiBG] X skip 2222 (%d,%d,%d)=>(%d,%d,%d)", player.nX,player.nY,player.nZ, x,y,z))		--该点不可达
			return false
		end
		--LOG.INFO(string.format("[LiBG] X skip 3333 (%d,%d,%d)", x,y,z))				--hotPointReader.IsVisible函数调用错误
		return false
	else
		--LOG.INFO(string.format("[LiBG] skip IsValidPos (%d,%d,%d)", x,y,z))		--已经超出地图的限定范围
	end
	--LOG.INFO(string.format("[LiBG] skip(%d,%d,%d)", x,y,z))
	return false
end

function HotPointRunMap.Y(nStep) 
	local hotPointReader = GetHotPointReader()
	local player = GetClientPlayer()
	local scene = player.GetScene()
	local dwMapID = player.GetMapID()
	
	local x,y,z = recordX,recordY,recordZ
	y = y + nStep
	--LOG.INFO(string.format("[LiBG] Next (%d,%d,%d)", x,y,z))
	if HotPointRunMap.IsValidPos(x,y,z) then
		local r0, r1 = hotPointReader.IsVisible(dwMapID,recordX,recordY,recordZ, x,y,z)
        --LOG.INFO(" X [LiBG] hotPointReader ", r0, r1)
		if r0 then
			if r1 then
				local r,id,visible,visit = KQcHotSpotGather.LuaGetPosVisibleInfo(x,y,z)
				if not r then
					KQcHotSpotGather.LuaAddPosition(x,y,z,1,0)
					--LOG.INFO(string.format("[LiBG] LuaAddPosition(%d,%d,%d)", x,y,z))
					return true
				end
				--LOG.INFO(string.format("[LiBG] Y skip 1111 (%d,%d,%d)=>(%d,%d,%d)", player.nX,player.nY,player.nZ, x,y,z))
				return false
			end
			--LOG.INFO(string.format("[LiBG] Y skip 2222 (%d,%d,%d)=>(%d,%d,%d)", player.nX,player.nY,player.nZ, x,y,z))
			return false
		end
		--LOG.INFO(string.format("[LiBG] Y skip 3333 (%d,%d,%d)", x,y,z))
		return false
	else
		--LOG.INFO(string.format("[LiBG] skip IsValidPos (%d,%d,%d)", x,y,z))
	end
		--LOG.INFO(string.format("[LiBG] skip(%d,%d,%d)", x,y,z))
	return false
end

function HotPointRunMap.Z(nStep)
	local hotPointReader = GetHotPointReader()
	local player = GetClientPlayer()
	local scene = player.GetScene()
	local dwMapID = player.GetMapID()
	
	local x,y,z = recordX,recordY,recordZ
	z = z + nStep
	--LOG.INFO(string.format("[LiBG] Next (%d,%d,%d)", x,y,z))
	if HotPointRunMap.IsValidPos(x,y,z) then
		local r0, r1 = hotPointReader.IsVisible(dwMapID,recordX,recordY,recordZ, x,y,z)
		--LOG.INFO(" Z [LiBG] hotPointReader ", r0, r1)
		if r0 then
			if r1 then
				local r,id,visible,visit = KQcHotSpotGather.LuaGetPosVisibleInfo(x,y,z)
				if not r then
					KQcHotSpotGather.LuaAddPosition(x,y,z,1,0)
					--LOG.INFO(string.format("[LiBG] LuaAddPosition(%d,%d,%d)", x,y,z))
					return true
				end
				--LOG.INFO(string.format("[LiBG] Z skip 1111 (%d,%d,%d)=>(%d,%d,%d)", player.nX,player.nY,player.nZ, x,y,z))
				return false
			end
			--LOG.INFO(string.format("[LiBG] Z skip 2222 (%d,%d,%d)=>(%d,%d,%d)", player.nX,player.nY,player.nZ, x,y,z))
			return false
		end
		--LOG.INFO(string.format("[LiBG] Z skip 3333 (%d,%d,%d)", x,y,z))
		return false
	else
		--LOG.INFO(string.format("[LiBG] skip IsValidPos (%d,%d,%d)", x,y,z))
	end
	--LOG.INFO(string.format("[LiBG] skip(%d,%d,%d)", x,y,z))
	return false
end

function HotPointRunMap.FrameUpdate()
    if not HotPointRunMap.IsRun then
        return
    end
    local player = GetClientPlayer()
	if bCanRecordPos and GetTickCount() <= nCurrentTime + nNextPosTime*1000+4*nNextCameraTime*1000 then
		if GetTickCount() >= nCurrentTime + (nRotationIndex + 1) * nNextCameraTime*1000 then
			GetPlayerInfo()
		end
		return
	end
	
	LOG.INFO("[LiBG] FrameUpdate 1")
	
	-- 返回角色当前所在位置的信息（信息，id，可达，是否使用过）
	
	local r,id,visible,visit = KQcHotSpotGather.LuaGetPosVisibleInfo(recordX,recordY,recordZ)
    --LOG.INFO("[DebugInfo] Posistion Info",KQcHotSpotGather.LuaGetPosVisibleInfo(recordX,recordY,recordZ))
	
	if r then
		-- 点位信息不为空，将该点位的 visit 设置为 true，即使用过这个点
		KQcHotSpotGather.LuaSetPosVisit(recordX,recordY,recordZ)
	else
		-- 点位信息为空，新增一个点位，设置点位信息为 visible=1即可达，visit=1即使用过
		KQcHotSpotGather.LuaAddPosition(recordX,recordY,recordZ,1,1)
	end
	
	local x0 = HotPointRunMap.X(HotPointRunMap.StepSize)
	local x1 = HotPointRunMap.X(-HotPointRunMap.StepSize)

	local x2 = HotPointRunMap.Y(HotPointRunMap.StepSize)
	local x3 = HotPointRunMap.Y(-HotPointRunMap.StepSize)

	local x4 = HotPointRunMap.Z(HotPointRunMap.StepSize)
	local x5 = HotPointRunMap.Z(-HotPointRunMap.StepSize)
	--x
	if x0 then
		recordX = recordX+HotPointRunMap.StepSize
		LOG.INFO(string.format("SendGMCommand(player.SetPosition(%d,%d,%d))",recordX,recordY,recordZ))
		SendGMCommand(string.format("player.SetPosition(%d,%d,%d)",recordX,recordY,recordZ))
		SendGMCommand(string.format("player.BirdFlyTo(%d,%d,%d)",  recordX,recordY,recordZ))
		SendGMCommand("player.Stop()")
        KQcHotSpotGather.LuaSetPosVisit(recordX,recordY,recordZ)
        nCurrentTime = GetTickCount()
        bCanRecordPos = true
		--LOG.INFO("[LiBG] FrameUpdate 2")
		return
	end

	if x1 then
		recordX = recordX-HotPointRunMap.StepSize
		LOG.INFO(string.format("SendGMCommand(player.SetPosition(%d,%d,%d))",recordX,recordY,recordZ))
		SendGMCommand(string.format("player.SetPosition(%d,%d,%d)",recordX,recordY,recordZ))
		SendGMCommand(string.format("player.BirdFlyTo(%d,%d,%d)",  recordX,recordY,recordZ))
		SendGMCommand("player.Stop()")
        KQcHotSpotGather.LuaSetPosVisit(recordX,recordY,recordZ)
        nCurrentTime = GetTickCount()
        bCanRecordPos = true
		--LOG.INFO("[LiBG] FrameUpdate 3")
		return
	end

	--y
	if x2 then
        recordY = recordY+HotPointRunMap.StepSize
		LOG.INFO(string.format("SendGMCommand(player.SetPosition(%d,%d,%d))",recordX,recordY,recordZ))
		SendGMCommand(string.format("player.SetPosition(%d,%d,%d)",recordX,recordY,recordZ))
		SendGMCommand(string.format("player.BirdFlyTo(%d,%d,%d)",  recordX,recordY,recordZ))
		SendGMCommand("player.Stop()")
        KQcHotSpotGather.LuaSetPosVisit(recordX,recordY,recordZ)
        nCurrentTime = GetTickCount()
        bCanRecordPos = true
		--LOG.INFO("[LiBG] FrameUpdate 4")
		return
	end

	if x3 then
        recordY = recordY-HotPointRunMap.StepSize
		LOG.INFO(string.format("SendGMCommand(player.SetPosition(%d,%d,%d))",recordX,recordY,recordZ))
		SendGMCommand(string.format("player.SetPosition(%d,%d,%d)",recordX,recordY,recordZ))
		SendGMCommand(string.format("player.BirdFlyTo(%d,%d,%d)",  recordX,recordY,recordZ))
		SendGMCommand("player.Stop()")
        KQcHotSpotGather.LuaSetPosVisit(recordX,recordY,recordZ)
        nCurrentTime = GetTickCount()
        bCanRecordPos = true
		--LOG.INFO("[LiBG] FrameUpdate 5")
		return
	end

	--z
	if x4 then
        recordZ = recordZ+HotPointRunMap.StepSize
		LOG.INFO(string.format("SendGMCommand(player.SetPosition(%d,%d,%d))",recordX,recordY,recordZ))
		SendGMCommand(string.format("player.SetPosition(%d,%d,%d)",recordX,recordY,recordZ))
		SendGMCommand(string.format("player.BirdFlyTo(%d,%d,%d)",  recordX,recordY,recordZ))
		SendGMCommand("player.Stop()")
        KQcHotSpotGather.LuaSetPosVisit(recordX,recordY,recordZ)
        nCurrentTime = GetTickCount()
        bCanRecordPos = true
		--LOG.INFO("[LiBG] FrameUpdate 6")
		return
	end

	if x5 then
        recordZ = recordZ-HotPointRunMap.StepSize
		LOG.INFO(string.format("SendGMCommand(player.SetPosition(%d,%d,%d))",recordX,recordY,recordZ))
		SendGMCommand(string.format("player.SetPosition(%d,%d,%d)",recordX,recordY,recordZ))
        SendGMCommand(string.format("player.BirdFlyTo(%d,%d,%d)",  recordX,recordY,recordZ))
		SendGMCommand("player.Stop()")
        KQcHotSpotGather.LuaSetPosVisit(recordX,recordY,recordZ)
        nCurrentTime = GetTickCount()
        bCanRecordPos = true
		--LOG.INFO("[LiBG] FrameUpdate 7")
		return
	end
	
	local r, x, y, z = KQcHotSpotGather.LuaGetNextVisitPos()
	if r then
		LOG.INFO(string.format("SendGMCommand(player.SetPosition(%d,%d,%d))",recordX,recordY,recordZ))
		LOG.INFO("[LiBG] FrameUpdate 8:",KQcHotSpotGather.LuaGetPosVisibleInfo(x,y,z))
		SendGMCommand(string.format("player.SetPosition(%d,%d,%d)",x,y,z))
		SendGMCommand(string.format("player.BirdFlyTo(%d,%d,%d)",x,y,z))
		SendGMCommand("player.Stop()")
        recordX = x
        recordY = y
        recordZ = z
        KQcHotSpotGather.LuaSetPosVisit(x,y,z)	-- 无论是否传送到指定点位，都认为传送过去的点位已经到达过（hotPointRedaer可达但和实际坐标一定的偏差）
		nCurrentTime = GetTickCount()
		bCanRecordPos = true
		--LOG.INFO("[LiBG] FrameUpdate 8")
		return
	end
	LOG.INFO("[LiBG] FrameUpdate 9")
	HotPointRunMap.Stop()
end

local pCurrentTime = 0
local bFlag=true
local nNextTime=tonumber(30)
local nCurrentStep=1
local function FrameUpdate()
    if not HotPointRunMap.bSwitch then
        return
    end
    if not SearchPanel.IsFromLoadingEnterGame() then
        return
    end
    if bFlag and GetTickCount()-pCurrentTime>nNextTime*1000 then
        if nCurrentStep==#list_RunMapCMD then
            bFlag=false
        end
        --切图前后置操作
        local szCmd=list_RunMapCMD[nCurrentStep]
        local nTime=tonumber(list_RunMapTime[nCurrentStep])
        LOG.INFO(szCmd)
        pcall(function ()
            SearchPanel.RunCommand(szCmd)
        end)
        LOG.INFO(szCmd.."===ok")
        OutputMessage("MSG_SYS",szCmd)
        nNextTime=nTime
		--切图操作
        if string.find(szCmd,"HotPoint_Start") then
			--启动跑图帧更新
			HotPointRunMap.nEntryID=Timer.AddFrameCycle(HotPointRunMap,1,function ()
				HotPointRunMap.FrameUpdate()
			end)
			--初始化理论坐标 X,Y,Z
			local player = GetClientPlayer()
			recordX=player.nX
			recordY=player.nY
			recordZ=player.nZ
            HotPointRunMap.Start()
            bFlag=false
        end
		pCurrentTime=GetTickCount()
        nCurrentStep=nCurrentStep+1 
    end
 
end

function HotPointRunMap.PrintPos()
	local player = GetClientPlayer()
	if not player then
        return
    end
	local scene = player.GetScene()
	HotPointRunMap.MaxX,HotPointRunMap.MaxY,HotPointRunMap.MaxZ = scene.GetXYZMax()
end

--创建数据库，启动帧更新
function HotPointRunMap.Start()
	if HotPointRunMap.IsRun then
		return
	end
    -- nCurrentTime = GetTickCount() + waitLoad*1000
    -- HotPointRunMap.PrintPos() 获取当前地图的最大边界
	if KQcHotSpotGather.LuaOpenDB(SearchPanel.szCurrentInterfacePath.."posList.db") then
		HotPointRunMap.IsRun = true
		LOG.INFO("[LiBG] create database")
    else
        LOG.INFO("[LiBG]fail to create database")
	end
end

function HotPointRunMap.Stop()
	-- Timer.DelAllTimer(HotPointRunMap)
	HotPointRunMap.IsRun = false

    -- 控制 RunMap.tab 执行位置
    bFlag=true
    pCurrentTime=GetTickCount()

	KQcHotSpotGather.LuaCloseDB()
	
	LOG.INFO("[LiBG] Output Data.json")
	local szRet=JsonEncode(tbHotPointData)
	local file=io.open(SearchPanel.szCurrentInterfacePath.."Data.json","w")
	LOG.INFO('HotPointRunMap:	'..szRet)
	file:write(szRet)
	file:close()

	LOG.INFO("[LiBG] finished")
end



Timer.AddFrameCycle(HotPointRunMap,1,function ()
    FrameUpdate()
end)

return HotPointRunMap
