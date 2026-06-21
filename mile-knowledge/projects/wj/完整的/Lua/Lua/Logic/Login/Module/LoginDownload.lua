local LoginDownload = {}
local self = LoginDownload

function LoginDownload.RegisterEvent()

end

function LoginDownload.OnEnter(szPrevStep)
    -- UIMgr.Open(VIEW_ID.PanelDownload, self._onDownloadComplete)
    PakDownloadMgr.DownloadCoreList() --登录后，若基础包下载完成则下载核心队列

    --登录后立刻进入RoleList
    if g_tbLoginData.bReLoginToRoleListFlag then
        g_tbLoginData.bReLoginToRoleListFlag = false
        LoginMgr.SwitchStep(LoginModule.LOGIN_ROLELIST)
    end
end

function LoginDownload.OnExit(szNextStep)
    -- UIMgr.Close(VIEW_ID.PanelDownload)
end

-------------------------------- Public --------------------------------

function LoginDownload.StartDownload()
    LoginMgr.Log(self, "StartDownloadBasicPack")
    if not PakDownloadMgr.IsBasicDownloading() then
        PakDownloadMgr.DownloadBasicPack()
    elseif PakDownloadMgr.IsBasicPause() then
        PakDownloadMgr.ResumeBasicPack()
    end
end

function LoginDownload.ShowDownloadConfirm(fnConfirm, fnCancel)
    local nState, dwTotalSize, dwDownloadedSize = PakDownloadMgr.GetBasicPackState(true)
    local dwLeftDownloadSize = dwTotalSize - dwDownloadedSize

    local function fnDownload()
        -- local dwSpace = App_GetRemainStorageSpace()
        -- local dwMargin = 100 * 1024 * 1024 --余量
        -- if dwLeftDownloadSize + dwMargin > dwSpace then
        --     TipsHelper.ShowNormalTip("基础资源下载失败：磁盘空间不足")
        --     return
        -- end

        self.StartDownload()
        if fnConfirm then
            fnConfirm()
        end
    end

    local szContent
    if Platform.IsWindows() or Platform.IsMac() then
        szContent = "当前需要下载" .. PakDownloadMgr.FormatSize(dwLeftDownloadSize) .. "资源方能进入游戏场景（下载期间可正常创建角色及捏脸），是否下载？"
    else
        local nNetMode = App_GetNetMode()
        if nNetMode == NET_MODE.WIFI then
            szContent = "当前需要下载" .. PakDownloadMgr.FormatSize(dwLeftDownloadSize) .. "资源方能进入游戏场景（下载期间可正常创建角色及捏脸），当前为WIFI环境，是否下载？"
        elseif nNetMode == NET_MODE.CELLULAR then
            szContent = "当前需要下载" .. PakDownloadMgr.FormatSize(dwLeftDownloadSize) .. "资源方能进入游戏场景（下载期间可正常创建角色及捏脸），当前为移动网络环境，是否下载？"
        else
            --无网络
            return
        end
    end

    XGSDK_TrackEvent("game.cellular.data.show.download.confirm", "confirm", {})

    local dialog = UIHelper.ShowSystemConfirm(szContent, function()
        -- if nNetMode == NET_MODE.CELLULAR then
        --     PakDownloadMgr.SetAllowNotWifiDownload(true)
        -- end
        fnDownload()
        XGSDK_TrackEvent("game.cellular.data.download.confirmation", "confirmation", {})
    end, function()
        fnCancel()
        XGSDK_TrackEvent("game.cellular.data.download.cancel", "cancel", {})
    end)
end

-------------------------------- Private --------------------------------


return LoginDownload