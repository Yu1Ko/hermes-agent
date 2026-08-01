-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UICameraPhotoShareView
-- Date: 2023-05-25 16:56:32
-- Desc: 照相图片分享界面
-- ---------------------------------------------------------------------------------

local UICameraPhotoShareView = class("UICameraPhotoShareView")

function UICameraPhotoShareView:OnEnter(picTexture ,pImage ,fullPath, fileName , closeCallback,pMessageImage,bHideMessageToggle, nWidth, nHeight)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.closeCallback = closeCallback

    self.fileName = fileName
    self.fullPath = GBKToUTF8(fullPath)
    if not self.fullPath then
        self.fullPath = fullPath
    end
    self.szDefaultFilePath = self.fullPath..self.fileName
    self.picTexture = picTexture
    self.pImage = pImage
    self.bSavingPhoto = false
    self.bSaveImageToPhoto = false
    self.pMessageImage = pMessageImage
    self.bHideMessageToggle = bHideMessageToggle
    self.bEnableScaleSave = true
    self.nWidth = nWidth
    self.nHeight = nHeight
    self.tImageCacheState = {
        ["ALL"] = false,
        ["HideMessage"] = false,
        ["HideName"] = false
    }
    self.nTime = os.time()
    self:UpdateInfo()
    TuiLanData.request_tuilan_is_bound()
    Global.SetShowRewardListEnable(VIEW_ID.PanelCameraPhotoShare, true)
    Global.SetShowLeftRewardTipsEnable(VIEW_ID.PanelCameraPhotoShare, false)
end

function UICameraPhotoShareView:OnExit()
    if self.closeCallback then
        self.closeCallback()
    end

    if safe_check(self.pImage) then
        self.pImage:release()
    end

    if self.pMessageImage and safe_check(self.pMessageImage) then
        self.pMessageImage:release()
    end

    if self.pChangeTexture then
        if safe_check(self.pChangeTexture) then
            self.pChangeTexture:release()
        end

        if safe_check(self.picTexture) then
            self.picTexture:release()
        end
    end

    self.bInit = false
    self:UnRegEvent()
    Global.SetShowRewardListEnable(VIEW_ID.PanelCameraPhotoShare, false)
    Global.SetShowLeftRewardTipsEnable(VIEW_ID.PanelCameraPhotoShare, true)
    Global.SetWindowsSizeChangedExtraIgnoreViewIDs({})
    if not self.bSaveImageToPhoto then
        local ccFileUtils = cc.FileUtils:getInstance()
        ccFileUtils:removeFile(UIHelper.UTF8ToGBK(self.szDefaultFilePath))
    end
end

