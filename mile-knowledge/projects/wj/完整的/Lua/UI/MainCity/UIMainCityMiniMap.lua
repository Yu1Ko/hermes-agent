local UIMainCityMiniMap = class("UIMainCityMiniMap")


local WIDTH = 196
local HEIGHT = 196
local TRACE_LIMIT = 78
local MIMAP_SCALE = 1

local DEATH_NODE = 4
local QUEST_NODE = 5
local TEAMMATE_NODE = 6
local DOODAD_NODE = 7
local TRACE_NODE = 8
local MARK_NODE = 9
local SIGNPOST_NODE = 10

local DEATH_FRAME = 'UIAtlas2_Public_PublicIcon_PublicIcon1_icon_Die.png'
local QUEST_FRAME = 'UIAtlas2_Public_PublicIcon_PublicIcon1_icon_renwuWC_huang.png'
local ENEMY_FRAME = 'UIAtlas2_Public_PublicIcon_PublicIcon1_img_FocusPermanent.png'
local TEAMMATE_FRAME = {
    'UIAtlas2_Public_PublicIcon_PublicIcon1_img_teammate.png',
    'UIAtlas2_Public_PublicIcon_PublicIcon1_img_teammate1.png'
}
local DOODAD_FRAME = {
    'UIAtlas2_Map_MapIcon_icon_mineral.png',
    'UIAtlas2_Map_MapIcon_icon_herb.png',
}
local TRACE_FRAME = {
    'UIAtlas2_Public_PublicIcon_PublicIcon1_icon_mubiao.png',
    'UIAtlas2_Public_PublicIcon_PublicIcon1_icon_teace_now2.png',
}

function UIMainCityMiniMap:OnEnter()
    self.tbMarkNode = {}
    self.tbImgPosMapX = {}
    self.tbImgPosMapY = {}
    self.prefabPool = self.prefabPool or PrefabPool.New(PREFAB_ID.WidgetMiniMapMark, 20)

    self:Update()
    Timer.DelTimer(self, self.nUpdateTimer)
    self.nUpdateTimer = Timer.AddCycle(self, 0.1, function()
        self:Update()
    end)

    self:UpdateCurrentMap()

    Event.Reg(self, EventType.OnClientPlayerEnter, function()
        self.nPlayerID = g_pClientPlayer and g_pClientPlayer.dwID or 0
        self.nLeft = -1
        self.nRight = -1
        self.nBottom = -1
        self.nTop = -1
        self:UpdateCurrentMap()
    end)

    Event.Reg(self, EventType.OnClientPlayerLeave, function()
        self.szImageHover = nil
        for nType, v in pairs(self.tbMarkNode) do
            for nID, tNode in pairs(v) do
                self:RemoveMarkNode(nType, nID)
            end
        end
    end)

    Event.Reg(self, EventType.UpdateMinimapHover, function(tbInfo)
        local nFrame = tbInfo.nFrame
        if tbInfo.szImagePath then
            local szPath = UIHelper.GBKToUTF8(tbInfo.szImagePath)
            local szImageID = string.sub(szPath, -7, -7)
            self.szImageHover = string.format("Resource/Minimap/BattleMinimap%d_%d.png", tonumber(szImageID), nFrame)
        else
            self.szImageHover = nil
        end
    end)


    Event.Reg(self, "UPDATE_NPC_MINIMAP_MARK", function()
        local tNode = self:ShowMarkNode(QUEST_NODE, arg0, arg1, arg2, QUEST_FRAME)
        if not tNode then return end
        tNode.nFrame = 30

        self:UpdateNodePosition(tNode)
    end)

    Event.Reg(self, "PLAYER_DEATH", function()
        local player = GetClientPlayer()
        self.nDeathMap = player.GetMapID()
        local tNode = self:ShowMarkNode(DEATH_NODE, 0, player.nX, player.nY, DEATH_FRAME)

        self:UpdateNodePosition(tNode)
    end)

    Event.Reg(self, "DOODAD_ENTER_SCENE", function()
        local nDoodadID = arg0
        local doodad = GetDoodad(nDoodadID)
        if not doodad then
            return
        end
        local nCraftID = Table_GetCraftDoodadID(doodad.dwTemplateID)
        if not DOODAD_FRAME[nCraftID] then
            return
        end
        local tNode = self:ShowMarkNode(DOODAD_NODE, nDoodadID, doodad.nX, doodad.nY, DOODAD_FRAME[nCraftID], nCraftID)

        self:UpdateNodePosition(tNode)
    end)

    Event.Reg(self, "DOODAD_LEAVE_SCENE", function()
        local nDoodadID = arg0
        local tNode = self:RemoveMarkNode(DOODAD_NODE, nDoodadID)
        if tNode then
            self:UpdateNodePosition(tNode)
        end
    end)

    Event.Reg(self, "MINIMAP_MARK", function()
        local type, id, del, gx, gy, gz, desc, disLimit, fadeoutTime  = arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8
    end)

    Event.Reg(self, "UPDATE_MAP_MARK", function(nX, nY, nZ, nType, szComment, bShowMidMap)
        if nX ~= -10000 then
            local tNode = self:ShowMarkNode(MARK_NODE, 0, nX, nY, "UIAtlas2_Map_MapIcon_icon_tingzhan.png")
            self:UpdateNodePosition(tNode)
            self:SetMarkVisible(MARK_NODE, 0, true)
        else
            self:SetMarkVisible(MARK_NODE, 0, false)
        end
    end)

    Event.Reg(self, "UPDATE_REGION_INFO", function(dwRegionInfo)
        if self.nMapID and dwRegionInfo then
            local szName = MapHelper.GetMapAreaName(self.nMapID, dwRegionInfo)
            UIHelper.SetString(self.LabelMapName, GBKToUTF8(szName), 6)
        end
    end)

    Event.Reg(self, "HOME_LAND_RESULT_CODE", function (nResultType)
        if nResultType == HOMELAND_RESULT_CODE.CLIENT_READY then
            self:UpdateCurrentMap()
        end
    end)


    Event.Reg(self, "ON_ENEMY_PLAYER_ENTER", function(nkey, dwIndex, nX, nY, nLeftTime)
        local tNode = self:ShowMarkNode(nkey, dwIndex, nX, nY, ENEMY_FRAME)
        tNode.nFrame = nLeftTime
        self:UpdateNodePosition(tNode)
    end)
