-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationShop
-- Date: 2026-03-26 14:42:32
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOperationShop = class("UIOperationShop")

local tCellCustomInfo = {
    tWidgetItemInfo = {PREFAB_ID.WidgetItem_100, "WidgetItem"}
}

function UIOperationShop:OnEnter(nOperationID, nID, tComponentContext)
    self.nOperationID = nOperationID
    self.nID = nID
    self.tComponentContext = tComponentContext
    self.scriptTop = self.tComponentContext and self.tComponentContext.tScriptLayoutTop and self.tComponentContext.tScriptLayoutTop[1]

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    OperationShopData.Init(self.nOperationID)

	self.tCustomData = CustomData.GetData(CustomDataType.Role, "ShopCustomData")
	if not self.tCustomData then
        self.tCustomData = {}
        CustomData.Register(CustomDataType.Role, "ShopCustomData", self.tCustomData)
    end

	Timer.AddFrameCycle(self, 1, function()
        self:AutoBuyGoods()
    end)
end

function UIOperationShop:OnExit()
    self.bInit = false
    self:UnRegEvent()

    OperationShopData.UnInit()
end

function UIOperationShop:BindUIEvent()
    UIHelper.TableView_addCellAtIndexCallback(self.scriptTop.TableViewContentGridList, function(tableView, nIndex, script, node, cell)
        -- if not script then
        --     return
        -- end
        -- local tInfos = {}
        -- for i = 1, self.nColumnCount do
        --     local nGoodsIndex = (nIndex-1) * self.nColumnCount + i
        --     table.insert(tInfos, self.aGoods[nGoodsIndex])
        -- end
        -- script:OnEnter(self.nNpcID, self.nShopID, self.dwPlayerRemoteDataID, tInfos, tCellCustomInfo)
        --  for i = 1, self.nColumnCount do
        --     local nGoodsIndex = (nIndex-1) * self.nColumnCount + i
        --     self.scriptGoodsMap[nGoodsIndex] = script.tScriptList[i]
        --     self.scriptGoodsMap[nGoodsIndex].nIndex = nGoodsIndex
        -- end
    end)
end

function UIOperationShop:RegEvent()
    Event.Reg(self, EventType.OnOperationShopDataUpdate, function ()
        self:UpdateInfo()
    end)

    Event.Reg(self, "SHOP_UPDATEITEM", function(nShopID, dwItemIndex, bAdd, nItemTemplateIndex)
        self:UpdateShopItem(nShopID, dwItemIndex, bAdd, nItemTemplateIndex)
    end)

    Event.Reg(self, EventType.OnShopGoodsSelectChanged, function(nCurGoodsIndex, bSelected, aShopInfo)
        if bSelected then
            self.aShopInfo = aShopInfo
            self.nCurGoodsIndex = nCurGoodsIndex
            self:UpdateSelectedGoodsDetails()
        end
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        self.scriptItemTip = nil
        self.scriptQuantityController = nil
        self.WidgetItemTipQuantityController = nil

        for _, script in pairs(self.scriptGoodsMap) do
            UIHelper.SetSelected(script.ToggleSelect, false, false)
        end
    end)

	Event.Reg(self, EventType.OnShopBuyGoodsSure, function(nBuyCount)
        self:ShowBuyGoodsConfirm(nBuyCount)
    end)
end

function UIOperationShop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIOperationShop:UpdateInfo()
    UIHelper.SetVisible(self.scriptTop.WidgetMiniTitle, false)
    if not self.scriptGoodsMap then
        self:InitGoodList()
    else
        self:UpdateGoodList()
    end
end