function UICameraPhotoShareView:SavePhoto(nDelayTime)
    local _OnSaveToLocalPhoto = function()
        Timer.Add(self, 0.2 , function ()
            local dt = TimeToDate(self.nTime)
            local fileName = string.format("%04d%02d%02d%02d%02d%02d.png",dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second)
            local filePath = self.fullPath..fileName
            if Channel.Is_WLColud() then filePath = self:_getWLCloudFilePath()..fileName end
            TipsHelper.ShowNormalTip("照片保存中，请稍等... ")
            self:ShowShareButton(false)
            self.bSavingPhoto = true
            self.bSaveImageToPhoto = true
            local function _doSave(pImage)
                UIHelper.SetVisible(self.WidgetSwitchHideMessage , true)
                UIHelper.SetVisible(self.WidgetSwitchHideName , true)
                UIHelper.SetVisible(self.WidgetAnchorBtn , true)
                UIHelper.SaveImageToLocalFile_RGB(filePath , pImage , function (nCaptureRet)
                    if nCaptureRet == CaptureScreenResult.SaveFinish then
                        if Platform.IsMobile() or Channel.Is_WLColud() then
                            if Channel.Is_WLColud() then
                                self:_copyFromWLCloudFileToDcim(filePath, fileName)
                            else
                                TipsHelper.ShowNormalTip("照片保存成功")
                            end
                        else
                            TipsHelper.ShowNormalTip("照片保存成功 , 路径："..filePath)
                        end
                        Timer.Add(self , 0.2 , function ()
                            UIHelper.SaveImageToPhoto(filePath, function(nCaptureRet)
                                
                            end)
                        end)
                    elseif nCaptureRet == CaptureScreenResult.Failed then
                        TipsHelper.ShowNormalTip("照片保存失败")
                    end
                    Timer.Add(self , 2 , function ()
                        self.bSavingPhoto = false
                        self:ShowShareButton(true)
                    end)
                    self.bSelectState = false
                end)
            end
            if self.nWidth and self.nHeight then
                local sx, sy = UIHelper.GetScreenToResolutionScale()
                local nWidth, nHeight = UIHelper.GetContentSize(self.MaskPhoto)
                nWidth = nWidth * sx / 2
                nHeight = nHeight * sy / 2
                UIHelper.CropImage(function (pRetTexture, pImage)
                    UIHelper.SetVisible(self.ImgBg, true)
                    self.pMessageImage = pImage
                    self.pCurImage = pImage
                    _doSave(self.pCurImage)
                end, self.pCurImage, -nWidth, nWidth, -nHeight, nHeight, true)
            else
                _doSave(self.pCurImage)
            end
        end)
    end

    nDelayTime = nDelayTime * 0.001
    -- 放大缩小只有1S
    if nDelayTime < 0.1 then
        nDelayTime = 0.1
    end

    Timer.Add(self, nDelayTime , function ()
        UIHelper.SetVisible(self.WidgetAnchorMiddle , true)
        UIHelper.SetVisible(self.widgetFullScreen , false)
        UIMgr.SetShowAllInLayer(UILayer.Scene, true)
        if Platform.IsWindows() or Platform.IsMac() then
            _OnSaveToLocalPhoto()
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
                                _OnSaveToLocalPhoto()
                            end
                        end
                    end)
                end
            else
                _OnSaveToLocalPhoto()
            end
        end
    end)
end

