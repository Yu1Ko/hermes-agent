CharacterExteriorData = CharacterExteriorData or {}

local self = CharacterExteriorData
local CUSTOM_COUNT = 5
local tExteriorInfo =
{
	-- [1] = tOneUiConfigLine,
}

local function InitExteriorInfo()
	if not IsTableEmpty(tExteriorInfo) then
		return
	end
	local nCount = g_tTable.ExteriorInfo:GetRowCount()
	for i = 2, nCount do
		local tLine = clone(g_tTable.ExteriorInfo:GetRow(i))

		for j = 1, 2 do
			local szRpIDGroups = tLine["szRepresentIDGroups" .. j]
			local aRpIDGroups = SplitString(szRpIDGroups, "|")
			tLine["aRepresentIDGroups" .. j] = {}
			for _, szOneRpGroup in ipairs(aRpIDGroups) do
				local aRpIDsInGroup = SplitString(szOneRpGroup, ";")
				local tOneRpGroup = {}
				for _, szOneRpIDInfo in ipairs(aRpIDsInGroup) do
					local t = SplitString(szOneRpIDInfo, ":")
					local nRepresentIndex = tonumber(t[1])
					local dwRepresentID = tonumber(t[2])
					tOneRpGroup[nRepresentIndex] = dwRepresentID
				end
				table.insert(tLine["aRepresentIDGroups" .. j], tOneRpGroup)
			end
			tLine["szRepresentIDGroups" .. j] = nil
		end

		tExteriorInfo[i] = tLine
	end
end

local function DoesInfoRIDsMatchPlayer(aRIDGroups, tPlayerRIDs)
	local bMatch = true
	for _, tOneRpGroup in ipairs(aRIDGroups) do
		bMatch = true
		for nRpIndex, dwRpID in pairs(tOneRpGroup) do
			if tPlayerRIDs[nRpIndex] ~= dwRpID then
				bMatch = false
				break
			end
		end
		if bMatch then
			break
		end
	end

	return bMatch
end

local function DoesExteriorInfoMatch(tLine, tPlayerRIDs)
	local pPlayer = GetClientPlayer()
	if not pPlayer then
		return
	end

	local bPlayerHideBackCloakSprintSFX = pPlayer.bHideBackCloakSprintSFX
	local bPlayerOnHorse = pPlayer.bOnHorse
	local nPlayerRoleType = pPlayer.nRoleType

	local nThisOnHorse = tLine.nOnHorse
	if not (nThisOnHorse == -1 or
			(nThisOnHorse == 0 ) or
			(nThisOnHorse == 1 and bPlayerOnHorse))
	then
		return false
	end

	local nThisRoleType = tLine.nRoleType
	if nThisRoleType ~= -1 and nThisRoleType ~= nPlayerRoleType then
		return false
	end

	local nThisBackCloakSprintSfx = tLine.nBackCloakSprintSfx
	if not (nThisBackCloakSprintSfx == -1 or
			(nThisBackCloakSprintSfx == 0 and bPlayerHideBackCloakSprintSFX) or
			(nThisBackCloakSprintSfx == 1 and not bPlayerHideBackCloakSprintSFX)) then
		return false
	end

	local bMatch1 = DoesInfoRIDsMatchPlayer(tLine.aRepresentIDGroups1, tPlayerRIDs)
	local bMatch2 = DoesInfoRIDsMatchPlayer(tLine.aRepresentIDGroups2, tPlayerRIDs)

	return bMatch1 and bMatch2
end

function CharacterExteriorData.Init()

end

function CharacterExteriorData.UnInit()

end

function CharacterExteriorData.FindMatchedExteriorInfo(tPlayerRIDs)
	InitExteriorInfo()
	local aRes = {}

	for _, tLine in pairs(tExteriorInfo) do
		local bFit = DoesExteriorInfoMatch(tLine, tPlayerRIDs)
		if bFit then
			table.insert(aRes, tLine)
		end
	end
	return aRes
end

function CharacterExteriorData.IsExtrior(aRepresentIDGroups)
	local result = false
	local tbPosList = {1, 5 ,6 ,14, 32 ,33 ,34}
	for _, v in pairs(aRepresentIDGroups) do
		for pos, id in pairs(v) do
			if table.contain_value(tbPosList , pos) then
				result = true
				break
			end
		end
	end
	return result
end

function CharacterExteriorData.IsPet(aRepresentIDGroups)
	local result = false
	local tbPosList = {41,42}
	for _, v in pairs(aRepresentIDGroups) do
		for pos, id in pairs(v) do
			if table.contain_value(tbPosList , pos) then
				result = true
				break
			end
		end
	end
	return result
end

function CharacterExteriorData.IsHorse(aRepresentIDGroups)
	local result = false
	local tbPosList = {26,27,28,29,30}
	for _, v in pairs(aRepresentIDGroups) do
		for pos, id in pairs(v) do
			if table.contain_value(tbPosList , pos) then
				result = true
				break
			end
		end
	end
	return result
end

function CharacterExteriorData.IsLHandPandent(aRepresentIDGroups)
	local result = false
	local tbPosList = {44}
	for _, v in pairs(aRepresentIDGroups) do
		local nLen = table.get_len(v)
		if nLen == 1 then
			for pos, id in pairs(v) do
				if table.contain_value(tbPosList , pos) then
					result = true
					break
				end
			end
		end
	end
	return result
end

