-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOtherCharacterEquipPage
-- Date: 2023-03-07 11:36:10
-- Desc: ?
-- ---------------------------------------------------------------------------------
local Equip1Enum = {
    -- 头部
    EQUIPMENT_INVENTORY.HELM,
    -- 上衣
    EQUIPMENT_INVENTORY.CHEST,
    -- 腰带
    EQUIPMENT_INVENTORY.WAIST,
    -- 下装
    EQUIPMENT_INVENTORY.PANTS,
    -- 鞋子
    EQUIPMENT_INVENTORY.BOOTS,
}

local Equip2Enum = {
    -- 护腕
    EQUIPMENT_INVENTORY.BANGLE,
    -- 项链
    EQUIPMENT_INVENTORY.AMULET,
    -- 腰坠
    EQUIPMENT_INVENTORY.PENDANT,
    -- 戒指
    EQUIPMENT_INVENTORY.LEFT_RING,
    -- 戒指
    EQUIPMENT_INVENTORY.RIGHT_RING,
}

local WeaponEnum = {
    -- 普通近战武器
    EQUIPMENT_INVENTORY.MELEE_WEAPON,
    -- 重剑
    EQUIPMENT_INVENTORY.BIG_SWORD,
    -- 远程武器
    EQUIPMENT_INVENTORY.RANGE_WEAPON,
    -- 暗器
    EQUIPMENT_INVENTORY.ARROW,
}

local UIOtherCharacterEquipPage = class("UIOtherCharacterEquipPage")

