-- Author:	Jiang Zhenghao
-- Date:	2018-12-15
-- Version:	1.0
-- Description:	声望相关（包括家将）基础数据管理模块

-- Editor:	Jiang Zhenghao
-- Date:	2020-01-09
-- Version:	1.1
-- Description: 对两种类型的奖励增加子类功能支持
----------------------------------------------------------------------

---------------------- 声望势力公共数据（包括家将数据）管理模块 ----------------------
local _tRepuData =
{
	className = "ReputationBase",
	--- 势力本身相关
	m_aAllGroupedForces =  --- 表示存在分组信息的势力，包含了不会在界面上显示的
	{
		--- dwForceID,
	},

	m_tForceID2ServantNpcIndex =
	{
		---[dwForceID] = dwNpcIndex,
	},

	m_nVisibleForces = 0,

	--- 声望相关
	m_tRepuDlcStats = --- 各个版本达到顶级声望的势力数
	{
		---[nDlcIndex] = {nCount, nTotalCount},  --- nDlcIndex通过Table_GetSortedDlcList()得到的列表对应到nDlcID
	},

	m_bRepuStatsInited = false,

	--- 道具奖励相关
	m_aItemTypes =
	{
		--[[
			dwType 来自枚举类型 ITEM_TABLE_TYPE.*；
			dwSubType 来自枚举类型 EQUIPMENT_SUB(目前只有 ITEM_TABLE_TYPE.CUST_TRINKET 类型才有这一项)，也可为字符串"other"，表示未被明确指出的其他子类型
		--]]
		--- [1] = {dwType=dwType, dwSubType=dwSubType},
	},

	m_aAllSpecialRepuRewards =
	{
		---{dwTabType, dwTabIndex, dwForceID, nRequiredRepuLevel},
	},

	m_aReceivedRepuRewards =
	{
		---{nIndexInList, bReceived},--- 第1项是在m_aAllSpecialRepuRewards中的序号，第2项为 false 表示可获得但未获得
	},
	m_aUnreceivedRepuRewards =
	{
		---nIndexInList,
	},

	m_bRepuRewardsInited = false,

	--- 家将相关
	m_aServantRoleTypes =
	{
		--- [1] = szRoleType,
	},

	m_aReceivedNpcRewards =
	{
		---dwForceID,
	},
	m_aUnreceivedNpcRewards =
	{
		---dwForceID,
	},

	m_aRecentReceivedNpcForces =
	{
		---dwForceID,
	},

	m_bNpcRewardsInited = false,
	m_bNeedSortNpcRewards = false,

	--- UI常量
	---_REPU_MIN_UI_LEVEL = 3,
	_REPU_MAX_UI_LEVEL = 8,
	---_NEUTRAL_REPU_LEVEL = 3,  --- 高于此等级的声望等级X，每获得一个，[NEUTRAL_REPU_LEVEL, X]内的统计项都要加1（现在不需要）

	--- 逻辑常量
	dwNpcIDToRegainServant = 6129,
}

_tRepuData._REPU_MIN_LOGIC_LEVEL, _tRepuData._REPU_MAX_LOGIC_LEVEL = Table_GetMinMaxReputationLevel()

local _tRewardItemTypePriorities =
{
	[ITEM_TABLE_TYPE.CUST_TRINKET] = 1,
	[ITEM_TABLE_TYPE.HOMELAND] = 2,
	[ITEM_TABLE_TYPE.OTHER] = 3,
}

local _tRewardItemSubTypePriorities =
{
	[EQUIPMENT_SUB.BACK_EXTEND] = 1,
	[EQUIPMENT_SUB.WAIST_EXTEND] = 2,
	[EQUIPMENT_SUB.FACE_EXTEND] = 3,
	[EQUIPMENT_SUB.HORSE_EQUIP] = 4,
	[EQUIPMENT_SUB.HORSE] = 5,
	--["other"] = 6, --- 不应该出现
}

---- 势力本身相关
function _tRepuData.InsertForcesInDlc(aResultForces, tGroupList, dwPlayerForceID, nDlcID)
	for szGroupName, aForceList in pairs(tGroupList) do
		for _, dwForceID in ipairs(aForceList) do
			if _tRepuData.CanShowForce(dwForceID, dwPlayerForceID) then
				table.insert(aResultForces, {dwForceID, szGroupName, nDlcID})
			end
		end
	end
end

function _tRepuData.GetAllForcesInDlc(nDlcID)  --- 包含了不会在界面上显示的
	local player = GetClientPlayer()
	assert(player)
	local dwPlayerForceID = player.dwForceID

	if nDlcID > 0 then
		local aForces = {}
		local tGroupList = Table_GetAllRepuForceGroupInfo()[nDlcID]

		_tRepuData.InsertForcesInDlc(aForces, tGroupList, dwPlayerForceID, nDlcID)
		return aForces
	else
		local aTotalForces = {}
		local tAllRepuForceGroupInfo, aDlcList = Table_GetAllRepuForceGroupInfo()
		for _, nDlcID in ipairs_r(aDlcList) do
			local tGroupList = tAllRepuForceGroupInfo[nDlcID]
			_tRepuData.InsertForcesInDlc(aTotalForces, tGroupList, dwPlayerForceID, nDlcID)
		end

		return aTotalForces
	end
end

