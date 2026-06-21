-- ---------------------------------------------------------------------------------
-- Author: JiaYuRan
-- Name: UIPanelWareHouse
-- ---------------------------------------------------------------------------------

local UIWidgetWareHouseTab = class("UIWidgetWareHouseTab")

function UIWidgetWareHouseTab:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetWareHouseTab:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetWareHouseTab:BindUIEvent()
end

function UIWidgetWareHouseTab:RegEvent()

end

function UIWidgetWareHouseTab:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetWareHouseTab:UpdateInfo()

end

function UIWidgetWareHouseTab:SetToggleGroup(toggleGroup)
    UIHelper.ToggleGroupAddToggle(toggleGroup, self.TogWarehouseTab)
end

function UIWidgetWareHouseTab:SetName(szName)
    UIHelper.SetString(self.LabelName, szName)
    UIHelper.SetString(self.LabelNameSelected, szName)
end

function UIWidgetWareHouseTab:SetIcon(szIconPath)
    --UIHelper.SetString(self.LabelName, szName)
end

function UIWidgetWareHouseTab:SetSelectCallback(fnFunc)
    UIHelper.BindUIEvent(self.TogWarehouseTab, EventType.OnSelectChanged, fnFunc)
end

return UIWidgetWareHouseTab