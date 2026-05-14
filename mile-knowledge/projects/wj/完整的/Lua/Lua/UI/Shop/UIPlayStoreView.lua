

local UIPlayStoreView = class("UIPlayStoreView")

local ITEM_MAX_MULTIPLE = 10
local MAX_BOOK_NUM = 20
local MAX_SHOP_QUERY_ITEM_COUNT = 32 -- 商店每次同步商品的数量

-- 当前模式(买/卖)，条件筛选后的商品列表，关键字筛选后的商品列表，整个商店的商品列表，通过dwShopIndex索引的商品列表 ，关键字过滤，筛选项，选中的商品
-- self.nShopMode, self.aGoods, self.aFilterGoods, self.aAllGoods, self.aSearchByShopIndexGoods , self.szFilter, self.tGoodsSelected

local SELECTOR_SORTER = {   -- 枚举类筛选项排序规则
	['KungfuSelector'] = {
		[10014] = 1 , [10015] = 2 , -- [FORCE_TYPE.CHUN_YANG]
		[10026] = 3 , [10062] = 4 , -- [FORCE_TYPE.TIAN_CE]
		[10021] = 5 , [10028] = 6 , -- [FORCE_TYPE.WAN_HUA]
		[10080] = 7 , [10081] = 7 , -- [FORCE_TYPE.QI_XIU]
		[10002] = 9 , [10003] = 8 , -- [FORCE_TYPE.SHAO_LIN]
		[10144] = 11, [10145] = 9 , -- [FORCE_TYPE.CANG_JIAN]
		[10175] = 13, [10176] = 10, -- [FORCE_TYPE.WU_DU]
		[10224] = 15, [10225] = 11, -- [FORCE_TYPE.TANG_MEN]
		[10242] = 17, [10243] = 12, -- [FORCE_TYPE.MING_JIAO]
		[10268] = 19,               -- [FORCE_TYPE.GAI_BANG]
		[10389] = 20, [10390] = 21, -- [FORCE_TYPE.CANG_YUN]
	},
	['EquipPosSelector'] = {
		[EQUIPMENT_SUB.CHEST]        = 1 , -- "上衣",
		[EQUIPMENT_SUB.PANTS]        = 2 , -- "下装",
		[EQUIPMENT_SUB.HELM]         = 3 , -- "帽子",
		[EQUIPMENT_SUB.WAIST]        = 4 , -- "腰带",
		[EQUIPMENT_SUB.BANGLE]       = 5 , -- "护腕",
		[EQUIPMENT_SUB.BOOTS]        = 6 , -- "鞋子",
		[EQUIPMENT_SUB.AMULET]       = 7 , -- "项链",
		[EQUIPMENT_SUB.RING]         = 8 , -- "戒指",
		[EQUIPMENT_SUB.PENDANT]      = 9 , -- "腰坠",
		[EQUIPMENT_SUB.MELEE_WEAPON] = 10, -- "近身武器",
		[EQUIPMENT_SUB.RANGE_WEAPON] = 11, -- "远程武器",
		-- [EQUIPMENT_SUB.WAIST_EXTEND] = , -- "腰部挂件",
		-- [EQUIPMENT_SUB.PACKAGE]      = , -- "包裹",
		-- [EQUIPMENT_SUB.ARROW]        = , -- "暗器",
		-- [EQUIPMENT_SUB.BACK_EXTEND]  = , -- "背部挂件",
		-- [EQUIPMENT_SUB.HORSE]        = , -- "坐骑",
		-- [EQUIPMENT_SUB.BULLET]       = , -- "唐门千机",
		-- [EQUIPMENT_SUB.FACE_EXTEND]  = , -- "面部挂件",
		-- [EQUIPMENT_SUB.MINI_AVATAR]  = , -- "头像",
		-- [EQUIPMENT_SUB.PET]          = , -- "宠物",
	},
	['QualitySelector'] = {
		1,2,3,4,5,6
	},
	["SchoolSelector"] = function(a, b)
		return a.value < b.value
	end
}
local GOODS_SORTER = {
	['EquipPosSelector'] = {
		[EQUIPMENT_SUB.MELEE_WEAPON] = 0 , -- "近身武器",
		[EQUIPMENT_SUB.RANGE_WEAPON] = 1 , -- "远程武器",
		[EQUIPMENT_SUB.CHEST]        = 2 , -- "上衣",
		[EQUIPMENT_SUB.HELM]         = 3 , -- "帽子",
		[EQUIPMENT_SUB.PANTS]        = 4 , -- "下装",
		[EQUIPMENT_SUB.WAIST]        = 5 , -- "腰带",
		[EQUIPMENT_SUB.BOOTS]        = 6 , -- "鞋子",
		[EQUIPMENT_SUB.BANGLE]       = 7 , -- "护腕",
		[EQUIPMENT_SUB.PENDANT]      = 8 , -- "腰坠",
		[EQUIPMENT_SUB.RING]         = 9 , -- "戒指",
		[EQUIPMENT_SUB.AMULET]       = 10, -- "项链",
		-- [EQUIPMENT_SUB.WAIST_EXTEND] = , -- "腰部挂件",
		-- [EQUIPMENT_SUB.PACKAGE]      = , -- "包裹",
		-- [EQUIPMENT_SUB.ARROW]        = , -- "暗器",
		-- [EQUIPMENT_SUB.BACK_EXTEND]  = , -- "背部挂件",
		-- [EQUIPMENT_SUB.HORSE]        = , -- "坐骑",
		-- [EQUIPMENT_SUB.BULLET]       = , -- "唐门千机",
		-- [EQUIPMENT_SUB.FACE_EXTEND]  = , -- "面部挂件",
		-- [EQUIPMENT_SUB.MINI_AVATAR]  = , -- "头像",
		-- [EQUIPMENT_SUB.PET]          = , -- "宠物",
	},
}
local SELECTOR_TITLE = {
	['SchoolSelector']       	= g_tStrings.Shop.STR_GUILD_SCHOOL,  -- 门派过滤器
	['KungfuSelector']      	= g_tStrings.Shop.STR_SKILL_NG,      -- 心法过滤器
	['EquipPosSelector']    	= g_tStrings.Shop.STR_EQUIP_POS,     -- 部位过滤器
	['AttriSelector']       	= g_tStrings.Shop.STR_EQUIP_ATTR,    -- 属性过滤器
	['RequireLevelSelector']	= g_tStrings.Shop.STR_GUILD_LEVEL,   -- 等级过滤器
	['LevelSelector']       	= FormatString(g_tStrings.Shop.STR_ITEM_H_ITEM_LEVEL, ''), -- 品质过滤器
	['QualitySelector']     	= g_tStrings.Shop.BOOK_QUALITY,      -- 品级过滤器
	['ScoreSelector']       	= FormatString(g_tStrings.Shop.STR_ITEM_H_ITEM_SCORE, ''), -- 装备分过滤器
	['SkillSelector']       	= g_tStrings.Shop.STR_SKILL,         -- 技能过滤器
	['HaveReadSelector']    	= g_tStrings.Shop.STR_READ_TITLE,    -- 已读未读过滤器
	['CollectFurniture']   		= g_tStrings.Shop.STR_COLLECTED_TITLE, -- 已收集未收集滤器
}

local TipsShowTime = 2
local nColumnCount = 3
-----------------------------事件处理--------------------------------------
function UIPlayStoreView:OnEnter(...)
	local args = {...}

	self.nClassID = 1

	if type(args[2]) == "number" then
		self.nShopID = args[1]
		self.nNpcID = args[2]
		self:HideShopGroup()
	else
		self.nShopID = nil
		self.nNpcID = args[1]
		self:UpdateShopGroup(self.nNpcID, args[2])
	end

	self.TableView = self.TableViewWithoutClass
	self.nColumnCount = 3
	if self.tShopGroup then
		self.TableView = self.TableViewWithClass
		self.nColumnCount = 2
	end

	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end

	self:InitGlobalShopInfo()
	OpenShopRequest(self.nShopID, self.nNpcID)
	RedpointHelper.SystemShop_SetNew(self.nShopID, false)
	self:OnFrameBreathe()

	UIHelper.SetVisible(self.BtnSendToChat, self.nNpcID == nil or self.nNpcID == 0)
	UIHelper.LayoutDoLayout(UIHelper.GetParent(self.BtnSendToChat))
end

function UIPlayStoreView:OnExit()
	self.tCustomData.bAutoSell = self.bAutoSell
	self.tCustomData.bAutoRepair = self.bAutoRepair
	CustomData.Register(CustomDataType.Role, "ShopCustomData", self.tCustomData)
	self.bInit = false
end

