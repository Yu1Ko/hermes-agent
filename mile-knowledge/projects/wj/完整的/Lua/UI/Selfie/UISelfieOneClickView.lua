-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UISelfieOneClickView
-- Date: 
-- Desc: 
-- ---------------------------------------------------------------------------------
local UISelfieOneClickView = class("UISelfieOneClickView")

-- 标签类型
local IndexType = 
{
    CamerMovie = 1,
    BGM = 2,
    FaceAction = 3,
    Action = 4,
    AI = 5,
    None = 10,
}

local tbGSRSnapShotGPUModel = {
    ["Apple A9X GPU"] = true,
}

local BGM_UI_PRIORITY = 7
local m_nOneClickID = 0
local m_bWaitPrepareFlag = nil
local m_bActionPlaySuccess = nil
local m_bResourceLoaded = nil
local m_fPrepareTotalTime = nil
-----------------------------DataModel------------------------------
local DataModel = {}

function DataModel.Init()
    DataModel.tCamAniData = {}
    DataModel.bCustomBgm = nil
    DataModel.dwActionID = nil
    DataModel.dwFaceEmotionID = nil
    DataModel.tVideoPrams = {}
end

function DataModel.UnInit()
    for k, v in pairs(DataModel) do
        if type(v) ~= "function" then
            DataModel[k] = nil
        end
    end
end

function DataModel.GetCamAniPlayData(nType, nCamAniID)
    local tData = {
        nType = nType,
        nID = nCamAniID,
        bEnableLerp = false
    }
    return tData
end
-----------------------------View------------------------------
function UISelfieOneClickView:OnEnter(onCloseCallback)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.onCloseCallback = onCloseCallback
    DataModel.Init()
    self:UpdateInfo()
    SelfieOneClickModeData.bOpenOneMode = true
end

function UISelfieOneClickView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    self:EndRecording(true)
    SelfieOneClickModeData.bOpenOneMode = false
    SelfieMusicData.OnStopBgMusic(true)
    SelfieOneClickModeData.Clear()
    if self.onCloseCallback then
        self.onCloseCallback()
    end
end

