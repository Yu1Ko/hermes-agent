local UIDungeonBossHeadPoint = class("UIDungeonBossHeadPoint")

function UIDungeonBossHeadPoint:OnEnter(bSelected, fCallBack)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.fCallBack = fCallBack
    self:UpdateInfo(bSelected)
end

function UIDungeonBossHeadPoint:OnExit()
    self.bInit = false
end

function UIDungeonBossHeadPoint:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnDot, EventType.OnClick, function ()
        if self.fCallBack then self.fCallBack() end
    end)
end

function UIDungeonBossHeadPoint:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIDungeonBossHeadPoint:UpdateInfo(bSelected)
    self.bSelected = bSelected
    UIHelper.SetVisible(self.ImgBossHeadNormalUp, bSelected)
end

return UIDungeonBossHeadPoint