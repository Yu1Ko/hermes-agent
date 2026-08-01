LoginMgr.Log("StabilityController","StabilityController imported")

-- 稳定性主控插件
StabilityController = {}
StabilityController.bFlag = true
local tbInterface={"LoginCreateRole","LoginChangeFace","NewDaoxiangchunTask","SectTask","ShopErgodicTDR","UITraversal","Dungeons","FlySkill","ArenaPvP","LightSkill"}
for _,szStabilityJourneyTask in pairs(tbInterface) do
    local szInterfacePath="mui/Lua/Interface/StabilityJourneyTask/"
    require(szInterfacePath..szStabilityJourneyTask..'/'..szStabilityJourneyTask..'.lua')
    LoginMgr.Log("StabilityController",szInterfacePath..szStabilityJourneyTask..'/'..szStabilityJourneyTask..'.lua')
end

local list_RunMapCMD = {}
local list_RunMapTime = {}
local nCurrentTime = 0
local nNextTime=tonumber(20)
local nCurrentStep=1
StabilityController.szInterfacePath=SearchPanel.szCurrentInterfacePath
--读取tab的内容
local tbRunMapData=SearchPanel.LoadRunMapFile(SearchPanel.szCurrentInterfacePath.."RunMap.tab",2)
list_RunMapCMD = tbRunMapData[1]
list_RunMapTime = tbRunMapData[2]

-- 设置脚本
function StabilityController.SetDungeons(nDungeonMap)
    DungeonsRunMapTask(StabilityController.szInterfacePath.."Dungeons/DungeonsTask/"..tostring(nDungeonMap)..".tab")
end

-- 主控RunMap.文件
function StabilityController.FrameUpdate()
    if StabilityController.bFlag and GetTickCount()-nCurrentTime>nNextTime*1000 then
        if nCurrentStep==#list_RunMapCMD then
            StabilityController.bFlag=false
        end
        --切图前后置操作
        local szCmd=list_RunMapCMD[nCurrentStep]
        local nTime=tonumber(list_RunMapTime[nCurrentStep])
        pcall(function ()
            SearchPanel.RunCommand(szCmd)
        end)
       AutoTestLog.INFO(tostring(StabilityController.bFlag))
       AutoTestLog.INFO(szCmd)
        nNextTime=nTime
        --启动插件操作
        if string.find(szCmd,"LoginCreateRole") then
            Preconditions.bSwitch = true
            StabilityController.bFlag = false
        elseif string.find(szCmd,"LoginChangeFace") then
            LoginChangeFaceStart.bSwitch = true
            StabilityController.bFlag = false
        elseif string.find(szCmd,"NewDaoxiangchunTask") then
            NewDaoxiangchunTaskStart.bSwitch = true
            StabilityController.bFlag = false
        elseif string.find(szCmd,"SectTask") then
            SectTaskStart.bSwitch = true
            StabilityController.bFlag = false
        elseif string.find(szCmd,"UITraversal") then
            UITraversalStart.bSwitch = true
            StabilityController.bFlag = false
        elseif string.find(szCmd,"ShopErgodicTDR") then
            ShopErgodicStart.bSwitch = true
            StabilityController.bFlag = false
        elseif string.find(szCmd,"DungeonsTask") then
            DungeonsStart.bSwitch = true
            StabilityController.bFlag = false
        elseif string.find(szCmd,"FlySkill") then
            FlySkillStart.bSwitch = true
            StabilityController.bFlag = false
        elseif string.find(szCmd,"ArenaPvP") then
            ArenaPvPStart.bSwitch = true
            StabilityController.bFlag = false
        elseif string.find(szCmd,"perfeye_start") then
            SearchPanel.bPerfeye_Start=true
        elseif string.find(szCmd,"perfeye_stop") then
            SearchPanel.bPerfeye_Stop=true
        elseif string.find(szCmd,"LightSkill") then
            LightSkillStart.bSwitch = true
            StabilityController.bFlag = false
        end
        nCurrentTime=GetTickCount()
        nCurrentStep=nCurrentStep+1
    end
end

Timer.AddFrameCycle(StabilityController,1,function ()
    StabilityController.FrameUpdate()
end)

local CloseView = {}
CloseView.VIEW_ID = {
    VIEW_ID.PanelNormalConfirmation,
}

-- 特殊处理的弹窗
function CloseView.FrameUpdate()
    for _, value in pairs(CloseView.VIEW_ID) do
        if UIMgr.IsViewOpened(value) then
            -- 关闭弹窗
            UIMgr.Close(value)
        end
    end
end

Timer.AddCycle(CloseView,10,function ()
    CloseView.FrameUpdate()
end)

LoginMgr.Log("StabilityController","StabilityController End")