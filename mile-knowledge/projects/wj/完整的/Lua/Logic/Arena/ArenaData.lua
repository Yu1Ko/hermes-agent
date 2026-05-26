ArenaData = ArenaData or {className = "ArenaData"}
local self = ArenaData

-- 创建名剑队消耗金钱
ArenaData.CREATE_GOLD = 800

ArenaData.WIN_REWARD_ITEM = 48195

local tbDoubleType =
{
	[ARENA_UI_TYPE.ARENA_1V1] = 1,
	[ARENA_UI_TYPE.ARENA_2V2] = 1,
	[ARENA_UI_TYPE.ARENA_3V3] = 1,
	[ARENA_UI_TYPE.ARENA_5V5] = 1,
	[ARENA_UI_TYPE.ARENA_MASTER_3V3] = 2,
}

local tbWeeklyRequestTime =
{
	[ARENA_UI_TYPE.ARENA_1V1] = -1,
	[ARENA_UI_TYPE.ARENA_2V2] = -1,
	[ARENA_UI_TYPE.ARENA_3V3] = -1,
	[ARENA_UI_TYPE.ARENA_5V5] = -1,
	[ARENA_UI_TYPE.ARENA_MASTER_3V3] = -1,
}

local DXModeToVkMode = {
	[3] = 6,
}

ArenaData.tbCorpsList =
{
	ARENA_UI_TYPE.ARENA_2V2,
	ARENA_UI_TYPE.ARENA_3V3,
	ARENA_UI_TYPE.ARENA_5V5,
	ARENA_UI_TYPE.ARENA_PRACTICE,
	ARENA_UI_TYPE.ARENA_MASTER_3V3,
	ARENA_UI_TYPE.ARENA_1V1,
}

ArenaData.tbClientCorps =
{
	[ARENA_UI_TYPE.ARENA_2V2] = 0,
	[ARENA_UI_TYPE.ARENA_3V3] = 0,
	[ARENA_UI_TYPE.ARENA_5V5] = 0,
	[ARENA_UI_TYPE.ARENA_MASTER_3V3] = 0,
	[ARENA_UI_TYPE.ARENA_PRACTICE] = 0,
}

ArenaData.tbTargetCorps =
{
	[ARENA_UI_TYPE.ARENA_2V2] = 0,
	[ARENA_UI_TYPE.ARENA_3V3] = 0,
	[ARENA_UI_TYPE.ARENA_5V5] = 0,
	[ARENA_UI_TYPE.ARENA_MASTER_3V3] = 0,
	[ARENA_UI_TYPE.ARENA_PRACTICE] = 0,
}

ArenaData.RoomNextCreateTime = 120	--下次开房间的CD时间
ArenaData.tRoomPendingTime = {
	[ARENA_TYPE.ARENA_2V2] = 100,
	[ARENA_TYPE.ARENA_3V3] = 150,
	[ARENA_TYPE.ARENA_5V5] = 210,
}

ArenaData.ArenaTypePlayerCount = {	--开房间不同模式的人数限制
	[ARENA_TYPE.ARENA_2V2] = 2,
	[ARENA_TYPE.ARENA_3V3] = 3,
	[ARENA_TYPE.ARENA_5V5] = 5,
}

ArenaData.CorpsMemberMaxCount =
{
	[ARENA_UI_TYPE.ARENA_2V2] = 3,
	[ARENA_UI_TYPE.ARENA_3V3] = 5,
	[ARENA_UI_TYPE.ARENA_5V5] = 8,
	[ARENA_UI_TYPE.ARENA_MASTER_3V3] = 5,
}

ArenaData.ArenaMatchNpcID = {
	[16113] = true,
	[16059] = true,
}


ArenaData.MIN_SHOW_WIN_COUNT 	= 5
ArenaData.MATCH_TIME			= 10 * 60
ArenaData.MATCH_TIME2			= 5 * 60

-- {"七秀", "万花", "五毒", "长歌", "药宗", "少林", "纯阳", "万灵", "唐门", "衍天", "蓬莱", "丐帮", "明教", "凌雪", "苍云", "藏剑", "天策", "霸刀"}
ArenaData.tbArenaMarkForcePriority = {5, 2, 6, 22, 212, 1, 4, 214, 7, 211, 24, 9, 10, 25, 21, 8, 3, 23, 213}


-- 防止刷新数据失败
local _bSyncingCorpsBaseData
local _bSyncingCorpsMemberData
local _bIsLastSyncingBaseData
local _SyncCorpsBaseData = SyncCorpsBaseData
local _SyncCorpsMemberData = SyncCorpsMemberData
local function SyncCorpsBaseData(corpsid, ...)
	local pack = {corpsid, ...}
	if not (corpsid and corpsid > 0) then
		return LOG.ERROR("SyncCorpsBaseData: invalid corpsid " .. tostring(corpsid))
	end
	local res = _SyncCorpsBaseData(corpsid, ...)

	if not res then
        res = _SyncCorpsBaseData(unpack(pack))
	end
	return res
end

local function SyncCorpsMemberData(corpsid, ...)
	local pack = {corpsid, ...}
	if not (corpsid and corpsid > 0) then
		return LOG.ERROR("SyncCorpsMemberData: invalid corpsid " .. tostring(corpsid))
	end
	local res = _SyncCorpsMemberData(corpsid, ...)
	if not res then
        res = _SyncCorpsMemberData(unpack(pack))
	end
	return res
end

--缓存门派信息，为了解决取不到早退玩家的门派，逻辑决定直接去掉门派，让界面缓存
local tPlayerForce = {}
local tPlayerKungfuID = {}
local tDelay = {}
function ArenaData.OnPlayerEnterScene(dwPlayerID)
	if not ArenaData.IsInArena() and not ArenaTowerData.IsInArenaTowerMap() then
		return
	end
	local hPlayer = GetPlayer(dwPlayerID)
	local bSuccess = false

	if not self.tbArenaBattleData then
		-- 扬刀大会初始化tQiXueInfo
		self.tbArenaBattleData = {
			tQiXueInfo = {}
		}
	end

	if hPlayer and hPlayer.dwForceID ~= 0 then
		tPlayerForce[dwPlayerID] = hPlayer.dwForceID
		TopBuffData.UpdateTopBuff(true, dwPlayerID)
		bSuccess = true
		local tInfo = {dwID = hPlayer.dwID, szName = hPlayer.szName, nIndex = hPlayer.nBattleFieldSide, dwMountKungfuID = hPlayer.GetActualKungfuMountID()}
		tPlayerKungfuID[tInfo.dwID] = tInfo.dwMountKungfuID
		self.tbArenaBattleData.tQiXueInfo[hPlayer.dwID] = tInfo
		if hPlayer.dwID ~= GetClientPlayer().dwID then
			ArenaData.GetPlayerQiXueAndSkillInfo(hPlayer.dwID)
		end
	end

	if not bSuccess then
		local nNowTime = GetTickCount()
		if not tDelay[dwPlayerID] then
			tDelay[dwPlayerID] = nNowTime
		end
		if nNowTime - tDelay[dwPlayerID] > 1000 * 60 then
			tDelay[dwPlayerID] = nil
			return
		end
		Timer.Add(ArenaData, 0.5, function() ArenaData.OnPlayerEnterScene(dwPlayerID) end)
	end
end

function ArenaData.PeekAllPlayerQiXue()
	local function PeekQiXue(nIndex)
		for dwID, tInfo in pairs(self.tbArenaBattleData.tQiXueInfo) do
			if tInfo.nIndex == nIndex and dwID ~= GetClientPlayer().dwID then
				ArenaData.GetPlayerQiXueAndSkillInfo(dwID)
			end
		end
	end

	PeekQiXue(0)
	PeekQiXue(1)
end

function ArenaData.OpenQiXuePanel()
	if (not ArenaData.IsInArena() and not ArenaTowerData.IsInArenaTowerMap()) or not self.tbArenaBattleData then
		return
	end
	local pPlayer = GetClientPlayer()
	if not pPlayer then
		return
	end

	local tPlayer = {}
	local nSelfSide = pPlayer.nBattleFieldSide
	local dwSelfID = pPlayer.dwID
	local bCanReport = not ArenaTowerData.IsInArenaTowerMap()
	for dwID, tInfo in pairs(self.tbArenaBattleData.tQiXueInfo) do
		-- if tInfo.bGetQiXue or dwID == dwSelfID then
			tInfo.bCanReport = bCanReport and (tInfo.nIndex == nSelfSide and dwID ~= dwSelfID)
			table.insert(tPlayer, tInfo)
		-- end
	end
	UIMgr.Open(VIEW_ID.PanelPVPJJCTeamMessage, tPlayer)
end

function ArenaData.GetArenaPlayerForce(dwPlayerID)
	return tPlayerForce[dwPlayerID] or 0
end

function ArenaData.GetArenaPlayerKungfuID(dwPlayerID)
	if not tPlayerKungfuID[dwPlayerID] then
		local pPlayer = GetPlayer(dwPlayerID)
		if pPlayer then
			tPlayerKungfuID[dwPlayerID] = pPlayer.GetActualKungfuMountID()
		end
	end

	return tPlayerKungfuID[dwPlayerID] or 0
end

