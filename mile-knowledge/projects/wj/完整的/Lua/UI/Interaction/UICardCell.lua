-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICardCell
-- Date: 2023-04-11 20:20:38
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICardCell = class("UICardCell")

function UICardCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UICardCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICardCell:BindUIEvent()
    
end

function UICardCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICardCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICardCell:UpdateInfo()
    
end


return UICardCell