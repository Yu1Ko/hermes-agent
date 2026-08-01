EquipData = EquipData or {className = "EquipData"}
local self =EquipData

local Def = {
    EquipInventory = {
        EQUIPMENT_INVENTORY.HELM,
        EQUIPMENT_INVENTORY.CHEST,
        EQUIPMENT_INVENTORY.BANGLE,
        EQUIPMENT_INVENTORY.WAIST,
        EQUIPMENT_INVENTORY.PANTS,
        EQUIPMENT_INVENTORY.BOOTS,
        EQUIPMENT_INVENTORY.MELEE_WEAPON,
        EQUIPMENT_INVENTORY.RANGE_WEAPON,
    }
}

function EquipData.Init()
	Event.Reg(EquipData, "FE_BREAK_EQUIP", function(nResult)
		if nResult == BREAK_EQUIP_RESULT_CODE.SUCCESS then
			OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.BREAK_EQUIP_RESULT[nResult])
		elseif g_tStrings.BREAK_EQUIP_RESULT[nResult] then
			OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.BREAK_EQUIP_RESULT[nResult])
		end
	end)

	Event.Reg(self, EventType.OnAccountLogout, function()
		Timer.DelTimer(self, self.nTimerID)
	end)

	Event.Reg(self, "LOADING_END", function()
        EquipData.UpdateEquipDurability()
    end)

	Event.Reg(self, "EQUIP_CHANGE", function(result)
        if result == ITEM_RESULT_CODE.SUCCESS then
            if self.tbEquipCache and table.get_len(self.tbEquipCache) > 0 then
				EquipData.RestoreEquip()
            end
        end
    end)
end

function EquipData.UnInit()
	Timer.DelTimer(self, self.nTimerID)
end

function EquipData.GetEquipRecipeDesc(Value1, Value2)
	local szText = ""
	local bIsMobile = false
	local tRecipeSkillAtrri = g_tTable.EquipmentRecipe:Search(Value1, Value2)
	if tRecipeSkillAtrri then
		szText = tRecipeSkillAtrri.szDesc
		bIsMobile = tRecipeSkillAtrri.bIsMobile
	end
	return szText, bIsMobile
end

function EquipData.FormatAttributeValue(v)
	if v.nID == ATTRIBUTE_TYPE.DAMAGE_TO_LIFE_FOR_SELF or v.nID == ATTRIBUTE_TYPE.DAMAGE_TO_MANA_FOR_SELF then
		if v.nValue1 then
			v.nValue1 = KeepTwoByteFloat(v.nValue1 * 100 / 1024)
			v.nValue2 = KeepTwoByteFloat(v.nValue2 * 100 / 1024)
		end
		if v.Param0 then
			v.Param0 = KeepTwoByteFloat(v.Param0 * 100 / 1024)
			v.Param1 = KeepTwoByteFloat(v.Param1 * 100 / 1024)
			v.Param2 = KeepTwoByteFloat(v.Param2 * 100 / 1024)
			v.Param3 = KeepTwoByteFloat(v.Param3 * 100 / 1024)
		end

	end
end

function EquipData.IsMagicAttriStrength(item, bItem, id, AttribOrg, Attrib)-- AttribOrg, Attrib can ignore
	AttribOrg 	= AttribOrg or {}
	Attrib 		= Attrib or {}
	if item.nGenre ~= ITEM_GENRE.NPC_EQUIPMENT then
        local player = GetClientPlayer()
        local tbEquipStrengthInfo = EquipData.GetEquipStrengthInfo(player, item, bItem)
		AttribOrg 	= AttribOrg or item.GetMagicAttribByStrengthLevel(0)
		Attrib 		= Attrib or item.GetMagicAttribByStrengthLevel(tbEquipStrengthInfo.nTrueLevel)
	end

	local nTop = #AttribOrg
	local index, value1, value2 = 0, 0, 0
	for i = 1, nTop, 1 do
		if id == AttribOrg[i].nID then
            local bStrength = AttribOrg[i].nValue1 ~= Attrib[i].nValue1 or AttribOrg[i].nValue2 ~= Attrib[i].nValue2
			return bStrength, AttribOrg[i].nValue1, AttribOrg[i].nValue2, Attrib[i].nValue1, Attrib[i].nValue2
		end
	end
end

function EquipData.GetMagicAttriText(item, attri, bItem, AttribOrgs, Attribs)
	local tbInfo = {
		szText = "",
		bIsNormal = false,
		bIsEquipmentRecipe = false,
		bIsSkillEventHandler = false,
		bIsMobile = false,
		bShowSign = false,
	}
	local id = attri.nID
	local aValue
	local bShowSign = false
	if id == ATTRIBUTE_TYPE.SET_EQUIPMENT_RECIPE then
		tbInfo.bIsEquipmentRecipe = true
		if attri.Param0 then
			local bIsMobile = false
			tbInfo.szText, bIsMobile = EquipData.GetEquipRecipeDesc( attri.Param0, attri.Param2 )
			tbInfo.szText = string.pure_text(tbInfo.szText)
			if bIsMobile then
				tbInfo.bIsMobile = true
				tbInfo.bShowSign = true
			end
			return tbInfo
		else
			local bIsMobile = false
			tbInfo.szText, bIsMobile = EquipData.GetEquipRecipeDesc( attri.nValue1, attri.nValue2 )
			tbInfo.szText = string.pure_text(tbInfo.szText)
			if bIsMobile then
				tbInfo.bIsMobile = true
				tbInfo.bShowSign = true
			end
			return tbInfo
		end
	end

	if id == ATTRIBUTE_TYPE.SKILL_EVENT_HANDLER then
		tbInfo.bIsSkillEventHandler = true
		if attri.Param0 then
			aValue = { attri.Param0, attri.Param1, attri.Param2, attri.Param3 }
		else
			aValue = { attri.nValue1, attri.nValue2 }
		end

		local skillEvent = g_tTable.SkillEvent:Search(aValue[1])
		if skillEvent then
			tbInfo.szText = FormatString(skillEvent.szDesc, unpack(aValue))
			tbInfo.szText = string.pure_text(tbInfo.szText)
			return tbInfo
		else
			tbInfo.szText = "<text>text=\"unknown skill event id:"..aValue[1].."\"</text>"
			tbInfo.szText = string.pure_text(tbInfo.szText)
			return tbInfo
		end
	end

    EquipData.FormatAttributeValue(attri)

    local bStrengthAttrib, org_value1, org_value2, new_value1, new_value2 = EquipData.IsMagicAttriStrength(item, bItem, id, AttribOrgs, Attribs)

    if attri.Param0 then
        aValue = { tonumber(attri.Param0), tonumber(attri.Param1), tonumber(attri.Param2), tonumber(attri.Param3) }
    elseif bItem and bStrengthAttrib then
        aValue = { org_value1, org_value2, new_value1, new_value2 }
    else
        aValue = { tonumber(attri.nValue1), tonumber(attri.nValue2), MAGIC_ATTRI_DEF, MAGIC_ATTRI_DEF }
    end

    local szText = FormatString(Table_GetMagicAttributeInfo(id, bItem), unpack(aValue))
	szText = string.pure_text(szText)

	if bStrengthAttrib then
		local szValue = FormatString(Table_GetMagicAttriStrengthValue(id), org_value1, org_value2, new_value1, new_value2, 0)
		szText = string.format("%s<color=#3ADB95>(+%s)</c>", szText, szValue)
	end


	local tbConfig = GetAttribute(id)
	tbInfo.szText = szText
	if tbConfig and tbConfig.bIsNormal then
		tbInfo.bIsNormal = true
	end

	return tbInfo
end

function EquipData.GetMagicAttriTip(item, bItem, nEquipInventory)
	local tbMagicAttriInfo = {}
	if not bItem or not item.GetChangeInfo then
		return tbMagicAttriInfo
	end

	local player = GetClientPlayer()
	local nSrcAttri, nDstAttri, nSrcPer, nDstPer = item.GetChangeInfo()
    local tbEquipStrengthInfo = EquipData.GetEquipStrengthInfo(player, item, bItem, nEquipInventory)
    local nStrengthLevel = tbEquipStrengthInfo.nTrueLevel
	local magicAttrib = item.GetMagicAttrib()

	local magicStrengthAttribOrg = {}
	local magicStrengthAttrib = {}
	if item.nGenre ~= ITEM_GENRE.NPC_EQUIPMENT then
		magicStrengthAttribOrg= item.GetMagicAttribByStrengthLevel(0)
		magicStrengthAttrib = item.GetMagicAttribByStrengthLevel(nStrengthLevel)
	end

	for k, v in pairs(magicAttrib) do
		local tbInfo = EquipData.GetMagicAttriText(item, v, true, magicStrengthAttribOrg, magicStrengthAttrib)
		table.insert(tbMagicAttriInfo, tbInfo)
	end

	local fChangePer = item.GetChangeCof()
	local changeAttrib = item.GetChangeAttrib()
	local changeStrengthAttribOrg = {}
	local changeStrengthAttrib = {}
	if item.nGenre ~= ITEM_GENRE.NPC_EQUIPMENT then
		changeStrengthAttribOrg = item.GetChangeAttribByStrengthLevel(0)
		changeStrengthAttrib = item.GetChangeAttribByStrengthLevel(nStrengthLevel)
	end
	for k, v in pairs(changeAttrib) do
		local tbInfo = EquipData.GetMagicAttriText(item, v, true, changeStrengthAttribOrg, changeStrengthAttrib)
		if nDstAttri == v.nID then
			local _, _, level, r, g, b = EquipData.GetEquipMagicChangeLevel( fChangePer )
			tbInfo.szText = tbInfo.szText .. UIHelper.UTF8ToGBK(string.format("<color=#%X%X%X>【%s品转化】</c>", r, g, b, g_tStrings.STR_NUMBER[level]))
		end
		table.insert(tbMagicAttriInfo, tbInfo)
	end
	return tbMagicAttriInfo
end

