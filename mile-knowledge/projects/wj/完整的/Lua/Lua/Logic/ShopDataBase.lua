--------------------------------------------
-- @File  : ShopDataBase.lua
-- @Desc  : 商品购买界面 - 共享状态与数据函数
--------------------------------------------

ShopDataBase = ShopDataBase or {className = "ShopDataBase"}
local self = ShopDataBase
-------------------------------- 消息定义 --------------------------------
ShopDataBase.Event = {}
ShopDataBase.Event.XXX = "ShopDataBase.Msg.XXX"

-- 当前模式(买/卖)，当前页码，条件筛选后的商品列表，关键字筛选后的商品列表，整个商店的商品列表，通过dwShopIndex索引的商品列表 ，关键字过滤，筛选项，选中的商品, 打开时默认页面, 打开时默认购买道具类型, 打开时默认购买道具ID
-- Shared state table
local State = {
	m_nNpcID = 0,
	m_dwRequireForceID = 0,
	m_szShopName = "",
	m_bFullScreen = false,
	m_nFullScreen = 0,
	m_nShopID = nil,
	m_bCanRepair = nil,
	m_nTemplateID = nil,
	m_bCustomShop = nil,
	m_bGroup = nil,
	m_bTreasureHunt = nil,
	m_shopMode = nil,
	m_nPage = nil,
	m_aGoods = nil,
	m_aFilterGoods = nil,
	m_aAllGoods = nil,
	m_aSearchByShopIndexGoods = nil,
	m_szFilter = nil,
	m_goodsSelected = nil,
	m_nDefaultPage = nil,
	m_nOpenMultiBuyItemType = nil,
	m_nOpenMultiBuyItemIndex = nil,
	m_nOpenMultiBuyItemCount = nil,
	m_Selector = nil,
	m_bSendHelper = nil,
	m_frame = nil,
	m_tDefaultAnchor = nil,
	m_tCustomShop = {},
	m_tCustomShopEx = {},
	m_dwPlayerRemoteDataID = nil,
	m_bBagPanelOpened = nil,
}

function ShopDataBase.GetState()
	return State
end

-- Exported constants
ShopDataBase.SHOP_PAGE_SIZE = 20
ShopDataBase.ITEM_MAX_MULTIPLE = 10
ShopDataBase.MAX_BOOK_NUM = 20
ShopDataBase.DEFAULT_STEP = 10
ShopDataBase.DEFAULT_SYS_SHOP_ID = 922

