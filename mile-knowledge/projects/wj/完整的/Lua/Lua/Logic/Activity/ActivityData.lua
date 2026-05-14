-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: ActivityData
-- Date: 2022-12-05 17:48:36
-- Desc: ?
-- ---------------------------------------------------------------------------------


TypeToClassID = {
    [ACTIVITY_TYPE.RELAX] = { 1, 2 },
    [ACTIVITY_TYPE.CONFRONT] = { 3 },
    [ACTIVITY_TYPE.TEAM] = { 4 },
    [ACTIVITY_TYPE.HOME] = { 5 },
    [ACTIVITY_TYPE.HISTORY] = { 6 },
}

ClassIDToType = {
    [1] = ACTIVITY_TYPE.RELAX,
    [2] = ACTIVITY_TYPE.RELAX,
    [3] = ACTIVITY_TYPE.CONFRONT,
    [4] = ACTIVITY_TYPE.TEAM,
    [5] = ACTIVITY_TYPE.HOME,
    [6] = ACTIVITY_TYPE.HISTORY,
}

--玩家完成活动的状态
PLAYER_ACTIVITY_STATE = {
    FINISH = 1,
    CAN_REPEAT = 2,
    NONE = 3,
}


local nTreasureActiveID = 104

local AwardPriority = {
    ["exitem1"] = 1,
    ["exitem2"] = 2,
    ["exitem3"] = 3,
    ["exitem4"] = 4,
    ["exteriorpiece"] = 5,
    ["money"] = 6,
    ["justice"] = 7,
    ["prestige"] = 8,
    ["titlepoint"] = 9,
    ["train"] = 10,
    ["vigor"] = 11,
    ["tongfund"] = 12,
    ["tongresource"] = 13,
    ["prestigelimit"] = 14,
    ["justicelimit"] = 15,
    ["personalhighlevel"] = 16,
    ["teamhighlevel"] = 17,
    ["exdoubleitem"] = 18,
    ["experience"] = 19,
    ["ActiveID"] = 20,
    ["contribution"] = 21,
}

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

    local tbActive = Table_GetCalenderActivityQuest(nQuestID)
    if tbActive and tbActive.nNpcTemplateID ~= -1 then
        local _, nID = pPlayer.RandomByDailyQuest(nQuestID, tbActive.nNpcTemplateID)
        local nFinishedCount, nTotalCount = pPlayer.GetRandomDailyQuestFinishedCount(tbActive.nQuestGroupID)
        local nQusetState = pPlayer.GetQuestPhase(nID)
        if nFinishedCount == nTotalCount then
            nQusetState = QUEST_PHASE.FINISH
        end
        return nID, nQusetState
    else
        return fnFindNext(nQuestID)
    end
end

ActivityData = ActivityData or { className = "ActivityData" }
local self = ActivityData
-------------------------------- 消息定义 --------------------------------
ActivityData.Event = {}
ActivityData.Event.XXX = "ActivityData.Msg.XXX"

local function BigIntAdd(nLeft, nRight)
    return nLeft + nRight
end

local function BigIntSub(nLeft, nRight)
    return nLeft - nRight
end

function ActivityData.Init()
    self._registerEvent()
end

function ActivityData.UnInit()
    Event.UnRegAll(self)
end

function ActivityData.OnLogin()

end

function ActivityData.OnFirstLoadEnd()

end

function ActivityData._loadActivityData()

    self.tbActivityList = {}
    self.tbLikeActivityInfo = {}
    self.tbActivityIDMap = {}

    local tTime = self.GetTodayTime()
    local tbActiveList = Table_GetActivityOfDay(tTime.year, tTime.month, tTime.day, ACTIVITY_UI.CALENDER)

    for _, tbActive in ipairs(tbActiveList) do
        local nType = ClassIDToType[tbActive.nClass]
        if not self.tbActivityList[nType] then
            self.tbActivityList[nType] = {}
        end
        tbActive = self.GetActivityInfo(tbActive)
        if tbActive then
            self.tbActivityIDMap[tbActive.dwID] = true
            table.insert(self.tbActivityList[nType], tbActive)

            if Storage.Activity.bAutoCollect and tbActive.bAutoCollect then
                self.AddLikeActivity(tbActive.dwID, tbActive)
            end
            if self.IsLikeActivity(tbActive.dwID) then
                self.UpdateActiveInfo(tbActive.dwID, tbActive)
            end
        end
    end

    for nType, tbActiveList in pairs(self.tbActivityList) do
        self.SortActivityList(tbActiveList)
    end
    self.UpdateLickActivityList()
end

--新的一天开始则刷新活动数据
function ActivityData._startTimer()
    local nCurTime = GetCurrentTime()
    local nDayEndTime = self.GetDayEndTime()
    self.nTimer = Timer.Add(self, nDayEndTime - nCurTime, function()
        self._loadActivityData()
        self._startTimer()
    end)
end

function ActivityData._stopTimer()
    if self.nTimer then
        Timer.DelTimer(self, self.nTimer)
        self.nTimer = nil
    end
end

function ActivityData.GetTodayTime()
    local nTime = GetCurrentTime()
    local t = TimeToDate(nTime)

    return t
end

function ActivityData.GetDayEndTime()
    local nTime = GetCurrentTime()
    local t = TimeToDate(nTime)
    local nEndTime = DateToTime(t.year, t.month, t.day + 1, 0, 0, 0)
    return nEndTime
end

