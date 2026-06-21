Fabric={}
local RunMap = {}
local bFlag =true

-- 默认地图
local SwitchMapList ={
    "15,72062, 30521, 1094784",
    "7,24839, 13024, 1159296",
    "6,63541, 66207, 1053440",
    "17,5569, 15660, 1052672"
}
--开启布料接口
function Fabric.StartVideo()
    QualityMgr.ModifyCurQuality("bEnableApexClothing_new",true,false);Event.Dispatch(EventType.OnQualitySettingChange);rlcmd("enable apex clothing 1")
end

local function MapSwitch(_Postition)
    local szCmd = string.format("/gm player.SwitchMap(%s)", tostring(_Postition))
    pcall(function ()
        SearchPanel.RunCommand(szCmd)
        SearchPanel.RunCommand("/gm player.Revive()")
    end)
end
-----init----------------
local Init = BaseState:New("Init")
function Init:OnEnter()

end

function Init:OnUpdate()
    fsm:Switch("Player")
end

function Init:OnLeave()                               

end

local nPlayerLine = 1 --操作
local nPlayerTime = 0
local nPlayerNextTime = 5
local Player = BaseState:New("Player")
function Player:OnEnter()
    nPlayerTime = GetTickCount()
end
function Player:OnUpdate()
    if GetTickCount()-nPlayerTime>nPlayerNextTime*1000 then
        if nPlayerLine == 1 then
            UIMgr.Open(51)
        end
        if nPlayerLine == 2 then
            CameraMgr.Zoom(1)
        end
        if nPlayerLine == 3  then
            fsm:Switch("Sleep")
            return
        end
        nPlayerTime=GetTickCount()
        nPlayerLine= nPlayerLine + 1
    end
end

function Player:OnLeave()                               
    nPlayerLine = 1
end

-- Sleep
local nSleepStartTime = 0
local nSleepCurrentTime = 10
-- 设置时间
function Fabric.SetSleepTime(nSleepCount)
    nSleepCurrentTime=tonumber(nSleepCount)
end
Sleep = BaseState:New("Sleep")
function  Sleep:OnEnter()
    -- 进入状态之前现重置睡眠时间
    nSleepStartTime=GetTickCount()
end

function  Sleep:OnUpdate()
    -- 等待完成后开始切图
    if GetTickCount()-nSleepStartTime>nSleepCurrentTime*1000 then
        fsm:Switch("SwitchMap")
    end
end

function  Sleep:OnLeave()

end




local SwitchMap = BaseState:New("SwitchMap")
local SwitchMapCount = 2 -- 默认2次
local SwitchMapLine = 1
local SwitchMapCountLine = 0
-- 重复遍历的次数
function Fabric.SetMapCount(nCount)
    SwitchMapCount = tonumber(nCount)
end
function SwitchMap:OnEnter()

end

function SwitchMap:OnUpdate()
    if SwitchMapLine == #SwitchMapList+1 then
        SwitchMapCountLine = SwitchMapCountLine + 1
        print("abc")
        print(SwitchMapCountLine,SwitchMapCount)
        if SwitchMapCountLine == SwitchMapCount  then
            Timer.DelAllTimer(Fabric)
            bFlag = true
        else
            SwitchMapLine = 1
            fsm:Switch("Player")
        end
    else
        MapSwitch(SwitchMapList[SwitchMapLine])
        SwitchMapLine=SwitchMapLine+1
        fsm:Switch("Player")
    end
end

function SwitchMap:OnLeave()                               

end




function Fabric.FrameUpdate()
    if not SearchPanel.IsFromLoadingEnterGame() then
        return
    end
    fsm.curState:OnUpdate()
end



function Fabric.Start()
    fsm = FsmMachine:New()
    fsm:AddState(Sleep)
    fsm:AddState(Player)
    fsm:AddState(SwitchMap)
    fsm:AddInitState(Init)
    Timer.AddFrameCycle(Fabric,1,function ()
        Fabric.FrameUpdate()
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
        if string.find(szCmd,"Fabric_start") then
            --更新函数
            Fabric.Start()
            bFlag = false
        end
		nCurrentTime=GetTickCount()
        nCurrentStep=nCurrentStep+1 
    end
end

Timer.AddFrameCycle(RunMap,1,function ()
    RunMap.FrameUpdate()
end)