-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetLeftBag
-- Date: 2023-03-08 09:42:19
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetLeftBag = class("UIWidgetLeftBag")

function UIWidgetLeftBag:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbFilter = {
        {szName = "装备", bSelected = false, filterFunc = function(item) return item.nGenre == ITEM_GENRE.EQUIPMENT end},
        {szName = "药品", bSelected = false, filterFunc = function(item) return item.nGenre == ITEM_GENRE.POTION end},
        {szName = "材料", bSelected = false, filterFunc = function(item) return item.nGenre == ITEM_GENRE.MATERIAL end},
        {szName = "书籍", bSelected = false, filterFunc = function(item) return item.nGenre == ITEM_GENRE.BOOK end},
        {szName = "家具", bSelected = false, filterFunc = function(item) return item.nGenre == ITEM_GENRE.HOMELAND end},
        {szName = "次品", bSelected = false, filterFunc = function(item) return item.nQuality == 0 end}
    }
    UIHelper.SetVisible(self.WidgetAnchorCategoryTips, false)
    self:UpdateInfo()
end

function UIWidgetLeftBag:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetLeftBag:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnScreen, EventType.OnClick, function()
        local bVisible = UIHelper.GetVisible(self.WidgetAnchorCategoryTips)
        UIHelper.SetVisible(self.WidgetAnchorCategoryTips, not bVisible)
        if not bVisible then
            self:UpdateScrollViewFilter()
        end
    end)

    UIHelper.BindUIEvent(self.BtnReset, EventType.OnClick, function()
        self:InitFilterToggle()
    end)

    UIHelper.BindUIEvent(self.BtnAffirm, EventType.OnClick, function()

        local szNameList = {}
        for index, scriptView in ipairs(self.tbFilterScript) do
            local bSelect = scriptView:GetSelected()
            if bSelect then
                table.insert(szNameList, scriptView:GetSelectorName())
            end
        end

        for index, tbInfo in ipairs(self.tbFilter) do
            tbInfo.bSelected = table.contain_value(szNameList, tbInfo.szName)
        end
        self:UpdateInfo()
    end)
end

function UIWidgetLeftBag:RegEvent()
    Event.Reg(self, EventType.OnTouchViewBackGround, function()
        self:Close()
    end)

    Event.Reg(self, EventType.OnShopSelectorSelectChanged, function(szSelectorName, selectValue, bSelected)
        
    end)

    Event.Reg(self, EventType.ON_AUCTION_SELL_SUCCESS, function()
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.ON_PRICE_LOOK_UP, function(nTotalCount, tbGoodInfo)
        if self.bOpenBuyView then
            if nTotalCount ~= 0 then
                self:OpenBuyView(self.nSelectItemBox, self.nSelectItemIndex)
            else
                TipsHelper.ShowNormalTip("当前物品无在售")
            end
            self.bOpenBuyView = false
        end
    end)
end

function UIWidgetLeftBag:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetLeftBag:UpdateInfo()
    self.tbItemList = TradingData.GetBoxItem()
    UIHelper.SetVisible(self.WidgetEmpty, self.tbItemList == nil or #self.tbItemList == 0)
    UIHelper.RemoveAllChildren(self.ScrollBag)
    local bNeedFilter = self:NeedFilter()
    for index, tbItemInfo in ipairs(self.tbItemList) do
        if bNeedFilter then--是否需要筛选，没有勾上任何条件时不筛选
            bShow = self:CanShow(tbItemInfo)
        else
            bShow = true
        end
        if bShow then
            local cellScript = UIHelper.AddPrefab(PREFAB_ID.WidgetBagBottom, self.ScrollBag)
            cellScript:OnEnter(tbItemInfo.nBox, tbItemInfo.nIndex)
            local itemScript = cellScript:GetItemScript()
            if itemScript then
                itemScript:SetToggleGroupIndex(ToggleGroupIndex.BagItem)
                itemScript:SetSelectChangeCallback(function(dwItemID, bSelected, nBox, nIndex) self:OnItemSelectChange(dwItemID, bSelected, nBox, nIndex) end)
            end
        end
    end
    UIHelper.ScrollViewDoLayout(self.ScrollBag)
    UIHelper.ScrollToTop(self.ScrollBag, 0)
end

function UIWidgetLeftBag:UpdateScrollViewFilter()
    UIHelper.RemoveAllChildren(self.ScrollViewFilter)
    self.tbFilterScript = {}
    for _, tbBagFilterCell in ipairs(self.tbFilter) do
        local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetSubToggleSelector, self.ScrollViewFilter, tbBagFilterCell.szName, tbBagFilterCell.szName, 0)
        scriptView:SetSelected(tbBagFilterCell.bSelected)
        table.insert(self.tbFilterScript, scriptView)
    end
    UIHelper.ScrollViewDoLayout(self.ScrollViewFilter)
    UIHelper.ScrollToTop(self.ScrollViewFilter)
