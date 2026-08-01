local FlySkill = {}
local Role = {}
local RunMap = {}
local list_RunMapCMD = {}                       -- CMD文件
local list_RunMapTime = {}                      -- 文件时间
local nStartTime = 0                            -- 初始化时间
local tTargetPointTable = {}                    -- 目标点信息表
local nLine = 1                                 -- 初始当前行
local nRowcount = 0                             -- 初始化总点数
local bFlyStart = false -- 初始化轻功启动
FlySkill.bSwitch = true
-- RunMap文件提取跑图坐标
local tbRunMapData=SearchPanel.LoadRunMapFile(SearchPanel.szCurrentInterfacePath.."FlySkill/FlySkillTask.tab",12)
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
    LOG.INFO(nMapPositioningStart,nMapPositioningEnd)
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

local stay                  -- 原地等待时间
local bJump = true          -- 跳跃状态
local bJumpTimer = false    -- 读取每段跳跃时间
local tLine1                -- 当前坐标点
local current_x             -- 当前坐标点x
local current_y             -- 当前坐标点y
local tLine2                -- 下个坐标点
local next_x                -- 下个坐标点x
local next_y                -- 下个坐标点y
local next_z
local bTurnto = false   -- 调整方向
local function AdjustDirection()                                                   -- 调整方向
    local player = GetClientPlayer()                                               -- 获取玩家当前坐标
    current_x = player.nX
    current_y = player.nY
    tLine2 = tTargetPointTable[nLine]                                         -- 取得第i行点信息
    next_x = tLine2["x"]
    next_y = tLine2["y"]
    next_z = tLine2["z"]
    local vector_x =  next_x - current_x
    local vector_y =  next_y - current_y
    local turnto = GetLogicDirection(vector_x,vector_y)                                -- 计算朝向
    LOG.INFO(string.format("[RunMapByPoint] TurnTo {%d}",turnto))
    SearchPanel.MyExecuteScriptCommand("TurnTo("..tostring(turnto)..")")                       -- 调整当前面部朝向
    TurnToFaceDirection()
end

local tbJumpTimer={}    -- 轻功每段的跳跃时间
local nJumpStartTime = 0
local bisStop = false   -- 是否为原地停止状态
local tbLine  -- 当前坐标数据
local nJumpLine = 1     -- 当前轻功段数
local FlySkillCount = 1 -- 轻功的总次数
local nFlySkillLine = 1 -- 当前执行轻功行数
local bJumpCount = false
local nJumpCountStartTime = 0
local function RunNextPoint()
    -- 判断玩家的状态是
    if not bJumpTimer then
        SearchPanel.MyExecuteScriptCommand("FuncSlotMgr.tbCommands.EndSprint()")
        nLine = nLine + 1
        tbLine = tTargetPointTable[nLine]
        tbJumpTimer = {tonumber(tbLine["Jump1"]),tonumber(tbLine["Jump2"]),tonumber(tbLine["Jump3"]),tonumber(tbLine["Jump4"]),tonumber(tbLine["Jump5"])}
        bJumpTimer = true
        if nLine ~= 1 then
            stay = tonumber(tbLine["stay"])
        end
        FlySkillCount = tbLine["FlyCount"]
        bJump = false
    end
    if stay == 0 then
        SearchPanel.MyExecuteScriptCommand("FuncSlotMgr.tbCommands.StartSprint()")
        bJump = true
        bTurnto = false
        nJumpStartTime = GetTickCount()
        nJumpLine = 1
    elseif stay>0 then
        if GetClientPlayer().nJumpCount == 0  then
            if GetTickCount() - nJumpCountStartTime >= 5*1000 then
                if not bJumpCount then
                    bJumpCount = true
                    nJumpCountStartTime = GetTickCount()
                    return
                end
                if not bisStop then
                    -- 直接进行强制移动
                    SendGMCommand("player.SetPosition("..tostring(next_x)..","..tostring(next_y)..","..tostring(next_z)..")")
                    nStartTime =  GetTickCount()
                    bisStop = true                                                 -- 标记开始
                end
                if GetTickCount() - nStartTime >= stay*1000 then                          -- 原地停 stay 秒
                    SearchPanel.MyExecuteScriptCommand("FuncSlotMgr.tbCommands.StartSprint()")                          -- 往下一个目标点跑
                    nJumpLine = 1
                    bJump = true
                    bTurnto = false
                    bisStop = false
                    bJumpCount= false
                    bJumpTimer = false
                    if nFlySkillLine == FlySkillCount then
                        nFlySkillLine = 1
                    else
                        nFlySkillLine = nFlySkillLine + 1
                    end
                    nJumpStartTime = GetTickCount()
                end
            end
        end
    end
