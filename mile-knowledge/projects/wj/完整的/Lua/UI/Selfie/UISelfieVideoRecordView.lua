-- ---------------------------------------------------------------------------------
-- Author:
-- Name: UISelfieVideoRecordView
-- Date: 2026-04-16
-- Desc: 录像界面
-- ---------------------------------------------------------------------------------

local UISelfieVideoRecordView = class("UISelfieVideoRecordView")
local nVideoMaxTime = 60
local INTERACTION_STATE =
{
    None = 1,
    Camera = 2,
    Video = 3,
    VideoTime = 4,
}
local tbGSRSnapShotGPUModel = {
    ["Apple A9X GPU"] = true,
}
function UISelfieVideoRecordView:OnEnter(nType, tVideoParams, fnReady, fnClose, fnPlay, fnReset)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tVideoParams = tVideoParams
    self.fnReady = fnReady
    self.fnClose = fnClose
    self.fnPlay = fnPlay 
    self.fnReset = fnReset 
    self.nType = nType
end

function UISelfieVideoRecordView:RegEvent()
    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        if nViewID == VIEW_ID.PanelCameraVideoShare then
           self:OnCloseHandle()
        end
    end)
end

function UISelfieVideoRecordView:UnRegEvent()
    
end

function UISelfieVideoRecordView:BindUIEvent()

    UIHelper.BindUIEvent(self.BtnLuxiang_L, EventType.OnClick, function()
        self:OnVideoDown()
    end)

    UIHelper.BindUIEvent(self.BtnStopLuxiang, EventType.OnClick, function()
        if self.bCanClickLuaXiang then
            self:OnEndVideo()
        else
            TipsHelper.ShowNormalTip("录制最少1秒")
        end
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        if self.fnClose then
            self.fnClose()
        end
        UIMgr.Close(self)
    end)
end

function UISelfieVideoRecordView:OnExit()
    self:StopRecordScreen()
    if self.eInteractionState == INTERACTION_STATE.VideoTime then
        cc.FileUtils:getInstance():removeFile(UIHelper.UTF8ToGBK(self.tVideoParams.szRecordScreenFilePath..self.tVideoParams.szFileName))
    end
    if self.fnClose then
        self.fnClose()
    end
end

function UISelfieVideoRecordView:OnCloseHandle()
    UIMgr.Close(self)
end


function UISelfieVideoRecordView:UpdateInfo()
    self:SetTitleVisible(self.nType ~= SELFIE_VIDEO_RECORD_TYPE.PREVIEW and self.nType ~= SELFIE_VIDEO_RECORD_TYPE.FILM)
    self:SetLayoutBtnVisible(self.nType ~= SELFIE_VIDEO_RECORD_TYPE.PREVIEW and self.nType ~= SELFIE_VIDEO_RECORD_TYPE.FILM)
    UIHelper.SetVisible(self.WidgetNormalProgress,  self.nType == SELFIE_VIDEO_RECORD_TYPE.FILM)
    UIHelper.SetVisible(self.WigetCameraChange,  self.nType ~= SELFIE_VIDEO_RECORD_TYPE.FILM)
    UIHelper.SetVisible(self.WidgetLuXiangTime,  false)
    if self.fnReady then
        self.fnReady()
    end
end

function UISelfieVideoRecordView:SetTitleVisible(bVisible)
    UIHelper.SetVisible(self.WidgetAniTitle, bVisible)
end

function UISelfieVideoRecordView:SetLayoutBtnVisible(bVisible)
    UIHelper.SetVisible(self.LayoutBtn, bVisible)
end

function UISelfieVideoRecordView:SetProgress(nProgress)
    UIHelper.SetProgressBarPercent(self.SliderNormalProgress, nProgress)
end

function UISelfieVideoRecordView:RecordFilm(nPrepareTotalTime)
    UIHelper.SetVisible(self.BtnClose,  false)
    UIHelper.SetProgressBarPercent(self.SliderNormalProgress, 0)
    self:SwitchQulity(function ()
        self:StartRecordScreen()
    end,QualityMgr.tbCurQuality.nResolutionLevel)
    Timer.AddCountDown(self, nPrepareTotalTime, function (nRemain)
        UIHelper.SetProgressBarPercent(self.SliderNormalProgress,(1 - nRemain/nPrepareTotalTime) * 100)
    end, function ()
        UIHelper.SetVisible(self.BtnClose,  true)
        self:OnEndVideo()
        
    end)
