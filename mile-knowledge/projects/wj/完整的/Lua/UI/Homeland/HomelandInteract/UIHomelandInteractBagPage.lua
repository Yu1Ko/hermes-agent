-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandInteractBagPage
-- Date: 2023-08-21 14:40:06
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandInteractBagPage = class("UIHomelandInteractBagPage")
local _PET_ITEM_TYPE = 1
local _OTHER_ITEM_TYPE = 8
local tFilterCheck = HomelandMiniGameData.tFilterCheck
function UIHomelandInteractBagPage:OnEnter(tbInfo, nModuleID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self:GetTheSlotWithOpenShopTable()
        self.bInit = true
        FilterDef.HomelandPet.Reset()
    end

    if self.nModuleID ~= nModuleID then
        self.szSearch = ""
        UIHelper.SetText(self.EditKindSearch, "")
    end

    self.tbInfo = tbInfo
    self.nModuleID = nModuleID

    self:UpdateInfo()
    self:Show()
end

function UIHomelandInteractBagPage:OnExit()
    self.bInit = false
end

function UIHomelandInteractBagPage:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCloseBag, EventType.OnClick, function ()
        self:Hide()
    end)

    UIHelper.BindUIEvent(self.BtnScreen, EventType.OnClick, function(btn)
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnScreen, TipsLayoutDir.BOTTOM_CENTER, FilterDef.HomelandPet)
    end)


    if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditKindSearch, function()
			self.szSearch = UIHelper.GetText(self.EditKindSearch)
            self:UpdateListInfo()
        end)
    else
        UIHelper.RegisterEditBoxReturn(self.EditKindSearch, function()
			self.szSearch = UIHelper.GetText(self.EditKindSearch)
            self:UpdateListInfo()
        end)
    end
end

function UIHomelandInteractBagPage:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function ()
        self:ClearSelect()
        self:HideItemTips()
    end)

    Event.Reg(self, EventType.EmailBagItemSelected, function(nBox, nIndex, nCurCount)
        local item = ItemData.GetItemByPos(nBox, nIndex)
        if not item then
            return
        end

        local tItem = {nSlotType = self.tbInfo.nType}
        if self.tbInfo.nType == PETS_SCREE_TYPE.ORDINARYMOUNT then -- 坐骑
            tItem.dwTabType = item.dwTabType
            tItem.dwIndex = item.dwIndex
            tItem.nStackNum = nCurCount
            local bSuccess = HomelandMiniGameData.AddItemToSlot(self.tbInfo, tItem)
            if bSuccess then
                self:HideItemTips()
                Event.Dispatch(EventType.OnUpdateHomelandInteractItemData)
                self:Hide()
            end
        else
            tItem.dwTabType = item.dwTabType
            tItem.dwIndex = item.dwIndex
            tItem.nStackNum = nCurCount
            local bSuccess = HomelandMiniGameData.AddItemToSlot(self.tbInfo, tItem)
            if bSuccess then
                self:HideItemTips()
                Event.Dispatch(EventType.OnUpdateHomelandInteractItemData)
                self:Hide()

                if self.tbInfo.nBtnID and self.tbInfo.nCostType then
                    HomelandMiniGameData.GameProtocol(self.tbInfo.nBtnID, self.tbInfo.nCostType, true)
                end
            end
        end
    end)

    Event.Reg(self, EventType.OnFilter, function(szKey, tbInfo)
        if szKey ~= FilterDef.HomelandPet.Key then
            return
        end

        self:UpdateInfo()
    end)
end

function UIHomelandInteractBagPage:UpdateInfo()
    self.tbItems = {}
    UIHelper.SetVisible(self.BtnScreen, false)
    self.tbFilterConfig = nil

    if self.tbInfo.nType == PETS_SCREE_TYPE.ORDINARYPET then -- 宠物
        self:UpdatePetInfo()
    elseif self.tbInfo.nType == PETS_SCREE_TYPE.HANGUPPET then -- 挂宠
        self:UpdatePendantPetInfo()
    elseif self.tbInfo.nType == PETS_SCREE_TYPE.ORDINARYMOUNT then -- 坐骑
        self:UpdateHorseInfo()
    elseif self.tbInfo.nType == PETS_SCREE_TYPE.WEAPON then -- 坐骑
        self:UpdateWeaponInfo()
    elseif self:CheckIsPetFeedSlot() then -- 宠物饲料
        self:UpdatePetFeedInfo()
    else
        self:UpdateItemInfo()
    end

    self:UpdateListInfo()

    UIHelper.LayoutDoLayout(self.LayoutRightBtns)
