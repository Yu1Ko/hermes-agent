-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICharacterEquipCompareView
-- Date: 2023-07-25 10:14:47
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICharacterEquipCompareView = class("UICharacterEquipCompareView")

local EquipQualityType = {
    All = 1,
    White = 2,
    Green = 3,
    Blue = 4,
    Purple = 5,
    Orange = 6,
}

local EquipQualitySortType = {
    DownToUp = 1,
    UpToDown = 2,
}

local tbFilterType = {
    [1] = EQUIPMENT_INVENTORY.MELEE_WEAPON,   -- "近身武器"
    [2] = EQUIPMENT_INVENTORY.RANGE_WEAPON,   -- "远程武器"
    [3] = EQUIPMENT_INVENTORY.HELM,           -- "帽子"
    [4] = EQUIPMENT_INVENTORY.CHEST,          -- "上衣"
    [5] = EQUIPMENT_INVENTORY.WAIST,          -- "腰带"
    [6] = EQUIPMENT_INVENTORY.BANGLE,         -- "护腕"
    [7] = EQUIPMENT_INVENTORY.PANTS,          -- "下装"
    [8] = EQUIPMENT_INVENTORY.BOOTS,          -- "鞋子"
    [9] = EQUIPMENT_INVENTORY.AMULET,         -- "项链"
    [10] = EQUIPMENT_INVENTORY.PENDANT,       -- "腰坠"
    [11] = EQUIPMENT_INVENTORY.LEFT_RING,     -- "戒指"
    [12] = EQUIPMENT_INVENTORY.ARROW,         -- "暗器"
}

local tbCJFilterType = {
    [1] = EQUIPMENT_INVENTORY.MELEE_WEAPON,   -- "近身武器"
    [2] = EQUIPMENT_INVENTORY.BIG_SWORD,      -- "重剑"
    [3] = EQUIPMENT_INVENTORY.RANGE_WEAPON,   -- "远程武器"
    [4] = EQUIPMENT_INVENTORY.HELM,           -- "帽子"
    [5] = EQUIPMENT_INVENTORY.CHEST,          -- "上衣"
    [6] = EQUIPMENT_INVENTORY.WAIST,          -- "腰带"
    [7] = EQUIPMENT_INVENTORY.BANGLE,         -- "护腕"
    [8] = EQUIPMENT_INVENTORY.PANTS,          -- "下装"
    [9] = EQUIPMENT_INVENTORY.BOOTS,          -- "鞋子"
    [10] = EQUIPMENT_INVENTORY.AMULET,        -- "项链"
    [11] = EQUIPMENT_INVENTORY.PENDANT,       -- "腰坠"
    [12] = EQUIPMENT_INVENTORY.LEFT_RING,     -- "戒指"
    [13] = EQUIPMENT_INVENTORY.ARROW,         -- "暗器"
}

local PlayType = {
    PVP = 0,
    PVE = 1,
    PVX = 2,
}

local TogIndex2PlayType = {
    [1] = PlayType.PVE,
    [2] = PlayType.PVP,
    [3] = PlayType.PVX,
}

local TogIndex2Name = {
    [1] = "秘境",
    [2] = "对抗",
    [3] = "休闲",
}

local tbUnSelectFilterType = {
    [EQUIPMENT_INVENTORY.MELEE_WEAPON] = 1,   -- "近身武器"
    [EQUIPMENT_INVENTORY.RANGE_WEAPON] = 2,   -- "远程武器"
    [EQUIPMENT_INVENTORY.HELM] = 3,           -- "帽子"
    [EQUIPMENT_INVENTORY.CHEST] = 4,          -- "上衣"
    [EQUIPMENT_INVENTORY.WAIST] = 5,          -- "腰带"
    [EQUIPMENT_INVENTORY.BANGLE] = 6,         -- "护腕"
    [EQUIPMENT_INVENTORY.PANTS] = 7,          -- "下装"
    [EQUIPMENT_INVENTORY.BOOTS] = 8,          -- "鞋子"
    [EQUIPMENT_INVENTORY.AMULET] = 9,         -- "项链"
    [EQUIPMENT_INVENTORY.PENDANT] = 10,       -- "腰坠"
    [EQUIPMENT_INVENTORY.LEFT_RING] = 11,     -- "戒指"

}

