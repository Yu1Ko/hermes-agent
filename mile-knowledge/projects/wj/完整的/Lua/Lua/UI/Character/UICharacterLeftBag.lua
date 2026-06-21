-- ---------------------------------------------------------------------------------
-- Author: Jiayuran
-- Name: UICharacterWidgetEquipRefine
-- Date: 2022-12-06 14:39
-- Desc: UICharacterWidgetEquipRefine
-- ---------------------------------------------------------------------------------
---@class UICharacterLeftBag
local UICharacterLeftBag = class("UICharacterLeftBag")

local ALL_QUALITY = 0
local ITEM_TAB_TYPE = 5

function UICharacterLeftBag:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self.tbTabCfg = {
            [MaterialType.WuXingStone] = { filterFunc = function(item)
                return item.nGenre == ITEM_GENRE.DIAMOND
            end },
            [MaterialType.WuCaiStone] = { filterFunc = function(item)
                return item.nGenre == ITEM_GENRE.COLOR_DIAMOND
            end },
            [MaterialType.BothStone] = { filterFunc = function(item)
                if item.nGenre == ITEM_GENRE.COLOR_DIAMOND or item.nGenre == ITEM_GENRE.DIAMOND then
                    return true
                end
                return false
            end },
        }

        self.tbString = {
            [LeftTabType.WuXingStone] = { szTitle = "五行石", szEmptyDescribe = "暂未拥有五行石" },
            [LeftTabType.WuCaiStone] = { szTitle = "五彩石", szEmptyDescribe = "暂未拥有五彩石" },
            [LeftTabType.BothStone] = { szTitle = "背包", szEmptyDescribe = "暂未拥有对应材料" },
            [LeftTabType.Enchant] = { szTitle = "附魔", szEmptyDescribe = "暂未拥有可用的附魔" },
        }

        self.bIsAscend = true
        self.nSelectedQuality = 0

        UIHelper.SetActiveAndCache(self, self._rootNode, false)

        UIHelper.SetTouchDownHideTips(self.BtnBg, false)
        UIHelper.SetTouchDownHideTips(self.ScrollBag, false)
        UIHelper.SetTouchEnabled(self.LayoutList, true)
        UIHelper.SetTouchDownHideTips(self.LayoutList, false)

        UIHelper.SetTouchDownHideTips(self.ScrollBagRefine, false)

        UIHelper.WidgetFoceDoAlign(self)
    end
end

function UICharacterLeftBag:OnExit()
    self.bInit = false
end

function UICharacterLeftBag:BindUIEvent()
    UIHelper.BindUIEvent(self.TogAoutSellUp, EventType.OnSelectChanged, function(toggle, bValue)
        if bValue then
            self.bIsAscend = true
            self:RefreshBagCell()
        end
    end)

    UIHelper.BindUIEvent(self.TogAoutSellBelow, EventType.OnSelectChanged, function(toggle, bValue)
        if bValue then
            self.bIsAscend = false
            self:RefreshBagCell()
        end
    end)

    for index, toggle in ipairs(self.qualityFilterToggles) do
        UIHelper.BindUIEvent(toggle, EventType.OnSelectChanged, function(toggle, bValue)
            if bValue then
                self.nSelectedQuality = index - 1
                self:RefreshBagCell()
            end
        end)
    end

    UIHelper.BindUIEvent(self.BtnChooseClose, EventType.OnClick, function()
        UIHelper.SetVisible(self.WidgetAnchorRepeatedTips, false)
        UIHelper.SetSelected(self.TogQuality, false)
    end)

    UIHelper.BindUIEvent(self.BtnSortClose, EventType.OnClick, function()
        UIHelper.SetVisible(self.WidgetAnchorAloneTips, false)
        UIHelper.SetSelected(self.TogQualityUpDown, false)
    end)

    UIHelper.BindUIEvent(self.BtnSalesmanCloseColor, EventType.OnClick, function()
        UIHelper.SetVisible(self.WidgetSalesmanListColor, false)
    end)

    UIHelper.BindUIEvent(self.BtnSalesmanClose, EventType.OnClick, function()
        UIHelper.SetVisible(self.WidgetSalesmanList, false)
    end)

    UIHelper.BindUIEvent(self.TogTrace, EventType.OnClick, function()
        UIHelper.SetVisible(self.WidgetSalesmanList, true)
    end)

    UIHelper.BindUIEvent(self.TogTraceWuXing, EventType.OnClick, function()
        self:UpdateNavigationLayout(LeftTabType.WuXingStone, true)
        UIHelper.SetVisible(self.WidgetSalesmanListColor, true)
    end)

    UIHelper.BindUIEvent(self.TogTraceWuCai, EventType.OnClick, function()
        self:UpdateNavigationLayout(LeftTabType.WuCaiStone, true)
        UIHelper.SetVisible(self.WidgetSalesmanListColor, true)
    end)

    UIHelper.BindUIEvent(self.TogTraceFumo, EventType.OnClick, function()
        self:UpdateNavigationLayout(LeftTabType.Enchant)
        UIHelper.SetVisible(self.WidgetSalesmanList, true)
    end)

    UIHelper.BindUIEvent(self.TogTraceMuShi, EventType.OnClick, function()
        self:UpdateNavigationLayout(LeftTabType.ZeXinMuShi)
        UIHelper.SetVisible(self.WidgetSalesmanList, true)
    end)
