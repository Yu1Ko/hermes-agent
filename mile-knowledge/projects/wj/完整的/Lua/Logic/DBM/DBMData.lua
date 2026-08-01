-- ---------------------------------------------------------------------------------
-- Author: liuyumin
-- Name: DBMData
-- Date: 2023-12-14 20:33:30
-- Desc: ?
-- ---------------------------------------------------------------------------------

DBMData = DBMData or {className = "DBMData"}
local self = DBMData

self.tbNpcList = {}

self.tbCurDbmList = {}

self.tbTimerList = {}

self.tbNpcTimerList = {}

self.tbCurDbmSkillList = {}
self.tbStopDbmList = {}

self.nTime = nil

self.nPassTime = 0

self.nCurBossTemplateID = nil

self.tbFightTimerList = {}

self.tbCurBossTemplateID = {}

self.bStart = false

local DBM_TYPE = {
	BUFF = 1,
	SKILL = 2,
	NPC = 3
}
local DBM_ACTION_TYPE = {
	BUFF = {
		GET = 1,
		LOST = 2
	},
	SKILL = {
		START = 1,
		END = 2
	},
	NPC = {
		STARTFIGHT = 1,
		LIFEPERCENT = 2,
		MANAPERCENT = 3,
		DEAD = 4,
		ALLDEAD = 5,
		APPEAR = 6
	}
}

local CLEAR_TYPE = {
	ALL = 1,
	COUNTDOWN = 2,
	TIMER = 3
}

local BUFF_TARGET_TYPE = {
	ALL = 1,
	PLAYER = 2,
	TEAM = 3,
	ENEMY = 4,
	TARGET = 5
}

local SKILL_STATE = {
	NONE = 1,
	PREPARE = 2,
	DONE = 3,
}

local PAUSE_DBM = {
	PAUSE = 1,
	START = 2
}

local function RegisterTablePath(dwMapID, szTitle, tPath, szSuffix)
	local szPath = tPath.Path .. dwMapID .. szSuffix
	if not IsUITableRegister(szTitle) then
        RegisterUITable(szTitle, szPath, tPath.Title)
    end

	return IsFileExist(szPath)
end

local function ParseBossDbmSkillString(sz)
    if type(sz) ~= "string" then
        return nil
    end

    sz = sz:match("^%s*(.-)%s*$")
    if sz == "" then
        return {}
    end

    local out = {}

    for rawName, rawTime in sz:gmatch("%[%s*([^,%]]+)%s*,%s*([^%]]-)%s*%]") do
        local name = rawName:match("^%s*(.-)%s*$")
        name = name:gsub('^"(.*)"$', "%1")
        name = name:gsub("^'(.*)'$", "%1")

        local timeStr = rawTime:match("^%s*(.-)%s*$")
        local timeNum = tonumber(timeStr)

        table.insert(out, name)
        table.insert(out, timeNum ~= nil and timeNum or timeStr)
    end

    return out
end

local function GetDbmListByMapId(nMapID)
	if not nMapID then
		return nil
	end

	local tbDbmList = {}
	local szTabName = "BossDbmMap"..nMapID
	if RegisterTablePath(nMapID, szTabName, g_tBossDbmMap, ".tab") then
		local nCount = g_tTable[szTabName]:GetRowCount()
		for i = 2, nCount do
			local tLine = g_tTable[szTabName]:GetRow(i)
			local tbDbm = clone(tLine)
			tbDbm.tbSkill = ParseBossDbmSkillString(UIHelper.GBKToUTF8(tLine.tbSkill))
			table.insert(tbDbmList, tbDbm)
		end
	end

	return tbDbmList
end

local function ClassifyDbmList(tbMapDbmList)
	if not tbMapDbmList or table.is_empty(tbMapDbmList) then
		return nil
	end

	local tbClassifiedDbmList = {
		[DBM_TYPE.BUFF] = {},
		[DBM_TYPE.SKILL] = {},
		[DBM_TYPE.NPC] = {}
	}
	for _, dbm in ipairs(tbMapDbmList) do
		local dbmType = tbClassifiedDbmList[dbm.nType]
		if dbmType then
			dbmType[dbm.nTargetID] = dbmType[dbm.nTargetID] or {}
			table.insert(dbmType[dbm.nTargetID], dbm)
		end
	end

	return tbClassifiedDbmList
end

function DBMData.Init()
	DBMData.RegEvent()
end

function DBMData.UnInit()
	Event.UnRegAll(self)
    Timer.DelAllTimer(self)
end

