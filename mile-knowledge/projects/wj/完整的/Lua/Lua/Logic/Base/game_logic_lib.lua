-----------------------------------------------------------------------------
-- game logic func extensions
-----------------------------------------------------------------------------
-- 用于注册事件
local tGameLogicEvents = {className = "game_logic_lib"}

--==== bag funs =====================================
local m_tPackageIndex =
{
	INVENTORY_INDEX.PACKAGE,
	INVENTORY_INDEX.PACKAGE1,
	INVENTORY_INDEX.PACKAGE2,
	INVENTORY_INDEX.PACKAGE3,
	INVENTORY_INDEX.PACKAGE4,
	INVENTORY_INDEX.PACKAGE_MIBAO,
	INVENTORY_INDEX.LIMITED_PACKAGE,
}

local m_tBankIndex =
{
	INVENTORY_INDEX.BANK,
	INVENTORY_INDEX.BANK_PACKAGE1,
	INVENTORY_INDEX.BANK_PACKAGE2,
	INVENTORY_INDEX.BANK_PACKAGE3,
	INVENTORY_INDEX.BANK_PACKAGE4,
	INVENTORY_INDEX.BANK_PACKAGE5,
}

-- * 获取背包索引表
 function GetPackageIndex(bClone)
 	if bClone then
 		return clone(m_tPackageIndex)
 	end
	return m_tPackageIndex
end

function GetBannkPackageIndex( ... )
	return m_tBankIndex
end

-- * 是否是背包格子，不包括银行仓库
function IsObjectFromPackage(dwBox)
	local t = GetPackageIndex()
	for _, index in pairs(t) do
		if dwBox == index then
			return true
		end
	end
 	return false
end

-- * 是否是格子，包括背包和银行仓库
function IsObjectFromBag(dwBox)
	if IsObjectFromPackage(dwBox) then
		return true
	end

 	if dwBox == INVENTORY_INDEX.EQUIP then
 		return false
 	elseif dwBox == INVENTORY_INDEX.BANK then
 		return true
 	elseif dwBox == INVENTORY_INDEX.BANK_PACKAGE1 then
 		return true
 	elseif dwBox == INVENTORY_INDEX.BANK_PACKAGE2 then
 		return true
 	elseif dwBox == INVENTORY_INDEX.BANK_PACKAGE3 then
 		return true
 	elseif dwBox == INVENTORY_INDEX.BANK_PACKAGE4 then
 		return true
 	elseif dwBox == INVENTORY_INDEX.BANK_PACKAGE5 then
 		return true
	elseif dwBox == INVENTORY_INDEX.SOLD_LIST then
		return false
	end
 	return false
end

-- * 非固定背包 就是可装备背包。ps:新建号有一个20格的固定背包（INVENTORY_INDEX.PACKAGE），其他都是可装备的
function IsCanEquipPackage(dwBox)
	if dwBox >= INVENTORY_INDEX.PACKAGE1 and dwBox <= INVENTORY_INDEX.PACKAGE_MIBAO then
		return true
	end
end

--==== item funs  =====================================

-- * (观察者模式)枚举穿在身上的装备，把道具传给处理函数
function Task_EquipedItem(func)
	local player = GetClientPlayer()
	local item, finish
	for i = 0, EQUIPMENT_INVENTORY.TOTAL - 1, 1 do
		 item = PlayerData.GetPlayerItem(player, INVENTORY_INDEX.EQUIP, i)
		 if item then
			 finish = func(item)
			 if finish then
			 	return
			 end
		end
    end
end

-- * 是否是装备
function IsEquipment(item)
	return (item.nGenre == ITEM_GENRE.EQUIPMENT)
end

-- * 是否是可装备道具,带有战斗属性的道具（注释排除挂件，小头像等类型）
function IsAttriEquipment(item)
	if (item.nGenre == ITEM_GENRE.EQUIPMENT) and
		item.nSub ~= EQUIPMENT_SUB.WAIST_EXTEND and
		item.nSub ~= EQUIPMENT_SUB.BACK_EXTEND and
		item.nSub ~= EQUIPMENT_SUB.FACE_EXTEND and
		item.nSub ~= EQUIPMENT_SUB.BULLET and
		item.nSub ~= EQUIPMENT_SUB.MINI_AVATAR and
		item.nSub ~= EQUIPMENT_SUB.GLASSES_EXTEND and
		item.nSub ~= EQUIPMENT_SUB.L_GLOVE_EXTEND and
		item.nSub ~= EQUIPMENT_SUB.R_GLOVE_EXTEND and
		item.nSub ~= EQUIPMENT_SUB.NAME_CARD_SKIN and
		item.nSub ~= EQUIPMENT_SUB.PET and
        item.nSub ~= EQUIPMENT_SUB.HEAD_EXTEND then
		return true
	end
end

local function CompareItem(player, item, equipedItem)
    if not equipedItem then
        return true
	elseif player.nLevel < player.nMaxLevel then
		return (item.nEquipScore > equipedItem.nEquipScore)
	else
		return ( (item.nEquipScore > equipedItem.nEquipScore) or
				(item.nLevel > equipedItem.nLevel and item.nQuality >= equipedItem.nQuality) )
	end
end

-- * 当前装备是否是比身上已经装备的更好
function IsBetterEquipment(item, packageId, boxId)
	if item.nGenre ~= ITEM_GENRE.EQUIPMENT or not IsAttriEquipment(item) then
		return
	end

	local specify = false
	local player = GetClientPlayer()
	if not packageId then
		packageId, boxId = ItemData.GetEquipItemEquiped(player, item.nSub, item.nDetail)
	else
		specify = true
	end

	local res = true
	local equipedItem = nil
	if packageId then
		equipedItem = PlayerData.GetPlayerItem(player, packageId, boxId)
	end
	if equipedItem then
		res = CompareItem(player, item, equipedItem)
	end

	if not specify then
		if not res and boxId == EQUIPMENT_INVENTORY.LEFT_RING then
			equipedItem = PlayerData.GetPlayerItem(player, packageId, EQUIPMENT_INVENTORY.RIGHT_RING)
            res = CompareItem(player, item, equipedItem)
		end
	end

	return res
end

function IsBetterHorseByItem(itemL, itemR)
	if not itemL or not itemR then
		return
	end
	if itemL.nQuality == itemR.nQuality then
		return itemL.nLevel > itemR.nLevel
	end

	return itemL.nQuality > itemR.nQuality
end

-- * 该格子的坐骑是否是比当前坐骑的更好
function IsBetterHorse(dwBox, dwX)
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return false
	end

	local hItem = PlayerData.GetPlayerItem(hPlayer, dwBox, dwX)
	if not hItem then
		return
	end
	if hItem.nSub ~= EQUIPMENT_SUB.HORSE then
		return false
	end

	local hHorse = hPlayer.GetEquippedHorse()
	if not hHorse then
		return true
	end

	return IsBetterHorseByItem(hItem, hHorse)
end

-- * 获取当前装备的戒指中比较差的那只的位置
function GetWorstRingPos(player)
	player = player or GetClientPlayer()
	local lRingItem = PlayerData.GetPlayerItem(player, INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.LEFT_RING)
	if not lRingItem then
		return EQUIPMENT_INVENTORY.LEFT_RING
	end

	local rRingItem = PlayerData.GetPlayerItem(player, INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.RIGHT_RING)
	if not rRingItem then
		return EQUIPMENT_INVENTORY.RIGHT_RING
	end

	if IsBetterEquipment(lRingItem, INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.RIGHT_RING) then
		return EQUIPMENT_INVENTORY.RIGHT_RING
	end
	return EQUIPMENT_INVENTORY.LEFT_RING
end

-------------------------------pendent------------------------------------
function IsPendantSub(nSub)
	if GetPendantTypeByEquipSub(nSub) then
		return true
	end

	return false
end

function IsPendantItem(item)
	return IsPendantSub(item.nSub)
end

function IsPendantPetSub(nSub)
	if nSub == EQUIPMENT_SUB.PENDENT_PET then
		return true
	end

	return false
end

function IsPendantPetItem(item)
	return IsPendantPetSub(item.nSub)
end

function IsPendantPetItemByIndex(dwTabType, dwIndex)
	local hItemInfo = GetItemInfo(dwTabType, dwIndex)
	return IsPendantPetItem(hItemInfo)
end

