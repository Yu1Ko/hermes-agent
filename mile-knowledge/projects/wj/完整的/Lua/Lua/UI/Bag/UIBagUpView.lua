-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBagUpView
-- Date: 2022-11-11 10:41:17
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIBagUpView = class("UIBagUpView")
function UIBagUpView:OnEnter(dwItemID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    for _, toggle in ipairs(self.tbToggleSlot) do
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupSlot, toggle)
    end

    self.nSelectedItemID = nil
    self.nSelectSlotIndex = ItemData.SlotSet.BagSlot[1]
    self.tbScriptSlotItem = {}

    if dwItemID and dwItemID ~= 0 then
        local nOptimalSlotIndex = self:GetOptimalSlotIndex(dwItemID)
        
        if self.nSelectSlotIndex ~= nOptimalSlotIndex then
            for i, nBox in ipairs(ItemData.SlotSet.BagSlot) do
                if nBox == nOptimalSlotIndex then
                    UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupSlot, self.tbToggleSlot[i])
                end
            end
        end

        self.nSelectSlotIndex = nOptimalSlotIndex
        self.nSelectedItemID = dwItemID
    end

    local bCanUseMibaoPackage = ItemData.CanUseMibaoPackage()
    UIHelper.SetVisible(self.BtnMiBaoLock, not bCanUseMibaoPackage)
    UIHelper.SetVisible(self.WidgetMiBaoAdd, bCanUseMibaoPackage)
    UIHelper.SetVisible(self.ImgMiBaoBg, bCanUseMibaoPackage)
    UIHelper.SetVisible(self.WidgetMiBaoAdd, bCanUseMibaoPackage)
    
    self:UpdateInfo()
    
    Timer.AddFrame(self, 1, function()
        local nIndex = self:GetFirstExpandCell()
        UIHelper.SetToggleGroupSelected(self.ToggleGroupSlot, nIndex - 1)
        self:PopExpandTip(nIndex)
    end)
end

function UIBagUpView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIBagUpView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnAccept, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    for i, toggleSolt in ipairs(self.tbToggleSlot) do
        UIHelper.BindUIEvent(toggleSolt, EventType.OnClick, function()
            self.nSelectSlotIndex = ItemData.SlotSet.BagSlot[i]
            if not (i == 5 and not ItemData.CanUseMibaoPackage()) then
                self:PopExpandTip(i)
            end
        end)
    end

    UIHelper.BindUIEvent(self.BtnMiBaoLock, EventType.OnClick, function()
        self:OnBtnMiBaoLockClick()
    end)

    UIHelper.BindUIEvent(self.BtnBagUpgradeQuit, EventType.OnClick, function()
        --退出扩容
        Event.Dispatch("ON_UPDATE_BAGUPGRADE_STATE")
    end)
end

function UIBagUpView:RegEvent()
    Event.Reg(self, "EQUIP_ITEM_UPDATE", function(nBox, nIndex, bNewAdd)
        if table.contain_value(BANK_EXPAND_SLOTS, nIndex) then
            return
        end

        local item = ItemData.GetItemByPos(nBox, nIndex)
        local nSlotIndex = table.get_key(ItemData.SlotSet.BagSlot, nIndex)
        if not self.tbScriptSlotItem[nIndex + 1] and item and nSlotIndex then
            local itemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.tbWidgetSlot[nSlotIndex])
            itemIcon:OnInit(nBox, nIndex)
            itemIcon:SetLabelCountVisible(false)
            itemIcon:SetSelectEnable(false)
            itemIcon:SetRecallCallback(function()
                ItemData.UnEquipItem(nBox, nIndex)
            end)
            itemIcon:SetRecallVisible(true)
            self.tbScriptSlotItem[nIndex + 1] = itemIcon
        elseif self.tbScriptSlotItem[nIndex + 1] and item then
            self.tbScriptSlotItem[nIndex + 1]:UpdateInfo(item)
        else
            UIHelper.RemoveAllChildren(self.tbWidgetSlot[nSlotIndex])
            self.tbScriptSlotItem[nIndex + 1] = nil
        end

        self:UpdateBagSize()
        self:SelectNextEmptySlot()

        local bVisible = UIHelper.GetVisible(self._rootNode)
        if bVisible then
            self:PopExpandTip()
        end
    end)

    --Event.Reg(self, "BAG_ITEM_UPDATE", function(nBox, nIndex, bNewAdd)
    --    local item = ItemData.GetItemByPos(nBox, nIndex)
    --
    --    self.nSelectedItemID = nil
    --    -- 更新格子
    --    self:UpdateBagItemList()
    --    self:UpdateSelectedItemDetails()
    --end)

    --Event.Reg(self, EventType.OnSceneTouchNothing, function()
    --    UIMgr.Close(self)
    --end)
