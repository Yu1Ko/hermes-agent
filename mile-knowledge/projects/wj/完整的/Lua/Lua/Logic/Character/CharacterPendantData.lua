CharacterPendantData = CharacterPendantData or {className = "CharacterPendantData"}

local self = CharacterPendantData

local BOX_PAGENUM = 28 --每页数量
-- 收藏数据块
local REMOTE_PREFER_PENDANT = 1113
local STAR_NUM = 40

local tPendantType = {
	[0] = {szType = "Star", szName = "收藏", szIcon = "UIAtlas2_Character_Accessory_Img_Liked.png", szIcon2 = "UIAtlas2_Character_Accessory_Img_Liked_T.png"},
	[1] = {szType = "Head", szName = "头饰", szIcon = "UIAtlas2_Character_Accessory_Img_Head.png", szIcon2 = "UIAtlas2_Character_Accessory_Img_Head_T2.png", nPendantType = KPENDENT_TYPE.HEAD,},
	[2] = {szType = "Face", szName = "脸部", szIcon = "UIAtlas2_Character_Accessory_Img_Face.png", szIcon2 = "UIAtlas2_Character_Accessory_Img_Face_T.png", nPendantType = KPENDENT_TYPE.FACE,},
	[3] = {szType = "Glasses", szName = "眼饰", szIcon = "UIAtlas2_Character_Accessory_Img_eye.png", szIcon2 = "UIAtlas2_Character_Accessory_Img_eye_T.png", nPendantType = KPENDENT_TYPE.GLASSES,},
	[4] = {szType = "BackCloak", szName = "披风", szIcon = "UIAtlas2_Character_Accessory_Img_Cloak.png", szIcon2 = "UIAtlas2_Character_Accessory_Img_Cloak_T.png", nPendantType = KPENDENT_TYPE.BACKCLOAK, bShowGabSize = true},
    [5] = {szType = "PendantPet", szName = "挂宠", szIcon = "UIAtlas2_Character_Accessory_Img_PetHanging.png", szIcon2 = "UIAtlas2_Character_Accessory_Img_PetHanging_T.png",},
	[6] = {szType = "Bag", szName = "佩囊", szIcon = "UIAtlas2_Character_Accessory_Img_BagHanging.png", szIcon2 = "UIAtlas2_Character_Accessory_Img_BagHanging_T.png", nPendantType = KPENDENT_TYPE.BAG,},
	[7] = {szType = "LShoulder", szName = "左肩饰", szIcon = "UIAtlas2_Character_Accessory_Img_ShoulderLeft.png", szIcon2 = "UIAtlas2_Character_Accessory_Img_ShoulderLeft_T.png", nPendantType = KPENDENT_TYPE.LSHOULDER, bShowGabSize = true},
	[8] = {szType = "RShoulder", szName = "右肩饰", szIcon = "UIAtlas2_Character_Accessory_Img_ShoulderRight.png", szIcon2 = "UIAtlas2_Character_Accessory_Img_ShoulderRight_T.png", nPendantType = KPENDENT_TYPE.RSHOULDER, bShowGabSize = true},
	[9] = {szType = "LHand", szName = "左手饰", szIcon = "UIAtlas2_Character_Accessory_Img_HandLeft.png", szIcon2 = "UIAtlas2_Character_Accessory_Img_HandLeft_T.png", nPendantType = KPENDENT_TYPE.LGLOVE,},
	[10] = {szType = "RHand", szName = "右手饰", szIcon = "UIAtlas2_Character_Accessory_Img_HandRight.png", szIcon2 = "UIAtlas2_Character_Accessory_Img_HandRight_T.png", nPendantType = KPENDENT_TYPE.RGLOVE,},
	[11] = {szType = "Back", szName = "背部", szIcon = "UIAtlas2_Character_Accessory_Img_BackHanging.png", szIcon2 = "UIAtlas2_Character_Accessory_Img_BackHanging_T.png", nPendantType = KPENDENT_TYPE.BACK, bShowGabSize = true},
	[12] = {szType = "Waist", szName = "腰部", szIcon = "UIAtlas2_Character_Accessory_Img_WaistHanging.png", szIcon2 = "UIAtlas2_Character_Accessory_Img_WaistHanging_T.png", nPendantType = KPENDENT_TYPE.WAIST, bShowGabSize = true},
}

