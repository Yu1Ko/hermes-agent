UITrl={}
UITrl.List={}-- 处理过的面板数据
RunMap ={}
--读取tab的内容
local tbRunMapData=SearchPanel.LoadRunMapFile(SearchPanel.szCurrentInterfacePath.."RunMap.tab",2)
local list_RunMapCMD = tbRunMapData[1]
local list_RunMapTime = tbRunMapData[2]
-- 前后置条件
local bFlag = true
local nUIStartTime = 0
local nUINextTime=tonumber(5)
local nUILine=1
local NumberCycles = 1  -- 循环的次数
local nUINumber = 0     -- 遍历的轮数
local nUIViewCount= 500
local bOpen = false   -- 是否打开面板
UITrl.bSwitch = true

-- 调整遍历次数接口
function UITrl.SetUICount(nUICount2)
    nUIViewCount = tonumber(nUICount2)
end


function UITrl.FrameUpdate()
    if not UITrl.bSwitch then
        return
    end
    if GetTickCount()-nUIStartTime>nUINextTime*1000 then
        if not bOpen then
            if nUILine== nUIViewCount then
                nUILine = 1
                nUINumber = nUINumber+1
                if nUINumber == NumberCycles then
                    -- 遍历完成后 关闭UI遍历帧函数
                    Timer.DelAllTimer(UITrl)
                    bFlag = true
                end
            end
            --执行操作
            UIMgr.Open(51)
            bOpen = true
        else
            UIMgr.Close(51)
            nUILine=nUILine+1
            bOpen = false
        end
        nUIStartTime=GetTickCount()
    end
end

local pCurrentTime = 0
local nNextTime=tonumber(20)
local nCurrentStep=1
function RunMap.FrameUpdate()
    if not UITrl.bSwitch then
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
        if string.find(szCmd,"UITrl") then
            -- 执行UI帧函数
            Timer.AddFrameCycle(UITrl,1,function ()
                UITrl.FrameUpdate()
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