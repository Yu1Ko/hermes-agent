-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationLayOutTaskList
-- Date: 2026-03-20
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOperationLayOutTaskList = class("UIOperationLayOutTaskList")

-- nType: 1 - WidgetLayOutTaskList80, 2 - WidgetLayOutTaskList100
function UIOperationLayOutTaskList:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIOperationLayOutTaskList:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationLayOutTaskList:BindUIEvent()

end

function UIOperationLayOutTaskList:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIOperationLayOutTaskList:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below   ----------------------------------------------------------


function UIOperationLayOutTaskList:UpdateInfo()
    UIHelper.WidgetFoceDoAlign(self)
    UIHelper.RemoveAllChildren(self.WidgetLayOutTaskList)
    UIHelper.SetAnchorPoint(self._rootNode, 0, 0)
    UIHelper.SetPositionX(self._rootNode, 0)
    self.scriptTitle = UIHelper.AddPrefab(PREFAB_ID.WidgetMiniTitle, self.WidgetLayOutTaskList)
    local prefab = PREFAB_ID.WidgetTaskList80
    if tonumber(self.nType) == 1 then
        prefab = PREFAB_ID.WidgetTaskList80
    elseif tonumber(self.nType) == 2 then
        prefab = PREFAB_ID.WidgetTaskList100
    end
    self.tScriptTaskList = {}
    for i = 1, 4 do
        local script = UIHelper.AddPrefab(prefab, self.WidgetLayOutTaskList)
        script.nType = self.nType
        table.insert(self.tScriptTaskList, script)
    end
    UIHelper.LayoutDoLayout(self.WidgetLayOutTaskList)
end

-- 设置标题单元显隐
function UIOperationLayOutTaskList:SetVisibleTitle(bVisible)
    if self.scriptTitle then
        UIHelper.SetVisible(self.scriptTitle._rootNode, bVisible)
        UIHelper.LayoutDoLayout(self.WidgetLayOutTaskList)
    end
end

-- 设置任务单元显隐
function UIOperationLayOutTaskList:SetVisibleTaskCell(index, bVisible)
    if self.tScriptTaskList[index] then
        UIHelper.SetVisible(self.tScriptTaskList[index]._rootNode, bVisible)
        UIHelper.LayoutDoLayout(self.WidgetLayOutTaskList)
    end
end

return UIOperationLayOutTaskList