function ArenaData.Init()
	-- ArenaBonusData.Init()
	self.tbNotifyList = {}
    self.tbCorpsInfo = {}
    self.tbCorpsMineInfo = {}
    self.tbCorpsMemberInfo = {}
    self.tbCorpsPeekID = {}
    self.tbWeaklyReward = {}
	self.tbBattleData = {}
	self.nBattleStartTime = -1
	self.nBattleStartCountDown = -1

	self.tbLevelRewardInfo = nil
	self.nGotLevel = nil

	self.nSyncTimer = nil --事件定时器
    self.ARENA_MASTER_3V3_ACTIVITYID = 247

	Event.Reg(ArenaData, "SYNC_CORPS_BASE_DATA", function(nCorpsID, nCorpsType, nPlayerID)
		self.tbCorpsInfo[nCorpsType] = GetCorpsInfo(nCorpsID, false)
		if table_is_empty(self.tbCorpsInfo) then
			self.SyncAllCorpsBaseInfo()
		end
		if nCorpsID and nCorpsID ~= 0 then
            SyncCorpsMemberData(nCorpsID, false, nPlayerID)
        end
	end)

	Event.Reg(ArenaData, "SYNC_CORPS_MEMBER_DATA", function (nCorpsID, nCorpsType, nPlayerID)
		local nClientPlayerID = self.nPlayerID or PlayerData.GetClientPlayer()

		if SyncCorpsMemberData(nCorpsID, false, nPlayerID) then
			self.SyncAllCorpsBaseInfo()
		end
		self.tbCorpsMemberInfo[nCorpsType] = GetCorpsMemberInfo(nCorpsID, false)
		for _, info in ipairs(self.tbCorpsMemberInfo[nCorpsType]) do
			if info.dwPlayerID == nClientPlayerID then
				self.tbCorpsMineInfo[nCorpsType] = info
			end
		end

		Event.Dispatch(EventType.OnArenaStateUpdate, self.nPlayerID)
	end)

	Event.Reg(ArenaData, "SYNC_CORPS_LIST", function (nPeekID)
		-- Event.Dispatch(EventType.OnArenaStateUpdate, nPeekID)
	end)

	Event.Reg(ArenaData, "REQUEST_ARENA_CORPS", function (nPeekID)
		ArenaData.SyncCorpsList(nPeekID)
	end)

	Event.Reg(ArenaData, "ON_ARENA_WEEKLY_INFO_UPDATE", function (nArenaType, tbInfo)
		local nType = tbDoubleType[nArenaType]
		self.tbWeaklyReward[nType] = tbInfo
	end)

	Event.Reg(ArenaData, "JOIN_ARENA_VISITOR_QUEUE", function (nArenaType, tbInfo)
		local bInWatchQueueBuff = Player_GetBuff(15011) --屏蔽服务端将玩家挪入jjc观战的错误提示
		if bInWatchQueueBuff then
			return
		end
		local szTip = g_tStrings.tArenaVisitorResult[arg0]
		if not szTip then
			return
		end

		if arg0 == ARENA_RESULT_CODE.SUCCESS then
			OutputMessage("MSG_ANNOUNCE_YELLOW", szTip)
			OutputMessage("MSG_SYS", szTip)
		else
			OutputMessage("MSG_ANNOUNCE_RED", szTip)
			OutputMessage("MSG_SYS", szTip)
		end
	end)

	Event.Reg(ArenaData, "ARENA_NOTIFY", function(nType, nArenaType, dwCorpsID, nAvgQueueTime, nPassTime, dwMapID, nCopyIndex, nCenterID, nGroupID, dwJoinValue, bSingle, dwIndex, bChaosFight, eGameType, bGlobalRoom)
		if nType == ARENA_NOTIFY_TYPE.ARENA_QUEUE_INFO and bChaosFight == 1 then -- 逻辑不在ARENATYPE增加练习模式枚举类型，使用arg12标识。
			nArenaType = ARENA_UI_TYPE.ARENA_PRACTICE
		elseif nType == ARENA_NOTIFY_TYPE.ARENA_QUEUE_INFO  and eGameType ~= ARENA_GAME_TYPE.NORMAL then
			g_tStrings.tCorpsType[ARENA_UI_TYPE.ARENA_ROBOT] = FormatString(g_tStrings.STR_ROBOT_MOD, g_tStrings.tCorpsType[nArenaType], g_tStrings.tRobotCorpsDifficulty[eGameType])
			nArenaType = ARENA_UI_TYPE.ARENA_ROBOT
		end

		if nType == ARENA_NOTIFY_TYPE.ARENA_QUEUE_INFO
		or nType == ARENA_NOTIFY_TYPE.LOG_IN_ARENA_MAP then
			local bFirst = false
			if not self.tbNotifyList[nArenaType] then
				self.tbNotifyList[nArenaType] = {}
				bFirst = true

				if nType == ARENA_NOTIFY_TYPE.ARENA_QUEUE_INFO then
					local szTip = FormatString(g_tStrings.STR_ARENA_QUEUE_WAIT, g_tStrings.tCorpsType[nArenaType])
					OutputMessage("MSG_ANNOUNCE_NORMAL", szTip)
				end
			end
			local nOldType = self.tbNotifyList[nArenaType].nNotifyType
			self.tbNotifyList[nArenaType].nArenaType = nArenaType
			self.tbNotifyList[nArenaType].nNotifyType = nType
			self.tbNotifyList[nArenaType].nAvgQueueTime = nAvgQueueTime
			self.tbNotifyList[nArenaType].nPassTime = nPassTime
			self.tbNotifyList[nArenaType].dwCorpsID = dwCorpsID
			self.tbNotifyList[nArenaType].bSingle = bSingle
			self.tbNotifyList[nArenaType].bGlobalRoom = bGlobalRoom

			if nType == ARENA_NOTIFY_TYPE.LOG_IN_ARENA_MAP then
				dwCompetitionIndex = dwIndex
				self.tbNotifyList[nArenaType].nCopyIndex = nCopyIndex
				self.tbNotifyList[nArenaType].nCenterID = nCenterID
				self.tbNotifyList[nArenaType].dwMapID = dwMapID

				self.tbNotifyList[nArenaType].nGroupID = nGroupID
				self.tbNotifyList[nArenaType].dwJoinValue = dwJoinValue
			end

			if nOldType == nType then
				Event.Dispatch("ARENA_UPDATE_TIME")
			end

			if bFirst then
				local tbMapList = ArenaData.GetMapList()
				for _, dwMapID in ipairs(tbMapList) do
					local nState, dwTotalSize, dwDownloadedSize = PakDownloadMgr.GetMapResPackState(dwMapID)
            		if nState ~= DOWNLOAD_OBJECT_STATE.DOWNLOADED and dwDownloadedSize < dwTotalSize then
						TipsHelper.ShowNormalTip("未下载场景资源，玩法中途下载将影响游戏体验")
						break
					end
				end

				BubbleMsgData.PushMsgWithType("ArenaQueueTips", {
					nBarTime = 0, 							-- 显示在气泡栏的时长, 单位为秒
					szContent = function ()
						local nPassTime, nAvgQueueTime = ArenaData.GetQueueTime()
						local szContent = string.format("预计排队：%s\n已排队%s", ArenaData.FormatArenaTime(nAvgQueueTime), ArenaData.FormatArenaTime(nPassTime))
						return szContent, 0.5
					end,
					szAction = function ()
						PvpEnterConfirmationData.OpenView(
							PlayEnterConfirmationType.InQueue,
							PlayType.Arena,
							{
								szTitle = "名剑大会排队中",
								onClickCancelQueue = function ()
									ArenaData.LeaveArenaQueue()
								end
							})
					end,
				})
				Event.Dispatch("ARENA_STATE_UPDATE")
			end

		elseif nType == ARENA_NOTIFY_TYPE.LOG_OUT_ARENA_MAP then
		elseif nType == ARENA_NOTIFY_TYPE.IN_BLACK_LIST then
		elseif nType == ARENA_NOTIFY_TYPE.LEAVE_BLACK_LIST then
		end

		if nType == ARENA_NOTIFY_TYPE.LOG_IN_ARENA_MAP then
			if not self.tbNotifyList[nArenaType].bRemind then
				self.tbNotifyList[nArenaType].dwStartTime = GetTickCount()
				self.tbNotifyList[nArenaType].nArenaEnterCount = Const.MAX_BATTLE_FIELD_OVERTIME
				self.tbNotifyList[nArenaType].bRemind = true
				local dialog = nil
				PSMMgr.ExitPSMMode()
				PvpEnterConfirmationData.OpenView(PlayEnterConfirmationType.Enter, PlayType.Arena, {
					szTitle = "名剑大会匹配成功",
					nStartTime = self.tbNotifyList[nArenaType].dwStartTime,
					nTotalCountDown = Const.MAX_BATTLE_FIELD_OVERTIME,
					onClickEnter = function ()
						ArenaData.AcceptJoinArena(nArenaType, self.tbNotifyList)
						UIMgr.CloseAllInLayer("UIPageLayer")
    					UIMgr.CloseAllInLayer("UIPopupLayer")
						BubbleMsgData.RemoveMsg("PVPMatchSuccessTips")
						if dialog then
							UIMgr.Close(dialog)
						end
					end,
					onClickGiveUp = function()
						local szMsg = FormatString(g_tStrings.STR_BATTLEFIELD_MESSAGE_SURE_LEAVE, g_tStrings.STR_ARENA_TITLE)
						dialog = UIHelper.ShowConfirm(szMsg, function()
							RemoteCallToServer("On_JJC_NotEnterJJC")
							ArenaData.DoLeaveArenaQueue(nArenaType)
							PvpEnterConfirmationData.CloseView(PlayType.Arena)
						end)
					end,
				})

				BubbleMsgData.RemoveMsg("ArenaQueueTips")

				BubbleMsgData.PushMsgWithType("PVPMatchSuccessTips", {
					nBarTime = 0, 							-- 显示在气泡栏的时长, 单位为秒
					szContent = "已匹配成功",
					nStartTime = GetCurrentTime(),
					nEndTime = Const.MAX_BATTLE_FIELD_OVERTIME + GetCurrentTime(),
					nTotalTime = Const.MAX_BATTLE_FIELD_OVERTIME,
					bShowTimeLabel = true,
					bHideTimeSilder = true,
					szAction = function ()
						PvpEnterConfirmationData.ShowView(PlayType.Arena)
					end,
				})
			end
			Event.Dispatch("ARENA_STATE_UPDATE")
		end
	end)

	Event.Reg(ArenaData, "LEAVE_ARENA_QUEUE", function(nErrorCode)
		ArenaData.SetCacheData("nRoomKey", nil)
		ArenaData.SetCacheData("nCreateArenaRoomTime", nil)

        self.tbNotifyList = {}
		BubbleMsgData.RemoveMsg("ArenaQueueTips")
		Event.Dispatch("ARENA_STATE_UPDATE")
    end)

	Event.Reg(ArenaData, "PLAYER_ENTER_SCENE", function(nPlayerID)
		if ArenaData.IsInArena() or ArenaTowerData.IsInArenaTowerMap() then
			tDelay[nPlayerID] = nil
		end
		ArenaData.OnPlayerEnterScene(nPlayerID)
	end)

	Event.Reg(ArenaData, "PLAYER_LEAVE_SCENE", function(nPlayerID)
		if not self.tbArenaBattleData then
			return
		end

		local player = GetClientPlayer()
		if not player or nPlayerID == player.dwID then
			self.tbArenaBattleData.tQiXueInfo = {}
			return
		end

		if not ArenaTowerData.IsInArenaTowerMap() then
			return
		end

		local nSelfSide = player.nBattleFieldSide
		local tInfo = self.tbArenaBattleData.tQiXueInfo[nPlayerID]
		if tInfo and tInfo.nIndex ~= nSelfSide then
			self.tbArenaBattleData.tQiXueInfo[nPlayerID] = nil -- 扬刀大会只显示当前在场的敌方机器人奇穴信息
		end
	end)

	Event.Reg(ArenaData, EventType.OnClientPlayerLeave, function()
		ArenaData.SetShowTop(false)
	end)

	Event.Reg(ArenaData, "PLAYER_LEAVE_GAME", function (nPlayerID)
		ArenaData.Reset()
	end)

	Event.Reg(ArenaData, "LOGIN_NOTIFY", function(nEvent)
		if nEvent == LOGIN.REQUEST_LOGIN_GAME_SUCCESS or nEvent == LOGIN.MISS_CONNECTION then
			ArenaData.Reset()
		end
    end)

	Event.Reg(ArenaData, EventType.OnArenaEventNotify, function(szEvent, ...)
        local tbParams = {...}
        if szEvent == "PLAYER_UPDATE" then
            if ArenaData.IsInArena() then
                self.tbBattleData = tbParams[1]
                self.nBattleStartTime = tbParams[2]
            end
		elseif szEvent == "START_COUNT_DOWN" then
			if ArenaData.IsInArena() then
				self.nBattleStartCountDown = tbParams[1]
				TipsHelper.PlayCountDown(self.nBattleStartCountDown)
			end
        end
    end)

	Event.Reg(ArenaData, "ON_JJC_LEVEL_AWARD_UPDATE", function(tbInfo, nGotLevel)
		self.tbLevelRewardInfo = tbInfo or {}
		self.nGotLevel = nGotLevel or 0
		Event.Dispatch(EventType.OnUpdateArenaRedPoint)
    end)

	Event.Reg(ArenaData, "LEVEL_AWARD_GET_SUCCESS", function()
        ArenaData.GetLevelAwardInfo()
    end)

	Event.Reg(ArenaData, "LOADING_END", function(szEvent, ...)
		ArenaData.GetLevelAwardInfo()

		local player = PlayerData.GetClientPlayer()
		if not ArenaData.IsInArena() then
			if self.bInArenaBattle then

			end

			self.bInArenaBattle = false
			return
		end

		self.bInArenaBattle = true
		local scene = player.GetScene()
		if scene.dwMapID then
			self.tbArenaBattleData = {
				tbAllPlayer			= {},
				tbPraised			= {},
				tbPraiseList 		= {},
				tbAddPraiseList 	= {},
				tbMutualPraiseList 	= {},
				tbExcellentData 	= {},
				tbBlackList 		= {},
				tQiXueInfo          = {},
			}
			ArenaData.ApplyArenaStatistics()
		end
		Event.Dispatch(EventType.OnSelectedTaskTeamViewToggle, true)
    end)

	Event.Reg(ArenaData, "ARENA_END", function(bIsSingle, bChaosFight)
		local player = PlayerData.GetClientPlayer()
		if not ArenaData.IsContestant(player) then return end

		if not self.nBattleStartTime or self.nBattleStartTime == 0 then
			self.nBattleGameTime = 0
		else
			if self.tbArenaBattleData.nCorpsType == ARENA_UI_TYPE.ARENA_2V2 then
				self.nBattleGameTime = math.min(GetCurrentTime() - self.nBattleStartTime + 1, ArenaData.MATCH_TIME2)
			else
				self.nBattleGameTime = math.min(GetCurrentTime() - self.nBattleStartTime + 1, ArenaData.MATCH_TIME)
			end
		end

		CameraCommon.EndWatch()
		ArenaData.ClearCacheData()
		ArenaData.ApplyArenaStatistics()
		ArenaData.ApplyBattleFieldStatistics()
		self.tbArenaBattleData.bArenaEnd = true
		self.tbArenaBattleData.bChaosFight = bChaosFight
    end)

	Event.Reg(ArenaData, "BATTLE_FIELD_SYNC_STATISTICS", function(szEvent, ...)
		-- LOG.INFO("----------------BATTLE_FIELD_SYNC_STATISTICS")
		if not ArenaData.IsInArena() then
			LOG.INFO("----------------BATTLE_FIELD_SYNC_STATISTICS-----not ArenaData.IsInArena()")
			return
		end

		local tbPQStat = ArenaData.GetBattleFieldStatistics()
		if not tbPQStat or IsTableEmpty(tbPQStat) then
			LOG.INFO("----------------BATTLE_FIELD_SYNC_STATISTICS-----not tbPQStat")
			return
		end

		self.tbArenaBattleData.tbPQStat = tbPQStat
		local _, _, nBeginTime, nEndTime  = ArenaData.GetBattleFieldPQInfo()
		local nCurrentTime = GetCurrentTime()
		if nBeginTime and nBeginTime > 0 then
			local nTime = 0
			if nEndTime ~= 0 and nCurrentTime > nEndTime then
				nTime = nEndTime - nBeginTime
			else
				nTime = nCurrentTime - nBeginTime
			end
			self.tbArenaBattleData.nAllTime = nTime
		end

		ArenaData.MergeBattleData()
    end)

	Event.Reg(ArenaData, "SYNC_ARENA_STATISTICS", function(szEvent, ...)
		-- LOG.INFO("----------------SYNC_ARENA_STATISTICS")
		if not ArenaData.IsInArena() then
			LOG.INFO("----------------SYNC_ARENA_STATISTICS-----not ArenaData.IsInArena()")
			return
		end

		local tbStat = ArenaData.GetArenaStatistics()
		if not tbStat or IsTableEmpty(tbStat) then
			LOG.INFO("----------------SYNC_ARENA_STATISTICS-----not tbStat")
			return
		end

		for k, v in pairs(tbStat) do
			if not v.nKillCount then
				v.nKillCount = 0
			end
		end
		local nCorpsType = tbStat[1].nCorpsType
		self.tbArenaBattleData.nCorpsType = nCorpsType
		self.tbArenaBattleData.tbArenaStat = tbStat

		for _, v in pairs(tbStat) do
            if not table.contain_value(self.tbArenaBattleData.tbAllPlayer, v.dwRoleID) then
                table.insert(self.tbArenaBattleData.tbAllPlayer, v.dwRoleID)
            end
        end
		ArenaData.UpdatePlayerQiXueInfo(tbStat)
		ArenaData.UpdateAllPlayerKungfuID()
        ArenaData.SetShowTop(ArenaData.IsInArena())

		ArenaData.MergeBattleData()
    end)

	Event.Reg(ArenaData, "SYS_MSG", function(szEvent, ...)
		if szEvent == "UI_OME_BANISH_PLAYER" then
			if not ArenaData.IsInArena() then
				return
			end

			local tbParams = {...}
			if tbParams[1] == BANISH_CODE.MAP_REFRESH or tbParams[1] == BANISH_CODE.NOT_IN_MAP_OWNER_PARTY then
				self.tbArenaBattleData.nBanishTime = tbParams[2] * 1000 + GetTickCount()
			elseif arg1 == BANISH_CODE.CANCEL_BANISH then
				self.tbArenaBattleData.nBanishTime = nil
			end
		elseif szEvent == "UI_OME_DEATH_NOTIFY" then
			if not ArenaData.IsInArena() then
				return
			end

			local dwID, dwKiller = arg1, arg2
			local szTargetName = ""
			local szKillerName = ""
			local tbSelfTeamData = ArenaData.GetBattlePlayerData(false)
			local tbEnemyTeamData = ArenaData.GetBattlePlayerData(true)
			for i, tbInfo in ipairs(tbSelfTeamData) do
				if tbInfo.dwID == dwKiller then
					szKillerName = UIHelper.GBKToUTF8(tbInfo.szName)
					break
				end
			end

			for i, tbInfo in ipairs(tbEnemyTeamData) do
				if tbInfo.dwID == dwID then
					szTargetName = UIHelper.GBKToUTF8(tbInfo.szName)
					break
				end
			end

			if not string.is_nil(szTargetName) and not string.is_nil(szKillerName) then
				Event.Dispatch("ShowMobaBattleMsg", szKillerName, szTargetName, UIHelper.UTF8ToGBK("data\\source\\other\\HD特效\\其他\\Pss\\S_杀伤效果.pss"))
			end
		end
    end)

	Event.Reg(ArenaData, "Update_FriendPraiseList", function(nType, tList)
		local tbArenaInfo = self.tbArenaBattleData
		if nType == 5 then --JJC
			tbArenaInfo.tbPraiseList = {}
			for k, v in pairs(tList) do
				if v ~= UI_GetClientPlayerID() then
					tbArenaInfo.tbPraiseList[v] = 1
				end
			end

			Event.Dispatch(EventType.OnUpdateArenaFinishDataFriendPraiseList)
		end
    end)

	Event.Reg(ArenaData, "ON_ARENA_ADD_PLAYER_TO_BLACK_LIST", function()
		local dwPlayerID, nResultCode = arg0, arg1
		OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_JJC_BLACK_RESULT[nResultCode]);
		OutputMessage("MSG_SYS", g_tStrings.STR_JJC_BLACK_RESULT[nResultCode])
    end)

	Event.Reg(ArenaData, "ON_CREATE_ARENA_ROOM_NOTIFY", function(nRoomKey, nErrorCode)
		if nErrorCode ~= ARENA_RESULT_CODE.SUCCESS then
			local szTip = g_tStrings.tArenaResult[nErrorCode]
			OutputMessage("MSG_ANNOUNCE_NORMAL", szTip);
			OutputMessage("MSG_SYS", szTip);
		else
			ArenaData.SetCacheData("nRoomKey", nRoomKey)
			ArenaData.SetCacheData("nCreateArenaRoomTime", GetTickCount())

			local nSide = ArenaData.GetCacheData("nCreateRoomSide", 0)
			ArenaData.JoinPracticeRoom(nRoomKey, nSide, false, true)
			Event.Dispatch("ARENA_STATE_UPDATE")
		end
    end)

	Event.Reg(ArenaData, "CORPS_OPERATION", function(nType, nRetCode, dwCorpsID, dwCorpsType, dwOperatorID, dwBeOperatorID, szOperatorName, szBeOperatorName, szCorpsName)
		local szTip = ""
		local player = PlayerData.GetClientPlayer()
		szOperatorName = UIHelper.GBKToUTF8(szOperatorName)
		szBeOperatorName = UIHelper.GBKToUTF8(szBeOperatorName)
		szCorpsName = UIHelper.GBKToUTF8(szCorpsName)

		if nRetCode == CORPS_OPERATION_RESULT_CODE.SUCCESS then
			if nType == CORPS_OPERATION_TYPE.CORPS_CREATE then
				ArenaData.tbClientCorps[dwCorpsType] = dwCorpsID
				szTip = g_tStrings.tArenaCorpsResult[nType][nRetCode]

			elseif nType == CORPS_OPERATION_TYPE.CORPS_DEL_MEMBER then
				szTip = g_tStrings.tArenaCorpsResult[nType][nRetCode]
				if player.dwID == dwBeOperatorID then
					ArenaData.tbClientCorps[dwCorpsType] = 0
					szBeOperatorName = g_tStrings.STR_NAME_YOU

				elseif not szBeOperatorName or szBeOperatorName == "" then
					szBeOperatorName = g_tStrings.TARGET
				elseif szBeOperatorName and szBeOperatorName ~= "" then
					szBeOperatorName = "[" .. szBeOperatorName .."]"
				end
				szTip = FormatString(szTip, szBeOperatorName, g_tStrings.tCorpsType[dwCorpsType])

				if dwBeOperatorID ~= player.dwID then
					SyncCorpsMemberData(dwCorpsID, false, self.nPlayerID or player.dwID)
				end
			elseif nType == CORPS_OPERATION_TYPE.CORPS_DESTROY then
				ArenaData.tbClientCorps[dwCorpsType] = 0
				szTip = g_tStrings.tArenaCorpsResult[nType][nRetCode]

			elseif nType == CORPS_OPERATION_TYPE.CORPS_ADD_MEMBER then
				szTip = g_tStrings.tArenaCorpsResult[nType][nRetCode]
				if player.dwID == dwBeOperatorID then
					ArenaData.tbClientCorps[dwCorpsType] = dwCorpsID
					szBeOperatorName = g_tStrings.STR_NAME_YOU

				elseif not szBeOperatorName or szBeOperatorName == "" then
					szBeOperatorName = g_tStrings.TARGET
				elseif szBeOperatorName and szBeOperatorName ~= "" then
					szBeOperatorName = "[" .. szBeOperatorName .."]"
				end
				szTip = FormatString(szTip, szBeOperatorName, g_tStrings.tCorpsType[dwCorpsType], szCorpsName)

				if dwBeOperatorID == player.dwID then
					ArenaData.SyncCorpsList(player.dwID)
				else
					SyncCorpsMemberData(dwCorpsID, false, self.nPlayerID or player.dwID)
				end
			elseif nType == CORPS_OPERATION_TYPE.INVITATION_JOIN_CORPS then
                if IsFilterOperateEnable("INVITE_ARENA_CORPS") then
                    --FireUIEvent("FILTER_INVITE_ARENA_CORPS", dwCorpsID, dwCorpsType, dwOperatorID, dwBeOperatorID, szOperatorName, szBeOperatorName)
                    return
                end

				if FellowshipData.IsInBlackListByPlayerID(dwOperatorID) then
					ArenaData.ApplyInvitationJoinCorps(dwOperatorID, dwCorpsID, false)
					return
				end

                if IsFilterOperate("INVITE_ARENA_CORPS") then
                    ArenaData.ApplyInvitationJoinCorps(dwOperatorID, dwCorpsID, false)
                    return
                end

                -- OnInviteRespond(dwCorpsID, dwCorpsType, dwOperatorID, dwBeOperatorID, szOperatorName, szBeOperatorName)
				if player.dwID == dwOperatorID then
					szTip = g_tStrings.tArenaCorpsResult[nType][nRetCode]
					szTip = FormatString(szTip, szBeOperatorName, g_tStrings.tCorpsType[dwCorpsType])
				end

				local szContent = FormatString(g_tStrings.STR_ARENA_INVITE_MSG1, szOperatorName, g_tStrings.tCorpsType[dwCorpsType])
				local fnConfirm = function ()
					ArenaData.ApplyInvitationJoinCorps(dwOperatorID, dwCorpsID, true)
					BubbleMsgData.RemoveMsg("ArenaInviteTip")
				end
				local fnCancel = function ()
					ArenaData.ApplyInvitationJoinCorps(dwOperatorID, dwCorpsID, false)
					BubbleMsgData.RemoveMsg("ArenaInviteTip")
				end
				BubbleMsgData.PushMsgWithType("ArenaInviteTip", {
					nBarTime = 0, -- 显示在气泡栏的时长, 单位为秒
					szContent = szContent,
					szAction = function()
						local scriptDialog = UIHelper.ShowConfirm(szContent, fnConfirm, fnCancel, false)
						scriptDialog:SetButtonContent("Confirm", "同意")
    					scriptDialog:SetButtonContent("Cancel", "拒绝")
					end})
			elseif nType == CORPS_OPERATION_TYPE.CORPS_CHANGE_LEADER then
				if szBeOperatorName and szBeOperatorName ~= "" then
					szBeOperatorName = "[" .. szBeOperatorName .."]"
				end
				szTip = FormatString(g_tStrings.tArenaCorpsResult[nType][nRetCode], g_tStrings.tCorpsType[dwCorpsType], szBeOperatorName)

				SyncCorpsMemberData(dwCorpsID, false, self.nPlayerID or player.dwID)
			end

			if szTip and szTip ~= "" then
				OutputMessage("MSG_ANNOUNCE_NORMAL", szTip);
				OutputMessage("MSG_SYS", szTip);
			end
		elseif player.dwID == dwOperatorID  then
			local szTip = g_tStrings.tArenaCorpsResult[nType][nRetCode]
			OutputMessage("MSG_ANNOUNCE_NORMAL", szTip);
			OutputMessage("MSG_SYS", szTip);
		end
    end)

	Event.Reg(ArenaData, "PLAYER_STATE_UPDATE", function()
		local player = PlayerData.GetClientPlayer()
		if player and arg0 == player.dwID and ArenaData.IsInArena() then
			if player.nMoveState == MOVE_STATE.ON_DEATH then
				CameraCommon.StartWatch(true)
			elseif CameraCommon.IsWatch() then
				CameraCommon.EndWatch()
			end
		end
    end)

	Event.Reg(ArenaData, "OnMutualPraise", function ()
		local nType = arg0
		local dwPlayerID = arg1
		if nType ~= 5 then
			return
		end
        self.OnMutualPraise(dwPlayerID)
    end)

    Event.Reg(ArenaData, "Add_FriendPraiseShow", function ()
		local nType = arg0
		local dwPlayerID = arg1
		if nType ~= 5 then
			return
		end
        self.OnAddPraise(dwPlayerID)
    end)

	Event.Reg(ArenaData, "ON_UPDATE_TALENT", function ()
		local dwPlayerID = arg0
		local nType = arg1
		self.OnGetPlayerQiXue(dwPlayerID, nType)
    end)

	-- Event.Reg(ArenaData, "UPDATE_TALENT_SET_SLOT_SKILL", function ()
	-- 	self.OnGetPlayerSkill()
    -- end)

