-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIExtractPersetMainView
-- Date: 2025-03-24 11:32:32
-- Desc: ?
-- ---------------------------------------------------------------------------------
local LEFT = 1
local RIGHT = 2
local EQUIP = 3
local REMOTE_DATA_ID = 1183
local TYPE_TO_EACH_ROW_NUM = {
    [LEFT]    = {[ExtractViewType.PersetAndWareHouse] = 4, [ExtractViewType.BagAndLoot] = 4},
    [RIGHT]   = {[ExtractViewType.PersetAndWareHouse] = 7, [ExtractViewType.BagAndLoot] = 2},
}
local TYPE_TO_TITLE = {
    [LEFT]    = {[ExtractViewType.PersetAndWareHouse] = "预设背包", [ExtractViewType.BagAndLoot] = "背包"},
    [RIGHT]   = {[ExtractViewType.PersetAndWareHouse] = "寻宝仓库", [ExtractViewType.BagAndLoot] = "拾取列表"},
    [EQUIP]   = {[ExtractViewType.PersetAndWareHouse] = "预设装备", [ExtractViewType.BagAndLoot] = "装备"},
}

local MAIN_TITLE = {
    [ExtractViewType.PersetAndWareHouse] = "寻宝仓库",
    [ExtractViewType.BagAndLoot] = "背包",
}

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

local UIExtractPersetMainView = class("UIExtractPersetMainView")

function UIExtractPersetMainView:OnEnter(nType, dwDoodadID)
    nType = nType or ExtractWareHouseData.GetExtractViewType()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nType = nType
    self.dwDoodadID = dwDoodadID or nil
    self:Init(nType)
    self:UpdateViewTypeInfo()
end

function UIExtractPersetMainView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    self:UnInitScrollList()
end

function UIExtractPersetMainView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnQuickApply, EventType.OnClick, function()
        RemoteCallToServer("On_JueJing_LastGameIni")
    end)

    UIHelper.BindUIEvent(self.BtnHorse, EventType.OnClick, function()
        self:OnShowHorse(true)
    end)

    UIHelper.BindUIEvent(self.BtnBack_Horse, EventType.OnClick, function()
        self:OnShowHorse(false)
    end)

    UIHelper.BindUIEvent(self.BtnEquipShop, EventType.OnClick, function()
        ShopData.OpenSystemShopGroup(27, 1536)
    end)

    UIHelper.BindUIEvent(self.BtnWearAll, EventType.OnClick, function()
        TravellingBagData.QuickEquipAll()
    end)

    UIHelper.BindUIEvent(self.BtnQuickWear, EventType.OnClick, function()
        RemoteCallToServer("On_JueJing_QuickEquipAuto")
    end)

    UIHelper.BindUIEvent(self.BtnSetting, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelBattleFieldPubgSetPop)
    end)

    UIHelper.BindUIEvent(self.TogSetting, EventType.OnSelectChanged, function(_, bSelected)
        self:OnShowSetting(bSelected)
    end)

    UIHelper.BindUIEvent(self.BtnSorting, EventType.OnClick, function()
        TravellingBagData.BeginSort()
    end)

    UIHelper.BindUIEvent(self.BtnSorting_Warehouse, EventType.OnClick, function()
        RemoteCallToServer("On_JueJing_TbfSort")
    end)

    UIHelper.BindUIEvent(self.BtnPowerUp, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelPowerUp)
    end)

    UIHelper.BindUIEvent(self.BtnPutIn, EventType.OnClick, function()
        ExtractWareHouseData.SaveAllToWare()
    end)

    UIHelper.BindUIEvent(self.BtnBagCoin, EventType.OnClick, function()
        UIHelper.SetVisible(self.WidgetBagCoinTips, true)
    end)

    UIHelper.BindUIEvent(self.BtnBatchSell, EventType.OnClick, function()
        self:EnterBatchSell()
    end)

    UIHelper.BindUIEvent(self.BtnConfirmSell, EventType.OnClick, function()
        self:DoBatchSell()
    end)

    UIHelper.BindUIEvent(self.BtnCancelSell, EventType.OnClick, function()
        self:ResetBatchSell()
    end)

    UIHelper.BindUIEvent(self.BtnQuickEquipment, EventType.OnClick, function()
        if self.bBatchSell then
            TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSELL)
            return
        end

        local scriptEquipChoose = UIHelper.GetBindScript(self.WidgetAnchorTuijian)

        scriptEquipChoose:InitTypeSelect()
        scriptEquipChoose:UpdateQuickEquipment()
        UIHelper.SetVisible(self.WidgetAnchorWarehouse, false)
    end)

    UIHelper.BindUIEvent(self.BtnDiscard, EventType.OnClick, function ()
        -- if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.BANK) or BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP, "destroy") then
        --     return
        -- end
        local tItemList = TravellingBagData.GetTravellingBagItems()
        local tDestoryList = {}
        local nMaxQuality = 1
        for _, tItemInfo in ipairs(tItemList) do
            local hItem = tItemInfo.hItem
            if hItem and hItem.dwTabType ~= 5 and hItem.nQuality <= TreasureBattleFieldData.nDropColor then
                if TreasureBattleFieldData.bIncludeHorse or hItem.nSub ~= EQUIPMENT_SUB.HORSE then
                    table.insert(tDestoryList, {tItemInfo.nBox, tItemInfo.nIndex})
                    nMaxQuality = math.max(nMaxQuality, hItem.nQuality)
                end
            elseif TreasureBattleFieldData.nXunbaoItemColor > 1 and hItem and hItem.dwTabType == 5 and hItem.nQuality <= (TreasureBattleFieldData.nXunbaoItemColor - 1)then
                table.insert(tDestoryList, {tItemInfo.nBox, tItemInfo.nIndex})
                nMaxQuality = math.max(nMaxQuality, hItem.nQuality)
            end
        end
        if #tDestoryList == 0 then
        elseif #tDestoryList == 1 then
            if TravellingBagData.tbSorting then
                OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_CANNOT_DESTROY_IN_SORT)
                return
            end
            RemoteCallToServer("On_Item_Drop", tDestoryList[1][1], tDestoryList[1][2])
        else
            if TravellingBagData.tbSorting then
                OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_CANNOT_DESTROY_IN_SORT)
                return
            end
            RemoteCallToServer("On_Item_DropTable", tDestoryList, nMaxQuality)
        end
    end)

    if Platform.IsWindows() or Platform.IsMac() then
		UIHelper.RegisterEditBoxEnded(self.EditBoxSearch, function()
			local szSearchText = UIHelper.GetString(self.EditBoxSearch)
			self.szSearchText = szSearchText
            self:UpdateItemListData(false, true)
            self:UpdateScrollList(SCROLL_LIST_UPDATE_TYPE.RESET, RIGHT)
		end)
	else
		UIHelper.RegisterEditBoxReturn(self.EditBoxSearch, function()
			local szSearchText = UIHelper.GetString(self.EditBoxSearch)
			self.szSearchText = szSearchText
            self:UpdateItemListData(false, true)
            self:UpdateScrollList(SCROLL_LIST_UPDATE_TYPE.RESET, RIGHT)
		end)
	end
