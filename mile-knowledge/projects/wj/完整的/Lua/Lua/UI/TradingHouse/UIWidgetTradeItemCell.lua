-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetTradeItemCell
-- Date: 2023-03-14 19:17:24
-- Desc: ?
-- ---------------------------------------------------------------------------------
local NEAR_DUE_TIME = 600
local UIWidgetTradeItemCell = class("UIWidgetTradeItemCell")

function UIWidgetTradeItemCell:OnEnter(tbData, ToggleGroup)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if tbData then
        self.tbData = tbData
        self.ToggleGroup = ToggleGroup
        self:UpdateInfo()
    end
end

function UIWidgetTradeItemCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetTradeItemCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogAllSelect, EventType.OnSelectChanged, function(toggle, bSelect)
        Event.Dispatch(EventType.OnSelectGoodsForSale, bSelect, self.tbData)
    end)

    UIHelper.BindUIEvent(self.BtnEditPrice, EventType.OnClick, function()
        local scriptView = UIMgr.Open(VIEW_ID.PanelEditItemPrice, TRADING_ITEM_PANEL.CHANGE)
        scriptView:InitChangePrice(self.tbData)
    end)

    UIHelper.BindUIEvent(self.BtnLabelGroup, EventType.OnClick, function()
        if not self.tbData.bSell then 
            self:TryOpenBuyView(self.tbData.Item)
        end
    end)

    UIHelper.BindUIEvent(self.BtnDeleteItem, EventType.OnClick, function()
        TradingData.CanCelItem(self.tbData.ID)
    end)
   
end

function UIWidgetTradeItemCell:RegEvent()
    
end

function UIWidgetTradeItemCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetTradeItemCell:UpdateInfo()
    self:UpdateInfo_Name()
    self:UpdateInfo_Price()
    self:UpdateInfo_QualityOrLeftTime()
    self:UpdateInfo_Num()
    self:UpdateInfo_WidgetItem_80()

    self:UpdateInfo_TogAllSelect()
    self:UpdateInfo_BtnEditPrice()
    self:UpdateInfo_BtnDeleteItem()

    self:UpdateInfo_Selected(false)
end

function UIWidgetTradeItemCell:UpdateInfo_Price()
    if self.tbData.Price then
        -- UIHelper.SetString(self.LabelMoney_Yin, self.tbData.Price.nCopper)
        -- UIHelper.LayoutDoLayout(self.WidgetMoneyYin)
        -- UIHelper.SetString(self.LabelMoney_Jin, self.tbData.Price.nSilver)
        -- UIHelper.LayoutDoLayout(self.WidgetMoneyJin)
        -- UIHelper.SetString(self.LabelMoney_Zhuan, self.tbData.Price.nGold)
        -- UIHelper.LayoutDoLayout(self.WidgetMoneyZhuan)
        -- UIHelper.LayoutDoLayout(self.LayoutCost)
        local nMoney = CovertMoneyToCopper(self.tbData.Price)
        local scriptView = UIHelper.GetBindScript(self.LayoutCost)
        scriptView:OnEnter(nMoney)
    end
end

function UIWidgetTradeItemCell:UpdateInfo_Name()
    if self.tbData.Item then
        UIHelper.SetString(self.LabelItemName, UIHelper.GBKToUTF8(ItemData.GetItemNameByItem(self.tbData.Item)), 12)
        UIHelper.SetTextColor(self.LabelItemName, ItemQualityColorC4b[self.tbData.Item.nQuality + 1] or cc.c4b(182, 212, 220, 70))
    end
end

--品级
function UIWidgetTradeItemCell:UpdateInfo_QualityOrLeftTime()
    local szContent = ""
    local bShow = true
    if self.tbData.Item and not self.tbData.bSell then
        szContent = "品级: "..self.tbData.Item.nLevel
        bShow = self.tbData.Item.nLevel ~= 0
    elseif self.tbData.LeftTime and self.tbData.bSell then
        szContent = TradingData.FormatAuctionLeftTime(self.tbData.LeftTime)
    end
    UIHelper.SetString(self.LabelLastTime, szContent)
    UIHelper.SetVisible(self.LabelLastTime, bShow)
end

function UIWidgetTradeItemCell:UpdateInfo_Num()
    if self.tbData.StackNum then 
        UIHelper.SetString(self.LabelLeftSaleNum, FormatString(g_tStrings.COINSHOP_REWARDS_TIP, self.tbData.StackNum))
    end
end


function UIWidgetTradeItemCell:UpdateInfo_WidgetItem_80()
    if self.tbData.Item then
        local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem_80) 
        scriptView:OnInitWithTabID(self.tbData.Item.dwTabType, self.tbData.Item.dwIndex)
        UIHelper.ToggleGroupAddToggle(self.ToggleGroup, scriptView.ToggleSelect)
        scriptView:SetClickCallback(function(nTabType, nTabID)
            Event.Dispatch(EventType.ON_SHOW_TRADE_ITEM_CELL_TIP, nTabType, nTabID, scriptView, self.tbData.Item.dwID)
        end)
        scriptView:SetTouchDownHideTips(false)
    end
end

function UIWidgetTradeItemCell:UpdateInfo_TogAllSelect()
    UIHelper.SetVisible(self.TogAllSelect, self.tbData.bSell)
end

function UIWidgetTradeItemCell:UpdateInfo_BtnEditPrice()
    UIHelper.SetVisible(self.BtnEditPrice, self.tbData.bSell)
end

function UIWidgetTradeItemCell:UpdateInfo_BtnDeleteItem()
    UIHelper.SetVisible(self.BtnDeleteItem, self.tbData.bSell)
end

function UIWidgetTradeItemCell:UpdateInfo_Selected(bSelected)
    if UIHelper.GetVisible(self.TogAllSelect) and UIHelper.GetSelected(self.TogAllSelect) ~= bSelected then
        UIHelper.SetSelected(self.TogAllSelect, bSelected)
    end
end

function UIWidgetTradeItemCell:TryOpenBuyView(tbItem)
    local scriptView = UIMgr.Open(VIEW_ID.PanelBuyItem, TRADING_ITEM_PANEL.BUY)
    scriptView:InitBuy(nil, nil, tbItem)
end

return UIWidgetTradeItemCell