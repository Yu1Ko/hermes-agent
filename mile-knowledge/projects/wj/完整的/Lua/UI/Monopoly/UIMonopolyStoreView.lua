-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIMonopolyStoreView
-- Date: 2026-04-20 10:44:08
-- Desc: 大富翁-商店 PanelRichMan_Store
-- ---------------------------------------------------------------------------------

local UIMonopolyStoreView = class("UIMonopolyStoreView")

-- copy from DX Revision: 1836658
-----------------------------DataModel------------------------------
local DataModel = {
    nPlayerIndex = 0,
    bIsBuyMode = false,
    tStoreCards = {},
    tHandCards = {},
    tStorePrices = {},
    tSellPrices = {},
    nMoney = 0,
    nPoint = 0,
}

function DataModel.Init()
    DataModel.nPlayerIndex = MonopolyData.GetClientPlayerIndex() or 0
    DataModel.bIsBuyMode = true
    DataModel.RefreshStoreCards()
    DataModel.RefreshHandCards()
    DataModel.RefreshCurrency()
end

function DataModel.RefreshStoreCards()
    DataModel.tStoreCards = DFW_GetPlayerStoreCard(DataModel.nPlayerIndex) or {}
    DataModel.tStorePrices = {}
    for i = 1, #DataModel.tStoreCards do
        DataModel.tStorePrices[i] = DFW_GetPlayerStoreSlotPrice(DataModel.nPlayerIndex, i) or 0
    end
end

function DataModel.RefreshHandCards()
    DataModel.tHandCards = DFW_GetPlayerHandCard(DataModel.nPlayerIndex) or {}
    DataModel.tSellPrices = DFW_GetPlayerShopSellList(DataModel.nPlayerIndex) or {}
end

function DataModel.RefreshCurrency()
    DataModel.nMoney = DFW_GetPlayerMoney(DataModel.nPlayerIndex) or 0
    DataModel.nPoint = DFW_GetPlayerPointNum(DataModel.nPlayerIndex) or 0
end

function DataModel.GetHandCardCount()
    local nCardCount = 0
    for _, nCardID in ipairs(DataModel.tHandCards) do
        if nCardID ~= 0 then
            nCardCount = nCardCount + 1
        end
    end

    return nCardCount
end

function DataModel.GetBuyCurrencyByCard(nCardID)
    local tCardInfo = Table_GetMonopolyCardInfoByID(nCardID)
    if tCardInfo and tCardInfo.bMoney == false then
        return false, DataModel.nPoint
    end

    return true, DataModel.nMoney
end

function DataModel.CanBuyCard(nCardID, nPrice)
    if DataModel.GetHandCardCount() >= DFW_PLAYERCARD_INITNUM then
        return false
    end

    local _, nCurrency = DataModel.GetBuyCurrencyByCard(nCardID)
    if nCurrency < (nPrice or 0) then
        return false
    end

    return true
end

function DataModel.UnInit()
    for i, v in pairs(DataModel) do
        if type(v) ~= "function" then
            DataModel[i] = nil
        end
    end
end

-----------------------------View------------------------------
function UIMonopolyStoreView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        UIHelper.AddPrefab(PREFAB_ID.WidgetCoin, self.LayoutMoney, CurrencyType.MonopolyPoint)
        UIHelper.AddPrefab(PREFAB_ID.WidgetCoin, self.LayoutMoney, CurrencyType.MonopolyMoney)
        UIHelper.CascadeDoLayoutDoWidget(self.LayoutMoney, true, true)

        DataModel.Init()
        DataModel.bIsBuyMode = false
        DataModel.RefreshHandCards()
    end

    self:UpdateInfo()
end

function UIMonopolyStoreView:OnExit()
    self.bInit = false
    self:UnRegEvent()

    DataModel.UnInit()
    if self.bActive then
        MonopolyData.SendServerOperate(MINI_GAME_OPERATE_TYPE.SERVER_OPERATE, DFW_OPERATE_UP_STROE_CLOSE)
    end
end

function UIMonopolyStoreView:BindUIEvent()
    UIHelper.BindUIEvent(self.TogBuy, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            self:OnCheckBoxTradeBuyCheck()
        end
    end)
    UIHelper.BindUIEvent(self.TogSell, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            self:OnCheckBoxTradeSellCheck()
        end
    end)
    UIHelper.BindUIEvent(self.BtnCanel, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIMonopolyStoreView:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function()
        if self.selectedCard then
            self.selectedCard:SetSelected(false)
        end
    end)
    Event.Reg(self, EventType.OnMonopolyShopRefreshAfterBuy, function()
        self:RefreshAfterBuy()
    end)
    Event.Reg(self, EventType.OnMonopolyShopRefreshAfterSell, function()
        self:RefreshAfterSell()
    end)
    Event.Reg(self, EventType.OnMonopolyUpdatePlayerMoney, function()
        DataModel.RefreshCurrency()
        self:UpdateAllCardState()
    end)
    Event.Reg(self, EventType.OnMonopolyUpdatePlayerPointNum, function()
        DataModel.RefreshCurrency()
        self:UpdateAllCardState()
    end)
end

