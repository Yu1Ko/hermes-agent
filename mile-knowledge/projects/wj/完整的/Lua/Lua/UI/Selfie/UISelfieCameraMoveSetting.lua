-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UISelfieCameraMoveSetting
-- Date: 
-- Desc: 运镜选择设置
-- ---------------------------------------------------------------------------------
local UISelfieCameraMoveSetting = class("UISelfieCameraMoveSetting")
local MAX_CAMANI_SEQUENCE_NUM = 3
local CAMERA_PLAY_STATE = {
    STOP = 1,
    PLAY = 2,
    PAUSE = 3,
}
function UISelfieCameraMoveSetting:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    --UIHelper.SetScrollViewCombinedBatchEnabled(self._rootNode, false)
    self:UpdateInfo()
end

function UISelfieCameraMoveSetting:OnExit()
    self.bInit = false
    self:UnRegEvent()
    if self.nCamPlayState ~= CAMERA_PLAY_STATE.STOP then
        self:StopAni()
    end
end

function UISelfieCameraMoveSetting:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleChangeCount , EventType.OnSelectChanged , function (_,bSelected)
        self.bEnableCamSeq = bSelected
        UIHelper.SetString(self.LabelChange,  self.bEnableCamSeq and "单个运镜" or "连续运镜")
        self:UpdateCamAniSeqList()
        Scene_StopReferenceCameraAni()
    end)

    
   UIHelper.BindUIEvent(self.BtnReplay, EventType.OnClick, function ()
        self:OnReplayClick()
    end)

   UIHelper.BindUIEvent(self.BtnPlayPause, EventType.OnClick, function ()
        if self.nCamPlayState == CAMERA_PLAY_STATE.PLAY then
            self:OnPauseClick()
        else
            self:OnPlayClick()
        end
    end)

    UIHelper.BindUIEvent(self.BtnApplication, EventType.OnClick, function ()
        local tData = nil
        if not self.bEnableCamSeq then
            if self.nCurSelectAniID then
                tData = {}
                tData[0] = self:GetCamAniPlayData(SelfieData.CAMERA_ANI_TYPE.DEFAULT, self.nCurSelectAniID)
            end
        else
            tData = self:GetCamAniSeqPlayData()
            if table.is_empty(tData) then
                tData = nil
            end
        end
        Event.Dispatch("ON_ONE_CLICK_CHOOSE_CAM_ANI", self.bEnableCamSeq, tData)
    end)

    UIHelper.BindUIEvent(self.BtnReset, EventType.OnClick, function ()
        if self.bEnableCamSeq then
            for k, v in pairs(self.tCameraAniSeq or {}) do
                self:UpdateItemEque(v.nID, true)
            end
            
        else
           self:UpdateItemSingle(self.nCurSelectAniID, true)
        end
    end)
end

function UISelfieCameraMoveSetting:RegEvent()
    Event.Reg(self, EventType.OnSelfieCameraAniSelected, function (nCameraAniID, bSelected)
        if self.bEnableCamSeq then
            self:UpdateItemEque(nCameraAniID, bSelected)
        else
           self:UpdateItemSingle(nCameraAniID, bSelected)
        end
    end)

    Event.Reg(self, "STOP_REFERENCE_CAMERA_ANI", function ()
        if self.bReplayFlag then
            self.bReplayFlag = false
        else
            self:SetPlayState(CAMERA_PLAY_STATE.STOP)
            self:UpdateBtnState()
        end
    end)
end

function UISelfieCameraMoveSetting:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
   
end

function UISelfieCameraMoveSetting:Hide()
    
end


function UISelfieCameraMoveSetting:Open()
    
end

function UISelfieCameraMoveSetting:Close()
    
end

function UISelfieCameraMoveSetting:UpdateInfo()
    self.tSeqListScripts = {}
    for i, v in ipairs(self.tSeqWidgetList) do
        self.tSeqListScripts[i] = UIHelper.GetBindScript(v)
        self.tSeqListScripts[i]:SetPos(i)
        self.tSeqListScripts[i]:SetLRClickCallback(function (nPos)
            self:OnSeqListItemLeftClick(nPos)
        end, function (nPos)
            self:OnSeqListItemRightClick(nPos)
        end)
    end
    self.bEnableCamSeq = false
    self.nCurSelectAniID = nil
    self.bReplayFlag = false
    self:SetPlayState(CAMERA_PLAY_STATE.STOP)
    self.tCameraAniSeq = {}
    self.tScripts = {}
    local tCamList = Table_GetSelfieCameraAniList()
    for _, tInfo in ipairs(tCamList) do
        self.tScripts[tInfo.nCameraAniID] = UIHelper.AddPrefab(PREFAB_ID.WidgetCameraMoveModule, self.ScrollCameraMove, tInfo)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollCameraMove) 
    UIHelper.SetSelected(self.ToggleChangeCount, self.bEnableCamSeq)
