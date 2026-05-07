local UIWorldCitySelect = class("UIWorldCitySelect")

function UIWorldCitySelect:OnEnter(tArgs)
    self:RegisterEvent()
    UIHelper.SetNodeSwallowTouches(self._rootNode, false, true)
    if tArgs then
        self:UpdateInfo(tArgs.tbInfo, tArgs.bTransport)
    end
end

function UIWorldCitySelect:UpdateSelected(bSelected)
    self.bSelected = bSelected
    if self.bTransport then
        Event.Dispatch(EventType.OnMapTraceZoning, self.tbInfo.nMapID, bSelected)
    elseif self.tbTraffic.bTraffic then
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

function UIWorldCitySelect:RegisterEvent()
    UIHelper.BindUIEvent(self.TogCitySelect, EventType.OnSelectChanged, function(_, bSelected)
        self.bSelected = bSelected
        if self.fnSelected then
            self.fnSelected(bSelected)
        end
        self:UpdateSelected(bSelected)
    end)

    UIHelper.BindUIEvent(self.TogLike,  EventType.OnClick, function()
        local bSelected = UIHelper.GetSelected(self.TogLike)
        if bSelected then
            if not MapMgr.AddLikeMap(self.tbInfo.nMapID) then
                UIHelper.SetSelected(self.TogLike, false, false)
            end
        else
            MapMgr.RemoveLikeMap(self.tbInfo.nMapID)
        end
    end)

    Event.Reg(self, 'ON_WORLD_MAP_TEAMMATE_UPDATE', function(tbTeammate)
        if not self.tbInfo or not self.tbInfo.nMapID then
            return
        end
        UIHelper.SetVisible(self.ImgTeam, tbTeammate[self.tbInfo.nMapID] and true or false)
    end)

    Event.Reg(self, EventType.OnLikeMapListChange, function()
        UIHelper.SetSelected(self.TogLike, MapMgr.IsLikeMap(self.tbInfo.nMapID), false)
    end)
end

function UIWorldCitySelect:UpdateLocation()
    local player = g_pClientPlayer
    local script = UIHelper.GetBindScript(self.WidgetLocation)
    if script then
        script:Enable(self.tbInfo.nMapID == player.GetMapID())
    end

    UIHelper.SetVisible(self.WidgetAniTrace, MapMgr.IsMapTraced(self.tbInfo.nMapID))
end

function UIWorldCitySelect:UpdateInfo(tbInfo, bTransport, tbTraffic)
    self.tbInfo = tbInfo
    self.tbTraffic = tbTraffic or {}
    self.bSelected = false
    self.LabelCityName01:setString(tbInfo.szComment)
    UIHelper.SetSelected(self.TogCitySelect, false, false)

    if tbInfo.szFrame and tbInfo.szFrame ~= "" then
        UIHelper.SetSpriteFrame(self.ImgCity, tbInfo.szFrame)
    end

    self:UpdateLocation()

    --资源下载Widget
    local scriptDownload = UIHelper.GetBindScript(self.WidgetDownload)
    local nPackID = PakDownloadMgr.GetMapResPackID(self.tbInfo.nMapID)
    scriptDownload:OnInitWithPackID(nPackID, {bShowBg = true})
    
    UIHelper.SetSelected(self.TogLike, MapMgr.IsLikeMap(self.tbInfo.nMapID), false)
end

function UIWorldCitySelect:SetSelected(bSelected)
    if self.bSelected == bSelected then
        return
    end
    UIHelper.SetSelected(self.TogCitySelect, bSelected, false)
    self:UpdateSelected(bSelected)
end

return UIWorldCitySelect