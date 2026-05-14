-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandMainPage
-- Date: 2023-03-27 16:52:02
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandMainPage = class("UIHomelandMainPage")

function UIHomelandMainPage:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIHomelandMainPage:OnExit()
    self.bInit = false
end

function UIHomelandMainPage:BindUIEvent()

end

function UIHomelandMainPage:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandMainPage:UpdateInfo()

end


return UIHomelandMainPage