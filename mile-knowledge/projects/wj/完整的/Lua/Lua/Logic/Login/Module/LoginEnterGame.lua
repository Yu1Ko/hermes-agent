local LoginEnterGame = {className = "LoginEnterGame"}
local self = LoginEnterGame

local NEXT_LOGIN_STEP = LoginModule.LOGIN_ENTERGAME

function LoginEnterGame.RegisterEvent()
    LoginMgr.RegisterLoginNotify(LOGIN.REQUEST_LOGIN_GAME_SUCCESS, self.OnRequestLoginGameSuccess)
    LoginMgr.RegisterLoginNotify(LOGIN.GIVEUP_QUEUE_SUCCESS, self.OnGiveUpQueueSuccess)

    local tbFailEventList = {
        --LOGIN.REQUEST_LOGIN_GAME_SUCCESS,           -- "已经取得游戏世界登陆信息，正在连接服务器"
        LOGIN.REQUEST_LOGIN_GAME_MAINTENANCE,       -- "服务器正在维护"
        LOGIN.REQUEST_LOGIN_GAME_OVERLOAD,          -- "游戏世界人数已满,稍后再来"
        LOGIN.REQUEST_LOGIN_GAME_ROLE_LIMIT,        -- "限制角色登录"
        LOGIN.REQUEST_LOGIN_GAME_ROLEFREEZE,        -- "该角色已冻结"
        LOGIN.REQUEST_LOGIN_GAME_SWITCH_CENTER,     -- "该角色正在转服"
        LOGIN.REQUEST_LOGIN_GAME_CHANGE_ACCOUNT,    -- "帐号分离中"
        LOGIN.REQUEST_LOGIN_GAME_NEED_BIND_PHONE,   -- "帐号需要绑定手机"
        LOGIN.REQUEST_LOGIN_GAME_UNKNOWN_ERROR,     -- "未处理的其他错误"
        LOGIN.VERIFY_ROLE_LOGIN_TIME_LIMIT,         -- "角色当天允许在线时间已用完了"
        LOGIN.VERIFY_ROLE_INVALID_ROLE_NAME,        -- "角色名非法"
        LOGIN.VERIFY_ROLE_NOT_EXISTS,               -- "角色不存在"
        LOGIN.VERIFY_NO_MONEY,                      -- "没钱了"
        LOGIN.VERIFY_REJECT_CLIENT_BY_VERSION,      -- "很抱歉，该类型客户端暂时无法登录"
    }

    for i = 1, #tbFailEventList do
        local nEvent = tbFailEventList[i]
        LoginMgr.RegisterLoginNotify(
            nEvent,
            function()
                self.OnRequestLoginFail(nEvent)
            end
        )
    end

    Event.Reg(self, "SCENE_BEGIN_LOAD", function()
        if self.bRequestLogin then
            LoginMgr.Log(self, "SCENE_BEGIN_LOAD, time: %d", GetTickCount())
            LoginMgr.SetWaiting(false)

            self.bRequestLogin = false
            UIMgr.Close(VIEW_ID.PanelLogin)
            UIMgr.Close(VIEW_ID.PanelNormalConfirmation)
        end

        WaitingTipsData.RemoveAllWaitingTips()
        LoginMgr.UpdateAutoKick()
    end)

    Event.Reg(self, "LOGIN_QUEUE_STATE", function()
        local fnCancelCallback = function ()
            local szMsg = g_tStrings.STR_GIVEUP_QUEUE_SURE
            local fnConfirm = function ()
                WaitingTipsData.RemoveWaitingTips("LoginQueue")
                Login_GiveupQueue()
                LoginMgr.SetWaiting(false)
                self.bRequestLogin = false
            end
            UIHelper.ShowSystemConfirm(szMsg, fnConfirm)
        end

        local tMsg = {
            szType = "LoginQueue",
            szWaitingMsg = string.format("排队中（%d），请等待...", arg0),
            fnCancelCallback = fnCancelCallback,
            nPriority = 2,
            bHidePage = true,
            bSwallow = true,
        }
        WaitingTipsData.PushWaitingTips(tMsg)
    end)

    Event.Reg(self, "LOADING_END", function()
        self.tEnterGameRoleInfo = nil
    end)
