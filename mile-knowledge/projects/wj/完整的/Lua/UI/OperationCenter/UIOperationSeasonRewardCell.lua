-- ---------------------------------------------------------------------------------
-- Author: wangying9
-- Name: UIOperationSeasonRewardCell
-- Date: 2026-04-03 14:34:22
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOperationSeasonRewardCell = class("UIOperationSeasonRewardCell")

function UIOperationSeasonRewardCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIOperationSeasonRewardCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationSeasonRewardCell:BindUIEvent()

end

function UIOperationSeasonRewardCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIOperationSeasonRewardCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIOperationSeasonRewardCell:UpdateInfo()

end


return UIOperationSeasonRewardCell