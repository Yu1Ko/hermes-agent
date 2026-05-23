-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITopUpBtn
-- Date: 2022-12-21 14:33:09
-- Desc: 充值商品组件
-- Prefab: WidgetTopUpBtn / WIdgetTopUpSoloBtn
-- ---------------------------------------------------------------------------------

---@class UITopUpBtn
local UITopUpBtn = class("UITopUpBtn")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UITopUpBtn:_LuaBindList()
    self.BtnPay           = self.BtnPay --- 购买按钮
    self.ImgBackground    = self.ImgBackground --- 背景图片
    self.ImgItemIcon      = self.ImgItemIcon --- 商品图标
    self.LabelDescription = self.LabelDescription --- 商品描述
    self.LabelPrice       = self.LabelPrice --- 商品价格

    self.LabelPresentTips = self.LabelPresentTips --- 商品赠送信息
    self.ImgPresentTips   = self.ImgPresentTips --- 商品赠送信息的图片
end

---@param uiTopUpMainView UITopUpMainView
function UITopUpBtn:OnEnter(tbProductConfig, bSolo, uiTopUpMainView)
    --- PayData.GetAllPayConfig() 列表中的元素
    self.tbProductConfig = tbProductConfig
    --- 是否仅单个商品
    self.bSolo           = bSolo
    --- 充值界面的脚本
    self.uiTopUpMainView = uiTopUpMainView

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UITopUpBtn:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITopUpBtn:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnPay, EventType.OnClick, function()
        -- note: 7.18版本有充值活动，先禁用掉这个30分钟限制
        ---- iOS端只有点卡时长低于30分钟时，才可进行点卡充值
        --if Platform.IsIos() then
        --    local nMonthEndTime, nPointLeftTime, _, _ = Login_GetTimeOfFee()
        --    nPointLeftTime                            = PayData.GetActualPointLeftTime(nPointLeftTime, nMonthEndTime)
        --
        --    local bCanChargeInIos                     = nPointLeftTime <= 30 * 60
        --    if not bCanChargeInIos then
        --        local scriptConfirm = UIHelper.ShowConfirm("点卡剩余时间少于30分钟时才可充值，请稍后再试")
        --        scriptConfirm:HideButton("Cancel")
        --        return
        --    end
        --
        --    if XGSDK.bNeedSuccessNotify then
        --        -- iOS充值付款完成后，但尚未通知点卡到账前，不允许充值，避免绕过上面的30分钟的限制
        --        local scriptConfirm = UIHelper.ShowConfirm("充值尚未完成，请稍后再试")
        --        scriptConfirm:HideButton("Cancel")
        --        return
        --    end
        --end

        UIHelper.SetVisible(self.uiTopUpMainView.WidgetBuyingMask, true)
        PayData.Pay(self.tbProductConfig.szProductId)
    end)
end

function UITopUpBtn:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITopUpBtn:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITopUpBtn:UpdateInfo()
    UIHelper.SetString(self.LabelDescription, self.tbProductConfig.szProductName)

    if not self.bSolo then
        --- 目前仅 WidgetTopUpBtn 需要展示这个，而单个的 WIdgetTopUpSoloBtn 不需要这个
        local szPresentTips = self.tbProductConfig.szPresentTips

        local bShowPresentTips = szPresentTips and szPresentTips ~= ""
        if bShowPresentTips then
            UIHelper.SetString(self.LabelPresentTips, szPresentTips)
        end
        UIHelper.SetVisible(self.ImgPresentTips, bShowPresentTips)
    end
    UIHelper.SetString(self.LabelPrice, string.format("%d%s", self.tbProductConfig.nPrice, g_tStrings.CHARGE_YUAN))

    if self.tbProductConfig.szIconPath ~= "" then
        UIHelper.SetSpriteFrame(self.ImgItemIcon, self.tbProductConfig.szIconPath)
    end

    if Platform.IsIos() then
        UIHelper.SetVisible(self.ImgPresentTips, false)
    end
end

return UITopUpBtn