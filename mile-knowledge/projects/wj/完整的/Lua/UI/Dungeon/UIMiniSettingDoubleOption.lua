local UIMiniSettingDoubleOption = class("UIMiniSettingDoubleOption")

function UIMiniSettingDoubleOption:OnEnter(tbConfig)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbConfig = tbConfig
    self:UpdateInfo()
end

function UIMiniSettingDoubleOption:OnExit()
    self.bInit = false
end

function UIMiniSettingDoubleOption:BindUIEvent()
    for nTogIndex, toggle in ipairs(self.tbToggleList) do
        UIHelper.SetSwallowTouches(toggle, false)
        UIHelper.BindUIEvent(toggle, EventType.OnSelectChanged, function (_, bSelected)
            if self.tbConfig and self.tbConfig.fnOnSelectChanged then
                self.tbConfig.fnOnSelectChanged(nTogIndex)
                self:UpdateInfo()
            end
        end)
    end

    UIHelper.BindUIEvent(self.TogSelect, EventType.OnSelectChanged, function (_, bSelected)
        if self.tbConfig and self.tbConfig.fnOnSelectOption then
            self.tbConfig.fnOnSelectOption(bSelected)
        end
    end)

    UIHelper.BindUIEvent(self.BtnDelete, EventType.OnClick, function ()
        if self.tbConfig and self.tbConfig.fnOnBtnDeleteClick then
            self.tbConfig.fnOnBtnDeleteClick(self.tbConfig)
        end
    end)
end

function UIMiniSettingDoubleOption:RegEvent()
    Event.Reg(self, EventType.OnMiniSettingAllRefresh, function ()
        self:UpdateInfo()
    end)
end

function UIMiniSettingDoubleOption:UpdateInfo()
    local tbConfig = self.tbConfig
    if not tbConfig then return end

    UIHelper.SetString(self.LabelTitle, tbConfig.szName)

    local nSelect = tbConfig.fnGetSelectIndex()
    local bVisible = not tbConfig.fnGetVisible or tbConfig.fnGetVisible()

    UIHelper.SetVisible(self.TogSelect, not bVisible)
    UIHelper.SetVisible(self.WidgetDelete, not bVisible)
    UIHelper.SetVisible(self.LayoutAuto, bVisible)
    if bVisible then
        for nTogIndex, toggle in ipairs(self.tbToggleList) do
            UIHelper.SetSelected(toggle, nSelect == nTogIndex, false)
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutTitle)
end

return UIMiniSettingDoubleOption