local REMOTE_DATA_ID = 1183
local WARE_TYPE = 1

local SHOW_TYPE = {
    Normal = 1,
    Map = 2,
}

local function _GetSubArray(aArray, nBeg, nEnd)
    local aSubArray = {}
    for i = nBeg, nEnd do
        table.insert(aSubArray, aArray[i])
    end
    return aSubArray
end

local tBagFilterCheck = {
    [1] = { szFilter = "全部", bTakeOutAll = false, bShowEmptyCell = true, filterFunc = function(tbItemInfo)
        return true
    end },
    [2] = { szFilter = "回复", bTakeOutAll = true, bShowEmptyCell = false, filterFunc = function(tbItemInfo)
        return ExtractWareHouseData.GetItemSubType(tbItemInfo.nAucSub) == ExtractItemSub.MEDICINE
    end },
    [3] = { szFilter = "武器", bTakeOutAll = true, bShowEmptyCell = false, filterFunc = function(tbItemInfo)
        return ExtractWareHouseData.GetItemSubType(tbItemInfo.nAucSub) == ExtractItemSub.WENPOS
    end },
    [4] = { szFilter = "防具", bTakeOutAll = true, bShowEmptyCell = false, filterFunc = function(tbItemInfo)
        return ExtractWareHouseData.GetItemSubType(tbItemInfo.nAucSub) == ExtractItemSub.ARMOR
    end },
    [5] = { szFilter = "饰品", bTakeOutAll = true, bShowEmptyCell = false, filterFunc = function(tbItemInfo)
        return ExtractWareHouseData.GetItemSubType(tbItemInfo.nAucSub) == ExtractItemSub.ACCESSORIES
    end },
    [6] = { szFilter = "伪装", bTakeOutAll = true, bShowEmptyCell = false, filterFunc = function(tbItemInfo)
        return ExtractWareHouseData.GetItemSubType(tbItemInfo.nAucSub) == ExtractItemSub.INVISIBILITY
    end },
    [7] = { szFilter = "其它", bTakeOutAll = true, bShowEmptyCell = false, filterFunc = function(tbItemInfo)
        return ExtractWareHouseData.GetItemSubType(tbItemInfo.nAucSub) == ExtractItemSub.OTHER
    end },
}

local UIPanelExtractWareHouse = class("UIPanelExtractWareHouse")
function UIPanelExtractWareHouse:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        UIHelper.SetSwallowTouches(self.BtnBatchBg, true)
    end

    -- 因为仓库每次切换左侧导航页都会调用一次OnEnter，所以加个保护防清空
    self.tLockerInfo = self.tLockerInfo or {}

    self.tbBatchSelectedItems = {}

    self.tbCellScripts = {}
    self.bBatchSelect = false

    self.nWarehouseFilterIndex = 1
    self.nWarehouseShowType = SHOW_TYPE.Normal

    UIHelper.SetVisible(self.BtnBatchTakeOut, true)
    UIHelper.SetVisible(self.BtnPutIn, true)
    UIHelper.SetVisible(self.BtnEquip, true)
    UIHelper.SetVisible(self.BtnBatchSell, false)
    UIHelper.SetVisible(self.BtnNeaten, true)
    UIHelper.SetVisible(self.WidgetRoleList, true)
    UIHelper.SetVisible(self.WidgetBaiZhanSearch, true)
    UIHelper.LayoutDoLayout(self.LayoutSideButton)

    UIHelper.SetVisible(self.ScrollViewWareHouse, false)
    UIHelper.SetVisible(self.LayoutScrollList, true)

    local tbFunctions = {
        szName = "存入",
        OnClick = function(nNum, nBox, nIndex)
            if PropsSort.IsBagInSort() or PropsSort.IsBankInSort() then
                TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
                return
            end
            self:StoreOneItem(nNum, nBox, nIndex)
            Event.Dispatch(EventType.HideAllHoverTips)
        end,
        fnValid = function(nBox, nIndex)
            local item = ItemData.GetItemByPos(nBox, nIndex)
            return item.nAucGenre == AUC_GENRE.DESERT
        end
    }
    self.bagScript = ItemData.GetBagScript() ---@type UIBagView
    self.bagScript:EnterWareHouseState(tbFunctions)

    self.tbFilterScripts = {}
    UIHelper.SetVisible(self.WidgetChildTab, true)
    UIHelper.RemoveAllChildren(self.ScrollViewTab)
    local bFirst = true
    for i = 1, #tBagFilterCheck do
        local tConfig = tBagFilterCheck[i]
        local fnSubSelected = function(toggle, bState)
            if bState and self.nWarehouseFilterIndex ~= i then
                self.nWarehouseFilterIndex = i
                self:UpdateWareHouseInfo(SCROLL_LIST_UPDATE_TYPE.RESET)
            end
            UIHelper.SetVisible(self.LabelTitleSize, self.nWarehouseFilterIndex == 1)
        end
        local subData = { szTitle = tConfig.szFilter, onSelectChangeFunc = fnSubSelected}
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetWarehouseChild, self.ScrollViewTab, subData)

        script:SetSelected(bFirst)
        self.tbFilterScripts[i] = script
        bFirst = false
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTab)

    if not ExtractWareHouseData.bInitData then
        ExtractWareHouseData.Init()
    end
    self:ResetBatchSell()
    self:InitScrollList()
    self:UpdateInfo()
