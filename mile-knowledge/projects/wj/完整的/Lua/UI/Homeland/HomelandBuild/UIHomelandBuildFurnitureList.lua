-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildFurnitureList
-- Date: 2023-04-21 15:28:12
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildFurnitureList = class("UIHomelandBuildFurnitureList")

local IMG_ONE_ITEM_SCALE_WHEN_OVER = 1.2
local ATTRIBUTE_NUM = 5

local tFurnitureType2FrameTip = {
	["Brush"] = {50, g_tStrings.STR_HOMELAND_BUILDING_FURNITURE_TYPE_ICON_TIP_BRUSH},
	["CellarBrush"] = {108, g_tStrings.STR_HOMELAND_BUILDING_FURNITURE_TYPE_ICON_TIP_CELLAR_BRUSH},
	["Interaction"] = {51, g_tStrings.STR_HOMELAND_BUILDING_FURNITURE_TYPE_ICON_TIP_INTERACTION},
	["Dye"] = {52, g_tStrings.STR_HOMELAND_BUILDING_FURNITURE_TYPE_ICON_TIP_DYEABLE},
	["Scalable"] = {53, g_tStrings.STR_HOMELAND_BUILDING_FURNITURE_TYPE_ICON_TIP_SCALABLE},
	["Replaceable"] = {95, g_tStrings.STR_HOMELAND_BUILDING_FURNITURE_TYPE_ICON_TIP_REPLACEABLE},
	["NonUniformScaling"] = {53, g_tStrings.STR_HOMELAND_BUILDING_FURNITURE_TYPE_ICON_TIP_NONUNIFORMSCALE},
}

local nItemNumPrePage = 9

local tSortType2Function =
{
	["LEVEL"] = function(tL, tR)
		if not tL.bNew ~= not tR.bNew then
			return tL.bNew
		elseif not tL.bLocked ~= not tR.bLocked then
			return tR.bLocked
		elseif tL.nLevelLimit ~= tR.nLevelLimit then
			if tL.nLevelLimit and tR.nLevelLimit then
				return tL.nLevelLimit < tR.nLevelLimit
			elseif tL.nLevelLimit then
				return false
			elseif tR.nLevelLimit then
				return true
			end
		else
			return tL.dwTableID < tR.dwTableID
		end
	end,
	["QUALITY"] = function(tL, tR)
		if tL.nQualityLevel ~= tR.nQualityLevel then
			return tL.nQualityLevel > tR.nQualityLevel
		else
			return tL.dwTableID < tR.dwTableID
		end
	end,
	["RECORD"] = function(tL, tR)
		if tL.uRecord ~= tR.uRecord then
			return tL.uRecord > tR.uRecord
		else
			return tL.dwTableID < tR.dwTableID
		end
	end,
}

local tDefaultFilterInfo = {
	bCheckHave = true,
	bCheckNotHave = true,
	bArch = true,
	bShop = true,
	bSpeical = true,
	nMinLevel = -1,
	nMaxLevel= -1,
}

local tFilterOrder = {
	[1] = "LEVEL",
	[2] = "QUALITY",
	[3] = "RECORD",
}

-------------------------------DataModel--------------------------------
local DataModel = {}

function DataModel.Init()
	DataModel.tCatgInfo = {}
	DataModel.tDefaultCatg2 = {}
	DataModel.InitCatgInfo()

	DataModel.nCurSubgroup = Homeland_GetNullSubgroupID()
	DataModel.bInSearch = false
	DataModel.nCurCatg1Index = 1
	DataModel.nCurCatg2Index = DataModel.tDefaultCatg2[DataModel.nCurCatg1Index]
	DataModel.bNeedScrollToLeft = true

	DataModel.tLastTaken = {
		dwModelID = 0,
	}
	DataModel.tCurItemList = {}
	DataModel.tCurSubgroupList = {}
	DataModel.szSortType = "LEVEL"

	DataModel.tSearchItemList = {}
	DataModel.tFilterInfo = clone(tDefaultFilterInfo)
	if GDAPI_Homeland_IsNewPlayer() then
		local nLevel = HLBOp_Enter.GetLevel()
		if nLevel < HOMELAND_MAX_LEVEL then
			DataModel.tFilterInfo.nMinLevel = 1
			DataModel.tFilterInfo.nMaxLevel = nLevel
		else
			DataModel.tFilterInfo.nMinLevel = -1
			DataModel.tFilterInfo.nMaxLevel = -1
		end
		DataModel.tFilterInfo.bShop = false
		DataModel.tFilterInfo.bSpeical = false
	end
	DataModel.tRedDotInfo = {}
	DataModel.UpdateRedDotInfo()
	DataModel.UpdateCurItemList()
end

local function IsOriginalFilter()
	if DataModel.szSortType ~= "LEVEL" then
		return false
	end
	local tFilterInfo = DataModel.tFilterInfo
	for k, v in pairs(tDefaultFilterInfo) do
		if v ~= tFilterInfo[k] then
			return false
		end
	end
	return true
end

local function AddInfo(tTable, nCatg1, nCatg2, dwModelID)
	if not tTable[nCatg1] then
		tTable[nCatg1] = {}
	end
	if not tTable[nCatg1][nCatg2] then
		tTable[nCatg1][nCatg2] = {}
	end
	table.insert(tTable[nCatg1][nCatg2], dwModelID)
end

function DataModel.InitCatgInfo()
	local tCatg1Infos = FurnitureData.GetCatg1List()
	for nCatg1Index, tInfo in pairs(tCatg1Infos) do
		local tCatg2Infos = FurnitureData.GetCatg2List(nCatg1Index)
		local tTemp = {}
		local nCount = 1
		for _, tInfo in pairs(tCatg2Infos) do
			tTemp[nCount] = tInfo
			nCount = nCount + 1
		end
		local function fnCmp(tA, tB)
			return tA.dwTableID < tB.dwTableID
		end
		table.sort(tTemp, fnCmp)
		DataModel.tDefaultCatg2[nCatg1Index] = tTemp[1].nCatg2Index
		DataModel.tCatgInfo[nCatg1Index] = tTemp
	end
