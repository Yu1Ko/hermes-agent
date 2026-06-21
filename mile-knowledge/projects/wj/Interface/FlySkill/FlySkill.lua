AutoTestLog.Log("FlySkill","FlySkill imported")
FlySkill = {}
local Role = {}
local RunMap = {}
FlySkill.bSwitch = true
FlySkill.Status = 2  -- 当前角色的状态
local list_RunMapCMD = {}                       -- CMD文件
local list_RunMapTime = {}                      -- 文件时间
local nStartTime = 0                            -- 初始化时间
local tTargetPointTable = {}                    -- 目标点信息表
local nLine = 1                                 -- 初始当前行
local nRowcount = 0                             -- 初始化总点数
SearchPanel.RemoveFile(SearchPanel.szRunMapResultPath.."perfeye_start")
SearchPanel.RemoveFile(SearchPanel.szRunMapResultPath.."perfeye_stop")
SearchPanel.RemoveFile(SearchPanel.szRunMapResultPath.."FlySkill_Start")
SearchPanel.RemoveFile(SearchPanel.szRunMapResultPath.."ExitGame")
local bFlag = true

-- 角色人物坐标
FlySkill.nPlayerX = 0
FlySkill.nPlayerY = 0
FlySkill.nPlayerZ = 0
FlySkill.bPlayerStart = false

-- 轻功下一个坐标点
FlySkill.nNext_X = 0
FlySkill.nNext_Y = 0
FlySkill.nNext_Z = 0

-- 轻功
FlySkill.nJumpLine = 1  -- 当前轻功跳跃的段数
FlySkill.nJumpStartTime = 0  -- 每段轻功跳跃的时间
FlySkill.nJumpNextTime = 0  -- 每段轻功跳跃的时间
FlySkill.nJumpCount = 0 -- 需要跳跃的总数

-- 调整转向时间
FlySkill.nTurnNextTime = 2  -- 默认两秒后转向
FlySkill.nTurnStartTime = 0

-- 位移坐标时间
FlySkill.nSetPosNextTime = 2  -- 默认两秒后转向
FlySkill.nSetPosStartTime = 0

-- RunMap文件提取跑图坐标
SearchPanel.tbModule['AutoLogin'].SetAutoLoginInfo(nil,RandomString(8),'纯阳','成男')	-- 设置轻功角色
local tbRunMapData=SearchPanel.LoadRunMapFile(SearchPanel.szCurrentInterfacePath.."RunMap.tab",12)
local tbRunMapDataCount = #tbRunMapData[1]
local nMapPositioningStart = 0 -- 地图始
local nMapPositioningEnd = 0 -- 地图末
local function GetPointsRunMap()
    local strInfo=''
    for i=1,#tbRunMapData[1] do
        strInfo=tbRunMapData[1][i]:sub(1,1)
        if strInfo=='/' then
            table.insert(list_RunMapCMD,tbRunMapData[1][i])
            table.insert(list_RunMapTime,tbRunMapData[2][i])
            tbRunMapDataCount = tbRunMapDataCount-1
        elseif strInfo=='x' then
            nMapPositioningStart = i+1
        else

        end
    end
    nMapPositioningEnd = tbRunMapDataCount+nMapPositioningStart-2
end

GetPointsRunMap()                                                                  -- 初始化
local function GetPointsFile()                                             -- 获取目标点数据
    nRowcount = nMapPositioningEnd-nMapPositioningStart+1
    -- 记录地图始末 
    AutoTestLog.INFO(nMapPositioningStart..nMapPositioningEnd)
    for i=nMapPositioningStart,nMapPositioningEnd do
        table.insert(tTargetPointTable,{
            x=tonumber(tbRunMapData[1][i]),
            y=tonumber(tbRunMapData[2][i]),
            z=tonumber(tbRunMapData[3][i]),
            stay=tonumber(tbRunMapData[4][i]),
            mapid=tonumber(tbRunMapData[5][i]),
            Jump1=tonumber(tbRunMapData[7][i]),
            Jump2=tonumber(tbRunMapData[8][i]),
            Jump3=tonumber(tbRunMapData[9][i]),
            Jump4=tonumber(tbRunMapData[10][i]),
            Jump5=tonumber(tbRunMapData[11][i])
        })
    end
