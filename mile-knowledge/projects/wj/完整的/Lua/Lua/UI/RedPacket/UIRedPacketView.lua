-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UIRedPacketView
-- Date: 2023-11-20 15:51:48
-- Desc: 红包界面
-- ---------------------------------------------------------------------------------

local UIRedPacketView = class("UIRedPacketView")

local tbCoinImagePath =
{
    [1] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_TongBao_Big.png",
    [2] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_Jin_Big.png",
}

local tbCoinConditions =
{
    [1] = g_tStrings.STR_RED_GIFT_COINLIMIT1,
    [2] = g_tStrings.STR_RED_GIFT_MONEYLIMIT1,
}

local tbGIFT_CURRENCY_TYPE =
{
    [1] = GIFT_CURRENCY_TYPE.COIN,
    [2] = GIFT_CURRENCY_TYPE.MONEY
}

local tbGIFT_GET_LIMIT =
{
    [1] = GIFT_GET_LIMIT.NO_LIMIT,
    [2] = GIFT_GET_LIMIT.TONG,
    [3] = GIFT_GET_LIMIT.TEAM,
}

local tbCoinType =
{
    [1] = CurrencyType.Coin,
    [2] = CurrencyType.Money,
}

function UIRedPacketView:OnEnter(bDisableCoin)
    self.bDisableCoin = bDisableCoin
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIRedPacketView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIRedPacketView:BindUIEvent()
    for i, v in ipairs(self.tbIconTypeToggle) do
        if i == 1 and self.bDisableCoin then
            UIHelper.SetButtonState(v, BTN_STATE.Disable, "不支持发送通宝红包")
        end
        UIHelper.BindUIEvent(v , EventType.OnClick , function ()
            self:SwitchIconType(i)
        end)
    end

    for i, v in ipairs(self.tbReportTypeToggle) do
        UIHelper.BindUIEvent(v , EventType.OnClick , function ()
            self.nSelectReport = i
        end)
        UIHelper.ToggleGroupAddToggle(self.WidgetReportType , v)
    end

    UIHelper.BindUIEvent(self.BtnConfirm , EventType.OnClick , function ()
        local hPlayer = GetClientPlayer()

        local nGiftCount = tonumber(UIHelper.GetText(self.NumEditBox)) or 0
        local nCurrency = tonumber(UIHelper.GetText(self.TotalEditBox)) or 0
        local szComment = UIHelper.UTF8ToGBK(UIHelper.GetText(self.CongrasEditBox))
        if nGiftCount > 50 or nGiftCount < 5 then
            TipsHelper.ShowNormalTip(g_tStrings.STR_RED_GIFT_COUNTLIMIT)
            return
        end

        if self.nGiftCurrentcyType == GIFT_CURRENCY_TYPE.COIN then
            if nCurrency > 100000 or nCurrency < 2000 then
                TipsHelper.ShowNormalTip(g_tStrings.STR_RED_GIFT_COINLIMIT1)
                return
            end

            if nCurrency % 10 ~= 0 then
                TipsHelper.ShowNormalTip(g_tStrings.STR_RED_GIFT_COINLIMIT2)
                return
            end

            if nCurrency > hPlayer.nCoin then
                if not Web_QRCodeRecharge.JudgeEX(nCurrency - hPlayer.nCoin) then
                    TipsHelper.ShowNormalTip(g_tStrings.STR_RED_GIFT_COIN_NOMORE)
                end
                return
            end
        elseif self.nGiftCurrentcyType == GIFT_CURRENCY_TYPE.MONEY then
            local tMoney = hPlayer.GetMoney()
            local nGold = UnpackMoney(tMoney)

            if nCurrency > nGold then
                TipsHelper.ShowNormalTip(g_tStrings.STR_RED_GIFT_MONEY_NOMORE)
                return
            end
            if nCurrency > 800000 or nCurrency < 20000 then
                TipsHelper.ShowNormalTip(g_tStrings.STR_RED_GIFT_MONEYLIMIT1)
                return
            end

            if nCurrency % 10 ~= 0 then
                TipsHelper.ShowNormalTip(g_tStrings.STR_RED_GIFT_MONEYLIMIT2)
                return
            end
        end

        if not TextFilterCheck(szComment) then
            TipsHelper.ShowNormalTip(g_tStrings.STR_RED_GIFT_BLESS_LIMIT)
            return
        end
        RemoteCallToServer("On_Gift_CreateGiftRequest", nGiftCount, tbGIFT_GET_LIMIT[self.nSelectReport], self.nGiftCurrentcyType, nCurrency, szComment)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnClose , EventType.OnClick , function ()
        UIMgr.Close(self)
    end)

end

function UIRedPacketView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIRedPacketView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIRedPacketView:UpdateInfo()
    self.nSelectReport =  1
    self.tbCurrencyScript = {
        [1] = UIHelper.AddPrefab(PREFAB_ID.WidgetCoin, self.LayoutCurrency , nil , false),
        [2] = UIHelper.AddPrefab(PREFAB_ID.WidgetCurrency, self.LayoutCurrency),
    }
    local togIndex = self.bDisableCoin and 2 or 1
    UIHelper.SetToggleGroupSelected(self.TogChoiceRedPacket , togIndex-1)
    self:SwitchIconType(togIndex)
    UIHelper.SetText(self.NumEditBox, "")
    UIHelper.SetText(self.TotalEditBox, "")
    UIHelper.SetText(self.CongrasEditBox, "")
    UIHelper.SetOpacity(UIHelper.GetChildByName(self.CongrasEditBox, "PLACEHOLDER_LABEL"), 255)
end

function UIRedPacketView:SwitchIconType(index)

    self.nGiftCurrentcyType = tbGIFT_CURRENCY_TYPE[index]
    for k, v in pairs(self.tbWidgetTitle) do
        UIHelper.SetVisible(v , index == k)
    end
    UIHelper.SetSpriteFrame(self.ImgQuota ,tbCoinImagePath[index])
    UIHelper.SetString(self.LabelQuotaTips ,tbCoinConditions[index])
    for k, v in pairs(self.tbCurrencyScript) do
        UIHelper.SetVisible(v._rootNode , k == index)
    end
    UIHelper.LayoutDoLayout(self.LayoutCurrency)
end


return UIRedPacketView