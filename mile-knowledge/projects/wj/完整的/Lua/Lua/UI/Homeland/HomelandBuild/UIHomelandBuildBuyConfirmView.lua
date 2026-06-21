-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildBuyConfirmView
-- Date: 2023-04-26 11:13:48
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildBuyConfirmView = class("UIHomelandBuildBuyConfirmView")

local MAX_SILVER = 1000000
local MAX_NUM = 9999
local MAX_BUY_ITEM_NUM = 100
local CONFIRM_TIME = 3
local colorRed = cc.c3b(255, 133, 125)
local colorWhite = cc.c3b(255, 255, 255)

local function GetFurnitureArch(tFurnitureConfig)
	if tFurnitureConfig.nArchitecture > 0 then
		return tFurnitureConfig.nArchitecture
	elseif tFurnitureConfig.nReBuyCost > 0 then
		return tFurnitureConfig.nReBuyCost
	end
end
---------------------- DataModel ---------------------------
local nMaxBatch = 0
local nNowBatch = 0
local tBatchBuyInfo = {}
local nConfirmTime = 0
local DataModel = {}
local View = nil

local function GetHLMgr()
	local pHomelandMgr = GetHomelandMgr()
	assert(pHomelandMgr)
	return pHomelandMgr
end

local function CheckPrice()
	local pHomelandMgr = GetHomelandMgr()
	if not pHomelandMgr then
		return false
	end
	local nDiscount, bInDiscount = FurnitureBuy.GetGold2ArchDiscount()
	if DataModel.nExDiscount and DataModel.nExDiscount ~= nDiscount then
		return false
	end
	if (not DataModel.nExDiscount) and bInDiscount then
		return false
	end
	local nArch, tBuyInfo = DataModel.GetAccountInfo()
	local nNewTotalArch = 0
	for i = 1, #tBuyInfo do
		local tConfig = pHomelandMgr.GetFurnitureConfig(tBuyInfo[i][1])
		nNewTotalArch = nNewTotalArch + tConfig.nFinalArchitecture * tBuyInfo[i][2]
	end
	local nTotalArch = #tBuyInfo == 1 and DataModel.tSingleBuy.nTotalArch or DataModel.tMultBuy.nTotalArch
	return nNewTotalArch == nTotalArch
end

local function DoBuyMultFurniture(nBatch)
	nNowBatch = nBatch
	if DataModel.bAllGoldBuy then
		JustLog("调用接口参数", nNowBatch, 0, tBatchBuyInfo[nNowBatch])
		GetHLMgr().BuyFurniture(nNowBatch, 0, tBatchBuyInfo[nNowBatch])
	else
		local pPlayer = GetClientPlayer()
		if not pPlayer then
			return
		end
		DataModel.nPlayerArch = pPlayer.nArchitecture
		JustLog("调用接口参数", nNowBatch, DataModel.nPlayerArch, tBatchBuyInfo[nNowBatch])
		GetHLMgr().BuyFurniture(nNowBatch, DataModel.nPlayerArch, tBatchBuyInfo[nNowBatch])
	end
end

