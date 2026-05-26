-- ---------------------------------------------------------------------------------
-- Author: JiaYuRan
-- Name: UIPanelWareHouse
-- ---------------------------------------------------------------------------------

local tWareHouseInfoList = {
    {
        szName = "个人",
        szTitle = "个人仓库",
        szWareHouseType = WareHouseType.Role,
        szIconPath = "UIAtlas2_Warehouse_Warehouse_icon_GeRen",
        szUnavailableMsg = "当前地图禁止使用个人仓库"
    },
    {
        szName = "账号",
        szTitle = "账号仓库",
        szWareHouseType = WareHouseType.Account,
        szIconPath = "UIAtlas2_Warehouse_Warehouse_icon_ZhangHao",
        szUnavailableMsg = "当前地图禁止使用账号仓库"
    },
    {
        szName = "帮会",
        szTitle = "帮会仓库",
        szWareHouseType = WareHouseType.Faction,
        szIconPath = "UIAtlas2_Warehouse_Warehouse_icon_BangHui",
        szUnavailableMsg = "当前地图禁止使用帮会仓库"
    },
    {
        szName = "马厩",
        szTitle = "马厩",
        szWareHouseType = WareHouseType.Horse,
        szIconPath = "UIAtlas2_Warehouse_Warehouse_icon_MaJiu",
        szUnavailableMsg = "当前地图禁止使用马厩"
    },
    {
        szName = "家园",
        szTitle = "家园储物箱",
        szWareHouseType = WareHouseType.Homeland,
        szIconPath = "UIAtlas2_Warehouse_Warehouse_icon_JiaYuan",
        szUnavailableMsg = "当前地图禁止使用家园仓库"
    },
    {
        szName = "百战",
        szTitle = "百战书库",
        szWareHouseType = WareHouseType.BaiZhan,
        szIconPath = "UIAtlas2_Warehouse_Warehouse_icon_BaiZhan",
        szUnavailableMsg = "请前往百战异闻录使用"
    },
    {
        szName = "寻宝",
        szTitle = "寻宝模式",
        szWareHouseType = WareHouseType.Extract,
        szIconPath = "UIAtlas2_Warehouse_Warehouse_icon_XunBao",
        szUnavailableMsg = "当前地图禁止使用寻宝仓库"
    },
}

