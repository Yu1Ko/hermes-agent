-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: TeamMarkData
-- Date: 2023-12-07 09:59:30
-- Desc: ?
-- ---------------------------------------------------------------------------------
local g2u = UIHelper.GBKToUTF8
local u2g = UIHelper.UTF8ToGBK
local MAX_MARK_COUNT = 10
local ARENA_TYPE_TO_ENEMY_NUM = {
    [ARENA_UI_TYPE.ARENA_2V2] = 2,
    [ARENA_UI_TYPE.ARENA_3V3] = 3,
    [ARENA_UI_TYPE.ARENA_5V5] = 5,
}
TeamMarkData = TeamMarkData or {className = "TeamMarkData"}
local self = TeamMarkData
-------------------------------- 消息定义 --------------------------------
TeamMarkData.Event = {}
TeamMarkData.Event.XXX = "TeamMarkData.Msg.XXX"

function TeamMarkData.Init()
    self.nCurArenaMarkNum = nil
    self.tbMarkFlagList = {}
    self.tbMarkList     = {}
    self.tbAllPlayer    = {}
    self.RegisterEvent()
end

function TeamMarkData.UnInit()
    self.nCurArenaMarkNum = nil
    self.tbMarkList = {}

    if self.nPlayerAutoMarkTimer then
        Timer.DelTimer(self, self.nPlayerAutoMarkTimer)
        self.nPlayerAutoMarkTimer = nil
    end
end

function TeamMarkData.OnLogin()

end

function TeamMarkData.OnFirstLoadEnd()

end

function TeamMarkData.RegisterEvent()
    Event.Reg(self, EventType.OnClientPlayerEnter, function()
        self.tbMarkNpc = Table_GetMarkNPCList()
        local bNotUpdate = self.UpdateMarkNPCList()
        if bNotUpdate then return end
        self.UpdateTeamMarkNPCList()
        self:UpdateUIMarkInfo()
    end)

    Event.Reg(self, "LOADING_END", function(szEvent, ...)
        self.bIsAddonBanMap = self.IsAddonBanMap()

        if BattleFieldData.IsInBattleField() or ArenaData.IsInArena() then
            self.nCurArenaMarkNum = 0
            self.AutoSetTeamMark(true, false)  --进入战场或jjc后自动触发标记
        end
    end)

    Event.Reg(self, EventType.OnNpcEnterScene, function(nNpcID)
        -- if not TeamData.IsInParty() then return end
        self.DelayUpdateAllInfo()
    end)

    Event.Reg(self, EventType.OnNpcLeaveScene, function(nNpcID)
        -- if not TeamData.IsInParty() then return end
        self.DelayUpdateAllInfo()
    end)

    Event.Reg(self, "PARTY_SET_MARK", function()
        self.UpdateTeamMarkNPCList()
        self:UpdateUIMarkInfo()
    end)

    Event.Reg(self, "OTHER_PLAYER_REVIVE", function(dwID, szTemp)
        if self.IsNPCMarked(dwID) then
            self.DelayUpdateTeamMarkInfo()--这个时候玩家生命值还没改，要延迟
        end
    end)


    Event.Reg(self, "SYS_MSG", function(szType, dwCharacterID, dwKillerID)
        if szType == "UI_OME_DEATH_NOTIFY" and self.IsNPCMarked(dwCharacterID) then--标记玩家死亡
            self.DelayUpdateTeamMarkInfo()--这个时候玩家生命值还没改，要延迟
        end
    end)

    Event.Reg(self, "PLAYER_ENTER_SCENE", function (nPlayerID)
        if BattleFieldData.IsInBattleField() then
            TeamMarkData.AutoSetTeamMark(true, false)
        end
        self.DelayUpdateTeamMarkInfo()
    end)

    Event.Reg(self, EventType.OnArenaPlayerUpdate, function()
        if ArenaData.IsInBattle() then
            return  -- 开战后不自动标记
        end
        self.nCurArenaMarkNum = self.nCurArenaMarkNum or 0

        local tbEnemyPlayerData = ArenaData.GetBattlePlayerData(true)
        local bNeedMark = self.nCurArenaMarkNum < #tbEnemyPlayerData
        if bNeedMark then
            TeamMarkData.AutoSetTeamMark(true, true)
        end
    end)

    Event.Reg(self, "PLAYER_LEAVE_SCENE", function (nPlayerID)
        -- if BattleFieldData.IsInBattleField() or ArenaData.IsInArena() then
        --     TeamMarkData.AutoSetTeamMark(true)
        -- end
        self.DelayUpdateTeamMarkInfo()
    end)

    Event.Reg(self, "PARTY_UPDATE_BASE_INFO", function()
        self.UpdateTeamMarkNPCList()
        self:UpdateUIMarkInfo()
    end)

    Event.Reg(self, "PARTY_DELETE_MEMBER", function (_, nMemberID, _, nGroupIndex)
        local hPlayer = g_pClientPlayer
		if hPlayer and hPlayer.dwID == nMemberID then
            self.UpdateTeamMarkNPCList()
            self:UpdateUIMarkInfo()
		end
    end)

