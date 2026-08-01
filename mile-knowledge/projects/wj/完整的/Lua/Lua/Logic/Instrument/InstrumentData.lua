-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: InstrumentData
-- Date: 2025-07-07 16:44:08
-- Desc: ?
-- ---------------------------------------------------------------------------------
local tbIndex2Tone = {
    [1] = "Treble",
    [2] = "Midrange",
    [3] = "Bass",
    [4] = "DoubleBass",
}

local MAX_TONE_LEVEL = 6
local MIN_TONE_LEVEL = -6

-- bOpKey为策划可配表控制功能的按键
local tbSpecialKey = {
    ["CTRL"] = {bOpKey = false},
    ["SHIFT"] = {bOpKey = false},
    ["UP"] = {bOpKey = false},
    ["DOWN"] = {bOpKey = false},
    ["LEFT"] = {bOpKey = false},
    ["RIGHT"] = {bOpKey = false},
    ["SPACE"] = {bOpKey = true},
    ["-"] = {bOpKey = true},
    ["="] = {bOpKey = true},
}

local tbCCKeyCode2Name = {}
local tbCCKeyName2Code =
{
    ["SHIFT"] = cc.KeyCode.KEY_SHIFT,
    ["CTRL"] = cc.KeyCode.KEY_CTRL,
    ["SPACE"] =  cc.KeyCode.KEY_SPACE,
    ["LEFT"] = cc.KeyCode.KEY_LEFT_ARROW,
    ["RIGHT"] = cc.KeyCode.KEY_RIGHT_ARROW,
    ["UP"] = cc.KeyCode.KEY_UP_ARROW,
    ["DOWN"] = cc.KeyCode.KEY_DOWN_ARROW,
    ["OEMPLUS"] = cc.KeyCode.OEMPlus, -- '+' any country
    ["OEMMINUS"] = cc.KeyCode.OEMMinus, -- '-' any country
    ["KPPlus"] = cc.KeyCode.KEY_KP_PLUS, -- '+' any country
    ["KPMinus"] = cc.KeyCode.KEY_KP_MINUS, -- '-' any country
    ["1"] = cc.KeyCode.KEY_1,
    ["2"] = cc.KeyCode.KEY_2,
    ["3"] = cc.KeyCode.KEY_3,
    ["4"] = cc.KeyCode.KEY_4,
    ["5"] = cc.KeyCode.KEY_5,
    ["6"] = cc.KeyCode.KEY_6,
    ["7"] = cc.KeyCode.KEY_7,
    ["Q"] = cc.KeyCode.KEY_Q,
    ["W"] = cc.KeyCode.KEY_W,
    ["E"] = cc.KeyCode.KEY_E,
    ["R"] = cc.KeyCode.KEY_R,
    ["T"] = cc.KeyCode.KEY_T,
    ["Y"] = cc.KeyCode.KEY_Y,
    ["U"] = cc.KeyCode.KEY_U,
    ["A"] = cc.KeyCode.KEY_A,
    ["S"] = cc.KeyCode.KEY_S,
    ["D"] = cc.KeyCode.KEY_D,
    ["F"] = cc.KeyCode.KEY_F,
    ["G"] = cc.KeyCode.KEY_G,
    ["H"] = cc.KeyCode.KEY_H,
    ["J"] = cc.KeyCode.KEY_J,
    ["Z"] = cc.KeyCode.KEY_Z,
    ["X"] = cc.KeyCode.KEY_X,
    ["C"] = cc.KeyCode.KEY_C,
    ["V"] = cc.KeyCode.KEY_V,
    ["B"] = cc.KeyCode.KEY_B,
    ["N"] = cc.KeyCode.KEY_N,
    ["M"] = cc.KeyCode.KEY_M,
}

for k, v in pairs(tbCCKeyName2Code) do
    tbCCKeyCode2Name[v] = k
end

InstrumentData = InstrumentData or {className = "InstrumentData"}
local self = InstrumentData

function InstrumentData.Open(szType)
    UIMgr.Open(VIEW_ID.PanelMusicMainPlay, szType)
end

function InstrumentData.Exit()
    if UIMgr.GetView(VIEW_ID.PanelMusicMainPlay) then
        UIMgr.Close(VIEW_ID.PanelMusicMainPlay)
    end
