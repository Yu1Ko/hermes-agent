
RideExteriorData = RideExteriorData or {}
RideExteriorData.HORSE_EXTERIOR_INDEX = "HORSE_STYLE"

RideExteriorData.tHorseDetailToRe = 
{
    [RideExteriorData.HORSE_EXTERIOR_INDEX] = EQUIPMENT_REPRESENT.HORSE_STYLE,
    [HORSE_ENCHANT_DETAIL_TYPE.HEAD] = EQUIPMENT_REPRESENT.HORSE_ADORNMENT1,
    [HORSE_ENCHANT_DETAIL_TYPE.CHEST] = EQUIPMENT_REPRESENT.HORSE_ADORNMENT2,
    [HORSE_ENCHANT_DETAIL_TYPE.FOOT] = EQUIPMENT_REPRESENT.HORSE_ADORNMENT3,
    [HORSE_ENCHANT_DETAIL_TYPE.HANT_ITEM] = EQUIPMENT_REPRESENT.HORSE_ADORNMENT4,
}


local tExteriorTemp = {
	["HORSE_STYLE"] = 0,
    [HORSE_ENCHANT_DETAIL_TYPE.HEAD] = 0,
    [HORSE_ENCHANT_DETAIL_TYPE.CHEST] = 0,
    [HORSE_ENCHANT_DETAIL_TYPE.FOOT] = 0,
    [HORSE_ENCHANT_DETAIL_TYPE.HANT_ITEM] = 0,
}

RideExteriorData.tLogicIndexToUIIndex = {
    [RideExteriorData.HORSE_EXTERIOR_INDEX] = 5,
    [HORSE_ENCHANT_DETAIL_TYPE.HEAD] = 1,
    [HORSE_ENCHANT_DETAIL_TYPE.CHEST] = 2,
    [HORSE_ENCHANT_DETAIL_TYPE.FOOT] = 3,
    [HORSE_ENCHANT_DETAIL_TYPE.HANT_ITEM] = 4,
}

RideExteriorData.tPreviewExterior = clone(tExteriorTemp)

RideExteriorData.tOriginalExterior = clone(tExteriorTemp)

RideExteriorData.tNotShowItem = nil

RideExteriorData.FILTER_TYPE = {
    ALL = 1,
    HAVE = 2,
    COLLECTED = 3,
    NOT_COLLECTED = 4,
}

RideExteriorData.CommonFilter = {{
	function(_) return true end,
	function(item) return item.bHave end,
	function(item) return item.bCollected or item.bHave end,
	function(item) return (not item.bCollected) and (not item.bHave) end,
}}

function RideExteriorData.GetRideExteriorInfo(dwExteriorID, bEquip)
	local pPlayer = g_pClientPlayer
	if not pPlayer then
		return
	end
	if not dwExteriorID then
		return
	end
	if dwExteriorID == 0 then
		return
	end

	local hMgr = GetHorseExteriorManager()
	if not hMgr then
		return
	end

	local tRes = {}
	local tInfo = nil
	local tLogicInfo = nil
	tRes.bHave = false
	tRes.bCollected = false
	tRes.nQuality = 0
	tRes.nIconID = 0
	tRes.szName = ""
	tRes.tSourceItem = {}
	tRes.nPrice = 0
	tRes.nOriginalPrice = 0
	tRes.nNowDiscount = 100
	tRes.bOffer = false
	tRes.nExteriorSlot = 0
	tRes.dwRepresentID = 0
	tRes.dwExteriorID = 0
	tRes.nDisEndTime = -1

	if bEquip then
		tInfo = Table_GetHorseEquipExteriorByIndex(dwExteriorID)
	else
		tInfo = Table_GetHorseExteriorByIndex(dwExteriorID)
	end

	if not tInfo then
		return
	end

	if bEquip then
		tLogicInfo = hMgr.GetHorseEquipExteriorInfo(dwExteriorID)
	else
		tLogicInfo = hMgr.GetHorseExteriorInfo(dwExteriorID)
	end

	if not tLogicInfo then
		return
	end

	tRes.dwExteriorID = dwExteriorID
	tRes.nDisEndTime = tLogicInfo.nDisEndTime
	local nCurrentTime = GetGSCurrentTime()
    local nDisStartTime = tLogicInfo.nDisStartTime
    local nDisEndTime = tLogicInfo.nDisEndTime
    if ((nDisStartTime >= 0 and nDisStartTime < nCurrentTime) or nDisStartTime < 0) and 
    ((nDisStartTime >= 0 and nDisEndTime > nCurrentTime) or nDisEndTime < 0) and tLogicInfo.nDiscount < 100 then
        tRes.bOffer = true
		tRes.nNowDiscount = tLogicInfo.nDiscount
    end
	if tRes.bOffer then
		tRes.nPrice = tLogicInfo.nPrice * tLogicInfo.nDiscount / 100
	else
		tRes.nPrice = tLogicInfo.nPrice
	end
	tRes.nOriginalPrice = tLogicInfo.nPrice
	tRes.dwRepresentID = tLogicInfo.dwRepresentID

	if bEquip then
		tRes.bHave = pPlayer.IsHaveHorseEquipExterior(dwExteriorID)
		tRes.bCollected = pPlayer.IsHorseEquipExteriorCollected(dwExteriorID)
		local hItemInfo = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, tInfo[1].dwItemIndex)
		tRes.szName = UIHelper.GBKToUTF8(hItemInfo.szName)
		tRes.nIconID = Table_GetItemIconID(hItemInfo.nUiId)
		tRes.nQuality = hItemInfo.nQuality
		for k, v in ipairs(tInfo) do
			table.insert(tRes.tSourceItem, {[1] = ITEM_TABLE_TYPE.CUST_TRINKET, [2] = v.dwItemIndex})
        end
		tRes.nExteriorSlot = tLogicInfo.nDetailType
	else
		tRes.bHave = pPlayer.IsHaveHorseExterior(dwExteriorID)
		tRes.bCollected = pPlayer.IsHorseExteriorCollected(dwExteriorID)
		local hItemInfo = GetItemInfo(tInfo.tItem[1].nType, tInfo.tItem[1].dwIndex)
		tRes.nIconID = Table_GetItemIconID(hItemInfo.nUiId)
		tRes.nQuality = hItemInfo.nQuality
		tRes.szName = UIHelper.GBKToUTF8(tInfo.szName)
		for k, v in ipairs(tInfo.tItem) do
            table.insert(tRes.tSourceItem, {[1] = v.nType, [2] = v.dwIndex})
        end
		tRes.szHorseSource = tInfo.szSource
		tRes.nExteriorSlot = RideExteriorData.HORSE_EXTERIOR_INDEX
	end

	return tRes
