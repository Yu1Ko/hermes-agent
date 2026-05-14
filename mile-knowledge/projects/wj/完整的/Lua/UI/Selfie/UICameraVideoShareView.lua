-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICameraVideoShareView
-- Date: 2024-10-17 10:34:00
-- Desc: ?
-- ---------------------------------------------------------------------------------
local UICameraVideoShareView = class("UICameraVideoShareView")
local  ShareV2Mode = 
{
    ELocal  = 0,        -- 分享本地资源
    EOnline = 1         -- 分享网络资源
}
function UICameraVideoShareView:OnEnter(szFilePath, szFileName, onEnterCallback, nWidth, nHeight)
    self.szFilePath = szFilePath
    self.szFileName = szFileName
    self.szFullFilePath = szFilePath..szFileName
    self.bPlayVideo = false
    self.onEnterCallback = onEnterCallback

    -- 录制框大小
    self.nWidth = nWidth
    self.nHeight = nHeight
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.bReqUploadTime = true
    SelfieData.StartRegCurlRequest()
    SelfieData.ShareLoginAccount()
    self:UpdateInfo()
    SoundMgr.StopBgMusic()
end

function UICameraVideoShareView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    SelfieData.EndRegCurlRequest()
    if self.videoPlayer:isPlaying() then
        self.videoPlayer:stop()
    end
    if self.pFirstFrameImage and safe_check(self.pFirstFrameImage) then
        self.pFirstFrameImage:release()
    end

    if self.szFullFilePath and not self.bSaveLocalVideo then
        cc.FileUtils:getInstance():removeFile(UIHelper.UTF8ToGBK(self.szFullFilePath))
        self.szFullFilePath = nil
    end
    if self.szSaveImageUrl then
        cc.FileUtils:getInstance():removeFile(UIHelper.UTF8ToGBK(self.szSaveImageUrl))
        self.szSaveImageUrl = nil
    end
    Global.SetWindowsSizeChangedExtraIgnoreViewIDs({})
    SoundMgr.PlayLastBgMusic()
end

