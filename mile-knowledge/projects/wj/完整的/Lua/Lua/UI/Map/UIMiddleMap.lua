
local UIMiddleMap = class("UIMiddleMap")

local QUERY_WANTED_INTERVAL =  30
local MAX_TRACE_HEIGHT = 300000

local QUERY_KILLER_CD = 10

local DEFAULT_OFFSET_X = 50
local DEFAULT_OFFSET_Y = 20
local MARGIN = 50

local SCALE_RATE = 20
local MIN_SCALE = 1
local MAX_SCALE = 4

local DISTANCE = 40
local ICON_NEAR_OFFSET = 35
local ICON_AWAY_OFFSET = 25

local RANK_LIST_ID = 283

local MARK_UIINDEX_TO_LOGICINDEX = {
    [1] = 1,
    [2] = 2,
    [3] = 3,
    [4] = 4,
    [5] = 5,
    [6] = 38,
    [7] = 7,
    [8] = 8,
    [9] = 9,
    [10] =11,
    [11] = 12,
    [12] = 13,
    [13] = 15,
    [14] = 16,
    [15] = 17,
    [16] = 18,
    [17] = 19,
    [18] = 20,
    [19] = 21,
    [20] = 22,
}

local tActivityShieldMap =
{
    [27] = true,
    [25] = true,
    [136] = true,
    [138] = true,
    [175] = true,
    [176] = true,
}
local ACTIVITY_SYMBOL_REQUEST_INTERVAL = 1000 * 30

local function OnShowMap(self, nArea, bIndex)
    MapHelper.InitMiddleMapInfo(self.nMapID)
    self.nIndex = bIndex and nArea or MapHelper.GetMapMiddleMapIndex(self.nMapID, nArea)
    self.tTransferNode, self.tTrafficNode = MapHelper.InitTrafficInfo(self.nMapID, self.nStartTrafficID)
    self:InitNodeSelect(self.nMapID)
    self:InitSceneQuest(self.nMapID)

    self.LeftScript:SetIndex(self.nIndex)

    -- UIHelper.PlayAni(self, self.AniAll, "AniMiddleMapShow")
    if CommandBaseData.IsCommandModeCanBeEntered() and CommandBaseData.IsCommanderExisted() and self.nMapID == g_pClientPlayer.GetMapID() then
        UIHelper.SetSelected(self.TogPQCommand, true)
    else
        self:UpdateCurrentMap()
    end

    -- UIHelper.PlayAni(self, self.AniAll, "AniMiddleMapShow")

    --资源下载Widget
    local scriptDownload = UIHelper.GetBindScript(self.WidgetDownload)
    local nPackID = PakDownloadMgr.GetMapResPackID(self.nMapID)
    local tConfig = {
        fnOnSetVisible = function(bVisible)
            UIHelper.SetVisible(self.WidgetDownload, bVisible)
            UIHelper.LayoutDoLayout(self.LayoutBtn)
        end
    }
    scriptDownload:OnInitWithPackID(nPackID, tConfig)
    self:MarkActivitySymbol()
end

local function CanExploreEventShow(tInfo)
    if not tInfo or not tInfo.nState then
        return
    end

    --未探索配置隐藏
    if tInfo.nState == MAP_EXPLORE_STATE.NOT_EXPLORE and tInfo.bUnexploredHide then
        return false
    end

    --已完成隐藏
    if tInfo.nState >= MAP_EXPLORE_STATE.FINISH and not Storage.MiddleMapData.bShowExploreFinish then
        return false
    end

    return true
end

function UIMiddleMap:IsCurrentMap()
    local player = GetClientPlayer()
    if not player then
        return false
    end
    local scene = player.GetScene()
    return scene.dwMapID == self.nMapID
end

function UIMiddleMap:IsShowTrafficNode()
    -- return true
    if MapHelper.IsRemotePvpMap(self.nMapID) then
        return false
    end
    if self.bTraffic then
        local _, nMapType = GetMapParams(self.nMapID)
        if nMapType ==  MAP_TYPE.DUNGEON then--驿站车夫状态下，配置在表里的Map也显示神行点，譬如温泉山庄
            return SHOW_TRAFFIC_DUNGEON_MAP[self.nMapID] ~= nil
        else
            return nMapType == MAP_TYPE.NORMAL_MAP or nMapType == MAP_TYPE.BIRTH_MAP
        end
    else
        local _, nMapType = GetMapParams(self.nMapID)
        return nMapType == MAP_TYPE.NORMAL_MAP or nMapType == MAP_TYPE.BIRTH_MAP
    end
end

-- Init
function UIMiddleMap:InitNodeSelect(nMapID)
    self.tbNodeSelect = {}
    --[[self.tbNodeSelect = Table_GetMiddleMapSelectNpc()]]--
    --[[for i, v in ipairs(MapHelper.tbMiddleMapNpc[nMapID] or {}) do
        --self.tbNodeSelect[v.id] = v.defaultcheck
        self.tbNodeSelect[v.id] = true
    end]]--

    self.tbNodeCatalogue = {}
    local aNpc = MapMgr.GetNpcList(self.nMapID) or {}
    for k, v in pairs(aNpc) do
        local tbCatalogue = MapHelper.GetMiddleMapNpcCatalogueIconTab(v.id)
        if tbCatalogue then
            -- if v.middlemap == self.nIndex then
                local tGroup = v.group
                if tGroup then
                    for _, tNpc in ipairs(tGroup) do
                        self.tbNodeCatalogue[tNpc] = tbCatalogue
                    end
                end
            -- end
        end
    end
end

function UIMiddleMap:InitSceneQuest(nMapID)
    -- if self.tbCanAcceptQuest then
    --     return
    -- end
    self.tbCanAcceptQuest = Table_GetAllSceneQuest(nMapID)
end

function UIMiddleMap:UpdateCurrentMap()
    self.tbMemberScripts = require("Lua/UI/Map/Component/UIPrefabComponent"):CreateInstance()
    self.tbMemberScripts:Init(self.WidgetTeammate, PREFAB_ID.WidgetTeammate)
    local szName = GBKToUTF8(Table_GetMapName(self.nMapID))
    local szPath = MapMgr.GetMapParams_UIEx(self.nMapID)
    local dwMapID = self.nMapID
    local nIndex  = self.nIndex
    local dwMainMapID, bIsMainMap = MapHelper.GetMainMap(dwMapID)
    if dwMainMapID and dwMainMapID ~= dwMapID then
        dwMapID = dwMainMapID
        nIndex = 0
    end
    local tbMapInfo = MapHelper.tbMiddleMapInfo[dwMapID]
    if tbMapInfo and tbMapInfo[nIndex] then
        local tb = tbMapInfo[nIndex]
        if tb.name then
            szName = tb.name
        end
        szName = string.gsub(szName, "·", "\n·")
        local szName1, nLastNumIndex = UIHelper.GetUtf8HeadNum(szName)
        if szName1 == "" then
            szName1, nLastNumIndex = UIHelper.GetUtf8SubString(szName, 1, 1), 2
        end
        local szName2 = UIHelper.GetUtf8SubString(szName, nLastNumIndex, UIHelper.GetUtf8Len(szName))
        UIHelper.SetString(self.LabelTitle, szName1)
        UIHelper.SetString(self.LabelTitle2, szName2)

        UIHelper.CascadeDoLayoutDoWidget(self.WidgetAnchorTitle, true, true)

        self.PosComponent:Init(tb.width, tb.height, tb.startx, tb.starty, tb.scale, self.nMapID)

        -- TODO
        if tb.color ~= "" then
            local r = tonumber('0x' .. string.sub(tb.color, 1, 2))
            local g = tonumber('0x' .. string.sub(tb.color, 3, 4))
            local b = tonumber('0x' .. string.sub(tb.color, 5, 6))
            self.tbColor = cc.c3b(r, g, b)
        end

        self.nLeftShowX = tb.showleftx
        self.nLeftShowY = tb.showlefty
        self.nRightShowX = tb.showrightx
        self.nRightShowY = tb.showrighty
        local szImage = szPath .. "minimap_mb\\" .. tb.image
        if Platform.IsMobile() then szImage = UIHelper.ConvertToMBPath(szImage) end
        self:UpdateMapImage(szImage)
        self:UpdateSliderPercent()
    end

    if not self:IsCurrentMap() then
        self.WidgetLocation:setVisible(false)
    end

    self:RemoveAllTeammate()
    self:UpdateMarkNodes()
    self:UpdateDynamicNodes()
    self:AskForCustomeRankList()
    self:UpdatePQData()
    self:UpdateMapMark()
    self:UpdateActivitySymbol()
    self:UpdateNodeTrace()
    self:UpdateNodeAutoNav()
    self:UpdateHomeLandMapMark()
    self:UpdateExtraNodes()
    self:UpdateFlyLine()

    self:UpdateEnterBtnVis()
    self:UpdateSearchNpcNodes()

    self.initialized = true
    self:Update()
    self:UpdateCircleSFX()
    self:UpdateHeatMapState()
    self:UpdateAllLines()


    UIHelper.SetVisible(self.ImgBgTitleLine, PakDownloadMgr.IsEnabled())
    self:CloseAllTip()
    self.nTracingQuestID = nil--更换地图，刷新追踪任务位置
    self:UpdateCurMapCopyInfo()
    self:UpdateExploreButton()
end

function UIMiddleMap:UpdateAllLines()
    self.scriptLineMgr = self.scriptLineMgr or UIHelper.GetBindScript(self.WidgetLine)
    self.scriptLineMgr:OnEnter(self.nMapID, self.PosComponent)
end

function UIMiddleMap:UpdateAllLinePos()
    self.scriptLineMgr = self.scriptLineMgr or UIHelper.GetBindScript(self.WidgetLine)
    self.scriptLineMgr:UpdateAllLinePos()
end

function UIMiddleMap:UpdateEnterBtnVis()
    local bVis = MapMgr.IsCommander() and CommandBaseData.IsCommanderExisted() and CommandBaseData.IsCommandModeCanBeEntered()
    UIHelper.SetVisible(self.TogPQCommand, bVis)
    UIHelper.SetTouchEnabled(self.TogPQCommand, self.nMapID == g_pClientPlayer.GetMapID())

    local bIsInActivityTime, bIsInActivityMap = CampData.IsInActivity()
    local bIsInPvpMap = MapHelper.IsRemotePvpMap()
    local bInCampWar = (bIsInActivityTime and bIsInActivityMap and g_pClientPlayer ~= nil and g_pClientPlayer.nCamp ~= CAMP.NEUTRAL) or bIsInPvpMap
    UIHelper.SetVisible(self.TogChangeMap, bInCampWar)
    UIHelper.SetString(self.LabelToGongFang, bIsInPvpMap and "切到阵营" or "切到攻防")
    if bInCampWar then
        local scriptMainCity = UIMgr.GetViewScript(VIEW_ID.PanelMainCity)
        local bCampRightTopState = scriptMainCity ~= nil and scriptMainCity:GetCampRightTopState() or false
        UIHelper.SetSelected(self.TogChangeMap, bCampRightTopState, false)
    end

    local bIsPlayerCanDraw = MapMgr.IsPlayerCanDraw()
    local nState = bIsPlayerCanDraw and BTN_STATE.Normal or BTN_STATE.Disable
    UIHelper.SetButtonState(self.BtnSynchronous, nState, nil, true)
    UIHelper.SetButtonState(self.BtnRevert, nState, nil, true)

    self:UpdateWeather()

    UIHelper.LayoutDoLayout(self.LayoutBtn)
end

function UIMiddleMap:UpdateSelectNpcHighlight(nTypeID, bHighlight)
    local tList = self.tbNodeScripts[nTypeID]
    if tList then
        for k, v in ipairs(tList) do
            v:SetHighlight(bHighlight)
        end
    end
end

function UIMiddleMap:IsInMapView(x, y, bNotTurnMainMap)
    local absX, absY = self.PosComponent:LogicPosToMapPos(x, y, nil, nil, bNotTurnMainMap)

    local nWoldMaskX, nWoldMaskY = UIHelper.GetWorldPosition(self.ImgMapMask)
    local nWidth = UIHelper.GetWidth(self.ImgMapMask)
    local nHeight = UIHelper.GetHeight(self.ImgMapMask)
    local nLeft = nWoldMaskX - nWidth / 2
    local nRight = nWoldMaskX + nWidth / 2
    local nBottom = nWoldMaskY - nHeight / 2
    local nTop = nWoldMaskY + nHeight / 2

    if absX < nLeft or absX > nRight then
        return false
    end
    if absY < nBottom or absY > nTop then
        return false
    end
    return true
end

function UIMiddleMap:UpdateNodePos(script, nLogicX, nLogicY)
    local absX, absY = self.PosComponent:LogicPosToMapPos(nLogicX, nLogicY, nil, nil, script.bNotTurnMainMap)
    local parent = script._rootNode:getParent()
    local pos = parent:convertToNodeSpace({x = absX, y = absY})
    local fScale = self.TouchComponent:GetScale()
    script:SetPosition(pos.x, pos.y, nLogicX, nLogicY, fScale)

    local bCanShow = true
    if script.CanShow then bCanShow = script:CanShow() end
    if script.fShowScale and fScale < script.fShowScale and not script.bShowNotify then
        bCanShow = false
    end
    UIHelper.SetVisible(script._rootNode, self:IsInMapView(nLogicX, nLogicY) and bCanShow)
end

function UIMiddleMap:CreateMapNodeFromLogicPos(parent, x, y, bClip, nPrefabID, bNotTurnMainMap)
    local nLogicX, nLogicY = x, y
    local absX, absY = self.PosComponent:LogicPosToMapPos(x, y, nil, nil, bNotTurnMainMap)
    local pos = parent:convertToNodeSpace({x = absX, y = absY})

    nPrefabID = nPrefabID or PREFAB_ID.WidgetMiddleSignButton
    --2023.9.22 超出地图范围的图标不裁剪
    if bClip and not self:IsInMapView(nLogicX, nLogicY, bNotTurnMainMap) then
        return
    end
    local script = UIHelper.AddPrefab(nPrefabID, parent, self.nMapID)
    script:SetPosition(pos.x, pos.y, nLogicX, nLogicY)
    script.bNotTurnMainMap = bNotTurnMainMap
    return script
end

function UIMiddleMap:GetNeighborhood(nX, nY)
    local tNeighborhood = {}
    for _, tList in pairs(self.tbNodeScripts) do
        for k, v in pairs(tList) do
            if v.GetPosition and v.CanAddToNeiborList and v:CanAddToNeiborList() then
                local x, y = v:GetPosition()
                if math.abs(nX - x) < DISTANCE and math.abs(nY - y) < DISTANCE then--改为以世界坐标计算
                    table.insert(tNeighborhood, v)
                end
            end
        end
    end
    table.sort(tNeighborhood, function(a, b)
        if a.bTransfer ~= b.bTransfer then--神行
            return a.bTransfer
        end
        if a.bBoss ~= b.bBoss then--副本Boss
            return a.bBoss
        end
        if a.bQuest ~= b.bQuest then--任务
            return a.bQuest
        end
        if a.bPQ ~= b.bPQ then--PQ事件
            return a.bPQ
        end
        local nTypeA = a.nCatalogue or 0
        local nTypeB = b.nCatalogue or 0
        return nTypeA < nTypeB
    end)
    return tNeighborhood
end

function UIMiddleMap:OnSelectSignButton(script, bSelected)
    self:CloseNeiborAndAutoWalk()
    if bSelected then
        local nX, nY = script:GetPosition()
        local tbNeighborhood = self:GetNeighborhood(nX, nY)
        local tbNpcInfo = script:GetNPCInfo()
        if not script.bNotShowNeibor and #tbNeighborhood > 1 then
            self:ShowNeighborhoodAndAutoWalk(tbNeighborhood, nX, nY, false)
            self.TraceScript:Hide()
        elseif script.bOpenPanel then
            script:DoAction()
        elseif tbNpcInfo then
            self:ShowWidgetNpc(tbNpcInfo, nX, nY)
            self.TraceScript:Hide()
        end
    end
end

function UIMiddleMap:ShowShieldSelect()
    if not self.bLoadCheckBox then
        UIHelper.AddPrefab(PREFAB_ID.WidgetTogTypeMulti_XS, self.LayoutBg, "任务", MapMgr.IsShowQuest(), function(bSelect)
            MapMgr.SetShowQuest(bSelect)
            self:UpdateQuestVis()
        end)
        UIHelper.AddPrefab(PREFAB_ID.WidgetTogTypeMulti_XS, self.LayoutBg, "神行点", MapMgr.IsShowShenXing(), function(bSelect)
            MapMgr.SetShowShenXing(bSelect)
            self:UpdateShenXingVis()
        end)
        UIHelper.AddPrefab(PREFAB_ID.WidgetTogTypeMulti_XS, self.LayoutBg, "交通点", MapMgr.IsShowTraffic(), function(bSelect)
            MapMgr.SetShowTraffic(bSelect)
            self:UpdateTrafficNpcVis()
        end)
        UIHelper.AddPrefab(PREFAB_ID.WidgetTogTypeMulti_XS, self.LayoutBg, "已完成探索", MapMgr.IsShowExploreFinish(), function(bSelect)
            if self.nExploreNotifyTimer then
                Timer.DelTimer(self, self.nExploreNotifyTimer)
                self.nExploreNotifyTimer = nil
            end
            MapMgr.SetShowExploreFinish(bSelect)
            self:UpdateExploreNodes()
        end)
        UIHelper.LayoutDoLayout(self.LayoutBg)
        self.bLoadCheckBox = true
    end
end

function UIMiddleMap:ShowWidgetNpc(tbNpcInfo, nWorldX, nWorldY)
    local nX, nY = self:CaculateWidgetPos(nWorldX, nWorldY, self.WidgetNpc)
    self.WidgetNpcScript:Show(tbNpcInfo, nX, nY, self.nMapID)
end


function UIMiddleMap:ShowWidgetPQ(script, nWorldX, nWorldY)
    local nX, nY = self:CaculateWidgetPos(nWorldX, nWorldY, self.WidgetPQ)
    self.WidgetPQScript:Show(script, nX, nY)
end

function UIMiddleMap:ShowWidgetTeamInfo(szName, nWorldX, nWorldY, szFrame)
    local nX, nY = self:CaculateWidgetPos(nWorldX, nWorldY, self.WidgetTeammate_single)
    self.WidgetTeamInfoScript:Show(szName, nX, nY, szFrame)
end

function UIMiddleMap:CanShowTrafficNode(tNode)
    -- 非交通状态（神行状态）所有节点都显示
    if not self.bTraffic then
        return true
    end
    if tNode.bDisable then
        return false
    end
    if self.nFinishCityID and self.nFinishCityID ~= tNode.dwTrafficID then
        return false
    end
    return true
end

-- Traffic
function UIMiddleMap:AddTrafficNodes()
    if not self.tTransferNode or not self:IsShowTrafficNode() then
        return
    end

    local tbNode = self.bTraffic and self.tTrafficNode or self.tTransferNode
    for _, tNode in ipairs(tbNode) do
        -- 交通状态时，不显示bDisabled节点
        if self:CanShowTrafficNode(tNode) then
            local script = self:CreateMapNodeFromLogicPos(self.WidgetShenXing, tNode.nX, tNode.nY, true)
            if script then
                local tbIllegal = {
                    Level = self.bIllegalLevel,
                    Visit = self.bIllegalVisit,
                }

                script.bOpenPanel = true
                if self.bTraffic then
                    script:SetTraffic(self.nMapID, tNode, tbIllegal)
                    script.fnDetailPanel = function()
                        if tNode.dwTrafficID == self.nStartTrafficID then
                            TipsHelper.ShowNormalTip(g_tStrings.TRAFFIC_MIDDLE_ALEADY_IN_THIS_AREA)
                            return
                        end
                        UIHelper.ShowConfirm(FormatString(g_tStrings.STR_TRAFFICTO_TIP, tNode.szName), function()
                            MapMgr.TrafficTo(tNode.dwNodeID, tNode.dwCityID)
                        end)
                    end
                else
                    script.bNotShowNeibor = self.bTrafficNodeSkill
                    script:SetTransfer(self.nMapID, tNode, tbIllegal)
                    script.fnDetailPanel = function()
                        if script.bIllegal then
                            return
                        end
                        MapMgr.TryTransfer(self.nMapID, tNode.dwCityID)
                    end
                end

                script.fnSelected = function(bSelected)
                    self:OnSelectSignButton(script, bSelected)
                    script.bNotShowNeibor = self.bTrafficNodeSkill
                end

                self.tbNodeScripts["Traffic"] = self.tbNodeScripts["Traffic"] or {}
                table.insert(self.tbNodeScripts["Traffic"], script)
            end
        end
    end
    self:UpdateShenXingVis()