end

function UICharacterLeftBag:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function()
        if UIHelper.GetVisible(self._rootNode) then
            self:CloseLeftPanel()
        end
    end)
end

local tTabTypeToNavigateLabel = {
    [LeftTabType.WuXingStone] = "获取五行石",
    [LeftTabType.Enchant] = "获取附魔",
    [LeftTabType.WuCaiStone] = "获取五彩石",
}

-------------------------------------------------------
function UICharacterLeftBag:UpdateNavigationLayout(nTabType, bBothStone)
    local tLayout = bBothStone and self.LayoutSalesmanListColor or self.LayoutSalesmanList
    local tParent = bBothStone and self.WidgetSalesmanListColor or self.WidgetSalesmanList
    UIHelper.RemoveAllChildren(tLayout)

    if nTabType == LeftTabType.WuXingStone then
        local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetSalesmanListCell, tLayout)
        cell:SetLabelText("五行石商店获取")
        cell:BindClickFunction(function()
            ShopData.OpenSystemShopGroup(1, 407, 5, 24423)
            UIHelper.SetVisible(tParent, false)
        end)

        cell = UIHelper.AddPrefab(PREFAB_ID.WidgetSalesmanListCell, tLayout)
        cell:SetLabelText("交易行获取")
        cell:BindClickFunction(function()
            TradingData.OpenSourceTradeSearchPanel("5/24423")
            UIHelper.SetVisible(tParent, false)
        end)
    elseif nTabType == LeftTabType.Enchant or nTabType == LeftTabType.WuCaiStone then
        local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetSalesmanListCell, tLayout)
        cell:SetLabelText("交易行获取")
        cell:BindClickFunction(function()
            if g_pClientPlayer and g_pClientPlayer.nLevel >= 106 then
                if nTabType == LeftTabType.WuCaiStone then
                    TradingData.OpenSourceTradeSearchPanelWithName("五彩石")
                else
                    TradingData.InitTradingHouse()
                end
            else
                TipsHelper.ShowNormalTip("侠士达到106级后方可开启交易行")
            end

            UIHelper.SetVisible(tParent, false)
        end)

        if nTabType == LeftTabType.Enchant then
            local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetSalesmanListCell, tLayout)
            cell:SetLabelText("25人团队副本掉落")
            cell:BindClickFunction(function()
                UIMgr.Open(VIEW_ID.PanelDungeonEntrance, { dwTargetMapID = 650 })
                UIHelper.SetVisible(tParent, false)
            end)

            cell = UIHelper.AddPrefab(PREFAB_ID.WidgetSalesmanListCell, tLayout)
            cell:SetLabelText("名剑商店获取")
            cell:BindClickFunction(function()
                if g_pClientPlayer.nLevel >= 120 then
                    ShopData.OpenSystemShopGroup(1, 1426, 5, 54375)
                else
                    TipsHelper.ShowImportantYellowTip("需玩家达到120级")
                end
                UIHelper.SetVisible(tParent, false)
            end)

            cell = UIHelper.AddPrefab(PREFAB_ID.WidgetSalesmanListCell, tLayout)
            cell:SetLabelText("飞沙令商店获取")
            cell:BindClickFunction(function()
                if g_pClientPlayer.nLevel >= 120 then
                    ShopData.OpenSystemShopGroup(1, 1136, 5, 54375)
                else
                    TipsHelper.ShowImportantYellowTip("需玩家达到120级")
                end
                UIHelper.SetVisible(tParent, false)
            end)

            cell = UIHelper.AddPrefab(PREFAB_ID.WidgetSalesmanListCell, tLayout)
            cell:SetLabelText("部分活动产出")
            cell:BindClickFunction(function()
                UIMgr.Open(VIEW_ID.PanelActivityCalendar)
                UIHelper.SetVisible(tParent, false)
            end)
        end
    elseif nTabType == LeftTabType.ZeXinMuShi then
        local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetSalesmanListCell, tLayout)
        cell:SetLabelText("玩法[秘境日常]")
        cell:BindClickFunction(function()
            UIMgr.Open(VIEW_ID.PanelDungeonEntrance, { dwTargetMapID = 691 })
        end)
    end

    UIHelper.CascadeDoLayoutDoWidget(tParent, true, false)
