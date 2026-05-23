-- Author:	Jiang Zhenghao
-- Date:	2020-07-09
-- Version:	1.0
-- Description:	家园基础脚本，用于处理全局事件、处理远程调用等（引用了策划脚本\scripts\Map\家园系统客户端\include\HomelandCommon.lua）
----------------------------------------------------------------------
NewModule("HomelandEventHandler")
----------------------------------------------------------------------

function GetMaxLandLevel()
	return 16 -- 来自逻辑
end

local APPLY_SET_COLLECTION_TIME = 5

----------------------------↓↓↓家园消息↓↓↓----------------------------
local bRequestingSelfHouseInfo = false
local m_userdata1, m_userdata2 = nil, nil
local m_nPlayerLastLandIndex = 0
local m_bPlayerLastLandIsMine = false

function RequestSelfHouseInfo(userdata1, userdata2)
	LOG.INFO("=== 调用了 RequestSelfHouseInfo()")
	GetHomelandMgr().ApplyEstateToHS() -- 据说这个会把共居信息给覆盖掉；后来被逻辑改得不会了
	bRequestingSelfHouseInfo = true
	m_userdata1 = userdata1
	m_userdata2 = userdata2
end

local function OnGetSelfHouseInfo()
	local aNolandHouses = {}
	local homelandMgr = GetHomelandMgr()
	local aMyHouseIDs = homelandMgr.GetAllMyHouse() or {}
	local nMyHouseCnt = #aMyHouseIDs
	local aMyLandInfos = homelandMgr.GetAllMyLand() or {}

	for _, szHouseID in ipairs(aMyHouseIDs) do
		if FindTableValueByKey(aMyLandInfos, "uHouseID", szHouseID) then
			-- Do nothing
		else
			table.insert(aNolandHouses, szHouseID)
		end
	end

	RemoteCallToServer("On_HomeLand_GetNolandHouses", nMyHouseCnt, aNolandHouses, m_userdata1, m_userdata2)

	bRequestingSelfHouseInfo = false
	m_userdata1 = nil
	m_userdata2 = nil
end

local aIgnoredHomeRetCodes =
{
	[HOMELAND_RESULT_CODE.APPLY_LAND_INFO] = 1,
	[HOMELAND_RESULT_CODE.APPLY_COMMUNITY_DIGEST] = 2,
	[HOMELAND_RESULT_CODE.APPLY_COMMUNITY_INFO] = 3,
	[HOMELAND_RESULT_CODE.APPLY_COMMUNITY_RANK] = 4,
	[HOMELAND_RESULT_CODE.BUY_LAND_SUCCEED] = 5, -- 土地购买成功 (dwMapID, CopyIndex, LandIndex)
	[HOMELAND_RESULT_CODE.PEEK_LAND_SUCCEED] = 6, -- 获取土地数据成功，对象为
	[HOMELAND_RESULT_CODE.PEEK_HOUSE_SUCCEED] = 7, -- 获取房屋数据成功，对象为
}

local function fnOnHomeRetCode()
	--LOG.INFO("==== 响应了事件 HOME_LAND_RESULT_CODE，返回码是：" .. tostring(arg0))
	local nResultType = arg0
	local szMsg
	local bShowInEditBox = true
	if aIgnoredHomeRetCodes[nResultType] then
		-- Do nothing
	elseif nResultType == HOMELAND_RESULT_CODE.LAND_BUILD_LOCK_SUCCEED then -- 特殊处理
		-- if HLBOp_Base.IsInCohabit() then
		-- 	OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tHomelandBuildingSuccessNotify[nResultType])
		-- else
		-- 	return
		-- end
	elseif g_tStrings.tHomelandBuildingSuccessNotify[nResultType] then
		szMsg = g_tStrings.tHomelandBuildingSuccessNotify[nResultType]
		OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
	elseif g_tStrings.tHomelandBuildingFailureNotify[nResultType] then
		szMsg = g_tStrings.tHomelandBuildingFailureNotify[nResultType]
		OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
	else
		--LOG.INFO("ERROR! 未被识别的家园操作错误码！ (" .. tostring(nErrorCode) .. ")")
	end

	if szMsg then
		LOG.INFO(szMsg)
		if bShowInEditBox then
			OutputMessage("MSG_SYS", szMsg .. "\n")
		end
	end

	if nResultType == HOMELAND_RESULT_CODE.TASK_FAILED_SD_SIZE_EXCEED_LIMIT
		or nResultType == HOMELAND_RESULT_CODE.TASK_FAILED_LAND_OBJECT_SIZE_EXCEED_LIMIT then
		local szLog = "【ERROR】 请策划检查\"scripts\\Map\\家园系统客户端\\include\\Home_BuildLandObjectModels.lua\"的配置是否有遗漏！"
		if IsDebugClient() and not IsVersionExp() then
			OutputMessage("MSG_SYS", szLog .. "\n")
		end
		LOG.INFO(szLog)
	end

	if nResultType == HOMELAND_RESULT_CODE.APPLY_ESTATE_SUCCEED or nResultType == HOMELAND_RESULT_CODE.APPLY_ESTATE_TO_HS_SUCCEED then -- 重要：先统一处理，后面再做出区分
		LOG.INFO("==== 响应了事件 HOME_LAND_RESULT_CODE，返回码是： ")
		LOG.INFO(nResultType == HOMELAND_RESULT_CODE.APPLY_ESTATE_SUCCEED and "HOMELAND_RESULT_CODE.APPLY_ESTATE_SUCCEED" or "HOMELAND_RESULT_CODE.APPLY_ESTATE_TO_HS_SUCCEED")
		if bRequestingSelfHouseInfo then
			OnGetSelfHouseInfo()
		end
		local dwMapID, nCopyIndex, nCenterID, nIndex = arg1, arg2, arg3, arg4
		CheckMyHomeLand(dwMapID, nCopyIndex)

	elseif nResultType == HOMELAND_RESULT_CODE.APPLY_LAND_SUCCEED then
		LOG.INFO("==== 响应了事件 HOME_LAND_RESULT_CODE，返回码是： HOMELAND_RESULT_CODE.APPLY_LAND_SUCCEED")
	elseif nResultType == HOMELAND_RESULT_CODE.BUY_HOUSE_SUCCEED then
		LOG.INFO("==== 响应了事件 HOME_LAND_RESULT_CODE，返回码是： HOMELAND_RESULT_CODE.BUY_HOUSE_SUCCEED")
		RequestSelfHouseInfo()
	elseif nResultType == HOMELAND_RESULT_CODE.ABANDON_LAND_SUCCESS then
		LOG.INFO("==== 丢弃土地成功")
		GetHomelandMgr().ApplyEstateToHS()
	elseif nResultType == HOMELAND_RESULT_CODE.CLIENT_READY then
		LOG.INFO("==== 接收到了 CLIENT_READY 的事件")
		HouseUpgradeApplyData()
	elseif nResultType == HOMELAND_RESULT_CODE.TASK_BUILDING_SUCCEED then
		if Homeland_IsInBuildingTeachingQuest() then
			RemoteCallToServer("On_HomeLand_BuildSuccessful")
		end
	end
