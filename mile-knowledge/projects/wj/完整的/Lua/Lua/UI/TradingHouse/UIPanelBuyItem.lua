-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelBuyItem
-- Date: 2023-03-13 16:00:36
-- Desc: ?
-- ---------------------------------------------------------------------------------
local MAX_PRICE_COPPER = 500000000000
local UIPanelBuyItem = class("UIPanelBuyItem")

function UIPanelBuyItem:OnEnter(nPanelType)
    self.nPanelType = nPanelType--BindUIEvent会用到，所以写在这
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    --self:DrawChart()
end



function UIPanelBuyItem:InitBuy(nBox, nIndex, tbItem)
    self.nBox = nBox
    self.nIndex = nIndex
    TradingData.NewDayUpdate()
    self:SetDescendingOrder(0, true)

    if self.nBox and self.nIndex then
        self:SetItemByBox(self.nBox, self.nIndex)
    else
        self:SetItemByItem(tbItem)
    end

    local nMaxPage = TradingData.GetPriceListMaxPage()

    self:SetPerItemPrice({["nGold"] = 0, ["nSilver"] = 0, ["nCopper"] = 0})
    self:SetMaxPage(nMaxPage or 1)
    self:SetCurPage(1, true, nMaxPage ~= nil)
    self:SetItemNum(1)
    self:SetMaxItemNum()
    self:SetHistoryPrice(0)
    self:UpdateInfo_MyMoney()
    self:UpdateGoodInfo()
end

function UIPanelBuyItem:InitSell(nBox, nIndex)

    self.nBox = nBox
    self.nIndex = nIndex
    TradingData.NewDayUpdate()
    self:SetDescendingOrder(0, true)
    self:SetItemByBox(self.nBox, self.nIndex)

    local tbLastSellPrice = TradingData.GetLastSellInfo(self.tbItem)
    self:SetPerItemPrice(tbLastSellPrice.tbPrice or {["nGold"] = 0, ["nSilver"] = 0, ["nCopper"] = 0})

    self:SetMaxPage(1)
    self:SetCurPage(1, true)

    local nItemNum = TradingData.GetSellItemCount(self.tbItem)
    self:SetItemNum(nItemNum or 1)

    local nDefaultSaveTime = tonumber(string.sub(g_tStrings.AuctionString.tAuctionTime[1], 1, 2))
    self:SetSaveTime(nDefaultSaveTime)

    self:UpdateInfo_SellSaveTime()
    self:SetMaxItemNum()
    self:SetHistoryPrice(0)
    self:UpdateInfo_MyMoney()
end


function UIPanelBuyItem:InitChangePrice(tbInfo)
    self.dwSaleID = tbInfo.ID
    self:SetDescendingOrder(0, true)
    self:SetItemByItem(tbInfo.Item)
    self:SetPerItemPrice(tbInfo and tbInfo.Price or {["nGold"] = 0, ["nSilver"] = 0, ["nCopper"] = 0})
    self:SetMaxPage(1)
    self:SetCurPage(1, true)
    self:SetItemNum(tbInfo and tbInfo.StackNum or 1)

    local nDefaultSaveTime = tonumber(string.sub(g_tStrings.AuctionString.tAuctionTime[1], 1, 2))
    self:SetSaveTime(tbInfo and tbInfo.LastDurationTime or nDefaultSaveTime)

    -- self:UpdateInfo_ChangePriceSaveTime()
    self:UpdateInfo_SellSaveTime()
    self:SetMaxItemNum()
    self:SetHistoryPrice(0)
    self:UpdateInfo_MyMoney()
end