function UISelfieOneClickView:BindUIEvent()

    UIHelper.BindUIEvent(self.BtnPreview, EventType.OnClick, function ()
        self:OnOpenVideoRecord(SELFIE_VIDEO_RECORD_TYPE.PREVIEW)
    end)

    UIHelper.BindUIEvent(self.BtnCompleteFilm, EventType.OnClick, function ()
        if Platform.IsMobile() then
            if QualityMgr.GetRecommendQualityType() < GameQualityType.HIGH then
                TipsHelper.ShowImportantBlueTip("默认推荐画质为电影或极致的设备方可使用此功能")
            else
                self:StartOneClickRecord()
            end
        else
            self:StartOneClickRecord()
        end
    end)

    UIHelper.BindUIEvent(self.TogAI, EventType.OnClick, function ()
        Event.Dispatch("ON_SELFIE_SWITCH_RIGHT_TYPE",SELFIE_CAMERA_RIGHT_TYPE.AIGC)
        self:SetRightWidgetVisible(false)
        self:ChangeToggleState(IndexType.AI, true)
    end)

    UIHelper.BindUIEvent(self.TogCamMove, EventType.OnClick, function ()
        Event.Dispatch("ON_SELFIE_SWITCH_RIGHT_TYPE",SELFIE_CAMERA_RIGHT_TYPE.MOVIE)
        self:SetRightWidgetVisible(false)
        self:ChangeToggleState(IndexType.CamerMovie, true)
    end)

    UIHelper.BindUIEvent(self.TogFaceAction, EventType.OnClick, function ()
        if SelfieOneClickModeData.bEnableAIGerate  then
            Event.Dispatch("ON_SELFIE_SWITCH_EMOTION_FACEACTION")
        end
        SelfieOneClickModeData.nCustomMotionType = AI_MOTION_TYPE.FACE
        self:SetRightWidgetVisible(false)
        self:ChangeToggleState(IndexType.FaceAction, true)
    end)

    UIHelper.BindUIEvent(self.TogAction, EventType.OnClick, function ()
        if SelfieOneClickModeData.bEnableAIGerate  then
            Event.Dispatch("ON_SELFIE_SWITCH_EMOTION_ACTION")
        end
        SelfieOneClickModeData.nCustomMotionType = AI_MOTION_TYPE.BODY
        self:SetRightWidgetVisible(false)
        self:ChangeToggleState(IndexType.Action, true)
    end)

    UIHelper.BindUIEvent(self.TogBgm, EventType.OnClick, function ()
        Event.Dispatch("ON_SELFIE_SWITCH_RIGHT_TYPE",SELFIE_CAMERA_RIGHT_TYPE.MUSIC)
        self:SetRightWidgetVisible(false)
        self:ChangeToggleState(IndexType.BGM, true)
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    for k, btnDeleted in pairs(self.tbBtnDelete) do
        UIHelper.BindUIEvent(btnDeleted, EventType.OnClick, function ()
            if k == IndexType.BGM then
                Event.Dispatch("ON_ONE_CLICK_CHOOSE_BGM", nil, 0,0,false)
            elseif k == IndexType.CamerMovie  then
                Event.Dispatch("ON_ONE_CLICK_CHOOSE_CAM_ANI", false, nil)
            elseif k == IndexType.Action  then
                Event.Dispatch("ON_ONE_CLICK_CHOOSE_BODY_ACTION", false, nil, nil)
            elseif k == IndexType.FaceAction  then
                Event.Dispatch("ON_ONE_CLICK_CHOOSE_FACE_ACTION", false, nil, nil)
            end
        end)
    end
end

function UISelfieOneClickView:OnPrepareFinish(nUserID, fTotalTime)
    m_bResourceLoaded = true
    m_fPrepareTotalTime= fTotalTime
    local dwActionID = DataModel.dwActionID
    if dwActionID then
        if dwActionID > 0 then
            EmotionData.ProcessEmotionAction(dwActionID, nil, true)
        elseif DataModel.szAIActionPath then
            AiBodyMotionData.ProcessAIAction(DataModel.szAIActionPath, true)
        end
    end

    local dwFaceEmotionID = DataModel.dwFaceEmotionID
    if dwFaceEmotionID then
        if dwFaceEmotionID > 0 then
            AiBodyMotionData.ProcessFaceMotion(dwFaceEmotionID)
        elseif DataModel.szAIFacePath then
            AiBodyMotionData.ProcessFaceMotion(DataModel.szAIFacePath)
        end
    end

    LOG.INFO("[UISelfieOneClickView] OnPrepareFinish  %s,%s",tostring(dwActionID),tostring(dwFaceEmotionID))

    if not dwActionID then
        self:OnOpenVideoRecord(SELFIE_VIDEO_RECORD_TYPE.FILM, DataModel.tVideoPrams)
        self:StartRecording()
    end
   
end

function UISelfieOneClickView:RegEvent()
    Event.Reg(self, "ILLUSION_VIDEO_NOTIFY", function (nEventType, nUserID, fTotalTime)
        if nEventType == ILLUSION_VIDEO_EVENT.RESOURCE_LOADED then
            self:OnPrepareFinish(nUserID, fTotalTime)
        elseif nEventType == ILLUSION_VIDEO_EVENT.VIDEO_FINISH then
            self:EndRecording(true)
        elseif nEventType == ILLUSION_VIDEO_EVENT.END then
            self:EndRecording(true)
        end
    end)

    Event.Reg(self, "ON_ONE_CLICK_CHOOSE_CAM_ANI", function (bSeq, tCamAniData)
        DataModel.tCamAniData = tCamAniData
        self:UpdateCamAni(bSeq, tCamAniData)
        self:UpdatePreviewAndRecordState()
    end)

    Event.Reg(self, "ON_ONE_CLICK_CHOOSE_BGM", function (nBgmID, nStartTime, nEndTime, bCustom)
        self:UpdateBgm(nBgmID, nStartTime, nEndTime, bCustom)
        self:UpdatePreviewAndRecordState()
    end)

    Event.Reg(self, "ON_ONE_CLICK_CHOOSE_BODY_ACTION", function (bAIAct, szKey, szCustomName)
        self:UpdateBodyAction(bAIAct, szKey, szCustomName)
        self:UpdatePreviewAndRecordState()
    end)

    Event.Reg(self, "ON_ONE_CLICK_CHOOSE_FACE_ACTION", function (bAIAct, szKey, szCustomName)
        self:UpdateFaceAction(bAIAct, szKey, szCustomName)
        self:UpdatePreviewAndRecordState()
    end)

    Event.Reg(self, "OnPlayOneClickAction_CallBack", function (bSuccess)
        LOG.INFO("[UISelfieOneClickView] OnPlayOneClickAction_CallBack  %s,%s,%s,%s",tostring(m_bWaitPrepareFlag),tostring(m_bResourceLoaded),tostring(m_fPrepareTotalTime),tostring(bSuccess))
        if not m_bWaitPrepareFlag then
            return
        end
    
        if not m_bResourceLoaded then
            return
        end
    
        if m_fPrepareTotalTime == nil then
            return
        end
        if not bSuccess then
            m_bWaitPrepareFlag = nil
            Timer.DelTimer(self, self.nPrepareTimerID)
            OutputMessage("MSG_SYS", g_tStrings.STR_SELFIE_ONE_CLICK_ACTION_FAIL)
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_SELFIE_ONE_CLICK_ACTION_FAIL)
            self:UpdatePreviewAndRecordState()
        else
            m_bWaitPrepareFlag = nil
            self:OnOpenVideoRecord(SELFIE_VIDEO_RECORD_TYPE.FILM, DataModel.tVideoPrams)
            self:StartRecording()
        end
    end)
    
    Event.Reg(self, "ON_SELFIE_EMOTION_ACTION_HIDE", function ()
        self:SetRightWidgetVisible(true)
    end)

    Event.Reg(self, "ON_SELFIE_RIGHT_PANEL_HIDE", function ()
        self:SetRightWidgetVisible(true)
    end)
