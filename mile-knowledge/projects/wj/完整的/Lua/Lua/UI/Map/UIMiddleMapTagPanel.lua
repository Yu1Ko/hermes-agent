local UIMiddleMapTagPanel = class("UIMiddleMapTagPanel")

function UIMiddleMapTagPanel:OnEnter()
    self:RegisterEvent()

    self.tbIconScripts = {}
    for nIndex, v in ipairs(self.tbIconList) do
        self.tbIconScripts[nIndex] = UIHelper.GetBindScript(v)
        self.tbIconScripts[nIndex]:UpdateInfo(nIndex)
    end
end

function UIMiddleMapTagPanel:OnExit()

end

function UIMiddleMapTagPanel:RegisterEvent()
    UIHelper.BindUIEvent(self.BtnCreate, EventType.OnClick, function()
        local bTeamMark = self:IsTeamMark()
        if bTeamMark then
            local nLPosx, nLPosy = self.tbInfo.nX, self.tbInfo.nY
            local bRet = MapMgr.ChangeSFXMark(nLPosx, nLPosy, self.tbInfo.nMapID)
            if bRet then
                self:UpdateInfo(MapMgr.GetTeamTag())
            end
        else
            self.tbInfo.bCreated = true
            local nTagCount = MapMgr.GetTagListLen(self.tbInfo.nMapID)
            if nTagCount < MapHelper.MAX_TAG_COUNT then
                MapMgr.AddNormalTag(self.tbInfo.nMapID, self.tbInfo)
                self:UpdateInfo(self.tbInfo)
            else
                OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_MIDDLE_MAP_TAG_OVERFLOW)
            end
        end
    end)
    UIHelper.BindUIEvent(self.BtnDelete, EventType.OnClick, function()
        if self:IsTeamMark() then
            MapMgr.ChangeSFXMark(0, 0, self.tbInfo.nMapID)
            self:Hide()
        else
            MapMgr.RemoveTracePointByUID(self.tbInfo.szUID)
            Event.Dispatch('ON_MIDDLE_MAP_TAG_REMOVE', self.tbInfo.nMapID, self.tbInfo.nIndex)
        end
    end)
    UIHelper.BindUIEvent(self.BtnCloseCustom, EventType.OnClick, function()
        Event.Dispatch('ON_MIDDLE_MAP_UPDATE_TAGS')
        self:Hide()
    end)
    UIHelper.BindUIEvent(self.BtnTrace04, EventType.OnClick, function()
        -- local nZ = Scene_GetFloor(self.tbInfo.nX, self.tbInfo.nY)
        local tbTagIconTab = MapHelper.GetMiddleMapTagIconTab(self.tbInfo.nIconID)
        local szFrame = tbTagIconTab and tbTagIconTab.szFrame or ""
        MapMgr.SetTracePoint(g_tStrings.CUSTOM_TRACE, self.tbInfo.nMapID, {self.tbInfo.nX, self.tbInfo.nY}, self.tbInfo.szUID, szFrame)
        self:Hide()
    end)

    UIHelper.BindUIEvent(self.BtnWalk, EventType.OnClick, function()
        -- 地图戳点
        local nX, nY = self.tbInfo.nX, self.tbInfo.nY
        local nZ = Scene_GetFloor(nX, nY)
        AutoNav.NavTo(self.tbInfo.nMapID, nX, nY, nZ, nil, "CustomPoint")
    end)
    UIHelper.BindUIEvent(self.BtnWalk_Custom, EventType.OnClick, function()
        local nX, nY = self.tbInfo.nX, self.tbInfo.nY
        local nZ = Scene_GetFloor(nX, nY)
        AutoNav.NavTo(self.tbInfo.nMapID, nX, nY, nZ)
    end)
    UIHelper.RegisterEditBoxEnded(self.EditSigh, function()
        self.tbInfo.szName = UIHelper.GetText(self.EditSigh)
        Storage.MiddleMapData.Dirty()
    end)
    Event.Reg(self, "ON_MIDDLE_MAP_ICON_SELECTED", function(obj, nIconID)
        self.tbInfo.nIconID = nIconID
        Storage.MiddleMapData.Dirty()
        Event.Dispatch('ON_MIDDLE_MAP_TAG_UPDATE_ICON', self.tbInfo)
        self:UpdateInfo(self.tbInfo)
    end)
end

function UIMiddleMapTagPanel:Show()
    UIHelper.SetVisible(self._rootNode, true)
end

function UIMiddleMapTagPanel:Hide()
    UIHelper.SetVisible(self._rootNode, false)
    UIHelper.SetVisible(self.WidgetAniSidePanel_Others, false)
end

function UIMiddleMapTagPanel:UpdateInfo(tbData, bCreated)
    self.tbInfo = tbData

    local bCreated = self.tbInfo.bCreated
    if bCreated then
        local bTeamTag = self:IsTeamMark()
        UIHelper.SetVisible(self.BtnCreate, false)

        UIHelper.SetVisible(self.BtnWalk_Custom, true)
        UIHelper.SetVisible(self.BtnDelete, not bTeamTag or TeamData.IsTeamLeader())
        UIHelper.SetVisible(self.BtnTrace04, true)

        UIHelper.SetVisible(self.BtnWalk, false)

    else
        local bTemporaryTrace = self:IsTemporaryTrace()
        UIHelper.SetVisible(self.BtnCreate, not bTemporaryTrace)--不是临时追踪标记

        UIHelper.SetVisible(self.BtnWalk_Custom, false)
        UIHelper.SetVisible(self.BtnDelete, false)
        UIHelper.SetVisible(self.BtnTrace04, bTemporaryTrace)
        UIHelper.SetVisible(self.BtnWalk, bTemporaryTrace)
    end
    UIHelper.SetString(self.LabelNum, string.format(g_tStrings.STR_MIDDLE_MAP_TAG_COUNT, MapMgr.GetTagListLen(tbData.nMapID), MapHelper.MAX_TAG_COUNT))
    UIHelper.SetText(self.EditSigh, tbData.szName)

    local szContent = self:IsTeamMark() and g_tStrings.CREATE_TEAM_MARK or g_tStrings.CREATE_CUSTOM_MARK
    UIHelper.SetString(self.LabelCreate, szContent)

    for _, script in ipairs(self.tbIconScripts) do
        script:SetSelected(false)
    end
    self.tbIconScripts[tbData.nIconID]:SetSelected(true)

    local bLeader = TeamData.IsTeamLeader()
    local bShowTeamporary = (not bCreated) or (bCreated and self:IsTemporaryTrace())
    local bShowTeam = (not bCreated and bLeader) or (bCreated and self:IsTeamMark())
    local bShowEdit = (not bCreated) or (bCreated and not self:IsTeamMark() and not self:IsTemporaryTrace())

    UIHelper.SetVisible(self.WidgetTeam, bShowTeam)
    UIHelper.SetVisible(self.WidgetEdit, bShowEdit)
    UIHelper.SetVisible(self.WidgetTemporary, bShowTeamporary)

    UIHelper.LayoutDoLayout(self.LayoutCustom)
end

function UIMiddleMapTagPanel:IsTeamMark()
    return self.tbInfo.nIconID == 8
end

function UIMiddleMapTagPanel:IsTemporaryTrace()
    return self.tbInfo.nIconID == 7
end

return UIMiddleMapTagPanel