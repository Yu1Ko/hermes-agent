---@class LoginAccount
local LoginAccount = {}
local self = LoginAccount

local NEXT_LOGIN_STEP = LoginModule.LOGIN_SERVERLIST

function LoginAccount.RegisterEvent()
    LoginMgr.RegisterLoginNotify(LOGIN.VERIFY_SUCCESS, self.OnVerifySuccess)
    LoginMgr.RegisterLoginNotify(LOGIN.WAIT_QUEUE_POSTION_NOTIFY, self.OnQueueNotify) -- "服务器过于火爆，排队<D0>人，请稍后..."（这个消息在登录账号 和 登录游戏时都可能会收到）

    local tbFailEventList = {
        -- LOGIN.VERIFY_SUCCESS,                       -- "验证通过,一切顺利"
        LOGIN.NEED_TOKEN_PASSWORD,                  -- "验证通过,但是令牌密保用户 需要密保密码"        --TODO: ShowLoginTokenPanel()
        LOGIN.NEED_MATRIX_PASSWORD,                 -- "验证通过,但是矩阵卡密保用户 需要密保密码"      --TODO: ShowSecurityCard()
        LOGIN.NEED_PHONE_PASSWORD,                  -- "验证通过,但是手机令牌用户 需要手机随机密码"    --TODO: ShowLoginPhoneTokenPanel()
        LOGIN.VERIFY_ACC_PSW_ERROR,                 -- "账号或者密码错误"
        LOGIN.VERIFY_NOT_ACTIVE,                    -- "账号没有激活"
        LOGIN.VERIFY_ACTIVATE_CODE_ERR,             -- "激活码错误，不存在或已经被使用过了"
        LOGIN.VERIFY_IN_OTHER_GROUP,                -- "该账号已经在其他区服登录"
        LOGIN.VERIFY_ACC_FREEZED,                   -- "账号被冻结了"
        LOGIN.VERIFY_PAYSYS_BLACK_LIST,             -- "多次密码错误,账号被Paysys锁进黑名单了"
        LOGIN.VERIFY_LIMIT_ACCOUNT,                 -- "访沉迷用户，不能登入"
        LOGIN.VERIFY_LIMIT_FACE_RECOGNITION,        -- "防沉迷，需要人脸识别验证"
        LOGIN.VERIFY_ACC_SMS_LOCK,                  -- "账号被用户短信锁定"
        LOGIN.VERIFY_IN_GAME,                       -- "账号正在游戏中，稍后重试(自动踢号)"
        LOGIN.VERIFY_ALREADY_IN_GATEWAY,            -- "该账号正在使用: 正在本组服务器的Bishop上验证呢!"
        LOGIN.ACCOUNT_FREEZE_PLAYER_TOKEN,          -- "帐号被手机令牌冻结"
        LOGIN.ACCOUNT_FREEZE_PLAYER_SMS,            -- "帐号被短信冻结"
        LOGIN.ACCOUNT_FREEZE_PLAYER_WEB,            -- "帐号从官网自助页面被冻结"
        LOGIN.ACCOUNT_FREEZE_PLAYER_FARMER,         -- "疑似工作室，帐号被冻结了"
        LOGIN.ACCOUNT_VERIFY_TOO_FREQUENTLY,        -- "验证过于频繁"    --TODO: 参数arg4倒计时
        LOGIN.VERIFY_UNKNOWN_ERROR,                 -- "未处理的错误码"

        LOGIN.UNION_ACCOUNT_VERIFY_HTTP_FAILED,     -- "联合账号验证网络错误"
        LOGIN.UNION_ACCOUNT_VERIFY_FAILED,          -- "联合账号验证不通过"
        LOGIN.UNION_ACCOUNT_VERIFY_UNKNOWN_FAILED,  -- "联合账号验证未知错误"
        LOGIN.UNION_ACCOUNT_VERIFY_XG_CUSTOM_ERROR, -- "联合账号验证西瓜自定义错误"
    }

    for i = 1, #tbFailEventList do
        local nEvent = tbFailEventList[i]
        LoginMgr.RegisterLoginNotify(nEvent, function(...)
            self.OnVerifyFail(nEvent, ...)
        end)
    end