function UIPlayStoreView:BindUIEvent()
	UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
		UIMgr.Close(VIEW_ID.PanelPlayStore)
	end)

	-- 筛选界面
	self.bBtnScreenVisable = false
	UIHelper.SetVisible(self.WidgetAnchorCategoryTips, self.bBtnScreenVisable)

	UIHelper.BindUIEvent(self.BtnScreen, EventType.OnClick, function()
		self:GeneratePervFilter()
		TipsHelper.DeleteAllHoverTips(false)
		local _,scriptView = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnScreen, TipsLayoutDir.BOTTOM_RIGHT, FilterDef.Shop)
		self.scriptFilter = scriptView
	end)

	UIHelper.BindUIEvent(self.BtnAffirm, EventType.OnClick, function()
		UIHelper.SetVisible(self.WidgetAnchorCategoryTips, false)
	end)

	UIHelper.BindUIEvent(self.BtnRecEquip, EventType.OnClick, function()
		if UIMgr.IsViewOpened(VIEW_ID.PanelEquipCompare, true) then
			UIMgr.CloseWithCallBack(VIEW_ID.PanelEquipCompare, function ()
				UIMgr.Open(VIEW_ID.PanelEquipCompare, EquipCompareType.Bag, true, nil, true)
			end)
		else
			UIMgr.Open(VIEW_ID.PanelEquipCompare, EquipCompareType.Bag, true, nil, true)
		end
	end)

	UIHelper.BindUIEvent(self.TogStore, EventType.OnSelectChanged, function (_, bSelected)
		if bSelected then
			self:HideBagWidget()
			self:ClearCells()
			self:SwitchShop(self.nShopID)
		end
	end)

	UIHelper.BindUIEvent(self.TogRebuy, EventType.OnSelectChanged, function (_, bSelected)
		if bSelected then
			self:HideBagWidget()
			self:SwitchShop('BUY_BACK')
			self:UpdateBuyBackCell()
			self:UpdateSelectedGoodsDetails()
		end
	end)

	UIHelper.BindUIEvent(self.TogSpecialRebuy, EventType.OnSelectChanged, function (_, bSelected)
		if bSelected then
			self:HideBagWidget()
			self:SwitchShop('BUY_BACK_ADVANCED')
			self:UpdateBuyBackCell()
			self:UpdateSelectedGoodsDetails()
		end
	end)

	UIHelper.BindUIEvent(self.TogSell, EventType.OnSelectChanged, function (_, bSelected)
		if bSelected then
			self:ShowBagWidget()
		end
	end)

	UIHelper.BindUIEvent(self.TogSearch, EventType.OnSelectChanged, function (_, bSelected)
		UIHelper.SetVisible(self.LayoutCurrency, not bSelected)
	end)

	-- 自动出售灰色物品
	self.bWidgetAnchorSellTipsVisable = false
	UIHelper.BindUIEvent(self.BtnSet, EventType.OnClick, function()
		self.bWidgetAnchorSellTipsVisable = not self.bWidgetAnchorSellTipsVisable
		UIHelper.SetVisible(self.WidgetAnchorSellTips, self.bWidgetAnchorSellTipsVisable)
	end)

	UIHelper.BindUIEvent(self.TogAutoSell, EventType.OnSelectChanged, function (_, bSelected)
		self.bAutoSell = bSelected
	end)

	-- 自动修复
	-- UIHelper.BindUIEvent(self.TogAutoRepair, EventType.OnSelectChanged, function (_, bSelected)
	-- 	self.bAutoRepair = bSelected
	-- end)

	UIHelper.BindUIEvent(self.BtnSendToChat, EventType.OnClick, function ()
		if self.nShopID then
			local shopinfo = GetShop(self.nShopID)
			if not shopinfo then return end

			local szName = UIHelper.GBKToUTF8(shopinfo.szShopName) or ""
			local szLinkInfo = string.format("ShopPanel/%d", self.nShopID)
			ChatHelper.SendEventLinkToChat(szName, szLinkInfo)
		end
	end)

	UIHelper.BindUIEvent(self.BtnCleanOut, EventType.OnClick, function ()
		self.szSearchkey = nil
		UIHelper.SetText(self.EditBoxSearch, "")
		UIHelper.SetVisible(self.BtnCleanOut, self.szSearchkey and #self.szSearchkey > 0)
		self:ForceRefreshGoods()
	end)

	UIHelper.RegisterEditBoxEnded(self.EditBoxSearch, function ()
		self.szSearchkey = UIHelper.GetText(self.EditBoxSearch)
		UIHelper.SetVisible(self.BtnCleanOut, self.szSearchkey and #self.szSearchkey > 0)
		if not self.bOnOpenBag then
			self:ForceRefreshGoods()
		else
			self.nLastSellIndex = nil
			self:RefreshBagWidget()
		end
	end)

    UIHelper.TableView_addCellAtIndexCallback(self.TableViewWithoutClass, function(tableView, nIndex, script, node, cell)
		self:OnTableViewUpdate(script, nIndex)
    end)

	UIHelper.TableView_addCellAtIndexCallback(self.TableViewWithClass, function(tableView, nIndex, script, node, cell)
		self:OnTableViewUpdate(script, nIndex)
    end)

	UIHelper.TableView_addCellAtIndexCallback(self.TableViewOnSell, function(tableView, nIndex, script, node, cell)
		self:OnTableViewOnSellUpdate(script, nIndex)
    end)
end

function UIPlayStoreView:RegEvent()
	Event.Reg(self, "SHOP_OPENSHOP", function (nShopID)
		self:OpenShop(nShopID)
	end)

	Event.Reg(self, "SHOP_UPDATEITEM", function (nShopID,dwItemIndex,bAdd,nItemTemplateIndex)
		if self.bCustomShop and bAdd and nItemTemplateIndex ~= 0 then
			self.tCustomShop[nItemTemplateIndex] = dwItemIndex
			self.tCustomShopEx[dwItemIndex] = true
			self.nReloadTimerID = self.nReloadTimerID or Timer.AddFrame(self, 15, function ()
				self.nReloadTimerID = nil
				self:SwitchShop(nShopID)
			end)
		else
			self:OnShopUpdateItem(nShopID,dwItemIndex,bAdd,nItemTemplateIndex)
		end
	end)

	self.SellMsgCDEndTime = 0
	Event.Reg(self, "SYS_MSG", function (szEventType, nRespondCode, nMoney)
		if szEventType == "UI_OME_SHOP_RESPOND" then
			if nRespondCode == SHOP_SYSTEM_RESPOND_CODE.BUY_SUCCESS then
				if self.nShopMode == "SHOP" then
					self:UpdateCurCells()
				end
			elseif nRespondCode == SHOP_SYSTEM_RESPOND_CODE.SELL_SUCCESS then
				local nowTime = os.time()
				if self.SellMsgCDEndTime<nowTime then
					self.SellMsgCDEndTime = nowTime + TipsShowTime
					local szMsg = g_tStrings.g_ShopStrings[nRespondCode].. UIHelper.GetMoneyText(nMoney)
					TipsHelper.OutputMessage("MSG_SYS", szMsg , true, TipsShowTime)
				end
				SoundMgr.PlaySound(SOUND.UI_SOUND, g_sound.Sell)
			end
		end
	end)

	Event.Reg(self, "BAG_ITEM_UPDATE", function(nBox, nIndex, bNewAdd)
		self:RefreshBuyBackCell()
		self:RefreshBagWidget()
		if not self.bOnOpenBag then self:UpdateCurCells() return end
    end)

	Event.Reg(self, "MONEY_UPDATE", function (nDeltaGold, nDeltaSilver, nDeltaCopper, bShowMsg)
        self:UpdateCurCells()
    end)

	local tCurrencyUpdateEvent = Currency_Base.GetCurrencyList()
	for _, szCurrency in ipairs(tCurrencyUpdateEvent) do
		local szEvent = ("UPDATE_" .. szCurrency):upper()
		if szEvent then
			Event.Reg(self, szEvent, function()
				self:UpdateCurCells()
			end)
		end
	end
	
	Event.Reg(self, "PLAYER_LEVEL_UPDATE", function ()
        self:UpdateCurCells()
    end)

	Event.Reg(self, "REMOTE_SHOPLIMIT_FRESH", function ()
        self:UpdateCurCells()
    end)

	Event.Reg(self, "SOLD_ITEM_UPDATE", function (nBox, nIndex, bNewAdd)
		self:RefreshBuyBackCell()
        self:UpdateCurCells()
		if nBox == self.dwRequestSoldBox and nIndex == self.dwRequestSoldIndex and not bNewAdd then
			TipsHelper.ShowNormalTip("回购成功")
		end
    end)

	Event.Reg(self, "TIME_LIMIT_SOLD_ITEM_UPDATE", function (nBox, nIndex, bNewAdd)
		self:RefreshBuyBackCell()
        self:UpdateCurCells()
		if nBox == self.dwRequestSoldBox and nIndex == self.dwRequestSoldIndex and not bNewAdd then
			TipsHelper.ShowNormalTip("回购成功")
		end
    end)

	Event.Reg(self, "TIME_LIMIT_SOLD_ITEM_TIME_UPDATE", function (nBox, nIndex, bNewAdd)
		self:RefreshBuyBackCell()
        self:UpdateCurCells()
    end)

	Event.Reg(self, EventType.OnBuyBackItemTimeOut, function ()
		self:RefreshBuyBackCell()
    end)

	Event.Reg(self, EventType.OnShopGoodsSelectChanged, function (nCurGoodsIndex, bSelected, aShopInfo)
		if bSelected then
			self.aShopInfo = aShopInfo
			self.nCurGoodsIndex = nCurGoodsIndex
			self:UpdateSelectedGoodsDetails()
		end
	end)

	Event.Reg(self, EventType.OnShopSelectorSelectChanged, function (szSelectorName,selectValue, bSelected)
		self:SetSelector(self.tSelector, szSelectorName,selectValue,bSelected)
		--self:UpdateSelectors()
		self:UpdateCell()
	end)

	Event.Reg(self, EventType.OnShopBuyGoodsSure, function (nBuyCount)
		self:ShowBuyGoodsConfirm(nBuyCount)
	end)

	Event.Reg(self, EventType.OnShopClassSelectChanged, function (nClassID, scriptClass, bSelected)
		if bSelected and self.nClassID ~= nClassID then
			Timer.AddFrame(self, 1, function ()
				self.nClassID = nClassID
				self:UpdateShopClass(true)
				self:ClearCells()
				OpenShopRequest(self.nShopID, self.nNpcID)
				RedpointHelper.SystemShop_SetNew(self.nShopID, false)
			end)
		elseif not bSelected and self.nClassID == nClassID then
			Timer.AddFrame(self, 1, function ()
				self.nLastClassID = self.nClassID
				self.nClassID = 0
				self:UpdateShopClass(true)
			end)
		end
	end)

	Event.Reg(self, EventType.OnSubShopSelectChanged, function (nShopID, scriptSubShop, bSelected)
		UIHelper.SetVisible(scriptSubShop.Eff_MenuSelect, bSelected)
		if not bSelected then
			return
		end
		self.nShopID = nShopID
		OpenShopRequest(self.nShopID, self.nNpcID)
		RedpointHelper.SystemShop_SetNew(self.nShopID, false)
	end)

	Event.Reg(self, EventType.OnWindowsSizeChanged, function ()
		UIHelper.WidgetFoceDoAlign(self)
		local nodeParent = UIHelper.GetParent(self.BtnScreen)
		UIHelper.LayoutDoLayout(nodeParent)

		if self.scriptItemTip then		
			self:RefreshItemTipsScrollViewHeight()
			UIHelper.SetPositionY(self.scriptItemTip._rootNode, 0)
		end
		
		if self.scriptQuantityController then
			Timer.AddFrame(self, 3, function ()
				self:ForceFixQuantityController()
			end)
			Timer.AddFrame(self, 5, function ()
				self:ForceFixQuantityController()
			end)
			Timer.AddFrame(self, 7, function ()
				self:ForceFixQuantityController()
				UIHelper.ScrollViewDoLayoutAndToTop(self.scriptItemTip.ScrollViewContent)
			end)
		end
		
		UIHelper.TableView_scrollToTop(self.TableView, 0)
		UIHelper.TableView_scrollToTop(self.TableViewOnSell, 0)
	end)

	Event.Reg(self, EventType.HideAllHoverTips, function ()
		self:OnHideAllHoverTips()
	end)

	Event.Reg(self, EventType.OnTouchViewBackGround, function ()
        self:OnHideAllHoverTips()
    end)

	Event.Reg(self, EventType.OnFilter, function (szKey, tbFilter , nLastChoosedIndex, nLastChoosedSubIndex)
		if szKey == FilterDef.Shop.Key then
            self:UpdateFilterState(self.tPervSelector, tbFilter, true)
			self.tSelector = CopyTable(self.tPervSelector)
			self:ApplySearchFilter()
			self:ApplySelector()
			self:GeneratePervFilter()
			TipsHelper.DeleteAllHoverTips(false)
			local _,scriptView = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnScreen, TipsLayoutDir.BOTTOM_RIGHT, FilterDef.Shop)
			self.scriptFilter = scriptView
			Timer.AddFrame(self, 1, function ()
				self:RedirectFilter(self.scriptFilter, nLastChoosedIndex, nLastChoosedSubIndex)
			end)

			self.bNeedRefresh = true
			self:QueryAllData()
        end
    end)

	Event.Reg(self, EventType.OnFilterSelectChanged, function (szKey, tbFilter)
		if szKey == FilterDef.Shop.Key then
            self:UpdateFilterState(self.tPervSelector, tbFilter)
			self:GeneratePervFilter()
			if self.scriptFilter then
				self.scriptFilter:Refresh()
			end
        end
    end)

	Event.Reg(self, EventType.OnViewOpen, function (nViewID)
		if nViewID ~= VIEW_ID.PanelChatSocial then return end

		UIHelper.SetVisible(self.WidgetAnchorBottom, false)
		UIHelper.PlayAni(self, self.AniAll, "AniBottomHide")
    end)

	Event.Reg(self, EventType.OnViewClose, function (nViewID)
		if nViewID ~= VIEW_ID.PanelChatSocial then return end

		UIHelper.PlayAni(self, self.AniAll, "AniBottomShow")
		UIHelper.SetVisible(self.WidgetAnchorBottom, true)
    end)
end

function UIPlayStoreView:UpdateFilterState(tSelector, tbFilter, bRefreshBtnSreen)
	for nSelectorClassID, tChoosenList in ipairs(tbFilter) do
		local szSelectorName = self.tSelectorClassID2SelectorName[nSelectorClassID]
		self:SetSelector(tSelector, szSelectorName, nil)
		for nIndex, nChoosenIndex in ipairs(tChoosenList) do
			local value = FilterDef.Shop[nSelectorClassID].tbValList[nChoosenIndex]
			self:SetSelector(tSelector, szSelectorName, value)
		end
	end

	if bRefreshBtnSreen then
		self.bFiltered = not self:IsDefaultSelected(tbFilter)
		if not self.bFiltered then
			UIHelper.SetSpriteFrame(self.ImgScreen, ShopData.szScreenImgDefault)
		else
			UIHelper.SetSpriteFrame(self.ImgScreen, ShopData.szScreenImgActiving)
		end
	end
end

function UIPlayStoreView:UpdateFilterSelected(tbFilter)
	for nSelectorClassID, tChoosenList in ipairs(tbFilter) do
		FilterDef.Shop[nSelectorClassID].tbDefault = tChoosenList
	end
end

function UIPlayStoreView:OnFrameBreathe()
	self:UpdateShopItemTableView()
	self:AutoBuyGoods()
	self:AutoRefreshCostItem()
	Timer.AddFrame(self, 1, function()
		self:OnFrameBreathe()
	end)
end

local function TableView_GetProgress(tableView)
	-- tableView的可见区域(tableViewMask)
	local nodeWindow = UIHelper.GetParent(tableView)
	-- tableView的实时可滑动区域
	local nodeContent = UIHelper.GetChildren(tableView)[1]
	-- 当nodeConent的顶部与nodeWindow顶部重合进度为0，当nodeConent的底部与nodeWindow的底部重合进度为100
	local nWinBottomY = UIHelper.GetWorldPositionY(nodeWindow)
	local nConBottomY = UIHelper.GetWorldPositionY(nodeContent)
	local nWinHeight = UIHelper.GetHeight(nodeWindow)
	local nConHeight = UIHelper.GetHeight(nodeContent)
	-- nodeConent的最大滑动距离
	local nTotalHeight = nConHeight - nWinHeight
	-- 以底部重合为基点，nodeContent当前滑出距离
	local nCurHeight = nConBottomY - nWinBottomY
	
	local nPercent = (1 - math.abs(nCurHeight/nTotalHeight))*100
	return nPercent
end

function UIPlayStoreView:TableView_SetupArrow(tableView, arrowParent)
    if not self.bTableViewCanSlide or not safe_check(tableView) or not safe_check(arrowParent) then
        return
    end

    local widgetArrow = arrowParent._widgetArrow
    if not widgetArrow or not IsUserData(widgetArrow) then
        arrowParent._widgetArrow = UIHelper.AddPrefab(PREFAB_ID.WidgetArrow, arrowParent)
        widgetArrow = arrowParent._widgetArrow
    end

    local nPercent = TableView_GetProgress(tableView)
	UIHelper.SetVisible(widgetArrow, nPercent < 100)
end

function UIPlayStoreView:UpdateShopItemTableView()
	if self.bTableViewCanSlide and not self.bOnOpenBag then
		self:TableView_SetupArrow(self.TableView, self.WidgetArrowParent)
		self:TableView_SetupArrow(self.TableView, self.WidgetArrowParent2)
	end	
	if not self.bNeedRefresh then
		return
	end

	self.bNeedRefresh = false
	self:ClearCurrency()
	self.nCurGoodsIndex = nil
	local nTotalCellCount = math.ceil(#self.aGoods/self.nColumnCount)
	for _, goods in ipairs(self.aGoods) do
		self:RemarkCurrency(goods.dwShopIndex)
		self:RemarkCostItem(goods.dwShopIndex)
	end
	UIHelper.TableView_init(self.TableView, nTotalCellCount, PREFAB_ID.WidgetPlayStoreRow_PercentAnchor)
	UIHelper.TableView_reloadData(self.TableView)
	UIHelper.SetVisible(self.WidgetEmpty, #self.aGoods == 0)
	UIHelper.SetVisible(self.WidgetCard, #self.aGoods > 0)

	if self.dwDefaultTabType and self.dwDefaultIndex then
		for idx, tbGoods in ipairs(self.aGoods) do
			if self.dwDefaultTabType == tbGoods.nItemType and self.dwDefaultIndex == tbGoods.nItemIndex then
				local nIndex = math.ceil(idx/self.nColumnCount)
				UIHelper.TableView_scrollToCell(self.TableView, nTotalCellCount, nIndex, 0)
			end
		end
	end
	self.bTableViewCanSlide = UIHelper.TableView_CanSlide(self.TableView, nTotalCellCount)
	UIHelper.SetVisible(self.WidgetArrowParent, self.bTableViewCanSlide)
	UIHelper.SetVisible(self.WidgetArrowParent2, self.bTableViewCanSlide)
end

function UIPlayStoreView:OnTableViewUpdate(striptRow, nIndex)
    if not striptRow then return end

	striptRow:OnEnter(PREFAB_ID.WidgetPlayStoreCell, self.ToggleGroupBag, self.nColumnCount)
    for i = 1, self.nColumnCount do
        local nIdx = (nIndex-1)*self.nColumnCount + i
        local bVisible = nIdx <= #self.aGoods
        if bVisible then
            local tbGoods = self.aGoods[nIdx]
			self:RemarkCurrency(tbGoods.dwShopIndex)
            local nCount = striptRow:GetDataCount()
            if nCount < self.nColumnCount then
                local scriptCell = striptRow:PushData(nIdx, self.nNpcID, self.nShopID, self.dwPlayerRemoteDataID, tbGoods)
				scriptCell.tbGoods = tbGoods
                self.scriptGoodsMap[nIdx] = scriptCell
            else
                local scriptCell = striptRow:UpdateData(nIdx, self.nNpcID, self.nShopID, self.dwPlayerRemoteDataID, tbGoods)
                self.scriptGoodsMap[nIdx] = scriptCell
				scriptCell.tbGoods = tbGoods
            end
            local scriptCell = self.scriptGoodsMap[nIdx]
            local bSelected = UIHelper.GetSelected(scriptCell.ToggleSelect)
            if self.nCurGoodsIndex ~= nIdx and bSelected then -- 当前组件显示的不是被选中项，但是处于选中状态
                UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupBag, self.ToggleDefaultGoods)
            elseif self.nCurGoodsIndex == nIdx and not bSelected then -- 当前组件显示的是被选中项，但是未处于选中状态
                UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupBag, scriptCell.ToggleSelect)
            end

			if not self.bEquipSet and (self.dwDefaultTabType and self.dwDefaultIndex) and (self.dwDefaultTabType == tbGoods.nItemType and self.dwDefaultIndex == tbGoods.nItemIndex) then
				self.dwDefaultTabType = nil
				self.dwDefaultIndex = nil
				tbGoods.nNeedCount = self.nNeedCount
				self:OnSelectedGoodsChanged(nIdx, tbGoods)
			elseif not self.nCurGoodsIndex then
                self:OnSelectedGoodsChanged(nIdx, tbGoods)
            end
        end
        striptRow:SetCellVisible(nIdx, bVisible)
    end
end

function UIPlayStoreView:OnTableViewOnSellUpdate(striptRow, nIndex)
    if not striptRow then return end
	-- 出售自动选择原始位置临近商品，优先选中新的递补到原始位置的商品，其次选择最后一件商品。
	if self.nLastSellIndex and self.nLastSellIndex > #self.tBagItemInfoList then self.nLastSellIndex = #self.tBagItemInfoList end
	striptRow:OnEnter(PREFAB_ID.WidgetSellOutCell, self.ToggleGroupBag, nColumnCount, true)
    for i = 1, nColumnCount do
        local nIdx = (nIndex-1)*nColumnCount + i
        local bVisible = nIdx <= #self.tBagItemInfoList
        if bVisible then
            local tBagItem = self.tBagItemInfoList[nIdx]
            local nCount = striptRow:GetDataCount()
            if nCount < nColumnCount then
                local scriptCell = striptRow:PushData(nIdx, self.nNpcID, self.nShopID, tBagItem.nBox, tBagItem.nIndex)
				self.tScriptSellOutScellList[nIdx] = scriptCell
            else
                local scriptCell = striptRow:UpdateData(nIdx, self.nNpcID, self.nShopID, tBagItem.nBox, tBagItem.nIndex)
				self.tScriptSellOutScellList[nIdx] = scriptCell
            end
            local scriptCell = self.tScriptSellOutScellList[nIdx]
			scriptCell:SetSelectChangeCallback(function(dwItemID, bSelected)
				if bSelected then
					self:DoUpdateSelect(dwItemID)
				end
			end)

            if (not self.nLastSellIndex and (not self.tbSelected.dwItemID or nIdx == 1)) or self.nLastSellIndex == nIdx then
				local item = ItemData.GetItemByPos(tBagItem.nBox, tBagItem.nIndex)
				if item then
					self:DoUpdateSelect(item.dwID)
					self.nCurGoodsIndex = nIdx
				end
            end

			local bSelected = UIHelper.GetSelected(scriptCell.ToggleSelect)
            if self.nCurGoodsIndex ~= nIdx and bSelected then -- 当前组件显示的不是被选中项，但是处于选中状态
                UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupBag, self.ToggleDefaultGoods)
            elseif self.nCurGoodsIndex == nIdx and not bSelected then -- 当前组件显示的是被选中项，但是未处于选中状态
                UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupBag, scriptCell.ToggleSelect)
            end
        end
        striptRow:SetCellVisible(nIdx, bVisible)
    end
