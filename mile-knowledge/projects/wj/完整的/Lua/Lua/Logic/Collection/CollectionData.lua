-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: CollectionData
-- Date: 2023-12-18 15:49:20
-- Desc: ?
-- ---------------------------------------------------------------------------------

CollectionData = CollectionData or {className = "CollectionData"}
local self = CollectionData
-------------------------------- 消息定义 --------------------------------
CollectionData.Event = {}
CollectionData.Event.XXX = "CollectionData.Msg.XXX"


local DAILY_FB_ACTIVITY_ID = 29
local nDefaultQuestID = 25449
local MAX_SHOW_NUM = 10000

local CLASS_LIST = {
	1,2,3
}


local PAGETYPE_TO_CLASS = {
	[COLLECTION_PAGE_TYPE.SECRET] = CLASS_MODE.FB,--秘境
	[COLLECTION_PAGE_TYPE.CAMP] = CLASS_MODE.CAMP,--阵营
	[COLLECTION_PAGE_TYPE.ATHLETICS] = CLASS_MODE.CONTEST,--竞技
	[COLLECTION_PAGE_TYPE.REST] = CLASS_MODE.RELAXATION,--休闲
}

local function CheckLevel(tInfo)
	if not tInfo then
		return
	end

	local hPlayer = g_pClientPlayer
	if not hPlayer then
		return
	end

	if hPlayer.nLevel >= tInfo.nMinLevel and hPlayer.nLevel <= tInfo.nMaxLevel then
		return true
	end

	return false
end

local function GetQuestState(nQuestID)
	local pPlayer = g_pClientPlayer
	local nCount = 0

	local fnFindNext
	fnFindNext = function(nID)
		if nCount > 100 then
			return
		end
		nCount = nCount + 1

		if not nID or nID <= 0 then
			return
		end
		local nQusetState = pPlayer.GetQuestPhase(nID)
		if nQusetState ~= QUEST_PHASE.FINISH then
			return nID, nQusetState
		else
			local nSubsequenceID = GetQuestInfo(nID).dwSubsequenceID
			local nNewID, nNewQusetState = fnFindNext(nSubsequenceID)
			if nNewID and nNewID > 0 then
				return nNewID, nNewQusetState
			else
				return nID, nQusetState
			end
		end
	end

	local tLine = Table_GetCalenderActivityQuest(nQuestID)
	if tLine and tLine.nNpcTemplateID ~= -1 then
		local _, nID = pPlayer.RandomByDailyQuest(nQuestID, tLine.nNpcTemplateID)

		LOG.INFO("--------CollectionData  RandomByDailyQuest nQuestID: %s  nNpcTemplateID: %s  nResID: %s--------",tostring(nQuestID),
		tostring(tLine.nNpcTemplateID), tostring(nID))

		local nFinishedCount, nTotalCount = pPlayer.GetRandomDailyQuestFinishedCount(tLine.nQuestGroupID)
		local nQusetState = pPlayer.GetQuestPhase(nID)
		if nFinishedCount == nTotalCount then
			nQusetState = QUEST_PHASE.FINISH
		end
		return nID, nQusetState
	else
		return fnFindNext(nQuestID)
	end
end

local function GetQuestFinishCount(tQuestID)
	local nCount = 0
	for _, v in ipairs(tQuestID) do
		local _, nQusetState = GetQuestState(tonumber(v))
		if nQusetState and nQusetState == QUEST_PHASE.FINISH then
			nCount = nCount + 1
		end
	end
	return nCount
end

--获取真正的任务ID
local function GetShowQuestID(tQuestID)
	local pPlayer = g_pClientPlayer
	local tNewQuestID = {}
	local nQuestNum = 0
	for _, v in ipairs(tQuestID) do
		local nQuestID = tonumber(v)
		local tLine = Table_GetCalenderActivityQuest(nQuestID)
		local nResult = pPlayer.CanAcceptQuest(nQuestID)
		if nResult == QUEST_RESULT.SUCCESS or
			nResult == QUEST_RESULT.ALREADY_ACCEPTED or
			nResult == QUEST_RESULT.ALREADY_FINISHED or
			nResult == QUEST_RESULT.FINISHED_MAX_COUNT or
			(tLine and tLine.bIgnoreCanAccept)
		then
			nQuestNum = nQuestNum + 1
		end

		local nQuestID, nQusetState = GetQuestState(nQuestID)
		if nQusetState == QUEST_PHASE.FINISH then
			-- if not tLine or tLine.bCompleteShow then
				table.insert(tNewQuestID, nQuestID)
			-- end
		elseif nQusetState == QUEST_PHASE.UNACCEPT then
			if (not tLine or tLine.bUnacceptedShow) and (tLine and tLine.bIgnoreCanAccept or pPlayer.CanAcceptQuest(nQuestID) == QUEST_RESULT.SUCCESS) then
				table.insert(tNewQuestID, nQuestID)
			end
		elseif nQusetState == QUEST_PHASE.ACCEPT or nQusetState == QUEST_PHASE.DONE then
			table.insert(tNewQuestID, nQuestID)
		end
	end
	return tNewQuestID, nQuestNum
