-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandMainView
-- Date: 2023-03-27 16:33:21
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandMainView = class("UIHomelandMainView")

local PageIndex2PrefabID = {
    [1] = PREFAB_ID.WidgetHomeLand,
    [2] = PREFAB_ID.WidgetHomeMatch,
    [3] = PREFAB_ID.WidgetHousehold,
    [4] = PREFAB_ID.WidgetFurnitureCollect,
    [5] = PREFAB_ID.WidgetHomeAchievement,
}

local View = nil
local DataModel =
{
	tDstCommunity = {
		--[[
		dwMapID = 0,
		nCopyIndex = 0,
		nCenterID = 0,
		nIndex = 0,
		--]]
	},

	tDstLand = {
		--[[
		dwMapID = 0,
		nCopyIndex = 0,
		nLandIndex = 0,
		--]]
	},

	tDstPrivateHome = {
		--[[
		dwMapID = 0,
		nCopyIndex = 0,
		--]]
	},
	tDstPrivateLand = {
		--[[
		dwMapID = 0,
		nCopyIndex = 0,
		nLandIndex = 0,
		--]]
	}
}

local _MAX_COHABIT_HOUSES = 3 -- 来自逻辑
local LAND_ATTRIBUTE_NUM = 5
local MAP_SCALE_SPEED = 0.1         --鼠标每次滚动的缩放值
local MAP_SCALE_LERP_SPEED = 0.07   --地图缩放和移动的速度

local NPC_TRACE_LINKID = 2364	--个人家园npc指引
local NPC_TRACK_MAPID = 108

local DEFAULT_SKINID = 0 			--默认皮肤ID

--local LEVEL_FULL_FRAME = 20         --线路满帧数
local LEVEL_HOT_FRAME = 44          --推荐帧数
--local LEVEL_EMPTY_FRAME = 21        --闲帧数
local PAGE_INDEX_COUNT = 50
local LOG_FONT = "font=10" .. " r=255 g=255 b=255"

local MAX_NUM_SEASONFURNITURE = 8

local NUM_AREA_OF_PRIVATELAND = 7 --地的数量，目前只有一块先放着

local HOME_TYPE = {
	COMMUNITY = 1,
	PRIVATE = 2,
}

local MAP_IMAGE_INFO =
{
	[414] = {
		w = 3496,h = 3072,
		nDefaultScale = 0.45,
		nSelectScale = 0.6,
		nDefaultPosX = -100,
		nDefaultPosY = -400,
		nTypeFlag = HOME_TYPE.COMMUNITY,
	},
	[455] = {
		w = 3496,h = 3072,--地图的宽和高
		nDefaultScale = 0.45,--地图打开时默认的缩放值
		nSelectScale = 0.6,--选择地块动画的最大的缩放值
		nDefaultPosX = -100,--地图打开时默认的x轴位置
		nDefaultPosY = -400,--地图打开时默认的y轴位置
		nTypeFlag = HOME_TYPE.COMMUNITY,   --家园地图类型
	},
	[462] = {
		w = 5093,h = 4191,
		nDefaultScale = 0.25,
		nSelectScale = 0.6,
		nDefaultPosX = -300,
		nDefaultPosY = -80,
		nTypeFlag = HOME_TYPE.COMMUNITY,
	},
	[471] = {
		w = 3496,h = 3072,
		nDefaultScale = 0.45,
		nSelectScale = 0.6,
		nDefaultPosX = -100,
		nDefaultPosY = -400,
		nTypeFlag = HOME_TYPE.COMMUNITY,
	},
	[486] = {
		w = 3496,h = 3072,
		nDefaultScale = 0.45,
		nSelectScale = 0.6,
		nDefaultPosX = -100,
		nDefaultPosY = -400,
		nTypeFlag = HOME_TYPE.COMMUNITY,
	},
	[565] = {   --个人家园
		w = 4096,h = 3072,
		nDefaultScale = 0.45,
		nSelectScale = 0.48,
		nDefaultPosX = -240,
		nDefaultPosY = -250,
		nTypeFlag = HOME_TYPE.PRIVATE,
	},
	[674] = {
		w = 3496,h = 3072,
		nDefaultScale = 0.4,
		nSelectScale = 0.6,
		nDefaultPosX = -100,
		nDefaultPosY = -150,
		nTypeFlag = HOME_TYPE.COMMUNITY,
	},
}

local tSpecialMapBuyLandRequirementTitle =
{
	[462] = g_tStrings.STR_DATANGJIAYUAN_BUY_LAND_REQUIREMENT_TITLE_SPECIAL_1,-- 九寨沟
}

-- 家园经营图标配置表
local _tLAND_MARKET_TYPE_ICON_FRAMES =
{
	-- -- [经营类型枚举值] = {图标图素文件, 图标在文件中的帧数, Tip},
	-- [GDENUM_HOMELAND_MARKET_TYPE.CARD] = {"ui/Image/JYMap/JYUi_02.UITex", 57, g_tStrings.STR_HOMELAND_MARKET_TYPE_ICON_TIP_CARD},
	-- [GDENUM_HOMELAND_MARKET_TYPE.DINE] = {"ui/Image/JYMap/JYUi_02.UITex", 56, g_tStrings.STR_HOMELAND_MARKET_TYPE_ICON_TIP_DINE},
	-- [GDENUM_HOMELAND_MARKET_TYPE.SELL] = {"ui/Image/JYMap/JYUi_02.UITex", 58, g_tStrings.STR_HOMELAND_MARKET_TYPE_ICON_TIP_SELL},
}


local bApplyCommunityDigestFlag = false
local function FireAllSubWindowEvent(szEvent, ...)
	if HomelandPVP[szEvent] then
		HomelandPVP[szEvent](...)
	end

	if Cohabitation[szEvent] then
		Cohabitation[szEvent](...)
	end

	if FurnitureSetCollect[szEvent] then
		FurnitureSetCollect[szEvent](...)
	end

	if HouseMovingGuide[szEvent] then
		HouseMovingGuide[szEvent](...)
	end

	if SeasonFurniture[szEvent] then
		SeasonFurniture[szEvent](...)
	end
end

local function _IsPagePVPActive()
	local hFrame = GetFrame()
	if hFrame then
		local hPageSet = View.GetPageSetAll(hFrame)
		return hPageSet:GetActivePage():GetName() == "Page_PVP"
	end
end

local function FireSubWindowEvent(szEvent)
	local hFrame = GetFrame()
	if not hFrame then -- 可能此时已经关闭了界面
		return
	end

	if HouseMovingGuide[szEvent] then
		HouseMovingGuide[szEvent]()
	end

	local hPageSet = View.GetPageSetAll(hFrame)
	if hPageSet then
		local szCurPageName = hPageSet:GetActivePage():GetName()

		if szCurPageName == "Page_PVP" then
			local fnAction2 = HomelandPVP[szEvent]
			if fnAction2 then
				fnAction2()
			end
		elseif szCurPageName == "Page_Cohabitation" then
			local fnAction3 = Cohabitation[szEvent]
			if fnAction3 then
				fnAction3()
			end
		elseif szCurPageName == "Page_FurnitureSetCollect" then
			local fnAction4 = FurnitureSetCollect[szEvent]
			if fnAction4 then
				fnAction4()
			end
		elseif szCurPageName == "Page_SeasonFurniture" then
			local fnAction5 = SeasonFurniture[szEvent]
			if fnAction5 then
				fnAction5()
			end
		end
	end
end

local m_tTrackingData = nil
local function InitTrackingData()
	m_tTrackingData =
	{
		actiontype = 23,
		col_1 = "DaTangJiaYuan",
		col_2 = { ["Page_DaTang"] = GetTickCount() },
	}
end