function DBMData.RegEvent()
	Event.Reg(self, "LOADING_END", function ()
		local bInDungeon = DungeonData.IsInDungeon()
		if not bInDungeon then
			return
		end

		local player = GetClientPlayer()
		if not player then
			return
		end
		local nMapID = player.GetMapID()
		local szTabName = "BossDbmMap"..nMapID
		local tbMapDbmList = GetDbmListByMapId(nMapID)
		self.tbClassifiedDbmList = ClassifyDbmList(tbMapDbmList)

        if self.tbPendingNpcEnterList then
            for dwCharacterID, _ in pairs(self.tbPendingNpcEnterList) do
                Event.Dispatch(EventType.OnNpcEnterScene, dwCharacterID)
            end
            self.tbPendingNpcEnterList = {}
        end
	end)

	Event.Reg(self, "SYS_MSG", function()
		if not self.tbClassifiedDbmList then
			return
		end

        if arg0 == "UI_OME_SKILL_CAST_LOG" then	--技能蓄力
			local dwCaster, dwSkillID, dwLevel = arg1, arg2, arg3
			local player = GetClientPlayer()
			if not player then
				return
			end
			local nMapID = player.GetMapID()
			if self.IsSkillDbmInMapExist(nMapID, dwSkillID) then
				self.DoSkillCastDbm(dwCaster, dwSkillID, dwLevel, DBM_ACTION_TYPE.SKILL.START)
			end

        end
    end)

	Event.Reg(self, "DO_SKILL_CAST", function(dwCaster, dwSkillID, dwLevel)--技能释放
		if not self.tbClassifiedDbmList then
			return
		end

		local player = GetClientPlayer()
		if not player then
			return
		end
		local nMapID = player.GetMapID()
		if self.IsSkillDbmInMapExist(nMapID, dwSkillID) then
			self.DoSkillCastDbm(dwCaster, dwSkillID, dwLevel, DBM_ACTION_TYPE.SKILL.END)
		end
    end)

	Event.Reg(self, "BUFF_UPDATE", function()
		if not self.tbClassifiedDbmList then
			return
		end

        local owner, bdelete, index, cancancel, id  , stacknum, endframe, binit, level, srcid, isvalid, leftframe
		= arg0 , arg1   , arg2 , arg3     , arg4, arg5    , arg6    , arg7 , arg8 , arg9 , arg10  , arg11

		local tbAllObtainedDbm = nil
		local tbAllLostDbm = nil
		local tbBuffDbm = nil
		local player = GetClientPlayer()
		if not player then
			return
		end
		local dwTargetType, dwTargetID = player.GetTarget()
		local nMapID = player.GetMapID()
		local _, nMapType = GetMapParams(nMapID)
		if nMapType ~= 1 then
			return
		end
		if self.IsBuffDbmInMapExist(DBM_TYPE.BUFF, nMapID, id, level) then
			if bdelete then
				--tbAllLostDbm = self.GetBuffLostDbmList(id, level)
				tbAllLostDbm = self.GetBuffDbmList(id, level, DBM_ACTION_TYPE.BUFF.LOST, nMapID)
			else
				--tbAllObtainedDbm = self.GetBuffObtainedDbmList(id, level)
				tbAllObtainedDbm = self.GetBuffDbmList(id, level, DBM_ACTION_TYPE.BUFF.GET, nMapID)
			end
			if tbAllObtainedDbm and not table.is_empty(tbAllObtainedDbm) then
				tbBuffDbm = self.GetBuffDbmListByType(tbAllObtainedDbm, owner, dwTargetID)
			end
			if tbAllLostDbm and not table.is_empty(tbAllLostDbm) then
				tbBuffDbm = self.GetBuffDbmListByType(tbAllLostDbm, owner, dwTargetID)
			end

			if tbBuffDbm and not table.is_empty(tbBuffDbm) then
				table.sort(tbBuffDbm, function (a, b)
					if a.nID < b.nID then
						return true
					else
						return false
					end
				end)
				for k, dbm in pairs(tbBuffDbm) do
					self.TriggerDbm(dbm, id, DBM_TYPE.BUFF)
				end
			end
		end
		if id == 71222 and level == 1 and bdelete then
			self.tbNpcList = {}
			self.tbCurDbmList = {}
			self.tbTimerList = {}
			self.tbNpcTimerList = {}
			self.tbStopDbmList = {}
			self.nTime = nil
			self.nPassTime = 0
			self.tbCurBossTemplateID = {}
			Timer.DelAllTimer()
			Event.Dispatch("ON_UPDATEBOSSDBM_STATE", false)
		end
	end)

	Event.Reg(self, EventType.OnNpcEnterScene, function(dwCharacterID)	--npc出现
		if not self.tbClassifiedDbmList then
			self.tbPendingNpcEnterList = self.tbPendingNpcEnterList or {}
            self.tbPendingNpcEnterList[dwCharacterID] = true
			return
		end

		local player = GetClientPlayer()
		if not player then
			return
		end
		local nMapID = player.GetMapID()
		local _, nMapType = GetMapParams(nMapID)
		if nMapType ~= 1 then
			return
		end
		local npc = GetNpc(dwCharacterID)
		if not npc then
			return
		end
		local dwTemplateID = npc.dwTemplateID
		local bFight = false
		local bAppear = true
		local bDead = false

		local nCurrentLife = nil
		local nCurrentMana = npc.nCurrentMana
		local nMaxLife = nil
		local nMaxMana = npc.nMaxMana
		local nPercentLife = nil
		local nPercentMana = 100 * nCurrentMana / nMaxMana
		local dwTargetType, dwTargetID = player.GetTarget()
		local nCurrentSkillId = nil
		local nCurrentSkillLevel = nil
		if self.IsNpcDbmInMapExist(nMapID, dwCharacterID) then
			if 2 == npc.nIntensity or 6 == npc.nIntensity then	--npc为boss
				nCurrentLife = npc.fCurrentLife64 or 0
				nMaxLife = GetTargetMaxLife(TARGET.NPC, dwCharacterID)
				nPercentLife = 100 * nCurrentLife / nMaxLife
			else	--普通npc
				nCurrentLife = npc.nCurrentLife or 0
				nMaxLife = npc.nMaxLife
				nPercentLife = 100 * nCurrentLife / nMaxLife
			end
			self.tbNpcList[dwCharacterID] = {["dwTemplateID"] = dwTemplateID, ["npc"] = npc, ["bFight"] = bFight, ["bAppear"] = bAppear, ["bDead"] = bDead, ["nPercentLife"] = nPercentLife, ["nPercentMana"] = nPercentMana}
			local tbAppearDbm = self.GetNpcAppearDbmList(DBM_TYPE.NPC, nMapID, dwTemplateID)
			if tbAppearDbm and not table.is_empty(tbAppearDbm) then
				local tbDbm = self.GetBuffDbmListByType(tbAppearDbm, dwCharacterID, dwTargetID)
				if tbDbm and not table.is_empty(tbDbm) then
					table.sort(tbDbm, function (a, b)
						if a.nID < b.nID then
							return true
						else
							return false
						end
					end)
					for k, dbm in pairs(tbDbm) do
						self.TriggerDbm(dbm, dwTemplateID, DBM_TYPE.NPC)
					end
				end
			end
			local tbFightDbmList = self.GetNpcStartFightDbmList(nMapID, dwTemplateID)	--获取该npc的开战dbm
			if tbFightDbmList and not table.is_empty(tbFightDbmList) then	--开刷
				if not self.tbFightTimerList[dwTemplateID] then
					self.tbFightTimerList[dwTemplateID] = Timer.AddFrameCycle(self, 2, function ()
						player = GetClientPlayer()
						if not self.tbNpcList[dwCharacterID] then
							self.tbNpcList[dwCharacterID] = {["dwTemplateID"] = dwTemplateID, ["npc"] = npc, ["bFight"] = false, ["bAppear"] = bAppear, ["bDead"] = bDead, ["nPercentLife"] = nPercentLife, ["nPercentMana"] = nPercentMana}
						end
						local tbNpc = self.tbNpcList[dwCharacterID]
						npc = GetNpc(dwCharacterID)
						if npc and tbNpc then
							if npc.bFightState and not tbNpc.bFight then
								local tbFightDbm = self.GetBuffDbmListByType(tbFightDbmList, dwCharacterID, dwTargetID)
								if tbFightDbm and not table.is_empty(tbFightDbm) then
									self.tbNpcList[dwCharacterID].bFight = true
									table.sort(tbFightDbm, function (a, b)
										if a.nID < b.nID then
											return true
										else
											return false
										end
									end)
									for k, dbm in pairs(tbFightDbm) do
										if dbm.bIsBoss and not table.contain_value(self.tbCurBossTemplateID, dwTemplateID) then
											table.insert(self.tbCurBossTemplateID, dwTemplateID)
											--self.nCurBossTemplateID = dwTemplateID
										end
										self.TriggerDbm(dbm, dwTemplateID, DBM_TYPE.NPC)
									end
									self.bStart = true
								end
							end
							--npc脱战
							if player and tbNpc and not npc.bFightState and tbNpc.bFight and not player.IsHaveBuff(71222, 1) then
								self.NpcEndFight(dwTemplateID)
							end
						end
						for npcID, v in pairs(self.tbNpcList) do
							if player and dwTemplateID == v.dwTemplateID and not GetNpc(npcID) and not player.IsHaveBuff(71222, 1) then
								self.NpcEndFight(dwTemplateID)
								Timer.DelTimer(self, self.tbFightTimerList[dwTemplateID])
								self.tbFightTimerList[dwTemplateID] = nil
							end
							if not GetNpc(npcID) then
								self.tbNpcList[npcID] = nil
							end
						end
					end)
				end

			end
		end
    end)

	Event.Reg(self, EventType.OnNpcLeaveScene, function(dwCharacterID)	--npc离开场景
		if not self.tbClassifiedDbmList then
			return
		end

		local player = GetClientPlayer()
		if not player then
			return
		end
		local nMapID = player.GetMapID()
		local _, nMapType = GetMapParams(nMapID)
		if nMapType ~= 1 then
			return
		end
		if player.IsHaveBuff(71222, 1) then
			return
		end
		local dwTargetType, dwTargetID = player.GetTarget()
		if self.IsNpcDbmInMapExist(nMapID, dwCharacterID) then
			local npc = GetNpc(dwCharacterID)
			local dwTemplateID = npc.dwTemplateID
			local tbDeadDbmList = self.GetNpcDeadDbmList(nMapID, dwTemplateID)
			local tbAllDeadDbmList = self.GetNpcSAllDeadDbmList(nMapID, dwTemplateID)
			self.tbNpcList[dwCharacterID] = nil--表中移除该死亡npc
			if tbDeadDbmList and not table.is_empty(tbDeadDbmList) then
				local tbDeadDbm = self.GetBuffDbmListByType(tbDeadDbmList, dwCharacterID, dwTargetID)
				if tbDeadDbm and not table.is_empty(tbDeadDbm) then
					table.sort(tbDeadDbm, function (a, b)
						if a.nID < b.nID then
							return true
						else
							return false
						end
					end)
					for k, dbm in pairs(tbDeadDbm) do
						self.TriggerDbm(dbm, dwTemplateID, DBM_TYPE.NPC)
					end
				end
			elseif DBMData.IsLastSameNpc(npc.dwTemplateID) and tbAllDeadDbmList and not table.is_empty(tbAllDeadDbmList) then	--全部死亡
				local tbAllDeadDbm = self.GetBuffDbmListByType(tbAllDeadDbmList, dwCharacterID, dwTargetID)
				if tbAllDeadDbm and not table.is_empty(tbAllDeadDbm) then
					table.sort(tbAllDeadDbm, function (a, b)
						if a.nID < b.nID then
							return true
						else
							return false
						end
					end)
					for k, dbm in pairs(tbAllDeadDbm) do
						self.TriggerDbm(dbm, dwTemplateID, DBM_TYPE.NPC)
					end
				end
			else
				self.NpcEndFight(dwTemplateID)
			end
		end
    end)

	Event.Reg(self, "NPC_STATE_UPDATE", function (dwCharacterID)
		if not self.tbClassifiedDbmList then
			return
		end
		
		local player = GetClientPlayer()
		if not player then
			return
		end
		local nMapID = player.GetMapID()
		local _, nMapType = GetMapParams(nMapID)
		if nMapType ~= 1 then
			return
		end
		local dwTargetType, dwTargetID = player.GetTarget()
		if self.IsNpcDbmInMapExist(nMapID, dwCharacterID) and self.tbNpcList[dwCharacterID] and self.bStart then	--玩家当前所在场景存在dbm，开始监听
			local newNpc = GetNpc(dwCharacterID)
			local dwTemplateID = newNpc.dwTemplateID
			local nCurrentLife = nil
			local nMaxLife = nil
			local nPercentLife = nil
			if 2 == newNpc.nIntensity or 6 == newNpc.nIntensity then	--npc为boss
				nCurrentLife = newNpc.fCurrentLife64 or 0
				nMaxLife = GetTargetMaxLife(TARGET.NPC, dwCharacterID)
				nPercentLife = 100 * nCurrentLife / nMaxLife
			else	--普通npc
				nCurrentLife = newNpc.nCurrentLife or 0
				nMaxLife = newNpc.nMaxLife
				nPercentLife = 100 * nCurrentLife / nMaxLife
			end
			local nPercentMana = 100 * newNpc.nCurrentMana / newNpc.nMaxMana
			local nTarTarType, nTarTarID = newNpc.GetTarget()


			local npc = self.tbNpcList[dwCharacterID]
			--npc脱战
			if npc and not newNpc.bFightState and npc.bFight then
				self.NpcEndFight(dwTemplateID)
				return
			end
			--找到该npc在表中对应的气血百分比dbm然后判断触发
			if npc then
				local tbLifeDbmList = self.GetNpcLifeOrManaDbmList(nMapID, dwTemplateID, nPercentLife, npc.nPercentLife, DBM_ACTION_TYPE.NPC.LIFEPERCENT)
				self.tbNpcList[dwCharacterID].nPercentLife = nPercentLife--设置npc气血百分比
				if tbLifeDbmList and not table.is_empty(tbLifeDbmList) then
					local tbLifeDbm = self.GetBuffDbmListByType(tbLifeDbmList, dwCharacterID, dwTargetID)
					if tbLifeDbm and not table.is_empty(tbLifeDbm) then
						table.sort(tbLifeDbm, function (a, b)
							if a.nID < b.nID then
								return true
							else
								return false
							end
						end)
						for k, dbm in pairs(tbLifeDbm) do
							self.TriggerDbm(dbm, dwTemplateID, DBM_TYPE.NPC)
						end
					end
				end
			end


			--找到该npc在表中对应的内力百分比dbm然后判断触发
			if npc then
				local tbManaDbmList = self.GetNpcLifeOrManaDbmList(nMapID, dwTemplateID, nPercentMana, npc.nPercentMana, DBM_ACTION_TYPE.NPC.MANAPERCENT)
				self.tbNpcList[dwCharacterID].nPercentMana = nPercentMana--设置npc内力百分比
				if tbManaDbmList and not table.is_empty(tbManaDbmList) then
					local tbManaDbm = self.GetBuffDbmListByType(tbManaDbmList, dwCharacterID, dwTargetID)
					if tbManaDbm and not table.is_empty(tbManaDbm) then
						table.sort(tbManaDbm, function (a, b)
							if a.nID < b.nID then
								return true
							else
								return false
							end
						end)
						for k, dbm in pairs(tbManaDbm) do
							self.TriggerDbm(dbm, dwTemplateID, DBM_TYPE.NPC)
						end
					end
				end
			end

		end

	end)
