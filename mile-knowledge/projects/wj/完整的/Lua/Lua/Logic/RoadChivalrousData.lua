-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: RoadChivalrousData
-- Date: 2023-04-03 16:34:46
-- Desc: ?
-- ---------------------------------------------------------------------------------

RoadChivalrousData = RoadChivalrousData or {}
local self = RoadChivalrousData
-------------------------------- 消息定义 --------------------------------
RoadChivalrousData.Event = {}
RoadChivalrousData.Event.XXX = "RoadChivalrousData.Msg.XXX"

local m_tModuleInfo = {}
local m_tSubModuleInfo = {}
local m_tQuestInfo = {}

--a;b;d;
local function ParseKey(szKey)
    local tLine = {}
    tLine = SplitString(szKey, ";")
    for index, value in pairs(tLine) do
        tLine[index] = tonumber(value)
    end
    return tLine
end

--type_index_count;type_index_count
local function ParseItemString(szReward)
    local tItemList		= {}
    local tItems 	    = SplitString(szReward, ";")
    local nNumOfItems	= #tItems
    for j = 1, nNumOfItems do
        local tItemInfo = {}
        local tItem = SplitString(tItems[j], "_")
        tItemInfo.nItemType  = tItem[1]
        tItemInfo.nItemIndex = tItem[2]
        tItemInfo.nItemNum   = tItem[3]
        table.insert(tItemList, tItemInfo)
    end
    return tItemList
end

--<12,23><15,18>
local function ParseLimitTimeString(szTime)
    local tRet = {}
    for szTime in string.gmatch(szTime, "<([%d,;|]+)>") do
        -- local tList = {}
        local tTime = SplitString(szTime, ",")
        tRet["StartTime"] = tonumber(tTime[1])
        tRet["EndTime"] = tonumber(tTime[2])
        -- table.insert(tRet, tList)
    end
    return tRet
end

function RoadChivalrousData.LoadRoadChivalRousModuleTable()
    m_tModuleInfo = {}
    local nCount = g_tTable.RoadChivalrousModule:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.RoadChivalrousModule:GetRow(i)
        local dwModuleID = tLine.dwModuleID
        m_tModuleInfo[dwModuleID] = {}
        m_tModuleInfo[dwModuleID].tSubModuleID = ParseKey(tLine.szSubModuleID)
        m_tModuleInfo[dwModuleID].tItemID = ParseKey(tLine.szIniItem)
        m_tModuleInfo[dwModuleID].tReward = ParseItemString(tLine.szReward)
        m_tModuleInfo[dwModuleID].nLimitLevel = tLine.nLimitLevel
        m_tModuleInfo[dwModuleID].dwBindingQuestID = tLine.dwBindingQuestID
    end
end

function RoadChivalrousData.LoadRoadChivalRousSubModuleTable()
    m_tSubModuleInfo = {}
    local player = GetClientPlayer()
    local nCount = g_tTable.RoadChivalrousSubModule:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.RoadChivalrousSubModule:GetRow(i)
        local dwSubModuleID = tLine.dwSubModuleID
        m_tSubModuleInfo[dwSubModuleID] = {}
        m_tSubModuleInfo[dwSubModuleID].szName = tLine.szName
        m_tSubModuleInfo[dwSubModuleID].tQuestID = ParseKey(tLine.szQuestID)
        m_tSubModuleInfo[dwSubModuleID].szImagePath = tLine.szImagePath
        m_tSubModuleInfo[dwSubModuleID].nActivatedImageFrame = tLine.nActivatedImageFrame
        m_tSubModuleInfo[dwSubModuleID].nInActivatedImageFrame = tLine.nInActivatedImageFrame
        m_tSubModuleInfo[dwSubModuleID].tReward = ParseItemString(tLine.szReward)
        m_tSubModuleInfo[dwSubModuleID].tPredecessorID = ParseKey(tLine.szPredecessor) or {}
        m_tSubModuleInfo[dwSubModuleID].dwBindingQuestID = tLine.dwBindingQuestID
        m_tSubModuleInfo[dwSubModuleID].nLimitLevel = tLine.nLimitLevel
        m_tSubModuleInfo[dwSubModuleID].nLimitNumber = tLine.nLimitNumber
        m_tSubModuleInfo[dwSubModuleID].tLimitTime = ParseLimitTimeString(tLine.szLimitTime)
        m_tSubModuleInfo[dwSubModuleID].nRefreshTime = tLine.nRefreshTime
        m_tSubModuleInfo[dwSubModuleID].szTip = tLine.szTip
        m_tSubModuleInfo[dwSubModuleID].szTarget = tLine.szTarget
    end
end

