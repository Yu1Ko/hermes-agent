-- ---------------------------------------------------------------------------------
-- Author: Jiayuran
-- Name: UIBagViewNew
-- Date: 2025-1-23 17:01:56
-- Desc: ?
-- ---------------------------------------------------------------------------------

local function NeedUseTravellingBag()
    return BattleFieldData.IsInZombieBattleFieldMap() or BattleFieldData.IsInMobaBattleFieldMap()
end

local function GetPackageType(nIndex)
    local player = PlayerData.GetClientPlayer()
    local item = ItemData.GetPlayerItem(player, INVENTORY_INDEX.EQUIP, ItemData.SlotSet.BagSlot[nIndex - 1])
    local bMiBao = ItemData.BoxSet.Bag[nIndex] == INVENTORY_INDEX.PACKAGE_MIBAO
    if item then
        local itemInfo = GetItemInfo(item.dwTabType, item.dwIndex)
        if itemInfo then
            if itemInfo.nPackageGenerType == 4 and itemInfo.nPackageSubType == -1 then
                return 1
            elseif itemInfo.nPackageGenerType == 3 and itemInfo.nPackageSubType == 2 then
                return 2
            elseif itemInfo.nPackageGenerType == 3 and itemInfo.nPackageSubType == 1 then
                return 3
            elseif bMiBao then
                return 4
            else
                return nil
            end
        end
    end
end

local function GetBoxSet()
    local tBoxSet = ItemData.BoxSet.Bag  -- 默认是普通背包

    if NeedUseTravellingBag() then
        tBoxSet = ItemData.BoxSet.TravellingBag  -- 某些特殊玩法中使用特殊背包
    end

    return tBoxSet
end

local DataModel = {
    tBoxSize = {},
    tAllItemLIst = {}
}

function DataModel.IsShowAll()
    return DataModel.nFilterClass == 0
end

function DataModel.RefreshAll()
    local tbBoxSet = GetBoxSet()
    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

    DataModel.nTimeLimitedCount = 0
    DataModel.tBoxSize = {}
    DataModel.tAllItemLIst = {}
    for i, nBox in ipairs(tbBoxSet) do
        local nType = nil
        if i > 1 then
            nType = GetPackageType(i)
        end
        DataModel.tAllItemLIst[nBox] = DataModel.tAllItemLIst[nBox] or {}
        DataModel.tBoxSize[nBox] = player.GetBoxSize(nBox)
        for nIndex = 0, player.GetBoxSize(nBox) - 1 do
            DataModel.UpdateItemByPos(nBox, nIndex, nil, nType)
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
    local tbBoxSet = GetBoxSet()

    for i, nBox in ipairs(tbBoxSet) do
        if not DataModel.tBoxSize[nBox] or player.GetBoxSize(nBox) ~= DataModel.tBoxSize[nBox] then
            DataModel.RefreshAll()
            break
        end
    end

    for i, nBox in ipairs(tbBoxSet) do
        for index = 0, player.GetBoxSize(nBox) - 1 do
            local tData = DataModel.tAllItemLIst[nBox][index]
            if fnFilter(tData.hItem) then
                table.insert(tRes, tData)
            end
        end
    end
    return tRes
end

---@class UIBagViewNew
local UIBagViewNew = class("UIBagViewNew")
local BAG_VIEW_TYPE = {
    ALL = 1,
    TYPE = 2,
    TOY = 3
}

local BATCH_TYPE = {
    Destroy = 1,
    Sell = 2,
    WareHouse = 3,
    Break = 4,
    Lock = 5,
}

local tErrorMsg = {
    [BATCH_TYPE.Sell] = "该物品无法被出售",
    [BATCH_TYPE.WareHouse] = "该物品无法被放入仓库",
    [BATCH_TYPE.Break] = "该物品无法被拆解",
    [BATCH_TYPE.Lock] = "该格子无法被锁定",
}
local tBtnConfirmStr = {
    [BATCH_TYPE.Destroy] = "全部丢弃",
    [BATCH_TYPE.WareHouse] = "全部存储",
    [BATCH_TYPE.Break] = "全部拆解",
    [BATCH_TYPE.Lock] = "确认设置",
}

local tSliderStr = {
    [BATCH_TYPE.Destroy] = g_tStrings.STR_DISCARD_COUNT,
    [BATCH_TYPE.WareHouse] = "存储数量：",
    [BATCH_TYPE.Break] = "拆解数量：",
    [BATCH_TYPE.Lock] = "锁定数量：",
}

local m_szMark = "bag"
local MAX_BRAEK_EQUIP_COUNT = 10

local ITEM_DRAG_ACC = -0.1
local TIME_TO_MAX_SPEED = 2
local STANDARD_MOVE_SPEED = 10
local MAX_INCREMENT_SPEED = 30
local nItemCountOfEachRow = 5
local nTimeLimitedIndex = 12

function UIBagViewNew:OnEnter(nFirstSelectId)
    self.nFirstSelectId = nFirstSelectId
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self:InitMainFilter()
        self.bInit = true
        self.bShowMore = false
        self.tbMoved = {}
        self:InitScrollList()
        UIHelper.SetParent(self.WidgetTipForWarehouse, UIHelper.GetParent(self._rootNode))
    end

    DataModel.RefreshAll()

    DataModel.nFilterClass = -1
    DataModel.nFilterSub = 0
    DataModel.nFilterTag = 0

    self.bBatchType = BATCH_TYPE.Destroy
    self.bBatchSelect = false
    self.bCompareBank = false
    self.tbSelected = { dwItemID = nil, tbPos = { nBox = nil, nIndex = nil }, tbBatch = nil }
    self.nAdditionalFilterTab = 1
    self.nPVPType = 1
    self.szItemNameFilter = nil
    self.tbBox = {}
    self.tbBagDataList = {}
    self.scriptItemTip = nil
    self.scriptToyItemTip = nil
    self.scriptItemLinkTip = nil
    self.bUpdatingCell = false
    self.WidgetCard = self.WidgetTipNormal
    self.nOriginalScrollListHeight = UIHelper.GetHeight(self.WidgetScrollListParent)
    CurrencyData.bCurrentBagView = true

    self.tbPVPFilter = PVP_FILTER_TABLE
    self.tbNameFilter = function(item)
        if not self.szItemNameFilter then
            return true
        end

        if not item then
            return false
        end

        if item and not IsString(item) then
            local szType = ItemData.GetItemTypeInfoDesc(item, true)
            if szType and string.find(szType, self.szItemNameFilter) then
                return true
            end

            local szItemDesc = ItemData.GetItemDesc(item.nUiId)
            if szItemDesc and string.find(szItemDesc, self.szItemNameFilterUTF8) then
                return true
            end
        end

        local szName = item
        if not IsString(szName) then
            szName = ItemData.GetItemNameByItem(item)
        end

        return string.find(szName, self.szItemNameFilter)
    end

    ToyBoxData.Init()
    ToyBoxData.ResetFilter()

    local tbFilterDefSelected = FilterDef.Bag.tbRuntime
    if tbFilterDefSelected then
        tbFilterDefSelected[1][1] = 1
        tbFilterDefSelected[2][1] = 1
    end

    local tbFilterToySelected = FilterDef.ToyBox.tbRuntime
    if tbFilterToySelected then
        tbFilterToySelected[1] = clone(FilterDef.ToyBox[1].tbDefault)
        tbFilterToySelected[2] = clone(FilterDef.ToyBox[2].tbDefault)
        tbFilterToySelected[3] = clone(FilterDef.ToyBox[3].tbDefault)
    end

    self.nBagScreen = ITEM_SCREEN.ALL
    self.nBagViewType = BAG_VIEW_TYPE.ALL

    -- 某些特殊玩法中，仅显示 全部 tab
    if NeedUseTravellingBag() then
        for idx, comp in ipairs(self.ToggleGroupTab) do
            if idx ~= 1 then
                UIHelper.SetVisible(comp, false)
            end
        end
    end

    UIHelper.SetVisible(self.WidgetMoneyList, Storage.Bag.bShowMoneyList) -- 还原上次关闭背包时列表状态
    UIHelper.SetSelected(self.BtnMoneySetting, Storage.Bag.bShowMoneyList) -- 还原上次关闭背包时列表状态

    self:UpdateBagSize()
    self:UpdateWareHouseExpire()
    self:UpdateCoinAndMoney()
    self:UpdateEmptyWidget()
    self:InitEquipPageInfo()
    self:AdjustTipsPos()
    self:SetupArrow()

    RedpointMgr.RegisterRedpoint(self.ImgRedPoint, nil, { 1601 })

    OpenShopRequest(1232, 0)

    Event.Dispatch(EventType.OnBagViewOpen)
end

function UIBagViewNew:OnExit()
    self.bInit = false
    self:CancelBatch()

    self:UnInitScrollList()
    self:UnRegEvent()

    ToyBoxData.UnInit()
    if UIMgr.IsViewOpened(VIEW_ID.PanelHalfWarehouse) then
        UIMgr.Close(VIEW_ID.PanelHalfWarehouse)
        self:ExitWareHouseState()
    end

    UIHelper.RemoveFromParent(self.WidgetTipForWarehouse, true)

    CurrencyData.bCurrentBagView = false
    Storage.Bag.bShowMoneyList = UIHelper.GetVisible(self.WidgetMoneyList) -- 记录货币列表是否打开
    BagViewData.ClearNewItem()
end

function UIBagViewNew:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnMoneySetting, EventType.OnClick, function()
        local bShow = UIHelper.GetVisible(self.WidgetMoneyList)
        UIHelper.SetVisible(self.WidgetMoneyList, not bShow)
        UIHelper.LayoutDoLayout(self.LayoutRight)
        UIHelper.LayoutDoLayout(self.LayoutBagAndMoney)
    end)

    UIHelper.BindUIEvent(self.BtnWarehouse, EventType.OnClick, function()
        if g_pClientPlayer and g_pClientPlayer.nMoveState == 16 then
            return TipsHelper.ShowImportantYellowTip("重伤时不可使用仓库")
        end

        if g_pClientPlayer and g_pClientPlayer.nLevel >= 102 then
            if not UIMgr.IsViewOpened(VIEW_ID.PanelHalfWarehouse) then
                local scene = g_pClientPlayer.GetScene()
                local dwMapID = scene and scene.dwMapID or 0
                if dwMapID == MonsterBookData.PLAY_MAP_ID then
                    UIMgr.Open(VIEW_ID.PanelHalfWarehouse, WareHouseType.BaiZhan)
                else
                    UIMgr.Open(VIEW_ID.PanelHalfWarehouse)
                end
            end
        else
            TipsHelper.ShowNormalTip("侠士达到102级后方可开启仓库")
        end
    end)

    UIHelper.BindUIEvent(self.BtnBatchDiscard, EventType.OnClick, function()
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.BANK) or BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP, "destroy") then
            return
        end

        self.bBatchType = BATCH_TYPE.Destroy
        self:EnterBatch()
        Event.Dispatch(EventType.OnCloseItemTeach)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        self:CancelBatch()
    end)

    UIHelper.BindUIEvent(self.BtnBatchBreak, EventType.OnClick, function()
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.OPERATE_DIAMOND, "OPERATE_DIAMOND") then
            return
        end

        local player = PlayerData.GetClientPlayer()
        if player.nLevel < 110 then
            TipsHelper.ShowNormalTip("侠士达到110级后方可拆解装备")
            return
        end
        self.bBatchType = BATCH_TYPE.Break
        self:EnterBatch()
        Event.Dispatch(EventType.OnCloseItemTeach)
    end)

    UIHelper.BindUIEvent(self.BtnSellOut, EventType.OnClick, function()
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.SHOP, "sell") then
            return
        end
        self.bBatchType = BATCH_TYPE.Sell
        self:UpdateCell()
        self:EnterBatch()
        Event.Dispatch(EventType.OnCloseItemTeach)
    end)

    UIHelper.BindUIEvent(self.BtnCancelSellOut, EventType.OnClick, function()
        self:CancelBatch()
    end)

    UIHelper.BindUIEvent(self.BtnAll, EventType.OnClick, function()
        if not empty(self.tbSelected.tbBatch) then
            if PropsSort.IsBagInSort() or PropsSort.IsBankInSort() then
                TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
                return
            end
            self:ConfirmBatch()
        elseif self.bBatchType == BATCH_TYPE.Lock and (not empty(self.tbSelected.tbLock) or not empty(self.tbSelected.tbUnLock)) then
            if PropsSort.IsBagInSort() or PropsSort.IsBankInSort() then
                TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
                return
            end
            self:ConfirmBatch()
        end
    end)

    UIHelper.BindUIEvent(self.BtnSellOutAll, EventType.OnClick, function()
        if not empty(self.tbSelected.tbBatch) then
            self:ConfirmBatch()
        end
    end)

    UIHelper.BindUIEvent(self.BtnNeaten, EventType.OnClick, function()
        local bOpen = GameSettingData.GetNewValue(UISettingKey.InventorySortConfirmation)
        if bOpen then
            local script = UIHelper.ShowConfirm("是否确定整理背包？", function()
                self:Sort()
            end, nil)
            assert(script)
            script:ShowTogOption("不再提醒", false)
            script:SetTogSelectedFunc(function(bSelected)
                if bSelected then
                    TipsHelper.ShowNormalTip("后续可在设置-操作设置中进行调整。")
                    GameSettingData.StoreNewValue(UISettingKey.InventorySortConfirmation, false)
                else
                    GameSettingData.StoreNewValue(UISettingKey.InventorySortConfirmation, true)
                end
            end)
        else
            self:Sort()
        end
    end)

    UIHelper.BindUIEvent(self.BtnCombine, EventType.OnClick, function()
        ItemSort.StackItem()
    end)

    UIHelper.BindUIEvent(self.BtnBagUpgrade, EventType.OnClick, function()
        if PropsSort.IsBagInSort() then
            TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
            return
        end
        self:UpdateBagUpGradeState()
    end)

    UIHelper.BindUIEvent(self.BtnTrandingHouse, EventType.OnClick, function()
        if g_pClientPlayer and g_pClientPlayer.nLevel >= 106 then
            TradingData.InitTradingHouse()
        else
            TipsHelper.ShowNormalTip("侠士达到106级后方可开启交易行")
        end

    end)

    UIHelper.BindUIEvent(self.TogToy, EventType.OnClick, function()
        self:UpdateToyInfo()
    end)

    for nIndex, tog in ipairs(self.tbTogPreset) do
        UIHelper.SetTouchDownHideTips(tog, false)
        UIHelper.BindUIEvent(tog, EventType.OnClick, function()
            EquipData.SwitchEquip(nIndex)
            self.nCurEquipPageIndex = nIndex
            UIHelper.SetToggleGroupSelected(self.ToggleGroupPreset, self.nCurEquipPageIndex - 1)
        end)
    end

    UIHelper.BindUIEvent(self.BtnLock, EventType.OnClick, function()
        self.bBatchType = BATCH_TYPE.Lock
        self:EnterBatch()
        Event.Dispatch(EventType.OnCloseItemTeach)
    end)

    
    UIHelper.BindUIEvent(self.BtnMore, EventType.OnClick, function()
        self:SetShowMoreButtonState(not self.bShowMore)
    end)

    -- 背包格子筛选 begin ----------------------------------------------
    UIHelper.BindUIEvent(self.BtnScreen, EventType.OnClick, function(btn)
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnScreen, TipsLayoutDir.BOTTOM_CENTER, FilterDef.Bag)
    end)

    UIHelper.BindUIEvent(self.BtnToyScreen, EventType.OnClick, function(btn)
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnToyScreen, TipsLayoutDir.BOTTOM_CENTER, FilterDef.ToyBox)
    end)

    UIHelper.RegisterEditBoxChanged(self.EditKindSearch, function()
        local szText = UIHelper.GetString(self.EditKindSearch)
        self.szItemNameFilter = nil
        self.szItemNameFilterUTF8 = nil
        if szText ~= "" then
            self.szItemNameFilter = UIHelper.UTF8ToGBK(szText)
            self.szItemNameFilterUTF8 = szText
        end

        if self.nBagViewType ~= BAG_VIEW_TYPE.TOY then
            self:UpdateCell()
        else
            self:UpdateFilter(true)
        end
    end)

    UIHelper.BindUIEvent(self.TogSearch, EventType.OnSelectChanged, function(_btn, bSelected)
        if not bSelected then
            self.szItemNameFilter = nil
            self.szItemNameFilterUTF8 = nil
        else
            local szText = UIHelper.GetString(self.EditKindSearch)
            self.szItemNameFilter = nil
            self.szItemNameFilterUTF8 = nil
            if szText ~= "" then
                self.szItemNameFilter = UIHelper.UTF8ToGBK(szText)
                self.szItemNameFilterUTF8 = szText
            end
        end

        if self.nBagViewType ~= BAG_VIEW_TYPE.TOY then
            self:UpdateCell(SCROLL_LIST_UPDATE_TYPE.RESET)
        else
            self:UpdateFilter(true)
        end
    end)

    -- 背包格子筛选 end ---------------------------------------------