end

function UIMainCityMiniMap:GetScenePosition(x, y)
    x = x * (self.scale or 0)
    y = y * (self.scale or 0)

    if not self.nPlayerX then self.nPlayerX = 0 end
    if not self.nPlayerY then self.nPlayerY = 0 end

    return (x - self.nPlayerX) * MIMAP_SCALE, (y - self.nPlayerY) * MIMAP_SCALE
end

function UIMainCityMiniMap:CreateMarkNode(nType, nID, szFrame)
    local node, script = self.prefabPool:Allocate(self.MaskMap, szFrame)
    script:SetYaoLing(nType == SIGNPOST_NODE)
    return {
        node = node,
        script = script,
    }
end

function UIMainCityMiniMap:ShowMarkNode(nType, nID, x, y, szFrame, nUserData)
    if self.blockwidth == 0 then return end
    self.tbMarkNode[nType] = self.tbMarkNode[nType] or {}
    if not self.tbMarkNode[nType][nID] then
        self.tbMarkNode[nType][nID] = self:CreateMarkNode(nType, nID, szFrame)
    end
    local tNode = self.tbMarkNode[nType][nID]
    tNode.x, tNode.y = Scene_PlaneGameWorldPosToScene(x, y)
    tNode.nData = nUserData
    tNode.frame = szFrame
    return tNode
end

function UIMainCityMiniMap:RemoveMarkNode(nType, nID)
    if not self.tbMarkNode[nType] or not self.tbMarkNode[nType][nID] then
        return
    end
    self.prefabPool:Recycle(self.tbMarkNode[nType][nID].node)
    self.tbMarkNode[nType][nID] = nil
end



function UIMainCityMiniMap:SetMarkVisible(nType, nID, bVisible)
    if not self.tbMarkNode[nType] or not self.tbMarkNode[nType][nID] then
        return
    end
    UIHelper.SetVisible(self.tbMarkNode[nType][nID].node, bVisible)
end

