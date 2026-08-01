-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandMyHomeRightPopLogCell
-- Date: 2023-09-25 17:28:06
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandMyHomeRightPopLogCell = class("UIHomelandMyHomeRightPopLogCell")

function UIHomelandMyHomeRightPopLogCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIHomelandMyHomeRightPopLogCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomelandMyHomeRightPopLogCell:BindUIEvent()
    
end

function UIHomelandMyHomeRightPopLogCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandMyHomeRightPopLogCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomelandMyHomeRightPopLogCell:UpdateInfo()
    
end


return UIHomelandMyHomeRightPopLogCell