end

function LoginAccount.OnEnter(szPrevStep)

end

function LoginAccount.OnExit(szNextStep)

end

function LoginAccount.OnClear()
    g_tbLoginData.bNotLogout = false
end

-------------------------------- Public --------------------------------

function LoginAccount.SetAccountPassword(szAccount, szPassword)
    if not g_tbLoginData.LoginView then return end

    -- SDK不用设置
    if not g_tbLoginData.bIsDevelop then return end

    UIHelper.SetString(g_tbLoginData.LoginView.EditBoxID, szAccount or "")
    UIHelper.SetString(g_tbLoginData.LoginView.EditBoxPassword, szPassword or "")
end

function LoginAccount.GetAccountPassword()
    if not g_tbLoginData.LoginView then
        return "", ""
    end

    local szAccount = UIHelper.GetString(g_tbLoginData.LoginView.EditBoxID) or ""
    local szPassword = UIHelper.GetString(g_tbLoginData.LoginView.EditBoxPassword) or "" --TODO 加密
    return szAccount, szPassword
end

function LoginAccount.ClearLogin()
    g_tbLoginData.tbLoginInfo = {}
    g_tbLoginData.bIsGetAllRoleListSuccess = false
    Login_CancelLogin()

    if not g_tbLoginData.bNotLogout and not g_tbLoginData.bReLoginToRoleListFlag then
        --PakDownloadMgr.CancelBasicPack()
    end
end

function LoginAccount.GetStorageAccountKey()
    local szAccountKey
    if g_tbLoginData.bIsDevelop then
        if g_tbLoginData.LoginView then
            szAccountKey = UIHelper.GetString(g_tbLoginData.LoginView.EditBoxID)
        else
            szAccountKey = Storage.Login.szAccount
        end
    else
        if self.szAccountKey then
            szAccountKey = self.szAccountKey
        else
            local moduleSDK = LoginMgr.GetModule(LoginModule.LOGIN_SDK)
            moduleSDK.GetUidInfo()
        end
    end
    return szAccountKey
end

function LoginAccount.SetStorageAccountKey(szAccountKey)
    self.szAccountKey = szAccountKey
end

-------------------------------- Protocol --------------------------------

function LoginAccount.AccountVerify(bReLogin)
    local fnTimeOut = function()
        --在排队
        if WaitingTipsData.GetMsgByType("LoginQueue_WQPN") then
            return
        end

        TipsHelper.ShowNormalTip("等待消息超时，请重试")
        LoginMgr.SetWaiting(false)
        self._onVerifyFail()
    end

    if not LoginMgr.SetWaiting(true, g_tStrings.tbLoginString.LOGINING, fnTimeOut) then return end

    local szAccount, szPassword
    if bReLogin then
        szAccount, szPassword = Storage.Login.szAccount, Storage.Login.szPassword
    else
        szAccount, szPassword = self.GetAccountPassword()
    end

    g_tbLoginData.bIsGetAllRoleListSuccess = false

    LoginMgr.Log(self, "AccountVerify Account = %s, Password = %s", szAccount, szPassword)
    szAccount = UIHelper.UTF8ToGBK(szAccount)
    szPassword = UIHelper.UTF8ToGBK(szPassword)
    Login_SetAccountPassword(szAccount, szPassword, true)
    Login_AccountVerify()

    -- Recv: OnVerifySuccess & LoginRoleList.OnGetRoleListSuccess & LoginRoleList.OnGetAllRoleListSuccess
end