function UICameraPhotoShareView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSave , EventType.OnClick , function ()
        UIHelper.SetVisible(self.WidgetSwitchHideMessage , false)
        UIHelper.SetVisible(self.WidgetSwitchHideName , false)
        UIHelper.SetVisible(self.WidgetAnchorBtn , false)
        if self.bEnableScaleSave and not (self.nHeight or self.nWidth) then
            -- 放大效果
            UIHelper.SetVisible(self.WidgetAnchorMiddle , false)
            UIHelper.SetVisible(self.widgetFullScreen , true)
            UIMgr.SetShowAllInLayer(UILayer.Scene, false)
            UIHelper.SetVisible(self.ImgFullLogo3, self.bSelectShowMessage)
            UIHelper.SetVisible(self.ImgFullQRCode ,  self.bSelectShowMessage and AppReviewMgr.IsOpenShaderCode())
            UIHelper.SetVisible(self.WidgetFullPlayerName,  self.bSelectShowPalyerInfo)

            Timer.AddFrame(self, 5, function ()
                local saveTime = GetTickCount()
                if (self.bSelectShowMessage or self.bSelectShowPalyerInfo) then
                    if self.pMessageImage and safe_check(self.pMessageImage) then
                        self.pMessageImage:release()
                    end

                    UIHelper.CaptureScreen(function (pRetTexture , pImage)
                        self.pMessageImage = pImage
                        self.pCurImage = pImage
                        self:SavePhoto(GetTickCount() - saveTime)
                    end, 1 , true)
                else
                    self:SavePhoto(1000)
                end
            end)
        elseif self.nHeight and self.nWidth then
            UIMgr.SetShowAllInLayer(UILayer.Scene, false)
            UIHelper.SetVisible(self.ImgBg, false)
            Timer.AddFrame(self, 5, function ()
                local saveTime = GetTickCount()
                if (self.bSelectShowMessage or self.bSelectShowPalyerInfo) then
                    if self.pMessageImage and safe_check(self.pMessageImage) then
                        self.pMessageImage:release()
                    end

                    UIHelper.CaptureScreen(function (pRetTexture, pImage)
                        self.pMessageImage = pImage
                        self.pCurImage = pImage
                        self:SavePhoto(GetTickCount() - saveTime)
                    end, 1 , true)
                else
                    self:SavePhoto(1000)
                end
            end)
        else
            self:SavePhoto(0)
        end

    end)

    UIHelper.BindUIEvent(self.btnClose , EventType.OnClick , function ()

        if UIHelper.GetVisible(self.WidgetTLCode) then
            UIHelper.SetVisible(self.WidgetTLCode, false)
            return
        end
        if self.bWaitingShareTuiLanApp then
            TipsHelper.ShowNormalTip(TuiLanData.szShareExcuteTip) 
            return  
        end
        if self.bSavingPhoto then
            TipsHelper.ShowNormalTip("照片保存中，请稍等...")
        else
            UIMgr.Close(self)
        end
    end)

    UIHelper.BindUIEvent(self.BtnClose , EventType.OnClick , function ()
        if UIHelper.GetVisible(self.WidgetTLCode) then
            UIHelper.SetVisible(self.WidgetTLCode, false)
            return
        end

        if self.bWaitingShareTuiLanApp then
            TipsHelper.ShowNormalTip(TuiLanData.szShareExcuteTip) 
            return  
        end

        if self.bSavingPhoto then
            TipsHelper.ShowNormalTip("照片保存中，请稍等...")
        else
            self.bShowRCode = not self.bShowRCode

            UIHelper.SetVisible(self.ImgLogo3 ,  self.bShowRCode)
            UIHelper.SetVisible(self.ImgQRCode , self.bShowRCode and AppReviewMgr.IsOpenShaderCode())
        end
    end)

    UIHelper.BindUIEvent(self.BtnShareQQ , EventType.OnClick , function ()
       self:SendShare("qqimage")
    end)

    UIHelper.BindUIEvent(self.BtnShareVX , EventType.OnClick , function ()
        self:SendShare("weichatfriend")
    end)

    UIHelper.BindUIEvent(self.BtnSharePYQ , EventType.OnClick , function ()
        self:SendShare("weichatzone")
    end)

    UIHelper.BindUIEvent(self.BtnShareWB , EventType.OnClick , function ()
        self:SendShare("weibo")
    end)

    UIHelper.BindUIEvent(self.BtnShareXHS , EventType.OnClick , function ()
        self:SendShare("xhsnote")
        self:UpdateXHSRewardTip(true)
    end)

    UIHelper.BindUIEvent(self.BtnShareTap , EventType.OnClick , function ()
        self:SendShare("taptappublish")
    end)

    UIHelper.BindUIEvent(self.BtnShareDY , EventType.OnClick , function ()
        self:SendShare("douyinpublish")
    end)

    UIHelper.BindUIEvent(self.ToggleHideMessage, EventType.OnSelectChanged, function(toggle, bSelect)
        if bSelect then
           self.pCurImage = self.pMessageImage

            if self.pChangeTexture then
                UIHelper.SetTextureWithBlur(self.ImgPhoto, self.pChangeTexture)
            end
        else
            self.pCurImage = self.pImage

            if self.pChangeTexture then
                UIHelper.SetTextureWithBlur(self.ImgPhoto, self.picTexture)
            end
        end
        self.bSelectShowMessage = bSelect
        self.bSelectState = true
        if self.bLogoNotHide then
            UIHelper.SetVisible(self.ImgLogo3 ,  true)
        else
            UIHelper.SetVisible(self.ImgLogo3 ,  bSelect)
        end

        UIHelper.SetVisible(self.ImgQRCode , bSelect and AppReviewMgr.IsOpenShaderCode())
    end)

    UIHelper.BindUIEvent(self.ToggleHideName, EventType.OnSelectChanged, function(toggle, bSelect)
        UIHelper.SetVisible(self.WidgetPlayerName , bSelect and not self.pChangeTexture)
        self.bSelectShowPalyerInfo = bSelect
    end)

    UIHelper.BindUIEvent(self.BtnAlbum , EventType.OnClick, function ()
        local i, folder, file = 0, GetStreamAdaptiveDirPath('dcim/')
        CPath.MakeDir(folder)
        OpenFolder(folder)
    end)

    UIHelper.SetVisible(self.BtnShareTL, not AppReviewMgr.IsReview())

    UIHelper.BindUIEvent(self.BtnShareTL, EventType.OnClick, function ()
        if  not self.nSns_Binded_Code or self.nSns_Binded_Code ~= SNS_BINDED_CODE.BINDED then
            if Platform.IsMobile() then
                UIHelper.OpenWebWithDefaultBrowser("https://daily.xoyo.com/#/")
            else
                UIHelper.SetVisible(self.WidgetTLCode, true)
            end
            return 
        end
        if not self.bWaitingShareTuiLanApp then
            local szState = "ALL"
            if not self.bSelectShowMessage then
                szState = "HideMessage"
            elseif not self.bSelectShowPalyerInfo then
                szState = "HideName"
            end

            if self.tImageCacheState[szState] then
                TipsHelper.ShowNormalTip(TuiLanData.szShareSuccessTip)   
                return
            end

            UIHelper.ShowConfirm(TuiLanData.szShareDialogContent, function ()
                self:SendShare("TuiLan")
                self.bWaitingShareTuiLanApp = true
            end)
        else
            TipsHelper.ShowNormalTip(TuiLanData.szShareExcuteTip)   
        end
    end)