end

function ArenaData.UnInit()
	self.nPlayerID = nil
	self.tbNotifyList = {}
    self.tbCorpsInfo = {}
    self.tbCorpsMineInfo = {}
    self.tbCorpsMemberInfo = {}
    self.tbCorpsPeekID = {}
    self.tbWeaklyReward = {}
	self.nSyncTimer = nil

	self.tbBattleData = {}
	self.nBattleStartTime = -1
	self.nBattleStartCountDown = -1

	-- 房间相关
	self.nRoomKey = nil
	self.nCreateArenaRoomTime = nil

	-- ArenaBonusData.UnInit()
end

function ArenaData.Reset()
	self.tbNotifyList = {}
    self.tbCorpsInfo = {}
    self.tbCorpsMineInfo = {}
    self.tbCorpsMemberInfo = {}
    self.tbCorpsPeekID = {}
    self.tbWeaklyReward = {}
	self.nRoomKey = nil
	self.nCreateArenaRoomTime = nil
end

------------------------------------------客户端逻辑---------------------------------------------------

function ArenaData.GetCorpsRoleInfo(nPlayerID, nArenaType)
	local tbInfo = GetCorpsRoleInfo(nPlayerID, nArenaType)
	return tbInfo or {}
end

function ArenaData.GetCorpsLevel(nPlayerID, nArenaType)
	local nScore = 1000
	local player = PlayerData.GetPlayer(nPlayerID)
	if nPlayerID == GetClientPlayer().dwID then
		nScore = player.GetCorpsLevel(nArenaType)
	else
		if not table.is_empty(self.tbCorpsInfo) then
			local nCorpsID = ArenaData.GetCorpsID(nArenaType, nPlayerID)
			self.tbCorpsInfo[nArenaType] = GetCorpsInfo(nCorpsID, false)
			if self.tbCorpsInfo[nArenaType] then
				nScore = self.tbCorpsInfo[nArenaType].nCorpsLevel
			end
		end
	end
	return nScore
