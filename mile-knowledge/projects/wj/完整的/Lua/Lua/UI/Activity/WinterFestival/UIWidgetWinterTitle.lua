-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetWinterTitle
-- Date: 2024-11-26 11:03:15
-- Desc: WidgetWinterTitle 门客培养 标题栏
-- ---------------------------------------------------------------------------------

local UIWidgetWinterTitle = class("UIWidgetWinterTitle")

function UIWidgetWinterTitle:OnEnter(szTitle)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.szTitle = szTitle
    self:UpdateInfo()
end

function UIWidgetWinterTitle:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetWinterTitle:BindUIEvent()
    
end

function UIWidgetWinterTitle:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetWinterTitle:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetWinterTitle:UpdateInfo()
    UIHelper.SetString(self.LabelDetail, self.szTitle)
end


return UIWidgetWinterTitle