local function DoBuyFurniture()
	if DataModel.bBought then
		return
	end
	local nArch, tBuyInfo = DataModel.GetAccountInfo()
	if not CheckPrice() then
        local script = UIHelper.ShowConfirm(g_tStrings.STR_BUY_FURNITURE_DISCOUNT_UPDATE)
        script:HideButton("Confirm")
        script:SetButtonContent("Cancel", g_tStrings.STR_HOTKEY_SURE)
	end
	OutputMessage("MSG_SYS", g_tStrings.STR_BUY_FURNITURE_WAIT .. "\n")
	OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_BUY_FURNITURE_WAIT .. "\n")
	JustLog("开始家具购买， 数量：" .. #tBuyInfo .. " 玩家园宅币：" .. nArch .. " 玩家选择Gold：", DataModel.bAllGoldBuy)
	Event.Dispatch(EventType.OnStartBuyFurniture)
	DataModel.bBought = true
	if #tBuyInfo > MAX_BUY_ITEM_NUM then
		tBatchBuyInfo = {}
		nMaxBatch = 0
		nNowBatch = 0
		for i = 1, #tBuyInfo do
			local nIndex = math.ceil(i / MAX_BUY_ITEM_NUM)
			if not tBatchBuyInfo[nIndex] then
				tBatchBuyInfo[nIndex] = {}
			end
			table.insert(tBatchBuyInfo[nIndex], tBuyInfo[i])
		end
		nMaxBatch = #tBatchBuyInfo
		JustLog("开始批量购买", nMaxBatch)
		DoBuyMultFurniture(1)
	else
		JustLog("调用接口参数", 0, nArch, tBuyInfo)
		GetHLMgr().BuyFurniture(0, nArch, tBuyInfo)
	end
end

local function OnClickSure()
	if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.BANK) then
		return
	end
	local tInfo = DataModel.tSingleBuy or DataModel.tMultBuy
	if DataModel.bAllGoldBuy then
		if tInfo.tAllMoney.nTotalSilver > DataModel.nPlayerSilver then
			OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_BUY_FURNITURE_GOLD2ARCH_NOT_ENOUGH)
		else
			local szMoney = UIHelper.GetMoneyTipText(tInfo.tAllMoney.nTotalSilver * 100, false)
			if DataModel.tSingleBuy then
				local nR, nG, nB = GetItemFontColorByQuality(DataModel.tSingleBuy.nQuality)
				local szItemName = GetFormatText("[" .. UIHelper.GBKToUTF8(DataModel.tSingleBuy.szName) .. "]", nil, nR, nG, nB)
				UIHelper.ShowConfirm(string.format("你确定花费%s购买%d个%s吗？", szMoney, DataModel.tSingleBuy.nNum, szItemName), function ()
					View:OpenGoldBuySure()
				end, nil, true)
			elseif DataModel.tMultBuy then
				UIHelper.ShowConfirm(string.format("你确定花费%s购买所有选择的物件吗？", szMoney), function ()
					View:OpenGoldBuySure()
				end, nil, true)
			end
		end
	else
		if tInfo.tDiffMoney and tInfo.tDiffMoney.nTotalSilver > DataModel.nPlayerSilver then
			OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_BUY_FURNITURE_GOLD2ARCH_NOT_ENOUGH)
		elseif tInfo.tDiffMoney then
			local szMoney = UIHelper.GetMoneyTipText(tInfo.tDiffMoney.nTotalSilver * 100, false)
			if DataModel.tSingleBuy then
				local nR, nG, nB = GetItemFontColorByQuality(DataModel.tSingleBuy.nQuality)
				local szItemName = GetFormatText("[" .. UIHelper.GBKToUTF8(DataModel.tSingleBuy.szName) .. "]", nil, nR, nG, nB)
				UIHelper.ShowConfirm(string.format("你确定花费%s补足园宅币以购买%d个%s吗？", szMoney, DataModel.tSingleBuy.nNum, szItemName), function ()
					View:OpenGoldBuySure()
				end, nil, true)
			elseif DataModel.tMultBuy then
				UIHelper.ShowConfirm(string.format("你确定花费%s补足园宅币以购买所有选择的物件吗？", szMoney), function ()
					View:OpenGoldBuySure()
				end, nil, true)
			end
		else
			DoBuyFurniture()
		end
	end
end

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
	local tMoney = pPlayer.GetMoney()
	DataModel.nPlayerSilver = tMoney.nGold * 100 + tMoney.nSilver
	DataModel.nPlayerArch = pPlayer.nArchitecture
	DataModel.bAllGoldBuy = false
	DataModel.InitBuyInfo()
	DataModel.bBought = false
end

function DataModel.UnInit()
	DataModel.tFurniture = nil
	DataModel.nPlayerSilver = nil
	DataModel.tSingleBuy = nil
	DataModel.tMultBuy = nil
	DataModel.nExDiscount = nil
end

function DataModel.InitBuyInfo()
	local nDiscount, bInDiscount = FurnitureBuy.GetGold2ArchDiscount()
	if bInDiscount then
		DataModel.nExDiscount = nDiscount
	end
	if #DataModel.tFurniture == 1 then
		DataModel.UpdateSingleBuy()
	elseif #DataModel.tFurniture > 1 then
		DataModel.UpdateMultBuy()
	end
end

