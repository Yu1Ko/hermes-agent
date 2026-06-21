-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationSafeRewardTip2
-- Date: 2026-03-29 22:39:08
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOperationSafeRewardTip2 = class("UIOperationSafeRewardTip2")

function UIOperationSafeRewardTip2:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIOperationSafeRewardTip2:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationSafeRewardTip2:BindUIEvent()

end

function UIOperationSafeRewardTip2:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIOperationSafeRewardTip2:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIOperationSafeRewardTip2:UpdateInfo()

end


return UIOperationSafeRewardTip2