end


local function fnOnHomeRetCodeInt()
	local nRetCode = arg0
	local szMsg
	local bShowInEditBox = true
	if aIgnoredHomeRetCodes[nRetCode] then
		-- Do nothing
	elseif nRetCode == HOMELAND_RESULT_CODE.PEEK_LAND_SUCCEED then
		szMsg = g_tStrings.tHomelandBuildingFailureNotify[nRetCode] .. " " .. arg1
		OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
	elseif nRetCode == HOMELAND_RESULT_CODE.PEEK_HOUSE_SUCCEED then
		szMsg = g_tStrings.tHomelandBuildingFailureNotify[nRetCode] .. " " .. arg1
		OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
	elseif nRetCode == HOMELAND_RESULT_CODE.PEEK_ROLE_NO_LAND then
		szMsg = g_tStrings.tHomelandBuildingFailureNotify[nRetCode] .. " " .. arg1
		OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
	elseif nRetCode == HOMELAND_RESULT_CODE.PEEK_ROLE_NO_HOUSE then
		szMsg = g_tStrings.tHomelandBuildingFailureNotify[nRetCode] .. " " .. arg1
		OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
	elseif nRetCode == HOMELAND_RESULT_CODE.INSTALL_HOUSE_SUCCEED then
		--安装房屋
		HouseUpgradeApplyData()
	elseif nRetCode == HOMELAND_RESULT_CODE.BUY_FURNITURE_SUCCEED then
		local dwCustomData = arg1
		-- 待补充
		LOG.INFO("==== 收到了返回码 HOMELAND_RESULT_CODE.BUY_FURNITURE_SUCCEED，自定义参数是：" .. tostring(dwCustomData))
	elseif nRetCode == HOMELAND_RESULT_CODE.PLAYER_COST_FURNITURE_FAILED then
		local dwID, nDiffCnt = arg1, arg2
		local szName
		local tInfo = FurnitureData.GetFurnInfoByTypeAndID(HS_FURNITURE_TYPE.FURNITURE, dwID)
		szName = tInfo and GBKToUTF8(tInfo.szName) or ("找不到家具！(id: " .. tostring(dwID) .. ")")
		if nDiffCnt < 0 then
			szMsg = FormatString(g_tStrings.tHomelandBuildingFailureNotify[nRetCode][1], szName, -nDiffCnt)
		else
			szMsg = FormatString(g_tStrings.tHomelandBuildingFailureNotify[nRetCode][2], szName, nDiffCnt)
		end
		OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
		LOG.INFO(szMsg)
	elseif nRetCode == HOMELAND_RESULT_CODE.NEED_BUY_PENDANT_FURNITURE or
		nRetCode == HOMELAND_RESULT_CODE.NEED_BUY_APPLIQUE_BRUSH or
		nRetCode == HOMELAND_RESULT_CODE.NEED_BUY_FOLIAGE_BRUSH then
		local dwID = arg1
		local nType = HS_FURNITURE_TYPE.PENDANT
		if nRetCode == HOMELAND_RESULT_CODE.NEED_BUY_APPLIQUE_BRUSH then
			nType = HS_FURNITURE_TYPE.APPLIQUE_BRUSH
		elseif nRetCode == HOMELAND_RESULT_CODE.NEED_BUY_FOLIAGE_BRUSH then
			nType = HS_FURNITURE_TYPE.FOLIAGE_BRUSH
		end
		local szName
		local tInfo = FurnitureData.GetFurnInfoByTypeAndID(HS_FURNITURE_TYPE.PENDANT, dwID)
		szName = tInfo and GBKToUTF8(tInfo.szName) or ("找不到家具！(id: " .. tostring(dwID) .. ")")
		szMsg = FormatString(g_tStrings.tHomelandBuildingFailureNotify[nRetCode], szName)
		OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
		LOG.INFO(szMsg)
	elseif nRetCode == HOMELAND_RESULT_CODE.DOWNLOAD_DIGITAL_BLP_RESPOND then
		local nErrorCode = arg1
		szMsg = g_tStrings.tHomelandBuildingFailureNotify[nRetCode] .. " " .. nErrorCode
		OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
	elseif nRetCode == HOMELAND_RESULT_CODE.SELL_DIGITAL_BLP_RESPOND then
		local nErrorCode = arg1
		szMsg = "寄售蓝图响应： " .. nErrorCode
		OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
	else
		--UILOG.INFO("ERROR! 未被识别的家园操作错误码！ (" .. tostring(nErrorCode) .. ")")
	end

	if szMsg and bShowInEditBox then
		OutputMessage("MSG_SYS", szMsg .. "\n")
		LOG.INFO(szMsg)
	end

	if nRetCode == HOMELAND_RESULT_CODE.BUY_LAND_SUCCEED then
		local dwMapID, nCopyIndex, nLandIndex = arg1, arg2, arg3
		UIMgr.Open(VIEW_ID.PanelHomeContractPop, dwMapID, nCopyIndex, nLandIndex)
		RemoteCallToServer("On_HomeLand_DoBuyLand", dwMapID, nCopyIndex, nLandIndex)
	elseif nRetCode == HOMELAND_RESULT_CODE.APPLY_COMMUNITY_INFO then
		local dwMapID, nCopyIndex, nCenterID, nIndex = arg1, arg2, arg3, arg4
		CheckMyHomeLand(dwMapID, nCopyIndex)
	elseif nRetCode == HOMELAND_RESULT_CODE.ALLIED_INFO_CHANGE then
		LOG.INFO("=== 响应了事件 HOMELAND_RESULT_CODE.ALLIED_INFO_CHANGE")
		LOG.INFO("=== 玩家名字是： " .. tostring(GetClientPlayer().szName))
		local dwMapID, nCopyIndex, nLandIndex, nNoticeType = arg1, arg2, arg3, arg4
		if nNoticeType == HOMELAND_RESULT_CODE.ALLIED_CHANGE_BY_ADD then
			LOG.INFO("==== 并且操作类型是【建立】！")
		elseif nNoticeType == HOMELAND_RESULT_CODE.ALLIED_CHANGE_BY_DELETE then
			LOG.INFO("==== 并且操作类型是【解除】！")
		elseif nNoticeType == HOMELAND_RESULT_CODE.ALLIED_CHANGE_BY_OTHER then
			LOG.INFO("==== 并且操作类型是【更新】！")
		else
			LOG.INFO("==== 并且操作类型无效！")
		end
		GetHomelandMgr().ApplyEstate()
		GetHomelandMgr().ApplyMyLandInfo(nLandIndex)
	elseif nRetCode == HOMELAND_RESULT_CODE.PLAYER_MOVE then
		local bIsInMyLand, nLandIndex = arg1 ~= 0, arg2
		LOG.INFO("==== 响应了事件 PLAYER_MOVE，参数 bIsInMyLand, nLandIndex == %s  %d", tostring(bIsInMyLand), nLandIndex)
		local scene = GetClientScene()
		local bShow = scene and HomelandData.IsHomelandMap(scene.dwMapID)
		if nLandIndex > 0 then
			-- if bIsInMyLand then
			-- 	bShow = true
			-- elseif m_bPlayerLastLandIsMine then
			-- 	bShow = false
			-- end

			bShow = true
			m_nPlayerLastLandIndex = nLandIndex
			m_bPlayerLastLandIsMine = bIsInMyLand
		else
			-- if m_bPlayerLastLandIsMine then
				-- bShow = false
			-- end
			m_nPlayerLastLandIndex = 0
		end

		Event.Dispatch(EventType.OnUpdateHomelandEntranceState, bShow)
	end
