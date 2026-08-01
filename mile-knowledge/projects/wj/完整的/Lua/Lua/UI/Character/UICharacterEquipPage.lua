-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICharacterEquipPage
-- Date: 2022-11-22 11:31:42
-- Desc: ?
-- ---------------------------------------------------------------------------------
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

local UICharacterEquipPage = class("UICharacterEquipPage")

function UICharacterEquipPage:OnEnter(nBox, nIndex)
    self.nBox = nBox
    self.nIndex = nIndex

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:InitSort()
    self:UpdateInfo()
end

function UICharacterEquipPage:OnExit()
    self.bInit = false
end


function UICharacterEquipPage:InitSort()
    self:SetSelectQulity(EquipQualityType.All)
    self:SetSelectQulitySort(EquipQualitySortType.DownToUp)
end

function UICharacterEquipPage:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()

        if UIHelper.GetSelected(self.TogQuality) or UIHelper.GetSelected(self.TogQualityUpDown) then
            self:ClearSelectSort()
            return
        end

        UIHelper.SetVisible(self._rootNode, false)
        self:ClearSelectSort()
        self:ClearSelectEquip()
    end)

    UIHelper.BindUIEvent(self.TogQuality, EventType.OnClick, function()
        UIHelper.SetSelected(self.TogQualityUpDown, false)
        self:ClearSelectEquip()
    end)

    UIHelper.BindUIEvent(self.TogQualityUpDown, EventType.OnClick, function()
        UIHelper.SetSelected(self.TogQuality, false)
        self:ClearSelectEquip()
    end)

    for i, tog in ipairs(self.tbTogQuality) do
        UIHelper.BindUIEvent(tog, EventType.OnClick, function()
            self:SetSelectQulity(i, UIHelper.GetSelected(tog))
            self:ClearSelectEquip()
            self:UpdateInfo()
        end)
    end

    for i, tog in ipairs(self.tbTogQualityUpDown) do
        UIHelper.BindUIEvent(tog, EventType.OnClick, function()
            self:SetSelectQulitySort(i)
            self:ClearSelectEquip()
            self:UpdateInfo()
        end)
    end
end

function UICharacterEquipPage:RegEvent()
    Event.Reg(self, "EQUIP_ITEM_UPDATE", function(nInventoryIndex, nEquipmentInventory)
        if nInventoryIndex == INVENTORY_INDEX.EQUIP then
            if self.scriptItemTip1 then
                self.scriptItemTip1:OnInit()
            end

            if self.scriptItemTip2 then
                self.scriptItemTip2:OnInit()
            end
            UIHelper.SetVisible(self._rootNode, false)
            self:ClearSelectSort()
            self:ClearSelectEquip()
        end
    end)

    Event.Reg(self, "EQUIP_CHANGE", function(result)
        if result == ITEM_RESULT_CODE.SPRINT then
            TipsHelper.ShowNormalTip("轻功中无法切换套装", false)
            return
        end

        if result ~= ITEM_RESULT_CODE.SUCCESS then
            return
        end
    end)
end

