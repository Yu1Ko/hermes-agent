local UIDungeonBossSkillStage = class("UIDungeonBossSkillStage")

function UIDungeonBossSkillStage:OnEnter(szName)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo(szName)
end

function UIDungeonBossSkillStage:OnExit()
    self.bInit = false
end

function UIDungeonBossSkillStage:BindUIEvent()
end

function UIDungeonBossSkillStage:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIDungeonBossSkillStage:UpdateInfo(szName)
    self.szName = szName
    UIHelper.SetString(self.LabelTitle, szName)
    UIHelper.LayoutDoLayout(self._rootNode)
end

return UIDungeonBossSkillStage