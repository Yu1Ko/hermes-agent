-- ---------------------------------------------------------------------------------
-- Author: JiaYuRan
-- Name: UIPanelWareHouse
-- ---------------------------------------------------------------------------------
local LOCKER_SIZE = 50
local DATA_LEN = 2
local DATA_INDEX = 1146
local START_INDEX = 0
local END_INDEX = 99

-----------------------------DataModel------------------------------

local DataModel = {}

local tbBaiZhanFilter = {
    [1] = { bShowEmptyCell = true, szName = "全部", filterFunc = function(item)
        local tInfo = DataModel.TABLE_OUT_SKILL_BOOK[item.dwID]
        return tInfo
    end },
    [2] = { bShowEmptyCell = false, szName = "一重", filterFunc = function(item)
        local tInfo = DataModel.TABLE_OUT_SKILL_BOOK[item.dwID]
        return tInfo and tInfo[2] == 1
    end },
    [3] = { bShowEmptyCell = false, szName = "二重", type = ITEM_GENRE.TASK_ITEM, filterFunc = function(item)
        local tInfo = DataModel.TABLE_OUT_SKILL_BOOK[item.dwID]
        return tInfo and tInfo[2] == 2
    end },
    [4] = { bShowEmptyCell = false, szName = "三重", type = ITEM_GENRE.EQUIPMENT, filterFunc = function(item)
        local tInfo = DataModel.TABLE_OUT_SKILL_BOOK[item.dwID]
        return tInfo and tInfo[2] == 3
    end },
    [5] = { bShowEmptyCell = false, szName = "四重", type = ITEM_GENRE.POTION, filterFunc = function(item)
        local tInfo = DataModel.TABLE_OUT_SKILL_BOOK[item.dwID]
        return tInfo and tInfo[2] == 4
    end },
    [6] = { bShowEmptyCell = false, szName = "五重", type = ITEM_GENRE.MATERIAL, filterFunc = function(item)
        local tInfo = DataModel.TABLE_OUT_SKILL_BOOK[item.dwID]
        return tInfo and tInfo[2] == 5
    end },
    [7] = { bShowEmptyCell = false, szName = "六重", type = ITEM_GENRE.MATERIAL, filterFunc = function(item)
        local tInfo = DataModel.TABLE_OUT_SKILL_BOOK[item.dwID]
        return tInfo and tInfo[2] == 6
    end },
    [8] = { bShowEmptyCell = false, szName = "七重", type = ITEM_GENRE.MATERIAL, filterFunc = function(item)
        local tInfo = DataModel.TABLE_OUT_SKILL_BOOK[item.dwID]
        return tInfo and tInfo[2] == 7
    end },
    [9] = { bShowEmptyCell = false, szName = "八重", type = ITEM_GENRE.MATERIAL, filterFunc = function(item)
        local tInfo = DataModel.TABLE_OUT_SKILL_BOOK[item.dwID]
        return tInfo and tInfo[2] == 8
    end },
    [10] = { bShowEmptyCell = false, szName = "九重", type = ITEM_GENRE.MATERIAL, filterFunc = function(item)
        local tInfo = DataModel.TABLE_OUT_SKILL_BOOK[item.dwID]
        return tInfo and tInfo[2] == 9
    end },
    [11] = { bShowEmptyCell = false, szName = "十重", type = ITEM_GENRE.MATERIAL, filterFunc = function(item)
        local tInfo = DataModel.TABLE_OUT_SKILL_BOOK[item.dwID]
        return tInfo and tInfo[2] == 10
    end },
}

function DataModel.Init()
    DataModel.szFliter = ""
    DataModel.tLockerItem = Table_GetMonsterLockerItem()
    DataModel.tLockerInfo = DataModel.UpdateLockerInfo()
end

function DataModel.UpdateLockerInfo()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    if not hPlayer.RemoteDataAutodownFinish() then
        TipsHelper.ShowImportantBlueTip(g_tStrings.STR_TOYBOX_ERROR_MSG)
        return
    end

    local tRes = {}
    for i = START_INDEX, END_INDEX, DATA_LEN do
        local dwID = hPlayer.GetRemoteArrayUInt(DATA_INDEX, i, DATA_LEN)
        if dwID and dwID ~= 0 then
            table.insert(tRes, { dwID = dwID, nDataIndex = i })
        end
    end
    return tRes
end

function DataModel.Update()
    DataModel.tLockerInfo = DataModel.UpdateLockerInfo()
end

function DataModel.GetTotalCount()
    if DataModel.tLockerInfo then
        return #DataModel.tLockerInfo
    end
end

function DataModel.GetLockerItem(dwID)
    return DataModel.tLockerItem[dwID]
end

function DataModel.GetLockerItemByItemID(dwID)
    for k, v in pairs(DataModel.tLockerItem) do
        if v.dwItemID == dwID then
            return v
        end
    end
end

function DataModel.UnInit()
    DataModel.szFliter = nil
    DataModel.tLockerItem = nil
    DataModel.tLockerInfo = nil
end

-----------------------------------------------------------