end

function UIPanelExtractWareHouse:OnExit()
    self.bInit = false
    self:UnRegEvent()
    ExtractWareHouseData.UnInit()
    self.tbCellScripts = {}
    self.tbFilterScripts = {}

    self:StopBatch()
    TipsHelper.DeleteAllHoverTips(true)
end

function UIPanelExtractWareHouse:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnNeaten, EventType.OnClick, function()
        RemoteCallToServer("On_JueJing_TbfSort")
    end)

    UIHelper.BindUIEvent(self.BtnSaveAll, EventType.OnClick, function()
        ExtractWareHouseData.SaveAllToWare()
    end)

    UIHelper.BindUIEvent(self.BtnBagUpgrade, EventType.OnClick, function()
        if PropsSort.IsBagInSort() or PropsSort.IsBankInSort() then
            UIHelper.SetSelected(self.BtnBagUpgrade, false)
            TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
            return
        end
        UIMgr.Open(VIEW_ID.PanelWarehouseUp)
    end)

    UIHelper.BindUIEvent(self.BtnBatchSell, EventType.OnClick, function()
        if PropsSort.IsBagInSort() or PropsSort.IsBankInSort() then
            TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
            return
        end

        self:EnterBatchSell()
    end)

    UIHelper.BindUIEvent(self.BtnBatchApply_Sell, EventType.OnClick, function()
        self:DoBatchSell()
    end)

    UIHelper.BindUIEvent(self.BtnBatchCancel_Sell, EventType.OnClick, function()
        self:ResetBatchSell()
    end)

    UIHelper.BindUIEvent(self.BtnBatchTakeOut, EventType.OnClick, function()
        if PropsSort.IsBagInSort() or PropsSort.IsBankInSort() then
            TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
            return
        end
        self.bagScript:CancelBatch()
        self:StartBatch()
    end)

    UIHelper.BindUIEvent(self.BtnBatchApply, EventType.OnClick, function()
        if PropsSort.IsBagInSort() or PropsSort.IsBankInSort() then
            TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
            return
        end
        self:ConfirmBatch()
    end)

    UIHelper.BindUIEvent(self.BtnBatchCancel, EventType.OnClick, function()
        self:StopBatch()
    end)

    UIHelper.BindUIEvent(self.BtnEquip, EventType.OnClick, function()
        UIMgr.OpenSingle(false, VIEW_ID.PanelBattleFieldXunBao)
    end)
end

function UIPanelExtractWareHouse:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function()
        if self.scriptItemTip then
            self.scriptItemTip:OnInit()
            self.scriptItemTip:ShowPlacementBtn(false)
            return
        end
    end)

    Event.Reg(self, EventType.OnWarehouseFilterTextUpdate, function()
        self:UpdateWareHouseInfo(SCROLL_LIST_UPDATE_TYPE.RESET)
        UIHelper.ScrollViewDoLayout(self.ScrollViewWareHouse)
        UIHelper.ScrollToTop(self.ScrollViewWareHouse, 0)
    end)

    Event.Reg(self, EventType.OnSelelctHLWarehouseFilter, function(nIndex)
        self.nWarehouseFilterIndex = nIndex
        self:UpdateWareHouseInfo(SCROLL_LIST_UPDATE_TYPE.RESET)

        self.tbFilterScripts[nIndex]:SetSelected(true)
    end)

    Event.Reg(self, EventType.UpdateTBFWareHouse, function()
        self.bFirstOpenFlag = false
        self:UpdateInfo()
    end)
end

