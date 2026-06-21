-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationScrollViewTaskList
-- Date: 2026-03-20
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOperationScrollViewTaskList = class("UIOperationScrollViewTaskList")

-- nType: 1 - WidgetScrollViewTaskList80, 2 - WidgetScrollViewTaskList100
function UIOperationScrollViewTaskList:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIOperationScrollViewTaskList:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationScrollViewTaskList:BindUIEvent()

end

function UIOperationScrollViewTaskList:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIOperationScrollViewTaskList:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  -----------------------------

function UIOperationScrollViewTaskList:UpdateInfo()
    self.scriptTitle = UIHelper.GetBindScript(self.WidgetMiniTitle)
    UIHelper.RemoveAllChildren(self.ScrollViewContentList)
    local prefab = PREFAB_ID.WidgetTaskList80
    if tonumber(self.nType) == 1 then
        prefab = PREFAB_ID.WidgetTaskList80
    elseif tonumber(self.nType) == 2 then
        prefab = PREFAB_ID.WidgetTaskList100
    end
    self.nItemPrefabID = prefab
end


return UIOperationScrollViewTaskList
