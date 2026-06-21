local UIWidgetMonsterBookTeamProgress = class("UIWidgetMonsterBookTeamProgress")

local _CRITICAL_BOSS_GROUP = 10001
local _XIULUO_BOSS_GROUP = 10002

function UIWidgetMonsterBookTeamProgress:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.bNeedReset = true
    self:InitData()
    self:UpdateInfo()
end

function UIWidgetMonsterBookTeamProgress:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMonsterBookTeamProgress:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)
end

function UIWidgetMonsterBookTeamProgress:RegEvent()
    Event.Reg(self, "UPDATE_DUNGEON_ROLE_PROGRESS", function ()
        self:UpdateInfo()
    end)
end

function UIWidgetMonsterBookTeamProgress:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIWidgetMonsterBookTeamProgress:InitData()
    self.nSelectGroup      = 6
    self.nSelectProgressID = nil

    if not self.bInited or self.bNeedReset then
		if self.bNeedReset then
            self.dwMapID = 0
			self:InitBossList() -- {[nGroup] = {tInfo_1, tInfo_2, ...},}
			self.bNeedReset = false
		end
		self.bInited = true
	end
    
    for _, dwPlayerID in ipairs(self:GetPlayerList()) do
        ApplyDungeonRoleProgress(self.dwMapID, dwPlayerID)
    end

    self.scriptBossKillTip = UIHelper.AddPrefab(PREFAB_ID.WidgetBossKillNoRewardTip, self.WidgetBossKillNoRewardTipShell)
    UIHelper.SetVisible(self.WidgetBossKillNoRewardTipShell, false)
end

function UIWidgetMonsterBookTeamProgress:InitBossList()
    local scene = g_pClientPlayer.GetScene()
    if not scene then return end

    self.dwMapID = scene.dwMapID
    if self.dwMapID == MonsterBookData.PLAY_MAP_ID then
        self.tBoss = Table_GetMonsterBossBySteps()
    else
        self.tBoss = {[1] = GetCDProcessInfo(self.dwMapID)}
    end
end

function UIWidgetMonsterBookTeamProgress:GetPlayerList()
    local team = GetClientTeam()
    return team and team.GetTeamMemberList() or {}
end

function UIWidgetMonsterBookTeamProgress:GetKillerList(dwProgressID)
    local tKillerList = {}
    local tPlayerList = self:GetPlayerList()
    if dwProgressID and tPlayerList then
        for _, dwPlayerID in ipairs(tPlayerList) do
            local bHasKilled = GetDungeonRoleProgress(self.dwMapID, dwPlayerID, dwProgressID)
            if bHasKilled then
                table.insert(tKillerList, dwPlayerID)
            end
        end
    end
    return tKillerList
end

function UIWidgetMonsterBookTeamProgress:UpdateInfo()
    self:UpdateTabList()
end

function UIWidgetMonsterBookTeamProgress:UpdateTabList()
    UIHelper.RemoveAllChildren(self.ScrollViewTabLeft)
    local tKeyList = {}
    for nKey,_ in pairs(self.tBoss) do
        table.insert(tKeyList, nKey)
    end
    table.sort(tKeyList, function (a, b)
        return a < b
    end)

    for nIndex, nGroup in ipairs(tKeyList) do
        local szText = g_tStrings.MONSTER_BOOK_BOSS_GROUP_SIMPLE
        if nGroup == _CRITICAL_BOSS_GROUP then
            szText = g_tStrings.MONSTER_BOOK_BOSS_GROUP_MAX
        elseif nGroup == _XIULUO_BOSS_GROUP then
            szText = g_tStrings.MONSTER_BOOK_BOSS_GROUP_XIULUO
        elseif nGroup >= 1 then
            local szNumber = UIHelper.NumberToChinese(nGroup)
            szText = FormatString(g_tStrings.MONSTER_BOOK_GROUP, szNumber) .. g_tStrings.MONSTER_BOOK_BOSS
        end
        local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetListTogBaiZhanCell, self.ScrollViewTabLeft)
        scriptCell:OnEnter(szText, function ()
            self.nSelectGroup = nGroup
            self:UpdateBossList()
        end)
        if nIndex == 1 then
            UIHelper.SetSelected(scriptCell.ToggleSelect, true, false)
            scriptCell.fCallBack()
        end
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTabLeft)
end

function UIWidgetMonsterBookTeamProgress:UpdateBossList()
    local tBossInfoList = self.tBoss[self.nSelectGroup]
	if not tBossInfoList then
		return
	end

    UIHelper.RemoveAllChildren(self.ScrollViewBossList)
    local bFirst = true
    for nIndex, tBossInfo in pairs(tBossInfoList) do
        local dwProgressID = tBossInfo.dwProgressID or tBossInfo.ProgressID
        local tBossParam = {}
        if tBossInfo.BossIndex then
            local dwBossIndex = tBossInfo.BossIndex
            local aNpcList = Table_GetDungeonBossNpcListByBossIndex(dwBossIndex) or {}
            local dwNpcIndex = aNpcList[1]
            tBossParam.dwNpcIndex = dwNpcIndex or 0
        else
            tBossParam.dwNpcID = tBossInfo.dwNpcID
        end
        tBossParam.szBossName = UIHelper.GBKToUTF8(tBossInfo.szName or tBossInfo.Name)
        tBossParam.dwMapID = self.dwMapID
        tBossParam.dwProgressID = dwProgressID
        tBossParam.nTotalPlayers = #self:GetPlayerList()
        tBossParam.tTotalPlayerList = self:GetPlayerList()
        tBossParam.tKillerList = self:GetKillerList(dwProgressID)
        tBossParam.nHasNotKilledPlayerNum = tBossParam.nTotalPlayers - #tBossParam.tKillerList
        local scriptBoss = UIHelper.AddPrefab(PREFAB_ID.WidgetBossListItem, self.ScrollViewBossList)
        scriptBoss:OnEnter(tBossParam, function ()
            self.scriptBossKillTip:OnEnter(tBossParam)
            UIHelper.SetVisible(self.WidgetBossKillNoRewardTipShell, true)
        end)
        if bFirst then
            bFirst = false
            UIHelper.SetSelected(scriptBoss.ToggleSelect, true, false)
            scriptBoss.fCallBack()
        end
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewBossList)
end

return UIWidgetMonsterBookTeamProgress