end
-----------------------

function DBMData.IsLastSameNpc(dwTemplateID)	--是否为场景中最后一个同名npc
	for i, npc in pairs(self.tbNpcList) do
		if npc.dwTemplateID == dwTemplateID then
			return false
		end
	end
	return true
end

function DBMData.GetNpcAppearDbmList(nType, nMapID, dwTemplateID)	--获取npc出现时的dbm
	local tbClassifiedDbmList = self.tbClassifiedDbmList
	local result = {}
	if tbClassifiedDbmList[DBM_TYPE.NPC] and tbClassifiedDbmList[DBM_TYPE.NPC][dwTemplateID] then
		for k, dbm in pairs(tbClassifiedDbmList[DBM_TYPE.NPC][dwTemplateID]) do
			if dbm.nActionID == DBM_ACTION_TYPE.NPC.APPEAR then
				table.insert(result, clone(dbm))
			end
		end
	end

	return result
end

function DBMData.IsTimerExist(nKey)
	if self.tbTimerList[nKey] ~= nil then
		return  true
	else
		return false
	end
end

function DBMData.DeleteTimer(nKey)
	if self.tbTimerList[nKey] then
		Timer.DelTimer(self, self.tbTimerList[nKey].nTimer)
		self.tbTimerList[nKey] = nil
	end