local tbEquipSubToPendantType =
{
	[EQUIPMENT_SUB.HEAD_EXTEND] = 1,
	[EQUIPMENT_SUB.FACE_EXTEND] = 2,
	[EQUIPMENT_SUB.GLASSES_EXTEND] = 3,
	[EQUIPMENT_SUB.BACK_CLOAK_EXTEND] = 4,
	[EQUIPMENT_SUB.PENDENT_PET] = 5,
	[EQUIPMENT_SUB.BAG_EXTEND] = 6,
	[EQUIPMENT_SUB.L_SHOULDER_EXTEND] = 7,
	[EQUIPMENT_SUB.R_SHOULDER_EXTEND] = 8,
	[EQUIPMENT_SUB.L_GLOVE_EXTEND] = 9,
	[EQUIPMENT_SUB.R_GLOVE_EXTEND] = 10,
	[EQUIPMENT_SUB.BACK_EXTEND] = 11,
	[EQUIPMENT_SUB.WAIST_EXTEND] = 12,
}

local tbEquipSubToRepresentSub =
{
	[EQUIPMENT_SUB.HEAD_EXTEND] = EQUIPMENT_REPRESENT.HEAD_EXTEND,
	[EQUIPMENT_SUB.FACE_EXTEND] = EQUIPMENT_REPRESENT.FACE_EXTEND,
	[EQUIPMENT_SUB.GLASSES_EXTEND] = EQUIPMENT_REPRESENT.GLASSES_EXTEND,
	[EQUIPMENT_SUB.BACK_CLOAK_EXTEND] = EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND,
	[EQUIPMENT_SUB.PENDENT_PET] = EQUIPMENT_REPRESENT.PENDENT_PET,
	[EQUIPMENT_SUB.BAG_EXTEND] = EQUIPMENT_REPRESENT.BAG_EXTEND,
	[EQUIPMENT_SUB.L_SHOULDER_EXTEND] = EQUIPMENT_REPRESENT.L_SHOULDER_EXTEND,
	[EQUIPMENT_SUB.R_SHOULDER_EXTEND] = EQUIPMENT_REPRESENT.R_SHOULDER_EXTEND,
	[EQUIPMENT_SUB.L_GLOVE_EXTEND] = EQUIPMENT_REPRESENT.L_GLOVE_EXTEND,
	[EQUIPMENT_SUB.R_GLOVE_EXTEND] = EQUIPMENT_REPRESENT.R_GLOVE_EXTEND,
	[EQUIPMENT_SUB.BACK_EXTEND] = EQUIPMENT_REPRESENT.BACK_EXTEND,
	[EQUIPMENT_SUB.WAIST_EXTEND] = EQUIPMENT_REPRESENT.WAIST_EXTEND,
}

Event.Reg(self, EventType.ON_ADD_PENDANT, function(dwItemIndex)
	CharacterPendantData.OnAddPendant(dwItemIndex)
end)


function CharacterPendantData.Init(dwSelectType)
    local szType = CharacterPendantData.GetType(dwSelectType)
    CharacterPendantData.dwSelectType = dwSelectType
	CharacterPendantData.dwSelectDLCID = 0
	CharacterPendantData.tDLCName = Table_GetDLCName()
	CharacterPendantData.tList = {}
    for dwPart, v in pairs(tPendantType) do
		if dwPart ~= 0 then
			local tPendanList = Table_GetPendantListByType(v.szType) or {}
			CharacterPendantData.tList[dwPart] = {
				tPendantList = tPendanList,
			}
		else
			CharacterPendantData.tList[dwPart] = {
				dwPendantMaxNum = STAR_NUM,
			}
		end
    end
	CharacterPendantData.EmptyAllFilter()
	CharacterPendantData.UpdateStarData()
	CharacterPendantData.UpdatePendantData()
	CharacterPendantData.UpdateSelectPandant()