end

function UISelfieCameraMoveSetting:UpdateItemSingle(nCameraAniID, bSelected)
    if self.nCurSelectAniID and self.nCurSelectAniID ~= nCameraAniID then
        self.tScripts[self.nCurSelectAniID]:SetSelectState(false, 0)
    end
    if nCameraAniID then
        self.tScripts[nCameraAniID]:SetSelectState(not bSelected, 0)
        if self.nCurSelectAniID and self.nCurSelectAniID == nCameraAniID then
            self:StopAni()
        else
            self:PlayAni(nCameraAniID)
        end
    end
    if  bSelected then
        self.nCurSelectAniID = nil
       -- Event.Dispatch("ON_ONE_CLICK_CHOOSE_CAM_ANI", false, nil)
        self:UpdateSigleItemInfo(nil)
    else
        self.nCurSelectAniID = nCameraAniID
        self:UpdateSigleItemInfo({nID = nCameraAniID})
    end
    self:UpdateApplicationBtn()
end

function UISelfieCameraMoveSetting:UpdateItemEque(nCameraAniID, bSelected)
    if bSelected then
        for i = 1, MAX_CAMANI_SEQUENCE_NUM do
            local v = self.tCameraAniSeq[i]
            if v and v.nID and v.nID == nCameraAniID then
                self.tCameraAniSeq[i] = nil
                self.tScripts[nCameraAniID]:SetSelectState(false, i)
                break
            end
        end   
    else
        if table.get_len(self.tCameraAniSeq) >= MAX_CAMANI_SEQUENCE_NUM then
            TipsHelper.ShowNormalTip(string.format(g_tStrings.STR_SELFIE_CAMERA_SEQ_MAX, MAX_CAMANI_SEQUENCE_NUM))   
            return
        end
        for i = 1, MAX_CAMANI_SEQUENCE_NUM do
            if not self.tCameraAniSeq[i] then
                self.tCameraAniSeq[i] = self:GetCamAniPlayData(SelfieData.CAMERA_ANI_TYPE.DEFAULT,nCameraAniID)
                break
            end
        end
    end
    self:UpdateCamAniSeqList()
end

function UISelfieCameraMoveSetting:UpdateCamAniSeqList()
    if self.nCurSelectAniID then
        self.tScripts[self.nCurSelectAniID]:SetSelectState(false, 0)
        self:StopAni()
        self.nCurSelectAniID = nil
    end
    local tDataID = {}
    for i = 1, MAX_CAMANI_SEQUENCE_NUM do
        local tInfo = self.tCameraAniSeq[i] or {}
        if tInfo.nID then
            self.tScripts[tInfo.nID]:SetSelectState(self.bEnableCamSeq, i)
        end
        if self.bEnableCamSeq then
            self.tSeqListScripts[i]:UpdateInfo(tInfo, MAX_CAMANI_SEQUENCE_NUM)
            UIHelper.SetVisible(self.tSeqListScripts[i]._rootNode, true)
        else
            UIHelper.SetVisible(self.tSeqListScripts[i]._rootNode, i == 1)
        end
    end
    if not self.bEnableCamSeq then
        self:UpdateSigleItemInfo()
    end
    UIHelper.LayoutDoLayout(self.WidgetMoveList)
    self:UpdateBtnState()
    self:UpdateApplicationBtn()
    --Event.Dispatch("ON_ONE_CLICK_CHOOSE_CAM_ANI", true, self.bEnableCamSeq and self:GetCamAniSeqPlayData() or nil)
end

function UISelfieCameraMoveSetting:UpdateSigleItemInfo(tInfo)
    self.tSeqListScripts[1]:UpdateSimpleInfo(tInfo)
    UIHelper.LayoutDoLayout(self.WidgetMoveList)
end

function UISelfieCameraMoveSetting:UpdateBtnState()
    local bEnable = table.get_len(self.tCameraAniSeq) > 0
    UIHelper.SetVisible(self.BtnReplay, bEnable)
    UIHelper.SetVisible(self.BtnPlayPause, bEnable)
    self:UpdateBtnPlayBGMState()
    UIHelper.LayoutDoLayout(self.LayoutBtnList)
end

function UISelfieCameraMoveSetting:UpdateApplicationBtn()
    local bVisible = false
    if SelfieOneClickModeData.bOpenOneMode then
        if  self.bEnableCamSeq then
            bVisible = table.get_len(self.tCameraAniSeq) > 0
        else
            bVisible = self.nCurSelectAniID ~= nil
        end
    end
    UIHelper.SetVisible(self.BtnApplication, bVisible)
    UIHelper.LayoutDoLayout(self.LayoutBtnList)