end

function UIHomelandInteractBagPage:IsShow()
    return UIHelper.GetVisible(self._rootNode)
end

function UIHomelandInteractBagPage:Show()
    UIHelper.SetVisible(self._rootNode, true)
end

function UIHomelandInteractBagPage:Hide()
    UIHelper.SetVisible(self._rootNode, false)
end

function UIHomelandInteractBagPage:ShowItemTips()
    UIHelper.SetVisible(self.WidgetAnchorTip, true)
end

function UIHomelandInteractBagPage:HideItemTips()
    self.scriptItemTip = nil
    UIHelper.RemoveAllChildren(self.WidgetAnchorTip)
    UIHelper.SetVisible(self.WidgetAnchorTip, false)
end

function UIHomelandInteractBagPage:UpdatePetInfo()
    self.tbFilterConfig = FilterDef.HomelandPet

    local tItemIndex = HomelandMiniGameData.FilterPet(self.tbInfo.tItemType)

    for i, value in ipairs(tItemIndex) do
        local tPet = Table_GetFellowPet(value)
        table.insert(self.tbItems, {nBox = _PET_ITEM_TYPE, nIndex = value, nSelectedQuantity = 0, szName = UIHelper.GBKToUTF8(tPet.szName)})
    end
    UIHelper.SetVisible(self.BtnScreen, true)
end

function UIHomelandInteractBagPage:UpdatePetFeedInfo()
    self:UpdateItemInfo()
    local tbItem = HomelandEventHandler.GDAPI_LandGetPetFeedList(HomelandMiniGameData.GetPetType(), self.tbItems)
    self.tbItems = tbItem
end

function UIHomelandInteractBagPage:UpdatePendantPetInfo()
    local tItemIndex = HomelandMiniGameData.FilterPendantPet(self.tbInfo.tItemType)
    for i, tbInfo in ipairs(tItemIndex) do
        local itemInfo = ItemData.GetItemInfo(_OTHER_ITEM_TYPE, tbInfo.dwItemIndex)
        table.insert(self.tbItems, {nBox = _OTHER_ITEM_TYPE, nIndex = tbInfo.dwItemIndex, nSelectedQuantity = 0, szName = UIHelper.GBKToUTF8(itemInfo.szName)})
    end
end

function UIHomelandInteractBagPage:UpdateHorseInfo()
    local tItemIndex = HomelandMiniGameData.FilterHorse(self.tbInfo.tItemType)
    for i, tbInfo in ipairs(tItemIndex) do
        table.insert(self.tbItems,{nBox = tbInfo.nBox, nIndex = tbInfo.nIndex, nSelectedQuantity = 0, hItem = tbInfo.item, szName = UIHelper.GBKToUTF8(tbInfo.item.szName)})
    end
end

function UIHomelandInteractBagPage:UpdateWeaponInfo()
    local tItemIndex = HomelandWeaponDisplayData.FilterWeapons(self.tbInfo.nDetail)
    for i, tbInfo in ipairs(tItemIndex) do
        local tUIInfo = g_tTable.CoinShop_Weapon:Search(tbInfo.dwIndex)
        table.insert(self.tbItems, {nBox = _OTHER_ITEM_TYPE, nIndex = tbInfo.dwIndex, nSelectedQuantity = 0, szName = UIHelper.GBKToUTF8(tUIInfo.szName)})
    end
end

local function fnHouseOpenShopItemFilter(pItem, tSlot, nModuleID)
	if pItem.nGameID == HomelandMiniGameData.tData.nGameID and nModuleID == pItem.nModuleID then
		for _, v in pairs(pItem.szSlotID:split(";", true)) do
			if tonumber(v) == tSlot.nID then
				return true
			end
		end
	end
	return false
end

local function fnHouseBagFilter(nType, tSlot)
	if nType then
		if tSlot.tItemType[nType] then
			return true
		end
	end
	return false
end

local function GetHouseBagNum(tItem)
	local tFilter = tFilterCheck[tItem.dwClassType]
	local nClassBagNum = GetClientPlayer().GetRemoteArrayUInt(tFilter.DATAMANAGE, tFilter.ITEMSTART + (tItem.dwDataIndex - 1) * tFilter.BYTE_NUM, tFilter.BYTE_NUM)
	return nClassBagNum
