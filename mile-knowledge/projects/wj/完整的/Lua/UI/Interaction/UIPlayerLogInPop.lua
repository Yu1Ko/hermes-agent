-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPlayerLogInPop
-- Date: 2023-03-07 16:46:00
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPlayerLogInPop = class("UIPlayerLogInPop")

function UIPlayerLogInPop:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIPlayerLogInPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPlayerLogInPop:BindUIEvent()
end

function UIPlayerLogInPop:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPlayerLogInPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPlayerLogInPop:UpdateInfo(tInfo)
end


return UIPlayerLogInPop