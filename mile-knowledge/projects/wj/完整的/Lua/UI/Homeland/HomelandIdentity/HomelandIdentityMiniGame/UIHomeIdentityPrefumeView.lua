-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomeIdentityPrefumeView
-- Date: 2024-01-23 11:18:36
-- Desc: ?
-- ---------------------------------------------------------------------------------
local DEF_MAX_MAKE_NUM = 100
local PER_PREFUME_COST = 20
local UIHomeIdentityPrefumeView = class("UIHomeIdentityPrefumeView")
local DataModel = {
	tData          = {},
	num            = {},
    tSelectionItem = {},
	bShowAni       = false,
	tHaveHistoryItem = {},
}

function DataModel.Init()
	DataModel.tData          = {}
	DataModel.num            = {}
    DataModel.tSelectionItem = {}
	DataModel.bShowAni       = false
	DataModel.tHaveHistoryItem = DataModel.tHaveHistoryItem or {}
	DataModel.nHaveHistoryNum = DataModel.nHaveHistoryNum or 0
end

function DataModel.UnInit()
	DataModel.tData             = {}
	DataModel.num               = {}
    DataModel.tSelectionItem    = {}
    DataModel.tHaveHistoryItem  = {}
	DataModel.nHaveHistoryNum   = nil
	DataModel.bShowAni          = false
    for i=1,4 do
		DataModel.tSelectionItem[i] = false
	end
end

function UIHomeIdentityPrefumeView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        RemoteCallToServer("On_Perfume_PanelOpen", 1)
        DataModel.Init()
        self.bInit = true
    end
    self.bResultMode = false
    self.bAutoPerfume = false
    self:Init()
    self:InitVigor()

    UIMgr.Close(ItemData.GetBagScript())
end

function UIHomeIdentityPrefumeView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    DataModel.UnInit()
end

