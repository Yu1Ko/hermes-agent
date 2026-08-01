-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIGamepadView
-- Date: 2024-08-15 16:21:14
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIGamepadView = class("UIGamepadView")

function UIGamepadView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIGamepadView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIGamepadView:BindUIEvent()
    
end

function UIGamepadView:RegEvent()
    Event.Reg(self , EventType.On_UI_ShowGamepadCursor, function (bShow)
        if self.WidgetGamepadCursor then
            UIHelper.SetVisible(self.WidgetGamepadCursor , bShow)
            if bShow then
                GamepadData.SetCursorNode(self.WidgetGamepadCursor)
            end
        end
    end)
end

function UIGamepadView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIGamepadView:UpdateInfo()
    if self.WidgetGamepadCursor then
        local bShow = GamepadData.nCurMoveMode == GamepadMoveMode.Cursor
        UIHelper.SetVisible(self.WidgetGamepadCursor , bShow)
        if bShow then
            GamepadData.SetCursorNode(self.WidgetGamepadCursor)
        end
    end
end


return UIGamepadView