end

function UIBagViewNew:RegEvent()
    Event.Reg(self, "BAG_ITEM_UPDATE", function(nBox, nIndex, bNewAdd)
        --LOG.WARN("BAG_ITEM_UPDATE")

        local bIsCurSelected = false
        local item = ItemData.GetItemByPos(nBox, nIndex)
        DataModel.UpdateItemByPos(nBox, nIndex)

        if (item and item.dwID == self.tbSelected.dwItemID) or (nBox == self.tbSelected.tbPos.nBox and nIndex == self.tbSelected.tbPos.nIndex) then
            self:DoUpdateSelect(self.tbSelected.dwItemID) -- 更新选中道具详细信息
            bIsCurSelected = true
        end

        -- 更新背包格子计数（used/total）
        self:UpdateBagSize()
        self:UpdateEmptyWidget()

        local scriptCell = self:GetCellScript(nBox, nIndex) -- 更新格子
        local bShow = self:IsShow(item)
        if scriptCell and bShow then
            scriptCell:UpdateInfo()
            local bIsNewItem = BagViewData.IsNewItem(nBox, nIndex)
            local itemScript = scriptCell:GetItemScript()
            self:InitItemScript(itemScript, bIsNewItem, nBox, nIndex, item and item.dwID, bIsCurSelected)
            self:UpdateRedPointArrow()
            self:UpdateTabToggle()

            local tBagData = self.tbBagDataList[scriptCell.nDataIndex]
            if tBagData then
                tBagData.dwItemID = item and item.dwID
                tBagData.bHasItem = item ~= nil
            end
        else
            local flag = self:ShouldUpdateAllCell(nBox, nIndex, bShow)
            if flag then
                self:UpdateCell(SCROLL_LIST_UPDATE_TYPE.RELOAD)
            else
                if not PropsSort.IsBagInSort() then
                    self:RefreshDataOnly(true)  --不在显示范围内，并且不影响当前显示内容时，仅更新数据内容
                end
            end
        end

        if not self.bProcessBatch and self.bCompareBank then
            Timer.AddFrame(self, 5, function()
                ItemData.UpdateCommonItemBetweenBagAndBank() -- 延迟更新，保证数据正确性
            end)
        end
    end)

    local fnProcessBatch = function()
        if self.bBatchSelect and table.get_len(self.tbSelected.tbBatch) > 0 and self.bProcessBatch then
            self:ProcessBatch() -- 监听仓库相关的更新事件以执行批量操作，确保物品交换逻辑的正确性
        end
    end
    Event.Reg(self, "CUB_ITEM_UPDATE", fnProcessBatch)
    Event.Reg(self, "BANK_ITEM_UPDATE", fnProcessBatch)
    Event.Reg(self, "ON_ACCOUNT_SHARED_PACKAGE_UPDATE", fnProcessBatch)
    Event.Reg(self, "UPDATE_TONG_REPERTORY_PAGE", fnProcessBatch)

    Event.Reg(self, EventType.OnBagRowRecycled, function(nBox, nIndex, bIsBag)
        if bIsBag then
            self:StoreCellScript(nBox, nIndex, nil)
        end
    end)

    Event.Reg(self, EventType.OnWarehouseExpireItemUpdate, function(bShowExpireIcon)
        self:UpdateWareHouseExpire(bShowExpireIcon)
    end)

    Event.Reg(self, EventType.OnCurrencyChange, function()
        self:UpdateCoinAndMoney(true)
    end)

    Event.Reg(self, "EQUIP_ITEM_UPDATE", function(nBox, nIndex, bNewAdd)
        if table.contain_value(ItemData.SlotSet.BagSlot, nIndex) then
            self:UpdateCell()
            self:UpdateBagSize()
        end
    end)

    Event.Reg(self, "ON_UPDATE_BAGUPGRADE_STATE", function()
        if PropsSort.IsBagInSort() then
            TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
            return
        end
        self:UpdateBagUpGradeState()
    end)

    Event.Reg(self, "ON_RESIZE_PACKAGE_NOTIFY", function(dwBox, dwSize)
        if INVENTORY_INDEX.PACKAGE == dwBox then
            self:UpdateCell()
            self:UpdateBagSize()
        end
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        if self.tbSelected.dwItemID then
            UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupBag, nil)
        end

        Timer.AddFrame(self, 3, function()
            UIHelper.ScrollViewDoLayout(self.ScrollViewTypeList)
            UIHelper.ScrollViewDoLayout(self.ScrollViewChildTab)
            UIHelper.ScrollToLeft(self.ScrollViewChildTab, 0)

            if self.selectedMainTog then
                UIHelper.ScrollLocateToPreviewItem(self.ScrollViewTypeList, self.selectedMainTog, Locate.TO_CENTER)
            end

            self.nOriginalScrollListHeight = UIHelper.GetHeight(self.WidgetScrollListParent)
            self:CalculateScrollListHeight(true)
            self:CalculateItemTipParentPos()
        end)
    end)

    Event.Reg(self, EventType.OnViewMutexPlayShowAnimFinish, function(nViewID)
        if nViewID == VIEW_ID.PanelHalfBag then
            self:CalculateScrollListHeight(false)
        end
    end)

    Event.Reg(self, "DO_CUSTOM_OTACTION_PROGRESS", function(nTotalFrame, szActionName, nType)
        local bShowSystemPrograss = false   -- 如果在全屏界面使用道具出现读条，如商城中打开背包的话，使用道具的读条要接PanelSystemPrograssBar
        local tbShowView = {
            [1] = VIEW_ID.PanelExteriorMain,
        }

        if nTotalFrame and nTotalFrame > 0 then
            for _, value in pairs(tbShowView) do
                if UIMgr.IsViewOpened(value) then
                    bShowSystemPrograss = true
                    break
                end
            end
            if bShowSystemPrograss then
                local tParam = {
                    szType = "Normal",
                    szFormat = UIHelper.GBKToUTF8(szActionName),
                    nDuration = nTotalFrame / GLOBAL.GAME_FPS,
                    fnCancel = function()
                        GetClientPlayer().StopCurrentAction()
                    end
                }
                if not UIMgr.GetView(VIEW_ID.PanelSystemPrograssBar) then
                    UIMgr.Open(VIEW_ID.PanelSystemPrograssBar, tParam)  --避免和界面重复打开
                end
            end
        end
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

    Event.Reg(self, EventType.OnSceneTouchTarget, function()
        if self.scriptItemLinkTip then
            self.scriptItemLinkTip = nil
            return
        end

        if self.bTipsJustHide then
            return
        end

        if UIMgr.IsViewOpened(VIEW_ID.PanelHalfWarehouse) then
            UIMgr.Close(VIEW_ID.PanelHalfWarehouse)
            self:ExitWareHouseState()
            return
        end

        if not UIHelper.GetVisible(self._rootNode) then
            return
        end

        if self.scriptEquipedItemTip and (UIHelper.GetVisible(self.WidgetTipNowEquip) or UIHelper.GetVisible(self.WidgetTipNowEquipEmpty)) then
            UIHelper.SetVisible(self.WidgetTipNowEquip, false)
            UIHelper.SetVisible(self.WidgetTipNowEquipEmpty, false)
            UIHelper.SetVisible(self.WidgetTogPreset, false)
        end

        if self.scriptItemTip and UIHelper.GetVisible(self.scriptItemTip._rootNode) then
            UIHelper.SetVisible(self.scriptItemTip._rootNode, false)
            return
        end

        if self.scriptToyItemTip and UIHelper.GetVisible(self.scriptToyItemTip._rootNode) then
            UIHelper.SetVisible(self.scriptToyItemTip._rootNode, false)
            return
        end

        --UIMgr.Close(VIEW_ID.PanelBagUp2)
        UIMgr.Close(VIEW_ID.PanelHalfBag)
    end)

    Event.Reg(self, EventType.OnSceneTouchNothing, function()
        if self.bTipsJustHide then
            return
        end

        if self.scriptItemLinkTip then
            self.scriptItemLinkTip = nil
            return
        end

        if UIMgr.IsViewOpened(VIEW_ID.PanelHalfWarehouse) then
            UIMgr.Close(VIEW_ID.PanelHalfWarehouse)
            self:ExitWareHouseState()
            return
        end

        if not UIHelper.GetVisible(self._rootNode) then
            return
        end

        if self.scriptEquipedItemTip and (UIHelper.GetVisible(self.WidgetTipNowEquip) or UIHelper.GetVisible(self.WidgetTipNowEquipEmpty)) then
            UIHelper.SetVisible(self.WidgetTipNowEquip, false)
            UIHelper.SetVisible(self.WidgetTipNowEquipEmpty, false)
            UIHelper.SetVisible(self.WidgetTogPreset, false)
        end

        if self.scriptItemTip and UIHelper.GetVisible(self.scriptItemTip._rootNode) then
            UIHelper.SetVisible(self.scriptItemTip._rootNode, false)
            return
        end

        if self.scriptToyItemTip and UIHelper.GetVisible(self.scriptToyItemTip._rootNode) then
            UIHelper.SetVisible(self.scriptToyItemTip._rootNode, false)
            return
        end

        UIMgr.Close(VIEW_ID.PanelHalfBag)
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        if self.scriptItemLinkTip then
            self.scriptItemLinkTip = nil
            return
        end

        if self.bBatchSelect and self.scriptItemTip then
            self.scriptItemTip:OnInit()
            --self.bTipsJustHide = true
            return
        end

        if self.tbSelected.dwItemID then
            UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupBag, nil)
            --self.bTipsJustHide = true
            return
        end

        --self.bTipsJustHide = false

        if self.scriptToyItemTip then
            UIHelper.SetVisible(self.scriptToyItemTip._rootNode, false)
        end
    end)

    local tbExclusionView = {
        VIEW_ID.PanelOldDialogue,
        VIEW_ID.PanelPlotDialogue,
        --VIEW_ID.PanelBagUp2,
    }
    Event.Reg(self, EventType.OnViewOpen, function(nViewID)
        if table.contain_value(tbExclusionView, nViewID) then
            UIHelper.SetVisible(self._rootNode, false)
        end
    end)

    Event.Reg(self, EventType.OnShowIteminfoLinkTips, function(scriptTips)
        self.scriptItemLinkTip = scriptTips
    end)

    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        if table.contain_value(tbExclusionView, nViewID) then
            UIHelper.SetVisible(self._rootNode, true)
        end
    end)

    Event.Reg(self, EventType.OnUseBoxItemToOpenBox, function(nBox, nIndex)
        if not self.scriptChooseAwardType then
            self.scriptChooseAwardType = UIHelper.AddPrefab(PREFAB_ID.WidgetChooseAwardType, self.WidgetTip, nBox, nIndex)
        else
            self.scriptChooseAwardType:OnEnter(nBox, nIndex)
        end
        if self.scriptItemTip then
            UIHelper.SetVisible(self.scriptItemTip._rootNode, false)
        end
    end)

    Event.Reg(self, EventType.OnClickMultUseBtn, function(nBox, nIndex)
        local nType = BAG_VIEW_TYPE.ALL
        local scriptBottom = self:GetCellScript(nBox, nIndex, nType)
        local scriptItem = scriptBottom:GetItemScript()
        local item = ItemData.GetItemByPos(nBox, nIndex)
        local dwItemID = item.dwID
        self.tbSelected.dwItemID = dwItemID
        self.tbSelected.tbPos = { nBox = nBox, nIndex = nIndex }
        scriptItem:SetSelected(true)
    end)

    Event.Reg(self, "TRY_EXCHANGE_PACKAGE", function(dwID)
        local hItem = ItemData.GetItem(dwID)
        local tbScript = UIHelper.GetBindScript(self.WidgetBagUp)
        if tbScript:IsBoxFull() and tbScript:IsLessBag(hItem.nCurrentDurability) then
            if not UIHelper.GetVisible(self.WidgetAniBagUp) then
                UIHelper.SetVisible(self.WidgetAniBagUp, true)
                UIHelper.SetVisible(self.WidgetLowerButton, false)
                UIHelper.SetVisible(self.BtnBagUpgradeQuit, true)
                self:SetShowMoreButtonState(true)
            end
        end
        tbScript:OnEnter(dwID)
        tbScript:EquipPackage()
    end)

    Event.Reg(self, "BUFF_UPDATE", function()
        local owner, bdelete, index, cancancel, id, stacknum, endframe, binit, level, srcid, isvalid, leftframe = arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11
        if binit and id == 24692 then
            UIMgr.Close(self)
        end
        for i, v in ipairs(self.tbWaitUpdateBuffList) do
            if v.nbuff ~= 0 and v.nbuff == id then
                self.tbToyScript[self.tbWaitUpdateBuffList[i].nCellIndex]:SetRecallVisible(not bdelete)
                table.remove(self.tbWaitUpdateBuffList, i)
                break
            end
        end
    end)

    Event.Reg(self, "EQUIP_CHANGE", function(result)
        if result == ITEM_RESULT_CODE.SUCCESS and UIMgr.GetFullPageViewCount() <= 0 then
            self:InitEquipPageInfo()
            self.bChangeEquipPage = true
            self:UpdateSelectedItemDetails()
        end
    end)

    Event.Reg(self, "PLAYER_DEATH", function()
        self:ExitWareHouseState()
    end)

    Event.Reg(self, EventType.BagItemLongPress, function(_, _, _, _, itemScript)
        if not self.tbMoved.dragScript or itemScript.nBox ~= self.tbMoved.nFirstBox or itemScript.nIndex ~= self.tbMoved.nFirstIndex then
            return
        end
        self.tbMoved.bLongPress = true
        self.tScrollList:SetScrollEnabled(false)
        UIHelper.SetVisible(self.tbMoved.dragScript._rootNode, true)
    end)

    Event.Reg(self, EventType.OnFilter, function(szKey, tbSelected)
        if szKey == FilterDef.Bag.Key then
            self.nAdditionalFilterTab = ITEM_FILTER_TYPE[tbSelected[1][1]]
            self.nPVPType = tbSelected[2][1]
            self:UpdateCell(SCROLL_LIST_UPDATE_TYPE.RESET)
        end

        if szKey == FilterDef.ToyBox.Key then
            for nIndex, val in ipairs(ToyBoxData.tSelectSource) do
                ToyBoxData.tSelectSource[nIndex] = table.contain_value(tbSelected[1], nIndex)
            end
            for nIndex, val in ipairs(ToyBoxData.tSelectDLC) do
                ToyBoxData.tSelectDLC[nIndex] = table.contain_value(tbSelected[2], nIndex)
            end
            for nIndex, val in ipairs(ToyBoxData.tSelectType) do
                ToyBoxData.tSelectType[nIndex] = table.contain_value(tbSelected[3], nIndex)
            end
            self:UpdateFilter(true)
        end
        self:CheckDefaultFilter(szKey)
    end)

    Event.Reg(self, EventType.OnBankBagCompareUpdate, function()
        if self.bCompareBank then
            self:RefreshScrollList()
        end
    end)

    local nPlayerID = PlayerData.GetPlayerID()
    if not IsRemotePlayer(nPlayerID) then
        RemoteCallToServer("OnInscriptionRequest", nPlayerID)
    end

    Event.Reg(self, EventType.UpdateActionToySkillState, function()
        local tbActionToyList = ToyBoxData.GetActionToyList()
        for i = table.get_len(self.tbActionToyList), 1, -1 do
            local tbToyInfo = self.tbActionToyList[i]
            local bExist = table.contain_value(tbActionToyList, tbToyInfo.dwID)
            tbToyInfo.tbScript:SetRecallVisible(bExist)
            if not bExist then
                table.remove(self.tbActionToyList, i)
            end
        end
    end)

    -- Scrolllist 相关 begin ----------------------------------------------

    Event.Reg(self, EventType.OnUIScrollListTouchBegan, function(x, y, tScrollList)
        if self.tScrollList == tScrollList then
            if PropsSort.IsBagInSort() then
                return
            end
            self:OnItemTouchBegin(x, y)
        end
    end)

    Event.Reg(self, EventType.OnUIScrollListTouchMove, function(x, y)
        self:OnItemTouchMoved(x, y)
    end)

    Event.Reg(self, EventType.OnUIScrollListTouchEnd, function(x, y)
        self:OnItemTouchEnd(x, y)
    end)

    Event.Reg(self, EventType.OnUIScrollListAddCell, function(tScrollList)
        if self.tScrollList == tScrollList then
            self:UpdateRedPointArrow()
        end
    end)
    -- 拖动背包格子相关 end ----------------------------------------------

    Event.Reg(self, "BAG_SORT", function(bState)
        if not bState then
            self:RefreshDataOnly(true) -- 结束整理时刷新数据
        end
    end)
