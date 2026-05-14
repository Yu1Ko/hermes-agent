-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopPreviewBox
-- Date: 2022-12-30 14:32:44
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICoinShopPreviewBox = class("UICoinShopPreviewBox")

function UICoinShopPreviewBox:OnEnter()
    self.tbRoleBoxes = {
        [COINSHOP_BOX_INDEX.FACE]               = { rootNode = self.TogHead01, szGroupType = "Head", szIndex="01" },

        [COINSHOP_BOX_INDEX.HAIR]               = { rootNode = self.TogHead02, szGroupType = "Dress", szIndex="02", szLink="1/0" },
        [COINSHOP_BOX_INDEX.BACK_CLOAK_EXTEND]  = { rootNode = self.TogDress01, szGroupType = "Dress", szIndex="01", szLink="6/3" },
        [COINSHOP_BOX_INDEX.CHEST]              = { rootNode = self.TogDress02, szGroupType = "Dress", szIndex="02", szLink="3/1" },
        [COINSHOP_BOX_INDEX.HELM]               = { rootNode = self.TogDress03, szGroupType = "Dress", szIndex="03", szLink="3/2" },
        [COINSHOP_BOX_INDEX.WAIST]              = { rootNode = self.TogDress04, szGroupType = "Dress", szIndex="04", szLink="3/2" },
        [COINSHOP_BOX_INDEX.BANGLE]             = { rootNode = self.TogDress05, szGroupType = "Dress", szIndex="05", szLink="3/2" },
        [COINSHOP_BOX_INDEX.BOOTS]              = { rootNode = self.TogDress06, szGroupType = "Dress", szIndex="06", szLink="3/2" },
        [COINSHOP_BOX_INDEX.IDLE_ACTION]        = { rootNode = self.TogDress07, szGroupType = "Dress", szIndex="07", szLink="10/0"},

        [COINSHOP_BOX_INDEX.PENDANT_PET]        = { rootNode = self.TogAccessory01, szGroupType = "Accessory", szIndex="01", szLink="6/60" },
        [COINSHOP_BOX_INDEX.BAG_EXTEND]         = { rootNode = self.TogAccessory02, szGroupType = "Accessory", szIndex="02", szLink="6/12"},
        [COINSHOP_BOX_INDEX.FACE_EXTEND]        = { rootNode = self.TogAccessory03, szGroupType = "Accessory", szIndex="03", szLink="6/4" },
        [COINSHOP_BOX_INDEX.GLASSES_EXTEND]     = { rootNode = self.TogAccessory04, szGroupType = "Accessory", szIndex="04", szLink="6/62" },
        [COINSHOP_BOX_INDEX.WAIST_EXTEND]       = { rootNode = self.TogAccessory05, szGroupType = "Accessory", szIndex="05", szLink="6/6" },
        [COINSHOP_BOX_INDEX.BACK_EXTEND]        = { rootNode = self.TogAccessory06, szGroupType = "Accessory", szIndex="06", szLink="6/5" },
        [COINSHOP_BOX_INDEX.L_SHOULDER_EXTEND]  = { rootNode = self.TogAccessory07, szGroupType = "Accessory", szIndex="07", szLink="6/8" },
        [COINSHOP_BOX_INDEX.R_SHOULDER_EXTEND]  = { rootNode = self.TogAccessory08, szGroupType = "Accessory", szIndex="08", szLink="6/9" },
        [COINSHOP_BOX_INDEX.L_GLOVE_EXTEND]     = { rootNode = self.TogAccessory09, szGroupType = "Accessory", szIndex="09", szLink="6/63" },
        [COINSHOP_BOX_INDEX.R_GLOVE_EXTEND]     = { rootNode = self.TogAccessory10, szGroupType = "Accessory", szIndex="10", szLink="6/64" },
        [COINSHOP_BOX_INDEX.HEAD_EXTEND]        = { rootNode = self.TogAccessory11, szGroupType = "Accessory", szIndex="11", szLink="6/65"},
        [COINSHOP_BOX_INDEX.HEAD_EXTEND1]       = { rootNode = self.TogAccessory11_2, szGroupType = "Accessory", szIndex="11_2", szLink="6/65"},
        [COINSHOP_BOX_INDEX.HEAD_EXTEND2]       = { rootNode = self.TogAccessory11_3, szGroupType = "Accessory", szIndex="11_3", szLink="6/65"},

        [COINSHOP_BOX_INDEX.WEAPON]             = { rootNode = self.TogWeapon, szGroupType = "Weapon", szIndex="01", szLink="7/0"},
        [COINSHOP_BOX_INDEX.BIG_SWORD]          = { rootNode = self.TogWeapon2, szGroupType = "Weapon", szIndex="01", szLink="7/0"},
        [COINSHOP_BOX_INDEX.ITEM]               = { rootNode = self.TogProp01, szGroupType = "Prop", szIndex="01"},
        -- [COINSHOP_BOX_INDEX.EFFECT_SFX]         = {
        --     [PLAYER_SFX_REPRESENT.FOOTPRINT] = { rootNode = self.TogFootPrint, szIndex="01", szLink = "6/66", nFilter = 1},
        --     [PLAYER_SFX_REPRESENT.SURROUND_BODY] = { rootNode = self.TogBodyRound, szIndex="02", szLink = "6/66", nFilter = 2},
        --     [PLAYER_SFX_REPRESENT.LEFT_HAND] = { rootNode = self.TogLHand, szIndex="03", szLink = "6/66", nFilter = 3},
        --     [PLAYER_SFX_REPRESENT.RIGHT_HAND] = { rootNode = self.TogRHand, szIndex="04",szLink = "6/66", nFilter = 4},
        -- }
    }
    self.tbRideBoxes = {
        [COINSHOP_RIDE_BOX_INDEX.HORSE]                 = { rootNode = self.TogSaddleHorse01, szGroupType = "SaddleHorse", szIndex="01", szLink="6/50"},
        [COINSHOP_RIDE_BOX_INDEX.HEAD_HORSE_EQUIP]      = { rootNode = self.TogSaddleHorse02, szGroupType = "SaddleHorse", szIndex="02", szLink="6/52"},
        [COINSHOP_RIDE_BOX_INDEX.CHEST_HORSE_EQUIP]     = { rootNode = self.TogSaddleHorse03, szGroupType = "SaddleHorse", szIndex="03", szLink="6/52"},
        [COINSHOP_RIDE_BOX_INDEX.FOOT_HORSE_EQUIP]      = { rootNode = self.TogSaddleHorse04, szGroupType = "SaddleHorse", szIndex="04", szLink="6/52"},
        [COINSHOP_RIDE_BOX_INDEX.HANG_ITEM_HORSE_EQUIP] = { rootNode = self.TogSaddleHorse05, szGroupType = "SaddleHorse", szIndex="05", szLink="6/52"},
        [COINSHOP_RIDE_BOX_INDEX.ITEM]                  = { rootNode = self.TogHorseProp01, szGroupType = "SaddleHorse", szIndex="01"},
    }
    UIHelper.SetVisible(self.ScrollViewHorseProp, false)

    self.tbFurnitureBox = { rootNode = self.TogFurniture }
    UIHelper.SetSelected(self.tbFurnitureBox.rootNode, false, false)

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    local hPlayer = GetClientPlayer()
    UIHelper.SetVisible(self.TogWeapon2, hPlayer and hPlayer.dwForceID == FORCE_TYPE.CANG_JIAN)
    UIHelper.SetVisible(self.tbRoleBoxes[COINSHOP_BOX_INDEX.IDLE_ACTION].rootNode, IsDebugClient() or UI_IsActivityOn(ACTIVITY_ID.ACTION))

    self:UpdateInfo()
end

