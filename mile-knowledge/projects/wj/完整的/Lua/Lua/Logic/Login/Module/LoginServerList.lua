local LoginServerList = {className = "LoginServerList"}
local self = LoginServerList

local m_szURL = GetServerListUrl()
--local m_szURL = "http://jx3comm.xoyocdn.com/jx3hd/zhcn_hd/serverlist/serverlist.ini"

local m_szSelectRegion
local m_szSelectServer

local COMMEND_STATE =  --推荐状态
{
	COMMEND    = 0, --推荐
	UN_COMMEND = 1, -- 不推荐
	UN_CREATE  = 2, -- 绝育
}

function LoginServerList.RegisterEvent()
    Event.Reg(self, "CURL_REQUEST_RESULT", self.OnCURLRequestResult)
end

function LoginServerList.OnEnter(szPrevStep)
    Event.Dispatch(EventType.Login_UpdateState)
end

function LoginServerList.OnExit(szNextStep)

end

-------------------------------- Public --------------------------------

function LoginServerList.CanCreateRole(tbServer)
    tbServer = tbServer or self.GetSelectServer()
    local nCommendState = tbServer and tbServer.nCommendState or COMMEND_STATE.UN_COMMEND
    return nCommendState ~= COMMEND_STATE.UN_CREATE
end

function LoginServerList.SetSelectServer(szRegion, szServer)
    local tbServer = self.GetServer(szRegion, szServer)
    if tbServer then
        m_szSelectRegion = tbServer.szRegion --为了优先从推荐/最近服务器中搜索服务器，szRegion可能为空
        m_szSelectServer = szServer
    end

    Event.Dispatch(EventType.Login_SelectServer, tbServer)
    APIHelper.SetWindowTitle()
end

function LoginServerList.GetSelectServer()
    local tbServer
    if m_szSelectRegion and m_szSelectServer then
        tbServer = self.GetServer(m_szSelectRegion, m_szSelectServer)
    end
    return tbServer
end

function LoginServerList.GetServer(szRegion, szServer)
    if szRegion then
        local tbRegion = self.GetRegion(szRegion)
        return self.GetServerInRegion(tbRegion, szServer)
    else
        for i = 1, #g_tbLoginData.aServerList do
            local tbRegion = g_tbLoginData.aServerList[i]
            local tbServer = self.GetServerInRegion(tbRegion, szServer)
            if tbServer then
                return tbServer
            end
        end
    end
end

function LoginServerList.GetServerInRegion(tbRegion, szServer)
    if not tbRegion then return end
    for i = 1, #tbRegion do
        if tbRegion[i].szServer == szServer then
            return tbRegion[i]
        end
    end
end

function LoginServerList.GetRegion(szRegion)
    for i = 1, #g_tbLoginData.aServerList do
        local tbRegion = g_tbLoginData.aServerList[i]
        if tbRegion.szRegion == szRegion then
            return tbRegion
        end
    end
end

function LoginServerList.GetRegionByDisplay(szDisplayRegion)
    for i = 1, #g_tbLoginData.aServerList do
        local tbRegion = g_tbLoginData.aServerList[i]
        if tbRegion.szDisplayRegion == szDisplayRegion then
            return tbRegion
        end
    end
end

function LoginServerList.SaveRecentLoginServer()
    local tbServer = self.GetSelectServer()
    local tbRecentLoginData = Storage.RecentLogin.tbServer
    if tbServer then
        local szKey = tbServer.szRegion.."/"..tbServer.szServer
        local tbRecentLogin = tbRecentLoginData[szKey]

        if not tbRecentLogin then
            tbRecentLogin = {}
            tbRecentLoginData[szKey] = tbRecentLogin
        end

        --更新登录服务器信息
        tbRecentLogin.szRegion = tbServer.szRegion
        tbRecentLogin.szServer = tbServer.szServer
        tbRecentLogin.nTime = Timer.GetTime()

        Storage.RecentLogin.Dirty()
    end
end

function LoginServerList.LoadRecentLoginServer()
    local tbRecentLoginData = Storage.RecentLogin.tbServer
    local nMaxTime, tbRecentLogin = 0, nil
    for szKey, tbLogin in pairs(tbRecentLoginData) do
        if tbLogin.nTime >= nMaxTime then
            nMaxTime = tbLogin.nTime
            tbRecentLogin = tbLogin
        end
    end
    return tbRecentLogin
end

-------------------------------- Protocol --------------------------------

