-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UISelfieMusicSettingView
-- Date: PREFAB_ID.WidgetVideoMusic
-- Desc:
-- ---------------------------------------------------------------------------------
local UISelfieMusicSettingView = class("UISelfieMusicSettingView")
local DataModel = {}
function UISelfieMusicSettingView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UISelfieMusicSettingView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    SelfieMusicData.SetProgressCallback(nil)
    SelfieMusicData.ActiviteProgressTimer(false)
    SelfieMusicData.OnStopBgMusic(true)
end

function UISelfieMusicSettingView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnApply, EventType.OnClick, function ()
        Event.Dispatch("ON_ONE_CLICK_CHOOSE_BGM", DataModel.nSelBGMID, DataModel.nPlayStartTime, DataModel.nPlayEndTime, DataModel.nTagType == SELFIE_CAMERA_RIGHT_TAG.CUSTOM)
    end)
end

function UISelfieMusicSettingView:RegEvent()
    Event.Reg(self, EventType.OnSelfieCameraBGMSelected, function (nBGMID, bSelected, bCustom, nCustomID)
        self:OnSelectBGMItem(nBGMID, not bSelected, bCustom, nCustomID)
    end)

    Event.Reg(self, EventType.OnSelfieCameraBGMPlay, function ()
        DataModel.nPlayState = BGM_PLAY_STATUS.PLAYING

        SelfieMusicData.PlayBgMusicWithPos(DataModel.nSelBGMID, DataModel.nBgmCurTime)
    end)

    Event.Reg(self, EventType.OnSelfieCameraBGMPause, function ()
        DataModel.nPlayState = BGM_PLAY_STATUS.STOP
        SelfieMusicData.OnStopBgMusic()
    end)

    Event.Reg(self, EventType.OnSelfieCameraBGMEditor, function (bEnter)
        if bEnter then
            UIMgr.Open(VIEW_ID.PanelCutMusic)
        else
            self:RefreshUI()
        end
    end)

    Event.Reg(self, EventType.OnSelfieCameraBGMCustomDeleted, function ()
        DataModel.nSelCustomBGMID = nil
        self:UpdateSelectModle(SELFIE_CAMERA_RIGHT_TAG.CUSTOM)
        self:OnSelectBGMItem(nil, false, true, nil)
    end)

    Event.Reg(self, "STOP_SELFIE_BGM", function ()
        if DataModel.nPlayState == BGM_PLAY_STATUS.PLAYING then
            DataModel.nPlayState = BGM_PLAY_STATUS.STOP
            SelfieMusicData.OnStopBgMusic()
        end
    end)
    
    Event.Reg(self, "REPLAY_SELFIE_BGM", function (bCustom)
        if DataModel.nSelBGMID then
            SelfieMusicData.OnRePlayBGM()
        end
    end)
end

function UISelfieMusicSettingView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UISelfieMusicSettingView:Close()
   
end


function UISelfieMusicSettingView:UpdateInfo()
    DataModel.nSelBGMID = nil
    DataModel.nSelCustomBGMID = nil
    DataModel.szPlayBgmEvent = nil
    DataModel.szSearchBGM = ""
    DataModel.nBgmCurTime = 0
    DataModel.nSelectDefaultID = nil
    DataModel.nPlayState = BGM_PLAY_STATUS.STOP
    SelfieMusicData.SetDataModel(DataModel)
    self:RefreshUI()
    UIHelper.SetVisible(self.BtnApply, SelfieOneClickModeData.bOpenOneMode)
    UIHelper.LayoutDoLayout(self.LayoutBtnList)
end

function UISelfieMusicSettingView:RefreshUI()
    SelfieMusicData.SetProgressCallback(function (fProgress)
        self:UpdateBgmPlayProgress(fProgress)
    end)
    if self.tScripts and self.tScripts[DataModel.nSelBGMID] then
        if DataModel.nPlayState == BGM_PLAY_STATUS.PLAYING then
            self.tScripts[DataModel.nSelBGMID]:OnStartPlay(DataModel.nBgmCurTime)
        else
            self.tScripts[DataModel.nSelBGMID]:OnPausePlay(DataModel.nBgmCurTime)
        end
        self:UpdateBgmPlayProgress(DataModel.nBgmCurTime / DataModel.nTotalBgmTime)
    end
end

function UISelfieMusicSettingView:UpdateSelectModle(nTagType)
    DataModel.nSelBGMID = nil
    if SELFIE_CAMERA_RIGHT_TAG.DEFAULT == nTagType then
        self:UpdateItemList()
    else
        self:UpdateCustomList()
    end
    DataModel.nTagType = nTagType
end

