-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIEmpty
-- Date: 2023-04-21 17:50:23
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIEmpty = class("UIEmpty")

function UIEmpty:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIEmpty:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIEmpty:BindUIEvent()
    
end

function UIEmpty:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIEmpty:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIEmpty:UpdateInfo()
    
end


return UIEmpty