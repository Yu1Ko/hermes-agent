-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopBuildFaceBuyDetailView
-- Date: 2023-11-10 10:14:11
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICoinShopBuildFaceBuyDetailView = class("UICoinShopBuildFaceBuyDetailView")

local DetailConfig = {
    {
        szName = "脸型调整",
        bShowRemoveBtn = true,
        bShowCost = true,
    },
    {
        szName = "妆容调整",
        bShowRemoveBtn = true,
        bShowCost = true,
    },
    {
        szName = "手续费",
        bShowRemoveBtn = false,
        bShowCost = true,
    },
    {
        szName = "发型",
        bShowRemoveBtn = true,
        bShowCost = false,
    },
    {
        szName = "体型",
        bShowRemoveBtn = true,
        bShowCost = true,
    },
}

function UICoinShopBuildFaceBuyDetailView:OnEnter(nFaceIndex, nBodyIndex, bNewFace, bFaceHave, bUseNewFace, funcDoBuy)
    self.bUseNewFace = nil
    self.bUseNewBody = nil

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nFaceIndex = nFaceIndex
    self.nBodyIndex = nBodyIndex
    self.bNewFace = bNewFace
    self.bFaceHave = bFaceHave
    self.funcDoBuy = funcDoBuy
    self:UpdateInfo()
end

function UICoinShopBuildFaceBuyDetailView:OnExit()
    self.bInit = false
end

function UICoinShopBuildFaceBuyDetailView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnBuy, EventType.OnClick, function(btn)
        if (not self.bFaceHave and self.bUseNewFace == nil) or (self.nBodyIndex and self.bUseNewBody == nil) then
            TipsHelper.ShowNormalTip("请先选择保存方式")
            return
        end

        if self.funcDoBuy then
            self.funcDoBuy(self.bUseNewFace, self.bUseNewBody)
        end
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.TogSaveNewFace, EventType.OnClick, function ()
        self.bUseNewFace = true
        self:UpdatePriceInfo()
        self:UpdateBtnState()
    end)

    UIHelper.BindUIEvent(self.TogEditFace, EventType.OnClick, function ()
        self.bUseNewFace = false
        self:UpdatePriceInfo()
        self:UpdateBtnState()
    end)
    UIHelper.ToggleGroupAddToggle(self.TogGroupSaveWayFace, self.TogSaveNewFace)
    UIHelper.ToggleGroupAddToggle(self.TogGroupSaveWayFace, self.TogEditFace)
    UIHelper.SetToggleGroupSelected(self.TogGroupSaveWayFace, self.bUseNewFace and 0 or 1)

    UIHelper.BindUIEvent(self.TogSaveNewBody, EventType.OnClick, function ()
        self.bUseNewBody = true
        self:UpdatePriceInfo()
        self:UpdateBtnState()
    end)

    UIHelper.BindUIEvent(self.TogEditBody, EventType.OnClick, function ()
        self.bUseNewBody = false
        self:UpdatePriceInfo()
        self:UpdateBtnState()
    end)
    UIHelper.ToggleGroupAddToggle(self.TogGroupSaveWayBody, self.TogSaveNewBody)
    UIHelper.ToggleGroupAddToggle(self.TogGroupSaveWayBody, self.TogEditBody)
    UIHelper.SetToggleGroupSelected(self.TogGroupSaveWayBody, self.bUseNewBody and 0 or 1)

    UIHelper.BindUIEvent(self.BtnFreeFaceShowTips, EventType.OnClick, function(btn)
        local hPlayer = GetClientPlayer()
        local nCount, nLimitCount, nFreeChanceEndTime = hPlayer.GetFaceLiftFreeChanceV2()
        local bNewFace = ExteriorCharacter.IsNewFace()
        if not bNewFace then
            nCount, nLimitCount, nFreeChanceEndTime = hPlayer.GetFaceLiftFreeChance()
        end
        local tData = TimeToDate(nFreeChanceEndTime)
		local szHour = string.format("%02d", tData.hour)
		local szMinute = string.format("%02d", tData.minute)
    	local szTips = string.format("限时时间:%s", FormatString(g_tStrings.STR_TIME_4, tData.year, tData.month, tData.day, szHour, szMinute))
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetRichTextTips, self.BtnFreeFaceShowTips, TipsLayoutDir.BOTTOM_CENTER, szTips)
    end)
    UIHelper.SetTouchDownHideTips(self.BtnFreeFaceShowTips, false)

    UIHelper.BindUIEvent(self.BtnFreeBodyShowTips, EventType.OnClick, function(btn)
        local hPlayer = GetClientPlayer()
        local nFreeCount, nTimeLimitFreeChance, nTimeLimitFreeChanceEndTime = hPlayer.GetBodyReshapingFreeChance()

        local tData = TimeToDate(nTimeLimitFreeChanceEndTime)
		local szHour = string.format("%02d", tData.hour)
		local szMinute = string.format("%02d", tData.minute)
    	local szTips = string.format("限时时间:%s", FormatString(g_tStrings.STR_TIME_4, tData.year, tData.month, tData.day, szHour, szMinute))
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetRichTextTips, self.BtnFreeBodyShowTips, TipsLayoutDir.BOTTOM_CENTER, szTips)
    end)
    UIHelper.SetTouchDownHideTips(self.BtnFreeBodyShowTips, false)

    UIHelper.BindUIEvent(self.BtnAddBuildBodyTimes, EventType.OnClick, function ()
        local tLine = CoinShopData.GetBuyBodyCountItem()
        if tLine then
            local tInfo = CoinShop_GetPriceInfo(tLine.dwGoodsID, COIN_SHOP_GOODS_TYPE.ITEM)
            local bDis, szDisCount = CoinShop_GetDisInfo(tInfo)
            local nPrice, nOriginalPrice = CoinShop_GetShowPrice(tInfo)
            local szName = CoinShop_GetGoodsName(eGoodsType, dwGoodsID)
            local szMsg = FormatString(g_tStrings.COINSHOP_BODY_BUY_COUNT, nPrice, szName, tLine.nCount)

            szMsg = ParseTextHelper.ParseNormalText(szMsg, false)
            UIHelper.ShowConfirm(szMsg, function ()
                CoinShop_BuyItem(tLine.dwGoodsID, COIN_SHOP_GOODS_TYPE.ITEM, 1)
            end, nil, true)

            return true
        else
            OutputMessage("MSG_ANNOUNCE_NORMAL", "暂无法购买体型次数")
        end
    end)
