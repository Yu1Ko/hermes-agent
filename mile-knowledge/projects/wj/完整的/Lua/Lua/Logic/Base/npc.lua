--TODO: xt-2022.11.23
-- 这里的逻辑功能逐步挪到NpcData.lua中
-- 且数据则存储到NpcData中


--[[
local tNpcList = {}
local tNpcHaveQuest = {}
local tSimplePlayerInfo = {}
local _bRegFree = nil
local tinsert = table.insert
local tconcat = table.concat

g_bHideQuestShowFlag = true
RegisterCustomData("g_bHideQuestShowFlag")

function SetHideQuestShow(bShow)
	g_bHideQuestShowFlag = bShow
	UpdateAllNpcTitleEffect()
end

function IsHideQuestShow()
	return g_bHideQuestShowFlag
end

function OnNpcEnterScene(dwNpcID)
	table.insert(tNpcList, dwNpcID)

	if IsSimplePlayer(dwNpcID) then
		local hNpc = GetNpc(dwNpcID)
		local hPlayer = {}
		hPlayer.dwID = hNpc.dwEmployer
		GetSimplePlayerInfo(hNpc.dwEmployer)
		tSimplePlayerInfo[dwNpcID] = hPlayer
	end
	regionPQPanel.OnNpcEnterScene(dwNpcID)
end

function OnNpcLeaveScene(dwNpcID)
	for key, value in pairs(tNpcList) do
		if value == dwNpcID then
			table.remove(tNpcList, key)
			tNpcHaveQuest[dwNpcID] = nil
			break
		end
	end

	local hPlayer = tSimplePlayerInfo[dwNpcID]
	if hPlayer then
		tSimplePlayerInfo[dwNpcID] = nil
	end
	regionPQPanel.OnNpcLeaveScene(dwNpcID)
end

do
local l_tSimplePlayerNpc = {}
function GetSimplePlayerNpc(dwID)
	if not l_tSimplePlayerNpc[dwID] then
		local KNpc = GetNpc(dwID)
		l_tSimplePlayerNpc[dwID] = setmetatable({}, {
			__index = function(t, key)
				return KNpc[key]
			end,
		})
	end
	return l_tSimplePlayerNpc[dwID]
end

RegisterEvent("NPC_LEAVE_SCENE", function()
	l_tSimplePlayerNpc[arg0] = nil
end)
end

function OnGetSimplePlayerInfo()
 	local nPlayerID = arg0
 	for dwNpcID, t in pairs(tSimplePlayerInfo) do
		if t.dwID == nPlayerID then
			t.dwID 				= arg0
			t.nLevel 			= arg1
			t.nCamp 			= arg2
			t.bCampFlag 		= arg3
			t.bFightState 		= arg4
			t.dwMiniAvatarID	= arg5
			t.dwForceID 		= arg6
			t.dwMountKungfuID 	= arg7
			t.nRoleType       	= arg8
			t.szName 			= arg9
			Character_SetEmployer(dwNpcID, t.szName)
		end
	end
end

function GetNpcSimplePlayerInfo(dwNpcID)
	return tSimplePlayerInfo[dwNpcID]
end

--RegisterEvent("GET_SIMPLE_PLAYER_INFO", OnGetSimplePlayerInfo)

function UpdateAllNpcTitleEffect()
	for _, dwNpcID in pairs(tNpcList) do
		UpdateNpcTitleEffect(dwNpcID)
	end
end

function GetNpcList()
	return tNpcList
end

--]]

local QUEST_MARK = -- see "represent/common/global_effect.txt"
{
	["normal_unaccept_proper"] = 1,
	["repeat_unaccept_proper"] = 2,
	["activity_unaccept_proper"] = 45,
	["unaccept_high"] = 5,
    ["main_unfinished"] = 6,
	-- ["unaccept_low"] = 6,
	["unaccept_lower"] = 43,
	["accpeted"] = 44,
	["normal_finished"] = 3,
	["repeat_finished"] = 4,
	["activity_finished"] = 46,
	["normal_notneedaccept"] = 44,
	["repeat_notneedaccept"] = 4,
	["activity_notneedaccept"] = 46,
	["lishijie_unaccept"] = 55,
	["lishijie_finished"] = 54,
}

local tinsert = table.insert
local tconcat = table.concat

