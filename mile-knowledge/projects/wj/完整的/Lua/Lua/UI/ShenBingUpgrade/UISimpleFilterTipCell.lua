-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UISimpleFilterTipCell
-- Date: 2024-04-22 21:05:40
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UISimpleFilterTipCell = class("UISimpleFilterTipCell")

function UISimpleFilterTipCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UISimpleFilterTipCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISimpleFilterTipCell:BindUIEvent()

end

function UISimpleFilterTipCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UISimpleFilterTipCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UISimpleFilterTipCell:UpdateInfo()

end


return UISimpleFilterTipCell