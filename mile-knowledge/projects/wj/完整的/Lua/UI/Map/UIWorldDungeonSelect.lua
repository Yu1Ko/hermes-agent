local UIWorldDungeonSelect = class("UIWorldDungeonSelect")

function UIWorldDungeonSelect:OnEnter(tArgs)
    UIHelper.SetNodeSwallowTouches(self._rootNode, false, true)
    if type(tArgs) == "table" then
        self:UpdateInfo(tArgs.tbInfo, tArgs.tbTraffic)
    end
end

function UIWorldDungeonSelect:UpdateSelected(bSelected, bExpand)
    self.bSelected = bSelected
    UIHelper.SetVisible(self.ImgDungeon_Select03, bSelected)
    if bExpand then
        UIHelper.SetVisible(self.WidgerButton, bSelected)
        self:UpdateLayout()
    end
end

function UIWorldDungeonSelect:RegisterEvent()
    -- 神行
    UIHelper.BindUIEvent(self.BtnTrace, EventType.OnClick, function()
        MapMgr.TryTransfer(self.tbInfo.nMapID, nil, true)
    end)

    -- 查看
    UIHelper.BindUIEvent(self.BtnDelete, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelMiddleMap, self.tbInfo.nMapID, 0)
    end)

    UIHelper.BindUIEvent(self.TogDungeonSelect, EventType.OnSelectChanged, function(_, bSelected)

        if self.bDungeon then
            self:OnDungeonSelectChanged(bSelected)
        else
            self:OnCitySelectChanged(bSelected)
        end
    end)

    Event.Reg(self, 'ON_MAP_DUNGEON_TOGGLE', function(obj, bSelected)
        if bSelected and self.bSelected and self ~= obj then
            UIHelper.SetSelected(self.TogDungeonSelect, false)
            self:UpdateSelected(false)
        end
    end)

    Event.Reg(self, 'ON_WORLD_MAP_TEAMMATE_UPDATE', function(tbTeammate)
        if not self.tbInfo or not self.tbInfo.nMapID then
            return
        end
        UIHelper.SetVisible(self.ImgTeam, tbTeammate[self.tbInfo.nMapID] and true or false)
    end)

    Event.Reg(self, "ON_SELECT_WORLD_ACTIVITY", function()
        self:SetSelectedWithExpand(false)
    end)
end

function UIWorldDungeonSelect:UpdateLocation()
    local player = g_pClientPlayer
    local script = UIHelper.GetBindScript(self.WidgetLocation)
    if script then
        script:Enable(self.tbInfo.nMapID == player.GetMapID())
    end

    UIHelper.SetVisible(self.WidgetAniTrace, MapMgr.IsMapTraced(self.tbInfo.nMapID))
end

function UIWorldDungeonSelect:UpdateLayout()
    UIHelper.LayoutDoLayout(self.LayoutDungeonSelect)
    UIHelper.LayoutDoLayout(self.WidgetWorldDungeonSelect)
    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, false)
end

function UIWorldDungeonSelect:UpdateInfo(tbInfo, tbTraffic)
    if not tbInfo then return end
    self.bDungeon = tbInfo.szType == nil--是秘境，两种数据结构不一样，注意取到空值，秘境UIWorldMapCopyTab表，城市UIWorldMapCityTab表
    if self.bDungeon then
        self:UpdateDungeonInfo(tbInfo, tbTraffic)
    else
        self:UpdateCityInfo(tbInfo, tbTraffic)
    end
end

function UIWorldDungeonSelect:UpdateDungeonInfo(tbInfo, tbTraffic)
    self.tbInfo = tbInfo
    self.bSelected = false

    self.tbTraffic = tbTraffic or {}

    UIHelper.SetSelected(self.TogDungeonSelect, false, false)
    UIHelper.SetEnable(self.TogDungeonSelect, not self.tbTraffic.bTraffic)
    UIHelper.SetString(self.LabelCityName01, tbInfo.szComment, 7)
    if tbInfo.szFrame and tbInfo.szFrame ~= "" then
        UIHelper.SetSpriteFrame(self.ImgDungeonIcon01, tbInfo.szFrame)
    end
    UIHelper.SetNodeGray(self.ImgDungeonIcon01, self.tbTraffic.bTraffic and true or false, true)
    UIHelper.SetVisible(self.ImgDungeonIcon01, self.bDungeon)
    UIHelper.SetVisible(self.ImgCityIcon, not self.bDungeon)

    self:RegisterEvent()
    self:UpdateLocation()
    self:UpdateLayout()

    --资源下载Widget
    local nMapID = self.tbInfo.nMapID
    local scriptDownload = UIHelper.GetBindScript(self.WidgetDownload)
    local nPackID = PakDownloadMgr.GetMapResPackID(nMapID)
    local nEnterPackID

    --下载秘境资源时，需同时下载秘境+秘境入口两张地图
    local tDungeonInfo = Table_GetDungeonInfo(nMapID)
    if tDungeonInfo then
        local nEnterMapID = tDungeonInfo and tDungeonInfo.nEnterMapID
        nEnterPackID = PakDownloadMgr.GetMapResPackID(nEnterMapID)
    end

    scriptDownload:OnInitWithPackID(nPackID, {nDungeonEnterPackID = nEnterPackID, bShowBg = true})
end