end

function CharacterPendantData.UnInit()
    --Event.UnRegAll(self)

    CharacterPendantData.EmptyAllFilter()
	CharacterPendantData.dwSelectType = nil
	CharacterPendantData.dwSelectDLCID  = 0
	CharacterPendantData.tList = {}
	CharacterPendantData.tSelectList = {}
	CharacterPendantData.dwSelectNum = nil
	CharacterPendantData.dwCurrentPage = nil
	CharacterPendantData.dwMaxPageCount = nil
	CharacterPendantData.dwEditPageNum = nil
end

function CharacterPendantData.GetType(dwSelectType)
    local tbInfo = tPendantType[dwSelectType]
    if not tbInfo then return end

	return tbInfo.szType
end

function CharacterPendantData.GetTypeInfo(dwSelectType)
    local tbInfo = tPendantType[dwSelectType]
    if not tbInfo then return end

	return tbInfo
end

function CharacterPendantData.GetdwPartID(szType)
	for dwPart, v in pairs(tPendantType) do
		if v.szType == szType then
			return dwPart
		end
    end
end

function CharacterPendantData.GetPendantTypeList()
	return tPendantType
end

function CharacterPendantData.Update()
	CharacterPendantData.UpdateStarData()
	CharacterPendantData.UpdatePendantData()
	CharacterPendantData.UpdateSelectPandant(true)
end

-- 判断挂件是否拥有、绝版、隐藏、使用、收藏，统计不同DLC版本的对应挂件数量
function CharacterPendantData.UpdatePendantData()
	local tStarList = {}
	local tStarInfo = CharacterPendantData.tStarInfo or {}
    for dwPart, tType in ipairs(tPendantType) do
		local tPendent = CharacterPendantData.tList[dwPart]
		local tPendentInfo, dwUsingPendantID, dwPendantListSize, tColorID, tUsingPendent = CharacterPendantData.GetPendentInfo(dwPart)
		if tPendentInfo then
			tPendent.dwPendantListSize = dwPendantListSize

			local tPendentHave = {}
			local tPendantList = tPendent.tPendantList
			for key, v in ipairs(tPendentInfo) do
				if tPendentHave[v.dwItemIndex] then
					table.insert(tPendentHave[v.dwItemIndex], v)
				else
					tPendentHave[v.dwItemIndex] = {v}
				end
			end

			local tDLCAll = {}
			local tDLCHave = {}
			local dwHaveTiming = 0
			local dwAllTiming = 0
			local dwSecretShow = 0
			local i = 1
			-- for i, aPendant in ipairs(tPendantList) do
			while i <= #tPendantList do
				local aPendant = tPendantList[i]
				local tItemInfo = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, aPendant.dwItemIndex)
				aPendant.szName = tItemInfo.szName
				aPendant.nQuality = tItemInfo.nQuality
				aPendant.dwSkillID = tItemInfo.dwSkillID or 0
				aPendant.dwPartID = dwPart

				if tPendentHave[aPendant.dwItemIndex] and #tPendentHave[aPendant.dwItemIndex] > 0 then
					local nHaveCount = tDLCHave[aPendant.dwDLCID] or 0
					nHaveCount = nHaveCount + #tPendentHave[aPendant.dwItemIndex]
					tDLCHave[aPendant.dwDLCID] = nHaveCount
					aPendant.bHave = true
					aPendant.tData = tPendentHave[aPendant.dwItemIndex]
				else
					aPendant.bHave = false
					aPendant.tData = nil
				end

				aPendant.bStar = false
				if tStarInfo[aPendant.dwItemIndex] then
					aPendant.bStar = true
					table.insert(tStarList, aPendant)
				end

				aPendant.bUsing = false
				if aPendant.dwItemIndex == dwUsingPendantID or (tUsingPendent and CheckIsInTable(tUsingPendent, aPendant.dwItemIndex)) then
					aPendant.bUsing = true
				end

				if aPendant.bLimited and (not aPendant.bHave) then --绝版未拥有
					-- table.insert(tLimited, aPendant)
					aPendant.bSecretShow = true
					dwSecretShow = dwSecretShow + 1
					--table.remove(tPendantList, i)
				end

				if aPendant.bHide then --隐藏挂件
					table.remove(tPendantList, i)
				else
					aPendant.bTiming = false
					if tItemInfo.nExistType ~= ITEM_EXIST_TYPE.PERMANENT then
						aPendant.bTiming = true
						dwAllTiming = dwAllTiming + 1
						if aPendant.bHave then
							dwHaveTiming = dwHaveTiming + 1
						end
					end
					local nAllCount = tDLCAll[aPendant.dwDLCID] or 0
					nAllCount = nAllCount + 1
					tDLCAll[aPendant.dwDLCID] = nAllCount
					i = i + 1
				end
			end
			tPendent.tColorID = tColorID
			tPendent.tDLCAll = tDLCAll									--不同DLC挂件数
			tPendent.tDLCHave = tDLCHave								--不同DLC拥有挂件数
			tPendent.dwPendantBagNum = #tPendentInfo					--拥有的挂件数量（挂件位处包含限时）
			tPendent.dwPendantNum = #tPendentInfo - dwHaveTiming		--拥有的挂件数量（不包含限时）
			tPendent.dwPendantMaxNum = #tPendantList - dwSecretShow -dwAllTiming		--所有的挂件数量（不包含限时, 绝版）
		end
    end
	CharacterPendantData.tList[0].tPendantList = tStarList
	CharacterPendantData.tList[0].dwPendantNum = #tStarList
	CharacterPendantData.UpdateDLCInfo()