do
    local nItemCountOfEachRow = 5
    local WARE_HOUSE_BATCH_LIMIT = 20
    local WARE_HOUSE_BATCH_EXCEED_TIPS = "已达最大批量数目"
    local WARE_HOUSE_MIN_INDEX, WARE_HOUSE_MAX_INDEX = 8, 13

    local fnAccountHasTemporary = function()
        if not g_pClientPlayer then
            return false
        end
        local dwSource = ACCOUNT_SHARED_PACKAGE_SOURCE.LEFT
        local player = g_pClientPlayer
        local nHaveCount = player.GetAccountSharedPackageBoxSize(dwSource, ACCOUNT_SHARED_PACKAGE_BOX.PACKAGE)
        for i = 0, nHaveCount - 1 do
            local dwBox, dwX = ACCOUNT_SHARED_PACKAGE_BOX.PACKAGE, i
            local hItem = player.GetItemInAccountSharedPackage(dwSource, dwBox, dwX)
            if hItem then
                return true
            end
        end
        return false
    end

    WarehouseData = WarehouseData or {
        szFilter = ""
    }
    local self = WarehouseData

    function WarehouseData.Init(script)
        WarehouseData.ClearFilter()
        WarehouseData.RegisterNode(script) -- 需要先注册再 InitScrollList
        WarehouseData.InitScrollList()
    end

    function WarehouseData.CheckMatchFilter(item)
        if not WarehouseData.szFilter or WarehouseData.szFilter == "" then
            return true
        end

        if not item then
            return false
        end

        local szType = ItemData.GetItemTypeInfoDesc(item, false)
        if string.find(szType, WarehouseData.szFilter) then
            return true
        end

        local szItemDesc = ItemData.GetItemDesc(item.nUiId)
        if szItemDesc and string.find(szItemDesc, WarehouseData.szFilterUTF8) then
            return true
        end

        local szName = ItemData.GetItemNameByItem(item)
        if string.find(szName, WarehouseData.szFilter) then
            return true
        end
    end

    function WarehouseData.HasFilterText()
        if not WarehouseData.szFilter or WarehouseData.szFilter == "" then
            return false
        end
        return true
    end

    function WarehouseData.ClearFilter()
        WarehouseData.szFilter = ""
        WarehouseData.szFilterUTF8 = ""
    end

    function WarehouseData.Clear()
        if self.tScrollList then
            self.tScrollList:SetCellTotal(0)
        end
        self.bUpdatingCell = false

        self.bBatchSelect = false
        self.dwItemID = nil
        self.tbCellScripts = {}
        self.tbPos = { nBox = nil, nIndex = nil }
        self.tbBatch = {}
        self.nIndexToCellPos = {}
        self.fnTakeOut = nil
        self.scriptItemTip = nil
        self.nBatchMaxCount = 0
    end

    function WarehouseData.BindUIEvent()
        -- 绑定通用的事件回调
        UIHelper.BindUIEvent(self.BtnPutIn, EventType.OnClick, function()
            if PropsSort.IsBagInSort() or PropsSort.IsBankInSort() then
                TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
                return
            end

            self.bagScript:EnterBatch()
            self.StopBatch()
        end)

        UIHelper.BindUIEvent(self.BtnBatchTakeOut, EventType.OnClick, function()
            if PropsSort.IsBagInSort() or PropsSort.IsBankInSort() then
                TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
                return
            end

            self.bagScript:CancelBatch()
            self.StartBatch()
        end)

        UIHelper.BindUIEvent(self.BtnBatchApply, EventType.OnClick, function()
            if PropsSort.IsBagInSort() or PropsSort.IsBankInSort() then
                TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
                return
            end
            self.ConfirmBatch()
        end)

        UIHelper.BindUIEvent(self.BtnBatchCancel, EventType.OnClick, function()
            self.StopBatch()
        end)
    end

    -- 使用ScrollList的仓库在整体刷新的时候需要调用该函数
    function WarehouseData.ClearCellScript()
        self.tbCellScripts = {}
    end

    function WarehouseData.DeselectAll()
        self.dwItemID = nil
        self.tbPos = { nBox = nil, nIndex = nil }
        self.DoUpdateSelect(nil)
    end

    function WarehouseData.TraverseCellScript(func)
        for nBoxKey, tbScriptList in pairs(self.tbCellScripts) do
            for nIndexKey, Script in pairs(tbScriptList) do
                func(Script, nBoxKey - 1, nIndexKey - 1)
            end
        end
    end

    function WarehouseData.StartBatch()
        self.DeselectAll()
        self.bBatchSelect = true
        WarehouseData.dwItemID = nil
        WarehouseData.tbBatch = {}
        WarehouseData.UpdateBatchSelectNum()

        local traverseFunc = function(CellScript, _nBox, _nIndex)
            local ItemScript = CellScript:GetItemScript()
            if ItemScript then
                ItemScript:SetSelectMode(true, true)
            end
        end

        self.TraverseCellScript(traverseFunc)

        UIHelper.SetVisible(self.WidgetDiscardAnchor, true)
        UIHelper.SetVisible(self.WidgetXunBaoAnchor, false)
        UIHelper.SetVisible(self.WidgetBaiZhanSearch, false)

        if self.warehouseScript.szWareHouseType == WareHouseType.Role then
            UIHelper.SetVisible(self.BtnScreen, false)
        end
        if self.warehouseScript.szWareHouseType == WareHouseType.Account then
            UIHelper.SetVisible(self.WidgetTemporaryWarehouse, false)
        end
    end

    function WarehouseData.ConfirmBatch()
        if IsTableEmpty(WarehouseData.tbBatch) then
            return
        end
        local szMsg = g_tStrings.tbItemString.BATCH_TAKEOUT_ITEM_CONFIRM
        local confirmDialog = UIHelper.ShowConfirm(szMsg, function()
            self.bProcessBatch = true
            self.ProcessBatch()
        end)

    end

    function WarehouseData.StopBatch()
        if not self.bBatchSelect then
            return
        end

        self.DeselectAll()
        self.bBatchSelect = false
        self.bProcessBatch = false

        WarehouseData.tbBatch = {}

        local traverseFunc = function(CellScript, _nBox, _nIndex)
            local ItemScript = CellScript:GetItemScript()
            if ItemScript then
                ItemScript:SetSelectMode(false, true)
                Event.Dispatch(EventType.OnSetUIItemIconChoose, false, _nBox, _nIndex, 0)
            end
        end

        self.TraverseCellScript(traverseFunc)

        UIHelper.SetVisible(self.WidgetDiscardAnchor, false)
        UIHelper.SetVisible(self.WidgetXunBaoAnchor, false)
        UIHelper.SetVisible(self.WidgetBaiZhanSearch, true)

        if self.warehouseScript.szWareHouseType == WareHouseType.Role then
            UIHelper.SetVisible(self.BtnScreen, true)
        end
        if self.warehouseScript.szWareHouseType == WareHouseType.Account then
            UIHelper.SetVisible(self.WidgetTemporaryWarehouse, fnAccountHasTemporary())
        end
    end

    function WarehouseData.ProcessBatch()
        if WarehouseData.tbBatch and table.get_len(WarehouseData.tbBatch) > 0 and self.fnTakeOut then
            for dwItemID, tInfo in pairs(WarehouseData.tbBatch) do
                local nBox, nIndex = tInfo.nBox, tInfo.nIndex -- 只执行一次，对队伍的道具进行交换操作
                self.fnTakeOut(nBox, nIndex, tInfo.nStackNum)
                WarehouseData.tbBatch[dwItemID] = nil

                WarehouseData.UpdateBatchSelectNum()
                break
            end
        end

        if WarehouseData.tbBatch and table.get_len(WarehouseData.tbBatch) == 0 then
            self.StopBatch()
        end
    end

    -- 注册UIPanelHalfWareHouse中需要用到的节点
    function WarehouseData.RegisterNode(script)
        self.WidgetItemCard = script.WidgetItemCard
        self.WidgetDiscardAnchor = script.WidgetDiscardAnchor
        self.WidgetBaiZhanSearch = script.WidgetBaiZhanSearch
        self.WidgetXunBaoAnchor = script.WidgetXunBaoAnchor
        self.BtnScreen = script.BtnScreen
        self.LabelBatchNum = script.LabelBatchNum
        self.BtnPutIn = script.BtnPutIn
        self.BtnBatchTakeOut = script.BtnBatchTakeOut
        self.BtnBatchApply = script.BtnBatchApply
        self.BtnBatchCancel = script.BtnBatchCancel
        self.BtnBatchCancel = script.BtnBatchCancel
        self.LayoutScrollList = script.LayoutScrollList
        self.warehouseScript = script

        self.bagScript = ItemData.GetBagScript() ---@type UIBagView
    end

    -------------------------General---------------------------

    function WarehouseData.GetItemByPos(dwASPSource)
        if g_pClientPlayer then
            local nBox, nIndex = WarehouseData.tbPos.nBox, WarehouseData.tbPos.nIndex
            if dwASPSource ~= nil then
                return ItemData.GetPlayerItem(g_pClientPlayer, nBox, nIndex, UI_BOX_TYPE.SHAREPACKAGE, dwASPSource)
            else
                return ItemData.GetPlayerItem(g_pClientPlayer, nBox, nIndex)
            end
        end
    end

    function WarehouseData.OnItemSelectChange(dwItemID, bSelected, dwASPSource)
        if self.bUpdatingCell then
            return
        end

        if bSelected then
            self.DoUpdateSelect(dwItemID, dwASPSource)
            if self.bBatchSelect then
                local nBox, nIndex = WarehouseData.tbPos.nBox, WarehouseData.tbPos.nIndex
                local hItem = WarehouseData.GetItemByPos(dwASPSource)
                local nStackNum = ItemData.GetItemStackNum(hItem)

                local fnDeselect = function()
                    Timer.AddFrame(self, 1, function()
                        local scriptCell = self.GetCellScript(nBox, nIndex)
                        if scriptCell then
                            local itemScript = scriptCell:GetItemScript()
                            if itemScript then
                                itemScript:RawSetSelected(false)
                            end
                        end
                    end)
                end
                if table.get_len(WarehouseData.tbBatch) >= self.nBatchMaxCount then
                    fnDeselect()
                    TipsHelper.ShowImportantRedTip(WARE_HOUSE_BATCH_EXCEED_TIPS)
                    return
                end

                if nBox and nIndex then
                    Event.Dispatch(EventType.OnSetUIItemIconChoose, true, nBox, nIndex, nStackNum)
                end
                WarehouseData.tbBatch[dwItemID] = { nBox = nBox, nIndex = nIndex, nStackNum = nStackNum }
            end
        else
            if self.bBatchSelect then
                local nBox, nIndex = WarehouseData.tbPos.nBox, WarehouseData.tbPos.nIndex
                if nBox and nIndex then
                    Event.Dispatch(EventType.OnSetUIItemIconChoose, false, nBox, nIndex, 0)
                end
                WarehouseData.tbBatch[dwItemID] = nil
            end
            if WarehouseData.dwItemID == dwItemID then
                self.DoUpdateSelect(nil, dwASPSource)
            end
        end

        if self.bBatchSelect then
            Event.Dispatch(EventType.OnWareHouseBatchNumberChange)
            self.UpdateBatchSelectNum(dwItemID, bSelected)
        end
    end

    function WarehouseData.DoUpdateSelect(dwItemID, dwASPSource)
        WarehouseData.dwItemID = dwItemID
        if WarehouseData.dwItemID then
            local nBox, nIndex = WarehouseData.tbPos.nBox, WarehouseData.tbPos.nIndex
            if not nBox or not (table.contain_value(ItemData.BoxSet.Bag, nBox)
                    or (nBox >= WARE_HOUSE_MIN_INDEX and nBox <= WARE_HOUSE_MAX_INDEX)) then
                local item = WarehouseData.GetItemByPos(dwASPSource) -- 用选中的格子信息找到新的选中道具
                if item then
                    WarehouseData.dwItemID = item.dwID
                else
                    WarehouseData.tbPos = { nBox = nil, nIndex = nil } -- 选中的格子中页没有新的道具，无选中
                end
            else
                WarehouseData.tbPos = { nBox = nBox, nIndex = nIndex }
            end
        else
            WarehouseData.tbPos = { nBox = nil, nIndex = nil }
        end
        self.UpdateSelectedItemDetails(dwASPSource)
    end

    function WarehouseData.UpdateSelectedItemDetails(dwASPSource)
        self.scriptItemTip = self.scriptItemTip or UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemCard)

        local fnCallback
        if not self.bBatchSelect then
            fnCallback = function(nCount, nBox, nIndex)
                if PropsSort.IsBagInSort() or PropsSort.IsBankInSort() then
                    TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
                    return
                end
                if self.fnTakeOut then
                    self.fnTakeOut(nBox, nIndex, nCount, dwASPSource)
                end
                Event.Dispatch(EventType.HideAllHoverTips)
            end
        end

        local nBox, nIndex = WarehouseData.tbPos.nBox, WarehouseData.tbPos.nIndex
        local hItem = self.GetItemByPos(dwASPSource)
        local szCountTitle = "取出数量："
        local szConfirmLabel = self.bBatchSelect and g_tStrings.STR_DISCARD_SURE or g_tStrings.tbItemString.TAKEOUT_ITEM_CONFIRM_DIALOG_BUTTON_NAME
        if hItem then
            local nStackNum = ItemData.GetItemStackNum(hItem)
            if self.bBatchSelect then
                self.scriptItemTip:SetFunctionButtons({})
                self.scriptItemTip:ShowPlacementBtn(true, nStackNum, nStackNum, szConfirmLabel, szCountTitle, fnCallback)
            else
                local tbFuncButtons = {}
                if hItem.nSub == EQUIPMENT_SUB.PACKAGE and self.warehouseScript.szWareHouseType == WareHouseType.Role then
                    table.insert(tbFuncButtons, { szName = g_tStrings.USE, OnClick = function()
                        if PropsSort.IsBankInSort() then
                            TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
                            return
                        end
                        Event.Dispatch(EventType.OnWareHouseUseExpandItem, WarehouseData.dwItemID)
                    end })
                end
                self.scriptItemTip:ShowWareHouseSlider(nStackNum, nStackNum, szConfirmLabel, szCountTitle, fnCallback, tbFuncButtons)
                self.scriptItemTip:ShowWareHousePreviewSlider(hItem.dwTabType, hItem.dwIndex)
            end
        end

        local bAccount = self.warehouseScript.szWareHouseType == WareHouseType.Account
        self.scriptItemTip:SetForbidShowEquipCompareBtn(true)
        self.scriptItemTip:OnInit(WarehouseData.tbPos.nBox, WarehouseData.tbPos.nIndex, bAccount, dwASPSource)
        if self.scriptItemTip.scriptItemIcon then
            self.scriptItemTip.scriptItemIcon:ShowEquipScoreArrow(true)
        end
    end

    function WarehouseData.StoreCellScript(nBox, nIndex, script)
        local arr = self.tbCellScripts
        arr[nBox + 1] = arr[nBox + 1] or {}
        arr[nBox + 1][nIndex + 1] = script
    end

    function WarehouseData.GetCellScript(nBox, nIndex)
        local tbWareHouseScriptArr = self.tbCellScripts

        if tbWareHouseScriptArr[nBox + 1] == nil then
            return nil
        end

        return tbWareHouseScriptArr[nBox + 1][nIndex + 1]
    end

    function WarehouseData.UpdateBatchSelectNum()
        if self.fnBatchMaxSizeFunc then
            self.nBatchMaxCount = self.fnBatchMaxSizeFunc() or 0
            self.nBatchMaxCount = math.min(self.nBatchMaxCount, WARE_HOUSE_BATCH_LIMIT)
            UIHelper.SetString(self.LabelBatchNum, string.format("%d/%d",
                    table.get_len(WarehouseData.tbBatch), self.nBatchMaxCount))
        end
    end

    -------------------------ScrollList------------------------

    function WarehouseData.RefreshScrollList(nUpdateType)
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

    function WarehouseData.UnInitScrollList()
        if self.tScrollList then
            self.tScrollList:Destroy()
            self.tScrollList = nil
        end
    end

    function WarehouseData.InitScrollList()
        self.UnInitScrollList()

        self.tScrollList = UIScrollList.Create({
            listNode = self.LayoutScrollList,
            nReboundScale = 1,
            bSlowRebound = true,
            fnGetCellType = function(nIndex)
                return PREFAB_ID.WidgetBagRow
            end,
            nSpace = 10,
            fnUpdateCell = function(cell, nIndex)
                self.UpdateBagRow(cell, nIndex)
            end,
        })
        self.tScrollList:SetScrollBarEnabled(true)
    end

    function WarehouseData.UpdateBagRow(cell, nIndex)
        if not cell then
            return
        end
        cell._keepmt = true

        local cellNodes = UIHelper.GetChildren(cell.LayoutBagItem)
        local nStartIndex = nItemCountOfEachRow * (nIndex - 1) + 1
        local nEndIndex = nItemCountOfEachRow * nIndex

        for i = nStartIndex, nEndIndex do
            local nNodeIndex = i - nStartIndex + 1
            local targetNode = cellNodes[nNodeIndex]
            local tbPos = self.nIndexToCellPos[i]          
            
            if tbPos then
                local cellScript = self.fnCellInit(targetNode, cell.LayoutBagItem, tbPos)
                if cellScript then
                    cellScript.bBagItem = false
                    if self.szWareHouseType ~= WareHouseType.Role and cellScript.UpdateBagImgType then
                        cellScript:UpdateBagImgType(-1) --只有个人仓库要显示背景图
                    end
                end
            elseif targetNode then
                ItemData.GetBagCellPrefabPool():Recycle(targetNode) -- 不存在时进行回收
            end
        end
    end

    function WarehouseData.RefreshDataOnly(bUpdateTotal)
        local player = g_pClientPlayer
        self.nIndexToCellPos = self.fnGetCellList()

        self.nCountOfRow = math.ceil((#self.nIndexToCellPos) / nItemCountOfEachRow)
        if bUpdateTotal then
            self.tScrollList:SetCellTotal(self.nCountOfRow)
        end
    end

    function WarehouseData.GetRangeOfLoadedCells()
        return self.tScrollList:GetIndexRangeOfLoadedCells()
    end

    function WarehouseData.IsScrollListEmpty()
        return #self.nIndexToCellPos <= 0
    end

    function WarehouseData.GetTotalCellSize()
        return #self.nIndexToCellPos
    end

    function WarehouseData.RemoveCell(node)
        local script = UIHelper.GetBindScript(node)
        if script then
            if script._nPrefabID ~= PREFAB_ID.WidgetBagBottom then
                UIHelper.RemoveFromParent(node, true)
            else
                ItemData.GetBagCellPrefabPool():Recycle(node)
            end
        end
    end

    function WarehouseData.UpdateListSize()
        if self.tScrollList then
            self.tScrollList:UpdateListSize()
        end
    end

    function WarehouseData.GetWareHouseCells()
        if self.szWareHouseType == WareHouseType.Homeland or self.szWareHouseType == WareHouseType.BaiZhan or self.szWareHouseType == WareHouseType.Extract then
            return {}
        end
        return self.tScrollList and self.tScrollList.m.tCells or {}
    end

    -------------------------------------------------

    --- 从仓库取出时的回调
    function WarehouseData.SetItemTipCallback(fnEx)
        self.fnTakeOut = fnEx
    end

    --- 获取批量最大值的回调
    function WarehouseData.SetBatchMaxSizeFunc(fnEx)
        self.fnBatchMaxSizeFunc = fnEx
    end

    --- 每个道具格的初始函数
    function WarehouseData.SetCellInitFunc(fnEx)
        self.fnCellInit = fnEx
    end

    --- 获取道具列表
    function WarehouseData.SetGetCellListFunc(fnEx)
        self.fnGetCellList = fnEx
    end

    Event.Reg(self, EventType.HideAllHoverTips, function(nBox, nIndex, bNewAdd)
        if WarehouseData.bBatchSelect and self.scriptItemTip then
            self.scriptItemTip:OnInit()
            return
        end
    end)

    Event.Reg(self, "BAG_ITEM_UPDATE", function(nBox, nIndex, bNewAdd)
        if WarehouseData.bBatchSelect and table.get_len(WarehouseData.tbBatch) > 0 and self.bProcessBatch then
            self.ProcessBatch()
        end
    end)

    Event.Reg(self, EventType.EmailBagItemSelected, function(nBox, nIndex, nCount)
        local player = g_pClientPlayer
        local item
        local bAccount = self.warehouseScript.szWareHouseType == WareHouseType.Account
        if bAccount then
            item = ItemData.GetPlayerItem(player, nBox, nIndex, UI_BOX_TYPE.SHAREPACKAGE, ACCOUNT_SHARED_PACKAGE_SOURCE.CURRENT)
        else
            item = ItemData.GetPlayerItem(player, nBox, nIndex)
        end

        if item and item.dwID == WarehouseData.dwItemID and WarehouseData.tbBatch and WarehouseData.tbBatch[item.dwID] then
            WarehouseData.tbBatch[item.dwID].nStackNum = nCount

            Event.Dispatch(EventType.OnSetUIItemIconChoose, true, nBox, nIndex, nCount)

            if WarehouseData.scriptItemTip then
                UIHelper.SetVisible(WarehouseData.scriptItemTip._rootNode, false)
            end
        end
    end)
end

WarehouseDragData = WarehouseDragData or {
    tbBagCell = {},
    fnExchange = nil,
    nBoxType = nil,
}

function WarehouseDragData.Clear()
    WarehouseDragData.tbBagCell = {}
end

function WarehouseDragData.Add(script)
    table.insert(WarehouseDragData.tbBagCell, script)
end

---@note 设置交换时的函数
function WarehouseDragData.SetExchangeFunc(fnEx)
    WarehouseDragData.fnExchange = fnEx
end

---@note 设置当前仓库的类型
function WarehouseDragData.SetUIBoxType(nType)
    WarehouseDragData.nBoxType = nType
end

local UIPanelHalfWareHouse = class("UIPanelHalfWareHouse")

function UIPanelHalfWareHouse:OnEnter(szInitWareHouseType)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        self.szInitWareHouseType = szInitWareHouseType
        self.tbMoved = {}

        self.tWareHouseScriptDict = {}
        for _, szWareHouseNodeName in pairs(WareHouseType) do
            local node = self[szWareHouseNodeName]
            self.tWareHouseScriptDict[szWareHouseNodeName] = UIHelper.GetBindScript(node)
        end

        self.bagScript = ItemData.GetBagScript() ---@type UIBagViewNew
        self.navigationScript = UIHelper.GetBindScript(self.WidgetVertical_Navigation)---@type UIWidgetScrollViewTree

        WarehouseData.Init(self)
    end

    GetTongClient().ApplyOpenRepertory(1)
    self:InitNavigation()

    --if not self.bWaitForFaction then
    --   self:InitNavigation()
    --else
    --    GetTongClient().ApplyOpenRepertory(1) -- 向服务器申请打开帮会仓库页面
    --end
end

function UIPanelHalfWareHouse:OnExit()
    self.bInit = false
    self:UnRegEvent()

    WarehouseData.Clear()
    WarehouseData.UnInitScrollList()

    self.bagScript = ItemData.GetBagScript() ---@type UIBagViewNew
    if self.bagScript then
        self.bagScript:ExitWareHouseState()
    end
end

function UIPanelHalfWareHouse:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCloseLeft, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnClose2, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnJoinFaction, EventType.OnClick, function()
        local v = UISystemMenuTab[14] -- 查看帮会相关限制
        local tConfig = SystemOpen.GetSystemOpenCfg(v.nSystemOpenID)
        if SystemOpen.IsSystemOpen(tConfig.nID, true) then
            TongData.OpenTongPanel()
        end
    end)

    UIHelper.BindUIEvent(self.TogSearch, EventType.OnSelectChanged, function(tog, bSelected)
        if not bSelected then
            WarehouseData.ClearFilter()
        else
            local szText = UIHelper.GetString(self.EditBoxSearch)
            WarehouseData.szFilterUTF8 = szText
            WarehouseData.szFilter = UIHelper.UTF8ToGBK(szText)
        end

        Event.Dispatch(EventType.OnWarehouseFilterTextUpdate)
    end)

    UIHelper.RegisterEditBoxChanged(self.EditBoxSearch, function()
        WarehouseData.szFilterUTF8 = UIHelper.GetText(self.EditBoxSearch)
        WarehouseData.szFilter = UIHelper.UTF8ToGBK(WarehouseData.szFilterUTF8)
        Event.Dispatch(EventType.OnWarehouseFilterTextUpdate)
    end)
end

function UIPanelHalfWareHouse:RegEvent()
    Event.Reg(self, EventType.OnWarehouseCancelTouch, function()
        self:OnItemTouchCanceled()
    end)
    
    Event.Reg(self, EventType.OnWarehouseExpireItemUpdate, function(bShowExpireIcon)
        self:UpdateWareHouseExpire(bShowExpireIcon)
    end)

    Event.Reg(self, "OPEN_TONG_REPERTORY", function(arg0)
        if self.bWaitForFaction then
            self:InitNavigation()
            self.bWaitForFaction = false
        end
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        Timer.AddFrame(self, 5, function()
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewChildTab)
            --UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollItemList)
        end)
    end)

    Event.Reg(self, EventType.BagItemLongPress, function(_, _, _, _, itemScript)
        if not self.tbMoved.dragScript or itemScript.nBox ~= self.tbMoved.nFirstBox or itemScript.nIndex ~= self.tbMoved.nFirstIndex then
            return
        end
        self.tbMoved.bLongPress = true
        WarehouseData.tScrollList:SetScrollEnabled(false)
        UIHelper.SetVisible(self.tbMoved.dragScript._rootNode, true)
    end)

    Event.Reg(self, EventType.OnCloseHomelandLocker, function()
        if self:GetCurWareHouseType() == WareHouseType.Homeland then
            UIMgr.Close(self)
        end
    end)

    -- Scrolllist 相关 begin ----------------------------------------------

    Event.Reg(self, EventType.OnUIScrollListTouchBegan, function(x, y, tScrollList)
        if WarehouseData.tScrollList == tScrollList then
            if PropsSort.IsBankInSort() then
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
end

function UIPanelHalfWareHouse:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
local function CheckPlayerIsRemote(dwPlayerID)
    if not dwPlayerID then
        local pPlayer = GetClientPlayer()
        if not pPlayer then
            return false
        end
        dwPlayerID = pPlayer.dwID
    end
    return IsRemotePlayer(dwPlayerID)
end

function UIPanelHalfWareHouse:InitNavigation()
    if not g_pClientPlayer then
        return
    end

    local tNavigationData = {}
    local nFirstIndex = 1
    for nIndex, tInfo in ipairs(tWareHouseInfoList) do
        local fnTitleSelected = function(bSelected, scriptContainer)
            if bSelected then
                Event.Dispatch(EventType.OnTeachButtonClick, VIEW_ID.PanelHalfWarehouse, tInfo.szWareHouseType)
                if self.currentScript then
                    self.currentScript:OnExit()
                end

                WarehouseData.StopBatch()
                WarehouseData.Clear()
                WarehouseData.BindUIEvent()
                WarehouseData.ClearFilter()

                UIHelper.SetText(self.EditBoxSearch, "")
                self:ResetNodeState()
                self:OnItemTouchCanceled()
                self.currentScript = self.tWareHouseScriptDict[tInfo.szWareHouseType]
                self:SetTitle(tInfo.szTitle)
                self.szWareHouseType = tInfo.szWareHouseType
                WarehouseData.szWareHouseType = tInfo.szWareHouseType

                if self:CanOpenWareHouse(tInfo.szWareHouseType) then
                    self.currentScript:OnEnter()
                else
                    self.bagScript:ExitWareHouseState()
                    self:ShowUnavailableState(tInfo)
                end

                UIHelper.CascadeDoLayoutDoWidget(self.LayoutBtnLeft, true, false)
                UIHelper.LayoutDoLayout(self.LayoutSideButton)
                UIHelper.LayoutDoLayout(self.LayoutLeft)
                UIHelper.LayoutDoLayout(self.LayoutRightBtns)
                UIHelper.LayoutDoLayout(self.LayoutBaiZhanBtn)
            end
        end

        local titleData = { tArgs = { szTitle = tInfo.szName, szIconPath = tInfo.szIconPath }, fnSelectedCallback = fnTitleSelected, tItemList = nil }
        table.insert(tNavigationData, titleData)

        if self.szInitWareHouseType and self.szInitWareHouseType == tInfo.szWareHouseType then
            nFirstIndex = #tNavigationData
        end
    end

    ---@param scriptContainer UIScrollViewTreeContainer
    local func = function(scriptContainer, tArgs)
        UIHelper.SetString(scriptContainer.LabelTitle, tArgs.szTitle)
        UIHelper.SetString(scriptContainer.LabelSelect, tArgs.szTitle)
        if tArgs.szIconPath then
            UIHelper.SetSpriteFrame(scriptContainer.ImgIcon, tArgs.szIconPath .. "02")
            UIHelper.SetSpriteFrame(scriptContainer.ImgSelectIcon, tArgs.szIconPath .. "01")
        end
    end

    self.navigationScript:SetOuterInitSelect(false)
    UIHelper.SetupScrollViewTree(self.navigationScript, PREFAB_ID.WidgetWarehouseTab, PREFAB_ID.WidgetWarehouseChild,
            func, tNavigationData)

    Timer.AddFrame(self, 2, function()
        local scriptContainer = self.navigationScript.tContainerList[nFirstIndex].scriptContainer
        UIHelper.SetSelected(scriptContainer.ToggleSelect, true)
        --UIHelper.ScrollToIndex(scriptContainer.ScrollViewContent, nFirstIndex)
    end)

    self:UpdateWareHouseExpire()
end

function UIPanelHalfWareHouse:SetTitle(szTitle)
    UIHelper.SetString(self.LabelTitle, szTitle)
end

function UIPanelHalfWareHouse:ResetNodeState()
    local tChilds = UIHelper.GetChildren(self.LayoutBtnLeft)
    for _, node in ipairs(tChilds) do
        if node.forceDoLayout then
            local lst = UIHelper.GetChildren(node)
            for _, _node in ipairs(lst) do
                UIHelper.SetVisible(_node, false)
            end
        else
            UIHelper.SetVisible(node, false)
        end
    end

    UIHelper.SetVisible(self.LayoutScrollList, false)
    UIHelper.SetVisible(self.ScrollBag, true)

    UIHelper.SetVisible(self.WidgetRoleList, false)
    UIHelper.SetVisible(self.BtnBagUpgrade, false)
    UIHelper.SetVisible(self.BtnChange_ToType, false)
    UIHelper.SetSelected(self.BtnChange_ToType, false)
    UIHelper.SetVisible(self.BtnRefresh, false)
    UIHelper.SetVisible(self.BtnSaveAll, false)
    UIHelper.SetVisible(self.BtnCombine, false)
    UIHelper.SetVisible(self.BtnDescription, false)
    UIHelper.SetVisible(self.BtnBatchSell, false)
    UIHelper.SetVisible(self.BtnScreen, false)
    UIHelper.SetVisible(self.TogCompareBag, false)
    UIHelper.SetVisible(self.BtnJoinFaction, false)
    UIHelper.SetVisible(self.WidgetChildTab, false)
    UIHelper.SetVisible(self.WidgetChildTabArrowParent, false)

    UIHelper.SetVisible(self.LayoutFunction, false)
    UIHelper.SetVisible(self.WidgetEmpty, false)
    UIHelper.SetVisible(self.WidgetUnavailable, false)

    UIHelper.SetVisible(self.TogBanZhanBookClose, false)
    UIHelper.SetVisible(self.BtnBookOpen, false)

    UIHelper.SetVisible(self.WidgetWareHouseUp, false)
    UIHelper.SetVisible(self.WidgetBottom, true)
    UIHelper.SetVisible(self.WidgetBaiZhanSearch, false)

    UIHelper.SetVisible(self.BtnFlowerPrice, false)
    UIHelper.SetVisible(self.BtnConfiguration, false)
    UIHelper.SetVisible(self.BtnTemporaryHouse, false)
    UIHelper.SetSelected(self.TogSearch, false)

    UIHelper.SetVisible(self.LabelTitleSize, true)
    UIHelper.SetVisible(self.WidgetDiscardAnchor, false)
    UIHelper.SetVisible(self.WidgetXunBaoAnchor, false)
    UIHelper.SetVisible(self.BtnEquip, false)
end

function UIPanelHalfWareHouse:CanOpenFaction()
    if not g_pClientPlayer then
        return false
    end

    local bLocked = BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TONG_REPERTORY)
    local bNoFaction = g_pClientPlayer.dwTongID == 0
    local bHasLimit = g_pClientPlayer.bFreeLimitFlag
    return not (bLocked or bNoFaction or bHasLimit)
