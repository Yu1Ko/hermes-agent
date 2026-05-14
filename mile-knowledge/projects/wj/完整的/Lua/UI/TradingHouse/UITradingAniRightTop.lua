-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITradingAniRightTop
-- Date: 2023-03-08 14:08:06
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UITradingAniRightTop = class("UITradingAniRightTop")

function UITradingAniRightTop:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UITradingAniRightTop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITradingAniRightTop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSearch, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelSearchItem)
    end)

    UIHelper.BindUIEvent(self.BtnBag, EventType.OnClick, function()
        self:OpenBag()
    end)

    UIHelper.BindUIEvent(self.BtnMail, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelEmail)
    end)
end

function UITradingAniRightTop:RegEvent()
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

function UITradingAniRightTop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITradingAniRightTop:UpdateInfo()
    UIHelper.AddPrefab(PREFAB_ID.WidgetCurrency, self.LayoutRightTop2 , function()
        UIHelper.LayoutDoLayout(self.LayoutRightTop2)
        UIHelper.LayoutDoLayout(self.LayoutRightTop)
    end)
    UIHelper.LayoutDoLayout(self.LayoutRightTop2)
    UIHelper.LayoutDoLayout(self.LayoutRightTop)
end

function UITradingAniRightTop:OpenSellView(nBox, nIndex)

    -- local nBox, nIndex = self:GetItemBoxAndIndex(dwItemTabType, dwItemTabIndex)
    if nBox == -1 then return end
    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelSellItem)
    if not scriptView then
        scriptView = UIMgr.Open(VIEW_ID.PanelSellItem, TRADING_ITEM_PANEL.SELL)
    end
    scriptView:InitSell(nBox, nIndex)
    -- UIMgr.Close(VIEW_ID.PanelLeftBag)
    self:CloseBag()
end

function UITradingAniRightTop:TryOpenBuyView(nBox, nIndex)
    -- local nBox, nIndex = self:GetItemBoxAndIndex(dwItemTabType, dwItemTabIndex)
    if nBox == -1 then return end
    self.bOpenBuyView = true
    self.nSelectItemBox = nBox
    self.nSelectItemIndex = nIndex
    local tbItem = ItemData.GetItemByPos(nBox, nIndex)
    TradingData.ApplyPriceLookUp(false, tbItem, 1)
end

function UITradingAniRightTop:OpenBuyView(nSelectItemBox, nSelectItemIndex)
    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelBuyItem)
    if not scriptView then
        scriptView = UIMgr.Open(VIEW_ID.PanelBuyItem, TRADING_ITEM_PANEL.BUY)
    end
    scriptView:InitBuy(self.nSelectItemBox, self.nSelectItemIndex, nil)
    -- UIMgr.Close(VIEW_ID.PanelLeftBag)
    self:CloseBag()
end

function UITradingAniRightTop:GetItemBoxAndIndex(dwItemTabType, dwItemTabIndex)
    if self.tbItemList then
        for nIndex, tbItemInfo in ipairs(self.tbItemList) do
            if tbItemInfo.hItem.dwTabType == dwItemTabType and tbItemInfo.hItem.dwIndex == dwItemTabIndex then
                return tbItemInfo.nBox, tbItemInfo.nIndex
            end
        end
    end
    return -1, -1
end

function UITradingAniRightTop:OpenBag()
    self.tbItemList = TradingData.GetBoxItem()
    -- --- 要显示的道具列表 { {dwTabType=1, dwIndex=2} }
    -- self.tItemTabTypeAndIndexList = tItemTabTypeAndIndexList
    -- --- 点击道具图标后显示的道具tip中显示的按钮列表，格式示例 { {szName="确认", OnClick=function(dwItemTabType, dwItemTabIndex) DoSomething() end} }
    -- self.tItemTipBtnList    = tItemTipBtnList or {}
    local tItemTabTypeAndIndexList = {}
    local tbItemTipBtnList = {
        {
            szName = g_tStrings.STR_MOBA_BUY,
            OnClick = function(nBox, nIndex)
                self:TryOpenBuyView(nBox, nIndex)
            end,
            bNormalBtn = true,
            bFobidCheckBtnType = true,
        },
        {
            szName = g_tStrings.STR_AUCTION_SELL,
            OnClick = function(nBox, nIndex)
                self:OpenSellView(nBox, nIndex)
            end,
            bNormalBtn = false,
            bFobidCheckBtnType = true,
        },
    }
    for nIndex, tbItemInfo in ipairs(self.tbItemList) do
        tbItemInfo.nSelectedQuantity = 0--不让他切换后自动显示右上角数字
        table.insert(tItemTabTypeAndIndexList, tbItemInfo)
    end


    local tbFilterInfo = {}
    tbFilterInfo.Def = FilterDef.TradingLeftBag
    tbFilterInfo.tbfuncFilter = BagDef.CommonFilter

    local script = UIMgr.Open(VIEW_ID.PanelLeftBag)
    script:OnInitWithBox(tItemTabTypeAndIndexList, tbFilterInfo)
    script:SetClickCallback(function(bSelected, nBox, nIndex)
        if bSelected then
            local scriptView = script:GetCurSelectedItem()
            local uiTips, uiItemTipScript = TipsHelper.ShowItemTips(scriptView._rootNode, nBox, nIndex, true)

            -- 为了方便外面获取道具信息，预制传入的回调与tip需要的回调格式有所不同，这里转换下
            local tItemTipBtnList = {}
            for _, tBtn in ipairs(tbItemTipBtnList) do
                table.insert(tItemTipBtnList, {
                    szName = tBtn.szName,
                    OnClick = function()
                        tBtn.OnClick(nBox, nIndex)
                    end,
                    bNormalBtn = tBtn.bNormalBtn,
                    bFobidCheckBtnType = tBtn.bFobidCheckBtnType,
                })
            end

            uiItemTipScript:SetBtnState(tItemTipBtnList)
            Event.Dispatch(EventType.OnLeftBagSelectItem)
        end
    
    end)
    script:OnInitCatogory(BagDef.CommonCatogory)
    script:HideChoose()
end

function UITradingAniRightTop:CloseBag()
    if UIMgr.IsViewOpened(VIEW_ID.PanelLeftBag) then
        UIMgr.Close(VIEW_ID.PanelLeftBag)
    end
end

return UITradingAniRightTop