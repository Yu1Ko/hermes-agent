local UIItemTipQuantityController = class("UIItemTipQuantityController")

local szAddButtonImgPath = "UIAtlas2_Public_PublicButton_PublicButton1_BtnAdd"
local szDefaultButtonImgPath = "UIAtlas2_Public_PublicButton_PublicButton1_BtnTo"
function UIItemTipQuantityController:OnEnter(tData)
    if not tData or not tData.tbGoods then
        return
    end
    if not tData.nMaxCount then
        tData.nMaxCount = 0
    end
    if not tData.tPrice then
        tData.tPrice = FormatMoneyTab(0)
    end
    if not tData.bCanStack then
        tData.bCanStack = false
    end

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:InitView(tData)
    if type(tData.tbGoods.nShopID) == "number" then
        local dwItemID = GetShopItemID(tData.tbGoods.nShopID, tData.tbGoods.dwShopIndex)
        if dwItemID and dwItemID > 0 then
            self.bCheckCanBuy = true
            self:UpdateInfo(tData.nMaxCount, tData.tPrice, tData.bCanStack, tData.tbGoods, tData.aShopInfo)
        end
    else
        self:UpdateInfo(tData.nMaxCount, tData.tPrice, tData.bCanStack, tData.tbGoods, tData.aShopInfo)
    end
end

function UIItemTipQuantityController:OnExit()
    self.bInit = false
end

function UIItemTipQuantityController:BindUIEvent()
    self:DoBindUIEvent(self.ButtonAddDefault, self.ButtonDecreaseDefault, self.SliderCountDefault, self.EditPaginateDefault)
    self:DoBindUIEvent(self.ButtonAddWithQuickBtn, self.ButtonDecreaseWithQuickBtn, self.SliderCountWithQuickBtn, self.EditPaginateWithQuickBtn)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        if type(self.tbGoods.nShopID) == "number" then
            local nRetCode = CanMultiBuyItem(self.nNpcID, self.nShopID, self.tbGoods.dwShopIndex, self.nBuyCount)
            if nRetCode ~= SHOP_SYSTEM_RESPOND_CODE.BUY_SUCCESS then
                local szMsg = g_tStrings.g_ShopStrings[nRetCode]
                if szMsg then
                    OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
                else
                    OutputMessage("MSG_ANNOUNCE_NORMAL", "购买条件不满足")
                end
                return
            end
        end
        Event.Dispatch(EventType.OnShopBuyGoodsSure, self.nBuyCount)
    end)

    UIHelper.BindUIEvent(self.ButtonCount, EventType.OnClick, function()
        if self.nDefaultNeedCount == 0 and self.nDefaultStepCount == 0  then return end

        if self.nBuyCount < self.nDefaultNeedCount then
            self.nBuyCount = self.nDefaultNeedCount
        else
            self.nBuyCount = self.nBuyCount + self.nDefaultStepCount
        end

        if self.nBuyCount > self.nMaxCount then
            self.nBuyCount = math.max(self.nMinCount, self.nMaxCount)
            OutputMessage("MSG_ANNOUNCE_NORMAL", "商品可购买数量已达上限")
        elseif self.nBuyCount < self.nMinCount then
            self.nBuyCount = self.nMinCount
            OutputMessage("MSG_ANNOUNCE_NORMAL", "商品可购买数量已达下限")
        end
        UIHelper.SetString(self.LabelCount, tostring(self.nBuyCount))
        UIHelper.SetText(self.EditPaginate, tostring(self.nBuyCount))
        self:RefreshProgressBarPercent()
        self:RefreshMoneyLabel()
    end)

    for nIndex, BtnCurrency in ipairs(self.tbButtonCurrency) do
        UIHelper.BindUIEvent(BtnCurrency, EventType.OnClick, function()
            local tData = self.tCurrencyData[nIndex]
            if type(tData) == "string" then
                CurrencyData.ShowCurrencyHoverTips(BtnCurrency,tData)
            else
                local _,tipsScriptView = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, BtnCurrency)
                tipsScriptView:OnInitWithTabID(tData.dwTabType, tData.dwIndex)
                tipsScriptView:SetBtnState({})
            end
        end)
    end

    UIHelper.BindUIEvent(self.BtnPreview, EventType.OnClick, function()
        local nItemType = self.tbGoods.nItemType
        local nItemIndex = self.tbGoods.nItemIndex
        local tbPreviewBtn = OutFitPreviewData.SetPreviewBtn(nItemType, nItemIndex)
        if not table.is_empty(tbPreviewBtn) then
            tbPreviewBtn[1].OnClick()
        end
    end)

    UIHelper.BindUIEvent(self.BtnBuy, EventType.OnClick, function()
        if type(self.tbGoods.nShopID) == "number" then
            if self.tbGoods.bNeedFame and not self.tbGoods.bFameSatisfy then
                TipsHelper.ShowNormalTip("江湖名望等级不足")
                return
            end

            local nRetCode = CanMultiBuyItem(self.nNpcID, self.nShopID, self.tbGoods.dwShopIndex, self.nBuyCount)
            if nRetCode ~= SHOP_SYSTEM_RESPOND_CODE.BUY_SUCCESS then
                local szMsg = g_tStrings.g_ShopStrings[nRetCode]
                if szMsg then
                    OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
                else
                    OutputMessage("MSG_ANNOUNCE_NORMAL", "购买条件不满足")
                end
                return
            end
        end
        Event.Dispatch(EventType.OnShopBuyGoodsSure, self.nBuyCount)
    end)
