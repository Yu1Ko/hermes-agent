-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomeCollectionPage
-- Date: 2023-08-02 17:21:29
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomeCollectionPage = class("UIHomeCollectionPage")
------------------------------ 数据模块 ------------------------------
------------------------------ 数据定义
local ARCHITECTURE_INDEX = 1
local COIN_INDEX = 2
local DEFAULT_INDEX = 0
local BUY_CD = 10
local START_HIDE_SCALE = 0.084
local _MAX_LIKED_SETS_IN_DLC = 8
local colorRed = cc.c3b(255, 133, 125)
local colorWhite = cc.c3b(255, 255, 255)

local tbFiliter = {
	-- 家具来源
	[1] =
	{
			[1] = "大水南方令" ,
			[2] = "园宅币" ,
			[3] = "节日活动" ,
			[4] = "商城" ,
			[5] = "其他" ,
	},

	-- 收集状态
	[2] =
	{
		[1] = SET_COLLECTION_STATE_TYPE.COLLECTED ,
		[2] = SET_COLLECTION_STATE_TYPE.TO_AWARD ,
		[3] = SET_COLLECTION_STATE_TYPE.COLLECTING ,
		[4] = SET_COLLECTION_STATE_TYPE.UNCOLLECTED ,
	},

	-- 难度
	[3] =
	{
		[1] = 1 ,
		[2] = 2 ,
		[3] = 3 ,
		[4] = 4 ,
	},
}

--[[
	当前置顶的套装ID列表（每个DLC最多 _MAX_LIKED_SETS 个）；
	后加的添加在末尾，排序时优先级从后往前
--]]

UIHomeCollectionPage.aLikedSets = {}
-- RegisterCustomData("UIHomeCollectionPage.aLikedSets")

local DataModel =
{
	---- 逻辑数据

	---- UI数据
	bInitted = false,

	aDlcs = {},

	tDlcSetInfo =
	{
	--[[
		[nDlcID] =
		{
			{dwSetID=dwSetID, szName=szName, szImgPath=szImgPath, nStars=nStars, nAchievePts=100,},
			...
		},
	--]]
	},

	tAllFurnitureSetInfo =
	{
	--[[
		[dwSetID] =
		{
			{ID=dwFurnitureID, SetIndex=nSetIndex},
			...
		},
	--]]
	},

	aCanGetRewardSetIDs = {},

	aSetSources = {}, -- 初始化时填充
	szFilteredSource = nil,
	eFilteredCollectState = nil,
	nFilteredStars = nil,

	szSearchKeyword = nil,

	bInBatchBuyMode = false,
	szBatchBuyMode = "",
	nTotalRequiredArchitecture = 0,
	nTotalRequiredCoin = 0,

	bInGetRewardCD = false,

	-- ↓↓ 控件相关
	hImgStarMode = nil,
	hHndlOneSetRewardItemMode = nil,
	hHndlOneNoticeRewardMode = nil,
	hLastSelectedCBoxDLC = nil,
	hLastSelectedCBoxSet = nil,

	nSingleBuyOrigRelY = nil,

	-- ↑↑ 控件相关

	-- 测试相关
	bTestEnabled = false,

	---- UI常量
	MAX_COLLECT_POINTS = 0,
	MAX_SET_STARS = 4,
	--- 界面控件样式相关
	_DLC_MORE_IMG_PATH = "ui/Image/UICommon/Achievement1.UITex",

	-- 购买CD
	bOnBuyFurniture = false,
	nCooldownBuyTime = 0,
	nLastFreshBuyTime = 0,
}

Event.Reg(DataModel, "HOME_LAND_RESULT_CODE_INT", function ()
	if arg0 == HOMELAND_RESULT_CODE.BUY_FURNITURE_SUCCEED
		or arg0 == HOMELAND_RESULT_CODE.FURNITURE_NOT_COLLECT then
		DataModel.OnBuyFurniture(false)
		DataModel.UpdateBuyFresh()
	end
end)

Event.Reg(DataModel, "LUA_HOMELAND_BUY_FURNITURE_END", function()
	DataModel.OnBuyFurniture(false)
	DataModel.UpdateBuyFresh()
end)

------------------------------ 数据相关函数
function DataModel.InitMaxCollectPoints()
	local tUiTable = Table_GetAllFurnitureSetCollectPointsLevelInfo()
	local nRowCount = tUiTable:GetRowCount()
	local tLastLine = tUiTable:GetRow(nRowCount)
	DataModel.MAX_COLLECT_POINTS = tLastLine.nDestPtsToNextLevel
end

function DataModel.InitAllDlcFurnitureSetInfo()
	DataModel.aDlcs = {}
	DataModel.tDlcSetInfo = {}
	DataModel.aSetSources = {}
	local tOrigTable = Table_GetAllFurnitureSetInfo()
	local nRowCount = tOrigTable:GetRowCount()
	local tLine, tInfo
	local nDlcID, dwSetID, szName, szImgPath, nStars
	local nAchieveTrigVal, nAchievePts, szSource

	for i = 2, nRowCount do
		tLine = tOrigTable:GetRow(i)
		nDlcID = tLine.nDlcID

		if not CheckIsInTable(DataModel.aDlcs, nDlcID) then
			table.insert(DataModel.aDlcs, nDlcID)
		end

		tInfo = clone(tLine)
		nAchieveTrigVal, nAchievePts = Table_GetAchievementInfo(tInfo.dwAchievementID)
		tInfo.nAchievePts = nAchievePts or 0
		tInfo.nUiIndex = i - 1
		tInfo.nDlcID = nil
		tInfo.dwAchievementID = nil

		DataModel.tDlcSetInfo[nDlcID] = DataModel.tDlcSetInfo[nDlcID] or {}
		table.insert(DataModel.tDlcSetInfo[nDlcID], tInfo)

		szSource = UIHelper.GBKToUTF8(tLine.szSource)
		_G.AppendWhenNotExist(DataModel.aSetSources, szSource)
	end

	local nOtherPos = _G.FindTableValue(DataModel.aSetSources, g_tStrings.STR_HOMELAND_FURNITURE_SET_FILTER_SOURCE_OTHER)
	if nOtherPos and nOtherPos ~= #DataModel.aSetSources then
		table.remove(DataModel.aSetSources, nOtherPos)
		table.insert(DataModel.aSetSources, g_tStrings.STR_HOMELAND_FURNITURE_SET_FILTER_SOURCE_OTHER)
	end
end

function DataModel.GetSetInfoByDlc(nDlcID)
	return DataModel.tDlcSetInfo[nDlcID]
end

function DataModel.GetSortedSetInfosByDlc(nDlcID)
	local aSetInfos = clone(DataModel.GetSetInfoByDlc(nDlcID))
	local _fnCmp = function(tL, tR)
		if tL == tR then
			return false
		end

		local nLikedIndexL = _G.FindTableValue(UIHomeCollectionPage.aLikedSets, tL.dwSetID)
		local nLikedIndexR = _G.FindTableValue(UIHomeCollectionPage.aLikedSets, tR.dwSetID)
		if nLikedIndexL and nLikedIndexR then
			return nLikedIndexL > nLikedIndexR
		elseif nLikedIndexL then
			return true
		elseif nLikedIndexR then
			return false
		else
			return tL.nUiIndex < tR.nUiIndex
		end
	end

	table.sort(aSetInfos, _fnCmp)
	return aSetInfos
end

