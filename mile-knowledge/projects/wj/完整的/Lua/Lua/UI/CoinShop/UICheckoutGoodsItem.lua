-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICheckoutGoodsItem
-- Date: 2022-12-19 15:06:01
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICheckoutGoodsItem = class("UICheckoutGoodsItem")

function UICheckoutGoodsItem:OnEnter(tbGoodsInfo, nIndex, fnUpdateCallback)
    self.tbGoodsInfo = tbGoodsInfo
    self.tbGoodsInfo.nBuyCount = self.tbGoodsInfo.nBuyCount or 1
    self.fnUpdateCallback = fnUpdateCallback

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    UIHelper.SetVisible(self.ImgBg, true)  -- 隔行出现背景图
    self:UpdateInfo()
end

function UICheckoutGoodsItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UICheckoutGoodsItem:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnIncrease, EventType.OnClick, function ()
        if self.tbGoodsInfo.bBody then
            return
        end

        self.tbGoodsInfo.nBuyCount = self.tbGoodsInfo.nBuyCount + 1
        self:CheckBuyItemCount()
        self:UpdateNum()
        self:OnDataUpdate()
    end)

    UIHelper.BindUIEvent(self.BtnDecrease, EventType.OnClick, function ()
        if self.tbGoodsInfo.bBody then
            return
        end

        if self.tbGoodsInfo.nBuyCount - 1 >= 1 then
            self.tbGoodsInfo.nBuyCount = self.tbGoodsInfo.nBuyCount - 1
            self:CheckBuyItemCount()
            self:UpdateNum()
            self:OnDataUpdate()
        end
    end)

    local _EditNumHandler = function()
        local szNum = UIHelper.GetString(self.EditNum)
        local nNum = tonumber(szNum)
        if not nNum or nNum < 1 then
            nNum = 1
        end
        self.tbGoodsInfo.nBuyCount = nNum
        self:CheckBuyItemCount()
        self:UpdateNum()
        self:OnDataUpdate()
    end

    self.EditNum:registerScriptEditBoxHandler(function(szType, _editbox)
        if szType == "ended" then
            if Platform.IsWindows() or Platform.IsMac() then
                _EditNumHandler()
            end
        elseif szType == "return" then
            if not Platform.IsWindows() then
                _EditNumHandler()
            end
        end
    end)

    UIHelper.BindUIEvent(self.TogSelect, EventType.OnSelectChanged, function (_, bSelected)
        self.tbGoodsInfo.bChoose = bSelected
        self:OnDataUpdate()
    end)

    UIHelper.BindUIEvent(self.BtnCollect, EventType.OnClick, function ()
        if self.tbGoodsInfo.eGoodsType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
            CoinShopExterior.Collect(self.tbGoodsInfo.dwGoodsID)
        elseif self.tbGoodsInfo.eGoodsType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
            CoinShopWeapon.Collect(self.tbGoodsInfo.dwGoodsID)
        end
    end)
end

function UICheckoutGoodsItem:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICheckoutGoodsItem:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICheckoutGoodsItem:UpdateInfo()
    if self.tbGoodsInfo.bBody then
        self:UpdateBuildBodyInfo()
    elseif self.tbGoodsInfo.bNewFace then
        self:UpdateBuildFaceInfo()
    elseif self.tbGoodsInfo.eGoodsType == COIN_SHOP_GOODS_TYPE.FACE then
        self:UpdateOldBuildFaceInfo()
    else
        self:UpdateNormalGoodsInfo()
    end
end

function UICheckoutGoodsItem:UpdateNormalGoodsInfo()
    if not self.ItemScript then
        self.ItemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem)
        self.ItemScript:SetClickNotSelected(true)
    end
    CoinShopPreview.InitItemIcon(self.ItemScript, self.tbGoodsInfo, nil, nil)

    UIHelper.SetString(self.LabelType, CoinShop_GetGoodsType(self.tbGoodsInfo))
    UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(CoinShopData.GetBuyItemName(self.tbGoodsInfo)))

    UIHelper.RemoveAllChildren(self.LayoutPrice)

    local nSelectPriceIndex = nil
    for i, tbPriceInfo in ipairs(self.tbGoodsInfo.tPriceInfo) do
        if self.tbGoodsInfo.ePayType == tbPriceInfo.nPayType and self.tbGoodsInfo.eTimeLimitType == tbPriceInfo.nTimeType then
            nSelectPriceIndex = i
        end
    end
    if not nSelectPriceIndex then
        nSelectPriceIndex = #self.tbGoodsInfo.tPriceInfo
    end

    self.tbGoodsInfo.tbPrice = self.tbGoodsInfo.tbPrice or self.tbGoodsInfo.tPriceInfo[nSelectPriceIndex]

    CoinShopData.CalcBill({self.tbGoodsInfo})

    for _, tbPriceInfo in ipairs(self.tbGoodsInfo.tPriceInfo) do
        self.scriptTogPrice = UIHelper.AddPrefab(PREFAB_ID.WidgetSettleAccountsContentCell, self.LayoutPrice, self.tbGoodsInfo, tbPriceInfo, self.TogGroupPrice, function ()
            self.tbGoodsInfo.tbPrice = tbPriceInfo
            self:OnDataUpdate()
        end)
    end

    Timer.AddFrame(self, 1, function ()
        UIHelper.SetToggleGroupSelected(self.TogGroupPrice, nSelectPriceIndex - 1)
    end)

    UIHelper.LayoutDoLayout(self.LayoutPrice)

    self:UpdateNum()
    self:UpdatePrice()



    UIHelper.SetSelected(self.TogSelect, self.tbGoodsInfo.bChoose, false)
    UIHelper.SetTouchEnabled(self.TogSelect, self.tbGoodsInfo.bCheckEnable)
