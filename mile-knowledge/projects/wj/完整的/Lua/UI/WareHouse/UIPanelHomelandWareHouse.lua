local MAX_SHOW_EMPTY_BOTTOM_COUNT = 50
local tbRegUpdateEvent = {
    "REMOTE_PLANT_WAREHOUSE1_EVENT", -- 对应类型物品存取触发事件
    "REMOTE_PLANT_WAREHOUSE2_EVENT",
    "REMOTE_FISH_WAREHOUSE2_EVENT",
    "REMOTE_QIWUPU_WAREHOUSE1_EVENT",
    "REMOTE_PERFUME_WAREHOUSE1_EVENT",
    "REMOTE_SERVANT_WAREHOUSE2_EVENT",
    "REMOTE_SELLER_WAREHOUSE1_EVENT",
}
local SHOW_TYPE = {
    Normal = 1,
    Map = 2,
}
local tbAlwaysShowList = {
    -- 家园地图外的道具显示列表
    ["CheckBox_Perfume"] = 5,
    ["CheckBox_ShopKeeper"] = 7,
}
local tWarehouseFilterCheck = {
    [0] = {
        szName = "全部",
        szCheck = "CheckBox_All",
        filterFunc = function(item)
            return true
        end
    },
    [1] = {
        szName = "种植材料",
        szCheck = "CheckBox_Plant",
        DATAMANAGE = 1064,
        ITEMSTART = 2,
        BYTE_NUM = 2,
    },
    [2] = {
        szName = "种植作物",
        szCheck = "CheckBox_Cereals",
        DATAMANAGE = 1065,
        ITEMSTART = 0,
        BYTE_NUM = 2,
    },
    [3] = {
        szName = "宠物出行",
        szCheck = "CheckBox_Pet",
        DATAMANAGE = 1112,
        ITEMSTART = 0,
        BYTE_NUM = 1,
    },
    [4] = {
        szName = "家园垂钓",
        szCheck = "CheckBox_Fish",
        DATAMANAGE = 1109,
        ITEMSTART = 0,
        BYTE_NUM = 2,
    },
    [5] = {
        szName = "调香材料",
        szCheck = "CheckBox_Perfume",
        DATAMANAGE = 1153,
        ITEMSTART = 0,
        BYTE_NUM = 1,
    },
    [6] = {
        szName = "管家物品",
        szCheck = "CheckBox_HouseKeep",
        DATAMANAGE = 1155,
        ITEMSTART = 0,
        BYTE_NUM = 2,
    },
    [7] = {
        szName = "掌柜物品",
        szCheck = "CheckBox_ShopKeeper",
        DATAMANAGE = 1157,
        ITEMSTART = 0,
        BYTE_NUM = 1,
    },
}
local tBagFilterCheck = {
    [1] = { szFilter = "全部", bTakeOutAll = false, bShowEmptyCell = true, filterFunc = function(nClassType)
        return true
    end },
    [2] = { szFilter = "种植", bTakeOutAll = true, bShowEmptyCell = false, filterFunc = function(nClassType)
        return nClassType == 1
    end },
    [3] = { szFilter = "作物", bTakeOutAll = true, bShowEmptyCell = false, filterFunc = function(nClassType)
        return nClassType == 2
    end },
    [4] = { szFilter = "出行", bTakeOutAll = true, bShowEmptyCell = false, filterFunc = function(nClassType)
        return nClassType == 3
    end },
    [5] = { szFilter = "垂钓", bTakeOutAll = true, bShowEmptyCell = false, filterFunc = function(nClassType)
        return nClassType == 4
    end },
    [6] = { szFilter = "调香", bTakeOutAll = true, bShowEmptyCell = false, filterFunc = function(nClassType)
        return nClassType == 5
    end },
    [7] = { szFilter = "管家", bTakeOutAll = true, bShowEmptyCell = false, filterFunc = function(nClassType)
        return nClassType == 6
    end },
    [8] = { szFilter = "掌柜", bTakeOutAll = true, bShowEmptyCell = false, filterFunc = function(nClassType)
        return nClassType == 7
    end },
}

