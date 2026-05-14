-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIGMBallView
-- Date: 2022-11-07 20:11:52
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetHurStatisticPage = class("UIWidgetHurStatisticPage")

function UIWidgetHurStatisticPage:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetHurStatisticPage:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetHurStatisticPage:BindUIEvent()
end

function UIWidgetHurStatisticPage:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetHurStatisticPage:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetHurStatisticPage:UpdateInfo()

end

return UIWidgetHurStatisticPage