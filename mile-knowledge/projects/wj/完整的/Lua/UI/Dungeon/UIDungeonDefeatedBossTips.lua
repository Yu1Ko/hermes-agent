local UIDungeonDefeatedBossTips = class("UIDungeonDefeatedBossTips")

local LEVEL_STAGE = {
    "（一阶）",
    "（二阶）",
    "（三阶）",
    "（四阶）",
    "（五阶）",
    "（六阶）",
    "（七阶）",
    "（八阶）",
    "（九阶）",
    "（十阶）",
}
function UIDungeonDefeatedBossTips:OnEnter(dwMapID, tBossList, bMonsterBook)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    if not tBossList then
        self:UpdateInfo(dwMapID)
    else
        self:UpdateProgressByBoss(dwMapID, tBossList, bMonsterBook)
    end
end

function UIDungeonDefeatedBossTips:OnExit()
    self.bInit = false
end

function UIDungeonDefeatedBossTips:BindUIEvent()
end

function UIDungeonDefeatedBossTips:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIDungeonDefeatedBossTips:UpdateInfo(dwMapID)
    local aProgressIDs = {}
    local aBossProcessInfoList = Table_GetCDProcessBoss(dwMapID)
    for j = 1, #aBossProcessInfoList do
        table.insert(aProgressIDs, aBossProcessInfoList[j].dwProgressID)
    end
    local player = GetClientPlayer()
    local dwPlayerID = player and player.dwID
    if dwPlayerID then
        self:RefreshKillBossProgress(dwMapID, dwPlayerID, aProgressIDs)
    end
end

function UIDungeonDefeatedBossTips:RefreshKillBossProgress(dwMapID, dwPlayerID, aProgressIDs)
    self.aKillingState = {}
    UIHelper.RemoveAllChildren(self.LayoutBoss)
    for i = 1, #aProgressIDs do
		local nProgressID = aProgressIDs[i]
		local bHasKilled = GetDungeonRoleProgress(dwMapID, dwPlayerID, nProgressID)
		table.insert(self.aKillingState, bHasKilled)
        local tBoss = Table_GetBoss(dwMapID, nProgressID)
        if tBoss then
            local szBossName = UIHelper.GBKToUTF8(tBoss.szName)
            UIHelper.AddPrefab(PREFAB_ID.WidgetKillBossState, self.LayoutBoss, bHasKilled, szBossName)   
        end		     
	end
    UIHelper.LayoutDoLayout(self.LayoutBoss)
end

function UIDungeonDefeatedBossTips:UpdateProgressByBoss(dwMapID, tBossList, bMonsterBook)
    UIHelper.RemoveAllChildren(self.LayoutBoss)
    for i = 1, #tBossList do
        local tBoss = tBossList[i]
		local nProgressID = tBoss.dwProgressID
		local bHasKilled = GetDungeonRoleProgress(dwMapID, UI_GetClientPlayerID(), nProgressID)
        if tBoss then
            local szBossName = UIHelper.GBKToUTF8(tBoss.szName)
            local szLevel = LEVEL_STAGE[tBoss.nSteps]
            if bMonsterBook and szLevel then
                szBossName = szBossName..LEVEL_STAGE[tBoss.nSteps]
            end
            UIHelper.AddPrefab(PREFAB_ID.WidgetKillBossState, self.LayoutBoss, bHasKilled, szBossName)   
        end		     
	end
    UIHelper.LayoutDoLayout(self.LayoutBoss)
end

return UIDungeonDefeatedBossTips