function GetPendantColor(dwTabType, dwIndex)
    local hItemInfo = GetItemInfo(dwTabType, dwIndex)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
    	return
    end
	local nType = GetPendantTypeByEquipSub(hItemInfo.nSub)
    local tColorID = hPlayer.GetSelectedPendentColor(nType)
    return tColorID
end

local _tEquipToPendantType =
{
	[EQUIPMENT_SUB.FACE_EXTEND] = PENDENT_SELECTED_POS.FACE,
	[EQUIPMENT_SUB.BACK_EXTEND] = PENDENT_SELECTED_POS.BACK,
	[EQUIPMENT_SUB.WAIST_EXTEND] = PENDENT_SELECTED_POS.WAIST,
	[EQUIPMENT_SUB.BACK_CLOAK_EXTEND] = PENDENT_SELECTED_POS.BACKCLOAK,
	[EQUIPMENT_SUB.L_SHOULDER_EXTEND] = PENDENT_SELECTED_POS.LSHOULDER,
	[EQUIPMENT_SUB.R_SHOULDER_EXTEND] = PENDENT_SELECTED_POS.RSHOULDER,
	[EQUIPMENT_SUB.BAG_EXTEND] = PENDENT_SELECTED_POS.BAG,
	[EQUIPMENT_SUB.GLASSES_EXTEND] = PENDENT_SELECTED_POS.GLASSES,
	[EQUIPMENT_SUB.L_GLOVE_EXTEND] = PENDENT_SELECTED_POS.LGLOVE,
	[EQUIPMENT_SUB.R_GLOVE_EXTEND] = PENDENT_SELECTED_POS.RGLOVE,
	[EQUIPMENT_SUB.HEAD_EXTEND] = PENDENT_SELECTED_POS.HEAD,
}

function GetPendantTypeByEquipSub(nSubType)
	return _tEquipToPendantType[nSubType]
end

function GetEquipSubByPendantType(nPendantType)
	for nSub, nType in pairs(_tEquipToPendantType) do
		if nPendantType == nType then
			return nSub
		end
	end
end

function DealwithPendantPosToShow(nPendantPos)
	if nPendantPos == PENDENT_SELECTED_POS.HEAD1 or nPendantPos == PENDENT_SELECTED_POS.HEAD2 then
        return PENDENT_SELECTED_POS.HEAD
    end
	return nPendantPos
end

--==== skill funs =======================================


local m_ForceTypeToWeapon =
{
	[FORCE_TYPE.JIANG_HU]	= nil,
	[FORCE_TYPE.SHAO_LIN]	= WEAPON_DETAIL.WAND, 			-- 少林内功=棍类
	[FORCE_TYPE.WAN_HUA]	= WEAPON_DETAIL.PEN, 			-- 万花内功=笔类
	[FORCE_TYPE.TIAN_CE]	= WEAPON_DETAIL.SPEAR, 			-- 天策内功=长兵类
	[FORCE_TYPE.CHUN_YANG]	= WEAPON_DETAIL.SWORD, 			-- 纯阳内功=短兵类
	[FORCE_TYPE.QI_XIU]		= WEAPON_DETAIL.DOUBLE_WEAPON, 	-- 七秀内功 = 双兵类
	[FORCE_TYPE.WU_DU]		= WEAPON_DETAIL.FLUTE, 			-- 五毒内功=笛类
	[FORCE_TYPE.TANG_MEN]	= WEAPON_DETAIL.BOW, 			-- 唐门内功=千机匣
	[FORCE_TYPE.CANG_JIAN]	= WEAPON_DETAIL.SWORD, 			-- 藏剑内功=短兵类,重兵类 WEAPON_DETAIL.BIG_SWORD
	[FORCE_TYPE.GAI_BANG]	= WEAPON_DETAIL.STICK, 			-- 丐帮内功=短棒
	[FORCE_TYPE.MING_JIAO]	= WEAPON_DETAIL.KNIFE, 			-- 明教内功=弯刀
	[FORCE_TYPE.CANG_YUN]	= WEAPON_DETAIL.BLADE_SHIELD, 	-- 苍云内功=刀盾
	[FORCE_TYPE.CHANG_GE]	= WEAPON_DETAIL.HEPTA_CHORD, 	-- 长歌内功=琴
	[FORCE_TYPE.BA_DAO]		= WEAPON_DETAIL.BROAD_SWORD, 	-- 霸刀内功=组合刀
	[FORCE_TYPE.PENG_LAI]	= WEAPON_DETAIL.UMBRELLA, 		-- 蓬莱内功=伞
	[FORCE_TYPE.LING_XUE]   = WEAPON_DETAIL.CHAIN_BLADE,     -- 凌雪内功=链刃
	[FORCE_TYPE.YAN_TIAN]   = WEAPON_DETAIL.SOUL_LAMP,    	-- 衍天内功=魂灯
	[FORCE_TYPE.YAO_ZONG]	= WEAPON_DETAIL.SCROLL,			-- 药宗内功=百草卷
	[FORCE_TYPE.DAO_ZONG]	= WEAPON_DETAIL.MASTER_BLADE,	-- 刀宗内功=横刀
	[FORCE_TYPE.WAN_LING]	= WEAPON_DETAIL.LONGBOW,		-- 万灵内功=弓箭
	[FORCE_TYPE.DUAN_SHI]	= WEAPON_DETAIL.FAN,			-- 段氏内功=扇
	[FORCE_TYPE.WU_XIANG]	= WEAPON_DETAIL.PUPPET,			-- 无相内功=傀儡

	--WEAPON_DETAIL.FIST = 拳腕
	--WEAPON_DETAIL.DART = 弓弦
	--WEAPON_DETAIL.MACH_DART = 机关暗器
	--WEAPON_DETAIL.SLING_SHOT = 投掷
}
-- * 当前装备是否适合当前势力
function GetForceWeaponType(dwForceID)
	if not dwForceID then
		local player = GetClientPlayer()
		if not player then
			return
		end
		dwForceID = player.dwForceID
	end

	return m_ForceTypeToWeapon[dwForceID]
end

local m_SchoolTypeToWeapon =
{
	[SCHOOL_TYPE.JIANG_HU]	= nil,
	[SCHOOL_TYPE.SHAO_LIN]	= WEAPON_DETAIL.WAND, 			-- 少林内功=棍类
	[SCHOOL_TYPE.WAN_HUA]	= WEAPON_DETAIL.PEN, 			-- 万花内功=笔类
	[SCHOOL_TYPE.TIAN_CE]	= WEAPON_DETAIL.SPEAR, 			-- 天策内功=长兵类
	[SCHOOL_TYPE.CHUN_YANG]	= WEAPON_DETAIL.SWORD, 			-- 纯阳内功=短兵类
	[SCHOOL_TYPE.QI_XIU]	= WEAPON_DETAIL.DOUBLE_WEAPON, 	-- 七秀内功 = 双兵类
	[SCHOOL_TYPE.WU_DU]		= WEAPON_DETAIL.FLUTE, 			-- 五毒内功=笛类
	[SCHOOL_TYPE.TANG_MEN]	= WEAPON_DETAIL.BOW, 			-- 唐门内功=千机匣
	[SCHOOL_TYPE.CANG_JIAN_WEN_SHUI] = WEAPON_DETAIL.SWORD, 			-- 藏剑内功=短兵类,重兵类 WEAPON_DETAIL.BIG_SWORD
	[SCHOOL_TYPE.CANG_JIAN_SHAN_JU]	= WEAPON_DETAIL.SWORD, 			-- 藏剑内功=短兵类,重兵类 WEAPON_DETAIL.BIG_SWORD
	[SCHOOL_TYPE.GAI_BANG]	= WEAPON_DETAIL.STICK, 			-- 丐帮内功=短棒
	[SCHOOL_TYPE.MING_JIAO]	= WEAPON_DETAIL.KNIFE, 			-- 明教内功=弯刀
	[SCHOOL_TYPE.CANG_YUN]	= WEAPON_DETAIL.BLADE_SHIELD, 	-- 苍云内功=刀盾
	[SCHOOL_TYPE.CHANG_GE]	= WEAPON_DETAIL.HEPTA_CHORD, 	-- 长歌内功=琴
	[SCHOOL_TYPE.BA_DAO]	= WEAPON_DETAIL.BROAD_SWORD, 	-- 霸刀内功=组合刀
	[SCHOOL_TYPE.PENG_LAI]	= WEAPON_DETAIL.UMBRELLA, 		-- 蓬莱内功=伞
	[SCHOOL_TYPE.LING_XUE]  = WEAPON_DETAIL.CHAIN_BLADE,     -- 凌雪内功=链刃
	[SCHOOL_TYPE.YAN_TIAN]  = WEAPON_DETAIL.SOUL_LAMP,    	-- 衍天内功=魂灯
	[SCHOOL_TYPE.YAO_ZONG]	= WEAPON_DETAIL.SCROLL,			-- 药宗内功=百草卷
	[SCHOOL_TYPE.DAO_ZONG]	= WEAPON_DETAIL.MASTER_BLADE,	-- 刀宗内功=横刀
	[SCHOOL_TYPE.WAN_LING]	= WEAPON_DETAIL.LONGBOW,		-- 万灵内功=弓箭
	[SCHOOL_TYPE.DUAN_SHI]	= WEAPON_DETAIL.FAN,			-- 段氏内功=扇
	[SCHOOL_TYPE.WU_XIANG]	= WEAPON_DETAIL.PUPPET,			-- 无相内功=傀儡
}
-- * 当前装备是否适合当前势力BitOPSchoolID
function GetBitOPSchoolIDWeaponType(dwBitOPSchoolID)
	if not dwBitOPSchoolID then
		local player = GetClientPlayer()
		if not player then
			return
		end
		dwBitOPSchoolID = player.dwBitOPSchoolID
	end

	return m_SchoolTypeToWeapon[dwBitOPSchoolID]