end

function LoginEnterGame.OnEnter(szPrevStep, szRoleName, bLackMapPakDispatch)
    self.bRequestLogin = false
    self.RequestLoginGame(szRoleName, bLackMapPakDispatch)
end

function LoginEnterGame.OnExit(szNextStep)
    self.bRequestLogin = false
    self.szRoleName = nil
    self.ClearTimer()
end

-------------------------------- Public --------------------------------

function LoginEnterGame.GetRoleName()
    return self.szRoleName
end

function LoginEnterGame.ClearRequestLogin()
    self.bRequestLogin = false
end

function LoginEnterGame.IsRequestLogin()
    return self.bRequestLogin
end

function LoginEnterGame.ClearTimer()
    Timer.DelTimer(self, self.nLoginTimerID)
    self.nLoginTimerID = nil
end

-------------------------------- Protocol --------------------------------

function LoginEnterGame.RequestLoginGame(szRoleName, bLackMapPakDispatch)
    bLackMapPakDispatch = bLackMapPakDispatch or false --缺少地图资源，进入默认地图
    local function fnTimeOut()
        -- Just Wait
    end

    if not szRoleName then
        return
    end

    if not LoginMgr.SetWaiting(true, g_tStrings.tbLoginString.ENTERING_GAME, fnTimeOut) then return end

    self.szRoleName = szRoleName
    LoginMgr.Log(self, "RequestLoginGame, RoleName: %s", GBKToUTF8(szRoleName))

    self.bRequestLogin = true

    -- local szCallStack = tostring(debug.traceback())
    -- local nLoginTimerID = self.nLoginTimerID
    -- --等一段时间再进入，避免界面卡在奇怪的地方
    -- self.ClearTimer()
    -- self.nLoginTimerID = Timer.Add(self, 0.5, function()
    --     self.nLoginTimerID = nil
    --     local moduleGateway = LoginMgr.GetModule(LoginModule.LOGIN_GATEWAY)
    --     local bIsConnectingGatewayBefore = moduleGateway.IsConnectingGateway()
    --     if moduleGateway.IsConnectingGateway() then
    --         LoginMgr.ErrorMsg(self, "操作频繁，账号数据加载中...")
    --         self.szRoleName = nil
    --         self.bRequestLogin = false
    --         LoginMgr.SetWaiting(false)
    --         return
    --     end

    --     self._setEnterGameRoleInfo(szRoleName)
    --     Login_RoleLogin(szRoleName, 0, bLackMapPakDispatch, PakDownloadMgr.GetLackMapPakMapIDList())

    --     local bIsConnectingGatewayAfter = moduleGateway.IsConnectingGateway()
    --     local nCurtime = GetTickCount()
    --     XGSDK_TrackEvent("game.lua.rolelogin", "rolelogin", {
    --         {"bIsConnectingGateway", string.format("%s/%s", tostring(bIsConnectingGatewayBefore), tostring(bIsConnectingGatewayAfter))},
    --         {"nCurtime", tostring(nCurtime)},
    --         {"nLoginTimerID", tostring(nLoginTimerID)},
    --         {"szCallStack", szCallStack}
    --     })
    -- end)

    --2024.11.26 临时去除Timer尝试定位埋点问题，by luwenhao1
    self._setEnterGameRoleInfo(szRoleName)
    Login_RoleLogin(szRoleName, 0, bLackMapPakDispatch, PakDownloadMgr.GetLackMapPakMapIDList())
    XGSDK_TrackEvent("game.lua.rolelogin", "rolelogin", {
        {"szCallStack", tostring(debug.traceback())}
    })
end

