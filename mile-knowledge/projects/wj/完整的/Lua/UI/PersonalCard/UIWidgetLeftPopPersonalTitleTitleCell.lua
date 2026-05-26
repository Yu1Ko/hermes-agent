-- ---------------------------------------------------------------------------------
-- Name: UIWidgetLeftPopPersonalTitleTitleCell
-- Desc: 名片形象 - 称号选择
-- ---------------------------------------------------------------------------------

local UIWidgetLeftPopPersonalTitleTitleCell = class("UIWidgetLeftPopPersonalTitleTitleCell")

function UIWidgetLeftPopPersonalTitleTitleCell:OnEnter()
    if not self.bInit then
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIWidgetLeftPopPersonalTitleTitleCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetLeftPopPersonalTitleTitleCell:BindUIEvent()
    
end

function UIWidgetLeftPopPersonalTitleTitleCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetLeftPopPersonalTitleTitleCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetLeftPopPersonalTitleTitleCell:UpdateInfo()
    
end


return UIWidgetLeftPopPersonalTitleTitleCell