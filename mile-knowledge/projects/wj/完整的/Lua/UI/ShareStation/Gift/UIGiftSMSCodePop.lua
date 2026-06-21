-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIGiftSMSCodePop
-- Date: 2025-09-22 15:08:18
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIGiftSMSCodePop = class("UIGiftSMSCodePop")

function UIGiftSMSCodePop:OnEnter(nType, fnSMSConfirm)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nType = nType
    self.fnSMSConfirm = fnSMSConfirm
    self:UpdateInfo()
    self:UpdateBtnState()
end

function UIGiftSMSCodePop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIGiftSMSCodePop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnGetCode, EventType.OnClick, function(btn)
        local bRet = GiftHelper.GetSMSCode(self.nType)
        if bRet then
            UIHelper.SetText(self.EditBox, "")
            self:UpdateInfo()
            self:UpdateBtnState()
            TipsHelper.ShowNormalTip("短信验证码已发送")
        end
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function(btn)
        if not self.fnSMSConfirm then
            return
        end

        local szCode = UIHelper.GetText(self.EditBox) or ""
        self.fnSMSConfirm(self.nType, szCode)
    end)

    UIHelper.RegisterEditBoxChanged(self.EditBox, function ()
        self:UpdateBtnState()
    end)
end

function UIGiftSMSCodePop:RegEvent()
    Event.Reg(self, "ON_GET_SMS_CODE_NOTIFY", function (nRet)
        UIHelper.SetText(self.EditBox, "")
        self:UpdateInfo()
        self:UpdateBtnState()
    end)

    Event.Reg(self, "CHANGE_NEW_EXT_POINT_NOTIFY", function ()
        if arg0 == EXT_POINT.WITHDRAW_TIMES then
            UIMgr.Close(self)
        end
    end)

    Event.Reg(self, "ON_WITHDRAW_CODE_FAILED", function ()
        self:UpdateInfo()
    end)
end

function UIGiftSMSCodePop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIGiftSMSCodePop:UpdateInfo()
    Timer.DelAllTimer(self)
    local tTipStatus = GiftHelper.GetTipStatus()
    if not tTipStatus then
        return
    end

    local nCreatTime = tTipStatus.nCreateTime
    local nIntervalSecond = tTipStatus.nIntervalSecond
    local nCurrentTime = GetCurrentTime()
    local nRemainSecond = nIntervalSecond - (nCurrentTime - nCreatTime)

    if nRemainSecond > 0 then
        UIHelper.SetButtonState(self.BtnGetCode, BTN_STATE.Disable)
        Timer.AddCountDown(self, nRemainSecond, function (nRemain)
            UIHelper.SetString(self.LabelGetCode, nRemain .. "s")
        end,
        function ()
            self:UpdateInfo()
        end)
    else
        UIHelper.SetButtonState(self.BtnGetCode, BTN_STATE.Normal)
        UIHelper.SetString(self.LabelGetCode, g_tStrings.WITHDRAW_GET_CODE)
    end
end

function UIGiftSMSCodePop:UpdateBtnState()
    local tTipStatus = GiftHelper.GetTipStatus()
    if not tTipStatus then
        UIHelper.SetButtonState(self.BtnConfirm, BTN_STATE.Disable)
        return
    end

    local szCode = UIHelper.GetText(self.EditBox) or ""
    local bEnable = tTipStatus.nSMSCodeLength == string.len(szCode)
    UIHelper.SetButtonState(self.BtnConfirm, bEnable and BTN_STATE.Normal or BTN_STATE.Disable)
end
return UIGiftSMSCodePop