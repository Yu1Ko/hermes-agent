-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UISelfieMainView
-- Date: 2023-04-23 10:56:24
-- Desc: 幻境云图主界面/个人名片设置
-- PanelCamera
-- ---------------------------------------------------------------------------------

local UISelfieMainView = class("UISelfieMainView")
local FREEZE_START_SKILL = 17799
local FREEZE_END_SKILL = 17800
local MIN_FACE_COUNT = 8
local THUMBNAIL_DIS = 5 * 64

local tbGSRSnapShotGPUModel = {
    ["Apple A9X GPU"] = true,
}

local _VIDEO_BASE_LEVEL_2_BLUR_SIZE =
{
    [CONFIGURE_LEVEL.LOWEST] = 5,
    [CONFIGURE_LEVEL.LOW_MOST] = 5,
    [CONFIGURE_LEVEL.LOW] = 10,
    [CONFIGURE_LEVEL.MEDIUM] = 10,
    [CONFIGURE_LEVEL.HIGH] = 15,
    [CONFIGURE_LEVEL.PERFECTION] = 20,
    [CONFIGURE_LEVEL.HD] = 25,
    [CONFIGURE_LEVEL.PERFECT] = 25,
    [CONFIGURE_LEVEL.EXPLORE] = 25,
}

local INTERACTION_STATE =
{
    None = 1,
    Camera = 2,
    Video = 3,
    VideoTime = 4,
}

local SIZE_TYPE =
{
    FullScreen = 1,  -- 全屏
    Ratio9To16 = 2,  -- 9：16
    Ratio1To1 = 3,   -- 1：1
    Ratio16To9 = 4,  -- 16：9
    Ratio3To4 = 5,  -- 3：4
}

local MIN_SIZE_SCALE = 0.5

local SIZE_TYPE_TO_RATIO =
{
    [SIZE_TYPE.FullScreen] = 1,
    [SIZE_TYPE.Ratio9To16] = 9 / 16,
    [SIZE_TYPE.Ratio1To1] = 1,
    [SIZE_TYPE.Ratio16To9] = 16 / 9,
    [SIZE_TYPE.Ratio3To4] = 3 / 4,
}

---- 基础相关
local _MAX_CAMERA_DIST = 3000  --- 最大摄像机距离
local cameraMoveRate = 0.2
local tReservedData = {}
local nVideoMaxTime = 60

local nDragX = 0
local nDragY = 0

local m_bShotting = false
local m_bLookAt = false
local m_bFocus = false
local m_bBloomEnable = false
local m_bCheckFaceMotionEdit = false
local m_bInFaceMotionEdit = false

local m_bEnableRecordVideo = true

