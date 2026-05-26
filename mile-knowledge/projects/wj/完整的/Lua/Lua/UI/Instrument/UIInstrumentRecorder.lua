-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIInstrumentRecorder
-- Date: 2025-07-08 10:24:36
-- Desc: ?
-- ---------------------------------------------------------------------------------
local CurrencyType = {
    Per_Record = 1, -- 准备录制
    Recording = 2, -- 正在录制
    End = 3, -- 录制结束
}

local CurrencyType2Title = {
    [CurrencyType.Per_Record] = "导入/录制曲谱",
    [CurrencyType.Recording] = "录制时长：%02d:%02d",
    [CurrencyType.End] = "导出曲谱",
}

local UIInstrumentRecorder = class("UIInstrumentRecorder")

function UIInstrumentRecorder:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.bSaveRecord = false
    self.tbRecordData = {}
    self.nState = CurrencyType.Per_Record
    self:UpdateInfo()
end

function UIInstrumentRecorder:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIInstrumentRecorder:BindUIEvent()
    for nIndex, btn in ipairs(self.tbBtns_1) do -- CurrencyType.Per_Record
        UIHelper.BindUIEvent(btn, EventType.OnClick, function(btn)
            if nIndex == 1 then
                if self:IsNeedToSave() then
                    UIHelper.ShowConfirm(g_tStrings.STR_INSTRUMENT_RECORD_SAVE_TIP2, function ()
                        self:ResetRecord()
                        InstrumentData.StartRecord()
                    end)
                    return
                end
                InstrumentData.StartRecord()
            elseif nIndex == 2 then
                Event.Dispatch(EventType.OnShowInstrumentList, false)
            elseif nIndex == 3 then
                UIMgr.Open(VIEW_ID.PanelCloudMusicCode)
            elseif nIndex == 4 then
                Event.Dispatch(EventType.OnShowInstrumentList, true)
            end
        end)
    end

    for nIndex, btn in ipairs(self.tbBtns_2) do -- CurrencyType.Recording
        UIHelper.BindUIEvent(btn, EventType.OnClick, function(btn)
            if nIndex == 1 then
               InstrumentData.StopRecord()
            end
        end)
    end

    for nIndex, btn in ipairs(self.tbBtns_3) do -- CurrencyType.End
        if nIndex ~= 1 then
            UIHelper.BindUIEvent(btn, EventType.OnClick, function(btn)
                if nIndex == 2 then
                    if not self.tbRecordData or table.is_empty(self.tbRecordData) then
                        return
                    end

                    UIMgr.Open(VIEW_ID.PanelPrintMusicToCloudPop, false, function(szFileName)
                        self.bSaveRecord = true
                        InstrumentData.UploadRecord(self.tbRecordData, szFileName)
                        UIMgr.Close(VIEW_ID.PanelPrintMusicToCloudPop)
                    end)
                elseif nIndex == 3 then
                    if not self.tbRecordData or table.is_empty(self.tbRecordData) then
                        return
                    end

                    UIMgr.Open(VIEW_ID.PanelPrintMusicToCloudPop, true, function(szFileName)
                        self.bSaveRecord = true
                        InstrumentData.SaveRecord(self.tbRecordData, szFileName)
                        UIMgr.Close(VIEW_ID.PanelPrintMusicToCloudPop)
                    end)
                end
            end)
        end
    end
end

function UIInstrumentRecorder:RegEvent()
    Event.Reg(self, EventType.OnInstrumentRecordStart, function (nStartTime)
        self:StartRecord(nStartTime)
    end)

    Event.Reg(self, EventType.OnInstrumentRecordStop, function (tRecord)
        self:StopRecord(tRecord)
    end)
end

function UIInstrumentRecorder:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIInstrumentRecorder:UpdateInfo()
    if self.nRecordTimer then
        Timer.DelTimer(self, self.nRecordTimer)
        self.nRecordTimer = nil
    end

    local szTitle = CurrencyType2Title[self.nState] or "未知状态"
    UIHelper.SetString(self.LabelMusicTitle, szTitle)
    for _, btn in ipairs(self.tbAllBtns) do
        UIHelper.SetVisible(btn, false)
    end

    local tbBtn = self["tbBtns_"..self.nState]
    for index, btn in ipairs(tbBtn) do
        UIHelper.SetVisible(btn, true)
    end

    UIHelper.SetVisible(self.BtnReturn, self.nState == CurrencyType.End)
    UIHelper.LayoutDoLayout(self.WidgetBtnLeft)
end

function UIInstrumentRecorder:StartRecord(nStarTime)
    self.bSaveRecord = false
    self.nState = CurrencyType.Recording
    self:UpdateInfo()

    local _fnUpdateTime = function()
        local szTitle = CurrencyType2Title[CurrencyType.Recording]
        local nCurTime = GetTickCount() - nStarTime
        local nSumS = math.floor(nCurTime / 1000)
        local nM, nS = nSumS / 60, nSumS % 60
        szTitle = string.format(szTitle, nM, nS)

        UIHelper.SetString(self.LabelMusicTitle, szTitle)
    end

    self.nRecordTimer = Timer.AddFrameCycle(self, 1, function ()
        _fnUpdateTime()
    end)

    _fnUpdateTime()
end

function UIInstrumentRecorder:StopRecord(tRecord)
    self.nState = CurrencyType.End
    self.tbRecordData = tRecord
    self:UpdateInfo()
end

function UIInstrumentRecorder:ResetRecord()
    self.nState = CurrencyType.Per_Record
    self.tbRecordData = {}
    self:UpdateInfo()
end

function UIInstrumentRecorder:IsNeedToSave()
    local bNeedSave = false
    if not table.is_empty(self.tbRecordData) and not self.bSaveRecord then
        bNeedSave = true
    end

    return bNeedSave
end

function UIInstrumentRecorder:OnReturn()
    self:ResetRecord()
end

return UIInstrumentRecorder