end

function UICameraPhotoShareView:RegEvent()
    Event.Reg(self, "XGSDK_OnShareSuccess", function ()
        LOG.INFO("XGSDK_OnShareSuccess")
        RemoteCallToServer("On_Mobile_ShareRewards")
    end)
    Event.Reg(self, "XGSDK_OnShareFail", function ()
        LOG.ERROR("XGSDK_OnShareFail")
    end)


    Event.Reg(self, "ON_IS_BIND_NOTIFY", function (nCode)
        self.nSns_Binded_Code = nCode
        if self.nSns_Binded_Code == SNS_BINDED_CODE.BINDED then
            UIHelper.SetVisible(self.WidgetTLCode, false)
        end
    end)

    Event.Reg(self, "ON_QINIUYUN_UPLOAD_FINISHED", function (bSuccess)
       self:OnSnsUploadFinished(bSuccess)
    end)
    

    Event.Reg(self, EventType.OnWindowsSizeChanged, function ()
        if not Platform.IsMobile() then
            self:AdjustViewScale()
        end
    end)
end

function UICameraPhotoShareView:OnSnsUploadFinished(bSuccess)
    LOG.INFO("OnSnsUploadFinished:"..tostring(bSuccess))
    self.bWaitingShareTuiLanApp = false
    if bSuccess then
        if not self.bSelectShowMessage then
            self.tImageCacheState.HideMessage = true
        elseif not self.bSelectShowPalyerInfo then
            self.tImageCacheState.HideName = true
        else
            self.tImageCacheState.ALL = true
        end
        RemoteCallToServer("On_Mobile_ShareRewards")
    end
end

function UICameraPhotoShareView:UnRegEvent()
    Event.UnRegAll(self)
end

