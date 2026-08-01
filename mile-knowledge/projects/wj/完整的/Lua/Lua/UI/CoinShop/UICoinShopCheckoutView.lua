-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopCheckoutView
-- Date: 2022-12-16 11:20:02
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICoinShopCheckoutView = class("UICoinShopCheckoutView")

local Page2Tog = {
    [1] = "TogTabRestrict",
    [2] = "TogTabCommon",
}

local function stable_sort(arr, comp)
    local indexed_arr = {}

    for i, value in ipairs(arr) do
        indexed_arr[i] = {index = i, value = value}
    end

    table.sort(indexed_arr, function(a, b)
        if comp(a.value, b.value) then
            return true
        elseif comp(b.value, a.value) then
            return false
        else
            return a.index < b.index
        end
    end)

    for i, entry in ipairs(indexed_arr) do
        arr[i] = entry.value
    end
end

function UICoinShopCheckoutView:OnEnter(tbGoods, bSave, bFromLimit)
    CoinShopData.SetIsBuying(false)
    CoinShopData.UpdateBuyItemState(tbGoods, bSave)
    self.bSave = bSave

    self.tbLimitGoods = {}
    self.tbNormalGoods = {}
    for _, tbGoodsInfo in ipairs(tbGoods) do
        if tbGoodsInfo.bLimitItem then
            table.insert(self.tbLimitGoods, tbGoodsInfo)
        else
            table.insert(self.tbNormalGoods, tbGoodsInfo)
        end
    end

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    local tbCurrentVoucher = CoinShopData.GetCurrentCoinShopVoucher()
    local nCurrentVoucher = tbCurrentVoucher and tbCurrentVoucher.nCount or 0
    if nCurrentVoucher > 0 and not self.VoucherScript then
        self.VoucherScript = UIMgr.AddPrefab(PREFAB_ID.WidgetOtherCurrency, self.WidgetCurrency)
        self.VoucherScript:SetCurrencyType(CurrencyType.CoinShopVoucher)
    end
    if self.VoucherScript then
        self.VoucherScript:SetLableCount(nCurrentVoucher)
    end

    if GetFaceLiftManager() then
        local nVouchars = GetFaceLiftManager().GetVouchers()
        if nVouchars > 0 then
            self.FaceVoucherScript = UIMgr.AddPrefab(PREFAB_ID.WidgetOtherCurrency, self.WidgetCurrency)
            self.FaceVoucherScript:SetCurrencyType(CurrencyType.FaceVouchers)
        end

        if self.FaceVoucherScript then
            self.FaceVoucherScript:SetLableCount(nVouchars)
        end
    end

    self.RewardsScript = UIMgr.AddPrefab(PREFAB_ID.WidgetOtherCurrency, self.WidgetCurrency)
    self.RewardsScript:SetCurrencyType(CurrencyType.StorePoint)

    self.MoneyScript = UIMgr.AddPrefab(PREFAB_ID.WidgetCurrency, self.WidgetCurrency)

    local bShowRecharge = Platform.IsWindows() or (Platform.IsAndroid() and not Channel.Is_dylianyunyun())
    UIMgr.AddPrefab(PREFAB_ID.WidgetCoin, self.WidgetCurrency, CurrencyType.Coin, false, nil, bShowRecharge)

    UIHelper.LayoutDoLayout(self.WidgetCurrency)

    UIHelper.ToggleGroupAddToggle(self.WidgetAnchorLeft, self.TogTabRestrict)
    UIHelper.ToggleGroupAddToggle(self.WidgetAnchorLeft, self.TogTabCommon)
    UIHelper.SetVisible(self.TogTabRestrict, #self.tbLimitGoods > 0)
    UIHelper.SetString(self.LabelNumLimit, #self.tbLimitGoods)
    UIHelper.SetString(self.LabelNumLimitSelect, #self.tbLimitGoods)
    UIHelper.SetVisible(self.TogTabCommon, #self.tbNormalGoods > 0)
    UIHelper.SetString(self.LabelNumNormal, #self.tbNormalGoods)
    UIHelper.SetString(self.LabelNumNormalSelect, #self.tbNormalGoods)
    UIHelper.LayoutDoLayout(self.LayoutLeft)

    -- 将普通商品排下序
    local fnSort = function(tLeft, tRight)
        local bCollect1, nGold1 = CoinShop_GetCollectInfo(tLeft.eGoodsType, tLeft.dwGoodsID)
        local bCollect2, nGold2 = CoinShop_GetCollectInfo(tRight.eGoodsType, tRight.dwGoodsID)
        if (not bCollect1 and nGold1 >= 0) and (bCollect2 or nGold2 < 0) then
            return true
        elseif bCollect1 and (not bCollect2 and nGold2 < 0) then
            return true
        else
            return false
        end
    end
    stable_sort(self.tbNormalGoods, fnSort)

    local nPage
    if (bFromLimit or #self.tbNormalGoods <= 0) and #self.tbLimitGoods > 0 then
        nPage = 1
        self:OnSelectedLimit()
    else
        nPage = 2
        self:OnSelectedNormal()
    end
    UIHelper.SetToggleGroupSelectedToggle(self.WidgetAnchorLeft, self[Page2Tog[nPage]])

    UIHelper.SetVisible(self.BtnCloseTip, false)
end

function UICoinShopCheckoutView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UICoinShopCheckoutView:BindUIEvent()
    -- 关闭按钮
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    -- 去充值按钮
    UIHelper.BindUIEvent(self.BtnGoPayCenter, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelTopUpMain)
    end)

    -- 购买按钮
    UIHelper.BindUIEvent(self.BtnBuy, EventType.OnClick, function ()
        self:OnBuyBtnClick()
    end)

    UIHelper.BindUIEvent(self.BtnCloesDropList, EventType.OnClick, function ()
        UIHelper.SetSelected(self.TogDisCoupon, false)
    end)

    UIHelper.BindUIEvent(self.BtnCollect, EventType.OnClick, function ()
        self:CollectAll(g_tStrings.COLLECT_ALL_SURE)
    end)

    -- UIHelper.BindUIEvent(self.TogDisCoupon, EventType.OnSelectChanged, function (_, bSelected)
    --     if bSelected then
    --         Timer.AddFrame(self, 1, function ()
    --             for _, script in pairs(self.tbDisCouponScriptList) do
    --                 UIHelper.LayoutDoLayout(script.LayourReduction)
    --             end
    --         end)
    --     end
    -- end)

    UIHelper.BindUIEvent(self.TogTabRestrict, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            self:OnSelectedLimit()
        end
    end)

    UIHelper.BindUIEvent(self.TogTabCommon, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            self:OnSelectedNormal()
        end
    end)
end

function UICoinShopCheckoutView:RegEvent()
    Event.Reg(self, "COIN_SHOP_BUY_RESPOND", function (nErrorCode)
        if nErrorCode == COIN_SHOP_ERROR_CODE.SUCCESS then
            UIMgr.Close(self)
        end
    end)

    Event.Reg(self, "COIN_SHOP_SAVE_RESPOND", function (nErrorCode)
        UIMgr.Close(self)
    end)

    Event.Reg(self, "SYNC_REWARDS", function ()
        self:UpdateCurreny()
    end)

    Event.Reg(self, "FACE_LIFT_VOUCHERS_CHANGE", function ()
        self:UpdateCurreny()
    end)

    Event.Reg(self, "ON_COIN_SHOP_VOUCHER_CHANGED", function ()
        self:UpdateCurreny()
    end)

    Event.Reg(self, "WEAPON_EXTERIOR_COLLECT_RESULT", function ()
        if arg1 == EXTERIOR_COLLECT_RESULT_CODE.SUCCESS then
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, "EXTERIOR_COLLECT_RESULT", function ()
        if arg1 == EXTERIOR_COLLECT_RESULT_CODE.SUCCESS then
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function ()
        for _, itemScript in ipairs(self.tbGoodsItemScriptList) do
            itemScript:SelectItemIcon(false)
        end
    end)

    Event.Reg(self, "ON_CHANGE_BODY_BONE_NOTIFY", function (nBodyIndex, nMethod)
        if nMethod == BODY_RESHAPING_OPERATE_METHOD.ADD or nMethod == BODY_RESHAPING_OPERATE_METHOD.REPLACE then
            UIMgr.Close(self)
        end
    end)

    Event.Reg(self, "FACE_LIFT_NOTIFY", function (nErrorCode)
		if nErrorCode == FACE_LIFT_ERROR_CODE.BUY_SUCCESS then
            UIMgr.Close(self)
        end
    end)

    Event.Reg(self, "SYNC_COIN", function()
        self:UpdatePrice(true)
    end)
end

function UICoinShopCheckoutView:UnRegEvent()
    Event.UnRegAll(self)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopCheckoutView:UpdateInfo()
    self:UpdateCurreny()
    self:SetupDisCouponList()
    self:UpdateGoodsList()
    self:UpdatePrice()
end

function UICoinShopCheckoutView:OnSelectedLimit()
    self.tbGoods = self.tbLimitGoods
    self.bLimit = true
    self:UpdateInfo()
end

function UICoinShopCheckoutView:OnSelectedNormal()
    self.tbGoods = self.tbNormalGoods
    self.bLimit = false
    self:UpdateInfo()
end

function UICoinShopCheckoutView:UpdateGoodsList()
    UIHelper.RemoveAllChildren(self.ScrollViewGoods)
    UIHelper.RemoveAllChildren(self.ScrollViewLimitGoods)
    UIHelper.SetVisible(self.ScrollViewGoods, not self.bLimit)
    UIHelper.SetVisible(self.WidgetRestrict, self.bLimit)

    CoinShopData.CalcBill(self.tbGoods, self.tbDisCoupon)

    self.tbGoodsItemScriptList = {}
    local scrollView = self.bLimit and self.ScrollViewLimitGoods or self.ScrollViewGoods
    for i, tbGoodsInfo in ipairs(self.tbGoods) do
        if tbGoodsInfo.nState ~= ACCOUNT_ITEM_STATUS.OFF then
            local GoodsItemScript = nil
            GoodsItemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetSettleAccountsContent, scrollView)
            GoodsItemScript:OnEnter(tbGoodsInfo, i, function ()
                if tbGoodsInfo.bLimitItem and tbGoodsInfo.bChoose then
                    for _, script in ipairs(self.tbGoodsItemScriptList) do
                        if script.tbGoodsInfo.dwGoodsID ~= tbGoodsInfo.dwGoodsID and script.tbGoodsInfo.bChoose then
                            script.tbGoodsInfo.bChoose = false
                            UIHelper.SetSelected(script.TogSelect, false, false)
                        end
                    end
                end
                self:SetupDisCouponList()
                self:UpdatePrice()
            end,
            nil, nil)
            table.insert(self.tbGoodsItemScriptList, GoodsItemScript)
        end
    end
    UIHelper.ScrollViewDoLayoutAndToTop(scrollView)

    Timer.AddFrame(self, 1, function ()
        self:UpdatePrice()
    end)
end

function UICoinShopCheckoutView:UpdateCurreny()
    local nRewards = CoinShopData.GetRewards()
    self.RewardsScript:SetLableCount(nRewards)

    local tbCurrentVoucher = CoinShopData.GetCurrentCoinShopVoucher()
    local nCurrentVoucher = tbCurrentVoucher and tbCurrentVoucher.nCount or 0
    if nCurrentVoucher > 0 and not self.VoucherScript then
        self.VoucherScript = UIMgr.AddPrefab(PREFAB_ID.WidgetOtherCurrency, self.WidgetCurrency)
        self.VoucherScript:SetCurrencyType(CurrencyType.CoinShopVoucher)
    end
    if self.VoucherScript then
        self.VoucherScript:SetLableCount(nCurrentVoucher)
    end

    if GetFaceLiftManager() then
        local nVouchars = GetFaceLiftManager().GetVouchers()
        if nVouchars > 0 then
            self.FaceVoucherScript = self.FaceVoucherScript or UIMgr.AddPrefab(PREFAB_ID.WidgetOtherCurrency, self.WidgetCurrency)
            self.FaceVoucherScript:SetCurrencyType(CurrencyType.FaceVouchers)
        end

        if self.FaceVoucherScript then
            self.FaceVoucherScript:SetLableCount(nVouchars)
        end
    end

    UIHelper.LayoutDoLayout(self.WidgetCurrency)

    --  TODO: 添加捏脸币
    -- local tbCurrentVoucher = CoinShopData.GetCurrentCoinShopVoucher()
    -- local nCurrentVoucher = tbCurrentVoucher and tbCurrentVoucher.nCount or 0
    -- UIHelper.SetString(self.LabelCurrency_Vouchers, nCurrentVoucher)
    -- UIHelper.SetVisible(UIHelper.GetParent(self.LabelCurrency_Vouchers), nCurrentVoucher ~= 0)

    -- UIHelper.CascadeDoLayoutDoWidget(self.LayoutCurrency, true, true)
end

function UICoinShopCheckoutView:UpdatePrice(bNotSelectDisCoupon)
    self.tbBill = CoinShopData.CalcBill(self.tbGoods, self.tbDisCoupon)
    if not bNotSelectDisCoupon then
        local dwDisCouponID = CoinShopData.IntelligentSelectDisCoupon(self.tbGoods)
        for _, tbDisCoupon in ipairs(self.tbDisCouponList) do
            if tbDisCoupon.dwDisCouponID == dwDisCouponID then
                self:UpdateCurDisCoupon(tbDisCoupon)
                break
            end
        end
    end

    UIHelper.SetString(self.LabelBuyNum, self.tbBill.nBuyCount)
    UIHelper.SetString(self.LabelBtnBuy, string.format(g_tStrings.COIN_SHOP_BUY_BTN_LABEL, self.tbBill.nBuyCount))
    UIHelper.SetButtonState(self.BtnBuy, self.tbBill.nBuyCount > 0 and BTN_STATE.Normal or BTN_STATE.Disable)
    UIHelper.SetString(self.LabelRebate, 0) -- 返还

    local bShowWorthPrice = false
    if self.tbBill.tbDisCoupon and self.tbBill.tbDisCoupon.nType ~= 0 then
        UIHelper.SetString(self.LabelCostRewards, self.tbBill.nRewards)
        UIHelper.SetString(self.LabelCostCoin, self.tbBill.nDisCouponCoin)
        UIHelper.SetString(self.LabelWorthRewards, self.tbBill.nRewards)
        UIHelper.SetString(self.LabelWorthCoin, self.tbBill.nCoin)
        bShowWorthPrice = true
    else
        UIHelper.SetString(self.LabelCostRewards, self.tbBill.nRewards)
        UIHelper.SetString(self.LabelCostCoin, self.tbBill.nCoin - self.tbBill.nUseVouchars)
    end

    local bLessMoney, _nCoin, nLackCoin, _, nLackRewards = CoinShopData.IsLessMoney(self.tbBill)
    local lackColor = cc.c4b(255, 118, 118, 255)
    local normalColor =  cc.c4b(255, 248, 209, 255)
    UIHelper.SetTextColor(self.LabelCostRewards, bLessMoney and nLackRewards and lackColor or normalColor)
    UIHelper.SetTextColor(self.LabelCostCoin, bLessMoney and nLackCoin and lackColor or normalColor)

    UIHelper.SetVisible(self.WdigetDiscounts, bShowWorthPrice)
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutBill, true, true)
    UIHelper.WidgetFoceDoAlignAssignNode(self, self.ImgInitialWorthCoin)
    UIHelper.WidgetFoceDoAlignAssignNode(self, self.ImgInitialWorthRewards)

    if self.tbGoodsItemScriptList then
        for _, GoodsItemScript in ipairs(self.tbGoodsItemScriptList) do
            GoodsItemScript:UpdatePrice()
        end
    end

    local _, _, nAllGold, bHave = self:GetCollectList()
    UIHelper.SetVisible(self.WidgetCollect, bHave)
    UIHelper.SetString(self.LabelCollect, nAllGold)
    -- 根据一键收集按钮是否出现，刷新一下scrollview列表
    if bHave then
        if UIHelper.GetVisible(self.ScrollViewCoupons) then
            self:UpdateDisCouponList()
        end
    else
        if UIHelper.GetVisible(self.ScrollViewCouponsShort) then
            self:UpdateDisCouponList()
        end
    end
end

function UICoinShopCheckoutView:OnBuyBtnClick()
    if CoinShopData.IsBuying() then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tCoinShopNotify[COIN_SHOP_ERROR_CODE.BUYING])
		OutputMessage("MSG_SYS", g_tStrings.tCoinShopNotify[COIN_SHOP_ERROR_CODE.BUYING])
        return
    end

    local tbGoods = self.tbGoods

    -- 检查优惠券可用
    if not CoinShopData.CheckDisCouponUsable(tbGoods, self.tbBill) then
        --SelectDisCoupon(hFrame, -1)
        return
    end

    -- 检查Coin、Reward足够
    local bLessMoney, _nCoin, nLackCoin, _, nLackRewards = CoinShopData.IsLessMoney(self.tbBill)
    if bLessMoney then
        if nLackCoin then
            if (Platform.IsAndroid() and not Channel.Is_dylianyunyun()) or Platform.IsWindows() or Platform.IsMac() then
                --UIHelper.ShowConfirm("通宝不足，是否前往充值", function()
                    --UIMgr.Open(VIEW_ID.PanelTopUpMain)
                    ---@see UICustomRechargeCoinView
                    UIMgr.Open(VIEW_ID.PanelQuickPop, PayData.tCustomRechargeMode.BuChaJia, _nCoin)
                --end)
            else
                TipsHelper.ShowNormalTip("通宝余额不足")
            end
        elseif nLackRewards then
            TipsHelper.ShowNormalTip("商城积分余额不足")
        end
        return
    end

    local _, _, _, bHave = self:GetCollectList()
    if bHave then
        self:CollectAll(g_tStrings.BUY_COLLECT_ALL_SURE)
		return
    end

    if self.tbDisCoupon and self.tbDisCoupon.nType ~= 0 and self.tbBill.nCoin > 0 then
        local szMsg = string.format(g_tStrings.DIS_COUPON_USE_MESSAGE, UIHelper.GBKToUTF8(self.tbDisCoupon.szMenuOption), self.tbBill.nDisCouponSaveCoin)
        UIHelper.ShowConfirm(szMsg, function ()
            self:Buy(tbGoods)
        end)
    else
        self:Buy(tbGoods)
    end
end

function UICoinShopCheckoutView:Buy(tbGoods)
    CoinShopData.Buy(tbGoods, self.tbBill, self.bSave and not self.bLimit)
end

function UICoinShopCheckoutView:SetupDisCouponList()
    self.tbDisCouponList = CoinShopData.GetUsableDisCouponList(self.tbGoods)
    local tbNoneDisCoupon = { dwDisCouponID = 0, nType = 0 }
    self.tbDisCoupon = self.tbDisCouponList[1] or tbNoneDisCoupon
    self:UpdateDisCouponList()
end

function UICoinShopCheckoutView:UpdateDisCouponList()
    UIHelper.RemoveAllChildren(self.ScrollViewCoupons)
    UIHelper.RemoveAllChildren(self.ScrollViewCouponsShort)
    UIHelper.SetVisible(self.ScrollViewCoupons, false)
    UIHelper.SetVisible(self.ScrollViewCouponsShort, false)
    self.tbDisCouponScriptList = {}

    local _, _, nAllGold, bHave = self:GetCollectList()
    local scrollView
    if bHave then
        scrollView = self.ScrollViewCouponsShort
    else
        scrollView = self.ScrollViewCoupons
    end
    local tbNoneDisCoupon = { dwDisCouponID = 0, nType = 0 }
    for _, tbDisCoupon in ipairs(self.tbDisCouponList) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetCouponsCell, scrollView)
        script:OnEnter(tbDisCoupon)
        script:SetSelectedCallback(function(_, bSelected)
            if bSelected then
                self:UpdateCurDisCoupon(tbDisCoupon)
            else
                self:UpdateCurDisCoupon(tbNoneDisCoupon)
            end
        end)
        table.insert(self.tbDisCouponScriptList, script)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(scrollView)
    UIHelper.SetVisible(scrollView, #self.tbDisCouponList > 0)
    UIHelper.SetVisible(self.WidgetEmptyCoupons, #self.tbDisCouponList <= 0)

    self:UpdateCurDisCoupon(self.tbDisCoupon)
end

function UICoinShopCheckoutView:UpdateCurDisCoupon(tbDisCoupon)
    for _, script in ipairs(self.tbDisCouponScriptList) do
        local bSame = tbDisCoupon.dwDisCouponID == script.tbDisCoupon.dwDisCouponID
        script:SetSelected(bSame, false)
    end

    if tbDisCoupon.dwDisCouponID ~= self.tbDisCoupon.dwDisCouponID then
        self.tbDisCoupon = tbDisCoupon
        self:UpdatePrice(true)
    end

    if #self.tbDisCouponList <= 0 then
        UIHelper.SetString(self.LabelTipCoupons, "暂无优惠券")
    elseif self.tbDisCoupon.dwDisCouponID == 0 then
        UIHelper.SetString(self.LabelTipCoupons, "不使用优惠券")
    else
        UIHelper.SetString(self.LabelTipCoupons, "已选择优惠券")
    end
end

function UICoinShopCheckoutView:GetCollectList()
    local tExterior = {}
    local tWeapon 	= {}
    local nAllGold 	= 0
    for _, script in ipairs(self.tbGoodsItemScriptList) do
        local tbGoodsInfo = script.tbGoodsInfo
        local nState = tbGoodsInfo.nState
        local bCollect, nGold = CoinShop_GetCollectInfo(tbGoodsInfo.eGoodsType, tbGoodsInfo.dwGoodsID)
        if nState == ACCOUNT_ITEM_STATUS.NORMAL and tbGoodsInfo.bChoose and not bCollect and (nGold and nGold >= 0) then
            nAllGold = nAllGold + nGold
            if tbGoodsInfo.eGoodsType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
                table.insert(tExterior, tbGoodsInfo.dwGoodsID)
            elseif tbGoodsInfo.eGoodsType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
                table.insert(tWeapon, tbGoodsInfo.dwGoodsID)
            end
        end
    end
    local bHave = (#tExterior + #tWeapon) > 0
    return tExterior, tWeapon, nAllGold, bHave
end

function UICoinShopCheckoutView:CollectAll(szMsg)
	local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
	local tExterior, tWeapon, nAllGold = self:GetCollectList()
	local tMoney = hPlayer.GetMoney()
    local nMyGold = UnpackMoney(tMoney)
	if nAllGold > nMyGold then
        UIHelper.ShowConfirm(g_tStrings.COLLECT_LESS_MONEY)
		return
	end

	local fnSureAction = function()
		for _, dwID in ipairs(tExterior) do
			local nRetCode = hPlayer.CollectExterior(dwID)
			if nRetCode ~= EXTERIOR_COLLECT_RESULT_CODE.SUCCESS then
				local szExteriorName = CoinShop_GetGoodsName(COIN_SHOP_GOODS_TYPE.EXTERIOR, dwID)
				local szMsg = g_tStrings.tCollectRespond[nRetCode]
				OutputMessage("MSG_ANNOUNCE_YELLOW", UIHelper.GBKToUTF8(szExteriorName) .. szMsg)
				OutputMessage("MSG_SYS", UIHelper.GBKToUTF8(szExteriorName) .. szMsg .. "\n")
			end
		end
		for _, dwID in ipairs(tWeapon) do
			local nRetCode = hPlayer.CollectWeaponExterior(dwID)
			if nRetCode ~= EXTERIOR_COLLECT_RESULT_CODE.SUCCESS then
				local szExteriorName = CoinShop_GetGoodsName(COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR, dwID)
				local szMsg = g_tStrings.tCollectRespond[nRetCode]
				OutputMessage("MSG_ANNOUNCE_YELLOW", UIHelper.GBKToUTF8(szExteriorName) .. szMsg)
				OutputMessage("MSG_SYS", UIHelper.GBKToUTF8(szExteriorName) .. szMsg .. "\n")
			end
		end
    end

	local szMessage = FormatString(szMsg, nAllGold)
    UIHelper.ShowConfirm(szMessage, fnSureAction)
end

return UICoinShopCheckoutView