end



function CollectionData.Init()
    self.tbDungeonCopyID = {}
    self.tbDungeonMapInfo = {}
    self.tbGameGuideInfo = Table_GetGameGuideInfo()
	self._registerEvent()
end

--1、左侧分类：日课、休闲等 2、nPageType:页面类的分类，一般为普通特殊（0/1） nID:卡片ID
function CollectionData.LinkToCardByID(nType, nPageType, nID)
	if not UIMgr.IsViewOpened(VIEW_ID.PanelRoadCollection) then
		UIMgr.Open(VIEW_ID.PanelRoadCollection, nType, nPageType, nID)
	else
		local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelRoadCollection)
		scriptView:LinkToCard(nType, nPageType, nID)
	end
end

function CollectionData.LinkToDailyCardByID(nID, bNotShowTip)
	local bOk = self.IsCardInQuestList(nID)
	if not bOk then
		if not bNotShowTip then TipsHelper.ShowNormalTip("该任务不在您的每日任务中") end
		return false
	end
	self.LinkToCardByID(COLLECTION_PAGE_TYPE.DAY, 0, nID)
	return true
end

function CollectionData.LinkToNormalCardByID(nID, bNotShowTip)
	local nType, nClass2  = self.GetCardInNormalList(nID)
	if not nType then
		if not bNotShowTip then TipsHelper.ShowNormalTip("该玩法不在活动时间内") end
		return false
	end
	self.LinkToCardByID(nType, nClass2, nID)
	return true
end

function CollectionData.LinkToCard(nID)
	if not self.LinkToDailyCardByID(nID, true) then
		self.LinkToNormalCardByID(nID, true)
	end
end

function CollectionData.ActivityCanShow(tInfo)
	if not tInfo then
		return
	end
	local bResult = false
	for _, v in pairs(tInfo.tActivity) do
		local dwActivityID = tonumber(v)
		if ActivityData.CheckActiveIsShowByID(dwActivityID) then
			bResult = true
			break
		end
	end
	if tInfo.szActivity == "" then
		bResult = true
	end

	--百战屏蔽
	if tInfo.dwID == 13 and not MonsterBookData.IsVisible() then
		bResult = false
	end
	return bResult
end

function CollectionData.GetInfoList(nClass1, nClass2)
    local tRes = {}
	if nClass1 == CLASS_MODE.FB and nClass2 == CLASS_TYPE.NORMAL then --大战
		local tQuestID  = self.GetQuestIDByActivityID(DAILY_FB_ACTIVITY_ID)
		local dwQuestID = tQuestID[1] or nDefaultQuestID
		local tInfo      = self.GetInfoByQuestID(dwQuestID)
		if tInfo then
			table.insert(tRes, tInfo)
		end
	end
	for _, v in pairs(self.tbGameGuideInfo) do
		if v.nClass1 == nClass1 and v.nClass2 == nClass2 then
			local bActivityShow = self.ActivityCanShow(v)
			if bActivityShow and CheckLevel(v) then
				table.insert(tRes, v)
			end
		end
	end

	for _, v in pairs(self.tbGameGuideInfo) do
		if v.nClass1 == nClass1 and v.nClass2 == nClass2 then
			local bAlwaysDisplay = v.bAlwaysDisplay
			local bActivityShow = self.ActivityCanShow(v)
			if bAlwaysDisplay and not bActivityShow and CheckLevel(v) then
				table.insert(tRes, v)
			end
		end
	end

	return tRes
end


function CollectionData.GetQuestIDByActivityID(dwActivityID)
	local tActivity = Table_GetCalenderActivity(dwActivityID)
	local tQuestID  = SplitString(tActivity.szQuestID, ";")
	if tonumber(tQuestID[1]) == -1 then
		return
	end
	tQuestID = GetShowQuestID(tQuestID)

	return tQuestID
end

function CollectionData.GetInfoByQuestID(dwQuestID)
	if not dwQuestID or dwQuestID == 0 then
		return
	end
	for _, v in pairs(self.tbGameGuideInfo) do
		if v.dwQuestID == dwQuestID then
			return v
		end
	end
end

