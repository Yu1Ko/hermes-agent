-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIInstrumentMenuTip
-- Date: 2025-07-08 10:16:29
-- Desc: ?
-- ---------------------------------------------------------------------------------
local tbKey2Btn = {
    ["CTRL"] = "BtnTremolo",
    ["SHIFT"] = "BtnOverTone",
    ["SPACE"] = "BtnStop",
    ["UP"] = "BtnSlideUp",
    ["DOWN"] = "BtnSlideDown",
    ["LEFT"] = "BtnSlideLeft",
    ["RIGHT"] = "BtnSlideRight",
}

local tbKey2Suffix = {
    ["CTRL"] = "Tr",
    ["SHIFT"] = "OT",
    ["UP"] = "SU",
    ["DOWN"] = "SD",
    ["LEFT"] = "SL",
    ["RIGHT"] = "SR",
}

local UIInstrumentMenuTip = class("UIInstrumentMenuTip")

function UIInstrumentMenuTip:OnEnter(tbInstrumentData)
    self.InstrumentData = tbInstrumentData
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateSpecialHotKey()
    self:UpdateInfo()
end

function UIInstrumentMenuTip:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIInstrumentMenuTip:BindUIEvent()
    if not self.InstrumentData then
        return
    end

    local fnBindKey = self.InstrumentData.BindBtnEvent
    if IsFunction(fnBindKey) then
        fnBindKey(false, self.BtnTremolo, self.ImgTremoloBtnBg_Up, "CTRL", function (bDown)
            UIHelper.SetVisible(self.ImgTremoloBtnBg_Up, bDown)
            self:UpdateInfo()
        end)
        fnBindKey(false, self.BtnOverTone, self.ImgBtnOverToneBg_Up, "SHIFT", function (bDown)
            UIHelper.SetVisible(self.ImgBtnOverToneBg_Up, bDown)
            self:UpdateInfo()
        end)
        fnBindKey(false, self.BtnStop, self.ImgBtnStopBg_Up, "SPACE", function (bDown)
            UIHelper.SetVisible(self.ImgBtnStopBg_Up, bDown)
            self:UpdateInfo()
        end)
        fnBindKey(false, self.BtnToneUp, self.ImgToneUpBg_Up, "OEMPLUS", function (bDown)
            UIHelper.SetVisible(self.ImgToneUpBg_Up, bDown)
            self:UpdateInfo()
        end)
        fnBindKey(false, self.BtnToneDown, self.ImgToneDownBg_Up, "OEMMINUS", function (bDown)
            UIHelper.SetVisible(self.ImgToneDownBg_Up, bDown)
            self:UpdateInfo()
        end)
        fnBindKey(false, self.BtnSlideUp, self.ImgSlideUpBg_Up, "UP", function (bDown)
            UIHelper.SetVisible(self.ImgSlideUpBg_Up, bDown)
            self:UpdateInfo()
        end)
        fnBindKey(false, self.BtnSlideDown, self.ImgSlideDownBg_Up, "DOWN", function (bDown)
            UIHelper.SetVisible(self.ImgSlideDownBg_Up, bDown)
            self:UpdateInfo()
        end)
        fnBindKey(false, self.BtnSlideLeft, self.ImgSlideLeftBg_Up, "LEFT", function (bDown)
            UIHelper.SetVisible(self.ImgSlideLeftBg_Up, bDown)
            self:UpdateInfo()
        end)
        fnBindKey(false, self.BtnSlideRight, self.ImgSlideRightBg_Up, "RIGHT", function (bDown)
            UIHelper.SetVisible(self.ImgSlideRightBg_Up, bDown)
            self:UpdateInfo()
        end)
    end
end

