HomelandPVPData = HomelandPVPData or {className = "HomelandPVPData"}
local self = HomelandPVPData

local LAST_WEEK = 0
local THIS_WEEK = 1
local tWeek = {LAST_WEEK, THIS_WEEK}

function HomelandPVPData.Init()
	self.bIndoor = true
	self.tSuit = {}
	self.tReward = {}
	self.tRewardLevel = {}
	self.ReadTable()

	local nTime = GetCurrentTime()
	for k, v in pairs(self.tSuit) do
		if (nTime >= v.nStartTime and nTime <= v.nEndTime) then
			self.nCurrentSuit = k
			break
		end
	end

	self.tWeekRankList = {}
	for k, nRankType in pairs(tWeek) do
		self.tWeekRankList[nRankType] = {}
		self.tWeekRankList[nRankType].nStart = self.tWeekRankList[nRankType].nStart or 0
		self.tWeekRankList[nRankType].tRankList = {}
	end

	--申请我的成绩
	GetHomelandMgr().ApplyMyHomelandRank(THIS_WEEK)
	GetHomelandMgr().ApplyMyHomelandRank(LAST_WEEK)

	Event.Reg(self, "SYNC_HOMELAND_RANK_LIST", function (nRankType, dwBeginIndex, dwEndIndex)
		self.UpdateRankList(nRankType, dwBeginIndex, dwEndIndex)
	end)
end

function HomelandPVPData.UnInit()
	self.bIndoor 					= nil
	self.tSuit 						= nil
	self.tReward 					= nil
	self.tRewardLevel 				= nil
	self.tWeekRankList 				= nil
	self.nCurrentSuit 				= nil
	self.tFurnitureCatgList 		= nil

	Event.UnRegAll(self)
end

function HomelandPVPData.Set(szName, value)
    self[szName] = value
end

function HomelandPVPData.GetRankPage(nRankType, nChange)
	local dwBeginIndex = self.tWeekRankList[nRankType].nStart + nChange
	GetHLRankList(nRankType, dwBeginIndex, dwBeginIndex + PAGE_COUNT - 1)
end

function HomelandPVPData.ReadTable()
	local nCount = g_tTable.HomelandRewardSuit:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.HomelandRewardSuit:GetRow(i)
		tLine.nStartTime = Time_AddZone(tLine.nStartTime)
		tLine.nEndTime = Time_AddZone(tLine.nEndTime)

		tLine.tRewardList = SplitString(tLine.szRewardList, ";")
		for k, v in pairs(tLine.tRewardList) do
			tLine.tRewardList[k] = tonumber(v)
		end
		self.tSuit[tLine.dwID] = tLine
	end

	local nCount = g_tTable.HomelandReward:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.HomelandReward:GetRow(i)
		self.tReward[tLine.dwID] = tLine
	end

	local nCount = g_tTable.HomelandRewardLevel:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.HomelandRewardLevel:GetRow(i)
		self.tRewardLevel[tLine.dwLevel] = tLine
	end
	self.tFurnitureCatgList = FurnitureData.GetAllCatgInfos()
end

function HomelandPVPData.UpdateRankList(nRankType, dwBeginIndex, dwEndIndex)
	self.tWeekRankList[nRankType].nStart = dwBeginIndex

	local tRankList = {}
    for i = dwBeginIndex, dwEndIndex do
        local tTable = GetHLRankRoleInfo(nRankType, i)
        tRankList[i + 1] = tTable
    end

	for key, value in pairs(tRankList) do
		self.tWeekRankList[nRankType].tRankList[key] = value
	end
end

function HomelandPVPData.CalculationScore(t)
	local nScore = 0
	for i = 1, 5 do
		nScore = nScore + (t["dwAttribute" .. i] or 0)
	end
	return nScore
end

function HomelandPVPData.GetRewardLevel(nIndex, nInfo)
	if nIndex ~= 0 then
		return g_tTable.HomelandRewardLevel:Search(1)
	end
	if nInfo == 0 then
		return g_tTable.HomelandRewardLevel:Search(0)
	end
	for k, v in pairs(HomelandPVPData.tRewardLevel) do
		if nInfo > v.nMinPercentage and nInfo <= v.nMaxPercentage then
			return v
		end
	end
end

function HomelandPVPData.GetHLRankList(nRankType, dwBeginIndex, dwEndIndex)
	if dwEndIndex - dwBeginIndex > 10 then
		local nNewEndIndex = -1
		for i = dwBeginIndex - 1, dwEndIndex, 10 do
			nNewEndIndex = math.min(dwEndIndex, i + 10)
			if i + 1 > nNewEndIndex then
				return
			end
			GetHLRankList(nRankType, i + 1, nNewEndIndex)
		end
	else
		GetHLRankList(nRankType, dwBeginIndex, dwEndIndex)
	end
end