end

function UICharacterLeftBag:_ClearLeftPanel()
    UIHelper.RemoveAllChildren(self.ScrollBag)
    DataModel.ClearMaterial()
end

function UICharacterLeftBag:_InitBagMaterialLeftPanel(nMaterialType)
    self:_ClearLeftPanel()
    self.nMaterialType = nMaterialType or self.nMaterialType

    for _, node in ipairs(self.qualityToggleGroups) do
        UIHelper.SetActiveAndCache(self, node, true)
    end

    self:UpdateMaterialList()

    UIHelper.SetVisible(self.WidgetEmpty, IsTableEmpty(DataModel.materialDict))
    self:RefreshBagCell()
end

local tStoneIDMapping = {
    [24442] = 24423,
    [24443] = 24424,
    [24444] = 24425,
    [24445] = 24426,
    [24446] = 24427,
    [24447] = 24428,
    [24448] = 24429,
    [24449] = 24430,

}
function UICharacterLeftBag:UpdateMaterialList()
    local fnEnchantFilter = function(item, nBox, nIndex)
        if (item.nGenre == ITEM_GENRE.ENCHANT_ITEM or item.nGenre == ITEM_GENRE.MATERIAL) and g_pClientPlayer then
            local bState = EnchantData.CanUseEnchantSimple(g_pClientPlayer, item, nBox, nIndex, self.nEnchantCategory)
            return bState
        end
        return false
    end

    self:_ClearLeftPanel()

    for _, tbItemInfo in ipairs(ItemData.GetItemList(ItemData.BoxSet.Bag)) do
        local bShowItem = false
        if tbItemInfo.hItem and self.nMaterialType == MaterialType.Enchant then
            bShowItem = fnEnchantFilter(tbItemInfo.hItem, self.nEnchantBox, self.nEnchantIndex)
        elseif tbItemInfo.hItem and self.nMaterialType ~= MaterialType.Enchant then
            bShowItem = self.tbTabCfg[self.nMaterialType].filterFunc(tbItemInfo.hItem)
        end

        if bShowItem then
            local item = ItemData.GetItemByPos(tbItemInfo.nBox, tbItemInfo.nIndex)
            DataModel.AddItem(item)
        end
    end

    local allInfos = {}
    --五行石分类里需要显示未曾获取的石头
    if self.nMaterialType == MaterialType.WuXingStone or self.nMaterialType == MaterialType.BothStone then
        allInfos = {
            [24423] = 1,
            [24424] = 1,
            [24425] = 1,
            [24426] = 1,
            [24427] = 1,
        }

        --精炼升级不显示6级以上的材料
        if self.nMaterialType ~= MaterialType.BothStone then
            allInfos[24428] = 1
            allInfos[24429] = 1
            allInfos[24430] = 1
        end
    end

    --附魔需要显示推荐附魔
    if self.nMaterialType == MaterialType.Enchant then
        allInfos = EnchantData.GetRecommendEnchant(self.nEnchantBox, self.nEnchantIndex, self.nEnchantCategory)
    end

    for dwIndex, tInfo in pairs(DataModel.materialDict) do
        local nTrueIndex = tStoneIDMapping[dwIndex] or dwIndex -- 背包里已有五行石时不显示对应的五行石推荐
        if nTrueIndex then
            allInfos[nTrueIndex] = nil
        end
    end

    for dwIndex, tInfo in pairs(allInfos) do
        DataModel.materialDict[dwIndex] = { totalCount = 0, list = {} }
    end
