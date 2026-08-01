-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIPanelYangDaoBlessShopView
-- Date: 2026-02-28 16:35:53
-- Desc: 扬刀大会-祝福商店界面 PanelYangDaoBlessShop
-- ---------------------------------------------------------------------------------

local UIPanelYangDaoBlessShopView = class("UIPanelYangDaoBlessShopView")

local PRICE_TEXT_COLOR = cc.c3b(255, 255, 255)
local PRICE_TEXT_COLOR_RED = cc.c3b(255, 117, 117)

local REFRESH_PRICE_TEXT_COLOR_GREEN = "#95FF95"
local REFRESH_PRICE_TEXT_COLOR_RED = "#FF7575"

function UIPanelYangDaoBlessShopView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        local dwTabType = ArenaTowerData.REFRESH_ITEM_ID[1]
        local dwIndex = ArenaTowerData.REFRESH_ITEM_ID[2]
        UIHelper.AddPrefab(PREFAB_ID.WidgetCoin, self.LayoutCoins, CurrencyType.TianJiToken)
        local scriptCoin = UIHelper.AddPrefab(PREFAB_ID.WidgetSingleCurrency, self.LayoutCoins, dwTabType, dwIndex, true)
        scriptCoin:SetCustomIcon(ArenaTowerData.REFRESH_ITEM_ICON_PATH)
        UIHelper.CascadeDoLayoutDoWidget(UIHelper.GetParent(self.LayoutCoins), true, true)
    end

    self.tShopCardList = ArenaTowerData.GetShopListInfo()
    self:InitTab()
    self:UpdateInfo()
end

function UIPanelYangDaoBlessShopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelYangDaoBlessShopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnChat, EventType.OnClick, function()
        ChatHelper.Chat(UI_Chat_Channel.Team)
    end)
    UIHelper.BindUIEvent(self.BtnDetail, EventType.OnClick, function()
        local tElementPoint, _, _ = ArenaTowerData.GetElementPointInfo()
        UIMgr.Open(VIEW_ID.PanelElementDetailSide, tElementPoint)
    end)
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
    UIHelper.BindUIEvent(self.TogDetailedDesc, EventType.OnSelectChanged, function(_, bSelected)
        ArenaTowerData.ShowBlessDetailDesc(bSelected)
    end)
    UIHelper.SetClickInterval(self.BtnBuy, 1)
    UIHelper.BindUIEvent(self.BtnBuy, EventType.OnClick, function()
        if not self.tSelCardData then
            return
        end

        local nPrice = self.tSelCardData.nPrice or 0
        local nShopItemType = self.tSelCardData.nShopItemType
        local dialog = UIHelper.ShowConfirm(string.format(g_tStrings.ARENA_TOWER_SHOP_BUY_CONFIRM, tostring(nPrice)), function()
            ArenaTowerData.BuyCard(self.nSelCardID, nShopItemType)
        end, nil, true)
    end)
    UIHelper.SetClickInterval(self.BtnRefresh, 1)
    UIHelper.BindUIEvent(self.BtnRefresh, EventType.OnClick, function()
        local szUseInfo
        if self.nNeedRefreshCount and self.nNeedRefreshItemCount then
            szUseInfo = string.format("%d易卦点和%d个易卦盘", self.nNeedRefreshCount, self.nNeedRefreshItemCount)
        elseif self.nNeedRefreshCount then
            szUseInfo = string.format("%d易卦点", self.nNeedRefreshCount)
        elseif self.nNeedRefreshItemCount then
            szUseInfo = string.format("%d个易卦盘", self.nNeedRefreshItemCount)
        else
            return
        end

        local szMsg = string.format(g_tStrings.ARENA_TOWER_REFRESH_SHOP_CONFIRM, szUseInfo)
        if self.nCanRefreshCount then
            szMsg = string.format("%s\n（%s%s）", szMsg, g_tStrings.ARENA_TOWER_CAN_USE_REFRESH_POINT, tostring(self.nCanRefreshCount))
        end
        local dialog = UIHelper.ShowConfirm(szMsg, function()
            ArenaTowerData.RefreshShop()
        end, nil, true)
    end)
