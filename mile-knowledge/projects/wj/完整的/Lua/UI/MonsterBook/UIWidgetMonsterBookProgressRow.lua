local UIWidgetMonsterBookProgressRow = class("UIWidgetMonsterBookProgressRow")

function UIWidgetMonsterBookProgressRow:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

end

function UIWidgetMonsterBookProgressRow:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMonsterBookProgressRow:BindUIEvent()

end

function UIWidgetMonsterBookProgressRow:RegEvent()

end

function UIWidgetMonsterBookProgressRow:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIWidgetMonsterBookProgressRow:ResetData()
    self.nCurDataCount = 0
    self.tScriptList = {}
    for _, widgetCell in ipairs(self.WidgetCellList) do
        UIHelper.SetVisible(widgetCell, false)
    end
end

function UIWidgetMonsterBookProgressRow:PushData(dwBossIndex, tMonsterBossList)
    local nColumnCount = #self.WidgetCellList
    if self.nCurDataCount >= nColumnCount then
        return
    end
    local widgetCell = self.WidgetCellList[self.nCurDataCount + 1]
    local scriptCell = self.tScriptList[dwBossIndex]
    if not scriptCell then
        scriptCell = UIHelper.GetBindScript(widgetCell)
        self.tScriptList[dwBossIndex] = scriptCell
    end
    scriptCell:OnEnter(dwBossIndex, tMonsterBossList or 0)
    UIHelper.SetVisible(widgetCell, true)
    self.nCurDataCount = self.nCurDataCount + 1
    return self.nCurDataCount < nColumnCount
end

return UIWidgetMonsterBookProgressRow