function UISelfieMainView:OnEnter(bNameCard, nIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        SelfieData.Enter()
        ShareCodeData.Init(false)
    end

    self.bNameCard = bNameCard
    self.nPersonalCardIndex = nIndex
    self.bCanSwitchUI = false
    self.eInteractionState = INTERACTION_STATE.Camera
    self.nSizeMode = SIZE_TYPE.FullScreen

    UIHelper.SetVisible(self.BtnTemplateImport , true)
    UIHelper.SetVisible(self.BtnTemplateExport , true)
    UIHelper.SetVisible(self.BtnCloudImport , true)
    UIHelper.SetVisible(self.BtnCloudExport, true)

    SelfieData.bCanSetFuncInfo = true
    self:UpdateInfo()
    if not bNameCard then
        self:OpenThumbnailParse()
    end
    Event.Dispatch(EventType.OnSetSystemMenuCloseBtnEnabled, false)
    Event.Dispatch(EventType.EnterSelfieMode, true)
    self:HideLayer()
    UIHelper.SetVisible(self._rootNode, true)
    if bNameCard then
        UIHelper.SetButtonState(self.BtnCamera, BTN_STATE.Disable, "请等待2秒后再试")
        Timer.Add(self, 2, function()
            UIHelper.SetButtonState(self.BtnCamera, BTN_STATE.Normal)
        end)
    end
    ShortcutInteractionData.SetEnableKeyBoard(false)

    local tShortcutInfoZoomIn = ShortcutInteractionData.GetShortcutInfoByDef(ShortcutDef.CameraZoomIn)
    local tShortcutInfoZoomOut = ShortcutInteractionData.GetShortcutInfoByDef(ShortcutDef.CameraZoomOut)
    local tZoomShortcut = { tShortcutInfoZoomIn.VKey, tShortcutInfoZoomOut.VKey }

    self.tZoomShortcutRevert = {}
    for _, VKey in pairs(tZoomShortcut) do
        if not table.contain_value(ShortcutInteractionData.tbIgnoreOnDisable, VKey) then
            table.insert(ShortcutInteractionData.tbIgnoreOnDisable, VKey)
            table.insert(self.tZoomShortcutRevert, VKey)
        end
    end
    if SelfieData.bOpenAgain then
        if SelfieData.IsInStudioMap() then
            self:OpenStudio()
        end
    end
    SelfieData.bOpenAgain = false
    FilterDef.CameraSize.Reset()

    SelfieData.bEnableBloom = KG3DEngine.GetMobileEngineOption().bEnableBloom
    SelfieData.UpdateLightDefaultParam()
    self.cameraSettingLua:UpdateDefaultScript()
    self:UpdateDownloadEquipRes()
    local tPhotoData = SelfieTemplateBase.GetTemplateData()
    if tPhotoData and not IsTableEmpty(tPhotoData) then
        self:SwitchQulity(function ()
            self:OpenImportDataPanel(tPhotoData)
        end)
    end

    if ShareStationData.szImportPhotoCode then
        ShareCodeData.ApplyData(false, SHARE_DATA_TYPE.PHOTO, ShareStationData.szImportPhotoCode)
        ShareStationData.szImportPhotoCode = nil
    end

    if IsDebugClient() then
        self.bUseAISign = false
        self.bUseAIParam = false
        AddMovieAISign(self.bUseAISign,self.bUseAIParam)
    end
end

function UISelfieMainView:OnExit()
    SelfieTemplateBase.CancelPhotoActionDataUse()
    SelfieTemplateBase.CancelFaceActionUse()
    SelfieTemplateBase.SetTemplateImportState(false)
    InputHelper.LockMove(false)

    CameraMgr.SetCameraFov(tReservedData.fCameraFovInRadian)
    local bIsPortrait = UIHelper.GetScreenPortrait()
    if bIsPortrait and self._nViewID == VIEW_ID.PanelCameraVertical then
        UIHelper.SetScreenPortrait(false)
    end
    self.bInit = false
    self:UnRegEvent()

    SelfieData.Leave()
    Event.Dispatch(EventType.EnterSelfieMode, false)
    Event.Dispatch(EventType.OnSetSystemMenuCloseBtnEnabled, true)
    self:ShowLayer()
    self:ReleaseFrame()

    if self.bNameCard then
        -- self:RevertNameSetting()
        local nViewID = VIEW_ID.PanelPersonalCard
        if not UIMgr.GetView(nViewID) then
            UIMgr.Open(nViewID)
        end
    end
    ShortcutInteractionData.SetEnableKeyBoard(true)
    for _, VKey in pairs(self.tZoomShortcutRevert or {}) do
        table.remove_value(ShortcutInteractionData.tbIgnoreOnDisable, VKey)
    end
    if not SelfieData.bIsWaitSwitchPortrait then
        SelfieData.StopCameraCapture()
    end
    self:StopRecordScreen()
    if self.eInteractionState == INTERACTION_STATE.VideoTime then
        if self.szRecordScreenFileName then
            cc.FileUtils:getInstance():removeFile(UIHelper.UTF8ToGBK(self.szRecordScreenFilePath..self.szRecordScreenFileName))
            self.szRecordScreenFileName = nil
        end
    end
    if self.nCurServantNpcIndex and self.nCurServantNpcIndex > 0 then
		Servant_CallServantByID(self.nCurServantNpcIndex, true)
	else
		Servant_DismissServantByID()
	end
    SelfieData.ShowClothWind(false)
    self:CloseThumbnailParse()
    if self.nDownloadDynamicID then
        PakDownloadMgr.ReleaseDynamicPakInfo(self.nDownloadDynamicID)
        self.nDownloadDynamicID = nil
    end
    if UIMgr.GetView(VIEW_ID.PanelCameraSettingRight) then
        UIMgr.Close(VIEW_ID.PanelCameraSettingRight)
        self.camerRightSettingLua = nil
    end
    if AiBodyMotionData.IsAIFeatureInWhitelist() and AiBodyMotionData.IsMaxLevel() then
        AiBodyMotionData.StopAIAction()
        AiBodyMotionData.StopFaceMotion()
    end
end

function UISelfieMainView:BindUIEvent()
    
    UIHelper.SetSwallowTouches(self.BtnBg , false)

    UIHelper.BindUIEvent(self.TogSetting , EventType.OnClick , function ()
        self:OnOpenSettingView()
    end)

    UIHelper.BindUIEvent(self.TogAction , EventType.OnClick , function ()
        self:OnOpenActionView()
    end)

    UIHelper.BindUIEvent(self.TogSizeBox , EventType.OnClick , function ()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.TogSizeBox, TipsLayoutDir.AUTO, FilterDef.CameraSize)
    end)

    self.BtnCompleteFilm = UIHelper.FindChildByName(self.WIdgetAchorRight, "BtnCompleteFilm")
    self.BtnCameraMoving = UIHelper.FindChildByName(self.WIdgetAchorRight, "BtnCameraMoving")
    self.BtnCameraMusic = UIHelper.FindChildByName(self.WIdgetAchorRight, "BtnCameraMusic")
    self.BtnMotionCapture = UIHelper.FindChildByName(self.WIdgetAchorRight, "BtnMotionCapture")

    UIHelper.SetVisible(self.BtnCompleteFilm,  true)
    UIHelper.SetVisible(self.BtnCameraMoving, true)
    UIHelper.SetVisible(self.BtnCameraMusic, true)
    UIHelper.SetVisible(self.BtnMotionCapture, true)
    if not AiBodyMotionData.IsAIFeatureInWhitelist() then
        UIHelper.SetButtonState(self.BtnMotionCapture, BTN_STATE.Disable, "封闭测试中，敬请期待")
    elseif not AiBodyMotionData.IsMaxLevel() then
        UIHelper.SetButtonState(self.BtnMotionCapture, BTN_STATE.Disable)
        UIHelper.SetVisible(UIHelper.FindChildByName(self.BtnMotionCapture,"WidgetMotionCaptureLocked"), true)
    else
        UIHelper.SetButtonState(self.BtnMotionCapture, BTN_STATE.Normal)
    end
    

    UIHelper.BindUIEvent(self.BtnCameraMusic, EventType.OnClick , function ()
        self:OpenRightSettingView(SELFIE_CAMERA_RIGHT_TYPE.MUSIC)
    end)

    UIHelper.BindUIEvent(self.BtnCameraMoving, EventType.OnClick , function ()
        self:OpenRightSettingView(SELFIE_CAMERA_RIGHT_TYPE.MOVIE)
    end)

    UIHelper.BindUIEvent(self.BtnMotionCapture, EventType.OnClick , function ()
        self:OpenRightSettingView(SELFIE_CAMERA_RIGHT_TYPE.AIGC)
    end)

    UIHelper.BindUIEvent(self.BtnCompleteFilm, EventType.OnClick , function ()
        self:OpenOneClickView()
    end)

    UIHelper.BindUIEvent(self.BtnPhotoStutio , EventType.OnClick , function ()
        self.studioLua:Open()
        UIHelper.SetVisible(self.WIdgetAchorRight , false)
        UIHelper.SetVisible(self.WidgetAnchorLowerRight , false)
        UIHelper.SetVisible(self.WidgetCameraZoomSlier , false)
        self:UpdateSwitchUI()
    end)

    UIHelper.BindUIEvent(self.BtnRenovate , EventType.OnClick , function ()
       self:OnClickResetCamera()
    end)

    UIHelper.BindUIEvent(self.BtnRenovate2 , EventType.OnClick , function ()
        self:OnClickResetCamera()
     end)

    UIHelper.BindUIEvent(self.BtnChange , EventType.OnClick , function ()
        self:ChangeSkillPanel()
    end)

    UIHelper.BindUIEvent(self.BtnTemplateImport , EventType.OnClick , function ()
        local hPlayer = GetClientPlayer()
        if not hPlayer then
            return
        end
        local tPhotoData, szError
        if Platform.IsWindows() and GetOpenFileName then
            local szFile = GetOpenFileName(g_tStrings.PHOTO_LIFT_CHOOSE_FILE, g_tStrings.STR_PHOTO_LIFT_CHOOSE_DAT .. "(*.dat)\0*.dat\0\0")
            Timer.AddFrame(self, 1, function ()
                if not string.is_nil(szFile) then
                    tPhotoData, szError = SelfieTemplateBase.LoadPhotoData(szFile)
                    self.exportLua:Hide()
                    self.importLua:Hide()
                    self:OpenImportDataPanel(tPhotoData)
                end
            end)
        else
            UIMgr.Open(VIEW_ID.PanelCameraCodeListLocal, function (szFile)
                if not Platform.IsWindows() then
                    szFile = UIHelper.UTF8ToGBK(GetFullPath(szFile))
                end
                tPhotoData, szError = SelfieTemplateBase.LoadPhotoData(szFile)
                self.exportLua:Hide()
                self.importLua:Hide()
                self:OpenImportDataPanel(tPhotoData)
            end)
        end
    end)

    UIHelper.BindUIEvent(self.BtnTem, EventType.OnClick , function ()
        --- todo 当前导入模板
        local hPlayer = GetClientPlayer()
        if not hPlayer then
            return
        end
        if self.importLua:IsOpen() then
            self.importLua:Hide()
        else
            self.importLua:Show()
            UIHelper.SetVisible(self.WIdgetAchorRight , false)
            UIHelper.SetVisible(self.WidgetAnchorLowerRight , false)
            UIHelper.SetVisible(self.WidgetCameraZoomSlier , false)
            self:UpdateSwitchUI()
        end
    end)

    UIHelper.BindUIEvent(self.BtnTemplateExport , EventType.OnClick , function ()
        --- todo 本地拍照模板导出
        local hPlayer = GetClientPlayer()
        if not hPlayer then
            return
        end
        self.importLua:Hide()
        self.exportLua:Hide()
        self.bOnExport = true
        self:DoUploadToLocal()
    end)

    UIHelper.BindUIEvent(self.BtnCloudImport , EventType.OnClick , function ()
        self.importLua:Hide()
        self.exportLua:Hide()
        UIMgr.Open(VIEW_ID.PanelEnterFaceCode, SHARE_DATA_TYPE.PHOTO)
    end)

    UIHelper.BindUIEvent(self.BtnCloudExport , EventType.OnClick , function ()
        -- if not ShareStationData.GetOpenState() then
        --     TipsHelper.ShowNormalTip("部分功能升级维护中，暂时无法上传作品")
        --     return
        -- end

        local _, scriptTips = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetTipMoreOper, self.BtnCloudExport)
        scriptTips:OnEnter({ -- 正式服屏蔽
        {
            szName = self.bNameCard and "上传名片模板" or "上传拍照模板",
            OnClick = function ()
                local bIsPortrait = UIHelper.GetScreenPortrait()
                local nPhotoSizeType = bIsPortrait and SHARE_PHOTO_SIZE_TYPE.VERTICAL or SHARE_PHOTO_SIZE_TYPE.HORIZONTAL
                if self.bNameCard then
                    nPhotoSizeType = SHARE_PHOTO_SIZE_TYPE.CARD
                elseif not bIsPortrait then
                    local nRatio = SIZE_TYPE_TO_RATIO[self.nSizeMode] or 1
                    nPhotoSizeType = nRatio >= 1 and SHARE_PHOTO_SIZE_TYPE.HORIZONTAL or SHARE_PHOTO_SIZE_TYPE.VERTICAL
                end
                self:DoUploadToShareStaton(SHARE_DATA_TYPE.PHOTO, nPhotoSizeType)
                TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
            end
        },
        {
            szName = "上传穿搭",
            bDisabled = self.bNameCard or self.nSizeMode ~= SIZE_TYPE.FullScreen,
            OnClick = function ()
                self:DoUploadToShareStaton(SHARE_DATA_TYPE.EXTERIOR)
                TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
            end
        },
        {
            szName = "上传体型",
            bDisabled = self.bNameCard or self.nSizeMode ~= SIZE_TYPE.FullScreen,
            OnClick = function ()
                self:DoUploadToShareStaton(SHARE_DATA_TYPE.BODY)
                TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
            end
        },
        {
            szName = "上传脸型",
            bDisabled = self.bNameCard or self.nSizeMode ~= SIZE_TYPE.FullScreen,
            OnClick = function ()
                self:DoUploadToShareStaton(SHARE_DATA_TYPE.FACE)
                TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
            end
        }, })
    end)

    UIHelper.BindUIEvent(self.BtnDesignStation , EventType.OnClick , function ()
        self:LinkToShareStation()
    end)

    UIHelper.BindUIEvent(self.TogHide , EventType.OnClick , function ()
       for k, v in pairs(self.tbHideWidget) do
            UIHelper.SetVisible(v , false)
       end
       UIHelper.SetVisible(self.BtnAR, false)
       UIHelper.SetVisible(self.BtnARMessage, false)
       UIHelper.SetVisible(self.BtnSwitchUI, false)

        UIHelper.SetVisible(self.BtnCompleteFilm,  false)
        UIHelper.SetVisible(self.BtnCameraMoving, false)
        UIHelper.SetVisible(self.BtnCameraMusic, false)
        UIHelper.SetVisible(self.BtnMotionCapture, false)

       UIHelper.LayoutDoLayout(self.WIdgetAchorRight)
       self.bClickToggleHide = not self.bClickToggleHide
    end)

    UIHelper.BindUIEvent(self.BtnBack , EventType.OnClick , function ()
        for k, v in pairs(self.tbHideWidget) do
             UIHelper.SetVisible(v , true)
        end
        local bShowARBtn = GetCameraCaptureState() == CAMERA_CAPTURE_STATE.Capturing
        UIHelper.SetVisible(self.BtnAR, SelfieData.IsDeviceAvailableCamera())
        UIHelper.SetVisible(self.BtnARMessage, bShowARBtn)
        UIHelper.SetVisible(self.BtnSwitchUI, bShowARBtn)
        UIHelper.SetVisible(self.BtnPortrait , Platform.IsMobile())
        UIHelper.SetVisible(self.BtnHotKeys, Platform.IsWindows() and not Channel.Is_WLColud())
        UIHelper.SetVisible(self.BtnBack , false)

        UIHelper.SetVisible(self.BtnCompleteFilm,  true)
        UIHelper.SetVisible(self.BtnCameraMoving, true)
        UIHelper.SetVisible(self.BtnCameraMusic, true)
        UIHelper.SetVisible(self.BtnMotionCapture, true)

        UIHelper.LayoutDoLayout(self.WIdgetAchorRight)
        self.bClickToggleHide = not self.bClickToggleHide
     end)

    UIHelper.BindUIEvent(self.BtnClose , EventType.OnClick , function ()
        if Platform.IsIos() then
            local bPortrait = UIHelper.GetScreenPortrait()
            if bPortrait then
                if UIMgr.GetView(VIEW_ID.PanelCamera) then
                    UIMgr.Close(VIEW_ID.PanelCamera)
                end

            else
                if UIMgr.GetView(VIEW_ID.PanelCameraVertical) then
                    UIMgr.Close(VIEW_ID.PanelCameraVertical)
                end
            end
            SelfieTemplateBase.CancelPhotoActionDataUse()
            SelfieTemplateBase.CancelFaceActionUse()
            SelfieTemplateBase.SetTemplateImportState(false)
        end
        SelfieData.bOpenAgain = false
        if self._nViewID == VIEW_ID.PanelCameraVertical then
            self:SwitchPortrait()
        else
            UIMgr.Close(self)
            SelfieTemplateBase.CancelPhotoActionDataUse()
            SelfieTemplateBase.CancelFaceActionUse()
            SelfieTemplateBase.SetTemplateImportState(false)
        end
    end)
    UIHelper.SetButtonClickSound(self.BtnBg, "")
    UIHelper.BindUIEvent(self.BtnBg , EventType.OnClick , function ()
        if self.bClickToggleHide then
            local togVisible = UIHelper.GetVisible(self.BtnBack)
            UIHelper.SetVisible(self.BtnBack , not togVisible)
            UIHelper.LayoutDoLayout(self.WIdgetAchorRight)
        else
            if  self.cameraSettingLua and self.cameraSettingLua:IsOpen() then
                self.cameraSettingLua:Hide()
            end
            if  self.emotionActionLua and self.emotionActionLua:IsOpen()  then
                self.emotionActionLua:Hide()
            end

            if  self.studioLua and self.studioLua:IsOpen()  then
                self.studioLua:Hide()
            end
        end
    end)

    UIHelper.BindUIEvent(self.BtnCamera , EventType.OnClick , function ()
        self:OnShutterDown()
    end)
    UIHelper.BindUIEvent(self.BtnCamera2 , EventType.OnClick , function ()
        self:OnShutterDown()
    end)

    UIHelper.BindUIEvent(self.TogRevolve , EventType.OnClick , function ()
        if self._nViewID == VIEW_ID.PanelCameraVertical then
            if Platform.IsIos() and (not UIHelper.GetScreenPortrait()) then
                return
            end
            self:SwitchPortrait()
        else
            CameraMgr.ResetOffset()
        end
    end)

    UIHelper.SetClickInterval(self.TogPause, 0)
    UIHelper.SetClickInterval(self.TogPause2, 0)
    UIHelper.BindUIEvent(self.TogPause , EventType.OnClick , function ()
        self:OnClickTogPause()
        UIHelper.SetSelected(self.TogPause2, UIHelper.GetSelected(self.TogPause), false)
    end)
    UIHelper.BindUIEvent(self.TogPause2 , EventType.OnClick , function ()
        self:OnClickTogPause()
        UIHelper.SetSelected(self.TogPause, UIHelper.GetSelected(self.TogPause2), false)
    end)

    UIHelper.SetClickInterval(self.TogLine, 0)
    UIHelper.SetClickInterval(self.TogLine2, 0)
    UIHelper.BindUIEvent(self.TogLine , EventType.OnClick , function ()
        UIHelper.SetSelected(self.TogLine2, UIHelper.GetSelected(self.TogLine), false)
    end)
    UIHelper.BindUIEvent(self.TogLine2 , EventType.OnClick , function ()
        UIHelper.SetSelected(self.TogLine, UIHelper.GetSelected(self.TogLine2), false)
    end)

    UIHelper.SetVisible(self.BtnPortrait, Platform.IsMobile())
    UIHelper.BindUIEvent(self.BtnPortrait, EventType.OnClick , function ()
        self:SwitchPortrait()
    end)

    UIHelper.SetVisible(self.BtnHotKeys, Platform.IsWindows() and not Channel.Is_WLColud())
    UIHelper.BindUIEvent(self.BtnHotKeys, EventType.OnClick , function ()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetConstructionHotKeysTip, self.BtnHotKeys, TipsLayoutDir.TOP_LEFT , "Selfie")
    end)

    UIHelper.SetVisible(self.BtnAR, SelfieData.IsDeviceAvailableCamera())
    UIHelper.BindUIEvent(self.BtnAR, EventType.OnClick , function ()
        if self.bNameCard then
            TipsHelper.ShowImportantBlueTip("名片拍摄状态无法使用")
            return
        end
        -- if self.eInteractionState == INTERACTION_STATE.VideoTime then
        --     TipsHelper.ShowImportantBlueTip("录像状态下无法使用")
        --     return
        -- end
        if g_pClientPlayer and g_pClientPlayer.nLevel < 120 then
            TipsHelper.ShowImportantBlueTip("侠士达到120级后方可开启增强现实")
            return
        end
        if Channel.IsCloud() then
            TipsHelper.ShowImportantBlueTip("云游戏暂不支持此功能")
            return
        end

        if not Storage.Selfie.bAcceptARConsent then
            if not UIMgr.IsViewOpened(VIEW_ID.PanelCameraARMessagePop) then
                local function fnCallback()
                    if not UIMgr.IsViewOpened(VIEW_ID.PanelCamera) and not UIMgr.IsViewOpened(VIEW_ID.PanelCameraVertical) then
                        return
                    end
                    SelfieData.StartCameraCapture()
                end
                UIMgr.Open(VIEW_ID.PanelCameraARMessagePop, fnCallback)
            end
            return
        end

        local nState = GetCameraCaptureState()
        if nState == CAMERA_CAPTURE_STATE.Capturing then
            SelfieData.StopCameraCapture()
        elseif nState == CAMERA_CAPTURE_STATE.Stop then
            SelfieData.StartCameraCapture()
        elseif nState == CAMERA_CAPTURE_STATE.Wait4Authorize then
            return
        end
    end)

    UIHelper.BindUIEvent(self.BtnARMessage, EventType.OnClick, function()
        if not UIMgr.IsViewOpened(VIEW_ID.PanelCameraARMessagePop) then
            UIMgr.Open(VIEW_ID.PanelCameraARMessagePop)
        end
    end)

    UIHelper.BindUIEvent(self.BtnSwitchUI, EventType.OnClick, function()
        Storage.Selfie.bSwitchUI = not Storage.Selfie.bSwitchUI
        Storage.Selfie.Flush()
        self:UpdateSwitchUI()
    end)



    UIHelper.BindUIEvent(self.WidgetCameraRemove, EventType.OnTouchBegan, function(btn, nX, nY)
        self:UpdateCameraRemove(nX, nY)
        UIHelper.SetVisible(self.WidgetRemoveLight, true)
        self:OpenCameraRemove(true)
    end)

    UIHelper.BindUIEvent(self.WidgetCameraRemove, EventType.OnTouchMoved, function(btn, nX, nY)

        self:UpdateCameraRemove(nX, nY)
    end)

    UIHelper.BindUIEvent(self.WidgetCameraRemove, EventType.OnTouchEnded, function(btn, nX, nY)
        UIHelper.SetPosition(self.ImgCameraRemove, self.nCameraRemoveOrgiX, self.nCameraRemoveOrgiY)
        UIHelper.SetVisible(self.WidgetRemoveLight, false)
        self:OpenCameraRemove(false)
    end)

    UIHelper.BindUIEvent(self.WidgetCameraRemove, EventType.OnTouchCanceled, function(btn, nX, nY)
        UIHelper.SetPosition(self.ImgCameraRemove, self.nCameraRemoveOrgiX, self.nCameraRemoveOrgiY)
        UIHelper.SetVisible(self.WidgetRemoveLight, false)
        self:OpenCameraRemove(false)
    end)

    UIHelper.BindUIEvent(self.WidgetCameraRevolve, EventType.OnTouchBegan, function(btn, nX, nY)
        self.nCameraRevolveTouch_X = nX
        self.nCameraRevolveTouch_Y = nY
        self:UpdateCameraRevolve(nX, nY)
    end)

    UIHelper.BindUIEvent(self.WidgetCameraRevolve, EventType.OnTouchMoved, function(btn, nX, nY)
        self.nCameraRevolveTouch_X = nX
        self.nCameraRevolveTouch_Y = nY
        self:UpdateCameraRevolve(nX, nY)
    end)

    UIHelper.BindUIEvent(self.WidgetCameraRevolve, EventType.OnTouchEnded, function(btn, nX, nY)
        UIHelper.SetPosition(self.ImgCameraRevole, self.nCameraRevoleOrgiX, self.nCameraRevoleOrgiY)
    end)

    UIHelper.BindUIEvent(self.WidgetCameraRevolve, EventType.OnTouchCanceled, function(btn, nX, nY)
        UIHelper.SetPosition(self.ImgCameraRevole, self.nCameraRevoleOrgiX, self.nCameraRevoleOrgiY)
    end)

    UIHelper.BindUIEvent(self.Btneyes, EventType.OnTouchBegan, function(btn, nX, nY)
        SelfieData.tLookAtPos = {x = nX, y = nY,}
        self:Lookat(nX, nY)
    end)

    UIHelper.BindUIEvent(self.Btneyes, EventType.OnTouchMoved, function(btn, nX, nY)
        SelfieData.tLookAtPos = {x = nX, y = nY,}
        self:Lookat(nX, nY)
    end)

    UIHelper.BindUIEvent(self.TogPauseFriend , EventType.OnSelectChanged , function (btn , bSelect)
        if bSelect then
            Servant_Freeze()
        else
            Servant_CancelFreeze()
        end
        UIHelper.SetSelected(self.TogPauseFriend2, bSelect, false)
    end)
    UIHelper.BindUIEvent(self.TogPauseFriend2 , EventType.OnSelectChanged , function (btn , bSelect)
        if bSelect then
            Servant_Freeze()
        else
            Servant_CancelFreeze()
        end
        UIHelper.SetSelected(self.TogPauseFriend, bSelect, false)
    end)

    UIHelper.SetClickInterval(self.TogPauseFaceEmotion, 0)
    UIHelper.SetClickInterval(self.TogPauseFaceEmotion2, 0)
    UIHelper.BindUIEvent(self.TogPauseFaceEmotion, EventType.OnSelectChanged , function (btn , bSelect)
        if bSelect then
            self:StartFaceMotionEdit()
        else
            self:EndFaceMotionEdit()
        end
        UIHelper.SetSelected(self.TogPauseFaceEmotion2, UIHelper.GetSelected(self.TogPauseFaceEmotion), false)
    end)
    UIHelper.BindUIEvent(self.TogPauseFaceEmotion2, EventType.OnSelectChanged , function (btn , bSelect)
        if bSelect then
            self:StartFaceMotionEdit()
        else
            self:EndFaceMotionEdit()
        end
        UIHelper.SetSelected(self.TogPauseFaceEmotion, UIHelper.GetSelected(self.TogPauseFaceEmotion2), false)
    end)

    UIHelper.BindUIEvent(self.SliderActionLine , EventType.OnChangeSliderPercent , function (SliderEventType, nSliderEvent)
        if nSliderEvent == ccui.SliderEventType.percentChanged then
            self:StartAniEdit()
            local sliderValue = UIHelper.GetProgressBarPercent(self.SliderActionLine)
            if sliderValue >= 100 then
                sliderValue = 99
            end
            UIHelper.SetProgressBarPercent(self.SliderActionSelect , sliderValue)
            rlcmd("seek animation " .. sliderValue * 0.01)
        end
    end)

    UIHelper.BindUIEvent(self.SliderActionLineFaceEmotion, EventType.OnChangeSliderPercent , function (SliderEventType, nSliderEvent)
        if nSliderEvent == ccui.SliderEventType.percentChanged then
            local sliderValue = UIHelper.GetProgressBarPercent(self.SliderActionLineFaceEmotion)
            if sliderValue >= 100 then
                sliderValue = 99
            end
            UIHelper.SetProgressBarPercent(self.SliderActionSelectFaceEmotion, sliderValue)
            rlcmd("seek face motion " .. sliderValue * 0.01)
        end
    end)

    UIHelper.BindUIEvent(self.BtnCameraFocus, EventType.OnTouchBegan, function(btn, nX, nY)
        SelfieData.tFocusPos = {x = nX, y = nY,}
        self:UpdateFocus(nX, nY)
    end)
     UIHelper.BindUIEvent(self.BtnCameraFocus, EventType.OnTouchMoved, function(btn, nX, nY)
        SelfieData.tFocusPos = {x = nX, y = nY,}
        self:UpdateFocus(nX, nY)
    end)

    UIHelper.BindUIEvent(self.SliderCameraZoomLine , EventType.OnChangeSliderPercent , function (SliderEventType, nSliderEvent)
        if nSliderEvent == ccui.SliderEventType.slideBallDown then
            self.bCurCameraZoomSliding = true
        elseif nSliderEvent == ccui.SliderEventType.slideBallUp then
            self.bCurCameraZoomSliding = false
        end
        if  self.bCurCameraZoomSliding then
            local sliderPercent = UIHelper.GetProgressBarPercent(self.SliderCameraZoomLine)
            UIHelper.SetProgressBarPercent(self.SliderCameraZoomSelect , sliderPercent *  self.fCameraZoomValueScale)
            local zoomScale = self.fCameraZoomMaxValue - (sliderPercent * 0.01) + self.nCameraZoomMinValue
            CameraMgr.Zoom(zoomScale)
        end
    end)

    UIHelper.BindUIEvent(self.BtnSmall, EventType.OnClick, function()
        local sliderPercent = UIHelper.GetProgressBarPercent(self.SliderCameraZoomLine)
        sliderPercent = sliderPercent * 0.01
        sliderPercent = sliderPercent - self.nCameraSplitValue
        if sliderPercent < 0 then
            sliderPercent = 0
        end
        UIHelper.SetProgressBarPercent(self.SliderCameraZoomLine , sliderPercent*100)
        UIHelper.SetProgressBarPercent(self.SliderCameraZoomSelect , sliderPercent*100 * self.fCameraZoomValueScale)
        local zoomValue = self.fCameraZoomMaxValue - sliderPercent + self.nCameraZoomMinValue
        CameraMgr.Zoom(zoomValue , true)
    end)

    UIHelper.BindUIEvent(self.BtnBig, EventType.OnClick, function()
        local sliderPercent = UIHelper.GetProgressBarPercent(self.SliderCameraZoomLine)
        sliderPercent = sliderPercent * 0.01
        sliderPercent = sliderPercent + self.nCameraSplitValue
        if sliderPercent > self.fCameraZoomMaxValue then
            sliderPercent = self.fCameraZoomMaxValue
        end
        UIHelper.SetProgressBarPercent(self.SliderCameraZoomLine , sliderPercent*100)
        UIHelper.SetProgressBarPercent(self.SliderCameraZoomSelect , sliderPercent*100 * self.fCameraZoomValueScale)
        CameraMgr.Zoom(self.fCameraZoomMaxValue - sliderPercent  + self.nCameraZoomMinValue , true)
    end)

    UIHelper.BindUIEvent(self.BtnCamera_S, EventType.OnClick, function()
        self.eInteractionState = INTERACTION_STATE.Camera
        self:UpdateInterationState()
    end)

    UIHelper.BindUIEvent(self.BtnCamera_L, EventType.OnClick, function()
       self:OnShutterDown()
    end)

    UIHelper.BindUIEvent(self.BtnCamera_S2, EventType.OnClick, function()
        self.eInteractionState = INTERACTION_STATE.Camera
        self:UpdateInterationState()
    end)

    UIHelper.BindUIEvent(self.BtnCamera_L2, EventType.OnClick, function()
       self:OnShutterDown()
    end)

    UIHelper.BindUIEvent(self.BtnLuxiang_S, EventType.OnClick, function()
        if Channel.Is_WLColud() then
            TipsHelper.ShowNormalTip("《云·剑网3无界》暂不支持使用录屏功能")
            return
        end
        self.eInteractionState = INTERACTION_STATE.Video
        self:UpdateInterationState()
    end)

    UIHelper.BindUIEvent(self.BtnLuxiang_L, EventType.OnClick, function()
        self:OnVideoDown()
    end)

    UIHelper.BindUIEvent(self.BtnLuxiang, EventType.OnClick, function()
        if self.bCanClickLuaXiang then
            self:OnEndVideo()
        else
            TipsHelper.ShowNormalTip("录制最少1秒")
        end
    end)

    UIHelper.BindUIEvent(self.BtnLuxiang_S2, EventType.OnClick, function()
        if Channel.Is_WLColud() then
            TipsHelper.ShowNormalTip("《云·剑网3无界》暂不支持使用录屏功能")
            return
        end
        self.eInteractionState = INTERACTION_STATE.Video
        self:UpdateInterationState()
    end)

    UIHelper.BindUIEvent(self.BtnLuxiang_L2, EventType.OnClick, function()
        self:OnVideoDown()
    end)

    UIHelper.BindUIEvent(self.BtnLuxiang2, EventType.OnClick, function()
        if self.bCanClickLuaXiang then
            self:OnEndVideo()
        else
            TipsHelper.ShowNormalTip("录制最少1秒")
        end
    end)

    UIHelper.BindUIEvent(self.TogUISwitch, EventType.OnSelectChanged, function(btn, bSelect)
        if SelfieData.bShowUIVideoRecord ~= bSelect and bSelect then
            TipsHelper.ShowNormalTip("已开启录制UI界面")
        end
        SelfieData.bShowUIVideoRecord = bSelect
    end)

    UIHelper.BindUIEvent(self.TogUISwitch2, EventType.OnSelectChanged, function(btn, bSelect)
        if SelfieData.bShowUIVideoRecord ~= bSelect and bSelect then
            TipsHelper.ShowNormalTip("已开启录制UI界面")
        end
        SelfieData.bShowUIVideoRecord = bSelect
    end)

    UIHelper.BindUIEvent(self.BtnImgCard, EventType.OnClick, function()
        if UIHelper.GetScreenPortrait() then
            UIMgr.Open(VIEW_ID.PanelCameraImgCardSharePortrait, self.nThumbnailImageID)
        else
            UIMgr.Open(VIEW_ID.PanelCameraImgCardShare, self.nThumbnailImageID)
        end
    end)

    UIHelper.BindUIEvent(self.BtnDrag, EventType.OnTouchBegan, function(btn, nX, nY)
        nDragX = nX
        nDragY = nY
        self:UpdateMaskPos(nX, nY)
    end)

    UIHelper.BindUIEvent(self.BtnDrag, EventType.OnTouchMoved, function(btn, nX, nY)
        self:UpdateMaskPos(nX, nY)
        nDragX = nX
        nDragY = nY
    end)

    UIHelper.BindUIEvent(self.BtnApplique, EventType.OnTouchBegan, function(btn, nX, nY)
        nDragX = nX
        nDragY = nY
        self:UpdateMaskSize(nX, nY)
    end)

    UIHelper.BindUIEvent(self.BtnApplique, EventType.OnTouchMoved, function(btn, nX, nY)
        self:UpdateMaskSize(nX, nY)
        nDragX = nX
        nDragY = nY
    end)