--获取活动的完成状态
function CollectionData.GetQuestFinishStateByActivity(dwActivityID)
	local tActive            = Table_GetCalenderActivity(dwActivityID)
	local tQuestID           = SplitString(tActive.szQuestID, ";")
	local dwBuffID           = tActive.dwBuffID
	local nQuestFinishAmount = 0
	local nQuestTotalCount   = tActive.nTotalCount
	local bResult            = false
	local nCurCount          = 0
	local nTolCount          = 0
	if dwBuffID and dwBuffID ~= 0 then
		local buff = Player_GetBuff(dwBuffID)
		if buff then
			nQuestFinishAmount = buff.nStackNum
		end
		if nQuestFinishAmount > nQuestTotalCount then
			nQuestFinishAmount = nQuestTotalCount
		end
		bResult = nQuestFinishAmount == nQuestTotalCount and nQuestTotalCount ~= 0
		nCurCount = nQuestFinishAmount
		nTolCount = nQuestTotalCount
	elseif tonumber(tQuestID[1]) and tonumber(tQuestID[1]) ~= -1 then
		local tNewQuestID, nQuestNum = GetShowQuestID(tQuestID)

		nQuestFinishAmount = GetQuestFinishCount(tQuestID)
		bResult = nQuestFinishAmount == nQuestNum and nQuestNum ~= 0
		nCurCount = nQuestFinishAmount
		nTolCount = nQuestNum
	else
		local nCount, nTotalCount, nNowCount, nFinishCount = ActivityData.GetActiveFinishCount(tActive)
		if nCount and nTotalCount then
			if nCount >= nTotalCount then
				bResult = true
			end
		end
	end
	return bResult, nCurCount, nTolCount
end

function CollectionData.GetFBRefreshTime(dwMapID, bRaid)
	local tInfo = self.tbDungeonMapInfo[dwMapID]
	local szResetTime = ""
	if not tInfo then
		return szResetTime
	end

	local _, _, _, _, _, _, bCanReset = GetMapParams(dwMapID)
	if not bRaid then
		if tInfo.nRefreshTime then
			szResetTime = UIHelper.GetDeltaTimeText(tInfo.nRefreshTime)
		end

	else
		if self.tbDungeonCopyID[dwMapID] then
			szResetTime = UIHelper.GetDeltaTimeText(tInfo.nRefreshTime)
		else
			szResetTime = UIHelper.GetDeltaTimeText(tInfo.nRefreshTime)
		end
	end
	return szResetTime
end

function CollectionData.IsCardInQuestList(nID)
	local tbQuestID = CollectionDailyData.GetQuestList()
	for nIndex, tbQuestInfo in ipairs(tbQuestID) do
		if tbQuestInfo[1] == nID then
			return true
		end
	end
	return false
end

function CollectionData.GetCardInNormalList(nID)
	for nIndex, nType in pairs(COLLECTION_PAGE_TYPE) do
		if nType ~= COLLECTION_PAGE_TYPE.DAY then
			local nClass1 = PAGETYPE_TO_CLASS[nType]
			for key, nClass2 in pairs(CLASS_TYPE) do
				local tbInfoList = CollectionData.GetInfoList(nClass1, nClass2)
				for nIndex, tbInfo in ipairs(tbInfoList) do
					if tbInfo.dwID == nID then
						return nType, nClass2
					end
				end
			end
		end
	end
	return nil, nil
end

function CollectionData.GetActiveActivity(tInfo)
	if not tInfo or not tInfo.tActivity then
		return
	end
	local tActivityList = tInfo.tActivity
	for _, v in pairs(tActivityList) do
		local dwActivityID = tonumber(v)
		if dwActivityID and dwActivityID ~= 0 and ActivityData.CheckActiveIsShowByID(dwActivityID) then
			return dwActivityID
		end
	end
end


function CollectionData.GetFinishState(tInfo)
    local dwMapID    = tInfo.dwMapID
	local nClass1    = tInfo.nClass1
	local bResult    = false
	local dwPlayerID = UI_GetClientPlayerID()
	local nCurCount  = 0
	local nTolCount  = 0

	tInfo.bDungeonProgress = false
	if nClass1 == CLASS_MODE.FB and dwMapID ~= 0 then   --副本，判Boss进度
		local _, _, _, _, _, _, _, bDungeonRoleProgressMap = GetMapParams(dwMapID)
		if bDungeonRoleProgressMap then
			ApplyDungeonRoleProgress(dwMapID, dwPlayerID)
			tInfo.bDungeonProgress = true
		end
	else --有关联活动判活动
		local dwActivity = self.GetActiveActivity(tInfo)
		if dwActivity and dwActivity ~= 0 then
			bResult, nCurCount, nTolCount = self.GetQuestFinishStateByActivity(dwActivity)
		end
	end
	return bResult, nCurCount, nTolCount
end

function CollectionData.CheckFBProgress(dwMapID)
	local dwPlayerID    = UI_GetClientPlayerID()
	local tProgressList = GetCDProcessInfo(dwMapID)
	local nTotalCount   = #tProgressList
	local nCount        = 0
	for i = 1, #tProgressList do
		local bHasKilled = GetDungeonRoleProgress(dwMapID, dwPlayerID, tProgressList[i].ProgressID)
		if bHasKilled then
			nCount = nCount + 1
		end
	end
	LOG.INFO("====CheckFBProgress %s %s %s====", tostring(dwMapID), tostring(nTotalCount), tostring(nCount))
	return nTotalCount ~= 0 and nTotalCount == nCount
