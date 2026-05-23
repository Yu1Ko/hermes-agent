-- 全屏视频播放窗口

--错误代码
-- AVERROR_BSF_NOT_FOUND: -1179861752
-- AVERROR_BUG: -558323010
-- AVERROR_BUFFER_TOO_SMALL: -1397118274
-- AVERROR_DECODER_NOT_FOUND: -1128613112
-- AVERROR_DEMUXER_NOT_FOUND: -1296385272
-- AVERROR_ENCODER_NOT_FOUND: -1129203192
-- AVERROR_EOF: -541478725
-- AVERROR_EXIT: -1414092869
-- AVERROR_EXTERNAL: -542398533
-- AVERROR_FILTER_NOT_FOUND: -1279870712
-- AVERROR_INVALIDDATA: -1094995529
-- AVERROR_MUXER_NOT_FOUND: -1481985528
-- AVERROR_OPTION_NOT_FOUND: -1414549496
-- AVERROR_PATCHWELCOME: -1163346256
-- AVERROR_PROTOCOL_NOT_FOUND: -1330794744
-- AVERROR_STREAM_NOT_FOUND: -1381258232
-- AVERROR_BUG2 = -541545794
-- AVERROR_UNKNOWN = -1313558101
-- AVERROR_EXPERIMENTAL = -733130664
-- AVERROR_INPUT_CHANGED = -1668179713
-- AVERROR_OUTPUT_CHANGED = -1668179714
-- AVERROR_HTTP_BAD_REQUEST = -808465656
-- AVERROR_HTTP_UNAUTHORIZED = -825242872
-- AVERROR_HTTP_FORBIDDEN = -858797304
-- AVERROR_HTTP_NOT_FOUND = -875574520
-- AVERROR_HTTP_OTHER_4XX = -1482175736
-- AVERROR_HTTP_SERVER_ERROR = -1482175992


local UICoinShopFadeInVideoPlayer = class("UICoinShopFadeInVideoPlayer")
local m_tbLayerIgnoreIDs =
{
    [UILayer.Tips] = {VIEW_ID.PanelNodeExplorer},
    [UILayer.Top] = {VIEW_ID.PanelGamepadCursor},
}
function UICoinShopFadeInVideoPlayer:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        self.szUrl = ""
    end
    self.nOldFpsLimit = nil
    UIHelper.SetVisible(self.nodeWin, false)
    UIHelper.SetVisible(self.labelTest, false)
    ShortcutInteractionData.SetEnableKeyBoard(false)
    self:OpenButtonHideState()
    self:HideLayer()
end

function UICoinShopFadeInVideoPlayer:OnExit()
    ShortcutInteractionData.SetEnableKeyBoard(true)
    for k, nPackID in pairs(self.tbPauseAllPackIDs) do
        PakDownloadMgr.ResumePack(nPackID)
    end

    self.bInit = false
    if self.fnEndCall then
        self.fnEndCall(self.bNormalEnd)
    end

    self:SettingSound(true)
    if self.bIsEnableDynamicFps then
        FrameMgr.StartDynamicFps()
    end
    if self.nOldFpsLimit then
        FrameMgr.SetFrameLimit(self.nOldFpsLimit)
    end
    self:ShowLayer()
end