local _aBlank = {}
local _aQuestState = {}
function GetNpcQuestState(hNpc, getquestid)
	if not hNpc then
		return _aBlank
	end

	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return _aBlank
	end

	if IsEnemy(hPlayer.dwID, hNpc.dwID) then
		return _aBlank
	end

	if not hNpc.bDialogFlag then
		return _aBlank
	end

	local aQuestList = hNpc.GetNpcQuest()

	if not aQuestList or #aQuestList == 0 then
		return _aBlank
	end

	for k, _ in pairs(_aQuestState) do
		_aQuestState[k] = nil
	end

	for _, dwQuestID in pairs(aQuestList) do
		-- 任务是否可交或可接
		if _aQuestState.szStatus ~= "CanFinish" then
			if QuestData.CanFinishQuest(dwQuestID, TARGET.NPC, hNpc.dwID) then
				_aQuestState.szStatus = "CanFinish"
			elseif QuestData.CanAcceptQuest(dwQuestID, TARGET.NPC, hNpc.dwID) then
				_aQuestState.szStatus = "CanAccept"
			end
		end

		local tQuestStringInfo = Table_GetQuestStringInfo(dwQuestID)
		if not tQuestStringInfo then
			return _aQuestState
		end
        if tQuestStringInfo.nChapterID ~= 0 and hPlayer.CanFinishQuest(dwQuestID, TARGET.NPC, hNpc.dwID) ~= QUEST_RESULT.SUCCESS then
            _aQuestState["main_unfinished"] = true
		elseif tQuestStringInfo.IsAdventure ~= 1 then
			local hQuestInfo = GetQuestInfo(dwQuestID)
			if hQuestInfo then
				local szKey = nil
                if hQuestInfo.bActivity then
                    szKey = "activity"
                elseif hQuestInfo.bRepeat then
                    szKey = "repeat"
                else
                    szKey = "normal"
                end

				local eCanFinish = hPlayer.CanFinishQuest(dwQuestID, TARGET.NPC, hNpc.dwID)
				local eCanAccept = hPlayer.CanAcceptQuest(dwQuestID, TARGET.NPC, hNpc.dwID)

				if eCanFinish == QUEST_RESULT.SUCCESS then
					szKey = szKey .. "_finished"
				elseif eCanAccept == QUEST_RESULT.NO_NEED_ACCEPT
				and eCanFinish ~= QUEST_RESULT.TOO_LOW_LEVEL
				and eCanFinish ~= QUEST_RESULT.PREQUEST_UNFINISHED
				and eCanFinish ~= QUEST_RESULT.ERROR_REPUTE
				and eCanFinish ~= QUEST_RESULT.ERROR_CAMP
				and eCanFinish ~= QUEST_RESULT.ERROR_GENDER
				and eCanFinish ~= QUEST_RESULT.ERROR_ROLETYPE
				and eCanFinish ~= QUEST_RESULT.ERROR_FORCE_ID
				and eCanFinish ~= QUEST_RESULT.ERROR_QUEST_STATE
				and eCanFinish ~= QUEST_RESULT.COOLDOWN
				and eCanFinish ~= QUEST_RESULT.ERROR_REPUTE then
					szKey = szKey .. "_notneedaccept"
				elseif eCanAccept == QUEST_RESULT.SUCCESS
				and hQuestInfo.dwStartNpcTemplateID == hNpc.dwTemplateID then
					szKey = szKey .. "_unaccept"
				elseif eCanAccept == QUEST_RESULT.ALREADY_ACCEPTED
				and hQuestInfo.dwEndNpcTemplateID == hNpc.dwTemplateID then
					szKey = szKey .. "_accepted"
				else
					szKey = szKey .. "_none"
				end

				local nDifficult = hPlayer.GetQuestDiffcultyLevel(dwQuestID)
				if nDifficult == QUEST_DIFFICULTY_LEVEL.PROPER_LEVEL then
					szKey = szKey .. "_proper"
				elseif nDifficult == QUEST_DIFFICULTY_LEVEL.HIGH_LEVEL then
					szKey = szKey .. "_high"
				elseif nDifficult == QUEST_DIFFICULTY_LEVEL.HIGHER_LEVEL then
					szKey = szKey .. "_higher"
				elseif nDifficult == QUEST_DIFFICULTY_LEVEL.LOW_LEVEL then
					szKey = szKey .. "_low"
				elseif nDifficult == QUEST_DIFFICULTY_LEVEL.LOWER_LEVEL then
					szKey = szKey .. "_lower"
				end

				if getquestid and not _aQuestState[szKey] then
					_aQuestState[szKey] = {}
				end

				if getquestid then
					table.insert(_aQuestState[szKey], dwQuestID)
				else
					_aQuestState[szKey] = true
				end
			end
		end
	end

	return _aQuestState