function ActivityData.GetActivityInfo(tbActive)
    local bShow, szTime, nStartTime, nEndTime = self.GetTimeText(tbActive)
    if bShow then
        tbActive.szTime = szTime
        tbActive.nStartTime = nStartTime
        tbActive.nEndTime = nEndTime
        -- tbActive.nState = self.GetActivityState(tbActive)
        return tbActive
    end
    return nil
end

function ActivityData.GetActivityTimeInfo(tbActive)
    local tTime = self.GetTodayTime()
    local nTime = DateToTime(tTime.year, tTime.month, tTime.day, 7, 0, 0)
    if tbActive.nEvent == CALENDER_EVENT_ALLDAY and BitwiseAnd(tbActive.nShowPosition, ACTIVITY_UI.CALENDER) > 0 then
        tbActive = Table_ParseCalenderActivity(tbActive)

        local tTimeInfo = {}
        tTimeInfo.nStartTime = nTime
        tTimeInfo.nEndTime = nTime + 24 * 60 * 60 - 1
        tbActive.tTimeInfo = tTimeInfo
    elseif tbActive.nEvent == CALENDER_EVENT_DYNAMIC and BitwiseAnd(tbActive.nShowPosition, ACTIVITY_UI.CALENDER) > 0 and
            UI_IsActivityOn(tbActive.dwID)
    then
        tbActive = Table_ParseCalenderActivity(tbActive)
        if IsActivityFitLevel(tbActive) then
            tbActive.nStartTime = nTime
        end
    end

    return tbActive
end

function ActivityData.GetActivityListByType(nType)

    local tbResList = {}
    if nType == ACTIVITY_TYPE.LIKE then
        --收藏根据存储的id取到活动初始数据
        return self.tbLickActivity
    end

    tbResList = self.tbActivityList[nType]
    return tbResList
end

function ActivityData.IsActivityOn(nActivityID, nTimeNow)
    -- if nTimeNow then
    --     return GetActivityMgrClient().IsActivityOn(nActivityID, nTimeNow)
    -- else
    --     return GetActivityMgrClient().IsActivityOn(nActivityID)
    -- end

    if not nTimeNow then
        nTimeNow = GetCurrentTime()
    end

    local nStartTime = nTimeNow - (nTimeNow % 86400)

    local tbDayActivity = self._cacheDayActivity
    if nStartTime ~= self._cacheDayActivityStartTime then
        local nTailTime = nStartTime + 86400 - 1
        tbDayActivity = GetActivityMgrClient().GetActivityOfPeriod(nStartTime, nTailTime)
        if tbDayActivity then
            self._cacheDayActivityStartTime = nStartTime
            self._cacheDayActivity = tbDayActivity
        end
    end
    if not tbDayActivity then
        return false
    end

    for _, tbActivity in ipairs(tbDayActivity) do
        if tbActivity.dwID == nActivityID then
            for _, timeInfo in ipairs(tbActivity.TimeInfo) do
                if timeInfo.nStartTime <= nTimeNow and timeInfo.nEndTime > nTimeNow then
                    return true
                end
            end
        end
    end
    return false
end

-- 获取收藏的活动列表
function ActivityData.GetLikeActivityIDList()
    return Storage.Activity.tbLikeActivityID
end

function ActivityData.AddLikeActivity(dwID, tbActive)
    self.UpdateActiveInfo(dwID, tbActive)
    if table.contain_value(Storage.Activity.tbLikeActivityID, dwID) then
        return
    end
    table.insert(Storage.Activity.tbLikeActivityID, dwID)
    Storage.Activity.Dirty()
    self.UpdateLickActivityList()
end

function ActivityData.UpdateActiveInfo(dwID, tbActive)
    if not self.tbLikeActivityInfo then
        self.tbLikeActivityInfo = {}
    end
    self.tbLikeActivityInfo[dwID] = tbActive
end

function ActivityData.RemoveLikeActivity(dwID)
    local tbActivityList = Storage.Activity.tbLikeActivityID
    for index, value in ipairs(tbActivityList) do
        if value == dwID then
            table.remove(tbActivityList, index)
            break
        end
    end
    Storage.Activity.Dirty()
    self.UpdateActiveInfo(dwID, nil)
    self.UpdateLickActivityList()
end

function ActivityData.IsLikeActivity(dwID)
    local tbActivityList = Storage.Activity.tbLikeActivityID
    for index, value in ipairs(tbActivityList) do
        if value == dwID then
            return true
        end
    end
    return false
end

function ActivityData.GetActivityState(tbActive)
    local nActiveState = PLAYER_ACTIVITY_STATE.NONE

    local tbQuest = string.split(tbActive.szQuestID, ";")
    local nBuffID = tbActive.dwBuffID
    local nQuestFinishAmount = 0
    local nQuestTotalCount = tbActive.nTotalCount

    if nBuffID ~= 0 then
        local buff = Player_GetBuff(nBuffID)
        if buff then
            nQuestFinishAmount = buff.nStackNum
        end
        if nQuestFinishAmount > nQuestTotalCount then
            nQuestFinishAmount = nQuestTotalCount
        end

        if nQuestFinishAmount == nQuestTotalCount and nQuestTotalCount ~= 0 then
            nActiveState = PLAYER_ACTIVITY_STATE.FINISH
        end


    elseif tonumber(tbQuest[1]) ~= -1 then
        local tNewQuestID, nQuestNum = self.GetShowQuestID(tbQuest)
        nQuestFinishAmount = self.GetQuestFinishCount(tbQuest)
        if nQuestFinishAmount == nQuestNum and nQuestNum ~= 0 then
            nActiveState = PLAYER_ACTIVITY_STATE.FINISH
        end

    else
        local nCount, nTotalCount, nNowCount, nFinishCount = self.GetActiveFinishCount(tbActive)
        if nCount and nTotalCount then
            if nCount >= nTotalCount then
                nActiveState = PLAYER_ACTIVITY_STATE.FINISH
                if tbActive.nFinishType == 1 then
                    nActiveState = PLAYER_ACTIVITY_STATE.CAN_REPEAT
                end
            end
        end
    end

    return nActiveState