end

function TeamMarkData.DelayUpdateAllInfo()
    self.UnDelayUpdateAllInfo()
    self.nTimer = Timer.AddFrame(self, 2, function()--延迟两帧，防止刚进场景时收到太多OnNpcEnterScene事件频繁更新
        local bNotUpdate = self.UpdateMarkNPCList()
        if bNotUpdate then return end
        self.UpdateTeamMarkNPCList()
        self:UpdateUIMarkInfo()
    end)
end

function TeamMarkData.UnDelayUpdateAllInfo()
    if self.nTimer then
        Timer.DelTimer(self, self.nTimer)
        self.nTimer = nil
    end
end

function TeamMarkData.DelayUpdateTeamMarkInfo()
    self.UnDelayUpdateTeamMarkInfo()
    self.nTeamMarkTimer = Timer.Add(self, 1, function()
        self.UpdateTeamMarkNPCList()
        self:UpdateUIMarkInfo()
    end)
end

function TeamMarkData.UnDelayUpdateTeamMarkInfo()
    if self.nTeamMarkTimer then
        Timer.DelTimer(self, self.nTeamMarkTimer)
        self.nTeamMarkTimer = nil
    end
end


function TeamMarkData.UpdateMarkNPCList()
    if self.tbMarkNpc then
        local tbAllNPC = NpcData.GetAllNpc()
        self.tbMarkNPCList = {}
        for dwCharacterID, npc in pairs(tbAllNPC) do
            local tbMarkNpcInfo = self.tbMarkNpc[npc.dwTemplateID]
            if tbMarkNpcInfo then
                local tbInfo = {}
                tbInfo.dwCharacterID = dwCharacterID
                tbInfo.dwAimMarkPriority = tbMarkNpcInfo.dwAimMarkPriority
                tbInfo.nTargetType = IsPlayer(dwCharacterID) and TARGET.PLAYER or TARGET.NPC
                tbInfo.bDeath = npc.nCurrentLife == 0
                tbInfo.npc = npc
                tbInfo.szName = UIHelper.GBKToUTF8(Table_GetNpcTemplateName(tbMarkNpcInfo.dwTemplateID))
                table.insert(self.tbMarkNPCList, tbInfo)
            end
        end

        table.sort(self.tbMarkNPCList, function(l, r)
            if l.dwAimMarkPriority ~= r.dwAimMarkPriority then
                return l.dwAimMarkPriority < r.dwAimMarkPriority
            else
                return l.dwCharacterID < r.dwCharacterID
            end
        end)
    end
    local bNotUpdate = self.AutoMarkNPC()
    return bNotUpdate
end

--获取附近的配置在表里被标记的npc
function TeamMarkData.GetMarkNPCList()
    return self.tbMarkNPCList or {}
end

function TeamMarkData.AutoMarkNPC()
    if self.tbMarkNPCList then
        if not self.IsTeamMarkOp() then
            return false
        end
        local team = GetClientTeam()
        local bEmptyMark = true
        local nIndex = 1
        for _, tbInfo in pairs(self.tbMarkNPCList) do
            local dwTargetID = tbInfo.dwCharacterID
            if nIndex > MAX_MARK_COUNT then
                break
            end
            team.SetTeamMark(nIndex, dwTargetID)
            nIndex = nIndex + 1
            bEmptyMark = false
        end
        if not bEmptyMark then
            return true
        end
    end
    return false
end

