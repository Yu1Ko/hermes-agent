-- ---------------------------------------------------------------------------------
-- Author: JiaYuRan
-- Name: UIPanelWareHouse
-- ---------------------------------------------------------------------------------

local UIPanelFactionWarehouse = class("UIPanelFactionWarehouse")

local m_szMark = "bank_warehouse"
local BOX_COUNT = 98

local function CanAddItemToGuildBank(dwBox, dwX, nPage)
    local item = GetClientPlayer().GetItem(dwBox, dwX)
    if not item then
        return
    end

    if item.nGenre == ITEM_GENRE.TASK_ITEM then
        return false
    end

    local itemInfo = GetItemInfo(item.dwTabType, item.dwIndex)
    if item.bBind and (not itemInfo.IsTongBind()) then
        return false
    end

    if itemInfo.nExistType ~= ITEM_EXIST_TYPE.PERMANENT then
        return false
    end

    if nPage == TONG_REPERTORY_SYSTEM_PAGE and (not itemInfo.IsTongBind()) then
        return false
    end

    if not GetTongClient().FindRepertoryEmptyGrid(nPage) then
        return false
    end

    return true
end

local KTONG_REPERTORY_INVALID_PAGE_POS = 255

local tNameOfFactionSub = {
    "仓库一",
    "仓库二",
    "仓库三",
    "仓库四",
    "仓库五",
    "仓库六",
    "仓库七",
    "仓库八",
    "天工坊",
}

local function AddItemToGuildBank(dwBox, dwX, nPage, nSplitAmount)
    local item = GetClientPlayer().GetItem(dwBox, dwX)
    if not item then
        return
    end

    if item.nGenre == ITEM_GENRE.TASK_ITEM then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.GUILD_BANK_CAN_NOT_PUT_TASK_ITME)
        return false
    end

    local itemInfo = GetItemInfo(item.dwTabType, item.dwIndex)
    if item.bBind and (not itemInfo.IsTongBind()) then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.GUILD_BANK_CAN_NOT_PUT_BIND_ITME)
        return false
    end

    if itemInfo.nExistType ~= ITEM_EXIST_TYPE.PERMANENT then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.ERROR_GUILD_NOT_TIME_LIMIT)
        return false
    end
    if not GetTongClient().FindRepertoryEmptyGrid(nPage) then

        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.GUILD_BANK_ERROR_PAGE_FULL)
        return false
    end

    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TONG_REPERTORY, "帮会仓库") then
        return
    end

    GetTongClient().PutItemToRepertory(dwBox, dwX, nPage, KTONG_REPERTORY_INVALID_PAGE_POS, nSplitAmount)
end

local function PutItemToBag(nPage, nIndex, nSplitAmount)
    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TONG_REPERTORY) then
        return
    end
    local TongClient = GetTongClient()
    local nReselt = TongClient.TakeRepertoryItem(nPage, nIndex, INVENTORY_INDEX.INVALID, 0, nSplitAmount)
    --print(nReselt, ADD_ITEM_RESULT_CODE.FAILED)
    if nReselt >= ADD_ITEM_RESULT_CODE.FAILED then
        local szMsg = g_tStrings.tAdd_Item_Msg[nReselt]

        if szMsg and szMsg ~= "" then
            OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
        end
    end
end

local function ExchangeItemBetweenBankAndBag(nBox, nIndex, nPage, nAmount)
    if PropsSort.IsBagInSort() or PropsSort.IsBankInSort() then
        TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
        return
    end

    nAmount = nAmount or 0
    local bBagItem = table.contain_value(ItemData.BoxSet.Bag, nBox)
    if bBagItem then
        AddItemToGuildBank(nBox, nIndex, nPage, nAmount)
    else
        local nPage, nIndex = GetGuildBankPagePos(nBox, nIndex)
        PutItemToBag(nPage, nIndex, nAmount)
    end
end

local function GetGuildBankBagPos(nPage, nIndex)
    return INVENTORY_GUILD_BANK, nPage * INVENTORY_GUILD_PAGE_SIZE + nIndex
