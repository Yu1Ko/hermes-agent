-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIQuickUseBagView
-- Date: 2023-02-10 17:37:43
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIQuickUseBagView = class("UIQuickUseBagView")
local OPTION_TYPE = {
    ITEM = 1,
    TOY = 2
}

function UIQuickUseBagView:OnEnter(nIndex, bIsQianJiXia)
    self.tbItemScriptList = {}
    self.tbToyScriptList = {}
    self.nIndex = nIndex
    self.nType = OPTION_TYPE.ITEM
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    if bIsQianJiXia then
        Event.Reg(self, "BAG_ITEM_UPDATE", function(nBox, nIndex, bNewAdd)
            self:UpdateQianJiXia()
        end)
        self:InitQianJiXia()
    else
        ToyBoxData.Init()
        UIHelper.SetTouchDownHideTips(self.ScrollCell, false)
        UIHelper.SetTouchDownHideTips(self.BtnClose, false)
        self:UpdateInfo()
        UIHelper.SetSelected(self.TogType1, true, false)
    end
    --UIHelper.LayoutDoLayout(self.LayoutHorizontal)
end

function UIQuickUseBagView:OnExit()
    self.bInit = false
    self:UnRegEvent()

    Event.Dispatch(EventType.OnQuickUseListCfgEnd)
    ToyBoxData.UnInit()
end

function UIQuickUseBagView:BindUIEvent()
    UIHelper.BindUIEvent(self.TogType1, EventType.OnSelectChanged, function(toggle, bSelect)
        if bSelect then
            self.nType = OPTION_TYPE.ITEM
            UIHelper.RemoveAllChildren(self.WidgetItemCard)
            self.scriptItemTip = nil
            self:UpdateUseableItemList()
        end
    end)

    UIHelper.BindUIEvent(self.TogType2, EventType.OnSelectChanged, function(toggle, bSelect)
        if bSelect then
            self.nType = OPTION_TYPE.TOY
            UIHelper.RemoveAllChildren(self.WidgetItemCard)
            self.scriptItemTip = nil
            self:UpdateUseableToyList()
        end
    end)
end

function UIQuickUseBagView:RegEvent()
    Event.Reg(self, EventType.OnQuickUseListChanged, function()
        self:UpdateRecallBtn()
        self:UpdateLabelTitle()
    end)

    Event.Reg(self, EventType.OnSceneTouchNothing, function()
        UIMgr.Close(self)
    end)

    Event.Reg(self, EventType.OnQuickUseAddItemChanged, function(nIndex)
        self.nIndex = nIndex
    end)
end

function UIQuickUseBagView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIQuickUseBagView:UpdateInfo()
    if self.nType == OPTION_TYPE.ITEM then
        self:UpdateUseableItemList()
    else
        self:UpdateUseableToyList()
    end

    self:UpdateLabelTitle()
end

