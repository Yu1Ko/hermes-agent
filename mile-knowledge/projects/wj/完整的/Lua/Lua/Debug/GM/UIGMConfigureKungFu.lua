local UIGMConfigureKungFu = class("UIGMConfigureKungFu")

function UIGMConfigureKungFu:OnEnter(tKungFungList, fnAction)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tKungFungList = tKungFungList
    self.fnAction = fnAction
    self:UpdateInfo()
end

function UIGMConfigureKungFu:OnExit()
    self.bInit = false
end

function UIGMConfigureKungFu:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleTask, EventType.OnSelectChanged, function(_,bSelected)
        if bSelected then
            if not self.fnAction then
                if UIMgr.GetView(VIEW_ID.PanelConfigureCamp) then
                    UIMgr.Close(VIEW_ID.PanelConfigureCamp)
                end
                UIMgr.Open(VIEW_ID.PanelConfigureCamp, self.tKungFungList)
            else
                self.fnAction()
                UIMgr.Close(VIEW_ID.PanelGM)
            end
        end
	end)
end

function UIGMConfigureKungFu:RegEvent()

end

function UIGMConfigureKungFu:UpdateInfo()
    UIHelper.SetString(self.LabelNomal, self.tKungFungList.szName)
    UIHelper.SetString(self.LabelUp, self.tKungFungList.szName)
    UIHelper.SetSwallowTouches(self.ToggleTask, false)
end

return UIGMConfigureKungFu