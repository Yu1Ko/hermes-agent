-- ---------------------------------------------------------------------------------
-- Author: JiaYuRan
-- Name: UIPanelWareHouse
-- ---------------------------------------------------------------------------------

local UIPanelAccountWareHouse = class("UIPanelAccountWareHouse")

local dwCurrentSource = ACCOUNT_SHARED_PACKAGE_SOURCE.CURRENT
local function ExchangeItemBetweenBagAndAccountWareHouse(dwBox, dwIndex, nAmount, dwSource)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    dwSource = dwSource or ACCOUNT_SHARED_PACKAGE_SOURCE.CURRENT
    local bAccountWareHouseItem = dwBox == ACCOUNT_SHARED_PACKAGE_BOX.PACKAGE
    if bAccountWareHouseItem then
        return ItemData.TakeItemFromAccountSharedPackage(dwSource, dwBox, dwIndex, nil, nil, nAmount)
    else
        if dwSource == ACCOUNT_SHARED_PACKAGE_SOURCE.LEFT then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.ASP_ISTEMPORARY_SHAREPACKGE)  --临时仓库不允许放入
            return
        end
        return ItemData.PutItemToAccountSharedPackage(dwBox, dwIndex, nil, nil, nAmount)
    end
end

local function ExchangeItemInAccountSharedPackage(dwSrcASPBox, dwSrcASPPos, dwDstASPBox, dwDstASPPos, dwSource)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    if not hPlayer.bAccountShared then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.ASP_NOT_BIND)
        return  --权限检测
    end

    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.SHOP) then
        return
    end
    local nRetCode = hPlayer.ExchangeItemInAccountSharedPackage(nil, dwSrcASPBox, dwSrcASPPos, dwDstASPBox, dwDstASPPos, 0)
    -- if nRetCode == ASP_RESULT_CODE.SUCCEED then
    -- 	OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.ASP_EXCHANGE_SUCCEED)
    if nRetCode == ASP_RESULT_CODE.FAILED then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.ASP_EXCHANGE_FAILED)
    else
        ItemData.ShowSharePackageRecodeTip(nRetCode)
    end
end

local function GetUseShareBagSize(dwSource)
    local nRetSize = 0
    local player = g_pClientPlayer
    if not player then
        return
    end
    local nHaveCount = player.GetAccountSharedPackageBoxSize(dwSource, ACCOUNT_SHARED_PACKAGE_BOX.PACKAGE)
    for i = 0, nHaveCount - 1 do
        if player.GetItemInAccountSharedPackage(dwSource, ACCOUNT_SHARED_PACKAGE_BOX.PACKAGE, i) then
            nRetSize = nRetSize + 1
        end
    end
    return nRetSize, nHaveCount
end

local GetBatchMaxSize = function()
    local nUsed, nTotal = GetUseShareBagSize(ACCOUNT_SHARED_PACKAGE_SOURCE.CURRENT)
    return nUsed
end

local fnExchangeClick = function(nCount, nBox, nIndex)
    ExchangeItemBetweenBagAndAccountWareHouse(nBox, nIndex, nCount)
    Event.Dispatch(EventType.HideAllHoverTips)
end

function UIPanelAccountWareHouse:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        UIHelper.SetSwallowTouches(self.BtnBatchBg, true)
    end

    UIHelper.SetVisible(self.BtnDescription, true)
    UIHelper.SetVisible(self.BtnBatchTakeOut, true)
    UIHelper.SetVisible(self.BtnPutIn, true)
    UIHelper.SetVisible(self.WidgetRoleList, true)
    UIHelper.SetVisible(self.WidgetBaiZhanSearch, true)

    UIHelper.SetVisible(self.ScrollViewWareHouse, false)
    UIHelper.SetVisible(self.LayoutScrollList, true)

    local tbFunctions = {
        OnClick = fnExchangeClick,
        fnValid = function(nBox, nIndex)
            if g_pClientPlayer and nBox and nIndex then
                return g_pClientPlayer.CanPutItemToAccountSharedPackage(1, nBox, nIndex) == ASP_RESULT_CODE.SUCCEED
            end
            return false
        end
    }
    self.bagScript = ItemData.GetBagScript() ---@type UIBagView
    self.bagScript:EnterWareHouseState(tbFunctions)

    WarehouseDragData.SetExchangeFunc(ExchangeItemInAccountSharedPackage)
    WarehouseDragData.SetUIBoxType(UI_BOX_TYPE.SHAREPACKAGE)

    self:InitScrollList()
    self:UpdateInfo()