function UICharacterEquipCompareView:OnEnter(nEquipCompareType, bItem, tbInfo, bShowRecommend, nSelectType)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        self.tbCurSelectQuality = {[EquipQualityType.All] = true}
    end
    self.tbInfo = tbInfo
    self.bItem = bItem or false
    self.nEquipCompareType = nEquipCompareType
    self.tbFilterType = tbFilterType
    self.nSelectPlayType = PlayType.PVE
    self.bShowRecommend = false

    local player = PlayerData.GetClientPlayer()
    if player and player.bCanUseBigSword then
        self.tbFilterType = tbCJFilterType
    end

    self.nSelectType = nSelectType or self.tbFilterType[1]
    if bShowRecommend then
        self.bShowRecommend = bShowRecommend
        UIHelper.SetSelected(self.TogRecommend, true)
        local tbEquipInfo = self:GetSortEquipInfo(self.nSelectType)
        self.nEquipIndex = self.nSelectType
        self.tbInfo = tbEquipInfo and tbEquipInfo[1] or {}
    end

    if self.nEquipCompareType == EquipCompareType.Bag then
        local nBox = self.tbInfo.nBox or 0
        local nIndex = self.tbInfo.nIndex
        local item = ItemData.GetItemByPos(nBox, nIndex)
        if item then
            self.nSelectPlayType = item.nEquipUsage
        end
        self:InitEquipTypeList()
    end

    self:InitEquipPageInfo()
    self:UpdateInfo()

    if self.nEquipCompareType == EquipCompareType.Bag then
        Timer.AddFrame(self, 1, function ()
            if not self.bShowRecommend then
                local tbEquipInfo = self:GetSortEquipInfo(self.nEquipIndex)
                self.tbInfo = tbEquipInfo and tbEquipInfo[1] or {}
            end
            Event.Dispatch(EventType.OnSelectedEquipCompareToggle, self.tbInfo)
        end)
    end
    UIHelper.ScrollToTop(self.ScrollViewItemList, 0)
end

function UICharacterEquipCompareView:OnExit()
    self.bInit = false
end

function UICharacterEquipCompareView:BindUIEvent()
    -- UIHelper.SetVisible(self.WidgetAnchorRightTop, false)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.TogFilter, EventType.OnClick, function()
        local tbConfig = FilterDef.EquipType
        tbConfig[1].tbDefault = {tbUnSelectFilterType[self.nEquipIndex]}
        _, self.scriptFilter = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.TogFilter, TipsLayoutDir.TOP_LEFT, tbConfig)
    end)

    UIHelper.BindUIEvent(self.TogAquired, EventType.OnClick, function(btn)
        self.bShowRecommend = false
        self.nSelectPlayType = PlayType.PVE
        local tbEquipInfo = self:GetSortEquipInfo(self.nEquipIndex)
        self.tbInfo = tbEquipInfo and tbEquipInfo[1] or {}
        self:UpdateInfo()
        Event.Dispatch(EventType.OnSelectedEquipCompareToggle, self.tbInfo)
    end)

    UIHelper.BindUIEvent(self.TogRecommend, EventType.OnClick, function(btn)
        self.bShowRecommend = true
        self.nSelectPlayType = PlayType.PVE
        local tbEquipInfo = self:GetSortEquipInfo(self.nEquipIndex)
        self.tbInfo = tbEquipInfo and tbEquipInfo[1] or {}
        self:UpdateInfo()
        Event.Dispatch(EventType.OnSelectedEquipCompareToggle, self.tbInfo)
    end)

    UIHelper.BindUIEvent(self.BtnCustomize, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelCustomizedSetShell)
    end)

    UIHelper.BindUIEvent(self.TogRing1, EventType.OnClick, function()
        self:SetSelectEquipType(EQUIPMENT_INVENTORY.LEFT_RING)
        Event.Dispatch(EventType.OnItemTipSwitchRing, INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.LEFT_RING)
    end)

    UIHelper.BindUIEvent(self.TogRing2, EventType.OnClick, function()
        self:SetSelectEquipType(EQUIPMENT_INVENTORY.RIGHT_RING)
        Event.Dispatch(EventType.OnItemTipSwitchRing, INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.RIGHT_RING)
    end)

    for i, tog in ipairs(self.tbTogType) do
        UIHelper.BindUIEvent(tog, EventType.OnClick, function(btn)
            self.nSelectPlayType = TogIndex2PlayType[i]
            local tbEquipInfo = self:GetSortEquipInfo(self.nEquipIndex)
            self.tbInfo = tbEquipInfo[1] or {}
            self:UpdateInfo()
            Event.Dispatch(EventType.OnSelectedEquipCompareToggle, self.tbInfo)
        end)
    end

    for nIndex, tog in ipairs(self.tbTogPreset) do
        UIHelper.BindUIEvent(tog, EventType.OnClick, function()
            EquipData.SwitchEquip(nIndex)
            self.nCurEquipPageIndex = nIndex
            UIHelper.SetToggleGroupSelected(self.ToggleGroupPreset, self.nCurEquipPageIndex - 1)
        end)
    end
end