end

local function GetFurnItemConfig(nFurnitureType, dwFurnitureID)
	local tConfig
	local hlMgr = GetHomelandMgr()

	if nFurnitureType == HS_FURNITURE_TYPE.FURNITURE then
		tConfig = hlMgr.GetFurnitureConfig(dwFurnitureID)
	elseif nFurnitureType == HS_FURNITURE_TYPE.PENDANT then
		tConfig = hlMgr.GetPendantConfig(dwFurnitureID)
	elseif nFurnitureType == HS_FURNITURE_TYPE.APPLIQUE_BRUSH then
		tConfig = hlMgr.GetAppliqueBrushConfig(dwFurnitureID)
	elseif nFurnitureType == HS_FURNITURE_TYPE.FOLIAGE_BRUSH then
		tConfig = hlMgr.GetFoliageBrushConfig(dwFurnitureID)
	end

	return tConfig
end

local function IsFurnitureSourceSpecial(tConfig)
	local tCoinInfo = FurnitureBuy.GetFurnitureInfo(tConfig.dwID)
	return ((not tCoinInfo) and tConfig.nArchitecture == 0) or (tCoinInfo and (not tCoinInfo.bSell))
end

local function CanShow(tInfo, tConfig, hlMgr, pPlayer, bInDev, nMode)
	local nFurnitureType, dwFurnitureID = tInfo.nFurnitureType, tInfo.dwFurnitureID
	local bCanShow = false
	if tConfig and not IsTableEmpty(tConfig) then
		bCanShow = (not tInfo.bForTest) or bInDev
		if bCanShow and (nMode == BUILD_MODE.COMMUNITY or nMode == BUILD_MODE.PRIVATE) and
			nFurnitureType == HS_FURNITURE_TYPE.PENDANT then
			if (not tInfo.bShowWhenNotGot) and (not pPlayer.IsPendentExist(tConfig.nItemID)) then
				bCanShow = false
			end
		end
	end
	return bCanShow
end

local function UpdateFurnItemInfo(tInfo, tConfig)
	local nLevel = HLBOp_Enter.GetLevel()
	local nFurnitureType = tInfo.nFurnitureType
	local dwFurnitureID = tInfo.dwFurnitureID
	local nMode = HLBOp_Main.GetBuildMode()
	local hlMgr = GetHomelandMgr()

	local bLocked = false
	local nLandLevel = HLBOp_Enter.GetLevel()
	local nRequiredLevel = tConfig.nLevelLimit ~= nil and tConfig.nLevelLimit or 0
	if nMode ~= BUILD_MODE.TEST then
		if nFurnitureType == HS_FURNITURE_TYPE.FURNITURE then
			if nRequiredLevel and nRequiredLevel > nLevel then
				bLocked = true
			elseif (nMode == BUILD_MODE.COMMUNITY or nMode == BUILD_MODE.PRIVATE) then
				if IsFurnitureSourceSpecial(tConfig) and (hlMgr.GetFurniture(dwFurnitureID) == 0) then
					if not FurnitureBuy.IsSpecialFurnitrueCanBuy(dwFurnitureID) then
						bLocked = true
					end
				end
			end
		elseif nFurnitureType == HS_FURNITURE_TYPE.PENDANT then
			if nMode == BUILD_MODE.COMMUNITY or nMode == BUILD_MODE.PRIVATE then
				local bCanDo, eErrType = Homeland_CanIsotypePendant(dwFurnitureID)
				if (nRequiredLevel and nRequiredLevel > nLandLevel) or
					eErrType == PENDANT_ERROR_TYPE.NOT_ACQUIRED then
					bLocked = true
				end
			end
		elseif nFurnitureType == HS_FURNITURE_TYPE.APPLIQUE_BRUSH then
			if HLBOp_Enter.IsTenant() then
				bLocked = true
			elseif nMode == BUILD_MODE.COMMUNITY or nMode == BUILD_MODE.PRIVATE then
				bLocked = not hlMgr.GetAppliqueBrush(dwFurnitureID)
			end
		elseif nFurnitureType == HS_FURNITURE_TYPE.FOLIAGE_BRUSH then
			if HLBOp_Enter.IsTenant() then
				bLocked = true
			elseif nMode == BUILD_MODE.COMMUNITY or nMode == BUILD_MODE.PRIVATE then
				bLocked = not hlMgr.GetFoliageBrush(dwFurnitureID)
			end
		end
	end
	local dwFurnitureUiId = hlMgr.MakeFurnitureUIID(tInfo.nFurnitureType, tInfo.dwFurnitureID)
	local tAddInfo = FurnitureData.GetFurnAddInfo(dwFurnitureUiId)
	if tAddInfo then
		tInfo.szSource = tAddInfo.szSource
		tInfo.szPath = tAddInfo.szPath
	end
	tInfo.tScaleRange = Homeland_GetRange(tInfo.szScaleRange)
	tInfo.bLocked = bLocked
	tInfo.nQualityLevel = tConfig.nQualityLevel
	tInfo.nLevelLimit = tConfig.nLevelLimit ~= nil and tConfig.nLevelLimit or 0
	tInfo.uRecord = tConfig.uRecord
end

