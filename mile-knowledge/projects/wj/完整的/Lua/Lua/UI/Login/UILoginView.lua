---@class UILoginView
local UILoginView = class("UILoginView")

local LOGIN_ANNOUNCEMENT_RQST_KEY = "LOGIN_ANNOUNCEMENT"

local tServerStateImg = {
    [LoginServerStatus.IDLE] = "UIAtlas2_Login_login_icon_fuwuqi_07",
    [LoginServerStatus.SMOOTHLY] = "UIAtlas2_Login_login_icon_fuwuqi_07",
    [LoginServerStatus.GOOD] = "UIAtlas2_Login_login_icon_fuwuqi_07",
    [LoginServerStatus.BUSY] = "UIAtlas2_Login_login_icon_fuwuqi_06",
    [LoginServerStatus.FULL] = "UIAtlas2_Login_login_icon_fuwuqi_05",
    [LoginServerStatus.SERVICING] = "UIAtlas2_Login_login_icon_fuwuqi_08",
}

function UILoginView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        g_tbLoginData.LoginView = self
        self.moduleServerList = LoginMgr.GetModule(LoginModule.LOGIN_SERVERLIST)
        self.moduleSDK = LoginMgr.GetModule(LoginModule.LOGIN_SDK)
        ---@type LoginAccount
        self.moduleAccount = LoginMgr.GetModule(LoginModule.LOGIN_ACCOUNT)
        ---@type LoginGateway
        self.moduleGateway = LoginMgr.GetModule(LoginModule.LOGIN_GATEWAY)
        self.moduleDownload = LoginMgr.GetModule(LoginModule.LOGIN_DOWNLOAD)

        self:InitUI()
        if g_tbLoginData.bIsDevelop then
            self.moduleAccount.SetAccountPassword(Storage.Login.szAccount, Storage.Login.szPassword)
        end

        --拉取服务器列表
        g_tbLoginData.bRequestServerListSuccess = false
        self.moduleServerList.RequestServerList()

        --默认以bIsDevelop来决定是否显示SDK登录窗口
        if not g_tbLoginData.bIsDevelop and not self.moduleSDK.GetAuthInfo() and not g_tbLoginData.bKickAccount then
            self.moduleSDK.OpenSDKWindow()
        end

        self:UpdateLoginState()
        self:UpdateQuality()
        self:UpdateResource()

        -- 这个定时器暂时屏蔽，目前登录界面没有下载进度显示 by huqing 2024/3/28
        -- 若正在下载，固定每0.1s更新一次
        -- Timer.AddCycle(self, 0.1, function()
        --     if not PakDownloadMgr.IsUIUpdateEnabled() then
        --         return
        --     end

        --     if PakDownloadMgr.IsBasicDownloading() then
        --         self:UpdateDownloadProgress()
        --     end
        -- end)

        -- Timer.AddCycle(self, 15, function()
        --     self:RequestAnnouncement()
        -- end)

        Timer.Add(self, 1, function()
            Platform.CheckIsDeviceSupport()
        end)
    end

    local szLoginMoviePath = Table_GetPath("MOBILE_LOGIN_MOVIE")
    if Platform.IsWindows() or Platform.IsMac() then
        szLoginMoviePath = Table_GetPath("PC_LOGIN_MOVIE")
    end

    -- 蔚领云游戏屏蔽
    if IsWLCloud() then
        UIHelper.SetVisible(self.BtnChangeAccount, false) -- 屏蔽切换账号
        UIHelper.SetVisible(self.BtnRepair, false) -- 屏蔽修复资源
        UIHelper.SetVisible(self.BtnQuit, false) -- 屏蔽退出
    end

    -- 抖音联运官包，屏蔽退出按钮
    if Channel.Is_dylianyunyun() then
        UIHelper.SetVisible(self.BtnQuit, false) -- 屏蔽退出
    end

    UIMgr.Open(VIEW_ID.PanelLogoVideo, nil, szLoginMoviePath, true, true)
	UIHelper.SetLocalZOrder(self._rootNode, -1) --防止断线后界面重新打开盖住下载之类的界面
    self:CheckShowKickOutMsg()

    GameSettingData.StoreNewValue(UISettingKey.EnableLogging, GameSettingData.IsOpenLogReport())
