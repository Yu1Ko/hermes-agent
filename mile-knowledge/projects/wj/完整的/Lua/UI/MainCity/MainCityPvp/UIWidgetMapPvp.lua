local UIWidgetMapPvp = class("UIWidgetMapPvp")
local MAX_SHOW_FLAG_TIME = 60 * 2

local SCALE_RATE = 20
local MIN_SCALE = 1
local MAX_SCALE = 3

local ICON_SCALE = 0.75

local ICON_NEAR_OFFSET = 25
local ICON_AWAY_OFFSET = 15

local TRACE_FRAME = "UIAtlas2_Public_PublicIcon_PublicIcon1_icon_teace_now2.png"

local MAP_MARK_FRAME = "UIAtlas2_Map_MapIcon_img_location1.png"
local BOARD_GATHER_FRAME = "UIAtlas2_Map_MapIcon_img_icon_team2"

local OnShowMap

function UIWidgetMapPvp:OnEnter()
    self.bShowSlider = false
    self.PosComponent = require("Lua/UI/Map/Component/UIPositionComponent"):CreateInstance()

    self:RegisterEvent()

    local player = GetClientPlayer()
    if not player then
        return
    end

    self.nMapID = player.GetMapID()
    self.nIconScale = self.nIconScale or ICON_SCALE
    PostThreadCall(OnShowMap, self, "GetRegionInfoByGameWorldPos", self.nMapID, player.nX, player.nY)
end

function UIWidgetMapPvp:OnExit()
    if self.nUpdateTimer then
        Timer.DelTimer(self, self.nUpdateTimer)
        self.nUpdateTimer = nil
    end
    if self.ZoomComponent then
        self.ZoomComponent:UnBindUIZoom()
    end
end

