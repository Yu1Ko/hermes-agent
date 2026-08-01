-- ---------------------------------------------------------------------------------
-- Author: Jiayuran
-- Name: UIWidgetChooseWuXingTips
-- Date: 2024-9-23 14:39
-- Desc: UIWidgetChooseWuXingTips
-- ---------------------------------------------------------------------------------
local ITEM_TAB_TYPE = 5
local MAX_MATERIAL_LIMIT = 128
local SLIDER_WIDTH = 328
local MILLION_NUMBER = 1048576 --百分率基数

---@class UIWidgetChooseWuXingTips
local UIWidgetChooseWuXingTips = class("UIWidgetChooseWuXingTips")

function UIWidgetChooseWuXingTips:OnEnter(fnAction)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        UIHelper.SetEditboxTextHorizontalAlign(self.EditPaginate, TextHAlignment.CENTER)
    end

    self.tCountDict = self.tCountDict or {}
    self.tAvailableList = {}
    self.fnAction = fnAction

    UIHelper.RemoveAllChildren(self.LayoutSalesmanList)

    local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetSalesmanListCell, self.LayoutSalesmanList)
    local tParent = self.WidgetSalesmanList
    cell:SetLabelText("五行石商店获取")
    cell:BindClickFunction(function()
        ShopData.OpenSystemShopGroup(1, 407, 5, 24423)
        UIHelper.SetVisible(tParent, false)
    end)

    cell = UIHelper.AddPrefab(PREFAB_ID.WidgetSalesmanListCell, self.LayoutSalesmanList)
    cell:SetLabelText("交易行获取")
    cell:BindClickFunction(function()
        TradingData.OpenSourceTradeSearchPanel("5/24423")
        UIHelper.SetVisible(tParent, false)
    end)

    UIHelper.LayoutDoLayout(self.LayoutSalesmanList)
end

function UIWidgetChooseWuXingTips:OnExit()
    self.bInit = false
end

function UIWidgetChooseWuXingTips:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSalesmanClose, EventType.OnClick, function()
        UIHelper.SetVisible(self.WidgetSalesmanList, false)
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIHelper.SetVisible(self._rootNode, false)
    end)

    UIHelper.BindUIEvent(self.BtnGetWuXing, EventType.OnClick, function()
        UIHelper.SetVisible(self.WidgetSalesmanList, true)
    end)

    UIHelper.BindUIEvent(self.ButtonAdd, EventType.OnClick, function()
        if self.dwSelectedItemID then
            local nOriginalCount = self.tCountDict[self.dwSelectedItemID]
            self:ModifySelectedNum(nOriginalCount + 1)
        end
    end)

    UIHelper.BindUIEvent(self.ButtonDecrease, EventType.OnClick, function()
        if self.dwSelectedItemID then
            local nOriginalCount = self.tCountDict[self.dwSelectedItemID]
            self:ModifySelectedNum(nOriginalCount - 1)
        end
    end)

    UIHelper.BindUIEvent(self.SliderCount, EventType.OnChangeSliderPercent, function(SliderEventType, nSliderEvent)
        if nSliderEvent == ccui.SliderEventType.slideBallDown then
            self.bSliding = true
        elseif nSliderEvent == ccui.SliderEventType.slideBallUp then
            self.bSliding = false
            -- 强制修正滑块进度
            local nPercent = (self.nCurrentValue - self.nMinVal) / (self.nMaxVal - self.nMinVal) * 100
            UIHelper.SetProgressBarPercent(self.SliderCount, nPercent)
            UIHelper.SetWidth(self.ImgAdjustment, nPercent * SLIDER_WIDTH / 100)
            self:ModifySelectedNum(self.nCurrentValue)

            LOG.WARN("OnChangeSliderPercent %d", UIHelper.GetProgressBarPercent(self.SliderCount))
        end

        if self.bSliding then
            local nPercent = UIHelper.GetProgressBarPercent(self.SliderCount)
            self.nCurrentValue = nPercent / 100 * (self.nMaxVal - self.nMinVal) + self.nMinVal
            self.nCurrentValue = math.min(self.nCurrentValue, self.nMaxVal)
            self.nCurrentValue = math.max(self.nCurrentValue, self.nMinVal)
            self.nCurrentValue = math.ceil(self.nCurrentValue)
            UIHelper.SetText(self.EditPaginate, self.nCurrentValue)
            UIHelper.SetWidth(self.ImgAdjustment, nPercent * SLIDER_WIDTH / 100)
        end
    end)

    local fnCallback = function()
        local nNewCount = tonumber(UIHelper.GetText(self.EditPaginate)) or 0
        nNewCount = math.max(self.nMinVal, nNewCount)
        nNewCount = math.min(self.nMaxVal, nNewCount)
        self:ModifySelectedNum(nNewCount)
    end
    if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditPaginate, function()
            fnCallback()
        end)
    else
        UIHelper.RegisterEditBoxReturn(self.EditPaginate, function()
            fnCallback()
        end)
    end