end

function UIItemTipQuantityController:DoBindUIEvent(ButtonAdd, ButtonDecrease, SliderCount, EditPaginate)
    UIHelper.BindUIEvent(ButtonAdd, EventType.OnClick, function()
        self.nBuyCount = self.nBuyCount + self.nMinCount

        self.nBuyCount = math.ceil(self.nBuyCount)
        if self.nBuyCount>self.nMaxCount then
            self.nBuyCount = math.max(self.nMinCount, self.nMaxCount)
            OutputMessage("MSG_ANNOUNCE_NORMAL", "商品可购买数量已达上限")
        end
        UIHelper.SetString(self.LabelCount, tostring(self.nBuyCount))
        UIHelper.SetText(self.EditPaginate, tostring(self.nBuyCount))
        self:RefreshProgressBarPercent()
        self:RefreshMoneyLabel()
    end)

    UIHelper.BindUIEvent(ButtonDecrease, EventType.OnClick, function()
        self.nBuyCount = self.nBuyCount - self.nMinCount
        self.nBuyCount = math.ceil(self.nBuyCount)
        if self.nBuyCount<self.nMinCount then
            self.nBuyCount = self.nMinCount
            OutputMessage("MSG_ANNOUNCE_NORMAL", "商品可购买数量已达下限")
        end
        UIHelper.SetString(self.LabelCount, tostring(self.nBuyCount))
        UIHelper.SetText(self.EditPaginate, tostring(self.nBuyCount))
        self:RefreshProgressBarPercent()
        self:RefreshMoneyLabel()
    end)

    UIHelper.BindUIEvent(SliderCount, EventType.OnChangeSliderPercent, function(SliderEventType, nSliderEvent)
        if nSliderEvent == ccui.SliderEventType.slideBallDown then
            self.bSliding = true
        elseif nSliderEvent == ccui.SliderEventType.slideBallUp then
            self.bSliding = false
            -- 强制修正滑块进度
            self:RefreshProgressBarPercent()
        end

        local percent = UIHelper.GetProgressBarPercent(SliderCount)/100
        if self.bSliding then
            local nMaxCount = self.nMaxCount
            local nBuyCount = percent*nMaxCount
            self.nBuyCount = nBuyCount+self.nMinCount
            if not self.bCanStack then
                self.nBuyCount = math.ceil(self.nBuyCount)
            else
                self.nBuyCount = math.floor(self.nBuyCount/self.nMinCount)*self.nMinCount
            end

            if self.nBuyCount<=self.nMinCount then
                self.nBuyCount = self.nMinCount
            elseif self.nBuyCount>=self.nMaxCount then
                self.nBuyCount = self.nMaxCount
            end
            UIHelper.SetString(self.LabelCount, tostring(self.nBuyCount))
            UIHelper.SetText(self.EditPaginate, tostring(self.nBuyCount))
            self:RefreshMoneyLabel()
            --self:RefreshProgressBarPercent()
        end

        UIHelper.SetWidth(self.ImgFg, UIHelper.GetWidth(self.ImgBg)*percent)
    end)

    UIHelper.RegisterEditBoxEnded(EditPaginate, function ()
        local szCount = UIHelper.GetText(EditPaginate) or "0"
        self.nBuyCount = tonumber(szCount)
        self.nBuyCount = math.ceil(self.nBuyCount)
        if self.nBuyCount>self.nMaxCount then
            self.nBuyCount = math.max(self.nMinCount, self.nMaxCount)
            OutputMessage("MSG_ANNOUNCE_NORMAL", "商品可购买数量已达上限")
        elseif self.nBuyCount<self.nMinCount then
            self.nBuyCount = self.nMinCount
            OutputMessage("MSG_ANNOUNCE_NORMAL", "商品可购买数量已达下限")
        end
        UIHelper.SetString(self.LabelCount, tostring(self.nBuyCount))
        UIHelper.SetText(EditPaginate, tostring(self.nBuyCount))
        self:RefreshProgressBarPercent()
        self:RefreshMoneyLabel()
    end)
