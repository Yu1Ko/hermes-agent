---@class LoginGateway
local LoginGateway = {}
local self = LoginGateway

local m_szIP = "127.0.0.1"
local m_nPort = 3724

local m_nHomeplace = 1  -- 当前的nHomeplace
local m_tHomeList = nil -- 当前的HomeList

function LoginGateway.RegisterEvent()
    LoginMgr.RegisterLoginNotify(LOGIN.HANDSHAKE_SUCCESS, self.OnHandShakeSuccess)
    LoginMgr.RegisterLoginNotify(LOGIN.UPDATE_HOMETOWN_LIST, self.OnQueryHometownList)

    local tbFailEventList = {
        LOGIN.UNABLE_TO_CONNECT_SERVER,         -- "无法连接服务器"
        LOGIN.MISS_CONNECTION,                  -- "服务器连接丢失"
        LOGIN.SYSTEM_MAINTENANCE,               -- "系统维护"
        LOGIN.UNMATCHED_LOGIN_PROTOCOL_VERSION, -- "登录协议版本不匹配，请更新"
		LOGIN.UNMATCHED_GAME_PROTOCOL_VERSION,  -- "游戏协议版本不匹配，请更新"
		LOGIN.UNMATCHED_GAME_RESOURCE_VERSION,  -- "游戏资源版本不匹配，请更新"
        LOGIN.ACCOUNT_VERIFY_TOO_FREQUENTLY,    -- 验证太频繁了，你是脱机外挂吧
        LOGIN.BAD_GUY,                          -- 系统错误，修改了客户端或者协议

        --LOGIN.HANDSHAKE_SUCCESS,                -- "握手成功"
        LOGIN.HANDSHAKE_ACCOUNT_SYSTEM_LOST,    -- "账号系统在维护，请稍后重试"
        LOGIN.VERIFY_KICK_BY_GM,              -- "你被GM踢下线了"
    }

    for i = 1, #tbFailEventList do
        local nEvent = tbFailEventList[i]
        LoginMgr.RegisterLoginNotify(nEvent, function()
            self.OnHandShakeFail(nEvent)
        end)
    end
end

function LoginGateway.OnEnter(szPrevStep)
    self._clearTempLoginData()

    if not g_tbLoginData.bIsDevelop then
        --2024.3.12 SDK登录时，返回登录界面断开Gateway连接
        local moduleAccount = LoginMgr.GetModule(LoginModule.LOGIN_ACCOUNT)
        moduleAccount.ClearLogin()
    end

    if not UIMgr.IsViewOpened(VIEW_ID.PanelLogin) then
        ---@see UILoginView#OnEnter
        UIMgr.Open(VIEW_ID.PanelLogin)
    else
        Event.Dispatch(EventType.Login_UpdateState)
    end

    local moduleCamera = LoginMgr.GetModule(LoginModule.LOGIN_CAMERA)
    moduleCamera.SetCameraStatus(LoginCameraStatus.LOGIN)
end

function LoginGateway.OnExit(szNextStep)

end

function LoginGateway.OnClear()
    Timer.DelAllTimer(self)
end

-------------------------------- Public --------------------------------



-------------------------------- Protocol --------------------------------

function LoginGateway.ConnectGateway()
    if not LoginMgr.SetWaiting(true, g_tStrings.tbLoginString.CONNECTING) then return end

    local moduleServerList = LoginMgr.GetModule(LoginModule.LOGIN_SERVERLIST)
    local tbServer = moduleServerList.GetSelectServer()
    if tbServer then
        m_szIP = tbServer.szIP or m_szIP
        m_nPort = tbServer.nPort or m_nPort
    end

    --保存到最近登录服务器 （BVT为了方便 还是在这个时候存最近登录的服务器）
    if Version.IsBVT() then
        moduleServerList.SaveRecentLoginServer()
    end

    self.bIsConnectingGateway = true

    -- Recv: OnHandShakeSuccess/OnVerifyFail
    LoginMgr.Log(self, "ConnectGateway, IP = %s, Port = %s", m_szIP, m_nPort)
    Login_SetGatewayAddress(m_szIP, m_nPort)
    Login_ConnectGateway()
end