function UIHomeIdentityPrefumeView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCloseLeftBag, EventType.OnClick, function ()
        if UIHelper.GetVisible(self.WidgetAniLeft) then
            self:SetSlotSelelct(nil)
            UIHelper.PlayAni(self, self.AniAll, "AniLeftHide", function ()
                UIHelper.SetVisible(self.WidgetAniLeft, false)
            end)
        end
    end)

    UIHelper.BindUIEvent(self.BtnCloseLeft, EventType.OnClick, function ()
        if UIHelper.GetVisible(self.WidgetAniLeft) then
            self:SetSlotSelelct(nil)
            UIHelper.PlayAni(self, self.AniAll, "AniLeftHide", function ()
                UIHelper.SetVisible(self.WidgetAniLeft, false)
            end)
        end
    end)

    UIHelper.BindUIEvent(self.BtnConfiguration, EventType.OnClick, function ()
        if self.bResultMode then
            UIHelper.RemoveAllChildren(self.WidgetGoods80)
            UIHelper.RemoveAllChildren(self.LayoutMore)
            UIHelper.RemoveAllChildren(self.ScrollViewMore)
            self:ClearAllInput()    --准备再次调制
            UIHelper.SetString(self.LabelConfiguration, "开始配置")
            UIHelper.PlayAni(self, self.AniAll, "AniAgain")
            UIHelper.SetVisible(self.TogAutoUpgrade, true)
            UIHelper.SetVisible(self.BtnWarehouse, true)
            UIHelper.SetVisible(self.WidgetConsume, true)
            UIHelper.SetVisible(self.WidgetFinishItem, false)
            UIHelper.SetVisible(self.WidgetFinishItemMore, false)
            self.bResultMode = false

	        local nType = 1
            RemoteCallToServer("On_Perfume_PanelOpen", nType)
            return
        end
        if not self.CheckFillBox(DataModel.tSelectionItem) then
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_HOUSE_CONDITION_TIP)
            return
        end

        local tbData = {}
        if self.bAutoPerfume then
            for _, tItem in ipairs(DataModel.tSelectionItem) do
                table.insert(tbData, {tItemIndex = tItem.tItemIndex, num = (tItem.num * self.nAutoPrefumeNum)})
            end
        else
            tbData = DataModel.tSelectionItem
        end
        RemoteCallToServer("On_Perfume_GetCostItem", tbData)
        UIHelper.SetVisible(self.BtnConfiguration, false)
        UIHelper.SetVisible(self.BtnWarehouse, false)
        UIHelper.SetVisible(self.TogAutoUpgrade, false)
        UIHelper.SetVisible(self.WidgetConsume, false)
        UIHelper.PlayAni(self, self.AniAll, "AniTiaoZhi")
        self:RestoreHistory(tbData)
        self:ClearAllInput()
    end)

    UIHelper.BindUIEvent(self.BtnSubAmountScript, EventType.OnClick, function()
        self.nAutoPrefumeNum = self.nAutoPrefumeNum - 1
        self.nAutoPrefumeNum = math.max(self.nAutoPrefumeNum, self.nAutoPrefumeNum and 1 or 0)

        local percent = 0
        if self.nMaxPrefumeNum > 0 then
            percent = self.nAutoPrefumeNum / self.nMaxPrefumeNum * 100
        end
        self:UpdateVigorCost()
        UIHelper.SetProgressBarPercent(self.SliderScriptNum, percent)
        UIHelper.SetProgressBarPercent(self.ProgressBarScriptNum, percent)
        UIHelper.SetString(self.LabelScriptUpgradeNum, self.nAutoPrefumeNum.."次")
    end)

    UIHelper.BindUIEvent(self.BtnAddAmountScript, EventType.OnClick, function()
        self.nAutoPrefumeNum = self.nAutoPrefumeNum + 1
        self.nAutoPrefumeNum = math.min(self.nMaxPrefumeNum, self.nAutoPrefumeNum)

        local percent = 0
        if self.nMaxPrefumeNum > 0 then
            percent = self.nAutoPrefumeNum / self.nMaxPrefumeNum * 100
        end
        self:UpdateVigorCost()
        UIHelper.SetProgressBarPercent(self.SliderScriptNum, percent)
        UIHelper.SetProgressBarPercent(self.ProgressBarScriptNum, percent)
        UIHelper.SetString(self.LabelScriptUpgradeNum, self.nAutoPrefumeNum.."次")
    end)

    UIHelper.BindUIEvent(self.SliderScriptNum, EventType.OnChangeSliderPercent, function(SliderEventType, nSliderEvent)
        if nSliderEvent == ccui.SliderEventType.slideBallDown then
            self.bSliding = true
        elseif nSliderEvent == ccui.SliderEventType.slideBallUp then
            self.bSliding = false
            local percent = UIHelper.GetProgressBarPercent(self.SliderScriptNum) / 100
            local maxAmount = math.floor(percent * self.nMaxPrefumeNum)
            if self.nAutoPrefumeNum > 0 and maxAmount < 1 then
                maxAmount = 1
                percent = maxAmount / self.nMaxPrefumeNum
            end
            percent = maxAmount / self.nMaxPrefumeNum
            UIHelper.SetProgressBarPercent(self.SliderScriptNum, percent * 100)
            UIHelper.SetProgressBarPercent(self.ProgressBarScriptNum, percent * 100)
        end

        if self.bSliding then
            local percent = UIHelper.GetProgressBarPercent(self.SliderScriptNum) / 100
            local maxAmount = math.floor(percent * self.nMaxPrefumeNum)
            if self.nAutoPrefumeNum > 0 and maxAmount < 1 then
                maxAmount = 1
                percent = maxAmount / self.nMaxPrefumeNum
            end
            UIHelper.SetString(self.LabelScriptUpgradeNum, maxAmount.."次")
            UIHelper.SetProgressBarPercent(self.ProgressBarScriptNum, percent * 100)
            self.nAutoPrefumeNum = maxAmount
            self:UpdateVigorCost()
        end
    end)

    UIHelper.BindUIEvent(self.TogAutoUpgrade, EventType.OnSelectChanged, function(toggle, bSelected)
        self.bAutoPerfume = bSelected
        self:UpdateVigorCost()
    end)

    UIHelper.BindUIEvent(self.BtnWarehouse, EventType.OnClick, function()
        UIMgr.Close(self)
        UIMgr.OpenSingle(false,VIEW_ID.PanelHalfBag)
        local scriptView = UIMgr.Open(VIEW_ID.PanelHalfWarehouse,WareHouseType.Homeland)
        Timer.AddFrame(scriptView, 5, function ()
            Event.Dispatch(EventType.OnSelelctHLWarehouseFilter, 6)
        end)
    end)
