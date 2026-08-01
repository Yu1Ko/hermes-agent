-- ---------------------------------------------------------------------------------
-- Author: JiaYuRan
-- Name: UIPanelWareHouse
-- ---------------------------------------------------------------------------------

local m_szMark = "bank"
local nCount = 6
local nItemCountOfEachRow = 5
local nTimeLimitedIndex = 12

local function BankIndexToInventoryIndex(nIndex)
    return INVENTORY_INDEX.BANK + nIndex - 1
end

local function Stack()
    local player = GetClientPlayer()
    if not player then
        return
    end
    local function JudgeStack(ntype)
        local _tItemList = {}
        for i = 1, nCount do
            local dwBox = BankIndexToInventoryIndex(i)
            local dwSize = player.GetBoxSize(dwBox)
            local item
            for dwX = 0, dwSize - 1 do
                item = player.GetItem(dwBox, dwX)
                if item and item.bCanStack and item.nStackNum < item.nMaxStackNum then
                    local key
                    if ntype then
                        key = item.dwTabType .. "|" .. item.dwIndex
                    else
                        key = item.dwTabType .. "|" .. item.dwIndex .. "|" .. item.GetLeftExistTime()
                    end
                    if not _tItemList[key] then
                        _tItemList[key] = { dwBox = dwBox, dwX = dwX, nLeftStackNum = item.nMaxStackNum - item.nStackNum }
                    else
                        if item.nStackNum < _tItemList[key].nLeftStackNum then
                            player.ExchangeItem(dwBox, dwX, _tItemList[key].dwBox, _tItemList[key].dwX, item.nStackNum)
                            _tItemList[key].nLeftStackNum = _tItemList[key].nLeftStackNum - item.nStackNum
                        elseif item.nStackNum == _tItemList[key].nLeftStackNum then
                            player.ExchangeItem(dwBox, dwX, _tItemList[key].dwBox, _tItemList[key].dwX, _tItemList[key].nLeftStackNum)
                            _tItemList[key] = nil
                        elseif item.nStackNum > _tItemList[key].nLeftStackNum then
                            player.ExchangeItem(dwBox, dwX, _tItemList[key].dwBox, _tItemList[key].dwX, _tItemList[key].nLeftStackNum)
                            _tItemList[key].dwBox = dwBox
                            _tItemList[key].dwX = dwX
                            _tItemList[key].nLeftStackNum = item.nMaxStackNum - item.nStackNum + _tItemList[key].nLeftStackNum
                        end
                    end
                end
            end
        end
    end
    local bJudge = false
    local _tJudgeList = {}
    for i = 1, nCount do
        local dwBox = BankIndexToInventoryIndex(i)
        local dwSize = player.GetBoxSize(dwBox)
        local item
        for dwX = 0, dwSize - 1 do
            item = player.GetItem(dwBox, dwX)
            if item and item.bCanStack and item.nStackNum < item.nMaxStackNum then
                local key = item.dwTabType .. "|" .. item.dwIndex
                if not _tJudgeList[key] then
                    _tJudgeList[key] = item.GetLeftExistTime()
                elseif _tJudgeList[key] ~= item.GetLeftExistTime() then
                    bJudge = true
                    break
                end
            end
        end
        if bJudge then
            break
        end
    end
    if bJudge then
        UIHelper.ShowConfirm(g_tStrings.STR_STACK_BANK_JUDGE, function()
            JudgeStack(true)
        end, function()
            JudgeStack(false)
        end)
    else
        JudgeStack(false)
    end
end

local tbExpandItemSlot = { nil, EQUIPMENT_INVENTORY.BANK_PACKAGE1, EQUIPMENT_INVENTORY.BANK_PACKAGE2, EQUIPMENT_INVENTORY.BANK_PACKAGE3,
                           EQUIPMENT_INVENTORY.BANK_PACKAGE4, EQUIPMENT_INVENTORY.BANK_PACKAGE5 } --第一个位置是自带包裹