end

function UIPlayStoreView:OnShopUpdateItem(nShopID,dwItemIndex,bAdd,nItemTemplateIndex)
	if nShopID ~= self.nShopID or not g_pClientPlayer then
		return
	end

	local tbGoods, nGoodsIndex = self:GetGoods(dwItemIndex)
	if not tbGoods then
		return
	end
	self:RemarkCurrency(dwItemIndex)
	self:RemarkCostItem(dwItemIndex)
	
	if self.bEquipSet and self.dwDefaultTabType then
		local tOtherShopInfo = GetShopItemBuyOtherInfo(self.nShopID, dwItemIndex)
		if tOtherShopInfo and tOtherShopInfo.dwTabType == self.dwDefaultTabType and tOtherShopInfo.dwIndex == self.dwDefaultIndex then
			local dwMainKungfuID = g_pClientPlayer.GetActualKungfuMountID()
			dwMainKungfuID = TabHelper.GetHDKungfuID(dwMainKungfuID) or dwMainKungfuID

			if tbGoods.tKungfuMatchMap and not tbGoods.tKungfuMatchMap[dwMainKungfuID] then -- 允许再跳一次当前心法
				self.dwFindMatchTabType = self.dwDefaultTabType
				self.dwFindMatchIndex = self.dwDefaultIndex
			end

			self.bEquipSet = nil
			self.dwDefaultTabType = tbGoods.nItemType
			self.dwDefaultIndex = tbGoods.nItemIndex
			self.bNeedRefresh = true
		end
	elseif self.dwFindMatchTabType then
		local tOtherShopInfo = GetShopItemBuyOtherInfo(self.nShopID, dwItemIndex)
		if tOtherShopInfo and tOtherShopInfo.dwTabType == self.dwFindMatchTabType and tOtherShopInfo.dwIndex == self.dwFindMatchIndex then
			local dwMainKungfuID = g_pClientPlayer.GetActualKungfuMountID()
			dwMainKungfuID = TabHelper.GetHDKungfuID(dwMainKungfuID) or dwMainKungfuID
			if tbGoods.tKungfuMatchMap[dwMainKungfuID] then
				self.dwFindMatchTabType = nil
				self.dwFindMatchIndex = nil
				self.dwDefaultTabType = tbGoods.nItemType
				self.dwDefaultIndex = tbGoods.nItemIndex
				self.bNeedRefresh = true
			end
		end
	end

	local scriptGoods = self.scriptGoodsMap[nGoodsIndex]
	if not scriptGoods then
		return
	end
	scriptGoods:OnEnter(self.nNpcID, self.nShopID, self.dwPlayerRemoteDataID, tbGoods)
	if nGoodsIndex == self.nCurGoodsIndex then
		self.aShopInfo = scriptGoods.aShopInfo
		self:UpdateSelectedGoodsDetails()
	end
end

function UIPlayStoreView:GetGoods(dwItemIndex)
	local targetGoods
	local nGoodsIndex
	for nIndex, tbGoods in ipairs(self.aGoods) do
		if tbGoods.dwShopIndex == dwItemIndex then
			targetGoods = tbGoods
			nGoodsIndex = nIndex
			break
		end
	end

	return targetGoods, nGoodsIndex
end

function UIPlayStoreView:OnSelectedGoodsChanged(nIdx, tbGoods)
    self.nCurGoodsIndex = nIdx

    local scriptCell = self.scriptGoodsMap[nIdx]
    if scriptCell then
        UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupBag, scriptCell.ToggleSelect)
    end
	self.aShopInfo = scriptCell.aShopInfo
	self:UpdateSelectedGoodsDetails()
end

--------------------------------------------------公共接口-----------------------------------------------
local function GetItemInfoRequireLevel(nTabType, itemInfo)
	if nTabType == ITEM_TABLE_TYPE.OTHER or nTabType == ITEM_TABLE_TYPE.HOMELAND or nTabType == ITEM_TABLE_TYPE.NPC_EQUIP then
		return itemInfo.nRequireLevel
	else
		local requireAttrib = itemInfo.GetRequireAttrib()
		for k, v in pairs(requireAttrib) do
			if v.nID == 5 then
				return v.nValue
			end
		end
	end
	return 0
end

function UIPlayStoreView:OpenShop(nShopID)
	local player = GetClientPlayer()
	if not player or player.nMoveState == MOVE_STATE.ON_DEATH then
		return
	end
	LOG.INFO("OpenShop GetShop(nShopID)=%s", tostring(nShopID))
	local shopinfo = GetShop(nShopID)
	if not shopinfo then
		return
	end
  	self.szFilter = nil
    self.nShopID = nShopID
    self.nNpcID = shopinfo.dwNpcID
	self.bCanRepair = shopinfo.bCanRepair
	self.nTemplateID = shopinfo.dwTemplateID
	self.bCustomShop = shopinfo.bCustomShop
	self.tCustomShop = {}
	self.tCustomShopEx = {}
	self.tShopConfig = Table_GetShopPanelSelector(shopinfo.dwTemplateID) or {}

	self.tPervSelector = nil
	self.tSelector = CopyTable(self.tShopConfig)

	self.dwPlayerRemoteDataID = shopinfo.dwPlayerRemoteDataID
	if self.dwPlayerRemoteDataID > 0 then
		player.ApplyRemoteData(self.dwPlayerRemoteDataID, REMOTE_DATA_APPLY_EVENT_TYPE.CLIENT_APPLY_SERVER_CALL_BACK)
	end

	self:InitShopInfo()

  	-- TODO: 打开界面需要自动提交王婆婆相关任务
	-- FireHelpEvent("OnOpenpanel", "ShopID", nil, nil, nShopID)
	self.nShopMode = 'SHOP'
	self:SwitchShop(nShopID)
end

function UIPlayStoreView:InitShopInfo()
	local npcName = ""
	local npc = GetNpc(self.nNpcID)
	if npc then
		npcName = UIHelper.GBKToUTF8(npc.szName)
	else
		npcName = UIHelper.GBKToUTF8(self.tShopGroup.szGroupName)
	end

	UIHelper.SetString(self.LabelTitle, npcName)

	self.tCostItemMark = {}
	-- 屏蔽无配置筛选的筛选按钮
	self.bHasBtnScreen = false
	self.bHasBtnScreen = self.tSelector.bAttriSelector or
	self.tSelector.bEquipPosSelector or
	self.tSelector.bForceSelector or
	self.tSelector.bHaveReadSelector or
	self.tSelector.bCollectFurniture or
	self.tSelector.bKungfuSelector or
	self.tSelector.bLevelSelector or
	self.tSelector.bQualitySelector or
	self.tSelector.bRequireLevelSelector or
	self.tSelector.bScoreSelector or
	self.tSelector.bSkillSelector

	self.bNoBtnScreen = not self.bHasBtnScreen
	self:RefreshWidgetBtns()

	-- 永远屏蔽自动维护
	UIHelper.SetVisible(self.WidgetAnchorAutoRepair, false)
	self.bAutoRepair = false
	if not self.bCheckAutoSell then
		self.bCheckAutoSell = true
		if self.bAutoSell then
			AutomaticSell(self.nNpcID, self.nShopID, GetClientPlayer())
		end
		if self.bAutoRepair and self.bCanRepair then
            OnCheckAddAchievement(998, "Shop_Frist_Repair")
			RepairAllItemsWithoutTips()
		end
	end
	UIHelper.SetVisible(self.LayoutTitle, true)
	UIHelper.LayoutDoLayout(self.LayoutTitle)

	UIHelper.SetTouchDownHideTips(self.BtnScreen, false)
end

function UIPlayStoreView:InitGlobalShopInfo()
	self.tCustomData = CustomData.GetData(CustomDataType.Role, "ShopCustomData")
	self.tForceToppingItemList = {}
	self.bAutoSell = true
	self.bAutoRepair = false
	if self.tCustomData then
		self.bAutoSell = self.tCustomData.bAutoSell
		UIHelper.SetSelected(self.TogAutoSell, self.bAutoSell)
		-- self.bAutoRepair = self.tCustomData.bAutoRepair
		-- UIHelper.SetSelected(self.TogAutoRepair, self.bAutoRepair)
	else
		self.tCustomData = {}
		CustomData.Register(CustomDataType.Role, "ShopCustomData", self.tCustomData)
	end

	UIHelper.SetTouchDownHideTips(self.BtnBg, false)
	UIHelper.SetTouchDownHideTips(self.ScrollViewFilter, false)
	UIHelper.SetTouchDownHideTips(self.BtnReset, false)
	UIHelper.SetTouchDownHideTips(self.BtnAffirm, false)
	UIHelper.SetTouchDownHideTips(self.TogAutoSell, false)
	UIHelper.SetTouchDownHideTips(self.BtnSet, false)


	local bInTravelingMap = TravellingBagData.IsInTravelingMap()
	UIHelper.SetVisible(self.ImgLine, not bInTravelingMap)
	UIHelper.SetVisible(self.TogSell, not bInTravelingMap)
	UIHelper.SetVisible(self.ImgLine02, not bInTravelingMap)
	UIHelper.SetVisible(self.TogRebuy, not bInTravelingMap)
	UIHelper.SetVisible(self.ImgLine03, not bInTravelingMap)
	UIHelper.SetVisible(self.TogSpecialRebuy, not bInTravelingMap)
	UIHelper.SetSwallowTouches(self.TableView, false)

	UIHelper.ToggleGroupAddToggle(self.ToggleGroupBag, self.ToggleDefaultGoods)

	-- 商品数据表
	self.tShopDataMap = {}
	self.scriptGoodsMap = {}
	self.tBagItemInfoList = {}
