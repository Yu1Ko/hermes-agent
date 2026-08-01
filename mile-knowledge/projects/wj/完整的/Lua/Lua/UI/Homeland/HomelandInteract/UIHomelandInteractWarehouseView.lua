-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandInteractWarehouseView
-- Date: 2023-08-24 10:37:43
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandInteractWarehouseView = class("UIHomelandInteractWarehouseView")
local tLockerInfo = Table_GetHomelandLockerInfo()
local tbRegUpdateEvent = {
    "REMOTE_PLANT_WAREHOUSE1_EVENT",    -- 对应类型物品存取触发事件
    "REMOTE_PLANT_WAREHOUSE2_EVENT",
    "REMOTE_FISH_WAREHOUSE2_EVENT",
    "REMOTE_QIWUPU_WAREHOUSE1_EVENT",
    "REMOTE_PERFUME_WAREHOUSE1_EVENT",
    "REMOTE_SERVANT_WAREHOUSE2_EVENT",
    "REMOTE_SELLER_WAREHOUSE1_EVENT",
}
local tWarehouseFilterCheck =
{
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
    [1] = { szFilter = "全部物品", bTakeOutAll = false, bShowEmptyCell = true, filterFunc = function(nClassType)
        return true
    end },
    [2] = { szFilter = "种植材料", bTakeOutAll = true, bShowEmptyCell = false, filterFunc = function(nClassType)
        return nClassType == 1
    end },
    [3] = { szFilter = "种植作物", bTakeOutAll = true, bShowEmptyCell = false, filterFunc = function(nClassType)
        return nClassType == 2
    end },
    [4] = { szFilter = "宠物出行", bTakeOutAll = true, bShowEmptyCell = false, filterFunc = function(nClassType)
        return nClassType == 3
    end },
    [5] = { szFilter = "家园垂钓", bTakeOutAll = true, bShowEmptyCell = false, filterFunc = function(nClassType)
        return nClassType == 4
    end },
    [6] = { szFilter = "调香材料", bTakeOutAll = true, bShowEmptyCell = false, filterFunc = function(nClassType)
        return nClassType == 5
    end },
    [7] = { szFilter = "管家物品", bTakeOutAll = true, bShowEmptyCell = false, filterFunc = function(nClassType)
        return nClassType == 6
    end },
    [8] = { szFilter = "掌柜物品", bTakeOutAll = true, bShowEmptyCell = false, filterFunc = function(nClassType)
        return nClassType == 7
    end },
}

local tbCellScripts = {
    [UI_BatchType.WareHouse] = {},
    [UI_BatchType.Bag] = {}
}

local function _GetSubArray(aArray, nBeg, nEnd)
	local aSubArray = {}
	for i = nBeg, nEnd do
		table.insert(aSubArray, aArray[i])
	end
	return aSubArray
end

function UIHomelandInteractWarehouseView:OnEnter(tCurrentItem, bServant)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        self.bFirstOpen = true
    end
    self.tCurrentItem = tCurrentItem
    self.bServant = bServant or false --判断是不是管家进来的 --已弃用
    self.tbCellScripts = tbCellScripts
    self.tbTabCfg = tBagFilterCheck
    self.bBatchSelect = false
    self.nBagFilterIndex = 1
    self.nWarehouseFilterIndex = 1
    self:GetWarehouseInfo(0)
    self:UpdateInfo()
end

function UIHomelandInteractWarehouseView:OnExit()
    self.bInit = false
    TipsHelper.DeleteAllHoverTips(true)
    Timer.DelAllTimer(self)
end

