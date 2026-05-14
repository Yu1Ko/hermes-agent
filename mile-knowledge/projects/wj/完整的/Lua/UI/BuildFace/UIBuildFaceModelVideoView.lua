-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBuildFaceModelVideoView
-- Date: 2024-04-15 15:25:34
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIBuildFaceModelVideoView = class("UIBuildFaceModelVideoView")

function UIBuildFaceModelVideoView:OnEnter(szRoleName)
    self.szRoleName = szRoleName
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
    NewFaceData.DelCacheCreateRoleFaceData()
end

function UIBuildFaceModelVideoView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    local moduleScene = LoginMgr.GetModule(LoginModule.LOGIN_SCENE)
    local ModleView = moduleScene.GetModel(LoginModel.FORCE_ROLE)
    if ModleView then
        ModleView:EndReshape()
        ModleView:EndFaceHighlightMgr()
        ModleView.UpdateRoleModel()
    end
    UIHelper.HideFullScreenSFX()
    BuildFaceData.SetInBuildMode(false)
end

function UIBuildFaceModelVideoView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose , EventType.OnClick , function ()
        LoginMgr.SwitchStep(LoginModule.LOGIN_ROLELIST, self.szRoleName)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnNext , EventType.OnClick , function ()
        LoginMgr.GetModule(LoginModule.LOGIN_ROLE).OnEnterGame()
    end)
    UIHelper.BindUIEvent(self.BtnShare , EventType.OnClick , function ()
        self.nCaptureIndex = self.nCaptureIndex + 1
        self:CaptureScreenByMessage()
    end)

    UIHelper.BindUIEvent(self.BtnH5 , EventType.OnClick , function ()
        BuildPresetData.OpenFreeUrl( UIHelper.GBKToUTF8(self.szRoleName) ,0 , KUNGFU_ID_FORCE_TYPE[BuildPresetData.nCreateForceID] , 0)
    end)
    UIHelper.SetVisible(self.BtnH5, false)
end

function UIBuildFaceModelVideoView:RegEvent()
    Event.Reg(self, "LOGIN_NOTIFY", function(nEvent)
		if nEvent == LOGIN.REQUEST_LOGIN_GAME_SUCCESS or nEvent == LOGIN.MISS_CONNECTION then
			Timer.Add(self, 0.3, function ()
                UIMgr.Close(self)
            end)
		end
    end)
end

function UIBuildFaceModelVideoView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIBuildFaceModelVideoView:UpdateInfo()
    self.nCaptureIndex = 0
    local nCameraStatus = LoginCameraStatus.ROLE_LIST
    local moduleCamera = LoginMgr.GetModule(LoginModule.LOGIN_CAMERA)
    moduleCamera.SetCameraStatus(nCameraStatus,  BuildPresetData.nCreateRoleType)

    local tbServer = LoginMgr.GetModule(LoginModule.LOGIN_SERVERLIST).GetSelectServer()

    UIHelper.SetString(self.LabelServer , tbServer.szRealServer)
    UIHelper.SetString(self.LabelPlayerName, UIHelper.GBKToUTF8(self.szRoleName))

    local compLuaBind = self.WidgetHead:getComponent("LuaBind")
	local scriptView = compLuaBind and compLuaBind:getScriptObject()
    if scriptView then
        scriptView:SetHeadInfo(0,0,BuildPresetData.nCreateRoleType,KUNGFU_ID_FORCE_TYPE[BuildPresetData.nCreateForceID])
    end

    local szImgSchool = PlayerKungfuID2SchoolImg_2[BuildPresetData.nCreateForceID]
    local szImgPoem = PlayerKungfuID2SchoolImgPoem[BuildPresetData.nCreateForceID]
    UIHelper.SetSpriteFrame(self.ImgSchoolBg, szImgSchool)
    UIHelper.SetSpriteFrame(self.ImgSchoolPoem, szImgPoem)

    BuildPresetData.ResetPlayAnimation(BuildPresetData.szLastAnimation)



    local moduleCamera = LoginMgr.GetModule(LoginModule.LOGIN_CAMERA)
    local moduleRole = LoginMgr.GetModule(LoginModule.LOGIN_ROLE)
    local nCameraStatus = LoginCameraStatus.BUILD_FACE_STEP2_SHARE
    moduleRole.UpdateModelScale()
    moduleCamera.SetCameraStatus(nCameraStatus, BuildPresetData.nCreateRoleType)

    self.WidgetShareParent = UIHelper.GetParent(self.BtnShare)

    UIHelper.SetVisible(self.WidgetShareParent , not AppReviewMgr.IsReview() )

    local WidgetAnchorRight = UIHelper.FindChildByName(self.WidgetShare , "WidgetAnchorRight")
    local WidgetAnchorRightBotom = UIHelper.FindChildByName(WidgetAnchorRight , "WidgetAnchorRightBotom")
    local ImgQRCode = UIHelper.FindChildByName(WidgetAnchorRightBotom , "ImgCode")
    UIHelper.SetVisible(ImgQRCode , AppReviewMgr.IsOpenShaderCode())
    UIHelper.SetSpriteFrame(ImgQRCode ,AppReviewMgr.GetShaderCodeImage() )
end

function UIBuildFaceModelVideoView:CaptureScreenByMessage()
    -- 此时在截一张带信息的全屏图
    UIHelper.SetVisible(self.WidgetShare , true)
    UIHelper.SetVisible(self.BtnNext , false)
    UIHelper.SetVisible(self.WidgetShareParent, false)
    UIHelper.SetVisible(self.BtnClose , false)
    cc.utils:setIgnoreAgainCapture(true)
    local folder = GetStreamAdaptiveDirPath(UIHelper.GBKToUTF8(GetFullPath("dcim/")))
    local dt = TimeToDate(GetCurrentTime())
    CPath.MakeDir(folder)
    local fileName = string.format("%d_%04d%02d%02d%02d%02d%02d.png",self.nCaptureIndex,dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second)
    Timer.Add(self , 0.2 , function ()
        UIHelper.CaptureScreen(function (pRetTexture , pImage)
            self.nPhotoshareViewID = VIEW_ID.PanelCameraPhotoShare
            if not UIMgr.GetView(self.nPhotoshareViewID) then
                local shareScript = UIMgr.Open(self.nPhotoshareViewID , pRetTexture ,pImage , folder,fileName, function ()
                    UIHelper.SetVisible(self.BtnNext , true)
                    UIHelper.SetVisible(self.WidgetShareParent , not AppReviewMgr.IsReview())
                    UIHelper.SetVisible(self.BtnClose , true)
                    UIHelper.SetVisible(self.WidgetShare , false)
                end,self.pMessageImage,true)
                shareScript:SetLogoNotHide(true)
                shareScript:SetPlayInfo(self.szRoleName ,BuildPresetData.nCreateRoleType , KUNGFU_ID_FORCE_TYPE[BuildPresetData.nCreateForceID])
            end
        end, 1 , true)
    end)
end

return UIBuildFaceModelVideoView