end

function UICheckoutGoodsItem:UpdateBuildBodyInfo()
    if not self.ItemScript then
        self.ItemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem)
        self.ItemScript:SetClickNotSelected(true)
    end

    self.ItemScript:OnInitWithIconID(18991, 2, 1)

    UIHelper.SetVisible(self.WidgetNum, false)
    UIHelper.SetVisible(self.LabelBodyTips, true)
    UIHelper.SetString(self.LabelName, g_tStrings.STR_CHECKOUT_BODY_NAME)
    UIHelper.SetString(self.LabelBodyTips, "消耗体型调整次数")

    if self.tbGoodsInfo.nIndex == nil then
        UIHelper.SetString(self.LabelType, "新增")
    else
        UIHelper.SetString(self.LabelType, "修改")
    end

    self.tbGoodsInfo.bChoose = true
    UIHelper.SetSelected(self.TogSelect, self.tbGoodsInfo.bChoose)
    self:OnDataUpdate()
end

function UICheckoutGoodsItem:UpdateBuildFaceInfo()
    local hFaceManager = GetFaceLiftManager()
	if not hFaceManager then
		return
	end

    if not self.ItemScript then
        self.ItemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem)
        self.ItemScript:SetClickNotSelected(true)
    end

    self.ItemScript:OnInitWithIconID(10776, 2, 1)

    UIHelper.SetVisible(self.WidgetNum, false)
    UIHelper.SetString(self.LabelName, g_tStrings.STR_CHECKOUT_NEW_FACE_NAME)

    local bFreeChance = CoinShopData.GetFreeChance(self.tbGoodsInfo.bNewFace)
    if bFreeChance then
        UIHelper.SetVisible(self.LabelBodyTips, true)
        UIHelper.SetString(self.LabelBodyTips, "消耗一次免费捏脸次数")
    else
        UIHelper.SetVisible(self.LabelBodyTips, false)
    end

    if self.tbGoodsInfo.nIndex == nil then
        UIHelper.SetString(self.LabelType, "新增")
    else
        UIHelper.SetString(self.LabelType, "修改")
    end

    local nVouchars = 0
    local bCanUseVouchers = hFaceManager.CanUseVouchers()
    if bCanUseVouchers then
        nVouchars = hFaceManager.GetVouchers()
    end

    self.tbGoodsInfo.nPrice = self.tbGoodsInfo.nPrice or 0
    if bFreeChance then
        self.tbGoodsInfo.nPrice = 0
    end
    UIHelper.RemoveAllChildren(self.LayoutPrice)
    local tbPriceInfo = {
        nPrice = math.max(self.tbGoodsInfo.nPrice - nVouchars, 0),
        szPriceDesc = "价格",
        bDis = false,
        nDisPrice = math.max(self.tbGoodsInfo.nPrice - nVouchars, 0),
        -- szImagePath = "",
    }
    self.scriptTogPrice = UIHelper.AddPrefab(PREFAB_ID.WidgetSettleAccountsContentCell, self.LayoutPrice, self.tbGoodsInfo, tbPriceInfo, self.TogGroupPrice, function ()
        self.tbGoodsInfo.tbPrice = tbPriceInfo
        self:OnDataUpdate()
    end)
    UIHelper.LayoutDoLayout(self.LayoutPrice)

    self.tbGoodsInfo.bChoose = true
    UIHelper.SetSelected(self.TogSelect, self.tbGoodsInfo.bChoose)
    self:OnDataUpdate()
end

