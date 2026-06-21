-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetAuctionStatsItem
-- Date: 2023-02-14 20:15:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetAuctionStatsItem = class("UIWidgetAuctionStatsItem")

function UIWidgetAuctionStatsItem:OnEnter(tData)
    if not tData then
        return
    end
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tData = tData
    self.tBidInfo = tData.tBidInfo
    self.bDeleteState = tData.bDeleteState
    self:UpdateInfo()
end

function UIWidgetAuctionStatsItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIWidgetAuctionStatsItem:BindUIEvent()
    UIHelper.BindUIEvent(self.TogMulti, EventType.OnSelectChanged, function (_, bSelected)
        self.tData.fOnDeleteRecordSeleted(self.tBidInfo, bSelected)
    end)

    UIHelper.BindUIEvent(self.BtnPay, EventType.OnClick, function ()
        local tBidInfo = self.tBidInfo
        local nPrice = tBidInfo.nPrice - tBidInfo.nPaidMoney
        local tData = {
            nBrick = math.floor(nPrice / 10000),
            nGold  = nPrice % 10000,
            dwPlayerID = tBidInfo.dwDestPlayerID,
        }
        local szMoney, szItemName, szDestPlayerName = AuctionData.GetStartBiddingConfirmContent(self.tBidInfo.dwItemID, tData)
        local szMsg = ""
        if tData.nBrick == 0 and tData.nGold == 0 then
            szMsg = string.format("你确认获取[%s]吗？", szItemName)
        elseif tBidInfo.dwItemID and tBidInfo.dwItemID > 0 then
            szMsg = string.format("你确认以%s购买[%s]吗？", szMoney, szItemName)
        else
            szMsg = string.format("你确认缴纳[%s]吗？", szMoney)
        end
        if tBidInfo.dwDestPlayerID ~= UI_GetClientPlayerID() then
            if tBidInfo.dwItemID and tBidInfo.dwItemID > 0 then
                szMsg = string.format("你确认以%s为[%s]购买[%s]吗？", szMoney, szDestPlayerName, szItemName)
            else
                szMsg = string.format("你确认为[%s]缴纳[%s]吗？", szDestPlayerName, szMoney)
            end
        end
        UIHelper.ShowConfirm(szMsg, function ()
            AuctionData.TryPay(self.tBidInfo)
        end, nil, true)
    end)

    UIHelper.BindUIEvent(self.BtnPayFor, EventType.OnClick, function ()
        local tBidInfo = self.tBidInfo
        local nPrice = tBidInfo.nPrice - tBidInfo.nPaidMoney
        local tData = {
            nBrick = math.floor(nPrice / 10000),
            nGold  = nPrice % 10000,
            dwPlayerID = tBidInfo.dwDestPlayerID,
        }
        local szMoney, szItemName, szDestPlayerName = AuctionData.GetStartBiddingConfirmContent(self.tBidInfo.dwItemID, tData)
        szDestPlayerName = szDestPlayerName or UIHelper.GBKToUTF8(tBidInfo.szDestPlayerName)
        local szMsg = ""
        if tBidInfo.dwItemID and tBidInfo.dwItemID > 0 then
            szMsg = string.format("你确认以%s为[%s]购买[%s]吗？", szMoney, szDestPlayerName, szItemName)
        else
            szMsg = string.format("你确认为[%s]缴纳[%s]吗？", szDestPlayerName, szMoney)
        end
        UIHelper.ShowConfirm(szMsg, function ()
            AuctionData.TryPay(self.tBidInfo)
        end, nil, true)
    end)

    UIHelper.BindUIEvent(self.BtnEdit, EventType.OnClick, function ()
        Event.Dispatch(EventType.OnEditAuctionRecord, self.tBidInfo)        
    end)
end

function UIWidgetAuctionStatsItem:RegEvent()
    Event.Reg(self, "BIDDING_OPERATION", function (eBidOperationType, dwOperatorPlayerID, nBidInfoIndex, nOperationTimestamp)
        local teamBidMgr = GetTeamBiddingMgr()
        local tBidInfo = teamBidMgr.GetBiddingInfo(nBidInfoIndex)
        if self.tBidInfo.nBiddingInfoIndex == nBidInfoIndex then
            self.tBidInfo = tBidInfo
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, "TEAM_AUTHORITY_CHANGED", function (nAuthorityType)
        if nAuthorityType == TEAM_AUTHORITY_TYPE.DISTRIBUTE then
            self:UpdateInfo()
        end
    end)
end

