-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UISelfieAIGeneratedView
-- Date:
-- Desc:
-- ---------------------------------------------------------------------------------
local UISelfieAIGeneratedView = class("UISelfieAIGeneratedView")
local MAX_UPLOAD_FILE_SIZE = 10 * 1024 * 1024
local MAX_UPLOAD_VIDEO_TIME = 30
local MAX_AI_ACT_NAME_LENGTH = 4
local DataModel = {}
local function DataModel_Init()
    DataModel.nAIDataType = AI_DATA_TYPE.VIDEO
    DataModel.nAIRemainTimes = 0
    DataModel.bWaitPhotoUploadCheck = false

    DataModel.nBodyMotionType = 1
    DataModel.nCustomMotionType = AI_MOTION_TYPE.BODY
    DataModel.nSelMotionID = nil
    DataModel.nSelCustomMotionID = nil
end
local function DataModel_UnInit()
    for k, v in pairs(DataModel) do
        if type(v) ~= "function" then
            DataModel[k] = nil
        end
    end
end

-- 构建视频文件过滤器字符串
local function BuildVideoFilter(extList)
    local parts = {}

    -- 组合描述行: "(*.mp4;*.mkv;...)"
    local desc = " ("
    for i, ext in ipairs(extList) do
        if i > 1 then desc = desc .. ";" end
        desc = desc .. "*." .. ext
    end
    desc = desc .. ")"

    -- 组合匹配模式行: "*.mp4;*.mkv;..."
    local pattern = ""
    for i, ext in ipairs(extList) do
        if i > 1 then pattern = pattern .. ";" end
        pattern = pattern .. "*." .. ext
    end

    -- 所有文件选项
    local allDesc = "All Files (*.*)"
    local allPattern = "*.*"

    -- 用 \000 作为 NULL 分隔符，最后双 \000 结尾
    local filter = desc .. "\000" .. pattern .. "\000"
                 .. allDesc .. "\000" .. allPattern .. "\000\000"

    return filter
end



function UISelfieAIGeneratedView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    DataModel_Init()
    self:UpdateInfo()

    UIHelper.SetScrollViewCombinedBatchEnabled(self.ScrollViewModule, false)
end

function UISelfieAIGeneratedView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    DataModel_UnInit()
    if self.checkVideoPlay then
        UIHelper.StopVideo(self.checkVideoPlay.WidgetVideo)
    end
end

function UISelfieAIGeneratedView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnImport, EventType.OnClick, function ()
        self:ImportAISourceData()
    end)

    UIHelper.BindUIEvent(self.BtnResetConfirm, EventType.OnClick, function ()
        local nAIStage = AiBodyMotionData.GetStage()
        if nAIStage == AI_ACT_STAGE.UPLOADED then
            AiBodyMotionData.DeleteData()
            AiBodyMotionData.BackStep()
        else
            AiBodyMotionData.Reset()
        end
        self:UpdateAIStage()
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function ()
        AiBodyMotionData.BackStep()
        self:UpdateAIStage()
    end)

    UIHelper.BindUIEvent(self.BtnGenerate, EventType.OnClick, function ()
        self:GenerateAIAction()
    end)

    UIHelper.BindUIEvent(self.BtnSave, EventType.OnClick, function ()
        self:OnSaveAIAction()
    end)

    UIHelper.BindUIEvent(self.BtnApply, EventType.OnClick, function ()
        self:OnApplyAIAction()
    end)

    UIHelper.BindUIEvent(self.BtnReset, EventType.OnClick, function ()
        AiBodyMotionData.Reset()
        self:UpdateAIStage()
    end)
end

