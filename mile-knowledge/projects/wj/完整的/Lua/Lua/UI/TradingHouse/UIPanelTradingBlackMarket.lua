-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelTradingBlackMarket
-- Date: 2023-03-29 09:18:08
-- Desc: ?
-- ---------------------------------------------------------------------------------
local DELAY_BID_ADD_MONEY_PERCENTAGE = 0.05
local REQUEST_TIME   = 10 * 1000
local DELAY_REQUEST_TIME = 1
local m_nNextLookupTime = 0

local CLICK_INTERVAL = 3

local UIPanelTradingBlackMarket = class("UIPanelTradingBlackMarket")

function UIPanelTradingBlackMarket:OnEnter(nCamp, bWorldBossActivity, bNeuterActivity)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:Init(nCamp, bWorldBossActivity, bNeuterActivity)
end

function UIPanelTradingBlackMarket:OnExit()
    self.bInit = false
    self:UnRegEvent()
    self:EndTimer()
end

function UIPanelTradingBlackMarket:OnViewClose()
    self:EndTimer()
end

function UIPanelTradingBlackMarket:Init(nCamp, bWorldBossActivity, bNeuterActivity)

    self.tbScriptAuctionCellClass = {}
    self.bWorldBossActivity = bWorldBossActivity or false
    self.bNeuterActivity = bNeuterActivity or false
    -- local tbBMDefaultData, nEndTime = self:GetDefaultBMData()
    self.nCurSelectItemID = nil
    self.bInitData = true
    self:SetEndTime(self.nEndTime or 0)
    self:SetBMDataList(self.tbBMDataList or {})

    self:StartTimer()

    self.bUpdated = true
    self.nCamp = nCamp
    self:BMLookUP()
    self.nRequestTime = GetTickCount() + REQUEST_TIME

    UIHelper.SetSwallowTouches(self.ScrolItem, false)
end

function UIPanelTradingBlackMarket:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnAddPrice, EventType.OnClick, function()
        if self.tbCurData then
            local nCurBidMoney = self:GetEditMoney()
            local nRes = TradingData.BMBid(self.tbCurData, math.floor(nCurBidMoney / 10000), self.nCamp)
            if nRes then--出价成功发到服务器才置灰
                UIHelper.SetButtonState(self.BtnAddPrice, BTN_STATE.Disable, function()
                    TipsHelper.ShowNormalTip("您的出价太频繁，请稍后再试")
                end, true)
                Timer.Add(self, CLICK_INTERVAL, function()
                    UIHelper.SetButtonState(self.BtnAddPrice, BTN_STATE.Normal)
                end)
                self.bUpdated = true
            end
        end
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        if self.tbCurData then
            TradingData.BMBidCanCel(self.tbCurData, self.nCamp)
        end
    end)

    UIHelper.BindUIEvent(self.BtnRefresh, EventType.OnClick, function()
        if self:BMLookUP() then
            TipsHelper.ShowNormalTip(g_tStrings.AuctionString.STR_REFRESH)
        else
            TipsHelper.ShowNormalTip(g_tStrings.AuctionString.STR_REFRESH_LATER)
        end
    end)

end