function TeamMarkData.UpdateTeamMarkNPCList()
    self.tbTeamMarkList = {}
    local team = GetClientTeam()
    if team.dwTeamID == 0 then return self.tbTeamMarkList end--没有队伍

    local tbPartyMark = team.GetTeamMark() or {}

    for dwCharacterID, dwMarkID in pairs(tbPartyMark) do
        local npc = GetPlayer(dwCharacterID) or GetNpc(dwCharacterID)
        if npc then
            local tbInfo = {}
            local bPlayer = IsPlayer(dwCharacterID)
            local szName = ""
            if not bPlayer then
                szName = UIHelper.GBKToUTF8(Table_GetNpcTemplateName(npc.dwTemplateID))
            end
            tbInfo.dwCharacterID = dwCharacterID
            tbInfo.dwMarkID = dwMarkID
            tbInfo.nTargetType = bPlayer and TARGET.PLAYER or TARGET.NPC
            tbInfo.bDeath = npc.nCurrentLife == 0
            tbInfo.npc = npc
            tbInfo.szName = szName
            table.insert(self.tbTeamMarkList, tbInfo)
        end
        local tbMarkNPCList = self.GetMarkNPCList()
        for nIndex, tbNPCInfo in pairs(tbMarkNPCList) do
            if tbNPCInfo.dwCharacterID == dwCharacterID then
                table.remove(tbMarkNPCList, nIndex)
                break
            end
        end
    end

    table.sort(self.tbTeamMarkList, function(l, r)
        return l.dwMarkID < r.dwMarkID
    end)
end

--主要用在玩家死亡或复活时，检测是否在标记表内
function TeamMarkData.IsNPCMarked(dwCharacterID)
    for nIndex, tbInfo in ipairs(self.tbTeamMarkList) do
        if tbInfo.dwCharacterID == dwCharacterID then
            return true
        end
    end
    return false
end

--获取附近的配置在表里被标记的npc
function TeamMarkData.GetTeamMarkList()
    return self.tbTeamMarkList
end

