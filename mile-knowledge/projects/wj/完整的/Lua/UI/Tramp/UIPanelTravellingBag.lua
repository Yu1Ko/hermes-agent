-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelTravellingBag
-- Date: 2023-04-17 15:14:08
-- Desc: ?
-- ---------------------------------------------------------------------------------
local MAX_BRAEK_EQUIP_COUNT = 10

local BATCH_TYPE = {
    Destroy = 1,
    Sell = 2,
    WareHouse = 3,
    Break = 4,
}

local UIPanelTravellingBag = class("UIPanelTravellingBag")

function UIPanelTravellingBag:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.bBatchSelect = false
    self.tbSelected = { dwItemID = nil, tbPos = { nBox = nil, nIndex = nil }, tbBatch = nil }
    self:UpdateInfo()
end

function UIPanelTravellingBag:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelTravellingBag:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnBatchDiscard, EventType.OnClick, function ()
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.BANK) or BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP, "destroy") then
            return
        end

        self.bBatchType = BATCH_TYPE.Destroy
        self:EnterBatch()
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function ()
        self:CancelBatch()
    end)
    UIHelper.BindUIEvent(self.BtnAll, EventType.OnClick, function ()
        if not empty(self.tbSelected.tbBatch) then
            self:ConfirmBatch()
        end
    end)

    UIHelper.BindUIEvent(self.BtnNeaten, EventType.OnClick, function()
        TravellingBagData.BeginSort()
    end)

end

function UIPanelTravellingBag:RegEvent()
    Event.Reg(self, "BAG_ITEM_UPDATE", function(nBox, nIndex, bNewAdd)
        local item = ItemData.GetItemByPos(nBox, nIndex)

        -- 更新选中道具详细信息
        if (item and item.dwID == self.tbSelected.dwItemID) or (nBox == self.tbSelected.tbPos.nBox and nIndex == self.tbSelected.tbPos.nIndex) then
            self:DoUpdateSelect(self.tbSelected.dwItemID, self.tbSelected.itemScript)
        end

        -- 更新背包格子计数（used/total）
        if bNewAdd or not item then
            self:UpdateBagSize()
            -- self:UpdateEmptyWidget()
        end

        -- 更新格子
        local scriptCell = self:GetCellScript(nBox, nIndex)
        if scriptCell then
            scriptCell:UpdateInfo()
            local bIsNewItem = BagViewData.IsNewItem(nBox, nIndex)
            local itemScript = scriptCell:GetItemScript()
            self:InitItemScript(itemScript, bIsNewItem, nBox, nIndex)
        else
            self:UpdateCell()
        end
    end)

    Event.Reg(self, "DO_CUSTOM_OTACTION_PROGRESS", function (nTotalFrame, szActionName, nType)
        if nTotalFrame and nTotalFrame > 0 then
            local tParam = {
                szType = "Normal",
                szFormat = UIHelper.GBKToUTF8(szActionName),
                nDuration = nTotalFrame / GLOBAL.GAME_FPS,
                fnCancel = function ()
                    GetClientPlayer().StopCurrentAction()
                end
            }
            -- UIMgr.Open(VIEW_ID.PanelSystemPrograssBar, tParam)
            TipsHelper.PlayProgressBar(tParam)
        end
    end)

    Event.Reg(self, EventType.OnTouchViewBackGround, function()
        self:TryCloseOrDismissTip()
    end)

    Event.Reg(self, EventType.OnSceneTouchTarget, function()
        self:TryCloseOrDismissTip()
    end)

    Event.Reg(self, EventType.OnSceneTouchNothing, function()
        self:TryCloseOrDismissTip()
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        if self.bBatchSelect then return end
        self:CloseTip()
    end)

    Event.Reg(self, EventType.EmailBagItemSelected, function(nBox, nIndex, nCount)
        local item = ItemData.GetItemByPos(nBox, nIndex)
        if item and item.dwID == self.tbSelected.dwItemID and self.tbSelected.tbBatch and self.tbSelected.tbBatch[item.dwID] then
            self.tbSelected.tbBatch[item.dwID] = nCount

            Event.Dispatch(EventType.OnSetUIItemIconChoose, true, nBox, nIndex, nCount)

            if self.scriptItemTip then
                UIHelper.SetVisible(self.scriptItemTip._rootNode, false)
            end
        end
    end)

end

function UIPanelTravellingBag:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelTravellingBag:UpdateInfo()
    self:UpdateBagSize()
    self:UpdateCell()
end

function UIPanelTravellingBag:UpdateBagSize()
    UIHelper.SetString(self.LabelNum, string.format("(%d/%d)",
        ItemData.GetBagUsedSize(ItemData.BoxSet.TravellingBag),
        ItemData.GetBagSize(ItemData.BoxSet.TravellingBag)
    ))