function RoadChivalrousData.LoadRoadChivalRousQuestTable()
    m_tQuestInfo = {}
    local nCount = g_tTable.RoadChivalrousQuest:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.RoadChivalrousQuest:GetRow(i)
        local dwQuestID = tLine.dwQuestID
        m_tQuestInfo[dwQuestID] = {}
        m_tQuestInfo[dwQuestID].szName = tLine.szName
    end
end

function RoadChivalrousData.LoadRoadChivalrousTable()
    self.LoadRoadChivalRousModuleTable()
    self.LoadRoadChivalRousSubModuleTable()
    self.LoadRoadChivalRousQuestTable()
end

function RoadChivalrousData.Init()
    if not self.bLoadData then
        self.LoadRoadChivalrousTable()
        self.bLoadData = true
    end
end

function RoadChivalrousData.UnInit()
    
end

function RoadChivalrousData.OnLogin()
    
end

function RoadChivalrousData.OnFirstLoadEnd()
    
end

function RoadChivalrousData.InitSubModuleIDIndex()
    self.nSubModuleIDIndex = 1
end

function RoadChivalrousData.GetSubModuleID(nCount, dwModuleID)
    local tbSubModuleID = {}
    local tbAllSubModuleID = self.GetSubModules(dwModuleID)
    for index = 1, nCount do
        table.insert(tbSubModuleID, tbAllSubModuleID[self.nSubModuleIDIndex])
        self.nSubModuleIDIndex = self.nSubModuleIDIndex + 1
    end
    return tbSubModuleID
end

