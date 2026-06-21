local UIWidgetRenowRewardNpcRow = class("UIWidgetRenowRewardNpcRow")

local nNpcColumnCount = 3
function UIWidgetRenowRewardNpcRow:OnEnter(nPrefabID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.scriptList = {}
    self.nPrefabID = nPrefabID
end

function UIWidgetRenowRewardNpcRow:OnExit()
    self.bInit = false
end

function UIWidgetRenowRewardNpcRow:BindUIEvent()

end

function UIWidgetRenowRewardNpcRow:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetRenowRewardNpcRow:UpdateInfo()
    
end

function UIWidgetRenowRewardNpcRow:ClearData()
    for _, scriptCell in pairs(self.scriptList) do
        UIHelper.SetVisible(scriptCell._rootNode, false)
    end
end

function UIWidgetRenowRewardNpcRow:PushData(nIdx, ...)
    local scriptBar = self.scriptList[nIdx%nNpcColumnCount]
    if not scriptBar then scriptBar = UIHelper.AddPrefab(self.nPrefabID, self._rootNode) end

    self.scriptList[nIdx%nNpcColumnCount] = scriptBar

    if scriptBar then scriptBar:OnEnter(...) end
    UIHelper.SetVisible(scriptBar._rootNode, true)

    UIHelper.LayoutDoLayout(self._rootNode)
    return scriptBar
end

function UIWidgetRenowRewardNpcRow:SetNpcVisible(nIdx, bVisible)
    local scriptBar = self.scriptList[nIdx%nNpcColumnCount]
    if scriptBar then
        UIHelper.SetVisible(scriptBar._rootNode, bVisible)
    end
end

function UIWidgetRenowRewardNpcRow:GetDataCount()
    if not self.scriptList then
        return 0
    end
    return table.GetCount(self.scriptList)
end

return UIWidgetRenowRewardNpcRow