end

function UIPanelYangDaoBlessShopView:RegEvent()
    Event.Reg(self, EventType.OnShowBlessDetailDesc, function()
        UIHelper.SetSelected(self.TogDetailedDesc, ArenaTowerData.bShowBlessDetailDesc, false)
    end)
    Event.Reg(self, EventType.OnArenaTowerDataUpdate, function()
        self:UpdateElementPoint()
    end)
    Event.Reg(self, "On_ArenaTower_ShopBuy_Respond", function()
        -- 购买成功刷新界面
        TipsHelper.ShowNormalTip("祈卦成功")
        -- ArenaTowerData.bArenaTowerViewFold = false
        self.tShopCardList = ArenaTowerData.GetShopListInfo()
        self:UpdateBlessList()
        if self.scriptBlessCardDetail then
            self.scriptBlessCardDetail:PlayAni(BlessCardAniEvent.OnGetCard)
        end
    end)
    Event.Reg(self, "On_ArenaTower_RefreshShop_Res", function()
        TipsHelper.ShowNormalTip("卦象更换成功")
        self.tShopCardList = ArenaTowerData.GetShopListInfo()
        self:UpdateBlessList()
        self:UpdateRefreshState()
    end)
    Event.Reg(self, "BAG_ITEM_UPDATE", function(dwBoxIndex, dwX, bIsNewAdd)
        local player = GetClientPlayer()
        local item = ItemData.GetPlayerItem(player, dwBoxIndex, dwX)
        local dwTabType = ArenaTowerData.REFRESH_ITEM_ID[1]
        local dwIndex = ArenaTowerData.REFRESH_ITEM_ID[2]
        if item and item.dwTabType == dwTabType and item.dwIndex == dwIndex then
            self:UpdateRefreshState()
        end
    end)
end

function UIPanelYangDaoBlessShopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIPanelYangDaoBlessShopView:InitTab()
    UIHelper.RemoveAllChildren(self.LayoutTab)

    local script = UIHelper.AddPrefab(PREFAB_ID.WidgetYangDaoBlessShopTabCell, self.LayoutTab, "全部", function()
        self:SelectTab(nil)
    end)
    UIHelper.AddPrefab(PREFAB_ID.WidgetYangDaoBlessShopTabCell, self.LayoutTab, "卦象", function()
        self:SelectTab(BlessShopItemType.Bless)
    end)
    UIHelper.AddPrefab(PREFAB_ID.WidgetYangDaoBlessShopTabCell, self.LayoutTab, "五灵点", function()
        self:SelectTab(BlessShopItemType.ElementPoint)
    end)
    UIHelper.AddPrefab(PREFAB_ID.WidgetYangDaoBlessShopTabCell, self.LayoutTab, "属性提升", function()
        self:SelectTab(BlessShopItemType.AttritubeUp)
    end)
    script:SetSelected(true, false)
end

function UIPanelYangDaoBlessShopView:UpdateBlessList()
    UIHelper.RemoveAllChildren(self.LayoutList)
    self.lastSelectCard = nil
    self:OnClearSelect()

    local bHasItem = false
    for _, tCardData in ipairs(self.tShopCardList or {}) do
        if (not self.nSelTabType or self.nSelTabType == tCardData.nShopItemType) then
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetBlessCardShopItem, self.LayoutList)
            local function OnSelected()
                if self.lastSelectCard and self.lastSelectCard ~= script then
                    self.lastSelectCard:SetSelected(false)
                end
                self.lastSelectCard = script
                self:OnSelectBlessCard(tCardData)
            end
            script:OnInitShopItem(tCardData)
            script:SetClickCallback(function()
                OnSelected()
            end)
            bHasItem = true
            -- 恢复选择
            local nShopItemType = self.tSelCardData and self.tSelCardData.nShopItemType
            if self.nSelCardID == tCardData.nCardID and nShopItemType == tCardData.nShopItemType then
                script:SetSelected(true)
                OnSelected()
            end
        end
    end
    UIHelper.SetVisible(self.WidgetEmpty, not bHasItem)

    UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewList, true, true)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewList)
