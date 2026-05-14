-- ---------------------------------------------------------------------------------
-- Author: CharacterHeadBuff
-- Name: NpcHeadBalloon
-- Date: 2024-10-10 10:49:31
-- Desc: ?
-- ---------------------------------------------------------------------------------
local BALLOON_VISIBLE_DISTANCE = 50 * 64
local NORMAL_SCALE_DISTANCE = 10 * 64
local CharacterHeadBuff = class("CharacterHeadBuff")
local DistancelScaleMin = 0.75
local MAX_CONTENT_LEN = 432

function CharacterHeadBuff:OnEnter(characterID, tBuffList, bTopBuff)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self.scriptTopBuff = UIHelper.GetBindScript(self.LayoutHeadBuff2)

        self.tBuffCellScrips = {}
        for nIndex = 1, 2 do
            self.tBuffCellScrips[nIndex] = UIHelper.AddPrefab(PREFAB_ID.WidgetMainCityHeadBuff, self.LayoutHeadBuff)
            UIHelper.SetVisible(self.tBuffCellScrips[nIndex]._rootNode, false)
        end
    end

    if bTopBuff and self.scriptTopBuff then
        self.bTopBuff = bTopBuff
        UIHelper.SetOpacity(self._rootNode, 255)
        UIHelper.SetVisible(self.LayoutHeadBuff, false)
        UIHelper.SetVisible(self.LayoutHeadBuff2, true)
        self.scriptTopBuff:OnEnter(characterID, self._rootNode)
        return
    end

    self.characterID = characterID
    self.tBuffList = tBuffList
    self.bShow = true
    self.bIsDelete = false

    if not tBuffList or #tBuffList <= 0 then
        self:HideNode()
        return
    end

    UIHelper.SetVisible(self._rootNode, true)
    self:UpdateInfo()
end

function CharacterHeadBuff:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function CharacterHeadBuff:BindUIEvent()

end

function CharacterHeadBuff:RegEvent()
    Event.Reg(self, EventType.SetNpcHeadBallonVisible, function(bVisible)
        if self.bTopBuff then return end
        UIHelper.SetOpacity(self._rootNode, bVisible and 255 or 0)
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function(width, height)
        if self.bTopBuff then return end
        self:UpdateInfo(true)
    end)
end

function CharacterHeadBuff:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function CharacterHeadBuff:SetBuff()
    for nIndex = 1, 2 do
        local tBuffInfo = self.tBuffList[nIndex]
        local script = self.tBuffCellScrips[nIndex]
        if tBuffInfo then
            script:UpdateBuffImage(tBuffInfo.dwID, tBuffInfo.nLevel, tBuffInfo.nStackNum, tBuffInfo.nEndFrame)
        end
        UIHelper.SetVisible(self.tBuffCellScrips[nIndex]._rootNode, tBuffInfo ~= nil)
    end

    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
end

function CharacterHeadBuff:UpdateInfo(bReUpdate)
    local player = GetClientPlayer()
    if not player then
        self:HideNode()
        return
    end
    self:SetBuff()

    local dwPlayerID = player.dwID
    Timer.DelAllTimer(self)
    local nDistance = 0
    if self.characterID ~= dwPlayerID then
        nDistance = GetCharacterDistance(self.characterID, dwPlayerID)
        if nDistance > BALLOON_VISIBLE_DISTANCE then
            LOG.INFO("NpcHeadBalloon,characterID = %d, nDistance = %d, too far, can not be show. szContent= %s", nDistance, self.characterID, self.szContent)
            self:HideNode()
            return
        end
    end

    local arrawW, arrawH = UIHelper.GetContentSize(self.LayoutHeadBuff)
    if not bReUpdate then
        local layoutWidth, layoutHeight = UIHelper.GetContentSize(self._rootNode)
        UIHelper.SetPosition(self.LayoutHeadBuff, layoutWidth * 0.5, 0)
    end

    local screenSize = UIHelper.GetSafeAreaRect()
    local pw, ph = screenSize.width, screenSize.height
    local scaleX, scaley = UIHelper.GetScreenToResolutionScale()
    local width, height = UIHelper.GetContentSize(self._rootNode)

    scaleX = 1 / scaleX
    scaley = 1 / scaley
    local baseOffsetY = ph * 0.5 + height * 0.5
    local baseOffsetX = -pw * 0.5 - width * 0.5

    baseOffsetX = baseOffsetX + 50 -- 偏移量在此处修改
    baseOffsetY = baseOffsetY + 0 -- 偏移量在此处修改

    self:UpdatePos(dwPlayerID, width, height, scaleX, scaley, baseOffsetX, baseOffsetY)
    UIHelper.SetOpacity(self._rootNode, 255)

    self.nCycleTimeID = Timer.AddFrameCycle(self, 1, function()
        self:UpdatePos(dwPlayerID, width, height, scaleX, scaley, baseOffsetX, baseOffsetY)
    end)
end

function CharacterHeadBuff:UpdatePos(dwPlayerID, width, height, scaleX, scaley, baseOffsetX, baseOffsetY)
    local fnCallback = function(screenX, screenY)
        if self.bIsDelete then
            return
        end

        local position = GetCharacterTopScreenXYZ(self.characterID)
        if position.z < 0 and self.bShow then
            self:HideNode()
            return
        end
        if not self.bShow then
            self.bShow = true
            UIHelper.SetVisible(self._rootNode, true)
        end

        local nDistance = GetCharacterDistance(self.characterID, dwPlayerID)
        local contentScale = 1
        if Platform.IsWindows() then
            contentScale = 0.82
        end
        if nDistance > NORMAL_SCALE_DISTANCE then
            local nCoefficient = (BALLOON_VISIBLE_DISTANCE - (nDistance - NORMAL_SCALE_DISTANCE) * 2) / BALLOON_VISIBLE_DISTANCE
            contentScale = contentScale * math.max(DistancelScaleMin, nCoefficient)
        end
        if nDistance > BALLOON_VISIBLE_DISTANCE or contentScale < 0 then
            self:HideNode()
            return
        end

        local scaleOffsetX = width * 0.5
        local scaleOffsetY = height * 0.5 * scaley
        local offsetX = baseOffsetX + (1 - contentScale) * scaleOffsetX
        local offsetY = baseOffsetY - (1 - contentScale) * scaleOffsetY
        local position = { x = screenX, y = screenY }

        UIHelper.SetPosition(self._rootNode, position.x * scaleX + offsetX, -position.y * scaley + offsetY)
        UIHelper.SetScale(self._rootNode, contentScale, contentScale)
    end

    local nX, nY = Scene_GetCharacterTopScreenPosX3D(self.characterID)
    fnCallback(nX, nY)
end

function CharacterHeadBuff:HideNode(bDelete)
    if bDelete then
        self.bIsDelete = true
    end

    if self.nCycleTimeID then
        Timer.DelAllTimer(self)
        self.nCycleTimeID = nil
    end
    self.bShow = false
    UIHelper.SetVisible(self._rootNode, false)

    for nIndex = 1, 2 do
        self.tBuffCellScrips[nIndex]:Stop()
    end
end

return CharacterHeadBuff