end

function RideExteriorData.GetWearRideExterior()
	local pPlayer = g_pClientPlayer
	if not pPlayer then
		return
	end
	local tInfo = {}
	local tWear = pPlayer.GetWearHorseEquipExterior()
	for k, v in pairs(tWear) do
		tInfo[k] = {dwExteriorID = v, bEquip = true}
	end
	local nWear = pPlayer.GetWearHorseExterior()
	tInfo[RideExteriorData.HORSE_EXTERIOR_INDEX] = {dwExteriorID = nWear, bEquip = false}
	return tInfo
end

function RideExteriorData.UpdateHorseExteriorData()
	local hPlayer = g_pClientPlayer
	local nHorseExterior = hPlayer.GetWearHorseExterior()
	local tHorseExteriorEquip = hPlayer.GetWearHorseEquipExterior()
	for k, v in pairs(tHorseExteriorEquip) do
		RideExteriorData.tOriginalExterior[k] = v
	end
	RideExteriorData.tOriginalExterior[RideExteriorData.HORSE_EXTERIOR_INDEX] = nHorseExterior
	RideExteriorData.tPreviewExterior = clone(RideExteriorData.tOriginalExterior)
end

function RideExteriorData.SetExteriorPreview(dwExteriorID, bEquip, nExteriorSlot)
	local tExteriorinfo = RideExteriorData.GetRideExteriorInfo(dwExteriorID, bEquip)
	if tExteriorinfo then
		RideExteriorData.tPreviewExterior[tExteriorinfo.nExteriorSlot] = dwExteriorID
	else
		RideExteriorData.tPreviewExterior[nExteriorSlot] = 0
	end
end

function RideExteriorData.IsInPreview(dwExteriorID, bEquip)
	local tExteriorinfo = RideExteriorData.GetRideExteriorInfo(dwExteriorID, bEquip)
	if tExteriorinfo then
		return RideExteriorData.tPreviewExterior[tExteriorinfo.nExteriorSlot] == dwExteriorID
	end
	return false
end

function RideExteriorData.SetExterior(tSetList)
	local pPlayer = g_pClientPlayer
	if not pPlayer then
		return
	end
	local nRetCode = EXTERIOR_APPLY_RESPOND_CODE.SUCCESS
	for _, v in ipairs(tSetList) do
		if v.bEquip then
			nRetCode = pPlayer.SetHorseEquipExterior(v.dwExteriorID, v.nExteriorSlot)
		else
			nRetCode = pPlayer.SetHorseExterior(v.dwExteriorID)
		end
		if nRetCode ~= EXTERIOR_APPLY_RESPOND_CODE.SUCCESS then
			OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.tSetRideExteriortWarn[nRetCode])
			OutputMessage("MSG_SYS", g_tStrings.tSetRideExteriortWarn[nRetCode] .. "\n")
			break
		end
	end
	if nRetCode == EXTERIOR_APPLY_RESPOND_CODE.SUCCESS then
		OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_RIDE_EXTERIOR_SAVE_SUCCESS)
		OutputMessage("MSG_SYS", g_tStrings.STR_RIDE_EXTERIOR_SAVE_SUCCESS .. "\n")
	end