end

function ArenaData.GetArenaLevel(nPlayerID, nArenaType)
	local nLevel = 0
	local tbInfo = ArenaData.GetCorpsRoleInfo(nPlayerID, nArenaType)
	if tbInfo and tbInfo.nArenaLevel then
		nLevel = tbInfo.nArenaLevel
	end
	return nLevel
end

local function CheckWeeklyInfoRequestTime(nArenaType)
	if not tbWeeklyRequestTime[nArenaType] then
		return false
	end

	if tbWeeklyRequestTime[nArenaType] < 0 then
		return true
	end

	return (GetTickCount() - tbWeeklyRequestTime[nArenaType]) > 10000
end

local function GetWeeklyInfo(nArenaType)
	local nType = tbDoubleType[nArenaType]
	local tbReward = self.tbWeaklyReward[nType]
	if not tbReward and CheckWeeklyInfoRequestTime(nArenaType) then
		RemoteCallToServer("On_JJC_GetArenaWeeklyInfo", nArenaType)
		tbWeeklyRequestTime[nArenaType] = GetTickCount()
	end
	return tbReward
end

function ArenaData.GetDoubleRewardInfo(nArenaType)
	local tbReward = GetWeeklyInfo(nArenaType)
	if not tbReward then
		return 0, 0
	end

	return tbReward.nLeftDoubleCount, tbReward.nMaxDoubleCount
