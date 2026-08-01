-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandOverviewRewardCell
-- Date: 2024-01-30 20:52:18
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandOverviewRewardCell = class("UIHomelandOverviewRewardCell")

function UIHomelandOverviewRewardCell:OnEnter(tbInfo, nTotalActiveNum)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbInfo = tbInfo
    self.nTotalActiveNum = nTotalActiveNum
    self.bGetAward = nTotalActiveNum >= tbInfo.nScore
    self:UpdateInfo()
end

function UIHomelandOverviewRewardCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomelandOverviewRewardCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogReward, EventType.OnTouchBegan, function(btn)
        if UIHelper.GetSelected(self.TogReward) then
            self.bHideReward = true
        end
    end)

    UIHelper.BindUIEvent(self.TogReward, EventType.OnClick, function(btn)
        if self.bHideReward then
            self.bHideReward = false
            UIHelper.SetSelected(self.TogReward, false)
        end
    end)

    UIHelper.SetToggleGroupIndex(self.TogReward, ToggleGroupIndex.HomelandOrderItem)
end

function UIHomelandOverviewRewardCell:RegEvent()
    Event.Reg(self, EventType.OnSceneTouchNothing, function ()
        self:SetSelected(false)
    end)

    Event.Reg(self, EventType.OnClearOverviewRewardListSelected, function ()
        self:SetSelected(false)
    end)
end

function UIHomelandOverviewRewardCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomelandOverviewRewardCell:UpdateInfo()
    self:SetSelected(false)
    UIHelper.SetVisible(self.WidgetObtained, self.bGetAward)
    UIHelper.SetVisible(self.WidgetNotObtained, not self.bGetAward)

    local tbInfo = self.tbInfo
    local tbRewardItems = tbInfo.tReward
    UIHelper.SetString(self.LabelObtained01, tbInfo.nScore)
    UIHelper.SetString(self.LabelNotObtained01, tbInfo.nScore)
    for _, v in ipairs(tbRewardItems) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.LayoutRewardList60)
        if not v.bIsCoin then
            script:OnInitWithTabID(v.nItemType, v.nItemID, v.nCount)
            script:SetClickCallback(function ()
                TipsHelper.ShowItemTips(script._rootNode, v.nItemType, v.nItemID, false)
            end)
        else
            local tIconLine = Table_GetCalenderActivityAwardIconByID(v.nCurrencyID) or {}
            local tCurrencyInfo = tIconLine.szName and Table_GetCurrencyInfoByIndex(tIconLine.szName) or nil
            script:OnInitCurrency(tCurrencyInfo.szName, v.nCount)
            script:SetClickCallback(function ()
               TipsHelper.ShowCurrencyTips(script._rootNode, tCurrencyInfo.szName, v.nCount)
            end)
        end
        script:SetToggleGroupIndex(ToggleGroupIndex.HomelandOrderRewardItem)
        script:SetTouchDownHideTips(false)
        script:SetClearSeletedOnCloseAllHoverTips(true)
    end
end

function UIHomelandOverviewRewardCell:SetSelected(bSelected)
    UIHelper.SetSelected(self.TogReward, bSelected)
end

return UIHomelandOverviewRewardCell