function UICoinShopPreviewBox:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UICoinShopPreviewBox:BindUIEvent()
    for nIndex, tbPreviewBox in pairs(self.tbRoleBoxes) do
        if nIndex == COINSHOP_BOX_INDEX.EFFECT_SFX then
            for nType, tbBox in pairs(tbPreviewBox) do
                UIHelper.BindUIEvent(tbBox.rootNode, EventType.OnSelectChanged, function (_, bSelected)
                    if bSelected then
                        if self.tbSelectedEffectTog and not self.tbSelectedEffectTog.itemIcon then
                            UIHelper.SetVisible(self.tbSelectedEffectTog.ImgSelect, false)
                        end
                        self.tbSelectedEffectTog = tbBox
                    end
                    local bVisible = (tbBox.itemIcon ~= nil) or bSelected
                    UIHelper.SetVisible(tbBox.ImgSelect, bVisible)
                    if bVisible and tbBox.szLink then
                        if FilterDef.CoinShopWardrobeEffect.GetRunTime() == nil then
                            local tbRuntime = { [1] = {tbBox.nFilter},}
                            FilterDef.CoinShopWardrobeEffect.SetRunTime(tbRuntime)
                        end
                        local tbFilterDefSelected = FilterDef.CoinShopWardrobeEffect.tbRuntime
                        tbFilterDefSelected[1][1] = tbBox.nFilter
                        Event.Dispatch(EventType.OnCoinShopPreviewBoxLinkTitle, tbBox.szLink)
                    end
                end)
            end
        else
            UIHelper.BindUIEvent(tbPreviewBox.rootNode, EventType.OnSelectChanged, function (_, bSelected)
                if bSelected and tbPreviewBox.szLink then
                    Event.Dispatch(EventType.OnCoinShopPreviewBoxLinkTitle, tbPreviewBox.szLink)
                end
            end)
        end

    end

    for _, tbPreviewBox in pairs(self.tbRideBoxes) do
        UIHelper.BindUIEvent(tbPreviewBox.rootNode, EventType.OnSelectChanged, function (_, bSelected)
            if bSelected and tbPreviewBox.szLink then
                Event.Dispatch(EventType.OnCoinShopPreviewBoxLinkTitle, tbPreviewBox.szLink)
            end
        end)
    end
end

function UICoinShopPreviewBox:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function ()
        self:ClearSelect()
    end)

    Event.Reg(self, "COINSHOPVIEW_ROLE_DATA_UPDATE", function ()
        self:OnRoleViewDataUpdate()
    end)

    Event.Reg(self, "COINSHOPVIEW_RIDE_DATA_UPDATE", function ()
        self:OnRideViewDataUpdate()
    end)

    Event.Reg(self, "COINSHOPVIEW_PET_DATA_UPDATE", function ()
        self:OnPetViewDataUpdate()
    end)

    Event.Reg(self, "COINSHOPVIEW_FURNITURE_DATA_UPDATE", function ()
        self:OnFurnitureViewDataUpdate()
    end)

    Event.Reg(self, "COINSHOP_SHOW_VIEW", function (szViewPage, bShowWeapon)
        szViewPage = szViewPage or "Role"
        if szViewPage == self.m_szViewPage then
            return
        end
        if szViewPage == "Role" then
            self:OnRoleViewDataUpdate()
        elseif szViewPage == "Ride" then
            self:OnRideViewDataUpdate()
        elseif szViewPage == "Pet" then
            self:OnPetViewDataUpdate()
        elseif szViewPage == "Furniture" then
            self:OnFurnitureViewDataUpdate()
        end
    end)

    Event.Reg(self, "PREVIEW_HAIR", function(nHairID, _, _, _, bMultiPreview)
        if bMultiPreview then
            return
        end
        local tRepresentID = g_pClientPlayer.GetRepresentID()
        if nHairID == tRepresentID[EQUIPMENT_REPRESENT.HAIR_STYLE] then
            return
        end
        UIHelper.SetSelected(self.TogRightTab02, true)
    end)

    Event.Reg(self, "ON_PREVIEW_HAIR", function(nHairID, _, _, _)
        local tRepresentID = g_pClientPlayer.GetRepresentID()
        if nHairID == tRepresentID[EQUIPMENT_REPRESENT.HAIR_STYLE] then
            return
        end
        UIHelper.SetSelected(self.TogRightTab02, true)
    end)

    Event.Reg(self, "PREVIEW_SET", function()
        UIHelper.SetSelected(self.TogRightTab02, true)
    end)

    Event.Reg(self, "PREVIEW_SUB", function(_, _, _, bMultiPreview)
        if bMultiPreview then
            return
        end
        UIHelper.SetSelected(self.TogRightTab02, true)
    end)

    Event.Reg(self, "ON_ACTION_CHANGED", function(bMultiPreview)
        if bMultiPreview then
            return
        end
        local hPlayer = GetClientPlayer()
        if not hPlayer then
            return
        end
        local nLogicAniID = ExteriorCharacter.GetPreviewAniID()
        local nResetAniID = hPlayer.GetDisplayIdleAction(PLAYER_IDLE_ACTION_DISPLAY_TYPE.COIN_SHOP)
        if nResetAniID == nLogicAniID then
            return
        end
        UIHelper.SetSelected(self.TogRightTab02, true)
    end)

    Event.Reg(self, "PREVIEW_PENDANT", function(tItem, bLimitItem, bMultiPreview)
        if not tItem or not tItem.dwTabType or not tItem.dwIndex then
            return
        end
        local tItemInfo = GetItemInfo(tItem.dwTabType, tItem.dwIndex)
        if bLimitItem and not bMultiPreview then
            tItemInfo = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, tItemInfo.nDetail)
        end
        if tItemInfo.nSub == EQUIPMENT_SUB.FACE_EXTEND then
            if not ExteriorCharacter.IsInitRole() and g_pClientPlayer then
                g_pClientPlayer.SetFacePendentHideFlag(false)
            end
        end
        if bMultiPreview then
            return
        end
        local nRepresentSub = ExteriorView_GetRepresentSub(tItemInfo.nSub, tItemInfo.nDetail)
        local nIndex = Exterior_RepresentToBoxIndex(nRepresentSub)
        if nIndex == COINSHOP_BOX_INDEX.BACK_CLOAK_EXTEND then
            UIHelper.SetSelected(self.TogRightTab01, true)
        else
            UIHelper.SetSelected(self.TogRightTab03, true)
            CoinShopPreview.LocatePreviewItem(self.ScrollViewAccessory, self.tbRoleBoxes[nIndex].rootNode)
        end
    end)

    Event.Reg(self, "PREVIEW_PENDANT_PET", function (_, _, bMultiPreview)
        if bMultiPreview then
            return
        end
        UIHelper.SetSelected(self.TogRightTab03, true)
    end)

    Event.Reg(self, "PREVIEW_WEAPON", function ()
        UIHelper.SetSelected(self.TogRightTab04, true)
    end)

    Event.Reg(self, "PREVIEW_ITEM", function ()
        UIHelper.SetSelected(self.TogRightTab05, true)
    end)

    -- Event.Reg(self, "PREVIEW_PENDANT_EFFECT_SFX", function()
        -- UIHelper.SetSelected(self.TogRightTab06, true)
    -- end)

    Event.Reg(self, "PREVIEW_HORSE_ITEM", function()
        UIHelper.SetSelected(self.TogHorseRightTab02, true)
    end)

    Event.Reg(self, "PREVIEW_HORSE", function()
        UIHelper.SetSelected(self.TogHorseRightTab01, true)
    end)

    Event.Reg(self, "PREVIEW_HORSE_ADORNMENT", function()
        UIHelper.SetSelected(self.TogHorseRightTab01, true)
    end)

    Event.Reg(self, "WEAPON_EXTERIOR_COLLECT_RESULT", function ()
        if arg1 == EXTERIOR_COLLECT_RESULT_CODE.SUCCESS then
            self:OnRoleViewDataUpdate()
        end
    end)

    Event.Reg(self, "EXTERIOR_COLLECT_RESULT", function ()
        if arg1 == EXTERIOR_COLLECT_RESULT_CODE.SUCCESS then
            self:OnRoleViewDataUpdate()
        end
    end)

    Event.Reg(self, "COIN_SHOP_BUY_RESPOND", function()
        self:UpdateViewData(self.m_szViewPage)
    end)
end

function UICoinShopPreviewBox:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopPreviewBox:UpdateInfo()
    if not self.m_szViewPage then
        local szViewPage = ExteriorCharacter.GetLogicPage()
        self:UpdateViewData(szViewPage)
    end
    UIHelper.SetSelected(self.TogRightTab02, true)

    Timer.AddFrame(self, 1, function()
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewAccessory)
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewDress)
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewProp)
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollSpecialEffect)
    end)
end

function UICoinShopPreviewBox:UpdateViewData(szViewPage)
    if szViewPage == "Role" then
        self:OnRoleViewDataUpdate()
    elseif szViewPage == "Ride" then
        self:OnRideViewDataUpdate()
    elseif szViewPage == "Pet" then
        self:OnPetViewDataUpdate()
    elseif szViewPage == "Furniture" then
        self:OnFurnitureViewDataUpdate()
    end
end

