BGMStateMgr = BGMStateMgr or {className = "BGMStateMgr"}

local self = BGMStateMgr

local m_tBGMStateList = nil
local m_tBGMStateListByMapID = {}
local m_tRegisteredEvents = {}

local function RegisterEventHandler(szEvent)
	if m_tRegisteredEvents[szEvent] then
		return
	end

	Event.Reg(self, szEvent, function(...)
		self.OnEvent(szEvent, ...)
	end)

	m_tRegisteredEvents[szEvent] = true
end

local function _GetCurrentMapID()
	local player = PlayerData.GetClientPlayer()
	if player then
		return player.GetMapID()
	end
	return 0
end

local function _GetCurrentAreaID()
	return QuestData.GetAreaID() or 0
end

function BGMStateMgr.CheckBUFF(player, tCondition)
	if tCondition.nBuffID <= 0 then
		return true
	end

	local bHaveBuff = false
	if tCondition.nBuffLevel > 0 then
		bHaveBuff = player.IsHaveBuff(tCondition.nBuffID, tCondition.nBuffLevel)
	else
		bHaveBuff = player.IsHaveBuff(tCondition.nBuffID)
	end

	return bHaveBuff == tCondition.bHaveBuff
end

function BGMStateMgr.CheckQuestState(player, tCondition)
	if tCondition.dwQuestID <= 0 then
		return true
	end
	local nQuestState = player.GetQuestPhase(tCondition.dwQuestID)
	return nQuestState == tCondition.nQuestState
end

function BGMStateMgr.CheckFightState(player, tCondition)
	if tCondition.nFightState < 0 then
		return true
	end
	local bNeedFight = tCondition.nFightState == 1
	return player.bFightState == bNeedFight
end

function BGMStateMgr.CheckHealth(player, tCondition)
	if tCondition.fMinHealthPct < 0 and tCondition.fMaxHealthPct < 0 then
		return true
	end

	local nCurrentLife = player.nCurrentLife or 0
	local nHealthMax = player.nMaxLife or 0
	local fHealthPct = 0
	if nHealthMax > 0 then
		fHealthPct = nCurrentLife / nHealthMax
	end

	if (tCondition.fMinHealthPct < 0 or fHealthPct > tCondition.fMinHealthPct)
		and (tCondition.fMaxHealthPct < 0 or fHealthPct <= tCondition.fMaxHealthPct) then
		return true
	end
	return false
end

function BGMStateMgr.CheckMap(tCondition)
	if not tCondition.tMapList or #tCondition.tMapList <= 0 then
		return true
	end

	local dwMapID = _GetCurrentMapID()
	for _, dwConditionMapID in ipairs(tCondition.tMapList) do
		if dwConditionMapID == dwMapID or dwConditionMapID == 0 then
			return true
		end
	end
	return false
end

function BGMStateMgr.CheckCurrentBGM(tCondition)
	if not tCondition.szOriginalBGM or tCondition.szOriginalBGM == "" then
		return true
	end

	local dwMapID = _GetCurrentMapID()
	local nAreaID = _GetCurrentAreaID()
	local szMusic = MapHelper.GetMapAreaBgMusic(dwMapID, nAreaID)
	return tCondition.szOriginalBGM == szMusic
end

function BGMStateMgr.DoUpdateBGM(tCondition)
	if not tCondition.bActive and not tCondition.bUpdated then
		return
	end

	if tCondition.bActive and not tCondition.bUpdated then
		if tCondition.szReplaceBGM and tCondition.szReplaceBGM ~= "" then
			LOG.INFO("[BGMState] Switch BGM - ID:%s BGM:%s", tostring(tCondition.nID), tostring(tCondition.szReplaceBGM))
			SoundMgr.PlayBgMusicPriority(tCondition.szReplaceBGM, tCondition.nPriority)
		end

		if tCondition.szStackingBGM and tCondition.szStackingBGM ~= "" then
			SetSoundState(tCondition.szStackingBGM, tCondition.szStackingState)
		end

		if tCondition.szSound and tCondition.szSound ~= "" and SOUND[tCondition.szSoundType] then
			PlaySound(SOUND[tCondition.szSoundType], tCondition.szSound)
		end

		tCondition.bUpdated = true
	elseif tCondition.bUpdated and not tCondition.bActive then
		if tCondition.szReplaceBGM and tCondition.szReplaceBGM ~= "" then
			LOG.INFO("[BGMState] Stop BGM - ID:%s BGM:%s", tostring(tCondition.nID), tostring(tCondition.szReplaceBGM))
			SoundMgr.StopBgMusicPriority(tCondition.szReplaceBGM, tCondition.nPriority)
		end

		if tCondition.szStackingBGM and tCondition.szStackingBGM ~= "" then
			SetSoundState(tCondition.szStackingBGM, tCondition.szStackingStopState)
		end

		tCondition.bUpdated = false
	end