function CharacterExteriorData.IsRHandPandent(aRepresentIDGroups)
	local result = false
	local tbPosList = {45}
	for _, v in pairs(aRepresentIDGroups) do
		local nLen = table.get_len(v)
		if nLen == 1 then
			for pos, id in pairs(v) do
				if table.contain_value(tbPosList , pos) then
					result = true
					break
				end
			end
		end
	end
	return result
end

function CharacterExteriorData.IsLRHandPandent(aRepresentIDGroups)
	local result = false
	for _, v in pairs(aRepresentIDGroups) do
		local nLen = table.get_len(v)
		if nLen == 2 then
			local hasLHand = false
			local hasRHand = false
			for pos, id in pairs(v) do
				if pos == 44 then
					hasLHand = true
				elseif pos == 45 then
					hasRHand = true
				end
			end
			if hasLHand and hasRHand then
				result = true
				break
			end
		end
	end
	return result
end

function CharacterExteriorData.IsGlassesPandent(aRepresentIDGroups)
	local result = false
	local tbPosList = {43}
	for _, v in pairs(aRepresentIDGroups) do
		for pos, id in pairs(v) do
			if table.contain_value(tbPosList , pos) then
				result = true
				break
			end
		end
	end
	return result
end

function CharacterExteriorData.IsBackPandent(aRepresentIDGroups)
	local result = false
	local tbPosList = {24}
	for _, v in pairs(aRepresentIDGroups) do
		for pos, id in pairs(v) do
			if table.contain_value(tbPosList , pos) then
				result = true
				break
			end
		end
	end
	return result
end


function CharacterExteriorData.GetAllSubsetHideExteriorSkills()
	if not g_pClientPlayer then
		return {}
	end
	local tSkills = {}
	local player = g_pClientPlayer
	local nCurrentSetID = player.GetCurrentSetID()
    local tExteriorSet 	= player.GetExteriorSet(nCurrentSetID)
    local dwExteriorID 	= tExteriorSet[EXTERIOR_INDEX_TYPE.CHEST]
	local tExteriorSkill = CharacterExteriorData.GetSubsetHideExteriorSkill(player, dwExteriorID, EQUIPMENT_REPRESENT.CHEST_SUBSET_HIDE_MASK)
	if tExteriorSkill then
		table.insert(tSkills, tExteriorSkill)
	end
	local tRepresentID = player.GetRepresentID()
	local dwHairID = tRepresentID[EQUIPMENT_REPRESENT.HAIR_STYLE]
	local tHairSkill = CharacterExteriorData.GetSubsetHideExteriorSkill(player, dwHairID, EQUIPMENT_REPRESENT.HAIR_SUBSET_HIDE_MASK)
	if tHairSkill then
		table.insert(tSkills, tHairSkill)
	end
	return tSkills
end

function CharacterExteriorData.GetSubsetHideExteriorSkill(player, dwExteriorID, nSubSetType)
	local m_tSubSetSkill = {
		[EQUIPMENT_REPRESENT.CHEST_SUBSET_HIDE_MASK] = {
			[0] = {dwSkillID = 40110, dwSkillLevel = 1, szDes = g_tStrings.STR_EXTERIOR_ACTION_CHEST_SHOW_DES, dwIconID = 23857}, --SubSet显示时候显示的
			[1] = {dwSkillID = 40110, dwSkillLevel = 1, szDes = g_tStrings.STR_EXTERIOR_ACTION_CHEST_HIDE_DES, dwIconID = 23856}, --SubSet隐藏时候显示的
		},
		[EQUIPMENT_REPRESENT.HAIR_SUBSET_HIDE_MASK] = {
			[0] = {dwSkillID = 40111, dwSkillLevel = 1, szDes = g_tStrings.STR_EXTERIOR_ACTION_HAIR_SHOW_DES, dwIconID = 23855},
			[1] = {dwSkillID = 40111, dwSkillLevel = 1, szDes = g_tStrings.STR_EXTERIOR_ACTION_HAIR_HIDE_DES, dwIconID = 23854},
		},
	}

	local nCanHideCount = 0
	local bHideFlag = false
	local szName
	if nSubSetType == EQUIPMENT_REPRESENT.CHEST_SUBSET_HIDE_MASK then
		local hExterior = GetExterior()
		nCanHideCount = hExterior.GetSubsetCanHideCount(dwExteriorID)
		if nCanHideCount > 0 then
			bHideFlag = player.GetExteriorSubsetHideFlag(dwExteriorID) ~= 0
			local tInfo = hExterior.GetExteriorInfo(dwExteriorID)
			if not tInfo then
				return
			end
			local tSet = Table_GetExteriorSet(tInfo.nSet)
			if not tSet then
				return
			end
			szName = tSet.szSetName
		end
	elseif nSubSetType == EQUIPMENT_REPRESENT.HAIR_SUBSET_HIDE_MASK then
		local nRoleType = Player_GetRoleType(player)
		nCanHideCount = GetHairShop().GetSubsetCanHideCount(nRoleType, dwExteriorID)
		if nCanHideCount > 0 then
			bHideFlag = player.GetHairSubsetHideFlag(dwExteriorID) ~= 0
			szName = CoinShopHair.GetHairText(dwExteriorID)
		end
	end
	if nCanHideCount == 1 then--策划要求只在等于一的时候显示外装动作
		local nHide = bHideFlag and 0 or 1
		local tInfo = m_tSubSetSkill[nSubSetType][nHide]
		return {
			dwSkillID = tInfo.dwSkillID,
			dwSkillLevel = tInfo.dwSkillLevel,
			bSubSet = true,
			szDes = tInfo.szDes,
			bHide = tInfo.bHide,
			dwIconID = tInfo.dwIconID,
			szName = szName,
		}
	end
	return nil
end