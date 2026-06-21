-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: DataName
-- Date: 2023-12-15 15:53:09
-- Desc: ?
-- ---------------------------------------------------------------------------------

WulintongjianDate = WulintongjianDate or {}
local self = WulintongjianDate
-------------------------------- 消息定义 --------------------------------
WulintongjianDate.Event = {}
WulintongjianDate.Event.XXX = "WulintongjianDate.Msg.XXX"

WulintongjianDate.tTempQuestStageInfo = {}
WulintongjianDate.tDLCRedPointFlag = {}

function WulintongjianDate.Init()
    WulintongjianDate.tDLCList = Table_GetDLCList()
    WulintongjianDate.nCurrentDLCID = 0
    WulintongjianDate.nCurrentSelectedDLCID = 1
    WulintongjianDate.szDLCName = ""
    WulintongjianDate.tRewardInfo = {}
    WulintongjianDate.tSortDLCMap = {}
	WulintongjianDate.tDLCScore = {}
	WulintongjianDate.tDLCImage = {}
	WulintongjianDate.nDLCCount = #WulintongjianDate.tDLCList or 0
	WulintongjianDate.tDLCRedPoint = {}

	Event.Reg(self, EventType.OnRoleLogin, function()
		WulintongjianDate.bFirstOpenWuLingTongJianView = false
		WulintongjianDate.nLastRedpointCount = 0
		WulintongjianDate.nCurRedpointCount = 0
    end)
end

function WulintongjianDate.UnInit()

end

function WulintongjianDate.OnLogin()

end

function WulintongjianDate.OnFirstLoadEnd()

end

function WulintongjianDate.SetCurDLCID(nCurrentDLCID)
    WulintongjianDate.nCurrentSelectedDLCID = nCurrentDLCID
end

function WulintongjianDate.GetDLCList()
    return WulintongjianDate.tDLCList
end

function WulintongjianDate.GetDLCName()
    return WulintongjianDate.szDLCName
end

function WulintongjianDate.GetDLCRewardInfo()
    return WulintongjianDate.tRewardInfo
end

function WulintongjianDate.GetFirstOpenWuLingTongJianView()
    return WulintongjianDate.bFirstOpenWuLingTongJianView == false
end

-- function WulintongjianDate.GetDLCList()
--     return WulintongjianDate.tDLCList
-- end

function WulintongjianDate.UpdateDLCInfo(nDLCID, bDate)
    WulintongjianDate.nCurrentDLCID = nDLCID
    local tLine = Table_GetDLCInfo(nDLCID)
	if tLine then
		WulintongjianDate.szDLCName = tLine.szDLCName
		WulintongjianDate.tDLCRedPoint[nDLCID] = {}
		WulintongjianDate.tDLCImage[nDLCID] = {}
		WulintongjianDate.tDLCImage[nDLCID].szMobileNameImage = tLine.szMobileNameImage
		WulintongjianDate.tDLCImage[nDLCID].szMobileNameImageBlack = tLine.szMobileNameImageBlack
		WulintongjianDate.GetDLCMapInfo(nDLCID, tLine.szDLCMapID, bDate)
		WulintongjianDate.tRewardInfo =
		{
			{
				nRewardQuestID = tLine.nRewardQuestID1,
				nRewardScore = tLine.nRewardScore1,
				nAwardState = WulintongjianDate.GetAwardState(tLine.nRewardQuestID1),
				szRewardName = UIHelper.GBKToUTF8(tLine.szRewardName1),
				szRewardImage = UIHelper.GBKToUTF8(tLine.szRewardImage1),
			},
			{
				nRewardQuestID = tLine.nRewardQuestID2,
				nRewardScore = tLine.nRewardScore2,
				nAwardState = WulintongjianDate.GetAwardState(tLine.nRewardQuestID2),
				szRewardName = UIHelper.GBKToUTF8(tLine.szRewardName2),
				szRewardImage = UIHelper.GBKToUTF8(tLine.szRewardImage2),
			},
			{
				nRewardQuestID = tLine.nRewardQuestID3,
				nRewardScore = tLine.nRewardScore3,
				nAwardState = WulintongjianDate.GetAwardState(tLine.nRewardQuestID3),
				szRewardName = UIHelper.GBKToUTF8(tLine.szRewardName3),
				szRewardImage = UIHelper.GBKToUTF8(tLine.szRewardImage3),
				dwAvatarID = tLine.dwAvatarID,
			},
			{
				nRewardQuestID = tLine.nRewardQuestID4,
				nRewardScore = tLine.nRewardScore4,
				nAwardState = WulintongjianDate.GetAwardState(tLine.nRewardQuestID4),
				szRewardName = UIHelper.GBKToUTF8(tLine.szRewardName4),
				szRewardImage = UIHelper.GBKToUTF8(tLine.szRewardImage4),
			},
		}
		return true
	end
	return false
