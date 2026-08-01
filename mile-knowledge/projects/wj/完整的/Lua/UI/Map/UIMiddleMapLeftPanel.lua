local UIMiddleMapLeftPanel = class("UIMiddleMapLeftPanel")

function UIMiddleMapLeftPanel:Enter()
    
end

function UIMiddleMapLeftPanel:RegisterEvent()
end

function UIMiddleMapLeftPanel:UpdateInfo(nMapID)
    self.nMapID = nMapID
    self.tbAreaList = {}
    self.LayoutTab:removeAllChildren()
    local tbList = Table_GetMiddleMap(nMapID) or {}
    if #tbList > 1 then
        UIHelper.SetVisible(self._rootNode, true)
        for nIndex, szMiddleMap in ipairs(tbList) do
            nIndex = nIndex - 1
            if szMiddleMap ~= "" then
                local script = UIHelper.AddPrefab(PREFAB_ID.WidgetMiddleTabListCell, self.LayoutTab)
                script:UpdateInfo(nIndex, GBKToUTF8(szMiddleMap), nMapID)
                self.tbAreaList[nIndex] = script
            end
        end
    -- else
    --     UIHelper.SetVisible(self._rootNode, false)
    end
end

function UIMiddleMapLeftPanel:SetIndex(nIndex)
    if not self.tbAreaList or not self.tbAreaList[nIndex] then
        return
    end
    Event.Dispatch('ON_MIDDLE_MAP_LEFT_CELL_TOGGLE', self.tbAreaList[nIndex], true, self.nMapID)
    self.tbAreaList[nIndex]:SetSelected(true)
end

function UIMiddleMapLeftPanel:Exit()
    
end

return UIMiddleMapLeftPanel