end

function UIPanelYangDaoBlessShopView:UpdateInfo()
    UIHelper.SetSelected(self.TogDetailedDesc, ArenaTowerData.bShowBlessDetailDesc, false)
    self:OnClearSelect()
    self:UpdateRefreshState()
    self:UpdateElementPoint()
    self:SelectTab(nil, true)
end

function UIPanelYangDaoBlessShopView:UpdateElementPoint()
    -- 注意这里self.tLabelElement的顺序要与BlessElementType的顺序一致
    local tElementPoint, _, _ = ArenaTowerData.GetElementPointInfo()
    for _, nType in pairs(BlessElementType) do
        UIHelper.SetString(self.tLabelElement[nType], tElementPoint[nType] or 0)
    end
end

-- BlessShopItemType
function UIPanelYangDaoBlessShopView:SelectTab(nTabType, bForce)
    if self.nSelTabType == nTabType and not bForce then
        return
    end
    self.nSelTabType = nTabType
    self:UpdateBlessList()
end

function UIPanelYangDaoBlessShopView:OnSelectBlessCard(tCardData)
    if not tCardData then
        return
    end

    self.tSelCardData = tCardData
    self.nSelCardID = tCardData.nCardID
    UIHelper.SetVisible(self.TogDetailedDesc, ArenaTowerData.CardHasShortDesc(tCardData))
    UIHelper.SetVisible(self.WidgetBlessCardEmpty, false)

    self.scriptBlessCardDetail = self.scriptBlessCardDetail or UIHelper.AddPrefab(PREFAB_ID.WidgetBlessCardL, self.WidgetBlessCardShell)
    self.scriptBlessCardDetail:OnInitLargeCard(tCardData)

    local nPrice = tCardData.nPrice or 0
    local nCoinInGame, _ = ArenaTowerData.GetCoinInGameInfo()
    UIHelper.SetString(self.LabelNum, nPrice)
    UIHelper.SetColor(self.LabelNum, nCoinInGame >= nPrice and PRICE_TEXT_COLOR or PRICE_TEXT_COLOR_RED)
    UIHelper.LayoutDoLayout(self.LayoutCoin)

    local nLeftBuyCount = tCardData.nLeftBuyCount
    if nLeftBuyCount <= 0 then
        self:SetBuyBtnEnable(false, "该卦象已达祈卦次数上限")
    elseif nCoinInGame < nPrice then
        self:SetBuyBtnEnable(false, "天机筹不足")
    else
        self:SetBuyBtnEnable(true)
    end

    local bCanBuy = nLeftBuyCount > 0
    UIHelper.SetVisible(self.WidgetBottomButton, bCanBuy)
    UIHelper.SetVisible(self.WidgetHintGot, not bCanBuy)
end

function UIPanelYangDaoBlessShopView:OnClearSelect()
    UIHelper.SetVisible(self.TogDetailedDesc, false)
    UIHelper.SetVisible(self.WidgetBottomButton, false)
    UIHelper.SetVisible(self.WidgetHintGot, false)
    UIHelper.SetVisible(self.WidgetBlessCardEmpty, true)
    UIHelper.RemoveAllChildren(self.WidgetBlessCardShell)
    UIHelper.SetString(self.LabelNum, "-")
    UIHelper.SetColor(self.LabelNum, PRICE_TEXT_COLOR)
    UIHelper.LayoutDoLayout(self.LayoutCoin)
    self.scriptBlessCardDetail = nil
    self:SetBuyBtnEnable(false)
end