end

function UIPlayStoreView:UpdateShopGroup(nNpcID, tShopGroup)
	UIHelper.SetVisible(self.WidgetContentWithoutClass, false)
	UIHelper.SetVisible(self.WidgetContentWithClass, true)
	UIHelper.SetVisible(self.WidgetContentSell, false)
	self.nNpcID = nNpcID
	self.bGroup = true
	self.tShopGroup = tShopGroup

	self.TableView = self.TableViewWithClass
	self.nColumnCount = 2

	if not self.nShopID and tShopGroup.nDefaultClassID then
		self.nClassID = tShopGroup.nDefaultClassID
	end

	if not self.nShopID and tShopGroup.nDefaultShopID then
		self.nShopID = tShopGroup.nDefaultShopID
	end

	if tShopGroup.dwDefaultTabType and tShopGroup.dwDefaultIndex then
		self.dwDefaultTabType = tShopGroup.dwDefaultTabType
		self.dwDefaultIndex = tShopGroup.dwDefaultIndex
		self.nNeedCount = tShopGroup.nNeedCount
		self.bEquipSet = tShopGroup.bEquipSet
	end

	local szGroupName = UIHelper.GBKToUTF8(tShopGroup.szGroupName)
	local tbInfo = Const.Shop.EquipmentShopInfo[szGroupName]
	local bShowRecEquipBtn = tbInfo and tbInfo.bShowRecEquipBtn
	UIHelper.SetVisible(self.BtnRecEquip, bShowRecEquipBtn)
	UIHelper.LayoutDoLayout(UIHelper.GetParent(self.BtnRecEquip))
	
	self:UpdateShopClass()
end

function UIPlayStoreView:UpdateShopClass(bNeedChangeShopID)
	UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupSubShop)
	UIHelper.RemoveAllChildren(self.ScrollViewClassList)

	for nClassID, tClass in ipairs(self.tShopGroup) do
		-- 增加分类
		local szClassName = tClass.szName or tClass.szClassName
		szClassName = UIHelper.GBKToUTF8(szClassName)
		local scriptClass = UIHelper.AddPrefab(PREFAB_ID.WidgetTreeClassSelector, self.ScrollViewClassList, nClassID, szClassName, tClass)
		if not scriptClass then
			break
		end
		if nClassID == self.nClassID then
			UIHelper.SetSelected(scriptClass.TogTab, true)
			for _, tShop in ipairs(tClass) do
				if tShop.bShow then
					-- 增加商店
					local szShopName = UIHelper.GBKToUTF8(tShop.szShopName)
					local scriptSubShop = UIHelper.AddPrefab(PREFAB_ID.WidgetTreeSubSelector, self.ScrollViewClassList, tShop.nShopID, szShopName)
					if not scriptSubShop then
						break
					end
					UIHelper.ToggleGroupAddToggle(self.ToggleGroupSubShop, scriptSubShop.TogTab)
					if not self.nShopID or bNeedChangeShopID then
						self.nShopID = tShop.nShopID
						bNeedChangeShopID = false
					end
					if self.nShopID == tShop.nShopID then
						UIHelper.SetVisible(scriptSubShop.Eff_MenuSelect, true)
						UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupSubShop, scriptSubShop.TogTab)
					end
				end
			end
		else
			UIHelper.SetSelected(scriptClass.TogTab, false)
		end
		UIHelper.SetVisible(scriptClass.Eff_MenuSelect, nClassID == self.nLastClassID and self.nClassID == 0)
	end

	UIHelper.ScrollViewDoLayout(self.ScrollViewClassList)
	UIHelper.ScrollToTop(self.ScrollViewClassList, 0)
end

function UIPlayStoreView:HideShopGroup()
	UIHelper.SetVisible(self.WidgetContentWithoutClass, true)
	UIHelper.SetVisible(self.WidgetContentWithClass, false)
	UIHelper.SetVisible(self.WidgetContentSell, false)
	UIHelper.SetVisible(self.WidgetArrowParent, self.bTableViewCanSlide)
	UIHelper.SetVisible(self.WidgetArrowParent2, self.bTableViewCanSlide)
	UIHelper.SetVisible(UIHelper.GetChildren(self.WidgetArrowParent)[1], false)
	UIHelper.SetVisible(UIHelper.GetChildren(self.WidgetArrowParent2)[1], false)

	self.TableView = self.TableViewWithoutClass
	self.nColumnCount = 3

	UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupShopClass)
	UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupSubShop)
	UIHelper.RemoveAllChildren(self.ScrollViewClassList)
	UIHelper.ScrollViewDoLayout(self.ScrollViewClassList)
	UIHelper.ScrollToTop(self.ScrollViewClassList, 0)
end

function UIPlayStoreView:ShowBagWidget()
	self.bWidgetContentWithoutClass = UIHelper.GetVisible(self.WidgetContentWithoutClass)
	self.bWidgetContentWithClass = UIHelper.GetVisible(self.WidgetContentWithClass)
	UIHelper.SetVisible(self.WidgetContentWithoutClass, false)
	UIHelper.SetVisible(self.WidgetContentWithClass, false)
	UIHelper.SetVisible(self.WidgetContentSell, true)
	UIHelper.SetVisible(self.BtnScreen, false)
	UIHelper.SetVisible(self.WidgetArrowParent, false)
	UIHelper.SetVisible(self.WidgetArrowParent2, false)
	UIHelper.LayoutDoLayout(self.LayoutTitle)
	self.bOnOpenBag = true
	self:RefreshBagWidget()
end

function UIPlayStoreView:HideBagWidget()
	if not self.bOnOpenBag then
		return
	end
	UIHelper.SetVisible(self.WidgetContentWithoutClass, self.bWidgetContentWithoutClass)
	UIHelper.SetVisible(self.WidgetContentWithClass, self.bWidgetContentWithClass)
	UIHelper.SetVisible(self.WidgetContentSell, false)
	UIHelper.SetVisible(self.BtnScreen, true)
	UIHelper.LayoutDoLayout(self.LayoutTitle)

	self.nLastSellIndex = nil
	self.bOnOpenBag = false
	self:RefreshWidgetBtns()

	self:ClearItemTips()
end

function UIPlayStoreView:DoUpdateSelect(dwItemID)
    self.tbSelected.dwItemID = dwItemID

    if self.tbSelected.dwItemID then
        local nBox, nIndex = ItemData.GetItemPos(self.tbSelected.dwItemID)
        if not nBox or not table.contain_value(ItemData.BoxSet.Bag, nBox) then   -- 如果选中道具已经不在背包中
            local item = ItemData.GetItemByPos(self.tbSelected.tbPos.nBox, self.tbSelected.tbPos.nIndex) -- 用选中的格子信息找到新的选中道具
            if item then
                self.tbSelected.dwItemID = item.dwID
            else                            -- 选中的格子中页没有新的道具，无选中
                self.tbSelected.dwItemID = nil
                self.tbSelected.tbPos = {nBox = nil, nIndex = nil}
                --self:DelayAutoSelectFirstItem()
            end
        else
            self.tbSelected.tbPos = {nBox = nBox, nIndex = nIndex}
        end
    else
        self.tbSelected.tbPos = {nBox = nil, nIndex = nil}
    end
    self:UpdateSelectedItemDetails()
end

function UIPlayStoreView:SellSelectedItem(nSellCount)
	if self.tbSelected then
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.SHOP, "sell") then
            return
        end

        OnCheckAddAchievement(997, "Shop_Frist_Sell")

        local item = ItemData.GetItemByPos(self.tbSelected.tbPos.nBox, self.tbSelected.tbPos.nIndex)
		local itemName = ItemData.GetItemNameByItem(item)
		local nBagItemIndex = 1
		for nIndex, tBagItem in ipairs(self.tBagItemInfoList) do
			if tBagItem.nBox == self.tbSelected.tbPos.nBox and tBagItem.nIndex == self.tbSelected.tbPos.nIndex then
				nBagItemIndex = nIndex
				break
			end
		end

		itemName = UIHelper.GBKToUTF8(itemName)
		if item then
			local nStackNum = nSellCount or 1
			if not nSellCount and item.bCanStack then
				nStackNum = item.nStackNum
			end
			local nBox = self.tbSelected.tbPos.nBox
			local nIndex = self.tbSelected.tbPos.nIndex
			local bTimeReturn = ItemData.IsCanTimeReturnItem(item)
			if (item.nQuality >= 3 and item.bCanTrade) or bTimeReturn then
				local nDiamondR, nDiamondG, nDiamondB = GetItemFontColorByQuality(item.nQuality)
				itemName = GetFormatText(itemName, nil, nDiamondR, nDiamondG, nDiamondB)
				local szSellTips
				local bCountDown = false
				if bTimeReturn then
					local szEnchant = ItemData.GetItemEnchantDesc(item)
					if szEnchant and szEnchant ~= "" then
						szSellTips = string.format(g_tStrings.Shop.STR_SELL_RETURN_ENCHANT_ITEM_TIPS, itemName, szEnchant)
						bCountDown = true
					else
						szSellTips = string.format(g_tStrings.Shop.STR_SELL_RETURN_ITEM_TIPS, itemName)
					end
				else
					szSellTips = g_tStrings.Shop.STR_SELL_NORMAL_ITEM_TIPS
				end
				szSellTips = string.format(szSellTips, itemName)

				local confirmDialog = UIHelper.ShowConfirm(szSellTips, function ()
					self.dwLastSellItemID = item.dwID
					self.nLastSellIndex = nBagItemIndex
					SellItem(self.nNpcID, self.nShopID, nBox, nIndex, nStackNum)
				end, nil, true)

				if bCountDown then
					confirmDialog:SetButtonCountDown(5)
				end	
			else
				self.dwLastSellItemID = item.dwID
				self.nLastSellIndex = nBagItemIndex
				SellItem(self.nNpcID, self.nShopID, nBox, nIndex, nStackNum)
			end
		end
	end
end

local function MatchString(szSrc, szDst)
    if not szDst then
        return true
    end
	local nPos = string.match(szSrc, szDst)
	if not nPos then
	   return false;
	end

	return true
end

