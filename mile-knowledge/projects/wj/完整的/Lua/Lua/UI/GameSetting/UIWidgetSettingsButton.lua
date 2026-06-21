-- ---------------------------------------------------------------------------------
-- Author: JiaYuRan
-- Name: UIWidgetSettingsButton
-- Date: 2024-7-15 14:34:51
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetSettingsButton = class("UIWidgetSettingsButton")

function UIWidgetSettingsButton:OnEnter(szName, bSelected, func)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    UIHelper.SetSelected(self.TogSelectBg, bSelected)
    UIHelper.SetString(self.LabelDesc, szName)
    self.func = func
end

function UIWidgetSettingsButton:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetSettingsButton:BindUIEvent()
    UIHelper.BindUIEvent(self.TogSelectBg, EventType.OnClick, function ()
        local bSelected = UIHelper.GetSelected(self.TogSelectBg)
        if self.func then
            self.func(bSelected)
        end
    end)
end

function UIWidgetSettingsButton:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetSettingsButton:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetSettingsButton:UpdateInfo()
    
end


return UIWidgetSettingsButton