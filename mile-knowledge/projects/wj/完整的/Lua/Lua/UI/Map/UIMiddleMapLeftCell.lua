local UIMiddleMapLeftCell = class("UIMiddleMapLeftCell")

function UIMiddleMapLeftCell:OnEnter()
    self:RegisterEvent()
end

function UIMiddleMapLeftCell:RegisterEvent()
    UIHelper.BindUIEvent(self.TogTabList, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            Event.Dispatch('ON_MIDDLE_MAP_SHOW_AREA', self.nArea)
            Event.Dispatch('ON_MIDDLE_MAP_LEFT_CELL_TOGGLE', self, bSelected, self.nMapID)
            UIHelper.SetTouchEnabled(self.TogTabList, false)
        end
    end)
    Event.Reg(self, "ON_MIDDLE_MAP_LEFT_CELL_TOGGLE", function(obj, bSelected, nMapID)
        if bSelected and obj ~= self and nMapID == self.nMapID then
            self:SetSelected(false)
        end
    end)
end

function UIMiddleMapLeftCell:UpdateInfo(nIndex, szName, nMapID)
    UIHelper.SetString(self.LabelNormal, szName)
    UIHelper.SetString(self.LabelUp, szName)

    self.nArea = nIndex
    self.nMapID = nMapID
end

function UIMiddleMapLeftCell:SetSelected(bSelected)
    UIHelper.SetSelected(self.TogTabList, bSelected, false)
    UIHelper.SetTouchEnabled(self.TogTabList, not bSelected)
end

function UIMiddleMapLeftCell:Exit()
    
end

return UIMiddleMapLeftCell