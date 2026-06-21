local UIWidgetMonopolyReadyArea = class("UIWidgetMonopolyReadyArea")

function UIWidgetMonopolyReadyArea:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:InitData()
    self:UpdateInfo()
end

function UIWidgetMonopolyReadyArea:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMonopolyReadyArea:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnGo, EventType.OnClick, function ()
        MonopolyData.SendServerOperate(MINI_GAME_OPERATE_TYPE.SERVER_OPERATE, DFW_OPERATE_UP_PREPARE_READY)
    end)
end

function UIWidgetMonopolyReadyArea:RegEvent()
    Event.Reg(self, EventType.OnMonopolyOperateDownprepareReady, function ()
        self:UpdateInfo()
    end)
end

function UIWidgetMonopolyReadyArea:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetMonopolyReadyArea:InitData()
    local tCountDown = DFW_GetCountDownTime()
    if tCountDown then
        self.nEndTime = tCountDown[1]
    else
        self.nEndTime = 0
    end
    self.nClientPlayerIndex = MonopolyData.GetClientPlayerIndex()
end

function UIWidgetMonopolyReadyArea:UpdateInfo()
    local bShowButton = DFW_GetPlayerReadyIndex(self.nClientPlayerIndex) == 0

    local nLeftTime = math.max(0, (self.nEndTime - GetCurrentTime()))
    UIHelper.SetString(self.LabelGoNum, nLeftTime)

    UIHelper.SetVisible(self.BtnGo, bShowButton)
end

return UIWidgetMonopolyReadyArea