local ChatTraversal = {}
ChatTraversal.bSwitch=true
local RunMap ={}
--读取tab的内容
local tbRunMapData=SearchPanel.LoadRunMapFile(SearchPanel.szCurrentInterfacePath.."RunMap.tab",2)
local list_RunMapCMD = tbRunMapData[1]
local list_RunMapTime = tbRunMapData[2]
-- 设置人物登录
--SearchPanel.tbModule['AutoLogin'].SetAutoLoginInfo(nil,RandomString(8),'纯阳','成男')
-- 前后置条件
local bFlag = true
function ChatTraversal.FrameUpdate()
    RobotControl.CMD("ReviveMySelf")
    -- 重新添加机器人buff
    RobotControl.CMD("CampfightBuff")
end

local pCurrentTime = 0
local nNextTime=tonumber(20)
local nCurrentStep=1
function RunMap.FrameUpdate()
    if not ChatTraversal.bSwitch then
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
        AutoTestLog.INFO(szCmd)
        pcall(function ()
            SearchPanel.RunCommand(szCmd)
        end)
        AutoTestLog.INFO(szCmd.."ok")
        if string.find(szCmd,"perfeye_start") then
            SearchPanel.bPerfeye_Start=true
        end
        if string.find(szCmd,"perfeye_stop") then
            SearchPanel.bPerfeye_Stop=true
        end
        nNextTime=nTime
        --切图操作
        if string.find(szCmd,"ChatTraversal") then
            -- 执行UI帧函数
            Timer.AddCycle(ChatTraversal,15,function ()
                ChatTraversal.FrameUpdate()
            end)
            bFlag=false
        end
		pCurrentTime=GetTickCount()
        nCurrentStep=nCurrentStep+1 
    end
end


Timer.AddFrameCycle(RunMap,1,function ()
    RunMap.FrameUpdate()
end)