end

local m_MountTypeToWeapon =
{
	[KUNGFU_TYPE.TIAN_CE] = WEAPON_DETAIL.SPEAR, 			-- 天策内功=长兵类
	[KUNGFU_TYPE.WAN_HUA] = WEAPON_DETAIL.PEN, 			-- 万花内功=笔类
	[KUNGFU_TYPE.CHUN_YANG] = WEAPON_DETAIL.SWORD, 			-- 纯阳内功=短兵类
	[KUNGFU_TYPE.QI_XIU] = WEAPON_DETAIL.DOUBLE_WEAPON, 	-- 七秀内功 = 双兵类
	[KUNGFU_TYPE.SHAO_LIN] = WEAPON_DETAIL.WAND, 			-- 少林内功=棍类
	[KUNGFU_TYPE.CANG_JIAN] = WEAPON_DETAIL.SWORD, 			-- 藏剑内功=短兵类,重兵类 WEAPON_DETAIL.BIG_SWORD
	[KUNGFU_TYPE.GAI_BANG] = WEAPON_DETAIL.STICK, 			-- 丐帮内功=短棒
	[KUNGFU_TYPE.MING_JIAO] = WEAPON_DETAIL.KNIFE, 			-- 明教内功=弯刀
	[KUNGFU_TYPE.WU_DU] = WEAPON_DETAIL.FLUTE, 			-- 五毒内功=笛类
	[KUNGFU_TYPE.TANG_MEN] = WEAPON_DETAIL.BOW,  			-- 唐门内功=千机匣
	[KUNGFU_TYPE.CANG_YUN] = WEAPON_DETAIL.BLADE_SHIELD, 	-- 苍云内功=刀盾
	[KUNGFU_TYPE.CHANG_GE] = WEAPON_DETAIL.HEPTA_CHORD, 	-- 长歌内功=琴
	[KUNGFU_TYPE.BA_DAO]	= WEAPON_DETAIL.BROAD_SWORD, 	-- 霸刀内功=组合刀
	[KUNGFU_TYPE.PENG_LAI]	= WEAPON_DETAIL.UMBRELLA, 		-- 蓬莱内功=伞
	[KUNGFU_TYPE.LING_XUE]  = WEAPON_DETAIL.CHAIN_BLADE,     -- 凌雪内功=链刃
	[KUNGFU_TYPE.YAN_TIAN]   = WEAPON_DETAIL.SOUL_LAMP,    	-- 衍天内功=魂灯
	[KUNGFU_TYPE.YAO_ZONG]   = WEAPON_DETAIL.SCROLL, 		-- 药宗内功=百草卷
	[KUNGFU_TYPE.DAO_ZONG]   = WEAPON_DETAIL.MASTER_BLADE, 	-- 刀宗内功=横刀
	[KUNGFU_TYPE.WAN_LING]	= WEAPON_DETAIL.LONGBOW,		-- 万灵山庄内功=弓箭
	[KUNGFU_TYPE.DUAN_SHI]  = WEAPON_DETAIL.FAN,			-- 段氏内功=扇
	[KUNGFU_TYPE.WU_XIANG]	= WEAPON_DETAIL.PUPPET,			-- 无相内功=傀儡

	--WEAPON_DETAIL.FIST = 拳腕
	--WEAPON_DETAIL.DART = 弓弦
	--WEAPON_DETAIL.MACH_DART = 机关暗器
	--WEAPON_DETAIL.SLING_SHOT = 投掷
}

--是否是DPS
function KungfuMount_IsDPS(dwKungfuMountID)
	if dwKungfuMountID == 10080 or --云裳心经
		dwKungfuMountID == 10176 or --补天诀
		dwKungfuMountID == 10028 or --离经易道
		dwKungfuMountID == 10448 then --相知
		return false
	else
		return true
	end
end

-- * 是否是近战内功
function Kungfu_IsJinZhan(mountType, skillId)
	if mountType == KUNGFU_TYPE.TIAN_CE or
	   mountType == KUNGFU_TYPE.SHAO_LIN or
	   mountType == KUNGFU_TYPE.CANG_JIAN or
	   mountType == KUNGFU_TYPE.GAI_BANG or
	   mountType == KUNGFU_TYPE.MING_JIAO or
	   mountType == KUNGFU_TYPE.BA_DAO or
	   mountType == KUNGFU_TYPE.CANG_YUN or
	   mountType == KUNGFU_TYPE.DAO_ZONG then
	   return true
	elseif mountType == KUNGFU_TYPE.CHUN_YANG and skillId == 10015 then
		return true
	end

	return false
end

-- * 获取玩家主武器类型
function GetPlayerWeaponType(player)
	player = player or GetClientPlayer()

	local item = PlayerData.GetPlayerItem(player, INVENTORY_INDEX.EQUIP, EQUIPMENT_SUB.MELEE_WEAPON)
	if item then
		return item.nDetail
	end
end

local m_recommentId
local m_data
-- * 当前装备是否适合当前内功
function IsItemFitKungfu(itemInfo, kungfu)
	if itemInfo.nSub == EQUIPMENT_SUB.MELEE_WEAPON then
		local player = GetClientPlayer()
		local skill  = kungfu or player.GetActualKungfuMount()
		if not skill then
			return false
		end
		if itemInfo.nDetail == WEAPON_DETAIL.BIG_SWORD and skill.dwMountType == 6 then
			return true
		end

		if (m_MountTypeToWeapon[skill.dwMountType] ~= itemInfo.nDetail) then
			return false
		end

		if not itemInfo.nRecommendID or itemInfo.nRecommendID == 0 then
			return true
		end
	end

	if not itemInfo.nRecommendID then
		return
	end
	if m_recommentId ~= itemInfo.nRecommendID then
		m_recommentId = itemInfo.nRecommendID
		m_data = g_tTable.EquipRecommend:Search(m_recommentId)
		if not m_data then
			return
		end
		m_data = string.split(m_data.kungfu_ids, "|")
	end

	if not m_data or not m_data[1] then
		return
	end

	if m_data[1] == "0" then
		return true
	end

	local player = GetClientPlayer()
	local skill  = kungfu or player.GetActualKungfuMount()
	if not skill then
		return false
	end
	for _, v in pairs(m_data) do
		if tonumber(v) == ShopData.GetHDKungfuID(skill.dwSkillID) then
			return true
		end
	end
end

