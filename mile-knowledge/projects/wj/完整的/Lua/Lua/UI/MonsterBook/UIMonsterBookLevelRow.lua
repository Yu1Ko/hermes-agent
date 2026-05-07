local UIMonsterBookLevelRow = class("UIMonsterBookLevelRow")

function UIMonsterBookLevelRow:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

end

function UIMonsterBookLevelRow:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIMonsterBookLevelRow:BindUIEvent()

end

function UIMonsterBookLevelRow:RegEvent()

end

function UIMonsterBookLevelRow:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIMonsterBookLevelRow:CreateScriptCell(nLevel)
    local nRowIndex = math.floor((nLevel-1)/10)
    self.nCellCount = self.nCellCount or 1
    self.bOrder2Right = nRowIndex % 2 == 0
    UIHelper.SetVisible(self.WidgetLineVertiRight, self.bOrder2Right)
    UIHelper.SetVisible(self.WidgetLineVertiLeft, not self.bOrder2Right)

    self.nLastLevel = nLevel
    local nodeShell = self.WidgetLevelShells[self.nCellCount]
    UIHelper.RemoveAllChildren(nodeShell)
    local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetWidgetLevelListSingleCell, nodeShell)
    self.nCellCount = self.nCellCount + 1
    return scriptCell
end

return UIMonsterBookLevelRow