local function UpdateFurnItemSell(tInfo, tConfig)
	local nFurnitureType = tInfo.nFurnitureType
	local dwFurnitureID = tInfo.dwFurnitureID
	if nnFurnitureType ~= HS_FURNITURE_TYPE.FURNITURE then
		return
	end
	local hlMgr = GetHomelandMgr()

	local tSellInfo = nil
	tSellInfo = {nDiscount = nil, bSell = false, bLimit = false}
	local nDisCoincount, bInCoinDiscount = FurnitureBuy.GetCoinBuyFurnitureDiscount(dwFurnitureID)
	local nDisArchcount, bInArchDiscount = FurnitureBuy.GetArchBuyFurnitureDiscount(dwFurnitureID)
	if bInCoinDiscount then
		tSellInfo.nDiscount = nDisCoincount
	elseif bInArchDiscount then
		tSellInfo.nDiscount = nDisArchcount
	end
	local tCoinInfo = FurnitureBuy.GetFurnitureInfo(dwFurnitureID)
	tSellInfo.bSell = tCoinInfo and tCoinInfo.bSell or true
	if tCoinInfo and tCoinInfo.nEndTime ~= -1 and tCoinInfo.bSell then
		tSellInfo.bLimit = true
	elseif bInArchDiscount and tConfig.nDiscountEndTime ~= -1 then
		tSellInfo.bLimit = true
	end
	tInfo.tSellInfo = tSellInfo
end

local function UpdateFurnItemNum(tInfo)
	local nFurnitureType = tInfo.nFurnitureType
	local dwFurnitureID = tInfo.dwFurnitureID

	if nFurnitureType ~= HS_FURNITURE_TYPE.FURNITURE and
		nFurnitureType ~= HS_FURNITURE_TYPE.PENDANT then
		return
	end

	local tNumInfo = {nRealAmount = 0, nLeftAmount = 0, nWarehouseLeftAmount = 0}
	local hlMgr = GetHomelandMgr()

	if nFurnitureType == HS_FURNITURE_TYPE.FURNITURE then
		tNumInfo.nRealAmount = hlMgr.GetFurniture(dwFurnitureID)
		tNumInfo.nLeftAmount = hlMgr.BuildGetFurnitureCanUse(nFurnitureType, dwFurnitureID)
		tNumInfo.nWarehouseLeftAmount = hlMgr.BuildGetWareHouseCanUse(nFurnitureType, dwFurnitureID)
		tInfo.bHave = tNumInfo.nLeftAmount + tNumInfo.nWarehouseLeftAmount > 0
	elseif nFurnitureType == HS_FURNITURE_TYPE.PENDANT then
		local bHavePendant = hlMgr.GetPendantFurniture(dwFurnitureID)
		tNumInfo.nRealAmount = bHavePendant and 1 or 0
		--local ePendantState = hlMgr.GetPendantFurniture(dwFurnitureID)
		--tNumInfo.nRealAmount = ePendantState == HS_PENDANT_STATE_TYPE.IDLE and 1 or 0
		tNumInfo.nLeftAmount = hlMgr.BuildGetFurnitureCanUse(nFurnitureType, dwFurnitureID)
		tNumInfo.nWarehouseLeftAmount = hlMgr.BuildGetWareHouseCanUse(nFurnitureType, dwFurnitureID)
		tInfo.bHave = tNumInfo.nLeftAmount + tNumInfo.nWarehouseLeftAmount > 0
	elseif nFurnitureType == HS_FURNITURE_TYPE.APPLIQUE_BRUSHE then
		tInfo.bHave = hlMgr.GetAppliqueBrush(dwFurnitureID)
	elseif nFurnitureType == HS_FURNITURE_TYPE.FOLIAGE_BRUSH then
		tInfo.bHave = hlMgr.GetFoliageBrush(dwFurnitureID)
	end
	tNumInfo.nUsedCount = hlMgr.BuildGetOnLandFurniture(nFurnitureType, dwFurnitureID)
	tInfo.tNumInfo = tNumInfo
end

local function FilterItem(tInfo)
	local tFilterInfo = DataModel.tFilterInfo
	local bShow = true
	local nFurnitureType = tInfo.nFurnitureType
	local dwFurnitureID = tInfo.dwFurnitureID
	local hlMgr = GetHomelandMgr()

	if not (tFilterInfo.bCheckHave and tFilterInfo.bCheckNotHave) then
		if not ((tFilterInfo.bCheckHave == tInfo.bHave) and (tFilterInfo.bCheckNotHave == not tInfo.bHave)) then
			bShow = false
		end
	end

	if not bShow then
		return bShow
	end

	if not (tFilterInfo.bArch and tFilterInfo.bShop and tFilterInfo.bSpeical) then
		local aSourceTexts = g_tStrings.tStrHomelandFurnitureFilterSourceTypes
		local szSource = UIHelper.GBKToUTF8(tInfo.szSource)
		local nSourceIndex = nil
		for nIndex, tSource in ipairs(aSourceTexts) do
			if tSource[2] then
				if tSource[1] == szSource then
					nSourceIndex = nIndex
					break
				end
			else
				if string.find(szSource, tSource[1]) then
					nSourceIndex = nIndex
					break
				end
			end
		end

		if nSourceIndex == 1 then
			bShow = tFilterInfo.bArch
		elseif nSourceIndex == 2 then
			bShow = tFilterInfo.bShop
		else
			bShow = tFilterInfo.bSpeical
		end
	end

	if not bShow then
		return bShow
	end

	if tFilterInfo.nMinLevel ~= -1 or tFilterInfo.nMaxLevel ~= -1 then
		local nMinLevel = tFilterInfo.nMinLevel == -1 and 1 or tFilterInfo.nMinLevel
		local nMaxLevel = tFilterInfo.nMaxLevel == -1 and HOMELAND_MAX_LEVEL or tFilterInfo.nMaxLevel
		if not (tInfo.nLevelLimit >= nMinLevel and tInfo.nLevelLimit <= nMaxLevel) then
			bShow = false
		end
	end
	return bShow
end