end

function UISelfieMainView:RegEvent()

    Event.Reg(self, EventType.OnSprintFightStateChanged, function(bSprint)
        self:UpdateFuncSlotState(bSprint)
    end)

    Event.Reg(self, EventType.ON_CHANGE_DYNAMIC_SKILL_GROUP, function(bEnter)
        if bEnter then
            self.bClickToggleSkill = false
            self:ChangeSkillPanel()
        else
            self:UpdateFuncSlotState()
        end
    end)

    Event.Reg(self, EventType.SelfieEyeFocusOpen, function()
        UIHelper.SetVisible(self.Btneyes , SelfieData.bEyeFollow)
        UIHelper.SetPosition(self.Btneyes,0, 0)
        SelfieData.tLookAtPos = {x = 0, y = 0,}
        m_bLookAt = SelfieData.bEyeFollow
        if m_bLookAt then
            rlcmd("enable look at camera")
        else
            rlcmd("disable look at camera")
        end
    end)

    Event.Reg(self, EventType.SelfieCameraFocusOpen, function(bOpen)
        m_bFocus = bOpen
        UIHelper.SetVisible(self.BtnCameraFocus , bOpen)
        UIHelper.SetPosition(self.BtnCameraFocus,0, 0)
        SelfieData.tFocusPos = {x = 0, y = 0,}
        KG3DEngine.SetPostRenderDofAutoFocus(bOpen)
    end)


    Event.Reg(self , EventType.OnSelfieServantChange , function(nNpcIndex)
        UIHelper.SetVisible(self.TogPauseFriend , nNpcIndex > 0)
        UIHelper.SetVisible(self.TogPauseFriend2 , nNpcIndex > 0)
        UIHelper.LayoutDoLayout(self.LayoutBtnPause)
        UIHelper.LayoutDoLayout(self.LayoutBtnPause2)
    end)

    Event.Reg(self, EventType.OnCameraZoom, function(scale)
        if self.nCameraZoomMinValue then
            UIHelper.SetProgressBarPercent(self.SliderCameraZoomLine , (self.fCameraZoomMaxValue - scale + self.nCameraZoomMinValue)*100)
            UIHelper.SetProgressBarPercent(self.SliderCameraZoomSelect , (self.fCameraZoomMaxValue - scale + self.nCameraZoomMinValue)*100 * self.fCameraZoomValueScale)
        end
    end)

    Event.Reg(self , "CHECK_CUR_ANIMATION_EDITABLE" , function()
        local bResult, bEditable = arg0, arg1
        if bResult then
            if self.WidgetAnchorActionLine then
                self.bIsOpenFreezeSlider = bEditable and not self:IsInFreeze()
            end
        end
    end)

    Event.Reg(self , "ENTER_ANIMATION_EDIT_MODE" , function()
        local bEnter, bResult, dwNumFrames, dwCurFrame = arg0, arg1, arg2, arg3
        self:OnGetAniEditModeRet(bEnter, bResult, dwNumFrames, dwCurFrame)
    end)

    Event.Reg(self , "ON_PLAY_FACE_MOTION" , function(dwFaceActionID)
        self:EndFaceMotionEdit()
        self:SetFaceMotionCheck(true)
    end)

    Event.Reg(self , "GET_FACE_ANIMATION_EDIT_INFO" , function()
        local bCanEdit, bInEdit, fCurPercent = arg0 == 1, arg1 == 1, arg2
        self:OnGetFaceMotionEditInfo(bCanEdit, bInEdit, fCurPercent)
    end)

    Event.Reg(self , "ON_FREEZE_END" , function()
        self.bIsOpenFreezeSlider = false
    end)

    Event.Reg(self , EventType.OnViewOpen , function(nViewID)

        if nViewID == VIEW_ID.PanelCamera or nViewID == VIEW_ID.PanelCameraVertical then
            return
        end

        if nViewID == VIEW_ID.PanelMusicMainPlay then
            UIHelper.SetVisible(self._rootNode, false)
            Event.Reg(self, EventType.OnViewClose, function(nViewID)
                UIHelper.SetVisible(self._rootNode, true)
            end,true)
        end

        if self:IsHideInvalidView(nViewID) then
            local tbViewInfo = UIMgr.GetView(nViewID)
            if tbViewInfo then
               UIHelper.SetVisible(tbViewInfo.node, false)
            end
        end
    end)

    Event.Reg(self, EventType.OnWindowsLostFocus, function()
        self.bIsCtrlDown = false
    end)

    Event.Reg(self, EventType.OnDownloadShareCodeData, function (bSuccess, szShareCode, szFilePath, nDataType)
        if bSuccess and ShareCodeData.szCurGetShareCode == szShareCode then
            if nDataType == SHARE_DATA_TYPE.PHOTO then
                local tData = ShareCodeData.GetShareCodeData(szShareCode)
                if tData then
                    self:OpenImportDataPanel(clone(tData))
                end
            end
        end
    end)

	Event.Reg(self, EventType.OnKeyboardUp, function(nKeyCode, szKey)
        if nKeyCode == cc.KeyCode.KEY_CTRL then
            self.bIsCtrlDown = false
        end
        if m_bShotting or UIMgr.GetView(VIEW_ID.PanelCameraPhotoShare) or UIMgr.GetView(VIEW_ID.PanelCameraPhotoSharePortrait) then
            return
        end

        if nKeyCode == cc.KeyCode.KEY_ENTER then
            if self.bIsCtrlDown then
                if self.eInteractionState == INTERACTION_STATE.Camera then
                    self:OnShutterDown()
                else
                    self:HotVideo()
                end
            else
                self:OnClickTogPause()
                UIHelper.SetSelected(self.TogPause , self.bIsSelectPause)
                UIHelper.SetSelected(self.TogPause2 , self.bIsSelectPause)
            end
        elseif nKeyCode == cc.KeyCode.KEY_R then
            if self.bIsCtrlDown then
                self:OnClickResetCamera()
            end
        elseif nKeyCode == cc.KeyCode.KEY_W then
            self:OnHotKeyUpdateCameraMove(0,0)
        elseif nKeyCode == cc.KeyCode.KEY_S then
            self:OnHotKeyUpdateCameraMove(0,0)
        elseif nKeyCode == cc.KeyCode.KEY_A then
            self:OnHotKeyUpdateCameraMove(0,0)
        elseif nKeyCode == cc.KeyCode.KEY_D then
            self:OnHotKeyUpdateCameraMove(0,0)
        elseif nKeyCode == cc.KeyCode.KEY_X then
            self:OnHotKeyUpdateCameraRatation(0)
        elseif nKeyCode == cc.KeyCode.KEY_Z then
            self:OnHotKeyUpdateCameraRatation(0)
        end
    end)

    Event.Reg(self, EventType.OnKeyboardDown, function(nKeyCode, szKey)
        if nKeyCode == cc.KeyCode.KEY_CTRL then
            self.bIsCtrlDown = true
        end
        if m_bShotting or UIMgr.GetView(VIEW_ID.PanelCameraPhotoShare) or UIMgr.GetView(VIEW_ID.PanelCameraPhotoSharePortrait) then
            return
        end

        if nKeyCode == cc.KeyCode.KEY_W then
            if self.bIsCtrlDown then
                self:OnHotKeyUpdateCameraMove(0,1)
            end
        elseif nKeyCode == cc.KeyCode.KEY_S then
            if self.bIsCtrlDown then
                self:OnHotKeyUpdateCameraMove(0,-1)
            end
        elseif nKeyCode == cc.KeyCode.KEY_A then
            if self.bIsCtrlDown then
                self:OnHotKeyUpdateCameraMove(-1,0)
            end
        elseif nKeyCode == cc.KeyCode.KEY_D then
            if self.bIsCtrlDown then
                self:OnHotKeyUpdateCameraMove(1,0)
            end
        elseif nKeyCode == cc.KeyCode.KEY_X then
            if self.bIsCtrlDown then
                self:OnHotKeyUpdateCameraRatation(1)
            end
        elseif nKeyCode == cc.KeyCode.KEY_Z then
            if self.bIsCtrlDown then
                self:OnHotKeyUpdateCameraRatation(-1)
            end
        end
    end)

    --进入省电模式/切后台，退出AR模式
    Event.Reg(self, EventType.OnEnterPowerSaveMode, function()
        SelfieData.StopCameraCapture()
    end)
    Event.Reg(self, EventType.OnApplicationDidEnterBackground, function()
        SelfieData.StopCameraCapture()
    end)

    Event.Reg(self, "PLAYER_DISPLAY_DATA_UPDATE", function()
        if arg0 == g_pClientPlayer.dwID then
            self:UpdateDownloadEquipRes()
        end
    end)

    Event.Reg(self, EventType.OnEquipPakResourceDownload, function()
        self:UpdateDownloadEquipRes()
    end)

    Event.Reg(self, EventType.OnSelfieWindSwitchEnable, function(bShow)
        self:UpdateDownloadEquipRes()
    end)

    Event.Reg(self, EventType.OnSelfieStudioWeatherChange, function(bEnable)
        tReservedData.m_t3DEngineOption.bEnableWeather = bEnable
    end)

    Event.Reg(self, EventType.OnFilter, function(szKey, tbInfo)
        if szKey ~= FilterDef.CameraSize.Key then
            return
        end

        local nSelected = tbInfo[1][1]
        self:OnChanegSizeMode(nSelected)
    end)

    Event.Reg(self, EventType.OnSetWindData, function (tWind)
        local tWind = clone(tWind)
        SelfieData.Wind_CurrentData = tWind
        SelfieData.Wind_CurrentData.bImportPhotoData = true
        local scriptSetting = self.cameraSettingLua
        scriptSetting:UpdateWindPage(tWind)
    end)

    Event.Reg(self, EventType.OnSetLightData, function (tLight)
        SelfieData.Light_CurrentData = tLight
        SelfieData.Light_CurrentData.bImportPhotoData = true
        local scriptSetting = self.cameraSettingLua
        scriptSetting:UpdateLightPage()
    end)

    Event.Reg(self, EventType.OnSetBaseData, function (tBase)
        local tRTParams = clone(tBase.tSelfieCamera.tRTParams)
        SelfieData.bEyeFollow = tBase.bIsLookAt
        SelfieData.bCameraSmoothing = tBase.bIsFocus
        SelfieData.bEnableBloom = tBase.bEnableBloom
        SelfieData.tFocusPos = tBase.tFocusPos
        SelfieData.tLookAtPos = tBase.tLookAtPos
        SelfieData.tSelfieCamera = tBase.tSelfieCamera
        SelfieData.bEyeFollow = tBase.bIsLookAt
        SelfieData.bOpenAdvancedDof = tBase.tSelfieCamera.bAdvancedDOFChecked

        local tShowHide = tBase.tShowHide
        SelfieData.g_ShowNPC = not tShowHide.bHideNPC
        SelfieData.g_ShowSelf = not tShowHide.bHideSelf
        SelfieData.g_ShowPlayer = tShowHide.bShowAllPlayers
        SelfieData.g_ShowPartyPlayer = tShowHide.bOnlyTeammates
        SelfieData.bShowFaceCount = tShowHide.bShowFeature
        SelfieData.tRoleBoxCheck = tShowHide.tRoleBoxCheck

        local scriptSetting = self.cameraSettingLua
        scriptSetting:UpdateBasePage()
        if tRTParams then
            rlcmd(("ob -camera params %f %f %f %f"):format(tRTParams.fScale, tRTParams.fYaw, tRTParams.fPitch, tRTParams.nTick))
            CameraMgr.TranslationOffset(tRTParams.nOffsetX, tRTParams.nOffsetY, tRTParams.nOffsetZ, tRTParams.nOffsetAngle)
        end

        if tBase.tLookAtPos and tBase.tLookAtPos.x and tBase.tLookAtPos.y then
            self:Lookat(tBase.tLookAtPos.x , tBase.tLookAtPos.y)
        end
        if tBase.tFocusPos and tBase.tFocusPos.x and tBase.tFocusPos.y then
            self:UpdateFocus(tBase.tFocusPos.x , tBase.tFocusPos.y)
        end
    end)

    Event.Reg(self, EventType.OnSetFilterData, function (tFilter)
        SelfieData.nCurSelectFilterIndex = tFilter.nFilterIndex
        SelfieData.SafeChangeFilter(tFilter.nFilterIndex)
        local scriptSetting = self.cameraSettingLua
        scriptSetting:UpdateFilterPage(tFilter)
    end)

    Event.Reg(self, EventType.OnGetShareStationUploadConfig, function (nDataType)
        if self.tbWaitForUploadData and self.tbWaitForUploadData.nDataType == nDataType then
            self:DoUploadToShareStaton(nDataType, self.tbWaitForUploadData.nPhotoSizeType)
            self.tbWaitForUploadData = nil
        end
    end)

    Event.Reg(self, EventType.OnActionDataUseState, function (bUseAction)
        UIHelper.SetCanSelect(self.TogPause, not bUseAction, "动作应用中，无法定格")
    end)


    Event.Reg(self, "ON_SELFIE_SWITCH_RIGHT_TYPE", function (nTagIndex)
        if self.emotionActionLua and self.emotionActionLua:IsOpen() then
            self.emotionActionLua:Hide()
        end
        self:OpenRightSettingView(nTagIndex)
    end)
   
    Event.Reg(self, "ON_SELFIE_SWITCH_EMOTION_FACEACTION", function ()
        if self.camerRightSettingLua and self.camerRightSettingLua:IsOpen() then
            self.camerRightSettingLua:Hide()
        end
       
        if self.emotionActionLua then
            self:OnOpenActionView(self.emotionActionLua:GetFaceMotionIndex())
        end
    end)

    Event.Reg(self, "ON_SELFIE_SWITCH_EMOTION_ACTION", function ()
        if self.camerRightSettingLua and self.camerRightSettingLua:IsOpen() then
            self.camerRightSettingLua:Hide()
        end
        if self.emotionActionLua then
            self:OnOpenActionView(1)
        end
    end)
