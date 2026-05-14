-- ---------------------------------------------------------------------------------
-- Author: Jiayuran
-- Name: UICharacterWidgetEquipRefine
-- Date: 2022-12-06 14:39
-- Desc: UICharacterWidgetEquipRefine
-- ---------------------------------------------------------------------------------

---@class UIWidgetEquipBarList
local UIWidgetEquipBarList = class("UIWidgetEquipBarList")

function UIWidgetEquipBarList:OnEnter(bIsFusion)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetEquipBarList:OnExit()
    self.bInit = false
end

function UIWidgetEquipBarList:BindUIEvent()
end

function UIWidgetEquipBarList:RegEvent()
    Event.Reg(self, "EQUIP_CHANGE", function(result)
        if result == ITEM_RESULT_CODE.SUCCESS then
            self:UpdateInfo()
            if self.nLastSelected then
                self:SetSelected(self.nLastSelected)
            end
        end
    end)
end

function UIWidgetEquipBarList:Init(bIsFusion, fnAction)
    self.bIsFusion = bIsFusion
    self.fnAction = fnAction
    self:UpdateInfo()
end

function UIWidgetEquipBarList:UpdateInfo()
    self.scripts = {}
    DataModel.UpdateEquipList(self.bIsFusion)

    UIHelper.RemoveAllChildren(self.LayoutEquip1)
    UIHelper.RemoveAllChildren(self.LayoutEquip2)
    UIHelper.RemoveAllChildren(self.LayoutWeapon)

    local tEquipEnumToParent = {
        [EQUIPMENT_INVENTORY.HELM] = self.LayoutEquip1,
        [EQUIPMENT_INVENTORY.CHEST] = self.LayoutEquip1,
        [EQUIPMENT_INVENTORY.WAIST] = self.LayoutEquip1,
        [EQUIPMENT_INVENTORY.PANTS] = self.LayoutEquip1,
        [EQUIPMENT_INVENTORY.BOOTS] = self.LayoutEquip1,
        [EQUIPMENT_INVENTORY.BANGLE] = self.LayoutEquip1,


        [EQUIPMENT_INVENTORY.AMULET] = self.LayoutEquip2,
        [EQUIPMENT_INVENTORY.PENDANT] = self.LayoutEquip2,
        [EQUIPMENT_INVENTORY.LEFT_RING] = self.LayoutEquip2,
        [EQUIPMENT_INVENTORY.RIGHT_RING] = self.LayoutEquip2,

        [EQUIPMENT_INVENTORY.MELEE_WEAPON] = self.LayoutWeapon,
        [EQUIPMENT_INVENTORY.RANGE_WEAPON] = self.LayoutWeapon,
        [EQUIPMENT_INVENTORY.BIG_SWORD] = self.LayoutWeapon,
    }

    for _, equipSlotInfo in pairs(DataModel.tEquipBoxList) do
        local nEquip = equipSlotInfo[1]
        local szName = equipSlotInfo[2]
        local pItem = DataModel.GetEquipItem(nEquip)
        local dwTabType = pItem and pItem.dwTabType or nil
        local dwIndex = pItem and pItem.dwIndex or nil

        local layout = tEquipEnumToParent[nEquip]
        local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetEquipBarCell, layout)
        itemScript:OnEnter(nEquip, dwTabType, dwIndex, self.bIsFusion)

        table.insert(self.scripts, itemScript)
        UIHelper.SetLongPressDistThreshold(itemScript.BtnClick, 60)
        UIHelper.BindUIEvent(itemScript.BtnClick, EventType.OnClick, function()
            if pItem then
                SoundMgr.PlayItemSound(pItem.nUiId)
            end
            self.fnAction(nEquip, dwTabType, dwIndex)
            self:SetSelected(nEquip)
        end)
    end

    UIHelper.LayoutDoLayout(self.LayoutWeapon)
end

function UIWidgetEquipBarList:SetSelected(nEquip)
    self.nLastSelected = nEquip
    for nIndex, equipSlotInfo in pairs(DataModel.tEquipBoxList) do
        UIHelper.SetVisible(self.scripts[nIndex].ImgChoosed, equipSlotInfo[1] == nEquip)
    end
end

return UIWidgetEquipBarList