end

local fnSortEquip = function(left, right)
    local nLeftNum = 1
    local nRightNum = 1
    if (not left.bCollected) and (not left.bHave) then
        nLeftNum = 1
    elseif left.bCollected and (not left.bHave) then
        nLeftNum = 2
    elseif left.bHave then
        nLeftNum = 3
    end
    if (not right.bCollected) and (not right.bHave) then
        nRightNum = 1
    elseif right.bCollected and (not right.bHave) then
        nRightNum = 2
    elseif right.bHave then
        nRightNum = 3
    end
    if nLeftNum == nRightNum then
        return left.dwExteriorID > right.dwExteriorID
    end
    return nLeftNum > nRightNum
end

function RideExteriorData.GetHorseExteriorList()
	local tList = Table_GetHorseExteriorList()
	local tRes = {}

	for _, tExterior in ipairs(tList) do
		local tExteriorInfo = RideExteriorData.GetRideExteriorInfo(tExterior.dwExteriorID, false)
		if tExteriorInfo then
			table.insert(tRes, tExteriorInfo)
		end
	end
	table.sort(tRes, fnSortEquip)
	return tRes
end

local function LoadNotShowItem()
	RideExteriorData.tNotShowItem = {}
    local nCount = g_tTable.CoinShop_HorseAdornment:GetRowCount()
    local tExteriorID = {}
    for i = 2, nCount do
        local tLine = g_tTable.CoinShop_HorseAdornment:GetRow(i)
        if tExteriorID[tLine.dwExteriorID] then
            RideExteriorData.tNotShowItem[tLine.dwItemIndex] = true
        else
            tExteriorID[tLine.dwExteriorID] = true
        end
    end
end

function RideExteriorData.GetHorseEquipExteriorList(szSearch, nFilter, nDetail)
	if not RideExteriorData.tNotShowItem then
		LoadNotShowItem()
	end
	local tRes = {}
	local tAllSetList = CoinShop_GetAllAdornmentSet()
	for _, tSet in pairs(tAllSetList) do
        for _, tItem in ipairs(tSet.tList) do
			local dwExteriorID = tItem.dwExteriorID
			local tExteriorInfo = RideExteriorData.GetRideExteriorInfo(dwExteriorID, true)
            local szName = tExteriorInfo.szName
            local bShow = not szSearch or szSearch == "" or string.find(szName, szSearch)
            if bShow then
				local bHave = tExteriorInfo.bHave
				local bCollected = tExteriorInfo.bCollected
                local bFilter = false
                if nFilter == RideExteriorData.FILTER_TYPE.ALL then
                    bFilter = true
                elseif nFilter == RideExteriorData.FILTER_TYPE.HAVE then
                    bFilter = bHave
                elseif nFilter == RideExteriorData.FILTER_TYPE.COLLECTED then
                    bFilter = bCollected and (not bHave)
                elseif nFilter == RideExteriorData.FILTER_TYPE.NOT_COLLECTED then  
                    bFilter = not bCollected and (not bHave)
                end
                local bAdornment = false
                if nDetail < 0 or tExteriorInfo.nExteriorSlot == nDetail then
                    bAdornment = true
                end
                if bFilter and bAdornment and not RideExteriorData.tNotShowItem[tItem.dwItemIndex] then
                    table.insert(tRes, tExteriorInfo)
                end
            end
        end
    end

	table.sort(tRes, fnSortEquip)
	return tRes
end

local fnSortSet = function(left, right)
	local nLHaveCount = left.tSetExteriorInfo.nHaveCount
	local nRHaveCount = right.tSetExteriorInfo.nHaveCount
    if nLHaveCount == nRHaveCount then
		local nLCollectCount = left.tSetExteriorInfo.nCollectCount
		local nRCollectCount = right.tSetExteriorInfo.nCollectCount
        if nLCollectCount == nRCollectCount then
            return left.nSetID > right.nSetID
        end
        return nLCollectCount > nRCollectCount
    end
    return nLHaveCount > nRHaveCount
end

