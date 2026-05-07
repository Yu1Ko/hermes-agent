-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOtherCharacterExteriorPage
-- Date: 2023-03-07 19:57:30
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOtherCharacterExteriorPage = class("UIOtherCharacterExteriorPage")

local PendantType = {
    PENDENT_SELECTED_POS.LSHOULDER,
    PENDENT_SELECTED_POS.RSHOULDER,
    PENDENT_SELECTED_POS.HEAD,
    PENDENT_SELECTED_POS.FACE,
    PENDENT_SELECTED_POS.LGLOVE,
    PENDENT_SELECTED_POS.RGLOVE,
    PENDENT_SELECTED_POS.GLASSES,
    PENDENT_SELECTED_POS.BACKCLOAK,
    0,
    PENDENT_SELECTED_POS.BAG,
    PENDENT_SELECTED_POS.BACK,
    PENDENT_SELECTED_POS.WAIST,
    PENDENT_SELECTED_POS.HEAD1,
    PENDENT_SELECTED_POS.HEAD2,
}

local EquipType = {
    WEAPON_EXTERIOR_BOX_INDEX_TYPE.MELEE_WEAPON,
    EXTERIOR_INDEX_TYPE.HELM,
    EXTERIOR_INDEX_TYPE.CHEST,
    EXTERIOR_INDEX_TYPE.WAIST,
    EXTERIOR_INDEX_TYPE.BANGLE,
    EXTERIOR_INDEX_TYPE.BOOTS,
    EQUIPMENT_REPRESENT.HAIR_STYLE,
}

function UIOtherCharacterExteriorPage:OnEnter(nPlayerID, nCenterID, szGlobalRoleID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nPlayerID = nPlayerID
    self.nCenterID = nCenterID
    self.szGlobalRoleID = szGlobalRoleID
    self:UpdateInfo()
end

function UIOtherCharacterExteriorPage:OnExit()
    self.bInit = false
end

function UIOtherCharacterExteriorPage:BindUIEvent()
    UIHelper.BindUIEvent(self.TogGuaJian, EventType.OnClick, function()

    end)

    UIHelper.BindUIEvent(self.TogWaiZhuang, EventType.OnClick, function()

    end)

    UIHelper.ToggleGroupAddToggle(self.TogGroupPage, self.TogGuaJian)
    UIHelper.ToggleGroupAddToggle(self.TogGroupPage, self.TogWaiZhuang)

    UIHelper.BindUIEvent(self.BtnPreviewAll, EventType.OnClick, function()
        local player = self:GetPlayer()
        if not player then return end
        OutFitPreviewData.tbCurPreview = clone(self.tbOtherPlayerOutFit)
        Event.Dispatch("ON_HIDEMINISCENE_UNTILNEWVIEWCLOSE")
        UIMgr.Open(VIEW_ID.PanelOutfitPreview, player.dwID, OutFitPreviewData.tbCurPreview)
    end)
end

function UIOtherCharacterExteriorPage:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function()
        self:ClearSelect()
    end)
end

function UIOtherCharacterExteriorPage:UpdateInfo()
    self.tbOtherPlayerOutFit = {}
    self:UpdatePendantInfo()
    self:UpdateEquipInfo()
    self:UpdatePersonalCardInfo()
end