function UISelfieMusicSettingView:UpdateItemList()
    local tBGMList = Table_GetSelfieBGMList()
    self.tScripts = {}
    local bEmpty = true
    UIHelper.RemoveAllChildren(self.ScrollViewMusicList)
    for _, tInfo in ipairs(tBGMList) do
        if DataModel.szSearchBGM == "" or self:MatchFilter(tInfo.szName, DataModel.szSearchBGM or "") then
            local bSel = DataModel.nSelectDefaultID and DataModel.nSelectDefaultID == tInfo.nID
            self.tScripts[tInfo.nID] = UIHelper.AddPrefab(PREFAB_ID.WidgetMusicTogCell, self.ScrollViewMusicList, tInfo, bSel)
            if bSel then
                DataModel.nSelBGMID = tInfo.nID
            end 
        end
        bEmpty = false
    end
    UIHelper.SetVisible(self.WidgetEmpty, bEmpty)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewMusicList)
end

function UISelfieMusicSettingView:UpdateCustomList()
    local bEmpty = true
    self.tScripts = {}
    UIHelper.RemoveAllChildren(self.ScrollViewMusicList)
    local tCustomBgmList = SelfieMusicData.GetAllCustomBGM() or {}
    if #tCustomBgmList > 0 then
        for nIndex, tInfo in ipairs(tCustomBgmList) do
            tInfo.bCustomMusic = true
            tInfo.nCustomBGMID = nIndex
            local bSel = DataModel.nSelCustomBGMID and DataModel.nSelCustomBGMID == tInfo.nCustomBGMID
            self.tScripts[tInfo.nCustomBGMID] = UIHelper.AddPrefab(PREFAB_ID.WidgetMusicTogCell, self.ScrollViewMusicList, tInfo, bSel)
            if bSel then
                DataModel.nSelBGMID = tInfo.nBGMID
            end 
        end
        bEmpty = false
    end
    UIHelper.SetVisible(self.WidgetEmpty, bEmpty)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewMusicList)
end

function UISelfieMusicSettingView:OnSelectBGMItem(nBGMID, bSelected, bCustom, nCustomID)

    if self.tScripts[nBGMID] then
        self.tScripts[nBGMID]:SetSelectState(bSelected)
    end
    if bSelected then
        if bCustom then
            if DataModel.nSelCustomBGMID and self.tScripts[DataModel.nSelCustomBGMID] then
                self.tScripts[DataModel.nSelCustomBGMID]:SetSelectState(false)
            end
        else
            if DataModel.nSelBGMID then
                self.tScripts[DataModel.nSelBGMID]:SetSelectState(false)
            end
        end

        if bCustom then
            DataModel.nSelCustomBGMID = nBGMID
            DataModel.nSelBGMID = nCustomID
            DataModel.nSelectDefaultID = nil
        else
            DataModel.nSelBGMID = nBGMID
            DataModel.nSelCustomBGMID = nil
            DataModel.nSelectDefaultID = nBGMID
        end
  
        SelfieMusicData.OnRePlayBGM()
        UIHelper.SetVisible(self.BtnApply, SelfieOneClickModeData.bOpenOneMode)
    else
        SelfieMusicData.OnStopBgMusic()
        DataModel.nSelBGMID = nil
        DataModel.nSelCustomBGMID = nil
        UIHelper.SetVisible(self.BtnApply, false)
    end
end

function UISelfieMusicSettingView:UpdateBgmPlayProgress(nProgress)
    if SELFIE_CAMERA_RIGHT_TAG.CUSTOM == DataModel.nTagType  then
        if DataModel.nSelCustomBGMID and self.tScripts[DataModel.nSelCustomBGMID] then
            self.tScripts[DataModel.nSelCustomBGMID]:SetProgress(nProgress, DataModel.nBgmCurTime - (DataModel.nPlayStartTime or 0))
            if nProgress >= 1 then
                 self.tScripts[DataModel.nSelCustomBGMID]:OnPausePlay(DataModel.nPlayEndTime-(DataModel.nPlayStartTime or 0))
            end
        end
    else
        if DataModel.nSelBGMID and self.tScripts[DataModel.nSelBGMID] then
            self.tScripts[DataModel.nSelBGMID]:SetProgress(nProgress, DataModel.nBgmCurTime- (DataModel.nPlayStartTime or 0))
            if nProgress >= 1 then
                 self.tScripts[DataModel.nSelBGMID]:OnPausePlay(DataModel.nPlayEndTime- (DataModel.nPlayStartTime or 0))
            end
        end
    end
end

function UISelfieMusicSettingView:MatchFilter(szInput, szFiler)
	if szFiler == "" then
		return true
	end
    local result = string.find(szInput, szFiler)
	return result and true or false
end

return UISelfieMusicSettingView