function UICoinShopPreviewBox:OnRoleViewDataUpdate()
    self.m_szViewPage = "Role"
    UIHelper.SetVisible(self.WidgetAnchorPetRight, self.m_szViewPage == "Pet")
    UIHelper.SetVisible(self.WidgetAnchorRight, self.m_szViewPage == "Role")
    UIHelper.SetVisible(self.WidgetAnchorFurnitureRight, self.m_szViewPage == "Furniture")
    UIHelper.SetVisible(self.WidgetAnchorSaddleHorseRight, self.m_szViewPage == "Ride")

    -- UIHelper.ScrollViewDoLayout(self.ScrollViewAccessory)
    -- UIHelper.ScrollToTop(self.ScrollViewAccessory, 0)
    self.bShowHairInPack = false
    self.bShowHairNoInPack = false
    self.bShowPendantInPack = false
    self.bShowPendantNotInPack = false
    self.bShowExteriorInPack = false
    self.bShowExteriorNotInPack = false

    local tRoleData = ExteriorCharacter.GetRoleData()
    local tWeaponBox = CoinShop_GetWeaponIndexArray()
    for nIndex, tData in pairs(tRoleData) do
        --UpdateInteraction(hWndInteraction, nIndex, tData.tItem)
        local nSub = Exterior_BoxIndexToExteriorSub(nIndex)
        if nSub then
            local nExterior = 0
            if not tData.bInit then
                nExterior = tData.nExterior
            end
            self:UpdateExteriorSubBox(nIndex, tData.dwID, tData.tItem, nExterior)
        elseif nIndex == COINSHOP_BOX_INDEX.ITEM then
            self:UpdateItemSubBox(nIndex, tData.tItem)
        elseif nIndex == COINSHOP_BOX_INDEX.HAIR then
            self:UpdateHairStyleBox(nIndex, tData.nHairID, tData.tItem, tData.nExterior)
        -- elseif nIndex == COINSHOP_BOX_INDEX.FACE then
        --     UpdateFaceStyleBox(hFrame, tData.nFaceID, tData.bUseLiftedFace, tData.UserData, tData.bModify)
        elseif nIndex == COINSHOP_BOX_INDEX.PENDANT_PET then
            self:UpdatePendantSubBox(nIndex, tData.tItem)
        elseif nIndex == COINSHOP_BOX_INDEX.EFFECT_SFX then
            self:UpdateEffectSfxSubBox(nIndex, tData)
        elseif CoinShop_BoxIndexToPendantType(nIndex) then
            self:UpdatePendantSubBox(nIndex, tData.tItem)
        elseif tWeaponBox[nIndex] then
            self:UpdateWeaponSubBox(nIndex, tData.dwID)
        end
    end
    self:UpdateActionSubBox()

    local imgBoxExterior = UIHelper.GetChildByName(self.TogRightTab02, "ImgBox")
    if self.bShowExteriorInPack or self.bShowHairInPack then
        UIHelper.SetSpriteFrame(imgBoxExterior, "UIAtlas2_Shopping_ShoppingIcon_Icon_Box1.png")
        UIHelper.SetVisible(imgBoxExterior, true)
    elseif self.bShowExteriorNotInPack or self.bShowHairNoInPack then
        UIHelper.SetSpriteFrame(imgBoxExterior, "UIAtlas2_Shopping_ShoppingIcon_Icon_Box2.png")
        UIHelper.SetVisible(imgBoxExterior, true)
    else
        UIHelper.SetVisible(imgBoxExterior, false)
    end

    local imgBoxPendant = UIHelper.GetChildByName(self.TogRightTab03, "ImgBox")
    if self.bShowPendantInPack then
        UIHelper.SetSpriteFrame(imgBoxPendant, "UIAtlas2_Shopping_ShoppingIcon_Icon_Box1.png")
        UIHelper.SetVisible(imgBoxPendant, true)
    elseif self.bShowPendantNotInPack then
        UIHelper.SetSpriteFrame(imgBoxPendant, "UIAtlas2_Shopping_ShoppingIcon_Icon_Box2.png")
        UIHelper.SetVisible(imgBoxPendant, true)
    else
        UIHelper.SetVisible(imgBoxPendant, false)
    end
end

function UICoinShopPreviewBox:UpdateExteriorSubBox(nIndex, dwExteriorID, tItem, dwViewExteriorID)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local hExteriorClient = GetExterior()
    if not hExteriorClient then
        return
    end
    local tbPreviewBox = self.tbRoleBoxes[nIndex]
    local widgetProp = tbPreviewBox.rootNode:getChildByName("WidgetPropBox" .. tbPreviewBox.szIndex)
    UIHelper.SetSwallowTouches(tbPreviewBox.rootNode, false)

    local imgNotCollect = tbPreviewBox.rootNode:getChildByName("ImgNotCollected" .. tbPreviewBox.szIndex)
    UIHelper.SetVisible(imgNotCollect, false)
    local labelNotCollect = UIHelper.GetChildByName(imgNotCollect, "LabelDressNotCollected" .. tbPreviewBox.szIndex)
    local labelTime = UIHelper.GetChildByName(imgNotCollect, "LabelTime")
    UIHelper.SetVisible(labelNotCollect, false)
    UIHelper.SetVisible(labelTime, false)

    local btnChange = UIHelper.GetChildByName(tbPreviewBox.rootNode, "TogChange")
    UIHelper.SetVisible(btnChange, false)
    UIHelper.UnBindUIEvent(btnChange, EventType.OnClick)

    local imgBox = UIHelper.GetChildByName(tbPreviewBox.rootNode, "ImgBox")
    UIHelper.SetVisible(imgBox, false)

    if dwExteriorID <= 0 and dwViewExteriorID and dwViewExteriorID > 0 then
        dwExteriorID = dwViewExteriorID
        if not IsTableEmpty(Table_GetExteriorToItemList(dwViewExteriorID, COIN_SHOP_GOODS_TYPE.EXTERIOR)) then
            UIHelper.SetVisible(imgBox, true)
            local bInPack = CoinShop_IsInViewPack(dwViewExteriorID)
            if bInPack then
                UIHelper.SetSpriteFrame(imgBox, "UIAtlas2_Shopping_ShoppingIcon_Icon_Box1.png")
                self.bShowExteriorInPack = true
            else
                UIHelper.SetSpriteFrame(imgBox, "UIAtlas2_Shopping_ShoppingIcon_Icon_Box2.png")
                self.bShowExteriorNotInPack = true
            end
        end
    end

    if dwExteriorID > 0 then
        local tExteriorInfo = hExteriorClient.GetExteriorInfo(dwExteriorID)
        local bIsInShop = tExteriorInfo.bIsInShop
        local bCollect, nGold = CoinShop_GetCollectInfo(COIN_SHOP_GOODS_TYPE.EXTERIOR, dwExteriorID)
        if not bIsInShop and not bCollect then
            UIHelper.SetVisible(imgNotCollect, true)
            UIHelper.SetVisible(labelNotCollect, true)
        end

        if not tbPreviewBox.itemIcon then
            tbPreviewBox.itemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, widgetProp)
            tbPreviewBox.itemIcon:SetToggleSwallowTouches(false)
            -- UIHelper.SetAnchorPoint(tbPreviewBox.itemIcon._rootNode , 0.5, 1)
            UIHelper.ToggleGroupAddToggle(self._rootNode, tbPreviewBox.itemIcon.ToggleSelect)
        end
        tbPreviewBox.itemIcon:OnInitWithTabID("EquipExterior", dwExteriorID)
        tbPreviewBox.itemIcon:SetRecallVisible(true)
        tbPreviewBox.itemIcon:SetRecallCallback(function ()
            FireUIEvent("CANCEL_PREVIEW_SUB", dwExteriorID, true, tItem, true)
        end)
        tbPreviewBox.itemIcon:SetClickCallback(function(nParam1, nParam2)
            if nParam1 and nParam2 then
                local tbGoods = {}
                if tItem then
                    tbGoods.eGoodsType = COIN_SHOP_GOODS_TYPE.ITEM
                    tbGoods.dwTabType = tItem.dwTabType
                    tbGoods.dwTabIndex = tItem.dwIndex
                    tbGoods.dwGoodsID = tItem.dwLogicID
                else
                    tbGoods.eGoodsType = COIN_SHOP_GOODS_TYPE.EXTERIOR
                    tbGoods.dwGoodsID = dwExteriorID
                end
                Event.Dispatch(EventType.OnCoinShopShowItemTips, tbGoods)
            end
        end)
        UIHelper.SetVisible(widgetProp, true)

        local nTimeType, nTime = hPlayer.GetExteriorTimeLimitInfo(dwExteriorID)
        local szHaveTime = ""
        if nTimeType and nTimeType ~= COIN_SHOP_TIME_LIMIT_TYPE.PERMANENT then
            if nTimeType == COIN_SHOP_TIME_LIMIT_TYPE.FREE_TRY_ON then
                nTime =  GetCoinShopClient().GetFreeTryOnEndTime()
            end
            local nLeftTime = nTime - GetGSCurrentTime()
            if nLeftTime < 0 then
                nLeftTime = 0
            end
            szHaveTime = TimeLib.GetTimeText(nLeftTime, nil, true)
            UIHelper.SetVisible(imgNotCollect, true)
            UIHelper.SetVisible(labelTime, true)
            UIHelper.SetString(labelTime, szHaveTime)
        end
    else
        UIHelper.SetVisible(widgetProp, false)
    end
    tbPreviewBox.dwExteriorID = dwExteriorID