local tbImgUp = {
    "ImgBtnStopBg_Up",
    "ImgBtnOverToneBg_Up",
    "ImgTremoloBtnBg_Up",
    "ImgToneUpBg_Up",   
    "ImgToneDownBg_Up",
    "ImgSlideUpBg_Up",
    "ImgSlideDownBg_Up",
    "ImgSlideLeftBg_Up",
    "ImgSlideRightBg_Up",
}
function UIInstrumentMenuTip:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function ()
        for _, szImg in pairs(tbImgUp) do
            local img = self[szImg]
            if img then
                UIHelper.SetVisible(img, false)
                local eff = UIHelper.GetChildByName(img, "Eff_演奏长按02")
                if eff then
                    UIHelper.SetVisible(eff, false)
                end
            end
        end
    end)

    Event.Reg(self, EventType.OnWindowsLostFocus, function ()
        for _, szImg in pairs(tbImgUp) do
            local img = self[szImg]
            if img then
                UIHelper.SetVisible(img, false)
                local eff = UIHelper.GetChildByName(img, "Eff_演奏长按01")
                if eff then
                    UIHelper.SetVisible(eff, false)
                end
            end
        end
    end)

    Event.Reg(self, EventType.OnPressInstrumentKey, function ()
        self:UpdateInfo()
    end)
end

function UIInstrumentMenuTip:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIInstrumentMenuTip:UpdateInfo()
    local tbInstrumentData = self.InstrumentData
    if not tbInstrumentData then
        return
    end

    local nCurTransfer = tbInstrumentData.nTransfer
    UIHelper.SetString(self.LabelToneNum, tostring(nCurTransfer))
    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)

    local _, tbEnableSpecialKey = self.InstrumentData.GetKeyList()
    for szKey, szBtn in pairs(tbKey2Btn) do
        local btn = self[szBtn]
        if btn then
            UIHelper.SetVisible(btn, tbEnableSpecialKey[szKey])
        end
    end

    if not tbEnableSpecialKey["UP"] and not tbEnableSpecialKey["DOWN"] then
        UIHelper.SetVisible(self.WidgetBtnGlideTone, false)
        UIHelper.LayoutDoLayout(self.LayoutWidgetBtn)
    end

    UIHelper.SetVisible(self.WidgetBtnListSL, tbEnableSpecialKey["LEFT"])
    UIHelper.SetVisible(self.WidgetBtnListSR, tbEnableSpecialKey["RIGHT"])
    UIHelper.LayoutDoLayout(self.LayoutWidgetBtn1)
end

function UIInstrumentMenuTip:UpdateSpecialHotKey()
    local tbPlayInfo = Table_GetInstrumentPlayInfo(self.InstrumentData.szType)
    if tbPlayInfo then
        for _, tbInfo in pairs(tbPlayInfo) do
            local szKey = tbInfo.szKey
            local szTitle = tbInfo.szTitle and UIHelper.GBKToUTF8(tbInfo.szTitle)
            local szSuffix = tbKey2Suffix[szKey]
            local label = self["LabelMusicTitle_"..szSuffix]
            if label then
                UIHelper.SetString(label, szTitle)
            end
        end
    end

    if not Platform.IsWindows() then
        UIHelper.SetVisible(self.LabelMusicKey_TU, false)
        UIHelper.SetVisible(self.LabelMusicKey_TD, false)
        UIHelper.SetVisible(self.LabelMusicKey_SU, false)
        UIHelper.SetVisible(self.LabelMusicKey_SD, false)
        UIHelper.SetVisible(self.LabelMusicKey_OT, false)
        UIHelper.SetVisible(self.LabelMusicKey_Tr, false)
        UIHelper.SetVisible(self.LabelMusicKey_St, false)
        return
    end

    UIHelper.SetString(self.LabelMusicKey_TU, "+")
    UIHelper.SetString(self.LabelMusicKey_TD, "-")
    UIHelper.SetString(self.LabelMusicKey_SU, "↑")
    UIHelper.SetString(self.LabelMusicKey_SD, "↓")
    UIHelper.SetString(self.LabelMusicKey_SL, "←")
    UIHelper.SetString(self.LabelMusicKey_SR, "→")
    UIHelper.SetString(self.LabelMusicKey_OT, "SHIFT")
    UIHelper.SetString(self.LabelMusicKey_Tr, "CTRL")
    UIHelper.SetString(self.LabelMusicKey_St, "SPACE")
end


return UIInstrumentMenuTip