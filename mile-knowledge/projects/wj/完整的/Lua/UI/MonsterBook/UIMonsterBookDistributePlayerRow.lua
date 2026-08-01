local UIMonsterBookDistributePlayerRow = class("UIMonsterBookDistributePlayerRow")

function UIMonsterBookDistributePlayerRow:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    
    self.nCellCount = 0
    for _, widgetCell in ipairs(self.WidgetPlayerList) do
        UIHelper.SetVisible(widgetCell, false)
    end
end

function UIMonsterBookDistributePlayerRow:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIMonsterBookDistributePlayerRow:BindUIEvent()

end

function UIMonsterBookDistributePlayerRow:RegEvent()

end

function UIMonsterBookDistributePlayerRow:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIMonsterBookDistributePlayerRow:CreateCellScript()
    if self.nCellCount >= 2 then
        return nil, false
    end
    self.nCellCount = self.nCellCount + 1
    local widgetCell = self.WidgetPlayerList[self.nCellCount]
    UIHelper.SetVisible(widgetCell, true)
    local scriptCell = UIHelper.GetBindScript(self.WidgetPlayerList[self.nCellCount])
    return scriptCell, self.nCellCount < 2
end

return UIMonsterBookDistributePlayerRow