end

function UIExtractPersetMainView:RegEvent()
    Event.Reg(self, "EQUIP_HORSE", function()
        self:UpdateHorseState()
        if self.bShowHorse then
            self:UpdateScrollList(SCROLL_LIST_UPDATE_TYPE.UPDATE_CELL, RIGHT)
        end
    end)

    Event.Reg(self, "UNEQUIP_HORSE", function()
        self:UpdateHorseState()
        if self.bShowHorse then
            self:UpdateScrollList(SCROLL_LIST_UPDATE_TYPE.UPDATE_CELL, RIGHT)
        end
    end)

    Event.Reg(self, "HORSE_ITEM_UPDATE", function()
        self:UpdateHorseState()
        if self.bShowHorse then
            self:UpdateScrollList(SCROLL_LIST_UPDATE_TYPE.UPDATE_CELL, RIGHT)
        end
    end)

    Event.Reg(self, "BAG_ITEM_UPDATE", function()
        if self.nType ~= ExtractViewType.BagAndLoot then
            return
        end
        self:UpdateItemListData(true, true)
        self:UpdateInfo(SCROLL_LIST_UPDATE_TYPE.UPDATE_CELL)
    end)

    Event.Reg(self, EventType.UpdateTBFWareHouse, function ()
        if self.scriptCurrency then
            self.scriptCurrency:HandleEvent()
        end

        self:UpdateItemListData(true, true)
        self:UpdateInfo(SCROLL_LIST_UPDATE_TYPE.UPDATE_CELL)
    end)

    Event.Reg(self, EventType.OnExtractOpenEquipChoosePage, function (bOpen, nIndex)
        local scriptEquipChoose = UIHelper.GetBindScript(self.WidgetAnchorTuijian)

        scriptEquipChoose:UpdateInfo(bOpen, nIndex)
        UIHelper.SetVisible(self.WidgetAnchorWarehouse, not bOpen)
    end)

    Event.Reg(self, EventType.OnExtractPersetBatchSell, function (bOpen)
        self:UpdateBatchSellInfo(bOpen)
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function ()
        if self.scriptLastClickItem and not self.bBatchSell then
            if self.scriptLastClickItem.SetSelected then
                self.scriptLastClickItem:SetSelected(false)
            end
            self.scriptLastClickItem = nil
        end

        UIHelper.SetVisible(self.WidgetBagCoinTips, false)
    end)
end

function UIExtractPersetMainView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
local function _fnGetLootItemList(dwDoodadID)
    local tbList = {}
    local doodad = GetDoodad(dwDoodadID)
    if not doodad then return tbList end
    local player = GetClientPlayer()
    if not player then return tbList end
    local scene = player.GetScene()
    if not scene then return tbList end

    local tAllLootItemInfo = scene.GetLootList(doodad.dwID)
    for i = 0, tAllLootItemInfo.nItemCount - 1 do
        local tItem = tAllLootItemInfo[i] and tAllLootItemInfo[i].Item
        if tItem then
            table.insert(tbList, {hItem = tItem})
        end
    end
    return tbList
end

local function _fnGetHorseList()
    local tbList = {}
    local tbBag = ItemData.GetItemList({INVENTORY_INDEX.HORSE})
    for index, tItem in ipairs(tbBag) do
        if tItem and tItem.hItem then
            table.insert(tbList, tItem)
        end
    end
    return tbList
end

function UIExtractPersetMainView:Init(nType)
    local player = GetClientPlayer()
    if not player then
        return
    end

    self.LeftScrollList     = self.tbLeftMainScrollList[nType]
    self.RightScrollList    = self.tbRightMainScrollList[nType]

    self:InitMainTitle()
    self:InitChildTab()
    self:InitScrollList()
    self:InitSettingInfo(nType)

    if self.dwDoodadID then
        local tbItemList = _fnGetLootItemList(self.dwDoodadID)
        self:InitLootFilter(tbItemList)
    end

    if not player.HaveRemoteData(REMOTE_DATA_ID) then
        player.ApplyRemoteData(REMOTE_DATA_ID, REMOTE_DATA_APPLY_EVENT_TYPE.CLIENT_APPLY_SERVER_CALL_BACK)
    end

    if not ExtractWareHouseData.bInitData then
        ExtractWareHouseData.Init()
    end

    ExtractWareHouseData.Update(true)
    self:InitEquipInfo(nType)
    self:UpdateItemListData(true, true)
    self:UpdateInfo()
    self:UpdateHorseState()
end

function UIExtractPersetMainView:InitMainTitle()
    local szTitle = MAIN_TITLE[self.nType]
    if self.dwDoodadID then
        szTitle = szTitle.."·拾取"
    end

    if self.nType == ExtractViewType.PersetAndWareHouse then
        if not self.scriptCurrency then
            self.scriptCurrency = UIHelper.AddPrefab(PREFAB_ID.WidgetOtherCurrency, self.LayoutCurrency)
            self.scriptCurrency:SetCurrencyType(CurrencyType.ExamPrint)
            self.scriptCurrency:HandleEvent()
        end
    end

    UIHelper.SetVisible(self.WidgetPowerUp, self.nType == ExtractViewType.PersetAndWareHouse)
    UIHelper.SetVisible(self.WidgetEquipShop, self.nType == ExtractViewType.PersetAndWareHouse)
    UIHelper.SetVisible(self.BtnQuickWear, self.nType == ExtractViewType.PersetAndWareHouse)
    UIHelper.SetVisible(self.BtnQuickApply, self.nType == ExtractViewType.PersetAndWareHouse)
    UIHelper.SetVisible(self.WidgetHorse, false)
    UIHelper.SetVisible(self.ImgEquipBg, self.nType == ExtractViewType.BagAndLoot)
    UIHelper.SetVisible(self.ImgBagBg, self.nType == ExtractViewType.BagAndLoot)
    UIHelper.SetString(self.LabelTitle, szTitle)

    UIHelper.LayoutDoLayout(self.LayoutBtn)
