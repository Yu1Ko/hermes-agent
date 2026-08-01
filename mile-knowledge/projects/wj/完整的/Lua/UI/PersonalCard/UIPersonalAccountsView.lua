-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPersonalAccountsView
-- Date: 2024-03-01 16:54:24
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPersonalAccountsView = class("UIPersonalAccountsView")

function UIPersonalAccountsView:OnEnter(tBuy)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    if CheckPlayerIsRemote() then
		return
	end

    self.tPersonalCardBuy = tBuy

    UIHelper.RemoveAllChildren(self.WidgetCurrency)
    self.RewardsScript = UIMgr.AddPrefab(PREFAB_ID.WidgetOtherCurrency, self.WidgetCurrency)
    self.RewardsScript:SetCurrencyType(CurrencyType.StorePoint)
    local nRewards = CoinShopData.GetRewards()
    self.RewardsScript:SetLableCount(nRewards)
    UIMgr.AddPrefab(PREFAB_ID.WidgetCoin, self.WidgetCurrency, CurrencyType.Coin, false)
    UIHelper.LayoutDoLayout(self.WidgetCurrency)

    UIHelper.SetTouchEnabled(self.TogTabCommon, false)

    self:UpdateInfo(tBuy)
end

function UIPersonalAccountsView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPersonalAccountsView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnPurchase, EventType.OnClick, function ()
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EXTERIOR, "CoinShop") then
            return
        end

        if CheckHaveUnPayOrder() then
            return
        end

        if CheckPlayerIsRemote(g_pClientPlayer.dwID, g_tStrings.tExteriorBuyRespond[EXTERIOR_BUY_RESPOND_CODE.SELF_REMOTE]) then
            return
        end

        local tBuy = {}
        for k, v in ipairs(self.tPersonalCardBuy) do
            if not self.tPersonalCardBuy[k].bCanCancel then
                self.nAllPrice = self.nAllPrice + v.nPrice
                table.insert(tBuy, v)
            end
        end
        if self.nAllPrice ~= 0 then
            local hCoinShopClient = GetCoinShopClient()
            local nRetCode = hCoinShopClient.Buy(tBuy, false)
            if nRetCode == COIN_SHOP_ERROR_CODE.SUCCESS then
                UIMgr.Close(self)
            else
                OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.tCoinShopNotify[nRetCode])
                OutputMessage("MSG_SYS", g_tStrings.tCoinShopNotify[nRetCode])
            end
        end
    end)

    Event.Reg(self, "SYNC_REWARDS", function ()
        local nRewards = CoinShopData.GetRewards()
        self.RewardsScript:SetLableCount(nRewards)
    end)

    Event.Reg(self, "FACE_LIFT_VOUCHERS_CHANGE", function ()
        local nRewards = CoinShopData.GetRewards()
        self.RewardsScript:SetLableCount(nRewards)
    end)

    Event.Reg(self, "ON_COIN_SHOP_VOUCHER_CHANGED", function ()
        local nRewards = CoinShopData.GetRewards()
        self.RewardsScript:SetLableCount(nRewards)
    end)
end

function UIPersonalAccountsView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPersonalAccountsView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPersonalAccountsView:UpdateInfo(tBuy)
    UIHelper.RemoveAllChildren(self.ScrollViewGoods)

    for i, tBuyItem in ipairs(tBuy) do
        local tInfo = Table_GetPersonalCardInfo(tBuyItem.nDecorationType, tBuyItem.dwGoodsID)
        local GoodsItemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetPersonalAccountsContent, self.ScrollViewGoods)
        if tInfo and GoodsItemScript then
            UIHelper.SetTexture(GoodsItemScript.ImgIcon, tInfo.szVKSmallPath)
            UIHelper.SetString(GoodsItemScript.LabelType, g_tStrings.STR_SHOW_CARD_DECORATION[tBuyItem.nDecorationType])
            UIHelper.SetString(GoodsItemScript.LabelName, UIHelper.GBKToUTF8(tInfo.szName))
            UIHelper.SetString(GoodsItemScript.LabelCostCoin, tBuyItem.nPrice)

            UIHelper.BindUIEvent(GoodsItemScript.TogSelect, EventType.OnSelectChanged, function (_, bSelected)
                if bSelected then
                    self.tPersonalCardBuy[i].bCanCancel = false
                else
                    self.tPersonalCardBuy[i].bCanCancel = true
                end

                self:UpdatePersonalCardCheckOutPrice()
            end)

        end
	end

    self:UpdatePersonalCardCheckOutPrice()
end

function UIPersonalAccountsView:UpdatePersonalCardCheckOutPrice(tBuy)
    UIHelper.SetString(self.LabelBuyNum, #self.tPersonalCardBuy)
    self.nAllPrice = 0
    local nCount = 0
    for k, v in ipairs(self.tPersonalCardBuy) do
        if not self.tPersonalCardBuy[k].bCanCancel then
            self.nAllPrice = self.nAllPrice + v.nPrice
            nCount = nCount + 1
        end
    end

    UIHelper.SetString(self.LabelNum, nCount)
    UIHelper.SetString(self.LabelNum01, nCount)
    UIHelper.SetString(self.LabelMoneyToatal, self.nAllPrice)
end

return UIPersonalAccountsView