function UIPlayStoreView:RefreshBagWidget()
	if not self.bOnOpenBag then
		return
	end
	self:ClearItemTips()
	self.bOnOpenBag = true
	self.bBatchSelect = false
    self.tbSelected = { dwItemID = nil, tbPos = { nBox = nil, nIndex = nil }, tbBatch = nil }
	self.tBagItemInfoList = {}
	self.tScriptSellOutScellList = {}

	for _, tbItemInfo in ipairs(ItemData.GetItemList(ItemData.BoxSet.Bag)) do
		local item = ItemData.GetItemByPos(tbItemInfo.nBox, tbItemInfo.nIndex)
		local bTimeReturn = ItemData.IsCanTimeReturnItem(item)
		if item and (item.bCanTrade or bTimeReturn) then
			local szItemName = ItemData.GetItemNameByItem(item)
			szItemName = UIHelper.GBKToUTF8(szItemName)
			local bCheckSearch = self.szSearchkey and self.szSearchkey ~= "" and MatchString(szItemName, self.szSearchkey)
			bCheckSearch = bCheckSearch or not self.szSearchkey or self.szSearchkey == ""
			if bCheckSearch then
				local tBagItem = {
					nBox = tbItemInfo.nBox,
					nIndex = tbItemInfo.nIndex,
				}
				table.insert(self.tBagItemInfoList, tBagItem)
			end
		end
    end
	table.sort(self.tBagItemInfoList, function (lhBagItem, rhBagItem)
		local lhItem = ItemData.GetItemByPos(lhBagItem.nBox, lhBagItem.nIndex)
		local rhItem = ItemData.GetItemByPos(rhBagItem.nBox, rhBagItem.nIndex)
		local lhWeight = self:GetToppingBagItemValue(lhItem, lhBagItem.nBox, lhBagItem.nIndex)
		local rhWeight = self:GetToppingBagItemValue(rhItem, rhBagItem.nBox, rhBagItem.nIndex)

		return lhWeight > rhWeight
	end)
	UIHelper.SetString(self.LabelEmptyDescibe, "没有可以出售的物品")
	self:ClearCurrency()
	UIHelper.SetVisible(self.WidgetEmpty, #self.tBagItemInfoList == 0)
	UIHelper.SetVisible(self.WidgetCard, #self.tBagItemInfoList > 0)

	local nRowCount = math.ceil(#self.tBagItemInfoList/nColumnCount)
	UIHelper.TableView_init(self.TableViewOnSell, nRowCount, PREFAB_ID.WidgetSellOutRow_PercentAnchor)
	UIHelper.TableView_reloadData(self.TableViewOnSell)
	UIHelper.TableView_scrollToCellFitTop(self.TableViewOnSell, nRowCount, math.ceil((self.nLastSellIndex or 0)/nColumnCount), 0)
end

function UIPlayStoreView:RefreshWidgetBtns()
	UIHelper.SetVisible(self.LabelScreenNum, not self.bNoBtnScreen)
	UIHelper.SetVisible(self.BtnScreen, not self.bNoBtnScreen)
	UIHelper.SetVisible(self.WidgetBtnsSingleShop, not self.bNoBtnScreen)
	UIHelper.SetVisible(self.WidgetBtnsMulShop, not self.bNoBtnScreen)

	local nodeParent = UIHelper.GetParent(self.WidgetBtnsMulShop)
	UIHelper.LayoutDoLayout(nodeParent)
	nodeParent = UIHelper.GetParent(self.WidgetBtnsSingleShop)
	UIHelper.LayoutDoLayout(nodeParent)

	Timer.AddFrame(self, 1, function ()
		nodeParent = UIHelper.GetParent(self.BtnScreen)
		UIHelper.LayoutDoLayout(nodeParent)
	end)
end

function UIPlayStoreView:ForceToppingBagItem(tItemList)
	self.tForceToppingItemList = tItemList or {}
	self:RefreshBagWidget()
end

function UIPlayStoreView:GetToppingBagItemValue(item, nBox, nIndex)
	if not item then return 0 end
	local nTotalCount = #self.tForceToppingItemList
	for nIndex, tItem in ipairs(self.tForceToppingItemList) do
		if tItem.dwTabType == item.dwTabType and tItem.dwIndex == item.dwIndex then
			if item.nGenre ~= ITEM_GENRE.BOOK or tItem.nBookID == item.nBookID then
				return nTotalCount - nIndex + 1
			end
		end
	end
	return -(nBox*10000 + nIndex)
end

function UIPlayStoreView:OnHideAllHoverTips()
	self.bBtnScreenVisable = false
	UIHelper.SetVisible(self.WidgetAnchorCategoryTips, self.bBtnScreenVisable)
	self.bWidgetAnchorSellTipsVisable = false
	UIHelper.SetVisible(self.WidgetAnchorSellTips, self.bWidgetAnchorSellTipsVisable)
end

function UIPlayStoreView:ClearCurrency()
	UIHelper.RemoveAllChildren(self.LayoutCurrency)
	UIHelper.AddPrefab(PREFAB_ID.WidgetCurrency, self.LayoutCurrency)
	self.tCurrencyMark = {}
	self.tCostItemMark = {}
end

function UIPlayStoreView:RemarkCurrency(dwItemIndex)
	local tOtherInfo = GetShopItemBuyOtherInfo(self.nShopID, dwItemIndex)
	if not tOtherInfo then
		return
	end
	self.tCurrencyMark = self.tCurrencyMark or {}
	local CheckCurrency = function (nCurrencyCode, nRequire)
		if nRequire > 0 and not self.tCurrencyMark[nCurrencyCode] then
			local scriptCurrency = UIHelper.AddPrefab(PREFAB_ID.WidgetSingleCurrency, self.LayoutCurrency, nCurrencyCode)
			self.tCurrencyMark[nCurrencyCode] = scriptCurrency
		end
	end

	for szCurrencyName, szCurrencyIndex in pairs(ShopData.OtherInfo2CurrencyType) do
		local nRequire = tOtherInfo[szCurrencyName]
		if szCurrencyIndex and nRequire > 0 and not self.tCurrencyMark[szCurrencyIndex] then
			local scriptCurrency = UIHelper.AddPrefab(PREFAB_ID.WidgetOtherCurrency, self.LayoutCurrency)
			scriptCurrency:SetCurrencyType(szCurrencyIndex)
			scriptCurrency:HandleEvent()
			self.tCurrencyMark[szCurrencyIndex] = scriptCurrency
		end
	end
end

function UIPlayStoreView:RemarkCostItem(dwItemIndex)
	local tOtherInfo = GetShopItemBuyOtherInfo(self.nShopID, dwItemIndex)
	if not tOtherInfo then
		return
	end
	self.nRemarkCostTick = GetLogicFrameCount()
	if tOtherInfo.dwTabType and tOtherInfo.dwTabType > 0 then
		local bHasRemark = false
		for _, tMark in ipairs(self.tCostItemMark) do
			if tMark.dwTabType == tOtherInfo.dwTabType and tMark.dwIndex == tOtherInfo.dwIndex then
				bHasRemark = true
				break
			end
		end
		if not bHasRemark then
			table.insert(self.tCostItemMark, {
				dwTabType = tOtherInfo.dwTabType,
				dwIndex = tOtherInfo.dwIndex
			})
		end

		if #self.tCostItemMark > 2 then
			for _, tMark in ipairs(self.tCostItemMark) do
				if tMark.tScript then
					UIHelper.RemoveFromParent(tMark.tScript._rootNode, true)
					tMark.tScript = nil
				end
			end
		end
	end
end

function UIPlayStoreView:ShowBuyGoodsConfirm(nBuyCount)
	local goods = self.aGoods[self.nCurGoodsIndex]
	if goods and self.nShopMode == 'SHOP' then
		local bRemind = ItemData.IsPriceNeedRemind(self.nNpcID, goods.nShopID, goods.dwShopIndex, nBuyCount)
		local item = ShopData.GetItemByGoods(goods)
		if item and not self.tCustomData.bHideCanReturnTips and goods.bCanReturn then

			local scriptConfirm = UIHelper.ShowConfirm(g_tStrings.Shop.STR_CAN_RETURN_ITEM_BUY_CONFIRM, function (bOptionChecked)
				self.tCustomData.bHideCanReturnTips = bOptionChecked
				self:BuyGoods(nBuyCount)
			end)
			scriptConfirm:ShowTogOption(g_tStrings.Shop.STR_CAN_RETURN_ITEM_CHECK_BOX, false)
		elseif item and (item.nQuality >= 3 or bRemind) then
			local bNeedGray,_ = ShopData.CheckNeedGray(self.nNpcID, self.nShopID, goods, nBuyCount)
			UIMgr.Open(VIEW_ID.PanelPlayStoreConfirm, self.nNpcID, self.nShopID, self.dwPlayerRemoteDataID, goods, bNeedGray, nBuyCount, bRemind, function ()
				self:BuyGoods(nBuyCount)
			end)
		else
			self:BuyGoods(nBuyCount)
		end
	else
		self:BuyGoods(nBuyCount)
	end
end

function UIPlayStoreView:SwitchShop(nShopID)
	self:ClearGoods()
	self:ClearCells()
	self:OnHideAllHoverTips()
	UIHelper.SetString(self.LabelEmptyDescibe, "没有符合条件的商品")
	UIHelper.SetVisible(self.WidgetEmpty, false)
	if type(nShopID) == 'number' then
		self.nShopMode = 'SHOP'
		self.nShopID = nShopID
		if self.bHasHideShopGroup and self.tShopGroup then
			self:UpdateShopGroup(self.nNpcID, self.tShopGroup)
			self.bHasHideShopGroup = false
		end
		self.bNoBtnScreen = not self.bHasBtnScreen
		self:RefreshWidgetBtns()
		for nIndex, item in ipairs(GetShopAllItemInfoParam(nShopID)) do
			local dwShopIndex
			local dwCustomShopIndex = self.tCustomShop[nIndex]
			if self.bCustomShop and dwCustomShopIndex then
				dwShopIndex = dwCustomShopIndex
			else
				dwShopIndex = item.dwItemInfoIndex
			end
			if not self.bCustomShop or dwCustomShopIndex then
				local bNeedFame, bFameSatisfy, nFameNeedLevel, nFameID = GDAPI_ShopCheckFame(self.nTemplateID, g_pClientPlayer, item.nItemType, item.nItemIndex)
				if not bNeedFame then nFameNeedLevel = nil end
				self:AddGoods({
					nShopID     = nShopID             ,
					dwShopIndex = dwShopIndex		  ,
					nItemType   = item.nItemType      ,
					nItemIndex  = item.nItemIndex     ,
					nDurability = item.nDurability    , --耐久度，当道具是书籍的时用来查询书籍ID dwBookID, dwSubID = GlobelRecipeID2BookID(dwRecipeID)
					bCanReturn 	= item.bCanReturn	  , --是否可以退货
					nFameID		= nFameID,
					bNeedFame	= bNeedFame,
					bFameSatisfy = bFameSatisfy,
					nFameNeedLevel = nFameNeedLevel	,
					bCustomShop = self.bCustomShop	,
				}, false)
			end
		end
	elseif nShopID == 'BUY_BACK' then
		if self.tShopGroup then
			self:HideShopGroup()
			self.bHasHideShopGroup = true
		end
		self.bNoBtnScreen = true
		self:RefreshWidgetBtns()
		self.nShopMode = 'BUY_BACK'
		local player = GetClientPlayer()
		for i = 0, player.GetBoxSize(INVENTORY_INDEX.SOLD_LIST) - 1, 1 do
			local item = ItemData.GetPlayerItem(player, INVENTORY_INDEX.SOLD_LIST, i)
			if item then
				self:AddGoods({
					nShopID     = 'BUY_BACK'          ,
					dwShopIndex = i                   ,
					nItemType   = item.dwTabType      ,
					nItemIndex  = item.dwIndex        ,
				}, true)
			end
		end
	elseif nShopID == 'BUY_BACK_ADVANCED' then
		if self.tShopGroup then
			self:HideShopGroup()
			self.bHasHideShopGroup = true
		end
		self.bNoBtnScreen = true
		self:RefreshWidgetBtns()
		self.nShopMode = 'BUY_BACK_ADVANCED'
		local player = GetClientPlayer()
		for i = 0, player.GetBoxSize(INVENTORY_INDEX.TIME_LIMIT_SOLD_LIST) - 1, 1 do
			local item = ItemData.GetPlayerItem(player, INVENTORY_INDEX.TIME_LIMIT_SOLD_LIST, i)
			if item then
				self:AddGoods({
					nShopID     = 'BUY_BACK_ADVANCED' ,
					dwShopIndex = i                   ,
					nItemType   = item.dwTabType      ,
					nItemIndex  = item.dwIndex        ,
				}, true)
			end
		end
	end

	if type(nShopID) == 'number' then
		self:GeneratePervFilter() 			-- 按照交互设计，第一次需要生成全部筛选项
		self:GeneratePervFilter(true) 		-- 第二次生成进行默认项勾选
		self.tSelector = CopyTable(self.tPervSelector)
		self:ApplySearchFilter()
		self:ApplySelector()
		self:QueryAllData()
	end
end

function UIPlayStoreView:ClearGoods()
	self.tGoodsSelected = nil -- 选中的商品
	self.aAllGoods     = {} -- 整个商店的商品
	self.aFilterGoods  = {} -- 关键字过滤后的商品
	self.aPrevGoods	   = {} -- 预筛选时的商品(用于置灰筛选项)
	self.aGoods        = {} -- 条件过滤之后的商品（实际显示的商品列表）
	self.aSearchByShopIndexGoods = {} --通过dwShopIndex索引的商品列表
end

function UIPlayStoreView:AddGoods(goods, bSoldList)
	goods.tSelector = {}
	goods.nOriginalIndex = #self.aAllGoods
	if not bSoldList then
		GenerateGoodsSelector(goods)
	end
	table.insert(self.aGoods, goods)
	table.insert(self.aPrevGoods, goods)
	table.insert(self.aFilterGoods, goods)
	table.insert(self.aAllGoods, goods)
	self.aSearchByShopIndexGoods[goods.dwShopIndex] = goods
end

function UIPlayStoreView:BuyGoods(nBuyCount)
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

		local _, nMaxCount, nDefaultCount  = CanMutiBuy(goods, self.aShopInfo)
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

function UIPlayStoreView:AutoBuyGoods()
	local bInBuyCD = ShopData.InBuyCD()
	if bInBuyCD then return end
	if not self.tBuyParams then return end

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

local function GetMaxCount(item, nMaxCount, tPrice)
	if nMaxCount then
		nMaxCount = math.min(nMaxCount, item.nMaxStackNum * ITEM_MAX_MULTIPLE)
	else
		nMaxCount = item.nMaxStackNum * ITEM_MAX_MULTIPLE
	end

	if item.nMaxExistAmount > 0 then
		nMaxCount = math.min(item.nMaxExistAmount, nMaxCount)
	end
	local tMoney = PackMoney(100000, 0, 0)
	local nCount = MoneyOptDivMoney(tMoney, tPrice)

	nMaxCount = math.min(nCount, nMaxCount)
	return nMaxCount
end

local function GetBuyCountInfo(item, nMaxCount, tPrice)
	local nDefaultCount = 0
	if (item.bCanStack or item.nGenre == ITEM_GENRE.BOOK) and item.nMaxStackNum > 1 then
		if nMaxCount < 0 then
			nMaxCount = GetMaxCount(item, nil, tPrice)
			nDefaultCount = item.nMaxStackNum
		else
			nDefaultCount = math.min(nMaxCount, item.nMaxStackNum)
			nMaxCount = GetMaxCount(item, nMaxCount, tPrice)
		end

		if not item.bCanStack and item.nGenre == ITEM_GENRE.BOOK then --??规则不明，照搬原先的
			nMaxCount = math.min(MAX_BOOK_NUM, nMaxCount)
		end
	else
		nMaxCount = 1
		nDefaultCount = 1
	end

	return nMaxCount, nDefaultCount
end

function AutomaticSell(nNpcID, nShopID, player)
	local tPackageIndex = {
		INVENTORY_INDEX.PACKAGE,
		INVENTORY_INDEX.PACKAGE1,
		INVENTORY_INDEX.PACKAGE2,
		INVENTORY_INDEX.PACKAGE3,
		INVENTORY_INDEX.PACKAGE4,
		INVENTORY_INDEX.PACKAGE_MIBAO,
	}
    local tIndex = tPackageIndex
	for _ , dwBox2 in pairs(tIndex) do
		local nSize = player.GetBoxSize(dwBox2) - 1
	       for dwX2 = 0, nSize, 1 do
			local item = ItemData.GetPlayerItem(player, dwBox2, dwX2)
			if item and item.nQuality == 0 and item.bCanTrade then
				local nCount = item.nStackNum
				SellItem(nNpcID, nShopID, dwBox2, dwX2, nCount)
			end
		end
	end
end

function CanMutiBuy(goods, aShopInfo)
	local item, bItem = ShopData.GetItemByGoods(goods)
	if not bItem or not item then
		return false
	end
	if type(goods.nShopID) ~= "number" then
		return true, 1,1
	end
	local nMaxCount = GetShopItemCount(goods.nShopID, goods.dwShopIndex)
	if not nMaxCount then
		return false
	end
	local tPrice = GetShopItemBuyPrice(goods.nShopID, goods.dwShopIndex) or {nGold=0, nSilver=0, nCopper=0}
	local nFreeSize = GetFreeItemSizeInBag(goods.nShopID, goods.dwShopIndex)

	nMaxCount = math.min(nMaxCount, nFreeSize)
	if nMaxCount<0 then
		nMaxCount = nFreeSize
	end
	local nMaxCount, nDefaultCount = GetBuyCountInfo(item, nMaxCount, tPrice)

	if aShopInfo then
		if aShopInfo.nGobalLimitCount > 0 and nMaxCount > aShopInfo.nGobalLimitCount then
			nMaxCount = aShopInfo.nGobalLimitCount
		end

		if aShopInfo.nPlayerLeftCount > 0 and nMaxCount > aShopInfo.nPlayerLeftCount then
			nMaxCount = aShopInfo.nPlayerLeftCount
		end
	end
	return (item.nGenre ~= ITEM_GENRE.EQUIPMENT or item.nSub == EQUIPMENT_SUB.ARROW) and nMaxCount > 1, nMaxCount, nDefaultCount
end

function GoldSilverAndCopperToMoney(nGold, nSilver, nCopper)
	local nMoney = 0
	if nGold>0 then
		nMoney = nGold*10000+nSilver*100+nCopper
	elseif nGold == 0 then
		if nSilver>0 then
			nMoney = nSilver * 100 + nCopper;
		elseif nSilver == 0 then
			nMoney = nCopper
		else
			nMoney = -(-nSilver * 100 + nCopper)
		end
	else
		nMoney = -(-nGold * 10000 + nSilver * 100 + nCopper);
	end

	return nMoney
end

function UIPlayStoreView:QueryAllData()
	local tTables = {}
	local tIndexTable = {}
	for _, goods in ipairs(self.aGoods) do
		if type(goods.nShopID) == 'number' then
			table.insert(tIndexTable, goods.dwShopIndex)
		end
		if #tIndexTable >= MAX_SHOP_QUERY_ITEM_COUNT-1 then
			table.insert(tTables, tIndexTable)
			tIndexTable = {}
		end
	end
	if #tIndexTable > 0 then
		table.insert(tTables, tIndexTable)
	end

	for _,indexTable in ipairs(tTables) do
		QueryRequestShopItems(self.nShopID, indexTable)
	end
end

function UIPlayStoreView:ClearCells()
	self.nCurGoodsIndex = 0
	self.scriptGoodsMap = {}

	self.dwFindMatchTabType = nil
	self.dwFindMatchIndex = nil

	self.bNeedRefresh = true
    UIHelper.RemoveAllChildren(self.ScrollBag)
end

function UIPlayStoreView:UpdateCell()
	self:ClearCells()
	self:QueryAllData()
end

function UIPlayStoreView:UpdateBuyBackCell()
	self:ClearCells()
end

function UIPlayStoreView:UpdateSelectedGoodsDetails()
	if self.bOnOpenBag then
		return
	end
	local hItem,bItem
    if self.nCurGoodsIndex and self.nCurGoodsIndex > 0 then
		local scriptGoods = self.scriptGoodsMap[self.nCurGoodsIndex]
		local goods = self.aGoods[self.nCurGoodsIndex]
        hItem, bItem = ShopData.GetItemByGoods(goods)
		local bCanShow = type(goods.nShopID) ~= "number" or self.nShopID == goods.nShopID
        if bItem and bCanShow then
			UIHelper.SetVisible(self.WidgetCard, true)
			self.scriptItemTip = self.scriptItemTip or UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetCard)
			self.scriptItemTip:SetShopInfo(nil)
			self.scriptItemTip:SetExpireTime(nil)
			self.scriptItemTip:SetShopTips(nil)
			self.scriptItemTip:IsPlayStore(true)
			self.scriptItemTip:SetPlayerID(PlayerData.GetPlayerID())
			self.scriptQuantityController = self.scriptQuantityController or UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipQuantityController, self.scriptItemTip.LayoutContentAll)
			self.WidgetItemTipQuantityController = self.scriptQuantityController._rootNode

			self.scriptItemTip.szBindSource = "shop"
			self.scriptItemTip:HidePreviewBtn(true)
			self.scriptItemTip:SetPlayAniEnabled(false)
			UIHelper.SetAnchorPoint(self.scriptItemTip._rootNode, 0.5, 1)
			UIHelper.SetPosition(self.scriptItemTip._rootNode, 0, 0)
			UIHelper.SetVisible(self.WidgetSellItem, false)
			UIHelper.SetVisible(self.WidgetItemTipQuantityController, true)

			local tbShopItemInfo = GetShopItemInfo(goods.nShopID, goods.dwShopIndex)
			self.scriptItemTip:SetBeginSellTime(0)
			local bWaitSell = tbShopItemInfo and tbShopItemInfo.nBeginSellTime > os.time()
			if bWaitSell then
				self.scriptItemTip:SetBeginSellTime(tbShopItemInfo.nBeginSellTime)
			end

			if scriptGoods and scriptGoods.tbGoods.dwShopIndex == goods.dwShopIndex then
				scriptGoods:OnEnter(self.nNpcID, self.nShopID, self.dwPlayerRemoteDataID, goods)
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
				local _, nMaxCount, _ = CanMutiBuy(goods, self.aShopInfo)				
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
				self:RefreshItemTipsScrollViewHeight()
			end
        end
    end
end

function UIPlayStoreView:ClearItemTips()
	-- UIHelper.SetVisible(self.WidgetCard, false)
	-- if self.scriptItemTip then self.scriptItemTip:RemoveAllChildren() end
end

function UIPlayStoreView:UpdateSelectedItemDetails()
	local item = ItemData.GetItemByPos(self.tbSelected.tbPos.nBox, self.tbSelected.tbPos.nIndex)
	if not item then
		return
	end

	self.scriptItemTip = self.scriptItemTip or UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetCard)
	self.scriptWidgetSellItem = self.scriptWidgetSellItem or UIHelper.AddPrefab(PREFAB_ID.WidgetSellItemController, self.scriptItemTip.LayoutContentAll)
	self.WidgetSellItem = self.scriptWidgetSellItem._rootNode

	UIHelper.SetAnchorPoint(self.scriptItemTip._rootNode, 0.5, 1)
	UIHelper.SetPosition(self.scriptItemTip._rootNode, 0, 0)
	UIHelper.SetVisible(self.WidgetSellItem, true)
	UIHelper.SetVisible(self.WidgetItemTipQuantityController, false)
	-- 初始化道具tips
	self.scriptItemTip:SetShopInfo(nil)
	self.scriptItemTip:SetExpireTime(nil)
	self.scriptItemTip:SetShopTips(nil)
	self.scriptItemTip:HidePreviewBtn(true)
	self.scriptItemTip:SetPlayAniEnabled(false)
	self.scriptItemTip:SetForbidAutoShortTip(true)
	self.scriptItemTip:SetFunctionButtons({})
	self.scriptItemTip:OnInit(self.tbSelected.tbPos.nBox, self.tbSelected.tbPos.nIndex)
	self.scriptItemTip:SetBtnState({})
	if self.scriptItemTip.scriptItemIcon then
		self.scriptItemTip.scriptItemIcon:ShowEquipScoreArrow(true)
	end
	-- 初始化出售面板
	self.scriptWidgetSellItem:OnEnter(self.nNpcID, self.nShopID, self.tbSelected.tbPos.nBox, self.tbSelected.tbPos.nIndex, self.nLastSellCount)
	self.scriptWidgetSellItem:SetSelectChangeCallback(function (nSellCount)
		self.nLastSellCount = nSellCount
		self:SellSelectedItem(nSellCount)
	end)
	UIHelper.SetVisible(self.WidgetSellItem, true)

	self:RefreshItemTipsScrollViewHeight()