end

function UIHomeIdentityPrefumeView:RegEvent()
    Event.Reg(self, EventType.OnHomeGetPerfumeMaterialInfo, function (tInfo, nType)
        DataModel.num = {}
        DataModel.tData = tInfo
        for i = 1, #tInfo do
            DataModel.num[tInfo[i].tItemIndex] = tInfo[i].num
        end
        if nType == 1 and not table.is_empty(DataModel.tHaveHistoryItem) then
            self:InitHistoryItem()
        elseif nType == 2 then
            for i = 1,4 do
                if DataModel.tSelectionItem[i] then
                    local tItemIndex = DataModel.tSelectionItem[i].tItemIndex
                    DataModel.num[tItemIndex] = DataModel.num[tItemIndex] - DataModel.tSelectionItem[i].num
                end
            end
            if UIHelper.GetVisible(self.WidgetAniLeft) then
                self:SetSlotSelelct(nil)
                UIHelper.PlayAni(self, self.AniAll, "AniLeftHide", function ()
                    UIHelper.SetVisible(self.WidgetAniLeft, false)
                end)
            end
            self:UpdateAutoPrefumeInfo()
        end
    end)

    Event.Reg(self, EventType.OnPerfumeGetAwardResult, function (tItem)
        self:OnGetItemsResult(tItem)
    end)

    Event.Reg(self, EventType.OnPrefumeAddMaterial, function (nSelectedSlot, dwItemTabIndex, nCount)
        self:ChangeSelelctItemTable(nSelectedSlot, dwItemTabIndex, nCount)
        Event.Dispatch(EventType.HideAllHoverTips)
        if nSelectedSlot >= 4 or DataModel.tSelectionItem[nSelectedSlot + 1] then
            self:SetSlotSelelct(nil)
            UIHelper.PlayAni(self, self.AniAll, "AniLeftHide", function ()
                UIHelper.SetVisible(self.WidgetAniLeft, false)
            end)
        else
            self:OpenLeftBag(nSelectedSlot + 1)
        end
    end)

    Event.Reg(self, "BAG_ITEM_UPDATE", function (dwBoxIndex, dwX, bIsNewAdd)
        local pPlayer = GetClientPlayer()
        local pItem = ItemData.GetPlayerItem(pPlayer, dwBoxIndex, dwX)
        if pItem and Table_GetPerfumeItemInfo(pItem.dwTabType, pItem.dwIndex) then
            local nType = 2
            RemoteCallToServer("On_Perfume_PanelOpen", nType)
        end
    end)

    Event.Reg(self, EventType.OnSceneTouchNothing, function ()
        UIHelper.PlayAni(self, self.AniAll, "AniLeftHide", function ()
            self:SetSlotSelelct(nil)
            UIHelper.SetVisible(self.WidgetAniLeft, false)
        end)
    end)
end