end

function UICoinShopBuildFaceBuyDetailView:RegEvent()
    Event.Reg(self, "SYNC_REWARDS", function ()
        self:UpdateCurreny()
    end)

    Event.Reg(self, "FACE_LIFT_VOUCHERS_CHANGE", function ()
        self:UpdateCurreny()
    end)

    Event.Reg(self, "ON_COIN_SHOP_VOUCHER_CHANGED", function ()
        self:UpdateCurreny()
    end)

    Event.Reg(self, "COIN_SHOP_BUY_RESPOND", function (nErrorCode)
        if nErrorCode == COIN_SHOP_ERROR_CODE.SUCCESS then
            self:UpdateBtnState()
        end
    end)

    Event.Reg(self, "FACE_LIFT_FREE_CHANCE_CHANGE", function ()
        self:UpdateBtnState()
    end)
end

function UICoinShopBuildFaceBuyDetailView:UpdateInfo()
    self:InitCurrency()
    self:UpdateBaseInfo()
    self:UpdatePriceInfo()
    self:UpdateBtnState()
end

function UICoinShopBuildFaceBuyDetailView:InitCurrency()
    UIMgr.AddPrefab(PREFAB_ID.WidgetCoin, self.LayoutCurrency, CurrencyType.Coin, false)
    self.RewardsScript = UIMgr.AddPrefab(PREFAB_ID.WidgetOtherCurrency, self.LayoutCurrency)
    self.RewardsScript:SetCurrencyType(CurrencyType.FaceVouchers)
    self:UpdateCurreny()
end

function UICoinShopBuildFaceBuyDetailView:UpdateCurreny()
    local nVouchars = GetFaceLiftManager().GetVouchers()
    if nVouchars > 0 then
        self.RewardsScript:SetLableCount(nVouchars)
        UIHelper.SetVisible(self.RewardsScript._rootNode, true)
    else
        UIHelper.SetVisible(self.RewardsScript._rootNode, false)
    end
    UIHelper.LayoutDoLayout(self.LayoutCurrency)
end

function UICoinShopBuildFaceBuyDetailView:UpdateBaseInfo()
    if not self.bFaceHave then
        UIHelper.SetTabVisible(self.tbWidgetBuildFace, true)
    else
        UIHelper.SetTabVisible(self.tbWidgetBuildFace, false)
    end

    if self.nBodyIndex then
        UIHelper.SetTabVisible(self.tbWidgetBuildBody, true)
    else
        UIHelper.SetTabVisible(self.tbWidgetBuildBody, false)
    end

    UIHelper.SetVisible(self.WidgetTogSaveOldFace, not not self.nFaceIndex)

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewDetailList)
end