local m_PendentTypeToPos =
{
	[KPENDENT_TYPE.WAIST]		= PENDENT_SELECTED_POS.WAIST,
	[KPENDENT_TYPE.BACK]		= PENDENT_SELECTED_POS.BACK,
	[KPENDENT_TYPE.FACE]		= PENDENT_SELECTED_POS.FACE,
	[KPENDENT_TYPE.LSHOULDER]	= PENDENT_SELECTED_POS.LSHOULDER,
	[KPENDENT_TYPE.RSHOULDER]	= PENDENT_SELECTED_POS.RSHOULDER,
	[KPENDENT_TYPE.BACKCLOAK]	= PENDENT_SELECTED_POS.BACKCLOAK,
	[KPENDENT_TYPE.BAG]			= PENDENT_SELECTED_POS.BAG,
	[KPENDENT_TYPE.GLASSES]		= PENDENT_SELECTED_POS.GLASSES,
	[KPENDENT_TYPE.LGLOVE]		= PENDENT_SELECTED_POS.LGLOVE,
	[KPENDENT_TYPE.RGLOVE]		= PENDENT_SELECTED_POS.RGLOVE,
	[KPENDENT_TYPE.HEAD]		= PENDENT_SELECTED_POS.HEAD,
}
-- * KPENDENT_TYPE转为PENDENT_SELECTED_POS
function GetPendentPos(nPendentType)
	return m_PendentTypeToPos[nPendentType]
end

function IsPendantHeadType(nPendentType)
	for _, nType in pairs(PENDENT_HEAD_TYPE) do
		if nType == nPendentType then
			return true
		end
	end
end

function IsItemFitByCamp(hItemInfo, nCamp)
	if not nCamp then
		nCamp = GetClientPlayer().nCamp
	end
    if nCamp == -1 then --全部
        return true
    elseif not hItemInfo.bCanNeutralCampUse and not hItemInfo.bCanGoodCampUse and not hItemInfo.bCanEvilCampUse then
        return false;
    elseif nCamp == CAMP.NEUTRAL and hItemInfo.bCanNeutralCampUse then -- 中立
        return true
    elseif nCamp == CAMP.GOOD and hItemInfo.bCanGoodCampUse then -- 浩气
        return true
    elseif nCamp == CAMP.EVIL and hItemInfo.bCanEvilCampUse then -- 恶人
        return true
    end
    return false
end

function IsItemFitPlayerForce(itemInfo)
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end
	local t = g_tTable.EquipRecommend:Search(itemInfo.nRecommendID)
	if t and t.szDesc and t.szDesc ~= "" then
		for _, v in ipairs(SplitString(t.kungfu_ids, "|")) do
			local dwKungfuID = tonumber(v)
			if dwKungfuID then
				if dwKungfuID == 0 then
					return true
				end
				local dwForceID = Kungfu_GetType(dwKungfuID)
				return dwForceID == hPlayer.dwForceID
			end
		end
	end
	return false
end

-- * 当前道具是否满足装备要求：包括身法，体型，门派，性别，等级，根骨，力量，体质
function IsSafisfyEquipRequire(item, is_item, player)
	player = player or GetClientPlayer()

	local requireAttrib = item.GetRequireAttrib()
	for k, v in pairs(requireAttrib) do
		if is_item and not player.SatisfyRequire(v.nID, v.nValue1, v.nValue2) then
			return false
		elseif not is_item and not player.SatisfyRequire(v.nID, v.nValue) then
			return false
		end
	end
	return true
end

-- * 获取内功类型
local m_tTypeFlag
function Kungfu_GetType(dwSkillID)
	if not m_tTypeFlag then
		m_tTypeFlag =
		{
			[10002] = FORCE_TYPE.SHAO_LIN,
			[10003] = FORCE_TYPE.SHAO_LIN,

			[10021] = FORCE_TYPE.WAN_HUA,
			[10028] = FORCE_TYPE.WAN_HUA,

			[10026] = FORCE_TYPE.TIAN_CE,
			[10062] = FORCE_TYPE.TIAN_CE,

			[10014] = FORCE_TYPE.CHUN_YANG,
			[10015] = FORCE_TYPE.CHUN_YANG,

			[10080] = FORCE_TYPE.QI_XIU,
			[10081] = FORCE_TYPE.QI_XIU,

			[10175] = FORCE_TYPE.WU_DU,
			[10176] = FORCE_TYPE.WU_DU,

			[10224] = FORCE_TYPE.TANG_MEN,
			[10225] = FORCE_TYPE.TANG_MEN,

			[10144] = FORCE_TYPE.CANG_JIAN,
			[10145] = FORCE_TYPE.CANG_JIAN,

			[10268] = FORCE_TYPE.GAI_BANG,

			[10242] = FORCE_TYPE.MING_JIAO,
			[10243] = FORCE_TYPE.MING_JIAO,

			[10389] = FORCE_TYPE.CANG_YUN,
			[10390] = FORCE_TYPE.CANG_YUN,

			[10447] = FORCE_TYPE.CHANG_GE,
			[10448] = FORCE_TYPE.CHANG_GE,

			[10464] = FORCE_TYPE.BA_DAO,

			[10533] = FORCE_TYPE.PENG_LAI,

			[10585] = FORCE_TYPE.LING_XUE,
			[10615] = FORCE_TYPE.YAN_TIAN,

			[10626] = FORCE_TYPE.YAO_ZONG,
			[10627] = FORCE_TYPE.YAO_ZONG,

			[10698] = FORCE_TYPE.DAO_ZONG,

			[10756] = FORCE_TYPE.WAN_LING,

			[10786] = FORCE_TYPE.DUAN_SHI,

			[10821] = FORCE_TYPE.WU_XIANG,
		}
	end

	return m_tTypeFlag[dwSkillID]
end

-- * 获取内功类型
local m_tSchoolTypeFlag
function Kungfu_GetSchoolType(dwSkillID)
	if not m_tSchoolTypeFlag then
		m_tSchoolTypeFlag =
		{
			[10002] = SCHOOL_TYPE.SHAO_LIN,
			[10003] = SCHOOL_TYPE.SHAO_LIN,

			[10021] = SCHOOL_TYPE.WAN_HUA,
			[10028] = SCHOOL_TYPE.WAN_HUA,

			[10026] = SCHOOL_TYPE.TIAN_CE,
			[10062] = SCHOOL_TYPE.TIAN_CE,

			[10014] = SCHOOL_TYPE.CHUN_YANG,
			[10015] = SCHOOL_TYPE.CHUN_YANG,

			[10080] = SCHOOL_TYPE.QI_XIU,
			[10081] = SCHOOL_TYPE.QI_XIU,

			[10175] = SCHOOL_TYPE.WU_DU,
			[10176] = SCHOOL_TYPE.WU_DU,

			[10224] = SCHOOL_TYPE.TANG_MEN,
			[10225] = SCHOOL_TYPE.TANG_MEN,

			[10144] = SCHOOL_TYPE.CANG_JIAN_WEN_SHUI,
			[10145] = SCHOOL_TYPE.CANG_JIAN_SHAN_JU,

			[10268] = SCHOOL_TYPE.GAI_BANG,

			[10242] = SCHOOL_TYPE.MING_JIAO,
			[10243] = SCHOOL_TYPE.MING_JIAO,

			[10389] = SCHOOL_TYPE.CANG_YUN,
			[10390] = SCHOOL_TYPE.CANG_YUN,

			[10447] = SCHOOL_TYPE.CHANG_GE,
			[10448] = SCHOOL_TYPE.CHANG_GE,

			[10464] = SCHOOL_TYPE.BA_DAO,

			[10533] = SCHOOL_TYPE.PENG_LAI,

			[10585] = SCHOOL_TYPE.LING_XUE,
			[10615] = SCHOOL_TYPE.YAN_TIAN,

			[10626] = SCHOOL_TYPE.YAO_ZONG,
			[10627] = SCHOOL_TYPE.YAO_ZONG,

			[10698] = SCHOOL_TYPE.DAO_ZONG,

			[10756] = SCHOOL_TYPE.WAN_LING,

			[10786] = SCHOOL_TYPE.DUAN_SHI,

			[10821] = SCHOOL_TYPE.WU_XIANG,
		}
	end

	return m_tSchoolTypeFlag[dwSkillID]
end

function Kungfu_GetBelongSchoolType(dwSkillID)
	local tKungfu = GetSkill(dwSkillID, 1)
	if not tKungfu then
		return 0
	end
	return tKungfu.dwBelongSchool
end

