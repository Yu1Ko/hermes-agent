local function GetString(...)
	local t = {...}
	local s = ""
	for i = 1, #t do
		if i == #t then
			s = s .. t[i]
		else
			s = s .. t[i] .. ", "
		end
	end
	return s
end

local GMplayer = {
	AddItem = function(...) local s = GetString(...) SendGMCommand("player.AddItem(" .. s ..")") end,
	SetItemStrengthLevel = function(...) local s = GetString(...) SendGMCommand("player.SetItemStrengthLevel(" .. s ..")") end,
	SetItemMountDiamond = function(...) local s = GetString(...) SendGMCommand("player.SetItemMountDiamond(" .. s ..")") end,
	SetItemMountColorDiamond = function(...) local s = GetString(...) SendGMCommand("player.SetItemMountColorDiamond(" .. s ..")") end,
	AddEnchant = function(...) local s = GetString(...) SendGMCommand("player.AddEnchant(" .. s ..")") end,
	ExchangeItem = function(...) local s = GetString(...) SendGMCommand("player.ExchangeItem(" .. s ..")") end,
	EquipHorse = function(...) local s = GetString(...) SendGMCommand("player.EquipHorse(" .. s ..")") end,
}

local tDiamondCount = {}

function GetEquipTypeByID(nType)
	local tType = {
		[EQUIPMENT_INVENTORY.BOOTS] = 7,	--鞋子
		[EQUIPMENT_INVENTORY.RANGE_WEAPON] = 6,	--远程武器
		[EQUIPMENT_INVENTORY.PANTS] = 7,	--裤子
		[EQUIPMENT_INVENTORY.RIGHT_RING] = 8,	--右手戒指
		[EQUIPMENT_INVENTORY.BANGLE] = 7,	--护手
		[EQUIPMENT_INVENTORY.CHEST] = 7,	--上衣
		[EQUIPMENT_INVENTORY.PENDANT] = 8,	--腰坠
		[EQUIPMENT_INVENTORY.HELM] = 7,	--帽子
		[EQUIPMENT_INVENTORY.AMULET] = 8,	--项链
		[EQUIPMENT_INVENTORY.LEFT_RING] = 8,	--左手戒指
		[EQUIPMENT_INVENTORY.WAIST] = 7,	--腰带
		[EQUIPMENT_INVENTORY.MELEE_WEAPON] = 6,	--近战武器
		[EQUIPMENT_INVENTORY.BIG_SWORD] = 6,	--重剑
	}
	for k, v in pairs(tType) do
		if k == nType then
			return v
		end
	end
end

function GetItemPosByPackage(player, nItemType, nItemIndex)
	local tRolePackageList = {
		[0] = "PACKAGE", 							-- 原始背包
		[1] = "PACKAGE1", 						-- 背包1
		[2] = "PACKAGE2", 						-- 背包2
		[3] = "PACKAGE3", 						-- 背包3
		[4] = "PACKAGE4",						 -- 背包4
		[5] = "PACKAGE_MIBAO", 						-- 背包5
	}

	local tPlayerPackageSize = {
		[0] = player.GetBoxSize(INVENTORY_INDEX.PACKAGE), 
		[1] = player.GetBoxSize(INVENTORY_INDEX.PACKAGE1), 
		[2] = player.GetBoxSize(INVENTORY_INDEX.PACKAGE2), 
		[3] = player.GetBoxSize(INVENTORY_INDEX.PACKAGE3), 
		[4] = player.GetBoxSize(INVENTORY_INDEX.PACKAGE4),
		[5] = player.GetBoxSize(INVENTORY_INDEX.PACKAGE_MIBAO), 
	}
	
	for i = 0, #tRolePackageList do 
		for j = 0, tPlayerPackageSize[i] - 1 do 
			--Output(INVENTORY_INDEX[tRolePackageList[i]], j,nItemIndex, "GetItemPosByPackage")
			local item = player.GetItem(INVENTORY_INDEX[tRolePackageList[i]], j)
			--Output(INVENTORY_INDEX[tRolePackageList[i]], j,nItemIndex, "GetItemPosByPackage")
			if item then
				--Output("getitem",nItemIndex,item.dwIndex,INVENTORY_INDEX[tRolePackageList[i]], j)
				if item.dwTabType == nItemType and item.dwIndex == nItemIndex then
					return INVENTORY_INDEX[tRolePackageList[i]], j
				end
			end
		end
	end
	return nil, nil
	
end

function DiamondMastToItemIndex(nMask, nType)
	--[[local tDiamondIndex = {
		{7701, 2},
		{7706, 4},
		{7711, 3, 5},
		{7696, 5, 5},
		{7716, 1},
	}
	local nDiamondIndex
	local nFirst = 0
	for i = 5, 1, -1 do					
		local nSplitedData = math.floor(nMask / 2 ^ (5 - i)) % 2
		if nSplitedData == 1 and nFirst < tDiamondIndex[6 - i][2] then
			if not tDiamondCount[6 - i] then
				tDiamondCount[6 - i] = 0
			end
			--print(i, tDiamondCount[6 - i])
			if nType == EQUIPMENT_INVENTORY.BIG_SWORD then
				nDiamondIndex = tDiamondIndex[6 - i][1]
				nFirst = tDiamondIndex[6 - i][2]									
			end
			if (not tDiamondIndex[6 - i][3] or tDiamondCount[6 - i] < tDiamondIndex[6 - i][3]) and nType ~= EQUIPMENT_INVENTORY.BIG_SWORD then
				nDiamondIndex = tDiamondIndex[6 - i][1]
				nFirst = tDiamondIndex[6 - i][2]
				tDiamondCount[6 - i] = tDiamondCount[6 - i] + 1
			end
		end
	end--]]
	return 24449