end

--- EquipSlot fnAction(nEquip,dwTabType,dwIndex)
--- WuXingStone fnAction(dwIndex)
function UICharacterLeftBag:OpenLeftPanel(tabType, fnAction, chosenMaterialCountDict, nEnchantCategory)
    if self.scriptItemTip then
        UIHelper.RemoveFromParent(self.scriptItemTip._rootNode, true)
        self.scriptItemTip = nil
    end

    if (not chosenMaterialCountDict or IsTable(chosenMaterialCountDict) == false) then
        LOG.ERROR("UICharacterLeftBag:OpenLeftPanel invalid when opening.")
        return
    end

    if not UIHelper.GetVisible(self._rootNode) then
        UIHelper.HidePageBottomBar()
        UIHelper.PlayAni(self, self.AniAll, "AniLeftShow")
    end

    if self.tbString[tabType] then
        UIHelper.SetString(self.LabelTitle, self.tbString[tabType].szTitle)
        UIHelper.SetString(self.LabelDescibe01, self.tbString[tabType].szEmptyDescribe)
    end

    DataModel.UpdateEquipList()

    self.chosenMaterialCountDict = chosenMaterialCountDict
    self.fnAction = fnAction
    self.nLeftTabType = tabType
    self.nEnchantCategory = nEnchantCategory

    if tabType == LeftTabType.WuXingStone then
        self:_InitBagMaterialLeftPanel(MaterialType.WuXingStone)
    elseif tabType == LeftTabType.WuCaiStone then
        self:_InitBagMaterialLeftPanel(MaterialType.WuCaiStone)
    elseif tabType == LeftTabType.BothStone then
        self:_InitBagMaterialLeftPanel(MaterialType.BothStone)
    elseif tabType == LeftTabType.Enchant then
        if self.nEnchantBox == nil or self.nEnchantIndex == nil then
            return OutputMessage("MSG_ANNOUNCE_NORMAL", "需要附魔的装备未设置")
        else
            self:_InitBagMaterialLeftPanel(MaterialType.Enchant)
        end
    end

    local szLabel = tTabTypeToNavigateLabel[tabType]
    UIHelper.SetVisible(self.TogTrace, szLabel ~= nil)
    UIHelper.SetString(self.LabelTrace, szLabel)
    if tabType == LeftTabType.Enchant then
        UIHelper.SetVisible(self.TogTraceFumo, true)
        UIHelper.SetVisible(self.TogTraceMuShi, true)
        UIHelper.SetVisible(self.TogTrace, false)
    end
    self:UpdateNavigationLayout(tabType)
    UIHelper.SetActiveAndCache(self, self._rootNode, true)
end

function UICharacterLeftBag:SetEnchantItem(nBox, nIndex)
    self.nEnchantBox = nBox
    self.nEnchantIndex = nIndex
end

function UICharacterLeftBag:CloseLeftPanel()
    if UIHelper.GetVisible(self._rootNode) then
        UIHelper.ShowPageBottomBar()

        UIHelper.PlayAni(self, self.AniAll, "AniLeftHide", function()
            UIHelper.SetActiveAndCache(self, self._rootNode, false)
        end)

        if self.scriptItemTip then
            UIHelper.SetVisible(self.scriptItemTip._rootNode, false)
        end
        UIHelper.SetVisible(self.WidgetAnchorAloneTips, false)
        UIHelper.SetVisible(self.WidgetAnchorRepeatedTips, false)
        UIHelper.SetVisible(self.WidgetSalesmanList, false)
    end
