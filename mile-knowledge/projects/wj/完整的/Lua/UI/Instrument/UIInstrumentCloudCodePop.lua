-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIInstrumentCloudCodePop
-- Date: 2024-03-19 19:50:36
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIInstrumentCloudCodePop = class("UIInstrumentCloudCodePop")

function UIInstrumentCloudCodePop:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIInstrumentCloudCodePop:OnExit()
    self.bInit = false
end

function UIInstrumentCloudCodePop:BindUIEvent()
    UIHelper.RegisterEditBoxChanged(self.EditBox, function()
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        if self.bBusy then
            TipsHelper.ShowNormalTip("正在导入曲谱，请稍候")
            return
        end
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function(btn)
        if self.bBusy then
            TipsHelper.ShowNormalTip("正在导入曲谱，请稍候")
            return
        end
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnPrint, EventType.OnClick, function(btn)
        local szCode = UIHelper.GetText(self.EditBox)
        MusicCodeData.FileDownload(UIHelper.UTF8ToGBK(szCode), true)
        self.bBusy = true
        TipsHelper.ShowNormalTip("正在导入曲谱，请稍候")
        UIHelper.SetButtonState(self.BtnPrint, BTN_STATE.Disable, "正在导入曲谱，请稍候")
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnPaste, EventType.OnClick, function(btn)
        local szCode = GetClipboard()
        szCode = string.match(szCode, "[0-9A-Za-z]*")
        if not string.is_nil(szCode) then
            UIHelper.SetText(self.EditBox, szCode)
            self:UpdateInfo()
        end
    end)
end

function UIInstrumentCloudCodePop:RegEvent()
    Event.Reg(self, "CURL_REQUEST_RESULT", function ()
        local szKey = arg0
        local bSuccess = arg1
        local szValue = arg2

        if szKey == "GET_INSTRUMENT" then
            self.bBusy = false
        end
    end)
end

function UIInstrumentCloudCodePop:UpdateInfo()
    if self.bBusy then
        return
    end

    local szCode = UIHelper.GetText(self.EditBox)
    szCode = string.match(szCode, "[0-9A-Za-z]*")
    UIHelper.SetText(self.EditBox, szCode)
    UIHelper.SetButtonState(self.BtnPrint, BTN_STATE.Normal)
end


return UIInstrumentCloudCodePop