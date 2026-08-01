local UIWorldMapActivityCell = class("UIWorldMapActivityCell")

function UIWorldMapActivityCell:OnEnter(tArgs)
    self:RegisterEvent()
    self:UpdateInfo(tArgs.szName, tArgs.nMapID, tArgs.tbPoint)
end

function UIWorldMapActivityCell:OnExit()
    
end

function UIWorldMapActivityCell:RegisterEvent()
    UIHelper.BindUIEvent(self.TogTrace, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            MapMgr.SetTracePoint(self.szName, self.nMapID, self.tbPoint)
        else
            MapMgr.ClearTracePoint()
        end
    end)

    UIHelper.BindUIEvent(self.TogActivity, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            Event.Dispatch(EventType.OnMapTraceZoning, self.nMapID, true)
        else
            Event.Dispatch("ON_WORLD_MAP_CITY_HIGHLIGHT")
        end
        Event.Dispatch("ON_WORLD_MAP_ACTIVITY_TOGGLE", self, bSelected)
    end)

    Event.Reg(self, "ON_WORLD_MAP_ACTIVITY_TOGGLE", function(obj, bSelected)
        if bSelected and obj ~= self then
            UIHelper.SetSelected(self.TogActivity, false, false)
        end
    end)
end

function UIWorldMapActivityCell:UpdateInfo(szName, nMapID, tbPoint)
    self.szName = szName
    self.nMapID = nMapID
    self.tbPoint = tbPoint

    UIHelper.SetString(self.LabelNameNormal, szName)
    UIHelper.SetString(self.LabelNameSelected, szName)

    UIHelper.SetVisible(self.TogTrace, tbPoint ~= nil)
end

return UIWorldMapActivityCell