function UIOtherCharacterEquipPage:OnEnter(nPlayerID, nCenterID, szGlobalRoleID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nPlayerID = nPlayerID
    self.nCenterID = nCenterID
    self.szGlobalRoleID = szGlobalRoleID
    self:UpdateInfo()
    OutFitPreviewData.nCurrentOtherPlayerID = nPlayerID
end

function UIOtherCharacterEquipPage:OnExit()
    self.bInit = false
end

function UIOtherCharacterEquipPage:BindUIEvent()

end

function UIOtherCharacterEquipPage:RegEvent()
    Event.Reg(self, "PEEK_PLAYER_EXTERIOR", function ()
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        self:ClearSelect()
    end)
end

function UIOtherCharacterEquipPage:UpdateInfo()
    local player = self:GetPlayer()
    if not player then return end

    self:UpdateEquipInfo()
    self:UpdatePersonalCardInfo()
end

function UIOtherCharacterEquipPage:UpdateEquipInfo()
    local player = self:GetPlayer()
    if not player then return end

    self.tbEquipCell = {}
    self.tbWeaponCell = {}

    UIHelper.SetVisible(self.WidgetEquipRank, true)
    UIHelper.SetString(self.LabelRankNum, PlayerData.GetPlayerTotalEquipScore(player))

    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupEquip)
    for i, nType in ipairs(Equip1Enum) do
        UIHelper.RemoveAllChildren(self.tbWidgetEquip1[i])
		self.tbEquipCell[nType] = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.tbWidgetEquip1[i])
        self.tbEquipCell[nType]:SetPlayerID(self.nPlayerID)
        self.tbEquipCell[nType]:OnInit(INVENTORY_INDEX.EQUIP, nType)
        self.tbEquipCell[nType]:UpdatePVPImg()
        self.tbEquipCell[nType]:SetLabelCountVisible(false)
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupEquip, self.tbEquipCell[nType].ToggleSelect)
        self.tbEquipCell[nType]:SetClickCallback(function(nBox, nIndex)
            if not self.scriptItemTip then
                self.scriptItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemCard)
                self.scriptItemTip:SetForbidShowEquipCompareBtn(true)

                self.scriptItemTip:SetPlayerID(self.nPlayerID)
            end
            if not self.scriptSelfItemTip then
                self.scriptSelfItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemSelfCard)
                self.scriptSelfItemTip:SetForbidShowEquipCompareBtn(true)
            end
            if nBox and nIndex then
                self.nCurSelectedEquipType = nType
            end

            if self.nCurSelectedEquipType == nType then
                self.scriptItemTip:OnInit(nBox, nIndex)
                if nType == EQUIPMENT_INVENTORY.PANTS then
                    self.scriptItemTip:SetBtnState({})
                else
                    self.scriptItemTip:SetBtnState({{
                        szName = "角色试穿",
                        OnClick = function ()
                            OutFitPreviewData.tbCurPreview = {}
                            local Item = ItemData.GetPlayerItem(player, nBox, nIndex)
                            table.insert(OutFitPreviewData.tbCurPreview, OutFitPreviewData.PandentItemType[3][nType], {["nType"] = OutFitPreviewData.PreviewType.Equip, ["nTabType"] = Item.dwTabType, ["dwIndex"] = Item.dwIndex})
                            Event.Dispatch("ON_HIDEMINISCENE_UNTILNEWVIEWCLOSE")
                            UIMgr.Open(VIEW_ID.PanelOutfitPreview, player.dwID, OutFitPreviewData.tbCurPreview)
                        end
                    }})
                end
                self.scriptSelfItemTip:ShowCompareEquipTip(true)
                self.scriptSelfItemTip:OnInit(nBox, nIndex)
                self.scriptSelfItemTip:ShowCurEquipImg(true)
            end

            if not ItemData.GetItemByPos(nBox, nIndex) then
                Event.Dispatch(EventType.OnShowCharacterChangeEquipList, nBox, nIndex)
            end
        end)

        local item = ItemData.GetItemByPos(INVENTORY_INDEX.EQUIP, nType)
        if item then
            local tbEquipStrengthInfo = EquipData.GetEquipStrengthInfo(player, item, true, nType)
            if tbEquipStrengthInfo and tbEquipStrengthInfo.nEquipMaxLevel > 0 then
                UIHelper.SetVisible(self.tbImgMaxFrameEquip1[i], tbEquipStrengthInfo.nBoxLevel >= tbEquipStrengthInfo.nEquipMaxLevel)
            elseif tbEquipStrengthInfo and tbEquipStrengthInfo.nBoxMaxLevel > 0 then
                UIHelper.SetVisible(self.tbImgMaxFrameEquip1[i], tbEquipStrengthInfo.nBoxLevel == tbEquipStrengthInfo.nBoxMaxLevel)
            else
                UIHelper.SetVisible(self.tbImgMaxFrameEquip1[i], false)
            end
        else
            UIHelper.SetVisible(self.tbImgMaxFrameEquip1[i], false)
        end
	end

    for i, nType in ipairs(Equip2Enum) do
        UIHelper.RemoveAllChildren(self.tbWidgetEquip2[i])
		self.tbEquipCell[nType] = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.tbWidgetEquip2[i])
        self.tbEquipCell[nType]:SetPlayerID(self.nPlayerID)
        self.tbEquipCell[nType]:OnInit(INVENTORY_INDEX.EQUIP, nType)
        self.tbEquipCell[nType]:UpdatePVPImg()
        self.tbEquipCell[nType]:SetLabelCountVisible(false)
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupEquip, self.tbEquipCell[nType].ToggleSelect)
        self.tbEquipCell[nType]:SetClickCallback(function(nBox, nIndex)
            if not self.scriptItemTip then
                self.scriptItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemCard)
                self.scriptItemTip:SetForbidShowEquipCompareBtn(true)
                self.scriptItemTip:SetPlayerID(self.nPlayerID)
            end
            if not self.scriptSelfItemTip then
                self.scriptSelfItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemSelfCard)
                self.scriptSelfItemTip:SetForbidShowEquipCompareBtn(true)
            end

            if nBox and nIndex then
                self.nCurSelectedEquipType = nType
            end

            if self.nCurSelectedEquipType == nType then
                self.scriptItemTip:OnInit(nBox, nIndex)
                if nType == EQUIPMENT_INVENTORY.BANGLE then
                    self.scriptItemTip:SetBtnState({{
                        szName = "角色试穿",
                        OnClick = function ()
                            OutFitPreviewData.tbCurPreview = {}
                            local Item = ItemData.GetPlayerItem(player, nBox, nIndex)
                            table.insert(OutFitPreviewData.tbCurPreview, OutFitPreviewData.PandentItemType[3][nType], {["nType"] = OutFitPreviewData.PreviewType.Equip, ["nTabType"] = Item.dwTabType, ["dwIndex"] = Item.dwIndex})
                            Event.Dispatch("ON_HIDEMINISCENE_UNTILNEWVIEWCLOSE")
                            UIMgr.Open(VIEW_ID.PanelOutfitPreview, player.dwID, OutFitPreviewData.tbCurPreview)
                        end
                    }})
                else
                    self.scriptItemTip:SetBtnState({})
                end
                self.scriptSelfItemTip:ShowCompareEquipTip(true)
                self.scriptSelfItemTip:OnInit(nBox, nIndex)
            end

            if not ItemData.GetItemByPos(nBox, nIndex) then
                Event.Dispatch(EventType.OnShowCharacterChangeEquipList, nBox, nIndex)
            end
        end)

        local item = ItemData.GetItemByPos(INVENTORY_INDEX.EQUIP, nType)
        if item then
            local tbEquipStrengthInfo = EquipData.GetEquipStrengthInfo(player, item, true, nType)
            if tbEquipStrengthInfo and tbEquipStrengthInfo.nEquipMaxLevel > 0 then
                UIHelper.SetVisible(self.tbImgMaxFrameEquip2[i], tbEquipStrengthInfo.nBoxLevel >= tbEquipStrengthInfo.nEquipMaxLevel)
            elseif tbEquipStrengthInfo and tbEquipStrengthInfo.nBoxMaxLevel > 0 then
                UIHelper.SetVisible(self.tbImgMaxFrameEquip2[i], tbEquipStrengthInfo.nBoxLevel == tbEquipStrengthInfo.nBoxMaxLevel)
            else
                UIHelper.SetVisible(self.tbImgMaxFrameEquip2[i], false)
            end
        else
            UIHelper.SetVisible(self.tbImgMaxFrameEquip2[i], false)
        end
	end

    for i, nType in ipairs(WeaponEnum) do
        local nPrefabID = PREFAB_ID.WidgetItem_100
        if nType == EQUIPMENT_INVENTORY.ARROW then
            nPrefabID = PREFAB_ID.WidgetItem_80
        end
        UIHelper.RemoveAllChildren(self.tbWidgetWeapon[i])
        self.tbWeaponCell[nType] = UIHelper.AddPrefab(nPrefabID, self.tbWidgetWeapon[i])
        self.tbWeaponCell[nType]:SetPlayerID(self.nPlayerID)
        self.tbWeaponCell[nType]:OnInit(INVENTORY_INDEX.EQUIP, nType)
        self.tbWeaponCell[nType]:UpdatePVPImg()
        if nType ~= EQUIPMENT_INVENTORY.ARROW then
            self.tbWeaponCell[nType]:SetLabelCountVisible(false)
        end
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupEquip, self.tbWeaponCell[nType].ToggleSelect)
        self.tbWeaponCell[nType]:SetClickCallback(function(nBox, nIndex)
            if not self.scriptItemTip then
                self.scriptItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemCard)
                self.scriptItemTip:SetForbidShowEquipCompareBtn(true)
                self.scriptItemTip:SetPlayerID(self.nPlayerID)
            end
            if not self.scriptSelfItemTip then
                self.scriptSelfItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemSelfCard)
                self.scriptSelfItemTip:SetForbidShowEquipCompareBtn(true)
            end

            if nBox and nIndex then
                self.nCurSelectedEquipType = nType
            end

            if self.nCurSelectedEquipType == nType then
                self.scriptItemTip:OnInit(nBox, nIndex)
                if nType ~= EQUIPMENT_INVENTORY.ARROW and nType ~= EQUIPMENT_INVENTORY.RANGE_WEAPON then
                    self.scriptItemTip:SetBtnState({{
                        szName = "角色试穿",
                        OnClick = function ()
                            OutFitPreviewData.tbCurPreview = {}
                            local Item = ItemData.GetPlayerItem(player, nBox, nIndex)
                            table.insert(OutFitPreviewData.tbCurPreview ,OutFitPreviewData.PandentItemType[3][nType], {["nType"] = OutFitPreviewData.PreviewType.EquipWeapon, ["nTabType"] = Item.dwTabType, ["dwIndex"] = Item.dwIndex})

                            Event.Dispatch("ON_HIDEMINISCENE_UNTILNEWVIEWCLOSE")
                            UIMgr.Open(VIEW_ID.PanelOutfitPreview, player.dwID, OutFitPreviewData.tbCurPreview)
                        end
                    }})
                else
                    self.scriptItemTip:SetBtnState({})
                end

                self.scriptSelfItemTip:ShowCompareEquipTip(true)
                self.scriptSelfItemTip:OnInit(nBox, nIndex)

            end

            if not ItemData.GetItemByPos(nBox, nIndex) then
                Event.Dispatch(EventType.OnShowCharacterChangeEquipList, nBox, nIndex)
            end
        end)

        local item = ItemData.GetItemByPos(INVENTORY_INDEX.EQUIP, nType)
        if item then
            local tbEquipStrengthInfo = EquipData.GetEquipStrengthInfo(player, item, true, nType)
            if tbEquipStrengthInfo and tbEquipStrengthInfo.nEquipMaxLevel > 0 then
                UIHelper.SetVisible(self.tbImgMaxFrameWeapon[i], tbEquipStrengthInfo.nBoxLevel >= tbEquipStrengthInfo.nEquipMaxLevel)
            elseif tbEquipStrengthInfo and tbEquipStrengthInfo.nBoxMaxLevel and tbEquipStrengthInfo.nBoxMaxLevel > 0 then
                UIHelper.SetVisible(self.tbImgMaxFrameWeapon[i], tbEquipStrengthInfo.nBoxLevel == tbEquipStrengthInfo.nBoxMaxLevel)
            else
                UIHelper.SetVisible(self.tbImgMaxFrameWeapon[i], false)
            end
        else
            UIHelper.SetVisible(self.tbImgMaxFrameWeapon[i], false)
        end
	end

    UIHelper.SetVisible(self.WidgetWeaponSecondary, player.bCanUseBigSword)

    UIHelper.LayoutDoLayout(self.LayoutWeapon)

    self:ClearSelect()