end

function DBMData.SortDbm()
	local tbSkillList = {}
	for i, npcDbm in pairs(self.tbCurDbmList) do
		for k = 1, table.get_len(npcDbm.tbSkill), 2 do
			local szSkill = npcDbm.tbSkill[k]
			local nTime = npcDbm.tbSkill[k + 1]
			if nTime >= 0 then
				table.insert(tbSkillList, {["nID"] = npcDbm.nID, ["szSkill"] = szSkill, ["nTime"] = nTime})
			end
		end
	end
	table.sort(tbSkillList, function (a, b)
		if a.nTime < b.nTime then
			return true
		else
			return false
		end
	end)
	return tbSkillList
end

function DBMData.IsNpcDbmInMapExist(nMapID, dwCharacterID)	--判断该npc在该地图中是否存在dbm
	local npc = GetNpc(dwCharacterID)
	local dwTemplateID = npc.dwTemplateID
	local tbClassifiedDbmList = self.tbClassifiedDbmList

	if tbClassifiedDbmList and tbClassifiedDbmList[DBM_TYPE.NPC] and tbClassifiedDbmList[DBM_TYPE.NPC][dwTemplateID] then
		return true
	end

	return false
end

function DBMData.IsBuffDbmInMapExist(nType, nMapID, dwID, nLevel)	--判断该buff在该地图中是否存在dbm
	local tbClassifiedDbmList = self.tbClassifiedDbmList
	if tbClassifiedDbmList[DBM_TYPE.BUFF] and tbClassifiedDbmList[DBM_TYPE.BUFF][dwID] then
		for k, dbm in pairs(tbClassifiedDbmList[DBM_TYPE.BUFF][dwID]) do
			if nLevel == dbm.nTargetLevel then
				return true
			end
		end
	end

	return false
