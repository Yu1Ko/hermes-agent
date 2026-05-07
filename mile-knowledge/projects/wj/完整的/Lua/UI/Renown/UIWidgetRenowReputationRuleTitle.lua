local UIWidgetRenowReputationRuleTitle = class("UIWidgetRenowReputationRuleTitle")


function UIWidgetRenowReputationRuleTitle:OnEnter(szTitle, nPrefabID, fCallBack)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if not szTitle then
        return
    end
    self.szTitle = szTitle
    self.nPrefabID = nPrefabID
    self.fCallBack = fCallBack
    self.scriptList = {}
    self:UpdateInfo(szTitle)
end

function UIWidgetRenowReputationRuleTitle:OnExit()
    self.bInit = false
end

function UIWidgetRenowReputationRuleTitle:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnSelectChanged, function (_, bSelected)
        for _, scriptBar in ipairs(self.scriptList) do
            UIHelper.SetVisible(scriptBar._rootNode, bSelected)
        end
        if self.scriptStoreDescribe then
            UIHelper.SetVisible(self.scriptStoreDescribe._rootNode, bSelected and self.scriptStoreDescribe.bEnabled)
        end
        UIHelper.LayoutDoLayout(self.LayoutReward)
        UIHelper.LayoutDoLayout(self._rootNode)
        self.fCallBack(bSelected)
    end)
end

function UIWidgetRenowReputationRuleTitle:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetRenowReputationRuleTitle:UpdateInfo(szTitle)
    UIHelper.SetString(self.LabelNameNormal, szTitle)
    UIHelper.SetString(self.LabelNameSelected, szTitle)
end

function UIWidgetRenowReputationRuleTitle:PushData(tData)
    local scriptBar = UIHelper.AddPrefab(self.nPrefabID, self.LayoutReward)
    if scriptBar then
        scriptBar:OnEnter(tData)
    end
    table.insert(self.scriptList, scriptBar)
    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
end

return UIWidgetRenowReputationRuleTitle