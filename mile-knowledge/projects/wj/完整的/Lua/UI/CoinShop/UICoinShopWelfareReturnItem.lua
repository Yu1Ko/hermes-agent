-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopWelfareReturnItem
-- Date: 2023-04-11 16:59:30
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICoinShopWelfareReturnItem = class("UICoinShopWelfareReturnItem")

local tInnerChargeTypeImg =
{
    [INNER_CHARGE_TYPE.DATE] = "UIAtlas2_Shopping_ShoppingTopUp_img_gift06.png",
    [INNER_CHARGE_TYPE.SECOND] = "UIAtlas2_Shopping_ShoppingTopUp_img_gift07.png",
    [INNER_CHARGE_TYPE.COIN] = "UIAtlas2_Shopping_ShoppingTopUp_img_gift08.png",
}

function UICoinShopWelfareReturnItem:OnEnter(tInfo, fnAction)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tInfo = tInfo
    self.fnAction = fnAction
    self:UpdateInfo()
end

function UICoinShopWelfareReturnItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICoinShopWelfareReturnItem:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        self.fnAction(self)
    end)
end

function UICoinShopWelfareReturnItem:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICoinShopWelfareReturnItem:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopWelfareReturnItem:UpdateInfo()
    local tInfo = self.tInfo
    UIHelper.SetString(self.LabelExamineRewardName, tInfo.uInnerChargeAmount .. g_tStrings.tInnerChargeType[tInfo.uInnerChargeType])
    local tDate = TimeToDate(tInfo.uExpiredTime)
    UIHelper.SetString(self.LabelExamineReward, FormatString(g_tStrings.STR_EXPIREDTIME, tDate.year, tDate.month, tDate.day))
    UIHelper.SetSpriteFrame(self.ImgCurrency, tInnerChargeTypeImg[tInfo.uInnerChargeType])
end


return UICoinShopWelfareReturnItem