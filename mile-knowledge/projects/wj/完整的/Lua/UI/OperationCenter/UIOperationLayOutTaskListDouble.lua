-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationLayOutTaskListDouble
-- Date: 2026-03-20
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOperationLayOutTaskListDouble = class("UIOperationLayOutTaskListDouble")

-- nType: 1 - WidgetLayOutTaskListDouble80, 2 - WidgetLayOutTaskListDouble100
function UIOperationLayOutTaskListDouble:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIOperationLayOutTaskListDouble:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationLayOutTaskListDouble:BindUIEvent()

end

function UIOperationLayOutTaskListDouble:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIOperationLayOutTaskListDouble:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end





-- ----------------------------------------------------------
-- Please write your own code below   ----------------------------------------------------------


function UIOperationLayOutTaskListDouble:UpdateInfo()
    UIHelper.WidgetFoceDoAlign(self)
    UIHelper.SetAnchorPoint(self._rootNode, 0, 0)
    UIHelper.SetPositionX(self._rootNode, 0)
    UIHelper.RemoveAllChildren(self.WidgetLayOutTaskListDouble)
    self.scriptTitle = UIHelper.AddPrefab(PREFAB_ID.WidgetMiniTitle, self.WidgetLayOutTaskListDouble)
    local prefab = PREFAB_ID.WidgetTaskListDouble80
    if tonumber(self.nType) == 1 then
        prefab = PREFAB_ID.WidgetTaskListDouble80
    elseif tonumber(self.nType) == 2 then
        prefab = PREFAB_ID.WidgetTaskListDouble100
    end

    self.tScriptTaskList = {}
    for i = 1, 4 do
        local script = UIHelper.AddPrefab(prefab, self.WidgetLayOutTaskListDouble)
        script.nType = self.nType
        table.insert(self.tScriptTaskList, script)
    end
    UIHelper.LayoutDoLayout(self.WidgetLayOutTaskListDouble)
end

-- 设置标题单元显隐
function UIOperationLayOutTaskListDouble:SetVisibleTitle(bVisible)
    if self.scriptTitle then
        UIHelper.SetVisible(self.scriptTitle._rootNode, bVisible)
        UIHelper.LayoutDoLayout(self.WidgetLayOutTaskListDouble)
    end
end

return UIOperationLayOutTaskListDouble