function UIPanelBuyItem:OnExit()
    TradingData.ClearPriceList()
    if self.nPanelType == TRADING_ITEM_PANEL.BUY then
        Event.Dispatch(EventType.OnBuyItemClose)
    end
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelBuyItem:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnMail, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelEmail)
    end)

    UIHelper.BindUIEvent(self.BtnBuyOrSell, EventType.OnClick, function()
        if PropsSort.IsBagInSort() then
            TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_TRADE_ITEM_INSORT)
            return
        end

        if self.nPanelType == TRADING_ITEM_PANEL.BUY then
            TradingData.TryBuyItem(self.nItemNum, self.tbPerItemPrice, self.nTotalCost, self.tbItem)
        end
        if self.nPanelType == TRADING_ITEM_PANEL.SELL then
            TradingData.TrySellItem(self.nBox, self.nIndex, self.tbPerItemPrice, self.nItemNum, self.nSaveMoney, self.nTotalInCome, self.nSaveTime)
            -- UIMgr.Close(self)
        end

        if self.nPanelType == TRADING_ITEM_PANEL.CHANGE then
            TradingData.ChangeItemPrice(self.tbItem, self.tbPerItemPrice, self.nItemNum, self.nSaveMoney, self.nTotalInCome, self.nSaveTime, self.dwSaleID)
            -- UIMgr.Close(self)
        end
    end)


    UIHelper.BindUIEvent(self.BtnLeft, EventType.OnClick, function()
        local nPage = self.nCurPage - 1
        self:SetCurPage(nPage)
    end)

    UIHelper.BindUIEvent(self.BtnRight, EventType.OnClick, function()
        local nPage = self.nCurPage + 1
        self:SetCurPage(nPage)
    end)

    UIHelper.BindUIEvent(self.BtnRefresh, EventType.OnClick, function()
        TradingData.ApplyPriceLookUp(true, self.tbItem, self.nCurPage, self.nDescendingOrder)
    end)

    UIHelper.BindUIEvent(self.BtnListDetail, EventType.OnClick, function()
        self:TryOpenDetailList()
    end)

    UIHelper.BindUIEvent(self.BtnPriceChart, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelPriceTrendChartPop, self.nHistoryLen, self.tbPriceData, self.nHistoryMax, self.nHistoryMin, self.nAvgPrice)
    end)

    if self.nPanelType ~= TRADING_ITEM_PANEL.CHANGE then
        UIHelper.BindUIEvent(self.BtnSubtract, EventType.OnClick, function()
            local nItemNum = (self.nItemNum - 1 >= 1) and self.nItemNum - 1 or self.nItemNum
            self:SetItemNum(nItemNum)
        end)

        UIHelper.BindUIEvent(self.BtnPlus, EventType.OnClick, function()
            local nItemNum = math.min(self.nItemNum + 1, self.nMaxItemNum)
            self:SetItemNum(nItemNum)
        end)

        UIHelper.BindUIEvent(self.BtnMax, EventType.OnClick, function()
            self:SetItemNum(self.nMaxItemNum)
        end)

        if Platform.IsWindows() or Platform.IsMac() then
            UIHelper.RegisterEditBoxEnded(self.WidgetEdit, function()
                self:OnEditBuyNumEnded()
            end)
        else
            UIHelper.RegisterEditBoxReturn(self.WidgetEdit, function()
                self:OnEditBuyNumEnded()
            end)
        end

        UIHelper.BindUIEvent(self.BtnTab, EventType.OnClick, function()
            self:OpenOrCloseBag()
        end)

    end

    if self.nPanelType == TRADING_ITEM_PANEL.SELL then
        UIHelper.BindUIEvent(self.Tog12Hours, EventType.OnSelectChanged, function(toggle, bSelect)
            if bSelect then
                self:SetSaveTime(12)
            end
        end)

        UIHelper.BindUIEvent(self.Tog24Hours, EventType.OnSelectChanged, function(toggle, bSelect)
            if bSelect then
                self:SetSaveTime(24)
            end
        end)

        UIHelper.BindUIEvent(self.Tog48Hours, EventType.OnSelectChanged, function(toggle, bSelect)
            if bSelect then
                self:SetSaveTime(48)
            end
        end)
    end

    if self.nPanelType ~= TRADING_ITEM_PANEL.BUY then
        UIHelper.BindUIEvent(self.TogRewardTips,  EventType.OnSelectChanged, function(toggle, bSelect)
            if bSelect then
                local scriptView = UIHelper.GetBindScript(self.LayoutCustodyFee)
                scriptView:OnEnter(self.nSaveMoney)
                local scriptView2 = UIHelper.GetBindScript(self.LayoutTradeFee)
                scriptView2:OnEnter(self.nChargeMoney)
            end
        end)
    end



    UIHelper.BindUIEvent(self.BtnSinglePrice, EventType.OnClick, function(toggle, bSelect)
        self:SetDescendingOrder((self.nDescendingOrder + 1) % 2)
    end)

    if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditPaginate, function(_editbox)
            local nPage = UIHelper.GetText(_editbox)
            self:SetCurPage(nPage)
        end)
    else
        UIHelper.RegisterEditBoxReturn(self.EditPaginate, function(_editbox)
            local nPage = UIHelper.GetText(_editbox)
            self:SetCurPage(nPage)
        end)
    end


end