end

function CollectionData.IsDailyDungeon(dwMapID)
	if not dwMapID or dwMapID == 0 then
		return false
	end

	if not CollectionData.tbDungeonFlagMap then
		CollectionData.tbDungeonFlagMap = {}
		local DAILY_TEAM_FB  = 29   --大战活动ID
		local WEEKLY_TEAM_FB = 501  --五人本周常活动ID
		local WEEKLY_RAID_FB = 502  --十人本周常活动ID
		local tDailyQuest = DungeonData.GetQuestIDByActivityID(DAILY_TEAM_FB) or {}
		local tTeamQuest  = DungeonData.GetQuestIDByActivityID(WEEKLY_TEAM_FB) or {}
		local tRaidQuest  = DungeonData.GetQuestIDByActivityID(WEEKLY_RAID_FB) or {}

		local tDungeonMap = Table_GetVersionName2DungeonHeadList()
		if tDungeonMap then
			for _, tVersionInfo in pairs(tDungeonMap) do
				if tVersionInfo.tHeadInfoList then
					for _, tHeadInfo in ipairs(tVersionInfo.tHeadInfoList) do
						if tHeadInfo.tRecordList then
							for _, tRecord in ipairs(tHeadInfo.tRecordList) do
								local nFlag = 0
								if table.contain_value(tDailyQuest, tRecord.dwQuestID) then
									nFlag = 1
								elseif table.contain_value(tTeamQuest, tRecord.dwQuestID)
									or table.contain_value(tRaidQuest, tRecord.dwQuestID) then
									nFlag = 2
								end
								CollectionData.tbDungeonFlagMap[tRecord.dwMapID] = nFlag
							end
						end
					end
				end
			end
		end
	end

	return CollectionData.tbDungeonFlagMap[dwMapID] == 1
end


function CollectionData.UpdateDungeonInfo(szEvent, tData, tData1)
    if szEvent == "ON_APPLY_PLAYER_SAVED_COPY_RESPOND" then
		if not tData then
			self.tbDungeonCopyID = {}
			tData = {}
		end
		for dwMapID, v in pairs(tData) do
			self.tbDungeonCopyID[dwMapID] = v[1]
		end
	elseif szEvent == "MAP_ENTER_INFO_NOTIFY" then
		local tEnterMapInfo = tData or {}
		local tLeftRefTime = tData1 or {}
		for dwMapID, v in pairs(tEnterMapInfo) do
			local szMapName = Table_GetMapName(dwMapID)
			local _, nMapType, nMaxPlayerCount, nLimitedTimes = GetMapParams(dwMapID)
			local nType, tInfo = nil, nil
			if nMapType and nMapType == MAP_TYPE.DUNGEON then
				local nRefreshCycle = GetMapRefreshInfo(dwMapID)
				local nCanEnterTimes = nLimitedTimes - v
                local nRefreshTime = tLeftRefTime[dwMapID] or 0
				if nRefreshCycle == 0 and nMaxPlayerCount <= 5 then
                    self.tbDungeonMapInfo[dwMapID] =
					{
						nEnterTimes = nCanEnterTimes,
                        nLimitedTimes = nLimitedTimes,
                        nRefreshTime = nRefreshTime
					}
				elseif nRefreshCycle ~= 0 and nMaxPlayerCount <= 5 then
					local nRefreshTime = tLeftRefTime[dwMapID] or 0
					self.tbDungeonMapInfo[dwMapID] =
					{
                        nEnterTimes = nCanEnterTimes,
                        nLimitedTimes = nLimitedTimes,
						nRefreshCycle = nRefreshCycle,
                        nRefreshTime = nRefreshTime
					}

				elseif nRefreshCycle ~= 0 and nMaxPlayerCount > 5 then
					local nRefreshTime = tLeftRefTime[dwMapID] or 0
					self.tbDungeonMapInfo[dwMapID] =
					{
						nRefreshCycle = nRefreshCycle,
                        nRefreshTime = nRefreshTime
					}
				end
			end
		end
	end
end

function CollectionData.IsLocked(tInfo)
	if not tInfo then
		return
	end
	local hPlayer = g_pClientPlayer
	if not hPlayer then
		return
	end
	local bLock          = false
	local szDesc         = ""
	local nLockLevel     = tInfo.nLockLevel
	local szLockDesc     = UIHelper.GBKToUTF8(tInfo.szLockDesc)
	local szLockFunction = tInfo.szLockFunction
	local szTipDesc      = nil
	if hPlayer.nLevel < nLockLevel then
		bLock = true
		szDesc = FormatString(g_tStrings.STR_FULL_LEVEL_HELP_LOCK_TIP_5, nLockLevel)
		szTipDesc = FormatString(g_tStrings.STR_GAME_GUIDE_LOCK_LEVEL, nLockLevel)
	elseif szLockFunction ~= "" then
		bLock = not self.IsActivityUnlock(szLockFunction)
		if bLock then
			szDesc = szLockDesc
		end
	end
	return bLock, szDesc, szTipDesc