function UIPanelExtractWareHouse:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelExtractWareHouse:UpdateInfo()
    local nUpdateType = SCROLL_LIST_UPDATE_TYPE.RELOAD
    if not self.bFirstOpenFlag then
        self:UpdateLockerInfo()
        nUpdateType = SCROLL_LIST_UPDATE_TYPE.RESET
        self.bFirstOpenFlag = true
    end
    self:UpdateWareHouseInfo(nUpdateType)
    self:RefreshButtons()
end

function UIPanelExtractWareHouse:InitScrollList()
    local fnGetCellList = function()
        local tCellList = {}
        local tItemFilter = tBagFilterCheck[self.nWarehouseFilterIndex]
        local tbLockerInfo = self:GetWarehouseInfo(self.nWarehouseFilterIndex - 1)
        local nMaxSize = ExtractWareHouseData.GetMaxZone(ExtractItemType.WareHouse)
        local nUnlockZone = ExtractWareHouseData.GetUnlockZone(ExtractItemType.WareHouse)
        for i = 1, nMaxSize, 1 do
            local bShow = tItemFilter.bShowEmptyCell
            local item = tbLockerInfo[i] or {}
            local dwTabType, dwItemIndex, nNum = item.nType, item.dwIndex, item.nNum
            if dwTabType and dwItemIndex and dwTabType > 0 and dwItemIndex > 0 then
                local iteminfo = GetItemInfo(dwTabType, dwItemIndex)
                bShow = WarehouseData.CheckMatchFilter(iteminfo) and tItemFilter.filterFunc(iteminfo)
            end

            if bShow then
                local item = {nIndex = i, dwItemType = dwTabType, dwItemIndex = dwItemIndex,
                                nNum = nNum, bLock = i > nUnlockZone}
                table.insert(tCellList, item)
            end
        end

        return tCellList
    end

    local fnCellInitFunc = function(targetNode, parentLayout, tbPos)
        WarehouseData.RemoveCell(targetNode)
        targetNode = nil

        local cellScript = UIHelper.AddPrefab(PREFAB_ID.WidgetXunBaoItemCell, parentLayout)
        cellScript:OnEnter(tbPos)
        if tbPos.nNum and tbPos.nNum > 0 then
            local itemScript = cellScript:GetItemScript()
            if itemScript then
                self:InitItemScript(itemScript, tbPos)
            end
        end
        return cellScript
    end

    WarehouseData.SetCellInitFunc(fnCellInitFunc)
    WarehouseData.SetGetCellListFunc(fnGetCellList)
end

-------------------------Batch---------------------------

function UIPanelExtractWareHouse:UpdateBatchSelectNum()
    UIHelper.SetString(self.LabelBatchNum, string.format("%d/%d",
            table.get_len(self.tbBatchSelectedItems), WarehouseData.GetTotalCellSize()))
end

function UIPanelExtractWareHouse:DeselectAll()
    self.tbSelected = {}
end

function UIPanelExtractWareHouse:TraverseCellScript(func)
    for _, script in pairs(self.tbCellScripts) do
        func(script)
    end
end

function UIPanelExtractWareHouse:StartBatch()
    self:DeselectAll()
    self.bBatchSelect = true
    self.tbSelected.dwTabIndex = nil
    self.tbSelected = {}
    self.tbBatchSelectedItems = {}

    self:UpdateWareHouseInfo(SCROLL_LIST_UPDATE_TYPE.RELOAD)
    self:UpdateBatchSelectNum()

    UIHelper.SetVisible(self.WidgetDiscardAnchor, true)
    UIHelper.SetVisible(self.WidgetBaiZhanSearch, false)
end

function UIPanelExtractWareHouse:ConfirmBatch()
    if empty(self.tbSelected) then
        return
    end
    local szMsg = g_tStrings.tbItemString.BATCH_TAKEOUT_ITEM_CONFIRM
    local confirmDialog = UIHelper.ShowConfirm(szMsg, function()
        self:DoTakeOutAllBatch()
        self:StopBatch()
        self:UpdateBatchSelectNum()
    end)

    confirmDialog:SetButtonContent("Confirm", g_tStrings.tbItemString.TAKEOUT_ITEM_CONFIRM_DIALOG_BUTTON_NAME)
end

function UIPanelExtractWareHouse:StopBatch()
    self:DeselectAll()
    self.bBatchSelect = false
    self.bProcessBatch = false

    self.tbSelected = {}

    local traverseFunc = function(CellScript)
        if CellScript then
            CellScript:SetSelectMode(false, true)
        end
    end

    self:TraverseCellScript(traverseFunc)

    UIHelper.SetButtonState(self.BtnBatchCancel, BTN_STATE.Normal)
    UIHelper.SetButtonState(self.BtnBatchApply, BTN_STATE.Normal)

    UIHelper.SetVisible(self.WidgetDiscardAnchor, false)
    UIHelper.SetVisible(self.WidgetBaiZhanSearch, true)