local function ExchangeItemBetweenBankAndBag(dwBox, dwX, nAmount)
    if PropsSort.IsBagInSort() or PropsSort.IsBankInSort() then
        TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
        return
    end

    local player = GetClientPlayer()
    if not player then
        return
    end
    local dwTargetBox, dwTargetX
    local dwBoxType = player.GetBoxType(dwBox);

    if dwBoxType == INVENTORY_TYPE.BANK then
        dwTargetBox, dwTargetX = player.GetStackRoomInPackage(dwBox, dwX, nAmount)
        if not (dwTargetBox and dwTargetX) then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_ERROR_PACKAGE_IS_FULL);
            return false
        end
    end

    if dwBoxType == INVENTORY_TYPE.PACKAGE then
        dwTargetBox, dwTargetX = player.GetStackRoomInBank(dwBox, dwX, nAmount)
        if not (dwTargetBox and dwTargetX) then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_ERROR_BANK_IS_FULL)
            return false
        end
    end

    local nRetCode, bTimeExistItem, nLeftExistTime, bEqualTime = player.CanStackTimeExistItem(dwBox, dwX, dwTargetBox, dwTargetX)
    if nRetCode == ITEM_RESULT_CODE.SUCCESS and bTimeExistItem and not bEqualTime then
        local szTime = UIHelper.GetTimeTextWithDay(nLeftExistTime)
        local szText = FormatString(g_tStrings.STACK_TIME_EXIST_ITEM_TIP, szTime)
        local dialog = UIHelper.ShowConfirm(szText, function()
            GetClientPlayer().ExchangeItem(dwBox, dwX, dwTargetBox, dwTargetX, nAmount)
        end, function()
            local dwEmptyBox, dwEmptyX
            if dwBoxType == INVENTORY_TYPE.PACKAGE then
                for i = 1, nCount, 1 do
                    local dwBankBox = BankIndexToInventoryIndex(i)
                    local dwSize = player.GetBoxSize(dwBankBox)
                    dwSize = dwSize - 1
                    for dwBankX = 0, dwSize, 1 do
                        local hItem = ItemData.GetPlayerItem(player, dwBankBox, dwBankX)
                        if not hItem and ItemData.CanExchangeItem(dwBox, dwX, dwBankBox, dwBankX) then
                            dwEmptyBox, dwEmptyX = dwBankBox, dwBankX
                            break
                        end
                    end
                    if dwEmptyBox and dwEmptyX then
                        break
                    end
                end
            else
                dwEmptyBox, dwEmptyX = player.GetFreeRoomInPackage()
            end
            GetClientPlayer().ExchangeItem(dwBox, dwX, dwEmptyBox, dwEmptyX, nAmount)
        end)
        dialog:SetConfirmButtonContent(g_tStrings.STR_DISCARD_SURE)
        dialog:SetCancelButtonContent("不叠加")
        return true
    else
        ItemData.OnExchangeItem(dwBox, dwX, dwTargetBox, dwTargetX, nAmount)
        return true
    end

    return false
end

local fnExchangeClick = function(nCount, nBox, nIndex)
    ExchangeItemBetweenBankAndBag(nBox, nIndex, nCount)
    Event.Dispatch(EventType.HideAllHoverTips)
end

local GetBatchMaxSize = function()
    local dwUsedSize = 0
    local player = g_pClientPlayer
    for i = 1, nCount, 1 do
        local nIndex = BankIndexToInventoryIndex(i)
        local dw1 = player.GetBoxSize(nIndex)
        if dw1 and dw1 ~= 0 then
            dwUsedSize = dwUsedSize + dw1 - player.GetBoxFreeRoomSize(nIndex)
        end
    end
    return dwUsedSize
end

local function GetPackageType(nBagIndex)
    local player = PlayerData.GetClientPlayer()
    local item = ItemData.GetPlayerItem(player, INVENTORY_INDEX.EQUIP, nBagIndex)
    if item then
        local itemInfo = GetItemInfo(item.dwTabType, item.dwIndex)
        if itemInfo then
            if itemInfo.nPackageGenerType == 4 and itemInfo.nPackageSubType == -1 then
                return 1
            elseif itemInfo.nPackageGenerType == 3 and itemInfo.nPackageSubType == 2 then
                return 2
            elseif itemInfo.nPackageGenerType == 3 and itemInfo.nPackageSubType == 1 then
                return 3
            else
                return nil
            end
        end
    end
end

local DataModel = {
    tBoxSize = {},
    tAllItemLIst = {}
}

function DataModel.IsShowAll()
    return DataModel.nFilterClass == 0
end

function DataModel.RefreshAll()
    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

    DataModel.nTimeLimitedCount = 0
    DataModel.tBoxSize = {}
    DataModel.tAllItemLIst = {}

    for i = 1, nCount, 1 do
        local dwBox = BankIndexToInventoryIndex(i)
        local dwSize = player.GetBoxSize(dwBox)
        local nType = GetPackageType(tbExpandItemSlot[i])

        DataModel.tAllItemLIst[dwBox] = DataModel.tAllItemLIst[dwBox] or {}
        DataModel.tBoxSize[dwBox] = dwSize

        for dwX = 0, dwSize - 1, 1 do
            DataModel.UpdateItemByPos(dwBox, dwX, nil, nType)
        end
    end