function _tRepuData.GetAllGroupedForces()
	if IsTableEmpty(_tRepuData.m_aAllGroupedForces) then
		local aAllForceGroupInfos = _tRepuData.GetAllForcesInDlc(0)
		for k, v in ipairs(aAllForceGroupInfos) do
			table.insert(_tRepuData.m_aAllGroupedForces, v[1])
		end
	end

	return _tRepuData.m_aAllGroupedForces
end

function _tRepuData.GetDlcIDAndGroupOfForce(dwForceID)
	for nDlcID, tGroupList in pairs(Table_GetAllRepuForceGroupInfo()) do
		for szGroupName, aForceList in pairs(tGroupList) do
			for _, dwThisForceID in ipairs(aForceList) do
				if dwThisForceID == dwForceID then
					return nDlcID, szGroupName
				end
			end
		end
	end

	Log("ERROR! 无法找到势力ID(" .. tostring(dwForceID) .. ")的DLC及分组信息！")
	return 0, ""
end

---- 声望相关
function _tRepuData.InitRepuOverallStatistics()
	local player = GetClientPlayer()
	assert(player)
	local dwPlayerForceID = player.dwForceID

	--- 初始化数据
	_tRepuData.m_nVisibleForces = 0
	_tRepuData.m_tRepuDlcStats = {}

	local nDlcIndex = 0
	for nDlcID, tGroupList in pairs(Table_GetAllRepuForceGroupInfo()) do
		nDlcIndex = nDlcIndex + 1
		for szGroupName, aForceList in pairs(tGroupList) do
			for _, dwForceID in ipairs(aForceList) do
				if _tRepuData.CanShowForce(dwForceID, dwPlayerForceID) then
					_tRepuData.m_nVisibleForces = _tRepuData.m_nVisibleForces + 1
					local nRepuLevel = player.GetReputeLevel(dwForceID)
					nRepuLevel = math.min(_tRepuData._REPU_MAX_UI_LEVEL, nRepuLevel)  --- 爆表的声望等级视为最大等级

					_tRepuData.m_tRepuDlcStats[nDlcIndex] = _tRepuData.m_tRepuDlcStats[nDlcIndex] or {0, 0}
					if 	nRepuLevel == _tRepuData._REPU_MAX_UI_LEVEL then
						_tRepuData.m_tRepuDlcStats[nDlcIndex][1] = _tRepuData.m_tRepuDlcStats[nDlcIndex][1] + 1
					end
					_tRepuData.m_tRepuDlcStats[nDlcIndex][2] = _tRepuData.m_tRepuDlcStats[nDlcIndex][2] + 1
				end
			end
		end
	end
end

function _tRepuData.TryInitingRepuStats(bReinit)
	if not(not(bReinit)) == _tRepuData.m_bRepuStatsInited then
		_tRepuData.InitRepuOverallStatistics()
		_tRepuData.m_bRepuStatsInited = true
		return true
	end
	return false
end

function _tRepuData.UpdateRepuOverallStatistics(dwForceID, nCurLevel, nOldLevel)
	if _tRepuData.CanShowForce(dwForceID) then
		assert(nCurLevel ~= nOldLevel)
		local nDlcID = _tRepuData.GetDlcIDAndGroupOfForce(dwForceID)
		if nDlcID > 0 then
			local tDlcStatsInfo = _tRepuData.FindDlcStatsInfoByDlcID(nDlcID)
			assert(tDlcStatsInfo)
			nCurLevel = math.min(_tRepuData._REPU_MAX_UI_LEVEL, nCurLevel)  --- 爆表的声望等级视为最大等级
			nOldLevel = math.min(_tRepuData._REPU_MAX_UI_LEVEL, nOldLevel)
			if nCurLevel > nOldLevel then
				if 	nCurLevel == _tRepuData._REPU_MAX_UI_LEVEL then
					tDlcStatsInfo[1] = tDlcStatsInfo[1] + 1
				end
			elseif nCurLevel < nOldLevel then
				if 	nOldLevel == _tRepuData._REPU_MAX_UI_LEVEL then
					tDlcStatsInfo[1] = tDlcStatsInfo[1] - 1
				end
			end
		end
	end
end

function _tRepuData.TryUpdatingRepuStats(dwForceID, nCurLevel, nOldLevel)
	if _tRepuData.m_bRepuStatsInited then
		_tRepuData.UpdateRepuOverallStatistics(dwForceID, nCurLevel, nOldLevel)
		return true
	end
	return false
end

function _tRepuData.GetTopRepuCount()
	local nCount = 0
	for key, t in pairs(_tRepuData.m_tRepuDlcStats) do
		nCount = nCount + t[1]
	end
	return nCount
end

function _tRepuData.FindDlcStatsInfoByDlcID(nDlcID)
	local aDlcList = Table_GetSortedDlcList()
	for nDlcIndex, nThisDlcID in ipairs(aDlcList) do
		if nThisDlcID == nDlcID then
			return _tRepuData.m_tRepuDlcStats[nDlcIndex]
		end
	end

	return nil
end