end

function UICoinShopPreviewBox:UpdateItemSubBox(nIndex, tItem)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local tbPreviewBox = self.tbRoleBoxes[nIndex]
    local widgetProp = tbPreviewBox.rootNode:getChildByName("WidgetPropBox" .. tbPreviewBox.szIndex)
    UIHelper.SetSwallowTouches(tbPreviewBox.rootNode, false)

    if tItem then
        if not tbPreviewBox.itemIcon then
            tbPreviewBox.itemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, widgetProp)
            tbPreviewBox.itemIcon:SetToggleSwallowTouches(false)
            -- UIHelper.SetAnchorPoint(tbPreviewBox.itemIcon._rootNode , 0.5, 1)
            UIHelper.ToggleGroupAddToggle(self._rootNode, tbPreviewBox.itemIcon.ToggleSelect)
        end

        local dwLogicID, dwTabType, dwIndex = tItem.dwLogicID, tItem.dwTabType, tItem.dwIndex
        tbPreviewBox.itemIcon:OnInitWithTabID(dwTabType, dwIndex)
        tbPreviewBox.itemIcon:SetRecallVisible(true)
        tbPreviewBox.itemIcon:SetRecallCallback(function ()
            ExteriorCharacter.CancelPreviewRewards(tItem, nil, true)
        end)
        tbPreviewBox.itemIcon:SetClickCallback(function(nParam1, nParam2)
            if nParam1 and nParam2 then
                local tbGoods = {
                    eGoodsType = COIN_SHOP_GOODS_TYPE.ITEM,
                    dwTabType = dwTabType,
                    dwTabIndex = dwIndex,
                    dwGoodsID = dwLogicID
                }
                Event.Dispatch(EventType.OnCoinShopShowItemTips, tbGoods)
            end
        end)
        UIHelper.SetVisible(widgetProp, true)
    else
        UIHelper.SetVisible(widgetProp, false)
    end

    self:UpdateItemSubBoxSubItems(nIndex, tItem)
end

function UICoinShopPreviewBox:UpdateSubItems(tItem, tItemScripts, scrollView)
    local tSubItems = {}
    if tItem and tItem.dwTabType and tItem.dwIndex then
        local hItemInfo = GetItemInfo(tItem.dwTabType, tItem.dwIndex)
        if hItemInfo.nGenre == ITEM_GENRE.COIN_SHOP_QUANTITY_LIMIT_ITEM and hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.PACK then
            local tPackList = CoinShop_GetAllLimitViewPack(hItemInfo.nDetail)
            if not IsTableEmpty(tPackList) then
                for _, tPackInfo in ipairs(tPackList) do
                    local tPackItem = GetItemInfo(ITEM_TABLE_TYPE.OTHER, tPackInfo.dwIndex)
                    local tSubItem = {
                        dwItemType = ITEM_TABLE_TYPE.OTHER,
                        dwItemID = tPackInfo.dwIndex,
                        bPack = true,
                        tItem = {
                            dwTabType = ITEM_TABLE_TYPE.OTHER,
                            dwIndex = tPackInfo.dwIndex,
                        },
                    }
                    table.insert(tSubItems, tSubItem)
                end
            else
                local tViewItems = CoinShop_GetAllLimitView(hItemInfo.nDetail)
                for _, tViewItem in ipairs(tViewItems) do
                    if tViewItem.dwItemType ~= 0 and tViewItem.dwItemID ~= 0 then
                        table.insert(tSubItems, tViewItem)
                    end
                end
            end
        end
    end
    local hPlayer = g_pClientPlayer
    if not hPlayer then
        return
    end
    local n = math.max(#tItemScripts, #tSubItems)
    for i = 1, n, 1 do
        tItemScripts[i] = tItemScripts[i] or UIHelper.AddPrefab(PREFAB_ID.WidgetExteriorPreviewItemCell, scrollView)
        tItemScripts[i]:OnInitWithCell(i)
        local subCell = tItemScripts[i]
        if i <= #tSubItems then
            local bPreview = false
            local bCanChange = false
            local bReplace = false
            local bDisable = false
            -- role item
            if tSubItems[i].nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.EXTERIOR then
                bPreview = ExteriorCharacter.IsSubMultiPreview(tSubItems[i].dwLogicID, tItem)
                bCanChange = tSubItems[i].nRepresentID and tSubItems[i].nRepresentID ~= 0
                bReplace = ExteriorCharacter.IsSubMultiReplace(tSubItems[i].dwLogicID, tItem)
            elseif tSubItems[i].nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.PENDENT then
                local tNewItem = {dwTabType = ITEM_TABLE_TYPE.CUST_TRINKET, dwIndex = tSubItems[i].dwLogicID}
                bPreview = ExteriorCharacter.IsPendantMultiPreview(tNewItem)
            elseif tSubItems[i].nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.HAIR then
                bPreview = ExteriorCharacter.IsHairMultiPreview(tSubItems[i].dwLogicID, tItem)
            elseif tSubItems[i].nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.PENDENT_PET then
                local tNewItem = {dwTabType = ITEM_TABLE_TYPE.CUST_TRINKET, dwIndex = tSubItems[i].dwLogicID}
                bPreview = ExteriorCharacter.IsPendantPetMultiPreview(tNewItem, false)
            elseif tSubItems[i].nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.IDLE_ACTION then
                local nLogicAniID, bMultiPreview = ExteriorCharacter.GetPreviewAniID()
                bPreview = bMultiPreview and nLogicAniID == tSubItems[i].dwLogicID
            elseif tSubItems[i].bPack then
                bPreview = ExteriorCharacter.IsRewardsPreview(tSubItems[i].tItem)

            end
            -- pet item
            if tSubItems[i].nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.FELLOW_PET then
                local tLine = Table_GetRewardsItem(tSubItems[i].dwLogicID)
                bPreview = ExteriorCharacter.IsPetMultiPreview(tLine.nPetIndex, tItem)
                bDisable = bPreview
            end
            UIHelper.SetSwallowTouches(subCell.TogPitchCell, true)
            UIHelper.SetSelected(subCell.TogPitchCell, bPreview, false)
            UIHelper.UnBindUIEvent(subCell.TogPitchCell, EventType.OnSelectChanged)
            UIHelper.BindUIEvent(subCell.TogPitchCell, EventType.OnSelectChanged, function (_, bSelected)
                local fnAction = function()
                    if not bSelected then
                        if tSubItems[i].bPack then
                            ExteriorCharacter.CancelPreviewRewards(tSubItems[i].tItem)
                        else
                            ExteriorCharacter.CancelPreviewRewards(tItem, {tSubItems[i]})
                        end
                    else
                        if tSubItems[i].bPack then
                            ExteriorCharacter.PreviewRewardsItem(tSubItems[i].tItem)
                        else
                            local tViewItem = clone(tSubItems[i])
                            if bCanChange and not bReplace then
                                tViewItem.nRepresentID = nil
                                tViewItem.nColorID = nil
                            end
                            ExteriorCharacter.PreviewRewardsItem(tItem, {tViewItem})
                        end
                    end
                end
                Timer.DelTimer(self.nPreviewRewardsTimerID)
                self.nPreviewRewardsTimerID = Timer.AddFrame(self, 1, function()
                    if bDisable then
                        UIHelper.SetSelected(subCell.TogPitchCell, not bSelected, false)
                    else
                        fnAction()
                    end
                end)
            end)

            UIHelper.SetVisible(subCell.TogChangeCell, bCanChange and bPreview)
            UIHelper.SetSelected(subCell.TogChangeCell, bReplace, false)
            UIHelper.UnBindUIEvent(subCell.TogChangeCell, EventType.OnSelectChanged)
            UIHelper.BindUIEvent(subCell.TogChangeCell, EventType.OnSelectChanged, function(_, bSelected)
                if bCanChange then
                    local tViewItem = clone(tSubItems[i])
                    if bReplace then
                        tViewItem.nRepresentID = nil
                        tViewItem.nColorID = nil
                    end
                    ExteriorCharacter.PreviewRewardsItem(tItem, {tViewItem})
                end
            end)

            subCell.ItemCellScript:OnInitWithTabID(tSubItems[i].dwItemType, tSubItems[i].dwItemID)
            subCell.ItemCellScript:SetToggleSwallowTouches(false)
            subCell.ItemCellScript:SetClickCallback(function(nParam1, nParam2)
                if nParam1 and nParam2 then
                    local tbGoods = {
                        dwTabType = tSubItems[i].dwItemType,
                        dwTabIndex = tSubItems[i].dwItemID,
                    }
                    Event.Dispatch(EventType.OnCoinShopShowItemTips, tbGoods)
                end
            end)
            UIHelper.SetVisible(subCell._rootNode, true)
        else
            UIHelper.SetVisible(subCell._rootNode, false)
        end
    end
end

function UICoinShopPreviewBox:UpdateItemSubBoxSubItems(nIndex, tItem)
    local tbPreviewBox = self.tbRoleBoxes[nIndex]

    self.tbTogSubItems = self.tbTogSubItems or {}
    self:UpdateSubItems(tItem, self.tbTogSubItems, self.ScrollViewProp)
    local bSame = self.tCacheItem and tItem and self.tCacheItem.dwTabType == tItem.dwTabType and self.tCacheItem.dwIndex == tItem.dwIndex
    if not bSame then
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewProp)
    end
    self.tCacheItem = tItem