-- * 获取门派对应心法ID列表
local m_tForceToKungfu
function ForceIDToKungfuIDs(dwForceID)
	if not m_tForceToKungfu then
		m_tForceToKungfu = {
			[FORCE_TYPE.SHAO_LIN] 	= { 10002, 10003, 100069, 100053, },
			[FORCE_TYPE.WAN_HUA] 	= { 10021, 10028, 100408, 100411, },
			[FORCE_TYPE.TIAN_CE] 	= { 10026, 10062, 100406, 100407, },
			[FORCE_TYPE.CHUN_YANG] 	= { 10014, 10015, 100398, 100389, },
			[FORCE_TYPE.QI_XIU] 	= { 10080, 10081, 100409, 100410, },
			[FORCE_TYPE.WU_DU] 		= { 10175, 10176, 100654, 100655, },
			[FORCE_TYPE.TANG_MEN] 	= { 10224, 10225, 101734, 101716, },
			[FORCE_TYPE.CANG_JIAN] 	= { 10144, 10145, 100725, },
			[FORCE_TYPE.GAI_BANG] 	= { 10268, 100651, },
			[FORCE_TYPE.MING_JIAO] 	= { 10242, 10243, 100618,100631, },
			[FORCE_TYPE.CANG_YUN] 	= { 10389, 10390, 101024, 101025, },
			[FORCE_TYPE.CHANG_GE] 	= { 10447, 10448, 101124, 101125, },
			[FORCE_TYPE.BA_DAO] 	= { 10464, 100994, },
			[FORCE_TYPE.PENG_LAI] 	= { 10533, 101090, },
			[FORCE_TYPE.LING_XUE]   = { 10585, 101173, },
			[FORCE_TYPE.YAN_TIAN]   = { 10615, 101450, },
			[FORCE_TYPE.YAO_ZONG]   = { 10626, 10627, 101374, 101355, },
			[FORCE_TYPE.DAO_ZONG]   = { 10698, 101375, },
			[FORCE_TYPE.WAN_LING]   = { 10756},
			[FORCE_TYPE.DUAN_SHI]   = { 10786},
			[FORCE_TYPE.WU_XIANG]   = { 10821},
		}
	end
	return m_tForceToKungfu[dwForceID] or {}
end

--* 流派分页SchoolID
SECOND_SCHOOL_TOTAL = 999

local m_tSecondSchool = {
	[BELONG_SCHOOL_TYPE.WU_XIANG] = 10821, -- schoolid->kungfuid
}

--* 是否是流派School
function IsSecondSchool(dwSchoolID)
	return m_tSecondSchool[dwSchoolID]
end

function GetSecondSchoolByKungfuID(dwMKungfuID)
	for dwSchoolID, dwKungfuID in pairs(m_tSecondSchool) do
		if dwKungfuID == dwMKungfuID then
			return dwSchoolID
		end
	end
end

--* 获取流派心法列表
function GetSecondSchoolList()
	local tKungfuList = {}
	for _, dwKungfuID in pairs(m_tSecondSchool) do
		table.insert(tKungfuList, dwKungfuID)
	end
	return tKungfuList
end

-- * 获取玩家装备的内功类型
function Kungfu_GetPlayerMountType(player)
	player = player or GetClientPlayer()
	local skill  = player.GetActualKungfuMount()
	if not skill then
		return
	end
	local nKungFuID = skill.dwSkillID
	if not TabHelper.IsHDKungfuID(nKungFuID) then
		nKungFuID = TabHelper.GetHDKungfuID(nKungFuID)
	end
	return Kungfu_GetType(nKungFuID)
end

function BagIndexToInventoryIndex(nIndex)
	return INVENTORY_INDEX.PACKAGE + nIndex - 1
end

--* 获取是否还有背包空位
function IsHaveFreeBag()
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end
	local nCount = Bag_GetPacketCount()
	for i = 2, nCount, 1 do
		local nInventoryIndex = BagIndexToInventoryIndex(i)
		local dwSize = hPlayer.GetBoxSize(nInventoryIndex)

		if dwSize == 0 and (i ~= INVENTORY_INDEX.PACKAGE_MIBAO  or hPlayer.CanUseMibaoPackage()) then
			return INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.PACKAGE1 + i - 2
		end
	end
end

--* 是否比当前的背包好
function IsBetterBag(item)
	if not item or item.nGenre ~= ITEM_GENRE.EQUIPMENT or item.nSub ~= EQUIPMENT_SUB.PACKAGE then
		return
	end

	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end

	local itemInfo = GetItemInfo(item.dwTabType, item.dwIndex)
	if itemInfo.nPackageGenerType ~= -1 then --拦截了草药包、书包等花式背包
		return
	end

	local nNewValue = item.nCurrentDurability
	local nCount = #ItemData.BoxSet.Bag
	local nMinSize
	local nBoxX
	for i = 2, nCount, 1 do
		local nInventoryIndex = BagIndexToInventoryIndex(i)
		local dwSize = hPlayer.GetBoxSize(nInventoryIndex)

		if nNewValue > dwSize and (not nMinSize or dwSize < nMinSize) and (i ~= INVENTORY_INDEX.PACKAGE_MIBAO  or hPlayer.CanUseMibaoPackage()) then
			nMinSize = dwSize
			nBoxX = EQUIPMENT_INVENTORY.PACKAGE1 + i - 2
		end
	end
	if nBoxX then
		return INVENTORY_INDEX.EQUIP, nBoxX
	end
end

local PERSON_LABEL =
{
	GOOD_MASTER = 1,-- 好团长
}

-- * 获取个人标签等级
function PersonLabel_GetLevel(count, id)
	local level
	if count == 0 then
		return 1
	end

	if id == PERSON_LABEL.GOOD_MASTER then
		level = 0.5 + math.sqrt( 2 * count - 1.75 )
		level = math.floor(level)
	elseif id == PRAISE_TYPE.PERSONAL_CARD then
		if count <= 100000 then
			level = (count / 10) ^ (1/2)
		else
			level = (count * 10) ^ (1/3)
		end
		level = math.max(math.floor(level), 1)
	else
		if count <= 3826 then
			level = ( math.sqrt( 6 * count - 3.75 ) - 1.5) / 3
		else
			level = math.sqrt(7800 + 4 * count)  / 2 - 26
		end
		level = math.floor(level) + 1
	end

	return level
end

-- * 获取个人标签某等级时需要多少次点赞
function PersonLabel_GetLevelCount(level, id)
	local count
	if id == PERSON_LABEL.GOOD_MASTER then
		count = 0.5 * level ^ 2 - 0.5 * level + 1
	elseif id == PRAISE_TYPE.PERSONAL_CARD then
		if level == 1 then
			return 1
		elseif level <= 100 then
			count = 10 * level ^ 2
		else
			count = 0.1 * level ^ 3
		end
		count = math.floor(count)
	else
		level = level - 1
		if level <= 50 then
			count = 1.5 * level * level  + 1.5 * level + 1
		else
			count = level * level  + 52 * level - 1274
		end
		count = math.floor(count)
	end

	return count
end

local function GetCofValue(player)
	local nCof = 1
	if player.nLevel <= 15 then
		nCof = 50
	elseif player.nLevel <=90 then
		nCof = 4 * player.nLevel -10
	elseif player.nLevel <=95 then
		nCof = 85 * player.nLevel - 7300
	elseif player.nLevel <=100 then
		nCof = 185 * player.nLevel - 16800
	else
		nCof = 205 * player.nLevel - 18800
	end
	return nCof
end

-- * 获取玩家招架值
function GetPlayerParryValue(player)
	player = player or GetClientPlayer()

	local ParryParam = 4.345
	local nCof = GetCofValue(player)
	local value = player.nParryBaseRate + 10000 * player.nParry / (ParryParam * nCof + player.nParry)
	return KeepTwoByteFloat(value / 100)
end

-- * 是否是套装位置
function IsSuitEquipPos(equipPos)
	return ( (equipPos == INVENTORY_INDEX.EQUIP) or
		(equipPos == INVENTORY_INDEX.EQUIP_BACKUP1) or
		(equipPos == INVENTORY_INDEX.EQUIP_BACKUP2) or
		(equipPos == INVENTORY_INDEX.EQUIP_BACKUP3) )
end

-- * 获取套装的逻辑位置
function GetLogicEquipPos(suitIndex)
	local player = GetClientPlayer()
	for i=0, 3, 1 do
		if player.GetEquipIDArray(i) == suitIndex then
			if i == 0 then
				return INVENTORY_INDEX.EQUIP
			else
				return INVENTORY_INDEX["EQUIP_BACKUP"..i]
			end
		end
	end
	return INVENTORY_INDEX.EQUIP
end