function UICameraVideoShareView:BindUIEvent()
    
    UIHelper.BindUIEvent(self.TogVideoPlay, EventType.OnSelectChanged, function (_, bSelected)
        self.bClickPlayVideo = bSelected
        if bSelected then
            self:StartPlayVideo()
        else
            self:PausePlayVideo()
        end
    end)
    if not self.BtnClose then
        self.BtnClose = UIHelper.GetChildByName(self.WidgetAnchorMiddle, "BtnClose")
    end
   
    
    UIHelper.BindUIEvent(self.BtnClose , EventType.OnClick , function ()
        if self.bSavingVideo then
            TipsHelper.ShowNormalTip("视频保存中，请稍等...")
            return
        elseif self.bWaitSendFinished then
            TipsHelper.ShowNormalTip("正在分享中，请稍等...")
            return
        end
        if Platform.IsWindows() then
            if not self.bSaveVideoSuccess then
                UIHelper.ShowConfirm("当前视频尚未保存，确定要关闭吗？", function ()
                    UIMgr.Close(self)
                end)
                return
            end
        else
            if not self.bSaveVideoSuccess and not self.bShareSuccess then
                UIHelper.ShowConfirm("当前视频尚未保存或分享，确定要关闭吗？", function ()
                    UIMgr.Close(self)
                end)
                return
            end
        end

        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnSave , EventType.OnClick , function ()
        if Platform.IsWindows() or Platform.IsMac() then
            self.bSaveLocalVideo = true
            self.bSaveVideoSuccess = true
            TipsHelper.ShowNormalTip("视频保存成功 , 路径："..self.szFullFilePath)
            self:UpdateShareButtonState(true)
        else
            if not Permission.CheckPermission(Permission.ExternalStorageWrite) then
                if Permission.CheckHasAsked(Permission.ExternalStorageWrite) then
                    Permission.AskForSwitchToAppPermissionSetting(Permission.ExternalStorageWrite)
                    return
                else
                    Permission.RequestUserPermission(Permission.ExternalStorageWrite)
                    Event.Reg(self, "OnRequestPermissionCallback", function(nPermission, bResult)
                        if nPermission == Permission.ExternalStorageWrite then
                            Event.UnReg(self, "OnRequestPermissionCallback")
                            if bResult then
                                self:OnSaveStorageVideo(true)
                            end
                        end
                    end)
                end
            else
                self:OnSaveStorageVideo(true)
            end 
        end
    end)

    UIHelper.BindUIEvent(self.BtnAlbum , EventType.OnClick , function ()
        local i, folder, file = 0, GetStreamAdaptiveDirPath('dcim/')
        CPath.MakeDir(folder)
        OpenFolder(folder)
    end)

    UIHelper.BindUIEvent(self.BtnShareQQ , EventType.OnClick , function ()
        self:SendShare("qqfriend",ShareV2Mode.EOnline)
     end)
 
     UIHelper.BindUIEvent(self.BtnShareVX , EventType.OnClick , function ()
         self:SendShare("wechatfriend",ShareV2Mode.EOnline)
     end)
 
     UIHelper.BindUIEvent(self.BtnSharePYQ , EventType.OnClick , function ()
         self:SendShare("wechatzone",ShareV2Mode.EOnline)
     end)
 
     UIHelper.BindUIEvent(self.BtnShareWB , EventType.OnClick , function ()
         self:SendShare("weibo",ShareV2Mode.ELocal)
     end)
 
     UIHelper.BindUIEvent(self.BtnShareXHS , EventType.OnClick , function ()
         self:SendShare("xhsnote",ShareV2Mode.ELocal)
     end)
 
     UIHelper.BindUIEvent(self.BtnShareTap , EventType.OnClick , function ()
         self:SendShare("taptappublish")
     end)
 
     UIHelper.BindUIEvent(self.BtnShareDY , EventType.OnClick , function ()
         self:SendShare("douyinpublish",ShareV2Mode.ELocal)
     end)

    self.videoPlayer:addEventListener(function (_, nEvent , msg)
        if self.bInit then
            if nEvent == 0 then     -- playing
                self.nCurCountTime  = 0
                self.nVideoDuration = self.videoPlayer:getVideoDuration()
                if self.nVideoDuration <= 0 then
                    self.nVideoDuration = 1
                end
                UIHelper.SetProgressBarPercent(self.SliderLeftMargin, 0)
                UIHelper.SetProgressBarPercent(self.ImgLeftMargin , 0)
                self:UpdateLabelTime(0)
            elseif nEvent == 3 then -- completed
                Timer.Add(self , 0.2 , function ()
                    Timer.DelTimer(self, self.nCountTimerID)
                    self.nCurCountTime = 0
                    self.videoPlayer:play()
                    self:UpdateTime()
                end)
            elseif nEvent == 4 then -- error
                if not Platform.IsMobile() then
                    TipsHelper.ShowNormalTip("当前设备的显存不足，无法使用此功能！")
                end
                Timer.Add(self , 0.2 , function ()
                    UIMgr.Close(self)
                end)
            elseif nEvent == 7 then -- pre load first frame
                if not self.bInitFirstFrame then
                    self.bInitFirstFrame = true
                    -- 先放大拍照（作为分享的首帧画面）
                    local scale = 0.5
                    local sizeResolution = UIHelper.GetCurResolutionSize()
                    local sizeScreen = UIHelper.GetScreenSize()

                    local nScaleX = (sizeResolution.width / sizeScreen.width)
                    local nScaleY = (sizeResolution.height / sizeScreen.height)
                    if nScaleX < 1 or nScaleY < 1 then
                        if nScaleX > nScaleY then
                            scale = scale * nScaleY
                        else
                            scale = scale * nScaleX
                        end
                    end
                    UIHelper.SetVisible(self.WidgetLoading, false)
                    UIHelper.CaptureScreenMainPlayer(function (pRetTexture , pImage)
                        self.pFirstFrameImage = pImage
                        self.pFirstFrameRetTexture = pRetTexture
                        self:SwitchFullScreen(false)
                    end, scale , true)
                end
            end
        end
    end)
end

function UICameraVideoShareView:RegEvent()
    Event.Reg(self, EventType.OnSelfieWebCodeRsp, function (szKey, tInfo)
        if szKey == "LOGIN_ACCOUNT" then
            if SelfieData.szUploadVideoSessionID then
                SelfieData.ReqGetUploadTime()
            else
                TipsHelper.ShowNormalTip("校验上传次数失败")
                LOG.INFO("校验上传次数失败")
            end
        elseif szKey == "GET_UPLOAD_TIME" then
            if tInfo and tInfo.code then
                self.nGetUploadTimeStatusCode = tInfo.code
                if tInfo.code == 1 and tInfo.data then
                    self.nCanUploadTime = tInfo.data.remain_upload_time
                end
                self.bReqUploadTime = false
                LOG.INFO("获取上传次数:  %d,%d",tInfo.code,self.nCanUploadTime)
            end
        elseif szKey == "DO_UPLOAD_VIDEO" then
            if tInfo and tInfo.code and tInfo.code == 1 then
                local tData = tInfo.data
                if tData then
                    self.video_url = tData.file_link
                    self:DoXGSDKShare()
                    SelfieData.ReqVideoUploadLog(tData.file_id, tData.file_link)
                end
            else
                TipsHelper.ShowNormalTip("分享失败")
            end
        elseif szKey == "UPLOAD_VIDEO" then
            if tInfo and tInfo.code then
                if tInfo.code == 1 then
                    self.nCanUploadTime = tInfo.data.remain_upload_time
                else
                    Timer.Add(self, 0.5, function ()
                        SelfieData.ShareLoginAccount()
                    end)
                end
            end
        end
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function ()
        if not Platform.IsMobile() then
            self:AdjustViewScale()
        end
    end)