end

function UICoinShopPreviewBox:UpdateHairStyleBox(nIndex, nHairID, tItem, dwViewExteriorID)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local tbPreviewBox = self.tbRoleBoxes[nIndex]
    local widgetProp = tbPreviewBox.rootNode:getChildByName("WidgetPropBox" .. tbPreviewBox.szIndex)
    UIHelper.SetSwallowTouches(tbPreviewBox.rootNode, false)

    local tRepresentID = hPlayer.GetRepresentID()
    local nResetHairID = tRepresentID[EQUIPMENT_REPRESENT.HAIR_STYLE]

    if not tbPreviewBox.itemIcon then
        tbPreviewBox.itemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, widgetProp)
        tbPreviewBox.itemIcon:SetToggleSwallowTouches(false)
        UIHelper.ToggleGroupAddToggle(self._rootNode, tbPreviewBox.itemIcon.ToggleSelect)
    end

    local btnChange = UIHelper.GetChildByName(tbPreviewBox.rootNode, "TogChange")
    UIHelper.SetVisible(btnChange, false)
    UIHelper.UnBindUIEvent(btnChange, EventType.OnClick)

    local imgBox = UIHelper.GetChildByName(tbPreviewBox.rootNode, "ImgBox")
    UIHelper.SetVisible(imgBox, false)

    if tItem then
        local dwLogicID, dwTabType, dwIndex = tItem.dwLogicID, tItem.dwTabType, tItem.dwIndex
        tbPreviewBox.itemIcon:OnInitWithTabID(dwTabType, dwIndex)
        tbPreviewBox.itemIcon:SetRecallVisible(true)
        tbPreviewBox.itemIcon:SetRecallCallback(function ()
            ExteriorCharacter.CancelPreviewRewards(tItem)
        end)
        tbPreviewBox.itemIcon:SetClickCallback(function(nParam1, nParam2)
            if nParam1 and nParam2 then
                local tbGoods = {
                    eGoodsType = COIN_SHOP_GOODS_TYPE.ITEM,
                    dwTabType = dwTabType,
                    dwTabIndex = dwIndex,
                    dwGoodsID = dwLogicID
                }
                Event.Dispatch(EventType.OnCoinShopShowItemTips, tbGoods)
            end
        end)
        UIHelper.SetVisible(widgetProp, true)
    else
        if dwViewExteriorID and dwViewExteriorID > 0 and dwViewExteriorID ~= nHairID then
            nHairID = dwViewExteriorID
            UIHelper.SetVisible(imgBox, true)
            local bInPack = CoinShop_IsInViewPack(dwViewExteriorID)
            if bInPack then
                UIHelper.SetSpriteFrame(imgBox, "UIAtlas2_Shopping_ShoppingIcon_Icon_Box1.png")
                self.bShowHairInPack = true
            else
                UIHelper.SetSpriteFrame(imgBox, "UIAtlas2_Shopping_ShoppingIcon_Icon_Box2.png")
                self.bShowHairNoInPack = true
            end
        end

        tbPreviewBox.itemIcon:OnInitWithIconID(10775, 2, 1)
        tbPreviewBox.itemIcon:SetSelectChangeCallback(function(_, bSelected)
            if bSelected then
                local tbGoods = {}
                tbGoods.eGoodsType = COIN_SHOP_GOODS_TYPE.HAIR
                tbGoods.dwGoodsID = nHairID
                Event.Dispatch(EventType.OnCoinShopShowItemTips, tbGoods)
            end
        end)
        tbPreviewBox.itemIcon:SetRecallVisible(nResetHairID ~= nHairID)
        tbPreviewBox.itemIcon:SetRecallCallback(function ()
            Event.Dispatch("RESET_HAIR")
        end)
        UIHelper.SetVisible(widgetProp, true)
    end
end

function UICoinShopPreviewBox:UpdateWeaponSubBox(nIndex, dwWeaponID)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local hExteriorClient = GetExterior()
    if not hExteriorClient then
        return
    end
    local tbPreviewBox = self.tbRoleBoxes[nIndex]
    if not tbPreviewBox then
        return
    end
    local widgetProp = tbPreviewBox.rootNode:getChildByName("WidgetPropBox" .. tbPreviewBox.szIndex)
    UIHelper.SetSwallowTouches(tbPreviewBox.rootNode, false)

    local imgNotCollect = tbPreviewBox.rootNode:getChildByName("ImgNotCollected" .. tbPreviewBox.szIndex)
    UIHelper.SetVisible(imgNotCollect, false)
    local labelNotCollect = UIHelper.GetChildByName(imgNotCollect, "LabelDressNotCollected" .. tbPreviewBox.szIndex)
    local labelTime = UIHelper.GetChildByName(imgNotCollect, "LabelTime")
    UIHelper.SetVisible(labelNotCollect, false)
    UIHelper.SetVisible(labelTime, false)

    local bHave = false
    local tExteriorInfo = CoinShop_GetWeaponExteriorInfo(dwWeaponID, hExteriorClient)
    if dwWeaponID > 0 then
        local nHaveType = GetCoinShopClient().CheckAlreadyHave(COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR, dwWeaponID)
        bHave = nHaveType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE
        local bCollect, nGold = CoinShop_GetCollectInfo(COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR, dwWeaponID)
        if not bCollect then
            UIHelper.SetVisible(imgNotCollect, true)
            UIHelper.SetVisible(labelNotCollect, true)
        end

        local tWeaponInfo = g_tTable.CoinShop_Weapon:Search(dwWeaponID)

        if not tbPreviewBox.itemIcon then
            tbPreviewBox.itemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, widgetProp)
            tbPreviewBox.itemIcon:SetToggleSwallowTouches(false)
            UIHelper.ToggleGroupAddToggle(self._rootNode, tbPreviewBox.itemIcon.ToggleSelect)
        end
        tbPreviewBox.itemIcon:OnInitWithTabID("WeaponExterior", dwWeaponID)
        tbPreviewBox.itemIcon:SetRecallVisible(true)
        tbPreviewBox.itemIcon:SetRecallCallback(function ()
            FireUIEvent("CANCEL_PREVIEW_WEAPON", dwWeaponID)
        end)
        tbPreviewBox.itemIcon:SetClickCallback(function(nParam1, nParam2)
            if nParam1 and nParam2 then
                local tbGoods = {
                    eGoodsType = COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR,
                    dwGoodsID = dwWeaponID
                }
                Event.Dispatch(EventType.OnCoinShopShowItemTips, tbGoods)
            end
        end)
        UIHelper.SetVisible(widgetProp, true)

        local nTimeType, nTime = hPlayer.GetWeaponExteriorTimeLimitInfo(dwWeaponID)
        local szHaveTime = ""
        if nTimeType and nTimeType ~= COIN_SHOP_TIME_LIMIT_TYPE.PERMANENT then
            if nTimeType == COIN_SHOP_TIME_LIMIT_TYPE.FREE_TRY_ON then
                nTime =  GetCoinShopClient().GetFreeTryOnEndTime()
            end
            local nLeftTime = nTime - GetGSCurrentTime()
            if nLeftTime < 0 then
                nLeftTime = 0
            end
            szHaveTime = TimeLib.GetTimeText(nLeftTime, nil, true)
            UIHelper.SetVisible(imgNotCollect, true)
            UIHelper.SetVisible(labelTime, true)
            UIHelper.SetString(labelTime, szHaveTime)
        end
    else
        UIHelper.SetVisible(widgetProp, false)
    end