function DataModel.UpdateSingleBuy()
	DataModel.tSingleBuy = {}
	local tInfo = DataModel.tSingleBuy
	tInfo.dwFurnitureID = DataModel.tFurniture[1].dwFurnitureID
	tInfo.nNum = DataModel.tFurniture[1].nNum

	local tItemInfo = FurnitureData.GetFurnInfoByTypeAndID(HS_FURNITURE_TYPE.FURNITURE, tInfo.dwFurnitureID)
	tInfo.szName = tItemInfo.szName
	tInfo.nQuality = tItemInfo.nQuality
	local nItemUiId = GetHLMgr().MakeFurnitureUIID(HS_FURNITURE_TYPE.FURNITURE, tInfo.dwFurnitureID)
	local tLine = Table_GetFurnitureAddInfo(nItemUiId)
	tInfo.nFrame = tLine.nFrame
	tInfo.szPath = tLine.szPath

	local tFurnitureConfig = GetHLMgr().GetFurnitureConfig(tInfo.dwFurnitureID)
	tInfo.nArchitecture = GetFurnitureArch(tFurnitureConfig)
	tInfo.nFinalArchitecture = tFurnitureConfig.nFinalArchitecture or 0
	local nDiscount, bInDiscount = FurnitureBuy.GetArchBuyFurnitureDiscount(tInfo.dwFurnitureID)
	if bInDiscount then
		tInfo.nDiscount = nDiscount
		tInfo.nDiscountArch = (tInfo.nArchitecture - tInfo.nFinalArchitecture) * tInfo.nNum
	end
	local nTotalArch = tInfo.nFinalArchitecture * tInfo.nNum
	tInfo.nTotalArch = nTotalArch
	DataModel.UpdatePayInfo(tInfo)
end

function DataModel.UpdateMultBuy()
	DataModel.tMultBuy = {}
	local tInfo = DataModel.tMultBuy
	tInfo.bMultDiscount = false
	tInfo.nTotalArch = 0
	nTotalBeforeDiscount = 0
	for i = 1, #DataModel.tFurniture do
		local tItem = DataModel.tFurniture[i]
		local nDiscount, bInDiscount = FurnitureBuy.GetArchBuyFurnitureDiscount(tItem.dwFurnitureID)
		local tFurnitureConfig = GetHLMgr().GetFurnitureConfig(tItem.dwFurnitureID)
		tItem.nDiscount = nDiscount
		local nArch = GetFurnitureArch(tFurnitureConfig)
		nTotalBeforeDiscount = nTotalBeforeDiscount + nArch * tItem.nNum
		tInfo.nTotalArch = tInfo.nTotalArch + tFurnitureConfig.nFinalArchitecture * tItem.nNum
	end
	if nTotalBeforeDiscount ~= tInfo.nTotalArch then
		tInfo.nDiscountArch = nTotalBeforeDiscount - tInfo.nTotalArch
	end

	for i = 2, #DataModel.tFurniture do
		local tItem2 = DataModel.tFurniture[i]
		local tItem1 = DataModel.tFurniture[i - 1]
		if tItem1.nDiscount ~= tItem2.nDiscount then
			tInfo.bMultDiscount = true
			break
		end
	end

	DataModel.UpdatePayInfo(tInfo)
end

function DataModel.UpdatePayInfo(tInfo)
	local nTotalArch = tInfo.nTotalArch
	local nZhuan, nGold, nSilver = FurnitureBuy.ArchExMoneyDetail(nTotalArch)
	tInfo.tAllMoney = {nZhuan = nZhuan, nGold = nGold, nSilver = nSilver}
	tInfo.tAllMoney.nTotalSilver = FurnitureBuy.ArchExSilver(nTotalArch)

	local nTotalSilver = 0 --总共省的钱
	if tInfo.nDiscount then
		nTotalSilver = FurnitureBuy.ArchExSilver(tInfo.nDiscountArch)
	end
	if DataModel.nExDiscount then
		nTotalSilver = nTotalSilver + FurnitureBuy.DiscountSilver(nTotalArch)
	end
	if nTotalSilver > 0 then
		nZhuan, nGold, nSilver = FurnitureBuy.GetMoneyDetail(nTotalSilver)
		tInfo.tDiscountMoney = {nZhuan = nZhuan, nGold = nGold, nSilver = nSilver}
	end

	if DataModel.nPlayerArch < nTotalArch then
		local nDiffArch = nTotalArch - DataModel.nPlayerArch
		nTotalSilver = FurnitureBuy.ArchExSilver(nDiffArch)
		nZhuan, nGold, nSilver = FurnitureBuy.ArchExMoneyDetail(nDiffArch)
		tInfo.tDiffMoney = {nZhuan = nZhuan, nGold = nGold, nSilver = nSilver}
		tInfo.tDiffMoney.nTotalSilver = nTotalSilver
		local nSilver = FurnitureBuy.DiscountSilver(nDiffArch)
		if nSilver > 0 then
			nZhuan, nGold, nSilver = FurnitureBuy.GetMoneyDetail(nSilver)
			tInfo.tDiffDiscountMoney = {nZhuan = nZhuan, nGold = nGold, nSilver = nSilver}
		end
	end