---- 道具奖励相关
function _tRepuData.SortItemTypes()
	local function fnCompare(tTypeL, tTypeR)
		local dwTypeL = tTypeL.dwType
		local dwTypeR = tTypeR.dwType
		if dwTypeL == dwTypeR then
			if dwTypeL == ITEM_TABLE_TYPE.CUST_TRINKET then
				local dwSubTypeL = tTypeL.dwSubType
				local dwSubTypeR = tTypeR.dwSubType
				if dwSubTypeL == dwSubTypeR then
					return false
				else
					return _tRewardItemSubTypePriorities[dwSubTypeL] < _tRewardItemSubTypePriorities[dwSubTypeR]
				end
			else -- dwTypeL == ITEM_TABLE_TYPE.OTHER/ITEM_TABLE_TYPE.HOMELAND
				return false -- 只有一个，与自己比较
			end
		else
			return _tRewardItemTypePriorities[dwTypeL] < _tRewardItemTypePriorities[dwTypeR]
		end
	end

	table.sort(_tRepuData.m_aItemTypes, fnCompare)
end

function _tRepuData.GetItemTypeByItemInfo(dwItemTabType, dwItemTabIndex)
	local dwType, dwSubType
	if dwItemTabType == ITEM_TABLE_TYPE.CUST_TRINKET then
		dwType = dwItemTabType

		local itemInfo = GetItemInfo(dwItemTabType, dwItemTabIndex)
		dwSubType = itemInfo and itemInfo.nSub
		if dwSubType and _tRewardItemSubTypePriorities[dwSubType] then
			--- Do nothing
		else
			return nil
		end
	elseif dwItemTabType == ITEM_TABLE_TYPE.HOMELAND or dwItemTabType == ITEM_TABLE_TYPE.OTHER then
		dwType = dwItemTabType
	else
		return nil
	end

	local t = {dwType=dwType, dwSubType=dwSubType}
	return t
end

function _tRepuData.GetItemTypeName(tItemUIType)
	local dwType = tItemUIType.dwType
	local dwSubType = tItemUIType.dwSubType
	if dwType == ITEM_TABLE_TYPE.CUST_TRINKET then
		if dwSubType == "other" then
			return "???"
		else
			return g_tStrings.tEquipTypeNameTable[dwSubType]
		end
	elseif dwType == ITEM_TABLE_TYPE.HOMELAND then
		return g_tStrings.STR_REPUTATION_REWARD_ITEM_TYPE_HOMELAND
	else -- dwType == ITEM_TABLE_TYPE.OTHER
		return g_tStrings.STR_REPUTATION_REWARD_ITEM_TYPE_SPECIAL
	end
end

function _tRepuData.IsItemOfItemType(dwItemTabType, dwItemTabIndex, tItemUIType)
	local t = _tRepuData.GetItemTypeByItemInfo(dwItemTabType, dwItemTabIndex)
	return t.dwType == tItemUIType.dwType and t.dwSubType == tItemUIType.dwSubType
end

function _tRepuData.InitAllRepuRewards()
	_tRepuData.m_aAllSpecialRepuRewards = {}
	_tRepuData.m_aItemTypes = {}
	local tAllForceRewardInfo = Table_GetAllReputationRewardItemInfo()
	local player = GetClientPlayer()
	assert(player)
	local dwPlayerForceID = player.dwForceID
	for dwForceID, tAllLevelRepuRewards in pairs(tAllForceRewardInfo) do
		if _tRepuData.CanShowForce(dwForceID, dwPlayerForceID) then
			for nRepuLevel = _tRepuData._REPU_MIN_LOGIC_LEVEL, _tRepuData._REPU_MAX_LOGIC_LEVEL do
				local aRewardList = tAllLevelRepuRewards[nRepuLevel]
				if aRewardList then
					for k, tItem in ipairs(aRewardList) do
						local dwTabType, dwTabIndex = tItem.dwItemTabType, tItem.dwItemTabIndex
						if _tRewardItemTypePriorities[dwTabType] then
							local tItemUIType = _tRepuData.GetItemTypeByItemInfo(dwTabType, dwTabIndex)
							if tItemUIType then
								table.insert(_tRepuData.m_aAllSpecialRepuRewards, {dwTabType, dwTabIndex, dwForceID, nRepuLevel})

								if not CheckIsInTable(_tRepuData.m_aItemTypes, tItemUIType) then
									table.insert(_tRepuData.m_aItemTypes, tItemUIType)
								end
							end
						end
					end
				end
			end
		end
	end

	_tRepuData.SortItemTypes()
end

function _tRepuData.TryInitingAllRepuRewards(bForceInit)
	if not _tRepuData.m_bRepuRewardsInited or bForceInit then
		_tRepuData.InitAllRepuRewards()
		_tRepuData.m_bRepuRewardsInited = true
	end
end

function _tRepuData.InitReceivedRepuRewards()
	_tRepuData.m_aReceivedRepuRewards = {}
	_tRepuData.m_aUnreceivedRepuRewards = {}
	local player = GetClientPlayer()
	for nIndex, tRewardInfo in ipairs(_tRepuData.m_aAllSpecialRepuRewards) do
		if player.GetReputeLevel(tRewardInfo[3]) >= tRewardInfo[4] then
			local bReceived = _tRepuData.IsItemRewardReceived(tRewardInfo[1], tRewardInfo[2])
			table.insert(_tRepuData.m_aReceivedRepuRewards, {nIndex, bReceived})
		else
			table.insert(_tRepuData.m_aUnreceivedRepuRewards, nIndex)
		end
	end
end