function UIOperationShop:InitGoodList()
    local tList = OperationShopData.GetGoodsList()
    local S = OperationShopData.GetShopState()

    self.scriptGoodsMap = {}
    self.nCurGoodsIndex = 1
    self.aGoods = tList
	self.nNpcID = S.m_nNpcID
    self.nShopID = S.m_nShopID
	self.nShopMode = S.m_shopMode
	self.dwPlayerRemoteDataID = S.m_dwPlayerRemoteDataID
    self.nColumnCount = 3

    UIHelper.HideAllChildren(self.scriptTop.WidgetScrollViewTopAnchore)
    -- UIHelper.SetVisible(self.scriptTop.TableViewMaskContentGridList, true)
    -- local parent = self.scriptTop.TableViewContentGridList
	-- UIHelper.SetVisible(parent, true)
    -- local nTotalCellCount = math.ceil(#self.aGoods/self.nColumnCount)
    -- UIHelper.TableView_init(parent, nTotalCellCount, PREFAB_ID.WidgetLayOutZhuiGanShopCell)
    -- UIHelper.TableView_reloadData(parent)
    -- Timer.AddFrame(self, 1, function()
    --     UIHelper.TableView_scrollToTop(parent)
    -- end)

    UIHelper.SetVisible(self.scriptTop.ScrollViewTopAnchoreContentList, true)
    local parent = self.scriptTop.ScrollViewTopAnchoreContentList
    local nPageSize = 3
    local nPageCount = math.ceil(#tList / nPageSize)
    for i = 1, nPageCount do
        local nFrame = i
        Timer.AddFrame(self, nFrame, function()
            for nIndex = nPageSize * (i - 1) + 1, nPageSize * i do
                if nIndex > #tList then
                    break
                end
                local tInfo = tList[nIndex]
                local script = UIHelper.AddPrefab(PREFAB_ID.WidgetStoreItem, parent, self.nNpcID, self.nShopID, self.dwPlayerRemoteDataID, tInfo, nil, nil, tCellCustomInfo)
                script.nIndex = nIndex
                self.scriptGoodsMap[nIndex] = script
            end
            UIHelper.ScrollViewDoLayoutAndToTop(parent)
        end)
    end
end

function UIOperationShop:UpdateGoodList()
    for _, script in pairs(self.scriptGoodsMap) do
        script:OnEnter(self.nNpcID, self.nShopID, self.dwPlayerRemoteDataID, script.tbGoods, nil, nil, tCellCustomInfo)
    end
    --self:UpdateSelectedGoodsDetails()
end

function UIOperationShop:UpdateShopItem(nShopID, dwItemIndex, bAdd, nItemTemplateIndex)
    if nShopID ~= self.nShopID or not g_pClientPlayer then
        return
    end
    for _, script in pairs(self.scriptGoodsMap) do
        if script.tbGoods.dwShopIndex == dwItemIndex then
            script:OnEnter(self.nNpcID, self.nShopID, self.dwPlayerRemoteDataID, script.tbGoods, nil, nil, tCellCustomInfo)
            break
        end
    end
    --self:UpdateSelectedGoodsDetails()
end

function UIOperationShop:UpdateSelectedGoodsDetails()
    if self.scriptItemTip then
        return
    end
	local hItem,bItem
    if self.nCurGoodsIndex and self.nCurGoodsIndex > 0 then
		local scriptGoods = self.scriptGoodsMap[self.nCurGoodsIndex]
		local goods = self.aGoods[self.nCurGoodsIndex]
        hItem, bItem = ShopData.GetItemByGoods(goods)
		local bCanShow = type(goods.nShopID) ~= "number" or self.nShopID == goods.nShopID
        if bItem and bCanShow then
            local _, scriptItemTip = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, self.scriptTop._rootNode, TipsLayoutDir.LEFT_CENTER)
            self.scriptItemTip = scriptItemTip
			self.scriptItemTip:SetShopInfo(nil)
			self.scriptItemTip:SetExpireTime(nil)
			self.scriptItemTip:SetShopTips(nil)
			--self.scriptItemTip:IsPlayStore(true)
			self.scriptItemTip:SetPlayerID(PlayerData.GetPlayerID())
			self.scriptQuantityController = self.scriptQuantityController or UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipQuantityController, self.scriptItemTip.LayoutContentAll)
			self.WidgetItemTipQuantityController = self.scriptQuantityController._rootNode

			self.scriptItemTip.szBindSource = "shop"
			self.scriptItemTip:HidePreviewBtn(true)
			self.scriptItemTip:SetPlayAniEnabled(false)
			-- UIHelper.SetAnchorPoint(self.scriptItemTip._rootNode, 0.5, 1)
			-- UIHelper.SetPosition(self.scriptItemTip._rootNode, 0, 0)
			-- UIHelper.SetVisible(self.WidgetSellItem, false)
			UIHelper.SetVisible(self.WidgetItemTipQuantityController, true)

			local tbShopItemInfo = GetShopItemInfo(goods.nShopID, goods.dwShopIndex)
			self.scriptItemTip:SetBeginSellTime(0)
			local bWaitSell = tbShopItemInfo and tbShopItemInfo.nBeginSellTime > os.time()
			if bWaitSell then
				self.scriptItemTip:SetBeginSellTime(tbShopItemInfo.nBeginSellTime)
			end

			if scriptGoods and scriptGoods.tbGoods.dwShopIndex == goods.dwShopIndex then
				--scriptGoods:OnEnter(self.nNpcID, self.nShopID, self.dwPlayerRemoteDataID, goods)
				if scriptGoods.aShopInfo then
					local szTip = ShopData.GetShopTip("", scriptGoods.aShopInfo, hItem, false)
					if szTip and self.scriptItemTip then
						self.scriptItemTip:SetShopTips(szTip)
						self.scriptItemTip:SetShopInfo(scriptGoods.aShopInfo)
					end
				end
			end

			if hItem.nGenre == ITEM_GENRE.BOOK then
				self.scriptItemTip:SetBookID(goods.nDurability)
			end
			if type(goods.nShopID) == 'number' then
				if bItem then
					self.scriptItemTip:OnInitWithItemID(hItem.dwID)
				else
					self.scriptItemTip:OnInitWithTabID(goods.nItemType, goods.nItemIndex)
				end
			elseif goods.nShopID == 'BUY_BACK' then
				self.scriptItemTip:OnInit(INVENTORY_INDEX.SOLD_LIST, goods.dwShopIndex)
			elseif goods.nShopID == 'BUY_BACK_ADVANCED' then
				self.scriptItemTip:OnInit(INVENTORY_INDEX.TIME_LIMIT_SOLD_LIST, goods.dwShopIndex)
			end
			self.scriptItemTip:SetBtnState({})
			if self.scriptItemTip.scriptItemIcon then
				self.scriptItemTip.scriptItemIcon:ShowEquipScoreArrow(true)
			end

			if self.scriptQuantityController then
				local _, nMaxCount, _ = ShopDataBase.CanMultiBuy(goods)
				local tPrice = ShopData.GetGoodsPrice(self.nNpcID, self.nShopID, goods)
				local tData = {
					nNpcID = self.nNpcID,
					nShopID = self.nShopID,
					nNeedCount = goods.nNeedCount,
					nMaxCount = nMaxCount,
					tPrice = tPrice,
					bCanStack = hItem.bCanStack,
					tbGoods = goods,
					aShopInfo = scriptGoods.aShopInfo,
				}
			 	self.scriptQuantityController:OnEnter(tData)
				local bCanPreview = OutFitPreviewData.CanPreview(goods.nItemType, goods.nItemIndex)
				self.scriptQuantityController:SetPreviewBtn(bCanPreview)
				self.scriptQuantityController:SetWaitSell(bWaitSell, "敬请期待")
				self.scriptQuantityController:SetTouchDownHideTips(false)
			end

            self:RefreshItemTipsScrollViewHeight()
        end
    end
