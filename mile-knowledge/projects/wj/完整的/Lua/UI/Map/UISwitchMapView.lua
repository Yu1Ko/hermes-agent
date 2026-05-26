local UISwitchMapView = class("UISwitchMapView")

function UISwitchMapView:OnEnter(dwWindowID, tMapInfoList)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        Timer.AddFrameCycle(self, 1, function()
            self:UpdateTime()
        end)
    end

    self.tMapInfoList = tMapInfoList
    self:InitSwtichMap(dwWindowID)
    self:UpdateInfo()
    Timer.AddFrame(self, 1, function ()
        RemoteCallToServer("On_Castle_GetCastleTipsRequest")
    end)
end

function UISwitchMapView:OnExit()
    if self.confirmEnterScript then
        UIMgr.Close(self.confirmEnterScript)
        self.confirmEnterScript = nil
    end

    self.bInit = false
end

function UISwitchMapView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
		UIMgr.Close(VIEW_ID.PanelSwitchMap)
	end)
end

function UISwitchMapView:RegEvent()
    Event.Reg(self, EventType.AutoSelectSwitchMapWindow, function (nMapID)
        for _, tMapInfo in ipairs(self.tMapInfoList) do
            if table.contain_value(tMapInfo.tMapIDList, nMapID) then
                self:OnSelectMap(nMapID, true)
            end
        end
    end)
end

function UISwitchMapView:InitSwtichMap(dwWindowID)
    self.dwWindowID = dwWindowID
end

function UISwitchMapView:UpdateInfo()
    UIHelper.SetVisible(self.ScrollViewMapEntranceList, #self.tMapInfoList > 5)
    UIHelper.SetVisible(self.LayoutMapList, #self.tMapInfoList <= 5)

    local bHasNormal = false
    local bHasDungeon = false
    if #self.tMapInfoList > 5 then
        UIHelper.RemoveAllChildren(self.ScrollViewMapEntranceList)

        for _, tMapInfo in ipairs(self.tMapInfoList) do
            bHasNormal = bHasNormal or tMapInfo.nMapType ~= 1
            bHasDungeon = bHasDungeon or tMapInfo.nMapType == 1
            local scriptEntrance = UIHelper.AddPrefab(PREFAB_ID.WidgetMapEntrance, self.ScrollViewMapEntranceList, tMapInfo, function ()
                if tMapInfo.nMapType ~= 1 then
                    self:OnSelectMap(tMapInfo.tMapIDList[1])
                else
                    self:OnSelectDungeon(tMapInfo)
                end
            end)
            if scriptEntrance then
                UIHelper.SetAnchorPoint(scriptEntrance._rootNode, 0.5, 0)
            end
        end

        UIHelper.ScrollViewDoLayout(self.ScrollViewMapEntranceList)
        UIHelper.ScrollToLeft(self.ScrollViewMapEntranceList, 0)
    else
        UIHelper.RemoveAllChildren(self.LayoutMapList)
        for _,tMapInfo in ipairs(self.tMapInfoList) do
            bHasNormal = bHasNormal or tMapInfo.nMapType ~= 1
            bHasDungeon = bHasDungeon or tMapInfo.nMapType == 1
            UIHelper.AddPrefab(PREFAB_ID.WidgetMapEntrance, self.LayoutMapList, tMapInfo, function (tMapInfo)
                if tMapInfo.nMapType ~= 1 then
                    self:OnSelectMap(tMapInfo.tMapIDList[1])
                else
                    self:OnSelectDungeon(tMapInfo)
                end
            end)
        end
        UIHelper.LayoutDoLayout(self.LayoutMapList)
    end

    if bHasDungeon and not bHasNormal then
        UIHelper.SetString(self.LabelTip1, "请选择需要前往的秘境")
    elseif bHasDungeon and bHasNormal then
        UIHelper.SetString(self.LabelTip1, "请选择需要前往的地区或秘境")
    else
        UIHelper.SetString(self.LabelTip1, "请选择需要前往的地区")
    end
end

function UISwitchMapView:OnSelectMap(dwMapID, bIgnoreConfirm)
    -- 地图资源下载检测拦截
    if PakDownloadMgr.UserCheckDownloadMapRes(dwMapID, nil, nil, true) then
        if bIgnoreConfirm then
            self:DoEnterMap(dwMapID)
        else
            local szMapName = UIHelper.GBKToUTF8(Table_GetMapName(dwMapID))
            local szMsg = string.format(g_tStrings.TRAFFIC_TO_FIGHT_MAP_SURE, szMapName)
            self.confirmEnterScript = UIHelper.ShowConfirm(szMsg, function ()
                self.confirmEnterScript = nil
                self:DoEnterMap(dwMapID)
            end)
            self.confirmEnterScript:SetDynamicText(function()
                local nCurrentTime = GetCurrentTime()
                local tTime = TimeToDate(nCurrentTime)
                return string.format("当前系统时间：%02d:%02d:%02d", tTime.hour, tTime.minute, tTime.second)
            end)
        end
    end
end

function UISwitchMapView:OnSelectDungeon(tMapInfo)
    UIMgr.CloseWithCallBack(VIEW_ID.PanelSwitchMap, function ()
        UIMgr.Open(VIEW_ID.PanelDungeonDetail, self.dwWindowID, tMapInfo)
    end)
end

function UISwitchMapView:DoEnterMap(dwMapID)
    local tSwitchMapInfo = Table_GetSwitchMapInfo(dwMapID, self.dwWindowID)
    SelectSwitchMapWindow(tSwitchMapInfo.dwID)
    UIMgr.Close(VIEW_ID.PanelSwitchMap)
end

function UISwitchMapView:UpdateTime()
    local nCurrentTime = GetCurrentTime()
    local tTime = TimeToDate(nCurrentTime)
    local szTime = string.format("当前系统时间：%02d:%02d:%02d", tTime.hour, tTime.minute, tTime.second)
    UIHelper.SetString(self.LabelTime, szTime)
    UIHelper.SetVisible(self.LabelTime, true)
end

return UISwitchMapView