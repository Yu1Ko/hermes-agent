-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICustomizedSetEquipSlotCell
-- Date: 2024-07-16 11:37:28
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICustomizedSetEquipSlotCell = class("UICustomizedSetEquipSlotCell")

function UICustomizedSetEquipSlotCell:OnEnter(nType, funcCallback)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nType = nType
    self.funcCallback = funcCallback

    self.tbData = EquipCodeData.GetCustomizedSetEquip(nType)
    self.tbPowerUpInfo = EquipCodeData.GetCustomizedSetEquipPowerUpInfo(nType)

    self:UpdateInfo()
end

function UICustomizedSetEquipSlotCell:OnExit()
    self.bInit = false
end

function UICustomizedSetEquipSlotCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogSelect, EventType.OnClick, function ()
        if self.funcCallback then
            self.funcCallback()
        end

        if self.tbData then
            Event.Dispatch(EventType.OnSelectedEquipCompareToggle, self.tbData)
        end
    end)
end

function UICustomizedSetEquipSlotCell:RegEvent()
    Event.Reg(self, EventType.OnUpdateCustomizedSetEquipList, function(nType)
        if not nType or nType == self.nType then
            self.tbData = EquipCodeData.GetCustomizedSetEquip(self.nType)
            self.tbPowerUpInfo = EquipCodeData.GetCustomizedSetEquipPowerUpInfo(self.nType)
            self:UpdateEquipInfo()
        end
    end)
end

function UICustomizedSetEquipSlotCell:UpdateInfo()
    self:UpdateBaseInfo()
    self:UpdateEquipInfo()
end

function UICustomizedSetEquipSlotCell:UpdateBaseInfo()
    UIHelper.SetSpriteFrame(self.ImgEquipBarIcon, EquipToDefaultIcon[self.nType])
end

function UICustomizedSetEquipSlotCell:UpdateEquipInfo()
    -- UIHelper.SetRichText(self.LabelRefineLevel, string.format("%d/%d", self.tbData.nRefineLevel, self.tbData.nMaxRefineLevel))
    UIHelper.SetTabVisible(self.tbWidgetWuxing, false)
    for nSlot, widget in ipairs(self.tbWidgetWuxing) do
        if nSlot <= EquipType2SlotCount[self.nType] then
            UIHelper.SetVisible(widget, true)
        end

        local scriptCell = UIHelper.GetBindScript(self.tbWidgetWuxing[nSlot])
        UIHelper.ClearTexture(scriptCell.ImgIconWuxing)
    end

    if self.tbData then
        UIHelper.SetVisible(self.WidgetItem, true)
        if not self.scriptIcon then
            self.scriptIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem)
        end

        self.scriptIcon:OnInitWithTabID(self.tbData.dwTabType, self.tbData.dwIndex)
        self.scriptIcon:SetSelectEnable(false)

        local tbEquipStrengthInfo = EquipData.GetStrength(self.tbData.item, false)
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
        end
    else
        UIHelper.SetVisible(self.WidgetItem, false)
        UIHelper.SetRichText(self.RichTextRefineLevel, "")
    end
end

return UICustomizedSetEquipSlotCell