end

function UISelfieCameraMoveSetting:UpdateBtnPlayBGMState()
    if self.nCamPlayState == CAMERA_PLAY_STATE.PLAY then
        UIHelper.SetString(self.LabelPlay, "停止")
    else
        UIHelper.SetString(self.LabelPlay, "播放")
    end
end

function UISelfieCameraMoveSetting:OnSeqListItemLeftClick(nCurPos)
    local tCamAniSeq = self.tCameraAniSeq
    if nCurPos > 1 then
        tCamAniSeq[nCurPos], tCamAniSeq[nCurPos - 1] = tCamAniSeq[nCurPos - 1], tCamAniSeq[nCurPos]
    end
    self:UpdateCamAniSeqList()
end

function UISelfieCameraMoveSetting:OnSeqListItemRightClick(nCurPos)
    local tCamAniSeq = self.tCameraAniSeq
    if nCurPos < MAX_CAMANI_SEQUENCE_NUM then
        tCamAniSeq[nCurPos], tCamAniSeq[nCurPos + 1] = tCamAniSeq[nCurPos + 1], tCamAniSeq[nCurPos]
    end
    self:UpdateCamAniSeqList()
end

function UISelfieCameraMoveSetting:OnReplayClick()
    if self.nCamPlayState ~= CAMERA_PLAY_STATE.STOP then
        self.bReplayFlag = true
    end

    local tData, nStayCharacterID, nPlotCharacterID = self:GetCamAniSeqPlayData()
    Scene_PlayReferenceCameraAni(tData, nStayCharacterID, nPlotCharacterID)
    self:SetPlayState(CAMERA_PLAY_STATE.PLAY)
    self:UpdateBtnState()
end

function UISelfieCameraMoveSetting:OnPlayClick()
    if self.nCamPlayState == CAMERA_PLAY_STATE.STOP then
        local tData, nStayCharacterID, nPlotCharacterID = self:GetCamAniSeqPlayData()
        Scene_PlayReferenceCameraAni(tData, nStayCharacterID, nPlotCharacterID)
    elseif self.nCamPlayState == CAMERA_PLAY_STATE.PAUSE then
        Scene_PauseReferenceCameraAni(false)
    end
    self:SetPlayState(CAMERA_PLAY_STATE.PLAY)
    self:UpdateBtnState()
end

function UISelfieCameraMoveSetting:OnPauseClick()
    Scene_PauseReferenceCameraAni(true)
    self:SetPlayState(CAMERA_PLAY_STATE.PAUSE)
    self:UpdateBtnState()
end

function UISelfieCameraMoveSetting:PlayAni(nCameraAniID)
    local tData = {}
    tData[0] = self:GetCamAniPlayData(SelfieData.CAMERA_ANI_TYPE.DEFAULT, nCameraAniID)

    local dwPlayer = UI_GetClientPlayerID()
    local nStayCharacterID = dwPlayer
    local nPlotCharacterID = dwPlayer
    Scene_PlayReferenceCameraAni(tData, nStayCharacterID, nPlotCharacterID)
    self:SetPlayState(CAMERA_PLAY_STATE.PLAY)
    self:UpdateApplicationBtn()
    --Event.Dispatch("ON_ONE_CLICK_CHOOSE_CAM_ANI", false, tData)
end

function UISelfieCameraMoveSetting:StopAni()
    Scene_StopReferenceCameraAni()
    self:SetPlayState(CAMERA_PLAY_STATE.STOP)
end

function UISelfieCameraMoveSetting:SetPlayState(playState)
    self.nCamPlayState = playState
end


function UISelfieCameraMoveSetting:GetCamAniPlayData(nType, nCameraAniID)
    local tData = {
        nType = nType,
        nID = nCameraAniID,
        bEnableLerp = false
    }
    return tData
end

function UISelfieCameraMoveSetting:GetCamAniSeqPlayData()
    local tCameraAniSeq = self.tCameraAniSeq

    local tData = {}
    local nDataIndex = 0
    for i = 1, MAX_CAMANI_SEQUENCE_NUM do
        local v = tCameraAniSeq[i]
        if v then
            tData[nDataIndex] = v
            nDataIndex = nDataIndex + 1
        end
    end

    local dwPlayer = UI_GetClientPlayerID()
    local nStayCharacterID = dwPlayer
    local nPlotCharacterID = dwPlayer
    return tData, nStayCharacterID, nPlotCharacterID
end

return UISelfieCameraMoveSetting