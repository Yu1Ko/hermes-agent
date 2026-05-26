-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICustomizedSetShareEquipCell
-- Date: 2024-07-16 11:37:28
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICustomizedSetShareEquipCell = class("UICustomizedSetShareEquipCell")

function UICustomizedSetShareEquipCell:OnEnter(nType, bPreview, tEquipData, tbPowerUpInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nType = nType
    self.bPreview = bPreview

    self.tEquipData = tEquipData
    self.tbPowerUpInfo = tbPowerUpInfo or {}

    self:UpdateInfo()
end

function UICustomizedSetShareEquipCell:OnExit()
    self.bInit = false
end

function UICustomizedSetShareEquipCell:BindUIEvent()

end

function UICustomizedSetShareEquipCell:RegEvent()

end

function UICustomizedSetShareEquipCell:UpdateInfo()
    self:UpdateBaseInfo()
    self:UpdateEquipInfo()
end

function UICustomizedSetShareEquipCell:UpdateBaseInfo()
    UIHelper.SetSpriteFrame(self.ImgEquipBarIcon, EquipToDefaultIcon[self.nType])
end

function UICustomizedSetShareEquipCell:UpdateEquipInfo()
    -- UIHelper.SetRichText(self.LabelRefineLevel, string.format("%d/%d", self.tEquipData.nRefineLevel, self.tEquipData.nMaxRefineLevel))
    local szEnchantAttrib = "附魔：无"

    UIHelper.SetTabVisible(self.tbWidgetWuxing, false)
    for nSlot, widget in ipairs(self.tbWidgetWuxing) do
        if nSlot <= EquipType2SlotCount[self.nType] then
            UIHelper.SetVisible(widget, true)
        end

        local scriptCell = UIHelper.GetBindScript(self.tbWidgetWuxing[nSlot])
        UIHelper.ClearTexture(scriptCell.ImgIconWuxing)
    end

    if self.tEquipData then
        UIHelper.SetVisible(self.WidgetItem, true)
        if not self.scriptIcon then
            self.scriptIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem)
            self.scriptIcon:SetClickNotSelected(true)
        end

        self.scriptIcon:OnInitWithTabID(self.tEquipData.dwTabType, self.tEquipData.dwIndex)

        if self.bPreview then
            self.scriptIcon:SetSelectEnable(true)
            self.scriptIcon:SetClickCallback(function(nItemType, nItemIndex)
                Timer.AddFrame(self, 1, function()
                    local tips, scriptItemTip = TipsHelper.ShowItemTips(self._rootNode, self.tEquipData.dwTabType, self.tEquipData.dwIndex, false)
                    scriptItemTip:SetPlayerID(0)
                    scriptItemTip:SetCustomizedSetEquipPowerUpInfo(self.tbPowerUpInfo)
                    scriptItemTip:OnInitWithTabID(self.tEquipData.dwTabType, self.tEquipData.dwIndex)
                    tips:SetAutoLayoutDirPriority({TipsLayoutDir.RIGHT_CENTER, TipsLayoutDir.LEFT_CENTER})
                    tips:Update()
                end)
            end)
        else
            self.scriptIcon:SetSelectEnable(false)
        end


        local tbEquipStrengthInfo = EquipData.GetStrength(self.tEquipData.item, false)
        UIHelper.SetRichText(self.RichTextRefineLevel, string.format("%d/%d", 0, tbEquipStrengthInfo.nEquipMaxLevel))

        if self.tbPowerUpInfo then
            UIHelper.SetRichText(self.RichTextRefineLevel, string.format("%d/%d", self.tbPowerUpInfo.nStrengthLevel or 0, tbEquipStrengthInfo.nEquipMaxLevel))
            for nSlot, nLevel in pairs(self.tbPowerUpInfo.tbSlotInfo or {}) do
                local scriptCell = UIHelper.GetBindScript(self.tbWidgetWuxing[nSlot])
                local nItemTabID = WU_XING_STONE_ITEM_ID[nLevel]
                local itemInfo = ItemData.GetItemInfo(ITEM_TABLE_TYPE.OTHER, nItemTabID)
                local bResult = UIHelper.SetItemIconByItemInfo(scriptCell.ImgIconWuxing, itemInfo)
                if not bResult then
                    UIHelper.ClearTexture(scriptCell.ImgIconWuxing)
                end
            end
            UIHelper.LayoutDoLayout(self.LayoutWuXingInlay)

            local tbEnchant = self.tbPowerUpInfo.tbEnchant or {}
            if tbEnchant.nID and tbEnchant.nID > 0 then
                local result = UIHelper.GBKToUTF8(Table_GetEnchantAttributeName(tbEnchant.nID) or "")
                if not string.is_nil(result) then
                    szEnchantAttrib = string.format("附魔：%s", result)
                else
                    local nItemTabID = EnchantData.GetItemIndexWithEnchantID(tbEnchant.nID)
                    if nItemTabID then
                        local itemInfo = ItemData.GetItemInfo(5, nItemTabID)
                        szName = ItemData.GetItemNameByItem(itemInfo)
                        szName = UIHelper.GBKToUTF8(szName)
                        szEnchantAttrib = string.format("附魔：%s", szName)
                    end
                end
            end

            local item = self.tEquipData.item
            local bMatchSub = (item.nSub == EQUIPMENT_SUB.HELM or item.nSub == EQUIPMENT_SUB.CHEST or item.nSub == EQUIPMENT_SUB.WAIST
                            or item.nSub == EQUIPMENT_SUB.BANGLE or item.nSub == EQUIPMENT_SUB.BOOTS)
            local bUsage = self.tEquipData.tbConfig and (self.tEquipData.tbConfig.nEquipUsage == EQUIPMENT_USAGE_TYPE.IS_PVE_EQUIP or self.tEquipData.tbConfig.nEquipUsage == EQUIPMENT_USAGE_TYPE.IS_PVP_EQUIP)
            local bMatchLevel = item.nLevel >= 5600
            if bMatchSub and bMatchLevel and bUsage then
                -- if self.tEquipData.tbConfig.nEquipUsage == EQUIPMENT_USAGE_TYPE.IS_PVE_EQUIP then
                --     local tbBigEnchantItemIndex = EnchantData.GetRecommendEnchantWithItemInfo(item, 2, EquipCodeData.dwCurKungfuID, self.tEquipData.tbConfig.nEquipUsage)
                --     local szName, nLastItemTabID
                --     for nItemTabID, _ in pairs(tbBigEnchantItemIndex) do
                --         if not nLastItemTabID or nLastItemTabID < nItemTabID then
                --             nLastItemTabID = nItemTabID
                --         end
                --     end
                --     if nLastItemTabID then
                --         local itemInfo = ItemData.GetItemInfo(5, nLastItemTabID)
                --         szName = ItemData.GetItemNameByItem(itemInfo)
                --         szName = UIHelper.GBKToUTF8(szName)
                --     end

                --     if szName then
                --         local start = string.find(szName, "·")
                --         if start then
                --             szName = string.sub(szName, 0, start - 1)
                --         end
                --         szEnchantAttrib = string.format("%s | %s", szEnchantAttrib, szName)
                --     end
                -- else
                local tbBigEnchant = self.tbPowerUpInfo.tbBigEnchant or {}
                if tbBigEnchant.nID and tbBigEnchant.nID > 0 then
                    local nItemTabID = EnchantData.GetItemIndexWithEnchantID(tbBigEnchant.nID)
                    local szName

                    if nItemTabID then
                        local itemInfo = ItemData.GetItemInfo(5, nItemTabID)
                        szName = ItemData.GetItemNameByItem(itemInfo)
                        szName = UIHelper.GBKToUTF8(szName)
                    end

                    if szName then
                        local start = string.find(szName, "·")
                        if start then
                            szName = string.sub(szName, 0, start - 1)
                        end
                        szEnchantAttrib = string.format("%s | %s", szEnchantAttrib, szName)
                    end
                end
                -- end
            end
        end

        local item = self.tEquipData.item
        local szName = UIHelper.GBKToUTF8(item.szName)
        local szType1 = ItemData.GetItemTypeInfo(item)

        UIHelper.SetString(self.LabelTypeNormal, szType1)
        UIHelper.SetStringAutoClamp(self.LabelNameNormal, szName)
        UIHelper.SetStringAutoClamp(self.LabelStatusNormal, szEnchantAttrib)

        if self.tEquipData.tbConfig and self.tEquipData.tbConfig["szMagicType1"] then
            local szType = ""
            for i = 1, 3 do
                if self.tEquipData.tbConfig["szMagicType" .. i] and self.tEquipData.tbConfig["szMagicType" .. i] ~= "" then
                    if szType == "" then
                        szType = UIHelper.GBKToUTF8(self.tEquipData.tbConfig["szMagicType" .. i])
                    else
                        szType = szType .. "/" .. UIHelper.GBKToUTF8(self.tEquipData.tbConfig["szMagicType" .. i])
                    end
                end
            end

            UIHelper.SetString(self.LabelTypeNormal, szType)
        end

    else
        UIHelper.SetVisible(self.WidgetItem, false)
        UIHelper.SetRichText(self.RichTextRefineLevel, "")

        UIHelper.SetString(self.LabelTypeNormal, "")
        UIHelper.SetStringAutoClamp(self.LabelNameNormal, "未选择")
        UIHelper.SetStringAutoClamp(self.LabelStatusNormal, szEnchantAttrib)
    end
end

return UICustomizedSetShareEquipCell