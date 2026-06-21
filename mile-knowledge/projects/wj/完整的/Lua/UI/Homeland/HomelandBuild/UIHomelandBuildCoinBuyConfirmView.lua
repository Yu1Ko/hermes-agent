-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildCoinBuyConfirmView
-- Date: 2023-12-20 10:48:52
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildCoinBuyConfirmView = class("UIHomelandBuildCoinBuyConfirmView")

local colorRed = cc.c3b(255, 133, 125)
local colorWhite = cc.c3b(255, 255, 255)

--------------------------通宝购买------------------------------
local MAX_NUM = 9999
local MAX_BUY_ITEM_NUM = 30
local DataModel = {}

--------------------------金币购买------------------------------
local MONEY_BUY_MAX_GOLD = 10000
local MONEY_BUY_MAX_NUM = 9999
local MONEY_BUY_MAX_BUY_ITEM_NUM = 100
local MONEY_BUY_CONFIRM_TIME = 3
local MONEY_BUY_START_BATCH = 10000
local nMaxBatch = MONEY_BUY_START_BATCH
local nNowBatch = MONEY_BUY_START_BATCH
local tBatchBuyInfo = {}
local nConfirmTime = 0
local MoneyBuyDataModel = {}

--[[
tFurniture = {
	{[dwFurnitureID] = 1062, [nNum] = 2}
}
--]]
function DataModel.Init(tFurniture)
	DataModel.tFurniture = tFurniture
	local pPlayer = GetClientPlayer()
	if not pPlayer then
		return
	end
	DataModel.nPlayerCoin = pPlayer.nCoin
	DataModel.nSelectDisCoupon = -1
	DataModel.tDisCouponList = {}
	DataModel.nCouponSaveCoin = 0
	DataModel.InitBuyInfo()
end

function DataModel.UnInit()
	DataModel.tFurniture = nil
	DataModel.nPlayerCoin = nil
	DataModel.tSingleBuy = nil
	DataModel.tMultBuy = nil
	DataModel.tDisCouponList = nil
	DataModel.nSelectDisCoupon = -1
end

function DataModel.InitBuyInfo()
	if #DataModel.tFurniture == 1 then
		DataModel.UpdateSingleBuy()
	elseif #DataModel.tFurniture > 1 then
		DataModel.UpdateMultBuy()
	end
	local tBuyInfo = DataModel.GetAccountInfo()
	DataModel.tDisCouponList = FurnitureBuy.GetUsableFurnitureDisCouponList(tBuyInfo)
end

function DataModel.UpdateSingleBuy()
	local pHomelandMgr = GetHomelandMgr()
	if not pHomelandMgr then
		return
	end

	DataModel.tSingleBuy = {}
	local tInfo = DataModel.tSingleBuy
	tInfo.dwFurnitureID = DataModel.tFurniture[1].dwFurnitureID
	tInfo.nNum = DataModel.tFurniture[1].nNum

	local tItemInfo = FurnitureData.GetFurnInfoByTypeAndID(HS_FURNITURE_TYPE.FURNITURE, tInfo.dwFurnitureID)
	tInfo.szName = tItemInfo.szName
	tInfo.nQuality = tItemInfo.nQuality
	local nItemUiId = pHomelandMgr.MakeFurnitureUIID(HS_FURNITURE_TYPE.FURNITURE, tInfo.dwFurnitureID)
	local tLine = Table_GetFurnitureAddInfo(nItemUiId)
	tInfo.nFrame = tLine.nFrame
	tInfo.szPath = tLine.szPath

	local tGoodsInfo = FurnitureBuy.GetFurnitureInfo(tInfo.dwFurnitureID)
	tGoodsInfo.nBuyCount = tInfo.nNum
	DataModel.tFurniture[1].tGoodsInfo = tGoodsInfo
	tInfo.nCoin = tGoodsInfo.nCoin
	tInfo.nFinalCoin = tGoodsInfo.nFinalCoin
	local nDiscount, bInDiscount = FurnitureBuy.GetCoinBuyFurnitureDiscount(tInfo.dwFurnitureID)
	if bInDiscount then
		tInfo.nDiscount = nDiscount
		tInfo.nDiscountCoin = (tInfo.nCoin - tInfo.nFinalCoin) * tInfo.nNum
	end
	local nTotalCoin = tInfo.nFinalCoin * tInfo.nNum
	if DataModel.nSelectDisCoupon ~= -1 then
		tInfo.nTotalCoin = nTotalCoin - DataModel.nCouponSaveCoin
	else
		tInfo.nTotalCoin = nTotalCoin
	end
end