end

function UISelfieOneClickView:UnRegEvent()
    
end

function UISelfieOneClickView:UpdateInfo()
    self.ToggleSeletedState = {}
    for k, v in pairs(IndexType) do
        self.ToggleSeletedState[v] = false
    end
    local tAniData = SelfieOneClickModeData.GetCamAniData()
    local tBgmData = SelfieOneClickModeData.GetBGMData()
    local tBodyData = SelfieOneClickModeData.GetBodyActionData()
    local tFaceData = SelfieOneClickModeData.GetFaceActionData()
    self:UpdateCamAni(tAniData.bSeq, tAniData.tCamAniData)
    self:UpdateBgm(tBgmData.nBgmID, tBgmData.nStartTime, tBgmData.nEndTime, tBgmData.bCustom)
    self:UpdateBodyAction(tBodyData.bAIAct, tBodyData.szKey, tBodyData.szCustomName)
    self:UpdateFaceAction(tFaceData.bAIAct, tFaceData.szKey, tFaceData.szCustomName)
    self:UpdatePreviewAndRecordState()

    if not AiBodyMotionData.IsAIFeatureInWhitelist() then
        UIHelper.SetButtonState(self.TogAI, BTN_STATE.Disable, "封闭测试中，敬请期待")
    elseif not AiBodyMotionData.IsMaxLevel() then
        UIHelper.SetButtonState(self.TogAI, BTN_STATE.Disable)
        UIHelper.SetVisible(UIHelper.FindChildByName(self.TogAI,"WidgetMotionCaptureLocked"), true)
    else
        UIHelper.SetButtonState(self.TogAI, BTN_STATE.Normal)
    end
end

function UISelfieOneClickView:ChangeToggleState(index, bSelected)
    if index ~= IndexType.None then
        self.ToggleSeletedState[index] = bSelected or (not self.ToggleSeletedState[index])
        UIHelper.SetVisible(self.tbWidgetSelected[index], self.ToggleSeletedState[index])
    end
    for k, v in pairs(self.tbWidgetSelected) do
        if k ~= index and self.ToggleSeletedState[k] then
            self.ToggleSeletedState[k] = false
            UIHelper.SetVisible(v, false)
        end
    end
