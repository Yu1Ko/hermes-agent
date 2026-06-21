-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopCheckoutHairDyeView
-- Date: 2025-10-16 16:54:20
-- Desc: ?
-- ---------------------------------------------------------------------------------
local INDEX_TO_COST_TYPE = {
    [1] = HAIR_CUSTOM_DYEING_TYPE.BASE_COLOR,
    [2] = HAIR_CUSTOM_DYEING_TYPE.HAIR_COLOR,
    [3] = HAIR_CUSTOM_DYEING_TYPE.DECORATION_COLOR,
}

local TABLE_DYEING_HAIR = {
    [1] = {
        szName = g_tStrings.STR_DYEING_BASE,
        nColorType = HAIR_CUSTOM_DYEING_TYPE.BASE_COLOR,
        tSub = {
            {nLogicType = HAIR_CUSTOM_DYEING_TYPE.BASE_ROUGHNESS, szKey = "Roughness", szName = g_tStrings.STR_BASE_DYEING_ROUGHNESS},
            {nLogicType = HAIR_CUSTOM_DYEING_TYPE.BASE_HIGHLIGHT, szKey = "Highlight", szName = g_tStrings.STR_BASE_DYEING_HIGHLIGHT},   
            {nLogicType = HAIR_CUSTOM_DYEING_TYPE.BASE_ABLEDO_COLORA, szKey = "AbledoColorA", szName = g_tStrings.STR_BASE_DYEING_ABLEDO_COLORA},
            {nLogicType = HAIR_CUSTOM_DYEING_TYPE.BASE_SPECULAR_COLORA, szKey = "SpecularColorA", szName = g_tStrings.STR_BASE_DYEING_SPECULAR_COLORA},   
        },  
    },

    [2] = {
        szName = g_tStrings.STR_DYEING_HAIR,
        nColorType = HAIR_CUSTOM_DYEING_TYPE.HAIR_COLOR,
        tSub = {
            {nLogicType = HAIR_CUSTOM_DYEING_TYPE.HAIR_ROUGHNESS, szKey = "Roughness", szName = g_tStrings.STR_HAIR_DYEING_ROUGHNESS},
            {nLogicType = HAIR_CUSTOM_DYEING_TYPE.HAIR_HIGHLIGHT, szKey = "Highlight", szName = g_tStrings.STR_HAIR_DYEING_HIGHLIGHT},
            {nLogicType = HAIR_CUSTOM_DYEING_TYPE.HAIR_ABLEDO_COLORA, szKey = "AbledoColorA", szName = g_tStrings.STR_HAIR_DYEING_ABLEDO_COLORA},
            {nLogicType = HAIR_CUSTOM_DYEING_TYPE.HAIR_SPECULAR_COLORA, szKey = "SpecularColorA", szName = g_tStrings.STR_HAIR_DYEING_SPECULAR_COLORA},
        },
    },

    [3] = {
        szName = g_tStrings.STR_DYEING_DECORATION,
        nColorType = HAIR_CUSTOM_DYEING_TYPE.DECORATION_COLOR,
        tSub = {
            {nLogicType = HAIR_CUSTOM_DYEING_TYPE.DECORATION_COLORA, szKey = "ColorA", szName = g_tStrings.STR_DECORATION_DYEING_COLORA},
            {nLogicType = HAIR_CUSTOM_DYEING_TYPE.DECORATION_COLOR_STRENGTH, szKey = "ColorStrength", szName = g_tStrings.STR_DECORATION_DYEING_COLOR_STRENGTH},
        },
        bDecoration = true,
    },
}

local UICoinShopCheckoutHairDyeView = class("UICoinShopCheckoutHairDyeView")

function UICoinShopCheckoutHairDyeView:OnEnter(tNowData, nNowHair, nNowDyeingIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.bAutoBuy = false
    self.tNowData = tNowData
    self.nNowHair = nNowHair
    self.nNowDyeingIndex = nNowDyeingIndex

    local bShowRecharge = Platform.IsWindows() or (Platform.IsAndroid() and not Channel.Is_dylianyunyun())
    UIMgr.AddPrefab(PREFAB_ID.WidgetCoin, self.LayoutTongBao, CurrencyType.Coin, false, nil, bShowRecharge)
    UIHelper.LayoutDoLayout(self.LayoutTongBao)

    self:UpdateInfo()
end

function UICoinShopCheckoutHairDyeView:OnExit()
    self.bInit = false
    self:UnRegEvent()

    if not UIMgr.GetView(VIEW_ID.PanelDyeingDetail) then
        UIMgr.ShowView(VIEW_ID.PanelCoinShopBuildDyeing)
    end
end

function UICoinShopCheckoutHairDyeView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnBuy, EventType.OnClick, function(btn)
        self:BuyHairDye()
    end)
end

function UICoinShopCheckoutHairDyeView:RegEvent()
    Event.Reg(self, "COIN_SHOP_BUY_RESPOND", function ()
        local tCostItem, tSellItem = self:GetCostList(self.nNowDyeingIndex)
        if self.bAutoBuy and #tSellItem == 0 then
            self:BuyHairDye()
        end
    end)
end