end

function UIPanelTravellingBag:DeselectAll()
    self.tbSelected = { tbPos = {} }
    self:DoUpdateSelect(nil)
end



function UIPanelTravellingBag:TraverseCellScript(func)
    for nBoxKey, tbScriptList in pairs(self.tbBox) do
        for nIndexKey, Script in pairs(tbScriptList) do
            func(Script, nBoxKey - 1, nIndexKey -1)
        end
    end
end


function UIPanelTravellingBag:UpdateBatchSelectNum()
    local nCount = 0

    self:TraverseCellScript(function(CellScript, _nBox, _nIndex)
        if CellScript:GetItemScript() then
            nCount = nCount + 1
        end
    end)

    nCount = math.min(MAX_BRAEK_EQUIP_COUNT, nCount) -- 背包批量最大数量都限制为10

    self.nBatchMaxCount = nCount

    UIHelper.SetString(self.LabelSelectedNum, string.format("%d/%d",
        table.get_len(self.tbSelected.tbBatch),
        nCount
    ))
end

function UIPanelTravellingBag:UpdateCell()
    UIHelper.RemoveAllChildren(self.ScrollViewBag)
    local bHasItem = false
    local FirstItemScript = nil
    self.tbBox = {}
    local tbItemList = TravellingBagData.GetTravellingBagItems()
    for index, tbItemInfo in ipairs(tbItemList) do
        -- body
        if tbItemInfo.hItem then

            bHasItem = true
            local cellScript = UIHelper.AddPrefab(PREFAB_ID.WidgetBagBottom, self.ScrollViewBag)
            cellScript:OnEnter(tbItemInfo.nBox, tbItemInfo.nIndex)
            local itemScript = cellScript:GetItemScript()
            cellScript:SetTouchDownHideTips(false)
            local bIsNewItem = BagViewData.IsNewItem(tbItemInfo.nBox, tbItemInfo.nIndex)
            self:InitItemScript(itemScript, bIsNewItem, tbItemInfo.nBox, tbItemInfo.nIndex)
            self:StoreCellScript(tbItemInfo.nBox, tbItemInfo.nIndex, cellScript)

            if not FirstItemScript then
                FirstItemScript = itemScript
            end
        end
    end
    UIHelper.ScrollViewDoLayout(self.ScrollViewBag)
    UIHelper.ScrollToTop(self.ScrollViewBag)
    UIHelper.SetVisible(self.WidgetEmpty, not bHasItem)
    UIHelper.SetSwallowTouches(self.ScrollViewBag, false)

    -- if FirstItemScript then
    --     FirstItemScript:SetSelected(true)
    -- end
end

function UIPanelTravellingBag:InitItemScript(itemScript, bIsNewItem, nBox, nIndex)
    if itemScript then
        itemScript.bIsNewItem = bIsNewItem -- 用于判断新道具数量
        itemScript:EnableTimeLimitFlag(true)
        itemScript:SetToggleGroup(self.ToggleGroupBag)
        itemScript:SetHandleChooseEvent(true)
        itemScript:SetSelectMode(self.bBatchSelect, true)
        -- itemScript:SetNewItemFlag(bIsNewItem)
        itemScript:SetSelectChangeCallback(function(dwItemID, bSelected)
            self:OnItemSelectChange(dwItemID, bSelected, itemScript)
        end)
        -- self:SetNodeGray(itemScript, nBox, nIndex)
    end
end

-- function UIPanelTravellingBag:SetNodeGray(ItemScript, _nBox, _nIndex)
--     if ItemScript and _nBox and _nIndex then
--         ItemScript:SetSelectMode(self.bBatchSelect, true)
--         local bNotWareHouseOperation = self.bWareHouse and self.tbWareHouseFunctions.fnValid and not self.tbWareHouseFunctions.fnValid(_nBox, _nIndex)
--         UIHelper.SetNodeGray(ItemScript.ImgIcon, bNotWareHouseOperation, true)
--         UIHelper.SetOpacity(ItemScript._rootNode, not bNotWareHouseOperation and 255 or 120)
--     end
-- end

