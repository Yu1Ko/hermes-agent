PakDownloadMgr = PakDownloadMgr or {className = "PakDownloadMgr"}
local self = PakDownloadMgr

 --configHttpFile.ini里的开关
local m_bEnabled = nil
local m_bDebug = nil

local STORAGE_SIZE_MARGIN = 100 * 1024 * 1024 --存储空间余量/B
local AUTO_RETRY_DELAY = 5 --自动重试时间间隔/s
local MAX_DOWNLOAD_COUNT = 1 --下载队列最大同时下载数量，小于等于0则无限制
local ENABLED_BASIC_DOWNLOAD = true --是否需要下载基础包
local ENABLED_CORE_DOWNLOAD = true --是否需要下载核心包
local ENABLED_UI_UPDATE = true --UI是否Update刷新
local DEBUG_DOWNLOADED_PACK = {} --测试用 已完成资源

local Log = function(...)
    --print(...)

    local len = select('#', ...)
    local tbMsg = {...}
    local str = ""
    for i = 1, len do
        local msg = tbMsg[i]
        if msg ~= nil then
            str = str .. tostring(msg)
        else
            str = str .. "nil"
        end
        if i ~= len then
            str = str .. "\t"
        end
    end

    LOG.INFO(str)
end

local LogDebug = function(...)
    if PakDownloadMgr.IsDebug() then
        Log(...)
    end
end

--打印用
local tEnumInfo = {}
local GetEnumStr = function(tEnum, nEnumValue)
    if not tEnumInfo[tEnum] then
        tEnumInfo[tEnum] = {}
        for szKey, nValue in pairs(tEnum) do
            tEnumInfo[tEnum][nValue] = nValue .. "(" .. szKey .. ")"
        end
    end
    return tEnumInfo[tEnum][nEnumValue] or nEnumValue
end

local Timer = DownloadTimer or Timer

-------------------------------- Init --------------------------------

PakDownloadMgr.ALL_EQUIP_PACKID = 4 --外装资源包ID
PakDownloadMgr.ALL_CLOTH_PACKID = 17 --布料资源包ID

function PakDownloadMgr.Init()
    self.RegEvent()

    self.bInit = true
    self.bManageBackgroundMode = false
    self.nManageBackgroundModeTime = 0
    self.bCurManageBackgroundMode = false
    self.tPakInfoList = {}
    self.tExtensionPackIDList = {}
    self.tDynamicPakInfoList = {}
    self.tDownloadingList = {}
    self.tTopMostPackIDList = {}
    self.tPackIDListMap = {}
    self.tGlobalTimer = { className = "PakDownloadMgr.tGlobalTimer" }
    self.tRetryTimerID = {}
    self.tDeletingPack = {}

    Storage.Download.tbTaskTable[DOWNLOAD_STATE.DOWNLOADING] = Storage.Download.tbTaskTable[DOWNLOAD_STATE.DOWNLOADING] or {}
    Storage.Download.tbTaskTable[DOWNLOAD_STATE.QUEUE] = Storage.Download.tbTaskTable[DOWNLOAD_STATE.QUEUE] or {}
    Storage.Download.tbTaskTable[DOWNLOAD_STATE.PAUSE] = Storage.Download.tbTaskTable[DOWNLOAD_STATE.PAUSE] or {}
    Storage.Download.tbTaskTable[DOWNLOAD_STATE.COMPLETE] = Storage.Download.tbTaskTable[DOWNLOAD_STATE.COMPLETE] or {}

    self._InitPackConfig()
    self._InitPriorityPackConfig()
    self._InitPackTreeConfig()
    MapHelper._InitExtraWhiteMap()
    self._InitExtensionPackIDList()

    self._TaskVersionUpdate()
    self._ClearTaskTable(true, true, true, true)
    self._UpdateMultiIntanceState(true)

    Timer.AddFrame(self.tGlobalTimer, 1, self._RefreshBasicPackState) --延迟1帧，等PakSizeQueryMgr初始化
    Timer.AddCycle(self.tGlobalTimer, 1, self._UpdateManageBackgroundMode)
end

function PakDownloadMgr.UnInit()
    Event.UnRegAll(self)
    Timer.DelAllTimer(self)
    Timer.DelAllTimer(self.tGlobalTimer)
    PakSizeQueryMgr.UnRegAllQuerySize(self)

    self._SetManageBackgroundMode(false)
    self._UpdateManageBackgroundMode(true)

    --self.PauseAllPack()
    self._ClearTaskTable(true, true, true, true)
    self.CheckClearTaskList()
    self._FlushDownloadStorage(true)

    self.bInit = false
    self.bManageBackgroundMode = false
    self.nManageBackgroundModeTime = 0
    self.bCurManageBackgroundMode = false
    self.bFlushingStorage = false
    self.dwRemainStorageSpace = nil
    self.nNetQuerySizeEntryID = nil
    self.nNetErrorRetryPackID = nil
    self.fnPauseDialog = nil
    self.tPakInfoList = {}
    self.tExtensionPackIDList = {}
    self.tDynamicPakInfoList = {}
    self.tDownloadingList = {}
    self.tTopMostPackIDList = {}
    self.tPackIDListMap = {}
    self.tGlobalTimer = {}
    self.tRetryTimerID = {}
    self.tDeletingPack = {}
end

function PakDownloadMgr._SetTimerEnabled(bEnabled)
    Timer.DelAllTimer(self)
    if bEnabled then
        self.nNetMode = App_GetNetMode() --初始化
        Log("[PakDownloadMgr] InitNetMode", GetEnumStr(NET_MODE, self.nNetMode))
        Timer.AddCycle(self, 1, self._UpdateBackgroundNotice)
    end
end

function PakDownloadMgr.RegEvent()
    Event.Reg(self, EventType.OnViewOpen, function(nViewID)
        if nViewID == VIEW_ID.PanelLogin then
            if self.bInitStorageTaskList then
                return
            end

            --第一次进入登录界面，准备基础包和未完成任务的下载
            self.bInitStorageTaskList = true
            self._InitStorageTaskList()
        elseif nViewID == VIEW_ID.PanelRoleChoices then
            if not self.tReloginPackIDList then
                return
            end

            local tCorePackIDList = self.tReloginPackIDList
            local tPausePackIDList = {}
            local function fnOnAllPaused()
                --WIFI环境自动下载
                local nNetMode = App_GetNetMode()
                if nNetMode == NET_MODE.WIFI then
                    for _, nPackID in ipairs(tCorePackIDList) do
                        self.ResumePack(nPackID)
                    end
                    Timer.Add(self.tGlobalTimer, 1, function()
                        local tCoreStateInfo = self.GetStateInfoByPackIDList(tCorePackIDList)
                        if tCoreStateInfo.nState == DOWNLOAD_STATE.DOWNLOADING then
                            TipsHelper.ShowNormalTip("核心资源已开始下载")
                        end
                    end)
                    UIMgr.Open(VIEW_ID.PanelResourcesDownload, RESOURCES_PAGE.DOWNLOADING, 1) --跳转到资源管理界面-正在下载-主要
                end
                for _, nPackID in ipairs(tPausePackIDList) do
                    self.ResumePack(nPackID)
                end
                self.tReloginPackIDList = nil
            end

            tPausePackIDList = self.PauseAllPack(fnOnAllPaused)
        end
    end)
    Event.Reg(self, EventType.OnRoleLogin, function()
        self._ClearCoreList() --成功进入场景，停止核心队列下载

        --登录后第一次加载结束
        Event.Reg(self, "LOADING_END", function()
            --初始化优先下载
            self.nUserDownloadingMapID = nil
            self._InitPriorityList()
            self._DownloadPriorityList()
        end, true)
    end)
    Event.Reg(self, "PLAYER_LEAVE_GAME", function()
        Log("[PakDownloadMgr] PLAYER_LEAVE_GAME")
        --2023.12.6 现在登录界面也可以下载，玩家退出不需要暂停或清理任务
        -- self.PauseAllPack()
        -- self.CheckClearTaskList()
        self._ClearTaskTable(false, true, true, false) --仅清理优先包
        self.bPushBubbleMsg = false
        self.tPriorityList = nil
        self.tDefaultList = nil
        self.bIsAllPriorityComplete = nil
        self.nUserDownloadingMapID = nil
        self.nDownloadSceneResMapID = nil
        Timer.DelTimer(self, self.nCheckScenePakTimerID)
    end)
    Event.Reg(self, EventType.OnClientPlayerEnter, function()
        local player = GetClientPlayer()
        self.dwClientPlayerForceID = player and player.dwForceID

        local moduleEnterGame = LoginMgr.GetModule(LoginModule.LOGIN_ENTERGAME)
        moduleEnterGame.ClearRoleLoginRealMap()
    end)
    Event.Reg(self, EventType.OnAccountLogout, function()
        self.dwClientPlayerForceID = nil
    end)
    Event.Reg(self, "CHECK_SCENE_PAK", function(nMapID, bLogin)
        -- --家园地图资源ID替换
        -- NOTE: 此时还无法获取到dwSkinID，客户端OnCheckScenePakComplete时才会调到NewClientScene里的CheckChangeSkin，这段代码先注释
        -- local hHomelandMgr = GetHomelandMgr()
        -- if hHomelandMgr then
        --     if hHomelandMgr.IsPrivateHomeMap(nMapID) then
        --         local dwMapID, dwSkinID = hHomelandMgr.GetClientCurSkin()
        --         if dwSkinID > 0  then
        --             nMapID = MapHelper.GetHomelandSkinResMapID(dwMapID, dwSkinID)
        --         end
        --     end
        -- end

        Log("[PakDownloadMgr] CHECK_SCENE_PAK", nMapID, bLogin)

        Timer.DelTimer(self, self.nCheckScenePakTimerID)

        self.nPendingMapID = nMapID
        self.nCheckScenePakTimerID = Timer.AddFrame(self.tGlobalTimer, 1, function()
            local moduleEnterGame = LoginMgr.GetModule(LoginModule.LOGIN_ENTERGAME)
            local tEnterGameRoleInfo = moduleEnterGame.GetEnterGameRoleInfo()
            local dwForceID = self.dwClientPlayerForceID or (tEnterGameRoleInfo and tEnterGameRoleInfo.dwForceID)
            local tCorePackIDList = self.NeedDownloadCorePack(nMapID, dwForceID) and self.GetCorePackIDList() or {}
            local tCoreStateInfo = self.GetStateInfoByPackIDList(tCorePackIDList)
            local dwCoreLeftDownloadSize = tCoreStateInfo.dwTotalSize - tCoreStateInfo.dwDownloadedSize

            local _, dwTotalSize, dwDownloadedSize = self.GetMapResPackState(nMapID)
            local dwMapLeftDownloadSize = dwTotalSize - dwDownloadedSize

            if dwCoreLeftDownloadSize > 0 then
                SceneMgr.HideSwitcher()

                local szContent
                if dwMapLeftDownloadSize > 0 then
                    --szContent = "前往其他场景需要下载核心资源和地图资源，是否前往并返回角色选择界面进行下载？取消则回到之前的场景位置"
                    szContent = "前往其他场景需要下载核心资源和地图资源，需要返回角色选择界面进行下载"
                else
                    --szContent = "前往其他场景需要下载核心资源，是否前往并返回角色选择界面进行下载？取消则回到之前的场景位置"
                    szContent = "前往其他场景需要下载核心资源，需要返回角色选择界面进行下载"
                end

                local dialog = UIHelper.ShowSystemConfirm(szContent, function()
                    --把核心包和地图加到下载队列
                    local tCorePackIDList = self.GetCorePackIDList()
                    local tPackIDList = tCorePackIDList
                    local nMapPackID = self.GetMapResPackID(nMapID)
                    if not table.contain_value(tPackIDList, nMapPackID) then
                        table.insert(tPackIDList, nMapPackID)
                    end
                    for i = #tPackIDList, 1, -1 do
                        local nPackID = tPackIDList[i]
                        self.CreatePausedTask(nPackID, true)
                    end

                    self.tReloginPackIDList = tPackIDList

                    Global.BackToLogin(true)
                end, function()
                    --TODO 返回场景
                end)
                --dialog:SetButtonContent("Confirm", "角色选择")
                --dialog:SetButtonContent("Cancel", "返回场景")
                dialog:HideCancelButton()

                return
            end

            if not self._IsMapResValid(nMapID) or dwMapLeftDownloadSize <= 0 then
                self.nDownloadSceneResMapID = nil
                Log("[PakDownloadMgr] CheckScenePakComplete", bLogin, self.nPendingMapID, nMapID)

                if self.nPendingMapID == nMapID then
                    self.nPendingMapID = 0
                    CheckScenePakComplete(bLogin)
                end
            else
                --处理客户端连续调了两次CHECK_SCENE_PAK的情况
                if self.nDownloadSceneResMapID == nMapID then
                    Log("[PakDownloadMgr] self.nDownloadSceneResMapID == nMapID", nMapID)
                    return
                end

                SceneMgr.HideSwitcher()

                local tPausePackIDList = {}
                local function fnOnAllPaused()
                    local function fnResume()
                        --若客户端调了两次CHECK_SCENE_PAK且地图ID不同，只留最新的
                        if self.nDownloadSceneResMapID ~= nMapID then
                            return
                        end

                        self.nDownloadSceneResMapID = nil
                        for _, nPackID in ipairs(tPausePackIDList or {}) do
                            self.ResumePack(nPackID)
                        end
                        Log("[PakDownloadMgr] CheckScenePakComplete", bLogin, self.nPendingMapID, nMapID)

                        if self.nPendingMapID == nMapID then
                            self.nPendingMapID = 0
                            CheckScenePakComplete(bLogin)
                        end
                    end

                    if self.CheckLoginToDefaultMap(nMapID) then
                        moduleEnterGame.SetRoleLoginRealMap(nMapID)
                    end

                    local nPackID = self.GetMapResPackID(nMapID)
                    local nNetMode = App_GetNetMode()
                    if nNetMode == NET_MODE.WIFI or self.GetAllowNotWifiDownload() then
                        self.nDownloadSceneResMapID = nMapID
                        self.DownloadPack(nPackID, fnResume)
                    elseif nNetMode == NET_MODE.CELLULAR then
                        local szMapName = UIHelper.GBKToUTF8(Table_GetMapName(nMapID)) or ""
                        if not string.is_nil(szMapName) then
                            szMapName = "[" .. szMapName .. "]"
                        end
                        local szMapLeftDownloadSize = self.FormatSize(dwMapLeftDownloadSize)
                        local szContent = "当前处于移动网络，是否使用流量下载" .. szMapLeftDownloadSize .. "的" .. szMapName .. "地图资源文件？"
                        local dialog = UIHelper.ShowSystemConfirm(szContent, function()
                            self.nDownloadSceneResMapID = nMapID
                            self.DownloadPack(nPackID, fnResume)
                        end, function()
                            for _, nPackID in ipairs(tPausePackIDList or {}) do
                                self.ResumePack(nPackID)
                            end
                            Global.BackToLogin(true)
                        end)
                        dialog:SetButtonContent("Confirm", "继续下载")
                        dialog:SetButtonContent("Cancel", g_tStrings.STR_CANCEL)
                    else
                        --无网络
                    end
                end

                --下载前先把所有其他正在下载的资源包暂停，下载完成后再继续
                tPausePackIDList = self.PauseAllPack(fnOnAllPaused)
            end
        end)
    end)

    Event.Reg(self, EventType.PakDownload_OnStart, function(nPackID, nTotalFile, dwTotalSize)
        Log("[PakDownloadMgr] PakDownload_OnStart", nPackID, nTotalFile, dwTotalSize)
        self._SetDownloadingState(nPackID, DOWNLOAD_STATE.DOWNLOADING)
        local tDownloadInfo = self.GetDownloadingInfo(nPackID)
        if tDownloadInfo then
            tDownloadInfo.bStartFlag = true
            -- tDownloadInfo.nTotalFile = nTotalFile
            -- tDownloadInfo.dwTotalSize = dwTotalSize
            if tDownloadInfo.bPauseFlag then
                tDownloadInfo.bPauseFlag = false
                self._FlushTaskTable(nPackID)
                self.PausePack(nPackID, tDownloadInfo.fnOnPaused)
            end
        end

        self._OnDownloadStart()
    end)
    Event.Reg(self, EventType.PakDownload_OnPause, function(nPackID, bSuccess)
        Log("[PakDownloadMgr] PakDownload_OnPause", nPackID, bSuccess)
        if bSuccess then
            self._SetDownloadingState(nPackID, DOWNLOAD_STATE.PAUSE)
            local tDownloadInfo = self.GetDownloadingInfo(nPackID)
            if tDownloadInfo then
                tDownloadInfo.bPausingFlag = false
                tDownloadInfo.dwDownloadSpeed = 0
                if tDownloadInfo.fnOnPaused then
                    tDownloadInfo.fnOnPaused()
                    tDownloadInfo.fnOnPaused = nil
                end
                if tDownloadInfo.bResumeFlag then
                    tDownloadInfo.bResumeFlag = false
                    self.ResumePack(nPackID)
                end
            end
            if not self.bBatchPause then
                self._UpdateDownloadQueue()
            end
        else
            --暂停失败
        end
    end)
    Event.Reg(self, EventType.PakDownload_OnProgress, function(nPackID, dwDownloadSpeed, nDownloadedFile, dwDownloadedSize)
        --LogDebug("[PakDownloadMgr] PakDownload_OnProgress", nPackID, dwDownloadSpeed, nDownloadedFile, dwDownloadedSize)
        self._SetDownloadingState(nPackID, DOWNLOAD_STATE.DOWNLOADING)
        local tDownloadInfo = self.GetDownloadingInfo(nPackID)
        if tDownloadInfo then
            --若重试成功，则自动关闭错误弹窗
            if tDownloadInfo.bRetryFlag and dwDownloadedSize > tDownloadInfo.dwDownloadedSize then
                Log("[PakDownloadMgr] Clear RetryFlag", dwDownloadSpeed, dwDownloadedSize, tDownloadInfo.dwDownloadedSize)
                tDownloadInfo.bRetryFlag = false
                if self.downloadFailedDialog then
                    UIMgr.Close(self.downloadFailedDialog)
                    self.downloadFailedDialog = nil
                end
            end

            --流量统计
            if self.tStatistics then
                if not self.tStatistics[nPackID] then
                    self.tStatistics[nPackID] = 0
                end
                if dwDownloadedSize < tDownloadInfo.dwTotalSize then
                    self.tStatistics[nPackID] = self.tStatistics[nPackID] + (dwDownloadedSize - tDownloadInfo.dwDownloadedSize)
                end
            end

            tDownloadInfo.nDownloadedFile = nDownloadedFile
            tDownloadInfo.dwDownloadSpeed = dwDownloadSpeed
            tDownloadInfo.dwDownloadedSize = dwDownloadedSize
        end
        self._OnDownloadStart()
    end)
    Event.Reg(self, EventType.PakDownload_OnComplete, function(nPackID, nResult)
        Log("[PakDownloadMgr] PakDownload_OnComplete", nPackID, GetEnumStr(DOWNLOAD_OBJECT_RESULT, nResult))
        self._ClearRetryTimer(nPackID)
        local tDownloadInfo = self.GetDownloadingInfo(nPackID)
        if tDownloadInfo then
            tDownloadInfo.dwDownloadSpeed = 0
            tDownloadInfo.bStartFlag = false
            tDownloadInfo.nResult = nResult

            if nResult == DOWNLOAD_OBJECT_RESULT.SUCCESS then
                --因为要显示整体进度，所以下载完成后不立即将tDownloadInfo删除
                self._SetDownloadingState(nPackID, DOWNLOAD_STATE.COMPLETE)
                tDownloadInfo.dwDownloadSpeed = 0

                --若暂停时已完成，则将暂停事件也执行一下
                if tDownloadInfo.fnOnPaused then
                    tDownloadInfo.fnOnPaused()
                    tDownloadInfo.fnOnPaused = nil
                end
                if tDownloadInfo.fnOnComplete then
                    tDownloadInfo.fnOnComplete()
                end

                --关闭错误弹窗
                if tDownloadInfo.bRetryFlag then
                    tDownloadInfo.bRetryFlag = false
                    if self.downloadFailedDialog then
                        UIMgr.Close(self.downloadFailedDialog)
                        self.downloadFailedDialog = nil
                    end
                end

                self._CheckBasicDownloadEnd()

                --流量统计打印
                if self.tStatistics then
                    self.LogStatistics(nPackID)
                end

                -- 检查刷新场景所有模型
                self._CheckDynamicPakDownloadComplete(nPackID)
            else
                self._SetDownloadingState(nPackID, DOWNLOAD_STATE.FAILED, nResult == DOWNLOAD_OBJECT_RESULT.NET_ERROR) --网络错误时在等待队列中置顶自身

                if tDownloadInfo.fnOnPaused then
                    tDownloadInfo.fnOnPaused()
                    tDownloadInfo.fnOnPaused = nil
                end

                if nResult ~= DOWNLOAD_OBJECT_RESULT.DELETED_INTERRUPT and nResult ~= DOWNLOAD_OBJECT_RESULT.CANCEL_INTERRUPT then
                    --2023.9.21 后台自动重试下载，弹窗仅作为提醒
                    tDownloadInfo.bRetryFlag = true
                    if nResult == DOWNLOAD_OBJECT_RESULT.NET_ERROR then
                        self._ClearRetryTimer(self.nNetErrorRetryPackID)
                        self.nNetErrorRetryPackID = nPackID
                        self.tRetryTimerID[nPackID] = Timer.Add(self, AUTO_RETRY_DELAY, function()
                            self._ClearRetryTimer(nPackID)
                            self._SetDownloadingState(nPackID, DOWNLOAD_STATE.QUEUE)
                            self._UpdateDownloadQueue()
                        end)
                    else
                        self.tRetryTimerID[nPackID] = Timer.Add(self, AUTO_RETRY_DELAY, function()
                            self._ClearRetryTimer(nPackID)
                            self.DownloadPack(nPackID)
                        end)
                    end

                    --仅在过图Loading界面弹窗+防止弹窗重复出现
                    local szError = g_tStrings.tDownloadFailedResult[nResult]
                    if szError and self.nDownloadSceneResMapID and not self.downloadFailedDialog then
                        local szContent = string.format("资源下载失败：%s （错误码：%d）", szError, nResult)
                        self.downloadFailedDialog = UIHelper.ShowSystemConfirm(szContent,
                        function()
                            self.downloadFailedDialog = nil
                        end)

                        self.downloadFailedDialog:HideButton("Cancel")
                        --TODO 返回登录按钮？
                    end
                    Log("[PakDownloadMgr] Download Failed", szError)
                end
            end
        end
        if nResult ~= DOWNLOAD_OBJECT_RESULT.NET_ERROR then
            --2024.12.6 当因为网络问题下载失败时，不自动开始下一个，避免出现频繁轮刷的异常表现情况
            self._CheckCurDownloadAllComplete(nResult == DOWNLOAD_OBJECT_RESULT.SUCCESS)
        end
        self._UpdateMultiIntanceState()
    end)
    Event.Reg(self, EventType.PakDownload_OnDelete, function(nPackID, bSuccess)
        Log("[PakDownloadMgr] PakDownload_OnDelete", nPackID, bSuccess)
        if bSuccess then
            self.tDownloadingList[nPackID] = nil
            self.tTopMostPackIDList[nPackID] = nil
            self._FlushTaskTable(nPackID)
            self._CheckCurDownloadAllComplete()
            Log("[PakDownloadMgr] PakDownload_OnStateUpdate (Delete)", nPackID)
            Event.Dispatch(EventType.PakDownload_OnStateUpdate, nPackID)
        else
            TipsHelper.ShowNormalTip("文件删除失败")
        end

        self._UpdateMultiIntanceState()

        self.tDeletingPack[nPackID] = nil
        if table.is_empty(self.tDeletingPack) then
            Log("[PakDownloadMgr] PakDownload_UnlockModify")
            PakDownload_UnlockModify()
        end
    end)
    Event.Reg(self, EventType.PakDownload_OnCancel, function(nPackID, bSuccess)
        Log("[PakDownloadMgr] PakDownload_OnCancel", nPackID, bSuccess)
        if bSuccess then
            local tDownloadInfo = self.GetDownloadingInfo(nPackID)
            local tTask, _ = self.GetTask(nPackID)
            local nTriggerType = tTask and tTask.nTriggerType --记录触发类型

            self.tDownloadingList[nPackID] = nil
            self._FlushTaskTable(nPackID)
            self._CheckCurDownloadAllComplete()
            Log("[PakDownloadMgr] PakDownload_OnStateUpdate (Cancel)", nPackID)
            Event.Dispatch(EventType.PakDownload_OnStateUpdate, nPackID)

            --若bCancelFlag被移除，则表示等待取消期间，调用过下载，则这里重新调一次
            if tDownloadInfo and not tDownloadInfo.bCancelFlag then
                self.DownloadPack(nPackID, tDownloadInfo.fnOnComplete)
                tTask, _ = self.GetTask(nPackID)
                if tTask then
                    tTask.nTriggerType = nTriggerType --还原触发类型
                end
            end
        else
            --TipsHelper.ShowNormalTip("下载任务取消失败")
        end
    end)
    Event.Reg(self, EventType.PakDownload_OnStateUpdate, function(nPackID)
        self.nCanGetTotalInfoTime = nil --状态改变 允许总信息更新
    end)
    Event.Reg(self, "OnNetModeChanged", function(nNetMode)
        Log("[PakDownloadMgr] OnNetModeChanged", GetEnumStr(NET_MODE, self.nNetMode), GetEnumStr(NET_MODE, nNetMode), GetEnumStr(NET_MODE, App_GetNetMode()))
        self._UpdateNetMode()
    end)
    Event.Reg(self, EventType.OnAppPreQuit, function()
        Log("[PakDownloadMgr] OnAppPreQuit XGSDK_ManageBackgroundMode false")
        XGSDK_ManageBackgroundMode(false, AppReviewMgr.IsReview())
    end)
    Event.Reg(self, "UI_LUA_RESET", function()
        self.downloadFailedDialog = nil
        self.netPauseDialog = nil
        self.fnPauseDialog = nil
        self.tNetPausePackIDList = nil
    end)

    Event.Reg(self, EventType.OnApplicationDidEnterBackground, function()
        self.bInBackgroundMode = true
    end)

    Event.Reg(self, EventType.OnApplicationWillEnterForeground, function()
        self.bInBackgroundMode = false
        local fnPauseDialog = self.fnPauseDialog
        self.fnPauseDialog = nil
        if fnPauseDialog then
            fnPauseDialog()
        end
    end)