end

function CollectionData.IsActivityUnlock(szFuncName)
    if not szFuncName then
        return
    end
    local func = _G[szFuncName]
    if func and type(func) == "function" then
        return func()
    end
end

function CollectionData.GetGuideIsOpen(tInfo)
	if not tInfo or not tInfo.nClass1 then return false end

	local bNeedCheck = tInfo.nClass1 == 2 or tInfo.nClass1 == 3
	if not bNeedCheck then
		return true
	end

    if not tInfo.szActivity or tInfo.szActivity == "" then
        return false
    end
    for szID in string.gmatch(tInfo.szActivity, "[^;]+") do
        local nID = tonumber(szID)
        if nID and IsActivityOn(nID) then
            return true
        end
    end
    return false
end

function CollectionData.OnClickCard(tbCardInfo)
	local nLockLevel = tbCardInfo.nLockLevel or tbCardInfo.nLevel
    if nLockLevel and g_pClientPlayer.nLevel < nLockLevel then
        OutputMessage("MSG_ANNOUNCE_NORMAL", FormatString(g_tStrings.STR_GAME_GUIDE_LOCK_LEVEL, nLockLevel, UIHelper.GBKToUTF8(tbCardInfo.szName)))
        return
    end

	if tbCardInfo.bSimpleQuest then
		RemoteCallToServer("On_Daily_FinishCourse", tbCardInfo.dwID)
	end

    local szMobileFunction = tbCardInfo.szMobileFunction
    local dwActivityID = self.GetActiveActivity(tbCardInfo)
    if not string.is_nil(szMobileFunction) then
        CollectionFuncList.Excute(szMobileFunction)
    elseif tbCardInfo.dwMapID and tbCardInfo.dwMapID ~= 0 then
        --秘境
		UIMgr.Open(VIEW_ID.PanelDungeonEntrance, {dwTargetMapID = tbCardInfo.dwMapID})
    elseif tbCardInfo.nClass1 == CLASS_MODE.CAMP then
		if dwActivityID then
	        ActivityData.LinkToActiveByID(dwActivityID)
		else
        	OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_CALENDER_NO_LINK_COMMON)
		end
    end

end

function CollectionData.ApplyDesignation()
	local hPlayer = g_pClientPlayer
	if not hPlayer then
		return
	end
	local nTitle = hPlayer.nTitle
	local nCamp  = hPlayer.nCamp

	local dwID = GetDesignationIDByTitleAndCamp(nTitle, nCamp)
	if not dwID or dwID == 0 then
		OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_NO_DESIGNATION)
		return
	end

	hPlayer.SetCurrentDesignation(dwID, 0, false)
end

--2、秘境 3、竞技 4、阵营
function CollectionData.OpenCollection(nType)
	if nType == COLLECTION_PAGE_TYPE.CAMP and g_pClientPlayer.nCamp == CAMP.NEUTRAL then
		UIMgr.Open(VIEW_ID.PanelPvPCampJoin)
	else
		UIMgr.Open(VIEW_ID.PanelRoadCollection, nType)
	end
end

function CollectionData.GetLevelInfo()
	local nTotalCollectPoints = self.GetTotalCollectPoints()
	local nCPLevel, nPointsInLevel, nDestPointsInLevel = self.GetLevelValuesByTotalCollectPoints(nTotalCollectPoints)
	local tLevelInfo = Table_GetFurnitureSetCollectPointsLevelInfo(nCPLevel)
	return tLevelInfo
end

function CollectionData.GetCollectScore()
	local nScore = g_pClientPlayer.GetHomelandRecord()
	if nScore > MAX_SHOW_NUM then
		nScore = math.floor(nScore / MAX_SHOW_NUM * 100) / 100
	end
	return nScore
end

function CollectionData.GetAddCollectScore()
    local tbHomelandOverviewInfo = GDAPI_GetHomelandOverviewInfo()
    local nAddCollectScore = tbHomelandOverviewInfo and tbHomelandOverviewInfo.nSensonRecord or 0--新增赛季分
	if nAddCollectScore > MAX_SHOW_NUM then
		nAddCollectScore = math.floor(nAddCollectScore / MAX_SHOW_NUM * 100) / 100
	end
	return nAddCollectScore
end

function CollectionData.GetJustice()
	local nJustice = 0
	local nRemain  = 0
	local hPlayer  = g_pClientPlayer
	if hPlayer then
		nJustice = hPlayer.nJustice
		nRemain  = hPlayer.GetJusticeRemainSpace()
	end
	return nJustice, nRemain