end

function UIBagUpView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIBagUpView:UpdateInfo()
    for i, tbItemInfo in ipairs(ItemData.GetBoxSlotItemList(ItemData.BoxSet.BagSlot[1], ItemData.SlotSet.BagSlot)) do
        if tbItemInfo.hItem then
            local itemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.tbWidgetSlot[i])
            itemIcon:OnInit(tbItemInfo.nBox, tbItemInfo.nIndex)
            itemIcon:SetLabelCountVisible(false)
            itemIcon:SetSelectEnable(false)
            itemIcon:SetRecallCallback(function()
                ItemData.UnEquipItem(tbItemInfo.nBox, tbItemInfo.nIndex)
            end)
            itemIcon:SetRecallVisible(true)
            self.tbScriptSlotItem[tbItemInfo.nIndex + 1] = itemIcon
        end
    end

    self:UpdateBagSize()
end

function UIBagUpView:UpdateSelectedItemDetails()
    local hItem, dwBox, dwIndex

    if self.nSelectedItemID then
        hItem, dwBox, dwIndex = ItemData.GetItem(self.nSelectedItemID)

        if hItem then
            if not self.scriptItemTip then
                self.scriptItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetCard)
                self.scriptItemTip:SetForbidAutoShortTip(true)
            end

            if self.scriptItemTip then
                self.scriptItemTip:OnInit(dwBox, dwIndex)
                self.scriptItemTip:SetBtnState({
                    {
                        OnClick = function()
                            self:EquipPackage()
                            TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
                        end,
                        szName = g_tStrings.STR_ITEM_FUNCTION_EQUIP
                    }
                })
            end
        else
            self.nSelectedItemID = nil
        end
    else
        if self.scriptItemTip then
            UIHelper.SetVisible(self.scriptItemTip._rootNode, false)
        end
    end
end

function UIBagUpView:UpdateBagSize()
    for i, nBox in ipairs(ItemData.BoxSet.EquipableBag) do
        local LabelSlotSize = self.tbLabelSlotSize[i]
        local ImgSlotBg = self.tbSlotBg[i]
        if LabelSlotSize then
            local nSize = ItemData.GetBagSize({ nBox })

            if nSize == 0 then
                UIHelper.SetVisible(ImgSlotBg, false)
            else
                local szText = string.format(g_tStrings.STR_BAG_SIZE, nSize)
                UIHelper.SetString(LabelSlotSize, szText)
                UIHelper.SetVisible(ImgSlotBg, true)
            end
        end
    end
end

function UIBagUpView:EquipPackage()
    if not self.nSelectedItemID or not self.nSelectSlotIndex then
        return
    end

    local item, dwBox, dwIndex = ItemData.GetItem(self.nSelectedItemID)
    if item.nBindType == ITEM_BIND.BIND_ON_EQUIPPED and not item.bBind then
        local szShowMessage = g_tStrings.STR_MSG_EQUIP_BIND_ITEM_SURE
        local szConfirmContain = string.format(szShowMessage, UIHelper.GBKToUTF8(item.szName))
        UIHelper.ShowConfirm(szConfirmContain, function()
            local bExchangeResult = ItemData.ExchangeItem(dwBox, dwIndex, ItemData.BoxSet.BagSlot[1], self.nSelectSlotIndex)
            if bExchangeResult then
                TipsHelper.ShowNormalTip("背包扩容成功")
            end
        end)
    else
        local bExchangeResult = ItemData.ExchangeItem(dwBox, dwIndex, ItemData.BoxSet.BagSlot[1], self.nSelectSlotIndex)
        if bExchangeResult then
            TipsHelper.ShowNormalTip("背包扩容成功")
        end
    end
end