end

function UICharacterLeftBag:ShowItemTip(item, fnCallback)
    --local tbBtnInfo = {
    --    {
    --        szName = "置入",
    --        OnClick = fnCallback
    --    } }
    local dwIndex = item.dwIndex

    if self.scriptItemTip == nil then
        self.scriptItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetCard)
    end

    if self:IsShowItem() and DataModel.GetItemCount(dwIndex) > 0 then
        local nBox, nIndex = ItemData.GetItemPos(item.dwID)
        self.scriptItemTip:OnInit(nBox, nIndex)
    else
        self.scriptItemTip:OnInitWithTabID(ITEM_TAB_TYPE, dwIndex)
    end

    self.scriptItemTip:SetBtnState({})
end

function UICharacterLeftBag:RefreshBagCell()
    UIHelper.RemoveAllChildren(self.ScrollBag)
    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroup)
    UIHelper.SetVisible(self.WidgetContentNormal, self.nMaterialType ~= MaterialType.BothStone)
    UIHelper.SetVisible(self.WidgetContentRefineUp, self.nMaterialType == MaterialType.BothStone)

    local lst = {}
    for dwIndex, tInfo in pairs(DataModel.materialDict) do
        local itemInfo = ItemData.GetItemInfo(ITEM_TAB_TYPE, dwIndex)
        if self.nSelectedQuality == ALL_QUALITY or itemInfo.nQuality == self.nSelectedQuality then
            local nCount = DataModel.GetItemCount(dwIndex)
            local itemList = DataModel.GetItemList(dwIndex)

            if self:IsShowItemInfo() or nCount == 0 then
                local itemList = DataModel.GetItemList(dwIndex)
                local trueItem = itemList and itemList[1]
                local item = {
                    nQuality = itemInfo.nQuality,
                    nDetail = itemInfo.nDetail,
                    dwIndex = itemInfo.dwID,
                    nUiId = itemInfo.nUiId,
                    bBind = itemInfo.nBindType == 3,
                    nGenre = itemInfo.nGenre,
                }

                if trueItem then
                    item.dwID = trueItem.dwID
                end
                table.insert(lst, item)
            else
                for _, item in ipairs(itemList) do
                    table.insert(lst, item)
                end
            end
        end
    end

    local sortByAscend = function(a, b)
        local aDetail, bDetail
        if self:IsShowItem() then
            aDetail, bDetail = a.dwIndex, b.dwIndex
        else
            aDetail = a.nDetail ~= 0 and a.nDetail or 9
            bDetail = b.nDetail ~= 0 and b.nDetail or 9
        end
        return a.nQuality < b.nQuality or (a.nQuality == b.nQuality and aDetail < bDetail)
    end

    local sortByDescend = function(a, b)
        local aDetail, bDetail
        if self:IsShowItem() then
            aDetail, bDetail = a.dwIndex, b.dwIndex
        else
            aDetail = a.nDetail ~= 0 and a.nDetail or 9
            bDetail = b.nDetail ~= 0 and b.nDetail or 9
        end
        return a.nQuality > b.nQuality or (a.nQuality == b.nQuality and aDetail > bDetail)
    end

    table.sort(lst, self.bIsAscend and sortByAscend or sortByDescend)

    local chosenMaterialCountDict = self.chosenMaterialCountDict
    for nIndex, item in pairs(lst) do
        local dwIndex = item.dwIndex
        local bBind = item.bBind
        local nTotalCount = DataModel.GetItemCount(dwIndex)
        local bIsUnavailable = nTotalCount == 0
        local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetRefineMaterial_100, self.ScrollBag) ---@type UICharacterRefineMaterialCell
        local fnCallback = function()
            if self.nLeftTabType == LeftTabType.Enchant then
                if item.dwID then
                    self.fnAction(item.dwID, dwIndex)
                end
            else
                self.fnAction(dwIndex)
            end
        end

        if self:IsShowItem() and nTotalCount > 0 then
            nTotalCount = ItemData.GetItemStackNum(item) -- 附魔分类单独显示每个附魔
            itemScript:SetEnchantItemID(item.dwID)
        end

        itemScript:SetBind(bBind)
        if self:IsShowItem() then
            itemScript:RefreshInfo(EQUIP_REFINE_SLOT_TYPE.MATERIAL_IN_BAG, dwIndex, item.nUiId, item.nQuality
            , ItemData.GetItemStackNum(item), chosenMaterialCountDict[item.dwID])
        else
            itemScript:RefreshInfo(EQUIP_REFINE_SLOT_TYPE.MATERIAL_IN_BAG, dwIndex, item.nUiId, item.nQuality
            , nTotalCount, chosenMaterialCountDict[dwIndex])
        end

        UIHelper.SetButtonClickSound(itemScript.BtnCell, "")
        UIHelper.BindUIEvent(itemScript.BtnCell, EventType.OnClick, function()
            SoundMgr.PlayItemSound(item.nUiId)
            self:ShowItemTip(item)
            if not bIsUnavailable then
                fnCallback()
            end
        end)

        if bIsUnavailable then
            itemScript:SetBind(false)
            UIHelper.SetNodeGray(itemScript._rootNode, true, true)
        end
    end

    UIHelper.ScrollViewDoLayout(self.ScrollBag)
    UIHelper.ScrollToTop(self.ScrollBag, 0)