local function _GetSubArray(aArray, nBeg, nEnd)
    local aSubArray = {}
    for i = nBeg, nEnd do
        table.insert(aSubArray, aArray[i])
    end
    return aSubArray
end
local UIPanelHomelandWareHouse = class("UIPanelHomelandWareHouse")
function UIPanelHomelandWareHouse:OnEnter()
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

    self.tbTabCfg = tBagFilterCheck

    self.nWarehouseFilterIndex = 1
    self.nWarehouseShowType = SHOW_TYPE.Normal

    -- UIHelper.SetVisible(self.BtnScreen, true)
    UIHelper.SetVisible(self.BtnBatchTakeOut, true)
    UIHelper.SetVisible(self.BtnPutIn, true)
    UIHelper.SetVisible(self.WidgetRoleList, true)
    --UIHelper.SetVisible(self.BtnChange_ToType, true)
    UIHelper.SetVisible(self.WidgetBaiZhanSearch, true)
    UIHelper.LayoutDoLayout(self.LayoutSideButton)

    UIHelper.SetVisible(self.ScrollViewWareHouse, false)
    UIHelper.SetVisible(self.LayoutScrollList, true)

    local tbFunctions = {
        szName = "存入",
        OnClick = function(nCount, nBox, nIndex)
            if PropsSort.IsBagInSort() or PropsSort.IsBankInSort() then
                TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
                return
            end
            self:StoreOneItem(nCount, nBox, nIndex)
            Event.Dispatch(EventType.HideAllHoverTips)
        end,
    }
    self.bagScript = ItemData.GetBagScript() ---@type UIBagView
    self.bagScript:EnterWareHouseState(tbFunctions)

    self.tbFilterScripts = {}
    UIHelper.SetVisible(self.WidgetChildTab, true)
    UIHelper.RemoveAllChildren(self.ScrollViewTab)
    local bFirst = true
    for i = 1, 8 do
        local tConfig = self.tbTabCfg[i]
        local fnSubSelected = function(toggle, bState)
            if bState and self.nWarehouseFilterIndex ~= i then
                self.nWarehouseFilterIndex = i
                self:UpdateWareHouseInfo(SCROLL_LIST_UPDATE_TYPE.RESET)
            end
        end
        local subData = { szTitle = tConfig.szFilter, onSelectChangeFunc = fnSubSelected }
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetWarehouseChild, self.ScrollViewTab, subData)

        script:SetSelected(bFirst)
        self.tbFilterScripts[i] = script
        bFirst = false
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTab)

    self:InitScrollList()
    self:UpdateInfo()
end

function UIPanelHomelandWareHouse:OnExit()
    self.bInit = false
    self:UnRegEvent()

    self.tbCellScripts = {}
    self.tbFilterScripts = {}

    self:StopBatch()
    TipsHelper.DeleteAllHoverTips(true)
end

function UIPanelHomelandWareHouse:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnBagUpgrade, EventType.OnClick, function()
        if PropsSort.IsBagInSort() or PropsSort.IsBankInSort() then
            UIHelper.SetSelected(self.BtnBagUpgrade, false)
            TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
            return
        end
        UIMgr.Open(VIEW_ID.PanelWarehouseUp)
    end)

    UIHelper.BindUIEvent(self.BtnTemporaryHouse, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelFurnitureStoragePop)
    end)

    UIHelper.BindUIEvent(self.BtnSaveAll, EventType.OnClick, function()
        local tClass = {}
        if not self:IsBagCanStoreAll() then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_LOCKER_CANSTORE_ALL)
            return
        end
        if PropsSort.IsBagInSort() or PropsSort.IsBankInSort() then
            TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
            return
        end
        for _, v in ipairs(self.tWarehouseFilterCheck) do
            table.insert(tClass, v.DATAMANAGE)
        end
        local tBagLock = BagViewData.GetHomelandLockData()
        RemoteCallToServer("On_HomeLand_StoreAll", tClass, tBagLock)
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_LOCKER_STORESUCCESS)
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

    UIHelper.BindUIEvent(self.BtnFlowerPrice, EventType.OnClick, function()
        UIMgr.Close(VIEW_ID.PanelHalfBag)
        UIMgr.Close(VIEW_ID.PanelHalfWarehouse)
        UIMgr.Close(VIEW_ID.PanelSystemMenu)
        UIMgr.Open(VIEW_ID.PanelFlowerPrice)
    end)

    UIHelper.BindUIEvent(self.BtnConfiguration, EventType.OnClick, function()
        HomelandIdentity.UseToyBoxSkill(76)
    end)
