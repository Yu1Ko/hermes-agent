local UIMiddleMapTraceTransport = class("UIMiddleMapTraceTransport")

function UIMiddleMapTraceTransport:RegisterEvent()
    UIHelper.BindUIEvent(self.BtnUse, EventType.OnClick, function()
        MapMgr.UseResetItem()
    end)
end

function UIMiddleMapTraceTransport:OnEnter()
    self:RegisterEvent()
end

function UIMiddleMapTraceTransport:OnExit()
end


function UIMiddleMapTraceTransport:UpdateTransportItem()
    local bCD, szText = MapMgr.GetTransferSkillInfo()
    local nCount = MapMgr.GetResetItemCount()
    self.LabelTraceTime:setString(szText)

    if bCD and nCount == 0 then
        UIHelper.SetNodeGray(self.BtnTrace03, true, true)
        UIHelper.SetTouchEnabled(self.BtnTrace03, false)
    else
        UIHelper.SetNodeGray(self.BtnTrace03, false, true)
        UIHelper.SetTouchEnabled(self.BtnTrace03, true)
    end

    if not bCD then
        UIHelper.SetVisible(self.WidgetAnchorPropQuantuty, false)
        UIHelper.SetVisible(self.ImgTraceGray, false)
        UIHelper.SetVisible(self.LabelTraceTime, false)
    else
        UIHelper.SetVisible(self.WidgetAnchorPropQuantuty, true)
        UIHelper.SetVisible(self.ImgTraceGray, true)
        UIHelper.SetVisible(self.LabelTraceTime, true)
    end

    UIHelper.CascadeDoLayoutDoWidget(self.LayoutTrace, true, true)
end

function UIMiddleMapTraceTransport:Show(szName, nMapID, nCityID, tbIllegal)
    self._rootNode:setVisible(true)
    self.LabelTitleGo:setString(szName)

    tbIllegal = tbIllegal or {}

    if tbIllegal.Level then
        self.WidgetTraceAll:setVisible(false)
        self.LabelNoneLevel:setVisible(true)
        self.LabelClose:setVisible(false)
    elseif tbIllegal.Visit then
        self.WidgetTraceAll:setVisible(false)
        self.LabelNoneLevel:setVisible(false)
        self.LabelClose:setVisible(true)
    else
        self.WidgetTraceAll:setVisible(true)
        self.LabelNoneLevel:setVisible(false)
        self.LabelClose:setVisible(false)

        self.LabelCity:setString(string.format(g_tStrings.STR_TRAFFIC_BRACKETS, szName))

        local nCount = MapMgr.GetResetItemCount()

        local script = UIHelper.GetBindScript(self.WidgetItem_44)
        MapMgr.UpdateResetItemIcon(script)

        self.LabelQuantuty:setString(string.format("1/%d", nCount))

        self:UpdateTransportItem()
        self.nUpdateTimer = Timer.AddCycle(self, 0.5, function()
            self:UpdateTransportItem()
        end)

        UIHelper.BindUIEvent(self.BtnTrace03, EventType.OnClick, function()
            MapMgr.CheckTransferCDExecute(function()
                MapMgr.TransportToMap(nMapID, nCityID)
                UIMgr.Close(VIEW_ID.PanelMiddleMap)
                UIMgr.Close(VIEW_ID.PanelWorldMap)
                UIMgr.Close(VIEW_ID.PanelDungeonEntrance)
                UIMgr.CloseAllInLayer("UIPageLayer")
                UIMgr.CloseAllInLayer("UIPopupLayer")
            end)
        end)
    end
end

function UIMiddleMapTraceTransport:ShowTraffic(szName, nMapID, nNodeID, nCityID)
    self._rootNode:setVisible(true)
    self.LabelTitleGo:setString(szName)

    self.WidgetTraceAll:setVisible(true)
    self.LabelNoneLevel:setVisible(false)
    self.LabelClose:setVisible(false)
    self.WidgetAnchorPropQuantuty:setVisible(false)

    -- TODO
    self.LabelCity:setString(string.format(g_tStrings.STR_TRAFFIC_BRACKETS, szName))
    self.LabelTrace03:setString(g_tStrings.STR_TRAFFIC_GOTO)

    UIHelper.BindUIEvent(self.BtnTrace03, EventType.OnClick, function()
        RoadTrackStartOut(nNodeID, nCityID)
        UIMgr.Close(VIEW_ID.PanelMiddleMap)
        UIMgr.CloseAllInLayer("UIPageLayer")
        UIMgr.CloseAllInLayer("UIPopupLayer")
    end)
end

function UIMiddleMapTraceTransport:Hide()
    if self.nUpdateTimer then
        Timer.DelTimer(self, self.nUpdateTimer)
        self.nUpdateTimer = nil
    end
end

return UIMiddleMapTraceTransport