function LoginEnterGame.OnRequestLoginGameSuccess()
    LoginMgr.Log(self, "OnRequestLoginGameSuccess, time: %d", GetTickCount())

    --改为收到切场景的消息才关闭转圈的UI
    --LoginMgr.SetWaiting(false)
    Event.Dispatch(EventType.OnRoleLogin, self.szRoleName)

    -- UIMgr.Close(VIEW_ID.PanelLogin)
    LoginMgr.Clear()
end

function LoginEnterGame.OnRequestLoginFail(nEvent)
    LoginMgr.Log(self, "OnRequestLoginFail %d", nEvent)

    self.szRoleName = nil
    self.bRequestLogin = false
    LoginMgr.SetWaiting(false)
    WaitingTipsData.RemoveWaitingTips("LoginQueue_WQPN")

    UIMgr.Close(VIEW_ID.PanelLoading)

    if nEvent == LOGIN.REQUEST_LOGIN_GAME_MAINTENANCE then
        --返回登录界面
        LoginMgr.BackToLogin()
    elseif nEvent == LOGIN.VERIFY_NO_MONEY then
        RemindRecharge(true)
        LoginMgr.SwitchStep(LoginModule.LOGIN_ROLELIST)
        return
    elseif nEvent == LOGIN.REQUEST_LOGIN_GAME_ROLEFREEZE then
        -- 该角色已冻结
        if self.tbCurRoleInfo and self.tbCurRoleInfo.byFreezeType then
            local nTime = GetCurrentTime()
            local nShowTime = self.tbCurRoleInfo.nFreezeTime - nTime
            local szText = TimeLib.GetTimeText(nShowTime, false, true, true, true, "show three", true)

            local szMsg = g_tGlue.tFreezeMsg[self.tbCurRoleInfo.byFreezeType]
            szMsg = UIHelper.GBKToUTF8(szMsg)

            local szMsg = FormatString(szMsg, szText)

            if self.tbCurRoleInfo.byFreezeType == FREEZE_TYPE.PLUG_IN then
                Login_WebSignRequest(1, "ROLE_FREEZE_APPEAL")
                Event.Reg(self, "WEB_SIGN_NOTIFY", function(nSign, nTime, szComment, nType)
                    if szComment == "ROLE_FREEZE_APPEAL" then
                        --Sign/账号/角色id/时间戳/区id/服id/区名称/服名称/门派ID/角色名称/冻结时间/账号类型
                        local szUserRegion, szUserSever = WebUrl.GetServerName()
                        local szUrl = string.format(
                            tUrl.FreezeAppeal, nSign, Login_GetAccount(), self.tbCurRoleInfo.nRoleID, nTime, "", "", --区id/服id 登录界面没有，传空
                            UrlEncode(szUserRegion), UrlEncode(szUserSever),
                            self.tbCurRoleInfo.nForceID, UrlEncode(self.tbCurRoleInfo.szRoleName), self.tbCurRoleInfo.nFreezeTime, GetAccountType()
                        )

                        -- 弹框
                        local dialog = UIHelper.ShowSystemConfirm(szMsg, function()
                            UIHelper.OpenWebWithDefaultBrowser(szUrl)
                            self.ReloginToRoleList()
                        end, function()
                            self.ReloginToRoleList()
                        end, true)
                        dialog:SetButtonContent("Confirm", "申诉")
                        dialog:SetButtonContent("Cancel", "取消")
                        --self.tbCurRoleInfo = nil
                    end
                end, true)
            elseif self.tbCurRoleInfo.byFreezeType == FREEZE_TYPE.CONSIGN then
                local dialog = UIHelper.ShowSystemConfirm(szMsg, function()
                    UIHelper.OpenWebWithDefaultBrowser(tUrl.FreezeConsign)
                    self.ReloginToRoleList()
                end, function()
                    self.ReloginToRoleList()
                end)

                dialog:SetButtonContent("Confirm", "前往")
                dialog:SetButtonContent("Cancel", "取消")
            else
                local dialog = UIHelper.ShowSystemConfirm(szMsg, function()
                    ServiceCenterData.OpenServiceWeb()
                    Timer.Add(self, 1, function()
                        self.ReloginToRoleList()
                    end)
                end, function()
                    self.ReloginToRoleList()
                end)

                dialog:SetButtonContent("Confirm", "联系客服")
                dialog:SetButtonContent("Cancel", "取消")
            end
        end


        return
    else
        self.ReloginToRoleList()
    end

    if nEvent == LOGIN.REQUEST_LOGIN_GAME_NEED_BIND_PHONE then
        UIHelper.ShowSystemConfirm(g_tStrings.BIND_PHONE_TIPS, function()
            APIHelper.OpenURL_VerifyPhone()
        end)
    else
        LoginMgr.ErrorMsg(self, LoginEventName[nEvent])
    end
