AutoTestLog.Log("RecurrentDump","RecurrentDump Start")
RecurrentDump = {}
RecurrentDump.bSwitch = true
RecurrentDump.bStatus = 1
local bFlag = true
local RunMap ={}
--读取tab的内容
local tbRunMapData=SearchPanel.LoadRunMapFile(SearchPanel.szCurrentInterfacePath.."RunMap.tab",2)
local list_RunMapCMD = tbRunMapData[1]
local list_RunMapTime = tbRunMapData[2]
RecurrentDump.nCount = 1
function RecurrentDump.FrameUpdate()
    if RecurrentDump.bStatus == 1 then
        UINodeControl.BtnTriggerByPath("BtnShop","WidgetRightTopAnchor/WidgetMainCityRightTop/LayoutSystemBtn/BtnShop")
        RecurrentDump.bStatus = RecurrentDump.bStatus + 1
    else
        UINodeControl.BtnTrigger("BtnClose","WidgetAnchorRightTop")
        RecurrentDump.bStatus = 1
    end
    -- 记录遍历次数
    AutoTestLog.INFO(tostring(RecurrentDump.nCount))
    RecurrentDump.nCount = RecurrentDump.nCount + 1
end



function RecurrentDump.Start()
    if not RecurrentDump.bSwitch  then
        return
    end
    -- 每三秒运行次
    Timer.AddCycle(RecurrentDump,3,function ()
        RecurrentDump.FrameUpdate()
    end)
end


local pCurrentTime = 0
local nNextTime=tonumber(20)
local nCurrentStep=1
function RunMap.FrameUpdate()
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
        if string.find(szCmd,"ShopStart") then
            RecurrentDump.Start()
            bFlag=false
        end
		pCurrentTime=GetTickCount()
        nCurrentStep=nCurrentStep+1
    end
end


Timer.AddFrameCycle(RunMap,1,function ()
    RunMap.FrameUpdate()
end)

AutoTestLog.Log("RecurrentDump","RecurrentDump End")