end

function UIExtractPersetMainView:InitChildTab()
    self.nLeftFilterIndex = 1
    self.nWareFilterIndex = 1
    UIHelper.RemoveAllChildren(self.ScrollViewLeftTab)
    UIHelper.RemoveAllChildren(self.ScrollViewWarehouseTab)

    local fnUpdateLeftFilter = function()
        local bFirst = true
        for i = 1, #tBagFilterCheck do
            local tConfig = tBagFilterCheck[i]
            local fnSubSelected = function(toggle, bState)
                if bState and self.nLeftFilterIndex ~= i then
                    self.nLeftFilterIndex = i
                    self:UpdateItemListData(true, false)
                    self:UpdateScrollList(SCROLL_LIST_UPDATE_TYPE.RESET, LEFT)
                end
            end
            local subData = { szTitle = tConfig.szFilter, onSelectChangeFunc = fnSubSelected}
            local scriptLeft = UIHelper.AddPrefab(PREFAB_ID.WidgetWarehouseChild, self.ScrollViewLeftTab, subData)
            UIHelper.SetToggleGroupIndex(scriptLeft.ToggleChildNavigation, ToggleGroupIndex.ExtractWareLeftChil)
            scriptLeft:SetSelected(bFirst)
            bFirst = false
        end
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewLeftTab)
    end

    local fnUpdateWarehouseFilter = function()
        local bFirst = true
        for i = 1, #tBagFilterCheck do
            local tConfig = tBagFilterCheck[i]
            local fnSubSelected = function(toggle, bState)
                if bState and self.nWareFilterIndex ~= i then
                    self.nWareFilterIndex = i
                    self:UpdateItemListData(false, true)
                    self:UpdateScrollList(SCROLL_LIST_UPDATE_TYPE.RESET, RIGHT)
                end
            end
            local subData = { szTitle = tConfig.szFilter, onSelectChangeFunc = fnSubSelected}
            local scriptRight = UIHelper.AddPrefab(PREFAB_ID.WidgetWarehouseChild, self.ScrollViewWarehouseTab, subData)
            UIHelper.SetToggleGroupIndex(scriptRight.ToggleChildNavigation, ToggleGroupIndex.ExtractWareRightChil)
            scriptRight:ShowLeftSelectUp(true)
            scriptRight:SetSelected(bFirst)
            bFirst = false
        end
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewWarehouseTab)
    end

    if self.nType == ExtractViewType.PersetAndWareHouse then
        fnUpdateWarehouseFilter()
    end
    fnUpdateLeftFilter()
end

local function _checkFilter(iteminfo, filterConfig)
    local result
    for nIndex, tCheck in pairs(filterConfig) do
        if nIndex ~= 1 and tCheck.filterFunc(iteminfo) then
            result = nIndex
            break
        end
    end
    return result
end

function UIExtractPersetMainView:InitLootFilter(tLootList)
    if not tLootList or #tLootList <= 0 then
        return
    end

    self.nLootFilterIndex = 1
    UIHelper.RemoveAllChildren(self.LayoutTypeFilter)
    local tbFilter = {tBagFilterCheck[1]}
    for _, tItem in ipairs(tLootList) do
        local item = tItem.hItem or {}
        local dwTabType, dwItemIndex = item.dwTabType, item.dwIndex

        if dwTabType and dwItemIndex and dwTabType > 0 and dwItemIndex > 0 then
            local iteminfo = GetItemInfo(dwTabType, dwItemIndex)

            local nResult = _checkFilter(iteminfo, tbFilter)
            if not nResult then
                nResult = _checkFilter(iteminfo, tBagFilterCheck)
                if nResult then
                    tbFilter[nResult] = tBagFilterCheck[nResult]
                end
            end
        end
    end

    for key, filter in pairs(tbFilter) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSimpleFilterTipCell, self.LayoutTypeFilter)
        UIHelper.SetString(script.LabelContentText, filter.szFilter)
        UIHelper.SetSwallowTouches(script.TogType, true)
        UIHelper.SetSelected(script.TogType, key == self.nLootFilterIndex, false)
        UIHelper.BindUIEvent(script.TogType, EventType.OnSelectChanged, function(_, bSelected)
            if bSelected then
                self.nLootFilterIndex = key
                self:UpdateItemListData(false, true)
                self:UpdateScrollList(SCROLL_LIST_UPDATE_TYPE.RESET, RIGHT)

                UIHelper.SetString(self.LabelLootType, filter.szFilter)
                UIHelper.SetString(self.LabelLootType_Up, filter.szFilter)
                UIHelper.SetSelected(self.TogTreasureType, false)
            end
        end)
    end
end

function UIExtractPersetMainView:InitEquipInfo(nType)
    self.scriptEquipList = UIHelper.GetBindScript(self.WidgetEquipList)
    self.scriptEquipList:OnEnter(nType)
end

function UIExtractPersetMainView:InitSettingInfo(nType)
    if nType ~= ExtractViewType.BagAndLoot then
        return
    end

    self.bShowSetting = not self.dwDoodadID
    UIHelper.SetSelected(self.TogSetting, self.bShowSetting, false)

    self.scriptSetting = UIHelper.GetBindScript(self.WidgetAnchorSetting)
    self.scriptSetting:OnEnter(nType)
end

function UIExtractPersetMainView:InitScrollList()
    self:UnInitScrollList()

    local LeftScrollList = self.tbLeftMainScrollList[self.nType]
    local RightScrollList = self.tbRightMainScrollList[self.nType]
    local nLeftRowPrefabID = PREFAB_ID.WidgetBagRow
    local nRightRowPrefabID = PREFAB_ID.WidgetBagRow
    if self.nType == ExtractViewType.BagAndLoot then
        nRightRowPrefabID = PREFAB_ID.WidgetTreasureItem
    end

    self.tLeftScrollList = UIScrollList.Create({
        listNode = LeftScrollList,
        nReboundScale = 1,
        bSlowRebound = true,
        fnGetCellType = function(nIndex)
            return nLeftRowPrefabID
        end,
        nSpace = 10,
        fnUpdateCell = function(cell, nIndex)
            self:UpdateLeftRow(cell, nIndex)
        end,
    })

    self.tRightScrollList = UIScrollList.Create({
        listNode = RightScrollList,
        nReboundScale = 1,
        bSlowRebound = true,
        fnGetCellType = function(nIndex)
            return nRightRowPrefabID
        end,
        nSpace = 10,
        fnUpdateCell = function(cell, nIndex)
            self:UpdateRightRow(cell, nIndex)
        end,
    })

    self.tLeftScrollList:SetScrollBarEnabled(true)
    self.tRightScrollList:SetScrollBarEnabled(true)
    local scriptDrag = UIHelper.GetBindScript(self.WidgetDrag)
    scriptDrag:SetScrollList(self.tLeftScrollList, self.tRightScrollList)