function UICheckoutGoodsItem:UpdateOldBuildFaceInfo()
    local hFaceManager = GetFaceLiftManager()
	if not hFaceManager then
		return
	end

    if not self.ItemScript then
        self.ItemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem)
        self.ItemScript:SetClickNotSelected(true)
    end

    self.ItemScript:OnInitWithIconID(10776, 2, 1)

    UIHelper.SetVisible(self.WidgetNum, false)

    local szName = CoinShop_GetGoodsName(COIN_SHOP_GOODS_TYPE.FACE)
    UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(szName))

    local bFreeChance = CoinShopData.GetFreeChance(false)
    if bFreeChance then
        UIHelper.SetVisible(self.LabelBodyTips, true)
        UIHelper.SetString(self.LabelBodyTips, "消耗一次免费捏脸次数")
    else
        UIHelper.SetVisible(self.LabelBodyTips, false)
    end

    if self.tbGoodsInfo.nIndex == nil then
        UIHelper.SetString(self.LabelType, "新增")
    else
        UIHelper.SetString(self.LabelType, "修改")
    end

    local nVouchars = 0
    local bCanUseVouchers = hFaceManager.CanUseVouchers()
    if bCanUseVouchers then
        nVouchars = hFaceManager.GetVouchers()
    end

    self.tbGoodsInfo.nPrice = self.tbGoodsInfo.nPrice or 0
    if bFreeChance then
        self.tbGoodsInfo.nPrice = 0
    end
    UIHelper.RemoveAllChildren(self.LayoutPrice)
    local tbPriceInfo = {
        nPrice = math.max(self.tbGoodsInfo.nPrice - nVouchars, 0),
        szPriceDesc = "价格",
        bDis = false,
        nDisPrice = math.max(self.tbGoodsInfo.nPrice - nVouchars, 0),
        -- szImagePath = "",
    }
    self.scriptTogPrice = UIHelper.AddPrefab(PREFAB_ID.WidgetSettleAccountsContentCell, self.LayoutPrice, self.tbGoodsInfo, tbPriceInfo, self.TogGroupPrice, function ()
        self.tbGoodsInfo.tbPrice = tbPriceInfo
        self:OnDataUpdate()
    end)
    UIHelper.LayoutDoLayout(self.LayoutPrice)

    self.tbGoodsInfo.bChoose = true
    UIHelper.SetSelected(self.TogSelect, self.tbGoodsInfo.bChoose)
    self:OnDataUpdate()
end

function UICheckoutGoodsItem:UpdateNum()
    UIHelper.SetVisible(self.WidgetNum, self.tbGoodsInfo.bCanBuyMultiple)
    UIHelper.SetVisible(self.BtnDecrease, self.tbGoodsInfo.bCanBuyMultiple)
    UIHelper.SetVisible(self.BtnIncrease, self.tbGoodsInfo.bCanBuyMultiple)
    UIHelper.SetVisible(self.EditNum, self.tbGoodsInfo.bCanBuyMultiple)
    UIHelper.SetVisible(self.EditNumFix, not self.tbGoodsInfo.bCanBuyMultiple)

    UIHelper.SetString(self.EditNum, self.tbGoodsInfo.nBuyCount)
end

function UICheckoutGoodsItem:CheckBuyItemCount()
    local nBuyCount = self.tbGoodsInfo.nBuyCount
    local hItemInfo = GetItemInfo(self.tbGoodsInfo.dwTabType, self.tbGoodsInfo.dwTabIndex)
    local nMaxCount = 1
	if hItemInfo.bCanStack then
		nMaxCount = hItemInfo.nMaxDurability
	end
    if nBuyCount < 1 or nBuyCount > nMaxCount then
		nBuyCount = RangeNumber(nBuyCount, 1, nMaxCount)
	end
	self.tbGoodsInfo.nBuyCount = nBuyCount
end

