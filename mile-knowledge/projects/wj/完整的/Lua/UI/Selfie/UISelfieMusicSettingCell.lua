-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UISelfieMusicSettingCell
-- Date: WidgetMusicTogCell
-- Desc: 一键成片BGM节点选择
-- ---------------------------------------------------------------------------------
local UISelfieMusicSettingCell = class("UISelfieMusicSettingCell")

function UISelfieMusicSettingCell:OnEnter(tInfo, bSel)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tInfo = tInfo
    self:UpdateInfo()
       
    self:SetSelectState(bSel)
end

function UISelfieMusicSettingCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISelfieMusicSettingCell:BindUIEvent()
    UIHelper.BindUIEvent(self.WidgetMusicTogCell , EventType.OnClick , function ()
        if not self.bSelected then
            local tSetting = GetGameSoundSetting(SOUND.MAIN)
            local bUnEnableMain = tSetting.TogSelect
            tSetting = GetGameSoundSetting(SOUND.BG_MUSIC)
            local bUnEnableMusic = tSetting.TogSelect
            local nBgmValue = GameSettingData.GetSoundSliderValue(SOUND.BG_MUSIC)
            local nMainValue = GameSettingData.GetSoundSliderValue(SOUND.MAIN)
            -- 静音判定：Enable 或 EnableBgMusic 关闭，或总音量/背景音量为 0 时视为静音
            local bMuted = (bUnEnableMain) or (bUnEnableMusic) or (nMainValue <= 0) or (nBgmValue <= 0)
            if bMuted then
                TipsHelper.ShowImportantYellowTip(g_tStrings.STR_SELFIE_BGM_MUTE_TIP)
            end

        end
        if self.tInfo.bCustomMusic then
            Event.Dispatch(EventType.OnSelfieCameraBGMSelected, self.tInfo.nCustomBGMID, self.bSelected, true, self.tInfo.nBGMID)
        else
            Event.Dispatch(EventType.OnSelfieCameraBGMSelected, self.tInfo.nID, self.bSelected)
        end
    end)

    UIHelper.BindUIEvent(self.BtnDelete , EventType.OnClick , function ()
        if self.tInfo.bCustomMusic then
            UIHelper.ShowConfirm(string.format(g_tStrings.STR_SELFIE_DELETE_CUSTOM_BGM_CONFIRM, self.tInfo.szCustomName), function ()
                SelfieMusicData.OnStopBgMusic(true)
                local szBgmEvent = Table_GetSelfieBGMEvent(self.tInfo.nBGMID)
                SoundMgr.StopUIBgMusic(szBgmEvent, true)
                SelfieMusicData.DeleteCustomBGM(self.tInfo.nCustomBGMID)
                Event.Dispatch(EventType.OnSelfieCameraBGMCustomDeleted)
            end)
        end
    end)

    UIHelper.BindUIEvent(self.BtnPlay , EventType.OnClick , function ()
        Event.Dispatch(EventType.OnSelfieCameraBGMPlay)
        UIHelper.SetVisible(self.BtnPause, true)
        UIHelper.SetVisible(self.BtnPlay, false)
    end)

    UIHelper.BindUIEvent(self.BtnPause , EventType.OnClick , function ()
        Event.Dispatch(EventType.OnSelfieCameraBGMPause)
        UIHelper.SetVisible(self.BtnPause, false)
        UIHelper.SetVisible(self.BtnPlay, true)
    end)

    UIHelper.BindUIEvent(self.BtnEdit , EventType.OnClick , function ()
        Event.Dispatch(EventType.OnSelfieCameraBGMEditor, true)
    end)

    UIHelper.SetSwallowTouches(self.BtnPause, true)
    UIHelper.SetSwallowTouches(self.BtnPlay, true)
    UIHelper.SetSwallowTouches(self.BtnEdit, true)
    UIHelper.SetSwallowTouches(self.BtnDelete, true)
end

function UISelfieMusicSettingCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UISelfieMusicSettingCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UISelfieMusicSettingCell:UpdateInfo()
    self:SetSelectState(false)
    UIHelper.SetVisible(self.TogCameraMoveSelection, true)
    local nTime = 0
    local szImgBgPath = "" 
    if self.tInfo.bCustomMusic then
        local tBGMInfo = Table_GetSelfieBGMInfo(self.tInfo.nBGMID)
        nTime = self.tInfo.nEndTime - self.tInfo.nStartTime
        szImgBgPath = tBGMInfo.szImgPath
        UIHelper.SetString(self.LabelMusicName, self.tInfo.szCustomName)
    else
        nTime = self.tInfo.nTime
        szImgBgPath = self.tInfo.szImgPath
        UIHelper.SetString(self.LabelMusicName, UIHelper.GBKToUTF8(self.tInfo.szName))
    end
  
    self.szTotleTime = Timer.FormatMilliseconds(nTime, nil, true)
    UIHelper.SetString(self.LabelTime,  self.szTotleTime)
    szImgBgPath = UIHelper.FixDXUIImagePath(szImgBgPath)
    if szImgBgPath and szImgBgPath ~= "" then
        UIHelper.SetTexture(self.ImgMusic, szImgBgPath)
    end
    UIHelper.SetVisible(self.BtnEdit, not self.tInfo.bCustomMusic)
    UIHelper.SetVisible(self.BtnDelete, self.tInfo.bCustomMusic)
end

function UISelfieMusicSettingCell:SetSelectState(bSelected)
    self.bSelected = bSelected
    UIHelper.SetVisible(self.WidgetSelected, self.bSelected)
    if bSelected then
        self:OnStartPlay()
    else
        self:OnEndPlay()
    end
end

function UISelfieMusicSettingCell:OnStartPlay(curTime)
    UIHelper.SetVisible(self.BtnPlay,  false)
    UIHelper.SetVisible(self.BtnPause, true)
    UIHelper.SetString(self.LabelTime, string.format("%s/%s", curTime and Timer.FormatMilliseconds(curTime, nil, true) or "00:00", self.szTotleTime))
end

function UISelfieMusicSettingCell:OnEndPlay()
    UIHelper.SetVisible(self.BtnPlay,  false)
    UIHelper.SetVisible(self.BtnPause, false)
    UIHelper.SetString(self.LabelTime,  self.szTotleTime)
end

function UISelfieMusicSettingCell:OnPausePlay(curTime)
    UIHelper.SetVisible(self.BtnPlay,  true)
    UIHelper.SetVisible(self.BtnPause, false)
    UIHelper.SetString(self.LabelTime, string.format("%s/%s", curTime and Timer.FormatMilliseconds(curTime, nil, true) or "00:00", self.szTotleTime))
end

function UISelfieMusicSettingCell:SetProgress(nProgress, curTime)
    UIHelper.SetProgressBarPercent(self.ProgressBarMusic, nProgress*100)

    UIHelper.SetString(self.LabelTime, string.format("%s/%s",Timer.FormatMilliseconds(curTime, nil, true), self.szTotleTime))
end

return UISelfieMusicSettingCell