end

function UISelfieMainView:UnRegEvent()
    Event.UnRegAll(self)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UISelfieMainView:UpdateInfo()
    self.bClickToggleHide = false
    self.bClickToggleSkill = false
    self.bIsSelectPause = false
    self:UpdateBaseFrame()
    local onNodeHideCallback = function()
        self:OnNodeHideCallback(true)
    end
    if SelfieData.IsInStudioMap() then
        SelfieData.bCanSetFuncInfo = false
    end
   
    self.cameraSettingLua = UIHelper.GetBindScript(self.WIdgetAnchorCameraSetting)
    self.cameraSettingLua:OnEnter(onNodeHideCallback, self.bNameCard)
    self.emotionActionLua = UIHelper.GetBindScript(self.WidgetAnchorActionSelect)
    self.emotionActionLua:OnEnter(onNodeHideCallback)
    self.studioLua = UIHelper.GetBindScript(self.WidgetScrollViewCameraStudio)
    if self.studioLua then
        self.studioLua:OnEnter(onNodeHideCallback)
    end
    self.exportLua = UIHelper.GetBindScript(self.WidgetScrollViewTemExport)
    if self.exportLua then
        self.exportLua:OnEnter(onNodeHideCallback)
    end
    self.importLua = UIHelper.GetBindScript(self.WidgetScrollViewTemDataInport)
    if self.importLua then
        self.importLua:OnEnter(onNodeHideCallback)
    end

    EmotionData.OnEmotionActionUpdate()
    if self.bNameCard then
        self:SetNameCardSetting()
    end

    if UIHelper.GetScreenPortrait() then
        -- 竖屏情况下
        cameraMoveRate = 0.2
    else
        cameraMoveRate = 0.2
    end

    UIHelper.SetVisible(self.mesageInfo , false)
    local tbServer = LoginMgr.GetModule(LoginModule.LOGIN_SERVERLIST).GetSelectServer()
    UIHelper.SetString(self.LabelServer , tbServer.szRealServer)
    UIHelper.SetString(self.LabelPlayerName, UIHelper.GBKToUTF8(g_pClientPlayer.szName))

    local compLuaBind = self.WidgetHead:getComponent("LuaBind")
    local scriptView = compLuaBind and compLuaBind:getScriptObject()
    if scriptView then
        scriptView:OnEnter(PlayerData.GetPlayerID())
    end
    local ImgQRCode = UIHelper.FindChildByName(self.mesageInfo , "ImgCode")
    UIHelper.SetVisible(ImgQRCode , AppReviewMgr.IsOpenShaderCode())
    UIHelper.SetSpriteFrame(ImgQRCode ,AppReviewMgr.GetShaderCodeImage() )

    if SelfieData.IsDeviceAvailableCamera() then
        Timer.AddFrameCycle(self, 1, function()
            local nState = GetCameraCaptureState()
            if nState ~= self.nCameraCaptureState then
                self.nCameraCaptureState = nState
                local tEnvCtrl = SelfieData.GetEnvCtrl()
                if nState == CAMERA_CAPTURE_STATE.Capturing then
                    --进入AR模式
                    UIHelper.SetString(self.LabelARTitle, "游戏场景")
                    UIHelper.SetVisible(self.BtnARMessage, not self.bClickToggleHide)
                    UIHelper.SetVisible(self.BtnSwitchUI, not self.bClickToggleHide)
                    UIHelper.SetSelected(self.TogWeather, false)
                    UIHelper.SetCanSelect(self.TogWeather, false, "增强现实模式下不支持灯光设置")
                    CameraMgr.SetDragPitchLimit(-90, 5)
                    --rlcmd(string.format("reset camera offset %d 1", 400))
                    self:SwitchTAA()
                    SelfieData.g_ShowNPC = false
                    tEnvCtrl:ShowNpc(false)
                    if not SelfieData.IsInStudioMap() then
                        rlcmd("show or hide all doodad 0")  -- hide doodad
                    end
                    self.bCanSwitchUI = true

                    if SelfieData.bShowARTips then
                        TipsHelper.ShowImportantBlueTip("亮度受游戏内场景影响，可在设置-基础-光源设置里调整")
                        SelfieData.bShowARTips = false --每次登录就弹一次
                    end
                else
                    --离开AR模式
                    UIHelper.SetString(self.LabelARTitle, "增强现实")
                    UIHelper.SetVisible(self.BtnARMessage, false)
                    UIHelper.SetVisible(self.BtnSwitchUI, false)
                    UIHelper.SetCanSelect(self.TogWeather, true)
                    CameraMgr.ResetDragPitchLimit()
                    self:ResetTAA()
                    SelfieData.g_ShowNPC = true
                    tEnvCtrl:ShowNpc(true)
                    if not SelfieData.IsInStudioMap() then
                        rlcmd("show or hide all doodad 1")  -- show doodad
                    end
                    self.bCanSwitchUI = false

                    SelfieData.SetMainLightDirection(tReservedData.fHeadingAngle, tReservedData.fAltitudeAngle)
                    KG3DEngine.SetPostRenderFixedExposure(tReservedData.fModelBrightness)
                end
                self:UpdateSwitchUI()
                UIHelper.LayoutDoLayout(self.WIdgetAchorRight)
                Event.Dispatch(EventType.OnCameraCaptureStateChanged, nState)
                if self.cameraSettingLua and self.cameraSettingLua:IsOpen() then
                    self.cameraSettingLua:Hide()
                end
            end
        end)
    end
    self:UpdateInterationState()
    self:UpdateRecordVideo()
    UIHelper.SetVisible(self.TogUISwitch, false)
    UIHelper.SetVisible(self.TogUISwitch2, false)

    if IsDebugClient() then
        UIHelper.SetVisible(self.TogAddAISign, false)
    end

    Servant_ReserveServant()
    self.nCurServantNpcIndex = Servant_GetCurServantNpcIndex()
    if self.nCurServantNpcIndex and self.nCurServantNpcIndex > 0 then
		Servant_CallServantByID(self.nCurServantNpcIndex, true)
	else
		Servant_DismissServantByID()
	end
    SelfieData.bCanSetFuncInfo = true
end

function UISelfieMainView:UpdateBaseFrame()
    --通知云端进入了幻境云图
    SM_PostEvent(STREAMING_POST_EVENT_TYPE.TAKE_PHOTO, 0)
    tReservedData.m_fDragSpeed, tReservedData.m_fMaxCameraDistance, tReservedData.m_fSpringResetSpeed, tReservedData.m_fCameraResetSpeed, tReservedData.m_nCameraMode = Camera_GetParams()
    CameraMgr.ResetOffset(0)
    local tSelfieSave = SelfieData.GetSelfieSave()
    local nWideAngle = GameSettingData.GetNewValue(UISettingKey.WideAngle)
    tReservedData.m_t3DEngineOption = clone(KG3DEngine.GetMobileEngineOption())
    tReservedData.fCameraFovInRadian = nWideAngle / 180 * math.pi
    CameraMgr.GetPerspectiveAsync(function (nFov, nAspect, nNear, nFar)
        local fMaxCameraAngle = 60 / 180 * math.pi
        tReservedData.fCameraFovInRadian = nFov
        if tReservedData.fCameraFovInRadian > fMaxCameraAngle then
            tReservedData.fCameraFovInRadian = fMaxCameraAngle
        end
    end)
    CameraMgr.GetMainLightDirectionAsync(function(fX, fY, fZ)
        local fHeadingAngle, fAltitudeAngle = SelfieData.VectorToAngle(cc.vec3(-fX, -fY, -fZ)) --因为编辑器端保存 environment.json 取反了
        print("[Selfie] GetMainLightDirectionAsync", fX, fY, fZ, fHeadingAngle, fAltitudeAngle)
        tReservedData.fHeadingAngle = fHeadingAngle
        tReservedData.fAltitudeAngle = fAltitudeAngle
        SelfieData.fHeadingAngle = fHeadingAngle
        SelfieData.fAltitudeAngle = fAltitudeAngle
    end)
    tReservedData.fModelBrightness = KG3DEngine.GetPostRenderFixedExposure()
    tReservedData.X, tReservedData.Y, tReservedData.Z, tReservedData.W = KG3DEngine.GetPostRenderDoFParam()
    tReservedData.DofGatherBlurSize = KG3DEngine.GetPostRenderDofGatherBlurSize()

    local tbSetting = QualityMgr.GetQualitySettingByType(QualityMgr.GetRecommendQualityType())
    KG3DEngine.SetPostRenderDofGatherBlurSize(tbSetting.nDofGatherBlurSize)

    HideGlobalHeadTop()
    self.fEnterCameraScale = CameraMgr.GetCameraScale()
    self:EnterCamera()
    SelfieData.SafeDefaultFilter()
    SelfieData.SetReservedData(tReservedData)

    self.nCameraRemoveOrgiX, self.nCameraRemoveOrgiY = UIHelper.GetPosition(self.ImgCameraRemove)
    self.nCameraRemoveRadius = 115
    self.nCameraRevoleOrgiX, self.nCameraRevoleOrgiY = UIHelper.GetPosition(self.ImgCameraRevole)
    self.nCameraRevoleOrgiWidth, self.nCameraRevoleOrgiHeight = UIHelper.GetContentSize(self.WidgetCameraRevolve)
    self.tbCameraRevoloeAngleAre = {left = -150 , right = -30}
    self.nCameraRevolerNormalX = 0
    self.nCameraMaxRotationAngle = CameraMgr.GetCameraMaxRotationAngle()
    --self.nCanvasWidth , self.nCanvasHeight = UIHelper.GetContentSize(self._rootNode)
    local screenSize = UIHelper.GetCurResolutionSize()
    self.nCanvasMidHeight= screenSize.height * 0.5
    self.nCanvasMidWidth = screenSize.width * 0.5
    self.nDefaultServantNpcIndex = Servant_GetCurServantNpcIndex()
    UIHelper.SetVisible(self.WidgetRemoveLight, false)
    UIHelper.SetRotation(self.WidgetRevolveLight, -90)
    UIHelper.SetVisible(self.TogPauseFriend , self.nDefaultServantNpcIndex ~= 0)
    UIHelper.SetVisible(self.TogPauseFriend2 , self.nDefaultServantNpcIndex ~= 0)
    UIHelper.SetVisible(self.TogPauseFaceEmotion, false)
    UIHelper.SetVisible(self.TogPauseFaceEmotion2, false)
    UIHelper.LayoutDoLayout(self.LayoutBtnPause)
    UIHelper.LayoutDoLayout(self.LayoutBtnPause2)
    UIHelper.SetVisible(self.WidgetAnchorActionLine, false)
    UIHelper.SetVisible(self.WidgetAnchorFaceEmotionLine, false)

    UIHelper.SetVisible(self.Btneyes , false)
    UIHelper.SetVisible(self.BtnCameraFocus , false)
    rlcmd("enable auto lookat 1")
    rlcmd("enter illusion 1")
    -- UIMgr.HideView(VIEW_ID.PanelMainCityInteractive)
    UIHelper.HideInteract()
    m_bBloomEnable = KG3DEngine.GetPostRenderBloomIsEnable()
    KG3DEngine.SetPostRenderBloomIsEnable(true)

    local disDof = math.min(MAIN_SCENE_DOF_DIST_MAX, math.max(SelfieData.GetDistanceOfFocus(), MAIN_SCENE_DOF_DIST_MIN))
    Timer.Add(self , 0.5 , function ()
        -- 开启镜头模式以后会修改Option中的参数，这里需要重新取一次新的值修改
        local tbEngineOption = KG3DEngine.GetMobileEngineOption()
        tbEngineOption.bEnableDof = false
        tbEngineOption.bEnablePointLightingCharacter = true
        tbEngineOption.bEnableBloom = tReservedData.m_t3DEngineOption.bEnableBloom
        KG3DEngine.SetMobileEngineOption(tbEngineOption)
        CameraMgr.SetPostRenderDoFParam(disDof , SelfieData.BASE_PARAM_MAX.DOF , CameraMgr.GetDofDegreeMin())
    end)
    self:CheckAniEditor()
    self:CheckFaceMotionEdit()
    m_bLookAt = false
    m_bFocus  = false
    self.bAniSliderChange = false

    self.bPostRenderGrainEnable = KG3DEngine.GetPostRenderGrainEnable()
    self.bPostRenderChromaticAberrationEnable = KG3DEngine.GetPostRenderChromaticAberrationEnable()
    local t3DEngineCaps = VideoData.Get3DEngineOptionCaps()
    local fCameraFov = t3DEngineCaps.fMinCameraAngle
    CameraMgr.SetCameraFov(fCameraFov)
    self:UpdateCameraZoomSlider()
    SelfieData.nCurSelectFilterIndex = 0
    if not SelfieData.IsSetPresetInStudio() then
        SelfieData.SetNewFilter(0)
    end
end

function UISelfieMainView:ReleaseFrame()
    m_bShotting = false
    -- --通知云端退出了幻境云图，云端执行清空DCIM目录
    SM_PostEvent(STREAMING_POST_EVENT_TYPE.TAKE_PHOTO, 1)
    self:EndFreeze()
    self:EndAniEdit()
    self:EndFaceMotionEdit()
    self:ResetTAA()
    self:SaveSetting()
    self:ExitCamera()
    local tbOption = tReservedData.m_t3DEngineOption
    tbOption.bEnablePointLightingCharacter = false
    KG3DEngine.SetMobileEngineOption(tbOption)
    KG3DEngine.SetPostRenderDoFParam(tReservedData.X, tReservedData.Y, tReservedData.Z, tReservedData.W)
    KG3DEngine.SetPostRenderDofGatherBlurSize(tReservedData.DofGatherBlurSize)

    CameraMgr.TranslationOffset(0, 0, 0, 0)
    CameraMgr.SetCameraFov(tReservedData.fCameraFovInRadian)
    CameraMgr.ResetDragPitchLimit()
    KG3DEngine.SetPostRenderFixedExposure(tReservedData.fModelBrightness)
    if not SelfieData.IsSetPresetInStudio() then
        SelfieData.SetMainLightDirection(tReservedData.fHeadingAngle, tReservedData.fAltitudeAngle)
    end

    ResumeGlobalHeadTop()
    KG3DEngine.SetPostRenderAdvancedDofEnable(false)
    KG3DEngine.SetPostRenderDofAutoFocus(false)

    if m_bLookAt then
        rlcmd("disable look at camera")
    end

    KG3DEngine.SetPostRenderBloomIsEnable(m_bBloomEnable)

    if Servant_IsInFreeze() then
        Servant_CancelFreeze()
    end

    if Servant_GetCurServantNpcIndex() ~= self.nDefaultServantNpcIndex then
        Servant_ClearFreezeState()
        Servant_CallServantByID(self.nDefaultServantNpcIndex, true)
    else
        Servant_RecoverServant()
    end

    Timer.DelAllTimer(self)
    local bEnableLookAt = GameSettingData.GetNewValue(UISettingKey.EyeTracking)
    if not bEnableLookAt then
        rlcmd("enable auto lookat 0")
    else
        rlcmd("enable auto lookat 1")
    end

    rlcmd("enter illusion 0")
    if not SelfieData.IsInStudioMap() then
        rlcmd("show or hide all doodad 1")  -- show doodad
    end

	rlcmd("set local offline idle action id -1")
    -- UIMgr.ShowView(VIEW_ID.PanelMainCityInteractive)
    UIHelper.ShowInteract()
    KG3DEngine.SetPostRenderGrainEnable(self.bPostRenderGrainEnable)
    KG3DEngine.SetPostRenderChromaticAberrationEnable(self.bPostRenderChromaticAberrationEnable)
    KG3DEngine.SetPostRenderVignetteEnable(false)
    local bInStudioMap = SelfieData.IsInStudioMap()
    if not bInStudioMap then
        if Storage.FilterParam and not IsEmpty(Storage.FilterParam.tbParams) then
            SelfieData.nCurSelectFilterIndex = Storage.FilterParam.nFilterIndex
            SelfieData.SafeChangeFilter(SelfieData.nCurSelectFilterIndex, true)
            for k, v in pairs(Storage.FilterParam.tbParams) do
                if k ~= Selfie_BaseSettingType.FilterQD then
                    SelfieData.SetSelfieFuncInfoByTypeID(k, v)
                end
            end
        else
            SelfieData.nCurSelectFilterIndex = 0
            SelfieData.SetNewFilter(0)
        end
    end