function UISelfieAIGeneratedView:RegEvent()
    Event.Reg(self, EventType.OnSelfieUpdateAIUploadRemainCount, function (nRemainTimes)
        LOG.INFO("[UISelfieAIGeneratedView] AIUploadRemainCount,:%d",nRemainTimes)
        self:UpdateAIUploadRemainCount(nRemainTimes)
    end)
    Event.Reg(self, "ON_MEDIA_PICKER_RESULT", function (eResultCode, eMediaType, szFilePath, szMimeType, szUri)
        LOG.INFO("[UISelfieAIGeneratedView] ON_MEDIA_PICKER_RESULT:%s,%s,%s,%s,%s",tostring(eResultCode), tostring(eMediaType), tostring(szFilePath), tostring(szMimeType), tostring(szUri))
        self:CheckImportAIVideoFile(szFilePath)
    end)
    Event.Reg(self, "ON_ONE_CLICK_AI_STAGE_CHANGED", function ()
        self:UpdateAIStage()
    end)
end

function UISelfieAIGeneratedView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UISelfieAIGeneratedView:Open()
    self:UpdateAIStage()
    UIHelper.SetVisible(self._rootNode, true)
end

function UISelfieAIGeneratedView:Hide()
    UIHelper.SetVisible(self._rootNode, false)
end

function UISelfieAIGeneratedView:UpdateInfo()
    self:UpdateAIStage()
    UIHelper.SetSelected(self.Tog_Face, true)
    UIHelper.SetSelected(self.Tog_Ani, true)
    RemoteCallToServer("On_AIMocap_GetRemainTimes")
end

function UISelfieAIGeneratedView:UpdateAIStage()
    local nAIStage = AiBodyMotionData.GetStage()
    LOG.INFO("UpdateAIStage  %d",nAIStage)
    if Platform.IsMobile() then
        if self.szMediaPickerPath and nAIStage == AI_ACT_STAGE.UPLOADED then
            cc.FileUtils:getInstance():removeFile(self.szMediaPickerPath)
            self.szMediaPickerPath = nil
        end
    end
    
    if nAIStage == AI_ACT_STAGE.PROCESSING or nAIStage == AI_ACT_STAGE.PROCESSING_FAILED or nAIStage == AI_ACT_STAGE.FINISHED then
        UIHelper.SetVisible(self.WidgetAIGenerating, nAIStage == AI_ACT_STAGE.PROCESSING or nAIStage == AI_ACT_STAGE.FINISHED)
        UIHelper.SetVisible(self.WidgetAIGeneratingF, nAIStage == AI_ACT_STAGE.PROCESSING_FAILED)
        UIHelper.SetVisible(self.LayoutAIList, nAIStage == AI_ACT_STAGE.FINISHED)
        UIHelper.SetVisible(self.LayoutImport, false)
        UIHelper.SetVisible(self.LayoutGenerated, true)
        UIHelper.LayoutDoLayout(self.LayoutGenerated)
        UIHelper.SetVisible(self.LabelWaitTime,  nAIStage == AI_ACT_STAGE.PROCESSING)
        if nAIStage == AI_ACT_STAGE.FINISHED then
            self:SetAIActionList()
            UIHelper.SetString(self.LabelGeneratingDes, "生成成功!")
        elseif nAIStage == AI_ACT_STAGE.PROCESSING then
            UIHelper.SetString(self.LabelGeneratingDes, "努力生成中...")
            self:UpdateAIGeneratingWaitInfo()
        end
        UIHelper.SetVisible(self.BtnReset, nAIStage == AI_ACT_STAGE.FINISHED)
    else
        UIHelper.SetVisible(self.WidgetContentImport, nAIStage == AI_ACT_STAGE.BEGIN)
        UIHelper.SetVisible(self.WidgetContentImportF, nAIStage == AI_ACT_STAGE.UPLOAD_FAILED)
        UIHelper.SetVisible(self.WidgetContentUploading, nAIStage == AI_ACT_STAGE.UPLOADING)
        UIHelper.SetVisible(self.WidgetContentUploaded, nAIStage == AI_ACT_STAGE.UPLOADED)            
        UIHelper.SetVisible(self.LayoutImport, true)
        UIHelper.SetVisible(self.LayoutGenerated, false)
        UIHelper.LayoutDoLayout(self.LayoutImport)
    end
    if nAIStage ~= AI_ACT_STAGE.PROCESSING then
        AiBodyMotionData.SetAIGenerateStartTick(nil)
    end
    self:UpdateAIBtnState()
end

