-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSettingsMultipleChoice
-- Date: 2022-12-22 16:19:35
-- Desc: ?
-- ---------------------------------------------------------------------------------

local MAX_SWITCH_NUM = 2

---@class UIWidgetSettingVolumeRow
local UIWidgetSettingVolumeRow = class("UIWidgetSettingVolumeRow")

function UIWidgetSettingVolumeRow:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetSettingVolumeRow:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetSettingVolumeRow:BindUIEvent()

end

function UIWidgetSettingVolumeRow:RegEvent()

end

function UIWidgetSettingVolumeRow:UnRegEvent()

end

function UIWidgetSettingVolumeRow:UpdateInfo()

end

function UIWidgetSettingVolumeRow:AddSwitch(tbSettingsCell, nCurrentValue, fnEndCallback)
    assert(tbSettingsCell)
    assert(nCurrentValue)
    assert(fnEndCallback)

    self.nAvailableIndex = self.nAvailableIndex or 1

    local tNode = self.tSwitches[self.nAvailableIndex]
    local script = UIHelper.GetBindScript(tNode)
    script:OnEnter(tbSettingsCell, nCurrentValue, fnEndCallback)
    script:SetName(tbSettingsCell.szName)

    UIHelper.SetVisible(tNode, true)

    self.nAvailableIndex = self.nAvailableIndex + 1
end

function UIWidgetSettingVolumeRow:IsFull()
    return self.nAvailableIndex > MAX_SWITCH_NUM
end

return UIWidgetSettingVolumeRow
