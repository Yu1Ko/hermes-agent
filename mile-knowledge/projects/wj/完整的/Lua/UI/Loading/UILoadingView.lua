local UILoadingView = class("UILoadingView")

local LOADING_TIME_OUT = 30   -- 最大加载场景时长（秒）
local DEFAULT_BG_IMG_PATH = "Texture/LoadingMap/Loading_CY.png"
local DOWNLOAD_TOTAL_PROGRESS = 100 -- 备用，下载所占进度条的百分比

function UILoadingView:OnEnter(nMapID, szPath, nFromMapID)
    SoundMgr.LockBgMusic(false)
    SoundMgr.StopBgMusic()
    self.nMapID = nMapID
    self.szPath = szPath
    self.nFromMapID = nFromMapID

    if self.nMapID == nil and self.szPath == nil then
        self:InitBgImg()
        UIHelper.SetString(self.LabelBar, "")
        UIHelper.SetString(self.LabelBar02, "")
        return
    end

    self.bPlayerEnterScene = false
    self.bXGTrackEvent = false
    self.bIsMainSubMapRelation = HaveMainSubMapRelation(self.nMapID, self.nFromMapID)

    SceneMgr.SetIsLoading(true)
    SceneMgr.SetLoadingIsMainSubMap(self.bIsMainSubMapRelation)
    self:PauseAllSound()

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    if not szPath and nMapID then
        local tbMapParams = MapHelper.GetMapParams(nMapID)
        szPath = tbMapParams and tbMapParams.szDir
    end

    LOG.INFO("[UILoadingView] MapID: %d, Map Path: %s", nMapID or -1, GBKToUTF8(szPath or ""))

    -- 主线支线关系的地图直接播放云雾特效，不显示Loading界面
    self:PlaySfx()

    self:InitBgImg(nMapID, szPath)
    self:InitMsgText(szPath)
    --self:InitStoryText(szPath)

    self:UpdateInfo()

    Event.Dispatch(EventType.UILoadingStart, nMapID)
end

function UILoadingView:OnExit()
    SceneMgr.SetIsLoading(false)
    SceneMgr.SetLoadingIsMainSubMap(false)
    self:ResumeAllSound()
    UIMgr.ShowLayer(UILayer.Scene, nil, true)
    Event.Dispatch(EventType.UILoadingFinish, self.nMapID)
end

function UILoadingView:PauseAllSound()
    if self.nMapID == nil then return end
    self.bTempIsEnableAllSound = IsEnableAllSound()
    SetTotalVolume(0)
end

function UILoadingView:ResumeAllSound()
    if self.nMapID == nil then return end
    local nMainSound = GameSettingData.GetSoundSliderValue(SOUND.MAIN)
    if nMainSound then
        SetTotalVolume(nMainSound)
    else
        SetTotalVolume(1.0)
    end
end

function UILoadingView:PlaySfx()
    UIHelper.SetVisible(self.Eff_Loading, false)

    if not self.bIsMainSubMapRelation then
        return
    end

    UIHelper.SetVisible(self.Eff_Loading, true)

    UIHelper.SetVisible(self.ImgBg, false)
    UIHelper.SetVisible(self.LabelBar02, false)
    UIHelper.SetVisible(self.widgetContainer, false)
end

function UILoadingView:BindUIEvent()

end

function UILoadingView:RegEvent()
    Event.Reg(self, EventType.OnClientPlayerEnter, function()
        self.bPlayerEnterScene = true
    end)

    Event.Reg(self, "COMMON_CALL_BACK", function()
        if arg0 == "GetSceneLoadingProcess" then
            local fProcess = arg2
            local nProcess = math.floor(fProcess * 100)
            if self.bLoadingTimeOut then
                nProcess = 100
            end

            -- 假如出现倒退进度，且差值小于25%的话，则不变进度等待即可
            if nProcess < self.nSceneLoadPercent and math.abs(nProcess - self.nSceneLoadPercent) <= 25 then

            else
                self.nSceneLoadPercent = nProcess
            end

            if not self.bPlayerEnterScene then
                self.nSceneLoadPercent = math.min(99, self.nSceneLoadPercent)
            end

        end
    end)