function UISelfieAIGeneratedView:SetAIActionList()
    local bShowBody, bShowFace = AiBodyMotionData.GetGenerateOption()
    UIHelper.RemoveAllChildren(self.LayoutAIList)
    self.bSelectGC_BODY = true
    self.bSelectGC_FACE = true
    local _onSelectedFun = function(motionType, bSelected)
        if motionType == AI_MOTION_TYPE.BODY then
            self.bSelectGC_BODY = bSelected
        elseif motionType == AI_MOTION_TYPE.FACE then
            self.bSelectGC_FACE = bSelected
        end

    end

    local _onPlayFun = function(motionType)
        if motionType == AI_MOTION_TYPE.BODY then
            self:PlayAIBodyMotion()
        elseif motionType == AI_MOTION_TYPE.FACE then
            self:PlayAIFaceMotion()
        end
    end
    if bShowBody then
        UIHelper.AddPrefab(PREFAB_ID.WidgetCameraAIGeneratedModule, self.LayoutAIList, AI_MOTION_TYPE.BODY,_onSelectedFun, _onPlayFun)
    end
    if bShowFace then
        UIHelper.AddPrefab(PREFAB_ID.WidgetCameraAIGeneratedModule, self.LayoutAIList, AI_MOTION_TYPE.FACE,_onSelectedFun, _onPlayFun)
    end
    UIHelper.LayoutDoLayout(self.LayoutAIList)
end

function UISelfieAIGeneratedView:PlayAIBodyMotion()
    local szAniFile = AiBodyMotionData.GetBodyAniFile()
    if not szAniFile then
        LOG.ERROR("Selfie PlayAIBodyMotion Failed! szAniFile is nil")
        return
    end
    AiBodyMotionData.ProcessAIAction(szAniFile, false)
    --FireUIEvent("ON_ONE_CLICK_CHOOSE_BODY_ACTION", true, szAniFile, self.szCustomBodyName)
end

function UISelfieAIGeneratedView:PlayAIFaceMotion()
    local szAniFile = AiBodyMotionData.GetFaceAniFile()
    if not szAniFile then
        LOG.ERROR("Selfie PlayAIFaceMotion Failed! szAniFile is nil")
        return
    end
    AiBodyMotionData.ProcessFaceMotion(szAniFile)
    --FireUIEvent("ON_ONE_CLICK_CHOOSE_FACE_ACTION", true, szAniFile, self.szCustomFaceName)
end

function UISelfieAIGeneratedView:UpdateAIBtnState()
    local nAIStage = AiBodyMotionData.GetStage()
    UIHelper.SetVisible(self.BtnGenerate, nAIStage == AI_ACT_STAGE.UPLOADED)
    UIHelper.SetVisible(self.BtnCancel, nAIStage == AI_ACT_STAGE.PROCESSING)
    UIHelper.SetVisible(self.BtnResetConfirm, nAIStage == AI_ACT_STAGE.UPLOADED or nAIStage == AI_ACT_STAGE.UPLOAD_FAILED or nAIStage == AI_ACT_STAGE.PROCESSING_FAILED)
    UIHelper.SetVisible(self.BtnSave, nAIStage == AI_ACT_STAGE.FINISHED)
    UIHelper.SetVisible(self.BtnApply, nAIStage == AI_ACT_STAGE.FINISHED)
    

    UIHelper.LayoutDoLayout(self.LayoutBtnList)
    self.bAIImportDisable = nAIStage ~= AI_ACT_STAGE.BEGIN or not AiBodyMotionData.IsMaxLevel()
end

