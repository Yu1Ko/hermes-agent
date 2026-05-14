-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBagUpView
-- Date: 2022-11-11 10:41:17
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWareHouseExpand = class("UIWareHouseExpand")

local function PutItemToBank(dwBox, dwX, nAmount)
    local player = GetClientPlayer()
    if not player then
        return
    end
    local dwTargetBox, dwTargetX

    dwTargetBox, dwTargetX = player.GetStackRoomInBank(dwBox, dwX)
    if dwTargetBox and dwTargetX then
        ItemData.ExchangeItem(dwBox, dwX, dwTargetBox, dwTargetX)
        return true
    else
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_ERROR_BANK_IS_FULL)
    end
    return false
end

local tbBankExpandSlot = BANK_EXPAND_SLOTS

local BankPackage = { INVENTORY_INDEX.BANK_PACKAGE1, INVENTORY_INDEX.BANK_PACKAGE2, INVENTORY_INDEX.BANK_PACKAGE3,
                      INVENTORY_INDEX.BANK_PACKAGE4, INVENTORY_INDEX.BANK_PACKAGE5 }

function UIWareHouseExpand:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nSelectedItemID = nil

    self:RefreshSlotLayout()
    self:UpdateInfo()
end

function UIWareHouseExpand:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWareHouseExpand:BindUIEvent()

end

function UIWareHouseExpand:RegEvent()
    Event.Reg(self, "EQUIP_ITEM_UPDATE", function(nBox, nIndex, bNewAdd)
       if not table.contain_value(tbBankExpandSlot, nIndex) then
            return
        end

        self:SelectNextEmptySlot()
        self:RefreshSlotLayout()
        self:PopExpandTip()
    end)

    Event.Reg(self, "UPDATE_BANK_SLOT", function()
        self:RefreshSlotLayout()
    end)

    Event.Reg(self, EventType.OnWareHouseUseExpandItem, function(dwPackageID)
        self:ExchangePackage(dwPackageID)
    end)
end

function UIWareHouseExpand:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWareHouseExpand:RefreshSlotLayout()
    UIHelper.RemoveAllChildren(self.LayoutBagCell)
    self.tbSlotScrips = {}
    self.tbScriptSlotItem = {}

    local nCount = g_pClientPlayer.GetBankPackageCount()
    for i, tbItemInfo in ipairs(ItemData.GetBoxSlotItemList(INVENTORY_INDEX.EQUIP, tbBankExpandSlot)) do
        local scripts = UIHelper.AddPrefab(PREFAB_ID.WidgetWareHouseExpandCell, self.LayoutBagCell)
        table.insert(self.tbSlotScrips, scripts)

        --UIHelper.SetToggleGroupIndex(scripts.ToggleAdd, 10086)
        UIHelper.BindUIEvent(scripts.BtnShopping, EventType.OnClick, function()
            self:BuyPackage()
        end)

        UIHelper.BindUIEvent(scripts.ToggleAdd, EventType.OnSelectChanged, function(_, bValue)
            if bValue then
                self.nIndex = i
                self:PopExpandTip(i)
            end
        end)

        if i <= nCount then
            UIHelper.SetVisible(scripts.BtnShopping, false)
            UIHelper.SetVisible(scripts.WidgetItemAdd, true)
        end

        if tbItemInfo.hItem then
            local itemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, scripts.WidgetGoods)
            self:UpdateItemIcon(itemIcon, tbItemInfo.nBox, tbItemInfo.nIndex)
            self.tbScriptSlotItem[tbItemInfo.nIndex + 1] = itemIcon

            local nSize = ItemData.GetBagSize({ BankPackage[i] })
            local szText = string.format(g_tStrings.STR_BAG_SIZE, nSize)
            UIHelper.SetString(scripts.LabelBagContainer, szText)
        end

        UIHelper.SetVisible(scripts.ImgBagContainerBg, tbItemInfo.hItem ~= nil)
        UIHelper.SetVisible(scripts.LabelBagContainer, tbItemInfo.hItem ~= nil)
    end

    if nCount >= 1 then
        UIHelper.SetString(self.LabelDescibe01, "暂未拥有仓库升级物品")
    end

    if self.nIndex then
        UIHelper.SetSelected(self.tbSlotScrips[self.nIndex].ToggleAdd, true, false)
    end

    --self:UpdateSlotSelectedToggle()
    UIHelper.LayoutDoLayout(self.LayoutBagCell)
end