end

--获取挂件信息的通用接口(方便后续对接逻辑)
function CharacterPendantData.GetPendentInfo(dwPart)
	local player = GetClientPlayer()
    if not player then
		return
    end
	local tPendentInfo = {}
	local dwUsingPendantID = 0
	local dwPendantListSize = 0
	local tColorID = {}

	local szType = tPendantType[dwPart].szType
	local tPendant = nil
	if szType == "PendantPet" then
		tPendentInfo = player.GetAllPendentPetData()
		dwPendantListSize = player.GetPendentPetBoxSize()
		dwUsingPendantID = player.GetEquippedPendentPet()
		tColorID = {0 , 0, 0}
	else
		local nPendantType = tPendantType[dwPart].nPendantType
		if nPendantType then
			tPendentInfo = player.GetAllPendent(nPendantType)
			dwPendantListSize = player.GetPendentBoxSize(nPendantType)
			dwUsingPendantID = player.GetSelectPendent(nPendantType)
			tColorID = player.GetSelectedPendentColor(nPendantType) or {0 , 0, 0}
			if nPendantType == KPENDENT_TYPE.HEAD then
				tPendant = {}
				for _, nPendantPos in ipairs(PENDENT_HEAD_TYPE) do
					local dwPendantID = player.GetSelectPendent(nPendantPos)
					if dwPendantID and dwPendantID ~= 0 then
						table.insert(tPendant, dwPendantID)
					end
				end
			end
		end
	end
	return tPendentInfo, dwUsingPendantID, dwPendantListSize, tColorID, tPendant
end