function UICameraPhotoShareView:SendShare(szChannel)
    if self.bWaitingShareTuiLanApp then
        TipsHelper.ShowNormalTip(TuiLanData.szShareExcuteTip) 
        return  
    end
    self:ShowShareButton(false)
    self.bSavingPhoto = true
    local onExSendShare = function()
        local szUid = Login_GetUnionAccount()
        local player = GetClientPlayer()
        local szRoleId = "NoRole"
        if player then
            szRoleId = tostring(player.dwID)
        end
        local szTitle = ""
        local szContent = ""
        Global.SetWindowsSizeChangedExtraIgnoreViewIDs({
            VIEW_ID.PanelCamera ,
            VIEW_ID.PanelCameraVertical,
            VIEW_ID.PanelCameraPhotoShare ,
            VIEW_ID.PanelCameraPhotoSharePortrait
        })
        XGSDK_Share(szUid, szRoleId, szChannel, "", szTitle, szContent, "", self.szDefaultFilePath)
    end
    local _onExcueSave = function()
        Timer.Add(self, 0.2 , function () 
            local function _doSave(pImage)
                UIHelper.SetVisible(self.WidgetSwitchHideMessage , true)
                UIHelper.SetVisible(self.WidgetSwitchHideName , true)
                UIHelper.SetVisible(self.WidgetAnchorBtn , true)
                UIHelper.SaveImageToLocalFile_RGB(self.szDefaultFilePath, pImage, function (nCaptureRet)
                    LOG.INFO(" UICameraPhotoShareView:SendShare %d",nCaptureRet)
                    if nCaptureRet == CaptureScreenResult.SaveFinish then
                        if szChannel ~= "TuiLan" then
                            onExSendShare()
                        else
                            self:OnSendTuiLan()
                        end
                    end
                    self:ShowShareButton(true)
                    self.bSavingPhoto = false
                    self.bSelectState = false
                end)
            end    
            if self.nWidth and self.nHeight then
                local sx, sy = UIHelper.GetScreenToResolutionScale()
                local nWidth, nHeight = UIHelper.GetContentSize(self.MaskPhoto)
                nWidth = nWidth * sx / 2
                nHeight = nHeight * sy / 2
                UIHelper.CropImage(function (pRetTexture, pImage)
                    UIHelper.SetVisible(self.ImgBg, true)
                    self.pMessageImage = pImage
                    self.pCurImage = pImage
                    _doSave(self.pCurImage)
                end, self.pCurImage, -nWidth, nWidth, -nHeight, nHeight, true)
            else
                _doSave(self.pCurImage)
            end
        end)
       
    end
    local _onSaveImageToLocalFile = function(nDelayTime)
        nDelayTime = nDelayTime * 0.001
        -- 放大缩小只有1S
        if nDelayTime < 0.1 then
            nDelayTime = 0.1
        end
        Timer.Add(self, nDelayTime , function ()
            UIHelper.SetVisible(self.WidgetAnchorMiddle , true)
            UIHelper.SetVisible(self.widgetFullScreen , false)
            UIMgr.SetShowAllInLayer(UILayer.Scene, true)
            _onExcueSave()
        end)
    end
    UIHelper.SetVisible(self.WidgetSwitchHideMessage , false)
    UIHelper.SetVisible(self.WidgetSwitchHideName , false)
    UIHelper.SetVisible(self.WidgetAnchorBtn , false)
    if self.bEnableScaleSave and not (self.nHeight or self.nWidth) then
        -- 放大效果
        UIHelper.SetVisible(self.WidgetAnchorMiddle , false)
        UIHelper.SetVisible(self.widgetFullScreen , true)
        UIMgr.SetShowAllInLayer(UILayer.Scene, false)
        UIHelper.SetVisible(self.ImgFullLogo3, self.bSelectShowMessage)
        UIHelper.SetVisible(self.ImgFullQRCode ,  self.bSelectShowMessage)
        UIHelper.SetVisible(self.WidgetFullPlayerName,  self.bSelectShowPalyerInfo)
        
        Timer.AddFrame(self, 5, function ()
            local saveTime = GetTickCount()
            if self.bSelectShowMessage or self.bSelectShowPalyerInfo then
                if self.pMessageImage and safe_check(self.pMessageImage) then
                    self.pMessageImage:release()
                end
                UIHelper.CaptureScreen(function (pRetTexture , pImage)
                    self.pMessageImage = pImage
                    self.pCurImage = pImage
                _onSaveImageToLocalFile(GetTickCount() - saveTime)
                end, 1 , true)
            else
                _onSaveImageToLocalFile(1000)
            end
        end)
    elseif self.nHeight and self.nWidth then
        UIMgr.SetShowAllInLayer(UILayer.Scene, false)
        UIHelper.SetVisible(self.ImgBg, false)
        Timer.AddFrame(self, 5, function ()
            local saveTime = GetTickCount()
            if (self.bSelectShowMessage or self.bSelectShowPalyerInfo) then
                if self.pMessageImage and safe_check(self.pMessageImage) then
                    self.pMessageImage:release()
                end
                UIHelper.CaptureScreen(function (pRetTexture, pImage)
                    self.pMessageImage = pImage
                    self.pCurImage = pImage
                    _onSaveImageToLocalFile(GetTickCount() - saveTime)
                end, 1 , true)
            else
                _onSaveImageToLocalFile(1000)
            end
        end)
    else
        _onSaveImageToLocalFile(0)
    end
    if szChannel ~= "TuiLan" then
        XGSDK_TrackEvent("game.share.cameraPhoto", "share", {{"shareChannel", szChannel}})
    end
