-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICharacterEquipCompareCell
-- Date: 2023-07-25 19:28:11
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICharacterEquipCompareCell = class("UICharacterEquipCompareCell")

function UICharacterEquipCompareCell:OnInit(tbInfo, bItem)
    self.tbInfo = tbInfo
    self.bItem = bItem
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo(self.tbInfo)
end

function UICharacterEquipCompareCell:OnExit()
    self.bInit = false
end

function UICharacterEquipCompareCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogCell, EventType.OnClick, function ()
        if self.tbInfo.funcOnClickCallback then
            self.tbInfo.funcOnClickCallback(self.tbInfo, self)
        else
            Event.Dispatch(EventType.OnSelectedEquipCompareToggle, self.tbInfo)
        end
    end)
    UIHelper.SetSwallowTouches(self.TogCell, false)
end

function UICharacterEquipCompareCell:RegEvent()
    Event.Reg(self, EventType.OnSelectedEquipCompareToggle, function(tbInfo)
        if not tbInfo then
            self:SetSelected(false)
        elseif (tbInfo.nBox and self.tbInfo.nBox == tbInfo.nBox and self.tbInfo.nIndex == tbInfo.nIndex) or
            (tbInfo.dwTabType and self.tbInfo.dwTabType == tbInfo.dwTabType and self.tbInfo.dwIndex == tbInfo.dwIndex) then
            self:SetSelected(true)
        else
            self:SetSelected(false)
        end
        self:UpdateInfo(self.tbInfo)
    end)

    Event.Reg(self, EventType.OnEnterEquipComparePanel, function(tbInfo)
        if not tbInfo then
            self:SetSelected(false)
        elseif (tbInfo.nBox and self.tbInfo.nBox == tbInfo.nBox and self.tbInfo.nIndex == tbInfo.nIndex) or
            (tbInfo.dwTabType and self.tbInfo.dwTabType == tbInfo.dwTabType and self.tbInfo.dwIndex == tbInfo.dwIndex) then
            self:SetSelected(true)
        else
            self:SetSelected(false)
        end
        self:UpdateInfo(self.tbInfo)
    end)
end

function UICharacterEquipCompareCell:UpdateInfo(tbInfo)
    local item = tbInfo.item
    local szName = UIHelper.GBKToUTF8(item.szName)
    local szType1 = ItemData.GetItemTypeInfo(item)

    UIHelper.SetString(self.LabelTypeNormal, szType1)
    UIHelper.SetString(self.LabelTypeUp, szType1)
    UIHelper.SetStringAutoClamp(self.LabelNameNormal, szName)
    UIHelper.SetStringAutoClamp(self.LabelNameUp, szName)
    UIHelper.SetVisible(self.WidgetEquipped, false)

    -- 是否推荐装备
    local dwTabType, dwIndex
    if self.bItem then
        dwTabType, dwIndex = item.dwTabType, item.dwIndex
    else
        dwTabType, dwIndex = tbInfo.dwTabType, tbInfo.dwIndex
    end
    if self.dwTabType ~= dwTabType or self.dwIndex ~= dwIndex then
        self.dwTabType = dwTabType
        self.dwIndex = dwIndex
        self.bRecommend, self.szRecommendTitle = EquipCodeData.CheckIsRoleRecommendEquip(dwTabType, dwIndex)
        UIHelper.SetVisible(self.WidgetRecommendState, self.bRecommend)
        UIHelper.SetString(self.LabelRecommendTitle, self.szRecommendTitle)
        UIHelper.LayoutDoLayout(self.WidgetRecommendState)
    end

    self.scriptIcon = self.scriptIcon or UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem)
    self.scriptIcon:SetLabelCountVisible(false)

    if self.bItem then
        self.scriptIcon:OnInit(tbInfo.nBox, tbInfo.nIndex)
    else
        self.scriptIcon:OnInitWithTabID(tbInfo.dwTabType, tbInfo.dwIndex)
        local nBox, nPos = ItemData.GetEquipItemEquiped(player, item.nSub, item.nDetail)
        local selfItem = ItemData.GetItemByPos(nBox, nPos)
        if selfItem and selfItem.dwIndex == tbInfo.dwIndex then
            UIHelper.SetVisible(self.WidgetEquipped, true)
        elseif item.nSub == EQUIPMENT_SUB.RING then
            local leftItem = ItemData.GetItemByPos(nBox, EQUIPMENT_INVENTORY.LEFT_RING)
            local rightItem = ItemData.GetItemByPos(nBox, EQUIPMENT_INVENTORY.RIGHT_RING)
            local bEquipped = (leftItem and leftItem.dwIndex == tbInfo.dwIndex) or (rightItem and rightItem.dwIndex == tbInfo.dwIndex) or false
            UIHelper.SetVisible(self.WidgetEquipped, bEquipped)
        end
    end

    if item.nBaseScore > 0 then
        self.scriptIcon:SetSpecialLabel(string.format("%d分", item.nBaseScore))
    else
        self.scriptIcon:SetSpecialLabel("")
    end

    local bRecommend = false
    if tbInfo.tbConfig and not string.is_nil(tbInfo.tbConfig.szRecommendKungfuID) then
        local tbKungfuID = string.split(tbInfo.tbConfig.szRecommendKungfuID, ";")
        local nSelfKungfuID = PlayerData.GetPlayerMountKungfuID()
        for _, szKungfuID in ipairs(tbKungfuID) do
            if szKungfuID == "1" or tostring(nSelfKungfuID) == szKungfuID then
                bRecommend = true
                break
            end
        end
    end
    UIHelper.SetVisible(self.WidgetState, bRecommend and not self.bForceHideRecommend)
    if tbInfo.tbConfig and tbInfo.tbConfig["szMagicType1"] then
        local szType = ""
        for i = 1, 3 do
            if tbInfo.tbConfig["szMagicType" .. i] and tbInfo.tbConfig["szMagicType" .. i] ~= "" then
                if szType == "" then
                    szType = UIHelper.GBKToUTF8(tbInfo.tbConfig["szMagicType" .. i])
                else
                    szType = szType .. "/" .. UIHelper.GBKToUTF8(tbInfo.tbConfig["szMagicType" .. i])
                end
            end
        end

        UIHelper.SetString(self.LabelTypeNormal, szType)
        UIHelper.SetString(self.LabelTypeUp, szType)
    end

    if tbInfo.nStrengthLevel then
        self.tbStrengStarCells = self.tbStrengStarCells or {}
        UIHelper.HideAllChildren(self.LayoutRefineStarShell)
        for i = 1, tbInfo.nStrengthLevel, 1 do
            if not self.tbStrengStarCells[i] then
                self.tbStrengStarCells[i] = UIHelper.AddPrefab(PREFAB_ID.WIdgetRefineStar, self.LayoutRefineStarShell)
            end
            UIHelper.SetVisible(self.tbStrengStarCells[i]._rootNode, true)
        end
        UIHelper.LayoutDoLayout(self.LayoutRefineStarShell)
        UIHelper.SetVisible(self.LayoutRefineStarShell, true)
    else
        UIHelper.SetVisible(self.LayoutRefineStarShell, false)
    end

    if tbInfo.tbConfig then
        self.scriptIcon:UpdatePVPImg(nil, tbInfo.tbConfig.nEquipUsage)
    elseif self.bItem then
        self.scriptIcon:UpdatePVPImg()
    else
        self.scriptIcon:UpdatePVPImg(nil, -1)
    end
    self.scriptIcon:SetSelectEnable(false)

    if self.bShowItemDesc then
        self:ShowItemDesc()
    end
