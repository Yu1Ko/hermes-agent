-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIItemTipTopContent1
-- Date: 2023-02-21 09:33:10
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIItemTipTopContent1 = class("UIItemTipTopContent1")

function UIItemTipTopContent1:OnEnter(item, bItem, szSource, nPlayerID, nBox)

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo(item, bItem, szSource, nPlayerID, nBox)
end

function UIItemTipTopContent1:OnExit()
    self.bInit = false
end

function UIItemTipTopContent1:BindUIEvent()

end

function UIItemTipTopContent1:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIItemTipTopContent1:UpdateInfo(item, bItem, szSource, nPlayerID, nBox)
    local tbInfo = { ItemData.GetItemTypeInfo(item, bItem, szSource) }
    for i = 1, 3, 1 do
        UIHelper.SetString(self["LabelEquipType"..i], tbInfo[i])
        if string.is_nil(tbInfo[i]) then
            UIHelper.SetVisible(self["LabelEquipType"..i], false)
        else
            UIHelper.SetVisible(self["LabelEquipType"..i], true)
        end
    end
    -- UIHelper.SetString(self.LabelEquipType1, szType1)
    -- UIHelper.SetString(self.LabelEquipType2, szType2)
    -- UIHelper.SetString(self.LabelEquipType3, szType3)

    UIHelper.LayoutDoLayout(self.LayoutRow1)

    for i, img in ipairs(self.tbImgStarEmpty) do
        UIHelper.SetVisible(img, false)
    end

    UIHelper.SetVisible(self.RichTextSchool, false)
    
    local bIsEquip = bItem and item.nGenre == ITEM_GENRE.EQUIPMENT and (item.nSub >= EQUIPMENT_SUB.MELEE_WEAPON and item.nSub <= EQUIPMENT_SUB.BANGLE)
    if bIsEquip then
        UIHelper.SetVisible(self.ImgPlayType, true)
        UIHelper.SetVisible(self.LabelPlayType, true)

        if item.nEquipUsage == 1 then
            UIHelper.SetString(self.LabelPlayType, g_tStrings.STR_ITEM_EQUIP_PVE)
            UIHelper.SetSpriteFrame(self.ImgPlayType, "UIAtlas2_Public_PublicItem_PublicItem1_MarkPve.png")
        elseif item.nEquipUsage == 0 then
            UIHelper.SetString(self.LabelPlayType, g_tStrings.STR_ITEM_EQUIP_PVP)
            UIHelper.SetSpriteFrame(self.ImgPlayType, "UIAtlas2_Public_PublicItem_PublicItem1_MarkPvp.png")
        elseif item.nEquipUsage == 3 then
            UIHelper.SetVisible(self.ImgPlayType, false)
            UIHelper.SetString(self.LabelPlayType, g_tStrings.STR_ITEM_EQUIP_GENERAL)
        else
            UIHelper.SetString(self.LabelPlayType, g_tStrings.STR_ITEM_EQUIP_PVX)
            UIHelper.SetSpriteFrame(self.ImgPlayType, "UIAtlas2_Public_PublicItem_PublicItem1_MarkPvx.png")
        end
        UIHelper.LayoutDoLayout(self.WidgetIconLabel)

        -- 判断哪些分类不显示精炼
        if bItem and item.nGenre == ITEM_GENRE.EQUIPMENT and not self:NotShowEquipStrength(item.nSub) then
            local player
            if nPlayerID then
                player = GetPlayer(nPlayerID)
            end
            if player then
                local szInfo = ""
                local tbEquipStrengthInfo = EquipData.GetStrength(item, bItem, { dwPlayerID = player.dwID, dwX = nBox })
                if tbEquipStrengthInfo then
                    szInfo = string.format("<color=#D7F6FF>装备栏精炼</c><color=#D7F6FF>  %d/%d</c>", tbEquipStrengthInfo.nBoxLevel, tbEquipStrengthInfo.nBoxMaxLevel)
                    UIHelper.SetVisible(self.RichTextSchool, true)
                    UIHelper.SetRichText(self.RichTextSchool, szInfo)
                end
            else
                UIHelper.SetVisible(self.RichTextSchool, false)
            end
        end
    end

    UIHelper.SetVisible(self.LabelPlayType, bIsEquip)
    UIHelper.SetVisible(self.ImgPlayType, bIsEquip)
    UIHelper.SetVisible(self.WidgetRow3, bIsEquip)
    UIHelper.SetVisible(self.WidgetRow2, bIsEquip)
    
    UIHelper.LayoutDoLayout(self.LayoutItemTipTopContent1)
    UIHelper.LayoutDoLayout(self._rootNode)
end

function UIItemTipTopContent1:NotShowEquipStrength(nSubType)
    if nSubType == EQUIPMENT_SUB.ARROW or
            nSubType == EQUIPMENT_SUB.HORSE or
            nSubType == EQUIPMENT_SUB.PACKAGE or
            nSubType == EQUIPMENT_SUB.HORSE_EQUIP or
            nSubType == EQUIPMENT_SUB.MINI_AVATAR or
            nSubType == EQUIPMENT_SUB.PET then
        return true
    end

    return false
end

return UIItemTipTopContent1