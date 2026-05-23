

local UIPlayStoreCell = class("UIPlayStoreCell")


function UIPlayStoreCell:OnEnter(nNpcID, nShopID, dwPlayerRemoteDataID, tbGoods, bNeedGray, nBuyCount, tCustomInfo)
    if not tbGoods then
        return
    end
    self:InitDefaultState()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbMoneyScripts = {}
    self.tbCurrencyScripts = {}

    for _, node in ipairs(self.tbMoneyWidgets) do
        table.insert(self.tbMoneyScripts, UIHelper.GetBindScript(node))
    end
    for _, node in ipairs(self.tbCurrencyWidgets) do
        table.insert(self.tbCurrencyScripts, UIHelper.GetBindScript(node))
    end

    self.tCustomInfo = tCustomInfo
    self:UpdateInfo(nNpcID, nShopID, dwPlayerRemoteDataID, tbGoods, bNeedGray, nBuyCount)
end

function UIPlayStoreCell:OnExit()
    self.bInit = false
end

function UIPlayStoreCell:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnSelectChanged, function (_, bSelected)
        if self.bForbidCallBack then return end
        Event.Dispatch(EventType.OnShopGoodsSelectChanged, self.nIndex, bSelected, self.aShopInfo)
    end)

    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnTouchBegan, function(btn, nX, nY)
        UIHelper.SetMultiTouch(self.ToggleSelect, true)
    end)

    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnTouchEnded, function(btn, nX, nY)
        UIHelper.SetMultiTouch(self.ToggleSelect, false)
        UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
    end)

    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnTouchCanceled, function(btn, nX, nY)
        UIHelper.SetMultiTouch(self.ToggleSelect, false)
        UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
    end)
end

function UIPlayStoreCell:RegEvent()
    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        Timer.AddFrame(self, 1, function ()
            self:ResizeRedline()
        end)
        Timer.AddFrame(self, 2, function ()
            self:ResizeRedline()
        end)
    end)

    Event.Reg(self, EventType.OnUpdateCustomizedSetList, function()
        self:UpdateCell()
    end)
end

function UIPlayStoreCell:InitDefaultState()
    UIHelper.SetString(self.LabelItemName, "商品加载中...")
    UIHelper.SetString(self.LabelItemNameShort, "商品加载中...")

    UIHelper.SetVisible(self.WidgetLimit1, false)
    UIHelper.SetVisible(self.WidgetLimit2, false)
    UIHelper.SetVisible(self.WidgetLimit3, false)

    UIHelper.SetVisible(self.WidgetTime, false)
    local nCurrencyCount = #self.tbMoneyWidgets
    for nCIndex = 1,nCurrencyCount do
        UIHelper.SetVisible(self.tbMoneyWidgets[nCIndex], false)
        UIHelper.SetVisible(self.tbCurrencyWidgets[nCIndex], false)
    end

    self.WidgetItem:removeAllChildren()
    UIHelper.SetVisible(self.WidgetCanBuy, false)

    UIHelper.SetVisible(self.WidgetRecommendState, false)
end

function UIPlayStoreCell:UpdateCell(bNeedGray)
    self:UpdateInfo(self.nNpcID, self.nShopID, self.dwPlayerRemoteDataID, self.tbGoods, bNeedGray)
end

