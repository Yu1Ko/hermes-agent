-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopSearch
-- Date: 2022-12-27 20:44:44
-- Desc: ?
-- ---------------------------------------------------------------------------------

local SEARCH_MAX_COUNT = 10

local function MatchString(szSrc, szDst)
    if not szDst then
        return true
    end
	local nPos = string.match(UIHelper.GBKToUTF8(szSrc), szDst)
	if not nPos then
	   return false;
	end

	return true
end

local UICoinShopSearchView = class("UICoinShopSearch")

function UICoinShopSearchView:OnEnter(nSearchType, fnClose)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.fnClose = fnClose
    self:OnInit(nSearchType)
end

function UICoinShopSearchView:OnExit()
    if self.fnClose then
        self.fnClose()
    end
    self.bInit = false
    self:UnRegEvent()
end

function UICoinShopSearchView:BindUIEvent()
    if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EdiBoxSearch, function()
            local szSearch = UIHelper.GetString(self.EdiBoxSearch)
            self:OnSearch(szSearch)
        end)
    else
        UIHelper.RegisterEditBoxReturn(self.EdiBoxSearch, function()
            local szSearch = UIHelper.GetString(self.EdiBoxSearch)
            self:OnSearch(szSearch)
        end)
    end
end

function UICoinShopSearchView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICoinShopSearchView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopSearchView:UpdateInfo()

end

function UICoinShopSearchView:OnInit(nSearchType)
    self.nCurSearchType = nSearchType
    local tbResult
    if self.nCurSearchType == UI_COINSHOP_GENERAL.SHOP then
        UIHelper.SetString(self.EdiBoxSearch, "")
        self.EdiBoxSearch:setPlaceHolder(g_tStrings.COINSHOP_SEARCH_SHOP)
        tbResult = self:GetEnjoyList()
        self:UpdateRecommandList(tbResult)
    else
        UIHelper.SetString(self.EdiBoxSearch, "")
        self.EdiBoxSearch:setPlaceHolder(g_tStrings.COINSHOP_SEARCH_WARDROBE)
        tbResult = self:SearchMySelf("")
        self:UpdateSearchList(tbResult)
    end
end

function UICoinShopSearchView:GetEnjoyList()
	local tResult = {}
	local tList = Table_GetExteriorHome()
	local count = 0
	for _, tItem in ipairs(tList[2]) do
		local eGoodsType = CoinShop_HomeTypeToGoods(tItem.nType)
		if eGoodsType then
			local szName = CoinShop_GetGoodsName(eGoodsType, tItem.dwDetailID)
            if szName == "" then
                LOG.DEBUG("TODO CoinShop_GetGoodsName")
            else
                table.insert(tResult, {szName, tItem.nType, tItem.dwDetailID, true})
                count = count + 1
                if count > 25 then
                    break
                end
            end
		end
	end
	return tResult
end

function UICoinShopSearchView:OnSearch(szSearch)
    local tResult
	if self.nCurSearchType == UI_COINSHOP_GENERAL.SHOP then
		if szSearch == "" then
			tResult = self:GetEnjoyList()
            self:UpdateRecommandList(tResult)
		else
			tResult = self:SearchShop(szSearch)
            self:UpdateSearchList(tResult)
		end
	else
		tResult = self:SearchMySelf(szSearch)
        self:UpdateSearchList(tResult)
	end
end

function UICoinShopSearchView:SearchShop(szSearch)
    local tResult = {}
    tResult = self:SearchFromExterior(szSearch, tResult)
    if #tResult >= SEARCH_MAX_COUNT then
        return tResult
    end
    tResult = self:SearchFromRewards(szSearch, tResult)
    if #tResult >= SEARCH_MAX_COUNT then
        return tResult
    end
    tResult = self:SearchFromWeapon(szSearch, tResult)

    tResult = self:SearchFromHair(szSearch, tResult)

    return tResult
end

