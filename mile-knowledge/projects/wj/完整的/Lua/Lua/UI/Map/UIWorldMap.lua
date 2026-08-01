local UIWorldMap = class("UIWorldMap")

local SCALE_MAX = 2
local SCALE_MIN = 0.5

function UIWorldMap:GetZoningName(dwMapID)
    for szName, zoning in pairs(self.tbZoningData) do
        for i, mapID in ipairs(zoning.tChildCopyMaps) do
            if mapID == dwMapID then
                return szName
            end
        end
        for i, mapID in ipairs(zoning.tChildCityMaps) do
            if mapID == dwMapID then
                return szName
            end
        end
    end
end


function UIWorldMap:GetZoningScript(nMapID)
    local szZoning = self:GetZoningName(nMapID)
    return self.tbZoningScript[szZoning]
end


function UIWorldMap:TraceMap(dwMapID, bHighlight, bOpenPeripheral)
    local zoningScript = self:GetZoningScript(dwMapID)
    if not zoningScript then
        local mapName = GBKToUTF8(Table_GetMapName(dwMapID))
        LOG.INFO(string.format("---------------------------- [WorldMap] Zoning %s(%d) Not Exist!", mapName, dwMapID))
        if self.bJump then
            UIMgr.Open(VIEW_ID.PanelMiddleMap, dwMapID, 0)
        end
        return
    end

    local parent = zoningScript._rootNode:getParent()
    local x, y = UIHelper.GetPosition(parent)
    local nScale = UIHelper.GetScale(self.WidgetWorldMap)

    self.TouchComponent:SetPosition(-x * nScale, -y * nScale)
    zoningScript:Highlight(bHighlight)

    if bHighlight then
        MapMgr.SetMapTrace(dwMapID)
    end

    if bOpenPeripheral then
        self:OpenPeripheral(self:GetZoningName(dwMapID))
    end
end

function UIWorldMap:SelectZoning(szZoningName, bEnable)
    local zoningScript = self.tbZoningScript[szZoningName]
    zoningScript:Select(bEnable)
end

function UIWorldMap:UpdatePlayerLocation()
    local player = GetClientPlayer()
    if not player then return end

    local dwMapID = player.GetMapID()
    local zoningScript = self:GetZoningScript(dwMapID)
    if zoningScript then
        zoningScript:Locate(true)
    end
end

function UIWorldMap:UpdateTeammate()
    local tbTeammate = {}
    local player = GetClientPlayer()
    if not player then return end

    for _, script in pairs(self.tbZoningScript) do
        script:SetTeammate(false)
    end
    TeamData.Generator(function(dwID, tMemberInfo)
        if dwID ~= player.dwID and tMemberInfo.bIsOnLine then
            local script = self:GetZoningScript(tMemberInfo.dwMapID)
            script:SetTeammate(true)

            tbTeammate[tMemberInfo.dwMapID] = true
        end
    end)
    Event.Dispatch("ON_WORLD_MAP_TEAMMATE_UPDATE", tbTeammate)
end

function UIWorldMap:OpenPeripheral(szName)
    if UIHelper.GetVisible(self.WidgetAni_Search) then return end
    self:LoadPeripheralList()
    local zoningData = self.tbZoningData[szName]
    self.CityScript:Hide()
    self.ActivityScript:Hide()
    self.PeripheralScript:ShowPeripheral(szName, zoningData, self.tbCityInfo, self.tbCopyInfo, self.tbTraffic)
    self:SelectZoning(szName, true)
end

