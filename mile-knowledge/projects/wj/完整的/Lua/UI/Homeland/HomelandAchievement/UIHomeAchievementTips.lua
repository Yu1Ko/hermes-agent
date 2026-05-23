-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomeAchievementTips
-- Date: 2023-07-19 20:01:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomeAchievementTips = class("UIHomeAchievementTips")

function UIHomeAchievementTips:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIHomeAchievementTips:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomeAchievementTips:BindUIEvent()
    
end

function UIHomeAchievementTips:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomeAchievementTips:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomeAchievementTips:UpdateInfo()
    
end


return UIHomeAchievementTips