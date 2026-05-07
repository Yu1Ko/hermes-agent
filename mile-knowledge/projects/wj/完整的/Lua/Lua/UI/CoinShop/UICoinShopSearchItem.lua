-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopSearchItem
-- Date: 2022-12-28 10:26:53
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICoinShopSearchItem = class("UICoinShopSearchItem")

function UICoinShopSearchItem:OnEnter(tbInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbInfo = tbInfo
    self:UpdateInfo()
end

function UICoinShopSearchItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UICoinShopSearchItem:BindUIEvent()
    UIHelper.BindUIEvent(self.TogShoppingSearch, EventType.OnClick, function ()
        Event.Dispatch(EventType.OnCoinShopSearch, self.tbInfo)
    end)
end

function UICoinShopSearchItem:RegEvent()
end

function UICoinShopSearchItem:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopSearchItem:UpdateInfo()
    UIHelper.SetString(self.LabelCommodity, UIHelper.GBKToUTF8(self.tbInfo[1]))
    UIHelper.SetString(self.LabelCommodity01, UIHelper.GBKToUTF8(self.tbInfo[1]))
    UIHelper.SetSwallowTouches(self.TogShoppingSearch, false)
    local nHomeType = self.tbInfo[2]
    if nHomeType == HOME_TYPE.EXTERIOR then
        local nIndex = Exterior_GetSubIndex(self.tbInfo[3])
        UIHelper.SetSpriteFrame(self.ImgIcon, CoinShopPreview.tRoleBoxIcon[nIndex])
    elseif nHomeType == HOME_TYPE.REWARDS then
        local dwID = self.tbInfo[3]
        local bOver = self.tbInfo[4]
        if bOver then
            UIHelper.SetSpriteFrame(self.ImgIcon, "UIAtlas2_Shopping_ShoppingIcon_icon_33")
        else
            local tItem = Table_GetRewardsItem(dwID)
            local hItemInfo = GetItemInfo(tItem.dwTabType, tItem.dwIndex)
            if hItemInfo.nGenre == ITEM_GENRE.EQUIPMENT and hItemInfo.nSub == EQUIPMENT_SUB.HORSE then
                UIHelper.SetSpriteFrame(self.ImgIcon, CoinShopPreview.tRideBoxIcon[COINSHOP_RIDE_BOX_INDEX.HORSE])
            elseif hItemInfo.nGenre == ITEM_GENRE.EQUIPMENT and hItemInfo.nSub == EQUIPMENT_SUB.HORSE_EQUIP then
                local hAdornment = hItemInfo
                local nRepresentSub = ExteriorView_GetRepresentSub(hAdornment.nSub, hAdornment.nDetail)
                local nIndex = CoinShop_GetRideIndex(nRepresentSub)
                UIHelper.SetSpriteFrame(self.ImgIcon, CoinShopPreview.tRideBoxIcon[nIndex])
            elseif hItemInfo.nGenre == ITEM_GENRE.EQUIPMENT and hItemInfo.nSub == EQUIPMENT_SUB.PET then
                UIHelper.SetSpriteFrame(self.ImgIcon, CoinShopPreview.szPetBoxIcon)
            elseif hItemInfo.nGenre == ITEM_GENRE.EQUIPMENT and IsPendantItem(hItemInfo) then
                local hPendant = hItemInfo
                local nRepresentSub = ExteriorView_GetRepresentSub(hPendant.nSub, hPendant.nDetail)
                local nIndex = Exterior_RepresentToBoxIndex(nRepresentSub)
                UIHelper.SetSpriteFrame(self.ImgIcon, CoinShopPreview.tRoleBoxIcon[nIndex])
            elseif hItemInfo.nGenre == ITEM_GENRE.EQUIPMENT and IsPendantPetItem(hItemInfo) then
                UIHelper.SetSpriteFrame(self.ImgIcon, CoinShopPreview.tRoleBoxIcon[COINSHOP_BOX_INDEX.PENDANT_PET])
            elseif hItemInfo.nGenre == ITEM_GENRE.COIN_SHOP_QUANTITY_LIMIT_ITEM then
                UIHelper.SetSpriteFrame(self.ImgIcon, CoinShopPreview.tRoleBoxIcon[COINSHOP_BOX_INDEX.ITEM])
            elseif hItemInfo.nGenre == ITEM_GENRE.HOMELAND then
                UIHelper.SetSpriteFrame(self.ImgIcon, CoinShopPreview.szFurnitureBoxIcon)
            else
                UIHelper.SetSpriteFrame(self.ImgIcon, CoinShopPreview.tRoleBoxIcon[COINSHOP_BOX_INDEX.ITEM])
            end
        end
    elseif nHomeType == HOME_TYPE.EXTERIOR_WEAPON then
        UIHelper.SetSpriteFrame(self.ImgIcon, CoinShopPreview.tRoleBoxIcon[COINSHOP_BOX_INDEX.WEAPON])
    elseif nHomeType == HOME_TYPE.EXTERIOR_SET then
        UIHelper.SetSpriteFrame(self.ImgIcon, CoinShopPreview.tRoleBoxIcon[COINSHOP_BOX_INDEX.CHEST])
    elseif nHomeType == HOME_TYPE.HAIR then
        UIHelper.SetSpriteFrame(self.ImgIcon, CoinShopPreview.tRoleBoxIcon[COINSHOP_BOX_INDEX.HAIR])
    elseif nHomeType == "Pendant" then
        local dwIndex = self.tbInfo[3]
        local hItemInfo = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, dwIndex)
        local nIndex = Exterior_SubToBoxIndex(hItemInfo.nSub)
        UIHelper.SetSpriteFrame(self.ImgIcon, CoinShopPreview.tRoleBoxIcon[nIndex])
    elseif nHomeType == HOME_TYPE.EFFECT_SFX then
        local dwIndex = self.tbInfo[3]
        UIHelper.SetSpriteFrame(self.ImgIcon, CoinShopPreview.tRoleBoxIcon[COINSHOP_BOX_INDEX.EFFECT_SFX][dwIndex])
    end
end


return UICoinShopSearchItem