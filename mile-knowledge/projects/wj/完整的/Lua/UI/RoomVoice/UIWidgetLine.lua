-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetLine
-- Date: 2025-09-17 16:22:13
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetLine = class("UIWidgetLine")

function UIWidgetLine:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetLine:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetLine:BindUIEvent()
    
end

function UIWidgetLine:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetLine:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetLine:UpdateInfo()
    
end


return UIWidgetLine