end

function UIExtractPersetMainView:UnInitScrollList()
    if self.tLeftScrollList then
        self.tLeftScrollList:Destroy()
        self.tLeftScrollList = nil
    end

    if self.tRightScrollList then
        self.tRightScrollList:Destroy()
        self.tRightScrollList = nil
    end
end

function UIExtractPersetMainView:UpdateViewTypeInfo()
    for index, widget in ipairs(self.tbLeftMainWidget) do
        UIHelper.SetVisible(widget, self.nType == index)
    end

    for index, widget in ipairs(self.tbRightMainWidget) do
        UIHelper.SetVisible(widget, self.nType == index)
    end

    for index, scrolllist in ipairs(self.tbLeftMainScrollList) do
        UIHelper.SetVisible(scrolllist, self.nType == index)
    end

    for index, scrolllist in ipairs(self.tbRightMainScrollList) do
        UIHelper.SetVisible(scrolllist, self.nType == index)
    end

    if self.bShowSetting then
        UIHelper.SetVisible(self.WidgetTreasureContent, false)
        UIHelper.SetVisible(self.WidgetAnchorSetting, true)
    elseif self.dwDoodadID or self.bShowHorse then
        UIHelper.SetVisible(self.WidgetTreasureContent, true)
        UIHelper.SetVisible(self.WidgetAnchorSetting, false)
    else
        UIHelper.SetVisible(self.tbRightMainWidget[ExtractViewType.BagAndLoot], false)
    end

    UIHelper.SetVisible(self.WidgetTip_Treasure, self.dwDoodadID and not self.bShowHorse)
    UIHelper.SetVisible(self.BtnDiscard, self.nType == ExtractViewType.BagAndLoot)
    UIHelper.SetVisible(self.BtnSorting, self.nType == ExtractViewType.BagAndLoot)
    UIHelper.SetVisible(self.TogSetting, self.nType == ExtractViewType.BagAndLoot)
    UIHelper.SetVisible(self.BtnSetting, false)

    UIHelper.SetVisible(self.WidgetTip, self.nType == ExtractViewType.PersetAndWareHouse)
    UIHelper.SetVisible(self.WidgetTip_Ware, self.nType == ExtractViewType.PersetAndWareHouse and not self.bBatchSell)
    UIHelper.SetVisible(self.BtnSorting_Warehouse, self.nType == ExtractViewType.PersetAndWareHouse)
    UIHelper.SetVisible(self.BtnBatchSell, false)
    UIHelper.SetVisible(self.WidgetQuickEquipment, self.nType == ExtractViewType.PersetAndWareHouse)
    UIHelper.SetVisible(self.BtnPutIn, self.nType == ExtractViewType.PersetAndWareHouse)
end

function UIExtractPersetMainView:UpdateLeftRow(cell, nIndex)
    if not cell then
        return
    end
    cell._keepmt = true

    local nItemCountOfEachRow = TYPE_TO_EACH_ROW_NUM[LEFT][self.nType]
    local cellNodes = UIHelper.GetChildren(cell.LayoutBagItem)
    local nStartIndex = nItemCountOfEachRow * (nIndex - 1) + 1
    local nEndIndex = nItemCountOfEachRow * nIndex

    for i = nStartIndex, nEndIndex do
        local nNodeIndex = i - nStartIndex + 1
        local targetNode = cellNodes[nNodeIndex]
        local tbPos = self.tbLeftItemList[i]

        if tbPos then
            local cellScript = UIHelper.GetBindScript(targetNode) or UIHelper.AddPrefab(PREFAB_ID.WidgetXunBaoItemCell, cell.LayoutBagItem)

            if cellScript then
                self:InitXunBaoItem(LEFT, cellScript, tbPos, i)
            end
        else
            UIHelper.RemoveAllChildren(targetNode)
        end
    end
end

function UIExtractPersetMainView:UpdateRightRow(cell, nIndex)
    if not cell then
        return
    end
    cell._keepmt = true

    local nItemCountOfEachRow = TYPE_TO_EACH_ROW_NUM[RIGHT][self.nType]
    local cellNodes = UIHelper.GetChildren(cell.LayoutBagItem)
    local nStartIndex = nItemCountOfEachRow * (nIndex - 1) + 1
    local nEndIndex = nItemCountOfEachRow * nIndex

    for i = nStartIndex, nEndIndex do
        local nNodeIndex = i - nStartIndex + 1
        local targetNode = cellNodes[nNodeIndex]
        local tbPos = self.tbRightItemList[i]

        if tbPos then
            local nPrefabID = PREFAB_ID.WidgetXunBaoItemCell
            if self.nType == ExtractViewType.BagAndLoot then
                nPrefabID = PREFAB_ID.WidgetEquipCompareItemCell
            end

            local cellScript = UIHelper.GetBindScript(targetNode) or UIHelper.AddPrefab(nPrefabID, cell.LayoutBagItem)
            if cellScript then
                if self.nType == ExtractViewType.PersetAndWareHouse then
                    self:InitXunBaoItem(RIGHT, cellScript, tbPos, i)
                elseif self.nType == ExtractViewType.BagAndLoot then
                    self:InitLootItem(self.bShowHorse, cellScript, tbPos, i)
                end
            end
        else
            UIHelper.RemoveAllChildren(targetNode)
        end
    end
end

