-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: PvPPlayerNum
-- Date: 2023-05-09 14:27:34
-- Desc: ?
-- ---------------------------------------------------------------------------------

local PvPPlayerNum = class("PvPPlayerNum")

function PvPPlayerNum:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function PvPPlayerNum:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function PvPPlayerNum:BindUIEvent()
    
end

function PvPPlayerNum:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function PvPPlayerNum:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function PvPPlayerNum:UpdateInfo()
    
end


return PvPPlayerNum