function UIPanelTravellingBag:OnItemSelectChange(dwItemID, bSelected, itemScript)
    if bSelected then
        self:DoUpdateSelect(dwItemID, itemScript)
        if self.bBatchSelect then
            local hItem = ItemData.GetItem(dwItemID)
            local nStackNum = ItemData.GetItemStackNum(hItem)
            local nBox, nIndex = ItemData.GetItemPos(dwItemID)

            local fnDeselect = function()
                Timer.AddFrame(self, 1, function()
                    local scriptCell = self:GetCellScript(nBox, nIndex, self.nBagViewType)
                    if scriptCell then
                        local itemScript = scriptCell:GetItemScript()
                        if itemScript then
                            itemScript:RawSetSelected(false)
                        end
                    end
                end)
            end

            if table.get_len(self.tbSelected.tbBatch) >= self.nBatchMaxCount then
                fnDeselect()
                TipsHelper.ShowImportantRedTip("已达最大批量数目")
                return
            end

            self.tbSelected.tbBatch[dwItemID] = nStackNum

            --local nBox, nIndex = ItemData.GetItemPos(dwItemID)
            if nBox and nIndex then
                Event.Dispatch(EventType.OnSetUIItemIconChoose, true, nBox, nIndex, nStackNum)
            end
        end
    else
        if self.tbSelected.dwItemID == dwItemID then
            self:DoUpdateSelect(nil)
        end
    end

    if self.bBatchSelect then
        self:UpdateBatchSelectNum()
    end
    self:UpdateSelectedItemDetails()
end

function UIPanelTravellingBag:EnterBatch()
    if not self.bBatchSelect then
        self:DeselectAll()
        self.nBatchMaxCount = 0
        self.bBatchSelect = true
        UIHelper.SetVisible(self.WidgetAniDiscard, true)
        self.tbSelected.tbBatch = self.tbSelected.tbBatch or {}
        self:TraverseCellScript(function(CellScript, _nBox, _nIndex)
            local ItemScript = CellScript:GetItemScript()
            if ItemScript then
                ItemScript:SetSelectMode(true, true)
                if not self.bWareHouse then
                    local item = ItemData.GetItemByPos(_nBox, _nIndex)
                    local bNotSellable = self.bBatchType == BATCH_TYPE.Sell and not item.bCanTrade
                    local bNotBreakable = self.bBatchType == BATCH_TYPE.Break and not EquipData.CanBreak(_nBox, _nIndex)

                    UIHelper.SetNodeGray(ItemScript.ImgIcon, bNotSellable or bNotBreakable, true)
                    UIHelper.SetOpacity(ItemScript._rootNode, not (bNotSellable or bNotBreakable) and 255 or 120)
                end
            end
        end)

        self:UpdateBatchSelectNum()
    end
end

function UIPanelTravellingBag:CancelBatch()
    if self.bBatchSelect then
        self:DeselectAll()
        self.bBatchSelect = false

        UIHelper.SetVisible(self.WidgetAniDiscard, false)
        self:TraverseCellScript(function(CellScript, nBox, nIndex)
            local ItemScript = CellScript:GetItemScript()
            if ItemScript then
                ItemScript:SetSelectMode(false, true)
                if not self.bWareHouse then
                    --UIHelper.SetNodeGray(ItemScript._rootNode, false, true)
                    UIHelper.SetNodeGray(ItemScript.ImgIcon, false, true)
                    UIHelper.SetOpacity(ItemScript._rootNode, 255)
                end
                Event.Dispatch(EventType.OnSetUIItemIconChoose, false, nBox, nIndex, 0)
            end
        end)

    end
end

function UIPanelTravellingBag:ConfirmBatch()

    local confirmDialog = UIHelper.ShowConfirm(g_tStrings.tbItemString.BATCH_DISCARD_ITEM_CONFIRM, function()
        self:CloseTip()
        for dwItemID, dwSplitAmount in pairs(self.tbSelected.tbBatch) do
            local nBox, nIndex = ItemData.GetItemPos(dwItemID)
            ItemData.DestroyItem(nBox, nIndex, dwSplitAmount)
        end
        self:CancelBatch()
    end, nil, true)

    confirmDialog:SetButtonContent("Confirm", g_tStrings.STR_HOTKEY_SURE)
end

function UIPanelTravellingBag:DoUpdateSelect(dwItemID, itemScript)
    self.tbSelected.dwItemID = dwItemID
    self.tbSelected.itemScript = itemScript

    if self.tbSelected.dwItemID then
        local nBox, nIndex = ItemData.GetItemPos(self.tbSelected.dwItemID)
        if not nBox or not table.contain_value(ItemData.BoxSet.TravellingBag, nBox) then   -- 如果选中道具已经不在背包中
            local item = ItemData.GetItemByPos(self.tbSelected.tbPos.nBox, self.tbSelected.tbPos.nIndex) -- 用选中的格子信息找到新的选中道具
            if item then
                self.tbSelected.dwItemID = item.dwID
            else                            -- 选中的格子中页没有新的道具，无选中
                self.tbSelected.dwItemID = nil
                self.tbSelected.tbPos = {nBox = nil, nIndex = nil}
            end
        else
            self.tbSelected.tbPos = {nBox = nBox, nIndex = nIndex}
        end
    else
        self.tbSelected.tbPos = {nBox = nil, nIndex = nil}
    end
    self:UpdateSelectedItemDetails()
end