function EquipData.GetItemInfoMagicAttriTip(itemInfo, tbPowerUpInfo)
	local tbMagicAttriInfo = {}
	local tbEquipStrengthInfo = EquipData.GetEquipStrengthInfo(nil, itemInfo, false)
    local nStrengthLevel = tbEquipStrengthInfo.nTrueLevel

	if tbPowerUpInfo and tbPowerUpInfo.nStrengthLevel then
		nStrengthLevel = tbPowerUpInfo.nStrengthLevel
	end

	local magicAttrib = GetItemMagicAttrib(itemInfo.GetMagicAttribIndexList())
    local magicStrengthAttribOrg = itemInfo.GetMagicAttribByStrengthLevel(0)
	local magicStrengthAttrib = itemInfo.GetMagicAttribByStrengthLevel(nStrengthLevel)
	for k, v in pairs(magicAttrib) do
		local tbInfo =  EquipData.GetMagicAttriText(itemInfo, v, false, magicStrengthAttribOrg, magicStrengthAttrib)
		table.insert(tbMagicAttriInfo, tbInfo)
	end
	return tbMagicAttriInfo
end


----五行石 孔属性------------------------------
function EquipData.GetEquipSlotTip(item, bItem, tSource)
	local szTip  = ""
	local szText = ""
	local szTmpText, currentAttr
	local org_text, bActived
	local nSlots = item.GetSlotCount()
	local tbEquipSlotInfo = {}

	for i = 1, nSlots, 1 do
		local tbInfo = {}
		tbInfo.diamon, tbInfo.nType, tbInfo.nTabIndex = EquipData.GetEquipSlotDiamon(i - 1, item, bItem, tSource)
		tbInfo.szAttr, tbInfo.bActived = EquipData.GetSlotAttr(item, i - 1, bItem, nil, tSource)
		table.insert(tbEquipSlotInfo, tbInfo)
	end
	return tbEquipSlotInfo
end

--获取武器的五彩石附魔ID
local function GetWeaponFEAEnchantID(dwPlayerID, item, bItem)
	local nEnchantID  = 0
	local dwTabType   = 0
	local dwItemIndex = 0

	if bItem then
		dwTabType   = item.dwTabType
		dwItemIndex = item.dwIndex or item.dwID
	else
		dwTabType   = ITEM_TABLE_TYPE.CUST_WEAPON
		dwItemIndex = item.dwID
	end

	if not dwTabType or not dwItemIndex then
		return nEnchantID
	end

	--地图掩码不显示五彩石
	if item.dwMapBanEquipItemMask == 1 then
		return nEnchantID
	end

	--若装备栏中有五彩石
	local hPlayer    = GetPlayer(dwPlayerID)
	local nSlotIndex = -1
	if hPlayer then
		local tBindInfo = hPlayer.GetColorDiamondSlotBindWeaponInfo()
		for k, v in pairs(tBindInfo) do
			if v[1] == dwTabType and v[2] == dwItemIndex then
				nSlotIndex = v[3]
				break
			end
		end
	end

	if nSlotIndex > 0 then --装备栏中有绑定关系且不为0,直接用绑定的五彩石
		local dwEnchantID, nCurrentLevel = hPlayer.GetColorDiamondSlotInfo(nSlotIndex)
		if dwEnchantID > 0 and nCurrentLevel >= item.nLevel then
			nEnchantID = dwEnchantID
		end
	else
		if bItem then --武器自身有五彩石
			nEnchantID = item.GetMountFEAEnchantID()
		end
		if not nEnchantID or nEnchantID <= 0 and nSlotIndex == -1 and hPlayer then --武器自身没用五彩石,且绑定方案没有,去装备栏里面从左往右找第一个符合融嵌条件的五彩石（品级）
			for i = 1, 4 do
				local dwEnchantID, nCurrentLevel = hPlayer.GetColorDiamondSlotInfo(i)
				if dwEnchantID > 0 and nCurrentLevel >= item.nLevel then
					nEnchantID = dwEnchantID
					break
				end
			end
		end
	end

	return nEnchantID
end

----五彩石属性--------------------------------
function EquipData.GetColorDiamondTip(dwPlayerID, item, bItem, nBoxIndex, nBoxItemIndex, tbPowerUpInfo)
	local function GetIntroduceTip()
		return {{bActived = false, szAttr = g_tStrings.STR_ITEM_H_COLOR_DIAMOND1}}
	end

	if not bItem and not tbPowerUpInfo then
		return GetIntroduceTip()
	end

	local bForceActive = false
	local nEnchantID = GetWeaponFEAEnchantID(dwPlayerID, item, bItem)
	if tbPowerUpInfo and tbPowerUpInfo.tbColorStone and tbPowerUpInfo.tbColorStone.nID then
		nEnchantID = tbPowerUpInfo.tbColorStone.nID
		bForceActive = true
	end

	if nEnchantID == 0 then
		return GetIntroduceTip()
	end

	local dwTabType, dwIndex = GetColorDiamondInfoFromEnchantID(nEnchantID)
	local itemInfo = GetItemInfo(dwTabType, dwIndex)

	local tbInfo = {}
	tbInfo.diamon, tbInfo.nType, tbInfo.nTabIndex = itemInfo, dwTabType, dwIndex
	tbInfo.bActived = true
	tbInfo.szAttr = ""

	local aAttr = GetFEAInfoByEnchantID(nEnchantID)
	local skillEvent_tab = g_tTable.SkillEvent
	for k, v in pairs(aAttr) do
		EquipData.FormatAttributeValue(v)
		local szPText = ""
		if v.nID == ATTRIBUTE_TYPE.SKILL_EVENT_HANDLER then
			local skillEvent = skillEvent_tab:Search(v.nValue1)
			if skillEvent then
				szPText = FormatString(skillEvent.szDesc, v.nValue1, v.nValue2)
			else
				szPText = "unknown skill event id:"..v.nValue1
			end
		else
			szPText = FormatString(Table_GetMagicAttributeInfo(v.nID, true), v.nValue1, v.nValue2, MAGIC_ATTRI_DEF, MAGIC_ATTRI_DEF)
		end

		szPText = UIHelper.GBKToUTF8(szPText)
		szPText = string.pure_text(szPText)

		local bActive = GetFEAActiveFlag(dwPlayerID, nBoxIndex, nBoxItemIndex, tonumber(k) - 1) or bForceActive
		if bActive then
			szPText = string.format("<color=#1EDF4B>%s</c>", szPText)
		else
			szPText = string.format("<color=#AFC1D4>%s</c>", szPText)
		end

		if tbInfo.szAttr ~= "" then
			tbInfo.szAttr = tbInfo.szAttr .. "\n"
		end
		tbInfo.szAttr = tbInfo.szAttr .. szPText
	end

	return {tbInfo}
end

function EquipData.IsItemCharacterEquip(nType)
	return nType == ITEM_GENRE.EQUIPMENT or nType == ITEM_GENRE.NPC_EQUIPMENT
end

function EquipData.GetEquipRecommendTip(itemInfo)
	if not EquipData.IsItemCharacterEquip(itemInfo.nGenre) then
		return ""
	end

	local szTip = ""
	local hPlayer = GetClientPlayer()
    if not hPlayer then
        return szTip
    end
    local dwKungfuID = hPlayer.GetKungfuMountID()

	---门派推荐--------------------
	if itemInfo.nRecommendID and g_tTable.EquipRecommend then
		local t = g_tTable.EquipRecommend:Search(itemInfo.nRecommendID)
		if t and t.szDesc and t.szDesc ~= "" then
			local szDesc = UIHelper.GBKToUTF8(t.szDesc)
			local tbIDs = string.split(t.kungfu_ids, "|")
			szTip = szTip..FormatString(g_tStrings.RECOMMEND_SCHOOL, szDesc)

			for _, szID in ipairs(tbIDs) do
				local nID = tonumber(szID)
				if nID == 0 or nID == dwKungfuID then
					szTip = string.format("<color=#95FF95>%s</c>", szTip)
					break
				end
			end
		end
	end
	return szTip
end

function EquipData.GetExteriorTip(itemInfo)
	----外观--------------------
	local szTip = ""
	if not itemInfo.nCanExteriorSchool then
		return szTip
	end

	if itemInfo.IsMentorBind() or itemInfo.IsTongBind() then
		return szTip
	end

	local szExteriorName = ""
	local eGoodsType = nil
	local dwGoodsID = nil
	if itemInfo.nSub == EQUIPMENT_SUB.MELEE_WEAPON then
		local dwWeaponID = CoinShop_GetWeaponIDByItemInfo(itemInfo)
		eGoodsType = COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR
		dwGoodsID = dwWeaponID
	else
		local dwExteriorID = CoinShop_GetExteriorIDByItemInfo(itemInfo)
		eGoodsType = COIN_SHOP_GOODS_TYPE.EXTERIOR
		dwGoodsID = dwExteriorID
	end

	if eGoodsType and dwGoodsID and dwGoodsID > 0 then
		szExteriorName = CoinShop_GetGoodsName(eGoodsType, dwGoodsID)
	end

	if szExteriorName and szExteriorName ~= "" then
		local nHaveType = GetCoinShopClient().CheckAlreadyHave(eGoodsType, dwGoodsID)
		local bHave = nHaveType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE
		local bCollect = CoinShop_GetCollectInfo(eGoodsType, dwGoodsID)
		if szTip ~= "" then
			szTip = szTip .. "\n"
		end
		local szText = FormatString(g_tStrings.ITEM_TIP_EXTERIOR_NAME, UIHelper.GBKToUTF8(szExteriorName))
		szTip = szTip .. szText
		local nStatus = GET_STATUS.NOT_COLLECTED
		if bCollect or bHave then
			nStatus = GET_STATUS.COLLECTED
		end
		local szCollect = g_tStrings.tCoinshopGet[nStatus]

		szTip = szTip .. FormatString(g_tStrings.STR_ITEM_TEMP_ECHANT_LEFT_TIME, szCollect)
	end
	local szDesc = Table_GetCanExteriorDesc(itemInfo.nCanExteriorSchool)
	if szDesc ~= "" then
		if szTip ~= "" then
			szTip = szTip .. "\n"
		end
		szTip = szTip..FormatString(g_tStrings.RECOMMEND_EXTEROPR_SCHOOL, UIHelper.GBKToUTF8(szDesc))
	end
	return szTip
end