end

function UICameraVideoShareView:UnRegEvent()
    Event.UnReg(self, EventType.OnSelfieWebCodeRsp)
    Event.UnReg(self, EventType.OnWindowsSizeChanged)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICameraVideoShareView:UpdateInfo()
    self.bPlayingVideo = false
    self.bPauseVideo = false
    self.nCurCountTime = 0
    self.bInitFirstFrame = false
    self.bSavingVideo  = false
    self.nCanUploadTime = 0
    self.nVideoDuration = 0
    self.bWaitUpload = false

    self.bShareSuccess = false
    self.bSaveVideoSuccess = false

    self.nFullWidth, self.nFullHeight = UIHelper.GetContentSize(self._rootNode)
    self.nOrigWidth, self.nOrigHeight = UIHelper.GetContentSize(self.videoPlayer)
    self.nOrigPosX, self.nOrigPosY = UIHelper.GetPosition(self.WidgetAnchorMiddle)

    self.LabelTimeMessage = UIHelper.GetChildByName(self.WidgetVideoPlayList,"LabelTimeMessage")
    self:UpdateLabelTime(0)
    self:SwitchFullScreen(true)
    UIHelper.SetVisible(self.SliderLeftMargin,false)
    UIHelper.SetProgressBarPercent(self.SliderLeftMargin, 0)
    UIHelper.SetProgressBarPercent(self.ImgLeftMargin , 0)
    UIHelper.SetVisible(self.WidgetLoading, true)
    self:UpdateShareButtonState(true)
    if self.onEnterCallback then
        self.onEnterCallback()
    end
    UIHelper.SetSelected(self.TogVideoPlay, true)
    self:UpdateShareReward()
end

function UICameraVideoShareView:StartPlayVideo()
    if self.bPauseVideo then
        self.videoPlayer:setNeedFirstFrame(false)
        self.videoPlayer:resume()
        self.bPauseVideo = false
        self:UpdateTime()
    else
        UIHelper.PlayVideo(self.videoPlayer, self.szFullFilePath, false, nil,nil,nil, true)
    end
    self.bPlayingVideo = true
end

function UICameraVideoShareView:PausePlayVideo()
    if self.bPlayingVideo then
        self.videoPlayer:pause()
        self.bPauseVideo = true
        Timer.DelTimer(self, self.nCountTimerID)
    end
    self.bPlayingVideo = false
end

function UICameraVideoShareView:UpdateTime()
    Timer.DelTimer(self, self.nCountTimerID)
    self.nCountTimerID = Timer.AddCycle(self, 1, function ()
        self.nCurCountTime = self.nCurCountTime + 1
        if self.nVideoDuration <= 0 then
            self.nVideoDuration = 1
        end
        local nProgress = self.nCurCountTime/self.nVideoDuration*100
        UIHelper.SetProgressBarPercent(self.SliderLeftMargin, nProgress)
        UIHelper.SetProgressBarPercent(self.ImgLeftMargin , nProgress)
        self:UpdateLabelTime(self.nCurCountTime)
    end)
end