function UICharacterEquipCompareView:RegEvent()
    Event.Reg(self, "SYNC_EQUIPID_ARRAY", function()
        self:InitEquipPageInfo()
    end)

    Event.Reg(self, "BAG_ITEM_UPDATE", function(nBox, nIndex, bNewAdd)
        local tbEquipInfo = self:GetSortEquipInfo(self.nEquipIndex)
        self.tbInfo = tbEquipInfo[1] or {}
        Event.Dispatch(EventType.OnSelectedEquipCompareToggle, self.tbInfo)
        UIHelper.ScrollToTop(self.ScrollViewItemList, 0)
    end)

    Event.Reg(self, "EQUIP_ITEM_UPDATE", function(nInventoryIndex, nEquipmentInventory)
        if nInventoryIndex == INVENTORY_INDEX.EQUIP then
            if self.nEquipCompareType == EquipCompareType.Bag then
                local tbEquipInfo = self:GetSortEquipInfo(self.nEquipIndex)
                self.tbInfo = tbEquipInfo[1] or {}
                Event.Dispatch(EventType.OnSelectedEquipCompareToggle, self.tbInfo)
                UIHelper.ScrollToTop(self.ScrollViewItemList, 0)
            end
        end
    end)

    Event.Reg(self, "EQUIP_CHANGE", function(result)
        if result == ITEM_RESULT_CODE.SPRINT then
            TipsHelper.ShowNormalTip("轻功中无法切换套装", false)
            return
        end

        if result == ITEM_RESULT_CODE.SUCCESS then
            self:InitEquipPageInfo()
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, "DESTROY_ITEM", function()
        local tbEquipInfo = self:GetSortEquipInfo(self.nEquipIndex)
        self.tbInfo = tbEquipInfo[#tbEquipInfo] or {}
        Event.Dispatch(EventType.OnSelectedEquipCompareToggle, self.tbInfo)
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewItemList)
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnFilter, function(szKey, tbFilterInfo)
        if szKey ~= FilterDef.EquipType.Key then
            return
        end
        local tbSelectType = tbFilterInfo[1]
        self.nSelectType = self.tbFilterType[tbSelectType[1]]

        local tbEquipInfo = self:GetSortEquipInfo(self.nSelectType)
        self.nEquipIndex = self.nSelectType
        self.tbInfo = tbEquipInfo and tbEquipInfo[1] or {}
        Event.Dispatch(EventType.OnSelectedEquipCompareToggle, self.tbInfo)
        self:UpdateInfo()

        UIHelper.ScrollToTop(self.ScrollViewItemList, 0)
        Event.Dispatch(EventType.HideAllHoverTips)
    end)

    Event.Reg(self, EventType.OnSelectedEquipCompareToggle, function(tbInfo)
        self.tbInfo = tbInfo or {}
        self:UpdateInfo(true)
    end)

    Event.Reg(self, EventType.OnItemTipSelectRing, function(nBox, nIndex)
        self:SetSelectEquipType(nIndex)
    end)
end

function UICharacterEquipCompareView:InitEquipTypeList()
    self.tbEquipTypeCells = self.tbEquipTypeCells or {}
    for nIndex, nType in ipairs(self.tbFilterType) do
        if not self.tbEquipTypeCells[nIndex] then
            self.tbEquipTypeCells[nIndex] = UIHelper.AddPrefab(PREFAB_ID.WidgetEquipCompareTogItem, self.ScrollViewTogList)
            UIHelper.ToggleGroupAddToggle(self.TogGroupTogList, self.tbEquipTypeCells[nIndex].TogItem)
        end

        self.tbEquipTypeCells[nIndex]:OnEnter(nType, function()
            self.nSelectType = nType
            local tbEquipInfo = self:GetSortEquipInfo(self.nSelectType)
            self.nEquipIndex = self.nSelectType
            self.tbInfo = tbEquipInfo and tbEquipInfo[1] or {}
            Event.Dispatch(EventType.OnSelectedEquipCompareToggle, self.tbInfo)
            self:UpdateInfo()
        end)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTogList)
end

function UICharacterEquipCompareView:InitEquipPageInfo()
    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

    self.nCurEquipPageIndex = player.GetEquipIDArray(INVENTORY_INDEX.EQUIP) + 1
    UIHelper.SetToggleGroupSelected(self.ToggleGroupPreset, self.nCurEquipPageIndex - 1)
end

function UICharacterEquipCompareView:UpdateInfo(bJustUpdateData)
    -- UIHelper.SetVisible(self.WidgetItemTipsLeftEmpty, true)
    -- UIHelper.SetVisible(self.WidgetItemTipsRightEmpty, true)

    if self.nEquipCompareType == EquipCompareType.Bag then
        if self.bShowRecommend then
            self:UpdateRecommendEquipInfo(bJustUpdateData)
        else
            self:UpdateBagInfo(bJustUpdateData)
        end
        UIHelper.SetSelected(self.TogAquired, not self.bShowRecommend)
        UIHelper.SetSelected(self.TogRecommend, self.bShowRecommend)
        for i, tog in ipairs(self.tbTogType) do
            UIHelper.SetSelected(tog, self.nSelectPlayType == TogIndex2PlayType[i])
        end
    elseif self.nEquipCompareType == EquipCompareType.NormalByItemID then
        self:UpdateNormalInfoByItemID()
    elseif self.nEquipCompareType == EquipCompareType.NormalByBoxIndex then
        self:UpdateNormalInfoByBoxIndex()
    elseif self.nEquipCompareType == EquipCompareType.NormalByTabID then
        self:UpdateNormalInfoByTabID()
    end
    -- self:ItemTipsDoAlign()
    UIHelper.LayoutDoLayout(self.WidgetAnchorMiddle)
    UIHelper.LayoutDoLayout(self.LayoutItemTIps)
    UIHelper.SetVisible(self.BtnCustomize, self.nEquipCompareType == EquipCompareType.Bag)
