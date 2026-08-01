-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationTaskListDouble
-- Date: 2026-03-20
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOperationTaskListDouble = class("UIOperationTaskListDouble")

-- nType: 1 - WidgetTaskListDouble80, 2 - WidgetTaskListDouble100
function UIOperationTaskListDouble:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIOperationTaskListDouble:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationTaskListDouble:BindUIEvent()

end

function UIOperationTaskListDouble:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIOperationTaskListDouble:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  -----------------------------------------

function UIOperationTaskListDouble:UpdateInfo()
end

return UIOperationTaskListDouble