function UICameraVideoShareView:SwitchFullScreen(bFull)
    if Channel.IsCloud() and not Channel.Is_WLColud() then
        UIHelper.SetVisible(self.LayoutBtnShare, false)
    else
        UIHelper.SetVisible(self.LayoutBtnShare, not bFull)
    end
    UIHelper.SetVisible(self.WidgetVideoPlayList, not bFull)
    UIHelper.SetVisible(self.ImgBg, not bFull)

    if self.nWidth and self.nHeight then
        UIHelper.SetContentSize(self.WidgetAnchorMiddle, self.nWidth, self.nHeight)
        UIHelper.SetContentSize(self.videoPlayer, self.nWidth, self.nHeight)
        UIHelper.SetContentSize(self.MaskPhoto, self.nWidth, self.nHeight)
        UIHelper.SetPosition(self.videoPlayer, 0, 0, self.MaskPhoto)
        UIHelper.SetPosition(self.MaskPhoto, 0, 0, self.WidgetAnchorMiddle)
        UIHelper.SetPosition(self.WidgetAnchorMiddle, 0, 0)
        UIHelper.WidgetFoceDoAlign(self)
        return
    end

    if bFull then
        UIHelper.SetContentSize(self.WidgetAnchorMiddle, self.nFullWidth, self.nFullHeight)
        UIHelper.SetContentSize(self.videoPlayer, self.nFullWidth, self.nFullHeight)
        UIHelper.SetContentSize(self.MaskPhoto, self.nFullWidth, self.nFullHeight)
        UIHelper.SetPosition(self.videoPlayer, 0, 0, self.MaskPhoto)
        UIHelper.SetPosition(self.MaskPhoto, 0, 0, self.WidgetAnchorMiddle)
        UIHelper.SetPosition(self.WidgetAnchorMiddle, 0, 0)
        UIHelper.WidgetFoceDoAlign(self)
    else
        self:AdjustViewScale()
    end
end


function UICameraVideoShareView:OnSaveStorageVideo()
    TipsHelper.ShowNormalTip("视频保存中，请稍等... ")
    self:UpdateShareButtonState(false)
    self.bSavingVideo = true

    UIHelper.SaveVideoToPhoto(self.szFullFilePath, function(nCaptureRet)

    end)

    Timer.Add(self , 2 , function ()
        TipsHelper.ShowNormalTip("视频保存成功")
        self.bSavingVideo = false
        self.bSaveVideoSuccess = true
        self:UpdateShareButtonState(true)
    end)
end

function UICameraVideoShareView:UpdateShareButtonState(bShow)
    if Channel.IsCloud() and not Channel.Is_WLColud() then
        UIHelper.SetVisible(self.LayoutBtnShare, false)
        return
    end
    
    local bVisible = bShow and Platform.IsMobile() and not AppReviewMgr.IsReview()
    UIHelper.SetVisible(self.BtnShareQQ , bVisible and AppReviewMgr.IsShowCameraShareChannel("qqfriend"))
    UIHelper.SetVisible(self.BtnShareVX , bVisible and AppReviewMgr.IsShowCameraShareChannel("wechatfriend"))
    UIHelper.SetVisible(self.BtnSharePYQ , bVisible and AppReviewMgr.IsShowCameraShareChannel("wechatzone"))
    UIHelper.SetVisible(self.BtnShareWB , bVisible and AppReviewMgr.IsShowCameraShareChannel("weibo"))
    UIHelper.SetVisible(self.BtnShareXHS , bVisible and AppReviewMgr.IsShowCameraShareChannel("xhsnote"))
    UIHelper.SetVisible(self.BtnShareTap , false)--bVisible and AppReviewMgr.IsShowCameraShareChannel("taptappublish"))
    UIHelper.SetVisible(self.BtnShareDY , bVisible and AppReviewMgr.IsShowCameraShareChannel("douyinpublish"))
    UIHelper.SetVisible(self.BtnSave , bShow and not self.bSaveLocalVideo)
    UIHelper.SetVisible(self.BtnAlbum , bShow and self.bSaveLocalVideo and (Platform.IsWindows() or Platform.IsMac()))
    UIHelper.LayoutDoLayout(UIHelper.GetParent(self.BtnAlbum ))
end

function UICameraVideoShareView:SendShare(szChannel,nMode)

    if self.bReqUploadTime then
        TipsHelper.ShowNormalTip("正在校验可上传次数，请稍后再试！")
        return 
    end

    if self.bWaitSendFinished then
        TipsHelper.ShowNormalTip("正在分享，请稍候")
        return
    end
    if  not self.video_url and self.nCanUploadTime <= 0 then
        TipsHelper.ShowNormalTip("今日上传视频的次数已达上限！")
        return 
    end
    self.bWaitSendFinished = true
    self.szShareChannel = szChannel
    self.nShareMode = nMode
    self:UpdateShareButtonState(false)
    if not self.video_url then
        TipsHelper.ShowImportantBlueTip("正在分享中...", false, 1000)
        SelfieData.ReqGetUploadToken(self.szFullFilePath, self.szFileName)
    else
        self:DoXGSDKShare()
    end
    
end