local function SendTrackingData()
	if not m_tTrackingData then
		return
	end
	m_tTrackingData.col_2["Page_DaTang"] = GetTickCount() - m_tTrackingData.col_2["Page_DaTang"]
	FireClickTrackingEvent(m_tTrackingData)
	m_tTrackingData = nil
end

local function GetMapIDType(nMapID)
	return MAP_IMAGE_INFO[nMapID].nTypeFlag
end

--包装个人家园跳转
local function GotoPrivateHome(tHomeData)
	if tHomeData then
		if tHomeData.bNotOwn then
			RemoteCallToServer("On_HomeLand_PLandRequirement",tHomeData.nMapID) --家园入住条件
			DataModel.tPrivateLand.nSelectedAreaIndex = nil
            View:UpdatePrivateMap()
			-- View.UpdatePrivateMap(hFrame)
			-- View.UpdateRecommendTypeInfo(hFrame)
		else
			DataModel.ApplyPrivateHomeInfo(tHomeData.nMapID, tHomeData.nCopyIndex, true)
		end
		-- View.UpdateCurCheckedMyHome(hFrame, nil, nil ,nil)
	end
end
-----------------------------DataModel------------------------------
function DataModel.InitFromCopyIndex(nMapID, nCopyIndex, nLandIndex)
	local bDontShowMyHouse = nMapID and nCopyIndex and nLandIndex
	local pPlayer = GetClientPlayer()
	local nCurrentMapID = pPlayer.GetMapID()
	if HomelandData.IsHomelandCommunityMap(nCurrentMapID) and GetMapIDType(nCurrentMapID) ~= HOME_TYPE.PRIVATE then
		nMapID = nMapID or nCurrentMapID
		nCopyIndex = nCopyIndex or pPlayer.GetScene().nCopyIndex
		bDontShowMyHouse = true
	end

	DataModel.nCurrentMapID = nMapID or 455
	DataModel.nCurrentRankType = COMMUNITY_RANK_TYPE.LEVEL
	DataModel.tCenterList = GetHomelandMgr().GetRelationCenter(GetCenterID())

	DataModel.nExternalLandIndex = nLandIndex
	DataModel.bDontShowMyHouse = bDontShowMyHouse
	if bDontShowMyHouse then
		GetHomelandMgr().ApplyEstate()
		DataModel.ReInitCenterID(GetCenterID(), nCopyIndex)
	else
		DataModel.nInitCenterID = GetCenterID()
		DataModel.nInitCopyIndex = nCopyIndex
		GetHomelandMgr().ApplyEstate()
	end
end

function DataModel.InitFromCenterID(nMapID, nCenterID, nCommunityIndex)
	assert(nMapID, nCenterID, nCommunityIndex)

	DataModel.nCurrentMapID = nMapID
	DataModel.nCurrentRankType = COMMUNITY_RANK_TYPE.LEVEL
	DataModel.tCenterList = GetHomelandMgr().GetRelationCenter(nCenterID)

	DataModel.nExternalLandIndex = nil
	DataModel.bDontShowMyHouse = true

	GetHomelandMgr().ApplyEstate()

	bApplyCommunityDigestFlag = true
	DataModel.nRankPage = 1

	DataModel.nCenterID = nCenterID
	GetHomelandMgr().ApplyCommunityDigest(DataModel.nCurrentMapID, DataModel.nCenterID)
	DataModel.ApplyCommunityInfo(DataModel.nCurrentMapID, nil, DataModel.nCenterID, nCommunityIndex, true)
end

function DataModel.Init(nMapID, nCopyIndexOrCenterID, nLandIndexOrCommunityIndex, bForCenterIDAndCommunityIndex)
	local nCopyIndex, nLandIndex
	local nCenterID, nCommunityIndex
	if bForCenterIDAndCommunityIndex then
		nCenterID, nCommunityIndex = nCopyIndexOrCenterID, nLandIndexOrCommunityIndex
		DataModel.InitFromCenterID(nMapID, nCopyIndexOrCenterID, nLandIndexOrCommunityIndex)
	else
		nCopyIndex, nLandIndex = nCopyIndexOrCenterID, nLandIndexOrCommunityIndex
		DataModel.InitFromCopyIndex(nMapID, nCopyIndexOrCenterID, nLandIndexOrCommunityIndex)
	end
	DataModel.InitPrivateHome()
end

function DataModel.ReInitCenterID(nCenterID, nCopyIndex, bNotApplyCommunityInfo)
	bApplyCommunityDigestFlag = true
	DataModel.nRankPage = 1
	if nCopyIndex then
		DataModel.bApplyReInitCenter = true
		GetHomelandMgr().ApplyCommunityDigest(DataModel.nCurrentMapID, DataModel.nCenterID)
		DataModel.ApplyCommunityInfo(DataModel.nCurrentMapID, nCopyIndex, nil, nil, true)
	else
		DataModel.nCenterID = nCenterID
		GetHomelandMgr().ApplyCommunityDigest(DataModel.nCurrentMapID, DataModel.nCenterID)
		if not bNotApplyCommunityInfo then
			DataModel.ApplyCommunityInfo(DataModel.nCurrentMapID, nil, DataModel.nCenterID, 1, true)
		end
	end
end

function DataModel.UnInit()
	DataModel.aAllMyHomeData = nil
	DataModel.tDstCommunity = {}
	DataModel.tDstLand = {}
	DataModel.nCurrentMapID = nil
	DataModel.nCenterID = nil
	DataModel.tRecommendList = nil
	DataModel.tCommunityInfo = nil
	DataModel.tLandInfo = nil -- 重要：起个更具体直观的名字
	DataModel.nCurrentRankType = nil
	DataModel.nRankPage = nil
	DataModel.bDontShowMyHouse = nil
	DataModel.nExternalLandIndex = nil
	DataModel.tCenterList = nil
	DataModel.bApplyReInitCenter = nil
	DataModel.bNotClearIndex = nil
	DataModel.tPinStartPos = nil
	DataModel.nPanFinger = -1
	DataModel.nScrollMapID = nil
	DataModel.nInitCenterID = nil
	DataModel.nInitCopyIndex = nil
	-- only private use --
	DataModel.aAllMyPrivateData = nil
	DataModel.tDstPrivateHome = {}
	DataModel.tDstPrivateLand = {}
	DataModel.tPrivateHome = nil
	DataModel.tPrivateLand = nil
	DataModel.tSublandCons = nil
	DataModel.tSkinInfo = nil
	DataModel.dwScrollSkinID = nil
end

function DataModel.Set(szName, value)
	DataModel[szName] = value
end

function DataModel.HasMyHomeData()
	return DataModel.aAllMyHomeData and not (IsTableEmpty(DataModel.aAllMyHomeData.Own) and IsTableEmpty(DataModel.aAllMyHomeData.Cohabit))
end

function DataModel.HasPrivateHome()
	local bHas = false
	for _, tHash in ipairs(DataModel.aAllMyPrivateData) do
		if not tHash.bNotOwn then
			bHas = true
		end
	end
	return bHas
end

function DataModel.UpdateRankList(nRankType, nPage)
	if bApplyCommunityDigestFlag then
		return
	end

	if DataModel.nCurrentRankType and DataModel.nCurrentRankType == nRankType then
		return
	end

	DataModel.tRecommendList.tCopyIndex = {}
	DataModel.nCurrentRankType = nRankType or DataModel.nCurrentRankType
	local nPageNum = math.ceil(DataModel.tRecommendList.tTypeSize[DataModel.nCurrentRankType] / 10)

	DataModel.nRankPage = 1
	for i = 1, nPageNum, 1 do
		local nStart = i * 10 - 9
		GetHomelandMgr().ApplyCommunityRank(DataModel.nCurrentMapID, DataModel.nCurrentRankType, nStart, nStart + 9, DataModel.nCenterID)
	end
end

