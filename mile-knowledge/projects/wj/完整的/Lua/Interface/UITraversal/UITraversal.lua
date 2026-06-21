UITraversal={}
UITraversal.bSwitch=true
local RunMap ={}
--读取tab的内容
local tbRunMapData=SearchPanel.LoadRunMapFile(SearchPanel.szCurrentInterfacePath.."RunMap.tab",2)
local list_RunMapCMD = tbRunMapData[1]
local list_RunMapTime = tbRunMapData[2]
--读取UICMD文件
local tbUIData=SearchPanel.LoadRunMapFile(SearchPanel.szCurrentInterfacePath.."GMInstruct.tab",2)
local list_UICMD = tbUIData[1]
local list_UITime = tbUIData[2]
-- 设置人物登录
--SearchPanel.tbModule['AutoLogin'].SetAutoLoginInfo(nil,RandomString(8),'纯阳','成男')
-- 前后置条件
local bFlag = true
local nUIStartTime = 0
local nUINextTime=tonumber(5)
local nUILine=1
local NumberCycles = 2  -- 循环的次数
local nUINumber = 0     -- 遍历的轮数

-- 调整遍历次数接口
function UITraversal.SetUICount(nUICount)
    NumberCycles = tonumber(nUICount)
end

function UITraversal.FrameUpdate()
    if not UITraversal.bSwitch then
        return
    end
    if GetTickCount()-nUIStartTime>nUINextTime*1000 then
        if nUILine==#list_UICMD+1 then
            if nUINumber == NumberCycles then
                -- 遍历完成后 关闭UI遍历帧函数
                Timer.DelAllTimer(UITraversal)
                bFlag = true
            end
            nUILine = 1
            nUINumber = nUINumber+1
        end
        --执行操作
        local szCmd=list_UICMD[nUILine]
        local nUITime=tonumber(list_UITime[nUILine])
        LoginMgr.Log("szCmd",UTF8ToGBK(szCmd))
        LoginMgr.Log("szCmd",nUILine)
        local bCmd = SearchPanel.RunCommand(szCmd)
        nUINextTime=nUITime
        nUIStartTime=GetTickCount()
        nUILine=nUILine+1
    end
end

local pCurrentTime = 0
local nNextTime=tonumber(20)
local nCurrentStep=1
function RunMap.FrameUpdate()
    if not UITraversal.bSwitch then
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
        if string.find(szCmd,"UIErgodic") then
            -- 执行UI帧函数
            Timer.AddFrameCycle(UITraversal,1,function ()
                UITraversal.FrameUpdate()
            end)
            bFlag=false
        end
		pCurrentTime=GetTickCount()
        nCurrentStep=nCurrentStep+1 
    end
end


-- 帮会页面特殊操作
local GuildTips = {}
function GuildTips.FrameUpdate()
    if UIMgr.IsViewOpened(VIEW_ID.PanelNormalConfirmation) then
        UINodeControl.BtnTriggerByLable("BtnOk","太可怕了")
    end
    if UIMgr.IsViewOpened(VIEW_ID.PanelActivityBanner) then
        UIMgr.Close(VIEW_ID.PanelActivityBanner)
    end
    if UIMgr.IsViewOpened(VIEW_ID.PanelHotSpotBanner) then
        UIMgr.Close(VIEW_ID.PanelHotSpotBanner)
    end
end
Timer.AddCycle(GuildTips,1,function ()
    GuildTips.FrameUpdate()
end)

Timer.AddFrameCycle(RunMap,1,function ()
    RunMap.FrameUpdate()
end)