function UIPanelTravellingBag:UpdateSelectedItemDetails()
    if not self.tbSelected.tbPos.nBox then return end
    if not self.scriptItemTip then
        self.scriptItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetCard)
    end

    if self.scriptItemTip then

        local hItem, nBox, nIndex = ItemData.GetItem(self.tbSelected.dwItemID)
        local nStackNum = ItemData.GetItemStackNum(hItem)

        self.scriptItemTip:ShowSplitWidget(false)
        self.scriptItemTip:ShowPlacementBtn(false, 0, 0)
        self.scriptItemTip:ShowSellWidget(false)
        self.scriptItemTip:ShowMulitUseWidget(false)
        if self.scriptItemTip.scriptItemIcon then
            self.scriptItemTip.scriptItemIcon:ShowEquipScoreArrow(true)
        end

        self.scriptItemTip:ShowPlacementBtn(self.bBatchSelect, nStackNum, nStackNum, g_tStrings.STR_DISCARD_SURE, g_tStrings.STR_DISCARD_COUNT)
        self.scriptItemTip:SetFunctionButtons(self.bBatchSelect and {} or nil)
        self.scriptItemTip:OnInit(self.tbSelected.tbPos.nBox, self.tbSelected.tbPos.nIndex)

        self:InitEquipedPage(hItem, self.bBatchSelect)
    end
end

function UIPanelTravellingBag:InitEquipedPage(hItem, bForbidShow)
    if bForbidShow or not hItem or self.bWareHouse then
        if self.scriptEquipedItemTip then
            UIHelper.SetVisible(self.scriptEquipedItemTip._rootNode, false)
        end
        return
    end
    local item = hItem
    local nEquipIndex = EquipData.GetEquipInventory(item.nSub, item.nDetail)
    if not item or item.nGenre ~= ITEM_GENRE.EQUIPMENT or not nEquipIndex then
        if self.scriptEquipedItemTip then
            UIHelper.SetVisible(self.scriptEquipedItemTip._rootNode, false)
        end
        return
    end
    if not self.scriptEquipedItemTip then
        self.scriptEquipedItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetTipNowEquip)
        -- self.scriptEquipedItemTip:SetForbidAutoShortTip(true)
        self.scriptEquipedItemTip:SetForbidShowEquipCompareBtn(true)
        self.scriptEquipedItemTip:ShowCompareEquipTip(true)
        self.scriptEquipedItemTip:ShowRingSwitch(true)
    end
    local hEquipedItem = ItemData.GetItemByPos(INVENTORY_INDEX.EQUIP, nEquipIndex)
    if not hEquipedItem and nEquipIndex == EQUIPMENT_INVENTORY.LEFT_RING then
        nEquipIndex = EQUIPMENT_INVENTORY.RIGHT_RING    --默认获取左戒指，没有就尝试一波获取右戒指
        hEquipedItem = ItemData.GetItemByPos(INVENTORY_INDEX.EQUIP, nEquipIndex)
    end

    if self.scriptEquipedItemTip and hEquipedItem then
        self.scriptEquipedItemTip:OnInit(INVENTORY_INDEX.EQUIP, nEquipIndex)
        self.scriptEquipedItemTip:ShowCurEquipImg(true)
        UIHelper.SetVisible(self.scriptEquipedItemTip._rootNode, true)
        self.scriptEquipedItemTip:UpdateScrollViewHeight(480)
        self.scriptItemTip:UpdateScrollViewHeight(480)
    end
end


function UIPanelTravellingBag:CloseTip()
    if self.scriptItemTip then
        if self.tbSelected.itemScript then
            self.tbSelected.itemScript:SetSelected(false)
        end
        UIHelper.RemoveAllChildren(self.WidgetCard)
        self.scriptItemTip = nil
    end
    if self.scriptEquipedItemTip then
        UIHelper.SetVisible(self.scriptEquipedItemTip._rootNode, false)
    end
end

function UIPanelTravellingBag:TryCloseOrDismissTip()
    if self.scriptItemTip and UIHelper.GetVisible(self.scriptItemTip._rootNode) then
        self:CloseTip()
        return
    end

    if self.scriptEquipedItemTip and UIHelper.GetVisible(self.scriptEquipedItemTip._rootNode) then
        UIHelper.SetVisible(self.scriptEquipedItemTip._rootNode, false)
        return
    end

    UIMgr.Close(self)
end



function UIPanelTravellingBag:StoreCellScript(nBox, nIndex, script)
    self.tbBox[nBox + 1] = self.tbBox[nBox + 1] or {}
    self.tbBox[nBox + 1][nIndex + 1] = script
end

function UIPanelTravellingBag:GetCellScript(nBox, nIndex)
    if not self.tbBox[nBox + 1] then
        return nil
    end

    return self.tbBox[nBox + 1][nIndex + 1]
end


return UIPanelTravellingBag