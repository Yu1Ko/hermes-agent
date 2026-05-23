-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelFestivalRewardPop
-- Date: 2025-05-08 11:56:10
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelFestivalRewardPop = class("UIPanelFestivalRewardPop")

function UIPanelFestivalRewardPop:OnEnter(tbRewardInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbRewardInfo = tbRewardInfo
    self.tbActiveInfo = Table_GetActivityGetRewardlInfoByID(tbRewardInfo.nActivityID)
    self.tbTravelList = ActivityData.GetLinkList(self.tbActiveInfo)
    if tbRewardInfo then
        self:UpdateInfo()
    end
end

function UIPanelFestivalRewardPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelFestivalRewardPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        RemoteCallToServer("On_Activity_LoginReward", self.tbActiveInfo.nActivityID)
    end)

    UIHelper.BindUIEvent(self.BtnLeaveFor, EventType.OnClick, function()
        if self.tbActiveInfo.nActivityID == 633 then
            TipsHelper.ShowNormalTip("剑网3无界端暂不开放此功能")
            return 
        end

        local szPanelLink = self.tbActiveInfo.szPanelLink

        if #self.tbTravelList == 1 then
            local tbInfo = self.tbTravelList[1]
            ActivityData.Teleport_Go(tbInfo, self.tbActiveInfo.nActivityID)
        elseif szPanelLink and szPanelLink ~= "" then
            FireUIEvent("EVENT_LINK_NOTIFY", szPanelLink)
        else
            self:UpdateTravelTargets()
        end
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIPanelFestivalRewardPop:RegEvent()
    Event.Reg(self, EventType.OnSelectLeaveForBtn, function(tbInfo)
        ActivityData.Teleport_Go(tbInfo, self.tbActiveInfo.nActivityID)
        UIHelper.SetVisible(self.WidgetAnchorLeaveFor, false)
    end)

    Event.Reg(self, EventType.OnTouchViewBackGround, function ()
        UIHelper.SetVisible(self.WidgetAnchorLeaveFor, false)
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        UIHelper.SetVisible(self.WidgetAnchorLeaveFor, false)
    end)

    Event.Reg(self, "DO_CUSTOM_OTACTION_PROGRESS", function()
        UIMgr.Close(self)
    end)
end

function UIPanelFestivalRewardPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelFestivalRewardPop:UpdateInfo()

    local bReceived = self.tbRewardInfo.bReceived
    local tbItemList = self.tbRewardInfo.tItem
    local tbOtherRewards = self.tbRewardInfo.tOtherRewards
    local tbSpecialRewards = self.tbRewardInfo.tSpecialRewards

    UIHelper.RemoveAllChildren(self.LayoutRewardHind)
    if tbItemList then
        for nIndex, tbItem in ipairs(tbItemList) do
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.LayoutRewardHind)
            script:OnInitWithTabID(tbItem[1], tbItem[2], tbItem[3])
            script:SetItemReceived(bReceived)
            self:SetClickCallBack(script, tbItem)
        end
    end

    if tbOtherRewards then
        for szName, nCount in pairs(tbOtherRewards) do
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.LayoutRewardHind)
            szName = CurrencyNameToType[szName]
            script:OnInitCurrency(szName, nCount)
            script:SetItemReceived(bReceived)
            self:SetCurrencyClickCallBack(script, szName, nCount)
        end
    end

    if tbSpecialRewards then
        for nIndex, tbRewards in ipairs(tbSpecialRewards) do
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.LayoutRewardHind)
            script:OnInitWithTabID(tbRewards[1], tbRewards[2], tbRewards[3])
            script:SetItemReceived(bReceived)
            self:SetClickCallBack(script, tbRewards)
        end
    end
    UIHelper.SetRichText(self.LabelRewradTips, UIHelper.GBKToUTF8(self.tbActiveInfo.szText))
    UIHelper.LayoutDoLayout(self.LayoutRewardHind)
    UIHelper.LayoutDoLayout(self.LayoutRewardMiddle)

    local bCanReceived = self.tbRewardInfo.bCanReceived
    local nState = (bCanReceived and not bReceived) and BTN_STATE.Normal or BTN_STATE.Disable
    UIHelper.SetButtonState(self.BtnConfirm, nState)

    local szPanelLink = self.tbActiveInfo.szPanelLink
    UIHelper.SetVisible(self.BtnLeaveFor, #self.tbTravelList ~= 0 or (szPanelLink and szPanelLink ~= ""))
    UIHelper.SetSpriteFrame(self.ImgBg, self.tbActiveInfo.szMobileBgPath)
    UIHelper.SetVisible(self.ImgGet, bReceived)
end


function UIPanelFestivalRewardPop:UpdateTravelTargets()
    UIHelper.SetVisible(self.WidgetAnchorLeaveFor, true)
    local scriptView = UIHelper.GetBindScript(self.WidgetAnchorLeaveFor)
    if scriptView and self.tbTravelList then
        scriptView:OnEnter(self.tbTravelList)
    end
end

function UIPanelFestivalRewardPop:SetClickCallBack(script, item)
    script:SetToggleGroupIndex(ToggleGroupIndex.AchievementAward)
    script:SetClickCallback(function()
        local _, scriptItemTip = TipsHelper.ShowItemTips(script._rootNode, item[1], item[2], false)
        scriptItemTip:SetBtnState({})
    end)
end

function UIPanelFestivalRewardPop:SetCurrencyClickCallBack(script, szName, nStackNum)
    script:SetToggleGroupIndex(ToggleGroupIndex.AchievementAward)
    script:SetClickCallback(function()
        local _, scriptItemTip = TipsHelper.ShowCurrencyTips(script._rootNode, szName, nStackNum)
        scriptItemTip:SetBtnState({})
    end)
end


return UIPanelFestivalRewardPop