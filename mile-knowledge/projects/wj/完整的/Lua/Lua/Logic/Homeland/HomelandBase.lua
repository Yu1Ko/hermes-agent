-- 家园枚举
HOMELAND_MAX_LEVEL = 16
FURNITURE_MAX_QUALITY = 5

BUILD_MODE = {
	COMMUNITY = 1,
	PRIVATE = 2,
	DESIGN = 3,
	TEST = 4,
}

--家园建造埋点
HOMELAND_LOG_NUM = {
	ENTER_BUILDING = 1,
	EXIT_BUILDING = 2,
	IMPORT_BLUEP = 4,
	IMPORT_BLUEP_SUCCESS = 5,
	EXPORT_BLUEP = 6,
}

BUILD_CAM_OP_MODE = {
	BASIC = 1,
	ADVANCED = 2,
}

BUILD_SETTING = {
	CAM_MOVE_SPEED_INDOORS_MIN = 1,
	CAM_MOVE_SPEED_INDOORS_MAX = 100,
	CAM_MOVE_SPEED_OUTDOORS_MIN = 1,
	CAM_MOVE_SPEED_OUTDOORS_MAX = 100,
	CAM_SCREEN_EDGE_SPEED = 40,

	UNIT_CAM_MOVE_DIST_BY_MOUSE_WHEEL = 40,   --家园建造镜头缩放（PC端）
	UNIT_CAM_MOVE_DIST_BY_MOUSE_WHEEL_MOBLIE = 30, --家园建造镜头缩放（移动端）
	UNIT_CAM_MOVE_DIST_BY_MOUSE_MOVE = 0.1,
	UNIT_CAM_MOVE_DIST_BY_KEY_DOWN = 10,
	UNIT_CAM_VERTICAL_MOVE_DIST = 5,
	UNIT_CAM_ROTATE_YAW_ANGLE = 0.004,
	UNIT_CAM_ROTATE_PITCH_ANGLE = 0.004,
	UNIT_CAM_ROTATE_ANGLE = 0.18,
}

local BLUEPRINT_SELF_WEB_URL = "https://gdca.xoyo.com/p/zt/2023/02/27/blueprint/index.html#/management?type=normal"
local BLUEPRINT_SELF_WEB_URL_TEST = "http://test-zt.xoyo.com/gdca.xoyo.com/p/zt/2023/02/27/blueprint/index.html#/management?type=normal"

HOMELAND_BLUEPRINT_WEB_URL = "https://gdca.xoyo.com/p/zt/2023/02/27/blueprint/index.html#/"
HOMELAND_BLUEPRINT_WEB_URL_TEST = "http://test-zt.xoyo.com/gdca.xoyo.com/p/zt/2023/02/27/blueprint/index.html#/"
HOMELAND_WAN_BAO_LOU_BLUEPRINT_WEB_URL = "https://jx3.seasunwbl.com/auth/from-jx3-client?t=blueprint"
HOMELAND_WAN_BAO_LOU_BLUEPRINT_WEB_URL_TEST = "https://jx3.seasunwbl.com/auth/from-jx3-client"
------------------------------------------------
g_HomelandBuildingData = {
	nCamSpeedIndoors = 20, --室内镜头转动灵敏度初始值（PC端）
	nCamSpeedOutdoors = 30, --庭院镜头转动灵敏度初始值（PC端）
	nCamMoveSpeedIndoors = 20, --室内镜头移动灵敏度初始值（PC端）
	nCamMoveSpeedOutdoors = 30, --庭院镜头移动灵敏度初始值（PC端）
	bShowHelp = true,
	bShowItemList = false,
	bEnableItemOperations = true,
	bShowBaseboards = true,
	tFlowerBrushConfig = nil,
	eCurCameraOpMode = BUILD_CAM_OP_MODE.ADVANCED,
	bShowGrid = true,
	bGridAlignEnabled = true,
	bEnableMultiSelectBasement = false,
}

if Platform.IsMobile() then
	g_HomelandBuildingData.nCamSpeedIndoors = 20 --室内镜头转动灵敏度初始值（移动端）
	g_HomelandBuildingData.nCamSpeedOutdoors = 30 --庭院镜头转动灵敏度初始值（移动端）
	g_HomelandBuildingData.nCamMoveSpeedIndoors = 20 --室内镜头移动灵敏度初始值（移动端）
	g_HomelandBuildingData.nCamMoveSpeedOutdoors = 30 --庭院镜头移动灵敏度初始值（移动端）