function UIHomelandInteractWarehouseView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnLeaveWith, EventType.OnClick, function ()
        local tClass = {}
        if not self.bCanStore then
            return
        end
        if self.bServant then
            local player = GetClientPlayer()
            local eTargetType, nTargetID = player.GetTarget()
            RemoteCallToServer("On_HomeLand_ClearInventoryAll", eTargetType, nTargetID, 1)
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_LOCKER_STORESUCCESS)
            return
        end
		for _, v in ipairs(tWarehouseFilterCheck) do
			table.insert(tClass, v.DATAMANAGE)
		end
        local tBagLock = BagViewData.GetHomelandLockData()
		RemoteCallToServer("On_HomeLand_StoreAll", tClass, tBagLock)
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_LOCKER_STORESUCCESS)
    end)

    UIHelper.BindUIEvent(self.BtnTakeOut, EventType.OnClick, function ()
        if not table.is_empty(self.tbCellScripts[UI_BatchType.WareHouse]) then
            self.bBatchSelect = true
        end
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnTakeOutAll, EventType.OnClick, function ()
        self:UpdateBatchModeInfo(true)
        local _MAX_APPLY_COUNT = 10
		local nItemCount = #self.tbPickUpList
		local nRounds = math.ceil(nItemCount / _MAX_APPLY_COUNT)

		local i = 1
		Timer.AddCycle(self, 0.2, function()
			if i <= nRounds then
				local aParamItems = _GetSubArray(self.tbPickUpList, (i-1) * _MAX_APPLY_COUNT + 1, math.min(nItemCount, i * _MAX_APPLY_COUNT))
				if not table.is_empty(aParamItems) then
                    for index, tbItemInfo in ipairs(aParamItems) do
                        self:PickUpOneItem(tbItemInfo)
                    end
                end
				i = i + 1
			end
            if i >= nRounds then
                Timer.DelAllTimer(self)
            end
		end)
        self.bBatchSelect = false
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function ()
        self.bBatchSelect = false
        self:UpdateInfo()
    end)
end

function UIHomelandInteractWarehouseView:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function()
        self:CloseTip()
    end)

    Event.Reg(self, EventType.GetHomelandServantItemTab, function(tCurrentItem)
        if table.is_empty(tCurrentItem) then
            UIMgr.Close(self)
        end
        self:GetNewServantItemList(tCurrentItem)
    end)

    Event.Reg(self, EventType.OnViewOpen, function(nViewID)
        if nViewID == VIEW_ID.PanelOldDialogue then
            UIMgr.Close(self)
        end
    end)

    Event.Reg(self, EventType.OnHomeWarehouseUpdate, function()
        self.nUpdateTimer = self.nUpdateTimer or Timer.Add(self, 0.1, function ()
            self:UpdateInfo()
            self.nUpdateTimer = nil
        end)
    end)

    for _, event in ipairs(tbRegUpdateEvent) do -- 物品存取触发更新
        Event.Reg(self, event, function()
            Event.Dispatch(EventType.OnHomeWarehouseUpdate)
        end)
    end
end

function UIHomelandInteractWarehouseView:UpdateInfo()
    self:UpdateServantModeInfo()
    self:BatchModeCheck()
    self:RefreshWarehouseCells()
    self:RefreshBagCells()
    self:UpdateFilter()
end

function UIHomelandInteractWarehouseView:RefreshBagCells()
    UIHelper.RemoveAllChildren(self.ScrollViewBag)
    UIHelper.ScrollViewDoLayout(self.ScrollViewBag)
    self.tbCellScripts[UI_BatchType.Bag] = {}
    self.scriptCurBagIcon = nil
    self.bCanStore = false  --用于判断存入tip是否显示
    local tbSelectedTabCfg = self.tbTabCfg[self.nBagFilterIndex]
    local FirstItemScript = nil
    for _, tbItemInfo in ipairs(ItemData.GetItemList(ItemData.BoxSet.Bag)) do
        local bCanStore = false
        local nClassType = 0
        local item = ItemData.GetItemByPos(tbItemInfo.nBox, tbItemInfo.nIndex)
        if item then
            for _, v in ipairs(tLockerInfo) do
                if v.dwItemType == item.dwTabType and v.dwItemID == item.dwIndex then
                    bCanStore = true
                    nClassType = v.dwClassType
                    if (v.dwMaxNum - v.nCount) > 0 then
                        self.bCanStore = self.bCanStore or true
                    end
                end
            end
        end
        local bShowItem = tbItemInfo.hItem and tbSelectedTabCfg.filterFunc(nClassType)
        if bShowItem or tbSelectedTabCfg.bShowEmptyCell then
            local cellScript = UIHelper.AddPrefab(PREFAB_ID.WidgetBagBottom, self.ScrollViewBag)
            cellScript:OnEnter(tbItemInfo.nBox, tbItemInfo.nIndex)
            local itemScript = cellScript:GetItemScript()
            -- Timer.DelAllTimer(itemScript)
            if itemScript then
                table.insert(self.tbCellScripts[UI_BatchType.Bag], itemScript)
                itemScript:SetToggleGroupIndex(ToggleGroupIndex.BagItem)
                itemScript:SetSelectMode(false)
                itemScript:SetClickCallback(function()
                    self:CloseTip()
                    self.scriptCurBagIcon = itemScript
                    _, self.tipsScriptView = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, itemScript._rootNode)
                    self.tipsScriptView:SetForbidShowEquipCompareBtn(true)
                    self.tipsScriptView:OnInit(tbItemInfo.nBox, tbItemInfo.nIndex)
                    self.tipsScriptView:SetBtnState({})
                    if bCanStore and not self.bServant then
                        self.tipsScriptView:SetBtnState({{
                            szName = "存入",
                            OnClick = function()
                                self:StoreOneItem(item)
                            end
                        }})
                    end
                end)
            end

            if itemScript and not FirstItemScript then
                FirstItemScript = itemScript
            end
        end
    end

    if self.bFirstOpen or self.nBagFilterIndex ~= 1 then
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewBag)
        self.bFirstOpen = false
    end
    self:ItemEmptyCheck()
    local szBagSize = string.format("背包(%d/%d)",ItemData.GetBagUsedSize(ItemData.BoxSet.Bag), ItemData.GetBagSize(ItemData.BoxSet.Bag))
    UIHelper.SetString(self.LabelBag, szBagSize)
    UIHelper.ScrollViewDoLayout(self.ScrollViewBag)