function UIPanelTradingBlackMarket:RegEvent()
    --Event.Reg(self, EventType.XXX, func)

    Event.Reg(self, "BM_LOOKUP_RESPOND", function(nRespondCode, nCamp)
        self.bApplying = false
        if nCamp ~= self.nCamp then return end
        if nRespondCode == AUCTION_RESPOND_CODE.SUCCEED then
            local tbData, nEndTime, nHighestID= TradingData.GetBMDataList(self.nCamp, self.nHighestID, self.nCamp ~= BLACK_MARKET_TYPE.NEUTRAL)
            
            self:SetHighestID(nHighestID)
            -- self:SetDefaultBMData(tbData, nEndTime)
            if self.bInitData then
                self.nCurSelectItemID = nil
                self.bInitData = false
            end

            self:SetEndTime(nEndTime)
            self:SetBMDataList(tbData)

        elseif nRespondCode == AUCTION_RESPOND_CODE.BM_CLOSEID then

        else

		end
    end)

    Event.Reg(self, "BM_BID_RESPOND", function(nRespondCode, nSaleID, nCamp)
        if nCamp ~= self.nCamp then return end
        if nRespondCode == AUCTION_RESPOND_CODE.SUCCEED then
            TipsHelper.ShowNormalTip(g_tStrings.AuctionString.STR_BLACK_MARKET_BID_SUCCESS)
			local tItem = TradingData.GetBidItem(nSaleID, nCamp)
			if tItem then
				local szName = g_pClientPlayer.szName
				if szName == tItem.HighestBidderName then
                    TradingData.SetBidCache(nSaleID, nil)
				else
                    TradingData.SetBidCache(nSaleID, true)
				end
			end
        elseif nRespondCode == AUCTION_RESPOND_CODE.PRICE_TOO_LOW then
            TipsHelper.ShowNormalTip(g_tStrings.AuctionString.STR_BID_LOW)
        else
            TipsHelper.ShowNormalTip(g_tStrings.AuctionString.tAuctionRespond[nRespondCode])
		end
        self:BMLookUP()
    end)

    Event.Reg(self, "BM_BID_CANCEL_RESPOND", function(nRespondCode, nSaleID, nCamp)
        if nCamp ~= self.nCamp then return end 
        if nSaleID then
            TradingData.SetBidCache(nSaleID, nil)
		end
        self:BMLookUP()
    end)


    -- Event.Reg(self, EventType.ON_BM_LOOKUP_SUCCEED, function(tbBMDataList, nEndTime)
    --     self:SetEndTime(nEndTime)
    --     self:SetBMDataList(tbBMDataList)
    -- end)
    Event.Reg(self, EventType.OnTouchViewBackGround, function()
        self:CloseLeftTips()
        self:CloseRightTips()
    end)
end

function UIPanelTradingBlackMarket:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIPanelTradingBlackMarket:StartTimer()
    self.nTimer = Timer.AddFrameCycle(self, 1, function()
        self:OnTimer()
    end)
end

function UIPanelTradingBlackMarket:OnTimer()
    local nTickCount =  GetTickCount()
    if not self.bInDelayBid and self.nRequestTime and nTickCount > self.nRequestTime then
        self:BMLookUP()
        self.nRequestTime = nTickCount + REQUEST_TIME
    end


    if self.bInDelayBid then
        local nTime = GetGSCurrentTime()
        if nTime > m_nNextLookupTime then
            TradingData.BMLookup(self.nCamp)
			m_nNextLookupTime = nTime + DELAY_REQUEST_TIME
		end
    end

    self:UpdateInfo_RemainTime()
end

function UIPanelTradingBlackMarket:EndTimer()
    if self.nTimer then
        Timer.DelTimer(self, self.nTimer)
        self.nTimer = nil
    end
end

function UIPanelTradingBlackMarket:BMLookUP()
    if not self.bApplying then
        TradingData.BMLookup(self.nCamp)
        self.bApplying = true
        return true
    end
    return false
end



