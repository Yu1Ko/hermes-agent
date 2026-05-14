local UIDungeonFliterItem = class("UIDungeonFliterItem")

function UIDungeonFliterItem:OnEnter(szName, bSelected, bHasNext)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo(szName, bSelected, bHasNext)
end

function UIDungeonFliterItem:OnExit()
    self.bInit = false
end

function UIDungeonFliterItem:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnFilterItem, EventType.OnClick, function()
        Event.Dispatch(EventType.OnDungeonFliterSelectChanged, self.szName)
	end)
end

function UIDungeonFliterItem:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIDungeonFliterItem:UpdateInfo(szName, bSelected, bHasNext)
    self.szName = szName
    self.bSelected = bSelected
    self.bHasNext = bHasNext

    UIHelper.SetString(self.LabelFilterItem, szName)
    UIHelper.SetVisible(self.ImgChecked, bSelected)
    UIHelper.SetVisible(self.ImgNext, bHasNext)
end

function UIDungeonFliterItem:SetSelected(bSelected)
    self.bSelected = bSelected
    UIHelper.SetVisible(self.ImgChecked, bSelected)
end

return UIDungeonFliterItem