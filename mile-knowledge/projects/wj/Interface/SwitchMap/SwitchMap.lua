SwitchMap={}
SwitchMap.bSwitch = true
SwitchMap.nOptionalMap = 1 -- 1为自定义切图,2GM配置表切图

local szFilePath=SearchPanel.szCurrentInterfacePath.."SwitchMap.ini"
local iniFile = Ini.Open(szFilePath)
local mWaitTime = iniFile:ReadString("SwitchMap", "SwitchMapWaitTime", "")
local mCountStart=iniFile:ReadString("SwitchMap", "MapStart", "")
local mCountEnd=iniFile:ReadString("SwitchMap", "MapEnd", "")
local vSleepTime=iniFile:ReadString("SwitchVideo", "SwitchVideoWaitTime", "")
local bVideoSwitch = iniFile:ReadString("SwitchVideo", "VideoSwitch", "")
local nOptionalMap=iniFile:ReadString("SwitchMap","OptionalMap","")
SwitchMap.nSwitchMapSleepTime = tonumber(mWaitTime)     -- 切换地图时间
SwitchMap.nVideoSleepTime = tonumber(vSleepTime)    -- 切换画质时间
SwitchMap.bVideoSwitch = tonumber(bVideoSwitch)   -- 画质开关
SwitchMap.nMapStart = tonumber(mCountStart)         -- 自定义开始地图
SwitchMap.nMapEnd = tonumber(mCountEnd)             -- 自定义结束地图
SwitchMap.nOptionalMap =  tonumber(nOptionalMap)  -- 1为自定义切图,2GM配置表切图
local bFlag = true
local RunMap = {}
-- 读取GM配置表的内容
local tbGmMapTable = {}
for i = 1, g_tTable.MapList:GetRowCount() do
    local tRow = g_tTable.MapList:GetRow(i)
    table.insert(tbGmMapTable,tRow.nID)
end
local list_Map = {} --地图
local nCurrentMap = SwitchMap.nMapStart --当前地图
local nMapEnd = SwitchMap.nMapEnd   -- 结束地图
local function checkstr(str)
	if not string.find(str,",") then
		str = str..",100,100,100"
	end
	return str
end
--处理未知弹窗
Timer.AddCycle(SearchPanel.tbTips,1,SearchPanel.DealWithTips)
-- 初始化自定义地图
local function InitSwitchMap()
    local mapIni = Ini.Open(SearchPanel.szCurrentInterfacePath.."Config_SwitchMap.ini")
    if mapIni == nil then
        return nil
    else
        local MapIDNum =mapIni:ReadString("Count", "MapIDNum", "")
        for i = 1, tonumber(MapIDNum) do
            local szMapPosition = mapIni:ReadString("MapID", tostring(i), "")
            if szMapPosition == "" or szMapPosition == nil then
                AutoTestLog.Log("[SwitchMap]",tostring(i).."-->szMapPosition is nil")
            else
                local str = checkstr(szMapPosition)
                table.insert(list_Map,str)
                AutoTestLog.Log("[SwitchMap]","Success Load: "..str)
            end
        end
    end
end

-- GM配置表切换地图 地图ID
local function GmMapSwitch(nMapID)
    local szCmd = string.format("/gm player.Transmission(%s)", tostring(nMapID))
    pcall(function ()
        SearchPanel.RunCommand(szCmd)
    end)
    AutoTestLog.Log("[SwitchMap]","Success ReplaceMapID: "..tostring(nMapID))
end
-- 自定义切换地图
local function MapSwitch(_Postition)
    local szCmd = string.format("/gm player.SwitchMap(%s)", tostring(_Postition))
    pcall(function ()
        SearchPanel.RunCommand(szCmd)
    end)
    AutoTestLog.Log("[SwitchMap]","Success ReplacePostition: ".._Postition)
end

-----init----------------
local Init = BaseState:New("Init")
function Init:OnEnter()

end

function Init:OnUpdate()
    if SwitchMap.nOptionalMap == 1 then
        InitSwitchMap()
    end
    fsm:Switch("ReplaceMap")
end

function Init:OnLeave()                               

end

-- 结束切图
function SwitchMap.Stop()
    Timer.DelAllTimer(SwitchMap)
    bFlag = true
    AutoTestLog.INFO("[SwitchMap] SwitchMap Stop")
end

--切地图
local ReplaceMap = BaseState:New("ReplaceMap")
local nReplaceMapStartTime = 0
local nReplaceMapNextTime = SwitchMap.nSwitchMapSleepTime
function ReplaceMap:OnEnter()
    nReplaceMapStartTime = GetTickCount()
end

