-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetTradingSell
-- Date: 2023-03-14 20:56:56
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetTradingSell = class("UIWidgetTradingSell")

local SortType = {
    TimeUp = 1,
    TimeDown = 2,
    PriceUp = 3,
    PriceDown = 4,
}

local tbSortFunc = {
    [SortType.TimeUp] = function(tbMyStateData)
        return TradingData.SortSellItemByTime(tbMyStateData, true)
    end,
    [SortType.TimeDown] = function(tbMyStateData)
        return TradingData.SortSellItemByTime(tbMyStateData, false)
    end,
    [SortType.PriceUp] = function(tbMyStateData)
        return TradingData.SortSellItemByPrice(tbMyStateData, true)
    end,
    [SortType.PriceDown] = function(tbMyStateData)
        return TradingData.SortSellItemByPrice(tbMyStateData, false)
    end,
}

function UIWidgetTradingSell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:Init()
end

function UIWidgetTradingSell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetTradingSell:OnViewClose()

end

function UIWidgetTradingSell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnRefresh, EventType.OnClick, function()
        TradingData.ApplySellLookUp(true, 1)
    end)

    UIHelper.BindUIEvent(self.BtnSort, EventType.OnClick, function()
        local bVisible = UIHelper.GetVisible(self.WidgetSellListSort)
        UIHelper.SetVisible(self.WidgetSellListSort, not bVisible)
    end)

    UIHelper.BindUIEvent(self.BtnReSell, EventType.OnClick, function()
        UIHelper.ShowConfirm(g_tStrings.AuctionString.STR_BATCH_RESELL_NOTICE, function()
            TradingData.ReShelfItem()
        end, function() end, false)
    end)

    UIHelper.BindUIEvent(self.TogAllSelect, EventType.OnSelectChanged, function(toggle, bSelect)
        self:SetSelectAll(bSelect)
    end)

    UIHelper.BindUIEvent(self.TogSellListSort01, EventType.OnSelectChanged, function(toggle, bSelect)
        if bSelect then
            self:SetSortType(SortType.TimeUp)
            self:SetMyStateData(self.tbMyStateData)
            UIHelper.SetVisible(self.WidgetSellListSort, false)
        end
    end)

    UIHelper.BindUIEvent(self.TogSellListSort02, EventType.OnSelectChanged, function(toggle, bSelect)
        if bSelect then
            self:SetSortType(SortType.TimeDown)
            self:SetMyStateData(self.tbMyStateData)
            UIHelper.SetVisible(self.WidgetSellListSort, false)
        end
    end)

    UIHelper.BindUIEvent(self.TogSellListSort03, EventType.OnSelectChanged, function(toggle, bSelect)
        if bSelect then
            self:SetSortType(SortType.PriceUp)
            self:SetMyStateData(self.tbMyStateData)
            UIHelper.SetVisible(self.WidgetSellListSort, false)
        end
    end)

    UIHelper.BindUIEvent(self.TogSellListSort04, EventType.OnSelectChanged, function(toggle, bSelect)
        if bSelect then
            self:SetSortType(SortType.PriceDown)
            self:SetMyStateData(self.tbMyStateData)
            UIHelper.SetVisible(self.WidgetSellListSort, false)
        end
    end)

end

function UIWidgetTradingSell:RegEvent()
    Event.Reg(self, EventType.ON_SELL_LOOK_UP_RES, function(nTotalCount, tbMyStateData)
        TradingData.ClearReShelfItem()
        self:SetMyStateData(tbMyStateData)
    end)

    Event.Reg(self, EventType.OnSelectGoodsForSale, function(bSelect, tbData)
        local nNum = bSelect and 1 or -1
        local nSelectedNum = self.nSelectedNum + nNum
        nSelectedNum = math.max(0, nSelectedNum)
        self:SetSelectedNum(nSelectedNum)
        if bSelect then
            self:AddReShelfItem(tbData)
        else
            self:DeleteReShelfItem(tbData)
        end
    end)

    Event.Reg(self, EventType.ON_AUCTION_CANCEL_RESPOND, function()
        self:SetSelectedNum(0)
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        if self.scriptItemTip then
            UIHelper.RemoveAllChildren(self.WidgetItemTip2)
            self.scriptItemTip = nil
            self.nCurSelectIconView:RawSetSelected(false)
        end
        local bVisible = UIHelper.GetVisible(self.WidgetSellListSort)
        UIHelper.SetVisible(self.WidgetSellListSort, false)
    end)

    Event.Reg(self, EventType.ON_SHOW_TRADE_ITEM_CELL_TIP, function(nTabType, nTabID, scriptView)
        if nTabType and nTabID and UIHelper.GetVisible(self._rootNode) then
            if not self.scriptItemTip then
                self.scriptItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemTip2)
            end
            self.scriptItemTip:OnInitWithTabID(nTabType, nTabID)
            self.scriptItemTip:SetBtnState({})
            self.nCurSelectIconView = scriptView
        else
            UIHelper.RemoveAllChildren(self.WidgetItemTip2)
            self.scriptItemTip = nil
        end
    end)

end

function UIWidgetTradingSell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetTradingSell:InitToggle()
    for nIndex = 1, 4 do
        local toggle = self[string.format("TogSellListSort0%s", tostring(nIndex))]
        UIHelper.ToggleGroupAddToggle(self.ToggleSellListSort, toggle)
    end
    UIHelper.SetToggleGroupSelected(self.ToggleSellListSort, 0)
    self:SetSortType(SortType.TimeUp)