end

function UILoginView:OnExit()
    self.bInit = false
    self:UnRegEvent()

    g_tbLoginData.LoginView = nil
    g_tbLoginData.bKickAccount = false

    --若登录界面关闭，则同时也将子界面关闭
    UIMgr.Close(VIEW_ID.PanelServerSelect)
    UIMgr.Close(VIEW_ID.PanelAgeLimitedPop)
    UIMgr.Close(VIEW_ID.PanelLogoVideo)
    UIMgr.Close(VIEW_ID.PanelUpdateAbroad)
    --UIMgr.ShowLayer("UISceneLayer")
end

function UILoginView:RegEvent()
    Event.Reg(self, EventType.Login_UpdateState, function()
        self:UpdateLoginState()
    end)
    Event.Reg(self, EventType.Login_SelectServer, function(tbServer)
        if tbServer then
            local szShowText = string.format("%s·%s", tbServer.szDisplayRegion, tbServer.szDisplayServer)
            UIHelper.SetString(self.LabelServerChange, szShowText)
            UIHelper.SetSpriteFrame(self.ImgServerState, tServerStateImg[tbServer.nState])

            if Version.IsBVT() then
                if tbServer.nState == 1 then
                    UIHelper.SetSpriteFrame(self.ImgServerState, tServerStateImg[LoginServerStatus.SMOOTHLY])
                end
            end

            CareerData.UpdateServerName(tbServer.szDisplayServer)
        else
            UIHelper.SetString(self.LabelServerChange, "选择服务器")
            UIHelper.SetSpriteFrame(self.ImgServerState, tServerStateImg[LoginServerStatus.SERVICING])
        end
        UIHelper.LayoutDoLayout(self.LayoutLogin)
    end)

    -- Event.Reg(self, EventType.PakDownload_OnBasicStart, function()
    --     self:UpdateDownloadProgress()
    -- end)
    -- Event.Reg(self, EventType.PakDownload_OnBasicComplete, function()
    --     self:UpdateDownloadProgress()
    -- end)
    -- Event.Reg(self, EventType.PakDownload_OnStateUpdate, function(nPackID)
    --     if PakDownloadMgr.IsBasicDownloading() then
    --         self:UpdateDownloadProgress()
    --     end
    -- end)
    Event.Reg(self, "CURL_REQUEST_RESULT", function(szKey, bSuccess, szContent, dwBufferSize)
        self:OnCURLRequestResult(szKey, bSuccess, szContent, dwBufferSize)
    end)
    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        if nViewID == VIEW_ID.PanelSceneSwitcher then
            self:CheckShowKickOutMsg()
        end
    end)
    Event.Reg(self, EventType.OnWindowsSetFocus, function()
        self:DoIconLayout()
    end)
    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        self:DoIconLayout()
    end)

    Event.Reg(self, EventType.XGSDK_OnLoginSuccess, function()
        local bHasNewBulletin = false

        for _, szBulletinType in pairs(BulletinType) do
            if BulletinData.HasNewBulletin(szBulletinType) then
                bHasNewBulletin = true
                break
            end
        end

        --SDK登录成功后，若有公告需要弹出，则将登录按钮禁用0.5s
        if bHasNewBulletin then
            self.nCanClickBtnTime = GetTickCount() + 500
        end
    end)

    Event.Reg(self, EventType.OnKeyboardDown, function(nKeyCode, szKeyName)
        if LoginMgr.IsWaiting() then
            return
        end

        if nKeyCode == cc.KeyCode.KEY_ENTER then
            if UIHelper.GetHierarchyVisible(self.BtnStart) then
                self:OnClickStart()
            elseif UIHelper.GetHierarchyVisible(self.BtnLogin) then
                self:OnClickLogin()
            end
        end
    end)
end

function UILoginView:UnRegEvent()

end

