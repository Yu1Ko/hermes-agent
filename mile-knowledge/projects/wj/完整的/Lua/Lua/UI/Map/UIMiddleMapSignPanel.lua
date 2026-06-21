local UIMiddleMapSignPanel = class("UIMiddleMapSignPanel")

function UIMiddleMapSignPanel:OnEnter(parent)
    self:SetVisible(false)
    self.tbIndex = {}
    self.tbSelected = {}
    self.bFromBubble = false
    self:RegisterEvent()
end

function UIMiddleMapSignPanel:OnExit()
    self:SetVisible(false)
end

function UIMiddleMapSignPanel:Show()
    self:SetVisible(true)
end

function UIMiddleMapSignPanel:SetVisible(bVisible)
    UIHelper.SetVisible(self._rootNode, bVisible)
end

function UIMiddleMapSignPanel:SetScrollVisible(bVisible)
    UIHelper.SetVisible(self.WidgetEmpty, not bVisible)
    UIHelper.SetVisible(self.WidgetScrollViewContent, bVisible)
end

function UIMiddleMapSignPanel:RegisterEvent()
    UIHelper.BindUIEvent(self.TogSet, EventType.OnSelectChanged, function(_, selected)
        self.WidgetAnchorSignSetPop:setVisible(selected)
    end)
    UIHelper.BindUIEvent(self.BtnAffirm, EventType.OnClick, function()
        self.WidgetAnchorSignSetPop:setVisible(false)
    end)
    UIHelper.BindUIEvent(self.BtnClose01, EventType.OnClick, function()
        self:SetVisible(false)

        for i, v in ipairs(self.tbNavScript or {}) do
            v:SetSelected(false)
        end
    end)
    UIHelper.BindUIEvent(self.BtnClose02, EventType.OnClick, function()
        self.WidgetAnchorSignSetPop:setVisible(false)
    end)
    local children = self.LayoutTab:getChildren()
    for _, node in ipairs(children) do
        UIHelper.BindUIEvent(node, EventType.OnSelectChanged, function()
            MapMgr.UnselectOther(node, children)
            UIHelper.ScrollViewDoLayout(self.ScrollViewContentSelect01)
            UIHelper.ScrollToTop(self.ScrollViewContentSelect01, 0, false)
        end)
    end
    for i, v in ipairs(self.tbTogType) do
        UIHelper.BindUIEvent(v, EventType.OnSelectChanged, function(obj, bSelected)
            MapMgr.UnselectOther(v, self.tbTogType)
            if bSelected then
                self.ScriptScrollViewTree:ClearContainer()
                if self.tbNavigationInfo[i] then
                    self:SetScrollVisible(true)
                    UIHelper.SetupScrollViewTree(self.ScriptScrollViewTree,
                        PREFAB_ID.WidgetMiddleNavigation, PREFAB_ID.WidgetMiddleNavigationCell,
                        function(scriptContainer, tArgs)
                            scriptContainer.Label1:setString(tArgs.kind)
                            scriptContainer.Label2:setString(tArgs.kind)
                            local tItemScripts = scriptContainer:GetItemScript()
                            if i==2 and self.bFromBubble and tItemScripts[1] then
                                tItemScripts[1]:SetSelected(true)
                                if tItemScripts[1].tbInfo then
                                    Event.Dispatch("ON_MIDDLE_MAP_MARK_SHOW", tItemScripts[1].tbInfo)
                                end
                            end
                        end,
                        self.tbNavigationInfo[i]
                    )
                else
                    self:SetScrollVisible(false)
                end
            end
        end)
    end

    UIHelper.BindUIEvent(self.BtnCloseNPC, EventType.OnClick, function()
        self:SetVisible(false)
    end)

    Event.Reg(self, "ON_SETMSGTOGTYPE", function() --选中信使tog并打开第一条内容
        self.bFromBubble = true
        UIHelper.SetSelected(self.tbTogType[2], true)
        self.ScriptScrollViewTree:SetContainerSelected(1,true)
    end)
end

function UIMiddleMapSignPanel:UpdateInfo(tbNpc, tbSelected, nMapID, nIndex, nCatalogue)
    self.nMapID = nMapID
    self.tbSelected = tbSelected
    self.tbNavigationInfo = {}

    local tbData = {}
    for k, v in pairs(tbNpc) do
        local tbCatalogue = MapHelper.GetMiddleMapNpcCatalogueIconTab(v.id)
        if tbCatalogue then
            if v.middlemap == nIndex and tbCatalogue.nNpcCatalogue ~= 0 then
                tbData[tbCatalogue.nNpcCatalogue] = tbData[tbCatalogue.nNpcCatalogue] or {}
                table.insert(tbData[tbCatalogue.nNpcCatalogue], v)
            end
        else
            LOG.INFO("------------------MapHelper.GetMiddleMapNpcCatalogueIconTab Error --------------------------")
            LOG.INFO("NPC [kind=%s] [id=%d] Not Found!", v.kind, v.id)
        end
    end

    for nType, tbNav in pairs(tbData) do
        self.tbNavigationInfo[nType] = self.tbNavigationInfo[nType] or {}
        for nNav, tbCell in ipairs(tbNav) do
            local tItemList = {}
            for i, v in ipairs(tbCell.group) do
                table.insert(tItemList, {
                    tArgs = {
                        nType, nNav, i, v, self.nMapID, self.tbIndex, tbCell.middlemap
                    }
                })
            end
            table.insert(self.tbNavigationInfo[nType], {
                tArgs = tbCell,
                tItemList = tItemList,
                fnSelectedCallback = function(bSelected) end,
            })
        end
    end

    self.ScriptScrollViewTree = UIHelper.GetBindScript(self.WidgetScrollViewContent)

    UIHelper.SetSelected(self.tbTogType[self.tbIndex.nType or 1], true)

    UIHelper.ScrollViewDoLayout(self.ScrollViewSignSet)
    UIHelper.ScrollToTop(self.ScrollViewSignSet, 0, false)

end

return UIMiddleMapSignPanel