end
GetPointsFile()

-----init----------------
local Init = BaseState:New("Init")
function Init:OnEnter()

end

function Init:OnUpdate()
    fsm:Switch("Sleep")
end

function Init:OnLeave()                               

end




-----Sleep----------------
local Sleep = BaseState:New("Sleep")
local nStartTime = 0
local nNextTime=tonumber(5) -- 下一次等待时间 没有默认为5秒一次
-- 每进行一个状态 进行一次睡眠
function Sleep:OnEnter()
    nStartTime = GetTickCount()
end

function Sleep:OnUpdate()
    -- 判断点数是否结束
    if nLine == nRowcount +1 then
        -- 结束轻功
        Timer.DelAllTimer(FlySkill)
        bFlag = true
    end
    local player = GetClientPlayer()
    -- 是否落地
    if player.nJumpCount == 0 then
        if GetTickCount()-nStartTime >= nNextTime*1000 then
            if FlySkill.Status == 1 then
                fsm:Switch("FlyStatus")
            elseif FlySkill.Status == 2 then
                fsm:Switch("PlayerTurn")
            elseif FlySkill.Status == 3 then
                fsm:Switch("PlayerSetPos")
            else
                AutoTestLog.INFO("FlySkill Error")
            end
        end
    end
end

function Sleep:OnLeave()                               

end



-----FlyStatus----------------
-- 重置轻功跳跃时间
local tbJumpTimer
local nStay -- 轻功停留的时间
function JumpDataReset()
    local tbJumpData = tTargetPointTable[nLine]
    tbJumpTimer = {
        tonumber(tbJumpData["Jump1"]),
        tonumber(tbJumpData["Jump2"]),
        tonumber(tbJumpData["Jump3"]),
        tonumber(tbJumpData["Jump4"]),
        tonumber(tbJumpData["Jump5"]),
    }
    nStay = tonumber(tbJumpData["stay"])
    FlySkill.nJumpCount= #tbJumpTimer
    FlySkill.nJumpLine = 1
    FlySkill.nJumpNextTime = tbJumpTimer[FlySkill.nJumpLine]
end

local FlyStatus = BaseState:New("FlyStatus")
function FlyStatus:OnEnter()
    -- 启动轻功
    SearchPanel.MyExecuteScriptCommand("FuncSlotMgr.tbCommands.StartSprint()")
    JumpDataReset()
    FlySkill.nJumpStartTime = GetTickCount()
end

function FlyStatus:OnUpdate()
    -- 判断跳跃时间是否结束
    if FlySkill.nJumpLine == FlySkill.nJumpCount+1 then
        SearchPanel.MyExecuteScriptCommand("FuncSlotMgr.tbCommands.EndSprint()")
        fsm:Switch("Sleep")
        return
    end
    if GetTickCount()-FlySkill.nJumpStartTime >= FlySkill.nJumpNextTime*1000 then
        -- 跳跃
        Jump()
        FlySkill.nJumpLine = FlySkill.nJumpLine + 1
        FlySkill.nJumpNextTime = tbJumpTimer[FlySkill.nJumpLine]
        FlySkill.nJumpStartTime = GetTickCount()
    end
end

function FlyStatus:OnLeave()                   
    nLine = nLine + 1
    -- 执行下次等待时间
    nNextTime=5
    FlySkill.Status = 3
end


-----PlayerTurn----------------
local PlayerTurn = BaseState:New("PlayerTurn")
function PlayerTurn:OnEnter()
    
end