end

function BGMStateMgr.UpdateBGMStateCondition(tConditionList)
	if not tConditionList then
		return
	end

	local player = PlayerData.GetClientPlayer()
	if not player then
		return
	end

	for _, tCondition in ipairs(tConditionList) do
		local bActive = self.CheckBUFF(player, tCondition)
			and self.CheckQuestState(player, tCondition)
			and self.CheckFightState(player, tCondition)
			and self.CheckHealth(player, tCondition)
			and self.CheckMap(tCondition)
			and self.CheckCurrentBGM(tCondition)

		tCondition.bActive = bActive
		self.DoUpdateBGM(tCondition)
	end
end

function BGMStateMgr.UpdateBGMStateByMapIDAndCategory(dwMapID, szCategory, key)
	local tMapData = m_tBGMStateListByMapID[dwMapID]
	if not tMapData then
		return
	end

	local tCategoryTable = tMapData[szCategory]
	if not tCategoryTable then
		return
	end

	if key then
		local tConditionList = tCategoryTable[key]
		if tConditionList then
			self.UpdateBGMStateCondition(tConditionList)
		end
	else
		self.UpdateBGMStateCondition(tCategoryTable)
	end
end

function BGMStateMgr.UpdateBGMStateByCategory(szCategory, key)
	local dwCurrentMapID = _GetCurrentMapID()
	self.UpdateBGMStateByMapIDAndCategory(0, szCategory, key)
	self.UpdateBGMStateByMapIDAndCategory(dwCurrentMapID, szCategory, key)
end

function BGMStateMgr.UpdateBGMStateByMapLoadingEnd(dwNewMapID)
	self.UpdateBGMStateByMapID(0)
	self.UpdateBGMStateByMapID(dwNewMapID)
end

function BGMStateMgr.UpdateBGMStateByBuffID(nBuffID)
	if not nBuffID or nBuffID <= 0 then
		return
	end
	self.UpdateBGMStateByCategory("Buff", nBuffID)
end

function BGMStateMgr.UpdateBGMStateByQuestID(dwQuestID)
	if not dwQuestID or dwQuestID <= 0 then
		return
	end
	self.UpdateBGMStateByCategory("Quest", dwQuestID)
end

function BGMStateMgr.UpdateBGMStateByHealth()
	self.UpdateBGMStateByCategory("HealthPct")
end

function BGMStateMgr.UpdateBGMStateByFightState()
	self.UpdateBGMStateByCategory("FightState")
end

function BGMStateMgr.UpdateBGMStateByMapID(dwMapID)
	if not dwMapID or dwMapID < 0 then
		return
	end

	local tMapData = m_tBGMStateListByMapID[dwMapID]
	if not tMapData then
		return
	end

	for _, tCategoryTable in pairs(tMapData) do
		if type(tCategoryTable) == "table" then
			if type(tCategoryTable[1]) == "table" then
				self.UpdateBGMStateCondition(tCategoryTable)
			else
				for _, tConditionList in pairs(tCategoryTable) do
					if type(tConditionList) == "table" then
						self.UpdateBGMStateCondition(tConditionList)
					end
				end
			end
		end
	end
end

function BGMStateMgr.UpdateBGMStateByOriginalBGM(szOriginalBGM)
	if not szOriginalBGM or szOriginalBGM == "" then
		return
	end
	self.UpdateBGMStateByCategory("OriginalBGM", szOriginalBGM)
end

function BGMStateMgr.OnQuestEvent(szEvent, p0, p1)
	local dwQuestID
	local nQuestIndex
	if szEvent == "QUEST_CANCELED" or szEvent == "QUEST_FINISHED" then
		dwQuestID = p0
	elseif szEvent == "QUEST_ACCEPTED" then
		dwQuestID = p1 or p0
	elseif szEvent == "QUEST_FAILED" or szEvent == "QUEST_DATA_UPDATE" then
		nQuestIndex = p0
	end

	if nQuestIndex then
		local player = PlayerData.GetClientPlayer()
		if player then
			dwQuestID = player.GetQuestID(nQuestIndex)
		end
	end

	self.UpdateBGMStateByQuestID(dwQuestID)
end