end

function UIPanelHomelandWareHouse:RegEvent()
    for _, event in ipairs(tbRegUpdateEvent) do
        -- 物品存取触发更新
        Event.Reg(self, event, function()
            Event.Dispatch(EventType.OnHomeWarehouseUpdate)
        end)
    end

    Event.Reg(self, EventType.OnHomeWarehouseUpdate, function()
        self.nUpdateTimer = self.nUpdateTimer or Timer.AddFrame(self, 1, function()
            self:UpdateLockerInfo()
            self:UpdateInfo()
            self.nUpdateTimer = nil
        end)
    end)

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
end

function UIPanelHomelandWareHouse:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelHomelandWareHouse:UpdateInfo()
    local nUpdateType = SCROLL_LIST_UPDATE_TYPE.RELOAD
    if not self.bFirstOpenFlag then
        self:UpdateLockerInfo()
        nUpdateType = SCROLL_LIST_UPDATE_TYPE.RESET
        self.bFirstOpenFlag = true
    end
    self:UpdateWareHouseInfo(nUpdateType)
    self:RefreshButtons()
end

function UIPanelHomelandWareHouse:InitScrollList()
    local fnGetCellList = function()
        local tCellList = {}
        local bHasFilterText = WarehouseData.HasFilterText()
        local tbSelectedTabCfg = self.tbTabCfg[1]
        local tbItemList = self:GetWarehouseInfo(self.nWarehouseFilterIndex - 1)
        for index, tbItemInfo in ipairs(tbItemList) do
            local tItemInfo = ItemData.GetItemInfo(tbItemInfo.dwItemType, tbItemInfo.dwItemID)
            local bShowItem = tItemInfo and WarehouseData.CheckMatchFilter(tItemInfo)

            local bShowEmpty = not bHasFilterText and tbSelectedTabCfg.bShowEmptyCell
            if bShowItem or bShowEmpty then
                local tNew = tbItemInfo
                table.insert(tCellList, tNew)
            end
        end
        return tCellList
    end

    local fnCellInitFunc = function(targetNode, parentLayout, tbPos)
        local cellScript = UIHelper.GetBindScript(targetNode) or select(2, ItemData.GetBagCellPrefabPool():Allocate(parentLayout))
        if cellScript:GetItemScript() then
            cellScript:GetItemScript():OnPoolRecycled(true)
        end

        cellScript:OnInitWithTabID(tbPos.dwItemType, tbPos.dwItemID, tbPos.nCount)
        local itemScript = cellScript:GetItemScript()
        if itemScript then
            self:InitItemScript(itemScript, tbPos)
        end
        return cellScript
    end

    WarehouseData.SetCellInitFunc(fnCellInitFunc)
    WarehouseData.SetGetCellListFunc(fnGetCellList)
end

-------------------------Batch---------------------------

function UIPanelHomelandWareHouse:UpdateBatchSelectNum()
    UIHelper.SetString(self.LabelBatchNum, string.format("%d/%d",
            table.get_len(self.tbBatchSelectedItems), WarehouseData.GetTotalCellSize()))
end

function UIPanelHomelandWareHouse:DeselectAll()
    self.tbSelected = {}
end

function UIPanelHomelandWareHouse:TraverseCellScript(func)
    for _, script in pairs(self.tbCellScripts) do
        func(script)
    end
end