end
----------------------------↑↑↑家园消息↑↑↑----------------------------

----------家园宠物、种植等小游戏相关-----------------
local function OnHouseGame()
	LoadScriptFile(UIHelper.UTF8ToGBK("scripts/Map/家园系统客户端/Include/Home_MiniGameCommonFunction.lua"), HomelandEventHandler)
	LoadScriptFile(UIHelper.UTF8ToGBK("scripts/Map/家园系统/include/家园烹饪参数.lua"), HomelandEventHandler)
	LoadScriptFile(UIHelper.UTF8ToGBK("scripts/Map/家园系统/include/酿酒头文件.lua"), HomelandEventHandler)

	HomelandEventHandler.LandObject_GetSaveTimeText = function(nTime)
		local t = TimeToDate(nTime)
		local szText = FormatString(g_tStrings.STR_TIME_1, t.year, t.month, t.day)
		return UIHelper.UTF8ToGBK(szText)
	end

	HomelandEventHandler.LandObject_GetSaveTimeText2 = function(nTime)
		local t = TimeToDate(nTime)
		local szText = FormatString(g_tStrings.STR_TIME_10, t.month, t.day, t.hour)
		return UIHelper.UTF8ToGBK(szText)
	end

	-- HomelandEventHandler.GetAlcoholRecipe = function()
	-- 	return tAlcoholRecipe
	-- end

	-- HomelandEventHandler.GettRecipes = function()
	-- 	return tRecipes
	-- end

	local dwMapID, nCopyIndex, nLandIndex, nDataType, nDataPos = arg0, arg1, arg2, arg3, arg4
	local nFurnitureInstanceID, tFurnitureInfo, tPosInfo = arg5, arg6, arg7
	-- from scripts\Map\家园系统客户端\Include\Home_MiniGameCommonFunction.lua
	HomelandEventHandler.LandObject_OpenMiniGameUIView(dwMapID, nCopyIndex, nLandIndex, nDataType, nDataPos, nFurnitureInstanceID, tFurnitureInfo, tPosInfo)
