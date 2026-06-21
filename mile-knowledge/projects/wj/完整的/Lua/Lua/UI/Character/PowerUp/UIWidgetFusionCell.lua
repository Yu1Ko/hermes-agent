-- ---------------------------------------------------------------------------------
-- Author: Jiayuran
-- Name: UICharacterWidgetEquipRefine
-- Date: 2022-12-06 14:39
-- Desc: UICharacterWidgetEquipRefine
-- ---------------------------------------------------------------------------------

local szNoWuCaiShi = "<color=#AED6E0>置入五彩石以查看属性</color>"
local szNoAttri = "该装备暂无熔嵌属性加成"
local szNoEquip = "穿戴装备可见熔嵌属性"

local NEW_MATERIAL_COLOR = "#79EAB4"

---@class UIWidgetFusionCell
local UIWidgetFusionCell = class("UIWidgetFusionCell")

function UIWidgetFusionCell:OnEnter()
    if not self.bInit then
        if not self.itemScript then
            self.itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetRefineMaterial_80, self.WidgetItemTop) ---@type UICharacterRefineMaterialCell
            UIHelper.SetVisible(self.itemScript._rootNode, false)
        end

        self:RegEvent()
        self.bInit = true
    end
end

function UIWidgetFusionCell:OnExit()
    self.bInit = false
end

function UIWidgetFusionCell:RegEvent()
end

function UIWidgetFusionCell:BindCancelFunc(fnCancel)
    self.itemScript:BindCancelFunc(fnCancel)
end

--local szColorRed = "#FF7575"
--local szColorGreen = "#79EAB4"
local szColorGray = FontColorID.Text_Level2
function UIWidgetFusionCell:RefreshWuXing(nEquip, nSlotIndex, tbNewMaterialInfo)
    local tOldInfo = DataModel.GetSlotBoxInfo(nEquip, nSlotIndex)
    local nSlotLevel = 0
    local bLight = true
    local pItem = DataModel.GetEquipItem(nEquip)
    local bCanMount = tOldInfo.bCanMount
    local nQuality = tOldInfo.nQuality
    local nMaxQuality = tOldInfo.nMaxQuality
    local hasItemIcon = false
    --local szQualityColor = pItem and nQuality >= pItem.nLevel

    local szColor = szColorGray
    local szName = " "
    bLight = bCanMount and pItem and nQuality >= pItem.nLevel

    if tOldInfo.dwEnchantID > 0 then
        local dwTabType, dwTabIndex = GetDiamondInfoFromEnchantID(tOldInfo.dwEnchantID)
        if dwTabType and dwTabIndex then
            local pItemInfo = ItemData.GetItemInfo(dwTabType, dwTabIndex)
            nSlotLevel = pItemInfo.nDetail

            if tbNewMaterialInfo == nil then
                self:ShowItemIcon(EQUIP_REFINE_SLOT_TYPE.DISPLAY, dwTabIndex, pItemInfo.nUiId, pItemInfo.nQuality, false)
                self.itemScript:SetBind(false)
                szColor = "#FFFFFF"
                hasItemIcon = true

                local nDiamondR, nDiamondG, nDiamondB = GetItemFontColorByQuality(pItemInfo.nQuality)
                szName = GetFormatText(UIHelper.GBKToUTF8(pItemInfo.szName), nil, nDiamondR, nDiamondG, nDiamondB)
            end
        end
    end

    if tbNewMaterialInfo ~= nil then
        if tbNewMaterialInfo.nDetail <= nSlotLevel then
            LOG.ERROR("UICharacterFusionSlotCell Error, New Material Should have level higher than original")
        end
        szColor = NEW_MATERIAL_COLOR
        nSlotLevel = tbNewMaterialInfo.nDetail
        self:ShowItemIcon(EQUIP_REFINE_SLOT_TYPE.MATERIAL_CHOSEN,
                tbNewMaterialInfo.dwIndex, tbNewMaterialInfo.nUiId, tbNewMaterialInfo.nQuality, true)
        self.itemScript:SetBind(tbNewMaterialInfo.bBind)
        local nDiamondR, nDiamondG, nDiamondB = GetItemFontColorByQuality(tbNewMaterialInfo.nQuality)
        szName = GetFormatText(UIHelper.GBKToUTF8(tbNewMaterialInfo.szName), nil, nDiamondR, nDiamondG, nDiamondB)
        nQuality = nMaxQuality --新熔嵌的孔位熔嵌后会拥有最大品质等级
        hasItemIcon = true
    end

    local szContent = ""
    if pItem then
        local tAttr = pItem.GetSlotAttrib(nSlotIndex, nSlotLevel) or {}

        if nSlotLevel == 0 then
            szContent = GetAttributeString(tAttr.nID)
            szContent = UIHelper.GBKToUTF8(szContent)
        else
            szContent = GetAttributeString(tAttr.nID, tAttr.Param0, tAttr.Param1, MAGIC_ATTRI_DEF, MAGIC_ATTRI_DEF)
            szContent = UIHelper.GBKToUTF8(szContent)
        end

        szContent = szContent ~= "" and szContent or szNoAttri
        if nSlotLevel == 0 and szContent ~= szNoAttri then
            szContent = szContent .. "?"
        end
    else
        szContent = szNoEquip
    end

    szContent = string.format("<color=%s>%s</color>", szColor, szContent)

    local szEffective = (pItem and pItem.nLevel > nQuality) and FontColorID.ImportantRed or szColorGray
    UIHelper.SetRichText(self.LabelNotEffective, UIHelper.AttachTextColor(string.format("%d品及以下生效", nQuality), szEffective))
    UIHelper.SetRichText(self.LabelActivatedTop, szContent)
    UIHelper.SetRichText(self.LabelWuXingShiName, szName)
    UIHelper.SetVisible(self.LabelWuXingShiName, hasItemIcon)
    UIHelper.SetVisible(self.LabelNotEffective, hasItemIcon)
    UIHelper.SetVisible(self.itemScript._rootNode, hasItemIcon)
    UIHelper.SetVisible(self.itemScript.BtnAdd, false)
    UIHelper.LayoutDoLayout(self.WidgetAttriTop)