end

function UICameraPhotoShareView:OnSendTuiLan()
    TuiLanData.request_photo_token(false, self.szDefaultFilePath)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICameraPhotoShareView:UpdateInfo()
    self.WidgetAnchorBtn = UIHelper.GetParent(self.LayoutBtnShare)
    UIHelper.SetTextureWithBlur(self.ImgPhoto, self.picTexture)
    UIHelper.SetVisible(self.ImgQRCode,false)
    UIHelper.SetVisible(self.BtnShare ,false)
    UIHelper.SetVisible(self.BtnClose ,false)

    UIHelper.SetVisible(self.WidgetSwitchHideName ,false)

    self.nImageNodeOrW, self.nImageNodeOrH =  UIHelper.GetContentSize(self.ImgPhoto)
    self:AdjustViewScale()
    self.bShowRCode = true

    self:ShowShareButton(true)
    UIHelper.SetVisible(self.ImgLogo3 , false)
    self.pCurImage = self.pImage
    local tbServer = LoginMgr.GetModule(LoginModule.LOGIN_SERVERLIST).GetSelectServer()
    UIHelper.SetString(self.LabelServer , tbServer.szRealServer)
    UIHelper.SetString(self.LabelFullServer , tbServer.szRealServer)
    if g_pClientPlayer then
        local szPlayerName =  UIHelper.GBKToUTF8(g_pClientPlayer.szName)
        UIHelper.SetString(self.LabelPlayerName,szPlayerName)
        UIHelper.SetString(self.LabelFullPlayerName, szPlayerName)
        local compLuaBind = self.WidgetHead:getComponent("LuaBind")
        local scriptView = compLuaBind and compLuaBind:getScriptObject()
        if scriptView then
            scriptView:OnEnter(PlayerData.GetPlayerID())
        end
    end
    self.bSelectState = false
    UIHelper.SetVisible(self.WidgetPlayerName , false)
    UIHelper.SetVisible(self.ToggleHideMessage , not self.bHideMessageToggle)
    UIHelper.SetVisible(self.WidgetSwitchHideMessage ,not self.bHideMessageToggle)
    UIHelper.SetVisible(self.WidgetSwitchHideName , not self.bHideMessageToggle)
    UIHelper.SetVisible(self.ToggleHideName , not self.bHideMessageToggle)

    self:UpdateShareReward()
    if not self.bHideMessageToggle then
        UIHelper.SetSelected(self.ToggleHideMessage , true)
        UIHelper.SetSelected(self.ToggleHideName , true)
    end
    UIHelper.SetSpriteFrame(self.ImgQRCode ,AppReviewMgr.GetShaderCodeImage() )
    self:UpdateXHSRewardTip()

    UIHelper.SetTextureWithBlur(self.ImgFullPhoto, self.picTexture)


    UIHelper.SetSpriteFrame(self.ImgFullQRCode ,AppReviewMgr.GetShaderCodeImage() )

    if g_pClientPlayer then
        local compLuaBind = self.WidgetFullHead:getComponent("LuaBind")
        local scriptView = compLuaBind and compLuaBind:getScriptObject()
        if scriptView then
            scriptView:OnEnter(PlayerData.GetPlayerID())
        end
    end