function UIPanelBuyItem:RegEvent()

    Event.Reg(self, EventType.ON_AVG_LOOK_UP_RES, function(nLength, tbPriceData, tbMinPrice, tbMaxPrice, nMaxCopper, nMinCopper, tbAvgPrice)
        self:SetHistoryPrice(nLength, tbPriceData, tbMaxPrice, tbMinPrice, nMaxCopper, nMinCopper, tbAvgPrice)
    end)

    Event.Reg(self, EventType.ON_PRICE_LOOK_UP, function(nTotalCount, tbGoodInfo)

        if self.bOpenBuyView then
            if nTotalCount ~= 0 then
                self:OpenBuyView(self.nSelectItemBox, self.nSelectItemIndex)
            else
                TipsHelper.ShowNormalTip("当前物品无在售")
            end
            self.bOpenBuyView = false
            return
        end

        self:UpdateGoodInfo()
        if nTotalCount ~= 0 then
            self:SetMaxPage(nTotalCount)
        end
    end)

    Event.Reg(self, EventType.OnSelectPriceListCell, function(tbMoney)
       self:SetPerItemPrice(tbMoney)
    end)

    Event.Reg(self, EventType.OnTouchViewBackGround, function(nViewID)
        if self.WidgetRewardTips and UIHelper.GetVisible(self.WidgetRewardTips) then
            UIHelper.SetVisible(self.WidgetRewardTips, false)
            UIHelper.SetSelected(self.TogRewardTips, false, false)
        end

        if UIHelper.GetVisible(self.WidgetPriceTips) then
            UIHelper.SetVisible(self.WidgetPriceTips, false)
            UIHelper.SetSelected(self.TogPriceTips, false, false)
        end

    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        self:CloseTips()
    end)

    Event.Reg(self, EventType.ON_AUCTION_SELL_SUCCESS, function()
        UIMgr.Close(self)--出价成功关闭界面
    end)

    Event.Reg(self, EventType.ON_DETAIL_LOOK_UP, function(nMaxPage, tbDetailInfo)
        if self.bOpenDetailList then
            if nMaxPage ~= 0 then
                UIMgr.Open(VIEW_ID.PanelSaleListDetailPop, self.tbItem)
            else
                TipsHelper.ShowNormalTip("当前无在售商品")
            end
            self.bOpenDetailList = false
        end
    end)

    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        if nViewID == VIEW_ID.PanelLeftBag and self.WidgetItemScript then
            self.WidgetItemScript:RawSetSelected(false)
            self.scriptBag = nil
        end
     end)

     Event.Reg(self, EventType.OnViewOpen, function(nViewID)
        if nViewID == VIEW_ID.PanelLeftBag and self.WidgetItemScript then
            self.WidgetItemScript:RawSetSelected(true)
        end
     end)

     -- 打开的时候设置最大最小值
     Event.Reg(self, EventType.OnGameNumKeyboardOpen, function(editbox)
        if editbox == self.EditPaginate then
            UIHelper.SetEditBoxGameKeyboardRange(self.EditPaginate, 1, self.nMaxPage)
        elseif editbox == self.WidgetEdit then
            UIHelper.SetEditBoxGameKeyboardRange(self.WidgetEdit, 1, self.nMaxItemNum)
        end
     end)

     Event.Reg(self, EventType.OnGameNumKeyboardChanged, function(editbox, num)
        if editbox == self.EditPaginate then
            local nPage = UIHelper.GetText(self.EditPaginate)
            self:SetCurPage(nPage)
        elseif editbox == self.WidgetEdit then
            self:OnEditBuyNumEnded()
        end
    end)

    Event.Reg(self, EventType.OnApplySellItem, function()
        UIHelper.SetButtonState(self.BtnBuyOrSell, BTN_STATE.Disable, function()
            TipsHelper.ShowNormalTip(g_tStrings.AuctionString.STR_FORBID_SELL_ITEM_TIP)
        end, true)
    end)

    Event.Reg(self, EventType.OnApplyBuyItem, function()
        UIHelper.SetButtonState(self.BtnBuyOrSell, BTN_STATE.Disable, function()
            TipsHelper.ShowNormalTip(g_tStrings.AuctionString.STR_FORBID_BUY_ITEM_TIP)
        end, true)
    end)

    Event.Reg(self, EventType.ON_AUCTION_BUY_RESPOND, function(bSuccess, nCD)
        if nCD and nCD ~= 0 then
            Timer.Add(self, nCD, function ()
                UIHelper.SetButtonState(self.BtnBuyOrSell, BTN_STATE.Normal)
            end)
            return 
        end
        UIHelper.SetButtonState(self.BtnBuyOrSell, BTN_STATE.Normal)
        if bSuccess then
            TradingData.ApplyPriceLookUp(true, self.tbItem, self.nCurPage, self.nDescendingOrder)
        end
    end)

    Event.Reg(self, EventType.ON_AUCTION_SELL_RESPOND, function()
        UIHelper.SetButtonState(self.BtnBuyOrSell, BTN_STATE.Normal)
    end)