end

function UIHomelandInteractWarehouseView:RefreshWarehouseCells()
    UIHelper.RemoveAllChildren(self.ScrollViewWareHouse)

    self.tbCellScripts[UI_BatchType.WareHouse] = {}

    local tbSelectedTabCfg = self.tbTabCfg[1]
    local bHasCell = false
    local FirstItemScript = nil

    local tbItemList = self:GetWarehouseInfo(self.nWarehouseFilterIndex - 1)
    for index, tbItemInfo in ipairs(tbItemList) do
        local bShowItem = tbItemInfo.hItem or false
        if bShowItem or tbSelectedTabCfg.bShowEmptyCell then
            local cellScript = UIHelper.AddPrefab(PREFAB_ID.WidgetBagBottom, self.ScrollViewWareHouse)
            if self.bServant then
                cellScript:OnInitWithTabID(tbItemInfo.nType, tbItemInfo.nID, tbItemInfo.nCount)
            else
                cellScript:OnInitWithTabID(tbItemInfo.dwItemType, tbItemInfo.dwItemID, tbItemInfo.nCount)
            end
            local itemScript = cellScript:GetItemScript()
            if itemScript then
                self:CloseTip()
                table.insert(self.tbCellScripts[UI_BatchType.WareHouse], itemScript)
                itemScript.tbItemInfo = {
                    dwItemType = tbItemInfo.dwItemType or nil,
                    dwItemID = tbItemInfo.dwItemID or nil,
                    nCount = tbItemInfo.nCount or nil,
                    dwClassType = tbItemInfo.dwClassType or nil,
                    dwDataIndex = tbItemInfo.dwDataIndex or nil,
                    nIndex = index --管家仓库取出道具用
                }
                itemScript:SetToggleGroupIndex(ToggleGroupIndex.BagItem)
                itemScript:SetSelectMode(self.bBatchSelect)
                itemScript:SetClickCallback(function(nTabType, nTabID)
                    if nTabType and nTabID then
                        if self.bBatchSelect then
                            self:UpdateBatchModeInfo()
                        end
                        self.nCurIconScript = itemScript
                        _, self.tipsScriptView = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, itemScript._rootNode)
                        self.tipsScriptView:OnInitWithTabID(nTabType, nTabID)
                        self.tipsScriptView:SetBtnState({{
                            szName = "取出",
                            OnClick = function()
                                if PropsSort.IsBagInSort() or PropsSort.IsBankInSort() then
                                    TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
                                    return
                                end
                                self:PickUpOneItem(itemScript.tbItemInfo)
                                self:CloseTip()
                                self:UpdateInfo()
                            end
                        }})
                        if self.bBatchSelect then   --批量取出时去掉按钮
                            self.tipsScriptView:SetBtnState({})
                        end
                    else
                        self:CloseTip()
                    end
                end)
            end

            if itemScript and not FirstItemScript then
                FirstItemScript = itemScript
            end

            bHasCell = true
        end
    end

    if bHasCell then
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewWareHouse)
    end
    self:ItemEmptyCheck()