function UICheckoutGoodsItem:UpdatePrice()
    if not self.bInit then
        return
    end
    local bCollect, nGold = CoinShop_GetCollectInfo(self.tbGoodsInfo.eGoodsType, self.tbGoodsInfo.dwGoodsID)
    UIHelper.SetVisible(self.LabelNeedCollect, not bCollect)
    UIHelper.SetVisible(self.WidgetGoldCollect, not bCollect and nGold >= 0)
    UIHelper.SetString(self.LabelGoldCollect, nGold or 0)
    UIHelper.SetVisible(self.LayoutPrice, bCollect)
    UIHelper.SetSwallowTouches(self.BtnCollect, true)

    UIHelper.SetVisible(self.LayoutSettleAccounts, false)
    UIHelper.SetVisible(self.ImgSettleAccounts, false)
    UIHelper.SetVisible(self.ImgSettleAccountsTime, false)
    if self.tbGoodsInfo.bBody then
        self.tbGoodsInfo.nPrice = 0
        self.tbGoodsInfo.nDiscount = 1
        -- bSureEnable = true
        -- UpdateBodyText(hWndItem, true)
    elseif self.tbGoodsInfo.bNewFace then
        local hManager = GetFaceLiftManager()
        if not hManager then
            return
        end

        local bFreeChance = CoinShopData.GetFreeChance(self.tbGoodsInfo.bNewFace)
        if bFreeChance then
            -- UpdateFaceFreeText(hWndItem, true)
            -- bSureEnable = true
        else
            local tNewPrice
            if self.tbGoodsInfo.nIndex then
                tNewPrice = hManager.GetFacePrice(self.tbGoodsInfo.tFaceData, self.tbGoodsInfo.nIndex)
            else
                tNewPrice = hManager.GetFacePrice(self.tbGoodsInfo.tFaceData)
            end
            self.tbGoodsInfo.ePayType = COIN_SHOP_PAY_TYPE.COIN
            self.tbGoodsInfo.nPrice = tNewPrice.nTotalPrice
            self.tbGoodsInfo.nDiscount = 1
        end
    elseif bCollect then
        local tFormatGoodsInfo = CoinShopData.FormatGood(self.tbGoodsInfo.dwGoodsID, self.tbGoodsInfo.eGoodsType)
        local bShowLimit = tFormatGoodsInfo.szTime and tFormatGoodsInfo.szTime ~= ""
        if self.tbGoodsInfo.bDisCoupon then
            if self.tbGoodsInfo.bFullcut then
                UIHelper.SetString(self.LabelSettleAccounts, "抵扣")
            else
                local nDisCoupon = self.tbGoodsInfo.tbPrice.nDisCoupon
                UIHelper.SetString(self.LabelSettleAccounts, FormatString(g_tStrings.REWARDS_SHOP_DISCOUNT, ("%.1f"):format(nDisCoupon / 10)))
            end
            UIHelper.SetVisible(self.ImgSettleAccounts, true)
            UIHelper.SetVisible(self.LayoutSettleAccounts, true)
            UIHelper.LayoutDoLayout(self.LayoutSettleAccounts)
        elseif bShowLimit then
            UIHelper.SetString(self.LabelSettleAccounts, "限" .. tFormatGoodsInfo.szTime)
            UIHelper.SetVisible(self.ImgSettleAccounts, true)
            UIHelper.SetVisible(self.LayoutSettleAccounts, true)
            UIHelper.LayoutDoLayout(self.LayoutSettleAccounts)
        end
        -- 限量倒计时
        local szLimitItemTime = ""
        if self.tbGoodsInfo.bLimitItem then
            local tbInfo = CoinShop_GetPriceInfo(self.tbGoodsInfo.dwGoodsID, self.tbGoodsInfo.eGoodsType)
            local nTime = GetGSCurrentTime()
            if tbInfo.nStartTime ~= -1 and nTime <= tbInfo.nStartTime then
                local nLeftTime = tbInfo.nStartTime - nTime
                if nLeftTime > 3600 then
                    szLimitItemTime = "大于1小时开售"
                else
                    szLimitItemTime = UIHelper.GetTimeText(nLeftTime) .. "开售"
                end
            end
        end
        -- 有折扣时，限量倒计时就塞进折扣时间里
        if self.tbGoodsInfo.tbPrice.bDis then
            local szDisCount, szDisTime = CoinShop_GetOneDisInfo(self.tbGoodsInfo.tbPrice, self.tbGoodsInfo.tbPrice.bSecondDis, true)
            if szLimitItemTime ~= "" then
                UIHelper.SetString(self.LabelSettleAccountsTime, szDisCount.. "(" .. szLimitItemTime .. ")")
            else
                UIHelper.SetString(self.LabelSettleAccountsTime, szDisCount..szDisTime)
            end
            UIHelper.SetVisible(self.ImgSettleAccountsTime, true)
            UIHelper.SetVisible(self.LayoutSettleAccounts, true)
            UIHelper.LayoutDoLayout(self.LayoutSettleAccounts)
        elseif szLimitItemTime ~= "" then
            UIHelper.SetString(self.LabelSettleAccountsTime, szLimitItemTime)
            UIHelper.SetVisible(self.ImgSettleAccountsTime, true)
            UIHelper.SetVisible(self.LayoutSettleAccounts, true)
            UIHelper.LayoutDoLayout(self.LayoutSettleAccounts)
        end
    end
    --UIHelper.SetEnable(self.TogSelect, bCollect)
    Timer.DelTimer(self, self.nPriceTimerID)
    self.nPriceTimerID = Timer.Add(self, 0.1, function()
        self:UpdatePrice()
    end)
end

function UICheckoutGoodsItem:OnDataUpdate()
    if self.fnUpdateCallback then
        self.fnUpdateCallback()
    end
end

function UICheckoutGoodsItem:SelectItemIcon(bSelect)
    if self.ItemScript then
        self.ItemScript:SetSelected(bSelect)
    end
end

return UICheckoutGoodsItem