function LoginGateway.OnHandShakeSuccess()
    LoginMgr.Log(self, "OnHandShakeSuccess")
    LoginMgr.SetWaiting(false)

    self.bIsConnectingGateway = false

    ---@type LoginAccount
    local moduleAccount = LoginMgr.GetModule(LoginModule.LOGIN_ACCOUNT)
    if g_tbLoginData.bIsDevelop or not XGSDK_IsEnable() then
        moduleAccount.AccountVerify(g_tbLoginData.bReLoginToRoleListFlag)
    else
        moduleAccount.XGSDKAccountVerify(g_tbLoginData.bReLoginToRoleListFlag)
    end
end

function LoginGateway.OnHandShakeFail(nEvent)
    LoginMgr.Log(self, "OnHandShakeFail %d", nEvent)
    LoginMgr.SetWaiting(false)

    self.bIsConnectingGateway = false

    local moduleAccount = LoginMgr.GetModule(LoginModule.LOGIN_ACCOUNT)
    moduleAccount.ClearLogin()

    -- local moduleSDK = LoginMgr.GetModule(LoginModule.LOGIN_SDK)
    -- moduleSDK.ClearAuthInfo()

    Event.Dispatch(EventType.Login_UpdateState)

    --错误提示
    local szMsg = LoginEventName[nEvent]
    if nEvent == LOGIN.ACCOUNT_VERIFY_TOO_FREQUENTLY then
        szMsg = FormatString(LoginEventName[LOGIN.ACCOUNT_VERIFY_TOO_FREQUENTLY], arg4)
    end

    if nEvent ~= LOGIN.MISS_CONNECTION then
        LoginMgr.ErrorMsg(self, szMsg)
    else
        -- 断网时不弹提示，仅打印个日志
        LoginMgr.Log(self, szMsg)
    end
    -- if nEvent == LOGIN.UNMATCHED_LOGIN_PROTOCOL_VERSION or nEvent == LOGIN.UNMATCHED_GAME_PROTOCOL_VERSION or
    --     nEvent == LOGIN.UNMATCHED_GAME_RESOURCE_VERSION then
    --     --版本不匹配，出错误弹窗并重启游戏
    --     local dialog = UIHelper.ShowConfirm(szMsg, function()
    --         --TODO 重启游戏
    --     end)
    --     dialog:HideCancelButton()
    -- else
    --     --错误提示
    --     LoginMgr.ErrorMsg(self, szMsg)
    -- end


    if nEvent == LOGIN.VERIFY_KICK_BY_GM then
        -- 你被GM踢下线了，直接返回登录界面
        FireUIEvent("KICK_ACCOUNT_NOTIFY", KICK_ACCOUNT_REASON_CODE.GM_KICK_ACCOUNT)
        return
    end

    local fnLostNetworkBackToLogin = function()
        local confirm = UIHelper.ShowSystemConfirm(LoginEventName[LOGIN.MISS_CONNECTION], function()
            UIMgr.Close(VIEW_ID.PanelResourcesDownload)
            LoginMgr.BackToLogin()
        end)

        confirm:HideButton("Cancel")
    end

    if nEvent == LOGIN.MISS_CONNECTION then
        if g_tbLoginData.bIsDevelop then
            -- 开发者登录提示返回登录界面
            fnLostNetworkBackToLogin()
        else
            -- 避免断线重现时序问题加个延迟
            Timer.DelAllTimer(self)
            Timer.AddFrame(self, 5, function()
                -- 西瓜sdk登录的情况下，标记一下，然后，立即尝试重连一次
                g_tbLoginData.bXgSdkLoginLostNetworkTryReConnect = true
                -- 标记下，确保重连成功时，不会尝试跳转到服务器列表界面
                g_tbLoginData.bReLoginToRoleListFlag = true

                self.ConnectGateway()
            end)
        end
    else
        LoginMgr.BackToLogin()
    end

    if g_tbLoginData.bXgSdkLoginLostNetworkTryReConnect and nEvent == LOGIN.UNABLE_TO_CONNECT_SERVER then
        -- 断网重连失败的情况下，弹出二次确认框，回到登录界面
        g_tbLoginData.bXgSdkLoginLostNetworkTryReConnect = false
        fnLostNetworkBackToLogin()
    end
end

function LoginGateway.QueryHometownList()
    local script = UIMgr.GetViewScript(VIEW_ID.PanelSchoolSelect)
    if not script then
        return
    end

    local nKungfuID = script:GetKungfuID()
    -- local aHomeplaceList = Login_GetHometownList(nKungfuID)
    -- if not table.is_empty(aHomeplaceList) then
    --     self.OnQueryHometownList()
    --     return
    -- end

	Login_QueryHometownList(nKungfuID)