end

function LoginEnterGame.CheckEnterGame(szRoleName, bDefaultMap)
    local moduleGateway = LoginMgr.GetModule(LoginModule.LOGIN_GATEWAY)
    if moduleGateway.IsConnectingGateway() then
        LoginMgr.ErrorMsg(self, "操作频繁，账号数据加载中...")
        return
    end

    local moduleRoleList = LoginMgr.GetModule(LoginModule.LOGIN_ROLELIST)
    local tRoleInfoList = moduleRoleList and moduleRoleList.GetRoleInfoList()
    for _, tRoleInfo in pairs(tRoleInfoList or {}) do
        if tRoleInfo.RoleName == szRoleName then
            local dwMapID = tRoleInfo.dwMapID

            --临时功能，地图白名单
            local nPackID = PakDownloadMgr.GetMapResPackID(dwMapID)
            if not PakDownloadMgr.IsPackInWhiteList(nPackID, "本次测试暂未开放此场景，将前往其他场景") then
                LoginMgr.SwitchStep(NEXT_LOGIN_STEP, szRoleName, true)
                XGSDK_TrackEvent("game.login.checkmap", "confirm.download", {})
                return
            end

            if not PakDownloadMgr.CheckLoginToDefaultMap(dwMapID, tRoleInfo.RoleLevel, tRoleInfo.dwForceID) then
                break
            end

            local function _loginToDefaultMap()
                --返回默认场景
                LoginMgr.SwitchStep(NEXT_LOGIN_STEP, szRoleName, true)
                XGSDK_TrackEvent("game.login.checkmap", "confirm.download", {{"confirmdownload", "not"}})
            end

            if bDefaultMap then
                _loginToDefaultMap()
                return
            end

            --判断地图资源是否下载完成
            local nState, dwTotalSize, dwDownloadedSize = PakDownloadMgr.GetMapResPackState(dwMapID)
            if nState ~= DOWNLOAD_OBJECT_STATE.DOWNLOADED and dwDownloadedSize < dwTotalSize then
                if UIMgr.IsOpening() then
                    return
                end

                LoginMgr.Log(self, "CheckEnterGame, Map Need Download, %d", dwMapID)
                local dialog = UIHelper.ShowSystemConfirm("当前角色离线场景需要下载资源，是否继续前往离线场景或返回无需下载资源的默认场景（侠客岛/百溪）？", function()
                    LoginMgr.SwitchStep(NEXT_LOGIN_STEP, szRoleName)
                    XGSDK_TrackEvent("game.login.checkmap", "confirm.download", {{"confirmdownload", "confirmd"}})
                end, function()
                    --取消
                    --TODO 埋点？
                end)

                dialog:ShowOtherButton()
                dialog:SetOtherButtonClickedCallback(_loginToDefaultMap)

                dialog:SetConfirmButtonContent("下载资源前往")
                dialog:SetCancelButtonContent("取消")
                dialog:SetOtherButtonContent("返回默认场景")
                return
            end
            break
        end
    end

    LoginMgr.SwitchStep(NEXT_LOGIN_STEP, szRoleName)
    XGSDK_TrackEvent("game.login.checkmap", "confirm.download", {})
end

function LoginEnterGame.OnGiveUpQueueSuccess()
    self.ReloginToRoleList()