end

function UIItemTipQuantityController:RegEvent()
    Event.Reg(self, EventType.OnGameNumKeyboardOpen, function(editbox)
        if editbox ~= self.EditPaginate then return end
        UIHelper.SetEditBoxGameKeyboardRange(self.EditPaginate, self.nMinCount, self.nMaxCount)
    end)

    Event.Reg(self, EventType.OnGameNumKeyboardChanged, function(editbox, num)
        if editbox ~= self.EditPaginate then return end

        local szCount = UIHelper.GetText(self.EditPaginate) or "0"
        self.nBuyCount = tonumber(szCount)
        self.nBuyCount = math.ceil(self.nBuyCount)
        if self.nBuyCount>self.nMaxCount then
            self.nBuyCount = math.max(self.nMinCount, self.nMaxCount)
            OutputMessage("MSG_ANNOUNCE_NORMAL", "商品可购买数量已达上限")
        elseif self.nBuyCount<self.nMinCount then
            self.nBuyCount = self.nMinCount
            OutputMessage("MSG_ANNOUNCE_NORMAL", "商品可购买数量已达下限")
        end
        UIHelper.SetString(self.LabelCount, tostring(self.nBuyCount))
        UIHelper.SetText(self.EditPaginate, tostring(self.nBuyCount))
        self:RefreshProgressBarPercent()
        self:RefreshMoneyLabel()
    end)
end

function UIItemTipQuantityController:InitView(tData)
    self.tData = tData
    self.nNpcID = tData.nNpcID
    self.nShopID = tData.nShopID
    self.nNeedCount = tData.nNeedCount
    self.bCheckCanBuy = false

    self.nDefaultNeedCount, self.nDefaultStepCount = Table_GetShopMultiBuyLimit(tData.tbGoods.nItemType, tData.tbGoods.nItemIndex)
    self.nDefaultNeedCount = self.nDefaultStepCount or 0  -- 玩家反馈当前批量购买覆盖值太大，策划决定先改成读步长值更新出去
    self.nDefaultStepCount = self.nDefaultStepCount or 0

    self.ButtonAdd = self.ButtonAddDefault
    self.ButtonDecrease = self.ButtonDecreaseDefault
    self.SliderCount = self.SliderCountDefault
    self.ImgBg = self.ImgBgDefault
    self.ImgFg = self.ImgFgDefault
    self.LabelCountTittle = self.LabelCountTittleDefault
    self.WidgetEdit = self.WidgetEditDefault
    self.EditPaginate = self.EditPaginateDefault

    if self.nDefaultNeedCount > 0 or self.nDefaultStepCount > 0 then
        self.ButtonAdd = self.ButtonAddWithQuickBtn
        self.ButtonDecrease = self.ButtonDecreaseWithQuickBtn
        self.SliderCount = self.SliderCountWithQuickBtn
        self.ImgBg = self.ImgBgWithQuickBtn
        self.ImgFg = self.ImgFgWithQuickBtn

        self.LabelCountTittle = self.LabelCountTittleWithQuickBtn
        self.WidgetEdit = self.WidgetEditWithQuickBtn
        self.EditPaginate = self.EditPaginateWithQuickBtn

        if self.nDefaultNeedCount > 0 then
            UIHelper.SetString(self.LabelDefaultCount, tostring(self.nDefaultNeedCount))
        elseif self.nDefaultStepCount > 0 then
            UIHelper.SetString(self.LabelDefaultCount, tostring(self.nDefaultStepCount))
        end
    end
