-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBookItem
-- Date: 2022-12-09 10:31:03
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelMysteryRightBag = class("UIPanelMysteryRightBag")

function UIPanelMysteryRightBag:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self.nTotalCount = 0
        self.tbSelected = {
            tbBatch = {},
            tbPos = {}
        }
    end
    self:UpdateInfo()
end

function UIPanelMysteryRightBag:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelMysteryRightBag:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnMove, EventType.OnClick, function()
        self:Store()
    end)
end

function UIPanelMysteryRightBag:RegEvent()
    Event.Reg(self, "ON_CHANGE_MYSTERY_PENDANT_ITEM_NOTIFY", function()
        --print("UIPanelMysteryRightBag")
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function(nBox, nIndex, bNewAdd)
        if self.scriptItemTip then
            self.scriptItemTip:OnInit()
            return
        end
    end)

    Event.Reg(self, EventType.EmailBagItemSelected, function(nBox, nIndex, nCount)
        local item = ItemData.GetItemByPos(nBox, nIndex)
        if item and self.tbSelected.tbBatch and self.tbSelected.tbBatch[item.dwID] then
            self.tbSelected.tbBatch[item.dwID] = nCount

            Event.Dispatch(EventType.OnSetUIItemIconChoose, true, nBox, nIndex, nCount)

            if self.scriptItemTip then
                UIHelper.SetVisible(self.scriptItemTip._rootNode, false)
            end
        end
    end)
end

function UIPanelMysteryRightBag:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIPanelMysteryRightBag:UpdateInfo()
    self:UpdatePendantCell()
    self:UpdateBatchSelectNum()
end

function UIPanelMysteryRightBag:UpdatePendantCell()
    self.tbBox = {}
    self.nTotalCount = 0

    local cellNodes = UIHelper.GetChildren(self.ScrollBag)
    for _, cellNode in ipairs(cellNodes) do
        ItemData.GetBagCellPrefabPool():Recycle(cellNode)
    end

    local tbBoxSet = ItemData.BoxSet.Bag
    local bHsCell = false
    for i, nBox in ipairs(tbBoxSet) do
        for k, tbItemInfo in ipairs(ItemData.GetBoxItem(nBox)) do
            local bShowItem = tbItemInfo.hItem and tbItemInfo.hItem.nGenre == ITEM_GENRE.MYSTERY_ITEM
            if bShowItem then
                local cellScript = select(2, ItemData.GetBagCellPrefabPool():Allocate(self.ScrollBag))
                cellScript:OnEnter(tbItemInfo.nBox, tbItemInfo.nIndex)
                local itemScript = cellScript:GetItemScript()
                if itemScript then
                    bHsCell = true

                    local bIsNewItem = BagViewData.IsNewItem(tbItemInfo.nBox, tbItemInfo.nIndex)
                    itemScript:SetToggleGroup(self.ToggleGroup)
                    itemScript:SetSelectMode(true, true)
                    itemScript:SetSelectChangeCallback(function(dwItemID, bSelected)
                        self:OnItemSelectChange(dwItemID, bSelected)
                    end)
                    itemScript:SetNewItemFlag(bIsNewItem)
                    itemScript:SetHandleChooseEvent(true)

                    self.nTotalCount = self.nTotalCount + 1
                    self:StoreCellScript(tbItemInfo.nBox, tbItemInfo.nIndex, cellScript)
                end
            end
        end
    end

    UIHelper.SetVisible(self.WidgetEmpty, not bHsCell)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollBag)
end

local fnExchangeClick = function(nCount, nBox, nIndex)
    if g_pClientPlayer then
        g_pClientPlayer.PutMysteryPendantItemToBox(nBox, nIndex)
        Event.Dispatch(EventType.HideAllHoverTips)
    end
end