end

function CollectionData.GetPrestige()
	local nPrestige = 0
	local nRemain   = 0
	local hPlayer   = g_pClientPlayer
	if hPlayer then
		nPrestige = hPlayer.nCurrentPrestige
		nRemain   = hPlayer.GetPrestigeRemainSpace()
	end
	return nPrestige, nRemain
end


function CollectionData.GetCPLevelName()
	local szName    = ""
	local nCPPoints = self.GetTotalCollectPoints()
	local nCPLevel  = self.GetCPLevelValues(nCPPoints)
	local tInfo     = Table_GetFurnitureSetCollectPointsLevelInfo(nCPLevel)
	if tInfo then
		szName = tInfo._Comment
	end
	return szName
end

function CollectionData.GetTotalCollectPoints()
	return GetClientPlayer().GetRemoteDWordArray(1076, 0)
end

function CollectionData.GetCPLevelValues(nTotalCollectPoints)
	local nCollectPointsLevel, nPointsInLevel, nDestPointsInLevel
	local nInitialPointsInLevel = 0
	local tUiTable = Table_GetAllFurnitureSetCollectPointsLevelInfo()
	local nRowCount = tUiTable:GetRowCount()
	for i = 2, nRowCount do
		local tLine = tUiTable:GetRow(i)
		local nDestPtsToNextLevel = tLine.nDestPtsToNextLevel
		if nDestPtsToNextLevel > nTotalCollectPoints then
			nCollectPointsLevel = tLine.nLevel
			nPointsInLevel = nTotalCollectPoints - nInitialPointsInLevel
			nDestPointsInLevel = nDestPtsToNextLevel - nInitialPointsInLevel
			break
		else
			nInitialPointsInLevel = nDestPtsToNextLevel
		end
	end

	-- 总分爆表的特殊情况处理
	if not nCollectPointsLevel then
		local tLastLine = tUiTable:GetRow(nRowCount)
		nCollectPointsLevel = tLastLine.nLevel
		nDestPointsInLevel = tLastLine.nDestPtsToNextLevel - tUiTable:GetRow(nRowCount - 1).nDestPtsToNextLevel
		nPointsInLevel = nDestPointsInLevel
	end

	return nCollectPointsLevel, nPointsInLevel, nDestPointsInLevel
end


function CollectionData.GetAllCollectPointsLevelAwardInfos()
	local tUiTable = Table_GetAllFurnitureSetCollectPointsLevelInfo()
	local nRowCount = tUiTable:GetRowCount()
	local nStartLevel = 2 -- 从第2级开始才有奖励
	local aAllRewardInfos = {}
	local nDestPoints = 0
	for i = nStartLevel, nRowCount do
		local tLine = tUiTable:GetRow(i)

		if i > nStartLevel then
			if tLine.dwRewardItemIndex > 0 then
				table.insert(aAllRewardInfos,
						{nPoints=nDestPoints, szName=tLine.szRewardName, nItemType=tLine.nRewardItemType,
						 dwItemIndex=tLine.dwRewardItemIndex, szIconPath=tLine.szRewardIconPath, nIconFrame=tLine.nRewardIconFrame, nNextPoints=tLine.nDestPtsToNextLevel})
			else
				break
			end
		else
			-- Do nothing
		end

		nDestPoints = tLine.nDestPtsToNextLevel
	end
	return aAllRewardInfos
end

function CollectionData.GetLevelValuesByTotalCollectPoints(nTotalCollectPoints)
	local nCollectPointsLevel, nPointsInLevel, nDestPointsInLevel
	local nInitialPointsInLevel = 0
	local tUiTable = Table_GetAllFurnitureSetCollectPointsLevelInfo()
	local nRowCount = tUiTable:GetRowCount()
	for i = 2, nRowCount do
		local tLine = tUiTable:GetRow(i)
		local nDestPtsToNextLevel = tLine.nDestPtsToNextLevel
		if nDestPtsToNextLevel > nTotalCollectPoints then
			nCollectPointsLevel = tLine.nLevel
			nPointsInLevel = nTotalCollectPoints - nInitialPointsInLevel
			nDestPointsInLevel = nDestPtsToNextLevel - nInitialPointsInLevel
			break
		else
			nInitialPointsInLevel = nDestPtsToNextLevel
		end
	end

	-- 总分爆表的特殊情况处理
	if not nCollectPointsLevel then
		local tLastLine = tUiTable:GetRow(nRowCount)
		nCollectPointsLevel = tLastLine.nLevel
		nDestPointsInLevel = tLastLine.nDestPtsToNextLevel - tUiTable:GetRow(nRowCount - 1).nDestPtsToNextLevel
		nPointsInLevel = nDestPointsInLevel
	end

	return nCollectPointsLevel, nPointsInLevel, nDestPointsInLevel
end


function CollectionData.UnInit()

end

function CollectionData.OnLogin()