function UIPlayStoreCell:UpdateInfo(nNpcID, nShopID, dwPlayerRemoteDataID, tbGoods, bNeedGray, nBuyCount)
    if not nNpcID then
        return
    end
    local tShopInfo = GetShop(nShopID)
	if not tShopInfo then
		return
	end
    self.nNpcID = nNpcID
    self.nShopID = nShopID
    self.tbGoods = tbGoods
    self.dwPlayerRemoteDataID = dwPlayerRemoteDataID
    self.nBuyCount = nBuyCount or 1
    local bIsBigIcon = self._nPrefabID ~= PREFAB_ID.WidgetPlayStoreCell
    local player = GetClientPlayer()
    local bNeedGray,_ = ShopData.CheckNeedGray(nNpcID, nShopID, tbGoods, 1)
    if tbGoods then
        local item,bItem = ShopData.GetItemByGoods(tbGoods)
		if not bItem or not item then
			return
		end
        self.Item = item
        local tbShopItemInfo
        UIHelper.SetVisible(self.WidgetTime, false)
        if type(tbGoods.nShopID) == "number" then
            tbShopItemInfo = GetShopItemInfo(tbGoods.nShopID, tbGoods.dwShopIndex)
            if tbShopItemInfo and tbShopItemInfo.nBeginSellTime > 0 then
                if tbShopItemInfo.nBeginSellTime > os.time() then
                    UIHelper.SetVisible(self.WidgetTime, true)
                    bNeedGray = true
                end
            end
        end

        -- 数量堆叠
        local nStackCount = -1
        local nLimitCount = -1
        local nGobalLimitCount = -1
        local nPlayerBuyCount = -1
        local nPlayerLeftCount = -1
        local bNeedShowStackCount = true
        self.bBackBackAdvanced = tbGoods.nShopID == 'BUY_BACK_ADVANCED'
        if tbGoods.nShopID == 'BUY_BACK' or tbGoods.nShopID == 'BUY_BACK_ADVANCED' then
            if item.bCanStack then
                nStackCount = item.nStackNum
            end
        else
            -- 限量
            nGobalLimitCount = GetShopItemCount(tbGoods.nShopID, tbGoods.dwShopIndex) --全服限量
            self.bGlobalLimit = nGobalLimitCount >= 0
            nLimitCount = nGobalLimitCount
            if tbShopItemInfo.nPlayerRemoteDataPos >= 0 then
				nPlayerBuyCount = player.GetRemoteArrayUInt(self.dwPlayerRemoteDataID, tbShopItemInfo.nPlayerRemoteDataPos, tbShopItemInfo.nPlayerRemoteDataLength)
				nPlayerLeftCount = tbShopItemInfo.nPlayerBuyLimit - nPlayerBuyCount
				if nGobalLimitCount >= 0 and nPlayerLeftCount then --钟琰需求：商店限量和个人限购同时存在时，道具左下角显示商店限量，个人限购通过购买报错来提示玩家。
					nLimitCount = nGobalLimitCount
				else
					nLimitCount = nPlayerLeftCount
				end
				self.bPlayerLimit = true
			end

            -- 堆叠
            if item.bCanStack then
                if bItem and nStackCount < 0 then
                    if tbGoods.bCustomShop then
                        nStackCount = tbShopItemInfo.nDurability
                    else
                        nStackCount = item.nCurrentDurability
                    end
                end
                nStackCount = nStackCount or 1
                if item.nGenre == ITEM_GENRE.BOOK or nStackCount < 0 then
                    bNeedShowStackCount = false
                end
            end
        end
        -- 价格
        local tPrice = ShopData.GetGoodsPrice(self.nNpcID, self.nShopID, tbGoods)
        local tOrgPrice = tbShopItemInfo and tbShopItemInfo.tOriginalPrice
        if nStackCount > 0 and type(tbGoods.nShopID) == "number" then
            nStackCount = self.nBuyCount * nStackCount
            tPrice = MoneyOptMult(tPrice, nStackCount)
            if tOrgPrice then
                tOrgPrice = MoneyOptMult(tOrgPrice, nStackCount)
            end
        end

        -- 能不能购买
        local bReputeLimit = false
        if tbShopItemInfo and item and bItem then
            local bReputeLimit = false
            local nReputeLevel = GetShopItemReputeLevel(self.tbGoods.nShopID, self.tbGoods.dwShopIndex)
            local dwForceID = tShopInfo.dwRequireForceID
            if self.nNpcID > 0 then
                local npc = GetNpc(self.nNpcID)
                dwForceID = npc.dwForceID
            end

            local nPlayerReputeLevel = player.GetReputeLevel(dwForceID)
            if nPlayerReputeLevel < nReputeLevel then
                bReputeLimit = true
            end
            self.aShopInfo = {
                bSatisfy            = not bReputeLimit  ,
                dwNeedLevel         = nReputeLevel      ,
                dwNeedForce         = dwForceID         ,
                dwPlayerReputeLevel = nPlayerReputeLevel,
                bLimit              = self.bGlobalLimit ,
                bCustomLimit 		= tbShopItemInfo.nLimit ~= -1 and tbGoods.bCustomShop,
                nGobalLimitCount  	= nGobalLimitCount,
                nBuyCount           = tbShopItemInfo.nLimit - nGobalLimitCount,
                nGlobalLimt         = tbShopItemInfo.nLimit,
                nPlayerLimit        = tbShopItemInfo.nPlayerBuyLimit,
                nPlayerBuyCount     = nPlayerBuyCount,
                nPlayerLeftCount    = nPlayerLeftCount,
                nFameID             = tbGoods.nFameID,
                bNeedFame           = tbGoods.bNeedFame,
                bFameSatisfy        = tbGoods.bFameSatisfy,
                nFameNeedLevel      = tbGoods.nFameNeedLevel,
            }
            self:GenerateShopInfo(tbShopItemInfo, nStackCount)
        end

        UIHelper.SetVisible(self.LabelCount, false)
        if bNeedShowStackCount and nStackCount > 1 then
            UIHelper.SetVisible(self.LabelCount, true)
            UIHelper.SetString(self.LabelCount, tostring(nStackCount))
        end

        local otherInfo
        self.bEquipSet = false
        local bShop = type(tbGoods.nShopID) == "number"
        if bShop then
            otherInfo = GetShopItemBuyOtherInfo(tbGoods.nShopID, tbGoods.dwShopIndex)
            if otherInfo and otherInfo.dwTabType and otherInfo.dwTabType ~= 0 and otherInfo.dwIndex ~= 0 then
                local tCostItemInfo = GetItemInfo(otherInfo.dwTabType, otherInfo.dwIndex)
                self.bEquipSet = tCostItemInfo and tCostItemInfo.nGenre == ITEM_GENRE.MATERIAL and tCostItemInfo.nSub == MATERIAL_SUB_TYPE.SET
            end
        end
        self:RefreshCurrencyLabel(tPrice, tOrgPrice, otherInfo, nStackCount)

        if self.itemScript then
            self.WidgetItem:removeAllChildren()
            self.itemScript = nil
        end
        local nItemPrefabID = PREFAB_ID.WidgetItem_100
        local parentItem = self.WidgetItem
        local tCustomWidgetItem = self.tCustomInfo and self.tCustomInfo.tWidgetItemInfo or nil
        if tCustomWidgetItem then
            nItemPrefabID = tCustomWidgetItem[1] or nItemPrefabID
            parentItem = self[tCustomWidgetItem[2]] or self.WidgetItem
        end
        self.itemScript = self.itemScript or UIHelper.AddPrefab(nItemPrefabID, parentItem)
        UIHelper.SetNodeSwallowTouches(self.itemScript._rootNode, false, true)
        self.itemScript:SetSelectEnable(false)
        self.itemScript:ShowEquipScoreArrow(true)

        self.itemScript:SetClickCallback(function(nItemType, nItemIndex)
            if self.bBackBackAdvanced then
                TipsHelper.ShowItemTips(self.itemScript._rootNode, INVENTORY_INDEX.TIME_LIMIT_SOLD_LIST, tbGoods.dwShopIndex, true)
            elseif nItemType and nItemIndex then
                TipsHelper.ShowItemTips(self.itemScript._rootNode, nItemType, nItemIndex, false)
            else
                TipsHelper.DeleteAllHoverTips()
            end
        end)

        if self.ImgBlack then
            UIHelper.SetVisible(self.ImgBlack, bNeedGray) -- 不能购买时显示黑色遮罩 ActivityItem专属逻辑
        else
            if bNeedGray then
                UIHelper.SetColor(self.itemScript.ImgIcon, cc.c3b(64, 64, 64))
            else
                UIHelper.SetColor(self.itemScript.ImgIcon, cc.c3b(255, 255, 255))
            end
        end

        if bIsBigIcon and not tCustomWidgetItem then
            local szImgPath = Table_GetItemLargeIconPathByItemUiId(self.Item.nUiId)
            self.itemScript:ShowClearIcon(szImgPath)
            UIHelper.SetScale(self.itemScript._rootNode, 1.6, 1.6)
        else
            self.itemScript:OnInitWithTabID(tbGoods.nItemType, tbGoods.nItemIndex)
        end

        -- 限购标签
        local aShopInfo = self.aShopInfo
        if aShopInfo then
            UIHelper.SetString(self.LabelLimitCount1, aShopInfo.nGlobalLimt - aShopInfo.nBuyCount)
            UIHelper.SetString(self.LabelLimitCount2, aShopInfo.nGobalLimitCount)
            UIHelper.SetString(self.LabelLimitCount3, aShopInfo.nPlayerLimit - aShopInfo.nPlayerBuyCount)
        end
        local bGlobalLimit = aShopInfo and not aShopInfo.bCustomLimit and aShopInfo.nGlobalLimt > 0
        local bShopLimit = aShopInfo and aShopInfo.bCustomLimit and aShopInfo.nGobalLimitCount > 0
        local bPlayerLimit = aShopInfo and aShopInfo.nPlayerBuyCount >= 0
        local bNoLimit = not bGlobalLimit and not bShopLimit and not bPlayerLimit
        UIHelper.SetVisible(self.WidgetLimit1, bGlobalLimit)
        UIHelper.SetVisible(self.WidgetLimit2, bShopLimit)
        UIHelper.SetVisible(self.WidgetLimit3, bPlayerLimit)
        UIHelper.SetVisible(self.LayoutLimit, not bNoLimit)
        UIHelper.SetVisible(self.LabelItemName, bNoLimit)
        UIHelper.SetVisible(self.LabelItemNameShort, not bNoLimit)

        -- 匹配心法
        local dwMainKungfuID = player.GetActualKungfuMountID()
        dwMainKungfuID = TabHelper.GetHDKungfuID(dwMainKungfuID) or dwMainKungfuID
        local bNeedGray, bMoneyNotEnough, _ = ShopData.CheckNeedGray(self.nNpcID, self.nShopID, self.tbGoods, 1)
        UIHelper.SetVisible(self.ImgXinFa, tbGoods.tKungfuMatchMap and tbGoods.tKungfuMatchMap[dwMainKungfuID])
        UIHelper.SetVisible(self.ImgTongYong, tbGoods.tKungfuMatchMap and tbGoods.tKungfuMatchMap[0])
        UIHelper.SetVisible(self.ImgCanBuy, bShop and self.bEquipSet and not bNeedGray) -- 仅兑换牌显示可购买标识
        UIHelper.SetVisible(self.WidgetCanBuy, true)
        -- 名字
        local szName = ShopData.GetItemNameByGoods(tbGoods)
        szName = UIHelper.GBKToUTF8(szName)
        szName = bIsBigIcon and UIHelper.LimitUtf8Len(szName, 6) or szName
        UIHelper.SetStringAutoClamp(self.LabelItemName, szName)
        UIHelper.SetStringAutoClamp(self.LabelItemNameShort, szName)

        local nDiamondR, nDiamondG, nDiamondB = GetItemFontColorByQuality(item.nQuality)
        UIHelper.SetTextColor(self.LabelItemName, cc.c3b(nDiamondR, nDiamondG, nDiamondB))
        UIHelper.SetTextColor(self.LabelItemNameShort, cc.c3b(nDiamondR, nDiamondG, nDiamondB))

        if self.ImgQualityBg and item.nQuality and ShopData.FullScreenQualityBg[item.nQuality] then
            UIHelper.SetSpriteFrame(self.ImgQualityBg, ShopData.FullScreenQualityBg[item.nQuality])
        end

        -- 是否推荐装备
        local bRecommend, szRecommendTitle = EquipCodeData.CheckIsRoleRecommendEquip(item.dwTabType, item.dwIndex)
        UIHelper.SetVisible(self.WidgetRecommendState, bRecommend)
        UIHelper.SetString(self.LabelRecommendTitle, szRecommendTitle)
        UIHelper.LayoutDoLayout(self.WidgetRecommendState)
    end

    -- 倒计时
    self:RefreshBuyBackItemLeftTime()
    UIHelper.SetPositionY(self.LayoutContent, 0)
    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
