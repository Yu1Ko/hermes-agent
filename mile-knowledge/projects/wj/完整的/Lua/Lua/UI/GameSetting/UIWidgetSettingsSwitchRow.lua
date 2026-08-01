-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSettingsMultipleChoice
-- Date: 2022-12-22 16:19:35
-- Desc: ?
-- ---------------------------------------------------------------------------------

local MAX_SWITCH_NUM = 2

---@class UIWidgetSettingsSwitchRow
local UIWidgetSettingsSwitchRow = class("UIWidgetSettingsSwitchRow")

function UIWidgetSettingsSwitchRow:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetSettingsSwitchRow:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetSettingsSwitchRow:BindUIEvent()

end

function UIWidgetSettingsSwitchRow:RegEvent()

end

function UIWidgetSettingsSwitchRow:UnRegEvent()

end

function UIWidgetSettingsSwitchRow:UpdateInfo()

end


function UIWidgetSettingsSwitchRow:AddSwitch(tCellInfo, func, bSelected, nMainCategory)
    self.nAvailableIndex = self.nAvailableIndex or 1

    local szName = tCellInfo.szName
    local szHelpText = tCellInfo.szHelpText

    local tNode = self.tSwitches[self.nAvailableIndex]
    local script = UIHelper.GetBindScript(tNode) ---@type UIWidgetSettingsSwitch
    script:AddToggleFunc(func)
    script:AddBtnExtraFunc(tCellInfo.fnExtra)
    script:SetSelected(bSelected)
    script:SetName(szName)
    script:SetHelpText(szHelpText)

    if tCellInfo.bCommit then
        UIHelper.SetVisible(script.BtnCommit, bSelected)
        UIHelper.BindUIEvent(script.BtnCommit, EventType.OnClick, function()
            GameSettingData.OnLogReport()
        end)
    end
    if tCellInfo.tEnable then
        local fnEnable = tCellInfo.tEnable.fnEnable
        local szMsg = tCellInfo.tEnable.szMessage
        local bEnable = true
        if fnEnable then
            bEnable = fnEnable()
        end
        if bEnable == false then
            script:SetEnable(false)
            script:SetGray(true)
            script:BindDisabledEvent(szMsg)
            if tCellInfo.tEnable.bDisableValue ~= nil then
                script:SetSelected(tCellInfo.tEnable.bDisableValue)
            end
        elseif fnExtraEnable then
            script:SetTipEnable(fnExtraEnable(), szExtraEnableTip)
        end
    end

    if nMainCategory and nMainCategory == DISPLAY.TOP_HEAD then
        if SelfieData.IsInStudioMap() then
            script:SetTipEnable(false, "万景阁内不可调整")
        end
    end

    UIHelper.SetVisible(tNode, true)

    self.nAvailableIndex = self.nAvailableIndex + 1
end

function UIWidgetSettingsSwitchRow:AddButton(tCellInfo)
    self.nAvailableIndex = self.nAvailableIndex or 1

    local szName = tCellInfo.szName
    local szHelpText = tCellInfo.szHelpText
    local fnFunc = tCellInfo.fnFunc
    local szBtnLabelName = tCellInfo.fnBtnLabelName and tCellInfo.fnBtnLabelName() or tCellInfo.szBtnLabelName
    
    local tNode = self.tSwitches[self.nAvailableIndex]
    local script = UIHelper.GetBindScript(tNode) ---@type UIWidgetSettingsSwitch
    script:InitButton(szName, szBtnLabelName, fnFunc, tCellInfo.tEnable)
    script:SetHelpText(szHelpText)

    UIHelper.SetVisible(tNode, true)

    self.nAvailableIndex = self.nAvailableIndex + 1
end

function UIWidgetSettingsSwitchRow:IsFull()
    return self.nAvailableIndex > MAX_SWITCH_NUM
end

return UIWidgetSettingsSwitchRow