function DataModel.GoToAnotherPageOfIndices(nDeltaPages)
	local nPage = DataModel.nRankPage
	nPage = nPage + nDeltaPages
	DataModel.UpdateRankList(nil, nPage)
end

function DataModel.UpdateRecommendTypeInfo(nMapID, nCenterID)
	DataModel.tRecommendList = {
		nMapID = nMapID,
		nCenterID = nCenterID,
		--nTotalSize = nTotalSize,
		tTypeSize = GetHomelandMgr().GetCommunityDigest(nMapID, nCenterID)
	}

	DataModel.tRecommendList.nTotalSize = DataModel.tRecommendList.tTypeSize[COMMUNITY_RANK_TYPE.NORMAL]
	DataModel.UpdateRankList()
end

function DataModel.UpdateRecommendList(nMapID, nCenterID, nRankType, nBeginIndex, nCount)
	local pHomelandMgr = GetHomelandMgr()
	if not pHomelandMgr then
		return
	end

	if DataModel.nCurrentRankType ~= nRankType then
		return
	end

	DataModel.tRecommendList.nRankType = nRankType
	local tCopyIndex = {}
	local nEndIndex = math.min(nBeginIndex + nCount - 1, DataModel.tRecommendList.nTotalSize)
	for i = nBeginIndex, nEndIndex do
		local nIndex, nRankKey, nSurplusCount = pHomelandMgr.GetCommunityRank(nMapID, nRankType, i, nCenterID)
		tCopyIndex[i] = { nIndex = nIndex,nRankValue = nRankKey,nSurplusCount = nSurplusCount }
	end

	DataModel.tRecommendList.tCopyIndex = DataModel.tRecommendList.tCopyIndex or {}
	for key, value in pairs(tCopyIndex) do
		DataModel.tRecommendList.tCopyIndex[key] = value
	end
end

function DataModel.UpdateCommunityInfo(nMapID, nCopyIndex, nCenterID)
	local pHlMgr = GetHomelandMgr()
	if not pHlMgr then
		return
	end

	if DataModel.bApplyReInitCenter and (not DataModel.nCenterID or nCenterID ~= DataModel.nCenterID) then
		DataModel.bApplyReInitCenter = false
		DataModel.ReInitCenterID(nCenterID, nil, true)
	end

	local tCommunityInfo = pHlMgr.GetCommunityInfo(nMapID, nCopyIndex)
	if not tCommunityInfo then
		return
	end
	local tUILandInfo = Table_GetLandInfo(nMapID) or {}
	local tInfo = {}
	local nSelectedLandIndex = nil

	if DataModel.tCommunityInfo and nMapID == DataModel.tCommunityInfo.nMapID and nCopyIndex == DataModel.tCommunityInfo.nCopyIndex and nCenterID == DataModel.tCommunityInfo.nCenterID then
		nSelectedLandIndex = DataModel.tCommunityInfo.nSelectedLandIndex
	end
	tInfo.nMapID = nMapID
	tInfo.nCopyIndex = nCopyIndex
	tInfo.nCenterID = tCommunityInfo.dwCenterID
	tInfo.nIndex = tCommunityInfo.nIndex
	tInfo.nLevel = tCommunityInfo.nLevel
	tInfo.nActiveValue = tCommunityInfo.nActiveness
	tInfo.nLandCount = tCommunityInfo.nLandCount
	tInfo.nSoldNum = 0
	tInfo.tLandInfo = {}
	for i = 1, tCommunityInfo.nLandCount do
		local tThisLandInfo = {}
		local tThisLandUiInfo = tUILandInfo[i]
		--tInfo.tLandInfo[i] = {}
		local bIsSelling, bPrepareToSale, bIsOpen, nLevel, nAllyCount, eMarketType1, eMarketType2 = pHlMgr.GetLandState(nMapID, nCopyIndex, i)
		nLevel = nLevel or 1
		nAllyCount = nAllyCount or 0
		tThisLandInfo.bIsSelling = bIsSelling
		tThisLandInfo.bPrepareToSale = bPrepareToSale
		tThisLandInfo.bIsOpen = bIsOpen
		tThisLandInfo.nLevel = nLevel
		tThisLandInfo.nAllyCount = nAllyCount
		if not bIsSelling and not bPrepareToSale then
			tInfo.nSoldNum = tInfo.nSoldNum + 1
		end
		tThisLandInfo.bMyLandFlag = pHlMgr.IsMyLand(nMapID, nCopyIndex, i) -- 共居的房子也返回 true
		-- if tThisLandInfo.bMyLandFlag then
		--     tInfo.nSelectedLandIndex = i
		-- end

		tThisLandInfo.eMarketType1 = eMarketType1 -- 潜规则：0表示没有；下同
		tThisLandInfo.eMarketType2 = eMarketType2

		if tThisLandUiInfo then
			tThisLandInfo.szLandName = tThisLandUiInfo.szLandName
			tThisLandInfo.szQuality = tThisLandUiInfo.szQuality
			tThisLandInfo.nArea = tThisLandUiInfo.nArea
			tThisLandInfo.nPrice = tThisLandUiInfo.nPrice
			tThisLandInfo.nUIComponentIndex = tThisLandUiInfo.nUIComponentIndex
			tThisLandInfo.nPosX = tThisLandUiInfo.nPosX
			tThisLandInfo.nPosY = tThisLandUiInfo.nPosY
		else
			Log("DEBUG: 地图(dwMapID: " .. tostring(nMapID) .. ", nCopyIndex: " .. tostring(nCopyIndex) .. ")的第" .. i .. "号地基不存在 tUILandInfo !")
		end

		tThisLandInfo.bFurnitureAllCollected = DataModel.IsSeasonFurnitureAllCollected(nMapID, nCopyIndex, i)

		tInfo.tLandInfo[i] = tThisLandInfo
	end
	DataModel.tCommunityInfo = tInfo
	if DataModel.nExternalLandIndex then
		nSelectedLandIndex = DataModel.nExternalLandIndex
		DataModel.nExternalLandIndex = nil
	end
	if nSelectedLandIndex then
		DataModel.ApplyLandInfo(nMapID, nCopyIndex, nSelectedLandIndex, true)
		RemoteCallToServer("On_HomeLand_LandRequirement", nMapID, nCopyIndex, nSelectedLandIndex)
	else
		local bNeedUncheck = true
		if DataModel.tDstLand and DataModel.tDstCommunity then -- 有点山寨，寻求更优解法
			if (DataModel.tDstLand.dwMapID == DataModel.tDstCommunity.dwMapID and DataModel.tDstLand.nCopyIndex == DataModel.tDstCommunity.nCopyIndex) then
				bNeedUncheck = false
			end
		end
		if bNeedUncheck then
			-- View.UpdateCurCheckedMyHome(GetFrame(), nil, nil, nil)
		end
	end
end