end

function DBMData.GetNpcSkillDbmInMap(nType, nMapID, dwSkillID, nLevel, dwTemplateID)	--获取该技能在该地图开始蓄力dbm和成功释放dbm
	local tbClassifiedDbmList = self.tbClassifiedDbmList
	local tbStartDbm = {}
	local tbSucessDbm = {}
	if tbClassifiedDbmList[DBM_TYPE.SKILL] and tbClassifiedDbmList[DBM_TYPE.SKILL][dwSkillID] then
		for k, dbm in pairs(tbClassifiedDbmList[DBM_TYPE.SKILL][dwSkillID]) do
			if dbm.nAction > 0 and dbm.nAction == dwTemplateID and (dbm.nTargetLevel <= 0 or nLevel == dbm.nTargetLevel) then
				if dbm.nActionID == DBM_ACTION_TYPE.SKILL.START then
					table.insert(tbStartDbm, clone(dbm))
				elseif dbm.nActionID == DBM_ACTION_TYPE.SKILL.END then
					table.insert(tbSucessDbm, clone(dbm))
				end
			elseif dbm.nAction <= 0 and (dbm.nTargetLevel <= 0 or nLevel == dbm.nTargetLevel) then
				if dbm.nActionID == DBM_ACTION_TYPE.SKILL.START then
					table.insert(tbStartDbm, clone(dbm))
				elseif dbm.nActionID == DBM_ACTION_TYPE.SKILL.END then
					table.insert(tbSucessDbm, clone(dbm))
				end
			end
		end
	end

	return tbStartDbm, tbSucessDbm