function DataModel.UpdateMultBuy()
	DataModel.tMultBuy = {}
	local tInfo = DataModel.tMultBuy
	tInfo.bMultDiscount = false
	tInfo.nTotalCoin = 0
	nTotalBeforeDiscount = 0
	for i = 1, #DataModel.tFurniture do
		local tItem = DataModel.tFurniture[i]
		local tGoodsInfo = FurnitureBuy.GetFurnitureInfo(tItem.dwFurnitureID)
		local nDiscount, bInDiscount = FurnitureBuy.GetCoinBuyFurnitureDiscount(tItem.dwFurnitureID)
		tGoodsInfo.nBuyCount = tItem.nNum
		tItem.tGoodsInfo = tGoodsInfo
		tItem.nDiscount = nDiscount
		nTotalBeforeDiscount = nTotalBeforeDiscount + tGoodsInfo.nCoin * tItem.nNum
		tInfo.nTotalCoin = tInfo.nTotalCoin + tGoodsInfo.nFinalCoin * tItem.nNum
	end
	if nTotalBeforeDiscount ~= tInfo.nTotalArch then
		tInfo.nDiscountCoin = nTotalBeforeDiscount - tInfo.nTotalCoin
	end

	for i = 2, #DataModel.tFurniture do
		local tItem2 = DataModel.tFurniture[i]
		local tItem1 = DataModel.tFurniture[i - 1]
		if tItem1.nDiscount ~= tItem2.nDiscount then
			tInfo.bMultDiscount = true
			break
		end
	end

	if DataModel.nSelectDisCoupon ~= -1 then
		tInfo.nTotalCoin = tInfo.nTotalCoin - DataModel.nCouponSaveCoin
	end
end

function DataModel.UpdateChooseCoupon()
	local dwID = DataModel.nSelectDisCoupon
	if dwID ~= -1 then
		local tBuyInfo = {}
		for i = 1, #DataModel.tFurniture do
			local tItem = DataModel.tFurniture[i]
			table.insert(tBuyInfo, tItem.tGoodsInfo)
		end
		local tDisCoupon = FurnitureBuy.GetFurnitureWelfare(dwID)
		DataModel.nCouponSaveCoin = math.ceil(FurnitureBuy.GetDisCouponPrice(tBuyInfo, tDisCoupon))
	else
		DataModel.nCouponSaveCoin = 0
	end
	DataModel.InitBuyInfo()
end

function DataModel.GetBestDisCouponID()
	local dwID = -1
	if #DataModel.tDisCouponList > 0 then
		local tBuyInfo = {}
		for i = 1, #DataModel.tFurniture do
			local tItem = DataModel.tFurniture[i]
			table.insert(tBuyInfo, tItem.tGoodsInfo)
		end
		dwID = FurnitureBuy.IntelligentSelectDisCouponEx(tBuyInfo)
	end
	return dwID
end

function DataModel.UpdateEditboxNum(nInputNum)
    if nInputNum then
        if nInputNum < 1 then
            nInputNum = 1
        elseif nInputNum > MAX_NUM then
            nInputNum = DataModel.tFurniture[1].nNum
        end
        DataModel.tFurniture[1].nNum = nInputNum
		DataModel.tFurniture[1].tGoodsInfo.nBuyCount = nInputNum
    end
end

function DataModel.GetAccountInfo()
	local tBuyInfo = {}
	for i = 1, #DataModel.tFurniture do
		local tItem = DataModel.tFurniture[i]
		table.insert(tBuyInfo, tItem.tGoodsInfo)
	end
	return tBuyInfo
end

function MoneyBuyDataModel.Init(tFurniture)
	MoneyBuyDataModel.tFurniture = tFurniture
	local pPlayer = GetClientPlayer()
	if not pPlayer then
		return
	end
	local tMoney = pPlayer.GetMoney()
	MoneyBuyDataModel.nPlayerGold = tMoney.nGold
	MoneyBuyDataModel.InitBuyInfo()
	MoneyBuyDataModel.bBought = false
end

function MoneyBuyDataModel.UnInit()
	MoneyBuyDataModel.tFurniture = nil
	MoneyBuyDataModel.nPlayerGold = nil
	MoneyBuyDataModel.tSingleBuy = nil
	MoneyBuyDataModel.tMultBuy = nil
end

function MoneyBuyDataModel.InitBuyInfo()
	if #MoneyBuyDataModel.tFurniture == 1 then
		MoneyBuyDataModel.UpdateSingleBuy()
	elseif #MoneyBuyDataModel.tFurniture > 1 then
		MoneyBuyDataModel.UpdateMultBuy()
	end
