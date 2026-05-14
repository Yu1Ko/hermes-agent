-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIFriendEmail02View
-- Date: 2022-11-15 17:21:59
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIFriendEmail02View = class("UIFriendEmail02View")

function UIFriendEmail02View:OnEnter(nIndex, szLabelEmail, szLabelDays, bImgLtem, bItemFlag, bMoneyFlag, bReadFlag)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIFriendEmail02View:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIFriendEmail02View:BindUIEvent()
end

function UIFriendEmail02View:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIFriendEmail02View:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIFriendEmail02View:UpdateInfo()
end


return UIFriendEmail02View