-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationCommon
-- Date: 2026-03-19 16:32:07
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOperationCommon = class("UIOperationCommon")

function UIOperationCommon:OnEnter(nOperationID, nID, tComponentContext)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nID = nID
    self.nOperationID = nOperationID
    self.tComponentContext = tComponentContext

    self:UpdateInfo()
end

function UIOperationCommon:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationCommon:BindUIEvent()

end

function UIOperationCommon:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIOperationCommon:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIOperationCommon:UpdateInfo()
end

return UIOperationCommon