function UILoginView:BindUIEvent()
    local function BindUIEvent(btn, nEventType, fnCallback)
        UIHelper.BindUIEvent(btn, nEventType, function()
            --避免同时按Enter和点按钮的情况
            if LoginMgr.IsWaiting() or not UIHelper.GetHierarchyVisible(btn) then
                return
            end
            if fnCallback then
                fnCallback()
            end
        end)
    end

    --登录服务器
    BindUIEvent(self.BtnStart, EventType.OnClick, function()
        self:OnClickStart()
    end)

    --选服
    BindUIEvent(self.BtnServerChange, EventType.OnClick, function()
        if self.nCanClickBtnTime and GetTickCount() < self.nCanClickBtnTime then
            return
        end

        --记录换服前的登录信息，若换服失败则使用该信息显示
        self.szLoginAccount = g_tbLoginData.tbLoginInfo.szLoginAccount or self.szLoginAccount
        UIMgr.Open(VIEW_ID.PanelServerSelect)
    end)

    --登录账号
    BindUIEvent(self.BtnLogin, EventType.OnClick, function()
        self:OnClickLogin()
    end)

    --切换账号
    BindUIEvent(self.BtnChangeAccount, EventType.OnClick, function()
        if g_tbLoginData.bIsDevelop then
            self.szLoginAccount = nil
            g_tbLoginData.bNotLogout = false
            self:Logout()
        else
            self.nCanClickBtnTime = GetTickCount() + 1000 --加个登录按钮的CD，避免点了切换账号后立即点登录
            self.moduleSDK.OpenUserCenter()
            --self.moduleSDK.SDKLogout()
        end
    end)

    --官网 显隐状态通过改UIVisibleCheckTab表控制
    BindUIEvent(self.BtnOfficialWebsite, EventType.OnClick, function()
        UIHelper.OpenWebWithDefaultBrowser("https://jx3.xoyo.com/")
    end)

    --片头
    BindUIEvent(self.BtnTitles, EventType.OnClick, function()
        LOG.INFO("---------------- BtnTitles OnClick ----------------")
    end)

    --公告
    BindUIEvent(self.BtnBroadcast, EventType.OnClick, function()
        --UIHelper.OpenWeb("https://jx3.xoyo.com/show-2466-5474-1.html")
        UIMgr.Open(VIEW_ID.PanelUpdateAbroad)
    end)

    --修复
    BindUIEvent(self.BtnRepair, EventType.OnClick, function()
        local tTotalInfo = PakDownloadMgr.GetTotalDownloadInfo()
        if tTotalInfo.nTotalState == TOTAL_DOWNLOAD_STATE.DOWNLOADING then
            TipsHelper.ShowNormalTip("资源下载期间，无法进行修复操作")
            return
        end
        UIHelper.ShowConfirm("是否立即退出游戏进行资源检测修复？将在下次启动游戏时生效。修复耗时较长，为防止数据文件损坏，修复过程中请勿中断退出游戏。", function()
            PakDownloadMgr.RepairAllPacks(function()
                Game.Exit() --修复后自动退出游戏
            end)
        end)
    end)

    --名单
    BindUIEvent(self.BtnList, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelCreatorName)
    end)

    --说明-适龄提醒
    BindUIEvent(self.BtnUnder18, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelHelpPop, 18)
    end)

    --协议改为使用SDK提供的
    -- --协议1
    -- BindUIEvent(self.BtnAgreement01, EventType.OnClick, function()
    --     LOG.INFO("---------------- BtnAgreement01 OnClick ----------------")
    -- end)

    -- --协议2
    -- BindUIEvent(self.BtnAgreement02, EventType.OnClick, function()
    --     LOG.INFO("---------------- BtnAgreement02 OnClick ----------------")
    -- end)

    --适龄提示
    BindUIEvent(self.ButtonAgeLimit, EventType.OnClick, function()
        --UIMgr.Open(VIEW_ID.PanelAgeLimitedPop)
        UIMgr.Open(VIEW_ID.PanelHelpPop, 17)
    end)

    --开发者选服
    BindUIEvent(self.BtnDevelop, EventType.OnClick, function()
        --self.moduleServerList._parseLocalServerList(false)
        local bIsLogin = LoginMgr.IsLogin()
        if bIsLogin then
            --记录换服前的登录信息，若换服失败则使用该信息显示
            self.szLoginAccount = g_tbLoginData.tbLoginInfo.szLoginAccount or self.szLoginAccount
        end
        UIMgr.Open(VIEW_ID.PanelServerSelect)
    end)

    --退出游戏
    BindUIEvent(self.BtnQuit, EventType.OnClick, function()
        UIHelper.ShowConfirm(g_tStrings.EXIT_QUIT, function()
            Game.Exit()
        end)
    end)

    --切换SDK/开发者登录
    BindUIEvent(self.BtnLoginSwitch, EventType.OnClick, function()
        self:SwitchSDKLogin()
    end)

    --打开SDK窗口
    BindUIEvent(self.BtnSDK, EventType.OnClick, function()
        self.moduleSDK.OpenSDKWindow()
    end)

    UIHelper.BindUIEvent(self.TogVolume, EventType.OnSelectChanged, function(_,bSelected)
        local tVal = GetGameSoundSetting(SOUND.MAIN)
        tVal.TogSelect = bSelected
        EnableAllSound(not bSelected)
    end)

    --重置画面设置
    BindUIEvent(self.BtnRevert, EventType.OnClick, function()

        local szConetnt = "是否恢复默认设置？如选择“确认”，本设备的<color=#ffe26e>画面设置</color>将恢复默认，请谨慎选择！"
        UIHelper.ShowConfirm(szConetnt,
                function()
                    QualityMgr.ResetToDefaultQuality()
                    self:UpdateQuality()
                end, nil, true)
    end)

    BindUIEvent(self.BtnCommitDate, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelCommitDatePop)
    end)