end

function UIBagViewNew:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIBagViewNew:SetupArrow()
    UIHelper.AddPrefab(PREFAB_ID.WidgetArrow, self.WidgetArrowParent)

    Event.Reg(self, EventType.OnWindowsMouseWheel, function()
        local nPercent = UIHelper.GetScrollPercent(self.ScrollViewTypeList)
        if nPercent >= 95 then
            self.bWidgetArrow = false
            UIHelper.SetVisible(self.WidgetArrowParent, self.bWidgetArrow)
            Event.UnReg(self, EventType.OnWindowsMouseWheel)
        end
    end)

    UIHelper.BindUIEvent(self.ScrollViewTypeList, EventType.OnScrollingScrollView, function(_, eventType)
        if eventType == ccui.ScrollviewEventType.containerMoved then
            self:UpdateWidgetArrow()
            if self.bWidgetArrow then
                local nPercent = UIHelper.GetScrollPercent(self.ScrollViewTypeList)
                if nPercent >= 95 then
                    self.bWidgetArrow = false
                    UIHelper.SetVisible(self.WidgetArrowParent, self.bWidgetArrow)
                end
            end
        end
    end)
end

function UIBagViewNew:InitMainFilter()
    self.tbMainFilterScripts = {}
    UIHelper.RemoveAllChildren(self.ScrollViewTypeList)
    UIHelper.SetToggleGroupIndex(self.TogToy, ToggleGroupIndex.AchievementAwardGather)

    local nFirstClass = Storage.Bag.nTabType and math.max(0, Storage.Bag.nTabType) or 0
    for _, i in ipairs(BAG_FILTER_ORDER) do
        local tConfig = ITEM_FILTER_SETTING[i]
        if tConfig then
            local fnSubSelected = function(toggle, bState)
                if bState then
                    if self.nBagViewType == BAG_VIEW_TYPE.TOY or i ~= DataModel.nFilterClass then
                        self:SelectItemCategory(i)
                        self.selectedMainTog = toggle
                    end
                end
            end
            local subData = { szTitle = tConfig.szName, onSelectChangeFunc = fnSubSelected }
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetBagTab, self.ScrollViewTypeList, subData)
            script.nFilterClass = i
            table.insert(self.tbMainFilterScripts, script)
            UIHelper.SetToggleGroupIndex(script.ToggleChildNavigation, ToggleGroupIndex.AchievementAwardGather)

            if i == 0 then
                self.tbTogAllScript = script
            end

            if i == nFirstClass then
                self.tbInitialTogScript = script
            end

            if i == nTimeLimitedIndex then
                self.tTimeLimitedNode = script._rootNode
            end
        end
    end

    Timer.AddFrame(self, 2, function()
        if self.nFirstSelectId then
            self:UpdateToyInfo()
        else
            if self.tbInitialTogScript then
                self.bWidgetArrow = true
                UIHelper.ScrollLocateToPreviewItem(self.ScrollViewTypeList, self.tbInitialTogScript._rootNode, Locate.TO_CENTER)  -- WidgetWarehouseChild 的应用有延迟 因此延后一帧
                UIHelper.SetSelected(self.tbInitialTogScript.ToggleChildNavigation, true, true)  -- WidgetWarehouseChild 的应用有延迟 因此延后一帧
            end
        end
    end)
end

function UIBagViewNew:SelectItemCategory(nFilterClass)
    DataModel.nFilterClass = nFilterClass
    DataModel.nFilterSub = 0
    DataModel.nFilterTag = Table_GetBigBagFilterTag(DataModel.nFilterClass)
    Storage.Bag.nTabType = nFilterClass

    self.tChildFilterScripts = {}
    local tFilterData = ITEM_FILTER_SETTING[nFilterClass]  --初始化二级分类
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
                            self:CancelBatch()
                            self:UpdateBagInfo()
                        end
                    end
                end
                local subData = { szTitle = szName, onSelectChangeFunc = fnSubSelected }
                local script = UIHelper.AddPrefab(PREFAB_ID.WidgetBagChildTab, self.ScrollViewChildTab, subData)
                UIHelper.SetToggleGroupIndex(script.ToggleChildNavigation, ToggleGroupIndex.Apprentice)
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

    UIHelper.SetVisible(self.WidgetChildTab, bHasSub)
    
    self:OnItemTouchCanceled()
    self:CalculateScrollListHeight()
    self:CancelBatch()
    self:UpdateBagInfo()
end

function UIBagViewNew:UpdateInfo()
    self:UpdateCell(SCROLL_LIST_UPDATE_TYPE.RESET)   --全部视图
    --self:UpdateTypeView()   --分类视图
    self:UpdateBagSize()
    self:UpdateCoinAndMoney()
    self:UpdateEmptyWidget()
    --self:UpdateViewTypeBtnAndScroll()
end

function UIBagViewNew:StoreCellScript(nBox, nIndex, script, nType)
    local tbList = self.tbBox

    tbList[nBox + 1] = tbList[nBox + 1] or {}
    tbList[nBox + 1][nIndex + 1] = script
end

function UIBagViewNew:GetCellScript(nBox, nIndex, nType)
    local tbList = self.tbBox

    if not tbList[nBox + 1] then
        return nil
    end

    return tbList[nBox + 1][nIndex + 1]
end

function UIBagViewNew:TraverseCellScript(func)
    for nBoxKey, tbScriptList in pairs(self.tbBox) do
        for nIndexKey, Script in pairs(tbScriptList) do
            func(Script, nBoxKey - 1, nIndexKey - 1)
        end
    end
end

function UIBagViewNew:UpdateSelectedItemDetails()
    local bHasSelected = self.tbSelected and self.tbSelected.dwItemID
    if bHasSelected and not self.scriptItemTip then
        self.scriptItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetCard)
        self.scriptItemTip:SetForbidShowEquipCompareBtn(true)
        self.scriptItemTip:ShowAuctionSellBtn(true)
        -- self.scriptItemTip:SetForbidAutoShortTip(true)
        self.scriptItemTip:SetUseItemToItemCallback(function(nBox, nIndex)
            self:ShowUseItemToItemNew(nBox, nIndex)
        end)
    end

    if self.scriptItemTip then
        self.scriptItemTip:ShowSplitWidget(false)
        self.scriptItemTip:ShowPlacementBtn(false, 0, 0)
        self.scriptItemTip:ShowSellWidget(false)
        self.scriptItemTip:ShowMulitUseWidget(false)

        if self.scriptItemTip.scriptItemIcon then
            self.scriptItemTip.scriptItemIcon:ShowEquipScoreArrow(true)
        end

        local hItem, nBox, nIndex = ItemData.GetItem(self.tbSelected.dwItemID)
        local nStackNum = ItemData.GetItemStackNum(hItem)
        local szCountTitle = tSliderStr[self.bBatchType]
        local szConfirmLabel = (self.bWareHouse and not self.bBatchSelect) and g_tStrings.tbItemString.STORE_ITEM_CONFIRM_DIALOG_BUTTON_NAME or g_tStrings.STR_DISCARD_SURE
        if hItem then
            if self.bBatchSelect and self.bBatchType == BATCH_TYPE.Sell then
                if self.scriptWidgetSellItem then
                    UIHelper.RemoveFromParent(self.scriptWidgetSellItem._rootNode, true)
                    self.scriptWidgetSellItem = nil
                end
                self.scriptWidgetSellItem = UIHelper.AddPrefab(PREFAB_ID.WidgetSellItemController, self.scriptItemTip.LayoutContentAll)
                local WidgetSellItem = self.scriptWidgetSellItem._rootNode
                self.scriptItemTip:SetFunctionButtons({})
                self.scriptItemTip:OnInit(nBox, nIndex)
                self.scriptItemTip:SetBtnState({})
                if self.scriptWidgetSellItem then
                    self.scriptWidgetSellItem:UpdateInfo(0, 1232, nBox, nIndex, self.nLastSellCount)
                    self.scriptWidgetSellItem:SetSelectChangeCallback(function(nSellCount)
                        local item = ItemData.GetItemByPos(nBox, nIndex)
                        if item and item.dwID == self.tbSelected.dwItemID and self.tbSelected.tbBatch and self.tbSelected.tbBatch[item.dwID] then
                            self.nLastSellCount = nSellCount
                            self.tbSelected.tbBatch[hItem.dwID] = self.nLastSellCount
                            Event.Dispatch(EventType.OnSetUIItemIconChoose, true, nBox, nIndex, nSellCount)
                            self:UpdateSellMoneyInfo(self.tbSelected.tbBatch)
                            if self.scriptItemTip then
                                UIHelper.SetVisible(self.scriptItemTip._rootNode, false)
                            end
                        end
                    end)
                    if nStackNum > 1 then
                        UIHelper.SetString(self.scriptWidgetSellItem.LabelConfirm, "确定")
                    else
                        UIHelper.SetVisible(self.scriptWidgetSellItem.BtnConfirm, false)
                    end
                    UIHelper.SetVisible(WidgetSellItem, true)
                end
            elseif self.bWareHouse and not self.bBatchSelect then
                self.scriptItemTip:ShowWareHouseSlider(nStackNum, nStackNum, szConfirmLabel, szCountTitle, self.tbWareHouseFunctions.OnClick)
                self.scriptItemTip:ShowWareHousePreviewSlider(hItem.dwTabType, hItem.dwIndex)
            else
                self.scriptItemTip:ShowPlacementBtn(self.bBatchSelect, nStackNum, nStackNum, szConfirmLabel, szCountTitle)
                self.scriptItemTip:SetFunctionButtons(self.bBatchSelect and {} or nil)
            end
        end

        self.scriptItemTip:OnInit(self.tbSelected.tbPos.nBox, self.tbSelected.tbPos.nIndex)
        self:InitEquippedPage(hItem, self.bBatchSelect)
        UIHelper.CascadeDoLayoutDoWidget(self.WidgetAnchorItemTip, true, true)
        self:CalculateItemTipParentPos()
    end

    if bHasSelected then
        UIMgr.Close(VIEW_ID.PanelChatSocial)
    end
end

function UIBagViewNew:UnInitScrollList()
    if self.tScrollList then
        self.tScrollList:Destroy()
        self.tScrollList = nil
    end
end

