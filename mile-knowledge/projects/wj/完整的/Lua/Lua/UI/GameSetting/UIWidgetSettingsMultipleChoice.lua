-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSettingsMultipleChoice
-- Date: 2022-12-22 16:19:35
-- Desc: ?
-- ---------------------------------------------------------------------------------

---@class UIWidgetSettingsMultipleChoice
local UIWidgetSettingsMultipleChoice = class("UIWidgetSettingsMultipleChoice")

function UIWidgetSettingsMultipleChoice:OnEnter(bMultiMode, tbSettingsCell)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.bMultiMode = bMultiMode
    self.fnEnable = tbSettingsCell and tbSettingsCell.fnEnable

    local bEnable = true
    if self.fnEnable then bEnable = self.fnEnable() end
    self:SetEnable(bEnable, "")
end

function UIWidgetSettingsMultipleChoice:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetSettingsMultipleChoice:BindUIEvent()
    UIHelper.BindUIEvent(self.TogSettingsMultipleChoice, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            local tip, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetSettingsMultipleChoicePop, self.TogSettingsMultipleChoice, TipsLayoutDir.BOTTOM_CENTER)

            script:UpdateSingleChoice(self.tBtnInfoList, self.bMultiMode)

            tip:SetSize(UIHelper.GetContentSize(script:GetSuitableContainer()))
            tip:SetOffset(nil, 0)
            tip:Update()

            Event.Dispatch(EventType.OnTeachButtonClick, VIEW_ID.PanelGameSettings, UIHelper.GetString(self.LabelSettingsMultipleChoiceTitle))
        end
    end)
end

function UIWidgetSettingsMultipleChoice:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function()
        if UIHelper.GetSelected(self.TogSettingsMultipleChoice) then
            UIHelper.SetSelected(self.TogSettingsMultipleChoice, false)
        end
    end)
end

function UIWidgetSettingsMultipleChoice:UnRegEvent()

end

function UIWidgetSettingsMultipleChoice:UpdateInfo()

end

function UIWidgetSettingsMultipleChoice:SetName(szName)
    UIHelper.SetString(self.LabelSettingsMultipleChoiceTitle, szName)
end

--function UIWidgetSettingsMultipleChoice:SetHelpVisible(bVisible)
--    UIHelper.SetVisible(self.TogHelp, bVisible)
--end

function UIWidgetSettingsMultipleChoice:SetHelpText(szText)
    if szText then
        UIHelper.SetVisible(self.TogHelp, true)
        UIHelper.BindUIEvent(self.TogHelp, EventType.OnClick, function()
            local tips, tipsScript = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.TogHelp
            , TipsLayoutDir.RIGHT_CENTER, szText)

            local x, y = UIHelper.GetContentSize(tipsScript.ImgPublicLabelTips)
            tips:SetSize(x, y)
            tips:Update()
        end)
    end
end

function UIWidgetSettingsMultipleChoice:AddSelectButton(szName, fnSelected, func, bRecommend, funcEnable)
    if self.tBtnInfoList == nil then
        self.tBtnInfoList = {}
    end

    if bRecommend == nil then
        bRecommend = false
    end

    self.fnClose = function()
        UIHelper.SetSelected(self.TogSettingsMultipleChoice, false)
    end

    local fnPackedFunc = function(szSelectName)
        --UIHelper.SetString(self.LabelSettingsMultipleChoice, szSelectName)
        UIHelper.SetSelected(self.TogSettingsMultipleChoice, false)
        func()
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetSettingsMultipleChoicePop)
    end
    local tInfo = { szName = szName, func = fnPackedFunc, fnSelected = fnSelected,
                    bRecommend = bRecommend, funcEnable = funcEnable }
    table.insert(self.tBtnInfoList, tInfo)
end

function UIWidgetSettingsMultipleChoice:SetSelectName(szName)
    UIHelper.SetString(self.LabelSettingsMultipleChoice, UIHelper.LimitUtf8Len(szName,16))
end

function UIWidgetSettingsMultipleChoice:SetEnable(bEnable, szReason)
    if not bEnable then
        UIHelper.SetCanSelect(self.TogSettingsMultipleChoice, false, szReason or g_tStrings.WAIT_FOR_OPEN_TIPS)
    end
end

return UIWidgetSettingsMultipleChoice