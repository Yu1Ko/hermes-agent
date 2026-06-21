-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UISelfieMusicCutSetView
-- Date: 
-- Desc: 
-- ---------------------------------------------------------------------------------
local UISelfieMusicCutSetView = class("UISelfieMusicCutSetView")
local MoveTargetType = 
{
    Dot = 1,
    Start = 2,
    End = 3
}
local BGM_MICRO_STEP_MS = 100
local DataModel = {}
function UISelfieMusicCutSetView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UISelfieMusicCutSetView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISelfieMusicCutSetView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnEmpty, EventType.OnClick, function()
        self:TryClose()
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        self:TryClose()
    end)

    UIHelper.BindUIEvent(self.BtnApply, EventType.OnClick, function()
        Event.Dispatch("ON_ONE_CLICK_CHOOSE_BGM", DataModel.nSelBGMID, DataModel.nCutStartTime, DataModel.nCutEndTime, DataModel.nTagType == SELFIE_CAMERA_RIGHT_TAG.CUSTOM)
    end)

    UIHelper.BindUIEvent(self.BtnSave, EventType.OnClick, function()
        if SelfieMusicData.IsCanSaveCustom() then
            UIMgr.Open(VIEW_ID.PanelCameraBgmSavePop, DataModel.nSelBGMID, DataModel.nCutStartTime, DataModel.nCutEndTime, function ()
                self.bHasEdit = false
                TipsHelper.ShowNormalTip("保存成功")
                Event.Dispatch( EventType.OnSelfieCameraBGMCustomSaved)
               
            end)
        else
            TipsHelper.ShowNormalTip(g_tStrings.STR_SELFIE_BGM_CUSTOM_COUNT_LIMIT)
        end
    end)

    UIHelper.BindUIEvent(self.BtnPlayPause, EventType.OnClick, function()
        if DataModel.nPlayState == BGM_PLAY_STATUS.PLAYING then
            DataModel.nPlayState = BGM_PLAY_STATUS.STOP
            SelfieMusicData.OnStopBgMusic()
        else
            DataModel.nPlayState = BGM_PLAY_STATUS.PLAYING
            SelfieMusicData.PlayBgMusicWithPos(self:GetRealyBgmID(), DataModel.nBgmCurTime)
            --SelfieMusicData.OnRePlayBGM(DataModel.nBgmCurTime, DataModel.nCutEndTime)
        end
        self:UpdateBtnPlayBGMState()
    end)

    UIHelper.BindUIEvent(self.BtnLeft_Start, EventType.OnClick, function()
        self.bHasEdit = true
        self:UpdateClipMicroNudge(true, -BGM_MICRO_STEP_MS)
    end)

    UIHelper.BindUIEvent(self.BtnRight_Start, EventType.OnClick, function()
        self.bHasEdit = true
        self:UpdateClipMicroNudge(true, BGM_MICRO_STEP_MS)
    end)

    UIHelper.BindUIEvent(self.BtnLeft_End, EventType.OnClick, function()
        self.bHasEdit = true
        self:UpdateClipMicroNudge(false, -BGM_MICRO_STEP_MS)
    end)

    UIHelper.BindUIEvent(self.BtnRight_End, EventType.OnClick, function()
        self.bHasEdit = true
        self:UpdateClipMicroNudge(false, BGM_MICRO_STEP_MS)
    end)

    self.EditPaginate_Start:registerScriptEditBoxHandler(function(szType, _editbox)
        if szType == "ended" or szType == "return" then
            self:CheckCutEditor(true)
            self.bHasEdit = true
        end
    end)

    self.EditPaginate_End:registerScriptEditBoxHandler(function(szType, _editbox)
        if szType == "ended" or szType == "return" then
            self:CheckCutEditor(false)
            self.bHasEdit = true
        end
    end)

    UIHelper.BindUIEvent(self.BtnCutLeft, EventType.OnTouchBegan, function(btn, nX, nY)
        self.bHasEdit = true
        self:UpdateDragItemStart(self.BtnCutLeft, MoveTargetType.Start)
    end)

    UIHelper.BindUIEvent(self.BtnCutRight, EventType.OnTouchBegan, function(btn, nX, nY)
        self.bHasEdit = true
        self:UpdateDragItemStart(self.BtnCutRight, MoveTargetType.End)
    end)

    UIHelper.BindUIEvent(self.BtnPlayLIne, EventType.OnTouchBegan, function(btn, nX, nY)
        self:UpdateDragItemStart(self.BtnPlayLIne, MoveTargetType.Dot)
    end)

    UIHelper.BindUIEvent(self.BtnCutLeft, EventType.OnTouchMoved, function(btn, nX, nY)
        self:UpdateDragItemMove(self.BtnCutLeft ,nX, nY)
        self:UpdateCutImageSize()
    end)

    UIHelper.BindUIEvent(self.BtnCutRight, EventType.OnTouchMoved, function(btn, nX, nY)
        self:UpdateDragItemMove(self.BtnCutRight ,nX, nY)
        self:UpdateCutImageSize()
    end)

    UIHelper.BindUIEvent(self.BtnPlayLIne, EventType.OnTouchMoved, function(btn, nX, nY)
        self:UpdateDragItemMove(self.BtnPlayLIne ,nX, nY)
    end)

    UIHelper.BindUIEvent(self.BtnCutLeft, EventType.OnTouchEnded, function(btn, nX, nY)
       self:UpdateDragItemEnd(self.BtnCutLeft, MoveTargetType.Start)
    end)

    UIHelper.BindUIEvent(self.BtnCutRight, EventType.OnTouchEnded, function(btn, nX, nY)
        self:UpdateDragItemEnd(self.BtnCutRight, MoveTargetType.End)
    end)

    UIHelper.BindUIEvent(self.BtnPlayLIne, EventType.OnTouchEnded, function(btn, nX, nY)
        self:UpdateDragItemEnd(self.BtnPlayLIne, MoveTargetType.Dot)
    end)


    UIHelper.BindUIEvent(self.BtnCutLeft, EventType.OnTouchCanceled, function(btn, nX, nY)
        self:UpdateDragItemEnd(self.BtnCutLeft, MoveTargetType.Start)
     end)
 
     UIHelper.BindUIEvent(self.BtnCutRight, EventType.OnTouchCanceled, function(btn, nX, nY)
         self:UpdateDragItemEnd(self.BtnCutRight, MoveTargetType.End)
     end)
 
     UIHelper.BindUIEvent(self.BtnPlayLIne, EventType.OnTouchCanceled, function(btn, nX, nY)
         self:UpdateDragItemEnd(self.BtnPlayLIne, MoveTargetType.Dot)
     end)

