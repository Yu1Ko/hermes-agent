-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIFriendRecruitRewardCell
-- Date: 2023-05-23 16:16:43
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIFriendRecruitRewardCell = class("UIFriendRecruitRewardCell")

function UIFriendRecruitRewardCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIFriendRecruitRewardCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIFriendRecruitRewardCell:BindUIEvent()
    
end

function UIFriendRecruitRewardCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIFriendRecruitRewardCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIFriendRecruitRewardCell:UpdateInfo()
    
end


return UIFriendRecruitRewardCell