-- * 判断否新手玩家组队满了，满了申请是不是团队招募的
function GetFreshMenFinishTeamBuilding()
	if TeamBuilding.ISFreshMen() and GetClientPlayer().IsPartyFull() then
		ApplyTeamPushSingle(GetClientPlayer().dwID)
	end
end

-- * 判断是否新手玩家通过团队招募组满了人
function ISFreshMenFinishByTeamBuilding()
	local hPlayer = GetClientPlayer()
	local tInfo = GetTeamPushInfoSingle(hPlayer.dwID)
	if TeamBuilding.ISFreshMen() --新手
		and hPlayer.IsPartyFull() --组满
			and tInfo then --有发布过招募
		local msg =
		{
			szMessage = g_tStrings.STR_TEAM_BUILD_TEACH,
			szName = "TeamBuildingTeach",
			{ szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() RemoteCallToServer("On_Team_SuccessTeaching") end},
			{ szOption = g_tStrings.STR_HOTKEY_CANCEL},
		}
		MessageBox(msg)
	end
end

-- * 判断没有产出的五彩石不能精炼
function IsColorDiamondCanNotUp(item)
	local tInfo = GetEnchantProduceItemInfo(item.dwEnchantID)
	if not tInfo or tInfo.dwTabType == 0 or tInfo.dwTabIndex == 0 then
		return true
	end
end

-- * Player Talk
function Player_Talk(player, nChannel, szReceiver, tbMsg, bSaveWhisper)
	if bSaveWhisper == nil then
		bSaveWhisper = true
	end

	player = player or g_pClientPlayer

	-- 处理弹幕频道
	local ColourID, FontSize, ShowMode, nType
	if nChannel == PLAYER_TALK_CHANNEL.JJC_BULLET_SCREEN or
	 	nChannel == PLAYER_TALK_CHANNEL.CAMP_FIGHT_BULLET_SCREEN or
		nChannel == PLAYER_TALK_CHANNEL.DUNGEON_BULLET_SCREEN or
		ChatData.bBulletDebug then
		ColourID = Storage.Chat_Bullet.nColorID
		FontSize = Storage.Chat_Bullet.nFontSize
		ShowMode = Storage.Chat_Bullet.nShowMode
		if not ColourID or not FontSize or not ShowMode then
			OutputMessage("MSG_SYS", g_tStrings.tNotPushDanmaku[0])
			return
		end

		nType = nChannel
	end

	if player.CanUseNewChatSystem(nChannel) then
		return player.PushChat(nChannel, szReceiver, ColourID, FontSize, ShowMode, nType, bSaveWhisper, tbMsg)
	end
end



-- * 申请副本进度
function GetMapCopyProgress()
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end
	local tData = hPlayer.GetMapCopyProgress()
	FireUIEvent("ON_APPLY_PLAYER_SAVED_COPY_RESPOND", tData)
end

function Player_IsBuffExist(dwBuffID, player, dwBuffLevel)
	if not player then
		player = GetClientPlayer()
	end

	if not dwBuffID then
		return
	end

	dwBuffLevel = dwBuffLevel or 0
	return player.IsHaveBuff(dwBuffID, dwBuffLevel)
end

function Player_GetBuff(dwBuffID)
	local player = GetClientPlayer()
	if not player then
		return
	end
	local nCount = player.GetBuffCount()
	if nCount == 0 or not dwBuffID then
		return
	end

	local buff = {}
	for k=1, nCount, 1 do
		Buffer_Get(player, k - 1, buff)
		if buff.dwID == dwBuffID then
			return buff
		end
	end
end

-- * 判断是否敌对， 同样的2个ID，参数位置不一样结果会不一样
function IsEnemyEx(dwPeerID, dwSelfID)
	local src = dwPeerID
	local dest = dwSelfID

	if IsPlayer(dwPeerID) and IsPlayer(dwSelfID) then
		src = dwSelfID
		dest = dwPeerID
	end

	return IsEnemy(src, dest)
end

function IsBelongToForce(dwForceID, dwSkillID)
    local tKungFu = Table_GetSkillSchoolKungfu(dwForceID)
    if not tKungFu then
        return false
    end

    for _, dwKungfuID in ipairs(tKungFu) do
        if dwSkillID == dwKungfuID then
            return true
        end
    end

    return false
end

function IsCanForceEndVehicle(dwObjType, dwObjID)
	if (dwObjType == TARGET_EX.VEHICLE and dwObjID == UI_GetClientPlayerID() and CanForceEndRoadTrack()) then
		return true
	end
end


function IsForceRequired(player, item, bItem)
	local aValue

	local requireAttrib = item.GetRequireAttrib()
	for k, v in pairs(requireAttrib) do
		nFont = 106
		if bItem then
			aValue = { v.nValue1, v.nValue2 }
		else
			aValue = { v.nValue }
		end

		if v.nID == 6 then -- 需求的是门派
			if player and not player.SatisfyRequire(v.nID, unpack(aValue)) then
				return false
			end
		end
	end
	return true
end

--==== fliter some event ===============================================================
local m_tShieldBuff =
{
	[4964]	= "Boss", -- 特殊屏蔽 活动用
	[6007]	= "Boss", -- 特殊屏蔽 活动用
	[8840]	= "Boss", -- 特殊屏蔽 活动用
	[791]	= "TongArena", -- 帮会擂台 进行中bu
	[10970]	= "MsgBox", -- 专门屏蔽各类操作
	[11638]	= "Boss", -- 郭萌萌直播屏蔽骚扰
}

function BossCondition_0(player)
	player = player or GetClientPlayer()

	local nCount = player.GetBuffCount()
	if nCount == 0 then
		return
	end

	local dwID
	for k=1, nCount, 1 do
		dwID = player.GetBuff(k - 1)
		if m_tShieldBuff[dwID] == "Boss" then
			if dwID == 8840 then
				return true, true
			end
			return true
		end
	end

	return false
end

function CheckFliterBuff(player)
	player = player or GetClientPlayer()
	local nCount = player.GetBuffCount()
	if nCount == 0 then
		return
	end

	local dwID
	for k=1, nCount, 1 do
		dwID = player.GetBuff(k - 1)
		if m_tShieldBuff[dwID] then
			return true
		end
	end

	return false
end

local m_tFilter = {}
--  * enable/disable fliter the event
function EnableFilterOperate(event, enable)
	m_tFilter[event] = enable
end

function ResetFilterOperate()
    m_tFilter = {}
end

function IsFilterOperateEnable(event)
	return m_tFilter[event]
end

function IsFilterOperate(event, nParam)
	if m_tFilter[event] then
		return true
	end

	if event == "TRADING_INVITE" 			or event == "INVITE_ARENA_CORPS" 		or
	   event == "INVITE_JOIN_TONG_REQUEST" 	or event == "PARTY_INVITE_REQUEST" 		or
	   event == "STR_PLAYER_APPLY_PARTY" 	or event == "PLAYER_BE_ADD_FELLOWSHIP" 	or
	   event == "OnQueryApprentice" 		or event == "OnQueryMentor" 			or
	   event == "OnQueryDirectMentor"  		or event == "EMOTION_ACTION_REQUEST" 	or
	   event == "HAS_BE_ADD_FOE"            or event == "PLAYER_APPLYDUEL"
	   then
	  	if CheckFliterBuff() then
			return true
		end
	end

	return false
end
--==== end ===============================================================

do
local function GetSkillLevel(...)
	return 0