end

function UISelfieMainView:InitPageBase(t3DEngineCaps)

end

function UISelfieMainView:StartFreeze()
    if not self:IsInFreeze() then
        self.bStartFreeze = true
        RemoteCallToServer("On_FrameFreeze_Frame")
        Event.Dispatch(EventType.OnSelfieFrameFreezeState, true)
    end
end

function UISelfieMainView:EndFreeze()
    if self:IsInFreeze() or self.bStartFreeze then
        self.bStartFreeze = false
        RemoteCallToServer("On_FrameFreeze_Frame")
        Event.Dispatch(EventType.OnSelfieFrameFreezeState, false)
    end
end

function UISelfieMainView:IsInFreeze()
    local player = GetClientPlayer()
    if player then
        return player.IsHaveBuff(12024, 1)
    else
        return false
    end
end

function UISelfieMainView:StartAniEdit()
    if not self.bAniSliderChange and not self:IsInAniEdit() then
        RemoteCallToServer("On_EditAnimation_Edit")
        self.bAniSliderChange = true
    end
end

function UISelfieMainView:EndAniEdit()
    if self:IsInAniEdit() then
        RemoteCallToServer("On_EditAnimation_Edit")
    end
    self.bAniSliderChange = false
    rlcmd("check current animation editable")
end

function UISelfieMainView:IsInAniEdit()
    local player = GetClientPlayer()
    if player then
        return player.IsHaveBuff(23496, 1)
    else
        return false
    end
end

function UISelfieMainView:StartFaceMotionEdit()
	if not self:IsFaceMotionEdit() then
		rlcmd("pause face animation 1")
	end
end

function UISelfieMainView:EndFaceMotionEdit()
	if self:IsFaceMotionEdit() then
		rlcmd("pause face animation 0")
	end
	rlcmd("get face animation edit info")
end

function UISelfieMainView:IsFaceMotionEdit()
	return m_bInFaceMotionEdit
end

function UISelfieMainView:SaveSetting()

end

function UISelfieMainView:SwitchQulity(fnExContent, nLevel)
    self.nCurResolutionLevel = QualityMgr.tbCurQuality.nResolutionLevel
    self.bCurEnableFSR = QualityMgr.tbCurQuality.bEnableFSR
    self.bCurEnableGSR = QualityMgr.tbCurQuality.bEnableGSR
    self.bCurEnableGSR2 = QualityMgr.tbCurQuality.bEnableGSR2
    self.bCurEnableGSR2Performance = QualityMgr.tbCurQuality.bEnableGSR2Performance
    nLevel = nLevel or 5

    local blocalEnableGSR = false
    local szGPUModel = GetDeviceGPU() or ""
    if tbGSRSnapShotGPUModel[szGPUModel] then
        blocalEnableGSR = true
    end

    KG3DEngine.SetMobileEngineOption({nResolutionLevel = nLevel, bEnableFSR = true, bEnableGSR = blocalEnableGSR, bEnableGSR2 = false, bEnableGSR2Performance= false, bEnablePointLightingCharacter = true})
    Timer.AddFrame(self , 15 , function ()
        fnExContent()
    end)
end

function UISelfieMainView:ResetQulity()
    if self.nCurResolutionLevel then
        KG3DEngine.SetMobileEngineOption({nResolutionLevel = self.nCurResolutionLevel , bEnableFSR = self.bCurEnableFSR, bEnableGSR= self.bCurEnableGSR, bEnableGSR2= self.bCurEnableGSR2, bEnableGSR2Performance= self.bCurEnableGSR2Performance, bEnablePointLightingCharacter = true})
        self.nCurResolutionLevel = nil
    end
end

function UISelfieMainView:SwitchTAA()
    self.bCurEnableTAA = QualityMgr.tbCurQuality.bEnableTAA
    KG3DEngine.SetMobileEngineOption({bEnableTAA = false, bEnableSSPRAnti = false})
end

function UISelfieMainView:ResetTAA()
    if self.bCurEnableTAA ~= nil then
        -- 当在Windows端且开启了TAA时，同时开启SSPR抗锯齿（修复水面倒影闪烁问题 @蒙占志）
        KG3DEngine.SetMobileEngineOption({bEnableTAA = self.bCurEnableTAA, bEnableSSPRAnti = Platform.IsWindows() and self.bCurEnableTAA})
        self.bCurEnableTAA = nil
    end
end

function UISelfieMainView:OnShutterDown()
    if m_bShotting then
        return
    end
    m_bShotting = true
    self:HotPhoto()
end

function UISelfieMainView:CaptureScreenNoMessage()
    -- 此时在截一张不带信息的全屏图
    Timer.AddFrame(self , 2 , function ()

        cc.utils:setIgnoreAgainCapture(true)
        local folder = GetFullPath("dcim/")
        local dt = TimeToDate(GetCurrentTime())
        CPath.MakeDir(folder)
        local fileName = string.format("%04d%02d%02d%02d%02d%02d.png",dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second)
        UIHelper.CaptureScreen(function (pRetTexture, pImage)
            m_bShotting = false
            self.nPhotoshareViewID = VIEW_ID.PanelCameraPhotoShare

            if self._nViewID == VIEW_ID.PanelCameraVertical then
                self.nPhotoshareViewID = VIEW_ID.PanelCameraPhotoSharePortrait
            end

            --开启忽略的界面
            for _, tbIgnoreIDs in pairs(SelfieData.tbLayerIgnoreIDs) do
                for k, _viewId in pairs(tbIgnoreIDs) do
                    if table.contain_value(self.tbPhotoHideViews , _viewId) then
                        local view = UIMgr.GetView(_viewId)
                        local node = view and view.node
                        if node then
                            node:setVisible(true)
                        end
                    end
                end
            end

            if not UIMgr.GetView(self.nPhotoshareViewID) then
                if self.nSizeMode ~= SIZE_TYPE.FullScreen then
                    Timer.AddFrame(self, 3, function ()
                        local nWidth, nHeight = UIHelper.GetContentSize(self.ImgBgBox)
                        local nLeft, nRight, nTop, nBottom = self:GetRecordSize(true)
                        UIHelper.CropImage(function (pCroppedTexture, pCroppedImage)
                            local shareScript = UIMgr.Open(self.nPhotoshareViewID , pCroppedTexture ,pCroppedImage, folder, fileName, function ()
                                UIHelper.SetVisible(self._rootNode , true)
                                self:ShowAllView()
                                self:ResetQulity()
                                if not self.bIsSelectPause then
                                    self:EndFreeze()
                                end
                            end, self.pMessageImage, nil, nWidth, nHeight)
                        end, pImage, nLeft, nRight, - nTop, - nBottom, true)
                    end)
                else
                    local shareScript = UIMgr.Open(self.nPhotoshareViewID , pRetTexture ,pImage , folder,fileName, function ()
                        UIHelper.SetVisible(self._rootNode , true)
                        self:ShowAllView()
                        self:ResetQulity()
                        if not self.bIsSelectPause then
                            self:EndFreeze()
                        end
                    end,self.pMessageImage)
                end
            end
            self:FlowerPsNeeded()
        end, 1 , true)
    end)
end

function UISelfieMainView:OnVideoDown()
    local onExcute = function()
        self.eInteractionState = INTERACTION_STATE.VideoTime
        self:UpdateInterationState()
        UIHelper.SetProgressBarPercent(self.ImgSliderExperience , 0)
        UIHelper.SetProgressBarPercent(self.ImgSliderExperience2 , 0)
        UIHelper.SetString(self.labelLuXiangTime,Timer.Format2Minute(0))
        UIHelper.SetString(self.labelLuXiangTime2,Timer.Format2Minute(0))
        UIHelper.SetString(self.LabelBeginTitle,"4")
        UIHelper.SetString(self.LabelBeginTitle2,"4")
        UIHelper.SetButtonState(self.BtnLuxiang, BTN_STATE.Disable,"倒计时预备中")
        UIHelper.SetButtonState(self.BtnLuxiang2, BTN_STATE.Disable,"倒计时预备中")
        self.bVideoTimeDownCount = true
        UIHelper.SetVisible(self.TogUISwitch, false)
        UIHelper.SetVisible(self.TogUISwitch2, false)
        self:SwitchQulity(function ()
            self:OnStartVideo()
        end,QualityMgr.tbCurQuality.nResolutionLevel)
    end
    if Platform.IsMobile() then
        if QualityMgr.GetRecommendQualityType() < GameQualityType.HIGH then
            TipsHelper.ShowImportantBlueTip("默认推荐画质为电影或极致的设备方可使用此功能")
            return
        else
            onExcute()
        end
    else
        if self:IsCardCropp4K() and SelfieData.bShowDropConfirm  then
            local script = UIHelper.ShowConfirm("当前分辨率为4K，录制可能会出现卡顿。确认开始录制?", function(bShowDropConfirm)
                SelfieData.bShowDropConfirm = not bShowDropConfirm
                onExcute()
            end, function(bShowDropConfirm)
                SelfieData.bShowDropConfirm = bShowDropConfirm
            end)
            script:ShowTogOption("下次不再提示", SelfieData.bShowDropConfirm)
        else
            onExcute()
        end
    end
end

function UISelfieMainView:UpdateFuncSlotState(bSprint)
    local player = GetClientPlayer()
    if not player then
        return
    end
    if not self.scriptFuncSlot then
        return
    end
    if bSprint == nil then
        bSprint = SprintData.GetViewState()
    end

    local bCanCastSkill = QTEMgr.CanCastSkill()
    UIHelper.SetVisible(self.scriptFuncSlot._rootNode, bSprint and bCanCastSkill and not JiangHuData.bIsArtist)
end

function UISelfieMainView:UpdateCameraRemove(nX , nY)
    local nCursorX, nCursorY = UIHelper.ConvertToNodeSpace(self.WidgetCameraRemove, nX, nY)
    local nDistance = kmath.len2(nCursorX, nCursorY, self.nCameraRemoveOrgiX, self.nCameraRemoveOrgiY)
    local nNormalizeX, nNormalizeY = kmath.normalize2(nCursorX - self.nCameraRemoveOrgiX, nCursorY - self.nCameraRemoveOrgiY)


    if nDistance < self.nCameraRemoveRadius then
        UIHelper.SetPosition(self.ImgCameraRemove, nCursorX, nCursorY)
    else
        local nX = self.nCameraRemoveOrgiX + nNormalizeX * self.nCameraRemoveRadius
        local nY = self.nCameraRemoveOrgiY + nNormalizeY * self.nCameraRemoveRadius
        UIHelper.SetPosition(self.ImgCameraRemove, nX, nY)
    end

    --CameraMgr.TranslationMove(0, nNormalizeX*(-SelfieData.CameraRemoveSpeed) , nNormalizeY*SelfieData.CameraRemoveSpeed)

    local nRadian = math.atan2(nCursorY - self.nCameraRemoveOrgiX, nCursorX - self.nCameraRemoveOrgiY) -- 弧度
    local nAngle = -(nRadian * 180 / math.pi) -- 角度
    UIHelper.SetRotation(self.WidgetRemoveLight, nAngle)

    self.nCamerRemoveCursorX = nCursorX
    self.nCamerRemoveCursorY = nCursorY
end

function UISelfieMainView:UpdateCameraRevolve(nX , nY)
    local nCursorX, nCursorY = UIHelper.ConvertToNodeSpace(self.WidgetCameraRevolve, nX, nY)
    local nDistance = kmath.len2(nCursorX, nCursorY, self.nCameraRevoleOrgiX, self.nCameraRevoleOrgiY)
    local nNormalizeX, nNormalizeY = kmath.normalize2(nCursorX - self.nCameraRevoleOrgiX, nCursorY - self.nCameraRevoleOrgiY)

    if nDistance < self.nCameraRemoveRadius then
        UIHelper.SetPosition(self.ImgCameraRevole, nCursorX, nCursorY)
    else
        local nX = self.nCameraRevoleOrgiX + nNormalizeX * self.nCameraRemoveRadius
        local nY = self.nCameraRevoleOrgiY + nNormalizeY * self.nCameraRemoveRadius
        UIHelper.SetPosition(self.ImgCameraRevole, nX, nY)
    end

    local nRadian = math.atan2(nCursorY - self.nCameraRevoleOrgiX, nCursorX - self.nCameraRevoleOrgiY) -- 弧度
    local nAngle = -(nRadian * 180 / math.pi) -- 角度

    if nAngle < self.tbCameraRevoloeAngleAre.left then
        return
    elseif nAngle > self.tbCameraRevoloeAngleAre.right then
        return
    end
    local nDec = 0
    if nNormalizeX < self.nCameraRevolerNormalX then
        nDec = -1
    elseif nNormalizeX > self.nCameraRevolerNormalX then
        nDec = 1
    end
    local nSub = math.abs(self.nCameraRevolerNormalX - nNormalizeX)
    local nFix = 0
    if nSub >= 0.05 then
        nFix = math.floor(nSub * 20) * 0.05 * nDec
        self.nCameraRevolerNormalX =  self.nCameraRevolerNormalX + nFix
    end

    CameraMgr.TranslationMove(0, 0, 0, nFix*self.nCameraMaxRotationAngle)

    UIHelper.SetRotation(self.WidgetRevolveLight, nAngle)
end

function UISelfieMainView:Lookat(nX , nY)
    local cellW, cellH = UIHelper.GetContentSize(self.Btneyes)
    local x = nX - self.nCanvasMidWidth
    local y = nY - self.nCanvasMidHeight
    UIHelper.SetPosition(self.Btneyes, x, y)
    rlcmd(string.format("set look at offset %d %d", -x - cellW*0.5, y + cellH*0.5))
end

function UISelfieMainView:UpdateFocus(nX , nY)
    if m_bFocus then
        local cellW, cellH = UIHelper.GetContentSize(self.BtnCameraFocus)
        local x = nX - self.nCanvasMidWidth
        local y = nY - self.nCanvasMidHeight
        UIHelper.SetPosition(self.BtnCameraFocus, x, y)
        rlcmd(string.format("set screen pos for view space depth %f %f",x , y))
    end
end

function UISelfieMainView:CheckAniEditor()
    self.nCheckAniTimerID = Timer.AddFrameCycle(self , 10 , function ()
        if not self.IsInAniEdit then
            Timer.DelTimer(self , self.nCheckAniTimerID )
        end
        if not self:IsInAniEdit() then
            rlcmd("check current animation editable")
        end
    end)
end

function UISelfieMainView:OnGetAniEditModeRet(bEnter, bResult, dwNumFrames, dwCurFrame)
    if not bResult then
        if bEnter then
            self:EndAniEdit()
        end
        return
    end
    self.bIsEnteraAniEditMode = bEnter
    if bEnter then
        local fProgress = math.floor((dwCurFrame / dwNumFrames) * 100)
        UIHelper.SetProgressBarPercent(self.SliderActionSelect , fProgress)
        UIHelper.SetProgressBarPercent(self.SliderActionLine , fProgress)
    else
        if self:IsInAniEdit() then
            self:EndAniEdit()
        end
    end
end

function UISelfieMainView:CheckFaceMotionEdit()
    self.nCheckFaceTimerID = Timer.AddFrameCycle(self , 10 , function ()
        if not self.IsFaceMotionEdit then
            Timer.DelTimer(self , self.nCheckFaceTimerID )
        end
        if m_bCheckFaceMotionEdit and not self:IsFaceMotionEdit() then
            rlcmd("get face animation edit info")
        end
    end)