function UIBagUpView:GetOptimalSlotIndex(dwItemID)
    local nMinSize
    local nOptimalSlotIndex = ItemData.SlotSet.BagSlot[1]

    local nItemBox, nItemIndex = ItemData.GetItemPos(dwItemID)
    local hItem = ItemData.GetItem(dwItemID)
    if not nItemBox then
        return nOptimalSlotIndex
    end

    if self:IsBoxFull() and self:IsLessBag(hItem.nCurrentDurability) then
        TipsHelper.ShowNormalTip("当前的包裹大小比已装备的包裹都小，无法直接更换")
    else
        for i, nSlot in ipairs(ItemData.SlotSet.BagSlot) do
            local nSize = ItemData.GetBoxSize(ItemData.BoxSet.EquipableBag[i])
            if not nMinSize or nSize < nMinSize then
                local bCanExchange = ItemData.CanExchangeItem(nItemBox, nItemIndex, ItemData.BoxSet.BagSlot[1], nSlot)
                if bCanExchange then
                    nMinSize = nSize
                    nOptimalSlotIndex = nSlot
                end
            end
        end

        return nOptimalSlotIndex
    end

end

function UIBagUpView:OnBtnMiBaoLockClick()
    UIHelper.OpenWebWithDefaultBrowser("https://jx3.xoyo.com/zt/2018/05/22/linglong/mobile.html")
end

function UIBagUpView:SelectNextEmptySlot()
    for i = 1, #ItemData.SlotSet.BagSlot do
        if not ItemData.GetItemByPos(ItemData.BoxSet.BagSlot[1], ItemData.SlotSet.BagSlot[i]) then
            if ItemData.SlotSet.BagSlot[i] == EQUIPMENT_INVENTORY.PACKAGE_MIBAO and not ItemData.CanUseMibaoPackage() then
            else
                UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupSlot, self.tbToggleSlot[i])
                self.nSelectSlotIndex = ItemData.SlotSet.BagSlot[i]
                self.nSlotIndex = i
                return
            end

        end
    end
end

function UIBagUpView:IsBoxFull()
    --扩容格子已满？
    local bCanUseMibaoPackage = ItemData.CanUseMibaoPackage()
    for i, nSlot in ipairs(ItemData.SlotSet.BagSlot) do
        if i ~= #ItemData.SlotSet.BagSlot then
            if ItemData.GetBoxSize(ItemData.BoxSet.EquipableBag[i]) == 0 then
                return false
            end
        elseif bCanUseMibaoPackage and ItemData.GetBoxSize(ItemData.BoxSet.EquipableBag[i]) == 0 then
            return false
        end
    end
    return true
end

function UIBagUpView:IsLessBag(nCapacity)
    --当前扩容背包容量比所有格子容量都小？
    local tbCapacityList = {}
    local nMinCapacity
    local bCanUseMibaoPackage = ItemData.CanUseMibaoPackage()
    for i, nSlot in ipairs(ItemData.SlotSet.BagSlot) do
        if i == #ItemData.SlotSet.BagSlot then
            if bCanUseMibaoPackage and (not nMinCapacity or ItemData.GetBoxSize(ItemData.BoxSet.EquipableBag[i]) < nMinCapacity) then
                nMinCapacity = ItemData.GetBoxSize(ItemData.BoxSet.EquipableBag[i])
            end
        elseif not nMinCapacity or ItemData.GetBoxSize(ItemData.BoxSet.EquipableBag[i]) < nMinCapacity then
            nMinCapacity = ItemData.GetBoxSize(ItemData.BoxSet.EquipableBag[i])
        end
    end
    return nCapacity <= nMinCapacity
end

function UIBagUpView:UpdateBagItemTips(nIndex)
    local bCanUseMibaoPackage = ItemData.CanUseMibaoPackage()
    local nSize = ItemData.GetBoxSize(ItemData.BoxSet.EquipableBag[nIndex])
    if nIndex ~= 5 and nSize == 0 then
        TipsHelper.ShowNormalTip("请使用包裹来装备扩容")
    else
        if bCanUseMibaoPackage and nSize == 0 then
            TipsHelper.ShowNormalTip("请使用包裹来装备扩容")
        end
    end
end