end

function UILoginView:InitUI()
    if g_tbLoginData.bIsDevelop then
        UIHelper.SetString(self.LabelLoginSwitch, "切换SDK登录")
    else
        UIHelper.SetString(self.LabelLoginSwitch, "切换开发者登录")
    end

    UIHelper.SetVisible(self.BtnDevelop, g_tbLoginData.bShowDevelopBtn)
    UIHelper.SetVisible(self.BtnLoginSwitch, g_tbLoginData.bShowDevelopBtn)

    UIHelper.SetString(self.LabelServerChange, "选择服务器")
    UIHelper.SetSpriteFrame(self.ImgServerState, tServerStateImg[LoginServerStatus.SERVICING])

    --公告
    UIHelper.SetVisible(self.LayoutBroadcast, false)
    -- self:RequestAnnouncement()
    if not g_tbLoginData.bIsDevelop and LoginMgr.IsLogin() then
        Timer.Add(self, 1, function()
            BulletinData.CheckOpenBulletinPanel()
        end)
    end

    local szVersionName = GetVersionName()
    local nVersionCode = GetVersionCode()
    local nPakV5Version = GetPakV5Version()
    UIHelper.SetString(self.LabelPeice01, tostring(nPakV5Version))
    UIHelper.SetString(self.LabelPeice02, string.format("%s(%s)", szVersionName, tostring(nVersionCode)))

    --资源下载
    local scriptDownload = UIHelper.GetBindScript(self.WidgetDownloadPop)
    --scriptDownload:OnInitBasic()
    scriptDownload:OnInitTotal()

    local bEnableSound = not App_GetMute()
    UIHelper.SetSelected(self.TogVolume ,not bEnableSound)
end

function UILoginView:RequestAnnouncement()
    local szUrl
    local _, _, _, szVersionEx, _ = GetVersion()
    if szVersionEx == GetVersionExp() or szVersionEx == "bvt" then
        szUrl = "https://jx3.xoyo.com/client/v3_kefu_tf_ext.txt" --体服
    else
        szUrl = tUrl.Bulletin
    end

    if szUrl then
        --LOG.INFO("[LoginMgr] Request Announcement: %s", szUrl)
        local bSSL = string.starts(szUrl, "https")
        CURL_HttpRqst(LOGIN_ANNOUNCEMENT_RQST_KEY, szUrl, bSSL, 10)
    end
end