end

function MoneyBuyDataModel.UpdateSingleBuy()
	MoneyBuyDataModel.tSingleBuy = {}
	local tInfo = MoneyBuyDataModel.tSingleBuy
	tInfo.dwFurnitureID = MoneyBuyDataModel.tFurniture[1].dwFurnitureID
	tInfo.nNum = MoneyBuyDataModel.tFurniture[1].nNum

	local tItemInfo = FurnitureData.GetFurnInfoByTypeAndID(HS_FURNITURE_TYPE.FURNITURE, tInfo.dwFurnitureID)
	tInfo.szName = tItemInfo.szName
	tInfo.nQuality = tItemInfo.nQuality
	local nItemUiId = MoneyBuyDataModel.GetHLMgr().MakeFurnitureUIID(HS_FURNITURE_TYPE.FURNITURE, tInfo.dwFurnitureID)
	local tLine = FurnitureData.GetFurnAddInfo(nItemUiId)
	tInfo.nFrame = tLine.nFrame
	tInfo.szPath = tLine.szPath

	local tFurnitureConfig = MoneyBuyDataModel.GetHLMgr().GetFurnitureConfig(tInfo.dwFurnitureID)

	assert(FurnitureBuy.IsSpecialFurnitrueCanBuy(tInfo.dwFurnitureID), "购买出错")

	tInfo.nTotalGold = tFurnitureConfig.nReBuyCost * tInfo.nNum
	MoneyBuyDataModel.UpdataSpecialPayInfo(tInfo)
end