end

function DataModel.UpdateItemByPos(nBox, nIndex, item, nType)
    local tOldData = DataModel.tAllItemLIst[nBox][nIndex]
    nType = nType or (tOldData and tOldData.nType)
    if tOldData and tOldData.bIsExpiring then
        DataModel.nTimeLimitedCount = DataModel.nTimeLimitedCount - 1 -- 计算临期物品数量
    end

    item = item or ItemData.GetItemByPos(nBox, nIndex)
    local tItemInfo = item and GetItemInfo(item.dwTabType, item.dwIndex)
    local bIsExpiring = ItemData.IsItemExpiring(tItemInfo, item)
    local tData = { nBox = nBox, nIndex = nIndex, nType = nType, bHasItem = item ~= nil
    , dwItemID = item and item.dwID, hItem = item, bIsExpiring = bIsExpiring }
    DataModel.tAllItemLIst[nBox][nIndex] = tData

    if bIsExpiring then
        DataModel.nTimeLimitedCount = DataModel.nTimeLimitedCount + 1 -- 计算临期物品数量
    end
end

function DataModel.GetFilteredItemDataList(fnFilter)
    local player = PlayerData.GetClientPlayer()
    local tRes = {}
    if not player or not fnFilter then
        return tRes
    end

    for i = 1, nCount, 1 do
        local nBox = BankIndexToInventoryIndex(i)
        if not DataModel.tBoxSize[nBox] or player.GetBoxSize(nBox) ~= DataModel.tBoxSize[nBox] then
            DataModel.RefreshAll() -- 检查背包大小是否发生变化
            break
        end
    end

    for i = 1, nCount, 1 do
        local nBox = BankIndexToInventoryIndex(i)
        for index = 0, player.GetBoxSize(nBox) - 1 do
            local tData = DataModel.tAllItemLIst[nBox][index]
            if fnFilter(tData.hItem) then
                table.insert(tRes, tData)
            end
        end
    end

    return tRes
end

local UIPanelRoleWareHouse = class("UIPanelRoleWareHouse")

function UIPanelRoleWareHouse:OnEnter()
    self:RegEvent()
    self:BindUIEvent()

    DataModel.nFilterClass = -1
    DataModel.nFilterSub = 0
    DataModel.nFilterTag = 0
    DataModel.RefreshAll()

    self.nPVPType = 1
    self.nAdditionalFilterTab = 1
    self.nCount = 6
    self.bCompareBag = false
    self.expandScript = UIHelper.GetBindScript(self.WidgetAniWareHouseUp)
    self.nOriginalScrollListHeight = UIHelper.GetHeight(self.WidgetScrollListParent)

    if not self.bInit then
        self.bInit = true
        self.tbPVPFilter = PVP_FILTER_TABLE

        local tbFilterDefSelected = FilterDef.Storehouse.tbRuntime
        if tbFilterDefSelected then
            tbFilterDefSelected[1][1] = 1
            tbFilterDefSelected[2][1] = 1
        end

        UIHelper.SetSwallowTouches(self.BtnBatchBg, true)
    end

    UIHelper.SetVisible(self.BtnScreen, true)
    UIHelper.SetVisible(self.BtnNeaten, true)
    UIHelper.SetVisible(self.BtnCombine, true)
    UIHelper.SetVisible(self.BtnBatchTakeOut, true)
    UIHelper.SetVisible(self.BtnPutIn, true)
    UIHelper.SetVisible(self.BtnBagUpgrade, true)
    UIHelper.SetVisible(self.WidgetBaiZhanSearch, true)
    UIHelper.SetVisible(self.TogCompareBag, true)
    UIHelper.SetSelected(self.TogCompareBag, false, false)
    UIHelper.SetVisible(self.WidgetRoleHouseTab, true)
    UIHelper.SetVisible(self.WidgetRoleHouseArrowParent, true)

    UIHelper.SetVisible(self.ScrollViewWareHouse, false)
    UIHelper.SetVisible(self.LayoutScrollList, true)

    self:CheckDefaultFilter()
    self:InitScrollList()
    self:InitMainFilter()
    UIHelper.SetSelected(self.tbLeftTogScripts[1].ToggleChildNavigation, true, true)
    UIHelper.ScrollViewSetupArrow(self.ScrollViewTab, self.WidgetRoleHouseArrowParent)

    WarehouseDragData.SetExchangeFunc(ItemData.OnExchangeItem)
    WarehouseDragData.SetUIBoxType(nil)

    local tbFunctions = {
        szName = "存入",
        OnClick = fnExchangeClick
    }
    self.bagScript = ItemData.GetBagScript() ---@type UIBagViewNew
    self.bagScript:EnterWareHouseState(tbFunctions)