function UIHomeIdentityPrefumeView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIHomeIdentityPrefumeView:Init()
    self:InitSilder()
    self:UpdateAutoPrefumeInfo()
    self.scriptLeftBag = self.scriptLeftBag or UIHelper.GetBindScript(self.WidgetLeftBag)
    for index, widget in ipairs(self.tbAddWidget) do
        self["scriptAddWidget"..index] = UIHelper.GetBindScript(widget)
        self["scriptAddWidget"..index]:OnEnter(index)
        self["scriptAddWidget"..index]:SetClickCallback(function ()
            self:OpenLeftBag(index)
        end)
    end
end

function UIHomeIdentityPrefumeView:OpenLeftBag(nSelectedSlot)
    UIHelper.PlayAni(self, self.AniAll, "AniLeftShow")
    UIHelper.SetVisible(self.WidgetAniLeft, true)
    self:SetSlotSelelct(nSelectedSlot)
    -- self.CheckBuyTheItemInBag(nSelectedSlot)

    local tBag = self.GetPerfumeItemList(nSelectedSlot)
    self.scriptLeftBag:OnInitWithTabID(tBag, nSelectedSlot, true)
end

function UIHomeIdentityPrefumeView.CheckFillBox(tItem)
	if not tItem[1] or not tItem[2] or not tItem[3] or not tItem[4] then
		return false
	end
	return true
end

local function fnHouseDatasFilter(dwTabType, dwIndex, nSelectedSlot)
	local tLine = Table_GetPerfumeItemInfo(dwTabType, dwIndex)
	if tLine then
		if tLine.nItemPos == nSelectedSlot then
			return true
		elseif tLine.nItemPos == 1 and nSelectedSlot ~= 4 then
			return true
		end
	end
	return false
end

function UIHomeIdentityPrefumeView.CheckBuyTheItemInBag(nSelectedSlot)
	local pPlayer = GetClientPlayer()
	for _, dwBox in pairs(GetPackageIndex()) do
		local nSize = pPlayer.GetBoxSize(dwBox)
		for dwX = 0, nSize - 1 do
			local pItem = PlayerData.GetPlayerItem(pPlayer, dwBox, dwX)
			if pItem and fnHouseDatasFilter(pItem.dwTabType, pItem.dwIndex, nSelectedSlot) then
				local nCount = pPlayer.GetItemAmountInPackage(pItem.dwTabType, pItem.dwIndex)
				-- for k, v in pairs(DataModel.tSelectionItem) do
				-- 	if v and v.tItemIndex == pItem.dwIndex then
				-- 		nCount = nCount - 1
				-- 	end
				-- end
                if DataModel.num[pItem.dwIndex] and nCount == 0 then
					DataModel.num[pItem.dwIndex] = 0
				elseif nCount ~= 0 then
					DataModel.num[pItem.dwIndex] = nCount
				end
			end
		end
	end
end

local function GetCurInputCount(dwTabIndex)
    local nCount = 0
    for index, tbItem in pairs(DataModel.tSelectionItem) do
        if tbItem.tItemIndex == dwTabIndex then
            nCount = nCount + tbItem.num
        end
    end
    return nCount
end

