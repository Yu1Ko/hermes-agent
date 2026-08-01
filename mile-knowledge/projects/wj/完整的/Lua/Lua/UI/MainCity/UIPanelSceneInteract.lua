-- ---------------------------------------------------------------------------------
-- Author: zhengjianqiang
-- Name: UIPanelSceneInteract
-- Date: 2022-11-02 16:40:08
-- Desc: 场景可交互列表
-- ---------------------------------------------------------------------------------

local SORT_TYPE = {
	ITEM = 1,--物品
	NPC_FINISH_QUEST = 2,--交任务NPC
	NPC_ACCEPT_QUEST = 3,--接任务NPC
	NPC_DIALOGUE = 4,--任务对话NPC
	FURNITURE = 5,--家具
	DOODAD_QUEST = 6, -- 任务操作DooDad
	NPC_PRIORITY = 7,--某些优先级npc
	DOODAD_PRIORITY = 8,-->某些优先级Doodad
	NPC_NORMAL = 9,--普通npc
	NPC_EMPLOYER = 10,--有雇主且雇主不是自己的npc
	DOODAD_NORMAL = 11, --普通DooDad
	NONE = 12,--未定义
}

--物品->交任务->接任务->任务对话->家具->任务操作DooDad->某些优先级npc->某些优先级Doodad->普通npc->普通DooDad->有雇主且雇主不是自己的npc->其它
local SORT_PRIORITY_VALUE = {
	[SORT_TYPE.ITEM] = 11,
	[SORT_TYPE.NPC_FINISH_QUEST] = 10,
	[SORT_TYPE.NPC_ACCEPT_QUEST] = 9,
	[SORT_TYPE.NPC_DIALOGUE] = 8,
	[SORT_TYPE.FURNITURE] = 7,
	[SORT_TYPE.DOODAD_QUEST] = 6,
	[SORT_TYPE.NPC_PRIORITY] = 5,
	[SORT_TYPE.DOODAD_PRIORITY] = 4,
	[SORT_TYPE.NPC_NORMAL] = 3,
	[SORT_TYPE.DOODAD_NORMAL] = 2,
	[SORT_TYPE.NPC_EMPLOYER] = 1,
	[SORT_TYPE.NONE] = 0,
}

local UIPanelSceneInteract = class("UIPanelSceneInteract")

local _tOpenedDoodadIds = {}
local nPetInteractiveDistance = 2 * 64
local szDefaultBg = "UIAtlas2_Public_PublicHint_PublicHint_img_JiaohuBg.png"

local Def = {
	nWaitDoodadOpenTime = 0.5, --采集需要的时间
	nSearchRadius       = 3 * 64, --尺数*转换为米的值（最终为米数）
	nDoodadRadius       = 6 * 64, --尺数*转换为米的值（最终为米数）
	nDoodadNameRadius   = 36 * 64,--名字显示范围
	nSearchAngle        = 270, --角度
	QuestState          = {
		None = 1,
		CanAccept = 2,
		HaveFinish = 3,
	},
	OT_STATE            = {
		ON_PREPARE = 1, -- 正向读条(需要每帧计算重绘)
		ON_CHANNEL = 2, -- 逆向读条(需要每帧计算重绘)
		SUCCEED    = 8, -- 读条成功结束(渐变隐藏)
		FAILED     = 9, -- 读条失败结束(渐变隐藏)
		IDLE       = 10, -- 没有读条(空闲)
	},
}


--交互类型
local INTERACTIVE_TYPE = {
	NPC = "npc",
	ITEM = "item",
	FURNITURE = "furniture",
	COMPASS = "Compass",
	PETACTION = "PetAction",
	ONCE = "once", --Doodad 拾取后就消失 不需要读条的
	ONCE_TIME = "once_time", --Doodad 拾取后就消失 需要读条的
	DIALOG = "dialog", --Doodad 一直存在的
	WORKBENCH = "workbench", -- 工作台Doodad，点击跳转到技艺界面对应分类
}

--玩家技能创建的npc屏蔽列表
local tbPlayerSkillNpcHideList = {
	[57658] = true,		-- 封渊震煞
	[58120] = true,		-- 楚河汉界
	[127059] = true,	-- 霸刀刀墙
	[127070] = true,	-- 霸刀刀墙
	[126626] = true,	-- 藏剑剑魂
	[127106] = true,	-- 长歌影子
	[127267] = true,	-- 万灵乘黄
	[127268] = true,	-- 万灵归平野
	[300229] = true,	-- 逐云寒蕊
	[300228] = true,	-- 苍棘缚地
	[300239] = true,	-- 青川濯莲
}

local QUESTSTAET_PRIORITY = {
	[Def.QuestState.HaveFinish] = SORT_TYPE.NPC_FINISH_QUEST,
	[Def.QuestState.CanAccept] = SORT_TYPE.NPC_ACCEPT_QUEST,
	[Def.QuestState.None] = SORT_TYPE.NPC_NORMAL,
}


-- 是否有掉落可领
local function _HaveLoot(doodad)
	local scene = g_pClientPlayer.GetScene()
	if not scene then return false end

	local tAllLootItemInfo = scene.GetLootList(doodad.dwID)
	if not tAllLootItemInfo then return false end
	return scene.GetLootMoney(doodad.dwID) > 0 or tAllLootItemInfo.nItemCount > 0
end

local function _IsOpened(nDoodadId)
	return true == _tOpenedDoodadIds[nDoodadId]
end

local function _CanLoot(doodad, nPlayerId)
	if _IsOpened(doodad.dwID) and _HaveLoot(doodad) then
		return true
	end
	return false
end

local function _LoadCfg()
	--=======================================================================
	local function InteractType0(doodad, player)
		-- 有掉落
		if _HaveLoot(doodad) then
			-- 是通过搜索后的掉落
			if doodad.CanSearch() then
				-- 已被打开, 可拾取
				if _IsOpened(doodad.dwID) then
					return INTERACTIVE_TYPE.ONCE, g_tStrings.FISH_ROOT_TIELE, 31
				end
				-- 是击杀掉落的掉落, 可拾取
			else
				return INTERACTIVE_TYPE.ONCE, g_tStrings.FISH_ROOT_TIELE, 31
			end
		end

		local doodadTemp = GetDoodadTemplate(doodad.dwTemplateID)
		if doodadTemp
			and doodadTemp.dwCraftID ~= 0
			and player.IsProfessionLearnedByCraftID(doodadTemp.dwCraftID) then --庖丁
				-- g_tStrings.STR_CRAFT3
			return INTERACTIVE_TYPE.ONCE_TIME, nil, 30
		end
	end

	local function InteractType1(doodad, player)
		local doodadTemp = GetDoodadTemplate(doodad.dwTemplateID)
		if not doodadTemp or not player.IsProfessionLearnedByCraftID(doodadTemp.dwCraftID) then
			return
		end

		if doodadTemp.dwCraftID == 1 then --采矿
			if _CanLoot(doodad, player.dwID) then
				return INTERACTIVE_TYPE.ONCE, g_tStrings.FISH_ROOT_TIELE, 31
			else
				return INTERACTIVE_TYPE.ONCE_TIME, g_tStrings.STR_CRAFT1, 30
			end
		elseif doodadTemp.dwCraftID == 2 then --采药
			if _CanLoot(doodad, player.dwID) then
				return INTERACTIVE_TYPE.ONCE, g_tStrings.FISH_ROOT_TIELE, 31
			else
				return INTERACTIVE_TYPE.ONCE_TIME, g_tStrings.STR_CRAFT2, 30
			end
		elseif doodadTemp.dwCraftID == 3 then --庖丁, 30
			if _CanLoot(doodad, player.dwID) then
				return INTERACTIVE_TYPE.ONCE, g_tStrings.FISH_ROOT_TIELE, 31
			else
				return INTERACTIVE_TYPE.ONCE_TIME, g_tStrings.STR_CRAFT3, 30
			end
		elseif doodadTemp.dwCraftID == 12 then --抄录
			return INTERACTIVE_TYPE.ONCE_TIME, g_tStrings.STR_CRAFT12, 32
		elseif doodadTemp.dwCraftID == 8 then --阅读
			return INTERACTIVE_TYPE.DIALOG, g_tStrings.STR_LOOK, 32
		end
	end

	local function InteractType2(doodad, player)
		if doodad.HaveQuest(player.dwID) then
			if _CanLoot(doodad, player.dwID) then
				return INTERACTIVE_TYPE.ONCE, g_tStrings.FISH_ROOT_TIELE, 31
			else
				return INTERACTIVE_TYPE.ONCE_TIME, g_tStrings.STR_OPT, 31
			end
		end
	end

	local function InteractType3(doodad, player)
		-- local doodadInfo = GetDoodadTemplate(doodad.dwTemplateID)
		-- if (doodadInfo and doodadInfo.bCanOperateEach) then
		-- 	return INTERACTIVE_TYPE.DIALOG, g_tStrings.STR_OPT, 31
		-- else
		-- 	if _CanLoot(doodad, player.dwID) then
		-- 		return INTERACTIVE_TYPE.ONCE, g_tStrings.FISH_ROOT_TIELE, 31
		-- 	else
		-- 		return INTERACTIVE_TYPE.ONCE_TIME, g_tStrings.STR_OPT, 31
		-- 	end
		-- end
		if _CanLoot(doodad, player.dwID) then
			return INTERACTIVE_TYPE.ONCE, g_tStrings.FISH_ROOT_TIELE, 31
		else
			local doodadInfo = GetDoodadTemplate(doodad.dwTemplateID)
			if (doodadInfo and doodadInfo.bCanOperateEach) then
				return INTERACTIVE_TYPE.DIALOG, g_tStrings.STR_OPT, 31
			else
				return INTERACTIVE_TYPE.ONCE_TIME, g_tStrings.STR_OPT, 31
			end
		end
	end

	local function InteractType4(doodad, player)
		local dwCustomValue = doodad.dwCustomValue
		local hTeam = GetClientTeam()
		if dwCustomValue == 0 or (dwCustomValue > 0 and hTeam and hTeam.IsPlayerInTeam(dwCustomValue)) then
			return "dialog", g_tStrings.STR_LOOK, 8
		end
	end

	--doodad 拾取类型被分为：
	--第 1 优先 once 		拾取后就消失 不需要读条的
	--第 2 优先 once_time 	拾取后就消失 需要读条的
	--第 3 优先 dialog 	一直存在的
	_tDoodadCfg =
	{
		[DOODAD_KIND.CORPSE] = InteractType0,
		[DOODAD_KIND.CRAFT_TARGET] = InteractType1,
		[DOODAD_KIND.QUEST] = InteractType2,
		[DOODAD_KIND.ACCEPT_QUEST] = function() return INTERACTIVE_TYPE.DIALOG, g_tStrings.STR_LOOK, 32 end,
		[DOODAD_KIND.READ] = function() return INTERACTIVE_TYPE.DIALOG, g_tStrings.STR_LOOK, 32 end,
		[DOODAD_KIND.DIALOG] = function() return INTERACTIVE_TYPE.DIALOG, g_tStrings.STR_DIALOG_PANEL, 32 end,
		[DOODAD_KIND.TREASURE] = InteractType3,
		[DOODAD_KIND.DOOR] = function() return INTERACTIVE_TYPE.ONCE_TIME, g_tStrings.STR_LOOK, 32 end,
		[DOODAD_KIND.CHAIR] = function() return INTERACTIVE_TYPE.DIALOG, g_tStrings.STR_LOOK, 32 end,
		[DOODAD_KIND.NPCDROP] = InteractType0,
		[DOODAD_KIND.CRAFT_HERB]   = function() return INTERACTIVE_TYPE.ONCE_TIME, g_tStrings.STR_CRAFT2, 30 end,
		[DOODAD_KIND.CRAFT_MINERAL] = function() return INTERACTIVE_TYPE.ONCE_TIME, g_tStrings.STR_CRAFT2, 30 end,
		[DOODAD_KIND.BANQUET] = InteractType4,
	}