function UIQuickUseBagView:UpdateUseableItemList()
    UIHelper.SetVisible(self.LayoutToyItem, false)
    UIHelper.RemoveAllChildren(self.LayoutEquip)
    UIHelper.RemoveAllChildren(self.LayoutBagItem)
    self.tbItemScriptList = {}

    -- 是否使用特殊背包，如在浪客行、吃鸡、生化等玩法中
    local bUseTravellingBag = TravellingBagData.IsInTravelingMap() or BattleFieldData.IsInTreasureBattleFieldMap() or BattleFieldData.IsInZombieBattleFieldMap()

    local tbUseableEquipList = {}
    local nItemType = bUseTravellingBag and ItemData.BoxSet.TravellingBag or ItemData.BoxSet.Equip
    for _, tbItemInfo in ipairs(ItemData.GetItemList(nItemType)) do
        if tbItemInfo.hItem and ItemData.CanQuickUse(tbItemInfo) then
            table.insert(tbUseableEquipList, tbItemInfo)
        end
    end

    UIHelper.SetVisible(self.LabelEquipTitle, #tbUseableEquipList ~= 0)
    UIHelper.SetVisible(self.LayoutEquip, #tbUseableEquipList ~= 0)

    for _, tbItemInfo in ipairs(tbUseableEquipList) do
        local dwTabType, dwIndex = tbItemInfo.hItem.dwTabType, tbItemInfo.hItem.dwIndex
        local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.LayoutEquip)
        itemScript:OnInit(tbItemInfo.nBox, tbItemInfo.nIndex, false)
        itemScript:SetClickCallback(function(_, _)
            ItemData.AddQuickUseList(dwTabType, dwIndex, nil, self.nIndex)

            self.tbSelected = { nBox = tbItemInfo.nBox, nIndex = tbItemInfo.nIndex }
            self:UpdateSelectedItemDetails()
        end)
        itemScript:SetRecallCallback(function()
            ItemData.RemoveQuickUseList(dwTabType, dwIndex)

            self.tbSelected = { nBox = nil, nIndex = nil }
            self:UpdateSelectedItemDetails()
        end)
        itemScript:SetRecallVisible(ItemData.IsInQuickUseList(dwTabType, dwIndex))
        itemScript:SetToggleGroupIndex(ToggleGroupIndex.QuickUseItemBagView)

        table.insert(self.tbItemScriptList, { Script = itemScript, dwTabType = dwTabType, dwIndex = dwIndex })
        UIHelper.SetSwallowTouches(itemScript.ToggleSelect, false)
        UIHelper.SetTouchDownHideTips(itemScript.ToggleSelect, false)
        UIHelper.SetTouchDownHideTips(itemScript.BtnRecall, false)
    end
    UIHelper.LayoutDoLayout(self.LayoutEquip)

    local tbUseableItemList = {}
    for _, tbItemInfo in ipairs(ItemData.GetItemList(ItemData.BoxSet.Bag)) do
        if tbItemInfo.hItem and ItemData.CanQuickUse(tbItemInfo) then
            table.insert(tbUseableItemList, tbItemInfo)
        end
    end

    if not bUseTravellingBag then
        for nIndex = 1, Storage.QuickUse.nMaxSlotCount, 1 do
            local tbItemTab = Storage.QuickUse.tbItemTypeList[nIndex]
            if tbItemTab and not tbItemTab.bToy and not ItemData.GetItemPos(tbItemTab.dwTabType, tbItemTab.dwIndex) then
                local tbItem = { hItem = { dwTabType = tbItemTab.dwTabType, dwIndex = tbItemTab.dwIndex } }
                table.insert(tbUseableItemList, tbItem)
            end
        end
        tbUseableItemList = self:SortUseableItemList(tbUseableItemList)
    end

    tbUseableItemList = bUseTravellingBag and {} or tbUseableItemList--在浪客行地图只有浪客行中的指定物品

    UIHelper.SetVisible(self.LabelBagItemTitle, #tbUseableItemList ~= 0)
    UIHelper.SetVisible(self.LayoutBagItem, #tbUseableItemList ~= 0)

    for _, tbItemInfo in ipairs(tbUseableItemList) do
        local dwTabType, dwIndex = tbItemInfo.hItem.dwTabType, tbItemInfo.hItem.dwIndex
        local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.LayoutBagItem)
        if tbItemInfo.nBox and tbItemInfo.nIndex then
            itemScript:OnInit(tbItemInfo.nBox, tbItemInfo.nIndex, false)
        else
            itemScript:OnInitWithTabID(dwTabType, dwIndex, 0)
            itemScript:SetColor(cc.c3b(55, 55, 55))
        end
        itemScript:SetClickCallback(function(_, _)
            ItemData.AddQuickUseList(dwTabType, dwIndex, nil, self.nIndex)

            self.tbSelected = { nBox = tbItemInfo.nBox, nIndex = tbItemInfo.nIndex }
            self:UpdateSelectedItemDetails()
        end)
        itemScript:SetRecallCallback(function()
            ItemData.RemoveQuickUseList(dwTabType, dwIndex)

            self.tbSelected = { nBox = nil, nIndex = nil }
            self:UpdateSelectedItemDetails()
        end)
        itemScript:SetToggleGroupIndex(ToggleGroupIndex.QuickUseItemBagView)

        table.insert(self.tbItemScriptList, { Script = itemScript, dwTabType = dwTabType, dwIndex = dwIndex })
        UIHelper.SetSwallowTouches(itemScript.ToggleSelect, false)
        UIHelper.SetTouchDownHideTips(itemScript.ToggleSelect, false)
        UIHelper.SetTouchDownHideTips(itemScript.BtnRecall, false)
    end
    UIHelper.LayoutDoLayout(self.LayoutBagItem)

    UIHelper.SetVisible(self.WidgetEmpty, #tbUseableEquipList == 0 and #tbUseableItemList == 0)

    self:UpdateRecallBtn()

    UIHelper.ScrollViewDoLayout(self.ScrollCell)
    UIHelper.ScrollToTop(self.ScrollCell, 0)
end

function UIQuickUseBagView:AddItemToQuickUse(dwItemID)
    local item = ItemData.GetItem(dwItemID)
    if not item then
        return
    end

    if not ItemData.IsInQuickUseList(item.dwTabType, item.dwIndex) then
        ItemData.AddQuickUseList(item.dwTabType, item.dwIndex)
    end
end

function UIQuickUseBagView:RemoveItemFromQuickUse(dwItemID)
    local item = ItemData.GetItem(dwItemID)
    if not item then
        return
    end

    ItemData.RemoveQuickUseList(item.dwTabType, item.dwIndex)
end

function UIQuickUseBagView:UpdateSelectedItemDetails(bToy)
    if not self.scriptItemTip then
        self.scriptItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemCard)
    end

    if self.scriptItemTip then
        self.scriptItemTip:SetFunctionButtons({})
        if bToy then
            self.scriptItemTip:OnInitOperationBoxItem(self.tbSelected, function(useboxInfo)
            end)
            self.scriptItemTip:SetBtnState({})
        else
            self.scriptItemTip:OnInit(self.tbSelected.nBox, self.tbSelected.nIndex)
        end
    end
end

function UIQuickUseBagView:UpdateRecallBtn()
    for _, tbItemScriptInfo in ipairs(self.tbItemScriptList) do
        local bIsInQuickUseList = ItemData.IsInQuickUseList(tbItemScriptInfo.dwTabType, tbItemScriptInfo.dwIndex)
        tbItemScriptInfo.Script:SetRecallVisible(bIsInQuickUseList)
    end

    for _, tbToyScriptInfo in ipairs(self.tbToyScriptList) do
        local bToyIsInQuickUseList = ItemData.IsToyInQuickUseList(tbToyScriptInfo.dwID)
        tbToyScriptInfo.Script:SetRecallVisible(bToyIsInQuickUseList)
    end
end

function UIQuickUseBagView:UpdateLabelTitle()
    local tbItemTypeList = TravellingBagData.IsInTravelingMap() and Storage.QuickUse.tbItemTypeListInLKX or Storage.QuickUse.tbItemTypeList
    UIHelper.SetString(self.LabelTitle, string.format(g_tStrings.STR_EDIT_QUICK_USE,
            table.get_len(tbItemTypeList), Storage.QuickUse.nMaxSlotCount))
end

function UIQuickUseBagView:UpdateUseableToyList()
    UIHelper.SetVisible(self.LayoutToyItem, true)
    UIHelper.SetVisible(self.LayoutBagItem, false)
    UIHelper.SetVisible(self.LayoutEquip, false)
    UIHelper.RemoveAllChildren(self.LayoutToyItem)

    self.tbToyScriptList = {}
    ToyBoxData.UpdateStatus()
    local tShowBoxInfo = ToyBoxData.GetShowBoxInfo("", ToyBoxData.szChooseHave)
    local tbNewBoxInfo = {}
    for k, v in pairs(tShowBoxInfo) do
        if v.bIsHave then
            table.insert(tbNewBoxInfo, v)
        end
    end
    table.sort(tbNewBoxInfo, function(a, b)
        if a.nQuality == b.nQuality then
            return a.nIcon > b.nIcon
        else
            return a.nQuality > b.nQuality
        end
    end)

    UIHelper.SetVisible(self.WidgetEmpty, table.get_len(tbNewBoxInfo) == 0)
    for k, v in ipairs(tbNewBoxInfo) do
        if v then
            local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.LayoutToyItem)
            if itemScript then
                itemScript:OnInitWithIconID(v.nIcon, v.nQuality)
                itemScript:SetClickCallback(function(_, _)
                    ItemData.AddToyQuickUseList(v.dwID, self.nIndex)

                    self.tbSelected = v
                    self:UpdateSelectedItemDetails(true)
                end)
                itemScript:SetRecallCallback(function()
                    ItemData.RemoveQuickUseToyList(v.dwID)
                    UIHelper.RemoveAllChildren(self.WidgetItemCard)
                    self.scriptItemTip = nil
                end)
                itemScript:SetRecallVisible(ItemData.IsToyInQuickUseList(v.dwID))

                itemScript:SetToggleGroupIndex(ToggleGroupIndex.QuickUseItemBagView)

                table.insert(self.tbToyScriptList, { Script = itemScript, dwID = v.dwID })
                UIHelper.SetSwallowTouches(itemScript.ToggleSelect, false)
                UIHelper.SetTouchDownHideTips(itemScript.ToggleSelect, false)
                UIHelper.SetTouchDownHideTips(itemScript.BtnRecall, false)
            end
        end
    end

    self:UpdateRecallBtn()
    UIHelper.LayoutDoLayout(self.LayoutToyItem)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollCell)
