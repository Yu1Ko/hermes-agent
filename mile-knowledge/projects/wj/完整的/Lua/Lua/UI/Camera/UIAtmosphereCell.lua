local UIAtmosphereCell = class("UIAtmosphereCell")

function UIAtmosphereCell:OnEnter()
    self:BindUIEvent()
end

function UIAtmosphereCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogAtmosphere, EventType.OnSelectChanged, function(_, bSelected)
        if self.fnCallback then
            self.fnCallback(self.szName, bSelected)
        end
    end)
end

function UIAtmosphereCell:UpdateInfo(szName, fnCallback)
    self.fnCallback = fnCallback
    self.szName = szName
    UIHelper.SetString(self.LabelNormal, szName)
end

function UIAtmosphereCell:ShowSelectState(bSelected)
    UIHelper.SetSelected(self.TogAtmosphere, bSelected, false)
end

return UIAtmosphereCell