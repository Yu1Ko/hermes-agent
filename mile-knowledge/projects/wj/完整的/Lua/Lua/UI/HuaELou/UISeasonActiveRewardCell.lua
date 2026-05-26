-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UISeasonActiveRewardCell
-- Date: 2023-06-15 16:06:50
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UISeasonActiveRewardCell = class("UISeasonActiveRewardCell")

function UISeasonActiveRewardCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UISeasonActiveRewardCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISeasonActiveRewardCell:BindUIEvent()
    
end

function UISeasonActiveRewardCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UISeasonActiveRewardCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UISeasonActiveRewardCell:UpdateInfo()
    
end


return UISeasonActiveRewardCell