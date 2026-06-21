local UIDungeonSyncProgressView = class("UIDungeonSyncProgressView")

function UIDungeonSyncProgressView:OnEnter(dwMapID, nCopyIndex, nLeftTime, tpbyProgress)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo(dwMapID, nCopyIndex, nLeftTime, tpbyProgress)
    Timer.AddFrameCycle(self, 15, function ()
        self:OnFrameBreathe()
    end)
end

function UIDungeonSyncProgressView:OnExit()
    self.bInit = false
end

function UIDungeonSyncProgressView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
		UIMgr.Close(VIEW_ID.PanelDungeonChallengeSync)
        GetClientPlayer().CancelSyncMapProgress()
	end)

    UIHelper.BindUIEvent(self.BtnQuit, EventType.OnClick, function()
		UIMgr.Close(VIEW_ID.PanelDungeonChallengeSync)
        GetClientPlayer().CancelSyncMapProgress()
	end)

    UIHelper.BindUIEvent(self.BtnSynchronize, EventType.OnClick, function()
		UIMgr.Close(VIEW_ID.PanelDungeonChallengeSync)
        GetClientPlayer().ComfirmSyncMapProgress()
	end)
end

function UIDungeonSyncProgressView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIDungeonSyncProgressView:OnFrameBreathe()
    local nLeftTime = self.nEndTime - GetTickCount()
    self:RefreshProgressTips()
    if nLeftTime >= 0 then
        local szTime = UIHelper.GetHeightestTimeText(nLeftTime/1000)
        UIHelper.SetString(self.LabelTimeNum, szTime)
    else
        UIMgr.Close(VIEW_ID.PanelDungeonChallengeSync)
        GetClientPlayer().CancelSyncMapProgress()
    end
end

function UIDungeonSyncProgressView:UpdateInfo(dwMapID, nCopyIndex, nLeftTime, tpbyProgress)
    self.dwMapID = dwMapID
    self.tpbyProgress = tpbyProgress
    self.nEndTime = nLeftTime*1000 + GetTickCount()
    local player = GetClientPlayer()
    local dwPlayerID = player and player.dwID
    if not dwPlayerID then
        return
    end
    self.tScriptList = {}
    UIHelper.SetVisible(self.WidgetBaizhan, MonsterBookData.bIsPlaying)
    UIHelper.SetVisible(self.WidgetNormalDungeon, not MonsterBookData.bIsPlaying)
    UIHelper.RemoveAllChildren(self.ScrollViewSign)
    local tBossList = Table_GetCDProcessBoss(dwMapID)
    if not tBossList then
        return
    end
    for i=1,#tBossList do
        local tBoss = tBossList[i]
        local bTeamPass = false
        for _, nBossID in ipairs(tpbyProgress) do
            if nBossID == tBoss.dwProgressID then
                bTeamPass = true
                break
            end
        end

        local szBossName = UIHelper.GBKToUTF8(tBoss.szName)
        local scriptSign = UIHelper.AddPrefab(PREFAB_ID.WidgetSign, self.ScrollViewSign, szBossName, false)
        if bTeamPass and scriptSign then
            scriptSign:UpdateTeamMarkInfo(true)
        end
        local bPersonalPass = GetDungeonRoleProgress(dwMapID, dwPlayerID, tBoss.dwProgressID)
        if bPersonalPass and scriptSign then
            scriptSign:UpdatePersionalMarkInfo(true)
        end
        table.insert(self.tScriptList, scriptSign)
    end
    
    UIHelper.ScrollViewDoLayout(self.ScrollViewSign)
    UIHelper.ScrollToLeft(self.ScrollViewSign, 0)
end

function UIDungeonSyncProgressView:RefreshProgressTips()
    local bPeopleLeft = false
    local bPeopleRight = false
    local bTeamLeft = false
    local bTeamRight = false

    local nLeftLimitX = UIHelper.GetWorldPositionX(self.ScrollViewSign)
    local nRightLimitX = nLeftLimitX + UIHelper.GetWidth(self.ScrollViewSign)
    for _, scriptSign in ipairs(self.tScriptList) do
        local nPosX = UIHelper.GetWorldPositionX(scriptSign._rootNode)
        local nNearPosX = nPosX + UIHelper.GetWidth(scriptSign._rootNode) / 2 - UIHelper.GetWidth(scriptSign.ImgTeamIcon) / 2
        local nFarPosX = nPosX + UIHelper.GetWidth(scriptSign._rootNode) / 2 + UIHelper.GetWidth(scriptSign.ImgTeamIcon) / 2

        bPeopleLeft = bPeopleLeft or (scriptSign.bIsPersional and nFarPosX < nLeftLimitX)
        bPeopleRight = bPeopleRight or (scriptSign.bIsPersional and nNearPosX > nRightLimitX)
        bTeamLeft = bTeamLeft or (scriptSign.bIsTeam and nFarPosX < nLeftLimitX)
        bTeamRight = bTeamRight or (scriptSign.bIsTeam and nNearPosX > nRightLimitX)
    end

    UIHelper.SetVisible(self.ImgTeamBgLeft, bTeamLeft)
    UIHelper.SetVisible(self.ImgTeamBgRight, bTeamRight)
    UIHelper.SetVisible(self.ImgPeopleBgLeft, bPeopleLeft)
    UIHelper.SetVisible(self.ImgPeopleBgRight, bPeopleRight)
end

return UIDungeonSyncProgressView