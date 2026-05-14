-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UISaddleHorseHarnessBagView
-- Date: 2024-03-11 17:13:57
-- Desc: ?
-- ---------------------------------------------------------------------------------

local tEquipIndex =
{
    [1] = EQUIPMENT_INVENTORY.HEAD_HORSE_EQUIP,
    [2] = EQUIPMENT_INVENTORY.CHEST_HORSE_EQUIP,
    [3] = EQUIPMENT_INVENTORY.FOOT_HORSE_EQUIP,
    [4] = EQUIPMENT_INVENTORY.HANG_ITEM_HORSE_EQUIP,
}

local UISaddleHorseHarnessBagView = class("UISaddleHorseHarnessBagView")

local dwHorseEquipType = ITEM_TABLE_TYPE.CUST_TRINKET
local m_tListMap --玩家已有的马具
local m_tSetList --马具按套装排序，排好了
local nPageHorseEquipSetCount = 5
local nPageHorseEquipCount = 40
local tHorseEquipState = {
    All = 1,
    HAVE = 2,
    NOT_HAVE = 3,
}

local nHorseEquipTogIndex = {
    All = 1,
    Set = 2,
    HEAD = 3,
    CHEST = 4,
    FOOT = 5,
    HANT_ITEM = 6,
}

function UISaddleHorseHarnessBagView:OnEnter(nIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nIndex = nIndex or 0
    self.dwCurEquipBox, self.dwCurEquipX = g_pClientPlayer.GetEquippedHorsePos()
    self.nHorseEquipTogIndex = nHorseEquipTogIndex.All
    UIHelper.SetEditboxTextHorizontalAlign(self.EditPaginate, TextHAlignment.CENTER)

    self:InitHorseEquipBagInfo()
    self:UpdateInfo()
end

function UISaddleHorseHarnessBagView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISaddleHorseHarnessBagView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnScreen, EventType.OnClick, function ()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnScreen, TipsLayoutDir.BOTTOM_RIGHT, FilterDef.HorseEquip)
    end)

    for index,Toggle in ipairs(self.tbTogBackBag) do
        UIHelper.BindUIEvent(Toggle,EventType.OnSelectChanged,function (_,bSelected)
            if bSelected then
                self.nHorseEquipTogIndex = index
                self.nPageIndex = 1
                UIHelper.SetString(self.EditPaginate, self.nPageIndex)
                self:UpdateHorseEquipBag()
            end
        end)
    end

    UIHelper.BindUIEvent(self.BtnLeft,EventType.OnClick,function ()
        if self.nPageIndex > 1 then
            self.nPageIndex = self.nPageIndex - 1
            UIHelper.SetString(self.EditPaginate, self.nPageIndex)
            self:UpdateHorseEquipBag()
        end
    end)

    UIHelper.BindUIEvent(self.BtnRight,EventType.OnClick,function ()
        if self.nPageIndex < self.nPageCount then
            self.nPageIndex = self.nPageIndex + 1
            UIHelper.SetString(self.EditPaginate, self.nPageIndex)
            self:UpdateHorseEquipBag()
        end
    end)

    UIHelper.RegisterEditBoxEnded(self.EditPaginate, function ()
        local nPageIndex = tonumber(UIHelper.GetString(self.EditPaginate))
        if nPageIndex then
            if nPageIndex ~= self.nPageIndex then
                if nPageIndex < 1 then
                    self.nPageIndex = 1
                elseif nPageIndex > self.nPageCount then
                    self.nPageIndex = self.nPageCount
                else
                    self.nPageIndex = nPageIndex
                end
                if self.nPageIndex ~= nPageIndex then
                    UIHelper.SetString(self.EditPaginate, self.nPageIndex)
                end
                self:UpdateHorseEquipBag()
            end
        else
            UIHelper.SetString(self.EditPaginate, self.nPageIndex)
        end
    end)
end