-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelTradingBlackMarket:UpdateInfo_BMList()
    self:RemoveChildren()
    for index, tbData in ipairs(self.tbBMDataList) do
        local scriptView = self.tbItemCell[index] and UIHelper.GetBindScript(self.tbItemCell[index]) or nil
        if not scriptView then
            local scriptAuctionCellClass = self.tbScriptAuctionCellClass[#self.tbScriptAuctionCellClass]
            if scriptAuctionCellClass and scriptAuctionCellClass:HasCell() then-- 最后一个WidgetAuctionCellClass预制是否还有子节点没用
                ItemCell = scriptAuctionCellClass:GetAuctionCell()
            else
                local scriptAucCellClass = UIHelper.AddPrefab(PREFAB_ID.WidgetAuctionCellClass, self.LayoutCellBottom)
                table.insert(self.tbScriptAuctionCellClass, scriptAucCellClass)
                ItemCell = scriptAucCellClass:GetAuctionCell()
            end
            table.insert(self.tbItemCell, ItemCell)
            scriptView = UIHelper.GetBindScript(ItemCell)
        end
        tbData.OnSelectCallBack = function(tbData)
            self.nCurSelectItemID = tbData.ID
            self:UpdateInfo_AuctionBid(tbData, true)
        end
        tbData.ShowOrCloseItemTips = function(nTabType, nTabID, scriptView)
            if nTabType and nTabID then
                self:ShowRightTips(nTabType, nTabID, scriptView)
            else
                self:CloseRightTips()
            end
        end
        tbData.nEndTime = self.nEndTime
        tbData.nCamp = self.nCamp
        tbData.nHighestID = self.nHighestID
        tbData.tbBidCache = Storage.TradingHouse.tbBidCache
        scriptView:Init(tbData, index == 1, self.ToggleGroupAuction)--index判断是否是大ItemCell
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupAuctionList, scriptView._rootNode)
        if self.nCurSelectItemID == tbData.ID then
            UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupAuctionList, scriptView._rootNode)
            self:UpdateInfo_AuctionBid(tbData, false)
        end
        UIHelper.SetVisible(scriptView._rootNode, true)
    end

    UIHelper.LayoutDoLayout(self.LayoutCellBottom)
    UIHelper.ScrollViewDoLayout(self.ScrolItem)
    if self.bCanSrollToTop then
        UIHelper.ScrollToTop(self.ScrolItem)
    end
    UIHelper.SetVisible(self.WidgetEmpty, #self.tbBMDataList == 0)

    UIHelper.SetVisible(self.WidgetAniAuctionBid, #self.tbBMDataList ~= 0)
end

function UIPanelTradingBlackMarket:UpdateInfo_AuctionBid(tbData, bSelect)

    self.tbCurData = tbData

    if not self.ItemIconView then
        self.ItemIconView = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.WidgetItem_100)
    end
    self.ItemIconView:OnInitWithTabID(tbData.Item.dwTabType, tbData.Item.dwIndex)
    self.ItemIconView:SetClickCallback(function(nTabType, nTabID)
        if nTabType and nTabID then
            self:ShowLeftTips(nTabType, nTabID, self.ItemIconView)
        else
            self:CloseLeftTips()
        end
    end)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupAuction, self.ItemIconView.ToggleSelect)

    local szItemName = string.format("<color=%s>%s</color>", ItemQualityColor[tbData.Item.nQuality + 1], UIHelper.GBKToUTF8(ItemData.GetItemNameByItem(tbData.Item)))
    UIHelper.SetRichText(self.LabelAuctionItemName, szItemName)

    local nHighestBid, nMyBid, nBaseBid, bOrgBid = TradingData.GetBidData(tbData)
    local scriptBasePrice = UIHelper.GetBindScript(self.LayoutBasePrice)
    scriptBasePrice:OnEnter(nBaseBid)

    local scriptCurrentPrice = UIHelper.GetBindScript(self.WidgetPresentAuctionPrice)
    scriptCurrentPrice:OnEnter(nHighestBid)

    local scriptMyPrice = UIHelper.GetBindScript(self.WidgetPlayerAuctionPrice)
    scriptMyPrice:OnEnter(nMyBid)

    ---限时拍卖，如果当前玩家阵营不满足当前选择的阵营，加价、出价隐藏
    -- local bSameCamp = self.nCamp == BLACK_MARKET_TYPE.NEUTRAL or self.nCamp == BLACK_MARKET_TYPE.ACTIVITY or (self.nCamp == CampToBlackMarketType[g_pClientPlayer.nCamp])
    -- UIHelper.SetVisible(self.WidgetStartAuction, tbData.BidderCount == 0 and bSameCamp)
    -- UIHelper.SetVisible(self.WidgetItemAddPrice, tbData.BidderCount ~= 0 and bSameCamp)
    -- UIHelper.SetVisible(self.WidgetPlayerAuctionPrice, bSameCamp)
    -- if self.LabelAddPrice_Copy then
    --     UIHelper.SetVisible(self.LabelAddPrice_Copy, bSameCamp)
    -- end

    local nBidGold =  TradingData.GetMinBidPrice(tbData)
    local nLeastGold = nBidGold
    if tbData.InDelayBid == 1 then
        nLeastGold = math.ceil(tbData.StartPrice * DELAY_BID_ADD_MONEY_PERCENTAGE) * 10000--LeastGold单位为铜
    end

    local scriptLeastAddPrice = UIHelper.GetBindScript(self.WidgetPresentAuctionPrice_Copy)
    scriptLeastAddPrice:OnEnter(nLeastGold)

    local tbMyMoney = g_pClientPlayer.GetMoney()
    local nAddPrice = math.min(tbMyMoney.nGold * 10000, nBidGold)

    self:UpdateInfo_EidtPrice(nAddPrice, bSelect)

    local szAddPrice = nMyBid == 0 and g_tStrings.AuctionString.STR_FIRST_ADD_MONEY or g_tStrings.AuctionString.STR_ADD_MONEY
    UIHelper.SetString(self.LabelAddPrice, szAddPrice)

    local szState1, szState2 =  TradingData.GetBidState(tbData, self.nCamp, self.bWorldBossActivity, self.bNeuterActivity)

    UIHelper.SetVisible(self.BtnAddPrice, szState2 == "FirstBid" or szState2 == "AddMoney")
    UIHelper.SetVisible(self.BtnCancel, szState1 == "CanCancel")
    UIHelper.LayoutDoLayout(self.LayoutBtns)

    self:UpdateInfo_BtnAddPriceState()
