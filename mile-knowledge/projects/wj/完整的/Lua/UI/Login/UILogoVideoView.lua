-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UILogoVideoView
-- Date: 2022-11-29 14:59:29
-- Desc: 登录Logo、健康游戏忠告界面 PanelLogoVideo
-- ---------------------------------------------------------------------------------

local UILogoVideoView = class("UILogoVideoView")

local m_bIsVideoPlaying

local m_tOrComSize = {width=1600, height=900}

function UILogoVideoView:OnEnter(fnCompleteCallback, szUrl, bIsLocal, bLoop)
    m_bIsVideoPlaying = false
    
    m_tOrComSize.width, m_tOrComSize.height = UIHelper.GetContentSize(self.VideoPlayer)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self.fnCompleteCallback = fnCompleteCallback
        self.szUrl = szUrl
        self.bIsLocal = bIsLocal
        self.bLoop = bLoop

        self:StartPlay()
    end
end

function UILogoVideoView:StartPlay()
    if APIHelper.IsMinimize() then
        self.bWaitPlay = true
        return
    end

    if not self.szUrl then
        self:PlayLogoVideo()
    else
        if not g_LoginVideoHasFirsstPlay then
            self:PlayVideo(self.szUrl, self.bIsLocal, self.fnCompleteCallback, self.bLoop)
            g_LoginVideoHasFirsstPlay = true
        else
            self:PlayVideo(self.szUrl, self.bIsLocal, self.fnCompleteCallback, self.bLoop)
        end
    end
end

function UILogoVideoView:PlayEnter(szPath)
    local szEnterPath = string.format(szPath, "Enter")
    UIHelper.PlayVideo(self.VideoPlayer, szEnterPath, true, function(nVideoPlayerEvent, szMsg)
        if nVideoPlayerEvent == ccui.VideoPlayerEvent.COMPLETED then
            self:PlayLoop(szPath)
        elseif nVideoPlayerEvent == ccui.VideoPlayerEvent.ERROR then
            TipsHelper.ShowNormalTip("视频播放错误："..tostring(szMsg))
        end
    end)
end

function UILogoVideoView:PlayLoop(szPath)
    local szLoopPath = string.format(szPath, "Loop")
    UIHelper.PlayVideo(self.VideoPlayer, szLoopPath, true, function(nVideoPlayerEvent, szMsg)
        if nVideoPlayerEvent == ccui.VideoPlayerEvent.COMPLETED then
            self:PlayLoop(szPath)
        elseif nVideoPlayerEvent == ccui.VideoPlayerEvent.ERROR then
            TipsHelper.ShowNormalTip("视频播放错误："..tostring(szMsg))
        end
    end)
end

function UILogoVideoView:PlayExit(szExitPath, szEnterPath)
    szExitPath = string.format(szExitPath, "Exit")

    UIHelper.PlayVideo(self.VideoPlayer, szExitPath, true, function(nVideoPlayerEvent, szMsg)
        if nVideoPlayerEvent == ccui.VideoPlayerEvent.COMPLETED then
            self:PlayEnter(szEnterPath)
        elseif nVideoPlayerEvent == ccui.VideoPlayerEvent.ERROR then
            TipsHelper.ShowNormalTip("视频播放错误："..tostring(szMsg))
        end
    end)
end

function UILogoVideoView:OnExit()
    self.bInit = false
    self:UnRegEvent()

    m_bIsVideoPlaying = false
    UIHelper.StopVideo(self.VideoPlayer)
    --SoundMgr.PlayLastBgMusic()
end

function UILogoVideoView:BindUIEvent()

end

function UILogoVideoView:RegEvent()
    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        if self.bWaitPlay and not APIHelper.IsMinimize() then
            self.bWaitPlay = false
            self:StartPlay()
        end
        self:AdjustRect()
    end)
end