function UIWidgetAuctionStatsItem:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetAuctionStatsItem:UpdateInfo()
    local tBidInfo = self.tBidInfo
    local szItemName = "金钱"
    local itemInfo = GetItemInfo(tBidInfo.dwItemTabType, tBidInfo.dwItemTabIndex)
    if itemInfo then
        self.scriptIcon = self.scriptIcon or UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem)
        if self.scriptIcon then
            self.scriptIcon:OnInitWithTabID(tBidInfo.dwItemTabType, tBidInfo.dwItemTabIndex)
            self.scriptIcon:SetClickCallback(function (nItemType, nItemIndex)
                local _, scriptItemTip = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, self.scriptIcon._rootNode)
                scriptItemTip:SetFunctionButtons({})
                local item = GetItem(tBidInfo.dwItemID)
                if item then
                    scriptItemTip:OnInitWithItemID(tBidInfo.dwItemID)
                else
                    scriptItemTip:OnInitWithTabID(tBidInfo.dwItemTabType, tBidInfo.dwItemTabIndex)
                end            
            end)
            UIHelper.SetToggleGroupIndex(self.scriptIcon.ToggleSelect, ToggleGroupIndex.DungeonDropItem)
        end
        local nBookInfo
        if itemInfo.nGenre == ITEM_GENRE.BOOK then
            nBookInfo = itemInfo.nDurability
        end
        szItemName = ItemData.GetItemNameByItemInfo(itemInfo, nBookInfo)
        szItemName = UIHelper.GBKToUTF8(szItemName)
    else
        UIHelper.RemoveAllChildren(self.WidgetItem)
    end

    UIHelper.SetVisible(self.ImgMoney, itemInfo == nil)
    UIHelper.SetString(self.LabelItemName, szItemName, 10)

    local destPlayerName = tBidInfo.szDestPlayerName    
    destPlayerName = UIHelper.GBKToUTF8(destPlayerName)    
    UIHelper.SetString(self.LabelGetterPlayerName, destPlayerName, 8)

    local team = GetClientTeam()
    local tMemberInfo = team.GetMemberInfo(tBidInfo.dwDestPlayerID)
    if tMemberInfo then
        local szImagePath = PlayerForceID2SchoolImg2[tMemberInfo.dwForceID]
        UIHelper.SetSpriteFrame(self.ImgSchool, szImagePath)
    end

    UIHelper.SetString(self.LabelMoney_Zhuan, tostring(math.floor(tBidInfo.nPrice / 10000)))
    UIHelper.SetString(self.LabelMoney_Jin, tostring(tBidInfo.nPrice % 10000))

    local nRemainGold = tBidInfo.nPrice - tBidInfo.nPaidMoney
    UIHelper.SetString(self.LabelRemainMoney_Zhuan, tostring(math.floor(nRemainGold / 10000)))
    UIHelper.SetString(self.LabelRemainMoney_Jin, tostring(nRemainGold % 10000))    

    local szDoodadName = AuctionData.GetDropItemSourceName({
        dwNpcTemplateID = tBidInfo.dwNpcTemplateID,
        nDoodadID = tBidInfo.dwDoodadID,
    }, "追加")
    UIHelper.SetString(self.LabelSourceDetail, szDoodadName)

    local nLeftTime = GetCurrentTime() - tBidInfo.nStartTime
    local szTime = UIHelper.GetHeightestTimeText(nLeftTime)..g_tStrings.STR_QIAN
    UIHelper.SetString(self.LabelDistributionTimeNum, szTime)

    local szComment = UIHelper.GBKToUTF8(tBidInfo.szComment)
    szComment = string.gsub(szComment, "\n", " ")
    UIHelper.SetString(self.LabelRemarkDetail, szComment, 16)

    if tBidInfo.dwPayerID and tBidInfo.dwPayerID > 0 then
        local szPayerName = UIHelper.GBKToUTF8(tBidInfo.szPayerName)
        UIHelper.SetString(self.LabelPayerName, szPayerName, 8)
        local tPayerInfo = team.GetMemberInfo(tBidInfo.dwPayerID)
        if tPayerInfo then
            local szImagePath = PlayerForceID2SchoolImg2[tPayerInfo.dwForceID]
            UIHelper.SetSpriteFrame(self.ImgPayerSchool, szImagePath)
        end
    end

    UIHelper.SetSelected(self.TogMulti, self.tData.bSelected)

    local player = GetClientPlayer()
    local bNeedPay = tBidInfo.nState == BIDDING_INFO_STATE.WAIT_PAYMENT
    local bPaid = tBidInfo.nState == BIDDING_INFO_STATE.PAID
    local bInvaid = tBidInfo.nState == BIDDING_INFO_STATE.INVALID
    local bDestPlayer = player.dwID == tBidInfo.dwDestPlayerID
    local bDistributer = AuctionData.IsDistributeMan()
    local bDeleteState = self.bDeleteState and (tBidInfo.nState == BIDDING_INFO_STATE.PAID or tBidInfo.nState == BIDDING_INFO_STATE.INVALID)
    UIHelper.SetVisible(self.BtnPayFor, bNeedPay and not bDestPlayer)
    UIHelper.SetVisible(self.BtnPay, bNeedPay and bDestPlayer)
    UIHelper.SetVisible(self.BtnEdit, bDistributer and bNeedPay)
    UIHelper.SetVisible(self.WidgetPaid, bPaid)
    UIHelper.SetVisible(self.WidgetInvalid, bInvaid)
    UIHelper.SetVisible(self.TogMulti, bDeleteState)
    UIHelper.SetVisible(self.LayoutToPay, bNeedPay and nRemainGold > 0)
    
    UIHelper.LayoutDoLayout(UIHelper.GetParent(self.BtnEdit))
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutContent, true, true)
end

return UIWidgetAuctionStatsItem