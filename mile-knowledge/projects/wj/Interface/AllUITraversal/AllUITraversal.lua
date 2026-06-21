AllUITraversal={}
AllUI={}
AllUITraversal.List={}-- 处理过的面板数据
RunMap ={}
--读取tab的内容
local tbRunMapData=SearchPanel.LoadRunMapFile(SearchPanel.szCurrentInterfacePath.."RunMap.tab",2)
local list_RunMapCMD = tbRunMapData[1]
local list_RunMapTime = tbRunMapData[2]
-- 前后置条件
local bFlag = true
local nUIStartTime = 0
local nUINextTime=tonumber(7)
local nUILine=1
local NumberCycles = 1  -- 循环的次数
local nUINumber = 0     -- 遍历的轮数
local nUIViewCount= 250
local bOpen = false   -- 是否打开面板
AllUITraversal.bSwitch = true
local error ={4804,6,20,4491,1530,33,4603,2204,77,181,1539,4564,5271,307,977,4692,4604,4602,4434,4498,4496,4565,4434,4498,4496,4565,4433,317,4203,110,2305,2208,115,323,28,82,301,861,801,1}
-- 处理外装面板的List
function AllUITraversal.GetVIEW_IDList()
    for key, value in pairs(VIEW_ID) do
        if tonumber(value) < 10000 then
            table.insert(AllUITraversal.List, {value,key})
        end
    end
end
function AllUITraversal.CheckErrorUI(nUIid)
    for _, v in ipairs(error) do
        if v == tonumber(nUIid)  then
           return true
        end
    end
    return false
end

-- 调整遍历次数接口
function AllUI.SetUICount(nUICount2)
    NumberCycles = tonumber(nUICount2)
end


-- 调整遍历人数接口
function AllUI.SetUI(nUILine1,nUICount)
    nUILine = tonumber(nUILine1)
    nUIViewCount = tonumber(nUICount)
end

function AllUITraversal.FrameUpdate()
    if not AllUITraversal.bSwitch then
        return
    end
    if GetTickCount()-nUIStartTime>nUINextTime*1000 then
        if not bOpen then
            if nUILine== nUIViewCount then
                nUILine = 1
                nUINumber = nUINumber+1
                if nUINumber == NumberCycles then
                    -- 遍历完成后 关闭UI遍历帧函数
                    Timer.DelAllTimer(AllUITraversal)
                    bFlag = true
                end
            end
            --执行操作
            if not AllUITraversal.CheckErrorUI(AllUITraversal.List[nUILine][1]) then
                UIMgr.Open(AllUITraversal.List[nUILine][1])
                local szCmd = tostring(AllUITraversal.List[nUILine][1])..","..tostring(AllUITraversal.List[nUILine][2])
                AutoTestLog.INFO(szCmd)
            end
            bOpen = true
        else
            UIMgr.Close(AllUITraversal.List[nUILine][1])
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
    if not AllUITraversal.bSwitch then
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
        if string.find(szCmd,"AllUITraversal") then
            AllUITraversal.GetVIEW_IDList()
            -- 执行UI帧函数
            Timer.AddFrameCycle(AllUITraversal,1,function ()
                AllUITraversal.FrameUpdate()
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