end

function PakDownloadMgr._InitPackConfig()
    self.tPakInfoList = {}

    local function _parseCatogoryConfig(szFileName, bHide)
        local szPath = "PakV5Filelist/" .. szFileName
        if not Lib.IsFileExist(szPath) then
            LOG.ERROR("[PakDownloadMgr] File does not exist. %s", szPath)
            return
        end

        local szJson = UIHelper.GBKToUTF8(Lib.GetStringFromFile(szPath))
        local tData = JsonDecode(szJson)

        local tCatogoryList = tData and tData.CatogoryList
        if not tCatogoryList then
            LOG.ERROR("[PakDownloadMgr] Json Parse Error. %s", szPath)
            return
        end

        -- local nVersion = tData.FormatVersion
        -- if nVersion ~= 1 then
        --     return
        -- end

        for szPackID, tLine in pairs(tCatogoryList) do
            local tInfo = {}
            tInfo.nPackID = tonumber(szPackID)

            -- --若在端游PakGroup配置表中存在该ID则使用表里的名字作为名称
            -- local tPakLine = g_tTable.PakGroup and g_tTable.PakGroup:Search(tInfo.nPackID)
            -- local szDisplayName = tPakLine and tPakLine.szDisplayName
            -- if szDisplayName and szDisplayName ~= "" then
            --     tInfo.szName = UIHelper.GBKToUTF8(szDisplayName)
            -- else
            --     tInfo.szName = tLine.CatogoryName or ""
            -- end

            -- 2024.2.6 使用配置表中地图的名称作为名称
            local szMapName = nil
            local bIsMapRes, nMapID = self.IsMapRes(tInfo.nPackID)
            if bIsMapRes then
                szMapName = UIHelper.GBKToUTF8(Table_GetMapName(nMapID))
            end

            tInfo.szName = szMapName or tLine.CatogoryName or ""

            --描述现在是生成的，和名字一样就当作默认不显示
            tInfo.szDownloadDesc = tLine.CatogoryName ~= tLine.DownloadDescription and tLine.DownloadDescription or ""
            tInfo.szDeleteDesc = tLine.CatogoryName ~= tLine.DeleteDescription and tLine.DeleteDescription or ""
            tInfo.szUpdateDesc = tLine.CatogoryName ~= tLine.UpdateDescription and tLine.UpdateDescription or ""
            tInfo.bIsBasic = tLine.IsBasic
            tInfo.bIsCore = tLine.IsCore
            tInfo.bHide = bHide

            local tPakList = {}
            for _, tSubCatogory in ipairs(tLine.SubCatogoryList or {}) do
                for _, nPakGroupID in ipairs(tSubCatogory.PakList or {}) do
                    if not table.contain_value(tPakList, nPakGroupID) then
                        table.insert(tPakList, nPakGroupID)
                    end
                end
            end
            tInfo.tPakList = tPakList

            self.tPakInfoList[tInfo.nPackID] = tInfo
        end
    end

    _parseCatogoryConfig("Easy.json")
    _parseCatogoryConfig("AutoMapDLC.json")
    _parseCatogoryConfig("OtherAutoMapDLC.json", true)

    --print_table_utf8(self.tPakInfoList)
end

--读取优先下载资源配置，用于登录游戏场景后自动开始下载
function PakDownloadMgr._InitPriorityPackConfig()
    self.tPriorityConfigList = {}
    self.tDefaultConfigList = {}
    self.tCoreConfigList = {}

    local szPath = "PakV5Filelist/Priority.json"
    if not Lib.IsFileExist(szPath) then
        LOG.ERROR("[PakDownloadMgr] File does not exist. %s", szPath)
        return
    end

    local szJson = Lib.GetStringFromFile(szPath)
    local tData = JsonDecode(szJson)

    local function _insert(tList, szKey, nPackID)
        szKey = string.gsub(szKey, " ", "") --去除空格
        if not tList[szKey] then
            tList[szKey] = {}
        end
        if not table.contain_value(tList[szKey], nPackID) then
            table.insert(tList[szKey], nPackID)
        end
    end

    local function _parseConfig(tList, szSection)
        local tConfigList = tData and tData[szSection]
        if not tConfigList then
            LOG.ERROR("[PakDownloadMgr] Json Parse Error. %s", szPath)
            return
        end
        for szKey, tLine in pairs(tConfigList) do
            for _, nID in ipairs(tLine) do
                if g_tTable.PackTree and g_tTable.PackTree:Search(nID) then
                    local tPackIDList = self.GetPackIDListInPackTree(nID)
                    for _, nPackID in ipairs(tPackIDList) do
                        _insert(tList, szKey, nPackID)
                    end
                elseif self.GetPackInfo(nID) or nID < 0 then
                    --作为nPackID
                    _insert(tList, szKey, nID)
                end
            end
        end
        --print_table(szSection, tList)
    end

    _parseConfig(self.tPriorityConfigList, "PriorityList")
    _parseConfig(self.tDefaultConfigList, "DefaultList")

    --核心包
    local tCoreList = tData and tData.CoreList
    if not tCoreList then
        return
    end

    for _, nID in ipairs(tCoreList) do
        if g_tTable.PackTree and g_tTable.PackTree:Search(nID) then
            local tPackIDList = self.GetPackIDListInPackTree(nID)
            for _, nPackID in ipairs(tPackIDList) do
                if not table.contain_value(self.tCoreConfigList, nPackID) then
                    table.insert(self.tCoreConfigList, nPackID)
                end
            end
        elseif self.GetPackInfo(nID) or nID < 0 then
            --作为nPackID
            if not table.contain_value(self.tCoreConfigList, nID) then
                table.insert(self.tCoreConfigList, nID)
            end
        end
    end
end

--[[
    tInfo = {
        szName = ...,
        szDesc = ...,
        nLevel = ...,
        tChildList = {

        },
    }
--]]
function PakDownloadMgr._InitPackTreeConfig()
    self.tPackTree = {}

    -- 1.读取PackTree.tab中的配置

    local function _getLineInfo(tLine, nLevel)
        if not tLine then
            return
        end
        nLevel = nLevel or 1

        local tInfo = clone(tLine)
        tInfo.szName = UIHelper.GBKToUTF8(tInfo.szName)
        tInfo.szDesc = UIHelper.GBKToUTF8(tInfo.szDesc)
        tInfo.nLevel = nLevel

        local tChildList = {}
        local tChildIDList = self.GetChildIDListInPackTree(tInfo.nID)
        for i = 1, #tChildIDList do
            local tChildLine = g_tTable.PackTree and g_tTable.PackTree:Search(tChildIDList[i])
            if tChildLine then
                local tChildInfo = _getLineInfo(tChildLine, nLevel + 1)
                table.insert(tChildList, tChildInfo)
            end
        end
        tInfo.tChildList = tChildList
        return tInfo
    end

    if g_tTable.PackTree then
        local nCount = g_tTable.PackTree:GetRowCount()
        for i = 2, nCount do
            local tLine = g_tTable.PackTree:GetRow(i)
            if tLine.nType > 0 then
                local tInfo = _getLineInfo(tLine, 1)
                table.insert(self.tPackTree, tInfo)
            end
        end
    else
        LOG.ERROR("[PakDownloadMgr] Table does not exist. g_tTable.PackTree")
    end

    -- 2.从端游Detail.json读取与地图相关的资源目录结构配置

    local szPath = "PakV4Manager/Detail.json"
    if not Lib.IsFileExist(szPath) then
        LOG.ERROR("[PakDownloadMgr] File does not exist. %s", szPath)
        return
    end

    local szJson = UIHelper.GBKToUTF8(Lib.GetStringFromFile(szPath))
    local tData = JsonDecode(szJson)

    local tCatogoryList = tData and tData.CatogoryList
    if not tCatogoryList then
        LOG.ERROR("[PakDownloadMgr] Json Parse Error. %s", szPath)
        return
    end

    for _, tLine in ipairs(tCatogoryList) do
        if tLine.CatogoryName == "世界场景" or tLine.CatogoryName == "秘境场景" then
            local tInfo = {}
            tInfo.szName = tLine.CatogoryName
            tInfo.szDesc = tLine.Description
            tInfo.nLevel = 1
            tInfo.nType = 1
            local bRecommend = tLine.SubCatogoryList and #tLine.SubCatogoryList > 0
            local tChildList = {}
            for _, tSubCatogory in ipairs(tLine.SubCatogoryList or {}) do
                local tSubInfo = {}
                tSubInfo.szName = tSubCatogory.SubCatogoryName
                tSubInfo.nLevel = 2
                local bSubRecommend = tSubCatogory.PakList and #tSubCatogory.PakList > 0
                local tSubChildList = {}
                for _, nPakGroupID in ipairs(tSubCatogory.PakList or {}) do
                    local tPackInfo = {}
                    -- local tPakLine = g_tTable.PakGroup and g_tTable.PakGroup:Search(nPakGroupID)
                    -- tPackInfo.szName = tPakLine and UIHelper.GBKToUTF8(tPakLine.szDisplayName) or ""
                    local tPakInfo = self.GetPackInfo(nPakGroupID)
                    tPackInfo.szName = tPakInfo and tPakInfo.szName or ""

                    tPackInfo.nLevel = 3
                    tPackInfo.nPackID = nPakGroupID --按规则将目前用的nPackID与以前端游用的nPakGroupID保持一致

                    local tLine = g_tTable.PackTree and g_tTable.PackTree:Search(nPakGroupID)
                    if tLine then
                        tPackInfo.bRecommend = tLine.bRecommend
                    end
                    if not tPackInfo.bRecommend then
                        bSubRecommend = false
                    end

                    table.insert(tSubChildList, tPackInfo)
                end

                if not bSubRecommend then
                    bRecommend = false
                end

                tSubInfo.bRecommend = bSubRecommend
                tSubInfo.tChildList = tSubChildList
                table.insert(tChildList, tSubInfo)
            end

            tInfo.bRecommend = bRecommend
            tInfo.tChildList = tChildList
            table.insert(self.tPackTree, tInfo)
        end
    end

    --调整排序
    local function _setOrderByCondition(fnCondition, nOrder)
        local nIndex, tInfo
        for k, v in pairs(self.tPackTree) do
            if fnCondition(v) then
                nIndex, tInfo = k, v
                break
            end
        end
        if nIndex then
            table.remove(self.tPackTree, nIndex)
            table.insert(self.tPackTree, nOrder, tInfo)
            nOrder = nOrder + 1
        end
        return nOrder
    end

    local nNextOrder = 1
    nNextOrder = _setOrderByCondition(function(tInfo) return tInfo.nType == 3 end, nNextOrder)
    nNextOrder = _setOrderByCondition(function(tInfo) return tInfo.nType == 2 end, nNextOrder)
    nNextOrder = _setOrderByCondition(function(tInfo) return tInfo.szName == "世界场景" end, nNextOrder)
    nNextOrder = _setOrderByCondition(function(tInfo) return tInfo.szName == "秘境场景" end, nNextOrder)

    --print_table_utf8(self.tPackTree)
end

function PakDownloadMgr._InitExtensionPackIDList()
    self.tExtensionPackIDList = {}
    local tExtensionPackIDMap = {} --用于去重，避免table.contain_value耗性能太大

    local function _insertValidPackID(tInfo)
        if not tInfo then
            return
        end

        local nPackID = tInfo.nPackID
        if nPackID and nPackID > 0 then
            --不存在或在白名单之外，排除
            if not self.GetPackInfo(nPackID) or not self.IsPackInWhiteList(nPackID) then
                return
            end
        else
            nPackID = nil
        end

        if nPackID and not tExtensionPackIDMap[nPackID] then
            table.insert(self.tExtensionPackIDList, nPackID)
            tExtensionPackIDMap[nPackID] = true

            self.GetPackState(nPackID) --手动触发一次GetPackState，使PakV5那边可以提前初始化，避免打开资源管理界面时卡顿
        end

        if tInfo.tChildList then
            for _, tChild in ipairs(tInfo.tChildList) do
                _insertValidPackID(tChild)
            end
        end
    end

    for nIndex, tInfo in ipairs(self.tPackTree or {}) do
        _insertValidPackID(tInfo)
    end
end

function PakDownloadMgr.IsEnabled()
    if m_bEnabled ~= nil then
        return m_bEnabled
    end

    if PakDownload_IsEnableDlc then
        m_bEnabled = PakDownload_IsEnableDlc()
    else
        local ini = Ini.Open("configHttpFile.ini", true)
        m_bEnabled = ini:ReadInteger("sys", "dlc", 0) == 1 and ini:ReadInteger("enable", "enableHttp", 0) == 1 and ini:ReadInteger("enable", "enablePakV5", 1) == 1
    end
    return m_bEnabled
end

function PakDownloadMgr.IsDebug()
    if m_bDebug ~= nil then
        return m_bDebug
    end

    if PakDownload_IsEnableDebugLog then
        m_bDebug = PakDownload_IsEnableDebugLog()
    else
        local ini = Ini.Open("configHttpFile.ini", true)
        m_bDebug = ini:ReadInteger("sys", "debug", 0) == 1
    end
    return m_bDebug
end

function PakDownloadMgr.GetPackTree()
    return self.tPackTree
end

function PakDownloadMgr.GetExtensionPackIDList()
    return self.tExtensionPackIDList
end

function PakDownloadMgr.IsAllExtensionPackStart()
    for _, nPackID in pairs(self.tExtensionPackIDList or {}) do
        local nState, dwTotalSize, dwDownloadedSize = self.GetPackState(nPackID)
        if nState == DOWNLOAD_OBJECT_STATE.NOTEXIST or nState == DOWNLOAD_OBJECT_STATE.PAUSE then
            local tDownloadInfo = self.GetDownloadingInfo(nPackID)
            if not tDownloadInfo or tDownloadInfo.nState == DOWNLOAD_STATE.NONE or tDownloadInfo.nState == DOWNLOAD_STATE.PAUSE then
                return false
            end
        end
    end
    return true
end

function PakDownloadMgr.IsAllExtensionPackDownloaded()
    for _, nPackID in pairs(self.tExtensionPackIDList or {}) do
        local nState, dwTotalSize, dwDownloadedSize = self.GetPackState(nPackID)
        if nState ~= DOWNLOAD_OBJECT_STATE.DOWNLOADED then
            return false
        end
    end
    return true
end

--规则：本地存在任一推荐下载以外的资源，且该资源不在忽略列表中
function PakDownloadMgr.CheckCanDeleteOldVersionRes()
    local tIgnoreMap = {}
    local tRecommendPackIDMap = {}
    local tPackTree = self.GetPackTree()
    for _, tInfo in ipairs(tPackTree or {}) do
        if tInfo.nType == 3 then --nType=3表示推荐资源
            local tPackIDList = self.GetPackIDListInPackTree(tInfo.nID)
            for _, nPackID in pairs(tPackIDList or {}) do
                tRecommendPackIDMap[nPackID] = true

                --取tPakList里的ID，用于处理副本等同资源多ID情况
                local bIsMapRes, nMapID = self.IsMapRes(nPackID)
                if bIsMapRes then
                    local nMapPackID = self.GetMapResPackID(nMapID)
                    tRecommendPackIDMap[nMapPackID] = true
                end
            end
        end
    end

    --基础包+门派地图+各体型视频
    local tBasicInfo = self._GetBasicPack()
    if tBasicInfo then
        tIgnoreMap[tBasicInfo.nPackID] = true
        for _, nPakGroupID in pairs(tBasicInfo.tPakList or {}) do
            if self.IsMapRes(nPakGroupID) then
                tIgnoreMap[nPakGroupID] = true
            end
        end
    end

    for _, tForceMapID in pairs(ForceIDToMapID) do
        tForceMapID = IsTable(tForceMapID) and tForceMapID or {tForceMapID}
        for _, nMapID in pairs(tForceMapID) do
            local nPackID = self.GetMapResPackID(nMapID)
            tIgnoreMap[nPackID] = true
        end
    end

    for _, nPackID in pairs(RoleTypeToPackID) do
        tIgnoreMap[nPackID] = true
    end

    for _, nPackID in pairs(self.tExtensionPackIDList or {}) do
        if not tRecommendPackIDMap[nPackID] and not tIgnoreMap[nPackID] then
            local nState, dwTotalSize, dwDownloadedSize = self.GetPackState(nPackID)
            if nState ~= DOWNLOAD_OBJECT_STATE.NOTEXIST then
                Log("[PakDownloadMgr] CheckCanDeleteOldVersionRes", nPackID)
                return true
            end
        end
    end

    return false
end

function PakDownloadMgr.GetPackIDListInPackTree(nPackTreeID)
    if self.tPackIDListMap[nPackTreeID] then
        return clone(self.tPackIDListMap[nPackTreeID])
    end

    local tPackIDList = {}
    local tPackIDMap = {} --用于去重，避免table.contain_value耗性能太大

    local function _insertLinePackID(nPackTreeID)
        local tLine = nPackTreeID and g_tTable.PackTree and g_tTable.PackTree:Search(nPackTreeID)
        if not tLine then
            return
        end

        local nPackID = tLine.nPackID
        if nPackID and nPackID > 0 and not tPackIDMap[nPackID] and self.IsPackInWhiteList(nPackID) then
            table.insert(tPackIDList, nPackID)
            tPackIDMap[nPackID] = true
        end

        local tChildIDList = self.GetChildIDListInPackTree(nPackTreeID)
        for i = 1, #tChildIDList do
            _insertLinePackID(tChildIDList[i])
        end
    end

    _insertLinePackID(nPackTreeID)
    self.tPackIDListMap[nPackTreeID] = tPackIDList --缓存

    return tPackIDList
end