function UIHomeIdentityPrefumeView.GetPerfumeItemList(nSelectedSlot)
	local tInfo = Table_GetPerfumeItemList()
    local tBag = {}
	local tFlag = {}
	for i = 1, #DataModel.tData do
		local dwType = DataModel.tData[i].tItemType
		local dwIndex = DataModel.tData[i].tItemIndex
        -- local nCurCount = GetCurInputCount(dwIndex)
		if fnHouseDatasFilter(dwType, dwIndex, nSelectedSlot) then
            local nAmount = DataModel.num[dwIndex]
            local tItemInfo = {dwTabType = dwType, dwIndex = dwIndex, nAmount = nAmount}
			table.insert(tBag, tItemInfo)
            tFlag[dwIndex] = true
		end
	end

	for i = 1, #tInfo do
		if fnHouseDatasFilter(tInfo[i].dwTabType, tInfo[i].dwIndex, nSelectedSlot) then
			if not tFlag[tInfo[i].dwIndex] and tInfo[i].bShop then
                local tItemInfo = {dwTabType = tInfo[i].dwTabType, dwIndex = tInfo[i].dwIndex}
                table.insert(tBag, #tBag+1, tItemInfo)
			end
		end
	end
    return tBag
end

function UIHomeIdentityPrefumeView:ChangeSelelctItemTable(nSelectedSlot, dwItemTabIndex, nCount)
    if DataModel.tSelectionItem[nSelectedSlot] then -- 走替换
        local nCurSelectItemIndex = DataModel.tSelectionItem[nSelectedSlot].tItemIndex
        DataModel.num[nCurSelectItemIndex] = DataModel.num[nCurSelectItemIndex] + DataModel.tSelectionItem[nSelectedSlot].num
        DataModel.tSelectionItem[nSelectedSlot] = nil
    end
    DataModel.tSelectionItem[nSelectedSlot] = {tItemIndex = dwItemTabIndex, num = nCount}
    DataModel.num[dwItemTabIndex] = DataModel.num[dwItemTabIndex] - nCount
    self:OnChangeItem(nSelectedSlot, dwItemTabIndex, nCount)
    self:UpdateAutoPrefumeInfo()
    self:AniPlay()
end

function UIHomeIdentityPrefumeView:ClearAllInput()
    DataModel.tSelectionItem = {}
    for index, _ in ipairs(self.tbAddWidget) do
        self["scriptAddWidget"..index]:OnChangeItem()
    end
    self:AniPlay()
end

function UIHomeIdentityPrefumeView:OnChangeItem(nSelectedSlot, dwItemTabIndex, nCount)
    self["scriptAddWidget"..nSelectedSlot]:OnChangeItem(dwItemTabIndex, nCount)
    self["scriptAddWidget"..nSelectedSlot]:SetItemCilckCallback(function ()
        self:OpenLeftBag(nSelectedSlot)
    end)
    self["scriptAddWidget"..nSelectedSlot]:SetRecallCallback(function ()
		DataModel.num[dwItemTabIndex] = DataModel.num[dwItemTabIndex] + nCount
        DataModel.tSelectionItem[nSelectedSlot] = nil
        self["scriptAddWidget"..nSelectedSlot]:OnChangeItem()
        self:OpenLeftBag(nSelectedSlot)
        self:AniPlay()
        self:UpdateAutoPrefumeInfo()
    end)
end

function UIHomeIdentityPrefumeView:InitHistoryItem()
    for i = 1, 4 do
		local tItem = DataModel.tHaveHistoryItem[i]
		if DataModel.num[tItem.tItemIndex] and DataModel.num[tItem.tItemIndex] - 1 > -1 then
			self:ChangeSelelctItemTable(i, tItem.tItemIndex, 1)
		end
	end

    if not self.CheckFillBox(DataModel.tSelectionItem) then
		OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_HOUSE_NOT_ENOUGH_ITEM)
        self:AniPlay()
    elseif DataModel.nHaveHistoryNum then
        self.nAutoPrefumeNum = math.min(DataModel.nHaveHistoryNum, self.nMaxPrefumeNum)

        local nPercent = self.nAutoPrefumeNum / self.nMaxPrefumeNum * 100
        self:UpdateVigorCost()
        UIHelper.SetString(self.LabelScriptUpgradeNum, self.nAutoPrefumeNum.."次")
        UIHelper.SetProgressBarPercent(self.SliderScriptNum, nPercent)
        UIHelper.SetProgressBarPercent(self.ProgressBarScriptNum, nPercent)
	end
end

function UIHomeIdentityPrefumeView:AniPlay()
    local bAllReady = true
    for index = 1, #self.tbAddWidget, 1 do
        if DataModel.tSelectionItem[index] and DataModel.tSelectionItem[index].tItemIndex > 0 then
            UIHelper.PlayAni(self, self.AniAll, "AniInstall0"..index)
        else
            bAllReady = false
            UIHelper.PlayAni(self, self.AniAll, "AniRemove0"..index)
        end
    end
    if bAllReady then
        UIHelper.PlayAni(self, self.AniAll, "AniZhunBei")
    end