end

g_HomelandBuildingDefaultData = Lib.copyTab(g_HomelandBuildingData)

-- RegisterCustomData("g_HomelandBuildingData.nCamSpeedIndoors")
-- RegisterCustomData("g_HomelandBuildingData.nCamSpeedOutdoors")
-- RegisterCustomData("g_HomelandBuildingData.bShowHelp")
-- RegisterCustomData("g_HomelandBuildingData.bShowItemList")
-- RegisterCustomData("g_HomelandBuildingData.bEnableItemOperations")
-- RegisterCustomData("g_HomelandBuildingData.bShowBaseboards")
-- RegisterCustomData("g_HomelandBuildingData.bShowGrid")
-- RegisterCustomData("g_HomelandBuildingData.bGridAlignEnabled")
-- RegisterCustomData("g_HomelandBuildingData.bEnableMultiSelectBasement")
-- RegisterCustomData("g_HomelandBuildingData.eCurCameraOpMode")
------------------------Config-----------------------------------
local tDefaultConfig = {
	bDesign = false,
	bPrivate = false,
	bTest = false,
	szFileName = "homelandblueprinttotal",
}

local tModeConfig = {
	[BUILD_MODE.COMMUNITY] = tDefaultConfig,
	[BUILD_MODE.PRIVATE] = Lib.copyTab(tDefaultConfig),
	[BUILD_MODE.DESIGN] = Lib.copyTab(tDefaultConfig),
	[BUILD_MODE.TEST] = Lib.copyTab(tDefaultConfig),
}

tModeConfig[BUILD_MODE.PRIVATE].bPrivate = true
tModeConfig[BUILD_MODE.DESIGN].bDesign = true
tModeConfig[BUILD_MODE.DESIGN].szFileName = "homelanddesign"
tModeConfig[BUILD_MODE.TEST].bTest = true
tModeConfig[BUILD_MODE.TEST].bDesign = true
HomelandCommon = HomelandCommon or {className = "HomelandCommon"}
local tbLoadExtensionsScript = {
    "scripts/Map/家园系统客户端/Include/HomelandCommon.lua",
    "scripts/Map/家园系统客户端/Include/Home_LandObjectInteraction.lua",
    "scripts/Map/家园系统客户端/Include/Home_MiniGameCommonFunction.lua",
}

for _, szPath in ipairs(tbLoadExtensionsScript) do
	LoadScriptFile(UIHelper.UTF8ToGBK(szPath), HomelandCommon)
end

function Homeland_GetModeConfig(nMode)
	return tModeConfig[nMode]
end
------------------------------------------------------------------
local FURNITURE_LABEL_MASK =
{
	--[nUIIndex] = {nLabelMask, szName},
	{1, g_tStrings.STR_HOMELAND_FURNITURE_TAGS[1]},
	{2, g_tStrings.STR_HOMELAND_FURNITURE_TAGS[2]},
	{4, g_tStrings.STR_HOMELAND_FURNITURE_TAGS[3]},
	{8, g_tStrings.STR_HOMELAND_FURNITURE_TAGS[4]},
}

local tFurnitureLabelImageFrame =
{
	-- [nLabelMask] = nFrame,
	[1] = 1,
	[2] = 5,
	[4] = 3,
	[8] = 4,
}

local FURNITURE_QUALITY_2_RGB =
{
	[1] = {255, 255, 255},
	[2] = {0, 200, 72},
	[3] = {0, 126, 255},
	[4] = {233, 18, 201},
	[5] = {255, 150, 0},
}

local szUrlForOfficialBlps_Test = "https://test-zt.xoyo.com/jx3.xoyo.com/zt/2020/09/24/blueprint/index.html"
local szUrlForOfficialBlps = "https://jx3.xoyo.com/zt/2020/09/24/blueprint/#/"

local MAX_STYLE_NUM = 4

local szStoreURL = ""
local szStoreSign = ""

function IsHomelandCommunityMap(dwMapID)
	if not dwMapID then
		local scene = GetClientScene()
		dwMapID = scene.dwMapID
	end
	local _, nMapType = GetMapParams(dwMapID)
	if nMapType == MAP_TYPE.HOMELAND then
		return true
	end
	return false
end