end

function UIHomelandInteractBagPage:CheckIsPetFeedSlot()
    local tSlot = self.tbInfo
	local bIsHavePutPet = HomelandMiniGameData.GetPetType()
	if bIsHavePutPet and (tSlot.nID == 5 or tSlot.nID == 6 or tSlot.nID == 7 or tSlot.nID == 8) then
		return true
	end
	return false
end

function UIHomelandInteractBagPage:GetTheSlotWithOpenShopTable()
    self.tSlotsWithOpenShop = {}
	local tFlag = {}
    local tList = Table_GetMiniGameShopList()
	for _, tItem in pairs(tList) do
		if tItem.dwIndex ~= 0 then
			for _, v in pairs(tItem.szSlotID:split(";", true)) do
				local nSlot = tonumber(v)
				if not tFlag[nSlot] then
					self.tSlotsWithOpenShop[nSlot] = nSlot
					tFlag[nSlot] = true
				end
			end
		end
	end
end

function UIHomelandInteractBagPage:UpdateItemInfo()
    local tItemNum = {}
	local tBagList = {}
    for _, tbItemInfo in ipairs(ItemData.GetItemList(ItemData.BoxSet.Bag)) do
        if tbItemInfo.hItem then
            local nType = HomelandEventHandler.LandObject_GetBoxTypeByItem(tbItemInfo.hItem.dwTabType, tbItemInfo.hItem.dwIndex)
            if self.tbInfo.tItemType and self.tbInfo.tItemType[nType] then
                local nCount = 0
                if table.contain_value(self.tItem, tbItemInfo.hItem.dwID) then
                    nCount = self.tItemCount[tbItemInfo.hItem.dwID]
                end

                local _, nBagCount = ItemData.GetItemAllStackNum(tbItemInfo.hItem, true)
                local tItem = {
                    nBox = tbItemInfo.nBox, nIndex = tbItemInfo.nIndex,
                    dwTabType = tbItemInfo.hItem.dwTabType, dwIndex = tbItemInfo.hItem.dwIndex,
                    nSelectedQuantity = nCount, hItem = tbItemInfo.hItem, nCount = nBagCount,
                    szName = UIHelper.GBKToUTF8(tbItemInfo.hItem.szName)
                }
                tBagList[tbItemInfo.hItem.dwIndex] = tItem
                tItemNum[tbItemInfo.hItem.dwIndex] = nBagCount
            end
        end
    end

    -- 需要从家园仓库里获取数据
	if self.tbInfo.dwClassType then
		local tHomeLandClassBag = Table_GetHomelandLockerInfoByClass(self.tbInfo.dwClassType)
		for _, v in ipairs(tHomeLandClassBag) do
			if v and fnHouseBagFilter(v.nItemType, self.tbInfo) then
				local nClassBagNum = GetHouseBagNum(v)
                local tbItemInfo = ItemData.GetItemInfo(v.dwItemType, v.dwItemID)
                local szItemName = tbItemInfo.szName
				if tItemNum[v.dwItemID] then
                    local nTotalCount = 0
                    nTotalCount = tItemNum[v.dwItemID] + nClassBagNum
                    table.insert(self.tbItems, {dwTabType = v.dwItemType, dwIndex = v.dwItemID,
                        nCount = nTotalCount, szName = UIHelper.GBKToUTF8(szItemName)})
                    tBagList[v.dwItemID] = nil
				elseif nClassBagNum > 0  then
                    tItemNum[v.dwItemID] = nClassBagNum
                    table.insert(self.tbItems, {dwTabType = v.dwItemType, dwIndex = v.dwItemID,
                        nCount = nClassBagNum, szName = UIHelper.GBKToUTF8(szItemName)})
				end
			end
		end
	end

    -- 背包里有，但是不进家园仓库的物品,也不在Locker表的物品（目前只有加速道具这一个）
	for _, v in pairs(tBagList) do
		table.insert(self.tbItems, v)
	end

    -- 需要跳转商店的该Slot的物品
	if self.tSlotsWithOpenShop[self.tbInfo.nID] then
		local tInfo = Table_GetMiniGameShopList()
		local tTemp = {}
		for i = 1, #tInfo do
			if not tItemNum[tInfo[i].dwIndex] then
				if fnHouseOpenShopItemFilter(tInfo[i], self.tbInfo, self.nModuleID) then
					table.insert(tTemp, tInfo[i])
				end
			end
		end
        for _, tbItemInfo in ipairs(tTemp) do
            table.insert(self.tbItems, tbItemInfo)
        end
	end