end

function UIWidgetFusionCell:RefreshWuCai(nEnchantID, tbChosenMaterialInfo)
    local bSloted = nEnchantID and nEnchantID > 0
    local hasItemIcon = false

    local dwTabType = nil
    local dwIndex = nil
    local isHighLight = false
    local slotType = EQUIP_REFINE_SLOT_TYPE.DISPLAY

    if tbChosenMaterialInfo ~= nil then
        dwTabType = tbChosenMaterialInfo.dwTabType
        dwIndex = tbChosenMaterialInfo.dwIndex
        isHighLight = true
        slotType = EQUIP_REFINE_SLOT_TYPE.MATERIAL_CHOSEN

    elseif bSloted then
        dwTabType, dwIndex = GetColorDiamondInfoFromEnchantID(nEnchantID)
    end

    local szContent = ""
    local pItemInfo = dwTabType and dwIndex and GetItemInfo(dwTabType, dwIndex) or nil
    if pItemInfo then
        local nDiamondR, nDiamondG, nDiamondB = GetItemFontColorByQuality(pItemInfo.nQuality)
        szContent = GetFormatText(pItemInfo.szName, nil, nDiamondR, nDiamondG, nDiamondB)
        self:ShowItemIcon(slotType, nil, pItemInfo.nUiId, pItemInfo.nQuality, isHighLight)
        hasItemIcon = true
        nEnchantID = pItemInfo.dwEnchantID
    end

    szContent = UIHelper.GBKToUTF8(szContent)
    UIHelper.SetRichText(self.LabelActivatedTop, szContent ~= "" and szContent or szNoWuCaiShi)
    UIHelper.SetVisible(self.itemScript._rootNode, hasItemIcon)
    UIHelper.SetVisible(self.itemScript.BtnAdd, false)
end

function UIWidgetFusionCell:ShowItemIcon(slotType, dwIndex, nUiId, nQuality, isHighlight)
    if not self.itemScript then
        self.itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetRefineMaterial_80, self.WidgetItemTop) ---@type UICharacterRefineMaterialCell
    end
    self.itemScript:RefreshInfo(slotType, dwIndex, nUiId, nQuality, 1)
    --self.itemIconScript:SetHighlight(isHighlight)
end

return UIWidgetFusionCell