-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIShuang11Card
-- Date: 2024-10-18 10:18:50
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIShuang11Card = class("UIShuang11Card")

function UIShuang11Card:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIShuang11Card:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIShuang11Card:BindUIEvent()

end

function UIShuang11Card:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIShuang11Card:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIShuang11Card:UpdateInfo()

end


return UIShuang11Card