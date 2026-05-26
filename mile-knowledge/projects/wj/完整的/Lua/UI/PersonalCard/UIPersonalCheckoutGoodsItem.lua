-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPersonalCheckoutGoodsItem
-- Date: 2024-03-01 17:01:14
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPersonalCheckoutGoodsItem = class("UIPersonalCheckoutGoodsItem")

function UIPersonalCheckoutGoodsItem:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIPersonalCheckoutGoodsItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPersonalCheckoutGoodsItem:BindUIEvent()

end

function UIPersonalCheckoutGoodsItem:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPersonalCheckoutGoodsItem:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPersonalCheckoutGoodsItem:UpdateInfo()

end


return UIPersonalCheckoutGoodsItem