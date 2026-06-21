-- ---------------------------------------------------------------------------------
-- Author: Jiayuran
-- Name: UICharacterRefineMaterialCell
-- Date: 2022-12-06 14:39
-- Desc: UICharacterRefineMaterialCell
-- ---------------------------------------------------------------------------------
---@class UICharacterRefineMaterialCell
---@field slotType EQUIP_REFINE_SLOT_TYPE
local UICharacterRefineMaterialCell = class("UICharacterRefineMaterialCell")

function UICharacterRefineMaterialCell:OnEnter()
    self.nChosenCount = 0
    self.bBind = false

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        UIHelper.SetTouchDownHideTips(self.BtnRecall, false)
        UIHelper.SetTouchDownHideTips(self.BtnAdd, false)
        UIHelper.SetTouchDownHideTips(self.BtnCell, false)

        UIHelper.SetSwallowTouches(self.BtnRecall, true)
    end
end

function UICharacterRefineMaterialCell:OnExit()
    self.bInit = false
end

function UICharacterRefineMaterialCell:BindUIEvent()

end

function UICharacterRefineMaterialCell:RegEvent()
    Event.Reg(self, EventType.EquipRefineSelectChanged, function(dwIndex, nVal)
        if self.slotType == EQUIP_REFINE_SLOT_TYPE.MATERIAL_IN_BAG and dwIndex == self.dwIndex then
            self.nChosenCount = self.nChosenCount + nVal
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, EventType.EnchantItemSelectChanged, function(dwItemUniqueIndex, nVal)
        if self.slotType == EQUIP_REFINE_SLOT_TYPE.MATERIAL_IN_BAG and dwItemUniqueIndex == self.dwItemUniqueIndex then
            self.nChosenCount = self.nChosenCount + nVal
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, "BAG_ITEM_UPDATE", function(arg0, arg1, arg2)
        if arg0 == self.nBox and arg1 == self.nIndex then
            Timer.AddFrame(self, 1, function()
                if arg0 == self.nBox and arg1 == self.nIndex then
                    self:UpdateEnchant()  --- 附魔背包的装备
                end
            end)
        end
    end)

    Event.Reg(self, "EQUIP_ITEM_UPDATE", function(arg0, arg1, arg2)
        Timer.AddFrame(self, 1, function()
            if arg0 == self.nBox and arg1 == self.nIndex then
                self:UpdateEnchant()     --- 附魔身上的装备
            end
        end)
    end)
end

function UICharacterRefineMaterialCell:BindCancelFunc(fnCancel)
    if fnCancel then
        UIHelper.BindUIEvent(self.BtnRecall, EventType.OnClick, fnCancel)
    end
end

function UICharacterRefineMaterialCell:BindAddFunc(fnFunc)
    if fnFunc then
        UIHelper.BindUIEvent(self.BtnAdd, EventType.OnClick, fnFunc)
    end
end

function UICharacterRefineMaterialCell:BindCellFunc(fnFunc)
    if fnFunc then
        UIHelper.BindUIEvent(self.BtnCell, EventType.OnClick, fnFunc)
    end
end

function UICharacterRefineMaterialCell:RefreshInfo(slotType, dwIndex, iconID, nQuality, nItemTotalCount, nCurrentCount)
    --local lastSlotType = slotType

    UIHelper.SetTouchDownHideTips(self.BtnRecall, false)
    UIHelper.SetTouchDownHideTips(self.BtnAdd, false)
    UIHelper.SetTouchDownHideTips(self.BtnCell, false)

    self.dwIndex = dwIndex
    self.nItemTotalCount = nItemTotalCount
    self.slotType = slotType
    self.iconID = iconID
    self.nQuality = nQuality
    self.nChosenCount = nCurrentCount or self.nChosenCount

    --if lastSlotType == self.slotType and lastSlotType == EQUIP_REFINE_SLOT_TYPE.EMPTY then
    --    return
    --end

    self:UpdateInfo()
