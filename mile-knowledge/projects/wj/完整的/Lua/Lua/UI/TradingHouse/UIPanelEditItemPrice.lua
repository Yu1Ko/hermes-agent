-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: PanelEditItemPrice
-- Date: 2023-03-13 16:01:15
-- Desc: ?
-- ---------------------------------------------------------------------------------

local PanelEditItemPrice = class("PanelEditItemPrice")

function PanelEditItemPrice:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function PanelEditItemPrice:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function PanelEditItemPrice:BindUIEvent()
    
end

function PanelEditItemPrice:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function PanelEditItemPrice:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function PanelEditItemPrice:UpdateInfo()
    
end


return PanelEditItemPrice