end

function UISelfieMusicCutSetView:RegEvent()

end

function UISelfieMusicCutSetView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UISelfieMusicCutSetView:TryClose()

    local onClose = function ()
        DataModel.nBgmStartTime = 0
        DataModel.nBgmEndTime = DataModel.nTotalBgmTime

        DataModel.nPlayStartTime = 0
        DataModel.nPlayEndTime = DataModel.nTotalBgmTime
        DataModel.nPlayTotalBgmTime = DataModel.nTotalBgmTime

        SelfieMusicData.SetProgressCallback(nil)
        SelfieMusicData.SetPlayStopCallback(nil)
        UIMgr.Close(self)
        Event.Dispatch(EventType.OnSelfieCameraBGMEditor, false)
    end

    if self.bHasEdit then
        UIHelper.ShowConfirm("尚未保存剪裁内容，退出后会重置，是否确认退出", function()
            onClose()
        end)
    else
        onClose()
    end
end

function UISelfieMusicCutSetView:UpdateDragItemMove(gItem ,nX, nY)
    local nCursorX, nCursorY = UIHelper.ConvertToNodeSpace(self.WidgetCutArea, nX, nY)
    if nCursorX <= self.nClipLen and nCursorX>= -self.nClipLen then
        UIHelper.SetPositionX(gItem, nCursorX)
    end
end

function UISelfieMusicCutSetView:UpdateDragItemStart(gItem, eMoveTargetType)
    self.bPauseUpdateTimePos = true
end

function UISelfieMusicCutSetView:UpdateDragItemEnd(gItem, eMoveTargetType)
    local nCursorX =  UIHelper.GetPositionX(gItem)
    if nCursorX <= self.nClipLen and nCursorX>= -self.nClipLen then
        local nProgress = (nCursorX + self.nClipLen) / (self.nClipLen * 2)
        if  eMoveTargetType == MoveTargetType.Dot then
            self:UpdatePlayTime(nProgress)
        elseif eMoveTargetType == MoveTargetType.Start then
            self:OnDragClipCutHandle(nProgress, true)
        elseif eMoveTargetType == MoveTargetType.End then
            self:OnDragClipCutHandle(nProgress, false)
        end
    end
    self.bPauseUpdateTimePos = false
end


function UISelfieMusicCutSetView:UpdateCutStartTime()
    UIHelper.SetText(self.EditPaginate_Start, Timer.FormatMilliseconds(DataModel.nCutStartTime, nil, true))
    local nX = self.nClipLen *  (DataModel.nCutStartTime / DataModel.nTotalBgmTime) * 2
    UIHelper.SetPositionX(self.BtnCutLeft, nX - self.nClipLen)
    self:UpdateCutImageSize()
end