function _tRepuData.TryFliterItems(aItemInfoList)
    if not aItemInfoList or #aItemInfoList < 32 then
        return aItemInfoList
    end
    local player = GetClientPlayer()
    if not player then
        return aItemInfoList
    end

    local tNewItemInfoList = {}
    for _, tItemInfo in ipairs(aItemInfoList) do
        tItemInfo.dwForceMap = {}
        local itemInfo = ItemData.GetItemInfo(tItemInfo.dwItemTabType, tItemInfo.dwItemTabIndex)
        local tRecommend = TabHelper.GetEquipRecommend(itemInfo.nRecommendID)
        if tRecommend then
			for _, v in ipairs(string.split(tRecommend.kungfu_ids, "|")) do
				local dwKungfuID = tonumber(v)
				if dwKungfuID then
					if dwKungfuID == 0 then
						table.insert(tNewItemInfoList, tItemInfo)
                        break
                    else
                        local dwForceType = Kungfu_GetType(dwKungfuID)
                        if dwForceType and dwForceType == player.dwForceID then
                            table.insert(tNewItemInfoList, tItemInfo)
                            break
                        end
					end
				end
			end
		end
    end

    return tNewItemInfoList
end

---- 家将相关
function _tRepuData.InitForceID2ServantNpcIndex()
	_tRepuData.m_tForceID2ServantNpcIndex = {}
	for dwNpcIndex, dwForceID in pairs(GetPet2ReputationList()) do
		_tRepuData.m_tForceID2ServantNpcIndex[dwForceID] = dwNpcIndex
	end
end

function _tRepuData.GetRepuServantNpcIndexByForceID(dwForceID)
	if IsTableEmpty(_tRepuData.m_tForceID2ServantNpcIndex) then
		_tRepuData.InitForceID2ServantNpcIndex()
	end
	local bSuccess = true
	local dwNpcIndex = _tRepuData.m_tForceID2ServantNpcIndex[dwForceID]
	if not dwNpcIndex then
		---Log("WARNING!无法找到声望势力" .. tostring(dwForceID) .. "对应的家将index！")

		dwNpcIndex = 0
		bSuccess = false
	end
	return dwNpcIndex, bSuccess
end

function _tRepuData.GetServantInfoByForceID(dwForceID, bOnlyIndex)
	local dwNpcIndex, bSuccess = _tRepuData.GetRepuServantNpcIndexByForceID(dwForceID)
	if bOnlyIndex then
		return dwNpcIndex, bSuccess
	else
		local tInfo
		if bSuccess then
			tInfo = Table_GetServantInfo(dwNpcIndex)
		end
		return tInfo, (tInfo ~= nil) and bSuccess
	end
end

function _tRepuData.GetForceIDByRepuServantNpcIndex(dwServantNpcIndex)
	local dwForceID = GetPet2ReputationList()[dwServantNpcIndex]
	if not dwForceID then
		Log("WARNING!无法找到家将index == " .. tostring(dwServantNpcIndex) .. "对应的声望势力！")
		dwForceID = 0
	end
	return dwForceID
end

function _tRepuData.InitReceivedNpcRewards()
	_tRepuData.m_aReceivedNpcRewards = {}
	_tRepuData.m_aUnreceivedNpcRewards = {}
	_tRepuData.m_aServantRoleTypes = {}

	local player = GetClientPlayer()
	local dwPlayerForceID = player.dwForceID
	for nIndex, dwForceID in ipairs(_tRepuData.GetAllGroupedForces()) do
		if _tRepuData.CanShowForce(dwForceID, dwPlayerForceID) then
			local tInfo = _tRepuData.GetServantInfoByForceID(dwForceID)
			if tInfo then
				local nCurRepuLevel = player.GetReputeLevel(dwForceID)
				local nRequiredRepuLevel = tInfo.nRequiredRepuLevel
				if nCurRepuLevel >= nRequiredRepuLevel then
					table.insert(_tRepuData.m_aReceivedNpcRewards, dwForceID)
				else
					table.insert(_tRepuData.m_aUnreceivedNpcRewards, dwForceID)
				end

				local szRoleType = tInfo.szRoleType
				if g_tStrings.tServantRoleType[szRoleType] and not CheckIsInTable(_tRepuData.m_aServantRoleTypes, szRoleType) then
					table.insert(_tRepuData.m_aServantRoleTypes, szRoleType)
				end
			else
				Log("==== 势力(id: " .. tostring(dwForceID) .. ")没有对应的家将信息，忽略")
			end
		else
			Log("==== 势力(id: " .. tostring(dwForceID) .. ")对玩家不可见，忽略")
		end
	end
end

function _tRepuData.SortReceivedNpcRewards()  --- 可能需要把比较函数作为参数传递进去
	local player = GetClientPlayer()
	local function _fnCompare(dwForceIDL, dwForceIDR)
		if dwForceIDL == dwForceIDR then
			return false
		end

		local bRecentlyReceivedL = CheckIsInTable(_tRepuData.m_aRecentReceivedNpcForces, dwForceIDL)
		local bRecentlyReceivedR = CheckIsInTable(_tRepuData.m_aRecentReceivedNpcForces, dwForceIDR)
		if bRecentlyReceivedL == bRecentlyReceivedR then
			local nDlcIDL = _tRepuData.GetDlcIDAndGroupOfForce(dwForceIDL)
			local nDlcIDR = _tRepuData.GetDlcIDAndGroupOfForce(dwForceIDR)
			if nDlcIDL ~= nDlcIDR then
				return nDlcIDL > nDlcIDR
			else
				local nRepuLevelL = player.GetReputeLevel(dwForceIDL)
				local nRepuLevelR = player.GetReputeLevel(dwForceIDR)
				if nRepuLevelL == nRepuLevelR then
					return player.GetReputation(dwForceIDL) > player.GetReputation(dwForceIDR)
				else
					return nRepuLevelL > nRepuLevelR
				end
			end
		else
			return bRecentlyReceivedL
		end
	end

	table.sort(_tRepuData.m_aReceivedNpcRewards, _fnCompare)
	table.sort(_tRepuData.m_aUnreceivedNpcRewards, _fnCompare)