end

function UIQuickUseBagView:SortUseableItemList(tbUseableItemList)
    if not tbUseableItemList or table.is_empty(tbUseableItemList) then
        return {}
    end

    local fnSort = function(a, b)
        local bAIsInQuickUseList = ItemData.IsInQuickUseList(a.hItem.dwTabType, a.hItem.dwIndex)
        local bBIsInQuickUseList = ItemData.IsInQuickUseList(b.hItem.dwTabType, b.hItem.dwIndex)
        if bAIsInQuickUseList and not bBIsInQuickUseList then
            return true
        end
        return false
    end

    table.sort(tbUseableItemList, fnSort)

    return tbUseableItemList
end

function UIQuickUseBagView:InitQianJiXia()
    UIHelper.SetString(self.LabelTitle, "背包")
    UIHelper.SetVisible(self.LayoutToyItem, false)
    UIHelper.SetVisible(self.TogType2, false)
    UIHelper.RemoveAllChildren(self.LayoutBagItem)

    UIHelper.SetSelected(self.TogType1, true, false)
    UIHelper.BindUIEvent(self.TogType1, EventType.OnSelectChanged, function(toggle, bSelect)
    end)
    
    self:UpdateQianJiXia()
end

function UIQuickUseBagView:UpdateQianJiXiaItemTips(hItem, nBox, nIndex)
    if not self.scriptItemTip then
        self.scriptItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemCard)
    end

    local fnExchangeClick = function(nCount, nBox, nIndex)
        ItemData.StoreTangMenBullet(nBox, nIndex, nCount)
        UIHelper.SetVisible(self.scriptItemTip._rootNode, false)
    end

    local szCountTitle = "存入数量："
    local szConfirmLabel = g_tStrings.tbItemString.STORE_ITEM_CONFIRM_DIALOG_BUTTON_NAME
    if hItem then
        local tbFuncButtons = {}
        local nStackNum = ItemData.GetItemStackNum(hItem)
        self.scriptItemTip:ShowWareHouseSlider(nStackNum, nStackNum, szConfirmLabel, szCountTitle, fnExchangeClick, tbFuncButtons)
        self.scriptItemTip:ShowWareHousePreviewSlider(hItem.dwTabType, hItem.dwIndex)
    end

    self.scriptItemTip:OnInit(nBox, nIndex, false)