function MoneyBuyDataModel.UpdateMultBuy()
	MoneyBuyDataModel.tMultBuy = {}
	local tInfo = MoneyBuyDataModel.tMultBuy
	local nSpecialFurnitrue = 0
	local nSpecialGold = 0
	for i = 1, #MoneyBuyDataModel.tFurniture do
		local tItem = MoneyBuyDataModel.tFurniture[i]
		local tFurnitureConfig = MoneyBuyDataModel.GetHLMgr().GetFurnitureConfig(tItem.dwFurnitureID)
		if FurnitureBuy.IsSpecialFurnitrueCanBuy(tItem.dwFurnitureID) then
			nSpecialFurnitrue = nSpecialFurnitrue + 1
			nSpecialGold = nSpecialGold + tFurnitureConfig.nReBuyCost * tItem.nNum
		end
	end

	assert(nSpecialFurnitrue == #MoneyBuyDataModel.tFurniture, "购买出错")

	tInfo.nTotalGold = nSpecialGold
	MoneyBuyDataModel.UpdataSpecialPayInfo(tInfo)
end

function MoneyBuyDataModel.UpdataSpecialPayInfo(tInfo)
	local nZhuan, nGold, nSilver = FurnitureBuy.GetSpecialFurnitrueMoneyDetail(tInfo.nTotalGold)
	tInfo.tAllMoney = {nZhuan = nZhuan, nGold = nGold, nSilver = nSilver}
end

function MoneyBuyDataModel.UpdateEditboxNum(nInputNum)
    if nInputNum then
        if nInputNum < 1 then
            nInputNum = 1
        elseif nInputNum > MAX_NUM then
            nInputNum = MoneyBuyDataModel.tFurniture[1].nNum
        end
        MoneyBuyDataModel.tFurniture[1].nNum = nInputNum
    end
end

function MoneyBuyDataModel.GetSpecialAccountInfo()
	local tInfo = MoneyBuyDataModel.tSingleBuy or MoneyBuyDataModel.tMultBuy
	local tBuyInfo = {}
	for i = 1, #MoneyBuyDataModel.tFurniture do
		local tItem = MoneyBuyDataModel.tFurniture[i]
		table.insert(tBuyInfo, {tItem.dwFurnitureID, tItem.nNum})
	end
	return tInfo.nTotalGold, tBuyInfo
end

function MoneyBuyDataModel.GetHLMgr()
	local pHomelandMgr = GetHomelandMgr()
	assert(pHomelandMgr)
	return pHomelandMgr
end

function UIHomelandBuildCoinBuyConfirmView:OnEnter(bCoinBuy, tFurniture)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.bCoinBuy = bCoinBuy
    if self.bCoinBuy then
        DataModel.Init(tFurniture)
    else
        MoneyBuyDataModel.Init(tFurniture)
    end
    self:UpdateInfo()
end

function UIHomelandBuildCoinBuyConfirmView:OnExit()
    self.bInit = false
    if self.bCoinBuy then
        DataModel.UnInit()
    else
        MoneyBuyDataModel.UnInit()
    end
end

function UIHomelandBuildCoinBuyConfirmView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    -- UIHelper.BindUIEvent(self.TogTongBao, EventType.OnClick, function ()
    --     DataModel.bAllGoldBuy = false
    -- end)

    -- UIHelper.BindUIEvent(self.TogMoney, EventType.OnClick, function ()
    --     DataModel.bAllGoldBuy = true
    -- end)

    UIHelper.BindUIEvent(self.BtnPurchase, EventType.OnClick, function ()
        if self.bCoinBuy then
            self:OnClickSure()
        else
			self:OnMoneyBuyClickSure()
        end
    end)

    UIHelper.BindUIEvent(self.ButtonAdd, EventType.OnClick, function()
        if self.bCoinBuy then
            local tInfo = DataModel.tSingleBuy
            if not tInfo then
                return
            end

            local nNewCount = math.min(tInfo.nNum + 1, MAX_NUM)
            DataModel.UpdateEditboxNum(nNewCount)
            DataModel.InitBuyInfo()
            self:UpdateCostInfo()
        else
			local tInfo = MoneyBuyDataModel.tSingleBuy
            if not tInfo then
                return
            end

            local nNewCount = math.min(tInfo.nNum + 1, MONEY_BUY_MAX_NUM)
            MoneyBuyDataModel.UpdateEditboxNum(nNewCount)
            MoneyBuyDataModel.InitBuyInfo()
            self:UpdateMoneyBuyCostInfo()
        end
    end)

    UIHelper.BindUIEvent(self.ButtonDecrease, EventType.OnClick, function()
        if self.bCoinBuy then
            local tInfo = DataModel.tSingleBuy
            if not tInfo then
                return
            end

            local nNewCount = math.max(tInfo.nNum - 1, 1)
            DataModel.UpdateEditboxNum(nNewCount)
            DataModel.InitBuyInfo()
            self:UpdateCostInfo()
        else
			local tInfo = MoneyBuyDataModel.tSingleBuy
            if not tInfo then
                return
            end

            local nNewCount = math.max(tInfo.nNum - 1, 1)
            MoneyBuyDataModel.UpdateEditboxNum(nNewCount)
            MoneyBuyDataModel.InitBuyInfo()
            self:UpdateMoneyBuyCostInfo()
        end
    end)

    UIHelper.BindUIEvent(self.SliderCount, EventType.OnChangeSliderPercent, function(SliderEventType, nSliderEvent)
        if self.bCoinBuy then
            if nSliderEvent == ccui.SliderEventType.slideBallDown then
				self.bSliding = true
			elseif nSliderEvent == ccui.SliderEventType.slideBallUp then
				self.bSliding = false
				-- 强制修正滑块进度
				local nNewCount = math.max(1, math.floor(self.fSliderPerc / 100 * MAX_NUM))
				UIHelper.SetProgressBarPercent(self.ImgFg, self.fSliderPerc)
				UIHelper.SetProgressBarPercent(self.SliderCount, self.fSliderPerc)
				DataModel.UpdateEditboxNum(nNewCount)
				DataModel.InitBuyInfo()
				self:UpdateCostInfo()
			end

			if self.bSliding then
				self.fSliderPerc = UIHelper.GetProgressBarPercent(self.SliderCount)
				self.fSliderPerc = math.min(self.fSliderPerc, 100)
				self.fSliderPerc = math.max(self.fSliderPerc, 0)

				local nNewCount = math.max(1, math.floor(self.fSliderPerc / 100 * MAX_NUM))
				UIHelper.SetString(self.LabelCount, tostring(nNewCount))
				UIHelper.SetString(self.EditPaginate, tostring(nNewCount))
				UIHelper.SetProgressBarPercent(self.ImgFg, self.fSliderPerc)
				UIHelper.LayoutDoLayout(self.LayoutCount)
			end
        else
			if nSliderEvent == ccui.SliderEventType.slideBallDown then
				self.bSliding = true
			elseif nSliderEvent == ccui.SliderEventType.slideBallUp then
				self.bSliding = false
				-- 强制修正滑块进度
				local nNewCount = math.max(1, math.floor(self.fSliderPerc / 100 * MONEY_BUY_MAX_NUM))
				UIHelper.SetProgressBarPercent(self.ImgFg, self.fSliderPerc)
				UIHelper.SetProgressBarPercent(self.SliderCount, self.fSliderPerc)
				MoneyBuyDataModel.UpdateEditboxNum(nNewCount)
				MoneyBuyDataModel.InitBuyInfo()
				self:UpdateMoneyBuyCostInfo()
			end

			if self.bSliding then
				self.fSliderPerc = UIHelper.GetProgressBarPercent(self.SliderCount)
				self.fSliderPerc = math.min(self.fSliderPerc, 100)
				self.fSliderPerc = math.max(self.fSliderPerc, 0)

				local nNewCount = math.max(1, math.floor(self.fSliderPerc / 100 * MONEY_BUY_MAX_NUM))
				UIHelper.SetString(self.LabelCount, tostring(nNewCount))
				UIHelper.SetString(self.EditPaginate, tostring(nNewCount))
				UIHelper.SetProgressBarPercent(self.ImgFg, self.fSliderPerc)
				UIHelper.LayoutDoLayout(self.LayoutCount)
			end
        end
    end)

	UIHelper.SetEditboxTextHorizontalAlign(self.EditPaginate, TextHAlignment.CENTER)
	if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditPaginate, function ()
			self:OnEditBoxChanged()
		end)
    else
		UIHelper.RegisterEditBoxReturn(self.EditPaginate, function ()
			self:OnEditBoxChanged()
		end)
    end

    Event.Reg(self, EventType.OnGameNumKeyboardChanged, function (editBox, nCurNum)
        if editBox == self.EditPaginate then
            self:OnEditBoxChanged()
        end
    end)
