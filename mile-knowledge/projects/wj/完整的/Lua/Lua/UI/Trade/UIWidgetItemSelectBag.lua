-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetItemSelectBag
-- Date: 2023-02-15 19:33:18
-- Desc: ?
-- ---------------------------------------------------------------------------------

--已弃用，改用通用背包

local UIWidgetItemSelectBag = class("UIWidgetSelectBag")

local DEFAULT_BAG_FLITER = {
    {szName = "任务", bSelected = false, filterFunc = function(item) return item.nGenre == ITEM_GENRE.TASK_ITEM end},
    {szName = "药品", bSelected = false, filterFunc = function(item) return item.nGenre == ITEM_GENRE.POTION end},
    {szName = "材料", bSelected = false, filterFunc = function(item) return item.nGenre == ITEM_GENRE.MATERIAL end},
    {szName = "书籍", bSelected = false, filterFunc = function(item) return item.nGenre == ITEM_GENRE.BOOK end},
    {szName = "家具", bSelected = false, filterFunc = function(item) return item.nGenre == ITEM_GENRE.HOMELAND end},
    {szName = "次品", bSelected = false, filterFunc = function(item) return item.nQuality == 0 end}
}    
local DEFAULT_BASE_FLITER = function(item) return true end

function UIWidgetItemSelectBag:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        
        if not self.bInitUI then
            self.tbBagFilter = DEFAULT_BAG_FLITER
            self.fnBaseFliter = DEFAULT_BASE_FLITER

            self:UpdateTempFliter()

            self:InitViewFilter()
            self:UpdateBag()
        end
    end
end

function UIWidgetItemSelectBag:OnExit()
    self.bInit = false
    self:UnRegEvent()

    if self.scriptItemTip then
        self.scriptItemTip:OnInit()
        self.scriptItemTip = nil
    end
end

function UIWidgetItemSelectBag:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        self:CheckClose()
    end)
    UIHelper.BindUIEvent(self.BtnScreen, EventType.OnClick, function() --筛选
        if UIHelper.GetVisible(self.WidgetItemTip) then
            UIHelper.SetVisible(self.WidgetItemTip, false)
        end

        local bCurVisible = UIHelper.GetVisible(self.WidgetAnchorCategoryTips)
        UIHelper.SetVisible(self.WidgetAnchorCategoryTips, not bCurVisible)

        if bCurVisible then
            self:ResetFliterByTemp()
        else
            self:UpdateTempFliter()
        end
    end)
    UIHelper.BindUIEvent(self.BtnSwitch, EventType.OnClick, function() --排序 TODO 暂无需求，未实现

    end)
    UIHelper.BindUIEvent(self.BtnReset, EventType.OnClick, function()
        self:ClearFliter()
    end)
    UIHelper.BindUIEvent(self.BtnAffirm, EventType.OnClick, function()
        self.bBagFilter = false
        UIHelper.SetVisible(self.WidgetAnchorCategoryTips, false)
        for _, tbBagFilterCell in ipairs(self.tbBagFilter) do
            if tbBagFilterCell.bSelected then
                self.bBagFilter = true
                break
            end
        end
        self:UpdateBag()
    end)
    UIHelper.BindUIEvent(self.BtnTipClose, EventType.OnClick, function()
        self:ClearSelect()
    end)
end

function UIWidgetItemSelectBag:RegEvent()
    Event.Reg(self, "BAG_ITEM_UPDATE", function(dwBoxID, dwX)
        self:UpdateBag()
    end)
    Event.Reg(self, EventType.OnShopSelectorSelectChanged, function(szSelectorName, _, bSelected)
        for _, tbBagFilterCell in ipairs(self.tbBagFilter) do
            if tbBagFilterCell.szName == szSelectorName then
                if bSelected then
                    tbBagFilterCell.bSelected = true
                else
                    tbBagFilterCell.bSelected = false
                end
                break
            end
        end
    end)
    Event.Reg(self, EventType.OnTouchViewBackGround, function ()
        self:CheckClose()
    end)

    Event.Reg(self, EventType.BagItemLongPress, function(nBox, nIndex, nCount)
        self:OnConfirmItem(nBox, nIndex, nCount)
    end)