end

function ActivityData.GetActiveFinishCount(tbActive)
    local hPlayer = g_pClientPlayer
    local nCount, nTotalCount, nNowCount, nFinishCount
    if tbActive.dwDailyQuestID > 0 then
        nCount, nTotalCount = hPlayer.GetRandomDailyQuestFinishedCount(tbActive.dwDailyQuestID)
        nNowCount = nCount
        if nCount and nTotalCount then
            nCount = math.min(nCount, nTotalCount)
        end

    elseif tbActive.dwBuffID > 0 then
        nTotalCount = tbActive.nTotalCount
        local buff = Player_GetBuff(tbActive.dwBuffID)
        nCount = 0
        if buff then
            nCount = buff.nStackNum
            nNowCount = nCount
            nCount = math.min(nCount, nTotalCount)
        end

    end
    nFinishCount = tbActive.nFinishCount

    return nCount, nTotalCount, nNowCount, nFinishCount
end

function ActivityData.UpdateLickActivityList()
    local tbActiveIDList = self.GetLikeActivityIDList()
    self.tbLickActivity = {}
    for nIndex, nActiveID in ipairs(tbActiveIDList) do
        local tbActiveInfo = self.tbLikeActivityInfo[nActiveID]
        table.insert(self.tbLickActivity, tbActiveInfo)
    end
    self.SortActivityList(self.tbLickActivity)
end

function ActivityData.SortActivityList(tbResList)
    local hPlayer = g_pClientPlayer

    local fnSortByLevel = function(tLeft, tRight)
        if tLeft.nSortLevel == tRight.nSortLevel then
            if tLeft.nClass == tRight.nClass then
                if tLeft.nStar == tRight.nStar then
                    return tLeft.nLevel > tRight.nLevel
                end

                return tLeft.nStar > tRight.nStar
            end

            return tLeft.nClass < tRight.nClass
        end

        return tLeft.nSortLevel < tRight.nSortLevel
    end

    local fnSortByPriority = function(tLeft, tRight)
        if tLeft.nClass == tRight.nClass then
            if tLeft.nStar == tRight.nStar then
                return tLeft.nLevel > tRight.nLevel
            end

            return tLeft.nStar > tRight.nStar
        end

        return tLeft.nClass < tRight.nClass
    end

    local fnSort = fnSortByPriority

    if hPlayer.nLevel < hPlayer.nMaxLevel then
        for _, tPage in ipairs(tbResList) do
            if tPage.nLevel <= hPlayer.nLevel then
                --优先排 能完成的任务
                tPage.nSortLevel = 1
            else
                tPage.nSortLevel = 2
            end
        end
        fnSort = fnSortByLevel
    end
    table.sort(tbResList, fnSort)
end

function ActivityData.SortAwardList(tbAwardList)

    local funcSort = function(tLeft, tRight)
        return AwardPriority[tLeft.szType] < AwardPriority[tRight.szType]
    end
    table.sort(tbAwardList, funcSort)

end

function ActivityData.GetTimeText(tbActive, bVisable)
    local bShow = true
    if tbActive.nEvent == CALENDER_EVENT_ALLDAY or tbActive.nEvent == CALENDER_EVENT_RESET then
        --全天开放;重置
        return bShow, g_tStrings.CALENDER_ALL_DAY    --全天开放
    elseif tbActive.nEvent == CALENDER_EVENT_DYNAMIC then
        return bShow, UIHelper.GBKToUTF8(tbActive.szTimeRepresent) ----动态开放
    end

    local nTime = GetCurrentTime()
    if bVisable then
        nTime = nTime + 24 * 3600
    end

    local tTimeInfo = tbActive.tTimeInfo

    local tShowTime
    for _, tTime in ipairs(tTimeInfo) do
        tShowTime = tTime
        if nTime < tTime.nStartTime or --没开始; 或者已经结束
                (nTime >= tTime.nStartTime and nTime <= tTime.nEndTime)
        then
            break
        end
    end

    local tNowTime = TimeToDate(nTime)
    local nDayStartTime = DateToTime(tNowTime.year, tNowTime.month, tNowTime.day, 7, 0, 0)
    local nDayEndTime = BigIntAdd(nDayStartTime, 24 * 60 * 60 - 60)
    local nTodayStartTime = DateToTime(tNowTime.year, tNowTime.month, tNowTime.day, 0, 0, 0)
    local nTodayEndTime = DateToTime(tNowTime.year, tNowTime.month, tNowTime.day, 23, 59, 59)

    if tbActive.nEvent == CALENDER_EVENT_LONG and tShowTime.nStartTime <= nDayStartTime and tShowTime.nEndTime >= nDayEndTime then
        return bShow, g_tStrings.CALENDER_ALL_DAY
    end

    local nStartTime
    local nEndTime
    if tShowTime.nEndTime >= nDayStartTime then
        nStartTime = math.max(tShowTime.nStartTime, nDayStartTime)
        nEndTime = math.min(tShowTime.nEndTime, nDayEndTime)
        bShow = (not (nTime < nDayStartTime and tShowTime.nStartTime >= nDayStartTime))
    else
        nStartTime = nTodayStartTime
        nEndTime = tShowTime.nEndTime
        --bShow = (nTime < nDayStartTime)
        bShow = (nTime < tShowTime.nEndTime)
    end

    local tStartTime = TimeToDate(nStartTime)
    local tEndTime = TimeToDate(nEndTime)
    local szStartTime = UIHelper.GBKToUTF8(tStartTime.hour) .. ":" .. string.format("%02d", UIHelper.GBKToUTF8(tStartTime.minute))
    local szEndTime = UIHelper.GBKToUTF8(tEndTime.hour) .. ":" .. string.format("%02d", UIHelper.GBKToUTF8(tEndTime.minute))
    if nEndTime > nTodayEndTime then
        szEndTime = g_tStrings.CYCLOPAEDIA_CLENDER_TOMORROW .. szEndTime
    end

    local szTime = FormatString(g_tStrings.CALENDER_TIME, szStartTime, szEndTime)
    return bShow, szTime, nStartTime, nEndTime
