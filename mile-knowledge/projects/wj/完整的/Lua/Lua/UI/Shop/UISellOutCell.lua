

local UISellOutCell = class("UISellOutCell")


function UISellOutCell:OnEnter(nNpcID, nShopID, nBox, nIndex)
    if not nNpcID then
        return
    end
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if self.nReturnItemTimeLimitTimerID then
        Timer.DelTimer(self, self.nReturnItemTimeLimitTimerID)
        self.nReturnItemTimeLimitTimerID = nil
    end
    UIHelper.SetVisible(self.WidgetRecommendState, false)
    self:UpdateInfo(nNpcID, nShopID, nBox, nIndex)
end

function UISellOutCell:OnExit()
    self.bInit = false
end

function UISellOutCell:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnSelectChanged, function (_, bSelected)
        self.fCallBack(self.Item.dwID, bSelected)
    end)
end

function UISellOutCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UISellOutCell:UpdateInfo(nNpcID, nShopID, nBox, nIndex)
    local item = ItemData.GetItemByPos(nBox, nIndex)
    if not item then
        return
    end
    self.nNpcID = nNpcID
    self.nShopID = nShopID
    self.nBox = nBox
    self.nIndex = nIndex
    self.Item = item
    -- 名字
    local szItemName = ItemData.GetItemNameByItem(item)
    szItemName = UIHelper.GBKToUTF8(szItemName)
    UIHelper.SetStringAutoClamp(self.LabelItemName, szItemName)
    local nDiamondR, nDiamondG, nDiamondB = GetItemFontColorByQuality(item.nQuality)
    UIHelper.SetTextColor(self.LabelItemName, cc.c3b(nDiamondR, nDiamondG, nDiamondB))

    -- 是否推荐装备
    local bRecommend, szRecommendTitle = EquipCodeData.CheckIsRoleRecommendEquip(item.dwTabType, item.dwIndex)        
    UIHelper.SetVisible(self.WidgetRecommendState, bRecommend)
    UIHelper.SetString(self.LabelRecommendTitle, szRecommendTitle)
    UIHelper.LayoutDoLayout(self.WidgetRecommendState)
    
    -- 图标
    if self.itemScript then
        self.WidgetItem:removeAllChildren()
        self.itemScript = nil
    end
    self.itemScript = self.itemScript or UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.WidgetItem)
    self.itemScript:OnInit(nBox, nIndex)
    UIHelper.SetNodeSwallowTouches(self.itemScript._rootNode, false, true)
    UIHelper.SetVisible(self.itemScript.WidgetSelectBG, false)
    -- 价格
    local nPrice = GetShopItemSellPrice(nShopID, nBox, nIndex)
    local tPrice = FormatMoneyTab(nPrice)
    local tbShopInfo = GetReturnItemShopInfo(nShopID, nBox, nIndex)
    local nStackCount = 1
    if item.bCanStack then
        nStackCount = item.nStackNum
    end
    if ItemData.IsCanTimeReturnItem(self.Item) and tbShopInfo then
        tPrice = tbShopInfo.tPrice
        self:RefreshCurrencyLabel(tPrice, tbShopInfo, nStackCount)
    else
        self:RefreshCurrencyLabel(tPrice)
    end
    -- 数量
    UIHelper.SetString(self.LabelCount, tostring(item.nStackNum))
    -- 倒计时
    self:RefreshReturnItemLeftTime()
end