function DataModel.GetPlayerHouseData(nTargetID)
	DataModel.aAllMyHomeData = nil
	local pPlayer = GetClientPlayer()
	local pHomelandMgr = GetHomelandMgr()
	if not pPlayer or not pHomelandMgr then
		return
	end

	local tLandHash = pHomelandMgr.GetAllMyLand()
	local aAllMyOwnHomeData = {}
	local aAllPrivateHomeData = {}
	local aAllMyCohabitedHomeData = {}
	for _, tHash in ipairs(tLandHash) do
		local nMapID, nCopyIndex, nLandIndex = pHomelandMgr.ConvertLandID(tHash.uLandID)
		if tHash.bAllied then
			table.insert(aAllMyCohabitedHomeData, { nMapID = nMapID,nCopyIndex = nCopyIndex,nLandIndex = nLandIndex })
		elseif not tHash.bPrivateLand then
			table.insert(aAllMyOwnHomeData, { nMapID = nMapID,nCopyIndex = nCopyIndex,nLandIndex = nLandIndex })
		end
	end

	local tPrivateHash = pHomelandMgr.GetAllMyPrivateHome() --{}或{{szPrivateHomeID, dwMapID,nCopyIndex},{...}}
	for _, tHash in ipairs(tPrivateHash) do
		table.insert(aAllPrivateHomeData, { nMapID = tHash.dwMapID,nCopyIndex = tHash.nCopyIndex})
		if DataModel.bBuyPrivateSucess and tHash.dwMapID == DataModel.tPrivateHome.nMapID then
			DataModel.bBuyPrivateSucess = false
			DataModel.ApplyPrivateHomeInfo(tHash.dwMapID, tHash.nCopyIndex, true)
			UIMgr.Open(VIEW_ID.PanelHomeContractPop, tHash.dwMapID, tHash.nCopyIndex, 1)
		end
	end

	--原机制：没有家园跳转455
	-- if IsTableEmpty(tLandHash) then
	-- 	if not DataModel.bDontShowMyHouse then
	-- 		DataModel.bDontShowMyHouse = true
	-- 		DataModel.ReInitCenterID(DataModel.nInitCenterID, DataModel.nInitCopyIndex)
	-- 		DataModel.nInitCenterID = nil
	-- 		DataModel.nInitCopyIndex = nil
	-- 	end
	-- 	return
	-- end

	--现：没有家园显示个人家园（未拥有,init的界面）
	if IsTableEmpty(tLandHash) and IsTableEmpty(tPrivateHash) then
		if not DataModel.bDontShowMyHouse then
			if nTargetID then
				DataModel.bDontShowMyHouse = true
				DataModel.ReInitCenterID(DataModel.nInitCenterID, DataModel.nInitCopyIndex)
				DataModel.nInitCenterID = nil
				DataModel.nInitCopyIndex = nil
			else
				DataModel.bDontShowMyHouse = true
				DataModel.nCenterID = GetCenterID()
				GotoPrivateHome(DataModel.tPrivateHome)
				DataModel.nInitCenterID = nil
				DataModel.nInitCopyIndex = nil
			end
		end
		return
	end

	if not IsTableEmpty(tPrivateHash) then
		DataModel.aAllMyPrivateData = aAllPrivateHomeData
	end

	DataModel.aAllMyHomeData = {Own = aAllMyOwnHomeData, Cohabit = aAllMyCohabitedHomeData }
	if not DataModel.bDontShowMyHouse then
		local bHasGoneTo = false
		DataModel.bDontShowMyHouse = true
		DataModel.bApplyReInitCenter = true

		for _, tHomeData in ipairs(aAllPrivateHomeData) do
			DataModel.Set("nCurrentMapID", tHomeData.nMapID)
			DataModel.ApplyPrivateHomeInfo(tHomeData.nMapID, tHomeData.nCopyIndex, not bHasGoneTo)
			if not bHasGoneTo then
				bHasGoneTo = true
			end
		end

		for _, tHomeData in ipairs(aAllMyOwnHomeData) do
			DataModel.Set("nCurrentMapID", tHomeData.nMapID)
			DataModel.ApplyCommunityInfo(tHomeData.nMapID, tHomeData.nCopyIndex, nil, nil, not bHasGoneTo)
			DataModel.ApplyLandInfo(tHomeData.nMapID, tHomeData.nCopyIndex, tHomeData.nLandIndex, not bHasGoneTo)
			if not bHasGoneTo then
				bHasGoneTo = true
			end
		end

		for _, tHomeData in ipairs(aAllMyCohabitedHomeData) do
			DataModel.ApplyCommunityInfo(tHomeData.nMapID, tHomeData.nCopyIndex, nil, nil, not bHasGoneTo)
			DataModel.ApplyLandInfo(tHomeData.nMapID, tHomeData.nCopyIndex, tHomeData.nLandIndex, not bHasGoneTo)
			if not bHasGoneTo then
				bHasGoneTo = true
			end
		end

		DataModel.nInitCenterID = nil
		DataModel.nInitCopyIndex = nil
	end
end

function DataModel.UpdateLandInfo(nMapID, nCopyIndex, nLandIndex)
	local tInfo = GetHomelandMgr().GetLandInfo(nMapID, nCopyIndex, nLandIndex)
	if not tInfo then
		return
	end
	DataModel.tLandInfo = DataModel.tLandInfo or {}
	local tLandInfo = DataModel.tLandInfo
	tLandInfo.nMapID = nMapID
	tLandInfo.nCopyIndex = nCopyIndex
	tLandInfo.nLandIndex = nLandIndex -- 重要： 这三个语句有点危险，因为未必是自己所关心的！（也有可能这个数据的意义没那么具体？）
	tLandInfo.nLevel = tInfo.nLevel
	tLandInfo.nStartSaleTime = tInfo.nStartSaleTime
	tLandInfo.szName = tInfo.szName
	tLandInfo.nDecorateValue1 = tInfo.dwDecorateInfo1
	tLandInfo.nDecorateValue2 = tInfo.dwDecorateInfo2
	tLandInfo.nDecorateValue3 = tInfo.dwDecorateInfo3
	tLandInfo.nDecorateValue4 = tInfo.dwDecorateInfo4
	tLandInfo.nDecorateValue5 = tInfo.dwDecorateInfo5
	tLandInfo.nGameplayUnlock = tInfo.uUnlockGame
	tLandInfo.bIsMyLand = GetHomelandMgr().IsMyLand(nMapID, nCopyIndex, nLandIndex)

    Event.Dispatch(EventType.OnUpdateHomelandLandInfo, nMapID, nCopyIndex, nLandIndex)
end

function DataModel.UpdateLandBuyCondition(tConditions)
	DataModel.tLandInfo = DataModel.tLandInfo or {}
	DataModel.tLandInfo.tConditions = tConditions
end

--[[
function DataModel.SetSelectingLand(nLandIndex)
    if DataModel.tCommunityInfo then
        DataModel.tCommunityInfo.nSelectedLandIndex = nLandIndex
    end
end
--]]

function DataModel.GetCenterNameByID(dwCenterID)
	for k, v in pairs(DataModel.tCenterList) do
		if v.dwCenterID == dwCenterID then
			return v.szCenterName
		end
	end
end

function DataModel.GetDragPos()
	if IsMobileStreamingEnable() then
		return Station.GetDragFingerPos()
	end

	return Cursor.GetPos()
end

function DataModel.IsGroupBuy(dwMapID)
	local tTable = GetHomelandMgr().GetHomelandMapList()
	for k, v in pairs(tTable) do
		if v.MapID == dwMapID then
			if v.IsGroupon == 1 then
				return true
			end
		end
	end

	return false
end

function DataModel.IsCommunityForYouHui() -- 重要： 改名为 IsCommunityInDiscount
	local tCommunityInfo = DataModel.tCommunityInfo
	local bInDiscount, szDiscountTip = false
	if ActivityData.IsActivityOn(681) and tCommunityInfo.nMapID == 462 then
		bInDiscount = true
		szDiscountTip = g_tStrings.STR_DATANGJIAYUAN_COMMUNITY_YOUHUI_ENABLED_TIP_SPECIAL
	elseif (tCommunityInfo.nLevel >= 5) and (tCommunityInfo.nSoldNum / tCommunityInfo.nLandCount >= 0.8) then
		bInDiscount = true
		szDiscountTip = g_tStrings.STR_DATANGJIAYUAN_COMMUNITY_YOUHUI_ENABLED_TIP
	else
		szDiscountTip = g_tStrings.STR_DATANGJIAYUAN_COMMUNITY_YOUHUI_DISABLED_TIP
	end
	return bInDiscount, szDiscountTip
end