function DataModel.GetCollectionProgressInDlc(nDlcID)
	local aSetInfosInDlc = DataModel.GetSetInfoByDlc(nDlcID)
	local player = GetClientPlayer()
	local nFinishedCnt = 0
	local tSetInfo
	for _, t in ipairs(aSetInfosInDlc) do
		tSetInfo = player.GetSetCollection(t.dwSetID)
		if tSetInfo.eType == SET_COLLECTION_STATE_TYPE.COLLECTED or tSetInfo.eType == SET_COLLECTION_STATE_TYPE.TO_AWARD then
			nFinishedCnt = nFinishedCnt + 1
		end
	end
	return nFinishedCnt, #aSetInfosInDlc
end

function DataModel.InitAllFurnitureSetInfo()
	DataModel.tAllFurnitureSetInfo = {}
	local pHlMgr = GetHomelandMgr()
	local tOrigUITable = Table_GetTableHomelandFurnitureInfo()
	local nRowCount = tOrigUITable:GetRowCount()
	local nFurnitureType, dwFurnitureID, tLogicInfo
	local dwSetID, nSetIndex
	for i = 2, nRowCount do
		local tLine = tOrigUITable:GetRow(i)
		nFurnitureType = tLine.nFurnitureType
		dwFurnitureID = tLine.dwFurnitureID
		if GDAPI_IsFurnitureSetShow(nFurnitureType, dwFurnitureID) then
			if nFurnitureType == HS_FURNITURE_TYPE.FURNITURE then
				tLogicInfo = pHlMgr.GetFurnitureConfig(dwFurnitureID)
				if tLogicInfo then
					dwSetID = tLogicInfo.nSetID
					nSetIndex = tLogicInfo.nSetIndex
					if dwSetID > 0 then -- 0表示无效值
						DataModel.tAllFurnitureSetInfo[dwSetID] = DataModel.tAllFurnitureSetInfo[dwSetID] or {}
						table.insert(DataModel.tAllFurnitureSetInfo[dwSetID], {ID=dwFurnitureID, SetIndex=nSetIndex})
					end
				end
			end
		end
	end

	for dwSetID, t in pairs(DataModel.tAllFurnitureSetInfo) do
		table.sort(t, function(tL, tR) return tL.SetIndex < tR.SetIndex end)

		-- 测试用
		--[[
		Log("=== 套装 [" .. dwSetID .. "]的家具信息：")
		for i = 1, math.min(7, #t) do
			UILog_Dev(t[i])
		end
		--]]
	end
end

function DataModel.GetAllFurnitureSetInfo(dwSetID)
	return DataModel.tAllFurnitureSetInfo[dwSetID]
end


function DataModel.Init()
	DataModel.InitMaxCollectPoints()
	DataModel.InitAllDlcFurnitureSetInfo()
	DataModel.InitAllFurnitureSetInfo()
	DataModel.UpdateAndGetAllCanGetRewardSetInfo(true)
	DataModel.bInitted = true

	RemoteCallToServer("On_HomeLand_GetSeasonPoints")
end

function DataModel.UnInit()
	DataModel.bInitted = false
	DataModel.aDlcs = nil
	DataModel.tDlcSetInfo = nil
	DataModel.tAllFurnitureSetInfo = nil
	DataModel.aCanGetRewardSetIDs = nil
	DataModel.hImgStarMode = nil
	DataModel.hHndlOneSetRewardItemMode = nil
	DataModel.hHndlOneNoticeRewardMode = nil
	DataModel.hLastSelectedCBoxDLC = nil
	DataModel.hLastSelectedCBoxSet = nil
	DataModel.nSingleBuyOrigRelY = nil

	DataModel.szSearchKeyword = nil
	DataModel.szFilteredSource = nil
	DataModel.eFilteredCollectState = nil
	DataModel.nFilteredStars = nil
	DataModel.bInBatchBuyMode = false
	DataModel.szBatchBuyMode = ""
	DataModel.nTotalRequiredArchitecture = 0
	DataModel.nTotalRequiredCoin = 0
	DataModel.bInGetRewardCD = false
	--DataModel.bTestEnabled = false
end

local nTestTotalPoints = nil
function DataModel.GetTotalCollectPoints()
	return nTestTotalPoints or GetClientPlayer().GetRemoteDWordArray(1076, 0)
end

--[[
	返回值：
	当前收藏分等级+收藏分在当前等级的超出分数+当前等级升级所需分数
--]]
function DataModel.GetLevelValuesByTotalCollectPoints(nTotalCollectPoints)
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

function DataModel.GetAllCollectPointsLevelAwardInfos()
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

--[[
	返回值：
	1. 套装收集状态（SET_COLLECTION_STATE_TYPE.COLLECTED/TO_AWARD/COLLECTING/UNCOLLECTED）
	2+3. 该套装的总体收集进度（X, Y）
--]]
function DataModel.GetSetBriefCollectProgress(dwSetID)
	--Log("==== 调用了函数 DataModel.GetSetBriefCollectProgress()，参数： " .. tostring(dwSetID))
	local tInfo = GetClientPlayer().GetSetCollection(dwSetID)
	local eCollectType = tInfo.eType
	local aSetIndicesCollectStates = tInfo.tSetUnit
	local nCollectedNum = 0
	for _, value in ipairs(aSetIndicesCollectStates) do
		if value == 1 then
			nCollectedNum = nCollectedNum + 1
		end
	end
	return eCollectType, nCollectedNum, #aSetIndicesCollectStates
end

function DataModel.GetSetCollectPoints(dwSetID)
	local tConfig = GetSetCollectionConfig(dwSetID)
	return tConfig and tConfig.dwCustomAwardData1 or 0
end

function DataModel.GetSeasonFurniturePoints(dwSetID)
	local tConfig = GetSetCollectionConfig(dwSetID)
	return tConfig and tConfig.dwCustomAwardData2 or 0
end

--[[
	返回值：
	1. 套装收集状态（SET_COLLECTION_STATE_TYPE.COLLECTED/TO_AWARD/COLLECTING/UNCOLLECTED）
	2. 收集完成时间
	3. 该套装各家具的收集状态（套装收集状态为 SET_COLLECTION_STATE_TYPE.COLLECTING 时才存在；顺序与
	   tAllFurnitureSetInfo 中对应数据的顺序相一致；值为布尔值）
--]]
function DataModel.GetSetDetailedCollectProgress(dwSetID)
	if not dwSetID or dwSetID <= 0 then
		return
	end

	local player = PlayerData.GetClientPlayer()
	if not player then
		return
	end

	local tInfo = player.GetSetCollection(dwSetID)
	if not tInfo then
		return
	end

	local eCollectType = tInfo.eType
	local dwFinishTime = tInfo.nTime -- 收集完成（非领奖）的时间
	local aSetIndicesCollectStates = tInfo.tSetUnit
	local aFurnitureCollectStates = {}
	--if eCollectType == SET_COLLECTION_STATE_TYPE.COLLECTING then
		local aFurnitureInfos = DataModel.GetAllFurnitureSetInfo(dwSetID)
		local nSetIndex
		for nInd, t in ipairs(aFurnitureInfos) do
			nSetIndex = t.SetIndex
			table.insert(aFurnitureCollectStates, aSetIndicesCollectStates[nSetIndex] == 1)
		end

		return eCollectType, dwFinishTime, aFurnitureCollectStates
	--else
	--	return eCollectType, dwFinishTime
	--end
end


function DataModel.GetTotalRequiredArchitecture()
	return DataModel.nTotalRequiredArchitecture
end

function DataModel.UpdateTotalRequiredArchitectureBy(nDiffValue)
	DataModel.nTotalRequiredArchitecture = DataModel.nTotalRequiredArchitecture + nDiffValue
end

function DataModel.UpdateTotalRequiredCoinBy(nDiffValue)
	DataModel.nTotalRequiredCoin = DataModel.nTotalRequiredCoin + nDiffValue
end

function DataModel.IsInSearchMode()
	return DataModel.szSearchKeyword and DataModel.szSearchKeyword ~= ""
end

function DataModel.DoesSetMatchSearchKeywordByFurnitureName(dwSetID)
	local aFurnitureInfos = DataModel.GetAllFurnitureSetInfo(dwSetID) or {}
	local tUiInfo
	for nIndex, tInfo in ipairs(aFurnitureInfos) do
		tUiInfo = FurnitureData.GetFurnInfoByTypeAndID(HS_FURNITURE_TYPE.FURNITURE, tInfo.ID)
		if StringFindW(UIHelper.GBKToUTF8(tUiInfo.szName), DataModel.szSearchKeyword) then
			return true
		end
	end
	return false
end

function DataModel.AppendOneLikedSet(dwSetID)
	if IsDebugClient() then
		Log("==== 调用了函数 DataModel.AppendOneLikedSet()，堆栈： " .. tostring(debug.traceback()))
	end
	local aRemovedSets = {}
	table.insert(UIHomeCollectionPage.aLikedSets, dwSetID)

	local tSetInfo = Table_GetFurnitureSetInfoByID(dwSetID)
	assert(tSetInfo)

	local nDlcID = tSetInfo.nDlcID
	local aFellowIndices = {}
	for k, dwTheSetID in ipairs(UIHomeCollectionPage.aLikedSets) do
		local tTheSetInfo = Table_GetFurnitureSetInfoByID(dwTheSetID)
		assert(tTheSetInfo)

		local nTheDlcID = tTheSetInfo.nDlcID
		if nTheDlcID == nDlcID then
			table.insert(aFellowIndices, k)
		end
	end

	if #aFellowIndices > _MAX_LIKED_SETS_IN_DLC then
		local nSurplus = #aFellowIndices - _MAX_LIKED_SETS_IN_DLC
		for m = nSurplus, 1, -1 do
			local dwRemovedSetID = table.remove(UIHomeCollectionPage.aLikedSets, aFellowIndices[m])
			table.insert(aRemovedSets, dwRemovedSetID)
		end
	end
	return aRemovedSets
end

function DataModel.RemoveOneLikedSet(dwSetID)
	_G.RemoveTableValue(UIHomeCollectionPage.aLikedSets, dwSetID)
end

-- 辅助用
function DataModel.UpdateAllNoticeRewardList(aAllNoticeRewardList, tNewRewardInfo)
	--tItem.dwItemType, tItem.dwItemID, tItem.nItemAmount = 1
	for _, t in ipairs(aAllNoticeRewardList) do
		if t.dwItemType == tNewRewardInfo.dwItemType and t.dwItemID == tNewRewardInfo.dwItemID then
			t.nItemAmount = t.nItemAmount + tNewRewardInfo.nItemAmount
			return
		end
	end
	table.insert(aAllNoticeRewardList, tNewRewardInfo)
end

--[[
	返回值：
	可领奖的套装ID列表，
	和对应套装奖励道具的总和
--]]
function DataModel.UpdateAndGetAllCanGetRewardSetInfo(bOnlySetIDs) -- 重要： 当传入false的时候，其实setID不需要更新了
	local dwSetID, eCollectType, tSetLogicConfig, aAwardItems
	DataModel.aCanGetRewardSetIDs = {}
	local aAllNoticeRewardList = {}
	for nDlcID, aSetInfosInDlc in pairs(DataModel.tDlcSetInfo) do
		for _, t in ipairs(aSetInfosInDlc) do
			dwSetID = t.dwSetID
			eCollectType = DataModel.GetSetBriefCollectProgress(dwSetID)

			if eCollectType == SET_COLLECTION_STATE_TYPE.TO_AWARD then
				table.insert(DataModel.aCanGetRewardSetIDs, dwSetID)

				if not bOnlySetIDs then
					tSetLogicConfig = GetSetCollectionConfig(dwSetID)
					aAwardItems = tSetLogicConfig and tSetLogicConfig.AwardItem or {}
					for _, tItem in ipairs(aAwardItems) do
						DataModel.UpdateAllNoticeRewardList(aAllNoticeRewardList, tItem)
					end
				end
			end
		end
	end

	return DataModel.aCanGetRewardSetIDs, aAllNoticeRewardList
end

function DataModel.GetCanGetRewardSetIDs()
	return DataModel.aCanGetRewardSetIDs
end

function DataModel.DoesDlcNeedShowRedDot(nDlcID)
	local aSetInfosInCurDlc = DataModel.GetSetInfoByDlc(nDlcID)
	local aCanGetRewardSetIDs = DataModel.GetCanGetRewardSetIDs()
	for _, t in ipairs(aSetInfosInCurDlc) do
		if CheckIsInTable(aCanGetRewardSetIDs, t.dwSetID) then
			return true
		end
	end
	return false
end

---- 逻辑申请
--[[
function DataModel.ApplyAllSetCollectionStates()
	--Log("=== 即将申请以便全局刷新家具套装状态")
	local pPlayer = PlayerData.GetClientPlayer()
	if pPlayer then
		pPlayer.ApplySetCollection()
	end
end]]

function DataModel.ApplySingleSetReward(dwSetID)
	GetClientPlayer().ApplySetCollectionAward(dwSetID)
end

local function _GetSubArray(aArray, nBeg, nEnd)
	local aSubArray = {}
	for i = nBeg, nEnd do
		table.insert(aSubArray, aArray[i])
	end
	return aSubArray
end

function DataModel.ApplyMultipleSetReward(aSetIDs)
	if IsTableEmpty(aSetIDs) then
		Log("【ERROR】尝试一键领取所有套装奖励时，不存在可领取的套装奖励！")
	else
		local _MAX_APPLY_COUNT = 6
		local nSetCount = #aSetIDs
		local nRounds = math.ceil(nSetCount / _MAX_APPLY_COUNT)

		local i = 1
		Timer.AddCycle(DataModel, 0.4, function()
			if i <= nRounds then
				local aParamSetIDs = _GetSubArray(aSetIDs, (i-1) * _MAX_APPLY_COUNT + 1, math.min(nSetCount, i * _MAX_APPLY_COUNT))
				GetClientPlayer().ApplySetCollectionAward(unpack(aParamSetIDs))
				Log("==== 刚刚尝试去领这些套装的奖励：")
				UILog_Dev2(aParamSetIDs)

				i = i + 1
			else
				Timer.DelAllTimer(DataModel)
				DataModel.bInGetRewardCD = false
			end
		end)
	end
end

-- 发起购买后，收到服务器回包前购买置灰，且在结算后再添加购买CD
function DataModel.OnBuyFurniture(bBuy)
	DataModel.bOnBuyFurniture = bBuy
end

function DataModel.UpdateBuyFresh()
	DataModel.nCooldownBuyTime = GetCurrentTime() + BUY_CD
end

----入口----
function UIHomeCollectionPage:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
		self.bInitSetList = true
		DataModel.Init()
		self:InitCurrency()
	end
	self.bIsBuyMode = false
	self.bIsFilterMode = false
	self.bIsSearchMode = false
	self.bAllSourceFilter = true
	self.bAllSetState = true
	self.bAllSetStars = true
	self.tSetSelected = {}
	FilterDef.HomelandCollectionFilter.Reset()
    local compLuaBind = self.WidgetFurnitureKindList:getComponent("LuaBind")
    self.navigationScript = compLuaBind and compLuaBind:getScriptObject() ---@type UIWidgetScrollViewTree

	local bUnavailable = HomelandEventHandler.IsFurnitureCollectLocked()
	if bUnavailable then
		UIHelper.SetVisible(self.WidgetAniMiddle, bUnavailable)
		if HomelandData.IsFurnitureSetCanAward() then
			TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_FURNITURE_UNLOCK_TIPS)
		end
		return
	end

	self:GetAllSetInfo()
    self:UpdateInfo()
	self:AddBuyCD()

    -- UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewFurnitureKindList)