end

function UIPanelHalfWareHouse:IsWareHouseAvailable()
    local scene = g_pClientPlayer.GetScene()
    --local bPlayerTake = g_pClientPlayer.GetOperationState(PLAYER_OPERATION_TYPE.DISABLE_BANK_PUT) == false
    --local bPlayerPut = g_pClientPlayer.GetOperationState(PLAYER_OPERATION_TYPE.DISABLE_BANK_PUT) == false
    --local bPlayer = g_pClientPlayer.GetOperationState(PLAYER_OPERATION_TYPE.DISABLE_BANK_PUT) == false
    local bPlayer = true
    local bMap = scene.GetMapOperationState(MAP_OPERATION_TYPE.DISABLE_BANK) == false
    return bPlayer and bMap
end

function UIPanelHalfWareHouse:CanOpenWareHouse(szWareHouseType)
    if not g_pClientPlayer or (CheckPlayerIsRemote() and szWareHouseType ~= WareHouseType.BaiZhan) then
        return false
    end

    if szWareHouseType == WareHouseType.Faction then
        return self:IsWareHouseAvailable() and self:CanOpenFaction()  -- 帮会仓库限制
    end

    -- if szWareHouseType == WareHouseType.Homeland then
    --     local dwMapID = g_pClientPlayer.GetMapID()  -- 家园仓库限制
    --     return HomelandData.IsHomelandMap(dwMapID) or HomelandData.IsHomelandCommunityMap(dwMapID)
    -- end

    if szWareHouseType == WareHouseType.BaiZhan then
        local scene = g_pClientPlayer.GetScene()
        local dwMapID = scene and scene.dwMapID or 0
        return dwMapID == MonsterBookData.PLAY_MAP_ID
    end

    if szWareHouseType == WareHouseType.Role then
        return self:IsWareHouseAvailable()
    end

    if szWareHouseType == WareHouseType.Horse then
        local scene = g_pClientPlayer.GetScene()
        local dwMapID = scene and scene.dwMapID or 0
        local _, nMapType = GetMapParams(dwMapID)
        return nMapType == 0 or nMapType == MAP_TYPE.HOMELAND --新增马厩限制判断
    end

    return true
