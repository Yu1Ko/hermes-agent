-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSubjoinSettingsCheck
-- Date: 2022-12-22 15:19:22
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetSubjoinSettingsCheck = class("UIWidgetSubjoinSettingsCheck")

function UIWidgetSubjoinSettingsCheck:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetSubjoinSettingsCheck:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetSubjoinSettingsCheck:BindUIEvent()

end

function UIWidgetSubjoinSettingsCheck:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetSubjoinSettingsCheck:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetSubjoinSettingsCheck:UpdateInfo()

end

function UIWidgetSubjoinSettingsCheck:AddChildTog(szName, bSelected, func)
    local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSettingSwitch, self.LayoutSubjoinSettingsCheck)
    script:SetName(szName)
    script:SetSelected(bSelected)
    script:AddToggleFunc(func)

    --UIHelper.AddPrefab(PREFAB_ID.WidgetGameSettingsCheck, self.LayoutSubjoinSettingsCheck, szName, bSelected, func)
end

return UIWidgetSubjoinSettingsCheck