function UIPanelMysteryRightBag:UpdateSelectedItemDetails()
    if not self.scriptItemTip then
        self.scriptItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemDetail)
        self.scriptItemTip:SetForbidShowEquipCompareBtn(true)
        self.scriptItemTip:SetForbidAutoShortTip(true)
    end

    if self.scriptItemTip then
        self.scriptItemTip:ShowSplitWidget(false)
        self.scriptItemTip:ShowPlacementBtn(false, 0, 0)
        self.scriptItemTip:ShowSellWidget(false)

        local hItem = ItemData.GetItemByPos(self.tbSelected.nBox, self.tbSelected.nIndex)
        local nStackNum = ItemData.GetItemStackNum(hItem)
        local szCountTitle = g_tStrings.STR_DISCARD_COUNT
        local szConfirmLabel = g_tStrings.STR_DISCARD_SURE
        if hItem then
            local tbFuncButtons = {}
            self.scriptItemTip:ShowWareHouseSlider(nStackNum, nStackNum, szConfirmLabel, szCountTitle, fnExchangeClick, tbFuncButtons)
            self.scriptItemTip:ShowWareHousePreviewSlider(hItem.dwTabType, hItem.dwIndex)
        end

        self.scriptItemTip:OnInit(self.tbSelected.tbPos.nBox, self.tbSelected.tbPos.nIndex)
    end
end

function UIPanelMysteryRightBag:OnItemSelectChange(dwItemID, bSelected)
    if bSelected then
        local nBox, nIndex = ItemData.GetItemPos(dwItemID)
        self.tbSelected.tbPos = { nBox = nBox, nIndex = nIndex }

        local hItem = ItemData.GetItem(dwItemID)
        local nStackNum = ItemData.GetItemStackNum(hItem)
        self.tbSelected.tbBatch[dwItemID] = nStackNum

        local nBox, nIndex = ItemData.GetItemPos(dwItemID)
        if nBox and nIndex then
            Event.Dispatch(EventType.OnSetUIItemIconChoose, true, nBox, nIndex, nStackNum)
        end
    else
        self.tbSelected.tbPos = { nBox = nil, nIndex = nil }
        self.tbSelected.tbBatch[dwItemID] = nil

        local nBox, nIndex = ItemData.GetItemPos(dwItemID)
        if nBox and nIndex then
            Event.Dispatch(EventType.OnSetUIItemIconChoose, false, nBox, nIndex, 0)
        end
    end

    self:RemoveNewItemFlag(dwItemID)
    self:UpdateBatchSelectNum()
    self:UpdateSelectedItemDetails()
end

function UIPanelMysteryRightBag:UpdateBatchSelectNum()
    UIHelper.SetString(self.LabelSelectNum, string.format("(%d/%d)", table.get_len(self.tbSelected.tbBatch), self.nTotalCount))
end

function UIPanelMysteryRightBag:RemoveNewItemFlag(dwItemID)
    local nBox, nIndex = ItemData.GetItemPos(dwItemID)
    if not nBox then
        return
    end
    BagViewData.RecordNewItem(nBox .. "_" .. nIndex, dwItemID, false)

    local scriptCell = self:GetCellScript(nBox, nIndex)
    if scriptCell then
        local itemScript = scriptCell:GetItemScript()
        if itemScript then
            itemScript:SetNewItemFlag(false)
        end
    end
end

function UIPanelMysteryRightBag:StoreCellScript(nBox, nIndex, script)
    self.tbBox[nBox + 1] = self.tbBox[nBox + 1] or {}
    self.tbBox[nBox + 1][nIndex + 1] = script
end

function UIPanelMysteryRightBag:GetCellScript(nBox, nIndex)
    if not self.tbBox[nBox + 1] then
        return nil
    end

    return self.tbBox[nBox + 1][nIndex + 1]
end

function UIPanelMysteryRightBag:Store()
    local pPlayer = g_pClientPlayer
    if not pPlayer or table.get_len(self.tbSelected.tbBatch) <= 0 then
        return
    end
    local bSuccess = true
    for dwItemID, nStackNum in pairs(self.tbSelected.tbBatch) do
        local dwBox, dwX = ItemData.GetItemPos(dwItemID)
        local nRetCode = pPlayer.PutMysteryPendantItemToBox(dwBox, dwX)
        if nRetCode ~= MYSTERY_ITEM_ERROR_CODE.SUCCESS then
            bSuccess = false
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.tCollectionResult[nRetCode])
            --OutputMessage("MSG_SYS", g_tStrings.tCollectionResult[nRetCode])
            break
        end
    end
    if bSuccess then
        OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.tCollectionResult[MYSTERY_ITEM_ERROR_CODE.SUCCESS])
        --OutputMessage("MSG_SYS", g_tStrings.tCollectionResult[MYSTERY_ITEM_ERROR_CODE.SUCCESS])
    end

    self.tbSelected.tbBatch = {}
end

return UIPanelMysteryRightBag