end

local function GetRemainSpaceUsed(nArenaType)
	local tbReward = GetWeeklyInfo(nArenaType)
	if not tbReward then
		return 0
	end

	return tbReward.nRemainSpaceUsed
end

function ArenaData.GetPrestigeExtRemain(nArenaType, nScore)
	local player = GetClientPlayer()
	if not player then
		return
	end

	nScore = nScore or player.GetCorpsRoleLevel(nArenaType)
	local nRemainSpaceUsed = GetRemainSpaceUsed(nArenaType)
	local nPrestigeExtRemain = GDAPI_GetPrestigeExtRemain(player, nScore, nRemainSpaceUsed)
	return nPrestigeExtRemain
end

function ArenaData.GetQueueTime()
	local nPassTime, nAvgQueueTime = 0, 0
	local nQueueArenaType
	for nArenaType, tbInfo in pairs(self.tbNotifyList) do
		if tbInfo.nNotifyType == ARENA_NOTIFY_TYPE.ARENA_QUEUE_INFO then
			nPassTime, nAvgQueueTime = tbInfo.nPassTime, tbInfo.nAvgQueueTime
			nQueueArenaType = nArenaType
			break
		end
	end

	return nPassTime, nAvgQueueTime, nQueueArenaType
end

function ArenaData.IsInArenaQueue(nArenaType)
	if self.tbNotifyList[nArenaType] and self.tbNotifyList[nArenaType].nNotifyType == ARENA_NOTIFY_TYPE.ARENA_QUEUE_INFO then
		return true, self.tbNotifyList[nArenaType].bSingle, self.tbNotifyList[nArenaType].bGlobalRoom == 1
	end
	return false, false, false
end

function ArenaData.IsCanEnterArena()
	if not self.tbNotifyList then
		return false
	end

	for _, t in pairs(self.tbNotifyList) do
		if t and t.nNotifyType == ARENA_NOTIFY_TYPE.LOG_IN_ARENA_MAP then
			return true
		end
	end
	return false
end

function ArenaData.HasArenaInfo()
	local player = PlayerData.GetClientPlayer()
	if not player then
		return
	end

	if bBlacklist then
		return "disable"
	end

	for _, _ in pairs(self.tbNotifyList) do
		return "normal"
	end

	if ArenaData.IsInArena() then
		return "normal"
	end
end

function ArenaData.IsInArena()
	local player = PlayerData.GetClientPlayer()
	if player then
		local scene = player.GetScene()
		return scene.bIsArenaMap
	end
end

function ArenaData.IsJJCInjury()
	local player = PlayerData.GetClientPlayer()
	if not player then
		return false
	end
	if not ArenaData.IsInArena() then
		return false
	end
	if player.nMoveState == MOVE_STATE.ON_DEATH then
		return true
	end
	return false
end

function ArenaData.IsFinish()
	return self.tbArenaBattleData and self.tbArenaBattleData.bArenaEnd
end

function ArenaData.IsChaosFight()
	return self.tbArenaBattleData and self.tbArenaBattleData.bChaosFight
end

function ArenaData.IsMasterAreanOn()
	local bOn = ActivityData.IsActivityOn(ArenaData.ARENA_MASTER_3V3_ACTIVITYID)
	return bOn
end

function ArenaData.IsInMasterTime()
	local dwActivityID = GetArenaMasterActivityID()
	return ActivityData.IsActivityOn(dwActivityID)
end

function ArenaData.IsInBattle()
	if not ArenaData.IsInArena() then
		return false
	end

	local nArenaType = ArenaData.GetBattleArenaType()
    if not nArenaType then
		return false
	end

	if self.nBattleStartTime <= 0 then
		return false
	end

	local nEndTime = self.nBattleStartTime + ArenaData.MATCH_TIME2
	if nArenaType and nArenaType ~= ARENA_UI_TYPE.ARENA_2V2 then
		nEndTime = self.nBattleStartTime + ArenaData.MATCH_TIME
	end

	if GetCurrentTime() < nEndTime then
		return true
	end

	return false
end

function ArenaData.IsCanChangeSkillRecipe()
	if not ArenaData.IsInArena() then
		return true
	end

	local player = PlayerData.GetClientPlayer()
	local tbBuff = BuffMgr.GetAllBuff(player)
	for _, tbInfo in pairs(tbBuff) do
		if tbInfo.dwID == 11839 and tbInfo.nLevel == 1 then
			return true
		end
	end

	return false
end

function ArenaData.GetCorpsList()
	return self.tbCorpsList
end

function ArenaData.GetCorpsID(nArenaType, nPlayerID)
	if nPlayerID == PlayerData.GetPlayerID() then
		return GetCorpsID(nArenaType, nPlayerID)
	else
		return GetCorpsID(nArenaType, nPlayerID)
	end
end

local m_tLevelInfo = nil
local m_tLevelList = nil
local function LoadLevelInfo()
	m_tLevelInfo = {}
	m_tLevelList = {}
	for i, tLine in ilines(g_tTable.ArenaFightLevel) do
		if i >= 1 then
			m_tLevelInfo[tLine.level] = tLine
			table.insert(m_tLevelList, tLine)
		end
	end
end

function ArenaData.GetLevelInfo(nLevel)
	if not m_tLevelInfo or not m_tLevelList then
		LoadLevelInfo()
	end

	return m_tLevelInfo[nLevel]
end

function ArenaData.GetAllLevelInfo()
	if not m_tLevelInfo or not m_tLevelList then
		LoadLevelInfo()
	end

	return m_tLevelList
end

-------------------------------------------局内相关------------------------------------------------------
function ArenaData.IsContestant(player)
	if player.nBattleFieldSide == 0 or player.nBattleFieldSide == 1 then
		return true
	end
	return false
end

function ArenaData.GetArenaStatistics()
	local tbStatistics = GetArenaStatistics()
	return tbStatistics
end

function ArenaData.GetBattleFieldStatistics()
	local tbStatistics = GetBattleFieldStatistics()
	return tbStatistics
end

function ArenaData.GetBattleFieldPQInfo()
	local tbPQInfo = GetBattleFieldPQInfo()
	return tbPQInfo
end

function ArenaData.GetBattleArenaType()
	local nArenaType

	if self.tbArenaBattleData and self.tbArenaBattleData.nCorpsType then
		nArenaType = self.tbArenaBattleData.nCorpsType
	end

	return nArenaType
end

