local UIDungeonTaskTitle = class("UIDungeonTaskTitle")

function UIDungeonTaskTitle:OnEnter(szName)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo(szName)
end

function UIDungeonTaskTitle:OnExit()
    self.bInit = false
end

function UIDungeonTaskTitle:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleTitle, EventType.OnSelectChanged, function (_, bSelected)
        self:OnSelectChanged(bSelected)
    end)
end

function UIDungeonTaskTitle:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIDungeonTaskTitle:UpdateInfo(szName)
    self.szName = szName
    UIHelper.SetString(self.LabelTitle1, szName)
    UIHelper.SetString(self.LabelTitle2, szName)
end

function UIDungeonTaskTitle:OnSelectChanged(bSelected)
    if self.fOnClick then
        self.fOnClick(bSelected)
    end
end

function UIDungeonTaskTitle:SetSelectedCallBack(fOnClick)
    self.fOnClick = fOnClick
end

return UIDungeonTaskTitle