end

function UISelfieMainView:SetFaceMotionCheck(bCheck)
    m_bCheckFaceMotionEdit = bCheck
end

function UISelfieMainView:OnGetFaceMotionEditInfo(bCanEdit, bInEdit, fCurPercent)
    UIHelper.SetVisible(self.TogPauseFaceEmotion, bCanEdit)
    UIHelper.SetVisible(self.TogPauseFaceEmotion2, bCanEdit)
    UIHelper.LayoutDoLayout(self.LayoutBtnPause)
    UIHelper.LayoutDoLayout(self.LayoutBtnPause2)
    if not bCanEdit then
        self:SetFaceMotionCheck(false)
    end

    m_bInFaceMotionEdit = bInEdit
    UIHelper.SetSelected(self.TogPauseFaceEmotion, bInEdit, false)
    UIHelper.SetSelected(self.TogPauseFaceEmotion2, bInEdit, false)
    if bInEdit then
        UIHelper.SetVisible(self.WidgetAnchorFaceEmotionLine, true)
        local fProgress = math.floor(fCurPercent * 100)
        UIHelper.SetProgressBarPercent(self.SliderActionSelectFaceEmotion , fProgress)
        UIHelper.SetProgressBarPercent(self.SliderActionLineFaceEmotion , fProgress)
    else
        UIHelper.SetVisible(self.WidgetAnchorFaceEmotionLine, false)
    end
end

function UISelfieMainView:EnterCamera(nTime)
    local nEnterTime = nTime or 800 -- 单位 毫秒
    local nScale = 1
    local player = GetClientPlayer()
    if player then
        local bScreenPortrait = UIHelper.GetScreenPortrait()
        local fExtraScale = 1
        if player.bOnHorse and not bScreenPortrait then
            fExtraScale = player.IsFollowController() and 1.6 or 1.5
        elseif player.IsFollower() and not bScreenPortrait then
            fExtraScale = 4
        end
        local kUIModeDistance = 100 * fExtraScale
        if bScreenPortrait then
            kUIModeDistance = kUIModeDistance * 4
        end
        local _, nMaxCameraDis = Camera_GetParams()
        nScale = kUIModeDistance / nMaxCameraDis
        if player.bOnHorse then
            CameraMgr.Status_Push({
                mode    = "local camera",
                scale   = nScale,
                yaw     = 2 * math.pi - (player.nFaceDirection / 255 * math.pi * 2 + math.pi / 4),
                pitch   = - math.pi / 8,
                tick    = nEnterTime,
            }, true)
        elseif player.IsFollower() then
            CameraMgr.Status_Push({
                mode    = "local camera",
                scale   = nScale,
                yaw     = 2 * math.pi - (player.nFaceDirection / 255 * math.pi * 2),
                pitch   = - math.pi / 8,
                tick    = nEnterTime,
            }, true)
        else
            CameraMgr.Status_Push({
                mode    = "local camera",
                scale   = nScale,
                yaw     = 2 * math.pi - (player.nFaceDirection / 255 * math.pi * 2 + math.pi / 2),
                pitch   = - math.pi / 180,
                tick    = nEnterTime,
            }, true)
        end
    end
    if UIHelper.GetScreenPortrait() then
        --TODO_xt: 2023.3.7, 偏移焦点以后镜头会穿障碍，临时关闭，待镜头逻辑完善
        --rlcmd("enable camera focus diverge 1 0 -0.1")
    end
    self.nCameraStartZoomScale = nScale
    Event.Dispatch(EventType.OnCameraZoom, nScale)
end

function UISelfieMainView:ExitCamera()
    local nEnterTime = 800 -- 单位 毫秒
    local nScale = self.fEnterCameraScale or 1
    --rlcmd("enable camera focus diverge 0")
    CameraMgr.Status_Backward("all", nEnterTime)
    Event.Dispatch(EventType.OnCameraZoom, nScale)
end

function UISelfieMainView:ChangeSkillPanel()
    self.bClickToggleSkill = not self.bClickToggleSkill
    UIHelper.SetVisible(self.WidgetSkill , self.bClickToggleSkill)
    UIHelper.SetVisible(self.WidgetCameraAdjust , not self.bClickToggleSkill)
    if self.bClickToggleSkill then
        if not self.scriptSkill then
            self.scriptSkill = UIHelper.AddPrefab(SkillData.GetSkillPanelPrefabID(), self.WidgetSkill)
        end
        if not self.scriptFuncSlot then
            self.scriptFuncSlot = UIHelper.AddPrefab(SkillData.GetFunctionPanelPrefabID(), self.WidgetSkill, true)
        end
        self:UpdateFuncSlotState()
    end
    UIHelper.LayoutDoLayout(self.LayoutLowerRight)
end

function UISelfieMainView:OpenCameraRemove(bOpen)
    Timer.DelTimer(self , self.nCameraRemoveTimerID)
    if bOpen then
        self.nCameraRemoveTimerID = Timer.AddCycle(self , 0.02 , function ()
            if self.nCamerRemoveCursorX ~= nil then
                local nNormalizeX, nNormalizeY = kmath.normalize2(self.nCamerRemoveCursorX - self.nCameraRemoveOrgiX, self.nCamerRemoveCursorY - self.nCameraRemoveOrgiY)
                CameraMgr.TranslationMove(0, cameraMoveRate*nNormalizeX*(-SelfieData.CameraRemoveSpeed) ,cameraMoveRate*nNormalizeY*SelfieData.CameraRemoveSpeed)
            end
        end)
    else
        self.nCamerRemoveCursorX = nil
    end
end

function UISelfieMainView:HideLayer()
    for layer , tbIgnoreViewIDs in pairs(SelfieData.tbLayerIgnoreIDs) do
        UIMgr.SetShowAllInLayer(layer, false, tbIgnoreViewIDs)
    end
end

function UISelfieMainView:ShowLayer()
    for layer , tbIgnoreViewIDs in pairs(SelfieData.tbLayerIgnoreIDs) do
        UIMgr.SetShowAllInLayer(layer, true, tbIgnoreViewIDs)
    end
end

function UISelfieMainView:IsHideInvalidView(nViewID)
    local isHide = false
    local szLayer = UIMgr.GetViewLayerByViewID(nViewID)
    for layer , tbIgnoreViewIDs in pairs(SelfieData.tbLayerIgnoreIDs) do
        if layer == szLayer then
            isHide = not table.contain_value(tbIgnoreViewIDs, nViewID)
            break
        end

    end
    return isHide
end

function UISelfieMainView:SetNameCardSetting()
    UIHelper.SetVisible(self.BtnLuxiang_S, false)
    local parent = UIHelper.GetParent(self.WidgetLuxiang)
    if parent then
        local img = UIHelper.GetChildByName(parent, "ImgChangeBg")
        UIHelper.SetVisible(img, false)
    end
    UIHelper.SetVisible(self.BtnPortrait, false)
    UIHelper.SetVisible(self.TogLine, false)
    UIHelper.SetVisible(self.TogSizeBox, false)
    if self:IsCardCropp2K() then
        UIHelper.SetVisible(self.TogCardLine02, true)
        UIHelper.SetVisible(self.WidgetPersonalCardLine02, true)
    else
        UIHelper.SetVisible(self.TogCardLine, true)
        UIHelper.SetVisible(self.WidgetPersonalCardLine, true)
    end
    UIHelper.SetVisible(self.TogHide, false)

    SelfieData.g_ShowNPC = false
    SelfieData.g_ShowPlayer = false
    SelfieData.g_ShowPartyPlayer = false
    SelfieData.bShowFaceCount = false

    local tEnvCtrl = SelfieData.GetEnvCtrl()
    tEnvCtrl:ShowNpc(false)
    tEnvCtrl:ShowPlayer(PLAYER_SHOW_MODE.kNone)
    tEnvCtrl:SetHDFaceCount(8)

    rlcmd(string.format("enable avoid fliter type %d %d", ACTOR_FLITER_TYPE.ACTOR_FLITER_TYPE_SCREEN_SHOOT, 1))
end

function UISelfieMainView:RevertNameSetting()
    SelfieData.g_ShowNPC = true
    SelfieData.g_ShowPlayer = true
    SelfieData.g_ShowPartyPlayer = true

    local tEnvCtrl = SelfieData.GetEnvCtrl()
    tEnvCtrl:ShowNpc(true)
    tEnvCtrl:ShowPlayer(PLAYER_SHOW_MODE.kAll)
end

function UISelfieMainView:SwitchPortrait()
    local bIsPortrait = not UIHelper.GetScreenPortrait()
    UIMgr.HideLayer(UILayer.Page)
    UIMgr.HideLayer(UILayer.Scene)
    UIHelper.SetScreenPortrait(bIsPortrait)
    SelfieData.AsyncSwitchPortrait(bIsPortrait,self.bNameCard)
end

function UISelfieMainView:SetPersonalCardIndex(nIndex)
    self.nPersonalCardIndex = nIndex
end

function UISelfieMainView:HideAllView()
    self.tbPhotoHideViews = {}
    for szLayerName, nLayer in pairs(UILayer.NameToLayer) do
        if  szLayerName ~= UILayer.Scene and szLayerName ~= UILayer.Mask then
            local layer = UIMgr.tMapLayers[szLayerName]
            if layer then
                local tbStack = UIMgr.tMapLayerStacks[szLayerName]
                local nCount = #tbStack
                for i = nCount, 1 , -1 do
                    local one = tbStack[i]
                    if one then
                        if one.nViewID ~= self._nViewID and (not table.contain_value(SelfieData.tbCaptureScreenIgnoreIDs, one.nViewID))  then
                            local view = UIMgr.GetView(one.nViewID)
                            local node = view and view.node
                            if node then
                                if node:isVisible() then
                                    table.insert(self.tbPhotoHideViews , one.nViewID)
                                    node:setVisible(false)
                                end
                            end
                        end
                    end
                end
            end
        end
    end


    local reviceView = UIMgr.GetViewScript(VIEW_ID.PanelRevive)
    if reviceView then
        reviceView:AddOpenViewID(self._nViewID)
        reviceView:UpdateVisible()
    end

    Event.Dispatch(EventType.OnPhotoShareWidgetShow, false)
end

function UISelfieMainView:ShowAllView()
    for k, v in pairs(self.tbPhotoHideViews) do
        local view = UIMgr.GetView(v)
        local node = view and view.node
        if node then
            node:setVisible(true)
        end
    end
    local reviceView = UIMgr.GetViewScript(VIEW_ID.PanelRevive)
    if reviceView then
        reviceView:RemoveViewID(self._nViewID)
        reviceView:UpdateVisible()
    end
    Event.Dispatch(EventType.OnPhotoShareWidgetShow, true)
end

function UISelfieMainView:IsCardCropp2K()
    local tSize = GetFrameSize()
    local nWidth = tSize.width
    local nHeight = tSize.height
    return nWidth >= 2560
end

function UISelfieMainView:IsCardCropp4K()
    local tSize = GetFrameSize()
    local nWidth = tSize.width
    local nHeight = tSize.height
    return nWidth >= 3840
end

function UISelfieMainView:JudgeSpecialBuff()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return false
    end
    for k, v in ipairs(CommonDef.PERSONAL_CARD_CANCEL_BUFF_LIST) do
        if hPlayer.IsHaveBuff(v, 0) then
            return true
        end
    end
    return false
end

function UISelfieMainView:FlowerPsNeeded()
    local tCameraParam = CameraMgr.GetCameraParam()
	local hPlayer = GetClientPlayer()

	return UIscript_PhotoGameJudge(hPlayer, tCameraParam.from.x, tCameraParam.from.y, tCameraParam.from.z, tCameraParam.pitch, tCameraParam.yaw)
end

function UISelfieMainView:UpdateCameraZoomSlider()
    local tLimit = CameraMgr.tZoomLimit or {0,1}
    self.nCameraZoomMinValue = tLimit[1]
    self.fCameraZoomMaxValue = (tLimit[2]-tLimit[1])
    self.fCameraZoomValueScale = tLimit[2] / self.fCameraZoomMaxValue
    self.nCameraSplitValue = self.fCameraZoomMaxValue * 0.05
    local value = self.nCameraStartZoomScale -self.nCameraZoomMinValue
    if value < 0 then
        value = 0
    end

    UIHelper.SetMaxPercent(self.SliderCameraZoomLine , self.fCameraZoomMaxValue *100 )
    UIHelper.SetProgressBarPercent(self.SliderCameraZoomSelect , (self.fCameraZoomMaxValue-value) * 100 * self.fCameraZoomValueScale)
    UIHelper.SetProgressBarPercent(self.SliderCameraZoomLine ,  (self.fCameraZoomMaxValue-value) * 100)
end

function UISelfieMainView:OpenImportDataPanel(tPhotoData)
    local onNodeHideCallback = function()
        self:OnNodeHideCallback(true)
        UIHelper.SetVisible(self.BtnTem , true)
        UIHelper.LayoutDoLayout(self.LayoutRightBtn)
    end
    local OnNodeShow = function()
        self:OnNodeHideCallback(false)
        UIHelper.SetVisible(self.BtnTem , true)
        UIHelper.LayoutDoLayout(self.LayoutRightBtn)
    end

    self.importLua:Open(tPhotoData, onNodeHideCallback)
    if self.importLua:IsOpen() then
        OnNodeShow()
    end
end

function UISelfieMainView:IsSideNodeOpen()
    if self.cameraSettingLua and self.cameraSettingLua:IsOpen() then
        return true
    elseif self.emotionActionLua and self.emotionActionLua:IsOpen() then
        return true
    elseif self.studioLua and self.studioLua:IsOpen() then
        return true
    elseif self.importLua and self.importLua:IsOpen() then
        return true
    elseif self.exportLua and self.exportLua:IsOpen() then
        return true
    elseif self.DetailScript and self.DetailScript:IsOpen() then
        return true
    elseif self.camerRightSettingLua and self.camerRightSettingLua:IsOpen() then
        return true
    elseif self.script_oneclick then
        return true
    end
    return false
end

function UISelfieMainView:UpdateSwitchUI()
    -- local bSideOpen = (self.cameraSettingLua and self.cameraSettingLua:IsOpen()) or (self.emotionActionLua and self.emotionActionLua:IsOpen()) or (self.studioLua and self.studioLua:IsOpen()) or false
    local bSideOpen = self:IsSideNodeOpen()
    if self._nViewID ~= VIEW_ID.PanelCameraVertical then
        local bSwitchUI = self.bCanSwitchUI and Storage.Selfie.bSwitchUI or false
        UIHelper.SetVisible(self.WidgetAnchorLeft, not bSwitchUI and not bSideOpen)
        UIHelper.SetVisible(self.WidgetAnchorLeft_AR, bSwitchUI and not bSideOpen)
        UIHelper.SetVisible(self.WidgetSpaceOccupy, bSwitchUI and not bSideOpen)
        UIHelper.SetVisible(self.BtnRenovate, not bSwitchUI)
        UIHelper.SetVisible(self.BtnRenovate2, bSwitchUI)
        UIHelper.SetVisible(self.TogTemplateManagement, not bSwitchUI and not bSideOpen and not AppReviewMgr.IsReview())
    else
        UIHelper.SetVisible(self.WidgetAnchorLeft, not bSideOpen)
    end
    UIHelper.LayoutDoLayout(self.LayoutLowerRight)
end

function UISelfieMainView:OnClickTogPause()
    self.bIsSelectPause = not self.bIsSelectPause
    if self.bIsOpenFreezeSlider then
        UIHelper.SetVisible(self.WidgetAnchorActionLine, self.bIsSelectPause and self.bIsOpenFreezeSlider)
        if self.bIsSelectPause then
            self:StartAniEdit()
        else
            self:EndAniEdit()
        end
    else
        if self.bIsSelectPause then
            self:StartFreeze()
        else
            self:EndFreeze()
        end
    end
end

function UISelfieMainView:OnClickResetCamera()
    CameraMgr.ResetOffset(0)
    CameraMgr.Status_Backward("all")
    Timer.AddFrame(self, 2, function ()
        self:EnterCamera(0)
    end)
    self.nCameraRevolerNormalX = 0
    self.nCameraRevolveTouch_X = nil
    UIHelper.SetRotation(self.WidgetRevolveLight, -90)
end