end


function UIWidgetTradingSell:Init()
    if self:CheckInit() then
        self:InitToggle()
        self:SetMyStateData({})
        self:SetSelectedNum(0)
        self:UpdateLayoutBtn()
        TradingData.ClearReShelfItem()
        TradingData.ApplySellLookUp(false, 1)
    end
end

function UIWidgetTradingSell:CheckInit()
    if not self.nLastInitTime then
        self.nLastInitTime = GetTickCount()
        return true
    end
    local bOk = true
    local nTime = GetTickCount()
    if nTime - self.nLastInitTime <= 1000 then
        bOk = false
    end
    self.nLastInitTime = nTime

    return bOk

end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetTradingSell:UpdateInfo()

end


function UIWidgetTradingSell:UpdateLayoutBtn()
    UIHelper.LayoutDoLayout(self.LayoutBtn)
end


function UIWidgetTradingSell:UpdateMyStateData()

    UIHelper.SetVisible(self.BtnReSell, #self.tbMyStateData ~= 0)
    UIHelper.SetVisible(self.WidgetAnchorSelect, #self.tbMyStateData ~= 0)
    UIHelper.SetVisible(self.WidgetEmpty, #self.tbMyStateData == 0)
    UIHelper.RemoveAllChildren(self.ScrolItem)
    self.tbScriptView = {}
    local tbInfo = {}
    for index, tbData in ipairs(self.tbMyStateData) do
        tbData.bSell = true
        table.insert(tbInfo, tbData)
        if (index%2 == 0) or (index%2 ~= 0 and  index == #self.tbMyStateData) then
            local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetTradeItemClass, self.ScrolItem, tbInfo, self.ToggleGroupSell)
            table.insert(self.tbScriptView, scriptView)
            tbInfo = {}
        end
    end
    UIHelper.ScrollViewDoLayout(self.ScrolItem)
    UIHelper.ScrollToTop(self.ScrolItem, 0)
    UIHelper.SetSwallowTouches(self.ScrolItem, true)

    UIHelper.ScrollViewSetupArrow(self.ScrolItem, self.WidgetArrowSell)
end

function UIWidgetTradingSell:UpdateSelectedNum()
    UIHelper.SetString(self.LabelSelectedNum, self.nSelectedNum)
    local bDisable = (self.nSelectedNum <= 15 and self.nSelectedNum > 0) and BTN_STATE.Normal or BTN_STATE.Disable
    UIHelper.SetButtonState(self.BtnReSell, bDisable, function()
        if self.nSelectedNum ~= 0 then
            TipsHelper.ShowNormalTip(string.format(g_tStrings.AuctionString.STR_MAX_RESELL_ERROR, 15))
        end
    end)
end

function UIWidgetTradingSell:UpdateSortUI()

    local szDesc = ""
    local bDown  = true

    if self.nSortType == SortType.PriceDown then 
        szDesc = "单价" 
    end

    if self.nSortType == SortType.PriceUp then 
        szDesc = "单价" 
        bDown  = false
    end

    if self.nSortType == SortType.TimeDown then 
        szDesc = "时间" 
    end

    if self.nSortType == SortType.TimeUp then 
        szDesc = "时间" 
        bDown  = false
    end

    UIHelper.SetString(self.LabelEmptyDescibe, szDesc)
    UIHelper.SetOpacity(self.ImgDown, bDown and 255 or 70)
    UIHelper.SetOpacity(self.ImgUp, bDown and 70 or 255)
end

function UIWidgetTradingSell:UpdateSelectAll(bSelectAll)

    for nIndex = 1, 7 do
        local script = self.tbScriptView[nIndex]
        if script then 
            script:UpdateInfo_Selected(bSelectAll)
        end
    end

    if #self.tbScriptView >= 8 then
        self.tbScriptView[8]:SetSelected(1, bSelectAll)
    end
end



function UIWidgetTradingSell:SetMyStateData(tbMyStateData)
    self.tbMyStateData = self.FuncSort(tbMyStateData)
    self:UpdateMyStateData()
end

function UIWidgetTradingSell:SetSelectedNum(nSelectedNum)
    self.nSelectedNum = nSelectedNum
    self:RawSelectAll(self.nSelectedNum == #self.tbMyStateData and self.nSelectedNum ~= 0)
    self:UpdateSelectedNum()
end

function UIWidgetTradingSell:SetSelectAll(bSelect)
    self:UpdateSelectAll(bSelect)
end

function UIWidgetTradingSell:RawSelectAll(bSelect)
    UIHelper.SetSelected(self.TogAllSelect, bSelect, false)
end

--添加需要重新上架的
function UIWidgetTradingSell:AddReShelfItem(tbData)
    TradingData.AddReShelfItem(tbData)
end


--删除需要重新上架的
function UIWidgetTradingSell:DeleteReShelfItem(tbData)
    TradingData.DeleteReShelfItem(tbData.ID)
end

function UIWidgetTradingSell:SetSortType(nSortType)
    self.nSortType = nSortType
    self:UpdateSortUI()
    self:UpdateSortFunc()
end

function UIWidgetTradingSell:UpdateSortFunc()
    self.FuncSort = tbSortFunc[self.nSortType]
end


return UIWidgetTradingSell