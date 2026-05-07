BaseTrade = {}
RunMap={}
local bFlag =true
-----init----------------
local Init = BaseState:New("Init")
function Init:OnEnter()

end

function Init:OnUpdate()
    fsm:Switch("Dialogue")
end

function Init:OnLeave()                               

end

-- 对话流程
local tbProcedure = {
    "UINodeControl.BtnTrigger('BtnContent_1')",
    "UINodeControl.BtnTrigger('BtnOperation')",
    "UINodeControl.BtnTrigger('BtnOperation')",
}
local bStart = false
local nStartTime = 0
local nNextTime = 5
local nLine= 1
local nCount = 1
local Dialogue = BaseState:New("Dialogue")
function Dialogue:OnEnter()
    nStartTime = GetTickCount()
end

function Dialogue:OnUpdate()
    if GetTickCount()-nStartTime>= nNextTime*1000 then
        if not bStart  then
            Event.Dispatch(EventType.OnSceneInteractByHotkey, false)
            bStart = true
            nStartTime = GetTickCount()
            return
        end
        if nLine ~= #tbProcedure+1 then
            local szCMD = "/cmd "..tbProcedure[nLine]
            SearchPanel.RunCommand(szCMD)
            print(szCMD)
            nLine = nLine + 1
        else
            if nCount == 4 then
                Timer.DelAllTimer(BaseTrade)
                bFlag = true
                return
            end
            fsm:Switch("AutoWay")
        end
        nStartTime = GetTickCount()
    end
end

function Dialogue:OnLeave()
    nLine = 1
    nCount = nCount + 1
    bStart = false
end


local AutoWay = BaseState:New("AutoWay")
local bPlayerAutoNavStart = false
function AutoWay:OnEnter()
    
end
local nAutoStartTime = 0
local nAutoNextTime = 120
function AutoWay:OnUpdate()
    if not bPlayerAutoNavStart then
        AutoNav.StartNavPlan_Trading()
        bPlayerAutoNavStart = true
        nAutoStartTime = GetTickCount()
        return
    end
    if GetTickCount()-nAutoStartTime>= nAutoNextTime*1000 then
        fsm:Switch("Dialogue")
    end
end

function AutoWay:OnLeave()
    bPlayerAutoNavStart = false
end


function BaseTrade.FrameUpdate()
    if not SearchPanel.IsFromLoadingEnterGame() then
        return
    end
    fsm.curState:OnUpdate()
end



function BaseTrade.Start()
    fsm = FsmMachine:New()
    fsm:AddState(AutoWay)
    fsm:AddState(Dialogue)
    fsm:AddInitState(Init)
    Timer.AddFrameCycle(BaseTrade,1,function ()
        BaseTrade.FrameUpdate()
    end)
end




--读取tab的内容 
local list_RunMapCMD = {}
local list_RunMapTime = {}
local tbRunMapData=SearchPanel.LoadRunMapFile(SearchPanel.szCurrentInterfacePath.."RunMap.tab",2)
list_RunMapCMD = tbRunMapData[1]
list_RunMapTime = tbRunMapData[2]
local nCurrentTime = 0
local nNextTime=tonumber(30)
local nCurrentStep=1

-- 切图的前后置操作 这部分实现模块化后直接去除
function RunMap.FrameUpdate()
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
        AutoTestLog.INFO(szCmd)
        pcall(function ()
            SearchPanel.RunCommand(szCmd)
        end)
        AutoTestLog.INFO(szCmd.."===ok")
        OutputMessage("MSG_SYS",szCmd)
        nNextTime=nTime
        --切图操作
        if string.find(szCmd,"BaseTrade_start") then
            --启动切图帧更新函数
            BaseTrade.Start()
            bFlag = false
        end
		nCurrentTime=GetTickCount()
        nCurrentStep=nCurrentStep+1 
    end
end

Timer.AddFrameCycle(RunMap,1,function ()
    RunMap.FrameUpdate()
end)