end

function UIHomeCollectionPage:OnExit()
	DataModel.UnInit()
    self.bInit = false
end

function UIHomeCollectionPage:BindUIEvent()
	UIHelper.SetTouchDownHideTips(self.TogQuestion, false)
	UIHelper.BindUIEvent(self.BtnReceive02, EventType.OnClick, function ()
		local tSetInfo = GetClientPlayer().GetSetCollection(self.tSetSelected.dwSetID)
		if tSetInfo.eType ~= SET_COLLECTION_STATE_TYPE.TO_AWARD then
			return
		end
        if not table_is_empty(self.tSetSelected) then
			if DataModel.bInGetRewardCD then
				OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_HOMELAND_FURNITURE_SET_IN_GET_REWARD_CD)
				return
			end
			DataModel.ApplySingleSetReward(self.tSetSelected.dwSetID)
		end
    end)

	UIHelper.BindUIEvent(self.BtnReceive01, EventType.OnClick, function ()
		local aCanGetRewardSetIDs, aAllNoticeRewardList = DataModel.UpdateAndGetAllCanGetRewardSetInfo(false)
		DataModel.ApplyMultipleSetReward(aCanGetRewardSetIDs)
		self.bIsBuyMode = false
		self.bAllBuy = false
		self:UpdateInfo()
    end)

	UIHelper.BindUIEvent(self.BtnFurnitureBuy, EventType.OnClick, function ()
		self.bIsBuyMode = true
		self.bAllBuy = true
		self:EnterBuyModeCheck()
    end)

	UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function ()
		self.bIsBuyMode = false
		self.bAllBuy = false
		self:EnterBuyModeCheck()
    end)

	UIHelper.BindUIEvent(self.BtnCatalpaTrip, EventType.OnClick, function ()
		local view = UIMgr.Open(VIEW_ID.PanelFurnitureReward)
		view:UpdateFurnitureRewardInfo(DataModel)
    end)

	UIHelper.BindUIEvent(self.BtnSure, EventType.OnClick, function ()
		if DataModel.bOnBuyFurniture or DataModel.nCooldownBuyTime > GetCurrentTime() then
			return
		end
		self.tbBuyList = {}
		for _, cell in ipairs(self.tbFurnitureBuyCell) do
			local bSelected = UIHelper.GetSelected(cell.TogFurnitureSift)
			if bSelected then
				table.insert(self.tbBuyList, {dwFurnitureID = cell.tUiInfo.dwFurnitureID, nNum = 1})
			end
		end
		if not _G.IsHomelandCommunityMap() then
			OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_HOMELAND_FURNITURE_SET_CANT_BATCH_BUY_OUTSIDE_COMMUNITY_MAP)
			return false
		elseif table_is_empty(self.tbBuyList) then
			OutputMessage("MSG_ANNOUNCE_NORMAL", "请选择需要购买的家具")
		else
			TipsHelper.DeleteAllHoverTips(true)
			UIMgr.Open(VIEW_ID.PanelItemPurchasePop, self.tbBuyList)
		end
    end)

	UIHelper.BindUIEvent(self.BtnSkip,EventType.OnClick,function ()
        local tAllLinkInfo = Table_GetCareerGuideAllLink(2333)
		if #tAllLinkInfo > 0 then
			local tbTravel = tAllLinkInfo[1]
			MapMgr.SetTracePoint("阎矩", tbTravel.dwMapID, {tbTravel.fX, tbTravel.fY, tbTravel.fZ})
			HomelandData.CheckIsHomelandMapTeleportGo(2333, tbTravel.dwMapID, nil, nil, function ()
				UIMgr.Close(VIEW_ID.PanelHome)
			end)
		end
    end)

	UIHelper.RegisterEditBoxEnded(self.EditKindSearch, function()
        DataModel.szSearchKeyword = UIHelper.GetText(self.EditKindSearch)
		if DataModel.szSearchKeyword == "" then
			self.bIsSearchMode = false
		else
			self.bIsSearchMode = true
			UIHelper.SetVisible(self.WidgetLaunchFurnitureKindList, false)

		end
		self:EnterSearchModeCheck()
    end)

	UIHelper.BindUIEvent(self.TogSift, EventType.OnClick, function ()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.TogSift, TipsLayoutDir.BOTTOM_RIGHT, FilterDef.HomelandCollectionFilter)
    end)

	UIHelper.BindUIEvent(self.BtnFurnitureTips, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelFurnitureCollectLevelPop)
    end)

	local szZiXingDianDesTips = "<color=#00ff00><img src='UIAtlas2_Home_HomeLand_HomeIcon_icon_BoShi' width='35' height='35'/></c><color=#AED9E0>博识点可增加【结庐江湖】中【博识】进度的的积累。</color>\n<color=#00ff00><img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img-ZiLi' width='35' height='35'/></c><color=#AED9E0>资历点可增加【隐元秘鉴】中【资历】进度的积累。</c>\n<color=#00ff00><img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_zhixingdian' width='30' height='30'/></c><color=#AED9E0>梓行点可增加【庐园广记】中【梓行点等级】进度的积累。</c>"
	UIHelper.BindUIEvent(self.BtnZiXingDianDes1, EventType.OnClick, function(btn)
		local tip, tipScript = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetRichTextTips, self.BtnZiXingDianDes1, TipsLayoutDir.RIGHT_CENTER, szZiXingDianDesTips)
	end)
	UIHelper.BindUIEvent(self.BtnZiXingDianDes2, EventType.OnClick, function(btn)
		local tip, tipScript = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetRichTextTips, self.BtnZiXingDianDes2, TipsLayoutDir.RIGHT_CENTER, szZiXingDianDesTips)
	end)