function UIMainCityMiniMap:UpdateNodePosition(tNode)
    if not tNode then return end
    local size = self.MaskMap:getContentSize()
    local x, y = self:GetScenePosition(tNode.x, tNode.y)
    local dis = math.sqrt(math.pow(x, 2) + math.pow(y, 2))
    if tNode.limit and dis > tNode.limit then
        x = x / dis * tNode.limit
        y = y / dis * tNode.limit
        if tNode.limit_frame then
            tNode.script:SetFrame(tNode.limit_frame)
        end
    else
        tNode.script:SetFrame(tNode.frame)
    end
    if tNode.rotate then
        local nRadian = math.atan2(y, x) --弧度
        local nAngle = 90 -(nRadian * (180 / math.pi)) -- 角度
        if nAngle < 0 then nAngle = nAngle + 360 end
        UIHelper.SetRotation(tNode.node, nAngle)
    end
    UIHelper.SetPosition(tNode.node, x, y)
end

function UIMainCityMiniMap:UpdateNodesPosition()
    local tEnd = {}
    for nType, v in pairs(self.tbMarkNode) do
        if nType == DOODAD_NODE then
            local tbList = {}
            -- 排序后只显示最近的
            for nID, tNode in pairs(v) do
                local nCraftID = tNode.nData
                local x, y = self:GetScenePosition(tNode.x, tNode.y)
                tbList[nCraftID] = tbList[nCraftID] or {}
                table.insert(tbList[nCraftID], {nID, x * x + y * y})
            end
            for nCraftID, tb in pairs(tbList) do
                table.sort(tb, function(a, b) return a[2] < b[2] end)
            end
            for nID, tNode in pairs(v) do
                local tMinNode = tbList[tNode.nData][1]
                self:SetMarkVisible(nType, nID, tMinNode[1] == nID and Storage.MiddleMapData.bMiniMapShowCraft)
            end
        end
        for nID, tNode in pairs(v) do
            self:UpdateNodePosition(tNode)

            if tNode.nFrame then
                tNode.nFrame = tNode.nFrame - 1
                if tNode.nFrame <= 0 then
                    table.insert(tEnd, nID)
                end
            end
        end
        for _, nID in ipairs(tEnd) do
            self:RemoveMarkNode(nType, nID)
        end
    end
end

function UIMainCityMiniMap:OnExit()
    if self.nUpdateTimer then
        Timer.DelTimer(self, self.nUpdateTimer)
        self.nUpdateTimer = nil
    end

    if self.prefabPool then self.prefabPool:Dispose() end
    self.prefabPool = nil
end


function UIMainCityMiniMap:UpdateCurrentMap()
    local player = GetClientPlayer()
    if not player then
        return
    end
    local scene = player.GetScene()
	if not scene then
        LOG.ERROR("UIMainCityMiniMap:UpdateCurrentMap() not scene!")
		return
	end
    self.nMapID = scene.dwMapID
    UIHelper.SetString(self.LabelMapName, GBKToUTF8(Table_GetMapName(self.nMapID)), 6)

    local szPath = MapMgr.GetMapParams_UIEx(self.nMapID)
    self.szMinimapPath = szPath .. "minimap_mb/"
    local ini = Ini.Open(self.szMinimapPath .. "config.ini")
    if not ini then
        LOG.ERROR("UIMainCityMiniMap:UpdateCurrentMap() not ini config! szMinimapPath:%s", self.szMinimapPath)
        return
    end
    self.scale = ini:ReadFloat("config", "scale", 0)
    self.blockwidth = ini:ReadFloat("config", "width", 0)
    self.offsetx = ini:ReadFloat("config", "offsetx", 0)
    self.offsety = ini:ReadFloat("config", "offsety", 0)
    self.szImageMapPath = ini:ReadString("middlemap0", "image", "")

    -- temporary --
    self:UpdateImage()
end