function UIPanelHomelandWareHouse:StartBatch()
    self:DeselectAll()
    self.bBatchSelect = true
    self.tbSelected.dwItemID = nil
    self.tbSelected = {}
    self.tbBatchSelectedItems = {}

    self:UpdateWareHouseInfo(SCROLL_LIST_UPDATE_TYPE.RELOAD)
    self:UpdateBatchSelectNum()

    UIHelper.SetVisible(self.WidgetDiscardAnchor, true)
    UIHelper.SetVisible(self.WidgetBaiZhanSearch, false)
end

function UIPanelHomelandWareHouse:ConfirmBatch()
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

function UIPanelHomelandWareHouse:StopBatch()
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

function UIPanelHomelandWareHouse:DoTakeOutAllBatch()
    local tList = {}
    for _, tbIteminfo in pairs(self.tbBatchSelectedItems) do
        table.insert(tList, tbIteminfo)
    end
    
    local _MAX_APPLY_COUNT = 5
    local nItemCount = #tList
    local nRounds = math.ceil(nItemCount / _MAX_APPLY_COUNT)
    local i = 1
    self.nTakeOutTimerID = Timer.AddCycle(self, 0.4, function()
        if i <= nRounds then
            local aParamItems = _GetSubArray(tList, (i - 1) * _MAX_APPLY_COUNT + 1, math.min(nItemCount, i * _MAX_APPLY_COUNT))
            if not table.is_empty(aParamItems) then
                for _, tbItemInfo in ipairs(aParamItems) do
                    self:PickUpOneItem(tbItemInfo)
                end
            end
            i = i + 1
        end
        if i > nRounds then
            Timer.DelTimer(self, self.nTakeOutTimerID)
        end
    end)
end

-------------------------WareHouse------------------------------------

function UIPanelHomelandWareHouse:UpdateWareHouseSize()
    UIHelper.SetVisible(self.LabelWareHouseSize, false)
    UIHelper.SetVisible(self.LabelTitleSize, false)
end

function UIPanelHomelandWareHouse:UpdateWareHouseInfo(nUpdateType)
    -- UIHelper.SetVisible(self.ScrollViewWareHouse, false)
    -- UIHelper.SetVisible(self.ScrollTypeList, false)

    if self.nWarehouseShowType == SHOW_TYPE.Normal then
        -- UIHelper.SetVisible(self.ScrollViewWareHouse, true)
        self:UpdateWareHouseSize()
        self:RefreshWareHouseCells(nUpdateType)
    elseif self.nWarehouseShowType == SHOW_TYPE.Map then
        -- UIHelper.SetVisible(self.ScrollTypeList, true)
        --self:MapType_RefreshWareHouseCells()
    end
end