end

function UIHomeCollectionPage:RegEvent()
	Event.Reg(self, EventType.OnSelectedHomeCollectionLaunchTog, function(tbSetInfo)
		self.tbFurnitureInfos = DataModel.GetAllFurnitureSetInfo(tbSetInfo.dwSetID)
		self.tSetSelected = tbSetInfo
		self.bIsBuyMode = false
		self.bAllBuy = false
		self:EnterBuyModeCheck()
		self:UpdateSetAwardInfo(tbSetInfo)
		self:UpdateFurnitureListInfo()
    end)

	Event.Reg(self, EventType.OnStartBuyFurniture, function()
		DataModel.OnBuyFurniture(true)
    end)

	Event.Reg(self, "ON_SYNC_SET_COLLECTION", function()
		self:UpdateLeftInfo()
		self:UpdateSetAwardInfo(self.tSetSelected)
		self:UpdateFurnitureListInfo()
		self:EnterBuyModeCheck()
		if self.bInitSetList then
			self:EnterSearchModeCheck()
			self.bInitSetList = false
		end
    end)

    Event.Reg(self, "HOME_GET_SEASON_POINTS", function ()
		self:UpdateLeftInfo()
		self:UpdateSetAwardInfo(self.tSetSelected)
		self:EnterBuyModeCheck()
		if self.bInitSetList then
			self:EnterSearchModeCheck()
			self.bInitSetList = false
		end
	end)

	Event.Reg(self, EventType.HideAllHoverTips, function ()
		UIHelper.SetSelected(self.TogQuestion, false)
		UIHelper.SetVisible(self.WidgetTip, false)
    end)

	Event.Reg(self, "LUA_HOMELAND_FURNITURE_INCRE_BY", function()
		local dwFurnitureID, nDiffAmount, bAutoBuy = arg0, arg1, arg2
		local szName = FurnitureData.GetFurnNameByTypeAndID(HS_FURNITURE_TYPE.FURNITURE, dwFurnitureID)
		local nCost = HomelandEventHandler.GetFurniturePriceInArchitecture(dwFurnitureID, false, nDiffAmount)
		local szCost = tostring(nCost) .. g_tStrings.STR_HOMELAND_ARCHITECTURE_POINTS
		local szMsg = FormatString(g_tStrings.STR_HOMELAND_BUY_FURNITURE_SUCCESS_MSG, nDiffAmount, szName, szCost)
		OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)

		DataModel.OnBuyFurniture(false)
		DataModel.UpdateBuyFresh()
    end)

	Event.Reg(self, "LUA_HOMELAND_BUY_FURNITURE_FAIL", function()
		local dwFurnitureID, nCount, bAutoBuy = arg0, arg1, arg2
		local szName = FurnitureData.GetFurnNameByTypeAndID(HS_FURNITURE_TYPE.FURNITURE, dwFurnitureID)
		local szMsg = FormatString(g_tStrings.STR_HOMELAND_BUY_FURNITURE_FAILURE_MSG, nCount, szName)
		OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)

		DataModel.OnBuyFurniture(false)
		DataModel.UpdateBuyFresh()
    end)

	Event.Reg(self, "LUA_HOMELAND_BATCH_BUY_FURNITURE_SUCCESS", function()
		Log("==== 在 FurnitureSetCollect 界面中响应了事件 LUA_HOMELAND_BATCH_BUY_FURNITURE_SUCCESS")
		local nCostArchitecture = arg0
		local szCost = tostring(nCostArchitecture) .. g_tStrings.STR_HOMELAND_ARCHITECTURE_POINTS
		local szMsg = FormatString(g_tStrings.STR_HOMELAND_FURNITURE_SET_BATCH_BUY_SUCCESS, szCost)
		OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)

		DataModel.OnBuyFurniture(false)
		DataModel.UpdateBuyFresh()
    end)

	Event.Reg(self, "LUA_HOMELAND_BATCH_BUY_FURNITURE_FAIL", function()
		OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_HOMELAND_FURNITURE_SET_BATCH_BUY_FAILED)
		DataModel.OnBuyFurniture(false)
		DataModel.UpdateBuyFresh()
    end)

	Event.Reg(self, "HOME_LAND_RESULT_CODE_INT", function ()
		if arg0 == HOMELAND_RESULT_CODE.BUY_FURNITURE_SUCCEED
			or arg0 == HOMELAND_RESULT_CODE.FURNITURE_NOT_COLLECT then
				self.bIsBuyMode = false
				self:EnterBuyModeCheck()
		end
	end)

	Event.Reg(self, EventType.OnFilter, function(szKey, tbSelected)
        if szKey == FilterDef.HomelandCollectionFilter.Key then
            self.nSourceFilter = tbSelected[1][1] - 1
            self.nSetStateFilter = tbSelected[2][1] - 1
            self.nSetStarsFilter = tbSelected[3][1] - 1

			if self.nSourceFilter == 0 then self.bAllSourceFilter = true
				else self.bAllSourceFilter = false end

			if self.nSetStateFilter == 0 then self.bAllSetState = true
				else self.bAllSetState = false end

			if self.nSetStarsFilter == 0 then self.bAllSetStars = true
				else self.bAllSetStars = false end

			if self.bAllSetStars and self.bAllSetState and self.bAllSourceFilter then
				UIHelper.SetSpriteFrame(self.ImgInfoIcon, ShopData.szScreenImgDefault)
			else
				UIHelper.SetSpriteFrame(self.ImgInfoIcon, ShopData.szScreenImgActiving)
			end
        end
		if self.bIsSearchMode == true then
			self:UpdateSearchModeInfo()
		else
			self:UpdateDLCKindListInfo()
		end
    end)

	Event.Reg(self, EventType.OnClickHomeCollectionLikeSetTog, function()
		if self.bIsSearchMode then
			self:UpdateSearchModeInfo(true)
			return
		end
		local nScrollPercent = UIHelper.GetScrollPercent(self.navigationScript.ScrollViewContent)
		local nCurSelectIndex = self.tLastSelectDlcTog.tArgs.nDlcTogIndex
		self.navigationScript:ForbiOnUpdateScrollToTop(true)
		self:UpdateDLCKindListInfo(nCurSelectIndex, nScrollPercent)
    end)

	Event.Reg(self, "UPDATE_ARCHITECTURE", function ()
        self:UpdateCurrency()
    end)
