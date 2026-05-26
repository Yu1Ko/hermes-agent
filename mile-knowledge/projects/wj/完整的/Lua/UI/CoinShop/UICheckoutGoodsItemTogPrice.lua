-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICheckoutGoodsItemTogPrice
-- Date: 2022-12-19 21:16:34
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICheckoutGoodsItemTogPrice = class("UICheckoutGoodsItemTogPrice")

function UICheckoutGoodsItemTogPrice:OnEnter(tbGoodsInfo, tbPriceInfo, TogGroup, fnSelectCallback)
    self.tbGoodsInfo = tbGoodsInfo
    self.tbPriceInfo = tbPriceInfo
    self.TogGroup = TogGroup
    self.fnSelectCallback = fnSelectCallback
    self.tbBill = tbGoodsInfo.tbBill

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    UIHelper.ToggleGroupAddToggle(self.TogGroup, self.TogSelect)

    self:UpdateInfo()
end

function UICheckoutGoodsItemTogPrice:OnExit()
    self.bInit = false
    self:UnRegEvent()

    UIHelper.ToggleGroupRemoveToggle(self.TogGroup, self.TogSelect)
end

function UICheckoutGoodsItemTogPrice:BindUIEvent()
    UIHelper.BindUIEvent(self.TogSelect, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected and self.fnSelectCallback then
            self.fnSelectCallback()
        end
    end)
end

function UICheckoutGoodsItemTogPrice:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICheckoutGoodsItemTogPrice:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICheckoutGoodsItemTogPrice:UpdateInfo()
    if self.tbBill and (self.tbBill.bUseFaceVouchars or self.tbBill.dwUseVoucherID ~= 0) and self.tbBill.nUseVouchars > 0 then
        UIHelper.SetVisible(self.ImgPriceType, false)
        UIHelper.SetVisible(self.ImgSelectLabel, false)
        UIHelper.SetVisible(self.WidgetDaiBi, true)

        if self.tbBill.nCoin and self.tbBill.nCoin ~= 0 then
            UIHelper.SetString(self.LabelDaiBiTongBao, tostring(self.tbBill.nCoin))
            UIHelper.SetVisible(self.ImgDaoBiTongBao, true)
            UIHelper.SetVisible(self.LabelDaiBiTongBao, true)
        else
            UIHelper.SetVisible(self.ImgDaoBiTongBao, false)
            UIHelper.SetVisible(self.LabelDaiBiTongBao, false)
        end

        UIHelper.SetString(self.LabelDaiBi, tostring(self.tbBill.nUseVouchars))
        UIHelper.SetVisible(self.LabelDaiBiInitial, false)

        local szMsg = "<color=#EAD89A>%d</c></color><img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_TongRenYinPiao' width='32' height='32' /><color=#EAD89A>抵%d<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_TongBao' width='32' height='32' />"
        if self.tbBill.bUseFaceVouchars then
            szMsg = "<color=#EAD89A>%d</c></color><img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_NieLian' width='32' height='32' /><color=#EAD89A>抵%d<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_TongBao' width='32' height='32' />"
            UIHelper.SetSpriteFrame(self.ImgDaiBi, "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_NieLian.png")
        else
            UIHelper.SetSpriteFrame(self.ImgDaiBi, "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_TongRenYinPiao.png")
        end
        szMsg = string.format(szMsg, self.tbBill.nUseVouchars, self.tbBill.nOriginalCoin - self.tbBill.nCoin)
        UIHelper.SetRichText(self.LabelInitial2, szMsg)

    else
        local nPrice = self.tbPriceInfo.nShowPrice or self.tbPriceInfo.nPrice
        UIHelper.SetString(self.LabelDesc, self.tbPriceInfo.szPriceDesc)
        UIHelper.SetString(self.LabelWorth, nPrice)
        UIHelper.SetVisible(self.LabelWorth, self.tbPriceInfo.bDis)
        UIHelper.SetString(self.LabelCost, self.tbPriceInfo.nDisPrice)
        UIHelper.SetSpriteFrame(self.ImgPriceType, self.tbPriceInfo.szImagePath)
        UIHelper.WidgetFoceDoAlignAssignNode(self, self.ImgWorth)

        UIHelper.SetString(self.LabelDescSelect, self.tbPriceInfo.szPriceDesc)
        UIHelper.SetString(self.LabelWorthSelect, nPrice)
        UIHelper.SetVisible(self.LabelWorthSelect, self.tbPriceInfo.bDis)
        UIHelper.SetString(self.LabelCostSelect, self.tbPriceInfo.nDisPrice)
        UIHelper.SetSpriteFrame(self.ImgPriceTypeSelect, self.tbPriceInfo.szImagePath)
        UIHelper.WidgetFoceDoAlignAssignNode(self, self.ImgWorthSelect)
    end

    UIHelper.WidgetFoceDoAlign(self)
end

return UICheckoutGoodsItemTogPrice