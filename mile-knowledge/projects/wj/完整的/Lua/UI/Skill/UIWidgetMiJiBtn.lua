-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetMiJiBtn
-- Date: 2022-11-14 19:57:23
-- Desc: ?
-- ---------------------------------------------------------------------------------

---@class UIWidgetMiJiBtn
local UIWidgetMiJiBtn = class("UIWidgetMiJiBtn")

function UIWidgetMiJiBtn:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetMiJiBtn:OnExit()
    self.bInit = false
    Event.UnRegAll(self)
end

function UIWidgetMiJiBtn:BindUIEvent()
end

function UIWidgetMiJiBtn:RegEvent()

end

return UIWidgetMiJiBtn