end

function UIPlayStoreCell:RefreshCurrencyLabel(tPrice, tOrgPrice, tOtherInfo, nStackCount)
    self.nOrgPriceCount = nil
    UIHelper.SetVisible(self.ImgRedLine, false)
    if not tOrgPrice then
        self:RefreshPriceOnly(tPrice, tOtherInfo, nStackCount)
    else
        self:RefreshOrgPrice(tPrice, tOrgPrice, tOtherInfo, nStackCount)
    end
end

function UIPlayStoreCell:RefreshPriceOnly(tPrice, tOtherInfo, nStackCount)
    local player = GetClientPlayer()
    local colorRed = cc.c3b(255, 133, 125)
    local colorWhite = cc.c3b(255, 255, 255)
    if not nStackCount or nStackCount <= 0 or type(self.tbGoods.nShopID) ~= "number" then
        nStackCount = 1
    end

    local bNeedGray, bMoneyNotEnough, _ = ShopData.CheckNeedGray(self.nNpcID, self.nShopID, self.tbGoods, nStackCount)
    local nBrics,nGold,nSilver,nCopper = ItemData.GoldSilverAndCopperFromtMoney(tPrice)
    local currencys = {nBrics,nGold,nSilver,nCopper}
    local nMoneyIndex = 1
    -- 先填充砖金银铜
    local nCurrencyCount = #self.tbMoneyWidgets
    for nCIndex = 1,nCurrencyCount do
        UIHelper.SetVisible(self.tbMoneyWidgets[nCIndex], false)
        UIHelper.SetTextColor(self.tbMoneyScripts[nCIndex].LabelMoney, colorWhite)
        UIHelper.SetVisible(self.tbCurrencyWidgets[nCIndex], false)
        UIHelper.SetTextColor(self.tbCurrencyScripts[nCIndex].LabelMoney, colorWhite)
    end
    for nCIndex,currencyNum in ipairs(currencys) do
        if currencyNum > 0 or (nCIndex == nCurrencyCount and MoneyOptCmp(tPrice, 0) == 0) then
            local script = self.tbMoneyScripts[nMoneyIndex]
            if script then
                UIHelper.SetSpriteFrame(script.ImgMoney, ShopData.MoneyIndex2Tex[nCIndex])
                UIHelper.SetString(script.LabelMoney, tostring(currencyNum))
                UIHelper.SetVisible(script._rootNode, true)
                if bMoneyNotEnough then
                    UIHelper.SetTextColor(script.LabelMoney, colorRed)
                end
            else
                --LOG.WARN("")
            end

            nMoneyIndex = nMoneyIndex + 1
        end
    end

    UIHelper.SetVisible(self.LayoutMoney, nMoneyIndex >= 2)

    local fnShowCurrency = function(nIndex, nCurrencyType ,nCurrencyNum, bNotEnough)
        local script = self.tbCurrencyScripts[nIndex]
        UIHelper.SetSpriteFrame(script.ImgMoney, ShopData.CurrencyCode2Tex[nCurrencyType])
        UIHelper.SetString(script.LabelMoney, tostring(nCurrencyNum))
        UIHelper.SetVisible(script._rootNode, true)
        if bNotEnough then
            UIHelper.SetTextColor(script.LabelMoney, colorRed)
        end
    end

    if tOtherInfo then
        -- 填充其他货币
        nMoneyIndex = 1

        for szCurrencyName, szCurrencyIndex in pairs(ShopData.OtherInfo2CurrencyType) do
            local nAmount = tOtherInfo[szCurrencyName]
            if nMoneyIndex <= nCurrencyCount and nAmount > 0 then
                local bNotEnough = CurrencyData.GetCurCurrencyCount(szCurrencyIndex) < nAmount
                local nCurrencyNum = nAmount * nStackCount

                local script = self.tbCurrencyScripts[nMoneyIndex]
                UIHelper.SetSpriteFrame(script.ImgMoney, CurrencyData.tbImageSmallIcon[szCurrencyIndex])
                UIHelper.SetString(script.LabelMoney, tostring(nCurrencyNum))
                UIHelper.SetVisible(script._rootNode, true)
                if bNotEnough then
                    UIHelper.SetTextColor(script.LabelMoney, colorRed)
                end

                nMoneyIndex = nMoneyIndex + 1
            end
        end

        if nMoneyIndex<=nCurrencyCount and tOtherInfo.dwTabType > 0 then
            local itemInfo = GetItemInfo(tOtherInfo.dwTabType, tOtherInfo.dwIndex)
            if itemInfo then
                local nIconID = Table_GetItemIconID(itemInfo.nUiId)
                if nIconID > 0 then
                    local nRequireAmount = tOtherInfo.nRequireAmount*nStackCount

                    local script = self.tbCurrencyScripts[nMoneyIndex]
                    UIHelper.ClearTexture(script.ImgMoney)
                    UIHelper.SetItemIconByIconID(script.ImgMoney, nIconID, false)
                    UIHelper.SetString(script.LabelMoney, tostring(nRequireAmount))
                    UIHelper.SetVisible(script._rootNode, true)
                    local nHasAmount = player.GetItemAmount(tOtherInfo.dwTabType, tOtherInfo.dwIndex)
                    if nHasAmount < nRequireAmount then
                        UIHelper.SetTextColor(script.LabelMoney, colorRed)
                    end

                    -- 兑换牌需要显示数量成H/N
                    if itemInfo.nGenre == ITEM_GENRE.MATERIAL and itemInfo.nSub == MATERIAL_SUB_TYPE.SET then
                        UIHelper.SetString(script.LabelMoney, string.format("%d/%d", nHasAmount, nRequireAmount))
                    end
                    nMoneyIndex = nMoneyIndex + 1
                end
            end
        end

        UIHelper.SetVisible(self.LayoutCurrency, nMoneyIndex >= 2)
    end

    for nCIndex = 1,nCurrencyCount do
        UIHelper.LayoutDoLayout(self.tbCurrencyWidgets[nCIndex])
    end

    UIHelper.SetPositionY(self.LayoutContent, 0)
    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