local UIPanelBaiZhanWareHouse = class("UIPanelBaiZhanWareHouse")

local function AddItemToLocker(nCount, nBox, nIndex)
    if not g_pClientPlayer then
        return
    end

    local tItem = ItemData.GetPlayerItem(g_pClientPlayer, nBox, nIndex)
    if not tItem then
        return
    end

    local tInfo = DataModel.tLockerItem
    local bMatched = false
    for _, v in pairs(tInfo) do
        if v.dwItemType == tItem.dwTabType and v.dwItemID == tItem.dwIndex then
            bMatched = true
            RemoteCallToServer("On_MonsterBook_StoreItem", v.dwID, v.dwItemType, v.dwItemID)
            break
        end
    end

    if not bMatched then
        TipsHelper.ShowImportantYellowTip(g_tStrings.MONSTER_LOCKER_NOT_FIT)
    end
end

function UIPanelBaiZhanWareHouse:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        UIHelper.SetSwallowTouches(self.BtnBatchBg, true)

        DataModel.Init()
    end

    LoadScriptFile(UIHelper.UTF8ToGBK("scripts/Map/百战异闻录/include/百战异闻录外部技能常量数据.lua"), DataModel)

    self.tbTabCfg = tbBaiZhanFilter

    self.bBatchSelect = false

    self.nSelectedTab = 1
    self.tbSelected = { dwItemID = nil, tbPos = { nBox = nil, nIndex = nil }, tbBatch = {} }

    UIHelper.SetVisible(self.BtnSaveAll, true)
    UIHelper.SetVisible(self.WidgetBaiZhanSearch, true)
    UIHelper.SetVisible(self.TogSearch, true)
    UIHelper.SetVisible(self.WidgetChildTabArrowParent, true)

    UIHelper.SetVisible(self.ScrollViewWareHouse, false)
    UIHelper.SetVisible(self.LayoutScrollList, true)

    local tbFunctions = {
        OnClick = AddItemToLocker,
        fnValid = function(nBox, nIndex)
            if g_pClientPlayer and nBox and nIndex then
                local item = ItemData.GetItemByPos(nBox, nIndex)
                return DataModel.TABLE_OUT_SKILL_BOOK[item.dwIndex] ~= nil
            end
            return false
        end
    }
    self.bagScript = ItemData.GetBagScript() ---@type UIBagView
    self.bagScript:EnterWareHouseState(tbFunctions)

    UIHelper.SetVisible(self.WidgetChildTab, true)
    UIHelper.RemoveAllChildren(self.ScrollViewTab)
    local bFirst = true
    for i = 1, 11 do
        local tConfig = self.tbTabCfg[i]
        local fnSubSelected = function(toggle, bState)
            if bState and self.nSelectedTab ~= i then
                self.nSelectedTab = i
                self:RefreshWareHouseCells(SCROLL_LIST_UPDATE_TYPE.RESET)
            end
        end
        local subData = { szTitle = tConfig.szName, onSelectChangeFunc = fnSubSelected }
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetWarehouseChild, self.ScrollViewTab, subData)

        script:SetSelected(bFirst)
        bFirst = false
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTab)
    UIHelper.ScrollViewSetupArrow(self.ScrollViewTab, self.WidgetChildTabArrowParent)

    self:InitScrollList()
    DataModel.Update()
    self:RefreshWareHouseCells(SCROLL_LIST_UPDATE_TYPE.RESET)
end

function UIPanelBaiZhanWareHouse:OnExit()
    self.bInit = false
    self:UnRegEvent()

    --UIHelper.SetVisible(self.WidgetBaiZhanSearch, false)
    UIHelper.SetSelected(self.TogSearch, false)
    TipsHelper.DeleteAllHoverTips(true)
end

function UIPanelBaiZhanWareHouse:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSaveAll, EventType.OnClick, function()
        if PropsSort.IsBagInSort() or PropsSort.IsBankInSort() then
            TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
            return
        end
        self:StoreAll()
    end)

    UIHelper.BindUIEvent(self.TogBanZhanBookClose, EventType.OnClick, function()
        for _, script in pairs(self.tbTypeBagList) do
            --script:UpdateLayout()
            script:UpdateTogSelected(false)
        end
    end)

    UIHelper.BindUIEvent(self.BtnBookOpen, EventType.OnClick, function()
        for _, script in pairs(self.tbTypeBagList) do
            --script:UpdateLayout()
            script:UpdateTogSelected(true)
        end
    end)
end

function UIPanelBaiZhanWareHouse:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function(nBox, nIndex, bNewAdd)
        UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroup, nil)
        self:UpdateSelectedItemDetails()
    end)

    Event.Reg(self, "UPDATE_MONSTER_LOCKER", function(nBox, nIndex, bNewAdd)
        DataModel.Update()
        self:RefreshWareHouseCells()
    end)

    Event.Reg(self, EventType.OnWarehouseFilterTextUpdate, function()
        self:RefreshWareHouseCells(SCROLL_LIST_UPDATE_TYPE.RESET)
        UIHelper.ScrollToTop(self.ScrollViewWareHouse)
    end)
end

