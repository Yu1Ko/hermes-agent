-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UISetCodeUseView
-- Date: 2024-03-19 19:50:36
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UISetCodeUseView = class("UISetCodeUseView")

function UISetCodeUseView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    EquipCodeData.LoginAccount(false)
    self:UpdateInfo()
end

function UISetCodeUseView:OnExit()
    self.bInit = false
end

function UISetCodeUseView:BindUIEvent()
    UIHelper.RegisterEditBoxChanged(self.EditBox, function()
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnPrint, EventType.OnClick, function(btn)
        local szCode = UIHelper.GetText(self.EditBox)

        EquipCodeData.ReqGetEquip(szCode)
        TipsHelper.ShowNormalTip("正在导入配装，请稍候")
        UIHelper.SetButtonState(self.BtnPrint, BTN_STATE.Disable, "正在导入配装，请稍候")
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

function UISetCodeUseView:RegEvent()
    Event.Reg(self, EventType.OnEquipCodeRsp, function (szKey, tInfo)
        if szKey == "LOGIN_ACCOUNT_EQUIPCODE" then
            if EquipCodeData.szSessionID then
                self.bLoginWeb = true
                self:UpdateInfo()
            else
                TipsHelper.ShowNormalTip("连接云端服务器失败，请稍候重试")
                UIMgr.Close(self)
            end
        elseif szKey == "GET_EQUIPS" then
            if tInfo and tInfo.code and tInfo.code == 1 then
                UIMgr.Close(self)
            else
                self:UpdateInfo()
            end
        end
    end)

    Event.Reg(self, "LOGIN_NOTIFY", function(nEvent)
		if nEvent == LOGIN.REQUEST_LOGIN_GAME_SUCCESS or nEvent == LOGIN.MISS_CONNECTION then
			Timer.Add(self, 0.3, function ()
                UIMgr.Close(self)
            end)
		end
    end)
end

function UISetCodeUseView:UpdateInfo()
    local szCode = UIHelper.GetText(self.EditBox)
    szCode = string.match(szCode, "[0-9A-Za-z]*")
    UIHelper.SetText(self.EditBox, szCode)

    UIHelper.SetButtonState(self.BtnPrint, BTN_STATE.Normal)
    if not self.bLoginWeb then
        UIHelper.SetButtonState(self.BtnPrint, BTN_STATE.Disable, "正在登录云端服务器，请稍候")
    elseif not string.is_nil(szCode) then
        UIHelper.SetButtonState(self.BtnPrint, BTN_STATE.Normal)
    else
        UIHelper.SetButtonState(self.BtnPrint, BTN_STATE.Disable, "请输入配装方案码")
    end
end


return UISetCodeUseView