end
------------------家园升级相关----------------------------
--------------------------------------------------------
local m_bWaitingForUpdateFrameVisible = false

function HouseUpgradeApplyData()
	--LOG.INFO("==== 调用了函数 HouseUpgradeApplyData()")
	local scene = GetClientScene()
	if not scene then
		return
	end
	local dwMapID, nCopyIndex = scene.dwMapID, scene.nCopyIndex
	--LOG.INFO("==== dwMapID, nCopyIndex ==")
	--UILOG.INFO(dwMapID, nCopyIndex)
	local bHomelandCommunityMap = IsHomelandCommunityMap(dwMapID)
	--LOG.INFO("==== bHomelandCommunityMap == " .. tostring(bHomelandCommunityMap))
	if bHomelandCommunityMap then
		local pHomelandMgr = GetHomelandMgr()
		pHomelandMgr.ApplyEstate()
		pHomelandMgr.ApplyCommunityInfo(dwMapID, nCopyIndex)
		m_bWaitingForUpdateFrameVisible = true

		--LOG.INFO("==== 刚刚调用了 ApplyEstate() 和 ApplyCommunityInfo()")
	else
		Event.Dispatch(EventType.OnUpdateHomelandEntranceState, false)
	end
end

function CheckMyHomeLand(dwMapID, nCopyIndex)
	if m_bWaitingForUpdateFrameVisible then
		if not dwMapID then
			local scene = GetClientScene()
			dwMapID, nCopyIndex = scene.dwMapID, scene.nCopyIndex
		end

		local pHomelandMgr = GetHomelandMgr()
		local tCommunityInfo = pHomelandMgr.GetCommunityInfo(dwMapID, nCopyIndex)
		local aMyHouseIDs = pHomelandMgr.GetAllMyHouse()
		if not tCommunityInfo or not aMyHouseIDs or #aMyHouseIDs < 1 then
			return
		end

		local tMyHousedLandPos = {}
		for nLandIndex = 1, tCommunityInfo.nLandCount do
			local bMyLand = pHomelandMgr.IsMyLand(dwMapID, nCopyIndex, nLandIndex)
			if bMyLand then
				local tInfo = pHomelandMgr.GetHLLandInfo(nLandIndex) or {}
				local szHouseID = tInfo.uHouseID
				if szHouseID ~= "0" and CheckIsInTable(aMyHouseIDs, szHouseID) then
					table.insert(tMyHousedLandPos, {dwMapID, nCopyIndex, nLandIndex})
				end
			end
		end

		if #tMyHousedLandPos > 0 then
			RemoteCallToServer("On_Home_FindMyLand", tMyHousedLandPos)
		end

		m_bWaitingForUpdateFrameVisible = false
	end
end

function HomelandUpgradeResult(dwMapID, nCopyIndex, nLandIndex, nCode, nCurrLevel, nOldLevel)
	if nCode == 0 then --失败
		OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_HOMELAND_UPGRADE_FAILED)
	elseif nCode == 1 then 	--成功
		FireUIEvent("HOMELAND_UPGRADE_SUCCESS", dwMapID, nCopyIndex, nLandIndex, nCurrLevel, nOldLevel)
	end
end

------------------------------ ↓↓↓↓ 家具获取相关 ------------------------------

local function ShowMsgInChatPanel(nType, dwID, nNum)
	local szMsg = g_tStrings.STR_FURNITURE_ADD_FURNITURE_SUCCESS
	local tInfo = FurnitureData.GetFurnInfoByTypeAndID(nType, dwID)
	local tRGB = Homeland_GetFurnitureRGBByQuality(tInfo.nQuality)
	local szFont = FormatString("font=10 r=<D0> g=<D1> b=<D2>", tRGB[1], tRGB[2], tRGB[3])
	local szItemName = string.format("<color=#%02X%02X%02X>【%s】</color>", tRGB[1], tRGB[2], tRGB[3], UIHelper.GBKToUTF8(tInfo.szName))
	szMsg = szMsg .. string.format("%s x %d", szItemName, nNum)
	OutputMessage("MSG_NORMAL", szMsg, true)
	-- szMsg = GetFormatText(g_tStrings.STR_FURNITURE_ADD_FURNITURE_SUCCESS, 10, 170, 150, 30) ..  MakeFurnitureLink(UIHelper.GBKToUTF8(tInfo.szName), szFont, nType, dwID) .. GetFormatText(" × " .. nNum .. "\n", 10, 170, 150, 30)
	OutputMessage("MSG_SYS", szMsg, true)
end

local m_aNewlyGotFurniture =
{
	--dwFurnitureID,
}

local m_aNewlyGotFlowerBrush =
{
	--dwFurnitureID,
}

local m_aNewlyGotFloorBrush =
{
	--dwFurnitureID,
}

local m_aNewlyGotPendant =
{
	--dwFurnitureID,
}

function InitAllNewlyGotData()
	m_aNewlyGotFurniture = {}
	m_aNewlyGotFlowerBrush = {}
	m_aNewlyGotFloorBrush = {}
	m_aNewlyGotPendant = {}
end

function GetAllNewlyGotFurniture()
	return m_aNewlyGotFurniture
end

function GetAllNewlyGotFlowerBrush()
	return m_aNewlyGotFlowerBrush
end

function GetAllNewlyGotFloorBrush()
	return m_aNewlyGotFloorBrush
end

function GetAllNewlyGotPendant()
	return m_aNewlyGotPendant
end

function IsItemNewlyGot(dwFurnitureID)
	return CheckIsInTable(m_aNewlyGotFurniture, dwFurnitureID)
end

function IsFlowerBrushNewlyGot(dwFurnitureID)
	return CheckIsInTable(m_aNewlyGotFlowerBrush, dwFurnitureID)