end

function ActivityData.CanTPLinkShow(tLinkInfo)
    if not tLinkInfo then
        return
    end
    local hPlayer = g_pClientPlayer
    if not hPlayer then
        return
    end
    local bResult = true
    if tLinkInfo.nCamp and tLinkInfo.nCamp ~= 3 and tLinkInfo.nCamp ~= hPlayer.nCamp then
        bResult = false
    end
    if tLinkInfo.dwForceID and tLinkInfo.dwForceID ~= 0 and tLinkInfo.dwForceID ~= hPlayer.dwForceID then
        bResult = false
    end
    return bResult
end

function ActivityData.GetLinkList(tbActive)
    local tbTargetList = {}
    if (not tbActive) or (not tbActive.szTPLink) then
        return tbTargetList
    end
    local tbLinkMap = string.split(tbActive.szTPLink, ";")
    for nIndex, szArgs in ipairs(tbLinkMap) do
        local tbArgs = string.split(szArgs, "_")
        local nLinkID = tonumber(tbArgs[1])
        local dwMapID = tonumber(tbArgs[2])
        local tAllLinkInfo = {}
        if nLinkID and not dwMapID then
            tAllLinkInfo = Table_GetCareerGuideAllLink(nLinkID)
        elseif nLinkID and dwMapID then
            local tInfo = Table_GetCareerLinkNpcInfo(nLinkID, dwMapID)
            table.insert(tAllLinkInfo, tInfo)
        end
        for _, tInfo in pairs(tAllLinkInfo) do
            local bCanShow = self.CanTPLinkShow(tInfo)
            if bCanShow then
                table.insert(tbTargetList, tInfo)
            end
        end
    end

    return tbTargetList
end

--前往目标序列
function ActivityData.GetTravelTargets(tbActive)
    local tbTargetList = {}
    if (not tbActive) or (not tbActive.szDetailMap) then
        return tbTargetList
    end
    for szLink in string.gmatch(tbActive.szDetailMap, "link=\"%a+/%d+\"") do
        local szLinkEvent, szLinkArg = szLink:match("(%a+)/(%d+)")
        if szLinkEvent == "NPCGuide" then
            local nLinkID = tonumber(szLinkArg)
            local tAllLinkInfo = Table_GetCareerGuideAllLink(nLinkID)
            for _, tInfo in pairs(tAllLinkInfo) do
                table.insert(tbTargetList, tInfo)
            end
        end
    end
    self.SortTravelTargets(tbTargetList)
    return tbTargetList
end

---当前场景近距离 > 当前场景远距离 > 非当前场景配置在前 > 非当前场景配置在后
function ActivityData.SortTravelTargets(tbTargetList)
    local player = g_pClientPlayer
    if not player then
        return true
    end
    local scene = player.GetScene()

    local tbResList = {}
    for index, tbTargetInfo in ipairs(tbTargetList) do
        if scene.dwMapID == tbTargetInfo.dwMapID then
            table.insert(tbResList, tbTargetInfo)
        end
    end

    local funcSort = function(tLeft, tRight)
        local nPlayerX, nPlayerY = player.nX, player.nY
        local n2DDistanceToLeft = kmath.len2(nPlayerX, nPlayerY, tLeft.fX, tLeft.fY)
        local n2DDistanceToRight = kmath.len2(nPlayerX, nPlayerY, tRight.fX, tRight.fY)
        return n2DDistanceToLeft < n2DDistanceToRight
    end

    table.sort(tbResList, funcSort)
    for index, tbTargetInfo in ipairs(tbTargetList) do
        if scene.dwMapID ~= tbTargetInfo.dwMapID then
            table.insert(tbResList, tbTargetInfo)
        end
    end

    tbTargetList = tbResList
end

function ActivityData.GetActiveInfo(dwActiveID)
    return Table_GetCalenderActivity(dwActiveID)
end