end

function WulintongjianDate.GetDLCScore()
	WulintongjianDate.tDLCScore = {}
	WulintongjianDate.tDLCRedPoint = {}

	for nDLCID = 1, WulintongjianDate.nDLCCount  do
        if WulintongjianDate.UpdateDLCInfo(nDLCID) then
			local nFinishNum, nTotal = 0, 0
			for _, tMapInfo in pairs(WulintongjianDate.tDLCMapInfoDate) do
				local nMapFinishNum, nMapTotal = WulintongjianDate.GetMapAchievementFinishAndTotal(tMapInfo)
				nFinishNum, nTotal = nFinishNum + nMapFinishNum, nTotal + nMapTotal
			end

            WulintongjianDate.tDLCScore[nDLCID] = {["nFinishNum"] = nFinishNum, ["nTotal"] = nTotal}
		end
    end

	WulintongjianDate.tDLCScore[self.nDLCCount] = {["nFinishNum"] = 0, ["nTotal"] = 0}
end

function WulintongjianDate.GetDLCMapInfo(nDLCID, szDLCMapID, bDate)
    WulintongjianDate.tSortDLCMapData = SplitString(szDLCMapID, ";")
	WulintongjianDate.tDLCMapInfoDate = {}

	for _, szMapID in ipairs(WulintongjianDate.tSortDLCMapData) do
		WulintongjianDate.tDLCMapInfoDate[tonumber(szMapID)] = Table_GetDLCMainPanelMapInfo(WulintongjianDate.nCurrentDLCID, tonumber(szMapID))
		WulintongjianDate.tDLCRedPoint[nDLCID][tonumber(szMapID)] = {}
		WulintongjianDate.UpdateMapInfo(tonumber(szMapID))
	end
	if not bDate then
		WulintongjianDate.tSortDLCMap = WulintongjianDate.tSortDLCMapData
		WulintongjianDate.tDLCMapInfo = WulintongjianDate.tDLCMapInfoDate
	end

	WulintongjianDate.UpdateRecommendMapList()
end

function WulintongjianDate.GetAwardState(nQuestID)
    if not nQuestID or not g_pClientPlayer then
        return
    end
    return g_pClientPlayer.GetQuestPhase(nQuestID)
end

