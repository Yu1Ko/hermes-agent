local UIWidgetMonsterBookProgressCell = class("UIWidgetMonsterBookProgressCell")

local _XIULUO_BOSS_GROUP = 10002

function UIWidgetMonsterBookProgressCell:OnEnter(dwBossIndex, tMonsterBossList)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo(dwBossIndex, tMonsterBossList)
end

function UIWidgetMonsterBookProgressCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMonsterBookProgressCell:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnClick, function ()
        TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetDefeatedBossTips, self.ToggleSelect, MonsterBookData.PLAY_MAP_ID, self.tMonsterBossList, true)
    end)
end

function UIWidgetMonsterBookProgressCell:RegEvent()
    Event.Reg(self, "UPDATE_DUNGEON_ROLE_PROGRESS", function (dwMapID, dwPlayerID)
        if dwMapID == MonsterBookData.PLAY_MAP_ID and dwPlayerID == UI_GetClientPlayerID() then
            self:RefreshProgress()
        end        
    end)
end

function UIWidgetMonsterBookProgressCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetMonsterBookProgressCell:UpdateInfo(dwBossIndex, tMonsterBossList)
    self.tMonsterBossList = tMonsterBossList
    local tBoss = tMonsterBossList[1]
    local szBossName = UIHelper.GBKToUTF8(tBoss.szName)
    if tBoss.nGroup == _XIULUO_BOSS_GROUP then szBossName = g_tStrings.MONSTER_BOOK_BOSS_GROUP_XIULUO1 end
    UIHelper.SetString(self.LabelBossName, szBossName)

    self:RefreshProgress()
end

function UIWidgetMonsterBookProgressCell:RefreshProgress()
    local dwPlayerID = UI_GetClientPlayerID()
    local nTotalProgress = #self.tMonsterBossList
    if nTotalProgress == 0 then
        return
    end
    
    for nIndex, ImgPoint in ipairs(self.tImgPoints) do
        local bVisible =  nIndex <= nTotalProgress
        if bVisible then
            local tBoss = self.tMonsterBossList[nIndex]
            local bKilled = GetDungeonRoleProgress(MonsterBookData.PLAY_MAP_ID, dwPlayerID, tBoss.dwProgressID)
            UIHelper.SetVisible(ImgPoint, bKilled)
        end
        UIHelper.SetVisible(UIHelper.GetParent(ImgPoint), bVisible)
    end
end

function UIWidgetMonsterBookProgressCell:GetPlayerList()
    local team = GetClientTeam()
    return team and team.GetTeamMemberList() or {}  --- 要确认一下是不是需要把返回值作为参数传递进去
end

return UIWidgetMonsterBookProgressCell