end

local function _CheckNpc(npc, dwID)
	local dwTemplateID = npc.dwTemplateID
	local bResult = true
	local bPlayerSkillNpc = tbPlayerSkillNpcHideList[dwTemplateID] or false
	local bHaveEmployer = npc.dwEmployer and npc.dwEmployer > 0 -- 是否绑定了雇主id
	-- local bHasQuest = NpcData.HasQuest(dwID) -- 交互后是否有事件响应

	local hPetIndex = GetFellowPetIndexByNpcTemplateID(dwTemplateID)
	if hPetIndex ~= 0 then
		bResult = true
	end

	if AppReviewMgr.IsReview() then
		bResult = dwTemplateID ~= 68010 and dwTemplateID ~= 12120 -- 万宝楼执事 和 黄字零零玖
	end

	if bHaveEmployer then
		bResult = bResult and not bPlayerSkillNpc
	end

	--- 额外检查侠客的条件
	bResult = bResult and PartnerData.CheckPartnerInteractive(dwID)

	return bResult
end

local function _CheckPetAction(dwTemplateID)
	local bResult = true

	local hPetIndex = GetFellowPetIndexByNpcTemplateID(dwTemplateID)
	if hPetIndex ~= 0 then
		bResult = not Storage.QuickPetAction.bPetShieldAction
	end

	return  bResult
end

local _nNpcCount = nil
local function _SearchNpc(player)
	-- 36: sortAlly | sortNeutrality
	-- 5308: 浩气盟-谢渊
	-- 4997: 恶人谷-王遗风
	-- 4819: 陶寒亭
	-- 5135：可人
	-- 5196：影
	-- 59067：司空仲平
	local tResult = player.SearchForNpc(Def.nSearchRadius, Def.nSearchAngle, false, 36, CommonDef.Scene.IGNORE_CAMP_NPC_LIST)
	if not tResult then
		return {}
	end

	local npc
	local tNpcArr = {}
	for k, dwID in pairs(tResult) do
		if not IsPlayer(dwID) then
			npc = GetNpc(dwID)
			if npc
				and npc.IsSelectable()
				and npc.bDialogFlag
				and npc.CanDialog(player)
				-- and not Table_IsAutoSearchShield(TARGET.NPC, npc.dwTemplateID)
				and _CheckNpc(npc, dwID)
				and _CheckPetAction(npc.dwTemplateID)
				and not string.is_nil(npc.szName)
			then
				--当前所有能互动的NPC
				local name = npc.szName
				local tState = GetNpcQuestState(npc)
				local szFrame = "UIAtlas2_Public_PublicIcon_PublicIcon1_btn_Dialogue.png"
				local szFrameBg = "UIAtlas2_Public_PublicHint_PublicHint_img_JiaohuBg.png"
				local nQuestState = Def.QuestState.None
				local bBindQuest = QuestData.IsNpcBindQuest(npc.dwTemplateID)
				local employer = npc.GetEmployer()
				local nEmployerID = employer and employer.dwID
				if tState.szStatus == "CanFinish" then
					nQuestState = Def.QuestState.HaveFinish
					szFrame = "UIAtlas2_Public_PublicIcon_PublicIcon1_icon_renwuWC_huang.png"
					szFrameBg = "UIAtlas2_Public_PublicHint_PublicHint_img_JiaohuBg1.png"
				elseif tState.szStatus == "CanAccept" then
					nQuestState = Def.QuestState.CanAccept
					szFrame = "UIAtlas2_Public_PublicIcon_PublicIcon1_icon_renwu_huang.png"
					szFrameBg = "UIAtlas2_Public_PublicHint_PublicHint_img_JiaohuBg1.png"
				elseif bBindQuest then--不能交、不能接、绑定了任务、黄色底+黄色气泡
					szFrame = "UIAtlas2_Public_PublicIcon_PublicIcon1_btn_Dialogue2.png"
					szFrameBg = "UIAtlas2_Public_PublicHint_PublicHint_img_JiaohuBg1.png"
				end

				table.insert(tNpcArr, {
					nObjType = OBJ_TYPE.NPC,
					bBindQuest = bBindQuest,
					id = dwID,
					type = INTERACTIVE_TYPE.NPC,
					title = UIHelper.GBKToUTF8(name),
					imageFrame = szFrame,
					imageFrameBg = szFrameBg,
					nQuestState = nQuestState,
					dwTemplateID = npc.dwTemplateID,
					bEmployer = nEmployerID ~= nil and nEmployerID ~= g_pClientPlayer.dwID,
					fDistances = GetLogicDist({player.nX, player.nY, player.nZ}, {npc.nX, npc.nY, npc.nZ}) / 64 * 100,
				})
			end
		end
	end

	if DEBUG_ZJQ then
		local nNpcCount = #tResult
		if _nNpcCount ~= nNpcCount then
			--LOG.INFO("----> _SearchNpc: %d(%d)", nNpcCount, #tNpcArr)
			_nNpcCount = nNpcCount
		end
	end

	return tNpcArr
end

local function _CheckDoodad(doodad, player)
	if not doodad or not doodad.IsSelectable() then
		return
	end

	local func = _tDoodadCfg[doodad.nKind]
	if not func then
		return
	end
	return func(doodad, player);
end

local function _CheckPaoDingDoodad(doodad, player)
	local bResult = true
	local bState = SprintData.GetViewState()
	local doodadTemp = GetDoodadTemplate(doodad.dwTemplateID)
	if doodadTemp and doodadTemp.dwCraftID == 3 and player.bFightState then	--处于战斗状态且为庖丁
		bResult = false
	end
	return bResult
end

-- 从doodad中提取物品
local function _GetItemArrOfDoodad(doodad, tItemArr)
	assert(doodad)
	assert(tItemArr)
	local player = GetClientPlayer()
	if not player then return end
	local scene = player.GetScene()
	if not scene then return end

	local tAllLootItemInfo = scene.GetLootList(doodad.dwID)
	if not tAllLootItemInfo then return end

	local nMoney = scene.GetLootMoney(doodad.dwID)
	if nMoney and nMoney > 0 then
		table.insert(tItemArr, {
			nObjType = OBJ_TYPE.ITEM,
			type = INTERACTIVE_TYPE.ITEM,
			id = 0,
			title = g_tStrings.STR_MONEY,
			nCount = nMoney,
			nDoodadId = doodad.dwID
		})
	end

	for i = 0, tAllLootItemInfo.nItemCount - 1 do
		if tAllLootItemInfo[i] then
			local item = tAllLootItemInfo[i].Item
			local szItemName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItem(item))
			table.insert(tItemArr, {
				nObjType = OBJ_TYPE.ITEM,
				type = INTERACTIVE_TYPE.ITEM,
				id = item.dwID,
				dwIndex = item.dwIndex,
				dwTabType = item.dwTabType,
				title = szItemName,
				--nUiId = item.nUiId,
				nQuality = item.nQuality,
				nGenre = item.nGenre,
				nCount = item.bCanStack and item.nStackNum or 1,
				nDoodadId = doodad.dwID
			})
		end
	end
end

-- 合并相同的物品
local function _MergeItemList(tItemArr)
	local tItems = {}
	for _, v in ipairs(tItemArr) do
		local szKey = not v.dwTabType and "money" or (tostring(v.dwTabType) .. "_" .. tostring(v.dwIndex))
		-- 金币
		local tItem = tItems[szKey]
		if not tItem then
			tItem = v
			tItem.tLootData = {}
			tItems[szKey] = tItem
		else
			tItem.nCount = tItem.nCount + v.nCount
		end
		table.insert(tItem.tLootData, { v.nDoodadId, v.id })
	end
	return tItems
end

-- 物品排序
local function _SortItemList(tItems)
	local tItemArr = {}
	-- 任务/商店/对话/任务道具/普通掉落
	for _, tItem in pairs(tItems) do
		table.insert(tItemArr, tItem)
	end
	table.sort(tItemArr, function(tA, tB)
		local nA, nB = 0, 0
		-- 钱
		--if tA.nMoney then nA = nA + 0 end
		--if tB.nMoney then nB = nB + 0 end
		-- 物品
		if tA.dwTabType then nA = nA + 1 end
		if tB.dwTabType then nB = nB + 1 end
		-- 品质
		if tA.nQuality then nA = nA + tA.nQuality * 10 end
		if tB.nQuality then nB = nB + tB.nQuality * 10 end
		-- 任务
		if tA.nGenre == ITEM_GENRE.TASK_ITEM then nA = nA + 10 * 9 end
		if tB.nGenre == ITEM_GENRE.TASK_ITEM then nB = nB + 10 * 9 end

		return nA > nB
	end)

	return tItemArr
end