end

function IsFloorBrushNewlyGot(dwFurnitureID)
	return CheckIsInTable(m_aNewlyGotFloorBrush, dwFurnitureID)
end

function IsPendantNewlyGot(dwFurnitureID)
	return CheckIsInTable(m_aNewlyGotPendant, dwFurnitureID)
end

local function _AddOneNewlyGotItem(dwFurnitureID)
	if not CheckIsInTable(m_aNewlyGotFurniture, dwFurnitureID) then
		local tInfo = FurnitureData.GetFurnInfoByTypeAndID(HS_FURNITURE_TYPE.FURNITURE, dwFurnitureID)
		if tInfo then
			table.insert(m_aNewlyGotFurniture, dwFurnitureID)
			FireUIEvent("LUA_HOMELNAD_UPDATE_REDPONIT", HS_FURNITURE_TYPE.FURNITURE, dwFurnitureID)
		end
	end
end

function RemoveOneNewlyGotItem(dwFurnitureID)
	local nIndex = FindTableValue(m_aNewlyGotFurniture, dwFurnitureID)
	if nIndex then
		table.remove(m_aNewlyGotFurniture, nIndex)
	end
end

function RemoveOneNewlyGotFlowerBrush(dwFurnitureID)
	local nIndex = FindTableValue(m_aNewlyGotFlowerBrush, dwFurnitureID)
	if nIndex then
		table.remove(m_aNewlyGotFlowerBrush, nIndex)
	end
end

function RemoveOneNewlyGotFloorBrush(dwFurnitureID)
	local nIndex = FindTableValue(m_aNewlyGotFloorBrush, dwFurnitureID)
	if nIndex then
		table.remove(m_aNewlyGotFloorBrush, nIndex)
	end
end

function RemoveOneNewlyGotPendant(dwFurnitureID)
	local nIndex = FindTableValue(m_aNewlyGotPendant, dwFurnitureID)
	if nIndex then
		table.remove(m_aNewlyGotPendant, nIndex)
	end
end

local function fnOnFurnitureChange()
	local dwFurnitureID, nPreAmount, nCurAmount, eFrom = arg0, arg1, arg2, arg3

	local nDiff = nCurAmount - nPreAmount
	if eFrom == HOMELAND_ACQUIRE_FURNITURE_CODE.BUY or
	eFrom == HOMELAND_ACQUIRE_FURNITURE_CODE.ITEM or
	eFrom == HOMELAND_ACQUIRE_FURNITURE_CODE.SCRIPT then
		_AddOneNewlyGotItem(dwFurnitureID)
		if nDiff > 0 then
			ShowMsgInChatPanel(HS_FURNITURE_TYPE.FURNITURE, dwFurnitureID, nDiff)
		end
	end

	if nCurAmount <= 0 then
		RemoveOneNewlyGotItem(dwFurnitureID)
	end

	--[[if HomelandEventHandler.nApplySetCollectionDataTimerID then
		Timer.DelTimer(HomelandEventHandler, HomelandEventHandler.nApplySetCollectionDataTimerID)
		HomelandEventHandler.nApplySetCollectionDataTimerID = nil
	end
	HomelandEventHandler.nApplySetCollectionDataTimerID = Timer.Add(HomelandEventHandler, 0.5, function ()
		ApplySetCollectionData()
	end)]]
end

local function fnOnPendantFurnitureChange()
	local dwPendantID, bAdd = arg0, arg1
	if bAdd and (not CheckIsInTable(m_aNewlyGotPendant, dwPendantID))then
		local tInfo = FurnitureData.GetFurnInfoByTypeAndID(HS_FURNITURE_TYPE.PENDANT, dwPendantID)
		if tInfo then
			table.insert(m_aNewlyGotPendant, dwPendantID)
			FireUIEvent("LUA_HOMELNAD_UPDATE_REDPONIT", HS_FURNITURE_TYPE.PENDANT, dwPendantID)
		end
	end
	if bAdd then
		ShowMsgInChatPanel(HS_FURNITURE_TYPE.PENDANT, dwPendantID, 1)
	end
end

local function fnOnBrushChange()
	local nBrushType, nBrushID, bAdd = arg0, arg1, arg2
	if nBrushType == HS_FURNITURE_TYPE.APPLIQUE_BRUSH and (not CheckIsInTable(m_aNewlyGotFloorBrush, nBrushID)) then
		local tInfo = FurnitureData.GetFurnInfoByTypeAndID(HS_FURNITURE_TYPE.APPLIQUE_BRUSH, nBrushID)
		if tInfo then
			table.insert(m_aNewlyGotFloorBrush, nBrushID)
			FireUIEvent("LUA_HOMELNAD_UPDATE_REDPONIT", HS_FURNITURE_TYPE.APPLIQUE_BRUSH, nBrushID)
		end
	end

	if nBrushType == HS_FURNITURE_TYPE.FOLIAGE_BRUSH and (not CheckIsInTable(m_aNewlyGotFlowerBrush, nBrushID)) then
		local tInfo = FurnitureData.GetFurnInfoByTypeAndID(HS_FURNITURE_TYPE.FOLIAGE_BRUSH, nBrushID)
		if tInfo then
			table.insert(m_aNewlyGotFlowerBrush, nBrushID)
			FireUIEvent("LUA_HOMELNAD_UPDATE_REDPONIT", HS_FURNITURE_TYPE.FOLIAGE_BRUSH, nBrushID)
		end
	end

	if bAdd then
		ShowMsgInChatPanel(nBrushType, nBrushID, 1)
	end
end