function UIExtractPersetMainView:InitXunBaoItem(nScorllListType, cellScript, tbPos, nIndex)
    cellScript:OnEnter(tbPos)
    cellScript:SetToggleGroupIndex(ToggleGroupIndex.BagItem)

    local itemScript = cellScript:GetItemScript()

    if itemScript then
        itemScript:SetSelectMode(self.bBatchSell and tbPos.nType == ExtractItemType.WareHouse)
        itemScript:SetToggleSwallowTouches(false)
        UIHelper.UnBindUIEvent(itemScript.ToggleSelect, EventType.OnLongPress)
    end

    cellScript:SetDragEndCallBack(function (scriptTargetItem, node, bInParent)
        if self.nType == ExtractViewType.PersetAndWareHouse then
            local tbInfo = scriptTargetItem and scriptTargetItem:GetItemInfo()
            if tbInfo and tbInfo.nSlot and tbInfo.nType and not tbInfo.bLock then
                local nTargetType, nTargetSlot = tbInfo.nType, tbInfo.nSlot
                if nTargetType == ExtractItemType.Equip then
                    ExtractWareHouseData.SaveToEquip(tbPos.nType, tbPos.nSlot)
                    return
                end

                local szPlacementBtnText = "放入"
                local function fnCallBack (nCurCount)
                    RemoteCallToServer("On_JueJing_MoveItem", tbPos.nType, tbPos.nSlot, nTargetType, nTargetSlot, nCurCount)
                end
                self:ShowDragItemTip(tbPos, nScorllListType, szPlacementBtnText, fnCallBack)
            end
        elseif scriptTargetItem then
            if scriptTargetItem.nBox == INVENTORY_INDEX.EQUIP then
                ItemData.EquipItem(cellScript.nBox, cellScript.nIndex)
                return
            end

            local tbInfo = scriptTargetItem:GetItemInfo()
            local function fnCallback(nCurCount)
                ItemData.OnExchangeItem(cellScript.nBox, cellScript.nIndex, tbInfo.nBox, tbInfo.nIndex, nCurCount)
            end

            local bTargetEmpty = not ItemData.GetItemByPos(tbInfo.nBox, tbInfo.nIndex)
            if tbInfo.nBox and tbInfo.nIndex and not bTargetEmpty then
                fnCallback()
            elseif tbInfo.nBox and tbInfo.nIndex then
                local szPlacementBtnText = "放入"
                self:ShowDragItemTip(tbPos, nScorllListType, szPlacementBtnText, fnCallback)
            end
        elseif bInParent ~= nil and not bInParent then
            RemoteCallToServer("On_Item_Drop", cellScript.nBox, cellScript.nIndex)
        end
    end)

    cellScript:SetDoubleClickCallBack(function ()
        if self.nType == ExtractViewType.PersetAndWareHouse then
            if self.bBatchSell then
                TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSELL)
                return
            end

            if ExtractWareHouseData.IsWeaponBox(tbPos.dwItemType, tbPos.dwItemIndex) or
                    (tbPos.dwItemType >= ITEM_TABLE_TYPE.CUST_WEAPON and tbPos.dwItemType <= ITEM_TABLE_TYPE.CUST_TRINKET) then
                ExtractWareHouseData.SaveToEquip(tbPos.nType, nIndex)
            else
                ExtractWareHouseData.SaveToPerset(tbPos.nType, nIndex)
            end
        end
    end)

    local _fnUpdateBatchSellState = function()
        if not itemScript then
            return
        end

        itemScript:OnItemIconChoose(false)
        if self.bBatchSell then
            if tbPos.nSlot and self.tbSellList[tbPos.nSlot] then
                itemScript:OnItemIconChoose(true, nil, nil, self.tbSellList[tbPos.nSlot])
                UIHelper.SetString(itemScript.LabelChooseNum, self.tbSellList[tbPos.nSlot])
                UIHelper.SetVisible(itemScript.LabelChooseNum, true)
                UIHelper.SetSelected(itemScript.ToggleSelect, true, false)
            end
        end
    end

    _fnUpdateBatchSellState()

    cellScript:SetSelectChangeCallback(function (_, bSelected)
        if self.bBatchSell then
            if tbPos.nType == ExtractItemType.WareHouse then
                self:AddToBatchSell(bSelected, tbPos.nSlot, tbPos.nNum)
                _fnUpdateBatchSellState()
            elseif tbPos.nType == ExtractItemType.Perset then
                TipsHelper.ShowNormalTip(g_tStrings.STR_LOCKER_CAN_NOT_SELL_PRESET)
            end
        end

        if not bSelected then
            return
        end

        self.scriptLastClickItem = cellScript.scriptItem
        local scriptDrag = UIHelper.GetBindScript(self.WidgetDrag)
        local scriptItemTips = scriptDrag:OpenItemTip(nScorllListType)
        if self.nType == ExtractViewType.BagAndLoot then
            scriptItemTips:OnInit(tbPos.nBox, tbPos.nIndex)
            return
        end

        local tbBtnList = {}
        if tbPos.nNum and tbPos.nNum > 1 then
            local szCountTitle = "取出数量："
            local szPlacementBtnText = nScorllListType == RIGHT and "放入背包" or "取出"
            if self.bBatchSell and tbPos.nType == ExtractItemType.WareHouse then
                szCountTitle = "售出数量："
                szPlacementBtnText = "确认"
            end

            local fnPlacementCallback = function(nCurCount)
                if nScorllListType == RIGHT then
                    if self.bBatchSell and tbPos.nType == ExtractItemType.WareHouse then
                        LOG.INFO("UIPanelExtractWareHouse:UpdateWareHouseInfo: AddToBatchSell:nSlot = %d, nNum = %d", tbPos.nSlot, nCurCount)
                        -- self:AddToBatchSell(true, tbPos.nSlot, nNum)
                        -- _fnUpdateBatchSellState()
                        return
                    end
                    ExtractWareHouseData.SaveToPerset(ExtractItemType.WareHouse, tbPos.nSlot, nil, nCurCount)
                else
                    ExtractWareHouseData.SaveToWareHouse(false, ExtractItemType.Perset, tbPos.nSlot, nil, nCurCount)
                end
                Event.Dispatch(EventType.HideAllHoverTips)
            end
            scriptItemTips:ShowPlacementBtn(true, tbPos.nNum, tbPos.nNum, szPlacementBtnText, szCountTitle, fnPlacementCallback)
        else
            if self.nType == ExtractViewType.PersetAndWareHouse then
                if ExtractWareHouseData.IsWeaponBox(tbPos.dwItemType, tbPos.dwItemIndex) or
                        (tbPos.dwItemType >= ITEM_TABLE_TYPE.CUST_WEAPON and tbPos.dwItemType <= ITEM_TABLE_TYPE.CUST_TRINKET) then
                    table.insert(tbBtnList, { szName = "装备", OnClick = function()
                        ExtractWareHouseData.SaveToEquip(tbPos.nType, nIndex)
                        Event.Dispatch(EventType.HideAllHoverTips)
                    end })
                end

                if nScorllListType == RIGHT then
                    table.insert(tbBtnList, { szName = "放入背包", OnClick = function()
                        ExtractWareHouseData.SaveToPerset(ExtractItemType.WareHouse, tbPos.nSlot, nil)
                        Event.Dispatch(EventType.HideAllHoverTips)
                    end })
                else
                    table.insert(tbBtnList, { szName = "取出", OnClick = function()
                        ExtractWareHouseData.SaveToWareHouse(false, ExtractItemType.Perset, tbPos.nSlot)
                        Event.Dispatch(EventType.HideAllHoverTips)
                    end })
                end
            end
        end

        scriptItemTips:OnInitWithTabID(tbPos.dwItemType, tbPos.dwItemIndex)
        if not table.is_empty(tbBtnList) and not self.bBatchSell then
            scriptItemTips:SetBtnState(tbBtnList)
        end
    end)
