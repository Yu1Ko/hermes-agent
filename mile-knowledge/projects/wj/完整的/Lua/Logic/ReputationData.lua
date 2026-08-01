ReputationData =
{
	---- 逻辑数据
	aRecentConcernedForces = {},
}

function ReputationData.GetAllForcesInCurDlc(nDlcID)
	ReputationData.aForceListInCurDlc = RepuData.GetAllForcesInDlc(nDlcID)
end

function ReputationData.GetSortForceList(nDlcID)
	ReputationData.GetAllForcesInCurDlc(nDlcID)

	local function _fnCompare(tInfoL, tInfoR)
		if tInfoL == tInfoR then
			return false
		end

		local dwForceIDL = tInfoL[1]
		local dwForceIDR = tInfoR[1]
		local bIsRecentRepuL = CheckIsInTable(ReputationData.aRecentConcernedForces, dwForceIDL)
		local bIsRecentRepuR = CheckIsInTable(ReputationData.aRecentConcernedForces, dwForceIDR)
		if bIsRecentRepuL == bIsRecentRepuR then
			local player = GetClientPlayer()
			local nRepuLevelL = player.GetReputeLevel(dwForceIDL)
			local nRepuLevelR = player.GetReputeLevel(dwForceIDR)
			if nRepuLevelL == nRepuLevelR then
				return player.GetReputation(dwForceIDL) > player.GetReputation(dwForceIDR)
			else
				return nRepuLevelL > nRepuLevelR
			end
		else
			return bIsRecentRepuL
		end
	end

	local aSortedData = {}
	for i = 1, #ReputationData.aForceListInCurDlc do
		table.insert(aSortedData, ReputationData.aForceListInCurDlc[i])
	end
	table.sort(aSortedData, _fnCompare)

	return aSortedData
end

function ReputationData.IsForceIDInCurDlc(dwForceID)
	for k, v in ipairs(ReputationData.aForceListInCurDlc) do
		if v[1] == dwForceID then
			return true
		end
	end
	return false
end

function ReputationData.GetForceGroupNameListInDlc(nDlcID)  --- 以后考虑顺序的安排
	if nDlcID > 0 then
		local tGroupInfo = Table_GetAllRepuForceGroupInfo()[nDlcID]
		local aGroupList = {}
		for szGroupName, _ in pairs(tGroupInfo) do
			table.insert(aGroupList, szGroupName)
		end
		return aGroupList
	elseif nDlcID == 0 then
		local aTotalGroupList = {}
		local aDlcList = Table_GetSortedDlcList()
		for nDlcIndex, nThisDlcID in ipairs(aDlcList) do
			local tGroupInfo = ReputationData.GetForceGroupNameListInDlc(nThisDlcID)
			for _, szGroupName in pairs(tGroupInfo) do
				if not CheckIsInTable(aTotalGroupList, szGroupName) then
					table.insert(aTotalGroupList, szGroupName)
				end
			end
		end
		return aTotalGroupList
	end
end

function ReputationData.GetMapIDsInCurDlc()
	local aAllMapIDs = {}
	for i = 1, #ReputationData.aForceListInCurDlc do
		local dwForceID = ReputationData.aForceListInCurDlc[i][1]
		local aMapIDs = Table_GetReputationForceMaps(dwForceID)
		assert(aMapIDs)
		for k, dwMapID in ipairs(aMapIDs) do
			if not CheckIsInTable(aAllMapIDs, dwMapID) then
				table.insert(aAllMapIDs, dwMapID)
			end
		end
	end
	return aAllMapIDs
end

function ReputationData.GetMapRegionInfos(aMapIDS)
	local tMapRegionInfos =
	{
		---[nRegionID] = {{dwMapID,}, tCopy={dwMapID,},},
	}
	for i = 1, #aMapIDS do
		local dwMapID = aMapIDS[i]
		local tMapInfo = Table_GetMap(dwMapID)
		local nRegionID = tMapInfo.dwRegionID
		if not tMapRegionInfos[nRegionID] then
			tMapRegionInfos[nRegionID] = {}
		end

		if tMapInfo.nGroup == ReputationData._GROUP_TYPE_COPY then
			if not tMapRegionInfos[nRegionID].tCopy then
				tMapRegionInfos[nRegionID].tCopy = {}
			end
			table.insert(tMapRegionInfos[nRegionID].tCopy, dwMapID)
		else
			table.insert(tMapRegionInfos[nRegionID], dwMapID)
		end
	end

	return tMapRegionInfos