function UISelfieAIGeneratedView:ImportAISourceData()
    if self.bAIImportDisable then
        return
    end

    if not AiBodyMotionData.IsMaxLevel() then
        return
    end

	if not AiBodyMotionData.CheckAgreeStatement() then
    	return
    end

    if DataModel.nAIRemainTimes <= 0 then
        local szCountMsg = g_tStrings.STR_SELFIE_AI_UPLOAD_COUNT_NOT_ENOUGH
        OutputMessage("MSG_SYS", szCountMsg)
        OutputMessage("MSG_ANNOUNCE_RED", szCountMsg)
        return
    end

    local nAIDataType = DataModel.nAIDataType
    local szMsg = ""
    if nAIDataType == AI_DATA_TYPE.VIDEO then
        szMsg = g_tStrings.STR_SELFIE_AI_CHOOSE_VIDEO_FILE
    elseif nAIDataType == AI_DATA_TYPE.IMAGE then
        szMsg = g_tStrings.STR_SELFIE_AI_CHOOSE_IMAGE_FILE
    end
    if Platform.IsWindows() then
        local folder = GetStreamAdaptiveDirPath(UIHelper.GBKToUTF8(GetFullPath("dcim/")))
        CPath.MakeDir(folder)
        -- 使用
        local videoExts = {"mp4", "mkv", "avi", "flv", "mov", "m4v", "ts", "wmv", "webm"}
        local szFilter = BuildVideoFilter(videoExts)
        local szFile = GetOpenFileName(szMsg, szFilter, folder)
        self:CheckImportAIVideoFile(szFile)
    else
        OpenMediaPicker(nAIDataType == AI_DATA_TYPE.VIDEO and MediaPickerType.Video or MediaPickerType.Image)
    end
end

function UISelfieAIGeneratedView:UpdateAIUploadRemainCount(nRemainTimes)
    DataModel.nAIRemainTimes = nRemainTimes
    UIHelper.SetString(self.LabelContentNum, string.format("%d次",nRemainTimes))
    self:UpdateAILevelLimitState()
end
function UISelfieAIGeneratedView:UpdateAILevelLimitState()
    local pPlayer = GetClientPlayer()
    local nCurLevel = pPlayer and pPlayer.nLevel or 0
    local nMaxLevel = GetMaxPlayerLevel() or 0
    local bMaxLevelReached = nCurLevel >= nMaxLevel
   -- UIHelper.SetString(self.LabelContentNum, string.format(g_tStrings.STR_SELFIE_AI_LEVEL_NOT_ACHIEVED, nMaxLevel))
end

function UISelfieAIGeneratedView:CheckImportAIVideoFile(szFile)
	if szFile == "" then
		return
	end
    local tLegalFormat = {"mp4", "mkv", "avi", "flv", "mov", "m4v", "ts", "wmv", "webm"}
    local szSuffix = string.lower(string.match(szFile, "%.([^%.]+)$") or "")
    if not table.contain_value(tLegalFormat, szSuffix) then
        OutputMessage("MSG_SYS", g_tStrings.STR_SELFIE_AI_CHOOSE_FILE_ILLEGAL)
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_SELFIE_AI_CHOOSE_FILE_ILLEGAL)
        return
    end
    self.szMediaPickerPath = szFile

    self.checkVideoPlay = UIHelper.AddPrefab(PREFAB_ID.WidgetNewVideo, self.videocontainer)
    if self.checkVideoPlay then
        self.checkVideoPlay.WidgetVideo:addEventListener(function (_, nEvent , msg)
            if nEvent == 0 then     -- playing
                local strSplit = string.split(msg , "|")
                local byteSize = tonumber(strSplit[1])
                local videoTime = self.checkVideoPlay.WidgetVideo:getVideoDuration()
                self:TryUploadData(byteSize,videoTime)
                Timer.Add(self , 0.2 , function ()
                    UIHelper.StopVideo(self.checkVideoPlay.WidgetVideo)
                end)
            elseif nEvent == 2 or nEvent == 3 then
                Timer.Add(self , 0.2 , function ()
                    self.checkVideoPlay = nil
                    UIHelper.RemoveAllChildren(self.videocontainer)
                end)
            end
        end)
    end
    UIHelper.PlayVideo(self.checkVideoPlay.WidgetVideo, UIHelper.GBKToUTF8(szFile), false, nil,nil,0, true)
end