end

function UIMiddleMap:UpdateShenXingVis()
    UIHelper.SetVisible(self.WidgetShenXing, MapMgr.IsShowShenXing() or self.bTrafficNodeSkill)
end

function UIMiddleMap:AddCraftNodes(nID, nCraftID, tbCraft)
    self.tbCraftNodes[nID] = {}
    for _, v in ipairs(tbCraft) do
        local script = self:CreateMapNodeFromLogicPos(self.WidgetCraft, v[1], v[2], true, nil, true)
        if script then
            script:SetCraft(nCraftID)
            table.insert(self.tbCraftNodes[nID], script)
        end
    end
end

function UIMiddleMap:ClearCraftNodesByType(nID)
    for _, node in ipairs(self.tbCraftNodes[nID]) do
        -- node._rootNode:removeFromParent(true)
        self:DeleteMarkNode(node)
    end
    self.tbCraftNodes[nID] = {}
end

function UIMiddleMap:UpdateCraftNodes()

	--if not Storage.MiddleMapData.bShowCraft then return end
    self.tbCraftNodes = self.tbCraftNodes or {}

    for nType, _ in pairs(self.tbCraftNodes or {}) do
        self:ClearCraftNodesByType(nType)
    end

    for nType, v in pairs(Storage.MiddleMapData.tbCraftList or {}) do
        local tbCraft = MapMgr.GetCraftPosByID(self.nMapID, nType)
        self:AddCraftNodes(nType, v, tbCraft)
    end
end

function UIMiddleMap:UpdateMapMark()
    self:RemoveMapMark("MapMark")
    -- self.tbNodeScripts["MapMark"] = self.tbNodeScripts["MapMark"] or {}
    local szMarkName, nMarkX, nMarkY, nMarkZ, nMapMarkMapID = MapMgr.GetMarkInfo()
    if not szMarkName or self.nMapID ~= nMapMarkMapID then return end
    if nMarkX == -10000 then
        if self.scriptMapMark then
            self.scriptMapMark:SetVisible(false)
        end
    else
        local script = self:CreateMapNodeFromLogicPos(self.WidgetMapMark, nMarkX, nMarkY)
        if script then
            local tbPoint = {nMarkX, nMarkY, nMarkZ}
            script:SetMapMark(szMarkName, tbPoint)
            script.fnDetailPanel = function(bTrace)
                self:TraceNode(script.szName, self.nMapID, tbPoint)
            end
            script.fnSelected = function(bSelected)
                self:OnSelectSignButton(script, bSelected)
            end
            self.scriptMapMark = script
            table.insert(self.tbNodeScripts["MapMark"], script)

        end
    end
end

function UIMiddleMap:RemoveMapMark(szType)
    self.tbNodeScripts[szType] = self.tbNodeScripts[szType] or {}
    for index, script in ipairs(self.tbNodeScripts[szType]) do
        -- UIHelper.RemoveFromParent(script._rootNode)
        self:DeleteMarkNode(script)
        script = nil
    end
    self.tbNodeScripts[szType] = {}
end

function UIMiddleMap:MarkActivitySymbol()
    local bClear = true
    local hPlayer = GetClientPlayer()
    local bInCity = self.nIndex and self.nIndex ~= 0
    if hPlayer and not bInCity then
        local hScene = hPlayer.GetScene()
        local dwMapID = hScene.dwMapID

        if dwMapID == self.nMapID and not tActivityShieldMap[dwMapID] then
            local nTime = GetTickCount()
            if not MapHelper.nLastSymbolTime or nTime - MapHelper.nLastSymbolTime > ACTIVITY_SYMBOL_REQUEST_INTERVAL then
                RemoteCallToServer("On_Map_RequestActivitySymbol", dwMapID)
                MapHelper.nLastSymbolTime = nTime
            end
            bClear = false
        end

        if MapHelper.dwActivitySymbolMapID and MapHelper.dwActivitySymbolMapID ~= dwMapID then
            bClear = true
        end
    end

    if bClear then
        MapHelper.nLastSymbolTime = nil
    end
end

function UIMiddleMap:UpdateActivitySymbol(dwMapID, dwSymbol)
    if not dwMapID and not dwSymbol then
        dwMapID = MapHelper.dwActivitySymbolMapID
        dwSymbol = MapHelper.dwActivitySymbolSymbol
    end

    if dwMapID ~= self.nMapID then
        return
    end

    MapHelper.dwActivitySymbolMapID = dwMapID
    MapHelper.dwActivitySymbolSymbol = dwSymbol

    self:RemoveMapMark("ActivitySymbol")
    for i = 1, 32 do
        if GetNumberBit(dwSymbol, i) then
            local tSymbol = Table_GetActivitySymbol(dwMapID, i)
            if tSymbol then
                for _, tPoint in ipairs(tSymbol.tPointList) do
                    local script = self:CreateMapNodeFromLogicPos(self.WidgetActivitySymbol, tPoint[1], tPoint[2])
                    if script then
                        local tbPoint = {tPoint[1], tPoint[2], g_pClientPlayer.nZ}
                        script.bOpenPanel = true
                        script:SetActivitySymbolMark(UIHelper.GBKToUTF8(tSymbol.szName), tbPoint)
                        script.fnSelected = function(bSelected)
                            self:OnSelectSignButton(script, bSelected)
                        end

                        script.fnDetailPanel = function(bTrace)
                            TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips, script._rootNode, UIHelper.GBKToUTF8(tSymbol.szName) .."\n"..UIHelper.GBKToUTF8(tSymbol.szDesc))
                        end
                        table.insert(self.tbNodeScripts["ActivitySymbol"], script)
                    end
                end
            end
        end
    end
end

function UIMiddleMap:UpdateHomeLandMapMark()--该方法对家园的特殊MapMark“我的家园”进行处理
    -- UIHelper.RemoveAllChildren(self.WidgetHomelandMark)
    -- self.tbNodeScripts["MapMark"] = self.tbNodeScripts["MapMark"] or {}
    self:RemoveMapMark("HomeLandMapMark")
    local szMarkName, nMarkX, nMarkY, nMarkZ = MapMgr.GetHomelandMarkInfo()
    local player = GetClientPlayer()
    if not szMarkName then return end
    if nMarkX == -10000 then
        if self.scriptMapMark then
            self.scriptMapMark:SetVisible(false)
        end
    elseif self.nMapID ~= player.GetMapID() or not HomelandData.IsHomelandMap(self.nMapID) then
        UIHelper.SetVisible(self.WidgetHomelandMark, false)
    else
        local script = self:CreateMapNodeFromLogicPos(self.WidgetHomelandMark, nMarkX, nMarkY)
        if script then
            local tbPoint = {nMarkX, nMarkY, nMarkZ}
            script:SetMapMark(szMarkName, tbPoint)
            -- script.fnDetailPanel = function(bTrace)
            --     self:TraceNode(script.szName, self.nMapID, tbPoint)
            -- end
            script.fnSelected = function(bSelected)
                self:OnSelectSignButton(script, bSelected)
            end
            self.scriptMapMark = script
            table.insert(self.tbNodeScripts["HomeLandMapMark"], script)
        end
        UIHelper.SetVisible(self.WidgetHomelandMark, true)
    end
end

function UIMiddleMap:ShowTraceInfo()
    local nX, nY = UIHelper.GetWorldPosition(self.WidgetTraceOthers)
    local tNeiborghood = self:GetNeighborhood(nX, nY)
    self:ShowNeighborhoodAndAutoWalk(tNeiborghood, nX, nY, true)
end

function UIMiddleMap:UpdateNodeTrace()
    local szNpc, nMapID, tbPoint, szUID, szFrame = MapMgr.GetTraceInfo()
    local bCanShowTrace = MapMgr.CanShowTrace()
    self.TipScript:UpdateShowMap(self.nMapID)

    if nMapID == self.nMapID and bCanShowTrace and tbPoint then
        local nX, nY, _ = unpack(tbPoint)
        local x, y = self.PosComponent:LogicPosToMapPos(nX, nY)
        UIHelper.SetWorldPosition(self.WidgetTraceOthers, x, y)
        if szFrame then
            UIHelper.SetSpriteFrame(self.ImgTraceIcon, szFrame)
        end
        UIHelper.SetVisible(self.WidgetTraceOthers, self:IsInMapView(nX, nY))
    else
        UIHelper.SetVisible(self.WidgetTraceOthers, false)
    end
    for _, v in pairs(self.tbNodeScripts) do
        for k, script in pairs(v) do
            if script.UpdateTrace then
                script:UpdateTrace(self.nMapID)
            end
        end
    end
end


function UIMiddleMap:UpdateNodeAutoNav()
    local tbPoint = AutoNav.GetNavPoint()
    if tbPoint and tbPoint.nMapID == self.nMapID then
        local x, y = self.PosComponent:LogicPosToMapPos(tbPoint.nX, tbPoint.nY)
        UIHelper.SetVisible(self.WidgetWalk, true)
        UIHelper.SetWorldPosition(self.WidgetWalk, x, y)
    else
        UIHelper.SetVisible(self.WidgetWalk, false)
    end
end

function UIMiddleMap:AddNpcNode(tNpc, tbCatalogue, parent, bHighlight)
    self.tbNodeScripts[tNpc] = {}
    local tPoint = tNpc.tPoint
    for _, tP in ipairs(tPoint) do
        local x, y, _ = unpack(tP)
        local script = self:CreateMapNodeFromLogicPos(parent, x, y, true, nil, true)
        if script then
            script:SetNpc(tNpc, tP, tbCatalogue.szFrame, tbCatalogue.szBgFrame, tbCatalogue.nNpcCatalogue)
            script:SetHighlight(bHighlight)
            script.fnDetailPanel = function(bTrace)
                -- self:TraceNode(script.szName, self.nMapID, tP, script.szFrame)
                local tbNpcInfo = script:GetNPCInfo()
                if not script.bOpenPanel and tbNpcInfo then
                    local nX, nY = UIHelper.ConvertToWorldSpace(script._rootNode:getParent(), script.nX, script.nY)
                    self:ShowWidgetNpc(tbNpcInfo, nX, nY)
                end
            end
            script.fnSelected = function(bSelected)
                self:OnSelectSignButton(script, bSelected)
                script.bNotShowNeibor = false
            end
            table.insert(self.tbNodeScripts[tNpc], script)
        end
    end
end

function UIMiddleMap:UpdateExtraNodes()
    -- self:RemoveAllSearchNpcNodes()--和搜索npc的点互斥tbNpcInfo
    self.WidgetExtra:removeAllChildren()
    if self.bTraffic then
        return
    end
    local tNpc = self.tbNpc
    local tbCatalogue = tNpc and self.tbNodeCatalogue[tNpc]
    if tbCatalogue then
        self:AddNpcNode(tNpc, tbCatalogue, self.WidgetExtra, true)
    end
end

function UIMiddleMap:UpdateSearchNpcNodes()
    local tbNpcInfo = self.tbSearchNpcInfo
    self:RemoveAllSearchNpcNodes()
    if not tbNpcInfo then return end
    for nIndex, tbInfo in ipairs(tbNpcInfo.tbNpcList) do
        local script = self:CreateMapNodeFromLogicPos(self.WidgetSearchNPC, tonumber(tbInfo.nX), tonumber(tbInfo.nY), true)
        if script then
            script:SetSearchNpc(tbInfo)
            script.bNotShowNeibor = true
            script.fnDetailPanel = function(bTrace)
                -- self:TraceNode(script.szName, self.nMapID, tP, script.szFrame)
                local tbNpcInfo = script:GetNPCInfo()
                if not script.bOpenPanel and tbNpcInfo then
                    local nX, nY = UIHelper.ConvertToWorldSpace(script._rootNode:getParent(), script.nX, script.nY)
                    self:ShowWidgetNpc(tbNpcInfo, nX, nY)
                end
            end
            script.fnSelected = function(bSelected)
                self:OnSelectSignButton(script, bSelected)
            end
            script:SetHighlight(true)
            table.insert(self.tbSearchNpcNodes, script)
        end
    end
end

function UIMiddleMap:RemoveAllSearchNpcNodes()
    if self.tbSearchNpcNodes then
        for nIndex, script in ipairs(self.tbSearchNpcNodes) do
            self:DeleteMarkNode(script)
        end
    end
    self.tbSearchNpcNodes = {}
end

function UIMiddleMap:AskForCustomeRankList()
    if self.nMapID and SHOW_PQ_MAP[self.nMapID] then
        ApplyCustomRankList(RANK_LIST_ID)
    end
end

function UIMiddleMap:UpdatePQData()
	local hPlayer = g_pClientPlayer
	if not hPlayer then
		return
	end

	local dwMapID    = self.nMapID
	local dwCurMapID = hPlayer.GetMapID()
	--跨地图才显示
	if not dwMapID or dwMapID == dwCurMapID then
		return
	end

	local tRankList = {}
	if SHOW_PQ_MAP[dwMapID] and dwMapID ~= dwCurMapID then
		tRankList = GetCustomRankList(RANK_LIST_ID)
	end
	if not tRankList then
		return
	end

	local tData = {}

	local tDynamicParam = MapMgr.Table_GetMapDynamicData()

	for _, t in pairs(tRankList) do
		if t.dwID == self.nMapID then
			for k, v in pairs(t) do
				if type(k) == "number" then
					table.insert(tData, {nType = k, nX = v[1], nY = v[2]})
				end
			end
			break
		end
	end

	for i = 1, #tData do
		local tMarkD = tData[i]
		local tParam = tDynamicParam[tMarkD.nType]
		if tParam and hPlayer.nLevel >= tParam.nMinShowLevel then
			self:CreateDynamicNode(tMarkD, tParam)
		end
	end

end

function UIMiddleMap:ClearDynamicNodes()
    if self.tbNodeScripts["PQ"] then
        for nIndex, script in ipairs(self.tbNodeScripts["PQ"]) do
            self:DeleteMarkNode(script)
        end
    end
    self.tbNodeScripts["PQ"] = {}
end


function UIMiddleMap:UpdateDynamicNodes(tbData)

    self:ClearDynamicNodes()

    local player = g_pClientPlayer
    local tbData = player and player.GetMapMark() or {}
    if self.nMapID ~= player.GetMapID() then
        tbData = {}
    end
    local tDynamicParam = MapMgr.Table_GetMapDynamicData()

    for i = 1, #tbData do
		local tMarkD = tbData[i]
		local tParam = tDynamicParam[tMarkD.nType]
        local tbHuntInfo = MapMgr.GetPQHuntInfo(tMarkD.nType)
        if tParam and player.nLevel >= tParam.nMinShowLevel and self:IsShowDynamicNode(tMarkD) and tMarkD.nX > 0 and tMarkD.nY > 0 and not tbHuntInfo then
            self:CreateDynamicNode(tMarkD, tParam)
        end
    end
    self:UpdateNodeTrace()
    self:UpdateNodeAutoNav()
    MapMgr.ApplyDynamicDataEx()

    -- 战场的动态标记先放到这个组件下面
    self:UpdateBattleFieldMarkState()
    self:UpdateHuntEvent()
end

function UIMiddleMap:IsShowDynamicNode(tMarkD)--温泉山庄MapMark特殊处理，在驿站车夫打开中地图时屏蔽特定的mapMark
    local _, nMapType = GetMapParams(self.nMapID)
    if nMapType ==  MAP_TYPE.DUNGEON and self.bTraffic then
        local tbMarkType = SHOW_TRAFFIC_DUNGEON_MAP[self.nMapID]
        if tbMarkType then
            return not table.contain_value(tbMarkType, tMarkD.nType)
        end
    end
    return true
end

function UIMiddleMap:CreateDynamicNode(tMarkD, tParam)
    local script = self:CreateMapNodeFromLogicPos(self.WidgetDynamic, tMarkD.nX, tMarkD.nY, true)
    if script then
        local tPoint = {tMarkD.nX, tMarkD.nY, tMarkD.nZ or 0}
        script:SetPQ(tMarkD, tParam, tPoint)
        script.fnDetailPanel = function(bTrace)
            local tbNpcInfo = script:GetNPCInfo()
            if not script.bOpenPanel and tbNpcInfo then
                local nX, nY = UIHelper.ConvertToWorldSpace(script._rootNode:getParent(), script.nX, script.nY)
                self:ShowWidgetNpc(tbNpcInfo, nX, nY)
                RemoteCallToServer("On_PQ_ClickIcon", tMarkD.nType)
            end
        end
        script.fnSelected = function(bSelected)
            self:OnSelectSignButton(script, bSelected)
            RemoteCallToServer("On_PQ_ClickIcon", tMarkD.nType)
        end
        table.insert(self.tbNodeScripts["PQ"], script)
    end
end

function UIMiddleMap:ClearBattleFieldMarkState(szTypeName)
    if self.tbNodeScripts[szTypeName] then
        for nIndex, script in ipairs(self.tbNodeScripts[szTypeName]) do
            self:DeleteMarkNode(script)
        end
    end
    self.tbNodeScripts[szTypeName] = {}
end

function UIMiddleMap:UpdateBattleFieldMarkState()


    local szTypeName = "BattleFieldMark"

    self:ClearBattleFieldMarkState(szTypeName)

    local player = g_pClientPlayer
    if not (MapHelper.dwFieldMapID and MapHelper.dwFieldMapID == player.GetMapID() and MapHelper.dwFieldMapID == self.nMapID) then
        return
    end

    if not MapHelper.tFieldMark then
        return
    end

    local tFieldMarkStateFrame = self:Table_GetBattleMarkState()

    for _, tMark in pairs(MapHelper.tFieldMark) do
        local tInfo = tFieldMarkStateFrame[tMark.nState]

        local script = self:CreateMapNodeFromLogicPos(self.WidgetDynamic, tMark.nX, tMark.nY, true)
        if script then
            script.bNotShowNeibor = true
            local tbPoint = {tMark.nX, tMark.nY, player.nZ}
            script:SetBattleFieldMark(tInfo, tbPoint, tMark.tArg, tMark.nState)

            script.fnDetailPanel = function(bTrace)
                local tbNpcInfo = script:GetNPCInfo()
                local nX, nY = UIHelper.ConvertToWorldSpace(script._rootNode:getParent(), script.nX, script.nY)
                self:ShowWidgetNpc(tbNpcInfo, nX, nY)
            end

            script.fnSelected = function(bSelected)
                self:OnSelectSignButton(script, bSelected)
            end

            table.insert(self.tbNodeScripts[szTypeName], script)
        end
    end
end


function UIMiddleMap:UpdateWantedNodes(tbData)
    self.WidgetWanted:removeAllChildren()
    self.tbNodeScripts["Wanted"] = {}


    for k, v in ipairs(tbData) do
        local script = self:CreateMapNodeFromLogicPos(self.WidgetWanted, v.nX, v.nY)
        if script then
            local tPoint = {v.nX, v.nY, v.nZ or 0}
            script.bOpenPanel = true
            local bPublic = GetNumberBit(v.nWantedTypeMask, WANTED_TYPE_CODE.PUBLIC + 1)
            local tbImg = bPublic and WANTED_FRAME[1] or WANTED_FRAME[2]
            script:SetWanted(v, tbImg)
            script.fnSelected = function(bSelected)
                self:OnSelectSignButton(script, bSelected)
            end
            script.fnDetailPanel = function()
                -- local absX, absY = self.PosComponent:LogicPosToMapPos(v.nX, v.nY)
                -- self:ShowWidgetTeamInfo(UIHelper.GBKToUTF8(v.szName), absX, absY, tbImg.ICON)
                local tbNpcInfo = script:GetNPCInfo()
                local nX, nY = UIHelper.ConvertToWorldSpace(script._rootNode:getParent(), script.nX, script.nY)
                self:ShowWidgetNpc(tbNpcInfo, nX, nY)
            end
            table.insert(self.tbNodeScripts["Wanted"], script)
        end
    end
end



function UIMiddleMap:UpdateNpcNodes()
    local aNpc = MapMgr.GetNpcList(self.nMapID) or {}
    for k, v in pairs(aNpc) do
        local tbCatalogue = MapHelper.GetMiddleMapNpcCatalogueIconTab(v.id)
        if tbCatalogue then
            if tbCatalogue.nNpcCatalogue == 0 and v.middlemap == self.nIndex then
                local tGroup = v.group
                if tGroup then
                    for _, tNpc in ipairs(tGroup) do
                        self:AddNpcNode(tNpc, tbCatalogue, self.WidgetTraffic, false)
                    end
                end
            end
        end
    end
    self:UpdateTrafficNpcVis()