function UIWareHouseExpand:BuyPackage()
    local player = GetClientPlayer()
    local nCount = player.GetBankPackageCount()
    if nCount >= GLOBAL.MAX_BANK_PACKAGE_COUNT then
        return
    end
    local nMoney = GetBankPackagePrice(nCount + 1)
    local msg = nil

    msg = {
        szMessage = g_tStrings.MSG_BUY_WAREHOUSE_PANEL_NEED_MONEY ..
                UIHelper.GetMoneyTipText(nMoney, false) .. "\n" .. g_tStrings.MSG_SURE_BUY_WAREHOUSE_BAG_PANEL,
        szName = "BuyBagSure",
        fnAction = function()
            if MoneyOptCmp(nMoney, player.GetMoney()) > 0 then
                OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.g_ShopStrings[SHOP_SYSTEM_RESPOND_CODE.NOT_ENOUGH_MONEY])
            else
                player.EnableBankPackage()
            end
        end
    }

    UIHelper.ShowConfirm(msg.szMessage, msg.fnAction, nil, true)
end

function UIWareHouseExpand:UpdateInfo()
    --self:UpdateBankSize()
    --self:UpdateBagItemList()
end

function UIWareHouseExpand:ExchangePackage(nSelectedItemID, nTargetSlotIndex)
    if not nSelectedItemID then
        return
    end

    if g_pClientPlayer.GetBankPackageCount() == 0 then
        TipsHelper.ShowNormalTip(g_tStrings.tItem_Msg[ITEM_RESULT_CODE.BANK_PACKAGE_DISABLED])
        return
    end

    local hItem, nItemBox, nItemIndex = ItemData.GetItem(nSelectedItemID)
    if not nTargetSlotIndex then
        nTargetSlotIndex = self:GetOptimalSlotIndex(hItem, nItemBox, nItemIndex)
        if not nTargetSlotIndex then
            return TipsHelper.ShowNormalTip("当前的包裹大小比已装备的包裹都小，无法直接更换")
        end
    end

    --local dwBox, dwIndex = ItemData.GetItemPos(nSelectedItemID)
    local bRes = ItemData.ExchangeItem(nItemBox, nItemIndex, INVENTORY_INDEX.EQUIP, nTargetSlotIndex)
    if bRes then
        TipsHelper.ShowNormalTip("仓库扩容成功")
    end 
end

function UIWareHouseExpand:GetOptimalSlotIndex(hItem, nItemBox, nItemIndex)
    local nMinSize
    local nOptimalSlotIndex = nil

    if not hItem or not nItemBox then
        return nOptimalSlotIndex
    end

    if not self:CanPutPackage(hItem.nCurrentDurability) then
        TipsHelper.ShowNormalTip("当前的包裹大小比已装备的包裹都小，无法直接更换")
    else
        local nCount = g_pClientPlayer.GetBankPackageCount()
        for i = 1, nCount, 1 do
            local nEquipBankPackageIndex = tbBankExpandSlot[i]
            local nSize = ItemData.GetBagSize({ BankPackage[i] })
            if not nMinSize or nSize < nMinSize then
                local bCanExchange = ItemData.CanExchangeItem(nItemBox, nItemIndex, INVENTORY_INDEX.EQUIP, nEquipBankPackageIndex)
                if bCanExchange then
                    nMinSize = nSize
                    nOptimalSlotIndex = nEquipBankPackageIndex
                end
            end
        end
        return nOptimalSlotIndex
    end
end

function UIWareHouseExpand:SelectNextEmptySlot()
    local nCount = g_pClientPlayer.GetBankPackageCount()
    local nIndex = nCount
    for i = 1, nCount, 1 do
        local nSize = ItemData.GetBagSize({ BankPackage[i] })
        if nSize == 0 then
            nIndex = i
            break
        end
    end

    self.nIndex = nIndex
end

--背包满 且 当前扩容背包容量比所有格子容量都小时不可放入
function UIWareHouseExpand:CanPutPackage(nCapacity)
    local nCount = g_pClientPlayer.GetBankPackageCount()
    for i = 1, nCount, 1 do
        local nSize = ItemData.GetBagSize({ BankPackage[i] })
        if nSize == 0 or nCapacity > nSize then
            return true
        end
    end

    return false
end