function UICoinShopSearchView:SearchMySelf(szSearch)
    local tResult = {}
    tResult = self:SearchMyExterior(szSearch, tResult)
    if #tResult >= SEARCH_MAX_COUNT then
        return tResult
    end

	tResult = self:SearchFromMyHair(szSearch, tResult)
	if #tResult >= SEARCH_MAX_COUNT then
        return tResult
    end

    tResult = self:SearchFromMyPendent(szSearch, tResult)
	if #tResult >= SEARCH_MAX_COUNT then
        return tResult
    end

    -- tResult = self:SearchFromMySFX(szSearch, tResult)
	-- if #tResult >= SEARCH_MAX_COUNT then
    --     return tResult
    -- end

    return tResult
end

function UICoinShopSearchView:UpdateSearchList(tbResult)
    UIHelper.SetVisible(self.WidgetAnchorRecommend, false)
    UIHelper.SetVisible(self.ScrollViewShoppingSearch, true)
    self.ScrollViewShoppingSearch:removeAllChildren()
    for _, tbInfo in ipairs(tbResult) do
        UIHelper.AddPrefab(PREFAB_ID.WidgetShoppingSearch, self.ScrollViewShoppingSearch, tbInfo)
    end
    UIHelper.ScrollViewDoLayout(self.ScrollViewShoppingSearch)
    UIHelper.ScrollToTop(self.ScrollViewShoppingSearch, 0)
end

function UICoinShopSearchView:UpdateRecommandList(tbResult)
    UIHelper.SetVisible(self.WidgetAnchorRecommend, true)
    UIHelper.SetVisible(self.ScrollViewShoppingSearch, false)
    self.ScrollViewRecommend:removeAllChildren()
    for _, tbInfo in ipairs(tbResult) do
        UIHelper.AddPrefab(PREFAB_ID.WidgetShoppingSearch, self.ScrollViewRecommend, tbInfo)
    end
    UIHelper.ScrollViewDoLayout(self.ScrollViewRecommend)
    UIHelper.ScrollToTop(self.ScrollViewRecommend, 0)
end

function UICoinShopSearchView:OnSelectSearch()

end

---------------------------------------------------------------------------------
function UICoinShopSearchView:SearchFromExterior(szSearch, tResult)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local hExteriorClient = GetExterior()
    if not hExteriorClient then
        return
    end
    local nTime = GetGSCurrentTime()
    local nCount = g_tTable.ExteriorBox:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.ExteriorBox:GetRow(i)
        if (tLine.nGenre ~= EXTERIOR_GENRE.SCHOOL or hPlayer.dwForceID == tLine.nForce) then
            local nSetLabel = tLine.nLabel
            local tSub = {}
            local bSetSearch = false

            if MatchString(tLine.szSetName, szSearch) then
                bSetSearch = true
            end

            local bShop = true
            for i = 1, 5 do
                local dwExteriorID = tLine["nSub" .. i]
				if dwExteriorID > 0 then
					local tExteriorInfo = hExteriorClient.GetExteriorInfo(dwExteriorID)
					if not tExteriorInfo then
						LOG.ERROR("SearchFromExterior error not have logic exterior dwExteriorID = " .. dwExteriorID)
					end
                    local nStartTime = tExteriorInfo.nStartTime
                    local nEndTime = tExteriorInfo.nEndTime
                    local bCanBuy = (nStartTime == -1 or nTime >= nStartTime) and
                                (nEndTime == -1 or nTime <= nEndTime)
                    if bCanBuy then
                        if not bSetSearch then
                            local szName = tLine.szSetName .. g_tStrings.STR_CONNECT_GBK .. g_tStrings.tExteriorSubNameGBK[tExteriorInfo.nSubType]
                            if MatchString(szName, szSearch) then
                                table.insert(tResult, {szName, HOME_TYPE.EXTERIOR, dwExteriorID, bShop})
                                if #tResult >= SEARCH_MAX_COUNT then
                                    return tResult
                                end
                            end
                        else
                            table.insert(tSub, dwExteriorID)
                        end
                    end
                end
            end
            if bSetSearch and #tSub > 0 then
                table.insert(tResult, {tLine.szSetName, HOME_TYPE.EXTERIOR_SET, tLine.nSet, tSub, bShop})
                if #tResult >= SEARCH_MAX_COUNT then
                    return tResult
                end
            end
        end
    end
    return tResult
