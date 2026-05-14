-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetCreateRoleCell
-- Date: 2023-05-23 15:09:37
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetCreateRoleCell = class("UIWidgetCreateRoleCell")

function UIWidgetCreateRoleCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetCreateRoleCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetCreateRoleCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSlect04, EventType.OnClick, function()
        -- 如果服务器不让创角
        local moduleServerList = LoginMgr.GetModule(LoginModule.LOGIN_SERVERLIST)
        if not moduleServerList.CanCreateRole() then
            TipsHelper.ShowNormalTip(LoginEventName[LOGIN.CREATE_ROLE_UNABLE_TO_CREATE])
            return
        end

        local moduleRoleList = LoginMgr.GetModule(LoginModule.LOGIN_ROLELIST)
        moduleRoleList.CreateRole()
    end)
end

function UIWidgetCreateRoleCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetCreateRoleCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetCreateRoleCell:UpdateInfo()

end


return UIWidgetCreateRoleCell