function UISelfieAIGeneratedView:TryUploadData(byteSize,videoTime)
    if byteSize > MAX_UPLOAD_FILE_SIZE then
        OutputMessage("MSG_SYS", g_tStrings.STR_SELFIE_AI_UPLOAD_FILE_TOO_BIG)
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_SELFIE_AI_UPLOAD_FILE_TOO_BIG)
        return
    end
    if videoTime > MAX_UPLOAD_VIDEO_TIME then
        OutputMessage("MSG_SYS", g_tStrings.STR_SELFIE_AI_UPLOAD_VIDEO_TOO_LONG)
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_SELFIE_AI_UPLOAD_VIDEO_TOO_LONG)
        return
    end

    LOG.INFO("[UISelfieAIGeneratedView] TryUploadData:%d,%d",byteSize,videoTime)
    AiBodyMotionData.UploadData(self.szMediaPickerPath)
end


function UISelfieAIGeneratedView:GenerateAIAction()
    local bFace = UIHelper.GetSelected(self.Tog_Face)
    local bBody = UIHelper.GetSelected(self.Tog_Ani)

    if not bFace and not bBody then
        TipsHelper.ShowNormalTip("请勾选需要生成的内容")
        return 
    end
    AiBodyMotionData.SetAIGenerateStartTick(GetCurrentTime())
    AiBodyMotionData.NextStep()
    AiBodyMotionData.ProcessData(bBody, bFace)
end

function UISelfieAIGeneratedView:OnApplyAIAction()
    local szBodyAniFile = self.bSelectGC_BODY and AiBodyMotionData.GetBodyAniFile() or nil
    if szBodyAniFile then
        AiBodyMotionData.ProcessAIAction(szBodyAniFile, false)
    end
    Event.Dispatch("ON_ONE_CLICK_CHOOSE_BODY_ACTION", true, szBodyAniFile)

    local szFaceAniFile = self.bSelectGC_FACE and AiBodyMotionData.GetFaceAniFile() or nil
    if szFaceAniFile then
        AiBodyMotionData.ProcessFaceMotion(szFaceAniFile)
    end
    Event.Dispatch("ON_ONE_CLICK_CHOOSE_FACE_ACTION", true, szFaceAniFile)
end

function UISelfieAIGeneratedView:OnSaveAIAction()
    local tSaveType = {}
    local szBodyAniFile = self.bSelectGC_BODY and AiBodyMotionData.GetBodyAniFile() or nil
    if szBodyAniFile then
        table.insert(tSaveType, AI_MOTION_TYPE.BODY)
    end
    local szFaceAniFile = self.bSelectGC_FACE and AiBodyMotionData.GetFaceAniFile() or nil
    if szFaceAniFile then
        table.insert(tSaveType, AI_MOTION_TYPE.FACE)
    end

    if #tSaveType > 0 then
        UIMgr.Open(VIEW_ID.PanelDongBuFolder, tSaveType)
    end 
end

function UISelfieAIGeneratedView:UpdateAIGeneratingWaitInfo()
    Timer.DelTimer(self, self.nWaitGeneratingTimerID)
    if not self:UpdateWaitTime() then
        return
    end
    self.nWaitGeneratingTimerID = Timer.AddCycle(self, 1, function ()
        if not self:UpdateWaitTime() then
            Timer.DelTimer(self, self.nWaitGeneratingTimerID)
        end
    end)
end

function UISelfieAIGeneratedView:UpdateWaitTime()
    local nEnqueuedPos = AiBodyMotionData.GetEnqueuedPosition()
    local bShowWaitTime = nEnqueuedPos > 0
    if not bShowWaitTime then
        UIHelper.SetString(self.LabelWaitTime,"")
        return false
    end
    local nTick = AiBodyMotionData.GetAIGenerateStartTick()
    local nAvgWaitSec = nEnqueuedPos * 45
    local nStartTick = nTick or GetCurrentTime()
    local nPassSec = math.max(GetCurrentTime() - nStartTick, 0)
    UIHelper.SetString(self.LabelWaitTime,string.format("%s%s\n%s%s", g_tStrings.STR_SELFIE_AI_QUEUE_AVGTIME, AiBodyMotionData.FormatArenaTime(nAvgWaitSec), g_tStrings.STR_SELFIE_AI_QUEUE_PASSTIME, AiBodyMotionData.FormatArenaTime(nPassSec)))
    return true
end

return UISelfieAIGeneratedView