end

function UIHomeIdentityPrefumeView:SetSlotSelelct(nSlot)
    for index, widget in ipairs(self.tbAddWidget) do
        local scriptCell = UIHelper.GetBindScript(widget)
        UIHelper.SetVisible(scriptCell.ImgSelectWeapon, nSlot and (index == nSlot))
    end
end

function UIHomeIdentityPrefumeView:RestoreHistory(tbData)
    if table.is_empty(tbData) then
        return
    end
    local tbHistory = {}
    local nMinInputNum
    for index, item in ipairs(tbData) do
        nMinInputNum = nMinInputNum and math.min(nMinInputNum, item.num) or item.num
        table.insert(tbHistory, {tItemIndex = item.tItemIndex})
    end
	DataModel.nHaveHistoryNum = nMinInputNum
    DataModel.tHaveHistoryItem = tbHistory
end

function UIHomeIdentityPrefumeView:InitGetItemInfo(nIndex, nCount, parent)
    local script = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, parent)
    UIHelper.SetAnchorPoint(script._rootNode, 0, 0)
    script:OnInitWithTabID(ITEM_TABLE_TYPE.OTHER, nIndex, nCount)
    script:SetClearSeletedOnCloseAllHoverTips(true)
    script:SetClickCallback(function ()
        TipsHelper.ShowItemTips(script._rootNode, ITEM_TABLE_TYPE.OTHER, nIndex)
    end)
end

function UIHomeIdentityPrefumeView:OnGetItemsResult(tItem)
    UIHelper.RemoveAllChildren(self.WidgetGoods80)
    UIHelper.RemoveAllChildren(self.LayoutMore)
    UIHelper.RemoveAllChildren(self.ScrollViewMore)
    if not tItem or not tItem[1] then
        return
    end
    local szName = UIHelper.GBKToUTF8(tItem[1].szName)
    local bMore = #tItem > 1

    UIHelper.SetVisible(self.WidgetMainContent, false)
    UIHelper.SetVisible(self.LayoutMore, false)
    UIHelper.SetVisible(self.ScrollViewMore, false)
    UIHelper.SetVisible(self.WidgetGet, true)
    UIHelper.SetVisible(self.BtnConfiguration, true)
    UIHelper.SetVisible(self.BtnWarehouse, true)
    UIHelper.SetVisible(self.WidgetFinishItem, not bMore)
    UIHelper.SetVisible(self.WidgetFinishItemMore, bMore)

    if bMore then
        local nItemCount = 0
        local tSortItemList = {}
        for _, item in ipairs(tItem) do
            if tSortItemList[item.tItemIndex] then
                tSortItemList[item.tItemIndex] = tSortItemList[item.tItemIndex] + item.num
            else
                tSortItemList[item.tItemIndex] = item.num
                nItemCount = nItemCount + 1
            end
        end

        local parent = nItemCount > 4 and self.ScrollViewMore or self.LayoutMore
        for nIndex, nAmount in pairs(tSortItemList) do
            self:InitGetItemInfo(nIndex, nAmount, parent)
        end
        UIHelper.SetVisible(parent, true)
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewMore)
        UIHelper.LayoutDoLayout(self.LayoutMore)
        UIHelper.WidgetFoceDoAlignAssignNode(self, self.LayoutMore)
    else
        self:InitGetItemInfo(tItem[1].tItemIndex, tItem[1].num, self.WidgetGoods80)
    end

    UIHelper.SetString(self.LabelIteamName, szName)
    UIHelper.SetString(self.LabelMoreName, szName.."等")
    UIHelper.SetString(self.LabelConfiguration, "再次配置")

    -- 香膏使用教学指引
    if TeachEvent.CheckCondition(46) then
        TeachEvent.TeachStart(46)
    end
    self.bResultMode = true
