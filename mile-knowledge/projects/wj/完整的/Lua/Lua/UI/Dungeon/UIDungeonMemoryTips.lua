local UIDungeonMemoryTips = class("UIDungeonMemoryTips")

function UIDungeonMemoryTips:OnEnter(szName)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo(szName)
end

function UIDungeonMemoryTips:OnExit()
    self.bInit = false
end

function UIDungeonMemoryTips:BindUIEvent()
end

function UIDungeonMemoryTips:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIDungeonMemoryTips:UpdateInfo(szName)
    self.szName = szName
    UIHelper.SetString(self.LabelTips, szName)
    Timer.AddFrame(self, 1, function ()
        UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
    end)
end

return UIDungeonMemoryTips