function UICharacterEquipPage:UpdateInfo()
    local tbEquipInfo = ItemData.GetBagAllEquipWithType(self.nIndex)

    local i = #tbEquipInfo
    while i > 0 do
        local tbInfo = tbEquipInfo[i]
        if not self.tbCurSelectQuality[EquipQualityType.All] and not self.tbCurSelectQuality[tbInfo.item.nQuality + 1] then
            table.remove(tbEquipInfo, i)
        end

        i = i - 1
    end

    table.sort(tbEquipInfo, function (a, b)
        if self.nCurSelectQualitySort == EquipQualitySortType.DownToUp then
            return a.item.nQuality < b.item.nQuality
        else
            return a.item.nQuality > b.item.nQuality
        end
    end)

    UIHelper.SetVisible(self.WidgetEmpty, #tbEquipInfo == 0)

    self.tbScriptItem = self.tbScriptItem or {}
    for _, cell in ipairs(self.tbScriptItem) do
        UIHelper.SetVisible(cell._rootNode, false)
    end

    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupEquip)
    for i, tbInfo in ipairs(tbEquipInfo) do
        local cell = self.tbScriptItem[i]
        if not cell then
            cell = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.ScrollBag)
            table.insert(self.tbScriptItem, cell)
        end

        UIHelper.ToggleGroupAddToggle(self.ToggleGroupEquip, cell.ToggleSelect)
        UIHelper.SetVisible(cell._rootNode, true)
        cell:OnInit(tbInfo.nBox, tbInfo.nIndex)
        cell:SetSelected(false)
        cell:SetClickCallback(function(nBox, nIndex)
            self:ClearSelectSort()
            if nBox and nIndex then
                self.nCurSelectedEquipIndex = i
            end

            if not self.scriptItemTip1 then
                self.scriptItemTip1 = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemCard1)
                self.scriptItemTip1:SetForbidShowEquipCompareBtn(true)
                local w, h = UIHelper.GetContentSize(self.WidgetItemCard1)
                UIHelper.SetPosition(self.scriptItemTip1._rootNode, w / 2, -h / 2)
            end

            if not self.scriptItemTip2 then
                self.scriptItemTip2 = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemCard2)
                self.scriptItemTip2:SetForbidShowEquipCompareBtn(true)
                local w, h = UIHelper.GetContentSize(self.WidgetItemCard2)
                UIHelper.SetPosition(self.scriptItemTip2._rootNode, w / 2, -h / 2)
            end

            if self.nCurSelectedEquipIndex == i then
                if nBox and nIndex then
                    if ItemData.GetItemByPos(self.nBox, self.nIndex) then
                        self.scriptItemTip1:ShowCompareEquipTip(true)
                        self.scriptItemTip1:OnInit(self.nBox, self.nIndex)
                        self.scriptItemTip2:OnInit(nBox, nIndex)
                    else
                        self.scriptItemTip1:ShowCompareEquipTip(false)
                        self.scriptItemTip1:OnInit(nBox, nIndex)
                        self.scriptItemTip2:OnInit()
                    end
                else
                    self.scriptItemTip1:OnInit()
                    self.scriptItemTip2:OnInit()
                end
            end
        end)
    end

    UIHelper.ScrollViewDoLayout(self.ScrollBag)
    UIHelper.ScrollToTop(self.ScrollBag, 0)
end

function UICharacterEquipPage:SetSelectQulity(nIndex, bSelected)
    self.tbCurSelectQuality = self.tbCurSelectQuality or {}

    if nIndex == EquipQualityType.All then
        self.tbCurSelectQuality = {}
        self.tbCurSelectQuality[EquipQualityType.All] = true
    else
        self.tbCurSelectQuality[EquipQualityType.All] = false
        self.tbCurSelectQuality[nIndex] = bSelected
    end

    local bAll = true
    for key, value in pairs(EquipQualityType) do
        if value ~= EquipQualityType.All and not self.tbCurSelectQuality[value] then
            bAll = false
            break
        end
    end

    if bAll then
        self.tbCurSelectQuality = {}
        self.tbCurSelectQuality[EquipQualityType.All] = true
    end

    local bAllNotSelected = true
    for key, value in pairs(EquipQualityType) do
        if self.tbCurSelectQuality[value] then
            bAllNotSelected = false
            break
        end
    end

    if bAllNotSelected then
        self.tbCurSelectQuality = {}
        self.tbCurSelectQuality[EquipQualityType.All] = true
    end

    for i, tog in ipairs(self.tbTogQuality) do
        UIHelper.SetSelected(tog, not not self.tbCurSelectQuality[i])
    end
end

function UICharacterEquipPage:SetSelectQulitySort(nIndex)
    self.nCurSelectQualitySort = nIndex

    for i, tog in ipairs(self.tbTogQualityUpDown) do
        UIHelper.SetSelected(tog, i == self.nCurSelectQualitySort)
    end
end

function UICharacterEquipPage:ClearSelectEquip()
    if self.scriptItemTip1 then
        self.scriptItemTip1:OnInit()
    end

    if self.scriptItemTip2 then
        self.scriptItemTip2:OnInit()
    end
end

function UICharacterEquipPage:ClearSelectSort()
    UIHelper.SetSelected(self.TogQuality, false)
    UIHelper.SetSelected(self.TogQualityUpDown, false)
end

return UICharacterEquipPage