end

function UIMiddleMap:UpdateTrafficNpcVis()
    UIHelper.SetVisible(self.WidgetTraffic, MapMgr.IsShowTraffic())
end


function UIMiddleMap:ClearAllMarkNodes()
    if self.tbNodeScripts then
        for szType, tbScript in pairs(self.tbNodeScripts) do
            for nIndex, script in ipairs(tbScript) do
                UIHelper.RemoveFromParent(script._rootNode, true)
            end
        end
    end
    self.tbNodeScripts = {}
end

function UIMiddleMap:UpdateMarkNodes()
    -- self.tbNodeScripts = {}
    -- self.WidgetSign:removeAllChildren()
    -- self.WidgetTag:removeAllChildren()
    -- self.WidgetMapSyncBoard:removeAllChildren()
    self:ClearAllMarkNodes()
    MapMgr.UpdateMapTeamTag()
    self:UpdateWanted()
    self:UpdateKillerPos()
    self:UpdateTagNodes()
    self:UpdateCraftNodes()

    if CommandBaseData.IsCommandModeCanBeEntered() and CommandBaseData.IsCommanderExisted() and self.nMapID == g_pClientPlayer.GetMapID() then
        self:UpdateBoardInfo()
    end

    if not self.bTraffic then
        self:UpdateNpcNodes()
        self:UpdateQuestNodes()
    end
    if self:IsShowTrafficNode() then
        self:AddTrafficNodes()
    end

    self:UpdateBossNodes()
    self:UpdateExploreNodes()
end



--这个函数一定在UpdateMarkNodes里调用，因为有tbNodeScripts初始化
function UIMiddleMap:UpdateBossNodes()
    self.tbNodeScripts["Boss"] = {}
    local tbBossList = DungeonData.GetBossListByMapID(self.nMapID)
    if not tbBossList then return end

    local tbPogressID = {}
    for nIndex, tbBossInfo in ipairs(tbBossList) do
        local bHasKilled = DungeonData.GetBossProgress(self.nMapID, tbBossInfo.nProgress)
        local tbCatalogue = MapHelper.GetMiddleMapNpcCatalogueIconTab(tbBossInfo.nCatalogueID)
        local tbCompleteCatalogue = MapHelper.GetMiddleMapNpcCatalogueIconTab(tbBossInfo.nCompleteCatalogueID)
        local script = self:CreateMapNodeFromLogicPos(self.WidgetBoss, tbBossInfo.nX, tbBossInfo.nY, true)
        if script then
            script.bOpenPanel = true
            script:SetBossInfo(tbBossInfo, bHasKilled and tbCompleteCatalogue or tbCatalogue)
            script.fnDetailPanel = function()
                local tbNpcInfo = script:GetNPCInfo()
                local nX, nY = script:GetPosition()
                self:ShowWidgetNpc(tbNpcInfo, nX, nY)
                self.TraceScript:Hide()

                if bHasKilled then
                    --已被击杀,传送
                    self.WidgetNpcScript:ShowTransmit(function()
                        RemoteCallToServer("OnMoveToDungeonBoss", tbBossInfo.index)
                        UIMgr.Close(self)
                    end)
                end
            end
            script.fnSelected = function(bSelected)
                self:OnSelectSignButton(script, bSelected)
            end
            table.insert(self.tbNodeScripts["Boss"], script)
        end
        table.insert(tbPogressID, tbBossInfo.nProgress)
    end
end

function UIMiddleMap:UpdateExploreNodes()
    -- 清理现有节点
    self.tbNodeScripts["Explore"] = {}
    UIHelper.RemoveAllChildren(self.WidgetExplore)

    -- 重置加载状态
    self.tbExploreNodesToCreate = {}
    self.nExploreTotalCount = 0
    self.nExploreLoadedCount = 0
    self.bIsLoadingExploreNodes = false

    -- 收集所有需要创建的探索节点
    local tbExploreList = MapHelper.GetMapExploreInfo(self.nMapID) or {}
    for nType, tSubTypeList in pairs(tbExploreList) do
        for nSubType, tList in pairs(tSubTypeList) do
            for _, tbExploreInfo in pairs(tList) do
                local bShow = CanExploreEventShow(tbExploreInfo)
                if bShow then
                    table.insert(self.tbExploreNodesToCreate, {
                        tbExploreInfo = tbExploreInfo,
                        nType = nType,
                        nSubType = nSubType
                    })
                    self.nExploreTotalCount = self.nExploreTotalCount + 1
                end
            end
        end
    end

    -- 如果节点数量少，直接同步创建
    if self.nExploreTotalCount <= self.nExploreLoadingPerFrame then
        self:CreateAllExploreNodesSync()
    else
        -- 数量多时，启动分帧加载
        self:StartExploreNodesAsyncLoading()
    end
end

function UIMiddleMap:CreateAllExploreNodesSync()
    for _, tNodeData in ipairs(self.tbExploreNodesToCreate) do
        self:CreateExploreNode(tNodeData.tbExploreInfo)
    end
    self:RefreshExploreIcon()
    self.tbExploreNodesToCreate = {}
end

function UIMiddleMap:RefreshExploreIcon()
    local nScale = self.TouchComponent:GetScale()
    for _, script in pairs(self.tbNodeScripts["Explore"]) do
        if script and script.fShowScale and not script.bShowNotify then
            script:SetVisible(nScale >= script.fShowScale and self:IsInMapView(script.nLogicX, script.nLogicY))
        end
    end
end

function UIMiddleMap:StartExploreNodesAsyncLoading()
    if #self.tbExploreNodesToCreate == 0 then
        self:RefreshExploreIcon()
        return
    end

    -- 可以在这里显示加载提示（可选）
    self:ShowExploreLoadingTip(true)
end

function UIMiddleMap:ProcessExploreNodesAsync()
    -- 如果没有待创建的节点，完成加载
    if #self.tbExploreNodesToCreate == 0 then
        self:FinishExploreNodesLoading()
        return
    end

    -- 防止重复处理
    if self.bIsLoadingExploreNodes then
        return
    end

    self.bIsLoadingExploreNodes = true
    local nProcessed = 0

    -- 每帧处理固定数量的节点
    while nProcessed < self.nExploreLoadingPerFrame and #self.tbExploreNodesToCreate > 0 do
        local tNodeData = table.remove(self.tbExploreNodesToCreate, 1)
        self:CreateExploreNode(tNodeData.tbExploreInfo)

        self.nExploreLoadedCount = self.nExploreLoadedCount + 1
        nProcessed = nProcessed + 1
    end

    self.bIsLoadingExploreNodes = false

    -- 如果还有未处理的节点，继续下一帧
    if #self.tbExploreNodesToCreate > 0 then
        self:UpdateExploreLoadingProgress()
        self:RefreshExploreIcon()
    else
        self:FinishExploreNodesLoading()
    end
end

function UIMiddleMap:FinishExploreNodesLoading()
    self:RefreshExploreIcon()
    self:ShowExploreLoadingTip(false)
    self.tbExploreNodesToCreate = {}
end

function UIMiddleMap:ShowExploreLoadingTip(bShow)
    -- 可以显示加载提示文本
    if bShow then
        -- 可以显示加载提示UI（可选）
        -- 暂时不实现具体UI，留空
    else
        -- 隐藏加载提示
        -- 暂时不实现具体UI，留空
    end
end

function UIMiddleMap:UpdateExploreLoadingProgress()
    -- 更新加载进度（如果有进度条）
    local fProgress = self.nExploreLoadedCount / self.nExploreTotalCount
    -- 更新UI显示进度（可选）
    -- 暂时不实现具体UI
end

function UIMiddleMap:CreateExploreNode(tbExploreInfo)
    local script = self:CreateMapNodeFromLogicPos(
        self.WidgetExplore,
        tbExploreInfo.nX,
        tbExploreInfo.nY,
        true
    )

    if script then
        script:SetExplore(tbExploreInfo)
        script.fnSelected = function(bSelected)
            self:OnSelectSignButton(script, bSelected)
        end
        script.fnDetailPanel = function()
            local tbNpcInfo = script:GetNPCInfo()
            local nX, nY = UIHelper.ConvertToWorldSpace(script._rootNode:getParent(), script.nX, script.nY)
            self:ShowWidgetNpc(tbNpcInfo, nX, nY)
        end
        script.fShowScale = tbExploreInfo.fShowScale
        table.insert(self.tbNodeScripts["Explore"], script)
    end

    return script
end

function UIMiddleMap:UpdateExploreNotify(nType)
    local tNofityItem = {}
    if self.nExploreNotifyTimer then
        Timer.DelTimer(self, self.nExploreNotifyTimer)
        self.nExploreNotifyTimer = nil
    end
    for _, script in pairs(self.tbNodeScripts["Explore"]) do
        if script.nType == nType and script.nState == MAP_EXPLORE_STATE.EXPLORE then
            script:SetVisible(true)
            script:ShowExploreNotify(true)
            script.bShowNotify = true
        end
    end
    self.nExploreNotifyTimer = Timer.Add(self, 3, function()
        local nScale = self.TouchComponent:GetScale()
        for _, script in pairs(self.tbNodeScripts["Explore"]) do
            if script.nType == nType and script.nState == MAP_EXPLORE_STATE.EXPLORE then
                script:ShowExploreNotify(false)
            end
            script.bShowNotify = false
            script:SetVisible(nScale >= script.fShowScale and self:IsInMapView(script.nLogicX, script.nLogicY))
        end
    end)
end

function UIMiddleMap:UpdateExploreButton()
    local tExploreInfo = MapHelper.GetMapExploreInfo(self.nMapID)
    local bHasExplore  = tExploreInfo and not IsTableEmpty(tExploreInfo)
    UIHelper.SetVisible(self.BtnExplore, bHasExplore)
end

function UIMiddleMap:UpdateMapPosition()
    --[[local winSize = UIHelper.GetWinSizeInPixels()
    local rect = self.WidgetMaskMap:getContentSize()
    local x, y = rect.width / 2, rect.height / 2
    local imgRect = self.ImgMapMask:getContentSize()
    self.nImageScale = rect.height / imgRect.height

    rect.width = imgRect.width * self.nImageScale
    UIHelper.SetScale(self.ImgMapMask, self.nImageScale, self.nImageScale)
    -- UIHelper.SetScale(self.ImgMap, self.nImageScale, self.nImageScale)
    self.ImgMapMask:setPosition(x, y)
    -- self.ImgMap:setPosition(x, y)

    UIHelper.SetScale(self.ImgMargin, self.nImageScale, self.nImageScale)
    UIHelper.SetScale(self.ImgBg, self.nImageScale, self.nImageScale)
    UIHelper.SetScale(self.BtnMap, self.nImageScale, self.nImageScale)]]--
    if not self.tbOriginPos then
        self.tbOriginPos = {}
        for index, node in ipairs(self.tbNeedAdjustPosNode) do
            self.tbOriginPos[node] = UIHelper.GetPositionX(node)
        end
    end
    for index, node in ipairs(self.tbNeedAdjustPosNode) do
        local nX = self.bBoardPanelOpen and -150 or 0
        UIHelper.SetPositionX(node, self.tbOriginPos[node] + nX)
    end
    self:SetMapScale(1)
end

function UIMiddleMap:UpdateFlyLine()
    local tLine = TreasureBattleFieldData.tLine
	if tLine and tLine[1] then
		local tConfig = Table_GetMiddleMapLineConfig(tLine[1])
		UIHelper.SetTexture(self.ImgMapLine, string.format("Resource/StormLine/%s.png", tConfig.szMobileImageLineName))
		UIHelper.SetVisible(self.ImgMapLine, true)
	else
		UIHelper.SetVisible(self.ImgMapLine, false)
	end
end

function UIMiddleMap:SetMapScale(nScale)
    local nScaleY = UIHelper.GetScale(self.WidgetMaskMap)
    if nScaleY ~= 1 then
        if self.nCheckScaleTimer then
            Timer.DelTimer(self, self.nCheckScaleTimer)
            self.nCheckScaleTimer = nil
        end
        self.nCheckScaleTimer = Timer.AddFrameCycle(self, 1, function()
            local nScaleY = UIHelper.GetScaleY(self.WidgetMaskMap)
            if nScaleY == 1 then
                --矫正PositionComponent里nMapY的数据（WidgetMaskMap在播动画Scale没恢复时，ImgMap取得的世界坐标是不正确的，所以在这里做矫正
                --防止出现打开地图界面第一次点击时，所有点向下滑动的现象
                self.TouchComponent:Scale(nScale)
                Timer.DelTimer(self, self.nCheckScaleTimer)
                self.nCheckScaleTimer = nil
            end
        end)
    end
    self.TouchComponent:Scale(nScale)
end

function UIMiddleMap:UpdateMapImage(szImage)
    UIHelper.SetTexture(self.ImgMap, szImage, false)
    -- TODO
    if szImage:find('.tga') then
        self.ImgMap:setFlippedY(true)
    end

    UIHelper.UpdateMask(self.ImgMapMask)

    self:UpdateMapPosition()
end

function UIMiddleMap:OpenCraftPanel(...)
    self:OpenOtherPanel(self.WidgetAnchorSidePanel_Gather)
    self.CraftScript:UpdateInfo(...)
end

function UIMiddleMap:OpenTagPanel(tData)
    self:OpenOtherPanel(self.WidgetAnchorSidePanel_Custom)
    self.TagScript:UpdateInfo(tData)
end

function UIMiddleMap:OpenOtherPanel(targetNode)
    for index, node in ipairs(self.tbOtherPanel) do
        local bVis = node == targetNode
        local script = UIHelper.GetBindScript(node)
        if bVis then
            if script and script.Show then
                script:Show()
            else
                UIHelper.SetVisible(node, node == targetNode)
            end
        else
            if script and script.Hide then
                script:Hide()
            else
                UIHelper.SetVisible(node, node == targetNode)
            end
        end
    end
    UIHelper.SetVisible(self.WidgetAniSidePanel_Trace, false)
    UIHelper.SetVisible(self.WidgetAniSidePanel_Others, true)
end

function UIMiddleMap:AddQuestNode(tPoint, nQuestID, tQuest)
    local nType, nState = QuestData.GetQuestState(tQuest[2], nQuestID)
    local tQuestTab = nType and MapHelper.GetMiddleMapQuestIconTab(nType, nState)
    if not tQuestTab or not tQuestTab.szFrame or QuestData.IsAdventureQuest(nQuestID) then
        return
    end
    local x, y, z = unpack(tPoint)
    local script = self:CreateMapNodeFromLogicPos(self.WidgetQuestParent, x, y, true)
    if script then
        script:SetQuest(tQuest, tPoint, tQuestTab.szFrame, tQuestTab.szBgFrame)
        script.bOpenPanel = true
        script.fnDetailPanel = function(bTrace)
            self.TagScript:Hide()
            self.TraceScript:ShowQuest(tQuest, self.nMapID, tPoint, bTrace, tQuestTab.szFrame)
        end
        script.fnSelected = function(bSelected)
            if bSelected then
                self:OnSelectSignButton(script, bSelected)
            else
                self.TraceScript:Hide()
            end
        end

        self.tbNodeScripts["quest"] = self.tbNodeScripts["quest"] or {}
        table.insert(self.tbNodeScripts["quest"], script)
    end
end

function UIMiddleMap:AddMyQuestNode(tbRedPointQuestInfo, nIndex)
    local nQuestID, tbPoints, bFinished, szType = unpack(tbRedPointQuestInfo)
    local x, y, z = unpack(tbPoints)
    local script = self:CreateMapNodeFromLogicPos(self.WidgetQuestParent, x, y, true)
    if script then
        script.bOpenPanel = true
        script:SetMyQuest(nQuestID, tbPoints, nIndex, bFinished)
        script.fnDetailPanel = function(bTrace)
            if bFinished then
                local szFrame = "UIAtlas2_Public_PublicIcon_PublicIcon1_icon_renwuWC_huang.png"
                self.TraceScript:ShowQuest({nQuestID, szType}, self.nMapID, tbPoints, bTrace, szFrame)
            else
                local nWorldX, nWorldY = self.PosComponent:LogicPosToMapPos(x, y)
                local szTips = QuestData.GetMiddleMapMyQuestTip(nQuestID)
                local tips, tipsScript = TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetPublicLabelTips, nWorldX, nWorldY,  szTips)
            end
            self.TagScript:Hide()
            MapMgr.SetRedPointQuest(tbRedPointQuestInfo, self.nMapID)
        end
        script.fnSelected = function(bSelected)
            self:OnSelectSignButton(script, bSelected)
        end

        self.tbNodeScripts["MyQuest"] = self.tbNodeScripts["MyQuest"] or {}
        table.insert(self.tbNodeScripts["MyQuest"], script)

    end
end

function UIMiddleMap:AddQuestNodes()
    for k, v in ipairs(self.tbQuestNode) do
        local nQuestID, szType = unpack(v)

        local tData = TableQuest_GetPoint(nQuestID, szType, self.nIndex, self.nMapID, self.nArea or 0)
        for _, tPoints in ipairs(tData or {}) do
            if tData then
                if tPoints.type == "R" then
                    for _, tPoint in ipairs(tPoints) do

                    end
                else
                    for _, tPoint in ipairs(tPoints) do
                        self:AddQuestNode(tPoint, nQuestID, v)
                    end
                end
            end
        end
    end

    for k, v in ipairs(self.tbMyQuestNode) do
        local nQuestID, tPoints, bFinished, szType = unpack(v)
        self:AddMyQuestNode(v, k)
    end
end

function UIMiddleMap:UpdateQuestTarget(dwQuestID, szType, nIndex, bFirstHide)
    local tData = nil
    if dwQuestID and szType then
        tData = TableQuest_GetPoint(dwQuestID, szType, nIndex, self.nMapID, QuestData.GetAreaID() or 0)
    end
    if not tData then
        return
    end

    local bFirst = true
    for _, tPoints in ipairs(tData) do
        if tPoints.type == "R" then
            for _, tPoint in ipairs(tPoints) do
                bFirst = false
            end
        else
            for _, tPoint in ipairs(tPoints) do
                if self:IsPointShow(tPoint) then
                    if not bFirst or not bFirstHide then
                        self:AddQuestRedPoint(dwQuestID, szType, nIndex, tPoint)
                    end
                    bFirst = false
                end
            end
        end
    end

end

function UIMiddleMap:AddQuestRedPoint(dwQuestID, szType, nIndex, tPoint)
    local script = self:CreateMapNodeFromLogicPos(self.WidgetRedPoint, tPoint[1], tPoint[2], true)
    if script then
        script:SetRedPoint()
    end
end

function UIMiddleMap:IsPointShow(tPoint)
    local hPlayer = g_pClientPlayer
	if not hPlayer then
		return
	end

	local dwActivityID = tPoint[8]
	local bMatch = true
	if dwActivityID and dwActivityID > 0 then
		bMatch = ActivityData.MatchActivity(dwActivityID)
	end
	if not bMatch then
		return false
	end

	local bIdentity = true
	local dwIdentityVisiableID = tPoint[7]
	if dwIdentityVisiableID then
		if not hPlayer.IsQuestIdentityVisiable(hPlayer.dwIdentityVisiableID, dwIdentityVisiableID) then
			bIdentity = false
		end
	end
	return bIdentity
end

function UIMiddleMap:UpdateRedPoint()
    local tbRedPointInfo = MapMgr.GetRedPointQuestInfo(self.nMapID)
    if not tbRedPointInfo and #self.tbMyQuestNode > 0 then
        MapMgr.SetRedPointQuest(self.tbMyQuestNode[1], self.nMapID)
    end

    if tbRedPointInfo then
        local dwQuestID, szType, nTraceIndex = tbRedPointInfo[1], tbRedPointInfo[4], tbRedPointInfo[5]
        self:MarkTargetOfQuest(dwQuestID, szType, nTraceIndex)
    end
end

