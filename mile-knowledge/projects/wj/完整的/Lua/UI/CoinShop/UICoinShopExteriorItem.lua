-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopExteriorItem
-- Date: 2023-03-02 17:32:39
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICoinShopExteriorItem = class("UICoinShopExteriorItem")

function UICoinShopExteriorItem:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UICoinShopExteriorItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)

    if self.nDownloadDynamicID then
        PakDownloadMgr.ReleaseDynamicPakInfo(self.nDownloadDynamicID)
        self.nDownloadDynamicID = nil
    end
end

function UICoinShopExteriorItem:BindUIEvent()
    UIHelper.BindUIEvent(self.TogPetList, EventType.OnClick, function ()
        if self.tbOutfit then
            self:OnClickOutfit()
        end
    end)

    UIHelper.BindUIEvent(self.TogPetList, EventType.OnSelectChanged, function (_, bSelected)
        if self.tbReplaceOutfit then
            Event.Dispatch(EventType.OnCoinShopSelectedReplaceOutfit, self.tbReplaceOutfit, bSelected)
        end

        if self.fnSelected then
            self.fnSelected(bSelected)
        end
    end)
end

function UICoinShopExteriorItem:RegEvent()
    Event.Reg(self, EventType.OnEquipPakResourceDownload, function()
        self:UpdateDownload()
    end)
end

function UICoinShopExteriorItem:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopExteriorItem:UpdateItemState()
    if self.tbOutfit then
        local bPreview = self:IsOutfitPreview()
        UIHelper.SetSelected(self.TogPetList, bPreview, false)
        self.fnSelectedOutfit(self, bPreview)
    end
end

function UICoinShopExteriorItem:Update()
    if not self.bInit then
        return
    end
    if self.tbOutfit then
        self:UpdateOutfit()
    end
end

function UICoinShopExteriorItem:OnInitWithOutfit(tbOutfit, nIndex, fnSelected)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbOutfit = tbOutfit
    self.nIndex = nIndex
    self.fnSelectedOutfit = fnSelected

    self:UpdateOutfit()

    local tRepresentID = CoinShopData.GetOutfitRepresent(self.tbOutfit)
    local tEquipList, tEquipSfxList = PakEquipResData.GetRepresentPakResource(g_pClientPlayer.nRoleType, self.tbOutfit.bHideHat, tRepresentID)
    self:UpdateDownloadEquipRes({}, tEquipList, tEquipSfxList)
end

function UICoinShopExteriorItem:OnInitWithGoods(tGoods, nType, fnSelected)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tGoods = tGoods
    self.nType = nType
    self.fnSelected = fnSelected

    self:UpdateGoods()
end

function UICoinShopExteriorItem:UpdateOutfit()
    local tbOutfit = self.tbOutfit
    local nIndex = self.nIndex

    UIHelper.SetString(self.LabelPetTitle, tbOutfit.szName)
    UIHelper.SetString(self.LabelPetTitle02, tbOutfit.szName)
    UIHelper.SetString(self.LabelPetName, "预设")
    UIHelper.SetString(self.LabelPetName02, "预设")

    UIHelper.SetVisible(self.WidgetCollect, false)
    UIHelper.SetVisible(self.LayoutPrice, false)
    UIHelper.SetVisible(self.ImgDiscount02, false)

    UIHelper.SetVisible(self.ImgCollected, false)
    UIHelper.SetVisible(self.ImgTimeLimit, false)
    UIHelper.SetVisible(self.ImgNew, false)
    UIHelper.SetVisible(self.ImgCloud, tbOutfit.bServer)

    local bPreview = self:IsOutfitPreview()
    UIHelper.SetSelected(self.TogPetList, bPreview, false)
    self.fnSelectedOutfit(self, bPreview)
end

