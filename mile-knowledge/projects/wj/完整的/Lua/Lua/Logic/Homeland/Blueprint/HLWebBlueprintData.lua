HLWebBlueprintData = HLWebBlueprintData or {className = "HLWebBlueprintData"}

local m_szCipher = nil
local m_szPreRequestKey = nil
local m_tFileName2Index = {}
local m_nLastFreshTime = 0
local m_CDTime = 0

local DEFAULT_SELECT_INDEX = 0
local DEFAULT_SEARCH_TYPE = 1
local ITEM_PRE_PAGE = 100
local REOPEN_CD = 5

local tSearchType2Name = {
	[1] = g_tStrings.STR_BLUEPRINT_PANEL_SEARCH_TYPE_BLUEPRINT,
	[2] = g_tStrings.STR_BLUEPRINT_PANEL_SEARCH_TYPE_AUTHOR,
}

local tIndex2RequestArea = {
	[0] = {szName = g_tStrings.tDigitHomelandBlueprintCatg[0], nRequestMapType = 0, szRequestHomeArea = ""},
	[1] = {szName = g_tStrings.tDigitHomelandBlueprintCatg[1], nRequestMapType = 0, szRequestHomeArea = "1280" .. g_tStrings.STR_BLUEPRINT_PANEL_CATG},
	[2] = {szName = g_tStrings.tDigitHomelandBlueprintCatg[2], nRequestMapType = 0, szRequestHomeArea = "2240" .. g_tStrings.STR_BLUEPRINT_PANEL_CATG},
	[3] = {szName = g_tStrings.tDigitHomelandBlueprintCatg[3], nRequestMapType = 0, szRequestHomeArea = "4032" .. g_tStrings.STR_BLUEPRINT_PANEL_CATG},
	[4] = {szName = g_tStrings.tDigitHomelandBlueprintCatg[4], nRequestMapType = 0, szRequestHomeArea = "6272" .. g_tStrings.STR_BLUEPRINT_PANEL_CATG},
	[5] = {szName = g_tStrings.tDigitHomelandBlueprintCatg[5], nRequestMapType = 0, szRequestHomeArea = "7200" .. g_tStrings.STR_BLUEPRINT_PANEL_CATG},
	[6] = {szName = g_tStrings.tDigitHomelandBlueprintCatg[6], nRequestMapType = 0, szRequestHomeArea = "11648" .. g_tStrings.STR_BLUEPRINT_PANEL_CATG},
	[7] = {szName = g_tStrings.tDigitHomelandBlueprintCatg[7], nRequestMapType = 0, szRequestHomeArea = "45792" .. g_tStrings.STR_BLUEPRINT_PANEL_CATG},
	[8] = {szName = g_tStrings.tDigitHomelandBlueprintCatg[8], nRequestMapType = 2, szRequestHomeArea = ""},
}

local USE_MAP = {
	COMMUNITY = 1,
	PRIVATE = 2,
	BOTH = 3,
}

local tUseMap2Frame = {
	[USE_MAP.COMMUNITY] = 32,
	[USE_MAP.PRIVATE] = 33,
	[USE_MAP.BOTH] = 15,
}

local szKeyForGetList = "HomelandGetList"
local szUrlForGetList = "https://gdca-blueprint-api.xoyo.com/gamegw/home-blueprint/get-digital-asset-list"
local szUrlForGetList_Test = "http://120.92.151.103/gamegw/home-blueprint/get-digital-asset-list"
local szWebDataSign = "REQUEST_FOR_GET_BLUEPRINT_LIST"

local function GetAPIURL()
	if IsDebugClient() or IsVersionExp() then
		return szUrlForGetList_Test
	else
		return szUrlForGetList
	end
end

function HLWebBlueprintData.Init()
	HLWebBlueprintData.nPage = 1
	HLWebBlueprintData.nMaxPage = 1
	HLWebBlueprintData.tList = {}
	HLWebBlueprintData.szSelectIndex = DEFAULT_SELECT_INDEX
	HLWebBlueprintData.nSearchType = DEFAULT_SEARCH_TYPE
	HLWebBlueprintData.szKeyword = ""

	HLWebBlueprintData.RegEvent()
end