end

function UIWidgetItemSelectBag:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

--请先在外部调Init初始化
function UIWidgetItemSelectBag:OnInit(fnSelectItem, fnClose, fnOnBagUpdated, tbBagFilter, fnBaseFliter)
    self.bInitUI = true

    self.fnSelectItem = fnSelectItem --参数：nBox, nIndex, nCount
    self.fnOnBagUpdated = fnOnBagUpdated
    self.fnClose = fnClose

    self.tbBagFilter = tbBagFilter or DEFAULT_BAG_FLITER
    self.fnBaseFliter = fnBaseFliter or DEFAULT_BASE_FLITER

    self:UpdateTempFliter()

    self:InitViewFilter()
    self:UpdateBag()
end

function UIWidgetItemSelectBag:InitViewFilter()
    UIHelper.RemoveAllChildren(self.LayoutCategory)

    for _, tbBagFilterCell in ipairs(self.tbBagFilter) do
        UIHelper.AddPrefab(PREFAB_ID.WidgetSubToggleSelector, self.LayoutCategory, tbBagFilterCell.szName, tbBagFilterCell.szName, 0)
    end
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutFilter, true, true)
    UIHelper.ScrollViewDoLayout(self.ScrollViewFilter)
    UIHelper.ScrollToTop(self.ScrollViewFilter, 0)
end

function UIWidgetItemSelectBag:UpdateBag()
    self.tbBagItem = {}
    UIHelper.RemoveAllChildren(self.ScrollBag)
    if self.bBagFilter then
        self:UpdateBagByFilter()
        return
    end

    local bEmpty = true
    local tbBag = TravellingBagData.IsInTravelingMap() and ItemData.BoxSet.TravellingBag or ItemData.BoxSet.Bag
    for _, tbItemInfo in ipairs(ItemData.GetItemList(tbBag)) do
        if tbItemInfo.hItem and self.fnBaseFliter(tbItemInfo.hItem) then
            bEmpty = false
            self:AddItemPrefab(tbItemInfo)
        end
    end

    if self.fnOnBagUpdated then
        self.fnOnBagUpdated()
    end

    UIHelper.SetVisible(self.WidgetEmpty, bEmpty)
    UIHelper.ScrollViewDoLayout(self.ScrollBag)
    UIHelper.ScrollToTop(self.ScrollBag, 0)
end

function UIWidgetItemSelectBag:UpdateBagByFilter()
    local tbItemID = {}
    self.tbBagItem = {}
    for _, tbFilter in ipairs(self.tbBagFilter) do
        if tbFilter.bSelected then
            local tbBag = TravellingBagData.IsInTravelingMap() and ItemData.BoxSet.TravellingBag or ItemData.BoxSet.Bag
            for _, tbItemInfo in ipairs(ItemData.GetItemList(tbBag)) do
                if tbItemInfo.hItem and self.fnBaseFliter(tbItemInfo.hItem) and 
                tbFilter.filterFunc(tbItemInfo.hItem) and not table.contain_value(tbItemID, tbItemInfo.hItem.dwID) then

                    self:AddItemPrefab(tbItemInfo)
                    table.insert(tbItemID, tbItemInfo.hItem.dwID)
                end
            end
        end
    end

    if self.fnOnBagUpdated then
        self.fnOnBagUpdated()
    end

    UIHelper.ScrollViewDoLayout(self.ScrollBag)
    UIHelper.ScrollToTop(self.ScrollBag, 0)
end