end

function UIPanelRoleWareHouse:OnExit()
    --self.bInit = false
    self.expandScript:Hide()
    self.bCompareBag = false
    self:UnRegEvent()

    UIHelper.SetVisible(self.WidgetChildTab, false)
    UIHelper.SetSelected(self.BtnBagUpgrade, false)
    self:CalculateScrollListHeight()
    TipsHelper.DeleteAllHoverTips(true)
end

function UIPanelRoleWareHouse:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnScreen, EventType.OnClick, function(btn)
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnScreen, TipsLayoutDir.RIGHT_CENTER, FilterDef.Storehouse)
    end)

    UIHelper.BindUIEvent(self.BtnCombine, EventType.OnClick, function(btn)
        if PropsSort.IsBankInSort() then
            TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
            return
        end
        Stack()
    end)

    UIHelper.BindUIEvent(self.TogCompareBag, EventType.OnSelectChanged, function(tog, bSelected)
        if self.bagScript then
            if bSelected then
                self.bagScript:EnterCompareState()
                self.bCompareBag = true
            else
                self.bagScript:ExitCompareState()
                self.bCompareBag = false
            end
            WarehouseData.RefreshScrollList()
        end
    end)

    -- 仓库格子筛选 end ----------------------------------------------

    UIHelper.BindUIEvent(self.BtnNeaten, EventType.OnClick, function()
        self:BigBankSort()
    end)

    UIHelper.BindUIEvent(self.BtnBagUpgrade, EventType.OnSelectChanged, function(_, bSelected)
        if PropsSort.IsBagInSort() or PropsSort.IsBankInSort() then
            UIHelper.SetSelected(self.BtnBagUpgrade, false)
            TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
            return
        end

        self.expandScript:SetVisibility(bSelected)
    end)
end

function UIPanelRoleWareHouse:RegEvent()
    local OnUpdate = function(nBox, nIndex, szEvent)
        local item = ItemData.GetItemByPos(nBox, nIndex)
        DataModel.UpdateItemByPos(nBox, nIndex)

        if (item and item.dwID == WarehouseData.dwItemID) or (nBox == WarehouseData.tbPos.nBox and nIndex == WarehouseData.tbPos.nIndex) then
            WarehouseData.DoUpdateSelect(nil) -- 更新选中道具详细信息
        end

        -- 更新格子
        local scriptCell = WarehouseData.GetCellScript(nBox, nIndex) -- 更新格子
        local bShow = self:IsShow(item)
        if scriptCell and bShow then
            scriptCell:UpdateInfo()
            local itemScript = scriptCell:GetItemScript()
            self:InitItemScript(itemScript, nBox, nIndex, item and item.dwID)
            self:UpdateTabToggle()
        else
            local flag = self:ShouldUpdateAllCell(nBox, nIndex, bShow)
            if flag then
                self:RefreshWareHouseCells(SCROLL_LIST_UPDATE_TYPE.RELOAD)
            else
                if not PropsSort.IsBankInSort() then
                    WarehouseData.RefreshDataOnly(true)  --不在显示范围内，并且不影响当前显示内容时，仅更新数据内容
                    self:UpdateTabToggle()
                end
            end
        end

        self:UpdateWareHouseSize()
    end

    Event.Reg(self, "BANK_ITEM_UPDATE", function(nBox, nIndex, bNewAdd)
        OnUpdate(nBox, nIndex, "BANK_ITEM_UPDATE")
    end)

    Event.Reg(self, "EQUIP_ITEM_UPDATE", function(nBox, nIndex, bNewAdd)
        self:UpdateWareHouseInfo(SCROLL_LIST_UPDATE_TYPE.RELOAD)
    end)

    Event.Reg(self, "ON_RESIZE_PACKAGE_NOTIFY", function(dwBox, dwSize)
        if INVENTORY_INDEX.BANK == dwBox then
            self:UpdateWareHouseInfo(SCROLL_LIST_UPDATE_TYPE.RELOAD)
        end
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function(nBox, nIndex, bNewAdd)
        if WarehouseData.dwItemID then
            UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroup, nil)
        end
    end)

    Event.Reg(self, EventType.OnFilter, function(szKey, tbSelected)
        if szKey == FilterDef.Storehouse.Key then
            self.nAdditionalFilterTab = ITEM_FILTER_TYPE[tbSelected[1][1]]
            self.nPVPType = tbSelected[2][1]
            self:UpdateWareHouseInfo()
            self:CheckDefaultFilter()
        end
    end)

    Event.Reg(self, EventType.OnWarehouseFilterTextUpdate, function()
        self:UpdateWareHouseInfo()
    end)

    Event.Reg(self, EventType.OnWarehouseDragEnd, function()
        WarehouseData.dwItemID = 1 -- 拖动结束时标记为选中状态，方便后续相应HideAllHoverTips事件
    end)

    Event.Reg(self, EventType.OnBankBagCompareUpdate, function()
        if self.bCompareBag then
            WarehouseData.RefreshScrollList()
        end
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        if WarehouseData.dwItemID then
            UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroup, nil)
        end
        Timer.AddFrame(self, 3, function()
            UIHelper.ScrollViewDoLayout(self.ScrollViewChildTab)
            UIHelper.ScrollToLeft(self.ScrollViewChildTab, 0)

            self.nOriginalScrollListHeight = UIHelper.GetHeight(self.WidgetScrollListParent)
            self:CalculateScrollListHeight(true)
        end)
    end)
