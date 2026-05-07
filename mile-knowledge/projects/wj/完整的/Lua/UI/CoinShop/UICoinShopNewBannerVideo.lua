-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopNewBannerVideo
-- Date: 2024-03-26 15:22:26
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICoinShopNewBannerVideo = class("UICoinShopNewBannerVideo")

function UICoinShopNewBannerVideo:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    UIHelper.SetVisible(self._rootNode, false)
end

function UICoinShopNewBannerVideo:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICoinShopNewBannerVideo:BindUIEvent()

end

function UICoinShopNewBannerVideo:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICoinShopNewBannerVideo:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopNewBannerVideo:UpdateInfo()

end

function UICoinShopNewBannerVideo:PlayVideo(szUrl, fnCallback)
    UIHelper.SetVisible(self._rootNode, true)

    if Platform.IsAndroid() then
        szUrl = string.gsub(szUrl , "https:" , "http:")
    end

    UIHelper.PlayVideo(self.WidgetVideo, szUrl, false, function(nVideoPlayerEvent, szMsg)
        if nVideoPlayerEvent == ccui.VideoPlayerEvent.COMPLETED then
            if self.bCallback then
                fnCallback()
            end
            self.bCallback = false
        elseif nVideoPlayerEvent == ccui.VideoPlayerEvent.ERROR then
            TipsHelper.ShowNormalTip("视频播放错误："..tostring(szMsg))
            if self.bCallback then
                fnCallback()
            end
            self.bCallback = false
        end
    end)
    self.bCallback = true
end

function UICoinShopNewBannerVideo:StopVideo()
    UIHelper.SetVisible(self._rootNode, false)
    self.bCallback = false
    UIHelper.StopVideo(self.WidgetVideo)
end


return UICoinShopNewBannerVideo