function UISelfieMainView:OnHotKeyUpdateCameraMove(nAddX , nAddY)
    if nAddX == 0 and nAddY == 0 then
        if self.nCameraHotKeyTimerID then
            UIHelper.SetPosition(self.ImgCameraRemove, self.nCameraRemoveOrgiX, self.nCameraRemoveOrgiY)
            UIHelper.SetVisible(self.WidgetRemoveLight, false)
            self:OpenCameraRemove(false)
            Timer.DelTimer(self , self.nCameraHotKeyTimerID)
            self.nCameraHotKeyTimerID = nil
            InputHelper.LockMove(false)
        end
    else
        InputHelper.LockMove(true)
        UIHelper.SetVisible(self.WidgetRemoveLight, true)
        self:OpenCameraRemove(true)
        local nRemovePosX , nRemovePosY = UIHelper.GetWorldPosition(self.WidgetCameraRemove)
        Timer.DelTimer(self , self.nCameraHotKeyTimerID)
        self.nCameraHotKeyTimerID = Timer.AddCycle(self , 0.02 , function ()
            nRemovePosY = nRemovePosY + nAddY
            nRemovePosX = nRemovePosX + nAddX
            self:UpdateCameraRemove(nRemovePosX, nRemovePosY)
        end)
    end
end

function UISelfieMainView:OnHotKeyUpdateCameraRatation(nAddX)
    if nAddX == 0 then
        if self.nCameraHotKeyTimerID then
            Timer.DelTimer(self , self.nCameraHotKeyTimerID)
            self.nCameraHotKeyTimerID = nil
        end
    else
        local nPosX  , nPosY = UIHelper.GetWorldPosition(self.WidgetCameraRevolve)

        if self.nCameraRevolveTouch_X then
            local nLen = self.nCameraRevoleOrgiWidth * 0.5 + 150
            local nLeftLimit = nPosX - nLen
            local nRightLimit = nPosX + nLen
            if self.nCameraRevolveTouch_X < nLeftLimit then
                self.nCameraRevolveTouch_X = nLeftLimit
                self.nCameraRevolveTouch_Y = nPosY + self.nCameraRevoleOrgiHeight * 0.5
            elseif self.nCameraRevolveTouch_X > nRightLimit then
                self.nCameraRevolveTouch_X = nRightLimit
                self.nCameraRevolveTouch_Y = nPosY + self.nCameraRevoleOrgiHeight * 0.5
            end
        else
            self.nCameraRevolveTouch_X = nPosX
            self.nCameraRevolveTouch_Y = nPosY + self.nCameraRevoleOrgiHeight * 0.5
        end

        Timer.DelTimer(self , self.nCameraHotKeyTimerID)
        self.nCameraHotKeyTimerID = Timer.AddCycle(self , 0.02 , function ()
            self.nCameraRevolveTouch_X = self.nCameraRevolveTouch_X + nAddX
            if self.nCameraRevolveTouch_X > nPosX then
                self.nCameraRevolveTouch_Y = self.nCameraRevolveTouch_Y - nAddX
            else
                self.nCameraRevolveTouch_Y = self.nCameraRevolveTouch_Y + nAddX
            end
            self:UpdateCameraRevolve(self.nCameraRevolveTouch_X, self.nCameraRevolveTouch_Y)
        end)
    end
end

function UISelfieMainView:UpdateInterationState()
    UIHelper.SetVisible(self.WidgetLuxiang, self.eInteractionState == INTERACTION_STATE.Video)
    UIHelper.SetVisible(self.WidgetLuxiang2, self.eInteractionState == INTERACTION_STATE.Video)
    UIHelper.SetVisible(self.WidgetCamera, self.eInteractionState == INTERACTION_STATE.Camera)
    UIHelper.SetVisible(self.WidgetCamera2, self.eInteractionState == INTERACTION_STATE.Camera)
    UIHelper.SetVisible(self.BtnLuxiang, self.eInteractionState == INTERACTION_STATE.VideoTime)
    UIHelper.SetVisible(self.BtnLuxiang2, self.eInteractionState == INTERACTION_STATE.VideoTime)
    UIHelper.SetVisible(self.ProgressCameraTime, self.eInteractionState == INTERACTION_STATE.VideoTime)
    UIHelper.SetVisible(self.ProgressCameraTime2, self.eInteractionState == INTERACTION_STATE.VideoTime)
    UIHelper.SetVisible(self.TogUISwitch, self.eInteractionState == INTERACTION_STATE.Video)
    UIHelper.SetVisible(self.TogUISwitch2, self.eInteractionState == INTERACTION_STATE.Video)
    if self.eInteractionState == INTERACTION_STATE.Video then
        UIHelper.SetSelected(self.TogUISwitch, SelfieData.bShowUIVideoRecord)
        UIHelper.SetSelected(self.TogUISwitch2, SelfieData.bShowUIVideoRecord)
    end
end

function UISelfieMainView:OnStartVideo()
    UIHelper.SetString(self.LabelBeginTitle,"3")
    UIHelper.SetString(self.LabelBeginTitle2,"3")
    local nFpsCount = 0
    self:StartRecordScreen( GetFPS(), true)
    self.nVideoTestTimerID = Timer.AddCountDown(self, 3, function (nRemain)
        if nRemain <= 1 then
            nFpsCount = nFpsCount + GetFPS()
        end
        UIHelper.SetString(self.LabelBeginTitle,nRemain)
        UIHelper.SetString(self.LabelBeginTitle2,nRemain)
    end, function ()
        UIHelper.SetString(self.LabelBeginTitle,"")
        UIHelper.SetString(self.LabelBeginTitle2,"")
        self.bCanClickLuaXiang = false
        UIHelper.SetButtonState(self.BtnLuxiang, BTN_STATE.Normal)
        UIHelper.SetButtonState(self.BtnLuxiang2, BTN_STATE.Normal)
        self.bVideoTimeDownCount = false
        Timer.Add(self, 1 , function ()
            self.bCanClickLuaXiang = true
        end)
        self:StopRecordScreen()
        local recordFrame = math.floor(nFpsCount * 0.5)
        self:StartRecordScreen(recordFrame, false)
        UIHelper.SetString(self.labelLuXiangTime,Timer.Format2Minute(0))
        UIHelper.SetString(self.labelLuXiangTime2,Timer.Format2Minute(0))
        self.nVideoTimerID = Timer.AddCountDown(self, nVideoMaxTime, function (nRemain)
            UIHelper.SetString(self.labelLuXiangTime,Timer.Format2Minute(nVideoMaxTime - nRemain))
            UIHelper.SetString(self.labelLuXiangTime2,Timer.Format2Minute(nVideoMaxTime - nRemain))
            UIHelper.SetProgressBarPercent(self.ImgSliderExperience , math.min(100 - nRemain/nVideoMaxTime*100, 100))
            UIHelper.SetProgressBarPercent(self.ImgSliderExperience2 , math.min(100 - nRemain/nVideoMaxTime*100, 100))
        end, function ()
            self:OnEndVideo()
        end)
    end)
end

function UISelfieMainView:OnEndVideo()
    self.eInteractionState = INTERACTION_STATE.Video
    Timer.DelTimer(self, self.nVideoTestTimerID)
    Timer.DelTimer(self, self.nVideoTimerID)
    self:ResetQulity()
    if not self.WidgetLoading then
        self.WidgetLoading = UIHelper.FindChildByName(self.WidgetAnchorMiddle, "WidgetLoading")
    end
    UIHelper.SetVisible(self.WidgetLoading, true)
    Timer.AddFrame(self,1,function ()
        local nWidth, nHeight
        if self.nSizeMode ~= SIZE_TYPE.FullScreen then
            nWidth, nHeight = UIHelper.GetContentSize(self.ImgBgBox)
        end

        self:StopRecordScreen()
        UIMgr.Open(self._nViewID == VIEW_ID.PanelCameraVertical and VIEW_ID.PanelCameraVideoSharePortrait or VIEW_ID.PanelCameraVideoShare, self.szRecordScreenFilePath, self.szRecordScreenFileName, function ()
            Timer.Add(self,0.5,function ()
                self:UpdateInterationState()
            end)
            UIHelper.SetVisible(self.WidgetLoading, false)
        end, nWidth, nHeight)
    end)
end

function UISelfieMainView:StartRecordScreen(nFpsCount, bTest)
    if not self.bStartRecordScreen then
        local folder = GetFullPath("dcim/")
        local dt = TimeToDate(os.time())
        CPath.MakeDir(folder)
        self.szRecordScreenFileName = string.format("%04d%02d%02d%02d%02d%02d.mp4",dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second)
        self.szRecordScreenFilePath = UIHelper.GBKToUTF8(folder)
        if not Platform.IsMobile() and not Platform.IsMac() then
           folder = "dcim/"
        end

        if self.nSizeMode == SIZE_TYPE.FullScreen then
            cc.utils:takeRecordScreen(folder..self.szRecordScreenFileName , nFpsCount, bTest, SelfieData.bShowUIVideoRecord, false,self.bUseAISign,self.bUseAIParam)
        else
            local nEnginePosX, nEnginePosY, nCutX, nCutY = self:GetRecordSize()
            cc.utils:takeRecordScreen(folder..self.szRecordScreenFileName , nFpsCount, bTest, SelfieData.bShowUIVideoRecord, false,self.bUseAISign,self.bUseAIParam,nEnginePosX, nEnginePosY, nCutX, nCutY)
        end

        self.bStartRecordScreen = true
        UIHelper.SetVisible(self.BtnDrag, false)
        UIHelper.SetVisible(self.BtnApplique, false)
    end
end

function UISelfieMainView:StopRecordScreen()
    if self.bStartRecordScreen then
        cc.utils:stopRecordScreen()
    end
    UIHelper.SetString(self.labelLuXiangTime,"")
    UIHelper.SetString(self.labelLuXiangTime2,"")
    self.bStartRecordScreen = false
    UIHelper.SetVisible(self.BtnDrag, true)
    UIHelper.SetVisible(self.BtnApplique, true)
end

function UISelfieMainView:UpdateRecordVideo()
    UIHelper.SetVisible(self.BtnCamera, not m_bEnableRecordVideo)
    local WigetCameraChange = UIHelper.GetChildByName(self.WidgetAnchorLeft, "WigetCameraChange")
    local WigetCameraChange2 = UIHelper.GetChildByName(self.WidgetAnchorLeft_AR, "WigetCameraChange")
    if not self.labelLuXiangTime then
        self.labelLuXiangTime = UIHelper.GetChildByName(WigetCameraChange, "WidgetLuXiangTime/LabelTitle")
    end
    if not self.labelLuXiangTime2 then
        self.labelLuXiangTime2 = UIHelper.GetChildByName(WigetCameraChange2, "WidgetLuXiangTime/LabelTitle")
    end
    UIHelper.SetVisible(WigetCameraChange, m_bEnableRecordVideo)
    UIHelper.SetVisible(WigetCameraChange2, m_bEnableRecordVideo)
    UIHelper.SetVisible(self.WidgetCamera, m_bEnableRecordVideo)
    UIHelper.SetVisible(self.WidgetCamera2, m_bEnableRecordVideo)
    UIHelper.SetString(self.LabelBeginTitle,"")
    UIHelper.SetString(self.LabelBeginTitle2,"")
    UIHelper.SetString(self.labelLuXiangTime,"")
    UIHelper.SetString(self.labelLuXiangTime2,"")
end

function UISelfieMainView:HotVideo()
    if self.eInteractionState == INTERACTION_STATE.Video then
        if UIMgr.GetView(VIEW_ID.PanelCameraVideoShare) or UIMgr.GetView(VIEW_ID.PanelCameraVideoSharePortrait) then
            return
        end
        self:OnVideoDown()
    elseif self.eInteractionState == INTERACTION_STATE.VideoTime then
        if self.bVideoTimeDownCount then
            TipsHelper.ShowNormalTip("倒计时预备中")
        else
            if self.bCanClickLuaXiang then
                self:OnEndVideo()
            else
                TipsHelper.ShowNormalTip("录制最少1秒")
            end
        end
    end
end
local function SendTrackingData(bCard)
	local szEventID = "photo.click"
    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end
	local tData = {
		appid        = "jx3",
		eventdesc    = "selfie_vk",
		eventid      = szEventID,
		msgtype      = "custom.event",
		accountId    = Login_GetAccount and Login_GetAccount() or "",
		globalroleid = UI_GetClientPlayerGlobalID() or "",
		mapid 		 = player.GetMapID(),
		bCard 		 = bCard and 1 or 0,
	}
    local szPostContent = "appid=%s&msgtype=%s&eventid=%s&eventdesc=%s&accountId=%s&globalroleId=%s&mapid=%s&bcard=%d"
    local szData = string.format(szPostContent, tData.appid, tData.msgtype, tData.eventid, tData.eventdesc, tData.accountId, tData.globalroleid, tData.mapid, tData.bCard)

    CURL_HttpPost(szEventID, tUrl.PageClick, szData)
end

function UISelfieMainView:HotPhoto()
    UIHelper.SetVisible(self._rootNode , false)
    SendTrackingData(self.bNameCard)
    if self.bNameCard then
        if self:JudgeSpecialBuff() then
            TipsHelper.ShowNormalTip("您的角色当前状态不能拍摄名片")
            m_bShotting = false
            UIHelper.SetVisible(self._rootNode , true)
        else
            self:HideAllView()
            Timer.Add(self , 0.2 , function ()
                if self:JudgeSpecialBuff() then
                    self:ShowAllView()
                    m_bShotting = false
                    UIHelper.SetVisible(self._rootNode , true)
                    TipsHelper.ShowNormalTip("您的角色当前状态不能拍摄名片")
                else
                    self:SwitchQulity(function ()
                        UIHelper.CaptureScreenMainPlayer(function (pRetTexture , pImage)
                            m_bShotting = false
                            if not UIMgr.GetView(VIEW_ID.PanelPersonalCardCropping) then
                                local script = UIMgr.Open(self:IsCardCropp2K() and VIEW_ID.PanelPersonalCardCropping2k or VIEW_ID.PanelPersonalCardCropping , pRetTexture, pImage, function ()
                                    UIHelper.SetVisible(self._rootNode , true)
                                    self:ShowAllView()
                                    self:ResetQulity()
                                end)
                                assert(script)
                                script:SetPersonalCardIndex(self.nPersonalCardIndex)
                            end
                            self:FlowerPsNeeded()

                            --开启忽略的界面
                            for _, tbIgnoreIDs in pairs(SelfieData.tbLayerIgnoreIDs) do
                                for k, _viewId in pairs(tbIgnoreIDs) do
                                    if table.contain_value(self.tbPhotoHideViews , _viewId) then
                                        local view = UIMgr.GetView(_viewId)
                                        local node = view and view.node
                                        if node then
                                            node:setVisible(true)
                                        end
                                    end
                                end
                            end

                        end, 1 , true)
                    end)
                end
            end)
        end
    else
        self:SwitchQulity(function ()
            self:HideAllView()
            if not self.bStartFreeze then
                self:StartFreeze()
            end
            self:CaptureScreenNoMessage()
        end)
    end
end

function UISelfieMainView:OpenThumbnailParse()
    self.bOpenThumbnail = true
    self.nThumbnailTimerID = Timer.AddFrameCycle(self, 5, function ()
        local bShow = false

        local player = GetClientPlayer()
        if player then
            local nCurMapID = player.GetMapID()
            for k, v in pairs(UIThumbnailTab) do
                if nCurMapID == v.nMapID and QuestData.IsProgressing(v.nQuestID) then
                    local nX = (player.nX - v.tbPos[1])
                    local nY = (player.nY - v.tbPos[2])
                    local nZ = (player.nZ - v.tbPos[3])
                    local dis = math.sqrt(math.pow(nX, 2) + math.pow(nY, 2) + math.pow(nZ / 8, 2))
                    if dis <= THUMBNAIL_DIS then
                        bShow = true
                        self.nThumbnailImageID = v.nImageID
                        break
                    end
                end
            end

        end
        UIHelper.SetVisible(self.BtnImgCard , bShow)
        UIHelper.LayoutDoLayout(self.WIdgetAchorRight)
        if not bShow then
            self.nThumbnailImageID = 0
        end
    end)
end

function UISelfieMainView:CloseThumbnailParse()
    if self.bOpenThumbnail then
        Timer.DelTimer(self, self.nThumbnailTimerID)
    end
end

function UISelfieMainView:OpenStudio()
    self.studioLua:Open()
    UIHelper.SetVisible(self.WIdgetAchorRight , false)
    UIHelper.SetVisible(self.WidgetAnchorLowerRight , false)
    UIHelper.SetVisible(self.WidgetCameraZoomSlier , false)
    self:UpdateSwitchUI()
end
function UISelfieMainView:UpdateDownloadEquipRes()
    if not PakDownloadMgr.IsEnabled() then
        return
    end
    if not g_pClientPlayer then
        return
    end
    local tRepresentID = Role_GetRepresentID(g_pClientPlayer)
    local nRoleType = g_pClientPlayer.nRoleType
    local tEquipList, tEquipSfxList = Player_GetPakEquipResource(nRoleType, tRepresentID.nHatStyle, tRepresentID)
    local scriptDownload = UIHelper.GetBindScript(self.WidgetDownload)
    local tConfig = {}
    tConfig.bLong = true
    local bRemoteNotExist
    self.nDownloadDynamicID, bRemoteNotExist = PakDownloadMgr.UserCheckDownloadEquipRes(nRoleType, tEquipList, tEquipSfxList, self.nDownloadDynamicID)
    CoinShopPreview.UpdateSimpleDownloadBtn(scriptDownload, self.nDownloadDynamicID, bRemoteNotExist, tConfig)