end

function UIPlayStoreView:RefreshItemTipsScrollViewHeight()
	local nScrollViewContentWidgetTop = UIHelper.GetHeight(self.scriptItemTip.WidgetAnchorTop)
	local nLayoutContentSpaceY = UIHelper.LayoutGetSpacingY(self.scriptItemTip.LayoutContentAll)

	local nChildenCount = UIHelper.GetVisableChildrenCount(self.scriptItemTip.LayoutContentAll)
	local nDeltaHeight = UIHelper.GetHeight(self.WidgetCard) - nScrollViewContentWidgetTop - nLayoutContentSpaceY*nChildenCount

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

function UIPlayStoreView:GeneratePervFilter(bAutoSelect)
	local bFirstGenerate = not self.tPervSelector
	if bFirstGenerate then
		self.tPervSelector = CopyTable(self.tSelector)
	end
	local nSelectorCount = 0
	local tbSelected = {}
	self.tSelectorClassID2SelectorName = {}
	local tAllIndexs = {}
	for key,_ in pairs(FilterDef.Shop) do
		if(type(key)=="number") then
			table.insert(tAllIndexs, key)
		end
	end
	for _, nIndex in ipairs(tAllIndexs) do
		if bFirstGenerate then
			FilterDef.Shop[nIndex] = nil
		else
			local tFilterClass = FilterDef.Shop[nIndex]
			tFilterClass.tbDisableList = {}
			for nIndex,_ in ipairs(tFilterClass.tbList) do
				tFilterClass.tbDisableList[nIndex] = true
			end
		end
	end
	if self.tPervSelector and self.nShopMode == 'SHOP' then
		-- UI操作
		local UpdateEach = function(szSelectorName)
			local aSelector = self:GenerateSelector(self.tPervSelector, self.aPrevGoods, szSelectorName, bAutoSelect)
			if #aSelector > 0 then
				nSelectorCount = nSelectorCount + 1
				self.tSelectorClassID2SelectorName[nSelectorCount] = szSelectorName
				tbSelected[nSelectorCount] = {}
				local tFilterClass = FilterDef.Shop[nSelectorCount]
				if bFirstGenerate then
					tFilterClass =  {
						szType = FilterType.CheckBox,
						szSubType = FilterSubType.Small,
						bAllowAllOff = true,
						bResponseImmediately = false,
						bDispatchChangedEvent = true,
						bHideSingleOption = true,
						szTitle = SELECTOR_TITLE[szSelectorName],
						tbList = {},
						tbValList = {},
						tbName2Index = {},
						tbDisableList = {},
						tbDefault = {aSelector.nDefaultSelectorID},
					}
				end
				for nSelectorID, selector in ipairs(aSelector) do
					local szName = GetSelectorText(szSelectorName, selector.value or selector)
					if bFirstGenerate then
						tFilterClass.tbList[nSelectorID] = szName
						tFilterClass.tbName2Index[szName] = nSelectorID
						tFilterClass.tbValList[nSelectorID] = selector.value or selector
					end
					local nTbIndex = tFilterClass.tbName2Index[szName]
					tFilterClass.tbDisableList[nTbIndex] = nil
					if selector.bSelected then
						table.insert(tbSelected[nSelectorCount], nTbIndex)
					end
				end
				FilterDef.Shop[nSelectorCount] = tFilterClass
			end

			return #aSelector > 1
		end

		local bHasSelector = false
		-- 门派过滤器
		if self.tSelector.bSchoolSelector then
			bHasSelector = UpdateEach('SchoolSelector') or bHasSelector
		end
		-- 心法过滤器
		if self.tSelector.bKungfuSelector then
			bHasSelector = UpdateEach('KungfuSelector') or bHasSelector
		end
		-- 部位过滤器
		if self.tSelector.bEquipPosSelector then
			bHasSelector = UpdateEach('EquipPosSelector') or bHasSelector
		end
		-- 属性过滤器
		if self.tSelector.bAttriSelector then
			bHasSelector = UpdateEach('AttriSelector') or bHasSelector
		end
		-- 等级过滤器
		if self.tSelector.bRequireLevelSelector then
			bHasSelector = UpdateEach('RequireLevelSelector') or bHasSelector
		end
		-- 品质过滤器
		if self.tSelector.bLevelSelector then
			bHasSelector = UpdateEach('LevelSelector') or bHasSelector
		end
		-- 品级过滤器
		if self.tSelector.bQualitySelector then
			bHasSelector = UpdateEach('QualitySelector') or bHasSelector
		end
		-- 装备分过滤器
		if self.tSelector.bScoreSelector then
			bHasSelector = UpdateEach('ScoreSelector') or bHasSelector
		end
		-- 技能过滤器
		if self.tSelector.bSkillSelector then
			bHasSelector = UpdateEach('SkillSelector') or bHasSelector
		end
		-- 已读未读过滤器
		if self.tSelector.bHaveReadSelector then
			bHasSelector = UpdateEach('HaveReadSelector') or bHasSelector
		end
		-- 是否已收集家具
		if self.tSelector.bCollectFurniture then
			bHasSelector = UpdateEach('CollectFurniture') or bHasSelector
		end

		if not bHasSelector then
			self.bNoBtnScreen = true
			self:RefreshWidgetBtns()
		end
	end

	FilterDef.Shop.SetRunTime(tbSelected)
	if bAutoSelect then
		self.tbDefaultSelected = tbSelected
	end

	
end

function UIPlayStoreView:RedirectFilter(scriptView, nLastChoosedIndex, nLastChoosedSubIndex)
	local nTotalHeight = 0
	local nTargetHeight = 50
	for nIndex, oneDef in ipairs(FilterDef.Shop) do
		if oneDef and oneDef.tbList then
			nTotalHeight = nTotalHeight + 50
			if nIndex == nLastChoosedIndex then
				nTargetHeight = nTotalHeight + (nLastChoosedSubIndex+1)*60
			end
			nTotalHeight = nTotalHeight + 60 * #oneDef.tbList
		end
	end

	local nPercent = nTargetHeight/nTotalHeight*100
	UIHelper.ScrollToPercent(scriptView.ScrollViewType, nPercent, 0)
end

function UIPlayStoreView:IsDefaultSelected(tbSelected)
	-- if not self.tbDefaultSelected or not tbSelected then
	-- 	return false
	-- end

	-- for nClassID, nChoosenIDList in ipairs(self.tbDefaultSelected) do
	-- 	if not tbSelected[nClassID] then
	-- 		return false
	-- 	end
	-- 	if #tbSelected[nClassID] ~= #nChoosenIDList then
	-- 		return false
	-- 	end
	-- 	for nIndex, nChoosenID in ipairs(nChoosenIDList) do
	-- 		if nChoosenID ~= tbSelected[nClassID][nIndex] then
	-- 			return false
	-- 		end
	-- 	end
	-- end
	-- return true
	if not tbSelected then return true end

	for _, nChoosenIDList in ipairs(tbSelected) do
		if #nChoosenIDList ~= 0 then return false end
	end

	return true
end

