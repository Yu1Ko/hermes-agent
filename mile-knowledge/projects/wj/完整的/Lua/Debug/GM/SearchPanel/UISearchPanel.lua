-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UISearchPanel
-- Date: 2022-12-28 18:48:56
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UISearchPanel = class("UISearchPanel")

function UISearchPanel:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.EditSearchInfo:setTouchEnabled(false)
    SearchPanel.GetMapList()
    self:UpdateInfo()
end

function UISearchPanel:OnExit()
    self.bInit = false
    self:UnRegEvent()
    self.NPCTableView:setVisible(false)
    SearchPanel.tLastCell = nil
end

function UISearchPanel:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnSpeedCall, EventType.OnClick, function(btn)
        self.SearchPanelLeft:setVisible(false)
        self.SearchPanelRight:setVisible(false)
        self.WidgetSpeedCall:setVisible(true)
        local scriptView = UIHelper.GetBindScript(self.WidgetSpeedCall)
        scriptView:UpdateInfo(self)
        -- UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnSearch, EventType.OnClick, function(btn)
            self.NPCTableView:setVisible(true)
            self.SearchPanelRight:setVisible(false)
            local szSearchValue = UIHelper.GetString(self.EditSearch)
            local szMapName = UIHelper.GetString(self.LabelDropList)
            if szSearchValue == '' then
                SearchPanel.ListNPC(szMapName)
            else
                SearchPanel.SearchNPC(szMapName, szSearchValue)
            end
            UIHelper.TableView_init(self.NPCTableView, #SearchPanel.tInfo, PREFAB_ID.WidgetSearchPanel)
            UIHelper.TableView_reloadData(self.NPCTableView)
    end)

    UIHelper.RegisterEditBoxChanged(self.EditSearch, function()
        local szSearchValue = UIHelper.GetString(self.EditSearch)
        if not UIHelper.GetVisible(self.NPCTableView) then
            -- 根据编辑框的输入改变地图的筛选
            SearchPanel.tSearchResult = {}
            for _, tData in pairs(SearchPanel.tMapList) do
                if tData.nKey == tonumber(szSearchValue) or string.find(tData.szText, szSearchValue)then
                    table.insert(SearchPanel.tSearchResult,tData)
                end
            end
            UIHelper.TableView_init(self.ScrollViewDropList, #SearchPanel.tSearchResult, PREFAB_ID.WidgetSelectTog358X86)
            UIHelper.TableView_reloadData(self.ScrollViewDropList)
        end
    end)


    UIHelper.BindUIEvent(self.TogDropList, EventType.OnSelectChanged, function (_, bSelected)
        self.ScrollViewDropList:setVisible(true)
        self.NPCTableView:setVisible(false)
        self.EditSearch:setPlaceHolder('查找地图')
    end)

    --地图切换
    UIHelper.TableView_addCellAtIndexCallback(self.ScrollViewDropList, function(tableView, nIndex, script, node, cell)
        if not next(SearchPanel.tSearchResult) then
            SearchPanel.tSearchResult = SearchPanel.tMapList
        end
        local tMap = SearchPanel.tSearchResult[nIndex]
        script:OnEnter(tMap.nKey, tMap.szText, function (nKey, szText)
            SearchPanel.nSelectPushType = nKey
            UIHelper.SetSelected(self.TogDropList, false)
            UIHelper.SetString(self.LabelDropList, szText)
            --切换地图是直接获取对应NPC
            self.NPCTableView:setVisible(true)
            self.SearchPanelRight:setVisible(false)
            local szMapName = UIHelper.GetString(self.LabelDropList)
            SearchPanel.ListNPC(szMapName)
            UIHelper.TableView_init(self.NPCTableView, #SearchPanel.tInfo, PREFAB_ID.WidgetSearchPanel)
            UIHelper.TableView_reloadData(self.NPCTableView)
            UIHelper.SetString(self.EditSearch, '')
            self.EditSearch:setPlaceHolder('查找NPC')
            SearchPanel.tSearchResult = {}
            -- self:ToggleSelect()

        end, tMap.nKey == SearchPanel.nSelectPushType)

        if tMap.nKey == SearchPanel.nSelectPushType then
            UIHelper.SetString(self.LabelDropList, tMap.szText)
        end
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupDropList, script.ToggleSelect)
    end)

    --NPC信息
    UIHelper.TableView_addCellAtIndexCallback(self.NPCTableView, function(tableView, nIndex, script, node, cell)
        local tNPC = SearchPanel.tInfo[nIndex]
        if script and tNPC then
            script:OnEnter(self, tNPC)
        end
    end)

    --NPC右侧面板
    UIHelper.TableView_addCellAtIndexCallback(self.TableViewCMD, function(tableView, nIndex, script, node, cell)
        local tGMCMD = SearchPanel.tGMCMD[nIndex]
        if script and tGMCMD then
            script:OnEnter(self, tGMCMD)
        end
    end)
end


function UISearchPanel:ToggleSelect()
    UIHelper.TableView_init(self.ScrollViewDropList, #SearchPanel.tMapList, PREFAB_ID.WidgetSelectTog358X86)
    UIHelper.TableView_reloadData(self.ScrollViewDropList)
end

function UISearchPanel:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UISearchPanel:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UISearchPanel:UpdateInfo()
    UIHelper.SetSelected(self.TogDelivery, SearchPanel.bTogDelivery)
    self:ToggleSelect()
    local szMapName = UIHelper.GetString(self.LabelDropList)
    if SearchPanel.szMapName ~= szMapName and SearchPanel.szMapName ~= '' then
        UIHelper.SetString(self.LabelDropList, SearchPanel.szMapName)
        SearchPanel.ListNPC(SearchPanel.szMapName)
        UIHelper.TableView_init(self.NPCTableView, #SearchPanel.tInfo, PREFAB_ID.WidgetSearchPanel)
        UIHelper.TableView_reloadData(self.NPCTableView)
    end
end


return UISearchPanel