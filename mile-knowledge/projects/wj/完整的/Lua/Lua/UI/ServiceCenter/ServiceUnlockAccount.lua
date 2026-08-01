-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: ServiceUnlockAccount
-- Date: 2024-03-21 15:54:55
-- Desc: 账号异常登录解锁
-- ---------------------------------------------------------------------------------
local MAX_TIME = 10
local ServiceUnlockAccount = class("ServiceUnlockAccount")
local UNLOCK_TYPE = {
    CODE = 1,
    IDCARD = 2,
    MESSAGE = 3,
    SERVICE = 4,
    WECHAT = 5,
    NOPHONE = 6,
}
local REGET_CD = 60 * 1000

function ServiceUnlockAccount:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function ServiceUnlockAccount:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function ServiceUnlockAccount:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick , function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnGetCode, EventType.OnClick , function ()
        RemoteCallToServer("OnAccountSecuritySendSMS")
        self.nRegetTime = GetTickCount()
        self.nRegetTimer = Timer.AddCycle(self, 0.5, function()
            self:UpdateRegetBtn()
        end)
    end)

    UIHelper.BindUIEvent(self.BtnGetCodeIDCard, EventType.OnClick , function ()
        RemoteCallToServer("OnAccountSecuritySendSMS")
    end)

    UIHelper.BindUIEvent(self.BtnAccept, EventType.OnClick , function ()
        if ServiceCenterData.SafeReminder.nCount >= MAX_TIME then
            TipsHelper.ShowNormalTip(g_tStrings.SAFE_REMINDER_LIMIT)
			return
		end

        local editBox = self.nUnlockType == UNLOCK_TYPE.CODE and self.EditBoxSearch or self.EditBoxSearchIDCard
		local szText = UIHelper.GetText(editBox)

		if szText == "" or string.len(szText) ~= 6 then
            TipsHelper.ShowNormalTip(g_tStrings.SAFE_REMINDER_CODE_LIMIT)
			return
		end
        UIHelper.SetText(editBox  , "")
        
        TipsHelper.ShowNormalTip("正在验证，请稍后.....")
		RemoteCallToServer("OnAccountSecurityUserUnlock", self.nUnlockType, UIHelper.UTF8ToGBK(szText))
    end)

    UIHelper.BindUIEvent(self.BtnGoService, EventType.OnClick , function ()
        APIHelper.OpenURL_VerifyPhone()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.TogCode, EventType.OnSelectChanged , function (_,bSelect)
        UIHelper.SetVisible(self.WidgetCode , self.bBindPhone and bSelect)
        if bSelect then
            self:SetUnlockType(UNLOCK_TYPE.CODE)
            self:UpdateUnBindState()
        end
        UIHelper.LayoutDoLayout(self.LayoutBtns)
    end)

    UIHelper.BindUIEvent(self.TogMessage, EventType.OnSelectChanged , function (_,bSelect)
        UIHelper.SetVisible(self.WidgetMessage , self.bBindPhone and bSelect)
        if bSelect then
            self:SetUnlockType(UNLOCK_TYPE.MESSAGE)
            self:UpdateUnBindState()
        end
    end)

    UIHelper.BindUIEvent(self.TogWeChat, EventType.OnSelectChanged , function (_,bSelect)
        UIHelper.SetVisible(self.WidgetWeChat , self.bBindPhone and bSelect)
        if bSelect then
            self:SetUnlockType(UNLOCK_TYPE.WECHAT)
            self:UpdateUnBindState()
        end
    end)

    UIHelper.BindUIEvent(self.TogService, EventType.OnSelectChanged , function (_,bSelect)
        UIHelper.SetVisible(self.WidgetService , self.bBindPhone and bSelect)
        if bSelect then
            self:SetUnlockType(UNLOCK_TYPE.SERVICE)
            self:UpdateUnBindState()
        end
    end)

    UIHelper.BindUIEvent(self.TogIDCard, EventType.OnSelectChanged , function (_,bSelect)
        UIHelper.SetVisible(self.WidgetIDCard , bSelect)
        if bSelect then
            self:SetUnlockType(UNLOCK_TYPE.IDCARD)
            self:UpdateUnBindState()
        end
        UIHelper.LayoutDoLayout(self.LayoutBtns)
    end)
end

function ServiceUnlockAccount:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function ServiceUnlockAccount:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function ServiceUnlockAccount:UpdateInfo()
    self:SetUnlockType(UNLOCK_TYPE.CODE)
    self.bBindPhone = ServiceCenterData:IsPhoneBind()
    UIHelper.ToggleGroupAddToggle(self.toggleGroup , self.TogCode)
    UIHelper.ToggleGroupAddToggle(self.toggleGroup , self.TogMessage)
    UIHelper.ToggleGroupAddToggle(self.toggleGroup , self.TogWeChat)
    UIHelper.ToggleGroupAddToggle(self.toggleGroup , self.TogService)
    UIHelper.ToggleGroupAddToggle(self.toggleGroup , self.TogIDCard)
    UIHelper.SetToggleGroupSelected(self.toggleGroup , 0)

    UIHelper.SetVisible(self.BtnAccept , self.bBindPhone)
    UIHelper.SetVisible(self.WidgetCode , self.bBindPhone)
    self:UpdateUnBindState()


    UIHelper.SetText(self.EditBoxSearch  , "")
    UIHelper.SetString(self.LabelPart1Content , "用绑定手机编辑短信115游戏账号发送至106929996333")

end

function ServiceUnlockAccount:UpdateUnBindState()
    UIHelper.SetVisible(self.WidgetNoPhone , not self.bBindPhone and self.nUnlockType ~= UNLOCK_TYPE.IDCARD)
    UIHelper.SetVisible(self.BtnGoService , not self.bBindPhone and self.nUnlockType ~= UNLOCK_TYPE.IDCARD)
    local bShowAccept = (self.nUnlockType == UNLOCK_TYPE.CODE and self.bBindPhone) or self.nUnlockType == UNLOCK_TYPE.IDCARD
    UIHelper.SetVisible(self.BtnAccept , bShowAccept)
    UIHelper.LayoutDoLayout(self.LayoutBtns)
end

function ServiceUnlockAccount:SetUnlockType(nType)
    self.nUnlockType = nType
end

function ServiceUnlockAccount:UpdateRegetBtn()
	if not self.nRegetTime then
		return
	end
    
	local nTime = GetTickCount() - self.nRegetTime
	local szText = g_tStrings.STR_REGET_TEXT_MESSAGE
	if nTime > REGET_CD then
		UIHelper.SetButtonState(self.BtnGetCode, BTN_STATE.Normal)
        UIHelper.SetString(self.LabelGetCode , szText)
		self.nRegetTime = nil
        Timer.DelTimer(self, self.nRegetTimer)
		return 
	end

	local nTime = math.floor((REGET_CD - nTime) / 1000)
    local szTime = FormatString(g_tStrings.STR_ALL_PARENTHESES, nTime)
    UIHelper.SetString(self.LabelGetCode , szText .. szTime)
    UIHelper.SetButtonState(self.BtnGetCode, BTN_STATE.Disable)
end

return ServiceUnlockAccount