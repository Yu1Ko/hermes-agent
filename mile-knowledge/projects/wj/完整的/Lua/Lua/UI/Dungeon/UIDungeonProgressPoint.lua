local UIDungeonProgressPoint = class("UIDungeonProgressPoint")

function UIDungeonProgressPoint:OnEnter(bEnable)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:SetEnable(bEnable)
end

function UIDungeonProgressPoint:OnExit()
    self.bInit = false
end

function UIDungeonProgressPoint:BindUIEvent()
end

function UIDungeonProgressPoint:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIDungeonProgressPoint:SetEnable(bEnable)
    UIHelper.SetVisible(self.ImgPoint, bEnable)
end

return UIDungeonProgressPoint