end

function UIPanelRoleWareHouse:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelRoleWareHouse:UpdateInfo()
    self:UpdateWareHouseInfo()
end

function UIPanelRoleWareHouse:CheckDefaultFilter()
    local bDefault = self.nAdditionalFilterTab == 1 and self.nPVPType == 1
    UIHelper.SetSpriteFrame(self.ImgScreen, bDefault and ShopData.szScreenImgDefault or ShopData.szScreenImgActiving)
end

function UIPanelRoleWareHouse:InitScrollList()
    local fnGetCellList = function()
        local lst = DataModel.GetFilteredItemDataList(function(hItem)
            return self:IsShow(hItem)
        end)

        return lst
    end

    local fnCellInitFunc = function(targetNode, parentLayout, tbPos)
        local cellScript = UIHelper.GetBindScript(targetNode) or select(2, ItemData.GetBagCellPrefabPool():Allocate(parentLayout))
        if cellScript:GetItemScript() then
            cellScript:GetItemScript():OnPoolRecycled(true)
        end

        cellScript:OnEnter(tbPos.nBox, tbPos.nIndex)
        cellScript:UpdateBagImgType(tbPos.nType)
        
        local itemScript = cellScript:GetItemScript()
        self:InitItemScript(itemScript, tbPos.nBox, tbPos.nIndex, tbPos.dwItemID)
        WarehouseData.StoreCellScript(tbPos.nBox, tbPos.nIndex, cellScript)
        WarehouseDragData.Add(cellScript)
        return cellScript
    end

    WarehouseData.SetItemTipCallback(ExchangeItemBetweenBankAndBag)
    WarehouseData.SetBatchMaxSizeFunc(GetBatchMaxSize)
    WarehouseData.SetCellInitFunc(fnCellInitFunc)
    WarehouseData.SetGetCellListFunc(fnGetCellList)
end

function UIPanelRoleWareHouse:InitMainFilter()
    self.tbLeftTogScripts = {}
    UIHelper.RemoveAllChildren(self.ScrollViewTab)

    for _, i in ipairs(BAG_FILTER_ORDER) do
        local tConfig = ITEM_FILTER_SETTING[i]
        if tConfig and tConfig.szType ~= "New" then
            local fnSubSelected = function(toggle, bState)
                if bState then
                    if i ~= DataModel.nFilterClass then
                        self:SelectLeftTab(i)
                        self.selectedMainTog = toggle
                    end
                end
            end
            local subData = { szTitle = tConfig.szName, onSelectChangeFunc = fnSubSelected }
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetWarehouseChild, self.ScrollViewTab, subData)
            script.nFilterClass = i
            table.insert(self.tbLeftTogScripts, script)
            
            if i == nTimeLimitedIndex then
                self.tTimeLimitedNode = script._rootNode
            end
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTab)
end

-------------------------Special---------------------------