end

function UIWidgetChooseWuXingTips:RegEvent()
    Event.Reg(self, "FE_STRENGTH_EQUIP", function(arg0)
        self:ClearMaterial()
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnGameNumKeyboardChanged, function(editbox, num)
        if editbox ~= self.EditPaginate then
            return
        end

        local nNewCount = tonumber(UIHelper.GetText(self.EditPaginate)) or 0
        nNewCount = math.max(self.nMinVal, nNewCount)
        nNewCount = math.min(self.nMaxVal, nNewCount)
        self:ModifySelectedNum(nNewCount)
    end)
end

function UIWidgetChooseWuXingTips:UpdateInfo()
    self:UpdateMaterialList()
    self:RefreshCell()
end

function UIWidgetChooseWuXingTips:UpdateMaterialList()
    self.tAvailableList = {}

    local filterFunc = function(item)
        return item.nGenre == ITEM_GENRE.DIAMOND
    end

    for _, tbItemInfo in ipairs(ItemData.GetItemList(ItemData.BoxSet.Bag)) do
        local bShowItem = false
        if tbItemInfo.hItem then
            bShowItem = filterFunc(tbItemInfo.hItem)
        end

        if bShowItem then
            local item = ItemData.GetItemByPos(tbItemInfo.nBox, tbItemInfo.nIndex)
            table.insert(self.tAvailableList, item)
        end
    end
end

function UIWidgetChooseWuXingTips:ShowPanel()
    UIHelper.SetVisible(self._rootNode, true)
    self:RefreshCount(true)
end