end

function InstrumentData.CheckShowRuleTip()
    local bShowRule = Storage.InstrumentRule.bShowRule
    if not bShowRule then
        UIMgr.Open(VIEW_ID.PanelMusicRulePop)
    end
end
-------------------------------- 消息定义 --------------------------------
InstrumentData.Event = {}
InstrumentData.szType = "sanxian"

function InstrumentData.Init(szType)
    self.szType = szType or "sanxian"
    self.nTransfer = 0 -- 调移
    self.nSlider = 0 -- 滑音
    self.nStartTime = 0 -- 录音开始时间
    self.bIsCtrlDown = false -- 轮指
    self.bIsShiftDown = false -- 泛音
    self.bRecording = false
    self.bPlaying = false
    self.tRecord = {}
    self.tbCloudList = nil -- 云端数据
    self.tbHadLoadCloudList = {} -- 云端数据_已下载
    InstrumentData.Reg()
    InstrumentData.InitKeyList()
end

function InstrumentData.Reg()
    Event.Reg(self, EventType.OnGetInstrumentList, function(tList)
        self.tbCloudList = tList
        for _, tInstrument in pairs(tList) do
            if tInstrument.status == 1 then
                MusicCodeData.FileDownload(tInstrument.share_id, false)
            end
        end
    end)

    Event.Reg(self, EventType.OnDownloadMusicCodeData, function(szCode, bNeedPlay)
        self.tbHadLoadCloudList[szCode] = true
        if bNeedPlay then
            local tbData = self.GetMusicByCode(szCode)
            if tbData then
                self.SelecterInstrument(tbData, false)
            end
        end
    end)

	Event.Reg(self, EventType.OnKeyboardDown, function(nKeyCode, _)

        local szKey = tbCCKeyCode2Name[nKeyCode]
        InstrumentData.OnPlayMusicKey(szKey, true)
    end)

    Event.Reg(self, EventType.OnKeyboardUp, function(nKeyCode, _)
        local szKey = tbCCKeyCode2Name[nKeyCode]
        InstrumentData.OnPlayMusicKey(szKey, false)
    end)

    Event.Reg(self, EventType.OnWindowsLostFocus, function()
        self.bIsCtrlDown = false
        self.bIsShiftDown = false
    end)
end

function InstrumentData.ResetCloudData()
    self.tbCloudList = nil -- 云端数据
    MusicCodeData.GetInstrumentList()
end

function InstrumentData.UnInit()
    InstrumentData.StopPlaying()
    InstrumentData.OnPlayMusicKey("SPACE", true)
    self.tbKeys = nil
    self.tbEnableSpecialKey = nil
    self.nTransfer = nil
    self.nSlider = nil
    self.bIsCtrlDown = nil
    self.bIsShiftDown = nil
    self.nStartTime = nil -- 录音开始时间
    self.bRecording = nil
    self.bPlaying = nil
    self.tRecord = nil
    self.tbCloudList = nil -- 云端数据
    self.tbHadLoadCloudList = nil -- 云端数据_已下载
    self.tbKeys = nil
    self.tbBindKey = nil
    Event.UnRegAll(self)
end

-----------------数据层管理--------------------
function InstrumentData.InitKeyList()
    local tbKeys = {}
    local tbInfo = Table_GetInstrumentKeyInfo(self.szType)
    local tbPlayInfo = Table_GetInstrumentPlayInfo(self.szType)
    local tbEnableSpecialKey = {}

    for nIndex, szTone in ipairs(tbIndex2Tone) do
        tbKeys[nIndex] = tbKeys[nIndex] or {}

        if szTone == "DoubleBass" then
            local nStatr = 8 - table.GetCount(tbInfo[szTone]) - 1 -- 倍低特殊排版规则
            nStatr = math.max(nStatr, 0)
            for i, tbKey in ipairs(tbInfo[szTone]) do
                tbKeys[nIndex][i + nStatr] = tbKey
            end
        else
            tbKeys[nIndex] = tbInfo[szTone]
        end
    end

    for szKey, tbInfo in pairs(tbSpecialKey) do
        tbEnableSpecialKey[szKey] = tbInfo.bOpKey
    end

    for _, tbInfo in pairs(tbPlayInfo) do
        local szKey = tbInfo.szKey
        if not tbEnableSpecialKey[szKey] then
            tbEnableSpecialKey[szKey] = tbInfo.bShow
        end
    end

    self.tbKeys = tbKeys
    self.tbEnableSpecialKey = tbEnableSpecialKey
    self.tbBindKey = {}