end

local function SortBagEquipFunc(a, b)
    local nSelfKungfuID = PlayerData.GetPlayerMountKungfuID()
    local itemInfoA = ItemData.GetItemInfo(a.item.dwTabType, a.item.dwIndex)
    local itemInfoB = ItemData.GetItemInfo(b.item.dwTabType, b.item.dwIndex)
    local bRecommendA = false
    local bRecommendB = false
    if itemInfoA and itemInfoA.nRecommendID and g_tTable.EquipRecommend then
        local tbIDs = Table_GetEquipRecommendKungfus(itemInfoA.nRecommendID, true)
        for nID, _ in pairs(tbIDs) do
            if nID == 0 or nID == nSelfKungfuID then
                bRecommendA = true
                break
            end
        end
    end
    if itemInfoB and itemInfoB.nRecommendID and g_tTable.EquipRecommend then
        local tbIDs = Table_GetEquipRecommendKungfus(itemInfoB.nRecommendID, true)
        for nID, _ in pairs(tbIDs) do
            if nID == 0 or nID == nSelfKungfuID then
                bRecommendB = true
                break
            end
        end
    end
    if bRecommendA ~= bRecommendB then
        return bRecommendA
    elseif a.item.nBaseScore ~= b.item.nBaseScore then
        return a.item.nBaseScore > b.item.nBaseScore
    elseif a.dwIndex ~= b.dwIndex then
        return a.dwIndex > b.dwIndex
    else
        return false
    end
end

local function SortRecommendEquipFunc(a, b)
   if a.item.nBaseScore ~= b.item.nBaseScore then
        return a.item.nBaseScore < b.item.nBaseScore
    elseif a.dwIndex ~= b.dwIndex then
        return a.dwIndex < b.dwIndex
    else
        return false
    end
end

