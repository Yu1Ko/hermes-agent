local UIWidgetRenownForceFliter = class("UIWidgetRenownForceFliter")


function UIWidgetRenownForceFliter:OnEnter(szName, fCallBack)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.szName = szName
    self.fCallBack = fCallBack
    UIHelper.SetTouchDownHideTips(self.ToggleSelect, false)
    self:UpdateInfo()
end

function UIWidgetRenownForceFliter:OnExit()
    self.bInit = false
end

function UIWidgetRenownForceFliter:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            self.fCallBack()
        end
    end)
end

function UIWidgetRenownForceFliter:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetRenownForceFliter:UpdateInfo()
    UIHelper.SetString(self.LabelName, self.szName)
    UIHelper.SetSwallowTouches(self.ToggleSelect, false)
end

return UIWidgetRenownForceFliter