function UICoinShopCheckoutHairDyeView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopCheckoutHairDyeView:UpdateInfo()
    local tColorInfo = {}

    local nHair = self.nNowHair
    for index, nCostType in ipairs(INDEX_TO_COST_TYPE) do
        local dwColorID = self.tNowData[nCostType]
        local bDecoration = nCostType == HAIR_CUSTOM_DYEING_TYPE.DECORATION_COLOR
        if dwColorID then
            local tColor = bDecoration and Table_GetDyeingDecorationColorInfo(dwColorID) or Table_GetDyeingHairColorInfo(dwColorID)
            tColorInfo[index] = tColor
        end
    end

    local tCostItem, tSellItem = self:GetCostList(self.nNowDyeingIndex)
    local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetDyeingSettleAccountsContent, self.ScrollViewAchievementContentCommon)
    scriptItem:OnEnter(nHair, tColorInfo, {tCostItem, tSellItem}, self.nNowDyeingIndex)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewAchievementContentCommon)
end

function UICoinShopCheckoutHairDyeView:GetCostList(nDyeingIndex)
    local hDyeingManager = GetHairCustomDyeingManager()
    if not hDyeingManager then
        return
    end
    local tCost = hDyeingManager.GetDyeingDataCost(self.tNowData, self.nNowHair, nDyeingIndex)
    local tSellItem = {}
    local tCostItem = {}
    if tCost then
        for _, dwCostType in ipairs(tCost) do
            if dwCostType == 0 then
                break
            end
            local dwCostBox, dwCostX = hDyeingManager.GetCostColorItemInPackage(dwCostType)
            if dwCostBox == INVENTORY_INDEX.INVALID then
                local tSellInfo = Table_GetSellDyeingItemInfo(dwCostType)
                table.insert(tSellItem, 1, tSellInfo)
            else
                table.insert(tCostItem, {dwBox = dwCostBox, dwX = dwCostX})
            end
        end
    end
    return tCostItem, tSellItem
end

local function _GetBuyItemList(tSellItem)
    local tItemList = {}
    for k, v in ipairs(tSellItem) do
        local dwLogicID = Table_GetRewardsGoodID(v.dwItemType, v.dwItemIndex)
        table.insert(tItemList, {dwGoodsID = dwLogicID, eGoodsType = COIN_SHOP_GOODS_TYPE.ITEM, nBuyCount = 1})
    end
    return tItemList
end

local function GetMoney(tGoodList)
    local nMoney = 0
    for k, v in ipairs(tGoodList) do
        local nPrice = CoinShop_GetPrice(v.dwGoodsID, v.eGoodsType)
        nMoney = nMoney + nPrice
    end
    return nMoney
end

function UICoinShopCheckoutHairDyeView:BuyHairDye()
    local hDyeingManager = GetHairCustomDyeingManager()
    if not hDyeingManager then
        return
    end

    local tCostItem, tSellItem = self:GetCostList(self.nNowDyeingIndex)
    if #tSellItem == 0 then
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EXTERIOR, "CoinShop") then
            return
        end

        local tbData = clone(self.tNowData)
        self:DealWithBuyTable(tbData)

        local nCode = hDyeingManager.Buy(tbData, self.nNowHair, self.nNowDyeingIndex, tCostItem)
        if nCode == HAIR_CUSTOM_DYEING_ERROR_CODE.SUCCESS then
            UIMgr.Close(self)
            UIMgr.Close(VIEW_ID.PanelDyeingDetail)
            UIMgr.Close(VIEW_ID.PanelCoinShopBuildDyeing)
        else
            local szMsg 
            if self.nDyeingIndex == 0 then
                szMsg = g_tStrings.tHairDyeingBuyNotify[nCode]
            else
                szMsg = g_tStrings.tHairDyeingReplaceNotify[nCode]
            end
            TipsHelper.ShowNormalTip(szMsg)
            return 
        end
    else
        local szMsg = g_tStrings.STR_HAIR_DYEING_LESS_ITEM
        if #tSellItem == 1 then
            local szItemName = ItemData.GetItemNameByItemInfoIndex(tSellItem[1].dwItemType, tSellItem[1].dwItemIndex)
            szMsg = FormatString(g_tStrings.STR_HAIR_DYEING_LESS_ITEM_1, UIHelper.GBKToUTF8(szItemName))
        else
            local szItemName1 = ItemData.GetItemNameByItemInfoIndex(tSellItem[1].dwItemType, tSellItem[1].dwItemIndex)
            local szItemName2 = ItemData.GetItemNameByItemInfoIndex(tSellItem[2].dwItemType, tSellItem[2].dwItemIndex)

            szMsg = FormatString(g_tStrings.STR_HAIR_DYEING_LESS_ITEM_2, UIHelper.GBKToUTF8(szItemName1), UIHelper.GBKToUTF8(szItemName2))
        end
        local tGoodList = _GetBuyItemList(tSellItem)
        local nMoney = GetMoney(tGoodList)
        szMsg = szMsg .. FormatString(g_tStrings.STR_HAIR_DYEING_COST_MONEY, nMoney)

        szMsg = ParseTextHelper.ParseNormalText(szMsg, false)
        UIHelper.ShowConfirm(szMsg, function ()
            self.bAutoBuy = true
            CoinShop_BuyItemList(tGoodList)
        end, nil, true)
    end
end

function UICoinShopCheckoutHairDyeView:DealWithBuyTable(tData)
    for k, v in ipairs(TABLE_DYEING_HAIR) do
        local nColorType = v.nColorType
        if tData[nColorType] == 0 then
            for _, tInfo in ipairs(v.tSub) do
                local nLogicType = tInfo.nLogicType
                tData[nLogicType] = 0 
            end
        end
    end
end

return UICoinShopCheckoutHairDyeView