end
function GetTargetHandle(dwType, dwID)
	local hTarget = nil
	local dwFullyID = dwID
	if dwType == TARGET.PLAYER then
		hTarget = GetPlayer(dwID)
	elseif dwType == TARGET.NPC then
		if IsSimplePlayer(dwID) then
			hTarget = GetSimplePlayerNpc(dwID)
			if hTarget then
				local hEmployer = GetPlayer(hTarget.dwEmployer)
				local hNpc = GetNpcSimplePlayerInfo(dwID)

				if hEmployer then
					hTarget.bCampFlag 		= hEmployer.bCampFlag
					hTarget.bFightState 	= hEmployer.bFightState
				else
					hTarget.bCampFlag 		= hNpc.bCampFlag
					hTarget.bFightState 	= hNpc.bFightState
				end
				hEmployer 				= hEmployer or {}
				hTarget.dwID  			= dwID
				hTarget.nLevel 			= hEmployer.nLevel or hNpc.nLevel
				hTarget.nCamp 			= hEmployer.nCamp or hNpc.nCamp
				hTarget.dwMiniAvatarID 	= hNpc.dwMiniAvatarID or hEmployer.dwMiniAvatarID
				hTarget.dwForceID 		= hEmployer.dwForceID or hNpc.dwForceID
				hTarget.dwMountKungfuID = hNpc.dwMountKungfuID
				hTarget.szName 			= hEmployer.szName or hNpc.szName
				hTarget.nRoleType		= hEmployer.nRoleType or hNpc.nRoleType
				hTarget.f64MaxLife      = hEmployer.fMaxLife64 or hNpc.fMaxLife64
				hTarget.f64CurrentLife  = hEmployer.fCurrentLife64 or hNpc.fCurrentLife64

				local dwForceID = hTarget.dwForceID
				local dwMountKungfuID = hTarget.dwMountKungfuID
				hTarget.GetKungfuMount = function()
					local t = {
						dwBelongSchool = GetSchoolByForce(dwForceID),
						dwMountType = GetSkill(dwMountKungfuID, 1).dwMountType,
						dwSkillID = dwMountKungfuID,
						dwLevel = 1,
					}
					return t
				end
				hTarget.GetSchoolList = function()
					local t = {
					[1] = GetSchoolByForce(dwForceID),
					}
					return t
				end
				hTarget.GetAllMountKungfu = function()
					return {}
				end
				hTarget.nCurrentRage = 100
				hTarget.nMaxRage = 100
				hTarget.nPoseState = POSE_TYPE.SWORD --苍云的战斗姿态

				hTarget.nCurrentEnergy = 100
				hTarget.nMaxEnergy = 100
				--MJ
				hTarget.nCurrentSunEnergy = 100
				hTarget.nMaxSunEnergy = 100
				hTarget.nCurrentMoonEnergy = 100
				hTarget.nMaxMoonEnergy = 100
				hTarget.nSunPowerValue = 0
				hTarget.nMoonPowerValue = 0
				hTarget.nMaxLifeCount   = 0

				hTarget.nAccumulateValue = 5
				hTarget.GetSkillLevel = GetSkillLevel
				dwFullyID = hTarget.dwEmployer
			end
		else
			hTarget = GetNpc(dwID)
		end
	elseif dwType == TARGET.DOODAD then
		hTarget = GetDoodad(dwID)
	end
	return hTarget, dwFullyID
end
end

function GetTargetMaxLife(dwType, dwID)
	local hTarget = GetTargetHandle(dwType, dwID)
	local fMaxLife = 0
	if dwType == TARGET.NPC then
		local hNPC = GetNpcTemplate(hTarget.dwTemplateID)
		local fRecoverHP = Table_GetNpcRecoverHP(hTarget.dwTemplateID)
		if hNPC and fRecoverHP and fRecoverHP > 0 then
			fMaxLife = hNPC.fMaxLife64
		else
			fMaxLife = hTarget.fMaxLife64
		end
	else
		fMaxLife = hTarget.fMaxLife64
	end
	return fMaxLife
end
do
-- --------------------------------------------------
local l_bGlobalTopIntelligenceLife = true
--智能显示血条
--功能非战斗时不显示自己、其他玩家、NPC的血条，战斗中自动显示自己和全部敌对目标的血条。
--与现有的显示自己、其他玩家、NPC的血条效果共存。
--如：只勾选了智能显示血条和显示自己血条，则一直显示玩家自己的血条，并在进入战斗后显示敌对目标的血条。
function GetGlobalTopIntelligenceLife()
	return l_bGlobalTopIntelligenceLife
end

function GetGameSettingMaxVal(tSetting)
	if tSetting.nMaxVal then
		if IsNumber(tSetting.nMaxVal) then
			return tSetting.nMaxVal
		elseif IsTable(tSetting.nMaxVal) and tSetting.nMaxVal[QualityMgr.GetCurQualityType()] then
			return tSetting.nMaxVal[QualityMgr.GetCurQualityType()]
		end
	end
	LOG.ERROR("GetGameSettingMaxVal Failed %s ",tSetting.szName)
end

local function GetSettingCellInfo(nMainCategory, nSubCategory, szKey)
	local tList = UIGameSettingConfigTab[nMainCategory] ~= nil and UIGameSettingConfigTab[nMainCategory][nSubCategory]
	if tList then
		for _,tCellInfo in ipairs(tList) do
			if tCellInfo.szName == szKey then
				return tCellInfo
			end
		end
	end
end

function GetGameSetting(nMainCategory, nSubCategory, szKey)
	local tCellInfo = GetSettingCellInfo(nMainCategory, nSubCategory, szKey)
	if tCellInfo and tCellInfo.szKey then
		return GameSettingData.GetNewValue(tCellInfo.szKey)
	end

	if UISettingStoreTab[nMainCategory] ~= nil and UISettingStoreTab[nMainCategory][nSubCategory] ~= nil and
			UISettingStoreTab[nMainCategory][nSubCategory][szKey] ~= nil then
		return UISettingStoreTab[nMainCategory][nSubCategory][szKey]
	else
		LOG.ERROR("GetGameSetting Failed %s %s %s",nMainCategory,nSubCategory,szKey)
	end
end

function SetGameSetting(nMainCategory, nSubCategory, szKey, tVal)
	local tCellInfo = GetSettingCellInfo(nMainCategory, nSubCategory, szKey)
	if tCellInfo and tCellInfo.szKey then
		GameSettingData.StoreNewValue(tCellInfo.szKey, tVal)
		return
	end

	if UISettingStoreTab[nMainCategory] ~= nil and UISettingStoreTab[nMainCategory][nSubCategory] ~= nil and tVal~= nil then
		UISettingStoreTab[nMainCategory][nSubCategory][szKey] = tVal
	else
		LOG.ERROR("SetGameSetting Failed %s %s %s",nMainCategory,nSubCategory,szKey)
	end
end

function GetGameSoundSetting(nSoundType)
	local tInfo = GameSettingData.GetNewValue(SoundStorageKeyDict[nSoundType])
	if tInfo ~= nil then
		return tInfo
	else
		LOG.ERROR("GetGameSoundSetting Failed %s",nSoundType)
	end
end

function SetGlobalTopIntelligenceLife(bShow)
	Global_SetSmartLifeDisplayEnable(bShow)
end

function SetPlayerBirdFloatTitle(bShow)
	if bShow then
		rlcmd("show player bird float title")
	else
		rlcmd("hide player bird float title")
	end
end

function ShowCharacterDistance(bShow)
	if bShow then
		rlcmd("enable NPC name postfix dist 1")
		rlcmd("enable remote player name postfix dist 1")
	else
		rlcmd("enable NPC name postfix dist 0")
		rlcmd("enable remote player name postfix dist 0")
	end
end

function SetScreenVisibleCount() -- 同屏玩家、同屏NPC
	local nRenderNpcLimit = GameSettingData.GetNewValue(UISettingKey.NPCsOnScreen)
	local nRenderLimit = GameSettingData.GetNewValue(UISettingKey.PlayersOnScreen)
	rlcmd("set visible " .. nRenderNpcLimit .. " " .. nRenderLimit)
end

function SetSelfTopPriority(bTop)
	if bTop then
		rlcmd("force top local character 1")
	else
		rlcmd("force top local character 0")
	end
end

function SetOperationMode(nModeID)
	if nModeID == nil then
		local tSetting = GameSettingData.GetNewValue(UISettingKey.CameraMode)
		if tSetting.szDec == GameSettingType.OperationMode.Traditional.szDec then
			nModeID = CLASSICAL_MODE
		elseif tSetting.szDec == GameSettingType.OperationMode.Joystick.szDec then
			nModeID = JOYSTICK_MODE
		else
			nModeID = LOCKED_MODE
		end
	end

	if nModeID == CLASSICAL_MODE then
		rlcmd("set character camera lock ctrl 0")
		rlcmd("enable adjust camera by move 1")
	elseif nModeID == JOYSTICK_MODE then
		rlcmd("set character camera lock ctrl 0")
		rlcmd("enable adjust camera by move 0")
	elseif nModeID == LOCKED_MODE then
		rlcmd("enable adjust camera by move 0")
		rlcmd("set character camera lock ctrl 1 -30")
	end
end