function DataModel.GetFurnItemList(tFurnitureInfo)
	local hlMgr = GetHomelandMgr()
	local pPlayer = GetClientPlayer()
	local bInDev = HLBOp_Main.IsInDev()
	local nMode = HLBOp_Main.GetBuildMode()

	if not pPlayer then
		return
	end

	local tFurnItemList = {}
	local tSubgroupID2FurnInfo = {}
	for i = 1, #tFurnitureInfo do
		local tInfo = tFurnitureInfo[i]
		local nFurnitureType, dwFurnitureID = tInfo.nFurnitureType, tInfo.dwFurnitureID
		local tConfig = GetFurnItemConfig(nFurnitureType, dwFurnitureID)
		if CanShow(tInfo, tConfig, hlMgr, pPlayer, bInDev, nMode) then
			UpdateFurnItemInfo(tInfo, tConfig)
			UpdateFurnItemSell(tInfo, tConfig)
			UpdateFurnItemNum(tInfo)
			if FilterItem(tInfo) then
				local nSubgroupID = tInfo.nSubgroupID
				if nSubgroupID ~= Homeland_GetNullSubgroupID() then
					if not tSubgroupID2FurnInfo[nSubgroupID] then
						tSubgroupID2FurnInfo[nSubgroupID] = {}
					end
					table.insert(tSubgroupID2FurnInfo[nSubgroupID], tInfo)
				else
					table.insert(tFurnItemList, tInfo)
				end
			end
		end
	end

	local fnCmp = tSortType2Function[DataModel.szSortType]
	for nSubgroupID, tFurnInfo in pairs(tSubgroupID2FurnInfo) do
		local tInfo = tFurnInfo[1]
		if tInfo.nBrushModeCnt > 0 then
			tInfo.bShowNumberAsBrush = true
		end
		table.insert(tFurnItemList, tInfo)
		table.sort(tFurnInfo, fnCmp)
	end
	table.sort(tFurnItemList, fnCmp)
	for k, tList in pairs(tSubgroupID2FurnInfo) do
		table.sort(tList, fnCmp)
	end
	return tFurnItemList, tSubgroupID2FurnInfo
end

function DataModel.UpdateCurItemList()
	local tFurnitureInfo = FurnitureData.GetFurnListByCatg(DataModel.nCurCatg1Index, DataModel.nCurCatg2Index)
	if not tFurnitureInfo then
		tFurnitureInfo = {}
	end
	if tFurnitureInfo then
		DataModel.tCurItemList, DataModel.tCurSubgroupList = DataModel.GetFurnItemList(tFurnitureInfo)
		return
	end
end

function DataModel.UpdateSearchItemList(szItemKeyword)
	local hlMgr = GetHomelandMgr()
	local pPlayer = GetClientPlayer()
	local bInDev = HLBOp_Main.IsInDev()
	local nMode = HLBOp_Main.GetBuildMode()

	if not pPlayer then
		return
	end

	local _, tAllFurniturnInfos, _ = FurnitureData.GetAllFurniturnInfos()
	local bInDev = HLBOp_Main.IsInDev()
	local tItemList = {}

	for nModelID, tInfo in pairs(tAllFurniturnInfos) do
		local nFurnitureType, dwFurnitureID = tInfo.nFurnitureType, tInfo.dwFurnitureID
		local tConfig = GetFurnItemConfig(nFurnitureType, dwFurnitureID)
		if string.find(UIHelper.GBKToUTF8(tInfo.szName), szItemKeyword, 1, true) and CanShow(tInfo, tConfig, hlMgr, pPlayer, bInDev, nMode) then
			UpdateFurnItemInfo(tInfo, tConfig)
			UpdateFurnItemSell(tInfo, tConfig)
			UpdateFurnItemNum(tInfo)
			if FilterItem(tInfo) then
				table.insert(tItemList, tInfo)
			end
		end
	end
	DataModel.tSearchItemList = tItemList
end

function DataModel.GetOneItemInfo(nFurnitureType, dwFurnitureID)
	local hlMgr = GetHomelandMgr()
	local pPlayer = GetClientPlayer()
	local bInDev = HLBOp_Main.IsInDev()
	local nMode = HLBOp_Main.GetBuildMode()
	local tInfo = FurnitureData.GetFurnInfoByTypeAndID(nFurnitureType, dwFurnitureID)
	local nFurnitureType, dwFurnitureID = tInfo.nFurnitureType, tInfo.dwFurnitureID
	local tConfig = GetFurnItemConfig(nFurnitureType, dwFurnitureID)
	if CanShow(tInfo, tConfig, hlMgr, pPlayer, bInDev, nMode) then
		UpdateFurnItemInfo(tInfo, tConfig)
		UpdateFurnItemSell(tInfo, tConfig)
		UpdateFurnItemNum(tInfo)
		return tInfo
	end
	return nil
end

function DataModel.UpdateRedDotInfo()
	DataModel.tRedDotInfo = {}
	local tTable = DataModel.tRedDotInfo
	local tNewFurniture = HomelandEventHandler.GetAllNewlyGotFurniture()
	for i = 1, #tNewFurniture do
		local dwFurnitureID = tNewFurniture[i]
		local tInfo = FurnitureData.GetFurnInfoByTypeAndID(HS_FURNITURE_TYPE.FURNITURE, dwFurnitureID)
		AddInfo(tTable, tInfo.nCatg1Index, tInfo.nCatg2Index, tInfo.dwModelID)
	end
	local tNewPendant = HomelandEventHandler.GetAllNewlyGotPendant()
	for i = 1, #tNewPendant do
		local dwFurnitureID = tNewPendant[i]
		local tInfo = FurnitureData.GetFurnInfoByTypeAndID(HS_FURNITURE_TYPE.PENDANT, dwFurnitureID)
		AddInfo(tTable, tInfo.nCatg1Index, tInfo.nCatg2Index, tInfo.dwModelID)
	end
	local tNewFlowerBrush = HomelandEventHandler.GetAllNewlyGotFlowerBrush()
	for i = 1, #tNewFlowerBrush do
		local dwFurnitureID = tNewFlowerBrush[i]
		local tInfo = FurnitureData.GetFurnInfoByTypeAndID(HS_FURNITURE_TYPE.FOLIAGE_BRUSH, dwFurnitureID)
		AddInfo(tTable, tInfo.nCatg1Index, tInfo.nCatg2Index, tInfo.dwModelID)
	end
	local tNewFloorBrush = HomelandEventHandler.GetAllNewlyGotFloorBrush()
	for i = 1, #tNewFloorBrush do
		local dwFurnitureID = tNewFloorBrush[i]
		local tInfo = FurnitureData.GetFurnInfoByTypeAndID(HS_FURNITURE_TYPE.APPLIQUE_BRUSH, dwFurnitureID)
		AddInfo(tTable, tInfo.nCatg1Index, tInfo.nCatg2Index, tInfo.dwModelID)
	end