function UIMiddleMap:MarkTargetOfQuest(dwQuestID, szType, nTraceIndex)
    UIHelper.RemoveAllChildren(self.WidgetRedPoint)
	local hPlayer = g_pClientPlayer
	if not hPlayer then
		return
	end
	local bShow = QuestData.IsShowQuestTraceInfo(dwQuestID)
	if not bShow then
		return
	end

	local bFirstPointHide = false
	local tQuestTrace = hPlayer.GetQuestTraceInfo(dwQuestID)
	for k, v in pairs(tQuestTrace.quest_state) do
		if v.have < v.need then
			bFirstPointHide = false
			if szType == "quest_state" and v.i == nTraceIndex then
				bFirstPointHide = true
			end

			self:UpdateQuestTarget(dwQuestID, "quest_state", v.i, bFirstPointHide)
		end
	end

	for k, v in pairs(tQuestTrace.kill_npc) do
		if v.have < v.need then
			bFirstPointHide = false
			if szType == "kill_npc" and v.i == nTraceIndex then
				bFirstPointHide = true
			end
			self:UpdateQuestTarget(dwQuestID, "kill_npc", v.i, bFirstPointHide)
		end
	end

	for k, v in pairs(tQuestTrace.need_item) do
		local itemInfo = GetItemInfo(v.type, v.index)
		local nBookID = v.need
		if itemInfo.nGenre == ITEM_GENRE.BOOK then
			v.need = 1
		end
		if v.have < v.need then
			bFirstPointHide = false
			if szType == "need_item" and v.i == nTraceIndex then
				bFirstPointHide = true
			end
			self:UpdateQuestTarget(dwQuestID, "need_item", v.i, bFirstPointHide)
		end
	end

end

function UIMiddleMap:AddTagNode(tData)
    local script = self:CreateMapNodeFromLogicPos(self.WidgetTag, tData.nX, tData.nY, true)
    if not script then
        return
    end
    script.bOpenPanel = true
    script.fnSelected = function(bSelected)
        self:OnSelectSignButton(script, bSelected)
    end
    script.fnDetailPanel = function()
        self.CraftScript:Hide()
        self:OpenTagPanel(tData)
    end
    self.tbNodeScripts["Tag"] = self.tbNodeScripts["Tag"] or {}
    table.insert(self.tbNodeScripts["Tag"], script)
    script:SetTag(tData)

    return script
end

function UIMiddleMap:CreateTagNode(nX, nY)
    local nCount = MapMgr.GetTagListLen(self.nMapID)
    local x, y = self.PosComponent:MapPosToLogicPos(nX, nY)

    local tData = {
        nX = x,
        nY = y,
        nMapID = self.nMapID,
        nIndex = nCount + 1,
        szName = g_tStrings.STR_MIDDLE_MAP_TAG_NAME,
        nIconID = 7,
        szUID = string.format("%d_%d_%d", self.nMapID, nX, nY),
        bCreated = false,
    }

    local script = self:AddTagNode(tData)
    if script then
        script:SetSelected(true, true, false)
        self:OpenTagPanel(tData)
    end
end


function UIMiddleMap:UpdateTagNodes()
    self.TagScript:Hide()
    for _, script in ipairs(self.tbNodeScripts["Tag"] or {}) do
        -- script._rootNode:removeFromParent(true)
        self:DeleteMarkNode(script)
    end

    self.tbNodeScripts["Tag"] = nil
    for _, tData in ipairs(MapMgr.GetTagList(self.nMapID)) do
        self:AddTagNode(tData)
    end
end

function UIMiddleMap:AddTeamTag()
    local nMapID = Storage.MiddleMapData.tbTeamTagInfo.nMapID
    if nMapID ~= self.nMapID then
        return
    end
    local tbData = MapMgr.GetTeamTag()
    if not tbData then return end
    self:AddTagNode(tbData)
end

function UIMiddleMap:RemoveTeamTag()
    if not self.tbNodeScripts then return  end
    for _, script in ipairs(self.tbNodeScripts["Tag"] or {}) do
        if script:IsTeamTag() then
            -- script._rootNode:removeFromParent(true)
            self:DeleteMarkNode(script)
            table.remove(self.tbNodeScripts["Tag"], _)
            break
        end
    end
end

local function CanAcceptByActivity(dwActivityID)
    if dwActivityID <= 0 then
        return true
    end
    return GetActivityMgrClient().IsActivityOn(dwActivityID)
end

function UIMiddleMap:FillAcceptedQuest()
    local player = GetClientPlayer()
    if not player then
        return
    end
    local tQuest = player.GetQuestTree()
    for _, tClass in pairs(tQuest) do
        for _, nQuesIndex in pairs(tClass) do
            local dwQuestID = player.GetQuestID(nQuesIndex)
            local tQuestTrace = player.GetQuestTraceInfo(dwQuestID)

            if tQuestTrace.finish then
                if Table_GetQuestPosInfo(dwQuestID, "finish", 0) then
                    table.insert(self.tbQuestNode, {dwQuestID, "finish"})
                end
            else
                for _, v in pairs(tQuestTrace.quest_state) do
                    if v.have < v.need and Table_GetQuestPosInfo(dwQuestID, "quest_state", v.i) then
                        table.insert(self.tbQuestNode, {dwQuestID, "quest_state"})
                    end
                end

                for _, v in pairs(tQuestTrace.kill_npc) do
                    if v.have < v.need and Table_GetQuestPosInfo(dwQuestID, "kill_npc", v.i) then
                        table.insert(self.tbQuestNode, {dwQuestID, "kill_npc"})
                    end
                end

                for _, v in pairs(tQuestTrace.need_item) do
                    if v.have < v.need and Table_GetQuestPosInfo(dwQuestID, "need_item", v.i) then
                        table.insert(self.tbQuestNode, {dwQuestID, "need_item"})
                    end
                end
            end
        end
    end
end

function UIMiddleMap:FillCanAcceptQuest(nMapID)
    local player = g_pClientPlayer
    if not player then
        return
    end

    for nQuestID, tObject in pairs(self.tbCanAcceptQuest) do
        local bCanAccept = false
        local tQuestUIInfo = Table_GetQuestStringInfo(nQuestID)

        if CanAcceptByActivity(tQuestUIInfo.dwActivityID) then
            for _, tInfo in pairs(tObject) do
                local szType = tInfo[1]
                local dwObject = tInfo[2]
                if szType == "D" or szType == "N" then
                    if dwObject > 0 then
                        if player.CanAcceptQuest(nQuestID, dwObject) == QUEST_RESULT.SUCCESS then
                            bCanAccept = true
                            break
                        end
                    end
                elseif szType == "P" then
                    if player.CanAcceptQuest(nQuestID) == QUEST_RESULT.SUCCESS then
                        bCanAccept = true
                        break
                    end
                end
            end
        end

        if bCanAccept then
            table.insert(self.tbQuestNode, {nQuestID, "accept"})
        end
    end
end

function UIMiddleMap:UpdateQuestNodes()
    UIHelper.RemoveAllChildren(self.WidgetQuestParent)
    self.tbMyQuestNode = QuestData.GetAllQuestIDByMapID(self.nMapID)
    self.tbQuestNode = {}
    -- self:FillAcceptedQuest()
    self:FillCanAcceptQuest()
    self:AddQuestNodes()
    self:UpdateRedPoint()
    self:UpdateQuestVis()
end

function UIMiddleMap:UpdateQuestVis()
    UIHelper.SetVisible(self.WidgetQuestParent, MapMgr.IsShowQuest())
end

function UIMiddleMap:Table_GetMapDynamicData()
    if not self.tDynamicParam then
        local tResult = {}
        local nCount = g_tTable.Map_DynamicData:GetRowCount()

        --Row One for default value
        for i = 2, nCount do
            local tData = g_tTable.Map_DynamicData:GetRow(i)
            tResult[tData.nType] = tData
        end
        self.tDynamicParam = tResult
    end
    return self.tDynamicParam
end

function UIMiddleMap:Table_GetBattleMarkState()
    return MapMgr.Table_GetBattleMarkState()
end

function UIMiddleMap:RegisterEvent()
    UIHelper.BindUIEvent(self.TogHide, EventType.OnSelectChanged, function(_, bSelect)
        if bSelect then
            self:ShowShieldSelect()
        end
    end)

    UIHelper.BindUIEvent(self.BtnCloseLeftPanel, EventType.OnTouchBegan, function(btn, nX, nY)
        Event.Dispatch("ON_TOUCH_MAP_BEGAN", nX, nY)
    end)

    UIHelper.BindUIEvent(self.BtnCloseLeftPanel, EventType.OnTouchMoved, function(btn, nX, nY)
        Event.Dispatch("ON_TOUCH_MAP_MOVE", nX, nY)
    end)

    UIHelper.BindUIEvent(self.BtnCloseLeftPanel, EventType.OnTouchEnded, function(btn, nX, nY)
        Event.Dispatch("ON_TOUCH_MAP_END", nX, nY)
    end)

    UIHelper.BindUIEvent(self.BtnCloseLeftPanel, EventType.OnTouchCanceled, function(btn, nX, nY)
        Event.Dispatch("ON_TOUCH_MAP_CANCEL", nX, nY)
    end)

    UIHelper.BindUIEvent(self.BtnClose05, EventType.OnClick, function()
        UIMgr.Close(VIEW_ID.PanelMiddleMap)
    end)
    UIHelper.BindUIEvent(self.BtnWorldMap, EventType.OnClick, function()
        if not SystemOpen.IsSystemOpen(SystemOpenDef.WorldMap, true) then
            return
        end
        UIMgr.CloseImmediately(self)
        if not UIMgr.GetView(VIEW_ID.PanelWorldMap) then
            UIMgr.Open(VIEW_ID.PanelWorldMap)
        end

    end)
    UIHelper.BindUIEvent(self.BtnSign, EventType.OnClick, function()
        local aNpc = MapMgr.GetNpcList(self.nMapID) or {}
        self.SignScript:Show()
        self.SignScript:UpdateInfo(aNpc, self.tbNodeSelect, self.nMapID, self.nIndex)
    end)
    UIHelper.BindUIEvent(self.BtnGather, EventType.OnClick, function()
        if g_pClientPlayer and g_pClientPlayer.nLevel >= 106 then
            self:OpenCraftPanel(self.nMapID)
        else
            TipsHelper.ShowNormalTip("侠士达到106级后方可查看采集点")
        end

    end)
    UIHelper.BindUIEvent(self.BtnMap, EventType.OnTouchEnded, function(touch, nX, nY)
        self:DebugFly(nX, nY)
    end)

    UIHelper.BindUIEvent(self.BtnExplore, EventType.OnClick, function()
        self.ExploreScript:Show()
         self.ExploreScript:UpdateInfo(self.nMapID)
    end)

    UIHelper.BindUIEvent(self.BtnLineUp, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelMapLineUpPop)
    end)

    for nIndex, toggle in ipairs(self.tbMarkList) do
        UIHelper.BindUIEvent(toggle, EventType.OnSelectChanged, function(_, bSelected)
            if bSelected then
                self:SetBoardMarkType(nIndex)
            end
        end)
        UIHelper.SetToggleGroupIndex(toggle, ToggleGroupIndex.BagItem)
        UIHelper.SetTouchEnabled(toggle, MapMgr.IsPlayerCanDraw())
    end

    UIHelper.BindUIEvent(self.BtnSynchronous, EventType.OnClick, function()
        if not MapMgr.IsPlayerCanDraw() then return end
        self:ClearBoardInfo()
        RemoteCallToServer("On_Camp_GFSaveBoard", self:GetAllBoardInfo())
    end)

    UIHelper.BindUIEvent(self.BtnRevert, EventType.OnClick, function()
        if not MapMgr.IsPlayerCanDraw() then return end
        self:RemoveAllBoardDraw()
        self:ClearBoardInfo()
        RemoteCallToServer("On_Camp_DelCampSimplePos", CampOBBaseData.GetCampOfBoardInfo())
    end)

    UIHelper.RegisterEditBox(self.EditKindSearch, function(szType, _editbox)
        if szType == "began" then
            self.CloseScript:SetTouchEnabled(false)
        elseif szType == "ended" or szType == "return" then
            local szKey = UIHelper.GetString(self.EditKindSearch)
            self:SearchNPC(szKey)

            if self.nEditOutTimer then
                Timer.DelTimer(self, self.nEditOutTimer)
                self.nEditOutTimer = nil
            end

            self.nEditOutTimer = Timer.AddFrame(self, 1 ,function()
                self.CloseScript:SetTouchEnabled(true)--延迟打开，防止点击到地图出侧面板
                self.nEditOutTimer = nil
            end)
        end
    end)

    UIHelper.BindUIEvent(self.BtnClear, EventType.OnClick, function()
        UIHelper.SetText(self.EditKindSearch, "")
        self:SearchNPC("")
    end)

    UIHelper.BindUIEvent(self.TogQuestion, EventType.OnSelectChanged, function(_, bSelected)
        if not bSelected then
            UIHelper.SetVisible(self.WidgetAnchorLeaveFor, false)
        end
    end)

    UIHelper.BindUIEvent(self.TogPQCommand, EventType.OnSelectChanged, function(_, bSelected)
        self:OpenOrCloseBoardPanel(bSelected)
    end)

    UIHelper.BindUIEvent(self.TogChangeMap, EventType.OnSelectChanged, function(_, bSelected)
        Event.Dispatch(EventType.OnSwitchCampRightTopState, bSelected, true)
    end)

    UIHelper.BindUIEvent(self.TogTraceOthers, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            self:ShowTraceInfo()
        end
    end)

    UITouchHelper.BindUIZoom(self.WidgetTouch, function(delta)
        if self.TouchComponent then
            self.TouchComponent:Zoom(delta)
        end
    end)

    UIHelper.BindUIEvent(self.BtnBig, EventType.OnClick, function()
        self.bAutoSetPercent = false
        local nProgressBarPercent = UIHelper.GetProgressBarPercent(self.SliderCount)
        local nPercent = math.floor(nProgressBarPercent / SCALE_RATE) * SCALE_RATE + SCALE_RATE
        UIHelper.SetProgressBarPercent(self.SliderCount, nPercent)
    end)

    UIHelper.BindUIEvent(self.BtnSmall, EventType.OnClick, function()
        self.bAutoSetPercent = false
        local nProgressBarPercent = UIHelper.GetProgressBarPercent(self.SliderCount)
        local nPercent = math.floor(nProgressBarPercent / SCALE_RATE) * SCALE_RATE - SCALE_RATE
        UIHelper.SetProgressBarPercent(self.SliderCount, nPercent)
    end)

    UIHelper.BindUIEvent(self.SliderCount, EventType.OnChangeSliderPercent, function(slider, event)
        if self.bAutoSetPercent then self.bAutoSetPercent = false return end
        local nProgressBarPercent = UIHelper.GetProgressBarPercent(self.SliderCount)
        local nWidth = UIHelper.GetWidth(self.SliderCount) * nProgressBarPercent / 100
        UIHelper.SetWidth(self.ImgFg, nWidth)
        local nScale = nProgressBarPercent / 100 * (MAX_SCALE - 1) + 1
        if self.TouchComponent then
            self.TouchComponent:Scale(nScale)
        end
    end)

    UIHelper.BindUIEvent({self.BtnTeaceWalkRight, self.BtnTeaceWalkLeft}, EventType.OnClick, function()
        local szName, nMapID, tbPoint = MapMgr.GetTraceInfo()
        AutoNav.NavTo(nMapID, tbPoint[1], tbPoint[2], tbPoint[3])
    end)

    UIHelper.BindUIEvent(self.BtnShuntFilter, EventType.OnClick, function()
        self.bClickShuntFilter = not self.bClickShuntFilter
        self:UpdateMapCopyFilter()
    end)

    UIHelper.BindUIEvent(self.BtnRefresh, EventType.OnClick, function ()
        HeatMapData.DoApplyHeatMapInfo()
    end)

    UIHelper.BindUIEvent(self.BtnCampNum, EventType.OnClick, function ()
        local bVis = UIHelper.GetVisible(self.WidgetAnchorSidePanel_Camp) and UIHelper.GetVisible(self.WidgetAniSidePanel_Others)
        if not bVis then
            self:OpenOtherPanel(self.WidgetAnchorSidePanel_Camp)
        else
            UIHelper.SetVisible(self.WidgetAnchorSidePanel_Camp, false)
            UIHelper.SetVisible(self.WidgetAniSidePanel_Others, false)
        end
    end)

    UIHelper.BindUIEvent(self.BtnHelp4, EventType.OnClick, function()
        local szContent = "开启后显示攻防场景（浩气盟、恶人谷）系统预设场景和镜头的天气表现效果。"
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.BtnHelp4, TipsLayoutDir.TOP_CENTER, szContent)
    end)
    UIHelper.BindUIEvent(self.ToggleLightPositionSwitch, EventType.OnSelectChanged, function(_, bSelected)
        local function _setActivityPreset()
            SelfieData.EnableActivityPreset(bSelected)
            local dwCurMapID = MapHelper.GetMapID()
            if dwCurMapID == 25 or dwCurMapID == 27 then
                SelfieData.ResetFilterFromStorage()
            end
        end

        if bSelected then
            UIHelper.ShowConfirm("开启后显示攻防场景（浩气盟、恶人谷）系统预设场景和镜头的天气表现效果，会影响性能消耗，是否开启？",
            _setActivityPreset,
            function()
                UIHelper.SetSelected(self.ToggleLightPositionSwitch, false, false)
            end)
        else
            _setActivityPreset()
        end
    end)

    Event.Reg(self, EventType.ON_UPDATE_MIDDLE_MAP_LINE, function()
        self:UpdateFlyLine()
    end)

    Event.Reg(self, EventType.OnRefreshHuntEvent, function()
        self:UpdateDynamicNodes()
    end)

    Event.Reg(self, EventType.OnSelectHeatMapMode, function(nIndex)
        if HeatMapData.bCanShowHeatMap then
            self:UpdateHeatMapNum()
        end
    end)

    Event.Reg(self, "OnUpdateSceneProgress", function()
        self:UpdateBossNodes()
    end)

    Event.Reg(self, "ON_MIDDLE_MAP_REDPOINT_CHANGE", function()
        self:UpdateRedPoint()
    end)

    Event.Reg(self, "ON_MIDDLE_UPDATE_SIGN_BUTTON_POS", function(script, nLogicX, nLogicY)
        self:UpdateNodePos(script, nLogicX, nLogicY)
    end)

    Event.Reg(self, "ON_MIDDLE_UPDATE_MAP_ARROW_POS", function(tbArrowInfo, script)
        self:UpdateArrowPos(tbArrowInfo, script)
    end)

    Event.Reg(self, EventType.OnClickToHide, function(touch, nX, nY)
        if self.bBoardPanelOpen then return end--指挥标记已经打开
        if self:TryCloseSearchList() then return end--关闭搜索列表
        if self:TryCloseShieldTip() then return end--关闭神行和任务开关
        if self:TryCloseCampFilter() then return end--关闭显示统计点列表

        self:UpdateTagNodes()
        if self.bSidePanelHidden then
            self:CreateTagNode(self.nTouchX, self.nTouchY)
        end
    end)

    Event.Reg(self, "ON_TOUCH_MAP_BEGAN", function(nX, nY)
        self.nTouchX, self.nTouchY = nX, nY
        Event.Dispatch('ON_MIDDLE_MAP_SIGN_TOGGLE', false, true)
        self.bSidePanelHidden = self.CloseScript:IsHidden()

        if not self.bBoardPanelOpen or not self.nBoardMarkType then--没有在阵营指挥或者阵营指挥没有选中标记
            self.TouchComponent:TouchBegin(nX, nY)
            self.bStartMove = true
            return
        end

        if self.scriptMoveNode then --移动节点
            nX, nY = self.PosComponent:MapPosToLogicPos(nX, nY)
            self.scriptMoveNode.fnMove(nX, nY)
            self.scriptMoveNode = nil
            Event.Dispatch("ON_END_MOVE_BOARD_NODE")
        else
            if self:CreateBoardNode(nX, nY) and self:IsArrowMark() then
                self.bInArrowMode = true
            end
        end
    end)

    Event.Reg(self, "ON_TOUCH_MAP_MOVE", function(nX, nY)
        if self.bInArrowMode then
            self:UpdateArrowRotationAndLenth(nX, nY)
        elseif self.bStartMove then
            self.TouchComponent:TouchMoved(nX, nY)
        end

    end)

    Event.Reg(self, "ON_TOUCH_MAP_END", function(nX, nY)
        if self.bInArrowMode then
            self.bInArrowMode = false
        elseif self.bStartMove then
            self.bStartMove = false
        end
    end)

    Event.Reg(self, "ON_TOUCH_MAP_END", function(nX, nY)
        if self.bInArrowMode then
            self.bInArrowMode = false
        elseif self.bStartMove then
            self.bStartMove = false
        end
    end)

    Event.Reg(self, "ON_TOUCH_MAP_CANCEL", function(nX, nY)
        if self.bInArrowMode then
            self.bInArrowMode = false
        elseif self.bStartMove then
            self.bStartMove = false
        end
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function ()
        if self.Timer then
            Timer.DelTimer(self, self.Timer)
            self.Timer = nil
        end

        self.Timer = Timer.AddFrame(self, 2, function()
            self:UpdateMapPosition()
            self:UpdateMarkNodes()
            self:UpdateDynamicNodes()
            self:UpdateNodeTrace()
            self:UpdateNodeAutoNav()
            self:UpdateActivitySymbol()
            self.Timer = nil
        end)
    end)

    Event.Reg(self, EventType.OnKeyboardDown, function(nKeyCode, szKeyName)
        if nKeyCode == cc.KeyCode.KEY_SHIFT then
            self.bShiftDown = true
            self:SetDebugFlyVisible(false)
        end
    end)
    Event.Reg(self, EventType.OnKeyboardUp, function(nKeyCode, szKeyName)
        if nKeyCode == cc.KeyCode.KEY_SHIFT then
            self.bShiftDown = false
            self:SetDebugFlyVisible(true)
        end
    end)
    Event.Reg(self, "ON_MIDDLE_MAP_MARK_HIGHLIGHT", function(nTypeID, bSelected)
        self:UpdateSelectNpcHighlight(nTypeID, bSelected)
    end)

    Event.Reg(self, "ON_MIDDLE_MAP_MARK_SHOW", function(tbNpc, nIndex)
        if self.tbNpc then
            self.tbNodeScripts[self.tbNpc] = nil
        end

        if nIndex ~= self.nIndex then
            OnShowMap(self, nIndex, true)
        end

        self.tbNpc = tbNpc
        self:UpdateExtraNodes()
    end)

    Event.Reg(self, "ON_MIDDLE_MAP_MARK_UNCHECK", function()
        Event.Dispatch('ON_MIDDLE_MAP_SIGN_TOGGLE', false, true)
        self.TraceScript:Hide()
    end)
    Event.Reg(self, "ON_MIDDLE_MAP_SHOW_AREA", function(nArea)
        OnShowMap(self, nArea, true)
        self.TraceScript:Hide()
    end)
    Event.Reg(self, "ON_MIDDLE_MAP_SHOW_CRAFT", function(bCraftShow)
        self:UpdateCraft()
    end)
    Event.Reg(self, "ON_MIDDLE_MAP_SWITCH_SHENXING", function()
        self:UpdateCraft()
    end)
    Event.Reg(self, "ON_MIDDLE_MAP_UPDATE_TAGS", function()
        self:UpdateTagNodes()
    end)
    Event.Reg(self, EventType.OnMapUpdateNpcTrace, function()
        self:CloseAllTip()
        self:UpdateNodeTrace()
        Event.Dispatch("ON_MIDDLE_MAP_SIGN_TOGGLE", false, true)
    end)
    Event.Reg(self, EventType.OnMapOpenTraffic, function(tbTraffic)
        self:UpdateTraffic(tbTraffic)
    end)
    --[[Event.Reg(self, "ON_MAP_UPDATE_DYNAMIC_DATA_EX", function(tbDataEx)
        self:UpdateDataEx(tbDataEx)
    end)]]--
    Event.Reg(self, "ON_MAP_MARK_UPDATE", function()
        self:UpdateDynamicNodes()
    end)

    Event.Reg(self, "ON_FIELD_MARK_STATE_UPDATE", function(tFieldMark)
        if not g_pClientPlayer then
            return
        end

        local dwMapID = g_pClientPlayer.GetMapID()

        MapHelper.dwFieldMapID = dwMapID
        MapHelper.tFieldMark = tFieldMark
        self:UpdateDynamicNodes()
    end)
    Event.Reg(self, EventType.OnClientPlayerEnter, function()
        if not g_pClientPlayer then
            return
        end

        local dwMapID = g_pClientPlayer.GetMapID()

        if MapHelper.dwFieldMapID and MapHelper.dwFieldMapID ~= dwMapID then
            MapHelper.tFieldMark = nil
        end
    end)

    Event.Reg(self, "ON_WANTED_PLAYER_POSITION_UPDATE", function()
        self:UpdateWantedNodes(GetWantedPlayerPositions() or {})
    end)

    Event.Reg(self, EventType.OnMapQueueDataUpdate, function ()
        self:UpdateMapQueueInfo()
    end)

    Event.Reg(self, EventType.OnMapMarkUpdate, function (bClearMapMark)
        if bClearMapMark then
            self:RemoveMapMark("MapMark")
            self:RemoveMapMark("HomeLandMapMark")
        end

        self:UpdateMapMark()
    end)

    Event.Reg(self, EventType.OnHomeLandMapMarkUpdate, function ()
        self:UpdateHomeLandMapMark()
    end)

    Event.Reg(self, "ON_MIDDLE_MAP_REFRESH", function (nMapID, nIndex)
        self:UpdateInfo(nMapID, nIndex)
    end)
    Event.Reg(self, "ON_MIDDLE_MAP_CRAFT_UPDATE", function(nCraftID, nID, tbCraft, bShow)
        self:UpdateCraftNodes()
    end)
    Event.Reg(self, "ON_MIDDLE_MAP_TAG_REMOVE", function(nMapID, nIndex)
        if nMapID ~= self.nMapID then
            return
        end
        MapMgr.DeleteTag(nMapID, nIndex)

        if self.tbNodeScripts and self.tbNodeScripts["Tag"] and self.tbNodeScripts["Tag"][nIndex] then
            if safe_check(self.tbNodeScripts["Tag"][nIndex]._rootNode) then
                -- self.tbNodeScripts["Tag"][nIndex]._rootNode:removeFromParent(true)
                self:DeleteMarkNode(self.tbNodeScripts["Tag"][nIndex])
            end
            table.remove(self.tbNodeScripts["Tag"], nIndex)
        end

        UIHelper.SetVisible(self.WidgetAniSidePanel_Others, false)
    end)
    Event.Reg(self, "ON_MIDDLE_MAP_TAG_UPDATE_ICON", function(tbData)
        if not tbData then
            return
        end

        if tbData.nMapID ~= self.nMapID then
            return
        end

        if self.tbNodeScripts and self.tbNodeScripts["Tag"] and self.tbNodeScripts["Tag"][tbData.nIndex] then
            self.tbNodeScripts["Tag"][tbData.nIndex]:SetTag(tbData)
        end
    end)

    Event.Reg(self, "ON_MIDDLE_MAP_SHOW_DETAIL", function(tbNPC)
        if tbNPC and self.tbNodeScripts and self.tbNodeScripts[tbNPC] then
            local script = self.tbNodeScripts[tbNPC][1]
            if script then
                script.bNotShowNeibor = true--直接显示追踪tip
                script:SetSelected(true, true)
            end
        end
        UIHelper.SetVisible(self.WidgetAniSidePanel_Sign, false)
    end)

    Event.Reg(self, EventType.OnLeaderChangeTeamTag, function()
        if MapMgr.HasTeamTag() then
            self:AddTeamTag()
        else
            self:RemoveTeamTag()
        end
    end)

    Event.Reg(self, EventType.OnDeleteTeamMark, function()
        self:RemoveTeamTag()
    end)

    Event.Reg(self, EventType.ClientChangeAutoNavState, function(bStart)
        if bStart then
            UIMgr.Close(self)
        else
            self:UpdateNodeAutoNav()
            self:UpdateNodeTrace()
        end
    end)

    Event.Reg(self, EventType.OnAutoNavResult, function(bSuccess)
        -- if bSuccess then
            self:UpdateNodeAutoNav()
            self:UpdateNodeTrace()
        -- end
    end)

    Event.Reg(self, EventType.OnClickSearchList, function(tbNPCInfo)
        self.tbSearchNpcInfo = tbNPCInfo
        self:CloseWidgetPQ()
        self:UpdateSearchNpcNodes()
    end)

    Event.Reg(self, EventType.OnHeatMapDataUpdate, function()
        self:UpadteHeatMap()
    end)

    Event.Reg(self, EventType.OnSelectCampCell, function(nPQID)
        self:UpdateHighLightArea(nPQID)
    end)

    Event.Reg(self, EventType.OnKillerPosUpdate, function(tbKillerList)
        self:UpdateKillerPos(tbKillerList)
    end)

    Event.Reg(self, "BOARD_INFO_HAS_BEEN_UPDATED", function()
        if not self.initialized then return end
        self:UpdateBoardInfo()
    end)

    Event.Reg(self, "CHANGE_CAMP_UI", function(nX, nY, nCamp)
        self:UpdateBoardGatherPos(nX, nY, nCamp)
    end)

    Event.Reg(self, "DESTROY_CAMP_UI", function(nCamp)
        if nCamp ~= CampOBBaseData.GetCampOfBoardInfo() then return end
        self:RemoveGatherNode()
    end)

    Event.Reg(self, "CAMP_OB_BECOME_PLAYER", function()
        self:UpdateBoardInfo()
    end)

    Event.Reg(self, "ON_START_MOVE_BOARD_NODE", function(script)
        self.scriptMoveNode = script
    end)

    Event.Reg(self, "ON_MIDDLE_MAP_SIGN_TOGGLE", function(obj, bSelected)
        UIHelper.SetSelected(self.TogTraceOthers, false, false)
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        if self.bClickShuntFilter then
            self.bClickShuntFilter = false
            self:UpdateMapCopyFilter()
        end
    end)
    Event.Reg(self, "ON_MIDDLE_MAP_SCALE_CHANGE", function()
        self:UpdateNodeTrace()
        self:UpdateQuestTrace()
        self:UpdateNodeAutoNav()
        self:UpdateAllLinePos()
        self:CloseAllTip()
        self:RefreshExploreIcon()
        self:HidePlayerWhenScaleChanged()
        UIHelper.SetSelected(self.TogTraceOthers, false, false)
    end)

    Event.Reg(self, "CUSTOM_RANK_UPDATE", function(nType)
		if nType == RANK_LIST_ID then
			self:UpdatePQData()
		end
    end)

    Event.Reg(self, "ACTIVITY_SYMBOL_RESPOND", function(dwMapID, dwSymbol)
        self:UpdateActivitySymbol(dwMapID, dwSymbol)
    end)

    Event.Reg(self, "LUA_ON_ACTIVITY_STATE_CHANGED_NOTIFY", function(dwActivityID, bOpen)
        self:UpdateWeather()
    end)
    Event.Reg(self, "ON_ACTIVITY_PRESET_ENABLE_STATE_CHANGE", function()
        self:UpdateWeather()
    end)

    Event.Reg(self, "MAP_EXPLORE_NOTIFY", function(nType)
        self:UpdateExploreNotify(nType)
    end)

    Event.Reg(self, "UPDATE_MAP_EXPLORE", function()
        self:UpdateExploreNodes()
        if UIHelper.GetVisible(self.ExploreScript._rootNode) then
            self.ExploreScript:UpdateInfo(self.nMapID)
        end
    end)

    Event.Reg(self, "REMOTE_EXPLOR_YWYD_FRESH", function()
        self:UpdateExploreNodes()
        if UIHelper.GetVisible(self.ExploreScript._rootNode) then
            self.ExploreScript:UpdateInfo(self.nMapID)
        end
    end)
