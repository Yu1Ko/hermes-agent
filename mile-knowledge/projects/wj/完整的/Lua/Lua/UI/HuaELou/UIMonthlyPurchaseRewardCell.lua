-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIMonthlyPurchaseRewardCell
-- Date: 2023-06-05 16:34:45
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIMonthlyPurchaseRewardCell = class("UIMonthlyPurchaseRewardCell")

function UIMonthlyPurchaseRewardCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIMonthlyPurchaseRewardCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIMonthlyPurchaseRewardCell:BindUIEvent()
    
end

function UIMonthlyPurchaseRewardCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIMonthlyPurchaseRewardCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIMonthlyPurchaseRewardCell:UpdateInfo()
    
end


return UIMonthlyPurchaseRewardCell