function UISellOutCell:RefreshCurrencyLabel(tPrice, tOtherInfo, nStackCount)
    local player = GetClientPlayer()
    local nBrics,nGold,nSilver,nCopper = ItemData.GoldSilverAndCopperFromtMoney(tPrice)
    local currencys = {nBrics,nGold,nSilver,nCopper}
    local nMoneyIndex = 1
    if not nStackCount or nStackCount <= 0 then
        nStackCount = 1
    end
    -- 先填充砖金银铜
    local nCurrencyCount = #self.tbWidgetMoney
    for nCIndex = 1,nCurrencyCount do
        UIHelper.SetVisible(self.tbWidgetMoney[nCIndex], false)
        UIHelper.SetVisible(self.tbWidgetCurrency[nCIndex], false)
    end
    for nCIndex,currencyNum in ipairs(currencys) do
        if currencyNum > 0 or nCIndex == nCurrencyCount and MoneyOptCmp(tPrice, 0) == 0 then
            UIHelper.SetSpriteFrame(self.tbImgMoney[nMoneyIndex], ShopData.MoneyIndex2Tex[nCIndex])
            UIHelper.SetString(self.tbLabelMoney[nMoneyIndex], tostring(currencyNum))
            if currencyNum<=99999 then
                UIHelper.SetFontSize(self.tbLabelMoney[nMoneyIndex], 26)
            else
                UIHelper.SetFontSize(self.tbLabelMoney[nMoneyIndex], 20)
            end
            UIHelper.SetVisible(self.tbWidgetMoney[nMoneyIndex], true)
            nMoneyIndex = nMoneyIndex + 1
        end
    end

    UIHelper.SetVisible(self.LayoutMoney, nMoneyIndex >= 0)
    -- 填充其他货币
    if tOtherInfo then
        nMoneyIndex = 1
        nCurrencyCount = #self.tbWidgetCurrency
        local UpdateWidgetCurrency = function (nNeedValue, szImgPath)
            if nMoneyIndex<=nCurrencyCount and nNeedValue > 0 then
                UIHelper.SetSpriteFrame(self.tbImgCurrency[nMoneyIndex], szImgPath)
                UIHelper.SetString(self.tbLabelCurrency[nMoneyIndex], tostring(nNeedValue*nStackCount))
                if nNeedValue*nStackCount<=99999 then
                    UIHelper.SetFontSize(self.tbLabelCurrency[nMoneyIndex], 26)
                else
                    UIHelper.SetFontSize(self.tbLabelCurrency[nMoneyIndex], 20)
                end
                UIHelper.SetVisible(self.tbWidgetCurrency[nMoneyIndex], true)
                nMoneyIndex = nMoneyIndex + 1
            end
        end
        for szCurrencyName, szCurrencyIndex in pairs(ShopData.OtherInfo2CurrencyType) do
            local nNeedVal = tOtherInfo[szCurrencyName]
            if nNeedVal then
                UpdateWidgetCurrency(nNeedVal, CurrencyData.tbImageSmallIcon[szCurrencyIndex])
            end
        end

        if nMoneyIndex<=nCurrencyCount and tOtherInfo.dwTabType > 0 then
            local itemInfo = GetItemInfo(tOtherInfo.dwTabType, tOtherInfo.dwIndex)
            if itemInfo then
                local nIconID = Table_GetItemIconID(itemInfo.nUiId)
                if nIconID > 0 then
                    UIHelper.SetItemIconByIconID(self.tbImgCurrency[nMoneyIndex], nIconID)
                    local nRequireAmount = tOtherInfo.nRequireAmount*nStackCount
                    UIHelper.SetString(self.tbLabelCurrency[nMoneyIndex], tostring(nRequireAmount))
                    if nRequireAmount<=99999 then
                        UIHelper.SetFontSize(self.tbLabelCurrency[nMoneyIndex], 26)
                    else
                        UIHelper.SetFontSize(self.tbLabelCurrency[nMoneyIndex], 20)
                    end
                    UIHelper.SetVisible(self.tbWidgetCurrency[nMoneyIndex], true)
                    nMoneyIndex = nMoneyIndex + 1
                end
            end
        end
        UIHelper.SetVisible(self.LayoutCurrency, nMoneyIndex >= 0)
    end

    for nCIndex = 1,nCurrencyCount do
        UIHelper.LayoutDoLayout(self.tbWidgetCurrency[nCIndex])
    end
    UIHelper.LayoutDoLayout(self.LayoutCurrency)
end

function UISellOutCell:RefreshReturnItemLeftTime()
    local nLeftTime = ItemData.GetReturnItemLeftTime(self.Item)
    UIHelper.SetVisible(self.WidgetTime, nLeftTime > 0)
    if nLeftTime <= 1 then
        if not self.bDispatchEvent then
            self.bDispatchEvent = true
            Event.Dispatch(EventType.OnBuyBackItemTimeOut)
        end
    end
    if nLeftTime <= 0 then
        return
    end

    self.nReturnItemTimeLimitTimerID = self.nReturnItemTimeLimitTimerID or Timer.AddCountDown(self, nLeftTime+1, function ()
        self:RefreshReturnItemLeftTime()
    end, function ()
        self.nReturnItemTimeLimitTimerID = nil
        local nPrice = GetShopItemSellPrice(self.nShopID, self.nBox, self.nIndex)
        local tPrice = FormatMoneyTab(nPrice)
        self:RefreshCurrencyLabel(tPrice)
    end)

    local szLeftTime = UIHelper.GetDeltaTimeShortText(nLeftTime, false)
    UIHelper.SetString(self.LabelReturnItemTime, szLeftTime)
end

function UISellOutCell:SetSelectChangeCallback(fCallBack)
    self.fCallBack = fCallBack
end

return UISellOutCell