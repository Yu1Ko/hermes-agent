local UIPlayStoreSellItem = class("UIPlayStoreSellItem")


function UIPlayStoreSellItem:OnEnter(nNpcID, nShopID, nBox, nIndex, nDefaultSellCount)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nSellCount = nDefaultSellCount
    self.nImgSize = UIHelper.GetWidth(self.ImgSliderBg)
    UIHelper.SetTouchDownHideTips(self.BtnConfirm, false)
    UIHelper.SetTouchDownHideTips(self.ButtonAdd, false)
    UIHelper.SetTouchDownHideTips(self.ButtonDecrease, false)
    UIHelper.SetTouchDownHideTips(self.SliderCount, false)
    UIHelper.SetTouchDownHideTips(self.ImgEditBg, false)
    UIHelper.SetTouchDownHideTips(self.EditBoxPaginate, false)
    self:UpdateInfo(nNpcID, nShopID, nBox, nIndex)    
end

function UIPlayStoreSellItem:OnExit()
    self.bInit = false
end

function UIPlayStoreSellItem:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        self.fSelectedCallBack(self.nSellCount or 1)
    end)

    UIHelper.BindUIEvent(self.ButtonAdd, EventType.OnClick, function()
        self:TryAddSellCount()
    end)

    UIHelper.BindUIEvent(self.ButtonDecrease, EventType.OnClick, function()
        self:TrySubSellCount()
    end)

    UIHelper.RegisterEditBoxEnded(self.EditBoxPaginate, function ()
        self:OnEditBoxChanged()
    end)

    UIHelper.BindUIEvent(self.SliderCount, EventType.OnChangeSliderPercent, function(SliderEventType, nSliderEvent)
        if nSliderEvent == ccui.SliderEventType.slideBallDown then
            self.bSliding = true
        elseif nSliderEvent == ccui.SliderEventType.slideBallUp then
            self.bSliding = false
            -- 强制修正滑块进度
            self:RefreshSellCount(false)
        end

        if self.bSliding then
            local percent = UIHelper.GetProgressBarPercent(self.SliderCount) / 100
            self.nSellCount = math.ceil(percent * self.nMaxCount)
            if self.nSellCount <= self.nMinCount then
                self.nSellCount = 1
            elseif self.nSellCount >= self.nMaxCount then
                self.nSellCount = self.nMaxCount
            end
            UIHelper.SetWidth(self.ImgSliderFg, self.nSellCount * self.nImgSize / self.nMaxCount)
            self:RefreshSellCount(true)
        end
    end)
end

function UIPlayStoreSellItem:RegEvent()
    Event.Reg(self, EventType.OnGameNumKeyboardOpen, function(editbox)
        if editbox ~= self.EditBoxPaginate then return end
        UIHelper.SetEditBoxGameKeyboardRange(self.EditBoxPaginate, self.nMinCount, self.nMaxCount)
    end)

    Event.Reg(self, EventType.OnGameNumKeyboardChanged, function(editbox, num)
        if editbox ~= self.EditBoxPaginate then return end

        self:OnEditBoxChanged()
    end)
end

function UIPlayStoreSellItem:UpdateInfo(nNpcID, nShopID, nBox, nIndex)
    local item = ItemData.GetItemByPos(nBox, nIndex)
    if not item then
        return
    end
    self.nMaxCount = 1
    self.nMinCount = 1
    if item.bCanStack and item.nStackNum and item.nStackNum > 0 then
        self.nMaxCount = item.nStackNum
    end
    if not self.nSellCount then
        self.nSellCount = self.nMaxCount
    elseif self.nSellCount > self.nMaxCount then
        self.nSellCount = self.nMaxCount
    elseif self.nSellCount < self.nMinCount then
        self.nSellCount = self.nMinCount
    end    
    local nPrice = GetShopItemSellPrice(nShopID, nBox, nIndex)
    local tPrice = MoneyOptDiv(nPrice, self.nMaxCount)

    local tbShopInfo = GetReturnItemShopInfo(nShopID, nBox, nIndex)

    if ItemData.IsCanTimeReturnItem(item) then
        tPrice = tbShopInfo.tPrice
        self:RefreshCurrencyLabel(tPrice, tbShopInfo)
    else
        self:RefreshCurrencyLabel(tPrice)
    end
    self.tPrice = tPrice
    self.tbShopInfo = tbShopInfo
    self:RefreshSellCount()
end