end

function UIExtractPersetMainView:InitLootItem(bHorse, cellScript, tbPos, nIndex)
    local function funcOnClickCallback()
        self.scriptLastClickItem = cellScript.scriptItem
        local scriptDrag = UIHelper.GetBindScript(self.WidgetDrag)
        local scriptItemTips = scriptDrag:OpenItemTip(RIGHT)
        local tbBtnList = {}
        if bHorse then
            local dwCurBox, nCurIndex = EquipData.GetCurrentRide()
            if tbPos.nIndex and tbPos.nIndex ~= nCurIndex then
                table.insert(tbBtnList, { szName = "设为当前", OnClick = function()
                    g_pClientPlayer.EquipHorse(tbPos.nBox, tbPos.nIndex)
                    Event.Dispatch(EventType.HideAllHoverTips)
                end })
            end
        else
            table.insert(tbBtnList, { szName = "拾取", OnClick = function()
                LootItem(self.dwDoodadID, tbPos.item.dwID)
                Event.Dispatch(EventType.HideAllHoverTips)
            end })
        end

        if bHorse then
            scriptItemTips:OnInit(tbPos.nBox, tbPos.nIndex)
        else
            scriptItemTips:OnInitWithTabID(tbPos.dwItemType, tbPos.dwItemIndex)
        end

        scriptItemTips:SetBtnState(tbBtnList)
    end

    local tItem = { dwTabType = tbPos.dwItemType, dwIndex = tbPos.dwItemIndex,
                    dwItemType = tbPos.dwItemType, dwItemIndex = tbPos.dwItemIndex,
                    nBox = tbPos.nBox, nIndex = tbPos.nIndex, item = tbPos.item,
                        funcOnClickCallback = funcOnClickCallback}
    cellScript:OnInit(tItem, false)
    cellScript:SetToggleGroupIndex(ToggleGroupIndex.BagItem)
    cellScript.OnDragEnd = function(cellScript, scriptTargetItem, bInParent)
        if scriptTargetItem then
            LootItem(self.dwDoodadID, tbPos.item.dwID)
            Event.Reg(cellScript, "BAG_ITEM_UPDATE", function(nBox, nIndex, bNewAdd)
                if bNewAdd then
                    ItemData.OnExchangeItem(nBox, nIndex, scriptTargetItem.nBox, scriptTargetItem.nIndex)
                end
            end, true)
        end
    end

    cellScript.OnDoubleClick = function(cellScript)
        LootItem(self.dwDoodadID, tbPos.item.dwID)
    end
end

local function fnSearchText(iteminfo, szSearchText)
    if not iteminfo then
        return false
    end

    if string.is_nil(szSearchText) or szSearchText == "" then
        return true
    end

    local szName = UIHelper.GBKToUTF8(iteminfo.szName) or ""
    local bFind = string.find(szName, szSearchText)
    return bFind
end

function UIExtractPersetMainView:fnGetWareList(nType)
    local nSafeZone     = 0
    local tbList        = {}
    local nFilterIndex  = self.nWareFilterIndex
    local tbItemList    = ExtractWareHouseData.GetItemList(nType)
    local nMaxSize      = ExtractWareHouseData.GetMaxZone(nType)
    local nUnlockZone   = ExtractWareHouseData.GetUnlockZone(nType)

    if nType == ExtractItemType.Perset then
        nFilterIndex = self.nLeftFilterIndex
        nSafeZone = ExtractWareHouseData.GetPersetSafeZone()
    end

    for i = 1, nMaxSize, 1 do
        local tItemFilter = tBagFilterCheck[nFilterIndex]
        local bShow = tItemFilter.bShowEmptyCell
        if bShow and nType == ExtractItemType.WareHouse then
            bShow = string.is_nil(self.szSearchText)
        end

        local item = tbItemList[i] or {}
        local dwTabType, dwItemIndex, nNum = item.nType, item.dwIndex, item.nNum
        if dwTabType and dwItemIndex and dwTabType > 0 and dwItemIndex > 0 then
            local iteminfo = GetItemInfo(dwTabType, dwItemIndex)
            bShow = tItemFilter.filterFunc(iteminfo)

            if bShow and nType == ExtractItemType.WareHouse then
                bShow = fnSearchText(iteminfo, self.szSearchText)
            end
        end

        if bShow then
            table.insert(tbList, {nType = nType, nSlot = i, dwItemType = dwTabType, dwItemIndex = dwItemIndex,
                                        nNum = nNum, bLock = (nUnlockZone and i > nUnlockZone), bSafe = i <= nSafeZone})
        end
    end

    return tbList
end

function UIExtractPersetMainView:fnGetBagList(nType)
    local nSafeZone     = 0
    local nFilterIndex  = 1
    local tbList        = {}
    local tbItemList    = {}

    if nType == ExtractItemType.TravellingBag then
        nFilterIndex    = self.nLeftFilterIndex
        nSafeZone       = ExtractWareHouseData.GetPersetSafeZone()
        tbItemList      = TravellingBagData.GetTravellingBagItems()
    elseif nType == ExtractItemType.Loot then
        nFilterIndex    = self.nLootFilterIndex
        tbItemList      = _fnGetLootItemList(self.dwDoodadID)
    elseif nType == ExtractItemType.Horse then
        tbItemList      = _fnGetHorseList()
    end

    for i, tItemInfo in ipairs(tbItemList) do
        local item = tItemInfo.hItem
        local dwTabType, dwItemIndex, nNum
        if item then
            dwTabType, dwItemIndex, nNum = item.dwTabType, item.dwIndex, ItemData.GetItemStackNum(item)
        end

        local tItemFilter = tBagFilterCheck[nFilterIndex]
        local bShow = tItemFilter.bShowEmptyCell
        if dwTabType and dwItemIndex and dwTabType > 0 and dwItemIndex > 0 then
            local iteminfo = GetItemInfo(dwTabType, dwItemIndex)
            bShow = tItemFilter.filterFunc(iteminfo)
        end

        if bShow then
            table.insert(tbList, {nType = nType, nSlot = i, nNum = nNum, bSafe = i <= nSafeZone, -- 预设属性
                                    dwItemType = dwTabType, dwItemIndex = dwItemIndex, -- iteminfo属性
                                    nBox = tItemInfo.nBox, nIndex = tItemInfo.nIndex, -- item属性
                                    item = item})
        end
    end
    return tbList