function UIPanelRoleWareHouse:UpdateTabToggle()
    local player = g_pClientPlayer
    local bHasTimeLimitItem = false

    for i = 1, self.nCount, 1 do
        local dwBox = BankIndexToInventoryIndex(i)
        local dwSize = player.GetBoxSize(dwBox)
        dwSize = dwSize - 1

        for dwX = 0, dwSize, 1 do
            local hItem = ItemData.GetPlayerItem(player, dwBox, dwX)
            if hItem then
                local hItemInfo = GetItemInfo(hItem.dwTabType, hItem.dwIndex)
                if not bHasTimeLimitItem and ItemData.IsItemExpiring(hItemInfo, hItem) then
                    bHasTimeLimitItem = true
                    break
                end
            end

        end
    end
    Event.Dispatch(EventType.OnWarehouseExpireItemUpdate, bHasTimeLimitItem)

    if not bHasTimeLimitItem and DataModel.nFilterClass == nTimeLimitedIndex then
        UIHelper.SetSelected(self.tbLeftTogScripts[1].ToggleChildNavigation, true) -- 没有临期物品时分类消失
    end

    if self.tTimeLimitedNode and bHasTimeLimitItem ~= UIHelper.GetVisible(self.tTimeLimitedNode) then
        UIHelper.SetVisible(self.tTimeLimitedNode, bHasTimeLimitItem)
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTab)
        for _, script in ipairs(self.tbLeftTogScripts) do
            if script.nFilterClass == DataModel.nFilterClass then
                UIHelper.ScrollLocateToPreviewItem(self.ScrollViewTab, script._rootNode, Locate.TO_CENTER)
                break
            end
        end
    end
end

function UIPanelRoleWareHouse:IsShow(item)
    local bIsCommon = BagViewData.IsMatchCommon(item, DataModel.nFilterClass, DataModel.nFilterSub)
    local bMatch = bIsCommon or BagViewData.IsMatchFilter(item, DataModel.nFilterClass, DataModel.nFilterSub, DataModel.nFilterTag)
    local tbFilterCfg = ADDITIONAL_FILTER_TABLE[self.nAdditionalFilterTab]
    local tPVP = self.tbPVPFilter[self.nPVPType]

    return bMatch and tbFilterCfg.filterFunc(item) and tPVP.filterFunc(item) and WarehouseData.CheckMatchFilter(item)
end

function UIPanelRoleWareHouse:UpdateWareHouseSize()
    local dwSize, dwFreeSize = 0, 0
    local player = g_pClientPlayer
    for i = 1, self.nCount, 1 do
        local nIndex = BankIndexToInventoryIndex(i)
        local dw1 = player.GetBoxSize(nIndex)
        if dw1 and dw1 ~= 0 then
            dwSize = dwSize + dw1
            local dw2 = player.GetBoxFreeRoomSize(nIndex)
            dwFreeSize = dwFreeSize + dw2
        end
    end

    UIHelper.SetString(self.LabelWareHouseSize, string.format("(%d/%d)", dwSize - dwFreeSize, dwSize))
    UIHelper.SetString(self.LabelTitleSize, string.format("(%d/%d)", dwSize - dwFreeSize, dwSize))
    UIHelper.LayoutDoLayout(self.LayoutTitle)
end

function UIPanelRoleWareHouse:UpdateWareHouseInfo(nUpdateType)
    nUpdateType = nUpdateType or SCROLL_LIST_UPDATE_TYPE.RESET
    self:UpdateWareHouseSize()
    self:RefreshWareHouseCells(nUpdateType)
end

function UIPanelRoleWareHouse:InitItemScript(itemScript, nBox, nIndex, dwItemID)
    if itemScript then
        itemScript:EnableTimeLimitFlag(true)
        itemScript:SetToggleGroup(self.ToggleGroup)
        itemScript:SetSelectMode(WarehouseData.bBatchSelect, true)
        itemScript:SetHandleChooseEvent(true)
        itemScript:SetSelectChangeCallback(function(dwItemID, bSelected)
            WarehouseData.tbPos.nBox, WarehouseData.tbPos.nIndex = nBox, nIndex
            WarehouseData.OnItemSelectChange(dwItemID, bSelected)
        end)
        self:SetItemNodeGray(itemScript, nBox, nIndex)

        if WarehouseData.bBatchSelect then
            if dwItemID and WarehouseData.tbBatch[dwItemID] then
                itemScript:OnItemIconChoose(true, nBox, nIndex, WarehouseData.tbBatch[dwItemID].nStackNum)
                itemScript:RawSetSelected(true)
            else
                itemScript:RawSetSelected(false)
            end
        end
    end
end