end

function UIHomelandInteractBagPage:UpdateListInfo()
    local tbItems = self:GetSearch()

    UIHelper.SetVisible(self.WidgetEmpty, #tbItems <= 0)

    UIHelper.HideAllChildren(self.ScrollBag)
    self.tbItemCells = self.tbItemCells or {}
    for i, tbItemInfo in pairs(tbItems) do
        if not self.tbItemCells[i] then
            self.tbItemCells[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.ScrollBag)
        end

        UIHelper.SetVisible(self.tbItemCells[i]._rootNode, true)
        self.tbItemCells[i]:SetItemGray(false)
        if self.tbInfo.nType == PETS_SCREE_TYPE.ORDINARYPET then -- 宠物
            local tPet = Table_GetFellowPet(tbItemInfo.nIndex)

            self.tbItemCells[i]:OnInitWithIconID(tPet.nIconID, tPet.nQuality)
            self.tbItemCells[i]:SetClickCallback(function (nBox, nIndex)
                local tItem = {
                    nSlotType = self.tbInfo.nType,
                    nStackNum = 1,
                    dwIndex = tbItemInfo.nIndex,
                    dwTabType = _PET_ITEM_TYPE,
                }
                local bSuccess = HomelandMiniGameData.AddItemToSlot(self.tbInfo, tItem)
                if bSuccess then
                    self:HideItemTips()
                    Event.Dispatch(EventType.OnUpdateHomelandInteractItemData)
                    self:Hide()
                end
            end)
        elseif self.tbInfo.nType == PETS_SCREE_TYPE.HANGUPPET then -- 挂宠
            self.tbItemCells[i]:OnInitWithTabID(tbItemInfo.nBox, tbItemInfo.nIndex)
            self.tbItemCells[i]:SetClickCallback(function (nBox, nIndex)
                local tItem = {
                    nSlotType = self.tbInfo.nType,
                    nStackNum = 1,
                    dwIndex = tbItemInfo.nIndex,
                    dwTabType = 8,
                }
                local bSuccess = HomelandMiniGameData.AddItemToSlot(self.tbInfo, tItem)
                if bSuccess then
                    self:HideItemTips()
                    Event.Dispatch(EventType.OnUpdateHomelandInteractItemData)
                    self:Hide()
                end
            end)
        elseif self.tbInfo.nType == PETS_SCREE_TYPE.ORDINARYMOUNT then -- 坐骑
            self.tbItemCells[i]:OnInit(tbItemInfo.nBox, tbItemInfo.nIndex)
            self.tbItemCells[i]:SetClickCallback(function (nBox, nIndex)
                self:ClearSelect()
                if nBox and nIndex then
                    self:ShowItemTips()
                    self.tbItemCells[i]:SetSelected(true)
                    self.scriptItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetAnchorTip)
                    self.scriptItemTip:ShowPlacementBtn(true, ItemData.GetItemStackNum(tbItemInfo.hItem), 1)
                    self.scriptItemTip:OnInit(nBox, nIndex)
                else
                    self:HideItemTips()
                end
            end)
        elseif self.tbInfo.nType == PETS_SCREE_TYPE.WEAPON then -- 武器外装
            self.tbItemCells[i]:OnInitWithTabID("WeaponExterior", tbItemInfo.nIndex)
            self.tbItemCells[i]:SetClickCallback(function (nBox, nIndex)
                HomelandWeaponDisplayData.tData.tWeaponList = HomelandWeaponDisplayData.tData.tWeaponList or {}
                if self.tbInfo.nDetail == WEAPON_DETAIL.SWORD then
                    HomelandWeaponDisplayData.tData.tWeaponList[1] = nIndex
                elseif self.tbInfo.nDetail == WEAPON_DETAIL.BIG_SWORD then
                    HomelandWeaponDisplayData.tData.tWeaponList[2] = nIndex
                else
                    HomelandWeaponDisplayData.tData.tWeaponList[1] = nIndex
                end

                self:HideItemTips()
                Event.Dispatch(EventType.OnUpdateHomelandInteractItemData)
                self:Hide()
            end)
        else
            if tbItemInfo.dwIndex and tbItemInfo.dwIndex > 0 then
                local bGray = not tbItemInfo.nCount or tbItemInfo.nCount == 0
                self.tbItemCells[i]:OnInitWithTabID(tbItemInfo.dwTabType, tbItemInfo.dwIndex, tbItemInfo.nCount)
                -- UIHelper.SetNodeGray(self.tbItemCells[i]._rootNode, bGray, true)
                self.tbItemCells[i]:SetItemGray(bGray)
                self.tbItemCells[i]:SetClickCallback(function ()
                    self:ClearSelect()
                    if tbItemInfo.dwTabType and tbItemInfo.dwIndex then
                        self:ShowItemTips()
                        self.tbItemCells[i]:SetSelected(true)
                        self.scriptItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetAnchorTip)
                        if not bGray then
                            local nMaxCount = tbItemInfo.nCount
                            if self.tbInfo.nItemMaxNum and self.tbInfo.nItemMaxNum > 0 then
                                nMaxCount = math.min(tbItemInfo.nCount, self.tbInfo.nItemMaxNum)
                            end
                            local nType = HomelandEventHandler.LandObject_GetBoxTypeByItem(tbItemInfo.dwTabType, tbItemInfo.dwIndex)
                            if nType == 40 then--加速道具希望根据种子类型动态数量，需要特殊判定
                                local dwValue2, _, _, _, _, _, _ = HomelandMiniGameData.FormatGameData()
                                local pHlMgr = GetHomelandMgr()
                                local nSeedID = pHlMgr.GetDWORDValueByuint16(dwValue2, 2)
                                local nNumDefault = GDAPI_LandCalcuAcceSeedAndItem(nSeedID, tbItemInfo.dwIndex)
                                nMaxCount =  math.min(nNumDefault, nMaxCount)
                            end
                            self.scriptItemTip:ShowPlacementBtn(true, nMaxCount, nMaxCount, "置入", "", function (nCurCount)
                                local tItem = {nSlotType = self.tbInfo.nType}
                                tItem.dwTabType = tbItemInfo.dwTabType
                                tItem.dwIndex = tbItemInfo.dwIndex
                                tItem.nStackNum = nCurCount
                                local bSuccess = HomelandMiniGameData.AddItemToSlot(self.tbInfo, tItem)
                                if bSuccess then
                                    self:HideItemTips()
                                    Event.Dispatch(EventType.OnUpdateHomelandInteractItemData)
                                    self:Hide()

                                    if self.tbInfo.nBtnID and self.tbInfo.nCostType then
                                        HomelandMiniGameData.GameProtocol(self.tbInfo.nBtnID, self.tbInfo.nCostType, true)
                                    end
                                end
                            end)
                        end
                        self.scriptItemTip:OnInitWithTabID(tbItemInfo.dwTabType, tbItemInfo.dwIndex, tbItemInfo.nCount)
                        self.scriptItemTip:SetBtnState({})
                    else
                        self:HideItemTips()
                    end
                end)
            end
        end
    end
    self:ClearSelect()
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollBag)
end

function UIHomelandInteractBagPage:GetSearch()
    local tbItems = {}
    for _, tItemInfo in ipairs(self.tbItems) do
        -- 这里将格式转一遍，方便将需要置灰的物品沉底
        table.insert(tbItems, tItemInfo)
    end
    if string.is_nil(self.szSearch) then
        return tbItems
    end

    local tbSearchItems = {}
    if tbItems and #tbItems > 0 then
        for _, tbInfo in ipairs(tbItems) do
            if tbInfo.szName and string.find(tbInfo.szName, self.szSearch, 1, true) then
                table.insert(tbSearchItems, tbInfo)
            elseif not tbInfo.szName then
                local tbItemInfo = ItemData.GetItemInfo(tbInfo.dwTabType, tbInfo.dwIndex)
                if tbItemInfo and string.find(UIHelper.GBKToUTF8(tbItemInfo.szName), self.szSearch, 1, true) then
                    table.insert(tbSearchItems, tbInfo)
                end
            end
        end
    end

    return tbSearchItems
end

function UIHomelandInteractBagPage:ClearSelect()
    for i, cell in ipairs(self.tbItemCells or {}) do
        cell:SetSelected(false)
    end
end

return UIHomelandInteractBagPage