local _nDoodadCount = nil
local function _SearchDoodad(player)
	local tDoodadList  = {}
	local tItemList    = {}
	local tTemplateIds = {}

	local tDoodads     = player.SearchForDoodad(Def.nDoodadRadius)
	if not tDoodads then
		return tDoodadList, tItemList
	end

	local bHasOpenedItems = false
	local bTreasureBattle = BattleFieldData.IsInTreasureBattleFieldMap()
	if bTreasureBattle and not table_is_empty(_tOpenedDoodadIds) then
		for dwID in pairs(_tOpenedDoodadIds) do
			local doodad = GetDoodad(dwID)
			_GetItemArrOfDoodad(doodad, tItemList)
		end
		bHasOpenedItems = not table_is_empty(tItemList)
	end

	if not bHasOpenedItems then
		local doodad
		local szType, szTitle, nFrame
		local nX, nY, nZ = player.nX, player.nY, player.nZ
		for k, dwID in pairs(tDoodads) do
			doodad = GetDoodad(dwID)
			if doodad and _CheckPaoDingDoodad(doodad, player) then
				szType, szTitle, nFrame = _CheckDoodad(doodad, player)

				-- 只收集可交互的对象
				if szType and doodad.CanDialog(player) then
					if szType == INTERACTIVE_TYPE.ONCE then
						_GetItemArrOfDoodad(doodad, tItemList)
					elseif szType == INTERACTIVE_TYPE.ONCE_TIME or szType == INTERACTIVE_TYPE.DIALOG then
						if not tTemplateIds[doodad.dwTemplateID] then
							tTemplateIds[doodad.dwTemplateID] = true -- 排除TemplateID相同的交互
							local bBindQuest = doodad.HaveQuest(g_pClientPlayer.dwID)
							local tDoodad = {
								nObjType   = OBJ_TYPE.DOODAD,
								bBindQuest = bBindQuest,
								id = dwID,
								type = szType,
								title = UIHelper.GBKToUTF8(doodad.szName),
								imageFrame = bBindQuest and "UIAtlas2_Public_PublicIcon_PublicIcon1_btn_shiqu2.png"
								or "UIAtlas2_Public_PublicIcon_PublicIcon1_btn_shiqu.png",
								imageFrameBg = bBindQuest and "UIAtlas2_Public_PublicHint_PublicHint_img_JiaohuBg1.png"
								or "UIAtlas2_Public_PublicHint_PublicHint_img_JiaohuBg.png",
								szTitle = szTitle,
								dwTemplateID = doodad.dwTemplateID,
								fDistances = GetLogicDist({nX, nY, nZ}, {doodad.nX, doodad.nY, doodad.nZ}) / 64 * 100,
							}
							table.insert(tDoodadList, tDoodad)
						end
					end
				end
			end
		end
	end

	local tItems = _MergeItemList(tItemList)
	tItemList = _SortItemList(tItems)

	if DEBUG_ZJQ then
		local nDoodadCount = #tDoodads
		if _nDoodadCount ~= nDoodadCount then
			LOG.INFO("----> _SearchDoodad: %d(%d)(%d)", nDoodadCount, #tDoodadList, #tItemList)
			_nDoodadCount = nDoodadCount
		end
	end

	return tDoodadList, tItemList
end

local function _SearchNameVisibleDoodads(player)
	local tDoodadIDs = player.SearchForDoodad(Def.nDoodadNameRadius)
	if not tDoodadIDs then
		return {}
	end

	local tRet = {}
	for _, id in pairs(tDoodadIDs) do
		local doodad = GetDoodad(id)
		if doodad and doodad.nKind ~= DOODAD_KIND.CORPSE  then
			local szType = _CheckDoodad(doodad, player)
			if (szType == INTERACTIVE_TYPE.ONCE_TIME or szType == INTERACTIVE_TYPE.DIALOG)
				and not doodad.bShowName then	-- 只收集可交互的对象
				table.insert(tRet, id)
			end
		end
	end
	return tRet
end

local FURNITURE_RADIUS = 2
local FURNITURE_RADIUS2 = 8
local MAX_FURNITURE_FIND_COUNT = -1
local LandObjectInteractionConfig = nil
local function _SearchFurniture()
	local tFurnitureArr   = {}

	-- local nLandIndex, nInstID, dwReprID, dwGroupID = Homeland_GetNearestObjectInfo(FURNITURE_RADIUS)

	local player = PlayerData.GetClientPlayer()

	local nX, nY, nZ = player.nX, player.nY, player.nZ
	local tbObjInfos = Homeland_GetNearbyObjectsInfo(FURNITURE_RADIUS2)
	for i, tbInfo in ipairs(tbObjInfos) do
		tbInfo.fDistances = GetLogicDist({nX, nY, nZ}, {tbInfo.nX, tbInfo.nY, tbInfo.nZ}) / 64 * 100
	end

	-- table.sort(tbObjInfos, function (a, b)--后面全部物品会排一次序
	-- 	return a.fDistances < b.fDistances
	-- end)

	LandObjectInteractionConfig = LandObjectInteractionConfig or HomelandCommon.Home_GetLandObjectInteraction()
	local tbSelectInfos = {}

	for i, tbInfo in ipairs(tbObjInfos) do
		local tbSelectInfo
		local tbConfigs = LandObjectInteractionConfig[tbInfo.RepresentID]
		for _, tbConfig in ipairs(tbConfigs or {}) do
			if tbConfig and tbConfig.nMaxInteractDist >= tbInfo.fDistances then
				tbSelectInfo = tbInfo
				break
			end
		end
		if tbSelectInfo then
			table.insert(tbSelectInfos, tbSelectInfo)
		end
	end

	if #tbSelectInfos <= 0 then
		return
	end

	for _, tbSelectInfo in ipairs(tbSelectInfos) do
		local nLandIndex, nInstID, dwReprID, dwGroupID = tbSelectInfo.BaseId, tbSelectInfo.InstID, tbSelectInfo.RepresentID, tbSelectInfo.GroupID
		local tInfo = nil
		local tFurniture = {}

		tInfo = FurnitureData.GetInstFurnInfoByModelID(dwReprID)
		if not tInfo then
			tInfo = FurnitureData.GetFurnInfoByModelID(dwGroupID)
		end
		-- if not tInfo then
			-- if dwReprID == 0 or dwGroupID == 0 then
			-- 	LOG.ERROR("可交互家具的表现ID非法，请带上重现方法联系包敬恒。nBaseID:%s, nInstID:%s, dwReprID:%s, dwGroupID:%s",
			-- 		tostring(nLandIndex), tostring(nInstID), tostring(dwReprID), tostring(dwGroupID))
			-- else
			-- 	LOG.ERROR("可交互家具的表现ID有问题，请联系钟琰。nLandIndex:%s, nInstID:%s, dwReprID:%s, dwGroupID:%s",
			-- 	tostring(nLandIndex), tostring(nInstID), tostring(dwReprID), tostring(dwGroupID))
			-- end
		-- end
		if tInfo then	-- 显示信息处理
			local dwObjID         = LandObject_GetObjIDFromLandIndexAndInstID(nLandIndex, nInstID)
			local tbInteractInfo  = LandObject_GetLandObjectInteractionInfo(nLandIndex, nInstID, dwReprID)
			tFurniture.id         = dwObjID
			local tCatg1UIInfo    = FurnitureData.GetCatg1Info(tInfo.nCatg1Index)
			local tCatg2UIInfo    = FurnitureData.GetCatg2Info(tInfo.nCatg1Index, tInfo.nCatg2Index)
			local szItemName = nil
			if not table.is_empty(tbInteractInfo) then
				local nGameID = HomelandCommon.LandObject_GetFurniture2GameID(dwReprID)
				if (nGameID == 1 or nGameID == 4 or nGameID == 5 or nGameID == 6 or nGameID == 18)
						and tbInteractInfo.tModule1Item then -- 宠物窝
					local tPet = Table_GetFellowPet(tbInteractInfo.tModule1Item.dwIndex)
					if tPet then
						local szPetName = tPet.szName
						local szGameState = HomelandMiniGameData.GetPetHouseState(nGameID, tbInteractInfo.nGameState)
						if not string.is_nil(szGameState) then
							szItemName = string.format("%s(%s)", szPetName, UIHelper.UTF8ToGBK(szGameState))
						else
							szItemName = szPetName
						end
					end
				elseif nGameID == 20 and tbInteractInfo.tWeaponList then -- 武器架
					local nWeaponID1 = tbInteractInfo.tWeaponList[1]
					if nWeaponID1 > 0 then
						-- 武器外观信息要从商城表里读，加个检测防跪
						if IsUITableRegister("CoinShop_Weapon") then
							local tUIInfo = CoinShop_GetWeaponInfo(nWeaponID1)
							szItemName = tUIInfo and tUIInfo.szName
						end
					end
				elseif nGameID == 7 and tbInteractInfo.tModule1Item and tbInteractInfo.nTime then -- 藏酒
					local tItemInfo = ItemData.GetItemInfo(tbInteractInfo.tModule1Item.dwTabType, tbInteractInfo.tModule1Item.dwIndex)
					local szState = HomelandMiniGameData.GetBrewStateByTime(tbInteractInfo.nTime)
					szItemName = ItemData.GetItemNameByItem(tItemInfo)
					if not string.is_nil(szState) then
						szItemName = string.format("%s%s", szItemName, UIHelper.UTF8ToGBK("·"..szState))
					end
				else
					if tbInteractInfo.tModule1Item then
						local tItemInfo = ItemData.GetItemInfo(tbInteractInfo.tModule1Item.dwTabType, tbInteractInfo.tModule1Item.dwIndex)
						szItemName = ItemData.GetItemNameByItem(tItemInfo)
					end
				end
			end

			if not string.is_nil(szItemName) then
				tFurniture.title      = szItemName and UIHelper.GBKToUTF8(szItemName) or nil
			else
				tFurniture.title  	  = UIHelper.GBKToUTF8(tCatg2UIInfo.szInteract)
			end
			tFurniture.imagePath  = tCatg2UIInfo.szIconImgPath
			tFurniture.imageFrame = tCatg2UIInfo.nStaticPicFrame
			tFurniture.imageFrameBg = "UIAtlas2_Public_PublicHint_PublicHint_img_JiaohuBg.png"
			tFurniture.szInteract = tCatg2UIInfo.szInteract
			tFurniture.type       = INTERACTIVE_TYPE.FURNITURE
			tFurniture.nObjType   = OBJ_TYPE.FURNITURE
			tFurniture.modelid 	  = tInfo.dwModelID
			tFurniture.fDistances = tbSelectInfo.fDistances
			tFurniture.tbInteractInfo = tbInteractInfo

			table.insert(tFurnitureArr, tFurniture)

			if MAX_FURNITURE_FIND_COUNT > 0 and #tFurnitureArr >= MAX_FURNITURE_FIND_COUNT then
				break
			end
		end
	end

	return tFurnitureArr
end

local function _SearchCompass()
	if g_bCompassVisible and g_bCompassFind then
		local tCellData = {
			nObjType   = OBJ_TYPE.COMPASS,
			type = INTERACTIVE_TYPE.COMPASS,
			title = "发现",
		}

		local tCompassArr   = {}
		table.insert(tCompassArr, tCellData)

		return tCompassArr
	end
end

local function _SearchPetAction()
	local tPet = g_pClientPlayer.GetFellowPet()
	if not Storage.QuickPetAction.bPetShieldAction and tPet then
		local hPetIndex = GetFellowPetIndexByNpcTemplateID(tPet.dwTemplateID)
		local dwDistance = GetCharacterDistance(g_pClientPlayer.dwID, tPet.dwID)
		local bDynamicSkillState = QTEMgr.IsInDynamicSkillState()
		if hPetIndex and hPetIndex ~= 0 and dwDistance ~= -1 and dwDistance <= nPetInteractiveDistance and not bDynamicSkillState and not g_pClientPlayer.bFightState then
			local tCellData = {
				nObjType = OBJ_TYPE.PETACTION,
				type = INTERACTIVE_TYPE.PETACTION,
				title = "宠物动作",
				fDistances = GetLogicDist({g_pClientPlayer.nX, g_pClientPlayer.nY, g_pClientPlayer.nZ}, {tPet.nX, tPet.nY, tPet.nZ}) / 64 * 100,
			}

			local tPetActionArr = {}
			table.insert(tPetActionArr, tCellData)

			return tPetActionArr
		end
	end
end

local function _SearchWorkbench(player)
	local tDoodadList  = {}

	local tDoodads = player.SearchForDoodad(Def.nDoodadRadius)
	if not tDoodads then
		return tDoodadList
	end

	for k, dwID in pairs(tDoodads) do
		local doodad = GetDoodad(dwID)
		if doodad and doodad.dwTemplateID then
			local dwProfessionID = CraftData.CraftDoodadTemplateID2ProfessionID[doodad.dwTemplateID]
			if dwProfessionID and doodad.dwTemplateID > 0 then
				local szDoodadName = Table_GetDoodadName(doodad.dwTemplateID, doodad.dwNpcTemplateID)
				szDoodadName = UIHelper.GBKToUTF8(szDoodadName)
				local tCellData = {
					nObjType   = OBJ_TYPE.WORKBENCH,
					type = INTERACTIVE_TYPE.WORKBENCH,
					title = szDoodadName,
					doodadTemplateID = doodad.dwTemplateID,
					fDistances = GetLogicDist({player.nX, player.nY, player.nZ}, {doodad.nX, doodad.nY, doodad.nZ}) / 64 * 100,
				}
				table.insert(tDoodadList, tCellData)
			end
		end
	end

	return tDoodadList
end

local function _Equal(t1, t2, bIgnoreDistance)
	if #t1 > 0 and #t1 == #t2 then
		for i = 1, #t1 do
			if t1[i].id ~= t2[i].id
				or t1[i].type ~= t2[i].type
				or t1[i].imageFrame ~= t2[i].imageFrame
				or t1[i].imageFrameBg ~= t2[i].imageFrameBg
				or t1[i].title ~= t2[i].title
				or t1[i].nQuestState ~= t2[i].nQuestState
				or t1[i].nCount ~= t2[i].nCount
				or (t1[i].fDistances ~= t2[i].fDistances and not bIgnoreDistance)
			then
				return false
			end
		end

		return true
	elseif #t1 == 0 and #t2 == 0 then
		return true
	end
	return false
end

local function _PickDoodads(aDoodad, bKeyDown)
	--[[
	if IsNorOrMDLootListOpened() and bKeyDown then
		LootList_AutoPickup()
		CloseLootList();
		return
	end

	if IsGoldTeamLootListOpened() and bKeyDown then
		GoldTeamLootList_AutoPickup()
		CloseGoldTeamLootList()
		return
	end
	--]]

	InteractDoodad(aDoodad.id)
end

function UIPanelSceneInteract:LootMoney(nDoodadId)
	self:AddLootArr({ nDoodadId = nDoodadId, id = 0 })
end

function UIPanelSceneInteract:LootItem(nDoodadId, nItemId)
	self:AddLootArr({ nDoodadId = nDoodadId, id = nItemId })
end

function UIPanelSceneInteract:OnEnter()
	self.m = {}
	s_UIPanelSceneInteract = self
	self._tOpenedDoodadIds = _tOpenedDoodadIds
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true

		self.nListOriginHeight = UIHelper.GetHeight(self.LayoutContentLess)
		self.tTeachData = {}
	end

	self:PreloadResource()
	self:InitData()
	-- UIHelper.SetSwallowTouches(self.ScrollViewInteractiveList, true)
	-- UIHelper.SetSwallowTouches(self.LayoutContentLess, false)
	UIHelper.SetLocalZOrder(self.BtnGetAll, 1)

	-- 运行时
	Timer.AddDelayFrameCycle(self, 1, 3, function() self:OnUpdate() end)

	if GameSettingData.GetNewValue(UISettingKey.ShowGatherableObjectName) then
		self.m.nDoodadNameId = Timer.AddCycle(self, 0.5, function ()
			self:OnUpdateDoodadName()
		end)
	end

	--教学用，根据交互家具的ObjID获取dwModelID
	_G.GetFurnitureModelID = function(dwID)
		local tFurnitureArr = self.m and self.m.tFurnitureArr
		if tFurnitureArr then
			for _, tFurniture in pairs(tFurnitureArr) do
				if tFurniture.id == dwID then
					return tFurniture.modelid
				end
			end
		end
	end
end

function UIPanelSceneInteract:OnExit()
	self.bInit = false

	Timer.DelAllTimer(self)
	self:UnRegEvent()
	self:UnInitScrollList()
	s_UIPanelSceneInteract = nil
	self.m = nil
end

function UIPanelSceneInteract:TakeAll()
	local arr = self.m.tItemArr
	assert(arr)
	for i, v in ipairs(arr) do
		for _, tData in pairs(v.tLootData) do
			local nDoodadId = tData[1]
			local nItemId = tData[2]
			if nItemId == 0 then
				self:LootMoney(nDoodadId)
			else
				self:LootItem(nDoodadId, nItemId)
				if AuctionData.tPickedDoodads[nDoodadId] and not UIMgr.IsViewOpened(VIEW_ID.PanelTeamAuction) then
					AuctionData.OnOpenDoodad(nDoodadId)
					AuctionData.TryOpenAuctionView()
				end
			end
		end
	end
	UIHelper.SetVisible(self.TakeAllBtn, false)
end

function UIPanelSceneInteract:AutoTakeAll()
	local arr = self.m.tItemArr
	assert(arr)
	for i, v in ipairs(arr) do
		for _, tData in pairs(v.tLootData) do
			local nDoodadId = tData[1]
			local nItemId = tData[2]
			if nItemId == 0 then
				self:LootMoney(nDoodadId)
			elseif LootSetting.CanAutoLoot(nItemId) then
				self:LootItem(nDoodadId, nItemId)
				if AuctionData.tPickedDoodads[nDoodadId] and not UIMgr.IsViewOpened(VIEW_ID.PanelTeamAuction) then
					AuctionData.OnOpenDoodad(nDoodadId)
					AuctionData.TryOpenAuctionView()
				end
			end
		end
	end
	UIHelper.SetVisible(self.TakeAllBtn, false)
end

function UIPanelSceneInteract:BindUIEvent()
	UIHelper.SetButtonClickSound(self.TakeAllBtn, "")
	UIHelper.BindUIEvent(self.TakeAllBtn, EventType.OnClick, function()
		self:TakeAll()
	end)

	UIHelper.SetButtonClickSound(self.BtnGetAll, "")
	UIHelper.BindUIEvent(self.BtnGetAll, EventType.OnClick, function()
		self:TakeAll()
	end)
end

function UIPanelSceneInteract:RegEvent()
	Event.Reg(self, "OPEN_DOODAD", function()
		local nDoodadId = arg0
		local nPlayerId = arg1
		if nPlayerId == GetClientPlayer().dwID then
			_tOpenedDoodadIds[nDoodadId] = true
			self.m.nWaitEndTime = nil
			self.m.nProgressBarEndTime = nil

			-- 偿试自动拾取
			self:TryPickup(nDoodadId)

			local clientTeam = GetClientTeam()
			if clientTeam and clientTeam.nLootMode == PARTY_LOOT_MODE.BIDDING then
				--OpenGoldTeamLootList(arg0)
			else
				--OpenLootList(arg0) ????
				LOG.INFO("----> event OPEN_DOODAD id = %d", arg0)
			end
			self:UpdateLootArr()

			-- 与端游一样，当读条完毕，没有拾取列表时，直接结束拾取流程（关闭拾取窗口），而不是继续蹲着
			local doodad = GetDoodad(nDoodadId)
			if doodad then
				local bCanLoot = _CanLoot(doodad, nPlayerId)
				if not bCanLoot then
					self:CloseLootList()
				end
			end

			-- 捡技能玩法中如果技能道具满了，就打开技能背包
			if TreasureBattleFieldSkillData.IsInDynamic() then
				local tSkillList = TreasureBattleFieldSkillData.GetDoodadSkillItemList(nDoodadId) or {}
				local nHaveCount, nTotalCount = TreasureBattleFieldSkillData.GetDynamicSkillCount()
				if nHaveCount + #tSkillList > nTotalCount then
					UIMgr.Open(VIEW_ID.PanelBattleFieldPubgEquipBagRightPop, 3, arg0)
				end
			end

			if BattleFieldData.IsInXunBaoBattleFieldMap() and TravellingBagData.CheckIsFull() then
				ExtractWareHouseData.OpenExtractPersetPanel(ExtractViewType.BagAndLoot, nDoodadId)
				return
			end
		end
	end)

	Event.Reg(self, "CLOSE_DOODAD", function()
		local nDoodadId = arg0
		local nPlayerId = arg1
		if nPlayerId == GetClientPlayer().dwID then
			if BattleFieldData.IsInXunBaoBattleFieldMap() then
				_tOpenedDoodadIds = {}  -- 寻宝模式右键交互时不会关闭之前交互的doodad，所以改一下
			else
				_tOpenedDoodadIds[nDoodadId] = nil
			end
			self.m.nWaitEndTime = nil

			if IsTableEmpty(_tOpenedDoodadIds) then
				self:CloseLootList()
			end
		end
	end)

	Event.Reg(self, "DOODAD_LEAVE_SCENE", function()
		local nDoodadId = arg0
		_tOpenedDoodadIds[nDoodadId] = nil
	end)

	Event.Reg(self, EventType.OnClientPlayerLeave, function()
		_tOpenedDoodadIds = {}
		self.m.tShowNameDoodads = {}
	end)

	Event.Reg(self, "SYS_MSG", function()
		if arg0 == "UI_OME_CHECK_OPNE_DOODAD" then
			self.m.nWaitEndTime = nil
			self.m.nProgressBarEndTime = nil
		end
	end)

	Event.Reg(self, "OT_ACTION_PROGRESS_BREAK", function()
		local nPlayerId = arg0
		if nPlayerId == GetClientPlayer().dwID then
			self.m.nWaitEndTime = nil
			TipsHelper.StopProgressBar()
			self.m.nProgressBarEndTime = nil
		end
	end)

	Event.Reg(self, "DO_PICK_PREPARE_PROGRESS", function()
		local nFrameCount = arg0
		local nDoodadId = arg1
		if nFrameCount and nFrameCount > 0 then
			self:OnPickProgress(nDoodadId, nFrameCount)
		end
	end)
	Event.Reg(self, "DO_CUSTOM_OTACTION_PROGRESS", function()
		local nFrameCount = arg0
		local szTitle = UIHelper.GBKToUTF8(arg1)
		local nState = arg2 == 0 and Def.OT_STATE.ON_PREPARE or Def.OT_STATE.ON_CHANNEL

		if szTitle ~= nil then
			szTitle = szTitle .. "(%.2f/%.2f)"
		else
			szTitle = ""
		end

		if nFrameCount and nFrameCount > 0 then
			self:OnCustomProgress(szTitle, nFrameCount, nState)
		end
	end)
	Event.Reg(self, EventType.OnSceneInteractByHotkey, function(bTakeAll)
		self:OnSceneInteractByHotkey(bTakeAll)
	end)
	Event.Reg(self, "SYNC_LOOT_LIST", function()
		if _tOpenedDoodadIds[arg0] then
			self:OnUpdate()
			self:TryPickup(arg0)
		end
	end)

	Event.Reg(self, EventType.OnInteractChangeVisible, function(bVisible)
		if bVisible then
			self:ShowView()
		else
			self:HideView()
		end
	end)

	-- Event.Reg(self, EventType.OnCameraZoom, function(nScale)
		-- if nScale <= 0.2 and not self.bZoomHideInteract then
		-- 	self:HideView()
		-- 	self.bZoomHideInteract = true
		-- elseif nScale > 0.2 and self.bZoomHideInteract then
		-- 	self:ShowView()
		-- 	self.bZoomHideInteract = false
		-- end
	-- end)

	Event.Reg(self, "FOCUS_FACE_STATUS_CHANGE", function(bInFaceState)
		self.bInFaceState = bInFaceState
		if bInFaceState then
			self:HideView()
		else
			self:ShowView()
		end
	end)

	Event.Reg(self, EventType.OnAccountLogout, function()
		SwitchCursor(CURSOR_PATH.DEFAULT)
	end)

	Event.Reg(self, EventType.OnRightButtonInteract, function(dwObjID, dwObjType)
		local arr = self.m.tCellDataArr
		if not arr or #arr <= 0 then
			return
		end

		local player = GetClientPlayer()
		if not player then
			return
		end

		-- 防止在寻宝死了还能打开doodad
		if BattleFieldData.IsInXunBaoBattleFieldMap() and BattleFieldData.AllowMatchPlayer() then
			local szMsg = g_tStrings.STR_CHECK_OPEN_DOODAD
			OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
			return
		end

		for nCellIndex, tCellData in ipairs(arr) do
			if not TargetMgr.bInteracted and dwObjType == TARGET.PLAYER then
				if InteractPlayer(dwObjID) then
					TargetMgr.bInteracted = true
				end
			end
			if not TargetMgr.bInteracted and dwObjType == TARGET.NPC then
				if tCellData.type == INTERACTIVE_TYPE.NPC and tCellData.id == dwObjID then
					self:OnCellClicked(nCellIndex)
					TargetMgr.bInteracted = true
					return
				end
			end
			if not TargetMgr.bInteracted and dwObjType == TARGET.DOODAD then
				if tCellData.type == INTERACTIVE_TYPE.ITEM then
					if tCellData.nDoodadId == dwObjID then
						self:OnCellClicked(nCellIndex)
						TargetMgr.bInteracted = true
						return
					end
				elseif tCellData.type == INTERACTIVE_TYPE.ITEM or tCellData.type == INTERACTIVE_TYPE.ONCE or
					tCellData.type == INTERACTIVE_TYPE.ONCE_TIME or tCellData.type == INTERACTIVE_TYPE.DIALOG then
					if tCellData.id == dwObjID then
						self:OnCellClicked(nCellIndex)
						TargetMgr.bInteracted = true
						return
					end
				end
			end
			if not TargetMgr.bInteracted and dwObjType == TARGET.FURNITURE then
				if tCellData.type == INTERACTIVE_TYPE.FURNITURE and tCellData.id == dwObjID then
					self:OnCellClicked(nCellIndex)
					TargetMgr.bInteracted = true
					return
				end
			end
		end
	end)

	Event.Reg(self, EventType.ON_ENTER_HIDE_ACTION_DYNAMIC_SKILL, function(bHide)
		self.bHideAction = bHide
	end)

	Event.Reg(self, EventType.OnGameSettingShowDoodadName, function (bVisible)
		if bVisible then
			if not self.m.nDoodadNameId then
				self.m.nDoodadNameId = Timer.AddCycle(self, 0.5, function()
					self:OnUpdateDoodadName()
				end)
			end
		else
			if self.m.nDoodadNameId then
				Timer.DelTimer(self, self.m.nDoodadNameId)
				self.m.nDoodadNameId = nil
			end
			for _, id in pairs(self.m.tShowNameDoodads) do
				Doodad_ShowBalloon(id, false)
			end
			self.m.tShowNameDoodads = {}
		end
	end)

	Event.Reg(self, EventType.CloseLootList, function()
		self:CloseLootList()
	end)
end

function UIPanelSceneInteract:OnSceneInteractByHotkey(bTakeAll)
	if UIHelper.GetVisible(self.SubRoot) and not PlotMgr.IsOpen() then
		if bTakeAll then
			local arr = self.m.tItemArr
			if arr and #arr > 0 then
				self:TakeAll()
			end
		else
			local arr = self.m.tCellDataArr
			if arr and #arr > 0 then
				self:OnCellClicked(1)
			end
		end
	end
end

function UIPanelSceneInteract:OnPickProgress(nDoodadId, nFrameCount)
	local doodad = GetDoodad(nDoodadId)
	local szName = UIHelper.GBKToUTF8(Table_GetDoodadName(doodad.dwTemplateID, doodad.dwNpcTemplateID))
	local doodadTemplate = GetDoodadTemplate(doodad.dwTemplateID)

	if doodadTemplate then
		local szBarText = Table_GetDoodadTemplateBarText(doodad.dwTemplateID)
		if szBarText ~= "" then
			szName =  UIHelper.GBKToUTF8(szBarText)
		end

		if doodadTemplate.dwCraftID ~= 0 then
			local craft = GetCraft(doodadTemplate.dwCraftID)
			if craft then
				szName = Table_GetCraftName(doodadTemplate.dwCraftID)
			end
		end
	end

	local tParam = {
		szType = "Normal",
		szFormat = szName .. "(%.2f/%.2f)",
		nDuration = nFrameCount / GLOBAL.GAME_FPS,
		--fnStop = function (bCompleted) end,
	}
	TipsHelper.PlayProgressBar(tParam)
	self.m.nProgressBarEndTime = Timer.RealtimeSinceStartup() + tParam.nDuration
end

function UIPanelSceneInteract:OnCustomProgress(szTitle, nFrameCount, nState)
	local tParam = {
		szType = "Normal",
		szFormat = szTitle,
		nDuration = nFrameCount / GLOBAL.GAME_FPS,
		--nStartVal = 0,
		--nEndVal = 100,
		--fnStop = function (bCompleted) end,
	}
	TipsHelper.PlayProgressBar(tParam)
	self.m.nProgressBarEndTime = Timer.RealtimeSinceStartup() + tParam.nDuration
end

function UIPanelSceneInteract:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end

function UIPanelSceneInteract:OnUpdate()
	-- PC端如果场景不可见，就不做刷新
	if Platform.IsWindows() and not UIMgr.IsLayerVisible(UILayer.Scene) then
		return
	end

	self:UpdateSceneObj()
	self:UpdateLootArr()
	if Platform.IsWindows() then
		self:UpdateCursor()
	end

	if not g_pClientPlayer then
		self:CloseLootList()
	end
end

function UIPanelSceneInteract:OnUpdateDoodadName()
	if not g_pClientPlayer then
		return
	end
	if self.nHideCount and self.nHideCount > 0 then
		return	-- 交互中，不显示doodad名字
	end

	local tRets = _SearchNameVisibleDoodads(g_pClientPlayer)
	local tDels = self.m.tShowNameDoodads

	self.m.tShowNameDoodads = tRets
	for _, id in pairs(tRets) do
		table.remove_value(tDels, id)
		Doodad_ShowBalloon(id, true)
	end

	for _, id in pairs(tDels) do
		Doodad_ShowBalloon(id, false)
	end
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelSceneInteract:PreloadResource()

end

function UIPanelSceneInteract:InitData()
	self.m.tDoodadArr = {}
	self.m.tNpcArr = {}
	self.m.tItemArr = {}
	self.m.tFurnitureArr = {}
	self.m.tCompassArr = {}
	self.m.tPetActionArr = {}
	self.m.tWorkbenchArr = {}
	self.m.tCellDataArr = {}
	self.m.tShowNameDoodads = {}

	self.m.bInWater = false

	self.m.tLootItemArr = {}

	self:InitScrollList()
	_LoadCfg()
end

function UIPanelSceneInteract:InitScrollList()
	self:UnInitScrollList()
	self.tScrollList = UIScrollList.Create({
		nSpace = 10,
		listNode = self.LayoutContentLess,
		fnGetCellType = function() return PREFAB_ID.WidgetInteractive end,
		fnUpdateCell = function(cell, nIndex)
			self:UpdateCell(cell, nIndex)
		end,
	})
end

function UIPanelSceneInteract:UnInitScrollList()
	if self.tScrollList then
		self.tScrollList:Destroy()
		self.tScrollList = nil
	end
end

-- tLootItem = {id =, nDoodadId =,} id为0表示金币
function UIPanelSceneInteract:AddLootArr(tLootItem)
	for _, tItem in ipairs(self.m.tLootItemArr) do
		if tItem.nDoodadID == tLootItem.nDoodadID and tItem.id == tLootItem.id then return end
	end
	table.insert(self.m.tLootItemArr, tLootItem)
end

function UIPanelSceneInteract:UpdateLootArr()
	local nTime = GetCurrentTime()
	if self.m.nWaitEndTime then
		if nTime > self.m.nWaitEndTime then -- 延时已到, 清理
			self.m.nWaitEndTime = nil
		else
			return -- 延时未到, 暂不处理
		end
	end

	local arr = self.m.tLootItemArr
	local nCount = #arr
	if nCount == 0 then return end

	if nCount > 10 then
		LOG.DEBUG("A lot of request in tLootItemArr=%d, check it", nCount)
		-- LOG.ERROR("A lot of request in tLootItemArr, check it")
	end

	local player = g_pClientPlayer
	if not player then return end

	local nMaxCount = nCount
	if nMaxCount > 30 then nMaxCount = 30 end
	for i = nMaxCount, 1, -1 do
		local tLootItem = arr[i]
		if tLootItem.id > 0 and AuctionData.NeedOpenAuctionView(tLootItem.nDoodadId, tLootItem.id) then
			local doodad = GetDoodad(tLootItem.nDoodadId)
			if doodad then OpenDoodad(player, doodad) end

			AuctionData.OnOpenDoodad(tLootItem.nDoodadId)
			AuctionData.TryOpenAuctionView()
			table.remove(arr, i)
		elseif DungeonData.CanMobileLoot(tLootItem.nDoodadId, tLootItem.id) then
			if tLootItem.id == 0 then
				LOG.INFO("----> LootMoney: nDoodadId = %d", tLootItem.nDoodadId)
				LootMoney(tLootItem.nDoodadId)
			else
				LOG.INFO("----> LootItem: nDoodadId = %d, nItemId = %d", tLootItem.nDoodadId, tLootItem.id)
				LootItem(tLootItem.nDoodadId, tLootItem.id)
			end
			table.remove(arr, i)
		elseif _tOpenedDoodadIds[tLootItem.nDoodadId] then
			---[[
			if tLootItem.id == 0 then
				LOG.INFO("----> LootMoney: nDoodadId = %d", tLootItem.nDoodadId)
				LootMoney(tLootItem.nDoodadId)
			else
				LOG.INFO("----> LootItem: nDoodadId = %d, nItemId = %d", tLootItem.nDoodadId, tLootItem.id)
				LootItem(tLootItem.nDoodadId, tLootItem.id)
			end
			table.remove(arr, i)
			--]]
		else
			local doodad = GetDoodad(tLootItem.nDoodadId)
			-- 已经尝试过, 不成功
			if tLootItem.bTryOpen or not doodad then
				table.remove(arr, i) -- 放弃
			else
				if not self.m.nWaitEndTime then -- 一次只允许打开一个
					if OpenDoodad(player, doodad) then
						tLootItem.bTryOpen = true
						self.m.nWaitEndTime = nTime + Def.nWaitDoodadOpenTime
					end
				end
			end
		end
	end
end

function UIPanelSceneInteract:UpdateList(tCellDataArr)
	self.m.tCellDataArr = tCellDataArr
	local nCellCount = #tCellDataArr

	for _, tData in ipairs(self.tTeachData or {}) do
		if tData.CellBtn and tData.CellBtn._nTeachID then
			TeachEvent.TeachClose(tData.CellBtn._nTeachID) --按钮刷新时强制结束教学
		end
	end

	self.tTeachData = {}

	UIHelper.SetHeight(self.LayoutContentLess, self.nListOriginHeight)
	self.tScrollList:UpdateListSize()
	self.tScrollList:UpdateContentPos()
	self.tScrollList:Reset(nCellCount)
	local nListHeight = self.tScrollList:GetSizeOfCells()

	if nCellCount <= 4 then
		--减小Layout大小，防止空白区域挡住后面场景点不了
		UIHelper.SetHeight(self.LayoutContentLess, nListHeight)
		self.tScrollList:UpdateListSize()
		self.tScrollList:UpdateContentPos()
	end

	local nPickCount = 0
	for i = 1, nCellCount do
		local tCellData = tCellDataArr[i]
		if tCellData.type == INTERACTIVE_TYPE.ITEM then
			nPickCount = nPickCount + 1
		end
	end

	-- local bUseLayout = nCellCount > 0 and nCellCount <= 4
	local bEmpty = nCellCount == 0

	-- 全部拾取按钮
	UIHelper.SetVisible(self.TakeAllBtn, nPickCount >= 2)
	if UIHelper.GetVisible(self.TakeAllBtn) then
		local y = UIHelper.GetPositionY(self.LayoutContentLess)
		local nListH = UIHelper.GetHeight(self.LayoutContentLess)
		local nBtnH = UIHelper.GetHeight(self.TakeAllBtn)
		UIHelper.SetPositionY(self.TakeAllBtn, y - nListH - nBtnH / 2 - 10)
	end

	UIHelper.SetVisible(self.BtnGetAll, nPickCount >= 1 and nPickCount <= 4)
	UIHelper.SetPositionY(self.BtnGetAll, -nListHeight, self.LayoutContentLess)

	UIHelper.SetVisible(self.LayoutContentLess, not bEmpty)
	-- if bUseLayout then
		-- UIHelper.LayoutDoLayout(self.LayoutContentLess)
	-- end

	-- 教学 交互按钮出现
	for _, tData in pairs(self.tTeachData) do
		FireHelpEvent("OnBtnInteractiveShow", tData.type, tData.id, tData.nQuestState, tData.CellBtn)
	end
end

function UIPanelSceneInteract:UpdateCell(tScript, nCellIndex)
	local tCellData = self.m.tCellDataArr[nCellIndex]

	-- 教学 交互按钮出现，且排除掉相同教学按钮
	local bSame = false
	for _, tData in pairs(self.tTeachData) do
		if tData.type == tCellData.type then
			if tCellData.type == INTERACTIVE_TYPE.FURNITURE then --家具
				if tData.modelid == tCellData.modelid then
					bSame = true
				end
			elseif tCellData.type == INTERACTIVE_TYPE.ONCE or tCellData.type == INTERACTIVE_TYPE.ONCE_TIME or
					tCellData.type == INTERACTIVE_TYPE.DIALOG or tCellData.type == INTERACTIVE_TYPE.WORKBENCH then --Doodad
				local tDoodad = GetDoodad(tData.id)
				local tCellDoodad = GetDoodad(tCellData.id)
				if tDoodad and tCellDoodad and tDoodad.dwTemplateID == tCellDoodad.dwTemplateID then
					bSame = true
				end
			end
		end
	end

	if not bSame then
		local tData = {
			type = tCellData.type,
			id = tCellData.id,
			modelid = tCellData.modelid,
			nQuestState = tScript.nQuestState,
			CellBtn = tScript.CellBtn
		}
		table.insert(self.tTeachData, tData)
	end

	-- Label
	UIHelper.RemoveAllChildren(tScript.Label)
	---- 货币
	if tCellData.id == 0 then
		UIHelper.SetString(tScript.Label, "")
		UIHelper.SetMoneyText(tScript.Label, tCellData.nCount)
		---- 有操作描述
	elseif tCellData.szTitle then
		local sz = tCellData.szTitle
		if tCellData.title and tCellData.title ~= "" then
			-- sz = sz .. "(" .. tCellData.title .. ")"
			sz = tCellData.title
		end
		sz = UIHelper.LimitUtf8Len(sz, 9)
		UIHelper.SetString(tScript.Label, sz)
		---- 只有标题
	else
		local sz = UIHelper.LimitUtf8Len(tCellData.title, 8)
		UIHelper.SetString(tScript.Label, sz)
	end

	-- Icon
	UIHelper.SetVisible(tScript.Icon, false)
	UIHelper.SetVisible(tScript.WidgerIconItem, false)
	if tCellData.type == INTERACTIVE_TYPE.NPC then
		UIHelper.SetVisible(tScript.Icon, true)
		UIHelper.SetSpriteFrame(tScript.Icon, tCellData.imageFrame)
	elseif tCellData.type == INTERACTIVE_TYPE.ITEM then
		if tCellData.id == 0 then -- money
			UIHelper.SetVisible(tScript.WidgerIconItem, true)
			local tItemScript = UIHelper.AddItemIconPrefab_Small(tScript.WidgerIconItem)
			assert(tItemScript)
			UIHelper.InitItemIcon_Money(tItemScript, tCellData.nCount)
		else
			UIHelper.SetVisible(tScript.WidgerIconItem, true)
			local tItemScript = UIHelper.AddItemIconPrefab_Small(tScript.WidgerIconItem)
			assert(tItemScript)
			local item = GetItem(tCellData.id)
			assert(item, "fail to get item by id: " .. tCellData.id)
			UIHelper.InitItemIcon(tItemScript, item, tCellData.nCount)
		end
	elseif tCellData.type == INTERACTIVE_TYPE.COMPASS then
		UIHelper.SetVisible(tScript.Icon, true)
		UIHelper.SetSpriteFrame(tScript.Icon, "UIAtlas2_Public_PublicIcon_PublicIcon1_btn_wabao.png")
	elseif tCellData.type == INTERACTIVE_TYPE.ONCE_TIME or tCellData.type == INTERACTIVE_TYPE.DIALOG then
		UIHelper.SetVisible(tScript.Icon, true)
		UIHelper.SetSpriteFrame(tScript.Icon, tCellData.imageFrame)
	else
		UIHelper.SetVisible(tScript.Icon, true)
		UIHelper.SetSpriteFrame(tScript.Icon, "UIAtlas2_Public_PublicIcon_PublicIcon1_btn_shiqu.png")
	end


	if tCellData.imageFrameBg then
		UIHelper.SetSpriteFrame(tScript.ImgBg, tCellData.imageFrameBg)
	else
		UIHelper.SetSpriteFrame(tScript.ImgBg, szDefaultBg)
	end



	if tScript.nCellIndex then
		UIHelper.UnBindUIEvent(tScript.CellBtn, EventType.OnClick)
	end

	-- 添加事件
	tScript.nCellIndex = nCellIndex
	UIHelper.BindUIEvent(tScript.CellBtn, EventType.OnClick, function()
		self:OnCellClicked(tScript.nCellIndex)
	end)

	--全部自动拾取
	local bPickupAll = GameSettingData.GetNewValue(UISettingKey.AutoLootAll)
	if bPickupAll and tCellData.type == INTERACTIVE_TYPE.ITEM then
		local tItemArr = self.m.tItemArr
		if tItemArr and #tItemArr > 0 then
			self:AutoTakeAll()
		end
		-- local tCellDataArr = self.m.tCellDataArr
		-- if tCellDataArr and #tCellDataArr > 0 then
		-- 	self:OnCellClicked(1)
		-- end
	end

	local bHasTitle = tCellData and ((tCellData.szTitle and tCellData.sztitle ~= "") or (tCellData.title and tCellData.title ~= ""))
	UIHelper.SetVisible(tScript._rootNode, bHasTitle)

	local scriptView = UIHelper.GetBindScript(tScript.WidgetKeyBoardKey)
	scriptView:SetID(nCellIndex == 1 and 20 or -1)
	scriptView:RefreshUI()

end

function UIPanelSceneInteract:OnCellClicked(nCellIndex)
	assert(nCellIndex)
	local tCellData = self.m.tCellDataArr[nCellIndex]
	assert(tCellData)
	--print("OnCellClicked", tCellData.type, tCellData.id)

	if tCellData.type == INTERACTIVE_TYPE.NPC then
		if QTEMgr.CanCastSkill() then--右下角在动态技能，不允许切换
			SprintData.SetViewState(true)
		end
		SelectTarget(TARGET.NPC, tCellData.id)
		InteractNpc(tCellData.id)
	elseif tCellData.type == INTERACTIVE_TYPE.ITEM then
		if DungeonData.IsInDungeon() and TeamData.IsPlayerInTeam(UI_GetClientPlayerID()) and GetClientTeam().nLootMode ~= PARTY_LOOT_MODE.FREE_FOR_ALL then
			self:TakeAll() -- 阿翠需求，在副本中处于组队非自由拾取模式，则点击任意掉落道具都视为全部拾取
		else
			for _, tData in pairs(tCellData.tLootData) do
				local nDoodadId = tData[1]
				local nItemId = tData[2]
				if nItemId == 0 then -- money
					self:LootMoney(nDoodadId)
				else
					self:LootItem(nDoodadId, nItemId)
					if BattleFieldData.IsInXunBaoBattleFieldMap() and TravellingBagData.CheckIsFull() then
						UIMgr.OpenSingle(false, VIEW_ID.PanelBattleFieldXunBao, ExtractViewType.BagAndLoot, nDoodadId)
					elseif AuctionData.tPickedDoodads[nDoodadId] and not UIMgr.IsViewOpened(VIEW_ID.PanelTeamAuction) then
						AuctionData.OnOpenDoodad(nDoodadId)
						AuctionData.TryOpenAuctionView()
					end
				end
			end
		end
	elseif tCellData.type == INTERACTIVE_TYPE.FURNITURE then
		InteractLandObject(tCellData.id, true)
	elseif tCellData.type == INTERACTIVE_TYPE.COMPASS then
		RemoteCallToServer("On_Xunbao_HoroDigRequest")
	elseif tCellData.type == INTERACTIVE_TYPE.PETACTION then
		local tPet = g_pClientPlayer.GetFellowPet()
		if tPet then
			local hPetIndex = GetFellowPetIndexByNpcTemplateID(tPet.dwTemplateID)
			if hPetIndex and hPetIndex ~= 0 then
				local tSkill = Table_GetFellowPetSkill(hPetIndex)
				if tSkill then
					local tbSkilllist = {}
					for _, tSkillData in ipairs(tSkill) do
						local skill = {
							id = tSkillData[1],
							level = tSkillData[2],
							bPetAction = true
						}
						table.insert(tbSkilllist, skill)
					end
					local tbSKillInfo = {
						CanCastSkill = false,
						canuserchange = true,
						tbSkilllist = tbSkilllist,
					}
					QTEMgr.OnSwitchDynamicSkillStateBySkills(tbSKillInfo)
				end
			end
		end
	elseif tCellData.type == INTERACTIVE_TYPE.WORKBENCH then
		CraftData.OpenManufactureViewWithDoodadTemplateID(tCellData.doodadTemplateID)
	else
		_PickDoodads(tCellData)
	end
end

function UIPanelSceneInteract:UpdateSceneObj()
	local player = g_pClientPlayer
	if not player then return end

	local tDoodadArr, tItemArr = _SearchDoodad(player)
	local tNpcArr = _SearchNpc(player)
	local tWorkbenchArr = _SearchWorkbench(player)
	local tFurnitureArr = _SearchFurniture() or {}
	local tCompassArr = _SearchCompass() or {}
	local tPetActionArr = _SearchPetAction() or {}

	local bInWater = false --IsInSwimming()
	local bEmpty = false
	local nProgressBarEndTime = self.m.nProgressBarEndTime
	local bPlayingProgressBar = nProgressBarEndTime and nProgressBarEndTime > Timer.RealtimeSinceStartup()

	if (#tDoodadArr > 0) or (#tItemArr > 0) then
		tPetActionArr = {}
	end

	if #tDoodadArr <= 0 and #tNpcArr <= 0 and #tItemArr <= 0 and #tFurnitureArr <= 0 and not bInWater and  #tCompassArr <= 0 and  #tPetActionArr <= 0 and #tWorkbenchArr <= 0 then
		bEmpty = true
	end

	if self.bHideAction then
		bEmpty = true
	end

	-- 设置列表是否可见
	--ShowNewAutoSearch(not bEmpty) ????
	local bTreasureBattleHide = BattleFieldData.IsInTreasureBattleFieldMap() and player.nMoveState == MOVE_STATE.ON_DEATH
	UIHelper.SetVisible(self.SubRoot, not bEmpty and not bPlayingProgressBar and not bTreasureBattleHide and not SelfieData.IsInStudioMap())

	-- 若没有变化, 无需刷新（若刷新会触发与交互键相关的教学刷新）；考虑到交互按钮需要根据距离排序，这里如果距离变化了也会刷新
	if _Equal(tDoodadArr, self.m.tDoodadArr)
		and _Equal(tNpcArr, self.m.tNpcArr)
		and _Equal(tFurnitureArr, self.m.tFurnitureArr)
		and _Equal(tItemArr, self.m.tItemArr)
		and bInWater == self.m.bInWater
		and _Equal(tCompassArr, self.m.tCompassArr)
		and _Equal(tPetActionArr, self.m.tPetActionArr)
		and _Equal(tWorkbenchArr, self.m.tWorkbenchArr) then
		return
	end

	self.m.tDoodadArr = tDoodadArr
	self.m.tNpcArr = tNpcArr
	self.m.tFurnitureArr = tFurnitureArr
	self.m.tCompassArr = tCompassArr
	self.m.tPetActionArr = tPetActionArr
	self.m.tWorkbenchArr = tWorkbenchArr
	self.m.tItemArr = tItemArr
	self.m.bInWater = bInWater


	local tCellDataArr = {}
	for _, tNpc in ipairs(tNpcArr) do
		table.insert(tCellDataArr, tNpc)
	end
	for _, tDoodad in ipairs(tDoodadArr) do
		table.insert(tCellDataArr, tDoodad)
	end
	for _, tFurniture in ipairs(tFurnitureArr) do
		table.insert(tCellDataArr, tFurniture)
	end
	for _, tCompass in ipairs(tCompassArr) do
		table.insert(tCellDataArr, tCompass)
	end
	for _, tPetAction in ipairs(tPetActionArr) do
		table.insert(tCellDataArr, tPetAction)
	end
	for _, tWorkbench in ipairs(tWorkbenchArr) do
		table.insert(tCellDataArr, tWorkbench)
	end
	for _, tItem in ipairs(tItemArr) do
		table.insert(tCellDataArr, tItem)
	end

	-- 排序
	self:SortCellDataArr(tCellDataArr)

	--若整体无变化，也不刷新
	if _Equal(tCellDataArr, self.m.tCellDataArr, true) then
		return
	end

	-- 刷新UI
	self.m.bNoninteractiveUpdate = true
	self:UpdateList(tCellDataArr)
	self.m.bNoninteractiveUpdate = false

	Event.Dispatch(EventType.OnInteractListUpdate, bEmpty, (tNpcArr[1] and tNpcArr[1].id or 0))
end


function UIPanelSceneInteract:GetCellPriority(tbInfo)
	local nType = SORT_TYPE.NONE
	if tbInfo.nObjType == OBJ_TYPE.ITEM then
		nType = SORT_TYPE.ITEM
	end

	local bPriorityInAutoSearch = tbInfo.dwTemplateID and Table_IsPriorityInAutoSearch(tbInfo.nObjType, tbInfo.dwTemplateID)

	if tbInfo.nObjType == OBJ_TYPE.NPC then
		nType = QUESTSTAET_PRIORITY[tbInfo.nQuestState]
		if tbInfo.bBindQuest then
			nType = SORT_TYPE.NPC_DIALOGUE
		elseif tbInfo.nQuestState == Def.QuestState.None and bPriorityInAutoSearch then
			nType = SORT_TYPE.NPC_PRIORITY
		elseif tbInfo.bEmployer then
			nType = SORT_TYPE.NPC_EMPLOYER
		end
	end

	if tbInfo.nObjType == OBJ_TYPE.FURNITURE then
		nType = SORT_TYPE.FURNITURE
	end

	if tbInfo.nObjType == OBJ_TYPE.DOODAD then
		nType = SORT_TYPE.DOODAD_NORMAL
		if tbInfo.bBindQuest then
			nType = SORT_TYPE.DOODAD_QUEST
		elseif bPriorityInAutoSearch then
			nType = SORT_TYPE.DOODAD_PRIORITY
		end
	end

	return SORT_PRIORITY_VALUE[nType]

end

function UIPanelSceneInteract:SortCellDataArr(tCellDataArr)

	--根据条件设置权重
	table.sort(tCellDataArr, function (tA, tB)
		local nPriorityA = self:GetCellPriority(tA)
		local nPriorityB = self:GetCellPriority(tB)

		if nPriorityA ~= nPriorityB then
			return nPriorityA > nPriorityB
		else
			--同类型由近及远
			if tA.fDistances and tB.fDistances then
				return tA.fDistances < tB.fDistances
			end
			return false
		end
	end)
end

function UIPanelSceneInteract:TryPickup(nDoodadId)
	local doodad = GetDoodad(nDoodadId)
	if not doodad then
		return
	end
	local nKind = doodad.nKind
	if nKind == DOODAD_KIND.QUEST
		or nKind == DOODAD_KIND.TREASURE
	then
		local player = g_pClientPlayer
		if not player then return end

		local scene = player.GetScene()
		if not scene then return end

		local tAllLootItemInfo = scene.GetLootList(nDoodadId)
		if not tAllLootItemInfo then return end

		local nMoney = scene.GetLootMoney(nDoodadId)
		if nMoney and nMoney > 0 then
			self:LootMoney(nDoodadId)
		end

		local nLootItemCount = tAllLootItemInfo and tAllLootItemInfo.nItemCount or 0
		local tItemIDList = {}
		for i = 0, nLootItemCount - 1 do
			local tLootInfo = DungeonData.GetLootItemByIndex(nDoodadId, i) or {}
			local item = tLootInfo.Item
			if item then
				table.insert(tItemIDList, item.dwID)
			end
		end
		local bTreasureBattle = BattleFieldData.IsInTreasureBattleFieldMap()
		for i = 0, nLootItemCount - 1 do
			local tLootInfo = DungeonData.GetLootItemByIndex(nDoodadId, i) or {}
			local item = tLootInfo.Item
			local eType = tLootInfo.LootType
			local bNeedRoll = eType == LOOT_ITEM_TYPE.NEED_ROLL
			local bNeedDistribute = eType == LOOT_ITEM_TYPE.NEED_DISTRIBUTE
			local bNeedBidding = eType == LOOT_ITEM_TYPE.NEED_BIDDING
			-- local item, bNeedRoll, bNeedDistribute, bNeedBidding = DungeonData.GetLootItemByIndex(nDoodadId, i)
			if item then
				if bTreasureBattle then
					-- 吃鸡自动拾取
					if TreasureBattleFieldData.CheckAutoLoot(item, tItemIDList) then
						self:LootItem(nDoodadId, item.dwID)
					end
				else
					if item and not bNeedRoll and not bNeedDistribute and not bNeedBidding then
						self:LootItem(nDoodadId, item.dwID)
					end
				end
			end
		end
	end
end

local bHit = false
local function _forEachValidNode(node, func)
	if bHit then
		return -- 找到UI节点则不再继续查找
	end

	if not node then
		return  -- 筛选widget
	end

	if node:getName() == "PanelHoverTips" then
		return
	end
	if node:getName() == "PanelNodeExplorer" then
		return
	end
	if not UIHelper.GetVisible(node) then
		return
	end
	if node.isEnabled and not node:isEnabled() then
		return
	end

	local aChildren = node:getChildren()
	if aChildren then
		for i = 1, #aChildren do
			local childNode = aChildren[i]
			if UIHelper.GetVisible(childNode) and (not childNode.isEnabled or childNode:isEnabled()) then
				func(childNode)
				_forEachValidNode(childNode, func)
			end
		end
	end
end

function UIPanelSceneInteract:UpdateCursor()
	local player = GetClientPlayer()
	if not player then
		return
	end

	self.szLastCursor = self.szLastCursor or CURSOR_PATH.DEFAULT
	local szNewCursor = CURSOR_PATH.DEFAULT
	local tCursor = GetViewCursorPoint()
	local tPos = cc.Director:getInstance():convertToGL({ x = tCursor.x, y = tCursor.y })

	bHit = false
	local sceneNode = cc.Director:getInstance():getRunningScene()
	local camera = sceneNode:getDefaultCamera()

	if UIMgr.IsViewOpened(VIEW_ID.PanelCharacter) or ItemData.GetBagScript() then
		bHit = true -- 玩家信息界面特判 直接显示默认指针
	else
		-- 遍历所有节点
		_forEachValidNode(sceneNode, function(node)
			if node.hitTest and node:hitTest(tCursor, camera) then
				if node:isClippingParentContainsPoint(tCursor) and (node.SetScene or (node.isSwallowTouches and node:isSwallowTouches())) then
					bHit = true --遇到 swallowTouches 或者 miniscene则视为点击ui界面
				end
			end
		end)
	end

	if not bHit then
		local dwPlayerID = player.dwID
		local nScaleX, nScaleY = UIHelper.GetScreenToResolutionScale()
		local tSelectObject = Scene_SelectObjectsX3D(tPos.x * nScaleX, tPos.y * nScaleY)
		local nTargetType, nTargetID = TARGET.NO_TARGET, 0
		for _, obj in pairs(tSelectObject or {}) do
			nTargetType, nTargetID = obj.Type, obj.ID
			if nTargetType == TARGET.DOODAD then
				local doodad = GetDoodad(obj.ID)
				local doodadTemp = GetDoodadTemplate(doodad.dwTemplateID)
				-- local szType, szTitle, nFrame = _CheckDoodad(doodad, player)
				local bCan = doodad.CanDialog(player)
				if doodad.nKind == DOODAD_KIND.CRAFT_MINERAL then
					szNewCursor = bCan and CURSOR_PATH.MINERAL or CURSOR_PATH.UNABLE_MINERAL
					break
				elseif doodad.nKind == DOODAD_KIND.READ then
					szNewCursor = bCan and CURSOR_PATH.READ or CURSOR_PATH.UNABLE_READ
					break
				elseif doodad.nKind == DOODAD_KIND.CRAFT_HERB then
					szNewCursor = bCan and CURSOR_PATH.FLOWER or CURSOR_PATH.UNABLE_FLOWER
					break
				elseif doodad.nKind == DOODAD_KIND.TREASURE then
					szNewCursor = bCan and CURSOR_PATH.LOCK or CURSOR_PATH.UNABLE_LOCK
					break
				elseif doodad.nKind == DOODAD_KIND.CORPSE or doodad.nKind == DOODAD_KIND.NPCDROP then
					if doodad.CanLoot(dwPlayerID) then
						szNewCursor = bCan and CURSOR_PATH.LOOT or CURSOR_PATH.UNABLE_LOOT --拾取
						break
					end
					if doodad.CanSearch() then
						local doodadTemp = GetDoodadTemplate(doodad.dwTemplateID)
						if doodadTemp and doodadTemp.dwCraftID == 3 and player.IsProfessionLearnedByCraftID(doodadTemp.dwCraftID) then
							szNewCursor = bCan and CURSOR_PATH.SEARCH or CURSOR_PATH.UNABLE_SEARCH --搜索
							break
						end
					end
					break
				elseif doodad.nKind == DOODAD_KIND.CRAFT_TARGET then
					if doodadTemp and player.IsProfessionLearnedByCraftID(doodadTemp.dwCraftID) then
						if doodadTemp.dwCraftID == 1 then
							szNewCursor = bCan and CURSOR_PATH.MINERAL or CURSOR_PATH.UNABLE_MINERAL --采矿
							break
						elseif doodadTemp.dwCraftID == 2 then
							szNewCursor = bCan and CURSOR_PATH.FLOWER or CURSOR_PATH.UNABLE_FLOWER --采花
							break
						elseif doodadTemp.dwCraftID == 3 then
							szNewCursor = bCan and CURSOR_PATH.SEARCH or CURSOR_PATH.UNABLE_SEARCH --庖丁
							break
						elseif doodadTemp.dwCraftID == 8 then
							szNewCursor = bCan and CURSOR_PATH.READ or CURSOR_PATH.UNABLE_READ --阅读
							break
						end
					end
				end
			elseif nTargetType == TARGET.FURNITURE then
				szNewCursor = CURSOR_PATH.SEARCH
			end

			local nSelfID = player.dwID
			local nRelation = GetRelation(nSelfID, nTargetID)
			if nTargetType == TARGET.NPC then
				local npc = GetNpc(nTargetID)
				if npc and npc.IsSelectable() then
					if kmath.bit_and(nRelation, RELATION_TYPE.ENEMY) ~= 0 then
						szNewCursor = CURSOR_PATH.ATTACK
						break
					else
						local bCan = npc.CanDialog(player)
						szNewCursor = bCan and CURSOR_PATH.SPEAK or CURSOR_PATH.UNABLE_SPEAK  --说话
						break
					end
				end
			end

			if nTargetType == TARGET.PLAYER then
				local player = GetPlayer(nTargetID)
				if player and player.IsSelectable() then
					if kmath.bit_and(nRelation, RELATION_TYPE.ENEMY) ~= 0 then
						szNewCursor = CURSOR_PATH.ATTACK
						break
					end
				end
			end
		end
	end

	if szNewCursor ~= self.szLastCursor then
		self.szLastCursor = szNewCursor
		SwitchCursor(self.szLastCursor)
	end
end

function UIPanelSceneInteract:ShowView()
	if not self.nHideCount then return end
	self.nHideCount = self.nHideCount - 1
	if self.nHideCount == 0 then
		UIMgr.ShowView(self._nViewID)
	end
end

function UIPanelSceneInteract:HideView()
	if not self.nHideCount then self.nHideCount = 0 end
	self.nHideCount = self.nHideCount + 1
	if self.nHideCount == 1 then
		UIMgr.HideView(self._nViewID)

		-- 隐藏显示的doodad名字
		for _, id in pairs(self.m.tShowNameDoodads) do
			Doodad_ShowBalloon(id, false)
		end
		self.m.tShowNameDoodads = {}
	end
end

function UIPanelSceneInteract:CloseLootList()
	--CloseLootList()
	if not g_pClientPlayer then
		return
	end

	_tOpenedDoodadIds = {}
	g_pClientPlayer.OnCloseLootWindow()
end

return UIPanelSceneInteract
