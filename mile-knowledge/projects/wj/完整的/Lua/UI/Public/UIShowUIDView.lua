-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIShowUIDView
-- Date: 2024-06-27 10:29:11
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIShowUIDView = class("UIShowUIDView")

function UIShowUIDView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    UIHelper.SetString(self.LabelRightBottom, "UID:" .. UI_GetClientPlayerGlobalID())
end

function UIShowUIDView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIShowUIDView:BindUIEvent()

end

function UIShowUIDView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIShowUIDView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIShowUIDView:UpdateInfo()

end


return UIShowUIDView