-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopSecondNav
-- Date: 2022-12-14 20:31:13
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICoinShopSecondNav = class("UICoinShopSecondNav")

function UICoinShopSecondNav:OnEnter(tArgs)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tArgs = tArgs
    self:UpdateInfo()
end

function UICoinShopSecondNav:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)

    if self.bDelayClearNew then
        self:ClearMyTitleNew()
        self.bDelayClearNew = false
    end
end

function UICoinShopSecondNav:BindUIEvent()
    UIHelper.BindUIEvent(self.TogSecondNav, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            self.tArgs.fnSelectedCallback(self.tArgs)
            self.bDelayClearNew = true
        else
            if self.bDelayClearNew then
                self:ClearMyTitleNew()
                self.bDelayClearNew = false
            end
        end
    end)
end

function UICoinShopSecondNav:RegEvent()
end

function UICoinShopSecondNav:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopSecondNav:UpdateInfo()
    UIHelper.SetString(self.LabelNormal, UIHelper.GBKToUTF8(self.tArgs.szName))
    UIHelper.SetString(self.LabelUpAll01, UIHelper.GBKToUTF8(self.tArgs.szName))
    UIHelper.SetSwallowTouches(self.TogSecondNav, false)
    UIHelper.SetSelected(self.TogSecondNav, false, false)

    UIHelper.SetCanSelect(self.TogSecondNav, not self.tArgs.bDisable, g_tStrings.COINSHOP_HAIRSHOP_CAN_NOT_CHANGE)

    local nLabel = self.tArgs.nLabel
    local szLabelImgPath
    if nLabel == EXTERIOR_LABEL.NEW then
        szLabelImgPath = "UIAtlas2_Shopping_ShoppingIcon_img_new"
    elseif nLabel == EXTERIOR_LABEL.HOT then
        szLabelImgPath = "UIAtlas2_Shopping_ShoppingIcon_img_hot"
    elseif nLabel == EXTERIOR_LABEL.DISCOUNT then
        szLabelImgPath = "UIAtlas2_Shopping_ShoppingIcon_img_discount"
    elseif nLabel == EXTERIOR_LABEL.TIME_LIMIT then
        szLabelImgPath = "UIAtlas2_Shopping_ShoppingIcon_img_xian"
    end
    if szLabelImgPath then
        UIHelper.SetVisible(self.ImgNewIcon, true)
        UIHelper.SetSpriteFrame(self.ImgNewIcon, szLabelImgPath)
    else
        UIHelper.SetVisible(self.ImgNewIcon, false)
    end
    self:UpdateTitleRed()
    self:UpdateSchoolTitleRed()
end

function UICoinShopSecondNav:SetSelected(bSelected)
    UIHelper.SetSelected(self.TogSecondNav, bSelected)
end

function UICoinShopSecondNav:UpdateTitleRed()
    local bRed = false
    bRed = bRed or self:IsTitleNotify()
    bRed = bRed or self:IsMyTitleNew()
    UIHelper.SetVisible(self.ImgRedDot, bRed)
    UIHelper.SetVisible(self.ImgRedDotSelect, bRed)
    UIHelper.LayoutDoLayout(self.LayoutNameNormal)
    UIHelper.LayoutDoLayout(self.LayoutNameSelect)
end

function UICoinShopSecondNav:IsTitleNotify()
    local tArgs = self.tArgs
    if not tArgs.bShop then
        return
    end
    local bNotice = false
    if tArgs.nTitleClass and tArgs.nTitleSub and not tArgs.nSubClass then
        bNotice = CoinShop_IsNoticeTitle(tArgs.nTitleClass, tArgs.nTitleSub)
    end
    -- 发型特判一下显示全部
    if not bNotice then
        if tArgs.nType == COIN_SHOP_GOODS_TYPE.HAIR and tArgs.nSubClass == 1 then
            bNotice = CoinShop_IsNoticeTitle(tArgs.nTitleClass, tArgs.nTitleSub)
        end
    end
    return bNotice
end

function UICoinShopSecondNav:IsMyTitleNew()
    local tArgs = self.tArgs
    if tArgs.bShop then
        return
    end
    local bNew = false
    if tArgs.nType and tArgs.nRewardsClass then
        bNew = CoinShopData.IsMyTitleHasNew(tArgs.nType, tArgs.nRewardsClass)
    end
    return bNew
end

function UICoinShopSecondNav:ClearMyTitleNew()
    local tArgs = self.tArgs
    if tArgs.bShop then
        return
    end
    if tArgs.nType and tArgs.nRewardsClass then
        CoinShopData.ClearMyTitleNew(tArgs.nType, tArgs.nRewardsClass)
    end
end

function UICoinShopSecondNav:UpdateSchoolTitleRed()
    local tArgs = self.tArgs
    if not tArgs.bSchoolRule then
        return false
    end
    local bRed = RedpointHelper.CoinShopSchool_HasRedPoint()
    UIHelper.SetVisible(self.ImgRedDot, bRed)
    UIHelper.SetVisible(self.ImgRedDotSelect, bRed)
end

return UICoinShopSecondNav