end

function DBMData.IsSkillDbmInMapExist(nMapID, dwSkillID)	--判断在该地图中是否存在对应的技能dbm
	local tbClassifiedDbmList = self.tbClassifiedDbmList
	if tbClassifiedDbmList[DBM_TYPE.SKILL] and tbClassifiedDbmList[DBM_TYPE.SKILL][dwSkillID] then
		return true
	end

	return false
end

function DBMData.DeleteDbmByKey(nKey, nClearType)
	if nClearType == CLEAR_TYPE.ALL then		--清空key值为nkey的dbm和保护时间
		local nCount = table.get_len(self.tbCurDbmList)
		for i = nCount, 1, -1 do
			local dbm = self.tbCurDbmList[i]
			if dbm.nKey == nKey then
				table.remove(self.tbCurDbmList, i)
			end
		end
		if not table.is_empty(self.tbStopDbmList) then
			local nLength = table.get_len(self.tbStopDbmList)
			for i = nLength, 1, -1 do
				local stopdbm = self.tbStopDbmList[i]
				if stopdbm.nKey == nKey then
					table.remove(self.tbStopDbmList, i)
				end
			end
		end

		if self.tbTimerList[nKey] then
			Timer.DelTimer(self, self.tbTimerList[nKey].nTimer)
			self.tbTimerList[nKey] = nil
		end
	elseif nClearType == CLEAR_TYPE.COUNTDOWN then	--只清dbm
		local nCount = table.get_len(self.tbCurDbmList)
		for i = nCount, 1, -1 do
			local dbm = self.tbCurDbmList[i]
			if dbm.nKey == nKey then
				table.remove(self.tbCurDbmList, i)
			end
		end
	elseif nClearType == CLEAR_TYPE.TIMER then	--只清保护时间
		if self.tbTimerList[nKey] then
			Timer.DelTimer(self, self.tbTimerList[nKey].nTimer)
			self.tbTimerList[nKey] = nil
		end
	end

end

function DBMData.GetNpcDeadDbmList(nMapID, dwTemplateID)--获取该npc死亡时的dbm
	local result = {}
	local tbClassifiedDbmList = self.tbClassifiedDbmList

	if tbClassifiedDbmList[DBM_TYPE.NPC] and tbClassifiedDbmList[DBM_TYPE.NPC][dwTemplateID] then
		for k, dbm in pairs(tbClassifiedDbmList[DBM_TYPE.NPC][dwTemplateID]) do
			if dbm.nActionID == DBM_ACTION_TYPE.NPC.DEAD then
				table.insert(result, clone(dbm))
			end
		end
	end

	return result
end

function DBMData.GetNpcSAllDeadDbmList(nMapID, dwTemplateID)	--获取该npc全部死亡时的dbm
	local result = {}
	local tbClassifiedDbmList = self.tbClassifiedDbmList

	if tbClassifiedDbmList[DBM_TYPE.NPC] and tbClassifiedDbmList[DBM_TYPE.NPC][dwTemplateID] then
		for k, dbm in pairs(tbClassifiedDbmList[DBM_TYPE.NPC][dwTemplateID]) do
			if dbm.nActionID == DBM_ACTION_TYPE.NPC.ALLDEAD then
				table.insert(result, clone(dbm))
			end
		end
	end

	return result
end

function DBMData.GetNpcStartFightDbmList(nMapID, dwTemplateID)	--获取该npc开战时的dbm
	local result = {}
	local tbClassifiedDbmList = self.tbClassifiedDbmList

	if tbClassifiedDbmList[DBM_TYPE.NPC] and tbClassifiedDbmList[DBM_TYPE.NPC][dwTemplateID] then
		for k, dbm in pairs(tbClassifiedDbmList[DBM_TYPE.NPC][dwTemplateID]) do
			if dbm.nActionID == DBM_ACTION_TYPE.NPC.STARTFIGHT then
				table.insert(result, clone(dbm))
			end
		end
	end

	return result
end

function DBMData.NpcEndFight(dwTemplateID)	--npc脱战
	
	if table.contain_value(self.tbCurBossTemplateID, dwTemplateID) then
		--for k, v in pairs(self.tbNpcList) do
		--	if v.dwTemplateID == dwTemplateID then
				self.tbNpcList = {}
		--	end
		--end
		self.tbCurDbmList = {}
		if not table.is_empty(self.tbTimerList) then
			for k, tbInfo in pairs(self.tbTimerList) do
				Timer.DelTimer(self, tbInfo.nTimer)
			end
		end
		self.tbTimerList = {}
		self.tbNpcTimerList = {}
		self.tbStopDbmList = {}
		self.nTime = nil
		self.nPassTime = 0
		self.tbCurBossTemplateID = {}
		self.bStart = false
		Timer.DelAllTimer()
		Event.Dispatch("ON_UPDATEBOSSDBM_STATE", false)
	end