function DataModel.ApplyCommunityInfo(dwMapID, nCopyIndex, nCenterID, nIndex, bGoto)
	if bGoto then
		DataModel.tDstCommunity = {}
		DataModel.tDstCommunity.dwMapID = dwMapID
		if nCopyIndex then
			DataModel.tDstCommunity.nCopyIndex = nCopyIndex
		else
			DataModel.tDstCommunity.nCenterID = nCenterID
			DataModel.tDstCommunity.nIndex = nIndex
		end
	end

	if nCopyIndex then
		GetHomelandMgr().ApplyCommunityInfo(dwMapID, nCopyIndex)
	else
		GetHomelandMgr().ApplyCommunityInfo(dwMapID, nCenterID, nIndex)
	end
end

function DataModel.IsCommunityDestination(dwMapID, nCopyIndex, nCenterID, nIndex)
	if DataModel.tDstCommunity.dwMapID == dwMapID then
		if DataModel.tDstCommunity.nCopyIndex then
			return DataModel.tDstCommunity.nCopyIndex == nCopyIndex
		else
			return DataModel.tDstCommunity.nCenterID == nCenterID and DataModel.tDstCommunity.nIndex == nIndex
		end
	else
		return false
	end
end

function DataModel.ApplyLandInfo(dwMapID, nCopyIndex, nLandIndex, bSelectLandIndex)
	if bSelectLandIndex then
		DataModel.tDstLand = { dwMapID = dwMapID,nCopyIndex = nCopyIndex,nLandIndex = nLandIndex }

		-- 这样的实现有点奇怪
		if DataModel.tCommunityInfo and dwMapID == DataModel.tCommunityInfo.nMapID and nCopyIndex == DataModel.tCommunityInfo.nCopyIndex then
			DataModel.tCommunityInfo.nSelectedLandIndex = nLandIndex
		else
			DataModel.bWaitingForSetSelectedLandIndex = true
		end

		-- View.UpdateCurCheckedMyHome(GetFrame(), dwMapID, nCopyIndex, nLandIndex)
	end

	GetHomelandMgr().ApplyLandInfo(dwMapID, nCopyIndex, nLandIndex)
end

function DataModel.GetLandSeasonScore(dwMapID, nCopyIndex, nLandIndex)
	return GetHomelandMgr().GetLandSeasonData(dwMapID, nCopyIndex, nLandIndex, 8, 2)
end

function DataModel.IsSeasonFurnitureAllCollected(dwMapID, nCopyIndex, nLandIndex)
	local bCollected = false
	local dwCnt = 0
	local hHmMgr = GetHomelandMgr()
	if not hHmMgr then
		return
	end
	for i = 1, MAX_NUM_SEASONFURNITURE do
		local bUnlocked = GetHomelandMgr().GetLandSeasonData(dwMapID, nCopyIndex, nLandIndex, i - 1, 1) == 1
		if bUnlocked then
			dwCnt = dwCnt + 1
		end
		if dwCnt == MAX_NUM_SEASONFURNITURE then
			bCollected = true
		end
	end
	return bCollected
end

-- private home --
function DataModel.InitPrivateHome() --初始化一个未入住的个人家园
	local tMyPrivateData = {
		nMapID = 565,
		bNotOwn = true,
	}
	DataModel.aAllMyPrivateData = {tMyPrivateData}
	DataModel.tPrivateHome = tMyPrivateData
	DataModel.tPrivateHome.dwSkinID = 0
	DataModel.tPrivateHome.tUISkinInfo = Table_GetPrivateHomeSkin(DataModel.tPrivateHome.nMapID, DataModel.tPrivateHome.dwSkinID)
	DataModel.tPrivateLand = {nMapID = 565}
	DataModel.tPrivateLand.nLandIndex = 1
	DataModel.tPrivateLand.tUILandInfo = Table_GetMapLandInfo(DataModel.tPrivateLand.nMapID, DataModel.tPrivateLand.nLandIndex)
end

function DataModel.UpdatePrivateHomeInfo(nMapID, nCopyIndex)
	local tPrivateHome = DataModel.tPrivateHome
	local tPrivateInfo = GetHomelandMgr().GetPrivateHomeInfo(nMapID, nCopyIndex)
	if not tPrivateInfo then
		return
	end
	tPrivateHome.uPrivateHomeID = tPrivateInfo.uPrivateHomeID
	tPrivateHome.uOwnerID = tPrivateInfo.uOwnerID
	tPrivateHome.dwSkinID = tPrivateInfo.dwSkinID
	tPrivateHome.tUISkinInfo = Table_GetPrivateHomeSkin(nMapID, tPrivateInfo.dwSkinID)
	tPrivateHome.nMapID = nMapID
	tPrivateHome.nCopyIndex = nCopyIndex
	tPrivateHome.bNotOwn = false
end

function DataModel.UpdatePrivateLandInfo(nMapID, nCopyIndex, nLandIndex)
	local tInfo = GetHomelandMgr().GetLandInfo(nMapID, nCopyIndex, nLandIndex)
	if not tInfo then
		return
	end
	local tLandInfo = {}
	tLandInfo.nMapID = nMapID
	tLandInfo.nCopyIndex = nCopyIndex
	tLandInfo.nLandIndex = nLandIndex
	tLandInfo.nLevel = tInfo.nLevel
	tLandInfo.nStartSaleTime = tInfo.nStartSaleTime
	tLandInfo.szName = tInfo.szName
	tLandInfo.nDecorateValue1 = tInfo.dwDecorateInfo1
	tLandInfo.nDecorateValue2 = tInfo.dwDecorateInfo2
	tLandInfo.nDecorateValue3 = tInfo.dwDecorateInfo3
	tLandInfo.nDecorateValue4 = tInfo.dwDecorateInfo4
	tLandInfo.nDecorateValue5 = tInfo.dwDecorateInfo5
	tLandInfo.nGameplayUnlock = tInfo.uUnlockGame
	tLandInfo.uUnlockSubLand = tInfo.uUnlockSubLand  	--解锁
	tLandInfo.uDemolishSubLand = tInfo.uDemolishSubLand --铲平
	tLandInfo.tUILandInfo = Table_GetMapLandInfo(tLandInfo.nMapID, tLandInfo.nLandIndex)
	tLandInfo.nSelectedAreaIndex = nil
	DataModel.tPrivateLand = tLandInfo
end

function DataModel.ApplyPrivateHomeInfo(nMapID, nCopyIndex, bGoto)
	local hHmMgr = GetHomelandMgr()
	if not hHmMgr then
		return
	end
	if bGoto then
		DataModel.tDstPrivateHome.nMapID = nMapID
		DataModel.tDstPrivateHome.nIndex =  nCopyIndex
		RemoteCallToServer("On_HomeLand_PSubLandRequire", nMapID)
	end

	hHmMgr.ApplyPrivateHomeInfo(nMapID, nCopyIndex)
	DataModel.nCenterID = GetCenterID() --应该在apply之后获取
	local nLandIndex = hHmMgr.GetMaxMainLandIndex(nMapID) --就一个大地，还返回0？
	DataModel.ApplyPrivateLandInfo(nMapID, nCopyIndex, 1, bGoto) --这里应该nLandIndex
end

function DataModel.ApplyPrivateLandInfo(nMapID, nCopyIndex, nLandIndex, bGoto)
	if bGoto then
		DataModel.tDstPrivateLand.nMapID = nMapID
		DataModel.tDstPrivateLand.nCopyIndex =  nCopyIndex
		DataModel.tDstPrivateLand.nLandIndex =  nLandIndex
	end
	GetHomelandMgr().ApplyLandInfo(nMapID, nCopyIndex, nLandIndex)
end

function DataModel.UpdatePrivateLandBuyCondition(tConditions)
	DataModel.tPrivateHome.tConditions = tConditions
end

function DataModel.UpdatePSubLandUnlockCondition(tConditions)
	DataModel.tSubLandCons = tConditions