function UIPlayStoreView:UpdateAllCells()
	self.bNeedRefresh = true
	self:UpdateSelectedGoodsDetails()
end

function UIPlayStoreView:UpdateCurCells()
	for _, scriptCell in pairs(self.scriptGoodsMap) do
		scriptCell:OnEnter(self.nNpcID, self.nShopID, self.dwPlayerRemoteDataID, scriptCell.tbGoods)
	end
	self:UpdateSelectedGoodsDetails()
end

function UIPlayStoreView:RefreshBuyBackCell()
	if self.nShopMode ~= "SHOP" and not self.bOnOpenBag then
		self:SwitchShop(self.nShopMode)
		self:UpdateBuyBackCell()
		self:UpdateSelectedGoodsDetails()
	end
end

-------------------------------筛选数据-----------------------------------------
function SplitStringS(szFullString, szSeparator)
	local nFindStartIndex = 1
	local nSplitIndex = 1
	local nSplitArray = {}
	while true do
	   local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex)
	   if not nFindLastIndex then
		nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))
		break
	   end
	   nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)
	   nFindStartIndex = nFindLastIndex + string.len(szSeparator)
	   nSplitIndex = nSplitIndex + 1
	end
	return nSplitArray
end
-- 获取筛选项文字
function GetSelectorText(szSelectorName, oValue)
	-- 默认标题
	if oValue == nil then
		return SELECTOR_TITLE[szSelectorName]
	end
	-- 对应选项标题
	if szSelectorName == 'SchoolSelector' then
		local szName = Table_GetSkillSchoolName(oValue)
		szName = UIHelper.GBKToUTF8(szName)
		return szName
	elseif szSelectorName == 'KungfuSelector' then
		local szName = Table_GetSkillName(oValue, 1)
		szName = UIHelper.GBKToUTF8(szName)
		return szName
	elseif szSelectorName == 'EquipPosSelector' then
		return g_tStrings.tEquipTypeNameTable[oValue]
	elseif szSelectorName == 'AttriSelector' then
		return UIHelper.GBKToUTF8(oValue)
	elseif szSelectorName == 'SkillSelector'or
	szSelectorName == 'HaveReadSelector' or
	szSelectorName == 'CollectFurniture'then -- 简单枚举类选择器
		return oValue
	elseif szSelectorName == 'ScoreSelector' or
	szSelectorName == 'RequireLevelSelector' or
	szSelectorName == 'LevelSelector' then -- 数值范围类选择器
		local szText = tostring(oValue.minValue) .. '~' .. tostring(oValue.maxValue)
		if oValue.minValue == oValue.maxValue then
			szText = tostring(oValue.minValue)
		end
		if szSelectorName == 'RequireLevelSelector' then
			szText = szText .. g_tStrings.Shop.STR_LEVEL
		end
		return szText
	elseif szSelectorName == 'QualitySelector' then
		local szText = GetItemQualityCaption(oValue)
		return szText
	end
end

-- 生成商品筛选标签
function GenerateGoodsSelector(goods, szSelectorName)
	local iteminfo = ShopData.GetItemInfoByGoods(goods)

	if not szSelectorName then
		goods.tSelector = {}
	end

	-- 门派标签和心法标签都固定记在货物上，方便做跳转
	goods.tForceMatchMap = {}
	goods.tKungfuMatchMap = {}
	local t = TabHelper.GetEquipRecommend(iteminfo.nRecommendID)
	if t and t.desc and t.desc ~= "" then
		for _, v in ipairs(SplitStringS(t.kungfu_ids, "|")) do
			local dwKungfuID = tonumber(v)
			if dwKungfuID then
				if dwKungfuID == 0 then
					goods.tForceMatchMap[0] = true  -- 通用心法
					goods.tKungfuMatchMap[0] = true -- 通用门派
					break
				else
					goods.tKungfuMatchMap[dwKungfuID] = true
				end
			end
			local dwForceID = Kungfu_GetType(dwKungfuID)
			if dwForceID then
				goods.tForceMatchMap[dwForceID] = true
			end
		end
	end

	if not szSelectorName or szSelectorName == 'SchoolSelector' or szSelectorName == 'KungfuSelector' then
		goods.tSelector['SchoolSelector']  = {} -- 门派标签
		goods.tSelector['KungfuSelector'] = {} -- 心法标签
		local t = TabHelper.GetEquipRecommend(iteminfo.nRecommendID)
		if t and t.desc and t.desc ~= "" then
			for _, v in ipairs(SplitStringS(t.kungfu_ids, "|")) do
				local dwKungfuID = tonumber(v)
				if dwKungfuID then
					if dwKungfuID == 0 then
						goods.tSelector['SchoolSelector'][''] = true  -- 通用心法
						goods.tSelector['KungfuSelector'][''] = true -- 通用门派
						break
					else
						goods.tSelector['KungfuSelector'][dwKungfuID] = true
					end
				end
				local dwSchoolID = Kungfu_GetBelongSchoolType(dwKungfuID)
				if dwSchoolID then
					goods.tSelector['SchoolSelector'][dwSchoolID] = true
				end
			end
		end
	end

	if not szSelectorName or szSelectorName == 'EquipPosSelector' or szSelectorName == 'AttriSelector' then
		if iteminfo.nGenre == ITEM_GENRE.EQUIPMENT then
			goods.tSelector['EquipPosSelector'] = {} -- 装备位置标签
			if iteminfo.nGenre == ITEM_GENRE.EQUIPMENT then
				goods.tSelector['EquipPosSelector'][iteminfo.nSub] = true
			end

			goods.tSelector['AttriSelector'] = {} -- 装备属性标签
			local baseAttib = iteminfo.GetBaseAttrib()
			if baseAttib then
				for k, v in pairs(baseAttib) do
					--v.nID,  v.nValue1, v.nValue2
					local szCategory = Table_GetCategoryByAttributeID(v.nID)
					if szCategory then
						goods.tSelector['AttriSelector'][szCategory] = true
					end
				end
			end
			local magicAttrib = GetItemMagicAttrib(iteminfo.GetMagicAttribIndexList())
			if magicAttrib then
				for k, v in pairs(magicAttrib) do
					--v.nID,  v.nValue1, v.nValue2
					local szCategory = Table_GetCategoryByAttributeID(v.nID)
					if szCategory then
						goods.tSelector['AttriSelector'][szCategory] = true
					end
				end
			end
		end
	end

	-- 装备需求等级标签
	if not szSelectorName or szSelectorName == 'RequireLevelSelector' then
		if iteminfo.nGenre == ITEM_GENRE.EQUIPMENT then
			goods.tSelector['RequireLevelSelector'] = GetItemInfoRequireLevel(goods.nItemType, iteminfo)
		end
	end

	-- 装备品质标签
	if not szSelectorName or szSelectorName == 'QualitySelector' then
		goods.tSelector['QualitySelector'] = { [iteminfo.nQuality] = true }
	end

	-- 装备品级标签
	if not szSelectorName or szSelectorName == 'LevelSelector' then
		if iteminfo.nGenre == ITEM_GENRE.EQUIPMENT then
			goods.tSelector['LevelSelector'] = iteminfo.nLevel
		end
	end

	-- 装备分标签
	if not szSelectorName or szSelectorName == 'ScoreSelector' then
		if iteminfo.nGenre == ITEM_GENRE.EQUIPMENT then
			goods.tSelector['ScoreSelector'] = iteminfo.nBaseScore -- + iteminfo.nStrengthScore + iteminfo.nMountsScore
		end
	end

	-- 秘籍技能标签
	if not szSelectorName or szSelectorName == 'SkillSelector' then
		if iteminfo.nGenre == ITEM_GENRE.MATERIAL and iteminfo.nSub == ITEM_SUBTYPE_RECIPE then
			goods.tSelector['SkillSelector'] = {}
			iteminfo.szName:gsub(g_tStrings.Shop.STR_SKILLNAME_MATCH_EXP, function(_, szSkillName, _)
				goods.tSelector['SkillSelector'][szSkillName] = true
			end)
		end
	end

	-- 已阅读标签
	if not szSelectorName or szSelectorName == 'HaveReadSelector' then
		if iteminfo.nGenre == ITEM_GENRE.MATERIAL and iteminfo.nSub == ITEM_SUBTYPE_RECIPE then
			if PlayerData.IsMystiqueRecipeRead(iteminfo, true) then
				goods.tSelector['HaveReadSelector'] = { [g_tStrings.Shop.STR_ALREADY_READ] = true }
			else
				goods.tSelector['HaveReadSelector'] = { [g_tStrings.Shop.STR_UNREAD] = true }
			end
		elseif iteminfo.nGenre == ITEM_GENRE.BOOK then
			-- local nDurability = GetShopItemInfo(goods.nShopID, goods.dwShopIndex).nDurability
			local nBookID, nSegmentID = GlobelRecipeID2BookID(goods.nDurability)
			if GetClientPlayer().IsBookMemorized(nBookID, nSegmentID) then
				goods.tSelector['HaveReadSelector'] = { [g_tStrings.Shop.STR_ALREADY_READ] = true }
			else
				goods.tSelector['HaveReadSelector'] = { [g_tStrings.Shop.STR_UNREAD] = true }
			end
		end
	end

	-- 已收集标签
	if not szSelectorName or szSelectorName == 'CollectFurniture' then
		if iteminfo.nGenre == ITEM_GENRE.HOMELAND then
			local nFurnitureType = iteminfo.nFurnitureType or HS_FURNITURE_TYPE.FURNITURE
			if nFurnitureType == HS_FURNITURE_TYPE.FURNITURE then
				local bCollected = HomelandEventHandler.IsFurnitureCollected(iteminfo.dwFurnitureID)
				if bCollected then
					goods.tSelector['CollectFurniture'] = { [g_tStrings.STR_FURNITURE_TIP_OWN_STATE_COLLECTED] = true }
				else
					goods.tSelector['CollectFurniture'] = { [g_tStrings.STR_FURNITURE_TIP_OWN_STATE_NOT_COLLECTED] = true }
				end
			end
		end
	end

	FixGoodsSelector(goods, szSelectorName)
end

-- 人工修正部分商品的筛选
function FixGoodsSelector(goods, szSelectorName)
	local itemInfo = ShopData.GetItemInfoByGoods(goods)
	if not itemInfo then return end

	local nRecommendID = itemInfo.nRecommendID or 0
	-- 秘境商店-绝世装备-珠联璧合，新增藏剑门派筛选和山居剑意内功筛选，勾选则显示非装备商品。
	local ZHU_LIAN_BI_HE_SHOP_ID = 1401
	if ZHU_LIAN_BI_HE_SHOP_ID == goods.nShopID and nRecommendID == 0 then
		goods.tSelector['SchoolSelector'][BELONG_SCHOOL_TYPE.CANG_JIAN]  = true
		goods.tSelector['KungfuSelector'][10145] = true
	end
end