end

function _tRepuData.GetReceivedNpcRewards(bForceInit)
	_tRepuData.TryInitingNpcRewards(bForceInit)
	return _tRepuData.m_aReceivedNpcRewards, _tRepuData.m_aUnreceivedNpcRewards
end

function _tRepuData.UpdateRecentNpcRewardForces()
	_tRepuData.m_aRecentReceivedNpcForces = {}
	for i = 1, 5 do
		local nOffset = 42 + (i-1)*2
		local dwForceID = GetClientPlayer().GetPlayerIdentityManager().GetCustomUnsigned2(PLAYER_IDENTITY_TYPE.ARTIST, nOffset)
		if dwForceID > 0 and not CheckIsInTable(_tRepuData.m_aRecentReceivedNpcForces, dwForceID) then
			table.insert(_tRepuData.m_aRecentReceivedNpcForces, dwForceID)
		end
	end
end

function _tRepuData.GetRecentNpcRewardForces()
	return _tRepuData.m_aRecentReceivedNpcForces
end

--[[
function _tRepuData.ClearLogicData()
	--- 待补充
end
--]]

function _tRepuData.TryInitingNpcRewards(bForceInit)
	if not _tRepuData.m_bNpcRewardsInited or bForceInit then
		_tRepuData.InitReceivedNpcRewards()
		_tRepuData.UpdateRecentNpcRewardForces()
		_tRepuData.SortReceivedNpcRewards()

		_tRepuData.m_bNpcRewardsInited = true
	end
end

---- 逻辑相关辅助函数
function _tRepuData.CanShowForce(dwForceID, dwPlayerForceID)
	if not dwPlayerForceID then
		local player = GetClientPlayer()
		assert(player)
		dwPlayerForceID = player.dwForceID
	end

	local tRepuInfo = Table_GetReputationForceInfo(dwForceID)
	local bCanShow = true
	if not tRepuInfo then
		bCanShow = false
	elseif tRepuInfo.bHide then
		if (not tRepuInfo.bInShow) or dwPlayerForceID ~= dwForceID then
			bCanShow = false
		end
	else
		if tRepuInfo.nInNoShowForce > 0 and dwPlayerForceID == tRepuInfo.nInNoShowForce then
			bCanShow = false
		end
	end
	---if player.IsReputationHide(dwForceID) then  --- 现阶段不需要隐藏未获得声望的势力（若重新启用，则需要在响应某些消息的时候去更新 _tRepuData.m_tRepuDlcStats 等数据）
	---	bCanShow = false
	---end
	return bCanShow
end

--[[
function _tRepuData.IsSpecialReward(dwTabType, dwTabIndex)
	local itemInfo = GetItemInfo(dwTabType, dwTabIndex)
	if (itemInfo.nGenre == ITEM_GENRE.EQUIPMENT and IsPendantItem(itemInfo)) then
		return true
	end

	return false
end
--]]

--[[
function _tRepuData.IsSpecialItemRewardReceived(dwTabType, dwTabIndex)
	local player = GetClientPlayer()
	return player and player.IsPendentExist(dwTabIndex)
end
--]]

--[[
function _tRepuData.IsNpcRewardReceived(dwForceID)  -- This is never used!
	local dwNpcIndex, bSuccess = _tRepuData.GetServantInfoByForceID(dwForceID, true)
	local player = GetClientPlayer()
	assert(player)
	return IsReputationPetReceived(player, dwNpcIndex)
end
--]]

function _tRepuData.IsItemRewardReceived(dwTabType, dwTabIndex) --- 需要先保证声望等级达标
	local player = GetClientPlayer()
	if player then
		local itemInfo = GetItemInfo(dwTabType, dwTabIndex)
		if (itemInfo.nGenre == ITEM_GENRE.EQUIPMENT and IsPendantItem(itemInfo)) then --- 只针对"挂件"类型进行判断
			return player.IsPendentExist(dwTabIndex)
		else
			return true
		end
	end

	return false
end

---- 全局消息响应
local function l_OnRepuValueUpdate()
	--- arg0~arg1: dwForceID, bNewForce
	if _tRepuData.m_bNpcRewardsInited then
		--_tRepuData.SortReceivedNpcRewards() -- 优化效率，等到需要的时候（现在是打开声望面板界面时）再去排序
		_tRepuData.m_bNeedSortNpcRewards = true
	end
	FireUIEvent("UI_UPDATE_REPUTATION", arg0)
end

local function l_OnRepuLevelChange()
	--- arg0~arg2: dwForceID, nOldLevel
	local dwForceID, nOldLevel = arg0, arg1
	local nCurLevel = GetClientPlayer().GetReputeLevel(dwForceID)
	_tRepuData.TryUpdatingRepuStats(dwForceID, nCurLevel, nOldLevel)
	if _tRepuData.m_bNpcRewardsInited then
		_tRepuData.UpdateRecentNpcRewardForces()  --- 实践发现此时并不能够获取到最新的数据，待解决……
		_tRepuData.SortReceivedNpcRewards()
	end
	if _tRepuData.m_bRepuRewardsInited then
		_tRepuData.InitReceivedRepuRewards()  --- 要经常更新
	end

	FireUIEvent("UI_ON_REPU_LEVEL_CHANGE", dwForceID, nOldLevel, nCurLevel)