end

function UIHomeCollectionPage:InitCurrency()
    UIHelper.AddPrefab(PREFAB_ID.WidgetCurrency, self.LayoutCion)
    self.currencyScript = UIHelper.AddPrefab(PREFAB_ID.WidgetOtherCurrency, self.LayoutCion)
    self.currencyScript:SetCurrencyType(CurrencyType.Architecture)
    self:UpdateCurrency()
    -- UIHelper.SetAnchorPoint(self.currencyScript._rootNode, 0, 0.5)
end

function UIHomeCollectionPage:UpdateCurrency()
	local player = PlayerData.GetClientPlayer()
    local nArch = 0
    local nCoin = 0
    local tMoney = {nGold = 0}
    if player then
        nArch = player.nArchitecture or 0
        nCoin = player.nCoin or 0
        tMoney = player.GetMoney() or {nGold = 0}
    end
    self.currencyScript:SetLableCount(nArch)
    UIHelper.LayoutDoLayout(self.LayoutCion)
    UIHelper.LayoutDoLayout(self.WidgetAnchorRightTop)
end

function UIHomeCollectionPage:UpdateInfo()
	local bUnavailable = HomelandEventHandler.IsFurnitureCollectLocked()
	if bUnavailable then
		UIHelper.SetVisible(self.WidgetAniMiddle, bUnavailable)
		return
	end
	self:EnterBuyModeCheck()
	self:UpdateLeftInfo()

	if self.tSetSelected then
		self:UpdateSetAwardInfo()
		self:UpdateFurnitureListInfo()
	end
end

function UIHomeCollectionPage:UpdateLeftInfo()
	UIHelper.ClearTexture(self.ImgFurniture)
	UIHelper.ClearTexture(self.ImgFurnitureBg)

    local nTotalCollectPoints = DataModel.GetTotalCollectPoints()
	local nCPLevel, nPointsInLevel, nDestPointsInLevel = DataModel.GetLevelValuesByTotalCollectPoints(nTotalCollectPoints)
	local tLevelInfo = Table_GetFurnitureSetCollectPointsLevelInfo(nCPLevel)
	assert(tLevelInfo)

	local szLevelName = g_tStrings.tStrHomelandFurnitureCollectLevelName[tLevelInfo.nLevel]
	local szTotalCollectProgress = nTotalCollectPoints.."/"..DataModel.MAX_COLLECT_POINTS
	local fPercent = nTotalCollectPoints / DataModel.MAX_COLLECT_POINTS
	local aCanGetRewardSetIDs,_ = DataModel.UpdateAndGetAllCanGetRewardSetInfo(true)
	local bHasCanGet = #aCanGetRewardSetIDs > 0
	local szPath = string.gsub(tLevelInfo.szLevelIconPath, "ui/Image", "mui/Resource")
	szPath = string.gsub(szPath, ".tga", ".png")
	local szBgPath = string.gsub(tLevelInfo.szLevelIconBgPath, "ui/Image", "mui/Resource")
	szBgPath = string.gsub(szBgPath, ".tga", ".png")
	UIHelper.SetString(self.LabelFurnitureName, szLevelName)
	UIHelper.SetString(self.LabelCatalpaTripNum, nTotalCollectPoints)
	UIHelper.SetString(self.LabelCollectTitleNum, szTotalCollectProgress)
	UIHelper.SetVisible(self.ImgRedDot, bHasCanGet)
	UIHelper.SetVisible(self.BtnReceive01, bHasCanGet)
	UIHelper.SetTexture(self.ImgFurniture, szPath)
	UIHelper.SetTexture(self.ImgFurnitureBg, szBgPath)
	UIHelper.SetProgressBarStarPercentPt(self.ImgSliderExperience, 0, 0)
	UIHelper.SetProgressBarPercent(self.ImgSliderExperience, fPercent * 50)
	UIHelper.LayoutDoLayout(self.LayoutCollectTitle)
	UIHelper.LayoutDoLayout(self.LayoutCatalpaTrip)
