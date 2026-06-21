-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIRideExteriorCheckOutView
-- Date: 2024-03-01 16:54:24
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIRideExteriorCheckOutView = class("UIRideExteriorCheckOutView")

local EXTERIOR_TYPE = {
    HORSE = 3,
    EQUIP = 4,
}

local fnSort = function(a, b)
    if a.bEquip == b.bEquip then
        if a.bEquip then
            return a.nExteriorSlot < b.nExteriorSlot
        else
            return a.dwExteriorID < b.dwExteriorID
        end
    end
    return not a.bEquip
end

function UIRideExteriorCheckOutView:ConfirmSet()
    local tSetList = {}
    for k, v in ipairs(self.tRideExteriorBuy) do
        if not self.tRideExteriorBuy[k].bCancel then
            table.insert(tSetList, {dwExteriorID = v.dwExteriorID, bEquip = v.bEquip})
        end
    end
    for i, v in ipairs(self.tRideExteriorSet) do
        table.insert(tSetList, {dwExteriorID = v.dwExteriorID, bEquip = v.bEquip})
    end
    RideExteriorData.SetExterior(tSetList)
end

function UIRideExteriorCheckOutView:OnEnter(tBuy, tSet, bOnlyBuy)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    table.sort(tBuy, fnSort)
    table.sort(tSet, fnSort)
    self.tRideExteriorBuy = tBuy
    self.tRideExteriorSet = tSet
    self.bOnlyBuy = bOnlyBuy

    UIHelper.RemoveAllChildren(self.WidgetCurrency)
    UIHelper.AddPrefab(PREFAB_ID.WidgetCurrency, self.WidgetCurrency)
    UIHelper.LayoutDoLayout(self.WidgetCurrency)

    UIHelper.SetTouchEnabled(self.TogTabCommon, false)

    self:UpdateInfo()
end

function UIRideExteriorCheckOutView:RegEvent()
    Event.Reg(self, "ON_BUY_HORSE_EXTERIOR_MESSAGE_NOTIFY",function (nRetCode)
        LOG.INFO("ON_BUY_HORSE_EXTERIOR_MESSAGE_NOTIFY")
        if nRetCode == HORSE_EXTERIOR_BUY_ERROR_CODE.SUCCESS then
            OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_GROUPON_MEMBER_STATE_TIP_5)
            OutputMessage("MSG_SYS", g_tStrings.STR_GROUPON_MEMBER_STATE_TIP_5 .. "\n")
            if self.bOnlyBuy then
                UIMgr.Close(self)
                return
            end
            self:ConfirmSet()
            UIMgr.Close(self)
        end
    end)
    Event.Reg(self, EventType.OnWindowsSizeChanged, function (szName)
        Timer.AddFrame(self, 5, function()
            local childrens = UIHelper.GetChildren(self.LabelMoneyToatal)
            local fSumWidth = 0
            for _, children in ipairs(childrens) do
                local fWidth = UIHelper.GetWidth(children)
                fSumWidth = fSumWidth + fWidth
            end
            UIHelper.SetWidth(self.LabelMoneyToatal, fSumWidth)
        end)
    end)
end

function UIRideExteriorCheckOutView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
    TipsHelper.DeleteAllHoverTips()
end

function UIRideExteriorCheckOutView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnPurchase, EventType.OnClick, function ()
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.SHOP, "") then
            return
        end
        local tBuyList = {}
        for i, v in ipairs(self.tRideExteriorBuy) do
            if not self.tRideExteriorBuy[i].bCancel then
                if v.bEquip then
                    table.insert(tBuyList, {dwExteriorID = v.dwExteriorID, nExteriorType = EXTERIOR_TYPE.EQUIP})
                else
                    table.insert(tBuyList, {dwExteriorID = v.dwExteriorID, nExteriorType = EXTERIOR_TYPE.HORSE})
                end
            end
        end
        if #tBuyList > 0 then
            local hMgr = GetHorseExteriorManager()
            local nRetCode = hMgr.BuyMultiExterior(tBuyList)
            if nRetCode ~= HORSE_EXTERIOR_BUY_ERROR_CODE.SUCCESS then
                OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.tBuyRideExteriortWarn[nRetCode])
                OutputMessage("MSG_SYS", g_tStrings.tBuyRideExteriortWarn[nRetCode] .. "\n")
            end
            UIHelper.SetButtonState(self.BtnPurchase, BTN_STATE.Disable)
        elseif #self.tRideExteriorSet > 0 then
            self:ConfirmSet()
            UIMgr.Close(self)
        end
    end)
end

function UIRideExteriorCheckOutView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIRideExteriorCheckOutView:UpdateInfo()
    UIHelper.RemoveAllChildren(self.ScrollViewGoods)

    for i, tBuyItem in ipairs(self.tRideExteriorBuy) do
        local GoodsItemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetRideExteriorCheckOut, self.ScrollViewGoods, tBuyItem, tBuyItem.nExteriorSlot)

        UIHelper.BindUIEvent(GoodsItemScript.TogSelect, EventType.OnSelectChanged, function (_, bSelected)
            if bSelected then
                self.tRideExteriorBuy[i].bCancel = false
            else
                self.tRideExteriorBuy[i].bCancel = true
            end

            self:UpdateRideExteriorCheckOutPrice()
        end)
	end

    for i, tSetItem in ipairs(self.tRideExteriorSet) do
        local GoodsItemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetRideExteriorCheckOut, self.ScrollViewGoods, tSetItem, tSetItem.nExteriorSlot, true)
	end

    self:UpdateRideExteriorCheckOutPrice()
end

function UIRideExteriorCheckOutView:UpdateRideExteriorCheckOutPrice(tBuy)
    UIHelper.SetString(self.LabelBuyNum, #self.tRideExteriorBuy)
    self.nAllPrice = 0
    local nCount = 0
    for k, v in ipairs(self.tRideExteriorBuy) do
        if not self.tRideExteriorBuy[k].bCancel then
            local tExteriorInfo = RideExteriorData.GetRideExteriorInfo(v.dwExteriorID, v.bEquip)
            self.nAllPrice = self.nAllPrice + tExteriorInfo.nPrice
            nCount = nCount + 1
        end
    end

    UIHelper.SetString(self.LabelNum, nCount)
    UIHelper.SetString(self.LabelNum01, nCount)
    UIHelper.SetString(self.LabelMoneyToatal, "")
    local color = cc.c3b(255, 255, 255)
    local bMoney = true
    if MoneyOptCmp({nGold = self.nAllPrice}, g_pClientPlayer.GetMoney()) > 0 then
        color = cc.c3b(255, 0, 0)
        bMoney = false
    end
    if nCount > 0 and (not self.bOnlyBuy) then
        UIHelper.SetString(self.LabelPurchase, g_tStrings.STR_RIDE_EXTERIOR_BUY_AND_SAVE)
    elseif nCount > 0 and self.bOnlyBuy then
        UIHelper.SetString(self.LabelPurchase, g_tStrings.STR_RIDE_EXTERIOR_BUY)
    else
        UIHelper.SetString(self.LabelPurchase, g_tStrings.STR_RIDE_EXTERIOR_SAVE)
    end
    local bEnable = bMoney and (nCount > 0 or #self.tRideExteriorSet > 0)
    UIHelper.SetButtonState(self.BtnPurchase, bEnable and BTN_STATE.Normal or BTN_STATE.Disable)
    UIHelper.SetMoneyText(self.LabelMoneyToatal, {nGold = self.nAllPrice}, 25, false, nil, color)
    UIHelper.LayoutDoLayout(self.LayoutMoney)
end

return UIRideExteriorCheckOutView