end

function DataModel.RemoveRedDot(dwModelID)
	local tInfo = FurnitureData.GetFurnInfoByModelID(dwModelID)
	local nCatg1Index, nCatg2Index = tInfo.nCatg1Index, tInfo.nCatg2Index
	local tRedInfo = nil
	if DataModel.tRedDotInfo[nCatg1Index] then
		tRedInfo = DataModel.tRedDotInfo[nCatg1Index][nCatg2Index]
	end
	local bHaveRedDot = tRedInfo and FindTableValue(tRedInfo, dwModelID) ~= nil
	if not bHaveRedDot then
		return
	end

	if tInfo.nFurnitureType == HS_FURNITURE_TYPE.FURNITURE then
		HomelandEventHandler.RemoveOneNewlyGotItem(tInfo.dwFurnitureID)
	elseif tInfo.nFurnitureType == HS_FURNITURE_TYPE.PENDANT then
		HomelandEventHandler.RemoveOneNewlyGotPendant(tInfo.dwFurnitureID)
	elseif tInfo.nFurnitureType == HS_FURNITURE_TYPE.FOLIAGE_BRUSH then
		HomelandEventHandler.RemoveOneNewlyGotFlowerBrush(tInfo.dwFurnitureID)
	elseif tInfo.nFurnitureType == HS_FURNITURE_TYPE.APPLIQUE_BRUSH then
		HomelandEventHandler.RemoveOneNewlyGotFloorBrush(tInfo.dwFurnitureID)
	end

	DataModel.UpdateRedDotInfo()
	FireUIEvent("LUA_HOMELNAD_UPDATE_REDPONIT")
end
--------------------------------------------------------------------------------------------------------------
local TogFirstIndex2Type = {
	[1] = 1,
	[2] = 2,
	[3] = 3,
	[4] = 4,
	[5] = 5,
	[6] = 6,
	[7] = 9,
}
function UIHomelandBuildFurnitureList:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    DataModel.Init()
	HLBOp_Amount.RefreshLandData()
	-- HomelandCustomBrushData.Init()
    self:UpdateInfo()
end

function UIHomelandBuildFurnitureList:OnExit()
    self.bInit = false
	-- HomelandCustomBrushData.UnInit()
end

function UIHomelandBuildFurnitureList:BindUIEvent()
    for i, tog in ipairs(self.tbTogFirstType) do
        UIHelper.BindUIEvent(tog, EventType.OnClick, function ()
			local nSelectedIndex = i
            if DataModel.bInSearch then
                return
            elseif DataModel.nCurSubgroup ~= Homeland_GetNullSubgroupID() then
                DataModel.nCurSubgroup = Homeland_GetNullSubgroupID()
            end

			local nIndex = TogFirstIndex2Type[nSelectedIndex]
            DataModel.nCurCatg1Index = self.tbFirstTypeInfo[nIndex].nCatg1Index
            DataModel.nCurCatg2Index = DataModel.tDefaultCatg2[DataModel.nCurCatg1Index]
			DataModel.bNeedScrollToLeft = true
            DataModel.UpdateCurItemList()
            Event.Dispatch(EventType.OnUpdateHomelandFurnitureList)

            UIHelper.SetSelected(self.TogFatherType, false)
        end)

        UIHelper.ToggleGroupAddToggle(self.TogGroupFatherType, tog)
		UIHelper.SetTouchDownHideTips(tog, false)
    end

	UIHelper.BindUIEvent(self.TogFatherType, EventType.OnSelectChanged, function(btn, bSelected)
		Event.Dispatch(EventType.OnHomelandBuildTypeTog, bSelected)
	end)

	UIHelper.BindUIEvent(self.BtnBackToMain, EventType.OnClick, function()
		if DataModel.bInSearch then
			DataModel.bInSearch = false
		elseif DataModel.nCurSubgroup ~= Homeland_GetNullSubgroupID() then
			bBeforeSubgroup = true
			DataModel.nCurSubgroup = Homeland_GetNullSubgroupID()
		end
		self:UpdateItemList()
	end)

	UIHelper.BindUIEvent(self.BtnFilter, EventType.OnClick, function()
		TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnFilter, TipsLayoutDir.TOP_LEFT, FilterDef.HomelandBuildFurnitureList)
	end)

	UIHelper.SetVisible(self.BtnHotKeys, HomelandBuildData.GetInputType() == HLB_INPUT_TYPE.MAK)
	UIHelper.BindUIEvent(self.BtnHotKeys, EventType.OnClick, function()
		TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetConstructionHotKeysTip, self.BtnHotKeys, TipsLayoutDir.TOP_LEFT)
	end)

	UIHelper.BindUIEvent(self.TogSearch, EventType.OnClick, function()
		if UIHelper.GetSelected(self.TogSearch) then
			UIHelper.LayoutDoLayout(self.LayoutButtons)
			UIHelper.SetText(self.EditBoxSearch, "")
		else
			DataModel.bInSearch = false
			self:UpdateItemList()
			UIHelper.ScrollViewDoLayout(self.ScrollViewMainItemList)
    		UIHelper.ScrollToLeft(self.ScrollViewMainItemList, 0)
		end
	end)

	if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditBoxSearch, function()
			local szItemKeyword = UIHelper.GetText(self.EditBoxSearch)
			if not string.is_nil(szItemKeyword) then
				DataModel.UpdateSearchItemList(szItemKeyword)
				DataModel.bInSearch = true
			else
				DataModel.bInSearch = false
			end

			self:UpdateItemList()
			UIHelper.ScrollViewDoLayout(self.ScrollViewMainItemList)
    		UIHelper.ScrollToLeft(self.ScrollViewMainItemList, 0)
        end)
    else
        UIHelper.RegisterEditBoxReturn(self.EditBoxSearch, function()
			local szItemKeyword = UIHelper.GetText(self.EditBoxSearch)
			if not string.is_nil(szItemKeyword) then
				DataModel.UpdateSearchItemList(szItemKeyword)
				DataModel.bInSearch = true
			else
				DataModel.bInSearch = false
			end

			self:UpdateItemList()
			UIHelper.ScrollViewDoLayout(self.ScrollViewMainItemList)
    		UIHelper.ScrollToLeft(self.ScrollViewMainItemList, 0)
        end)
    end
