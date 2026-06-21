-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: CollectionDailyData
-- Date: 2026-03-31 19:56:33
-- Desc: 周末及日常相关逻辑数据层
-- ---------------------------------------------------------------------------------

CollectionDailyData = CollectionDailyData or {className = "CollectionDailyData"}
local self = CollectionDailyData

local WEEKLIMIT = 5
local RANK_COUNT = 3
local SHOW_DAILY_LEVEL = 120

local CLASS_MODE = {
    DAILY    = 1, --日课
    WEEK     = 2, --周课
}

local tClassOrder = {
    [1] = 1,
    [6] = 2,
    [3] = 3,
    [2] = 4,
    [4] = 5,
    [7] = 6,
    [5] = 7,
}

function CollectionDailyData.Init()
    Event.Reg(self, "LOADING_END", function()
		RemoteCallToServer("On_Daily_AllInfo")
	end)

    Event.Reg(self, "OnClientPlayerLeave", function()
		self.UnInit()
	end)
end

function CollectionDailyData.InitData()
    RemoteCallToServer("On_Daily_AllInfo")
    local tGetRewardLv, tReachLv = GDAPI_DXZLGetAllState() --周课的可领奖档由活跃天数推导（下发的0）
    self.tReachLv = tReachLv or {}
    self.tGetRewardLv = tGetRewardLv or {}
    
    local tQuestList = GDAPI_DXZLGetDailyQuestList()
    self.tQuestList = tQuestList or {}
    
    self.dwSelectID = 0  --选中的任务ID
    self.tDailyQuest = Table_GetDailyQuestInfo() 
    
    local tDailyReward, _, nNextWeekGiftID, nNextWeekGiftType = GDAPI_DXZLGetRewardConfig()
    self.tDailyReward = tDailyReward
    self.nNextWeekGiftID = nNextWeekGiftID
    self.nNextWeekGiftType = nNextWeekGiftType

    self.tWeekReward = GDAPI_DXZLGetWeeklyRewardInfo()
    
    local nDays, nCan, nClaimed = GDAPI_DXZLGetWeeklyNextWeekState() 
    self.bCan = nCan > 0
    self.bClaimed = nClaimed > 0
    self.tReachLv[CLASS_MODE.WEEK] = math.min(nDays or 0, WEEKLIMIT)
    
    self.UpdateRankInfo()
end