function UIWidgetMapPvp:RegisterEvent()
    Event.Reg(self, "ON_BATTLE_FIELD_MAKR_DATA_NOTIFY", function(tData)
        local bTreasureBattle = BattleFieldData.IsInTreasureBattleFieldMap()
        if bTreasureBattle then
            return
        end
        self.tMarkData = tData
        self:UpdateMarkNodes()
    end)
    Event.Reg(self, "ON_BATTLE_FIELD_GAIN_DATA_NOTIFY", function(tData)
        local bTreasureBattle = BattleFieldData.IsInTreasureBattleFieldMap()
        if bTreasureBattle then
            return
        end
        self.tGainData = tData
        self:UpdateGainNodes()
    end)
    Event.Reg(self, "ON_MAP_MARK_UPDATE", function()
        self:UpdateDynamicNodes()
    end)
    -- Event.Reg(self, "ON_FIELD_MARK_STATE_UPDATE", function(tFieldMark)
    --     self:UpdateDynamicNodes()
    -- end)
    Event.Reg(self, EventType.OnLeaderChangeTeamTag, function()
        self:UpdateTeamTag()
    end)
    Event.Reg(self, EventType.OnDeleteTeamMark, function()
        self:UpdateTeamTag()
    end)
    Event.Reg(self, EventType.OnMapUpdateNpcTrace, function()
        self:UpdateNodeTrace()
    end)
    Event.Reg(self, EventType.ClientChangeAutoNavState, function(bStart)
        self:UpdateNodeAutoNav()
        self:UpdateNodeTrace()
    end)
    Event.Reg(self, EventType.OnAutoNavResult, function(bSuccess)
        self:UpdateNodeAutoNav()
        self:UpdateNodeTrace()
    end)
    Event.Reg(self, EventType.OnMapMarkUpdate, function(bClearMapMark)
        self:UpdateMapMark()
    end)
    Event.Reg(self, "BOARD_INFO_HAS_BEEN_UPDATED", function()
        self:UpdateBoardInfo()
    end)
    Event.Reg(self, "BOARD_NPC_INFO_HAS_BEEN_UPDATED", function()
        self:UpdateBoardInfo()
    end)
    Event.Reg(self, "CAMP_OB_BECOME_PLAYER", function()
        self:UpdateBoardInfo()
    end)
    Event.Reg(self, "CHANGE_CAMP_UI", function(nX, nY, nCamp)
        if nCamp ~= CampOBBaseData.GetCampOfBoardInfo() then return end
        self.tbGatherData = {nX = nX, nY = nY}
        self:UpdateBoardGather()
    end)
    Event.Reg(self, "DESTROY_CAMP_UI", function(nCamp)
        if nCamp ~= CampOBBaseData.GetCampOfBoardInfo() then return end
        self.tbGatherData = nil
        self:UpdateBoardGather()
    end)

    Event.Reg(self, "QUEST_ACCEPTED", function(nQuestIndex, nQuestID)
        self:UpdateQuestNodes()
    end)
    Event.Reg(self, "SHARE_QUEST", function(nResultCode, nQuestID, dwDestPlayerID)
        Timer.AddFrame(self, 1, function()
            self:UpdateQuestNodes() --延迟一帧，否则GetQuestPhase状态不对会出一些问题
        end)
    end)
    Event.Reg(self, "QUEST_FINISHED", function(nQuestID, bForceFinish, bAssist, nAddStamina, nAddThew)
        self:UpdateQuestNodes()
    end)
    Event.Reg(self, "SUCCESSIVE_QUEST_FINISHED", function(nQuestID, nNextQuestID)
        self:UpdateQuestNodes()
    end)
    Event.Reg(self, "QUEST_FAILED", function(nQuestIndex)
        self:UpdateQuestNodes()
    end)
    Event.Reg(self, "QUEST_CANCELED", function(nQuestID)
        self:UpdateQuestNodes()
    end)
    Event.Reg(self, "SET_QUEST_STATE", function(nQuestID, nQuestState)
        self:UpdateQuestNodes()
    end)
    Event.Reg(self, "QUEST_DATA_UPDATE", function(nQuestIndex, eEventType, nValue1, nValue2, nValue3)
        self:UpdateQuestNodes()
    end)
    Event.Reg(self, EventType.OnHeatMapDataUpdate, function()
        self:UpdateHeatMap()
    end)
    Event.Reg(self, EventType.OnSelectHeatMapMode, function()
        self:UpdateHeatMap()
    end)


    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        self:UpdateMapPosition()
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnPvpMapUpdate, function()
        self.bShowSlider = false
        self:UpdateSliderVisible()

        self:UpdateMapPosition()
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnMap, EventType.OnClick, function()
        if not UIMgr.IsViewOpened(VIEW_ID.PanelMiddleMap) then
            UIMgr.Open(VIEW_ID.PanelMiddleMap)
        end
    end)

    UIHelper.BindUIEvent(self.BtnBig, EventType.OnClick, function()
        self.bAutoSetPercent = false
        local nProgressBarPercent = UIHelper.GetProgressBarPercent(self.SliderCount)
        local nPercent = math.floor(nProgressBarPercent / SCALE_RATE) * SCALE_RATE + SCALE_RATE
        UIHelper.SetProgressBarPercent(self.SliderCount, nPercent)
    end)

    UIHelper.BindUIEvent(self.BtnSliderSwitch, EventType.OnClick, function()
        self.bShowSlider = not self.bShowSlider
        self:UpdateSliderVisible()
    end)

    UIHelper.BindUIEvent(self.BtnSmall, EventType.OnClick, function()
        self.bAutoSetPercent = false
        local nProgressBarPercent = UIHelper.GetProgressBarPercent(self.SliderCount)
        local nPercent = math.floor(nProgressBarPercent / SCALE_RATE) * SCALE_RATE - SCALE_RATE
        UIHelper.SetProgressBarPercent(self.SliderCount, nPercent)
    end)

    UIHelper.BindUIEvent(self.BtnRefresh, EventType.OnClick, function()
        HeatMapData.DoApplyHeatMapInfo()
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

    UIHelper.SetTouchEnabled(self.WidgetTouch, true)
    UIHelper.SetSwallowTouches(self.WidgetTouch, false)
    UIHelper.BindUIEvent(self.WidgetTouch, EventType.OnTouchBegan, function(btn, nX, nY)
        if self.TouchComponent then
            self.TouchComponent:TouchBegin(nX, nY)
        end
        self.bStartMove = true
    end)
    UIHelper.BindUIEvent(self.WidgetTouch, EventType.OnTouchMoved, function(btn, nX, nY)
        if not self.bStartMove then
            return
        end

        if self.TouchComponent then
            self.TouchComponent:TouchMoved(nX, nY)
        end
    end)
    UIHelper.BindUIEvent(self.WidgetTouch, EventType.OnTouchEnded, function(btn, nX, nY)
        self.bStartMove = false
    end)
    UIHelper.BindUIEvent(self.WidgetTouch, EventType.OnTouchCanceled, function(btn, nX, nY)
        self.bStartMove = false
    end)
end

function UIWidgetMapPvp:InitData(nMapID, nIndex, nArea)
    self.tNodeScripts = self.tNodeScripts or {}

    local aM = MapHelper.tbMiddleMapInfo[nMapID]
    local szName = Table_GetMapName(nMapID)
    local szPath = MapHelper.GetMapParams(nMapID)
    if aM and aM[nIndex] then
        local t = aM[nIndex]
        if t.name then
            szName = t.name
        end

        self.nIndex = nIndex
        self.nArea = nArea
        self.szName = szName
        self.szImgPath = "mui/Resource/Minimap1/BMap_".. nMapID ..".png"

        self.PosComponent:Init(t.width, t.height, t.startx, t.starty, t.scale, self.nMapID)

        self.bIncopy = t.copy
        self.bInRresherRoom = t.fresherroom
        self.bInBattlefield = t.battlefield
        return true
    end
end

function UIWidgetMapPvp:InitTouchComponent()
    if self.TouchComponent or self.ZoomComponent then
        return
    end

    self.TouchComponent = require("Lua/UI/Map/Component/UIMapTouchComponent"):CreateInstance()
    self.TouchComponent:Init(self.ImgMap)

    self.TouchComponent:SetRangeWidget(self.ImgMapMask)
    self.TouchComponent:SetScaleLimit(MIN_SCALE, MAX_SCALE)
    self.TouchComponent:RegisterPosEvent(function(x, y)
        self.PosComponent:Update(self.ImgMap, true)
        self:UpdateInfo()

        UIHelper.SetOpacity(self.WidgetLocation, 0)
        Timer.DelTimer(self, self.nLocationAlphaTimerID)
        self.nLocationAlphaTimerID = Timer.Add(self, 0.3, function()
            UIHelper.SetOpacity(self.WidgetLocation, 255)
        end)
    end)
    self.TouchComponent:RegisterScaleEvent(function(nScale)
        self:UpdateSliderPercent()
    end)

    self.ZoomComponent = require("Lua/UI/Map/Component/UIMapZoomComponent"):CreateInstance()
    self.ZoomComponent:BindUIZoom(self.WidgetZoom, function(nDelta, bWheel)
        if not UIHelper.GetHierarchyVisible(self._rootNode) then
            return
        end

        if bWheel and self.WidgetTouch.getMouseIn and not self.WidgetTouch:getMouseIn() then
            return
        end

        if self.TouchComponent then
            self.TouchComponent:Zoom(nDelta)
            if bWheel then
                cc.utils:setMouseWheelHandled(true)
            end
        end
    end)

    self.nIconScale = 1
end

function UIWidgetMapPvp:UpdateSliderVisible()
    UIHelper.SetVisible(self.WidgetSlider, self.bShowSlider)
    UIHelper.SetVisible(self.BtnChangeMapSize, not self.bShowSlider)
    UIHelper.SetSpriteFrame(self.ImgBtn, self.bShowSlider and "UIAtlas2_Map_MapButton_MiniMapBtn2" or "UIAtlas2_Map_MapButton_MiniMapBtn1")
    UIHelper.LayoutDoLayout(self.LayoutBiggerMapBtn)
end

function UIWidgetMapPvp:UpdateSliderPercent()
    if not self.TouchComponent then
        return
    end

    self.bAutoSetPercent = true
    local nScale = self.TouchComponent:GetScale()
    local nPercent = (nScale - 1) / (MAX_SCALE - MIN_SCALE) * 100
    nPercent = math.floor(nPercent + 0.5) --这里四舍五入一下，不然会有精度问题，导致0.2*100=20，但实际C++那边取到的是19
    UIHelper.SetProgressBarPercent(self.SliderCount, nPercent)

    local nWidth = UIHelper.GetWidth(self.SliderCount) * nPercent / 100
    UIHelper.SetWidth(self.ImgFg, nWidth)
end

function UIWidgetMapPvp:UpdateMapImage()
    UIHelper.SetTexture(self.ImgMap, self.szImgPath, false)
    UIHelper.UpdateMask(self.ImgMapMask)
    self:UpdateMapPosition()
end

function UIWidgetMapPvp:UpdateMapPosition()
    if self.TouchComponent then
        self.TouchComponent:Scale(1)
    end
    self.PosComponent:Update(self.ImgMap, true)
end

function UIWidgetMapPvp:UpdateInfo()
    if not UIHelper.GetHierarchyVisible(self._rootNode) then
        return
    end

    self:Update()
    self:UpdateMarkNodes()
    self:UpdateGainNodes()
    self:UpdateDynamicNodes()
    MapMgr.UpdateMapTeamTag()
    self:UpdateTeamTag()
    self:UpdateNodeTrace()
    self:UpdateNodeAutoNav()
    self:UpdateMapMark()
    self:UpdateQuestNodes()
    self:UpdateBoardInfo()
    --self:UpdateHeatMapArea()
    self:UpdateHeatMap()
end

function UIWidgetMapPvp:Update()
    self:UpdatePosition()
    self:UpdateTeammate()
    --self:UpdateDeathNode()
    self:UpdateTeamSignPost()
    self:UpdateCircleSFX()
    self:UpdateEndTime()
end

function UIWidgetMapPvp:UpdatePosition()
    if not self.tNodeScripts then
        return
    end

    local player = GetClientPlayer()
    if not player then
        return
    end

    local nRotation = MapMgr.GetPlayerRotation(player)
    UIHelper.SetRotation(self.ImgSelf, nRotation)

    nRotation = MapMgr.GetCameraRotation()
    UIHelper.SetRotation(self.WidgetSelfCameraDirection, nRotation)

    local imgX, imgY = self.PosComponent:LogicPosToMapPos(player.nX, player.nY)
    UIHelper.SetWorldPosition(self.WidgetLocation, imgX, imgY)
end

function UIWidgetMapPvp:UpdateTeammate(player)
    if not self.tNodeScripts then return end

    local player = GetClientPlayer()
    if not player then
        return
    end

    local nIndex = 1
    local szType = "Teammate"
    self.tNodeScripts[szType] = self.tNodeScripts[szType] or {}

    TeamData.Generator(function(dwID, tMemberInfo)
        if dwID == player.dwID or not tMemberInfo.bIsOnLine or not player.IsPartyMemberInSameScene(dwID) then
            return
        end
        if tMemberInfo.nPosX and tMemberInfo.nPosY then
            local script = MapMgr.AllocScript(self.tNodeScripts[szType], self.WidgetTeammate, PREFAB_ID.WidgetTeammate, nIndex)
            UIHelper.SetParent(script._rootNode, self.WidgetTeammate)
            script:UpdateNodeName(szType .. nIndex)
            script:UpdatePosition(self.PosComponent, tMemberInfo.nPosX, tMemberInfo.nPosY)
            nIndex = nIndex + 1
        end
    end)

    MapMgr.ClearScript(self.tNodeScripts[szType], nIndex)
end

function UIWidgetMapPvp:UpdateDeathNode()
    if not self.tNodeScripts then return end

    local nIndex = 1
    local szType = "Death"
    self.tNodeScripts[szType] = self.tNodeScripts[szType] or {}

    local tbPoint = MapMgr.GetDeathPosition()
    if tbPoint then
        local nX, nY, _ = unpack(tbPoint)
        if nX and nY then
            local script = MapMgr.AllocScript(self.tNodeScripts[szType], self.WidgetOtherMark, PREFAB_ID.WidgetTeammate, nIndex)
            UIHelper.SetParent(script._rootNode, self.WidgetOtherMark)
            script:UpdateNodeName(szType .. nIndex)
            script:UpdateFrame(DEATH_FRAME.ICON, self.nIconScale * 0.8)
            script:UpdateBg(DEATH_FRAME.BG, self.nIconScale)
            script:UpdatePosition(self.PosComponent, nX, nY)
            nIndex = nIndex + 1
        end
    end

    MapMgr.ClearScript(self.tNodeScripts[szType], nIndex)
end

function UIWidgetMapPvp:UpdateTeamSignPost()
    if not self.tNodeScripts then return end

    local nIndex = 1
    local szType = "TeamSignPost"
    self.tNodeScripts[szType] = self.tNodeScripts[szType] or {}

    local nPingX, nPingY = TeamData.GetSignPostPos()
    if nPingX and nPingY then
        local script = MapMgr.AllocScript(self.tNodeScripts[szType], self.WidgetOtherMark, PREFAB_ID.WidgetTeammate, nIndex)
        UIHelper.SetParent(script._rootNode, self.WidgetOtherMark)
        script:UpdateNodeName(szType .. nIndex)
        script:SetTeamSignPost()
        script:UpdatePosition(self.PosComponent, nPingX, nPingY)
        nIndex = nIndex + 1
    end

    MapMgr.ClearScript(self.tNodeScripts[szType], nIndex)
end

OnShowMap = function(self, nArea)
    local nIndex = MapHelper.GetMapMiddleMapIndex(self.nMapID, nArea)

    self:InitData(self.nMapID, nIndex, nArea)
    self:UpdateMapImage()
    self:UpdateSliderVisible()
    self:UpdateSliderPercent()

    self:UpdateInfo()
    self.nUpdateTimer = Timer.AddCycle(self, 0.1, function()
        self:Update()
    end)
end

function UIWidgetMapPvp:UpdateMarkNodes()
    if not self.tNodeScripts then return end

    local nIndex = 1
    local szType = "Mark"
    self.tNodeScripts[szType] = self.tNodeScripts[szType] or {}

    self.tbEndTimeScript = {}
    local tBattleData = MapMgr.Table_GetBattleFieldData()

    for i, tbMarkInfo in ipairs(self.tMarkData or {}) do
        local tParam = tBattleData[tbMarkInfo.nType]
        local nX, nY = unpack(tbMarkInfo.aPoint)
        if tParam and nX and nY then
            local script = MapMgr.AllocScript(self.tNodeScripts[szType], self.WidgetOtherMark, PREFAB_ID.WidgetTeammate, nIndex)
            -- local szFrame = UIHelper.GBKToUTF8(tParam.szFrame)
            local szFrame = MapMgr.GetBattleFieldDataImage(tbMarkInfo.nType)
            UIHelper.SetParent(script._rootNode, self.WidgetOtherMark)
            script:UpdateNodeName(szType .. nIndex)
            script:UpdateFrame(szFrame, tParam.fScale * self.nIconScale / ICON_SCALE, false)
            script:UpdatePosition(self.PosComponent, nX, nY)

            if tbMarkInfo.nEndTime and tbMarkInfo.nEndTime > 0 then
                table.insert(self.tbEndTimeScript, {script = script, nEndTime = tbMarkInfo.nEndTime})
            end
            nIndex = nIndex + 1
        end
    end

    MapMgr.ClearScript(self.tNodeScripts[szType], nIndex)
end

function UIWidgetMapPvp:UpdateGainNodes()
    if not self.tNodeScripts then return end

    local nIndex = 1
    local szType = "Gain"
    self.tNodeScripts[szType] = self.tNodeScripts[szType] or {}

    local tBattleData = MapMgr.Table_GetBattleFieldData()

    for i, tbGainInfo in ipairs(self.tGainData or {}) do
        local tParam = tBattleData[tbGainInfo.nType]
        local nX, nY = unpack(tbGainInfo.aPoint)
        if tParam and nX and nY then
            local script = MapMgr.AllocScript(self.tNodeScripts[szType], self.WidgetOtherMark, PREFAB_ID.WidgetTeammate, nIndex)
            -- local szFrame = UIHelper.GBKToUTF8(tParam.szFrame)
            local szFrame = MapMgr.GetBattleFieldDataImage(tbGainInfo.nType)
            UIHelper.SetParent(script._rootNode, self.WidgetOtherMark)
            script:UpdateNodeName(szType .. nIndex)
            script:UpdateFrame(szFrame, tParam.fScale * self.nIconScale)
            script:UpdatePosition(self.PosComponent, nX, nY)
            nIndex = nIndex + 1
        end
    end

    MapMgr.ClearScript(self.tNodeScripts[szType], nIndex)
end

function UIWidgetMapPvp:UpdateDynamicNodes()
    if not self.tNodeScripts then return end

    local player = g_pClientPlayer
    if not player then
        return
    end

    if MapHelper.GetBattleFieldType() == BATTLEFIELD_MAP_TYPE.BATTLEFIELD then
        return
    end

    local nIndex = 1
    local szType = "Dynamic"
    self.tNodeScripts[szType] = self.tNodeScripts[szType] or {}

    local tDynamicData = player.GetMapMark()
    local tMapDynamicData = MapMgr.Table_GetMapDynamicData()

    for i, tbDynamicInfo in ipairs(tDynamicData or {}) do
        local tParam = tMapDynamicData[tbDynamicInfo.nType]
        if tParam and player.nLevel >= tParam.nMinShowLevel and tbDynamicInfo.nX > 0 and tbDynamicInfo.nY > 0 then
            local script = MapMgr.AllocScript(self.tNodeScripts[szType], self.WidgetOtherMark, PREFAB_ID.WidgetTeammate, nIndex)
            -- local szFrame = UIHelper.GBKToUTF8(tParam.szMobileImage)
            local szFrame = MapMgr.GetMapDynamicImage(tbDynamicInfo.nType)
            UIHelper.SetParent(script._rootNode, self.WidgetOtherMark) --刷新顺序
            script:UpdateNodeName(szType .. nIndex .. "_" .. tbDynamicInfo.nType)
            script:UpdateFrame(szFrame, self.nIconScale)
            script:UpdatePosition(self.PosComponent, tbDynamicInfo.nX, tbDynamicInfo.nY)
            nIndex = nIndex + 1
        end
    end

    MapMgr.ClearScript(self.tNodeScripts[szType], nIndex)

    -- 战场的动态标记先放到这个组件下面
    --self:UpdateBattleFieldMarkState() --ON_BATTLE_FIELD_MAKR_DATA_NOTIFY里已经显示了这里要显示的标记了，所以屏掉这里了
end

function UIWidgetMapPvp:UpdateBattleFieldMarkState()
    if not self.tNodeScripts then return end

    local nIndex = 1
    local szType = "BattleFieldMark"
    self.tNodeScripts[szType] = self.tNodeScripts[szType] or {}

    local tBattleFieldMarkData = MapHelper.dwFieldMapID ~= self.nMapID and MapHelper.tFieldMark
    local tFieldMarkStateFrame = MapMgr.Table_GetBattleMarkState()

    for i, tbBattleFieldMarkInfo in pairs(tBattleFieldMarkData or {}) do
        local tParam = tFieldMarkStateFrame[tbBattleFieldMarkInfo.nState]
        if tParam and tbBattleFieldMarkInfo.nX and tbBattleFieldMarkInfo.nY then
            local script = MapMgr.AllocScript(self.tNodeScripts[szType], self.WidgetOtherMark, PREFAB_ID.WidgetTeammate, nIndex)
            -- local szFrame = UIHelper.GBKToUTF8(tParam.szMobileImage)
            local szFrame = MapMgr.GetBattleMarkImage(tbBattleFieldMarkInfo.nState)
            UIHelper.SetParent(script._rootNode, self.WidgetOtherMark)
            script:UpdateNodeName(szType .. nIndex)
            script:UpdateFrame(szFrame, self.nIconScale)
            script:UpdatePosition(self.PosComponent, tbBattleFieldMarkInfo.nX, tbBattleFieldMarkInfo.nY)
            nIndex = nIndex + 1
        end
    end

    MapMgr.ClearScript(self.tNodeScripts[szType], nIndex)
end

function UIWidgetMapPvp:UpdateTeamTag()
    if not self.tNodeScripts then return end

    local nIndex = 1
    local szType = "TeamTag"
    self.tNodeScripts[szType] = self.tNodeScripts[szType] or {}

    local nMarkIndex
    for i, v in ipairs(Storage.MiddleMapData.tbTagList[self.nMapID] or {}) do
        if v.szName == g_tStrings.MIDDLEMAP_NEW_TEAM_FLAG then
            nMarkIndex = i
            break
        end
    end

    local tbMarkInfo = nMarkIndex and Storage.MiddleMapData.tbTagList[self.nMapID][nMarkIndex]
    if tbMarkInfo then
        local tParam = MapHelper.GetMiddleMapTagIconTab(tbMarkInfo.nIconID)
        if tParam and tbMarkInfo.nX and tbMarkInfo.nY then
            local script = MapMgr.AllocScript(self.tNodeScripts[szType], self.WidgetOtherMark, PREFAB_ID.WidgetTeammate, nIndex)
            UIHelper.SetParent(script._rootNode, self.WidgetOtherMark)
            script:UpdateNodeName(szType .. nIndex)
            script:UpdateFrame(tParam.szFrame, self.nIconScale)
            script:UpdatePosition(self.PosComponent, tbMarkInfo.nX, tbMarkInfo.nY)
            nIndex = nIndex + 1
        end
    end

    MapMgr.ClearScript(self.tNodeScripts[szType], nIndex)
end

function UIWidgetMapPvp:UpdateNodeTrace()
    if not self.tNodeScripts then return end

    local nIndex = 1
    local szType = "Trace"
    self.tNodeScripts[szType] = self.tNodeScripts[szType] or {}

    local szNpc, nMapID, tbPoint, szUID, szFrame = MapMgr.GetTraceInfo()
    local bCanShowTrace = MapMgr.CanShowTrace()

    if tbPoint and bCanShowTrace and nMapID == self.nMapID then
        local nX, nY, _ = unpack(tbPoint)
        if nX and nY then
            local script = MapMgr.AllocScript(self.tNodeScripts[szType], self.WidgetOtherMark, PREFAB_ID.WidgetTeammate, nIndex)
            szFrame = szFrame or TRACE_FRAME
            UIHelper.SetParent(script._rootNode, self.WidgetOtherMark)
            script:UpdateNodeName(szType .. nIndex)
            script:UpdateFrame(szFrame, self.nIconScale)
            script:UpdatePosition(self.PosComponent, nX, nY)
            nIndex = nIndex + 1
        end
    end

    MapMgr.ClearScript(self.tNodeScripts[szType], nIndex)
end

function UIWidgetMapPvp:UpdateNodeAutoNav()
    if not self.tNodeScripts then return end

    local tbPoint = AutoNav.GetNavPoint()
    if tbPoint and tbPoint.nMapID == self.nMapID then
        local nX, nY = self.PosComponent:LogicPosToMapPos(tbPoint.nX, tbPoint.nY)
        local nScale = self.nIconScale * 0.5
        UIHelper.SetVisible(self.WidgetWalk, true)
        UIHelper.SetScale(self.WidgetWalk, nScale, nScale)
        UIHelper.SetWorldPosition(self.WidgetWalk, nX, nY)
    else
        UIHelper.SetVisible(self.WidgetWalk, false)
    end
end

function UIWidgetMapPvp:UpdateMapMark()
    if not self.tNodeScripts then return end

    local nIndex = 1
    local szType = "MapMark"
    self.tNodeScripts[szType] = self.tNodeScripts[szType] or {}

    local szMarkName, nMarkX, nMarkY, nMarkZ, nMapMarkMapID = MapMgr.GetMarkInfo()
    if self.nMapID == nMapMarkMapID and nMarkX and nMarkX ~= -10000 and nMarkY then
        local script = MapMgr.AllocScript(self.tNodeScripts[szType], self.WidgetOtherMark, PREFAB_ID.WidgetTeammate, nIndex)
        UIHelper.SetParent(script._rootNode, self.WidgetOtherMark)
        script:UpdateNodeName(szType .. nIndex)
        script:UpdateFrame(MAP_MARK_FRAME, self.nIconScale)
        script:UpdatePosition(self.PosComponent, nMarkX, nMarkY)
        nIndex = nIndex + 1
    end

    MapMgr.ClearScript(self.tNodeScripts[szType], nIndex)
end

function UIWidgetMapPvp:UpdateQuestNodes()
    if not self.tNodeScripts then return end

    local player = g_pClientPlayer
    if not player then
        return
    end

    local nIndex = 1
    local szType = "Quest"
    self.tNodeScripts[szType] = self.tNodeScripts[szType] or {}

    local tMyQuestNode = QuestData.GetAllQuestIDByMapID(self.nMapID)
    self.tSceneQuest = self.tSceneQuest or Table_GetAllSceneQuest(self.nMapID)

    local tQuestNode = {}
    for nQuestID, tObject in pairs(self.tSceneQuest or {}) do
        local bCanAccept = false
        local tQuestUIInfo = Table_GetQuestStringInfo(nQuestID)
        if tQuestUIInfo.dwActivityID <= 0 or ActivityData.IsActivityOn(nQuestID) then
            for _, tInfo in pairs(tObject) do
                local szQuestType = tInfo[1]
                local dwObject = tInfo[2]
                if szQuestType == "D" or szQuestType == "N" then
                    if dwObject > 0 then
                        if player.CanAcceptQuest(nQuestID, dwObject) == QUEST_RESULT.SUCCESS then
                            bCanAccept = true
                            break
                        end
                    end
                elseif szQuestType == "P" then
                    if player.CanAcceptQuest(nQuestID) == QUEST_RESULT.SUCCESS then
                        bCanAccept = true
                        break
                    end
                end
            end
        end

        if bCanAccept then
            table.insert(tQuestNode, {nQuestID, "accept"})
        end
    end

    for _, tQuest in ipairs(tQuestNode) do
        local nQuestID, szQuestType = unpack(tQuest)
        local tData = TableQuest_GetPoint(nQuestID, szQuestType, self.nIndex, self.nMapID, self.nArea or 0)
        for _, tPoints in ipairs(tData or {}) do
            if tPoints.type ~= "R" then
                for _, tPoint in ipairs(tPoints) do
                    local nType, nState = QuestData.GetQuestState(szQuestType, nQuestID)
                    local tQuestTab = nType and MapHelper.GetMiddleMapQuestIconTab(nType, nState)
                    if tQuestTab and not QuestData.IsAdventureQuest(nQuestID) then
                        local nX, nY, nZ = unpack(tPoint)
                        if nX and nY then
                            local script = MapMgr.AllocScript(self.tNodeScripts[szType], self.WidgetOtherMark, PREFAB_ID.WidgetTeammate, nIndex)
                            UIHelper.SetParent(script._rootNode, self.WidgetOtherMark)
                            script:UpdateNodeName(szType .. nIndex)
                            script:UpdateFrame(tQuestTab.szFrame, self.nIconScale * 0.8)
                            -- script:UpdateBg(tQuestTab.szBgFrame, self.nIconScale)
                            script:UpdatePosition(self.PosComponent, nX, nY)
                            nIndex = nIndex + 1
                        end
                    end
                end
            end
        end
    end

    for _, tMyQuest in ipairs(tMyQuestNode) do
        local nQuestID, tPoint, bFinished, _ = unpack(tMyQuest)
        if bFinished then
            local nX, nY, nZ = unpack(tPoint)
            if nX and nY then
                local script = MapMgr.AllocScript(self.tNodeScripts[szType], self.WidgetOtherMark, PREFAB_ID.WidgetTeammate, nIndex)
                UIHelper.SetParent(script._rootNode, self.WidgetOtherMark)
                script:UpdateNodeName(szType .. nIndex)
                script:UpdateFrame(MYQUEST_FRAME[bFinished].ICON, self.nIconScale * 0.8)
                -- script:UpdateBg(MYQUEST_FRAME[bFinished].BG, self.nIconScale)
                script:UpdatePosition(self.PosComponent, nX, nY)
                nIndex = nIndex + 1
            end
        end
    end

    MapMgr.ClearScript(self.tNodeScripts[szType], nIndex)
end

function UIWidgetMapPvp:UpdateBoardInfo()
    local _, bIsInActivityMap = CampData.IsInActivity()
    if not bIsInActivityMap then
        return
    end

    --指挥标记
    self:UpdateBoardFlag()
    self:UpdateBoardArrow()

    --集结
    self:UpdateBoardGather()

    --其它阵营标记
    self:UpdateBoardCar()
    self:UpdateBoardNPC()
    self:UpdateBoardNPCBeAttacked()
end

function UIWidgetMapPvp:UpdateBoardFlag()
    if not self.tNodeScripts then return end

    local nIndex = 1
    local szType = "BoardFlag"
    self.tNodeScripts[szType] = self.tNodeScripts[szType] or {}

    local tbSyncBoardInfo = MapMgr.GetSyncBoardInfo()
    local tbFlag = tbSyncBoardInfo and tbSyncBoardInfo.tFlag

    for i, tbFlagInfo in ipairs(tbFlag or {}) do
        local tParam = MapMgr.GetMarkInfoByTypeID(tbFlagInfo.nType)
        if tParam and tbFlagInfo.nX and tbFlagInfo.nY then
            local script = MapMgr.AllocScript(self.tNodeScripts[szType], self.WidgetBoardMark, PREFAB_ID.WidgetTeammate, nIndex)
            local szFrame = UIHelper.GBKToUTF8(tParam.szMobileImage)
            UIHelper.SetParent(script._rootNode, self.WidgetBoardMark)
            script:UpdateNodeName(szType .. nIndex)
            script:UpdateFrame(szFrame, self.nIconScale, false)
            script:UpdatePosition(self.PosComponent, tbFlagInfo.nX, tbFlagInfo.nY)
            nIndex = nIndex + 1
        end
    end
    MapMgr.ClearScript(self.tNodeScripts[szType], nIndex)
end

function UIWidgetMapPvp:UpdateBoardArrow()
    if not self.tNodeScripts then return end

    local nIndex = 1
    local szType = "BoardArrow"
    self.tNodeScripts[szType] = self.tNodeScripts[szType] or {}

    local tbSyncBoardInfo = MapMgr.GetSyncBoardInfo()
    local tbArrow = tbSyncBoardInfo and tbSyncBoardInfo.tArrow

    for i, tbArrowInfo in ipairs(tbArrow or {}) do
        local script = MapMgr.AllocScript(self.tNodeScripts[szType], self.WidgetBoardMark, PREFAB_ID.WidgetTeammate, nIndex)
        UIHelper.SetParent(script._rootNode, self.WidgetBoardMark)
        script:UpdateNodeName(szType .. nIndex)
        script:SetArrow(self.PosComponent, tbArrowInfo)
        nIndex = nIndex + 1
    end
    MapMgr.ClearScript(self.tNodeScripts[szType], nIndex)
end

function UIWidgetMapPvp:UpdateBoardGather()
    if not self.tNodeScripts then return end

    local nIndex = 1
    local szType = "BoardGather"
    self.tNodeScripts[szType] = self.tNodeScripts[szType] or {}

    local tbSyncBoardInfo = MapMgr.GetSyncBoardInfo()
    local tGather = tbSyncBoardInfo and tbSyncBoardInfo.tGather

    for i, tbGatherInfo in ipairs(tGather or {}) do
        if tbGatherInfo.nX and tbGatherInfo.nY then
            local script = MapMgr.AllocScript(self.tNodeScripts[szType], self.WidgetBoardMark, PREFAB_ID.WidgetTeammate, nIndex)
            UIHelper.SetParent(script._rootNode, self.WidgetBoardMark)
            script:UpdateNodeName(szType .. nIndex)
            script:UpdateFrame(BOARD_GATHER_FRAME, self.nIconScale, false)
            script:UpdatePosition(self.PosComponent, tbGatherInfo.nX, tbGatherInfo.nY)
            nIndex = nIndex + 1
        end
    end

    MapMgr.ClearScript(self.tNodeScripts[szType], nIndex)
end

function UIWidgetMapPvp:UpdateBoardCar()
    if not self.tNodeScripts then return end

    local nIndex = 1
    local szType = "BoardCar"
    self.tNodeScripts[szType] = self.tNodeScripts[szType] or {}

    local tbSyncBoardInfo = MapMgr.GetSyncBoardInfo()
    local tbCar = tbSyncBoardInfo and tbSyncBoardInfo.tCar

    for i, tbCarInfo in ipairs(tbCar or {}) do
        local tParam = MapMgr.GetMarkInfoByTypeID(14)
        if tParam and tbCarInfo.nX and tbCarInfo.nY then
            local script = MapMgr.AllocScript(self.tNodeScripts[szType], self.WidgetBoardMark, PREFAB_ID.WidgetTeammate, nIndex)
            local szFrame = UIHelper.GBKToUTF8(tParam.szMobileImage)
            UIHelper.SetParent(script._rootNode, self.WidgetBoardMark)
            script:UpdateNodeName(szType .. nIndex)
            script:UpdateFrame(szFrame, self.nIconScale)
            script:UpdatePosition(self.PosComponent, tbCarInfo.nX, tbCarInfo.nY)
            nIndex = nIndex + 1
        end
    end

    MapMgr.ClearScript(self.tNodeScripts[szType], nIndex)
end

function UIWidgetMapPvp:UpdateBoardNPC()
    if self.nIconScale < 1 then return end
    if not self.tNodeScripts then return end

    local nIndex = 1
    local szType = "BoardNpc"
    self.tNodeScripts[szType] = self.tNodeScripts[szType] or {}

    local tbSyncBoardInfo = MapMgr.GetSyncBoardInfo()
    local tbNpc = tbSyncBoardInfo and tbSyncBoardInfo.tNPC

    for i, tbNpcInfo in pairs(tbNpc or {}) do
        if tbNpcInfo.nX and tbNpcInfo.nY then
            -- local script = MapMgr.AllocScript(self.tNodeScripts[szType], self.WidgetBoardMark, PREFAB_ID.WidgetTeammate, nIndex)
            -- local szFrame = UIHelper.GBKToUTF8(tbNpcInfo.szMobileImage)
            -- UIHelper.SetParent(script._rootNode, self.WidgetBoardMark)
            -- script:UpdateNodeName(szType .. nIndex)
            -- script:UpdateFrame(szFrame, self.nIconScale)
            -- script:UpdatePosition(self.PosComponent, tbNpcInfo.nX, tbNpcInfo.nY)
            -- if CommandBaseData.IsCommanderExisted() and CommandBaseData.IsCommandModeCanBeEntered() then
            --     script:UpdateProgress(tbNpcInfo.nHpPercentage)
            -- end
            local script = MapMgr.AllocScript(self.tNodeScripts[szType], self.WidgetBoardMark, PREFAB_ID.WidgetMiddleSignButton, nIndex)
            UIHelper.SetParent(script._rootNode, self.WidgetBoardMark)
            local nWorldX, nWorldY = self.PosComponent:LogicPosToMapPos(tbNpcInfo.nX, tbNpcInfo.nY)
            local pos = self.WidgetBoardMark:convertToNodeSpace({x = nWorldX, y = nWorldY})
            local nScale = self.nIconScale * 0.8
            UIHelper.SetScale(script._rootNode, nScale, nScale)
            script:SetIsMapPvp(true)
            script:SetPosition(pos.x, pos.y, tbNpcInfo.nX, tbNpcInfo.nY)
            script:SetBoardNPC(tbNpcInfo)
            UIHelper.SetName(script._rootNode, szType .. nIndex)
            nIndex = nIndex + 1
        end
    end

    self:FixNPCPos()
    MapMgr.ClearScript(self.tNodeScripts[szType], nIndex)
end

function UIWidgetMapPvp:UpdateBoardNPCBeAttacked()
    if not self.tNodeScripts then return end

    local tbSyncBoardInfo = MapMgr.GetSyncBoardInfo()
    local tbNPCBeAttacked = tbSyncBoardInfo and tbSyncBoardInfo.tNPCBeAttacked

    local nIndex = 1
    local szType = "BoardNpcBeAttacked"
    self.tNodeScripts[szType] = self.tNodeScripts[szType] or {}

    for i, tbNPCBeAttackedInfo in ipairs(tbNPCBeAttacked or {}) do
        if tbNPCBeAttackedInfo.nX and tbNPCBeAttackedInfo.nY then
            local script = MapMgr.AllocScript(self.tNodeScripts[szType], self.WidgetBoardMark, PREFAB_ID.WidgetTeammate, nIndex)
            UIHelper.SetParent(script._rootNode, self.WidgetBoardMark)
            script:UpdateNodeName(szType .. nIndex)
            script:UpdatePosition(self.PosComponent, tbNPCBeAttackedInfo.nX, tbNPCBeAttackedInfo.nY)
            script:SetFighting()
            nIndex = nIndex + 1
        end
    end

    MapMgr.ClearScript(self.tNodeScripts[szType], nIndex)
end

function UIWidgetMapPvp:FixNPCPos()
    if not self.tNodeScripts or not self.tNodeScripts["BoardNpc"] then return end
    local tbScriptList = self.tNodeScripts["BoardNpc"]
    for i = 1, #tbScriptList do
        for j = i + 1, #tbScriptList do
            local scriptA = tbScriptList[i]
            local scriptB = tbScriptList[j]
            local nXA, nYA = scriptA:GetPosition()
            local nXB, nYB = scriptB:GetPosition()
            if (nXA ~= 0 or nYA ~= 0) and (nXB ~= 0 or nYB ~= 0) then
                local nDist = GetLogicDist({nXA, nYA, 0}, {nXB, nYB, 0}) --改为以世界坐标计算
                local nOffset = ICON_AWAY_OFFSET + nDist
                if nDist <= ICON_NEAR_OFFSET then
                    self:MoveNode(scriptA, nOffset, 0)
                    self:MoveNode(scriptB, -nOffset, 0)
                end
            end
        end
    end
end

function UIWidgetMapPvp:MoveNode(script, nOffSetX, nOffSetY)
    if not script.GetPosition then return end
    local nX, nY = script.nX, script.nY
    nX = nX + nOffSetX
    nY = nY + nOffSetY

    local nLogicX, nLogicY = self.PosComponent:MapPosToLogicPos(nX, nY)
    script:SetPosition(nX, nY, nLogicX, nLogicY)
    return script
end

function UIWidgetMapPvp:UpdateHeatMapArea()
    if not self.tNodeScripts then return end

    local nIndex = 1
    local szType = "HeatMapArea"
    self.tNodeScripts[szType] = self.tNodeScripts[szType] or {}

    local tbGFAreaInfo = Table_GetHeatMapAreaInfo(self.nMapID)
    if tbGFAreaInfo and HeatMapData.bCanShowHeatMap then
        for _, tbInfo in ipairs(tbGFAreaInfo) do
            local tPoint = SplitString(tbInfo.szRegionPoint, ";")
            local nRegionX, nRegionY = tPoint[1], tPoint[2] + 2 * (tbInfo.nRegionH - 1)
            local nX = nRegionX * CELL_LENGTH * REGION_GRID_WIDTH
            local nY = nRegionY * CELL_LENGTH * REGION_GRID_HEIGHT
            local nWidth, nHeight = CELL_LENGTH * tbInfo.nRegionW, CELL_LENGTH * tbInfo.nRegionH
            local script = MapMgr.AllocScript(self.tNodeScripts[szType], self.WidgetGFArea, PREFAB_ID.WidgetMapCampArea, nIndex)
            UIHelper.SetParent(script._rootNode, self.WidgetGFArea)
            local nWorldX, nWorldY = self.PosComponent:LogicPosToMapPos(nX, nY)
            UIHelper.SetWorldPosition(script._rootNode, nWorldX, nWorldY)
            local nScale = self.TouchComponent and self.TouchComponent:GetScale() or 1
            script:OnShow(tbInfo, nScale * self.nIconScale)
            nIndex = nIndex + 1
        end
    end

    MapMgr.ClearScript(self.tNodeScripts[szType], nIndex)
end

function UIWidgetMapPvp:UpdateHeatMap()
    if not self.tNodeScripts then return end
    if self.nIconScale < 1 then return end --缩小时不显示

    local nIndex = 1
    local szType = "HeatMap"
    self.tNodeScripts[szType] = self.tNodeScripts[szType] or {}

    if HeatMapData.nHeatMapMode ~= HEAT_MAP_MODE.HIDE and HeatMapData.bCanShowHeatMap then
        local nBtnState = HeatMapData.CanAutoApplyHeatMapData() and BTN_STATE.Disable or BTN_STATE.Normal
        UIHelper.SetButtonState(self.BtnRefresh, nBtnState, g_tStrings.STR_HEAT_MAP_REFRESH_REAL_TIME, false)
        UIHelper.SetVisible(self.BtnRefresh, true)

        -- local nLeftFrame = hPlayer.GetCDLeft(HEAT_MAP_REFRESH_CD.COMMANDER)
        -- local nLeftTime  = math.ceil(nLeftFrame / GLOBAL.GAME_FPS)
        -- local szText     = g_tStrings.STR_HEAT_MAP_REFRESH
        -- if nLeftTime > 0 then
        --     szText = szText .. "(".. nLeftTime .. ")"
        -- end

        if Table_IsTongWarFieldMap(self.nMapID) then
            local tbHeatMapInfo = HeatMapData.GetHeatMapAreaInfo()
            for nRegionX, v in pairs(tbHeatMapInfo) do
                for nRegionY, t in pairs(tbHeatMapInfo[nRegionX]) do
                    local tInfo = t[CAMP.GOOD] or t[CAMP.EVIL]
                    local bCenter = not (t[CAMP.GOOD] and t[CAMP.EVIL])
                    local nX = tInfo.nRegionX * CELL_LENGTH * REGION_GRID_WIDTH
                    local nY = tInfo.nRegionY * CELL_LENGTH * REGION_GRID_HEIGHT
                    local script = MapMgr.AllocScript(self.tNodeScripts[szType], self.WidgetHeatMark, PREFAB_ID.WidgetMapCampCell, nIndex)
                    UIHelper.SetParent(script._rootNode, self.WidgetHeatMark)
                    local nWorldX, nWorldY = self.PosComponent:LogicPosToMapPos(nX, nY)
                    UIHelper.SetWorldPosition(script._rootNode, nWorldX, nWorldY)
                    UIHelper.SetScale(script._rootNode, self.nIconScale, self.nIconScale)
                    script:OnShow(t, HEAT_MAP_MODE.SHOW)
                    nIndex = nIndex + 1
                end
            end
        end

        local tbGFAreaNumInfo = HeatMapData.GetGFAreaNumInfo(self.nMapID)
        for _, tbInfo in ipairs(tbGFAreaNumInfo) do
            local tbAreaInfo = tbInfo.tAreaInfo
            local tPoint = SplitString(tbAreaInfo.szRegionPoint, ";")
            local nRegionX, nRegionY = tPoint[1], tPoint[2] + 2 * (tbAreaInfo.nRegionH - 1)
            local nX = nRegionX * CELL_LENGTH * REGION_GRID_WIDTH
            local nY = nRegionY * CELL_LENGTH * REGION_GRID_HEIGHT
            local nWidth, nHeight = CELL_LENGTH * tbAreaInfo.nRegionW, CELL_LENGTH * tbAreaInfo.nRegionH
            local script = MapMgr.AllocScript(self.tNodeScripts[szType], self.WidgetHeatMark, PREFAB_ID.WidgetMiddleSignButton, nIndex)
            UIHelper.SetAnchorPoint(script._rootNode, 0.5, 0.5)
            UIHelper.SetParent(script._rootNode, self.WidgetHeatMark)
            local nWorldX, nWorldY = self.PosComponent:LogicPosToMapPos(nX, nY)
            local nScale = self.nIconScale
            UIHelper.SetWorldPosition(script._rootNode, nWorldX - tbAreaInfo.nOffsetX * 0.3, nWorldY - tbAreaInfo.nOffsetY)
            UIHelper.SetScale(script._rootNode, nScale, nScale)
            script:SetProportion(tbInfo.nGoodTotalCount, tbInfo.nEvilTotalCount)
            nIndex = nIndex + 1
        end
    else
        UIHelper.SetVisible(self.BtnRefresh, false)
    end

    MapMgr.ClearScript(self.tNodeScripts[szType], nIndex)
end

function UIWidgetMapPvp:UpdateCircleSFX()
    self.tMapCircleSFX = self.tMapCircleSFX or {}

    for _, scriptSFX in pairs(self.tMapCircleSFX) do
        UIHelper.SetVisible(scriptSFX, false)
    end
    for i, circle in pairs(TreasureBattleFieldData.tCircle) do
        local tInfo = circle.tInfo
        local scriptSFX = self.tMapCircleSFX[i]
        if not scriptSFX then
            scriptSFX = cc.DrawNode:create()
            self.WidgetMark:addChild(scriptSFX, 1)
            UIHelper.SetPosition(scriptSFX, 0, 0)
            self.tMapCircleSFX[i] = scriptSFX
        end
        UIHelper.SetVisible(scriptSFX, true)

        local fPercent = math.min(1, (GetLogicFrameCount() - circle.nStartFrame) / circle.nTotalFrame)
        local fDistance = fPercent * (circle.fEndtDistance - circle.fStartDistance) + circle.fStartDistance

        local nX = circle.nStartX + fPercent * (circle.nEndX - circle.nStartX)
        local nY = circle.nStartY + fPercent * (circle.nEndY - circle.nStartY)

        local scale = math.min(0.8, math.max(0.2, 600 / fDistance * 0.5))
        local step = math.min(scale * fDistance, 1000)
        local nRadius = fDistance * 64

        local nCenterX, nCenterY = self.PosComponent:LogicPosToMapPos(nX, nY)
        local nBorderX, nBorderY = self.PosComponent:LogicPosToMapPos(nX + nRadius , nY)

        local nCX, nCY = nCenterX, nCenterY
        local nBX, nBY = nBorderX, nBorderY
        local nR = math.sqrt((nCX-nBX) * (nCX-nBX) + (nCY-nBY) * (nCY-nBY))
        local tC = TreasureBattleFieldData.tMiniMapCircleColor[i] or cc.c4f(1, 1, 1, 1)

        scriptSFX:clear()
        scriptSFX:drawCircle(cc.p(0, 0), nR, 360, step, false, tC)
        UIHelper.SetWorldPosition(scriptSFX, nCX, nCY)
    end
end

function UIWidgetMapPvp:UpdateEndTime()
    if not self.tbEndTimeScript then return end
    local nCount = #self.tbEndTimeScript
    if nCount == 0 then return end

    for nIndex = #self.tbEndTimeScript, 1, -1 do
        local tbInfo = self.tbEndTimeScript[nIndex]
        local script = tbInfo.script
        local nEndTime = tbInfo.nEndTime
        local szEndTime = self:GetFlagTime(nEndTime)
        script:UpdateEndTime(szEndTime)

        if szEndTime == -1 then
            table.remove(self.tbEndTimeScript, nIndex)
        end
    end
end

function UIWidgetMapPvp:GetFlagTime(nEndTime)
    local nLeftTime = nEndTime - GetCurrentTime()
    if nLeftTime > 0 then
        if nLeftTime > MAX_SHOW_FLAG_TIME then
            return -1
        else
            local nM = math.floor(nLeftTime / 60)
            local nS = nLeftTime % 60
            local szResult = ""
            if nM >= 1 then
                szResult = szResult .. nM .. "'"
                if nS < 10 then
                    szResult = szResult .. "0" .. nS .. "''"
                else
                    szResult = szResult .. nS .. "''"
                end
            else
                szResult = szResult .. nS .. "''"
            end
            return szResult
        end
    else
        return -1
    end
end

return UIWidgetMapPvp