end

local function l_OnPlayerForceChanged()  -- 会影响到 CanShowForce() 的结果
	-- arg0~arg2: dwPlayerID
	local player = GetClientPlayer()
	if player and arg0 == player.dwID then
		_tRepuData.TryInitingRepuStats(_tRepuData.m_bRepuStatsInited)
		_tRepuData.TryInitingNpcRewards(_tRepuData.m_bNpcRewardsInited)
		_tRepuData.TryInitingAllRepuRewards(_tRepuData.m_bRepuRewardsInited)

		FireUIEvent("UI_ON_PLAYER_FORCE_CHANGED")
	end
end

local function l_SortReceivedNpcRewards()
	if _tRepuData.m_bNeedSortNpcRewards then
		_tRepuData.SortReceivedNpcRewards()
		_tRepuData.m_bNeedSortNpcRewards = false
	end
end

local function l_OnSyncRoleDataEnd()
	_tRepuData.TryInitingRepuStats(_tRepuData.m_bRepuStatsInited)
	_tRepuData.TryInitingNpcRewards(_tRepuData.m_bNpcRewardsInited)
	-- 可能还要尝试去更新别的数据

	FireUIEvent("UI_ON_SYNC_REPU_DATA_END")
end

Event.Reg(_tRepuData, "UPDATE_REPUTATION", l_OnRepuValueUpdate)
Event.Reg(_tRepuData, "REPUTATION_LEVEL_UP", l_OnRepuLevelChange)
Event.Reg(_tRepuData, "CURRENT_PLAYER_FORCE_CHANGED", l_OnPlayerForceChanged)
Event.Reg(_tRepuData, "UI_REPUTATION_SORT_RECVED_NPC_REWARDS", l_SortReceivedNpcRewards)
Event.Reg(_tRepuData, "SYNC_ROLE_DATA_END", l_OnSyncRoleDataEnd)

---- 公共接口
RepuData =
{
	---- 接口
	GetAllForcesInDlc = _tRepuData.GetAllForcesInDlc,
	GetDlcIDAndGroupOfForce = _tRepuData.GetDlcIDAndGroupOfForce,
	GetTopRepuCount = _tRepuData.GetTopRepuCount,
	InitRepuOverallStatistics = _tRepuData.InitRepuOverallStatistics,
	TryInitingRepuStats = _tRepuData.TryInitingRepuStats,
	UpdateRepuOverallStatistics = _tRepuData.UpdateRepuOverallStatistics,
	TryUpdatingRepuStats = _tRepuData.TryUpdatingRepuStats,

	TryInitingAllRepuRewards = _tRepuData.TryInitingAllRepuRewards,
	InitReceivedRepuRewards = _tRepuData.InitReceivedRepuRewards,
	TryFliterItems = _tRepuData.TryFliterItems,

	GetServantInfoByForceID = _tRepuData.GetServantInfoByForceID,
	GetForceIDByRepuServantNpcIndex = _tRepuData.GetForceIDByRepuServantNpcIndex,
	SortItemTypes = _tRepuData.SortItemTypes,
	---SortReceivedNpcRewards = _tRepuData.SortReceivedNpcRewards,

	GetItemTypeName = _tRepuData.GetItemTypeName,
	IsItemOfItemType = _tRepuData.IsItemOfItemType,
	IsItemRewardReceived = _tRepuData.IsItemRewardReceived,
	GetReceivedNpcRewards = _tRepuData.GetReceivedNpcRewards,
	---UpdateRecentNpcRewardForces = _tRepuData.UpdateRecentNpcRewardForces,
	TryInitingNpcRewards = _tRepuData.TryInitingNpcRewards,
	GetRecentNpcRewardForces = _tRepuData.GetRecentNpcRewardForces,
	CanShowForce = _tRepuData.CanShowForce,

	---- 属性
	GetRepuMinLogicLevel = function() return _tRepuData._REPU_MIN_LOGIC_LEVEL end,
	GetRepuMaxLogicLevel = function() return _tRepuData._REPU_MAX_LOGIC_LEVEL end,
	GetRepuMaxLevel = function() return _tRepuData._REPU_MAX_UI_LEVEL end,
	GetVisibleForces = function() return _tRepuData.m_nVisibleForces end,
	GetRepuDlcStats = function() return _tRepuData.m_tRepuDlcStats end,
	GetItemTypes = function() return _tRepuData.m_aItemTypes end,
	GetAllRepuRewards = function() return _tRepuData.m_aAllSpecialRepuRewards end,
	GetReceivedRepuRewards = function() return _tRepuData.m_aReceivedRepuRewards end,
	GetUnreceivedRepuRewards = function() return _tRepuData.m_aUnreceivedRepuRewards end,
	GetServantRoleTypes = function() return _tRepuData.m_aServantRoleTypes end,
	GetRegainServantNpcID = function() return _tRepuData.dwNpcIDToRegainServant end,
}

---------------------- 家将召唤/动作/定格功能管理模块 ----------------------
local m_dwServantNpcIndex = 0
local m_dwReservedServantIndex = 0  --- 备份的家将Index

