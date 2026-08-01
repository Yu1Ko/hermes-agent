local UIMonsterBookSEHint = class("UIMonsterBookSEHint")

local _nDragThreshold2 = 450
local BUFF_ANGER = 32544
local BUFF_TENACITY = 22093

function UIMonsterBookSEHint:OnEnter(dwTargetType, dwTargetID, bTarget)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.dwTargetType = dwTargetType
    self.dwTargetID = dwTargetID
    self.bTarget = bTarget
    UIHelper.SetProgressBarStarPercentPt(self.ImgJing, 0, 0)
    UIHelper.SetProgressBarPercent(self.ImgJing, 0)
    UIHelper.SetProgressBarStarPercentPt(self.ImgNai, 0, 0)
    UIHelper.SetProgressBarPercent(self.ImgNai, 0)
    UIHelper.SetSwallowTouches(self.BtnMove, true)

    self:InitData()
    self:OnFrameBreathe()
    self.nTimerID = self.nTimerID or Timer.AddFrameCycle(self, 30, function ()
        self:OnFrameBreathe()
    end)
end

function UIMonsterBookSEHint:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIMonsterBookSEHint:BindUIEvent()
    if self.bCanMove then self:BindMoveFunction() end
end

function UIMonsterBookSEHint:RegEvent()
    Event.Reg(self, "QUEST_FINISHED", function(nQuestID, bForceFinish, bAssist, nAddStamina, nAddThew)
        if nQuestID == MonsterBookData.dwSEInfoPreQuestID then
            UIHelper.SetVisible(self._rootNode, MonsterBookData.IsFinishSEInfoPreQuest())
        end
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function ()
        self:InitData()
    end)

    Event.Reg(self, "BUFF_UPDATE", function ()
        self:UpdateAngry()
    end)
end

function UIMonsterBookSEHint:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIMonsterBookSEHint:InitData()
    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelMainCity)
    if not scriptView then return end

    self.nCenterX, self.nCenterY = UIHelper.GetWorldPosition(scriptView._rootNode)
    self.nWidth, self.nHeight = UIHelper.GetContentSize(scriptView._rootNode)
    local nCellWidth, nCellHeight = UIHelper.GetContentSize(self._rootNode)
    self.nMinX = self.nCenterX - self.nWidth / 2 + nCellWidth / 2
    self.nMaxX = self.nCenterX + self.nWidth / 2 - nCellWidth / 2
    self.nMinY = self.nCenterY - self.nHeight / 2 + nCellHeight / 2
    self.nMaxY = self.nCenterY + self.nHeight / 2 - nCellHeight / 2
end
function UIMonsterBookSEHint:OnFrameBreathe()
    UIHelper.SetVisible(self._rootNode, MonsterBookData.bIsPlaying)
    if not MonsterBookData.bIsPlaying then
        return
    end
    local player = GetClientPlayer()
    if not player then return end
	local tSpiritAndEnduranValue = GDAPI_SpiritEndurance_GetPlayerData(player)
    if not tSpiritAndEnduranValue or table.GetCount(tSpiritAndEnduranValue) == 0 then
        return
    end
    local nSpiritValue = tSpiritAndEnduranValue[1]
	local nSpiritMaxValue = tSpiritAndEnduranValue[2]
	local nEenduranceValue = tSpiritAndEnduranValue[3]
	local nEenduranceMaxValue = tSpiritAndEnduranValue[4]
    MonsterBookData.SetLastSpiritValue(player.dwID, nSpiritValue)
    MonsterBookData.SetLastEnduranceValue(player.dwID, nEenduranceValue)
    local tSpiritEndurancePlayer, tSpiritEnduranceNPC = GDAPI_SpiritEndurance_GetTargetData(player)
    if self.bTarget then
        local tSEData = {}        
        if TypeIsPlayer(self.dwTargetType, self.dwTargetID) then
            tSEData = tSpiritEndurancePlayer or {}
        elseif TypeIsNpc(self.dwTargetType, self.dwTargetID) then
            tSEData = tSpiritEnduranceNPC or {}
        end
        local bFindData = false
        for _, tData in pairs(tSEData) do
            if tData[5] == self.dwTargetID then
                bFindData = true
                nSpiritValue = tData[1]
                nSpiritMaxValue = tData[2]
                nEenduranceValue = tData[3]
                nEenduranceMaxValue = tData[4]
                MonsterBookData.SetLastSpiritValue(self.dwTargetID, nSpiritValue)
                MonsterBookData.SetLastEnduranceValue(self.dwTargetID, nEenduranceValue)
                break
            end
        end
        UIHelper.SetVisible(self._rootNode, bFindData)
        if not bFindData then
            return
        end
    end

    if nSpiritMaxValue == 0 then
        nSpiritValue = 0
        nSpiritMaxValue = 1
    end
    if nEenduranceMaxValue == 0 then
        nEenduranceValue = 0
        nEenduranceMaxValue = 0
    end
    local nSpiritPecent = nSpiritValue / nSpiritMaxValue
    local nEendurancePecent = nEenduranceValue / nEenduranceMaxValue
    local szSpirit = string.format("%d%%", math.floor(nSpiritPecent*100))
    local szEndurance = string.format("%d%%", math.floor(nEendurancePecent*100))
    UIHelper.SetString(self.LabelJing, szSpirit)
    UIHelper.SetString(self.LabelNai, szEndurance)

    UIHelper.SetProgressBarPercent(self.ImgJing, nSpiritPecent * 100)
    UIHelper.SetProgressBarPercent(self.ImgNai, nEendurancePecent * 100)
    UIHelper.SetVisible(self._rootNode, MonsterBookData.IsFinishSEInfoPreQuest())
    self:UpdateAngry()