function LoginServerList.ForceRequestServerList()
    if not g_tbLoginData.bUseRemoteServerList or not m_szURL or m_szURL == "" then
        return
    end

    LoginMgr.Log(self, "ForceRequestServerList CURL_HttpRqst LOGIN_SERVER_LIST: %s", m_szURL)

    local bSSL = string.starts(m_szURL, "https")
    CURL_HttpRqst("LOGIN_SERVER_LIST", m_szURL, bSSL, 10)
end

function LoginServerList.RequestServerList(bWithoutWait)
    if not LoginMgr.SetWaiting(true, g_tStrings.tbLoginString.SERVER_LIST_REQUESTING) then return end
    LoginMgr.Log(self, "RequestServerList, bUseRemoteServerList = %s, szURL = %s", tostring(g_tbLoginData.bUseRemoteServerList), tostring(m_szURL))

    if not g_tbLoginData.bUseRemoteServerList or not m_szURL or m_szURL == "" then
        Timer.AddFrame(self, 1, function ()
            LoginMgr.SetWaiting(false)
            self._parseLocalServerList()
            self._serverListRequestSuccess()
        end)
    elseif not g_tbLoginData.bRequestServerList and not g_tbLoginData.bRequestServerListSuccess then
        g_tbLoginData.bRequestServerList = true
        g_tbLoginData.bRequestServerListSuccess = false

        -- local _, _, szLang = GetVersion()
        -- if szLang ~= "zhcn" or IsVersionExp() then --海外版和台服不做CRC校验
        --     LoginMgr.Log(self, "Request ServerList: %s", m_szURL)
        --     CURL_HttpRqst("LOGIN_SERVER_LIST", m_szURL, false, 10)
        -- else
        --     LoginMgr.Log(self, "Request ServerList CRC: %s", m_szURL .. ".crc")
        --     CURL_HttpRqst("LOGIN_SERVER_LIST_CRC", m_szURL .. ".crc", false, 15)
        -- end
        LoginMgr.Log(self, "RequestServerList CURL_HttpRqst LOGIN_SERVER_LIST: %s", m_szURL)

        local bSSL = string.starts(m_szURL, "https")
        CURL_HttpRqst("LOGIN_SERVER_LIST", m_szURL, bSSL, 10)
    end
end

function LoginServerList.OnCURLRequestResult(szKey, bSuccess, szContent, dwBufferSize)
    --LoginMgr.Log(self, "OnCURLRequestResult: %s, bSuccess: %s", szKey, tostring(bSuccess))
    if szKey == "LOGIN_SERVER_LIST_CRC" then
        LoginMgr.SetWaiting(false)
        if bSuccess then
            local dwCRC = tonumber(szContent)
            LoginMgr.Log(self, "CRC Received: %s", szContent)
            --local szFile = GetJX3TempPath() .. GetServerListCacheFileRelPath(dwCRC)

            if dwCRC then
                --TODO luwenhao1 检查缓存 端游LoginServerList.lua: 626

                --若同CRC有缓存则不需要请求

                LoginMgr.SetWaiting(true, g_tStrings.tbLoginString.SERVER_LIST_REQUESTING)

                LoginMgr.Log(self, "Request ServerList: %s", m_szURL)

                local bSSL = string.starts(m_szURL, "https")
                CURL_HttpRqst("LOGIN_SERVER_LIST" .. dwCRC, m_szURL, bSSL, 10)
                return
            end
        end

        LoginMgr.Log(self, "CRC Request Failed!")
        g_tbLoginData.bRequestServerList = false
        --self._parseLocalServerList()
    elseif szKey:sub(1, 17) == "LOGIN_SERVER_LIST" then
        LoginMgr.SetWaiting(false)
        g_tbLoginData.bRequestServerList = false

        local dwCRC = tonumber((szKey:sub(18)))
        if not bSuccess then
            LoginMgr.Log(self, "ServerList Request Failed!")
            -- 保底操作：如果服务器上的服务器列表读不到，那就读本地的（前提是从来没有请求成功过）
            if not self.bRequestServerListSuccessed and Version.IsMB() or Version.IsEXP() then
                self._parseLocalServerList()
            end
            self._serverListRequestSuccess()
        elseif dwCRC and dwCRC ~= GetStringCRC(szContent) then
            LoginMgr.Log(self, "CRC Check Failed! Remote: %s, Cache: %s", dwCRC, GetStringCRC(szContent))
        else
            self.bRequestServerListSuccessed = true

            szContent = GBKToUTF8(szContent)
            --TODO luwenhao1 缓存服务器列表 端游LoginServerList.lua: 652
            -- local szFile = GetJX3TempPath() .. GetServerListCacheFileRelPath(dwCRC)
            -- SaveDataToFile(szContent, szFile)

            self._parseServerListString(szContent)
            LoginMgr.Log(self, "OnParseRemoveServerListSuccess")
            self._serverListRequestSuccess()

            Event.Dispatch(EventType.OnServerListReqSuccessed)

            return
        end

        --self._parseLocalServerList()
    end