end

function CollectionData.OnFirstLoadEnd()

end

function CollectionData.GetItemRewardList(tbInfo)
	local szReward = tbInfo.szReward
	local tbRes = {}
	if not szReward or szReward == "" then
		return tbRes
	end

	local tbReward = string.split(szReward, ";")
	local nNum = #tbReward
	for nIndex = 1, nNum do
		if tbReward[nIndex] ~= "" then
			local tRewardInfo = string.split(tbReward[nIndex], "_")
			table.insert(tbRes, tRewardInfo)
		end
	end
	return tbRes
end

--上次打开页面类型
function CollectionData.SetLastOpenType(nLastOpenType)
	self.nLastOpenType = nLastOpenType
end

function CollectionData.SetLastPageType(nLastPageType)
	self.nLastPageType = nLastPageType
end


function CollectionData._registerEvent()
	Event.Reg(self, EventType.OnLookUpPersonalCard, function(szGlobalID)
		if szGlobalID and g_pClientPlayer.GetGlobalID() ~= szGlobalID then
			RemoteCallToServer("On_Daily_FinishCourse", 2)
		end
	end)

	Event.Reg(self, "PLAYER_FELLOWSHIP_CHANGE", function(nRespondCode, dwPlayerID, dwValue1, dwValue2, szName)
        -- if nRespondCode == PLAYER_FELLOWSHIP_RESPOND.SUCCESS_ADD then
            -- RemoteCallToServer("On_Daily_FinishCourse", 1) -- 该ID给设计站了
        -- end
    end)

	Event.Reg(self, EventType.OnRoleLogin, function()
		self.SetLastOpenType(nil)
		self.SetLastPageType(nil)
	end)
end


-----------------------------赛季段位-----------------------------
local SEASON_LEVEL_CLASS = {
	[1] = {saName = g_tStrings.STR_RANK_TITLE_NAMA[7]},	--休闲
	[2] = {saName = g_tStrings.STR_RANK_TITLE_NAMA[6]},	--家园
	[3] = {saName = g_tStrings.STR_RANK_TITLE_NAMA[1]},	--秘境
	[4] = {saName = g_tStrings.STR_RANK_TITLE_NAMA[3]},	--jjc
	[5] = {saName = g_tStrings.STR_RANK_TITLE_NAMA[5]},	--绝境战场
	[6] = {saName = g_tStrings.STR_RANK_TITLE_NAMA[4]},	--战场
	[7] = {saName = g_tStrings.STR_RANK_TITLE_NAMA[2]},	--阵营
}

function CollectionData.GetLevelRewardListByLevel(nLevel)
	if not nLevel then
		return
	end
	local tInfo = GDAPI_SA_GetRewardTable()
	return tInfo[nLevel]
end

local tClassOrder = {
    [1] = 1,
    [6] = 2,
    [3] = 3,
    [2] = 4,
    [4] = 5,
    [7] = 6,
    [5] = 7,
}

function CollectionData.GetRankInfo()
    local tRankInfo = GDAPI_SA_GetAllRankBaseInfo()
    if not tRankInfo then
        LOG.INFO("function GDAPI_SA_GetAllRankBaseInfo not Get Info")
        return
    end

    for nClass, tRank in ipairs(tRankInfo) do
        tRank.nClass = nClass
    end
    table.sort(tRankInfo, function(a, b)
        if a.nRankLv ~= b.nRankLv then
            return a.nRankLv > b.nRankLv
        end
        local nOrderA = tClassOrder[a.nClass] or 99
        local nOrderB = tClassOrder[b.nClass] or 99
        return nOrderA < nOrderB
    end)
    local nCount = #tRankInfo
    local tRankList = {}
    for i = 1, nCount do
        tRankList[i] = tRankInfo[i]
    end
    return tRankList
end


function CollectionData.GetSeasonLevelTaskListByClass(nClass)
	local tbList = Table_GetSeasonLevelActiveTaskConfig(nClass)
	return tbList
end

-------------------------荣誉挑战------------------------------
local VIEW_SLOT_COUNT = 3
local HORSE_IMG = {
	[1] = "ChallengeXiuXian",
	[2] = "ChallengeMiJing",
	[3] = "ChallengePvp",
}
local function NormalizeMountInfo(tMount, nClass, nSlot)
    if type(tMount) ~= "table" then
        return nil
    end

    local dwTabType = tMount.dwTabType or tMount[1]
    local dwIndex = tMount.dwIndex or tMount[2]
    local nCost = tMount.nCost or tMount[3] or tMount.nCount

    if not dwTabType or not dwIndex then
        return nil
    end

    return {
        dwTabType = dwTabType,
        dwIndex = dwIndex,
        nCost = nCost,
    }
end