function UICameraVideoShareView:DoXGSDKShare()
    local szUid = Login_GetUnionAccount()
    local player = GetClientPlayer()
    local szRoleId = "NoRole"
    if player then
        szRoleId = tostring(player.dwID)
    end
    local szTitle = self.nShareMode == ShareV2Mode.EOnline and "剑网3无界" or ""
    local szContent = self.nShareMode == ShareV2Mode.EOnline and "国风武侠扛鼎之作" or ""
    local onExSendShare = function()
        Global.SetWindowsSizeChangedExtraIgnoreViewIDs({
            VIEW_ID.PanelCamera ,
            VIEW_ID.PanelCameraVertical,
            VIEW_ID.PanelCameraVideoShare ,
            VIEW_ID.PanelCameraVideoSharePortrait
        })
        if XGSDK_Share_Video then
            if self.nShareMode == ShareV2Mode.ELocal then
                XGSDK_Share_Video(szUid, szRoleId, self.szShareChannel, "", szTitle, szContent, self.szSaveImageUrl, self.szFullFilePath ,"JX3D",self.nShareMode)
            else
                XGSDK_Share_Video(szUid, szRoleId, self.szShareChannel, "", szTitle, szContent, self.szSaveImageUrl, self.video_url ,"JX3D",self.nShareMode)
            end
        end
        RemoteCallToServer("On_Mobile_ShareRewards")
        self:UpdateShareButtonState(true)
    end
    TipsHelper.SkipCurrentImportantTips()
    self.szSaveImageUrl = self.szFilePath.."tmp_videoShare_Img.png"
    UIHelper.SaveImageToLocalFile_RGB(self.szSaveImageUrl , self.pFirstFrameImage , function (nCaptureRet)
        if nCaptureRet == CaptureScreenResult.SaveFinish then
            onExSendShare()
        else
            self:UpdateShareButtonState(true)
        end
        self.bShareSuccess = true
        self.bWaitSendFinished = false
    end)
    LOG.INFO(string.format("分享成功，剩余次数:%d",self.nCanUploadTime))
end

function UICameraVideoShareView:UpdateLabelTime(nTimeCount)
    if nTimeCount > self.nVideoDuration then
        nTimeCount = self.nVideoDuration
    end
    UIHelper.SetString(self.LabelTimeMessage , string.format("%s/%s",Timer.Format2Minute(nTimeCount),Timer.Format2Minute(self.nVideoDuration)))
end

function UICameraVideoShareView:AdjustViewScale()
    local tbScreenSize = Platform.IsMac() and UIHelper.GetScreenSize() or UIHelper.DeviceScreenSize()
    local nodeW = self.nOrigWidth
    local nodeH = self.nOrigHeight
    local newNodeW = nodeH / tbScreenSize.height * tbScreenSize.width
    if newNodeW < tbScreenSize.width then
        nodeH = nodeW / tbScreenSize.width * tbScreenSize.height
    else
        nodeW = newNodeW
    end
    UIHelper.SetContentSize(self.WidgetAnchorMiddle , nodeW , nodeH)
    UIHelper.SetContentSize(self.videoPlayer , nodeW , nodeH)
    UIHelper.SetContentSize(self.MaskPhoto , nodeW , nodeH)
    UIHelper.SetContentSize(self.ImgBg , nodeW+20 , nodeH+20)
    UIHelper.SetPosition(self.videoPlayer ,0,0,self.MaskPhoto)
    UIHelper.SetPosition(self.MaskPhoto ,0,0,self.WidgetAnchorMiddle)
    UIHelper.SetPosition(self.ImgBg ,0,0,self.WidgetAnchorMiddle)
    UIHelper.SetSelected(self.TogVideoPlay, false)
    UIHelper.WidgetFoceDoAlign(self)
end

function UICameraVideoShareView:UpdateShareReward()
    local bVisible = Platform.IsMobile() and not AppReviewMgr.IsReview() and not Channel.IsCloud()
    UIHelper.SetVisible(self.LabelPlayerRewardName , bVisible)
    UIHelper.SetVisible(self.WidgetShareReward , bVisible)
    UIHelper.SetVisible(self.WidgetShareRewardGet , bVisible and self:IsHaveBuff())
    if not self.rewardItem then
        self.rewardItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.WidgetShareReward)
        self.rewardItem:OnInitWithTabID(5,40385,1)
        self.rewardItem:SetClickNotSelected(true)
        self.rewardItem:SetToggleSwallowTouches(true)
        self.rewardItem:SetClickCallback(function ()
            TipsHelper.ShowItemTips(self.WidgetShareReward, 5, 40385)
        end)
    end
end

function UICameraVideoShareView:IsHaveBuff()
    local player = GetClientPlayer()
    if player then
        return player.IsHaveBuff(28338, 1)
    else
        return false
    end
end

return UICameraVideoShareView