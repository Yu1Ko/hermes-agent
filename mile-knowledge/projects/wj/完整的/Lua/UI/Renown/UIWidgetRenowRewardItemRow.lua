local UIWidgetRenowRewardItemRow = class("UIWidgetRenowRewardItemRow")

local nItemColumnCount = 4
function UIWidgetRenowRewardItemRow:OnEnter(nPrefabID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.scriptList = {}
    self.nPrefabID = nPrefabID
end

function UIWidgetRenowRewardItemRow:OnExit()
    self.bInit = false
end

function UIWidgetRenowRewardItemRow:BindUIEvent()

end

function UIWidgetRenowRewardItemRow:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetRenowRewardItemRow:UpdateInfo()
    
end

function UIWidgetRenowRewardItemRow:ClearData()
    for _, scriptCell in pairs(self.scriptList) do
        UIHelper.SetVisible(scriptCell._rootNode, false)
    end
end

function UIWidgetRenowRewardItemRow:PushData(nIdx, tItemInfo)
    local scriptItem = self.scriptList[nIdx%nItemColumnCount]
    if not scriptItem then scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self._rootNode) end

    if scriptItem then
        scriptItem.dwItemTabType = tItemInfo.dwItemTabType
        scriptItem.dwItemTabIndex = tItemInfo.dwItemTabIndex
        scriptItem:OnInitWithTabID(tItemInfo.dwItemTabType, tItemInfo.dwItemTabIndex)
        scriptItem:SetSelectMode(false)        
        scriptItem.dwForceID = tItemInfo.dwForceID
        scriptItem:SetClickCallback(function(nTabType, nTabID)
            tItemInfo.fCallBack()
        end)            
        local itemInfo = ItemData.GetItemInfo(tItemInfo.dwItemTabType, tItemInfo.dwItemTabIndex)
        local nBookInfo
        if itemInfo.nGenre == ITEM_GENRE.BOOK then
            nBookInfo = itemInfo.nDurability
        end
        scriptItem.szRewardItemName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(itemInfo, nBookInfo))
        UIHelper.SetSwallowTouches(scriptItem.ToggleSelect, false)
        scriptItem:SetItemGray(not tItemInfo.bReceived)
        UIHelper.SetAnchorPoint(scriptItem._rootNode, 0.5, 0)
        UIHelper.SetVisible(scriptItem._rootNode, true)
        UIHelper.SetToggleGroupIndex(scriptItem.ToggleSelect, ToggleGroupIndex.RenowRewardItem)
    end

    self.scriptList[nIdx%nItemColumnCount] = scriptItem    
    UIHelper.LayoutDoLayout(self._rootNode)
    return scriptItem
end

function UIWidgetRenowRewardItemRow:SetItemVisible(nIdx, bVisible)
    local scriptBar = self.scriptList[nIdx%nItemColumnCount]
    if scriptBar then
        UIHelper.SetVisible(scriptBar._rootNode, bVisible)
    end
end

function UIWidgetRenowRewardItemRow:GetDataCount()
    if not self.scriptList then
        return 0
    end
    return table.GetCount(self.scriptList)
end

return UIWidgetRenowRewardItemRow