function Homeland_GetRequiredLevelByID(nFurnitureType, dwFurnitureID)
	local tConfig
	if nFurnitureType == HS_FURNITURE_TYPE.FURNITURE then
		tConfig = GetHomelandMgr().GetFurnitureConfig(dwFurnitureID)
	elseif nFurnitureType == HS_FURNITURE_TYPE.PENDANT then
		tConfig = GetHomelandMgr().GetPendantConfig(dwFurnitureID)
	end
	return tConfig.nLevelLimit ~= nil and tConfig.nLevelLimit or 0
end

function Homeland_GetFurnitureLabelImageFrame()
	return "ui/Image/UICommon/CommonPanel8.UITex", tFurnitureLabelImageFrame, MAX_STYLE_NUM
end

function Homeland_GetFurnitureRGBByQuality(nQuality)
	return FURNITURE_QUALITY_2_RGB[nQuality]
end

function Homeland_GetHomeName(nMapID, nLandIndex)
	return Table_GetMapName(nMapID) .. tostring(nLandIndex) .. UTF8ToGBK(g_tStrings.STR_HOMELAND_NUMBER)
end

------------------------教学相关--------------------------------
function Homeland_IsInBuildingTeachingQuest()
	local pPlayer = GetClientPlayer()
	if not pPlayer then
		return false
	end

	local aBuildingTeachingQuests = HomelandCommon.Homeland_GetBuildingTeachingQuests()
	for _, dwQuestID in ipairs(aBuildingTeachingQuests) do
		if pPlayer.GetQuestIndex(dwQuestID) then
			return true
		end
	end
	return false
end

function Homeland_InformServerOnFinishDyeing()
	local pPlayer = GetClientPlayer()
	if not pPlayer then
		return
	end
	if pPlayer.GetQuestIndex(HomelandCommon.Homeland_GetDyeTeachingQuestID()) then
		RemoteCallToServer("On_HomeLand_Dyeing")
	end
end

function Homeland_InformServerOnFinishScaling()
	local pPlayer = GetClientPlayer()
	if not pPlayer then
		return
	end
	if pPlayer.GetQuestIndex(HomelandCommon.Homeland_GetScaleTeachingQuestID()) then
		RemoteCallToServer("On_HomeLand_Zoom")
	end
end

-----------------------挂件相关---------------------------
PENDANT_ERROR_TYPE =
{
	NOT_ACQUIRED = 1,
	ALREADY_ISOTYPED = 2,
}

local PENDANT_TYPE = {
	NORMAL = 1,
	RAREHORSE = 2,
	PARTNER = 3,
}

local function GetPlayerItem(player, dwBox, dwX, szPackageType, dwASPSource)
	if szPackageType == UI_BOX_TYPE.SHAREPACKAGE then
		return player.GetItemInAccountSharedPackage(dwASPSource, dwBox, dwX)
	elseif dwBox == INVENTORY_GUILD_BANK then
		return GetTongClient().GetRepertoryItem(GetGuildBankPagePos(dwBox, dwX))
	else
		return player.GetItem(dwBox, dwX)
	end
end

local tCanIsotypeFunc = {
	[PENDANT_TYPE.RAREHORSE] = function(pPlayer, nItemID)
		local dwBox, dwX = _G.GetRareHorsePosInfo(ITEM_TABLE_TYPE.CUST_TRINKET, nItemID)
		assert(dwBox, "Cannot get PosInfo from tab index [" .. tostring(nItemID) ..
				"], which is from Qiqu pendant (furniture id: " .. tostring(dwPendantID) .. ")")
		return (pPlayer and GetPlayerItem(pPlayer, dwBox, dwX) ~= nil)
	end,
	[PENDANT_TYPE.PARTNER] = function(pPlayer, nItemID)
		return IsReputationPetReceived(pPlayer, nItemID)
	end,
	[PENDANT_TYPE.NORMAL] = function(pPlayer, nItemID)
		return (pPlayer and pPlayer.IsPendentExist(nItemID))
	end,
}

