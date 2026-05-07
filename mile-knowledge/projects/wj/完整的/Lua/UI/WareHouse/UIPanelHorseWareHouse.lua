-- ---------------------------------------------------------------------------------
-- Author: JiaYuRan
-- Name: UIPanelWareHouse
-- ---------------------------------------------------------------------------------

local UIPanelHorseWareHouse = class("UIPanelHorseWareHouse")

local function GetFirstFreeRoom()
    local player = g_pClientPlayer
    local nHaveCount = player.dwCubPackageSize
    local dwBox = INVENTORY_INDEX.CUB_PACKAGE

    for dwX = 0, nHaveCount - 1, 1 do
        local hItem = ItemData.GetPlayerItem(player, dwBox, dwX)
        if not hItem then
            return dwBox, dwX
        end
    end
end

local function OnExchangeBoxAndHandBoxItem(dwBox, dwX)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local hItem = ItemData.GetPlayerItem(hPlayer, dwBox, dwX)
    if not hItem then
        return
    end

    local dwTargetBox, dwTargetX
    local dwBoxType = hPlayer.GetBoxType(dwBox)
    if dwBoxType == INVENTORY_TYPE.CUB_PACKAGE then
        dwTargetBox, dwTargetX = hPlayer.GetStackRoomInPackage(dwBox, dwX)
        if dwTargetBox and dwTargetX then
            ItemData.OnExchangeItem(dwBox, dwX, dwTargetBox, dwTargetX)
            return true
        else
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_ERROR_PACKAGE_IS_FULL);
        end
    end

    if dwBoxType == INVENTORY_TYPE.PACKAGE then
        if (hItem.nGenre ~= ITEM_GENRE.CUB or hItem.nSub ~= DOMESTICATE_CUB_SUB_TYPE.FOAL) and
                (hItem.nGenre ~= ITEM_GENRE.EQUIPMENT or hItem.nSub ~= EQUIPMENT_SUB.HORSE) then
            TipsHelper.ShowImportantRedTip(g_tStrings.STR_ERROR_HORSE_STABLE_IONLY_CUB_HORSE)
            return
        end

        dwTargetBox, dwTargetX = GetFirstFreeRoom()
        if dwTargetBox and dwTargetX then
            ItemData.OnExchangeItem(dwBox, dwX, dwTargetBox, dwTargetX)
            return true
        else
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_ERROR_HORSE_STABLE_IS_FULL)
        end
    end
end

local GetUsedSize = function()
    local player = g_pClientPlayer
    local nHaveCount = player.dwCubPackageSize
    local dwBox = INVENTORY_INDEX.CUB_PACKAGE
    local nUsed = 0

    for dwX = 0, nHaveCount - 1, 1 do
        local hItem = ItemData.GetPlayerItem(player, dwBox, dwX)
        if hItem then
            nUsed = nUsed + 1
        end
    end

    return nUsed
end

local fnExchangeClick = function(nCount, nBox, nIndex)
    OnExchangeBoxAndHandBoxItem(nBox, nIndex)
    Event.Dispatch(EventType.HideAllHoverTips)
end

function UIPanelHorseWareHouse:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        UIHelper.SetSwallowTouches(self.BtnBatchBg, true)
    end

    UIHelper.SetVisible(self.BtnBatchTakeOut, true)
    UIHelper.SetVisible(self.BtnPutIn, true)
    UIHelper.SetVisible(self.WidgetBaiZhanSearch, true)

    UIHelper.SetVisible(self.ScrollViewWareHouse, false)
    UIHelper.SetVisible(self.LayoutScrollList, true)

    local tbFunctions = {
        OnClick = fnExchangeClick,
        fnValid = function(nBox, nIndex)
            if g_pClientPlayer and nBox and nIndex then
                local item = ItemData.GetItemByPos(nBox, nIndex)
                return (item.nGenre == ITEM_GENRE.CUB and DOMESTICATE_CUB_SUB_TYPE.FOAL)
                        or (item.nGenre == ITEM_GENRE.EQUIPMENT and item.nSub == EQUIPMENT_SUB.HORSE)
            end
            return false
        end
    }
    self.bagScript = ItemData.GetBagScript() ---@type UIBagView
    self.bagScript:EnterWareHouseState(tbFunctions)

    self:InitScrollList()
    self:UpdateInfo()

    WarehouseDragData.SetExchangeFunc(ItemData.OnExchangeItem)
    WarehouseDragData.SetUIBoxType(nil)
