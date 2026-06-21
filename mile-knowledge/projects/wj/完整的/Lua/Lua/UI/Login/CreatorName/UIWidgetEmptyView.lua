-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetEmptyView
-- Date: 2023-07-26 16:58:50
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetEmptyView = class("UIWidgetEmptyView")

function UIWidgetEmptyView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetEmptyView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetEmptyView:BindUIEvent()
    
end

function UIWidgetEmptyView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetEmptyView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetEmptyView:UpdateInfo()
    
end


return UIWidgetEmptyView