end

function UIOtherCharacterEquipPage:ClearSelect()
    for _, nType1 in pairs(Equip1Enum) do
        self.tbEquipCell[nType1]:SetSelected(false)
    end

    for _, nType1 in pairs(Equip2Enum) do
        self.tbEquipCell[nType1]:SetSelected(false)
    end

    for _, nType1 in pairs(WeaponEnum) do
        self.tbWeaponCell[nType1]:SetSelected(false)
    end

    if self.scriptItemTip then
        self.scriptItemTip:OnInit()
    end
    if self.scriptSelfItemTip then
        self.scriptSelfItemTip:OnInit()
    end
end

function UIOtherCharacterEquipPage:GetPlayer()
    if self.nPlayerID then
        local player = GetPlayer(self.nPlayerID)
        return player
    end

    if self.szGlobalRoleID then
        local player = GetPlayerByGlobalID(self.szGlobalRoleID)
        return player
    end
end

function UIOtherCharacterEquipPage:UpdatePersonalCardInfo()
    local pPlayer = self:GetPlayer()
    local szGlobalID = self.szGlobalRoleID
    if not szGlobalID then
        if not pPlayer then
            return
        end
        szGlobalID = pPlayer.GetGlobalID()
    end

    if not GDAPI_CanPeekPersonalCard(szGlobalID) then
        UIHelper.SetVisible(self.WidgetAnchorLeft, false)
        return
    else
        UIHelper.SetVisible(self.WidgetAnchorLeft, true)
    end

    self.scriptPersonalCard = self.scriptPersonalCard or UIHelper.AddPrefab(PREFAB_ID.WidgetPersonalCard, self.WidgetPersonalCardShell, szGlobalID)
	self.scriptPersonalCard:SetPlayerId(self.nPlayerID)
    self.scriptPersonalCard:SetEquipNumVisible(false)
    UIHelper.SetAnchorPoint(self.scriptPersonalCard._rootNode, 0.5, 0.5)
end

return UIOtherCharacterEquipPage