end

function UIHomeCollectionPage:UpdateSetAwardInfo(tbSetInfo)
	if not tbSetInfo then
		return
	end
	UIHelper.RemoveAllChildren(self.ScrollViewFurnitureReward)
	self.tSetSelected = tbSetInfo
	local eCollectType, nFinishTime, aFurnitureCollectStates = DataModel.GetSetDetailedCollectProgress(self.tSetSelected.dwSetID)
	local tSetLogicConfig = {}
	local aAwardItems = {}
	if not table_is_empty(self.tSetSelected) then
		tSetLogicConfig = GetSetCollectionConfig(self.tSetSelected.dwSetID)
		aAwardItems = tSetLogicConfig and tSetLogicConfig.AwardItem or {}
	end
	for index, tItem in ipairs(aAwardItems) do
		local item = ItemData.GetItem(tItem.dwItemID)
		local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.ScrollViewFurnitureReward)
		scriptCell:OnInitWithTabID(tItem.dwItemType, tItem.dwItemID, tItem.nItemAmount)
		UIHelper.SetAnchorPoint(scriptCell._rootNode, 0, 0)
		UIHelper.SetVisible(scriptCell.WidgetSelectBG, false)
		scriptCell:SetClickCallback(function (nTabType, nTabID)
			TipsHelper.ShowItemTips(scriptCell._rootNode, nTabType, nTabID)
			scriptCell:SetClearSeletedOnCloseAllHoverTips(true)
		end)
	end

	if eCollectType == SET_COLLECTION_STATE_TYPE.COLLECTED  then
		local tFinishTime = TimeToDate(nFinishTime)
		local szFinishText = tFinishTime.year .. "." .. tFinishTime.month .. "." .. tFinishTime.day
		UIHelper.SetVisible(self.BtnReceive02, false)
		UIHelper.SetVisible(self.ImgGetIcon, true)
		UIHelper.SetVisible(self.ImgReceive02, false)
		UIHelper.SetString(self.LabelGetTime, szFinishText)
	elseif eCollectType == SET_COLLECTION_STATE_TYPE.TO_AWARD  then
		self.bGetSingleSetAward = true
		UIHelper.SetVisible(self.BtnReceive02, true)
		UIHelper.SetVisible(self.ImgGetIcon, false)
		UIHelper.SetVisible(self.ImgReceive02, true)
	elseif eCollectType == SET_COLLECTION_STATE_TYPE.COLLECTING or eCollectType == SET_COLLECTION_STATE_TYPE.UNCOLLECTED  then
		self.bGetSingleSetAward = false
		UIHelper.SetVisible(self.BtnReceive02, false)
		UIHelper.SetVisible(self.ImgGetIcon, false)
		UIHelper.SetVisible(self.ImgReceive02, false)
	end

	UIHelper.ScrollViewDoLayout(self.ScrollViewFurnitureReward)
	UIHelper.ScrollToLeft(self.ScrollViewFurnitureReward)
end

function UIHomeCollectionPage:UpdateFurnitureListInfo()
	local nCanBuy = 0
	UIHelper.RemoveAllChildren(self.ScrollViewFurnitureList)
	UIHelper.RemoveAllChildren(self.ScrollViewFurnitureListBig)
	UIHelper.RemoveAllChildren(self.ScrollViewFurnitureBuyList)
	self.tbFurnitureCell = {}
	self.tbFurnitureInBigScrollCell = {}
	self.tbFurnitureBuyCell = {}
	for nIndex, tInfo in ipairs(self.tbFurnitureInfos) do
		local bCanBuy = false
		local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetFurnitureListCell, self.ScrollViewFurnitureList)
		local scriptInBigScrollCell = UIHelper.AddPrefab(PREFAB_ID.WidgetFurnitureListCell, self.ScrollViewFurnitureListBig)
		local scriptBuyCell = UIHelper.AddPrefab(PREFAB_ID.WidgetFurnitureListCell, self.ScrollViewFurnitureBuyList)
		table.insert(self.tbFurnitureCell, scriptCell)
		table.insert(self.tbFurnitureInBigScrollCell, scriptInBigScrollCell)
		table.insert(self.tbFurnitureBuyCell, scriptBuyCell)
		self:InitFunitureCell(scriptCell, tInfo, nIndex)
		self:InitFunitureCell(scriptInBigScrollCell, tInfo, nIndex)
		self:InitFunitureCell(scriptBuyCell, tInfo, nIndex)
		bCanBuy = scriptCell.bCanBuy
		if bCanBuy then
			nCanBuy = nCanBuy + 1
		end
	end

	local eCollectType, _, _ = DataModel.GetSetDetailedCollectProgress(self.tSetSelected.dwSetID)
	local bCollected = eCollectType == SET_COLLECTION_STATE_TYPE.COLLECTED or eCollectType == SET_COLLECTION_STATE_TYPE.TO_AWARD

	if nCanBuy == 0 or bCollected then
		UIHelper.SetVisible(self.BtnFurnitureBuy, false)
		UIHelper.SetVisible(self.ScrollViewFurnitureList, false)
		UIHelper.SetVisible(self.ScrollViewFurnitureListBig, true)
	else
		UIHelper.SetVisible(self.BtnFurnitureBuy, true)
		UIHelper.SetVisible(self.ScrollViewFurnitureList, true)
		UIHelper.SetVisible(self.ScrollViewFurnitureListBig, false)
	end
	UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewFurnitureList)
	UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewFurnitureListBig)
end