end

function UIPlayStoreCell:RefreshOrgPrice(tPrice, tOrgPrice, tOtherInfo, nStackCount)
    local colorRed = cc.c3b(255, 133, 125)
    local colorWhite = cc.c3b(255, 255, 255)
    if not nStackCount or nStackCount <= 0 or type(self.tbGoods.nShopID) ~= "number" then
        nStackCount = 1
    end

    local bNeedGray, bMoneyNotEnough, _ = ShopData.CheckNeedGray(self.nNpcID, self.nShopID, self.tbGoods, nStackCount)
    local nBrics,nGold,nSilver,nCopper = ItemData.GoldSilverAndCopperFromtMoney(tPrice)
    local nOrgBrics,nOrgGold,nOrgSilver,nOrgCopper = ItemData.GoldSilverAndCopperFromtMoney(tOrgPrice)
    local currencys = {nBrics,nGold,nSilver,nCopper}
    local orgCurrencys = {nOrgBrics,nOrgGold,nOrgSilver,nOrgCopper}
    local nMoneyIndex = 1
    local nOrgPriceCount = 0
    -- 先填原价
    local nCurrencyCount = #self.tbMoneyWidgets
    for nCIndex = 1,nCurrencyCount do
        UIHelper.SetVisible(self.tbMoneyWidgets[nCIndex], false)
        UIHelper.SetTextColor(self.tbMoneyScripts[nCIndex].LabelMoney, colorWhite)
        UIHelper.SetVisible(self.tbCurrencyWidgets[nCIndex], false)
        UIHelper.SetTextColor(self.tbCurrencyScripts[nCIndex].LabelMoney, colorWhite)
    end

    for nCIndex,currencyNum in ipairs(orgCurrencys) do
        if currencyNum > 0 or (nCIndex == nCurrencyCount and  MoneyOptCmp(tPrice, 0) == 0) then
            local script = self.tbMoneyScripts[nMoneyIndex]
            UIHelper.SetSpriteFrame(script.ImgMoney, ShopData.MoneyIndex2Tex[nCIndex])
            UIHelper.SetString(script.LabelMoney, tostring(currencyNum))
            UIHelper.SetVisible(script._rootNode, true)
            if bMoneyNotEnough then
                UIHelper.SetTextColor(script.LabelMoney, colorRed)
            end
            nMoneyIndex = nMoneyIndex + 1
            nOrgPriceCount = nOrgPriceCount + 1
        end
    end

    UIHelper.SetVisible(self.LayoutMoney, nMoneyIndex >= 2)

    -- 再填现价
    nMoneyIndex = 1
    local nCurrencyCount = #self.tbCurrencyWidgets
    for nCIndex,currencyNum in ipairs(currencys) do
        if currencyNum > 0 or (nCIndex == nCurrencyCount and  MoneyOptCmp(tPrice, 0) == 0) then
            local script = self.tbCurrencyScripts[nMoneyIndex]
            UIHelper.SetSpriteFrame(script.ImgMoney, ShopData.MoneyIndex2Tex[nCIndex])
            UIHelper.SetString(script.LabelMoney, tostring(currencyNum))
            UIHelper.SetVisible(script._rootNode, true)
            if bMoneyNotEnough then
                UIHelper.SetTextColor(script.LabelMoney, colorRed)
            end

            nMoneyIndex = nMoneyIndex + 1
        end
    end

    UIHelper.SetVisible(self.LayoutCurrency, nMoneyIndex >= 2)
    for nCIndex = 1, nCurrencyCount do
        UIHelper.LayoutDoLayout(self.tbMoneyWidgets[nCIndex])
        UIHelper.LayoutDoLayout(self.tbCurrencyWidgets[nCIndex])
    end

    UIHelper.SetPositionY(self.LayoutContent, 0)
    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)

    self.nOrgPriceCount = nOrgPriceCount
    Timer.AddFrame(self, 1, function ()
        self:ResizeRedline()
    end)
    Timer.AddFrame(self, 2, function ()
        self:ResizeRedline()
    end)