function UISaddleHorseHarnessBagView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)

    Event.Reg(self, EventType.OnFilter, function(szKey, tbSelected)
        if szKey == FilterDef.HorseEquip.Key then
            self.nHorseEquipState = tbSelected[1][1]
            for k, _ in ipairs(self.m_tSelectGainWay) do
                self.m_tSelectGainWay[k] = table.contain_value(tbSelected[2], k)
            end
            self.nPageIndex = 1
            UIHelper.SetString(self.EditPaginate, self.nPageIndex)
            self:UpdateHorseEquipBag()
        end
    end)

    Event.Reg(self, EventType.UpdateHorseEquipBag, function ()
        self:UpdateHorseEquipBag()
    end)
end

function UISaddleHorseHarnessBagView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UISaddleHorseHarnessBagView:UpdateInfo()
    self:UpdateHorseEquipBag()
end

function UISaddleHorseHarnessBagView:InitHorseEquipBagInfo()
    self:InitHorseEquipFilter()
    self:InitHorseEquipSetList()
end

function UISaddleHorseHarnessBagView:InitHorseEquipFilter()
    self.m_tSelectGainWay = {}
    local tGainWayList = Table_GetHorseEquipGainWay()
    for _, tLine in pairs(tGainWayList) do
        self.m_tSelectGainWay[tLine.nIndex] = true
    end
    self.nHorseEquipState = tHorseEquipState.All
end

--按照马具位置排列
local fnSortEquip = function(left, right)
    local nIndex_l = left.nDetail
    if not nIndex_l then
        nIndex_l = -1
    end

    local nIndex_r = right.nDetail
    if not nIndex_r then
        nIndex_r = -1
    end

    return nIndex_l < nIndex_r
end

--套装排序优先级 有无 品质 id
local fnSortSet = function(left, right)
    if left.nCollectNum and not right.nCollectNum then
        return true
    elseif not left.nCollectNum and right.nCollectNum then
        return false
    else
        if left.nQuality == right.nQuality then
            return left.nSetID > right.nSetID
        end
        return left.nQuality > right.nQuality
    end
end

function UISaddleHorseHarnessBagView:InitHorseEquipSetList()
    local tAllSetArray = CoinShop_GetAllAdornmentSet()
    local tAllSetList = {}

    self:UpdateAcquiredEquipList(tAllSetArray)

    for nSetID, tSet in pairs(tAllSetArray) do
        tSet.nSetID = nSetID
        for _, tItem in ipairs(tSet.tList) do
            local dwItemIndex = tItem.dwItemIndex
            tItem.bHave = m_tListMap[dwItemIndex]
            if not tSet.nGainWay then
                tSet.nGainWay = tItem.nGainWay
            end
            if tItem.bOutOfPrint then
                tSet.bOutOfPrint = tItem.bOutOfPrint
            end

            local pItemInfo = ItemData.GetItemInfo(dwHorseEquipType, dwItemIndex)
            tItem.nDetail = pItemInfo.nDetail
            tItem.szName = pItemInfo.szName
            tItem.nQuality = pItemInfo.nQuality
            if not tSet.nQuality then
                tSet.nQuality = pItemInfo.nQuality
            end
        end

        table.sort(tSet.tList, fnSortEquip)
        table.insert(tAllSetList, tSet)
    end

    table.sort(tAllSetList, fnSortSet)
    m_tSetList = tAllSetList
end

function UISaddleHorseHarnessBagView:UpdateAcquiredEquipList(tAllSetArray)
    local tList = g_pClientPlayer.GetAllHorseEquip()
    local tListMap = {}
    for _, tItem in ipairs(tList) do
        local nSetID = CoinShop_GetAdornmentSetID(tItem.dwItemIndex)
        local tSet = tAllSetArray[nSetID]
        if nSetID and tSet then
            tListMap[tItem.dwItemIndex] = true
            tSet.nCollectNum = (tSet.nCollectNum or 0) + 1
        end
    end
    m_tListMap = tListMap
end

