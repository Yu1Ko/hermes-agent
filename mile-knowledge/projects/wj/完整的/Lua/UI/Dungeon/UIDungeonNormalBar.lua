local UIDungeonNormalBar = class("UIDungeonNormalBar")

function UIDungeonNormalBar:OnEnter(szName)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo(szName)
end

function UIDungeonNormalBar:OnExit()
    self.bInit = false
end

function UIDungeonNormalBar:BindUIEvent()
end

function UIDungeonNormalBar:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIDungeonNormalBar:UpdateInfo(szName)
    self.szName = szName
    UIHelper.SetString(self.LabelTitle, szName)
end

return UIDungeonNormalBar