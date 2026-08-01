local UIWidgetPlayStoreRow = class("UIWidgetPlayStoreRow")

function UIWidgetPlayStoreRow:OnEnter(nPrefabID, ToggleGroup, nColumnCount, bOnSell)
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
    self.bOnSell = bOnSell
    UIHelper.SetVisible(self.WidgetClass, self.nColumnCount == 2)
    UIHelper.SetVisible(self.WidgetWithoutClass, self.nColumnCount == 3)
    UIHelper.SetVisible(self.WidgetFour, self.nColumnCount == 4)

    self.TwoCellRow = self.TwoCellRow or {}
    if #self.TwoCellRow == 0 and self.WidgetPlayStoreCellsWithClass and self.nColumnCount == 2 then
        for i = 1, 2 do
            local script = UIHelper.AddPrefab(nPrefabID, self.WidgetPlayStoreCellsWithClass[i])
            script._keepmt = true
            table.insert(self.TwoCellRow, script._rootNode)
        end
    end

    self.ThreeCellRow = self.ThreeCellRow or {}
    if #self.ThreeCellRow == 0 and self.WidgetPlayStoreCellsWithoutClass and self.nColumnCount == 3 then
        for i = 1, 3 do
            local script = UIHelper.AddPrefab(bOnSell and PREFAB_ID.WidgetSellOutCell or nPrefabID, self.WidgetPlayStoreCellsWithoutClass[i])
            script._keepmt = true
            table.insert(self.ThreeCellRow, script._rootNode)
        end
    end

    self.FourCellRow = self.FourCellRow or {}
    if #self.FourCellRow == 0 and self.WidgetPlayStoreCellFour and self.nColumnCount == 4 then
        for i = 1, 4 do
            local script = UIHelper.AddPrefab(nPrefabID, self.WidgetPlayStoreCellFour[i])
            script._keepmt = true
            table.insert(self.FourCellRow, script._rootNode)
        end
    end

    if self.nColumnCount == 2 then
        self.WidgetPlayStoreCells = self.TwoCellRow
    elseif self.nColumnCount == 3 then
        self.WidgetPlayStoreCells = self.ThreeCellRow
    elseif self.nColumnCount == 4 then
        self.WidgetPlayStoreCells = self.FourCellRow
    end
    --if bOnSell then
    --    self.WidgetPlayStoreCells = self.tbSellOutCell
    --end

    for _, cell in ipairs(self.WidgetPlayStoreCells) do
        UIHelper.SetVisible(cell, false)
    end
end

function UIWidgetPlayStoreRow:OnExit()
    self.bInit = false
end

function UIWidgetPlayStoreRow:BindUIEvent()

end

function UIWidgetPlayStoreRow:RegEvent()
    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        Timer.DelAllTimer(self)
        Timer.AddFrame(self, 3, function ()
            self:Resize()
        end)
        Timer.AddFrame(self, 4, function ()
            UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
        end)
    end)
end

function UIWidgetPlayStoreRow:Resize()
    local nodeShell = UIHelper.GetParent(self._rootNode)
    if not nodeShell then return end

    local nodeLayout = UIHelper.GetParent(nodeShell)
    local nWidth = UIHelper.GetWidth(nodeLayout)
    UIHelper.SetWidth(nodeShell, nWidth)
    UIHelper.SetWidth(self._rootNode, nWidth)
    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
end

function UIWidgetPlayStoreRow:PushData(nIdx, ...)
    local widgetCell = self.WidgetPlayStoreCells[(nIdx-1)%self.nColumnCount+1]
    local scriptCell = UIHelper.GetBindScript(widgetCell)
    self.scriptList[nIdx%self.nColumnCount] = scriptCell
    UIHelper.LayoutDoLayout(self._rootNode)
    if scriptCell then
        scriptCell.nIndex = nIdx
        scriptCell:OnEnter(...)
        if not scriptCell.bHasToggleGroup then
            scriptCell.bHasToggleGroup = true
            UIHelper.ToggleGroupAddToggle(self.ToggleGroup, scriptCell.ToggleSelect)
        end
    end
    UIHelper.SetVisible(widgetCell, true)

    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
    Timer.AddFrame(self, 1, function ()
        self:Resize()
    end)
    return scriptCell
end

function UIWidgetPlayStoreRow:UpdateData(nIdx, ...)
    local scriptCell = self.scriptList[nIdx%self.nColumnCount]
    if scriptCell then
        scriptCell.nIndex = nIdx
        scriptCell:OnEnter(...)
        UIHelper.SetVisible(scriptCell._rootNode, true)
    end

    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
    Timer.AddFrame(self, 1, function ()
        self:Resize()
    end)
    return scriptCell
end

function UIWidgetPlayStoreRow:SetCellVisible(nIdx, bVisible)
    local scriptCell = self.scriptList[nIdx%self.nColumnCount]
    if scriptCell then
        UIHelper.SetVisible(scriptCell._rootNode, bVisible)
    end
end

function UIWidgetPlayStoreRow:GetDataCount()
    if not self.scriptList then
        return 0
    end
    return table.GetCount(self.scriptList)
end

return UIWidgetPlayStoreRow