end

function UIItemTipQuantityController:UpdateInfo(nMaxCount, tDataPrice, bCanStack, tbGoods, aShopInfo)
    self.tbGoods = tbGoods
    self.bCanStack = bCanStack
    self.aShopInfo = aShopInfo
    self.nMinCount = 1
    self.nBuyCount = 1
    self.nStackNum = nil
    local tPrice = FormatMoneyTab(tDataPrice)
	if aShopInfo then
		if aShopInfo.nGobalLimitCount > 0 and nMaxCount > aShopInfo.nGobalLimitCount then
			nMaxCount = aShopInfo.nGobalLimitCount
		end

		if aShopInfo.nPlayerLeftCount > 0 and nMaxCount > aShopInfo.nPlayerLeftCount then
			nMaxCount = aShopInfo.nPlayerLeftCount
		end
	end

    local bBuyBack = type(tbGoods.nShopID) ~= "number"
    local item = ShopData.GetItemByGoods(tbGoods)
    if item and item.bCanStack and item.nStackNum and item.nStackNum > 0 then
        if bBuyBack then
            self.nStackNum = item.nStackNum
        else
            self.nBuyCount = item.nStackNum
        end
    end

    if self.nNeedCount and self.nNeedCount > 1 then
        self.nBuyCount = self.nNeedCount
    end

    local tOtherInfo
    if type(self.tbGoods.nShopID) == "number" then
        tOtherInfo = GetShopItemBuyOtherInfo(self.tbGoods.nShopID, self.tbGoods.dwShopIndex)
    end

    local nMaxCountWithMoney = self:GetMaxBuyLimit(tPrice, tOtherInfo)
    if nMaxCountWithMoney >= 1 and nMaxCountWithMoney < nMaxCount then
        nMaxCount = nMaxCountWithMoney
    elseif nMaxCountWithMoney < 1 then
        nMaxCount = 1
    end
    nMaxCount = math.floor(nMaxCount/self.nMinCount)*self.nMinCount
    self.nMaxCount = nMaxCount
    if self.nMaxCount < 1 then self.nMaxCount = 1 end
    if self.nBuyCount > self.nMaxCount then self.nBuyCount = self.nMaxCount end

    self.tPrice = tPrice

    if not self.nStackNum then
        UIHelper.SetString(self.LabelCount, tostring(self.nBuyCount))
    else
        UIHelper.SetString(self.LabelCount, tostring(self.nStackNum))
    end
    UIHelper.SetText(self.EditPaginate, tostring(self.nBuyCount))

    local bShowSlider = not bBuyBack and self.nMaxCount > 1
    local bHasDefaultCount = self.nDefaultNeedCount > 0 or self.nDefaultStepCount > 0
    UIHelper.SetVisible(self.WidgetSlider, bShowSlider and not bHasDefaultCount)
    UIHelper.SetVisible(self.WidgetSliderWithQuickBtn, bShowSlider and bHasDefaultCount)
    UIHelper.SetVisible(self.WidgetCountDefault, not bHasDefaultCount)
    UIHelper.SetVisible(self.WidgetCountWithQuickBtn, bHasDefaultCount)
    UIHelper.LayoutDoLayout(self.LayoutBuyCount)
    UIHelper.SetVisible(self.LabelCount, self.nMaxCount == 1)
    UIHelper.SetVisible(self.WidgetEdit, self.nMaxCount > 1)
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutCount, true, true)

    self:RefreshProgressBarPercent()
    self:RefreshMoneyLabel()

    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
end