end

--[[

function Npc_HaveQuest(dwNpcID)
	return tNpcHaveQuest[dwNpcID]
end

function UpdateNpcTitleEffect(dwNpcID)
	local nInScene = false	-- confirm the npc is in the scene or not
	for _, dwID in pairs(tNpcList) do
		if dwID == dwNpcID then
			nInScene = true
			break
		end
	end
	if not nInScene then
		return
	end

	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end

	local hNpc = GetNpc(dwNpcID)
	if not hNpc then
		return
	end

	local aQuestState = GetNpcQuestState(hNpc) or {}
	tNpcHaveQuest[dwNpcID] = nil
	if aQuestState.normal_finished_proper
	or aQuestState.normal_finished_high
	or aQuestState.normal_finished_higher
	or aQuestState.normal_finished_low
	or aQuestState.normal_finished_lower
	or aQuestState.repeat_finished_proper
	or aQuestState.repeat_finished_high
	or aQuestState.repeat_finished_higher
	or aQuestState.repeat_finished_low
	or aQuestState.repeat_finished_lower
	or aQuestState.activity_finished_proper
	or aQuestState.activity_finished_high
	or aQuestState.activity_finished_higher
	or aQuestState.activity_finished_low
	or aQuestState.activity_finished_lower then
		tNpcHaveQuest[dwNpcID] = true
		if IsInLishijie() then
			SceneObject_SetTitleEffect(TARGET.NPC, dwNpcID, QUEST_MARK.lishijie_finished)
		else
			SceneObject_SetTitleEffect(TARGET.NPC, dwNpcID, QUEST_MARK.normal_finished)
		end

		return
	end

    if aQuestState.main_unfinished then
        tNpcHaveQuest[dwNpcID] = true
        if IsInLishijie() then
            SceneObject_SetTitleEffect(TARGET.NPC, dwNpcID, QUEST_MARK.lishijie_unaccept)
        else
            SceneObject_SetTitleEffect(TARGET.NPC, dwNpcID, QUEST_MARK.main_unfinished)
        end
        return
    end

	if aQuestState.activity_unaccept_proper or aQuestState.activity_unaccept_low then
		tNpcHaveQuest[dwNpcID] = true
		if IsInLishijie() then
			SceneObject_SetTitleEffect(TARGET.NPC, dwNpcID, QUEST_MARK.lishijie_unaccept)
		else
			SceneObject_SetTitleEffect(TARGET.NPC, dwNpcID, QUEST_MARK.activity_unaccept_proper)
		end
		return
	end

	if aQuestState.normal_unaccept_proper or aQuestState.normal_unaccept_low then
		tNpcHaveQuest[dwNpcID] = true
		if IsInLishijie() then
			SceneObject_SetTitleEffect(TARGET.NPC, dwNpcID, QUEST_MARK.lishijie_unaccept)
		else
			SceneObject_SetTitleEffect(TARGET.NPC, dwNpcID, QUEST_MARK.normal_unaccept_proper)
		end
		return
	end

	if aQuestState.repeat_unaccept_proper or aQuestState.repeat_unaccept_low then
		tNpcHaveQuest[dwNpcID] = true
		if IsInLishijie() then
			SceneObject_SetTitleEffect(TARGET.NPC, dwNpcID, QUEST_MARK.lishijie_unaccept)
		else
			SceneObject_SetTitleEffect(TARGET.NPC, dwNpcID, QUEST_MARK.repeat_unaccept_proper)
		end
		return
	end

	if aQuestState.activity_notneedaccept_proper
	or aQuestState.activity_notneedaccept_low
	or aQuestState.activity_notneedaccept_lower
	or aQuestState.activity_notneedaccept_high
	or aQuestState.activity_notneedaccept_higher then
		tNpcHaveQuest[dwNpcID] = true
		SceneObject_SetTitleEffect(TARGET.NPC, dwNpcID, QUEST_MARK.activity_notneedaccept)
		return
	end

	if aQuestState.repeat_notneedaccept_proper
	or aQuestState.repeat_notneedaccept_low
	or aQuestState.repeat_notneedaccept_lower
	or aQuestState.repeat_notneedaccept_high
	or aQuestState.repeat_notneedaccept_higher then
		tNpcHaveQuest[dwNpcID] = true
		SceneObject_SetTitleEffect(TARGET.NPC, dwNpcID, QUEST_MARK.repeat_notneedaccept)
		return
	end

	if aQuestState.normal_notneedaccept_proper then
--	or aQuestState.normal_notneedaccept_low
--	or aQuestState.normal_notneedaccept_lower
--	or aQuestState.normal_notneedaccept_high
--	or aQuestState.normal_notneedaccept_higher
		tNpcHaveQuest[dwNpcID] = true
		SceneObject_SetTitleEffect(TARGET.NPC, dwNpcID, QUEST_MARK.normal_notneedaccept)
		return
	end

	if hPlayer.IsInParty() then	-- party mark
		local nPartyMark = GetClientTeam().GetMarkIndex(dwNpcID)
		if nPartyMark and PARTY_TITLE_MARK_EFFECT_LIST[nPartyMark] then
			SceneObject_SetTitleEffect(TARGET.NPC, dwNpcID, PARTY_TITLE_MARK_EFFECT_LIST[nPartyMark])
			if aQuestState.normal_unaccept_high or aQuestState.repeat_unaccept_high or aQuestState.activity_unaccept_high then
				tNpcHaveQuest[dwNpcID] = true
			end
			return
		end
	end

	-- npc type mark
	local tNpc = Table_GetNpc(hNpc.dwTemplateID)
	local dwNpcTypeID = nil
	if tNpc then
		dwNpcTypeID = tNpc.dwTypeID
	end
	if dwNpcTypeID and IsSearchTypeNpc(dwNpcTypeID) then
		local tNpcType = Table_GetNpcType(dwNpcTypeID)
		if tNpcType and tNpcType.dwEffectID > 0 then
			SceneObject_SetTitleEffect(TARGET.NPC, dwNpcID, tNpcType.dwEffectID)
			if aQuestState.normal_unaccept_high or aQuestState.repeat_unaccept_high or aQuestState.activity_unaccept_high then
				tNpcHaveQuest[dwNpcID] = true
			end
			return
		end
	end

	if aQuestState.normal_unaccept_high
	or aQuestState.repeat_unaccept_high
	or aQuestState.activity_unaccept_high
	then
		tNpcHaveQuest[dwNpcID] = true
		if IsInLishijie() then
			SceneObject_SetTitleEffect(TARGET.NPC, dwNpcID, QUEST_MARK.lishijie_unaccept)
		else
			SceneObject_SetTitleEffect(TARGET.NPC, dwNpcID, QUEST_MARK.unaccept_high)
		end
		return
	end

	-- if g_bHideQuestShowFlag and
	-- (
	-- 	aQuestState.normal_unaccept_low or
	-- 	aQuestState.repeat_unaccept_low or
	-- 	aQuestState.activity_unaccept_low
	-- ) then
	-- 	if IsInLishijie() then
	-- 		SceneObject_SetTitleEffect(TARGET.NPC, dwNpcID, QUEST_MARK.lishijie_unaccept)
	-- 	else
	-- 		SceneObject_SetTitleEffect(TARGET.NPC, dwNpcID, QUEST_MARK.unaccept_low)
	-- 	end
	-- 	return
	-- end

	if g_bHideQuestShowFlag and
	(
		aQuestState.normal_unaccept_lower or
		aQuestState.repeat_unaccept_lower or
		aQuestState.activity_unaccept_lower
	) then
		if IsInLishijie() then
			SceneObject_SetTitleEffect(TARGET.NPC, dwNpcID, QUEST_MARK.lishijie_unaccept)
		else
			SceneObject_SetTitleEffect(TARGET.NPC, dwNpcID, QUEST_MARK.unaccept_lower)
		end
		return
	end

-- 	if aQuestState.normal_accepted_proper
-- 	or aQuestState.normal_accepted_low
-- 	or aQuestState.normal_accepted_lower
-- 	or aQuestState.normal_accepted_high
-- --	or aQuestState.normal_accepted_higher
-- 	or aQuestState.repeat_accepted_proper
-- 	or aQuestState.repeat_accepted_high
-- --	or aQuestState.repeat_accepted_higher
-- 	or aQuestState.repeat_accepted_low
-- 	or aQuestState.repeat_accepted_lower
-- 	or aQuestState.activity_accepted_proper
-- 	or aQuestState.activity_accepted_low
-- 	or aQuestState.activity_accepted_lower
-- 	or aQuestState.activity_accepted_high then
-- 		SceneObject_SetTitleEffect(TARGET.NPC, dwNpcID, QUEST_MARK.accpeted)
-- 		return
-- 	end

	SceneObject_SetTitleEffect(TARGET.NPC, dwNpcID, 0)	-- none effect
end
--]]