end

function UIPanelTradingBlackMarket:UpdateInfo_RemainTime()
    local szText = ""
    if self.nEndTime ~= 0 then
        local nCurrentTime = GetGSCurrentTime()
        local nTime  = math.max(0, (self.nEndTime - nCurrentTime))
        szText = UIHelper.GetDeltaTimeText(nTime)
    else
        szText = g_tStrings.AuctionString.STR_NOT_STRAT
    end
    UIHelper.SetString(self.LabelAuctionCountdown, szText)
    UIHelper.SetVisible(self.WidgetAuctionTitle, self.nEndTime ~= 0)

    if self.bInDelayBid then--加价阶段
        for index, ItemCell in ipairs(self.tbItemCell) do
            if UIHelper.GetVisible(ItemCell) then
                local scriptView = UIHelper.GetBindScript(ItemCell)
                scriptView:UpdateCountDown()
            end
        end
    end

end

function UIPanelTradingBlackMarket:UpdateInfo_TimeTitle()
    if self.bInDelayBid then
        UIHelper.SetString(self.LabelTargetTimeTitle, g_tStrings.AuctionString.STR_AUCTION_LEFT_TIME_TITLE2)
    else
        UIHelper.SetString(self.LabelTargetTimeTitle, g_tStrings.AuctionString.STR_AUCTION_LEFT_TIME_TITLE1)
    end
end


function UIPanelTradingBlackMarket:UpdateInfo_EidtPrice(nMoney, bSelect)

    local tbMyMoney = g_pClientPlayer.GetMoney()
    local nMyMoney = UIHelper.GoldSilverAndCopperToMoney(tbMyMoney.nGold, tbMyMoney.nSilver, tbMyMoney.nCopper)

    local scriptAddPrice = UIHelper.GetBindScript(self.WidgetPresentAuctionPrice_copy)
    scriptAddPrice:OnEnter(nMoney, nil,
    function(nGold, nSilver, nCopper, nMoney) --每次输入完成的回调
        self:UpdateInfo_BtnAddPriceState()
    end,
    nMyMoney, --输入框允许最大的数目，单位铜
    function()--输入超过最大数目的回调
        TipsHelper.ShowNormalTip("资金不足")
    end, bSelect or (self.bUpdated))

    local scriptBidPrice = UIHelper.GetBindScript(self.WidgetStartAuction)
    scriptBidPrice:OnEnter(nMoney, nil,
    function(nGold, nSilver, nCopper, nMoney)
        self:UpdateInfo_BtnAddPriceState()
    end,
    nMyMoney,
    function()
        TipsHelper.ShowNormalTip("资金不足")
    end, bSelect or (self.bUpdated))

    self.bUpdated = false
end


function UIPanelTradingBlackMarket:UpdateInfo_BtnAddPriceState()
    -- local nCurMoney = self:GetEditMoney()
    -- local nBtnState = TradingData.CanBMBid(self.tbCurData, math.floor(nCurMoney / 10000)) and BTN_STATE.Normal or BTN_STATE.Disable
    -- UIHelper.SetButtonState(self.BtnAddPrice, nBtnState)