end

function UICoinShopPreviewBox:UpdateActionSubBox()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local hCoinShopClient = GetCoinShopClient()
    if not hCoinShopClient then
        return
    end

    local tbPreviewBox = self.tbRoleBoxes[COINSHOP_BOX_INDEX.IDLE_ACTION]
    local widgetProp = tbPreviewBox.rootNode:getChildByName("WidgetPropBox" .. tbPreviewBox.szIndex)
    UIHelper.SetSwallowTouches(tbPreviewBox.rootNode, false)

    local nLogicAniID, bMultiPreview = ExteriorCharacter.GetPreviewAniID()
    local nResetAniID = hPlayer.GetDisplayIdleAction(PLAYER_IDLE_ACTION_DISPLAY_TYPE.COIN_SHOP)
    if nLogicAniID == 0 or bMultiPreview then
        UIHelper.SetVisible(widgetProp, false)
    else
        local tInfo = Table_GetIdleAction(nLogicAniID)
        if not tInfo then
            return
        end
        if not tbPreviewBox.itemIcon then
            tbPreviewBox.itemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, widgetProp)
            tbPreviewBox.itemIcon:SetToggleSwallowTouches(false)
            -- UIHelper.SetAnchorPoint(tbPreviewBox.itemIcon._rootNode , 0.5, 1)
            UIHelper.ToggleGroupAddToggle(self._rootNode, tbPreviewBox.itemIcon.ToggleSelect)
        end
        tbPreviewBox.itemIcon:OnInitWithTabID(tInfo.dwItemType, tInfo.dwItemID)
        tbPreviewBox.itemIcon:SetRecallVisible(nResetAniID ~= nLogicAniID)
        tbPreviewBox.itemIcon:SetRecallCallback(function ()
            Event.Dispatch("RESET_ACTION")
        end)
        tbPreviewBox.itemIcon:SetClickCallback(function(nParam1, nParam2)
            if nParam1 and nParam2 then
                local tbGoods = {
                    dwTabType = tInfo.dwItemType,
                    dwTabIndex = tInfo.dwItemID,
                }
                Event.Dispatch(EventType.OnCoinShopShowItemTips, tbGoods)
            end
        end)
        UIHelper.SetVisible(widgetProp, true)
    end
end

function UICoinShopPreviewBox:UpdatePendantSubBox(nIndex, tItem)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local hCoinShopClient = GetCoinShopClient()
    if not hCoinShopClient then
        return
    end

    local tbPreviewBox = self.tbRoleBoxes[nIndex]
    local widgetProp = tbPreviewBox.rootNode:getChildByName("WidgetPropBox" .. tbPreviewBox.szIndex)
    UIHelper.SetSwallowTouches(tbPreviewBox.rootNode, false)

    local imgBox = UIHelper.GetChildByName(tbPreviewBox.rootNode, "ImgBox")
    UIHelper.SetVisible(imgBox, false)

    local tNewItem = tItem and clone(tItem) or nil
    if tNewItem and tNewItem.dwIndex == 0 and tNewItem.dwPendantIndex and tNewItem.dwPendantIndex > 0 then
        tNewItem.dwTabType = ITEM_TABLE_TYPE.CUST_TRINKET
        tNewItem.dwIndex = tNewItem.dwPendantIndex

        local bInPack = CoinShop_IsInViewPack(tItem.dwPendantIndex)
        UIHelper.SetVisible(imgBox, true)
        if bInPack then
            UIHelper.SetSpriteFrame(imgBox, "UIAtlas2_Shopping_ShoppingIcon_Icon_Box1.png")
            self.bShowPendantInPack = true
        else
            UIHelper.SetSpriteFrame(imgBox, "UIAtlas2_Shopping_ShoppingIcon_Icon_Box2.png")
            self.bShowPendantNotInPack = true
        end
    end

    if not tNewItem or tNewItem.dwIndex <= 0 then
        UIHelper.SetVisible(widgetProp, false)
    else
        if not tbPreviewBox.itemIcon then
            tbPreviewBox.itemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, widgetProp)
            tbPreviewBox.itemIcon:SetToggleSwallowTouches(false)
            -- UIHelper.SetAnchorPoint(tbPreviewBox.itemIcon._rootNode , 0.5, 1)
            UIHelper.ToggleGroupAddToggle(self._rootNode, tbPreviewBox.itemIcon.ToggleSelect)
        end
        tbPreviewBox.itemIcon:OnInitWithTabID(tNewItem.dwTabType, tNewItem.dwIndex)
        tbPreviewBox.itemIcon:SetRecallVisible(true)
        tbPreviewBox.itemIcon:SetRecallCallback(function ()
            ExteriorCharacter.CancelPreviewRewards(tNewItem)
        end)
        tbPreviewBox.itemIcon:SetClickCallback(function(nParam1, nParam2)
            if nParam1 and nParam2 then
                local tbGoods = {
                    eGoodsType = COIN_SHOP_GOODS_TYPE.ITEM,
                    dwTabType = tNewItem.dwTabType,
                    dwTabIndex = tNewItem.dwIndex,
                    dwGoodsID = tNewItem.dwLogicID
                }
                Event.Dispatch(EventType.OnCoinShopShowItemTips, tbGoods)
            end
        end)
        UIHelper.SetVisible(widgetProp, true)
    end
end

local function IsPreviewEffect(tInfo)
    for nType, tTable in pairs(tInfo) do
        if tTable and tTable.nEffectID and tTable.nEffectID > 0 then
            return true
        end
    end
end

local function IsEffectChanged(tEffectList, tLastEffectList)
    if table.get_len(tEffectList) ~= table.get_len(tLastEffectList) then
        return true
    else
        for nType, tTable in pairs(tEffectList) do
            local tLastTable = tLastEffectList[nType]
            if not tLastTable or tTable.nEffectID ~= tLastTable.nEffectID then
                return true
            end
        end
    end
    return false
end

function UICoinShopPreviewBox:UpdateEffectSfxSubBox(nIndex, tEffectList)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local hCoinShopClient = GetCoinShopClient()
    if not hCoinShopClient then
        return
    end

    local bChange = IsEffectChanged(tEffectList, self.tLastEffectList)
    self.tLastEffectList = clone(tEffectList)

    local tbPreviewBoxList = self.tbRoleBoxes[nIndex]
    for nType, tbEffectInfo in pairs(tbPreviewBoxList) do
        local tbPreviewBox = tbPreviewBoxList[nType]
        local widgetProp = tbPreviewBox.rootNode:getChildByName("WidgetPropBox" .. tbPreviewBox.szIndex)
        UIHelper.SetSwallowTouches(tbPreviewBox.rootNode, false)

        local tItem = tEffectList[nType]
        if not tbPreviewBox.ImgSelect then
            tbPreviewBox.ImgSelect = tbPreviewBox.rootNode:getChildByName("ImgSelect")
        end
        if not tItem then
            UIHelper.SetVisible(widgetProp, false)
            UIHelper.SetVisible(tbPreviewBox.ImgSelect, false)
            UIHelper.RemoveAllChildren(widgetProp)
            tbPreviewBox.itemIcon = nil
        else
            if not tbPreviewBox.itemIcon then
                tbPreviewBox.itemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, widgetProp)
                tbPreviewBox.itemIcon:RegEvent()
                tbPreviewBox.itemIcon:BindUIEvent()
                tbPreviewBox.itemIcon.bInit = true
                tbPreviewBox.itemIcon:SetToggleSwallowTouches(false)
            end
            UIHelper.SetVisible(tbPreviewBox.ImgSelect, true)
            local szImgPath = COINSHOP_EFFECT_BOX[nType]
            tbPreviewBox.itemIcon:SetIconByTexture(szImgPath, nil)
            tbPreviewBox.itemIcon:SetRecallVisible(true)
            tbPreviewBox.itemIcon:HideLabelCount()

            tbPreviewBox.itemIcon:SetRecallCallback(function ()
                FireUIEvent("RESET_ONE_EFFECT_SFX", nType)
            end)
            tbPreviewBox.itemIcon:SetClickCallback(function(nParam1, nParam2)
                local tbGoods = {
                    dwTabType = "Effect",
                    dwTabIndex = tItem.nEffectID,
                }
                Event.Dispatch(EventType.OnCoinShopShowItemTips, tbGoods)
            end)
            UIHelper.SetVisible(widgetProp, true)
        end
    end

    if not tEffectList or not IsPreviewEffect(tEffectList) then
        --隐藏特效类型tog
        Event.Dispatch(EventType.OnCoinShopSetEffectTogSelected, false)
    else
        if self.m_szViewPage == "Role" and bChange then
            --显示特效类型tog并选中
            Event.Dispatch(EventType.OnCoinShopSetEffectTogSelected, true)
        end
    end

