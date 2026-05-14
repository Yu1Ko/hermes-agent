BaseTrade = {}
local BaseTradeCloseView = {}
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
                Timer.DelAllTimer(BaseTradeCloseView)
                StabilityController.bFlag = true
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

BaseTradeCloseView.VIEW_ID = {
    VIEW_ID.PanelQianLiFaZhu,
}
-- 特殊处理
function BaseTradeCloseView.FrameUpdate()
    for _, value in pairs(BaseTradeCloseView.VIEW_ID) do
        if UIMgr.IsViewOpened(value) then
            -- 关闭弹窗
            UIMgr.Close(value)
        end
    end
end


function BaseTrade.Start()
    fsm = FsmMachine:New()
    fsm:AddState(AutoWay)
    fsm:AddState(Dialogue)
    fsm:AddInitState(Init)
    Timer.AddFrameCycle(BaseTradeCloseView,1,function ()
        BaseTradeCloseView.FrameUpdate()
    end)
    Timer.AddFrameCycle(BaseTrade,1,function ()
        BaseTrade.FrameUpdate()
    end)
end