function UICharacterEquipCompareView:GetSortEquipInfo(nType)
    local tbEquipInfo = {}
    local player = PlayerData.GetClientPlayer()
    if not player then
        UIMgr.Close(self)
        return
    end

    if self.bShowRecommend then
        if not self.tbRecommendEquips then
            local dwKungfuID = player.GetKungfuMountID()
            self.tbRecommendEquips = Table_GetAllRecommendEquipInfo(dwKungfuID)
        end

        local tbEquipInfoTop = {}
        local tbEquipInfo2 = {}
        local nSelfCamp = PlayerData.GetPlayerCamp()
        local nSelfKungfuID = PlayerData.GetPlayerMountKungfuID()
        for index, tbInfo in ipairs(self.tbRecommendEquips) do
            local nBox, nPos = ItemData.GetEquipItemEquiped(player, tbInfo.itemInfo.nSub, tbInfo.itemInfo.nDetail)
            local item = ItemData.GetItemByPos(nBox, nPos)
            if (tbInfo.tbConfig.nCamp == CAMP.NEUTRAL or nSelfCamp == tbInfo.tbConfig.nCamp) then
                local tb = tbEquipInfo
                if item and item.nBaseScore > tbInfo.itemInfo.nBaseScore then
                    tb = tbEquipInfo2
                end

                if tbInfo.tbConfig and not string.is_nil(tbInfo.tbConfig.szRecommendKungfuID) then
                    local tbKungfuID = string.split(tbInfo.tbConfig.szRecommendKungfuID, ";")
                    for _, szKungfuID in ipairs(tbKungfuID) do
                        if szKungfuID == "1" or tostring(nSelfKungfuID) == szKungfuID then
                            tb = tbEquipInfoTop
                            break
                        end
                    end
                end

                if nPos == nType then
                    table.insert(tb, {
                        item = tbInfo.itemInfo,
                        tbConfig = tbInfo.tbConfig,
                        dwTabType = tbInfo.tbConfig.dwTabType,
                        dwIndex = tbInfo.tbConfig.dwIndex,
                    })
                elseif nPos == EQUIPMENT_INVENTORY.LEFT_RING or nPos == EQUIPMENT_INVENTORY.RIGHT_RING then
                    if EQUIPMENT_INVENTORY.RIGHT_RING == nType or EQUIPMENT_INVENTORY.LEFT_RING == nType then
                        table.insert(tb, {
                            item = tbInfo.itemInfo,
                            tbConfig = tbInfo.tbConfig,
                            dwTabType = tbInfo.tbConfig.dwTabType,
                            dwIndex = tbInfo.tbConfig.dwIndex,
                        })
                    end
                end
            end
        end

        table.sort(tbEquipInfoTop, SortRecommendEquipFunc)
        table.sort(tbEquipInfo, SortRecommendEquipFunc)
        table.sort(tbEquipInfo2, SortRecommendEquipFunc)

        for _, v in ipairs(tbEquipInfo) do
            table.insert(tbEquipInfoTop, v)
        end

        for _, v in ipairs(tbEquipInfo2) do
            table.insert(tbEquipInfoTop, v)
        end

        tbEquipInfo = tbEquipInfoTop
    else
        tbEquipInfo = ItemData.GetBagAllEquipWithType(nType)
        table.sort(tbEquipInfo, SortBagEquipFunc)
    end

    local tbPlayTypeCount = {0, 0, 0}
    local i = #tbEquipInfo
    while i > 0 do
        local tbInfo = tbEquipInfo[i]
        if self.bShowRecommend then
            local nTogIndex = table.get_key(TogIndex2PlayType, tbInfo.tbConfig.nEquipUsage)
            if nTogIndex then
                if not tbInfo.item or tbInfo.item.nSub ~= EQUIPMENT_SUB.HORSE then
                    tbPlayTypeCount[nTogIndex] = tbPlayTypeCount[nTogIndex] + 1
                end
            elseif tbInfo.tbConfig.nEquipUsage == EQUIPMENT_USAGE_TYPE.IS_GENERAL_EQUIP then
                for key, _ in pairs(TogIndex2PlayType) do
                    tbPlayTypeCount[key] = tbPlayTypeCount[key] + 1
                end
            end

            if not self.tbCurSelectQuality[EquipQualityType.All] and not self.tbCurSelectQuality[tbInfo.item.nQuality + 1] then
                table.remove(tbEquipInfo, i)
            elseif tbInfo.item and tbInfo.item.nSub == EQUIPMENT_SUB.HORSE then
                table.remove(tbEquipInfo, i)    --坐骑不在此显示
            elseif tbInfo.tbConfig and tbInfo.tbConfig.nEquipUsage and tbInfo.tbConfig.nEquipUsage ~= self.nSelectPlayType and tbInfo.tbConfig.nEquipUsage ~= EQUIPMENT_USAGE_TYPE.IS_GENERAL_EQUIP then
                table.remove(tbEquipInfo, i)
            end
        else
            local nTogIndex = table.get_key(TogIndex2PlayType, tbInfo.item.nEquipUsage)
            if nTogIndex then
                if not tbInfo.item or tbInfo.item.nSub ~= EQUIPMENT_SUB.HORSE then
                    tbPlayTypeCount[nTogIndex] = tbPlayTypeCount[nTogIndex] + 1
                end
            elseif tbInfo.item.nEquipUsage == EQUIPMENT_USAGE_TYPE.IS_GENERAL_EQUIP then
                for key, _ in pairs(TogIndex2PlayType) do
                    tbPlayTypeCount[key] = tbPlayTypeCount[key] + 1
                end
            end

            if not self.tbCurSelectQuality[EquipQualityType.All] and not self.tbCurSelectQuality[tbInfo.item.nQuality + 1] then
                table.remove(tbEquipInfo, i)
            elseif tbInfo.item and tbInfo.item.nSub == EQUIPMENT_SUB.HORSE then
                table.remove(tbEquipInfo, i)    --坐骑不在此显示
            elseif tbInfo.item and tbInfo.item.nEquipUsage and tbInfo.item.nEquipUsage ~= self.nSelectPlayType and tbInfo.item.nEquipUsage ~= EQUIPMENT_USAGE_TYPE.IS_GENERAL_EQUIP then
                table.remove(tbEquipInfo, i)
            end
        end
        i = i - 1
    end

    return tbEquipInfo, tbPlayTypeCount
end