function Homeland_CanIsotypePendant(dwPendantID)
	local hlMgr = GetHomelandMgr()

	--local ePendantState = hlMgr.GetPendantFurniture(dwPendantID)
	--if ePendantState == HS_PENDANT_STATE_TYPE.NOT_ACQUIRED then
	local bHavePendtant = hlMgr.GetPendantFurniture(dwPendantID)
	if not bHavePendtant then
		local tInfo = hlMgr.GetPendantConfig(dwPendantID)
		--Log("====== 挂件家具(id: " .. tostring(dwPendantID) .. ")对应的 nItemID == " .. tostring(tInfo.nItemID))

		local ePendantType = PENDANT_TYPE.NORMAL
		local nCatg1, nCatg2 = FurnitureData.GetFurnCatgByTypeAndID(HS_FURNITURE_TYPE.PENDANT, dwPendantID)
		local tLine = FurnitureData.GetPendantInfo(nCatg1, nCatg2)
		if tLine then
			ePendantType = tLine.nType
		end

		local pPlayer = GetClientPlayer()
		local bCanIsotype = tCanIsotypeFunc[ePendantType](pPlayer, tInfo.nItemID)

		if bCanIsotype then
			return true
		else
			return false, PENDANT_ERROR_TYPE.NOT_ACQUIRED
		end
	else -- ePendantState == HS_PENDANT_STATE_TYPE.IDLE or ePendantState == HS_PENDANT_STATE_TYPE.USING
		return false, PENDANT_ERROR_TYPE.ALREADY_ISOTYPED
	end
end
------------------------up--------------------------------
function Homeland_OpenHomelandURL(szURL, bLogin, szName)
	if bLogin then
		szStoreURL = szURL
		local szSign = "HomelandOpenURL_" .. szName
		szStoreSign = szSign
		Homeland_ApplySignWeb(szSign)
	else
		UIHelper.OpenWebWithDefaultBrowser(szURL)
	end
end

function Homeland_VisitWebBlps()
	local szURL = ""
	if IsDebugClient() or IsVersionExp() then
		szURL = HOMELAND_BLUEPRINT_WEB_URL_TEST
	else
		szURL = HOMELAND_BLUEPRINT_WEB_URL
	end

	if szURL and szURL ~= "" then
		Homeland_OpenHomelandURL(szURL, true, "BlueprintWeb")
	end
	-- local nURLID = 0
	-- if IsDebugClient() or IsVersionExp() then
	-- 	nURLID = 22
	-- else
	-- 	nURLID = 23
	-- end
	-- WebUrl.OpenByID(nURLID)
end

function Homeland_VisitWebSelfBlps()
	local szURL = ""
	if IsDebugClient() or IsVersionExp() then
		szURL = BLUEPRINT_SELF_WEB_URL_TEST
	else
		szURL = BLUEPRINT_SELF_WEB_URL
	end
	Homeland_OpenHomelandURL(szURL, true, "BlueprintSelfWeb")
end

function Homeland_VisitWanBaoLouBlpsWeb()	-- 万宝楼蓝图分页跳转
	local nURLID = 0
	if IsDebugClient() or IsVersionExp() then
		nURLID = 29
	else
		nURLID = 28
	end
	WebUrl.OpenByID(nURLID)
end

function Homeland_GetFurnitureLabelMask()
	return FURNITURE_LABEL_MASK
end

function Homeland_GetMapAndCopyIndex()
	local scene = GetClientScene()
	local dwMapID, nCopyIndex = scene.dwMapID, scene.nCopyIndex
	return dwMapID, nCopyIndex
end

function Homeland_ToBoolean(value)
	if type(value) == "number" then
		value = value ~= 0
	else -- 布尔值
		-- Do nothing
	end
	return value
end

function Homeland_ServerLog(nMode, nLogNum, nUserData1, nUserData2)
	local nModeFlag
	if nMode == BUILD_MODE.COMMUNITY or nMode == BUILD_MODE.PRIVATE then
		nModeFlag = 1
	elseif nMode == BUILD_MODE.DESIGN then
		nModeFlag = 0
	else
		return
	end
	if nLogNum == HOMELAND_LOG_NUM.IMPORT_BLUEP_SUCCESS then
		local bDigital, szCode = nUserData1, nUserData2
		if bDigital then
			RemoteCallToServer("On_HomeLand_BuildLog", nLogNum, nModeFlag, 2, szCode)
		else
			RemoteCallToServer("On_HomeLand_BuildLog", nLogNum, nModeFlag, 1)
		end
	elseif nLogNum == HOMELAND_LOG_NUM.IMPORT_BLUEP then
		local szCode = nUserData1
		RemoteCallToServer("On_HomeLand_BuildLog", nLogNum, nModeFlag, szCode)
	else
		RemoteCallToServer("On_HomeLand_BuildLog", nLogNum, nModeFlag)
	end
