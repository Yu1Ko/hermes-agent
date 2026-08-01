-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetKeybordSetting
-- Date: 2023-01-12 14:52:11
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetKeybordSetting = class("UIWidgetKeybordSetting")

local NORMAL_FONT_SIZE = 26
local LONG_FONT_SIZE = 20
local NORMAL_THRESHOLD = 18
local SKILL_THRESHOLD = 13
local FONT_COLOR = "#AED9E0"

function UIWidgetKeybordSetting:OnEnter(nShortcutID, szName, szKeyName, nSettingType)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nShortcutID = nShortcutID
    self.szKeyName = szKeyName
    self.nSettingType = nSettingType or SHORTCUT_SETTING_TYPE.NORMAL --SHORTCUT_SETTING_TYPE

    UIHelper.SetTouchDownHideTips(self.BtnKeybord, false)
    UIHelper.SetTouchDownHideTips(self.BtnReset, false)
    UIHelper.SetSwallowTouches(self.BtnKeybord, true)
    UIHelper.SetSwallowTouches(self.BtnReset, true)
    UIHelper.SetVisible(self.BtnReset, false)
    UIHelper.SetLabel(self.LabelKeybordSettingTitle, szName)
    UIHelper.SetSwallowTouches(self.BtnKeybord, false)

    self:UpdateInfo()
end

function UIWidgetKeybordSetting:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetKeybordSetting:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnKeybord, EventType.OnSelectChanged, function(_, bSelected)
        UIHelper.SetVisible(self.BtnReset, bSelected)
        self.func(bSelected, self.bRightButtonCallback)
        if not self.bRightButtonCallback and bSelected then
            Event.Dispatch("OnClickKeyboardSetting", self.nKeyIndex)  -- 决定本次回调是否来自右侧按钮
        end
        self.bRightButtonCallback = false
    end)

    UIHelper.BindUIEvent(self.BtnReset, EventType.OnClick, function()
        if self.nSettingType == SHORTCUT_SETTING_TYPE.GAMEPAD then
            Event.Dispatch(EventType.OnGameSettingsGamepadReset, self.nShortcutID)
        else
            Event.Dispatch(EventType.OnGameSettingsKeyboardReset, self.nShortcutID)
        end
    end)
end

function UIWidgetKeybordSetting:RegEvent()
    Event.Reg(self, EventType.OnGameSettingsKeyboardChange, function(nShortcutID, szPreVaule, szValue)
        if self.nShortcutID == nShortcutID and self.nSettingType ~= SHORTCUT_SETTING_TYPE.GAMEPAD then
            self.szKeyName = szValue
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, EventType.OnGameSettingsGamepadChange, function(nShortcutID, szPreVaule, szValue)
        if self.nShortcutID == nShortcutID and self.nSettingType == SHORTCUT_SETTING_TYPE.GAMEPAD then
            self.szKeyName = szValue
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, "OnSkillSettingSelectChange", function(nIndex, bSelected)
        if (self.nSettingType == SHORTCUT_SETTING_TYPE.GAMEPAD and GamepadDef[self.nKeyIndex] == SlotId2GamepadDef[nIndex]) or self.nKeyIndex == nIndex and UIHelper.GetHierarchyVisible(self._rootNode) then
            self.bRightButtonCallback = true -- 决定本次回调是否来自右侧按钮
            UIHelper.SetSelected(self.BtnKeybord, bSelected)
        end
    end)

    Event.Reg(self, EventType.OnGamepadTypeChanged, function()
        if self.nSettingType == SHORTCUT_SETTING_TYPE.GAMEPAD and self.szKeyName then
            UIHelper.SetLabel(self.LabelSettingsMultipleChoice, ShortcutInteractionData.GetGamepadViewName(self.szKeyName))
        end
    end)
end

function UIWidgetKeybordSetting:SetSelectCallback(func)
    assert(func)
    self.func = func
end

function UIWidgetKeybordSetting:SetKeyIndex(nKeyIndex)
    assert(nKeyIndex)
    self.nKeyIndex = nKeyIndex
end

function UIWidgetKeybordSetting:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetKeybordSetting:UpdateInfo()
    if self.nSettingType == SHORTCUT_SETTING_TYPE.GAMEPAD then
        UIHelper.SetLabel(self.LabelSettingsMultipleChoice, ShortcutInteractionData.GetGamepadViewName(self.szKeyName))
    else
        local szKeyViewName = ShortcutInteractionData.GetKeyViewName(self.szKeyName, false, SHORTCUT_ICON_TYPE.SETTING)
        local szPureText = string.gsub(szKeyViewName, "<.->", "__") --图标换为占位符，用于计算文本长度做自适应字号
        local nFontThreshold = self.nSettingType == SHORTCUT_SETTING_TYPE.NORMAL and NORMAL_THRESHOLD or SKILL_THRESHOLD
        local nFontSize = GetStringCharCount(szPureText) > nFontThreshold and LONG_FONT_SIZE or NORMAL_FONT_SIZE
        szKeyViewName = string.format("<color=%s><size=%d>%s</size></color>", FONT_COLOR, nFontSize, szKeyViewName)
        UIHelper.SetLabel(self.LabelSettingsMultipleChoice, szKeyViewName)
    end
end

return UIWidgetKeybordSetting