end

function UISelfieOneClickView:UpdateBgm(nBgmID, nStartTime, nEndTime, bCustom)
    self:UpdateDeleteState(IndexType.BGM, nBgmID ~= nil)
    if not nBgmID then
        UIHelper.SetString(self.tbLabelName[IndexType.BGM], g_tStrings.STR_SELFIE_BGM)
        DataModel.tBgmParam = nil
        self:UpdateTexture(IndexType.BGM, "")
        return
    end

    local tInfo = Table_GetSelfieBGMInfo(nBgmID)
    DataModel.tBgmParam = {
        nBgmID = nBgmID,
        szFile = tInfo.szBgmEvent,
        nStartTime = nStartTime,
        nEndTime = nEndTime,
        nPriority = BGM_UI_PRIORITY,
    }
    DataModel.bCustomBgm = bCustom
    self:UpdateTexture(IndexType.BGM, tInfo.szImgPath or "")
    UIHelper.SetString(self.tbLabelName[IndexType.BGM], UIHelper.GBKToUTF8(tInfo.szName))
end

function UISelfieOneClickView:UpdateCamAni(bSeq, tCamAniData)
    if not bSeq then
        local tData = tCamAniData and tCamAniData[0]
        if tData then
            local tInfo = Table_GetSelfieCameraAniData(tData.nID)
            self:UpdateTexture(IndexType.CamerMovie, tInfo.szPreviewImgPath or "")
            UIHelper.SetString(self.tbLabelName[IndexType.CamerMovie], UIHelper.GBKToUTF8(tInfo.szName))
        else
            UIHelper.SetString(self.tbLabelName[IndexType.CamerMovie], g_tStrings.STR_SELFIE_CAMERA)
            self:UpdateTexture(IndexType.CamerMovie, "")
            Scene_StopReferenceCameraAni()
        end
        self:UpdateDeleteState(IndexType.CamerMovie, tData ~= nil)
    else
        if tCamAniData then
            self:UpdateTexture(IndexType.CamerMovie, "Resource\\UItimate\\Selfie\\CamAniImg\\LianXuYunJing.png")
            UIHelper.SetString(self.tbLabelName[IndexType.CamerMovie], g_tStrings.STR_SELFIE_SEQ_CAMERA)
        else
            UIHelper.SetString(self.tbLabelName[IndexType.CamerMovie], g_tStrings.STR_SELFIE_CAMERA)
            self:UpdateTexture(IndexType.CamerMovie, "")
        end
        self:UpdateDeleteState(IndexType.CamerMovie, tCamAniData ~= nil)
    end
end

function UISelfieOneClickView:UpdateBodyAction(bAIAct, szKey, szCustomName)
    self:UpdateDeleteState(IndexType.Action, szKey ~= nil)
    if not szKey then
        UIHelper.SetString(self.tbLabelName[IndexType.Action], g_tStrings.STR_SELFIE_ONE_CLICK_ACTION)
        DataModel.dwActionID = nil
        DataModel.szAIActionPath = nil
        self:UpdateItemIcon(IndexType.Action, -1)
        return
    end
    if bAIAct then
        if szCustomName then
            UIHelper.SetString(self.tbLabelName[IndexType.Action], szCustomName)
        else
            UIHelper.SetString(self.tbLabelName[IndexType.Action], g_tStrings.STR_SELFIE_AI_BODY_ACT)
        end
        self:UpdateItemIcon(IndexType.Action, 0, SelfieOneClickModeData.szBodyActionSprite)
        DataModel.dwActionID = 0
        DataModel.szAIActionPath = szKey
    else
        local tActInfo = EmotionData.GetEmotionAction(szKey)
        self:UpdateItemIcon(IndexType.Action, tActInfo.nIconID)
        local nCharCount,szUtfName = GetStringCharCountAndTopChars(UIHelper.GBKToUTF8(tActInfo.szName),4)
        UIHelper.SetString(self.tbLabelName[IndexType.Action],nCharCount > 4 and szUtfName.."..." or szUtfName)
        DataModel.dwActionID = szKey
        DataModel.szAIActionPath = nil
    end