function GetFurniturePriceInArchitecture(dwID, bModelID, nAmount)
	local dwFurnitureID
	if bModelID then
		local nType, dwTheFurnitureID = FurnitureData.GetFurnTypeAndIDByModelID(dwID)
		if nType ~= HS_FURNITURE_TYPE.FURNITURE then
			LOG.INFO("ERROR! 尝试获取挂件类型家具的资源点！")
			return 0
		else
			dwFurnitureID = dwTheFurnitureID
		end
	else
		dwFurnitureID = dwID
	end
	local pHomelandMgr = GetHomelandMgr()
	local tConfig = pHomelandMgr.GetFurnitureConfig(dwFurnitureID)
	return tConfig.nArchitecture * nAmount, dwFurnitureID
end

local _MAX_AUTO_BUY_MONEY = 2000

FURNITURE_CANT_BUY_REASON =
{
	NOT_BY_ARCHITECTURE = 1,
	LEVEL_TOO_HIGH = 2,
	MONEY_NOT_ENOUGH = 3,
	TOO_MUCH_FOR_AUTO_BUY = 4,
}

-- 返回： bCanBuy, eCantBuyReason
function CanBuyFurnitureWithArchitecture(dwID, bModelID, nAmount, bAutoBuy)
	local nRequiredArchitecture, dwFurnitureID = GetFurniturePriceInArchitecture(dwID, bModelID, nAmount)
	local player = GetClientPlayer()
	if nRequiredArchitecture == 0 then
		return false, FURNITURE_CANT_BUY_REASON.NOT_BY_ARCHITECTURE
	-- elseif (HLBOp_Base.GetLandLevel() or 1) < GetHomelandMgr().GetFurnitureConfig(dwFurnitureID).nLevelLimit then
	-- 	return false, FURNITURE_CANT_BUY_REASON.LEVEL_TOO_HIGH
	elseif player.nArchitecture < nRequiredArchitecture then
		return false, FURNITURE_CANT_BUY_REASON.MONEY_NOT_ENOUGH
	elseif bAutoBuy and nRequiredArchitecture > _MAX_AUTO_BUY_MONEY then
		return false, FURNITURE_CANT_BUY_REASON.TOO_MUCH_FOR_AUTO_BUY
	else
		return true
	end
end

function CanDismantleFurniture(dwID, bModelID, nAmount)
	local nCurAmount
	local dwFurnitureID
	if bModelID then
		local nType
		nType, dwFurnitureID = FurnitureData.GetFurnTypeAndIDByModelID(dwID)
		assert(nType == HS_FURNITURE_TYPE.FURNITURE)
	else
		dwFurnitureID = dwID
	end

	nCurAmount = GetHomelandMgr().GetFurniture(dwFurnitureID)

	return nCurAmount >= nAmount
end

function GetPendantPriceInMoney(dwID, bModelID)
	local dwPendantID
	if bModelID then
		local nType, dwTheFurnitureID = FurnitureData.GetFurnTypeAndIDByModelID(dwID)
		if nType ~= HS_FURNITURE_TYPE.PENDANT then
			LOG.INFO("ERROR! GetPendantPriceInMoney()参数对应的是普通类型家具！")
			return 0
		else
			dwPendantID = dwTheFurnitureID
		end
	else
		dwPendantID = dwID
	end
	return GetHomelandMgr().GetPendantConfig(dwPendantID).nMoney
end

function CanBuyPendantWithMoney(dwID, bModelID)
	local nRequiredMoney = GetPendantPriceInMoney(dwID, bModelID)
	local player = GetClientPlayer()
	local tMoney = player.GetMoney()
	local nGold, nSilver, nCopper = UnpackMoney(tMoney)
	return nRequiredMoney > 0 and nGold >= nRequiredMoney
end

FURNITURE_CANT_BATCH_BUY_REASON =
{
	NOT_BY_ARCHITECTURE = 1,
	MONEY_NOT_ENOUGH = 2,
	TOO_MUCH_FOR_AUTO_BUY = 3,
}

-- tCountInfo={{dwModelID, nCount}, ...}
-- 返回： bCanBuy, eCantBuyReason
function CanBatchBuyFurnitureWithArchitecture(tCountInfo, bModelID, bAutoBuy)
	local player = GetClientPlayer()
	local nAllArchitecture = 0
	if #tCountInfo > 10 then -- 逻辑最多支持同时购买10个
		return false
	end

	for _, t in pairs(tCountInfo) do
		local dwID, nCount = t[1], t[2]
		local nRequiredArchitecture = GetFurniturePriceInArchitecture(dwID, bModelID, nCount)
		if nRequiredArchitecture == 0 then
			return false, FURNITURE_CANT_BATCH_BUY_REASON.NOT_BY_ARCHITECTURE
		else
			nAllArchitecture = nAllArchitecture + nRequiredArchitecture
		end
	end

	--LOG.INFO("==== 需要的资源点总数是： " .. tostring(nAllArchitecture))

	if player.nArchitecture < nAllArchitecture then
		return false, FURNITURE_CANT_BATCH_BUY_REASON.MONEY_NOT_ENOUGH
	elseif bAutoBuy and nAllArchitecture > _MAX_AUTO_BUY_MONEY then
		return false, FURNITURE_CANT_BATCH_BUY_REASON.TOO_MUCH_FOR_AUTO_BUY
	else
		return true
	end
end

------------------------------ ↑↑↑↑ 家具购买相关 ------------------------------