function UIHomeCollectionPage:UpdateDLCKindListInfo(nDlcIndex, nScrollPercent)
    local navigationData = {}
	nDlcIndex = nDlcIndex or 1
    local fnTitleSelected = function(bSelected, scriptContainer)
		if not scriptContainer.tItemScripts[1] then
			return
		end
        if bSelected then
            UIHelper.SetVisible(scriptContainer.WidgetNormal, false)
            UIHelper.SetVisible(scriptContainer.WidgetTitleSelect, true)
			if not nScrollPercent then
				self.navigationScript:ForbiOnUpdateScrollToTop(false)
			end
        end
		UIHelper.SetSelected(scriptContainer.tItemScripts[1].TogLaunchFurnitureList, true)
		self.tLastSelectDlcTog = scriptContainer
		self.tSetSelected = scriptContainer.tItemScripts[1].tbSetInfo
		self.tbFurnitureInfos = DataModel.GetAllFurnitureSetInfo(self.tSetSelected.dwSetID)
		self:UpdateSetAwardInfo(self.tSetSelected)
		self:UpdateFurnitureListInfo()
        Event.Dispatch(EventType.OnSelectedHomeCollectionLaunchTog, self.tSetSelected)
    end

	-- local fnSubSelected = function(tSet, bSelected)
    --     if bSelected then
	-- 		self.nSclectedSetIndex = tSet.SetIndex
    --     end
    -- end
    self.navigationScript:ClearContainer()
    for i, nDlcID in ipairs(DataModel.aDlcs) do
		local nFinishedCnt = 0
		local tSetInfo = {}
		local tDlcInfo = Table_GetDLCInfo(nDlcID)
		local aSetInfosInCurDlc = DataModel.GetSetInfoByDlc(nDlcID)
		for i, tSet in ipairs(aSetInfosInCurDlc) do
			local szSource = UIHelper.GBKToUTF8(tSet.szSource)
			local nCollectState, _, _ = DataModel.GetSetDetailedCollectProgress(tSet.dwSetID)
			if ( self.bAllSourceFilter or tbFiliter[1][self.nSourceFilter] == szSource ) and
				( self.bAllSetState or tbFiliter[2][self.nSetStateFilter] == nCollectState) and
				( self.bAllSetStars or tbFiliter[3][self.nSetStarsFilter] == tSet.nStars)
			then
				if table.contain_value(Storage.HomeLand.tbLikedSetID, tSet.dwSetID) then
					table.insert(tSetInfo, 1, {tArgs = tSet})
				else
					table.insert(tSetInfo, {tArgs = tSet})
				end
				if nCollectState == SET_COLLECTION_STATE_TYPE.COLLECTED or nCollectState == SET_COLLECTION_STATE_TYPE.TO_AWARD then
					nFinishedCnt = nFinishedCnt + 1
				end
			end
		end
		local nTotal = #tSetInfo
		nFinishedCnt = math.min(nFinishedCnt, nTotal)
        local szCollected = nFinishedCnt.."/"..nTotal
        table.insert(navigationData, {tArgs = {szDLCName = UIHelper.GBKToUTF8(tDlcInfo.szDLCName), szCollected = szCollected, nDlcTogIndex = i, nDlcID = nDlcID},
            fnSelectedCallback = fnTitleSelected, tItemList = tSetInfo})
	end

    -- table.insert(scriptContainer, navigationData)
    ---@param scriptContainer UIScrollViewTreeContainer
    local func = function(scriptContainer, tArgs)
        UIHelper.SetString(scriptContainer.LabelTitle,  tArgs.szDLCName)
        UIHelper.SetString(scriptContainer.LabelSelect, tArgs.szDLCName)
        UIHelper.SetString(scriptContainer.LabelNum1, tArgs.szCollected)
        UIHelper.SetString(scriptContainer.LabelNum2, tArgs.szCollected)
		Event.Reg(scriptContainer, "ON_SYNC_SET_COLLECTION", function()	--用于更新领奖后的收集状态
			local nFinished, nTotal = self:GetCollectionProgressInDlc(tArgs.nDlcID)
			local szCollected = nFinished.."/"..nTotal
			UIHelper.SetString(scriptContainer.LabelNum1, szCollected)
			UIHelper.SetString(scriptContainer.LabelNum2, szCollected)
		end)
    end

	if not table_is_empty(self.navigationScript) then
		UIHelper.SetupScrollViewTree(self.navigationScript, PREFAB_ID.WidgetFurnitureListTog, PREFAB_ID.WidgetLaunchFurnitureListTog,
            func, navigationData, true)
	end

    --进入时的套装
    -- local scriptContainer = self.navigationScript.tContainerList[nDlcIndex].scriptContainer
    -- UIHelper.SetSelected(scriptContainer.ToggleSelect, true)
	-- UIHelper.SetSelected(scriptContainer.tItemScripts[1].TogLaunchFurnitureList, true)
	-- if nScrollPercent then
	-- 	UIHelper.ScrollToPercent(self.navigationScript.ScrollViewContent, nScrollPercent)
	-- end
end

function UIHomeCollectionPage:InitFunitureCell(scriptCell, tInfo, nIndex)
	scriptCell:OnEnter(tInfo)
	scriptCell:SetClickCallback(function(tUiInfo, bBuy)
		-- local _, scriptTips = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, scriptCell._rootNode, TipsLayoutDir.LEFT_CENTER)
		UIHelper.SetVisible(self.WidgetTip, true)
		self.scriptTips = self.scriptTips or UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetTip)
		self.scriptTips:OnInitFurniture(tUiInfo.nFurnitureType, tUiInfo.dwFurnitureID)
		if bBuy and not self.bIsBuyMode then
			self.scriptTips:SetBtnState({{
				szName = g_tStrings.STR_MOBA_BUY,
				OnClick = function()
					if not _G.IsHomelandCommunityMap() then
						OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_HOMELAND_FURNITURE_SET_CANT_BATCH_BUY_OUTSIDE_COMMUNITY_MAP)
						return false
					else
						TipsHelper.DeleteAllHoverTips(true)
						UIMgr.Open(VIEW_ID.PanelItemPurchasePop, {{dwFurnitureID = tInfo.ID, nNum = 1}})
					end
				end
			}})
		else
			self.scriptTips:SetBtnState({})
		end

	end)
	scriptCell:SetSelectCallback(function()
		-- self.bIsBuyMode = true
		-- self.tbFurnitureBuyCell[nIndex]:SetSelected(true)
		-- self:EnterBuyModeCheck()
		self:UpdateBuyModInfo()
	end)
end

function UIHomeCollectionPage:EnterBuyModeCheck()
	if self.bIsBuyMode then
		UIHelper.SetVisible(self.WidgetFurnitureList, false)
		UIHelper.SetVisible(self.BtnFurnitureBuy, false)
		UIHelper.SetVisible(self.WidgetFurnitureBuyList, true)
		if self.bAllBuy then
			for _, cell in ipairs(self.tbFurnitureBuyCell) do
				local bCanBuy = cell.bCanBuy
				if bCanBuy then
					cell:SetCanBuy(true)
					cell:SetSelected(true)
				end
			end
			self.bAllBuy = false
		end
		UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewFurnitureBuyList)
		self:UpdateBuyModInfo()
	else
		local bCanBuyAll = false
		for _, cell in ipairs(self.tbFurnitureCell) do
			local bCanBuy = cell.bCanBuy
			if bCanBuy then
				cell:SetSelected(false)
				bCanBuyAll = true
			end
		end
		for _, cell in ipairs(self.tbFurnitureBuyCell) do
			local bCanBuy = cell.bCanBuy
			if bCanBuy then
				cell:SetSelected(false)
				bCanBuyAll = true
			end
		end
		UIHelper.SetVisible(self.BtnFurnitureBuy, bCanBuyAll)
		UIHelper.SetVisible(self.WidgetFurnitureList, true)
		UIHelper.SetVisible(self.WidgetFurnitureBuyList, false)
	end
end

function UIHomeCollectionPage:UpdateBuyModInfo()
	local nCountArch = 0
	if self.bIsBuyMode then
		for _, tInfo in ipairs(self.tbFurnitureBuyCell) do
			local bSelected = UIHelper.GetSelected(tInfo.TogFurnitureSift)
			if bSelected then
				nCountArch = nCountArch + tInfo.nFinalArchitecture
			end
		end
		local tbMoney = self:CountAllNeedMoney(nCountArch)
		local bArchEnough = nCountArch <= GetClientPlayer().nArchitecture
		for index, value in ipairs(tbMoney) do
			UIHelper.SetString(self.tbMoney[index], tostring(value))
		end

		UIHelper.SetTextColor(self.tbMoney[1], bArchEnough and colorWhite or colorRed)
		UIHelper.SetSpriteFrame(self.ImgFurnitureBuyIcon01, "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_YuanZhaiBi.png")
		UIHelper.SetSpriteFrame(self.ImgFurnitureBuyIcon, "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_YuanZhaiBi.png")

		UIHelper.LayoutDoLayout(self.LayoutFurnitureBuyCost)
		UIHelper.LayoutDoLayout(self.LayoutFurnitureBuy)
	else
		UIHelper.SetVisible(self.WidgetFurnitureList, true)
		UIHelper.SetVisible(self.WidgetFurnitureBuyList, false)
	end