----门派推荐，外观--------------------
function EquipData.GetEquipRecommendAndExteriorTip(itemInfo)
	if not EquipData.IsItemCharacterEquip(itemInfo.nGenre) then
		return ""
	end

	local szTip = ""
	local hPlayer = GetClientPlayer()
    if not hPlayer then
        return szTip
    end
    local dwKungfuID = hPlayer.GetKungfuMountID()

	---门派推荐--------------------
	if itemInfo.nRecommendID and g_tTable.EquipRecommend then
		local t = g_tTable.EquipRecommend:Search(itemInfo.nRecommendID)
		if t and t.szDesc and t.szDesc ~= "" then
			local szDesc = UIHelper.GBKToUTF8(t.szDesc)
			local tbIDs = string.split(t.kungfu_ids, "|")
			szTip = szTip..FormatString(g_tStrings.RECOMMEND_SCHOOL, szDesc)

			for _, szID in ipairs(tbIDs) do
				local nID = tonumber(szID)
				if nID == 0 or nID == dwKungfuID then
					szTip = string.format("<color=#95FF95>%s</c>", szTip)
					break
				end
			end
		end
	end

	----外观--------------------
	if itemInfo.nCanExteriorSchool then
		local szExteriorName = ""
		local eGoodsType = nil
		local dwGoodsID = nil
		if itemInfo.nSub == EQUIPMENT_SUB.MELEE_WEAPON then
			local dwWeaponID = CoinShop_GetWeaponIDByItemInfo(itemInfo)
			eGoodsType = COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR
			dwGoodsID = dwWeaponID
		else
			local dwExteriorID = CoinShop_GetExteriorIDByItemInfo(itemInfo)
			eGoodsType = COIN_SHOP_GOODS_TYPE.EXTERIOR
			dwGoodsID = dwExteriorID
		end

		if eGoodsType and dwGoodsID and dwGoodsID > 0 then
			szExteriorName = CoinShop_GetGoodsName(eGoodsType, dwGoodsID)
		end

		if szExteriorName and szExteriorName ~= "" then
			local nHaveType = GetCoinShopClient().CheckAlreadyHave(eGoodsType, dwGoodsID)
			local bHave = nHaveType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE
			local bCollect = CoinShop_GetCollectInfo(eGoodsType, dwGoodsID)
			if szTip ~= "" then
				szTip = szTip .. "\n"
			end
			local szText = FormatString(g_tStrings.ITEM_TIP_EXTERIOR_NAME, UIHelper.GBKToUTF8(szExteriorName))
			szTip = szTip .. szText
			local nStatus = GET_STATUS.NOT_COLLECTED
			if bCollect or bHave then
				nStatus = GET_STATUS.COLLECTED
			end
			local szCollect = g_tStrings.tCoinshopGet[nStatus]

			szTip = szTip .. FormatString(g_tStrings.STR_ITEM_TEMP_ECHANT_LEFT_TIME, szCollect)
		end
		local szDesc = Table_GetCanExteriorDesc(itemInfo.nCanExteriorSchool)
		if szDesc ~= "" then
			if szTip ~= "" then
				szTip = szTip .. "\n"
			end
			szTip = szTip..FormatString(g_tStrings.RECOMMEND_EXTEROPR_SCHOOL, UIHelper.GBKToUTF8(szDesc))
		end
	end
	return szTip
end

local function GetSourcePlayer(tSource)
    local pPlayer
    if tSource then
        local bCmp       = tSource.bCmp
        local bLink      = tSource.bLink
        local dwPlayerID = tSource.dwPlayerID
        if bLink then
            pPlayer = nil
        else
            if bCmp then
                pPlayer = GetClientPlayer()
            elseif dwPlayerID then
                pPlayer = GetPlayer(dwPlayerID)
            else
                pPlayer = GetClientPlayer()
            end
        end
    else
        pPlayer = GetClientPlayer()
    end
    return pPlayer
end

function EquipData.GetSlotBoxInfo(nEquip, nSlotIndex, pPlayer)
    if not pPlayer then
        pPlayer = GetClientPlayer()
    end
    if nEquip == EQUIPMENT_INVENTORY.BIG_SWORD then
        --藏剑重剑对应轻剑装备栏
        nEquip = EQUIPMENT_INVENTORY.MELEE_WEAPON
    end
    local dwEnchantID, nBoxQuality = pPlayer.GetEquipBoxMountDiamondEnchantID(nEquip, nSlotIndex)
    local nMaxQuality, bCanMount = GetEquipBoxDiamondSlotInfo(nEquip, nSlotIndex)
    return {
        dwEnchantID = dwEnchantID,
        nQuality = nBoxQuality,
        nMaxQuality = nMaxQuality,
        bCanMount = bCanMount,
    }
end

local m_tEquipSubToInventory = {
    [EQUIPMENT_SUB.HELM]         = EQUIPMENT_INVENTORY.HELM,
    [EQUIPMENT_SUB.CHEST]        = EQUIPMENT_INVENTORY.CHEST,
    [EQUIPMENT_SUB.WAIST]        = EQUIPMENT_INVENTORY.WAIST,
    [EQUIPMENT_SUB.BANGLE]       = EQUIPMENT_INVENTORY.BANGLE,
    [EQUIPMENT_SUB.PANTS]        = EQUIPMENT_INVENTORY.PANTS,
    [EQUIPMENT_SUB.BOOTS]        = EQUIPMENT_INVENTORY.BOOTS,
    [EQUIPMENT_SUB.AMULET]       = EQUIPMENT_INVENTORY.AMULET,
    [EQUIPMENT_SUB.PENDANT]      = EQUIPMENT_INVENTORY.PENDANT,
    [EQUIPMENT_SUB.RING]         = EQUIPMENT_INVENTORY.LEFT_RING, -- 戒指默认用戒指一的装备栏属性
    [EQUIPMENT_SUB.MELEE_WEAPON] = EQUIPMENT_INVENTORY.MELEE_WEAPON, -- EQUIPMENT_INVENTORY.BIG_SWORD特殊处理
    [EQUIPMENT_SUB.RANGE_WEAPON] = EQUIPMENT_INVENTORY.RANGE_WEAPON,
}
function EquipData.GetEquipInventory(nSub, nDetail)
    local nEquipInv = m_tEquipSubToInventory[nSub]
    if nDetail then
		if nDetail == WEAPON_DETAIL.BIG_SWORD then
			nEquipInv = EQUIPMENT_INVENTORY.BIG_SWORD
		elseif nDetail == WEAPON_DETAIL.MELEE_WEAPON then
			nEquipInv = EQUIPMENT_INVENTORY.MELEE_WEAPON
		end
    end
    return nEquipInv
end

local function IsEqualDiamond(dwEnchant1, dwEnchant2)
    if dwEnchant1 <= 0 or dwEnchant2 <=0 then
        return
    end

    local dwTabType1, dwIndex1 = GetDiamondInfoFromEnchantID(dwEnchant1)
    local dwTabType2, dwIndex2 = GetDiamondInfoFromEnchantID(dwEnchant2)
    local tDiamond1 = nil
    local tDiamond2 = nil
    local nLevel1 = 0
    local nLevel2 = 0

    if dwTabType1 and dwIndex1 then
        tDiamond1 = ItemData.GetItemInfo(dwTabType1, dwIndex1)
        if tDiamond1 then
            nLevel1 = tDiamond1.nDetail
        end
    end

    if dwTabType2 and dwIndex2 then
        tDiamond2 = ItemData.GetItemInfo(dwTabType2, dwIndex2)
        if tDiamond2 then
            nLevel2 = tDiamond1.nDetail
        end
    end

    return nLevel1 == nLevel2 and nLevel1 ~= 0
end

function EquipData.GetAdaptedEnchantID(nSlotIndex, item, bItem, tSource)
    local dwTrueEnchantID = 0
    local bEquipBoxInvalid = false

    local pPlayer = GetSourcePlayer(tSource)
    if pPlayer then
		local nEquipInv = EquipData.GetEquipInventory(item.nSub, item.nDetail)
		if item.nDetail and item.nDetail == WEAPON_DETAIL.BIG_SWORD and item.nSub == EQUIPMENT_SUB.MELEE_WEAPON then
			nEquipInv = EQUIPMENT_INVENTORY.MELEE_WEAPON
		end

        local tInfo = EquipData.GetSlotBoxInfo(nEquipInv, nSlotIndex, pPlayer)
        local dwBoxEnchantID = tInfo.dwEnchantID
        local dwEquipEnchantID = 0
        if bItem then
            local dwAdaptedEnchantID = item.GetAdaptedDiamondEnchantID(nSlotIndex, item.nLevel, dwBoxEnchantID)
            dwTrueEnchantID = dwAdaptedEnchantID
            dwEquipEnchantID = item.GetMountDiamondEnchantID(nSlotIndex)
        else
            dwTrueEnchantID = dwBoxEnchantID
        end
        if dwTrueEnchantID == dwBoxEnchantID and item.nLevel > tInfo.nQuality and not IsEqualDiamond(dwTrueEnchantID, dwEquipEnchantID) then
            bEquipBoxInvalid = true
        end
    elseif bItem then -- Link走这里
        dwTrueEnchantID = item.GetMountDiamondEnchantID(nSlotIndex)
    end
    return dwTrueEnchantID, bEquipBoxInvalid
end

function EquipData.GetEquipSlotDiamon(nIndex, item, bItem, tSource)
	local diamon, nType, nTabIndex
    local dwEnchantID = EquipData.GetAdaptedEnchantID(nIndex, item, bItem, tSource)
    if dwEnchantID > 0 then
        nType, nTabIndex = GetDiamondInfoFromEnchantID(dwEnchantID)
        if nType and nTabIndex then
            diamon = GetItemInfo(nType, nTabIndex)
        end
	elseif tSource.tbPowerUpInfo and tSource.tbPowerUpInfo.tbSlotInfo and tSource.tbPowerUpInfo.tbSlotInfo[nIndex + 1] then
		local nLevel = tSource.tbPowerUpInfo.tbSlotInfo[nIndex + 1]
		local nItemTabID = WU_XING_STONE_ITEM_ID[nLevel]
		if nItemTabID then
			nType = ITEM_TABLE_TYPE.OTHER
			nTabIndex = nItemTabID
            diamon = GetItemInfo(nType, nTabIndex)
		end
    end

	return diamon, nType, nTabIndex
end

function EquipData.GetAttriInfo(nIndex, item, bItem, nLevel, tSource)
    local dwEnchantID = 0
    local bEquipBoxInvalid = false
    dwEnchantID, bEquipBoxInvalid = EquipData.GetAdaptedEnchantID(nIndex, item, bItem, tSource)
    return dwEnchantID > 0 and not bEquipBoxInvalid, item.GetSlotAttrib(nIndex, nLevel) or {}
