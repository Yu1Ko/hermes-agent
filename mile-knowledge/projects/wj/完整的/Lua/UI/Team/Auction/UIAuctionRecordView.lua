-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIAuctionRecordView
-- Date: 2023-02-14 20:15:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIAuctionRecordView = class("UIAuctionRecordView")

function UIAuctionRecordView:OnEnter(tParam)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.scriptAuction = UIHelper.GetBindScript(self.WidgetContentAuction)
    if not self.WidgetDistributionRecord then
        self.scriptDistribution = UIHelper.AddPrefab(PREFAB_ID.WidgetDistributionRecord, self.WidgetAniShell)
        self.WidgetDistributionRecord = self.scriptDistribution._rootNode
    end
    self.scriptDistribution = self.scriptDistribution or UIHelper.GetBindScript(self.WidgetDistributionRecord)
    self.scriptDistribution:HidePanel(false)
    self.scriptDistribution:SetShowPanelCallback(function ()
        UIHelper.PlayAni(self, self.AniAll, "AniBottomHide", function ()
            UIHelper.SetVisible(self.ToggleGroupNavigation, false)
        end)
    end)
    self.scriptDistribution:SetHidePanelCallback(function ()
        UIHelper.SetVisible(self.ToggleGroupNavigation, true)
        UIHelper.PlayAni(self, self.AniAll, "AniBottomShow")
    end)
    self:UpdateInfo()

    if tParam and tParam.tVoteInfo then
        self.scriptSalaryPage:OnVote(tParam.tVoteInfo)
        self:Redirect(2)
    end
end

function UIAuctionRecordView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAuctionRecordView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnChat, EventType.OnClick, function ()
        if UIMgr.IsViewOpened(VIEW_ID.PanelChatSocial, true) then
            UIMgr.CloseWithCallBack(VIEW_ID.PanelChatSocial, function ()
                ChatHelper.Chat(UI_Chat_Channel.Team)
            end)
        else
            ChatHelper.Chat(UI_Chat_Channel.Team)
        end        
    end)

    UIHelper.BindUIEvent(self.BtnMemberOption, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelMarkMemberPop)
    end)

    UIHelper.BindUIEvent(self.TogNavigationRecord, EventType.OnSelectChanged, function (_, bSelected)
        UIHelper.SetVisible(self.scriptBidInfoPage._rootNode, bSelected)
    end)

    UIHelper.BindUIEvent(self.TogNavigationSalary, EventType.OnSelectChanged, function (_, bSelected)
        UIHelper.SetVisible(self.scriptSalaryPage._rootNode, bSelected)
        UIHelper.SetVisible(self.LayoutCurrentBonus, bSelected)
        UIHelper.SetVisible(self.LayoutMemberTotal, bSelected)
        
        self:RefreshSubsidy()
    end)

    UIHelper.BindUIEvent(self.TogNavigationOperate, EventType.OnSelectChanged, function (_, bSelected)
        UIHelper.SetVisible(self.scriptOperatePage._rootNode, bSelected)
    end)
end

function UIAuctionRecordView:RegEvent()
    Event.Reg(self, EventType.OnEditAuctionRecord, function (tBidInfo)
        self.scriptDistribution:OnEnterWithBidInfo(tBidInfo, true, function (tData)
            self:OnEditAuctionRecord(tBidInfo, tData)
        end)
        
        self.scriptDistribution:ShowPanel(true)
    end)

    Event.Reg(self, EventType.OnSalaryDataChanged, function ()
        Timer.AddFrame(self, 1, function ()
            self:RefreshDistributableAndUnpaidMoney()
            self:RefreshSubsidy()
        end)
    end)

    Event.Reg(self, "ON_SYNC_TEAMERS_PAY", function () -- 工资同步
        Timer.AddFrame(self, 1, function ()
            self:RefreshDistributableAndUnpaidMoney()
            self:RefreshSubsidy()
        end)
    end)

    Event.Reg(self, "ON_SEND_TEAM_MONEY", function () -- 工资发放
        Timer.AddFrame(self, 1, function ()
            self:RefreshDistributableAndUnpaidMoney()
            self:RefreshSubsidy()
        end)
    end)

    Event.Reg(self, "BIDDING_OPERATION", function (eBidOperationType, dwOperatorPlayerID, nBidInfoIndex, nOperationTimestamp)
        Timer.AddFrame(self, 1, function ()
            self:RefreshDistributableAndUnpaidMoney()
            self:RefreshSubsidy()
        end)
    end)

    Event.Reg(self, "PARTY_LOOT_MODE_CHANGED", function()
        if arg1 ~= PARTY_LOOT_MODE.BIDDING then
            UIMgr.Close(self)
            UIMgr.Close(VIEW_ID.PanelAddIncomePop)
        end
    end)
end