function OutputNpcTip(dwNpcID)
	local npc = GetNpc(dwNpcID)

	local me = GetClientPlayer()
	local r, g, b = 255, 255, 255
	local t = {}

	-- 名字
	local szName = GBKToUTF8(TargetMgr.GetTargetName(TARGET.NPC, dwNpcID))
	tinsert(t, szName .. "\n")
	-- 称号
	if npc.szTitle ~= "" then
		tinsert(t, "＜" .. GBKToUTF8(npc.szTitle) .. "＞\n")
	end
	-- 等级
	if npc.nLevel - me.nLevel > 10 then
		tinsert(t, GetFormatText(g_tStrings.STR_PLAYER_H_UNKNOWN_LEVEL, 82))
	elseif npc.nLevel > 0 then
		tinsert(t, GetFormatText(FormatString(g_tStrings.STR_NPC_H_WHAT_LEVEL, npc.nLevel), 0))
	end
	-- 势力
	if npc.dwForceID ~= 0 then
		local tRepuForceInfo = Table_GetReputationForceInfo(npc.dwForceID)
		if tRepuForceInfo then
			tinsert(t, GetFormatText(tRepuForceInfo.szName .. "\n", 0))
		end
	end
	-- 任务信息
	tinsert(t, GetNpcQuestTip(npc.dwTemplateID))
	-- 调试信息`
    tinsert(t, GetFormatText(FormatString(g_tStrings.TIP_NPC_ID, npc.dwID), 102))
    tinsert(t, GetFormatText(FormatString(g_tStrings.TIP_TEMPLATE_ID_NPC_INTENSITY, npc.dwTemplateID, npc.nIntensity), 102))
    tinsert(t, GetFormatText(FormatString(g_tStrings.TIP_REPRESENTID_ID, npc.dwModelID), 102))
    -- if IsShiftKeyDown() then
    -- 	local tState = GetNpcQuestState(npc, true)
    -- 	for szKey, tQuestList in pairs(tState) do
    -- 		tState[szKey] = tconcat(tQuestList, ",")
    -- 	end
    -- 	tinsert(t, GetFormatText(var2str(tState, "  "), 102))
    -- end

    local szContent = string.format("<color=#FFFFFF>%s</color>", tconcat(t))
    --LOG.INFO(szXXX)

    return szName, szContent
end

function GetNpcQuestTip(dwNpcTemplateID)
	local nTargetFont = 0
	szTip = ""
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return szTip
	end

	local tQuestList = hPlayer.GetQuestList()
	for _, dwQuestID in pairs(tQuestList) do
		local szTarget = ""
		local tQuestTrace = hPlayer.GetQuestTraceInfo(dwQuestID)
		for _, v in ipairs(tQuestTrace.kill_npc) do
			if dwNpcTemplateID == v.template_id then
				if v.have < v.need then
					local szName = Table_GetNpcTemplateName(v.template_id)
					if not szName or szName == "" then
						szName = "Unknown Npc"
					end
					szTarget = GetFormatText(g_tStrings.STR_TWO_CHINESE_SPACE.. szName ..": "..v.have.."/"..v.need .. "\n", nTargetFont)
				end
				break
			end
		end

		local tQuestInfo = GetQuestInfo(dwQuestID)
		for i = 1, QUEST_COUNT.QUEST_END_ITEM_COUNT do
			if tQuestInfo["dwDropItemNpcTemplateID" .. i] ~= 0
			and tQuestInfo["dwDropItemNpcTemplateID" .. i] == dwNpcTemplateID
			then
				for _, v in ipairs(tQuestTrace.need_item) do
					if v.type == tQuestInfo["dwEndRequireItemType" .. i]
					and v.index == tQuestInfo["dwEndRequireItemIndex" .. i]
					and v.need == tQuestInfo["dwEndRequireItemAmount" .. i]
					then
						local tItemInfo = GetItemInfo(v.type, v.index)
						local nBookID = v.need
						if tItemInfo.nGenre == ITEM_GENRE.BOOK then
							v.need = 1
						end
						if v.have < v.need then
							local szName = "Unknown Item"
							if tItemInfo then
								szName = GetItemNameByItemInfo(tItemInfo, nBookID)
							end
							szTarget = szTarget .. GetFormatText(g_tStrings.STR_TWO_CHINESE_SPACE.. szName ..": "..v.have.."/"..v.need .. "\n", nTargetFont)
						end
						break
					end
				end
			end
		end
		if szTarget ~= "" then
			local tQuestStringInfo = Table_GetQuestStringInfo(dwQuestID)
			szTip = szTip .. GetFormatText("[" .. tQuestStringInfo.szName .. "]\n", 65) .. szTarget
		end
	end
	return szTip
end


--需要攻击返回flase，否则返回true
function InteractNpc(dwNpcID)
	local npc = GetNpc(dwNpcID)
	if not npc then
		return false
	end

	local player = GetClientPlayer()
	local dwPlayerID = player.dwID

	if npc.IsSelectable() then
		if IsEnemy(dwPlayerID, dwNpcID) then
			return false
		elseif npc.bDialogFlag then
			if player.bCannotDialogWithNPC then
				if Player_IsBuffExist(10864, player, 1) then
					OutputMessage("MSG_SYS", g_tStrings.MSG_CAN_NOT_DIALOG_WITH_NPC1)
				elseif Player_IsBuffExist(19902, player, 1) then
					OutputMessage("MSG_SYS", g_tStrings.MSG_CAN_NOT_DIALOG_WITH_NPC2)
				else
					OutputMessage("MSG_SYS", g_tStrings.MSG_CAN_NOT_DIALOG_WITH_NPC)
				end
				return true
			end

			DoAction(dwNpcID, CHARACTER_ACTION_TYPE.DIALOGUE)
			LOG.INFO(string.format("----> DoAction npcid = %d", dwNpcID))
			return true
		else
			return true
		end
	else
		return true
	end
end

--[[
function NeedHightlightNpc(dwNpcID)
	--TODO:可能会根据技能，势力，自身状态之类的条件做
	local npc = GetNpc(dwNpcID)

	if not npc then
		return false
	end

	if not npc.IsSelectable() then
		return false
	end
	return true
end

]]

function CanSelectNpc(dwNpcID)
	local npc = GetNpc(dwNpcID)
	if not npc then
		return false
	end
	if not npc.IsSelectable() then
		return false
	end
	return true
end

--[[
function ChangeCursorWhenOverNpc(dwNpcID)
	if IsCursorInExclusiveMode() then
		return
	end

	local player = GetClientPlayer()
	local dwPlayerID = player.dwID
	local npc = GetNpc(dwNpcID)
	if not npc then
		Cursor.Switch(CURSOR.NORMAL)
		return
	end

	local bCan = npc.CanDialog(player)

	if npc.IsSelectable() then
		if IsEnemy(dwPlayerID, dwNpcID) then
			Cursor.Switch(CURSOR.ATTACK)
		elseif npc.bDialogFlag then
			if bCan then
				Cursor.Switch(CURSOR.SPEAK)
			else
				Cursor.Switch(CURSOR.UNABLESPEAK)
			end
		else
			Cursor.Switch(CURSOR.NORMAL)
		end
	else
		Cursor.Switch(CURSOR.NORMAL)
	end
end

function NeedHighlightNpcWhenOver(dwNpcID)
	local dwPlayerID = GetClientPlayer().dwID
	local npc = GetNpc(dwNpcID)
	if not npc then
		return false
	end

	if npc.IsSelectable() then
		return true
	end
	return false
end

local _cache_npc
local function _cache_npc_update(cache)
	_cache_npc = cache
end

_cache_npc = cache_init(100, "npc", _cache_npc_update)

npccache_debug=function()
	UILog("npc cache use num "..tostring(_cache_npc._useNum))
end

function Table_GetNpc(dwTemplateID)
	local tNpc = _cache_npc[dwTemplateID]
	if not tNpc then
		tNpc = g_tTable.Npc:Search(dwTemplateID)
		tNpc = tNpc or -1
		_cache_npc = cache_append(_cache_npc, dwTemplateID, tNpc)
	end

	if tNpc == -1 then
		return
	end

	return tNpc
end

local _cache_npctype
local function _cache_npctype_update(cache)
	_cache_npctype = cache
end

_cache_npctype = cache_init(20, "npctype", _cache_npctype_update)

npctypecache_debug=function()
	UILog("npc type cache use num "..tostring(_cache_npctype._useNum))
end

function Table_GetNpcType(dwNpcTypeID)
	local tType = _cache_npctype[dwNpcTypeID]
	if not tType then
		tType = g_tTable.NpcType:Search(dwNpcTypeID)
		tType = tType or -1
		_cache_npctype = cache_append(_cache_npctype, dwNpcTypeID, tType)
	end

	if tType == -1 then
		return
	end

	return tType
end
--]]