end

function UIPanelExtractWareHouse:DoTakeOutAllBatch()
    local tList = {}
    for _, tbIteminfo in pairs(self.tbBatchSelectedItems) do
        table.insert(tList, {ExtractItemType.WareHouse, tbIteminfo.nIndex})
    end

    RemoteCallToServer("On_JueJing_TakeItemListW2B", tList)
end

-------------------------WareHouse------------------------------------

function UIPanelExtractWareHouse:UpdateWareHouseSize()
    UIHelper.SetVisible(self.LabelWareHouseSize, false)
    UIHelper.SetVisible(self.LabelTitleSize, false)
end

function UIPanelExtractWareHouse:UpdateWareHouseInfo(nUpdateType)
    if self.nWarehouseShowType == SHOW_TYPE.Normal then
        -- UIHelper.SetVisible(self.ScrollViewWareHouse, true)
        self:UpdateWareHouseSize()
        self:RefreshWareHouseCells(nUpdateType)
    elseif self.nWarehouseShowType == SHOW_TYPE.Map then
        -- UIHelper.SetVisible(self.ScrollTypeList, true)
        --self:MapType_RefreshWareHouseCells()
    end
end

function UIPanelExtractWareHouse:RefreshWareHouseCells(nUpdateType)
    self.tbCellScripts = {}

    WarehouseData.RefreshDataOnly(false)
    WarehouseData.RefreshScrollList(nUpdateType)

    UIHelper.SetVisible(self.WidgetEmpty, WarehouseData.IsScrollListEmpty())
end

function UIPanelExtractWareHouse:InitItemScript(itemScript, tbItemInfo)
    if itemScript then
        table.insert(self.tbCellScripts, itemScript)
        itemScript.tbItemInfo = {
            nIndex = tbItemInfo.nIndex or nil,
            dwTabType = tbItemInfo.dwTabType or nil,
            dwTabIndex = tbItemInfo.dwTabIndex or nil,
            nNum = tbItemInfo.nNum or nil,
        }
        itemScript.nBox = -1
        itemScript.nIndex = tbItemInfo.nIndex -- 用于仓库拖拽数据
        
        itemScript:SetToggleGroupIndex(ToggleGroupIndex.BagItem)
        itemScript:SetSelectMode(self.bBatchSelect or self.bBatchSell)
        itemScript:RawSetSelected(self.tbSellList and self.tbSellList[tbItemInfo.nIndex] ~= nil)
        itemScript:SetToggleSwallowTouches(false)

        local _fnUpdateBatchSellState = function()
            if self.bBatchSell then
                if tbItemInfo.nIndex and self.tbSellList[tbItemInfo.nIndex] then
                    itemScript:RawSetSelected(true)
                    itemScript:OnItemIconChoose(true, nil, nil, self.tbSellList[tbItemInfo.nIndex])
                    UIHelper.SetString(itemScript.LabelChooseNum, self.tbSellList[tbItemInfo.nIndex])
                    UIHelper.SetVisible(itemScript.LabelChooseNum, true)
                else
                    itemScript:OnItemIconChoose(false)
                    itemScript:RawSetSelected(false)
                end
            end
        end

        _fnUpdateBatchSellState()
        UIHelper.SetVisible(itemScript.ImgWeaponMark, false)
        itemScript:SetSelectChangeCallback(function(_, bSelected)
            self.tbSelected = itemScript
            if self.bBatchSelect then
                if self.tbBatchSelectedItems[tbItemInfo.nIndex] then
                    self.tbBatchSelectedItems[tbItemInfo.nIndex] = nil
                else
                    self.tbBatchSelectedItems[tbItemInfo.nIndex] = tbItemInfo
                end
                self:UpdateBatchSelectNum()
            end
            self.nCurIconScript = itemScript
            self.scriptItemTip = self.scriptItemTip or UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemCard)
            self.scriptItemTip:HidePreviewBtn(true)

            local nIndex = itemScript.tbItemInfo.nIndex
            local nStackNum = itemScript.tbItemInfo.nNum
            local szCountTitle = self.bBatchSell and "售出数量：" or "取出数量："
            local szConfirmLabel = self.bBatchSell and "确认" or "取出"
            if self.bBatchSelect then
                self.scriptItemTip:SetFunctionButtons({})
            else
                if self.bBatchSell then
                    self:AddToBatchSell(bSelected, nIndex, nStackNum)
                    _fnUpdateBatchSellState()
                end
                self.scriptItemTip:ShowPlacementBtn(true, nStackNum, nStackNum, szConfirmLabel, szCountTitle, function(nNum)
                    if PropsSort.IsBagInSort() or PropsSort.IsBankInSort() then
                        TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
                        return
                    end
                    Event.Dispatch(EventType.HideAllHoverTips)

                    if self.bBatchSell then
                        LOG.INFO("UIPanelExtractWareHouse:UpdateWareHouseInfo: AddToBatchSell:nSlot = %d, nNum = %d", nIndex, nNum)
                        -- self:AddToBatchSell(true, nIndex, nNum)
                        -- _fnUpdateBatchSellState()
                        return
                    end
                    self:PickUpOneItem(nIndex, nNum)
                end)
                self.scriptItemTip:ShowWareHousePreviewSlider(tbItemInfo.dwItemType, tbItemInfo.dwItemIndex)
            end
            self.scriptItemTip:OnInitWithTabID(tbItemInfo.dwItemType, tbItemInfo.dwItemIndex)
        end)
    end