function UIWidgetChooseWuXingTips:RefreshCell()
    local lst = self.tAvailableList
    local tCountDict = self.tCountDict or {}
    local nSelectedCount = self:GetRefineExpendMaterial()

    table.sort(lst, function(a, b)
        local aDetail = a.nDetail ~= 0 and a.nDetail or 9
        local bDetail = b.nDetail ~= 0 and b.nDetail or 9
        return a.nQuality < b.nQuality or (a.nQuality == b.nQuality and aDetail < bDetail)
    end)

    self.itemScripts = {}
    UIHelper.RemoveAllChildren(self.ScrollViewWuXingList)

    for nIndex, item in pairs(lst) do
        local dwIndex, bBind, dwItemUniqueIndex

        dwIndex = item.dwIndex
        bBind = item.bBind
        dwItemUniqueIndex = item.dwID

        tCountDict[dwItemUniqueIndex] = tCountDict[dwItemUniqueIndex] or 0

        local itemInfo = ItemData.GetItemInfo(ITEM_TAB_TYPE, dwIndex)
        local bIsUnavailable = item.dwID == nil
        local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetRefineMaterial_100, self.ScrollViewWuXingList) ---@type UICharacterRefineMaterialCell
        itemScript:RefreshInfo(EQUIP_REFINE_SLOT_TYPE.MATERIAL_IN_BAG
        , dwIndex, item.nUiId, item.nQuality, ItemData.GetItemStackNum(item), tCountDict[dwItemUniqueIndex])
        itemScript:SetBind(bBind)
        table.insert(self.itemScripts, itemScript)

        local fnCallback = function()
            self:RefreshCount()
            UIHelper.SetVisible(itemScript.ImgSelectBG, true)
        end

        UIHelper.SetButtonClickSound(itemScript.BtnCell, "")
        UIHelper.BindUIEvent(itemScript.BtnCell, EventType.OnClick, function()
            SoundMgr.PlayItemSound(item.nUiId)
            self:ShowItemTip(ITEM_TAB_TYPE, dwIndex)
            self:UpdateSelectedMaterialInfo(dwItemUniqueIndex, item, itemInfo)
            fnCallback()
        end)

        if bIsUnavailable then
            itemScript:SetBind(false)
            UIHelper.SetNodeGray(itemScript._rootNode, true, true)
            UIHelper.BindUIEvent(itemScript.BtnCell, EventType.OnClick, function()
                SoundMgr.PlayItemSound(item.nUiId)
                self:ShowItemTip(ITEM_TAB_TYPE, dwIndex)
            end)
        end

        if nIndex == 1 and nSelectedCount == 0 then
            self:OnSelectItem(item, itemScript)
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewWuXingList)
    UIHelper.ScrollViewSetupArrow(self.ScrollViewWuXingList, self.WidgetArrowParent)
    UIHelper.SetVisible(self.WidgetEmpty, #lst <= 0)
    UIHelper.SetVisible(self.WidgetBottom, #lst > 0)
end

function UIWidgetChooseWuXingTips:RefreshCount(bSelectFirst)
    local lst = self.tAvailableList
    local tCountDict = self.tCountDict or {}

    local fnFirstSelect = function(item, itemScript)
        UIHelper.ScrollLocateToPreviewItem(self.ScrollViewWuXingList, itemScript._rootNode, Locate.TO_CENTER)
        self:OnSelectItem(item, itemScript)
    end

    for nIndex, item in pairs(lst) do
        local dwIndex, dwItemUniqueIndex

        dwIndex = item.dwIndex
        dwItemUniqueIndex = item.dwID

        local itemScript = self.itemScripts[nIndex] ---@type UICharacterRefineMaterialCell
        itemScript:RefreshInfo(EQUIP_REFINE_SLOT_TYPE.MATERIAL_IN_BAG
        , dwIndex, item.nUiId, item.nQuality, ItemData.GetItemStackNum(item), tCountDict[dwItemUniqueIndex])

        if bSelectFirst and tCountDict[dwItemUniqueIndex] and tCountDict[dwItemUniqueIndex] > 0 then
            fnFirstSelect(item, itemScript)
            bSelectFirst = false
        end
    end

    if bSelectFirst then
        local item = lst[1]
        local itemScript = self.itemScripts[1] ---@type UICharacterRefineMaterialCell
        fnFirstSelect(item, itemScript)
    end

    UIHelper.SetString(self.LabelTitle, string.format("选择五行石(%d/%d)", self:GetRefineExpendMaterial(), MAX_MATERIAL_LIMIT))
end

function UIWidgetChooseWuXingTips:OnSelectItem(item, itemScript)
    local itemInfo = ItemData.GetItemInfo(ITEM_TAB_TYPE, item.dwIndex)
    UIHelper.SetVisible(itemScript.ImgSelectBG, true) -- 列表中没有任何选中状态
    self:UpdateSelectedMaterialInfo(item.dwID, item, itemInfo)
end

function UIWidgetChooseWuXingTips:ShowItemTip(dwTabType, dwIndex)
    local tip, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, self._rootNode, TipsLayoutDir.RIGHT_CENTER)
    script:OnInitWithTabID(dwTabType, dwIndex)
    script:SetBtnState({})
end

function UIWidgetChooseWuXingTips:UpdateSelectedMaterialInfo(dwItemUniqueIndex, item, itemInfo)
    if dwItemUniqueIndex and item then
        self.dwSelectedItemID = dwItemUniqueIndex
        self.dwTargetItem = item
        self.nMinVal = 0
        self.nCurrentValue = self.tCountDict[self.dwSelectedItemID]

        local nCurrentStackNum = ItemData.GetItemStackNum(self.dwTargetItem)
        self.nMaxVal = MAX_MATERIAL_LIMIT - (self:GetTotalSelectedCount() - self.nCurrentValue) -- 计算可放入的最大数量，避免超过128
        self.nMaxVal = math.min(nCurrentStackNum, self.nMaxVal)

        self:UpdateSlider()
    end

    if itemInfo then
        local nDiamondR, nDiamondG, nDiamondB = GetItemFontColorByQuality(itemInfo.nQuality)
        local szMainStoneName = GetFormatText(UIHelper.GBKToUTF8(itemInfo.szName), nil, nDiamondR, nDiamondG, nDiamondB)
        szMainStoneName = szMainStoneName .. "- " .. (itemInfo.nBindType ~= ITEM_BIND.BIND_ON_PICKED
                and g_tStrings.STR_ITEM_H_NOT_BIND or g_tStrings.STR_ITEM_H_HAS_BEEN_BIND)
        UIHelper.SetRichText(self.RichTextWuXingName, szMainStoneName)
    end
end

function UIWidgetChooseWuXingTips:UpdateSlider()
    if self.dwSelectedItemID then
        local nCurrentValue = self.tCountDict[self.dwSelectedItemID]
        UIHelper.SetText(self.EditPaginate, nCurrentValue)
        local nPercent = (nCurrentValue - self.nMinVal) / (self.nMaxVal - self.nMinVal) * 100
        UIHelper.SetProgressBarPercent(self.SliderCount, nPercent)
        UIHelper.SetWidth(self.ImgAdjustment, nPercent * SLIDER_WIDTH / 100)
    end
end

function UIWidgetChooseWuXingTips:GetTotalSelectedCount()
    local nTotal = 0
    for _, nNum in pairs(self.tCountDict) do
        nTotal = nTotal + nNum
    end
    return nTotal
end

function UIWidgetChooseWuXingTips:ModifySelectedNum(nTarget)
    if self.dwSelectedItemID and self.dwTargetItem then

        local nCount, t = self:GetRefineExpendMaterial()
        if nCount > 0 then
            local nEquip = DataModel.GetSelect(1)
            if nEquip == EQUIPMENT_INVENTORY.BIG_SWORD then
                nEquip = EQUIPMENT_INVENTORY.MELEE_WEAPON
            end
            local bResult, nCostMoney, nSuccessRate, nCostVigor, nCostTrain, nDiscount, bDiscount = GetStrengthEquipBoxInfo(nEquip, t)
            local nUpgradeTotalRate = nSuccessRate / MILLION_NUMBER * 100
            if bDiscount then
                nUpgradeTotalRate = nDiscount / MILLION_NUMBER * 100
            end

            if nTarget > self.tCountDict[self.dwSelectedItemID] and nUpgradeTotalRate >= 100 then
                nTarget = self.tCountDict[self.dwSelectedItemID]
                TipsHelper.ShowImportantYellowTip(g_tStrings.STR_MAX_RATE)
            end
        end

        if nTarget > self.nMaxVal then
            nTarget = self.tCountDict[self.dwSelectedItemID]
            TipsHelper.ShowImportantYellowTip("材料数量已到达上限")
        end
        
        local nNewCount = nTarget
        nNewCount = math.max(0, nNewCount)
        nNewCount = math.min(self.nMaxVal, nNewCount) -- 计算可放入的最大数量，避免超过128

        if nNewCount ~= self.tCountDict[self.dwSelectedItemID] then
            self.tCountDict[self.dwSelectedItemID] = nNewCount
            self:RefreshCount()
            self.fnAction()
        end
        self:UpdateSlider()
    end
end

function UIWidgetChooseWuXingTips:ClearMaterial()
    if self.tCountDict then
        for nKey, nNum in pairs(self.tCountDict) do
            self.tCountDict[nKey] = 0
        end
        self:RefreshCount()
        self:UpdateSelectedMaterialInfo(self.dwSelectedItemID, self.dwTargetItem)
        self.fnAction()
    end
end

function UIWidgetChooseWuXingTips:AutoFillDiamond(tMaterial)
    for k, v in pairs(tMaterial) do
        local KItem = ItemData.GetItemByPos(v.dwBox, v.dwX)
        self.tCountDict[KItem.dwID] = v.nStackNum
    end
    self:RefreshCount(true)
    self:UpdateSelectedMaterialInfo(self.dwSelectedItemID, self.dwTargetItem)
    self.fnAction()
end

function UIWidgetChooseWuXingTips:GetRefineExpendMaterial()
    local nCount, t = 0, {}
    if self.tCountDict then
        for nKey, nNum in pairs(self.tCountDict) do
            nCount = nCount + nNum
            local dwBox, dwX = ItemData.GetItemPos(nKey)
            for _ = 1, nNum do
                table.insert(t, { dwBox, dwX })
            end
        end
    end
    return nCount, t
end

return UIWidgetChooseWuXingTips