function UIBagViewNew:InitScrollList()
    self:UnInitScrollList()

    self.tScrollList = UIScrollList.Create({
        listNode = self.LayoutScrollList,
        nReboundScale = 1,
        bSlowRebound = true,
        fnGetCellType = function(nIndex)
            return PREFAB_ID.WidgetBagRow
        end,
        nSpace = 10,
        fnUpdateCell = function(cell, nIndex)
            self:UpdateBagRow(cell, nIndex)
        end,
    })
    self.tScrollList:SetScrollBarEnabled(true)
end

function UIBagViewNew:UpdateBagRow(cell, nIndex)
    if not cell then
        return
    end
    cell._keepmt = true
    cell.bIsBag = true

    local cellNodes = UIHelper.GetChildren(cell.LayoutBagItem)
    local nStartIndex = nItemCountOfEachRow * (nIndex - 1) + 1
    local nEndIndex = nItemCountOfEachRow * nIndex

    for i = nStartIndex, nEndIndex do
        local nNodeIndex = i - nStartIndex + 1
        local targetNode = cellNodes[nNodeIndex]
        local tbPos = self.tbBagDataList[i]
        if tbPos then
            local cellScript = UIHelper.GetBindScript(targetNode) or select(2, ItemData.GetBagCellPrefabPool():Allocate(cell.LayoutBagItem))
            cellScript:OnEnter(tbPos.nBox, tbPos.nIndex)
            cellScript:UpdateBagImgType(tbPos.nType)
            cellScript:SetClickCallBack(function(script)
                self:OnClickBox(tbPos, script)
            end)
            cellScript:SetLockVis(BagViewData.IsLockBox(tbPos.nBox, tbPos.nIndex))
            if self.bBatchSelect and self.bBatchType == BATCH_TYPE.Lock then
                local nSelectIndex = self:GetLockDataIndex(tbPos.nBox, tbPos.nIndex)
                cellScript:SetSelectedVis(nSelectIndex ~= nil)
            end
            cellScript.nDataIndex = i
            cellScript.bBagItem = true
            local itemScript = cellScript:GetItemScript()
            local item = ItemData.GetItemByPos(tbPos.nBox, tbPos.nIndex)
            local dwItemID = item and item.dwID
            local bIsNewItem = BagViewData.IsNewItem(tbPos.nBox, tbPos.nIndex)
            self:InitItemScript(itemScript, bIsNewItem, tbPos.nBox, tbPos.nIndex, dwItemID)
            self:StoreCellScript(tbPos.nBox, tbPos.nIndex, cellScript)
        elseif targetNode then
            ItemData.GetBagCellPrefabPool():Recycle(targetNode) -- 不存在时进行回收
        end
    end
end

function UIBagViewNew:UpdateCell(nUpdateType)
    if self.bBatchSelect then
        self.tbSelected.tbBatch = self.tbSelected.tbBatch or {}
        self.tbSelected.tbLock = self.tbSelected.tbLock or {}
        self.tbSelected.tbUnLock = self.tbSelected.tbUnLock or {}
    end

    self.bHasCell = false
    self.tbBox = {}

    self:RefreshDataOnly()
    self:RefreshScrollList(nUpdateType)

    UIHelper.SetVisible(self.WidgetEmpty, not self.bHasCell)
end

function UIBagViewNew:RefreshDataOnly(bUpdateTotal)
    self.tbBagDataList = DataModel.GetFilteredItemDataList(function(hItem)
        return self:IsShow(hItem)
    end)

    local nTotalCount = #self.tbBagDataList
    self.bHasCell = nTotalCount > 0
    self.nCountOfRow = math.ceil(nTotalCount / nItemCountOfEachRow)
    if bUpdateTotal then
        self.tScrollList:SetCellTotal(self.nCountOfRow)
    end

    self:UpdateRedPointArrow()
    self:UpdateTabToggle()
end

function UIBagViewNew:RefreshScrollList(nUpdateType)
    if not self.tScrollList then
        return
    end
    nUpdateType = nUpdateType or SCROLL_LIST_UPDATE_TYPE.RELOAD

    self.bUpdatingCell = true
    local nCountOfRow = self.nCountOfRow or 1
    local min, max = self.tScrollList:GetIndexRangeOfLoadedCells()

    if nUpdateType == SCROLL_LIST_UPDATE_TYPE.RESET then
        self.tScrollList:Reset(nCountOfRow) --完全重置，包括速度、位置
    elseif nUpdateType == SCROLL_LIST_UPDATE_TYPE.RELOAD then
        self.tScrollList:ReloadWithStartIndex(nCountOfRow, min) --刷新数量
    elseif nUpdateType == SCROLL_LIST_UPDATE_TYPE.UPDATE_CELL then
        self.tScrollList:UpdateAllCell() --仅更新当前所有的Cell
    end

    self.bUpdatingCell = false
end

function UIBagViewNew:IsShow(item)
    local bIsCommon = BagViewData.IsMatchCommon(item, DataModel.nFilterClass, DataModel.nFilterSub)
    local bMatch = bIsCommon or BagViewData.IsMatchFilter(item, DataModel.nFilterClass, DataModel.nFilterSub, DataModel.nFilterTag)
    local tbFilterCfg = ADDITIONAL_FILTER_TABLE[self.nAdditionalFilterTab]
    local tPVP = self.tbPVPFilter[self.nPVPType]

    local bShowItem = bMatch and tbFilterCfg.filterFunc(item)
    return bShowItem and tPVP.filterFunc(item) and self.tbNameFilter(item)
end

function UIBagViewNew:UpdateBagSize()
    UIHelper.SetString(self.LabelNum, string.format("(%d/%d)",
            ItemData.GetBagUsedSize(GetBoxSet()),
            ItemData.GetBagSize(GetBoxSet())
    ))
end

function UIBagViewNew:UpdateEmptyWidget()
    local nUsed = ItemData.GetBagUsedSize(GetBoxSet())
    UIHelper.SetVisible(self.WidgetSelectEmpty, nUsed == 0 and not DataModel.IsShowAll()) -- 显示空格子时候如果没有道具，右侧要显示特殊的状态
    UIHelper.SetVisible(self.TogSearch, nUsed ~= 0)
end

function UIBagViewNew:UpdateBatchSelectNum(dwItemID, bSelected)
    local nCount = 0

    local fnTraverse = function(_nBox, _nIndex, bHasItem)
        if bHasItem then
            local bBreakable = self.bBatchType == BATCH_TYPE.Break and EquipData.CanBreak(_nBox, _nIndex)
            if self.bBatchType ~= BATCH_TYPE.Break or bBreakable then
                nCount = nCount + 1
            end
        end
    end

    if self.bBatchType ~= BATCH_TYPE.Lock then
        if self.tbBagDataList then
            for i = 1, #self.tbBagDataList do
                local tData = self.tbBagDataList[i]
                fnTraverse(tData.nBox, tData.nIndex, tData.bHasItem)
            end
        end
        nCount = math.min(MAX_BRAEK_EQUIP_COUNT, nCount) -- 背包批量最大数量都限制为10
    else
        nCount = MAX_BLOCK_BOX_COUNT
    end

    local nSelectCount = self.bBatchType == BATCH_TYPE.Lock and table.get_len(self.tbSelected.tbLock) or table.get_len(self.tbSelected.tbBatch)

    self.nBatchMaxCount = nCount
    UIHelper.SetString(self.LabelSelectedNum, string.format("%d/%d",
            nSelectCount,
            nCount
    ))
    if self.bBatchType == BATCH_TYPE.Sell then
        self:UpdateSellMoneyInfo(self.tbSelected.tbBatch)
    end

    UIHelper.SetVisible(self.WidgetNum, bSelected)
    if bSelected and self.bBatchType ~= BATCH_TYPE.Lock then
        local nMaxAmount = ItemData.GetItem(dwItemID).nStackNum
        self.tbSelected.tbBatch[dwItemID] = math.min(self.tbSelected.tbBatch[dwItemID], nMaxAmount)
        self.tbSelected.tbBatch[dwItemID] = math.max(1, self.tbSelected.tbBatch[dwItemID])
        UIHelper.SetVisible(self.BtnSubtract, self.tbSelected.tbBatch[dwItemID] > 1)
        UIHelper.SetVisible(self.BtnPlus, self.tbSelected.tbBatch[dwItemID] < nMaxAmount)
    end
end

function UIBagViewNew:InitEquipPageInfo()
    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

    self.nCurEquipPageIndex = player.GetEquipIDArray(INVENTORY_INDEX.EQUIP) + 1
    UIHelper.SetToggleGroupSelected(self.ToggleGroupPreset, self.nCurEquipPageIndex - 1)
end

function UIBagViewNew:UpdateCoinAndMoney(bForce)
    if self.bUpdateCoinAndMoney and not bForce then
        return
    end

    self.bUpdateCoinAndMoney = true

    UIHelper.SetOpacity(self.LayoutCurrency, 0)
    Timer.Add(self, 0.1, function()
        UIHelper.RemoveAllChildren(self.LayoutCurrency)
        local tbSelectedList = Storage.Bag.tbSelectedCurrencyNew or {}
        for nMoneyType, _ in pairs(tbSelectedList) do
            if nMoneyType == CurrencyType.Money then
                local script = UIHelper.AddPrefab(PREFAB_ID.WidgetCurrency, self.LayoutCurrency)
                script:UpdateBagMoneyInfo()
            elseif nMoneyType == CurrencyType.Coin then
                local bShowRecharge = Platform.IsWindows() or (Platform.IsAndroid() and not Channel.Is_dylianyunyun())
                UIHelper.AddPrefab(PREFAB_ID.WidgetCoin, self.LayoutCurrency, CurrencyType.Coin, false, nil, bShowRecharge)
            else
                local script = UIHelper.AddPrefab(PREFAB_ID.WidgetOtherCurrency, self.LayoutCurrency)
                script:SetCurrencyType(nMoneyType)
                script:HandleEvent()
            end
        end
        UIHelper.CascadeDoLayoutDoWidget(self.LayoutCurrency, true, true)
    end)
    Timer.Add(self, 0.2, function()
        UIHelper.SetOpacity(self.LayoutCurrency, 255)
    end)
end

function UIBagViewNew:DoUpdateSelect(dwItemID)
    self.tbSelected.dwItemID = dwItemID

    if self.tbSelected.dwItemID then
        local nBox, nIndex = ItemData.GetItemPos(self.tbSelected.dwItemID)
        if not nBox or not table.contain_value(GetBoxSet(), nBox) then
            -- 如果选中道具已经不在背包中
            local item = ItemData.GetItemByPos(self.tbSelected.tbPos.nBox, self.tbSelected.tbPos.nIndex) -- 用选中的格子信息找到新的选中道具
            if item then
                self.tbSelected.dwItemID = item.dwID
            else
                -- 选中的格子中页没有新的道具，无选中
                self.tbSelected.dwItemID = nil
                self.tbSelected.tbPos = { nBox = nil, nIndex = nil }
            end
        else
            self.tbSelected.tbPos = { nBox = nBox, nIndex = nIndex }
        end
    else
        self.tbSelected.tbPos = { nBox = nil, nIndex = nil }
    end
    self.bChangeEquipPage = false
    self:UpdateSelectedItemDetails()
end

function UIBagViewNew:OnItemSelectChange(dwItemID, bSelected)
    if self.bUpdatingCell then
        return -- 非点击触发时忽略callback
    end

    if bSelected then
        self:DoUpdateSelect(dwItemID)
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

            if self.bBatchType == BATCH_TYPE.Lock then
                fnDeselect()
                self:DoUpdateSelect(nil)
                return
            end

            local bNotSellable = self.bBatchType == BATCH_TYPE.Sell and not hItem.bCanTrade
            local bNotWareHouseOperation = self.bBatchType == BATCH_TYPE.WareHouse and self.tbWareHouseFunctions.fnValid and not self.tbWareHouseFunctions.fnValid(nBox, nIndex)
            local bNotBreakable = self.bBatchType == BATCH_TYPE.Break and not EquipData.CanBreak(nBox, nIndex)

            if bNotSellable or bNotWareHouseOperation or bNotBreakable then
                fnDeselect()
                local szMsg = tErrorMsg[self.bBatchType]
                TipsHelper.ShowNormalTip(szMsg)
                self:DoUpdateSelect(nil)
                return
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
        if self.bBatchSelect then
            self.tbSelected.tbBatch[dwItemID] = nil

            local nBox, nIndex = ItemData.GetItemPos(dwItemID)
            if nBox and nIndex then
                Event.Dispatch(EventType.OnSetUIItemIconChoose, false, nBox, nIndex, 0)
            end
        end
    end

    if self.bBatchSelect then
        self:RemoveNewItemFlag(dwItemID) -- 非Batch状态下的新状态移除在OnItemTouchBegin调用
    end

    if self.bBatchSelect then
        self:UpdateBatchSelectNum(dwItemID, bSelected)
    end
    --self:UpdateSelectedItemDetails()
end

function UIBagViewNew:OnClickBox(tbPos, scriptCell)
    if not tbPos or not scriptCell then
        return
    end

    if self.bBatchSelect and self.bBatchType == BATCH_TYPE.Lock then
        local nIndex = self:GetLockDataIndex(tbPos.nBox, tbPos.nIndex)
        if not nIndex then--选中

            if #self.tbSelected.tbLock >= self.nBatchMaxCount then
                TipsHelper.ShowImportantRedTip("已达最大锁定数目")
                return
            end
            table.insert(self.tbSelected.tbLock, { nBox = tbPos.nBox, nIndex = tbPos.nIndex })
            scriptCell:SetSelectedVis(true)

        else--取消选中

            table.remove(self.tbSelected.tbLock, nIndex)
            if BagViewData.IsLockBox(tbPos.nBox, tbPos.nIndex) and not self:GetUnLockDataIndex(tbPos.nBox, tbPos.nIndex) then
                table.insert(self.tbSelected.tbUnLock, { nBox = tbPos.nBox, nIndex = tbPos.nIndex })
            end
            scriptCell:SetSelectedVis(false)

        end
        self:UpdateBatchSelectNum(nil, nIndex == nil)
    end
end

function UIBagViewNew:GetLockDataIndex(nBox, nIndex)
    if not self.tbSelected.tbLock then
        return
    end
    for index, tbInfo in pairs(self.tbSelected.tbLock) do
        if tbInfo.nBox == nBox and tbInfo.nIndex == nIndex then
            return index
        end
    end
    return
end

function UIBagViewNew:GetUnLockDataIndex(nBox, nIndex)
    if not self.tbSelected.tbUnLock then
        return
    end
    for index, tbInfo in pairs(self.tbSelected.tbUnLock) do
        if tbInfo.nBox == nBox and tbInfo.nIndex == nIndex then
            return index
        end
    end
    return
end