end

function UIHomeCollectionPage:CountAllNeedMoney(nArch)
	local nPlayerArch = GetClientPlayer().nArchitecture
	local nCountArch = nArch - nPlayerArch
	if nCountArch < 0 then
		return {nArch, 0, 0, 0, nArch}
	end
	local nZhuan, nGold, nSilver = 0
	local nCountMoney = FurnitureBuy.ArchExSilver(nCountArch)
	nZhuan, nGold, nSilver = FurnitureBuy.GetMoneyDetail(nCountMoney)
	return {nArch, nZhuan, nGold, nSilver, nPlayerArch}
end

function UIHomeCollectionPage:AddBuyCD()
	local fn = function ()
		local bOnBuyFurniture = DataModel.bOnBuyFurniture
		local nLeftTime = DataModel.nCooldownBuyTime - GetCurrentTime()
		if bOnBuyFurniture or nLeftTime > 0 then
			local szTime = bOnBuyFurniture and "" or FormatString(g_tStrings.STR_ITEM_TEMP_ECHANT_LEFT_TIME, nLeftTime)
			UIHelper.SetNodeGray(self.BtnSure, true, true)
			UIHelper.SetString(self.LabelSure, g_tStrings.STR_HOMELAND_FURNITURE_BUY..szTime)
		else
			UIHelper.SetNodeGray(self.BtnSure, false, true)
			UIHelper.SetString(self.LabelSure, g_tStrings.STR_HOMELAND_FURNITURE_BUY)
		end
	end
	self.nBuyTimerID = self.nBuyTimerID or Timer.AddCycle(self, 1, function ()
		fn()
	end)
	fn()
end

function UIHomeCollectionPage:EnterSearchModeCheck()
	if UIHelper.GetText(self.EditKindSearch) then
		DataModel.szSearchKeyword = UIHelper.GetText(self.EditKindSearch)
		if DataModel.szSearchKeyword == "" then
			self.bIsSearchMode = false
		else
			self.bIsSearchMode = true
		end
	end

	UIHelper.SetVisible(self.WidgetFurnitureList, true)
	UIHelper.SetVisible(self.WidgetAnchorEmpty, false)
	if self.bIsSearchMode then
		UIHelper.SetVisible(self.WidgetSearchResult, true)
		UIHelper.SetVisible(self.ScrollViewFurnitureKindList, false)
		UIHelper.RemoveAllChildren(self.WidgetLaunchFurnitureKindList)

		self:UpdateSearchModeInfo()
	else
		UIHelper.SetVisible(self.WidgetSearchResult, false)
		UIHelper.SetVisible(self.ScrollViewFurnitureKindList, true)
		self:UpdateDLCKindListInfo()
	end
end

function UIHomeCollectionPage:UpdateSearchModeInfo(bForbidToTop)
	bForbidToTop = bForbidToTop or false
	UIHelper.RemoveAllChildren(self.ScrollViewSearchResult)
	local tbSearchSet = {}
	for _, tbSetInfo in ipairs(self.tAllSetInfo) do
		local tbFurnitureInfo = DataModel.GetAllFurnitureSetInfo(tbSetInfo.dwSetID)
		local szSetName = UIHelper.GBKToUTF8(tbSetInfo.szName)
		local szSource = UIHelper.GBKToUTF8(tbSetInfo.szSource)
		local nCollectState, _, _ = DataModel.GetSetDetailedCollectProgress(tbSetInfo.dwSetID)
		if ( self.bAllSourceFilter or tbFiliter[1][self.nSourceFilter] == szSource ) and
			( self.bAllSetState or tbFiliter[2][self.nSetStateFilter] == nCollectState) and
			( self.bAllSetStars or tbFiliter[3][self.nSetStarsFilter] == tbSetInfo.nStars)
		then
			if string.find(szSetName, DataModel.szSearchKeyword) and not self:CheckIsInTable(tbSearchSet, tbSetInfo) then
				table.insert(tbSearchSet, tbSetInfo)
			else
				for _, tInfo in ipairs(tbFurnitureInfo) do
					local tUiInfo = FurnitureData.GetFurnInfoByTypeAndID(HS_FURNITURE_TYPE.FURNITURE, tInfo.ID)
					local szFurnitureName = UIHelper.GBKToUTF8(tUiInfo.szName)
					if string.find(szFurnitureName, DataModel.szSearchKeyword) and not self:CheckIsInTable(tbSearchSet, tbSetInfo) then
						table.insert(tbSearchSet, tbSetInfo)
					end
				end
			end
		end
	end

	for index, tbSetInfo in ipairs(tbSearchSet) do
		if table.contain_value(Storage.HomeLand.tbLikedSetID, tbSetInfo.dwSetID) then
			table.insert(tbSearchSet, 1, table.remove(tbSearchSet, index))	--根据like表重排一遍
		end
	end

	UIHelper.SetVisible(self.WidgetFurnitureList, #tbSearchSet > 0)
	UIHelper.SetVisible(self.WidgetAnchorEmpty, #tbSearchSet == 0)
	for _, tbSetInfo in ipairs(tbSearchSet) do
		local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetLaunchFurnitureListTog, self.ScrollViewSearchResult)
		scriptCell:OnEnter(tbSetInfo)
	end

	if bForbidToTop then
		return
	end
	UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSearchResult)
end

function UIHomeCollectionPage:GetAllSetInfo()
	self.tAllSetInfo = {}
	for i=#DataModel.aDlcs, 1, -1 do
        local nDlcID = DataModel.aDlcs[i]
		local aSetInfosInCurDlc = DataModel.GetSetInfoByDlc(nDlcID)
		for i, tSet in ipairs(aSetInfosInCurDlc) do
			table.insert(self.tAllSetInfo, tSet)
		end
	end
end

function UIHomeCollectionPage:CheckIsInTable(tbSearchSet, tbSetInfo)
	for _, tbInfo in ipairs(tbSearchSet) do
		if tbSetInfo.dwSetID == tbInfo.dwSetID then
			return true
		end
	end
	return false
end

function UIHomeCollectionPage:GetCollectionProgressInDlc(nDlcID)
	local nFinishedCnt = 0
	local nTotalCnt = 0
	local aSetInfosInCurDlc = DataModel.GetSetInfoByDlc(nDlcID)
	for i, tSet in ipairs(aSetInfosInCurDlc) do
		local szSource = UIHelper.GBKToUTF8(tSet.szSource)
		local nCollectState, _, _ = DataModel.GetSetDetailedCollectProgress(tSet.dwSetID)
		if ( self.bAllSourceFilter or tbFiliter[1][self.nSourceFilter] == szSource ) and
		( self.bAllSetState or tbFiliter[2][self.nSetStateFilter] == nCollectState) and
		( self.bAllSetStars or tbFiliter[3][self.nSetStarsFilter] == tSet.nStars)
		then
			nTotalCnt = nTotalCnt + 1
			if nCollectState == SET_COLLECTION_STATE_TYPE.COLLECTED or nCollectState == SET_COLLECTION_STATE_TYPE.TO_AWARD then
				nFinishedCnt = nFinishedCnt + 1
			end
		end
	end
	return nFinishedCnt, nTotalCnt
end

return UIHomeCollectionPage