function PakDownloadMgr.GetChildIDListInPackTree(nPackTreeID)
    local tIDList = {}

    local tLine = nPackTreeID and g_tTable.PackTree and g_tTable.PackTree:Search(nPackTreeID)
    if tLine then
        local tChildIDList = string.split(tLine.szChildList, ";")
        for i = 1, #tChildIDList do
            local nChildID = tonumber(tChildIDList[i])
            if nChildID then
                table.insert(tIDList, nChildID)
            end
        end
    end

    return tIDList
end

function PakDownloadMgr._PushBubbleMsg()
    local fnGetTitle = function()
        local tTotalInfo = self.GetTotalDownloadInfo()
        local szContent = "下载中(" .. tTotalInfo.nCompleteTask .. "/" .. tTotalInfo.nTotalTask .. ")" --已完成/总数
        return szContent, 0.1
    end

    local fnGetContent = function()
        local tTotalInfo = self.GetTotalDownloadInfo()
        local nTotalState = tTotalInfo.nTotalState
        local szContent = ""
        if nTotalState == TOTAL_DOWNLOAD_STATE.DOWNLOADING then
            szContent = "当前:" .. self.FormatSize(tTotalInfo.dwCurDownloadedSize) .. "/" .. self.FormatSize(tTotalInfo.dwCurTotalSize) .. "\n"
            szContent = szContent .. "速率:" .. self.FormatSize(tTotalInfo.dwCurDownloadSpeed, 2) .. "/s(查看详情)"
        elseif nTotalState == TOTAL_DOWNLOAD_STATE.PAUSING then
            szContent = "下载暂停中(查看详情)"
        elseif nTotalState == TOTAL_DOWNLOAD_STATE.RETRYING then
            szContent = "下载重试中(查看详情)"
        end
        return szContent, 0.1
    end

    local fnAction = function()
        --UIMgr.Open(VIEW_ID.PanelGameSettings, 6, 999) --跳转到设置界面-资源管理-正在下载（999表示跳转到最后一个次级导航）
        UIMgr.Open(VIEW_ID.PanelResourcesDownload, RESOURCES_PAGE.DOWNLOADING, 1) --跳转到资源管理界面-正在下载-主要
    end

    self.bPushBubbleMsg = true
    BubbleMsgData.PushMsgWithType("PakDownloadTips", {
        szTitle = fnGetTitle,       -- 显示在信息列表项中的标题, 支持回调函数(返回相应文本, 下次调用间隔)
        szBarTitle = fnGetTitle,    -- 显示在小地图旁边的气泡栏的短标题(若与szTitle一样, 可以不填)
        nBarTime = 0,               -- 显示在气泡栏的时长, 单位为秒
        szContent = fnGetContent,   -- 支持富文本, 支持回调函数(返回相应文本, 下次调用间隔)
        szAction = fnAction,        -- 点击后执行的动作(打开界面的ViewID名称|参数1|参数2), 支持回调函数
    })
end

function PakDownloadMgr._CheckShowDownloadBall()
    if Storage.Download.bShowDownloadBall and not UIMgr.IsViewOpened(VIEW_ID.PanelDownloadBall, true) then
        UIMgr.Open(VIEW_ID.PanelDownloadBall)
    end
end

function PakDownloadMgr._OnDownloadStart()
    if self.bDownloading then
        -- if not self.bPushBubbleMsg then
        --     self._PushBubbleMsg()
        -- end
        self._CheckShowDownloadBall()
        return
    end

    --后台保活
    self._SetManageBackgroundMode(true)

    self._SetTimerEnabled(true)
    -- self._PushBubbleMsg()
    self._CheckShowDownloadBall()

    self.bDownloading = true
    Log("[PakDownloadMgr] Download Start!")
    Event.Dispatch(EventType.PakDownload_OnDownloadStart)
end

function PakDownloadMgr._OnDownloadEnd(bCompleteEnd)
    if not self.bDownloading then
        return
    end

    --后台保活
    self._SetManageBackgroundMode(false)

    self._SetTimerEnabled(false)
    -- BubbleMsgData.RemoveMsg("PakDownloadTips")
    -- self.bPushBubbleMsg = false
    -- UIMgr.Close(VIEW_ID.PanelDownloadBall) --由资源下载悬浮球界面本身控制延迟关闭

    self.bDownloading = false
    Log("[PakDownloadMgr] Download End!")
    Event.Dispatch(EventType.PakDownload_OnDownloadEnd, bCompleteEnd or false)
end

function PakDownloadMgr._CheckBasicDownloadEnd()
    --判断基础包是否下载完成
    if self.tBasicTaskList and #self.tBasicTaskList <= 0 then
        if self.fnBasicOnComplete then
            self.fnBasicOnComplete()
        end
        Event.Dispatch(EventType.PakDownload_OnBasicComplete)
        self._RefreshBasicPackState()

        --基础包下载完成时，触发核心队列下载
        self.DownloadCoreList()

        self.tBasicTaskList = nil
        self.fnBasicOnComplete = nil
    end
end

function PakDownloadMgr._SetManageBackgroundMode(bActive)
    self.bManageBackgroundMode = bActive

    local nTime = GetTickCount()
    if nTime - self.nManageBackgroundModeTime > 1000 then
        self._UpdateManageBackgroundMode()
    end
end

--限制固定时间更新保活状态
function PakDownloadMgr._UpdateManageBackgroundMode(bForce)
    if self.bInBackgroundMode then
        return
    end

    if self.bManageBackgroundMode ~= self.bCurManageBackgroundMode or bForce then
        self.bCurManageBackgroundMode = self.bManageBackgroundMode
        self.nManageBackgroundModeTime = GetTickCount()

        Log("[PakDownloadMgr] XGSDK_ManageBackgroundMode", self.bManageBackgroundMode, AppReviewMgr.IsReview())
        XGSDK_ManageBackgroundMode(self.bManageBackgroundMode, AppReviewMgr.IsReview())

        if self.bManageBackgroundMode then
            self._UpdateBackgroundNotice()
        end
    end
end

--通知栏消息
function PakDownloadMgr._UpdateBackgroundNotice()
    --只有后台保活开启才有效，后台保活关闭后通知栏消息也会被移除
    if not self.bCurManageBackgroundMode then
        return
    end

    if not Platform.IsAndroid() then
        return
    end

    local tTotalInfo = self.GetTotalDownloadInfo(true)
    if tTotalInfo.nTotalTask > 0 then
        local szSpeed = self.FormatSize(tTotalInfo.dwCurDownloadSpeed, 2) .. "/s"
        local szSize = self.FormatSize(tTotalInfo.dwCurDownloadedSize) .. " / " .. self.FormatSize(tTotalInfo.dwCurTotalSize)
        local nProgress = tTotalInfo.nCurProgress

        local szContent
        if tTotalInfo.nCompleteTask == tTotalInfo.nTotalTask then
            szContent = "下载完成"
        elseif tTotalInfo.nTotalState == TOTAL_DOWNLOAD_STATE.RETRYING then
            szContent = "下载失败，重试中"
        else
            szContent = szSpeed .. " (" .. szSize .. ")"
        end

        if tTotalInfo.nTotalTask > 1 then
            szContent = szContent .. ", " .. tTotalInfo.nCompleteTask .. "/" .. tTotalInfo.nTotalTask
        end

        --Log("[PakDownloadMgr] XGSDK_UpdateBackgroundNotification", szContent, nProgress)
        XGSDK_UpdateBackgroundNotification("下载资源中...", szContent, nProgress)
    end
end

-------------------------------- Pack --------------------------------

function PakDownloadMgr.GetPakInfoList()
    return self.tPakInfoList
end

function PakDownloadMgr.GetPackInfo(nPackID)
    return self.tPakInfoList and self.tPakInfoList[nPackID] or self.tDynamicPakInfoList[nPackID]
end

function PakDownloadMgr.GetPackState(nPackID)
    -- BeginSample("PakDownloadMgr.GetPackState." .. nPackID)
    local nState, dwTotalSize, dwDownloadedSize, nTotalFile, nDownloadedFile = PakDownload_GetPackState(nPackID)
    -- EndSample()
    -- Log("[PakDownloadMgr] GetPackState", nPackID, GetEnumStr(DOWNLOAD_OBJECT_STATE, nState), dwTotalSize, dwDownloadedSize, nTotalFile, nDownloadedFile)
    if DEBUG_DOWNLOADED_PACK[nPackID] then
        nState = DOWNLOAD_OBJECT_STATE.DOWNLOADED
        dwDownloadedSize = dwTotalSize
        nDownloadedFile = nTotalFile
    end
    if dwDownloadedSize >= dwTotalSize then
        nState = DOWNLOAD_OBJECT_STATE.DOWNLOADED
    end
    return nState or DOWNLOAD_OBJECT_STATE.NOTEXIST, dwTotalSize or 0, dwDownloadedSize or 0, nTotalFile or 0, nDownloadedFile or 0
end

function PakDownloadMgr.DownloadPack(nPackID, fnOnComplete)
    if not self.IsPackInWhiteList(nPackID, true) then
        return
    end

    --若已在下载，则返回
    local tDownloadInfo = self.GetDownloadingInfo(nPackID)
    local bRetryFlag = false
    if tDownloadInfo then
        fnOnComplete = fnOnComplete or tDownloadInfo.fnOnComplete
        tDownloadInfo.fnOnComplete = fnOnComplete
        --若暂停则继续
        if tDownloadInfo.bPauseFlag or tDownloadInfo.nState == DOWNLOAD_STATE.PAUSE then
            Log("[PakDownloadMgr] DownloadPack (FromPause)", nPackID)
            tDownloadInfo.bPauseFlag = false
            self._FlushTaskTable(nPackID)
            self.ResumePack(nPackID)
            return
        elseif tDownloadInfo.bCancelFlag then
            Log("[PakDownloadMgr] DownloadPack (FromCancel)", nPackID)
            tDownloadInfo.bCancelFlag = false
            self._FlushTaskTable(nPackID)
            return
        elseif tDownloadInfo.nState == DOWNLOAD_STATE.FAILED then
            bRetryFlag = true
        else
            return
        end
    end

    local tPakInfo = self.GetPackInfo(nPackID)
    if not tPakInfo then
        return
    end

    --已下载
    local nState, dwTotalSize, dwDownloadedSize = self.GetPackState(nPackID)
    if nState == DOWNLOAD_OBJECT_STATE.DOWNLOADED then
        Log("[PakDownloadMgr] Downloading Pack is already Downloaded", nPackID, GetEnumStr(DOWNLOAD_OBJECT_STATE, nState), dwTotalSize, dwDownloadedSize)
        return
    end

    if not self.CanDownloadPack(nPackID) then
        return
    end

    --检测磁盘空间检测
    if not self._HasEnoughSpace(nPackID) then
        if tDownloadInfo then
            tDownloadInfo.nResult = DOWNLOAD_OBJECT_RESULT.NO_SPACE_FAIL
        end
        local szError = g_tStrings.tDownloadFailedResult[DOWNLOAD_OBJECT_RESULT.NO_SPACE_FAIL]
        TipsHelper.ShowNormalTip("资源下载失败：" .. szError)
        return
    end

    local nResult = tDownloadInfo and tDownloadInfo.nResult

    --新增下载信息并设置为排队状态
    Log("[PakDownloadMgr] DownloadPack (Queue)", nPackID)
    tDownloadInfo = self._CreateDownloadingInfo(nPackID)
    tDownloadInfo.fnOnComplete = fnOnComplete
    tDownloadInfo.bRetryFlag = bRetryFlag
    tDownloadInfo.nResult = nResult

    self._SetDownloadingState(nPackID, DOWNLOAD_STATE.QUEUE)
    Event.Dispatch(EventType.PakDownload_OnQueue, nPackID)
    self._UpdateDownloadQueue()
end