function UICharacterEquipCompareView:UpdateBagInfo(bJustUpdateData)
    self.nBox = self.tbInfo.nBox or 0
    self.nIndex = self.tbInfo.nIndex
    local item = ItemData.GetItemByPos(self.nBox, self.nIndex)
    if self.nBox == 0 then
        self.nEquipIndex = self.nIndex or self.nEquipIndex
    else
        self.nEquipIndex = self.nEquipIndex or EquipData.GetEquipInventory(item.nSub, item.nDetail)
    end

    local tbEquipInfo, tbPlayTypeCount = self:GetSortEquipInfo(self.nEquipIndex)
    self.tbScriptItem = self.tbScriptItem or {}

    for i, cell in ipairs(self.tbScriptItem) do
        UIHelper.SetVisible(cell._rootNode, false)
    end

    for i, tbInfo in ipairs(tbEquipInfo) do
        local cell = self.tbScriptItem[i]
        if not cell then
            cell = UIHelper.AddPrefab(PREFAB_ID.WidgetEquipCompareItemCell, self.ScrollViewItemList)
            table.insert(self.tbScriptItem, cell)
        end
        cell:OnInit(tbInfo, true)
        UIHelper.SetVisible(cell._rootNode, true)
    end

    for nTogIndex, nCount in ipairs(tbPlayTypeCount) do
        UIHelper.SetString(self.tbLabelType[nTogIndex], string.format("%s(%d)", TogIndex2Name[nTogIndex], nCount))
        UIHelper.SetString(self.tbLabelTypeSelected[nTogIndex], string.format("%s(%d)", TogIndex2Name[nTogIndex], nCount))
    end

    if not self.scriptItemTip2 then
        self.scriptItemTip2 = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemTipsNormalRight)
        self.scriptItemTip2:SetPlayerID(PlayerData.GetPlayerID())
        self.scriptItemTip2:SetForbidShowEquipCompareBtn(true)
        self.scriptItemTip2:SetForbidAutoShortTip(true)
        UIHelper.SetAnchorPoint(self.scriptItemTip2._rootNode, 0.5, 1)
        UIHelper.SetPositionY(self.scriptItemTip2._rootNode, 0)
    end
    if self.nBox == 0 then
        UIHelper.SetVisible(self.WidgetItemTipsRight, false)
        UIHelper.SetVisible(self.WidgetItemTipsNormalRight, false)
        UIHelper.SetVisible(self.WidgetItemTipsRightEmpty, true)
    else
        UIHelper.SetVisible(self.WidgetItemTipsRight, true)
        UIHelper.SetVisible(self.WidgetItemTipsNormalRight, true)
        UIHelper.SetVisible(self.WidgetItemTipsRightEmpty, false)
        self.scriptItemTip2:UpdateScrollViewHeight(480)
        self.scriptItemTip2:SetScrollGuildArrowType(1)
        self.scriptItemTip2:SetFunctionButtons()
        self.scriptItemTip2:OnInit(self.nBox, self.nIndex)

        if self.scriptItemTip2.scriptBtnList then
            UIHelper.SetVisible(self.scriptItemTip2.scriptBtnList.ScrollViewNegativeOp, false)
        end
    end
    self:InitEquipedPage(self.nEquipIndex, true)
    -- UIHelper.ScrollViewDoLayout(self.ScrollViewItemList)
    UIHelper.SetVisible(self.WidgetItemListEmpty, table.is_empty(tbEquipInfo))

    if self.nEquipIndex ~= EQUIPMENT_INVENTORY.RIGHT_RING then
        UIHelper.SetToggleGroupSelected(self.TogGroupTogList, table.get_key(self.tbFilterType, self.nEquipIndex) - 1)
    else
        UIHelper.SetToggleGroupSelected(self.TogGroupTogList, table.get_key(self.tbFilterType, EQUIPMENT_INVENTORY.LEFT_RING) - 1)
    end

    if not bJustUpdateData then
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewItemList)
    end
end

function UICharacterEquipCompareView:UpdateRecommendEquipInfo(bJustUpdateData)
    self.dwTabType = self.tbInfo.dwTabType or 0
    self.dwIndex = self.tbInfo.dwIndex

    local tbEquipInfo, tbPlayTypeCount = self:GetSortEquipInfo(self.nEquipIndex)
    self.tbScriptItem = self.tbScriptItem or {}

    for i, cell in ipairs(self.tbScriptItem) do
        UIHelper.SetVisible(cell._rootNode, false)
    end

    for i, tbInfo in ipairs(tbEquipInfo) do
        local cell = self.tbScriptItem[i]
        if not cell then
            cell = UIHelper.AddPrefab(PREFAB_ID.WidgetEquipCompareItemCell, self.ScrollViewItemList)
            table.insert(self.tbScriptItem, cell)
        end
        cell:OnInit(tbInfo, false)
        UIHelper.SetVisible(cell._rootNode, true)
    end

    for nTogIndex, nCount in ipairs(tbPlayTypeCount) do
        UIHelper.SetString(self.tbLabelType[nTogIndex], string.format("%s(%d)", TogIndex2Name[nTogIndex], nCount))
        UIHelper.SetString(self.tbLabelTypeSelected[nTogIndex], string.format("%s(%d)", TogIndex2Name[nTogIndex], nCount))
    end

    if not self.scriptItemTip2 then
        self.scriptItemTip2 = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemTipsNormalRight)
        self.scriptItemTip2:SetPlayerID(PlayerData.GetPlayerID())
        self.scriptItemTip2:SetForbidShowEquipCompareBtn(true)
        self.scriptItemTip2:SetForbidAutoShortTip(true)
        UIHelper.SetAnchorPoint(self.scriptItemTip2._rootNode, 0.5, 1)
        UIHelper.SetPositionY(self.scriptItemTip2._rootNode, 0)
    end
    if self.dwTabType == 0 then
        UIHelper.SetVisible(self.WidgetItemTipsRight, false)
        UIHelper.SetVisible(self.WidgetItemTipsNormalRight, false)
        UIHelper.SetVisible(self.WidgetItemTipsRightEmpty, true)
    else
        UIHelper.SetVisible(self.WidgetItemTipsRight, true)
        UIHelper.SetVisible(self.WidgetItemTipsNormalRight, true)
        UIHelper.SetVisible(self.WidgetItemTipsRightEmpty, false)
        self.scriptItemTip2:UpdateScrollViewHeight(480)
        self.scriptItemTip2:SetScrollGuildArrowType(2)

        local tbButton = {}
        if OutFitPreviewData.CanPreview(self.dwTabType, self.dwIndex) then
            local tbPreviewBtn = OutFitPreviewData.SetPreviewBtn(self.dwTabType, self.dwIndex)
            if not table.is_empty(tbPreviewBtn) then
                table.insert(tbButton, tbPreviewBtn[1])
            end
        end
        self.scriptItemTip2:SetFunctionButtons(tbButton)
        self.scriptItemTip2:OnInitWithTabID(self.dwTabType, self.dwIndex)
    end
    self:InitEquipedPage(self.nEquipIndex, true)
    -- UIHelper.ScrollViewDoLayout(self.ScrollViewItemList)
    UIHelper.SetVisible(self.WidgetItemListEmpty, table.is_empty(tbEquipInfo))
    if self.nEquipIndex ~= EQUIPMENT_INVENTORY.RIGHT_RING then
        UIHelper.SetToggleGroupSelected(self.TogGroupTogList, table.get_key(self.tbFilterType, self.nEquipIndex) - 1)
    else
        UIHelper.SetToggleGroupSelected(self.TogGroupTogList, table.get_key(self.tbFilterType, EQUIPMENT_INVENTORY.LEFT_RING) - 1)
    end

    if not bJustUpdateData then
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewItemList)
    end