-- 生成筛选器
function UIPlayStoreView:GenerateSelector(tSelector, aFilterGoods, szSelectorName, bAutoSelect)
	-- 暂时认为自动筛选
	if not tSelector[szSelectorName] then
		tSelector[szSelectorName] = { nSelected = 0}
	end

	if szSelectorName == 'SchoolSelector' or
	szSelectorName == 'KungfuSelector' or
	szSelectorName == 'EquipPosSelector' or
	szSelectorName == 'AttriSelector' or
	szSelectorName == 'QualitySelector' or
	szSelectorName == 'SkillSelector' or
	szSelectorName == 'HaveReadSelector' or
	szSelectorName == 'CollectFurniture' then -- 具体枚举类
		local tTmpSelector = {}
		-- 枚举商品的选择器标签
		local tResult = self:GetSelectorResult(tSelector, aFilterGoods, szSelectorName)
		for _, goods in ipairs(tResult) do
			if goods.tSelector[szSelectorName] and
			not goods.tSelector[szSelectorName][''] then -- 不是通用装备
				for tag, _ in pairs(goods.tSelector[szSelectorName]) do
					tTmpSelector[tag] = false
				end
			end
		end

		-- 处理之前选中的选项
		if tSelector[szSelectorName].nSelected > 0 then
			for _, selector in ipairs(tSelector[szSelectorName]) do
				if selector.bSelected then
					tTmpSelector[selector.value] = selector.bSelected
				end
			end
		end

		-- 建立新的筛选器结果
		local aSelector = { nSelected = 0 }
		for value, bSelected in pairs(tTmpSelector) do
			if bSelected then
				aSelector.nSelected = aSelector.nSelected + 1
			end
			table.insert(aSelector, { value = value, bSelected = bSelected })
		end

		-- 处理默认筛选项
		if bAutoSelect and tSelector.bAutoSelect then
			if szSelectorName == 'SchoolSelector' then
				for nSelectorID, selector in ipairs(aSelector) do
					if selector.value == PlayerData.GetMountBelongSchoolID() and not self.bEquipSet then
						selector.bSelected = true
						aSelector.nDefaultSelectorID = nSelectorID
						aSelector.nSelected = aSelector.nSelected + 1
					end
				end
			elseif szSelectorName == 'HaveReadSelector' then
				for nSelectorID, selector in ipairs(aSelector) do
					if selector.value == g_tStrings.Shop.STR_UNREAD then
						selector.bSelected = true
						aSelector.nDefaultSelectorID = nSelectorID
						aSelector.nSelected = aSelector.nSelected + 1
					end
				end
			end
		end

		-- 筛选器选项排序
		local sorter = SELECTOR_SORTER[szSelectorName]
		if sorter then
			local fnSort = nil
			if type(sorter) =="function" then
				fnSort = sorter
				table.sort(aSelector, sorter)
			else
				fnSort = function(s1, s2)
					local nIndex1 = sorter[s1.value]
					local nIndex2 = sorter[s2.value]
					if not nIndex2 then
						return false
					elseif nIndex2 and not nIndex1 then
						return true
					else
						return nIndex1 < nIndex2
					end
				end
			end
			table.sort(aSelector, fnSort)
		end

		-- 处理显示标题
		for _, selector in ipairs(aSelector) do
			if selector.bSelected then
				aSelector.szTitle = aSelector.szTitle or GetSelectorText(szSelectorName, selector.value)
				break
			end
		end
		tSelector[szSelectorName] = aSelector
	elseif szSelectorName == 'RequireLevelSelector' or
	szSelectorName == 'LevelSelector' or
	szSelectorName == 'ScoreSelector' then -- 范围值类
		-- 先取得所有取值枚举列表
		local tTmpSelector, tSelectorHash, nCount = {}, {}, 0
		for _, goods in ipairs(self:GetSelectorResult(tSelector, aFilterGoods, szSelectorName)) do
			if goods.tSelector[szSelectorName] then
				if tSelectorHash[goods.tSelector[szSelectorName]] == nil then
					nCount = nCount + 1
					table.insert(tTmpSelector, {
						minValue = goods.tSelector[szSelectorName],
						maxValue = goods.tSelector[szSelectorName],
					})
				end
				tSelectorHash[goods.tSelector[szSelectorName]] = false
			end
		end

		local aSelector = { nSelected = 0 }
		for _, selector in ipairs(tTmpSelector) do
			table.insert(aSelector, selector)
		end

		-- 对枚举值进行排序
		table.sort(aSelector, function(a, b)
			return a.minValue < b.minValue
		end)

		-- 处理默认筛选项
		if tSelector[szSelectorName].bFirstGenerate and tSelector.bAutoSelect then
			if szSelectorName == 'RequireLevelSelector' then
				for i = #aSelector, 1, -1 do
					local selector = aSelector[i]
					if selector.maxValue <= GetClientPlayer().nLevel then
						selector.bSelected = true
						break
					end
				end
			end
		end

		-- 如果枚举值超长的话 分段合并
		if nCount > 16 then
			local nStep = 2
			while nCount / nStep > 10 do
				nStep = nStep + 1
			end

			local nMod = 0
			local aNewSelector = { nSelected = 0 }
			for i, selector in ipairs(aSelector) do
				if nMod == 0 then
					local nOffset = #aSelector - i + 1
					if nOffset > nStep then
						nOffset = nStep
					end
					selector.maxValue = aSelector[i + nOffset - 1].maxValue
					table.insert(aNewSelector, selector)
				end

				nMod = nMod + 1
				if nMod == nStep then
					nMod = 0
				end
			end
			aSelector = aNewSelector
		end

		-- 处理之前选中的选项
		if tSelector[szSelectorName].nSelected > 0 then
			for _, selector_old in ipairs(tSelector[szSelectorName]) do
				if selector_old.bSelected then
					local bMatch = false
					for i, selector in ipairs(aSelector) do
						if (selector.minValue - selector_old.minValue) * (selector.maxValue - selector_old.maxValue) <= 0 then
							bMatch = true
							selector.bSelected = selector_old.bSelected
						elseif selector.minValue > selector_old.minValue or i == #aSelector then
							if (
							 (selector.minValue - selector.maxValue == 0 and selector_old.minValue - selector_old.maxValue == 0) or
							 (selector.minValue - selector.maxValue ~= 0 and selector_old.minValue - selector_old.maxValue ~= 0)
							) and not bMatch then
								table.insert(aSelector, i, selector_old)
							end
							break
						end
					end
				end
			end
			-- 再次对枚举值进行排序
			table.sort(aSelector, function(a, b)
				return a.minValue < b.minValue
			end)
		end

		-- 更新选择器选中项个数和选项标题
		for _, selector in ipairs(aSelector) do
			if selector.bSelected then
				aSelector.szTitle = aSelector.szTitle or GetSelectorText(szSelectorName, { minValue = selector.minValue, maxValue = selector.maxValue })
				aSelector.nSelected = aSelector.nSelected + 1
			end
		end
		tSelector[szSelectorName] = aSelector
	end

	return tSelector[szSelectorName]
end

-- 设置筛选器

function UIPlayStoreView:SetSelector(tSelector, szSelectorName, key, bSelected)
	local aSelector = tSelector[szSelectorName]
	if not aSelector then
		return
	end

	aSelector.nSelected = 0
	if type(key) == 'table' then
		for nSelectorID, selector in ipairs(aSelector) do
			if selector.minValue >= key.minValue and selector.maxValue <= key.maxValue then
				if bSelected == false or bSelected == true then
					selector.bSelected = bSelected
				else
					selector.bSelected = not selector.bSelected
				end
			end
			if selector.bSelected then
				aSelector.nSelected = aSelector.nSelected + 1
			end
		end
	elseif key ~= nil then
		for i, selector in ipairs(aSelector) do
			if selector.value == key then
				if bSelected == false or bSelected == true then
					selector.bSelected = bSelected
				else
					selector.bSelected = not selector.bSelected
				end
			end
			if selector.bSelected then
				aSelector.nSelected = aSelector.nSelected + 1
			end
		end
	else
		for i, selector in ipairs(aSelector) do
			selector.bSelected = bSelected
		end
		aSelector.nSelected = 0
	end
end
-- 获取筛选结果
function UIPlayStoreView:GetSelectorResult(tSelector, aFilterGoods, szIngoreSelectorName)
	local aGoods = {}
	for _, goods in ipairs(aFilterGoods) do
		table.insert(aGoods, goods)
	end
	-- 检查精确匹配类选择器
	local fnCheckEnumSelector = function(szSelectorName)
		local aSelector = tSelector[szSelectorName]
		if aSelector and szIngoreSelectorName ~= szSelectorName and aSelector.nSelected and aSelector.nSelected > 0 then
			for i=#aGoods, 1, -1 do
				local bShow, goods = false, aGoods[i]
				if goods.tSelector[szSelectorName] and
				goods.tSelector[szSelectorName][''] then -- 通用物品 全门派装备
					bShow = true
				else
					for _, selector in ipairs(aSelector) do
						if selector.bSelected and
						goods.tSelector[szSelectorName] and
						goods.tSelector[szSelectorName][selector.value] then
							bShow = true
							break
						end
					end
				end
				if not bShow then
					table.remove(aGoods, i)
				end
			end
		end
	end
	-- 检查范围类选择器
	local fnCheckRangeSelector = function(szSelectorName)
		local aSelector = tSelector[szSelectorName]
		if aSelector and szIngoreSelectorName ~= szSelectorName and aSelector.nSelected and aSelector.nSelected > 0 then
			for i=#aGoods, 1, -1 do
				local bShow, goods = false, aGoods[i]
				for _, selector in ipairs(aSelector) do
					if selector.bSelected then
						if goods.tSelector[szSelectorName] and
						goods.tSelector[szSelectorName] <= selector.maxValue and
						goods.tSelector[szSelectorName] >= selector.minValue then
							bShow = true
							break
						end
					end
				end
				if not bShow then
					table.remove(aGoods, i)
				end
			end
		end
	end
	fnCheckEnumSelector('SchoolSelector')         -- 门派过滤器
	fnCheckEnumSelector('KungfuSelector')        -- 心法过滤器
	fnCheckEnumSelector('EquipPosSelector')      -- 装备位置过滤器
	fnCheckEnumSelector('AttriSelector')         -- 属性过滤器
	fnCheckRangeSelector('RequireLevelSelector') -- 需求等级过滤器
	fnCheckRangeSelector('LevelSelector')        -- 装备品级过滤器
	fnCheckEnumSelector('QualitySelector')       -- 装备品质过滤器
	fnCheckRangeSelector('ScoreSelector')        -- 装备分数过滤器
	fnCheckEnumSelector('SkillSelector')         -- 秘籍技能过滤器
	fnCheckEnumSelector('HaveReadSelector')      -- 已读未读过滤器
	fnCheckEnumSelector('CollectFurniture') 	 -- 已收集未收集滤器

	return aGoods
end
-- 执行筛选（self.aFilterGoods -> self.aGoods）
function UIPlayStoreView:ApplySelector()
	if self.nShopMode == 'SHOP' then
		self.aGoods = self:GetSelectorResult(self.tSelector, self.aFilterGoods)
	else
		self.aGoods = {}
		for _, goods in ipairs(self.aFilterGoods) do
			table.insert(self.aGoods, goods)
		end
	end
	if not self.tSelector.bDisableSort or self.tSelector.bDisableSort == 0 then
		self:SortGoods()
	end

	self.bFiltered = not self:IsDefaultSelected(FilterDef.Shop.GetRunTime())
	if not self.bFiltered then
		UIHelper.SetSpriteFrame(self.ImgScreen, ShopData.szScreenImgDefault)
	else
		UIHelper.SetSpriteFrame(self.ImgScreen, ShopData.szScreenImgActiving)
	end

	UIHelper.SetString(self.LabelScreenNum, string.format("%d/%d", #self.aGoods, #self.aAllGoods))
end

function UIPlayStoreView:SortGoods()
	local player = GetClientPlayer()
	local tKungfuIDs = ForceIDToKungfuIDs(player.dwForceID)
	local tKungfus = {}
	for _, dwKungfuID in ipairs(tKungfuIDs) do
		local kungfu = GetSkill(dwKungfuID, 1)
		if kungfu then
			table.insert(tKungfus, kungfu)
		end
	end

	table.sort(self.aGoods, function(g1, g2)
		local itemInfo1 = ShopData.GetItemInfoByGoods(g1)
		local itemInfo2 = ShopData.GetItemInfoByGoods(g2)
		local bIsFit1, bIsFit2
		for _, kungfu in pairs(tKungfus) do
			bIsFit1 = bIsFit1 or IsItemFitKungfu(itemInfo1, kungfu)
			bIsFit2 = bIsFit2 or IsItemFitKungfu(itemInfo2, kungfu)
		end

		-- 按名望等级排
		if g1.nFameNeedLevel and g2.nFameNeedLevel and g1.nFameNeedLevel ~= g2.nFameNeedLevel then
			return g1.nFameNeedLevel > g2.nFameNeedLevel
		end

		-- 心法要求
		if bIsFit1 and not bIsFit2 then
			-- 1排在2前面
			return true
		elseif bIsFit2 and not bIsFit1 then
			-- 2排在1前面
			return false
		else
			-- 等级要求能否符合
			local bAccordLevel1 = GetItemInfoRequireLevel(g1.nItemType, itemInfo1) <= player.nLevel
			local bAccordLevel2 = GetItemInfoRequireLevel(g2.nItemType, itemInfo2) <= player.nLevel
			if bAccordLevel1 and not bAccordLevel2 then
				return true
			elseif bAccordLevel2 and not bAccordLevel1 then
				return false
			else
				-- 品质
				if itemInfo1.nQuality > itemInfo2.nQuality then
					return true
				elseif itemInfo1.nQuality < itemInfo2.nQuality then
					return false
				else
					-- 品级
					if itemInfo1.nLevel > itemInfo2.nLevel then
						return true
					elseif itemInfo1.nLevel < itemInfo2.nLevel then
						return false
					else
						-- 部位
						local nPos1, nPos2
						if itemInfo1.nGenre == ITEM_GENRE.EQUIPMENT then
							nPos1 = GOODS_SORTER['EquipPosSelector'][itemInfo1.nSub]
						end
						if itemInfo2.nGenre == ITEM_GENRE.EQUIPMENT then
							nPos2 = GOODS_SORTER['EquipPosSelector'][itemInfo2.nSub]
						end
						if nPos1 and nPos2 and nPos1 ~= nPos2 then
							return nPos1 < nPos2
						elseif nPos1 and not nPos2 then
							return true
						elseif nPos2 and not nPos1 then
							return false
						else
							return g1.nOriginalIndex < g2.nOriginalIndex
						end
					end
				end
			end
		end
	end)
end

function UIPlayStoreView:ApplySearchFilter()
	if self.szSearchkey and #self.szSearchkey > 0 then
		self.aFilterGoods = {}
		local szKey = UIHelper.UTF8ToGBK(self.szSearchkey)
		for _, goods in ipairs(self.aAllGoods) do
			local szName = ShopData.GetItemNameByGoods(goods)
			if string.match(szName, szKey) then
				table.insert(self.aFilterGoods, goods)
			end
		end
	else
		self.aFilterGoods = {}
		for _, goods in ipairs(self.aAllGoods) do
			table.insert(self.aFilterGoods, goods)
		end
		self.szSearchkey = nil
	end
end

function UIPlayStoreView:CanMutiBuy(goods)
	return CanMutiBuy(goods, self.aShopInfo)
end

function UIPlayStoreView:ForceRefreshGoods(bGenerateFilter)
	if bGenerateFilter then
		self:GeneratePervFilter() 			-- 按照交互设计，第一次需要生成全部筛选项
		self:GeneratePervFilter(true) 		-- 第二次生成进行默认项勾选
		self.tSelector = CopyTable(self.tPervSelector)
	end
	self:ApplySearchFilter()
	self:ApplySelector()
	self:QueryAllData()
	self.bNeedRefresh = true
end

function UIPlayStoreView:ForceFixQuantityController()
	if not self.scriptQuantityController then return end

	local LayoutContentAll = UIHelper.GetParent(self.scriptQuantityController._rootNode)
	local nHeight = UIHelper.GetHeight(LayoutContentAll)
	UIHelper.SetPositionY(self.scriptQuantityController._rootNode, -nHeight)
end

function UIPlayStoreView:AutoRefreshCostItem()
	if not self.nRemarkCostTick or (self.nRemarkCostTick and self.nRemarkCostTick + 5 >= GetLogicFrameCount()) then return end

	for _, tMark in ipairs(self.tCostItemMark) do
		if (#self.tCostItemMark > 2 or self.nShopMode ~= "SHOP") and self.tCostItemMark.tScript then
			UIHelper.RemoveFromParent(self.tCostItemMark.tScript._rootNode, true)
			self.tCostItemMark.tScript = nil
		elseif #self.tCostItemMark <= 2 and self.nShopMode == "SHOP" and not tMark.tScript then
			tMark.tScript = UIHelper.AddPrefab(PREFAB_ID.WidgetSingleCurrency, self.LayoutCurrency,
			tMark.dwTabType, tMark.dwIndex, true)
		end
	end
end

return UIPlayStoreView