end

function DBMData.GetNpcLifeOrManaDbmList(nMapID, dwTemplateID, nNewPercent, nOldPercent, nType)	--获取该npc某个气血百分比bdm
	--判断该npc的nOldLifePercent大于某个百分比而nNewLifePercent小于这个百分比则触发这个百分比对应的dbm
	--获取该npc所有关于气血的dbm列表
	local tbDbmList = {}
	local result = {}
	local tbClassifiedDbmList = self.tbClassifiedDbmList
	
	if tbClassifiedDbmList[DBM_TYPE.NPC] and tbClassifiedDbmList[DBM_TYPE.NPC][dwTemplateID] then
		for k, dbm in pairs(tbClassifiedDbmList[DBM_TYPE.NPC][dwTemplateID]) do
			if dbm.nActionID == nType then
				if nOldPercent > dbm.nAction and nNewPercent <= dbm.nAction then
					table.insert(result, clone(dbm))
				end
			end
		end
	end
	return result
end

function DBMData.GetBuffDbmList(nID, nLevel, nType, nMapID)
	local result = {}
	local tbClassifiedDbmList = self.tbClassifiedDbmList

	if tbClassifiedDbmList[DBM_TYPE.BUFF] and tbClassifiedDbmList[DBM_TYPE.BUFF][nID] then
		for k, dbm in pairs(tbClassifiedDbmList[DBM_TYPE.BUFF][nID]) do
			if dbm.nTargetLevel == nLevel and dbm.nActionID == nType then
				if dbm.nAction ~= 0 and table.contain_value(self.tbCurBossTemplateID, dbm.nAction) or dbm.nAction == 0 then
					table.insert(result, clone(dbm))
				end
			end
		end
	end

	return result
end

function DBMData.GetBuffDbmListByType(tbDbmList, owner, dwTargetID)
	local tbBuffDbm = {}
	for k, dbm in pairs(tbDbmList) do
		if dbm.nTargetType == BUFF_TARGET_TYPE.ALL then	--该buff类型为有人获得
			table.insert(tbBuffDbm, dbm)
		elseif dbm.nTargetType == BUFF_TARGET_TYPE.PLAYER and g_pClientPlayer.dwID == owner then	--该buff类型为自身获得就触发
			table.insert(tbBuffDbm, dbm)
		elseif dbm.nTargetType == BUFF_TARGET_TYPE.TEAM and TeamData.IsPlayerInTeam(owner) then	--该buff类型为团队获得触发
			table.insert(tbBuffDbm, dbm)
		elseif dbm.nTargetType == BUFF_TARGET_TYPE.ENEMY and IsEnemy(g_pClientPlayer.dwID, owner) then	--该buff类型为敌方获得触发
			table.insert(tbBuffDbm, dbm)
		elseif dbm.nTargetType == BUFF_TARGET_TYPE.TARGET and dwTargetID == owner then	--该buff类型为当前目标获得触发
			table.insert(tbBuffDbm, dbm)
		end
	end

	return tbBuffDbm
end

function DBMData.SetDbmSkillStartTime(tbDbm)
	if self.tbCurDbmList and not table.is_empty(self.tbCurDbmList) then
		for i, dbm in ipairs(self.tbCurDbmList) do
			for k = 1, table.get_len(dbm.tbSkill), 2 do
				self.tbCurDbmList[i].tbSkill[k + 1] = self.tbCurDbmList[i].tbSkill[k + 1] - (Timer.GetPassTime() - self.nPassTime)
				if tbDbm.nAddTimekey and dbm.nKey == tbDbm.nAddTimekey and self.tbCurDbmList[i].tbSkill[k + 1] > 0 and tbDbm.nTime ~= 0 then
					self.tbCurDbmList[i].tbSkill[k + 1] = self.tbCurDbmList[i].tbSkill[k + 1] + tbDbm.nTime
				end
			end
		end
		for k, dbm in pairs(self.tbCurDbmList) do
			for i, skill in pairs(dbm.tbSkill) do
				if i % 2 == 0 and self.tbCurDbmList[k].tbSkill[i] <= 0 then
					table.remove(self.tbCurDbmList[k].tbSkill, i)
					table.remove(self.tbCurDbmList[k].tbSkill, i - 1)
				end
			end
		end
	end
end

