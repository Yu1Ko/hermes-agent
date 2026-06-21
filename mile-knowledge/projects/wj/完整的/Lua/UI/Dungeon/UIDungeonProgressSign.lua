local UIDungeonProgressSign = class("UIDungeonProgressSign")

function UIDungeonProgressSign:OnEnter(szName)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo(szName)
end

function UIDungeonProgressSign:OnExit()
    self.bInit = false
end

function UIDungeonProgressSign:BindUIEvent()
end

function UIDungeonProgressSign:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIDungeonProgressSign:UpdateInfo(szName)
    self.szName = szName
    UIHelper.SetString(self.LabelTeammate, szName)

    UIHelper.SetVisible(self.ImgPeopleIcon, self.bIsPersional)
    UIHelper.SetVisible(self.ImgTeamIcon, self.bIsTeam) 
end

function UIDungeonProgressSign:UpdatePersionalMarkInfo(bIsPersional)
    self.bIsPersional = bIsPersional
    UIHelper.SetVisible(self.ImgPeopleIcon, bIsPersional)
end

function UIDungeonProgressSign:UpdateTeamMarkInfo(bIsTeam)
    self.bIsTeam = bIsTeam
    UIHelper.SetVisible(self.ImgTeamIcon, bIsTeam) 
end

return UIDungeonProgressSign