function UIMainCityMiniMap:UpdateImage()
    local player = g_pClientPlayer
    if not player or not self.scale then
        return
    end
    local nMapID = player.GetMapID()
    if nMapID ~= self.nMapID then
        return
    end
    local x, y = Scene_PlaneGameWorldPosToScene(player.nX, player.nY)
    self.nPlayerX = x * self.scale
    self.nPlayerY = y * self.scale

    local nImagePlayerX = self.nPlayerX + self.offsetx
    local nImagePlayerY = self.nPlayerY + self.offsety

    -- TODO
    local nLayer = 0

    local nMaskWidth = WIDTH / MIMAP_SCALE
    local nMaskHeight = HEIGHT / MIMAP_SCALE

    --玩家所在小地图左右上下的坐标
    local fLeft = nImagePlayerX - nMaskWidth / 2
    local fRight = fLeft + nMaskWidth
    local fBottom = nImagePlayerY - nMaskHeight / 2
    local fTop = fBottom + nMaskHeight

    local nBlockWidth = self.blockwidth
    local bShowOneImg = nBlockWidth == 0 or self.szImageHover ~= nil

    for nIndex, img in ipairs(self.ImgMiniMapList) do
        UIHelper.SetActiveAndCache(self, img, false)
    end

    local szPath = self.szImageHover or self.szMinimapPath..self.szImageMapPath
    if Platform.IsMobile() then szPath = UIHelper.ConvertToMBPath(szPath) end
    UIHelper.SetActiveAndCache(self,self.ImgMiniMapBaiZhan, bShowOneImg)
    if self.szLastPath ~= szPath then
        UIHelper.SetTexture(self.ImgMiniMapBaiZhan, szPath, true)
        self.szLastPath = szPath
    end
    UIHelper.SetActiveAndCache(self, self.WidgetMark, not bShowOneImg)

    if bShowOneImg then
        return
    end

    local nLeft = math.floor(fLeft / self.blockwidth)
    local nRight = math.floor(fRight / self.blockwidth)
	local nBottom = math.floor(fBottom / self.blockwidth)
    local nTop = math.floor(fTop / self.blockwidth)

    local bFrameReload = false
    if self.nLeft ~= nLeft or self.nRight ~= nRight or self.nBottom ~= nBottom or self.nTop ~= nTop then
        bFrameReload = true
        self.nLeft = nLeft
        self.nRight = nRight
        self.nBottom = nBottom
        self.nTop = nTop
    end

    local nIndex = 1
    local fRelX = nLeft * self.blockwidth - fLeft - nMaskWidth / 2
    local fRelY = nBottom * self.blockwidth - fBottom - nMaskHeight / 2

    for i = nBottom, nTop do
        for j = nLeft, nRight do
            local img = self.ImgMiniMapList[nIndex]
            if bFrameReload then
                local szImage = string.format("%s%d_%d_%d.png", self.szMinimapPath, nLayer, i, j)
                if Platform.IsMobile() then szImage = UIHelper.ConvertToMBPath(szImage) end
                UIHelper.SetTexture(img, szImage)--UIHelper.SetTexture(img, szImage, false)
                UIHelper.SetContentSize(img, self.blockwidth * MIMAP_SCALE, self.blockwidth * MIMAP_SCALE)
            end
            local fX = fRelX + (j - nLeft) * self.blockwidth
            local fY = fRelY + (i - nBottom) * self.blockwidth

            fX = fX * MIMAP_SCALE
            fY = fY * MIMAP_SCALE

            if fX ~= self.tbImgPosMapX[img] or fY ~= self.tbImgPosMapY[img] then
                UIHelper.SetPosition(img, fX, fY)
                self.tbImgPosMapX[img] = fX
                self.tbImgPosMapY[img] = fY
            end

            UIHelper.SetActiveAndCache(self, img, true)
            --UIHelper.SetVisible(img, true)
            nIndex = nIndex + 1
        end
    end

end

function UIMainCityMiniMap:UpdateTeamMarkNode()
    local player = g_pClientPlayer
    local bFound = false
    local tbActive = {}
    TeamData.Generator(function(dwID, tMemberInfo)
        -- 绝境战场隐藏死亡和OB队友
        local bPlayHide = BattleFieldData.IsInTreasureBattleFieldMap() and (tMemberInfo.bDeathFlag or player.nBattleFieldSide == BattleFieldData.OB_BATTLE_FIELD_SIDE)

        if dwID ~= player.dwID and tMemberInfo.bIsOnLine and tMemberInfo.dwMapID == self.nMapID and not bPlayHide and player.IsPartyMemberInSameScene(dwID) then
            local tNode = self:ShowMarkNode(TEAMMATE_NODE, dwID, tMemberInfo.nPosX, tMemberInfo.nPosY, TEAMMATE_FRAME[1])
            if not tNode then return end
            tNode.limit = TRACE_LIMIT
            tNode.rotate = true
            tNode.limit_frame = TEAMMATE_FRAME[2]

            tbActive[dwID] = true
        end
        bFound = true
    end)
    for dwID, tNode in pairs(self.tbMarkNode[TEAMMATE_NODE] or {}) do
        tbActive[dwID] = tbActive[dwID] or false
    end

    for dwID, bActive in pairs(tbActive) do
        if not bActive then
            self:RemoveMarkNode(TEAMMATE_NODE, dwID)
        end
    end

    if not bFound then
        self:ClearTeamMark()
    end
