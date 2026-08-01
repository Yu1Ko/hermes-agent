SwitchRobot = {}
-- 暂时写死
SwitchRobot.nMapID1 = 15
SwitchRobot.nX1 = 40011
SwitchRobot.nY1 = 93355
SwitchRobot.nZ1 = 1061632
SwitchRobot.nMapID2 = 332
SwitchRobot.nX2 = 87860
SwitchRobot.nY2 = 98231
SwitchRobot.nZ2 = 1048832
SwitchRobot.nMapCount = 1 -- 所在地图
local bFlag = true
function SwitchRobot.SetMapData()
    -- 写死暂时不动
end

-----init----------------
local Init = BaseState:New("Init")
function Init:OnEnter()

end

function Init:OnUpdate()
    fsm:Switch("ReplaceMap")
end

function Init:OnLeave()                               

end



-- 自定义切换地图
function SwitchRobot.MapSwitch()
    if SwitchRobot.nMapCount == 1 then
        local szCmd = string.format("/gm player.SwitchMap(%s)", tostring(SwitchRobot.nMapID1..","..SwitchRobot.nX1..","..SwitchRobot.nY1..","..SwitchRobot.nZ1))
        print(szCmd)
        pcall(function ()
            SearchPanel.RunCommand(szCmd)
        end)
        SwitchRobot.nMapCount = SwitchRobot.nMapCount + 1
    else
        local szCmd = string.format("/gm player.SwitchMap(%s)", tostring(SwitchRobot.nMapID2..","..SwitchRobot.nX2..","..SwitchRobot.nY2..","..SwitchRobot.nZ2))
        print(szCmd)
        pcall(function ()
            SearchPanel.RunCommand(szCmd)
        end)
        SwitchRobot.nMapCount = 1
    end
end



local nOperation = 1
local Init = BaseState:New("Init")
function Init:OnEnter()

end

function Init:OnUpdate()
    fsm:Switch("PlayerSwicth")
end

function Init:OnLeave()                               

end

-- 召唤机器人
local SummoningRobot = BaseState:New("SummoningRobot")
function SummoningRobot:OnEnter()

end

function SummoningRobot:OnUpdate()
    RobotControl.CMD("TeleportRobot")
    fsm:Switch("Sleep")
end

function SummoningRobot:OnLeave()                  
    nOperation = 1
end

-- 切换地图
local PlayerSwicth = BaseState:New("PlayerSwicth")
function PlayerSwicth:OnEnter()

end

function PlayerSwicth:OnUpdate()
    print("-----------")
    SwitchRobot.MapSwitch()
    fsm:Switch("Sleep")
end

function PlayerSwicth:OnLeave()                        
    nOperation = 2
end

-- Sleep
local nSleepStartTime = 0
local nSleepCurrentTime=0
Sleep = BaseState:New("Sleep")
function  Sleep:OnEnter()
    -- 进入状态之前现重置睡眠时间
    if nOperation ==1  then
        nSleepCurrentTime = 30 -- 操作1秒数
    elseif nOperation ==2 then
        nSleepCurrentTime = 5 -- 操作2秒数
    end
    nSleepStartTime=GetTickCount()
end

function Sleep:OnUpdate()
    if GetTickCount()-nSleepStartTime>nSleepCurrentTime*1000 then
        if nOperation ==1  then
            fsm:Switch("PlayerSwicth")
        elseif nOperation ==2 then
            fsm:Switch("SummoningRobot")
        end
    end
end

function  Sleep:OnLeave()

end


-- 切图切画质帧更新函数
function SwitchRobot.FrameUpdate()
    if not SearchPanel.IsFromLoadingEnterGame() then
        return
    end
    fsm.curState:OnUpdate()
end




function SwitchRobot.Start()
    fsm = FsmMachine:New()
    fsm:AddState(SummoningRobot)
    fsm:AddState(PlayerSwicth)
    fsm:AddState(Sleep)
    fsm:AddInitState(Init)
    Timer.AddFrameCycle(SwitchRobot,1,function ()
        SwitchRobot.FrameUpdate()
    end)
end



--读取tab的内容 
local RunMap = {}
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
        if string.find(szCmd,"switchmap_start") then
            --启动切图帧更新函数
            SwitchRobot.Start()
            bFlag = false
        end
		nCurrentTime=GetTickCount()
        nCurrentStep=nCurrentStep+1 
    end
end

Timer.AddFrameCycle(RunMap,1,function ()
    RunMap.FrameUpdate()
end)

return SwitchRobot