end

function UIHomelandBuildCoinBuyConfirmView:RegEvent()
    Event.Reg(self, "COIN_SHOP_BUY_RESPOND", function ()
        if arg0 == COIN_SHOP_ERROR_CODE.SUCCESS then
            FireUIEvent("LUA_HOMELAND_BUY_FURNITURE_END")
        end
        UIMgr.Close(self)
    end)

    Event.Reg(self, "HOME_LAND_RESULT_CODE_INT", function ()
        local nRetCode = arg0
        if arg0 == HOMELAND_RESULT_CODE.BUY_FURNITURE_SUCCEED then
            local dwUserData = arg1
            JustLog("收到购买成功事件", dwUserData)
            if dwUserData ~= 0 then
                if dwUserData == nMaxBatch then
                    FireUIEvent("LUA_HOMELAND_BUY_FURNITURE_END")
                    OutputMessage("MSG_SYS", g_tStrings.STR_GROUPON_MEMBER_STATE_TIP_5 .. "\n")
                    OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_GROUPON_MEMBER_STATE_TIP_5 .. "\n")
                    UIMgr.Close(self)
                elseif dwUserData == nNowBatch then
                    DoBuyMultFurniture(dwUserData + 1)
                end
            else
                FireUIEvent("LUA_HOMELAND_BUY_FURNITURE_END")
                OutputMessage("MSG_SYS", g_tStrings.STR_GROUPON_MEMBER_STATE_TIP_5 .. "\n")
                OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_GROUPON_MEMBER_STATE_TIP_5 .. "\n")
                UIMgr.Close(self)
            end
        elseif arg0 == HOMELAND_RESULT_CODE.FURNITURE_NOT_COLLECT then
            JustLog("购买失败家具未收集", dwUserData)
            tBatchBuyInfo = {}
            nMaxBatch = 0
            nNowBatch = 0
        end
    end)
end

function UIHomelandBuildCoinBuyConfirmView:UpdateInfo()
    UIHelper.SetVisible(self.LabelNormalTips, self.bCoinBuy)
    UIHelper.SetVisible(self.TogMoney, not self.bCoinBuy)
    UIHelper.SetVisible(self.TogTongBao, self.bCoinBuy)
    UIHelper.SetVisible(self.TogBargain, self.bCoinBuy)

    if self.bCoinBuy then
        if DataModel.tSingleBuy then
            self:UpdateSingleInfo()
        elseif DataModel.tMultBuy then
            self:UpdateMultInfo()
        end
        self:UpdateCostInfo()
    else
		if MoneyBuyDataModel.tSingleBuy then
            self:UpdateMoneyBuySingleInfo()
        elseif MoneyBuyDataModel.tMultBuy then
            self:UpdateMoneyBuyMultInfo()
        end
        self:UpdateMoneyBuyCostInfo()
    end
end


function UIHomelandBuildCoinBuyConfirmView:UpdateSingleInfo()
    UIHelper.SetVisible(self.WidgetPurchaseSingle, true)
	UIHelper.SetVisible(self.WidgetPurchaseMult, false)

    local tInfo = DataModel.tSingleBuy

    local szPath = string.gsub(tInfo.szPath, "ui/Image/", "Resource/")
    szPath = string.gsub(szPath, ".tga", ".png")
    UIHelper.SetTexture(self.ImgItemIcon, szPath)

    UIHelper.SetString(self.LabelItemName, UIHelper.GBKToUTF8(tInfo.szName))
    local r, g, b = GetItemFontColorByQuality(tInfo.nQuality, false)
    UIHelper.SetTextColor(self.LabelItemName, cc.c4b(r, g, b, 255))