end

function UIHomelandBuildFurnitureList:RegEvent()
    Event.Reg(self, "HOME_LAND_CHANGE_FURNITURE", function ()
        if DataModel.bInSearch then
			return
		end
		local eFrom = arg3
		if eFrom == HOMELAND_ACQUIRE_FURNITURE_CODE.BUILD then
			return
		end

		self:DelayUpdateItemList()
	end)

    Event.Reg(self, "LUA_HOMELAND_UPDATE_LANDDATA", function ()
        if DataModel.bInSearch then
			return
		end

		self:DelayUpdateItemList()
		self:DelayUpdateCatg()
    end)

    Event.Reg(self, "HOME_LAND_CHANGE_PENDANT_FURNITURE", function ()
        self:DelayUpdateItemList()
    end)

    Event.Reg(self, "HOME_LAND_CHANGE_PAINTBRUSH", function ()
		self:DelayUpdateItemList()
    end)

    Event.Reg(self, "LUA_HOMELNAD_UPDATE_REDPONIT", function ()
		DataModel.UpdateRedDotInfo()
		self:DelayUpdateItemList()
		self:DelayUpdateCatg()
    end)

	UIHelper.SetTouchDownHideTips(self.TogFatherType, false)--点击自己时不再发送HideAllHoverTips
	Event.Reg(self, EventType.HideAllHoverTips, function ()
        UIHelper.SetSelected(self.TogFatherType, false)
    end)

	Event.Reg(self, EventType.OnFilter, function (szKey, tbInfo)
		if szKey ~= "HomelandBuildFurnitureList" then
			return
		end

		DataModel.tFilterInfo.bCheckHave = table.contain_value(tbInfo[1], 1)
		DataModel.tFilterInfo.bCheckNotHave = table.contain_value(tbInfo[1], 2)
		DataModel.tFilterInfo.bArch = table.contain_value(tbInfo[2], 1)
		DataModel.tFilterInfo.bShop = table.contain_value(tbInfo[2], 2)
		DataModel.tFilterInfo.bSpeical = table.contain_value(tbInfo[2], 3)
		DataModel.tFilterInfo.nMinLevel = tbInfo[3][1]
		DataModel.tFilterInfo.nMaxLevel= tbInfo[3][2]
		DataModel.szSortType = tFilterOrder[tbInfo[4][1]]

		self:DelayUpdateItemList()
    end)

    Event.Reg(self, EventType.OnUpdateHomelandFurnitureList, function ()
        self:UpdateInfo()
    end)

	Event.Reg(self, EventType.OnGotoHomelandFurnitureListOneItem, function (...)
		if DataModel.bInSearch then
			DataModel.bInSearch = false
			UIHelper.SetSelected(self.TogSearch, false)
			UIHelper.ScrollViewDoLayout(self.ScrollViewMainItemList)
    		UIHelper.ScrollToLeft(self.ScrollViewMainItemList, 0)
		elseif DataModel.nCurSubgroup ~= Homeland_GetNullSubgroupID() then
			DataModel.nCurSubgroup = Homeland_GetNullSubgroupID()
		end

		local tbParams = {...}
		if #tbParams == 1 then
			local dwModelID = tbParams[1]
			local tInfo = FurnitureData.GetFurnInfoByModelID(dwModelID)
			if not tInfo then
				return
			end
			self:LocateFurniture(tInfo.nCatg1Index, tInfo.nCatg2Index, tInfo.nSubgroupID, dwModelID)
		elseif #tbParams == 3 then
			self:LocateFurniture(tbParams[1], tbParams[2], tbParams[3])
		end
	end)

	Event.Reg(self, EventType.OnHomeLandBuildResponseKey, function (szKey, ...)
        if szKey == "F1" then
			if TipsHelper.IsHoverTipsExist(PREFAB_ID.WidgetConstructionHotKeysTip) then
				TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetConstructionHotKeysTip)
			else
				TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetConstructionHotKeysTip, self.BtnHotKeys, TipsLayoutDir.TOP_LEFT)
			end
		elseif szKey == "LBracket" then
			self:ScrollOnePage(false)
		elseif szKey == "RBracket" then
			self:ScrollOnePage(true)
        end
    end)

end

function UIHomelandBuildFurnitureList:UpdateInfo()
    self:UpdateCatg1List()
	self:UpdateCatg2List()
	self:UpdateItemList()
    self:UpdateBrushEditor()
    self:UpdateHotKeyBtn()
end

function UIHomelandBuildFurnitureList:UpdateCatg1List()
    local tCatgInfos = FurnitureData.GetCatg1List()
    self.tbFirstTypeInfo = tCatgInfos

    local tbCurInfo = self.tbFirstTypeInfo[DataModel.nCurCatg1Index]
    local szName = UIHelper.GBKToUTF8(tbCurInfo.szName)
    for i, label in ipairs(self.tbLabelNormalName) do
        UIHelper.SetString(label, string.sub(szName, (i - 1) * 3 + 1, i * 3))
    end
    for i, label in ipairs(self.tbLabelPressedName) do
        UIHelper.SetString(label, string.sub(szName, (i - 1) * 3 + 1, i * 3))
    end

	for i, imgRedPoint in ipairs(self.tbImgRedPoint) do
		local nIndex = TogFirstIndex2Type[i]
		local nCatg1Index = self.tbFirstTypeInfo[nIndex].nCatg1Index
		UIHelper.SetVisible(imgRedPoint, not not DataModel.tRedDotInfo[nCatg1Index])
	end

    UIHelper.SetVisible(self.ImgRedPoint, not table.is_empty(DataModel.tRedDotInfo))