function UILoginView:OnCURLRequestResult(szKey, bSuccess, szContent, dwBufferSize)
    if szKey ~= LOGIN_ANNOUNCEMENT_RQST_KEY then
        return
    end

    if not bSuccess then
        return
    end

    if not szContent or szContent == "" then
        UIHelper.SetVisible(self.LayoutBroadcast, false)
        return
    end

    --TODO
    -- local _, _, szBulletinContent, szBulletinDate = string.find(szContent, "([^\n]*)\n(.*)")
    -- if not szBulletinContent or not szBulletinDate then
    --     UIHelper.SetVisible(self.LayoutBroadcast, false)
    --     return
    -- end

    UIHelper.SetVisible(self.LayoutBroadcast, true)
    UIHelper.SetString(self.LabelServerBroadcast, szContent)
    UIHelper.LayoutDoLayout(self.LayoutBroadcast)
end

function UILoginView:Login()
    self:Logout()
    self.moduleGateway.ConnectGateway()
end

function UILoginView:Relogin()
    self:ClearLogin()
    self.moduleGateway.ConnectGateway()
end

function UILoginView:Logout()
    self:ClearLogin()
    self:UpdateLoginState()
end

function UILoginView:ClearLogin()
    self.moduleAccount.ClearLogin()
end

--根据当前登录状态更新UI显示
function UILoginView:UpdateLoginState()
    local bIsLogin = LoginMgr.IsLogin() or self.szLoginAccount ~= nil
    if bIsLogin then
        if g_tbLoginData.bIsDevelop then
            self:SaveRecentLogin()
            local szLoginAccount = g_tbLoginData.tbLoginInfo.szLoginAccount or self.szLoginAccount
            UIHelper.SetString(self.LabelAccount, szLoginAccount) --设置右上角账号信息
        -- else
        --     UIHelper.SetString(self.LabelAccount, "")
        --     self.moduleSDK.GetAccountInfo()
        end
    end

    UIHelper.SetVisible(self.LabelAccount, bIsLogin and g_tbLoginData.bIsDevelop) --右上角账号信息
    UIHelper.SetVisible(self.BtnChangeAccount, bIsLogin and not IsWLCloud()) --右上角切换账号按钮
    UIHelper.SetVisible(self.BtnSDK, not bIsLogin and not g_tbLoginData.bIsDevelop)
    UIHelper.SetVisible(self.WidgetAnchorServer, bIsLogin or not g_tbLoginData.bIsDevelop)
    UIHelper.SetVisible(self.WidgetAnchorPassword, not bIsLogin and g_tbLoginData.bIsDevelop) --登录输入
    --UIHelper.SetVisible(self.WidgetAnchorBottom, not bIsLogin) --协议
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutIcon, true, true)
    self:UpdateDownloadProgress()
end

function UILoginView:UpdateDownloadProgress()
    local bIsLogin = LoginMgr.IsLogin()
    local bDownloading = false --PakDownloadMgr.IsBasicDownloading() --2023.12.14 不单独显示基础包下载进度条
    local nRoleCount = Login_GetRoleCount()
    local nState, _, _ = PakDownloadMgr.GetBasicPackState()

    local bShowDownload = bDownloading and bIsLogin
    UIHelper.SetVisible(self.WidgetDownload, bShowDownload) --下方下载进度条
    --UIHelper.SetVisible(self.WidgetDownloadPop, nState ~= DOWNLOAD_OBJECT_STATE.DOWNLOADED and bIsLogin) --下载按钮
    UIHelper.SetVisible(self.ImgBg, not bShowDownload)
    UIHelper.SetVisible(self.LabelResource, not bShowDownload) --下载时隐藏下方健康游戏忠告
    --UIHelper.SetVisible(self.WidgetAnchorServer,  bIsLogin and (not bDownloading or nRoleCount <= 0)) --2023.12.18 常驻显示
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutIcon, true, true)

    if not bDownloading then
        return
    end

    local tTotalInfo = PakDownloadMgr.GetTotalDownloadInfo()
    local dwDownloadSpeed = PakDownloadMgr.GetTotalDownloadSpeed()
    local nTotalState = tTotalInfo.nTotalState

    local szDownloaded = PakDownloadMgr.FormatSize(tTotalInfo.dwDownloadedSize) .. "/" .. PakDownloadMgr.FormatSize(tTotalInfo.dwTotalSize)

    UIHelper.SetProgressBarPercent(self.WidgetPrograss, tTotalInfo.nProgress * 100)

    if nTotalState == TOTAL_DOWNLOAD_STATE.DOWNLOADING then
        UIHelper.SetString(self.LabelSpeed, "下载中（" .. szDownloaded .. "，当前速度：" .. PakDownloadMgr.FormatSize(dwDownloadSpeed, 2) .. "/s）")
    elseif nTotalState == TOTAL_DOWNLOAD_STATE.PAUSING then
        UIHelper.SetString(self.LabelSpeed, "已暂停（" .. szDownloaded .. "）")
    elseif nTotalState == TOTAL_DOWNLOAD_STATE.RETRYING then
        UIHelper.SetString(self.LabelSpeed, "重试中（" .. szDownloaded .. "）")
    end
