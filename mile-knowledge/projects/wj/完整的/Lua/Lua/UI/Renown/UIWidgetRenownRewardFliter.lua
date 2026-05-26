local UIWidgetRenownRewardFliter = class("UIWidgetRenownRewardFliter")


function UIWidgetRenownRewardFliter:OnEnter(szName, fCallBack)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if not szName then
        return
    end
    self.szName = szName
    self.fCallBack = fCallBack
    UIHelper.SetTouchDownHideTips(self.ToggleSelect, false)
    self:UpdateInfo(szName)
end

function UIWidgetRenownRewardFliter:OnExit()
    self.bInit = false
end

function UIWidgetRenownRewardFliter:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            self.fCallBack()
        end        
    end)
end

function UIWidgetRenownRewardFliter:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetRenownRewardFliter:UpdateInfo(szName)
    UIHelper.SetString(self.LabelScreen, szName)
    UIHelper.SetSwallowTouches(self.ToggleSelect, false)
end


return UIWidgetRenownRewardFliter