-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBagCell
-- Date: 2022-11-10 09:14:27
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIBagRow = class("UIBagRow")

function UIBagRow:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        self.bIsBag = false
    end

    self:UpdateInfo()
end

function UIBagRow:OnExit()
    self.bInit = false

    local cellNodes = UIHelper.GetChildren(self.LayoutBagItem)
    if cellNodes then
        for _, cellNode in ipairs(cellNodes) do
            local script = UIHelper.GetBindScript(cellNode)
            if script then
                Event.Dispatch(EventType.OnBagRowRecycled, script.nBox, script.nIndex, self.bIsBag)

                if script._nPrefabID ~= PREFAB_ID.WidgetBagBottom then
                    UIHelper.RemoveFromParent(cellNode, true) -- 回收时删除马驹仓库加载的其他类型的节点
                else
                    local oldItemScript = script.GetItemScript and script:GetItemScript()
                    if oldItemScript then
                        oldItemScript:OnPoolRecycled(true)
                    end
                end
                
                --script:GetItemScript():SetSelectChangeCallback(nil) -- 回收时不触发
            end
            --ItemData.GetBagCellPrefabPool():Recycle(cellNode)
        end
    end
end

function UIBagRow:OnPoolRecycled()
    self.bInit = false
end

function UIBagRow:OnUnInit()
    local cellNodes = UIHelper.GetChildren(self.LayoutBagItem)
    if cellNodes then
        for _, cellNode in ipairs(cellNodes) do
            local script = UIHelper.GetBindScript(cellNode)
            if script then
                if script._nPrefabID ~= PREFAB_ID.WidgetBagBottom then
                    UIHelper.RemoveFromParent(cellNode, true)
                else
                    ItemData.GetBagCellPrefabPool():Recycle(cellNode)
                end
            end
        end
    end
end

function UIBagRow:BindUIEvent()

end

function UIBagRow:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIBagRow:UpdateInfo()

end

return UIBagRow