function ArenaData.MergeBattleData()
	local player = PlayerData.GetClientPlayer()
	if not ArenaData.IsContestant(player) then
		return
	end
	if not self.tbArenaBattleData.tbArenaStat or not self.tbArenaBattleData.tbPQStat then
		return
	end

	local tbTableIndex = {}
	for dwPlayerID, v in pairs(self.tbArenaBattleData.tbPQStat) do
		tbTableIndex[dwPlayerID] = v
	end

	local tbMVPData = {}
	self.tbArenaBattleData.tbExcellentData = {}
	local dwPlayerID = player.dwID
	for k, v in pairs(self.tbArenaBattleData.tbArenaStat) do
		local t = tbTableIndex[v.dwRoleID]
		if t then
			v.dwForceID          = ArenaData.GetArenaPlayerForce(v.dwRoleID)
			v.dwMountKungfuID    = ArenaData.GetArenaPlayerKungfuID(v.dwRoleID)
			v.nKillCount         = t[PQ_STATISTICS_INDEX.DECAPITATE_COUNT]
			v.nDamge             = t[PQ_STATISTICS_INDEX.HARM_OUTPUT]
			v.nHealth            = t[PQ_STATISTICS_INDEX.TREAT_OUTPUT]
			v.nNearDeath         = t[PQ_STATISTICS_INDEX.SPECIAL_OP_7]
			v.bJJCScoreProtected = (t[PQ_STATISTICS_INDEX.SPECIAL_OP_8] and t[PQ_STATISTICS_INDEX.SPECIAL_OP_8] == 1) or false
			if self.tbArenaBattleData.bArenaEnd then
				if v.bWin and v.bValidCount then
					v.dwMobileStreakWinCount = v.dwMobileStreakWinCount + 1
				else
					v.dwMobileStreakWinCount = 0
				end
				local tList = {}
				if v.bMVP then
					table.insert(tList, EXCELLENT_ID.MVP)
					if v.bWin then
						tbMVPData[v.dwRoleID] = {EXCELLENT_ID.MVP}
					end
				end

				if v.dwMobileStreakWinCount >= ArenaData.MIN_SHOW_WIN_COUNT then
					table.insert(tList, EXCELLENT_ID.WIN_COUNT)
				end

				self.tbArenaBattleData.tbExcellentData[v.dwRoleID] = tList

				if v.dwRoleID == dwPlayerID then
					self.tbArenaBattleData.bWin = v.bWin
					self.tbArenaBattleData.bMVP = v.bMVP
					self.tbArenaBattleData.dwMobileStreakWinCount = v.dwMobileStreakWinCount
					self.tbArenaBattleData.bValidCount = v.bValidCount
				end
			end
		end
	end

	--申请可点赞的人
	-- LOG.INFO("----------self.tbArenaBattleData.bArenaEnd:%s", tostring(self.tbArenaBattleData.bArenaEnd))
	if self.tbArenaBattleData.bArenaEnd then
		local tList = {}
		for k, v in pairs(self.tbArenaBattleData.tbArenaStat) do
			table.insert(tList, v.dwRoleID)
		end
		RemoteCallToServer("On_FriendPraise_PraiseList", 5, tList)
		-- LOG.INFO("------1----self.tbArenaBattleData.bArenaEnd:%s", tostring(self.tbArenaBattleData.bArenaEnd))

		if not self.tbArenaBattleData.bWin and self.tbArenaBattleData.bValidCount then	--可拉黑的人
			for k, v in pairs(self.tbArenaBattleData.tbArenaStat) do
				if not v.bWin and v.dwRoleID ~= UI_GetClientPlayerID() then
					self.tbArenaBattleData.tbBlackList[v.dwRoleID] = 1
				end
			end
		end

		UIMgr.CloseAllInLayer("UIPageLayer")
		UIMgr.CloseAllInLayer("UIPopupLayer")

		if not UIMgr.IsViewOpened(VIEW_ID.PanelPVPSettleData) and not UIMgr.IsViewOpened(VIEW_ID.PanelPvPSettlement) then
			-- LOG.INFO("----2------self.tbArenaBattleData.bWin:%s", tostring(self.tbArenaBattleData.bWin))
			local nPersonalCardSettleTimerID
			if not table.is_empty(tbMVPData) then
				nPersonalCardSettleTimerID = Timer.AddFrame(self, 5, function()
					local nSelfSide = 0
					local player = PlayerData.GetClientPlayer()
					if player then
						nSelfSide = player.nBattleFieldSide
					end

					local scriptCard = UIMgr.Open(VIEW_ID.PanelBattlePersonalCardSettle, tbMVPData, nSelfSide, self.tbArenaBattleData.nBanishTime, function ()
						UIMgr.Close(VIEW_ID.PanelBattlePersonalCardSettle)
						UIMgr.Open(VIEW_ID.PanelPVPSettleData, self.tbArenaBattleData, function ()
							UIMgr.Open(VIEW_ID.PanelBattlePersonalCardSettle, tbMVPData, nSelfSide, self.tbArenaBattleData.nBanishTime, function ()
								UIMgr.Close(VIEW_ID.PanelBattlePersonalCardSettle)
							end)
						end)
					end)
					scriptCard:SetVisible(false)
				end)
			end

			PSMMgr.ExitPSMMode() -- PanelPvPSettlement 竞技场结算特效， PanelPVPSettleData 竞技场结算数据界面
			UIMgr.Open(VIEW_ID.PanelPvPSettlement, self.tbArenaBattleData.bWin, function()
				-- LOG.INFO("----3------self.tbArenaBattleData.bWin:%s", tostring(self.tbArenaBattleData.bWin))
				local player = PlayerData.GetClientPlayer()
				if table.is_empty(tbMVPData) then
					UIMgr.Open(VIEW_ID.PanelPVPSettleData, self.tbArenaBattleData)
				else
					Timer.DelTimer(self, nPersonalCardSettleTimerID)
					local scriptCard = UIMgr.GetViewScript(VIEW_ID.PanelBattlePersonalCardSettle)
					if scriptCard then
						scriptCard:SetVisible(true)
					else
						local nSelfSide = 0
						if player then
							nSelfSide = player.nBattleFieldSide
						end

						UIMgr.Open(VIEW_ID.PanelBattlePersonalCardSettle, tbMVPData, nSelfSide, self.tbArenaBattleData.nBanishTime, function ()
							UIMgr.Close(VIEW_ID.PanelBattlePersonalCardSettle)
							UIMgr.Open(VIEW_ID.PanelPVPSettleData, self.tbArenaBattleData, function ()
								UIMgr.Open(VIEW_ID.PanelBattlePersonalCardSettle, tbMVPData, nSelfSide, self.tbArenaBattleData.nBanishTime, function ()
									UIMgr.Close(VIEW_ID.PanelBattlePersonalCardSettle)
								end)
							end)
						end)
					end
				end
			end, true, not self.tbArenaBattleData.bValidCount)
		end
	end
end

function ArenaData.GetPlayerQiXueAndSkillInfo(dwPlayerID)
	PeekOtherPlayerTalentSetSlotSkillList(dwPlayerID)
	PeekOtherPlayerSkillRecipe(dwPlayerID)
	PeekOtherPlayerTalent(dwPlayerID, QIXUE_TYPE.PVP_SHOW)
end

function ArenaData.UpdateAllPlayerKungfuID()
	local player = PlayerData.GetClientPlayer()
	if not player then
		return
	end
	local scene  = player.GetScene()
	local nCount  = scene.GetArenaPlayerCount()
    if nCount <= 0 then
        return
    end

	for i = 1, nCount, 1 do
		local dwID, szName, dwForceID, dwMountKungfuID, nBattleFieldSide, nCurrentLife, nMaxLife, nArenaLevel = scene.GetArenaPlayer(i - 1)
		if dwID and dwMountKungfuID then
			tPlayerKungfuID[dwID] = dwMountKungfuID
		end
	end
end

function ArenaData.UpdatePlayerQiXueInfo(tArenaStat)
	for _, v in pairs(tArenaStat) do
		local tInfo = {dwID = v.dwRoleID, szName = v.szPlayerName, nIndex = v.nGroupID}
		local pPlayer = GetPlayer(v.dwRoleID)
		if pPlayer then
			tInfo.dwMountKungfuID = pPlayer.GetActualKungfuMountID()
		end
		if v.dwRoleID ~= GetClientPlayer().dwID then
			ArenaData.GetPlayerQiXueAndSkillInfo(v.dwRoleID)
		end
		self.tbArenaBattleData.tQiXueInfo[v.dwRoleID] = tInfo
	end
end

function ArenaData.GetBattlePlayerData(bEnemy)
	local tbData = {}

	local player = PlayerData.GetClientPlayer()
	local scene  = player.GetScene()
	local nCount  = scene.GetArenaPlayerCount()

    if nCount <= 0 then
        return tbData
    end

	for i = 1, nCount, 1 do
		local tbInfo = {}
		-- TODO:KARENA_PLAYER_INFO 需要补充武器、奇穴数据
		tbInfo.dwID, tbInfo.szName, tbInfo.dwForceID, tbInfo.dwMountKungfuID, tbInfo.nBattleFieldSide, tbInfo.nCurrentLife, tbInfo.nMaxLife, tbInfo.nArenaLevel = scene.GetArenaPlayer(i - 1)
		if tbInfo.nBattleFieldSide == 0 or tbInfo.nBattleFieldSide == 1 then
			if bEnemy and player.nBattleFieldSide ~= tbInfo.nBattleFieldSide then
				table.insert(tbData, tbInfo)
			elseif not bEnemy and player.nBattleFieldSide == tbInfo.nBattleFieldSide then
				table.insert(tbData, tbInfo)
			end
		end
	end

	return tbData
end

function ArenaData.GetBattlePlayerDataByForce(bEnemy)
	local tbData = {}

	local player = PlayerData.GetClientPlayer()
	local scene  = player.GetScene()
	local nCount  = scene.GetArenaPlayerCount()

    if nCount <= 0 then
        return tbData
    end

	for i = 1, nCount, 1 do
		local tbInfo = {}
		-- TODO:KARENA_PLAYER_INFO 需要补充武器、奇穴数据
		tbInfo.dwID, tbInfo.szName, tbInfo.dwForceID, tbInfo.dwMountKungfuID, tbInfo.nBattleFieldSide, tbInfo.nCurrentLife, tbInfo.nMaxLife, tbInfo.nArenaLevel = scene.GetArenaPlayer(i - 1)
		tbData[tbInfo.dwForceID] = tbData[tbInfo.dwForceID] or {}
		if tbInfo.nBattleFieldSide == 0 or tbInfo.nBattleFieldSide == 1 then
			if bEnemy and player.nBattleFieldSide ~= tbInfo.nBattleFieldSide then
    			table.insert(tbData[tbInfo.dwForceID], tbInfo.dwID)
			elseif not bEnemy and player.nBattleFieldSide == tbInfo.nBattleFieldSide then
    			table.insert(tbData[tbInfo.dwForceID], tbInfo.dwID)
			end
		end
	end
	return tbData
