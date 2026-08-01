-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationSafeRewardTip1
-- Date: 2026-03-29 22:38:47
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOperationSafeRewardTip1 = class("UIOperationSafeRewardTip1")

function UIOperationSafeRewardTip1:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIOperationSafeRewardTip1:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationSafeRewardTip1:BindUIEvent()

end

function UIOperationSafeRewardTip1:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIOperationSafeRewardTip1:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIOperationSafeRewardTip1:UpdateInfo()

end


return UIOperationSafeRewardTip1