end

-----------------工具函数----------------------

function InstrumentData.GetKeyList()
    if not self.tbKeys or not self.tbEnableSpecialKey then
        InstrumentData.InitKeyList()
    end

    return self.tbKeys, self.tbEnableSpecialKey
end

function InstrumentData.GetKeyInfo(szKey)
    if not self.tbKeys then
        InstrumentData.InitKeyList()
    end

    for nTone, tLine in ipairs(self.tbKeys) do
        for nIndex, tbKey in ipairs(tLine) do
            if tbKey.szKey == szKey then
                return nTone, nIndex
            end
        end
    end
end

function InstrumentData.OnPlayMusicKey(szKey, bDown)
    if not szKey then
        return
    end

    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    local bShowRule = Storage.InstrumentRule.bShowRule
    if not bShowRule then
        return
    end

    local szType = self.szType
    if not szType then
        return
    end

    if szKey == "KPPlus" then
        szKey = "OEMPLUS"
    end

    if szKey == "KPMinus" then
        szKey = "OEMMINUS"
    end

    local nTone, nIndex = InstrumentData.GetKeyInfo(szKey)
    if not nTone or not nIndex then
        local img = self.tbBindKey[szKey] and self.tbBindKey[szKey].ImgPlayingUp
        if img then
            local eff = UIHelper.GetChildByName(img, "Eff_演奏长按01") or UIHelper.GetChildByName(img, "Eff_演奏长按02")
            UIHelper.SetVisible(img, bDown)
            if eff then
                UIHelper.SetVisible(eff, bDown)
            end
        end
    end

    if szKey == "OEMPLUS" or szKey == "KPPlus" then
        szKey = "="
    end

    if szKey == "OEMMINUS" or szKey == "KPMinus" then
        szKey = "-"
    end

    if bDown and szKey == "-" then
        self.nTransfer = self.nTransfer - 1
        self.nTransfer = math.max(self.nTransfer, MIN_TONE_LEVEL)
    end

    if bDown and szKey == "=" then
        self.nTransfer = self.nTransfer + 1
        self.nTransfer = math.min(self.nTransfer, MAX_TONE_LEVEL)
    end

    if self.nStartTime > 0 then
        local nTime = GetTickCount()
        self.tRecord[nTime - self.nStartTime] = {szKey1 = szKey, szState1 = bDown and "DOWN" or "UP"}
    end

    if tbSpecialKey[szKey] then
        if not self.tbEnableSpecialKey or not self.tbEnableSpecialKey[szKey] then
            return
        end
        if szKey == "CTRL" then
            self.bIsCtrlDown = bDown
        elseif szKey == "SHIFT" then
            self.bIsShiftDown = bDown
        end

        GDAPI_SpecialKeyChange(pPlayer, szType, szKey, bDown)
    else
        GDAPI_NormalKeyDown(pPlayer, szType, szKey, bDown, self.bIsShiftDown, self.bIsCtrlDown, self.nTransfer)
    end

    Event.Dispatch(EventType.OnPressInstrumentKey, nTone, nIndex, bDown)
end