end

function UIPanelHalfWareHouse:ShowUnavailableState(tInfo)
    local szWareHouseType = tInfo.szWareHouseType
    local bDontHaveFaction = szWareHouseType == WareHouseType.Faction and g_pClientPlayer.dwTongID == 0
    local szMsg = tInfo.szUnavailableMsg

    local bPlayer = g_pClientPlayer.GetOperationState(PLAYER_OPERATION_TYPE.DISABLE_BANK) == false
    if szWareHouseType == WareHouseType.Faction or szWareHouseType == WareHouseType.Role then
        szMsg = not bPlayer and ("当前状态无法使用" .. tInfo.szTitle) or szMsg
    end

    if bDontHaveFaction and self:IsWareHouseAvailable() then
        szMsg = "暂无帮会，请前往加入帮会"
        UIHelper.SetVisible(self.BtnJoinFaction, true)
    end

    if CheckPlayerIsRemote() then
        szMsg = "跨服中禁止使用" .. tInfo.szTitle
        UIHelper.SetVisible(self.BtnJoinFaction, false)
    end

    UIHelper.SetVisible(self.WidgetUnavailable, true)
    UIHelper.SetVisible(self.LabelTitleSize, false)
    UIHelper.SetString(self.LabelUnavailableDesc, szMsg)