function UIPanelRoleWareHouse:SelectLeftTab(nFilterClass)
    DataModel.nFilterClass = nFilterClass
    DataModel.nFilterSub = 0
    DataModel.nFilterTag = Table_GetBigBagFilterTag(DataModel.nFilterClass)

    self.tChildFilterScripts = {}
    -- 初始化二级分类
    local tFilterData = ITEM_FILTER_SETTING[nFilterClass]
    local bHasSub = false
    if tFilterData and not tFilterData.szType and not DataModel.IsShowAll() then
        local tSubList = Table_GetBigBagSubFilter(nFilterClass) --全部子类
        if #tSubList > 0 then
            UIHelper.RemoveAllChildren(self.ScrollViewChildTab)
            bHasSub = true
            local fnAddChildTab = function(nFilterSub, szName)
                local fnSubSelected = function(toggle, bState)
                    if bState then
                        if nFilterSub ~= DataModel.nFilterSub then
                            DataModel.nFilterSub = nFilterSub
                            DataModel.nFilterTag = Table_GetBigBagFilterTag(DataModel.nFilterClass, nFilterSub)
                            WarehouseData.StopBatch()
                            self:UpdateWareHouseInfo()
                        end
                    end
                end
                local subData = { szTitle = szName, onSelectChangeFunc = fnSubSelected }
                local script = UIHelper.AddPrefab(PREFAB_ID.WidgetBagChildTab, self.ScrollViewChildTab, subData)
                UIHelper.SetToggleGroupIndex(script.ToggleChildNavigation, ToggleGroupIndex.MainCityNodeSizeSelect)
                UIHelper.SetVisible(script.ImgRedpoint, false)
                return script
            end

            local script = fnAddChildTab(0, "全部")
            script.nFilterSub = 0
            UIHelper.SetSelected(script.ToggleChildNavigation, true, false)
            table.insert(self.tChildFilterScripts, script)

            for _, tSub in ipairs(tSubList) do
                if #self.tChildFilterScripts >= 5 then
                    UIHelper.AddPrefab(PREFAB_ID.WidgetBagChildTab_Empty, self.ScrollViewChildTab)
                    UIHelper.AddPrefab(PREFAB_ID.WidgetBagChildTab_Empty, self.ScrollViewChildTab) -- 为了让第六个选项居中 增加两个空的占位符
                end
                local nFilterSub = tSub.nSub
                local script = fnAddChildTab(nFilterSub, UIHelper.GBKToUTF8(tSub.szSubName))
                script.nFilterSub = nFilterSub
                table.insert(self.tChildFilterScripts, script)

                if _ == #tSubList then
                    UIHelper.SetVisible(script.ImgLine, false) -- 最后一个选项隐藏线
                end
            end

            UIHelper.ScrollViewDoLayout(self.ScrollViewChildTab)
            UIHelper.ScrollToLeft(self.ScrollViewChildTab, 0)
        end
    end

    UIHelper.SetVisible(self.LabelTitleSize, DataModel.IsShowAll())
    UIHelper.SetVisible(self.WidgetChildTab, bHasSub)
    WarehouseData.StopBatch()

    Event.Dispatch(EventType.OnWarehouseCancelTouch)
    self:CalculateScrollListHeight(true)
    self:UpdateWareHouseInfo()
end

function UIPanelRoleWareHouse:BigBankSort()
    local tList = {}
    local tAllBoxList = {}

    if PropsSort.IsBankInSort() then
        return
    end
    
    local bLocked = BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.BANK)
    if bLocked then
        UIMgr.OpenSingle(false, VIEW_ID.PanelLingLongMiBao, SAFE_LOCK_EFFECT_TYPE.BANK)
        return
    end

    -- 整理时处于全部分页且未进行筛选时对性能影响最小
    if not (DataModel.IsShowAll() and self.nAdditionalFilterTab == 1 and self.nPVPType == 1) then
        if self.selectedMainTog then
            UIHelper.SetSelected(self.selectedMainTog, false, false) -- 取消之前分页的选择状态
        end
        self.nAdditionalFilterTab = 1
        self.nPVPType = 1
        UIHelper.SetSelected(self.tbLeftTogScripts[1].ToggleChildNavigation, true, false) -- 应用全部分页选中状态
        self:SelectLeftTab(0)
        self:CheckDefaultFilter()
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTab)
    end

    tList, tAllBoxList = self:UpdateStack()
    PropsSort.BeginSort(tList, tAllBoxList, m_szMark)
end

function UIPanelRoleWareHouse:UpdateStack()
    local player = g_pClientPlayer
    local tList = {}
    local tAllBoxList = {}

    local nIndex = 0
    for i = 1, self.nCount, 1 do
        local dwBox = BankIndexToInventoryIndex(i)
        local dwSize = player.GetBoxSize(dwBox)
        if player.CheckBoxCanUse(dwBox) then
            for dwX = 0, dwSize - 1, 1 do
                local hItem = ItemData.GetPlayerItem(player, dwBox, dwX)
                if hItem ~= nil then
                    table.insert(tList, { dwBox, dwX })
                end
                table.insert(tAllBoxList, { dwBox, dwX })
                nIndex = nIndex + 1
            end
        end
    end

    return tList, tAllBoxList