function UISelfieMusicCutSetView:UpdateCutEndTime()
    UIHelper.SetText(self.EditPaginate_End, Timer.FormatMilliseconds(DataModel.nCutEndTime, nil, true))
    local nX =  self.nClipLen *  (DataModel.nCutEndTime / DataModel.nTotalBgmTime) * 2
    UIHelper.SetPositionX(self.BtnCutRight, nX - self.nClipLen)
    self:UpdateCutImageSize()
end

function UISelfieMusicCutSetView:OnDragClipCutHandle(nProgress, bStart)
    local nNewTime = math.floor(DataModel.nTotalBgmTime * nProgress)
    self:UpdateClipCutTime(bStart, nNewTime)
end

function UISelfieMusicCutSetView:UpdateClipCutTime(bStart, nNewTime)
    if bStart then
        DataModel.nCutStartTime = SelfieMusicData.GetMusicClipStartTime(nNewTime, DataModel.nTotalBgmTime,  DataModel.nCutEndTime)
    else
        DataModel.nCutEndTime = SelfieMusicData.GetMusicClipEndTime(nNewTime, DataModel.nTotalBgmTime, DataModel.nCutStartTime or DataModel.nBgmStartTime)
    end
    if bStart then
        self:UpdateCutStartTime() 
    else
        self:UpdateCutEndTime() 
    end
    self:UpdateCutTime()
    self:UpdateCheckClipToPlayTime(bStart)
end

function UISelfieMusicCutSetView:UpdateCheckClipToPlayTime(bStart)
    local nPlayTime = 0
    if bStart then
        nPlayTime= DataModel.nCutStartTime
    else
        nPlayTime = DataModel.nCutEndTime - SelfieMusicData.MIN_BGM_CUT_TIME
        if nPlayTime < DataModel.nCutStartTime then
            nPlayTime = DataModel.nCutStartTime
        end
    end
    self:UpdatePlayTime(nPlayTime / DataModel.nTotalBgmTime)
end

function UISelfieMusicCutSetView:UpdatePlayTime(nProgress)
    self:UpdateBgmPlayProgress(nProgress)
    DataModel.nPlayStartTime =  0
    DataModel.nPlayEndTime = DataModel.nCutEndTime
    SelfieMusicData.PlayBgMusicWithPos(self:GetRealyBgmID(), math.floor(DataModel.nTotalBgmTime * nProgress))
end

function UISelfieMusicCutSetView:UpdateBgmPlayProgress(fProgress)
    if fProgress < 0 or fProgress > 1 then
        return
    end
    if self.bPauseUpdateTimePos then
        return
    end
    local nX = self.nClipLen * fProgress * 2
    UIHelper.SetPositionX(self.BtnPlayLIne, nX - self.nClipLen)   
end

function UISelfieMusicCutSetView:UpdateCutTime()
    local nCutTime = DataModel.nCutEndTime - DataModel.nCutStartTime
    local szCutTime = Timer.FormatMsToSecondsTenthText(nCutTime)
    UIHelper.SetString(self.LabelTime, szCutTime)
end

function UISelfieMusicCutSetView:GetRealyBgmID()
    local nBGMID = DataModel.nSelBGMID
    if DataModel.nTagType == SELFIE_CAMERA_RIGHT_TAG.CUSTOM then
        local tCustom = SelfieMusicData.GetCustomBGM(DataModel.nSelBGMID)
        nBGMID = tCustom.nBGMID
    end
    return nBGMID
end
function UISelfieMusicCutSetView:UpdateClipMicroNudge(bStart, nDeltaMs)
    if bStart then
        self:UpdateClipCutTime(bStart, DataModel.nCutStartTime + nDeltaMs)
    else
        self:UpdateClipCutTime(bStart, DataModel.nCutEndTime + nDeltaMs)
    end
end