end

function UIHomeIdentityPrefumeView:InitSilder()
    local nPercent = 0
    self.nMaxPrefumeNum = 0
    self.nAutoPrefumeNum = 0
    if self.nMaxPrefumeNum > 0 then
        nPercent = 1 / self.nMaxPrefumeNum * 100
        self.nAutoPrefumeNum = 1
    end
    self:UpdateVigorCost()
    UIHelper.SetString(self.LabelScriptUpgradeNum, self.nAutoPrefumeNum.."次")
    UIHelper.SetProgressBarPercent(self.SliderScriptNum, nPercent)
    UIHelper.SetProgressBarPercent(self.ProgressBarScriptNum, nPercent)
end

function UIHomeIdentityPrefumeView:InitVigor()
    self.vigorScript = self.vigorScript or UIHelper.AddPrefab(PREFAB_ID.WidgetOtherCurrency, self.LayoutRTop)
    self.vigorScript:SetCurrencyType(CurrencyType.Vigor)
    self.vigorScript:HandleEvent(CurrencyType.Vigor)
end

function UIHomeIdentityPrefumeView:UpdateVigorCost()
    local bAutoPerfume = self.bAutoPerfume
    local nCurPerfumeNum = bAutoPerfume and self.nAutoPrefumeNum or 1
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local nVigor = hPlayer.nVigor + hPlayer.nCurrentStamina
    local nCost = nCurPerfumeNum * PER_PREFUME_COST
    local bEnough = nVigor >= nCost
    UIHelper.SetButtonState(self.BtnConfiguration, bEnough and BTN_STATE.Normal or BTN_STATE.Disable)
    UIHelper.SetColor(self.LabelConsumeNum, bEnough and cc.c3b(255, 255, 255) or cc.c3b(255, 0, 0))
    UIHelper.SetString(self.LabelConsumeNum, nCost)
    UIHelper.LayoutDoLayout(self.WidgetConsume)
end

function UIHomeIdentityPrefumeView:UpdateAutoPrefumeInfo()
    local nMaxPrefumeNum
    local tbInputNum = {}
    for _, tbInfo in pairs(DataModel.tSelectionItem) do
        local dwItemTabIndex = tbInfo.tItemIndex
        if tbInputNum[dwItemTabIndex] then
            tbInputNum[dwItemTabIndex] = tbInputNum[dwItemTabIndex] + 1
        else
            tbInputNum[dwItemTabIndex] = 1
        end
    end

    if self.CheckFillBox(DataModel.tSelectionItem) then
        for dwItemTabIndex, nCount in pairs(tbInputNum) do
            local nMaxCount = math.floor((DataModel.num[dwItemTabIndex] + nCount) / nCount) -- 加回对应的InputNum再重新算
            nMaxPrefumeNum = nMaxPrefumeNum and math.min(nMaxPrefumeNum, nMaxCount) or nMaxCount
        end
    end

    -- 制作的最大数量大于1时，最小制作数量为1
    self.nMaxPrefumeNum = nMaxPrefumeNum or 0
    self.nMaxPrefumeNum = math.min(self.nMaxPrefumeNum, DEF_MAX_MAKE_NUM)
    self.nAutoPrefumeNum = math.min(self.nAutoPrefumeNum < 1 and 1 or self.nAutoPrefumeNum, self.nMaxPrefumeNum)
    self:UpdateVigorCost()

    local nPercent = self.nAutoPrefumeNum / self.nMaxPrefumeNum * 100
    UIHelper.SetString(self.LabelScriptUpgradeNum, self.nAutoPrefumeNum.."次")
    UIHelper.SetProgressBarPercent(self.SliderScriptNum, nPercent)
    UIHelper.SetProgressBarPercent(self.ProgressBarScriptNum, nPercent)
end
return UIHomeIdentityPrefumeView