------ 家将召唤/收回相关
local function l_DoCallServant(dwNpcIndex)
	if IsReputationPetReceived(GetClientPlayer(), dwNpcIndex) then
		rlcmd(("accompany 1 %d"):format(dwNpcIndex))
	else
		Log("ERROR!你正试图召唤尚未获得的家将(ID: " .. tostring(dwNpcIndex) .. ")！")
		local dwForceID = _tRepuData.GetForceIDByRepuServantNpcIndex(dwNpcIndex)

		local tServantInfo = Table_GetServantInfo(dwNpcIndex)
		local nRequiredRepuLevel = tServantInfo.nRequiredRepuLevel

		local player = GetClientPlayer()
		local nCurRepuLevel = player.GetReputeLevel(dwForceID)
		if nCurRepuLevel >= nRequiredRepuLevel then
			OutputMessage("MSG_ANNOUNCE_NORMAL", FormatString(g_tStrings.STR_REPUTATION_SERVANT_LOST_MESSAGE, Table_GetNpcTemplateName(RepuData.GetRegainServantNpcID())))
		end

		FireUIEvent("UI_ON_GET_LOSE_NPC_PET", dwForceID, false)

		return false
	end
	return true
end

function Servant_CallServantByID(dwID, bIsNpcIndex, bApplyBuff, bDontFireEvent)
	local dwNpcIndex = bIsNpcIndex and dwID or _tRepuData.GetRepuServantNpcIndexByForceID(dwID)
	if m_dwServantNpcIndex ~= dwNpcIndex then
		if not l_DoCallServant(dwNpcIndex) then
			return false
		end
		local dwOldServantNpcIndex = m_dwServantNpcIndex
		m_dwServantNpcIndex = dwNpcIndex

		if dwOldServantNpcIndex > 0 and not bDontFireEvent then
			FireUIEvent("UI_CALL_REPU_SERVANT", dwOldServantNpcIndex, false)
		end

		if bApplyBuff then
			RemoteCallToServer("On_NpcPet_AddNpcBuff", dwNpcIndex)
		end

		if not bDontFireEvent then
			FireUIEvent("UI_CALL_REPU_SERVANT", dwNpcIndex, true)
		end
	end
	return true
end

function Servant_DismissServantByID(dwID, bIsNpcIndex, bDontFireEvent)
	local dwNpcIndex
	if dwID then
		dwNpcIndex = bIsNpcIndex and dwID or _tRepuData.GetRepuServantNpcIndexByForceID(dwID)
	else
		dwNpcIndex = m_dwServantNpcIndex
	end
	if m_dwServantNpcIndex ~= dwNpcIndex then
		Log("WARNING!你现在要收回的家将（ID：" .. tostring(dwNpcIndex) .. ")不是当前被召唤的！")
		return false
	else
		if m_dwServantNpcIndex ~= 0 then
			rlcmd("accompany 2")

			if not bDontFireEvent then
				m_dwServantNpcIndex = 0
				FireUIEvent("UI_CALL_REPU_SERVANT", dwNpcIndex, false)
			end
		end
		return true
	end
end

--- 返回值： bCallServant, bSuccess, dwNpcIndex
function Servant_CallOrDismissServant(dwForceID, bApplyBuff)
	local dwNpcIndex = _tRepuData.GetRepuServantNpcIndexByForceID(dwForceID)
	if dwNpcIndex == Servant_GetCurServantNpcIndex() then
		return false, Servant_DismissServantByID(dwNpcIndex, true), dwNpcIndex
	else
		return true, Servant_CallServantByID(dwNpcIndex, true, bApplyBuff), dwNpcIndex
	end
end

function Servant_GetCurServantNpcIndex()
	return m_dwServantNpcIndex
end

function Servant_ReserveServant()
	m_dwReservedServantIndex = m_dwServantNpcIndex
end

function Servant_RecoverServant()
	if m_dwServantNpcIndex ~= m_dwReservedServantIndex then
		if m_dwReservedServantIndex ~= 0 then
			Servant_CallServantByID(m_dwReservedServantIndex, true, false, false)
		else
			Servant_DismissServantByID()
		end

		m_dwServantNpcIndex = m_dwReservedServantIndex
	end
end

local function l_OnGetOrLoseRepuServant()
	--- arg0~arg2: dwPlayerID, dwForceID, bGet
	local dwPlayerID, dwForceID, bGet = arg0, arg1, arg2
	if dwPlayerID == UI_GetClientPlayerID() then
		if (not bGet) then
			local dwServantNpcIndex = _tRepuData.GetRepuServantNpcIndexByForceID(dwForceID)
			if dwServantNpcIndex == m_dwServantNpcIndex then
				rlcmd("accompany 2")
				m_dwServantNpcIndex = 0
				FireUIEvent("UI_CALL_REPU_SERVANT", dwServantNpcIndex, false)
				OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_REPUTATION_LOSE_SERVANT_MESSAGE, dwForceID) .. "\n")
			end
		end

		_tRepuData.TryInitingNpcRewards(_tRepuData.m_bNpcRewardsInited)
		FireUIEvent("UI_ON_GET_LOSE_NPC_PET", dwForceID, bGet)
	end
end

local function l_OnPlayerLeaveScene()
	Servant_DismissServantByID(nil, nil, true)
end

local function l_OnLoadingEnd()
	if m_dwServantNpcIndex ~= 0 then
		l_DoCallServant(m_dwServantNpcIndex)
	end