end

function UIPanelAccountWareHouse:OnExit()
    self.bInit = false
    self:UnRegEvent()

    TipsHelper.DeleteAllHoverTips(true)
    UIHelper.SetVisible(self.WidgetTemporaryWarehouse, false)
end

function UIPanelAccountWareHouse:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnDescription, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelHelpPop, 1)
    end)

    UIHelper.BindUIEvent(self.BtnBagUpgrade, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelWarehouseUp)
    end)
end

function UIPanelAccountWareHouse:RegEvent()
    Event.Reg(self, "ON_REMOVE_ROLE_FROM_ACCOUNT_SHARED_NOTIFY", function()
        self:RefreshBindRollCells()
        self:RefreshButtons()
    end)

    local OnUpdate = function(nBox, nIndex, szEvent)
        self:UpdateTemporaryWareHouse()

        -- 更新格子
        local scriptCell = WarehouseData.GetCellScript(nBox, nIndex)
        if WarehouseData.HasFilterText() or not scriptCell then
            self:RefreshWareHouseCells(SCROLL_LIST_UPDATE_TYPE.RELOAD)
        else
            scriptCell:UpdateInfo()
            local itemScript = scriptCell:GetItemScript()
            self:InitItemScript(itemScript, nBox, nIndex)
        end

        self:UpdateWareHouseSize()
    end

    Event.Reg(self, "ON_ACCOUNT_SHARED_PACKAGE_UPDATE", function(nBox, nIndex, bNewAdd)
        OnUpdate(nBox, nIndex, "BANK_ITEM_UPDATE")
    end)

    Event.Reg(self, "ON_SYNC_ACCOUNT_SHARED_PACKAGE_BOX_SIZE", function()
        self:RefreshWareHouseCells(SCROLL_LIST_UPDATE_TYPE.RELOAD)
        self:UpdateWareHouseSize()
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function(nBox, nIndex, bNewAdd)
        if WarehouseData.dwItemID then
            UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroup, nil)
        end
    end)

    Event.Reg(self, "ON_ADD_SELF_TO_ACCOUNT_SHARED_NOTIFY", function()
        self:RefreshBindRollCells()
        self:RefreshButtons()
    end)

    Event.Reg(self, "ON_REMOVE_ROLE_FROM_ACCOUNT_SHARED_NOTIFY", function()
        self:RefreshBindRollCells()
        self:RefreshButtons()
    end)

    Event.Reg(self, EventType.OnWarehouseFilterTextUpdate, function()
        self:UpdateWareHouseInfo()
        UIHelper.ScrollToTop(self.ScrollViewWareHouse)
    end)

    Event.Reg(self, EventType.OnWarehouseDragEnd, function()
        WarehouseData.dwItemID = 1 -- 拖动结束时标记为选中状态，方便后续相应HideAllHoverTips事件
    end)

end

function UIPanelAccountWareHouse:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelAccountWareHouse:UpdateInfo()
    self:UpdateWareHouseInfo()
    self:RefreshBindRollCells()
    self:RefreshButtons()
end

-------------------------WareHouse------------------------------------