function CharacterPendantData.IsDIYPendant(dwTabType, nIndex)
	if nIndex == 0 then
		return false
	end
	local bCanSet = false
	local hPlayer = GetClientPlayer()
    if not hPlayer then
        return bCanSet
    end

	local hItemInfo = GetItemInfo(dwTabType, nIndex)
	local nType = tbEquipSubToRepresentSub[hItemInfo.nSub]

	bCanSet = IsCustomPendantRepresentID(nType, hItemInfo.nRepresentID, hPlayer.nRoleType)
	return bCanSet
end

function CharacterPendantData.IsPetInPendentPartInfo(dwPart)
	local szType = tPendantType[dwPart].szType
	return szType == "PendantPet"
end

function CharacterPendantData.IsLHandInPendentPartInfo(dwPart)
	local szType = tPendantType[dwPart].szType
	return szType == "LHand"
end

function CharacterPendantData.IsRHandInPendentPartInfo(dwPart)
	local szType = tPendantType[dwPart].szType
	return szType == "RHand"
end

function CharacterPendantData.IsGlassesInPendentPartInfo(dwPart)
	local szType = tPendantType[dwPart].szType
	return szType == "Glasses"
end

function CharacterPendantData.GetPendentList(dwPart)
    return CharacterPendantData.tList and CharacterPendantData.tList[dwPart]
end

function CharacterPendantData.GetSelectList()
    return CharacterPendantData.tSelectList, CharacterPendantData.dwSelectNum, CharacterPendantData.dwMaxPageCount, CharacterPendantData.dwCurrentPage
end

function CharacterPendantData.GetMaxShowCount()
    return BOX_PAGENUM
end

function CharacterPendantData.GetCurrentPage()
    return CharacterPendantData.dwCurrentPage
end

function CharacterPendantData.SetFilter(dwSelectFilterClass, dwSelectFilterHave, dwSelectFilterWay)
    CharacterPendantData.dwSelectFilterClass = dwSelectFilterClass
	CharacterPendantData.dwSelectFilterHave = dwSelectFilterHave
	CharacterPendantData.dwSelectFilterWay = dwSelectFilterWay
    CharacterPendantData.UpdateSelectPandant()
end

function CharacterPendantData.IsPreferPendant(dwItemIndex)
	local tStarInfo = CharacterPendantData.tStarInfo or {}
	return tStarInfo[dwItemIndex]
end

function CharacterPendantData.UpdateDLCInfo()
	local tDLCInfo = {}
	for i, v in ipairs(CharacterPendantData.tDLCName) do
		local tDLC = {}
		tDLC.dwHave = 0
		tDLC.dwAll = 0
		for dwPart, tType in ipairs(tPendantType) do
			local tPendent = CharacterPendantData.tList[dwPart]
			local dwPartHave = tPendent.tDLCHave[i] or 0
			local dwPartAll = tPendent.tDLCAll[i] or 0
			tDLC.dwHave = tDLC.dwHave + dwPartHave
			tDLC.dwAll = tDLC.dwAll + dwPartAll
		end
		tDLCInfo[i] = tDLC
	end

	local dwHavePendant = 0
	local dwAllPendant = 0
	for dwPart, tType in ipairs(tPendantType) do
		local tPendant = CharacterPendantData.tList[dwPart]
		dwHavePendant = dwHavePendant + tPendant.dwPendantNum
		dwAllPendant = dwAllPendant + tPendant.dwPendantMaxNum
	end
	tDLCInfo[0] = {dwHave = dwHavePendant, dwAll = dwAllPendant}
	CharacterPendantData.tDLCInfo = tDLCInfo
end