end

function UISelfieOneClickView:UpdateFaceAction(bAIAct, szKey, szCustomName)
    self:UpdateDeleteState(IndexType.FaceAction, szKey ~= nil)
    if not szKey then
        UIHelper.SetString(self.tbLabelName[IndexType.FaceAction], g_tStrings.STR_SELFIE_ONE_CLICK_FACE)
        DataModel.dwFaceEmotionID = nil
        DataModel.szAIFacePath = nil
        self:UpdateItemIcon(IndexType.FaceAction, -1)
        return
    end
    if bAIAct then
        if szCustomName then
            UIHelper.SetString(self.tbLabelName[IndexType.FaceAction], szCustomName)
        else
            UIHelper.SetString(self.tbLabelName[IndexType.FaceAction], g_tStrings.STR_SELFIE_AI_FACE_ACT)
        end
        self:UpdateItemIcon(IndexType.FaceAction, 0, SelfieOneClickModeData.szFaceActionSprite)
        DataModel.dwFaceEmotionID = 0
        DataModel.szAIFacePath = szKey
    else
        local tFaceMotion = EmotionData.GetFaceMotion(szKey)
        if tFaceMotion then
            UIHelper.SetString(self.tbLabelName[IndexType.FaceAction], UIHelper.GBKToUTF8(tFaceMotion.szName))
            self:UpdateItemIcon(IndexType.FaceAction, tFaceMotion.nIconID)
        end
        DataModel.dwFaceEmotionID = szKey
        DataModel.szAIFacePath = nil
    end
end

function UISelfieOneClickView:UpdateTexture(index, szPath)
    UIHelper.SetVisible(self.tbIconEmpty[index], szPath == "")
    UIHelper.SetVisible(self.tbIcon[index], szPath ~= "")
    if szPath ~= "" then
        UIHelper.SetTexture(self.tbIcon[index], UIHelper.FixDXUIImagePath(szPath))
    end
end

function UISelfieOneClickView:UpdateItemIcon(index, nIconID, szkey)
    UIHelper.SetVisible(self.tbIconEmpty[index], nIconID == -1)
    UIHelper.SetVisible(self.tbIcon[index], nIconID ~= -1)
    if nIconID ~= -1 then
        if szkey then
            UIHelper.SetSpriteFrame(self.tbIcon[index], szkey)
        else
            UIHelper.SetItemIconByIconID(self.tbIcon[index], nIconID)
        end
    end
end

function UISelfieOneClickView:SetRightWidgetVisible(bVisible)
    UIHelper.SetVisible(self.WidgetAniRight, bVisible)
    UIHelper.SetVisible(self.WidgetAniRightTop, bVisible)
    if bVisible then
        self:ChangeToggleState(IndexType.None, false)
    end
end

function UISelfieOneClickView:UpdateDeleteState(index,bVisible)
    UIHelper.SetVisible(self.tbBtnDelete[index], bVisible)
end

function UISelfieOneClickView:UpdatePreviewAndRecordState()
    local bHasMovie = (DataModel.tCamAniData and not table.is_empty(DataModel.tCamAniData)) and true or false
    UIHelper.SetButtonState(self.BtnCompleteFilm, bHasMovie and BTN_STATE.Normal or BTN_STATE.Disable, nil, true)

    local bCanPre = (bHasMovie or DataModel.dwActionID or DataModel.dwFaceEmotionID or DataModel.tBgmParam) and true or false
    UIHelper.SetButtonState(self.BtnPreview, bCanPre and BTN_STATE.Normal or BTN_STATE.Disable, nil, true)
end