function UIPanelHomelandWareHouse:RefreshWareHouseCells(nUpdateType)
    self.tbCellScripts = {}

    WarehouseData.RefreshDataOnly(false)
    WarehouseData.RefreshScrollList(nUpdateType)

    --if not bHasFilterText then
    --    -- 策划要的剩余空格子,上限动态调整不小于设定值且为5的整数倍
    --    local nEndCount = math.max(MAX_SHOW_EMPTY_BOTTOM_COUNT, #tbItemList + (5 - math.fmod(#tbItemList, 5)))
    --    for i = #tbItemList + 1, nEndCount, 1 do
    --        UIHelper.AddPrefab(PREFAB_ID.WidgetBagBottom, self.ScrollViewWareHouse)
    --    end
    --end

    UIHelper.SetVisible(self.WidgetEmpty, WarehouseData.IsScrollListEmpty())
end

function UIPanelHomelandWareHouse:InitItemScript(itemScript, tbItemInfo)
    if itemScript then
        table.insert(self.tbCellScripts, itemScript)
        itemScript.tbItemInfo = {
            dwItemType = tbItemInfo.dwItemType or nil,
            dwItemID = tbItemInfo.dwItemID or nil,
            nCount = tbItemInfo.nCount or nil,
            dwClassType = tbItemInfo.dwClassType or nil,
            dwDataIndex = tbItemInfo.dwDataIndex or nil,
        }

        itemScript:SetToggleGroupIndex(ToggleGroupIndex.BagItem)
        itemScript:SetSelectMode(self.bBatchSelect)
        itemScript:RawSetSelected(self.tbBatchSelectedItems[tbItemInfo.dwItemID] ~= nil)

        UIHelper.SetVisible(itemScript.ImgWeaponMark, false)
        -- itemScript:SetClearSeletedOnCloseAllHoverTips(not self.bBatchSelect)
        itemScript:SetSelectChangeCallback(function(dwItemID, bSelected)
            self.tbSelected = itemScript
            if self.bBatchSelect then
                if self.tbBatchSelectedItems[tbItemInfo.dwItemID] then
                    self.tbBatchSelectedItems[tbItemInfo.dwItemID] = nil
                else
                    self.tbBatchSelectedItems[tbItemInfo.dwItemID] = tbItemInfo
                end
                self:UpdateBatchSelectNum()
            end
            self.nCurIconScript = itemScript
            self.scriptItemTip = self.scriptItemTip or UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemCard)

            local nStackNum = itemScript.tbItemInfo.nCount
            local szCountTitle = "取出数量："
            local szConfirmLabel = g_tStrings.tbItemString.TAKEOUT_ITEM_CONFIRM_DIALOG_BUTTON_NAME
            if self.bBatchSelect then
                self.scriptItemTip:SetFunctionButtons({})
                -- self.scriptItemTip:ShowPlacementBtn(true, nStackNum, nStackNum, szConfirmLabel, szCountTitle)
            else
                self.scriptItemTip:ShowWareHouseSlider(nStackNum, nStackNum, szConfirmLabel, szCountTitle, function(nCount)
                    if PropsSort.IsBagInSort() or PropsSort.IsBankInSort() then
                        TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
                        return
                    end
                    self:PickUpOneItem(itemScript.tbItemInfo, nCount)
                    Event.Dispatch(EventType.HideAllHoverTips)
                end)
                -- self.scriptItemTip:ShowWareHousePreviewSlider(tbItemInfo)
                self.scriptItemTip:ShowWareHousePreviewSlider(tbItemInfo.dwItemType, tbItemInfo.dwItemID)
            end
            if self.bBatchSelect then
                self.scriptItemTip:SetBtnState({}) --批量取出时去掉按钮
            end
            self.scriptItemTip:OnInitWithTabID(tbItemInfo.dwItemType, tbItemInfo.dwItemID)
            
        end)
    end
end

function UIPanelHomelandWareHouse:RefreshButtons()
    UIHelper.SetVisible(self.BtnFlowerPrice, self.bIsHomelandMap)
    UIHelper.SetVisible(self.BtnBatchTakeOut, self.bIsHomelandMap)
    UIHelper.SetVisible(self.BtnSaveAll, self.bIsHomelandMap)
    UIHelper.SetVisible(self.BtnTemporaryHouse, self.bIsHomelandMap)
    UIHelper.SetVisible(self.BtnConfiguration, true)
    UIHelper.SetVisible(self.BtnPutIn, false)
    UIHelper.SetVisible(self.LayoutBottomBtn2, true)
    UIHelper.LayoutDoLayout(self.LayoutBottomBtn)
end

function UIPanelHomelandWareHouse:UpdateLockerInfo()
    local pPlayer = GetClientPlayer()
    if not pPlayer.RemoteDataAutodownFinish() then
        OutputMessage("MSG_SYS", g_tStrings.STR_TOYBOX_ERROR_MSG)
        return
    end
    local dwMapID = pPlayer.GetMapID()
    local _, nMapType = GetMapParams(dwMapID)

    self.bIsHomelandMap = nMapType == MAP_TYPE.HOMELAND
    self.tLockerInfo = clone(Table_GetHomelandLockerInfo())
    self.tWarehouseFilterCheck = clone(tWarehouseFilterCheck)
    if not self.bIsHomelandMap then
        for dwClassType, _ in pairs(self.tWarehouseFilterCheck) do
            if not table.contain_value(tbAlwaysShowList, dwClassType) then
                self.tWarehouseFilterCheck[dwClassType] = nil
            end
        end
    end

    for k, v in ipairs(self.tLockerInfo) do
        if v.dwClassType > 0 and self.bIsHomelandMap then
            local tFilter = self.tWarehouseFilterCheck[v.dwClassType]
            local nCount = pPlayer.GetRemoteArrayUInt(tFilter.DATAMANAGE, tFilter.ITEMSTART + (v.dwDataIndex - 1) * tFilter.BYTE_NUM, tFilter.BYTE_NUM)
            v.nCount = nCount or 0
        elseif table.contain_value(tbAlwaysShowList, v.dwClassType) and not self.bIsHomelandMap then
            -- 家园地图外只获取掌柜道具
            local tFilter = self.tWarehouseFilterCheck[v.dwClassType]
            local nCount = pPlayer.GetRemoteArrayUInt(tFilter.DATAMANAGE, tFilter.ITEMSTART + (v.dwDataIndex - 1) * tFilter.BYTE_NUM, tFilter.BYTE_NUM)
            v.nCount = nCount or 0
        end
    end