function CharacterPendantData.UpdateStarData()
	CharacterPendantData.bOpenStar = false
	local pPlayer = GetClientPlayer()
	if not pPlayer then
		return
	end

	local dwPlayerID = pPlayer.dwID
	if IsRemotePlayer(dwPlayerID) then
		return
	end

	if not pPlayer.HaveRemoteData(REMOTE_PREFER_PENDANT) then
		pPlayer.ApplyRemoteData(REMOTE_PREFER_PENDANT)
		return
	end

	local tStar = {}
	local dwStarCount =  pPlayer.GetRemoteSetSize(REMOTE_PREFER_PENDANT)
	for i = 1, dwStarCount do
		local dwItemIndex = pPlayer.GetRemoteDWordArray(REMOTE_PREFER_PENDANT, i - 1)
		if dwItemIndex and dwItemIndex ~= 0 then
			tStar[dwItemIndex] = true
		end
	end
	CharacterPendantData.tStarInfo = tStar
	CharacterPendantData.bOpenStar = true
end

function CharacterPendantData.UpdateSelectPandant(bNotRefresh)
	local tPendant = CharacterPendantData.tList[CharacterPendantData.dwSelectType]
	if not tPendant then
		return
	end

	local tSelectList = tPendant.tPendantList

	--Filter
	tSelectList = CharacterPendantData.FilterSelectPendant(tSelectList)
	--sort
	tSelectList = CharacterPendantData.SortSelectPendant(tSelectList)

	CharacterPendantData.tSelectList = tSelectList
	CharacterPendantData.dwSelectNum = #tSelectList
	CharacterPendantData.dwMaxPageCount = math.ceil(#tSelectList / BOX_PAGENUM)
	if bNotRefresh and CharacterPendantData.dwCurrentPage then
		return
	end
	for i, tPendant in pairs(tSelectList) do
        if tPendant.bUsing then
            CharacterPendantData.dwCurrentPage = math.ceil(i / BOX_PAGENUM)
            return
        end
    end
	CharacterPendantData.dwCurrentPage = 1
end

function CharacterPendantData.SortSelectPendant(tPendantList) --排序, 权重：新获得>拥有>收藏>品质(>表中编号, table.sort不稳定）
	local function fnCmp(a, b)
		local bIsNewA = RedpointHelper.Pendant_IsNew(CharacterPendantData.dwSelectType, a.dwItemIndex)
		local bIsNewB = RedpointHelper.Pendant_IsNew(CharacterPendantData.dwSelectType, b.dwItemIndex)
		if bIsNewA == bIsNewB then
			if a.bHave == b.bHave then
				if a.bStar == b.bStar then
					if a.nQuality == b.nQuality then
						return a.dwID > b.dwID
					else
						return a.nQuality > b.nQuality
					end
				elseif a.bStar then
					return true
				else
					return false
				end
			elseif a.bHave then
				return true
			else
				return false
			end
		elseif bIsNewA then
			return true
		else
			return false
		end
	end
	table.sort(tPendantList, fnCmp)
	return tPendantList
end

function CharacterPendantData.FilterSelectPendant(tPendantList)
	local dwDLCID = CharacterPendantData.dwSelectDLCID or 0
	local dwFilterClass = CharacterPendantData.dwSelectFilterClass or 0
	local dwFilterHave = CharacterPendantData.dwSelectFilterHave or 0
	local dwFilterWay = CharacterPendantData.dwSelectFilterWay or 0
	local szSearchText = CharacterPendantData.szSearchText

	local function fnCheckFilter(tItem)
		local bMatchSearch = false
		local bMatchDLC = false
		local bMatchClass = false
		local bMatchHave = false
		local bMatchWay = false

		if (dwDLCID == 0) or (tItem.dwDLCID == dwDLCID) then
			bMatchDLC = true
		end

		if dwFilterClass == 0 then
			bMatchClass = true
		elseif dwFilterClass == 1 then
			bMatchClass = (tItem.dwSkillID ~= 0)
		elseif dwFilterClass == 2 then
			--限时道具
			bMatchClass = tItem.bTiming
		elseif dwFilterClass == 3 then
			bMatchClass = tItem.bLimited
		end

		if dwFilterHave == 0 then
			bMatchHave = true
		elseif dwFilterHave == 1 then
			bMatchHave = tItem.bHave
		elseif dwFilterHave == 2 then
			bMatchHave = not tItem.bHave
		end

		if dwFilterWay == 0 then
			bMatchWay = true
		else
			bMatchWay = (tItem.dwSource == dwFilterWay)
		end

		if not szSearchText or szSearchText == "" then
			bMatchSearch = true
		elseif string.find(UIHelper.GBKToUTF8(tItem.szName), szSearchText, 1, true) then
			bMatchSearch = true
		end
		return bMatchSearch and bMatchDLC and bMatchClass and bMatchHave and bMatchWay
	end

	local bLimted = (CharacterPendantData.dwSelectFilterClass == 3 and CharacterPendantData.dwSelectFilterHave == 2)

	local tResList = {}
	for _, tItem in ipairs(tPendantList) do
		if CharacterPendantData.dwSelectType == 0 then
			if fnCheckFilter(tItem) then
				table.insert(tResList, tItem)
			end
		else
			if fnCheckFilter(tItem) then
				if not tItem.bSecretShow and not bLimted then
					table.insert(tResList, tItem)
				elseif tItem.bSecretShow and bLimted then
					table.insert(tResList, tItem)
				end
			end
		end
	end
	return tResList
end

function CharacterPendantData.GetUsingPendantID(dwPart)
	local tPendentInfo, dwUsingPendantID, dwPendantListSize, tColorID, tUsingPendent = CharacterPendantData.GetPendentInfo(dwPart)
	return dwUsingPendantID, tUsingPendent
end

--获取一个头饰非空闲的挂件
function CharacterPendantData.GetSelectPendent(player, nPendentType)
	if nPendentType == KPENDENT_TYPE.HEAD then
		for _, nPendantPos in ipairs(PENDENT_HEAD_TYPE) do
			local dwHeadIndex = player.GetSelectPendent(nPendantPos)
			if dwHeadIndex and dwHeadIndex ~= 0 then
				return dwHeadIndex, nPendantPos
			end
		end
	end
	return _, nPendentType
end

function CharacterPendantData.ClearAllHeadPendant()
	local player = PlayerData.GetClientPlayer()
	if not player then
		return
	end

	for _, nPendantPos in ipairs(PENDENT_HEAD_TYPE) do
		local dwHeadIndex = player.GetSelectPendent(nPendantPos)
		if dwHeadIndex and dwHeadIndex ~= 0 then
			player.SelectPendent(EQUIPMENT_SUB.HEAD_EXTEND, 0, nPendantPos)
		end
	end

end

function CharacterPendantData.EquipPendant(tbPendantInfo, dwPart, bEquip, nColorIndex)
    local player = PlayerData.GetClientPlayer()
	if not player then
		return
	end

	if player.bFightState then
		OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.CANNOT_CHANGE_PENDENT_IN_FIGHT)
		return
	end
	if player.nMoveState == MOVE_STATE.ON_DEATH then
		OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_ERROR_CANNOT_EQUIP_PENDANT_WHEN_DIE)
		return
	end

    local dwIndex = 0
    if bEquip then
        dwIndex = tbPendantInfo.dwItemIndex
    end

	nColorIndex = nColorIndex or 1
	local tbData
	if tbPendantInfo and tbPendantInfo.tData and tbPendantInfo.tData[nColorIndex] then
		tbData = tbPendantInfo.tData[nColorIndex]
	end

    local tbInfo = CharacterPendantData.GetTypeInfo(dwPart)
	local nType = tbInfo.nPendantType
	local nPos
	if nType then
		local nEquipSub = GetEquipSubByPendantType(nType)
		local bColor = GetCloakChangeColorInfo(ITEM_TABLE_TYPE.CUST_TRINKET, dwIndex)
		if bColor and tbData and tbData.nColorID1 and (tbData.nColorID1 ~= 0 or tbData.nColorID2 ~= 0 or tbData.nColorID3 ~= 0) then
			player.SelectColorPendent(nEquipSub, dwIndex or 0, tbData.nColorID1, tbData.nColorID2, tbData.nColorID3)
		else
			if nType == KPENDENT_TYPE.HEAD then
				dwIndex = dwIndex or 0
				if not tbPendantInfo then --脱下当前
					CharacterPendantData.ClearAllHeadPendant()
					return
				end
				if dwIndex == 0 then
					nPos = player.GetHeadPendentSelectedPos(tbPendantInfo.dwItemIndex)
					player.SelectPendent(nEquipSub, dwIndex or 0, nPos)
				else
					nPos = player.GetHeadPendentSelectedPos(0)
					if nPos then
						player.SelectPendent(nEquipSub, dwIndex or 0, nPos)
					else
          				OutputMessage("MSG_SYS", g_tStrings.STR_SELECT_PENDANT_HEAD_ERROR)
          				OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_SELECT_PENDANT_HEAD_ERROR)
					end
				end
			else
				player.SelectPendent(nEquipSub, dwIndex or 0)
			end
		end
		if dwIndex and dwIndex > 0 then
			local hItemInfo = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, dwIndex)
			if hItemInfo then
				local nRepresentSub
				if nPos then
					nRepresentSub = CoinShop_PendantTypeToRepresentSub(nPos)
				else
					nRepresentSub = Exterior_SubToRepresentSub(nEquipSub)
				end
				local nRepresentID = hItemInfo.nRepresentID
				CoinShopData.CustomPendantSetLocalDataToPlayer(nRepresentSub, nRepresentID)
			end
		end
	else
		player.EquipPendentPet(dwIndex or 0)
	end