function InstrumentData.BindBtnEvent(bToggle, btn, ImgPlayingUp, szKey, fnCallBack)
    if not btn then
        return
    end

    if self.tbBindKey[szKey] then
        LOG.ERROR("InstrumentData.BindBtnEvent: szKey = %s already binded", szKey)
    end

    self.tbBindKey[szKey] = {btnKey = btn, ImgPlayingUp = ImgPlayingUp}
    UIHelper.SetTouchDownHideTips(btn, false)
    UIHelper.SetSwallowTouches(btn, true)
    if bToggle then
        UIHelper.BindUIEvent(btn, EventType.OnSelectChanged, function(_, bSelected)
            InstrumentData.OnPlayMusicKey(szKey, bSelected)
            if fnCallBack then
                fnCallBack(bSelected)
            end
        end)
    else
        UIHelper.BindUIEvent(btn, EventType.OnTouchBegan, function()
            InstrumentData.OnPlayMusicKey(szKey, true)
            if fnCallBack then
                fnCallBack(true)
            end
        end)

        UIHelper.BindUIEvent(btn, EventType.OnTouchCanceled, function()
            InstrumentData.OnPlayMusicKey(szKey, false)
            if fnCallBack then
                fnCallBack(false)
            end
        end)

        UIHelper.BindUIEvent(btn, EventType.OnTouchEnded, function()
            InstrumentData.OnPlayMusicKey(szKey, false)
            if fnCallBack then
                fnCallBack(false)
            end
        end)
    end
end

-------------IO---------------

function InstrumentData.ExportedFolder()
	return UIHelper.GBKToUTF8(GetStreamAdaptiveDirPath(GetFullPath("InstrumentDir") .. "/"))
end

function InstrumentData.StartRecord()
    if string.is_nil(self.szType) then
        return
    end

    InstrumentData.nStartTime = GetTickCount()
    InstrumentData.tRecord = {}
    InstrumentData.tRecord.nVersion = MusicCodeData.GetCurFileVersion()
    InstrumentData.tRecord.szType = self.szType
    Event.Dispatch(EventType.OnInstrumentRecordStart, InstrumentData.nStartTime)
end

function InstrumentData.StopRecord()
    local tRecord = InstrumentData.tRecord
    InstrumentData.tRecord = nil
    InstrumentData.nStartTime = 0
    Event.Dispatch(EventType.OnInstrumentRecordStop, tRecord)
end

function InstrumentData.SelecterInstrument(tData, bPreset)
    if self.nPlayTimer then
        Timer.DelTimer(self, self.nPlayTimer)
        self.nPlayTimer = nil
    end

    local szType = tData and tData.szType or "sanxian"
    if tData and szType ~= self.szType then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_INSTRUMENT_DATA_ERROR_TYPE)
        return
    end

    InstrumentData.tFileData = clone(tData)
    InstrumentData.tFileSort = {}
    local nMaxTime = 0
    for k, v in pairs(InstrumentData.tFileData) do
        if type(k) == "number" then
            v.nTime = k
            table.insert(InstrumentData.tFileSort, v)
            nMaxTime = math.max(nMaxTime, k)
        end
    end
    table.sort(InstrumentData.tFileSort, function(a, b) return a.nTime < b.nTime end)
    InstrumentData.nMaxTime = nMaxTime
    Event.Dispatch(EventType.OnSelectInstrumentMusic, tData, bPreset)
end

function InstrumentData.StartPlaying()
    if self.nPlayTimer then
        Timer.DelTimer(self, self.nPlayTimer)
        self.nPlayTimer = nil
    end
    local nStartTime = GetTickCount()
    InstrumentData.nPlayTime = nStartTime
    InstrumentData.nPlayIndex = 1
    Event.Dispatch(EventType.OnInstrumentPlayingStart, nStartTime)

    self.nPlayTimer = Timer.AddFrameCycle(self, 1, function()
        local nTime = GetTickCount()
        local nTimeDiff = nTime - InstrumentData.nPlayTime
        for i = InstrumentData.nPlayIndex, #InstrumentData.tFileSort do
            local tData = InstrumentData.tFileSort[i]
            if tData.nTime > nTimeDiff then
                InstrumentData.nPlayIndex = i
                return
            end

            local szKey, szState = tData.szKey1, tData.szState1
            if szKey == "=" then
                szKey = "OEMPLUS"
            end
            if szKey == "-" then
                szKey = "OEMMINUS"
            end

            local tbBindKey = InstrumentData.tbBindKey[szKey]
            if szState == "DOWN" and tbBindKey and tbBindKey.ImgPlayingUp then
                UIHelper.SetVisible(tbBindKey.ImgPlayingUp, true)
                Timer.Add(tbBindKey.ImgPlayingUp, 0.3, function()
                    UIHelper.SetVisible(tbBindKey.ImgPlayingUp, false)
                end)
            end
        end

        if InstrumentData.nPlayIndex >= #InstrumentData.tFileSort then
            InstrumentData.StopPlaying()
        end
    end)