end

function UICharacterEquipCompareView:UpdateNormalInfoByItemID()
    self.dwItemID = self.tbInfo.dwItemID
    local item = GetItem(self.dwItemID)
    local nEquipIndex = EquipData.GetEquipInventory(item.nSub, item.nDetail)

    if not self.scriptItemTip2 then
        self.scriptItemTip2 = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemTipsNarrow)
        self.scriptItemTip2:SetPlayerID(PlayerData.GetPlayerID())
        self.scriptItemTip2:SetForbidShowEquipCompareBtn(true)
        self.scriptItemTip2:SetForbidAutoShortTip(true)
        self.scriptItemTip2:ShowCompareEquipTip(true)
        UIHelper.SetAnchorPoint(self.scriptItemTip2._rootNode, 0.5, 1)
        UIHelper.SetPositionY(self.scriptItemTip2._rootNode, 0)
    end
    self:InitEquipedPage(nEquipIndex, true)
    UIHelper.SetVisible(self.WidgetRight, false)
    self.scriptItemTip2:UpdateScrollViewHeight(480)
    self.scriptItemTip2:SetScrollGuildArrowType(1)
    self.scriptItemTip2:OnInitWithItemID(self.dwItemID)

    UIHelper.SetVisible(self.TogFilter, false)
    UIHelper.SetVisible(self.WidgetItemTipsNarrow, true)
    UIHelper.SetVisible(self.WidgetItemTipsRightEmpty, false)
    self.scriptItemTip2:SetComparePreviewLabel()
end

function UICharacterEquipCompareView:UpdateNormalInfoByTabID()
    if not self.scriptItemTip2 then
        self.scriptItemTip2 = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemTipsNarrow)
        self.scriptItemTip2:SetPlayerID(PlayerData.GetPlayerID())
        self.scriptItemTip2:SetForbidAutoShortTip(true)
        self.scriptItemTip2:SetForbidShowEquipCompareBtn(true)
        self.scriptItemTip2:ShowCompareEquipTip(true)
        UIHelper.SetAnchorPoint(self.scriptItemTip2._rootNode, 0.5, 1)
        UIHelper.SetPositionY(self.scriptItemTip2._rootNode, 0)
    end

    self.nTabID = self.tbInfo.nTabID
    self.nTabType = self.tbInfo.nTabType
    local item = GetItemInfo(self.nTabType, self.nTabID)
    if not item then
        return
    end
    local nEquipIndex = EquipData.GetEquipInventory(item.nSub, item.nDetail)

    self:InitEquipedPage(nEquipIndex, true)
    UIHelper.SetVisible(self.WidgetRight, false)
    self.scriptItemTip2:UpdateScrollViewHeight(480)
    self.scriptItemTip2:SetScrollGuildArrowType(1)

    UIHelper.SetVisible(self.TogFilter, false)
    UIHelper.SetVisible(self.WidgetItemTipsNarrow, true)
    UIHelper.SetVisible(self.WidgetItemTipsRightEmpty, false)
    self.scriptItemTip2:SetComparePreviewLabel()
    self.scriptItemTip2:OnInitWithTabID(self.nTabType, self.nTabID)
end