function UIItemTipQuantityController:RefreshMoneyLabel()
    local bNeedGray, bMoneyNotEnough, _ = ShopData.CheckNeedGray(self.nNpcID, self.nShopID, self.tbGoods, self.nBuyCount)
    local tPrice = MoneyOptMult(self.tPrice, self.nBuyCount)
    local tOtherInfo
    if type(self.tbGoods.nShopID) == "number" then
        tOtherInfo = GetShopItemBuyOtherInfo(self.tbGoods.nShopID, self.tbGoods.dwShopIndex)
    else
        tPrice = self.tPrice
    end

    UIHelper.SetNodeGray(self.BtnConfirm, false, true)
    UIHelper.SetColor(self.BtnConfirm, cc.c3b(255, 255, 255))
    UIHelper.SetNodeGray(self.BtnBuy, false, true)
    UIHelper.SetColor(self.BtnBuy, cc.c3b(255, 255, 255))
    if self.aShopInfo and (
        (self.aShopInfo.nGlobalLimt>0 and self.aShopInfo.nBuyCount >= self.aShopInfo.nGlobalLimt) or
        (self.aShopInfo.nPlayerLimit>0 and self.aShopInfo.nPlayerBuyCount >= self.aShopInfo.nPlayerLimit)) then
        UIHelper.SetString(self.LabelConfirm, g_tStrings.Shop.STR_SELL_OUT)
    else
        UIHelper.SetString(self.LabelConfirm, g_tStrings.Shop.STR_BUY_ITEM)
    end

    UIHelper.SetNodeGray(self.ButtonAdd, false, true)
    UIHelper.SetNodeGray(self.ButtonDecrease, false, true)
    UIHelper.SetNodeGray(self.SliderCount, false, true)
    UIHelper.SetNodeGray(self.Handle, false, true)

    if self.nMaxCount == 1 or self.nBuyCount >=self.nMaxCount or bNeedGray then
        UIHelper.SetNodeGray(self.ButtonAdd, true, true)
    end

    if self.nBuyCount <= self.nMinCount then
        UIHelper.SetNodeGray(self.ButtonDecrease, true, true)
    end

    if self.nMaxCount == 1 or bNeedGray then
        UIHelper.SetNodeGray(self.SliderCount, true, true)
        UIHelper.SetNodeGray(self.Handle, true, true)
    end

    if bNeedGray then
        UIHelper.SetNodeGray(self.BtnConfirm, true, true)
        UIHelper.SetColor(self.BtnConfirm, cc.c3b(155, 155, 155))
        UIHelper.SetNodeGray(self.BtnBuy, true, true)
        UIHelper.SetColor(self.BtnBuy, cc.c3b(155, 155, 155))
    end

    if self.nDefaultNeedCount > 0 or self.nDefaultStepCount > 0 then
        UIHelper.SetSpriteFrame(self.ImgQuickBtnIcon, szDefaultButtonImgPath)
        UIHelper.SetString(self.LabelDefaultCount, tostring(self.nDefaultNeedCount))
        if self.nBuyCount >= self.nDefaultNeedCount then
            UIHelper.SetSpriteFrame(self.ImgQuickBtnIcon , szAddButtonImgPath)
            UIHelper.SetString(self.LabelDefaultCount, tostring(self.nDefaultStepCount))
        end
    end

    self:RefreshCurrencyLabel(tPrice, tOtherInfo, bMoneyNotEnough)

    UIHelper.CascadeDoLayoutDoWidget(self.LayoutCurrency, true, false)
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutBuyCount, true, false)
end

