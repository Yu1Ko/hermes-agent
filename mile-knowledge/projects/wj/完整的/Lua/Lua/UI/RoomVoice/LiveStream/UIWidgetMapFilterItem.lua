local UIWidgetMapFilterItem = class("UIWidgetMapFilterItem")

function UIWidgetMapFilterItem:OnEnter(szName, bSelected, bHasNext)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.szName = szName
    self.fnClickCallback = nil
    self:UpdateInfo(szName, bSelected, bHasNext)
end

function UIWidgetMapFilterItem:OnExit()
    self.bInit = false
end

function UIWidgetMapFilterItem:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnFilterItem, EventType.OnClick, function()
        if self.fnClickCallback then
            self.fnClickCallback(self.szName)
        end
    end)
end

function UIWidgetMapFilterItem:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetMapFilterItem:UpdateInfo(szName, bSelected, bHasNext)
    UIHelper.SetString(self.LabelFilterItem, szName)
    UIHelper.SetString(self.LabelFilterItem01, szName)
    UIHelper.SetVisible(self.ImgNext, bHasNext)
    self:SetSelected(bSelected)
end

function UIWidgetMapFilterItem:SetSelected(bSelected)
    UIHelper.SetVisible(self.WidgetFilterItem, not bSelected)
    UIHelper.SetVisible(self.WidgetSelected, bSelected)
end

function UIWidgetMapFilterItem:SetClickCallback(fnCallback)
    self.fnClickCallback = fnCallback
end

return UIWidgetMapFilterItem