end

function DataModel.UpdateSkinList()
	local tRetSkin = GetHomelandMgr().GetAllPrivateHomeSkin()
	local tSkinInfo = {}
	local uSkinID = GetHomelandMgr().GetMapSkinID(DataModel.tPrivateHome.nMapID, DEFAULT_SKINID) --默认皮肤
	tSkinInfo[DEFAULT_SKINID] = {uSkinID = uSkinID}
	if DataModel.tPrivateHome.dwSkinID == DEFAULT_SKINID then
		tSkinInfo[DEFAULT_SKINID].bUsing = true
	end
	for k, v in ipairs(tRetSkin) do
		local nMapID, dwSkinID = GetHomelandMgr().ConvertMapSkinID(v)
		if nMapID == DataModel.tPrivateHome.nMapID then
			tSkinInfo[dwSkinID] = {uSkinID = v}
			if dwSkinID == DataModel.tPrivateHome.dwSkinID then
				tSkinInfo[dwSkinID].bUsing = true
			end
		end
	end
	DataModel.tSkinInfo = tSkinInfo
end

function UIHomelandMainView:OnEnter(nPageIndex, nMapID, nCopyIndex, nLandIndex, nTargetID, bForCenterIDAndCommunityIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    View = self
	self.nTargetID = nTargetID
    DataModel.Init(nMapID, nCopyIndex, nLandIndex, bForCenterIDAndCommunityIndex)

    self.nCurPageIndex = nPageIndex or 1
	self.nMapID = nMapID
	self.nCur = nMapID
	self.nCopyIndex = nCopyIndex
	self.nLandIndex = nLandIndex

    self:InitView()
	self:RegRedPoint()

	self:UpdateWidgetDownloadVisible()
	UIHelper.SetToggleGroupSelected(self.ToggleGroupNavigation, self.nCurPageIndex - 1)
	if self.nCurPageIndex > 1 then
		local script = self:_getScriptByPageIndex(self.nCurPageIndex)
		if script then
			script:OnEnter()
		end
	end
    GetHomelandMgr().ApplyBuyLandGroupon()  -- 获取当前是否在团购，并添加左侧HouseholdToggle
end

function UIHomelandMainView:OnExit()
    self.bInit = false
	self:UnRegRedPoint()
	DataModel.UnInit()
	HomelandGroupBuyData.UnInit()
	if UIMgr.GetView(VIEW_ID.PanelUID) then
		UIMgr.Close(VIEW_ID.PanelUID)
	end
end

function UIHomelandMainView:BindUIEvent()
    for index, tog in ipairs(self.tbTogPage) do
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupNavigation ,tog)

        UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function (_tog, bSelected)
			if bSelected then
				self.nCurPageIndex = index
				self:UpdateWidgetDownloadVisible()
				local script = self:_getScriptByPageIndex(self.nCurPageIndex)
				if script and script.OnEnter then
					if self.nCurPageIndex > 1 then
						script:OnEnter()

						local scriptHome = self:_getScriptByPageIndex(1)
						if scriptHome and scriptHome.scriptMap and scriptHome.scriptMap.SetAllTextureAntiAliasEnabled then
							scriptHome.scriptMap:SetAllTextureAntiAliasEnabled(true)
						end
					end
				end
				self:ShowUID()
			end

			for _, widget in pairs(self.tbWidgetPage) do
				UIHelper.SetOpacity(widget, 0)
			end
        end)
    end

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

	UIHelper.BindUIEvent(self.BtnHomeAll, EventType.OnClick, function ()
        UIMgr.CloseAllInLayer(UILayer.Page)
        UIMgr.CloseAllInLayer(UILayer.Popup)
		UIMgr.Open(VIEW_ID.PanelHomeOverview)
    end)
end