function UIWidgetItemSelectBag:AddItemPrefab(tbItemInfo)
    local itemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.LayoutCell, tbItemInfo.nBox, tbItemInfo.nIndex)
    itemIcon:OnInit(tbItemInfo.nBox, tbItemInfo.nIndex)
    itemIcon:UpdateInfo(tbItemInfo.hItem)
    itemIcon:SetHandleChooseEvent(true)
    itemIcon:SetSelectChangeCallback(function(dwItemID, bSelected)
        if bSelected then
            self:OnSelectItem(dwItemID)
        else
            UIHelper.SetVisible(self.WidgetItemTip, false)
        end
    end)
    self.tbBagItem[tbItemInfo.hItem.dwID] = itemIcon
end

function UIWidgetItemSelectBag:OnSelectItem(dwItemID)
    self:ClearSelect(dwItemID)

    if not self.scriptItemTip then
        self.scriptItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemTip)
    end

    if UIHelper.GetVisible(self.WidgetAnchorCategoryTips) then
        UIHelper.SetVisible(self.WidgetAnchorCategoryTips, false)
    end

    UIHelper.SetVisible(self.WidgetItemTip, true)
    local dwBox, dwIndex = ItemData.GetItemPos(dwItemID)
    local item = ItemData.GetItem(dwItemID)
    local nStackNum = ItemData.GetItemStackNum(item)

    if ItemData.IsDelayTradeItem(dwItemID) then --这种不能拆分
        nStackNum = 1
    end

    self.scriptItemTip:ShowPlacementBtn(true, nStackNum, nStackNum)
    self.scriptItemTip:OnInit(dwBox, dwIndex)
end

function UIWidgetItemSelectBag:OnConfirmItem(nBox, nIndex, nCount)
    local item = ItemData.GetItemByPos(nBox, nIndex)
    if not item then
        return
    end

    self:ClearSelect()

    if self.fnSelectItem then
        self.fnSelectItem(nBox, nIndex, nCount)
    end
end

function UIWidgetItemSelectBag:ClearSelect(dwNewItemID)
    UIHelper.SetVisible(self.WidgetItemTip, false)

    if not self.tbBagItem then
        return
    end

    for dwID, itemIcon in pairs(self.tbBagItem) do
        if not dwNewItemID or dwID ~= dwNewItemID  then
            itemIcon:RawSetSelected(false)
        end
    end
end

function UIWidgetItemSelectBag:ClearFliter()
    self.bBagFilter = false
    local selectors = UIHelper.GetChildren(self.LayoutCategory)
    for nIndex, selector in ipairs(selectors) do
        local script = UIHelper.GetBindScript(selector) assert(script)
        script:RawSetSelected(false)
        self.tbBagFilter[nIndex].bSelected = false
    end
end

function UIWidgetItemSelectBag:UpdateTempFliter()
    self.tbTempFliterSelect = {}
    for nIndex, tbBagFilterCell in ipairs(self.tbBagFilter) do
        self.tbTempFliterSelect[nIndex] = tbBagFilterCell.bSelected
    end
end

function UIWidgetItemSelectBag:ResetFliterByTemp()
    self.bBagFilter = false

    local selectors = UIHelper.GetChildren(self.LayoutCategory)
    for nIndex, selector in ipairs(selectors) do
        local bSelected = self.tbTempFliterSelect[nIndex]
        local script = UIHelper.GetBindScript(selector) assert(script)
        script:RawSetSelected(bSelected)
        self.tbBagFilter[nIndex].bSelected = bSelected

        if bSelected and not self.bBagFilter then
            self.bBagFilter = true
        end
    end
end

function UIWidgetItemSelectBag:CheckClose()
    self:ResetFliterByTemp()
    if UIHelper.GetVisible(self.WidgetAnchorCategoryTips) then
        UIHelper.SetVisible(self.WidgetAnchorCategoryTips, false)
    elseif UIHelper.GetVisible(self.WidgetItemTip) then
        self:ClearSelect()
    elseif self.fnClose then
        self.fnClose()
    else
        UIHelper.SetVisible(self._rootNode, false)
    end
end

function UIWidgetItemSelectBag:CloseTips()
    UIHelper.SetVisible(self.WidgetAnchorCategoryTips, false)
    self:ClearSelect()
end

return UIWidgetItemSelectBag