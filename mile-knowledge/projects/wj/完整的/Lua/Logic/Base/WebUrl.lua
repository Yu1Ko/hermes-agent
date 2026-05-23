WebUrl = WebUrl or {className = "WebUrl"}

local m_tWebData = {}
local m_tSuffix = {}

local function ParseTime(szTime)
	local tTime = StringParse_IDList(szTime)
	for i in ipairs(tTime) do
		tTime[i] = Time_AddZone(tTime[i])
	end

	return tTime
end

local function ProcessCenterID(szCenterID)
	local tResult 		= {}
	local tCenterID 	= SplitString(szCenterID, ";")
	local nCntCenterID 	= #tCenterID
	for j = 1, nCntCenterID do
		local nCenterID = tonumber(tCenterID[j])
		if nCenterID then
			tResult[nCenterID] = true
		end
	end
	return tResult
end

local function LoadWebData()
	local nTime = GetCurrentTime()
	local nCount = g_tTable.WebUrlData:GetRowCount()
	m_tWebData = {}
	for i = 2, nCount do
		local tLine = g_tTable.WebUrlData:GetRow(i)
		tLine.tStartTime = ParseTime(tLine.szStartTime)
		tLine.tEndTime = ParseTime(tLine.szEndTime)
		m_tWebData[tLine.dwID] = tLine
		m_tWebData[tLine.dwID].tCenterID = ProcessCenterID(tLine.szCenterID)
	end
end

local function CanShowByTime(dwID)
	if not m_tWebData[dwID] then
		return false
	end
	local t = m_tWebData[dwID]
	local bStart = false

	local nTime = GetCurrentTime()
	if #t.tStartTime == 0 then
		bStart = true
	else
		for k, v in ipairs(t.tStartTime) do
			if nTime >= v then
				bStart = true
				break
			end
		end
	end
	if not bStart then
		return false
	end
	if #t.tStartTime == 0 then
		return true
	else
		for k, v in ipairs(t.tEndTime) do
			if nTime <= v then
				return true
			end
		end
	end

	return false
end

local function CanShowByCenterID(dwID)
	if not m_tWebData[dwID] then
		return false
	end

	local nCenterID = GetCenterID()
	if (GetTableCount(m_tWebData[dwID].tCenterID) == 1 and m_tWebData[dwID].tCenterID[0]) or
		m_tWebData[dwID].tCenterID[nCenterID]
	then
		return true
	end

	return false
end

local function CanShowByExtPoint(dwID)
	if not m_tWebData[dwID] then
		return false
	end

	local t = m_tWebData[dwID]
	if t.nExtPoint <= 0 then-- 有填扩展点才需要判断
		return true
	end

	local pPlayer = GetClientPlayer()
	if not pPlayer then
		return false
	end

	local nValue = pPlayer.GetExtPoint(t.nExtPoint) or 0
	return nValue == 1  --只有扩展点的值为1时才需要显示，否则都不需要
end

function WebUrl.Init()
	m_tWebData = {}

    Event.Reg(WebUrl, "FIRST_LOADING_END", function()

    end)

	Event.Reg(WebUrl, "ON_WEB_DATA_SIGN_NOTIFY", function()
		WebUrl.OnWebDataSignNotify()
    end)

	Event.Reg(WebUrl, "WEB_SIGN_NOTIFY", function()
		if arg3 == 2 or arg3 == 4  then
			WebUrl.OnLoginWebDataSignNotify()
		end
    end)

	LoadWebData()
end

function WebUrl.UnInit()
	Event.UnRegAll(WebUrl)
end

function WebUrl.CanShow(dwID)
	return CanShowByTime(dwID) and CanShowByCenterID(dwID) and CanShowByExtPoint(dwID)
end

function WebUrl.ApplySignWeb(dwID, nSignType)
	local pPlayer = GetClientPlayer()
	if not pPlayer then
		return
	end

	pPlayer.ApplyWebDataSign(nSignType, "APPLY_WEBID_" .. dwID)
end

function WebUrl.ApplyLoginSignWeb(dwID, nSignType)
	Login_WebSignRequest(nSignType, "APPLY_LOGIN_WEBID_" .. dwID)
end