function PakDownloadMgr.DownloadPackImmediately(nPackID, fnOnComplete)
    local tDownloadInfo = self.GetDownloadingInfo(nPackID)
    if not self._HasEnoughSpace(nPackID) then
        if tDownloadInfo then
            tDownloadInfo.nResult = DOWNLOAD_OBJECT_RESULT.NO_SPACE_FAIL
        end
        local szError = g_tStrings.tDownloadFailedResult[DOWNLOAD_OBJECT_RESULT.NO_SPACE_FAIL]
        TipsHelper.ShowNormalTip("资源下载失败：" .. szError)
        return
    end

    --若Pack未下载，则开始下载
    if not tDownloadInfo or tDownloadInfo.nState == DOWNLOAD_STATE.FAILED then
        self.DownloadPack(nPackID, fnOnComplete)
        tDownloadInfo = self.GetDownloadingInfo(nPackID)
        if not tDownloadInfo then
            return
        end
    elseif fnOnComplete then
        tDownloadInfo.fnOnComplete = fnOnComplete
    end

    if tDownloadInfo.nState == DOWNLOAD_STATE.PAUSE then
        self.ResumePack(nPackID)
    end

    --已完成/已在下载/继续下载失败（磁盘空间不足） 返回
    if tDownloadInfo.nState == DOWNLOAD_STATE.COMPLETE or tDownloadInfo.nState == DOWNLOAD_STATE.DOWNLOADING or tDownloadInfo.nState == DOWNLOAD_STATE.PAUSE then
        return
    end

    --置顶到等待队列最上层
    local tTask, nIndex = self.GetTask(nPackID)
    local tTaskTable = Storage.Download.tbTaskTable
    self._SetDownloadingState(nPackID, DOWNLOAD_STATE.QUEUE, true)

    --若超出最大同时下载数量，则将最后一个正在下载的先暂停后继续放入等待队列
    local nCount = self._GetDownloadingCount()
    if MAX_DOWNLOAD_COUNT and MAX_DOWNLOAD_COUNT > 0 and nCount >= MAX_DOWNLOAD_COUNT and tTask.nState == DOWNLOAD_STATE.QUEUE then
        local tLastDownloadingTask = tTaskTable[DOWNLOAD_STATE.DOWNLOADING][#tTaskTable[DOWNLOAD_STATE.DOWNLOADING]]
        local nLastDownloadingPackID = tLastDownloadingTask and tLastDownloadingTask.nPackID
        if nLastDownloadingPackID and nLastDownloadingPackID ~= nPackID then
            self.PausePack(nLastDownloadingPackID, function()
                self._UpdateDownloadQueue()
                self.ResumePack(nLastDownloadingPackID)

                --优先/默认/核心队列保证暂停后在等待队列中的顺序
                local tPauseTask, _ = self.GetTask(nLastDownloadingPackID)
                if tPauseTask.nTriggerType then
                    self._SetDownloadingState(nLastDownloadingPackID, DOWNLOAD_STATE.QUEUE, true)
                end
            end)
        end
    end
    self._UpdateDownloadQueue()
end

function PakDownloadMgr.DownloadPackListImmediately(tPackIDList, fnOnComplete)
    local tIDList = {}
    for _, nPackID in ipairs(tPackIDList) do
        local nState, _, _ = self.GetPackState(nPackID)
        if nState ~= DOWNLOAD_OBJECT_STATE.DOWNLOADED then
            table.insert(tIDList, nPackID)
        end
    end

    local bAllPriorityPackComplete = self.IsAllPriorityPackComplete()
    local bAllBasicPackComplete = self.IsAllBasicPackComplete()

    --立即下载第一项，并且将剩余插入到队首
    for i = #tIDList, 1, -1 do
        local nPackID = tIDList[i]
        if i == 1 and bAllPriorityPackComplete and bAllBasicPackComplete then
            self.DownloadPackImmediately(nPackID, fnOnComplete)
        else
            self.DownloadPack(nPackID, fnOnComplete)
            --置顶到Queue最顶层
            local tDownloadInfo = self.GetDownloadingInfo(nPackID)
            if tDownloadInfo and tDownloadInfo.nState == DOWNLOAD_STATE.QUEUE then
                self._SetDownloadingState(nPackID, DOWNLOAD_STATE.QUEUE, true)
            end
        end
    end
end

function PakDownloadMgr.DownloadPackTopMost(nPackID)
    self.tTopMostPackIDList[nPackID] = true
    self.PauseBasicPack()
    self.DownloadPackImmediately(nPackID)
end

function PakDownloadMgr.PausePack(nPackID, fnOnPaused)
    self._ClearRetryTimer(nPackID)
    local tDownloadInfo = self.GetDownloadingInfo(nPackID)
    if not tDownloadInfo then
        return
    end

    --只有下载中或排队中才可以点暂停
    if tDownloadInfo.nState ~= DOWNLOAD_STATE.DOWNLOADING and tDownloadInfo.nState ~= DOWNLOAD_STATE.QUEUE and tDownloadInfo.nState ~= DOWNLOAD_STATE.FAILED then
        return
    end

    tDownloadInfo.bResumeFlag = false
    tDownloadInfo.bRetryFlag = false
    tDownloadInfo.fnOnPaused = fnOnPaused
    if tDownloadInfo.nState == DOWNLOAD_STATE.QUEUE or tDownloadInfo.nState == DOWNLOAD_STATE.FAILED then
        --若排队中，则直接变为暂停状态
        Log("[PakDownloadMgr] PausePack (FromQueue)", nPackID)
        Event.Dispatch(EventType.PakDownload_OnPause, nPackID, true)
        return
    elseif not tDownloadInfo.bStartFlag then
        --若还未开始，则先记录，等待开始后再暂停
        Log("[PakDownloadMgr] PausePack (WaitStart)", nPackID)
        tDownloadInfo.bPauseFlag = true
        self._FlushTaskTable(nPackID)
        return
    end

    tDownloadInfo.bPausingFlag = true

    Log("[PakDownloadMgr] PausePack", nPackID)
    local bResult = PakDownload_PausePack(nPackID)
end

function PakDownloadMgr.CreatePausedTask(nPackID, bTop)
    local tDownloadInfo = self.GetDownloadingInfo(nPackID) or self._CreateDownloadingInfo(nPackID)
    tDownloadInfo.bCancelFlag = false

    if tDownloadInfo.nState == DOWNLOAD_STATE.DOWNLOADING then
        self.PausePack(nPackID)
    else
        self._SetDownloadingState(nPackID, DOWNLOAD_STATE.PAUSE, true)
        self._FlushTaskTable(nPackID)
    end
end

function PakDownloadMgr.PausePackInPackIDList(tPackIDList, fnOnAllPaused)
    if not tPackIDList then
        return
    end

    --由于下载中的资源暂停会有延迟，为了保证暂停后顺序一致，这里先等前一项暂停完后再暂停后续
    local nIndex = 1
    self.bBatchPause = true
    local function _pauseNext()
        if tPackIDList[nIndex] then
            local nPackID = tPackIDList[nIndex]
            nIndex = nIndex + 1
            local tDownloadInfo = self.GetDownloadingInfo(nPackID)
            if tDownloadInfo and (tDownloadInfo.nState == DOWNLOAD_STATE.QUEUE or tDownloadInfo.nState == DOWNLOAD_STATE.DOWNLOADING or tDownloadInfo.nState == DOWNLOAD_STATE.FAILED) then
                if tDownloadInfo.nState == DOWNLOAD_STATE.DOWNLOADING then
                    self.PausePack(nPackID, _pauseNext)
                else
                    self.PausePack(nPackID) --排队时暂停是同步的，如果将_pauseNext作为回调，当一次性暂停很多任务时，调用栈会爆
                    _pauseNext()
                end
            else
                _pauseNext()
            end
        else
            self.bBatchPause = false
            self._UpdateDownloadQueue()
            if fnOnAllPaused then
                fnOnAllPaused()
            end
        end
    end
    _pauseNext()
end

function PakDownloadMgr.PauseAllPack(fnOnAllPaused)
    local tPackIDList = {}
    local bAllQueue = true
    for _, tTask in pairs(Storage.Download.tbTaskTable[DOWNLOAD_STATE.DOWNLOADING]) do
        bAllQueue = false
        table.insert(tPackIDList, tTask.nPackID)
    end
    for _, tTask in pairs(Storage.Download.tbTaskTable[DOWNLOAD_STATE.QUEUE]) do
        table.insert(tPackIDList, tTask.nPackID)
    end
    if bAllQueue then
        --延迟1帧，避免tPackIDList未返回就执行回调
        Timer.AddFrame(self.tGlobalTimer, 1, function()
            self.PausePackInPackIDList(tPackIDList, fnOnAllPaused)
        end)
    else
        self.PausePackInPackIDList(tPackIDList, fnOnAllPaused)
    end
    return tPackIDList
end

function PakDownloadMgr.ResumePack(nPackID)
    local tDownloadInfo = self.GetDownloadingInfo(nPackID)
    if not tDownloadInfo or tDownloadInfo.nState == DOWNLOAD_STATE.FAILED then
        --若对未开始下载的扩展包执行“继续下载”，则会开始下载
        self.DownloadPack(nPackID)
        return
    end

    --检测磁盘空间检测
    if not self._HasEnoughSpace(nPackID) then
        if tDownloadInfo then
            tDownloadInfo.nResult = DOWNLOAD_OBJECT_RESULT.NO_SPACE_FAIL
        end
        local szError = g_tStrings.tDownloadFailedResult[DOWNLOAD_OBJECT_RESULT.NO_SPACE_FAIL]
        TipsHelper.ShowNormalTip("资源下载失败：" .. szError)
        return
    end

    local fnOnPaused = tDownloadInfo.fnOnPaused
    tDownloadInfo.fnOnPaused = nil
    if not tDownloadInfo.bStartFlag and (tDownloadInfo.nState == DOWNLOAD_STATE.DOWNLOADING or tDownloadInfo.nState == DOWNLOAD_STATE.QUEUE) then
        --若继续时还未开始，将OnPause执行一下，避免执行不到
        if fnOnPaused then
            fnOnPaused()
        end
        Log("[PakDownloadMgr] ResumePack (WaitStart)", nPackID)
        tDownloadInfo.bPauseFlag = false
        self._FlushTaskTable(nPackID)
    end

    --只有暂停中或排队中才可以点继续
    if tDownloadInfo.nState ~= DOWNLOAD_STATE.PAUSE and tDownloadInfo.nState ~= DOWNLOAD_STATE.QUEUE then
        if tDownloadInfo.bPausingFlag then
            tDownloadInfo.bResumeFlag = true
        end
        return
    end

    --设置为排队状态
    Log("[PakDownloadMgr] ResumePack (Queue)", nPackID)
    self._SetDownloadingState(nPackID, DOWNLOAD_STATE.QUEUE)
    Event.Dispatch(EventType.PakDownload_OnQueue, nPackID)
    self._UpdateDownloadQueue()
end

function PakDownloadMgr.ResumeAllPack()
    --按任务顺序继续下载
    local tPackIDList = {}
    for _, tTask in pairs(Storage.Download.tbTaskTable[DOWNLOAD_STATE.PAUSE]) do
        table.insert(tPackIDList, tTask.nPackID)
    end
    for _, nPackID in ipairs(tPackIDList) do
        self.ResumePack(nPackID)
    end
    return tPackIDList
end

function PakDownloadMgr.DeletePack(nPackID)
    self.DeletePackInPackIDList({nPackID})
end

function PakDownloadMgr.DeletePackInPackIDList(tPackIDList)
    if not tPackIDList or #tPackIDList <= 0 then
        return
    end

    local bMultiInstance = PakDownload_HasMultiInstance()
    if bMultiInstance then
        return
    end

    Log("[PakDownloadMgr] LockModify")
    local bRet = PakDownload_LockModify()
    if not bRet then
        Log("[PakDownloadMgr] LockModify Failed")
        return
    end

    for _, nPackID in ipairs(tPackIDList) do
        if not self.tDeletingPack[nPackID] then
            self.tDeletingPack[nPackID] = true
            self._ClearRetryTimer(nPackID)

            Log("[PakDownloadMgr] DeletePack", nPackID)
            local bResult = PakDownload_DeletePack(nPackID)

            if not bResult then
                self.tDeletingPack[nPackID] = nil
            end
        end
    end

    if table.is_empty(self.tDeletingPack) then
        Log("[PakDownloadMgr] UnlockModify")
        PakDownload_UnlockModify()
    end
end

--取消下载：移除任务
function PakDownloadMgr.CancelPack(nPackID, bClear)
    self._ClearRetryTimer(nPackID)

    -- 2024.9.11 策划需求 手动移除核心队列中的下载内容后，就当做已下载过
    -- 2024.11.26 默认队列也加进去
    local tTask, _ = self.GetTask(nPackID)
    if not bClear and tTask and (tTask.nTriggerType == TASK_TRIGGER_TYPE.CORE or tTask.nTriggerType == TASK_TRIGGER_TYPE.DEFAULT) then
        if tTask.nTriggerType == TASK_TRIGGER_TYPE.CORE then
            Storage.CoreDownload.tbCore[nPackID] = true
            Storage.CoreDownload.Flush()
        elseif tTask.nTriggerType == TASK_TRIGGER_TYPE.DEFAULT then
            Storage.PriorityDownload.tbDefault[nPackID] = true
            Storage.PriorityDownload.Flush()
        end
        Storage.AutoDownload.tbPackIDMap[nPackID] = true
        Storage.AutoDownload.Flush()
    end

    local tDownloadInfo = self.GetDownloadingInfo(nPackID)
    if not tDownloadInfo or tDownloadInfo.nState == DOWNLOAD_STATE.COMPLETE then
        self.tDownloadingList[nPackID] = nil
        self.tTopMostPackIDList[nPackID] = nil
        if tTask then
            self._FlushTaskTable(nPackID)
            Log("[PakDownloadMgr] PakDownload_OnStateUpdate (Clear)", nPackID)
            Event.Dispatch(EventType.PakDownload_OnStateUpdate, nPackID)
        end
        return
    end

    Log("[PakDownloadMgr] CancelPack", nPackID)
    tDownloadInfo.bCancelFlag = true
    self._FlushTaskTable(nPackID)
    if tDownloadInfo.nState ~= DOWNLOAD_STATE.DOWNLOADING and not tDownloadInfo.bStartFlag then
        Event.Dispatch(EventType.PakDownload_OnCancel, nPackID, true)
        return
    end

    local bResult = PakDownload_CancelPack(nPackID)
end

function PakDownloadMgr.CancelAllPack()
    Log("[PakDownloadMgr] CancelAllPack")
    for nPackID, _ in pairs(self.tDownloadingList) do
        --排除优先包/基础包/核心包
        local bBasic = self.IsBasicPack(nPackID) or self.IsMapInBasicPack(nPackID)
        local bCore = self.IsCorePack(nPackID)
        local bPriorityState = self.IsPriorityPack(nPackID) and not Storage.PriorityDownload.tbPriority[nPackID]
        if not bBasic and not bCore and not bPriorityState then
            self.CancelPack(nPackID)
        end
    end
end

function PakDownloadMgr.RefreshPackState(nPackID, fnOnComplete)
    LogDebug("[PakDownloadMgr] TryRefreshPackState (QuerySize)", nPackID)
    PakSizeQueryMgr.RegQuerySize(self, nPackID, function(bSuccess, dwTotalSize, dwDownloadedSize)
        if bSuccess then
            local nState, _, _ = self.GetPackState(nPackID)
            if dwDownloadedSize >= dwTotalSize and nState ~= DOWNLOAD_OBJECT_STATE.DOWNLOADED then
                Log("[PakDownloadMgr] RefreshPackState", nPackID)
                local tDownloadInfo = self.GetDownloadingInfo(nPackID)
                if tDownloadInfo and tDownloadInfo.bStartFlag then
                    if tDownloadInfo.nState == DOWNLOAD_STATE.PAUSE then
                        PakDownload_ResumePack(nPackID)
                    end
                else
                    PakDownload_DownloadPack(nPackID)
                end
            end
        end

        if fnOnComplete then
            fnOnComplete()
        end
    end)
end

function PakDownloadMgr.RefreshPackListState(tPackIDList, fnOnComplete)
    local nQueryCount = 0
    for _, nPackID in ipairs(tPackIDList) do
        nQueryCount = nQueryCount + 1
        self.RefreshPackState(nPackID, function()
            nQueryCount = nQueryCount - 1
            if nQueryCount <= 0 then
                if fnOnComplete then
                    fnOnComplete()
                end
            end
        end)
    end
end

function PakDownloadMgr.RefreshAllExtensionPackState()
    local tExtensionPackIDList = self.GetExtensionPackIDList()
    local nTime = GetTickCount()

    self.RefreshPackListState(tExtensionPackIDList, function()
        Log("[PakDownloadMgr] RefreshPackListState Complete, Use Time (ms): ", GetTickCount() - nTime)
    end)
end

function PakDownloadMgr._UpdateDownloadQueue(bRetry)
    local nCount = self._GetDownloadingCount()
    local bHasPausedPriority = false
    local tDownloadFailedList = {}

    local nBasicState, _, _ = self.GetBasicPackState()
    local tBasicPackIDList = self.GetBasicPackIDList()

    local bBreak = false
    local function _moveNext(nPackID)
        if bBreak then
            return
        end

        if MAX_DOWNLOAD_COUNT and MAX_DOWNLOAD_COUNT > 0 and nCount >= MAX_DOWNLOAD_COUNT then
            bBreak = true
            return
        end

        --当不在Loading界面下载地图且当前包不为最高优先下载时
        if not self.nDownloadSceneResMapID and not self.tTopMostPackIDList[nPackID] then
            --基础包下载完成后才可以下载普通包
            if nBasicState ~= DOWNLOAD_OBJECT_STATE.DOWNLOADED and not table.contain_value(tBasicPackIDList, nPackID) then
                bBreak = true
                return
            end

            --全部优先下载都已开始后才可以下载普通包
            if not self.IsPriorityPack(nPackID) and bHasPausedPriority then
                bBreak = true
                return
            end
        end

        local tDownloadInfo = self.GetDownloadingInfo(nPackID)
        if tDownloadInfo and tDownloadInfo.nState == DOWNLOAD_STATE.QUEUE then
            --空间不足下载失败，自动重试
            if not self._HasEnoughSpace(nPackID) then
                Log("[PakDownloadMgr] Download Failed, Retrying", nPackID)
                tDownloadInfo.bRetryFlag = true
                tDownloadInfo.nResult = DOWNLOAD_OBJECT_RESULT.NO_SPACE_FAIL
                if not self.tRetryTimerID[nPackID] and not bRetry then
                    local szError = g_tStrings.tDownloadFailedResult[DOWNLOAD_OBJECT_RESULT.NO_SPACE_FAIL]
                    TipsHelper.ShowNormalTip("资源下载失败：" .. szError)
                end
                --5s后自动重试
                self._ClearRetryTimer(nPackID)
                self.tRetryTimerID[nPackID] = Timer.Add(self, AUTO_RETRY_DELAY, function()
                    self._ClearRetryTimer(nPackID)
                    self._UpdateDownloadQueue(true)
                end)
                bBreak = true
                return
            end

            if not tDownloadInfo.bStartFlag then
                --若还未开始下载，则开始下载
                Log("[PakDownloadMgr] DownloadPack", nPackID)
                local bResult = PakDownload_DownloadPack(nPackID)
                if bResult then
                    nCount = nCount + 1
                    self._SetDownloadingState(nPackID, DOWNLOAD_STATE.DOWNLOADING)
                else
                    table.insert(tDownloadFailedList, nPackID)
                end
            else
                --若已开始下载，则继续下载
                Log("[PakDownloadMgr] ResumePack", nPackID)
                local bResult = PakDownload_ResumePack(nPackID)
                if bResult then
                    nCount = nCount + 1
                    self._SetDownloadingState(nPackID, DOWNLOAD_STATE.DOWNLOADING)
                end
            end
        end
    end

    --基础包
    if nBasicState ~= DOWNLOAD_OBJECT_STATE.DOWNLOADED then
        for _, nPackID in ipairs(tBasicPackIDList) do
            if bBreak then
                break
            end
            _moveNext(nPackID)
        end
    end

    --优先下载只能按顺序下载，若中间的暂停了则后面的也不能下
    for _, nPackID in ipairs(self.tPriorityList or {}) do
        if bBreak then
            break
        end
        local tTask, _ = self.GetTask(nPackID)
        if tTask and tTask.nTriggerType == TASK_TRIGGER_TYPE.PRIORITY then
            if tTask.nState == DOWNLOAD_STATE.QUEUE then
                _moveNext(nPackID)
            elseif tTask.nState == DOWNLOAD_STATE.PAUSE then
                bHasPausedPriority = true
                break
            end
        end
    end

    local nMapPackID = self.nDownloadSceneResMapID and self.GetMapResPackID(self.nDownloadSceneResMapID)
    for _, tTask in ipairs(Storage.Download.tbTaskTable[DOWNLOAD_STATE.QUEUE]) do
        if bBreak then
            break
        end
        if nMapPackID == tTask.nPackID or tTask.nTriggerType ~= TASK_TRIGGER_TYPE.PRIORITY then
            _moveNext(tTask.nPackID)
        end
    end

    --清理下载失败
    for _, nPackID in ipairs(tDownloadFailedList) do
        self.tDownloadingList[nPackID] = nil
        self.tTopMostPackIDList[nPackID] = nil
        self._FlushTaskTable(nPackID)
    end
    if #tDownloadFailedList > 0 then
        self._CheckCurDownloadAllComplete()
    end
end

function PakDownloadMgr._ClearRetryTimer(nPackID)
    if not nPackID then
        return
    end

    Timer.DelTimer(self, self.tRetryTimerID[nPackID])
    self.tRetryTimerID[nPackID] = nil
    if self.nNetErrorRetryPackID == nPackID then
        self.nNetErrorRetryPackID = nil
    end
end

-------------------------------- BasicPack --------------------------------

function PakDownloadMgr._GetBasicPack(bForce)
    if not ENABLED_BASIC_DOWNLOAD and not bForce then
        return nil
    end

    for _, tInfo in pairs(self.tPakInfoList) do
        if tInfo.bIsBasic then
            return tInfo
        end
    end
end

function PakDownloadMgr.GetBasicPackIDList()
    if self.tBasicPackIDList then
        --目前_GetRoleInfoPackIDList为固定列表，无动态ID，所以可以用缓存
        return clone(self.tBasicPackIDList)
    end

    self.tBasicPackIDList = {}

    local tBasicInfo = self._GetBasicPack()
    if tBasicInfo and tBasicInfo.nPackID then
        table.insert(self.tBasicPackIDList, tBasicInfo.nPackID)
    end

    local tRoleInfoPackIDList = self._GetRoleInfoPackIDList()
    for _, nPackID in ipairs(tRoleInfoPackIDList or {}) do
        --基础包里的可以跳过
        if not tBasicInfo or not table.contain_value(tBasicInfo.tPakList, nPackID) then
            table.insert(self.tBasicPackIDList, nPackID)
        end
    end

    return clone(self.tBasicPackIDList)
end

function PakDownloadMgr.GetBasicPackState(bLog)
    local nState = DOWNLOAD_OBJECT_STATE.NOTEXIST
    local dwTotalSize = 0
    local dwDownloadedSize = 0

    local tBasicInfo = self._GetBasicPack()
    if tBasicInfo and tBasicInfo.nPackID then
        nState, dwTotalSize, dwDownloadedSize = self.GetPackState(tBasicInfo.nPackID)
    end
    if bLog then
        Log("[PakDownloadMgr] GetBasicPackState, Basic: " .. dwDownloadedSize .. "/" .. dwTotalSize)
    end

    local tPackIDList = self._GetRoleInfoPackIDList()
    for _, nPackID in ipairs(tPackIDList or {}) do
        --基础包里的可以跳过
        if not tBasicInfo or not table.contain_value(tBasicInfo.tPakList, nPackID) then
            local nCurState, dwCurTotalSize, dwCurDownloadedSize = self.GetPackState(nPackID)
            if bLog then
                Log("[PakDownloadMgr] GetBasicPackState, RoleInfoPack: " .. nPackID .. ", " .. dwCurDownloadedSize .. "/" .. dwCurTotalSize)
            end
            dwTotalSize = dwTotalSize + dwCurTotalSize
            dwDownloadedSize = dwDownloadedSize + dwCurDownloadedSize
        end
    end

    if dwDownloadedSize == dwTotalSize then
        nState = DOWNLOAD_OBJECT_STATE.DOWNLOADED
    elseif dwDownloadedSize == 0 then
        nState = DOWNLOAD_OBJECT_STATE.NOTEXIST
    elseif self.tBasicTaskList and nState ~= DOWNLOAD_OBJECT_STATE.PAUSE then
        nState = DOWNLOAD_OBJECT_STATE.DOWNLOADING
    else
        nState = DOWNLOAD_OBJECT_STATE.PAUSE
    end

    return nState, dwTotalSize, dwDownloadedSize
end

function PakDownloadMgr.DownloadBasicPack(fnOnComplete)
    if self.IsBasicDownloading() then
        if self.IsBasicPause() then
            self.ResumeBasicPack()
        end
        return
    end

    self.tBasicTaskList = self.tBasicTaskList or {}
    self.fnBasicOnComplete = fnOnComplete

    local function _insert(nPackID)
        if not table.contain_value(self.tBasicTaskList, nPackID) then
            table.insert(self.tBasicTaskList, nPackID)
        end
    end

    local function _remove(nPackID)
        if self.tBasicTaskList then
            table.remove_value(self.tBasicTaskList, nPackID)
        end
    end

    local bDownload = false
    local tPackIDList = self.GetBasicPackIDList()
    for _, v in ipairs(tPackIDList or {}) do
        local nPackID = v
        local nState, _, _ = self.GetPackState(nPackID)
        if nState ~= DOWNLOAD_OBJECT_STATE.DOWNLOADED then
            if self._HasEnoughSpace(nPackID) then
                bDownload = true
            end
            _insert(nPackID)
            self.DownloadPack(nPackID, function() _remove(nPackID) end)
        end
    end

    if bDownload then
        Event.Dispatch(EventType.PakDownload_OnBasicStart)
    end
end

function PakDownloadMgr.PauseBasicPack()
    if not self.IsBasicDownloading() then
        return
    end

    self.PausePackInPackIDList(self.tBasicTaskList)
end

function PakDownloadMgr.ResumeBasicPack()
    if not self.IsBasicDownloading() then
        return
    end

    for _, nPackID in ipairs(self.tBasicTaskList or {}) do
        self.ResumePack(nPackID)
    end
end

function PakDownloadMgr.CancelBasicPack()
    for _, nPackID in ipairs(self.tBasicTaskList or {}) do
        self.CancelPack(nPackID)
    end

    self.tBasicTaskList = nil
    self.fnBasicOnComplete = nil
end

function PakDownloadMgr.IsBasicDownloading()
    return self.tBasicTaskList and #self.tBasicTaskList > 0
end

function PakDownloadMgr.IsAllBasicPackComplete()
    local nBasicState, _, _ = self.GetBasicPackState()
    return nBasicState == DOWNLOAD_OBJECT_STATE.DOWNLOADED
end

function PakDownloadMgr.IsInBasicIDList(nPackID)
    local tBasicPackIDList = self.GetBasicPackIDList()
    return table.contain_value(tBasicPackIDList, nPackID)
end

function PakDownloadMgr.IsBasicPause()
    if not self.IsBasicDownloading() then
        return false
    end
    local bBasicPause = true
    for _, nPackID in ipairs(self.tBasicTaskList) do
        local nState, _, _ = self.GetPackState(nPackID)
        if nState == DOWNLOAD_OBJECT_STATE.DOWNLOADING then
            bBasicPause = false
            break
        end
    end
    return bBasicPause
end

function PakDownloadMgr._RefreshBasicPackState()
    Log("[PakDownloadMgr] RefreshBasicPackState")
    local tBasicInfo = self._GetBasicPack(true)
    if tBasicInfo and tBasicInfo.tPakList then
        for _, nPakGroupID in pairs(tBasicInfo.tPakList) do
            if self.IsMapRes(nPakGroupID) then
                self.RefreshPackState(nPakGroupID)
            end
        end
    end
end

function PakDownloadMgr.IsBasicPack(nPackID)
    if not ENABLED_BASIC_DOWNLOAD then
        return false
    end

    local tPakInfo = self.GetPackInfo(nPackID)
    return tPakInfo and tPakInfo.bIsBasic
end

function PakDownloadMgr.IsMapInBasicPack(nPackID)
    if not self.IsMapRes(nPackID) then
        return false
    end

    local tBasicInfo = self._GetBasicPack(true)
    if tBasicInfo and tBasicInfo.tPakList then
        return table.contain_value(tBasicInfo.tPakList, nPackID)
    end
    return false
end

-------------------------------- CorePack --------------------------------

-- self.tCorePackIDList: Easy.json中标记为IsCore的核心资源，一定要下载完成才可进入
-- self.tCoreConfigList: Priority.json中配置的CoreList核心下载队列
-- self.tCoreList: 考虑了账号门派/体型后经过转换得到的实际核心下载的nPackID列表

function PakDownloadMgr.GetCorePackIDList()
    if self.tCorePackIDList then
        return clone(self.tCorePackIDList)
    end

    self.tCorePackIDList = {}
    for nPackID, tInfo in pairs(self.tPakInfoList) do
        if tInfo.bIsCore then
            table.insert(self.tCorePackIDList, nPackID)
        end
    end
    return clone(self.tCorePackIDList)
end

function PakDownloadMgr.IsCorePack(nPackID)
    local tCorePackIDList = self.GetCorePackIDList()
    local bCore, nIndex = table.contain_value(tCorePackIDList or {}, nPackID)
    return bCore, nIndex
end

function PakDownloadMgr.NeedDownloadCorePack(nMapID, dwForceID)
    if not self.IsEnabled() or not ENABLED_CORE_DOWNLOAD then
        return false
    end

    if not dwForceID then
        local player = GetClientPlayer()
        if not player then
            return false
        end

        dwForceID = player.dwForceID
    end

    --历程场景除外
    local tSkipMapID = { 653, 579 } --稻香村、百溪
    if table.contain_value(tSkipMapID, nMapID) then
        return false
    end

    --自己的门派场景除外
    local tForceMapID = ForceIDToMapID[dwForceID]
    tForceMapID = IsTable(tForceMapID) and tForceMapID or {tForceMapID}
    if table.contain_value(tForceMapID, nMapID) then
        return false
    end

    -- --基础包中的场景除外
    -- local nPackID = self.GetMapResPackID(nMapID)
    -- if self.IsMapInBasicPack(nPackID) then
    --     return false
    -- end

    return true
end

-------------------------------- Map Res --------------------------------

function PakDownloadMgr._IsMapResValid(nMapID)
    if not nMapID then
        return false
    end

    local nPackID = self.GetMapResPackID(nMapID)
    local tInfo = nPackID and self.GetPackInfo(nPackID)
    if not tInfo then
        if self.IsEnabled() then
            --LOG.WARN("Can't find MapID %d in Config", tostring(nMapID))
        end
        return false
    end

    return true
end

function PakDownloadMgr.GetMapResPackState(nMapID)
    if not self._IsMapResValid(nMapID) then
        return DOWNLOAD_OBJECT_STATE.NOTEXIST, 0, 0
    end

    local nPackID = self.GetMapResPackID(nMapID)
    local nState, dwTotalSize, dwDownloadedSize, nTotalFile, nDownloadedFile = self.GetPackState(nPackID)
    --Log("[PakDownloadMgr] GetMapResPackState", nMapID, GetEnumStr(DOWNLOAD_OBJECT_STATE, nState), dwTotalSize, dwDownloadedSize, nTotalFile, nDownloadedFile)
    return nState, dwTotalSize, dwDownloadedSize, nTotalFile, nDownloadedFile
end

function PakDownloadMgr.GetMapResPackID(nMapID)
    local nPackID = 800000 + nMapID --端游规则如此，保持一致

    --2024.3.8 PakV5需求，下载同资源的不同dlc时，取PakList中的ID作为dlcid
    local tInfo = self.GetPackInfo(nPackID)
    if tInfo and tInfo.tPakList and tInfo.tPakList[1] and tInfo.tPakList[1] ~= nPackID then
        nPackID = tInfo.tPakList[1]
    end

    return nPackID
end

function PakDownloadMgr.IsMapRes(nPackID)
    local bIsMapRes = nPackID > 800000 and nPackID < 809999
    local nMapID = bIsMapRes and (nPackID - 800000)
    return bIsMapRes, nMapID
end

--获取缺失地图资源的地图ID列表
function PakDownloadMgr.GetLackMapPakMapIDList()
    local tResult = {}
    local tAllMapIDs = Table_GetAllMapIDs()
    for _, nMapID in ipairs(tAllMapIDs) do
        local nPackID = self.GetMapResPackID(nMapID)
        local nState, dwTotalSize, dwDownloadedSize = self.GetPackState(nPackID)
        if nState ~= DOWNLOAD_OBJECT_STATE.DOWNLOADED or not self.IsPackInWhiteList(nPackID) then
            table.insert(tResult, nMapID)
        end
    end

    return tResult
end

--获取登录角色所在地图对应的nPackID
function PakDownloadMgr._GetRoleInfoPackIDList()
    local tMapIDList = {}
    local tPackIDList = {}

    --地图ID
    local nRoleCount = Login_GetRoleCount()
    for i = 0, nRoleCount - 1 do
        local tRoleInfo = Login_GetRoleInfo(i) or {}
        --print_table(tRoleInfo)

        -- --角色当前所在地图 2023.10.10 地图改为在Loading下载
        -- local nMapID = tRoleInfo.dwMapID
        -- if not table.contain_value(tMapIDList, nMapID) then
        --     table.insert(tMapIDList, nMapID)
        -- end

        -- --角色门派对应地图
        -- local dwForceID = tRoleInfo.dwForceID
        -- if dwForceID == 0 and tRoleInfo.nLastSaveTime == 0 and tRoleInfo.nTotalGameTime == 0 then
        --     dwForceID = KUNGFU_ID_FORCE_TYPE[tRoleInfo.dwKungfuID]
        -- end
        -- local tForceMapID = ForceIDToMapID[dwForceID]
        -- tForceMapID = IsTable(tForceMapID) and tForceMapID or {tForceMapID}
        -- for _, dwForceMapID in ipairs(tForceMapID) do
        --     if not table.contain_value(tMapIDList, dwForceMapID) then
        --         table.insert(tMapIDList, dwForceMapID)
        --     end
        -- end

        -- --角色装备
        -- for _, nEquipID in pairs(tRoleInfo.RepresentData or {}) do
        --     if nEquipID ~= 0 and not table.contain_value(tEquipList, nEquipID) then
        --         table.insert(tEquipList, nEquipID)
        --     end
        -- end
    end

    for _, nMapID in ipairs(tMapIDList) do
        local nPackID = self.GetMapResPackID(nMapID)
        table.insert(tPackIDList, nPackID)
    end

    return tPackIDList
end

function PakDownloadMgr._CheckOrderAndNeedDownload(tPackIDList)
    -- 期望状态：列表中第一个在下载，后续的按顺序在等待队列中置顶排列
    -- 当不满足该状态时：
    -- 1. 若存在未开始（包括暂停），则弹窗询问；
    -- 2. 若存在等待中但未置顶（包括失败重试），则置顶并弹tips提示；若无法置顶则仅弹Tips告知正在等待下载；
    -- 当满足下载状态时，则弹Tips告知正在下载；

    local bOrderError = false
    local bNeedDownload = false
    local nIndex = 0
    local tbTaskTable = Storage.Download.tbTaskTable
    local nDownloadingLen = #tbTaskTable[DOWNLOAD_STATE.DOWNLOADING]
    for _, nPackID in ipairs(tPackIDList) do
        nIndex = nIndex + 1
        local tTask = nIndex <= nDownloadingLen and tbTaskTable[DOWNLOAD_STATE.DOWNLOADING][nIndex] or tbTaskTable[DOWNLOAD_STATE.QUEUE][nIndex - nDownloadingLen]
        if not tTask or tTask.nPackID ~= nPackID then
            bOrderError = true
        end

        local nViewState = self.GetPackViewState(nPackID)
        if nViewState == DOWNLOAD_STATE.NONE or nViewState == DOWNLOAD_STATE.PAUSE then
            bOrderError = true
            bNeedDownload = true
            break
        end
    end

    return bOrderError, bNeedDownload
end

--玩家执行某些行为前检测地图资源是否存在，若不存在则弹窗下载
---@param tMapIDList table|number 地图ID/地图ID列表
---@param fnResDownloaded function|nil 下载完成后执行操作
---@param szCompleteConfirm string|nil 下载完成后弹出文本（弹窗/Tips）
---@param bTips boolean|nil 下载完成后弹出为Tips还是弹窗
---@param szMapName string|nil 确认下载时显示的地图名称，若为空则取第一个地图ID的名称
---@param fnConfirmDownload function|nil 确认下载时执行
---@param fnCancelDownload function|nil 取消下载时执行
function PakDownloadMgr.UserCheckDownloadMapRes(tMapIDList, fnResDownloaded, szCompleteConfirm, bTips, szMapName, fnConfirmDownload, fnCancelDownload, tOtherButton)
    if IsNumber(tMapIDList) then
        tMapIDList = {tMapIDList}
    elseif not IsTable(tMapIDList) then
        return false
    end

    for i = #tMapIDList, 1, -1 do
        local nPackID = self.GetMapResPackID(tMapIDList[i])
        if not self._IsMapResValid(tMapIDList[i]) or not self.IsPackInWhiteList(nPackID, true) then
            table.remove(tMapIDList, i)
        end
    end

    if #tMapIDList <= 0 then
        return false
    end

    local nMainMapID = tMapIDList[1]
    if not szMapName then
        szMapName = UIHelper.GBKToUTF8(Table_GetMapName(nMainMapID)) or ""
        if not string.is_nil(szMapName) then
            szMapName = "[" .. szMapName .. "]"
        end
    end

    local tCorePackIDList = self.NeedDownloadCorePack(nMainMapID) and self.GetCorePackIDList() or {}
    local tMapPackIDList = {}
    for _, nCurMapID in ipairs(tMapIDList) do
        local nPackID = self.GetMapResPackID(nCurMapID)
        table.insert(tMapPackIDList, nPackID)
    end

    local tPackIDList = {}
    local function _insertPackIDList(tSourcePackIDList)
        for _, nPackID in ipairs(tSourcePackIDList) do
            local nState, _, _ = self.GetPackState(nPackID)
            if nState ~= DOWNLOAD_OBJECT_STATE.DOWNLOADED and not table.contain_value(tPackIDList, nPackID) then
                table.insert(tPackIDList, nPackID)
            end
        end
    end

    _insertPackIDList(tCorePackIDList)
    _insertPackIDList(tMapPackIDList)

    --tPackIDList已排除完成，所以若列表为空则表示都已在完成
    if #tPackIDList <= 0 then
        return true
    end

    local bOrderError, bNeedDownload = self._CheckOrderAndNeedDownload(tPackIDList)
    local tMapStateInfo = self.GetStateInfoByPackIDList(tMapPackIDList)
    local tCoreStateInfo = self.GetStateInfoByPackIDList(tCorePackIDList)
    local tStateInfo = self.GetStateInfoByPackIDList(tPackIDList)

    local dwMapLeftDownloadSize = tMapStateInfo.dwTotalSize - tMapStateInfo.dwDownloadedSize
    local dwCoreLeftDownloadSize = tCoreStateInfo.dwTotalSize - tCoreStateInfo.dwDownloadedSize
    local dwLeftDownloadSize = tStateInfo.dwTotalSize - tStateInfo.dwDownloadedSize

    local szDownloadContentText = "资源文件"
    if dwCoreLeftDownloadSize > 0 and dwMapLeftDownloadSize > 0 then
        szDownloadContentText = "核心资源和地图资源"
    elseif dwCoreLeftDownloadSize > 0 then
        szDownloadContentText = "核心资源"
    elseif dwMapLeftDownloadSize > 0 then
        szDownloadContentText = "地图资源"
    end

    local fnOnComplete = function()
        local tStateInfo = self.GetStateInfoByPackIDList(tPackIDList)
        if tStateInfo.nState == DOWNLOAD_STATE.COMPLETE then
            if fnResDownloaded and not bTips then
                --仅最近一次玩家操作检测下载的地图需要弹窗询问是否进行后续操作
                if self.nUserDownloadingMapID ~= nMainMapID then
                    return
                end

                self.nUserDownloadingMapID = nil
                if not szCompleteConfirm then
                    szCompleteConfirm = szDownloadContentText .. "已下载完成，是否前往地图" .. szMapName .. " ？"
                end

                UIHelper.ShowConfirm(szCompleteConfirm, function()
                    fnResDownloaded()
                end)
            else
                TipsHelper.ShowNormalTip(szCompleteConfirm or (szDownloadContentText .. "已下载完成"))
            end
        end
    end

    if bNeedDownload then
        local szLeftDownloadSize = self.FormatSize(dwLeftDownloadSize)
        local szCoreLeftDownloadSize = self.FormatSize(dwCoreLeftDownloadSize)
        local szMapLeftDownloadSize = self.FormatSize(dwMapLeftDownloadSize)

        local szDownloadSizeText = "资源文件" .. szLeftDownloadSize
        if dwCoreLeftDownloadSize > 0 and dwMapLeftDownloadSize > 0 then
            szDownloadSizeText = string.format("资源文件%s（核心资源%s+地图资源%s）", szLeftDownloadSize, szCoreLeftDownloadSize, szMapLeftDownloadSize)
        elseif dwCoreLeftDownloadSize > 0 then
            szDownloadSizeText = "核心资源文件" .. szCoreLeftDownloadSize
        elseif dwMapLeftDownloadSize > 0 then
            szDownloadSizeText = "地图资源文件" .. szMapLeftDownloadSize
        end

        local nNetMode = App_GetNetMode()
        local szConfirmContent
        if nNetMode == NET_MODE.WIFI then
            szConfirmContent = string.format("前往%s需要下载%s，是否进行下载？", szMapName, szDownloadSizeText)
        elseif nNetMode == NET_MODE.CELLULAR then
            szConfirmContent = string.format("前往%s需要下载%s，当前处于移动网络，是否使用流量进行下载？", szMapName, szDownloadSizeText)
        else
            --无网络
        end

        local dialog = UIHelper.ShowConfirm(szConfirmContent, function()
            local tStateInfo = self.GetStateInfoByPackIDList(tPackIDList)
            if tStateInfo.nState == DOWNLOAD_STATE.DOWNLOADING then
                TipsHelper.ShowNormalTip(szDownloadContentText .. "已开始下载")
            end

            if fnResDownloaded and not bTips then
                --记录最近一次玩家操作检测下载的地图
                self.nUserDownloadingMapID = nMainMapID
            end

            self.DownloadPackListImmediately(tPackIDList, fnOnComplete)

            if fnConfirmDownload then
                fnConfirmDownload()
            end
        end, fnCancelDownload)
        dialog:SetButtonContent("Confirm", "继续下载")
        dialog:SetButtonContent("Cancel", g_tStrings.STR_CANCEL)
        if tOtherButton then
            dialog:ShowOtherButton()
            dialog:SetOtherButtonClickedCallback(tOtherButton.callback)
            dialog:SetOtherButtonContent(tOtherButton.szName)
        end
    else
        if bOrderError then
            if fnResDownloaded and not bTips then
                --记录最近一次玩家操作检测下载的地图
                self.nUserDownloadingMapID = nMainMapID
            end

            --已在下载队列中，但未置顶，则调整顺序
            self.DownloadPackListImmediately(tPackIDList, fnOnComplete)
        end
        TipsHelper.ShowNormalTip(string.format("前往%s需要下载%s，正在下载中，请稍候...", szMapName, szDownloadContentText))
    end

    return false
end

function PakDownloadMgr.UserCheckDownloadHomelandRes(nMapID, dwSkinID, fnResDownloaded)
    local nHomelandPackID = 2 --家园包ID
    local nPackID = self.GetMapResPackID(nMapID)
    local nSkinMapID = dwSkinID and MapHelper.GetHomelandSkinResMapID(nMapID, dwSkinID)
    local nSkinPackID = nSkinMapID and self.GetMapResPackID(nSkinMapID)
    local tMapPackIDList = {nHomelandPackID, nPackID, nSkinPackID}
    local tCorePackIDList = self.NeedDownloadCorePack(nMapID) and self.GetCorePackIDList() or {}

    local tPackIDList = {}
    local function _insertPackIDList(tSourcePackIDList)
        for _, nPackID in ipairs(tSourcePackIDList) do
            local nState, _, _ = self.GetPackState(nPackID)
            if nState ~= DOWNLOAD_OBJECT_STATE.DOWNLOADED and not table.contain_value(tPackIDList, nPackID) then
                table.insert(tPackIDList, nPackID)
            end
        end
    end

    _insertPackIDList(tCorePackIDList)
    _insertPackIDList(tMapPackIDList)

    --tPackIDList已排除完成，所以若列表为空则表示都已在完成
    if #tPackIDList <= 0 then
        return true
    end

    local bOrderError, bNeedDownload = self._CheckOrderAndNeedDownload(tPackIDList)
    local tMapStateInfo = self.GetStateInfoByPackIDList(tMapPackIDList)
    local tCoreStateInfo = self.GetStateInfoByPackIDList(tCorePackIDList)
    local tStateInfo = self.GetStateInfoByPackIDList(tPackIDList)

    local dwMapLeftDownloadSize = tMapStateInfo.dwTotalSize - tMapStateInfo.dwDownloadedSize
    local dwCoreLeftDownloadSize = tCoreStateInfo.dwTotalSize - tCoreStateInfo.dwDownloadedSize
    local dwLeftDownloadSize = tStateInfo.dwTotalSize - tStateInfo.dwDownloadedSize

    local szDownloadContentText = "资源文件"
    if dwCoreLeftDownloadSize > 0 and dwMapLeftDownloadSize > 0 then
        szDownloadContentText = "核心资源和地图资源"
    elseif dwCoreLeftDownloadSize > 0 then
        szDownloadContentText = "核心资源"
    elseif dwMapLeftDownloadSize > 0 then
        szDownloadContentText = "地图资源"
    end

    local szMapName = UIHelper.GBKToUTF8(Table_GetMapName(nMapID)) or ""
    local tLine = Table_GetPrivateHomeSkin(nMapID, dwSkinID)
    if tLine and tLine.szSkinName then
        szMapName = szMapName .. "·" .. UIHelper.GBKToUTF8(tLine.szSkinName)
    end
    if not string.is_nil(szMapName) then
        szMapName = "[" .. szMapName .. "]"
    end

    local fnOnComplete = function()
        local tStateInfo = self.GetStateInfoByPackIDList(tPackIDList)
        if tStateInfo.nState == DOWNLOAD_STATE.COMPLETE then
            if fnResDownloaded then
                --仅最近一次玩家操作检测下载的地图需要弹窗询问是否进行后续操作
                if self.nUserDownloadingMapID ~= nMapID then
                    return
                end

                self.nUserDownloadingMapID = nil
                local szCompleteConfirm = szDownloadContentText .. "已下载完成，是否前往家园" .. szMapName .. "？"
                UIHelper.ShowConfirm(szCompleteConfirm, function()
                    fnResDownloaded()
                end)
            else
                TipsHelper.ShowNormalTip(szDownloadContentText .. "已下载完成")
            end
        end
    end

    if bNeedDownload then
        local szLeftDownloadSize = self.FormatSize(dwLeftDownloadSize)
        local szCoreLeftDownloadSize = self.FormatSize(dwCoreLeftDownloadSize)
        local szMapLeftDownloadSize = self.FormatSize(dwMapLeftDownloadSize)

        local szDownloadSizeText = "资源文件" .. szLeftDownloadSize
        if dwCoreLeftDownloadSize > 0 and dwMapLeftDownloadSize > 0 then
            szDownloadSizeText = string.format("资源文件%s（核心资源%s+地图资源%s）", szLeftDownloadSize, szCoreLeftDownloadSize, szMapLeftDownloadSize)
        elseif dwCoreLeftDownloadSize > 0 then
            szDownloadSizeText = "核心资源文件" .. szCoreLeftDownloadSize
        elseif dwMapLeftDownloadSize > 0 then
            szDownloadSizeText = "地图资源文件" .. szMapLeftDownloadSize
        end

        local nNetMode = App_GetNetMode()
        local szConfirmContent
        if nNetMode == NET_MODE.WIFI then
            szConfirmContent = string.format("前往家园%s需要下载%s，是否进行下载？", szMapName, szDownloadSizeText)
        elseif nNetMode == NET_MODE.CELLULAR then
            szConfirmContent = string.format("前往家园%s需要下载%s，当前处于移动网络，是否使用流量进行下载？", szMapName, szDownloadSizeText)
        else
            --无网络
        end

        local dialog = UIHelper.ShowConfirm(szConfirmContent, function()
            local tStateInfo = self.GetStateInfoByPackIDList(tPackIDList)
            if tStateInfo.nState == DOWNLOAD_STATE.DOWNLOADING then
                TipsHelper.ShowNormalTip(szDownloadContentText .. "已开始下载")
            end

            if fnResDownloaded then
                --记录最近一次玩家操作检测下载的地图
                self.nUserDownloadingMapID = nMapID
            end

            self.DownloadPackListImmediately(tPackIDList, fnOnComplete)
        end)
        dialog:SetButtonContent("Confirm", "继续下载")
        dialog:SetButtonContent("Cancel", g_tStrings.STR_CANCEL)
    else
        if bOrderError then
            if fnResDownloaded then
                --记录最近一次玩家操作检测下载的地图
                self.nUserDownloadingMapID = nMapID
            end

            --已在下载队列中，但未置顶，则调整顺序
            self.DownloadPackListImmediately(tPackIDList, fnOnComplete)
        end
        TipsHelper.ShowNormalTip(string.format("前往家园%s需要下载%s，正在下载中，请稍候...", szMapName, szDownloadContentText))
    end

    return false
end

function PakDownloadMgr.UserCheckDownloadEquipRes(nRoleType, tEquipList, tEquipSfxList, nReplaceDynamicID)
    if nReplaceDynamicID then
        self.ReleaseDynamicPakInfo(nReplaceDynamicID)
    end

    if not nRoleType or not tEquipList or not tEquipSfxList then
        return nil, false
    end

    local fnSortByIndex = function(tLeft, tRight)
        if tLeft.nFileType < tRight.nFileType then
            return true
        elseif tLeft.nFileType > tRight.nFileType then
            return false
        else
            return tLeft.dwRepresentID < tRight.dwRepresentID
        end
    end
    table.sort(tEquipList, fnSortByIndex)
    table.sort(tEquipSfxList, fnSortByIndex)

    local bRemoteNotExist = false
    local tLackEquipList = {}
    for _, tEquip in ipairs(tEquipList) do
        local nState = PakDownload_IsExistEquipResource(nRoleType, tEquip)
        if nState == RESOURCE_EXIST_STATE.REMOTE_EXIST then
            LOG.INFO("[PakDownloadMgr] EquipRes remote exist, %d %d %d", nRoleType, tEquip.nFileType, tEquip.dwRepresentID)
            table.insert(tLackEquipList, tEquip)
        elseif nState == RESOURCE_EXIST_STATE.NOT_EXIST then
            LOG.INFO("[PakDownloadMgr] EquipRes not exist, %d %d %d", nRoleType, tEquip.nFileType, tEquip.dwRepresentID)
            bRemoteNotExist = true
        end
    end

    local tEquipApexList = {}
    local tLackEquipApexList = {}
    if QualityMgr.CanEnableClothSimulation() and GameSettingData.GetNewValue(UISettingKey.ClothSimulation) then
        for _, tEquip in ipairs(tEquipList) do
            local tEquipApex = clone(tEquip)
            table.insert(tEquipApexList, tEquipApex)
            local nState = PakDownload_IsExistEquipApexResource(nRoleType, tEquipApex)
            if nState == RESOURCE_EXIST_STATE.REMOTE_EXIST then
                LOG.INFO("[PakDownloadMgr] EquipApexRes remote exist, %d %d %d", nRoleType, tEquipApex.nFileType, tEquipApex.dwRepresentID)
                table.insert(tLackEquipApexList, tEquipApex)
            end
        end
    end

    local tLackEquipSfxList = {}
    for _, tEquipSfx in ipairs(tEquipSfxList) do
        local nState = PakDownload_IsExistEquipSfxResource(nRoleType, tEquipSfx)
        if nState == RESOURCE_EXIST_STATE.REMOTE_EXIST then
            table.insert(tLackEquipSfxList, tEquipSfx)
            LOG.INFO("[PakDownloadMgr] EquipSfxRes remote exist, %d %d %d %d", nRoleType, tEquipSfx.nFileType, tEquipSfx.dwRepresentID, tEquipSfx.dwEnchantID)
        elseif nState == RESOURCE_EXIST_STATE.NOT_EXIST then
            LOG.INFO("[PakDownloadMgr] EquipSfxRes not exist, %d %d %d %d", nRoleType, tEquipSfx.nFileType, tEquipSfx.dwRepresentID, tEquipSfx.dwEnchantID)
            bRemoteNotExist = true
        end
    end

    if #tLackEquipList > 0 or #tLackEquipApexList > 0 or #tLackEquipSfxList > 0 then
        local nCheckDynamicID = self._CheckDownloadEquipResExist(nRoleType, tEquipList, tEquipApexList, tEquipSfxList)
        if nCheckDynamicID then
            return nCheckDynamicID, bRemoteNotExist
        end
        local nDynamicID, dwDownloadSize, dwTotalSize = PakDownload_GetEquipResourceInfo(nRoleType, tLackEquipList, tLackEquipApexList, tLackEquipSfxList)
        if nDynamicID and nDynamicID > 0 then
            if dwDownloadSize < dwTotalSize then
                self.CreateDynamicPakInfo(nDynamicID, {
                    nRoleType = nRoleType,
                    tEquipList = tEquipList,
                    tLackEquipList = tLackEquipList,
                    tEquipApexList = tEquipApexList,
                    tLackEquipApexList = tLackEquipApexList,
                    tEquipSfxList = tEquipSfxList,
                    tLackEquipSfxList = tLackEquipSfxList,
                    bEquipRes = true,
                })
                return nDynamicID, bRemoteNotExist
            else
                PakDownload_ReleaseDynamicDLC(nDynamicID)
            end
        end
    end

    return nil, bRemoteNotExist
end

function PakDownloadMgr._CheckDownloadEquipResExist(nRoleType, tEquipList, tEquipApexList, tEquipSfxList)
    for nDynamicID, tInfo in pairs(self.tDynamicPakInfoList) do
        if not self._IsUselessDynamicPakInfo(nDynamicID)
            and tInfo.nRoleType == nRoleType
            and #tInfo.tEquipList == #tEquipList
            and #tInfo.tEquipApexList == #tEquipApexList
            and #tInfo.tEquipSfxList == #tEquipSfxList
            and IsTableEqual(tEquipList, tInfo.tEquipList)
            and IsTableEqual(tEquipApexList, tInfo.tEquipApexList)
            and IsTableEqual(tEquipSfxList, tInfo.tEquipSfxList)
        then
            return nDynamicID
        end
    end
end

function PakDownloadMgr.IsEquipRes(nPackID)
    return nPackID == PakDownloadMgr.ALL_EQUIP_PACKID
end

function PakDownloadMgr._OnDownloadEquipResComplete(nRoleType, tLackEquipList, tLackEquipApexList, tLackEquipSfxList)
    if not nRoleType or not tLackEquipList or not tLackEquipApexList or not tLackEquipSfxList then
        return
    end
    local tLackEquipKeyMap = {}
    for _, tEquip in ipairs(tLackEquipList) do
        local szKey = PakEquipResData.MakeEquipPakResourceKey(tEquip)
        tLackEquipKeyMap[szKey] = true
    end

    local tLackEquipApexKeyMap = {}
    for _, tEquipApex in ipairs(tLackEquipApexList) do
        local szKey = PakEquipResData.MakeEquipApexPakResourceKey(tEquipApex)
        tLackEquipApexKeyMap[szKey] = true
    end

    local tLackEquipSfxKeyMap = {}
    for _, tEquipSfx in ipairs(tLackEquipSfxList) do
        local szKey = PakEquipResData.MakeEquipSfxPakResourceKey(tEquipSfx)
        tLackEquipSfxKeyMap[szKey] = true
    end
    for _, player in pairs(PlayerData.GetAllPlayer()) do
        if player.nRoleType == nRoleType then
            local bUpdate = false
            local tRepresentID = Role_GetRepresentID(player)
            local tEquipList, tEquipSfxList = Player_GetPakEquipResource(nRoleType, tRepresentID.nHatStyle, tRepresentID)
            for _, tEquip in ipairs(tEquipList) do
                local szKey = PakEquipResData.MakeEquipPakResourceKey(tEquip)
                if tLackEquipKeyMap[szKey] then
                    bUpdate = true
                    break
                end
            end
            if not bUpdate then
                for _, tEquipApex in ipairs(tEquipList) do
                    local szKey = PakEquipResData.MakeEquipApexPakResourceKey(tEquipApex)
                    if tLackEquipApexKeyMap[szKey] then
                        bUpdate = true
                        break
                    end
                end
            end
            if not bUpdate then
                for _, tEquipSfx in ipairs(tEquipSfxList) do
                    local szKey = PakEquipResData.MakeEquipSfxPakResourceKey(tEquipSfx)
                    if tLackEquipSfxKeyMap[szKey] then
                        bUpdate = true
                        break
                    end
                end
            end
            if bUpdate then
                player.OnDownloadEquipResource()
            end
        end
    end
end

function PakDownloadMgr.CreateDynamicPakInfo(nDynamicID, tInfo)
    tInfo = tInfo or {}
    tInfo.nPackID = nDynamicID
    tInfo.bDynamic = true
    tInfo.szName = "外显资源"
    self.tDynamicPakInfoList[nDynamicID] = tInfo

    local nCount = 0
    for _ in pairs(self.tDynamicPakInfoList) do
        nCount = nCount + 1
    end
    LOG.INFO("PakDownloadMgr tDynamicPakInfoList len=%d", nCount)
end

function PakDownloadMgr.ReleaseDynamicPakInfo(nDynamicID)
    if not nDynamicID then
        return
    end
    if not self._IsUselessDynamicPakInfo(nDynamicID) then
        return
    end
    self.tDynamicPakInfoList[nDynamicID] = nil
    PakDownload_ReleaseDynamicDLC(nDynamicID)
end


function PakDownloadMgr._IsUselessDynamicPakInfo(nDynamicID)
    if not nDynamicID then
        return
    end
    local tDownloadInfo = self.GetDownloadingInfo(nDynamicID)
    local nState, _, _ = self.GetPackState(nDynamicID)
    return not tDownloadInfo and nState == DOWNLOAD_OBJECT_STATE.NOTEXIST
end

function PakDownloadMgr._CheckDynamicPakDownloadComplete(nDynamicID)
    local tPakInfo = self.GetPackInfo(nDynamicID)
    if not tPakInfo.bDynamic then
        return
    end
    if tPakInfo.bEquipRes then
        self._OnDownloadEquipResComplete(tPakInfo.nRoleType, tPakInfo.tLackEquipList, tPakInfo.tLackEquipApexList, tPakInfo.tLackEquipSfxList)
        Event.Dispatch(EventType.OnEquipPakResourceDownload, nDynamicID)
        return
    end
end

function PakDownloadMgr.IsDynamicPack(nDynamicID)
    return self.tDynamicPakInfoList[nDynamicID] ~= nil
end

-------------------------------- UpdateAllPacks --------------------------------

function PakDownloadMgr.UpdateAllPacks()
    local nPackID = -1
    --若已在下载，则返回
    if self.GetDownloadingInfo(nPackID) then
        return
    end

    Log("[PakDownloadMgr] PakDownload_UpdateAllPacks")
    local bResult = PakDownload_UpdateAllPacks()
    if bResult then
        self._CreateDownloadingInfo(nPackID)
    end

    self._SetDownloadingState(nPackID, DOWNLOAD_STATE.QUEUE)
    Event.Dispatch(EventType.PakDownload_OnQueue, nPackID)
    self._UpdateDownloadQueue()
end

function PakDownloadMgr.RepairAllPacks(fnOnComplete)
    local bResult = PakDownload_RepairAllPacks()
    if bResult then
        if fnOnComplete then
            fnOnComplete()
        end
    end
end

-------------------------------- Downloading --------------------------------

function PakDownloadMgr.IsDownloading()
    return self.bDownloading
end

function PakDownloadMgr.GetDownloadingList()
    return self.tDownloadingList
end

--获取扩展包的下载中信息，若为空则不在下载
function PakDownloadMgr.GetDownloadingInfo(nPackID)
    return self.tDownloadingList and self.tDownloadingList[nPackID]
end

function PakDownloadMgr.GetStateInfoByPackIDList(tPackIDList)
    if IsNumber(tPackIDList) then
        tPackIDList = {tPackIDList}
    else
        tPackIDList = tPackIDList or {}
    end

    local nState = DOWNLOAD_STATE.NONE
    local nTotalPack = #tPackIDList
    local nDownloadedPack = 0
    local nTotalTask = 0
    local dwTotalSize = 0
    local dwDownloadedSize = 0
    local nTotalFile = 0
    local nDownloadedFile = 0
    local dwDownloadSpeed = 0
    local nProgress = 0

    local bAllCompleted = true
    for _, nPackID in pairs(tPackIDList or {}) do
        local nCurState, dwCurTotalSize, dwCurDownloadedSize, nCurTotalFile, nCurDownloadedFile = self.GetPackState(nPackID)
        local tDownloadInfo = self.GetDownloadingInfo(nPackID)
        dwTotalSize = dwTotalSize + dwCurTotalSize
        dwDownloadedSize = dwDownloadedSize + dwCurDownloadedSize
        nTotalFile = nTotalFile + nCurTotalFile
        nDownloadedFile = nDownloadedFile + nCurDownloadedFile

        if tDownloadInfo then
            nTotalTask = nTotalTask + 1
            --dwDownloadSpeed = dwDownloadSpeed + tDownloadInfo.dwDownloadSpeed
            dwDownloadSpeed = dwDownloadSpeed + self.GetPackDownloadSpeed(nPackID)
            --优先级 DOWNLOADING > QUEUE > PAUSE > COMPLETE
            if tDownloadInfo.nState == DOWNLOAD_STATE.DOWNLOADING then
                nState = DOWNLOAD_STATE.DOWNLOADING
            elseif tDownloadInfo.nState == DOWNLOAD_STATE.QUEUE or tDownloadInfo.nState == DOWNLOAD_STATE.FAILED then
                if nState ~= DOWNLOAD_STATE.DOWNLOADING then
                    nState = DOWNLOAD_STATE.QUEUE
                end
            elseif (tDownloadInfo.nState == DOWNLOAD_STATE.PAUSE or tDownloadInfo.bPauseFlag) then
                if nState ~= DOWNLOAD_STATE.DOWNLOADING and nState ~= DOWNLOAD_STATE.QUEUE then
                    nState = DOWNLOAD_STATE.PAUSE
                end
            end

            if tDownloadInfo.nState ~= DOWNLOAD_STATE.COMPLETE then
                bAllCompleted = false
            end
        end

        if nCurState == DOWNLOAD_OBJECT_STATE.DOWNLOADED then
            nDownloadedPack = nDownloadedPack + 1
        else
            bAllCompleted = false
        end
    end
    if bAllCompleted then
        nState = DOWNLOAD_STATE.COMPLETE
    elseif nState == DOWNLOAD_STATE.NONE and dwDownloadedSize > 0 then
        nState = DOWNLOAD_STATE.PAUSE
    end

    nProgress = self.CalcProgress(dwTotalSize, dwDownloadedSize, nTotalFile, nDownloadedFile)

    local tStateInfo = {
        nState = nState,
        nTotalPack = nTotalPack,
        nDownloadedPack = nDownloadedPack,
        nTotalTask = nTotalTask,
        dwTotalSize = dwTotalSize,
        dwDownloadedSize = dwDownloadedSize,
        nTotalFile = nTotalFile,
        nDownloadedFile = nDownloadedFile,
        dwDownloadSpeed = dwDownloadSpeed,
        nProgress = nProgress,
    }

    return tStateInfo
end

--获取合计下载信息
function PakDownloadMgr.GetTotalDownloadInfo(bForce)
    local nTime = GetTickCount()
    if self.nCanGetTotalInfoTime and nTime < self.nCanGetTotalInfoTime and not bForce then
        return self.tTotalInfo
    end

    local nTotalState = TOTAL_DOWNLOAD_STATE.NONE
    local nTotalTask = 0
    local nCompleteTask = 0

    --总下载数据
    local dwTotalSize = 0
    local dwDownloadedSize = 0
    local nTotalFile = 0
    local nDownloadedFile = 0
    local dwTotalDownloadSpeed = 0
    local nLeftTime = 0
    local nProgress = 0

    --当前下载数据
    local nCurPackID = 0
    local nCurState = DOWNLOAD_STATE.NONE
    local dwCurTotalSize = 0
    local dwCurDownloadedSize = 0
    local nCurTotalFile = 0
    local nCurDownloadedFile = 0
    local dwCurDownloadSpeed = 0
    local nCurLeftTime = 0
    local nCurProgress = 0

    local bDownloading = false
    local bRetryFlag = false
    local dwDownloadingLeftSize = 0

    if self.IsAllBasicPackComplete() or self.IsBasicDownloading() then
        for nPackID, tDownloadInfo in pairs(self.tDownloadingList) do
            nTotalTask = nTotalTask + 1

            if tDownloadInfo.nState == DOWNLOAD_STATE.DOWNLOADING or tDownloadInfo.nState == DOWNLOAD_STATE.QUEUE or tDownloadInfo.nState == DOWNLOAD_STATE.FAILED then
                --dwTotalDownloadSpeed = dwTotalDownloadSpeed + tDownloadInfo.dwDownloadSpeed
                dwTotalDownloadSpeed = dwTotalDownloadSpeed + self.GetPackDownloadSpeed(nPackID)
                dwDownloadingLeftSize = dwDownloadingLeftSize + (tDownloadInfo.dwTotalSize - tDownloadInfo.dwDownloadedSize)
                if tDownloadInfo.bRetryFlag then
                    bRetryFlag = true
                end
            elseif tDownloadInfo.nState == DOWNLOAD_STATE.COMPLETE then
                nCompleteTask = nCompleteTask + 1
            end
            dwTotalSize = dwTotalSize + tDownloadInfo.dwTotalSize
            dwDownloadedSize = dwDownloadedSize + tDownloadInfo.dwDownloadedSize
            nTotalFile = nTotalFile + tDownloadInfo.nTotalFile
            nDownloadedFile = nDownloadedFile + tDownloadInfo.nDownloadedFile
        end

        --取第一个下载任务的数据
        local function _getCurInfoInTaskList(nState)
            for _, tTask in ipairs(Storage.Download.tbTaskTable[nState]) do
                local tDownloadInfo = self.GetDownloadingInfo(tTask.nPackID)
                if tDownloadInfo then
                    nCurPackID = tTask.nPackID
                    nCurState = tDownloadInfo.nState
                    dwCurTotalSize = tDownloadInfo.dwTotalSize
                    dwCurDownloadedSize = tDownloadInfo.dwDownloadedSize
                    nCurTotalFile = tDownloadInfo.nTotalFile
                    nCurDownloadedFile = tDownloadInfo.nDownloadedFile
                    --dwCurDownloadSpeed = tDownloadInfo.dwDownloadSpeed
                    dwCurDownloadSpeed = self.GetPackDownloadSpeed(tTask.nPackID)
                    return true
                end
            end
            return false
        end

        --取第一个正在下载的任务的数据，若无正在下载，则显示第一个正在暂停的任务的数据
        bDownloading = _getCurInfoInTaskList(DOWNLOAD_STATE.DOWNLOADING)
        if bDownloading then
            local tDownloadInfo = self.GetDownloadingInfo(nCurPackID)
            --若正在下载的任务为重试，则修正正在下载状态为false
            if tDownloadInfo and tDownloadInfo.bRetryFlag then
                bDownloading = false
            end
        else
            _getCurInfoInTaskList(DOWNLOAD_STATE.PAUSE)
        end
    end

    nLeftTime = dwTotalDownloadSpeed > 0 and dwDownloadingLeftSize / dwTotalDownloadSpeed or 0
    nProgress = self.CalcProgress(dwTotalSize, dwDownloadedSize, nTotalFile, nDownloadedFile)
    nCurLeftTime = dwCurDownloadSpeed > 0 and (dwCurTotalSize - dwCurDownloadedSize) / dwCurDownloadSpeed or 0
    nCurProgress = self.CalcProgress(dwCurTotalSize, dwCurDownloadedSize, nCurTotalFile, nCurDownloadedFile)

    --总状态优先级：下载中>重试中>已暂停
    if nTotalTask > 0 and nCompleteTask < nTotalTask then
        if bDownloading then
            nTotalState = TOTAL_DOWNLOAD_STATE.DOWNLOADING
        elseif bRetryFlag then
            nTotalState = TOTAL_DOWNLOAD_STATE.RETRYING
        else
            nTotalState = TOTAL_DOWNLOAD_STATE.PAUSING
        end
    end

    self.tTotalInfo = {
        nTotalState = nTotalState,
        nTotalTask = nTotalTask,
        nCompleteTask = nCompleteTask,

        dwTotalDownloadSpeed = dwTotalDownloadSpeed,
        nLeftTime = nLeftTime,
        dwTotalSize = dwTotalSize,
        dwDownloadedSize = dwDownloadedSize,
        nTotalFile = nTotalFile,
        nDownloadedFile = nDownloadedFile,
        nProgress = nProgress,

        nCurPackID = nCurPackID,
        nCurState = nCurState,
        dwCurTotalSize = dwCurTotalSize,
        dwCurDownloadedSize = dwCurDownloadedSize,
        nCurTotalFile = nCurTotalFile,
        nCurDownloadedFile = nCurDownloadedFile,
        dwCurDownloadSpeed = dwCurDownloadSpeed,
        nCurLeftTime = nCurLeftTime,
        nCurProgress = nCurProgress,
    }

    --限制每0.1s更新一次数据
    self.nCanGetTotalInfoTime = nTime + 100

    return self.tTotalInfo
end

--全局下载速度
function PakDownloadMgr.GetTotalDownloadSpeed()
    return PakDownload_GetDownloadSpeed()
end

function PakDownloadMgr.GetPackDownloadSpeed(nPackID)
    local tDownloadInfo = self.GetDownloadingInfo(nPackID)
    if tDownloadInfo and tDownloadInfo.nState == DOWNLOAD_STATE.DOWNLOADING then
        --return tDownloadInfo.dwDownloadSpeed
        return self.GetTotalDownloadSpeed() --因为现在只会同时下一个包，使用这个全局的速度（比较准确）
    end
    return 0
end

function PakDownloadMgr._CreateDownloadingInfo(nPackID)
    if not nPackID then
        return
    end

    local nState, dwTotalSize, dwDownloadedSize, nTotalFile, nDownloadedFile = self.GetPackState(nPackID)
    local tDownloadInfo = {
        nPackID = nPackID,
        nState = DOWNLOAD_STATE.NONE,
        nResult = nil,
        dwDownloadSpeed = 0,
        dwTotalSize = dwTotalSize,
        dwDownloadedSize = dwDownloadedSize,
        nTotalFile = nTotalFile,
        nDownloadedFile = nDownloadedFile,
        fnOnComplete = nil,
        fnOnPaused = nil,
        bStartFlag = false,     --OnStart标记
        bPauseFlag = false,     --OnStart前暂停标记
        bPausingFlag = false,   --等待OnPause标记
        bResumeFlag = false,    --OnPause后继续标记
        bCancelFlag = false,    --等待OnCancel标记
        bRetryFlag = false,     --OnComplete失败标记
    }
    self.tDownloadingList[nPackID] = tDownloadInfo
    return tDownloadInfo
end

--nState: DOWNLOAD_STATE
function PakDownloadMgr._SetDownloadingState(nPackID, nState, bTop)
    local tDownloadInfo = self.GetDownloadingInfo(nPackID)
    if tDownloadInfo then
        if tDownloadInfo.nState ~= nState then
            tDownloadInfo.nState = nState
            self._FlushTaskTable(nPackID, bTop)
            Log("[PakDownloadMgr] PakDownload_OnStateUpdate", nPackID, GetEnumStr(DOWNLOAD_STATE, nState))
            Event.Dispatch(EventType.PakDownload_OnStateUpdate, nPackID)
        elseif bTop then
            self._FlushTaskTable(nPackID, bTop)
        end
    end
end

function PakDownloadMgr._GetDownloadingCount()
    local nCount = 0
    for _, tDownloadInfo in pairs(self.tDownloadingList) do
        if tDownloadInfo.nState == DOWNLOAD_STATE.DOWNLOADING then
            nCount = nCount + 1
        end
    end
    return nCount
end

--是否所有下载任务完成
function PakDownloadMgr._IsCurDownloadAllComplete()
    for nPackID, tDownloadInfo in pairs(self.tDownloadingList) do
        if tDownloadInfo.nState ~= DOWNLOAD_STATE.COMPLETE then
            return false
        end
    end
    return true
end

--检测所有任务下载完成，并清理
function PakDownloadMgr._CheckCurDownloadAllComplete(bCompleteEnd)
    if self._IsCurDownloadAllComplete() then
        for nPackID, tDownloadInfo in pairs(self.tDownloadingList) do
            self.tDownloadingList[nPackID] = nil
            self.tTopMostPackIDList[nPackID] = nil
            --self._FlushTaskTable(nPackID) --注释掉这行，使所有下载任务完成后，正在下载界面先不立即移除（之后调CheckClearTaskList清理）
        end
        self._OnDownloadEnd(bCompleteEnd)
    else
        self._UpdateDownloadQueue()
    end
end

function PakDownloadMgr.GetAllowNotWifiDownload()
    if self.bAllowNotWifiDownload == nil then
        self.bAllowNotWifiDownload = false
    end
    return self.bAllowNotWifiDownload
end

function PakDownloadMgr.SetAllowNotWifiDownload(bAllowNotWifiDownload)
    self.bAllowNotWifiDownload = bAllowNotWifiDownload
    --local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelGameSettings)
    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelResourcesDownload)
    if scriptView then
        UIHelper.SetSelected(scriptView.TogNetworkDownLoad, bAllowNotWifiDownload, false)
    end
    if self.nNetMode == NET_MODE.CELLULAR then
        self._UpdateNetMode(true)
    end