end

function UIPanelHomelandWareHouse:GetWarehouseInfo(dwFilterID)
    local tRetLocker = {}
    if dwFilterID == 0 then
        for k, v in ipairs(self.tLockerInfo) do
            if v.nCount and v.nCount > 0 then
                table.insert(tRetLocker, v)
            end
        end
    else
        for k, v in ipairs(self.tLockerInfo) do
            if dwFilterID == v.dwClassType and v.nCount and v.nCount > 0 then
                table.insert(tRetLocker, v)
            end
        end
    end
    return tRetLocker
end

function UIPanelHomelandWareHouse:StoreOneItem(nCount, nBox, nIndex)
    local bCanStore = false
    local item = ItemData.GetItemByPos(nBox, nIndex)
    for _, v in ipairs(self.tLockerInfo) do
        if v.dwItemType == item.dwTabType and v.dwItemID == item.dwIndex then
            bCanStore = true
            local dwRemain = v.dwMaxNum - v.nCount
            local tFilter = self.tWarehouseFilterCheck[v.dwClassType]
            if dwRemain >= nCount then
                RemoteCallToServer("On_HomeLand_StoreItem", v.dwItemType, v.dwItemID, nCount, tFilter.DATAMANAGE, v.dwDataIndex, tFilter.BYTE_NUM)
                OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_LOCKER_STORESUCCESS)
            elseif dwRemain > 0 and dwRemain < nCount then
                RemoteCallToServer("On_HomeLand_StoreItem", v.dwItemType, v.dwItemID, dwRemain, tFilter.DATAMANAGE, v.dwDataIndex, tFilter.BYTE_NUM)
                OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_LOCKER_STORESUCCESS)
            else
                OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_LOCKER_FULLTORE)
            end
            break
        end
    end

    if not bCanStore then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_LOCKER_CANSTORE)
    end
end

function UIPanelHomelandWareHouse:PickUpOneItem(tbItemInfo, nCount)
    local tFilter = tWarehouseFilterCheck[tbItemInfo.dwClassType]
    nCount = nCount or tbItemInfo.nCount
    RemoteCallToServer("On_HomeLand_PickItem", tbItemInfo.dwItemType, tbItemInfo.dwItemID, nCount, tFilter.DATAMANAGE,
            tbItemInfo.dwDataIndex, tFilter.BYTE_NUM)
end

function UIPanelHomelandWareHouse:IsBagCanStoreAll()
    local bCanStore = false
    for _, tbItemInfo in ipairs(ItemData.GetItemList(ItemData.BoxSet.Bag)) do
        local item = ItemData.GetItemByPos(tbItemInfo.nBox, tbItemInfo.nIndex)
        if item then
            for _, v in ipairs(self.tLockerInfo) do
                if table.contain_key(self.tWarehouseFilterCheck, v.dwClassType) and v.dwItemType == item.dwTabType and v.dwItemID == item.dwIndex then
                    if (v.dwMaxNum - v.nCount) > 0 then
                        bCanStore = true    -- 还需要没达到储存上限
                        break
                    end
                end
            end
        end
    end
    return bCanStore
end
return UIPanelHomelandWareHouse