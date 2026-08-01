-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetAuctionItemCell
-- Date: 2023-03-29 10:02:22
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetAuctionItemCell = class("UIWidgetAuctionItemCell")

function UIWidgetAuctionItemCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetAuctionItemCell:Init(tbData, bBig, ToggleGroup)
    self.tbData = tbData
    self.bBig = bBig
    self.ToggleGroup = ToggleGroup
    self:UpdateInfo()
end

function UIWidgetAuctionItemCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetAuctionItemCell:BindUIEvent()
    UIHelper.BindUIEvent(self._rootNode, EventType.OnSelectChanged, function(toggle, bSelect)
        if bSelect then
            self.tbData.OnSelectCallBack(self.tbData)
        end
    end)
end

function UIWidgetAuctionItemCell:RegEvent()

end

function UIWidgetAuctionItemCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetAuctionItemCell:UpdateInfo()
    
    UIHelper.SetVisible(self._rootNode, true)
    if not self.ItemIconView then
        self.ItemIconView = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem_80)
    end
    self.ItemIconView:OnInitWithTabID(self.tbData.Item.dwTabType, self.tbData.Item.dwIndex)
    self.ItemIconView:SetClickCallback(function(nTabType, nTabID)
        self.tbData.ShowOrCloseItemTips(nTabType, nTabID, self.ItemIconView)
    end)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroup, self.ItemIconView.ToggleSelect)

    local szItemName = string.format("<color=%s>%s</color>", ItemQualityColor[self.tbData.Item.nQuality + 1], UIHelper.GBKToUTF8(ItemData.GetItemNameByItem(self.tbData.Item)))
    UIHelper.SetRichText(self.LabelAuctionItemName, szItemName)
    UIHelper.SetString(self.LabelAuctionItemType, TradingData.GetAuctionTypeName(self.tbData.Item))

    if self.bBig then
        local szHighestBidderName = self.tbData.HighestBidderName ~= "" and UIHelper.GBKToUTF8(self.tbData.HighestBidderName) or g_tStrings.AuctionString.STR_AUCTION_NO_ONE_BID
        UIHelper.SetString(self.LabelPlayerName, szHighestBidderName)
    end

    local nHighestBid, nMyBid, nBaseBid, bOrgBid = TradingData.GetBidData(self.tbData)
    local scriptView = UIHelper.GetBindScript(self.WidgetAuctionPrice)
    scriptView:OnEnter(nHighestBid)

    local szText = FormatString(g_tStrings.AuctionString.STR_MANY_BIDDER1, self.tbData.BidderCount)
    UIHelper.SetString(self.LabelAuctionPlayerNum, szText)
    UIHelper.SetVisible(self.WidgetAuctionPlayerNum, self.tbData.BidderCount > 0)
    UIHelper.SetVisible(self.WidgetAuctionHighest, g_pClientPlayer.szName == self.tbData.HighestBidderName)
    UIHelper.SetVisible(self.WidgetAuctionOverValence, nMyBid > 0 and nMyBid < nHighestBid)
    UIHelper.SetVisible(self.WidgetAuctionDeclinePrice, nMyBid <= nHighestBid and bOrgBid)

    UIHelper.SetVisible(self.WidgetRareIcon, self.tbData.nRareness and self.tbData.nRareness > 0)--稀有
    UIHelper.SetVisible(self.WidgetAuctionCountdown, self.tbData.InDelayBid == 1)

    local bShowOverValence = UIHelper.GetVisible(self.WidgetAuctionOverValence)
    local bShowHighest = UIHelper.GetVisible(self.WidgetAuctionHighest)
    local bShowPlayerNum = UIHelper.GetVisible(self.WidgetAuctionPlayerNum)
    local bShowDeclinePrice = UIHelper.GetVisible(self.WidgetAuctionDeclinePrice)

    local bBlackMarket = self.tbData.nCamp == BLACK_MARKET_TYPE.NEUTRAL
    local bHot = (bBlackMarket and self.bBig) or (not bBlackMarket and self.tbData.nHighestID == self.tbData.ID)

    UIHelper.SetVisible(self.ImgHot, bHot)

    UIHelper.SetVisible(self.WidgetAuctionState, bShowOverValence or bShowHighest or bShowPlayerNum or bShowDeclinePrice)

    UIHelper.CascadeDoLayoutDoWidget(self.WidgetAuctionState, true, true)

    UIHelper.LayoutDoLayout(self.WidgetAuctionInfo)

    UIHelper.SetSwallowTouches(self._rootNode, false)
end


function UIWidgetAuctionItemCell:UpdateCountDown()
    if self.tbData.InDelayBid == 1 then--加价
        local nTime = math.min(self.tbData.OverBidTime,  self.tbData.nEndTime)
        UIHelper.SetString(self.LabelAuctionCountdown, math.max(0, (nTime - GetGSCurrentTime())) .. g_tStrings.STR_BUFF_H_TIME_S_SHORT)
    end
end

return UIWidgetAuctionItemCell