local UIWorldMapPeripheralPanel = class("UIWorldMapPeripheralPanel")

function UIWorldMapPeripheralPanel:OnEnter()
    self._rootNode:setVisible(false)
    self.TransportScript = UIHelper.GetBindScript(self.WidgerAnchorGo)
end

function UIWorldMapPeripheralPanel:OnExit()
end

function UIWorldMapPeripheralPanel:Hide()
    self._rootNode:setVisible(false)
    if self.nUpdateTimer then
        Timer.DelTimer(self, self.nUpdateTimer)
        self.nUpdateTimer = nil
    end
end

function UIWorldMapPeripheralPanel:GetSelectNode()
    for nIndex, script in ipairs(self.tbScript) do
        if script.IsSelect and script:IsSelect() then 
            return script._rootNode
        end
    end
    return nil
end

function UIWorldMapPeripheralPanel:UpdateLayout()
    UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewType03, true, false)
    UIHelper.ScrollViewDoLayout(self.ScrollViewType03)
    local node = self:GetSelectNode()
    if node then
        if not UIHelper.IsPreviewItemInView(self.ScrollViewType03, node) then
            UIHelper.ScrollLocateToPreviewItem(self.ScrollViewType03, node, Locate.TO_BOTTOM, 0)
        end
    else
        UIHelper.ScrollToTop(self.ScrollViewType03, 0, false)
    end
end

function UIWorldMapPeripheralPanel:ShowPeripheral(szName, tbInfo, tbCityInfo, tbCopyInfo, tbTraffic)
    self.tbInfo = tbInfo
    self.tbTraffic = tbTraffic
    self._rootNode:setVisible(true)
    self.WidgetAnchorPeripheral:setVisible(true)
    self.WidgerAnchorGo:setVisible(false)

    self.LayoutCitySelect02:removeAllChildren()
    self.LayoutDungeonSelect02:removeAllChildren()

    self.tbScript = {}
    if #tbInfo.tChildCityMaps > 0 then
        self.LayoutCityType02:setVisible(true)
        for i, nMapID in ipairs(tbInfo.tChildCityMaps) do
            local peripheral = tbCityInfo[nMapID]
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetWorldCitySelect, self.LayoutCitySelect02)
            script:UpdateInfo(peripheral, false, tbTraffic)
            table.insert(self.tbScript, script)
        end
    else
        self.LayoutCityType02:setVisible(false)
    end
    
    if #tbInfo.tChildCopyMaps > 0 then
        self.LayoutDungeonType02:setVisible(true)
        for i, nMapID in ipairs(tbInfo.tChildCopyMaps) do
            local peripheral = tbCopyInfo[nMapID]
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetWorldDungeonSelect, self.LayoutDungeonSelect02, true)
            script:UpdateInfo(peripheral, tbTraffic, self.PeripheralToggleGroup)
            script.fnSelected = function()
                self:DelayUpdateLayout()
            end
            table.insert(self.tbScript, script)
        end
    else
        self.LayoutDungeonType02:setVisible(false)
    end

    self:UpdateLayout()
end

function UIWorldMapPeripheralPanel:TraceMap(nMapID)
    self._rootNode:setVisible(true)
    self.WidgerAnchorGo:setVisible(false)
    self.WidgetAnchorPeripheral:setVisible(true)

    -- local szName = GBKToUTF8(Table_GetMapName(nMapID) or "")
    -- self.TransportScript:Show(szName, nMapID)
end

function UIWorldMapPeripheralPanel:DelayUpdateLayout()
    if self.nTimer then
        Timer.DelTimer(self, self.nTimer)
        self.nTimer = nil
    end
    self.nTimer = Timer.AddFrame(self, 1 ,function()
        self:UpdateLayout()
    end)
end

return UIWorldMapPeripheralPanel