end

function UIPanelHorseWareHouse:OnExit()
    self.bInit = false
    self:UnRegEvent()

    TipsHelper.DeleteAllHoverTips(true)
end

function UIPanelHorseWareHouse:BindUIEvent()
end

function UIPanelHorseWareHouse:RegEvent()
    local OnUpdate = function(nBox, nIndex)
        -- 更新格子
        local scriptCell = WarehouseData.GetCellScript(nBox, nIndex)
        if WarehouseData.HasFilterText() or not scriptCell then
            self:RefreshWareHouseCells()
        else
            scriptCell:UpdateInfo()
            local itemScript = scriptCell:GetItemScript()
            self:InitItemScript(itemScript, nBox, nIndex)
        end
        self:UpdateWareHouseSize()
    end

    Event.Reg(self, "CUB_ITEM_UPDATE", function(nBox, nIndex, bNewAdd)
        OnUpdate(nBox, nIndex)
    end)

    Event.Reg(self, "BUY_CUB_PACKAGE", function(_, arg1)
        local szChannel = "MSG_ANNOUNCE_RED"
        if arg1 == BUY_CUB_PACKAGE_RESULT_CODE.SUCCESS then
            self:UpdateInfo()
            szChannel = "MSG_SYS"
        end
        OutputMessage(szChannel, g_tStrings.tBuyCubPackageRespond[arg1])
        --OnUpdate(nBox, nIndex)
    end)

    Event.Reg(self, "SYNC_CUB_PACKAGE_SIZE", function(_, arg1)

    end)

    Event.Reg(self, EventType.HideAllHoverTips, function(nBox, nIndex, bNewAdd)
        if WarehouseData.bBatchSelect and self.scriptItemTip then
            self.scriptItemTip:OnInit()
            return
        end

        if WarehouseData.dwItemID then
            UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroup, nil)
        end
    end)

    Event.Reg(self, EventType.OnWarehouseFilterTextUpdate, function()
        self:UpdateWareHouseInfo()
        UIHelper.ScrollToTop(self.ScrollViewWareHouse)
    end)
end

function UIPanelHorseWareHouse:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelHorseWareHouse:UpdateInfo()
    self:UpdateWareHouseInfo()
end

function UIPanelHorseWareHouse:InitScrollList()
    local fnGetCellList = function()
        local tCellList = {}
        local player = g_pClientPlayer

        local _, nTotalCount = GetCubPackageRoomRange()
        local nHaveCount = player.dwCubPackageSize
        local dwBox = INVENTORY_INDEX.CUB_PACKAGE
        local bShowEmpty = not WarehouseData.HasFilterText()

        for dwX = 0, nTotalCount - 1, 1 do
            if dwX <= nHaveCount - 1 then
                local hItem = ItemData.GetPlayerItem(player, dwBox, dwX)
                if bShowEmpty or (hItem and WarehouseData.CheckMatchFilter(hItem)) then
                    local tNew = { nBox = dwBox, nIndex = dwX, bHasItem = hItem ~= nil, dwItemID = hItem and hItem.dwID, bLocked = false }
                    table.insert(tCellList, tNew)
                end
            elseif bShowEmpty then
                local tNew = { nBox = dwBox, nIndex = dwX, bLocked = true }
                table.insert(tCellList, tNew)
            end
        end

        return tCellList
    end

    local fnCellInitFunc = function(targetNode, parentLayout, tbPos)
        WarehouseData.RemoveCell(targetNode)
        targetNode = nil

        if tbPos.bLocked then
            local scripts = UIHelper.AddPrefab(PREFAB_ID.WidgetWareHouseExpandCell, parentLayout)
            scripts:SetToggleGroup(self.ToggleGroup)
            UIHelper.BindUIEvent(scripts.BtnShopping, EventType.OnClick, function()
                self:BuyPackage()
            end)
        else
            local cellScript = UIHelper.GetBindScript(targetNode) or select(2, ItemData.GetBagCellPrefabPool():Allocate(parentLayout))
            if cellScript:GetItemScript() then
                cellScript:GetItemScript():OnPoolRecycled(true)
            end

            local dwBox, dwX = tbPos.nBox, tbPos.nIndex
            cellScript:OnEnter(dwBox, dwX)
            local itemScript = cellScript:GetItemScript()
            self:InitItemScript(itemScript, dwBox, dwX)
            WarehouseData.StoreCellScript(dwBox, dwX, cellScript)
            WarehouseDragData.Add(cellScript)
            return cellScript
        end
    end

    WarehouseData.SetItemTipCallback(OnExchangeBoxAndHandBoxItem)
    WarehouseData.SetBatchMaxSizeFunc(GetUsedSize)

    WarehouseData.SetCellInitFunc(fnCellInitFunc)
    WarehouseData.SetGetCellListFunc(fnGetCellList)