function UIItemTipQuantityController:RefreshCurrencyLabel(tPrice, tOtherInfo, bMoneyNotEnough)
    local player = GetClientPlayer()
    local nBrics,nGold,nSilver,nCopper = ItemData.GoldSilverAndCopperFromtMoney(tPrice)
    local currencys = {nBrics,nGold,nSilver,nCopper}
    local nMoneyIndex = 1
    local colorRed = cc.c3b(255, 133, 125)
    local colorWhite = cc.c3b(255, 255, 255)
    self.tCurrencyData = {}
    -- 先填充砖金银铜
    local nCurrencyCount = #self.tbWidgetCurrency
    for nCIndex = 1,nCurrencyCount do
        UIHelper.SetVisible(self.tbWidgetCurrency[nCIndex], false)
        UIHelper.SetTextColor(self.tbLabelCurrency[nCIndex], colorWhite)
        self.tCurrencyData[nCIndex] = CurrencyType.Money
    end
    for nCIndex,currencyNum in ipairs(currencys) do
        if currencyNum > 0 then
            UIHelper.SetSpriteFrame(self.tbImgCurrency[nMoneyIndex], ShopData.MoneyIndex2Tex[nCIndex])
            UIHelper.SetString(self.tbLabelCurrency[nMoneyIndex], tostring(currencyNum))
            UIHelper.SetVisible(self.tbWidgetCurrency[nMoneyIndex], true)
            if bMoneyNotEnough then
                UIHelper.SetTextColor(self.tbLabelCurrency[nMoneyIndex], colorRed)
            end
            nMoneyIndex = nMoneyIndex + 1
        end
    end
    if not tOtherInfo then
        return
    end


    for szCurrencyName, szCurrencyIndex in pairs(ShopData.OtherInfo2CurrencyType) do
        local nAmount = tOtherInfo[szCurrencyName]
        if nMoneyIndex <= nCurrencyCount and nAmount > 0 then
            local bNotEnough = CurrencyData.GetCurCurrencyCount(szCurrencyIndex) < nAmount
            local nCurrencyNum = nAmount * self.nBuyCount

            UIHelper.SetSpriteFrame(self.tbImgCurrency[nMoneyIndex], CurrencyData.tbImageSmallIcon[szCurrencyIndex])
            UIHelper.SetString(self.tbLabelCurrency[nMoneyIndex], tostring(nCurrencyNum))
            UIHelper.SetVisible(self.tbWidgetCurrency[nMoneyIndex], true)
            self.tCurrencyData[nMoneyIndex] = szCurrencyIndex
            if bNotEnough then
                UIHelper.SetTextColor(self.tbLabelCurrency[nMoneyIndex], colorRed)
            end
            nMoneyIndex = nMoneyIndex + 1
        end
    end

    if nMoneyIndex<=nCurrencyCount and tOtherInfo.dwTabType > 0 and tOtherInfo.dwIndex > 0 then
        local itemInfo = GetItemInfo(tOtherInfo.dwTabType, tOtherInfo.dwIndex)
        if itemInfo then
            local nIconID = Table_GetItemIconID(itemInfo.nUiId, false)
            if nIconID > 0 then
                local nRequireAmount = tOtherInfo.nRequireAmount*self.nBuyCount
                UIHelper.ClearTexture(self.tbImgCurrency[nMoneyIndex])
                UIHelper.SetItemIconByIconID(self.tbImgCurrency[nMoneyIndex], nIconID, false)
                UIHelper.SetString(self.tbLabelCurrency[nMoneyIndex], tostring(nRequireAmount))
                UIHelper.SetVisible(self.tbWidgetCurrency[nMoneyIndex], true)
                if player.GetItemAmount(tOtherInfo.dwTabType, tOtherInfo.dwIndex) < nRequireAmount then
                    UIHelper.SetTextColor(self.tbLabelCurrency[nMoneyIndex], colorRed)
                end
                self.tCurrencyData[nMoneyIndex] = tOtherInfo
                nMoneyIndex = nMoneyIndex + 1
            end
        end
    end
end

function UIItemTipQuantityController:RefreshProgressBarPercent()
    local totalSize = self.nMaxCount - self.nMinCount
    if totalSize == 0 then
        totalSize = self.nBuyCount - self.nMinCount
    end
    local percent = (self.nBuyCount- self.nMinCount)/totalSize*100
    UIHelper.SetProgressBarPercent(self.SliderCount, percent)
end

