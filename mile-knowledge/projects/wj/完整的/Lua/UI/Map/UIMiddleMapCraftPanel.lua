local UIMiddleMapCraftPanel = class("UIMiddleMapCraftPanel")

function UIMiddleMapCraftPanel:OnEnter()
    self:RegisterEvent()

    self.ScriptScrollViewTree = UIHelper.GetBindScript(self.WidgetScrollViewContent)
end

function UIMiddleMapCraftPanel:OnExit()
    
end

function UIMiddleMapCraftPanel:RegisterEvent()
    UIHelper.BindUIEvent(self.ToggleGather, EventType.OnSelectChanged, function(_, bSelected)
        Storage.MiddleMapData.bMiniMapShowCraft = bSelected
        Storage.MiddleMapData.Dirty()
    end)


    UIHelper.BindUIEvent(self.ToggleCraft, EventType.OnSelectChanged, function(_, bSelected)
        if self.scriptSelect then
            self.scriptSelect:SetSelectWithCallback(bSelected)
        end
    end)

    Event.Reg(self, "ON_MIDDLE_MAP_CRAFT_SELECTED", function(nCraftID, nID, bSelected, script)
        
        MapMgr.AddCraftInfo(nID, bSelected and nCraftID or nil)
        if bSelected and not self.bAutoSelected and not UIHelper.GetSelected(self.ToggleGather) then
            UIHelper.SetSelected(self.ToggleGather, bSelected, true)
            self.bAutoSelected = true
        end
        local tbCraft = MapMgr.GetCraftPosByID(self.nMapID, nID)
        Event.Dispatch('ON_MIDDLE_MAP_CRAFT_UPDATE', nCraftID, nID, tbCraft, bSelected)

        UIHelper.SetSelected(self.ToggleCraft, bSelected, false)
        if bSelected then
            self.scriptSelect = script
        end
    end)
end

function UIMiddleMapCraftPanel:Show()
    UIHelper.SetVisible(self._rootNode, true)
end

function UIMiddleMapCraftPanel:Hide()
    UIHelper.SetVisible(self._rootNode, false)
end

function UIMiddleMapCraftPanel:UpdateInfo(nMapID)
    self.nMapID = nMapID
    local tbCraftGuide = MapHelper.tbMiddleMapCraftGuide[nMapID]
    local tData = {}
    local tbExist = {}

    self.scriptSelect = nil
    for nIndex, craft in pairs(tbCraftGuide) do
        tbExist[craft.nCraftID] = true
        local tbCatalog
        for i, v in ipairs(tData) do
            if v.tArgs.nCraftID == craft.nCraftID then
                tbCatalog = v
                break
            end
        end
        if not tbCatalog then
            table.insert(tData, {
                tArgs = {
                    nCraftID = craft.nCraftID,
                },
                tItemList = {}
            })
            tbCatalog = tData[#tData]
        end
        table.insert(tbCatalog.tItemList,  {tArgs = craft} )
    end

    for _, data in ipairs(tData) do
        -- local szLayoutName = string.format('LayoutSignSet%02d', data.tArgs.nCraftID)
        local layout = self.LayoutSignSet[data.tArgs.nCraftID]
        if layout then
            layout:removeAllChildren()
            for _, craft in ipairs(data.tItemList) do
                local bSelect = Storage.MiddleMapData.tbCraftList[craft.tArgs.dwID] ~= nil
                local script = UIHelper.AddPrefab(PREFAB_ID.WidgetMiddleSignSet, layout, craft.tArgs)
                script:SetSelected(bSelect)
                if bSelect then
                    self.scriptSelect = script
                end
            end
        end
    end

    UIHelper.SetSelected(self.ToggleCraft, self.scriptSelect ~= nil, false)
    
    if #tData > 0 then
        UIHelper.SetVisible(self.WidgetScrollViewContent, true)
        UIHelper.SetVisible(self.WidgetEmpty, false)
        for i, layout in ipairs(self.LayoutSignSet) do
            if not tbExist[i] then
                UIHelper.SetVisible(layout, false)
                UIHelper.SetVisible(self.WidgetTittle[i], false)
            else
                UIHelper.SetVisible(layout, true)
                UIHelper.SetVisible(self.WidgetTittle[i], true)
            end
        end
        
        UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewContentSelect01, true, true)
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContentSelect01)
    else
        UIHelper.SetVisible(self.WidgetScrollViewContent, false)
        UIHelper.SetVisible(self.WidgetEmpty, true)
    end

    --[[self.ScriptScrollViewTree:ClearContainer()
    UIHelper.SetupScrollViewTree(self.ScriptScrollViewTree,
        PREFAB_ID.WidgetWorlActivity, PREFAB_ID.WidgetMiddleSignSelect,
        function(scriptContainer, tArgs)
            scriptContainer.LabelName01:setString(tArgs.szName)
            scriptContainer.LabelName02:setString(tArgs.szName)

            scriptContainer.fnSelectedCallback = function()
                
            end
        end,
        tData
    )
    UIHelper.CascadeDoLayoutDoWidget(self.ScriptScrollViewTree.ScrollViewContent, true, true)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScriptScrollViewTree.ScrollViewContent)]]--

    UIHelper.SetSelected(self.ToggleGather, Storage.MiddleMapData.bMiniMapShowCraft, false)


    UIHelper.SetVisible(self.WidgetShenXing, false)
end

return UIMiddleMapCraftPanel