end

function EquipData.CheckIsWeaponNotActiveSlot(player, item, nEquip)
	local bNotActiveSlot = false
	if player and item then
		local tBindWeaponInfo = player.GetColorDiamondSlotBindWeaponInfo()
		for k, v in pairs(tBindWeaponInfo) do
			if v[1] == item.dwTabType and v[2] == item.dwIndex then
				bNotActiveSlot = v[3] == 0
				break
			end
		end
	end

	return bNotActiveSlot
end

function EquipData.CheckIsEquipSlotQualityLower(item, nEquip)
    local bQualityLowerThanEquip = false

    for slotIndex = 1, 3 do
        local cpp_SlotIndex = slotIndex - 1
        local tInfo = EquipData.GetSlotBoxInfo(nEquip, cpp_SlotIndex)
        local bCanMount = tInfo.bCanMount

        if bCanMount then
            if item and tInfo.nQuality ~= 0 and tInfo.nQuality < item.nLevel then
                bQualityLowerThanEquip = true -- 未熔嵌孔的Quality默认为0，忽略
            end
        end
    end

	return bQualityLowerThanEquip
end

function EquipData.GetHorseMeasureState(item, bItem)
	local szTip = ""
	local colorType
    if bItem and item then
		-----------马匹饱食程度-----------------
		local tDisplay = Table_GetRideSubDisplay(item.nDetail)
		local nFullLevel = item.GetHorseFullLevel()
		local szFullMeasureState = tDisplay["szFullMeasure" .. (nFullLevel + 1)]
		if nFullLevel == FULL_LEVEL.FULL then
			colorType = cc.c3b(0x95, 0XFF, 0X95)
		elseif nFullLevel == FULL_LEVEL.HALF_HUNGRY then
			colorType = cc.c3b(0x89, 0XDF, 0XFF)
		elseif nFullLevel == FULL_LEVEL.HUNGRY then
			colorType = cc.c3b(0xFF, 0XE2, 0X6E)
		end
		szFullMeasureState = UIHelper.GBKToUTF8(szFullMeasureState)
		szTip = szFullMeasureState
	end
	return szTip, colorType
end

function EquipData.GetSlotAttr(item, nSlot, bItem, force_active, tSource, nLevel)
	local nLevel = nLevel or 0
	local diamon = EquipData.GetEquipSlotDiamon(nSlot, item, bItem, tSource)
	if diamon then
		nLevel = diamon.nDetail
	end

	if tSource.tbPowerUpInfo then
		if tSource.tbPowerUpInfo.tbSlotInfo and tSource.tbPowerUpInfo.tbSlotInfo[nSlot + 1] then
			nLevel = tSource.tbPowerUpInfo.tbSlotInfo[nSlot + 1]
			force_active = nLevel > 0
		end
	end

	local bActived, equipAttrib = EquipData.GetAttriInfo(nSlot, item, bItem, nLevel, tSource)
	if force_active ~= nil then
		bActived = force_active
	end

	if not bActived then
		equipAttrib.Param0 = g_tStrings.STR_QUESTION_M
		equipAttrib.Param1 = g_tStrings.STR_QUESTION_M
	end
	local szTmpText = nil
	if not bActived then
		szTmpText = g_tStrings.tDeactives[equipAttrib.nID]
	end

	if not szTmpText then
		szTmpText = FormatString(UIHelper.GBKToUTF8(Table_GetMagicAttributeInfo(equipAttrib.nID, true)), equipAttrib.Param0, equipAttrib.Param1, MAGIC_ATTRI_DEF, MAGIC_ATTRI_DEF)
		szTmpText = string.pure_text(szTmpText)
	end
	szTmpText = g_tStrings.STR_ITEM_SLOT .. szTmpText
	return szTmpText, bActived
end

-- 在玩家身上查找与装备匹配的心法，找不到则返回空值
function EquipData.GetItemMatchKungfu(item)
	local itemInfo = ItemData.GetItemInfo(item.dwTabType, item.dwIndex)
	local playerKungFuList = SkillData.GetKungFuList()
	if playerKungFuList and #playerKungFuList >= 1 and itemInfo and itemInfo.nRecommendID and g_tTable.EquipRecommend then
		local tHDKungFuIDs = {}
		for _, tInfo in ipairs(playerKungFuList) do
			local nKungFu = TabHelper.GetHDKungfuID(tInfo[1])
			tHDKungFuIDs[nKungFu] = true
		end
		
		local t = g_tTable.EquipRecommend:Search(itemInfo.nRecommendID)
		if t and t.szDesc and t.szDesc ~= "" then
			local tbIDs = string.split(t.kungfu_ids, "|")

			for _, szID in ipairs(tbIDs) do
				local nID = tonumber(szID)
				if tHDKungFuIDs[nID] then
					return nID
				end
			end
		end
	end
end

----附魔属性--------------------------
function EquipData.GetEnchantAttribTip(item, player, tbPowerUpInfo)
	player = player or GetClientPlayer()

	local tEnchantTipShow = Table_GetEnchantTipShow()
	local tShow = tEnchantTipShow[item.nSub]

	local tbInfo = {}
	local nNeedUpdate = false
	local fnAction = function (v)
		if v.nID == ATTRIBUTE_TYPE.SKILL_EVENT_HANDLER then
			local skillEvent = g_tTable.SkillEvent:Search(v.nValue1)
			if skillEvent then
				return FormatString(skillEvent.szDesc, v.nValue1, v.nValue2)
			else
				return "unknown skill event id:"..v.nValue1
			end
		elseif v.nID == ATTRIBUTE_TYPE.SET_EQUIPMENT_RECIPE then
			return EquipData.GetEquipRecipeDesc(v.nValue1, v.nValue2)
		else
			EquipData.FormatAttributeValue(v)
			return FormatString(Table_GetMagicAttributeInfo(v.nID, true), v.nValue1, v.nValue2, MAGIC_ATTRI_DEF, MAGIC_ATTRI_DEF)
		end
	end

	local szText
	local szImagePath = "ui/Image/UICommon/FEPanel.UITex"
	local nFrame = "UIAtlas2_Character_Character2_img_Enchant_In.png"
	local nUnEnchantFrame = "UIAtlas2_Character_Character2_img_Enchant_Empty.png"

	local nSruvivalFrame = "UIAtlas2_Character_Character2_img_Enchant_In.png"
	local nUnSruvivalFrame = "UIAtlas2_Character_Character2_img_Enchant_Empty.png"
	local nSpecialFrame = "UIAtlas2_Character_Character2_img_Enchant_KunWuSand.png"

	local dwPermanentEnchantID = 0
	if tbPowerUpInfo then
		if tbPowerUpInfo.tbEnchant and tbPowerUpInfo.tbEnchant.nID then
			dwPermanentEnchantID = tbPowerUpInfo.tbEnchant.nID
		end
	elseif item.dwPermanentEnchantID and item.dwPermanentEnchantID > 0 then
		dwPermanentEnchantID = item.dwPermanentEnchantID
	end
	if dwPermanentEnchantID ~= 0 then
		local desc = UIHelper.GBKToUTF8(Table_GetCommonEnchantDesc(dwPermanentEnchantID))
		if desc then
			table.insert(tbInfo, {
				szEnchantIconImg = nFrame,
				szAttr = string.pure_text(desc),
				bActived = true,
			})
		else
			local enchantAttrib = GetItemEnchantAttrib(dwPermanentEnchantID);
			if enchantAttrib then
				for k, v in pairs(enchantAttrib) do
					szText = UIHelper.GBKToUTF8(fnAction(v))
					table.insert(tbInfo, {
						szEnchantIconImg = nFrame,
						szAttr = string.pure_text(szText),
						bActived = true,
					})
				end
			end
		end
	else
		if tShow and tShow.bPermanentEnchant then
			table.insert(tbInfo, {
				szEnchantIconImg = nUnEnchantFrame,
				szAttr = g_tStrings.ITEM_TIP_NO_ENCHANT_PERMANENT,
				bActived = false,
			})
		end
	end
	local bSurvival = tShow and tShow.bSurvivalEnchant
	if tbPowerUpInfo then
		local bMatchSub = (item.nSub == EQUIPMENT_SUB.HELM or item.nSub == EQUIPMENT_SUB.CHEST or item.nSub == EQUIPMENT_SUB.WAIST
                    or item.nSub == EQUIPMENT_SUB.BANGLE or item.nSub == EQUIPMENT_SUB.BOOTS)
		local bMatchLevel = item.nLevel >= 5600
		if bMatchSub and bMatchLevel then
			local szDesc
			if tbPowerUpInfo.tbBigEnchant and tbPowerUpInfo.tbBigEnchant.nID then
				dwEnchantID = tbPowerUpInfo.tbBigEnchant and tbPowerUpInfo.tbBigEnchant.nID
				local nItemTabID = EnchantData.GetItemIndexWithEnchantID(dwEnchantID)
				local itemInfo = ItemData.GetItemInfo(5, nItemTabID)
				local szItemDesc = ItemData.GetItemDesc(itemInfo.nUiId)
				szDesc = ParseTextHelper.ParseNormalText(szItemDesc, true)
			else
           		local tbRecommendEquipInfo = Table_GetRecommendEquipInfo(tbPowerUpInfo.nTabType, tbPowerUpInfo.nTabID)
				if tbRecommendEquipInfo and tbRecommendEquipInfo.tbConfig and tbRecommendEquipInfo.tbConfig.nEquipUsage == EQUIPMENT_USAGE_TYPE.IS_PVE_EQUIP then
					local tbBigEnchantItemIndex = EnchantData.GetRecommendEnchantWithItemInfo(item, 2, EquipCodeData.dwCurKungfuID, EQUIPMENT_USAGE_TYPE.IS_PVE_EQUIP)
					for nItemTabID, _ in pairs(tbBigEnchantItemIndex) do
						local itemInfo = ItemData.GetItemInfo(5, nItemTabID)
						local szItemDesc = ItemData.GetItemDesc(itemInfo.nUiId)
						szDesc = ParseTextHelper.ParseNormalText(szItemDesc, true)
						break
					end
				end
			end

			if szDesc then
				-- szDesc = string.format("<color=#D7F6FF>%s</c>", szDesc)
				table.insert(tbInfo, {
					szEnchantIconImg = nSpecialFrame,
					szAttr = szDesc,
					bActived = true,
				})
			end
		end
	elseif item.dwTemporaryEnchantID and item.dwTemporaryEnchantID > 0 then
		local bValid = player.IsTempEnchantValid(item.dwTemporaryEnchantID)
		local desc = UIHelper.GBKToUTF8(Table_GetCommonEnchantDesc(item.dwTemporaryEnchantID))
		local nImageFrame = nFrame
		if bValid then
			if bSurvival then
				nImageFrame = nSruvivalFrame
			end
		end
		if desc then
			desc = string.pure_text(desc)
			if desc ~= "" and not bSurvival then
                if item.nSub == EQUIPMENT_SUB.MELEE_WEAPON or item.nSub == EQUIPMENT_SUB.PANTS then
                    local szTime = FormatString(g_tStrings.STR_ITEM_TEMP_ECHANT_LEFT_TIME, UIHelper.GetTimeText(item.GetTemporaryEnchantLeftSeconds()))
                    desc = desc .. string.format("<color=#FF4040>%s</c>", szTime)
					nNeedUpdate = true
                else
					nImageFrame = nSpecialFrame
				end
			end
			table.insert(tbInfo, {
				szEnchantIconImg = nImageFrame,
				szAttr = desc,
				bActived = true,
			})
		else
			local tempEnchantAttrib = GetItemEnchantAttrib(item.dwTemporaryEnchantID);
			if tempEnchantAttrib then
				for k, v in pairs(tempEnchantAttrib) do
					szText = UIHelper.GBKToUTF8(fnAction(v))
					szText = string.pure_text(szText)
					if szText ~= "" and not bSurvival then
                        if item.nSub == EQUIPMENT_SUB.MELEE_WEAPON or item.nSub == EQUIPMENT_SUB.PANTS then
                            local szTime = FormatString(g_tStrings.STR_ITEM_TEMP_ECHANT_LEFT_TIME, UIHelper.GetTimeText(item.GetTemporaryEnchantLeftSeconds()))
							szText = szText .. string.format("<color=#FF4040>%s</c>", szTime)
							nNeedUpdate = true
						else
                            nImageFrame = nSpecialFrame
						end
					end
					table.insert(tbInfo, {
						szEnchantIconImg = nImageFrame,
						szAttr = szText,
						bActived = true,
					})
				end
			end
		end
	else
		if bSurvival then
			table.insert(tbInfo, {
				szEnchantIconImg = nUnSruvivalFrame,
				szAttr = g_tStrings.ITEM_TIP_NO_ENCHANT_SURVIVAL,
				bActived = false,
			})
		elseif tShow and tShow.bTemporaryEnchant then
			table.insert(tbInfo, {
				szEnchantIconImg = nUnSruvivalFrame,
				szAttr = g_tStrings.ITEM_TIP_NO_ENCHANT_TEMPORARY,
				bActived = false,
			})
		end
	end

	return tbInfo, nNeedUpdate
