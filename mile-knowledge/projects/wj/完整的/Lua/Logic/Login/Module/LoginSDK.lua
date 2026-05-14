---@class LoginSDK
local LoginSDK = { className = "LoginSDK" }
local self = LoginSDK

local m_szAuthInfo
local m_bNotOpenSDKWindow

local m_bSDKWindowOpened = false

function LoginSDK.RegisterEvent()
    Event.Reg(self, EventType.XGSDK_OnLoginSuccess, self.OnXGSDKLoginSuccess)
    Event.Reg(self, EventType.XGSDK_OnLoginFail, self.OnXGSDKLoginFail)
    Event.Reg(self, EventType.XGSDK_OnLoginCancel, self.OnXGSDKLoginCancel)
    Event.Reg(self, EventType.XGSDK_OnLogoutSuccess, self.OnXGSDKLogoutSuccess)
    --Event.Reg(self, EventType.XGSDK_OnGetAccountInfoSuccess, self.OnXGSDKGetAccountInfoSuccess)
    --Event.Reg(self, EventType.XGSDK_OnGetAccountInfoFail, self.OnXGSDKGetAccountInfoFail)
    Event.Reg(self, EventType.XGSDK_OnGetUidInfoSuccess, self.OnXGSDKGetUidInfoSuccess)
    Event.Reg(self, EventType.XGSDK_OnGetUidInfoFail, self.OnXGSDKGetUidInfoFail)
    Event.Reg(self, EventType.XGSDK_OnExit, self.XGSDK_OnExit)
    Event.Reg(self, EventType.XGSDK_OnNoChannelExit, self.XGSDK_OnNoChannelExit)

    if Platform.IsWindows() or Platform.IsMac() then
        Event.Reg(self, "KICK_ACCOUNT", function()
            self.SDKLogout(true, true)
        end)
    end
end

function LoginSDK.OnEnter(szPrevStep)

end

function LoginSDK.OnExit(szNextStep)

end

-------------------------------- Public --------------------------------

function LoginSDK.OpenSDKWindow()
    if m_bSDKWindowOpened then
        TipsHelper.ShowNormalTip("账号数据加载中...") --等待上一次登录完成后才可以开始下一次登录，避免重复调用
        return
    end

    LoginMgr.Log(self, "OpenSDKWindow")
    m_bSDKWindowOpened = true
    XGSDK_Login()
end

function LoginSDK.OpenUserCenter()
    LoginMgr.Log(self, "OpenUserCenter")
    XGSDK_OpenUserCenter()
end

function LoginSDK.GetAccountInfo()
    LoginMgr.Log(self, "GetAccountInfo")
    XGSDK_GetAccountInfo()
end

function LoginSDK.SDKLogout(bNeedReLogin, bNotOpenSDKWindow)
    if not self._isSDKValid() then
        return
    end

    local moduleEnterGame = LoginMgr.GetModule(LoginModule.LOGIN_ENTERGAME)
    moduleEnterGame.ClearTimer()
    moduleEnterGame.ClearRequestLogin()
    moduleEnterGame.ClearRoleLoginRealMap()

    bNeedReLogin = bNeedReLogin or false
    m_bNotOpenSDKWindow = bNotOpenSDKWindow or false
    LoginMgr.Log(self, "SDKLogout, bNeedReLogin: %s", tostring(bNeedReLogin))
    XGSDK_Logout(bNeedReLogin)
end

function LoginSDK.GetAuthInfo()
    return m_szAuthInfo
end

function LoginSDK.ClearAuthInfo(szCtx)
    local moduleAccount = LoginMgr.GetModule(LoginModule.LOGIN_ACCOUNT)
    moduleAccount.SetStorageAccountKey(nil)
    self.bWaitGetUidInfo = false

    local moduleEnterGame = LoginMgr.GetModule(LoginModule.LOGIN_ENTERGAME)
    moduleEnterGame.ClearTimer()
    moduleEnterGame.ClearRequestLogin()
    moduleEnterGame.ClearRoleLoginRealMap()

    self._setAuthInfo(string.format("ClearAuthInfo %s", szCtx or ""))
end

function LoginSDK.IsSDKWindowOpened()
    return m_bSDKWindowOpened
end

function LoginSDK.GetUidInfo()
    if not self._isSDKValid() then return end
    if self.bWaitGetUidInfo then return end

    self.bWaitGetUidInfo = true
    LoginMgr.Log(self, "XGSDK_GetUidInfo")
    XGSDK_GetUidInfo() -- Recv: XGSDK_OnGetUidInfoSuccess/XGSDK_OnGetUidInfoFail
end

-------------------------------- Protocol --------------------------------

function LoginSDK.OnXGSDKLoginSuccess(szXGAuthInfo)
    m_bSDKWindowOpened = false
    LoginMgr.Log(self, "OnXGSDKLoginSuccess: %s", szXGAuthInfo)

    if not self._isSDKValid() then
        return
    end

    local moduleAccount = LoginMgr.GetModule(LoginModule.LOGIN_ACCOUNT)
    moduleAccount.ClearLogin()
    moduleAccount.SetStorageAccountKey(nil)

    local moduleEnterGame = LoginMgr.GetModule(LoginModule.LOGIN_ENTERGAME)
    moduleEnterGame.ClearTimer()
    moduleEnterGame.ClearRequestLogin()
    moduleEnterGame.ClearRoleLoginRealMap()

    self.bWaitGetUidInfo = false
    self.GetUidInfo()

    -- 保存登录信息，供后面验证时使用
    self._setAuthInfo("OnXGSDKLoginSuccess", szXGAuthInfo)
    self._clearDownload()
    Event.Dispatch(EventType.Login_UpdateState)

    if not Channel.Is_WLColud() then
        Timer.Add(self, 0.1, function()
            BulletinData.CheckOpenBulletinPanel()
        end)
    end