function UIBagViewNew:RemoveNewItemFlag(dwItemID)
    local nBox, nIndex = ItemData.GetItemPos(dwItemID)
    if not nBox then
        return
    end
    BagViewData.RecordNewItem(nBox .. "_" .. nIndex, dwItemID, false)

    local function RemoveItemFlag(scriptCell)
        if scriptCell then
            local itemScript = scriptCell:GetItemScript()
            if itemScript and itemScript.bIsNewItem then
                itemScript.bIsNewItem = false
                itemScript:SetNewItemFlag(false)
                self:UpdateTabToggle()
            end
        end
    end
    local scriptAllCell = self:GetCellScript(nBox, nIndex, BAG_VIEW_TYPE.ALL)
    local scriptTypeCell = self:GetCellScript(nBox, nIndex, BAG_VIEW_TYPE.TYPE)
    RemoveItemFlag(scriptAllCell)
    RemoveItemFlag(scriptTypeCell)
end

function UIBagViewNew:ShowUseItemToItem(nBox, nIndex)
    local toItemScript = UIHelper.GetBindScript(self.WidgetUseItemToItem)
    if not toItemScript then
        return
    end

    toItemScript:SetCloseCallback(function()
        UIHelper.SetVisible(self.scriptItemTip._rootNode, true)
        UIHelper.SetVisible(self.WidgetUseItemToItem, false)
        self:UpdateSelectedItemDetails()
    end)
    toItemScript:OnEnter(nBox, nIndex, function(dwTargetBox, dwTargetX)
        local item = ItemData.GetPlayerItem(g_pClientPlayer, dwTargetBox, dwTargetX)
        if item.nGenre ~= ITEM_GENRE.TASK_ITEM and BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP) then
            return
        end

        ItemData.UseItemToItem(nBox, nIndex, dwTargetBox, dwTargetX)
    end)

    UIHelper.SetVisible(self.WidgetUseItemToItem, true)
    UIHelper.SetVisible(self.scriptItemTip._rootNode, false)
end

function UIBagViewNew:ShowUseItemToItemNew(nBox, nIndex)
    local script = UIMgr.Open(VIEW_ID.PanelRightBag)
    script:OnInitUseItem(nBox, nIndex, function(dwTargetBox, dwTargetX)
        local item = ItemData.GetPlayerItem(g_pClientPlayer, dwTargetBox, dwTargetX)
        if item.nGenre ~= ITEM_GENRE.TASK_ITEM and BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP) then
            return
        end

        ItemData.UseItemToItem(nBox, nIndex, dwTargetBox, dwTargetX)
    end)

    -- UIMgr.Close(VIEW_ID.PanelHalfBag)
end

function UIBagViewNew:InitEquippedPage(hItem, bForbidShow)
    if bForbidShow or not hItem or self.bWareHouse then
        UIHelper.SetVisible(self.WidgetTipNowEquip, false)
        UIHelper.SetVisible(self.WidgetTipNowEquipEmpty, not not self.bChangeEquipPage)
        UIHelper.SetVisible(self.WidgetTogPreset, not not self.bChangeEquipPage)
        return
    end
    local item = hItem
    local nEquipIndex = EquipData.GetEquipInventory(item.nSub, item.nDetail)
    if not item or item.nGenre ~= ITEM_GENRE.EQUIPMENT or not nEquipIndex then
        UIHelper.SetVisible(self.WidgetTipNowEquip, false)
        UIHelper.SetVisible(self.WidgetTipNowEquipEmpty, not not self.bChangeEquipPage)
        UIHelper.SetVisible(self.WidgetTogPreset, not not self.bChangeEquipPage)
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

    local bIsMasterEquipMap = false
    local player = PlayerData.GetClientPlayer()
    if player then
        local dwMapID = player.GetMapID()
        bIsMasterEquipMap = IsMasterEquipMap(dwMapID)
    end

    if self.scriptEquipedItemTip and hEquipedItem and not bIsMasterEquipMap then
        self.scriptEquipedItemTip:OnInit(INVENTORY_INDEX.EQUIP, nEquipIndex)
        self.scriptEquipedItemTip:ShowCurEquipImg(true)
        UIHelper.SetVisible(self.WidgetTogPreset, true)
        UIHelper.SetVisible(self.WidgetTipNowEquip, true)
        UIHelper.SetVisible(self.WidgetTipNowEquipEmpty, false)
        self.scriptEquipedItemTip:UpdateScrollViewHeight(480)
        self.scriptItemTip:UpdateScrollViewHeight(480)
    else
        UIHelper.SetVisible(self.WidgetTipNowEquip, false)
        UIHelper.SetVisible(self.WidgetTipNowEquipEmpty, not not self.bChangeEquipPage)
        UIHelper.SetVisible(self.WidgetTogPreset, not not self.bChangeEquipPage)
    end
end

function UIBagViewNew:InitLockBox()
    if self.bBatchSelect and self.bBatchType == BATCH_TYPE.Lock then
        self.tbSelected.tbLock = {}
        self.tbSelected.tbUnLock = {}
        BagViewData.UpdateLockBoxData()
        local tbLockBoxMap = BagViewData.GetLockBoxMap()
        if tbLockBoxMap then
            for nBox, tbList in pairs(tbLockBoxMap) do
                for nIndex, bLock in pairs(tbList) do
                    if bLock then
                        table.insert(self.tbSelected.tbLock, { nBox = nBox, nIndex = nIndex })
                    end
                end
            end
        end
    end
end

function UIBagViewNew:EnterBatch()
    if not self.bBatchSelect then
        if UIHelper.GetVisible(self.WidgetAniBagUp) then
            UIHelper.SetVisible(self.WidgetAniBagUp, false) -- 关闭扩容界面
        end
        self:DeselectAll()
        self.nBatchMaxCount = 0
        self.bBatchSelect = true
        UIHelper.SetVisible(self.WidgetBagTittle, not self.bBatchSelect)
        self.tbSelected.tbBatch = self.tbSelected.tbBatch or {}
        self:InitLockBox()
        self:RefreshScrollList()

        self:UpdateBatchSelectNum()
        UIHelper.SetVisible(self.WidgetDiscard, self.bBatchType ~= BATCH_TYPE.Sell)
        UIHelper.SetString(self.LabelAll, tBtnConfirmStr[self.bBatchType])

        UIHelper.SetVisible(self.WidgetSellOut, self.bBatchType == BATCH_TYPE.Sell)
        UIHelper.SetVisible(self.BtnScreen, false)
        UIHelper.SetVisible(self.TogSearch, false)

        for i, comp in ipairs(self.ToggleGroupTab) do
            UIHelper.SetEnable(comp, false)
        end
    end
end

function UIBagViewNew:DeselectAll()
    self.tbSelected = { tbPos = {} }
    self:DoUpdateSelect(nil)
    Event.Dispatch(EventType.OnBoxSelectChanged, false)
end

function UIBagViewNew:CancelBatch()
    if self.bBatchSelect then
        self:DeselectAll()
        self.bBatchSelect = false
        self.bProcessBatch = false
        if self.scriptWidgetSellItem then
            UIHelper.RemoveFromParent(self.scriptWidgetSellItem._rootNode, true)
            self.scriptWidgetSellItem = nil
        end

        local traverseFunc = function(CellScript, _nBox, _nIndex)
            local ItemScript = CellScript:GetItemScript()
            if ItemScript then
                ItemScript:SetSelectMode(false, true)
                self:SetItemNodeGray(ItemScript, _nBox, _nIndex)
                Event.Dispatch(EventType.OnSetUIItemIconChoose, false, _nBox, _nIndex, 0)
            end
        end
        self:TraverseCellScript(traverseFunc)

        UIHelper.SetVisible(self.WidgetBagTittle, not self.bBatchSelect)

        UIHelper.SetVisible(self.WidgetDiscard, false)
        UIHelper.SetVisible(self.WidgetSellOut, false)
        UIHelper.SetVisible(self.BtnScreen, true)
        UIHelper.SetVisible(self.TogSearch, true)

        for i, comp in ipairs(self.ToggleGroupTab) do
            UIHelper.SetEnable(comp, true)
        end
    end
end

local QUALITY_LABEL = {
    [3] = "蓝色品质",
    [4] = "紫色品质",
    [5] = "橙色品质"
}

function UIBagViewNew:ConfirmBatch()
    if self.bBatchType == BATCH_TYPE.Break then
        local dwTabType = 5
        local tResultItem = {}
        for dwItemID, nCount in pairs(self.tbSelected.tbBatch) do
            local nBox, nIndex = ItemData.GetItemPos(dwItemID)
            local tbItemList = g_pClientPlayer.ShowBreakEquipProduct(nBox, nIndex)
            for _, tItem in ipairs(tbItemList) do
                local dw = tItem.dwTabType
                local nNewCount = (tResultItem[tItem.dwIndex] or 0) + tItem.nStackNum
                tResultItem[tItem.dwIndex] = nNewCount
            end
        end
        local tList = {}
        for dwIndex, nCount in pairs(tResultItem) do
            table.insert(tList, {
                dwIndex = dwIndex,
                nStackNum = nCount,
                dwTabType = dwTabType
            })
        end

        local nSelectNum = table.get_len(self.tbSelected.tbBatch)
        local nNeedVigor = GDAPI_BreakEquipCostVigor(nSelectNum)
        local nHaveVigor = GetPlayerVigorAndStamina(g_pClientPlayer)
        local szNeedVigor = nNeedVigor >= nHaveVigor and string.format("<color=#FF0000>%d</color>", nNeedVigor) or string.format("<color=#FFFFFF>%d</color>", nNeedVigor)
        UIHelper.ShowConfirmWithItemList(string.format(g_tStrings.tbItemString.BREAK_BATCH_CONFIRM, szNeedVigor), tList, function()
            local tSelectBreakEquip = {}
            for dwItemID, nCount in pairs(self.tbSelected.tbBatch) do
                local nBox, nIndex = ItemData.GetItemPos(dwItemID)
                if nBox and nIndex then
                    table.insert(tSelectBreakEquip, { nBox, nIndex })
                end
                -- ItemData.BreakEquip(nBox, nIndex)
            end
            ItemData.BatchBreakEquip(tSelectBreakEquip)
            self:CancelBatch()
        end)
        return
    end

    local szMsg = self.bWareHouse and g_tStrings.tbItemString.BATCH_STORE_ITEM_CONFIRM or g_tStrings.tbItemString.BATCH_DISCARD_ITEM_CONFIRM
    if self.bBatchType == BATCH_TYPE.Sell then
        local tTotalPrice = FormatMoneyTab(0)
        local nCurQuality = 0
        local szQualityTip = ""
        local szSellOutPriceTip = "当前出售价格为：%s"
        local bTimeReturn = false
        for dwItemID, nCount in pairs(self.tbSelected.tbBatch) do
            local item, nBox, nIndex = ItemData.GetItem(dwItemID)
            local nMaxCount = 1
            if item.bCanStack and item.nStackNum and item.nStackNum > 0 then
                nMaxCount = item.nStackNum
            end
            local nSinglePrice = GetShopItemSellPrice(1232, nBox, nIndex) / nMaxCount
            local tPrice = FormatMoneyTab(nSinglePrice)
            if item.nQuality > nCurQuality then
                nCurQuality = item.nQuality
            end
            if ItemData.IsCanTimeReturnItem(item) then
                bTimeReturn = true
            end
            tPrice = MoneyOptMult(tPrice, nCount)
            tTotalPrice = MoneyOptAdd(tTotalPrice, tPrice)
        end
        local szItemDesc = ""
        if nCurQuality >= 3 then
            local nDiamondR, nDiamondG, nDiamondB = GetItemFontColorByQuality(nCurQuality)
            local itemName = GetFormatText(QUALITY_LABEL[nCurQuality], nil, nDiamondR, nDiamondG, nDiamondB)
            szItemDesc = itemName
        end

        if bTimeReturn then
            if szItemDesc ~= "" then
                szItemDesc = szItemDesc .. g_tStrings.STR_PAUSE
            end
            szItemDesc = szItemDesc .. UIHelper.AttachTextColor("退货时限内", FontColorID.ImportantYellow)
        end

        if szItemDesc ~= "" then
            szQualityTip = string.format("同时出售的道具中含有%s道具，确认出售吗？", szItemDesc)
            if bTimeReturn then
                szQualityTip = szQualityTip .. "\n（精炼、附魔、熔嵌材料不退还！）"
            end
        end

        local szMoneyText = UIHelper.GetMoneyText(tTotalPrice)
        if MoneyOptCmp(tTotalPrice, 0) == 0 then
            szMoneyText = string.format("%d<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Tong' width='%d' height='%d' />", 0, 26 * 1.5, 26 * 1.5)
        end
        local bLimitGold = BubbleMsgData.GetGoldLimitState()
        if bLimitGold then
            local nLimit = 0
            local szMoneyLimit = string.format("%d<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Tong' width='%d' height='%d' />", 0, 26 * 1.5, 26 * 1.5)
            szMoneyText = szMoneyText .. "（风控" .. szMoneyLimit .. "）"
        end
        local szContent = string.format(szSellOutPriceTip, szMoneyText)
        szMsg = szQualityTip ~= "" and szContent .. "\n" .. szQualityTip or szContent
    end

    if self.bBatchType == BATCH_TYPE.Lock then
        szMsg = g_tStrings.tbBoxLockString.LOCK_COMFIRM
    end

    local confirmDialog = UIHelper.ShowConfirm(szMsg, function()
        self.bProcessBatch = true
        if self.bBatchType == BATCH_TYPE.Destroy then
            for dwItemID, dwSplitAmount in pairs(self.tbSelected.tbBatch) do
                local nBox, nIndex = ItemData.GetItemPos(dwItemID)
                ItemData.DestroyItem(nBox, nIndex, dwSplitAmount)
            end
            self:CancelBatch()
        elseif self.bBatchType == BATCH_TYPE.Sell then
            for dwItemID, dwSplitAmount in pairs(self.tbSelected.tbBatch) do
                local item, nBox, nIndex = ItemData.GetItem(dwItemID)
                SellItem(0, 1232, nBox, nIndex, dwSplitAmount)
            end
            self:CancelBatch()
        elseif self.bBatchType == BATCH_TYPE.Lock then
            for index, tbInfo in ipairs(self.tbSelected.tbUnLock) do
                BagViewData.StorageUnLock(tbInfo.nBox, tbInfo.nIndex)
            end
            for index, tbInfo in ipairs(self.tbSelected.tbLock) do
                BagViewData.StorageLock(tbInfo.nBox, tbInfo.nIndex)
            end
            self:CancelBatch()
        else
            self:ProcessBatch()
        end
    end, nil, true)

    confirmDialog:SetButtonContent("Confirm", g_tStrings.STR_HOTKEY_SURE)
end

