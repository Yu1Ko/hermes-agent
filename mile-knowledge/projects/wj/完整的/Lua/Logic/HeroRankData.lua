-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: HeroRankData
-- Date: 2024-09-19 09:56:06
-- Desc: ?
-- ---------------------------------------------------------------------------------

HeroRankData = HeroRankData or {className = "HeroRankData"}
-------------------------------- 消息定义 --------------------------------
HeroRankData.Event = {}
HeroRankData.Event.XXX = "HeroRankData.Msg.XXX"

HeroRankData =
{
	---- 逻辑数据
	aWulinShenghuiDuizhenbiao =
	{
		--- [nPhase] = {{<参赛者ID列表>}, {<对应的参赛者比赛状态的列表>}},
	},

	aAllLayerContestStates =
	{
		---[nLayer] = {<从左起每个控件对应的比赛状态>},
	},

	nCurContestPhase = 0,

	---- 逻辑常量
	SPECIAL_PHASE = 3, --- 这一阶段是特殊的，它与上一阶段在同一层
	TOTAL_PHASE = 6,
	SPECIAL_LAYER = 2, --- 这一层是特殊的，它对应了两个阶段
	TOTAL_LAYER = 5,

	---- UI数据

	---- UI常量
	tNPC_CONTEST_STATE =
	{
		UNKNOWN = 1,
		NOT_MATCHED = 2,
		WON = 3,
		LOST = 4,
	},

	tLINE_STATE =
	{
		GRAY = 1,
		LEFT_WIN = 2,
		RIGHT_WIN = 3,
	},

}

HeroRankData.tLineState2ImgName =
{
	[HeroRankData.tLINE_STATE.GRAY] = "Gray",
	[HeroRankData.tLINE_STATE.LEFT_WIN] = "Left",
	[HeroRankData.tLINE_STATE.RIGHT_WIN] = "Right",
}

HeroRankData.tNpcContestState2ImgName =
{
	[HeroRankData.tNPC_CONTEST_STATE.UNKNOWN] = "Unknown",
	[HeroRankData.tNPC_CONTEST_STATE.NOT_MATCHED] = "NotMatched",
	[HeroRankData.tNPC_CONTEST_STATE.WON] = "Won",
	[HeroRankData.tNPC_CONTEST_STATE.LOST] = "Lost",
}

local self = HeroRankData

function HeroRankData.Init(nContestPhase)
    assert(nContestPhase >= 1 and nContestPhase <= self.TOTAL_PHASE)

	self.nCurContestPhase = nContestPhase
	self.aWulinShenghuiDuizhenbiao = {}
	self.aAllLayerContestStates = {}

	local aAllPhaseNpcList = {}

	for i = 1, nContestPhase do
		local aNpcList = UIscript_GetWulinShenghuiDuizhenInfoByPhase(i)
		if aNpcList == nil then
			LOG.INFO("ERROR！传入的武林盛会阶段(" .. nContestPhase .. ")太大！")
			break
		end

		aAllPhaseNpcList[i] = aNpcList
	end

	for j = 1, nContestPhase do
		self.aWulinShenghuiDuizhenbiao[j] = {{}, {}}
		for _, dwNpcID in ipairs(aAllPhaseNpcList[j]) do
			table.insert(self.aWulinShenghuiDuizhenbiao[j][1], dwNpcID)
			table.insert(self.aWulinShenghuiDuizhenbiao[j][2], self.GetNpcContestState(dwNpcID, j, aAllPhaseNpcList))
		end
	end
end