end


function UIPanelBuyItem:UnRegEvent()

end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelBuyItem:UpdateInfo()

end

function UIPanelBuyItem:TryOpenBuyView(nBox, nIndex)
    self.bOpenBuyView = true
    self.nSelectItemBox = nBox
    self.nSelectItemIndex = nIndex
    local tbItem = ItemData.GetItemByPos(nBox, nIndex)
    TradingData.ApplyPriceLookUp(false, tbItem, 1, self.nDescendingOrder)
end

function UIPanelBuyItem:OpenSellView(nBox, nIndex)
    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelSellItem)
    if not scriptView then
        scriptView = UIMgr.Open(VIEW_ID.PanelSellItem, TRADING_ITEM_PANEL.SELL)
    end
    scriptView:InitSell(nBox, nIndex)
    self:CloseBag()
end

function UIPanelBuyItem:OpenBuyView(nBox, nIndex, nTotalCount)
    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelBuyItem)
    if not scriptView then
        scriptView = UIMgr.Open(VIEW_ID.PanelBuyItem, TRADING_ITEM_PANEL.BUY)
    end
    scriptView:InitBuy(self.nSelectItemBox, self.nSelectItemIndex, nil)
    self:CloseBag()
end

function UIPanelBuyItem:OpenOrCloseBag()
    if not self.scriptBag then
        self:OpenBag()
    else
        self:CloseBag()
    end
end

function UIPanelBuyItem:CloseBag()
    if self.scriptBag then
        UIMgr.Close(VIEW_ID.PanelLeftBag)
        self.scriptBag = nil
    end
end

function UIPanelBuyItem:OpenBag()
    local tItemTabTypeAndIndexList = {}

    for nIndex, tbItemInfo in ipairs(TradingData.GetBoxItem()) do
        tbItemInfo.nSelectedQuantity = 0
        table.insert(tItemTabTypeAndIndexList, tbItemInfo)
    end

    local tbFilterInfo = {}
    tbFilterInfo.Def = FilterDef.TradingLeftBag
    tbFilterInfo.tbfuncFilter = BagDef.CommonFilter

    self.scriptBag = UIMgr.Open(VIEW_ID.PanelLeftBag)
    self.scriptBag:OnInitWithBox(tItemTabTypeAndIndexList, tbFilterInfo)
    self.scriptBag:SetClickCallback(function(bSelect, nBox, nIndex)
        if bSelect then
            self:OpenTips(nBox, nIndex)
        end
    end)
    self.scriptBag:OnInitCatogory(BagDef.CommonCatogory)
    local nBox, nIndex = ItemData.GetItemPos(self.tbItem.dwTabType, self.tbItem.dwIndex)
    self.scriptBag:SetSelect(nBox, nIndex)
end

function UIPanelBuyItem:UpdateInfo_ItemInfo()

    UIHelper.SetString(self.LabelItemTitle, UIHelper.GBKToUTF8(ItemData.GetItemNameByItem(self.tbItem)))
    local color = ItemQualityColorC4b[self.tbItem.nQuality + 1] or cc.c4b(182, 212, 220, 70)
    UIHelper.SetTextColor(self.LabelItemTitle, color)
    self.WidgetItemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.WidgetItem_100)
    self.WidgetItemScript:OnInitWithTabID(self.tbItem.dwTabType, self.tbItem.dwIndex)
    self.WidgetItemScript:SetClickCallback(function(nTabType, nTabID)
        if nTabType and nTabID then
            self:OpenTipsByTabID(self.WidgetItemScript, nTabType, nTabID)
        else
            self:CloseTips()
        end
    end)
end