end

function UIMainCityMiniMap:ClearTeamMark()
    if not self.tbMarkNode[TEAMMATE_NODE] or table.is_empty(self.tbMarkNode[TEAMMATE_NODE]) then
        return
    end
    for nID, tbNode in pairs(self.tbMarkNode[TEAMMATE_NODE]) do
        self.prefabPool:Recycle(tbNode.node)
    end

    self.tbMarkNode[TEAMMATE_NODE] = {}
end

function UIMainCityMiniMap:UpdateTraceNode()
    local szNpc, nMapID, tbPoint = MapMgr.GetTraceInfo()
    if nMapID and self.nMapID == nMapID then
        local nX, nY, _ = unpack(tbPoint)
        local tNode = self:ShowMarkNode(TRACE_NODE, 2, nX, nY, TRACE_FRAME[2])
        if not tNode then return end
        tNode.limit = TRACE_LIMIT
    else
        self:RemoveMarkNode(TRACE_NODE, 2)
    end
    tbPoint = MAIN_CITY_TRACE_POINT
    if tbPoint then
        local nX, nY, _ = unpack(tbPoint)
        local tNode = self:ShowMarkNode(TRACE_NODE, 1, nX, nY, TRACE_FRAME[1])
        if not tNode then return end
        tNode.limit = TRACE_LIMIT
    else
        self:RemoveMarkNode(TRACE_NODE, 1)
    end
end

function UIMainCityMiniMap:Update()
    local player = g_pClientPlayer
    if not player or not self.scale then
        return
    end
    local nRotation = MapMgr.GetPlayerRotation(player)
    self.ImgSelf:setRotation(nRotation)

    nRotation = MapMgr.GetCameraRotation()
    self.WidgetSelfCameraDirection:setRotation(nRotation)

    self:UpdateImage()
    self:UpdateTeamMarkNode()
    self:UpdateTraceNode()
    self:UpdateNodesPosition()
    self:UpdateCircleSFX()
    self:UpdateTeamSignPost()
end

function UIMainCityMiniMap:UpdateCircleSFX()
    self.tMapCircleSFX = self.tMapCircleSFX or {}

    for _, scriptSFX in pairs(self.tMapCircleSFX) do
        UIHelper.SetVisible(scriptSFX, false)
    end
    for i, circle in pairs(TreasureBattleFieldData.tCircle) do
        local tInfo = circle.tInfo
        local scriptSFX = self.tMapCircleSFX[i]
        if not scriptSFX then
            scriptSFX = cc.DrawNode:create()
            self.MaskMap:addChild(scriptSFX, 1)
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

        local nCenterX, nCenterY = Scene_PlaneGameWorldPosToScene(nX, nY)
        local nBorderX, nBorderY = Scene_PlaneGameWorldPosToScene(nX + nRadius , nY)

        local nCX, nCY = self:GetScenePosition(nCenterX, nCenterY)
        local nBX, nBY = self:GetScenePosition(nBorderX, nBorderY)
        local nR = math.sqrt((nCX-nBX) * (nCX-nBX) + (nCY-nBY) * (nCY-nBY))
        local tC = TreasureBattleFieldData.tMiniMapCircleColor[i] or cc.c4f(1, 1, 1, 1)

        scriptSFX:clear()
        scriptSFX:drawCircle(cc.p(nCX, nCY), nR, 360, step, false, tC)
    end
end

function UIMainCityMiniMap:UpdateTeamSignPost()
    local pingX, pingY = TeamData.GetSignPostPos()
    if pingX and pingY then
        local tNode = self:ShowMarkNode(SIGNPOST_NODE, 0, pingX, pingY, "")
        if not tNode then return end
        tNode.limit = TRACE_LIMIT
        self:UpdateNodePosition(tNode)
    else
        self:RemoveMarkNode(SIGNPOST_NODE, 0)
    end
end

function UIMainCityMiniMap:SetLabelNorthVis(bShow)
    if self.LabelNorth then
        UIHelper.SetVisible(self.LabelNorth, bShow)
    end
end

return UIMainCityMiniMap