end

function Homeland_GetCenterScreenPosInPixels()
	local sizeDesign = UIHelper.GetCurResolutionSize()
	local tPos = cc.Director:getInstance():convertToGL({x = sizeDesign.width / 2, y = sizeDesign.height / 2})
    local nScaleX, nScaleY = UIHelper.GetScreenToResolutionScale()

	return tPos.x * nScaleX, tPos.y * nScaleY
end

function Homeland_GetTouchingPosInPixels()
	local tCursor = GetViewCursorPoint()

	local tPos = cc.Director:getInstance():convertToGL({x = tCursor.x, y = tCursor.y})
    local nScaleX, nScaleY = UIHelper.GetScreenToResolutionScale()

	return tPos.x * nScaleX, tPos.y * nScaleY
end

function Homeland_GetCursorPosInPixels()
	local tbTouchPos = SceneMgr.GetLastTouchPos()
	local tCursor = tbTouchPos[1]

	if tCursor and tCursor.nX and tCursor.nY then
		local tPos = cc.Director:getInstance():convertToGL({x = tCursor.nX, y = tCursor.nY})
		local nScaleX, nScaleY = UIHelper.GetScreenToResolutionScale()

		return tPos.x * nScaleX, tPos.y * nScaleY
	end

	return
end

function Homeland_GetCursorPosInPixelsByPos(nX, nY)
	local tCursor = {nX = nX, nY = nY}

	if tCursor and tCursor.nX and tCursor.nY then
		local tPos = cc.Director:getInstance():convertToGL({x = tCursor.nX, y = tCursor.nY})
		local nScaleX, nScaleY = UIHelper.GetScreenToResolutionScale()

		return tPos.x * nScaleX, tPos.y * nScaleY
	end

	return
end

function Homeland_GetPathForDisplay(szPath)
	szPath = string.gsub(szPath, '\\', '\\\\')
	szPath = string.gsub(szPath, '/', '\\\\')
	return szPath
end

function Homeland_GetExportedBlpFolder()
	return UIHelper.GBKToUTF8(GetStreamAdaptiveDirPath(GetFullPath("homelanddir") .. "/blueprints/"))
end

function Homeland_GetExportedShot360Folder()
	return UIHelper.GBKToUTF8(GetStreamAdaptiveDirPath(GetFullPath("homelanddir") .. "/shot/"))
end

function Homeland_Log(...)
	--JustLog(...)
	local tbParams = {...}
	local szLog = ""
	for _, v in ipairs(tbParams) do
		szLog = szLog .. "  " ..tostring(v)
	end
	LOG.INFO(szLog)
	LOG.INFO(debug.traceback())
end

function Homeland_StoreConsumption(tStore, bDel)
	local nDataCnt = arg3 / 2
	if nDataCnt > math.floor(nDataCnt) then
		nDataCnt = math.floor(nDataCnt)
	end
	local nModelID, nModelAmount
	for i = 1, nDataCnt do
		nModelID, nModelAmount = _G["arg" .. (2+2*i)], _G["arg" .. (3+2*i)]
		if bDel then
			nModelAmount = -nModelAmount
		end
		table.insert(tStore, {nModelID = nModelID, nModelAmount = nModelAmount})
	end
end

function Homeland_AdjustFilePath(szFilePath, szExtension)
	local szAdjust = szFilePath .. szExtension
	if not Lib.IsFileExist(szAdjust) then
		return szAdjust
	end

	for i = 1, 100 do
		szAdjust = szFilePath .. "(" .. i.. ")" .. szExtension
		if not Lib.IsFileExist(szAdjust) then
			return szAdjust
		end
	end
	local nTickCount = GetTickCount()
	szAdjust = szFilePath .. "(" .. nTickCount.. ")" .. szExtension
	return szAdjust
end

function Homeland_StoreObjID(tStore)
	local nDataCnt = arg3
	local dwObjID
	for i = 1, nDataCnt do
		dwObjID = _G["arg" .. (3+i)]
		table.insert(tStore, dwObjID)
	end
end