function ActivityData.GetAwardInfo(dwActiveID)
    local tbAwardList = Table_GetCalenderActivityAward(dwActiveID)
    local tbResList = {}
    for index, value in pairs(tbAwardList) do
        if ((type(value) == "number" and value > 0) or (type(value) == "string" and value ~= "")) and (index ~= "ActiveID" and index ~= "experience") then
            table.insert(tbResList, { ["szType"] = index, ["szCount"] = value })
        end
    end
    self.SortAwardList(tbResList)
    return tbResList
end

function ActivityData.GetActivityQuestIDList(tbActivityInfo)
    local tbResList = {}
    local tbStrQuestID = string.split(tbActivityInfo.szQuestID, ";")
    local pPlayer = g_pClientPlayer
    for index, szQuestID in ipairs(tbStrQuestID) do
        if szQuestID ~= "-1" and szQuestID ~= "" then
            local nQuestID = tonumber(szQuestID)
            local nQuestID, nQusetState = GetQuestState(nQuestID)
            local tbActive = Table_GetCalenderActivityQuest(nQuestID)
            if nQusetState == QUEST_PHASE.FINISH then
                if not tbActive or tbActive.bCompleteShow then
                    table.insert(tbResList, nQuestID)
                end
            elseif nQusetState == QUEST_PHASE.UNACCEPT then
                if (not tbActive or tbActive.bUnacceptedShow) and (tbActive and tbActive.bIgnoreCanAccept or pPlayer.CanAcceptQuest(nQuestID) == QUEST_RESULT.SUCCESS) then
                    table.insert(tbResList, nQuestID)
                end
            elseif nQusetState == QUEST_PHASE.ACCEPT or nQusetState == QUEST_PHASE.DONE then
                table.insert(tbResList, nQuestID)
            end
        end
    end
    return tbResList
end

function ActivityData.GetAllActivityQuestIDList()
    local player = g_pClientPlayer
    if not player then
        return
    end

    local tbResList = {}
    for nType, tbActivityList in pairs(self.tbActivityList) do
        for nIndex, tbActivityInfo in pairs(tbActivityList) do
            local tbStrQuestID = string.split(tbActivityInfo.szQuestID, ";")
            for index, szQuestID in ipairs(tbStrQuestID) do
                if szQuestID ~= "-1" and szQuestID ~= "" then
                    local nQuestID = tonumber(szQuestID)
                    local nQuestID, nQusetState = GetQuestState(nQuestID)
                    local tbActive = Table_GetCalenderActivityQuest(nQuestID)
                    if nQusetState == QUEST_PHASE.FINISH then
                        if not tbActive or tbActive.bCompleteShow then
                            table.insert(tbResList, nQuestID)
                        end
                    elseif nQusetState == QUEST_PHASE.UNACCEPT then
                        if (not tbActive or tbActive.bUnacceptedShow) and (tbActive and tbActive.bIgnoreCanAccept or pPlayer.CanAcceptQuest(nQuestID) == QUEST_RESULT.SUCCESS) then
                            table.insert(tbResList, nQuestID)
                        end
                    elseif nQusetState == QUEST_PHASE.ACCEPT or nQusetState == QUEST_PHASE.DONE then
                        table.insert(tbResList, nQuestID)
                    end
                end
            end
        end
    end
    return tbResList
end