function UIHomelandMainView:RegEvent()
    Event.Reg(self, "HOME_LAND_RESULT_CODE", function (nResultType, ...)
        LOG.INFO("--------HOME_LAND_RESULT_CODE--------nResultType:"..tostring(nResultType))
        if nResultType == HOMELAND_RESULT_CODE.APPLY_ESTATE_SUCCEED or nResultType == HOMELAND_RESULT_CODE.APPLY_ESTATE_TO_HS_SUCCEED then -- 重要：先统一处理，后面再做出区分
			DataModel.GetPlayerHouseData(self.nTargetID)
			View:UpdatePlayerHomeList()
			-- View.UpdatePlayerHomeList(this)
			-- View.UpdateRecommendTypeInfo(this)
			if DataModel.tCommunityInfo then
				DataModel.bNotClearIndex = true
				DataModel.ApplyCommunityInfo(DataModel.tCommunityInfo.nMapID, DataModel.tCommunityInfo.nCopyIndex, nil, nil, true)
			end
			if DataModel.tLandInfo then
				DataModel.ApplyLandInfo(DataModel.tLandInfo.nMapID, DataModel.tLandInfo.nCopyIndex, DataModel.tLandInfo.nLandIndex, true)
			else
				-- View.UpdateLands()
			end
			-- View.UpdateLandInfoWnd(this)
			-- local hWndRight = View.GetCommonWnd(this):Lookup("Wnd_Right")
			-- local hCBox = hWndRight:Lookup("CBox_ToggleWndRight")
			-- if (DataModel.HasMyHomeData() or DataModel.HasPrivateHome()) and not hCBox:IsCheckBoxChecked() then
			-- 	View.ToggleRecommendCheckBox()
			-- end
		elseif nResultType == HOMELAND_RESULT_CODE.ABANDON_LAND_SUCCESS then
			GetHomelandMgr().ApplyEstateToHS()
		elseif  nResultType == HOMELAND_RESULT_CODE.BUY_PRIVATE_HOME_SUCCEED then
			local nMapID, nCopyIndex = ...
			DataModel.bBuyPrivateSucess = true
			GetHomelandMgr().ApplyEstate()
		end
    end)

    Event.Reg(self, "HOME_LAND_RESULT_CODE_INT", function (nResultType, ...)
        LOG.INFO("--------HOME_LAND_RESULT_CODE_INT--------nResultType:"..tostring(nResultType))
        if nResultType == HOMELAND_RESULT_CODE.APPLY_LAND_INFO then --申请某块地详情
			local nMapID, nCopyIndex, nLandIndex = ...
			if nMapID == DataModel.tDstLand.dwMapID and nCopyIndex == DataModel.tDstLand.nCopyIndex
					and nLandIndex == DataModel.tDstLand.nLandIndex then
				if DataModel.bWaitingForSetSelectedLandIndex then
					if DataModel.tCommunityInfo then
						DataModel.tCommunityInfo.nSelectedLandIndex = nLandIndex -- 这样的实现略奇怪
					end
					DataModel.bWaitingForSetSelectedLandIndex = false
				end

				DataModel.UpdateLandInfo(nMapID, nCopyIndex, nLandIndex)
				-- View.UpdateLandInfoWnd(this)
				-- View.UpdateLands()
			elseif nMapID == DataModel.tDstPrivateLand.nMapID and nCopyIndex == DataModel.tDstPrivateLand.nCopyIndex
			and nLandIndex == DataModel.tDstPrivateLand.nLandIndex then
				DataModel.tDstPrivateLand = {}
				DataModel.UpdatePrivateLandInfo(nMapID, nCopyIndex, nLandIndex)
                self:UpdatePrivateMap()
				-- View.UpdatePrivateMap(this)
				-- View.UpdateAreas()
			end
		elseif nResultType == HOMELAND_RESULT_CODE.APPLY_COMMUNITY_RANK then --申请分线排行榜
			local nMapID, nCenterID, nRankType, nBeginIndex, nCount = ...
			DataModel.UpdateRecommendList(nMapID, nCenterID, nRankType, nBeginIndex, nCount)
			Event.Dispatch(EventType.OnUpdateHomelandMyHomeRankList)
		elseif nResultType == HOMELAND_RESULT_CODE.APPLY_COMMUNITY_INFO then --申请分线详情
			local nMapID, nCopyIndex, nCenterID, nIndex = ...
			if DataModel.IsCommunityDestination(nMapID, nCopyIndex, nCenterID, nIndex) then
				DataModel.UpdateCommunityInfo(nMapID, nCopyIndex, nCenterID)
				DataModel.tDstCommunity = {}
				-- View.UpdateCommunityInfoWnd(this)
                self:UpdateCommunityInfo()
				if not DataModel.bNotClearIndex then
					-- View.UpdateCommunityMap(this)
					-- View.CloseAllTipWnd(this)
				else
					DataModel.bNotClearIndex = false
				end
				-- View.UpdateRecommendTypeInfo(this)
				-- View.UpdateRecommendListSelect(this)
			end
		elseif nResultType == HOMELAND_RESULT_CODE.APPLY_COMMUNITY_DIGEST then --申请分线概况
			if bApplyCommunityDigestFlag then
				bApplyCommunityDigestFlag = false
				local nMapID, nCenterID = ...
				DataModel.UpdateRecommendTypeInfo(nMapID, nCenterID)
			end
		elseif nResultType == HOMELAND_RESULT_CODE.BUY_LAND_SUCCEED then
			local nMapID, nCopyIndex, nLandIndex = ...
			DataModel.ApplyCommunityInfo(nMapID, nCopyIndex, nil, nil, true)
			DataModel.ApplyLandInfo(dwMapID, nCopyIndex, nLandIndex, true)
			GetHomelandMgr().ApplyEstateToHS()
		elseif nResultType == HOMELAND_RESULT_CODE.BUY_PRIVATE_HOME_SUCCEED then
			DataModel.bBuyPrivateSucess = true
			GetHomelandMgr().ApplyEstate()
		elseif nResultType == HOMELAND_RESULT_CODE.APPLY_COMMUNITY_COUNT then
			if arg1 == HOMELAND_RESULT_CODE.SUCCEED then
				local script = self:_getScriptByPageIndex(1)
				if script then
					script:UpdateGroupBuyInfo()
				end
			end
		elseif nResultType == HOMELAND_RESULT_CODE.APPLY_PRIVATE_HOME_INFO_RESPOND then --申请个人家园信息
			local nMapID, nCopyIndex = ...
			if nMapID == DataModel.tDstPrivateHome.nMapID and nCopyIndex == DataModel.tDstPrivateHome.nIndex then
				DataModel.UpdatePrivateHomeInfo(nMapID, nCopyIndex)
                self:UpdatePrivateMap()
				-- View.UpdatePrivateMap(this)
				-- View.UpdateRecommendTypeInfo(this)
			end
		elseif nResultType == HOMELAND_RESULT_CODE.APPLY_BUY_LAND_GROUPON then
			local nResultCode2 = ...
            if nResultCode2 == HOMELAND_RESULT_CODE.GROUPON_SUCCEED then
				HomelandGroupBuyData.Init()
                self:UpdatePlayerHomeList()
            end
		elseif nResultType == HOMELAND_RESULT_CODE.SET_SUB_LAND_UNLOCK_SUCCEED then
			local tPrivateLand = DataModel.tPrivateLand
			local nMapID, nCopyIndex, nLandIndex = arg1, arg2, arg3
			if nMapID == tPrivateLand.nMapID and nCopyIndex == tPrivateLand.nCopyIndex and nLandIndex == tPrivateLand.nLandIndex then
				DataModel.ApplyPrivateLandInfo(nMapID, nCopyIndex, nLandIndex)
			end
		end
    end)

    Event.Reg(self, EventType.OnSelectHomelandMyHomeArea, function (nIndex)
        if DataModel.tCommunityInfo and DataModel.tCommunityInfo.nMapID == DataModel.nCurrentMapID then
            DataModel.ApplyLandInfo(DataModel.tCommunityInfo.nMapID, DataModel.tCommunityInfo.nCopyIndex, nIndex, true)
			RemoteCallToServer("On_HomeLand_LandRequirement", DataModel.tCommunityInfo.nMapID, DataModel.tCommunityInfo.nCopyIndex, nIndex)
        end
    end)

	Event.Reg(self, EventType.OnSelectHomelandMainPage, function (nIndex)
		self.nCurPageIndex = nIndex
		self:UpdateWidgetDownloadVisible()
		UIHelper.SetToggleGroupSelected(self.ToggleGroupNavigation, nIndex - 1)
    end)

    Event.Reg(self, EventType.OnSelectHomelandMyHomeMap, function (nMapID, nCopyIndex, nLandIndex)
        LOG.INFO("---------OnSelectHomelandMyHomeMap--------nMapID:%s, nCopyIndex:%s nLandIndex:%s", tostring(nMapID), tostring(nCopyIndex), tostring(nLandIndex))
        DataModel.Set("nCurrentMapID", nMapID)
        local nType = GetMapIDType(nMapID)
        if nType == HOME_TYPE.PRIVATE then
            GotoPrivateHome(tHomeData)
        else
            DataModel.nRankPage = 1
			if not nCopyIndex then
				DataModel.ReInitCenterID(DataModel.nCenterID, nCopyIndex, false)
			else
				DataModel.ReInitCenterID(DataModel.nCenterID, nCopyIndex, true)
			end
			if DataModel.tCommunityInfo then
				DataModel.tCommunityInfo.nSelectedLandIndex = nil
			end
			DataModel.ApplyLandInfo(nMapID, nCopyIndex, nLandIndex, true)
			RemoteCallToServer("On_HomeLand_LandRequirement", nMapID, nCopyIndex, nLandIndex)
        end

    end)

	Event.Reg(self, EventType.OnReInitHomelandCenterID, function(nCenterID)
		DataModel.ReInitCenterID(nCenterID)
	end)

    Event.Reg(self, EventType.OnHomeAchievementToAward, function (nIndex)
        local pPlayer = GetClientPlayer()
		local tFurnitureSet = Homeland_GetFurnitureSet()
		local tUSetID = tFurnitureSet[1]
        pPlayer.ApplySetCollectionAward(tUSetID[nIndex])
    end)
end

function UIHomelandMainView:InitView()
	local scriptDownload = UIHelper.GetBindScript(self.WidgetDownload)
    local tPackIDList = PakDownloadMgr.GetPackIDListInPackTree(PACKTREE_ID.Homeland) --家园资源列表
    scriptDownload:OnInitWithPackIDListInfo({szName = "家园基础资源", tPackIDList = tPackIDList})
end

function UIHomelandMainView:UpdatePrivateMap()
    LOG.INFO("--------------------UpdatePrivateMap")
    -- if DataModel.nCurrentMapID and DataModel.nCurrentMapID ~= DataModel.tPrivateHome.nMapID then
    --     return
    -- end
    self.nMapID     = DataModel.tPrivateHome.nMapID
    self.nCopyIndex = DataModel.tPrivateHome.nCopyIndex
    self.nLandIndex = 1
	self.dwSkinID = DataModel.tPrivateHome.dwSkinID

	local script = self:_getScriptByPageIndex(1)
	if script then
		script.nCurSelectAreaIndex = nil
		script:OnEnter(self.nMapID, self.nCopyIndex, self.nLandIndex, self.dwSkinID)
	end

	self:UpdatePlayerHomeTog()
end