function UIWorldMap:RegisterEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(VIEW_ID.PanelMiddleMap)
        UIMgr.Close(self)
        MapMgr.ClearMapTrace()
    end)

    UIHelper.BindUIEvent(self.BtnMidMap, EventType.OnClick, function()
        local middleMap = UIMgr.GetView(VIEW_ID.PanelMiddleMap)
        if middleMap then
            UIMgr.CloseImmediately(VIEW_ID.PanelMiddleMap)
        end
        UIMgr.CloseImmediately(self)
        UIMgr.Open(VIEW_ID.PanelMiddleMap)
        MapMgr.ClearMapTrace()
    end)

    UIHelper.BindUIEvent(self.BtnMapClose, EventType.OnClick, function()
        if not self.bCityClick then
            self.CityScript:Hide()
            self.PeripheralScript:Hide()
            self.SearchScript:Hide()
            self.ActivityScript:Hide()

            Event.Dispatch("ON_WORLD_MAP_CITY_SELECT", nil, false)
            Event.Dispatch("ON_WORLD_MAP_CITY_HIGHLIGHT", nil, false)
            MapMgr.ClearMapTrace()
        end

        self.bCityClick = false
    end)

    UIHelper.BindUIEvent(self.BtnMapClose, EventType.OnTouchBegan, function(btn, nX, nY)
        self.TouchComponent:TouchBegin(nX, nY)
    end)

    UIHelper.BindUIEvent(self.BtnMapClose, EventType.OnTouchMoved, function(btn, nX, nY)
        self.TouchComponent:TouchMoved(nX, nY)
    end)

    UITouchHelper.BindUIZoom(self.WidgetTouch, function(delta)
        if self.TouchComponent then
            self.TouchComponent:Zoom(delta)
        end
    end)

    UIHelper.BindUIEvent(self.BtnCity, EventType.OnClick, function()
        self:LoadCityList()
        self.CityScript:UpdateInfo(self.tbCityCatalog, self.tbCopyCatalog)
        self.CityScript:Show(self)
    end)

    UIHelper.BindUIEvent(self.BtnSearch, EventType.OnClick, function()
        self:LoadCityList()
        -- self.SearchScript:UpdateInfo(self.tbCityCatalog, self.tbCopyCatalog)
        self.SearchScript:Show(self)
    end)

    UIHelper.BindUIEvent(self.BtnActivity, EventType.OnClick, function()
        self:LoadPeripheralList()
        self.ActivityScript:Show()
    end)

    UIHelper.BindUIEvent(self.BtnLineUp, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelMapLineUpPop)
    end)

    Event.Reg(self, EventType.OnMapTraceZoning, function(nMapID, bHighlight, OpenPeripheral)
        self:TraceMap(nMapID, bHighlight, OpenPeripheral)
    end)

    Event.Reg(self, EventType.OnMapQueueDataUpdate, function()
        self:UpdateMapQueueInfo()
    end)

    Event.Reg(self, EventType.OnViewClose, function(nViewID)--勉强处理一下，防止中地图关闭导致缩放事件被注销
        if nViewID == VIEW_ID.PanelMiddleMap then
            UITouchHelper.BindUIZoom(self.WidgetTouch, function(delta)
                if self.TouchComponent then
                    self.TouchComponent:Zoom(delta)
                end
            end)
        end
    end)
end

function UIWorldMap:UnRegisterEvent()

end

function UIWorldMap:InitSidePanel()
    self.CityScript = UIHelper.GetBindScript(self.WidgetAni_City)
    self.PeripheralScript = UIHelper.GetBindScript(self.WidgetAni_Peripheral)
    self.SearchScript = UIHelper.GetBindScript(self.WidgetAni_Search)
    self.ActivityScript = UIHelper.GetBindScript(self.WidgetAni_Activity)
end

function UIWorldMap:OnEnter(tbParam)
    self:InitSidePanel()
    self:RegisterEvent()

    self.TouchComponent = require("Lua/UI/Map/Component/UIMapTouchComponent"):CreateInstance()
    self.TouchComponent:Init(self.WidgetWorldMap)
    self.TouchComponent:SetScaleLimit(SCALE_MIN, SCALE_MAX)
    self.TouchComponent:RegisterScaleEvent(function(nScale)
        Event.Dispatch("ON_WORLD_MAP_SCALE", nScale)
    end)

    self.bJump = false

    self:UpdateList()
    self:Update()
    self.nUpdateTimer = Timer.AddCycle(self, 0.1, function()
        self:Update()
    end)

    tbParam = tbParam or {}

    local nTraceMapID = tbParam.nTraceMapID
    if not nTraceMapID then
        local player = GetClientPlayer()
        if player then
            nTraceMapID = player.GetMapID()
        end
    end
    self.tbTraffic = {
        bTraffic = tbParam.bTraffic,
        nPoint = tbParam.nTrafficID,
    }
    self:TraceMap(nTraceMapID)
    self:UpdateMapQueueInfo()

    MapMgr.UpdateActivityState()
end

function UIWorldMap:Update()
    self:UpdatePlayerLocation()
    self:UpdateTeammate()
end

function UIWorldMap:LoadZoning()
    self.tbZoningData = {}
    for k, v in pairs(UIWorldMapZoningTab) do
        local tbChildCityMaps = loadstring("return" .. v.szChildCityMaps)
        local tbChildCopyMaps = loadstring("return" .. v.szChildCopyMaps)

        self.tbZoningData[v.szName] = {
            szShowLevel = v.szShowLevel,
            szName = v.szName,
            szFrame = v.szFrame,
            szCampFrame = v.szCampFrame,
            nSize = v.nSize,
            tChildCityMaps = tbChildCityMaps(),
            tChildCopyMaps = tbChildCopyMaps(),
        }
    end
end

