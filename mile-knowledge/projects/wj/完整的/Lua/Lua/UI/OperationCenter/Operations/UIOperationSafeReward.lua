-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationSafeReward
-- Date: 2026-03-29 22:28:21
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOperationSafeReward = class("UIOperationSafeReward")

function UIOperationSafeReward:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIOperationSafeReward:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationSafeReward:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSafeReward1, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetSafeRewardTip1, self.BtnSafeReward1)
    end)

    UIHelper.BindUIEvent(self.BtnSafeReward2, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetSafeRewardTip2, self.BtnSafeReward2)
    end)
end

function UIOperationSafeReward:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIOperationSafeReward:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIOperationSafeReward:UpdateInfo()

end


return UIOperationSafeReward