function UIOtherCharacterExteriorPage:UpdatePendantInfo()
    local player = self:GetPlayer()
    if not player then return end
    local nPetIndex = player.GetEquippedPendentPet()
    PendantType[9] = nPetIndex or 0

    self.tbScriptPandentItem = self.tbScriptPandentItem or {}
    for i, widgetItem in ipairs(self.tbPendantItemIcon) do
        self.tbScriptPandentItem[i] = self.tbScriptPandentItem[i] or UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, widgetItem)
        if i == 9 then
            -- 特判宠物
            if PendantType[i] > 0 then
                UIHelper.SetVisible(self.tbScriptPandentItem[i]._rootNode, true)
                self.tbScriptPandentItem[i]:OnInitWithTabID(ITEM_TABLE_TYPE.CUST_TRINKET, PendantType[i])
                self.tbScriptPandentItem[i]:SetLabelCountVisible(false)
                UIHelper.ToggleGroupAddToggle(self.ToggleGroupItem, self.tbScriptPandentItem[i].ToggleSelect)
                table.insert(self.tbOtherPlayerOutFit, OutFitPreviewData.PandentItemType[4][0], {["nType"] = OutFitPreviewData.PreviewType.Pandent, ["nTabType"] = ITEM_TABLE_TYPE.CUST_TRINKET, ["dwIndex"] = PendantType[i]})
                self.tbScriptPandentItem[i]:SetClickCallback(function(nBox, nIndex)
                    if not self.scriptItemTip then
                        self.scriptItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemCard)
                    end
                    if nBox and nIndex then
                        self.nCurSelectedIndex = i
                    end

                    if self.nCurSelectedIndex == i then
                        self.scriptItemTip:SetPlayerID(self.nPlayerID)
                        self.scriptItemTip:OnInitWithTabID(ITEM_TABLE_TYPE.CUST_TRINKET, PendantType[i])
                        self.scriptItemTip:SetBtnState({{
                            szName = "角色试穿",
                            OnClick = function ()
                                OutFitPreviewData.tbCurPreview = {}
                                local nIndex = player.GetEquippedPendentPet()
                                table.insert(OutFitPreviewData.tbCurPreview, OutFitPreviewData.PandentItemType[4][0], {["nType"] = OutFitPreviewData.PreviewType.Pandent, ["nTabType"] = ITEM_TABLE_TYPE.CUST_TRINKET, ["dwIndex"] = nIndex})
                                Event.Dispatch("ON_HIDEMINISCENE_UNTILNEWVIEWCLOSE")
                                UIMgr.Open(VIEW_ID.PanelOutfitPreview, player.dwID, OutFitPreviewData.tbCurPreview)
                            end
                        }})
                    end
                end)
            else
                UIHelper.SetVisible(self.tbScriptPandentItem[i]._rootNode, false)
            end
        elseif player.GetSelectPendent(PendantType[i]) ~= 0 then
            UIHelper.SetVisible(self.tbScriptPandentItem[i]._rootNode, true)
            self.tbScriptPandentItem[i]:OnInitWithTabID(ITEM_TABLE_TYPE.CUST_TRINKET, player.GetSelectPendent(PendantType[i]))
            self.tbScriptPandentItem[i]:SetLabelCountVisible(false)
            UIHelper.ToggleGroupAddToggle(self.ToggleGroupItem, self.tbScriptPandentItem[i].ToggleSelect)
            table.insert(self.tbOtherPlayerOutFit, OutFitPreviewData.PandentItemType[1][PendantType[i]], {["nType"] = OutFitPreviewData.PreviewType.Pandent, ["nTabType"] = ITEM_TABLE_TYPE.CUST_TRINKET, ["dwIndex"] = player.GetSelectPendent(PendantType[i])})
            self.tbScriptPandentItem[i]:SetClickCallback(function(nBox, nIndex)
                if not self.scriptItemTip then
                    self.scriptItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemCard)
                end
                if nBox and nIndex then
                    self.nCurSelectedIndex = i
                end

                if self.nCurSelectedIndex == i then
                    self.scriptItemTip:SetPlayerID(self.nPlayerID)
                    self.scriptItemTip:OnInitWithTabID(ITEM_TABLE_TYPE.CUST_TRINKET, player.GetSelectPendent(PendantType[i]))
                    self.scriptItemTip:SetBtnState({{
                        szName = "角色试穿",
                        OnClick = function ()
                            OutFitPreviewData.tbCurPreview = {}
                            local nIndex = player.GetSelectPendent(PendantType[i])
                            table.insert(OutFitPreviewData.tbCurPreview, OutFitPreviewData.PandentItemType[1][PendantType[i]], {["nType"] = OutFitPreviewData.PreviewType.Pandent, ["nTabType"] = ITEM_TABLE_TYPE.CUST_TRINKET, ["dwIndex"] = nIndex})
                            Event.Dispatch("ON_HIDEMINISCENE_UNTILNEWVIEWCLOSE")
                            UIMgr.Open(VIEW_ID.PanelOutfitPreview, player.dwID, OutFitPreviewData.tbCurPreview)
                        end
                    }})
                end
            end)
        else
            UIHelper.SetVisible(self.tbScriptPandentItem[i]._rootNode, false)
        end
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewAppearance)
    UIHelper.ScrollToTop(self.ScrollViewAppearance, 0)

    self:ClearSelect()
end