function RideExteriorData.GetHorseEquipExteriorSet(szSearch, nFilter)
	if not RideExteriorData.tNotShowItem then
		LoadNotShowItem()
	end
	local tAllSetArray = CoinShop_GetAllAdornmentSet()
    local tRes = {}

	for nSetID, tSet in pairs(tAllSetArray) do
		local szSetName = UIHelper.GBKToUTF8(tSet.szName)
        local bShow = not szSearch or szSearch == "" or string.find(szSetName, szSearch)
        if bShow then
            local bSetHave = false
            local bSetCollected = false
            local nHaveCount = 0
            local nCollectCount = 0
			local tShowSet = {}
			tShowSet.nSetID = nSetID
			tShowSet.szName = szSetName
			tShowSet.nQuality = tSet.nQuality
            for _, tItem in ipairs(tSet.tList) do
                local dwExteriorID = tItem.dwExteriorID
                local tExteriorInfo = RideExteriorData.GetRideExteriorInfo(dwExteriorID, true)
				local bNotShow = RideExteriorData.tNotShowItem[tItem.dwItemIndex]
				if not bNotShow then
					if not tShowSet.nQuality then
						tShowSet.nQuality = tExteriorInfo.nQuality
					end
					local bHave = tExteriorInfo.bHave
					local bCollected = tExteriorInfo.bCollected
					if bHave then
						bSetHave = true
					end
					if bCollected then
						bSetCollected = true
					end
					table.insert(tShowSet, tExteriorInfo)
					if bHave then
						nHaveCount = nHaveCount + 1
					end
					if bCollected then
						nCollectCount = nCollectCount + 1
					end
				end
            end
			if #tShowSet > 0 then
				table.sort(tShowSet, fnSortEquip)
				tShowSet.tSetExteriorInfo = {nHaveCount = nHaveCount, nCollectCount = nCollectCount}
				local bFilter = false
				if nFilter == RideExteriorData.FILTER_TYPE.ALL then
					bFilter = true
				elseif nFilter == RideExteriorData.FILTER_TYPE.HAVE then
					bFilter = bSetHave
				elseif nFilter == RideExteriorData.FILTER_TYPE.COLLECTED then
					bFilter = bSetCollected
				elseif nFilter == RideExteriorData.FILTER_TYPE.NOT_COLLECTED then  
					bFilter = not bSetCollected
				end
				if bFilter then
					table.insert(tRes, tShowSet)
				end
			end
        end
    end

	table.sort(tRes, fnSortSet)
    return tRes
end

function RideExteriorData.GetPlayerRideExterior(pPlayer)
	local tNowExterior = {}
	local nHorseExterior = pPlayer.GetWearHorseExterior()
	local tHorseEquipExterior = pPlayer.GetWearHorseEquipExterior()
	for k, v in pairs(tHorseEquipExterior) do
		tNowExterior[k] = v
	end
	tNowExterior[RideExteriorData.HORSE_EXTERIOR_INDEX] = nHorseExterior
	return tNowExterior
end

function RideExteriorData.GetPlayerRideRepresentID(pPlayer)
	local aRepresentID = pPlayer.GetRepresentID()
	if not aRepresentID then
		return
	end
	local tInfo = {}
	local tNowExterior = RideExteriorData.GetPlayerRideExterior(pPlayer)

	for k, v in pairs(RideExteriorData.tHorseDetailToRe) do
        local tExteriorInfo = RideExteriorData.GetRideExteriorInfo(tNowExterior[k], k ~= RideExteriorData.HORSE_EXTERIOR_INDEX)
		if tExteriorInfo then
			aRepresentID[v] = tExteriorInfo.dwRepresentID
		end
	end

	return aRepresentID
end

function RideExteriorData.GetExteriorTipsBtnState(dwExteriorID, bEquip)
    local tbBtnState = {}
    local tExteriorInfo = RideExteriorData.GetRideExteriorInfo(dwExteriorID, bEquip)
    if tExteriorInfo then
		if RideExteriorData.IsInPreview(dwExteriorID, bEquip) then
			table.insert(tbBtnState, {
				szName = "卸下",
				OnClick = function()
					scriptView = UIMgr.GetViewScript(VIEW_ID.PanelSaddleHorse)
					if scriptView then
						scriptView:SetExteriorPreview(0, bEquip, tExteriorInfo.nExteriorSlot)
					end
					TipsHelper.DeleteAllHoverTips()
				end
			})
		else
			table.insert(tbBtnState, {
				szName = "装备外观",
				OnClick = function()
					scriptView = UIMgr.GetViewScript(VIEW_ID.PanelSaddleHorse)
					if scriptView then
						scriptView:SetExteriorPreview(dwExteriorID, bEquip)
					end
					TipsHelper.DeleteAllHoverTips()
				end
			})
		end
        if tExteriorInfo.bCollected and (not tExteriorInfo.bHave) then
            table.insert(tbBtnState, {
                szName = g_tStrings.STR_HOMELAND_FURNITURE_ISOTYPE,
                OnClick = function()
                    UIMgr.Open(VIEW_ID.PanelRideExteriorCheckOut, {{dwExteriorID = dwExteriorID, bEquip = bEquip}}, {}, true)
                    TipsHelper.DeleteAllHoverTips()
                end
            })
        end
    end
    return tbBtnState
end