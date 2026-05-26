-- ---------------------------------------------------------------------------------
-- Author: wangying9
-- Name: UIOperationSeasonPreviewReward
-- Date: 2026-04-03 16:06:50
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOperationSeasonPreviewReward = class("UIOperationSeasonPreviewReward")

function UIOperationSeasonPreviewReward:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIOperationSeasonPreviewReward:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationSeasonPreviewReward:BindUIEvent()

end

function UIOperationSeasonPreviewReward:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIOperationSeasonPreviewReward:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIOperationSeasonPreviewReward:UpdateInfo()

end


return UIOperationSeasonPreviewReward