end

-------------------录制裁剪相关---------------------

function UISelfieMainView:GetRecordSize(bToCenter)
    local sx, sy = UIHelper.GetScreenToResolutionScale()
    local tbScreenSize = UIHelper.GetScreenSize()
    local screenW = tbScreenSize.width
    local screenH = tbScreenSize.height

    if bToCenter then -- 基于锚点为0.5，0.5的ImgBgBox获得上下左右的裁剪范围
        local nLeft, nRight, nBottom, nTop = 0, 0, 0, 0
        local nPosX, nPosY = UIHelper.GetPosition(self.MaskSize)
        local nDragX, nDragY = UIHelper.GetPosition(self.ImgBgBox)
        nLeft = (nPosX + nDragX) * sx
        nRight = (0 - nPosX + nDragX) * sx
        nTop = (nPosY + nDragY) * sy
        nBottom = (0 - nPosY + nDragY) * sy
        return nLeft, nRight, nTop, nBottom
    end

    local nEnginePosX, nEnginePosY = UIHelper.GetWorldPosition(self.MaskSize)
    nEnginePosX = nEnginePosX * sx
    nEnginePosY = screenH - nEnginePosY * sy

    local nCutX, nCutY = UIHelper.GetContentSize(self.MaskSize)
    nCutX = nCutX * sx
    nCutY = nCutY * sy

    return math.floor(nEnginePosX), math.floor(nEnginePosY), math.floor(nCutX), math.floor(nCutY)
end

function UISelfieMainView:OnChanegSizeMode(nSizeMode)
    self.nSizeMode = nSizeMode
    for k, img in ipairs(self.tbSizeBoxIcon) do
        UIHelper.SetVisible(img, k == self.nSizeMode)
    end

    if self.nSizeMode == SIZE_TYPE.FullScreen then
        UIHelper.SetVisible(self.WidgetSizeBox, false)
        return
    end

    UIHelper.SetVisible(self.WidgetSizeBox, true)

    local screenSize = UIHelper.GetScreenSize()
    local sx, sy = UIHelper.GetScreenToResolutionScale()
    local screenW = screenSize.width * 0.8 / sx
    local screenH = screenSize.height * 0.8 / sy

    local targetRatio = SIZE_TYPE_TO_RATIO[self.nSizeMode]
    local nodeW, nodeH

    if screenW / screenH > targetRatio then
        nodeH = screenH
        nodeW = nodeH * targetRatio
    else
        nodeW = screenW
        nodeH = nodeW / targetRatio
    end

    UIHelper.SetContentSize(self.ImgBgBox, nodeW, nodeH)
    UIHelper.SetContentSize(self.MaskSize, nodeW, nodeH)

    local worldPosX, worldPosY = UIHelper.GetWorldPosition(self.ImgBgBox)
    if not worldPosX or not worldPosY then
        return
    end

    local nWidth, nHeight = UIHelper.GetContentSize(self.ImgBgBox)
    if not nWidth or not nHeight then
        return
    end

    local nAnchorX, nAnchorY = UIHelper.GetAnchorPoint(self.ImgBgBox)
    local minX = nWidth * nAnchorX
    local maxX = screenW - nWidth * nAnchorX
    local minY = nHeight * nAnchorY
    local maxY = screenH - nHeight * nAnchorY

    local posX = worldPosX
    local posY = worldPosY

    if posX < minX then
        posX = minX + 1
    elseif posX > maxX then
        posX = maxX - 1
    end

    if posY < minY then
        posY = minY + 1
    elseif posY > maxY then
        posY = maxY - 1
    end

    UIHelper.SetPosition(self.ImgBgBox, 0, 0, self.WidgetSizeBox)
    UIHelper.WidgetFoceDoAlignAssignNode(self, self.MaskSize)
    UIHelper.WidgetFoceDoAlignAssignNode(self, self.BtnDrag)
    UIHelper.WidgetFoceDoAlignAssignNode(self, self.BtnApplique)
    UIHelper.CascadeDoLayoutDoWidget(self.ImgBgBox, true, true)
end

function UISelfieMainView:UpdateMaskPos(nX, nY)
    if not self.ImgBgBox then
        return
    end

    local screenW, screenH = UIHelper.GetContentSize(self.WidgetSizeBox)
    local nWidth, nHeight = UIHelper.GetContentSize(self.ImgBgBox)
    if not nWidth or not nHeight then
        return
    end

    local nAnchorX, nAnchorY = UIHelper.GetAnchorPoint(self.ImgBgBox)
    local currentPosX, currentPosY = UIHelper.GetPosition(self.ImgBgBox, self.WidgetSizeBox)

    local newPosX = currentPosX + ( nX - nDragX )
    local newPosY = currentPosY + ( nY - nDragY )

    local minX = - (screenW - nWidth) * nAnchorX
    local maxX = (screenW - nWidth) * nAnchorX

    local minY = - (screenH - nHeight) * nAnchorY
    local maxY = (screenH - nHeight) * nAnchorY

    if newPosX < minX then
        newPosX = minX + 1
    elseif newPosX > maxX then
        newPosX = maxX - 1
    end

    if newPosY < minY then
        newPosY = minY + 1
    elseif newPosY > maxY then
        newPosY = maxY - 1
    end

    UIHelper.SetPosition(self.ImgBgBox, newPosX, newPosY, self.WidgetSizeBox)

    UIHelper.WidgetFoceDoAlignAssignNode(self, self.MaskSize)
    UIHelper.WidgetFoceDoAlignAssignNode(self, self.BtnDrag)
    UIHelper.WidgetFoceDoAlignAssignNode(self, self.BtnApplique)
    UIHelper.CascadeDoLayoutDoWidget(self.ImgBgBox, true, true)
end

function UISelfieMainView:UpdateMaskSize(nX, nY)
    if not self.ImgBgBox or not self.nSizeMode then
        return
    end

    local screenW, screenH = UIHelper.GetContentSize(self.WidgetSizeBox)
    local currentWidth, currentHeight = UIHelper.GetContentSize(self.ImgBgBox)
    if not currentWidth or not currentHeight then
        return
    end

    local targetRatio = SIZE_TYPE_TO_RATIO[self.nSizeMode]
    local currentPosX, currentPosY = UIHelper.GetPosition(self.ImgBgBox, self.WidgetSizeBox)
    local nAnchorX, nAnchorY = UIHelper.GetAnchorPoint(self.ImgBgBox)

    local deltaX = nX - nDragX
    local deltaY = nY - nDragY

    local dragDistance = math.sqrt(deltaX * deltaX + deltaY * deltaY)
    local angle = math.atan2(deltaY, deltaX)
    local scaleFactor = 1.0 + (dragDistance * 0.003 * math.cos(angle))

    if scaleFactor < 0.1 then
        scaleFactor = 0.1
    elseif scaleFactor > 3.0 then
        scaleFactor = 3.0
    end

    local newWidth = currentWidth * scaleFactor
    local newHeight = currentHeight * scaleFactor

    local minWidth = screenW * MIN_SIZE_SCALE
    local minHeight = screenH * MIN_SIZE_SCALE

    local maxWidth = screenW * 0.80
    local maxHeight = screenH * 0.80

    if newWidth >= maxWidth or newHeight >= maxHeight
        or (newWidth <= minWidth and newHeight <= minHeight )then
        return
    end

    newWidth = math.min(newWidth, maxWidth)
    newHeight = math.min(newHeight, maxHeight)

    local minX = - (screenW - newWidth) * nAnchorX
    local maxX = (screenW - newWidth) * nAnchorX

    local minY = - (screenH - newHeight) * nAnchorY
    local maxY = (screenH - newHeight) * nAnchorY

    if currentPosX < minX + 1 or currentPosX > maxX - 1 or
       currentPosY < minY + 1 or currentPosY > maxY - 1 then
        return
    end

    UIHelper.SetContentSize(self.ImgBgBox, newWidth, newHeight)
    UIHelper.SetContentSize(self.MaskSize, newWidth, newHeight)

    UIHelper.WidgetFoceDoAlignAssignNode(self, self.MaskSize)
    UIHelper.WidgetFoceDoAlignAssignNode(self, self.BtnDrag)
    UIHelper.WidgetFoceDoAlignAssignNode(self, self.BtnApplique)
    UIHelper.CascadeDoLayoutDoWidget(self.ImgBgBox, true, true)
end
-------------------录制裁剪相关---------------------

-------------------设计站相关---------------------
function UISelfieMainView:DoUploadToShareStaton(nDataType, nPhotoSizeType)
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    if not nDataType then
        return
    end

    local tConfig = ShareCodeData.GetAccountConfig(nDataType)
    if not tConfig then
        self.tbWaitForUploadData = {nDataType = nDataType, nPhotoSizeType = nPhotoSizeType}
        ShareCodeData.ApplyAccountConfig(false, nDataType)
        return
    elseif tConfig.nCount >= tConfig.nUploadLimit then
        ShareCodeData.ShowUploadLimitMsg(nDataType, pPlayer.nRoleType)
        return
    end

    local nState = GetCameraCaptureState()
    if nState == CAMERA_CAPTURE_STATE.Capturing then
        TipsHelper.ShowNormalTip("AR模式下无法上传")
        return
    end

    self:SwitchQulity(function ()
        UIHelper.SetVisible(self._rootNode , false)
        if not self.bStartFreeze then
            self:StartFreeze()
        end

        local tPreviewData = {}
        if nDataType == SHARE_DATA_TYPE.FACE then
            tPreviewData = pPlayer.GetEquipLiftedFaceData()
        elseif nDataType == SHARE_DATA_TYPE.BODY then
            tPreviewData = pPlayer.GetEquippedBodyBoneData()
        elseif nDataType == SHARE_DATA_TYPE.EXTERIOR then
            tPreviewData = SelfieTemplateBase.GetPlayerExteriorData(pPlayer, false)
        end

        if nDataType == SHARE_DATA_TYPE.PHOTO then -- 照片模板需要等待动画信息
            local bIsPortrait = UIHelper.GetScreenPortrait()
            tPreviewData = SelfieTemplateBase.GetPhotoData(self.bNameCard, bIsPortrait)
            Event.Reg(self, EventType.OnSelfieGetLocalAnimationSuccess, function (tAction, tFaceAction)
                tPreviewData.tPlayerParam.tAction = tAction
                tPreviewData.tPlayerParam.tFaceAction = tFaceAction
                nPhotoSizeType = nPhotoSizeType or SHARE_PHOTO_SIZE_TYPE.HORIZONTAL
                ShareStationData.DoUploadByType(nDataType, nPhotoSizeType, tPreviewData, {}, function ()
                    UIHelper.SetVisible(self._rootNode, true)
                    self:ResetQulity()
                    if not self.bIsSelectPause then
                        self:EndFreeze()
                    end
                end)
            end, true)
            return
        end

        ShareStationData.DoUploadByType(nDataType, nPhotoSizeType, tPreviewData, {}, function ()
            UIHelper.SetVisible(self._rootNode, true)
            self:ResetQulity()
            if not self.bIsSelectPause then
                self:EndFreeze()
            end
        end)
    end)
end

function UISelfieMainView:DoUploadToLocal()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    local nState = GetCameraCaptureState()
    if nState == CAMERA_CAPTURE_STATE.Capturing then
        TipsHelper.ShowNormalTip("AR模式下无法上传")
        return
    end

    local onNodeHideCallback = function()
        self:OnNodeHideCallback(true)
    end

    local OnNodeShow = function()
        self:OnNodeHideCallback(false)
    end

    self:SwitchQulity(function ()
        UIHelper.SetVisible(self._rootNode , false)
        if not self.bStartFreeze then
            self:StartFreeze()
        end

        local bIsPortrait = UIHelper.GetScreenPortrait()
        local tPhotoData = SelfieTemplateBase.GetPhotoData(self.bNameCard, bIsPortrait)
        Event.Reg(self, EventType.OnSelfieGetLocalAnimationSuccess, function (tAction, tFaceAction)
            tPhotoData.tPlayerParam.tAction = tAction
            tPhotoData.tPlayerParam.tFaceAction = tFaceAction
        end, true)

        UIHelper.CaptureScreenMainPlayer(function (pRetTexture, pImage)
            self.DetailScript = UIHelper.GetBindScript(self.WidgetScrollViewTemData)
            self.DetailScript:OnEnter(tPhotoData,
                function ()
                    self.exportLua:Show()
                end,
                onNodeHideCallback
            )
            self.exportLua:Open(tPhotoData, pRetTexture, pImage,
                function ()
                    UIHelper.SetVisible(self._rootNode, true)
                    self:ResetQulity()
                    if not self.bIsSelectPause then
                        self:EndFreeze()
                    end
                end ,

                function (szFileName)
                    local bShowDetail = true
                    self.exportLua:Hide(bShowDetail)
                    self.DetailScript:Open(szFileName)
                end,
                onNodeHideCallback
            )
            OnNodeShow()
        end, 1)
    end)
end

function UISelfieMainView:LinkToShareStation()
    local bCardMode = self.bNameCard
    local szMsg = g_tStrings.STR_SHARE_STATION_LEAVE_SELFIE_CONFIRM
    if bCardMode then
        szMsg = g_tStrings.STR_SHARE_STATION_LEAVE_CARD_CONFIRM
    end
    UIHelper.ShowConfirm(szMsg, function ()
        local bIsPortrait = UIHelper.GetScreenPortrait()
        local nSubType = bCardMode and SHARE_PHOTO_SIZE_TYPE.CARD or SHARE_PHOTO_SIZE_TYPE.HORIZONTAL
        if bIsPortrait then
            nSubType = SHARE_PHOTO_SIZE_TYPE.VERTICAL
        end

        local funcOnClose = function ()
            ShareStationData.tbEventLinkInfo = {
                nDataType = SHARE_DATA_TYPE.PHOTO,
                nSubType = nSubType,
            }
            local scriptView = ShareStationData.OpenShareStation(SHARE_DATA_TYPE.PHOTO)
            Timer.Add(scriptView, 0.1, function ()
                scriptView:OnLink2Share()
            end)
        end

        UIMgr.Close(self)
        Timer.Add(ShareStationData, 1, funcOnClose)
    end)
end

function UISelfieMainView:OnOpenSettingView(nIndex)
    self.cameraSettingLua:Open(nIndex)
    UIHelper.SetVisible(self.WIdgetAchorRight , false)
    UIHelper.SetVisible(self.WidgetAnchorLowerRight , false)
    UIHelper.SetVisible(self.WidgetCameraZoomSlier , false)
    self:UpdateSwitchUI()
end

function UISelfieMainView:OnOpenActionView(nIndex)
    self.emotionActionLua:Open(nIndex)
    UIHelper.SetVisible(self.WIdgetAchorRight , false)
    UIHelper.SetVisible(self.WidgetAnchorLowerRight , false)
    UIHelper.SetVisible(self.WidgetCameraZoomSlier , false)
    self:UpdateSwitchUI()
end
-------------------设计站相关---------------------

function UISelfieMainView:OnNodeHideCallback(bHide, bIgnoreCondition, bLinkDesign)
    if SelfieOneClickModeData.bOpenOneMode and not bIgnoreCondition then
        return
    end
    UIHelper.SetVisible(self.WIdgetAchorRight , bHide)
    UIHelper.SetVisible(self.WidgetAnchorLowerRight , bHide)
    UIHelper.SetVisible(self.WidgetCameraZoomSlier , bHide)
    if bLinkDesign then
        UIHelper.SetVisible(self.BtnDesignStation, bHide)
    end
  
    self:UpdateSwitchUI()
end

-------------------一键成片相关---------------------
function UISelfieMainView:OpenRightSettingView(nType)
    if not self.camerRightSettingLua then
        self.camerRightSettingLua = UIMgr.Open(VIEW_ID.PanelCameraSettingRight, function ()
            self:OnNodeHideCallback(true, false, true)
            self.camerRightSettingLua = nil
        end)
    end
    self.camerRightSettingLua:Open(nType)
    self:OnNodeHideCallback(false, false, true)
end

function UISelfieMainView:OpenOneClickView()
    self.script_oneclick = UIMgr.Open(VIEW_ID.PanelToVideo, function ()
        self.script_oneclick = nil
        self:OnNodeHideCallback(true, true, true)
    end)
    self:OnNodeHideCallback(false, true, true)
end

-------------------一键成片End---------------------

return UISelfieMainView