function ActivityData.GetActivityTarget(tbActivityInfo)
    local tbResStr = ""
    local tbQuestIDList = self.GetActivityQuestIDList(tbActivityInfo)
    local nCount = #tbQuestIDList

    if nCount > 1 then
        for index, nQuestID in ipairs(tbQuestIDList) do
            local tbQuestConfig = QuestData.GetQuestConfig(nQuestID)
            local szActivityTarget = UIHelper.GBKToUTF8(tbQuestConfig.szObjective)
            tbResStr = tbResStr .. szActivityTarget .. (index == #tbQuestIDList and "" or "\n")
        end
    elseif nCount == 1 then
        tbResStr = QuestData.GetQuestTargetValueStr(tbQuestIDList[1])
    end

    return tbResStr, nCount
end

function ActivityData.GetQuestFinishCount(tbQuestID)
    local nCount = 0
    for _, v in ipairs(tbQuestID) do
        local _, nQusetState = GetQuestState(tonumber(v))
        if nQusetState and nQusetState == QUEST_PHASE.FINISH then
            nCount = nCount + 1
        end
    end
    return nCount
end

function ActivityData.GetShowQuestID(tbQuestID, bIgnoreCompleteShow)
    local pPlayer = g_pClientPlayer
    local tbNewQuestID = {}
    local nQuestNum = 0
    for _, v in ipairs(tbQuestID) do
        local nQuestID = tonumber(v)
        local nResult = pPlayer.CanAcceptQuest(nQuestID)
        local tLine = Table_GetCalenderActivityQuest(nQuestID)
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
            if (not tLine or tLine.bCompleteShow) or bIgnoreCompleteShow then
                table.insert(tbNewQuestID, nQuestID)
            end
        elseif nQusetState == QUEST_PHASE.UNACCEPT then
            if (not tLine or tLine.bUnacceptedShow) and (tLine and tLine.bIgnoreCanAccept or pPlayer.CanAcceptQuest(nQuestID) == QUEST_RESULT.SUCCESS) then
                table.insert(tbNewQuestID, nQuestID)
            end
        elseif nQusetState == QUEST_PHASE.ACCEPT or nQusetState == QUEST_PHASE.DONE then
            table.insert(tbNewQuestID, nQuestID)
        end
    end
    return tbNewQuestID, nQuestNum
end

function ActivityData.GetActivityQuestFinishAmount(tbActivityInfo)
    local nQuestFinishAmount = 0
    local tbQuestID = SplitString(tbActivityInfo.szQuestID, ";")
    local dwBuffID = tbActivityInfo.dwBuffID
    local nQuestTotalCount = tbActivityInfo.nTotalCount

    if dwBuffID ~= 0 then
        local buff = Player_GetBuff(dwBuffID)
        if buff then
            nQuestFinishAmount = buff.nStackNum
        end
        if nQuestFinishAmount > nQuestTotalCount then
            nQuestFinishAmount = nQuestTotalCount
        end
    elseif tonumber(tbQuestID[1]) ~= -1 then
        nQuestFinishAmount = self.GetQuestFinishCount(tbQuestID)
    end
    return nQuestFinishAmount
end

function ActivityData.GetActivityQuestFinishAmountByID(dwActiveID)
    local tbActivity = self.GetActiveInfo(dwActiveID)
    return self.GetActivityQuestFinishAmount(tbActivity)
end

function ActivityData.GetActivityQuestTotalCount(tbActivityInfo)
    local nQuestTotalCount = 0
    local tbQuestID = SplitString(tbActivityInfo.szQuestID, ";")
    local dwBuffID = tbActivityInfo.dwBuffID

    if dwBuffID ~= 0 then
        nQuestTotalCount = tbActivityInfo.nTotalCount
    elseif tonumber(tbQuestID[1]) ~= -1 then
        local tNewQuestID, nQuestNum = self.GetShowQuestID(tbQuestID)
        nQuestTotalCount = nQuestNum
    end
    return nQuestTotalCount
end

function ActivityData.GetActivityQuestTotalCountByID(dwActiveID)
    local tbActivity = self.GetActiveInfo(dwActiveID)
    return self.GetActivityQuestTotalCount(tbActivity)
end

function ActivityData.CheckActiveIsShowByID(dwActiveID)

    if self.tbActivityIDMap[dwActiveID] then
        return true
    end
    return false
end

function ActivityData.LinkToActiveByIDList(tbActivityID, szTips)
    local bLinkSuccess = false
    for nIndex, nActivityID in ipairs(tbActivityID) do
        if self.LinkToActiveByID(nActivityID, false) then
            bLinkSuccess = true
            return
        end
    end
    if not szTips then
        szTips = "活动未开放"
    end
    if not bLinkSuccess then
        TipsHelper.ShowNormalTip(szTips)
    end
end

function ActivityData.LinkToActiveByID(dwActiveID, bShowTip)

    if bShowTip == nil then
        bShowTip = true
    end

    if not self.CheckActiveIsShowByID(dwActiveID) then
        if bShowTip then
            TipsHelper.ShowNormalTip("活动未开放")
        end
        return
    end

    local tbActivity = ActivityData.GetActiveInfo(dwActiveID)
    local nTargetType = ClassIDToType[tbActivity.nClass]
    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelActivityCalendar)
    if not scriptView then
        scriptView = UIMgr.Open(VIEW_ID.PanelActivityCalendar, nTargetType, dwActiveID)
    else
        scriptView:OnEnter(nTargetType, dwActiveID)
    end
    return true
end

function ActivityData.GetActivityType(tbActive)
    if self.IsLikeActivity(tbActive.dwID) then
        return ACTIVITY_TYPE.LIKE
    end
    return ClassIDToType[tbActive.nClass]
end

local function InsertActive(tActiveList, tActive)
    for _, tA in ipairs(tActiveList) do
        if tA[1] == tActive[1] then
            return
        end
    end
    table.insert(tActiveList, tActive)
end

local function GetNextDay(tDate)
    local nTime = DateToTime(tDate.year, tDate.month, tDate.day, tDate.hour, tDate.minute, tDate.second)
    nTime = BigIntAdd(nTime, 24 * 60 * 60)
    local tTime = TimeToDate(nTime)
    return tTime
end

function ActivityData.UpdateAdvanceList(tbActiveList, tbAdvancedTimeMap, tbAdvanceActive)
    local nNowTime = GetCurrentTime()
    for _, tActive in ipairs(tbActiveList) do
        if tActive.tAdvancedTime and nNowTime < tActive.nStartTime then

            for _, nTime in ipairs(tActive.tAdvancedTime) do
                local nAdvanceTime = BigIntSub(tActive.nStartTime, nTime * 60)
                if nAdvanceTime > nNowTime then
                    if not tbAdvancedTimeMap[nAdvanceTime] then
                        table.insert(tbAdvanceActive, { nAdvanceTime, {} })
                        tbAdvancedTimeMap[nAdvanceTime] = #tbAdvanceActive
                    end
                    local nIndex = tbAdvancedTimeMap[nAdvanceTime]
                    InsertActive(tbAdvanceActive[nIndex][2], { tActive.dwID, tActive.szName, tActive.nStartTime, tActive.nEndTime })
                end
            end
        end
    end
end