function UIPanelYangDaoBlessShopView:UpdateRefreshState()
    local player = GetClientPlayer()
    if not player then
        return
    end

    local nFreeRefreshCount, nUseRefreshCount, nMaxRefreshCount, nRefreshItemCount = ArenaTowerData.GetRefreshCountInfo()
    local nCanRefreshCount = nMaxRefreshCount - nUseRefreshCount
    local nRefreshPrice = ArenaTowerData.SHOP_REFRESH_PRICE

    if nFreeRefreshCount > 0 then
        local szColor = nFreeRefreshCount >= nRefreshPrice and REFRESH_PRICE_TEXT_COLOR_GREEN or REFRESH_PRICE_TEXT_COLOR_RED
        local szText = string.format("免费易卦点：<color=%s>%d</c>/%d", szColor, nFreeRefreshCount, nRefreshPrice)
        UIHelper.SetRichText(self.LabelRefreshNum, szText)
        UIHelper.SetWidth(self.LabelRefreshNum, UIHelper.GetUtf8RichTextWidth(szText, 26) + 8)
        UIHelper.RichTextIgnoreContentAdaptWithSize(self.LabelRefreshNum, true)
        UIHelper.SetVisible(self.ImgRefreshIcon, false)
    else
        local szColor = nRefreshItemCount >= nRefreshPrice and REFRESH_PRICE_TEXT_COLOR_GREEN or REFRESH_PRICE_TEXT_COLOR_RED
        local szText = string.format("易卦盘：<color=%s>%d</c>/%d", szColor, nRefreshItemCount, nRefreshPrice)
        UIHelper.SetRichText(self.LabelRefreshNum, szText)
        UIHelper.SetWidth(self.LabelRefreshNum, UIHelper.GetUtf8RichTextWidth(szText, 26) + 8)
        UIHelper.RichTextIgnoreContentAdaptWithSize(self.LabelRefreshNum, true)
        UIHelper.SetVisible(self.ImgRefreshIcon, true)
    end

    local szColor = nCanRefreshCount >= nRefreshPrice and REFRESH_PRICE_TEXT_COLOR_GREEN or REFRESH_PRICE_TEXT_COLOR_RED
    local szCanRefresh = string.format("%s<color=%s>%d</c>", g_tStrings.ARENA_TOWER_CAN_USE_REFRESH_POINT, szColor, nCanRefreshCount)
    UIHelper.SetRichText(self.LabelRefreshDesc, szCanRefresh)
    UIHelper.SetWidth(self.LabelRefreshDesc, UIHelper.GetUtf8RichTextWidth(szCanRefresh, 24) + 12)
    UIHelper.RichTextIgnoreContentAdaptWithSize(self.LabelRefreshDesc, true)

    self.nNeedRefreshCount = nil
    self.nNeedRefreshItemCount = nil
    self.nCanRefreshCount = nCanRefreshCount
    if nFreeRefreshCount >= nRefreshPrice then
        self.nNeedRefreshCount = nRefreshPrice
    elseif nFreeRefreshCount > 0 and nFreeRefreshCount + nRefreshItemCount >= nRefreshPrice then
        self.nNeedRefreshCount = nFreeRefreshCount
        self.nNeedRefreshItemCount = nRefreshPrice - nFreeRefreshCount
    elseif nRefreshItemCount >= nRefreshPrice then
        self.nNeedRefreshItemCount = nRefreshPrice
    end

    if self.nNeedRefreshCount or self.nNeedRefreshItemCount then
        local bCanRefresh = nCanRefreshCount >= nRefreshPrice
        UIHelper.SetButtonState(self.BtnRefresh, bCanRefresh and BTN_STATE.Normal or BTN_STATE.Disable, "本次闯关可消耗易卦点不足")
    else
        UIHelper.SetButtonState(self.BtnRefresh, BTN_STATE.Disable, "易卦点和易卦盘不足")
    end

    UIHelper.LayoutDoLayout(self.LayoutRefreshCoin)
end

function UIPanelYangDaoBlessShopView:SetBuyBtnEnable(bEnabled, szTip)
    self.szBuyTip = szTip
    -- BTN_STATE没变的话SetButtonState的param不会重复生效
    UIHelper.SetButtonState(self.BtnBuy, bEnabled and BTN_STATE.Normal or BTN_STATE.Disable, function()
        if not string.is_nil(self.szBuyTip) then
            TipsHelper.ShowNormalTip(self.szBuyTip)
        end
    end)
end

return UIPanelYangDaoBlessShopView