function UIBagViewNew:ProcessBatch()
    if self.tbSelected.tbBatch and table.get_len(self.tbSelected.tbBatch) > 0 then
        for dwItemID, dwSplitAmount in pairs(self.tbSelected.tbBatch) do
            local nBox, nIndex = ItemData.GetItemPos(dwItemID)
            self.tbWareHouseFunctions.OnClick(dwSplitAmount, nBox, nIndex)
            self.tbSelected.tbBatch[dwItemID] = nil
            Event.Dispatch(EventType.OnSetUIItemIconChoose, false, nBox, nIndex, 0)
            break
        end
    end

    if self.tbSelected.tbBatch and table.get_len(self.tbSelected.tbBatch) == 0 then
        self:CancelBatch()
    end
end

function UIBagViewNew:EnterWareHouseState(tbWareHouseFunctions)
    if self.bWareHouse then
        self:ExitWareHouseState()
    end

    self.bWareHouse = true
    self.bBatchType = BATCH_TYPE.WareHouse
    self.tbWareHouseFunctions = tbWareHouseFunctions
    UIHelper.SetVisible(self.BtnBatchDiscard, false)
    UIHelper.SetVisible(self.BtnSellOut, false)
    UIHelper.SetVisible(self.BtnMore, false)
    UIHelper.LayoutDoLayout(self.LayoutBottomBtn)

    self:RefreshScrollList()

    if self.scriptItemTip then
        UIHelper.RemoveFromParent(self.scriptItemTip._rootNode, true)
    end
    UIHelper.SetLocalZOrder(self.WidgetTipForWarehouse, 10)
    self.WidgetCard = self.WidgetTipForWarehouse
    self.scriptItemTip = nil -- 移动ItemTip的位置以避免被遮挡
    self.scriptToyItemTip = nil
end

function UIBagViewNew:SetItemNodeGray(ItemScript, nBox, nIndex)
    if ItemScript and nBox and nIndex then
        local bGray = self.bWareHouse and self.tbWareHouseFunctions.fnValid and not self.tbWareHouseFunctions.fnValid(nBox, nIndex)
        if not bGray then
            local item = ItemData.GetItemByPos(nBox, nIndex)
            if item then
                if not self.bWareHouse and self.bBatchSelect then
                    local bNotSellable = self.bBatchType == BATCH_TYPE.Sell and not item.bCanTrade
                    local bNotBreakable = self.bBatchType == BATCH_TYPE.Break and not EquipData.CanBreak(nBox, nIndex)
                    bGray = bNotSellable or bNotBreakable
                end

                if not bGray and self.bCompareBank then
                    item = item or ItemData.GetItemByPos(nBox, nIndex)
                    if item then
                        bGray = not ItemData.IsCommonItemBetweenBagAndBank(item)
                    end
                end
            end
        end

        if bGray == nil then
            bGray = false
        end
        UIHelper.SetNodeGray(ItemScript.ImgIcon, bGray, true)
        UIHelper.SetOpacity(ItemScript._rootNode, not bGray and 255 or 120)
    end
end

function UIBagViewNew:ExitWareHouseState()
    if self.bWareHouse then
        self.bWareHouse = false
        self.tbWareHouseFunctions = nil
        UIHelper.SetVisible(self.BtnBatchDiscard, true)
        UIHelper.SetVisible(self.BtnSellOut, true)
        UIHelper.SetVisible(self.BtnMore, true)
        UIHelper.LayoutDoLayout(self.LayoutBottomBtn)
        self:CancelBatch()
        self:ExitCompareState()
        self:RefreshScrollList()

        if self.scriptItemTip then
            UIHelper.RemoveFromParent(self.scriptItemTip._rootNode, true)
        end
        self.WidgetCard = self.WidgetTipNormal
        self.scriptItemTip = nil
        self.scriptToyItemTip = nil

        UIHelper.CascadeDoLayoutDoWidget(self.LayoutBottomBtn, true)
    end
end

function UIBagViewNew:InitItemScript(itemScript, bIsNewItem, nBox, nIndex, dwItemID, bIsCurSelected)
    if itemScript then
        itemScript.bIsNewItem = bIsNewItem -- 用于判断新道具数量
        itemScript:EnableTimeLimitFlag(true)
        itemScript:SetSelectChangeCallback(nil)
        itemScript:SetToggleGroup(self.ToggleGroupBag)
        itemScript:SetHandleChooseEvent(true)
        itemScript:SetSelectMode(self.bBatchSelect, true)
        itemScript:SetNewItemFlag(bIsNewItem)
        itemScript:SetSelectChangeCallback(function(dwItemID, bSelected)
            self:OnItemSelectChange(dwItemID, bSelected)
            if bIsNewItem then
                self:UpdateRedPointArrow()
            end
        end)
        itemScript:EnableRightTouch(true)
        self:SetItemNodeGray(itemScript, nBox, nIndex)

        if self.bBatchSelect then
            if dwItemID and self.tbSelected.tbBatch[dwItemID] then
                itemScript:OnItemIconChoose(true, nBox, nIndex, self.tbSelected.tbBatch[dwItemID])
                itemScript:RawSetSelected(true)
            else
                itemScript:RawSetSelected(false)
            end
        elseif bIsCurSelected then
            itemScript:SetSelected(bIsCurSelected)
        end
    end
end

function UIBagViewNew:EnterCompareState()
    if not self.bCompareBank then
        ItemData.UpdateCommonItemBetweenBagAndBank()
        self.bCompareBank = true
        self:RefreshScrollList()
    end
end

function UIBagViewNew:ExitCompareState()
    if self.bCompareBank then
        self.bCompareBank = false
        self:RefreshScrollList()
    end
end

-----------------------背包红点提示--------------------------

function UIBagViewNew:UpdateWidgetArrow()
    local bHasRedPointBelow = false
    local bHasRedPointTop = false

    if not self.nScrollViewY then
        local nWorldX, nWorldY = UIHelper.ConvertToWorldSpace(self.ScrollViewTypeList, 0, 0)
        self.nScrollViewY = nWorldY
    end

    local nScrollListHeight = UIHelper.GetHeight(self.ScrollViewTypeList)
    for k, v in ipairs(self.tbMainFilterScripts) do
        if UIHelper.GetVisible(v.ImgRedpoint) then
            local nHeight = UIHelper.GetHeight(v.ImgRedpoint)
            local _nWorldX, _nWorldY = UIHelper.ConvertToWorldSpace(v.ImgRedpoint, 0, nHeight)
            if _nWorldY - self.nScrollViewY < 5 then
                bHasRedPointBelow = true
                break
            elseif _nWorldY - 5 - nHeight > self.nScrollViewY + nScrollListHeight then
                bHasRedPointTop = true
            end
        end
    end

    UIHelper.SetActiveAndCache(self, self.ImgRedPointArrowBottom, bHasRedPointBelow)
    UIHelper.SetActiveAndCache(self, self.ImgRedPointArrowTop, not bHasRedPointBelow and bHasRedPointTop)

    local _nWorldY = UIHelper.GetPositionY(self.tbMainFilterScripts[1]._rootNode)
    UIHelper.SetActiveAndCache(self, self.WidgetArrowParent, _nWorldY > nScrollListHeight and self.bWidgetArrow and not bHasRedPointBelow)
end

function UIBagViewNew:HasRedPointBelow()
    local bHasRedPointBelow = false
    local nRedPointCount = 0

    local min, max = self.tScrollList:GetIndexRangeOfLoadedCells()
    local nNotShowIndex = nItemCountOfEachRow * max + 1
    if max > 0 then
        for nIndex = nNotShowIndex, #self.tbBagDataList do
            local tData = self.tbBagDataList[nIndex]
            local bIsNewItem = tData and BagViewData.IsNewItem(tData.nBox, tData.nIndex)
            if bIsNewItem then
                nRedPointCount = nRedPointCount + 1
                bHasRedPointBelow = true
            end
        end
    end
    return bHasRedPointBelow, nRedPointCount
end

function UIBagViewNew:UpdateRedPointArrow()
    if self.nBagViewType ~= BAG_VIEW_TYPE.TOY then
        local bHasRedPointBelow, nRedPointCount = self:HasRedPointBelow()
        UIHelper.SetVisible(self.WidgetRedPointArrow, bHasRedPointBelow)
    else
        UIHelper.SetVisible(self.WidgetRedPointArrow, false)
    end
end

function UIBagViewNew:UpdateTabToggle()
    for nIndex, script in ipairs(self.tbMainFilterScripts) do
        UIHelper.SetActiveAndCache(self, script.ImgRedpoint, false)
    end

    for nIndex, script in ipairs(self.tChildFilterScripts) do
        UIHelper.SetActiveAndCache(self, script.ImgRedpoint, false)
    end

    for _, script in ipairs(self.tbMainFilterScripts) do
        local bMatch = BagViewData.IsHaveNewItem_Main(script.nFilterClass)
        if bMatch then
            UIHelper.SetActiveAndCache(self, script.ImgRedpoint, true)
            if script.nFilterClass == DataModel.nFilterClass then
                for _, childScript in ipairs(self.tChildFilterScripts) do
                    local bChildMatch = BagViewData.IsHaveNewItem_Sub(script.nFilterClass, childScript.nFilterSub)
                    if childScript.nFilterSub == 0 or bChildMatch then
                        UIHelper.SetActiveAndCache(self, childScript.ImgRedpoint, true)
                    end
                end
            end
        end
    end

    local bHasTimeLimitItem = DataModel.nTimeLimitedCount > 0

    if not bHasTimeLimitItem and DataModel.nFilterClass == nTimeLimitedIndex then
        UIHelper.SetSelected(self.tbMainFilterScripts[1].ToggleChildNavigation, true) -- 没有临期物品时分类消失
    end

    if self.tTimeLimitedNode and bHasTimeLimitItem ~= UIHelper.GetVisible(self.tTimeLimitedNode) then
        UIHelper.SetVisible(self.tTimeLimitedNode, bHasTimeLimitItem)
        UIHelper.ScrollViewDoLayout(self.ScrollViewTypeList)
        for _, script in ipairs(self.tbMainFilterScripts) do
            if script.nFilterClass == DataModel.nFilterClass then
                UIHelper.ScrollLocateToPreviewItem(self.ScrollViewTypeList, script._rootNode, Locate.TO_CENTER)
                break
            end
        end
    end

    self:UpdateWidgetArrow()
end

---------------玩具箱-----------------------
function UIBagViewNew:UpdateToyCells()
    UIHelper.SetVisible(self.LayoutRightBottom, false)
    ToyBoxData.UpdateStatus()
    self:UpdateFilter(true)
end

function UIBagViewNew:UpdateFilter(bIsHaveFilter)
    if self.nFrameCycleTimerID then
        return -- 防止重复加载
    end

    local bIsAllSele = true
    for k, v in pairs(ToyBoxData.tSelectSource) do
        if not v then
            bIsAllSele = false
        end
    end
    ToyBoxData.bSourceAll = bIsAllSele

    local bIsAllSele = true
    for k, v in pairs(ToyBoxData.tSelectDLC) do
        if not v then
            bIsAllSele = false
        end
    end
    ToyBoxData.bDLCAll = bIsAllSele

    local szText = self.szItemNameFilter or ""

    local tShowBoxInfo = ToyBoxData.GetShowBoxInfo(szText, ToyBoxData.szChooseHave)

    table.sort(tShowBoxInfo, function(a, b)
        if a.nQuality == b.nQuality then
            return a.nIcon > b.nIcon
        else
            return a.nQuality > b.nQuality
        end
    end)
    local tbNewBoxInfo = {}
    for i = table.get_len(tShowBoxInfo), 1, -1 do
        --已拥有玩具置前
        if tShowBoxInfo[i].bIsHave then
            table.insert(tbNewBoxInfo, tShowBoxInfo[i])
            table.remove(tShowBoxInfo, i)
        end
    end
    table.sort(tbNewBoxInfo, function(a, b)
        local bIsNewA = RedpointHelper.ToyBox_IsNew(a.dwID)
        local bIsNewB = RedpointHelper.ToyBox_IsNew(b.dwID)
        if bIsNewA ~= bIsNewB then
            return bIsNewA
        end

        if a.nQuality == b.nQuality then
            return a.nIcon > b.nIcon
        else
            return a.nQuality > b.nQuality
        end
    end)
    table.insert_tab(tbNewBoxInfo, tShowBoxInfo)

    self:UpdateToy(tbNewBoxInfo, bIsHaveFilter)
    --self:UpdateTitle()
end

function UIBagViewNew:UpdateToy(tShowBoxInfo, bIsHaveFilter)
    local bNoItem = table.get_len(tShowBoxInfo) == 0
    UIHelper.SetVisible(self.WidgetEmpty, bNoItem)
    UIHelper.SetVisible(self.ScrollToy, not bNoItem)
    if bNoItem then
        return
    end

    local loadIndex = 0
    local loadCount = table.get_len(tShowBoxInfo)

    UIHelper.RemoveAllChildren(self.ScrollToy)
    self.tbToyScript = {}
    local nScrollToIndex = nil
    local selectItem = nil
    self.nFrameCycleTimerID = Timer.AddFrameCycle(self, 1, function()
        for i = 1, 10, 1 do
            loadIndex = loadIndex + 1
            local boxInfo = tShowBoxInfo[loadIndex]
            if boxInfo then
                local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.ScrollToy)
                boxInfo.bShowShare = true
                UIHelper.SetSwallowTouches(itemScript.BtnRecall, true)
                boxInfo.nCellIndex = loadIndex
                if boxInfo.dwID == self.nFirstSelectId then
                    nScrollToIndex = loadIndex
                    selectItem = itemScript
                    self.nFirstSelectId = nil
                end
                if itemScript then
                    itemScript:OnInitWithIconID(boxInfo.nIcon, boxInfo.nQuality)
                    UIHelper.ToggleGroupAddToggle(self.ToggleGroupBag, itemScript.ToggleSelect)
                    itemScript:SetSelected(false)
                    itemScript:SetClickCallback(function()
                        UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupBag, itemScript.ToggleSelect)
                        self:UpdateSelectedToyDetails(boxInfo, itemScript) --打开tips
                    end)
                    if boxInfo.bIsHave then
                        itemScript:UpdateCDProgressBySkill(boxInfo.nSkillID, boxInfo.nSkillLevel)
                        local bInActionBar = ToyBoxData.IsToyInActionBar(boxInfo.dwID)
                        itemScript:SetRecallVisible(boxInfo.nbuff and GetClientPlayer().IsHaveBuff(boxInfo.nbuff, boxInfo.nbuffLevel) or bInActionBar)
                        itemScript:SetRecallCallback(function(boxInfo)
                            if ToyBoxData.IsToyInActionBar(boxInfo.dwID) then
                                ToyBoxData.RemoveActionToy(boxInfo.dwID)
                            else
                                local function fnCallBack()
                                    self:WaitUpdateBuff(boxInfo)
                                end
                                ToyBoxData.UseToySkill(boxInfo, fnCallBack)
                            end
                        end, boxInfo)

                        local bIsNew = RedpointHelper.ToyBox_IsNew(boxInfo.dwID)
                        if bIsNew then
                            itemScript:SetNewItemFlag(true)
                        end

                        if bInActionBar then
                            self:AddToActionList(boxInfo, itemScript)
                        end
                    end
                    self.tbToyScript[loadIndex] = itemScript
                    --UIHelper.SetNodeGray(itemScript._rootNode, not boxInfo.bIsHave, true)
                    UIHelper.SetNodeGray(itemScript.ImgIcon, not boxInfo.bIsHave, true)
                    UIHelper.SetOpacity(itemScript._rootNode, boxInfo.bIsHave and 255 or 120)
                end
            end

            if loadIndex == loadCount then
                Timer.DelTimer(self, self.nFrameCycleTimerID)
                self.nFrameCycleTimerID = nil

                if nScrollToIndex then
                    Timer.AddFrame(self, 1, function()
                        -- local nPercent = ((nScrollToIndex / loadCount) % 5) * 100
                        -- UIHelper.ScrollToPercent(self.ScrollToy, nPercent, 0)
                        UIHelper.ScrollLocateToPreviewItem(self.ScrollToy, selectItem._rootNode, Locate.TO_TOP)
                        UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupBag, selectItem.ToggleSelect)
                        self:UpdateSelectedToyDetails(tShowBoxInfo[nScrollToIndex])
                    end)
                end
                break
            end
        end
        UIHelper.ScrollViewDoLayout(self.ScrollToy)
        UIHelper.ScrollToTop(self.ScrollToy)
    end)
