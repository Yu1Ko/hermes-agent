-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIQuickOperationBtn
-- Date: 2023-03-21 11:16:51
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIQuickOperationBtn = class("UIQuickOperationBtn")

function UIQuickOperationBtn:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIQuickOperationBtn:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIQuickOperationBtn:BindUIEvent()
    
end

function UIQuickOperationBtn:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIQuickOperationBtn:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIQuickOperationBtn:UpdateInfo()
    
end


return UIQuickOperationBtn