function DBMData.PauseDbm(tbDbm)	--暂停时间轴
	if tbDbm.nStopTimer == PAUSE_DBM.PAUSE then
		local tbKeyList = {}
		local nLength = table.get_len(self.tbCurDbmList)

		if nLength > 0 then
			for i = nLength, 1, -1 do
				local dbm = self.tbCurDbmList[i]
				if tbDbm.nAddTimekey and dbm.nKey == tbDbm.nAddTimekey then
					if tbDbm.bTimeCeil then	--开启时间轴指定key的时间进1取整
						for k = 1, table.get_len(dbm.tbSkill), 2 do
							dbm.tbSkill[k + 1] =  math.floor(dbm.tbSkill[k + 1] + 1)
						end
					end
					table.insert(self.tbStopDbmList, dbm)
					table.remove(self.tbCurDbmList, i)
				end
			end
		end
	end
	if tbDbm.nStopTimer == PAUSE_DBM.START then	
		local nStopLength = table.get_len(self.tbStopDbmList)
		if nStopLength > 0 then
			for i = nStopLength, 1, -1 do
				local dbm = self.tbStopDbmList[i]
				if tbDbm.nAddTimekey and dbm.nKey == tbDbm.nAddTimekey then
					table.insert(self.tbCurDbmList, dbm)
					table.remove(self.tbStopDbmList, i)
				end
			end
		end
	end
end

function DBMData.DoSkillCastDbm(dwCaster, dwSkillID, dwLevel, nSkillType)
	local player = GetClientPlayer()
	if not player then
		return
	end
	local nMapID = player.GetMapID()
	local _, nMapType = GetMapParams(nMapID)
	if nMapType ~= 1 then
		return
	end
	local npc = GetNpc(dwCaster)
	if npc then
		local dwTemplateID = npc.dwTemplateID
		local dwTargetType, dwTargetID = player.GetTarget()
		local tbStartDbmList1, tbSucessDbmList1 = self.GetNpcSkillDbmInMap(DBM_TYPE.SKILL, nMapID, dwSkillID, dwLevel, dwTemplateID)
		local tbSkillDbmList = nil
		if nSkillType == DBM_ACTION_TYPE.SKILL.START then
			tbSkillDbmList = tbStartDbmList1
		else
			tbSkillDbmList = tbSucessDbmList1
		end
		if tbSkillDbmList and not table.is_empty(tbSkillDbmList) then
			local tbStartDbm = self.GetBuffDbmListByType(tbSkillDbmList, dwCaster, dwTargetID)
			if tbStartDbm and not table.is_empty(tbStartDbm) then
				table.sort(tbStartDbm, function (a, b)
					if a.nID < b.nID then
						return true
					else
						return false
					end
				end)
				for k, dbm in pairs(tbStartDbm) do
					self.TriggerDbm(dbm, dwSkillID, DBM_TYPE.SKILL)
				end
			end
		end
	end
end

function DBMData.TriggerDbm(tbDbm, nTargetID, nType)	--触发dbm
	if not self.IsTimerExist(tbDbm.nKey) then

		if tbDbm.nProtectTime > 0 then
			--if not self.IsTimerExist(tbDbm.nKey) then
	
				if tbDbm.nClearKey then
					self.DeleteDbmByKey(tbDbm.nClearKey, tbDbm.nClearType)
				end
				self.SetDbmSkillStartTime(tbDbm)
				if tbDbm.nStopTimer then
					self.PauseDbm(tbDbm)
				end
				if tbDbm.nAddTimekey and tbDbm.nTime then
					for key, tbInfo in pairs(self.tbTimerList) do
						if key == tbDbm.nAddTimekey then
							Timer.DelTimer(self, tbInfo.nTimer)
							local nNewProtectTime = tbInfo.nProtectTime - (Timer.GetPassTime() - tbDbm.nAddPassTime) + tbDbm.nTime
							local nTimer = Timer.AddCountDown(self, tbInfo.nProtectTime - (Timer.GetPassTime() - tbDbm.nAddPassTime) + tbDbm.nTime, function (nRemain)
							end, function ()
								self.DeleteTimer(tbDbm.nKey)
							end)
							self.tbTimerList[tbDbm.nKey] = {["nTimer"] = nTimer, ["nAddPassTime"] = Timer.GetPassTime(), ["nProtectTime"] = nNewProtectTime}
						end
					end
				else
	
				end
				table.insert(self.tbCurDbmList, clone(tbDbm))
				self.nPassTime = Timer.GetPassTime()
				Event.Dispatch("ON_UPDATEBOSSDBM_STATE", true)
				local nTimer = Timer.AddCountDown(self, tbDbm.nProtectTime, function (nRemain)
				end, function ()
					self.DeleteTimer(tbDbm.nKey)
				end)
				self.tbTimerList[tbDbm.nKey] = {["nTimer"] = nTimer, ["nAddPassTime"] = Timer.GetPassTime(), ["nProtectTime"] = tbDbm.nProtectTime}
			--end
		else
			if tbDbm.nClearKey then
				self.DeleteDbmByKey(tbDbm.nClearKey, tbDbm.nClearType)
			end
			self.SetDbmSkillStartTime(tbDbm)
			if tbDbm.nStopTimer then
				self.PauseDbm(tbDbm)
			end
			table.insert(self.tbCurDbmList, clone(tbDbm))
			self.nPassTime = Timer.GetPassTime()
			Event.Dispatch("ON_UPDATEBOSSDBM_STATE", true)
		end
	end

end