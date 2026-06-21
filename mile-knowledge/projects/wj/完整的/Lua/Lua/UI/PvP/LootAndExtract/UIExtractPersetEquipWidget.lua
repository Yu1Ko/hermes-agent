-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIExtractPersetEquipWidget
-- Date: 2025-03-26 11:45:53
-- Desc: ?
-- ---------------------------------------------------------------------------------
local VIEW_TYPE = {
    PersetAndWareHouse = 1,
    BagAndLoot = 2,
}

local tEquip2Index = {
    [EQUIPMENT_INVENTORY.MELEE_WEAPON]  = 1,
	[EQUIPMENT_INVENTORY.RANGE_WEAPON]  = 2,
	[EQUIPMENT_INVENTORY.CHEST]         = 3,
    [EQUIPMENT_INVENTORY.HELM]          = 4,
	[EQUIPMENT_INVENTORY.AMULET]        = 5,
	[EQUIPMENT_INVENTORY.LEFT_RING]     = 6,
	[EQUIPMENT_INVENTORY.RIGHT_RING]    = 7,
	[EQUIPMENT_INVENTORY.WAIST]         = 8,
	[EQUIPMENT_INVENTORY.PENDANT]       = 9,
	[EQUIPMENT_INVENTORY.PANTS]         = 10,
	[EQUIPMENT_INVENTORY.BOOTS]         = 11,
	[EQUIPMENT_INVENTORY.BANGLE]        = 12,
	[EQUIPMENT_INVENTORY.BIG_SWORD]     = 13,
}

local tIndex2Equip = {}
for nEquip, nIndex in pairs(tEquip2Index) do
    tIndex2Equip[nIndex] = nEquip
end

local UIExtractPersetEquipWidget = class("UIExtractPersetEquipWidget")

function UIExtractPersetEquipWidget:OnEnter(nType)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nType = nType
    self:Init()
    self:UpdateInfo()
end

function UIExtractPersetEquipWidget:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIExtractPersetEquipWidget:BindUIEvent()
    
end

function UIExtractPersetEquipWidget:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function ()
        if self.scriptLastClickItem then
            self.scriptLastClickItem:SetSelected(false)
            self.scriptLastClickItem = nil
        end
    end)

    Event.Reg(self, EventType.UpdateTBFWareHouse, function ()
        self:Init()
        self:UpdateInfo()
    end)

    Event.Reg(self, "BAG_ITEM_UPDATE", function(nBox, nIndex, bNewAdd)
        self:UpdateInfo()
    end)

    Event.Reg(self, "EQUIP_ITEM_UPDATE", function(nInventoryIndex, nEquipmentInventory)
        self:UpdateInfo()
    end)
end

function UIExtractPersetEquipWidget:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIExtractPersetEquipWidget:Init()
    self.tbEquipScrits = {}
    for nEquip, nIndex in pairs(tEquip2Index) do
        local widget = self.tbEquipSetWidget[nIndex]
        if widget then
            UIHelper.RemoveAllChildren(widget)
            local nType = self.nType == VIEW_TYPE.PersetAndWareHouse and ExtractItemType.Equip or INVENTORY_INDEX.EQUIP
            local nSlot = self.nType == VIEW_TYPE.PersetAndWareHouse and nIndex or nEquip

            local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetEquipBarCell, widget)
            local tbPos = {nType = nType, nSlot = nSlot}
            if self.nType == VIEW_TYPE.BagAndLoot then
                tbPos.nBox = INVENTORY_INDEX.EQUIP
                tbPos.nIndex = nEquip
            end
            scriptItem:InitExtractEquip(nEquip, tbPos)
            self.tbEquipScrits[nIndex] = scriptItem

            if nEquip == EQUIPMENT_INVENTORY.BIG_SWORD then
                -- local bCanUseBigSword = false
                -- if self.nType == VIEW_TYPE.BagAndLoot then
                --     local equip = ItemData.GetItemByPos(INVENTORY_INDEX.EQUIP, nEquip)
                --     bCanUseBigSword = g_pClientPlayer and g_pClientPlayer.bCanUseBigSword or false
                --     if equip then
                --         bCanUseBigSword = true
                --     end
                -- end
                UIHelper.SetVisible(widget, false)
            end
        end
    end
end