end

function DataModel.UpdateEditboxNum(nInputNum)
    if nInputNum then
        if nInputNum < 1 then
            nInputNum = 1
        elseif nInputNum > MAX_NUM then
            nInputNum = DataModel.tFurniture[1].nNum
        end
        DataModel.tFurniture[1].nNum = nInputNum
    end
end

function DataModel.GetAccountInfo()
	local tInfo = DataModel.tSingleBuy or DataModel.tMultBuy
	local tBuyInfo = {}
	for i = 1, #DataModel.tFurniture do
		local tItem = DataModel.tFurniture[i]
		table.insert(tBuyInfo, {tItem.dwFurnitureID, tItem.nNum})
	end
	local nArch = 0
	if not DataModel.bAllGoldBuy then
		nArch = DataModel.nPlayerArch
	end
	--UILog("nArch, tBuyInfo", nArch, tBuyInfo)
	return nArch, tBuyInfo
end

function UIHomelandBuildBuyConfirmView:OnEnter(tFurniture)
    View = self

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    DataModel.Init(tFurniture)
    self:UpdateInfo()
end

function UIHomelandBuildBuyConfirmView:OnExit()
    self.bInit = false
    DataModel.UnInit()
end

function UIHomelandBuildBuyConfirmView:BindUIEvent()
	UIHelper.SetEditboxTextHorizontalAlign(self.EditPaginate, TextHAlignment.CENTER)

	if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditPaginate, function ()
			local nNewCount = tonumber(UIHelper.GetText(self.EditPaginate)) or 1
			nNewCount = math.min(nNewCount, MAX_NUM)
			self.fSliderPerc = nNewCount * 100 / MAX_NUM
			UIHelper.SetProgressBarPercent(self.SliderCount, self.fSliderPerc)
			DataModel.UpdateEditboxNum(nNewCount)
			DataModel.InitBuyInfo()
			self:UpdateCostInfo()
		end)
    else
		UIHelper.RegisterEditBoxReturn(self.EditPaginate, function ()
			local nNewCount = tonumber(UIHelper.GetText(self.EditPaginate)) or 1
			nNewCount = math.min(nNewCount, MAX_NUM)
			self.fSliderPerc = nNewCount * 100 / MAX_NUM
			UIHelper.SetProgressBarPercent(self.SliderCount, self.fSliderPerc)
			DataModel.UpdateEditboxNum(nNewCount)
			DataModel.InitBuyInfo()
			self:UpdateCostInfo()
		end)
    end

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.TogYuanZhaiBi, EventType.OnClick, function ()
        DataModel.bAllGoldBuy = false
    end)

    UIHelper.BindUIEvent(self.TogGold, EventType.OnClick, function ()
        DataModel.bAllGoldBuy = true
    end)

    UIHelper.BindUIEvent(self.BtnPurchase, EventType.OnClick, function ()
        OnClickSure()
    end)

    UIHelper.BindUIEvent(self.ButtonAdd, EventType.OnClick, function()
        local tInfo = DataModel.tSingleBuy
        if not tInfo then
            return
        end

        local nNewCount = math.min(tInfo.nNum + 1, MAX_NUM)
        DataModel.UpdateEditboxNum(nNewCount)
        DataModel.InitBuyInfo()
        self:UpdateCostInfo()
    end)

    UIHelper.BindUIEvent(self.ButtonDecrease, EventType.OnClick, function()
        local tInfo = DataModel.tSingleBuy
        if not tInfo then
            return
        end

        local nNewCount = math.max(tInfo.nNum - 1, 1)
        DataModel.UpdateEditboxNum(nNewCount)
        DataModel.InitBuyInfo()
        self:UpdateCostInfo()
    end)

    UIHelper.BindUIEvent(self.SliderCount, EventType.OnChangeSliderPercent, function(SliderEventType, nSliderEvent)
        if nSliderEvent == ccui.SliderEventType.slideBallDown then
            self.bSliding = true
        elseif nSliderEvent == ccui.SliderEventType.slideBallUp then
            self.bSliding = false
            -- 强制修正滑块进度
            local nNewCount = math.max(1, math.floor(self.fSliderPerc / 100 * MAX_NUM))
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
            UIHelper.SetString(self.EditPaginate, tostring(nNewCount))
            UIHelper.LayoutDoLayout(self.LayoutCount)
        end
    end)

	Event.Reg(self, EventType.OnGameNumKeyboardChanged, function (editBox, nCurNum)
        if editBox == self.EditPaginate then
            local nNewCount = tonumber(UIHelper.GetText(self.EditPaginate)) or 1
			nNewCount = math.min(nNewCount, MAX_NUM)
			self.fSliderPerc = nNewCount * 100 / MAX_NUM
			UIHelper.SetProgressBarPercent(self.SliderCount, self.fSliderPerc)
			DataModel.UpdateEditboxNum(nNewCount)
			DataModel.InitBuyInfo()
			self:UpdateCostInfo()
        end
    end)