end

function UIPanelFactionWarehouse:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        UIHelper.SetSwallowTouches(self.BtnBatchBg, true)
    end

    UIHelper.SetVisible(self.WidgetDiscardAnchor, false)
    UIHelper.SetVisible(self.BtnBatchTakeOut, true)
    UIHelper.SetVisible(self.BtnPutIn, true)
    UIHelper.SetVisible(self.BtnNeaten, true)
    UIHelper.SetVisible(self.BtnRefresh, true)
    UIHelper.SetVisible(self.LayoutFunction, true)
    UIHelper.SetVisible(self.WidgetChildTab, true)
    UIHelper.SetVisible(self.WidgetBaiZhanSearch, true)

    UIHelper.SetVisible(self.ScrollViewWareHouse, false)
    UIHelper.SetVisible(self.LayoutScrollList, true)

    UIHelper.SetVisible(self.LabelTitleSize, false) -- 一开始先隐藏

    UIHelper.RemoveAllChildren(self.ScrollViewTab)

    local bFirst = true
    for i = 1, 9, 1 do
        local bShow = IsTongRepertoryPageEnable(i - 1)
        if bShow then
            local fnSubSelected = function(toggle, bState)
                if bState == true then
                    local nPage = i - 1
                    self:RefreshPage(nPage)
                end
            end
            local subData = { szTitle = tNameOfFactionSub[i], onSelectChangeFunc = fnSubSelected }
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetWarehouseChild, self.ScrollViewTab, subData)

            script:SetSelected(bFirst)
            bFirst = false
        end
    end

    self.fnGetBatchMaxSize = function()
        local nCount = 0
        for i = 0, BOX_COUNT - 1 do
            local dwBox, dwX = GetGuildBankBagPos(self.nPage, i)
            local hItem = ItemData.GetPlayerItem(g_pClientPlayer, dwBox, dwX)
            local bShowItem = hItem and WarehouseData.CheckMatchFilter(hItem)
            if bShowItem then
                nCount = nCount + 1
            end
        end
        return nCount
    end

    UIHelper.LayoutDoLayout(self.LayoutLeft)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTab)

    self:InitScrollList()

    WarehouseDragData.SetExchangeFunc(ItemData.OnExchangeItem)
    WarehouseDragData.SetUIBoxType(UI_BOX_TYPE.BANK)
end

function UIPanelFactionWarehouse:OnExit()
    self.bInit = false
    self:UnRegEvent()

    TipsHelper.DeleteAllHoverTips(true)
end

function UIPanelFactionWarehouse:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnRefresh, EventType.OnClick, function()
        self:RefreshPage(self.nPage)
    end)

    UIHelper.BindUIEvent(self.BtnNeaten, EventType.OnClick, function()
        self:BigBankSort()
    end)

    UIHelper.BindUIEvent(self.BtnBagUpgrade, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelWarehouseUp)
    end)
end

