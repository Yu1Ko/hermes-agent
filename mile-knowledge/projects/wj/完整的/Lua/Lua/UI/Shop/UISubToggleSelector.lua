local UISubToggleSelector = class("UISubToggleSelector")

local m_bRawSet = false

function UISubToggleSelector:OnEnter(szName, szSelectorName, selectValue)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.szName = szName
    self.szSelectorName = szSelectorName
    self.selectValue = selectValue
    UIHelper.SetTouchDownHideTips(self.TogPitchBg, false)
    self:UpdateInfo()
end

function UISubToggleSelector:OnExit()
    self.bInit = false
end

function UISubToggleSelector:BindUIEvent()
    UIHelper.BindUIEvent(self.TogPitchBg, EventType.OnSelectChanged, function (_, bSelected)
        if m_bRawSet then return end
        
        Event.Dispatch(EventType.OnShopSelectorSelectChanged, self.szSelectorName, self.selectValue, bSelected)
    end)
end

function UISubToggleSelector:RegEvent()

end

function UISubToggleSelector:UpdateInfo()
    UIHelper.SetString(self.LabelDesc, self.szName)
    UIHelper.SetSwallowTouches(self.TogPitchBg, false)
end

function UISubToggleSelector:SetSelected(bSelected)
    UIHelper.SetSelected(self.TogPitchBg, bSelected)
end

function UISubToggleSelector:GetSelected()
    return UIHelper.GetSelected(self.TogPitchBg)
end

function UISubToggleSelector:GetSelectorName()
    return self.szSelectorName
end

function UISubToggleSelector:RawSetSelected(bSelected)
    m_bRawSet = true
    self:SetSelected(bSelected)
    m_bRawSet = false
end

return UISubToggleSelector