end

function UIHomelandBuildCoinBuyConfirmView:UpdateMultInfo()
	UIHelper.SetVisible(self.WidgetPurchaseSingle, false)
	UIHelper.SetVisible(self.WidgetPurchaseMult, true)
end

function UIHomelandBuildCoinBuyConfirmView:UpdateCostInfo()
	local tInfo = DataModel.tSingleBuy or DataModel.tMultBuy
	local player = GetClientPlayer()
	if DataModel.tSingleBuy then
		UIHelper.SetString(self.LabelCount, tostring(tInfo.nNum))
		UIHelper.SetString(self.EditPaginate, tostring(tInfo.nNum))
    	UIHelper.LayoutDoLayout(self.LayoutCount)

		UIHelper.SetProgressBarPercent(self.ImgFg, 100 * tInfo.nNum / MAX_NUM)
		UIHelper.SetProgressBarPercent(self.SliderCount, 100 * tInfo.nNum / MAX_NUM)
	end

    UIHelper.SetString(self.LabelNumTongBao, tostring(tInfo.nTotalCoin))
    UIHelper.LayoutDoLayout(self.LayoutTongBao)

	if player.nCoin < tInfo.nTotalCoin then
		UIHelper.SetTextColor(self.LabelNumTongBao, colorRed)
	else
		UIHelper.SetTextColor(self.LabelNumTongBao, colorWhite)
	end

    local nDiscountCoin = tInfo.nDiscountCoin or 0
	local nCouponSaveCoin = DataModel.nCouponSaveCoin or 0
	if nDiscountCoin + nCouponSaveCoin > 0 then
        UIHelper.SetVisible(self.LayoutSavedTongBao, true)
        UIHelper.SetString(self.LabelNumSavedTongBao,  nDiscountCoin + nCouponSaveCoin)
        UIHelper.LayoutDoLayout(self.LayoutSavedTongBao)
    else
        UIHelper.SetVisible(self.LayoutSavedTongBao, false)
    end
    UIHelper.LayoutDoLayout(self.LayoutLeft)

    local bShowDiscount = false
    local szDiscount = ""
    if DataModel.nSelectDisCoupon ~= -1 then
		local tInfo = nil
		tInfo = FurnitureBuy.GetFurnitureWelfare(DataModel.nSelectDisCoupon)
		if tInfo and tInfo.nType == COIN_SHOP_DISCOUNT_TYPE.DISCOUNT then
            szDiscount = string.format("%d折", FurnitureBuy.GetDiscountNum(tInfo.nDiscount))
			bShowDiscount = true
		end
		if tInfo and tInfo.nType == COIN_SHOP_DISCOUNT_TYPE.FULL_CUT then
            szDiscount = string.format("满%d减%d券", tInfo.nFull, tInfo.nCut)
			bShowDiscount = true
		end
	end
    UIHelper.SetVisible(self.WidgetDiscountTongBao, bShowDisCount)
    UIHelper.SetString(self.LabelDiscountTongBao,  szDiscount)
end

function UIHomelandBuildCoinBuyConfirmView:SelectDisCoupon(dwID)
    DataModel.nSelectDisCoupon = dwID
	DataModel.UpdateChooseCoupon()
	self:UpdateInfo()
end

function UIHomelandBuildCoinBuyConfirmView:OnClickSure()
    local function fnChooseNewDisCoupon()
        local dwID = DataModel.GetBestDisCouponID()
        if dwID ~= -1 then
            local tDisCoupon = FurnitureBuy.GetFurnitureWelfare(dwID)
            self:SelectDisCoupon(dwID)
        else
            DataModel.nSelectDisCoupon = -1
        end
    end

	if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.COIN, "COIN") then
		return
	end
	local tBuy = DataModel.GetAccountInfo()
	if #tBuy > MAX_BUY_ITEM_NUM then
		OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_BUY_FURNITURE_COIN_ERROR)
		return
	end
	if DataModel.nSelectDisCoupon ~= -1 then
		FurnitureBuy.CoinBuy(tBuy, DataModel.nSelectDisCoupon, nil, fnChooseNewDisCoupon, nil)
	else
		FurnitureBuy.CoinBuy(tBuy, nil, nil, fnChooseNewDisCoupon, nil)
	end
end