end

function UIMiddleMap:UnRegisterEvent()
    UITouchHelper.UnBindUIZoom()
end

function UIMiddleMap:InitSidePanel()
    self.SignScript = UIHelper.GetBindScript(self.WidgetAniSidePanel_Sign)
    self.TraceScript = UIHelper.GetBindScript(self.WidgetAniSidePanel_Trace)
    self.CampDetailScript = UIHelper.GetBindScript(self.WidgetAnchorSidePanel_Camp)
    self.ExploreScript = UIHelper.GetBindScript(self.WidgetAniSidePanel_Explore)

    self.TipScript = UIHelper.GetBindScript(self.WidgetTraceTip)
    self.LeftScript = UIHelper.GetBindScript(self.WidgetAniLeft)
    -- WidgetAniSidePanel_Others
    self.CraftScript = UIHelper.GetBindScript(self.WidgetAnchorSidePanel_Gather)
    self.TagScript = UIHelper.GetBindScript(self.WidgetAnchorSidePanel_Custom)
    self.CloseScript = UIHelper.GetBindScript(self.BtnCloseLeftPanel)
    self.WidgetNpcScript = UIHelper.GetBindScript(self.WidgetNpc)
    self.WidgetPQScript = UIHelper.GetBindScript(self.WidgetPQ)
    self.WidgetTeamInfoScript = UIHelper.GetBindScript(self.WidgetTeammate_single)
    self.WidgetCampColorScript = UIHelper.GetBindScript(self.WidgetCampColor)

end

function UIMiddleMap:CheckLevel(szShowLevel)
    local player = GetClientPlayer()
    local nLevel = player.nLevel
    local tbShowLevel = string.split(szShowLevel, "~")
    local nMin = tonumber(tbShowLevel[1])
    local nMax
    if tbShowLevel[2] == "max" then
        nMax = -1
    else
        nMax = tonumber(tbShowLevel[2])
    end
    return nLevel >= nMin and (nMax == -1 or nLevel < nMax)
end

function UIMiddleMap:CheckOpened(nTrafficID)
    return RoadTrackIsCityOpen(nTrafficID)
end

function UIMiddleMap:TraceNode(szName, nMapID, point, szFrame)
    MapMgr.SetTracePoint(szName, nMapID, point, nil, szFrame)
    Event.Dispatch("ON_MIDDLE_MAP_MARK_UNCHECK")
end


--[[
tbTraffic = {
    nTrafficID = ?
    nFinishCityID = ?
}
tbDisplay = {
    bHideTraceTip = false,
    szMessage = nil,
}
]]--


function UIMiddleMap:OnEnter(nMapID, nIndex, tbInfo, tbTraffic, tbDisplay, bTrafficNodeSkill)
    self.TouchComponent = require("Lua/UI/Map/Component/UIMapTouchComponent"):CreateInstance()
    self.PosComponent = require("Lua/UI/Map/Component/UIPositionComponent"):CreateInstance()
    self.TouchComponent:Init(self.ImgMap)

    -- 设置上下可拖拽范围，上下有空白空隙上34，下31，预制里也做了相应修改 （ImgMap的上下挂靠也改了）
    local nodeW , nodeH =  UIHelper.GetContentSize(self.ImgMap)
    self.TouchComponent:SetMoveRegion(-nodeW / 2, nodeW / 2, -nodeH / 2 + 31, nodeH / 2 - 34)

    self.TouchComponent:SetRangeWidget(self.ImgMapMask)
    self.TouchComponent:SetScaleLimit(MIN_SCALE, MAX_SCALE)
    self.TouchComponent:RegisterPosEvent(function(x, y)
        self.PosComponent:Update(self.ImgMap)
        Event.Dispatch("ON_MIDDLE_MAP_SCALE_CHANGE")
    end)
    self.TouchComponent:RegisterScaleEvent(function(nScale)
        self:UpdateSliderPercent()
        self:RefreshExploreIcon()
    end)

    MapMgr.InitCraft()

    -- 初始化探索节点分帧加载状态管理
    self.tbExploreNodesToCreate = {}     -- 待创建的探索节点队列
    self.nExploreLoadingPerFrame = 10   -- 每帧创建的探索节点数量
    self.bIsLoadingExploreNodes = false
    self.nExploreTotalCount = 0         -- 总节点数（用于进度显示）
    self.nExploreLoadedCount = 0        -- 已加载节点数

    if Platform.IsIos() then
        self.nExploreLoadingPerFrame = 5
    end

    self.tbInfo = tbInfo
    if tbInfo then
        self.bIllegalLevel = not self:CheckLevel(tbInfo.szShowLevel)
        self.bIllegalVisit = not self:CheckOpened(tbInfo.nTrafficID)
    end
    tbDisplay = tbDisplay or {}
    bTrafficNodeSkill = bTrafficNodeSkill or false
    self.tbNodeScripts = {}

    self:RegisterEvent()
    self:InitSidePanel()

    if tbTraffic then
        self:UpdateTraffic(tbTraffic)
    end

    if tbDisplay.szMessage then
        UIHelper.SetString(self.LabelTraceTip, tbDisplay.szMessage)
        UIHelper.SetVisible(self.WidgetTakTip, true)
    else
        UIHelper.SetVisible(self.WidgetTakTip, false)
    end
    self.tbDisplay = tbDisplay
    self.bTrafficNodeSkill = bTrafficNodeSkill
    if bTrafficNodeSkill then
        MapMgr.ClearCraftInfo()
    end

    if not nMapID or not nIndex then
        local player = GetClientPlayer()
        local scene = player.GetScene()
        nMapID = scene.dwMapID

        self.nMapID = nMapID
        self.LeftScript:UpdateInfo(self.nMapID)
        PostThreadCall(OnShowMap, self, "GetRegionInfoByGameWorldPos", nMapID, player.nX, player.nY, player.nZ)
    else
        self.nMapID = nMapID
        self.LeftScript:UpdateInfo(self.nMapID)
        OnShowMap(self, nIndex, true)
    end

    self.TipScript:UpdateShowMap(self.nMapID)
    if tbDisplay.bHideTraceTip then
        self.TipScript:Hide()
    end

    self.nUpdateTimer = Timer.AddCycle(self, 0.1, function()
        self:Update()
    end)

    self:UpdateMapQueueInfo()

    self:InitDebugFly()

    OnCheckAddAchievement(1004, "Open_Middle_Map")

    Timer.AddCycle(self, 1, function ()
        self:UpdateCircleSFX()
    end)
    if SelfieData.IsInStudioMap() then
        UIHelper.SetCanSelect(self.BtnShuntFilter, false)
    end
end

function UIMiddleMap:UpdateInfo(nMapID, nIndex)
    self.nMapID = nMapID
    OnShowMap(self, nIndex, true)
    self.TipScript:UpdateShowMap(self.nMapID)
    self.LeftScript:UpdateInfo(self.nMapID)
end

function UIMiddleMap:UpdateTraffic(tbTraffic)
    self.bTraffic = true
    self.nStartTrafficID = tbTraffic.nTrafficID
    self.nFinishCityID = tbTraffic.nFinishCityID
end

--神行时不显示标记
function UIMiddleMap:UpdateCraft()
    -- local bShow = Storage.MiddleMapData.bShowCraft
    -- if bNotShowCraft then bShow = false end
    -- for _, v in ipairs(self.tbDisplayWidgets) do
    --     UIHelper.SetVisible(v, not bShow)
    -- end

    -- UIHelper.SetVisible(self.WidgetCraft, not self.bTrafficNodeSkill)

end

function UIMiddleMap:UpdatePosition()
    local player = GetClientPlayer()

    local nRotation = MapMgr.GetPlayerRotation(player)
    self.WidgetLocation:setRotation(nRotation)

    nRotation = MapMgr.GetCameraRotation() - nRotation
    self.ImgSight:setRotation(nRotation)

    local imgX, imgY = self.PosComponent:LogicPosToMapPos(player.nX, player.nY)
    UIHelper.SetWorldPosition(self.WidgetLocation, imgX, imgY)

    UIHelper.SetVisible(self.WidgetLocation, self:IsInMapView(player.nX, player.nY) and self:IsShowPlayerPos(player.nX, player.nY))
end

function UIMiddleMap:IsShowPlayerPos(nX, nY)
    if self.nLeftShowX == 0 and self.nRightShowX == 0 and self.nLeftShowY == 0 and self.nRightShowY == 0 then
		return true
	end

	if nX < self.nLeftShowX or nX > self.nRightShowX or nY > self.nLeftShowY or nY < self.nRightShowY then
		return false
	end
	return true
end

function UIMiddleMap:HidePlayerWhenScaleChanged()
    UIHelper.SetOpacity(self.WidgetLocation, 0)
    Timer.DelTimer(self, self.nLocationAlphaTimerID)
    self.nLocationAlphaTimerID = Timer.Add(self, 0.3, function()
        UIHelper.SetOpacity(self.WidgetLocation, 255)
    end)
end

function UIMiddleMap:ShowTeammatePos(dwMapID, nCopyIndex)
	local hPlayer = g_pClientPlayer
	if not hPlayer then
		return
	end

	local hScene  = hPlayer.GetScene()
	if not hScene then
		return
	end

	if hScene.dwMapID == dwMapID and hScene.nCopyIndex ~= nCopyIndex then
		return false
	end
	return true
end

