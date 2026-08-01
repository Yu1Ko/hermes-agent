-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSettingsMultipleChoice
-- Date: 2022-12-22 16:19:35
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetSettingsMultipleChoicePop = class("UIWidgetSettingsMultipleChoicePop")

function UIWidgetSettingsMultipleChoicePop:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        UIHelper.SetTouchDownHideTips(self.LayoutMultipleChoice, false)
        UIHelper.SetTouchDownHideTips(self.ScrollViewList, false)
    end
end

function UIWidgetSettingsMultipleChoicePop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetSettingsMultipleChoicePop:BindUIEvent()

end

function UIWidgetSettingsMultipleChoicePop:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetSettingsMultipleChoicePop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetSettingsMultipleChoicePop:UpdateSingleChoice(tBtnInfoList, bMultiMode)
    local tContainer = self:GetSuitableContainer(tBtnInfoList)
    UIHelper.RemoveAllChildren(tContainer)
    self.tbBtnScripts = {}

    for nIndex, tInfo in ipairs(tBtnInfoList) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSettingsMultipleChoiceBtn, tContainer, tInfo)
        table.insert(self.tbBtnScripts, script)
        if bMultiMode then
            UIHelper.SetContentSize(script.ImgCheck, 38, 38)
            UIHelper.SetSpriteFrame(script.ImgCheck, "UIAtlas2_Public_PublicButton_PublicButton1_img_select")
            UIHelper.SetSpriteFrame(script.ImgNormal, "UIAtlas2_Public_PublicButton_PublicButton1_btnTogBg")
        end

        local bSelected = tInfo.bSelected
        if tInfo.fnSelected then bSelected = tInfo.fnSelected() end

        if bSelected and tInfo.bScrollToIndex and tContainer == self.ScrollViewList then
            local nScrollIndex = nIndex - 1
            Timer.Add(self, 0.05, function()
                UIHelper.ScrollToIndex(self.ScrollViewList, nScrollIndex)
                if nScrollIndex > #tBtnInfoList - 7 then
                    UIHelper.SetVisible(self.WidgetArrowParent, false)
                end
            end)
        end
    end

    UIHelper.SetOpacity(self._rootNode, 0)
    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
    Timer.Add(self, 0.05, function()
        UIHelper.SetOpacity(self._rootNode, 255) -- 优化表现
        if tContainer == self.ScrollViewList then
            UIHelper.SetVisible(self.WidgetArrowParent, true)
            UIHelper.ScrollViewSetupArrow(self.ScrollViewList, self.WidgetArrowParent)
        end
    end)
end

function UIWidgetSettingsMultipleChoicePop:UpdateMultipleChoice(tBtnInfoList)
    local tContainer = self:GetSuitableContainer(tBtnInfoList)
    UIHelper.RemoveAllChildren(tContainer)
    
    self.tbBtnScripts = {}
    for nIndex, tInfo in ipairs(tBtnInfoList) do
        local szName = tInfo.szName
        local func = tInfo.func
        local bSelected = tInfo.bSelected
        if tInfo.fnSelected then bSelected = tInfo.fnSelected() end

        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetTogTypeMulti_XS, tContainer, szName, bSelected, func)
        table.insert(self.tbBtnScripts, script)

        if bSelected and tInfo.bScrollToIndex and tContainer == self.ScrollViewList then
            local nScrollIndex = nIndex - 1
            Timer.Add(self, 0.05, function()
                UIHelper.ScrollToIndex(self.ScrollViewList, nScrollIndex)
                if nScrollIndex > #tBtnInfoList - 7 then
                    UIHelper.SetVisible(self.WidgetArrowParent, false)
                end
            end)
        end
    end

    UIHelper.SetOpacity(self._rootNode, 0)
    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
    Timer.Add(self, 0.05, function()
        UIHelper.SetOpacity(self._rootNode, 255)
        if tContainer == self.ScrollViewList then
            UIHelper.SetVisible(self.WidgetArrowParent, true)
            UIHelper.ScrollViewSetupArrow(self.ScrollViewList, self.WidgetArrowParent)
        end
    end)
end

function UIWidgetSettingsMultipleChoicePop:SetBtnSelectedWithoutEvent(nIndex, bSelected)
    if self.tbBtnScripts[nIndex] then
        UIHelper.SetSelected(self.tbBtnScripts[nIndex].TogType, bSelected, false)
    end
end

function UIWidgetSettingsMultipleChoicePop:GetSuitableContainer(tBtnInfoList)
    if tBtnInfoList then
        self.tBtnInfoList = tBtnInfoList
    end
    
    if #self.tBtnInfoList <= 6 then
        UIHelper.SetVisible(self.LayoutMultipleChoice, true)
        UIHelper.SetVisible(self.WidgetScrollViewTip, false)
        
        return self.LayoutMultipleChoice
    else
        UIHelper.SetVisible(self.LayoutMultipleChoice, false)
        UIHelper.SetVisible(self.WidgetScrollViewTip, true)
        
        return self.ScrollViewList
    end
end

return UIWidgetSettingsMultipleChoicePop