------------------------------ 团购相关 ------------------------------
local function OutputErrorMessage(arg1)
    local szErrorText = g_tStrings.tHomelandBuildingFailureNotify[arg1] or
        g_tStrings.STR_GROUP_BUY_UNKNOWN_ERROR
	OutputMessage("MSG_SYS", szErrorText.."\n")
	OutputMessage("MSG_ANNOUNCE_NORMAL", szErrorText.."\n")
end

local function fnOnInvitionSucceed()
	UIMgr.Open(VIEW_ID.PanelHomeGroupPop, arg0, arg1)
end

local function fnOnBuyLandGrouponReadyRequest()
	if arg0 == HOMELAND_RESULT_CODE.BUY_LAND_GROUPON_READY_REQUEST then
		if arg1 == HOMELAND_RESULT_CODE.GROUPON_SUCCEED then
			local dwMapID = arg2
			local nLandIndex = arg3
			HomelandGroupBuyData.ShowGroupBuyTeamSurePop(dwMapID, nLandIndex)
		else
			OutputErrorMessage(arg1)
		end
	elseif arg0 == HOMELAND_RESULT_CODE.BUY_LAND_GROUPON_ADD_PLAYER then
		OutputErrorMessage(arg1)
	elseif arg0 == HOMELAND_RESULT_CODE.DELETE_BUY_LAND_GROUPON then
		if arg1 == HOMELAND_RESULT_CODE.GROUPON_SUCCEED then
			-- 因为打开家园界面时会申请一次团购信息，所以退出团购提示只在打开团购界面时弹
			if UIMgr.GetView(VIEW_ID.PanelCustomBuyPop) then
				OutputMessage("MSG_SYS", g_tStrings.STR_REMOVED_GROUP_BUY_TIPS.."\n")
				OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_REMOVED_GROUP_BUY_TIPS.."\n")
			end
		else
			OutputErrorMessage(arg1)
		end
	elseif arg0 == HOMELAND_RESULT_CODE.CREATE_BUY_LAND_GROUPON and
		arg1 ~= HOMELAND_RESULT_CODE.GROUPON_SUCCEED then
			OutputErrorMessage(arg1)
	elseif arg0 == HOMELAND_RESULT_CODE.BUY_LAND_GROUPON_REMOVE_PLAYER then
		OutputErrorMessage(arg1)
	elseif arg0 == HOMELAND_RESULT_CODE.BUY_LAND_GROUPON_BIND_PLAYER_LAND and
		arg1 ~= HOMELAND_RESULT_CODE.GROUPON_SUCCEED then
			OutputErrorMessage(arg1)
	elseif arg0 == HOMELAND_RESULT_CODE.BUY_LAND_GROUPON_DISBIND_PLAYER_LAND and
		arg1 ~= HOMELAND_RESULT_CODE.GROUPON_SUCCEED then
			OutputErrorMessage(arg1)
	end
end

local function fnOnGroupMemberDeleteSucceed()
	local szPlayerName = UIHelper.GBKToUTF8(arg0)
	OutputMessage("MSG_SYS", szPlayerName..g_tStrings.STR_LEAVE_GROUP_BUY_TIPS.."\n")
	OutputMessage("MSG_ANNOUNCE_NORMAL", szPlayerName..g_tStrings.STR_LEAVE_GROUP_BUY_TIPS.."\n")
end
------------------------------ 家具套装收集相关 ------------------------------

local _FURNITURE_COLLECT_ACTIVE_ID = 2

function GetFurnitureCollectActiveID()
	return _FURNITURE_COLLECT_ACTIVE_ID
end

local m_bShowFurnitureCollectHotPoint = false

function HasFurnitureCollectionHotPoint()
	return m_bShowFurnitureCollectHotPoint
end

function ClearFurnitureCollectionHotPoint()
	m_bShowFurnitureCollectHotPoint = false
end

function IsFurnitureCollectLocked()
	return Homeland_NeedTeachFurnitureCollect() -- from scripts\Map\家园系统客户端\Include\HomelandCommon.lua
end

-- 返回值：true 为已收集；false 为未收集；nil 为不在套装里
function IsFurnitureCollected(dwFurnitureID)
	local pHlMgr = GetHomelandMgr()
	local tLogicInfo = pHlMgr.GetFurnitureConfig(dwFurnitureID)
	local pPlayer = GetClientPlayer()
	if tLogicInfo then
		local dwSetID = tLogicInfo.nSetID
		if dwSetID > 0 then -- 0表示无效值
			local nSetIndex = tLogicInfo.nSetIndex
			local tSetConfig = pPlayer.GetSetCollection(dwSetID)
			if pPlayer.HaveSetCollectionData() then -- 现在其实必定成立
				local bCollected = tSetConfig.tSetUnit[nSetIndex] == 1
				return bCollected
			else
				-- Do nothing
			end
		else
			-- Do nothing（不在套装里）
		end
	end
	return nil
end
--[[
function ApplySetCollectionData()
	local pPlayer = GetClientPlayer()
	if not pPlayer then
		return
	end
	pPlayer.ApplySetCollection()
end]]

local bHasSyncedFurnitureCollectionInMap = false

local function fnOnSyncSetCollection()
	bHasSyncedFurnitureCollectionInMap = true
end

function IsSetCollectionSynced()
	return bHasSyncedFurnitureCollectionInMap
end

------------------------------ 橙色家具收集相关 ------------------------------
local _SEASON_FURNITURE_ACTIVE_ID = 3

function GetSeasonFurnitureActiveID()
	return _SEASON_FURNITURE_ACTIVE_ID
end

local m_bShowSeasonFurnitureHotPoint = false

function HasSeasonFurnitureHotPoint()
	return m_bShowSeasonFurnitureHotPoint
end

function ClearSeasonFurnitureHotPoint()
	m_bShowSeasonFurnitureHotPoint = false
