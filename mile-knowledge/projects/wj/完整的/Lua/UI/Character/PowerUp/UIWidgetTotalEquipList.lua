-- ---------------------------------------------------------------------------------
-- Author: Jiayuran
-- Name: UICharacterWidgetEquipRefine
-- Date: 2022-12-06 14:39
-- Desc: UICharacterWidgetEquipRefine
-- ---------------------------------------------------------------------------------

local m_tValidEquipSub = {
    [EQUIPMENT_SUB.CHEST] = true, -- "上衣",
    [EQUIPMENT_SUB.PANTS] = true, -- "下装",
    [EQUIPMENT_SUB.HELM] = true, -- "帽子",
    [EQUIPMENT_SUB.WAIST] = true, -- "腰带",
    [EQUIPMENT_SUB.BANGLE] = true, -- "护腕",
    [EQUIPMENT_SUB.BOOTS] = true, -- "鞋子",
    [EQUIPMENT_SUB.AMULET] = true, -- "项链",
    [EQUIPMENT_SUB.RING] = true, -- "戒指",
    [EQUIPMENT_SUB.PENDANT] = true, -- "腰坠",
    [EQUIPMENT_SUB.MELEE_WEAPON] = true, -- "近身武器",
    [EQUIPMENT_SUB.RANGE_WEAPON] = true, -- "远程武器",
    [EQUIPMENT_SUB.ARROW] = false, -- "暗器",
}

local m_tValidEquipSubForInfusion = {
    [EQUIPMENT_SUB.MELEE_WEAPON] = true, -- "近身武器",
    --[EQUIPMENT_SUB.RANGE_WEAPON] = true, -- "远程武器",
}

local EQUIPMENT_SHOW_ALL = 12

local tbFilterType = {
    [1] = EQUIPMENT_SHOW_ALL, -- "全部显示"
    [2] = EQUIPMENT_SUB.MELEE_WEAPON, -- "近身武器"
    [3] = EQUIPMENT_SUB.RANGE_WEAPON, -- "远程武器"
    [4] = EQUIPMENT_SUB.HELM, -- "帽子"
    [5] = EQUIPMENT_SUB.CHEST, -- "上衣"
    [6] = EQUIPMENT_SUB.WAIST, -- "腰带"
    [7] = EQUIPMENT_SUB.BANGLE, -- "护腕"
    [8] = EQUIPMENT_SUB.PANTS, -- "下装"
    [9] = EQUIPMENT_SUB.BOOTS, -- "鞋子"
    [10] = EQUIPMENT_SUB.AMULET, -- "项链"
    [11] = EQUIPMENT_SUB.PENDANT, -- "腰坠"
    [12] = EQUIPMENT_SUB.RING, -- "戒指"
}

---@class UIWidgetTotalEquipList
local UIWidgetTotalEquipList = class("UIWidgetTotalEquipList")

function UIWidgetTotalEquipList:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetTotalEquipList:OnExit()
    self.bInit = false
    Event.UnRegAll(self)
end

function UIWidgetTotalEquipList:BindUIEvent()
    for nIndex, tog in ipairs(self.tbTogEquipPreset) do
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupPreset, tog)
        UIHelper.BindUIEvent(tog, EventType.OnClick, function()
            EquipData.SwitchEquip(nIndex)
            self.nCurEquipPageIndex = nIndex
            UIHelper.SetToggleGroupSelected(self.ToggleGroupPreset, self.nCurEquipPageIndex - 1)
            UIHelper.SetSelected(self.TogPreset, false)
        end)
    end

    UIHelper.BindUIEvent(self.BtnBlock, EventType.OnClick, function()
        UIHelper.SetSelected(self.TogPreset, false)
    end)
    
    UIHelper.BindUIEvent(self.TogFilter, EventType.OnClick, function()
        local tbConfig = FilterDef.EnchantEquipType
        tbConfig[1].tbDefault = { 1 }
        _, self.scriptFilter = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.TogFilter, TipsLayoutDir.Right, tbConfig)
    end)
