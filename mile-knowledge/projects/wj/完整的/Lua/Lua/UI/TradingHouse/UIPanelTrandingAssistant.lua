-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelTrandingAssistant
-- Date: 2023-03-27 19:13:53
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelTrandingAssistant = class("UIPanelTrandingAssistant")

function UIPanelTrandingAssistant:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIPanelTrandingAssistant:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelTrandingAssistant:BindUIEvent()
    
end

function UIPanelTrandingAssistant:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPanelTrandingAssistant:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelTrandingAssistant:UpdateInfo()
    
end


return UIPanelTrandingAssistant