-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIInstrumentMainOption
-- Date: 2025-07-08 10:16:29
-- Desc: ?
-- ---------------------------------------------------------------------------------
local OPTION_MODE = {
    Free = 1,
    Preset = 2,
}
local UIInstrumentMainOption = class("UIInstrumentMainOption")

function UIInstrumentMainOption:OnEnter(InstrumentData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.InstrumentData = InstrumentData
    self:SetFreeMode(false)
    local tbPresetMusic = InstrumentPresetMusic.GetMusic(self.InstrumentData.szType)
    InstrumentData.SelecterInstrument(tbPresetMusic, true)
end

function UIInstrumentMainOption:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIInstrumentMainOption:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnReturn, EventType.OnClick, function(btn)
        local scriptPlayer = UIHelper.GetBindScript(self.WidgetMusicTipPlay)
        local scriptRecord = UIHelper.GetBindScript(self.WidgetMusicTipRecord)
        if scriptRecord then
            if scriptRecord:IsNeedToSave() then
                UIHelper.ShowConfirm(g_tStrings.STR_INSTRUMENT_RECORD_SAVE_TIP, function ()
                    scriptRecord:ResetRecord()
                end)
                return
            end
            scriptRecord:OnReturn()
        end

        if scriptPlayer then
            scriptPlayer:OnReturn()
        end
        self:SetFreeMode(self.nMode == OPTION_MODE.Free)
        UIHelper.SetVisible(self.BtnReturn, false)
        if self.InstrumentData and self.InstrumentData.StopPlaying then
            self.InstrumentData.StopPlaying()
        end
    end)
end

function UIInstrumentMainOption:RegEvent()
    Event.Reg(self, EventType.OnSelectInstrumentMusic, function (tData, bPreset)
        local scriptPlayer = UIHelper.GetBindScript(self.WidgetMusicTipPlay)
        -- local scriptRecord = UIHelper.GetBindScript(self.WidgetMusicTipRecord)

        if scriptPlayer then
            scriptPlayer:OnSelecterInstrument(tData, bPreset)
        end
        if not bPreset then
            self.nMode = OPTION_MODE.Free
            UIHelper.SetVisible(self.BtnReturn, true)
        end
        self:SetPlayingMode(true)
    end)
end

function UIInstrumentMainOption:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIInstrumentMainOption:UpdateInfo()
    
end

function UIInstrumentMainOption:SetFreeMode(bSet)
    local scriptRecord = UIHelper.GetBindScript(self.WidgetMusicTipRecord)

    self.nMode = bSet and OPTION_MODE.Free or OPTION_MODE.Preset
    if self.nMode == OPTION_MODE.Preset then
        local tbPresetMusic = InstrumentPresetMusic.GetMusic(self.InstrumentData.szType)
        InstrumentData.SelecterInstrument(tbPresetMusic, true)
        UIHelper.SetVisible(self.BtnReturn, false)
    else
        if scriptRecord and scriptRecord.tbRecordData and not table.is_empty(scriptRecord.tbRecordData) then
            UIHelper.SetVisible(self.BtnReturn, true)
        end
    end
    self:SetPlayingMode(not bSet)
end

function UIInstrumentMainOption:SetPlayingMode(bSet)
    UIHelper.SetVisible(self.WidgetMusicTipPlay, bSet)
    UIHelper.SetVisible(self.WidgetMusicTipRecord, not bSet)
end

return UIInstrumentMainOption