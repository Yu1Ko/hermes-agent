-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationScrollViewRewardList
-- Date: 2026-03-20
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOperationScrollViewRewardList = class("UIOperationScrollViewRewardList")

function UIOperationScrollViewRewardList:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIOperationScrollViewRewardList:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationScrollViewRewardList:BindUIEvent()

end

function UIOperationScrollViewRewardList:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIOperationScrollViewRewardList:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below ----------------

function UIOperationScrollViewRewardList:UpdateInfo()
    --todo
    local tbRewardItem = {}

    UIHelper.RemoveAllChildren(self.LayOutRewardItem)
    for _, tbData in ipairs(tbRewardItem) do
        local tItemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.LayOutRewardItem)
        if tItemScript then
            tItemScript:OnInit(tbData.dwBox, tbData.dwX)
            tItemScript:SetClickCallback(function()
            end)
        end
    end
    UIHelper.ScrollViewDoLayout(self.WidgetScrollViewRewardList)
    UIHelper.SetVisible(self.WidgetScrollViewRewardList, true)
end


return UIOperationScrollViewRewardList