end

function UIBagViewNew:UpdateSelectedToyDetails(boxInfo, tbScript)
    --添加玩具通用提示
    if not self.scriptToyItemTip then
        self.scriptToyItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetCard)
        self.scriptToyItemTip:SetForbidShowEquipCompareBtn(false)
    end
    UIHelper.SetVisible(self.scriptToyItemTip._rootNode, true)
    self.scriptToyItemTip:OnInitOperationBoxItem(boxInfo, function(useboxInfo)
        local function fnCallBack()
            self:WaitUpdateBuff(boxInfo)
        end

        local function fnActionCallBack()
            self:AddToActionList(boxInfo, tbScript)
        end
        ToyBoxData.UseToySkill(boxInfo, fnCallBack, fnActionCallBack)
        UIHelper.SetVisible(self.scriptToyItemTip._rootNode, false)
    end)
end

function UIBagViewNew:WaitUpdateBuff(useboxInfo)
    self.tbWaitUpdateBuffList = self.tbWaitUpdateBuffList or {}
    local bIsAdd = true
    for k, v in pairs(self.tbWaitUpdateBuffList) do
        if v.nbuff == useboxInfo.nbuff then
            bIsAdd = false
            break
        end
    end
    if bIsAdd then
        table.insert(self.tbWaitUpdateBuffList, useboxInfo)
    end
end

function UIBagViewNew:AddToActionList(boxInfo, itemScript)
    self.tbActionToyList = self.tbActionToyList or {}
    table.insert(self.tbActionToyList, { dwID = boxInfo.dwID, tbScript = itemScript })
end

function UIBagViewNew:UpdateSellMoneyInfo(tbBatch)
    local tTotalPrice = FormatMoneyTab(0)
    local bLimitGold = BubbleMsgData.GetGoldLimitState()
    for dwItemID, nCount in pairs(tbBatch) do
        local item, nBox, nIndex = ItemData.GetItem(dwItemID)
        local nMaxCount = 1
        if item.bCanStack and item.nStackNum and item.nStackNum > 0 then
            nMaxCount = item.nStackNum
        end
        local nSinglePrice = GetShopItemSellPrice(1232, nBox, nIndex) / nMaxCount
        local tPrice = FormatMoneyTab(nSinglePrice)
        tPrice = MoneyOptMult(tPrice, tbBatch[item.dwID])
        tTotalPrice = MoneyOptAdd(tTotalPrice, tPrice)
    end
    local player = GetClientPlayer()
    local nBrics, nGold, nSilver, nCopper = ItemData.GoldSilverAndCopperFromtMoney(tTotalPrice)
    local currencys = { nBrics, nGold, nSilver, nCopper }
    local nMoneyIndex = 1
    local nCurrencyCount = #self.tbWidgetMoney
    for nCIndex = 1, nCurrencyCount do
        UIHelper.SetVisible(self.tbWidgetMoney[nCIndex], false)
    end
    if bLimitGold then
        currencys = { 0, 0, 0, 0 }
    end
    for nCIndex, currencyNum in ipairs(currencys) do
        if currencyNum > 0 then
            UIHelper.SetString(self.tbLabelMoney[nCIndex], tostring(currencyNum))
            UIHelper.SetVisible(self.tbWidgetMoney[nCIndex], true)
            nMoneyIndex = nMoneyIndex + 1
        end
    end
    if MoneyOptCmp(tTotalPrice, 0) == 0 or bLimitGold then
        local szMoney = bLimitGold and ("（风控）" .. tostring(0)) or tostring(0)
        UIHelper.SetString(self.tbLabelMoney[4], szMoney)
        UIHelper.SetVisible(self.tbWidgetMoney[4], true)
    end
    UIHelper.LayoutDoLayout(self.tbWidgetMoney[4])
    Timer.AddFrame(self, 1, function()
        UIHelper.LayoutDoLayout(self.LayoutSellOutCurrency)
    end)
end

function UIBagViewNew:UpdateToyInfo()
    if g_pClientPlayer and g_pClientPlayer.nLevel >= 106 then
        if self.nBagViewType ~= BAG_VIEW_TYPE.TOY then
            if not g_pClientPlayer.RemoteDataAutodownFinish() then
                OutputMessage("MSG_SYS", g_tStrings.STR_TOYBOX_ERROR_MSG)
                return
            end
            self.nBagViewType = BAG_VIEW_TYPE.TOY

            if UIHelper.GetVisible(self.WidgetAniBagUp) then
                self:UpdateBagUpGradeState()
            end
            self:CancelBatch()
            self:UpdateToyCells()
            RedpointHelper.ToyBox_ClearAll()

            UIHelper.SetVisible(self.WidgetChildTab, false)
            UIHelper.SetVisible(self.ScrollToy, true)
            UIHelper.SetVisible(self.LayoutScrollList, false)
            UIHelper.SetVisible(self.WidgetLowerButton, false)
            UIHelper.SetVisible(self.WidgetBagLabel, false)
            UIHelper.SetVisible(self.WidgetToyLabel, true)
            UIHelper.SetVisible(self.WidgetRedPointArrow, false)
            self:SetShowMoreButtonState(false)

            UIHelper.SetSelected(self.TogSearch, false)
        end
    else
        TipsHelper.ShowNormalTip("侠士达到106级后方可开启玩具箱")
    end
end

function UIBagViewNew:UpdateBagInfo()
    if self.nBagViewType == BAG_VIEW_TYPE.TOY then
        UIHelper.SetVisible(self.WidgetAniBagUp, false)
    end
    self.nBagViewType = BAG_VIEW_TYPE.ALL

    self:UpdateCell(SCROLL_LIST_UPDATE_TYPE.RESET)
    UIHelper.SetVisible(self.LayoutRightBottom, true)
    UIHelper.SetVisible(self.LabelNum, DataModel.IsShowAll())
    local szName = ITEM_FILTER_SETTING[DataModel.nFilterClass] and ITEM_FILTER_SETTING[DataModel.nFilterClass].szName or "背包"
    UIHelper.SetString(self.LabelBagName, szName)

    UIHelper.SetVisible(self.ScrollToy, false)
    UIHelper.SetVisible(self.LayoutScrollList, true)

    UIHelper.SetVisible(self.WidgetLowerButton, not UIHelper.GetVisible(self.WidgetAniBagUp))
    UIHelper.LayoutDoLayout(self.LayoutBottomBtn)
    UIHelper.SetVisible(self.WidgetBagLabel, true)
    UIHelper.SetVisible(self.WidgetToyLabel, false)
end

function UIBagViewNew:CheckDefaultFilter(szKey)
    if szKey == FilterDef.Bag.Key then
        local bBagDefault = self.nAdditionalFilterTab == 1 and self.nPVPType == 1
        UIHelper.SetSpriteFrame(self.ImgScreen, bBagDefault and ShopData.szScreenImgDefault or ShopData.szScreenImgActiving)
    elseif szKey == FilterDef.ToyBox.Key then
        local bToyDefault = true
        for nIndex, val in ipairs(ToyBoxData.tSelectSource) do
            bToyDefault = bToyDefault and val or false
        end
        for nIndex, val in ipairs(ToyBoxData.tSelectDLC) do
            bToyDefault = bToyDefault and val or false
        end
        for nIndex, val in ipairs(ToyBoxData.tSelectType) do
            bToyDefault = bToyDefault and val or false
        end
        UIHelper.SetSpriteFrame(self.ImgToyScreen, bToyDefault and ShopData.szScreenImgDefault or ShopData.szScreenImgActiving)
    end
end

function UIBagViewNew:UpdateWareHouseExpire(bShowExpireIcon)
    if bShowExpireIcon == nil then
        UIHelper.SetVisible(self.ImgTimeOut, ItemData.IsRoleWareHouseContainExpiringItem())
    else
        UIHelper.SetVisible(self.ImgTimeOut, bShowExpireIcon)
    end
end

function UIBagViewNew:ShouldUpdateAllCell(nBox, nIndex)
    if self.tbBagDataList then
        local tbFilterCfg = ADDITIONAL_FILTER_TABLE[self.nAdditionalFilterTab]
        local tPVP = self.tbPVPFilter[self.nPVPType]
        if DataModel.IsShowAll() and tbFilterCfg.bShowEmptyCell and tPVP.bShowEmptyCell and not self.szItemNameFilter then
            return false  -- 展示所有格子的情况下必定不需要刷新所有CELL
        end

        local min, max = self.tScrollList:GetIndexRangeOfLoadedCells()
        local nStartIndex = (min - 1) * nItemCountOfEachRow + 1
        local nEndIndex = math.min(max * nItemCountOfEachRow, #self.tbBagDataList)

        local tStartData = self.tbBagDataList[nStartIndex]
        local tEndData = self.tbBagDataList[nEndIndex]

        if not tEndData or not tStartData then
            return true
        end

        local bBelow = tEndData and nBox > tEndData.nBox or (nBox == tEndData.nBox and nIndex > tEndData.nIndex)
        local bFull = nEndIndex >= max * nItemCountOfEachRow
        return not (bBelow and bFull) -- 只有当被更新的格子在当前展示格子的下方，且当前页面已满时 才不需要刷新页面
    end
end

-- 拖动背包格子相关 begin----------------------------------------------
-- self.tbMoved = {
--     tbBagCell = 所有的cellscript,
--     bTouchItem = 左键点击开始时是否有物品,
--     clickScript = 当前click的cellscript,
--     dragScript = 拖动显示的script,
--     nFirstIndex = 交换的第一个index,
--     nSecondIndex = 交换的第二个index,
--     changeNode = 要交换的道具,
--     bSetOpacity = 要交换的道具是否设置透明度,
-- }

local function JudgeInNode(x, y, node)
    if not x or not y then
        return false
    end

    local nXmin, nXMax, nYMin, nYMax = UIHelper.GetNodeEdgeXY(node)
    if nXmin and nXMax and nYMin and nYMax then
        if x >= nXmin and x <= nXMax and y >= nYMin and y <= nYMax then
            return true
        else
            return false
        end
    else
        return false
    end
    -- print("*****************************"  .. nXMin .. "," .. nXMax .. "," .. nYMin .. "," .. nYMax)
end

function UIBagViewNew:GetScrollListItems()
    -- 取代原self.tbMoved.tbBagCell，避免快速拖动时发生scrolllist节点和缓存节点不同步导致safe_check无法通过的问题
    local tbScripts = {}
    if not self.tScrollList or not self.tScrollList.m then
        return tbScripts
    end

    self.tbMoved.wareHouseCells = WarehouseData and WarehouseData.GetWareHouseCells() or {}
    self.tbMoved.bagCells = self.tScrollList.m.tCells

    local tCells = {}
    table.insert_tab_pairs(tCells, self.tbMoved.bagCells)
    table.insert_tab_pairs(tCells, self.tbMoved.wareHouseCells)
    for _, script in pairs(tCells) do
        local tbItems = UIHelper.GetChildren(script.LayoutBagItem)
        for _, node in ipairs(tbItems) do
            local scriptCell = UIHelper.GetBindScript(node)
            table.insert(tbScripts, scriptCell)
        end
    end

    return tbScripts
end

function UIBagViewNew:OnItemTouchBegin(x, y)
    self:ClearMovedParam()
    if self.bBatchSelect or (WarehouseData and WarehouseData.bBatchSelect) then
        return
    end
    
    self.tbMoved.nFinalX, self.tbMoved.nFinalY = x, y
    for _, cellScript in ipairs(self:GetScrollListItems()) do
        if JudgeInNode(x, y, cellScript._rootNode) then
            local item = ItemData.GetPlayerItem(g_pClientPlayer, cellScript.nBox, cellScript.nIndex)
            if item then
                self.tbMoved.bTouchItem = true

                self.tbMoved.nFirstBox = cellScript.nBox
                self.tbMoved.nFirstIndex = cellScript.nIndex
                self.tbMoved.clickScript = cellScript
                self.tbMoved.changeNode = cellScript._rootNode
                self.tbMoved.originalItemScript = cellScript:GetItemScript()
                
                self.tbMoved.dragScript = self.tbMoved.dragScript or UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.WidgetTipForWarehouse)
                self.tbMoved.dragScript:OnInit(cellScript.nBox, cellScript.nIndex)
                UIHelper.SetScale(self.tbMoved.dragScript._rootNode, 0.5, 0.5)
                local nLocalX, nLocalY = UIHelper.ConvertToNodeSpace(self.WidgetTipForWarehouse, x, y)
                UIHelper.SetPosition(self.tbMoved.dragScript._rootNode, nLocalX, nLocalY, self.WidgetTipForWarehouse)
                UIHelper.SetVisible(self.tbMoved.dragScript._rootNode, false)

                self:RemoveNewItemFlag(item.dwID)
            end

            -- print("begin===================" .. cellScript.nIndex)
            return
        end
    end
end