function UIWorldMap:UpdateList()
    self:LoadZoning()
    self.tbZoningScript = {}

    for k, v in pairs(UIWorldMapZoningTab) do
        local widget = self.WidgetCityIcon:getChildByName(v.szWidgetName) -- TODO
        if widget then
            local tbInfo = self.tbZoningData[v.szName]
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetWorldCityIcon, widget, v.szName, tbInfo)

            --获取地图资源列表
            local tPackIDList = {}
            for _, nMapID in ipairs(tbInfo.tChildCityMaps or {}) do
                local nPackID = PakDownloadMgr.GetMapResPackID(nMapID)
                table.insert(tPackIDList, nPackID)
            end
            for _, nMapID in ipairs(tbInfo.tChildCopyMaps or {}) do
                local nPackID = PakDownloadMgr.GetMapResPackID(nMapID)
                table.insert(tPackIDList, nPackID)
            end

            --资源下载组件：资源下载完成后提示
            local scriptDownload = UIHelper.GetBindScript(script.WidgetDownload)
            scriptDownload:OnInitWithCompleteHintPackIDList(tPackIDList)

            script.fnClick = function(szName)
                self.bCityClick = true
                self:OpenPeripheral(szName)
                scriptDownload:SetVisible(false) --点击按钮后隐藏资源下载完成提示
            end
            self.tbZoningScript[v.szName] = script
        else
            LOG.INFO("---ERROR MAP NODE WIDGET----")
            LOG.INFO(v.szWidgetName)
        end
    end
end

function UIWorldMap:OnExit()
    self:UnRegisterEvent()

    if self.nUpdateTimer then
        Timer.DelTimer(self, self.nUpdateTimer)
        self.nUpdateTimer = nil
    end

    UITouchHelper.UnBindUIZoom()
end

function UIWorldMap:LoadCityList()
    if self.tbCityCatalog and self.tbCopyCatalog then
        return
    end
    self.tbCityCatalog = {}
    self.tbCopyCatalog = {}

    local nType = 1
    local CityType = {}
    for i, v in ipairs(UIWorldMapCityTab) do
        if not CityType[v.szType] then
            CityType[v.szType] = nType
            self.tbCityCatalog[nType] = {
                szType = v.szType,
                nType = nType,
            }
            nType = nType + 1
        end

        table.insert(self.tbCityCatalog[CityType[v.szType]], v)
    end

    nType = 1
    local CopyVersion = {}
    for i, v in ipairs(UIWorldMapCopyTab) do
        if not CopyVersion[v.szVersion] then
            CopyVersion[v.szVersion] = nType
            self.tbCopyCatalog[nType] = {
                szType = v.szVersion,
                nType = nType,
            }
            nType = nType + 1
        end

        table.insert(self.tbCopyCatalog[CopyVersion[v.szVersion]], v)
    end
end

function UIWorldMap:LoadPeripheralList()
    if self.tbCityInfo and self.tbCopyInfo then
        return
    end
    self.tbCityInfo = {}
    for k, v in pairs(UIWorldMapCityTab) do
        self.tbCityInfo[v.nMapID] = v
    end
    self.tbCopyInfo = {}
    self.tbParentMapID = {}
    for k, v in pairs(UIWorldMapCopyTab) do
        self.tbCopyInfo[v.nMapID] = v
        local szOtherMapID = v.szOtherMapID
        local tbOtherMapID = string.split(szOtherMapID, ",")
        for nIndex, szMapID in ipairs(tbOtherMapID) do
            self.tbParentMapID[tonumber(szMapID)] = v.nMapID
        end
    end
end

function UIWorldMap:UpdateMapQueueInfo()
    local tNormalTips = BubbleMsgData.GetMsgByType("MapQueueTips")
    local tPVPFieldTips = BubbleMsgData.GetMsgByType("PVPFieldMapQueueTips")

    local nQueueMapCount = 0
    if tNormalTips then
        nQueueMapCount = nQueueMapCount + tNormalTips.nQueueMapCount
    end
    if tPVPFieldTips then
        nQueueMapCount = nQueueMapCount + tPVPFieldTips.nQueueMapCount
    end

    if not tNormalTips and not tPVPFieldTips then
        UIHelper.SetVisible(self.WidgetAnchorLineUpTip, false)
        return
    end

    UIHelper.SetVisible(self.WidgetAnchorLineUpTip, true)
    UIHelper.SetString(self.LabelLineUpName01, string.format("已排队：%d个场景", nQueueMapCount))
   -- UIHelper.SetString(self.LabelLineUpName02, tContent[2])
end

function UIWorldMap:SetIsTrafficNodeSkill(bTrafficNodeSkill)
    self.bTrafficNodeSkill = bTrafficNodeSkill
end

function UIWorldMap:GetIsTrafficNodeSkill()
    return self.bTrafficNodeSkill or false
end

function UIWorldMap:SetJumpToMiddle(bJump)
    self.bJump = bJump
end

return UIWorldMap