function UIBagUpView:PopExpandTip(nSlotIndex)
    if not UIHelper.GetHierarchyVisible(self._rootNode) then
        return
    end
    nSlotIndex = nSlotIndex or self.nSlotIndex
    self.nSlotIndex = nSlotIndex

    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetClickFeeding)
    local tip, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetClickFeeding, self.ToggleGroupSlot, TipsLayoutDir.TOP_CENTER)
    self.scriptFeeding = script
    if self.scriptFeeding then
        self.scriptFeeding:SetTitle("选择扩容道具")
        self.scriptFeeding:HideFullScreenButton()

        local tExpandItemList = self:GetExpandItem()
        local parent = self.scriptFeeding.ScrollViewList

        local sortFunc = function(a, b)
            return a.nCurrentDurability > b.nCurrentDurability
        end
        table.sort(tExpandItemList, sortFunc)

        UIHelper.RemoveAllChildren(parent)
        for k, hItem in ipairs(tExpandItemList) do
            local tbItemInfo = ItemData.GetItemInfo(hItem.dwTabType, hItem.dwIndex)
            local szName = UIHelper.GBKToUTF8(Table_GetItemName(tbItemInfo.nUiId))
            local nExpandCount = hItem.nCurrentDurability
            local itemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetAwardItem1, parent, szName, "+" .. nExpandCount, hItem.dwTabType, hItem.dwIndex, false)
            if itemIcon then
                local nSize = ItemData.GetBagSize({ ItemData.BoxSet.EquipableBag[nSlotIndex] })
                local bAvailable = nExpandCount >= nSize
                itemIcon:SetClickCallback(function(dwTabType, dwIndex)
                    local function DoExchangeCheck(hItem, nSlotIndex, bAvailable)
                        if bAvailable then
                            self:ExchangePackage(hItem.dwID, ItemData.SlotSet.BagSlot[nSlotIndex])
                        else
                            TipsHelper.ShowNormalTip("当前的包裹容量比已装备的包裹小，无法直接更换")
                        end
                    end

                    if hItem.nBindType == ITEM_BIND.BIND_ON_EQUIPPED and not hItem.bBind then
                        local szConfirmContain = string.format(g_tStrings.STR_MSG_EQUIP_BIND_ITEM_SURE, szName)
                        UIHelper.ShowConfirm(szConfirmContain, function()
                            DoExchangeCheck(hItem, nSlotIndex, bAvailable)
                        end)
                    else
                        DoExchangeCheck(hItem, nSlotIndex, bAvailable)
                    end
                end)

                UIHelper.SetNodeGray(itemIcon.ImgIcon, not bAvailable, true)
                UIHelper.SetOpacity(itemIcon._rootNode, bAvailable and 255 or 120)
                UIHelper.SetTouchDownHideTips(itemIcon.TogItem, false)
                Timer.AddFrame(self, 1, function()
                    if itemIcon and itemIcon.scriptItemIcon then
                        itemIcon.scriptItemIcon:SetClickCallback(nil) -- WidgetAwardItem1预制有问题，此处防止触发两次回调
                    end
                end)
            end
        end

        UIHelper.SetVisible(self.scriptFeeding.WidgetScroll, true)
        UIHelper.ScrollViewDoLayoutAndToTop(self.scriptFeeding.ScrollViewList)

        if #tExpandItemList == 0 then
            self.scriptFeeding:ShowEmpty()
        end
    end
end

function UIBagUpView:GetExpandItem()
    local player = g_pClientPlayer
    local tExpandItemList = {}
    for i, nBox in ipairs(ItemData.BoxSet.Bag) do
        for k, tbItemInfo in ipairs(ItemData.GetBoxItem(nBox)) do
            local bShowItem = tbItemInfo.hItem and tbItemInfo.hItem.nSub == EQUIPMENT_SUB.PACKAGE
            if bShowItem then
                table.insert(tExpandItemList, tbItemInfo.hItem)
            end
        end
    end

    return tExpandItemList
end

function UIBagUpView:ExchangePackage(nSelectedItemID, nTargetSlotIndex)
    if not nSelectedItemID then
        return
    end
    local hItem, nItemBox, nItemIndex = ItemData.GetItem(nSelectedItemID)
    local bRes = ItemData.ExchangeItem(nItemBox, nItemIndex, INVENTORY_INDEX.EQUIP, nTargetSlotIndex)
    if bRes then
        TipsHelper.ShowNormalTip("背包扩容成功")
    end
end

function UIBagUpView:GetFirstExpandCell()
    local nIndex = 1
    for i, nBox in ipairs(ItemData.BoxSet.EquipableBag) do
        local nSize = ItemData.GetBagSize({ nBox })
        if nSize == 0 and (nBox ~= INVENTORY_INDEX.PACKAGE_MIBAO or ItemData.CanUseMibaoPackage()) then
            nIndex = i
            return nIndex
        end
    end
    return nIndex
end

return UIBagUpView