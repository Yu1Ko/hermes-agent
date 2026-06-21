local UIWareHouseExpandCell = class("UIWareHouseExpandCell")

function UIWareHouseExpandCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWareHouseExpandCell:OnExit()
    if self.toggleGroup then
        UIHelper.ToggleGroupRemoveToggle(self.toggleGroup, self.ToggleAdd)
    end
    self.bInit = false
    self:UnRegEvent()
end

function UIWareHouseExpandCell:BindUIEvent()

end

function UIWareHouseExpandCell:RegEvent()

end

function UIWareHouseExpandCell:UnRegEvent()

end

function UIWareHouseExpandCell:SetToggleGroup(toggleGroup)
    self.toggleGroup = toggleGroup
    UIHelper.ToggleGroupAddToggle(toggleGroup, self.ToggleAdd)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

return UIWareHouseExpandCell