function PlayerTurn:OnUpdate()
    -- 根据角色坐标来进行调整
    -- 角色转向后等待
    if not FlySkill.bPlayerStart then
        local player = GetClientPlayer()                                               -- 获取玩家当前坐标
        FlySkill.nPlayerX = player.nX
        FlySkill.nPlayerY = player.nY
        FlySkill.nPlayerZ = player.nZ
        local tLine = tTargetPointTable[nLine]                                         -- 取得第i行点信息
        -- 获取下一个目标点
        FlySkill.nNext_X = tLine["x"]
        FlySkill.nNext_Y = tLine["y"]
        FlySkill.nNext_Z = tLine["z"]
        local vector_x =  FlySkill.nNext_X - FlySkill.nPlayerX
        local vector_y =  FlySkill.nNext_Y - FlySkill.nPlayerY
        local nTurnto = GetLogicDirection(vector_x,vector_y)
        SearchPanel.MyExecuteScriptCommand("TurnTo("..tostring(nTurnto)..")")                       -- 调整当前面部朝向
        FlySkill.bPlayerStart = true
        FlySkill.nTurnStartTime = GetTickCount()
    end
    if GetTickCount() - FlySkill.nTurnStartTime >= FlySkill.nTurnNextTime*1000 then
        -- 调整面板朝向
        TurnToFaceDirection()
        -- 执行下个状态
        fsm:Switch("Sleep")
    end
end

function PlayerTurn:OnLeave()                              
    FlySkill.bPlayerStart =false
    FlySkill.Status = 1
end


local PlayerSetPos = BaseState:New("PlayerSetPos")
function PlayerSetPos:OnEnter()
    FlySkill.nSetPosStartTime = GetTickCount()
end

function PlayerSetPos:OnUpdate()
    if GetTickCount()-FlySkill.nSetPosStartTime> FlySkill.nSetPosNextTime*1000 then
        SendGMCommand("player.SetPosition("..tostring(FlySkill.nNext_X)..","..tostring(FlySkill.nNext_Y)..","..tostring(FlySkill.nNext_Z)..")")
        fsm:Switch("Sleep")
    end
end

function PlayerSetPos:OnLeave()                          
    nNextTime=nStay
    FlySkill.Status = 2
end





-- 切图切画质帧更新函数
function FlySkill.FrameUpdate()
    if not SearchPanel.IsFromLoadingEnterGame() then
        return
    end
    fsm.curState:OnUpdate()
end


function FlySkill.Start()
    if not FlySkill.bSwitch then
        return
    end
    fsm = FsmMachine:New()
    fsm:AddState(FlyStatus)
    fsm:AddState(PlayerTurn)
    fsm:AddState(PlayerSetPos)
    fsm:AddState(Sleep)
    fsm:AddInitState(Init)
    Timer.AddFrameCycle(FlySkill,1,function ()
        FlySkill.FrameUpdate()
    end)
end


local nCurrentTime = 0
local nNextTime=tonumber(20)
local nCurrentStep=1
local function RunMapFrameUpdate()
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
        pcall(function ()
            SearchPanel.RunCommand(szCmd)
        end)
        AutoTestLog.INFO(szCmd.."===ok")
        OutputMessage("MSG_SYS",szCmd)
        nNextTime=nTime
        if string.find(szCmd,"perfeye_start") then
            SearchPanel.bPerfeye_Start=true
        end
        if string.find(szCmd,"FlySkill_Start") then
            --启动跑图帧更新函数
            FlySkill.Start()
            bFlag = false
        end
        if string.find(szCmd,"perfeye_stop") then
            SearchPanel.bPerfeye_Stop=true
        end
        nCurrentTime=GetTickCount()
        nCurrentStep=nCurrentStep+1
    end
end

Timer.AddFrameCycle(RunMap,1,function()
    RunMapFrameUpdate()
end)

-- 人物可能掉落死亡（当前每段轻功都会执行完待定）
function Role.Revive()
    local player=GetClientPlayer()
    if not player then
        return
    end
    if player.nMoveState == 16 then
        SearchPanel.RunCommand("/gm player.Revive()")
    end
end
-- 人物死亡后复活
Timer.AddCycle(Role, 1, function ()
    Role.Revive()
end)

AutoTestLog.Log("FlySkill","FlySkill End")