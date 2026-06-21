-- ---------------------------------------------------------------------------------
-- Author: Jiayuran
-- Name: UICharacterWidgetEquipRefine
-- Date: 2022-12-06 14:39
-- Desc: UICharacterWidgetEquipRefine
-- ---------------------------------------------------------------------------------

local UICharacterFusionSlotCell = class("UICharacterFusionSlotCell")

local szQuality = "属性对%d品以下装备生效"
local szNoAttri = "该装备暂无属性"
local szNoWuCaiShi = "暂未选择五彩石"
function UICharacterFusionSlotCell:OnEnter(nEquip, szName, tEquipBoxInfo, dwTabType, dwIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        print("UICharacterFusionSlotCell:OnEnter")
    end
end

function UICharacterFusionSlotCell:OnInit(nEquip, nSlotIndex, tbChosenMaterialInfo)
    local tInfo = DataModel.GetSlotBoxInfo(nEquip, nSlotIndex)
    local nSlotLevel = 0
    local bLight = true
    local pItem = DataModel.GetEquipItem(nEquip)
    local bCanMount = tInfo.bCanMount
    local nQuality = tInfo.nQuality
    local nMaxQuality = tInfo.nMaxQuality
    local hasItemIcon = false
    bLight = bCanMount and pItem and nQuality >= pItem.nLevel

    if tInfo.dwEnchantID > 0 then
        local dwTabType, dwTabIndex = GetDiamondInfoFromEnchantID(tInfo.dwEnchantID)
        if dwTabType and dwTabIndex then
            local pItemInfo = ItemData.GetItemInfo(dwTabType, dwTabIndex)
            nSlotLevel = pItemInfo.nDetail
        end

        if tbChosenMaterialInfo == nil then
            self:ShowItemIcon(dwTabType, dwTabIndex, false)
            hasItemIcon = true
        end
    end

    if tbChosenMaterialInfo ~= nil then
        if tbChosenMaterialInfo.nDetail <= nSlotLevel then
            LOG.ERROR("UICharacterFusionSlotCell Error, New Material Should have level higher than original")
        end
        nSlotLevel = tbChosenMaterialInfo.nDetail
        self:ShowItemIcon(tbChosenMaterialInfo.dwTabType, tbChosenMaterialInfo.dwIndex, true)
        hasItemIcon = true
    end

    local szContent = ""
    if pItem then
        local tAttr = pItem.GetSlotAttrib(nSlotIndex, nSlotLevel) or {}

        if nSlotLevel == 0 then
            --hDesc:SetFontColor(192, 192, 192)
            --hDesc:SetText(GetAttributeString(tAttr.nID))
            szContent = GetAttributeString(tAttr.nID)
            szContent = UIHelper.GBKToUTF8(szContent)
        else
            --hDesc:SetFontColor(0, 200, 0)
            --hDesc:SetText(GetAttributeString(tAttr.nID, tAttr.Param0, tAttr.Param1, MAGIC_ATTRI_DEF, MAGIC_ATTRI_DEF))
            szContent = GetAttributeString(tAttr.nID, tAttr.Param0, tAttr.Param1, MAGIC_ATTRI_DEF, MAGIC_ATTRI_DEF)
            szContent = UIHelper.GBKToUTF8(szContent)
        end
    end

    UIHelper.SetString(self.LabelActivatedTop, szContent ~= "" and szContent or szNoAttri)
    UIHelper.SetRichText(self.LabelOtherContent, GetFormatText(string.format(szQuality, nMaxQuality),nil,206,225,249))
    UIHelper.LayoutDoLayout(self.LayoutContent)
    if hasItemIcon == false then
        self:HideItemIcon()
    end
end

function UICharacterFusionSlotCell:OnInitWuCaiStone(nEquip, tbChosenMaterialInfo)
    local pItemWeapon = DataModel.GetEquipItem(nEquip)
    local nEnchantID = pItemWeapon and pItemWeapon.GetMountFEAEnchantID() or 0
    local bSloted = nEnchantID > 0
    local hasItemIcon = false
    
    local dwTabType = nil
    local dwIndex = nil
    local isHighLight = false
    
    if tbChosenMaterialInfo ~= nil then
        dwTabType = tbChosenMaterialInfo.dwTabType
        dwIndex = tbChosenMaterialInfo.dwIndex
        isHighLight = true
    elseif bSloted then
        dwTabType, dwIndex = GetColorDiamondInfoFromEnchantID(nEnchantID)
    end
    
    local szContent = ""
    local pItemInfo = dwTabType and dwIndex and GetItemInfo(dwTabType, dwIndex) or nil
    if pItemInfo then
        local nDiamondR, nDiamondG, nDiamondB = GetItemFontColorByQuality(pItemInfo.nQuality)
        szContent = GetFormatText(pItemInfo.szName,nil,nDiamondR, nDiamondG, nDiamondB)
        self:ShowItemIcon(dwTabType, dwIndex, isHighLight)
        hasItemIcon = true
        nEnchantID = pItemInfo.dwEnchantID
    end

    --if nEnchantID > 0 then
    --    local aAttr = GetFEAInfoByEnchantID(nEnchantID)
    --    local szContent = nil
    --    --LOG.TABLE(aAttr)
    --    for k, v in pairs(aAttr) do
    --        if v.nID ~= ATTRIBUTE_TYPE.SKILL_EVENT_HANDLER then
    --            ItemData.FormatAttributeValue(v)
    --            local szText = GetAttributeString(v.nID, v.nValue1, v.nValue2, MAGIC_ATTRI_DEF, MAGIC_ATTRI_DEF)
    --            szText = GetFormatText(szText,nil,133,174,181)
    --            --local hItem = hAttrList:AppendItemFromIni(INI_PATH, "Handle_DiamondAttr")
    --            --local hTextAttr = hItem:Lookup("Text_DiamondAttr")
    --            --hTextAttr:SetText(szText)
    --            --if GetFEAActiveFlag(GetClientPlayer().dwID, INVENTORY_INDEX.EQUIP, nEquipInv, tonumber(k) - 1) then
    --            --    hTextAttr:SetFontColor(0, 200, 0)
    --            --else
    --            --    hTextAttr:SetFontColor(192, 192, 192)
    --            --end
    --            if szContent == nil then
    --                szContent = szText
    --            else
    --                szContent = table.concat({szContent,"\n",szText})
    --            end
    --        end
    --    end
    szContent = UIHelper.GBKToUTF8(szContent)
    UIHelper.SetRichText(self.LabelAddContent, szContent ~= "" and szContent or szNoWuCaiShi)
    UIHelper.LayoutDoLayout(self.LayoutContent)       
end

function UICharacterFusionSlotCell:ShowItemIcon(dwTabType, dwTabIndex, isHighlight)
    if self.itemIconScript == nil then
        self.itemIconScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.WidgetGoods)
        self.itemIconScript:HideButton()
    end
    self.itemIconScript:OnInitWithTabID(dwTabType, dwTabIndex)
    self.itemIconScript:SetHighlight(isHighlight)
    UIHelper.SetActiveAndCache(self, self.itemIconScript._rootNode, true)
end

function UICharacterFusionSlotCell:HideItemIcon()
    if self.itemIconScript ~= nil then
        UIHelper.SetActiveAndCache(self, self.itemIconScript._rootNode, false)
    end
end

function UICharacterFusionSlotCell:OnExit()
    self.bInit = false
end

function UICharacterFusionSlotCell:BindUIEvent()
end

function UICharacterFusionSlotCell:RegEvent()

end

return UICharacterFusionSlotCell