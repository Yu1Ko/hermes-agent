-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICommonSignInCell
-- Date: 2023-07-24 16:57:31
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICommonSignInCell = class("UICommonSignInCell")

function UICommonSignInCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UICommonSignInCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICommonSignInCell:BindUIEvent()

end

function UICommonSignInCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICommonSignInCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICommonSignInCell:UpdateInfo()

end


return UICommonSignInCell