end

Event.Reg(_tRepuData, "ON_GET_LOSE_NPC_PET", l_OnGetOrLoseRepuServant)
Event.Reg(_tRepuData, EventType.OnClientPlayerLeave, l_OnPlayerLeaveScene)
Event.Reg(_tRepuData, "LOADING_END", l_OnLoadingEnd)

------ 家将动作相关（包括定格）
local m_bFreezingServant = false

function Servant_DoActionByID(dwActionID)
	rlcmd(("client action 0 %d"):format(dwActionID))
end

function Servant_Freeze()
	if not m_bFreezingServant then
		rlcmd("client action 0 135000")
		m_bFreezingServant = true
	else
		Log("WARNING!试图在已经锁定家将动作的时候将其锁定！")
	end
end

function Servant_CancelFreeze()
	if m_bFreezingServant then
		rlcmd("client action 0 135000")
		m_bFreezingServant = false
	else
		Log("WARNING!试图在未锁定家将动作的时候对其解除锁定！")
	end
end

function Servant_IsInFreeze()
	return m_bFreezingServant
end

function Servant_ClearFreezeState()
	m_bFreezingServant = false
end

function Servant_GetActionInfoList(dwNpcIndex)
	local aActionInfoList =
	{
		--[[
			{dwActionID=dwActionID,
			szName=szName,
			nIconID=nIconID}
		--]]
	}
	local aAllCommonActionInfos = Table_GetServantAllCommonActionInfos()
	for nIndex, tInfo in ipairs(aAllCommonActionInfos) do
		local dwActionID = tInfo.dwActionID
		if CanServantDoAction(dwNpcIndex, dwActionID) then
			table.insert(aActionInfoList,
					{dwActionID=dwActionID, szName=tInfo.szName, nIconID=tInfo.nIconID})
		end
	end

	local tSpecialActionInfo = Table_GetServantSpecialActionInfoByNpcIndex(dwNpcIndex)
	if tSpecialActionInfo then
		local dwSpecialActionID = tSpecialActionInfo.dwActionID
		if CanServantDoAction(dwNpcIndex, dwSpecialActionID) then
			table.insert(aActionInfoList,
					{dwActionID=dwSpecialActionID, szName=tSpecialActionInfo.szActionName, nIconID=tSpecialActionInfo.nIconID})

		end
	end
	return aActionInfoList
end
---------------------- 声望排名数据管理模块 ----------------------

local l_fReputationRank = 0
local _REPU_RANK_DIFF_THRESHOLD = 0.0005  --- 排名数值的变动超过此数值时才更新l_fReputationRank（精确度是0.001，由于显示时是四舍五入，所以需要精确到它的一半）
local l_bRepuRankInited = false

local function l_OnUpdateReputationRank()
	--- arg0: fRank(0到1的小数)
	local fNewRepuRank = arg0
	if math.abs(fNewRepuRank - l_fReputationRank) >= _REPU_RANK_DIFF_THRESHOLD then
		local bNeedShowTip = l_bRepuRankInited and (fNewRepuRank > l_fReputationRank)
		l_fReputationRank = fNewRepuRank

		Event.Dispatch(EventType.OnUpdateReputationRank)
		if bNeedShowTip then
			OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_REPUTATION_RANK_UP_MESSAGE, GetRoundedNumber(100 * l_fReputationRank, 1)) .. "\n")
		end
	end

	if not l_bRepuRankInited then
		l_bRepuRankInited = true
	end
end

function Reputation_GetSelfRepuRank()
	return l_fReputationRank
end

function Reputation_IsSelfRepuRankInited()
	return l_bRepuRankInited
end

Event.Reg(_tRepuData, "ON_UPDATE_REPUTATION_RANK", l_OnUpdateReputationRank)  --- 玩家在各个势力中的声望总值在全体玩家中的百分比得到了更新

---------------------- 测试用接口 ----------------------
--[[
function RepuData_GetServantInfoByForceID(dwForceID)
	local player = GetClientPlayer()
	local bRecentlyReceived = CheckIsInTable(_tRepuData.m_aRecentReceivedNpcForces, dwForceID)
	local nDlcID = _tRepuData.GetDlcIDAndGroupOfForce(dwForceID)
	local nRepuLevel = player.GetReputeLevel(dwForceID)
	local nRepuValue = player.GetReputation(dwForceID)
	local szInfo = "对应势力ID：" .. tostring(dwForceID) .. "\n是否是最近获得的：" .. tostring(bRecentlyReceived) ..
			"\n对应的DLC ID：" .. tostring(nDlcID) .. "\n声望等级：" .. tostring(nRepuLevel) .. "\n声望值：" .. tostring(nRepuValue)
	return szInfo
end
--]]

function RepuData_FindHiddenServantIDs()
	local tTab = g_tTable.Servant
	for i = 2, tTab:GetRowCount() do
		local tRow = tTab:GetRow(i)
		local dwNpcIndex = tRow.dwNpcIndex

		local dwForceID = _tRepuData.GetForceIDByRepuServantNpcIndex(dwNpcIndex)
		if dwForceID == 0 then
			--- Do nothing
		elseif not _tRepuData.CanShowForce(dwForceID) then
			Log("==== 玩家不能显示知交(id: " .. tostring(dwNpcIndex) .. ")对应的势力(id: " .. tostring(dwForceID) .. ")")
		end
	end
end