end

function UIHomelandBuildFurnitureList:UpdateCatg2List()
    local tCatg2Infos = DataModel.tCatgInfo[DataModel.nCurCatg1Index]

	self.tbCatg2Cells = self.tbCatg2Cells or {}
	self.tbCellIndexToCatg2Index = {}
    UIHelper.HideAllChildren(self.ScrollViewChildTypeList)
	local i = 1
	for _, tInfo in pairs(tCatg2Infos) do
        local cell = self.tbCatg2Cells[i]
		if not cell then
			cell = UIHelper.AddPrefab(PREFAB_ID.WidgetChildTypeItem, self.ScrollViewChildTypeList)
			self.tbCatg2Cells[i] = cell
			UIHelper.ToggleGroupAddToggle(self.TogGroupChildType, cell.TogChildTypeItem)
		end
		self.tbCellIndexToCatg2Index[i] = tInfo.nCatg2Index
		UIHelper.SetVisible(cell._rootNode, true)
        cell:OnEnter(DataModel, tInfo)
		i = i + 1
	end

	UIHelper.SetToggleGroupSelected(self.TogGroupChildType, table.get_key(self.tbCellIndexToCatg2Index, DataModel.nCurCatg2Index) - 1)

	local bDoLayout = false
	if not self.nLastCatg1Index then
		bDoLayout = true
		self.nLastCatg1Index = DataModel.nCurCatg1Index
	elseif self.nLastCatg1Index ~= DataModel.nCurCatg1Index then
		bDoLayout = true
		self.nLastCatg1Index = DataModel.nCurCatg1Index
	end

	if bDoLayout then
		UIHelper.ScrollViewDoLayout(self.ScrollViewChildTypeList)
    	UIHelper.ScrollToLeft(self.ScrollViewChildTypeList, 0)
	end
end

function UIHomelandBuildFurnitureList:UpdateItemList()
    if DataModel.bInSearch then
		self:UpdateSearchItemList()
	elseif DataModel.nCurSubgroup ~= Homeland_GetNullSubgroupID() and #DataModel.tCurSubgroupList[DataModel.nCurSubgroup] > 1 then
		self:UpdateSubgroupItemList()
	else
		self:UpdateNormalItemList()
	end
end