end

function UICharacterRefineMaterialCell:UpdateInfo()
    UIHelper.SetVisible(self.BtnCell, false)
    UIHelper.SetVisible(self.BtnRecall, false)
    UIHelper.SetVisible(self.BtnAdd, false)
    UIHelper.SetVisible(self.ImgBlack, true)

    if self.slotType == EQUIP_REFINE_SLOT_TYPE.MATERIAL_IN_BAG then
        UIHelper.SetVisible(self.BtnCell, true)
    end

    if self.slotType == EQUIP_REFINE_SLOT_TYPE.MATERIAL_CHOSEN then
        UIHelper.SetVisible(self.BtnRecall, true)
        UIHelper.SetVisible(self.BtnAdd, true)
    end

    if self.slotType == EQUIP_REFINE_SLOT_TYPE.ADD_MATERIAL then
        UIHelper.SetVisible(self.ImgBlack, false)
        UIHelper.SetVisible(self.BtnAdd, true)
    end

    if self.slotType == EQUIP_REFINE_SLOT_TYPE.EMPTY then
        UIHelper.SetVisible(self.ImgBlack, false)
    end

    UIHelper.SetVisible(self.ImgPolishCountBG, false) -- 放在Btn状态之后设置，防止Btn对子节点Visible状态的影响
    UIHelper.SetVisible(self.LabelCount, false)
    UIHelper.SetVisible(self.ImgSelectBG, false)
    UIHelper.SetVisible(self.ImgSelectRT, false)
    UIHelper.SetVisible(self.ImgIcon, false)
    UIHelper.SetVisible(self.LabelChosenCount, false)
    UIHelper.SetVisible(self.WidgetBind, self.bBind)

    if self.slotType == EQUIP_REFINE_SLOT_TYPE.EMPTY or self.slotType == EQUIP_REFINE_SLOT_TYPE.ADD_MATERIAL then
        self:SetBind(false)
        return
    end

    local iconID, nQuality = self.iconID, self.nQuality

    if iconID and nQuality then
        if self.nChosenCount and self.nChosenCount > 0 then
            UIHelper.SetVisible(self.ImgSelectRT, true)
            UIHelper.SetVisible(self.ImgSelectBG, true)
            UIHelper.SetVisible(self.LabelChosenCount, true)
            UIHelper.SetString(self.LabelChosenCount, self.nChosenCount)
            UIHelper.LayoutDoLayout(self.ImgChooseNum)
        end

        --print(item.dwTabType, item.szName, ItemData.GetItemStackNum(item), self.nItemID, item.nUiId)

        UIHelper.SetSpriteFrame(self.ImgPolishCountBG, ItemQualityBGColor[nQuality + 1])
        UIHelper.SetVisible(self.ImgPolishCountBG, true)

        UIHelper.SetItemIconByItemUuid(self.ImgIcon, iconID)

        local nStackNum = self.nItemTotalCount
        if nStackNum and nStackNum > 1 then
            -- and item.nGenre ~= ITEM_GENRE.EQUIPMENT
            UIHelper.SetString(self.LabelCount, tostring(nStackNum))
            UIHelper.SetVisible(self.LabelCount, true)
        end

        UIHelper.SetVisible(self.ImgIcon, true)
    else
        LOG.ERROR("[UICharacterRefineMaterialCell 'UpdateInfo'] tbItem not properly set.")
    end
end

function UICharacterRefineMaterialCell:SetBind(bBind)
    self.bBind = bBind
    UIHelper.SetVisible(self.WidgetBind, bBind)
end

function UICharacterRefineMaterialCell:ShowToggle()
    UIHelper.SetVisible(self.BtnRecall, false)
    UIHelper.SetVisible(self.BtnAdd, false)
    UIHelper.SetVisible(self.BtnCell, false)
    UIHelper.SetVisible(self.ToggleSingle, true)

end