end

-------------------------------- Private --------------------------------

function LoginServerList._serverListRequestSuccess()
    LoginMgr.Log(self, "OnServerListRequestSuccess")

    g_tbLoginData.bRequestServerListSuccess = true

    --服务器列表拉取完成，设置上次登录服务器与账号
    if g_tbLoginData.LoginView then
        g_tbLoginData.LoginView:InitRecentLogin()
    end
end

function LoginServerList._parseLocalServerList()
    local aServerList = {}

    local tbDevServerList = g_tbLoginData.GetDevServerList()
    for _, v in ipairs(tbDevServerList) do
        local szRegion = v[1]
        local szServer = v[2]
        local szIp = v[4]
        local szPort = tonumber(v[5]) or 0
        local szSerial = v[10] or "z01"

        local aServer = {}
        aServer[1] = szRegion                           --szSimpleRegion
        aServer[2] = szServer                           --szServer
        aServer[3] = tonumber(v[3])                     --nState
        aServer[4] = szIp                               --szIP
        aServer[5] = szPort                             --nPort
        aServer[6] = szRegion                           --szDisplayRegion
        aServer[7] = szServer                           --szDisplayServer
        aServer[8] = 0                                  --nAreaID
        aServer[9] = 0                                  --nGroupID
        aServer[10] = szSerial                          --szSerial
        aServer[11] = szServer                          --szRealServer
        aServer[12] = szRegion                          --szRegion
        aServer[13] = nil                               --szStatePath
        aServer[14] = nil                               --nStateFrame
        aServer[15] = false                             --bPvp
        aServer[16] = 0                                 --nServerMark

        table.insert(aServerList, aServer)
    end
    self._parseServerList(aServerList)

    LoginMgr.Log(self, "OnParseLocalServerListSuccess")
end

function LoginServerList._parseServerListString(szValue)
    if not szValue then
        return
    end

    -- ParseServerListFromString
    local aServerList = LoginServerDef.ParseServerListString(szValue)
    self._parseServerList(aServerList)
end