function UICoinShopBuildFaceBuyDetailView:UpdatePriceInfo()
    local tbBuySaveList = CoinShopPreview.GetBuySaveList(self.bUseNewFace, self.bUseNewBody)
    if #tbBuySaveList <= 0 then
        TipsHelper.ShowNormalTip("已无任何改动，自动退出购买详情界面")
        UIMgr.Close(self)
		return
    end

    local tbData = Lib.copyTab(DetailConfig)
    self:ParseData(tbBuySaveList, tbData)

    for i, widget in ipairs(self.tbScriptCell) do
        local script = UIHelper.GetBindScript(widget)
        if script then
            script:OnEnter(tbData[i])
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewDetailList)
end

function UICoinShopBuildFaceBuyDetailView:UpdateBtnState()
    if (not self.bFaceHave and self.bUseNewFace == nil) or (self.nBodyIndex and self.bUseNewBody == nil) then
        UIHelper.SetButtonState(self.BtnBuy, BTN_STATE.Disable, "请先选择保存方式")
    else
        UIHelper.SetButtonState(self.BtnBuy, BTN_STATE.Normal)
    end

    if self.bUseNewFace == nil then
        UIHelper.SetSelected(self.TogSaveNewFace, false)
        UIHelper.SetSelected(self.TogEditFace, false)
    end

    if self.bUseNewBody == nil then
        UIHelper.SetSelected(self.TogSaveNewBody, false)
        UIHelper.SetSelected(self.TogEditBody, false)
    end

    local hPlayer = GetClientPlayer()
    local nCount, nLimitCount, nFreeChanceEndTime = hPlayer.GetFaceLiftFreeChanceV2()
    local bNewFace = ExteriorCharacter.IsNewFace()
    if not bNewFace then
        nCount, nLimitCount, nFreeChanceEndTime = hPlayer.GetFaceLiftFreeChance()
    end

    UIHelper.SetVisible(self.LabelFreeTip, (nCount + nLimitCount) > 0 and not self.bFaceHave)
    UIHelper.LayoutDoLayout(self.LayoutMoney)
    UIHelper.LayoutDoLayout(self.LayoutPrice)

    UIHelper.SetVisible(self.BtnFreeFaceShowTips, nLimitCount and nLimitCount > 0)
    UIHelper.SetString(self.LabelFreeFace, string.format("%d(永久)+%d(限时)", nCount or 0, nLimitCount or 0))
    UIHelper.LayoutDoLayout(self.LayoutFreeFace)

    local nFreeCount, nTimeLimitFreeChance, nTimeLimitFreeChanceEndTime = hPlayer.GetBodyReshapingFreeChance()
    UIHelper.SetVisible(self.BtnFreeBodyShowTips, nTimeLimitFreeChance and nTimeLimitFreeChance > 0)
    UIHelper.SetString(self.LabelFreeBody, string.format("%d(永久)+%d(限时)", nFreeCount or 0, nTimeLimitFreeChance or 0))
    UIHelper.LayoutDoLayout(self.LayoutFreeBody)

    UIHelper.LayoutDoLayout(self.LayoutBtn)
    UIHelper.LayoutDoLayout(self.LayoutRightTop)
end

