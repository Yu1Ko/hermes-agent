

HeadEmotionData = HeadEmotionData or {className = "HeadEmotionData"}
local self = HeadEmotionData
-------------------------------------------------------------------------
-- 头顶表情
-------------------------------------------------------------------------
local _tHeadEmotionMap 	= {} --id为索引 HeadEmotion表
local _tAllHeadEmotions = {} --type为索引
local _tEmotionType = {}
local _tLikeEmotion = {}
local MAX_COLLECTION_COUNT = 8 --收藏上限
local nMaxFaviEmotionNum = 5
local REMOTE_PREFER_BRIGHTMARK = 1169
local PREFER_BM_REMOTE_DATA_START = 0
local PREFER_BM_REMOTE_DATA_END = 14
local PREFER_BM_REMOTE_DATA_LEN = 2

Event.Reg(self, "FIRST_LOADING_END", function()
	HeadEmotionData.Init()
end)

function HeadEmotionData.Init()
	_tHeadEmotionMap 	= {}
	_tAllHeadEmotions = {}
	_tEmotionType = {}
	_tLikeEmotion = {}

	for i, tLine in ilines(g_tTable.BrightMarkIcon) do
		_tHeadEmotionMap[tLine.dwID] = tLine
		if not _tEmotionType[tLine.nPageID] then
			_tEmotionType[tLine.nPageID] = false
		end
		-- if tLine.bShow then
			if not _tAllHeadEmotions[tLine.nPageID] then
				_tAllHeadEmotions[tLine.nPageID] = {}
			end
			table.insert(_tAllHeadEmotions[tLine.nPageID], tLine)
		-- end
	end

	for nType, _ in pairs(_tEmotionType) do
		if not _tAllHeadEmotions[nType] then
			_tEmotionType[nType] = true
			fakeData = {}
			fakeData.nPageID = nType
			_tAllHeadEmotions[nType] = {}
			table.insert(_tAllHeadEmotions[nType], fakeData)
		end
	end

	self:OnHeadEmotionUpdate()
	self:RegEvent()
end

function HeadEmotionData.UnInit()
	_tHeadEmotionMap    = {}
	_tAllHeadEmotions   = {}
	_tLikeEmotion = {}
end

function HeadEmotionData.OnLogin()

end

function HeadEmotionData.RegEvent()
	Event.Reg(self, "ON_OPERATE_BRIGHT_MARK_NOTIFY", function ()
		self:OnHeadEmotionUpdate()
	end)
end

---get function

function HeadEmotionData.GetHeadEmotion(szKey)
	if szKey then
		return _tHeadEmotionMap[szKey]
	else
		return  _tAllHeadEmotions
	end
end

function HeadEmotionData.GetHeadEmotionPackage(nType)
	if nType then
		local tShowData = {}
		for _, tLine in ipairs(_tAllHeadEmotions[nType]) do
            if tLine.bShow then
				table.insert(tShowData, tLine)
			else
				if GetClientPlayer().IsHaveBrightMark(tLine.dwID) then
					table.insert(tShowData, tLine)
				end
			end
        end
		return tShowData
	else
		return _tAllHeadEmotions
	end
end

function HeadEmotionData.GetFaviHeadEmotions()
	return GetClientPlayer().GetMobileHeadEmotionDIYList() or {}
end

---judge funtion

function HeadEmotionData.IsFaviHeadEmotion(dwID)
	local bFavi = false
	local tFaviEmotionActions = self:GetFaviHeadEmotions()
	if dwID then
		for _, id in ipairs(tFaviEmotionActions) do
			if dwID == id then
				bFavi = true
				break
			end
		end
	end
	return bFavi
end

function HeadEmotionData.IsFaviEmotionActionbFull()
	local tFaviEmotionActions = GetClientPlayer().GetMobileHeadEmotionDIYList() or {}
	if #tFaviEmotionActions < nMaxFaviEmotionNum then
		return false
	else
		return true
	end
end

---
function HeadEmotionData.OnHeadEmotionUpdate()
	local function fnBDegree(a, b)
		local bIsNewA = RedpointHelper.BrightMark_IsNew(a.dwID)
		local bIsNewB = RedpointHelper.BrightMark_IsNew(b.dwID)
		if bIsNewA ~= bIsNewB then
			return bIsNewA
		end

		if a.bLearned and b.bLearned then
			return a.dwID < b.dwID
		elseif a.bLearned then
			return true
		elseif b.bLearned then
			return false
		else
			return a.dwID < b.dwID
		end
	end

	local function fnCDegree(a, b)
		local nA, nB
		for _, tLine in pairs(a) do
			nA = tLine.nPageID
			break
		end
		for _, tLine in pairs(b) do
			nB = tLine.nPageID
			break
		end
		return nA < nB
	end

	local pPlayer = GetClientPlayer()
	if not pPlayer then
		return
	end

	table.sort(_tAllHeadEmotions, fnCDegree)
	for k, tHeadEmotionPage in pairs(_tAllHeadEmotions) do
		for _, tLine in pairs(tHeadEmotionPage) do
			tLine.bLearned = pPlayer.IsHaveBrightMark(tLine.dwID)
		end
		table.sort(tHeadEmotionPage, fnBDegree)
	end
end

function HeadEmotionData.ProcessHeadEmotion(dwID)
	local pPlayer = GetClientPlayer()
	if not pPlayer then
		return
	end
	pPlayer.PlayBrightMark(dwID)
end

function HeadEmotionData.GetTypeIsHave()
	return _tEmotionType
end

-- 头顶表情收藏

function HeadEmotionData.UpdateHeadEmotionCollectData()

	local pPlayer = GetClientPlayer()
	if not pPlayer then
		return
	end

	local dwPlayerID = pPlayer.dwID
	if IsRemotePlayer(dwPlayerID) then
		return
	end

	if not pPlayer.HaveRemoteData(REMOTE_PREFER_BRIGHTMARK) then
		pPlayer.ApplyRemoteData(REMOTE_PREFER_BRIGHTMARK)
		return
	end

	local tCollection = {}
	for i = PREFER_BM_REMOTE_DATA_START, PREFER_BM_REMOTE_DATA_END, PREFER_BM_REMOTE_DATA_LEN do
		local dwBrightMarkID = pPlayer.GetRemoteArrayUInt(REMOTE_PREFER_BRIGHTMARK, i, PREFER_BM_REMOTE_DATA_LEN)
		if dwBrightMarkID and dwBrightMarkID ~= 0 then
			tCollection[dwBrightMarkID] = true
		end
	end
	_tLikeEmotion = tCollection
	return _tLikeEmotion
end

function HeadEmotionData.IsLikeHeadEmotion(dwID)
	local bCollect = _tLikeEmotion and _tLikeEmotion[dwID]
    return bCollect
end

function HeadEmotionData.IsLikeHeadEmotionbFull()
	if #_tLikeEmotion < MAX_COLLECTION_COUNT then
		return false
	else
		return true
	end
end