function UIHomelandBuildCoinBuyConfirmView:UpdateMoneyBuySingleInfo()
    UIHelper.SetVisible(self.WidgetPurchaseSingle, true)
	UIHelper.SetVisible(self.WidgetPurchaseMult, false)

    local tInfo = MoneyBuyDataModel.tSingleBuy

    local szPath = string.gsub(tInfo.szPath, "ui/Image/", "Resource/")
    szPath = string.gsub(szPath, ".tga", ".png")
    UIHelper.SetTexture(self.ImgItemIcon, szPath)

    UIHelper.SetString(self.LabelItemName, UIHelper.GBKToUTF8(tInfo.szName))
    local r, g, b = GetItemFontColorByQuality(tInfo.nQuality, false)
    UIHelper.SetTextColor(self.LabelItemName, cc.c4b(r, g, b, 255))
end

function UIHomelandBuildCoinBuyConfirmView:UpdateMoneyBuyMultInfo()
	UIHelper.SetVisible(self.WidgetPurchaseSingle, true)
	UIHelper.SetVisible(self.WidgetPurchaseMult, false)
end

function UIHomelandBuildCoinBuyConfirmView:UpdateMoneyBuyCostInfo()
	local tInfo = MoneyBuyDataModel.tSingleBuy or MoneyBuyDataModel.tMultBuy
	local player = GetClientPlayer()
	if MoneyBuyDataModel.tSingleBuy then
		UIHelper.SetString(self.LabelCount, tostring(tInfo.nNum))
		UIHelper.SetString(self.EditPaginate, tostring(tInfo.nNum))

    	UIHelper.LayoutDoLayout(self.LayoutCount)

		UIHelper.SetProgressBarPercent(self.ImgFg, 100 * tInfo.nNum / MAX_NUM)
		UIHelper.SetProgressBarPercent(self.SliderCount, 100 * tInfo.nNum / MAX_NUM)
	end

	UIHelper.SetString(self.tbLabelMoney[1], tostring(tInfo.tAllMoney.nZhuan))
	UIHelper.SetString(self.tbLabelMoney[2], tostring(tInfo.tAllMoney.nGold))
	UIHelper.SetString(self.tbLabelMoney[3], tostring(tInfo.tAllMoney.nSilver))

	local tMoney = player.GetMoney()
	if tMoney.nGold < tInfo.nTotalGold then
		UIHelper.SetTextColor(self.tbLabelMoney[1], colorRed)
		UIHelper.SetTextColor(self.tbLabelMoney[2], colorRed)
		UIHelper.SetTextColor(self.tbLabelMoney[3], colorRed)
	else
		UIHelper.SetTextColor(self.tbLabelMoney[1], colorWhite)
		UIHelper.SetTextColor(self.tbLabelMoney[2], colorWhite)
		UIHelper.SetTextColor(self.tbLabelMoney[3], colorWhite)
	end

    UIHelper.LayoutDoLayout(self.LayoutMoney)
    UIHelper.LayoutDoLayout(self.LayoutMoneyLeft)
end

function UIHomelandBuildCoinBuyConfirmView:OnMoneyBuyClickSure()
	if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.SHOP) then
		return
	end
	if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.BANK) then
		return
	end
	local tInfo = MoneyBuyDataModel.tSingleBuy or MoneyBuyDataModel.tMultBuy
	if tInfo.nTotalGold > MoneyBuyDataModel.nPlayerGold then
		OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_BUY_FURNITURE_GOLD2ARCH_NOT_ENOUGH)
	else
		local szMoney = UIHelper.GetMoneyTipText(tInfo.nTotalGold * 10000, false)
		if MoneyBuyDataModel.tSingleBuy then
			local nR, nG, nB = GetItemFontColorByQuality(MoneyBuyDataModel.tSingleBuy.nQuality)
			local szItemName = GetFormatText("[" .. UIHelper.GBKToUTF8(MoneyBuyDataModel.tSingleBuy.szName) .. "]", nil, nR, nG, nB)
			UIHelper.ShowConfirm(string.format("你确定花费%s购买%d个%s吗？", szMoney, MoneyBuyDataModel.tSingleBuy.nNum, szItemName), function ()
				self:OpenGoldBuySure()
			end, nil, true)
		elseif MoneyBuyDataModel.tMultBuy then
			UIHelper.ShowConfirm(string.format("你确定花费%s购买所有选择的物件吗？", szMoney), function ()
				self:OpenGoldBuySure()
			end, nil, true)
		end
	end
end