function UIPanelAccountWareHouse:InitScrollList()
    local fnGetCellList = function()
        local tCellList = {}
        local player = g_pClientPlayer
        local bShowEmpty = not WarehouseData.HasFilterText()
        if player then
            local nHaveCount = player.GetAccountSharedPackageBoxSize(dwCurrentSource, ACCOUNT_SHARED_PACKAGE_BOX.PACKAGE) --获取当前大小
            local nUnlockBoxPrice, nMaxBagCount = GDAPI_GetShareBagExtandGold(nHaveCount)
            local dwBox = ACCOUNT_SHARED_PACKAGE_BOX.PACKAGE --索引值, 0
            for dwX = 0, nMaxBagCount - 1, 1 do
                if dwX <= nHaveCount - 1 then
                    local hItem = ItemData.GetPlayerItem(player, dwBox, dwX, UI_BOX_TYPE.SHAREPACKAGE, dwCurrentSource)
                    if bShowEmpty or (hItem and WarehouseData.CheckMatchFilter(hItem)) then
                        local tNew = { nBox = dwBox, nIndex = dwX, bHasItem = hItem ~= nil, dwItemID = hItem and hItem.dwID, bLocked = false }
                        table.insert(tCellList, tNew)
                    end
                elseif bShowEmpty then
                    local tNew = { nBox = dwBox, nIndex = dwX, bLocked = true }
                    table.insert(tCellList, tNew)
                end
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
            cellScript:OnEnter(dwBox, dwX, true)
            local itemScript = cellScript:GetItemScript()
            self:InitItemScript(itemScript, dwBox, dwX)
            WarehouseData.StoreCellScript(dwBox, dwX, cellScript)
            WarehouseDragData.Add(cellScript)
            return cellScript
        end
    end

    WarehouseData.SetItemTipCallback(ExchangeItemBetweenBagAndAccountWareHouse)
    WarehouseData.SetBatchMaxSizeFunc(GetBatchMaxSize)

    WarehouseData.SetCellInitFunc(fnCellInitFunc)
    WarehouseData.SetGetCellListFunc(fnGetCellList)
end

function UIPanelAccountWareHouse:UpdateWareHouseSize()
    local player = g_pClientPlayer
    local dwUseSize = GetUseShareBagSize(dwSource)
    local dwSize = player.GetAccountSharedPackageBoxSize(dwCurrentSource, ACCOUNT_SHARED_PACKAGE_BOX.PACKAGE)

    UIHelper.SetString(self.LabelWareHouseSize, string.format("(%d/%d)", dwUseSize, dwSize))
    UIHelper.SetString(self.LabelTitleSize, string.format("(%d/%d)", dwUseSize, dwSize))
    UIHelper.LayoutDoLayout(self.LayoutTitle)
end

function UIPanelAccountWareHouse:UpdateWareHouseInfo()
    self:UpdateWareHouseSize()
    self:RefreshWareHouseCells(SCROLL_LIST_UPDATE_TYPE.RESET)
end

function UIPanelAccountWareHouse:RefreshWareHouseCells(nUpdateType)
    WarehouseData.ClearCellScript()
    WarehouseDragData.Clear()

    WarehouseData.RefreshDataOnly(false)
    WarehouseData.RefreshScrollList(nUpdateType)

    UIHelper.SetVisible(self.WidgetEmpty, WarehouseData.IsScrollListEmpty())
    self:UpdateTemporaryWareHouse()
end

function UIPanelAccountWareHouse:InitItemScript(itemScript, dwBox, dwX)
    if itemScript then
        itemScript:SetToggleGroup(self.ToggleGroup)
        itemScript:SetSelectMode(WarehouseData.bBatchSelect, true)
        itemScript:SetHandleChooseEvent(true)
        itemScript:SetSelectChangeCallback(function(dwItemID, bSelected)
            WarehouseData.tbPos.nBox, WarehouseData.tbPos.nIndex = dwBox, dwX
            WarehouseData.OnItemSelectChange(dwItemID, bSelected, ACCOUNT_SHARED_PACKAGE_SOURCE.CURRENT)
        end)
    end
end

function UIPanelAccountWareHouse:RefreshButtons()
    local bPlayerAccountShared = g_pClientPlayer.bAccountShared
    UIHelper.SetVisible(self.BtnBatchTakeOut, bPlayerAccountShared)
    UIHelper.SetVisible(self.BtnPutIn, bPlayerAccountShared)
    UIHelper.LayoutDoLayout(self.LayoutBottomBtn)
end

function UIPanelAccountWareHouse:RefreshBindRollCells()
    UIHelper.RemoveAllChildren(self.LayoutRoleList)

    local tBindPlayer = g_pClientPlayer.GetAccountSharedRoleList()
    for index = 1, 3, 1 do
        local cellScript = UIHelper.AddPrefab(PREFAB_ID.WidgetAccountsBindingRole, self.LayoutRoleList, tBindPlayer[index])
    end
    UIHelper.LayoutDoLayout(self.LayoutBindingRole)