end

function EquipData.GetEnchantAttribTipWithItemInfo(itemInfo)
	local player = GetClientPlayer()

	local tEnchantTipShow = Table_GetEnchantTipShow()
	local tShow = tEnchantTipShow[itemInfo.nSub]

	local tbInfo = {}

	if tShow and tShow.bPermanentEnchant then
		table.insert(tbInfo, {
			szEnchantIconImg = nUnEnchantFrame,
			szAttr = g_tStrings.ITEM_TIP_NO_ENCHANT_PERMANENT,
			bActived = false,
		})
	end
	local bSurvival = tShow and tShow.bSurvivalEnchant
	if bSurvival then
		table.insert(tbInfo, {
			szEnchantIconImg = nUnSruvivalFrame,
			szAttr = g_tStrings.ITEM_TIP_NO_ENCHANT_SURVIVAL,
			bActived = false,
		})
	elseif tShow and tShow.bTemporaryEnchant then
		table.insert(tbInfo, {
			szEnchantIconImg = nUnSruvivalFrame,
			szAttr = g_tStrings.ITEM_TIP_NO_ENCHANT_TEMPORARY,
			bActived = false,
		})
	end

	return tbInfo
end

-------------------------------------- 套装属性----------------------------------------------------
local _tUISet
local _dwSetID
local MAGIC_ATTRI_DEF = 0

local function GetReplaceID(nUiId)
	if not tEquipRelpace then
		EquipData.LoadEquipRelpace()
	end

	if tEquipRelpace[nUiId] then
		return tEquipRelpace[nUiId]
	end

	return nUiId
end

local function IsItemEquiped(player, nUiId, nEquipPos)
	local item = ItemData.GetPlayerItem(player, INVENTORY_INDEX.EQUIP, nEquipPos)
	if item and GetReplaceID(item.nUiId) == nUiId then
		return true
	end
end

local function GetSetAttriValueTip(setAttrib, bSetAttriEnable, nHave, setUiId)
	local bFirst = true
	local szTip = ""
	local tbInfo = {}
	local tbDXInfo = {}
	local tbVKInfo = {}

	local bShowSign = false
	for k, tSet in pairs(setAttrib) do
		for _, v in pairs(tSet.Attrib) do
			if v.nID == ATTRIBUTE_TYPE.SKILL_EVENT_HANDLER then
				local skillEvent = g_tTable.SkillEvent:Search(v.nValue1)
				if skillEvent then
					local szAttr = UIHelper.GBKToUTF8(FormatString(skillEvent.szDesc, v.nValue1, v.nValue2))
					bShowSign = bShowSign or skillEvent.bIsMobile
				end
			elseif v.nID == ATTRIBUTE_TYPE.SET_EQUIPMENT_RECIPE then
				local szAttr, bIsMobile = EquipData.GetEquipRecipeDesc(v.nValue1, v.nValue2)
				bShowSign = bShowSign or bIsMobile
			else
				local bIsMobile = Table_GetMagicAttributeIsMobile(v.nID, true)
				bShowSign = bShowSign or bIsMobile
			end
		end
	end

	for k, tSet in pairs(setAttrib) do
		local szAt = ""
		local bShowMobile = false
		for _, v in pairs(tSet.Attrib) do
			if not string.is_nil(szAt) then
				szAt = szAt .. g_tStrings.STR_COMMA
			end

			if v.nID == ATTRIBUTE_TYPE.SKILL_EVENT_HANDLER then
				local skillEvent = g_tTable.SkillEvent:Search(v.nValue1)
				if skillEvent then
					local szAttr = UIHelper.GBKToUTF8(FormatString(skillEvent.szDesc, v.nValue1, v.nValue2))
					if skillEvent.bIsMobile and not bShowMobile then
						szAt = szAt .. "{Mobile}" .. string.pure_text(szAttr)
						bShowMobile = true
					else
						szAt = szAt .. string.pure_text(szAttr)
					end
				else
					szAt = szAt .. "unknown skill event id:"..v.nValue1
				end
			elseif v.nID == ATTRIBUTE_TYPE.SET_EQUIPMENT_RECIPE then
				local szAttr, bIsMobile = EquipData.GetEquipRecipeDesc(v.nValue1, v.nValue2)
				if bIsMobile and not bShowMobile then
					szAt = szAt .. "{Mobile}" .. string.pure_text(UIHelper.GBKToUTF8(szAttr))
					bShowMobile = true
				else
					szAt = szAt .. string.pure_text(UIHelper.GBKToUTF8(szAttr))
				end
			else
				EquipData.FormatAttributeValue(v)
				local bIsMobile = Table_GetMagicAttributeIsMobile(v.nID, true)
				local szAttr = UIHelper.GBKToUTF8(FormatString(Table_GetMagicAttributeInfo(v.nID, true), v.nValue1, v.nValue2, MAGIC_ATTRI_DEF, MAGIC_ATTRI_DEF))
				if bIsMobile and not bShowMobile then
					szAt = szAt .. "{Mobile}" .. string.pure_text(szAttr)
					bShowMobile = true
				else
					szAt = szAt .. string.pure_text(szAttr)
				end
			end
		end

		if not string.is_nil(szAt) then
			if bShowSign then
				local tbAts = string.split(szAt, g_tStrings.STR_COMMA .. "{Mobile}")
				local szTip = ""
				for i, sz in ipairs(tbAts) do
					if i == 1 and #tbAts > 1 then
						local szTip = string.format("[%d]%s", tSet.nCount, sz)
						table.insert(tbDXInfo, {
							szTip = szTip,
							bActived = bSetAttriEnable and nHave >= tSet.nCount,
							bIsMobile = false,
						})
					elseif #tbAts == 1 or i == 2 then
						local szTip = string.format("[%d]%s", tSet.nCount, sz)
						table.insert(tbVKInfo, {
							szTip = szTip,
							bActived = bSetAttriEnable and nHave >= tSet.nCount,
							bIsMobile = true,
						})
					end
				end

				if #tbVKInfo > #tbDXInfo then
					local szTip = string.format("[%d]%s", tSet.nCount, "属性效果双端一致")
					table.insert(tbDXInfo, {
						szTip = szTip,
						bActived = bSetAttriEnable and nHave >= tSet.nCount,
						bIsMobile = false,
					})
				end
			else
				table.insert(tbInfo, {
					szTip = "["..tSet.nCount.."]" .. szAt,
					bActived = bSetAttriEnable and nHave >= tSet.nCount,
				})
			end

		end
	end

	if #tbDXInfo > 0 and #tbVKInfo > 0 then
		local szTip = string.format("%s%s", EquipSuitPlatformType2Desc[2], "套装属性效果")
		table.insert(tbInfo, {
			szTip = szTip,
			bActived = true,
			bIsMobile = true,
		})
		for index, value in ipairs(tbVKInfo) do
			table.insert(tbInfo, value)
		end

		local szTip = string.format("%s%s", EquipSuitPlatformType2Desc[1], "套装属性效果")
		table.insert(tbInfo, {
			szTip = szTip,
			bActived = true,
			bIsMobile = true,
		})
		for index, value in ipairs(tbDXInfo) do
			table.insert(tbInfo, value)
		end
	end
	return tbInfo
end

