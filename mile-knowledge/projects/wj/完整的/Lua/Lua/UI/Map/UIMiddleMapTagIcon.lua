local UIMiddleMapTagIcon = class("UIMiddleMapTagIcon")

function UIMiddleMapTagIcon:OnEnter()
    self:RegisterEvent()
end

function UIMiddleMapTagIcon:OnExit()
    
end

function UIMiddleMapTagIcon:UpdateInfo(nIconID)
    self.nIconID = nIconID
end

function UIMiddleMapTagIcon:SetSelected(bSelected)
    UIHelper.SetSelected(self.TogCustomIcon, bSelected, false)
end

function UIMiddleMapTagIcon:RegisterEvent()
    UIHelper.BindUIEvent(self.TogCustomIcon, EventType.OnSelectChanged, function(_, bSelected)
        Event.Dispatch('ON_MIDDLE_MAP_ICON_SELECTED', self, self.nIconID)
    end)
    Event.Reg(self, "ON_MIDDLE_MAP_ICON_SELECTED", function(obj, nIconID)
        if nIconID == self.nIconID then
            return
        end
        UIHelper.SetSelected(self.TogCustomIcon, false, false)
    end)
end

return UIMiddleMapTagIcon