end

function UIPanelHalfWareHouse:UpdateWareHouseExpire(bShowExpireIcon)
    local scriptContainer = self.navigationScript.tContainerList[1].scriptContainer
    if bShowExpireIcon == nil then
        UIHelper.SetVisible(scriptContainer.ImgTimeOut, ItemData.IsRoleWareHouseContainExpiringItem())
    else
        UIHelper.SetVisible(scriptContainer.ImgTimeOut, bShowExpireIcon)
    end
end

-------------------------WareHouse------------------------------------

local ITEM_DRAG_ACC = -0.1
local TIME_TO_MAX_SPEED = 2
local STANDARD_MOVE_SPEED = 10
local MAX_INCREMENT_SPEED = 30

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

function UIPanelHalfWareHouse:GetScrollListItems()
    -- 取代原self.tbMoved.tbBagCell，避免快速拖动时发生scrolllist节点和缓存节点不同步导致safe_check无法通过的问题
    local tbScripts = {}
    if not WarehouseData.tScrollList or not WarehouseData.tScrollList.m then
        return tbScripts
    end

    self.tbMoved.wareHouseCells = WarehouseData.GetWareHouseCells()
    self.tbMoved.bagCells = self.bagScript.tScrollList.m.tCells

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

function UIPanelHalfWareHouse:OnItemTouchBegin(x, y)
    self:ClearMovedParam(true)

    if (not self.currentScript) or WarehouseData.bBatchSelect or self.bagScript.bBatchSelect
            or not (self.szWareHouseType == WareHouseType.Role or self.szWareHouseType == WareHouseType.Account
            or self.szWareHouseType == WareHouseType.Faction or self.szWareHouseType == WareHouseType.Horse) then
        return
    end

    self.tbMoved.nFinalX, self.tbMoved.nFinalY = x, y
    for _, cellScript in ipairs(self:GetScrollListItems()) do
        if JudgeInNode(x, y, cellScript._rootNode) then
            local item = ItemData.GetPlayerItem(g_pClientPlayer, cellScript.nBox, cellScript.nIndex, WarehouseDragData.nBoxType)
            if item then
                self.tbMoved.bTouchItem = true

                self.tbMoved.nFirstBox = cellScript.nBox
                self.tbMoved.nFirstIndex = cellScript.nIndex
                self.tbMoved.clickScript = cellScript
                self.tbMoved.changeNode = cellScript._rootNode
                self.tbMoved.originalItemScript = cellScript:GetItemScript()
                
                local tParent = self.WidgetAniLeft
                self.tbMoved.dragScript = self.tbMoved.dragScript or UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, tParent)
                self.tbMoved.dragScript:OnInit(cellScript.nBox, cellScript.nIndex, false, WarehouseDragData.nBoxType == UI_BOX_TYPE.SHAREPACKAGE)
                UIHelper.SetScale(self.tbMoved.dragScript._rootNode, 0.5, 0.5)
                local nLocalX, nLocalY = UIHelper.ConvertToNodeSpace(tParent, x, y)
                UIHelper.SetPosition(self.tbMoved.dragScript._rootNode, nLocalX, nLocalY, tParent)
                UIHelper.SetVisible(self.tbMoved.dragScript._rootNode, false)
            end

            -- print("begin===================" .. cellScript.nIndex)
            return
        end
    end