function UICoinShopFadeInVideoPlayer:BindUIEvent()
    UIHelper.BindUIEvent(self.btnClose, EventType.OnClick, function ()
        self:Close()
    end)

    UIHelper.BindUIEvent(self.btnSkip, EventType.OnClick, function ()
        if self.bPlayError then
            self:DelayCloseView()
            return
        end
        if not self.bLoadingData then
            self.videoPlayer:pause()
        end
        self.bClickSkip = true
        UIHelper.ShowConfirm(g_tStrings.STR_COMFIRM_SKIP_STORY_DISPLAY, function ()
            self.bClickSkip = false
            self:WaitCloseView()
        end , function ()
            self.bClickSkip = false
            self.videoPlayer:resume()
        end)
    end)

    UIHelper.BindUIEvent(self.btnOpen, EventType.OnClick, function ()
        if not  self.bButtonLayoutOpen then
            self:OpenButtonHideState()
        end
    end)

    -- 注册播放事件
    self.videoPlayer:addEventListener(function (_, nEvent , msg)
        if nEvent == 0 then     -- playing
            local strSplit = string.split(msg , "|")
            local byteSize = tonumber(strSplit[1])
            local nNetMode = App_GetNetMode()
            if nNetMode == NET_MODE.CELLULAR then
                if byteSize > 1024*1024 then
                    local memsize ,szUnit = FormatByteSize(byteSize)
                    UIHelper.SetString(self.label_memsize , string.format( "本次播放将消耗流量:%.1f%s", memsize,szUnit))
                end
            end
            if table.get_len(strSplit) == 3 and self.tConfig.bEnableAdjust then
                self.tVideoSize =
                {
                    width = tonumber(strSplit[2]),
                    height = tonumber(strSplit[3]),
                }
                self:AdjustViewScale()
            end

            if self.bWaitCloseView then
                Timer.Add(self , 0.2 , function ()
                    UIHelper.StopVideo(self.videoPlayer)
                end)
                self.bWaitCloseView = false
            end
            UIHelper.SetVisible(self.WidgetLoading , false)
        elseif nEvent == 1 then -- pause
            LOG.INFO("video player status:pause")
        elseif nEvent == 2 then -- stopeed
            LOG.INFO("video player status:stopeed")
            self:DelayCloseView()
        elseif nEvent == 3 then -- completed
            if self.bReconnection then
                Timer.Add(self , 0.2 , function ()
                    self:Play(self.szUrl, self.tConfig, self.fnEndCall)
                end)
                self.bReconnection = false
            else
                self.bNormalEnd = true
                self:DelayCloseView()
            end
        elseif nEvent == 4 then -- error
            self.bNormalEnd = true
            if self.bWaitCloseView then
                self:DelayCloseView()
                self.bWaitCloseView = false
            else
                if string.find(msg , "open_input error") then
                    UIHelper.ShowConfirm("视频错误,请检查并重试", function()
                        self:DelayCloseView()
                    end, function()
                        self:DelayCloseView()
                    end)
                    self.bPlayError = true
                else
                    UIHelper.ShowConfirm("视频加载失败，可能是由于您的网络连接不稳定。是否要重新播放？", function()
                        self.bReconnection = true
                        Timer.Add(self , 0.2 , function ()
                            UIHelper.StopVideo(self.videoPlayer)
                        end)
                    end,function ()
                        self:DelayCloseView()
                    end)
                end
            end
        elseif nEvent == 5 then -- pre load completed
            self.bLoadingData = false
            if self.bClickSkip then
                Timer.AddFrame(self , 2 , function ()
                    self.videoPlayer:pause()
                end)
            end
            UIHelper.SetVisible(self.WidgetLoading , false)
        elseif nEvent == 6 then -- pre loading
            self.bLoadingData = true
            UIHelper.SetVisible(self.WidgetLoading , true)
        end
    end)

end
function UICoinShopFadeInVideoPlayer:DelayCloseView()
    Timer.Add(self , 0.2 , function ()
        UIMgr.Close(self)
    end)
end

function UICoinShopFadeInVideoPlayer:RegEvent()
    Event.Reg(self , EventType.OnViewOpen , function(nViewID)

        if nViewID == self._nViewID then
            return
        end

        if self:IsHideInvalidView(nViewID) then
            local tbViewInfo = UIMgr.GetView(nViewID)
            if tbViewInfo then
               UIHelper.SetVisible(tbViewInfo.node, false)
            end
        end
    end)

    Event.Reg(self, EventType.OnKeyboardDown, function(nKeyCode, szKey)
        if nKeyCode == cc.KeyCode.KEY_ESCAPE then
            if self.bIsStory and (not self.bClickSkip) and (not self.bWaitCloseView) and (not self.bClickESC)  then
                if not self.bLoadingData then
                    self.videoPlayer:pause()
                end
                self.bClickESC = true
                self.bClickSkip = true
                UIHelper.ShowConfirm(g_tStrings.STR_COMFIRM_SKIP_STORY_DISPLAY, function ()
                    self.bClickSkip = false
                    self:WaitCloseView()
                end , function ()
                    self.bClickSkip = false
                    self.videoPlayer:resume()
                    self.bClickESC = false
                end)
            end
        end
    end)
end