end

function UIOperationShop:RefreshItemTipsScrollViewHeight()
	local nScrollViewContentWidgetTop = UIHelper.GetHeight(self.scriptItemTip.WidgetAnchorTop)
	local nLayoutContentSpaceY = UIHelper.LayoutGetSpacingY(self.scriptItemTip.LayoutContentAll)

	local nChildenCount = UIHelper.GetVisableChildrenCount(self.scriptItemTip.LayoutContentAll)
	local nDeltaHeight = UIHelper.GetHeight(self.scriptTop._rootNode) - nScrollViewContentWidgetTop - nLayoutContentSpaceY*nChildenCount

	if self.WidgetItemTipQuantityController and UIHelper.GetVisible(self.WidgetItemTipQuantityController) then
		nDeltaHeight = nDeltaHeight - UIHelper.GetHeight(self.WidgetItemTipQuantityController)
	end
	if self.WidgetSellItem and UIHelper.GetVisible(self.WidgetSellItem) then
		-- nDeltaHeight = nDeltaHeight - UIHelper.GetHeight(self.WidgetSellItem)
		if self.scriptWidgetSellItem and self.scriptWidgetSellItem.nMaxCount == 1 then
			nDeltaHeight = nDeltaHeight - 188
		else
			nDeltaHeight = nDeltaHeight - 204
		end
	end
	self.scriptItemTip:UpdateScrollViewHeight(nDeltaHeight)
end

function UIOperationShop:ShowBuyGoodsConfirm(nBuyCount)
    local goods = self.aGoods[self.nCurGoodsIndex]
    if goods and self.nShopMode == 'SHOP' then
        local bRemind = ItemData.IsPriceNeedRemind(self.nNpcID, goods.nShopID, goods.dwShopIndex, nBuyCount)
        local item = ShopData.GetItemByGoods(goods)
        if item and not self.tCustomData.bHideCanReturnTips and goods.bCanReturn then
            local scriptConfirm = UIHelper.ShowConfirm(g_tStrings.Shop.STR_CAN_RETURN_ITEM_BUY_CONFIRM, function(bOptionChecked)
                self.tCustomData.bHideCanReturnTips = bOptionChecked
                self:BuyGoods(nBuyCount)
            end)
            scriptConfirm:ShowTogOption(g_tStrings.Shop.STR_CAN_RETURN_ITEM_CHECK_BOX, false)
        elseif item and (item.nQuality >= 3 or bRemind) then
            local bNeedGray, _ = ShopData.CheckNeedGray(self.nNpcID, self.nShopID, goods, nBuyCount)
            UIMgr.Open(VIEW_ID.PanelPlayStoreConfirm, self.nNpcID, self.nShopID, self.dwPlayerRemoteDataID, goods, bNeedGray, nBuyCount, bRemind, function()
                self:BuyGoods(nBuyCount)
            end)
        else
            self:BuyGoods(nBuyCount)
        end
    else
        self:BuyGoods(nBuyCount)
    end