function UILogoVideoView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UILogoVideoView:OnVideoCompleted()

    if not m_bIsVideoPlaying then return end

    UIHelper.StopVideo(self.VideoPlayer)
    UIHelper.SetVisible(self.ImgBlackMask, true)
    m_bIsVideoPlaying = false

    XGSDK_TrackEvent("game.splash.end", "loginlogo", {})

    --隔1帧再切UI，否则C++那边会报错
    Timer.AddFrame(self, 1, function()
        UIMgr.Open(VIEW_ID.PanelGameAdvice, self.fnCompleteCallback)
        UIMgr.Close(self)
    end)
end

function UILogoVideoView:PlayLogoVideo()
    UIHelper.SetVisible(self.ImgBlackMask, false)

    m_bIsVideoPlaying = true
    local szPath = "Video\\PC\\LogoVideo.mp4"
    if Platform.IsMobile() then
        szPath = "Video\\MOBILE\\LogoVideo.mp4"
    end
    
    self.VideoPlayer:setUserInputEnabled(false)  -- 禁止暂停
    UIHelper.SetVideoPlayerModel(self.VideoPlayer , VIDEOPLAYER_MODEL.BINK)
    szPath = UIHelper.ParseVideoPlayerFile(szPath , VIDEOPLAYER_MODEL.BINK)
    XGSDK_TrackEvent("game.splash.begin", "startmodule", {})
    UIHelper.PlayVideo(self.VideoPlayer, szPath, true, function(nVideoPlayerEvent, szMsg)
        if nVideoPlayerEvent == ccui.VideoPlayerEvent.COMPLETED then
            self:OnVideoCompleted()
        elseif nVideoPlayerEvent == ccui.VideoPlayerEvent.ERROR then
            TipsHelper.ShowNormalTip("视频播放错误："..tostring(szMsg))
            self:OnVideoCompleted()
        end
    end)
    self:AdjustRect()
end

function UILogoVideoView:PlayVideo(szUrl, bIsLocal, fnCompleteCallback, bLoop)
    if m_bIsVideoPlaying then
        return
    end

    if bIsLocal then
        UIHelper.SetVideoPlayerModel(self.VideoPlayer , VIDEOPLAYER_MODEL.BINK)
    else
        UIHelper.SetVideoPlayerModel(self.VideoPlayer , VIDEOPLAYER_MODEL.FFMPEG)
    end
    szUrl = UIHelper.ParseVideoPlayerFile(szUrl , VIDEOPLAYER_MODEL.BINK)
    m_bIsVideoPlaying = true
    UIHelper.SetVideoLooping(self.VideoPlayer, bLoop)
    UIHelper.PlayVideo(self.VideoPlayer, szUrl, bIsLocal, function (nVideoPlayerEvent, szMsg)
        if nVideoPlayerEvent == ccui.VideoPlayerEvent.COMPLETED or nVideoPlayerEvent == ccui.VideoPlayerEvent.ERROR then
            if m_bIsVideoPlaying then
                -- if fnCompleteCallback then
                --     fnCompleteCallback()
                -- end
                m_bIsVideoPlaying = false
            end
        end
    end)
    self:AdjustRect()
end


function UILogoVideoView:AdjustRect()
    local tbScreenSize = UIHelper.DeviceScreenSize()
    local fScreenRatio = tbScreenSize.width / tbScreenSize.height
    local fVideoRatio = m_tOrComSize.width / m_tOrComSize.height
    local newNodeWidth = 0
    local newNodeHeight = 0
    if fVideoRatio > fScreenRatio then
        newNodeWidth = m_tOrComSize.width * (fVideoRatio / fScreenRatio)
        newNodeHeight = m_tOrComSize.height * (fVideoRatio / fScreenRatio)
    else 
        newNodeWidth = m_tOrComSize.width * (fScreenRatio / fVideoRatio)
        newNodeHeight = m_tOrComSize.height * (fScreenRatio / fVideoRatio)
    end
    UIHelper.SetContentSize(self.VideoPlayer , newNodeWidth , newNodeHeight)
    UIHelper.SetPosition(self.VideoPlayer, 0, 0)
end

return UILogoVideoView