function LoginAccount.XGSDKAccountVerify(bReLogin)
    local fnTimeOut = function()
        --在排队
        if WaitingTipsData.GetMsgByType("LoginQueue_WQPN") then
            return
        end

        TipsHelper.ShowNormalTip("等待消息超时，请重试")
        LoginMgr.SetWaiting(false)
        self._onVerifyFail()
    end

    if not LoginMgr.SetWaiting(true, g_tStrings.tbLoginString.LOGINING, fnTimeOut) then return end

    local moduleSDK = LoginMgr.GetModule(LoginModule.LOGIN_SDK)
    local szXGAuthInfo = moduleSDK.GetAuthInfo() or ""

    LoginMgr.Log(self, "XGSDKAccountVerify XGAuthInfo = %s", szXGAuthInfo)
    Login_XGSDKAccountVerify(szXGAuthInfo)

    -- Recv: OnVerifySuccess & LoginRoleList.OnGetRoleListSuccess & LoginRoleList.OnGetAllRoleListSuccess
end

function LoginAccount.OnVerifySuccess()
    --备注：AccountVerify成功后会再收到LoginRoleList.OnGetAllRoleListSuccess
    LoginMgr.Log(self, "OnVerifySuccess")

    --验证密保也会收到OnVerifySuccess
    if g_tbLoginData.bVerifyMiBao then
        local moduleRoleList = LoginMgr.GetModule(LoginModule.LOGIN_ROLELIST)
        moduleRoleList.OnRoleMiBaoVerifySuccess()
        return
    end

    WaitingTipsData.RemoveWaitingTips("LoginQueue_WQPN")

    --请求进入游戏会先收到OnVerifySuccess，再收到LoginEnterGame.OnRequestLoginGameSuccess
    local moduleEnterGame = LoginMgr.GetModule(LoginModule.LOGIN_ENTERGAME)
    if moduleEnterGame.IsRequestLogin() then
        return
    end

    LoginMgr.SetWaiting(false)
    moduleEnterGame.ClearTimer()

    --登陆到gateway并验证账号成功后，清除标记
    g_tbLoginData.bXgSdkLoginLostNetworkTryReConnect = false

    --登录成功后设置自动登录
    g_tbLoginData.bAutoLogin = true

    Event.Dispatch(EventType.OnAccountLogin)

    local moduleServerList = LoginMgr.GetModule(LoginModule.LOGIN_SERVERLIST)
    moduleServerList.SaveRecentLoginServer()
    local tbServer = moduleServerList.GetSelectServer()
    if tbServer then
        g_tbLoginData.tbLoginInfo.nLoginServerID = tbServer.nId --记录登录服务器的ID
    end

    if not g_tbLoginData.bIsGetAllRoleListSuccess then
        LoginMgr.SetWaiting(true, g_tStrings.tbLoginString.GETTING_ROLE_LIST)
    end

    --返回选角
    if g_tbLoginData.bReLoginToRoleListFlag then
        g_tbLoginData.tbLoginInfo.szLoginAccount = Storage.Login.szAccount
    else
        g_tbLoginData.tbLoginInfo.szLoginAccount = self.GetAccountPassword()

        --进入选服模块
        LoginMgr.SwitchStep(NEXT_LOGIN_STEP)
    end
end