end

--更新网络状态
function PakDownloadMgr._UpdateNetMode(bForce)
    local nNetMode = App_GetNetMode()
    if nNetMode == NET_MODE.CELLULAR and not self.GetAllowNotWifiDownload() and (self.nNetMode ~= NET_MODE.CELLULAR or bForce) then
        Log("[PakDownloadMgr] UpdateNetMode", GetEnumStr(NET_MODE, self.nNetMode), GetEnumStr(NET_MODE, nNetMode))

        --从wifi或无网络变为蜂窝网
        local tPausePackIDList = self.PauseAllPack()
        if #tPausePackIDList > 0 and not self.tNetPausePackIDList then
            local fnCancel = nil
            if self.nDownloadSceneResMapID then
                fnCancel = function()
                    self.nDownloadSceneResMapID = nil
                    Global.BackToLogin(true)
                end
            end

            self.tNetPausePackIDList = tPausePackIDList
            PakSizeQueryMgr.UnRegQuerySize(self, self.nNetQuerySizeEntryID)
            self.nNetQuerySizeEntryID = PakSizeQueryMgr.RegQuerySize(self, tPausePackIDList, function(bSuccess, dwTotalSize, dwDownloadedSize)
                self.nNetQuerySizeEntryID = nil
                local szContent
                if bSuccess then
                    local dwLeftDownloadSize = dwTotalSize - dwDownloadedSize
                    szContent = "当前处于移动网络，是否使用流量下载" .. self.FormatSize(dwLeftDownloadSize) .. "的资源文件？"
                else
                    szContent = "当前处于移动网络，是否使用流量下载资源文件？"
                end

                local function fnPauseDialog()
                    self.netPauseDialog = UIHelper.ShowSystemConfirm(szContent, function()
                        -- self.SetAllowNotWifiDownload(true)
                        for _, nPackID in ipairs(tPausePackIDList) do
                            self.ResumePack(nPackID)
                        end
                        self.netPauseDialog = nil
                        self.tNetPausePackIDList = nil
                    end, function()
                        if fnCancel then
                            fnCancel()
                        end
                        self.netPauseDialog = nil
                        self.tNetPausePackIDList = nil
                    end)
                    self.netPauseDialog:SetButtonContent("Confirm", "继续下载")
                    self.netPauseDialog:SetButtonContent("Cancel", g_tStrings.STR_CANCEL)
                end

                --后台无法弹窗，等回到前台再弹
                if self.bInBackgroundMode then
                    self.fnPauseDialog = fnPauseDialog
                else
                    fnPauseDialog()
                end
            end, true)
        end
    elseif nNetMode == NET_MODE.WIFI and self.tNetPausePackIDList then
        --网络变回Wifi，自动关闭弹窗，恢复下载
        if self.netPauseDialog then
            UIMgr.Close(self.netPauseDialog)
        end
        PakSizeQueryMgr.UnRegQuerySize(self, self.nNetQuerySizeEntryID)
        for _, nPackID in ipairs(self.tNetPausePackIDList) do
            self.ResumePack(nPackID)
        end
        self.netPauseDialog = nil
        self.fnPauseDialog = nil
        self.tNetPausePackIDList = nil
        self.nNetQuerySizeEntryID = nil
    end

    self.nNetMode = nNetMode
