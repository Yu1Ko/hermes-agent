-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationScrollViewContentList
-- Date: 2026-03-20
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOperationScrollViewContentList = class("UIOperationScrollViewContentList")

function UIOperationScrollViewContentList:OnEnter(nOperationID, nID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nOperationID = nOperationID
    self.nID = nID

    self:UpdateInfo()
end

function UIOperationScrollViewContentList:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationScrollViewContentList:BindUIEvent()

end

function UIOperationScrollViewContentList:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIOperationScrollViewContentList:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  -------------------------------------------------------

function UIOperationScrollViewContentList:UpdateInfo()

end

return UIOperationScrollViewContentList