function UIBagViewNew:OnItemTouchMoved(x, y)
    if not self.tbMoved.bTouchItem or not self.tbMoved.bLongPress then
        return
    end

    local nBox = self.tbMoved.originalItemScript.nBox
    local nIndex = self.tbMoved.originalItemScript.nIndex
    local bSetOpacity = false
    if nBox == self.tbMoved.nFirstBox and nIndex == self.tbMoved.nFirstIndex then
        bSetOpacity = true
    end
    UIHelper.SetVisible(self.tbMoved.originalItemScript.WidgetDownloadShell, bSetOpacity)

    self.tbMoved.nFinalX, self.tbMoved.nFinalY = x, y
    if self.tbMoved.dragScript then
        local nLocalX, nLocalY = UIHelper.ConvertToNodeSpace(self.WidgetTipForWarehouse, x, y)  -- 鼠标跟点画image
        UIHelper.SetPosition(self.tbMoved.dragScript._rootNode, nLocalX, nLocalY, self.WidgetTipForWarehouse)
    end

    -- 选中格子高亮
    local bFindClickScript = false
    if self.tbMoved.clickScript then
        local cellScript = self.tbMoved.clickScript
        if not JudgeInNode(x, y, cellScript._rootNode) then
            self.tbMoved.clickScript = nil
            UIHelper.SetVisible(cellScript.ImgSelect, false)
        end
    end

    if not bFindClickScript then
        for _, cellScript in ipairs(self:GetScrollListItems()) do
            if JudgeInNode(x, y, cellScript._rootNode) then
                -- print("moved===================" .. cellScript.nIndex)
                self.tbMoved.clickScript = cellScript
                UIHelper.SetVisible(cellScript.ImgSelect, true)
                bFindClickScript = true
                break
            end
        end
    end

    if not JudgeInNode(x, y, self.LayoutScrollList) then
        if JudgeInNode(x, y, self.AutoDown) then
            self:AutoScrollUpdate(true, -1)
        elseif JudgeInNode(x, y, self.AutoUp) then
            self:AutoScrollUpdate(true, 1)
        else
            self:AutoScrollUpdate(false)
        end
    else
        self:AutoScrollUpdate(false)
    end
end

function UIBagViewNew:OnItemTouchEnd()
    if not self.tbMoved.bTouchItem or not self.tbMoved.bLongPress or not self.tbMoved.nFinalX or not self.tbMoved.nFinalY then
        return
    end
    
    local x, y = self.tbMoved.nFinalX, self.tbMoved.nFinalY
    local bFound = false
    local nSecondBox, nSecondIndex, bBagItem
    if self.tbMoved.clickScript then
        local cellScript = self.tbMoved.clickScript
        if JudgeInNode(x, y, cellScript._rootNode) then
            nSecondBox = cellScript.nBox
            nSecondIndex = cellScript.nIndex
            bBagItem = cellScript.bBagItem
            bFound = true
        end
    end

    if bFound and self.tbMoved.nFirstIndex and nSecondIndex then
        if self.tbMoved.nFirstBox ~= nSecondBox or self.tbMoved.nFirstIndex ~= nSecondIndex then

            if PropsSort.IsBagInSort() then
                TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
                return
            end

            local item = ItemData.GetPlayerItem(g_pClientPlayer, nSecondBox, nSecondIndex)
            if item then
                self:RemoveNewItemFlag(item.dwID)
            end

            if not bBagItem and WarehouseData and WarehouseData.szWareHouseType == WareHouseType.Account then
                ItemData.PutItemToAccountSharedPackage(self.tbMoved.nFirstBox, self.tbMoved.nFirstIndex, nSecondBox, nSecondIndex)
            else
                ItemData.OnExchangeItem(self.tbMoved.nFirstBox, self.tbMoved.nFirstIndex, nSecondBox, nSecondIndex)
            end
        end
    end
    
    self:ClearMovedParam()
end

-- end不在ScrollBag范围内的
function UIBagViewNew:OnItemTouchCanceled()
    if not self.tbMoved.bTouchItem or not self.tbMoved.bLongPress then
        return
    end
    
    self:ClearMovedParam()
end

function UIBagViewNew:ClearMovedParam()
    local drag = self.tbMoved.dragScript

    if self.tbMoved.originalItemScript then
        UIHelper.SetVisible(self.tbMoved.originalItemScript.WidgetDownloadShell, false)
        self.tbMoved.originalItemScript:ClearLongPressState()
    end

    if self.tbMoved.clickScript then
        UIHelper.SetVisible(self.tbMoved.clickScript.ImgSelect, false)
    end

    if drag then
        UIHelper.SetVisible(drag._rootNode, false)
    end

    if self.tbMoved.nScrollTime then
        Timer.DelTimer(self, self.tbMoved.nScrollTime)
        self.tbMoved.nScrollTime = nil
    end

    self.tScrollList:SetScrollEnabled(true)
    self.tbMoved = { dragScript = drag }
end

local function _GetScorllSpeed(nStayTime, nFpsLimit)
    nFpsLimit = nFpsLimit or GetFpsLimit()
    nStayTime = nStayTime or 0
    local nDelta = STANDARD_MOVE_SPEED + MAX_INCREMENT_SPEED / (1 + math.exp(ITEM_DRAG_ACC * (nStayTime - nFpsLimit * TIME_TO_MAX_SPEED)))
    return nDelta
end

function UIBagViewNew:AutoScrollUpdate(bMove, direction)
    if bMove and not self.tbMoved.bEnterMove and self.tScrollList:_IsCanDrag() then
        if self.tbMoved.nScrollTime then
            Timer.DelTimer(self, self.tbMoved.nScrollTime)
            self.tbMoved.nScrollTime = nil
        end
        local nStayTime = 0
        local nFpsLimit = GetFPS()
        self.tbMoved.nScrollTime = Timer.AddFrameCycle(self, 1, function()
            if self.tScrollList:GetPercentage() <= 1.2 then
                local nDelta = _GetScorllSpeed(nStayTime, nFpsLimit) * direction
                self.tScrollList:_SetContentPosWithOffset(nDelta, false)
                nStayTime = nStayTime + 1
            end
        end)
        self.tbMoved.bEnterMove = true
    elseif not bMove then
        self.tScrollList:SetScrollEnabled(false)
        self.tbMoved.bEnterMove = false
        if self.tbMoved.nScrollTime then
            Timer.DelTimer(self, self.tbMoved.nScrollTime)
            self.tbMoved.nScrollTime = nil
        end
    end
end

function UIBagViewNew:CalculateScrollListHeight(bForceUpdate)
    local nChildTabHeight = 0
    if UIHelper.GetVisible(self.WidgetChildTab) then
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
        self.tScrollList:UpdateListSize()
    end

    if bForceUpdate then
        self:RefreshScrollList(SCROLL_LIST_UPDATE_TYPE.RESET)
    end
end

-- 为了让Tips动态贴近背包界面并且不产生遮挡计算 显示装备对比与否 这两种不同情况下 ItemTip父节点的最优位置
function UIBagViewNew:CalculateItemTipParentPos()
    local nSpace = 20

    local nWx, nWy = UIHelper.GetWorldPosition(self.LayoutBagAndMoney)
    local w, h = UIHelper.GetScaledContentSize(self.LayoutBagAndMoney)
    local nLeftBoarder = nWx - w

    do
        local nOriX, nOrigY = UIHelper.GetWorldPosition(self.WidgetAnchorItemTip)
        local w_node, h_node = UIHelper.GetScaledContentSize(self.WidgetAnchorItemTip)
        local nCalX = nLeftBoarder - w_node / 2
        UIHelper.SetWorldPosition(self.WidgetAnchorItemTip, nCalX, nOrigY)

        if UIHelper.GetVisible(self.WidgetTogPreset) then
            UIHelper.UpdateNodeInsideScreen(self.WidgetAnchorItemTip, nCalX, nOrigY) -- 只有显示装备对比界面时才需要确保WidgetAnchorItemTip整体都在屏幕范围内展示
        end
    end

    do
        local nOriX, nOrigY = UIHelper.GetWorldPosition(self.WidgetTipForWarehouse)
        local w_node, h_node = UIHelper.GetScaledContentSize(self.WidgetTipForWarehouse)
        local nCalX = nLeftBoarder - w_node / 2
        UIHelper.SetWorldPosition(self.WidgetTipForWarehouse, nCalX, nOrigY)
    end
end

-- 拖动背包格子相关 end ----------------------------------------------

function UIBagViewNew:UpdateBagUpGradeState()
    if self.tbSelected.dwItemID then
        UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupBag, nil)
    end

    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP) then
        return
    end

    if UIHelper.GetVisible(self.WidgetAniBagUp) then
        UIHelper.SetVisible(self.WidgetAniBagUp, false)
        UIHelper.SetVisible(self.BtnBagUpgradeQuit, false)
        UIHelper.SetVisible(self.BtnBagUpgrade, true)
        UIHelper.SetVisible(self.WidgetLowerButton, true)
        UIHelper.LayoutDoLayout(self.LayoutBottomBtn)
    else
        local tbScript = UIHelper.GetBindScript(self.WidgetBagUp)
        tbScript:OnEnter()
        UIHelper.SetVisible(self.WidgetAniBagUp, true)
        UIHelper.SetVisible(self.BtnBagUpgradeQuit, true)
        UIHelper.SetVisible(self.BtnBagUpgrade, false)
        UIHelper.SetVisible(self.WidgetLowerButton, false)
    end
end

function UIBagViewNew:AdjustTipsPos()
    local nWorldPosX = UIHelper.GetWorldPositionX(self.WidgetTipNowEquip)
    local nWidth = UIHelper.GetWidth(self.WidgetTipNowEquip)
    local nPos = nWorldPosX - nWidth / 2 - 10

    if nPos < 0 then
        UIHelper.SetPositionX(self.WidgetTipNowEquip, UIHelper.GetPositionX(self.WidgetTipNowEquip) - nPos)
        UIHelper.SetPositionX(self.WidgetTipNowEquipEmpty, UIHelper.GetPositionX(self.WidgetTipNowEquipEmpty) - nPos)
        UIHelper.SetPositionX(self.WidgetCard, UIHelper.GetPositionX(self.WidgetCard) - nPos)
        UIHelper.SetPositionX(self.WidgetTogPreset, UIHelper.GetPositionX(self.WidgetTogPreset) - nPos)
    end
end

function UIBagViewNew:Sort()
    self:OnItemTouchCanceled() -- 防止多指触控产生bug
    
    local tList = {}
    local tAllBoxList = {}

    if PropsSort.IsItemSorting(m_szMark) then
        return
    end

    local player = GetClientPlayer()
    if not player then
        return
    end

    self:ExitCompareState()
    local view = UIMgr.GetViewScript(VIEW_ID.PanelHalfWarehouse)
    if view then
        UIHelper.SetSelected(view.TogCompareBag, false)
    end

    local tbBoxSet = GetBoxSet()
    local tbItemList = ItemData.GetItemList(tbBoxSet)
    for _, tbItemInfo in ipairs(tbItemList) do
        if tbItemInfo.nBox ~= INVENTORY_INDEX.PACKAGE_MIBAO or player.CanUseMibaoPackage() then
            if player.CheckBoxCanUse(tbItemInfo.nBox) and not BagViewData.IsLockBox(tbItemInfo.nBox,tbItemInfo.nIndex) then--被锁住的格子不参与整理
                if tbItemInfo.hItem then
                    table.insert(tList, { tbItemInfo.nBox, tbItemInfo.nIndex })
                end
                table.insert(tAllBoxList, { tbItemInfo.nBox, tbItemInfo.nIndex })
            end
        end
    end

    -- 整理时，背包处于无筛选模式时对性能影响最小
    -- 在有筛选状态的时候 刷新为无筛选模式
    if not (DataModel.IsShowAll() and self.nAdditionalFilterTab == 1 and self.nPVPType == 1) then
        if self.selectedMainTog then
            UIHelper.SetSelected(self.selectedMainTog, false, false) -- 取消之前分页的选择状态
        end
        self.nAdditionalFilterTab = 1
        self.nPVPType = 1
        UIHelper.SetSelected(self.tbMainFilterScripts[1].ToggleChildNavigation, true, false) -- 应用全部分页选中状态

        self:SelectItemCategory(0)
        self:CheckDefaultFilter(FilterDef.Bag.Key)
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTypeList)
    end

    Timer.AddFrame(self, 5, function()
        BagViewData.ClearNewItem()
        PropsSort.BeginSort(tList, tAllBoxList, m_szMark)
    end)
end

-- 教学相关，根据道具ID获取道具格子的按钮并且滚动到对应位置
function UIBagViewNew:ScrollToItemAndReturnItemBtn(dwTabType, dwIndex, nBookID)
    if not self.tbBagDataList then
        return
    end

    -- 自动切换到“全部”分页
    if self.tbTogAllScript then
        self.tbInitialTogScript = self.tbTogAllScript
        UIHelper.SetSelected(self.tbTogAllScript.ToggleChildNavigation, true, true)
    else
        self:SelectItemCategory(0)
    end

    for i, tbPos in ipairs(self.tbBagDataList) do
        local hItem = ItemData.GetItemByPos(tbPos.nBox, tbPos.nIndex)
        if hItem and hItem.dwTabType == dwTabType and hItem.dwIndex == dwIndex and (not nBookID or hItem.nBookID == nBookID) then
            local nRowIndex = math.ceil(i / nItemCountOfEachRow)
            self.tScrollList:ScrollToIndexImmediately(nRowIndex)
            local cellScript = self:GetCellScript(tbPos.nBox, tbPos.nIndex)
            local itemScript = cellScript and cellScript:GetItemScript()
            return itemScript and itemScript.ToggleSelect
        end
    end
end

function UIBagViewNew:SetShowMoreButtonState(bShowMore)
    if bShowMore ~= self.bShowMore then
        self.bShowMore = bShowMore
        UIHelper.SetVisible(self.BtnLock, bShowMore)
        UIHelper.SetVisible(self.BtnBagUpgrade, bShowMore)
        UIHelper.SetVisible(self.BtnCombine, bShowMore)
        UIHelper.SetVisible(self.BtnBatchBreak, bShowMore)
        UIHelper.SetVisible(self.ImgQuit, bShowMore)

        UIHelper.SetVisible(self.BtnBatchDiscard, not bShowMore)
        UIHelper.SetVisible(self.BtnSellOut, not bShowMore)
        UIHelper.SetVisible(self.BtnNeaten, not bShowMore)
        UIHelper.SetVisible(self.LayoutBottomBtn2, not bShowMore)
        UIHelper.SetVisible(self.ImgMore, not bShowMore)

        UIHelper.LayoutDoLayout(self.LayoutBottomBtn)
    end
end

return UIBagViewNew