end

function UIHomelandInteractWarehouseView:GetWarehouseInfo(dwFilterID)
    local tRetLocker = {}
    local pPlayer = GetClientPlayer()
    self.tWarehouseFilterCheck = tWarehouseFilterCheck
	if not pPlayer.RemoteDataAutodownFinish() then
		OutputMessage("MSG_SYS", g_tStrings.STR_TOYBOX_ERROR_MSG)
        UIMgr.Close(self)
	end

	for k, v in ipairs(tLockerInfo) do
		if v.dwClassType > 0 then
			local tFilter = self.tWarehouseFilterCheck[v.dwClassType]
			local nCount = pPlayer.GetRemoteArrayUInt(tFilter.DATAMANAGE, tFilter.ITEMSTART + (v.dwDataIndex - 1) * tFilter.BYTE_NUM, tFilter.BYTE_NUM)
            v.nCount = nCount or 0
		end
	end
	if dwFilterID == 0 then
		for k, v in ipairs(tLockerInfo) do
			if v.nCount > 0 then
				table.insert(tRetLocker, v)
			end
		end
	else
		for k, v in ipairs(tLockerInfo) do
			if dwFilterID == v.dwClassType and v.nCount > 0 then
				table.insert(tRetLocker, v)
			end
		end
	end
    return tRetLocker
end

function UIHomelandInteractWarehouseView:UpdateFilter()
    if UIHelper.GetChildrenCount(self.LayoutContent02) == 0 then --背包
        for index, value in ipairs(self.tbTabCfg) do
            local scriptFilter = UIHelper.AddPrefab(PREFAB_ID.WidgetHomeWarehouseScreen, self.LayoutContent02)
            scriptFilter:OnEnter()
            UIHelper.SetString(scriptFilter.LabelFullReduction, value.szFilter)
            UIHelper.ToggleGroupAddToggle(self.ToggleGroupTravelingBagScreen, scriptFilter.TogSettleAccounts)
            UIHelper.SetToggleGroupAllowedNoSelection(self.ToggleGroupTravelingBagScreen, false)
            scriptFilter:SetfuncCallBack(function ()
                self.nBagFilterIndex = index
                self.nWarehouseFilterIndex = index
                self:RefreshBagCells()
                self:RefreshWarehouseCells()
                UIHelper.SetString(self.LabelBagAdd, value.szFilter)
                UIHelper.SetString(self.LabelWarehouseAdd, value.szFilter)
                UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewBag)
                UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewWareHouse)
                self:CloseTip()
            end)
            Timer.AddFrame(self, 1, function()
                UIHelper.SetToggleGroupSelected(self.ToggleGroupTravelingBagScreen, 0)
                self.nBagFilterIndex = 1
            end)
        end
        UIHelper.LayoutDoLayout(self.LayoutContent02)
    end

    if UIHelper.GetChildrenCount(self.LayoutContent) == 0 then --仓库
        for index, value in ipairs(self.tbTabCfg) do
            local scriptFilter = UIHelper.AddPrefab(PREFAB_ID.WidgetHomeWarehouseScreen, self.LayoutContent)
            scriptFilter:OnEnter()
            UIHelper.SetString(scriptFilter.LabelFullReduction, value.szFilter)
            UIHelper.ToggleGroupAddToggle(self.ToggleGroupWareHouseScreen, scriptFilter.TogSettleAccounts)
            UIHelper.SetToggleGroupAllowedNoSelection(self.ToggleGroupWareHouseScreen, false)
            scriptFilter:SetfuncCallBack(function ()
                self.nWarehouseFilterIndex = index
                self:RefreshWarehouseCells()
                self:CloseTip()
                UIHelper.SetString(self.LabelWarehouseAdd, value.szFilter)
                UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewWareHouse)
            end)
            Timer.AddFrame(self, 1, function()
                UIHelper.SetToggleGroupSelected(self.ToggleGroupWareHouseScreen, 0)
                self.nWarehouseFilterIndex = 1
            end)
        end
        UIHelper.LayoutDoLayout(self.LayoutContent)
    end

    UIHelper.SetTouchDownHideTips(self.TogUnfold, false)
    UIHelper.SetTouchDownHideTips(self.TogTravelingBagUnfold, false)