end

function CharacterPendantData.GetRedPointPendantType(nSub)
	return tbEquipSubToPendantType[nSub]
end

function CharacterPendantData.OnAddPendant(dwItemIndex)
	local tItemInfo = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, dwItemIndex)
	if not tItemInfo then
		return
	end

	if tItemInfo.nGenre ~= ITEM_GENRE.EQUIPMENT then
		return
	end

	local nPendantType = tbEquipSubToPendantType[tItemInfo.nSub]
	if not nPendantType then
		return
	end

	RedpointHelper.Pendant_SetNew(nPendantType, dwItemIndex, true)
end

---------------------挂饰秘鉴通用界面配置函数-----------------------

function CharacterPendantData.SetCurrentPage(dwCurrentPage)
    CharacterPendantData.dwCurrentPage = dwCurrentPage
end

function CharacterPendantData.SetSelectType(dwPart)
    CharacterPendantData.dwSelectType = dwPart
    CharacterPendantData.EmptyAllFilter()
end

function CharacterPendantData.SetSearchText(szSearchText)
    CharacterPendantData.szSearchText = szSearchText
end

function CharacterPendantData.GetSearchText()
    return CharacterPendantData.szSearchText
end

function CharacterPendantData.GetCollectionProgressTips()
    local nTotalNum = #self.tSelectList
	local nHaveNum = 0
	for k, v in ipairs(self.tSelectList) do
		if v.bHave then
			nHaveNum = nHaveNum + 1
		end
	end
	return nTotalNum, nHaveNum
end

function CharacterPendantData.GetCollectedNum()
    local nTotalNum = STAR_NUM
	local nHaveNum = CharacterPendantData.tList[0].dwPendantNum

	return nTotalNum, nHaveNum
end

function CharacterPendantData.GetCurPageInfo()
    local nTotalPage = self.dwMaxPageCount
	return nTotalPage, self.dwCurrentPage
end

function CharacterPendantData.EmptyAllFilter()
	CharacterPendantData.szSearchText = ""
	CharacterPendantData.dwSelectFilterClass = 0
	CharacterPendantData.dwSelectFilterHave = 0
	CharacterPendantData.dwSelectFilterWay = 0
end

function CharacterPendantData.UpdateFilterList()
    CharacterPendantData.UpdateSelectPandant()
end