end

function UIPanelRoleWareHouse:UpdateBankCompare()
    self:TraverseCellScript(function(CellScript, _nBox, _nIndex)
        local ItemScript = CellScript:GetItemScript()
        if ItemScript then
            local item = ItemData.GetItemByPos(_nBox, _nIndex)
            if item then
                local bGray = self.bCompareBag and not ItemData.IsCommonItemBetweenBagAndBank(item)
                UIHelper.SetNodeGray(ItemScript.ImgIcon, bGray, true)
                UIHelper.SetOpacity(ItemScript._rootNode, not bGray and 255 or 120)
            end
        end
    end)
end

function UIPanelRoleWareHouse:RefreshWareHouseCells(nUpdateType)
    WarehouseDragData.Clear()
    WarehouseData.ClearCellScript()

    WarehouseData.RefreshDataOnly(false)
    WarehouseData.RefreshScrollList(nUpdateType)
    self:UpdateTabToggle()

    UIHelper.SetVisible(self.WidgetEmpty, WarehouseData.IsScrollListEmpty())
end

function UIPanelRoleWareHouse:SetItemNodeGray(ItemScript, nBox, nIndex)
    if ItemScript and nBox and nIndex then
        local bGray = false
        local item = ItemData.GetItemByPos(nBox, nIndex)
        if item then
            if not bGray and self.bCompareBag then
                item = item or ItemData.GetItemByPos(nBox, nIndex)
                if item then
                    bGray = not ItemData.IsCommonItemBetweenBagAndBank(item)
                end
            end
        end

        UIHelper.SetNodeGray(ItemScript.ImgIcon, bGray, true)
        UIHelper.SetOpacity(ItemScript._rootNode, not bGray and 255 or 120)
    end
end

function UIPanelRoleWareHouse:CalculateScrollListHeight(bForceUpdate)
    local nChildTabHeight = 0
    if UIHelper.GetHierarchyVisible(self.ScrollViewChildTab) then
        nChildTabHeight = #self.tChildFilterScripts > 5 and 80 or 40
        UIHelper.SetHeight(self.ScrollViewChildTab, nChildTabHeight)

        nChildTabHeight = nChildTabHeight - 25 -- LayoutScrollList 稍微往上提

        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewChildTab)
    end

    local nCurrentHeight = UIHelper.GetHeight(self.LayoutScrollList)
    local nDiffHeight = nChildTabHeight
    local nTargetHeight = self.nOriginalScrollListHeight - nDiffHeight
    if bForceUpdate or nCurrentHeight ~= nTargetHeight then
        UIHelper.SetHeight(self.LayoutScrollList, nTargetHeight)
        WarehouseData.UpdateListSize()
    end

    if bForceUpdate then
        WarehouseData.RefreshScrollList(SCROLL_LIST_UPDATE_TYPE.RESET)
    end
end

-----------------------------------------------------------------------------

function UIPanelRoleWareHouse:ShouldUpdateAllCell(nBox, nIndex)
    if WarehouseData.nIndexToCellPos then
        local tbFilterCfg = ADDITIONAL_FILTER_TABLE[self.nAdditionalFilterTab]
        local tPVP = self.tbPVPFilter[self.nPVPType]
        if DataModel.IsShowAll() and tbFilterCfg.bShowEmptyCell and tPVP.bShowEmptyCell and not WarehouseData.HasFilterText() then
            return false  -- 展示所有格子的情况下必定不需要刷新所有CELL
        end

        local min, max = WarehouseData.GetRangeOfLoadedCells()
        local nStartIndex = (min - 1) * nItemCountOfEachRow + 1
        local nEndIndex = math.min(max * nItemCountOfEachRow, #WarehouseData.nIndexToCellPos)

        local tStartData = WarehouseData.nIndexToCellPos[nStartIndex]
        local tEndData = WarehouseData.nIndexToCellPos[nEndIndex]

        if not tEndData or not tStartData then
            return true
        end

        local bBelow = tEndData and nBox > tEndData.nBox or (nBox == tEndData.nBox and nIndex > tEndData.nIndex)
        local bFull = nEndIndex >= max * nItemCountOfEachRow
        return not (bBelow and bFull) -- 只有当被更新的格子在当前展示格子的下方，且当前页面已满时 才不需要刷新页面
    end
end

return UIPanelRoleWareHouse