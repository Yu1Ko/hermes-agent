-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UIRedPacketTakeGiftView
-- Date: 2023-11-28 10:42:06
-- Desc: 红包领取界面
-- ---------------------------------------------------------------------------------

local UIRedPacketTakeGiftView = class("UIRedPacketTakeGiftView")
local tbCoinImagePath =
{
    [1] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_TongBao_Big.png",
    [2] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_Jin_Big.png",
}
function UIRedPacketTakeGiftView:OnEnter(dwGiftID, nCoinType, nCurrency, szOwnerName ,szDesc , bIsGeneral)
    self.dwGiftID = dwGiftID
    self.nCoinType = nCoinType
    self.nCurrency = nCurrency
    self.szOwnerName = szOwnerName
    self.szDesc = szDesc
    self.bIsGeneral = bIsGeneral
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIRedPacketTakeGiftView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIRedPacketTakeGiftView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnConfirm , EventType.OnClick , function ()
        local szBlessMsg = UIHelper.GetText(self.EditBlessBox)
        if szBlessMsg == "" then
            TipsHelper.ShowNormalTip(g_tStrings.STR_RED_GIFT_BLESS_CHECK)
            return
        elseif not TextFilterCheck(UIHelper.UTF8ToGBK(szBlessMsg)) then
            TipsHelper.ShowNormalTip(g_tStrings.STR_RED_GIFT_BLESS_LIMIT)
            return
        end
        RemoteCallToServer("On_Gift_ModifyBlessRequest", self.dwGiftID, UIHelper.UTF8ToGBK(szBlessMsg), self.szOwnerName)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnClose , EventType.OnClick , function ()
        UIMgr.Close(self)
    end)
end

function UIRedPacketTakeGiftView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIRedPacketTakeGiftView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIRedPacketTakeGiftView:UpdateInfo()
    UIHelper.SetVisible(self.ImgYBIcon , self.nCoinType == GIFT_CURRENCY_TYPE.COIN)
    UIHelper.SetVisible(self.ImgJBIcon , self.nCoinType == GIFT_CURRENCY_TYPE.MONEY)
    if  self.nCoinType == GIFT_CURRENCY_TYPE.COIN then
        UIHelper.SetSpriteFrame(self.ImgNum ,tbCoinImagePath[1])
    else
        UIHelper.SetSpriteFrame(self.ImgNum ,tbCoinImagePath[2])
    end
    UIHelper.SetString(self.LabelNum , self.nCurrency)
    UIHelper.LayoutDoLayout(self.LayoutNum)
    UIHelper.SetString(self.LabelName , FormatString(g_tStrings.STR_GET_WHO_REDENVELOPE, UIHelper.GBKToUTF8(self.szOwnerName)))

    UIHelper.SetVisible(self.BtnConfirm , not self.bIsGeneral)
    UIHelper.SetVisible(self.WidgetBless , not self.bIsGeneral)

    UIHelper.SetString(self.LabelDesc , self.bIsGeneral and UIHelper.GBKToUTF8(self.szDesc) or "")
    UIHelper.SetText(self.EditBlessBox , self.EditBlessBox:getPlaceHolder())
end


return UIRedPacketTakeGiftView