function UICharacterEquipCompareView:UpdateNormalInfoByBoxIndex()
    if not self.scriptItemTip2 then
        self.scriptItemTip2 = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemTipsNarrow)
        self.scriptItemTip2:SetPlayerID(PlayerData.GetPlayerID())
        self.scriptItemTip2:SetForbidAutoShortTip(true)
        self.scriptItemTip2:SetForbidShowEquipCompareBtn(true)
        self.scriptItemTip2:ShowCompareEquipTip(true)
        UIHelper.SetAnchorPoint(self.scriptItemTip2._rootNode, 0.5, 1)
        UIHelper.SetPositionY(self.scriptItemTip2._rootNode, 0)
    end

    self.nBox = self.tbInfo.nBox
    self.nIndex = self.tbInfo.nIndex
    local item = ItemData.GetItemByPos(self.nBox, self.nIndex)
    if not item then
        return
    end
    local nEquipIndex = EquipData.GetEquipInventory(item.nSub, item.nDetail)

    self:InitEquipedPage(nEquipIndex, true)
    UIHelper.SetVisible(self.WidgetRight, false)
    self.scriptItemTip2:UpdateScrollViewHeight(480)
    self.scriptItemTip2:SetScrollGuildArrowType(1)

    UIHelper.SetVisible(self.TogFilter, false)
    UIHelper.SetVisible(self.WidgetItemTipsNarrow, true)
    UIHelper.SetVisible(self.WidgetItemTipsRightEmpty, false)
    self.scriptItemTip2:SetComparePreviewLabel()
    self.scriptItemTip2:OnInit(self.nBox, self.nIndex)
end

function UICharacterEquipCompareView:InitEquipedPage(nEquipIndex, bForbiBtn)
    local player = GetClientPlayer()
    local item = PlayerData.GetPlayerItem(player, INVENTORY_INDEX.EQUIP, nEquipIndex)
    UIHelper.SetVisible(self.WidgetItemTipsLeft, false)
    UIHelper.SetVisible(self.WidgetItemTipsLeftEmpty, false)
    UIHelper.SetVisible(self.WidgetRingSwitch, nEquipIndex == EQUIPMENT_INVENTORY.RIGHT_RING or nEquipIndex == EQUIPMENT_INVENTORY.LEFT_RING)

    if not self.scriptItemTip1 then
        self.scriptItemTip1 = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemTipsLeft)
        self.scriptItemTip1:SetPlayerID(PlayerData.GetPlayerID())
        self.scriptItemTip1:SetForbidAutoShortTip(true)
        self.scriptItemTip1:SetForbidShowEquipCompareBtn(true)
        self.scriptItemTip1:ShowRingSwitch(true, false)
        self.scriptItemTip1:ShowCompareEquipTip(true)
        UIHelper.SetAnchorPoint(self.scriptItemTip1._rootNode, 0.5, 1)
        UIHelper.SetPositionY(self.scriptItemTip1._rootNode, 0)
    end

    if item then
        self.scriptItemTip1:UpdateScrollViewHeight(480)
        UIHelper.SetVisible(self.WidgetItemTipsLeft, true)
        self.scriptItemTip1:OnInit(INVENTORY_INDEX.EQUIP, nEquipIndex)
        self.scriptItemTip1:ShowCurEquipImg(true)
    else
        UIHelper.SetAnchorPoint(self.WidgetItemTipsLeftEmpty._rootNode, 0.5, 1)
        UIHelper.SetPositionY(self.WidgetItemTipsLeftEmpty._rootNode, 0)
        UIHelper.SetVisible(self.WidgetItemTipsLeftEmpty, true)
    end

    if nEquipIndex == EQUIPMENT_INVENTORY.LEFT_RING then
        UIHelper.SetSelected(self.TogRing1, true)
        UIHelper.SetSelected(self.TogRing2, false)
        Event.Dispatch(EventType.OnItemTipSwitchRing, INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.LEFT_RING)
    elseif nEquipIndex == EQUIPMENT_INVENTORY.RIGHT_RING then
        UIHelper.SetSelected(self.TogRing2, true)
        UIHelper.SetSelected(self.TogRing1, false)
        Event.Dispatch(EventType.OnItemTipSwitchRing, INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.RIGHT_RING)
    end
end

function UICharacterEquipCompareView:SetSelectEquipType(nSelectType)
    self.nSelectType = nSelectType
    local tbEquipInfo = self:GetSortEquipInfo(self.nSelectType)
    self.nEquipIndex = self.nSelectType
    self.tbInfo = tbEquipInfo and tbEquipInfo[1] or {}
    Event.Dispatch(EventType.OnSelectedEquipCompareToggle, self.tbInfo)
    self:UpdateInfo()
end

function UICharacterEquipCompareView:ItemTipsDoAlign()
    if self.nEquipCompareType == EquipCompareType.Bag then
        return
    end
    local nWidthTip, nHeightTip = UIHelper.GetContentSize(self.scriptItemTip2._rootNode)
    UIHelper.SetContentSize(self.WidgetItemTipsRight, nWidthTip, nHeightTip)
    UIHelper.SetPosition(self.scriptItemTip2._rootNode, 0, 0, self.WidgetItemTipsRight)
    UIHelper.WidgetFoceDoAlign(self.scriptItemTip1)
    UIHelper.WidgetFoceDoAlign(self.scriptItemTip2)
end

return UICharacterEquipCompareView