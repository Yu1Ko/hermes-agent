local UIWidgetAwardItemSmall = class("UIWidgetAwardItemSmall")
function UIWidgetAwardItemSmall:OnEnter(dwTabType, dwIndex, nAmount)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo(dwTabType, dwIndex, nAmount)
end

function UIWidgetAwardItemSmall:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetAwardItemSmall:BindUIEvent()
end

function UIWidgetAwardItemSmall:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetAwardItemSmall:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetAwardItemSmall:UpdateInfo(dwTabType, dwIndex, nAmount)
    UIHelper.RemoveAllChildren(self.WidgetItem)
    local scriptIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.WidgetItem)
    scriptIcon:OnInitWithTabID(dwTabType, dwIndex)
    scriptIcon:SetLabelCount(nAmount)
    scriptIcon:SetClickCallback(function()
        local tips, tipsView = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, scriptIcon._rootNode)
        tipsView:SetFunctionButtons({})
        tipsView:OnInitWithTabID(dwTabType, dwIndex)
    end)
    UIHelper.SetToggleGroupIndex(scriptIcon.ToggleSelect, ToggleGroupIndex.BagUpItem)
    UIHelper.SetTouchDownHideTips(scriptIcon.ToggleSelect, false)
    UIHelper.SetSwallowTouches(scriptIcon.ToggleSelect, false)

    local szItemName = ShopData.GetItemNameWithColor(nil, dwTabType, dwIndex)
    UIHelper.SetRichText(self.RichTextName, szItemName)
end

return UIWidgetAwardItemSmall