end


function UICameraPhotoShareView:AdjustViewScale()
    local tbScreenSize = Platform.IsMac() and UIHelper.GetScreenSize() or UIHelper.DeviceScreenSize()
    local nodeW = self.nImageNodeOrW
    local nodeH = self.nImageNodeOrH
    local newNodeW = nodeH / tbScreenSize.height * tbScreenSize.width
    if newNodeW < tbScreenSize.width then
        nodeH = nodeW / tbScreenSize.width * tbScreenSize.height
    else
        nodeW = newNodeW
    end
    if self.nWidth and self.nHeight then
        if self.nHeight >= self.nWidth then -- 防止界面信息超框或重叠
            local bPortrait = nodeW < nodeH
            local nScaleW = self.nWidth / nodeW
            local nScaleH = self.nHeight / nodeH
            local nScaleW = math.min(nScaleW, nScaleH)
            UIHelper.SetScale(self.ImgQRCode, nScaleW, nScaleW)
            nScaleW = bPortrait and nScaleW or 1 - nScaleW -- 横屏的情况下需要填充空间
            UIHelper.SetScale(self.WidgetPlayerName, nScaleW, nScaleW)
            UIHelper.SetScale(self.ImgLogo3, nScaleW, nScaleW)
        end
        nodeW = self.nWidth
        nodeH = self.nHeight
    end
    UIHelper.SetContentSize(self.WidgetAnchorMiddle , nodeW , nodeH)
    UIHelper.SetContentSize(self.ImgPhoto , nodeW , nodeH)
    UIHelper.SetContentSize(self.MaskPhoto , nodeW , nodeH)
    UIHelper.SetContentSize(self.WIdgetPhotoWaterMark , nodeW , nodeH)
    UIHelper.SetContentSize(self.ImgBg , nodeW+20 , nodeH+20)
    UIHelper.SetPosition(self.WIdgetPhotoWaterMark ,0,0,self.WidgetAnchorMiddle)
    UIHelper.SetPosition(self.ImgPhoto ,0,0,self.MaskPhoto)
    UIHelper.SetPosition(self.MaskPhoto ,0,0,self.WidgetAnchorMiddle)
    UIHelper.SetPosition(self.ImgBg ,0,0,self.WidgetAnchorMiddle)
    UIHelper.WidgetFoceDoAlign(self)
    UIHelper.SetPosition(self.WidgetAnchorMiddle, 0, 0, self._rootNode)
    UIHelper.WidgetFoceDoAlignAssignNode(self, self.WidgetAnchorMiddle)
end


function UICameraPhotoShareView:ShowShareButton(isShow)
    if Channel.IsCloud() and not Channel.Is_WLColud() then
        UIHelper.SetVisible(self.LayoutBtnShare, false)
        return
    end

    local bVisible = isShow and Platform.IsMobile() and not AppReviewMgr.IsReview()
    UIHelper.SetVisible(self.BtnShareQQ , bVisible and AppReviewMgr.IsShowCameraShareChannel("qqimage"))
    UIHelper.SetVisible(self.BtnShareVX , bVisible and AppReviewMgr.IsShowCameraShareChannel("weichatfriend"))
    UIHelper.SetVisible(self.BtnSharePYQ , bVisible and AppReviewMgr.IsShowCameraShareChannel("weichatzone"))
    UIHelper.SetVisible(self.BtnShareWB , bVisible and AppReviewMgr.IsShowCameraShareChannel("weibo"))
    UIHelper.SetVisible(self.BtnShareXHS , bVisible and AppReviewMgr.IsShowCameraShareChannel("xhsnote"))
    UIHelper.SetVisible(self.BtnShareTap , bVisible and AppReviewMgr.IsShowCameraShareChannel("taptappublish"))
    UIHelper.SetVisible(self.BtnShareDY , bVisible and AppReviewMgr.IsShowCameraShareChannel("douyinpublish"))
    UIHelper.SetVisible(self.BtnSave , isShow)
    UIHelper.SetVisible(self.BtnAlbum , (Platform.IsWindows() and not Channel.Is_WLColud()) or Platform.IsMac())
    UIHelper.LayoutDoLayout(self.LayoutBtnShare)