end

function UIPlayStoreCell:ResizeRedline()
    if not self.nOrgPriceCount then return end

    local nRedlineWith = UIHelper.GetWidth(UIHelper.GetParent(self.tbMoneyWidgets[1]))
    local nMinPosX = UIHelper.GetWorldPositionX(self.LayoutContent)
    UIHelper.SetVisible(self.ImgRedLine, true)
    UIHelper.SetWidth(self.ImgRedLine, nRedlineWith)
    --UIHelper.SetWorldPosition(self.ImgRedLine, nMinPosX, UIHelper.GetWorldPositionY(self.tbMoneyWidgets[1]))
end

function UIPlayStoreCell:GenerateShopInfo(tbShopItemInfo, nStackCount)
    local bSatisfy = true
    local player = GetClientPlayer()
    if not self.aShopInfo then
        self.aShopInfo = {}
    end
    local nRequireAchievementRecord = nStackCount * tbShopItemInfo.nRequireAchievementRecord
    if nRequireAchievementRecord and nRequireAchievementRecord > 0 then
        self.aShopInfo.nRequireAchievementRecord = nRequireAchievementRecord
        self.aShopInfo.bSatisfyAchievementRecord = nRequireAchievementRecord <= player.GetAchievementRecord()
        bSatisfy = bSatisfy and self.aShopInfo.bSatisfyAchievementRecord
    end
    local nCampTitle = tbShopItemInfo.nRequireTitle
    if nCampTitle and nCampTitle > 0 then
		self.aShopInfo.nCampTitle = nCampTitle
		self.aShopInfo.bSatisfyCampTitle = nCampTitle <= player.nTitle
        bSatisfy = bSatisfy and self.aShopInfo.bSatisfyCampTitle
    end
    local nRequireCorpsValue = tbShopItemInfo.nRequireCorpsValue
    local dwMaskCorpsNeedToCheck = tbShopItemInfo.dwMaskCorpsNeedToCheck
    if nRequireCorpsValue and nRequireCorpsValue > 0 then
		self.aShopInfo.nRequireCorpsValue = nRequireCorpsValue
		self.aShopInfo.dwMaskCorpsNeedToCheck = dwMaskCorpsNeedToCheck
		self.aShopInfo.bSatisfyCorpsValue = false

		local dwMask = dwMaskCorpsNeedToCheck % (2 ^ ARENA_UI_TYPE.ARENA_END)
		for i = ARENA_UI_TYPE.ARENA_END - 1, ARENA_UI_TYPE.ARENA_BEGIN, -1 do
			if dwMask >= 2 ^ i then
				local nCorpsLevel = player.GetCorpsLevel(i)
				local nCorpsRoleLevel = player.GetCorpsRoleLevel(i)
				if nRequireCorpsValue <= nCorpsLevel and nRequireCorpsValue <= nCorpsRoleLevel then
					self.aShopInfo.bSatisfyCorpsValue = true
					break
				end
				dwMask = dwMask - 2 ^ i;
			end
		end
        bSatisfy = bSatisfy and self.aShopInfo.bSatisfyCorpsValue
    end
    local nRequireArenaLevel = tbShopItemInfo.nRequireArenaLevel
    if nRequireArenaLevel and nRequireArenaLevel > 0 then
		local level  = nRequireArenaLevel
		self.aShopInfo.nRequireArenaLevel = level
		if player.nArenaLevel2v2 >= level or player.nArenaLevel3v3 >= level or player.nArenaLevel5v5 >= level then
			self.aShopInfo.bSatisfyArenaLevel = true
		end
        bSatisfy = bSatisfy and self.aShopInfo.bSatisfyArenaLevel
	end
    local nRequireArenaLevelExcept2v2 = tbShopItemInfo.nRequireArenaLevelExcept2v2
    if nRequireArenaLevelExcept2v2 and nRequireArenaLevelExcept2v2 > 0 then
		local level  = nRequireArenaLevelExcept2v2
		self.aShopInfo.nRequireArenaLevelExcept2v2 = level
		if player.nArenaLevel3v3 >= level or player.nArenaLevel5v5 >= level then
			self.aShopInfo.bSatisfyArenaLevelE2v2 = true
		end
        bSatisfy = bSatisfy and self.aShopInfo.bSatisfyArenaLevelE2v2
	end
    local nBeginSellTime = tbShopItemInfo.nBeginSellTime
    if nBeginSellTime and nBeginSellTime > 0 then
        self.aShopInfo.nBeginSellTime = nBeginSellTime
    end
    return bSatisfy