function UIPanelBuyItem:UpdateInfo_PriceList()
    local bHasList = self.tbGoodInfo and #self.tbGoodInfo >= 1
    UIHelper.SetVisible(self.WidgetDescibe, not bHasList)
    UIHelper.SetVisible(self.WidgetPaginate, bHasList)
    if not self.tbGoodInfo then return end
    UIHelper.RemoveAllChildren(self.ScrolItem)
    local nSelectIndex = 1
    for nIndex, tItem in ipairs(self.tbGoodInfo) do
        UIHelper.AddPrefab(PREFAB_ID.WidgetPriceListCell, self.ScrolItem, tItem.Price, tItem.StackNum, tItem.SellerNum, nIndex == nSelectIndex)
    end
    UIHelper.ScrollViewDoLayout(self.ScrolItem)
    UIHelper.ScrollToTop(self.ScrolItem)
    UIHelper.SetSwallowTouches(self.ScrolItem, false)
end


function UIPanelBuyItem:UpdateInfo_AveragePrice()
    local scriptViewMax = UIHelper.GetBindScript(self.WidgetMaxPrice)
    scriptViewMax:OnEnter(self.nHistoryMax, nil, self.nHistoryMax == 0)
    local scriptViewMin = UIHelper.GetBindScript(self.WidgetMinPrice)
    scriptViewMin:OnEnter(self.nHistoryMin, nil, self.nHistoryMin == 0)
    local scriptViewYd = UIHelper.GetBindScript(self.WidgetAverageYesterday)
    scriptViewYd:OnEnter(self.nAvgPrice)

    self:DrawChart()
end


--物品单价
function UIPanelBuyItem:UpdateInfo_PerItemPrice()
    local tbPrice = self.tbPerItemPrice
    local scriptView = UIHelper.GetBindScript(self.LabelItemPrice)
    local nMaxPrice = self.nPanelType == TRADING_ITEM_PANEL.CHANGE and MAX_PRICE_COPPER / (self.nItemNum or 1) or MAX_PRICE_COPPER
    scriptView:OnEnter(UIHelper.GoldSilverAndCopperToMoney(tbPrice.nGold, tbPrice.nSilver, tbPrice.nCopper), nil, function(nBullion, nGold, nSilver, nTotalMoney)
        self:OnEditPerItemPriceChanged(nBullion, nGold, nSilver)
    end, nMaxPrice)
end


--最高总价
function UIPanelBuyItem:UpdateInfo_TotalCostOrInCome()
    local scriptView = UIHelper.GetBindScript(self.WidgetMaxCost)
    local nMoney = self.nPanelType == TRADING_ITEM_PANEL.BUY and self.nTotalCost or self.nTotalInCome
    scriptView:OnEnter(nMoney)
end

--购买数量
function UIPanelBuyItem:UpdateInfo_ItemNum()
    local nNum = self.nItemNum
    if self.nPanelType == TRADING_ITEM_PANEL.CHANGE then
        UIHelper.SetString(self.LabelItemNumDetail, nNum)
    else
        UIHelper.SetText(self.WidgetEdit, nNum)
        UIHelper.SetEditboxTextHorizontalAlign(self.WidgetEdit, TextHAlignment.CENTER)
    end
end

function UIPanelBuyItem:UpdateBtnState()

    local bMaxItemNum = self.nItemNum == self.nMaxItemNum
    local nPlusState = bMaxItemNum and BTN_STATE.Disable or BTN_STATE.Normal
    UIHelper.SetButtonState(self.BtnPlus, nPlusState)

    local bMinItemNum = self.nItemNum == 1
    local nSubtractState = bMinItemNum and BTN_STATE.Disable or BTN_STATE.Normal
    UIHelper.SetButtonState(self.BtnSubtract, nSubtractState)
end

function UIPanelBuyItem:UpdateInfo_CurPage()
    UIHelper.SetText(self.EditPaginate, self.nCurPage)
end

function UIPanelBuyItem:UpdateInfo_MaxPage()
    UIHelper.SetString(self.LabelPaginate, "/"..self.nMaxPage)
end


function UIPanelBuyItem:UpdateInfo_MyMoney()
    UIHelper.RemoveAllChildren(self.LayoutRightTop2)
    UIHelper.AddPrefab(PREFAB_ID.WidgetCurrency, self.LayoutRightTop2, function()
        UIHelper.LayoutDoLayout(self.LayoutRightTop2)
        UIHelper.LayoutDoLayout(self.LayoutRightTop)
    end)
    UIHelper.LayoutDoLayout(self.LayoutRightTop2)
    UIHelper.LayoutDoLayout(self.LayoutRightTop)
end