function UIMiddleMap:UpdateTeammate(player)
    local tbTeammate = {}
    self.tbNodeScripts["Teammate"] = self.tbNodeScripts["Teammate"] or {}
    TeamData.Generator(function(dwID, tMemberInfo)
        if dwID == player.dwID or not tMemberInfo.bIsOnLine or tMemberInfo.dwMapID ~= self.nMapID or not self:ShowTeammatePos(tMemberInfo.dwMapID, tMemberInfo.nMapCopyIndex) then
            return
        end
        tbTeammate[dwID] = true
        local absX, absY = self.PosComponent:LogicPosToMapPos(tMemberInfo.nPosX, tMemberInfo.nPosY)
        if not self.tbNodeScripts["Teammate"][dwID] then
            local script = self:CreateMapNodeFromLogicPos(self.WidgetTeammate, tMemberInfo.nPosX, tMemberInfo.nPosY)
            script.bOpenPanel = true
            script:SetTeammate(tMemberInfo.szName)
            script.fnSelected = function(bSelected)
                self:OnSelectSignButton(script, bSelected)
            end
            script.fnDetailPanel = function()
                self:ShowWidgetTeamInfo(UIHelper.GBKToUTF8(tMemberInfo.szName), absX, absY, TEAMMATE_FRAME.ICON)
            end
            self.tbNodeScripts["Teammate"][dwID] = script
        end
        local pos = self.WidgetTeammate:convertToNodeSpace({x = absX, y = absY})
        self.tbNodeScripts["Teammate"][dwID]:SetPosition(pos.x, pos.y, tMemberInfo.nPosX, tMemberInfo.nPosY)
    end)

    for dwID, node in pairs(self.tbNodeScripts["Teammate"]) do
        if not tbTeammate[dwID] then
            -- node._rootNode:removeFromParent(true)
            self:DeleteMarkNode(node)
            self.tbNodeScripts["Teammate"][dwID] = nil
        end
    end
end

function UIMiddleMap:RemoveAllTeammate()
    if not self.tbNodeScripts or not self.tbNodeScripts["Teammate"] then return end
    for dwID, node in pairs(self.tbNodeScripts["Teammate"]) do
        -- node._rootNode:removeFromParent(true)
        self:DeleteMarkNode(node)
        self.tbNodeScripts["Teammate"][dwID] = nil
    end
end

function UIMiddleMap:CanQueryWanted(player)
    local nMapID = player.GetMapID()
	if nMapID ~= self.nMapID then
		return false
	end

    if MapMgr.IsInGFMapInGFTime(nMapID) then
        return false
    end

	return true
end

function UIMiddleMap:UpdateWanted()
    local player = g_pClientPlayer
    local nCurrentTime = GetCurrentTime()
    local nTime = nCurrentTime - (self.nStartWantedTime or 0)
    if nTime > QUERY_WANTED_INTERVAL then
		local bCanQuery = self:CanQueryWanted(player)
		if bCanQuery then
			QueryWantedPlayerPosition()
		else
			self:UpdateWantedNodes({})
		end
        self.nStartWantedTime = nCurrentTime
    end
end

function UIMiddleMap:QueryKiller()
    local player = g_pClientPlayer
    local nCurrentTime = GetCurrentTime()

    if not self.nLastQueryKiller or nCurrentTime - self.nLastQueryKiller > QUERY_KILLER_CD then
        local bCanQuery = self:CanQueryWanted(player)
        if bCanQuery then
            RemoteCallToServer("On_Camp_UpdateKiller")
        else
            self:UpdateKillerPos()
        end
        self.nLastQueryKiller = nCurrentTime
    end
end

--更新击杀者的位置
function UIMiddleMap:UpdateKillerPos(tbKillerList)
    if not tbKillerList then tbKillerList = self.tbKillerList end
    if tbKillerList == nil then
        return
    end
    self.tbKillerList = tbKillerList
    if not self.tbNodeScripts then self.tbNodeScripts = {} end
    self.tbNodeScripts["KillerPos"] = {}
    UIHelper.RemoveAllChildren(self.WidgetKiller)
    for nIndex, tbPos in pairs(tbKillerList) do
        local script = self:CreateMapNodeFromLogicPos(self.WidgetKiller, tbPos.x, tbPos.y)
        if script then
            script:SetKillerPos(tbPos)
            script.fnSelected = function(bSelected)
                self:OnSelectSignButton(script, bSelected)
            end
            script.fnDetailPanel = function()
                local tbNpcInfo = script:GetNPCInfo()
                local nX, nY = UIHelper.ConvertToWorldSpace(script._rootNode:getParent(), script.nX, script.nY)
                self:ShowWidgetNpc(tbNpcInfo, nX, nY)
            end
            table.insert(self.tbNodeScripts["KillerPos"], script)
        end
    end

end

function UIMiddleMap:GetQuestTracingPoint()
    local tbQuest = QuestData.GetTracingQuestIDList()
    if not tbQuest or #tbQuest <= 0 then
        return
    end
    for _, nQuestID in ipairs(tbQuest) do
        local nMapID, tbPoint = QuestData.GetQuestMapIDAndPoints(nQuestID)
        if nMapID == self.nMapID and tbPoint then
            return nQuestID, tbPoint
        end
    end
end

function UIMiddleMap:UpdateQuestTrace()
    local nQuestID, tbPoint = self:GetQuestTracingPoint()

    -- if nQuestID == self.nTracingQuestID then
    --     return
    -- end

    if tbPoint and self.tbDisplay.szMessage then
        local nX, nY, _ = unpack(tbPoint)
        local x, y = self.PosComponent:LogicPosToMapPos(nX, nY)
        UIHelper.SetWorldPosition(self.WidgetTraceQuest, x, y)
        UIHelper.SetVisible(self.WidgetTraceQuest, self:IsInMapView(nX, nY))
    else
        UIHelper.SetVisible(self.WidgetTraceQuest, false)
    end


    self.nTracingQuestID = nQuestID
end

function UIMiddleMap:UpdateDeathNode()

    local script
    self.tbNodeScripts['Death'] = self.tbNodeScripts['Death'] or {}
    if not self.tbNodeScripts['Death'][1] then
        script = self:CreateMapNodeFromLogicPos(self.WidgetSign, 0, 0)
        script:SetDeath()
        script.fnSelected = function(bSelected)
            self:OnSelectSignButton(script, bSelected)
        end
        script.fnDetailPanel = function()
            local tbNpcInfo = script:GetNPCInfo()
            if not script.bOpenPanel and tbNpcInfo then
                local nX, nY = UIHelper.ConvertToWorldSpace(script._rootNode:getParent(), script.nX, script.nY)
                self:ShowWidgetNpc(tbNpcInfo, nX, nY)
            end
        end
        self.tbNodeScripts['Death'][1] = script
    end
    script = self.tbNodeScripts['Death'][1]
    local tbPoint = MapMgr.GetDeathPosition()
    if MapMgr.IsCurrentMap(self.nMapID) and tbPoint then
        local nX, nY, _ = unpack(tbPoint)
        local absX, absY = self.PosComponent:LogicPosToMapPos(nX, nY)
        local pos = self.WidgetSign:convertToNodeSpace({x = absX, y = absY})
        script:SetPosition(pos.x, pos.y, nX, nY)
        script:SetVisible(true)
    else
        script:SetVisible(false)
    end
end

function UIMiddleMap:RemoveAllBoardNotDraw()
    if self.tbNodeScripts["BoardCar"] then
        for nIndex, script in ipairs(self.tbNodeScripts["BoardCar"]) do
            self:DeleteMarkNode(script)
        end
    end

    if self.tbNodeScripts["BoardNPC"] then
        for nIndex, script in ipairs(self.tbNodeScripts["BoardNPC"]) do
            self:DeleteMarkNode(script)
        end
    end

    if self.tbNodeScripts["BoardNPCBeAttacked"] then
        for nIndex, script in ipairs(self.tbNodeScripts["BoardNPCBeAttacked"]) do
            self:DeleteMarkNode(script)
        end
    end
    self.tbNodeScripts["BoardCar"] = {}
    self.tbNodeScripts["BoardNPC"] = {}
    self.tbNodeScripts["BoardNPCBeAttacked"] = {}
end

function UIMiddleMap:UpdateBoardNotDraw()
    self:RemoveAllBoardNotDraw()
    self:UpdateCar()
    self:UpdateAllNPC()
    self:UpdateNPCBeAttacked()
end

function UIMiddleMap:UpdateCar()
    local tbSyncBoardInfo = MapMgr.GetSyncBoardInfo()
    if table.is_empty(tbSyncBoardInfo) then return end
    local tbCar = tbSyncBoardInfo.tCar
    for nIndex, tbCarInfo in ipairs(tbCar) do
        local script = self.tbNodeScripts["BoardCar"] and self.tbNodeScripts["BoardCar"][nIndex]
        if script then
            self:UpdateBoardCar(script, tbCarInfo)
        else
            self:AddBoardCarNode(tbCarInfo)
        end
    end
end

function UIMiddleMap:AddBoardCarNode(tbCarInfo)
    local script = self:CreateMapNodeFromLogicPos(self.WidgetMapSyncBoard, tbCarInfo.nX, tbCarInfo.nY)
    self:UpdateBoardCar(script, tbCarInfo)
    table.insert(self.tbNodeScripts["BoardCar"], script)
end

function UIMiddleMap:UpdateBoardCar(script, tbCarInfo)
    script:SetCar(tbCarInfo)
    script.fnSelected = function(bSelected)
        self:OnSelectSignButton(script, bSelected)
    end

    script.fnDetailPanel = function()
        local tbNpcInfo = script:GetNPCInfo()
        if not script.bOpenPanel and tbNpcInfo then
            local nX, nY = UIHelper.ConvertToWorldSpace(script._rootNode:getParent(), script.nX, script.nY)
            self:ShowWidgetNpc(tbNpcInfo, nX, nY)
        end
    end
end

function UIMiddleMap:UpdateAllNPC()
    local tbSyncBoardInfo = MapMgr.GetSyncBoardInfo()
    if table.is_empty(tbSyncBoardInfo) then return end
    local tbNPC = tbSyncBoardInfo.tNPC
    for nIndex, tbNPCInfo in pairs(tbNPC) do
        if tbNPCInfo.nX and tbNPCInfo.nY then
            local script = self.tbNodeScripts["BoardNPC"] and self.tbNodeScripts["BoardNPC"][nIndex]
            if script then
                self:UpdateBoardNPC(script, tbNPCInfo)
            else
                self:AddBoardNPCNode(tbNPCInfo)
            end
        end
    end
    self:FixNPCPos()
end

function UIMiddleMap:FixNPCPos()
    if not self.tbNodeScripts or not self.tbNodeScripts["BoardNPC"] then return end
    local tbScriptList = self.tbNodeScripts["BoardNPC"]
    for nIndex = 1, #tbScriptList do
        for index = nIndex + 1, #tbScriptList do
            local scriptA = tbScriptList[nIndex]
            local scriptB = tbScriptList[index]
            local nXA, nYA = scriptA:GetPosition()
            local nXB, nYB = scriptB:GetPosition()
            if GetLogicDist({nXA, nYA, 0}, {nXB, nYB, 0}) < ICON_NEAR_OFFSET then--改为以世界坐标计算
                self:MoveNode(scriptA, -ICON_AWAY_OFFSET, 0)
                self:MoveNode(scriptB, ICON_AWAY_OFFSET, 0)
            end
        end
    end
end

function UIMiddleMap:MoveNode(script, nOffSetX, nOffSetY)
    if not script.GetPosition then return end
    local nX, nY = script:GetPosition()
    nX = nX + nOffSetX
    nY = nY + nOffSetY

    local nLogicX, nLogicY = self.PosComponent:MapPosToLogicPos(nX, nY)
    local parent = UIHelper.GetParent(script._rootNode)
    local pos = parent:convertToNodeSpace({x = nX, y = nY})
    script:SetPosition(pos.x, pos.y, nLogicX, nLogicY)
    return script
end

function UIMiddleMap:AddBoardNPCNode(tbNPCInfo)
    local script = self:CreateMapNodeFromLogicPos(self.WidgetMapSyncBoard, tbNPCInfo.nX, tbNPCInfo.nY)
    self:UpdateBoardNPC(script, tbNPCInfo)

    if not self.tbNodeScripts["BoardNPC"] then self.tbNodeScripts["BoardNPC"] = {} end
    table.insert(self.tbNodeScripts["BoardNPC"], script)
end

function UIMiddleMap:UpdateBoardNPC(script, tbNPCInfo)
    script:SetBoardNPC(tbNPCInfo)
    script.fnSelected = function(bSelected)
        self:OnSelectSignButton(script, bSelected)
    end

    script.fnDetailPanel = function()
        local tbNpcInfo = script:GetNPCInfo()
        if not script.bOpenPanel and tbNpcInfo then
            local nX, nY = UIHelper.ConvertToWorldSpace(script._rootNode:getParent(), script.nX, script.nY)
            self:ShowWidgetNpc(tbNpcInfo, nX, nY)
        end
    end
end

function UIMiddleMap:UpdateNPCBeAttacked()
    local tbSyncBoardInfo    = MapMgr.GetSyncBoardInfo()
    if table.is_empty(tbSyncBoardInfo) then return end
    local tbAllNPCBeAttacked = tbSyncBoardInfo.tNPCBeAttacked
    for nIndex, tbNPCBeAttacked in ipairs(tbAllNPCBeAttacked) do
        local script = self.tbNodeScripts["BoardNPCBeAttacked"] and self.tbNodeScripts["BoardNPCBeAttacked"][nIndex]
        if script then
            self:UpdateNPCBeAttaked(script, tbNPCBeAttacked)
        else
            self:AddNPCBeAttacked(tbNPCBeAttacked)
        end
    end
end

function UIMiddleMap:AddNPCBeAttacked(tbNPCBeAttacked)
    local script = self:CreateMapNodeFromLogicPos(self.WidgetMapSyncBoard, tbNPCBeAttacked.nX, tbNPCBeAttacked.nY, true)
    if not script then return end
    self:UpdateNPCBeAttaked(script, tbNPCBeAttacked)
    self.tbNodeScripts["BoardNPCBeAttacked"] = self.tbNodeScripts["BoardNPCBeAttacked"] or {}
    table.insert(self.tbNodeScripts["BoardNPCBeAttacked"], script)
end

function UIMiddleMap:UpdateNPCBeAttaked(script, tbNPCBeAttacked)
    script:SetNpcBeAttacked(tbNPCBeAttacked)

end

function UIMiddleMap:RemoveAllBoardDraw()
    if self.tbNodeScripts["BoardFlag"] then
        for index, script in ipairs(self.tbNodeScripts["BoardFlag"]) do
            -- script.fnDelete()
            UIHelper.RemoveFromParent(script._rootNode, true)
        end
    end

    if self.tbNodeScripts["BoardArrow"] then
        for index, script in ipairs(self.tbNodeScripts["BoardArrow"]) do
            -- script.fnDelete()
            UIHelper.RemoveFromParent(script._rootNode, true)
        end
    end
    self.tbNodeScripts["BoardFlag"] = {}
    self.tbNodeScripts["BoardArrow"] = {}

end

function UIMiddleMap:CreateBoardNode(nX, nY)
    if not MapMgr.IsPlayerCanDraw() then return false end
    nX, nY = self.PosComponent:MapPosToLogicPos(nX, nY)
    if self:IsArrowMark() and self:CheckCanDrawArrow() then
        local tbInfo = {nX = nX, nY = nY, nEndX = nX, nEndY = nY, nType = self.nBoardMarkType}
        self:AddArrowNode(tbInfo)
        self:AddArrowInfo(tbInfo)
        self:UpdateArrowNum()
        return true
    elseif self:IsGatherMark() then
        self:AddGatherNode(nX, nY)
        if nX >= 0 and nY >= 0 then
            RemoteCallToServer("On_Camp_SetCampSimplePos", nX, nY, CampOBBaseData.GetCampOfBoardInfo())
        end
        return true
    elseif self:IsFlagMark() and self:CheckCanDrawFlag() then
        local tbInfo = {nX = nX, nY = nY, nType = self.nBoardMarkType}
        self:AddFlagNode(tbInfo)
        self:AddBoardTagInfo(tbInfo)
        self:UpdateFlagNum()
        return true
    end
    return false
end

function UIMiddleMap:CheckCanDrawArrow()
    local nCount = self:GetArrowNum()
    if nCount >= COMMAND_BOARD.MAX_ARROW then
        TipsHelper.ShowNormalTip(FormatString(g_tStrings.STR_BEYOND_ARROW_LIMIT, COMMAND_BOARD.MAX_ARROW))
    end
    return nCount < COMMAND_BOARD.MAX_ARROW
end

function UIMiddleMap:CheckCanDrawFlag()
    local nCount = self:GetFlagNum()
    if nCount >= COMMAND_BOARD.MAX_MARK then
        TipsHelper.ShowNormalTip(FormatString(g_tStrings.STR_BEYOND_MARK_LIMIT, COMMAND_BOARD.MAX_MARK))
    end
    return nCount < COMMAND_BOARD.MAX_MARK
end

function UIMiddleMap:UpdateArrowNum()
    local nCount = self:GetArrowNum()
    UIHelper.SetString(self.LabelArrowNum, tostring(nCount) .. "/".. tostring(COMMAND_BOARD.MAX_ARROW))
end

function UIMiddleMap:UpdateFlagNum()
    local nCount = self:GetFlagNum()
    UIHelper.SetString(self.LabelFlagNum, tostring(nCount) .. "/".. tostring(COMMAND_BOARD.MAX_MARK))
end

function UIMiddleMap:UpdateGatherNum()
    local nCount = 0
    if self.tbNodeScripts and self.tbNodeScripts["Gather"] then
        nCount = #self.tbNodeScripts["Gather"]
    end
    UIHelper.SetString(self.LabelGatherNum, tostring(nCount) .. "/".. tostring(COMMAND_BOARD.MAX_GATHER))
end

function UIMiddleMap:UpdateArrowRotationAndLenth(nX, nY)
    local nLogicX, nLogicY = self.PosComponent:MapPosToLogicPos(nX, nY)
    if not self:IsInMapView(nLogicX, nLogicY) then return end
    nX, nY = UIHelper.ConvertToNodeSpace(self.WidgetMapSyncBoard, nX, nY)
    local nLen = #self.tbNodeScripts["BoardArrow"]
    local script = self.tbNodeScripts["BoardArrow"][nLen]
    local nLenInfo = #self.tbArrowInfoList
    local tbInfo = self.tbArrowInfoList[nLenInfo]
    tbInfo.nEndX = nLogicX
    tbInfo.nEndY = nLogicY
    if script then
        script:UpdateArrowRotationAndLenth(nX, nY, nLogicX, nLogicY)
    end
end

function UIMiddleMap:UpdateBoardInfo()
    if not CommandBaseData.IsCommandModeCanBeEntered() then return end
    -- if CommandBaseData.IsBreatheCallOpened() and (self.nMapID == g_pClientPlayer.GetMapID()) then
    self:UpdateBoardDraw()
    self:UpdateBoardGather()
    self:UpdateBoardNotDraw()
    -- end
end