end

function UIOperationShop:IsOwnedEquipGoods(goods)
    local player = GetClientPlayer()
    if not player or not goods then
        return false
    end
     local item = ShopDataBase.GetItemByGoods(goods)
    if not item or not ItemData.IsItemCanBeEquip(item.nGenre, item.nSub) then
        return false
    end

    local dwTabType = item.dwTabType or goods.nItemType
    local dwIndex   = item.dwIndex or goods.nItemIndex
    if not dwTabType or not dwIndex then
        return false
    end

    return player.GetItemAmountInAllPackages(dwTabType, dwIndex) > 0
end

function UIOperationShop:BuyGoods(nBuyCount)
    local goods = self.aGoods[self.nCurGoodsIndex]
    if not goods then
        return
    end
    if self:IsOwnedEquipGoods(goods) then
        UIHelper.ShowConfirm(g_tStrings.STR_OPERATION_BUY_EQUIP_CONFIRM, function ()
            self:RealBuyGoods(nBuyCount)
        end)
    else
        self:RealBuyGoods(nBuyCount)
    end
end

function UIOperationShop:RealBuyGoods(nBuyCount)
    OnCheckAddAchievement(996, "Shop_Frist_Buy")

    if not self.nCurGoodsIndex or self.nCurGoodsIndex <= 0 then
        return
    end

    local goods = self.aGoods[self.nCurGoodsIndex]
    if self.nShopMode == 'SHOP' then
        local item, bItem = ShopData.GetItemByGoods(goods)
        if (item and item.nGenre ~= ITEM_GENRE.TASK_ITEM or
                (item.nGenre == ITEM_GENRE.TASK_ITEM and item.nAucGenre == AUC_GENRE.DESERT))
                and BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.SHOP, "buy") then
            return
        end

        if self.tBuyParams then
            TipsHelper.ShowNormalTip("网络异常，请稍后再试")
            return
        end

        if ShopData.InBuyCD() then
            TipsHelper.ShowNormalTip("购买操作太频繁，请稍后再试")
            return
        end

        local nRetCode = CanMultiBuyItem(self.nNpcID, goods.nShopID, goods.dwShopIndex, nBuyCount)
        if nRetCode ~= SHOP_SYSTEM_RESPOND_CODE.BUY_SUCCESS then
            local szMsg = g_tStrings.g_ShopStrings[nRetCode]
            if szMsg then
                OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
            else
                OutputMessage("MSG_ANNOUNCE_NORMAL", "购买条件不满足")
            end
            return
        end

        local _, nMaxCount, nDefaultCount = ShopDataBase.CanMultiBuy(goods)
        if nBuyCount > nMaxCount then
            return
        end
        self.tBuyParams = {
            nBuyCount = nBuyCount,
            nDefaultCount = nDefaultCount,
            nNpcID = self.nNpcID,
            nShopID = self.nShopID,
            dwShopIndex = goods.dwShopIndex,
        }
        goods.nNeedCount = nil
    elseif self.nShopMode == 'BUY_BACK' then
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.SHOP, "回购") then
            return
        end

        self.dwRequestSoldBox, self.dwRequestSoldIndex = INVENTORY_INDEX.SOLD_LIST, goods.dwShopIndex
        BuySoldListItem(self.nNpcID, self.nShopID, goods.dwShopIndex)
    elseif self.nShopMode == 'BUY_BACK_ADVANCED' then
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.SHOP, "高级回购") then
            return
        end

        self.dwRequestSoldBox, self.dwRequestSoldIndex = INVENTORY_INDEX.TIME_LIMIT_SOLD_LIST, goods.dwShopIndex
        BuyTimeLimitSoldListItem(self.nNpcID, self.nShopID, goods.dwShopIndex)
    end
end

function UIOperationShop:AutoBuyGoods()
    local bInBuyCD = ShopData.InBuyCD()
    if bInBuyCD then
        return
    end
    if not self.tBuyParams then
        return
    end

    if self.tBuyParams.nBuyCount > self.tBuyParams.nDefaultCount then
        self.tBuyParams.nBuyCount = self.tBuyParams.nBuyCount - self.tBuyParams.nDefaultCount
        ShopData.BuyItem(self.tBuyParams.nNpcID, self.tBuyParams.nShopID, self.tBuyParams.dwShopIndex, self.tBuyParams.nDefaultCount)
    elseif self.tBuyParams.nBuyCount > 0 then
        ShopData.BuyItem(self.tBuyParams.nNpcID, self.tBuyParams.nShopID, self.tBuyParams.dwShopIndex, self.tBuyParams.nBuyCount)
        self.tBuyParams = nil
    else
        self.tBuyParams = nil
    end
end


return UIOperationShop