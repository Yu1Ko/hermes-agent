local UIWidgetMonsterBookBossHead = class("UIWidgetMonsterBookBossHead")

function UIWidgetMonsterBookBossHead:OnEnter(dwBossIndex, tMonsterBossList)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo(dwBossIndex, tMonsterBossList)
end

function UIWidgetMonsterBookBossHead:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMonsterBookBossHead:BindUIEvent()

end

function UIWidgetMonsterBookBossHead:RegEvent()

end

function UIWidgetMonsterBookBossHead:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetMonsterBookBossHead:UpdateInfo(dwBossIndex, tMonsterBossList)
    
end

function UIWidgetMonsterBookBossHead:GetPlayerList()
    local team = GetClientTeam()
    return team and team.GetTeamMemberList() or {}  --- 要确认一下是不是需要把返回值作为参数传递进去
end

return UIWidgetMonsterBookBossHead