function WebUrl.OpenByID(dwID , bUseInsideWeb , bPortrait, szSuffix)
	LOG.INFO("WebUrl.OpenByID, dwID = %s", tostring(dwID))

	local tInfo = m_tWebData[dwID]
	if not tInfo then
		LOG.ERROR("WebUrl.OpenByID has not info by dwID = %s.", tostring(dwID))
		return
	end

	LOG.INFO("WebUrl.OpenByID, szUrl = %s", tostring(tInfo.szUrl))

	if not WebUrl.CanShow(dwID) then
		LOG.ERROR("WebUrl.OpenByID can not show.")
		return
	end

	WebUrl.bUseInsideWeb = bUseInsideWeb
	WebUrl.bPortrait = bPortrait

	m_tSuffix[dwID] = szSuffix
	if tInfo.bLoginSign and not LoginMgr.IsInGame() then
		if LoginMgr.IsLogin() then
			local nSignType = tInfo.nSignType > 0 and tInfo.nSignType or 2
			WebUrl.ApplyLoginSignWeb(dwID, nSignType)
			return
		end
	end

	if tInfo.bSign  then
		if not tInfo.bRemoteSign and CheckPlayerIsRemote() then --bRemoteSign表示跨服中也发起签名，比如万宝楼
			return
		end

		local nSignType = tInfo.nSignType > 0 and tInfo.nSignType or WEB_DATA_SIGN_RQST.LOGIN
		WebUrl.ApplySignWeb(dwID, nSignType)
	else
		WebUrl.OnOpenNoSign(dwID)
	end
end

function WebUrl.CloseByID(dwID)
	local t = m_tWebData[dwID]
	if t.nWebType == WEBURL_TYPE.SIMPLE_WEB or t.nWebType == WEBURL_TYPE.INTERNETEXPLORER then
		UIMgr.Close(VIEW_ID.PanelEmbeddedWebPages)
	end
end

function WebUrl.OnOpenNoSign(dwID)
	local t = m_tWebData[dwID]

	local szUrl = t.szUrl
	if t.szParam ~= "" then
		local tParam = WebUrl.GetParam(t.szParam)
		szUrl = string.format(szUrl, unpack(tParam))
	end

	WebUrl.OnOpen(t, szUrl)
end

function WebUrl.GetParam(szParam)
	local player = GetClientPlayer()
	if not player then
		return ""
	end

	szParam = string.gsub(szParam, "<(.-)>", function(szkey)
			local Value = ""
			if szkey == "ForceID" then
				Value = player.dwForceID
			elseif szkey == "RoleName" then
				Value = UrlEncode(UIHelper.GBKToUTF8(player.szName))
			elseif szkey == "CreateTime" then
				Value = player.GetCreateTime()
			elseif szkey == "Level" then
				Value = player.nLevel
			elseif szkey == "Account" then
				Value = Login_GetAccount()
			elseif szkey == "RoleID" then
				Value = player.dwID
			elseif szkey == "GlobalID" then
				Value = player.GetGlobalID()
			elseif szkey == "Time" then
				Value = GetCurrentTime()
			elseif szkey == "ServerCode" then
				local _, szUserServer = GetUserServer()
				Value = LoginServerList.GetServerCode(szUserServer)
			elseif szkey == "CenterName" then
				Value = UrlEncode(UIHelper.GBKToUTF8(GetCenterName()))
			elseif szkey == "UserRegion" then
				local szUserRegion, szUserSever = WebUrl.GetServerName()
				Value = UrlEncode(szUserRegion)
			elseif szkey == "UserSever" then
				local szUserRegion, szUserSever = WebUrl.GetServerName()
				Value = UrlEncode(szUserSever)
			elseif szkey == "sourceId" then
				Value = 62203
			end
			return Value
		end
	)
	return szParam
end

function WebUrl.OnOpen(t, szUrl)
	if t.nWebType == WEBURL_TYPE.SIMPLE_WEB or t.nWebType == WEBURL_TYPE.INTERNETEXPLORER or WebUrl.bUseInsideWeb then
		UIHelper.OpenWeb(szUrl , FORCE_USE_EMBEDDED_WEBPAGES_IN_WINDOWS_ID[t.dwID] , WebUrl.bPortrait)
	else
		UIHelper.OpenWebWithDefaultBrowser(szUrl)
	end
	WebUrl.bUseInsideWeb = false
	WebUrl.bPortrait = false
end

-- 不跳转浏览器，在dx其实是用szFunction但不知道为啥没接
local tbIgnoreID = {
	[69] = true, -- 69乐谱网页
	[80] = true, -- AI动捕
}