function UISelfieOneClickView:GetVideoParams()
    -- AI动作拦截：未同意免责声明时不允许使用AI身体/面部动作
    local bAIBodyAct = DataModel.szAIActionPath ~= nil and DataModel.szAIActionPath ~= ""
    local bAIFaceAct = DataModel.szAIFacePath ~= nil and DataModel.szAIFacePath ~= ""
    local bAddAIMetaData = bAIBodyAct or bAIFaceAct

    if bAddAIMetaData and not AiBodyMotionData.CheckAgreeStatement() then
        return
    end

    -- 预先设置隐式数据块（备用）；是否写入视频由 bAddAIMetaData 决定
    SelfieData.SetAIParam()
    local nFps = GetFPS()

    local bUseAILogo = false
    if bAddAIMetaData then
         bUseAILogo = true 
    end

    local folder = GetFullPath("dcim/")
    local dt = TimeToDate(os.time())
    CPath.MakeDir(folder)
    local szFileName = string.format("%04d%02d%02d%02d%02d%02d.mp4",dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second)
    folder= UIHelper.GBKToUTF8(folder)
    local szRecordScreenFilePath = folder
    if not Platform.IsMobile() and not Platform.IsMac() then
        folder = "dcim/"
     end

    local tVideoPrams = {
        nFps = nFps,
        bRecordUI = false,
        bUseAILogo = bUseAILogo,
        bAddAIMetaData = bAddAIMetaData,
        szRecordScreenFilePath = szRecordScreenFilePath,
        szFolder = folder,
        szFileName = szFileName,
    }
    return tVideoPrams
end

function UISelfieOneClickView:OnOpenVideoRecord(nType, tParams)
    local tVideoPrams = tParams or self:GetVideoParams()
    if not tVideoPrams then
        return
    end
    UIHelper.SetVisible(self._rootNode, false)
    self.script_record = UIMgr.Open(VIEW_ID.PanelRecord, nType, tVideoPrams, function ()
        if nType == SELFIE_VIDEO_RECORD_TYPE.PREVIEW then
            self:StartPreview()
        elseif nType == SELFIE_VIDEO_RECORD_TYPE.FILM then
            self.script_record:SetProgress(0)
        end
    end,function ()
        self:StopPreview()
        if DataModel.tBgmParam then
            local szBgmEvent = Table_GetSelfieBGMEvent(DataModel.tBgmParam.nBgmID)
            SoundMgr.StopUIBgMusic(szBgmEvent, true)
        end
        
        self.script_record = nil
        UIHelper.SetVisible(self._rootNode, true)
    end)
    self.script_record:UpdateInfo()
end

function UISelfieOneClickView:StartOneClickRecord()
    local tVideoPrams = self:GetVideoParams()
    if not tVideoPrams then
        return
    end
    DataModel.tVideoPrams = tVideoPrams
    -- BGM 注:如果选了BGM，需要提前停掉当前在播的BGM，防止和表现加的是同名BGM
    local tBgmParam = DataModel.tBgmParam
    if tBgmParam then
        SoundMgr.StopBgMusic(true)
        SoundMgr.StopUIBgMusic(tBgmParam.szFile, false)
        FireUIEvent("STOP_SELFIE_BGM", tBgmParam.szFile)
    end
    -- 动作
    local dwEmotionID = DataModel.dwActionID

    -- 面部表情
    local dwFaceEmotionID = DataModel.dwFaceEmotionID

    local tCameraParam = {
        tData = DataModel.tCamAniData
    }

    m_nOneClickID = m_nOneClickID + 1
    m_bResourceLoaded = nil
    m_fPrepareTotalTime = nil

    local player = GetClientPlayer()
	if player then
		if player.dwEmotionActionID > 0 then
            EmotionData.ForceStopCurAction()
            Timer.Add(self, 2, function ()
                Scene_PlayIllusionVideo(dwEmotionID, tCameraParam, DataModel.tBgmParam, nil, m_nOneClickID, dwFaceEmotionID)
            end)
        else
            Scene_PlayIllusionVideo(dwEmotionID, tCameraParam, DataModel.tBgmParam, nil, m_nOneClickID, dwFaceEmotionID)
        end
	end

    UIHelper.SetButtonState(self.BtnCompleteFilm, BTN_STATE.Disable, nil, true)
    UIHelper.SetButtonState(self.BtnPreview, BTN_STATE.Disable, nil, true)
    m_bWaitPrepareFlag = true
    self.nPrepareTimerID = Timer.Add(self, 5, function ()
        if m_bWaitPrepareFlag then
            m_bWaitPrepareFlag = nil
            OutputMessage("MSG_SYS", g_tStrings.STR_SELFIE_ONE_CLICK_PREPARE_FAIL)
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_SELFIE_ONE_CLICK_PREPARE_FAIL)
            self:EndRecording(true)
        end
    end)