end

function UIPanelHalfWareHouse:OnItemTouchMoved(x, y)
    if not self.tbMoved.bTouchItem or not self.tbMoved.bLongPress then
        return
    end
    
    local nBox = self.tbMoved.originalItemScript.nBox
    local nIndex = self.tbMoved.originalItemScript.nIndex
    local bSetOpacity = false
    if nBox == self.tbMoved.nFirstBox and nIndex == self.tbMoved.nFirstIndex then
        bSetOpacity = true
    end
    UIHelper.SetOpacity(self.tbMoved.originalItemScript._rootNode, bSetOpacity and 125 or 255)

    self.tbMoved.nFinalX, self.tbMoved.nFinalY = x, y
    if self.tbMoved.dragScript then
        local tParent = self.WidgetAniLeft
        local nLocalX, nLocalY = UIHelper.ConvertToNodeSpace(tParent, x, y)  -- 鼠标跟点画image
        UIHelper.SetPosition(self.tbMoved.dragScript._rootNode, nLocalX, nLocalY, tParent)
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
                self.tbMoved.clickScript = cellScript
                -- print("moved===================" .. cellScript.nIndex)
                UIHelper.SetVisible(cellScript.ImgSelect, true)
                bFindClickScript = true
                break
            end
        end
    end

    if not JudgeInNode(x, y, self.ScrollBag) then
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