end

function PakDownloadMgr._UpdateMultiIntanceState(bInit)
    if not PakDownload_IsMainInstance() then
        return
    end

    --判断全部资源下载完成则允许多开（初始化时若bEnableMultiInstance为false则无需调用）
    local bEnableMultiInstance = self.IsAllExtensionPackDownloaded() --PakDownload_GetAllDLCIsInstalled()
    if bEnableMultiInstance ~= self.bEnableMultiInstance then
        self.bEnableMultiInstance = bEnableMultiInstance
        if bInit and not bEnableMultiInstance then
            return
        end

        Log("[PakDownloadMgr] EnableMultiInstance", bEnableMultiInstance)
        PakDownload_EnableMultiInstance(bEnableMultiInstance)
    end
end

function PakDownloadMgr._HasEnoughSpace(nPackID)
    local _, dwTotalSize, dwDownloadedSize = self.GetPackState(nPackID)
    local dwSpace = self._GetRemainStorageSpace()
    local dwNeedSpace = (dwTotalSize - dwDownloadedSize) + STORAGE_SIZE_MARGIN
    local bEnough = dwNeedSpace <= dwSpace
    --local bEnough = dwNeedSpace <= 1024 * 1024 * 1024 --测试用
    if not bEnough then
        Log("[PakDownloadMgr] Space Not Enough: " .. dwNeedSpace .. "/" .. dwSpace)
    end
    return bEnough