function TeamMarkData.UpdateUIMarkInfo()

    --先拿配表里的npc，再拿队友标记的
    local tbMarkList = clone(self.GetTeamMarkList())
    local tbMarkNPCList = clone(self.GetMarkNPCList())

    table.insert_tab(tbMarkList, tbMarkNPCList)

    if not PublicQuestData.IsTableEqual(self.tbMarkList, tbMarkList) then
         --从0到有标记目标以及标记目标全部清空时，强制刷UI
        local bForceUpdate = #self.tbMarkList == 0 and #tbMarkList ~= 0
        self.tbMarkList = tbMarkList
        Event.Dispatch(EventType.UpdateMarkData, #self.tbMarkList ~= 0, bForceUpdate)
    end
end

function TeamMarkData.GetTeamMarkInfo()
    return self.tbMarkList
end

function TeamMarkData.IsAddonBanMap()   --是否在不可标记地图
    local player = GetClientPlayer()
    local dwMapID = player and player.GetMapID()
    if not dwMapID then
        return false
    end

    if Table_IsMobaBattleFieldMap(dwMapID) or
		Table_IsZombieBattleFieldMap(dwMapID) or
	 	Table_IsTreasureBattleFieldMap(dwMapID) or
		Table_IsPleasantGoatBattleFieldMap(dwMapID) then
		return true
	end
	return false
end

-- 判断目标是否应该被标记
function TeamMarkData.TargetShoudMark(tarID)    --_JX_FastMarker.ShoudMark
    if IsEnemy(UI_GetClientPlayerID(), tarID) then
        return true
    elseif IsAlly(UI_GetClientPlayerID(), tarID) or UI_GetClientPlayerID() == tarID then
        -- if JX_FastMarker.tFriend["bFriend"] and JX_FastMarker.tFriend[forceID] then
        --     return true
        -- end
    end
    return false
end

--[[
    tbMarkTargetList = {
        [dwForceID] = {nPlayerID1, nPlayerID2}
    }
]]--
function TeamMarkData._SetTeamMark(tbMarkTargetList, bForbidAutoTalk, bReset)
    if table.is_empty(tbMarkTargetList) and not bForbidAutoTalk then
        TipsHelper.ShowNormalTip(g_tStrings.tAutoTeamMarkWaring.NONE_MARK_TARGET)
		return
    end

    local team = GetClientTeam()
	if not team then
		return
	end

    if bReset == nil then
		bReset = true
	end

	local tbMarkTemp = {} -- 已占用标记
    local tbMarkPlayerTemp = {} -- 已标记玩家
    if not bReset then
        for _, tbInfo in pairs(self.tbMarkList) do
            tbMarkTemp[tbInfo.dwMarkID] = true
            tbMarkPlayerTemp[tbInfo.dwCharacterID] = true
        end
    end

    local bEmptyMark = true
	local bMarkFull = false -- 标记达到上限后不再添加
	for _, v in pairs(TeamMarkPriority) do
		if tbMarkTargetList[v] and not table.is_empty(tbMarkTargetList[v]) then
			for _, dwTargetID in pairs(tbMarkTargetList[v]) do
				for i = 1, 10 do
                    if not self.TargetShoudMark(dwTargetID) or tbMarkPlayerTemp[dwTargetID] then
                        break   --不是自动标记目标就下一个
                    end

					if not tbMarkTemp[i] then
                        bEmptyMark = false
						tbMarkTemp[i] = true
						team.SetTeamMark(i, dwTargetID)
						if i == 10 then
							bMarkFull = true
						end
                        break
					end
				end
				if bMarkFull then break end
			end
		end
		if bMarkFull then break end
	end
    if bEmptyMark and not bForbidAutoTalk then
        TipsHelper.ShowNormalTip(g_tStrings.tAutoTeamMarkWaring.NONE_MARK_TARGET)
    end
end

function TeamMarkData.IsTeamMarkOp()    -- 是否拥有标记权限
    local team = GetClientTeam()
    local dwAuthority = team and team.GetAuthorityInfo(3)
	if dwAuthority and g_pClientPlayer and dwAuthority == g_pClientPlayer.dwID then
        return true
    end
    return false
end

function TeamMarkData.TalkTeamMarkData()
    local me = GetClientPlayer()
    local team = GetClientTeam()
    local dwAuthority = team and team.GetAuthorityInfo(3)
	if dwAuthority and dwAuthority ~= me.dwID then
        local nMyGroup = team.GetMemberGroupIndex(me.dwID) + 1
        local szMyName = g2u(me.szName)
        local szLeader = g2u(team.GetClientTeamMemberName(dwAuthority))
        local szText = string.format(g_tStrings.STR_TEAM_TALK_CHANGE_MARK_OP, szLeader, nMyGroup, szMyName)
        local tWord =
        {
            {type = "text", text = u2g(szText)},
        }

        -- JJC和战场里 用的都是战场频道的  包括吃鸡地图
        local nChannel = PLAYER_TALK_CHANNEL.RAID
        if ArenaData.IsInArena() or BattleFieldData.IsInBattleField() then
            nChannel = PLAYER_TALK_CHANNEL.BATTLE_FIELD
        end

        Player_Talk(me, nChannel, "", tWord)
    end
end

function TeamMarkData.Arena_SetTeamMark()
    local tbMarkTargetList = {}
    local tbEnemyPlayerData = ArenaData.GetBattlePlayerData(true)
    for _, player in pairs(tbEnemyPlayerData) do
        local nKungfuType = GetKungfuTypeByKungfuID(player.dwMountKungfuID)
        if nKungfuType == 2 then
            table.insert(tbMarkTargetList, 1, player.dwID)
        else
            table.insert(tbMarkTargetList, player.dwID)
        end

        if #tbMarkTargetList >= 10 then
            break
        end
    end

    local team = GetClientTeam()
	if not team then
		return
	end

    for i, dwTargetID in ipairs(tbMarkTargetList) do
        team.SetTeamMark(i, dwTargetID)
    end
    self.nCurArenaMarkNum = #tbMarkTargetList
end

function TeamMarkData.AutoSetTeamMark(bForbidAutoTalk, bReset)
    if self.nPlayerAutoMarkTimer then
        Timer.DelTimer(self, self.nPlayerAutoMarkTimer)
        self.nPlayerAutoMarkTimer = nil
    end

    if self.bIsAddonBanMap then
        return
    end

    if not TeamData.IsPlayerInTeam() then
        return
    end

	if not self.IsTeamMarkOp() then
        if not bForbidAutoTalk then
            TipsHelper.ShowNormalTip(g_tStrings.tAutoTeamMarkWaring.NEED_TEAM_MARK_OP)
            self.TalkTeamMarkData()
        end
        return
    end

    if bReset == nil then
        bReset = true
    end

    local _fnMark = function()
        local tbMarkTargetList = {}
        if ArenaData.IsInArena() then
            if bReset then
                TeamMarkData.Arena_SetTeamMark()
                return
            end
            tbMarkTargetList = JX.GetKungfuTypePlayer()
        elseif BattleFieldData.IsInBattleField() then
            tbMarkTargetList = JX.GetForcePlayer()
        else
            tbMarkTargetList = JX.GetForcePlayer()
        end

        TeamMarkData._SetTeamMark(tbMarkTargetList, bForbidAutoTalk, bReset)
    end

    self.nPlayerAutoMarkTimer = Timer.Add(self, 0.1, function()
        _fnMark()
    end)
end