-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIFittingCell
-- Date: 2024-01-31 19:42:11
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIFittingCell = class("UIFittingCell")

function UIFittingCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIFittingCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIFittingCell:BindUIEvent()

end

function UIFittingCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIFittingCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIFittingCell:UpdateInfo()

end


return UIFittingCell
