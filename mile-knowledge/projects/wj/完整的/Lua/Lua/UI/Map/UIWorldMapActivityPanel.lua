local UIWorldMapActivityPanel = class("UIWorldMapActivityPanel")

function UIWorldMapActivityPanel:OnEnter()
    self._rootNode:setVisible(false)
    self.ScriptScrollViewTree = UIHelper.GetBindScript(self.WidgetScrollViewActivityType)
    self:RegisterEvent()
end

function UIWorldMapActivityPanel:RegisterEvent()
    Event.Reg(self, 'ON_MAP_DUNGEON_TOGGLE', function(obj, bSelected)
        UIHelper.CascadeDoLayoutDoWidget(self.ScriptScrollViewTree.ScrollViewContent, true, true)
        UIHelper.ScrollViewDoLayout(self.ScriptScrollViewTree.ScrollViewContent)
        -- UIHelper.ScrollViewDoLayoutAndToTop(self.DungeonScrollViewScript.ScrollViewContent)

        --展开/折叠后ScrollView位置做相应调整
        local nDelta = 90
        local nScrolledX, nScrolledY = UIHelper.GetScrolledPosition(self.ScriptScrollViewTree.ScrollViewContent)
        if bSelected then
            nScrolledY = nScrolledY - nDelta
        else
            nScrolledY = nScrolledY + nDelta
        end

        UIHelper.SetScrolledPosition(self.ScriptScrollViewTree.ScrollViewContent, nScrolledX, nScrolledY)
    end)

    Event.Reg(self, EventType.ON_MAPMAR_ACTIVITYLIST_UPDATE, function()
        self:UpdateInfo()
    end)
end

function UIWorldMapActivityPanel:OnExit()
end

function UIWorldMapActivityPanel:Show()
    self._rootNode:setVisible(true)
    self:RegisterEvent()
    if not MapMgr.UpdateActivityState() then
        self:UpdateInfo()
    end
end

function UIWorldMapActivityPanel:Hide()
    self._rootNode:setVisible(false)
    Event.UnRegAll(self)
end

function UIWorldMapActivityPanel:UpdateInfo()
    local scriptWorldMap = UIMgr.GetViewScript(VIEW_ID.PanelWorldMap)
    if not scriptWorldMap then return end
    local tbCityInfo, tbCopyInfo, tbZoningData, tbTraffic, tbParentMapID = scriptWorldMap.tbCityInfo, scriptWorldMap.tbCopyInfo, 
    scriptWorldMap.tbZoningData, scriptWorldMap.tbTraffic, scriptWorldMap.tbParentMapID 
    local tTime = TimeLib.GetTodayTime()
    local tActiveList = Table_GetActivityOfDay(tTime.year, tTime.month, tTime.day, ACTIVITY_UI.WORLDMAP)

    local fnSortByPriority = function(tLeft, tRight)
        if tLeft.nLabel == tRight.nLabel then
            return tLeft.nShowPriority < tRight.nShowPriority
        end

        return tLeft.nLabel > tRight.nLabel
    end

    table.sort(tActiveList, fnSortByPriority)

    local tbSVTInfo = {}
    local player = g_pClientPlayer
    for _, tActive in ipairs(tActiveList) do
        tActive.tPointList = {}
        for szLink in string.gmatch(tActive.szDetailMap, "link=\"%a+/%d+\"") do
            local _, szLinkArg = szLink:match("(%a+)/(%d+)")
            local nID = tonumber(szLinkArg)
            if not tActive.tPointList[nID] then
                tActive.tPointList[nID] = true
            end
        end
        self:UpdateActive(player, tActive, tbCityInfo, tbCopyInfo, tbZoningData, tbTraffic, tbSVTInfo, false, tbParentMapID)
    end

    for _, tSActive in ipairs(MapMgr.tActivityList or {}) do
        local tActive = Table_GetCalenderActivity(tSActive.dwID)
        tActive.tMap = tSActive.tMap

        self:UpdateActive(player, tActive, tbCityInfo, tbCopyInfo, tbZoningData, tbTraffic, tbSVTInfo, true, tbParentMapID)
    end

    self.ScriptScrollViewTree:SetOuterInitSelect()
    self.ScriptScrollViewTree:ClearContainer()
    UIHelper.SetupScrollViewTree(self.ScriptScrollViewTree,
        PREFAB_ID.WidgetWorlActivity, PREFAB_ID.WidgetWorldDungeonSelect,
        function(scriptContainer, tArgs)
            scriptContainer.LabelName01:setString(tArgs.szName)
            scriptContainer.LabelName02:setString(tArgs.szName)

            scriptContainer.LabelTime01:setString(tArgs.szTime)
            scriptContainer.LabelTime02:setString(tArgs.szTime)

            
        end,
        tbSVTInfo
    )