end

function LoginGateway.OnQueryHometownList()
    local script = UIMgr.GetViewScript(VIEW_ID.PanelSchoolSelect)
    if not script then
        return
    end

    local nKungfuID = script:GetKungfuID()
	local aHomeplaceList = Login_GetHometownList(nKungfuID)
    self._parseHometownList(aHomeplaceList)
end

function LoginGateway.GetSelectedHomeplaceInfo()
    if m_tHomeList then
        local tInfo = m_tHomeList[m_nHomeplace]
        if tInfo then
            return tInfo.dwMapID, tInfo.nCopyIndex
        end
    end

    return 653, 0
end

function LoginGateway.IsConnectingGateway()
    return self.bIsConnectingGateway
end

-------------------------------- Private --------------------------------

function LoginGateway._clearTempLoginData()
    -- local moduleSDK = LoginMgr.GetModule(LoginModule.LOGIN_SDK)
    -- moduleSDK.ClearAuthInfo()

    g_tbLoginData.bReLoginToRoleListFlag =  false
end

function LoginGateway._parseHometownList(aHomeplaceList)
	local nIndex = 1
	local tHomeList = {}
	for k, v in pairs(aHomeplaceList or {}) do
		local dwMapID = v["MapID"]
		local szMapName = Table_GetMapName(dwMapID)
		local tInfo = self._getHomeInfo(nIndex, szMapName, dwMapID, 0, 0)
		table.insert(tHomeList, tInfo)
		nIndex = nIndex + 1

		local tRandomIndex = {}
		local i = 1

		for nIndex, _ in pairs(v["Copy"]) do
			tRandomIndex[i] = {}
			tRandomIndex[i]["ID"] = nIndex
			tRandomIndex[i]["RandomNum"] = math.random(1, #v["Copy"])
			i = i + 1
		end

		table.sort(tRandomIndex,
			function(a, b)
				return a["RandomNum"] < b["RandomNum"]
			end
		)

		for _, tIndex in pairs(tRandomIndex) do
			local tCopy = v["Copy"][tIndex["ID"]]
			local nCopyIndex = tCopy["CopyIndex"]
			local nLoadFactor = tCopy["LoadFactor"]

			local tInfo = self._getHomeInfo(nIndex, szMapName, dwMapID, nCopyIndex, nLoadFactor)

			nIndex = nIndex + 1
			table.insert(tHomeList, tInfo)
		end
	end

	m_nHomeplace = 1
	m_tHomeList = tHomeList
end

function LoginGateway._getHomeInfo(nIndex, szMapName, dwMapID, nCopyIndex, nLoadFactor)
    local szStatus = g_tStrings.STR_SERVER_STATUS_GOOD
    local nStatusFontScheme = 80
    if nLoadFactor < 64 then
        szStatus = g_tStrings.STR_SERVER_STATUS_GOOD
        nStatusFontScheme = 80
    elseif nLoadFactor < 128 then
        szStatus = g_tStrings.STR_SERVER_STATUS_NORMAL
        nStatusFontScheme = 65
    elseif nLoadFactor < 192 then
        szStatus = g_tStrings.STR_SERVER_STATUS_CROWD
        nStatusFontScheme = 68
    else
        szStatus = g_tStrings.STR_SERVER_STATUS_BUSY
        nStatusFontScheme = 71
    end

    szMapName = GBKToUTF8(szMapName)

    local szText = ""
    local szName = ""
    if nCopyIndex == 0 then
        szText = GetFormatText(g_tStrings.tbLoginString.AUTO_SELECT, 0)
        szName = g_tStrings.tbLoginString.AUTO_SELECT
    else
        szText = GetFormatText(szMapName.."["..UIHelper.NumberToChinese(nCopyIndex).."]", 0)
        szText = szText .. GetFormatText("(" .. szStatus .. ")", nStatusFontScheme)
        szName = szMapName.."["..UIHelper.NumberToChinese(nCopyIndex).."]" .. "(" .. szStatus .. ")"
    end
    local tInfo = {}
    tInfo.dwMapID = dwMapID
    tInfo.nCopyIndex = nCopyIndex
    tInfo.nLoadFactor = nLoadFactor
    tInfo.nIndex = nIndex
    tInfo.szText = szText
    tInfo.szName = szName

    return tInfo
end

return LoginGateway
