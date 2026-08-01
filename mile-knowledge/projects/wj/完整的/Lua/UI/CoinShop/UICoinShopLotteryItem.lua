-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopLotteryItem
-- Date: 2023-04-10 15:51:37
-- Desc: ?
-- ---------------------------------------------------------------------------------

local GIFT_TYPE = {
	HAIR_TYPE = 1,
	EXTERIOR_TYPE = 3,
    COIN_TYPE = 4,
    TIME_CARD_TYPE = 15,
    MONTH_CARD_TYPE = 16,
}


local tCurrentyTypeImg = 
{
    [GIFT_TYPE.MONTH_CARD_TYPE] = "UIAtlas2_Shopping_ShoppingTopUp_img_gift06.png",
    [GIFT_TYPE.TIME_CARD_TYPE] = "UIAtlas2_Shopping_ShoppingTopUp_img_gift07.png",
    [GIFT_TYPE.COIN_TYPE] = "UIAtlas2_Shopping_ShoppingTopUp_img_gift08.png",
}

local QUALITY = {
    BLUE = 2,
    PURPLE = 3,
    GOLD = 4,
}

local UICoinShopLotteryItem = class("UICoinShopLotteryItem")

function UICoinShopLotteryItem:OnEnter(nIndex, fnAction)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.bOpen = false
    self.nIndex = nIndex
    self.fnAction = fnAction
    self:UpdateInfo()
end

function UICoinShopLotteryItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICoinShopLotteryItem:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnlIntegrallottery, EventType.OnClick, function ()
        self.fnAction(self)
    end)
end

function UICoinShopLotteryItem:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICoinShopLotteryItem:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopLotteryItem:UpdateInfo()
    UIHelper.SetVisible(self.BtnlIntegrallottery, true)
    UIHelper.SetVisible(self.BtnIntegrallotteryProp, false)
end

function UICoinShopLotteryItem:SetRewards(nItemType, dwItemIndex, nItemNum)
    UIHelper.SetVisible(self.BtnlIntegrallottery, false)
    UIHelper.SetVisible(self.BtnIntegrallotteryProp, true)
    UIHelper.SetVisible(self.ImgCurrency, false)
    UIHelper.SetVisible(self.WidgetItemProp, false)
    self.bOpen = true
    
    if nItemType == GIFT_TYPE.COIN_TYPE or nItemType == GIFT_TYPE.TIME_CARD_TYPE or nItemType == GIFT_TYPE.MONTH_CARD_TYPE then
        local tCurrencyInfo = Table_GetPointsDrawCurrencyInfo(nItemType, dwItemIndex)
        if not tCurrencyInfo then
            return
        end
        UIHelper.SetVisible(self.ImgCurrency, true)
        UIHelper.SetSpriteFrame(self.ImgCurrency, tCurrentyTypeImg[nItemType])
        UIHelper.SetString(self.LabelPropName, UIHelper.GBKToUTF8(tCurrencyInfo.szName))
    else
        UIHelper.SetVisible(self.WidgetItemProp, true)
        if not self.itemIconScript then
            self.itemIconScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItemProp)
        end
        if nItemType == GIFT_TYPE.HAIR_TYPE then
        elseif nItemType == GIFT_TYPE.EXTERIOR_TYPE then
            local tExteriorInfo = GetExterior().GetExteriorInfo(dwItemIndex)
            local szName = Table_GetExteriorSetName(tExteriorInfo.nGenre, tExteriorInfo.nSet)
            UIHelper.SetString(self.LabelPropName, UIHelper.GBKToUTF8(szName))
            self.itemIconScript:OnInitWithTabID("EquipExterior", dwItemIndex, nItemNum)
            self.itemIconScript:SetClickCallback(function(nParam1, nParam2)
                if nParam1 and nParam2 then
                    local _, itemTips = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, self.WidgetItemProp)
                    itemTips:OnInitWithTabID("EquipExterior", dwItemIndex)
                    itemTips:SetBtnState({})
                end
            end)
        else
            local KItemInfo = GetItemInfo(nItemType, dwItemIndex)
            if not KItemInfo then
                return
            end
            local szName = ItemData.GetItemNameByItemInfo(KItemInfo)
            UIHelper.SetString(self.LabelPropName, UIHelper.GBKToUTF8(szName))
            self.itemIconScript:OnInitWithTabID(nItemType, dwItemIndex, nItemNum)
            self.itemIconScript:SetClickCallback(function(nParam1, nParam2)
                if nParam1 and nParam2 then
                    local _, itemTips = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, self.WidgetItemProp)
                    itemTips:OnInitWithTabID(nItemType, dwItemIndex)
                    itemTips:SetBtnState({})
                end
            end)
        end
    end
end

return UICoinShopLotteryItem