function UIItemTipQuantityController:GetMaxBuyLimit(tPrice, tOtherInfo)
    local player = GetClientPlayer()

    local tbMoney = ItemData.GetOriginalMoney()
    local tMoney = PackMoney(100000, 0, 0)
    if MoneyOptCmp(tbMoney, tMoney) > 0 then
        tbMoney = tMoney
    end

	local nMaxLimit = MoneyOptDivMoney(tbMoney, tPrice)

    if not tOtherInfo then
        return math.floor(nMaxLimit)
    end

    if tOtherInfo.nPrestige > 0 and player.nCurrentPrestige > tOtherInfo.nPrestige then
        nMaxLimit = math.min(nMaxLimit, player.nCurrentPrestige / tOtherInfo.nPrestige)
    end

    if tOtherInfo.nContribution > 0 and player.nContribution > tOtherInfo.nContribution then
        nMaxLimit = math.min(nMaxLimit, player.nContribution / tOtherInfo.nContribution)
    end

    local tTong = GetTongClient()
    local nCurrentFund = 0
    if tTong then
        nCurrentFund = tTong.GetFundTodayRemainCanUse()
    end
    if tOtherInfo.nTongFund > 0 and nCurrentFund > tOtherInfo.nTongFund then
        nMaxLimit = math.min(nMaxLimit, nCurrentFund / tOtherInfo.nTongFund)
    end

    if tOtherInfo.nJustice > 0 and player.nJustice > tOtherInfo.nJustice then
        nMaxLimit = math.min(nMaxLimit, player.nJustice / tOtherInfo.nJustice)
    end

    if tOtherInfo.nExamPrint > 0 and player.nExamPrint > tOtherInfo.nExamPrint then
        nMaxLimit = math.min(nMaxLimit, player.nExamPrint / tOtherInfo.nExamPrint)
    end

    if tOtherInfo.nArenaAward > 0 and player.nArenaAward > tOtherInfo.nArenaAward then
        nMaxLimit = math.min(nMaxLimit, player.nArenaAward / tOtherInfo.nArenaAward)
    end

    if tOtherInfo.nActivityAward > 0 and player.nActivityAward > tOtherInfo.nActivityAward then
        nMaxLimit = math.min(nMaxLimit, player.nActivityAward / tOtherInfo.nActivityAward)
    end

    if tOtherInfo.nMentorAward > 0 and player.nMentorAward > tOtherInfo.nMentorAward then
        nMaxLimit = math.min(nMaxLimit, player.nMentorAward / tOtherInfo.nMentorAward)
    end

    if tOtherInfo.nArchitecture > 0 and player.nArchitecture > tOtherInfo.nArchitecture then
        nMaxLimit = math.min(nMaxLimit, player.nArchitecture / tOtherInfo.nArchitecture)
    end

    if tOtherInfo.nCoin > 0 and player.nCoin > tOtherInfo.nCoin then
        nMaxLimit = math.min(nMaxLimit, player.nCoin / tOtherInfo.nCoin)
    end

    if tOtherInfo.dwTabType > 0 and tOtherInfo.dwIndex > 0 then
        local itemInfo = GetItemInfo(tOtherInfo.dwTabType, tOtherInfo.dwIndex)
        if itemInfo then
            local nRequireAmount = tOtherInfo.nRequireAmount*self.nBuyCount
            local nHasAmount = player.GetItemAmount(tOtherInfo.dwTabType, tOtherInfo.dwIndex)
            if nHasAmount > nRequireAmount then
                nMaxLimit = math.min(nMaxLimit, nHasAmount / nRequireAmount)
            end
        end
    end

    return math.floor(nMaxLimit)
end

function UIItemTipQuantityController:IsMoneyEnough()
    local tbMoney = ItemData.GetOriginalMoney()
    local bEnough = MoneyOptCmp(tbMoney, self.tPrice) > 0

    return bEnough
end

function UIItemTipQuantityController:SetWaitSell(bEnable, szDesc)
    if bEnable then
        UIHelper.SetVisible(self.LabelCount, false)
        UIHelper.SetString(self.LabelCountTittle, szDesc)
    else
        UIHelper.SetVisible(self.LabelCount, self.nMaxCount == 1)
        UIHelper.SetString(self.LabelCountTittle, "购买数量：")
    end
end

function UIItemTipQuantityController:SetPreviewBtn(bShow)
    UIHelper.SetVisible(self.WidgetBtns, bShow)
    UIHelper.SetVisible(self.BtnPreview, bShow)
    UIHelper.SetVisible(self.BtnConfirm, not bShow)
    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
end

function UIItemTipQuantityController:SetTouchDownHideTips(bHideTips)
    UIHelper.SetTouchDownHideTips(self.BtnConfirm, bHideTips)
    UIHelper.SetTouchDownHideTips(self.BtnBuy, bHideTips)
    UIHelper.SetTouchDownHideTips(self.BtnPreview, bHideTips)
    UIHelper.SetTouchDownHideTips(self.ButtonAddDefault, bHideTips)
    UIHelper.SetTouchDownHideTips(self.ButtonDecreaseDefault, bHideTips)
    UIHelper.SetTouchDownHideTips(self.SliderCountDefault, bHideTips)
    UIHelper.SetTouchDownHideTips(self.EditPaginateDefault, bHideTips)
end

return UIItemTipQuantityController