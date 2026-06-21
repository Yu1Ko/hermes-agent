local UIMiddleMapSignSet = class("UIMiddleMapSignSet")

function UIMiddleMapSignSet:OnEnter(tArgs)
    self:RegisterEvent()
    UIHelper.SetNodeSwallowTouches(self._rootNode, false, true)
    self:UpdateInfo(tArgs)
end

function UIMiddleMapSignSet:RegisterEvent()
    UIHelper.BindUIEvent(self.TogPitch, EventType.OnSelectChanged, function(_, bSelected)
        self:OnSelectChanged(bSelected)
    end)

    Event.Reg(self, "ON_MIDDLE_MAP_CRAFT_SELECTED", function(nCraftID, nID, bSelected, script)
        if bSelected then
            UIHelper.SetSelected(self.TogPitch, script == self, false)
        end
    end)
end

function UIMiddleMapSignSet:UpdateInfo(tArgs)
    self.tbInfo = tArgs
    self.tbSelected = {}
    self.dwID = tArgs.dwID
    self.nCraftID = tArgs.nCraftID

    self.LabelSign:setString(GBKToUTF8(tArgs.szName))
    -- UIHelper.SetSelected(self.TogPitch, bSelected, false)
end

function UIMiddleMapSignSet:OnSelectChanged(bSelected)
    Event.Dispatch('ON_MIDDLE_MAP_CRAFT_SELECTED', self.nCraftID, self.dwID, bSelected, self)
end

function UIMiddleMapSignSet:SetSelected(bSelected)
    UIHelper.SetSelected(self.TogPitch, bSelected, false)
end

function UIMiddleMapSignSet:SetSelectWithCallback(bSelected)
    UIHelper.SetSelected(self.TogPitch, bSelected)
    if not bSelected then
        self:OnSelectChanged(bSelected)
    end
end

return UIMiddleMapSignSet