local UITableViewRow = class("UITableViewRow")

function UITableViewRow:OnEnter(nPrefabID, ToggleGroup, nColumnCount)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if nPrefabID == nil or ToggleGroup == nil then
        return
    end
    self.scriptList = {}
    self.ToggleGroup = ToggleGroup
    self.nPrefabID = nPrefabID
    self.nColumnCount = nColumnCount
    UIHelper.RemoveAllChildren(self._rootNode)
end

function UITableViewRow:OnExit()
    self.bInit = false
end

function UITableViewRow:BindUIEvent()

end

function UITableViewRow:RegEvent()
    Event.Reg(self, EventType.OnWindowsSizeChanged, function ()
        local nodeShell = UIHelper.GetParent(self._rootNode)
        if not nodeShell then return end
        local nodeLayout = UIHelper.GetParent(nodeShell)
        local nWidth = UIHelper.GetWidth(nodeLayout)
        UIHelper.SetWidth(nodeShell, nWidth)
        UIHelper.SetWidth(self._rootNode, nWidth)
        Timer.AddFrame(self, 1, function ()
            UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
        end)
    end)
end

function UITableViewRow:UpdateInfo()
    
end

function UITableViewRow:PushData(nIdx, ...)
    local scriptCell = UIHelper.AddPrefab(self.nPrefabID, self._rootNode, ...)
    self.scriptList[nIdx%self.nColumnCount] = scriptCell
    UIHelper.LayoutDoLayout(self._rootNode)
    if scriptCell then
        scriptCell.nIndex = nIdx
        UIHelper.ToggleGroupAddToggle(self.ToggleGroup, scriptCell.ToggleSelect)
    end
    return scriptCell
end

function UITableViewRow:UpdateData(nIdx, ...)
    local scriptCell = self.scriptList[nIdx%self.nColumnCount]
    if scriptCell then
        scriptCell.nIndex = nIdx
        scriptCell:OnEnter(...)        
    end
    UIHelper.LayoutDoLayout(self._rootNode)

    return scriptCell
end

function UITableViewRow:SetCellVisible(nIdx, bVisible)
    local scriptCell = self.scriptList[nIdx%self.nColumnCount]
    if scriptCell then
        UIHelper.SetVisible(scriptCell._rootNode, bVisible)
    end
end

function UITableViewRow:GetDataCount()
    if not self.scriptList then
        return 0
    end
    return table.GetCount(self.scriptList)
end

return UITableViewRow