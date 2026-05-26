-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPersonalPhoto
-- Date: 2024-02-05 16:06:37
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPersonalPhoto = class("UIPersonalPhoto")

function UIPersonalPhoto:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIPersonalPhoto:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPersonalPhoto:BindUIEvent()

end

function UIPersonalPhoto:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPersonalPhoto:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPersonalPhoto:UpdateInfo()

end


return UIPersonalPhoto