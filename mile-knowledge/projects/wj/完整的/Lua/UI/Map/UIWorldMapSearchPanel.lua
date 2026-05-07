local UIWorldMapSearchPanel = class("UIWorldMapSearchPanel")

function UIWorldMapSearchPanel:OnEnter()
    self:RegisterEvent()
    self:UpdateLayout()
    self._rootNode:setVisible(false)
end

function UIWorldMapSearchPanel:OnExit()
    
end

function UIWorldMapSearchPanel:UpdateInfo(tbCityList, tbCopyList)
    self.tbCityList = tbCityList
    self.tbCopyList = tbCopyList
end

function UIWorldMapSearchPanel:UpdateSearchContent()
    local szSearchValue = UIHelper.GetString(self.EditSearch)
    self.LayoutHistory:removeAllChildren()
    self.LayoutCitySelect03:removeAllChildren()

    if szSearchValue ~= "" then
        local bFind = false
        UIHelper.SetVisible(self.BtnClose06, true)
        UIHelper.SetVisible(self.WidgetAnchorHistory, false)
        for i, v in ipairs(UIWorldMapCityTab) do
            if string.find(v.szComment, szSearchValue) then
                bFind = true
                local script = UIHelper.AddPrefab(PREFAB_ID.WidgetWorldCitySelect, self.LayoutCitySelect03)
                script:UpdateInfo(v, false, false)
            end
        end
    
        for i, v in ipairs(UIWorldMapCopyTab) do
            if string.find(v.szComment, szSearchValue) then
                bFind = true
                local script = UIHelper.AddPrefab(PREFAB_ID.WidgetWorldDungeonSelect, self.LayoutCitySelect03, true)
                script:UpdateInfo(v, false, self.HistoryToggleGroup)
            end
        end
        if bFind then
            UIHelper.SetVisible(self.ScrollViewSearch03, true)
            UIHelper.SetVisible(self.WidgetAnchorNo, false)
        else
            UIHelper.SetVisible(self.ScrollViewSearch03, false)
            UIHelper.SetVisible(self.WidgetAnchorNo, true)
        end
    else
        if not self.tbCityInfo then
            self.tbCityInfo = {}
            for i, v in ipairs(UIWorldMapCityTab) do
                self.tbCityInfo[v.nMapID] = v
            end
            self.tbCopyInfo = {}
            for i, v in ipairs(UIWorldMapCopyTab) do
                self.tbCopyInfo[v.nMapID] = v
            end
        end
        for i, nMapID in ipairs(Storage.WorldMapData.tbRecordList) do
            if self.tbCityInfo[nMapID] then
                local script = UIHelper.AddPrefab(PREFAB_ID.WidgetWorldCitySelect, self.LayoutHistory)
                script:UpdateInfo(self.tbCityInfo[nMapID], false, false)
            elseif self.tbCopyInfo[nMapID] then
                local script = UIHelper.AddPrefab(PREFAB_ID.WidgetWorldDungeonSelect, self.LayoutHistory, true)
                script:UpdateInfo(self.tbCopyInfo[nMapID], false, self.HistoryToggleGroup)
            end
        end
        UIHelper.SetVisible(self.ScrollViewSearch03, false)
        UIHelper.SetVisible(self.WidgetAnchorNo, false)
        UIHelper.SetVisible(self.BtnClose06, false)
        UIHelper.SetVisible(self.WidgetAnchorHistory, true)
    end
    self:UpdateLayout()
end

function UIWorldMapSearchPanel:RegisterEvent()
    UIHelper.BindUIEvent(self.BtnClose06, EventType.OnClick, function()
        UIHelper.SetString(self.EditSearch, "")
        self:UpdateSearchContent()
    end)

    UIHelper.RegisterEditBoxChanged(self.EditSearch, function()
        self:UpdateSearchContent()
    end)

    Event.Reg(self, 'ON_MAP_DUNGEON_TOGGLE', function(obj, bSelected)
        UIHelper.CascadeDoLayoutDoWidget(self.WidgetAnchorContent04, true, true)
        local nScrolledX, nScrolledY
        local ScrollView
        if UIHelper.GetVisible(self.ScrollViewSearch03) then
            ScrollView = self.ScrollViewSearch03
        elseif UIHelper.GetVisible(self.ScrollViewHistory) then
            ScrollView = self.ScrollViewHistory
        end

        UIHelper.ScrollViewDoLayout(ScrollView)
        local nDelta = 90
        local nScrolledX, nScrolledY = UIHelper.GetScrolledPosition(ScrollView)
        if bSelected then
            nScrolledY = nScrolledY - nDelta
        else
            nScrolledY = nScrolledY + nDelta
        end
        UIHelper.SetScrolledPosition(ScrollView, nScrolledX, nScrolledY)
    end)
end

function UIWorldMapSearchPanel:Show()
    self._rootNode:setVisible(true)
    self:UpdateSearchContent()
end

function UIWorldMapSearchPanel:Hide()
    self._rootNode:setVisible(false)
end

function UIWorldMapSearchPanel:UpdateLayout()
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSearch03)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewHistory)
end

return UIWorldMapSearchPanel