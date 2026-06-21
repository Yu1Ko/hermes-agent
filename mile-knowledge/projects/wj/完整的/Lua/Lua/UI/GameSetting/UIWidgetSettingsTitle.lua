-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSettingsTitle
-- Date: 2022-12-20 14:50:09
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetSettingsTitle = class("UIWidgetSettingsTitle")

function UIWidgetSettingsTitle:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetSettingsTitle:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetSettingsTitle:BindUIEvent()

end

function UIWidgetSettingsTitle:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetSettingsTitle:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


function UIWidgetSettingsTitle:UpdateInfo()

end

function UIWidgetSettingsTitle:SetTitle(szTitle)
    UIHelper.SetString(self.LabelSettingsWordageTitle, szTitle)
end

function UIWidgetSettingsTitle:SetDesc(szDesc)
    if not szDesc or szDesc == "" then
        UIHelper.SetVisible(self.LabelSettingsWarning, false)
        return
    end

    UIHelper.SetString(self.LabelSettingsWarning, szDesc)
    UIHelper.SetVisible(self.LabelSettingsWarning, true)
end

return UIWidgetSettingsTitle