function UIMiddleMap:UpdateBoardGather()
    local tbSyncBoardInfo = MapMgr.GetSyncBoardInfo()
    if table.is_empty(tbSyncBoardInfo) then return end
    local tbGather = tbSyncBoardInfo and tbSyncBoardInfo.tGather
    local nX = (tbGather and #tbGather > 0) and tbGather[1].nX or nil
    local nY = (tbGather and #tbGather > 0) and tbGather[1].nY or nil

    self:UpdateBoardGatherPos(nX, nY, CampOBBaseData.GetCampOfBoardInfo())
end

function UIMiddleMap:UpdateBoardGatherPos(nX, nY, nCamp)
    if nCamp ~= CampOBBaseData.GetCampOfBoardInfo() then return end
    self:AddGatherNode(nX, nY)
end

function UIMiddleMap:RemoveGatherNode()
    if not self.tbNodeScripts then return end
    local tbScript = self.tbNodeScripts["Gather"]
    if tbScript and #tbScript > 0 then
        local script = table.remove(tbScript, 1)
        UIHelper.RemoveFromParent(script._rootNode, true)
        -- self:DeleteMarkNode(script)
    end
    self:UpdateGatherNum()
end

function UIMiddleMap:AddGatherNode(nX, nY)

    self:RemoveGatherNode()

    if nX and nY then
        local script = self:CreateMapNodeFromLogicPos(self.WidgetMapSyncBoard, nX, nY)
        script.fnSelected = function(bSelect)
            if bSelect then
                local nWorldX, nWorldY = self.PosComponent:LogicPosToMapPos(nX, nY)
                self:ShowWidgetPQ(script, nWorldX, nWorldY)
            end
        end
        script:SetGather(nX, nY)
        if not self.tbNodeScripts["Gather"] then self.tbNodeScripts["Gather"] = {} end
        table.insert(self.tbNodeScripts["Gather"], script)

        script.fnDelete = function()
            RemoteCallToServer("On_Camp_DelCampSimplePos", CampOBBaseData.GetCampOfBoardInfo())
        end

        script.fnMove = function(nX, nY)
            script.fnDelete()
            RemoteCallToServer("On_Camp_SetCampSimplePos", nX, nY, CampOBBaseData.GetCampOfBoardInfo())
        end
        self:UpdateGatherNum()
    end
end

function UIMiddleMap:UpdateBoardDraw()
    self:RemoveAllBoardDraw()

    if self.tbBoardTagInfoList then
        for nIndex, tbFlagInfo in ipairs(self.tbBoardTagInfoList) do
            self:AddFlagNode(tbFlagInfo)
        end
    end

    if self.tbArrowInfoList then
        for nIndex, tbArrowInfo in ipairs(self.tbArrowInfoList) do
            self:AddArrowNode(tbArrowInfo)
        end
    end

    local tbSyncBoardInfo = MapMgr.GetSyncBoardInfo()
    if table.is_empty(tbSyncBoardInfo) then return end

    local tbAllflag = tbSyncBoardInfo.tFlag
    local tbAllArrow = tbSyncBoardInfo.tArrow

    for nIndex, tbFlagInfo in ipairs(tbAllflag) do
        self:AddFlagNode(tbFlagInfo)
    end

    for nIndex, tbArrowInfo in ipairs(tbAllArrow) do
        self:AddArrowNode(tbArrowInfo)
    end

    self:UpdateFlagNum()
    self:UpdateArrowNum()
end

function UIMiddleMap:OnBoardFlagRemove(script, tbInfo)
    for nIndex, scriptView in ipairs(self.tbNodeScripts["BoardFlag"]) do
        if scriptView == script then
            table.remove(self.tbNodeScripts["BoardFlag"], nIndex)
            break
        end
    end
    if self.tbBoardTagInfoList then
        for nIndex, tbFlagInfo in ipairs(self.tbBoardTagInfoList) do
            if tbInfo == tbFlagInfo then
                table.remove(self.tbBoardTagInfoList, nIndex)
                break
            end
        end
    end

    self:UpdateFlagNum()
end

function UIMiddleMap:AddFlagNode(tbFlagInfo)
    local script = self:CreateMapNodeFromLogicPos(self.WidgetMapSyncBoard, tbFlagInfo.nX, tbFlagInfo.nY, true)
    if not script then return end
    script:SetFlag(tbFlagInfo)

    script.fnSelected = function(bSelect)
        if bSelect then
            local nWorldX, nWorldY = self.PosComponent:LogicPosToMapPos(tbFlagInfo.nX, tbFlagInfo.nY)
            self:ShowWidgetPQ(script, nWorldX, nWorldY)
        end
    end

    table.insert(self.tbNodeScripts["BoardFlag"], script)

    script.fnDelete = function()
        self:OnBoardFlagRemove(script, tbFlagInfo)
        UIHelper.RemoveFromParent(script._rootNode, true)
    end

    script.fnMove = function(nX, nY)
        tbFlagInfo.nX = nX
        tbFlagInfo.nY = nY
        self:AddFlagNode(tbFlagInfo)
        script.fnDelete()
    end
end

function UIMiddleMap:OnRemoveArrowNode(script, tbInfo)
    for nIndex, scriptView in ipairs(self.tbNodeScripts["BoardArrow"]) do
        if scriptView == script then
            table.remove(self.tbNodeScripts["BoardArrow"], nIndex)
            break
        end
    end

    if self.tbArrowInfoList then
        for nIndex, tbArrowInfo in ipairs(self.tbArrowInfoList) do
            if tbInfo == tbArrowInfo then
                table.remove(self.tbArrowInfoList, nIndex)
                break
            end
        end
    end

    self:UpdateArrowNum()
end

function UIMiddleMap:AddArrowNode(tbArrowInfo)
    local script = self:CreateMapNodeFromLogicPos(self.WidgetMapSyncBoard, tbArrowInfo.nX, tbArrowInfo.nY, false, PREFAB_ID.WidgetMapPQ_Arrow)

    local nWorldStartX, nWorldStartY = self.PosComponent:LogicPosToMapPos(tbArrowInfo.nX, tbArrowInfo.nY)
    local nStartX, nStartY = UIHelper.ConvertToNodeSpace(self.WidgetMapSyncBoard, nWorldStartX, nWorldStartY)

    local nWorldEndX, nWorldEndY = self.PosComponent:LogicPosToMapPos(tbArrowInfo.nEndX, tbArrowInfo.nEndY)
    local nEndX, nEndY = UIHelper.ConvertToNodeSpace(self.WidgetMapSyncBoard, nWorldEndX, nWorldEndY)

    script:SetArrow(tbArrowInfo, nStartX, nStartY, nEndX, nEndY, tbArrowInfo.nX, tbArrowInfo.nY)

    script.fnSelected = function()
        local tbArrowInfo = script:GetArrowInfo()
        local nWorldEndX, nWorldEndY = self.PosComponent:LogicPosToMapPos(tbArrowInfo.nImageWidth, tbArrowInfo.nRotateDegree)
        local nWorldX, nWorldY = (nWorldStartX + nWorldEndX) / 2, (nWorldStartY + nWorldEndY) / 2

        self:ShowWidgetPQ(script, nWorldX, nWorldY)
    end

    table.insert(self.tbNodeScripts["BoardArrow"], script)

    script.fnDelete = function()
        self:OnRemoveArrowNode(script, tbArrowInfo)
        UIHelper.RemoveFromParent(script._rootNode, true)
        -- self:DeleteMarkNode(script)
    end
end

function UIMiddleMap:UpdateArrowPos(tbArrowInfo, script)

    local nLogicX, nLogicY = tbArrowInfo.nX, tbArrowInfo.nY
    local absX, absY = self.PosComponent:LogicPosToMapPos(nLogicX, nLogicY)
    local pos = script._rootNode:getParent():convertToNodeSpace({x = absX, y = absY})
    script:SetPosition(pos.x, pos.y, nLogicX, nLogicY)

    local nWorldStartX, nWorldStartY = self.PosComponent:LogicPosToMapPos(tbArrowInfo.nX, tbArrowInfo.nY)
    local nStartX, nStartY = UIHelper.ConvertToNodeSpace(self.WidgetMapSyncBoard, nWorldStartX, nWorldStartY)

    local nWorldEndX, nWorldEndY = self.PosComponent:LogicPosToMapPos(tbArrowInfo.nEndX, tbArrowInfo.nEndY)
    local nEndX, nEndY = UIHelper.ConvertToNodeSpace(self.WidgetMapSyncBoard, nWorldEndX, nWorldEndY)

    script:SetArrow(tbArrowInfo, nStartX, nStartY, nEndX, nEndY, nLogicX, nLogicY)
end

function UIMiddleMap:GetAllBoardInfo()
    local tbBoradInfo  = {}
    tbBoradInfo.tFlag  = {}
    tbBoradInfo.tArrow = {}
    local nArrowCount , nFlagCount = 0, 0
    if self.tbNodeScripts["BoardFlag"] then
        for nIndex, script in ipairs(self.tbNodeScripts["BoardFlag"]) do
            table.insert(tbBoradInfo.tFlag, script:GetBoardInfo())
            nFlagCount = nFlagCount + 1
        end
    end

    if self.tbNodeScripts["BoardArrow"] then
        for nIndex, script in ipairs(self.tbNodeScripts["BoardArrow"]) do
            table.insert(tbBoradInfo.tArrow, script:GetArrowInfo())
            nArrowCount = nArrowCount + 1
        end
    end
    LOG.INFO("------GetAllBoardInfo  %s %s----", tostring(nFlagCount), tostring(nArrowCount))
    return tbBoradInfo
end

function UIMiddleMap:Update()
    if not self.initialized then
        return
    end

    local player = GetClientPlayer()

    if self:IsCurrentMap() then
        self:UpdatePosition()
    end

    self:UpdateTeammate(player)
    self:UpdateWanted()
    self:QueryKiller()
    -- self:UpdateQuestTrace()
    self:UpdateDeathNode()
    self:UpdateTeamSignPost()

    -- 处理探索节点的分帧加载
    self:ProcessExploreNodesAsync()
end

function UIMiddleMap:OnExit()
    if self.nUpdateTimer then
        Timer.DelTimer(self, self.nUpdateTimer)
        self.nUpdateTimer = nil
    end

    if self.nApplyTimer then
        Timer.DelTimer(self, self.nApplyTimer)
        self.nApplyTimer = nil
    end

    self:UnRegisterEvent()
end

function UIMiddleMap:ShowNeighborhoodAndAutoWalk(tNeiborghood, nWorldX, nWorldY, bShowAutoWalk)
    UIHelper.SetVisible(self.WidgetSpecificSelection, true)
    local nCount = #tNeiborghood
    local bShowNeibor = nCount > 1 or (bShowAutoWalk and nCount > 0)

    local bRight = true
    if bShowAutoWalk then
        bRight = self:ShowAutoWalk(nWorldX, nWorldY)
    end
    if bShowNeibor then
        self:ShowNeighborhood(tNeiborghood, nWorldX, nWorldY, not bRight)
    end


    UIHelper.SetVisible(self.LayoutXuanzeshangren, bShowNeibor and nCount <= 6)
    UIHelper.SetVisible(self.ScrollViewPlayerSelect, bShowNeibor and nCount > 6)
    UIHelper.SetVisible(self.ImgScrollView, bShowNeibor and nCount > 6)

    UIHelper.SetVisible(self.WidgetTeaceWalkLeft, bShowAutoWalk and not bRight)
    UIHelper.SetVisible(self.WidgetTeaceWalkRight, bShowAutoWalk and bRight)

    self:CloseWidgetPQ()
    self:CloseTeamInfo()
end

function UIMiddleMap:ShowNeighborhood(tNeiborghood, nWorldX, nWorldY, bRight)
    UIHelper.RemoveAllChildren(self.ScrollViewPlayerSelect)
    UIHelper.RemoveAllChildren(self.LayoutXuanzeshangren)

    self.tbNeiborhood = {}
    local nCount = #tNeiborghood
    local parent = nCount > 6 and self.ScrollViewPlayerSelect or self.LayoutXuanzeshangren
    for i, v in ipairs(tNeiborghood) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetMiddleSignSelect, parent)
        script:UpdateInfo(v)
        script.fnSelected = function()
            self:CloseNeiborAndAutoWalk()
        end
        table.insert(self.tbNeiborhood, script)
    end
    UIHelper.LayoutDoLayout(self.LayoutXuanzeshangren)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewPlayerSelect)
    local nX, nY = UIHelper.ConvertToNodeSpace(parent:getParent(), nWorldX, nWorldY)
    local nWidth, nHeight = UIHelper.GetContentSize(parent)
    local nImageWidth, nImageHeight = UIHelper.GetContentSize(self.ImgMap)
    local nShowX = nX + DEFAULT_OFFSET_X
    local nShowY = nY + DEFAULT_OFFSET_Y


    if UIHelper.GetVisible(self.WidgetSpecificSelection2) then--有显示自动寻路tip，将列表放置在自动寻路tip对面
        if not bRight then
            nShowX = nX - nWidth + DEFAULT_OFFSET_X
        end
    else
        if nX + nWidth > nImageWidth / 2 then--没有显示自动寻路tip，自适应位置
            nShowX = nX - nWidth + DEFAULT_OFFSET_X
        end
    end

    if nY - nHeight < -nImageHeight / 2 then
        nShowY = nY + nHeight - DEFAULT_OFFSET_Y
    end
    if parent == self.LayoutXuanzeshangren then
        UIHelper.SetPosition(parent, nShowX, nShowY)
    else
        UIHelper.SetPosition(self.ImgScrollView, nShowX, nShowY)
    end
end


function UIMiddleMap:CloseAllTip()
    self:CloseNeiborAndAutoWalk()
    self:CloseTeamInfo()
    self:CloseWidgetPQ()
end

function UIMiddleMap:CloseNeiborAndAutoWalk()
    UIHelper.SetVisible(self.WidgetSpecificSelection, false)
    UIHelper.SetVisible(self.WidgetSpecificSelection2, false)
end

function UIMiddleMap:CloseTeamInfo()
    UIHelper.SetVisible(self.WidgetTeamInfoScript._rootNode, false)
end

function UIMiddleMap:CloseWidgetPQ()
    UIHelper.SetVisible(self.WidgetNpcScript._rootNode, false)
end

function UIMiddleMap:UpdateNeiborhood(script)
    local bNeiborShow = UIHelper.GetVisible(self.LayoutXuanzeshangren) or UIHelper.GetVisible(self.ImgScrollView)
    if bNeiborShow and self.tbNeiborhood then
        for nIndex, v in ipairs(self.tbNeiborhood) do
            if v:HasScript(script) then
                table.remove(self.tbNeiborhood, nIndex)
                UIHelper.RemoveFromParent(v._rootNode, true)
                UIHelper.LayoutDoLayout(self.LayoutXuanzeshangren)
                UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewPlayerSelect)
                break
            end
        end
    end
end

function UIMiddleMap:ShowAutoWalk(nWorldX, nWorldY)
    UIHelper.SetVisible(self.WidgetSpecificSelection2, true)
    UIHelper.SetWorldPosition(self.WidgetTeaceWalkLeft, nWorldX, nWorldY)
    UIHelper.SetWorldPosition(self.WidgetTeaceWalkRight, nWorldX, nWorldY)

    local bRight = true
    local nImgBgWidth = UIHelper.GetWidth(self.ImgMapMask)
    local nWorldImgBgX = UIHelper.GetWorldPositionX(self.ImgMapMask)
    if nWorldX + UIHelper.GetWidth(self.WidgetTeaceWalkRight) > nImgBgWidth + nWorldImgBgX / 2 then--超出右边界
        bRight = false
    end

    UIHelper.SetVisible(self.WidgetTeaceWalkLeft, bShowAutoWalk and not bRight)
    UIHelper.SetVisible(self.WidgetTeaceWalkRight, bShowAutoWalk and bRight)
    return bRight
end

function UIMiddleMap:CaculateWidgetPos(nWorldX, nWorldY, widget, parent)
    local parent = UIHelper.GetParent(widget)
    local nX, nY = UIHelper.ConvertToNodeSpace(parent, nWorldX, nWorldY)
    local nWidth, nHeight = UIHelper.GetContentSize(widget)
    local nImageWidth, nImageHeight = UIHelper.GetContentSize(self.WidgetIconMask)
    local nIconMaskX, nIconMaskY = UIHelper.GetPosition(self.WidgetIconMask)
    local nShowX = nX + nWidth / 2 + DEFAULT_OFFSET_X--锚点在中心点
    local nShowY = nY

    if nShowX + nWidth / 2  > nIconMaskX + nImageWidth / 2 then
        nShowX = nX - nWidth / 2 - DEFAULT_OFFSET_X
    end
    if nShowY - nHeight / 2 < -nImageHeight / 2 then
        nShowY = -nImageHeight / 2 + nHeight / 2
    end
    return nShowX, nShowY
end

function UIMiddleMap:UpdateSliderPercent()
    self.bAutoSetPercent = true
    local nScale = self.TouchComponent:GetScale()
    local nPercent = (nScale - 1) / (MAX_SCALE - MIN_SCALE) * 100
    UIHelper.SetProgressBarPercent(self.SliderCount, nPercent)

    local nWidth = UIHelper.GetWidth(self.SliderCount) * nPercent / 100
    UIHelper.SetWidth(self.ImgFg, nWidth)
end

function UIMiddleMap:UpdateMapQueueInfo()
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

function UIMiddleMap:InitDebugFly()
    if not Config.bGM then
        return
    end

    if Platform.IsWindows() or Platform.IsMac() then
        return
    end

    UIHelper.BindUIEvent(self.BtnWorldMap, EventType.OnTouchBegan, function(btn)
        Timer.DelTimer(self, self.nDebugFlyTimerID)
        self.nDebugFlyTimerID = Timer.Add(self, 0.5, function()
            self:SetDebugFlyVisible(false)
            self.bShiftDown = true
        end)
    end)
    UIHelper.BindUIEvent(self.BtnWorldMap, EventType.OnTouchEnded, function(btn)
        Timer.DelTimer(self, self.nDebugFlyTimerID)
        self:SetDebugFlyVisible(true)
        self.bShiftDown = false
    end)
    UIHelper.BindUIEvent(self.BtnWorldMap, EventType.OnTouchCanceled, function(btn)
        Timer.DelTimer(self, self.nDebugFlyTimerID)
        self:SetDebugFlyVisible(true)
        self.bShiftDown = false
    end)
end

function UIMiddleMap:SetDebugFlyVisible(bVisible)
    if not Config.bGM then
        return
    end

    ShortcutInteractionData.SetEnableKeyBoard(bVisible) --防止按到轻功

    -- 要记录下之前的显示隐藏状态，不然还原的时候就乱了
    if self.tbLastVisibleMap == nil then
        self.tbLastVisibleMap = {}
    end

    for k, v in ipairs(self.tbDebugFlyHideList) do
        local bRealVisible = nil
        if bVisible then
            bRealVisible = self.tbLastVisibleMap[v]
        else
            bRealVisible = false
            self.tbLastVisibleMap[v] = UIHelper.GetVisible(v)
        end

        if IsBoolean(bRealVisible) then
            UIHelper.SetVisible(v, bRealVisible)
        end
    end
end

function UIMiddleMap:DebugFly(nX, nY)
    if not Config.bGM then
        return
    end

    if self.bShiftDown then
        local x, y = self.PosComponent:MapPosToLogicPos(nX, nY, true)
        SendGMCommand("player.GMSetPosition("..x..","..y..")")
    end
end

function UIMiddleMap:ShowRightMenu()
    local aNpc = MapMgr.GetNpcList(self.nMapID) or {}
    local nIndex = 0
    self.SignScript:Show()
    self.SignScript:UpdateInfo(aNpc, self.tbNodeSelect, self.nMapID, nIndex)
    Event.Dispatch("ON_SETMSGTOGTYPE")
end

function UIMiddleMap:UpdateCircleSFX()
    if not self.initialized then
        return
    end

    if not g_pClientPlayer then
        return
    end
    if self.nMapID ~= g_pClientPlayer.GetMapID() then
        return
    end

    self.tMapCircleSFX = self.tMapCircleSFX or {}

    for _, scriptSFX in pairs(self.tMapCircleSFX) do
        UIHelper.SetVisible(scriptSFX._rootNode, false)
    end
    for i, circle in pairs(TreasureBattleFieldData.tCircle) do
        local tInfo = circle.tInfo
        local scriptSFX = self.tMapCircleSFX[i]
        if not scriptSFX then
            scriptSFX = UIHelper.AddPrefab(PREFAB_ID.WidgetMapSfx, self.WidgetMapDisplay, tInfo.szCirclePath)
            self.tMapCircleSFX[i] = scriptSFX
        elseif scriptSFX.szSFXPath ~= tInfo.szCirclePath then
            UIHelper.RemoveFromParent(scriptSFX._rootNode)
            scriptSFX = UIHelper.AddPrefab(PREFAB_ID.WidgetMapSfx, self.WidgetMapDisplay, tInfo.szCirclePath)
            self.tMapCircleSFX[i] = scriptSFX
        end
        UIHelper.SetVisible(scriptSFX._rootNode, true)

        local fPercent = math.min(1, (GetLogicFrameCount() - circle.nStartFrame) / circle.nTotalFrame)
        local fDistance = fPercent * (circle.fEndtDistance - circle.fStartDistance) + circle.fStartDistance

        local nX = circle.nStartX + fPercent * (circle.nEndX - circle.nStartX)
        local nY = circle.nStartY + fPercent * (circle.nEndY - circle.nStartY)

        local nScale = fDistance * 64 * 2 * self.PosComponent.nScale / tInfo.nCircleDiameter
        local nScaleX = UIHelper.GetScaleX(self.ImgMap)
        local nScaleY = UIHelper.GetScaleY(self.ImgMap)

        -- UIHelper.SetScale(scriptSFX.SFXMap, nScale * nScaleX, nScale * nScaleY)
        scriptSFX.SFXMap:setScale(nScale * nScaleX)

        local imgX, imgY = self.PosComponent:LogicPosToMapPos(nX, nY)
        UIHelper.SetWorldPosition(scriptSFX.SFXMap, imgX, imgY)
    end
