-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIShoppingRecommendCell
-- Date: 2023-08-16 20:09:53
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIShoppingRecommendCell = class("UIShoppingRecommendCell")

function UIShoppingRecommendCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIShoppingRecommendCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIShoppingRecommendCell:BindUIEvent()

end

function UIShoppingRecommendCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIShoppingRecommendCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIShoppingRecommendCell:UpdateInfo()

end


return UIShoppingRecommendCell