function HeroRankData.GetNpcContestState(dwNpcID, nPhase, aAllPhaseNpcList)
	assert(nPhase <= self.nCurContestPhase)

	if dwNpcID == 0 then
		return self.tNPC_CONTEST_STATE.UNKNOWN
	end

	if self.nCurContestPhase == 1 then
		return self.tNPC_CONTEST_STATE.NOT_MATCHED
	else
		local aCompleteNpcList = aAllPhaseNpcList[1]
		if self.nCurContestPhase == self.SPECIAL_PHASE - 1 then
			local aWinnerNpcs = aAllPhaseNpcList[self.SPECIAL_PHASE - 1]
			local aMatchedNpcs = {}
			for _, dwTheNpcID in ipairs(aWinnerNpcs) do
				local nOrigNpcIndex = FindTableValue(aCompleteNpcList, dwTheNpcID)
				assert(nOrigNpcIndex)
				local dwOpponentNpcID = aCompleteNpcList[(nOrigNpcIndex % 2 == 1) and (nOrigNpcIndex + 1) or (nOrigNpcIndex - 1)]

				table.insert(aMatchedNpcs, dwTheNpcID)
				table.insert(aMatchedNpcs, dwOpponentNpcID)
			end

			if CheckIsInTable(aMatchedNpcs, dwNpcID) then
				if nPhase == self.nCurContestPhase then
					return self.tNPC_CONTEST_STATE.NOT_MATCHED
				else
					if CheckIsInTable(aWinnerNpcs, dwNpcID) then
						return self.tNPC_CONTEST_STATE.WON
					else
						return self.tNPC_CONTEST_STATE.LOST
					end
				end
			else
				return self.tNPC_CONTEST_STATE.NOT_MATCHED
			end
		elseif self.nCurContestPhase == self.SPECIAL_PHASE then
			if nPhase == self.SPECIAL_PHASE or nPhase == self.SPECIAL_PHASE - 1 then
				return self.tNPC_CONTEST_STATE.NOT_MATCHED
			else
				if CheckIsInTable(aAllPhaseNpcList[self.SPECIAL_PHASE], dwNpcID)
						or CheckIsInTable(aAllPhaseNpcList[self.SPECIAL_PHASE - 1], dwNpcID) then
					return self.tNPC_CONTEST_STATE.WON
				else
					return self.tNPC_CONTEST_STATE.LOST
				end
			end
		else
			if nPhase == self.nCurContestPhase then
				if nPhase == self.TOTAL_PHASE then
					return self.tNPC_CONTEST_STATE.WON
				else
					return self.tNPC_CONTEST_STATE.NOT_MATCHED
				end
			else
				local bWinner = false
				if nPhase == 1 then
					bWinner = CheckIsInTable(aAllPhaseNpcList[self.SPECIAL_PHASE], dwNpcID) or CheckIsInTable(aAllPhaseNpcList[self.SPECIAL_PHASE - 1], dwNpcID)
				elseif nPhase == self.SPECIAL_PHASE - 1 then
					bWinner = CheckIsInTable(aAllPhaseNpcList[self.SPECIAL_PHASE + 1], dwNpcID)
				else
					bWinner = CheckIsInTable(aAllPhaseNpcList[nPhase + 1], dwNpcID)
				end

				if bWinner then
					return self.tNPC_CONTEST_STATE.WON
				else
					return self.tNPC_CONTEST_STATE.LOST
				end
			end
		end
	end
end

function HeroRankData.GetLayerByPhase(nPhase) --- 比赛阶段数转化为对阵表层数
	local nLayer
	if nPhase >= self.SPECIAL_PHASE then
		nLayer = nPhase - 1
	else
		nLayer = nPhase
	end
	return nLayer
end

--- 返回对应NPC在nPhase所对应的那一层里的UI控件的序号
function HeroRankData.GetNpcUIIndexInLayer(dwNpcID, nPhase)
	local nNpcUIIndex
	if nPhase == HeroRankData.SPECIAL_PHASE or nPhase == HeroRankData.SPECIAL_PHASE - 1 then --- 特殊处理
		nNpcUIIndex = math.ceil(FindTableValue(HeroRankData.aWulinShenghuiDuizhenbiao[1][1], dwNpcID) / 2)
	else
		nNpcUIIndex = FindTableValue(HeroRankData.aWulinShenghuiDuizhenbiao[nPhase][1], dwNpcID)
	end

	return nNpcUIIndex
end