end

function UIHomelandBuildBuyConfirmView:RegEvent()
	Event.Reg(HomelandBuildData, "HOME_LAND_RESULT_CODE", function()
		local nRetCode = arg0
		if nRetCode == HOMELAND_RESULT_CODE.AMOUNT_SPILLED then
			DataModel.bBought = false
		end
    end)

    Event.Reg(self, "HOME_LAND_RESULT_CODE_INT", function (nRetCode)
        if nRetCode == HOMELAND_RESULT_CODE.BUY_FURNITURE_SUCCEED then
            local dwUserData = arg1
            JustLog("收到购买成功事件", dwUserData)
            if dwUserData ~= 0 then
                if dwUserData == nMaxBatch then
                    FireUIEvent("LUA_HOMELAND_BUY_FURNITURE_END")
                    OutputMessage("MSG_SYS", g_tStrings.STR_GROUPON_MEMBER_STATE_TIP_5 .. "\n")
                    OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_GROUPON_MEMBER_STATE_TIP_5 .. "\n")
                    UIMgr.Close(self)
                elseif dwUserData == nNowBatch then
                    DoBuyMultFurniture(dwUserData + 1)
                end
            else
                FireUIEvent("LUA_HOMELAND_BUY_FURNITURE_END")
                OutputMessage("MSG_SYS", g_tStrings.STR_GROUPON_MEMBER_STATE_TIP_5 .. "\n")
                OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_GROUPON_MEMBER_STATE_TIP_5 .. "\n")
                UIMgr.Close(self)
            end
        end
    end)
end

function UIHomelandBuildBuyConfirmView:UpdateInfo()
	local nArch = CurrencyData.GetCurCurrencyCount(CurrencyType.Architecture)

	UIHelper.AddPrefab(PREFAB_ID.WidgetCurrency, self.LayoutAllCurrency)
	local scriptCurrency = scriptCurrency or UIHelper.AddPrefab(PREFAB_ID.WidgetOtherCurrency, self.LayoutAllCurrency)
    scriptCurrency:SetLableCount(nArch)
    scriptCurrency:SetCurrencyType(CurrencyType.Architecture)

    if DataModel.tSingleBuy then
		self:UpdateSingleBaseInfo()
		self:UpdateCostInfo()
	elseif DataModel.tMultBuy then
		self:UpdateMult()
		self:UpdateCostInfo()
	end
end

function UIHomelandBuildBuyConfirmView:UpdateSingleBaseInfo()
	local tInfo = DataModel.tSingleBuy

    local szPath = string.gsub(tInfo.szPath, "ui/Image/", "Resource/")
    szPath = string.gsub(szPath, ".tga", ".png")
    UIHelper.SetTexture(self.ImgItemIcon, szPath)

    UIHelper.SetString(self.LabelItemName, UIHelper.GBKToUTF8(tInfo.szName))
    local r, g, b = GetItemFontColorByQuality(tInfo.nQuality, false)
    UIHelper.SetTextColor(self.LabelItemName, cc.c4b(r, g, b, 255))

	UIHelper.SetVisible(self.WidgetPurchaseSingle, true)
	UIHelper.SetVisible(self.WidgetPurchaseMult, false)
end

function UIHomelandBuildBuyConfirmView:UpdateMult()
	UIHelper.SetVisible(self.WidgetPurchaseSingle, false)
	UIHelper.SetVisible(self.WidgetPurchaseMult, true)
end