end

--初始化最近登录信息
function UILoginView:InitRecentLogin()
    local tbSelectServer = self.moduleServerList.GetSelectServer()
    if not tbSelectServer then
        local tbRecentServer = self.moduleServerList.LoadRecentLoginServer()
        if (not tbRecentServer or not self.moduleServerList.GetServer(tbRecentServer.szRegion, tbRecentServer.szServer)) then
            if g_tbLoginData.bIsDevelop then
                --手机开发包默认连BVT服务器
                if not Platform.IsWindows() then
                    local tbBVTServer = self.moduleServerList.GetServer(LoginServerDef.AutoRegion, LoginServerDef.AutoServer)
                    if tbBVTServer then
                        tbRecentServer = tbBVTServer
                    end
                end
            else
                -- bvt包，并且SDK登录就默认选择SDK测试服
                if not g_tbLoginData.bUseRemoteServerList then
                    local tbSDKTestServer = self.moduleServerList.GetServer(LoginServerDef.AutoRegion_SDKTest, LoginServerDef.AutoServer_SDKTest)
                    if tbSDKTestServer then
                        tbRecentServer = tbSDKTestServer
                    end
                end
            end
        end

        --若无最近服务器，则将最新的服务器作为目标服务器
        --以第一个服务器作为最新服务器
        if (not tbRecentServer or not self.moduleServerList.GetServer(tbRecentServer.szRegion, tbRecentServer.szServer)) and g_tbLoginData.aServerList[1] then
            if g_tbLoginData.aServerList[1].bCommend then
                local nRandom = math.random(1, #g_tbLoginData.aServerList[1])
                tbRecentServer = g_tbLoginData.aServerList[1][nRandom]
                LOG.INFO("[Login] Select Random Server: %d (%s)", nRandom, tostring(tbRecentServer.szServer))
            else
                tbRecentServer = g_tbLoginData.aServerList[1][1]
            end
        end

        self.moduleServerList.SetSelectServer(tbRecentServer.szRegion, tbRecentServer.szServer)
    else
        self.moduleServerList.SetSelectServer(tbSelectServer.szRegion, tbSelectServer.szServer)
    end

    local tLoginData = Storage.Login
    self.moduleAccount.SetAccountPassword(tLoginData.szAccount, tLoginData.szPassword)

    --UIHelper.SetSelected(self.TogCheck, tLoginData.bIsRemAcc)
    UIHelper.SetSelected(self.TogCheck, true) --2023.7.6 记住账号临时改为默认勾选
    --UIHelper.SetSelected(self.TogConsent, tLoginData.bIsConsent)

    --自动登录
    if g_tbLoginData.bIsDevelop and not Config.bSDKLogin and g_tbLoginData.bAutoLogin and not g_tbLoginData.bNotLogout and
    tLoginData.szAccount ~= "" and tLoginData.szPassword ~= "" then
        LOG.INFO(g_tStrings.tbLoginString.ACCOUNT_AUTO_LOGIN_COUNTDOWN)
        self:Login()
    end
end

--保存最近登录信息
function UILoginView:SaveRecentLogin()
    local tLoginData = Storage.Login
    tLoginData.bIsRemAcc = UIHelper.GetSelected(self.TogCheck)
    --tLoginData.bIsConsent = UIHelper.GetSelected(self.TogConsent)

    if tLoginData.bIsRemAcc then
        local szAccount, szPassword = self.moduleAccount.GetAccountPassword()
        tLoginData.szAccount = szAccount
        tLoginData.szPassword = szPassword
    else
        tLoginData.szAccount = ""
        tLoginData.szPassword = ""
    end
    tLoginData.Dirty()
end

function UILoginView:SwitchSDKLogin()
    if not g_tbLoginData.bIsDevelop then
        self.moduleSDK.SDKLogout()
    end
    g_tbLoginData.bIsDevelop = not g_tbLoginData.bIsDevelop
    LoginMgr.BackToLogin() --清理缓存数据
    self:Logout()

    if g_tbLoginData.bIsDevelop then
        UIHelper.SetString(self.LabelLoginSwitch, "切换SDK登录")
        LOG.INFO("[LoginMgr] 已进入开发者登录模式")
    else
        UIHelper.SetString(self.LabelLoginSwitch, "切换开发者登录")
        LOG.INFO("[LoginMgr] 已进入SDK登录模式")
        self.moduleSDK.OpenSDKWindow()
    end

    self.moduleServerList._parseLocalServerList(not g_tbLoginData.bIsDevelop)
    self:InitRecentLogin()
end

function UILoginView:CheckShowKickOutMsg()
    if not g_tbLoginData.bKickAccount then
        return
    end

    --等场景切换界面关闭后再打开
    if UIMgr.GetView(VIEW_ID.PanelSceneSwitcher) then
        return
    end

    g_tbLoginData.bKickAccount = false

    if g_tbLoginData.nKickAccountReason then
        local szContent = g_tStrings.tbLoginString.BE_KICK_ACCOUNT
        if g_tbLoginData.nKickAccountReason == LOAD_LOGIN_REASON.KICK_OUT_BY_OTHERS then
            szContent = g_tStrings.tbLoginString.BE_KICK_ACCOUNT
        elseif g_tbLoginData.nKickAccountReason == LOAD_LOGIN_REASON.KICK_OUT_BY_GM then
            szContent = g_tStrings.tbLoginString.BE_KICK_ACCOUNT_GM
        end

        Timer.Add(self, 0.3, function()
            local dialog = TipsHelper.ShowServiceConfirmTips(szContent, function()
                local szUrl = ""
                if Platform.IsWindows() or Platform.IsMac() then
                    szUrl = tUrl.ServiceCenter_VK_PC
                else
                    szUrl = tUrl.ServiceCenter_VK_Mobile
                end

                if not string.is_nil(szUrl) then
                    UIHelper.OpenWeb(szUrl)
                end
                if not g_tbLoginData.bIsDevelop and not self.moduleSDK.GetAuthInfo() then
                    self.moduleSDK.OpenSDKWindow()
                end
            end)
        end)

        g_tbLoginData.nKickAccountReason = nil
    else
        if not g_tbLoginData.bIsDevelop and not self.moduleSDK.GetAuthInfo() then
            self.moduleSDK.OpenSDKWindow()
        end
    end
end

-- 模拟器检测
function UILoginView:CheckIsSimulator()
    local bResult = false
    if Device.IsSimulator() then
        local dialog = UIHelper.ShowConfirm("请使用非模拟器进行游戏。", function()
            Game.Exit()
        end)
        dialog:HideButton("Cancel")
        bResult = true
    end
    return bResult
end

function UILoginView:OnClickStart()
    if self:CheckIsSimulator() then
        return
    end

    if self.moduleSDK.IsSDKWindowOpened() then
        return
    end

    -- --许可协议 改为使用SDK提供的
    -- if not UIHelper.GetSelected(self.TogConsent) then
    --     TipsHelper.ShowNormalTip(g_tStrings.tbLoginString.EULA_UNCHECK)
    --     return
    -- end

    self.szLoginAccount = nil
    g_tbLoginData.bNotLogout = false
    local szAccount, szPassword = self.moduleAccount.GetAccountPassword()

    -- 开发者登录的给一个默认密码，不然每次要求输密码
    if g_tbLoginData.bIsDevelop then
        szPassword = "a"
    end

    if szAccount ~= "" and szPassword ~= "" then
        self:Login()
    else
        if szAccount == "" and szPassword == "" then
            TipsHelper.ShowNormalTip(g_tStrings.tbLoginString.ACCOUNT_PASSWORD_CANNOT_EMPTY)
        elseif szAccount == "" then
            TipsHelper.ShowNormalTip(g_tStrings.tbLoginString.ACCOUNT_CANNOT_EMPTY)
        elseif szPassword == "" then
            TipsHelper.ShowNormalTip(g_tStrings.tbLoginString.PASSWORD_CANNOT_EMPTY)
        end
    end
end

function UILoginView:OnClickLogin()
    if self:CheckIsSimulator() then
        return
    end

    if self.nCanClickBtnTime and GetTickCount() < self.nCanClickBtnTime then
        return
    end

    if self.moduleSDK.IsSDKWindowOpened() then
        return
    end

    local bIsLogin = LoginMgr.IsLogin()
    if not bIsLogin and not g_tbLoginData.bIsDevelop then
        self.moduleSDK.OpenSDKWindow()
        return
    end

    if bIsLogin and g_tbLoginData.bIsDevelop and not g_tbLoginData.bIsGetAllRoleListSuccess then
        --若角色列表未拉取完成，则等待
        TipsHelper.ShowNormalTip(g_tStrings.tbLoginString.WAITING_ROLE_LIST)
        return
    end

    local function fnLogin()
        local tbServer = self.moduleServerList.GetSelectServer()
        if tbServer then
            if tbServer.nId == g_tbLoginData.tbLoginInfo.nLoginServerID then
                LoginMgr.SwitchStep(LoginModule.LOGIN_ROLELIST)
            else
                --重新登录，且登录成功后立刻切换到RoleList
                g_tbLoginData.bReLoginToRoleListFlag = true
                self:Relogin()
            end
        end
    end

    local nState, _, _ = PakDownloadMgr.GetBasicPackState(true)
    if nState == DOWNLOAD_OBJECT_STATE.NOTEXIST or nState == DOWNLOAD_OBJECT_STATE.PAUSE then
        self.moduleDownload.ShowDownloadConfirm(fnLogin, fnLogin)
    else
        fnLogin()
    end
end

function UILoginView:DoIconLayout()
    Timer.DelTimer(self, self.nLayoutTimerID)
    local nCount = 0
    self.nLayoutTimerID = Timer.AddFrameCycle(self, 1, function()
        nCount = nCount + 1
        UIHelper.CascadeDoLayoutDoWidget(self.LayoutIcon, true, true)
        if nCount >= 10 then
            Timer.DelTimer(self, self.nLayoutTimerID)
        end
    end)
end

function UILoginView:UpdateQuality()
    local nQualityType = QualityMgr.GetCurQualityType() or GameQualityType.MID
    local bIsRecommend = QualityMgr.GetRecommendQualityType() == nQualityType
    if not bIsRecommend then
        local szText = string.format("当前画质：%s",QualityMgr.GetQualityNameByType(nQualityType))
        UIHelper.SetRichText(self.RichTextScreen, szText)
    end
    UIHelper.SetVisible(self.WidgetAnchorRightBottom, not bIsRecommend)
end

function UILoginView:UpdateResource()
    local szContent = ""

    if Platform.IsIos() then
        szContent = [[本公司积极履行《网络游戏行业防沉迷自律公约》
        抵制不良游戏，拒绝盗版游戏。注意自我保护，谨防受骗上当。适度游戏益脑，沉迷游戏伤身。合理安排时间，享受健康生活。
        游戏著作权人：珠海金山数字网络科技有限公司  著作权登记号：2023SR1257710  审批文号：国新出审〔2023〕1736号
        出版物号：ISBN 978-7-498-12695-5  ICP备案号：琼ICP备2021004338号-13A  出版单位：成都西山居世游科技有限公司]]
    else
        szContent = [[本公司积极履行《网络游戏行业防沉迷自律公约》
        抵制不良游戏，拒绝盗版游戏。注意自我保护，谨防受骗上当。适度游戏益脑，沉迷游戏伤身。合理安排时间，享受健康生活。
        游戏著作权人：珠海金山数字网络科技有限公司  著作权登记号：2023SR1257710  审批文号：国新出审〔2023〕1736号
        出版物号：ISBN 978-7-498-12695-5  ICP备案号：蜀ICP备14009198号-32A  出版单位：成都西山居世游科技有限公司]]
    end

    UIHelper.SetString(self.LabelResource, szContent)
end

return UILoginView