local _GetEquipList = function (nType)
    local tbList = {}
    local tbEquipList = {}
    if nType == VIEW_TYPE.PersetAndWareHouse then
        tbEquipList = ExtractWareHouseData.GetItemList(ExtractItemType.Equip)
    elseif nType == VIEW_TYPE.BagAndLoot then
        for nEquip, nIndex in pairs(tEquip2Index) do
            local item = ItemData.GetItemByPos(INVENTORY_INDEX.EQUIP, nEquip) or {}
            tbEquipList[nIndex] = item
        end
    end

    tbList = tbEquipList
    return tbList
end

function UIExtractPersetEquipWidget:UpdateInfo()
    local tbEquipList = _GetEquipList(self.nType)

    for nIndex, tbInfo in ipairs(tbEquipList) do
        local scriptParent = self.tbEquipScrits[nIndex]
        local nTabType, dwTabIndex = tbInfo.dwTabType, tbInfo.dwIndex
        if scriptParent then
            if not scriptParent.tbPos or dwTabIndex ~= scriptParent.tbPos.dwItemIndex then
                if self.nType == ExtractViewType.BagAndLoot then
                    scriptParent.nBox = INVENTORY_INDEX.EQUIP
                    scriptParent.nIndex = tIndex2Equip[nIndex]
                end

                scriptParent.OnDragEnd = function (script, scriptTargetItem)
                    if self.nType == ExtractViewType.PersetAndWareHouse then
                        local tbInfo = scriptTargetItem:GetItemInfo()
                        if tbInfo and tbInfo.nSlot and tbInfo.nType and not tbInfo.bLock then
                            local nTargetType, nTargetSlot = tbInfo.nType, tbInfo.nSlot
                            RemoteCallToServer("On_JueJing_MoveItem", ExtractItemType.Equip, nIndex, nTargetType, nTargetSlot)
                        end
                    elseif scriptTargetItem then
                        local tbInfo = scriptTargetItem:GetItemInfo()
                        if tbInfo and tbInfo.nBox and tbInfo.nIndex then
                            ItemData.OnExchangeItem(INVENTORY_INDEX.EQUIP, tIndex2Equip[nIndex], tbInfo.nBox, tbInfo.nIndex)
                        end
                    end
                end

                UIHelper.BindUIEvent(scriptParent.BtnClick, EventType.OnClick, function ()
                    if self.nType == VIEW_TYPE.PersetAndWareHouse then
                        if self.bBatchSell then
                            TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSELL)
                            return
                        end
                        Event.Dispatch(EventType.OnExtractOpenEquipChoosePage, true, nIndex)
                    end
                end)

                scriptParent.tbPos.dwItemType = nil
                scriptParent.tbPos.dwItemIndex = nil
                UIHelper.RemoveAllChildren(scriptParent.WidgetGoods)

                if nTabType and dwTabIndex and nTabType > 0 and dwTabIndex > 0 then
                    scriptParent.tbPos.dwItemType = nTabType
                    scriptParent.tbPos.dwItemIndex = dwTabIndex

                    local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, scriptParent.WidgetGoods)
                    scriptItem:OnInitWithTabID(nTabType, dwTabIndex)
                    scriptItem:SetToggleGroupIndex(ToggleGroupIndex.BagItem)
                    scriptItem:SetSelectChangeCallback(function (_, bSelected)
                        if not bSelected then
                            return
                        end
                        self.scriptLastClickItem = scriptItem
                        local scriptDrag = UIHelper.GetBindScript(self.WidgetDrag)
                        local scriptItemTips = scriptDrag:OpenItemTip(3)
                        if self.nType == ExtractViewType.BagAndLoot then
                            scriptItemTips:OnInit(scriptParent.nBox, scriptParent.nIndex)
                            return
                        end
                        
                        scriptItemTips:OnInitWithTabID(nTabType, dwTabIndex)
                        local tbBtnList = {
                            {
                                szName = "卸下",
                                OnClick = function ()
                                    ExtractWareHouseData.SaveToWareHouse(false, ExtractItemType.Equip, nIndex)
                                    Event.Dispatch(EventType.HideAllHoverTips)
                                end
                            },
                            {
                                szName = "推荐",
                                OnClick = function ()
                                    Event.Dispatch(EventType.OnExtractOpenEquipChoosePage, true, nIndex)
                                    Event.Dispatch(EventType.HideAllHoverTips)
                                end
                            },
                        }

                        if not self.bBatchSell then
                            scriptItemTips:SetBtnState(tbBtnList)
                        end
                    end)
                end
            end
        end
    end
end

function UIExtractPersetEquipWidget:SetSellMode(bSet)
    self.bBatchSell = bSet
end

return UIExtractPersetEquipWidget