end

function UIExtractPersetMainView:UpdateItemListData(bUpdateLeft, bUpdateRight, bUpdateHorse)
    self.tbLeftItemList = self.tbLeftItemList or {}
    self.tbRightItemList = self.tbRightItemList or {}

    if self.nType == ExtractViewType.PersetAndWareHouse then
        self.tbLeftItemList     = bUpdateLeft and self:fnGetWareList(ExtractItemType.Perset) or self.tbLeftItemList
        self.tbRightItemList    = bUpdateRight and self:fnGetWareList(ExtractItemType.WareHouse) or self.tbRightItemList
    else
        self.tbLeftItemList     = bUpdateLeft and self:fnGetBagList(ExtractItemType.TravellingBag) or self.tbLeftItemList
        self.tbRightItemList    = bUpdateRight and self:fnGetBagList(ExtractItemType.Loot) or self.tbRightItemList
    end

    if self.bShowHorse then
        self.tbRightItemList = bUpdateHorse and self:fnGetBagList(ExtractItemType.Horse) or self.tbRightItemList
    end

    self.nLeftCountOfRow = math.ceil((#self.tbLeftItemList) / TYPE_TO_EACH_ROW_NUM[LEFT][self.nType])
    self.nRightCountOfRow = math.ceil((#self.tbRightItemList) / TYPE_TO_EACH_ROW_NUM[RIGHT][self.nType])

    self.tLeftScrollList:SetCellTotal(self.nLeftCountOfRow)
    self.tRightScrollList:SetCellTotal(self.nRightCountOfRow)
    self:UpdateTitle()
end

local function fnGetItemCount(tbItemList)
    local nCount = 0
    local nTotalZone = #tbItemList
    for index, tbInfo in ipairs(tbItemList) do
        if tbInfo.nNum and tbInfo.nNum > 0 then
            nCount = nCount + 1
        elseif tbInfo.bLock then
            nTotalZone = index - 1
            break
        end
    end
    return nCount, nTotalZone
end

function UIExtractPersetMainView:UpdateTitle()
    local nPersetValue, nBagValue, nEquipValue
    local nBagValue    = nil
    local nEquipValue   = nil
    local bShowLeftCount = true
    local bShowRightCount = self.nType ~= ExtractViewType.BagAndLoot
    local bLeftEmpty    = #self.tbLeftItemList == 0
    local bRightEmpty   = #self.tbRightItemList == 0
    local szLeftTitle   = TYPE_TO_TITLE[LEFT][self.nType]
    local szRightTitle  = TYPE_TO_TITLE[RIGHT][self.nType]
    local szEquipTitle  = TYPE_TO_TITLE[EQUIP][self.nType]
    local nLeftItemCont, nLeftItemTotal     = fnGetItemCount(self.tbLeftItemList)
    local nRightItemCont, nRightItemTotal   = fnGetItemCount(self.tbRightItemList)
    nPersetValue, nBagValue, nEquipValue = ExtractWareHouseData.GetPersetValue()

    local szCount = "（%d/%d）"
    local tLeftFilter = tBagFilterCheck[self.nLeftFilterIndex]
    bShowLeftCount = bShowLeftCount and tLeftFilter.bShowEmptyCell
    if bShowLeftCount then
        szLeftTitle  = szLeftTitle..string.format(szCount, nLeftItemCont, nLeftItemTotal)
    end

    local tRightFilter = tBagFilterCheck[self.nWareFilterIndex]
    bShowRightCount = bShowRightCount and tRightFilter.bShowEmptyCell
    if bShowRightCount then
        szRightTitle = szRightTitle..string.format(szCount, nRightItemCont, nRightItemTotal)
    end

    nBagValue = GDAPI_TbfWareGetPackageValue() or 0
    nEquipValue = GDAPI_TbfWareGetCurEquipValue() or 0
    if self.nType == ExtractViewType.BagAndLoot then
        local szCurrencyImg = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_QiJing"
        local szBagValue = UIHelper.GetCurrencyText(nBagValue, szCurrencyImg, 27)
        local szEquipValue = UIHelper.GetCurrencyText(nEquipValue, szCurrencyImg, 27)
        szBagValue = string.format("<color=#AED9E0>背包价值：%s</c>", szBagValue)
        szEquipValue = string.format("<color=#AED9E0>装备价值：%s</c>", szEquipValue)

        UIHelper.SetRichText(self.LabelBagScroe, szBagValue)
        UIHelper.SetRichText(self.LabelEquipScroe, szEquipValue)
    end

    if self.bShowHorse then
        szRightTitle = "坐骑"
    end

    UIHelper.SetString(self.LabelNum, nPersetValue)
    UIHelper.SetString(self.LabelNum_Bag, nBagValue)
    UIHelper.SetString(self.LabelNum_Equip, nEquipValue)
    UIHelper.SetString(self.LabelTtleBag, szLeftTitle)
    UIHelper.SetString(self.LabelTtleWarehouse, szRightTitle)
    UIHelper.SetString(self.LabelTtleTreasure, szRightTitle)
    UIHelper.SetString(self.LabelTtleEquipment, szEquipTitle)

    UIHelper.SetVisible(self.WidgetEmpty_Left, bLeftEmpty)
    UIHelper.SetVisible(self.WidgetEmpty_Loot, bRightEmpty and self.nType == ExtractViewType.BagAndLoot)
    UIHelper.SetVisible(self.WidgetEmpty_Ware, bRightEmpty and self.nType == ExtractViewType.PersetAndWareHouse)
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutCoin, true, true)
end

function UIExtractPersetMainView:UpdateScrollList(nUpdateType, nScorllListType)
    local tScrollList = nScorllListType == LEFT and self.tLeftScrollList or self.tRightScrollList
    if not tScrollList then
        return
    end
    local nCountOfRow = nScorllListType == LEFT and self.nLeftCountOfRow or self.nRightCountOfRow
    local min, max = tScrollList:GetIndexRangeOfLoadedCells()
    nUpdateType = nUpdateType or SCROLL_LIST_UPDATE_TYPE.RELOAD

    if nUpdateType == SCROLL_LIST_UPDATE_TYPE.RESET then
        tScrollList:Reset(nCountOfRow) --完全重置，包括速度、位置
    elseif nUpdateType == SCROLL_LIST_UPDATE_TYPE.RELOAD then
        tScrollList:ReloadWithStartIndex(nCountOfRow, min) --刷新数量
    elseif nUpdateType == SCROLL_LIST_UPDATE_TYPE.UPDATE_CELL then
        tScrollList:UpdateAllCell() --仅更新当前所有的Cell
    end
end

function UIExtractPersetMainView:UpdateInfo(nUpdateType)
    nUpdateType = nUpdateType or SCROLL_LIST_UPDATE_TYPE.RESET
    self:UpdateScrollList(nUpdateType, LEFT)
    self:UpdateScrollList(nUpdateType, RIGHT)

    Event.Dispatch(EventType.HideAllHoverTips)
end

function UIExtractPersetMainView:UpdateHorseState()
	local hPlayer = PlayerData.GetClientPlayer()
    local horse = hPlayer.GetEquippedHorse()
    UIHelper.SetProgressBarStarPercentPt(self.ImgHungerFg, 0, 0)
	if not horse then
        UIHelper.SetProgressBarPercent(self.ImgHungerFg, 0)
        UIHelper.SetString(self.LabelHunger, "")
        return
	end

	local nFullLevel = horse.GetHorseFullLevel()
	local fCurFullMeasure = horse.GetHorseFullMeasure()
	local fMaxFullMeasure = horse.GetHorseMaxFullMeasure()

    local fPerc = fCurFullMeasure / fMaxFullMeasure * 100
	local szPerc = string.format("%.0f%%", fPerc)
    UIHelper.SetString(self.LabelHunger, szPerc)
    UIHelper.SetProgressBarPercent(self.ImgHungerFg, fPerc * 0.5)
end

function UIExtractPersetMainView:OnShowHorse(bShow)
    self.bShowHorse = bShow
    if self.bShowHorse then
        UIHelper.SetSelected(self.TogSetting, false)
    end
    self:UpdateViewTypeInfo()
    self:UpdateItemListData(false, not bShow, bShow)
    self:UpdateInfo(SCROLL_LIST_UPDATE_TYPE.UPDATE_CELL)

    UIHelper.SetVisible(self.BtnBack_Horse, self.bShowHorse)
    UIHelper.SetVisible(self.TogTreasureType, not self.bShowHorse)
    UIHelper.LayoutDoLayout(self.LayoutBtn_Treasure)
    UIHelper.PlayAni(self, self.tbRightMainWidget[ExtractViewType.BagAndLoot], "AniTreasureContent")
end

function UIExtractPersetMainView:OnShowSetting(bShow)
    self.bShowSetting = bShow
    if self.bShowSetting then
        self.bShowHorse = false
        self:UpdateItemListData(false, true, false)
    end
    self:UpdateViewTypeInfo()

    UIHelper.PlayAni(self, self.tbRightMainWidget[ExtractViewType.BagAndLoot], "AniTreasureContent")
end

function UIExtractPersetMainView:ShowDragItemTip(tItem, nScorllListType, szPlacementBtnText, fnCallback)
    -- 拖拽物品，若可堆叠则显示数量选择Tips
    if not tItem.nNum or tItem.nNum <= 1 then
        fnCallback()
        return
    end

    local scriptDrag = UIHelper.GetBindScript(self.WidgetDrag)
    local scriptItemTips = scriptDrag:OpenItemTip(nScorllListType)
    scriptItemTips:ShowPlacementBtn(true, tItem.nNum, tItem.nNum, szPlacementBtnText, nil, function (nCurCount)
        fnCallback(nCurCount)
    end)
    scriptItemTips:OnInitWithTabID(tItem.dwItemType, tItem.dwItemIndex)
end

function UIExtractPersetMainView:EnterBatchSell()
    self.bBatchSell = true
    self.tbSellList = {}
    self:UpdateInfo(SCROLL_LIST_UPDATE_TYPE.UPDATE_CELL)
    self:UpdateSellInfo()
    self:UpdateViewTypeInfo()

    local scriptDrag = UIHelper.GetBindScript(self.WidgetDrag)
    if scriptDrag then
        scriptDrag:SetSellMode(true)
    end

    local scriptEquip = UIHelper.GetBindScript(self.WidgetEquipList)
    if scriptEquip then
        scriptEquip:SetSellMode(true)
    end
end

function UIExtractPersetMainView:DoBatchSell()
    local tIndexList = {}
    for k, v in pairs(self.tbSellList) do
        table.insert(tIndexList, k)
    end
    RemoteCallToServer("On_JueJing_QuickSoldInWare", tIndexList)
    self:ResetBatchSell()
end

function UIExtractPersetMainView:AddToBatchSell(bSelected, nSlot, nNum)
    self.tbSellList = self.tbSellList or {}
    if bSelected then
        self.tbSellList[nSlot] = nNum
    else
        self.tbSellList[nSlot] = nil
    end

    self:UpdateSellInfo()
end

function UIExtractPersetMainView:UpdateSellInfo()
    self.tbSellList = self.tbSellList or {}
    local nTotalValue = 0
    for k, nNum in pairs(self.tbSellList) do
        nTotalValue = nTotalValue + ExtractWareHouseData.GetItemValue(ExtractItemType.WareHouse, k, nNum)
    end

    UIHelper.SetString(self.LabelCoinNum, nTotalValue)
    UIHelper.LayoutDoLayout(self.LayoutCost)
end

function UIExtractPersetMainView:ResetBatchSell()
    self.bBatchSell = false
    self.tbSellList = nil
    self:UpdateInfo(SCROLL_LIST_UPDATE_TYPE.UPDATE_CELL)
    self:UpdateViewTypeInfo()

    local scriptDrag = UIHelper.GetBindScript(self.WidgetDrag)
    if scriptDrag then
        scriptDrag:SetSellMode(false)
    end

    local scriptEquip = UIHelper.GetBindScript(self.WidgetEquipList)
    if scriptEquip then
        scriptEquip:SetSellMode(false)
    end
end

return UIExtractPersetMainView