function Homeland_GetRange(szInfo)
	local tRange = szInfo:split(";", true)
	if #tRange < 2 then
		return nil
	end
	local fMinScale = tonumber(tRange[1])
	local fMaxScale = tonumber(tRange[2])
	if fMinScale == 0 and fMaxScale == 0 then
		return nil
	else
		return {fMinScale, fMaxScale}
	end
end

local CIRCLE_ANGLE_UNITS = 32 -- 一个周角分成多少个单位角度
local UNIT_ROTATE_ANGLE = 360 / CIRCLE_ANGLE_UNITS
local FIXED_ROTATE_ANGLE_IN_UNITS = 8

function Homeland_GetKeyXAngles()
	return -FIXED_ROTATE_ANGLE_IN_UNITS * UNIT_ROTATE_ANGLE
end

function Homeland_GetKeyZCAngles()
	return -UNIT_ROTATE_ANGLE
end

function Homeland_GetNullSubgroupID()
	return 0
end

function Homeland_GetNullCatg2Index()
	return 0
end

function Homeland_GetBaseboardCatg2Index()
	return 3
end

function Homeland_GetMechanismCatg2Index()
	return 8
end

function Homeland_GetFunctionCatg1Index()
	return 9
end

function Homeland_GetCustomBrushCatg1Index()
	return 6
end

function Homeland_GetFlowerBrushCatg2Index()
	return 1
end

function Homeland_GetFloorBrushCatg2Index()
	return 2
end

function Homeland_GetClueCatg2Index()
	return 1
end

function Homeland_GetRoleCatg2Index()
	return 2
end

function Homeland_GetTestBuildLevel()
	return 16
end

-----Http------
function Homeland_TransformDataEncode(tData)
	for k, v in pairs(tData) do
		if type(v) == "string" and v ~= "" then
			tData[k] = UIHelper.GBKToUTF8(v)
		end
	end
end

function Homeland_GenerateCipher(uSign, dwType, nTime, nZoneID, dwCenterID)
	if dwType ~= WEB_DATA_SIGN_RQST.LOGIN then
		return
	end

	local pPlayer = GetClientPlayer()
	if not pPlayer then
		return
	end

	local szAccount = Login_GetAccount()
	local szName = pPlayer.szName
	local dwID = pPlayer.dwID
	local dwForceID = pPlayer.dwForceID

	local szUserRegion, szUserSever = HomelandBuildData.GetServerName()
	szName = UIHelper.GBKToUTF8(szName)

	local szCipherParam = "%d/%s/%d/%d/%d/%d/%s/%s/%d/%s/%d/%s"

	szCipherParam = string.format(
			szCipherParam, uSign, szAccount, dwID, nTime, nZoneID,
			dwCenterID, szUserRegion, szUserSever, dwForceID, szName, nTime, GetAccountType()
	)

	return szCipherParam
end

function Homeland_GetDownloadPath(szName)
	local function GetDownloadEXPPath()
		local path = GetJX3TempPath() .. "ExpHotSpot\\"
		if not Lib.IsFileExist(path) then
			CPath.MakeDir(path)
		end
		return path
	end

	local bExp = IsVersionExp()
	if bExp then
		return GetDownloadEXPPath() .. szName
	else
		return GetJX3TempPath() .. szName
	end
end

function Homeland_ApplySignWeb(szSign)
	local pPlayer = GetClientPlayer()
	if not pPlayer then
		return
	end
	Homeland_Log("HomelandBase ApplySignWeb")
	pPlayer.ApplyWebDataSign(WEB_DATA_SIGN_RQST.LOGIN, szSign)
end

function Homeland_OpenHomelandURL(szURL, bLogin, szName)
	if bLogin then
		szStoreURL = szURL
		local szSign = "HomelandOpenURL_" .. szName
		szStoreSign = szSign
		Homeland_ApplySignWeb(szSign)
	else
		UIHelper.OpenWeb(szURL)
	end
end
function Homeland_OnApplyWebDataSign()
	local uSign                     = arg0
	local dwType 					= arg1
	local nTime                     = arg2
	local nZoneID                   = arg3
	local dwCenterID                = arg4
	local bIsFirstWebPhoneVerified  = arg5
	local szOrderSN                 = arg6

	if not (dwType == WEB_DATA_SIGN_RQST.LOGIN and szOrderSN == szStoreSign) then
		return
	end

	local szCipher = Homeland_GenerateCipher(uSign, dwType, nTime, nZoneID, dwCenterID)
	Homeland_Log("==== HomelandOpen szCipher === " .. tostring(szCipher))
	local tInfo = SplitString(szStoreURL, "#")
	local szNewURL = tInfo[1] .. "?cipher=" .. szCipher .. "#" .. tInfo[2]
	UIHelper.OpenWeb(szNewURL)
	Homeland_Log("HomelandOpen URL", szNewURL)
