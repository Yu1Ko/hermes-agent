-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIInstrumentPlayer
-- Date: 2025-07-08 10:24:36
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIInstrumentPlayer = class("UIInstrumentPlayer")

function UIInstrumentPlayer:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIInstrumentPlayer:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIInstrumentPlayer:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnRight1, EventType.OnClick, function(btn)
        InstrumentData.StartPlaying()
    end)

    UIHelper.BindUIEvent(self.BtnRight2, EventType.OnClick, function(btn)
        InstrumentData.StopPlaying()
    end)

    UIHelper.BindUIEvent(self.BtnRight3, EventType.OnClick, function(btn)
        Event.Dispatch(EventType.OnShowInstrumentList, true)
    end)

    UIHelper.BindUIEvent(self.BtnRight4, EventType.OnClick, function(btn)
        if not self.tbSelectInstrument or not IsTable(self.tbSelectInstrument) then
            return
        end

        UIMgr.Open(VIEW_ID.PanelPrintMusicToCloudPop, false, function(szFileName)
            InstrumentData.UploadRecord(self.tbSelectInstrument, szFileName)
            UIMgr.Close(VIEW_ID.PanelPrintMusicToCloudPop)
        end)
    end)

    UIHelper.BindUIEvent(self.BtnRight5, EventType.OnClick, function(btn)
        if not self.tbSelectInstrument or not IsTable(self.tbSelectInstrument) then
            return
        end

        UIMgr.Open(VIEW_ID.PanelPrintMusicToCloudPop, true, function(szFileName)
            InstrumentData.SaveRecord(self.tbSelectInstrument, szFileName)
            UIMgr.Close(VIEW_ID.PanelPrintMusicToCloudPop)
        end)
    end)
end

function UIInstrumentPlayer:RegEvent()
    Event.Reg(self, EventType.OnInstrumentPlayingStart, function (nStarTime)
        self:StartPlaying(nStarTime)
    end)

    Event.Reg(self, EventType.OnInstrumentPlayingStop, function ()
        self:UpdateInfo()
    end)
end

function UIInstrumentPlayer:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIInstrumentPlayer:OnReturn()
    self.tbSelectInstrument = nil
    self:UpdateInfo()
end

function UIInstrumentPlayer:OnSelecterInstrument(tbData, bPreset)
    if not tbData then
        return
    end

    self.bPreset = bPreset
    self.tbSelectInstrument = clone(tbData)
    self:UpdateInfo()
    if bPreset then
        UIHelper.SetVisible(self.BtnRight3, true)
        UIHelper.SetVisible(self.BtnRight4, false)
        UIHelper.SetVisible(self.BtnRight5, false)
    end
end

function UIInstrumentPlayer:UpdateInfo()
    if self.nPlayTimer then
        Timer.DelTimer(self, self.nPlayTimer)
        self.nPlayTimer = nil
    end

    local bHaveInstrument = self.tbSelectInstrument and IsTable(self.tbSelectInstrument)
    local tbData = self.tbSelectInstrument or {}
    local szTitle = bHaveInstrument and tbData.szFileName or "未知曲谱"
    UIHelper.SetVisible(self.BtnRight1, true)
    UIHelper.SetVisible(self.BtnRight2, false)

    if not bHaveInstrument then
        UIHelper.SetVisible(self.BtnRight3, true)
        UIHelper.SetVisible(self.BtnRight4, false)
        UIHelper.SetVisible(self.BtnRight5, false)
        UIHelper.SetString(self.LabelMusicName, szTitle)
        UIHelper.SetString(self.LabelMusicTime1, "--:--")
        UIHelper.SetString(self.LabelMusicTime2, "--:--")
        UIHelper.SetProgressBarPercent(self.SliderActionSelect, 0)
        UIHelper.SetButtonState(self.BtnRight1, BTN_STATE.Disable, "请选择曲谱")
        return
    end

    local nMaxTime = InstrumentData.GetMaxTime(tbData, true)
    local nSumSMax = math.floor(nMaxTime / 1000)
    local nMMax, nSMax = nSumSMax / 60, nSumSMax % 60
    local szMaxTime = string.format("%02d:%02d", nMMax, nSMax)
    szTitle = tbData.szFileName and tbData.szFileName or "未知曲谱"

    UIHelper.SetString(self.LabelMusicName, szTitle)
    UIHelper.SetString(self.LabelMusicTime1, "00:00")
    UIHelper.SetString(self.LabelMusicTime2, szMaxTime)
    UIHelper.SetProgressBarPercent(self.SliderActionSelect, 0)
    UIHelper.SetVisible(self.BtnRight3, self.bPreset)
    UIHelper.SetVisible(self.BtnRight4, not self.bPreset)
    UIHelper.SetVisible(self.BtnRight5, false)
    UIHelper.SetButtonState(self.BtnRight1, BTN_STATE.Normal)
end

function UIInstrumentPlayer:StartPlaying(nStarTime)
    if self.nPlayTimer then
        Timer.DelTimer(self, self.nPlayTimer)
        self.nPlayTimer = nil
    end

    local _fnUpdateTime = function()
        if not self.tbSelectInstrument then
            return
        end

        local nCurTime = GetTickCount() - nStarTime
        local nMaxTime = InstrumentData.GetMaxTime(self.tbSelectInstrument, true)
        if nCurTime > nMaxTime then
            Timer.DelTimer(self, self.nPlayTimer)
            self.nPlayTimer = nil
            self:UpdateInfo()
            return
        end

        local nSumS = math.floor(nCurTime / 1000)
        local nM, nS = nSumS / 60, nSumS % 60
        local szCurTime = string.format("%02d:%02d", nM, nS)

        UIHelper.SetString(self.LabelMusicTime1, szCurTime)
        UIHelper.SetProgressBarPercent(self.SliderActionSelect, (nCurTime / nMaxTime) * 100)
    end

    self.nPlayTimer = Timer.AddFrameCycle(self, 1, function ()
        _fnUpdateTime()
    end)

    _fnUpdateTime()
    UIHelper.SetVisible(self.BtnRight1, false)
    UIHelper.SetVisible(self.BtnRight2, true)
end



return UIInstrumentPlayer