end

function UIPanelExtractWareHouse:RefreshButtons()
    UIHelper.SetVisible(self.BtnSaveAll, true)
    UIHelper.SetVisible(self.BtnPutIn, false)
    UIHelper.SetVisible(self.LayoutBottomBtn3, true)
    UIHelper.LayoutDoLayout(self.LayoutBottomBtn)
end

function UIPanelExtractWareHouse:UpdateLockerInfo()
    self.tLockerInfo = ExtractWareHouseData.GetItemList(ExtractItemType.WareHouse)
end

function UIPanelExtractWareHouse:GetWarehouseInfo(dwFilterID)
    local tRetLocker = {}
    for k, v in ipairs(self.tLockerInfo) do
        table.insert(tRetLocker, v)
    end
    return tRetLocker
end

function UIPanelExtractWareHouse:StoreOneItem(nNum, nBox, nIndex)
    local bCanStore = true
    local Item = ItemData.GetItemByPos(nBox, nIndex)
    RemoteCallToServer("On_JueJing_SaveItemB2W", Item.dwTabType, Item.dwIndex, nNum, WARE_TYPE)

    if not bCanStore then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_LOCKER_CANSTORE)
    end
end

function UIPanelExtractWareHouse:PickUpOneItem(nIndex, nNum)
    RemoteCallToServer("On_JueJing_TakeItemW2B", WARE_TYPE, nIndex, nil, nil, nNum)
end

function UIPanelExtractWareHouse:EnterBatchSell()
    self.bBatchSell = true
    self.tbSellList = {}
    self:UpdateWareHouseInfo(SCROLL_LIST_UPDATE_TYPE.UPDATE_CELL)
    self:UpdateSellInfo()
    UIHelper.SetVisible(self.WidgetXunBaoAnchor, true)
end

function UIPanelExtractWareHouse:DoBatchSell()
    local tIndexList = {}
    for k, v in pairs(self.tbSellList) do
        table.insert(tIndexList, k)
    end
    RemoteCallToServer("On_JueJing_QuickSoldInWare", tIndexList)
    self:ResetBatchSell()
end

function UIPanelExtractWareHouse:AddToBatchSell(bSelected, nSlot, nNum)
    self.tbSellList = self.tbSellList or {}
    if bSelected then
        self.tbSellList[nSlot] = nNum
    else
        self.tbSellList[nSlot] = nil
    end

    self:UpdateSellInfo()
end

function UIPanelExtractWareHouse:UpdateSellInfo()
    self.tbSellList = self.tbSellList or {}
    local nTotalValue = 0
    for k, nNum in pairs(self.tbSellList) do
        nTotalValue = nTotalValue + ExtractWareHouseData.GetItemValue(ExtractItemType.WareHouse, k, nNum)
    end

    UIHelper.SetString(self.LabelCoinNum, nTotalValue)
    UIHelper.LayoutDoLayout(self.LayoutCost)
end

function UIPanelExtractWareHouse:ResetBatchSell()
    self.bBatchSell = false
    self.tbSellList = nil
    self:UpdateWareHouseInfo(SCROLL_LIST_UPDATE_TYPE.UPDATE_CELL)
    UIHelper.SetVisible(self.WidgetXunBaoAnchor, false)
end

return UIPanelExtractWareHouse