end

function ArenaData.GetPlayerStatisticData(dwPlayerID)
    local tbArenaInfo = self.tbArenaBattleData or {}
	for _, tData in pairs(tbArenaInfo.tbArenaStat or {}) do
		if tData.dwRoleID == dwPlayerID then
			return tData
		end
	end
end

function ArenaData.CanAddPraise(dwPlayerID)
	local bResult = false
    local tbArenaInfo = self.tbArenaBattleData or {}
	if tbArenaInfo.tbPraiseList and tbArenaInfo.tbPraiseList[dwPlayerID] then
		bResult = true
	end
	return bResult
end

function ArenaData.OnAddPraise(dwPlayerID)
    local tbArenaInfo = self.tbArenaBattleData or {}
	if not tbArenaInfo.tbAddPraiseList then
		tbArenaInfo.tbAddPraiseList = {}
	end
	tbArenaInfo.tbAddPraiseList[dwPlayerID] = (tbArenaInfo.tbAddPraiseList[dwPlayerID] or 0) + 1
	Event.Dispatch(EventType.OnUpdateArenaFinishDataFriendPraiseList)
end

function ArenaData.OnGetPlayerQiXue(dwID, nType)
	if (not ArenaData.IsInArena() and not ArenaTowerData.IsInArenaTowerMap()) or not self.tbArenaBattleData then
		return
	end
	local tQiXueInfo = self.tbArenaBattleData.tQiXueInfo

	if nType == QIXUE_TYPE.PVP_SHOW and dwID and tQiXueInfo[dwID] then
		local hPlayer = GetPlayer(dwID)
		tQiXueInfo[dwID].bGetQiXue = true
		if hPlayer then
			local nSetID
			local nCurrentKungFuID = hPlayer.GetActualKungfuMountID()
			if nCurrentKungFuID then
				tQiXueInfo[dwID].dwMountKungfuID = nCurrentKungFuID
				nSetID = hPlayer.GetTalentCurrentSet(hPlayer.dwForceID, nCurrentKungFuID)
			end
			local tKungfu = nCurrentKungFuID and nCurrentKungFuID > 0 and GetSkill(nCurrentKungFuID, 1)
			tQiXueInfo[dwID].nKungfuMountType = tKungfu and tKungfu.dwMountType

			tQiXueInfo[dwID].tTalentInfo = hPlayer.GetTalentInfo(hPlayer.dwForceID, tQiXueInfo[dwID].dwMountKungfuID, nSetID)
			tQiXueInfo[dwID].tSkillInfo = hPlayer.GetSlotToSkillList(nSetID)
			-- 1-5 为普通招式槽位 策划说还想看小轻功 将相关数据放在第六槽位
			tQiXueInfo[dwID].tSkillInfo[6] = SkillData.GetForceSpecialSprintID(hPlayer.dwSchoolID)
		end
	end
end

function ArenaData.OnMutualPraise(dwPlayerID)
    local tbArenaInfo = self.tbArenaBattleData or {}
	if not tbArenaInfo.tbMutualPraiseList then
		tbArenaInfo.tbMutualPraiseList = {}
	end
	tbArenaInfo.tbMutualPraiseList[dwPlayerID] = true
	Event.Dispatch(EventType.OnUpdateArenaFinishDataFriendPraiseList)
end

function ArenaData.IsPraised(dwPlayerID)
	local bResult = false
    local tbArenaInfo = self.tbArenaBattleData or {}
	if tbArenaInfo.tbPraised and tbArenaInfo.tbPraised[dwPlayerID] then
		bResult = true
	end
	return bResult
end

function ArenaData.IsAddPraise(dwPlayerID)
	local bResult = false
    local tbArenaInfo = self.tbArenaBattleData or {}
	if tbArenaInfo.tbAddPraiseList and tbArenaInfo.tbAddPraiseList[dwPlayerID] then
		bResult = true
	end
	return bResult
end

function ArenaData.IsMutualPraise(dwPlayerID)
	local bResult = false
    local tbArenaInfo = self.tbArenaBattleData or {}
	if tbArenaInfo.tbMutualPraiseList and tbArenaInfo.tbMutualPraiseList[dwPlayerID] then
		bResult = true
	end
	return bResult
end

function ArenaData.ReqPraise(dwPlayerID)
	local player = GetClientPlayer()
	if not player then
		return
	end
	RemoteCallToServer("On_FriendPraise_AddRequest", player.dwID, dwPlayerID, 5)

	local tbArenaInfo = self.tbArenaBattleData or {}
	if not tbArenaInfo.tbPraised then
		tbArenaInfo.tbPraised = {}
	end
	tbArenaInfo.tbPraised[dwPlayerID] = true
end

function ArenaData.ReqPraiseAll()
	local player = GetClientPlayer()
	if not player then
		return
	end

	local tPlayerID = {}
	local tbArenaInfo = self.tbArenaBattleData

	for dwPlayerID, _ in pairs(tbArenaInfo.tbPraiseList) do
		local tbArenaInfo = self.tbArenaBattleData or {}
		if not tbArenaInfo.tbPraised then
			tbArenaInfo.tbPraised = {}
		end
		if not tbArenaInfo.tbPraised[dwPlayerID] then
			tbArenaInfo.tbPraised[dwPlayerID] = true
			table.insert(tPlayerID, dwPlayerID)
		end
	end

	if not table.is_empty(tPlayerID) then
		RemoteCallToServer("On_FriendPraise_AddRequestAll", player.dwID, tPlayerID, 5)
	end
end
function ArenaData.GetPraiseCount(dwPlayerID)
	local nCount = 0
    local tbArenaInfo = self.tbArenaBattleData or {}
	if tbArenaInfo.tbAddPraiseList and tbArenaInfo.tbAddPraiseList[dwPlayerID] then
		nCount = tbArenaInfo.tbAddPraiseList[dwPlayerID]
	end
	return nCount
end

function ArenaData.OnTeamAutoMarkPlayer()
	local team = GetClientTeam()
	if not team then
		return
	end
	local tbEnemyList = self.GetBattlePlayerDataByForce(true)
	if table.is_empty(tbEnemyList) then
		return
	end

	local tbMarkList = TeamMarkData.GetTeamMarkInfo()
	local tbMarkTemp = {} -- 已占用标记
	for _, nMID in pairs(tbMarkList) do
		tbMarkTemp[nMID] = true
	end

	local bMarkFull = false
	for _, v in pairs(self.tbArenaMarkForcePriority) do
		if tbEnemyList[v] then
			for _, dwForcePID in pairs(tbEnemyList[v]) do
				for i = 1, 10 do
					if not tbMarkTemp[i] then
						team.SetTeamMark(i, dwForcePID)
						tbMarkTemp[i] = true
						tbMarkList[dwForcePID] = i
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
end

function ArenaData.SetCacheData(szKey, value)
	self._tbCacheData = self._tbCacheData or {}
	self._tbCacheData[szKey] = value
end

function ArenaData.GetCacheData(szKey, defaultValue)
	self._tbCacheData = self._tbCacheData or {}
	return self._tbCacheData[szKey] or defaultValue
end

function ArenaData.ClearCacheData()
	self._tbCacheData = {}
end

function ArenaData.FormatArenaTime(nTime)
	local szTime
	if nTime > 60 then
		szTime = math.floor(nTime / 60) .. g_tStrings.STR_BUFF_H_TIME_M
	else
		szTime = nTime .. g_tStrings.STR_BUFF_H_TIME_S
	end
	return szTime
end

function ArenaData.FormatArenaQueueTip(szBattleField, nPassTime, nAvgTime)
	local szBattleField = GetFormatText(szBattleField, STRESS_FONT)
	local szTip = FormatString(
		g_tStrings.STR_BATTLEFIELD_QUEUE_WAIT,
		"\"font=" .. NORMAL_FONT .. " </text>" .. szBattleField .. "<text>text=\""
	)
	szTip = szTip .. "\n"
	szTip = "<text>text=\"" .. szTip .. "\" font=" .. NORMAL_FONT .. "</text>"

	if nAvgTime > 0 then
		szTip = szTip .. GetFormatText(g_tStrings.STR_BATTLEFIELD_QUEUE_AVGTIME, NORMAL_FONT)
		szTip = szTip .. GetFormatText(FormatArenaTime(nAvgTime) .. "\n", STRESS_FONT)
	else
		szTip = szTip .. GetFormatText(g_tStrings.STR_BATTLEFIELD_QUEUE_TIME_UNKNOW .. "\n", NORMAL_FONT)
	end

	szTip = szTip .. GetFormatText(g_tStrings.STR_BATTLEFIELD_QUEUE_PASSTIME, NORMAL_FONT)
	szTip = szTip .. GetFormatText(FormatArenaTime(nPassTime) .. "\n", STRESS_FONT)
	szTip = szTip .. g_tStrings.STR_ARENA_QUEUE_TIP
	return szTip
end

-------------------------------------------协议相关---------------------------------------------------
function ArenaData.JoinArenaQueue(nArenaType, bSingle, nArenaGameType, bOpenRecord)
	if bOpenRecord == nil then
		bOpenRecord = false
	end

	local tbMapList = ArenaData.GetMapList()
    if PakDownloadMgr.UserCheckDownloadMapRes(tbMapList, nil, nil, nil, "名剑大会") then
		LOG.INFO("------ArenaData.JoinArenaQueue---------nArenaType:%d,%s,%d,%s", nArenaType, tostring(bSingle), nArenaGameType, tostring(bOpenRecord))
		JoinArenaQueue(nArenaType, bSingle, nArenaGameType, bOpenRecord)
	end