function UIHomelandBuildBuyConfirmView:UpdateCostInfo()
	local tInfo = DataModel.tSingleBuy or DataModel.tMultBuy
	local player = GetClientPlayer()
	if DataModel.tSingleBuy then
		UIHelper.SetString(self.EditPaginate, tostring(tInfo.nNum))
    	UIHelper.LayoutDoLayout(self.LayoutCount)

		UIHelper.SetProgressBarPercent(self.SliderCount, 100 * tInfo.nNum / MAX_NUM)
	end

    UIHelper.SetVisible(self.LayoutMakeUpGold, tInfo.tDiffMoney ~= nil)
    UIHelper.SetVisible(self.LayoutMakeUpGoldSelect, tInfo.tDiffMoney ~= nil)
    if tInfo.tDiffMoney then
        self:UpdateMoney(self.tbLabelRepairMoney, self.tbLayoutRepairMoney, tInfo.tDiffMoney.nZhuan, tInfo.tDiffMoney.nGold, tInfo.tDiffMoney.nSilver)
        self:UpdateMoney(self.tbLabelRepairMoney_S, self.tbLayoutRepairMoney_S, tInfo.tDiffMoney.nZhuan, tInfo.tDiffMoney.nGold, tInfo.tDiffMoney.nSilver)
        UIHelper.LayoutDoLayout(self.LayoutMakeUpGold)
        UIHelper.LayoutDoLayout(self.LayoutMakeUpGoldSelect)
    end

    self:UpdateMoney(self.tbLabelAllMoney, self.tbLayoutAllMoney, tInfo.tAllMoney.nZhuan, tInfo.tAllMoney.nGold, tInfo.tAllMoney.nSilver)
    self:UpdateMoney(self.tbLabelAllMoney_S, self.tbLayoutAllMoney_S, tInfo.tAllMoney.nZhuan, tInfo.tAllMoney.nGold, tInfo.tAllMoney.nSilver)
    UIHelper.LayoutDoLayout(self.LayoutCurrency)
    UIHelper.LayoutDoLayout(self.LayoutCurrencySelect)

    UIHelper.SetString(self.LabelNumYuanZhaiBi, tostring(tInfo.nTotalArch))
    UIHelper.SetString(self.LabelNumYuanZhaiBi_S, tostring(tInfo.nTotalArch))
    UIHelper.LayoutDoLayout(self.LayoutYuanZhaiBi)
    UIHelper.LayoutDoLayout(self.LayoutYuanZhaiBiSelect)

	if player.nArchitecture < tInfo.nTotalArch then
		UIHelper.SetTextColor(self.LabelNumYuanZhaiBi, colorRed)
		UIHelper.SetTextColor(self.LabelNumYuanZhaiBi_S, colorRed)
	else
		UIHelper.SetTextColor(self.LabelNumYuanZhaiBi, colorWhite)
		UIHelper.SetTextColor(self.LabelNumYuanZhaiBi_S, colorWhite)
	end
end

function UIHomelandBuildBuyConfirmView:UpdateMoney(tbLabel, tbLayout, nZhuan, nGold, nSilver)
	local player = GetClientPlayer()
    local tbMoney = {0, nSilver, nGold, nZhuan}
	local tbCurMoney = player.GetMoney()
	local bEnough = true
	if MoneyOptCmp(tbCurMoney, { nGold = nGold + nZhuan*10000, nSilver = nSilver, nCopper = 0 }) < 0 then
		bEnough = false
	end
	local colorType = bEnough and colorWhite or colorRed
    for i, label in ipairs(tbLabel) do
        local layout = tbLayout[i]
        UIHelper.SetString(label, tostring(tbMoney[i]))
		UIHelper.SetTextColor(label, colorType)
        UIHelper.LayoutDoLayout(layout)
    end
end

function UIHomelandBuildBuyConfirmView:OpenGoldBuySure()
    local tInfo = DataModel.tSingleBuy or DataModel.tMultBuy
	if (DataModel.bAllGoldBuy and tInfo.tAllMoney.nTotalSilver > MAX_SILVER) or
		(tInfo.tDiffMoney and tInfo.tDiffMoney.nTotalSilver > MAX_SILVER) then

        local scriptView = UIHelper.ShowConfirm("注意：当前涉及大额交易，请谨慎！", DoBuyFurniture, nil, false)
        scriptView:SetButtonCountDown(3)
	else
		DoBuyFurniture()
	end
end

return UIHomelandBuildBuyConfirmView