end

function ReputationData.GetMapsInCurDlcAndRegion(nRegionID)
	local tMapRegionInfos = ReputationData.GetMapRegionInfos(ReputationData.GetMapIDsInCurDlc())
	return tMapRegionInfos[nRegionID]  --- {{dwMapID,}, tCopy={dwMapID,},}
end

function ReputationData.SetOnlyShowForAchievement(bShow)
	ReputationData.bOnlyShowForAchievement = bShow
end

function ReputationData.ResetOnlyShowForAchievement()
	ReputationData.bOnlyShowForAchievement = false
end

function ReputationData.InitFilter(nSelectDlcID)
	FilterDef.Reputation[1].tbList = {}
	FilterDef.Reputation[2].tbList = {}
	FilterDef.Reputation[3].tbList = {}

	local tbIndexToLevelMap = {}
	local tbIndexToGroupMap = {}

	-- 地图筛选器，仅有[全部地图]和[当前地图]两项
	table.insert(FilterDef.Reputation[1].tbList, g_tStrings.STR_REPUTATION_ALL_MAPS)
	table.insert(FilterDef.Reputation[1].tbList, "当前地图")

	-- 等级筛选器
	table.insert(FilterDef.Reputation[2].tbList, g_tStrings.STR_ALL_REPU_LEVELS)
    local nMinLevel, nMaxLevel = Table_GetMinMaxReputationLevel()
	local nIndex = 2
    for nLevel = nMinLevel, nMaxLevel do
        local tLevelInfo = Table_GetReputationLevelInfo(nLevel)
        local szName = UIHelper.GBKToUTF8(tLevelInfo.szName)
        table.insert(FilterDef.Reputation[2].tbList, szName)
		tbIndexToLevelMap[nIndex] = nLevel
		nIndex = nIndex + 1
		if szName == "钦佩" then -- 屏蔽钦佩以上的筛选
            break
        end
    end

	-- 势力筛选器
	table.insert(FilterDef.Reputation[3].tbList, g_tStrings.STR_ALL_REPU_FORCE_GROUPS)
	local nGroupIndex = 2
    local aGroupNameList = ReputationData.GetForceGroupNameListInDlc(nSelectDlcID)
    for _, szGroupName in ipairs(aGroupNameList) do
        local szName = UIHelper.GBKToUTF8(szGroupName)
		table.insert(FilterDef.Reputation[3].tbList, szName)
		tbIndexToGroupMap[nGroupIndex] = szName
		nGroupIndex = nGroupIndex + 1
    end

	return tbIndexToLevelMap, tbIndexToGroupMap
end

function ReputationData.CanUseReputationItem(dwForceID)
	local dwQusetID_YSJS = 14615
	local dwQuestID_MBHMXB = 14616
    local tReputeItemMap = GetReputeItemMap()
    local tReputeForceMap = GetReputeForceMap()
	local player = g_pClientPlayer
    for dwIndex, tItemConfig in pairs(tReputeItemMap) do
		local tForceConfig = tReputeForceMap[tItemConfig.nType][dwForceID]
        if tForceConfig then
			--处理阴山集市和觅宝会声望不能同时加
			local bMatchQuest = true
			if tForceConfig.dwReputeIndex == RELATION_FORCE.ANSHI_YINSHANHEISHI then
				local nQuestPhase_YSJS = player.GetQuestPhase(dwQusetID_YSJS)
				bMatchQuest = nQuestPhase_YSJS == 3
			elseif tForceConfig.dwReputeIndex == RELATION_FORCE.ANSHI_MIBAOHUI_MOXIBU then
				local nQuestPhase_MBHMXB = player.GetQuestPhase(dwQuestID_MBHMXB)
				bMatchQuest = nQuestPhase_MBHMXB == 3
			end
			-- 有阵营需求的要求阵营匹配
			local bMatchCamp = not tForceConfig.nCamp or tForceConfig.nCamp == player.nCamp
			if bMatchQuest and bMatchCamp then
				return true
			end            
        end        
    end
	return false
end

function ReputationData.ClearFilterState()
	ReputationData.szLastKeyWord = nil
	FilterDef.Reputation.Reset()
end

Event.Reg(ReputationData, EventType.OnRoleLogin, function ()
	ReputationData.ClearFilterState()
end)