function UIAuctionRecordView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIAuctionRecordView:UpdateInfo()
    local szInfo = "拍团记录-%s-%s-%s-%s"
    local scene = GetClientScene()
    local szMapName = scene and UIHelper.GBKToUTF8(Table_GetMapName(scene.dwMapID)) or g_tStrings.STR_QUESTION_M
    local szYear = os.date("%Y");
    local szMonth = os.date("%m");
    local szMonthDay = os.date("%d");
    szInfo = string.format(szInfo, szMapName, szYear, szMonth, szMonthDay)
    UIHelper.SetString(self.LabelRecordInfo, szInfo)

    -- 拍卖统计
    self.scriptBidInfoPage = self.scriptBidInfoPage or UIHelper.AddPrefab(PREFAB_ID.WidgetAuctionStatsPage, self.WidgetAnchorMiddle)
    local fAddRecord = function ()
        self:OpenAddRecordPanel()
    end
    local fOnDeleteRecord = function (bDeleteState)
        UIHelper.SetVisible(self.LayoutBottomLeft, not bDeleteState)
        UIHelper.SetVisible(UIHelper.GetParent(self.TogNavigationOperate), not bDeleteState)
    end
    self.scriptBidInfoPage:OnEnter(fAddRecord, fOnDeleteRecord)
    local bVisible = UIHelper.GetSelected(self.TogNavigationRecord)
    UIHelper.SetVisible(self.scriptBidInfoPage._rootNode, bVisible)
    -- 收入分配
    self.scriptSalaryPage = self.scriptSalaryPage or UIHelper.AddPrefab(PREFAB_ID.WidgetSalaryPayPage, self.WidgetAnchorMiddle)
    local tData = {}
    self.scriptSalaryPage:OnEnter(tData)
    local bVisible = UIHelper.GetSelected(self.TogNavigationSalary)
    UIHelper.SetVisible(self.scriptSalaryPage._rootNode, bVisible)

    local player = GetClientPlayer()
    local clientTeam = GetClientTeam()
    local dwDistributerID = clientTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE)
    local bDistributer = dwDistributerID == player.dwID

    UIHelper.SetVisible(self.BtnMemberOption, bDistributer)
    -- 可分配收入和待分配收入
    self:RefreshDistributableAndUnpaidMoney()
    self:RefreshSubsidy()

    -- 操作记录
    self.scriptOperatePage = self.scriptOperatePage or UIHelper.AddPrefab(PREFAB_ID.WidgetOperRecordPage, self.WidgetAnchorMiddle)
    local tData = {}
    self.scriptOperatePage:OnEnter(tData)
    local bVisible = UIHelper.GetSelected(self.TogNavigationOperate)
    UIHelper.SetVisible(self.scriptOperatePage._rootNode, bVisible)
end

function UIAuctionRecordView:RefreshDistributableAndUnpaidMoney()
    local nDistribSum, nUnpaidSum = AuctionData.GetAllDistributableAndUnpaidMoney()
    UIHelper.SetString(self.LabelDistributeZhuan, tostring(math.floor(nDistribSum/10000)))
    UIHelper.SetString(self.LabelDistributeJin, tostring(math.floor(nDistribSum%10000)))
    UIHelper.SetString(self.LabelUnpaidZhuan, tostring(math.floor(nUnpaidSum/10000)))
    UIHelper.SetString(self.LabelUnpaidJin, tostring(math.floor(nUnpaidSum%10000)))
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutBottomLeft, true, true)
end

function UIAuctionRecordView:RefreshSubsidy()
    AuctionData.FixTeamerData()
    
    local nTotalSubsidies = AuctionData.GetTotalSubsidies()
    local nSelected = table.GetCount(AuctionData.tCheckTeamers)

    UIHelper.SetString(self.LabelSubsidyZhuan, tostring(math.floor(nTotalSubsidies/10000)))
    UIHelper.SetString(self.LabelSubsidyJin, tostring(nTotalSubsidies%10000))
    UIHelper.SetString(self.LabelMemberTotalNum, tostring(nSelected))
    UIHelper.SetVisible(self.LayoutBottomLeft, AuctionData.dwVoteStartTime == nil)
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutBottomLeft, true, true)
end

function UIAuctionRecordView:OnEditAuctionRecord(tBidInfo, tData)
    local szMoney, szItemName, szPlayerName = AuctionData.GetStartBiddingConfirmContent(tBidInfo.dwItemID, tData)
    local szContent = string.format("你确认以%s将[%s]分配给[%s]吗？", szMoney, szItemName, szPlayerName)
    UIHelper.ShowConfirm(szContent, function ()
        AuctionData.Rebidding(tBidInfo, tData.nBrick, tData.nGold, tData.szComment, tData.dwPlayerID)
    end, nil, true)
end

function UIAuctionRecordView:OpenAddRecordPanel()
    self.scriptDistribution:OnEnterWithDoodadID(0, true, function (tData)
        local szMoney = ShopData.GetPriceRichText(tData.nBrick, tData.nGold, 0, 0)
        local szPlayerName = UIHelper.GBKToUTF8(TeamData.GetTeammateName(tData.dwPlayerID))
        local szContent = string.format("你确认向%s收取%s吗？", szPlayerName, szMoney)
        UIHelper.ShowConfirm(szContent, function ()
            --- 对应于罚款
            local nGolds = tData.nBrick*10000 + tData.nGold
            AuctionData.AddPenaltyRecord(tData.dwPlayerID, nGolds, tData.szComment)
        end,nil, true)
    end)
    self.scriptDistribution:ShowPanel(true)
end

function UIAuctionRecordView:Redirect(nPageIndex)
    UIHelper.SetSelected(self.TogNavigationRecord, nPageIndex == 1)
    UIHelper.SetSelected(self.TogNavigationSalary, nPageIndex == 2)
    UIHelper.SetSelected(self.TogNavigationOperate, nPageIndex == 3)

    UIHelper.SetVisible(self.scriptBidInfoPage._rootNode, nPageIndex == 1)
    UIHelper.SetVisible(self.scriptSalaryPage._rootNode, nPageIndex == 2)
    UIHelper.SetVisible(self.scriptOperatePage._rootNode, nPageIndex == 3)
    
    UIHelper.SetVisible(self.LayoutCurrentBonus, true)
    UIHelper.SetVisible(self.LayoutMemberTotal, true)

    self:RefreshSubsidy()
end

return UIAuctionRecordView