end

function UIPanelAccountWareHouse:IsAvailableToStore(nBox, nIndex)
    local nResponse = g_pClientPlayer.CanPutItemToAccountSharedPackage(dwNpcID, nBox, nIndex)
    local bState = nResponse == ASP_RESULT_CODE.SUCCEED or nResponse == ASP_RESULT_CODE.NOT_ENOUGH_FREE_ROOM
    return bState
end

function UIPanelAccountWareHouse:UpdateTemporaryWareHouse()
    UIHelper.RemoveAllChildren(self.LayoutTemporaryCell)
    local dwSource = ACCOUNT_SHARED_PACKAGE_SOURCE.LEFT
    local player = g_pClientPlayer
    self.bTemporaryHasCell = false
    local nHaveCount = player.GetAccountSharedPackageBoxSize(dwSource, ACCOUNT_SHARED_PACKAGE_BOX.PACKAGE)
    for i = 0, nHaveCount - 1 do
        local dwBox, dwX = ACCOUNT_SHARED_PACKAGE_BOX.PACKAGE, i
        local hItem = player.GetItemInAccountSharedPackage(dwSource, dwBox, dwX)
        if hItem and WarehouseData.CheckMatchFilter(hItem) then
            local cellScript = UIHelper.AddPrefab(PREFAB_ID.WidgetBagBottom, self.LayoutTemporaryCell)
            cellScript:OnEnter(dwBox, dwX, true, dwSource)
            local itemScript = cellScript:GetItemScript()
            itemScript:SetToggleGroup(self.ToggleGroup)
            itemScript:SetSelectMode(false, true)
            --itemScript:SetHandleChooseEvent(true)
            itemScript:SetSelectChangeCallback(function(dwItemID, bSelected)
                WarehouseData.tbPos.nBox, WarehouseData.tbPos.nIndex = dwBox, dwX
                WarehouseData.OnItemSelectChange(dwItemID, bSelected, ACCOUNT_SHARED_PACKAGE_SOURCE.LEFT)
            end)
            self.bTemporaryHasCell = true
        end
    end

    if self.bTemporaryHasCell then
        UIHelper.LayoutDoLayout(self.LayoutTemporaryCell)
    end
    UIHelper.SetVisible(self.WidgetTemporaryWarehouse, self.bTemporaryHasCell)
end

function UIPanelAccountWareHouse:BuyPackage()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local nHaveCount = hPlayer.GetAccountSharedPackageBoxSize(dwCurrentSource, ACCOUNT_SHARED_PACKAGE_BOX.PACKAGE) --获取当前大小
    local nUnlockBoxPrice, nMaxBagCount = GDAPI_GetShareBagExtandGold(nHaveCount)
    
    if nHaveCount >= nMaxBagCount then
        return
    end

    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.SHOP) then
        return
    end
    
    if MoneyOptCmp(nUnlockBoxPrice, hPlayer.GetMoney()) > 0 then
        local szMessage = GetFormatText(g_tStrings.SG_BUY_ACCOUNT_PACKAGE_NEED_MONEY, 105) ..
                UIHelper.GetMoneyTipText(nUnlockBoxPrice, true) ..
                GetFormatText(g_tStrings.MSG_NOT_ENOUGH_MONEY, 105)
        local script = UIHelper.ShowConfirm(szMessage, nil, nil, true)
        script:HideButton("Cancel")
    else
        local fnConfirm = function()
            RemoteCallToServer("On_SystemBox_ShareExtand")
        end
        local szMessage = GetFormatText(g_tStrings.SG_BUY_ACCOUNT_PACKAGE_NEED_MONEY, 105) ..
                UIHelper.GetMoneyTipText(nUnlockBoxPrice, true) ..
                GetFormatText(g_tStrings.MSG_SURE_BUY_ACCOUNT_PACKAGE, 105)
        UIHelper.ShowConfirm(szMessage, fnConfirm, nil, true)
    end
end

return UIPanelAccountWareHouse