--部件排序优先级 有无 品质 id
local fnSortList = function(left, right)
    local dwItemIndex_l = left.dwItemIndex
    local dwItemIndex_r = right.dwItemIndex
    local nHave_l = 0
    local nHave_r = 0
    if m_tListMap[dwItemIndex_l] then
        nHave_l = 1
    end
    if m_tListMap[dwItemIndex_r] then
        nHave_r = 1
    end

    if nHave_l == nHave_r then
        if left.nQuality == right.nQuality then
            return dwItemIndex_l > dwItemIndex_r
        end
        return left.nQuality > right.nQuality
    end
    return nHave_l > nHave_r
end

function UISaddleHorseHarnessBagView:GetHorseEquipList()
    local tAllList = {}
    if self.nHorseEquipTogIndex == nHorseEquipTogIndex.Set then
        for _, tSet in ipairs(m_tSetList) do
            local bCollectFilter = self.nHorseEquipState == tHorseEquipState.All
            if self.nHorseEquipState == tHorseEquipState.HAVE then
                bCollectFilter = tSet.nCollectNum and tSet.nCollectNum > 0
            elseif self.nHorseEquipState == tHorseEquipState.NOT_HAVE then
                bCollectFilter = not tSet.nCollectNum
            end

            local nSetGainWay = tSet.nGainWay
            local bGainWayFilter = self.m_tSelectGainWay[nSetGainWay]

            local bShow = not tSet.bOutOfPrint or (tSet.nCollectNum and tSet.nCollectNum > 0)

            if bCollectFilter and bGainWayFilter and bShow then
                table.insert(tAllList, tSet)
            end
        end
    else
        for _, tSet in ipairs(m_tSetList) do
            for _, tItem in ipairs(tSet.tList) do
                local bTypeFilter = self.nHorseEquipTogIndex == nHorseEquipTogIndex.All or self.nHorseEquipTogIndex == tItem.nDetail + 3

                local bCollectFilter = self.nHorseEquipState == tHorseEquipState.All
                if self.nHorseEquipState == tHorseEquipState.HAVE then
                    bCollectFilter = m_tListMap[tItem.dwItemIndex]
                elseif self.nHorseEquipState == tHorseEquipState.NOT_HAVE then
                    bCollectFilter = not m_tListMap[tItem.dwItemIndex]
                end

                local bGainWayFilter = self.m_tSelectGainWay[tItem.nGainWay]
                local bShow = not tItem.bOutOfPrint or m_tListMap[tItem.dwItemIndex]

                if bTypeFilter and bCollectFilter and bGainWayFilter and bShow then
                    table.insert(tAllList, tItem)
                end
            end
        end
        table.sort(tAllList, fnSortList)
    end
    return tAllList
end