end


function UIPanelTradingBlackMarket:RemoveChildren()
    if not self.tbItemCell then self.tbItemCell = {} return end
    for index, Node in ipairs(self.tbItemCell) do
        -- UIHelper.RemoveFromParent(Node)
        UIHelper.SetVisible(Node, false)
    end
    -- self.tbItemCell = {}
end

function UIPanelTradingBlackMarket:SetBMDataList(tbBMDataList)
    self.bCanSrollToTop = true
    if tbBMDataList and self.tbBMDataList and #tbBMDataList == #self.tbBMDataList then--当拍卖物品数量有变时执行ScrollToTop，防止排版乱掉
        self.bCanSrollToTop = false
    end
    self.tbBMDataList = tbBMDataList
    self.nCurSelectItemID = self.nCurSelectItemID or (#tbBMDataList > 0 and tbBMDataList[1].ID or nil)
    self:UpdateInDelayBid()
    self:UpdateInfo_BMList()
end



function UIPanelTradingBlackMarket:GetEditMoney()

    local nCurMoney = 0

    if UIHelper.GetVisible(self.WidgetItemAddPrice) then
        local scriptAddPrice = UIHelper.GetBindScript(self.WidgetPresentAuctionPrice_copy)
        nCurMoney = scriptAddPrice:GetNMoney()
    end

    if UIHelper.GetVisible(self.WidgetStartAuction) then
        local scriptBidPrice = UIHelper.GetBindScript(self.WidgetStartAuction)
        nCurMoney = scriptBidPrice:GetNMoney()
    end
    return nCurMoney
end

function UIPanelTradingBlackMarket:SetEndTime(nEndTime)
    self.nEndTime = nEndTime
    if self.nCamp == 0 then--私货
        TradingData.SetBlackMarketEndTime(nEndTime)
    end
end

function UIPanelTradingBlackMarket:UpdateInDelayBid()
    self.bInDelayBid = false
    for index, tbData in ipairs(self.tbBMDataList) do
        if tbData.InDelayBid == 1 then
            self.bInDelayBid = true
            break
        end
    end
    if self.bInDelayBid then
        m_nNextLookupTime = GetGSCurrentTime() + DELAY_REQUEST_TIME
    end
    self:UpdateInfo_TimeTitle()
end

function UIPanelTradingBlackMarket:ShowLeftTips(nTabType, nTabID, scriptLeft)
    if not self.scriptLeftTips then
        self.scriptLeftTips = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemTipLeft)
    end
    self.scriptLeftTips:OnInitWithTabID(nTabType, nTabID)
    self.scriptLeftTips:SetBtnState({})
    self.nCurLeftView = scriptLeft
    self:CloseRightTips()
end

function UIPanelTradingBlackMarket:CloseLeftTips()
    if self.scriptLeftTips then
        UIHelper.RemoveAllChildren(self.WidgetItemTipLeft)
        self.scriptLeftTips = nil
        self.nCurLeftView:RawSetSelected(false)
    end
end

function UIPanelTradingBlackMarket:ShowRightTips(nTabType, nTabID, scriptRight)
    if not self.scriptRightTips then
        self.scriptRightTips = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemTipRight)
    end
    self.scriptRightTips:OnInitWithTabID(nTabType, nTabID)
    self.scriptRightTips:SetBtnState({})
    self.nCurRightView = scriptRight
    self:CloseLeftTips()
end

function UIPanelTradingBlackMarket:CloseRightTips()
    if self.scriptRightTips then
        UIHelper.RemoveAllChildren(self.WidgetItemTipRight)
        self.scriptRightTips = nil
        self.nCurRightView:RawSetSelected(false)
    end
end


-- function UIPanelTradingBlackMarket:SetDefaultBMData(tbData, nTime)
--     self.tbData, self.nTime = tbData, nTime
-- end

-- function UIPanelTradingBlackMarket:GetDefaultBMData()
--     return self.tbData, self.nTime
-- end

function UIPanelTradingBlackMarket:SetHighestID(nHighestID)
    self.nHighestID = nHighestID
end

return UIPanelTradingBlackMarket