end

function UIWidgetLeftBag:InitFilterToggle()
    for index, scriptView in ipairs(self.tbFilterScript) do
        scriptView:SetSelected(false)
    end
end

function UIWidgetLeftBag:OnItemSelectChange(dwItemID, bSelected, nBox, nIndex)
    if bSelected then
        if not self.WidgetItemTip then
            if UIMgr.IsViewOpened(VIEW_ID.PanelBuyItem) then
                self:TryOpenBuyView(nBox, nIndex)
            else
                self:OpenSellView(nBox, nIndex)
            end
            return 
        end
        if not self.scriptItemTip then
            self.scriptItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemTip)
        end
        if self.scriptItemTip then
            local tbFunctions = {
                {
                    szName = g_tStrings.STR_MOBA_BUY,
                    OnClick = function()
                        self:TryOpenBuyView(nBox, nIndex)
                    end
                },
                {
                    szName = g_tStrings.STR_AUCTION_SELL,
                    OnClick = function()
                        self:OpenSellView(nBox, nIndex)
                    end
                }
            }
            self.scriptItemTip:SetFunctionButtons(tbFunctions)
            self.scriptItemTip:OnInit(nBox, nIndex)
        end
    end
end

function UIWidgetLeftBag:TryOpenBuyView(nBox, nIndex)
    self.bOpenBuyView = true
    self.nSelectItemBox = nBox
    self.nSelectItemIndex = nIndex
    local tbItem = ItemData.GetItemByPos(nBox, nIndex)
    TradingData.ApplyPriceLookUp(false, tbItem, 1)
end

function UIWidgetLeftBag:OpenSellView(nBox, nIndex)
    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelSellItem)
    if not scriptView then
        scriptView = UIMgr.Open(VIEW_ID.PanelSellItem, TRADING_ITEM_PANEL.SELL)
    end
    scriptView:InitSell(nBox, nIndex)
    self:Close()
end

function UIWidgetLeftBag:OpenBuyView(nBox, nIndex, nTotalCount)
    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelBuyItem)
    if not scriptView then
        scriptView = UIMgr.Open(VIEW_ID.PanelBuyItem, TRADING_ITEM_PANEL.BUY)
    end
    scriptView:InitBuy(self.nSelectItemBox, self.nSelectItemIndex, nil)
    self:Close()
end

function UIWidgetLeftBag:NeedFilter()
    for index, value in ipairs(self.tbFilter) do
        if value.bSelected == true then
            return true
        end
    end
    return false
end

function UIWidgetLeftBag:CanShow(tbItemInfo)
    local tbItem = ItemData.GetItemByPos(tbItemInfo.nBox, tbItemInfo.nIndex)
    for index, value in ipairs(self.tbFilter) do
        if value.bSelected and value.filterFunc(tbItem) then
            return true
        end
    end
    return false
end

function UIWidgetLeftBag:Close()
    self:OnClose()
    UIHelper.SetVisible(self._rootNode, false)
end

function UIWidgetLeftBag:OnClose()
    if self.scriptItemTip then
        UIHelper.RemoveFromParent(self.scriptItemTip._rootNode)
        self.scriptItemTip = nil 
    end
    UIHelper.SetVisible(self.WidgetAnchorCategoryTips, false)
end

return UIWidgetLeftBag