function UIPlayStoreSellItem:RefreshCurrencyLabel(tPrice, tOtherInfo)
    local player = GetClientPlayer()
    local nBrics,nGold,nSilver,nCopper = ItemData.GoldSilverAndCopperFromtMoney(tPrice)
    local currencys = {nBrics,nGold,nSilver,nCopper}
    local nMoneyIndex = 1
    -- 先填充砖金银铜
    local nCurrencyCount = #self.tbWidgetCurrency
    for nCIndex = 1,nCurrencyCount do
        UIHelper.SetVisible(self.tbWidgetCurrency[nCIndex], false)
    end
    local bLimitGold = BubbleMsgData.GetGoldLimitState()
    if bLimitGold then
        UIHelper.SetSpriteFrame(self.tbImgCurrency[nMoneyIndex], ShopData.MoneyIndex2Tex[nCurrencyCount])
        UIHelper.SetString(self.tbLabelCurrency[nMoneyIndex], "（风控）" .. tostring(0))
        UIHelper.SetVisible(self.tbWidgetCurrency[nMoneyIndex], true)
        nMoneyIndex = nMoneyIndex + 1
    else
        for nCIndex, currencyNum in ipairs(currencys) do
            if currencyNum > 0 or (nCIndex == nCurrencyCount and MoneyOptCmp(tPrice, 0) == 0) then
                UIHelper.SetSpriteFrame(self.tbImgCurrency[nMoneyIndex], ShopData.MoneyIndex2Tex[nCIndex])
                UIHelper.SetString(self.tbLabelCurrency[nMoneyIndex], tostring(currencyNum))
                UIHelper.SetVisible(self.tbWidgetCurrency[nMoneyIndex], true)
                nMoneyIndex = nMoneyIndex + 1
            end
        end
    end
    if not tOtherInfo then
        UIHelper.CascadeDoLayoutDoWidget(self.LayoutCurrency, true, true)
        return
    end

    for szCurrencyName, szCurrencyIndex in pairs(ShopData.OtherInfo2CurrencyType) do
        local nSellVal = tOtherInfo[szCurrencyName]
        if nMoneyIndex<=nCurrencyCount and nSellVal > 0 then
            UIHelper.SetSpriteFrame(self.tbImgCurrency[nMoneyIndex], CurrencyData.tbImageSmallIcon[szCurrencyIndex])
            UIHelper.SetString(self.tbLabelCurrency[nMoneyIndex], tostring(nSellVal))
            UIHelper.SetVisible(self.tbWidgetCurrency[nMoneyIndex], true)
            nMoneyIndex = nMoneyIndex + 1
        end
    end

    if nMoneyIndex<=nCurrencyCount and tOtherInfo.dwTabType > 0 and tOtherInfo.dwIndex > 0 then
        local itemInfo = GetItemInfo(tOtherInfo.dwTabType, tOtherInfo.dwIndex)
        if itemInfo then
            local nIconID = Table_GetItemIconID(itemInfo.nUiId, false)
            if nIconID > 0 then
                local nRequireAmount = tOtherInfo.nRequireAmount
                UIHelper.SetItemIconByIconID(self.tbImgCurrency[nMoneyIndex], nIconID)
                UIHelper.SetString(self.tbLabelCurrency[nMoneyIndex], tostring(nRequireAmount))
                UIHelper.SetVisible(self.tbWidgetCurrency[nMoneyIndex], true)
                nMoneyIndex = nMoneyIndex + 1
            end
        end
    end
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutCurrency, true, true)
end

function UIPlayStoreSellItem:RefreshSellCount(NoRefreshProgressBar)
    local bCanEdit = self.nMaxCount ~= self.nMinCount
    UIHelper.SetVisible(self.WidgetEdit, bCanEdit)
    UIHelper.SetVisible(self.WidgetSlider, bCanEdit)
    UIHelper.SetVisible(self.LabelCount, not bCanEdit)
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutSellCount, true, true)

    if not NoRefreshProgressBar then
        -- local totalSize = self.nMaxCount - self.nMinCount
        -- if totalSize == 0 then
        --     totalSize = self.nSellCount - self.nMinCount
        -- end
        local nCurCount = self.nSellCount- self.nMinCount
        local percent = self.nSellCount/self.nMaxCount*100
        UIHelper.SetProgressBarPercent(self.SliderCount, percent)
        UIHelper.SetWidth(self.ImgSliderFg, percent * self.nImgSize / 100)
    end

    local szSellCount = tostring(self.nSellCount)
    UIHelper.SetString(self.LabelCount, szSellCount)
    UIHelper.SetText(self.EditBoxPaginate, szSellCount)

    UIHelper.SetButtonState(self.ButtonAdd, BTN_STATE.Normal)
    UIHelper.SetButtonState(self.ButtonDecrease, BTN_STATE.Normal)
    if self.nSellCount >= self.nMaxCount then UIHelper.SetButtonState(self.ButtonAdd, BTN_STATE.Disable, "已达到最大可出售上限") end
    if self.nSellCount <= self.nMinCount then UIHelper.SetButtonState(self.ButtonDecrease, BTN_STATE.Disable, "已达到最小可出售上限") end

    local tPrice = MoneyOptMult(self.tPrice, self.nSellCount)
    self:RefreshCurrencyLabel(tPrice, self.tbShopInfo)
end

function UIPlayStoreSellItem:TryAddSellCount()
    if self.nSellCount + 1 > self.nMaxCount then return end

    self.nSellCount = self.nSellCount + 1
    self:RefreshSellCount()
end

function UIPlayStoreSellItem:TrySubSellCount()
    if self.nSellCount - 1 < self.nMinCount then return end
    
    self.nSellCount = self.nSellCount - 1
    self:RefreshSellCount()
end

function UIPlayStoreSellItem:IsMoneyEnough()
    local tbMoney = ItemData.GetOriginalMoney()
    local bEnough = MoneyOptCmp(tbMoney, self.tPrice) > 0

    return bEnough
end

function UIPlayStoreSellItem:SetSelectChangeCallback(fCallBack)
    self.fSelectedCallBack = fCallBack
end

function UIPlayStoreSellItem:OnEditBoxChanged()
    local szCount = UIHelper.GetText(self.EditBoxPaginate)
    local nInput = tonumber(szCount) or 1
    nInput = math.min(nInput, self.nMaxCount)
    nInput = math.max(nInput, 1)
    self.nSellCount = nInput or self.nMaxCount
    
    UIHelper.SetText(self.EditBoxPaginate, tostring(self.nSellCount))

    self:RefreshSellCount()
end

return UIPlayStoreSellItem