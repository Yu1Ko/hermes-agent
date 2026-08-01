-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetFilterItem
-- Date: 2023-02-14 20:15:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetFilterItem = class("UIWidgetFilterItem")

function UIWidgetFilterItem:OnEnter(tbConfig, fnSelect)
    if not tbConfig then
        return
    end
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbConfig = tbConfig
    self.fnSelect = fnSelect
    self:UpdateInfo()
end

function UIWidgetFilterItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIWidgetFilterItem:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnSelectChanged, function (_, bSelected)
        self.fnSelect(self, bSelected)
    end)
end

function UIWidgetFilterItem:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetFilterItem:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetFilterItem:UpdateInfo()
    UIHelper.SetString(self.LabelDesc, self.tbConfig.szName)
    UIHelper.SetSwallowTouches(self.ToggleSelect, false)
end

function UIWidgetFilterItem:GetSelected()
    return UIHelper.GetSelected(self.ToggleSelect)
end

function UIWidgetFilterItem:SetSelected(bSelected)
    UIHelper.SetSelected(self.ToggleSelect, bSelected, false)
end

return UIWidgetFilterItem