-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIQuestListCellView
-- Date: 2022-12-15 19:09:46
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIQuestListCellView = class("UIQuestListCellView")

function UIQuestListCellView:OnEnter(tbQuestInfo, tbChooseQuestInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if tbQuestInfo then
        self.tbQuestInfo = tbQuestInfo
        self.tbChooseQuestInfo = tbChooseQuestInfo
        self:UpdateInfo()
    end
end

function UIQuestListCellView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIQuestListCellView:BindUIEvent()

end

function UIQuestListCellView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "OnDetailSelectChanged", function()
        UIHelper.LayoutDoLayout(self.LayoutTaskToggle)
        UIHelper.LayoutDoLayout(self.WidgetTaskListCell)
        Event.Dispatch("OnTaskToggleVisChanged")
    end)
end

function UIQuestListCellView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIQuestListCellView:UpdateInfo()
    UIHelper.SetString(self.LabelTitle, self.tbQuestInfo.szClassName)
    UIHelper.RemoveAllChildren(self.LayoutTaskToggle)
    self.tbCells = {}
    for index, tbQuestInfo in ipairs(self.tbQuestInfo.tbQuestList) do
        self.tbCells[index] = UIHelper.AddPrefab(PREFAB_ID.WidgetTaskToggle, self.LayoutTaskToggle, tbQuestInfo, self.tbChooseQuestInfo)
    end
    UIHelper.LayoutDoLayout(self.LayoutTaskToggle)
    UIHelper.LayoutDoLayout(self.WidgetTaskListCell)
    UIHelper.SetNodeSwallowTouches(self._rootNode, false, true)
end

function UIQuestListCellView:GetScriptCells()
    return self.tbCells or {}
end

function UIQuestListCellView:LayoutDoLayout()
    UIHelper.LayoutDoLayout(self.LayoutTaskToggle)
        UIHelper.LayoutDoLayout(self.WidgetTaskListCell)
end

return UIQuestListCellView