function UISelfieMusicCutSetView:UpdateInfo(nBGMID)
   
    DataModel = SelfieMusicData.GetDataModel()
    DataModel.nBgmStartTime = 0
    DataModel.nBgmEndTime = DataModel.nTotalBgmTime

    DataModel.nCutStartTime = 0
    DataModel.nCutEndTime = DataModel.nTotalBgmTime

    self.nClipLen = UIHelper.GetWidth(self.WidgetCutArea)*0.5
    self.bHasEdit = false
    UIHelper.SetEditboxTextHorizontalAlign(self.EditPaginate_Start, TextHAlignment.CENTER)
    UIHelper.SetEditboxTextHorizontalAlign(self.EditPaginate_End, TextHAlignment.CENTER)
    
    local tBGMInfo = Table_GetSelfieBGMInfo(DataModel.nSelBGMID)
    if tBGMInfo then
        UIHelper.SetString(self.LabelMusicName, UIHelper.GBKToUTF8(tBGMInfo.szName))
        UIHelper.SetString(self.LabelEnd, Timer.FormatMilliseconds(tBGMInfo.nTime, nil, true))

        local szImgCutPath = UIHelper.FixDXUIImagePath(tBGMInfo.szImgCutPath)
        if szImgCutPath and szImgCutPath ~= "" then
            UIHelper.SetTexture(self.ImgMusicLine,szImgCutPath)
        end
    end

    UIHelper.SetVisible(self.BtnApply, SelfieOneClickModeData.bOpenOneMode)
    UIHelper.LayoutDoLayout(self.LayoutButton)
    self:UpdateBtnPlayBGMState()
    self:UpdateCutStartTime()
    self:UpdateCutEndTime()
    self:UpdateCutTime()
    SelfieMusicData.SetProgressCallback(function (fProgress)
        self:UpdateBgmPlayProgress(fProgress)
    end)
    SelfieMusicData.SetPlayStopCallback(function ()
        self:UpdateBtnPlayBGMState()
    end)
    local fProgress = DataModel.nBgmCurTime / DataModel.nTotalBgmTime
    self:UpdateBgmPlayProgress(fProgress)
    if DataModel.nPlayState == BGM_PLAY_STATUS.PLAYING then
        SelfieMusicData.ActiviteProgressTimer(true)
    end
end

function UISelfieMusicCutSetView:UpdateBtnPlayBGMState()
    if DataModel.nPlayState == BGM_PLAY_STATUS.PLAYING then
        UIHelper.SetString(self.LabelPlay, "停止")
    else
        UIHelper.SetString(self.LabelPlay, "播放")
    end
end

function UISelfieMusicCutSetView:CheckCutEditor(bStart)
    local tSTimeData = self:ParseMsTimeText(UIHelper.GetText(self.EditPaginate_Start))
    local tETimeData = self:ParseMsTimeText(UIHelper.GetText(self.EditPaginate_End))
    
    if not tSTimeData or not tETimeData then
        TipsHelper.ShowNormalTip(g_tStrings.STR_SELFIE_BGM_INVALID_TIME)
        if bStart then
            UIHelper.SetText(self.EditPaginate_Start, Timer.FormatMilliseconds(DataModel.nCutStartTime, nil, true))
        else
            UIHelper.SetText(self.EditPaginate_End, Timer.FormatMilliseconds(DataModel.nCutEndTime, nil, true))
        end
        return
    end
    local nTotalTime = Table_GetSelfieBGMTime(self:GetRealyBgmID())
    DataModel.nCutStartTime = SelfieMusicData.GetMusicClipStartTime(tSTimeData.nTotalMilliseconds, nTotalTime,  tETimeData.nTotalMilliseconds)
    DataModel.nCutEndTime = SelfieMusicData.GetMusicClipEndTime(tETimeData.nTotalMilliseconds, nTotalTime, DataModel.nCutStartTime)
    self:UpdateCheckClipToPlayTime(bStart)
    self:UpdateCutStartTime()
    self:UpdateCutEndTime()
end

function UISelfieMusicCutSetView:IsValidTimeFormat(szTimeText)
    if type(szTimeText) ~= "string" then
        return false
    end
    
    local szMinute, szSecond
    
    szMinute, szSecond = string.match(szTimeText, "^(%d+):(%d+)$")
    if szMinute and szSecond then
        local nMinute = tonumber(szMinute)
        local nSecond = tonumber(szSecond)
        if nMinute and nSecond then
            return nMinute >= 0 and nSecond >= 0 and nSecond <= 59
        end
    end
    
    return false
end

function UISelfieMusicCutSetView:ParseMsTimeText(szTimeText)
    if not self:IsValidTimeFormat(szTimeText) then
        return
    end
    
    local tTimeData
    local szMinute, szSecond
    
    szMinute, szSecond = string.match(szTimeText, "^(%d+):(%d+)$")
    
    if szMinute and szSecond then
        local nMinute = tonumber(szMinute)
        local nSecond = tonumber(szSecond)
        tTimeData = {
            nMinute = nMinute,
            nSecond = nSecond,
            nTotalMilliseconds = (nMinute * 60 + nSecond) * 1000
        }
    end
    
    return tTimeData
end

function UISelfieMusicCutSetView:UpdateCutImageSize()
    local leftX = UIHelper.GetPositionX(self.BtnCutLeft)
    local rightX = UIHelper.GetPositionX(self.BtnCutRight)
    UIHelper.SetWidth(self.ImgMusicSelected, rightX - leftX)
    UIHelper.SetPositionX(self.ImgMusicSelected, (rightX + leftX)*0.5 )
end



return UISelfieMusicCutSetView