--只有Init才会调一次设置toggle勾选状态
function UIPanelBuyItem:UpdateInfo_SellSaveTime()
    if self.nPanelType == TRADING_ITEM_PANEL.SELL then
        local nSaveTime = self.nSaveTime
        local tbAllTime = {12, 24, 48}
        for index, nTime in ipairs(tbAllTime) do
            local toggle = self[string.format("Tog%dHours", nTime)]
            UIHelper.ToggleGroupAddToggle(self.ToggleGroupChooseLastingTime, toggle)
        end
        for index, nTime in ipairs(tbAllTime) do
            local toggle = self[string.format("Tog%dHours", nTime)]
            if nTime == nSaveTime then
                UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupChooseLastingTime, toggle)
            end
        end
    elseif self.nPanelType == TRADING_ITEM_PANEL.CHANGE then
        UIHelper.SetString(self.LabelLastingTimeDetail, self.nSaveTime .. "小时")
    end
end

--单价按钮状态
function UIPanelBuyItem:UpdateInfo_TogSinglePriceState()
    UIHelper.SetVisible(self.ImgTitleUP, self.nDescendingOrder == 0)
    UIHelper.SetVisible(self.ImgTitleDown, self.nDescendingOrder == 1)
end

function UIPanelBuyItem:OnEditBuyNumEnded()
    local szText = UIHelper.GetText(self.WidgetEdit)
    local nNum = tonumber(szText) or 1
    nNum = math.min(nNum, self.nMaxItemNum)
    nNum = math.max(nNum, 1)
    if self.nPanelType ~= TRADING_ITEM_PANEL.CHANGE then
        self:SetItemNum(nNum)
    end
end

function UIPanelBuyItem:OnEditPerItemPriceChanged(nBullion, nGold, nSilver)
    self:SetPerItemPrice({["nGold"] = nBullion * 10000 + nGold, ["nSilver"] = nSilver , ["nCopper"] = 0})
end











--------------------------------------------------------------------------------------------------------------------------------------------
--Sell的总营收
function UIPanelBuyItem:SetTotalInCome()
    if (not self.tbPerItemPrice) or (not self.nItemNum) or (not self.nSaveMoney) or (not self.nChargeMoney) then return end
    self.nTotalInCome = TradingData.ComputeInCome(self.tbPerItemPrice, self.nItemNum, self.nSaveMoney, self.nChargeMoney)
    self:UpdateInfo_TotalCostOrInCome()
end

--Sell的保管金
function UIPanelBuyItem:SetSaveMoney()
    if (not self.nShopPrice) or (not self.nItemNum) or (not self.nShopPrice) then return end
    self.nSaveMoney = TradingData.ComputeSaveMoney(self.nShopPrice, self.nItemNum, self.nSaveTime)
end

function UIPanelBuyItem:SetShopPrice(nShopPrice)
    self.nShopPrice = nShopPrice
end

function UIPanelBuyItem:SetSaveTime(nSaveTime)
    self.nSaveTime = nSaveTime
    self:SetSaveMoney()
    self:SetChargeMoney()
    self:SetTotalInCome()
end

--Sell时的交易费
function UIPanelBuyItem:SetChargeMoney()
    if not self.tbPerItemPrice or not self.nItemNum then return end
    self.nChargeMoney = TradingData.ComputeChargeMoney(self.tbPerItemPrice, self.nItemNum)
end


function UIPanelBuyItem:SetItemNum(nItemNum)
    -- if nItemNum == self.nItemNum then return end
    self.nItemNum = nItemNum
    self:UpdateInfo_ItemNum()
    self:UpdateBtnState()
    if self.nPanelType == TRADING_ITEM_PANEL.BUY then
        self:SetTotalCost()
    else
        self:SetSaveMoney()
        self:SetChargeMoney()
        self:SetTotalInCome()
    end
end



function UIPanelBuyItem:SetPerItemPrice(tbPerItemPrice)
    self.tbPerItemPrice = tbPerItemPrice
    self:UpdateInfo_PerItemPrice()
    self:SetMaxItemNum()

    if self.nPanelType == TRADING_ITEM_PANEL.BUY then
        self:SetTotalCost()
    end

    if self.nPanelType ~= TRADING_ITEM_PANEL.BUY then
        self:SetChargeMoney()
        self:SetTotalInCome()
    end
end

--Buy的总花费
function UIPanelBuyItem:SetTotalCost()
    local tbInComePrice = MoneyOptMult(self.tbPerItemPrice, self.nItemNum)
    local nTotalCost = UIHelper.GoldSilverAndCopperToMoney(tbInComePrice.nGold, tbInComePrice.nSilver, tbInComePrice.nCopper)
    if self.nTotalCost == nTotalCost then return end
    self.nTotalCost = nTotalCost
    self:UpdateInfo_TotalCostOrInCome()