end

function InstrumentData.StopPlaying()
    if self.nPlayTimer then
        Timer.DelTimer(self, self.nPlayTimer)
        self.nPlayTimer = nil
    end
    InstrumentData.tFileData = nil
    InstrumentData.nPlayTime = 0
    Event.Dispatch(EventType.OnInstrumentPlayingStop)
end

function InstrumentData.SaveRecord(tRecord, szFileName)
    if not szFileName or szFileName == "" then
        TipsHelper.ShowImportantRedTip(g_tStrings.STR_INSTRUMENT_CLOUD_EXPORT_NULL)
        return
    end

    if not TextFilterCheck(szFileName) then --过滤文字
        TipsHelper.ShowImportantRedTip(g_tStrings.STR_INSTRUMENT_CLOUD_NAME_ERROR)
        return
    end
    tRecord.szFileName = szFileName
    local szRecordFilePath = MusicCodeData.GetCurrentTimeFilePath()
    SaveLUAData(szRecordFilePath, tRecord)
    if Platform.IsWindows() then
        local dialog = UIHelper.ShowConfirm(g_tStrings.STR_INSTRUMENT_DATA_EXPORT, function ()
            local i, folder, file = 0, GetStreamAdaptiveDirPath('InstrumentDir/')
            CPath.MakeDir(folder)
            OpenFolder(folder)
        end)
        dialog:SetButtonContent("Confirm", g_tStrings.FACE_OPEN_FLODER)
    else
        local scriptView = UIHelper.ShowConfirm(g_tStrings.STR_INSTRUMENT_DATA_EXPORT)
        scriptView:HideButton("Cancel")
    end
end

function InstrumentData.UploadRecord(tRecord, szFileName)
    if not szFileName or szFileName == "" then
        TipsHelper.ShowImportantRedTip(g_tStrings.STR_INSTRUMENT_CLOUD_EXPORT_NULL)
        return
    end

    if not TextFilterCheck(szFileName) then --过滤文字
        TipsHelper.ShowImportantRedTip(g_tStrings.STR_INSTRUMENT_CLOUD_NAME_ERROR)
        return
    end

    tRecord.szFileName = szFileName
    local szRecordFilePath = MusicCodeData.GetCurrentTimeFilePath()
    SaveLUAData(szRecordFilePath, tRecord)
    MusicCodeData.FileUpload(szRecordFilePath)
end

function InstrumentData.Delete(szCode)
    MusicCodeData.DeleteInstrument(szCode)
end

function InstrumentData.DeletBatch(tbCode)
    MusicCodeData.DeletBatchInstrument(tbCode)
end

function InstrumentData.GetCloudList()
    if not self.tbCloudList then
        MusicCodeData.GetInstrumentList()
        return
    end

    return self.tbCloudList
end

function InstrumentData.GetMusicByCode(szCode, bShowList)
    local bHaveCode = self.tbHadLoadCloudList and self.tbHadLoadCloudList[szCode]
    if not bHaveCode then
        return nil
    end

    local szFilePath = MusicCodeData.GetDownloadFilePath(szCode)
    local tData = MusicCodeData.FileProcess(szFilePath)
    if not tData then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_INSTRUMENT_DATA_ERROR)
        return
    end
    if not bShowList and tData.szType ~= self.szType then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_INSTRUMENT_DATA_ERROR_TYPE)
        return
    end
    if not szFilePath or szFilePath == "" then
        return nil
    end

    return tData
end

----------------------工具--------------------------

function InstrumentData.GetMaxTime(tbData, bTickTime)
    local nMaxTime = 0
    for k, v in pairs(tbData) do
        if type(k) == "number" then
            nMaxTime = math.max(nMaxTime, k)
        end
    end

    if bTickTime then
        return nMaxTime
    end

    local nSumSMax = math.floor(nMaxTime / 1000)
    local nMMax, nSMax = nSumSMax / 60, nSumSMax % 60
    local szMaxTime = string.format("%02d:%02d", nMMax, nSMax)
    return szMaxTime
end