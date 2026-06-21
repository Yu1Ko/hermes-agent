local UIToggleSelector = class("UIToggleSelector")


function UIToggleSelector:OnEnter(szName)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.SubToggleWidth, self.SubToggleHeight = UIHelper.GetContentSize(self.WidgetSubToggleSelector)
    self.LabelCategoryWidght, self.LabelCategoryHeight = UIHelper.GetContentSize(self.LabelCategory)
    UIHelper.RemoveAllChildren(self.LayoutCategory)
    self:UpdateInfo(szName)
end

function UIToggleSelector:OnExit()
    self.bInit = false
end

function UIToggleSelector:BindUIEvent()
    
end

function UIToggleSelector:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIToggleSelector:UpdateInfo(szName)
    UIHelper.SetString(self.LabelCategory, szName)
end

return UIToggleSelector