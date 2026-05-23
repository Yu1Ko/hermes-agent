-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIQuickOperationTitle
-- Date: 2023-03-20 20:19:48
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIQuickOperationTitle = class("UIQuickOperationTitle")

function UIQuickOperationTitle:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIQuickOperationTitle:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIQuickOperationTitle:BindUIEvent()
    
end

function UIQuickOperationTitle:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIQuickOperationTitle:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIQuickOperationTitle:UpdateInfo()
    
end


return UIQuickOperationTitle