function UIPanelHalfWareHouse:OnItemTouchEnd()
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
        if self.tbMoved.nFirstBox ~= nSecondBox or self.tbMoved.nFirstIndex ~= nSecondIndex
                and WarehouseDragData.fnExchange then
            if bBagItem and self.szWareHouseType == WareHouseType.Account then
                ItemData.TakeItemFromAccountSharedPackage(ACCOUNT_SHARED_PACKAGE_SOURCE.CURRENT, self.tbMoved.nFirstBox, self.tbMoved.nFirstIndex, nSecondBox, nSecondIndex)
            else
                WarehouseDragData.fnExchange(self.tbMoved.nFirstBox, self.tbMoved.nFirstIndex, nSecondBox, nSecondIndex)
            end
        end
    end
    
    self:ClearMovedParam()
end

-- end不在ScrollBag范围内的
function UIPanelHalfWareHouse:OnItemTouchCanceled()
    if not self.tbMoved.bTouchItem or not self.tbMoved.bLongPress then
        return
    end
    
    self:ClearMovedParam()
end

function UIPanelHalfWareHouse:ClearMovedParam()
    local drag = self.tbMoved.dragScript
    
    if self.tbMoved.clickScript then
        UIHelper.SetVisible(self.tbMoved.clickScript.ImgSelect, false)
    end
    
    if self.tbMoved.originalItemScript and self.tbMoved.originalItemScript then
        UIHelper.SetOpacity(self.tbMoved.originalItemScript._rootNode, 255)
        self.tbMoved.originalItemScript:ClearLongPressState()
    end

    if drag then
        UIHelper.SetVisible(drag._rootNode, false)
    end

    if self.tbMoved.nScrollTime then
        Timer.DelTimer(self, self.tbMoved.nScrollTime)
        self.tbMoved.nScrollTime = nil
    end

    WarehouseData.tScrollList:SetScrollEnabled(true)
    self.tbMoved = {dragScript = drag}