function UICoinShopExteriorItem:UpdateGoods()
    local tGoods = self.tGoods
    local szName = tGoods.szName
    local szSubType = tGoods.szSubType
    local dwTabType = tGoods.dwTabType
    local bSelected = tGoods.bSelected

    UIHelper.SetString(self.LabelPetTitle, szName)
    UIHelper.SetString(self.LabelPetTitle02, szName)
    UIHelper.SetString(self.LabelPetName, szSubType)
    UIHelper.SetString(self.LabelPetName02, szSubType)

    UIHelper.SetVisible(self.WidgetCollect, false)
    UIHelper.SetVisible(self.LayoutPrice, false)
    UIHelper.SetVisible(self.ImgDiscount02, false)

    UIHelper.SetVisible(self.ImgCollected, tGoods.bHave)
    UIHelper.SetVisible(self.ImgTimeLimit, false)
    UIHelper.SetVisible(self.ImgNew, false)
    UIHelper.SetVisible(self.ImgCloud, false)

    UIHelper.SetSelected(self.TogPetList, bSelected, false)

    UIHelper.RemoveAllChildren(self.ImgNormalIcon1)
    UIHelper.RemoveAllChildren(self.ImgNormalIcon2)
    if not tGoods.dwGoodsID or tGoods.dwGoodsID <= 0 then
        return
    end

    local scriptItem1 = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.ImgNormalIcon1)
    local scriptItem2 = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.ImgNormalIcon2)

    scriptItem1:SetClickNotSelected(true)
    scriptItem2:SetClickNotSelected(true)

    if tGoods.eGoodsType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
        scriptItem1:OnInitWithTabID(dwTabType, tGoods.dwGoodsID)
        scriptItem2:OnInitWithTabID(dwTabType, tGoods.dwGoodsID)
    elseif tGoods.eGoodsType == COIN_SHOP_GOODS_TYPE.HAIR then
        scriptItem1:OnInitWithIconID(10775)
        scriptItem2:OnInitWithIconID(10775)
    elseif tGoods.eGoodsType == COIN_SHOP_GOODS_TYPE.ITEM then
        scriptItem1:OnInitWithTabID(dwTabType, tGoods.dwGoodsID)
        scriptItem2:OnInitWithTabID(dwTabType, tGoods.dwGoodsID)
    elseif tGoods.eGoodsType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
        scriptItem1:OnInitWithTabID(dwTabType, tGoods.dwGoodsID)
        scriptItem2:OnInitWithTabID(dwTabType, tGoods.dwGoodsID)
    end

    scriptItem1:SetClickCallback(function()
        local tips, showTipsScript = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, self._rootNode)
        showTipsScript:HidePreviewBtn(true)
        if tGoods.eGoodsType == COIN_SHOP_GOODS_TYPE.ITEM then
            showTipsScript:OnInitWithTabID(dwTabType, tGoods.dwGoodsID)
        else
            showTipsScript:OnInitWithCoinShopGoods(tGoods)
        end
        showTipsScript:SetBtnState({})
    end)

    scriptItem2:SetClickCallback(function()
        local tips, showTipsScript = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, self._rootNode)
        showTipsScript:HidePreviewBtn(true)
        if tGoods.eGoodsType == COIN_SHOP_GOODS_TYPE.ITEM then
            showTipsScript:OnInitWithTabID(dwTabType, tGoods.dwGoodsID)
        else
            showTipsScript:OnInitWithCoinShopGoods(tGoods)
        end
        showTipsScript:SetBtnState({})
    end)
end

function UICoinShopExteriorItem:OnClickOutfit()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    FireUIEvent("COINSHOP_CLEAR_ROLE_PREVIEW", false)

    local tWeaponBox = CoinShop_GetWeaponIndexArray()
    for _, tData in ipairs(self.tbOutfit.tData) do
        local dwID = tData.dwID
        local nIndex = tData.nIndex

        local nSub = Exterior_BoxIndexToExteriorSub(nIndex)
        if dwID and dwID > 0 then
            if nSub then
                FireUIEvent("PREVIEW_SUB", dwID, nil, false, false)
            elseif nIndex == COINSHOP_BOX_INDEX.ITEM then -- item did not save
            elseif nIndex == COINSHOP_BOX_INDEX.HAIR then
                local tColorID = tData.tColorID
                FireUIEvent("PREVIEW_HAIR", dwID, nil, false, false, false, tColorID[1])
            elseif nIndex == COINSHOP_BOX_INDEX.NEW_FACE then
                local tFaceData = CoinShopData.GetNewFaceData(dwID)
                FireUIEvent("PREVIEW_NEW_FACE", dwID, tFaceData, true)
            elseif nIndex == COINSHOP_BOX_INDEX.FACE then
                if tData.bUseLiftedFace then
                    local tFaceData = CoinShopData.GetLiftedFaceData(dwID)
                    local UserData = {}
                    UserData.tFaceData = tFaceData
                    UserData.nIndex = dwID
                    FireUIEvent("PREVIEW_FACE", nil, true, UserData, true, true)
                else
                    FireUIEvent("PREVIEW_FACE", dwID, nil, nil, false, true)
                end
            elseif nIndex == COINSHOP_BOX_INDEX.PENDANT_PET then
                local tItem = {}
                tItem.dwTabType = ITEM_TABLE_TYPE.CUST_TRINKET
                tItem.dwIndex = dwID
                local tPendantPet = hPlayer.GetPendentPet(dwID)
                tItem.nPos = tPendantPet.nPos
                FireUIEvent("PREVIEW_PENDANT_PET", tItem, false, false)
            elseif nIndex == COINSHOP_BOX_INDEX.BODY then
                local tBody = CoinShopData.GetPlayerBodyIndexData(dwID)
                if tBody then
                    FireUIEvent("PREVIEW_BODY", dwID, tBody)
                end
            elseif CoinShop_BoxIndexToPendantType(nIndex) then
                local tItem = {}
                tItem.dwTabType = ITEM_TABLE_TYPE.CUST_TRINKET
                tItem.dwIndex = dwID
                tItem.tColorID = tData.tColorID
                FireUIEvent("PREVIEW_PENDANT", tItem, false, false, CoinShop_BoxIndexToPendantType(nIndex))
            elseif tWeaponBox[nIndex] then
                FireUIEvent("PREVIEW_WEAPON", dwID, false)
            end
        end
    end

    FireUIEvent("COINSHOPVIEW_ROLE_DATA_UPDATE")
    FireUIEvent("COINSHOP_HIDE_HAT", self.tbOutfit.bHideHat)
