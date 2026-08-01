-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomeAchievementPageViewCell
-- Date: 2023-10-31 17:31:12
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomeAchievementPageViewCell = class("UIHomeAchievementPageViewCell")

function UIHomeAchievementPageViewCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIHomeAchievementPageViewCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomeAchievementPageViewCell:BindUIEvent()
    
end

function UIHomeAchievementPageViewCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomeAchievementPageViewCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomeAchievementPageViewCell:UpdateInfo()
    
end


return UIHomeAchievementPageViewCell