function UIHomelandBuildFurnitureList:UpdateSubgroupItemList()
	local nQuality = 1
	local tCurItemList = DataModel.tCurSubgroupList[DataModel.nCurSubgroup]

	self.tbSubgroupItemCells = self.tbSubgroupItemCells or {}
	UIHelper.HideAllChildren(self.ScrollViewConstructionItemList)
	for i = 1, #tCurItemList do
		local tInfo = tCurItemList[i]
        local cell = self.tbSubgroupItemCells[i]
		if not cell then
			cell = UIHelper.AddPrefab(PREFAB_ID.WidgetConstructionItem, self.ScrollViewConstructionItemList)
			self.tbSubgroupItemCells[i] = cell
		end
		UIHelper.SetVisible(cell._rootNode, true)
        cell:OnEnter(DataModel, tInfo, false)
	end

	UIHelper.SetVisible(self.WidgetSubList, true)
	UIHelper.SetVisible(self.WidgetMainList, false)
	UIHelper.SetVisible(self.WidgetEmpty, #tCurItemList <= 0)

	if DataModel.bNeedScrollToLeft then
		UIHelper.ScrollViewDoLayout(self.ScrollViewConstructionItemList)
    	UIHelper.ScrollToLeft(self.ScrollViewConstructionItemList, 0)
		DataModel.bNeedScrollToLeft = false
	end
end

function UIHomelandBuildFurnitureList:UpdateNormalItemList()
	local tCurItemList = DataModel.tCurItemList
	local nQuality = 1

	self.tbItemCells = self.tbItemCells or {}
	UIHelper.HideAllChildren(self.ScrollViewMainItemList)
	for i = 1, #tCurItemList do
		local tInfo = tCurItemList[i]
        local cell = self.tbItemCells[i]
		if not cell then
			cell = UIHelper.AddPrefab(PREFAB_ID.WidgetConstructionItem, self.ScrollViewMainItemList)
			self.tbItemCells[i] = cell
		end
		UIHelper.SetVisible(cell._rootNode, true)
        cell:OnEnter(DataModel, tInfo, true)
	end

	UIHelper.SetVisible(self.WidgetSubList, false)
	UIHelper.SetVisible(self.WidgetMainList, true)
	UIHelper.SetVisible(self.WidgetEmpty, #tCurItemList <= 0)

	if DataModel.bNeedScrollToLeft then
		UIHelper.ScrollViewDoLayout(self.ScrollViewMainItemList)
    	UIHelper.ScrollToLeft(self.ScrollViewMainItemList, 0)
		DataModel.bNeedScrollToLeft = false
	end
end

function UIHomelandBuildFurnitureList:UpdateSearchItemList()
	local tCurItemList = DataModel.tSearchItemList

	self.tbItemCells = self.tbItemCells or {}
	UIHelper.HideAllChildren(self.ScrollViewMainItemList)
	for i = 1, #tCurItemList do
		local tInfo = tCurItemList[i]
        local cell = self.tbItemCells[i]
		if not cell then
			cell = UIHelper.AddPrefab(PREFAB_ID.WidgetConstructionItem, self.ScrollViewMainItemList)
			self.tbItemCells[i] = cell
		end
		UIHelper.SetVisible(cell._rootNode, true)
        cell:OnEnter(DataModel, tInfo, false)
	end

	UIHelper.SetVisible(self.WidgetSubList, false)
	UIHelper.SetVisible(self.WidgetMainList, true)
	UIHelper.SetVisible(self.WidgetEmpty, #tCurItemList <= 0)
    UIHelper.ScrollViewDoLayout(self.ScrollViewMainItemList)
    UIHelper.ScrollToLeft(self.ScrollViewMainItemList, 0)
end

function UIHomelandBuildFurnitureList:UpdateBrushEditor()
	UIHelper.SetVisible(self.WidgetVegetationBrush, false)
	UIHelper.SetVisible(self.WidgetGroundBrush, false)

	if not HLBOp_Enter.IsTenant() and DataModel.nCurCatg1Index == Homeland_GetCustomBrushCatg1Index() then
		if DataModel.nCurCatg2Index == Homeland_GetFlowerBrushCatg2Index() then
			HomelandCustomBrushData.EnterFlowerBrush()
			UIHelper.SetVisible(self.WidgetVegetationBrush, true)

			if not self.scriptFlowerBrush then
				self.scriptFlowerBrush = UIHelper.GetBindScript(self.WidgetVegetationBrush)
			end
			self.scriptFlowerBrush:OnEnter()
		elseif DataModel.nCurCatg2Index == Homeland_GetFloorBrushCatg2Index() then
			HomelandCustomBrushData.EnterFloorBrush()
			UIHelper.SetVisible(self.WidgetGroundBrush, true)

			if not self.scriptFloorBrush then
				self.scriptFloorBrush = UIHelper.GetBindScript(self.WidgetGroundBrush)
			end
			self.scriptFloorBrush:OnEnter()
		end
	else
		HomelandCustomBrushData.Close()
	end
end

function UIHomelandBuildFurnitureList:DelayUpdateItemList()
	if self.nUpdateDataTimerID then
		Timer.DelTimer(self, self.nUpdateDataTimerID)
		self.nUpdateDataTimerID = nil
	end
	self.nUpdateDataTimerID = Timer.Add(self, 0.5, function ()
		DataModel.UpdateCurItemList()
		self:UpdateItemList()
	end)
end

function UIHomelandBuildFurnitureList:DelayUpdateCatg()
	if self.nUpdateCatgDataTimerID then
		Timer.DelTimer(self, self.nUpdateCatgDataTimerID)
		self.nUpdateCatgDataTimerID = nil
	end
	self.nUpdateCatgDataTimerID = Timer.Add(self, 0.5, function ()
		self:UpdateCatg1List()
		self:UpdateCatg2List()
	end)
end

function UIHomelandBuildFurnitureList:UpdateHotKeyBtn()
	UIHelper.SetVisible(self.BtnHotKeys, HomelandBuildData.GetInputType() == HLB_INPUT_TYPE.MAK)
end

function UIHomelandBuildFurnitureList:LocateFurniture(nCatg1Index, nCatg2Index, nSubgroupID, dwModelID)
	DataModel.nCurCatg1Index = nCatg1Index
	DataModel.nCurCatg2Index = nCatg2Index
	DataModel.nCurSubgroup = nSubgroupID

	local bSameList = false
	local nSelectedIndex = table.get_key(TogFirstIndex2Type, nCatg1Index)
	UIHelper.SetToggleGroupSelected(self.TogGroupFatherType, nSelectedIndex - 1)
	DataModel.UpdateCurItemList()

	if DataModel.tLastTaken.dwModelID == dwModelID then
		bSameList = true
	else
		DataModel.tLastTaken.dwModelID = dwModelID
	end

	self:UpdateCatg1List()
	self:UpdateCatg2List()
	self:UpdateItemList()

	local function _doLocate(nIndex, scrollview, bSameList)
		Timer.Add(self, 0.1, function ()
			UIHelper.ScrollViewDoLayout(self.ScrollViewMainItemList)
			UIHelper.ScrollViewDoLayout(self.ScrollViewConstructionItemList)
			UIHelper.ScrollToIndex(scrollview, nIndex - 1, bSameList and 0 or 0.5, true)
		end)
	end

	local bShowSubGroup = DataModel.nCurSubgroup ~= Homeland_GetNullSubgroupID() and #DataModel.tCurSubgroupList[DataModel.nCurSubgroup] > 1
	local tbScriptList = bShowSubGroup and self.tbSubgroupItemCells or self.tbItemCells
	local scrollview = bShowSubGroup and self.ScrollViewConstructionItemList or self.ScrollViewMainItemList
	for i, cell in ipairs(tbScriptList) do
		if cell:FindModelID(dwModelID) then
			if not bSameList then
				UIHelper.ScrollToLeft(scrollview, 0)
			end
			UIHelper.SetVisible(cell.ImgUp, true)
			_doLocate(i, scrollview, bSameList)
			break
		end
	end
end

function UIHomelandBuildFurnitureList:ScrollOnePage(bAdd)
	local layout = self.ScrollViewMainItemList:getInnerContainer()
    if not layout then
        return
    end

    local nLayoutWidth, _ = UIHelper.GetContentSize(layout)
    local nScreenWidth, _ = UIHelper.GetContentSize(self.ScrollViewMainItemList)
    local nOnePagePercent = nScreenWidth / nLayoutWidth * 100

    local nCurPercent = UIHelper.GetScrollPercent(self.ScrollViewMainItemList)
    local nNewPercent
    if bAdd then
        nNewPercent = nCurPercent + nOnePagePercent
    else
        nNewPercent = nCurPercent - nOnePagePercent
    end
    if nNewPercent <= 1 then    --nOnePagePercent不被整数，接近直接到底
        UIHelper.ScrollToPercent(self.ScrollViewMainItemList, 0)
    elseif nNewPercent >= 99 then
        UIHelper.ScrollToPercent(self.ScrollViewMainItemList, 100)
    else
        UIHelper.ScrollToPercent(self.ScrollViewMainItemList, nNewPercent)
    end
end

return UIHomelandBuildFurnitureList