end

--获取剩余空间大小，且避免同帧多次调用（iOS耗时大）
function PakDownloadMgr._GetRemainStorageSpace()
    if self.dwRemainStorageSpace then
        return self.dwRemainStorageSpace
    end

    self.dwRemainStorageSpace = App_GetRemainStorageSpace()
    LogDebug("[PakDownloadMgr] App_GetRemainStorageSpace", self.dwRemainStorageSpace)
    Timer.AddFrame(self.tGlobalTimer, 1, function()
        self.dwRemainStorageSpace = nil
    end)
    return self.dwRemainStorageSpace
end

function PakDownloadMgr._InitPriorityList()
    local function _insert(tIDList, nPackID, szStorageKey)
        if not nPackID then
            return
        end

        if not self.IsPackInWhiteList(nPackID) then
            return
        end

        if not table.contain_value(self.tPriorityList, nPackID) and not table.contain_value(self.tDefaultList, nPackID) then
            table.insert(tIDList, nPackID)
        end

        --若优先包已存在于本地，则记录为下载过
        local nState, _, _ = self.GetPackState(nPackID)
        if nState == DOWNLOAD_OBJECT_STATE.DOWNLOADED then
            if szStorageKey and Storage.PriorityDownload[szStorageKey] then
                Storage.PriorityDownload[szStorageKey][nPackID] = true
            end
            Storage.AutoDownload.tbPackIDMap[nPackID] = true
        end
    end

    self.tPriorityList = {}
    self.tDefaultList = {}

    local player = GetClientPlayer()
    if player then
        local nLevel = player.nLevel
        local dwForceID = player.dwForceID
        local nRoleType = player.nRoleType

        local function _parseList(tConfigList, tTargetList, szStorageKey)
            local tPackIDList
            for szKey, tLine in pairs(tConfigList) do
                --匹配[0,110), [110,120)这样的范围
                local szLowerBound, szLowerLevel, szUpperLevel, szUpperBound = string.match(szKey, "(.)(%d+),(%d+)(.)")
                if (szLowerBound == "[" or szLowerBound == "(") and (szUpperBound == "]" or szUpperBound == ")") then
                    local bIncludeLower, bIncludeUpper, nLowerLevel, nUpperLevel = szLowerBound == "[", szUpperBound == "]", tonumber(szLowerLevel), tonumber(szUpperLevel)
                    if
                        ((bIncludeLower and nLevel >= nLowerLevel) or (not bIncludeLower and nLevel > nLowerLevel)) and
                        ((bIncludeUpper and nLevel <= nUpperLevel) or (not bIncludeUpper and nLevel < nUpperLevel))
                    then
                        tPackIDList = clone(tLine)
                        break
                    end
                else
                    Log("[PakDownloadMgr] Parse Priority Config Error: Invalid Key: ", szKey)
                end
            end

            --print_table(tPackIDList)

            for _, nPackID in ipairs(tPackIDList or {}) do
                if nPackID == -1 then
                    -- -1表示门派地图
                    local tForceMapID = ForceIDToMapID[dwForceID]
                    tForceMapID = IsTable(tForceMapID) and tForceMapID or {tForceMapID}
                    for _, nMapID in ipairs(tForceMapID) do
                        local nMapPackID = self.GetMapResPackID(nMapID)
                        _insert(tTargetList, nMapPackID, szStorageKey)
                    end
                elseif nPackID == -2 then
                    -- -2表示不同体型的稻香村视频
                    local nRolePackID = RoleTypeToPackID[nRoleType]
                    _insert(tTargetList, nRolePackID, szStorageKey)
                else
                    _insert(tTargetList, nPackID, szStorageKey)
                end
            end
        end

        _parseList(self.tPriorityConfigList, self.tPriorityList, "tbPriority")
        _parseList(self.tDefaultConfigList, self.tDefaultList, "tbDefault")
    end

    Storage.PriorityDownload.Flush()
    Storage.AutoDownload.Flush()
    self._UpdatePriorityCompleteState()
end

--继续未完成的任务
function PakDownloadMgr._InitStorageTaskList()
    local nNetMode = App_GetNetMode()
    Log("[PakDownloadMgr] InitStorageTaskList", GetEnumStr(NET_MODE, nNetMode))
    self._ClearTaskTable(true, true, true, false)

    local tBasicPackIDList = self.GetBasicPackIDList()
    local tTaskTable = Storage.Download.tbTaskTable
    local tResumeTaskList = {}
    local tResumeTaskMap = {} --用于去重，避免table.contain_value耗性能太大

    for _, tTaskList in pairs(tTaskTable) do
        for _, tTask in ipairs(tTaskList) do
            local nPackID = tTask.nPackID
            local nState, _, _ = self.GetPackState(nPackID)
            if nState ~= DOWNLOAD_OBJECT_STATE.DOWNLOADED and not tResumeTaskMap[nPackID] and not table.contain_value(tBasicPackIDList, nPackID) then
                table.insert(tResumeTaskList, nPackID)
                tResumeTaskMap[nPackID] = true
            end
        end
    end

    local dwLeftDownloadSize = 0

    --2024.3.6 PC端基础包自动开始下载
    --2024.5.10 非提审包也自动下载
    if (Platform.IsWindows() or Platform.IsMac()) or not AppReviewMgr.IsReview() then
        --若基础包未下载，开始基础包并暂停
        local nState, dwTotalSize, dwDownloadedSize = self.GetBasicPackState()
        dwLeftDownloadSize = dwTotalSize - dwDownloadedSize
        if nState ~= DOWNLOAD_OBJECT_STATE.DOWNLOADED then
            self.DownloadBasicPack()
            self.PauseBasicPack()
        end
    end

    --初始化所有下载任务，并置为暂停状态
    for _, nPackID in ipairs(tResumeTaskList) do
        local _, dwTotalSize, dwDownloadedSize = self.GetPackState(nPackID)
        dwLeftDownloadSize = dwLeftDownloadSize + (dwTotalSize - dwDownloadedSize)
        self.CreatePausedTask(nPackID)
    end

    -- print_table("tResumeTaskList", tResumeTaskList)
    -- print_table("Storage.Download", Storage.Download)

    --WIFI环境自动下载
    if nNetMode == NET_MODE.WIFI or dwLeftDownloadSize <= 0 then
        self.ResumeBasicPack()
        for _, nPackID in ipairs(tResumeTaskList) do
            self.ResumePack(nPackID)
        end
    end
end