end


function UIPanelBuyItem:SetMaxPage(nMaxPage)
    if nMaxPage == self.nMaxPage then return end
    self.nMaxPage = nMaxPage
    self:UpdateInfo_MaxPage()
end


function UIPanelBuyItem:SetCurPage(nCurPage, bForceApply, bNotApply)
    if IsString(nCurPage) then
        nCurPage = tonumber(nCurPage)
    end
    if not nCurPage then nCurPage = 1 end
    if nCurPage == self.nCurPage and not bForceApply then return end
    nCurPage = math.max(nCurPage, 1)
    nCurPage = math.min(nCurPage, self.nMaxPage)
    self.nCurPage = nCurPage
    local bFromButton = true
    if bForceApply then bFromButton = false end
    if not bNotApply and TradingData.ApplyPriceLookUp(bFromButton, self.tbItem, nCurPage, self.nDescendingOrder) then
        self:UpdateInfo_CurPage()
    else
        self:UpdateInfo_CurPage()
    end
end


function UIPanelBuyItem:SetMaxItemNum()

    self.nMaxItemNum = TradingData.GetMaxItemNum(self.tbItem, self.tbPerItemPrice, self.nPanelType)
    if self.nPanelType == TRADING_ITEM_PANEL.CHANGE then return end

    local nCurItemNum =  self.nItemNum
    if nCurItemNum == nil then return end
    local nNum = nCurItemNum
    if nNum > self.nMaxItemNum then
        nNum = self.nMaxItemNum
    end
    if self.nPanelType ~= TRADING_ITEM_PANEL.CHANGE then
        self:SetItemNum(nNum)
    end
end

function UIPanelBuyItem:SetItemByBox(nBox, nIndex)
    self.tbItem = ItemData.GetItemByPos(nBox, nIndex)
    self:SetItem()
end

function UIPanelBuyItem:SetItemByItem(tbItem)
    self.tbItem = tbItem
    self:SetItem()
end

function UIPanelBuyItem:SetItem()
    local nShopPrice = self.tbItem and self.tbItem.nPrice or 0
    self:SetShopPrice(nShopPrice)
    if not self.tbItem then return end

    TradingData.ApplyAvgPrice(false, self.tbItem.dwID)


    self:UpdateInfo_ItemInfo()
end


function UIPanelBuyItem:SetHistoryPrice(nLength, tbPriceData, tbMaxPrice, tbMinPrice, nMaxCopper, nMinCopper, tbAvgPrice)
    self.nHistoryLen = nLength

    self.tbPriceData = tbPriceData
    self.tbMaxPrice = tbMaxPrice
    self.tbMinPrice = tbMinPrice

    self.nHistoryMax = nMaxCopper or 0
    self.nHistoryMin = nMinCopper or 0
    self.tbAvgPrice = tbAvgPrice or {nGold = 0, nSilver = 0, nCopper = 0}
    self.nAvgPrice = nLength >= 1 and UIHelper.GoldSilverAndCopperToMoney(self.tbAvgPrice.nGold, self.tbAvgPrice.nSilver, self.tbAvgPrice.nCopper) or 0
    self:UpdateInfo_AveragePrice()

    if nLength >=1 and self.nPanelType == TRADING_ITEM_PANEL.SELL and (not self.tbPerItemPrice or (CovertMoneyToCopper(self.tbPerItemPrice) == 0))
        and TradingData.GetItemIsFirstSellToday(self.tbItem) then
        self:SetPerItemPrice(self.tbAvgPrice)
    end

end

function UIPanelBuyItem:SetDescendingOrder(nDescendingOrder, bNotApply)
    self.nDescendingOrder = nDescendingOrder
    if bNotApply then
        self:UpdateInfo_TogSinglePriceState()
        self:UpdateGoodInfo()
    else
        if TradingData.ApplyPriceLookUp(true, self.tbItem, self.nCurPage, self.nDescendingOrder) then
            self:UpdateInfo_TogSinglePriceState()
            self:UpdateGoodInfo()
        else
            self.nDescendingOrder = (self.nDescendingOrder + 1) % 2
        end
    end
end

function UIPanelBuyItem:UpdateGoodInfo()
    self.tbGoodInfo = TradingData.GetGoodInfo()
    if self.tbGoodInfo then
        self:UpdateInfo_PriceList()
    end
end