local function GetReplaceTipInfo(dwSetID, nUIID, bEquiped)
	-- local szColorFormat = "<color=#FFFFFF>%s</c>\n"	--未穿戴装备字体
	-- if bEquiped then
	-- 	szColorFormat = "<color=#F9B222>%s</c>\n"
	-- end
	local tLine = g_tTable.EquipSet:Search(dwSetID, nUIID)
	local szName = UIHelper.GBKToUTF8(Table_GetItemName(nUIID))
	if not tLine then
		-- return string.format(szColorFormat, szName)

		return szName
	end

	if tLine then
		if tLine.szDesc ~= "" then
			-- return string.format(szColorFormat, UIHelper.GBKToUTF8(tLine.szDesc))
			szName=UIHelper.GBKToUTF8(tLine.szDesc)
			return szName
		end
		local szDesc = szName
		local tReplace = SplitString(UIHelper.GBKToUTF8(tLine.szReplaceUIID), ";")
		for k, szUIID in ipairs(tReplace) do
			szDesc = szDesc .. " / " .. szName
		end
		-- szDesc = string.format(szColorFormat, szDesc)
		return szDesc
	end
end

function EquipData.GetUISetInfo(dwSetID)
	if _dwSetID == dwSetID and _tUISet then
		return _tUISet
	end

	local tab = g_tTable.Set
	local nrow = tab:GetRowCount()
	local tLine
	local tRes
	for i = 2, nrow, 1 do
		tLine = tab:GetRow(i)
		if dwSetID == tLine.setid then
			tRes = tRes or {}
			table.insert(tRes, tLine)
		elseif tRes then
			break
		end
	end

	if tRes then
		_tUISet = tRes
		_dwSetID = dwSetID
	end
	return tRes
end

function EquipData.GetSetAttriTipFromUI(tUISet, dwSetID, dwPlayerID, dwSchoolID, bItemInfo)
	local setUiId, _, _, _, setAttrib, dwSchoolMask = GetItemSetAttrib(dwSetID, dwPlayerID);
	local player = GetPlayer(dwPlayerID)
	local tbAttribInfos = {}
	local activecount = 0
	-- local szTip = ""
	-- local szTip1 = ""

	local bSetAttriEnable, szEnableInfo = EquipData.GetSetSchoolInfo(dwSchoolMask, dwSchoolID)
	if szEnableInfo ~= "" then
		table.insert(tbAttribInfos, {
			szTip = FormatString(g_tStrings.STR_SET_ATTRI_SCHOOL, szEnableInfo),
		})
	end

	for _, v in ipairs(tUISet) do
		local nUsefulUiID = v.uiid
		local bEquiped = false
		nUsefulUiID = GetReplaceID(nUsefulUiID)
		if not bItemInfo and IsItemEquiped(player, nUsefulUiID, EQUIPMENT_INVENTORY[v.pos]) then
			activecount = activecount + 1
			bEquiped = true
		end
		table.insert(tbAttribInfos, {
			szTip = GetReplaceTipInfo(dwSetID, nUsefulUiID, v),
			bEquiped = bEquiped
		})
	end

	table.insert(tbAttribInfos, 2, {	--第二行中插入套装收集信息
		szTip = FormatString(g_tStrings.STR_ITEM_H_SET_NAME1, UIHelper.GBKToUTF8(Table_GetItemName(setUiId)), activecount, #tUISet),
	})

	table.insert_tab(tbAttribInfos, GetSetAttriValueTip(setAttrib, bSetAttriEnable, activecount, setUiId))

	return tbAttribInfos
end

function EquipData.LoadEquipRelpace()
	tEquipRelpace = {}
	local nCount = g_tTable.EquipSet:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.EquipSet:GetRow(i)
		local tReplace = SplitString(tLine.szReplaceUIID, ";")
		tEquipRelpace[tLine.nUIID] = tLine.nUIID
		for _, szUIID in ipairs(tReplace) do
			local nUIID = tonumber(szUIID)
			tEquipRelpace[nUIID] = tLine.nUIID
		end
	end
end

function EquipData.GetEquipUnActiveItem(player)
	if not player or not player.bCanUseBigSword then
		return
	end

	local item
	if player.bBigSwordSelected then
		item = ItemData.GetPlayerItem(player, INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.MELEE_WEAPON)
	else
		item = ItemData.GetPlayerItem(player, INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.BIG_SWORD)
	end
	return item
end

function EquipData.GetSetSchoolInfo(dwSchoolMask, dwSchoolID)
	local bEnable = false
	if dwSchoolMask == 0 then
		bEnable = true
	elseif dwSchoolID and dwSchoolID ~= 0 then
		bEnable = GetNumberBit(dwSchoolMask, dwSchoolID + 1)
	end

	local szTip = ""
	if dwSchoolMask ~= 0 then
		local bHaveCangjian = false
		for k, v in pairs(g_tStrings.tSchoolTitle) do
			if k ~= 0 and GetNumberBit(dwSchoolMask, GetBitOPSchoolID(k) + 1) then
				local szText = ""
				if szTip ~= "" then
					szText = g_tStrings.STR_PAUSE
				end
				szText = szText .. string.format("%s%s", v, g_tStrings.STR_SKILL_NG)
				if k == SCHOOL_TYPE.CANG_JIAN_WEN_SHUI or k == SCHOOL_TYPE.CANG_JIAN_SHAN_JU then --藏剑内功只显示一个
					if bHaveCangjian then
						szText = ""
					end
					bHaveCangjian = true
				end
				szTip = szTip .. szText
			end
		end
	end
	return bEnable, szTip
end

function EquipData.GetSetAttriTip(dwSetID, dwPlayerID, dwSchoolID, bItemInfo)
	local szTip = ""
	local tbAttribInfos = {}
	-- local player = {}

	local tUISet = EquipData.GetUISetInfo(dwSetID)
	if tUISet then
		return EquipData.GetSetAttriTipFromUI(tUISet, dwSetID, dwPlayerID, dwSchoolID, bItemInfo)
	end

	local setUiId, setTableOrg, nTotal, nHave, setAttrib, dwSchoolMask = GetItemSetAttrib(dwSetID, dwPlayerID);
	if not setUiId then
		return
	end

	if not tEquipRelpace then
		EquipData.LoadEquipRelpace()
	end

	local player = GetPlayer(dwPlayerID)
	-- if dwPlayerID then
	-- 	player = GetVideoManager().GetCompetitor(dwPlayerID)
	-- end

	local unActiveItem
	if not bItemInfo then
		unActiveItem = EquipData.GetEquipUnActiveItem(player)
	end

	local bSetAttriEnable, szEnableInfo = EquipData.GetSetSchoolInfo(dwSchoolMask, dwSchoolID)
	if szEnableInfo ~= "" then
		table.insert(tbAttribInfos, {
			szTip = FormatString(g_tStrings.STR_SET_ATTRI_SCHOOL, szEnableInfo),
		})
	end

	local nNewTotal = 0
	local nNewHave  = 0
	local setTable = {}
	-- local ReplaceTable = {}
	for k, v in pairs(setTableOrg) do
		local nUsefulUiID = v.nUiId
		if tEquipRelpace[nUsefulUiID] then
			nUsefulUiID = tEquipRelpace[nUsefulUiID]
		end

		if setTable[nUsefulUiID] == nil then

			setTable[nUsefulUiID] = v.bEquiped
			nNewTotal = nNewTotal + 1
		else
			setTable[nUsefulUiID] = setTable[nUsefulUiID] or v.bEquiped
		end

		if unActiveItem and unActiveItem.nUiId == nUsefulUiID then -- cang jian two sowrd3 only active one
			setTable[nUsefulUiID] = false;
		end
	end

	for k, v in pairs(setTable) do
		if v then
			nNewHave = nNewHave + 1
		end
	end
	nTotal = nNewTotal
	nHave  = nNewHave

	table.insert(tbAttribInfos, {
		szTip = FormatString(g_tStrings.STR_ITEM_H_SET_NAME1, UIHelper.GBKToUTF8(Table_GetItemName(setUiId)), nHave, nTotal),
	})

	for k, v in pairs(setTable) do
		table.insert(tbAttribInfos, {
			szTip = GetReplaceTipInfo(dwSetID, k, v),
			bEquiped = v
		})
	end

	table.insert_tab(tbAttribInfos, GetSetAttriValueTip(setAttrib, bSetAttriEnable, nHave, setUiId))
	return tbAttribInfos
end
-------------------------------------- 套装属性_END----------------------------------------------------

function EquipData.GetEquipStrengthInfo(player, item, bItem, nEquipInventory)
    local tInfo =
    {   -- Equip:装备属性  Box:装备栏属性  Quality:品质等级
        nEquipLevel = 0,
        nEquipMaxLevel = 0,
        nBoxLevel = 0,
        nBoxMaxLevel = 0,
        nBoxMaxQuality = 0,
        nBoxQuality = 0,
        nTrueLevel = 0,
        bBoxAttr = 0,
        szTip = ""
    }
    local nEquipQuality = 0
    local _, nEquipInv = nil, nEquipInventory
    if item then
		if not nEquipInv then
        	_, nEquipInv = ItemData.GetEquipItemEquiped(player, item.nSub, item.nDetail)
		end
		if nEquipInv == EQUIPMENT_INVENTORY.BIG_SWORD then --藏剑重剑对应轻剑装备栏
			nEquipInv = EQUIPMENT_INVENTORY.MELEE_WEAPON
		end

        nEquipQuality = item.nLevel
        if bItem then
            tInfo.nEquipLevel = item.nStrengthLevel or 0
            tInfo.nEquipMaxLevel = ItemData.GetItemInfo(item.dwTabType, item.dwIndex).nMaxStrengthLevel or 0
        else -- ItemInfo走这里
            tInfo.nEquipLevel = 0
            tInfo.nEquipMaxLevel = item.nMaxStrengthLevel and item.nMaxStrengthLevel or 0
        end
    end

    if player and nEquipInv then
		if nEquipInv == EQUIPMENT_INVENTORY.BIG_SWORD then --藏剑重剑对应轻剑装备栏
			nEquipInv = EQUIPMENT_INVENTORY.MELEE_WEAPON
		end

        local nBoxLevel, nBoxQuality = player.GetEquipBoxStrength(nEquipInv)
        tInfo.nBoxLevel = nBoxLevel or 0
        tInfo.nBoxQuality = nBoxQuality or 0
        tInfo.nBoxMaxLevel, tInfo.nBoxMaxQuality = GetEquipBoxMaxStrengthInfo(nEquipInv)

        if nEquipQuality <= tInfo.nBoxQuality then              -- 检查品质等级
            if tInfo.nBoxLevel >= tInfo.nEquipLevel then        -- 检查装备栏等级
                if tInfo.nBoxLevel <= tInfo.nEquipMaxLevel then -- 检查装备等级上限
                    tInfo.nTrueLevel = tInfo.nBoxLevel
                    tInfo.bBoxAttr = true
                else                                            -- 装备栏等级溢出
                    tInfo.nTrueLevel = tInfo.nEquipMaxLevel
                    tInfo.bBoxAttr = true
                    tInfo.szTip = "装备栏等级溢出"
                end
            else                                                -- 装备栏等级偏低
                tInfo.nTrueLevel = tInfo.nEquipLevel
                tInfo.bBoxAttr = false
                tInfo.szTip = "装备栏等级偏低"
            end
        else                                                    -- 装备栏品质不足
            tInfo.nTrueLevel = tInfo.nEquipLevel
            tInfo.bBoxAttr = false
            if tInfo.nBoxLevel > 0 then
                tInfo.szTip = "装备栏品质不足"
                tInfo.bBoxQualityNotEnough = true
            end
        end
    else                                                        -- 此部位尚未穿戴
        tInfo.nTrueLevel = tInfo.nEquipLevel
        tInfo.bBoxAttr = false
        tInfo.szTip = "此部位尚未穿戴"
    end
    return tInfo
end

function EquipData.CanBreak(dwTargetBox, dwTargetX)
	local player = GetClientPlayer()
	if not player then
		return false
	end
	local hItem = player.GetItem(dwTargetBox, dwTargetX)
	if not hItem then
		return false
	end

	local nRet = player.CanBreakEquip(dwTargetBox, dwTargetX)
	if nRet == BREAK_EQUIP_RESULT_CODE.NEED_CAN_SELL or nRet == BREAK_EQUIP_RESULT_CODE.EQUIP_NEED_CAN_BEBREAK or
	nRet == BREAK_EQUIP_RESULT_CODE.NOT_IN_PACKAGE or nRet == BREAK_EQUIP_RESULT_CODE.FAILED or nRet == BREAK_EQUIP_RESULT_CODE.NEED_EQUIPMENT
	then
		-- OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.BREAK_EQUIP_RESULT[ nRet ])
		return false;
	end

	return true