end

function UIMonsterBookSEHint:UpdateAngry()
    if not self.bTarget then
        UIHelper.SetVisible(self.BtnATenacity, false)
        return
    end

    local dwID = self.dwTargetID
    local hTarget = GetNpc(dwID)
    if not hTarget then
        UIHelper.SetVisible(self.BtnATenacity, false)
        return
    end
    local tBuffAnger    = {}
    local tBuffTenacity = {}
    Buffer_GetByID(hTarget, BUFF_ANGER, 1, tBuffAnger)
    Buffer_GetByID(hTarget, BUFF_TENACITY, 1, tBuffTenacity)

    --怒气值
    local nAnger = tBuffAnger and tBuffAnger.nStackNum or 0
    UIHelper.SetString(self.LabelAnger, nAnger .. "%")
    UIHelper.SetProgressBarPercent(self.ImgAnger, nAnger)
    
    --韧性值
    local nTenacity = tBuffTenacity and tBuffTenacity.nStackNum or 0
    UIHelper.SetString(self.LabelTenacity, nTenacity .. "%")
    UIHelper.SetProgressBarPercent(self.ImgTenacity, nTenacity)
    MapMgr.tShowMonsterAnger[dwID] = MapMgr.tShowMonsterAnger[dwID] or nAnger > 0 or nTenacity > 0
    UIHelper.SetVisible(self.BtnATenacity, MapMgr.tShowMonsterAnger[dwID])
end

function UIMonsterBookSEHint:BindMoveFunction()
    UIHelper.BindUIEvent(self.BtnMove, EventType.OnTouchBegan, function(btn, nX, nY)
        self.nTouchBeganX, self.nTouchBeganY = nX, nY
        self.bDragging = false
        return true
    end)

    UIHelper.BindUIEvent(self.BtnMove, EventType.OnTouchMoved, function(btn, nX, nY)
        if not self.bDragging then
            local dx = nX - self.nTouchBeganX
            local dy = nY - self.nTouchBeganY
            local dx2 = dx * dx
            local dy2 = dy * dy
            if dx2 + dy2 > _nDragThreshold2 then
                self.bDragging = self:OnDragStart(nX, nY)  -- 成功触发拖动
            end
        end

        if self.bDragging then
            self:OnDragMoved(nX, nY)
        end
    end)

    UIHelper.BindUIEvent(self.BtnMove, EventType.OnTouchEnded, function(btn, nX, nY)
        if self.bDragging then
            self:OnDragEnd(nX, nY)
            self.bDragging = false
        end

    end)

    UIHelper.BindUIEvent(self.BtnMove, EventType.OnTouchCanceled, function(btn, nX, nY)
        if self.bDragging then
            self:OnDragEnd(nX, nY)
            self.bDragging = false
        end
    end)
end

function UIMonsterBookSEHint:OnDragStart(nPosX, nPosY)
    return true
end

function UIMonsterBookSEHint:OnDragMoved(nPosX, nPosY)
    if nPosX < self.nMinX then nPosX = self.nMinX end
    if nPosX > self.nMaxX then nPosX = self.nMaxX end
    if nPosY < self.nMinY then nPosY = self.nMinY end
    if nPosY > self.nMaxY then nPosY = self.nMaxY end

    UIHelper.SetWorldPosition(self._rootNode, nPosX, nPosY)
end

function UIMonsterBookSEHint:OnDragEnd(nPosX, nPosY)

end

return UIMonsterBookSEHint