function UICoinShopFadeInVideoPlayer:Play(szUrl, tConfig, fnEndCall)
    self.szUrl = szUrl
    self.bNormalEnd = false
    self.fnEndCall = fnEndCall
    self.tConfig = tConfig
    self.bIsOnlineVideo = string.starts(szUrl, "http")
    self.bReconnection = false
    self.bPlayError = false
    UIHelper.SetVisible(self.WidgetLoading , self.bIsOnlineVideo)
    UIHelper.SetActiveAndCache(self,self.videoPlayer,true)
    UIHelper.SetString(self.label_memsize , "")
    LOG.INFO("播放视频, url:%s", szUrl)
    if Platform.IsAndroid() then
        szUrl = string.gsub(szUrl,"https","http")
    end
    self.tbPauseAllPackIDs = {}

    if FrameMgr.nDynamicFpsTimerID then
        self.bIsEnableDynamicFps = true
    else
        self.bIsEnableDynamicFps = false
    end
    self.nOldFpsLimit = FrameMgr.GetFrameLimit()
    FrameMgr.StopDynamicFps()
    FrameMgr.SetFrameLimit(45)

    if tConfig.bNet then
        szUrl = MovieMgr.ParseStaticUrl(szUrl)
        self.tbPauseAllPackIDs = PakDownloadMgr.PauseAllPack(function ()
            UIHelper.PlayVideo(self.videoPlayer, szUrl, false)
            if self.tConfig.bImmeClose then
                self:Close()
            elseif self.tConfig.bWaitClose then
                self:WaitCloseView()
            end
        end)
    else
        UIHelper.PlayVideo(self.videoPlayer, szUrl, true)
    end
    self.fGlobalAllSountVolume = 1
    local nMainSound = GameSettingData.GetSoundSliderValue(SOUND.MAIN)
    if nMainSound then
        self.fGlobalAllSountVolume = nMainSound
    end
    self:SettingSound(false)

    -- local bCanStop = true
    -- if IsBoolean(tConfig.bCanStop) then
    --     bCanStop = tConfig.bCanStop
    -- end
    UIHelper.SetVisible(self.btnSkip , self.bIsStory)
    UIHelper.SetVisible(self.btnClose , not self.bIsStory)
    UIHelper.LayoutDoLayout(self.LayoutBtn)
    self:DoFadeOut()
end

function UICoinShopFadeInVideoPlayer:SetStoryState(bIsStory)
    self.bIsStory = bIsStory
end

function UICoinShopFadeInVideoPlayer:Close()
    if self.videoPlayer:isPlaying() then
        self.videoPlayer:stop()
    else
        self:DelayCloseView()
    end
end

function UICoinShopFadeInVideoPlayer:WaitCloseView()
    if self.videoPlayer:isPlaying() then
        self.videoPlayer:stop()
    else
        self.bWaitCloseView = true
    end
end

function UICoinShopFadeInVideoPlayer:OpenButtonHideState()
    self.bButtonLayoutOpen = true
    UIHelper.SetVisible(self.LayoutBtn , true)
    Timer.Add(self , 5 , function ()
        UIHelper.SetVisible(self.LayoutBtn , false)
        self.bButtonLayoutOpen = false
    end)
end

function UICoinShopFadeInVideoPlayer:AdjustViewScale()
    local nodeW , nodeH =  UIHelper.GetContentSize(self._rootNode)
    local fScale = self.tVideoSize.width / nodeW
    local newHeight = self.tVideoSize.height / fScale
    UIHelper.SetContentSize(self.videoPlayer , nodeW , newHeight)
end

function UICoinShopFadeInVideoPlayer:SettingSound(bEnable)
    if bEnable then
        SetTotalVolume(self.fGlobalAllSountVolume)
    else
        SetTotalVolume(0)
    end
end

function UICoinShopFadeInVideoPlayer:HideLayer()
    for layer , tbIgnoreViewIDs in pairs(m_tbLayerIgnoreIDs) do
        UIMgr.SetShowAllInLayer(layer, false, tbIgnoreViewIDs)
    end
end

function UICoinShopFadeInVideoPlayer:ShowLayer()
    for layer , tbIgnoreViewIDs in pairs(m_tbLayerIgnoreIDs) do
        UIMgr.SetShowAllInLayer(layer, true, tbIgnoreViewIDs)
    end
end

function UICoinShopFadeInVideoPlayer:IsHideInvalidView(nViewID)
    local isHide = false
    local szLayer = UIMgr.GetViewLayerByViewID(nViewID)
    for layer , tbIgnoreViewIDs in pairs(m_tbLayerIgnoreIDs) do
        if layer == szLayer then
            isHide = not table.contain_value(tbIgnoreViewIDs, nViewID)
            break
        end
    end
    return isHide
end

function UICoinShopFadeInVideoPlayer:DoFadeOut()
    UIHelper.SetVisible(self._rootNode, true)
end
return UICoinShopFadeInVideoPlayer