function UIOtherCharacterExteriorPage:UpdateEquipInfo()
    local player = self:GetPlayer()
    if not player then return end

    local hExteriorClient = GetExterior()
	if not hExteriorClient then
		return
	end

    local nCurrentSetID = player.GetCurrentSetID() or 0
	local tExteriorSet = player.GetExteriorSet(nCurrentSetID) or {}
	local tWeaponExterior = player.GetWeaponExteriorSet(nCurrentSetID) or {}

    UIHelper.SetVisible(self.WidgetEquipRank, true)
    UIHelper.SetString(self.LabelRankNum, PlayerData.GetPlayerTotalEquipScore(player))

    self.tbScriptEquipItem = self.tbScriptEquipItem or {}
    for i, widgetItem in ipairs(self.tbEquipItemIcon) do
        self.tbScriptEquipItem[i] = self.tbScriptEquipItem[i] or UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, widgetItem)
        if i == 1 then
            -- 特判武器
            local nWeaponSub = EquipType[i]
            local dwExteriorID = tWeaponExterior[nWeaponSub] or 0
            if dwExteriorID > 0 then
                self.tbScriptEquipItem[i]:OnInitWithTabID("WeaponExterior", dwExteriorID)
                self.tbScriptEquipItem[i]:SetLabelCountVisible(false)
                UIHelper.ToggleGroupAddToggle(self.ToggleGroupItem, self.tbScriptEquipItem[i].ToggleSelect)
                table.insert(self.tbOtherPlayerOutFit, OutFitPreviewData.PandentItemType[5][nWeaponSub], {["nType"] = OutFitPreviewData.PreviewType.ExteriorWeapon, ["dwWeaponID"] = dwExteriorID})
                self.tbScriptEquipItem[i]:SetClickCallback(function(nBox, nIndex)
                    if not self.scriptItemTip then
                        self.scriptItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemCard)
                    end
                    if nBox and nIndex then
                        self.nCurSelectedIndex = i
                    end

                    if self.nCurSelectedIndex == i then
                        self.scriptItemTip:SetPlayerID(self.nPlayerID)
                        self.scriptItemTip:OnInitWithTabID("WeaponExterior", dwExteriorID)
                        self.scriptItemTip:SetBtnState({{
                            szName = "角色试穿",
                            OnClick = function ()
                                OutFitPreviewData.tbCurPreview = {}
                                local nCurrentSetID = player.GetCurrentSetID() or 0
                                local tWeaponExterior = player.GetWeaponExteriorSet(nCurrentSetID) or {}
                                local dwWeaponID = tWeaponExterior[WEAPON_EXTERIOR_BOX_INDEX_TYPE.MELEE_WEAPON] or 0
                                table.insert(OutFitPreviewData.tbCurPreview, OutFitPreviewData.PandentItemType[5][nWeaponSub], {["nType"] = OutFitPreviewData.PreviewType.ExteriorWeapon, ["dwWeaponID"] = dwWeaponID})
                                Event.Dispatch("ON_HIDEMINISCENE_UNTILNEWVIEWCLOSE")
                                UIMgr.Open(VIEW_ID.PanelOutfitPreview, player.dwID, OutFitPreviewData.tbCurPreview)
                            end
                        }})
                    end
                end)
                UIHelper.SetVisible(self.tbScriptEquipItem[i]._rootNode, true)
            else
                UIHelper.SetVisible(self.tbScriptEquipItem[i]._rootNode, false)
            end
        elseif i == 7 then
            local tRepresentID = player.GetRepresentID()
            local nHairID = tRepresentID[EQUIPMENT_REPRESENT.HAIR_STYLE]
            if nHairID > 0 then
                self.tbScriptEquipItem[i]:OnInitWithIconID(10775, 2, 1)
                self.tbScriptEquipItem[i]:SetLabelCountVisible(false)
                UIHelper.ToggleGroupAddToggle(self.ToggleGroupItem, self.tbScriptEquipItem[i].ToggleSelect)
                table.insert(self.tbOtherPlayerOutFit, OutFitPreviewData.PandentItemType[6][EQUIPMENT_REPRESENT.HAIR_STYLE], {["nType"] = OutFitPreviewData.PreviewType.ExteriorHair, ["nHairID"] = nHairID})
                self.tbScriptEquipItem[i]:SetSelectChangeCallback(function(_, bSelected)
                    if not self.scriptItemTip then
                        self.scriptItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemCard)
                    end

                    if bSelected then
                        self.nCurSelectedIndex = i
                        local tbGoods = {}
                        tbGoods.eGoodsType = COIN_SHOP_GOODS_TYPE.HAIR
                        tbGoods.dwGoodsID = nHairID

                        self.scriptItemTip:SetPlayerID(self.nPlayerID)
                        self.scriptItemTip:OnInitWithCoinShopGoods(tbGoods)
                        self.scriptItemTip:SetBtnState({{
                            szName = "角色试穿",
                            OnClick = function ()
                                OutFitPreviewData.tbCurPreview = {}
                                table.insert(OutFitPreviewData.tbCurPreview, OutFitPreviewData.PandentItemType[6][EQUIPMENT_REPRESENT.HAIR_STYLE], {["nType"] = OutFitPreviewData.PreviewType.ExteriorHair, ["nHairID"] = nHairID})
                                Event.Dispatch("ON_HIDEMINISCENE_UNTILNEWVIEWCLOSE")
                                UIMgr.Open(VIEW_ID.PanelOutfitPreview, player.dwID, OutFitPreviewData.tbCurPreview)
                            end
                        }})
                    end
                end)
            else
                UIHelper.SetVisible(self.tbScriptEquipItem[i]._rootNode, false)
            end

        else
            local nExteriorSub = EquipType[i]
            local dwExteriorID = tExteriorSet[nExteriorSub] or 0
            if dwExteriorID > 0 then
                self.tbScriptEquipItem[i]:OnInitWithTabID("EquipExterior", dwExteriorID)
                self.tbScriptEquipItem[i]:SetLabelCountVisible(false)
                UIHelper.ToggleGroupAddToggle(self.ToggleGroupItem, self.tbScriptEquipItem[i].ToggleSelect)
                table.insert(self.tbOtherPlayerOutFit, OutFitPreviewData.PandentItemType[2][nExteriorSub], {["nType"] = OutFitPreviewData.PreviewType.ExteriorEquip, ["dwExteriorID"] = dwExteriorID})
                self.tbScriptEquipItem[i]:SetClickCallback(function(nBox, nIndex)
                    if not self.scriptItemTip then
                        self.scriptItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemCard)
                    end
                    if nBox and nIndex then
                        self.nCurSelectedIndex = i
                    end

                    if self.nCurSelectedIndex == i then
                        self.scriptItemTip:SetPlayerID(self.nPlayerID)
                        self.scriptItemTip:OnInitWithTabID("EquipExterior", dwExteriorID)
                        self.scriptItemTip:SetBtnState({{
                            szName = "角色试穿",
                            OnClick = function ()
                                OutFitPreviewData.tbCurPreview = {}
                                table.insert(OutFitPreviewData.tbCurPreview,OutFitPreviewData.PandentItemType[2][nExteriorSub], {["nType"] = OutFitPreviewData.PreviewType.ExteriorEquip, ["dwExteriorID"] = dwExteriorID})
                                Event.Dispatch("ON_HIDEMINISCENE_UNTILNEWVIEWCLOSE")
                                UIMgr.Open(VIEW_ID.PanelOutfitPreview, player.dwID, OutFitPreviewData.tbCurPreview)
                            end
                        }})
                    end
                end)
                UIHelper.SetVisible(self.tbScriptEquipItem[i]._rootNode, true)
            else
                UIHelper.SetVisible(self.tbScriptEquipItem[i]._rootNode, false)
            end
        end
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewEquip)
    UIHelper.ScrollToTop(self.ScrollViewEquip, 0)
    self:ClearSelect()
end

function UIOtherCharacterExteriorPage:ClearSelect()
    for _, scriptItem in pairs(self.tbScriptPandentItem or {}) do
        scriptItem:SetSelected(false)
    end

    for _, scriptItem in pairs(self.tbScriptEquipItem or {}) do
        scriptItem:SetSelected(false)
    end

    if self.scriptItemTip then
        self.scriptItemTip:OnInit()
    end
end

function UIOtherCharacterExteriorPage:GetPlayer()
    if self.nPlayerID then
        local player = GetPlayer(self.nPlayerID)
        return player
    end

    if self.szGlobalRoleID then
        local player = GetPlayerByGlobalID(self.szGlobalRoleID)
        return player
    end
end

function UIOtherCharacterExteriorPage:UpdatePersonalCardInfo()
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

return UIOtherCharacterExteriorPage