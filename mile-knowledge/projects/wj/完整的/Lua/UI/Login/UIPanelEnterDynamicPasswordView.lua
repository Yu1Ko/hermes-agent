-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelEnterDynamicPasswordView
-- Date: 2023-06-14 15:33:47
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelEnterDynamicPasswordView = class("UIPanelEnterDynamicPasswordView")

function UIPanelEnterDynamicPasswordView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIPanelEnterDynamicPasswordView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelEnterDynamicPasswordView:BindUIEvent()

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        g_tbLoginData.bVerifyMiBao = true
        local szDynamicPassword = UIHelper.GetString(self.EditBox)
        LoginMgr.SetWaiting(true, g_tStrings.tbLoginString.LOADING)
        Login_MibaoVerify(szDynamicPassword)
        UIMgr.Close(self)
    end)
end

function UIPanelEnterDynamicPasswordView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPanelEnterDynamicPasswordView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelEnterDynamicPasswordView:UpdateInfo()
    
end


return UIPanelEnterDynamicPasswordView