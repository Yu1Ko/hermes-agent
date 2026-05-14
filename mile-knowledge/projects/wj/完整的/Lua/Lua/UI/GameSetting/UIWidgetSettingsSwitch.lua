-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSettingsMultipleChoice
-- Date: 2022-12-22 16:19:35
-- Desc: ?
-- ---------------------------------------------------------------------------------

---@class UIWidgetSettingsSwitch
local UIWidgetSettingsSwitch = class("UIWidgetSettingsSwitch")

function UIWidgetSettingsSwitch:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetSettingsSwitch:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetSettingsSwitch:BindUIEvent()

end

function UIWidgetSettingsSwitch:RegEvent()

end

function UIWidgetSettingsSwitch:UnRegEvent()

end

function UIWidgetSettingsSwitch:UpdateInfo()

end

function UIWidgetSettingsSwitch:SetName(szName)
    UIHelper.SetString(self.LabelSettingsMultipleChoiceTitle, szName)
end

function UIWidgetSettingsSwitch:AddToggleFunc(func)
    UIHelper.BindUIEvent(self.ToggleHideNpc, EventType.OnSelectChanged, function(toggle, bSel)
        local bSelected = UIHelper.GetSelected(self.ToggleHideNpc)
        func(bSel, toggle, self)
    end)
end

function UIWidgetSettingsSwitch:AddBtnExtraFunc(func)
    if not func then return end
    
    UIHelper.BindUIEvent(self.BtnExtra, EventType.OnClick, function()
        func()
    end)
    UIHelper.SetVisible(self.BtnExtra, true)
end

function UIWidgetSettingsSwitch:SetSelected(bSelected)
    if bSelected ~= nil then
        UIHelper.SetSelected(self.ToggleHideNpc, bSelected, false)
    end
end

function UIWidgetSettingsSwitch:SetEnable(bVal)
    if bVal ~= nil then
        UIHelper.SetEnable(self.ToggleHideNpc, bVal)
    end
end

function UIWidgetSettingsSwitch:SetTipEnable(bVal, szTipText)
    if bVal ~= nil then
        UIHelper.SetCanSelect(self.ToggleHideNpc, bVal, szTipText, true)
    end
end

function UIWidgetSettingsSwitch:SetGray(bVal)
    if bVal ~= nil then
        UIHelper.SetNodeGray(self._rootNode, bVal, true)
    end
end

function UIWidgetSettingsSwitch:BindDisabledEvent(szMsg)
    if szMsg and szMsg ~= "" then
        UIHelper.SetVisible(self.BtnDisabled, true)
        UIHelper.BindUIEvent(self.BtnDisabled, EventType.OnClick, function()
            local scriptConfirm = UIHelper.ShowConfirm(szMsg)
            scriptConfirm:HideButton("Confirm")
        end)
    end
end

function UIWidgetSettingsSwitch:SetHelpText(szText)
    if szText then
        UIHelper.SetVisible(self.BtnHelp, true)
        UIHelper.BindUIEvent(self.BtnHelp, EventType.OnClick, function()
            local tips, tipsScript = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.BtnHelp
            , TipsLayoutDir.RIGHT_CENTER, szText)

            local x, y = UIHelper.GetContentSize(tipsScript.ImgPublicLabelTips)
            tips:SetSize(x, y)
            tips:Update()
        end)
    end
end

function UIWidgetSettingsSwitch:InitButton(szName, szBtnLabelName, fnFunc, tEnable)
    UIHelper.SetVisible(self.ToggleHideNpc, false)
    UIHelper.SetVisible(self.BtnGo, true)
    
    UIHelper.SetString(self.LabelSettingsMultipleChoiceTitle, szName)
    UIHelper.SetString(self.LabelBtn, szBtnLabelName)
    UIHelper.BindUIEvent(self.BtnGo, EventType.OnClick, fnFunc)

    if tEnable then
        local bEnabled = tEnable.fnEnable and tEnable.fnEnable()
        UIHelper.SetButtonState(self.BtnGo, bEnabled and BTN_STATE.Normal or BTN_STATE.Disable, function()
            if tEnable.szMessage then
                TipsHelper.ShowImportantYellowTip(tEnable.szMessage)
            end
        end)
    end
end

return UIWidgetSettingsSwitch