function UIMonopolyStoreView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIMonopolyStoreView:UpdateCardState(scriptCard)
    if not scriptCard then
        return
    end

    local nPrice = scriptCard.nPrice
    local bUseMoney = scriptCard.bUseMoney

    local nCurrency = bUseMoney and DataModel.nMoney or DataModel.nPoint
    local bLackMoney = DataModel.bIsBuyMode and nPrice and nCurrency < nPrice
    scriptCard:SetLackMoney(bLackMoney)
end

function UIMonopolyStoreView:BuildCardItem(scriptCard, nCardID, nPrice, bIsBuyMode, nIndex)
    scriptCard:SetVisible(true)
    scriptCard:OnEnter(nCardID)
    scriptCard:SetPrice(nPrice)

    local nPrice = scriptCard.nPrice
    local bUseMoney = scriptCard.bUseMoney

    local nCurrency = bUseMoney and DataModel.nMoney or DataModel.nPoint
    local bLackMoney = bIsBuyMode and nPrice and nCurrency < nPrice

    local bCanBuy = DataModel.CanBuyCard(nCardID, nPrice) -- 手牌数量上限检测
    local bEnabled = not bIsBuyMode or (bCanBuy and not bLackMoney)
    scriptCard:InitBuyBtn(bIsBuyMode, bEnabled, function()
        self:OnCardBtnClick(nCardID, nIndex)
    end)
    scriptCard:SetSelectedCallback(function(bSelected)
        if not bSelected then
            return
        end
        self.selectedCard = scriptCard
        local tCardInfo = Table_GetMonopolyCardInfoByID(nCardID)
        if tCardInfo then
            local szTitle = UIHelper.GBKToUTF8(tCardInfo.szName)
            local szTip = UIHelper.GBKToUTF8(tCardInfo.szDesc)
            TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetRichManTips, scriptCard.TogCard, TipsLayoutDir.RIGHT_CENTER, szTitle, szTip)
        end
    end)
    scriptCard:SetSelected(false)

    if not bCanBuy then
        if bLackMoney then
            -- 货币不足
        else
            -- 卡槽已满
        end
    else
        -- 复原
    end

    self:UpdateCardState(scriptCard)
end

function UIMonopolyStoreView:UpdateCardList(hFrame)
    local tCards, tPrices
    if DataModel.bIsBuyMode then
        tCards = DataModel.tStoreCards
        tPrices = DataModel.tStorePrices
    else
        tCards = DataModel.tHandCards
        tPrices = DataModel.tSellPrices
    end

    self.tScriptCards = self.tScriptCards or {}
    for _, scriptCard in pairs(self.tScriptCards) do
        scriptCard:SetVisible(false)
    end

    local nCount = #tCards
    for i = 1, nCount do
        local nCardID = tCards[i] or 0
        if nCardID ~= 0 then
            self.tScriptCards[i] = self.tScriptCards[i] or UIHelper.AddPrefab(PREFAB_ID.WidgetCard, self.LayoutCard)
            self:BuildCardItem(self.tScriptCards[i], tCards[i], tPrices[i] or 0, DataModel.bIsBuyMode, i)
        end
    end
    UIHelper.LayoutDoLayout(self.LayoutCard)
end

function UIMonopolyStoreView:UpdateAllCardState()
    for _, scriptCard in pairs(self.tScriptCards or {}) do
        if UIHelper.GetVisible(scriptCard) then
            self:UpdateCardState(scriptCard)
        end
    end
end

function UIMonopolyStoreView:UpdateTabState()
    UIHelper.SetSelected(self.TogBuy, DataModel.bIsBuyMode, false)
    UIHelper.SetSelected(self.TogSell, not DataModel.bIsBuyMode, false)
end

function UIMonopolyStoreView:UpdateInfo()
    self:UpdateCardList()
    self:UpdateTabState()
end

-----------------------------Controller------------------------------
function UIMonopolyStoreView:OnCheckBoxTradeBuyCheck()
    DataModel.bIsBuyMode = true
    DataModel.RefreshStoreCards()
    DataModel.RefreshHandCards()
    self:UpdateInfo()
end

function UIMonopolyStoreView:OnCheckBoxTradeSellCheck()
    DataModel.bIsBuyMode = false
    DataModel.RefreshHandCards()
    self:UpdateInfo()
end

function UIMonopolyStoreView:OnCardBtnClick(nCardID, nIndex)
    if not nCardID then
        return
    end

    if DataModel.bIsBuyMode then
        MonopolyData.SendServerOperate(
            MINI_GAME_OPERATE_TYPE.SERVER_OPERATE,
            DFW_OPERATE_UP_STROE_BUY,
            nCardID,
            nIndex or 0
        )
    else
        MonopolyData.SendServerOperate(
            MINI_GAME_OPERATE_TYPE.SERVER_OPERATE,
            DFW_OPERATE_UP_STROE_SELL,
            nCardID
        )
    end
end

function UIMonopolyStoreView:RefreshAfterBuy()
    DataModel.RefreshStoreCards()
    DataModel.RefreshHandCards()
    DataModel.RefreshCurrency()
    self:UpdateInfo()
end

function UIMonopolyStoreView:RefreshAfterSell()
    DataModel.RefreshHandCards()
    DataModel.RefreshCurrency()
    self:UpdateInfo()
end

return UIMonopolyStoreView