end

function UICoinShopExteriorItem:IsOutfitPreview()
    local tbOutfit = ExteriorCharacter.GetCurrentOutfit()
    local bSame = CoinShop_IsOutfitSame(tbOutfit, self.tbOutfit)
    return bSame
end

function UICoinShopExteriorItem:UpdateOutfitStorageState()
    UIHelper.SetVisible(self.ImgCloud, self.tbOutfit.bServer)
end

function UICoinShopExteriorItem:OnInitWithReplaceOutfit(tbReplaceOutfit)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbReplaceOutfit = tbReplaceOutfit

    UIHelper.SetString(self.LabelPetTitle, tbReplaceOutfit.szName)
    UIHelper.SetString(self.LabelPetTitle02, tbReplaceOutfit.szName)
    UIHelper.SetString(self.LabelPetName, "预设")
    UIHelper.SetString(self.LabelPetName02, "预设")

    UIHelper.SetVisible(self.WidgetCollect, false)
    UIHelper.SetVisible(self.LayoutPrice, false)
    UIHelper.SetVisible(self.ImgDiscount02, false)

    UIHelper.SetVisible(self.ImgCollected, false)
    UIHelper.SetVisible(self.ImgTimeLimit, false)
    UIHelper.SetVisible(self.ImgNew, false)
    UIHelper.SetVisible(self.ImgCloud, tbReplaceOutfit.bServer)

    UIHelper.SetSelected(self.TogPetList, false, false)
end

function UICoinShopExteriorItem:UpdateDownloadEquipRes(tList, tEquipList, tEquipSfxList)
    if not PakDownloadMgr.IsEnabled() then
        return
    end
    if not tEquipList and not tEquipSfxList then
        tEquipList, tEquipSfxList = PakEquipResData.GetPakResource(g_pClientPlayer.nRoleType, tList)
    end
    self.tEquipList, self.tEquipSfxList = tEquipList, tEquipSfxList
    self:UpdateDownload()
end

function UICoinShopExteriorItem:UpdateDownload()
    local tEquipList, tEquipSfxList = self.tEquipList, self.tEquipSfxList
    if not tEquipList or not tEquipSfxList then
        return
    end
    local tConfig = {}
    tConfig.bCoinShop = true
    tConfig.nTouchWidth, tConfig.nTouchHeight = UIHelper.GetContentSize(self.TogPetList)
    tConfig.bSwallowTouch = false
    local bRemoteNotExist
    self.nDownloadDynamicID, bRemoteNotExist = PakDownloadMgr.UserCheckDownloadEquipRes(g_pClientPlayer.nRoleType, tEquipList, tEquipSfxList, self.nDownloadDynamicID)
    local scriptMask = UIHelper.GetBindScript(self.WidgetDownloadShell)
    scriptMask:SetShowCondition(function()
        return UIHelper.GetSelected(self.TogPetList)
    end)
    scriptMask:SetVisibleChangedCallback(function (bVisible)
        UIHelper.SetTouchEnabled(self.TogPetList, not bVisible)
        UIHelper.SetSwallowTouches(self.TogPetList, false)
    end)
    scriptMask:SetInfo(self.nDownloadDynamicID, bRemoteNotExist, tConfig)
end

return UICoinShopExteriorItem