function WulintongjianDate.UpdateMapInfo(nMapID)
    local tDLCMapInfo = WulintongjianDate.tDLCMapInfoDate[nMapID]
	if not g_pClientPlayer or not tDLCMapInfo then
		return
	end

    local tInfo = {}
	tInfo.nNum, tInfo.nFinishNum = 0, 0
	if tDLCMapInfo.nQuestAchiID ~= 0 then
		tInfo.nNum = Table_GetAchievementInfo(tDLCMapInfo.nQuestAchiID) or 0
		tInfo.nFinishNum = g_pClientPlayer.GetAchievementCount(tDLCMapInfo.nQuestAchiID) or 0
	end
	tDLCMapInfo.tQuestInfo = tInfo

	tInfo = {}
	tInfo.nFinishNum, tInfo.nNum = WulintongjianDate.GetAchievementFinishNum(tDLCMapInfo.szDungeonAchiID)
	tDLCMapInfo.tDungeonInfo = tInfo

	tInfo = {}
	tInfo.nFinishNum, tInfo.nNum, tInfo.tResult = WulintongjianDate.GetAchievementFinishNum(tDLCMapInfo.szReputationAchiID)
	tDLCMapInfo.tReputationInfo = tInfo

	tInfo = {}
	tInfo.nFinishNum, tInfo.nNum = WulintongjianDate.GetAchievementFinishNum(tDLCMapInfo.szOtherAchiID)
	tDLCMapInfo.tOtherInfo = tInfo

	tDLCMapInfo.tQuestInfo.tStageRewardInfo = WulintongjianDate.GetStageRewardInfo(tDLCMapInfo.szQuestStageNum, tDLCMapInfo.szQuestStageQuestID, tDLCMapInfo.szQuestStageIcon)
	tDLCMapInfo.tDungeonInfo.tStageRewardInfo = WulintongjianDate.GetStageRewardInfo(tDLCMapInfo.szDungeonStageNum, tDLCMapInfo.szDungeonStageQuestID, tDLCMapInfo.szDungeonStageIcon)
	tDLCMapInfo.tOtherInfo.tStageRewardInfo = WulintongjianDate.GetStageRewardInfo(tDLCMapInfo.szOtherStageNum, tDLCMapInfo.szOtherStageQuestID, tDLCMapInfo.szOtherStageIcon)

	tDLCMapInfo.tReputationInfo.tStageRewardInfo = {}
    local tSplitResult, tIcon = SplitString(tDLCMapInfo.szReputationIcon, ";"), {}
	for i, szIcon in ipairs(tSplitResult) do
		tIcon[i] = tonumber(szIcon)
	end
	tSplitResult = SplitString(tDLCMapInfo.szReputationID, ";")
    local tReputationID,tName = {},{}
	for i, szReputationID in ipairs(tSplitResult) do
		tReputationID[i] = tonumber(szReputationID)
		local tServantInfo, bSuccess = RepuData.GetServantInfoByForceID(tReputationID[i])
		if bSuccess then
			tName[i] = tServantInfo.szNpcName
		else
			tName[i] = ""
		end
	end

	tDLCMapInfo.tReputationInfo.tStageRewardInfo.nSize = #tIcon
	tDLCMapInfo.tReputationInfo.tStageRewardInfo.tStageIcon = tIcon
	tDLCMapInfo.tReputationInfo.tStageRewardInfo.tReputationID = tReputationID
	tDLCMapInfo.tReputationInfo.tStageRewardInfo.tStageName = tName

    for i = 1, tDLCMapInfo.tQuestInfo.tStageRewardInfo.nSize,1 do
        local nQuestState = WulintongjianDate.GetAwardState(tDLCMapInfo.tQuestInfo.tStageRewardInfo.tStageQuestID[i])
        if nQuestState ~= QUEST_PHASE.FINISH and tDLCMapInfo.tQuestInfo.nFinishNum >= tDLCMapInfo.tQuestInfo.tStageRewardInfo.tStageNum[i] then
            WulintongjianDate.tDLCRedPoint[WulintongjianDate.nCurrentDLCID][nMapID] = true
			break
        end
    end

    for i = 1, tDLCMapInfo.tDungeonInfo.tStageRewardInfo.nSize,1 do
        local nQuestState = WulintongjianDate.GetAwardState(tDLCMapInfo.tDungeonInfo.tStageRewardInfo.tStageQuestID[i])
        if nQuestState ~= QUEST_PHASE.FINISH and tDLCMapInfo.tDungeonInfo.nFinishNum >= tDLCMapInfo.tDungeonInfo.tStageRewardInfo.tStageNum[i] then
            WulintongjianDate.tDLCRedPoint[WulintongjianDate.nCurrentDLCID][nMapID] = true
			break
        end
    end

    for i = 1, tDLCMapInfo.tOtherInfo.tStageRewardInfo.nSize,1 do
        local nQuestState = WulintongjianDate.GetAwardState(tDLCMapInfo.tOtherInfo.tStageRewardInfo.tStageQuestID[i])
        if nQuestState ~= QUEST_PHASE.FINISH and tDLCMapInfo.tOtherInfo.nFinishNum >= tDLCMapInfo.tOtherInfo.tStageRewardInfo.tStageNum[i] then
            WulintongjianDate.tDLCRedPoint[WulintongjianDate.nCurrentDLCID][nMapID] = true
			break
        end
    end
