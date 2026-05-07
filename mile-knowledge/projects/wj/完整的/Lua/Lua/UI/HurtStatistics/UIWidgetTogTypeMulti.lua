-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIGMBallView
-- Date: 2022-11-07 20:11:52
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetTogTypeMulti = class("UIWidgetTogTypeMulti")

function UIWidgetTogTypeMulti:OnEnter(szName, bSelected, func)
    if not self.bInit then
        self:RegEvent()
        self.bInit = true
    end

    if szName then
        UIHelper.SetString(self.LabelAllSuit, szName)
    end
    UIHelper.SetSelected(self.TogType, bSelected)

    UIHelper.BindUIEvent(self.TogType, EventType.OnSelectChanged, function(toggle, bSel)
        if func then
            func(bSel)
        end
    end)
end

function UIWidgetTogTypeMulti:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetTogTypeMulti:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetTogTypeMulti:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetTogTypeMulti:UpdateInfo()

end

return UIWidgetTogTypeMulti