end

function EquipData.IsCanTimeReturnItem(item)
	if not item then
		return false
	end

	local player = g_pClientPlayer
	local nLeftTime = player.GetTimeLimitReturnItemLeftTime(item.dwID)
	return (nLeftTime > 0)
end

function EquipData.IsCanTimeTradeItem(item)
	if not item then
		return false
	end

	local player = g_pClientPlayer
	local nLeftTime = player.GetTradeItemLeftTime(item.dwID)
	return (nLeftTime > 0)
end

function EquipData.GetTimeOperateItemTip(item)
	local szText = ""
	if EquipData.IsCanTimeReturnItem(item) then
		szText = szText .. GetFormatText(g_tStrings.TIME_RETURN_MSG)
	end

	if EquipData.IsCanTimeTradeItem(item) then
		szText = szText .. GetFormatText("\n"..g_tStrings.STR_EN_PREV_PANT)..
				FormatString(g_tStrings.STR_TRADE_BIND, 71) ..
				GetFormatText(g_tStrings.STR_EN_END_PANT)
	end
	return szText
end

function EquipData.GetStrength(pItem, bItem, tSource)
    local tInfo =
    {   -- Equip:装备属性  Box:装备栏属性  Quality:品质等级
        nEquipLevel = 0,
        nEquipMaxLevel = 0,
        nBoxLevel = 0,
        nBoxMaxLevel = 0,
        nBoxQuality = 0,
        nBoxMaxQuality = 0,
        nTrueLevel = 0,
        bBoxAttr = 0,
        szTip = ""
    }
    local nEquipQuality = 0
    local nEquipInv
    if pItem then
        nEquipInv = tSource and tSource.dwX or EquipData.GetEquipInventory(pItem.nSub, pItem.nDetail)

        -- 藏剑重剑对应轻剑装备栏
        if nEquipInv == EQUIPMENT_INVENTORY.BIG_SWORD then
            nEquipInv = EQUIPMENT_INVENTORY.MELEE_WEAPON
        end
        nEquipQuality = pItem.nLevel
        if bItem then
            tInfo.nEquipLevel = pItem.nStrengthLevel or 0
            tInfo.nEquipMaxLevel = GetItemInfo(pItem.dwTabType, pItem.dwIndex).nMaxStrengthLevel or 0
        else -- ItemInfo走这里
            tInfo.nEquipLevel = 0
            tInfo.nEquipMaxLevel = pItem.nMaxStrengthLevel or 0
        end
    end

    local pPlayer = GetSourcePlayer(tSource)
    if pPlayer and nEquipInv then
        -- 藏剑重剑对应轻剑装备栏
        if nEquipInv == EQUIPMENT_INVENTORY.BIG_SWORD then
            nEquipInv = EQUIPMENT_INVENTORY.MELEE_WEAPON
        end
        local nBoxLevel, nBoxQuality = pPlayer.GetEquipBoxStrength(nEquipInv)
        tInfo.nBoxLevel = nBoxLevel or 0
        tInfo.nBoxQuality = nBoxQuality or 0
        tInfo.nBoxMaxLevel, tInfo.nBoxMaxQuality = GetEquipBoxMaxStrengthInfo(nEquipInv)

        if nEquipQuality <= tInfo.nBoxQuality then              -- 检查品质等级
            if tInfo.nBoxLevel >= tInfo.nEquipLevel then        -- 检查装备栏等级
                if tInfo.nBoxLevel <= tInfo.nEquipMaxLevel then -- 检查装备等级上限
                    tInfo.nTrueLevel = tInfo.nBoxLevel
                    tInfo.bBoxAttr = true
                else                                            -- 装备栏等级溢出
                    tInfo.nTrueLevel = tInfo.nEquipMaxLevel
                    tInfo.bBoxAttr = true
                    tInfo.szTip = g_tStrings.EQUIPBOX_ERROR_LEVEL_HIGH
                end
            else                                                -- 装备栏等级偏低
                tInfo.nTrueLevel = tInfo.nEquipLevel
                tInfo.bBoxAttr = false
                tInfo.szTip = g_tStrings.EQUIPBOX_ERROR_LEVEL_LOW
            end
        else                                                    -- 装备栏品质不足
            tInfo.nTrueLevel = tInfo.nEquipLevel
            tInfo.bBoxAttr = false
            if tInfo.nBoxLevel > 0 then
                tInfo.szTip = g_tStrings.EQUIPBOX_ERROR_QUALITY_LOW
                tInfo.bLowQuality = true
            end
        end
    else                                                        -- 此部位尚未穿戴
        tInfo.nTrueLevel = tInfo.nEquipLevel
        tInfo.bBoxAttr = false
        tInfo.szTip = g_tStrings.EQUIPBOX_ERROR_NO_EQUIP
    end
    return tInfo
end

-- 装备过期提示
-- 装备修理过后 UI_OME_SHOP_RESPOND
-- 有新的装备损坏
function EquipData.UpdateEquipDurability()
    --g_tStrings.tInventoryNameTable[]
	Timer.DelTimer(self, self.nTimerID)

    self.nTimerID = Timer.AddCycle(self, 1, function()
		if not g_pClientPlayer then
			return
		end

		local nMinPos, nMinDurability = nil, 0xffffffff
		for _, nPos in ipairs(Def.EquipInventory) do
			local item = PlayerData.GetPlayerItem(g_pClientPlayer, INVENTORY_INDEX.EQUIP, nPos)
			if item and item.nCurrentDurability < item.nMaxDurability then
				if not nMinPos or nMinDurability > item.nCurrentDurability then
					nMinPos = nPos
					nMinDurability = item.nCurrentDurability
				end
			end
		end

		local szTitle = nil
		if nMinPos then
			szTitle = string.format("%s%s",
					g_tStrings.tInventoryNameTable[nMinPos],
					nMinDurability == 0 and "已损坏" or "即将损坏")
		end
		if self.szLastEquipDurabilityTitle ~= szTitle then
			if szTitle == nil then
				BubbleMsgData.RemoveMsg("EquipDurabilityWarning")
			else
				BubbleMsgData.PushMsgWithType("EquipDurabilityWarning", {
					nBarTime = 0,
					szTitle = szTitle,
					szBarTitle = szTitle,
					szContent = g_tStrings.STR_DURABILITY_BUBBLE,
					szAction = function()
						EquipData.RepairItem()
					end,
					nPosIndex = nMinPos,
				})
			end

			--教学 装备耐久消耗
			FireHelpEvent("OnLossDurability", nMinDurability == 0 and "Damage" or "Warning")
		end
		self.szLastEquipDurabilityTitle = szTitle
	end)
end

function EquipData.RepairItem()
	local player = GetClientPlayer()

	local nPrice = GetRepairAllItemsPrice()
	local tPrice = PackMoney(UIHelper.MoneyToGoldSilverAndCopper(nPrice))
	local szMoney = UIHelper.GetMoneyText(tPrice)
	local szMessage

	local bEnough = MoneyOptCmp(player.GetMoney(), tPrice) > 0
	if bEnough or nPrice == 0 then
		if nPrice > 0 then
			szMessage = "确定用" .. szMoney ..  "修理所有装备吗？"
		else
			szMessage = "确定修理所有装备吗？"
		end
		UIHelper.ShowConfirm(szMessage, function ()
			RepairAllItemsWithoutTips()
		end, nil, true)
	else
		szMessage = "本次修理需要" .. szMoney ..  "，余额不足。"
		local scriptConfirm = UIHelper.ShowConfirm(szMessage, _, _, true)
		scriptConfirm:HideButton("Confirm")
	end
end