end

function UIMiddleMap:RemoveAllSearchRes()

    if self.tbSearchRes then
        for nIndex, script in ipairs(self.tbSearchRes) do
            script:SetSelectedWithCallBack(false)
        end
    end
    self.tbSearchRes = {}

    UIHelper.RemoveAllChildren(self.ScrollViewActivityDetail)
    UIHelper.RemoveAllChildren(self.LayoutLeaveFor)
end

function UIMiddleMap:TryCloseShieldTip()
    if UIHelper.GetSelected(self.TogHide) then
        UIHelper.SetSelected(self.TogHide, false)
        return true
    end
    return false
end

function UIMiddleMap:TryCloseSearchList()
    if UIHelper.GetSelected(self.TogQuestion) then
        UIHelper.SetSelected(self.TogQuestion, false)
        return true
    end
    return false
end

function UIMiddleMap:SearchNPC(szKey)

    self:RemoveAllSearchRes()
    if string.is_nil(szKey) then
        UIHelper.SetVisible(self.WidgetAnchorLeaveFor, false)
        return
    end

    local bAllNPC = true

    local tbNPCList = MapMgr.GetNPCListByKey(self.nMapID, szKey)
    if #tbNPCList == 0 then--地图未下载
        tbNPCList = self:GetSearchResList(szKey)
        bAllNPC = false
    end

    local bScrollView = #tbNPCList > 5
    local parent = bScrollView and self.ScrollViewActivityDetail or self.LayoutLeaveFor

    local nPrefabID = bAllNPC and PREFAB_ID.WidgetSearchCell or PREFAB_ID.WidgetMiddleNavigationCell

    for nIndex, tbNPCInfo in ipairs(tbNPCList) do
        local scriptView = UIHelper.AddPrefab(nPrefabID, parent, tbNPCInfo)
        table.insert(self.tbSearchRes, scriptView)
    end

    if bScrollView then
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewActivityDetail)
    else
        UIHelper.SetTouchEnabled(self.LayoutLeaveFor, true)
        UIHelper.LayoutDoLayout(self.LayoutLeaveFor)
        UIHelper.LayoutDoLayout(self.LayoutDetail)
    end

    UIHelper.SetVisible(self.WidgetAnchorLeaveFor, true)
    UIHelper.SetVisible(self.WidgetAnchorNo, #tbNPCList == 0)
    UIHelper.SetVisible(self.WidgetLayoutDetail, not bScrollView and #tbNPCList ~= 0)
    UIHelper.SetVisible(self.WidgetScrollViewDetail, bScrollView or #tbNPCList == 0)
    UIHelper.SetSwallowTouches(self.ScrollViewActivityDetail, true)
    UIHelper.SetSwallowTouches(self.LayoutLeaveFor, true)
end

function UIMiddleMap:GetSearchNPCList()
    if self.tbNPCList then return self.tbNPCList end

    self.tbNPCList = {}

    local nIndex = 0
    local aNpc = MapMgr.GetNpcList(self.nMapID) or {}
    for k, v in pairs(aNpc) do
        local tbCatalogue = MapHelper.GetMiddleMapNpcCatalogueIconTab(v.id)
        if tbCatalogue then
            if tbCatalogue.nNpcCatalogue ~= 0 then
                self.tbNPCList[tbCatalogue.nNpcCatalogue] = self.tbNPCList[tbCatalogue.nNpcCatalogue] or {}
                table.insert(self.tbNPCList[tbCatalogue.nNpcCatalogue], v)
            end
        end
    end

    return self.tbNPCList
end

function UIMiddleMap:GetSearchResList(szKey)
    local tbNPCList = {}
    self.tbIndex = {}
    for nType, tbNav in pairs(self:GetSearchNPCList()) do
        for nNav, tbCell in ipairs(tbNav) do
            for i, v in ipairs(tbCell.group) do
                local szName = UIHelper.GBKToUTF8(Table_GetNpcTemplateName(v.nNpcID))
                local szDisplay = self:FormatName(szName, v.szKind, v.szOrderName)
                if string.match(szDisplay, szKey) then
                    table.insert(tbNPCList, {
                        nType, nNav, i, v, self.nMapID, self.tbIndex, tbCell.middlemap
                    })
                end
            end
        end
    end
    return tbNPCList
end


function UIMiddleMap:FormatName(szName, szKind, szOrder)
    if szKind and szKind ~= "" then
        szName = string.format("%s·%s", szKind, szName)
    end
    if szOrder and szOrder ~= "" then
        szName = string.format("%s·%s", szName, szOrder)
    end
    return UIHelper.LimitUtf8Len(szName, 11)
end

function UIMiddleMap:OpenOrCloseBoardPanel(bOpen)
    self.bBoardPanelOpen = bOpen
    UIHelper.SetVisible(self.WidgetZYZH, bOpen)
    for nIndex, node in ipairs(self.tbZYZHHideNode) do
        UIHelper.SetVisible(node, not bOpen)
    end
    UIHelper.SetVisible(self.WidgetMapSyncBoard, bOpen)
    UIHelper.SetVisible(self.WidgetAniBottomBtn, not bOpen)
    self:UpdateCurrentMap()
    self:UpdateArrowNum()
    self:UpdateFlagNum()
    self:UpdateGatherNum()
end

--设置当前阵营指挥标记类型
function UIMiddleMap:SetBoardMarkType(nIndex)
    if not MapMgr.IsPlayerCanDraw() then return end
    self.nBoardMarkType = MARK_UIINDEX_TO_LOGICINDEX[nIndex]
    self.tbBoardMarkInfo = MapMgr.GetMarkInfoByTypeID(self.nBoardMarkType)
end

function UIMiddleMap:IsArrowMark()
    return self.tbBoardMarkInfo and self.tbBoardMarkInfo.szAppendWndName == "Wnd_MapArrow"
end

function UIMiddleMap:IsGatherMark()
    return self.tbBoardMarkInfo and self.tbBoardMarkInfo.szAppendWndName == "Wnd_MapGather"
end

function UIMiddleMap:IsFlagMark()
    return self.tbBoardMarkInfo and self.tbBoardMarkInfo.szAppendWndName == "Wnd_MapMark"
end

function UIMiddleMap:DeleteMarkNode(script)
    UIHelper.RemoveFromParent(script._rootNode, true)
    self:UpdateNeiborhood(script)
end

function UIMiddleMap:UpdateTeamSignPost()
    local pingX, pingY = TeamData.GetSignPostPos()
    local script
    self.tbNodeScripts["TeamSignPost"] = self.tbNodeScripts["TeamSignPost"] or {}
    if pingX and pingY then
        if not self.tbNodeScripts["TeamSignPost"][1] then
            script = self:CreateMapNodeFromLogicPos(self.WidgetSign, 0, 0)
            script:SetTeamSignPost()
            self.tbNodeScripts["TeamSignPost"][1] = script
        end
        script = self.tbNodeScripts["TeamSignPost"][1]
        local absX, absY = self.PosComponent:LogicPosToMapPos(pingX, pingY)
        local pos = self.WidgetSign:convertToNodeSpace({x = absX, y = absY})
        script:SetPosition(pos.x, pos.y, pingX, pingY)
        script:SetVisible(true)
    else
        script = self.tbNodeScripts["TeamSignPost"][1]
        if script then
            script:SetVisible(false)
        end
    end
end

function UIMiddleMap:ClearHuntEventNodes()
    if self.tbNodeScripts["HuntEvent"] then
        for nIndex, script in ipairs(self.tbNodeScripts["HuntEvent"]) do
            self:DeleteMarkNode(script)
        end
    end
    self.tbNodeScripts["HuntEvent"] = {}
end

function UIMiddleMap:UpdateHuntEvent()

    self:ClearHuntEventNodes()
    local hPlayer = g_pClientPlayer
    if not hPlayer then
        return
    end

    local tData   = hPlayer.GetMapMark()
    local dwMapID = hPlayer.GetMapID()

    if dwMapID ~= self.nMapID then
        tData = {}
    end

    table.sort(tData, function(a, b) return a.nY > b.nY end)
    for _, tMarkD in pairs(tData) do
        local tEventInfo = MapMgr.GetPQHuntInfo(tMarkD.nType)
        local tPoint = {tMarkD.nX, tMarkD.nY, tMarkD.nZ or 0}
        if tEventInfo then
            local script = self:CreateMapNodeFromLogicPos(self.WidgetDynamic, tMarkD.nX, tMarkD.nY, true)
            script:SetHuntEvent(tEventInfo, tMarkD, tPoint)
            script.fnDetailPanel = function(bTrace)
                local tbNpcInfo = script:GetNPCInfo()
                if not script.bOpenPanel and tbNpcInfo then
                    local nX, nY = UIHelper.ConvertToWorldSpace(script._rootNode:getParent(), script.nX, script.nY)
                    self:ShowWidgetNpc(tbNpcInfo, nX, nY)
                    RemoteCallToServer("On_PQ_ClickIcon", tMarkD.nType)
                end
            end
            script.fnSelected = function(bSelected)
                self:OnSelectSignButton(script, bSelected)
                RemoteCallToServer("On_PQ_ClickIcon", tMarkD.nType)
            end
            table.insert(self.tbNodeScripts["HuntEvent"], script)
        end
    end
end

function UIMiddleMap:InitHeatMapArea()
    self.tbHeatMapArea = {}
    UIHelper.RemoveAllChildren(self.WidgetGFArea)
    local tbGFAreaInfo = Table_GetHeatMapAreaInfo(self.nMapID)
    if tbGFAreaInfo and HeatMapData.bCanShowHeatMap then
        for nIndex, tbInfo in ipairs(tbGFAreaInfo) do
            local tPoint = SplitString(tbInfo.szRegionPoint, ";")
            local nRegionX, nRegionY = tPoint[1], tPoint[2] + 2 * (tbInfo.nRegionH - 1)
            local nX = nRegionX * CELL_LENGTH * REGION_GRID_WIDTH
            local nY = nRegionY * CELL_LENGTH * REGION_GRID_HEIGHT
            local nWidth, nHeight = CELL_LENGTH * tbInfo.nRegionW, CELL_LENGTH * tbInfo.nRegionH
            local scriptView = self:CreateMapNodeFromLogicPos(self.WidgetGFArea, nX, nY, false, PREFAB_ID.WidgetMapCampArea)
            scriptView:OnShow(tbInfo, self.TouchComponent:GetScale())
            table.insert(self.tbHeatMapArea, scriptView)
        end
    end
end

function UIMiddleMap:UpdateHighLightArea(nPQID)
    if not self.tbHeatMapArea then return end
    for index, script in ipairs(self.tbHeatMapArea) do
        script:UpdateCampAreaHighLight(nPQID)
    end
end

function UIMiddleMap:UpdateHeatMapState()
    self:UpdateHeatMapBtnState()
    -- self:InitHeatMapArea()
    self:UpdateHeatMapDetailList()
    self:UpdateMapModeList()
end

function UIMiddleMap:UpdateHeatMapBtnState()
    local bCanShowHeatMap = HeatMapData.bCanShowHeatMap
    UIHelper.SetVisible(self.BtnRefresh, bCanShowHeatMap)
    UIHelper.SetVisible(self.BtnCampNum, bCanShowHeatMap and not Table_IsTongWarFieldMap(self.nMapID))
    UIHelper.SetVisible(self.TogCamp, bCanShowHeatMap)
    self.WidgetCampColorScript:OnEnter(self.nMapID)
    UIHelper.LayoutDoLayout(self.LayoutBtn)
end

--更新人数列表、头像等
function UIMiddleMap:UpadteHeatMap()
    self:UpdateHeatMapDetailList()
    self:UpdateHeatMapNum()
end

function UIMiddleMap:UpdateHeatMapDetailList()
    self.CampDetailScript:OnEnter(self.nMapID)
end

--人数
function UIMiddleMap:UpdateHeatMapNum()
    UIHelper.RemoveAllChildren(self.WidgetGFList)
    if HeatMapData.nHeatMapMode == HEAT_MAP_MODE.HIDE or not HeatMapData.bCanShowHeatMap then return end
    local tbHeatMapInfo = HeatMapData.GetHeatMapAreaInfo()
    for nRegionX, v in pairs(tbHeatMapInfo) do
        for nRegionY, t in pairs(tbHeatMapInfo[nRegionX]) do
            local tInfo = t[CAMP.GOOD] or t[CAMP.EVIL]
            local bCenter = not (t[CAMP.GOOD] and t[CAMP.EVIL])
            local nX = tInfo.nRegionX * CELL_LENGTH * REGION_GRID_WIDTH
            local nY = tInfo.nRegionY * CELL_LENGTH * REGION_GRID_HEIGHT
            local scriptView = self:CreateMapNodeFromLogicPos(self.WidgetGFList, nX, nY, false, PREFAB_ID.WidgetMapCampCell)
            scriptView:OnShow(t, HeatMapData.nHeatMapMode)
        end
    end
end

function UIMiddleMap:TryCloseCampFilter()
    if UIHelper.GetSelected(self.TogCamp) then
        UIHelper.SetSelected(self.TogCamp, false)
        return true
    end
    return false
end

function UIMiddleMap:UpdateMapModeList()
    if not HeatMapData.bCanShowHeatMap then return end
    local script = UIHelper.GetBindScript(self.WidgetCampFilter)
    if script then
        script:OnEnter(HeatMapData.nHeatMapMode)
    end
end

function UIMiddleMap:AddArrowInfo(tbArrowInfo)
    if not self.tbArrowInfoList then
        self.tbArrowInfoList = {}
    end
    table.insert(self.tbArrowInfoList, tbArrowInfo)
end

--获得当前界面上箭头数量
function UIMiddleMap:GetArrowNum()
    local tbAllBoadInfo = self:GetAllBoardInfo()
    return #tbAllBoadInfo.tArrow
end

function UIMiddleMap:GetFlagNum()
    local tbAllBoadInfo = self:GetAllBoardInfo()
    return #tbAllBoadInfo.tFlag
end



function UIMiddleMap:AddBoardTagInfo(tbTagInfo)
    if not self.tbBoardTagInfoList then
        self.tbBoardTagInfoList = {}
    end
    table.insert(self.tbBoardTagInfoList, tbTagInfo)
end

function UIMiddleMap:ClearBoardInfo()
    self.tbArrowInfoList = {}
    self.tbBoardTagInfoList = {}
end
-----------------------------切线相关Begin
-- 更新当前切线
function UIMiddleMap:UpdateCurMapCopyInfo()
    local bShowMapCopy = self:GetMapCopyInfo() and not HeatMapData.bCanShowHeatMap--self:IsCurrentMap() and (self:GetMapCopyInfo() ~= nil)

    UIHelper.SetVisible(self.BtnShuntFilter , bShowMapCopy)
    UIHelper.SetVisible(self.ShuntImgDown , not SelfieData.IsInStudioMap())
    if bShowMapCopy then
        self.nCurSceneCopyIndex = 1
        local scene = GetClientPlayer().GetScene()
        if scene then
            if self.nMapID ~= scene.dwMapID then
                self.nCurSceneCopyIndex = 0
            else
                self.nCurSceneCopyIndex = scene.nCopyIndex
            end
        end
        if self.nCurSceneCopyIndex == 0 then
            UIHelper.SetString(self.LabelShuntFilter , "1线")
        else
            UIHelper.SetString(self.LabelShuntFilter , string.format("当前-%d线",self.nCurSceneCopyIndex))
        end
        UIHelper.SetString(self.LabelShuntFilterCoolCD , "")
        UIHelper.SetTouchDownHideTips(self.BtnShuntFilter , false)
    else
        --Timer.DelTimer(self , self.nMapCopyCoolTimerID)
    end
end

function UIMiddleMap:UpdateCoolTime()
    local player = GetClientPlayer()
    if not player then
        return
    end
    local nSubTime =  (MapMgr.nChangeMapCopyCoolTime or 0) + player.GetCDLeft(GDAPI_GetMapCopyCoolDownCD()) - GetCurrentTime()
    if nSubTime > 0 then
        UIHelper.SetVisible(self.ShuntImgUp , false)
        UIHelper.SetVisible(self.ShuntImgDown , false)
        UIHelper.SetString(self.LabelShuntFilterCoolCD , string.format("(%d秒)",nSubTime))
        UIHelper.SetCanSelect(self.BtnShuntFilter , false , "您的操作过于频繁，请稍后再试" , true)
        Timer.DelTimer(self , self.nMapCopyCoolTimerID)
        Timer.AddCountDown(self , nSubTime , function (deltaTime)
            UIHelper.SetString(self.LabelShuntFilterCoolCD , string.format("(%d秒)",deltaTime))
        end,function ()
            UIHelper.SetVisible(self.ShuntImgUp , self.bClickShuntFilter)
            UIHelper.SetVisible(self.ShuntImgDown , not self.bClickShuntFilter)
            UIHelper.SetCanSelect(self.BtnShuntFilter , true)
            UIHelper.SetString(self.LabelShuntFilterCoolCD , "")
        end)
    end
end

function UIMiddleMap:GetMapCopyInfo()
    local tMapCopyInfo = GDAPI_GetMapCopyInfo(self.nMapID)
    local nStudioMaxCopy = GDAPI_GetPhotoStudioMaxCopy(self.nMapID)
    if not tMapCopyInfo and not nStudioMaxCopy then
        return false
    end
    return true
end

function UIMiddleMap:UpdateMapCopyFilter()
    UIHelper.SetVisible(self.ShuntImgUp , self.bClickShuntFilter)
    UIHelper.SetVisible(self.ShuntImgDown , not self.bClickShuntFilter)
    UIHelper.SetVisible(self.WidgetShuntFilter , self.bClickShuntFilter)
    if not self.bClickShuntFilter then
        return
    end
    -- local player = GetClientPlayer()
    -- if not player then
    --     return
    -- end
    -- local scene = player.GetScene()
    local mapCopyData = GDAPI_GetMapCopyInfo(self.nMapID) or {nMaxCopy = 1}
    local bMore = mapCopyData.nMaxCopy >= 7
    UIHelper.SetVisible(self.ScrollViewDateFilter , bMore)
    UIHelper.SetVisible(self.WidgetShunImgBg , bMore)
    UIHelper.SetVisible(self.LayoutShuntFilter , not bMore)
    local parentNode = self.ScrollViewDateFilter
    if not bMore then
        parentNode = self.LayoutShuntFilter
    end
    UIHelper.RemoveAllChildren(parentNode)
    for i = 1, mapCopyData.nMaxCopy, 1 do
         UIHelper.AddPrefab(PREFAB_ID.WidgetMidShuntFilter , parentNode , i , self.nCurSceneCopyIndex == i , function (nCopyIndex)
            self.bClickShuntFilter = false
            self:UpdateMapCopyFilter()
            if nCopyIndex ~= self.nCurSceneCopyIndex then
                UIHelper.ShowConfirm(string.format("确认是否前往【%s%d线】" , GBKToUTF8(Table_GetMapName(self.nMapID)) , nCopyIndex) , function ()
                    MapMgr.nChangeMapCopyCoolTime = GetCurrentTime()
                    RemoteCallToServer("On_Map_ChangeMapCopy" , self.nMapID ,nCopyIndex )
                    UIMgr.Close(VIEW_ID.PanelMiddleMap)
                    UIMgr.Close(VIEW_ID.PanelWorldMap)
                end)
            else
                TipsHelper.ShowNormalTip("您已处于当前分线")
            end
         end)
    end
    if not bMore then
        UIHelper.LayoutDoLayout(parentNode)
    else
        UIHelper.ScrollViewDoLayoutAndToTop(parentNode)
    end
    UIHelper.SetTouchDownHideTips(parentNode , false)
end

-----------------------------切线相关End

function UIMiddleMap:UpdateWeather()
    if self.nMapID ~= 25 and self.nMapID ~= 27 then
        UIHelper.SetVisible(self.WidgetWeatherSwitch, false)
        return
    end

    local bShowWeather, _ = CampData.IsActivityPresetOn(self.nMapID)
    local bEnablePreset = SelfieData.IsActivityPresetEnabled()

    UIHelper.SetVisible(self.WidgetWeatherSwitch, bShowWeather)
    UIHelper.SetSelected(self.ToggleLightPositionSwitch, bEnablePreset, false)
end

return UIMiddleMap