end

function UICoinShopSearchView:SearchFromRewards(szSearch, tResult)
    local hRewardsShop = GetRewardsShop()
    if not hRewardsShop then
        return
    end

    local nCount = g_tTable.RewardsShop:GetRowCount()
    local tClassInfo = {}
    local nTime = GetGSCurrentTime()
    for i = 2, nCount do
        local tLine = g_tTable.RewardsShop:GetRow(i)
        local nClass = tLine.nClass
        local nSubClass = tLine.nSubClass
        if not CoinShopData.IsFilterTitle(COIN_SHOP_GOODS_TYPE.ITEM, nClass) then
            local hItemInfo = GetItemInfo(tLine.dwTabType, tLine.dwIndex)
            if hItemInfo then
                local szName =  ItemData.GetItemNameByItemInfo(hItemInfo)
                if MatchString(szName, szSearch) and CoinShopData.IsStartTimeOK(tLine.nStartTime, nTime) then
                    if tLine.bOverdueShow then
                        table.insert(tResult, {szName, HOME_TYPE.REWARDS, tLine.dwLogicID, true})
                    else
                        local bCanBuy = CoinShop_RewardsShow(tLine.dwLogicID, tLine.nClass)
                        if bCanBuy then
                            table.insert(tResult, {szName, HOME_TYPE.REWARDS, tLine.dwLogicID})
                        end
                    end
                    if #tResult >= SEARCH_MAX_COUNT then
                        return tResult
                    end
                end
            end
        end
    end
    return tResult
end

function UICoinShopSearchView:SearchFromWeapon(szSearch, tResult)
    local hPlayer = GetClientPlayer()
    if not hPlayer or hPlayer.dwForceID == 0 then
        return tResult
    end
    local nCount = g_tTable.CoinShop_Weapon:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.CoinShop_Weapon:GetRow(i)
        local dwID = tLine.dwID
        local bCanBuy = CoinShop_WeaponCanBuy(dwID)
        local tExteriorInfo = CoinShop_GetWeaponExteriorInfo(dwID)
        if bCanBuy then
            local szName = tLine.szName
            if MatchString(szName, szSearch) then
                table.insert(tResult, {szName, HOME_TYPE.EXTERIOR_WEAPON, dwID})
                if #tResult >= SEARCH_MAX_COUNT then
                    return tResult
                end
            end
        end
    end
    return tResult
end

function UICoinShopSearchView:SearchFromHair(szSearch, tResult)
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end
	local tHairMap = CoinShopData.GetHairMap()
	local nTime = GetGSCurrentTime()
	local tList = tHairMap["reHair"]
    for nRepresentID, v in pairs(tList) do
		local szHairName = v[3]
		local bSetSearch = MatchString(szHairName, szSearch)
		if bSetSearch then
			local dwHairID = CoinShopData.GetHairID(nRepresentID, 0, 0)
			local tInfo = GetHairShop().GetHairPrice(hPlayer.nRoleType, HAIR_STYLE.HAIR, dwHairID)
			local nStartTime = tInfo.nStartTime
			local nEndTime = tInfo.nEndTime
			local bCanBuy = (nStartTime == -1 or nTime >= nStartTime) and
						(nEndTime == -1 or nTime <= nEndTime)
			if bCanBuy then
                local nShowType = v[4]
                if nShowType ~= HAIR_SHOW_TYPE.GROUP then
                    table.insert(tResult, {szHairName, HOME_TYPE.HAIR, dwHairID})
                    if #tResult >= SEARCH_MAX_COUNT then
                        return tResult
                    end
                end
			end
		end
    end
    return tResult
