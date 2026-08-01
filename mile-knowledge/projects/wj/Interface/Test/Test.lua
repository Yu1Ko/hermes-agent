-- local player = GetClientPlayer() -- 客户端状态

-- player.nX,player.nY,player.nZ --角色人物坐标


-- TurnTo() -- 人物转向

-- TurnToFaceDirection() --背身调节

-- Timer.AddFrameCycle(BasicRunMap,1,function ()
--     FrameUpdate()
-- end)
local d = {77883, 67767, 1070208}

Test = {}


-- 当前位置
function PlayerZuoBiao()
    local player = GetClientPlayer()
    return player.nX,player.nY
end


-- 判断是否到下个位置坐标
local function JudgeArrive(nPlayerX,nPlayerY,nTargetX,nTargetY)
    local nVectorX=nTargetX-nPlayerX
    local nVectorY=nTargetY-nPlayerY
    if nVectorX*nVectorX+nVectorY*nVectorY<=800 then
        return true
    else
        return false
    end
end


-- 调整视角
local function AdjustDirection(nPlayerX,nPlayerY,nTargetX,nTargetY)
    local nVectorX =  nTargetX - nPlayerX
    local nVectorY =  nTargetY - nPlayerY

    local nTurnto = GetLogicDirection(nVectorX,nVectorY)
    SearchPanel.MyExecuteScriptCommand("TurnTo("..tostring(nTurnto)..")")
end

local bFlag = false
-- 帧函数内容
function Test.FrameUpdate()
    if not bFlag then
        SkillMgr.AutoRun(true)
        bFlag = true
        return
    end
    local player = GetClientPlayer()
    local nX,nY = player.nX,player.nY
    print(JudgeArrive(nX,nY,d[1],d[2]))
    if JudgeArrive(nX,nY,d[1],d[2]) then
        SkillMgr.AutoRun(false)
    else
        AdjustDirection(nX,nY,d[1],d[2])
    end
end

function Test.Start()
    Timer.AddCycle(Test,1,function ()
        Test.FrameUpdate()
    end)
end