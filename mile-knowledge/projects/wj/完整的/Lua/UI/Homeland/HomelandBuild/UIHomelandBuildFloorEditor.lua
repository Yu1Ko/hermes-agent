-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildFloorEditor
-- Date: 2023-12-05 17:32:09
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildFloorEditor = class("UIHomelandBuildFloorEditor")

function UIHomelandBuildFloorEditor:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIHomelandBuildFloorEditor:OnExit()
    self.bInit = false
end

function UIHomelandBuildFloorEditor:BindUIEvent()

end

function UIHomelandBuildFloorEditor:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandBuildFloorEditor:UpdateInfo()

end


return UIHomelandBuildFloorEditor