local function CheckPrice()
	local pHomelandMgr = GetHomelandMgr()
	if not pHomelandMgr then
		return false
	end
	local nGold, tBuyInfo = MoneyBuyDataModel.GetSpecialAccountInfo()
	local nNewTotalGold = 0
	for i = 1, #tBuyInfo do
		local tConfig = pHomelandMgr.GetFurnitureConfig(tBuyInfo[i][1])
		nNewTotalGold = nNewTotalGold + tConfig.nGold * tBuyInfo[i][2]
	end
	local nTotalGold = #tBuyInfo == 1 and MoneyBuyDataModel.tSingleBuy.nTotalGold or MoneyBuyDataModel.tMultBuy.nTotalGold
	return nNewTotalGold == nTotalGold
end

local function DoBuyMultFurniture(nBatch)
	nNowBatch = nBatch
	JustLog("调用接口参数", nNowBatch, 0, tBatchBuyInfo[nNowBatch - MONEY_BUY_START_BATCH])
	MoneyBuyDataModel.GetHLMgr().BuyFurniture(nNowBatch, 0, tBatchBuyInfo[nNowBatch - MONEY_BUY_START_BATCH])
end

local function DoBuyFurniture()
	if MoneyBuyDataModel.bBought then
		return
	end
	local nGold, tBuyInfo = MoneyBuyDataModel.GetSpecialAccountInfo()
	if not CheckPrice() then
        local script = UIHelper.ShowConfirm(g_tStrings.STR_BUY_FURNITURE_DISCOUNT_UPDATE, nil, function ()
			UIMgr.Close(self)
		end)
        script:HideButton("Confirm")
        script:SetButtonContent("Cancel", g_tStrings.STR_HOTKEY_SURE)
	end
	OutputMessage("MSG_SYS", g_tStrings.STR_BUY_FURNITURE_WAIT .. "\n")
	OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_BUY_FURNITURE_WAIT .. "\n")
	-- JustLog("开始家具购买， 数量：" .. #tBuyInfo .. " 花费金币：" .. nGold)
	MoneyBuyDataModel.bBought = true
	if #tBuyInfo > MONEY_BUY_MAX_BUY_ITEM_NUM then
		tBatchBuyInfo = {}
		nMaxBatch = MONEY_BUY_START_BATCH
		nNowBatch = MONEY_BUY_START_BATCH
		for i = 1, #tBuyInfo do
			local nIndex = math.ceil(i / MONEY_BUY_MAX_BUY_ITEM_NUM)
			if not tBatchBuyInfo[nIndex] then
				tBatchBuyInfo[nIndex] = {}
			end
			table.insert(tBatchBuyInfo[nIndex], tBuyInfo[i])
		end
		nMaxBatch = #tBatchBuyInfo + MONEY_BUY_START_BATCH
		-- JustLog("开始批量购买", nMaxBatch)
		DoBuyMultFurniture(MONEY_BUY_START_BATCH + 1)
	else
		-- JustLog("调用接口参数", 0, 0, tBuyInfo)
		MoneyBuyDataModel.GetHLMgr().BuyFurniture(0, 0, tBuyInfo)
	end
end

function UIHomelandBuildCoinBuyConfirmView:OpenGoldBuySure()
    local tInfo = MoneyBuyDataModel.tSingleBuy or MoneyBuyDataModel.tMultBuy
	if tInfo.nTotalGold > MONEY_BUY_MAX_GOLD then
        local scriptView = UIHelper.ShowConfirm("注意：当前涉及大额交易，请谨慎！", DoBuyFurniture, nil, false)
        scriptView:SetButtonCountDown(MONEY_BUY_CONFIRM_TIME)
	else
		DoBuyFurniture()
	end
end

function UIHomelandBuildCoinBuyConfirmView:OnEditBoxChanged()
	local nNewCount = tonumber(UIHelper.GetText(self.EditPaginate)) or 1
	if self.bCoinBuy then
		local tInfo = DataModel.tSingleBuy
		if not tInfo then
			return
		end

		nNewCount = math.min(nNewCount, MAX_NUM)
		nNewCount = math.max(nNewCount, 1)

		DataModel.UpdateEditboxNum(nNewCount)
		DataModel.InitBuyInfo()
		self:UpdateCostInfo()
	else
		local tInfo = MoneyBuyDataModel.tSingleBuy
		if not tInfo then
			return
		end

		nNewCount = math.min(nNewCount, MAX_NUM)
		nNewCount = math.max(nNewCount, 1)

		MoneyBuyDataModel.UpdateEditboxNum(nNewCount)
		MoneyBuyDataModel.InitBuyInfo()
		self:UpdateMoneyBuyCostInfo()
	end
end

return UIHomelandBuildCoinBuyConfirmView