end

function UICoinShopSearchView:SearchMyExterior(szSearch, tResult)
    local hExterior = GetExterior()
    if not hExterior then
        return
    end

    local tAllExterior = GetPlayerAllExterior()

    local nTime = GetGSCurrentTime()
    local tSubList = {}
    local tSetList = {}
    local tSetMap = {}
    for _, tExterior in ipairs(tAllExterior) do
		local dwExteriorID = tExterior.dwExteriorID
        local tInfo = hExterior.GetExteriorInfo(dwExteriorID)
        local tLine = Table_GetExteriorSet(tInfo.nSet)

		local bSetSearch = MatchString(tLine.szSetName, szSearch) and self:ExcludeEqually(tResult, tLine.szSetName)
		if bSetSearch then
			table.insert(tResult, {tLine.szSetName, HOME_TYPE.EXTERIOR_SET, tInfo.nSet})
			if #tResult >= SEARCH_MAX_COUNT then
				return tResult
			end
		end
	end

    return tResult
end

function UICoinShopSearchView:SearchFromMyHair(szSearch, tResult)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

	local tHairList = hPlayer.GetAllHair(HAIR_STYLE.HAIR)
    for k, v in ipairs(tHairList) do
		local nID = v.dwID
		local szHairName = CoinShopHair.GetHairText(nID)
		local bSetSearch = MatchString(szHairName, szSearch)
		if bSetSearch then
			table.insert(tResult, {szHairName, HOME_TYPE.HAIR, nID})
			if #tResult >= SEARCH_MAX_COUNT then
				return tResult
			end
		end
	end
	return tResult
end

function UICoinShopSearchView:SearchFromMyPendent(szSearch, tResult)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

	local nPendantType = KPENDENT_TYPE.WAIST
	while nPendantType < KPENDENT_TYPE.TOTAL do
		local tMyList = hPlayer.GetAllPendent(nPendantType) or {}
		for k, tItem in ipairs(tMyList) do
			local dwItemIndex = tItem.dwItemIndex
            local nColorID1, nColorID2, nColorID3 = tItem.nColorID1 or 0, tItem.nColorID2 or 0, tItem.nColorID3 or 0
			local tItemInfo = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, dwItemIndex)
			if tItemInfo then
				local bSearch = MatchString(tItemInfo.szName, szSearch)
				if bSearch then
					local nEquipSub = GetEquipSubByPendantType(nPendantType)
					local nClass = CoinShop_SubToRewardsClass(nEquipSub)
					local t = {tItemInfo.szName, "Pendant", dwItemIndex, nColorID1, nColorID2, nColorID3}
					table.insert(tResult, t)
				end
			end
		end
		if #tResult >= SEARCH_MAX_COUNT then
			return tResult
		end
		nPendantType = nPendantType + 1
	end

	return tResult
end

function UICoinShopSearchView:SearchFromMySFX(szSearch, tResult)
    -- for nEffectType = 1, PLAYER_SFX_REPRESENT.COUNT do
    --     local tMyList = CharacterEffectData.GetPendantEffectListByType(nEffectType)
	-- 	for k, tLine in ipairs(tMyList) do
	-- 		local bSearch = MatchString(tLine.szName, szSearch)
	-- 		if bSearch then
	-- 			local t = {tLine.szName, HOME_TYPE.EFFECT_SFX, nEffectType, tLine.dwEffectID}
	-- 			table.insert(tResult, t)
	-- 		end
	-- 	end
    --     if #tResult >= SEARCH_MAX_COUNT then
	-- 		return tResult
	-- 	end
    -- end
	
	-- return tResult
end

function UICoinShopSearchView:ExcludeEqually(tResult, szSetName)
	for k, v in ipairs(tResult) do
		if v[1] == szSetName then
			return false
		end
	end
	return true
end

return UICoinShopSearchView