function UISaddleHorseHarnessBagView:UpdateHorseEquipBag()
    UIHelper.SetVisible(self.ScrollViewSuit, self.nHorseEquipTogIndex == nHorseEquipTogIndex.Set)
    UIHelper.SetVisible(self.ScrollViewGridList, self.nHorseEquipTogIndex ~= nHorseEquipTogIndex.Set)

    local tList = self:GetHorseEquipList()

    self.nPageIndex = self.nPageIndex or 1
    self.tbHorseEquipBag = {}

    if self.nHorseEquipTogIndex == nHorseEquipTogIndex.Set then
        self:UpdateHorseEquipSet(tList)
    else
        self:UpdateHorseEquipGrid(tList)
    end

    UIHelper.SetVisible(self.WidgetEmpty, #tList == 0)
    UIHelper.SetString(self.LabelPaginate, "/"..self.nPageCount)

    self:SetHorseEquipBagSelect()
end

function UISaddleHorseHarnessBagView:UpdateHorseEquipSet(tList)
    UIHelper.RemoveAllChildren(self.ScrollViewSuit)

    if tList and not table_is_empty(tList) then
        self.nPageCount = math.ceil(#tList/nPageHorseEquipSetCount) or 0
        local nIndex1 = nPageHorseEquipSetCount * (self.nPageIndex - 1) + 1
        local nIndex2 = nIndex1 + nPageHorseEquipSetCount - 1
        for i = nIndex1, nIndex2 do
            local tSet = tList[i]
            if tList[i] then
                local HarnessBagScript = UIHelper.AddPrefab(PREFAB_ID.WidgetHarnessBagContent, self.ScrollViewSuit, tSet.nSetID, UIHelper.GBKToUTF8(tSet.szName), tSet.tList)
                if HarnessBagScript then
                    local tHave = {}
                    for k,tItem in ipairs(tSet.tList) do
                        tHave[k] = m_tListMap[tItem.dwItemIndex]
                    end
                    HarnessBagScript:SetHarnessBagContent(#tSet.tList, tHave)
                end
            end
        end
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSuit)
    end
end

function UISaddleHorseHarnessBagView:UpdateHorseEquipGrid(tList)
    UIHelper.RemoveAllChildren(self.ScrollViewGridList)

    self.nPageCount = math.ceil(#tList / nPageHorseEquipCount) or 0
    local nIndex1 = nPageHorseEquipCount * (self.nPageIndex - 1) + 1
    local nIndex2 = nIndex1 + nPageHorseEquipCount - 1

    for i = nIndex1, nIndex2 do
        local tItem = tList[i]
        if tItem then
            local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetHorseBagItem, self.ScrollViewGridList, dwHorseEquipType, tItem.dwItemIndex, true)
            if itemScript then
                itemScript:SetClickCallback(function ()
                    Event.Dispatch(EventType.ShowHorseEquipTips, dwHorseEquipType, tItem.dwItemIndex, m_tListMap[tItem.dwItemIndex])
                end)
                UIHelper.SetNodeGray(itemScript.ImgIcon, not m_tListMap[tItem.dwItemIndex], true)
                UIHelper.SetOpacity(itemScript.WidgetItem, m_tListMap[tItem.dwItemIndex] and 255 or 120)
                UIHelper.SetNodeSwallowTouches(itemScript.ToggleSelect, false, true)
                self.tbHorseEquipBag[tItem.dwItemIndex] = itemScript
            end
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewGridList)
end



function UISaddleHorseHarnessBagView:SetHorseEquipBagSelect()
    self.tCurHorseEquip = {}

    for i = 1,HORSE_ADORNMENT_COUNT do
        local dwIndex = self:GetEquipItemIndex(i)
        if dwIndex and dwIndex ~= 0 then
            table.insert(self.tCurHorseEquip,dwIndex)
        end
    end

    if self.nHorseEquipTogIndex == nHorseEquipTogIndex.Set then
        Event.Dispatch(EventType.HorseEquipSelect, self.tCurHorseEquip)
    else
        for dwItemIndex,itemIcon in pairs(self.tbHorseEquipBag) do
            local bCurContain = table.contain_value(self.tCurHorseEquip,dwItemIndex)
            itemIcon:SetCurEquiped(bCurContain)
        end
    end
end

function UISaddleHorseHarnessBagView:GetEquipItemIndex(nIndex)
    local bCurrent = false
    local dwEquipBox, dwEquipX = self.dwCurEquipBox, self.dwCurEquipX
    if INVENTORY_INDEX.HORSE == dwEquipBox and self.nIndex == dwEquipX then
        bCurrent = true
    end

    if bCurrent then
        local nEquipX = tEquipIndex[nIndex]
        local hAdornment = g_pClientPlayer.GetEquippedHorseEquip(nEquipX)
        if hAdornment then
            return hAdornment.dwIndex
        end
    else
        local tHorseEquip = g_pClientPlayer.GetHorseEquipPresetData(self.nIndex)
        local dwIndex = 0
        if tHorseEquip then
            dwIndex = tHorseEquip[nIndex - 1]
        end
        return dwIndex
    end
end



return UISaddleHorseHarnessBagView