end

function UIPlayStoreCell:RefreshBuyBackItemLeftTime()
    if not self.bBackBackAdvanced then
        return
    end
    local player = GetClientPlayer()
    if not player then
        return
    end
    local nLeftTime = player.GetTimeLimitSoldListInfoLeftTime(self.Item.dwID)
    UIHelper.SetVisible(self.WidgetTime, nLeftTime > 0)
    if nLeftTime <= 0 then
        return
    end

    self.nBuyBackItemTimeLimitTimerID = self.nBuyBackItemTimeLimitTimerID or Timer.AddCountDown(self, nLeftTime+1, function ()
        self:RefreshBuyBackItemLeftTime()
    end, function ()
        self.nBuyBackItemTimeLimitTimerID = nil
        local nPrice = GetShopItemSellPrice(self.nShopID, self.nBox, self.nIndex)
        local tPrice = FormatMoneyTab(nPrice)
        local tbShopItemInfo = GetShopItemInfo(self.nShopID, self.tbGoods.dwShopIndex)
        local tOrgPrice = tbShopItemInfo and tbShopItemInfo.tOriginalPrice
        self:RefreshCurrencyLabel(tPrice, tOrgPrice)
    end)

    local szLeftTime = UIHelper.GetHeightestCeilTimeText(nLeftTime, false)
    szLeftTime = FormatString(g_tStrings.STR_SHOP_TIME, szLeftTime)
    UIHelper.SetString(self.LabelTime, szLeftTime)
    UIHelper.SetFontSize(self.LabelTime, 20)
    UIHelper.HideAllChildren(self.WidgetTime)
    UIHelper.SetVisible(self.LabelTime, true)

end

function UIPlayStoreCell:SetForbidCallBack(bForbidCallBack)
    self.bForbidCallBack = bForbidCallBack
end

return UIPlayStoreCell