end

function UICharacterLeftBag:IsShowItemInfo()
    return self.nMaterialType == MaterialType.WuXingStone or self.nMaterialType == MaterialType.BothStone
            or self.nMaterialType == MaterialType.WuCaiStone
end

function UICharacterLeftBag:IsShowItem()
    return self.nMaterialType == MaterialType.Enchant
end

--function UICharacterLeftBag:RefreshBagCellBothStone(lst)
--    UIHelper.RemoveAllChildren(self.LayoutWuXingStone)
--    UIHelper.RemoveAllChildren(self.LayoutWuCaiStone)
--
--    local bHasColor = false
--    local chosenMaterialCountDict = self.chosenMaterialCountDict
--    for nIndex, item in pairs(lst) do
--        if item.nDetail < 6 then
--            local dwIndex, bBind -- 精炼升级主材料不大于5级
--            local bColor = item.nGenre == ITEM_GENRE.COLOR_DIAMOND
--            if bColor then
--                bHasColor = true
--            end
--
--            dwIndex = item.dwIndex
--            bBind = item.bBind
--
--            local bIsUnavailable = DataModel.GetItemCount(dwIndex) == 0
--            local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetRefineMaterial_100, bColor and self.LayoutWuCaiStone or self.LayoutWuXingStone) ---@type UICharacterRefineMaterialCell
--            itemScript:RefreshInfo(EQUIP_REFINE_SLOT_TYPE.MATERIAL_IN_BAG, dwIndex, item.nUiId, item.nQuality
--            , DataModel.GetItemCount(dwIndex), chosenMaterialCountDict[dwIndex])
--            itemScript:SetBind(bBind)
--
--            local fnCallback = function()
--                self.fnAction(dwIndex)
--            end
--            UIHelper.SetButtonClickSound(itemScript.BtnCell, "")
--            UIHelper.BindUIEvent(itemScript.BtnCell, EventType.OnClick, function()
--                SoundMgr.PlayItemSound(item.nUiId)
--                self:ShowItemTip(dwIndex)
--                fnCallback()
--            end)
--
--            if bIsUnavailable then
--                itemScript:SetBind(false)
--                UIHelper.SetNodeGray(itemScript._rootNode, true, true)
--                UIHelper.BindUIEvent(itemScript.BtnCell, EventType.OnClick, function()
--                    SoundMgr.PlayItemSound(item.nUiId)
--                    self:ShowItemTip(dwIndex)
--                end)
--            end
--        end
--    end
--
--    UIHelper.SetVisible(self.WidgetEmptyWuCai, not bHasColor)
--    UIHelper.CascadeDoLayoutDoWidget(self.ScrollBagRefine, true, true)
--    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollBagRefine)
--end



return UICharacterLeftBag