function ActivityData.OnStartBubbleCall()
    local nNowTime = GetCurrentTime()
    local tTime = TimeToDate(nNowTime)
    local tAdvancedTimeMap = {}

    if not self.tAdvanceActive then
        self.tAdvanceActive = {}
        local tAllActive = Table_GetCalenderOfDay(tTime.year, tTime.month, tTime.day, ACTIVITY_UI.BUBBLE)
        self.UpdateAdvanceList(tAllActive, tAdvancedTimeMap, self.tAdvanceActive)
    end
    local tNextDay = GetNextDay(tTime)
    local tAllActive = Table_GetCalenderOfDay(tNextDay.year, tNextDay.month, tNextDay.day, ACTIVITY_UI.BUBBLE)
    self.UpdateAdvanceList(tAllActive, tAdvancedTimeMap, self.tAdvanceActive)

    local nNextTime = DateToTime(tNextDay.year, tNextDay.month, tNextDay.day, 1, 0, 0)
    if nNextTime < nNowTime then
        return
    end

    local nLimitTime = 24 * 60 * 60
    local nCallTime = BigIntSub(nNextTime, nNowTime)
    if nCallTime < nLimitTime then
        Timer.Add(self, nCallTime, function()
            self.OnStartBubbleCall()
        end)
    end

    local SortByTime = function(tLeft, tRight)
        return tLeft[1] > tRight[1]
    end

    table.sort(self.tAdvanceActive, SortByTime)
    local nIndex = #self.tAdvanceActive
    if nIndex >= 1 then
        local nDelayCallTime = BigIntSub(self.tAdvanceActive[nIndex][1], nNowTime)
        if nDelayCallTime < nLimitTime then
            Timer.Add(self, nDelayCallTime, function()
                self.OnAdviceActoveCall()
            end)
        end
    end
end

function ActivityData.OnAdviceActoveCall()
    local nTime = GetCurrentTime()
    local nCount = #self.tAdvanceActive
    if nCount <= 0 then
        return
    end

    local tNeedAdvance = self.tAdvanceActive[nCount][2]
    for _, tActive in ipairs(tNeedAdvance) do
        local nLivetime = tActive[3] - GetCurrentTime()
        local szContent = nLivetime > 0 and UIHelper.GetTimeText(nLivetime, false, true) .. g_tStrings.ACTIVE_POPULARIZE_START or g_tStrings.ACTIVE_POPULARIZE_STARTED
        BubbleMsgData.PushMsgWithType("OnAdvancedActiveTip", {
            szTitle = UIHelper.GBKToUTF8(tActive[2]),
            szBarTitle = UIHelper.GBKToUTF8(tActive[2]),
            nBarTime = 10, -- 显示在气泡栏的时长, 单位为秒
            szContent = szContent,
            szAction = function()
                self.LinkToActiveByID(tActive[1])
            end,
            nLifeTime = 10, -- 存在时长, 单位为秒
        })
    end

    if nCount >= 2 then
        local nDelayCallTime = BigIntSub(self.tAdvanceActive[nCount - 1][1], nTime)
        Timer.Add(self, nDelayCallTime, function()
            self.OnAdviceActoveCall()
        end)
    end

    table.remove(self.tAdvanceActive, nCount)
end

function ActivityData.Teleport_Go(tbInfo, nActivityId)
    local enterCrossServerMap = function()
        if HomelandData.CheckIsHomelandMapTeleportGo(tbInfo.nLinkID, tbInfo.dwMapID, nActivityId, nil, function ()
                if nActivityId == nTreasureActiveID then
                    self.bShowTreasure = true
                end
            end) then
            return
        end

        MapMgr.CheckTransferCDExecute(function()
            RemoteCallToServer("On_Teleport_Go", tbInfo.nLinkID, tbInfo.dwMapID, nActivityId)
            if nActivityId == nTreasureActiveID then
                self.bShowTreasure = true
            end
        end)
    end

    local szMapName = UIHelper.GBKToUTF8(Table_GetMapName(tbInfo.dwMapID))
    if not PakDownloadMgr.UserCheckDownloadMapRes(tbInfo.dwMapID, enterCrossServerMap, "地图资源文件下载完成，" .. szMapName) then
        return
    end

    enterCrossServerMap()

end

function ActivityData.IsJingHuaMap()
    return g_pClientPlayer and g_pClientPlayer.GetMapID() == 487 --镜花别院
end

function ActivityData.IsHotSpringActivity()
    return g_pClientPlayer and g_pClientPlayer.GetMapID() == 451 and (self.IsActivityOn(32) or UI_IsActivityOn(32)) --温泉山庄
end

function ActivityData._delayLoadData()
    if self.nLoadTimer then
        Timer.DelTimer(self, self.nLoadTimer)
        self.nLoadTimer = nil
    end
    self.nLoadTimer = Timer.AddFrame(self, 10, function()
        self._loadActivityData()
    end)
end

function ActivityData._registerEvent()
    Event.Reg(self, "FIRST_LOADING_END", function()
        self.OnStartBubbleCall()
    end)

    Event.Reg(self, "ON_ACTIVITY_STATE_CHANGED_NOTIFY", function(dwActivityID, nState)
        self._delayLoadData()
    end)


    Event.Reg(self, "PLAYER_LEVEL_UP", function()
        local nPlayerId = arg0
        if g_pClientPlayer.dwID == nPlayerId then
            self._delayLoadData()
        end
    end)

    Event.Reg(self, "PLAYER_LEVEL_UPDATE", function()
        local nPlayerId = arg0
        if g_pClientPlayer.dwID == nPlayerId then
            self._delayLoadData()
        end
    end)

    Event.Reg(self, EventType.OnClientPlayerEnter, function()
        self._loadActivityData()
        self._startTimer()
    end)

    Event.Reg(self, EventType.OnClientPlayerLeave, function()
        self._stopTimer()
    end)

    Event.Reg(self, "LOADING_END", function()
        local player = g_pClientPlayer
        if not player then
            return
        end

        local nMapID = player.GetMapID()
        if self.bShowTreasure then
            self._showTreasure(nMapID)
            self.bShowTreasure = false
        end
    end)