function SetModelTopBarSize(tTempData)
	local tOrigin = tTempData or Storage.HeadTopBarSetting
	local nFontLevel = tOrigin.nFontLevel
	if not nFontLevel or not IsNumber(nFontLevel) or nFontLevel < 20 or nFontLevel > 40 then
		tOrigin.nFontLevel = 28
	end
	local nHealthBarSize = tOrigin.nHealthBarSize or -1
	local nBorderWidth = tOrigin.nBorderWidth or -1
	local nSpan = tOrigin.nSpan or -1
	local nBorderColorRGB = tOrigin.nBorderColorRGB or -1

	KG3DEngine.SetCaptionLevel(nFontLevel, nHealthBarSize, nBorderWidth, nSpan, nBorderColorRGB)
end

function ShowEmployeeCaption(szType, bShow)
	local szCmd = "enable employee <D0> <D1>"
	local nVisible
	if bShow then
		nVisible = 1
	else
		nVisible = 0
	end
	szCmd = FormatString(szCmd, szType, nVisible)
	rlcmd(szCmd)
end

function UpdateSfxIntensity()
	local fMyEffectLight = GameSettingData.GetNewValue(UISettingKey.SelfEffectBrightness)
	local fMyEffectAlpha = GameSettingData.GetNewValue(UISettingKey.SelfEffectTransparency)
	local fOtherEffectLight = GameSettingData.GetNewValue(UISettingKey.OtherEffectBrightness)
	local fOtherEffectAlpha = GameSettingData.GetNewValue(UISettingKey.OtherEffectTransparency)
	rlcmd("set sfx intensity " .. fMyEffectLight .. " " ..
			fMyEffectAlpha .. " " .. fOtherEffectLight .. " " .. fOtherEffectAlpha)
end

local lc_bSyncTeamFightData = true
function IsSyncTeamFightData()
	return lc_bSyncTeamFightData
end

function SetSyncTeamFightDataState(bState)
	lc_bSyncTeamFightData = bState
end

local function OnPartyMsgNotify()
	if arg0 == PARTY_NOTIFY_CODE.PNC_PARTY_JOINED or
	   arg0 == PARTY_NOTIFY_CODE.PNC_PARTY_CREATED then
		SetTeamSkillEffectSyncOption(true)
		lc_bSyncTeamFightData = true
	end
end
--RegisterEvent("PARTY_MESSAGE_NOTIFY", OnPartyMsgNotify)

local function OnFirstLoadingEnd()
	RLEnv.ApplyDefaultVisible()
	SetTeamSkillEffectSyncOption(lc_bSyncTeamFightData)
	OnInitCaptionIconVisible()

	--TODO: 强制设置智能显示头顶血条
	SetGlobalTopIntelligenceLife(true)
end
Event.Reg(tGameLogicEvents, "LOADING_END", OnFirstLoadingEnd, true)
end

function IsDianXinArea()
	local COIN_COUNTER_AREA = 38
	local nValue = GetGlobalCounterValue(COIN_COUNTER_AREA)
	return nValue == 1
end

local tActivityState = {}

--[[
	IsActivityOn() 是根据活动时间判
	UI_IsActivityOn() 会根据活动状态判
	二者都由逻辑数据状态决定，区别在于前者走配置表，后者由配置表+策划事件通知组成的
--]]
function UI_IsActivityOn(dwActivityID)
	return tActivityState[dwActivityID]
end

local function OnActivityStateChanged(dwActivityID, bOpen)
	tActivityState[dwActivityID] = bOpen
	FireUIEvent("LUA_ON_ACTIVITY_STATE_CHANGED_NOTIFY", dwActivityID, bOpen)
end

-- 其他脚本中最好不响应这个事件，只响应 LUA_ON_ACTIVITY_STATE_CHANGED_NOTIFY
Event.Reg(tGameLogicEvents, "ON_ACTIVITY_STATE_CHANGED_NOTIFY", OnActivityStateChanged)
Event.Reg(tGameLogicEvents, "UI_LUA_RESET", function ()
	tActivityState = {}
end)

function GetPlayerVigorAndStamina(hPlayer)
	if not hPlayer then
		return 0
	end
	return hPlayer.nVigor + hPlayer.nCurrentStamina
end


local GET_GIFT_CD_TIME = 1000 * 5
local nLastTime = nil
function GetGameGift(dwGiftID, szOwnerName)
	if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TALK, "GameGift") then
		return
	end

	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end

	if hPlayer.nLevel < 100 then
		OutputMessage("MSG_SYS", g_tStrings.STR_RED_GIFT_GET_ERROR)
		OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_RED_GIFT_GET_ERROR)
		return
	end

	local nTime = GetTickCount()
	if nLastTime and nTime - nLastTime < GET_GIFT_CD_TIME then
		OutputMessage("MSG_SYS", g_tStrings.STR_HAVE_CD)
		OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_HAVE_CD)
		return
	end

	nLastTime = nTime
	OutputMessage("MSG_SYS", g_tStrings.STR_RED_GIFT_GET_INFO)
	OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_RED_GIFT_GET_INFO)
	--RemoteCallToServer("On_Gift_GetGiftRequest", dwGiftID, szOwnerName)
	hPlayer.GetChatGiftRequest(dwGiftID, szOwnerName)
end

local function OnGetGameGiftNotify()
	local szMsg = g_tStrings.tRedGiftNotify[arg0]
	OutputMessage("MSG_SYS", szMsg)
	OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)

end
--RegisterEvent("ON_CHAT_GIFT_GET_CODE_NOTIFY", OnGetGameGiftNotify)

local function OnPlayerLeaveGame()
    ZZQ_Stop()
	if PerformanceCollect ~= nil then
		PerformanceCollect.Close()
	end
end

--RegisterEvent("PLAYER_LEAVE_GAME", OnPlayerLeaveGame)

function GetMapParams_UIEx(dwMapID)
	local hHomeland = GetHomelandMgr()
	if not hHomeland then
		return GetMapParams(dwMapID)
	end
	local bPrivateHome = hHomeland.IsPrivateHomeMap(dwMapID)
	if not bPrivateHome then
		return GetMapParams(dwMapID)
	end

	local tPrivateHomeInfo = hHomeland.GetCurPrivateHomeInfo()
	if not tPrivateHomeInfo then
		return GetMapParams(dwMapID)
	end

	local uMapSkinID = hHomeland.GetMapSkinID(dwMapID, tPrivateHomeInfo.dwSkinID)
	if tPrivateHomeInfo.dwSkinID == 0 then
		return GetMapParams(dwMapID)
	end

	local tSkinConfig= hHomeland.GetPrivateHomeSkinConfig(uMapSkinID)
	if not tSkinConfig then
		return GetMapParams(dwMapID)
	end
	return tSkinConfig.szResourceDir, select(2, GetMapParams(dwMapID))
end

function GetMapID_UIEx(dwMapID)
	local hHomeland = GetHomelandMgr()
	if not hHomeland then
		return dwMapID
	end
	local bPrivateHome = hHomeland.IsPrivateHomeMap(dwMapID)
	if not bPrivateHome then
		return dwMapID
	end

	local tPrivateHomeInfo = hHomeland.GetCurPrivateHomeInfo()
	local uMapSkinID = hHomeland.GetMapSkinID(dwMapID, tPrivateHomeInfo.dwSkinID)
	if tPrivateHomeInfo.dwSkinID == 0 then
		return dwMapID
	end
	return uMapSkinID
end

function UpdateCursorSize()
	if Platform.IsWindows() then
		local nVal = GameSettingData.GetNewValue(UISettingKey.MouseSize)
		local tSetting = UISettingKey2SettingConfig[UISettingKey.MouseSize]
		if nVal and tSetting then
			nVal = math.min(tSetting.nMaxVal, nVal)
			nVal = math.max(tSetting.nMinVal, nVal)
			nVal = nVal / 10
			SetCursorScale(nVal)
		end
	end
end

function IsDesignationEffectSfxItem(tItem)
	return false
	-- local hItemInfo = GetItemInfo(tItem.dwTabType, tItem.dwIndex)
	-- return IsDesignationEffectSfxItemInfo(hItemInfo)
end

function IsDesignationEffectSfxItemInfo(hItemInfo)
	if hItemInfo.nGenre ~= ITEM_GENRE.DESIGNATION then
		return false
	end

	local nType, nEffectID = ExteriorCharacter.GetRewardsEffectSfxTypeItemInfo(hItemInfo)
	if not nType then
		return false
	end

	if not nEffectID then
		return false
	end

	return true
end
