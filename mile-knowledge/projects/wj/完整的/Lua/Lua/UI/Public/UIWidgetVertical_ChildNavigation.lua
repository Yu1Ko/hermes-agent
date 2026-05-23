-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetVertical_ChildNavigation
-- Date: 2024-02-22 17:01:57
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetVertical_ChildNavigation = class("UIWidgetVertical_ChildNavigation")

function UIWidgetVertical_ChildNavigation:OnEnter(tbData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbData = tbData
    self:UpdateInfo()
end

function UIWidgetVertical_ChildNavigation:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetVertical_ChildNavigation:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleChildNavigation, EventType.OnSelectChanged, function(_, bSelect)
        local fnSelectedCallback = self.tbData.fnSelectedCallback
        if fnSelectedCallback then 
            fnSelectedCallback(bSelect)
        end
    end)
end

function UIWidgetVertical_ChildNavigation:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetVertical_ChildNavigation:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetVertical_ChildNavigation:UpdateInfo()
    local szName = self.tbData.szName 
    UIHelper.SetString(self.LabelChildNavigationNormal, szName)
    UIHelper.SetString(self.LabelChildNavigationSelect, szName)

    local toggleGroup = self.tbData.toggleGroup
    UIHelper.ToggleGroupAddToggle(toggleGroup, self.ToggleChildNavigation)
end

function UIWidgetVertical_ChildNavigation:SetSelected(bSelected)
    -- UIHelper.SetSelected(self.ToggleChildNavigation, bSelected)
    UIHelper.SetToggleGroupSelectedToggle(self.tbData.toggleGroup, self.ToggleChildNavigation)
    local fnSelectedCallback = self.tbData.fnSelectedCallback
    if fnSelectedCallback then 
        fnSelectedCallback(bSelected)
    end
end


return UIWidgetVertical_ChildNavigation