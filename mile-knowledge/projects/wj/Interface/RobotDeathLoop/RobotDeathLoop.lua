AutoTestLog.Log("RobotDeathLoop", "RobotDeathLoop Start")

RobotDeathLoop = {}
RobotDeathLoop.bSwitch = true
RobotDeathLoop.nCycleCount = 0
RobotDeathLoop.nMaxCycles = 360
RobotDeathLoop.nInterval = 10
RobotDeathLoop.timerDeathLoop = nil

-- ===== RunMap 命令解析器 =====
local RunMap = {}
local bFlag = true
local pCurrentTime = 0
local nNextTime = 3
local nCurrentStep = 1
local tbRunMapData = SearchPanel.LoadRunMapFile(SearchPanel.szCurrentInterfacePath.."RunMap.tab", 2)
local list_RunMapCMD = tbRunMapData[1]
local list_RunMapTime = tbRunMapData[2]

local function RunMapFrameUpdate()
    local player = GetClientPlayer()
    if not player then return end
    if bFlag and GetTickCount() - pCurrentTime > nNextTime * 1000 then
        if nCurrentStep > #list_RunMapCMD then
            bFlag = false
            return
        end
        local szCmd = list_RunMapCMD[nCurrentStep]
        local nTime = tonumber(list_RunMapTime[nCurrentStep])
        if szCmd and szCmd:sub(1, 1) == "/" then
            SearchPanel.RunCommand(szCmd)
            AutoTestLog.INFO("RobotDeathLoop: " .. szCmd .. " === ok")
        end
        nNextTime = nTime
        pCurrentTime = GetTickCount()
        nCurrentStep = nCurrentStep + 1
    end
end

Timer.AddFrameCycle(RunMap, 1, function()
    RunMapFrameUpdate()
end)

-- ===== 死亡循环：每10秒先复活再自杀 =====
function RobotDeathLoop.Start()
    if not RobotDeathLoop.bSwitch then return end
    AutoTestLog.Log("RobotDeathLoop", "开始复活/自杀循环 " .. tostring(RobotDeathLoop.nMaxCycles) .. "轮 间隔" .. tostring(RobotDeathLoop.nInterval) .. "秒")
    RobotDeathLoop.StartDeathCycle()
end

function RobotDeathLoop.StartDeathCycle()
    RobotDeathLoop.timerDeathLoop = Timer.AddCycle(RobotDeathLoop, RobotDeathLoop.nInterval, function()
        if not RobotDeathLoop.bSwitch then
            RobotDeathLoop.StopCycle()
            return
        end

        RobotDeathLoop.nCycleCount = RobotDeathLoop.nCycleCount + 1
        LOG.INFO("RobotDeathLoop: === 第 %d / %d 轮 ===", RobotDeathLoop.nCycleCount, RobotDeathLoop.nMaxCycles)

        -- 先复活
        RobotControl.CMD("ReviveMySelf")

        -- 等1秒后自杀
        Timer.Add(RobotDeathLoop, 1, function()
            RobotControl.CMD("KillMySelf")
        end)

        if RobotDeathLoop.nCycleCount >= RobotDeathLoop.nMaxCycles then
            RobotDeathLoop.StopCycle()
        end
    end)
end

function RobotDeathLoop.StopCycle()
    if RobotDeathLoop.timerDeathLoop then
        Timer.Del(RobotDeathLoop.timerDeathLoop)
        RobotDeathLoop.timerDeathLoop = nil
    end
    AutoTestLog.Log("RobotDeathLoop", "循环已停止 共执行 " .. tostring(RobotDeathLoop.nCycleCount) .. " 轮")
end

AutoTestLog.Log("RobotDeathLoop", "RobotDeathLoop End")
return RobotDeathLoop