end

-- function UIWorldMapActivityPanel:GetZoningInfo(tbZoningData, dwMapID)
--     for szName, zoning in pairs(tbZoningData) do
--         for i, mapID in ipairs(zoning.tChildCopyMaps) do
--             if mapID == dwMapID then
--                 return zoning
--             end
--         end
--         for i, mapID in ipairs(zoning.tChildCityMaps) do
--             if mapID == dwMapID then
--                 return zoning
--             end
--         end
--     end
-- end

function UIWorldMapActivityPanel:UpdateActive(player, tActive, tbCityInfo, tbCopyInfo, tbZoningData, tbTraffic, tbSVTInfo, bSpecial, tbParentMapID)
    local bShow, bFinish, szTime
    if not bSpecial then
        bShow, szTime = ActivityData.GetTimeText(tActive)
        local nCount, nTotalCount = ActivityData.GetActiveFinishCount(tActive, player)
        bFinish = nCount and nTotalCount and nCount >= nTotalCount
    else
        szTime = GBKToUTF8(tActive.szTimeRepresent)
    end

  
    if bSpecial or (bShow and player.nLevel >= tActive.nLevel and not bFinish) then
        local t = {
            tArgs = {
                nMapID = tActive.tMap,
                szName = GBKToUTF8(tActive.szName),
                szTime = szTime
            },
            tItemList = {},
            fnSelectedCallback = function(bSelected, scriptContainer)
                
            end
        }
        if tActive.tMap and #tActive.tMap > 0 then
            for i, dwMapID in ipairs(tActive.tMap) do
                local nMapID = tbParentMapID[dwMapID] or dwMapID
                local peripheral = tbCityInfo[nMapID] or tbCopyInfo[nMapID]
                if not peripheral then
                    LOG.ERROR("=====地图ID：%s缺少配置=====", tostring(dwMapID))
                else
                    table.insert(t.tItemList, {
                        tArgs = {
                            tbInfo = peripheral,
                            tbTraffic = tbTraffic,
                            toggleGroup = self.ActivityToggleGroup,
                        }
                    })
                end
            end
        end
        if tActive.tPointList then
            for nLinkID, _ in pairs(tActive.tPointList) do
                local tLink = Table_GetCareerLinkNpcInfo(nLinkID)
                local dwMapID = tLink.dwMapID
                local nMapID = tbParentMapID[dwMapID] or dwMapID
                local peripheral = tbCityInfo[nMapID] or tbCopyInfo[nMapID]
                if not peripheral then
                    LOG.ERROR("=====地图ID：%s缺少配置=====", tostring(dwMapID))
                else
                    table.insert(t.tItemList, {
                        tArgs = {
                            tbInfo = peripheral,
                            tbTraffic = tbTraffic,
                            toggleGroup = self.ActivityToggleGroup,
                        }
                    })
                end
            end
        end
        if #t.tItemList > 0 then
            table.insert(tbSVTInfo, t)
        end
    end
end
return UIWorldMapActivityPanel