end

--显示寻宝
function ActivityData._showTreasure(nMapID)
    if CrossMgr.IsCrossing(nil, true) then
        return
    end

    if BattleFieldData.IsInTreasureBattleFieldMap(true) then
        return
    end

    local bOutScene = not Table_DoesMapHaveTreasure(nMapID)
    if bOutScene then
        -- OutputMessage("MSG_SYS", Craft_GetCantOpenCompassInSceneMsg())
        TipsHelper.ShowNormalTip("当前场景不能感应到宝藏点")
    else
        Event.Dispatch(EventType.OnTogCompass, true)
        RemoteCallToServer("OnHoroSysDataRequest")
    end
end

-- 某些界面（目前包括队伍招募界面、师徒界面、帮会列表界面等）的信息编辑是否被允许
function ActivityData.IsMsgEditAllowed()
    return UI_IsActivityOn(ACTIVITY_ID.ALLOW_EDIT) -- 此活动在时间上一直开启，通过策划调用指令来改变实际的开启状态
end

function ActivityData.MatchActivity(dwActivityID)
	if not dwActivityID or dwActivityID <= 0 then
		return true
	end

	local bOn = UI_IsActivityOn(dwActivityID)
	return bOn
end

function ActivityData.GetQuestState(nQuestID)
    return GetQuestState(nQuestID)
end

function ActivityData.GetCountdownTimeText(tbActiveInfo)
    local nTime = GetCurrentTime()
    local tTimeInfo = tbActiveInfo.tTimeInfo
	local szTime = ""
    local tShowTime
    for _, tTime in ipairs(tTimeInfo) do
        tShowTime = tTime
        if nTime < tTime.nStartTime or --没开始; 或者已经结束
           (nTime >= tTime.nStartTime and nTime <= tTime.nEndTime)
        then
            break
        end
    end
	if tShowTime and tShowTime.nEndTime then
		local nLeftTime = tShowTime.nEndTime - nTime
		szTime = UIHelper.GetTimeTextWithDay(nLeftTime, false, false)
	end
	return szTime
end

function ActivityData.IsActivityVisited(dwActivityID, nVersion)
    nVersion = nVersion or 0
    if not Storage.Activity.tActivityRedDotVertion[dwActivityID] then
        self.SetActivityRedDotVersion(dwActivityID, 0)
    end
    return Storage.Activity.tActivityRedDotVertion[dwActivityID] >= nVersion
end

function ActivityData.SetActivityRedDotVersion(dwActivityID, nVersion)
    nVersion = nVersion or 0
    Storage.Activity.tActivityRedDotVertion[dwActivityID] = nVersion
    Storage.Activity.Flush()
end

function ActivityData.CheckNewActivity(nType)
    local bResult = nil
    if nType then
        local tbActiveList = self.GetActivityListByType(nType)
        bResult = self.CheckNewByInfo(tbActiveList)
    else
        bResult = self.CheckAllActivity()
    end
    return bResult
end

function ActivityData.CheckAllActivity()    --所有活动红点
    -- 因为 GetActivityMgrClient().GetActivityOfDayEx(nYear, nMonth, nDay)
    -- 这个C++接口 使用的时区和东8区跨度较大就会特别卡（在手机上）
    -- 因此这里特判，其他比如过图、打开世界地图活动界面暂时不理
    if Platform.IsAndroid() then
        if GetTimezone() ~= -28800 then
            return false
        end
    end

    if Platform.IsIos() then
        if gettimezone() ~= 28800 then
            return false
        end
    end

    local bHasNew    = false
    local tTime = self.GetTodayTime()
    local tbActiveList = Table_GetActivityOfDay(tTime.year, tTime.month, tTime.day, ACTIVITY_UI.CALENDER)
    if tbActiveList then
        for nType, tbActive in pairs(tbActiveList) do
            local bShow = self.GetTimeText(tbActive)
            if bShow and not self.IsActivityVisited(tbActive.dwID, tbActive.nRedDotVersion) then
                bHasNew = true
                break
            end
        end
    end

    return bHasNew
end

function ActivityData.CheckNewByInfo(tbActiveList)
    local bHasNew    = false
    for _, tInfo in pairs(tbActiveList) do
	    if tInfo then
			local bShow = self.GetTimeText(tInfo)
			local bVisited = self.IsActivityVisited(tInfo.dwID, tInfo.nRedDotVersion)
			if bShow and not bVisited then
				bHasNew = true
				break
            end
		end
	end
	return bHasNew
end


function ActivityData.OpenFestivalRewardPop(nActivityID)
    if not g_pClientPlayer then
        return
    end
    local tbRewardInfo = GDAPI_GetInfo_LoginReward(g_pClientPlayer, nActivityID)
    if nActivityID and tbRewardInfo then
        UIMgr.Open(VIEW_ID.PanelFestivalRewardPop, tbRewardInfo)
    end
end

function ActivityData.OpenFestivalStampPop(nActivityID)
    local tInfo = Table_GetActivityCollectInfoList(nActivityID)
    if tInfo then
        tInfo.nActivityID = nActivityID
        UIMgr.Open(VIEW_ID.PanelFestivalStampPop, tInfo)
    end
end