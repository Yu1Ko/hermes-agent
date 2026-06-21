local UIDungeonProgressPoint = class("UIDungeonProgressPoint")

function UIDungeonProgressPoint:OnEnter(bKilled, szName)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo(bKilled, szName)
end

function UIDungeonProgressPoint:OnExit()
    self.bInit = false
end

function UIDungeonProgressPoint:BindUIEvent()
end

function UIDungeonProgressPoint:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIDungeonProgressPoint:UpdateInfo(bKilled, szName)
    UIHelper.SetVisible(self.LabelBossUp, not bKilled)
    UIHelper.SetVisible(self.ImgRateLine, bKilled)

    UIHelper.SetString(self.LabelBoss, szName)
    UIHelper.SetString(self.LabelBossUp, szName)
end

return UIDungeonProgressPoint