function UICoinShopBuildFaceBuyDetailView:ParseData(tbBuySaveList, tbData)
    local hFaceManager = GetFaceLiftManager()
	if not hFaceManager then
		return
	end

    local nTotalPrice = 0
    for _, tbInfo in ipairs(tbBuySaveList) do

        local nVouchars = 0
        local bCanUseVouchers = hFaceManager.CanUseVouchers()
        if bCanUseVouchers then
            nVouchars = hFaceManager.GetVouchers()
        end

        if tbInfo.bNewFace then
            local tNewPrice = hFaceManager.GetFacePrice(BuildFaceData.tNowFaceData)
            if not self.bUseNewFace and self.nFaceIndex then
                tNewPrice = hFaceManager.GetFacePrice(BuildFaceData.tNowFaceData, self.nFaceIndex)
            end
            if not tNewPrice then
                LOG.ERROR("UICoinShopBuildFaceBuyDetailView:ParseData ERROR! tNewPrice is nil!")
                return
            end

            tbData[1].bUseFreeTimes = false
            tbData[1].nPrice = tNewPrice.nBonePrice
            tbData[1].funcDel = function ()
                BuildFaceData.ResetFaceBone()
                Event.Dispatch(EventType.OnUpdateBuildFaceModle)
                self:UpdatePriceInfo()
            end

            local tPriceInfo 		= hFaceManager.GetBasePriceInfo()
            local bDis 				= CoinShop_IsDis(tPriceInfo)
            local szDisCount 		= CoinShop_GetOneDisInfo(tPriceInfo)

            tbData[1].bDis = bDis
            tbData[1].szDisCount = szDisCount

            tbData[2].bUseFreeTimes = false
            tbData[2].nPrice = tNewPrice.nDecalPrice + tNewPrice.nDecorationPrice
            tbData[2].funcDel = function ()
                BuildFaceData.ResetFaceDecal()
                BuildFaceData.ResetFaceDecoration()
                Event.Dispatch(EventType.OnUpdateBuildFaceModle)
                self:UpdatePriceInfo()
            end

            bDis, szDisCount 	= BuildFaceData.GetDecalDis()
            if not bDis then
                bDis, szDisCount = BuildFaceData.GetDecorationDis()
            end
            tbData[2].bDis = bDis
            tbData[2].szDisCount = szDisCount

            tbData[3].bUseFreeTimes = false
            tbData[3].nPrice = tNewPrice.nTaxPrice

            tPriceInfo 	= hFaceManager.GetChangeTaxPriceInfo()
            bDis 				= CoinShop_IsDis(tPriceInfo)
            szDisCount 	= CoinShop_GetOneDisInfo(tPriceInfo)
            tbData[3].bDis = bDis
            tbData[3].szDisCount = szDisCount

            nTotalPrice = nTotalPrice + math.max(0, tNewPrice.nTotalPrice - nVouchars)
        elseif tbInfo.eGoodsType == COIN_SHOP_GOODS_TYPE.FACE then
            local tNewPrice = hFaceManager.GetFacePrice(BuildFaceData.tNowFaceData.tFaceData)
            if not self.bUseNewFace and self.nFaceIndex then
                tNewPrice = hFaceManager.GetFacePrice(BuildFaceData.tNowFaceData.tFaceData, self.nFaceIndex)
            end
            if not tNewPrice then
                LOG.ERROR("UICoinShopBuildFaceBuyDetailView:ParseData ERROR! tNewPrice is nil!")
                return
            end

            tbData[1].bUseFreeTimes = false
            tbData[1].nPrice = tNewPrice.nBonePrice
            tbData[1].funcDel = function ()
                BuildFaceData.ResetFaceBone()
                Event.Dispatch(EventType.OnUpdateBuildFaceModle)
                self:UpdatePriceInfo()
            end

            local tPriceInfo 		= hFaceManager.GetBasePriceInfo()
            local bDis 				= CoinShop_IsDis(tPriceInfo)
            local szDisCount 		= CoinShop_GetOneDisInfo(tPriceInfo)

            tbData[1].bDis = bDis
            tbData[1].szDisCount = szDisCount

            tbData[2].bUseFreeTimes = false
            tbData[2].nPrice = tNewPrice.nDecalPrice + tNewPrice.nDecorationPrice
            tbData[2].funcDel = function ()
                BuildFaceData.ResetFaceDecal()
                BuildFaceData.ResetFaceDecoration()
                Event.Dispatch(EventType.OnUpdateBuildFaceModle)
                self:UpdatePriceInfo()
            end

            local bDis, szDisCount = BuildFaceData.GetOldDecalDis()
            if not bDis then
                bDis, szDisCount = BuildFaceData.GetOldDecorationDis()
            end
            tbData[2].bDis = bDis
            tbData[2].szDisCount = szDisCount

            tbData[3].bUseFreeTimes = false
            tbData[3].nPrice = tNewPrice.nTaxPrice

            tPriceInfo 	= hFaceManager.GetChangeTaxPriceInfo()
            bDis 				= CoinShop_IsDis(tPriceInfo)
            szDisCount 	= CoinShop_GetOneDisInfo(tPriceInfo)
            tbData[3].bDis = bDis
            tbData[3].szDisCount = szDisCount


            nTotalPrice = nTotalPrice + math.max(0, tNewPrice.nTotalPrice - nVouchars)
        elseif tbInfo.bBody then
            tbData[5].bUseFreeTimes = true
            tbData[5].szFreeTimes = nil

            tbData[5].funcDel = function ()
                BuildFaceData.ResetFaceDecal()
                BuildFaceData.ResetFaceDecoration()
                Event.Dispatch(EventType.OnUpdateBuildFaceModle)
            end
        elseif tbInfo.dwGoodsID then
            tbData[4].funcDel = function ()
                BuildHairData.ResetHair()
                Event.Dispatch(EventType.OnUpdateBuildFaceModle)
            end
        end
    end

    UIHelper.SetString(self.LabelMoney, nTotalPrice)
    UIHelper.LayoutDoLayout(self.LayoutMoney)
end


return UICoinShopBuildFaceBuyDetailView