end

function LoginEnterGame.ReloginToRoleList()
    g_tbLoginData.bNotLogout = false
    g_tbLoginData.bReLoginToRoleListFlag = true
    local moduleGateway = LoginMgr.GetModule(LoginModule.LOGIN_GATEWAY)
    local moduleAccount = LoginMgr.GetModule(LoginModule.LOGIN_ACCOUNT)
    moduleAccount.ClearLogin()
    moduleGateway.ConnectGateway()
end

function LoginEnterGame.GetEnterGameRoleInfo()
    return self.tEnterGameRoleInfo
end

function LoginEnterGame.GetCurRoleInfo()
    -- return self.tbCurRoleInfo
    return self.szRoleName
end

function LoginEnterGame.SetRoleTypeAndForceID(tbRoleInfo)
    self.tbCurRoleInfo =
    {
        nRoleType = 1,
        nForceID = 1,
        nFreezeTime = 0,
        byFreezeType = 0,
        nRoleID = 0,
        szRoleName = "",
        szGlobalID = ""
    }

    if tbRoleInfo then
        self.tbCurRoleInfo.nRoleType = tbRoleInfo.RoleType
        self.tbCurRoleInfo.nForceID = tbRoleInfo.dwForceID
        self.tbCurRoleInfo.nFreezeTime = tbRoleInfo.nFreezeTime
        self.tbCurRoleInfo.byFreezeType = tbRoleInfo.byFreezeType
        self.tbCurRoleInfo.nRoleID = tbRoleInfo.RoleID
        self.tbCurRoleInfo.szRoleName = UIHelper.GBKToUTF8(tbRoleInfo.RoleName)
        self.tbCurRoleInfo.szGlobalID = tbRoleInfo.GlobalID
    end
end

function LoginEnterGame.SetRoleLoginRealMap(dwMapID)
    if not self.szRoleName then
        LoginMgr.Log(self, "SetRoleLoginRealMap Error, szRoleName is nil")
        return
    end
    if self.tEnterGameRoleInfo and self.tEnterGameRoleInfo.dwMapID == dwMapID then
        return
    end
    self.tRoleLoginRealMapID = self.tRoleLoginRealMapID or {}
    self.tRoleLoginRealMapID[self.szRoleName] = dwMapID
end

function LoginEnterGame.GetRoleLoginRealMap(szRoleName)
    if not szRoleName then return end
    return self.tRoleLoginRealMapID and self.tRoleLoginRealMapID[szRoleName]
end

function LoginEnterGame.ClearRoleLoginRealMap()
    self.tRoleLoginRealMapID = {}
end

-------------------------------- Private --------------------------------

function LoginEnterGame._setEnterGameRoleInfo(szRoleName)
    local moduleRoleList = LoginMgr.GetModule(LoginModule.LOGIN_ROLELIST)
    local tRoleInfoList = moduleRoleList.GetRoleInfoList()
    local nRoleIndex = moduleRoleList.GetRoleIndex(szRoleName)
    local tRoleInfo = tRoleInfoList and tRoleInfoList[nRoleIndex]
    if tRoleInfo then
        --记录当次登录的部分信息，用于显示Loading图片（LOADING_END时清除）
        self.tEnterGameRoleInfo = {
            dwMapID = tRoleInfo.dwMapID,
            dwForceID = tRoleInfo.dwForceID,
            nTotalGameTime = tRoleInfo.nTotalGameTime,
        }

        if self.tEnterGameRoleInfo.dwForceID == 0 and self.tEnterGameRoleInfo.nLastSaveTime == 0 and self.tEnterGameRoleInfo.nTotalGameTime == 0 then
            --新创建的角色获取不到dwForceID，要转一下
            self.tEnterGameRoleInfo.dwForceID = KUNGFU_ID_FORCE_TYPE[tRoleInfo.dwKungfuID]
        end
    else
        self.tEnterGameRoleInfo = nil
    end
end

return LoginEnterGame
