local UIDungeonListCell = class("UIDungeonListCell")

function UIDungeonListCell:OnEnter(szName)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo(szName)
end

function UIDungeonListCell:OnExit()
    self.bInit = false
end

function UIDungeonListCell:BindUIEvent()
end

function UIDungeonListCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIDungeonListCell:UpdateInfo(szName)
    self.szName = szName
    UIHelper.SetString(self.LabelTitle, szName)
end

return UIDungeonListCell