function UIHomelandMainView:UpdateCommunityInfo()
    LOG.INFO("--------------------UpdateCommunityInfo")
	local tCommunityInfo = DataModel.tCommunityInfo
    if not DataModel.nCurrentMapID or DataModel.nCurrentMapID ~= tCommunityInfo.nMapID then
        return
    end
    self.nMapID     = tCommunityInfo.nMapID
    self.nCopyIndex = tCommunityInfo.nCopyIndex
    self.nCenterID = tCommunityInfo.nCenterID
    self.nLandIndex = 0

	if DataModel.tDstLand and self.nMapID == DataModel.tDstLand.dwMapID and self.nCopyIndex == DataModel.tDstLand.nCopyIndex then
		self.nLandIndex = DataModel.tDstLand.nLandIndex
	end

	local script = self:_getScriptByPageIndex(1)
	if script then
		script:OnEnter(self.nMapID, self.nCopyIndex, self.nLandIndex, 0, DataModel.tCommunityInfo)
	end

	self:UpdatePlayerHomeTog()
end

function UIHomelandMainView:UpdatePlayerHomeTog()
	local script = self:_getScriptByPageIndex(1)
	if script then
		script:UpdatePlayerHomeTog(self.nMapID, self.nCopyIndex, self.nLandIndex)
	end
end

function UIHomelandMainView:UpdatePlayerHomeList()
    LOG.INFO("--------------------UpdatePlayerHomeList")
	local tbData = {}
	for _, tHomeData in ipairs(DataModel.aAllMyPrivateData) do
		local tbInfo = {}
		tbInfo.tHomeData = tHomeData
		tbInfo.bOwn = not tHomeData.bNotOwn
		tbInfo.funcClickCallback = function ()
			if UIMgr.GetView(VIEW_ID.PanelCustomBuyPop) then
                TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_ON_GROUPON_BUY_TIPS)
                TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetCommunityTips)
                return
            end
			local tHomeData = tbInfo.tHomeData
			if tHomeData then
				DataModel.bApplyReInitCenter = true
				DataModel.nCurrentMapID = tHomeData.nMapID
				GotoPrivateHome(tHomeData)
			end
		end
		table.insert(tbData, tbInfo)
	end

	if DataModel.HasMyHomeData() then
		--社区
		for _, tHomeData in ipairs(DataModel.aAllMyHomeData.Own) do
			local tbInfo = {}
			tbInfo.tHomeData = tHomeData
			tbInfo.bOwn = true
			tbInfo.funcClickCallback = function ()
				if UIMgr.GetView(VIEW_ID.PanelCustomBuyPop) then
					TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_ON_GROUPON_BUY_TIPS)
					TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetCommunityTips)
					return
				end
				local tHomeData = tbInfo.tHomeData
				if tHomeData then
					DataModel.Set("nCurrentMapID", tHomeData.nMapID)
					DataModel.ReInitCenterID(nil, tHomeData.nCopyIndex, false)
					if DataModel.tCommunityInfo then
						DataModel.tCommunityInfo.nSelectedLandIndex = nil
					end
					DataModel.ApplyCommunityInfo(tHomeData.nMapID, tHomeData.nCopyIndex, nil, nil, true)
					DataModel.ApplyLandInfo(tHomeData.nMapID, tHomeData.nCopyIndex, tHomeData.nLandIndex, true)
					RemoteCallToServer("On_HomeLand_LandRequirement", tHomeData.nMapID, tHomeData.nCopyIndex, tHomeData.nLandIndex)
				end
			end
			table.insert(tbData, tbInfo)
		end

		--共居
		for _, tHomeData in ipairs(DataModel.aAllMyHomeData.Cohabit) do
			local tbInfo = {}
			tbInfo.tHomeData = tHomeData
			tbInfo.bOwn = false
			tbInfo.bCohabitHome = true
			tbInfo.funcClickCallback = function ()
				if UIMgr.GetView(VIEW_ID.PanelCustomBuyPop) then
					TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_ON_GROUPON_BUY_TIPS)
					TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetCommunityTips)
					return
				end
				local tHomeData = tbInfo.tHomeData
				if tHomeData then
					DataModel.Set("nCurrentMapID", tHomeData.nMapID)
					DataModel.ReInitCenterID(nil, tHomeData.nCopyIndex, false)
					if DataModel.tCommunityInfo then
						DataModel.tCommunityInfo.nSelectedLandIndex = nil
					end
					DataModel.ApplyCommunityInfo(tHomeData.nMapID, tHomeData.nCopyIndex, nil, nil, true)
					DataModel.ApplyLandInfo(tHomeData.nMapID, tHomeData.nCopyIndex, tHomeData.nLandIndex, true)
					RemoteCallToServer("On_HomeLand_LandRequirement", tHomeData.nMapID, tHomeData.nCopyIndex, tHomeData.nLandIndex)
				end
			end
			table.insert(tbData, tbInfo)
		end

		--未共居
		for j = #DataModel.aAllMyHomeData.Cohabit + 1, _MAX_COHABIT_HOUSES do
			local tbInfo = {}
			tbInfo.tHomeData = nil
			tbInfo.bOwn = false
			tbInfo.funcClickCallback = function ()

			end
			-- table.insert(tbData, tbInfo)
		end
	end

	-- 团购
	if HomelandGroupBuyData.dwMapID and HomelandGroupBuyData.dwMapID > 0 then
		local tbInfo = {}
		tbInfo.bGroupBuy = true
		tbInfo.tHomeData = {}
		tbInfo.tHomeData.nMapID = HomelandGroupBuyData.dwMapID
		tbInfo.funcClickCallback = function ()
			Event.Dispatch(EventType.OnSelectHomelandMyHomeMap, HomelandGroupBuyData.dwMapID)
			if not UIMgr.GetView(VIEW_ID.PanelCustomBuyPop) then
				UIMgr.Open(VIEW_ID.PanelCustomBuyPop, HomelandGroupBuyData.dwMapID)
			end
		end
		table.insert(tbData, tbInfo)
	end

	local script = self:_getScriptByPageIndex(1)
	if script then
		script:UpdateHomeList(tbData, DataModel.nCurrentMapID)
	end
end

function UIHomelandMainView:UpdateWidgetDownloadVisible()
	UIHelper.SetVisible(self.WidgetDownload, self.nCurPageIndex == 1 or self.nCurPageIndex == 3)
end

function UIHomelandMainView:RegRedPoint()
	-- RedpointMgr.RegisterRedpoint(self.tbImgRedPoint[1], nil, {3805})
	RedpointMgr.RegisterRedpoint(self.tbImgRedPoint[4], nil, {3803})
	RedpointMgr.RegisterRedpoint(self.tbImgRedPoint[5], nil, {3804})
end

function UIHomelandMainView:UnRegRedPoint()
	-- RedpointMgr.UnRegisterRedpoint(self.tbImgRedPoint[1], {3805})
	RedpointMgr.UnRegisterRedpoint(self.tbImgRedPoint[4], {3803})
	RedpointMgr.UnRegisterRedpoint(self.tbImgRedPoint[5], {3804})
end

function UIHomelandMainView:_getScriptByPageIndex(nPageIndex)
	local nPrefabID = PageIndex2PrefabID[nPageIndex]
	self.tbScriptPage = self.tbScriptPage or {}
	self.tbScriptPage[nPageIndex] = self.tbScriptPage[nPageIndex] or UIHelper.AddPrefab(nPrefabID, self.tbWidgetPage[nPageIndex])
	if self.tbScriptPage[nPageIndex] and self.tbScriptPage[nPageIndex].InitDataModel then
		self.tbScriptPage[nPageIndex]:InitDataModel(DataModel)
	end

	return self.tbScriptPage[nPageIndex]
end

function UIHomelandMainView:ShowUID()
	if UIMgr.GetView(VIEW_ID.PanelUID) then
		UIMgr.SetViewShow(VIEW_ID.PanelUID, self.nCurPageIndex == 5)
	elseif self.nCurPageIndex == 5 then
		UIMgr.Open(VIEW_ID.PanelUID)
	end
end

return UIHomelandMainView