function UIPanelBaiZhanWareHouse:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelBaiZhanWareHouse:InitScrollList()
    local fnGetCellList = function()
        local tCellList = {}
        local nCurCount = 0
        for _, v in pairs(DataModel.tLockerInfo) do
            local tInfo = DataModel.GetLockerItem(v.dwID)
            if tInfo then
                local tItem = ItemData.GetItemInfo(tInfo.dwItemType, tInfo.dwItemID)
                if tItem and WarehouseData.CheckMatchFilter(tItem) then
                    local tbSelectedTabCfg = self.tbTabCfg[self.nSelectedTab]
                    local bShowItem = tbSelectedTabCfg.filterFunc(tItem)
                    if bShowItem then
                        nCurCount = nCurCount + 1
                        local tNew = { nDataIndex = v.nDataIndex, dwID = tInfo.dwID,
                                       dwItemType = tInfo.dwItemType, dwItemID = tInfo.dwItemID }
                        table.insert(tCellList, tNew)
                    end
                end
            end
            if nCurCount >= LOCKER_SIZE then
                break
            end
        end
        return tCellList
    end

    local fnCellInitFunc = function(targetNode, parentLayout, tbPos)
        local cellScript = UIHelper.GetBindScript(targetNode) or select(2, ItemData.GetBagCellPrefabPool():Allocate(parentLayout))
        if cellScript:GetItemScript() then
            cellScript:GetItemScript():OnPoolRecycled(true)
        end

        local dwID = tbPos.dwID
        local dwItemType = tbPos.dwItemType
        local dwItemID = tbPos.dwItemID

        cellScript:OnInitWithTabID(dwItemType, dwItemID)
        local itemScript = cellScript:GetItemScript()
        if itemScript then
            itemScript:SetToggleGroup(self.ToggleGroup)
            itemScript:SetSelectMode(false)
            itemScript:SetSelectChangeCallback(function(_, bSelected)
                if bSelected then
                    self:UpdateSelectedItemDetails(dwID, dwItemType, dwItemID, tbPos.nDataIndex)
                end
            end)
        end
        return cellScript
    end

    WarehouseData.SetCellInitFunc(fnCellInitFunc)
    WarehouseData.SetGetCellListFunc(fnGetCellList)
end

-------------------------General---------------------------

function UIPanelBaiZhanWareHouse:UpdateSelectedItemDetails(dwID, dwItemType, dwItemID, nDataIndex)
    self.scriptItemTip = self.scriptItemTip or UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemCard)

    local fnCallback = function()
        if PropsSort.IsBagInSort() or PropsSort.IsBankInSort() then
            TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
            return
        end
        RemoteCallToServer("On_MonsterBook_PickItem", dwID, dwItemType, dwItemID, nDataIndex)
        self:UpdateSelectedItemDetails()
    end

    local szCountTitle = "取出数量："
    local szConfirmLabel = g_tStrings.tbItemString.TAKEOUT_ITEM_CONFIRM_DIALOG_BUTTON_NAME
    self.scriptItemTip:ShowWareHouseSlider(1, 1, szConfirmLabel, szCountTitle, fnCallback)
    self.scriptItemTip:ShowWareHousePreviewSlider(dwItemType, dwItemID)
    self.scriptItemTip:SetForbidShowEquipCompareBtn(true)
    if dwItemType and dwItemID then
        self.scriptItemTip:OnInitWithTabID(dwItemType, dwItemID)
    else
        UIHelper.SetVisible(self.scriptItemTip._rootNode, false)
    end
end

-------------------------WareHouse------------------------------------

function UIPanelBaiZhanWareHouse:UpdateWareHouseSize()
    local nCount = DataModel.GetTotalCount() or 0
    UIHelper.SetString(self.LabelWareHouseSize, string.format("(%d/%d)", nCount, LOCKER_SIZE))
    UIHelper.SetString(self.LabelTitleSize, string.format(" (%d/%d)", nCount, LOCKER_SIZE))
    UIHelper.LayoutDoLayout(self.LayoutTitle)
end

function UIPanelBaiZhanWareHouse:RefreshWareHouseCells(nUpdateType)
    WarehouseData.RefreshDataOnly(false)
    WarehouseData.RefreshScrollList(nUpdateType)

    UIHelper.SetVisible(self.WidgetEmpty, WarehouseData.IsScrollListEmpty())
    self:UpdateWareHouseSize()
end

function UIPanelBaiZhanWareHouse:StoreAll()
    local tRes = {}
    local hPlayer = g_pClientPlayer
    if not hPlayer then
        return
    end

    for k, tbItemInfo in ipairs(ItemData.GetItemList(ItemData.BoxSet.Bag)) do
        if tbItemInfo.hItem then
            local tInfo = DataModel.GetLockerItemByItemID(tbItemInfo.hItem.dwIndex)
            if tInfo then
                table.insert(tRes, { tInfo.dwID, tInfo.dwItemType, tInfo.dwItemID })
            end
        end
    end

    RemoteCallToServer("On_MonsterBook_StoreAll", tRes)
end

return UIPanelBaiZhanWareHouse