function EquipData.GetEquipScore(item, nPlayerID)
	local nBaseScore = item.nBaseScore
	local nStrengthScore = 0
	local nStoneScore = item.nMountsScore
	nPlayerID = nPlayerID or PlayerData.GetPlayerID()

	if nPlayerID then
		local tInfo = EquipData.GetStrength(item, true, { dwPlayerID = nPlayerID })
		nStrengthScore = item.CalculateStrengthScore(tInfo.nTrueLevel, item.nLevel)

		local player = GetPlayer(nPlayerID)
		if player then
			local nEquipInv = EquipData.GetEquipInventory(item.nSub, item.nDetail)
			local dwEnchantID0, nCurrentLevel0, dwEnchantID1, nCurrentLevel1, dwEnchantID2, nCurrentLevel2 = 0, 0, 0, 0, 0, 0
			local dwFEAEnchangeID = GetWeaponFEAEnchantID(nPlayerID, item, bItem)

			dwEnchantID0, nCurrentLevel0, dwEnchantID1, nCurrentLevel1, dwEnchantID2, nCurrentLevel2 = player.GetEquipBoxAllMountDiamondEnchantID(nEquipInv)
			nStoneScore = item.CalculateMountsScore(dwEnchantID0, nCurrentLevel0, dwEnchantID1, nCurrentLevel1, dwEnchantID2, nCurrentLevel2, dwFEAEnchangeID)
		end
	end

	return nBaseScore, nStrengthScore, nStoneScore
end

local _tChangeLevel
function EquipData.EquipMagicChangeLevel()
	if not _tChangeLevel then
		_tChangeLevel = {}

		_tChangeLevel[ 60 ] 	= { level = 1, img_frame = 11, r=184, g=250, b=177} 	-- 一品转化
		_tChangeLevel[ 65 ] 	= { level = 2, img_frame = 8 , r=184, g=250, b=177}  	-- 二品转化
		_tChangeLevel[ 70 ] 	= { level = 3, img_frame = 12, r=134, g=246, b=220} 	-- 三品转化
		_tChangeLevel[ 75 ] 	= { level = 4, img_frame = 16, r=134, g=246, b=220} 	-- 四品转化
		_tChangeLevel[ 80 ] 	= { level = 5, img_frame = 15, r=127, g=178, b=254}	-- 五品转化
		_tChangeLevel[ 85 ] 	= { level = 6, img_frame = 26, r=127, g=178, b=254}	-- 六品转化
		_tChangeLevel[ 90 ] 	= { level = 7, img_frame = 27, r=213, g=117, b=227}	-- 七品转化
		_tChangeLevel[ 95 ] 	= { level = 8, img_frame = 24, r=213, g=117, b=227}	-- 八品转化
		_tChangeLevel[ 100 ] 	= { level = 9, img_frame = 25, r=238, g=157, b=86}	-- 九品转化
	end
	return _tChangeLevel
end

function EquipData.GetEquipMagicChangeLevel(percent)
	local tLevel = EquipData.EquipMagicChangeLevel()
	local min = 100
	local value = 0
	local dst
	for k, v in pairs(tLevel) do
		value = math.abs(percent - k)
		if value < min then
			min = value
			dst = v
		end
	end

	if dst then
		return "ui/Image/UICommon/EquipMagicChange.UITex",dst.img_frame, dst.level, dst.r, dst.g, dst.b
	end
end

function EquipData.GetEquipItemCompaireItem(nEqSubType, nDetailType, nRingPos)
	local player = GetClientPlayer()
	if not player then return end

	local nPos = nil
	if nEqSubType == EQUIPMENT_SUB.MELEE_WEAPON then
		nPos = EQUIPMENT_INVENTORY.MELEE_WEAPON
		if nDetailType == WEAPON_DETAIL.BIG_SWORD then
			nPos = EQUIPMENT_INVENTORY.BIG_SWORD
		end
	elseif nEqSubType == EQUIPMENT_SUB.RANGE_WEAPON then
		nPos = EQUIPMENT_INVENTORY.RANGE_WEAPON
	elseif nEqSubType == EQUIPMENT_SUB.ARROW then
		nPos = EQUIPMENT_INVENTORY.ARROW
	elseif nEqSubType == EQUIPMENT_SUB.CHEST then
		nPos = EQUIPMENT_INVENTORY.CHEST
	elseif nEqSubType == EQUIPMENT_SUB.HELM then
		nPos = EQUIPMENT_INVENTORY.HELM
	elseif nEqSubType == EQUIPMENT_SUB.AMULET then
		nPos = EQUIPMENT_INVENTORY.AMULET
	elseif nEqSubType == EQUIPMENT_SUB.RING then
		if nRingPos then
			return ItemData.GetPlayerItem(player, INVENTORY_INDEX.EQUIP, nRingPos)
		end
		local itemLeft = ItemData.GetPlayerItem(player, INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.LEFT_RING)
        local itemRight = ItemData.GetPlayerItem(player, INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.RIGHT_RING)
		return itemLeft, itemRight
	elseif nEqSubType == EQUIPMENT_SUB.WAIST then
		nPos = EQUIPMENT_INVENTORY.WAIST
	elseif nEqSubType == EQUIPMENT_SUB.PENDANT then
		nPos = EQUIPMENT_INVENTORY.PENDANT
	elseif nEqSubType == EQUIPMENT_SUB.PANTS then
		nPos = EQUIPMENT_INVENTORY.PANTS
	elseif nEqSubType == EQUIPMENT_SUB.BOOTS then
		nPos = EQUIPMENT_INVENTORY.BOOTS
	elseif nEqSubType == EQUIPMENT_SUB.BANGLE then
		nPos = EQUIPMENT_INVENTORY.BANGLE
	elseif nEqSubType == EQUIPMENT_SUB.WAIST_EXTEND then
		--nPos = EQUIPMENT_INVENTORY.WAIST_EXTEND
	elseif nEqSubType == EQUIPMENT_SUB.BACK_EXTEND then
		--nPos = EQUIPMENT_INVENTORY.BACK_EXTEND
	elseif nEqSubType == EQUIPMENT_SUB.HORSE then
		return player.GetEquippedHorse()
	end
	if not nPos then
		return nil
	end
	return ItemData.GetPlayerItem(player, INVENTORY_INDEX.EQUIP, nPos)
end

function EquipData.ChangeSuit(nIndex)
	RemoteCallToServer("OnExchangeEquipBackUp", nIndex - 1)
	APIHelper.SetCanShowEquipScore(true)
end

local FilterSwitchEquipSuitType2EquipType = {
	[1]  = EQUIPMENT_INVENTORY.MELEE_WEAPON,	-- "近身武器"
    [2]  = EQUIPMENT_INVENTORY.BIG_SWORD,    	-- "重兵类"
    [3]  = EQUIPMENT_INVENTORY.RANGE_WEAPON,	-- "远程武器"
    [4]  = EQUIPMENT_INVENTORY.CHEST,       	-- "上衣"
    [5]  = EQUIPMENT_INVENTORY.HELM,        	-- "帽子"
    [6]  = EQUIPMENT_INVENTORY.AMULET,      	-- "项链"
    [7]  = EQUIPMENT_INVENTORY.LEFT_RING,   	-- "戒指·左"
    [8]  = EQUIPMENT_INVENTORY.RIGHT_RING, 		-- "戒指·右"
    [9]  = EQUIPMENT_INVENTORY.WAIST,       	-- "腰带"
    [10] = EQUIPMENT_INVENTORY.PENDANT,     	-- "腰坠"
    [11] = EQUIPMENT_INVENTORY.PANTS,       	-- "下装"
    [12] = EQUIPMENT_INVENTORY.BOOTS,       	-- "鞋子"
    [13] = EQUIPMENT_INVENTORY.BANGLE,      	-- "护腕"
    [14] = EQUIPMENT_INVENTORY.ARROW,      		-- "暗器"
}

function EquipData.SwitchEquip(nSuit)
    if not nSuit then
        return
    end

    local player = GetClientPlayer()
    if not player then
        return
    end

    if player.bFightState then
        TipsHelper.ShowNormalTip(g_tStrings.tItem_Msg[ITEM_RESULT_CODE.PLAYER_IN_FIGHT])
        return
    end

	local nCurSuit = player.GetEquipIDArray(0) + 1
	if nCurSuit == nSuit then
		return
	end

    if (nSuit > 2 and nCurSuit <= 2) or (nSuit <= 2 and nCurSuit > 2) then
        EquipData.ChangeSuit(nSuit)
        return
    end

    local tNilBox = self:GetNilBox()
    local tbConfigs = Storage.SwitchEquipSuit or {}
    if nSuit <= 2 then
		tbConfigs = tbConfigs.tbEquipType1 or {}
	elseif nSuit <= 4 then
		tbConfigs = tbConfigs.tbEquipType2 or {}
	end

    for nEquipType, bValid in pairs(tbConfigs) do
        if #tNilBox == 0 then
			TipsHelper.ShowNormalTip("背包空间不足，共用部位无法替换")
            break
        end

		if bValid then
			local nEquipPos = FilterSwitchEquipSuitType2EquipType[nEquipType]
			local item = player.GetItem(INVENTORY_INDEX.EQUIP, nEquipPos)
			if item then
				self.tbEquipCache = self.tbEquipCache or {}
				self.tbEquipCache[nEquipPos] = { dwBox = tNilBox[1][1], dwX = tNilBox[1][2] }
				ItemData.ExchangeItem(INVENTORY_INDEX.EQUIP, nEquipPos, table.unpack(tNilBox[1]))
				table.remove(tNilBox, 1)
			end
		end
    end

    EquipData.ChangeSuit(nSuit)
end

-- 获取空余背包位置
function EquipData.GetNilBox()
    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

    local tNilBox = {}
    for _, nBox in ipairs(ItemData.BoxSet.Bag) do
        if #tNilBox >= 13 then
            break
        end
        for index = 0, player.GetBoxSize(nBox) - 1 do
            local hItem = player.GetItem(nBox, index)
            if not hItem then
                table.insert(tNilBox, {nBox, index})
            end
            if #tNilBox >= 13 then
                break
            end
        end
    end

    return tNilBox
end

-- 还原缓存的装备
function EquipData.RestoreEquip()
	local tCache = self.tbEquipCache
    if not tCache or table.is_empty(tCache) then
        return
    end
    for k, v in pairs(tCache) do
        ItemData.ExchangeItem(v.dwBox, v.dwX, INVENTORY_INDEX.EQUIP, k)
    end
	self.tbEquipCache = {}
end

-- 获取当前使用的坐骑
function EquipData.GetCurrentRide()
	local player = g_pClientPlayer
	if not player then
		return
	end
	local dwCurEquipBox, dwCurEquipX = player.GetEquippedHorsePos()
	local hItem = player.GetItem(dwCurEquipBox, dwCurEquipX)
	if not hItem then
		return
	end

	return dwCurEquipBox, dwCurEquipX
end