function ReplaceMap:OnUpdate()
    if GetTickCount()-nReplaceMapStartTime >= nReplaceMapNextTime*1000 then
        -- 自定义切图结束和GM切图结束
        if SwitchMap.nOptionalMap == 1 then
            if nCurrentMap == nMapEnd + 1 then
                SwitchMap.Stop()
            end
        else
            if nCurrentMap == #tbGmMapTable then
                SwitchMap.Stop()
            end
            return
        end
        -- 执行切图
        if SwitchMap.nOptionalMap == 1 then
            MapSwitch(list_Map[nCurrentMap])
        else
            GmMapSwitch(tbGmMapTable[nCurrentMap])
        end
        if SwitchMap.bVideoSwitch == 1 then
            fsm:Switch("ReplaceVideo")
        else
            nCurrentMap = nCurrentMap + 1
        end
        nReplaceMapStartTime = GetTickCount()
    end
end

function ReplaceMap:OnLeave()
    nCurrentMap = nCurrentMap + 1
end

--切画质
local ReplaceVideo = BaseState:New("ReplaceVideo")
-- 根据画质切画质
local list_Video={}
-- 切画质时间
local nVideoStartTimer = 0
local nVideoNextTimer = SwitchMap.nVideoSleepTime
local nVideoLine = 1
local nVideoCountLine = 1
-- 切画质接口
function VideoSwitch(nVideo)
    if SearchPanel.CheckDevicesQuality(nVideo) then
        QualityMgr.SetQualityByType(nVideo)
        -- 记录当前切换的画质
        AutoTestLog.Log("SwitchMap ReplaceVideo:",tostring(list_Video[nVideoLine]))
    end
end
-- 低->中->高->中->低
-- 画质顺序
function VideoOrder()
    if nVideoCountLine >= #list_Video then
        nVideoLine = nVideoLine - 1
    else
        nVideoLine = nVideoLine + 1
    end
    nVideoCountLine = nVideoCountLine + 1
end

function ReplaceVideo:OnEnter()
    nVideoStartTimer = GetTickCount()
end

function ReplaceVideo:OnUpdate()
    if GetTickCount()-nVideoStartTimer>= nVideoNextTimer*1000 then
        if nVideoCountLine == #list_Video*2 then
            fsm:Switch("ReplaceMap")
            return
        end
        -- 切换画质
        VideoSwitch(list_Video[nVideoLine])
        VideoOrder()
        nVideoStartTimer = GetTickCount()
    end
end

function ReplaceVideo:OnLeave()
    -- 重置参数
    nVideoLine = 1
    nVideoCountLine = 1
end


-- 切图切画质帧更新函数
function SwitchMap.FrameUpdate()
    if not SearchPanel.IsFromLoadingEnterGame() then
        nReplaceMapStartTime = GetTickCount()
        return
    end
    fsm.curState:OnUpdate()
end


function SwitchMap.Start()
    if not SwitchMap.bSwitch then
       return
    end
    list_Video = SearchPanel.GetDevicesOptionList()
    fsm = FsmMachine:New()
    fsm:AddState(ReplaceVideo)
    fsm:AddState(ReplaceMap)
    fsm:AddInitState(Init)
    Timer.AddFrameCycle(SwitchMap,1,function ()
        SwitchMap.FrameUpdate()
    end)
end

--读取tab的内容 
local list_RunMapCMD = {}
local list_RunMapTime = {}
local tbRunMapData=SearchPanel.LoadRunMapFile(SearchPanel.szCurrentInterfacePath.."RunMap.tab",2)
list_RunMapCMD = tbRunMapData[1]
list_RunMapTime = tbRunMapData[2]
local nCurrentTime = 0
local nNextTime=tonumber(30)
local nCurrentStep=1

-- 切图的前后置操作 这部分实现模块化后直接去除
function RunMap.FrameUpdate()
    if not SearchPanel.IsFromLoadingEnterGame() then
        return
    end
    if bFlag and GetTickCount()-nCurrentTime>nNextTime*1000 then
        if nCurrentStep==#list_RunMapCMD then
            bFlag=false
        end
        --切图前后置操作
        local szCmd=list_RunMapCMD[nCurrentStep]
        local nTime=tonumber(list_RunMapTime[nCurrentStep])
        AutoTestLog.INFO(szCmd)
        pcall(function ()
            SearchPanel.RunCommand(szCmd)
        end)
        AutoTestLog.INFO(szCmd.."===ok")
        OutputMessage("MSG_SYS",szCmd)
        nNextTime=nTime
        --切图操作
        if string.find(szCmd,"SwitchMap_start") then
            --启动切图帧更新函数
            SwitchMap.Start()
            bFlag = false
        end
		nCurrentTime=GetTickCount()
        nCurrentStep=nCurrentStep+1 
    end
end

Timer.AddFrameCycle(RunMap,1,function ()
    RunMap.FrameUpdate()
end)

return SwitchMap