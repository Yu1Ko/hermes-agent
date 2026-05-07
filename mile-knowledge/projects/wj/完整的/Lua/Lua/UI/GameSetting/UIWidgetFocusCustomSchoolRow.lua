-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSettingsMultipleChoice
-- Date: 2022-12-22 16:19:35
-- Desc: ?
-- ---------------------------------------------------------------------------------

local MAX_SWITCH_NUM = 2

---@class UIWidgetFocusCustomSchoolRow
local UIWidgetFocusCustomSchoolRow = class("UIWidgetSettingsSwitchRow")

function UIWidgetFocusCustomSchoolRow:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetFocusCustomSchoolRow:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetFocusCustomSchoolRow:BindUIEvent()

end

function UIWidgetFocusCustomSchoolRow:RegEvent()

end

function UIWidgetFocusCustomSchoolRow:UnRegEvent()

end

function UIWidgetFocusCustomSchoolRow:UpdateInfo()

end

function UIWidgetFocusCustomSchoolRow:AddSchool(szName, bSelected, func, bTouchDownHideTips)
    self.nAvailableIndex = self.nAvailableIndex or 1

    local tToggle = self.toggles[self.nAvailableIndex]
    local tLabel = self.labels[self.nAvailableIndex]

    UIHelper.SetString(tLabel, szName)
    UIHelper.SetSelected(tToggle, bSelected)
    UIHelper.BindUIEvent(tToggle, EventType.OnClick, func)
    UIHelper.SetVisible(UIHelper.GetParent(tToggle), true)

    if bTouchDownHideTips == false then
        UIHelper.SetTouchDownHideTips(tToggle, bTouchDownHideTips)
    end

    self.nAvailableIndex = self.nAvailableIndex + 1
end

function UIWidgetFocusCustomSchoolRow:IsFull()
    return self.nAvailableIndex > MAX_SWITCH_NUM
end

return UIWidgetFocusCustomSchoolRow
