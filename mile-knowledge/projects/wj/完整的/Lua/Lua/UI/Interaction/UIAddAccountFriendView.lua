-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIAddAccountFriendView
-- Date: 2022-11-29 15:56:39
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIAddAccountFriendView = class("UIAddAccountFriendView")

function UIAddAccountFriendView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIAddAccountFriendView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAddAccountFriendView:BindUIEvent()
end

function UIAddAccountFriendView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIAddAccountFriendView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAddAccountFriendView:UpdateInfo()
end

return UIAddAccountFriendView