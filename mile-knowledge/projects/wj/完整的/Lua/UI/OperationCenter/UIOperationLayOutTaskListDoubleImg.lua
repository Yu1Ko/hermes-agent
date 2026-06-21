-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationLayOutTaskListDoubleImg
-- Date: 2026-03-20
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOperationLayOutTaskListDoubleImg = class("UIOperationLayOutTaskListDoubleImg")

function UIOperationLayOutTaskListDoubleImg:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIOperationLayOutTaskListDoubleImg:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationLayOutTaskListDoubleImg:BindUIEvent()

end

function UIOperationLayOutTaskListDoubleImg:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIOperationLayOutTaskListDoubleImg:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  -----------------------------------------------------

function UIOperationLayOutTaskListDoubleImg:UpdateInfo()

end


return UIOperationLayOutTaskListDoubleImg