end

function UICoinShopPreviewBox:OnRideViewDataUpdate()
    self.m_szViewPage = "Ride"
    UIHelper.SetVisible(self.WidgetAnchorPetRight, self.m_szViewPage == "Pet")
    UIHelper.SetVisible(self.WidgetAnchorRight, self.m_szViewPage == "Role")
    UIHelper.SetVisible(self.WidgetAnchorFurnitureRight, self.m_szViewPage == "Furniture")
    UIHelper.SetVisible(self.WidgetAnchorSaddleHorseRight, self.m_szViewPage == "Ride")

    local tbRideData = ExteriorCharacter.GetRideData()
    for nIndex, tbData in ipairs(tbRideData) do
        if nIndex == COINSHOP_RIDE_BOX_INDEX.ITEM then
            self:UpdateRideItemSubBox(nIndex, tbData.tItem)
        else
            self:UpdateRideSubBox(nIndex, tbData.tItem)
        end
    end
end

function UICoinShopPreviewBox:UpdateRideSubBox(nIndex, tItem)
    local tbPreviewBox = self.tbRideBoxes[nIndex]
    if not tbPreviewBox then
        return
    end
    local widgetProp = tbPreviewBox.rootNode:getChildByName("WidgetPropBox" .. tbPreviewBox.szIndex)
    UIHelper.SetSwallowTouches(tbPreviewBox.rootNode, false)

    if not tItem or tItem.dwIndex <= 0 then
        UIHelper.SetVisible(widgetProp, false)
    else
        if not tbPreviewBox.itemIcon then
            tbPreviewBox.itemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, widgetProp)
            tbPreviewBox.itemIcon:SetToggleSwallowTouches(false)
            -- UIHelper.SetAnchorPoint(tbPreviewBox.itemIcon._rootNode , 0.5, 1)
            UIHelper.ToggleGroupAddToggle(self._rootNode, tbPreviewBox.itemIcon.ToggleSelect)
        end
        tbPreviewBox.itemIcon:OnInitWithTabID(tItem.dwTabType, tItem.dwIndex)
        tbPreviewBox.itemIcon:SetRecallVisible(true)
        tbPreviewBox.itemIcon:SetRecallCallback(function ()
            ExteriorCharacter.CancelPreviewRewards(tItem)
        end)
        tbPreviewBox.itemIcon:SetClickCallback(function(nParam1, nParam2)
            if nParam1 and nParam2 then
                local tbGoods = {
                    eGoodsType = COIN_SHOP_GOODS_TYPE.ITEM,
                    dwTabType = tItem.dwTabType,
                    dwTabIndex = tItem.dwIndex,
                    dwGoodsID = tItem.dwLogicID
                }
                Event.Dispatch(EventType.OnCoinShopShowItemTips, tbGoods)
            end
        end)
        UIHelper.SetVisible(widgetProp, true)
    end
end

function UICoinShopPreviewBox:UpdateRideItemSubBox(nIndex, tItem)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local tbPreviewBox = self.tbRideBoxes[nIndex]
    local widgetProp = tbPreviewBox.rootNode:getChildByName("WidgetPropBox" .. tbPreviewBox.szIndex)
    UIHelper.SetSwallowTouches(tbPreviewBox.rootNode, false)

    if tItem then
        if not tbPreviewBox.itemIcon then
            tbPreviewBox.itemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, widgetProp)
            tbPreviewBox.itemIcon:SetToggleSwallowTouches(false)
            -- UIHelper.SetAnchorPoint(tbPreviewBox.itemIcon._rootNode , 0.5, 1)
            UIHelper.ToggleGroupAddToggle(self._rootNode, tbPreviewBox.itemIcon.ToggleSelect)
        end

        local dwLogicID, dwTabType, dwIndex = tItem.dwLogicID, tItem.dwTabType, tItem.dwIndex
        tbPreviewBox.itemIcon:OnInitWithTabID(dwTabType, dwIndex)
        tbPreviewBox.itemIcon:SetRecallVisible(true)
        tbPreviewBox.itemIcon:SetRecallCallback(function ()
            ExteriorCharacter.CancelPreviewRewards(tItem)
        end)
        tbPreviewBox.itemIcon:SetClickCallback(function(nParam1, nParam2)
            if nParam1 and nParam2 then
                local tbGoods = {
                    eGoodsType = COIN_SHOP_GOODS_TYPE.ITEM,
                    dwTabType = dwTabType,
                    dwTabIndex = dwIndex,
                    dwGoodsID = dwLogicID,
                }
                Event.Dispatch(EventType.OnCoinShopShowItemTips, tbGoods)
            end
        end)
        UIHelper.SetVisible(widgetProp, true)
    else
        UIHelper.SetVisible(widgetProp, false)
    end

    self:UpdateRideItemSubBoxSubItems(nIndex, tItem)
end