function UIWorldDungeonSelect:UpdateCityInfo(tbInfo, tbTraffic)
    self.tbInfo = tbInfo
    self.bSelected = false

    self.tbTraffic = tbTraffic or {}

    UIHelper.SetSelected(self.TogDungeonSelect, false, false)
    UIHelper.SetEnable(self.TogDungeonSelect, not self.tbTraffic.bTraffic)
    UIHelper.SetString(self.LabelCityName01, tbInfo.szComment, 7)
    if tbInfo.szFrame and tbInfo.szFrame ~= "" then
        UIHelper.SetSpriteFrame(self.ImgCityIcon, tbInfo.szFrame)
    end
    UIHelper.SetNodeGray(self.ImgCityIcon, self.tbTraffic.bTraffic and true or false, true)
    UIHelper.SetVisible(self.ImgDungeonIcon01, self.bDungeon)
    UIHelper.SetVisible(self.ImgCityIcon, not self.bDungeon)

    self:RegisterEvent()
    self:UpdateLocation()
    self:UpdateLayout()

    --资源下载Widget
    local nMapID = self.tbInfo.nMapID
    local scriptDownload = UIHelper.GetBindScript(self.WidgetDownload)
    local nPackID = PakDownloadMgr.GetMapResPackID(nMapID)
    local nEnterPackID

    --下载秘境资源时，需同时下载秘境+秘境入口两张地图
    local tDungeonInfo = Table_GetDungeonInfo(nMapID)
    if tDungeonInfo then
        local nEnterMapID = tDungeonInfo and tDungeonInfo.nEnterMapID
        nEnterPackID = PakDownloadMgr.GetMapResPackID(nEnterMapID)
    end

    scriptDownload:OnInitWithPackID(nPackID, {nDungeonEnterPackID = nEnterPackID, bShowBg = true})
end

function UIWorldDungeonSelect:OnDungeonSelectChanged(bSelected)
    local bSelected = bSelected
    self:UpdateSelected(bSelected, not MapHelper.IsMapSwitchServer(self.tbInfo.nMapID))
    if MapHelper.IsMapSwitchServer(self.tbInfo.nMapID) then
        -- local player = g_pClientPlayer
        -- if player and player.nCamp == CAMP.NEUTRAL then
        --     UIMgr.Open(VIEW_ID.PanelPvPCampJoin)
        -- else
            UIMgr.Open(VIEW_ID.PanelQianLiFaZhu)
        -- end
        UIMgr.Close(VIEW_ID.PanelMiddleMap)
        UIMgr.Close(VIEW_ID.PanelWorldMap)
        MapMgr.ClearMapTrace()
    end
    if self.fnSelected then
        self.fnSelected(bSelected)
    end
    Event.Dispatch('ON_MAP_DUNGEON_TOGGLE', self, bSelected)
    Event.Dispatch(EventType.OnMapTraceZoning, self.tbInfo.nMapID, bSelected)
end

function UIWorldDungeonSelect:OnCitySelectChanged(bSelected)
    local bSelected = bSelected
    self:UpdateSelected(bSelected)
    if self.fnSelected then
        self.fnSelected(bSelected)
    end
    Event.Dispatch('ON_MAP_DUNGEON_TOGGLE', self, bSelected)
    Event.Dispatch(EventType.OnMapTraceZoning, self.tbInfo.nMapID, bSelected)
    if bSelected then self:OnSelectedCity() end
end

function UIWorldDungeonSelect:OnSelectedCity()
    if self.tbTraffic.bTraffic then
        local nPoint = self.tbTraffic.nPoint
        local nTrafficID = self.tbInfo.nTrafficID

        local bOk = RoadTrackIsReachable(nPoint, nTrafficID)
        if not bOk then
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.TRAFFIC_CANNOT_ARRIVE)
            return 
        end

        -- 地图资源下载检测拦截
        if PakDownloadMgr.UserCheckDownloadMapRes(self.tbInfo.nMapID, nil, nil, true) then
            UIHelper.ShowConfirm(FormatString(g_tStrings.TRAFFIC_SURE_GO, self.tbInfo.szComment), function()
                RoadTrackStartOut(nPoint, nTrafficID)
                UIMgr.Close(VIEW_ID.PanelWorldMap)
            end)
        end
    else
        local script = UIMgr.GetViewScript(VIEW_ID.PanelWorldMap)
        local bTrafficNodeSkill = script:GetIsTrafficNodeSkill()
        UIMgr.Open(VIEW_ID.PanelMiddleMap, self.tbInfo.nMapID, 0, self.tbInfo, nil, nil, bTrafficNodeSkill)
    end
end

function UIWorldDungeonSelect:SetSelected(bSelected)
    if self.bSelected == bSelected then
        return
    end
    UIHelper.SetSelected(self.TogDungeonSelect, bSelected, false)
    self:UpdateSelected(bSelected)
end

function UIWorldDungeonSelect:SetSelectedWithExpand(bSelected)
    if self.bSelected == bSelected then
        return
    end
    UIHelper.SetSelected(self.TogDungeonSelect, bSelected, false)
    self:UpdateSelected(bSelected, true)
end

function UIWorldDungeonSelect:IsSelect()
    return UIHelper.GetSelected(self.TogDungeonSelect)
end

return UIWorldDungeonSelect