end

function WulintongjianDate.GetAchievementFinishNum(szAchiIDList)
    local tAchiID = SplitString(szAchiIDList, ";")
	local nTotalNum = #tAchiID
	local nFinishNum = 0
	local tAchiResult = {}
	for i, szAchiID in ipairs(tAchiID) do
		if g_pClientPlayer.IsAchievementAcquired(tonumber(szAchiID)) then
			nFinishNum = nFinishNum + 1
			tAchiResult[i] = true
		else
			tAchiResult[i] = false
		end
	end
	return nFinishNum, nTotalNum, tAchiResult
end

function WulintongjianDate.GetStageRewardInfo(szStageNum, szStageQuestID, szStageIcon)
    local tNum, tQuestID, tIcon = {}, {}, {}
	local tSplitResult = SplitString(szStageNum, ";")
	for i, szNum in ipairs(tSplitResult) do
		tNum[i] = tonumber(szNum)
	end
	tSplitResult = SplitString(szStageQuestID, ";")
	for i, szQuestID in ipairs(tSplitResult) do
		tQuestID[i] = tonumber(szQuestID)
	end
	tSplitResult = SplitString(szStageIcon, ";")
	for i, szIcon in ipairs(tSplitResult) do
		tIcon[i] = tonumber(szIcon)
	end
	return {nSize = #tSplitResult, tStageNum = tNum, tStageQuestID = tQuestID, tStageIcon = tIcon}
end

function WulintongjianDate.UpdateRecommendMapList()
    local nFirstMap
	for nMapID, tMapInfo in pairs(WulintongjianDate.tDLCMapInfo) do
		if tMapInfo.nLastRecomMap ~= 0 then
			if tMapInfo.nLastRecomMap == -1 then
				nFirstMap = nMapID
			else
				WulintongjianDate.tDLCMapInfo[tMapInfo.nLastRecomMap].nNextRecomMap = nMapID
			end
		end
	end

	while nFirstMap do
		WulintongjianDate.nCurrentRecomMap = nFirstMap
		if WulintongjianDate.tDLCMapInfo[nFirstMap].tQuestInfo.nNum == WulintongjianDate.tDLCMapInfo[nFirstMap].tQuestInfo.nFinishNum then
			nFirstMap = WulintongjianDate.tDLCMapInfo[nFirstMap].nNextRecomMap
			if nFirstMap == nil then
				WulintongjianDate.nCurrentRecomMap = nil
			end
		else
			nFirstMap = nil
		end
	end
end

function WulintongjianDate.GetMapAchievementFinishAndTotal(tMapInfo)
	local nFinishNum, nTotal = 0, 0
	nFinishNum = nFinishNum + tMapInfo.tQuestInfo.nFinishNum
	nTotal = nTotal + tMapInfo.tQuestInfo.nNum
	nFinishNum = nFinishNum + tMapInfo.tDungeonInfo.nFinishNum
	nTotal = nTotal + tMapInfo.tDungeonInfo.nNum
	nFinishNum = nFinishNum + tMapInfo.tReputationInfo.nFinishNum
	nTotal = nTotal + tMapInfo.tReputationInfo.nNum
	nFinishNum = nFinishNum + tMapInfo.tOtherInfo.nFinishNum
	nTotal = nTotal + tMapInfo.tOtherInfo.nNum
	return nFinishNum, nTotal
end

--dlc整体还有多少奖励没领
function WulintongjianDate.GetDLCRewardRedPoint()
	local nCount = 0
	local tList = WulintongjianDate.GetDLCList()
	for i = 1, #tList do
		if WulintongjianDate.UpdateDLCInfo(i, true) then
			local nFinishNum, nTotal = 0, 0
			for _, tMapInfo in pairs(WulintongjianDate.tDLCMapInfo) do
				local nMapFinishNum, nMapTotal = WulintongjianDate.GetMapAchievementFinishAndTotal(tMapInfo)
				nFinishNum, nTotal = nFinishNum + nMapFinishNum, nTotal + nMapTotal
			end
			for _, tReward in ipairs(WulintongjianDate.tRewardInfo) do
				if nFinishNum < tReward.nRewardScore then
					break
				end
				if tReward.nAwardState ~= QUEST_PHASE.FINISH then
					WulintongjianDate.tDLCRedPointFlag[i] = true
					nCount = nCount + 1
				end
			end
		end
	end

    for nDLCID = 1, WulintongjianDate.nDLCCount - 1 do
        local bRotPoint = table.contain_value(WulintongjianDate.tDLCRedPoint[nDLCID], true)
		if bRotPoint then
			nCount = nCount + 1
		end
    end

	if WulintongjianDate.bFirstOpenWuLingTongJianView then
		WulintongjianDate.nLastRedpointCount = WulintongjianDate.nCurRedpointCount
		WulintongjianDate.nCurRedpointCount = nCount
		if WulintongjianDate.nCurRedpointCount > WulintongjianDate.nLastRedpointCount then
			WulintongjianDate.bFirstOpenWuLingTongJianView = false
		end
	else
		WulintongjianDate.nLastRedpointCount = 0
		WulintongjianDate.nCurRedpointCount = nCount
	end

	return WulintongjianDate.nCurRedpointCount > WulintongjianDate.nLastRedpointCount
end

--获取是否有阶段性的奖励可领取，只判任务的，其他无视
local tTempQuestStageInfo = {}
function WulintongjianDate.CanGetQuestReward(nMapID)
	local pPlayer = GetClientPlayer()
	if not pPlayer then
		return
	end

	local tQuestStageInfos
	if tTempQuestStageInfo[nMapID] then
		tQuestStageInfos = tTempQuestStageInfo[nMapID]
	else
		tQuestStageInfos = {}
		local tList = WulintongjianDate.GetDLCList()
		for i = 1, #tList - 1 do
			local tMapInfo = Table_GetDLCMainPanelMapInfo(i, nMapID)
			if tMapInfo then
				local tQuestStageInfo = WulintongjianDate.GetStageRewardInfo(tMapInfo.szQuestStageNum, tMapInfo.szQuestStageQuestID, tMapInfo.szQuestStageIcon)
				tQuestStageInfo.nQuestAchiID = tMapInfo.nQuestAchiID
				tQuestStageInfo.nDLCID = i
				table.insert(tQuestStageInfos, tQuestStageInfo)
			end
		end
		tTempQuestStageInfo[nMapID] = tQuestStageInfos
	end

	if not tQuestStageInfos or #tQuestStageInfos <= 0 then
		return false
	end

	for _, tQuestStageInfo in ipairs(tQuestStageInfos) do
		local nFinishNum = pPlayer.GetAchievementCount(tQuestStageInfo.nQuestAchiID)
		for i = 1, tQuestStageInfo.nSize do
			local nQuestState = WulintongjianDate.GetAwardState(tQuestStageInfo.tStageQuestID[i])
			if nQuestState ~= QUEST_PHASE.FINISH and nFinishNum >= tQuestStageInfo.tStageNum[i] then
				WulintongjianDate.tDLCRedPointFlag[tQuestStageInfo.nDLCID] = true
				return true
			end
		end
	end
	return false
end