function CollectionDailyData.UpdateRankInfo()
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
    local nCount = math.min(RANK_COUNT, #tRankInfo)
    local tRankList = {}
    for i = 1, nCount do
        tRankList[i] = tRankInfo[i]
    end
    self.tRankList = tRankList
end

function CollectionDailyData.UpdateWeekly(nPoint, nGetRewardLv)
    local nDays = math.floor(nPoint / 100)
    self.tReachLv = self.tReachLv or {}
    self.tGetRewardLv = self.tGetRewardLv or {}
    self.tReachLv[CLASS_MODE.WEEK] = math.min(nDays, WEEKLIMIT) --可领取的周课档
    self.tGetRewardLv[CLASS_MODE.WEEK] = nGetRewardLv
end

function CollectionDailyData.UpdateNextWeek(nCan, nClaimed) --（0/1）是否可领 (0/1)是否已领
    self.bCan = nCan > 0
    self.bClaimed = nClaimed > 0
end

function CollectionDailyData.Update(tQuestList, nGetRewardLv, nReachLv, dwRewardIndex)
    self.tQuestList = tQuestList
    self.tReachLv = self.tReachLv or {}
    self.tGetRewardLv = self.tGetRewardLv or {}
    self.tReachLv[CLASS_MODE.DAILY] = nReachLv
    self.tGetRewardLv[CLASS_MODE.DAILY] = nGetRewardLv
    self.dwRewardIndex = dwRewardIndex
end

function CollectionDailyData.UpdateSingleDailyInfo(nPos, tQuestInfo, nGetRewardLv, nReachLv)
    if not self.tQuestList or not nPos or not self.tQuestList[nPos] then
        return
    end
    self.tReachLv[CLASS_MODE.DAILY] = nReachLv
    self.tGetRewardLv[CLASS_MODE.DAILY] = nGetRewardLv
    self.tQuestList[nPos] = tQuestInfo
end

function CollectionDailyData.IsQuestFinish(dwID)
    if not self.tQuestList then return false end
    for _, v in pairs(self.tQuestList) do
        if dwID == v[1] then
            return v[2]
        end
    end
    return false
end

function CollectionDailyData.GetDailyQuestInfo(dwID)
    if not self.tDailyQuest then return nil end
    for _, v in pairs(self.tDailyQuest) do
        if dwID == v.dwID then
            return v
        end
    end
    return nil
end

function CollectionDailyData.UnInit()
    self.tReachLv = nil
    self.tGetRewardLv = nil
    self.tQuestList = nil
    self.dwSelectID = 0
    self.tDailyQuest = nil
    self.tDailyReward = nil
    self.nNextWeekGiftID = nil
    self.nNextWeekGiftType = nil
    self.tWeekReward = nil
    self.bCan = false
    self.bClaimed = false
end

function CollectionDailyData.OnLogin()
    
end

function CollectionDailyData.OnFirstLoadEnd()
    
end

function CollectionDailyData.GetQuestList()
	return self.tQuestList
end

function CollectionDailyData.GetRankList()
    return self.tRankList
end

function CollectionDailyData.GetReachLv()
    return self.tReachLv
end

function CollectionDailyData.GetGetRewardLv()
    return self.tGetRewardLv
end

function CollectionDailyData.GetDailyQuestReward(nLevel)
    for _, v in pairs(self.tDailyReward) do
		if nLevel == v.nLevel then
			return v.szReward
		end
	end
end

function CollectionDailyData.GetWeekQuestReward(nLevel)
    for _, v in pairs(self.tWeekReward) do
		if nLevel == v.nLevel then
			return v
		end
	end
end

function CollectionDailyData.GetNextWeekState()
    return self.bCan, self.bClaimed
end

function CollectionDailyData.CanGetReward()
	local hPlayer = GetClientPlayer()
	if hPlayer and hPlayer.nLevel < SHOW_DAILY_LEVEL then
		return false
	end
	if not self.tGetRewardLv or not self.tReachLv then
		return false
	end

    if not IsNil(self.tReachLv[CLASS_MODE.DAILY]) then
        if self.tGetRewardLv[CLASS_MODE.DAILY] < self.tReachLv[CLASS_MODE.DAILY] then
            return true
        end
    end

    return false
end

function CollectionDailyData.CanGetWeekReward()
	local hPlayer = GetClientPlayer()
	if hPlayer and hPlayer.nLevel < SHOW_DAILY_LEVEL then
		return false
	end
	if not self.tGetRewardLv or not self.tReachLv then
		return false
	end

    if not IsNil(self.tReachLv[CLASS_MODE.WEEK]) then
        if self.tGetRewardLv[CLASS_MODE.WEEK] < self.tReachLv[CLASS_MODE.WEEK] then
            return true
        end
    end

    return false
end

function CollectionDailyData.GetDailyQuestFinishCount()
	local nCount = 0
	local nTotal = 5
	if not self.tQuestList then return nCount, nTotal end
	for nIndex, tbInfo in ipairs(self.tQuestList) do
		if tbInfo[2] then
			nCount = nCount + 1
		end
	end
	return nCount, nTotal
end

function CollectionDailyData.GetNextWeekRewardItem()
    local nNextWeekGiftID, nNextWeekGiftType = self.nNextWeekGiftID, self.nNextWeekGiftType
    if not nNextWeekGiftID or not nNextWeekGiftType then
        local tDailyReward, _, nNextWeekGiftID, nNextWeekGiftType = GDAPI_DXZLGetRewardConfig()
        self.nNextWeekGiftID = nNextWeekGiftID
        self.nNextWeekGiftType = nNextWeekGiftType
    end
    return self.nNextWeekGiftID, self.nNextWeekGiftType
end

function CollectionDailyData.GetQuestInfoByID(dwID)
	return self.tDailyQuest[dwID]
end