end

function UILoadingView:UnRegEvent()

end

function UILoadingView:InitBgImg(nMapID, szPath)
    local szName = nMapID and Table_GetMapName(nMapID) or ""
    UIHelper.SetString(self.LabelMapName, UIHelper.GBKToUTF8(szName))
    UIHelper.SetString(self.LabelMapNameBg, UIHelper.GBKToUTF8(szName))

    -- 背景只设置一次，因为外面会多次调用过来，这里也是为了避免加载场景盖不住的问题
    if self.bHasSetTex then
        return
    end

    local szImgPath = DEFAULT_BG_IMG_PATH

    --新号第一次进图，使用门派对应的Loading图
    local moduleEnterGame = LoginMgr.GetModule(LoginModule.LOGIN_ENTERGAME)
    local tEnterGameRoleInfo = moduleEnterGame.GetEnterGameRoleInfo()
    if tEnterGameRoleInfo then
        local dwForceID = tEnterGameRoleInfo.dwForceID
        local nTotalGameTime = tEnterGameRoleInfo.nTotalGameTime
        if nTotalGameTime <= 0 then
            local szImgPath = g_tLoad.tForceIDToImg[dwForceID]
            --print("[Loading] SetTexture: ", szImgPath)
            UIHelper.SetTexture(self.ImgBg, szImgPath, false)
            self.bHasSetTex = true
            return
        end
    end

    --显示当前进入地图对应的图片
    -- local ini = Ini.Open(szPath .. "minimap\\config.ini")
    -- if ini then
    --     local szLoadingPath = ini:ReadString("loading", "image", "")
    --     --print("[Loading] szLoadingPath: ", szLoadingPath)
    --     if szLoadingPath and #szLoadingPath > 0 then
    --         szImgPath = szPath .. "minimap\\" .. string.gsub(szLoadingPath, ".dds", ".png")
    --     end
    -- end

    -- 随机显示
    local szMapType = MapHelper.GetMapNewType(nMapID)
    local tbRandom = g_tLoad.aLoadingImgList[szMapType]
    if not tbRandom then
        tbRandom = g_tLoad.aLoadingImgList["其它"]
    end
    LOG.INFO("[Loading] MapType: %s, nMapID: %s", szMapType or "", tostring(nMapID))
    if tbRandom then
        local nIndex = math.random(1, #tbRandom)
        szImgPath = tbRandom[nIndex]
    end

    --print("[Loading] SetTexture: ", szImgPath)
    UIHelper.SetTexture(self.ImgBg, szImgPath, false)
    self.bHasSetTex = true
end

function UILoadingView:InitMsgText(szPath)
    local szTipPath = szPath and szPath .. "minimap_mb\\loadingtip.tab"
    local szMsg = self:LoadUIText(szTipPath)

    if not szMsg or szMsg == "" then
        szMsg = self:GetLoadingMsg(not LoginMgr.IsLogin())
    end
    szMsg = szMsg or ""
    UIHelper.SetString(self.LabelBar02, szMsg)

end

function UILoadingView:InitStoryText(szPath)
    local szStoryPath = szPath and szPath .. "minimap_mb\\loadingstory.tab"
    local szStory = self:LoadUIText(szStoryPath)

    if not szStory or szStory == "" then
        szStory = self:GetLoadingStory()
    end
    szStory = szStory or ""
    UIHelper.SetString(self.LabelStory, szStory)
end

function UILoadingView:LoadUIText(szTabPath)
    if not szTabPath then
        return
    end

    local szText = ""
    if szTabPath and Lib.IsFileExist(szTabPath) then
        local tTab = KG_Table.Load(szTabPath, { { f = "S", t = "szText" } }, TABLE_FILE_OPEN_MODE.NORMAL)
        if tTab then
            local nCount = tTab:GetRowCount()
            local tRow = tTab:GetRow(math.random(1, nCount))
            if tRow then
                szText = tRow.szText
                szText = string.pure_text(szText)
                szText = string.gsub(szText, "\\", "\n") or szText
                szText = UIHelper.GBKToUTF8(szText)
            end
            tTab = nil
        end
    end
    return szText
end

function UILoadingView:GetLoadingMsg(bOnlyLoading)
    local nPos = math.random(1, #(g_tLoad.aLoadingMsg))
    nPos = math.floor(nPos)
    return g_tLoad.aLoadingMsg[nPos]

    -- TODO 若已登录，加载后还会显示部分按键提示文本
    -- if bOnlyLoading then
    -- 	local nPos = math.random(1, #(g_tLoad.aLoadingMsg))
    -- 	nPos = math.floor(nPos)
    -- 	return g_tLoad.aLoadingMsg[nPos]
    -- end
    -- local nCount = #(g_tLoad.aLoadingMsg) + #(g_tLoad.aHotkeyMsg)
    -- local nPos = math.random(1, nCount)
    -- nPos = math.floor(nPos)
    -- if nPos > #(g_tLoad.aLoadingMsg) then
    -- 	nPos = nPos - #g_tLoad.aLoadingMsg
    -- 	local szMsg = g_tLoad.aHotkeyMsg[nPos]
    -- 	szMsg = string.gsub(szMsg, "<KEY (.-)>", Helper.GetHotkey) --TODO
    -- 	return szMsg
    -- end
    -- return g_tLoad.aLoadingMsg[nPos]
end

function UILoadingView:GetLoadingStory()
    local nPos = math.random(1, #(g_tLoad.aStory))
    nPos = math.floor(nPos)
    return g_tLoad.aStory[nPos]
end

function UILoadingView:UpdateInfo()
    UIHelper.SetProgressBarPercent(self.ProgressBar, 0)
    Timer.DelAllTimer(self)
    self.bUpdateLastFrame = false
    self.nPercent = 0
    self.nSceneLoadPercent = 0
    self:UpdateProgress()

    --判断当前地图是否已下载，若未下载则在Loading界面等
    if self.nMapID and PakDownloadMgr.IsEnabled() then
        if not self.bXGTrackEvent  then
            XGSDK_TrackEvent("game.check.scene.pak", "login", {})
            self.bXGTrackEvent = true
        end
        local nPackID = PakDownloadMgr.GetMapResPackID(self.nMapID)
        local nPackState, _, _ = PakDownloadMgr.GetPackState(nPackID)
        if nPackState ~= DOWNLOAD_OBJECT_STATE.DOWNLOADED then
            local nState, dwTotalSize, dwDownloadedSize = PakDownloadMgr.GetMapResPackState(self.nMapID)
            if nState ~= DOWNLOAD_OBJECT_STATE.DOWNLOADED and dwTotalSize > 0 and dwDownloadedSize < dwTotalSize then
                self:UpdateDownload()
                return
            end
        end
    end

    if self.nPercent == 0 then
        Event.Dispatch(EventType.UILoadingProgressBegin)
    end

    self.bLoadingTimeOut = false

    if self.nLoadingTimeOutTimerID then
        Timer.DelTimer(self, self.nLoadingTimeOutTimerID)
        self.nLoadingTimeOutTimerID = nil
    end
    self.nLoadingTimeOutTimerID = Timer.Add(self, LOADING_TIME_OUT, function ()
        self.bLoadingTimeOut = true
    end)

    local bIsSwitchEngineOptions = false
    self:StartFakeProgressing(
        function()  --fnPause
            local nPercent = math.min(self.nSceneLoadPercent, self.nPercent)

            if nPercent >= 50 and not bIsSwitchEngineOptions then
                bIsSwitchEngineOptions = true
                QualityMgr.TrySwitchEngineOptions()
            end

            return nPercent >= 90 and not self.bPlayerEnterScene
        end,
        function()  --fnStop
            local nPercent = math.min(self.nSceneLoadPercent, self.nPercent)
            return nPercent >= 100
        end,
        function()  --fnOnComplete
            self:OnLoadingEnd()
        end
    )
end

function UILoadingView:UpdateDownload()
    local _, dwTotalSize, dwDownloadedSize = PakDownloadMgr.GetMapResPackState(self.nMapID)
    if dwDownloadedSize < dwTotalSize then
        --如果上次没下载完，获取下载进度会获取到大于0的值，策划不想进度条突然跳过去，
        --所以这里先跑假进度，当假进度追上真进度的时候再用真进度显示
        self:StartFakeProgressing(
            nil, --fnPause
            function()
                --fnStop
                local _, dwTotalSize, dwDownloadedSize, nTotalFile, nDownloadedFile = PakDownloadMgr.GetMapResPackState(self.nMapID)
                local nProgress = DOWNLOAD_TOTAL_PROGRESS * PakDownloadMgr.CalcProgress(dwTotalSize, dwDownloadedSize, nTotalFile, nDownloadedFile)
                self.nSceneLoadPercent = self.nPercent
                return self.nPercent >= nProgress --判断假进度是否追上真进度
            end,
            function()
                --fnOnComplete
                local nPackID = PakDownloadMgr.GetMapResPackID(self.nMapID)
                Timer.AddFrameCycle(self, 1, function()
                    --假进度追上后，这里再每帧更新显示实际的下载进度
                    local nState, dwTotalSize, dwDownloadedSize, nTotalFile, nDownloadedFile = PakDownloadMgr.GetMapResPackState(self.nMapID)
                    if nState ~= DOWNLOAD_OBJECT_STATE.DOWNLOADED then
                        local tDownloadInfo = PakDownloadMgr.GetDownloadingInfo(nPackID)
                        --local dwDownloadSpeed = tDownloadInfo and tDownloadInfo.dwDownloadSpeed or 0
                        local dwDownloadSpeed = PakDownloadMgr.GetPackDownloadSpeed(nPackID)
                        self.nPercent = DOWNLOAD_TOTAL_PROGRESS * PakDownloadMgr.CalcProgress(dwTotalSize, dwDownloadedSize, nTotalFile, nDownloadedFile)
                        self.nSceneLoadPercent = self.nPercent

                        local szContent = "正在下载场景资源：" ..
                                PakDownloadMgr.FormatSize(dwDownloadedSize) .. "/" .. PakDownloadMgr.FormatSize(dwTotalSize) ..
                                "（下载速度：" .. PakDownloadMgr.FormatSize(dwDownloadSpeed, 2) .. "/s） "

                        UIHelper.SetString(self.LabelBar02, szContent)
                        self:UpdateProgress()
                    elseif self.nPercent < DOWNLOAD_TOTAL_PROGRESS then
                        self.nPercent = self.nPercent + 1
                        self.nSceneLoadPercent = self.nPercent

                        local szContent = "正在解压资源"
                        UIHelper.SetString(self.LabelBar02, szContent)
                        self:UpdateProgress()
                    else
                        UIHelper.SetString(self.LabelBar02, "场景资源已下载完成，正在进入场景...")
                        self:UpdateInfo() --下载完成后再走普通的进度等场景加载，这个里面已有DelAllTimer
                    end
                end)
            end
        )
    else
        Timer.AddFrameCycle(self, 1, function()
            local nState, dwTotalSize, dwDownloadedSize = PakDownloadMgr.GetMapResPackState(self.nMapID)
            if nState ~= DOWNLOAD_OBJECT_STATE.DOWNLOADED then
                local szContent = "正在解压资源"
                UIHelper.SetString(self.LabelBar02, szContent)
                self:UpdateProgress()
            else
                UIHelper.SetString(self.LabelBar02, "正在进入场景...")
                self:UpdateInfo() --下载完成后再走普通的进度等场景加载，这个里面已有DelAllTimer
            end
        end)
    end
end

function UILoadingView:OnLoadingEnd()
    if not g_pClientPlayer or not SceneMgr.GetCurSceneID() then
        local confirm = UIHelper.ShowSystemConfirm("当前网络不稳定，请重新登录", function()
            Global.BackToLogin(false)
        end)

        confirm:HideButton("Cancel")
        return
    end

    if not LoginMgr.bFirstLoadEnding then
        LoginMgr.bFirstLoadEnding = true
        Event.Dispatch("FIRST_LOADING_END")
        XGSDK_TrackEvent("game.first.load.ending", "loading", {})
    end

    if self.bPlayerEnterScene then
        Event.Dispatch("LOADING_END")
        rlcmd("ui loading end")
        self:Finish()
    end
end

function UILoadingView:StartFakeProgressing(fnPause, fnStop, fnOnComplete)
    self.nFakeProgressTimerID = Timer.AddFrameCycle(self, 2, function()
        if fnStop and fnStop() then
            --判断是否满足结束条件
            Timer.DelTimer(self, self.nFakeProgressTimerID)
            if fnOnComplete then
                fnOnComplete() --结束，调用完成function
            end
        end

        if fnPause and fnPause() then
            --判断是否暂停
            return
        end

        local logicScene = GetClientScene()
        if logicScene then
            local ret = GetSceneLoadingProcess(logicScene.dwID)
            if ret == "_error0" then
                self.nSceneLoadPercent = self.nSceneLoadPercent + 1
            end
        end

        self.nPercent = self.nPercent + 1
        self:UpdateProgress()
    end)
end

function UILoadingView:UpdateProgress()
    local nPercent = math.min(self.nSceneLoadPercent, self.nPercent)
    local nCurPercent = UIHelper.GetProgressBarPercent(self.ProgressBar)

    local nLabelWidth = UIHelper.GetWidth(self.LabelMapName)
    self.nScrollWidth = self.nScrollWidth or UIHelper.GetWidth(self.ScrollViewSlipLabel)
    UIHelper.SetPositionX(self.ScrollViewSlipLabel, 3.5 - (nLabelWidth - self.nScrollWidth))

    UIHelper.SetProgressBarPercent(self.ProgressBar, math.max(nPercent, nCurPercent))
    UIHelper.SetWidth(self.ScrollViewSlipLabel, nLabelWidth * math.max(nPercent, nCurPercent) * 0.01)
    --隔帧更新
    if not self.bUpdateLastFrame then
        UIHelper.SetString(self.LabelBar, string.format("%d%%", math.max(nPercent, nCurPercent)))
        self.bUpdateLastFrame = true
    else
        self.bUpdateLastFrame = false
    end
end

function UILoadingView:Finish()
    -- 播放 稻香秘事 视频
    -- 获取玩家的上次存盘时间, 为 0 表示第一次登录
    local nLastSaveTime = g_pClientPlayer and g_pClientPlayer.GetLastSaveTime() or -1
	if nLastSaveTime == 0 then
        local szPath = FIRST_MOVIE[g_pClientPlayer.nRoleType or ROLE_TYPE.STANDARD_MALE]
        if szPath and not g_FirstMoviePlayed then

            if Platform.IsMobile() then
                szPath = string.format(szPath , "MOBILE")
            else
                szPath = string.format(szPath , "PC")
            end

            MovieMgr.PlayVideo(szPath, {bNet = false}, {szMoviePath = szPath}, true)
            g_FirstMoviePlayed = true
        end
    end

    UIMgr.Close(self)
end

return UILoadingView