end

function UIWidgetTotalEquipList:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function()
        if self.scriptItemTip then
            UIHelper.SetVisible(self.scriptItemTip._rootNode, false)
        end
    end)

    Event.Reg(self, EventType.OnFilter, function(szKey, tbSelected)
        if szKey == FilterDef.EnchantEquipType.Key then
            self.nEquipSub = tbFilterType[tbSelected[1][1]]
            LOG.TABLE(tbSelected)
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, "EQUIP_CHANGE", function(result)
        if result == ITEM_RESULT_CODE.SPRINT then
            TipsHelper.ShowNormalTip("轻功中无法切换套装", false)
            self:UpdateInfo()
            return
        end

        if result ~= ITEM_RESULT_CODE.SUCCESS then
            if result == ITEM_RESULT_CODE.DISARM then
                TipsHelper.ShowNormalTip("马上无法切换装备以及交换物品，请侠士下马后再次尝试")
            else
                TipsHelper.ShowNormalTip(g_tStrings.tItem_Msg[result])
            end
            self:UpdateInfo()
            return
        end

        self:UpdateInfo()
    end)
end

function UIWidgetTotalEquipList:Filter(pItem)
    if pItem then
        if pItem.nGenre == ITEM_GENRE.EQUIPMENT and self.tValidEquipSub[pItem.nSub] then
            local bShowAll = self.nEquipSub == EQUIPMENT_SHOW_ALL
            return bShowAll or self.nEquipSub == pItem.nSub
        end
    end
end

function UIWidgetTotalEquipList:Init(szButtonName, fnCallback, bIsInfusion)
    self:OnEnter()
    
    self.nEquipSub = EQUIPMENT_SHOW_ALL

    UIHelper.SetVisible(self.TogFilter, not bIsInfusion)

    self.tValidEquipSub = bIsInfusion and clone(m_tValidEquipSubForInfusion) or clone(m_tValidEquipSub)

    self.ShowItemTip = function(nBox, nIndex)
        if self.scriptItemTip == nil then
            self.scriptItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemTipsShell)
        end

        local tbBtnInfo = {
            --{ szName = szButtonName,
            --  OnClick = function()
            --      if fnCallback then
            --          fnCallback(nBox, nIndex)
            --      end
            --      UIHelper.SetVisible(self.scriptItemTip._rootNode, false)
            --  end }
        }

        UIHelper.SetVisible(self.scriptItemTip._rootNode, true)
        self.scriptItemTip:HidePreviewBtn(true)
        self.scriptItemTip:SetForbidShowEquipCompareBtn(true)
        self.scriptItemTip:OnInit(nBox, nIndex, false)
        self.scriptItemTip:SetBtnState(tbBtnInfo)

        if fnCallback then
            fnCallback(nBox, nIndex)
        end
    end

    self:UpdateInfo()
end