function HLWebBlueprintData.UnInit()
	HLWebBlueprintData.nPage = 1
	HLWebBlueprintData.nMaxPage = 1
	HLWebBlueprintData.tList = nil
	HLWebBlueprintData.szSelectIndex = DEFAULT_SELECT_INDEX
	HLWebBlueprintData.nSearchType = DEFAULT_SEARCH_TYPE
	HLWebBlueprintData.szKeyword = ""

	Event.UnRegAll(HLWebBlueprintData)
end

function HLWebBlueprintData.RegEvent()
	Event.Reg(HLWebBlueprintData, "ON_WEB_DATA_SIGN_NOTIFY", function ()
		local szOrderSN                 = arg6
		local dwType 					= arg1
		if not (dwType == WEB_DATA_SIGN_RQST.LOGIN and szOrderSN == szWebDataSign) then
			return
		end
		HLWebBlueprintData.OnApplySign()
		HLWebBlueprintData.PostGetList()
	end)

	Event.Reg(HLWebBlueprintData, "CURL_REQUEST_RESULT", function ()
		local szKey = arg0
		local bSuccess = arg1
		local szValue = arg2
		local uBufSize = arg3
		if szKey == m_szPreRequestKey and bSuccess then
			local tInfo, szErrMsg = JsonDecode(szValue)
			if tInfo and tInfo.code then
				Homeland_Log("ERROR CODE", tInfo.code)
			end
			HLWebBlueprintData.OnPostGetList(tInfo)
		end
	end)

	Event.Reg(HLWebBlueprintData, "CURL_DOWNLOAD_RESULT", function ()
		local bSuccess = arg1
		local szFileName = arg0
		if not bSuccess then
			UILog("下载图片失败")
			return
		end
		if not m_tFileName2Index[szFileName] then
			return
		end

		Event.Dispatch(EventType.OnUpdateHLWebBlueprintList)
		-- View.UpdatePic(szFileName)
	end)
end

function HLWebBlueprintData.GetQuestParm()
	local nQuestPage = HLWebBlueprintData.nPage
	local szRequestHomeArea = ""
	local nRequestMapType = 0
	local tInfo = tIndex2RequestArea[HLWebBlueprintData.szSelectIndex]
	if tInfo then
		szRequestHomeArea = tInfo.szRequestHomeArea
		nRequestMapType = tInfo.nRequestMapType
	end
	local nRequestSearchType = HLWebBlueprintData.nSearchType
	local szRequestKeyword = HLWebBlueprintData.szKeyword
	return nQuestPage, szRequestHomeArea, nRequestMapType, nRequestSearchType,szRequestKeyword
end

function HLWebBlueprintData.HandleResponse(tInfo)
	if tInfo.code ~= 0 then
		UILog("出错", tInfo, HLWebBlueprintData.GetQuestParm())
		HLBView_Message.Show(g_tStrings.STR_BLUEPRINT_PANEL_ASK_FOR_LIST_FAILED, 3)
		return
	end
	local tList = {}
	local tData = tInfo.data.data
	HLWebBlueprintData.nPage = tInfo.data.cursor
	HLWebBlueprintData.nMaxPage = math.max(math.ceil(tInfo.data.total / ITEM_PRE_PAGE), 1)
	Homeland_Log("cursor", tInfo.data.cursor, tInfo.data.total)
	HLWebBlueprintData.tList = {}
	if tData then
		for i = 1, #tData do
			local tItem = {}
			local tTemp = tData[i]
			tItem.szTitle = tTemp.title
			tItem.szDescription = (tTemp.description)
			tItem.szAuthor = (tTemp.author)
			tItem.nFurnitureCount = tonumber(tTemp.furnitureCount)
			tItem.szDownloadPic = (tTemp.picDownloadUrl)
			tItem.nCount = tTemp.count
			tItem.bInUse = tTemp.isUse
			tItem.bExistReplica = tTemp.isExistReplica
			tItem.nMatchRate = tTemp.matchRate
			tItem.szCode = (tTemp.issueAssetCode)
			tItem.szDetailUrl = tTemp.detailUrl
			tItem.eUseMap = tTemp.useMap
			table.insert(tList, tItem)
		end
		HLWebBlueprintData.tList = tList
	end
	Homeland_Log("tList", tList)

	Event.Dispatch(EventType.OnUpdateHLWebBlueprintList)
end

