local UIWorldMapCityPanel = class("UIWorldMapCityPanel")

function UIWorldMapCityPanel:OnEnter()
    self._rootNode:setVisible(false)

    self.CityScrollViewScript    = UIHelper.GetBindScript(self.WidgetScrollViewCityType)
    self.DungeonScrollViewScript = UIHelper.GetBindScript(self.WidgetScrollViewDungeonType)
end

function UIWorldMapCityPanel:Show()
    self._rootNode:setVisible(true)
end

function UIWorldMapCityPanel:UpdateDungeonLayout(bToTop)
    UIHelper.CascadeDoLayoutDoWidget(self.DungeonScrollViewScript.ScrollViewContent, true, true)
    UIHelper.ScrollViewDoLayoutAndToTop(self.DungeonScrollViewScript.ScrollViewContent)
end

function UIWorldMapCityPanel:UpdateCityLayout(bToTop)
    UIHelper.CascadeDoLayoutDoWidget(self.CityScrollViewScript.ScrollViewContent, true, true)
    UIHelper.ScrollViewDoLayoutAndToTop(self.CityScrollViewScript.ScrollViewContent)
end

function UIWorldMapCityPanel:RegisterEvent()
    Event.Reg(self, 'ON_MAP_DUNGEON_TOGGLE', function(obj, bSelected)
        UIHelper.CascadeDoLayoutDoWidget(self.DungeonScrollViewScript.ScrollViewContent, true, true)
        UIHelper.ScrollViewDoLayout(self.DungeonScrollViewScript.ScrollViewContent)
        -- UIHelper.ScrollViewDoLayoutAndToTop(self.DungeonScrollViewScript.ScrollViewContent)

        --展开/折叠后ScrollView位置做相应调整
        local nDelta = 90
        local nScrolledX, nScrolledY = UIHelper.GetScrolledPosition(self.DungeonScrollViewScript.ScrollViewContent)
        if bSelected then
            nScrolledY = nScrolledY - nDelta
        else
            nScrolledY = nScrolledY + nDelta
        end
        UIHelper.SetScrolledPosition(self.DungeonScrollViewScript.ScrollViewContent, nScrolledX, nScrolledY)
    end)
end

function UIWorldMapCityPanel:UnRegisterEvent()
end

function UIWorldMapCityPanel:UpdateCityTypeList()
    self.tbCityScrollViewData = {}
    for i, tb in ipairs(self.tbCityCatalog) do
        local tItemList = {}
        for _, v in ipairs(tb) do
            table.insert(tItemList, {
                tArgs = { tbInfo = v, bTransport = true}
            })
        end
        table.insert(self.tbCityScrollViewData, {
            tArgs = { szType = tb.szType},
            tItemList = tItemList,
            fnSelectedCallback = function(bSelected) end,
        })
    end

    self.CityScrollViewScript:ClearContainer()
    UIHelper.SetupScrollViewTree(self.CityScrollViewScript,
        PREFAB_ID.WidgetCityType, PREFAB_ID.WidgetWorldCitySelect,
        function(scriptContainer, tArgs)
            scriptContainer.LabelTitle02:setString(tArgs.szType)
            scriptContainer.LabelTitle03:setString(tArgs.szType)
        end,
        self.tbCityScrollViewData,
        true
    )

    self:UpdateCityLayout(true)
end

function UIWorldMapCityPanel:UpdateDungeonTypeList()
    self.tbDungeonScrollViewData = {}
    for i, tb in ipairs(self.tbCopyCatalog) do
        local tItemList = {}
        for _, v in ipairs(tb) do
            table.insert(tItemList, {
                tArgs = { tbInfo = v, bTransport = true , toggleGroup = self.DungeonToggleGroup}
            })
        end
        table.insert(self.tbDungeonScrollViewData, {
            tArgs = { szType = tb.szType},
            tItemList = tItemList,
            fnSelectedCallback = function(bSelected) end,
        })
    end

    self.DungeonScrollViewScript:ClearContainer()
    UIHelper.SetupScrollViewTree(self.DungeonScrollViewScript,
        PREFAB_ID.WidgetCityType, PREFAB_ID.WidgetWorldDungeonSelect,
        function(scriptContainer, tArgs)
            scriptContainer.LabelTitle02:setString(tArgs.szType)
            scriptContainer.LabelTitle03:setString(tArgs.szType)
        end,
        self.tbDungeonScrollViewData,
        true
    )
    
    self:UpdateDungeonLayout(true)
end

function UIWorldMapCityPanel:UpdateInfo(tbCityCatalog, tbCopyCatalog)
    self.tbCityCatalog = tbCityCatalog
    self.tbCopyCatalog = tbCopyCatalog
    self:UpdateCityTypeList()
    self:UpdateDungeonTypeList()

    self:RegisterEvent()
end

function UIWorldMapCityPanel:Hide()
    self._rootNode:setVisible(false)
end

function UIWorldMapCityPanel:OnExit()
    self:UnRegisterEvent()
end

return UIWorldMapCityPanel