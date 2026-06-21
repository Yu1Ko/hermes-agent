-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopLotteryMyRewardsItem
-- Date: 2023-04-11 19:33:59
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

local tCurrentyTypeName = 
{
    [GIFT_TYPE.MONTH_CARD_TYPE] = "月卡",
    [GIFT_TYPE.TIME_CARD_TYPE] = "点卡",
    [GIFT_TYPE.COIN_TYPE] = "通宝",
}

local QUALITY = {
    BLUE = 2,
    PURPLE = 3,
    GOLD = 4,
}

local UICoinShopLotteryMyRewardsItem = class("UICoinShopLotteryMyRewardsItem")

function UICoinShopLotteryMyRewardsItem:OnEnter(tRewardsItem)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tRewardsItem = tRewardsItem
    self:UpdateInfo()
end

function UICoinShopLotteryMyRewardsItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICoinShopLotteryMyRewardsItem:BindUIEvent()
    
end

function UICoinShopLotteryMyRewardsItem:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICoinShopLotteryMyRewardsItem:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopLotteryMyRewardsItem:UpdateInfo()
    UIHelper.SetVisible(self.ImgCurrency, false)
    UIHelper.SetVisible(self.WidgetItemProp, false)

    local nItemType   = self.tRewardsItem[1]
    local dwItemIndex = self.tRewardsItem[2]
    local nItemNum    = self.tRewardsItem[3]

    if nItemType == GIFT_TYPE.COIN_TYPE or nItemType == GIFT_TYPE.TIME_CARD_TYPE or nItemType == GIFT_TYPE.MONTH_CARD_TYPE then
        local tCurrencyInfo = Table_GetPointsDrawCurrencyInfo(nItemType, dwItemIndex)
        if not tCurrencyInfo then
            return
        end
        UIHelper.SetVisible(self.ImgCurrency, true)
        UIHelper.SetSpriteFrame(self.ImgCurrency, tCurrentyTypeImg[nItemType])
        UIHelper.SetString(self.LabelExamineReward, UIHelper.GBKToUTF8(tCurrencyInfo.szName))
        UIHelper.SetString(self.LabelExamineRewardName, tCurrentyTypeName[nItemType])
    else
        local tGiftInfo = Table_GetPointsDrawGiftInfo(nItemType, dwItemIndex)
        if not tGiftInfo then
            return
        end
        local tGiftTypeInfo = Table_GetPointsDrawGiftTypeInfo(tGiftInfo.nGiftType)
        if not tGiftTypeInfo then
            return
        end
        UIHelper.SetVisible(self.WidgetItemProp, true)
        if not self.itemIconScript then
            self.itemIconScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItemProp)
        end
        UIHelper.SetString(self.LabelExamineReward, UIHelper.GBKToUTF8(tGiftTypeInfo.szName))
        if nItemType == GIFT_TYPE.HAIR_TYPE then
        elseif nItemType == GIFT_TYPE.EXTERIOR_TYPE then
            local tExteriorInfo = GetExterior().GetExteriorInfo(dwItemIndex)
            local szName = Table_GetExteriorSetName(tExteriorInfo.nGenre, tExteriorInfo.nSet)
            UIHelper.SetString(self.LabelExamineRewardName, UIHelper.GBKToUTF8(szName))
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
            UIHelper.SetString(self.LabelExamineRewardName, UIHelper.GBKToUTF8(szName))
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


return UICoinShopLotteryMyRewardsItem