end

function Homeland_IsDigitalBlueprint(eMarketType)
	local tInfo = GDAPI_Homeland_CheckBusness(eMarketType)
	return tInfo[GDENUM_HOMELAND_MARKET_TYPE.LEGAL]
end

local szPreRequestKey = nil
local szKeyForGetList = "HomelandGetNameAndAuthor"
local szKeyForGetListUI = "DaTangJiaYuanUI"
local szUrlForGetList = "https://gdca-blueprint-api.xoyo.com/gamegw/digital-asset/get-asset-creator-name"
local szUrlForGetList_Test = "http://120.92.151.103/gamegw/digital-asset/get-asset-creator-name"
local function GetAPIURL()
	if IsDebugClient() or IsVersionExp() then
		return szUrlForGetList_Test
	else
		return szUrlForGetList
	end
end

-- GS --> Client --> GS
-- 逻辑说GS没有Http 不给做
function Homeland_GetDigitalBlueprintNameAndAuthor(szGlobalID, nType)
	local tHttpData = {}
	tHttpData["globalRoleId"] = szGlobalID
	tHttpData["mapType"] = nType
	-- Homeland_TransformDataEncode(tHttpData)
	szPreRequestKey = szKeyForGetList .. GetTickCount()
	LOG.TABLE({"PostGetNameAndAuthor", tHttpData})
	CURL_HttpPost(szPreRequestKey, GetAPIURL(),
		JsonEncode(tHttpData), true, 60, 60, { [1] = "Content-Type:application/json"})
end

--大唐家园界面
function Homeland_GetDigitalBlueprintNameAndAuthorUI(szGlobalID, nType)
	local tHttpData = {}
	tHttpData["globalRoleId"] = szGlobalID
	tHttpData["mapType"] = nType
	Homeland_TransformDataEncode(tHttpData)
	szPreRequestKey = szKeyForGetListUI .. GetTickCount()
	UILog("PostGetNameAndAuthorUI", tHttpData)
	CURL_HttpPost(szPreRequestKey, GetAPIURL(),
		JsonEncode(tHttpData), true, 60, 60, { [1] = "Content-Type:application/json"})
end

function Homeland_OnGetDigitalBlueprintNameAndAuthor(tInfo)
	tInfo = tInfo.data
	local szName = UIHelper.UTF8ToGBK(tInfo.assetName)
	local szAuthor = UIHelper.UTF8ToGBK(tInfo.creatorName)
	RemoteCallToServer("On_Home_ShowBlNameAuthor", szName, szAuthor)
end

Event.Reg(HomelandCommon, "ON_WEB_DATA_SIGN_NOTIFY", Homeland_OnApplyWebDataSign)
Event.Reg(HomelandCommon, "CURL_REQUEST_RESULT", function()
	local szKey = arg0
	local bSuccess = arg1
	local szValue = arg2
	local uBufSize = arg3
	if szKey == szPreRequestKey and bSuccess then
		local tInfo, szErrMsg = JsonDecode(szValue)
		if tInfo and tInfo.code then
			Homeland_Log("ERROR CODE", tInfo.code)
		end
		if not tInfo.data then
			return
		end
		if string.find(szPreRequestKey, "DaTangJiaYuanUI") then
			local tData = tInfo.data
			local szName = tData.assetName
			local szAuthor = tData.creatorName
			if szName and szName ~= "" then
				TipsHelper.ShowNormalTip(FormatString(g_tStrings.STR_HOMELNAD_DIGITAL_BLUEPRINT_NAME_AUTHOR, szName, szAuthor))
			else
				TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELNAD_DIGITAL_BLUEPRINT_NAME_AUTHOR_NULL)
			end
		else
			Homeland_OnGetDigitalBlueprintNameAndAuthor(tInfo)
		end
	end
end)

HLBView_Message = HLBView_Message or {}
function HLBView_Message.Show(szMsg, nTime)
	TipsHelper.ShowNormalTip(szMsg, false)
end