end

function UISelfieVideoRecordView:OnVideoDown()
    local onExcute = function()
        self.eInteractionState = INTERACTION_STATE.VideoTime
        self:UpdateInterationState()
        UIHelper.SetProgressBarPercent(self.ImgSliderExperience , 0)
        UIHelper.SetString(self.labelLuXiangTime,Timer.Format2Minute(0))
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

function UISelfieVideoRecordView:IsCardCropp4K()
    local tSize = GetFrameSize()
    local nWidth = tSize.width
    local nHeight = tSize.height
    return nWidth >= 3840
end

function UISelfieVideoRecordView:SwitchQulity(fnExContent, nLevel)
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

function UISelfieVideoRecordView:ResetQulity()
    if self.nCurResolutionLevel then
        KG3DEngine.SetMobileEngineOption({nResolutionLevel = self.nCurResolutionLevel , bEnableFSR = self.bCurEnableFSR, bEnableGSR= self.bCurEnableGSR, bEnableGSR2= self.bCurEnableGSR2, bEnableGSR2Performance= self.bCurEnableGSR2Performance, bEnablePointLightingCharacter = true})
        self.nCurResolutionLevel = nil
    end
end

function UISelfieVideoRecordView:UpdateInterationState()
    UIHelper.SetVisible(self.BtnLuxiang_L, self.eInteractionState == INTERACTION_STATE.Video)
    UIHelper.SetVisible(self.BtnStopLuxiang, self.eInteractionState == INTERACTION_STATE.VideoTime)
    UIHelper.SetVisible(self.ProgressCameraTime, self.eInteractionState == INTERACTION_STATE.VideoTime)
    UIHelper.SetVisible(self.WidgetLuXiangTime,  self.eInteractionState == INTERACTION_STATE.VideoTime)
end

function UISelfieVideoRecordView:OnStartVideo()
    self.bCanClickLuaXiang = false
    Timer.Add(self, 1 , function ()
        self.bCanClickLuaXiang = true
    end)
    self:StartRecordScreen()
    self.nVideoTimerID = Timer.AddCountDown(self, nVideoMaxTime, function (nRemain)
        UIHelper.SetString(self.labelLuXiangTime,Timer.Format2Minute(nVideoMaxTime - nRemain))
        UIHelper.SetProgressBarPercent(self.ImgSliderExperience , math.min(100 - nRemain/nVideoMaxTime*100, 100))
    end)
end

function UISelfieVideoRecordView:StartRecordScreen()
    self:StopRecordScreen()
    if not self.bStartRecordScreen then
        cc.utils:takeRecordScreen(self.tVideoParams.szFolder..self.tVideoParams.szFileName , self.tVideoParams.nFps, false, false, false, self.tVideoParams.bUseAILogo, self.tVideoParams.bAddAIMetaData)
        self.bStartRecordScreen = true
    end
end

function UISelfieVideoRecordView:OnEndVideo()
    self.eInteractionState = INTERACTION_STATE.Video
    Timer.DelTimer(self, self.nVideoTestTimerID)
    Timer.DelTimer(self, self.nVideoTimerID)
    self:ResetQulity()
    if not self.WidgetLoading then
        --self.WidgetLoading = UIHelper.FindChildByName(self.WidgetAnchorMiddle, "WidgetLoading")
    end
    UIHelper.SetVisible(self.WidgetLoading, true)
    Timer.AddFrame(self,1,function ()
        self:StopRecordScreen()
        UIHelper.SetVisible(self.WidgetNormalProgress,  false)
        UIMgr.Open(VIEW_ID.PanelCameraVideoShare, self.tVideoParams.szRecordScreenFilePath, self.tVideoParams.szFileName, function ()
        end)
    end)
end

function UISelfieVideoRecordView:StopRecordScreen()
    if self.bStartRecordScreen then
        cc.utils:stopRecordScreen()
    end
    self.bStartRecordScreen = false
end

return UISelfieVideoRecordView