function UIPanelBuyItem:TryOpenDetailList()
    self.bOpenDetailList = true
    TradingData.ApplyDetailLookUp(false, 1, self.tbItem, self.nDescendingOrder)
end

function UIPanelBuyItem:CloseTips()
    if self.scriptItemTip then
        self.WidgetItemScript:RawSetSelected(false)
        self.scriptItemTip = nil
    end
end

function UIPanelBuyItem:OpenTips(nBox, nIndex)
    if not self.scriptItemTip then
        self.tips, self.scriptItemTip = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, self.scriptBag._rootNode, TipsLayoutDir.MIDDLE)
    end
    self.scriptItemTip:OnInit(nBox, nIndex)
    self.scriptItemTip:SetBtnState({
        {
            szName = "置入",
            OnClick = function()
                if self.nPanelType == TRADING_ITEM_PANEL.BUY then
                    self:TryOpenBuyView(nBox, nIndex)
                elseif self.nPanelType == TRADING_ITEM_PANEL.SELL then
                    self:OpenSellView(nBox, nIndex)
                end
            end
        },
    })
    UIHelper.SetVisible(self.WidgetAniLeftBag, false)
end

function UIPanelBuyItem:OpenTipsByTabID(scriptView, nTabType, nTabID)
    if not self.scriptItemTip then
        self.tips, self.scriptItemTip = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, scriptView._rootNode, TipsLayoutDir.LEFT_CENTER)
    end
    self.scriptItemTip:OnInitWithTabID(nTabType, nTabID)
    self.scriptItemTip:SetBtnState({
        {
            szName = "置入",
            OnClick = function()
                if self.nPanelType == TRADING_ITEM_PANEL.BUY then
                    self:TryOpenBuyView(nBox, nIndex)
                elseif self.nPanelType == TRADING_ITEM_PANEL.SELL then
                    self:OpenSellView(nBox, nIndex)
                end
            end
        },
    })
    UIHelper.SetVisible(self.WidgetAniLeftBag, false)
end






































-- -------------------------------------------------------------------
-- 画图测试
-- -------------------------------------------------------------------
function UIPanelBuyItem:DrawChart()

    if not self.tbPriceData then return end
    --数据是倒着的，第一个为前一天

    local nChatWidth = UIHelper.GetWidth(self.WidgetPriceTrend)
    local nChatHeight = UIHelper.GetHeight(self.WidgetPriceTrend)


    local nMaxPrice = 0
    for i = 1, 8 do
        local tbPrice = self.tbPriceData[i] and self.tbPriceData[i].Price or {["nGold"] = 0, ["nSilver"] = 0, ["nCopper"] = 0}
        local nPrice = UIHelper.GoldSilverAndCopperToMoney(tbPrice.nGold, tbPrice.nSilver, tbPrice.nCopper)
        nMaxPrice = math.max(nMaxPrice, nPrice)
    end

    local nVScale = Lib.SafeDivision(nChatHeight, nMaxPrice)

    local nHMax = 7
    local nHScale = Lib.SafeDivision(nChatWidth, nHMax)

    self.drawNode = self.drawNode or cc.DrawNode:create()
    self.WidgetPriceTrend:addChild(self.drawNode, 1)

    --前七天
    for i = 7, 1, -1 do

        local nCurDataIndex = i
        local nLastDataIndex = i + 1

        local tbCurPrice = self.tbPriceData[nCurDataIndex] and self.tbPriceData[nCurDataIndex].Price or {["nGold"] = 0, ["nSilver"] = 0, ["nCopper"] = 0}
        local nCurPrice = UIHelper.GoldSilverAndCopperToMoney(tbCurPrice.nGold, tbCurPrice.nSilver, tbCurPrice.nCopper)

        local tbLastPrice = self.tbPriceData[nLastDataIndex] and self.tbPriceData[nLastDataIndex].Price or {["nGold"] = 0, ["nSilver"] = 0, ["nCopper"] = 0}
        local nLastPrice = UIHelper.GoldSilverAndCopperToMoney(tbLastPrice.nGold, tbLastPrice.nSilver, tbLastPrice.nCopper)

        local pStart = cc.p((7 - i)*nHScale, (nLastPrice or 0)*nVScale)
        local pEnd = cc.p((7 - i + 1)*nHScale, nCurPrice*nVScale)

        local color = cc.c4f(1, 0.5, 0.5, 1)
        self.drawNode:drawLine(pStart, pEnd, color)
    end



end










return UIPanelBuyItem