end

function UISelfieOneClickView:StartPreview()
    if DataModel.tCamAniData and not table.is_empty(DataModel.tCamAniData) then
        local dwPlayer = UI_GetClientPlayerID()
        local nStayCharacterID = dwPlayer
        local nPlotCharacterID = dwPlayer
        Scene_PlayReferenceCameraAni(DataModel.tCamAniData, nStayCharacterID, nPlotCharacterID)
    end

    local dwActionID = DataModel.dwActionID
    if dwActionID then
        if dwActionID > 0 then
            EmotionData.ProcessEmotionAction(dwActionID, nil, true)
        elseif DataModel.szAIActionPath then
            AiBodyMotionData.ProcessAIAction(DataModel.szAIActionPath, true)
        end
    end

    local dwFaceEmotionID = DataModel.dwFaceEmotionID
    if dwFaceEmotionID then
        if dwFaceEmotionID > 0 then
            AiBodyMotionData.ProcessFaceMotion(dwFaceEmotionID)
        elseif DataModel.szAIFacePath then
            AiBodyMotionData.ProcessFaceMotion(DataModel.szAIFacePath)
        end
    end

    local tBgmParam = DataModel.tBgmParam
    if tBgmParam then
        SelfieMusicData.PlayBgMusicWithPos(DataModel.tBgmParam.nBgmID, DataModel.tBgmParam.nStartTime, true)
    end
    UIHelper.SetButtonState(self.BtnCompleteFilm, BTN_STATE.Disable, nil, true)
    UIHelper.SetButtonState(self.BtnPreview, BTN_STATE.Disable, nil, true)
end

function UISelfieOneClickView:StopPreview()
    if DataModel.tCamAniData and not table.is_empty(DataModel.tCamAniData) then
        Scene_StopReferenceCameraAni()
    end

    local dwActionID = DataModel.dwActionID
    if dwActionID then
        if dwActionID > 0 then
            EmotionData.StopCurrentEmotionAction(dwActionID)
        elseif DataModel.szAIActionPath then
            AiBodyMotionData.StopAIAction()
        end
    end

    local dwFaceEmotionID = DataModel.dwFaceEmotionID
    if dwFaceEmotionID then
        if DataModel.szAIFacePath then
            AiBodyMotionData.StopFaceMotion()
        end
    end
    local tBgmParam = DataModel.tBgmParam
    if tBgmParam then
        SelfieMusicData.OnStopBgMusic(true)
    end
    self:UpdatePreviewAndRecordState()
end

function UISelfieOneClickView:StartRecording()
    Timer.DelTimer(self, self.nPrepareTimerID)
    self.bIsStartRecording = true
    if self.script_record then
        local nPrepareTotalTime = m_fPrepareTotalTime/1000 + 1
        self.script_record:RecordFilm(nPrepareTotalTime)
    else
        self:EndRecording(true)
    end
end

function UISelfieOneClickView:EndRecording(bStopIllusionVideo, bCloseRecordView)
    self.bIsStartRecording = false
    m_bWaitPrepareFlag = nil
    m_bResourceLoaded = nil
    m_fPrepareTotalTime = nil
    DataModel.tVideoPrams = nil
    if bStopIllusionVideo then
        Scene_StopIllusionVideo()
        EmotionData.ForceStopCurAction()
    end
    Timer.DelTimer(self, self.nPrepareTimerID)
    self:UpdatePreviewAndRecordState()
    if bCloseRecordView then
        if self.script_record then
            self.script_record:OnCloseHandle()
        end
    end
end

return UISelfieOneClickView