end

local function _GetScorllSpeed(nStayTime, nFpsLimit)
    nFpsLimit = nFpsLimit or GetFpsLimit()
    nStayTime = nStayTime or 0
    local nDelta = STANDARD_MOVE_SPEED + MAX_INCREMENT_SPEED / (1 + math.exp(ITEM_DRAG_ACC * (nStayTime - nFpsLimit * TIME_TO_MAX_SPEED)))
    return nDelta
end

function UIPanelHalfWareHouse:AutoScrollUpdate(bMove, direction)
    if bMove and not self.tbMoved.bEnterMove and WarehouseData.tScrollList:_IsCanDrag() then
        if self.tbMoved.nScrollTime then
            Timer.DelTimer(self, self.tbMoved.nScrollTime)
            self.tbMoved.nScrollTime = nil
        end
        local nStayTime = 0
        local nFpsLimit = GetFPS()
        self.tbMoved.nScrollTime = Timer.AddFrameCycle(self, 1, function()
            if WarehouseData.tScrollList:GetPercentage() <= 1.2 then
                local nDelta = _GetScorllSpeed(nStayTime, nFpsLimit) * direction
                WarehouseData.tScrollList:_SetContentPosWithOffset(nDelta, false)
                nStayTime = nStayTime + 1
            end
        end)
        self.tbMoved.bEnterMove = true
    elseif not bMove then
        WarehouseData.tScrollList:SetScrollEnabled(false)
        self.tbMoved.bEnterMove = false
        if self.tbMoved.nScrollTime then
            Timer.DelTimer(self, self.tbMoved.nScrollTime)
            self.tbMoved.nScrollTime = nil
        end
    end
end

-- 拖动背包格子相关 end ----------------------------------------------

function UIPanelHalfWareHouse:GetCurWareHouseType()
    if not self.szWareHouseType then
        return WareHouseType.Role
    end

    return self.szWareHouseType
end

return UIPanelHalfWareHouse