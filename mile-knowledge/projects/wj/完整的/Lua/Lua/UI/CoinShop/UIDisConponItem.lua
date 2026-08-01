-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIDisConponItem
-- Date: 2022-12-20 18:22:08
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIDisConponItem = class("UIDisConponItem")

function UIDisConponItem:OnEnter(tbDisCoupon, fnClickCallback)
    self.tbDisCoupon = tbDisCoupon
    self.fnClickCallback = fnClickCallback

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIDisConponItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIDisConponItem:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSettleAccounts, EventType.OnClick, function ()
        if self.fnClickCallback then
            self.fnClickCallback()
        end
    end)
end

function UIDisConponItem:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIDisConponItem:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIDisConponItem:UpdateInfo()
    if table_is_empty(self.tbDisCoupon) then
        UIHelper.SetRichText(self.LabelDiscount, string.format("<color=#ffffff>%s</color>", g_tStrings.STR_NOT_ANY_WELFARE))
        UIHelper.SetVisible(self.LayourReduction, false)
        UIHelper.SetVisible(self.LabelDiscount, true)
        UIHelper.SetVisible(self.LabelDesc, false)
        return
    end

    if self.tbDisCoupon.nType == COIN_SHOP_DISCOUNT_TYPE.DISCOUNT then
        UIHelper.SetRichText(self.LabelDiscount, string.format("<color=#ffffff>%s</color>", UIHelper.GBKToUTF8(self.tbDisCoupon.szMenuOption)))
        UIHelper.SetRichText(self.LabelDesc, string.format("<color=#FFE26E>%s</color>", UIHelper.GBKToUTF8(self.tbDisCoupon.szDescription)))
    elseif self.tbDisCoupon.nType == COIN_SHOP_DISCOUNT_TYPE.FULL_CUT then
        local szTip = UIHelper.GBKToUTF8(self.tbDisCoupon.szTipContent)
        local sz1, sz2  = szTip:match("%D+(%d+)%D+(%d+)%D+")
        UIHelper.SetString(self.LabelFullCurrency, sz1)
        UIHelper.SetString(self.LabelCutCurrency, sz2)
        UIHelper.SetRichText(self.LabelDesc, string.format("<color=#FFE26E>%s</color>", UIHelper.GBKToUTF8(self.tbDisCoupon.szDescription)))
    else
        UIHelper.SetRichText(self.LabelDiscount, string.format("<color=#ffffff>%s</color>", g_tStrings.STR_NOT_USE_WELFARE))
        UIHelper.SetVisible(self.LabelDesc, false)
    end

    UIHelper.SetVisible(self.LayourReduction, self.tbDisCoupon.nType == COIN_SHOP_DISCOUNT_TYPE.FULL_CUT)
    UIHelper.SetVisible(self.LabelDiscount, self.tbDisCoupon.nType ~= COIN_SHOP_DISCOUNT_TYPE.FULL_CUT)

    UIHelper.LayoutDoLayout(self.WidgetMoneyFull)
    UIHelper.LayoutDoLayout(self.WidgetMoneyReduction)
    UIHelper.LayoutDoLayout(self.LayourReduction)
    UIHelper.LayoutDoLayout(self.WidgetFullCut)
end

return UIDisConponItem