-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationPublicTogSecondTwoLines
-- Date: 2026-03-20
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOperationPublicTogSecondTwoLines = class("UIOperationPublicTogSecondTwoLines")

function UIOperationPublicTogSecondTwoLines:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIOperationPublicTogSecondTwoLines:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationPublicTogSecondTwoLines:BindUIEvent()

end

function UIOperationPublicTogSecondTwoLines:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIOperationPublicTogSecondTwoLines:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  -------------------------------------------------------

function UIOperationPublicTogSecondTwoLines:UpdateInfo()

end


return UIOperationPublicTogSecondTwoLines