end

function UIHomelandInteractWarehouseView:StoreOneItem(item)
    local nCount = item.nStackNum
    for _, v in ipairs(tLockerInfo) do
		if v.dwItemType == item.dwTabType and v.dwItemID == item.dwIndex then
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
		end
	end
end

function UIHomelandInteractWarehouseView:PickUpOneItem(tbItemInfo)
    if self.bServant then
        local player = GetClientPlayer()
        local eTargetType, nTargetID = player.GetTarget()
	    RemoteCallToServer("On_HomeLand_GetRestoreItem", eTargetType, nTargetID, tbItemInfo.nIndex)
    else
        local tFilter = tWarehouseFilterCheck[tbItemInfo.dwClassType]
        RemoteCallToServer("On_HomeLand_PickItem", tbItemInfo.dwItemType, tbItemInfo.dwItemID, tbItemInfo.nCount, tFilter.DATAMANAGE,
            tbItemInfo.dwDataIndex, tFilter.BYTE_NUM)
    end
end

function UIHomelandInteractWarehouseView:BatchModeCheck()
    if self.bBatchSelect then
        UIHelper.SetVisible(self.WidgetAnchorLeftBtn, false)
        UIHelper.SetVisible(self.WidgetAnchorRightBtn, false)
        UIHelper.SetVisible(self.WidgetAnchorBottom, true)
        self:UpdateBatchModeInfo()
    else
        UIHelper.SetVisible(self.WidgetAnchorLeftBtn, true)
        UIHelper.SetVisible(self.WidgetAnchorRightBtn, true)
        UIHelper.SetVisible(self.WidgetAnchorBottom, false)
    end
end

function UIHomelandInteractWarehouseView:UpdateBatchModeInfo(bSure)
    local nCount = 0
    self.tbPickUpList = {}
    for i, itemScript in ipairs(self.tbCellScripts[UI_BatchType.WareHouse]) do
        if itemScript:GetSelected() then
            if bSure then
                table.insert(self.tbPickUpList, itemScript.tbItemInfo)
            end
            nCount = nCount + 1
        end
    end
    UIHelper.SetString(self.LabelSelectNum, tostring(nCount))
end

function UIHomelandInteractWarehouseView:UpdateServantModeInfo()
    if self.bServant then
        UIHelper.SetVisible(self.TogUnfold, false)
        UIHelper.SetVisible(self.BtnTakeOut, false)
    else
        UIHelper.SetVisible(self.TogUnfold, true)
        UIHelper.SetVisible(self.BtnTakeOut, true)
    end
end

function UIHomelandInteractWarehouseView:CloseTip()
    if self.tipsScriptView then
        if not self.bBatchSelect then
            if self.nCurIconScript then
                self.nCurIconScript:RawSetSelected(false)
            end
        end
        if self.scriptCurBagIcon then
            self.scriptCurBagIcon:RawSetSelected(false)
        end
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
        self.tipsScriptView = nil
    end
    UIHelper.SetSelected(self.TogTravelingBagUnfold, false)
    UIHelper.SetSelected(self.TogUnfold, false)
end

function UIHomelandInteractWarehouseView:ItemEmptyCheck()
    local bWarehouseEmpty = table.is_empty(self.tbCellScripts[UI_BatchType.WareHouse])
    local bBagEmpty = table.is_empty(self.tbCellScripts[UI_BatchType.Bag])

    UIHelper.SetNodeGray(self.BtnTakeOut, bWarehouseEmpty, true)
    UIHelper.SetNodeGray(self.BtnLeaveWith, bBagEmpty, true)
    UIHelper.SetVisible(self.WidgetEmptyLeft, bWarehouseEmpty)
    UIHelper.SetVisible(self.WidgetEmptyRight, bBagEmpty)
end

function UIHomelandInteractWarehouseView:GetNewServantItemList(tCurrentItem)
    self.tCurrentItem = tCurrentItem
    self:UpdateInfo()
end

return UIHomelandInteractWarehouseView