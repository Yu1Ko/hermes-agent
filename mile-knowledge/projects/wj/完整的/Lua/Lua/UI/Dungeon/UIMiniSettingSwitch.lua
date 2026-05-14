local UIMiniSettingSwitch = class("UIMiniSettingSwitch")

function UIMiniSettingSwitch:OnEnter(tbConfig)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbConfig = tbConfig
    self:UpdateInfo()
end

function UIMiniSettingSwitch:OnExit()
    self.bInit = false
end

function UIMiniSettingSwitch:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleSwitch, EventType.OnSelectChanged, function (_, bSelected)
        if self.tbConfig and self.tbConfig.fnFunc then
            self.tbConfig.fnFunc(bSelected)            
        end
    end)
end

function UIMiniSettingSwitch:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIMiniSettingSwitch:UpdateInfo()
    local tbConfig = self.tbConfig
    if not tbConfig or not tbConfig.fnGetValue then return end

    UIHelper.SetString(self.LabelTitle, tbConfig.szName)
    UIHelper.LayoutDoLayout(self.LayoutTitle)

    UIHelper.SetSelected(self.ToggleSwitch, tbConfig.fnGetValue(), false)
end

return UIMiniSettingSwitch