function CollectionData.GetMountState(nClass, nSlot, tRewardLv, nFragment, tMountList)
	local tState = GDAPI_SH_GetMountExchangeState(nClass)
	if not tState then
		return
	end
	local nState = tState and tState[nSlot]
    local tMount = tMountList and tMountList[nSlot]
    local nCost = tMount and tMount.nCost
    return {
        bReceived = nState == 2,
        bUnlocked = nState == 0 or nState == 3 or nState == 4,
        bCanExchange = nState == 1,
        nCost = nCost,
    }
end

function CollectionData.GetMountList(nClass)
    local tRawList = GDAPI_SH_GetMountRewardsByClass(nClass) or {}
    local tResult = {}
    for i = 1, VIEW_SLOT_COUNT do
        tResult[i] = NormalizeMountInfo(tRawList[i], nClass, i)
    end
    return tResult
end

function CollectionData.ChallengeHasCanGet(nClass, szCatgName)
	local tConfigList = Table_GetSeasonHonorTaskConfig(nClass) or {}
    local bFilterCategory = szCatgName and szCatgName ~= ""

    for _, tTask in ipairs(tConfigList) do
        if tTask.bShow and ((not bFilterCategory) or UIHelper.GBKToUTF8(tTask.szCatgName) == szCatgName) then
            local nTaskClass = tTask.nClass or nClass
            local nStatus = GDAPI_SH_GetAllTaskRewardInfo(nTaskClass, tTask.szTaskKey)
            if nStatus == 1 then
                return true
            end
        end
    end

    return false
end

function CollectionData.ChallengeHasCanGetReward(nClass)
	if not nClass then return false end

    local nScore, tRewardLv = GDAPI_SH_GetBaseInfo(nClass)
    local tRewardList = Table_GetSeasonHonorRewardConfig(nClass) or {}
    local tCanGet = GDAPI_SH_GetLevelRewardState(nClass) or {}

    for i, tRewardCfg in ipairs(tRewardList) do
        local nStage = tRewardCfg and tRewardCfg.nStage or 0
        if nStage > 0 then
            local bReceived = tRewardLv and tRewardLv[nStage] == 1 or false
            local bConditionMet = (not bReceived) and ((nScore or 0) >= (tRewardCfg.nScore or 0))
            local bCanGet = bConditionMet and tCanGet[i] == 1

            if bCanGet then
                return true
            end
        end
    end

    return false
end

function CollectionData.AllTaskHasCanGet()
    for i = 1, VIEW_SLOT_COUNT do
        if self.ChallengeHasCanGet(i) then
            return true
        end
    end

    return false
end

function CollectionData.AllChallengeRewardHasCanGet()
	for i = 1, VIEW_SLOT_COUNT do
        if self.ChallengeHasCanGetReward(i) then
            return true
        end
    end

    return false
end

function CollectionData.SeasonLevelHasCanGet(nClass)
	local tRankInfo = GDAPI_SA_GetAllRankBaseInfo()
    if not tRankInfo then 
        return false 
    end

	local tClassInfo = tRankInfo[nClass]
	if tClassInfo and tClassInfo.tList then
        for nRankLv, nState in pairs(tClassInfo.tList) do
            if nState == 1 then
                return true
            end
        end
    end

	return false
end

function CollectionData.AllSeasonLevelHasCanGet()	--赛季段位有无奖励
    local tRankInfo = GDAPI_SA_GetAllRankBaseInfo()
    if not tRankInfo then 
        return false 
    end
    
    for nClass, tClassInfo in pairs(tRankInfo) do
        if tClassInfo.tList then
            for nRankLv, nState in pairs(tClassInfo.tList) do
                if nState == 1 then
                    return true
                end
            end
        end
    end
    
    return false
end

function CollectionData.HasCanGetHorse(nClass)
    if not nClass then
        return false, nil
    end

    local nFragment = GDAPI_SH_GetMountFragmentCount(nClass)
    local _, tRewardLv = GDAPI_SH_GetBaseInfo(nClass)
    local tMountList = CollectionData.GetMountList(nClass)
    
    if not tMountList then
        return false, nil
    end

    for nSlot = 1, VIEW_SLOT_COUNT do
        local tMount = tMountList[nSlot]
        if tMount then
            local tState = CollectionData.GetMountState(nClass, nSlot, tRewardLv, nFragment, tMountList)
            if tState and tState.bCanExchange then
                return true, nSlot
            end
        end
    end

    return false, nil
end

function CollectionData.CheckChallengeHorseRedDot(nClass)
    if not nClass then return false end
    local bCanGet, nSlot = CollectionData.HasCanGetHorse(nClass)
    if bCanGet then
        return (Storage.ChallengeHorseSlot[nClass] or 0) ~= nSlot
    end
    return false
end


function CollectionData.CheckAllChallengeHorseRedDot()
	for nSlot = 1, VIEW_SLOT_COUNT do
		if CollectionData.CheckChallengeHorseRedDot(nSlot) then
			return true
		end
	end
	return false
end