function UIPanelFactionWarehouse:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function(nBox, nIndex, bNewAdd)
        if WarehouseData.dwItemID then
            UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroup, nil)
        end
    end)

    Event.Reg(self, "TONG_EVENT_NOTIFY", function(arg0, arg1, bNewAdd)
        local guild = GetTongClient()
        if arg0 == TONG_EVENT_CODE.REPERTORY_GRID_FILLED_ERROR then
            guild.ApplyRepertoryPage(arg1)
        elseif arg0 == TONG_EVENT_CODE.TONG_SERVER_OFFLINE then
            UIMgr.Close(self)
        elseif arg0 == TONG_EVENT_CODE.MODIFY_BASE_OPERATION_MASK_SUCCESS or
                arg0 == TONG_EVENT_CODE.MODIFY_ADVANCE_OPERATION_MASK_SUCCESS then
            guild.ApplyTongInfo()
        elseif arg0 == TONG_EVENT_CODE.STACK_ITEM_TO_REPERTORY_FAIL_ERROR or
                arg0 == TONG_EVENT_CODE.ITEM_NOT_IN_REPERTORY_ERROR or
                arg0 == TONG_EVENT_CODE.REPERTORY_TARGET_ITEM_CHANGE_ERROR or
                arg0 == TONG_EVENT_CODE.REPERTORY_PAGE_FULL_ERROR or
                arg0 == TONG_EVENT_CODE.STACK_ITEM_IN_REPERTORY_FAILERROR then
            if WarehouseData.bBatchSelect then
                self:StopBatch()
            end
            print("--------------------------------------------------")
            guild.ApplyRepertoryPage(arg1)
        else
            if not WarehouseData.bBatchSelect then
                guild.ApplyRepertoryPage(arg1)
            end
        end
    end)

    Event.Reg(self, "UPDATE_TONG_INFO_FINISH", function()
        self:UpdateInfo()
    end)

    Event.Reg(self, "UPDATE_TONG_REPERTORY_PAGE", function(arg0, arg1, bNewAdd)
        local nPage = arg0
        if nPage == self.nPage then
            --LOG.INFO("UPDATE_TONG_REPERTORY_PAGE")
            self:UpdateWareHouseInfo(SCROLL_LIST_UPDATE_TYPE.RELOAD)
        end
    end)

    Event.Reg(self, EventType.OnWarehouseFilterTextUpdate, function()
        self:UpdateWareHouseInfo(SCROLL_LIST_UPDATE_TYPE.RESET)
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewWareHouse)
    end)
end

function UIPanelFactionWarehouse:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIPanelFactionWarehouse:InitScrollList()
    local fnGetCellList = function()
        local tCellList = {}
        local player = g_pClientPlayer
        if player then
            local player = g_pClientPlayer
            local bShowEmpty = not WarehouseData.HasFilterText()

            for i = 0, BOX_COUNT - 1 do
                local dwBox, dwX = GetGuildBankBagPos(self.nPage, i)
                local hItem = ItemData.GetPlayerItem(player, dwBox, dwX)
                local bShowItem = hItem and WarehouseData.CheckMatchFilter(hItem)
                if bShowEmpty or bShowItem then
                    local tNew = { nBox = dwBox, nIndex = dwX, bHasItem = hItem ~= nil, dwItemID = hItem and hItem.dwID }
                    table.insert(tCellList, tNew)
                end
            end
        end
        return tCellList
    end

    local fnCellInitFunc = function(targetNode, parentLayout, tbPos)
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

    local fnTakeOut = function(dwBox, dwX, nAmount)
        ExchangeItemBetweenBankAndBag(dwBox, dwX, self.nPage, nAmount)
    end

    WarehouseData.SetItemTipCallback(fnTakeOut)
    WarehouseData.SetBatchMaxSizeFunc( self.fnGetBatchMaxSize)

    WarehouseData.SetCellInitFunc(fnCellInitFunc)
    WarehouseData.SetGetCellListFunc(fnGetCellList)
end

function UIPanelFactionWarehouse:RefreshPage(nPage)
    self.nPage = nPage or 0
    self.bLoadPage = true
    local tbFunctions = {
        szName = "存入",
        OnClick = function(nCount, nBox, nIndex)
            ExchangeItemBetweenBankAndBag(nBox, nIndex, self.nPage, nCount)
            Event.Dispatch(EventType.HideAllHoverTips)
        end,
        fnValid = function(nBox, nIndex)
            if g_pClientPlayer and nBox and nIndex then
                return CanAddItemToGuildBank(nBox, nIndex, self.nPage)
            end
            return false
        end
    }
    self.bagScript = ItemData.GetBagScript() ---@type UIBagViewNew
    self.bagScript:EnterWareHouseState(tbFunctions)
    GetTongClient().ApplyRepertoryPage(self.nPage)

    Event.Dispatch(EventType.OnWarehouseCancelTouch)
end

-------------------------WareHouse------------------------------------

