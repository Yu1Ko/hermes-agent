local UIDungeonTaskToggle = class("UIDungeonTaskToggle")

function UIDungeonTaskToggle:OnEnter(tParams)
    if not tParams then return end

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tHeadInfo = tParams.tHeadInfo
    self.fCallBack = tParams.fCallBack
    self:UpdateInfo(self.tHeadInfo)
end

function UIDungeonTaskToggle:OnExit()
    self.bInit = false
end

function UIDungeonTaskToggle:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnSelectChanged, function(_,bSelected)
		if bSelected and self.fCallBack then self.fCallBack(self.tHeadInfo) end
	end)
end

function UIDungeonTaskToggle:RegEvent()

end

function UIDungeonTaskToggle:UpdateInfo(tHeadInfo)
    local szTask = tHeadInfo.szName
    UIHelper.SetString(self.LabelNomal, szTask)
    UIHelper.SetString(self.LabelUp, szTask)
    UIHelper.SetSwallowTouches(self.ToggleSelect, false)

    UIHelper.SetVisible(self.ImgDaily, DungeonData.IsHeadMatchFlag(tHeadInfo, 1))
    UIHelper.SetVisible(self.ImgWeekly, DungeonData.IsHeadMatchFlag(tHeadInfo, 2))
    UIHelper.SetVisible(self.ImgWishItem, DungeonData.IsHeadMatchWishItem(tHeadInfo))
    UIHelper.LayoutDoLayout(self.LayoutTags)
end

return UIDungeonTaskToggle