-- Selector sort orders (local)
-- 枚举类筛选项排序规则
local SELECTOR_SORTER = {
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

-- Exported for NormalShop.UpdateSelector
ShopDataBase.SELECTOR_TITLE = {
	['SchoolSelector']       = g_tStrings.SHOP_SELECTOR_SCHOOL,  -- 门派过滤器
	['KungfuSelector']      = g_tStrings.STR_SKILL_NG,      -- 心法过滤器
	['EquipPosSelector']    = g_tStrings.STR_EQUIP_POS,     -- 部位过滤器
	['AttriSelector']       = g_tStrings.STR_EQUIP_ATTR,    -- 属性过滤器
	['RequireLevelSelector']= g_tStrings.STR_GUILD_LEVEL,   -- 等级过滤器
	['LevelSelector']       = FormatString(g_tStrings.STR_ITEM_H_ITEM_LEVEL, ''), -- 品质过滤器
	['QualitySelector']     = g_tStrings.BOOK_QUALITY,      -- 品级过滤器
	['ScoreSelector']       = FormatString(g_tStrings.STR_ITEM_H_ITEM_SCORE, ''), -- 装备分过滤器
	['SkillSelector']       = g_tStrings.STR_SKILL,         -- 技能过滤器
	['HaveReadSelector']    = g_tStrings.STR_READ_TITLE,    -- 已读未读过滤器
	['CollectFurniture'] 	= g_tStrings.STR_FURNITURE_COLLECT_TITLE, --家具收集过滤器
}

---------------------------------------------------------------
-- Safe wrappers (local)
---------------------------------------------------------------
local _GetItem = GetItem
local function GetItem(...)
	local tArg = {...}
	if #tArg ~= 1 or tArg[1] == 0 then
		return
	end
	for i = 1, select("#", ...) do
		if not tArg[i] then
			return -- 省的刷LOG
		end
	end
	return _GetItem(...)
end

local _GetItemInfo = GetItemInfo
local function GetItemInfo(...)
	local tArg = {...}
	if #tArg ~= 2 then
		return
	end
	for i = 1, select("#", ...) do
		if not tArg[i] then
			return -- 省的刷LOG
		end
	end
	return _GetItemInfo(...)
end

---------------------------------------------------------------
-- Item info helpers
---------------------------------------------------------------
function ShopDataBase.GetItemQualityFrame(nQuality)
	local nFrame = -1
	if nQuality == 1 then
		nFrame = -1
	elseif nQuality == 2 then
		nFrame = 0
	elseif nQuality == 3 then
		nFrame = 1
	elseif nQuality == 4 then
		nFrame = 2
	elseif nQuality == 5 then
		nFrame = 3
	end
	return nFrame
end

function ShopDataBase.IsItemCollected(item)
	local nStatus = 0
	local hPlayer = GetClientPlayer()
	if item.nGenre == ITEM_GENRE.HOMELAND and item.dwTabType == ITEM_TABLE_TYPE.HOMELAND then
		local bCollected = HomelandEventHandler.IsFurnitureCollected(item.dwFurnitureID)
		if bCollected then
			nStatus = GET_STATUS.COLLECTED
		elseif bCollected == false then
			nStatus = GET_STATUS.NOT_COLLECTED
		end
	elseif item.nGenre == ITEM_GENRE.EQUIPMENT and IsPendantPetItem(item) then
		if hPlayer then
			local bExit = hPlayer.IsHavePendentPet(item.dwIndex)
			nStatus = GET_STATUS.NOT_COLLECTED
			if bExit then
				nStatus = GET_STATUS.COLLECTED
			end
		end
	elseif item.nGenre == ITEM_GENRE.EQUIPMENT and IsPendantItem(item) then
		if hPlayer then
			local bExit = hPlayer.IsPendentExist(item.dwIndex)
			nStatus = GET_STATUS.NOT_COLLECTED
			if bExit then
				nStatus = GET_STATUS.COLLECTED
			end
		end
	elseif item.nGenre == ITEM_GENRE.EQUIPMENT and item.nSub == EQUIPMENT_SUB.PET then
		if hPlayer then
			local nPetIndex = GetFellowPetIndexByItemIndex(ITEM_TABLE_TYPE.CUST_TRINKET, item.dwIndex)
			local bHave = hPlayer.IsFellowPetAcquired(nPetIndex)
			nStatus = GET_STATUS.NOT_COLLECTED
			if bHave then
				nStatus = GET_STATUS.COLLECTED
			end
		end
	elseif item.nGenre == ITEM_GENRE.TOY then
		if not hPlayer or not hPlayer.RemoteDataAutodownFinish() then
			return nStatus
		end

		local tToy = Table_GetToyBoxByItem(item.dwIndex)
		if not tToy then
			return nStatus
		end

		nStatus = GET_STATUS.NOT_COLLECTED

		if GDAPI_IsToyHave(hPlayer, tToy.dwID, tToy.nCountDataIndex) then
			nStatus = GET_STATUS.COLLECTED
		end
	end
	return nStatus
end

---------------------------------------------------------------
-- Basic data accessors
---------------------------------------------------------------
function ShopDataBase.GetNpcID()
	return State.m_nNpcID
end

function ShopDataBase.GetShopID()
	return State.m_nShopID
end

function ShopDataBase.IsSameGoodsInFullShop(g1, g2)
	if not (g1 and g2) then
		return false
	end

	if g1.nShopID and g1.dwShopIndex and g1.nShopID == g2.nShopID and g1.dwShopIndex == g2.dwShopIndex then
		return true
	else
		return false
	end
	if g1.nItemType and g1.nItemIndex and g1.nItemType == g2.nItemType and g1.nItemIndex == g2.nItemIndex then
		return true
	end
	return false
end

function ShopDataBase.IsSameGoods(g1, g2)
	if not (g1 and g2) then
		return false
	elseif g1.nShopID and g1.dwShopIndex and g1.nShopID == g2.nShopID and g1.dwShopIndex == g2.dwShopIndex then
		return true
	elseif g1.nItemType and g1.nItemIndex and g1.nItemType == g2.nItemType and g1.nItemIndex == g2.nItemIndex then
		return true
	end
	return false
end

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

function ShopDataBase.CanMeUseThisItem(player, item)
	if item.nGenre ~= ITEM_GENRE.EQUIPMENT then
		return true
	end

	local requireAttrib = item.GetRequireAttrib()
	for k, v in pairs(requireAttrib) do
		if not player.SatisfyRequire(v.nID, v.nValue1, v.nValue2) then
			return false
		end
	end
	return true
end

function ShopDataBase.GetSatisfyColor(bSatisfy)
	if bSatisfy then
		return 255, 255, 255
	else
		return 255, 0, 0
	end
end

function ShopDataBase.GetItemInfoByGoods(goods)
	return GetItemInfo(goods.nItemType, goods.nItemIndex)
end

function ShopDataBase.GetItemByGoods(goods)
	if not goods then
		return
	elseif goods.nShopID == 'BUY_BACK' then
		return GetPlayerItem(GetClientPlayer(), INVENTORY_INDEX.SOLD_LIST, goods.dwShopIndex), true
	elseif goods.nShopID == 'BUY_BACK_ADVANCED' then
		return GetPlayerItem(GetClientPlayer(), INVENTORY_INDEX.TIME_LIMIT_SOLD_LIST, goods.dwShopIndex), true
	else
		local item = GetItem(GetShopItemID(goods.nShopID, goods.dwShopIndex))
		--第一次加载商店，商店物品还没创建，取不到信息
		if item then
			return item, true
		else
			return GetItemInfo(goods.nItemType, goods.nItemIndex), false
		end
	end
end

function ShopDataBase.GetItemNameByGoods(goods)
	local KItem, bItem = ShopDataBase.GetItemByGoods(goods)
	local szName
	if bItem then
		szName = GetItemNameByItem(KItem)
	elseif KItem then
		szName = GetItemNameByItemInfo(KItem, (GetShopItemInfo(State.m_nShopID, goods.dwShopIndex) or EMPTY_TABLE).nDurability)
	end
	return szName or ""
end

---------------------------------------------------------------
-- Goods management
---------------------------------------------------------------
function ShopDataBase.ClearGoods()
	State.m_goodsSelected = nil -- 选中的商品
	State.m_aAllGoods     = {} -- 整个商店的商品
	State.m_aFilterGoods  = {} -- 关键字过滤后的商品
	State.m_aGoods        = {} -- 条件过滤之后的商品（实际显示的商品列表）
	State.m_aSearchByShopIndexGoods = {} --通过dwShopIndex索引的商品列表
end

function ShopDataBase.AddGoods(goods, bSoldList)
	goods.tSelector = {}
	goods.nOriginalIndex = #State.m_aAllGoods
	if not bSoldList then
		ShopDataBase.GenerateGoodsSelector(goods)
	end
	table.insert(State.m_aGoods, goods)
	table.insert(State.m_aFilterGoods, goods)
	table.insert(State.m_aAllGoods, goods)
	State.m_aSearchByShopIndexGoods[goods.dwShopIndex] = goods
end

function ShopDataBase.SwitchShop(nShopID)
	ShopDataBase.ClearGoods()
	if type(nShopID) == 'number' then
		State.m_shopMode = 'SHOP'
		State.m_nShopID = nShopID
		local player = GetClientPlayer()
		for nIndex, item in ipairs(GetShopAllItemInfoParam(nShopID)) do
			local dwShopIndex
			local dwCustomShopIndex = State.m_tCustomShop[nIndex]
			if State.m_bCustomShop and dwCustomShopIndex then
				dwShopIndex = dwCustomShopIndex
			else
				dwShopIndex = item.dwItemInfoIndex
			end
			if not State.m_bCustomShop or dwCustomShopIndex then
				local bNeedFame, bFameSatisfy, nFameNeedLevel = GDAPI_ShopCheckFame(State.m_nTemplateID, player, item.nItemType, item.nItemIndex)
				if not bNeedFame then
					nFameNeedLevel = nil
				end
				ShopDataBase.AddGoods({
					nShopID     = nShopID             ,
					dwShopIndex = dwShopIndex		  ,
					nItemType   = item.nItemType      ,
					nItemIndex  = item.nItemIndex     ,
					nDurability = item.nDurability    , --耐久度，当道具是书籍的时用来查询书籍ID dwBookID, dwSubID = GlobelRecipeID2BookID(dwRecipeID)
					bCanReturn 	= item.bCanReturn	  , --是否可以退货
					nFameNeedLevel = nFameNeedLevel,
				}, false)
			end
		end
	elseif nShopID == 'BUY_BACK' then
		State.m_shopMode = 'BUY_BACK'
		local player = GetClientPlayer()
		for i = 0, player.GetBoxSize(INVENTORY_INDEX.SOLD_LIST) - 1, 1 do
			local item = GetPlayerItem(player, INVENTORY_INDEX.SOLD_LIST, i)
			if item then
				ShopDataBase.AddGoods({
					nShopID     = 'BUY_BACK'          ,
					dwShopIndex = i                   ,
					nItemType   = item.dwTabType      ,
					nItemIndex  = item.dwIndex        ,
				}, true)
			end
		end
	elseif nShopID == 'BUY_BACK_ADVANCED' then
		State.m_shopMode = 'BUY_BACK_ADVANCED'
		local player = GetClientPlayer()
		for i = 0, player.GetBoxSize(INVENTORY_INDEX.TIME_LIMIT_SOLD_LIST) - 1, 1 do
			local item = GetPlayerItem(player, INVENTORY_INDEX.TIME_LIMIT_SOLD_LIST, i)
			if item then
				ShopDataBase.AddGoods({
					nShopID     = 'BUY_BACK_ADVANCED' ,
					dwShopIndex = i                   ,
					nItemType   = item.dwTabType      ,
					nItemIndex  = item.dwIndex        ,
				}, true)
			end
		end
	end
	if not State.m_Selector.bDisableSort then
		ShopDataBase.SortGoods()
	end
	-- NOTE: UpdateSelector() removed - callers handle UI update
end

function ShopDataBase.SwitchFullShop(nShopID)
	ShopDataBase.ClearGoods()
	if type(nShopID) == 'number' then
		State.m_shopMode = 'SHOP'
		State.m_nShopID = nShopID
		local player = GetClientPlayer()
		local nCount = 0
		for nIndex, item in ipairs(GetShopAllItemInfoParam(nShopID)) do
			local dwShopIndex
			local dwCustomShopIndex = State.m_tCustomShop[nIndex]
			if State.m_bCustomShop and dwCustomShopIndex then
				dwShopIndex = dwCustomShopIndex
			else
				dwShopIndex = item.dwItemInfoIndex
			end
			if not State.m_bCustomShop or dwCustomShopIndex then
				local bNeedFame, bFameSatisfy, nFameNeedLevel = GDAPI_ShopCheckFame(State.m_nTemplateID, player, item.nItemType, item.nItemIndex)
				if not bNeedFame then
					nFameNeedLevel = nil
				end
				ShopDataBase.AddGoods({
					nShopID     = nShopID             ,
					dwShopIndex = dwShopIndex		  ,
					nItemType   = item.nItemType      ,
					nItemIndex  = item.nItemIndex     ,
					nDurability = item.nDurability    , --耐久度，当道具是书籍的时用来查询书籍ID dwBookID, dwSubID = GlobelRecipeID2BookID(dwRecipeID)
					bCanReturn 	= item.bCanReturn	  , --是否可以退货
					nFameNeedLevel = nFameNeedLevel,
				}, false)
			end
			nCount = nIndex
		end
	end
end

function ShopDataBase.SortGoods()
	local player = GetClientPlayer()
	local tKungfuIDs = ForceIDToKungfuIDs(player.dwForceID)
	local tKungfus = {}
	for _, dwKungfuID in ipairs(tKungfuIDs) do
		local kungfu = GetSkill(dwKungfuID, 1)
		if kungfu then
			table.insert(tKungfus, kungfu)
		end
	end

	table.sort(State.m_aAllGoods, function(g1, g2)
		local itemInfo1 = ShopDataBase.GetItemInfoByGoods(g1)
		local itemInfo2 = ShopDataBase.GetItemInfoByGoods(g2)
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

function ShopDataBase.Filter(szFilter)
	if szFilter and #szFilter > 0 then
		State.m_aFilterGoods = {}
		for _, goods in ipairs(State.m_aAllGoods) do
			local szName = ShopDataBase.GetItemNameByGoods(goods)
			if wstring.find(szName, szFilter) then
				table.insert(State.m_aFilterGoods, goods)
			end
		end
		State.m_szFilter = szFilter
	else
		State.m_aFilterGoods = {}
		for _, goods in ipairs(State.m_aAllGoods) do
			table.insert(State.m_aFilterGoods, goods)
		end
		State.m_szFilter = nil
	end
	-- NOTE: ApplySelector() removed - callers handle this
end

function ShopDataBase.GetFullShopOtherIndex(tSystemShopInfo, nShopID, nClassIndex)
	for nGroupIndex, tGroup in ipairs(tSystemShopInfo) do
        for nFindClassIndex, tClass in ipairs(tGroup) do
            for _, tShopInfo in ipairs(tClass) do
				if (not nShopID) and (not nClassIndex) then
					return tShopInfo.nShopID, nFindClassIndex, nGroupIndex
				end
				if tShopInfo.nShopID == nShopID and (not nClassIndex) then
					return tShopInfo.nShopID, nFindClassIndex, nGroupIndex
				end
				if nFindClassIndex == nClassIndex and (not nShopID) then
					return tShopInfo.nShopID, nFindClassIndex, nGroupIndex
				end
            end
        end
    end
end

---------------------------------------------------------------
-- Selector system
---------------------------------------------------------------
-- 获取筛选项文字
function ShopDataBase.GetSelectorText(szSelectorName, oValue)
	-- 默认标题
	if oValue == nil then
		return ShopDataBase.SELECTOR_TITLE[szSelectorName]
	end
	-- 对应选项标题
	if szSelectorName == 'SchoolSelector' then
		return Table_GetSkillSchoolName(oValue)
	elseif szSelectorName == 'KungfuSelector' then
		return Table_GetSkillName(oValue, 1)
	elseif szSelectorName == 'EquipPosSelector' then
		return g_tStrings.tEquipTypeNameTable[oValue]
	elseif szSelectorName == 'AttriSelector'or
	szSelectorName == 'SkillSelector'or
	szSelectorName == 'HaveReadSelector' or
	szSelectorName == 'CollectFurniture'
	then -- 简单枚举类选择器
		return oValue
	elseif szSelectorName == 'ScoreSelector' or
	szSelectorName == 'RequireLevelSelector' or
	szSelectorName == 'LevelSelector' then -- 数值范围类选择器
		local szText = (oValue.minValue == oValue.maxValue and oValue.minValue) or (oValue.minValue .. '~' .. oValue.maxValue)
		if szSelectorName == 'RequireLevelSelector' then
			szText = szText .. g_tStrings.STR_LEVEL
		end
		return szText
	elseif szSelectorName == 'QualitySelector' then
		return GetItemQualityCaption(oValue)
	end
end

-- 获取筛选项颜色
function ShopDataBase.GetSelectorRgb(szSelectorName, oValue)
	if oValue ~= nil then
		if szSelectorName == 'QualitySelector' then
			return GetItemFontColorByQuality(oValue)
		end
	end
	return 255, 255, 255
end

-- 生成商品筛选标签
function ShopDataBase.GenerateGoodsSelector(goods, szSelectorName)
	local iteminfo = ShopDataBase.GetItemInfoByGoods(goods)

	if not szSelectorName then
		goods.tSelector = {}
	end

	if not szSelectorName or szSelectorName == 'SchoolSelector' or szSelectorName == 'KungfuSelector' then
		goods.tSelector['SchoolSelector'] = {} -- school标签
		goods.tSelector['KungfuSelector'] = {} -- 心法标签
		local t = g_tTable.EquipRecommend:Search(iteminfo.nRecommendID)
		if t and t.szDesc and t.szDesc ~= "" then
			for _, v in ipairs(SplitString(t.kungfu_ids, "|")) do
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
					--v.nID, v.nValue1, v.nValue2
					local szCategory = Table_GetCategoryByAttributeID(v.nID)
					if szCategory then
						goods.tSelector['AttriSelector'][szCategory] = true
					end
				end
			end
			local magicAttrib = GetItemMagicAttrib(iteminfo.GetMagicAttribIndexList())
			if magicAttrib then
				for k, v in pairs(magicAttrib) do
					--v.nID, v.nValue1, v.nValue2
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
			goods.tSelector['ScoreSelector'] = iteminfo.nBaseScore
		end
	end

	-- 秘籍技能标签
	if not szSelectorName or szSelectorName == 'SkillSelector' then
		if iteminfo.nGenre == ITEM_GENRE.MATERIAL and iteminfo.nSub == ITEM_SUBTYPE_RECIPE then
			goods.tSelector['SkillSelector'] = {}
			iteminfo.szName:gsub(g_tStrings.STR_SKILLNAME_MATCH_EXP, function(_, szSkillName, _)
				goods.tSelector['SkillSelector'][szSkillName] = true
			end)
		end
	end

	-- 已阅读标签
	if not szSelectorName or szSelectorName == 'HaveReadSelector' then
		if iteminfo.nGenre == ITEM_GENRE.MATERIAL and iteminfo.nSub == ITEM_SUBTYPE_RECIPE then
			if IsMystiqueRecipeRead(iteminfo, true) then
				goods.tSelector['HaveReadSelector'] = { [g_tStrings.STR_ALREADY_READ] = true }
			else
				goods.tSelector['HaveReadSelector'] = { [g_tStrings.STR_UNREAD] = true }
			end
		elseif iteminfo.nGenre == ITEM_GENRE.BOOK then
			local nDurability = GetShopItemInfo(State.m_nShopID, goods.dwShopIndex).nDurability
			local nBookID, nSegmentID = GlobelRecipeID2BookID(nDurability)
			if GetClientPlayer().IsBookMemorized(nBookID, nSegmentID) then
				goods.tSelector['HaveReadSelector'] = { [g_tStrings.STR_ALREADY_READ] = true }
			else
				goods.tSelector['HaveReadSelector'] = { [g_tStrings.STR_UNREAD] = true }
			end
		end
	end

	--家具已收集标签
	if not szSelectorName or szSelectorName == 'CollectFurniture' then
		if iteminfo.nGenre == ITEM_GENRE.HOMELAND then
			local nFurnitureType = iteminfo.nFurnitureType or HS_FURNITURE_TYPE.FURNITURE
			local dwFurnitureID = iteminfo.dwFurnitureID
			if nFurnitureType == HS_FURNITURE_TYPE.FURNITURE then
				local bCollected = HomelandEventHandler.IsFurnitureCollected(dwFurnitureID)
				if bCollected then
					goods.tSelector['CollectFurniture'] = { [g_tStrings.STR_FURNITURE_COLLECTED] = true }
				else
					goods.tSelector['CollectFurniture'] = { [g_tStrings.STR_FURNITURE_UNCOLLECT] = true }
				end
			end
		end
	end
end

-- 生成筛选器
function ShopDataBase.GenerateSelector(szSelectorName)
	if not State.m_Selector[szSelectorName] then
		State.m_Selector[szSelectorName] = { nSelected = 0, bFirstGenerate = true }
	end

	if szSelectorName == 'SchoolSelector' or
	szSelectorName == 'KungfuSelector' or
	szSelectorName == 'EquipPosSelector' or
	szSelectorName == 'AttriSelector' or
	szSelectorName == 'QualitySelector' or
	szSelectorName == 'SkillSelector' or
	szSelectorName == 'HaveReadSelector' or
	szSelectorName == 'CollectFurniture'
	then -- 具体枚举类
		local tSelector = {}
		-- 枚举商品的选择器标签
		for _, goods in ipairs(ShopDataBase.GetSelectorResult(szSelectorName)) do
			if goods.tSelector[szSelectorName] and
			not goods.tSelector[szSelectorName][''] then -- 不是通用装备
				for tag, _ in pairs(goods.tSelector[szSelectorName]) do
					tSelector[tag] = false
				end
			end
		end

		-- 处理之前选中的选项
		if State.m_Selector[szSelectorName].nSelected > 0 then
			for _, selector in ipairs(State.m_Selector[szSelectorName]) do
				if selector.bSelected then
					tSelector[selector.value] = selector.bSelected
				end
			end
		end

		-- 建立新的筛选器结果
		local aSelector = { nSelected = 0 }
		for value, bSelected in pairs(tSelector) do
			if bSelected then
				aSelector.nSelected = aSelector.nSelected + 1
			end
			table.insert(aSelector, { value = value, bSelected = bSelected })
		end

		-- 处理默认筛选项
		if State.m_Selector[szSelectorName].bFirstGenerate and State.m_Selector.bAutoSelect then
			if szSelectorName == 'SchoolSelector' then
				for _, selector in ipairs(aSelector) do
					if selector.value == PlayerData.GetMountBelongSchoolID() then
						selector.bSelected = true
						aSelector.nSelected = aSelector.nSelected + 1
					end
				end
			elseif szSelectorName == 'HaveReadSelector' then
				for _, selector in ipairs(aSelector) do
					if selector.value == g_tStrings.STR_UNREAD then
						selector.bSelected = true
						aSelector.nSelected = aSelector.nSelected + 1
					end
				end
			elseif szSelectorName == 'CollectFurniture' then
				for _, selector in ipairs(aSelector) do
					if selector.value == g_tStrings.STR_FURNITURE_UNCOLLECT then
						selector.bSelected = true
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
				aSelector.szTitle = aSelector.szTitle or ShopDataBase.GetSelectorText(szSelectorName, selector.value)
				break
			end
		end
		State.m_Selector[szSelectorName] = aSelector
	elseif szSelectorName == 'RequireLevelSelector' or
		szSelectorName == 'LevelSelector' or
		szSelectorName == 'ScoreSelector' then -- 范围值类
			-- 先取得所有取值枚举列表
			local tSelector, tSelectorHash, nCount = {}, {}, 0
			for _, goods in ipairs(ShopDataBase.GetSelectorResult(szSelectorName)) do
				if goods.tSelector[szSelectorName] then
					if tSelectorHash[goods.tSelector[szSelectorName]] == nil then
						nCount = nCount + 1
						table.insert(tSelector, {
							minValue = goods.tSelector[szSelectorName],
							maxValue = goods.tSelector[szSelectorName],
						})
					end
					tSelectorHash[goods.tSelector[szSelectorName]] = false
				end
			end

		local aSelector = { nSelected = 0 }
		for _, selector in ipairs(tSelector) do
			table.insert(aSelector, selector)
		end

		-- 对枚举值进行排序
		table.sort(aSelector, function(a, b)
			return a.minValue < b.minValue
		end)

		-- 处理默认筛选项
		if State.m_Selector[szSelectorName].bFirstGenerate and State.m_Selector.bAutoSelect then
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
		if State.m_Selector[szSelectorName].nSelected > 0 then
			for _, selector_old in ipairs(State.m_Selector[szSelectorName]) do
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
				aSelector.szTitle = aSelector.szTitle or ShopDataBase.GetSelectorText(szSelectorName, { minValue = selector.minValue, maxValue = selector.maxValue })
				aSelector.nSelected = aSelector.nSelected + 1
			end
		end
		State.m_Selector[szSelectorName] = aSelector
	end

	return State.m_Selector[szSelectorName]
end

-- 设置筛选器
-- SetSelector('ForceSelector', 9)          -- 转换9的选择状态
-- SetSelector('ForceSelector', 9, false)   -- 设置9为不选
-- SetSelector('ForceSelector', nil, false) -- 全部设置为否
function ShopDataBase.SetSelector(szSelectorName, key, bSelected)
	local aSelector = State.m_Selector[szSelectorName]
	if not aSelector then
		return
	end

	aSelector.nSelected = 0
	if type(key) == 'table' then
		for i, selector in ipairs(aSelector) do
			if selector.minValue >= key[1] and selector.maxValue <= key[2] then
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
	ShopDataBase.ApplySelector()
end

-- 获取筛选结果
function ShopDataBase.GetSelectorResult(szIngoreSelectorName, bAllowSelectorEmpty)
	local aGoods = {}
	for _, goods in ipairs(State.m_aFilterGoods) do
		table.insert(aGoods, goods)
	end
	-- 检查精确匹配类选择器
	local fnCheckEnumSelector = function(szSelectorName)
		local aSelector = State.m_Selector[szSelectorName]
		if aSelector and szIngoreSelectorName ~= szSelectorName and aSelector.nSelected and aSelector.nSelected > 0 then
			for i=#aGoods, 1, -1 do
				local bShow, goods = false, aGoods[i]
				if goods.tSelector[szSelectorName] and
				(goods.tSelector[szSelectorName][''] or (bAllowSelectorEmpty and not next(goods.tSelector[szSelectorName]))) then -- 通用物品 全门派装备
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
		local aSelector = State.m_Selector[szSelectorName]
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
	fnCheckEnumSelector('CollectFurniture')      -- 家具收集过滤器
	return aGoods
end

-- 执行筛选（m_aFilterGoods -> m_aGoods）
function ShopDataBase.ApplySelector(bAllowSelectorEmpty)
	if State.m_shopMode == 'SHOP' then
		State.m_aGoods = ShopDataBase.GetSelectorResult(nil, bAllowSelectorEmpty)
	else
		State.m_aGoods = {}
		for _, goods in ipairs(State.m_aFilterGoods) do
			table.insert(State.m_aGoods, goods)
		end
	end
end
---------------------------------------------------------------
-- Buy count logic
---------------------------------------------------------------
function ShopDataBase.GetGoods(nIndex)
	return State.m_aGoods[nIndex]
end

local function GetMaxCountByTokenMoney(nCanBuyCount, nRequire, fnGetCurrent)
	if nRequire and nRequire > 0 then
		local nCount = math.floor(fnGetCurrent() / nRequire)
		nCount = math.max(nCount, 1)
		nCanBuyCount = math.min(nCount, nCanBuyCount)
	end
	return nCanBuyCount
end

local function GetMaxCountByItem(nCanBuyCount, tShopItemInfo)
	local hPlayer = GetClientPlayer()
	local dwTabType                   = tShopItemInfo.dwTabType
	local dwIndex                     = tShopItemInfo.dwIndex
	local nRequireAmount              = tShopItemInfo.nRequireAmount

	-- 消耗物品
	if dwTabType and dwTabType > 0 and dwIndex and dwIndex > 0 and nRequireAmount and nRequireAmount > 0 and hPlayer then
		local nCurrent = hPlayer.GetItemAmount(dwTabType, dwIndex)
		local nCount = math.floor(nCurrent / nRequireAmount)
		nCount = math.max(nCount, 1)
		nCanBuyCount = math.min(nCount, nCanBuyCount)
	end
	return nCanBuyCount
end

local function GetMaxCount(goods, nMaxCount)
	local item = ShopDataBase.GetItemByGoods(goods)
	local tShopItemInfo = GetShopItemInfo(goods.nShopID, goods.dwShopIndex)
	local tPrice = GetShopItemBuyPrice(goods.nShopID, goods.dwShopIndex) or {nGold=0, nSilver=0, nCopper=0}

	if nMaxCount then
		nMaxCount = math.min(nMaxCount, item.nMaxStackNum * ShopDataBase.ITEM_MAX_MULTIPLE)
	else
		nMaxCount = item.nMaxStackNum * ShopDataBase.ITEM_MAX_MULTIPLE
	end

	if item.nMaxExistAmount > 0 then
		nMaxCount = math.min(item.nMaxExistAmount, nMaxCount)
	end
	local tMoney = PackMoney(100000, 0, 0)
	local nCount = MoneyOptDivMoney(tMoney, tPrice)
	nMaxCount = math.min(nCount, nMaxCount)

	if not item.bCanStack and item.nGenre == ITEM_GENRE.BOOK then --??规则不明，照搬原先的
		nMaxCount = math.min(ShopDataBase.MAX_BOOK_NUM, nMaxCount)
	end

	local nCanBuyCount = nMaxCount
	-- 威望
	nCanBuyCount = GetMaxCountByTokenMoney(nCanBuyCount, tShopItemInfo.nPrestige, function() return GetClientPlayer().nCurrentPrestige end)
	-- 狭义
	nCanBuyCount = GetMaxCountByTokenMoney(nCanBuyCount, tShopItemInfo.nJustice, function() return GetClientPlayer().nJustice end)
	-- 吃鸡代币
	nCanBuyCount = GetMaxCountByTokenMoney(nCanBuyCount, tShopItemInfo.nExamPrint, function() return GetClientPlayer().nExamPrint end)
	-- 名剑币
	nCanBuyCount = GetMaxCountByTokenMoney(nCanBuyCount, tShopItemInfo.nArenaAward, function() return GetClientPlayer().nArenaAward end)
	-- 活动积分
	nCanBuyCount = GetMaxCountByTokenMoney(nCanBuyCount, tShopItemInfo.nActivityAward, function() return GetClientPlayer().nActivityAward end)
	-- 成就积分
	nCanBuyCount = GetMaxCountByTokenMoney(nCanBuyCount, tShopItemInfo.nAchievementPoint, function() return GetClientPlayer().GetAchievementPoint() end)
	-- 休闲点
	nCanBuyCount = GetMaxCountByTokenMoney(nCanBuyCount, tShopItemInfo.nContribution, function() return GetClientPlayer().nContribution end)
	-- 师徒值
	nCanBuyCount = GetMaxCountByTokenMoney(nCanBuyCount, tShopItemInfo.nMentorAward, function() return GetClientPlayer().nMentorAward end)
	-- 帮会资金
	nCanBuyCount = GetMaxCountByTokenMoney(nCanBuyCount, tShopItemInfo.nTongFund, function() return GetTongClient().GetFundTodayRemainCanUse() end)
	--园宅币
	nCanBuyCount = GetMaxCountByTokenMoney(nCanBuyCount, tShopItemInfo.nArchitecture, function() return GetClientPlayer().nArchitecture end)

	-- 消耗物品
	nCanBuyCount = GetMaxCountByItem(nCanBuyCount, tShopItemInfo)

	return nMaxCount, nCanBuyCount
end

local function GetBuyCountInfo(goods)
	local nMaxCount = GetShopItemCount(goods.nShopID, goods.dwShopIndex)
	local item = ShopDataBase.GetItemByGoods(goods)
	local nCanBuyCount = 1

	local nDefaultCount
	if (item.bCanStack or item.nGenre == ITEM_GENRE.BOOK) and item.nMaxStackNum > 1 then
		if nMaxCount < 0 then
			nMaxCount, nCanBuyCount = GetMaxCount(goods, nil)
			nDefaultCount = item.nMaxStackNum
		else
			nDefaultCount = math.min(nMaxCount, item.nMaxStackNum)
			nMaxCount, nCanBuyCount = GetMaxCount(goods, nMaxCount)
		end
	else
		nMaxCount = 1
		nDefaultCount = 1
		nCanBuyCount = 1
	end

	return nMaxCount, nDefaultCount, nCanBuyCount
end

function ShopDataBase.CanMultiBuy(goods)
	local item, bItem = ShopDataBase.GetItemByGoods(goods)
	if not bItem then
		return false
	end

	if not GetShopItemCount(goods.nShopID, goods.dwShopIndex) then
		return false
	end

	local nMaxCount, nDefaultCount, nCanBuyCount = GetBuyCountInfo(goods)

	local nLimitCount = ShopDataBase.GetItemLimitCount(goods)
	if nLimitCount and nLimitCount > 0 then
		nCanBuyCount = math.min(nCanBuyCount, nLimitCount)
		nDefaultCount = math.min(nDefaultCount, nLimitCount)
	end
	local nMultiBuyLimit = Table_GetShopMultiBuyLimit(goods.nItemType, goods.nItemIndex)
	if nMultiBuyLimit and nMultiBuyLimit > 0 then
		nDefaultCount = math.min(nDefaultCount, nMultiBuyLimit)
	end

	return (item.nGenre ~= ITEM_GENRE.EQUIPMENT or item.nSub == EQUIPMENT_SUB.ARROW) and nMaxCount > 1, nCanBuyCount, nDefaultCount
end

function ShopDataBase.CanBuyGoods(goods, nCount)
	if goods.nShopID == 'BUY_BACK' or goods.nShopID == 'BUY_BACK_ADVANCED' then
		return true
	else
		local _, bItem = ShopDataBase.GetItemByGoods(goods)
		if bItem then
			return CanBuyItem(State.m_nNpcID, goods.nShopID, goods.dwShopIndex, nCount)
		else
			return false
		end
	end
end

function ShopDataBase.GetItemLimitCount(goods)
	local tShopItemInfo = GetShopItemInfo(goods.nShopID, goods.dwShopIndex)
	local player = GetClientPlayer()
	local nLimitCount = -1
	local nGobalLimitCount = -1
	local nPlayerBuyCount = -1

	nGobalLimitCount = GetShopItemCount(goods.nShopID, goods.dwShopIndex)
	local bGlobalLimit = nGobalLimitCount >= 0
	nLimitCount = nGobalLimitCount
	if tShopItemInfo.nPlayerRemoteDataPos >= 0 then
		if player.HaveRemoteData(State.m_dwPlayerRemoteDataID) then
			nPlayerBuyCount = player.GetRemoteArrayUInt(State.m_dwPlayerRemoteDataID, tShopItemInfo.nPlayerRemoteDataPos, tShopItemInfo.nPlayerRemoteDataLength)
			local nPlayerLeftCount = tShopItemInfo.nPlayerBuyLimit - nPlayerBuyCount
			if nGobalLimitCount >= 0 and nPlayerLeftCount then --钟琰需求：商店限量和个人限购同时存在时，道具左下角显示商店限量，个人限购通过购买报错来提示玩家。
				nLimitCount = nGobalLimitCount
			else
				nLimitCount = nPlayerLeftCount
			end
		end
	end
	return nLimitCount, nGobalLimitCount, nPlayerBuyCount
end

---------------------------------------------------------------
-- Query functions
---------------------------------------------------------------
-- 从服务器更新所有页的信息
function ShopDataBase.QueryAllPageData()
	local nPage = 1
	local nMaxPage = math.ceil(#State.m_aGoods / ShopDataBase.SHOP_PAGE_SIZE)
	while(nPage <= nMaxPage)
	do
		ShopDataBase.QueryPageData(nPage)
		nPage = nPage + 1
	end
end

function ShopDataBase.QueryFullShopData()
	local tIndexTable = {}
	for i = 1, #State.m_aGoods do
		local goods = State.m_aGoods[i]
		if type(goods.nShopID) == 'number' then
			table.insert(tIndexTable, goods.dwShopIndex)
		end
	end
	QueryRequestShopItems(State.m_nShopID, tIndexTable)
end

-- 从服务器更新当前页的信息
function ShopDataBase.QueryPageData(nPage)
	if nPage <= 0 then
		return
	end
	local nStart = (nPage - 1) * ShopDataBase.SHOP_PAGE_SIZE + 1
	local nEnd   = nPage * ShopDataBase.SHOP_PAGE_SIZE
	if nEnd > #State.m_aGoods then
		nEnd = #State.m_aGoods
	end
	local tIndexTable = {}
	for i = nStart, nEnd do
		local goods = State.m_aGoods[i]
		if type(goods.nShopID) == 'number' then
			table.insert(tIndexTable, goods.dwShopIndex)
		end
	end
	if #tIndexTable > 0 then
		QueryRequestShopItems(State.m_nShopID, tIndexTable)
	end
end

-- 重载当前商店数据
function ShopDataBase.ReloadCurrentShop()
	if State.m_shopMode == 'SHOP' then
		ShopDataBase.SwitchShop(State.m_nShopID)
	elseif State.m_shopMode == 'BUY_BACK' then
		ShopDataBase.SwitchShop("BUY_BACK")
	elseif State.m_shopMode == 'BUY_BACK_ADVANCED' then
		ShopDataBase.SwitchShop("BUY_BACK_ADVANCED")
	end
	ShopDataBase.Filter(State.m_szFilter)
	ShopDataBase.ApplySelector()
end

---------------------------------------------------------------
-- 生命周期函数 (原框架占位)
---------------------------------------------------------------
function ShopDataBase.Init()

end

function ShopDataBase.UnInit()

end

function ShopDataBase.OnLogin()

end

function ShopDataBase.OnFirstLoadEnd()

end

return ShopDataBase