end

function UIQuickUseBagView:UpdateQianJiXia()
    UIHelper.RemoveAllChildren(self.LayoutEquip)

    local tbUseableEquipList = {}
    local tbBoxSet = ItemData.BoxSet.Bag
    local tbItemList = ItemData.GetItemList(tbBoxSet)
    for _, tbItemInfo in ipairs(tbItemList) do
        local dwItemCurrentType = tbItemInfo.hItem and tbItemInfo.hItem.dwIndex
        if dwItemCurrentType == 4000 or dwItemCurrentType == 4014 then
            table.insert(tbUseableEquipList, tbItemInfo)
        end
    end

    for _, tbItemInfo in ipairs(tbUseableEquipList) do
        local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.LayoutEquip)
        itemScript:OnInit(tbItemInfo.nBox, tbItemInfo.nIndex, false)
        itemScript:SetClickCallback(function(_, _)
            self:UpdateQianJiXiaItemTips(tbItemInfo.hItem, tbItemInfo.nBox, tbItemInfo.nIndex)
        end)
        itemScript:SetToggleGroupIndex(ToggleGroupIndex.QuickUseItemBagView)

        UIHelper.SetSwallowTouches(itemScript.ToggleSelect, false)
        UIHelper.SetTouchDownHideTips(itemScript.ToggleSelect, false)
        UIHelper.SetTouchDownHideTips(itemScript.BtnRecall, false)
    end

    UIHelper.LayoutDoLayout(self.LayoutEquip)
    UIHelper.SetVisible(self.WidgetEmpty, #tbUseableEquipList == 0)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollCell)
end

return UIQuickUseBagView