end

------------------------------ 庐园广记和橙色家具收集通用 ------------------------------

local function fnOnSyncSetCollectionToAwardActive()
	if arg0 == _FURNITURE_COLLECT_ACTIVE_ID then -- 界面未打开时的红点提示
		m_bShowFurnitureCollectHotPoint = true
		FireUIEvent("LUA_HOMELAND_FURNITURE_COLLECT_ON_NEW_HOTPOINT")
	elseif arg0 == _SEASON_FURNITURE_ACTIVE_ID then
		m_bShowSeasonFurnitureHotPoint = true
	end
end

------------------------------ 其他 ------------------------------
local m_bPlayLandSfx = true

function SwitchLandSfx()
	m_bPlayLandSfx = not m_bPlayLandSfx
end

function PlayLandSfx(param)
	if m_bPlayLandSfx then
		rlcmd(("homeland -play sfx %s"):format(param))
	end
end

local m_nGrass = 127

function UpdateGrass(nGrass)
	m_nGrass = nGrass
	local scene = GetClientScene()
	local pHlMgr = GetHomelandMgr()
	local dwCurMapID, nCurCopyIndex = scene.dwMapID, scene.nCopyIndex
	if pHlMgr.IsPrivateHomeMap(dwCurMapID) then
		local nLandIndex = pHlMgr.GetNowLandIndex()
		local nMaxSubLandIndex = pHlMgr.GetMaxSubLandIndex(dwCurMapID, nLandIndex)
		-- JustLOG.INFO(FormatString("homeland -set subland base grass visible <D0> <D1>", nMaxSubLandIndex, m_nGrass))
		rlcmd(FormatString("homeland -set subland base grass visible <D0> <D1>", nMaxSubLandIndex, m_nGrass))
	end
end

function GetGrass()
	return m_nGrass
end

function SetGrass(nGrass)
	local pHLMgr = GetHomelandMgr()
	if not pHLMgr then
		return
	end
	local nEventID = 3
	pHLMgr.SendCustomEvent(nEventID, nGrass, 0)
end

local m_nGrasseEffectFurniture = 1 -- 摆放家具 花草刷穿模 1：不穿模 0：穿模

function UpdateGrasseEffectFurniture(nGrasseEffectFurniture)
	m_nGrasseEffectFurniture = nGrasseEffectFurniture
end

function GetGrasseEffectFurniture()
	return m_nGrasseEffectFurniture
end

function SetGrasseEffectFurniture(nGrasseEffectFurniture)
	local pHLMgr = GetHomelandMgr()
	if not pHLMgr then
		return
	end
	local nEventID = 4
	pHLMgr.SendCustomEvent(nEventID, nGrasseEffectFurniture, 0)
end

function Init()
	local RegEvent = function (szEvent)
		Event.Reg(HomelandEventHandler, szEvent, function ()
			OnEvent(szEvent)
		end)
	end

	RegEvent("HOME_LAND_RESULT_CODE")
	RegEvent("HOME_LAND_RESULT_CODE_INT")
	RegEvent("SHOW_HOMELAND_MINIGAME_PANEL")
	RegEvent("HOME_LAND_CHANGE_FURNITURE")
	RegEvent("HOME_LAND_CHANGE_PENDANT_FURNITURE")
	RegEvent("HOME_LAND_CHANGE_PAINTBRUSH")
	RegEvent("HS_BUY_LAND_GROUPON_ADD_PLAYER_REQUEST")
	RegEvent("HS_BUY_LAND_GROUPON_REMOVE_PLAYER")
	RegEvent("ON_SYNC_SET_COLLECTION_TO_AWARD_ACTIVE")

	--[[Event.Reg(HomelandEventHandler, "FIRST_LOADING_END", function()
		ApplySetCollectionData()
	end)]]

	Event.Reg(HomelandEventHandler, "ON_SYNC_SET_COLLECTION", function()
		fnOnSyncSetCollection()
	end)

	Event.Reg(HomelandEventHandler, "LOGIN_NOTIFY", function(nEvent)
		if nEvent == LOGIN.REQUEST_LOGIN_GAME_SUCCESS or nEvent == LOGIN.MISS_CONNECTION then
            InitAllNewlyGotData()
		end
    end)
end

function OnEvent(szEvent)
	LOG.INFO("----------------HomelandEventHandler.OnEvent--------%s", szEvent)
	if szEvent == "HOME_LAND_RESULT_CODE" then
		fnOnHomeRetCode()
	elseif szEvent == "HOME_LAND_RESULT_CODE_INT" then
		fnOnHomeRetCodeInt()
		fnOnBuyLandGrouponReadyRequest()
	elseif szEvent == "SHOW_HOMELAND_MINIGAME_PANEL" then
		OnHouseGame()
	elseif szEvent == "HOME_LAND_CHANGE_FURNITURE" then
		fnOnFurnitureChange()
	elseif szEvent == "HOME_LAND_CHANGE_PENDANT_FURNITURE" then
		fnOnPendantFurnitureChange()
	elseif szEvent == "HOME_LAND_CHANGE_PAINTBRUSH" then
		fnOnBrushChange()
	elseif szEvent == "HS_BUY_LAND_GROUPON_ADD_PLAYER_REQUEST" then
		fnOnInvitionSucceed()
	elseif szEvent == "HS_BUY_LAND_GROUPON_REMOVE_PLAYER" then
		fnOnGroupMemberDeleteSucceed()
	elseif szEvent == "ON_SYNC_SET_COLLECTION_TO_AWARD_ACTIVE" then
		fnOnSyncSetCollectionToAwardActive()
	end
end