function UICoinShopPreviewBox:UpdateRideItemSubBoxSubItems(nIndex, tItem)
    local tbPreviewBox = self.tbRideBoxes[nIndex]
    local tSubItems = {}
    if tItem then
        local hItemInfo = GetItemInfo(tItem.dwTabType, tItem.dwIndex)
        if hItemInfo.nGenre == ITEM_GENRE.COIN_SHOP_QUANTITY_LIMIT_ITEM and hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.PACK then
            local tPackList = CoinShop_GetAllLimitViewPack(hItemInfo.nDetail)
            if not IsTableEmpty(tPackList) then
                for _, tPackInfo in ipairs(tPackList) do
                    local tPackItem = GetItemInfo(ITEM_TABLE_TYPE.OTHER, tPackInfo.dwIndex)
                    -- local tViewItems = CoinShop_GetLimitView(tPackItem.nDetail)
                    local tSubItem = {
                        dwItemType = ITEM_TABLE_TYPE.OTHER,
                        dwItemID = tPackInfo.dwIndex,
                        bPack = true,
                        tItem = {
                            dwTabType = ITEM_TABLE_TYPE.OTHER,
                            dwIndex = tPackInfo.dwIndex,
                        },
                    }
                    table.insert(tSubItems, tSubItem)
                end
            else
                local tViewItems = CoinShop_GetAllLimitView(hItemInfo.nDetail)
                for _, tViewItem in ipairs(tViewItems) do
                    if tViewItem.dwItemType ~= 0 and tViewItem.dwItemID ~= 0 then
                        table.insert(tSubItems, tViewItem)
                    end
                end
            end
        end
    end
    for i, togSub in ipairs(self.tbTogHorseSubItems) do
        tbPreviewBox.tbSubItemIcons = tbPreviewBox.tbSubItemIcons or {}

        if i <= #tSubItems then
            local bPreview = false
            if tSubItems[i].nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.HORSE_EQUIP then
                local tNewItem = {dwTabType = ITEM_TABLE_TYPE.CUST_TRINKET, dwIndex = tSubItems[i].dwLogicID}
                bPreview = ExteriorCharacter.IsHAdornmentMultiPreview(tNewItem)
            elseif tSubItems[i].nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.HORSE then
                local tNewItem = {dwTabType = ITEM_TABLE_TYPE.CUST_TRINKET, dwIndex = tSubItems[i].dwLogicID}
                bPreview = ExteriorCharacter.IsHorseMultiPreview(tNewItem)
            elseif tSubItems[i].bPack then
                bPreview = ExteriorCharacter.IsRewardsPreview(tSubItems[i].tItem)
            end
            -- todo MultiData
            local togView = togSub:getChildByName("TogPitch0" .. i+1)
            UIHelper.SetSelected(togView, bPreview, false)
            LOG.INFO("%d %s", i, tostring(bPreview))

            if not tbPreviewBox.tbSubItemIcons[i] then
                local widgetSubProp = togSub:getChildByName("WidgetPropBox0" .. i+1)
                UIHelper.SetVisible(widgetSubProp, true)
                local togView = togSub:getChildByName("TogPitch0" .. i+1)
                UIHelper.SetSwallowTouches(togView, true)
                tbPreviewBox.tbSubItemIcons[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, widgetSubProp)
            end

            tbPreviewBox.tbSubItemIcons[i]:OnInitWithTabID(tSubItems[i].dwItemType, tSubItems[i].dwItemID)
            tbPreviewBox.tbSubItemIcons[i]:SetToggleSwallowTouches(false)
            local togView = togSub:getChildByName("TogPitch0" .. i+1)
            UIHelper.UnBindUIEvent(togView, EventType.OnSelectChanged)
            UIHelper.BindUIEvent(togView, EventType.OnSelectChanged, function (_, bSelected)
                if not bSelected then
                    if tSubItems[i].bPack then
                        ExteriorCharacter.CancelPreviewRewards(tSubItems[i].tItem)
                    else
                        local tItems = {}
                        table.insert(tItems, tSubItems[i])
                        ExteriorCharacter.CancelPreviewRewards(tItem, tItems)
                    end
                else
                    if tSubItems[i].bPack then
                        ExteriorCharacter.PreviewRewardsItem(tSubItems[i].tItem)
                    else
                        local tItems = {}
                        table.insert(tItems, tSubItems[i])
                        ExteriorCharacter.PreviewRewardsItem(tItem, tItems)
                    end
                end
            end)

            tbPreviewBox.tbSubItemIcons[i]:SetClickCallback(function(nParam1, nParam2)
                if nParam1 and nParam2 then
                    local tbGoods = {
                        -- eGoodsType = COIN_SHOP_GOODS_TYPE.ITEM,
                        dwTabType = tSubItems[i].dwItemType,
                        dwTabIndex = tSubItems[i].dwItemID,
                        -- dwGoodsID = tSubItems[i].dwLogicID,
                    }
                    Event.Dispatch(EventType.OnCoinShopShowItemTips, tbGoods)
                end
            end)

            UIHelper.SetVisible(togSub, true)
        else
            UIHelper.SetVisible(togSub, false)
        end
    end
    UIHelper.SetVisible(self.ImgHorseItemBox, #tSubItems > 0)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewHorseProp)
end

function UICoinShopPreviewBox:OnPetViewDataUpdate()
    self.m_szViewPage = "Pet"
    UIHelper.SetVisible(self.WidgetAnchorPetRight, self.m_szViewPage == "Pet")
    UIHelper.SetVisible(self.WidgetAnchorRight, self.m_szViewPage == "Role")
    UIHelper.SetVisible(self.WidgetAnchorFurnitureRight, self.m_szViewPage == "Furniture")
    UIHelper.SetVisible(self.WidgetAnchorSaddleHorseRight, self.m_szViewPage == "Ride")

    self.tbPetBox = self.tbPetBox or UIHelper.AddPrefab(PREFAB_ID.WidgetExteriorPreviewItemCell, self.ScrollViewPet)
    self.tbPetBox:OnInitWithBox()
    local tData = ExteriorCharacter.GetPetData()
    local tItem = tData.tItem
    local tPetItem = tItem
    local bMultiPreview = false
    if tItem and tItem.tPetItem then
        tPetItem = tItem and tItem.tPetItem
        bMultiPreview = true
    end
    if not tItem or tItem.dwIndex <= 0 then
        UIHelper.SetVisible(self.tbPetBox.ItemBoxScript._rootNode, false)
    else
        UIHelper.SetVisible(self.tbPetBox.ItemBoxScript._rootNode, true)
        self.tbPetBox.ItemBoxScript:OnInitWithTabID(tPetItem.dwTabType, tPetItem.dwIndex)
        self.tbPetBox.ItemBoxScript:SetClickCallback(function(nParam1, nParam2)
            if nParam1 and nParam2 then
                local tbGoods = {
                    eGoodsType = COIN_SHOP_GOODS_TYPE.ITEM,
                    dwTabType = tPetItem.dwTabType,
                    dwTabIndex = tPetItem.dwIndex,
                    dwGoodsID = tPetItem.dwLogicID,
                }
                Event.Dispatch(EventType.OnCoinShopShowItemTips, tbGoods)
            end
        end)
    end
    UIHelper.SetVisible(self.tbPetBox.ImgItem_Kuang, bMultiPreview)
    self:UpdatePetSubItems(tPetItem)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewPet)
end

function UICoinShopPreviewBox:UpdatePetSubItems(tItem)
    self.tbPetSubItems = self.tbPetSubItems or {}
    self:UpdateSubItems(tItem, self.tbPetSubItems, self.ScrollViewPet)
end

function UICoinShopPreviewBox:OnFurnitureViewDataUpdate()
    self.m_szViewPage = "Furniture"
    UIHelper.SetVisible(self.WidgetAnchorPetRight, self.m_szViewPage == "Pet")
    UIHelper.SetVisible(self.WidgetAnchorRight, self.m_szViewPage == "Role")
    UIHelper.SetVisible(self.WidgetAnchorFurnitureRight, self.m_szViewPage == "Furniture")
    UIHelper.SetVisible(self.WidgetAnchorSaddleHorseRight, self.m_szViewPage == "Ride")

    local tbPreviewBox = self.tbFurnitureBox
    local tData = ExteriorCharacter.GetFurnitureData()
    local tItem = tData.tItem
    if not tbPreviewBox then
        return
    end
    local widgetProp = tbPreviewBox.rootNode:getChildByName("WidgetPropBox")
    UIHelper.SetSwallowTouches(tbPreviewBox.rootNode, false)

    if not tItem or tItem.dwIndex <= 0 then
        UIHelper.SetVisible(widgetProp, false)
    else
        if not tbPreviewBox.itemIcon then
            tbPreviewBox.itemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, widgetProp)
            tbPreviewBox.itemIcon:SetToggleSwallowTouches(false)
            UIHelper.ToggleGroupAddToggle(self._rootNode, tbPreviewBox.itemIcon.ToggleSelect)
        end

        tbPreviewBox.itemIcon:OnInitWithTabID(tItem.dwTabType, tItem.dwIndex)
        tbPreviewBox.itemIcon:SetClickCallback(function(nParam1, nParam2)
            if nParam1 and nParam2 then
                local tbGoods = {
                    eGoodsType = COIN_SHOP_GOODS_TYPE.ITEM,
                    dwTabType = tItem.dwTabType,
                    dwTabIndex = tItem.dwIndex,
                    dwGoodsID = tItem.dwLogicID,
                }
                Event.Dispatch(EventType.OnCoinShopShowItemTips, tbGoods)
            end
        end)
        UIHelper.SetVisible(widgetProp, true)
    end
end

function UICoinShopPreviewBox:ClearSelect()
    for nIndex, tbPreviewBox in pairs(self.tbRoleBoxes) do
        if nIndex == COINSHOP_BOX_INDEX.EFFECT_SFX  then
            for _, tbSubBox in pairs(tbPreviewBox) do
                UIHelper.SetSelected(tbSubBox.rootNode, false, false)
                if tbSubBox.itemIcon then
                    tbSubBox.itemIcon:SetSelected(false)
                end
            end
        else
            UIHelper.SetSelected(tbPreviewBox.rootNode, false, false)
            if tbPreviewBox.itemIcon then
                tbPreviewBox.itemIcon:SetSelected(false)
            end
        end
    end
    if self.tbTogSubItems then
        for _, subCell in ipairs(self.tbTogSubItems) do
            subCell.ItemCellScript:SetSelected(false)
        end
    end

    for _, tbPreviewBox in pairs(self.tbRideBoxes) do
        UIHelper.SetSelected(tbPreviewBox.rootNode, false, false)
        if tbPreviewBox.itemIcon then
            tbPreviewBox.itemIcon:SetSelected(false)
        end
    end
    local tbRideSubItemIcons = self.tbRideBoxes[COINSHOP_RIDE_BOX_INDEX.ITEM].tbSubItemIcons
    if  tbRideSubItemIcons then
        for _, itemIcon in ipairs(tbRideSubItemIcons) do
            itemIcon:SetSelected(false)
        end
    end

    if self.tbPetBox then
        self.tbPetBox.ItemBoxScript:SetSelected(false)
    end
    for _, subCell in ipairs(self.tbPetSubItems) do
        subCell.ItemCellScript:SetSelected(false)
    end

    if self.tbFurnitureBox.itemIcon then
        self.tbFurnitureBox.itemIcon:SetSelected(false)
    end
end


return UICoinShopPreviewBox