end

-------------------------WareHouse------------------------------------

function UIPanelHorseWareHouse:UpdateWareHouseSize()
    local nTotalCount = g_pClientPlayer.dwCubPackageSize
    local nHaveCount = GetUsedSize()

    UIHelper.SetString(self.LabelWareHouseSize, string.format("(%d/%d)", nHaveCount, nTotalCount))
    UIHelper.SetString(self.LabelTitleSize, string.format("(%d/%d)", nHaveCount, nTotalCount))
    UIHelper.LayoutDoLayout(self.LayoutTitle)
end

function UIPanelHorseWareHouse:UpdateWareHouseInfo()
    self:UpdateWareHouseSize()
    self:RefreshWareHouseCells(SCROLL_LIST_UPDATE_TYPE.RESET)
end

function UIPanelHorseWareHouse:RefreshWareHouseCells(nUpdateType)
    WarehouseData.ClearCellScript()
    WarehouseDragData.Clear()

    WarehouseData.RefreshDataOnly(false)
    WarehouseData.RefreshScrollList(nUpdateType)
    UIHelper.SetVisible(self.WidgetEmpty, WarehouseData.IsScrollListEmpty())
end

function UIPanelHorseWareHouse:BuyPackage()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local _, nTotalCount = GetCubPackageRoomRange()
    local nHaveCount = hPlayer.dwCubPackageSize
    if nHaveCount >= nTotalCount then
        return
    end

    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.SHOP) then
        return
    end
    
    local nMoney = GetCubPackageRoomPrices(nHaveCount)
    local tMsg = nil
    if MoneyOptCmp(nMoney, hPlayer.GetMoney()) > 0 then
        local szMessage = GetFormatText(g_tStrings.MSG_BUY_CUB_PACKAGE_NEED_MONEY, 105) ..
                UIHelper.GetMoneyTipText(nMoney, false) ..
                GetFormatText(g_tStrings.MSG_NOT_ENOUGH_MONEY, 105)
        local script = UIHelper.ShowConfirm(szMessage, nil, nil, true)
        script:HideButton("Cancel")
    else
        local fnConfirm = function()
            GetClientPlayer().BuyCubPackage(1)
        end
        local szMessage = GetFormatText(g_tStrings.MSG_BUY_CUB_PACKAGE_NEED_MONEY, 105) ..
                UIHelper.GetMoneyTipText(nMoney, false) ..
                GetFormatText(g_tStrings.MSG_SURE_BUY_CUB_PACKAGE, 105)
        UIHelper.ShowConfirm(szMessage, fnConfirm, nil, true)
    end
end

function UIPanelHorseWareHouse:InitItemScript(itemScript, dwBox, dwX)
    if itemScript then
        itemScript:SetToggleGroup(self.ToggleGroup)
        itemScript:SetSelectMode(WarehouseData.bBatchSelect, true)
        itemScript:SetHandleChooseEvent(true)
        itemScript:SetSelectChangeCallback(function(dwItemID, bSelected)
            WarehouseData.tbPos.nBox, WarehouseData.tbPos.nIndex = dwBox, dwX
            WarehouseData.OnItemSelectChange(dwItemID, bSelected)
        end)
    end
end

return UIPanelHorseWareHouse