end

function LoginSDK.OnXGSDKLoginFail(nCode, szMsg, nChannelCode)
    m_bSDKWindowOpened = false
    LoginMgr.Log(self, "OnXGSDKLoginFail, Code: %d", nCode)

    if not self._isSDKValid() then
        return
    end

    self.ClearAuthInfo("OnXGSDKLoginFail")
    self._clearDownload()
end

function LoginSDK.OnXGSDKLoginCancel()
    m_bSDKWindowOpened = false
    LoginMgr.Log(self, "OnXGSDKLoginCancel")

    if not self._isSDKValid() then
        return
    end

    self._clearDownload()

    -- --强制重新打开登录窗口
    -- self.OpenSDKWindow()
end

function LoginSDK.OnXGSDKLogoutSuccess()
    m_bSDKWindowOpened = false
    LoginMgr.Log(self, "OnXGSDKLogoutSuccess")

    if not self._isSDKValid() then
        return
    end

    self._clearDownload()
    self.ClearAuthInfo("OnXGSDKLogoutSuccess")
    Event.Dispatch(EventType.Login_UpdateState)

    if not m_bNotOpenSDKWindow then
        self.OpenSDKWindow()
    end
end

function LoginSDK.XGSDK_OnExit()
    LoginMgr.Log(self, "XGSDK_OnExit")

    self.ClearAuthInfo("XGSDK_OnExit")
    Game.Exit()
end

function LoginSDK.XGSDK_OnNoChannelExit()
    LoginMgr.Log(self, "XGSDK_OnNoChannelExit")

    if Platform.IsAndroid() then
        if SceneMgr.IsLoading() then
            return
        end

        if not Global.bIsEnterGame then
            if UIMgr.IsViewOpened(VIEW_ID.PanelLogin) and not UIMgr.IsViewOpened(VIEW_ID.PanelSystemConfirm) then
                UIHelper.ShowSystemConfirm(g_tStrings.EXIT_QUIT, function()
                    self.ClearAuthInfo("XGSDK_OnNoChannelExit")
                    Game.Exit()
                end)
                return
            end
            return
        end

        ShortcutInteractionData._bindMenuAction("PanelSystemMenu","Esc")
        return
    end

    self.ClearAuthInfo("XGSDK_OnNoChannelExit")
    Game.Exit()
end

-- function LoginSDK.OnXGSDKGetAccountInfoSuccess(szJsonStr)
--     if not self._isSDKValid() then return end

--     LoginMgr.Log(self, "OnXGSDKGetAccountInfoSuccess, %s", szJsonStr or "")

--     if g_tbLoginData.LoginView then
--         local tJson = JsonDecode(szJsonStr)
--         local szSDKAccount = tJson and tJson["passport_id"]
--         g_tbLoginData.tbLoginInfo.szSDKLoginAccount = szSDKAccount
--         UIHelper.SetString(g_tbLoginData.LoginView.LabelAccount, szSDKAccount)
--     end
-- end

-- function LoginSDK.OnXGSDKGetAccountInfoFail(nCode, szMsg)
--     if not self._isSDKValid() then return end

--     LoginMgr.Log(self, "OnXGSDKGetAccountInfoFail, Code: %d", nCode)
-- end

function LoginSDK.OnXGSDKGetUidInfoSuccess(szResult)
    LoginMgr.Log(self, "OnXGSDKGetAccountInfoSuccess, %s", tostring(szResult))

    if not self._isSDKValid() then return end
    if not self.bWaitGetUidInfo then return end

    self.bWaitGetUidInfo = false

    local tJson = JsonDecode(szResult)
    local szUidInfo = tJson and tJson["uid"]

    local moduleAccount = LoginMgr.GetModule(LoginModule.LOGIN_ACCOUNT)
    moduleAccount.SetStorageAccountKey(szUidInfo)
end

function LoginSDK.OnXGSDKGetUidInfoFail(nCode, szMsg)
    LoginMgr.Log(self, "OnXGSDKGetUidInfoFail, Code: %d", nCode)

    if not self._isSDKValid() then return end
    if not self.bWaitGetUidInfo then return end

    self.bWaitGetUidInfo = false

    local moduleAccount = LoginMgr.GetModule(LoginModule.LOGIN_ACCOUNT)
    moduleAccount.SetStorageAccountKey(nil)
end

-------------------------------- Private --------------------------------

function LoginSDK._setAuthInfo(szCtx, szAuthInfo)
    LOG.DEBUG("_setAuthInfo: %s %s", szCtx, szAuthInfo or "")
    m_szAuthInfo = szAuthInfo
end

function LoginSDK._isSDKValid()
    return not g_tbLoginData.bIsDevelop and XGSDK_IsEnable()
end

function LoginSDK._clearDownload()
    g_tbLoginData.bNotLogout = false
    --PakDownloadMgr.CancelBasicPack()
end

return LoginSDK