function UIWareHouseExpand:UpdateItemIcon(itemScript, nBox, nIndex)
    itemScript:OnInit(nBox, nIndex)
    itemScript:SetSelectEnable(false)
    itemScript:HideLabelCount()
    itemScript:SetRecallCallback(function()
        ItemData.UnEquipItem(nBox, nIndex)
        --PutItemToBank(nBox, nIndex, 1)
    end)
    itemScript:SetRecallVisible(true)
end

function UIWareHouseExpand:SetVisibility(bSelected)
    if not bSelected then
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetClickFeeding)
        UIHelper.SetVisible(self.WidgetWareHouseUp, false)
        UIHelper.SetVisible(self.LayoutBottomBtn, true)
    else
        UIHelper.SetVisible(self.WidgetWareHouseUp, true)
        UIHelper.SetVisible(self.LayoutBottomBtn, false)

        local nIndex = self:GetFirstExpandCell()    --默认选中一个格子弹弹窗
        UIHelper.SetSelected(self.tbSlotScrips[nIndex].ToggleAdd, true)
    end
end

function UIWareHouseExpand:Hide()
    UIHelper.SetVisible(self.WidgetWareHouseUp, false)
    UIHelper.SetVisible(self.LayoutBottomBtn, true)
end

local function BankIndexToInventoryIndex(nIndex)
    return INVENTORY_INDEX.BANK + nIndex - 1
end

function UIWareHouseExpand:GetExpandItem()
    local player = g_pClientPlayer
    local tExpandItemList = {}
    for i, nBox in ipairs(ItemData.BoxSet.Bag) do
        for k, tbItemInfo in ipairs(ItemData.GetBoxItem(nBox)) do
            local bShowItem = tbItemInfo.hItem and tbItemInfo.hItem .nSub == EQUIPMENT_SUB.PACKAGE
            if bShowItem then
                table.insert(tExpandItemList, tbItemInfo.hItem)
            end
        end
    end

    for i = 1, 6, 1 do
        local dwBox = BankIndexToInventoryIndex(i)
        local dwSize = player.GetBoxSize(dwBox)
        dwSize = dwSize - 1

        for dwX = 0, dwSize, 1 do
            local hItem = ItemData.GetPlayerItem(player, dwBox, dwX)
            local bShowItem = hItem and hItem.nSub == EQUIPMENT_SUB.PACKAGE
            if bShowItem then
                table.insert(tExpandItemList, hItem)
            end
        end
    end

    return tExpandItemList
end

function UIWareHouseExpand:PopExpandTip(nSlotIndex)
    if not UIHelper.GetHierarchyVisible(self._rootNode) then
        return
    end
    nSlotIndex = nSlotIndex or self.nIndex

    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetClickFeeding)
    local tip, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetClickFeeding, self.LayoutBagCell, TipsLayoutDir.TOP_CENTER)
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
                --if nStackNum > 0 then
                --    itemIcon:SetIconCount(nStackNum)
                --end

                local nSize = ItemData.GetBagSize({ BankPackage[nSlotIndex] })
                local bAvailable = nExpandCount >= nSize
                 itemIcon:SetClickCallback(function(dwTabType, dwIndex)
                    local function DoExchangeCheck(hItem, nSlotIndex, bAvailable)
                        if bAvailable then
                            self:ExchangePackage(hItem.dwID, tbBankExpandSlot[nSlotIndex])
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
                Timer.AddFrame(self,1,function()
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

--function UIWareHouseExpand:TryExchange(nSlotIndex, nCapacity)
--    local nEquipBankPackageIndex = tbBankExpandSlot[nSlotIndex]
--    local nSize = ItemData.GetBagSize({ BankPackage[nSlotIndex] })
--
--    local bCanExchange = ItemData.CanExchangeItem(nItemBox, nItemIndex, INVENTORY_INDEX.EQUIP, nEquipBankPackageIndex)
--    if bCanExchange then
--        nMinSize = nSize
--        nOptimalSlotIndex = nEquipBankPackageIndex
--    end
--
--    return nOptimalSlotIndex
--end

function UIWareHouseExpand:GetFirstExpandCell()
    local nIndex = 1
    local nCount = g_pClientPlayer.GetBankPackageCount()
    for i, tbItemInfo in ipairs(ItemData.GetBoxSlotItemList(INVENTORY_INDEX.EQUIP, tbBankExpandSlot)) do
        local nSize = ItemData.GetBagSize({ BankPackage[i] })
        if i <= nCount and nSize == 0 then
            nIndex = i
            return nIndex
        end
    end
    return nIndex
end

return UIWareHouseExpand