function UIPanelFactionWarehouse:UpdateWareHouseSize()
    local nUsed =  self.fnGetBatchMaxSize()
    UIHelper.SetString(self.LabelWareHouseSize, string.format("(%d/%d)", nUsed, BOX_COUNT))
    UIHelper.SetString(self.LabelTitleSize, string.format(" (%d/%d)", nUsed, BOX_COUNT))
    UIHelper.SetVisible(self.LabelTitleSize, true) -- 有数据之后再显示仓库大小
    UIHelper.LayoutDoLayout(self.LayoutTitle)
end

function UIPanelFactionWarehouse:UpdateWareHouseInfo(nUpdateType)
    self:RefreshWareHouseCells(nUpdateType)
    self:UpdateWareHouseSize()
    self:UpdateBankPermission()
end

function UIPanelFactionWarehouse:RefreshWareHouseCells(nUpdateType)
    WarehouseData.ClearCellScript()
    WarehouseDragData.Clear()

    if self.bLoadPage then
        nUpdateType = SCROLL_LIST_UPDATE_TYPE.RESET
        self.bLoadPage = false
    end

    WarehouseData.RefreshDataOnly(false)
    WarehouseData.RefreshScrollList(nUpdateType)
    UIHelper.SetVisible(self.WidgetEmpty, WarehouseData.IsScrollListEmpty())
end

function UIPanelFactionWarehouse:InitItemScript(itemScript, dwBox, dwX)
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

function UIPanelFactionWarehouse:UpdateBankPermission()
    local player = GetClientPlayer()
    local guild = GetTongClient()
    --local info = guild.GetMemberInfo(player.dwID)
    local dwGroupIndex = guild.nGroup

    local store = {}
    store.bAccess = true
    store.bAdvance = false
    store.nPermissionIndex = 5 + (self.nPage * 2)
    self.bCanStore = guild.CheckBaseOperationGroup(dwGroupIndex, store.nPermissionIndex)
    --local enable = guild.CanBaseGrant(info.nGroupID, dwGroupIndex, store.nPermissionIndex)

    local take = {}
    take.bAccess = true
    take.bAdvance = false
    take.nPermissionIndex = 6 + (self.nPage * 2)
    self.bCanTake = guild.CheckBaseOperationGroup(dwGroupIndex, take.nPermissionIndex)
    --local enable = guild.CanBaseGrant(info.nGroupID, dwGroupIndex, take.nPermissionIndex)

    UIHelper.SetVisible(self.ImgState_In_Yes, self.bCanStore)
    UIHelper.SetVisible(self.ImgState_Out_Yes, self.bCanTake)
    UIHelper.SetVisible(self.ImgState_In_No, not self.bCanStore)
    UIHelper.SetVisible(self.ImgState_Out_No, not self.bCanTake)

    UIHelper.SetVisible(self.BtnNeaten, self.bCanStore and self.bCanTake)
    UIHelper.SetVisible(self.BtnBatchTakeOut, self.bCanTake)
    UIHelper.SetVisible(self.BtnPutIn, self.bCanStore)
    UIHelper.LayoutDoLayout(self.LayoutBottomBtn)
end

function UIPanelFactionWarehouse:BigBankSort()
    local tList = {}
    local tAllBoxList = {}

    local bLocked = BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.BANK)
    if bLocked then
        return
    end

    if PropsSort.IsBankInSort() then
        return
    end

    local script = UIHelper.ShowConfirm("是否确定整理帮会仓库？", function()
        tList, tAllBoxList = self:UpdateStack()
        PropsSort.BeginSort(tList, tAllBoxList, m_szMark)
    end, nil)
end

function UIPanelFactionWarehouse:UpdateStack()
    local player = g_pClientPlayer
    local tList = {}
    local tAllBoxList = {}

    local nIndex = 0
    for i = 0, BOX_COUNT - 1 do
        local dwBox, dwX = GetGuildBankBagPos(self.nPage, i)
        local hItem = ItemData.GetPlayerItem(player, dwBox, dwX)
        if hItem ~= nil then
            table.insert(tList, { dwBox, dwX })
        end
        table.insert(tAllBoxList, { dwBox, dwX })
        nIndex = nIndex + 1
    end

    return tList, tAllBoxList
end

return UIPanelFactionWarehouse