function WebUrl.OnOpenSignWeb(dwID, uSign, nTime, nZoneID, dwCenterID)
	if not WebUrl.CanShow(dwID) then
		return
	end

	local t = m_tWebData[dwID]
	if tbIgnoreID[dwID] then
		if t.szFunction then
			UIGlobalFunction[t.szFunction](dwID, uSign, nTime, nZoneID, dwCenterID)
		end
		return
	end

	local dwPlayerID = 0
	local dwForceID = 0
	local szRoleName = ""
	local dwCreateTime = 0
	local szGlobalID = ""

	local player = GetClientPlayer()
	if player then
		dwPlayerID = player.dwID
		dwForceID = player.dwForceID
		szRoleName =  UrlEncode(UIHelper.GBKToUTF8(player.szName))
		dwCreateTime = player.GetCreateTime()
		szGlobalID = player.GetGlobalID()
	end

	local szAccount = Login_GetAccount()
	local szUserRegion, szUserSever = WebUrl.GetServerName()
	--param=sign/account/roleID/time/zoneID/centerID/测试区/测试服/门派ID/角色名称/角色创建时间/账号类型
	local szDefaultParam = "param=%d/%s/%d/%d/%d/%d/%s/%s/%d/%s/%d/%d"
	szDefaultParam = string.format(
		szDefaultParam, uSign, szAccount, dwPlayerID, nTime, nZoneID,
		dwCenterID, UrlEncode(szUserRegion), UrlEncode(szUserSever),
		dwForceID, szRoleName, dwCreateTime, GetAccountType()
	)

	szDefaultParam = string.format("&game=jx3&tid=%d&role_id=%s&%s", t.nSignType, szGlobalID, szDefaultParam)

	local szUrl = t.szUrl
	if not string.find(szUrl, "?") then
		szUrl = szUrl .. "?"
	end
	szUrl = szUrl .. szDefaultParam
	if dwID == WEBURL_ID.WAN_BAO_LOU_ITEM and m_tSuffix[dwID] then
		local bTestMode = IsDebugClient()
		if bTestMode then
			szUrl = szUrl .. "&redirect=" .. UrlEncode("https://qa-jx3.seasunwbl.com/buyer?appearance_name=" .. UIHelper.GBKToUTF8(m_tSuffix[dwID]) .. "&t=skin")
		else
			szUrl = szUrl .. "&redirect=" .. UrlEncode("https://jx3.seasunwbl.com/buyer?appearance_name=" .. UIHelper.GBKToUTF8(m_tSuffix[dwID]) .. "&t=skin")
		end
		m_tSuffix[dwID] = nil
	end
	WebUrl.OnOpen(t, szUrl)
end

function WebUrl.OnWebDataSignNotify()
	local szComment = arg6
	local dwApplyWebID = szComment:match("APPLY_WEBID_(.*)")
	if dwApplyWebID then
		dwApplyWebID = tonumber(dwApplyWebID)
		local uSign = arg0
		local nTime = arg2
		local nZoneID = arg3
		local dwCenterID = arg4
		WebUrl.OnOpenSignWeb(dwApplyWebID, uSign, nTime, nZoneID, dwCenterID)
	end
end

function WebUrl.OnLoginWebDataSignNotify()
	local szComment = arg2
	local dwApplyWebID = szComment:match("APPLY_LOGIN_WEBID_(.*)")
	if dwApplyWebID then
		dwApplyWebID = tonumber(dwApplyWebID)
		local uSign = arg0
		local nTime = arg1
		local nZoneID = 0
		local dwCenterID = 0
		WebUrl.OnOpenSignWeb(dwApplyWebID, uSign, nTime, nZoneID, dwCenterID)
	end
end

function WebUrl.GetServerName()
	local szUserRegion, szUserSever = "", ""
    local tbRecentLoginData = Storage.RecentLogin.tbServer
    local nMaxTime, tbRecentLogin = 0, nil
    for szKey, tbLogin in pairs(tbRecentLoginData) do
        if tbLogin.nTime >= nMaxTime then
            nMaxTime = tbLogin.nTime
            tbRecentLogin = tbLogin
        end
    end

	if tbRecentLogin then
		szUserRegion, szUserSever = tbRecentLogin.szRegion, tbRecentLogin.szServer
	end

	local moduleServerList = LoginMgr.GetModule(LoginModule.LOGIN_SERVERLIST)
    if not moduleServerList then
        return szUserRegion, szUserSever
    end

    local tServer = moduleServerList.GetSelectServer()
	if tServer then
		if tServer.szRealRegion and tServer.szRealServer then
			szUserRegion, szUserSever = tServer.szRealRegion, tServer.szRealServer
		elseif tServer.szRegion and tServer.szServer then
			szUserRegion, szUserSever = tServer.szRegion, tServer.szServer
		end
	end

    return szUserRegion, szUserSever
end