function RoadChivalrousData.GetReMainSubModuleID(dwModuleID)
    local tbAllSubModuleID = self.GetSubModules(dwModuleID)
    return math.max(0, #tbAllSubModuleID - self.nSubModuleIDIndex + 1)
end

function RoadChivalrousData.GetModuleReward(dwModuleID)
    return m_tModuleInfo[dwModuleID].tReward
end

function RoadChivalrousData.GetSubModuleLimitLevel( dwSubModuleID )
    return m_tSubModuleInfo[dwSubModuleID].nLimitLevel
end

function RoadChivalrousData.GetQuestName(dwQuestID)
    local tQuestInfo = m_tQuestInfo[dwQuestID]
    if not tQuestInfo then
        UILog("RoadChivalrousQuest.txt中不存在QuestID="..dwQuestID.."的名字")
    end
    return tQuestInfo.szName
end


function RoadChivalrousData.GetSubModules(dwModuleID)
    return m_tModuleInfo[dwModuleID].tSubModuleID
end

function RoadChivalrousData.GetModuleLimitLevel(dwModuleID)
    return m_tModuleInfo[dwModuleID].nLimitLevel
end

function RoadChivalrousData.GetModuleBindingQuest(dwModuleID)
    return m_tModuleInfo[dwModuleID].dwBindingQuestID
end

function RoadChivalrousData.GetSubModuleContainer(dwModuleID)
    return m_tModuleInfo[dwModuleID].tItemID
end

function RoadChivalrousData.QuestHasFinished(dwQuestID)
    local nResult = false
    local player = GetClientPlayer()
	if not player then
		return 
    end
    
    local nState = player.GetQuestState(dwQuestID)
    if nState == 1 then --已完成
        nResult = true
    end
    return nResult
end

function RoadChivalrousData.GetPredecessor(dwSubModuleID)
    if dwSubModuleID == -1 then
        return
    end
    return m_tSubModuleInfo[dwSubModuleID].tPredecessorID
end

function RoadChivalrousData.GetSubModuleQuests(dwSubModuleID)
    return m_tSubModuleInfo[dwSubModuleID].tQuestID
end

function RoadChivalrousData.GetSubModuleBindingQuest(dwSubModuleID)
    return m_tSubModuleInfo[dwSubModuleID].dwBindingQuestID
end

function RoadChivalrousData.GetSubModuleName(dwSubModuleID)
    return m_tSubModuleInfo[dwSubModuleID].szName
end

function RoadChivalrousData.GetSubModuleLimitNumber( dwSubModuleID )
    return m_tSubModuleInfo[dwSubModuleID].nLimitNumber
end

function RoadChivalrousData.GetSubModuleLimitTime(dwSubModuleID)
    return m_tSubModuleInfo[dwSubModuleID].tLimitTime
end

function RoadChivalrousData.GetSubModuleTips(dwSubModuleID)
    return m_tSubModuleInfo[dwSubModuleID].szTip
end

function RoadChivalrousData.GetSubModuleReward(dwSubModuleID)
    return m_tSubModuleInfo[dwSubModuleID].tReward
end

function RoadChivalrousData.SubModuleHasAccept(dwSubModuleID)
    --标识是否已接收子模块，通过子模块的第一个任务的接收状态判断
    local tSubModuleID = self.GetSubModuleQuests(dwSubModuleID)
    -- UILog("submoduleid quest", dwSubModuleID, tSubModuleID)
    local dwQuestID = tSubModuleID[1]
    local player = GetClientPlayer()
	if not player then
		return
    end
    local nPhase = player.GetQuestPhase(dwQuestID)
    return nPhase ~= QUEST_PHASE.ERROR and nPhase ~= QUEST_PHASE.UNACCEPT
end


function RoadChivalrousData.GetModuleState(dwModuleID)
    local nState = ROAD_CHIVALROUS_MODULE_STATE.INCOMPLETED
    local nFinishedSubModuleCount = 0
    local nAllSubModuleCount = 0
    local tSubModules = self.GetSubModules(dwModuleID)
    nAllSubModuleCount = GetTableCount(tSubModules)

    local nLimitLevel = self.GetModuleLimitLevel(dwModuleID)
    local player = GetClientPlayer()
    if player.nLevel < nLimitLevel then
        return ROAD_CHIVALROUS_MODULE_STATE.INACTIVATED, 0, nAllSubModuleCount
    end

    nState = ROAD_CHIVALROUS_MODULE_STATE.INCOMPLETED
    for _, dwSubModuleID in pairs(tSubModules) do
        local nSubModuleStatus = self.GetSubModuleState(dwSubModuleID)
        if nSubModuleStatus == ROAD_CHIVALROUS_SUBMODULE_STATE.COMPLETED_NOT_GOT_REWARDS or nSubModuleStatus == ROAD_CHIVALROUS_SUBMODULE_STATE.COMPLETED_GOT_REWARDS then
            nFinishedSubModuleCount = nFinishedSubModuleCount + 1
        end
    end

    if nFinishedSubModuleCount == nAllSubModuleCount then
        nState = ROAD_CHIVALROUS_MODULE_STATE.COMPLETED_NOT_GOT_FINAL_REWARDS
    end

    local dwQuestID = self.GetModuleBindingQuest(dwModuleID)
    if self.QuestHasFinished(dwQuestID) then
        nState = ROAD_CHIVALROUS_MODULE_STATE.COMPLETED_GOT_FINAL_REWARDS
    end

    return nState, nFinishedSubModuleCount, nAllSubModuleCount
end

-- 1. Inactivated
-- 2. Accepted, Incompleted
-- 3. Completed, Has rewards to get
-- 4. Completed, Got the rewards
function RoadChivalrousData.GetSubModuleState(dwSubModuleID)
    --前置子模块未完成，本模块未激活
    local tPredecessorID = self.GetPredecessor(dwSubModuleID)
    for _, dwPredecessorID in pairs(tPredecessorID) do
        local nState = self.GetSubModuleState(dwPredecessorID)
        if nState == ROAD_CHIVALROUS_SUBMODULE_STATE.INACTIVATED or nState == ROAD_CHIVALROUS_SUBMODULE_STATE.INCOMPLETED then
            return ROAD_CHIVALROUS_SUBMODULE_STATE.INACTIVATED
        end
    end

    --本子模块已激活，未完成
    local tQuests = self.GetSubModuleQuests(dwSubModuleID)
    for _, dwQuestID in pairs(tQuests) do
        local bFinished = self.QuestHasFinished(dwQuestID)
        if not bFinished then
            return ROAD_CHIVALROUS_SUBMODULE_STATE.INCOMPLETED
        end
    end

    --本子模块已完成，已领取奖励，通过任务标识
    local dwQuestID = self.GetSubModuleBindingQuest(dwSubModuleID)
    local player = GetClientPlayer()
	if not player then
		return
    end
    local nQuestState = player.GetQuestState(dwQuestID)
	local nQuestPhase = player.GetQuestPhase(dwQuestID)
	if nQuestState == 1 or nQuestPhase == 2 then
		return ROAD_CHIVALROUS_SUBMODULE_STATE.COMPLETED_GOT_REWARDS
	end

    --本子模块已完成，未领取奖励
    return ROAD_CHIVALROUS_SUBMODULE_STATE.COMPLETED_NOT_GOT_REWARDS
end

function RoadChivalrousData.GetSubModuleInCompletedPressID(dwSubModuleID, tbResID)
    --前置子模块未完成，本模块未激活
    local tPredecessorID = self.GetPredecessor(dwSubModuleID)
    for _, dwPredecessorID in pairs(tPredecessorID) do
        local nState = self.GetSubModuleState(dwPredecessorID)
        if nState == ROAD_CHIVALROUS_SUBMODULE_STATE.INACTIVATED or nState == ROAD_CHIVALROUS_SUBMODULE_STATE.INCOMPLETED then
            table.insert(tbResID, dwPredecessorID)
        end
    end
end