--开始优先下载
function PakDownloadMgr._DownloadPriorityList()
    self._ClearTaskTable(false, true, true, false)

    local tPriorityList = {} --待下载优先包
    local tDefaultList = {}
    for _, nPackID in ipairs(self.tPriorityList or {}) do
        local nState, _, _ = self.GetPackState(nPackID)
        if not Storage.PriorityDownload.tbPriority[nPackID] and nState ~= DOWNLOAD_OBJECT_STATE.DOWNLOADED then
            table.insert(tPriorityList, nPackID)
        else
            Log("[PakDownloadMgr] PriorityPack Skip", nPackID, Storage.PriorityDownload.tbPriority[nPackID], GetEnumStr(DOWNLOAD_OBJECT_STATE, nState))
        end
    end
    for _, nPackID in ipairs(self.tDefaultList or {}) do
        local nState, _, _ = self.GetPackState(nPackID)
        local bDownloaded = Storage.PriorityDownload.tbDefault[nPackID] or Storage.AutoDownload.tbPackIDMap[nPackID]
        if not bDownloaded and nState ~= DOWNLOAD_OBJECT_STATE.DOWNLOADED then
            table.insert(tDefaultList, nPackID)
        else
            Log("[PakDownloadMgr] DefaultPack Skip", nPackID, Storage.PriorityDownload.tbDefault[nPackID], Storage.AutoDownload.tbPackIDMap[nPackID], GetEnumStr(DOWNLOAD_OBJECT_STATE, nState))
        end
    end

    local dwLeftDownloadSize = 0
    local function _initTask(tIDList, nTriggerType)
        for i = #tIDList, 1, -1 do
            local nPackID = tIDList[i]
            local _, dwTotalSize, dwDownloadedSize = self.GetPackState(nPackID)
            dwLeftDownloadSize = dwLeftDownloadSize + (dwTotalSize - dwDownloadedSize)

            local bAddFlag = true
            local tTask, _ = self.GetTask(nPackID)
            if tTask and not tTask.nTriggerType then
                --若下载任务已被手动触发，则不再自动触发
                bAddFlag = false
            end
            self.CreatePausedTask(nPackID, true)

            --这里的Flag指优先包本次作为优先包下载，当角色下载过优先包后，若删除再下载，则不再作为优先包下载，这里Flag就不为true
            if nTriggerType and bAddFlag then
                tTask, _ = self.GetTask(nPackID)
                tTask.nTriggerType = nTriggerType
            end
        end
    end

    --倒序置顶插入暂停队列，所以先Default后Priority
    _initTask(tDefaultList, TASK_TRIGGER_TYPE.DEFAULT)
    _initTask(tPriorityList, TASK_TRIGGER_TYPE.PRIORITY)

    local tPausePackIDList = {}
    local function fnOnAllPaused()
        --WIFI环境自动下载
        local nNetMode = App_GetNetMode()
        Log("[PakDownloadMgr] DownloadPriorityList", nNetMode, #tPriorityList, #tDefaultList, #tPausePackIDList)
        if nNetMode == NET_MODE.WIFI or dwLeftDownloadSize <= 0 then
            for _, nPackID in ipairs(tPriorityList) do
                self.ResumePack(nPackID)
            end
            for _, nPackID in ipairs(tDefaultList) do
                self.ResumePack(nPackID)
            end
        end
        for _, nPackID in ipairs(tPausePackIDList) do
            self.ResumePack(nPackID)
        end
    end

    tPausePackIDList = self.PauseAllPack(fnOnAllPaused)
end

function PakDownloadMgr._InitCoreList()
    local function _insert(nPackID)
        if not nPackID then
            return
        end

        if not self.IsPackInWhiteList(nPackID) then
            return
        end

        if not table.contain_value(self.tCoreList, nPackID) then
            table.insert(self.tCoreList, nPackID)
        end

        --若核心包已存在于本地，则记录为下载过
        local nState, _, _ = self.GetPackState(nPackID)
        if nState == DOWNLOAD_OBJECT_STATE.DOWNLOADED then
            Storage.CoreDownload.tbCore[nPackID] = true
            Storage.AutoDownload.tbPackIDMap[nPackID] = true
        end
    end

    self.tCoreList = {}

    local nRoleCount = Login_GetRoleCount()
    for _, nPackID in ipairs(self.tCoreConfigList or {}) do
        if nPackID == -1 then
            -- -1表示门派地图
            for i = 0, nRoleCount - 1 do
                local tRoleInfo = Login_GetRoleInfo(i)
                local dwForceID = tRoleInfo and tRoleInfo.dwForceID
                if dwForceID == 0 and tRoleInfo.nLastSaveTime == 0 and tRoleInfo.nTotalGameTime == 0 then
                    --新创建的角色获取不到dwForceID，要转一下
                    dwForceID = KUNGFU_ID_FORCE_TYPE[tRoleInfo.dwKungfuID]
                end
                local tForceMapID = dwForceID and ForceIDToMapID[dwForceID]
                tForceMapID = IsTable(tForceMapID) and tForceMapID or {tForceMapID}
                for _, nMapID in ipairs(tForceMapID) do
                    local nMapPackID = self.GetMapResPackID(nMapID)
                    _insert(nMapPackID)
                end
            end
        elseif nPackID == -2 then
            -- -2表示不同体型的稻香村视频
            for i = 0, nRoleCount - 1 do
                local tRoleInfo = Login_GetRoleInfo(i)
                local nRoleType = tRoleInfo and tRoleInfo.RoleType
                local nRolePackID = nRoleType and RoleTypeToPackID[nRoleType]
                _insert(nRolePackID)
            end
        else
            _insert(nPackID)
        end
    end
    Storage.CoreDownload.Flush()
    Storage.AutoDownload.Flush()
end

function PakDownloadMgr.DownloadCoreList()
    if AppReviewMgr.IsReview() then
        return
    end

    local nBasicState, _, _ = self.GetBasicPackState()
    if nBasicState ~= DOWNLOAD_OBJECT_STATE.DOWNLOADED then
        return
    end

    self._InitCoreList()
    local tCoreList = {}
    for _, nPackID in ipairs(self.tCoreList) do
        local nState, _, _ = self.GetPackState(nPackID)
        local bDownloaded = Storage.CoreDownload.tbCore[nPackID] or Storage.AutoDownload.tbPackIDMap[nPackID]
        if (not bDownloaded or self.IsCorePack(nPackID)) and nState ~= DOWNLOAD_OBJECT_STATE.DOWNLOADED then
            table.insert(tCoreList, nPackID)
        else
            Log("[PakDownloadMgr] CorePack Skip", nPackID, Storage.CoreDownload.tbCore[nPackID], Storage.AutoDownload.tbPackIDMap[nPackID], GetEnumStr(DOWNLOAD_OBJECT_STATE, nState))
        end
    end

    local dwLeftDownloadSize = 0
    for i = #tCoreList, 1, -1 do
        local nPackID = tCoreList[i]
        local _, dwTotalSize, dwDownloadedSize = self.GetPackState(nPackID)
        dwLeftDownloadSize = dwLeftDownloadSize + (dwTotalSize - dwDownloadedSize)

        local bAddFlag = true
        local tTask, _ = self.GetTask(nPackID)
        if tTask and not tTask.nTriggerType then
            --若下载任务已被手动触发，则不再自动触发
            bAddFlag = false
        end
        self.CreatePausedTask(nPackID, true)

        if bAddFlag then
            tTask, _ = self.GetTask(nPackID)
            tTask.nTriggerType = TASK_TRIGGER_TYPE.CORE
        end
    end

    local tPausePackIDList = {}
    local function fnOnAllPaused()
        --WIFI环境自动下载
        local nNetMode = App_GetNetMode()
        Log("[PakDownloadMgr] DownloadCoreList", nNetMode, #tCoreList, #tPausePackIDList)
        if nNetMode == NET_MODE.WIFI or dwLeftDownloadSize <= 0 then
            for _, nPackID in ipairs(tCoreList) do
                self.ResumePack(nPackID)
            end
        end
        for _, nPackID in ipairs(tPausePackIDList) do
            self.ResumePack(nPackID)
        end
    end

    tPausePackIDList = self.PauseAllPack(fnOnAllPaused)
end

function PakDownloadMgr._ClearCoreList()
    -- 2024.10.31 不再清除核心队列
    -- for _, nPackID in ipairs(self.tCoreList or {}) do
    --     local tTask, _ = self.GetTask(nPackID)
    --     if tTask and tTask.nTriggerType == TASK_TRIGGER_TYPE.CORE then
    --         self.CancelPack(nPackID, true)
    --     end
    -- end
    self.tCoreList = nil
end

function PakDownloadMgr._TaskVersionUpdate()
    local tTaskTable = Storage.Download.tbTaskTable
    for _, tTaskList in pairs(tTaskTable) do
        for _, tTask in ipairs(tTaskList) do
            if tTask.bCore then
                tTask.bCore = nil
                tTask.nTriggerType = TASK_TRIGGER_TYPE.CORE
            elseif tTask.bPriority then
                tTask.bPriority = nil
                tTask.nTriggerType = TASK_TRIGGER_TYPE.PRIORITY
            elseif tTask.bDefault then
                tTask.bDefault = nil
                tTask.nTriggerType = TASK_TRIGGER_TYPE.DEFAULT
            end
        end
    end
    self._FlushDownloadStorage()
end

function PakDownloadMgr._ClearTaskTable(bClearComplete, bClearPriority, bClearDefault, bClearDynamic)
    --Log("[PakDownloadMgr] ClearTaskTable", bClearComplete, bClearPriority, bClearDefault, bClearDynamic)
    bClearDefault = false --2024.10.31 不再清除默认队列
    local tTaskTable = Storage.Download.tbTaskTable
    local tClearTaskList = {}
    for _, tTaskList in pairs(tTaskTable) do
        for _, tTask in ipairs(tTaskList) do
            local nPackID = tTask.nPackID
            local nState, _, _ = self.GetPackState(nPackID)
            local bComplete = nState == DOWNLOAD_OBJECT_STATE.DOWNLOADED or tTask.nState == DOWNLOAD_STATE.COMPLETE
            local bCore = self.IsCorePack(nPackID)
            -- local bPriority = (tTask.nTriggerType == TASK_TRIGGER_TYPE.PRIORITY or self.IsPriorityPack(nPackID)) and not bCore
            -- local bDefault = (tTask.nTriggerType == TASK_TRIGGER_TYPE.DEFAULT or (self.tDefaultList and table.contain_value(self.tDefaultList, nPackID))) and not bCore
            local bPriority = tTask.nTriggerType == TASK_TRIGGER_TYPE.PRIORITY and not bCore
            local bDefault = tTask.nTriggerType == TASK_TRIGGER_TYPE.DEFAULT and not bCore
            local bDynamic = tTask.bDynamic
            if ((bClearComplete and bComplete) or (bClearPriority and bPriority) or (bClearDefault and bDefault) or (bClearDynamic and bDynamic)) then
                table.insert(tClearTaskList, nPackID)
            end
        end
    end
    for _, nPackID in ipairs(tClearTaskList) do
        self.CancelPack(nPackID, true)
    end
end

function PakDownloadMgr._UpdatePriorityCompleteState()
    for _, nPackID in ipairs(self.tPriorityList or {}) do
        local nState, _, _ = self.GetPackState(nPackID)
        if not Storage.PriorityDownload.tbPriority[nPackID] and nState ~= DOWNLOAD_OBJECT_STATE.DOWNLOADED then
            self.bIsAllPriorityComplete = false
            return
        end
    end
    self.bIsAllPriorityComplete = true
end

--所有任务下载完成后，不立即清理正在下载中的内容，调用这个之后才会清理
function PakDownloadMgr.CheckClearTaskList()
    --[[
        关闭游戏时，若资源管理界面正好打开，会因为PakDownloadMgr和UIMgr的UnInit时序问题，
        导致资源管理界面OnExit调到CheckClearTaskList时，PakDownloadMgr已被反初始化，
        此时GetDownloadingInfo都为空，使得tbTaskTable全被清了，这里加个逻辑，反初始化后就直接跳出
    --]]
    if not self.bInit then
        return
    end

    for _, tTaskList in pairs(Storage.Download.tbTaskTable) do
        for i = #tTaskList, 1, -1 do
            local tTask = tTaskList[i]
            local tDownloadInfo = self.GetDownloadingInfo(tTask.nPackID)

            if not tDownloadInfo or tDownloadInfo.bCancelFlag then
                table.remove(tTaskList, i)
            end
        end
    end
    self._FlushDownloadStorage()
end

function PakDownloadMgr.IsTopMostPack(nPackID)
    return self.tTopMostPackIDList[nPackID] or false
end

function PakDownloadMgr.IsPriorityPack(nPackID)
    local bPriority, nIndex = table.contain_value(self.tPriorityList or {}, nPackID)
    return bPriority, nIndex
end

function PakDownloadMgr.IsAllPriorityPackComplete()
    if self.bIsAllPriorityComplete == nil then
        self._UpdatePriorityCompleteState()
    end
    return self.bIsAllPriorityComplete
end

function PakDownloadMgr.GetPriorityList()
    return self.tPriorityList
end

--当tDownloadInfo的nState/bPauseFlag/bCancelFlag变化或自身+/-时需要调用该函数
function PakDownloadMgr._FlushTaskTable(nPackID, bTop)
    if not nPackID then
        return
    end

    local tTask, nIndex = self.GetTask(nPackID)
    local tDownloadInfo = self.GetDownloadingInfo(nPackID)
    if not tDownloadInfo and not tTask then
        return
    end

    local tTaskTable = Storage.Download.tbTaskTable
    if tTask and (not tDownloadInfo or tDownloadInfo.bCancelFlag) then
        --Log("[PakDownloadMgr] FlushTaskTable Remove", nPackID, GetEnumStr(DOWNLOAD_STATE, tTask.nState), nIndex)
        table.remove(tTaskTable[tTask.nState], nIndex)
        self._FlushDownloadStorage()
        return
    end

    if not tDownloadInfo or tDownloadInfo.bCancelFlag then
        return
    end

    --保证nState只有QUEUE/DOWNLOADING/PAUSE/COMPLETE
    local nState
    if tDownloadInfo.bPauseFlag then
        nState = DOWNLOAD_STATE.PAUSE
    elseif tDownloadInfo.nState == DOWNLOAD_STATE.FAILED or tDownloadInfo.nState == DOWNLOAD_STATE.NONE then
        nState = DOWNLOAD_STATE.QUEUE
    else
        nState = tDownloadInfo.nState
    end

    local nInsertIndex = bTop and 1 or (#tTaskTable[nState] + 1)
    local tPakInfo = self.GetPackInfo(nPackID)
    if not tTask then
        tTask = {
            nPackID = nPackID,
            bDynamic = tPakInfo and tPakInfo.bDynamic,
        }
        --Log("[PakDownloadMgr] FlushTaskTable Insert", nPackID, GetEnumStr(DOWNLOAD_STATE, nState))
        table.insert(tTaskTable[nState], nInsertIndex, tTask)
    elseif tTask.nState ~= nState or bTop then
        --Log("[PakDownloadMgr] FlushTaskTable Move", nPackID, GetEnumStr(DOWNLOAD_STATE, tTask.nState), GetEnumStr(DOWNLOAD_STATE, nState))
        table.remove(tTaskTable[tTask.nState], nIndex)
        table.insert(tTaskTable[nState], nInsertIndex, tTask)
    end

    tTask.nState = nState
    self._FlushDownloadStorage()

    --优先下载记录
    if nState == DOWNLOAD_STATE.COMPLETE then
        if tTask.nTriggerType then
            if tTask.nTriggerType == TASK_TRIGGER_TYPE.PRIORITY then
                Storage.PriorityDownload.tbPriority[tTask.nPackID] = true
                Storage.PriorityDownload.Flush()
                self._UpdatePriorityCompleteState()
            elseif tTask.nTriggerType == TASK_TRIGGER_TYPE.DEFAULT then
                Storage.PriorityDownload.tbDefault[tTask.nPackID] = true
                Storage.PriorityDownload.Flush()
            elseif tTask.nTriggerType == TASK_TRIGGER_TYPE.CORE then
                Storage.CoreDownload.tbCore[tTask.nPackID] = true
                Storage.CoreDownload.Flush()
            end
            Storage.AutoDownload.tbPackIDMap[nPackID] = true
            Storage.AutoDownload.Flush()
        end
    end
end

--保存下载队列到本地文件，且避免同帧调多次
function PakDownloadMgr._FlushDownloadStorage(bImmediately)
    if bImmediately then
        self.bFlushingStorage = false
        Storage.Download.Flush()
        return
    end

    if self.bFlushingStorage then
        return
    end

    Storage.Download.Dirty()
    self.bFlushingStorage = true

    Timer.AddFrame(self.tGlobalTimer, 1, function()
        self.bFlushingStorage = false
        Storage.Download.Flush()
    end)
end

function PakDownloadMgr.GetTask(nPackID)
    for _, tTaskList in pairs(Storage.Download.tbTaskTable) do
        for nIndex, tTask in ipairs(tTaskList) do
            if tTask.nPackID == nPackID then
                return tTask, nIndex
            end
        end
    end
end

-------------------------------- Format --------------------------------

local POSTFIX_GB = "GB"
local POSTFIX_MB = "MB"
local POSTFIX_KB = "KB"
local POSTFIX_B = "B"

function PakDownloadMgr.FormatSize(nSize, nDecimal)
    local nGB = math.floor(nSize / 1024 / 1024 / 1024)
    local nMB = math.floor(nSize / 1024 / 1024)
    local nKB = math.floor(nSize / 1024)
    local nB = math.floor(nSize)
    nDecimal = nDecimal or 0 --保留小数点后位数

    --2023.10.16 最大只显示MB
    -- if nGB ~= 0 then
    --     local szGB = string.format("%0." .. nDecimal .. "f%s", nGB, POSTFIX_GB)
    --     return szGB
    -- else
    if nMB ~= 0 then
        if nDecimal == 0 then
            nMB = nMB + 1
        else
            nMB = nSize / 1024 / 1024
        end
        local szMB = string.format("%0." .. nDecimal .. "f%s", nMB, POSTFIX_MB)
        return szMB
    elseif nKB ~= 0 then
        if nDecimal == 0 then
            nKB = nKB + 1
        else
            nKB = nSize / 1024
        end
        local szKB = string.format("%0." .. nDecimal .. "f%s", nKB, POSTFIX_KB)
        return szKB
    else
        return nB .. POSTFIX_B
    end
end

function PakDownloadMgr.FormatTime(nTime)
    local nHour = math.floor(nTime / 60 / 60)
    local nMin = math.floor(nTime / 60)

    if nHour ~= 0 then
        nMin = nMin - 60 * nHour
        return "约" .. nHour .. "小时" .. nMin .. "分钟"
    elseif nMin ~= 0 then
        return "约" .. nMin .. "分钟"
    else
        return "1分钟内"
    end
end

--计算进度，因为计算进度的方式经常改，所以抽成函数了
function PakDownloadMgr.CalcProgress(dwTotalSize, dwDownloadedSize, nTotalFile, nDownloadedFile)
    local nProgressSize = dwTotalSize > 0 and dwDownloadedSize / dwTotalSize or 0
    --local nProgressFile = nTotalFile > 0 and nDownloadedFile / nTotalFile or 0
    return nProgressSize
end

--将tDownloadInfo中的异步复杂状态简化为用于界面显示的简单状态：NONE/QUEUE/DOWNLOADING/PAUSE/COMPLETE
function PakDownloadMgr.GetPackViewState(nPackID)
    local nViewState = DOWNLOAD_STATE.NONE
    local tDownloadInfo = self.GetDownloadingInfo(nPackID)
    if tDownloadInfo then
        if tDownloadInfo.bPauseFlag then
            nViewState = DOWNLOAD_STATE.PAUSE
        elseif tDownloadInfo.nState == DOWNLOAD_STATE.FAILED or tDownloadInfo.nState == DOWNLOAD_STATE.NONE then
            nViewState = DOWNLOAD_STATE.QUEUE
        else
            nViewState = tDownloadInfo.nState
        end
    else
        local nState, _, _ = self.GetPackState(nPackID)
        if nState == DOWNLOAD_OBJECT_STATE.NOTEXIST then
            nViewState = DOWNLOAD_STATE.NONE
        elseif nState == DOWNLOAD_OBJECT_STATE.DOWNLOADING then
            nViewState = DOWNLOAD_STATE.DOWNLOADING
        elseif nState == DOWNLOAD_OBJECT_STATE.PAUSE then
            nViewState = DOWNLOAD_STATE.PAUSE
        elseif nState == DOWNLOAD_OBJECT_STATE.DOWNLOADED then
            nViewState = DOWNLOAD_STATE.COMPLETE
        end
    end
    return nViewState
end

function PakDownloadMgr.GetDeleteState(nPackID)
    local nDelState = RESOURCE_DELETE_STATE.CAN_DELETE

    local tDownloadInfo = self.GetDownloadingInfo(nPackID)
    local bBasic = self.IsBasicPack(nPackID) or self.IsMapInBasicPack(nPackID)
    local bCore = self.IsCorePack(nPackID)
    local nState, dwTotalSize, dwDownloadedSize = self.GetPackState(nPackID)

    if bBasic then
        nDelState = RESOURCE_DELETE_STATE.BASIC_PACK
    elseif bCore then
        nDelState = RESOURCE_DELETE_STATE.CORE_PACK
    elseif nState == DOWNLOAD_OBJECT_STATE.NOTEXIST or (dwTotalSize > 0 and dwDownloadedSize <= 0 and nState == DOWNLOAD_OBJECT_STATE.PAUSE) then
        nDelState = RESOURCE_DELETE_STATE.NOT_EXIST
    -- elseif tDownloadInfo and (tDownloadInfo.nState == DOWNLOAD_STATE.DOWNLOADING or tDownloadInfo.nState == DOWNLOAD_STATE.QUEUE) then
    --     nResult = RESOURCE_DELETE_STATE.DOWNLOADING
    else
        local bPriorityState = self.IsPriorityPack(nPackID) and not Storage.PriorityDownload.tbPriority[nPackID]
        if bPriorityState and nState ~= DOWNLOAD_OBJECT_STATE.DOWNLOADED then
            nDelState = RESOURCE_DELETE_STATE.PRIORITY_PACK
        end

        --当前所在地图的包不能删除
        local player = GetClientPlayer()
        if player then
            local dwMapID = player.GetMapID()
            local nMapPackID = self.GetMapResPackID(dwMapID)
            if nMapPackID == nPackID then
                nDelState = RESOURCE_DELETE_STATE.CURRENT_MAP
            end
        end
    end

    return nDelState
end

function PakDownloadMgr.CheckNetDownload(fnDownload, dwLeftDownloadSize, szContent)
    -- local dwSpace = self._GetRemainStorageSpace()
    -- local dwNeedSpace = dwLeftDownloadSize + STORAGE_SIZE_MARGIN
    -- if dwSpace < dwNeedSpace then
    --     local szError = g_tStrings.tDownloadFailedResult[DOWNLOAD_OBJECT_RESULT.NO_SPACE_FAIL]
    --     TipsHelper.ShowNormalTip("资源下载失败：" .. szError)
    --     return
    -- end

    local nNetMode = App_GetNetMode()
    if nNetMode == NET_MODE.NONE then
        TipsHelper.ShowNormalTip("无法连接服务器，请稍后再试")
    elseif nNetMode == NET_MODE.WIFI or self.GetAllowNotWifiDownload() or (dwLeftDownloadSize and dwLeftDownloadSize <= 0) then
        if fnDownload then
            fnDownload()
        end
    elseif nNetMode == NET_MODE.CELLULAR then
        szContent = szContent or "当前处于移动网络，是否使用流量下载" .. self.FormatSize(dwLeftDownloadSize) .. "的资源文件？"
        local dialog = UIHelper.ShowConfirm(szContent, function()
            -- self.SetAllowNotWifiDownload(true)
            if fnDownload then
                fnDownload()
            end
        end)
        dialog:SetButtonContent("Confirm", "继续下载")
        dialog:SetButtonContent("Cancel", g_tStrings.STR_CANCEL)
    end
end

--资源是否在白名单内
function PakDownloadMgr.IsPackInWhiteList(nPackID, bLog)
    --体服不显示v5里不存在的包
    if IsVersionExp() then
        local _, dwTotalSize, _ = self.GetPackState(nPackID)
        if dwTotalSize <= 0 then
            Log("[Error] Resources does not exist.", nPackID)
            return false
        end
    end

    local bIsMapRes, nMapID = self.IsMapRes(nPackID)
    if bIsMapRes then
        if self.nDownloadSceneResMapID ~= nMapID and not MapHelper.IsMapOpen(nMapID) then
            if bLog then
                local szLog = IsString(bLog) and bLog or "此场景暂未开放资源下载，敬请期待！"
                TipsHelper.ShowNormalTip(szLog)
            end
            return false
        end
    end

    --不支持的设备不显示布料资源包
    if (not QualityMgr.CanEnableClothSimulation()) and nPackID == PakDownloadMgr.ALL_CLOTH_PACKID then
        --如果本地有资源，则需要显示，避免规则变更后无法删除该资源包
        if self.GetPackState(PakDownloadMgr.ALL_CLOTH_PACKID) == DOWNLOAD_OBJECT_STATE.DOWNLOADED then
            return true
        end
        if bLog then
            local szLog = IsString(bLog) and bLog or "本设备不支持布料资源"
            TipsHelper.ShowNormalTip(szLog)
        end
        return false
    end

    return true
end

--运行时判断是否可以下载资源
function PakDownloadMgr.CanDownloadPack(nPackID)
    --布料包
    if nPackID == PakDownloadMgr.ALL_CLOTH_PACKID then
        local bExteriorDownloaded = self.GetPackState(PakDownloadMgr.ALL_EQUIP_PACKID) == DOWNLOAD_OBJECT_STATE.DOWNLOADED
        local bClothEnabled = GameSettingData.GetNewValue(UISettingKey.ClothSimulation)
        return (bExteriorDownloaded and bClothEnabled), bExteriorDownloaded, bClothEnabled
    end
    return true
end

function PakDownloadMgr.CheckCanDownloadClothPack(script, tPackIDList)
    if IsNumber(tPackIDList) then
        tPackIDList = {tPackIDList}
    else
        tPackIDList = tPackIDList or {}
    end

    --特殊处理 布料包前置资源拦截检测
    local bIsClothPack = false
    local bContainsClothPath = table.contain_value(tPackIDList, PakDownloadMgr.ALL_CLOTH_PACKID)
    if bContainsClothPath then
        if #tPackIDList == 1 then
            bIsClothPack = true
        else
            local bHasOtherPack = false
            for _, nPackID in pairs(tPackIDList) do
                if nPackID ~= PakDownloadMgr.ALL_CLOTH_PACKID then
                    local nState, dwTotalSize, dwDownloadedSize = self.GetPackState(nPackID)
                    if nState ~= DOWNLOAD_OBJECT_STATE.DOWNLOADED then
                        bHasOtherPack = true
                        break
                    end
                end
            end
            --判断是否只需要下载布料包
            if not bHasOtherPack then
                bIsClothPack = true
            end
        end
    end

    if not bIsClothPack and not bContainsClothPath then
        return true
    end

    local bCanDownload, bExteriorDownloaded, bClothEnabled = self.CanDownloadPack(PakDownloadMgr.ALL_CLOTH_PACKID)
    if bCanDownload then
        return true
    end

    local tNewPackIDList
    if bContainsClothPath then
        tNewPackIDList = clone(tPackIDList)
        table.remove_value(tNewPackIDList, PakDownloadMgr.ALL_CLOTH_PACKID)
    end

    if not bExteriorDownloaded and not bClothEnabled then
        if bIsClothPack then
            if g_pClientPlayer then
                local szContent = "请在完成<color=#ffe26e>外观基础资源包</color>下载并开启布料效果后，再进行外观布料资源包下载，是否需要下载<color=#ffe26e>外观基础资源包</color>并前往设置<color=#ffe26e>开启布料效果</color>？<font size='20'>\n\n（目前布料效果<color=#ffe26e>仅在地图场景中生效</color>，开启布料效果后将<color=#ffe26e>影响性能效果</color>）</font>"
                local dialog = UIHelper.ShowConfirm(szContent, function()
                    PakSizeQueryMgr.RegQuerySizeCheckNetDownload(script, function()
                        self.DownloadPack(PakDownloadMgr.ALL_EQUIP_PACKID)
                        UIMgr.OpenSingle(true, VIEW_ID.PanelGameSettings, SettingCategory.Quality)
                    end, PakDownloadMgr.ALL_EQUIP_PACKID)
                end, nil, true)
                dialog:SetButtonContent("Confirm", "下载并前往设置")
                dialog:SetButtonContent("Cancel", "取消")
            else
                local szContent = "检测到侠士目前暂未开启布料效果，暂无法下载外观布料资源包。<font size='20'>\n\n目前布料效果<color=#ffe26e>仅在地图场景中生效</color>，开启布料效果后将<color=#ffe26e>影响性能效果</color>；侠士需在进入游戏场景并前往画质设置中开启布料效果后，再进行外观布料资源包下载。</font>"
                local dialog = UIHelper.ShowConfirm(szContent, nil, nil, true)
                dialog:HideCancelButton()
            end
            return false
        elseif bContainsClothPath then
            TipsHelper.ShowNormalTip("请在完成外观基础资源包下载并开启布料效果后，再进行外观布料资源包下载")
            return true, tNewPackIDList
        end
    elseif bExteriorDownloaded and not bClothEnabled then
        if bIsClothPack then
            if g_pClientPlayer then
                local szContent = "请在画质设置中开启布料效果后再进行外观布料资源包下载，是否需要前往设置<color=#ffe26e>开启布料效果</color>？<font size='20'>\n\n（目前布料效果<color=#ffe26e>仅在地图场景中生效</color>，开启布料效果后将<color=#ffe26e>影响性能效果</color>）</font>"
                local dialog = UIHelper.ShowConfirm(szContent, function()
                    UIMgr.OpenSingle(true, VIEW_ID.PanelGameSettings, SettingCategory.Quality)
                end, nil, true)
                dialog:SetButtonContent("Confirm", "前往设置")
                dialog:SetButtonContent("Cancel", "取消")
            else
                local szContent = "检测到侠士目前暂未开启布料效果，暂无法下载外观布料资源包。<font size='20'>\n\n目前布料效果<color=#ffe26e>仅在地图场景中生效</color>，开启布料效果后将<color=#ffe26e>影响性能效果</color>；侠士需在进入游戏场景并前往画质设置中开启布料效果后，再进行外观布料资源包下载。</font>"
                local dialog = UIHelper.ShowConfirm(szContent, nil, nil, true)
                dialog:HideCancelButton()
            end
            return false
        elseif bContainsClothPath then
            TipsHelper.ShowNormalTip("请在画质设置中开启布料效果后，再进行外观布料资源包下载")
            return true, tNewPackIDList
        end
    elseif not bExteriorDownloaded and bClothEnabled then
        if bIsClothPack then
            local szContent = "请在完成<color=#ffe26e>外观基础资源包</color>下载后再进行外观布料资源包下载，是否需要下载<color=#ffe26e>外观基础资源包</color>？<font size='20'>\n\n（目前布料效果<color=#ffe26e>仅在地图场景中生效</color>，开启布料效果后将<color=#ffe26e>影响性能效果</color>）</font>"
            local dialog = UIHelper.ShowConfirm(szContent, function()
                PakSizeQueryMgr.RegQuerySizeCheckNetDownload(script, function()
                    self.DownloadPack(PakDownloadMgr.ALL_EQUIP_PACKID)
                end, PakDownloadMgr.ALL_EQUIP_PACKID)
            end, nil, true)
            dialog:SetButtonContent("Confirm", "确认")
            dialog:SetButtonContent("Cancel", "取消")
            return false
        elseif bContainsClothPath then
            TipsHelper.ShowNormalTip("请在完成外观基础资源包下载后再进行外观布料资源包下载")
            return true, tNewPackIDList
        end
    end

    return true
end

--检测当前登录地图是否可以跳转到无需下载地图的默认地图
function PakDownloadMgr.CheckLoginToDefaultMap(dwMapID, nLevel, dwForceID)
    --排除战场、秘境等有传出惩罚之类的地图(BIRTH_MAP包含小黑屋，也不能传出) -- 2024.6.17 副本也弹窗
    local tMapParams = MapHelper.GetMapParams(dwMapID)
    if --[[tMapParams.nType == MAP_TYPE.DUNGEON or]] tMapParams.nType == MAP_TYPE.BATTLE_FIELD or tMapParams.nType == MAP_TYPE.BIRTH_MAP then
        return false
    end

    --排除门派场景
    if nLevel and dwForceID then
        if nLevel < 120 then
            local tForceMapID = ForceIDToMapID[dwForceID]
            tForceMapID = IsTable(tForceMapID) and tForceMapID or {tForceMapID}
            if table.contain_value(tForceMapID, dwMapID) then
                return false
            end
        end
    end

    local tSkipMap = {
        -- 6,      -- 扬州
        -- 108,    -- 成都
        -- 194,    -- 太原
        332,    -- 侠客岛
        579,    -- 百溪
    }

    --排除部分地图
    if table.contain_value(tSkipMap, dwMapID) then
        return false
    end

    return true
end

--GM 资源下载统计
function PakDownloadMgr.SetStatisticsEnabled(bEnabled)
    local szContent = (bEnabled and "开始" or "结束") .. "资源下载流量统计"
    OutputMessage("MSG_SYS", szContent)
    Log(szContent)
    if bEnabled then
        self.tStatistics = {}
    else
        for nPackID, _ in pairs(self.tStatistics) do
            self.LogStatistics(nPackID)
        end
        self.tStatistics = nil
    end
end

function PakDownloadMgr.LogStatistics(nPackID)
    if self.tStatistics and self.tStatistics[nPackID] then
        local tPackInfo = self.GetPackInfo(nPackID)
        local szName = tPackInfo and tPackInfo.szName or ""
        local szContent = string.format("[%s]%s: %s", tostring(nPackID), szName, self.FormatSize(self.tStatistics[nPackID]))
        OutputMessage("MSG_SYS", szContent)
        Log(szContent)
    end
end

-- 0:无网络, 1:WIFI, 2:移动网络
function PakDownloadMgr.DebugSetNetMode(nNetMode)
    App_GetNetMode = function() return nNetMode end
    Event.Dispatch("OnNetModeChanged", nNetMode)
end

function PakDownloadMgr.DebugSetEnableBasicPack(bEnabled)
    ENABLED_BASIC_DOWNLOAD = bEnabled
end

function PakDownloadMgr.DebugSetEnableCorePack(bEnabled)
    ENABLED_CORE_DOWNLOAD = bEnabled
end

function PakDownloadMgr.DebugSetEnableUIUpdate(bEnabled)
    ENABLED_UI_UPDATE = bEnabled
end

function PakDownloadMgr.DebugSetPackDownloaded(nPackID, bDownloaded)
    if bDownloaded == nil then
        bDownloaded = true
    end
    DEBUG_DOWNLOADED_PACK[nPackID] = bDownloaded
end

function PakDownloadMgr.SetDebugMode(bDebug)
    m_bDebug = bDebug
end

function PakDownloadMgr.IsUIUpdateEnabled()
    return ENABLED_UI_UPDATE
end