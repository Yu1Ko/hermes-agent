-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UISeasonRewardCell
-- Date: 2023-06-15 14:34:22
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UISeasonRewardCell = class("UISeasonRewardCell")

function UISeasonRewardCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UISeasonRewardCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISeasonRewardCell:BindUIEvent()
    
end

function UISeasonRewardCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UISeasonRewardCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UISeasonRewardCell:UpdateInfo()
    
end


return UISeasonRewardCell