function LoginAccount.OnVerifyFail(nEvent, ...)
    --请求进入游戏会先收到OnVerifySuccess，再收到LoginEnterGame.OnRequestLoginGameSuccess
    local moduleEnterGame = LoginMgr.GetModule(LoginModule.LOGIN_ENTERGAME)
    if moduleEnterGame.IsRequestLogin() then
        moduleEnterGame.OnRequestLoginFail(nEvent)
        return
    end

    LoginMgr.Log(self, "OnVerifyFail %d", nEvent)
    LoginMgr.SetWaiting(false)
    WaitingTipsData.RemoveWaitingTips("LoginQueue_WQPN")

    --错误提示
    local szMsg = LoginEventName[nEvent]
    if nEvent == LOGIN.ACCOUNT_VERIFY_TOO_FREQUENTLY then
        szMsg = FormatString(LoginEventName[LOGIN.ACCOUNT_VERIFY_TOO_FREQUENTLY], arg4)
    end

    if nEvent == LOGIN.VERIFY_IN_GAME then
        local dialog = UIHelper.ShowSystemConfirm(szMsg)
        dialog:HideCancelButton()
    elseif nEvent == LOGIN.UNION_ACCOUNT_VERIFY_XG_CUSTOM_ERROR then
        self.OnXGCustomError(nEvent, ...)
    elseif nEvent == LOGIN.VERIFY_LIMIT_ACCOUNT then
        if arg2 == 1413 then
            szMsg = g_tStrings.ACCOUNT_REGISITER_INVALID
            LoginMgr.ErrorMsg(self, szMsg)
        elseif arg2 == 1414 then
            szMsg = LoginEventName[LOGIN.REQUEST_LOGIN_GAME_NEED_BIND_PHONE]
            UIHelper.ShowSystemConfirm(szMsg, function()
                Event.Reg(self, "WEB_SIGN_NOTIFY", function()
                    self._onVerifyFail()
                end, true)
                APIHelper.OpenURL_VerifyPhone()
            end)
            return
        else
            LoginMgr.ErrorMsg(self, szMsg)
        end
    elseif nEvent == LOGIN.ACCOUNT_FREEZE_PLAYER_FARMER then
        -- local szMsg = LoginEventName[LOGIN.ACCOUNT_FREEZE_PLAYER_FARMER]
        local dialog = UIHelper.ShowSystemConfirm(szMsg, function()
            UIHelper.OpenWebWithDefaultBrowser(tUrl.szUrlShenSu)
        end)
        dialog:SetButtonContent("Confirm", "前往申诉")
    else
        LoginMgr.ErrorMsg(self, szMsg)
    end

    self._onVerifyFail()
end

function LoginAccount.OnQueueNotify()
    local bLoginView = UIMgr.IsViewOpened(VIEW_ID.PanelLogin) or g_tbLoginData.bReLoginToRoleListFlag

    local fnCancelCallback = function ()
        local szMsg = g_tStrings.STR_GIVEUP_QUEUE_SURE
        local fnConfirm = function ()
            LoginMgr.SetWaiting(false)
            WaitingTipsData.RemoveWaitingTips("LoginQueue_WQPN")
            -- Logout

            if bLoginView then
                self._onVerifyFail()
            else
                g_tbLoginData.bNotLogout = false
                g_tbLoginData.bReLoginToRoleListFlag = true
                local moduleGateway = LoginMgr.GetModule(LoginModule.LOGIN_GATEWAY)
                local moduleEnterGame = LoginMgr.GetModule(LoginModule.LOGIN_ENTERGAME)
                moduleEnterGame.ClearRequestLogin()
                self.ClearLogin()
                moduleGateway.ConnectGateway()
            end
        end
        UIHelper.ShowSystemConfirm(szMsg, fnConfirm)
    end

    local szWaitingMsg = ""
    if bLoginView then
        szWaitingMsg = FormatString(g_tStrings.tbLoginString.WAIT_QUEUE_POSTION_NOTIFY, arg5)
    else
        szWaitingMsg = FormatString(g_tStrings.tbLoginString.WAIT_QUEUE_POSTION_NOTIFY_LOGININ, arg5)
    end

    local tMsg = {
        szType = "LoginQueue_WQPN",
        szWaitingMsg = szWaitingMsg,
        fnCancelCallback = fnCancelCallback,
        nPriority = 2,
        bHidePage = true,
        bSwallow = true,
    }
    WaitingTipsData.PushWaitingTips(tMsg)
end

function LoginAccount.OnXGCustomError(nEvent, szMatrixPosition, dwLimitPlayTimeFlag, szRoleName, nVerifyInterval, dwPostion, nChannel, szIP, szXGMessage)
    LoginMgr.ErrorMsg(self, szXGMessage)
end

function LoginAccount._onVerifyFail()
    if g_tbLoginData.LoginView and g_tbLoginData.bIsDevelop then
        --清除已经输入的密码
        UIHelper.SetString(g_tbLoginData.LoginView.EditBoxPassword, "")

        g_tbLoginData.LoginView:Logout()
    end

    self.ClearLogin() --被顶号时会先收到OnVerifySuccess再收到OnVerifyFail，要清理一下OnVerifySuccess时设的状态

    --返回选角
    if g_tbLoginData.bReLoginToRoleListFlag then
        LoginMgr.BackToLogin()
        return
    end
end

return LoginAccount