function BGMStateMgr.OnEvent(szEvent, ...)
	if szEvent == "PLAYER_LEAVE_GAME" then
		SoundMgr.ClearBGM()
	elseif szEvent == "BUFF_UPDATE" then
		local nBuffOwnerID, _, _, _, nBuffID = ...
		local dwPlayerID = UI_GetClientPlayerID and UI_GetClientPlayerID() or nil
		if not dwPlayerID or nBuffOwnerID ~= dwPlayerID then
			return
		end
		self.UpdateBGMStateByBuffID(nBuffID)
	elseif szEvent == "QUEST_ACCEPTED"
		or szEvent == "QUEST_FAILED"
		or szEvent == "QUEST_CANCELED"
		or szEvent == "QUEST_FINISHED"
		or szEvent == "QUEST_DATA_UPDATE" then
		self.OnQuestEvent(szEvent, ...)
	elseif szEvent == "FIGHT_HINT" then
		self.UpdateBGMStateByFightState()
	elseif szEvent == "PLAYER_STATE_UPDATE" then
		self.UpdateBGMStateByHealth()
	elseif szEvent == "LOADING_END" then
		self.UpdateBGMStateByMapLoadingEnd(_GetCurrentMapID())
	elseif szEvent == "UPDATE_REGION_INFO" then
		local nAreaID = ...
		local dwMapID = _GetCurrentMapID()
		local szMusic = MapHelper.GetMapAreaBgMusic(dwMapID, nAreaID)
		self.UpdateBGMStateByOriginalBGM(szMusic)
	elseif szEvent == EventType.UILoadingStart then
		SoundMgr.ClearBGM()
	end
end

function BGMStateMgr.LoadBGMStateTable()
	m_tBGMStateList = {}
	m_tBGMStateListByMapID = {}

	local nCount = g_tTable.BGMState:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.BGMState:GetRow(i)
		tLine.tMapList = StringParse_IDList(tLine.szMapList, ";")
		table.insert(m_tBGMStateList, tLine)

		if tLine.tMapList and #tLine.tMapList > 0 then
			for _, dwMapID in ipairs(tLine.tMapList) do
				if not m_tBGMStateListByMapID[dwMapID] then
					m_tBGMStateListByMapID[dwMapID] = {
						Buff = {},
						Quest = {},
						HealthPct = {},
						FightState = {},
						OriginalBGM = {},
					}
				end

				if tLine.nBuffID and tLine.nBuffID > 0 then
					if not m_tBGMStateListByMapID[dwMapID].Buff[tLine.nBuffID] then
						m_tBGMStateListByMapID[dwMapID].Buff[tLine.nBuffID] = {}
					end
					table.insert(m_tBGMStateListByMapID[dwMapID].Buff[tLine.nBuffID], tLine)
				end

				if tLine.dwQuestID and tLine.dwQuestID > 0 then
					if not m_tBGMStateListByMapID[dwMapID].Quest[tLine.dwQuestID] then
						m_tBGMStateListByMapID[dwMapID].Quest[tLine.dwQuestID] = {}
					end
					table.insert(m_tBGMStateListByMapID[dwMapID].Quest[tLine.dwQuestID], tLine)
				end

				if (tLine.fMinHealthPct and tLine.fMinHealthPct > 0) or (tLine.fMaxHealthPct and tLine.fMaxHealthPct > 0) then
					table.insert(m_tBGMStateListByMapID[dwMapID].HealthPct, tLine)
				end

				if tLine.nFightState and tLine.nFightState >= 0 then
					table.insert(m_tBGMStateListByMapID[dwMapID].FightState, tLine)
				end

				if tLine.szOriginalBGM and tLine.szOriginalBGM ~= "" then
					if not m_tBGMStateListByMapID[dwMapID].OriginalBGM[tLine.szOriginalBGM] then
						m_tBGMStateListByMapID[dwMapID].OriginalBGM[tLine.szOriginalBGM] = {}
					end
					table.insert(m_tBGMStateListByMapID[dwMapID].OriginalBGM[tLine.szOriginalBGM], tLine)
				end
			end
		end
	end
end

function BGMStateMgr.Init()
	self.LoadBGMStateTable()

	-- 防止 Init 重入导致同一实例重复监听
	Event.UnRegAll(self)
	m_tRegisteredEvents = {}

	RegisterEventHandler("PLAYER_LEAVE_GAME")
	RegisterEventHandler("BUFF_UPDATE")
	RegisterEventHandler("QUEST_ACCEPTED")
	RegisterEventHandler("QUEST_FAILED")
	RegisterEventHandler("QUEST_CANCELED")
	RegisterEventHandler("QUEST_FINISHED")
	RegisterEventHandler("QUEST_DATA_UPDATE")
	RegisterEventHandler("FIGHT_HINT")
	RegisterEventHandler("LOADING_END")
	RegisterEventHandler("PLAYER_STATE_UPDATE")
	RegisterEventHandler("UPDATE_REGION_INFO")
	RegisterEventHandler(EventType.UILoadingStart)
end

function BGMStateMgr.UnInit()
	Event.UnRegAll(self)
	m_tRegisteredEvents = {}
end

function BGMStateMgr.Reset()
end
