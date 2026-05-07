-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildFloorEditorCell
-- Date: 2023-12-05 17:32:24
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildFloorEditorCell = class("UIHomelandBuildFloorEditorCell")

function UIHomelandBuildFloorEditorCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIHomelandBuildFloorEditorCell:OnExit()
    self.bInit = false
end

function UIHomelandBuildFloorEditorCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogLayer, EventType.OnClick, function(btn)

    end)

end

function UIHomelandBuildFloorEditorCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandBuildFloorEditorCell:UpdateInfo()

end


return UIHomelandBuildFloorEditorCell