end

function UICharacterEquipCompareCell:SetSelected(bSelected)
    UIHelper.SetSelected(self.TogCell, bSelected)
end

function UICharacterEquipCompareCell:GetSelected()
    return UIHelper.GetSelected(self.TogCell)
end

function UICharacterEquipCompareCell:SetToggleGroupIndex(nIndex)
    UIHelper.SetToggleGroupIndex(self.TogCell, nIndex)
end

function UICharacterEquipCompareCell:SetCurrency(szRichText, bSetColorRed)
    UIHelper.SetVisible(self.WidgetCurrency, not string.is_nil(szRichText))
    UIHelper.SetRichText(self.LabelMoney, szRichText)
    if bSetColorRed then
        szRichText = UIHelper.AttachTextColor(szRichText, FontColorID.ImportantRed)
    end

    UIHelper.LayoutDoLayout(self.WidgetCurrency)
end

function UICharacterEquipCompareCell:ShowItemDesc()
    self.bShowItemDesc = true

    if not self.tbInfo then
        return
    end

    local tbInfo = self.tbInfo
    local item = tbInfo.item
    local dwTabType, dwIndex
    if self.bItem then
        dwTabType, dwIndex = item.dwTabType, item.dwIndex
    else
        dwTabType, dwIndex = tbInfo.dwTabType, tbInfo.dwIndex
    end

    local itemInfo = ItemData.GetItemInfo(dwTabType, dwIndex)
    if not itemInfo then
        return
    end

    local szItemDesc = ItemData.GetItemDesc(itemInfo.nUiId)
    local szDesc = ParseTextHelper.ParseNormalText(szItemDesc, true)

    if szDesc then
        szDesc = string.gsub(szDesc, "使用：", "")
        szDesc = string.gsub(szDesc, "。", "")
        UIHelper.SetString(self.LabelTypeNormal, szDesc, 12)
        UIHelper.SetString(self.LabelTypeUp, szDesc, 12)
    end
end

function UICharacterEquipCompareCell:HideRecommend()
    self.bForceHideRecommend = true
    UIHelper.SetVisible(self.WidgetState, false)
end

function UICharacterEquipCompareCell:HideStarEffect()
    for _, cell in pairs(self.tbStrengStarCells) do
        UIHelper.SetVisible(cell.ImgStarLightEff, false)
    end
end

function UICharacterEquipCompareCell:ShowEquipLevel()
    local item = self.tbInfo and self.tbInfo.item

    if item and item.nLevel > 0 then
        self.scriptIcon:SetSpecialLabel(string.format("%d品", item.nLevel))
    else
        self.scriptIcon:SetSpecialLabel("")
    end
end

function UICharacterEquipCompareCell:SetEquipped(bEquipped)
    UIHelper.SetVisible(self.WidgetEquipped, bEquipped)
end

function UICharacterEquipCompareCell:SetEquipState(bShow, szImg, szContent)
    UIHelper.SetVisible(self.WidgetEquipped, bShow)
    UIHelper.SetString(self.LabelEquipped, szContent)
    UIHelper.SetSpriteFrame(self.ImgEquipped, szImg)
end

function UICharacterEquipCompareCell:SetSelectEnable(bEnable)
    self.TogCell:setEnabled(bEnable)
end

function UICharacterEquipCompareCell:GetItemInfo()
    return self.tbInfo
end

return UICharacterEquipCompareCell