end

local bFlag = true
local bFlySkill = false
local nFlySkillStartTimer = 0
function FlySkill.FrameUpdate()
    -- 落地后再停止进行采集
    if nLine == nRowcount +1 then
        if GetClientPlayer().nJumpCount == 0 then
            if not bFlySkill  then
                nFlySkillStartTimer = GetTickCount()
                SearchPanel.MyExecuteScriptCommand("FuncSlotMgr.tbCommands.EndSprint()")
                bFlySkill = true
            end
            if GetTickCount() - nFlySkillStartTimer >= 10*1000 then
                -- 结束轻功
                Timer.DelAllTimer(FlySkill)
                FlySkill.bSwitch = false
            end
        end
        return
    end
    -- 调整方向先
    if not bTurnto then
        AdjustDirection()
        bTurnto = true
        return
    end
    -- 初始化启动轻功
    if not bFlyStart then
        tbLine = tTargetPointTable[nLine]
        tbJumpTimer = {tonumber(tbLine["Jump1"]),tonumber(tbLine["Jump2"]),tonumber(tbLine["Jump3"]),tonumber(tbLine["Jump4"]),tonumber(tbLine["Jump5"])}
        stay = tonumber(tbLine["stay"])
        SearchPanel.MyExecuteScriptCommand("FuncSlotMgr.tbCommands.StartSprint()")
        bFlyStart = true
        return
    end
    TurnToFaceDirection()
    -- 跳跃部分
    if nJumpLine == 6 then
        RunNextPoint()
        return
    end
    if not bisStop then
        if bJump then
            -- 不同跳跃时间
            if tbJumpTimer[nJumpLine] == 0 then
                nJumpLine = 6
                return
            end
            if GetTickCount() - nJumpStartTime >= tbJumpTimer[nJumpLine]*1000 then 
                Jump()
                nJumpLine = nJumpLine + 1
                nJumpStartTime = GetTickCount()
            end
        end
    end
end

function FlySkill.Start()
    Timer.AddFrameCycle(FlySkill,1,function ()
        FlySkill.FrameUpdate()
    end)
end

-- 人物可能掉落死亡（当前每段轻功都会执行完待定）
function Role.Revive()
    local player=GetClientPlayer()
    if not player then
        return
    end
    if player.nMoveState == 16 then
        SearchPanel.RunCommand("/gm player.Revive()")
    end
    if UIMgr.IsViewOpened(VIEW_ID.PanelTutorialLite) then
        UIMgr.Close(VIEW_ID.PanelTutorialLite)
    end
end


FlySkillStart = {}
FlySkillStart.bSwitch = false
function FlySkillStart.FrameUpdate()
    if not FlySkill.bSwitch then
        Timer.DelAllTimer(FlySkillStart)
        Timer.DelAllTimer(Role)
        StabilityController.bFlag = true
    end
    if FlySkillStart.bSwitch then
        if FlySkill.bSwitch then
            FlySkill.Start()
            -- 人物死亡后复活
            Timer.AddCycle(Role, 1, function ()
                Role.Revive()
            end)
            FlySkillStart.bSwitch = false
        end
    end
end

Timer.AddCycle(FlySkillStart,1,function ()
    FlySkillStart.FrameUpdate()
end)