end

function GetColorDiamondIndex(nKungfuID)
	if not tEquipItemByKungfuID[nKungfuID] then
		return nil
	end
	return tEquipItemByKungfuID[nKungfuID].ColorDiamond
end

function EquipConfigDataInit()
	tDiamondCount = {}
end

function NewRoleEquipConfig(MountKungfu)
	EquipConfigDataInit()
	GMMgr.DelayCall(4,fnGetEquip, {MountKungfu, 1}) --延时1秒执行SaveBodyPart函数
end

function ReCheckEquip()
	local player = GetClientPlayer()
	local nKungfuID = player.GetActualKungfuMountID()
	if nKungfuID then
		local tEquipData = tEquipItemByKungfuID[nKungfuID]["EquipInfo"]
		--Output("ReCheckEquip")
		for k, v in ipairs(tEquipData) do
			local nEquipPos = v[1]
			local EquipItemIndex
			local item = player.GetItem(INVENTORY_INDEX.EQUIP, nEquipPos)
			--Output(INVENTORY_INDEX.EQUIP, nEquipPos,item, "ReCheckEquip")
			if not item then
				--Output("ReCheckEquip",nEquipPos)
				local nItemType = GetEquipTypeByID(nEquipPos)
				if type(v[2]) == "table" then
					if #v[2] ~= 1 then
						EquipItemIndex = v[2][player.nCamp + 1]
					else
						EquipItemIndex = v[2][1]
					end
				else
					EquipItemIndex = v[2]
				end
				local nEmptyBag, nEmptySlot = GetItemPosByPackage(player, nItemType, EquipItemIndex)
				if nEmptyBag then
					--Output("ReCheckEquip",nItemType, EquipItemIndex, nKungfuID, nEquipPos, v[3])
					fnEquipCfg({nItemType, EquipItemIndex, nKungfuID, nEquipPos, v[3]})
				end
			end
		end
	end
	-- 触发配置完成事件
	Event.Dispatch("ROLE_CONFIG_END")
end

function fnGetEquip(t)
	local nKungfuID = t[1]
	local nParam1 = t[2]
	local player = GetClientPlayer()
	--Output("xxx:" .. nKungfuID,nParam1)
	if not tEquipItemByKungfuID[nKungfuID] then
		return
	end
	if not tEquipItemByKungfuID[nKungfuID]["EquipInfo"][nParam1] then
		local tTalentList = tEquipItemByKungfuID[nKungfuID]["TalentCfg"]
		if tTalentList then
			RemoteCallToServer("On_Skill_SetNewTalent", tTalentList)
		end
		SendGMCommand("player.".._G.CurLife.." = player.".._G.MaxLife)
		if player.GetItemAmount(5, 5284) < 1 then
			GMplayer.AddItem(5, 5284)
		end
		--local horse = player.GetItem(INVENTORY_INDEX.EQUIP,EQUIPMENT_INVENTORY.HORSE)
		local horse = player.GetEquippedHorse()
		if not horse then
			--GMplayer.DestroyItem(INVENTORY_INDEX.HORSE, 0)
			GMplayer.AddItem(8,5758,1,INVENTORY_INDEX.HORSE, 0)
			GMplayer.EquipHorse(INVENTORY_INDEX.HORSE, 0)	
			--GMplayer.AddItem(8, 5758, 1, INVENTORY_INDEX.EQUIP,INVENTORY_INDEX.HORSE)
		end
