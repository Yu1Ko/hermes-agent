-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetCard
-- Date: 2026-04-21 14:33:21
-- Desc: 大富翁 卡牌 WidgetCard
-- ---------------------------------------------------------------------------------

local UIWidgetCard = class("UIWidgetCard")

local PRICE_TEXT_COLOR = cc.c3b(255, 255, 255)
local PRICE_TEXT_COLOR_RED = cc.c3b(255, 117, 117)

function UIWidgetCard:OnEnter(nCardID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    if not nCardID then return end

    self.nCardID = nCardID
    self:UpdateInfo()
end

function UIWidgetCard:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetCard:BindUIEvent()
    UIHelper.BindUIEvent(self.TogCard, EventType.OnSelectChanged, function(_, bSelected)
        if self.fnSelectedCallback then
            self.fnSelectedCallback(bSelected)
        end
    end)
end

function UIWidgetCard:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetCard:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetCard:UpdateInfo()
    local nCardID = self.nCardID
    if not nCardID then
        return
    end

    local tCardInfo = Table_GetMonopolyCardInfoByID(nCardID)
    local bUseMoney = true
    if tCardInfo then
        bUseMoney = tCardInfo.bMoney ~= false
        UIHelper.SetString(self.LabelCardTitle, UIHelper.GBKToUTF8(tCardInfo.szName))
        -- local hCardBg = hContent:Lookup("Image_CardBg")
        -- if hCardBg and tCardInfo.szPath then
        --     hCardBg:FromUITex(tCardInfo.szPath, tCardInfo.nFrame)
        -- end
    end

    self.bUseMoney = bUseMoney

    UIHelper.SetVisible(self.ImgNotAvailable, false)
    UIHelper.SetVisible(self.ImgDiscard_New, false)
    UIHelper.SetVisible(self.ImgCost, false)
end

function UIWidgetCard:SetPrice(nPrice)
    self.nPrice = nPrice
    -- if hPriceText then
    --     hPriceText:SetText(tostring(nPrice or 0))
    -- end
    -- if hPriceIcon then
    --     hPriceIcon:SetFrame(bUseMoney and PRICE_ICON_FRAME.MONEY or PRICE_ICON_FRAME.POINT)
    -- end
    UIHelper.SetVisible(self.ImgCost, true)
    UIHelper.SetString(self.LabelCost, nPrice)
    local szIconPath = self.bUseMoney and "" or ""
    UIHelper.SetSpriteFrame(self.ImgCostIcon, szIconPath)
    UIHelper.LayoutDoLayout(self.LayoutCost)
end

function UIWidgetCard:InitBuyBtn(bIsBuyMode, bEnabled, fnCallback)
    if fnCallback then
        UIHelper.SetVisible(self.BtnBuy, true)
        UIHelper.SetString(self.LabelBuy, bIsBuyMode and "购买" or "出售")
        UIHelper.SetButtonState(self.BtnBuy, bEnabled and BTN_STATE.Normal or BTN_STATE.Disable)
        UIHelper.UnBindUIEvent(self.BtnBuy, EventType.OnClick)
        UIHelper.BindUIEvent(self.BtnBuy, EventType.OnClick, function()
            fnCallback()
        end)
    else
        UIHelper.SetVisible(self.BtnBuy, false)
        UIHelper.UnBindUIEvent(self.BtnBuy, EventType.OnClick)
    end
end

function UIWidgetCard:SetLackMoney(bLackMoney)
    UIHelper.SetButtonState(self.BtnBuy, bLackMoney and BTN_STATE.Disable or BTN_STATE.Normal)
    UIHelper.SetColor(self.LabelPrice, bLackMoney and PRICE_TEXT_COLOR_RED or PRICE_TEXT_COLOR)
end

function UIWidgetCard:SetSelected(bSelected)
    UIHelper.SetSelected(self.TogCard, bSelected)
end

function UIWidgetCard:SetVisible(bVisible)
    UIHelper.SetVisible(self._rootNode, bVisible)
end

function UIWidgetCard:SetSelectedCallback(fnSelectedCallback)
    self.fnSelectedCallback = fnSelectedCallback
end

function UIWidgetCard:SetNeedUnlockState(bNeedUnlock)
    UIHelper.SetVisible(self.ImgNotAvailable, bNeedUnlock)
end

return UIWidgetCard