end

function ArenaData.JoinRoomArena(nArenaType)
	LOG.INFO("------ArenaData.JoinRoomArena---------")
	RemoteCallToServer("On_JJC_RoomArena", nArenaType, ARENA_GAME_TYPE.NORMAL, false)
end

function ArenaData.LeaveArenaQueue()
	LOG.INFO("------ArenaData.LeaveArenaQueue---------")
	LeaveArenaQueue()
end

function ArenaData.ApplyArenaStatistics()
	ApplyArenaStatistics()
end

function ArenaData.ApplyBattleFieldStatistics()
	ApplyBattleFieldStatistics()
end

function ArenaData.LogOutArena()
	LogOutArena()
end

function ArenaData.AcceptJoinArena(nArenaType, tbNotifyList)
	if not tbNotifyList then return end
	local tData = tbNotifyList[nArenaType]
	if tData then
		ArenaData.DoAcceptJoinArena(nArenaType, tData.nCenterID, tData.dwMapID, tData.nCopyIndex, tData.nGroupID, tData.dwJoinValue, tData.dwCorpsID, tData.bSingle)
	end
end

function ArenaData.DoAcceptJoinArena(nArenaType, nCenterID, dwMapID, nCopyIndex, nGroupID, dwJoinValue, dwCorpsID, bSingle)
	self.tbNotifyList[nArenaType] = nil
	ArenaData.ClearCacheData()
	Event.Dispatch("ARENA_STATE_UPDATE")
	LogInArena(nArenaType, nCenterID, dwMapID, nCopyIndex, nGroupID, dwJoinValue, dwCorpsID)
end

function ArenaData.DoLeaveArenaQueue(nArenaType)
	self.tbNotifyList[nArenaType] = nil
	ArenaData.ClearCacheData()
	Event.Dispatch("ARENA_STATE_UPDATE")
	LeaveArenaQueue()
end

function ArenaData.CreatePracticeRoom(nCreateRoomMapID, nCreatePracticeRoomType)
	RemoteCallToServer("On_JJC_CreateChaosRoom", nCreateRoomMapID, nCreatePracticeRoomType)
end

function ArenaData.JoinPracticeRoom(szRoomID, nJoinType, bTeam, bAuto)
	if bTeam then
		RemoteCallToServer("On_JJC_JoinChaosFightTeam", szRoomID, nJoinType, bAuto)
	else
		RemoteCallToServer("On_JJC_JoinChaosFight", szRoomID, nJoinType, bAuto)
	end
end

function ArenaData.CreateCorps(nArenaType, szName)
	szName = UIHelper.UTF8ToGBK(szName)
	CreateCorps(nArenaType, szName)
end

function ArenaData.DestroyCorps(nCorpsID)
	DestroyCorps(nCorpsID)
end

function ArenaData.CorpsDelMember(nDelPlayerID, nCorpsID)
	CorpsDelMember(nDelPlayerID, nCorpsID)
end

function ArenaData.CorpsChangeLeader(nChangePlayerID, nCorpsID)
	CorpsChangeLeader(nChangePlayerID, nCorpsID)
end

function ArenaData.InvitationJoinCorps(szInviteesName, nCorpsID)
	szInviteesName = UIHelper.UTF8ToGBK(szInviteesName)
	InvitationJoinCorps(szInviteesName, nCorpsID)
end

function ArenaData.ApplyInvitationJoinCorps(nInvitationPlayerID, nCorpsID, bAcceptInvitation)
	ApplyInvitationJoinCorps(nInvitationPlayerID, nCorpsID, bAcceptInvitation)
end

function ArenaData.SyncAllCorpsBaseInfo()
	if self.nSyncTimer then
		Timer.DelTimer(self, self.nSyncTimer)
		self.nSyncTimer = nil
	end

	self.nSyncTimer = Timer.Add(self, 0.5, function()
		local nPlayerID = self.nPlayerID or PlayerData.GetPlayerID()
		RemoteCallToServer("On_JJC_ApplyHighestRankScore", nPlayerID)
		ArenaData.SyncCorpsList(nPlayerID)
		for nCorpsType = ARENA_UI_TYPE.ARENA_BEGIN, ARENA_UI_TYPE.ARENA_END - 1 do
			local nCorpsID = ArenaData.GetCorpsID(nCorpsType, nPlayerID)
			if nCorpsID and nCorpsID ~= 0 then
				SyncCorpsBaseData(nCorpsID, false, nPlayerID)
				self.tbCorpsMemberInfo[nCorpsType] = GetCorpsMemberInfo(nCorpsID, false)
				self.tbCorpsInfo[nCorpsType] = GetCorpsInfo(nCorpsID, false)
			end
		end
		Timer.DelTimer(self, self.nSyncTimer)
		self.nSyncTimer = nil
	end)
end

function ArenaData.SyncCorpsList(nPeekID)
	if self.tbCorpsPeekID then
		if nPeekID == self.nPlayerID then
			self.tbCorpsPeekID[nPeekID] = ArenaData.tbClientCorps
		else
			self.tbCorpsPeekID[nPeekID] = _tTargetCorps
		end
	end
	SyncCorpsList(nPeekID)
end

function ArenaData.GetLevelAwardInfo()
	RemoteCallToServer("On_JJC_CanGetLevelAward")
end

function ArenaData.GetLevelAward(nArenaType)
	RemoteCallToServer("On_JJC_GetLevelAward", nArenaType)
end

function ArenaData.GetMasterBuffCustomValue()
	RemoteCallToServer("On_JJC_GetBuffCus")
end

local ARENA_1V1_DATA = 1181
function ArenaData.ApplyPlayerSoloInfo(dwPlayerID)
	local player = GetClientPlayer()
	if not player then
		return
	end

	if dwPlayerID and dwPlayerID ~= player.dwID then
		if not HaveOtherPlayerRemoteData(dwPlayerID, ARENA_1V1_DATA) then
			PeekPlayerRemoteData(dwPlayerID, ARENA_1V1_DATA)
			return
		end
	else
		if not player.HaveRemoteData(ARENA_1V1_DATA) then
			player.ApplyRemoteData(ARENA_1V1_DATA)
			return
		end
	end

	return true
end

function ArenaData.GetPlayerSoloInfo(dwPlayerID)
	local player = GetClientPlayer()
	if not player then
		return
	end

	if not ArenaData.ApplyPlayerSoloInfo(dwPlayerID) then
		return
	end

	return GDAPI_GetPlayerSoloInfo(player, dwPlayerID)
end

function ArenaData.SetPlayerIDByPeek(nPlayerID)
	self.nPlayerID = nPlayerID
end

function ArenaData.IsInWarning(nScore, nWin, bTeam)
	if nScore >= 2400 and nScore <2500 and nWin < 5 then --分数高于2400，本周胜场小于5
		return true, 5
	end

	if nScore >= 2500 and nWin < 10 then --分数高于2500，本周胜场小于10
		return true, 10
	end

	return false
end

function ArenaData.GetAutoName(tList)
	if not ArenaData.tAutoNameList then
		ArenaData.tAutoNameList = Table_GetAutoCorpsNameList()
	end

	local t = {}
	local szName = ""
	for k, v in ipairs(tList) do
		if v.dwForceID then
			if not t[v.dwForceID] then
				t[v.dwForceID] = 0
			end
			t[v.dwForceID] = t[v.dwForceID] + 1
		end
	end

	local bInit = false
	for k, v in pairs(ArenaData.tAutoNameList) do
		if t[k] and t[k] > 0 then
			if not bInit then
				bInit = true
				szName = v.szPreTitle
			end
			for i = 1, t[k] do
				szName = szName .. v.szTitle
			end
		end
	end
	if szName ~= "" then
		szName = szName .. UIHelper.UTF8ToGBK(g_tStrings.STR_ARENA_LIVE_TEAM)
	end
	return szName
end

function ArenaData.GetMapList()
	local tbMapList = {}
	local tbMapInfo = Table_GetMapInfoIdxByMapID()
	for nMapID, _ in pairs(tbMapInfo) do
		table.insert(tbMapList, nMapID)
	end

	return tbMapList
end

function ArenaData.SetUISelectIndex(nIndex)
	self.nUISelectIndex = nIndex
end

function ArenaData.GetUISelectIndex()
	return self.nUISelectIndex
end


function ArenaData.IsCanReportPlayer(szRoleName)
	if not ArenaData.IsInArena() then
		return
	end

	local player = GetClientPlayer()
	if not player then
		return
	end

	local bIsInParty = player.IsInParty()
	if not bIsInParty then
		return
	end

	local hTeam = GetClientTeam()
	if not hTeam then
		return
	end

	local tMembers = {}
	hTeam.GetTeamMemberList(tMembers)
	for _, dwMemberID in pairs(tMembers) do
		local tMemberInfo = hTeam.GetMemberInfo(dwMemberID)
		if tMemberInfo and dwMemberID ~= player.dwID and
			tMemberInfo.szName == szRoleName then
			return dwMemberID
		end
	end
end

function ArenaData.SetShowTop(bShow, bForce)
	-- 这里暂时没问题，先不调用
	-- local tAllPlayer = self.tbArenaBattleData and self.tbArenaBattleData.tAllPlayer
	-- if not tAllPlayer or IsTableEmpty(tAllPlayer) then
	-- 	return
	-- end

	-- for k, dwPlayerID in ipairs(tAllPlayer) do
	-- 	TopBuffData.UpdateTopBuff(bShow, dwPlayerID, bForce)
	-- end
end


function ArenaData.OpenPvpMatching(nMode)
	local nSelectMode = DXModeToVkMode[nMode] or nMode
	UIMgr.Open(VIEW_ID.PanelPvPMatching, nil, nSelectMode, true)
end