function UIWidgetTotalEquipList:UpdateInfo()
    local nIndex = g_pClientPlayer.GetEquipIDArray(INVENTORY_INDEX.EQUIP)
    UIHelper.SetToggleGroupSelected(self.ToggleGroupPreset, nIndex, false)
    UIHelper.SetString(self.LabelNum, nIndex + 1)
    
    UIHelper.RemoveAllChildren(self.LayoutInBagItems)
    for i = 1, 4 do
        UIHelper.RemoveAllChildren(self.backupLayouts[i])
    end

    local tUnequippedList = {}
    local tEquippedList = {
        [1] = {},
        [2] = {},
        [3] = {},
        [4] = {},
    }

    local bHasEquip = false

    --- 遍历背包装备
    for _, tbItemInfo in ipairs(ItemData.GetItemList(ItemData.BoxSet.Bag)) do
        if tbItemInfo.hItem and self:Filter(tbItemInfo.hItem) then
            table.insert(tUnequippedList, tbItemInfo.hItem)
        end
    end

    --- 遍历身上装备
    for nIndex, nMainEnum in ipairs(EquipMainEnumList) do
        for _, nEquipEnum in ipairs(EquipSlotEnum) do
            local item = ItemData.GetItemByPos(nMainEnum, nEquipEnum)
            if item and self:Filter(item) then
                table.insert(tEquippedList[nIndex], item)
            end
        end
    end

    local sortByAscend = function(a, b)
        local aDetail = a.nDetail ~= 0 and a.nDetail or 9
        local bDetail = b.nDetail ~= 0 and b.nDetail or 9
        return a.nQuality < b.nQuality or (a.nQuality == b.nQuality and aDetail < bDetail)
    end

    local sortByDescend = function(a, b)
        local aDetail = a.nDetail ~= 0 and a.nDetail or 9
        local bDetail = b.nDetail ~= 0 and b.nDetail or 9
        return a.nQuality > b.nQuality or (a.nQuality == b.nQuality and aDetail > bDetail)
    end

    --table.sort(lst, self.bIsAscend and sortByAscend or sortByDescend)
    self.totalScript = {}
    local initFunc = function(tList, tParent, tTitle)
        for _, item in ipairs(tList) do
            bHasEquip = true

            local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetRefineMaterial_80, tParent) ---@type UICharacterRefineMaterialCell
            itemScript:RefreshInfo(EQUIP_REFINE_SLOT_TYPE.MATERIAL_IN_BAG, item.dwIndex, item.nUiId, item.nQuality)
            itemScript:SetToggleSwallowTouches(false)
            itemScript:ShowToggle()

            local nUiId = item.nUiId
            local nIconID = Table_GetItemIconID(item.nUiId, false)
            local nBox, nIndex = ItemData.GetItemPos(item.dwID)

            itemScript:SetItemPos(nBox, nIndex)
            itemScript:UpdateEnchant(item)
            itemScript:UpdatePVPImg(item)
            
            UIHelper.SetButtonClickSound(itemScript.BtnCell, "")
            UIHelper.BindUIEvent(itemScript.ToggleSingle, EventType.OnSelectChanged, function(toggle, bSelected)
                if bSelected then
                    SoundMgr.PlayItemSound(nUiId)
                    self.ShowItemTip(nBox, nIndex)
                end
            end)

            table.insert(self.totalScript, itemScript)
            UIHelper.ToggleGroupAddToggle(self.ToggleGroupLeft, itemScript.ToggleSingle)
        end
        UIHelper.SetVisible(tParent, #tList > 0)
        UIHelper.SetVisible(tTitle, #tList > 0)

        UIHelper.LayoutDoLayout(tParent)
    end

    for i = 1, 4 do
        initFunc(tEquippedList[i], self.backupLayouts[i], self.backupTitles[i])
    end

    initFunc(tUnequippedList, self.LayoutInBagItems, self.WidgetTitleNotEquipped)
    UIHelper.SetVisible(self.LabelEmpty, not bHasEquip)

    Timer.AddFrame(self, 2, function()
        UIHelper.WidgetFoceDoAlign(self)
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewEquipList)
    end)
end

function UIWidgetTotalEquipList:DeselectToggle()
    local nIndex = UIHelper.GetToggleGroupSelectedIndex(self.ToggleGroupLeft)
    local toggle = UIHelper.ToggleGroupGetToggleByIndex(self.ToggleGroupLeft, nIndex)
    UIHelper.SetSelected(toggle, false)
end

function UIWidgetTotalEquipList:SetSelected(nBox, nIndex)
    for _, script in ipairs(self.totalScript) do
        if script.nBox == nBox and script.nIndex == nIndex then
            UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupLeft, script.ToggleSingle)
            return
        end
    end
end

return UIWidgetTotalEquipList