function UICharacterRefineMaterialCell:SetToggleSwallowTouches()
    UIHelper.SetSwallowTouches(self.BtnAdd, false)
    UIHelper.SetSwallowTouches(self.ToggleSingle, false)
end

function UICharacterRefineMaterialCell:UpdateEnchant(item)
    item = item or ItemData.GetItemByPos(self.nBox, self.nIndex)
    if item then
        local bHasActivated = false
        local tbAttribInfos, nNeedUpdate = EquipData.GetEnchantAttribTip(item)
        for i = 1, 2 do
            if tbAttribInfos[i] then
                local bActived = tbAttribInfos[i].bActived
                local szIconImg = tbAttribInfos[i].szEnchantIconImg
                if bActived then
                    bHasActivated = true
                    UIHelper.SetSpriteFrame(self.IconAttris[i], szIconImg)
                    UIHelper.SetVisible(self.WidgetAttris[i], true)
                else
                    UIHelper.SetVisible(self.WidgetAttris[i], false)
                end
            end
        end
        UIHelper.LayoutDoLayout(self.LayoutFuMoBar)
        UIHelper.SetVisible(self.LayoutFuMoBar, bHasActivated)
    end
end

function UICharacterRefineMaterialCell:SetItemPos(nBox, nIndex)
    self.nBox, self.nIndex = nBox, nIndex
end

function UICharacterRefineMaterialCell:SetEnchantItemID(dwItemUniqueIndex)
    self.dwItemUniqueIndex = dwItemUniqueIndex
end

function UICharacterRefineMaterialCell:SetEnable(bState, szTip)
    UIHelper.SetEnable(self.BtnRecall, bState)
    UIHelper.SetButtonState(self.BtnAdd, bState and BTN_STATE.Normal or BTN_STATE.Disable,function()
        TipsHelper.ShowImportantBlueTip(szTip)
    end)
    UIHelper.SetEnable(self.BtnCell, bState)
end

function UICharacterRefineMaterialCell:UpdatePVPImg(item)
    -- local bCanShowPVP = (item.dwTabType == ITEM_TABLE_TYPE.CUST_WEAPON and item.nSub ~= 13 and item.nSub ~= 16)
    --     or item.dwTabType == ITEM_TABLE_TYPE.CUST_ARMOR
    --     or (item.dwTabType == ITEM_TABLE_TYPE.CUST_TRINKET and (item.nSub == 4 or item.nSub == 5 or item.nSub == 7))
    if item then
        local bCanShowPVP = item.nGenre == ITEM_GENRE.EQUIPMENT and (item.nSub >= EQUIPMENT_SUB.MELEE_WEAPON and item.nSub <= EQUIPMENT_SUB.BANGLE)
        local nEquipUsage = item.nEquipUsage
        -- print( self.nBox, self.nIndex, item.nGenre, item.nSub, item.nEquipUsage, bCanShowPVP)
        if bCanShowPVP then
            if nEquipUsage == 1 then
                UIHelper.SetSpriteFrame(self.ImgWeaponMark, "UIAtlas2_Public_PublicItem_PublicItem1_MarkPve.png")
                UIHelper.SetVisible(self.ImgWeaponMark, true)
            elseif nEquipUsage == 0 then
                UIHelper.SetSpriteFrame(self.ImgWeaponMark, "UIAtlas2_Public_PublicItem_PublicItem1_MarkPvp.png")
                UIHelper.SetVisible(self.ImgWeaponMark, true)
            elseif nEquipUsage == 2 then
                UIHelper.SetSpriteFrame(self.ImgWeaponMark, "UIAtlas2_Public_PublicItem_PublicItem1_MarkPvx.png")
                UIHelper.SetVisible(self.ImgWeaponMark, true)
            elseif nEquipUsage == 3 then
                UIHelper.SetVisible(self.ImgWeaponMark, false)
            end
        else
            UIHelper.SetVisible(self.ImgWeaponMark, false)
        end
    end
end

return UICharacterRefineMaterialCell