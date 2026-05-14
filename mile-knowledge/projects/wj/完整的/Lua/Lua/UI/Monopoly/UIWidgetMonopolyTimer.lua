local UIWidgetMonopolyTimer = class("UIWidgetMonopolyTimer")
local COUNTDOWN_TIME = 5
function UIWidgetMonopolyTimer:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    
end

function UIWidgetMonopolyTimer:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMonopolyTimer:BindUIEvent()
    
end

function UIWidgetMonopolyTimer:RegEvent()
    Event.Reg(self, EventType.OnMonopolyOperateDownCountDown, function ()
        self:StartTimer()
    end)
end

function UIWidgetMonopolyTimer:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIWidgetMonopolyTimer:SetDirection(szDirection)
    self.szDirection = szDirection
end

function UIWidgetMonopolyTimer:StartTimer()
    local tCountDown = DFW_GetCountDownTime()
    if tCountDown then
        self.nEndTime = tCountDown[1]
    else
        self.nEndTime = 0
    end

    self.nTimerID = self.nTimerID or Timer.AddFrameCycle(self, 15, function ()
        self:UpdateTimer()
    end)

    UIHelper.SetVisible(self._rootNode, true)
end

function UIWidgetMonopolyTimer:StopTimer()
    self.nEndTime = 0

    Timer.DelAllTimer(self)
    self.nTimerID = nil

    UIHelper.SetVisible(self._rootNode, false)
end

function UIWidgetMonopolyTimer:UpdateTimer()
    local nLeftTime = math.max(0, (self.nEndTime - GetCurrentTime()))

    UIHelper.SetString(self.TextTimeNum , nLeftTime)
    if nLeftTime == 0 then
        self:StopTimer()
    end
end


function UIWidgetMonopolyTimer:SetVisible(bVisible)
    self.bVisible = bVisible
    UIHelper.SetVisible(self._rootNode , bVisible)
end

return UIWidgetMonopolyTimer