--~ 		GMMgr.DelayCall(200, LearnSkillRecipeItem) 	---九天逍遥里的学习技能秘籍是旧的，改版后不一定维护到最新，所以换种方式实现
		GMMgr.DelayCall(1, ReCheckEquip)
		--Output("mashang ok")
		return
	end
	local nKungfuID = player.GetActualKungfuMountID()
	local nEmptyBag, nEmptySlot = player.GetFreeRoomInPackage()
	if not nEmptyBag then
		OutputMessage("MSG_ANNOUNCE_YELLOW", UIHelper.GBKToUTF8("包裹没位置了，请重新来过..."))
		return
	end
	if nKungfuID then
		if not tEquipItemByKungfuID[nKungfuID]["EquipInfo"] then
			--Output("no equip info:" .. nKungfuID)
			return
		end
		local tEquipData = tEquipItemByKungfuID[nKungfuID]["EquipInfo"][nParam1]
		if tEquipData then
			local nEquipPos = tEquipData[1]
			local EquipItemIndex
			local item = player.GetItem(INVENTORY_INDEX.EQUIP, nEquipPos)
			local nItemType = GetEquipTypeByID(nEquipPos)
			local nEnchantID = 0
			if item then
				DestroyItem(INVENTORY_INDEX.EQUIP, nEquipPos)
			end
			if type(tEquipData[2]) == "table" then
				if #tEquipData[2] ~= 1 then
					EquipItemIndex = tEquipData[2][player.nCamp + 1]
					GMplayer.AddItem(nItemType, EquipItemIndex, 1)
				else
					EquipItemIndex = tEquipData[2][1]
					GMplayer.AddItem(nItemType, EquipItemIndex, 1)
				end
			else
				EquipItemIndex = tEquipData[2]
				GMplayer.AddItem(nItemType, EquipItemIndex, 1)
			end
			
			if type(tEquipData[3]) == "table" then
				if player.nCamp ~= 0 then
					nEnchantID = tEquipData[3][2]
				else
					nEnchantID = tEquipData[3][1]
				end
			else
				nEnchantID = tEquipData[3]
			end
			
			nParam1 = nParam1 + 1
			----Output("GMMgr.DelayCall", 4 + nParam1 + 0.5, 4 + nParam1)
			OutputMessage("MSG_ANNOUNCE_YELLOW", UIHelper.GBKToUTF8("正在配置装备、五行石，请不要重复操作..."))
			GMMgr.DelayCall(1, fnEquipCfg, {nItemType, EquipItemIndex, nKungfuID, nEquipPos, nEnchantID})
			GMMgr.DelayCall(2, fnGetEquip, {nKungfuID, nParam1})
		end
	end
end

function fnEquipCfg(t)
	local nItemType, nItemIndex, nKungfuID, nEquipPos, nEnchantID  = t[1], t[2], t[3], t[4], t[5]
--	Output(nItemType, nItemIndex, nKungfuID, nEquipPos, nEnchantID, "fnEquipCfg")
	local player = GetClientPlayer()
	local nEmptyBag, nEmptySlot = GetItemPosByPackage(player, nItemType, nItemIndex)
	local itemNew
	
	if nEmptyBag then
		itemNew = player.GetItem(nEmptyBag, nEmptySlot)
	end
	----Output(nEmptyBag, nEmptySlot, itemNew)
	--Output(nEmptyBag, nEmptySlot, nItemIndex, nItemType ,"fnEquipCfg",itemNew)
	if itemNew then
		local ItemInfo = GetItemInfo(nItemType, nItemIndex)
		local nMaxStrengthLevel = ItemInfo.nMaxStrengthLevel
		GMplayer.SetItemStrengthLevel(nEmptyBag, nEmptySlot, nMaxStrengthLevel)
		for i = 0, 2 do
			local tSlotAttribInfo = itemNew.GetSlotAttrib(i, 8)
			if tSlotAttribInfo then
				local nDiamondIndex = DiamondMastToItemIndex(nEquipPos)
				if nDiamondIndex then
					GMplayer.SetItemMountDiamond(nEmptyBag, nEmptySlot, i, 5, nDiamondIndex)
				end
			end
		end
		if itemNew.CanMountColorDiamond() then
			local nColorDiamondIndex = GetColorDiamondIndex(nKungfuID)
			if nColorDiamondIndex then
				GMplayer.SetItemMountColorDiamond(nEmptyBag, nEmptySlot, 5, nColorDiamondIndex)
			end
		end
		if nEnchantID ~= 0 then
			GMplayer.AddEnchant(nEmptyBag, nEmptySlot, nEnchantID, ENCHANT_INDEX.PERMANENT_ENCHANT)
		end
	end
	--Output("ExchangeItem",nEmptyBag, nEmptySlot, INVENTORY_INDEX.EQUIP, nEquipPos)		
	GMplayer.ExchangeItem(nEmptyBag, nEmptySlot, INVENTORY_INDEX.EQUIP, nEquipPos)
	
end

function LearnSkillRecipeItem()
	local player = GetClientPlayer()
	local nEmptyBag, nEmptySlot = GetItemPosByPackage(player, 5, 5284)
	
	if player.GetMapID() ~= 1 then
		OutputMessage("MSG_ANNOUNCE_YELLOW", "学习秘笈需要在稻香村进行，请在稻香村手动使用【九天·逍遥】学习...")
		return
	end
	local fnLearnRecipe = function()
		local frame = Station.Lookup("Normal/DialoguePanel")
		if not frame and not frame:IsVisible() then
			return
		end
		local tDialogueInfo = frame.aInfo
		if not tDialogueInfo then
			return
		end
		local szText = "学习门派对应秘笈"
		for k, v in ipairs(tDialogueInfo) do
			if v.name == "$" then
				if string.find(v.context, szText) then
					player.WindowSelect(frame.dwIndex, v.attribute.id)
					CloseDialoguePanel()
					return
				end
			end
		end
		CloseDialoguePanel()
	end
	
	if nEmptyBag then
		OnUseItem(nEmptyBag, nEmptySlot)
		GMMgr.DelayCall(1, fnLearnRecipe)
	end
end