function LoginServerList._parseServerList(aServerList)
    if not aServerList then
        return
    end

    local aIPList = {}

    local nRegionIndex = 1
	local tList        = {}
	local aRecent      = { nRegionIndex = -1, szRegion = g_tStrings.STR_SERVER_STATUS_RECENT , szDisplayRegion = g_tStrings.STR_SERVER_STATUS_RECENT , szSimpleRegion = g_tStrings.STR_SERVER_STATUS_RECENT , bRecent  = true } -- 常用服务器列表
	local aCommend     = { nRegionIndex = 0 , szRegion = g_tStrings.STR_SERVER_STATUS_COMMEND, szDisplayRegion = g_tStrings.STR_SERVER_STATUS_COMMEND, szSimpleRegion = g_tStrings.STR_SERVER_STATUS_COMMEND, bCommend = true } -- 推荐服务器列表
	local tSerial      = {}

    for nIndex, v in ipairs(aServerList) do
		local szSimpleRegion  = v[1]
		local szRegion        = self._dealWithOr(v[12], v[1])       -- 大区名称
		local szServer        = v[2]                                -- 服务器名称
		local szRealRegion    = szRegion                            -- 数据互通主服大区
		local szRealServer    = self._dealWithOr(v[11], szServer)   -- 数据互通主服名称
		local nState          = tonumber(v[3])                      -- 服务器状态
		local szIP            = v[4]                                -- 服务器IP
		local nPort           = tonumber(v[5])                      -- 服务器端口
		local szDisplayRegion = self._dealWithOr(v[6], szRegion)    -- 大区显示名（UI分组和显示使用）
		local szDisplayServer = self._dealWithOr(v[7], szServer)    -- 服务器显示名（UI分组和显示使用）
		local nAreaID         = tonumber(v[8])
		local nGroupID        = tonumber(v[9])
		local szSerial        = v[10]
		local szStatePath     = self._dealWithOr(v[13], nil)
		local nStateFrame     = self._dealWithOr(v[14], nil)
		local bPvp            = self._dealWithOr(v[15], false)
		local nServerMark     = tonumber(v[16])
		local nCommendState   = COMMEND_STATE.UN_COMMEND
		nState, nCommendState = self._parseServerState(nState)

		if szRegion and szServer and nState and szIP and nPort then
			-- 插入服务器信息到列表
			local tbRegion = tList[szDisplayRegion]
			if not tbRegion then
				tbRegion = {
					nRegionIndex    = nRegionIndex   ,
					szRegion        = szRegion       ,
					szRealRegion    = szRealRegion   ,
					szDisplayRegion = szDisplayRegion,
					szSimpleRegion  = szSimpleRegion ,
					szStatePath     = szStatePath    ,
					nStateFrame     = nStateFrame    ,
				}
				nRegionIndex = nRegionIndex + 1
				tList[szDisplayRegion] = tbRegion
			else
				if not tbRegion.szStatePath and szStatePath then
					tbRegion.szStatePath  = szStatePath
				end
				if not tbRegion.nStateFrame and nStateFrame then
					tbRegion.nStateFrame  = nStateFrame
				end
			end
			local tbServer = {
				nId             = nIndex         ,
				szRegion        = szRegion       ,
				szServer        = szServer       ,
				szRealRegion    = szRealRegion   ,
				szRealServer    = szRealServer   ,
				szDisplayRegion = szDisplayRegion,
				szDisplayServer = szDisplayServer,
				szIP            = szIP           ,
				nPort           = nPort          ,
				nState          = nState         ,
				nAreaID         = nAreaID        ,
				nGroupID        = nGroupID       ,
				szSerial        = szSerial       ,
				nLastTime       = 0              ,
				bPvp            = bPvp           ,
				nServerMark     = nServerMark    ,
                nCommendState   = nCommendState  ,
			}
			table.insert(tbRegion, tbServer)
            aIPList[szIP]		= tbServer

			-- 插入服务器信息到推荐
			if nCommendState == COMMEND_STATE.COMMEND then -- 推荐服务器
				table.insert(aCommend, tbServer)
			end

			-- 插入服务器信息到常用
			local tbRecentLogin = Storage.RecentLogin.tbServer[szRegion .. '/' .. szServer]
			if tbRecentLogin then
				tbServer.nLastTime = tbRecentLogin.nTime
				if tbRecentLogin.szRegion == szRegion and tbRecentLogin.szServer == szServer then
					table.insert(aRecent, tbServer)
				end
			end

			-- 设置服务器分组信息
			if szSerial and szSerial ~= "" then
				tSerial[szDisplayServer] = szSerial
			end
		end
	end

    local aList = {}
	for _, tbRegion in pairs(tList) do
        self._sortServerList(tbRegion)
		table.insert(aList, tbRegion)
	end
	if #aCommend > 0 then
		table.insert(aList, aCommend)
	end
	if #aRecent > 0 then --2024.5.10 策划需求，最近登录大于0就显示该切页
		--table.sort(aRecent, function(svr1, svr2) return svr1.nId < svr2.nId end)
		table.sort(aRecent, function(svr1, svr2) return svr1.nLastTime > svr2.nLastTime end) --按时间排序
        --TODO luwenhao1 最近登录只显示五个？
		table.insert(aList, aRecent)
	end
	table.sort(aList, function(reg1, reg2) return reg1.nRegionIndex < reg2.nRegionIndex end)

    g_tbLoginData.aServerList = aList
    g_tbLoginData.tSerial = tSerial
    g_tbLoginData.aIPList = aIPList
end

function LoginServerList._dealWithOr(a, b)
	if a and a ~= "" then
		return a
	end
	if b and b ~= "" then
		return b
	end
	return nil
end

function LoginServerList._parseServerState(nState)
	local nServerState = nState
	local nCommendState = nState
	if nState >= 10 then --为了兼容新旧版本～
		nServerState =  math.floor(nState / 10)
		nCommendState = math.floor(nState % 10)
	end

	return nServerState, nCommendState
end

function LoginServerList._sortServerList(tbRegion)
	local fnSortByMark = function(tLeft, tRight)
		if tLeft.nServerMark == tRight.nServerMark then
			return tLeft.nId < tRight.nId
		end
		return tLeft.nServerMark > tRight.nServerMark
	end
	table.sort(tbRegion, fnSortByMark)
end

return LoginServerList