end

function UICameraPhotoShareView:SetMessageImage(pImage)
    self.pMessageImage = pImage
end

function UICameraPhotoShareView:UpdateShareReward()
    local bVisible = not AppReviewMgr.IsReview() and not Channel.IsCloud() and not self.bHideMessageToggle
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

function UICameraPhotoShareView:IsHaveBuff()
    local player = GetClientPlayer()
    if player then
        return player.IsHaveBuff(28338, 1)
    else
        return false
    end
end

function UICameraPhotoShareView:SetPlayInfo(szRoleName , nRoleType,nForceID)
    UIHelper.SetString(self.LabelPlayerName, UIHelper.GBKToUTF8(szRoleName))
    local compLuaBind = self.WidgetHead:getComponent("LuaBind")
    local scriptView = compLuaBind and compLuaBind:getScriptObject()
    if scriptView then
        scriptView:SetHeadInfo(0,0,nRoleType,nForceID)
    end
end

function UICameraPhotoShareView:SetLogoNotHide(bNotHide)
   self.bLogoNotHide = bNotHide
end

function UICameraPhotoShareView:SetChangeTexture(pTexture)
    if self.pChangeTexture then
        if safe_check(self.pChangeTexture) then
            self.pChangeTexture:release()
        end
    end

    if safe_check(pTexture) then
        self.pChangeTexture = pTexture
        self.pChangeTexture:retain()
    end

    if safe_check(self.picTexture) then
        self.picTexture:retain()
    end

    UIHelper.SetVisible(self.WIdgetPhotoWaterMark, false)
    UIHelper.SetVisible(self.WidgetPlayerName, false)

    UIHelper.SetTextureWithBlur(self.ImgPhoto, self.pChangeTexture)
 end

function UICameraPhotoShareView:EnableScaleSave(bEnable)
    self.bEnableScaleSave = bEnable
end

function UICameraPhotoShareView:HidePlayerInfoToggle()
    UIHelper.SetVisible(self.WidgetSwitchHideName , false)
end

function UICameraPhotoShareView:UpdateXHSRewardTip(bChange)
    local bShow = false
    if self.widgetXHSRewardTip then
        if IsActivityOn(975) and not Storage.PhotoShare.bShareXHS then
            bShow = true
            if bChange then
                Storage.PhotoShare.bShareXHS = true
            end
        end  
    end
    UIHelper.SetVisible(self.widgetXHSRewardTip, bShow)
end

--[[
    蔚领云：特殊处理
    保存相册时，先将图片保存到wldcim这个地方先
    因为蔚领云服务器监控了dcim目录的文件新增，但是图片文件写入需要一个过程
    直接保存到dcim目录，会导致保存到云APP的图片会有残缺
    所以，先保存到wldcim，等保存完毕后，再拷贝到dcim目录
]]
function UICameraPhotoShareView:_getWLCloudFilePath()
    local folder = GetStreamAdaptiveDirPath(UIHelper.GBKToUTF8(GetFullPath("wldcim/")))
    CPath.MakeDir(folder)
    self.wlfullPath = GBKToUTF8(folder)
    if not self.wlfullPath then
        self.wlfullPath = folder
    end
    return self.wlfullPath
end

-- 蔚领云APP，将图片从 wldcim拷贝到dcim
function UICameraPhotoShareView:_copyFromWLCloudFileToDcim(wlFilepath, fileName)
    local data = Lib.GetStringFromFile(wlFilepath)
    Lib.WriteStringToFile(data, self.fullPath..fileName)
end

return UICameraPhotoShareView