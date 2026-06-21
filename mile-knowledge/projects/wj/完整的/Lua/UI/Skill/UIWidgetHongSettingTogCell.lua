-- ---------------------------------------------------------------------------------
-- Author: Jiayuran
-- Name: UIWidgetHongSettingTogCell
-- Date: 2025-7-24 19:57:23
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetHongSettingTogCell = class("UIWidgetHongSettingTogCell")

function UIWidgetHongSettingTogCell:OnEnter(nMacroID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nMacroID = IsNumber(nMacroID) and nMacroID or nil
    self:UpdateInfo()
end

function UIWidgetHongSettingTogCell:OnExit()
    self.bInit = false
    Event.UnRegAll(self)
end

function UIWidgetHongSettingTogCell:BindUIEvent()
end

function UIWidgetHongSettingTogCell:RegEvent()
    Event.Reg(self, EventType.OnDXMacroUpdate, function(dwID)
        if self.nMacroID == dwID then
            self:UpdateInfo()
        end
    end)
end

function UIWidgetHongSettingTogCell:UpdateInfo()
    if self.nMacroID then
        UIHelper.SetLabel(self.LabelBrightTitle, GetMacroName(self.nMacroID))
        UIHelper.SetLabel(self.LabelUsualTitle, GetMacroName(self.nMacroID))

        UIHelper.SetLabel(self.LabelUsualDescribe, GetMacroDesc(self.nMacroID))
        UIHelper.SetLabel(self.LabelBrightDescribe, GetMacroDesc(self.nMacroID))

        if not self.iconScript then
            self.iconScript = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, self.WidgetIcon)
        end
        self.iconScript:UpdateByIconID(GetMacroIcon(self.nMacroID))
    end
end

function UIWidgetHongSettingTogCell:SetSelected(bSel)
    UIHelper.SetSelected(self.TogHongSetting, bSel)
end

function UIWidgetHongSettingTogCell:BindSelectFunc(fnSelected)
    if fnSelected then
        UIHelper.BindUIEvent(self.TogHongSetting, EventType.OnSelectChanged, fnSelected)
    end
end

function UIWidgetHongSettingTogCell:SetToggleGroup(toggleGroup)
    if toggleGroup then
        UIHelper.ToggleGroupAddToggle(toggleGroup, self.TogHongSetting)
    end
end

return UIWidgetHongSettingTogCell