function HLWebBlueprintData.UpdateCD()
	local hFrame = GetFrame()
	local hCD = hFrame:Lookup("Wnd_CD_Digit")
	local hText = hCD:Lookup("", "Text_CD_Digit")
	local hWndEmpty = hFrame:Lookup("Wnd_Empty_Digit")
	hWndEmpty:Hide()
	if m_nCDTime > 0 then
		hText:SetText(FormatString(g_tStrings.STR_HOMELAND_BUILDING_LOAD_BLUEPRINT_IN_CD, m_nCDTime))
		HLBView_Blueprint.ShowEmptyBg(false)
		hCD:Show()
	else
		HLBView_Blueprint.ShowEmptyBg(true)
		hCD:Hide()
		if IsOpened() then
			ApplySign()
		end
	end
end

function HLWebBlueprintData.ApplySign()
	local pPlayer = GetClientPlayer()
	if not pPlayer then
		return
	end
	Log("ApplySign")
	-- View.DisableAllFrame()
	pPlayer.ApplyWebDataSign(WEB_DATA_SIGN_RQST.LOGIN, szWebDataSign)
end

function HLWebBlueprintData.OnApplySign()
	local uSign                     = arg0
	local dwType 					= arg1
	local nTime                     = arg2
	local nZoneID                   = arg3
	local dwCenterID                = arg4
	local bIsFirstWebPhoneVerified  = arg5
	local szOrderSN                 = arg6

	if not (dwType == WEB_DATA_SIGN_RQST.LOGIN and szOrderSN == szWebDataSign) then
		return
	end

	local szCipher = Homeland_GenerateCipher(uSign, dwType, nTime, nZoneID, dwCenterID)
	Log("==== Blueprint szCipher === " .. tostring(szCipher))
	m_szCipher = szCipher
end

function HLWebBlueprintData.PostGetList()
	local nQuestPage, szRequestHomeArea, nRequestMapType, nRequestSearchType,szRequestKeyword =
		HLWebBlueprintData.GetQuestParm()
	local tHttpData = {}
	tHttpData["cipher"] = m_szCipher
	tHttpData["globalRoleId"] = GetClientPlayer().GetGlobalID()
	tHttpData["type"] = 1
	tHttpData["homeArea"] = szRequestHomeArea
	tHttpData["mapType"] = nRequestMapType
	tHttpData["searchType"] = nRequestSearchType
	tHttpData["keyword"] = szRequestKeyword
	tHttpData["cursor"] = nQuestPage
	tHttpData["size"] = ITEM_PRE_PAGE
	UILog("PostGetList", tHttpData)
	-- Homeland_TransformDataEncode(tHttpData)
	m_szPreRequestKey = szKeyForGetList .. GetTickCount()
	CURL_HttpPost(m_szPreRequestKey, GetAPIURL(),
		JsonEncode(tHttpData), true, 60, 60, { [1] = "Content-Type:application/json"})
	-- View.DisableAllFrame()
end

function HLWebBlueprintData.DownloadPic()
	m_tFileName2Index = {}
	for nIndex, tInfo in ipairs(HLWebBlueprintData.tList) do
		local szFileName = HLWebBlueprintData.GetPicName(tInfo.szDownloadPic)
		local szLocalFile = Homeland_GetDownloadPath(szFileName)
		m_tFileName2Index[szFileName] = nIndex
		if not Lib.IsFileExist(szLocalFile) then
			LOG.INFO("DownloadFile:%s", szLocalFile)
			local szDowloadUrl = tInfo.szDownloadPic
			local nPos = string.find(szDowloadUrl, "?imageMogr2")
			if nPos then
				szDowloadUrl = string.sub(szDowloadUrl, 1, nPos - 1)
			end
			szDowloadUrl = szDowloadUrl .. "?imageMogr2/thumbnail/!30p/format/png"
			CURL_DownloadFile(szFileName, szDowloadUrl, szLocalFile, true, 120)
		end
	end

	Event.Dispatch(EventType.OnUpdateHLWebBlueprintList)
end

function HLWebBlueprintData.OnPostGetList(tInfo)
	HLWebBlueprintData.HandleResponse(tInfo)
	-- View.Update()
	HLWebBlueprintData.DownloadPic()
	-- View.EnableAllFrame()
end

function HLWebBlueprintData.GetPicName(szURL)
	local szFileName = ""
	local tInfo = SplitString(szURL, "/")
	szFileName = tInfo[4]

	if not Platform.IsWindows() then
		return szFileName .. ".mpng"
	end

	return szFileName .. ".png"
end