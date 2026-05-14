-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICharacterPendantExteriorPage
-- Date: 2023-02-27 11:20:09
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICharacterPendantExteriorPage = class("UICharacterPendantExteriorPage")

local MAX_GROUP_MEMBER_COUNT = 6
local OFFSET_Z = 128
local MODEL_POS = {
    [1] = { 133420, 4405, 35844 + OFFSET_Z, 1.5},
    [2] = { 133420, 4405, 35844, 1.5},
    [3] = { 133420, 4405, 35844 - OFFSET_Z, 1.5},
    [4] = { 133420, 4195, 35844 + OFFSET_Z, 1.5},
    [5] = { 133420, 4195, 35844, 1.5},
    [6] = { 133420, 4195, 35844 - OFFSET_Z, 1.5},
}

local CAMERA_POS = { 132968, 4420, 35806, 133398, 4400, 35844 }

function UICharacterPendantExteriorPage:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nCurPage = 1
    self.nMaxPage = 1
    self.nCurSelectIndex = 1
    self.tbScriptCell = {}
    self.tbList = CoinShopData.GetOutfitList() or {}

    self:UpdateInfo()
end

function UICharacterPendantExteriorPage:OnExit()
    self.bInit = false
end

function UICharacterPendantExteriorPage:BindUIEvent()
    UIHelper.SetEditboxTextHorizontalAlign(self.EditPaginate, TextHAlignment.CENTER)
    UIHelper.BindUIEvent(self.BtnRight, EventType.OnClick, function()
        if self.nCurPage >= self.nMaxPage then
            return
        end

        self.nCurPage = self.nCurPage + 1
        self:UpdateListInfo()
        self:UpdatePageInfo()
    end)

    UIHelper.BindUIEvent(self.BtnLeft, EventType.OnClick, function()
        if self.nCurPage <= 1 then
            return
        end

        self.nCurPage = self.nCurPage - 1
        self:UpdateListInfo()
        self:UpdatePageInfo()
    end)

    UIHelper.BindUIEvent(self.BtnDelete, EventType.OnClick, function()
        self:Delete()
    end)

    UIHelper.BindUIEvent(self.TogCloud, EventType.OnClick, function()
        self:CheckStorage()
    end)

    UIHelper.BindUIEvent(self.BtnSet, EventType.OnClick, function()

    end)

    if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditPaginate, function()
            local szPage = UIHelper.GetString(self.EditPaginate)
            local nPage = tonumber(szPage)
            if not nPage or nPage <= 0 then
                nPage = self.nCurPage
            elseif nPage > self.nMaxPage then
                nPage = self.nMaxPage
            end

            UIHelper.SetString(self.EditPaginate, tostring(nPage))

            if nPage == self.nCurPage then
                return
            end

            self.nCurPage = nPage
            self:UpdateListInfo()
        end)
    else
        Event.Reg(self, EventType.OnGameNumKeyboardConfirmed, function(editbox)
            if editbox ~= self.EditPaginate then return end
            local szPage = UIHelper.GetString(self.EditPaginate)
            local nPage = tonumber(szPage)
            if not nPage or nPage <= 0 then
                nPage = self.nCurPage
            elseif nPage > self.nMaxPage then
                nPage = self.nMaxPage
            end

            UIHelper.SetString(self.EditPaginate, tostring(nPage))

            if nPage == self.nCurPage then
                return
            end

            self.nCurPage = nPage
            self:UpdateListInfo()
        end)

        UIHelper.RegisterEditBoxReturn(self.EditPaginate, function()
            local szPage = UIHelper.GetString(self.EditPaginate)
            local nPage = tonumber(szPage)
            if not nPage or nPage <= 0 then
                nPage = self.nCurPage
            elseif nPage > self.nMaxPage then
                nPage = self.nMaxPage
            end

            UIHelper.SetString(self.EditPaginate, tostring(nPage))

            if nPage == self.nCurPage then
                return
            end

            self.nCurPage = nPage
            self:UpdateListInfo()
        end)
    end
end

function UICharacterPendantExteriorPage:RegEvent()
    Event.Reg(self, "COIN_SHOP_PRESET_INFO_CHANGED", function (dwIndex, nParam, nMode)
        self:UpdateTitleInfo()
        if nMode == COIN_SHOP_PRESET_NOTIFY_MODE.ADD then
            local tSet = self.tbList[nParam]
            if tSet then
                tSet.dwIndex = dwIndex
            end
        elseif nParam == -1 or nMode == COIN_SHOP_PRESET_NOTIFY_MODE.REPLACE then
            self:RefreshSetList()
        end
    end)

    Event.Reg(self, "DELETE_OUTFIT_SUCCESS", function ()
        self:RefreshSetList()
    end)
end

function UICharacterPendantExteriorPage:UpdateInfo()
    self:UpdateTitleInfo()
    self:UpdatePageInfo()
    self:UpdateListInfo()
    self:UpdateBtnState()
end

function UICharacterPendantExteriorPage:RefreshSetList()
    self.tbList = CoinShopData.GetOutfitList() or {}
    self:UpdatePageInfo()
    self:UpdateListInfo()
    self:UpdateBtnState()
end

function UICharacterPendantExteriorPage:UpdateTitleInfo()
    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

    local nMax = GetCoinShopPresetDataMaxCount()
    local tList = player.GetAllCoinShopPresetData()
    UIHelper.SetString(self.LabelExteriorNumber, string.format("%d/%d", #tList, nMax))
end

function UICharacterPendantExteriorPage:UpdateListInfo()
    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

    UIHelper.SetVisible(self.WidgetEmpty, table.is_empty(self.tbList))
    UIHelper.SetVisible(self.WidgetExterioraginate, not table.is_empty(self.tbList))
    UIHelper.SetVisible(self.BtnDelete, not table.is_empty(self.tbList))
    UIHelper.SetVisible(self.TogCloud, not table.is_empty(self.tbList))

    local nCellIndex = 1

    for i = 1, MAX_GROUP_MEMBER_COUNT, 1 do
        local nCurIndex = (self.nCurPage - 1) * MAX_GROUP_MEMBER_COUNT + i
        local tSet = self.tbList[nCurIndex]

        local scriptCell = self.tbScriptCell[nCellIndex]
        if not scriptCell then
            scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetPresetListItem, self.ScrollViewPresetList)
            table.insert(self.tbScriptCell, scriptCell)
            UIHelper.ToggleGroupAddToggle(self.ToggleGroupExteriorCell, scriptCell.TogPreset)
        end

        if tSet then
            scriptCell:OnEnter(tSet)
            scriptCell:SetClickCallback(function()
                self.nCurSelectIndex = nCurIndex
                self:Apply()
                self:UpdateBtnState()
            end)
            scriptCell:SetVisible(true)
        else
            scriptCell:SetVisible(false)
        end

        nCellIndex = nCellIndex + 1
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewPresetList)
    UIHelper.ScrollToTop(self.ScrollViewPresetList, 0)
end

function UICharacterPendantExteriorPage:UpdatePageInfo()
    self.nMaxPage = math.max(1, math.ceil(#self.tbList / MAX_GROUP_MEMBER_COUNT))

    UIHelper.SetString(self.EditPaginate, tostring(self.nCurPage))
    UIHelper.SetString(self.LabelPaginate, string.format("/%d", self.nMaxPage))

    UIHelper.SetVisible(self.BtnSet, false)
end

function UICharacterPendantExteriorPage:UpdateBtnState()
    local tSet = self:GetCurSelectSet() or {}
    UIHelper.SetSelected(self.TogCloud, tSet.bServer)
end

function UICharacterPendantExteriorPage:DataToServer(tData)
    local tPreset = {}
    local tWeaponBox = CoinShop_GetWeaponIndexArray()
    local bUseLiftedFace = false
    for _, tData in ipairs(tData) do
        local nIndex = tData.nIndex
        local nSub = Exterior_BoxIndexToExteriorSub(nIndex)
        local nSource = nil
        local dwType = nil
        local tColorID = {0, 0, 0}
        if nSub then
            if tData.dwID > 0 then
                nSource = COIN_SHOP_GOODS_SOURCE.COIN_SHOP
                dwType = COIN_SHOP_GOODS_TYPE.EXTERIOR
            end
        --elseif nIndex == COINSHOP_BOX_INDEX.ITEM then -- item did not save
        elseif nIndex == COINSHOP_BOX_INDEX.HAIR then
            nSource = COIN_SHOP_GOODS_SOURCE.COIN_SHOP
            dwType = COIN_SHOP_GOODS_TYPE.HAIR
            if tData.tColorID then
                tColorID = tData.tColorID
                if tColorID[1] < 0 then
                    tColorID[1] = 0
                end
            end
        elseif nIndex == COINSHOP_BOX_INDEX.FACE then
            nSource = COIN_SHOP_GOODS_SOURCE.COIN_SHOP
            dwType = COIN_SHOP_GOODS_TYPE.FACE
            if tData.bUseLiftedFace then
                bUseLiftedFace = true
                nSource = COIN_SHOP_GOODS_SOURCE.FACE_LIFT
            end
        elseif nIndex == COINSHOP_BOX_INDEX.PENDANT_PET then
            if tData.dwID > 0 then
                nSource = COIN_SHOP_GOODS_SOURCE.ITEM_TAB
            end
        elseif nIndex == COINSHOP_BOX_INDEX.BODY then
            if tData.dwID > 0 then
                dwType = COIN_SHOP_GOODS_TYPE.BODY
                nSource = COIN_SHOP_GOODS_SOURCE.BODY_RESHAPING
            end
        elseif nIndex == COINSHOP_BOX_INDEX.NEW_FACE then
            if tData.dwID > 0 then
                nSource = COIN_SHOP_GOODS_SOURCE.FACE_LIFT
                bUseLiftedFace = true
            end
        elseif CoinShop_BoxIndexToPendantType(nIndex) then
            if tData.dwID > 0 then
                nSource = COIN_SHOP_GOODS_SOURCE.ITEM_TAB
                dwType = 0
                if tData.tColorID then
                    tColorID = tData.tColorID
                end
            end
        elseif tWeaponBox[nIndex] then
            if tData.dwID > 0 then
                nSource = COIN_SHOP_GOODS_SOURCE.COIN_SHOP
                dwType = COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR
            end
        end
        if nSource then
            table.insert(tPreset, {nSource = nSource, dwType = dwType, dwID = tData.dwID, nColor1 = tColorID[1], nColor2 = tColorID[2], nColor3 = tColorID[3]})
        end
    end
    return tPreset, bUseLiftedFace
end

function UICharacterPendantExteriorPage:StorageReplaceServer()
    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end
    local tSet = self:GetCurSelectSet()
    local tOutfit = ExteriorCharacter.GetCurrentOutfit()
    local tPreset, bUseLiftedFace = self:DataToServer(tOutfit.tData)
    local nRetCode = player.ReplaceCoinShopPreset(tSet.dwIndex, UIHelper.UTF8ToGBK(tSet.szName), bUseLiftedFace, tSet.bHideHat, self.nCurSelectIndex, tPreset)
    if nRetCode == COIN_SHOP_PRESET_ERROR_CODE.SUCCESS then
        FireUIEvent("REPLACE_OUTFIT_SUCCESS")
        return
    end

    if nRetCode then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tCoinShopPresetNotify[nRetCode])
        OutputMessage("MSG_SYS", g_tStrings.tCoinShopPresetNotify[nRetCode])
    end
end

function UICharacterPendantExteriorPage:StorageToServer(tSet)
    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end
    local tData = tSet.tData
    local tPreset, bUseLiftedFace = self:DataToServer(tData)
    local nRetCode = player.AddCoinShopPreset(UIHelper.UTF8ToGBK(tSet.szName), bUseLiftedFace, tSet.bHideHat, self.nCurSelectIndex, tPreset)

    if nRetCode == COIN_SHOP_PRESET_ERROR_CODE.SUCCESS then
        tSet.bServer = true
        self:UpdateCellStorageState(tSet)
        local _, nIndex = CoinShop_OutfitCheckRepeat(tSet)
        CoinShop_DeleteOutfitList(nIndex, false)
        tSet.nIndex = nil
        self:UpdateBtnState()
        return
    end
    if nRetCode then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tCoinShopPresetNotify[nRetCode])
        OutputMessage("MSG_SYS", g_tStrings.tCoinShopPresetNotify[nRetCode])
    end
end

function UICharacterPendantExteriorPage:StorageToLocal(tSet)
    local player = PlayerData.GetClientPlayer()
    if not player or not player.DeleteCoinShopPreset then
        return
    end
    local bRepeat, nIndex = CoinShop_OutfitCheckRepeat(tSet)
    if bRepeat then
        local tOutfit = CoinShop_GetOutfitByIndex(nIndex)
        local szMessage = FormatString(g_tStrings.COIN_SHOP_PRESET_TO_LOCAL_FAILED, tOutfit.szName)

        local scriptConfirm = UIHelper.ShowConfirm(szMessage)
        scriptConfirm:HideButton("Confirm")
        scriptConfirm:SetButtonContent("Cancel", g_tStrings.STR_HOTKEY_KNOW)
        return
    end
    local nRetCode = player.DeleteCoinShopPreset(tSet.dwIndex, self.nCurSelectIndex)
    if nRetCode then
        tSet.bServer = false
        self:UpdateCellStorageState(tSet)
        tSet.dwIndex = nil
        CoinShop_SaveOutfitList(tSet, false)
        self:UpdateBtnState()
    end
end

function UICharacterPendantExteriorPage:CheckStorage()
    local tSet = self:GetCurSelectSet()
    if not tSet then return end

    if not tSet.bServer then
        self:StorageToServer(tSet)
    else
        self:StorageToLocal(tSet)
    end
end

function UICharacterPendantExteriorPage:Delete()
    local tSet = self:GetCurSelectSet()
    if not tSet then return end

    local fnSureAction = function()
        if tSet.bServer then
            GetClientPlayer().DeleteCoinShopPreset(tSet.dwIndex, -1)
        else
            local _, nIndex = CoinShop_OutfitCheckRepeat(tSet)
            CoinShop_DeleteOutfitList(nIndex, true)
        end
    end

    local szMsg = g_tStrings.COINSHOP_OUTFIT_SURE_DELETE
    -- local tMsg =
    -- {
    --     bModal = true,
    --     bVisibleWhenHideUI = true,
    --     szName = "outfit_delete_sure",
    --     fnAutoClose = fnAutoClose,
    --     szMessage = szMessage,
    --     {szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = fnSureAction},
    --     {szOption = g_tStrings.STR_HOTKEY_CANCEL},
    -- }
    UIHelper.ShowConfirm(szMsg, fnSureAction)
end

local function GetOutfit(tSet)
    if not tSet.tDataMap then
        local tMap = {}
        for _, tData in ipairs(tSet.tData) do
            tMap[tData.nIndex] = tData
        end
        tSet.tDataMap = tMap
    end

    return tSet.tDataMap
end

local function GetChangeExterior(tOutfit, tChangeList)
    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

    local nCurrentSetID = player.GetCurrentSetID()
    local tExteriorSet = player.GetExteriorSet(nCurrentSetID)

    for i = 1, EXTERIOR_SUB_NUMBER do
        local tData = tOutfit[i]
        local dwExteriorID = 0
        if tData then
            dwExteriorID = tData.dwID
        end
        local nExteriorSub  = Exterior_BoxIndexToExteriorSub(i)
        local dwCurrentExteriorID = tExteriorSet[nExteriorSub]

        if dwExteriorID and dwExteriorID ~= dwCurrentExteriorID then
            local tItem = {}
            tItem.dwGoodsID = dwExteriorID
            tItem.eGoodsType = COIN_SHOP_GOODS_TYPE.EXTERIOR

            local nOwnType = GetCoinShopClient().CheckAlreadyHave(tItem.eGoodsType, tItem.dwGoodsID)
            tItem.bHave = nOwnType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE

            local nTimeType, nTime = player.GetExteriorTimeLimitInfo(dwExteriorID)
            if nTimeType == COIN_SHOP_TIME_LIMIT_TYPE.SEVEN_DAYS_LIMIT or
                nTimeType == COIN_SHOP_TIME_LIMIT_TYPE.FREE_TRY_ON
            then
                tItem.eGoodsType = COIN_SHOP_GOODS_TYPE.RENEW
                tItem.nRenewTime = nTime
            end

            if dwExteriorID > 0 then
                tItem.tPriceInfo = CoinShop_GetExteriorPriceInfo(dwExteriorID)
                tItem.szTime = CoinShop_GetExteriorTime(dwExteriorID)
                local tInfo = GetExterior().GetExteriorInfo(dwExteriorID)
                tItem.bForbiddPeerPay = tInfo.bForbiddPeerPay
                tItem.bForbidDisCoupon = tInfo.bForbidDisCoupon
            end
            tItem.nSubType = Exterior_BoxIndexToSub(i)
            table.insert(tChangeList, tItem)
        end
    end
end

local function GetChangeHair(tOutfit, tChangeList)
    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

    local tCRepresentID = player.GetRepresentID()

    local tHair = tOutfit[COINSHOP_BOX_INDEX.HAIR]
    if not tHair then
        return
    end

    local nHairID = tHair.dwID
    local nCurrentHairID = tCRepresentID[EQUIPMENT_REPRESENT.HAIR_STYLE]
    local nIndex = player.GetEquippedHairCustomDyeingIndex(nCurrentHairID)
    if nIndex == -1 then
        nIndex = 0
    end
    if nHairID ~= nCurrentHairID or (tHair.tColorID and tHair.tColorID[1] ~= nIndex) then
        local tItem = {}
        tItem.dwGoodsID = nHairID
        tItem.nState = ACCOUNT_ITEM_STATUS.NORMAL
        tItem.eGoodsType = COIN_SHOP_GOODS_TYPE.HAIR
        tItem.tPriceInfo = HairShop_GetPriceInfo(HAIR_STYLE.HAIR, nHairID, COIN_SHOP_GOODS_TYPE.HAIR)
        tItem.szTime = HairShop_GetTime(HAIR_STYLE.HAIR, nHairID)
        tItem.nHairDyeingIndex = tHair.tColorID[1]
        local nOwnType = COIN_SHOP_OWN_TYPE.INVALID
        if tItem.dwGoodsID ~= 0 then
            nOwnType = GetCoinShopClient().CheckAlreadyHave(tItem.eGoodsType, tItem.dwGoodsID)
        end
        tItem.bHave = nOwnType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE
        table.insert(tChangeList, tItem)
    end
end

local function GetChangeFaceLift(tOutfit, tChangeList)
    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

    local hManager = GetFaceLiftManager()
    if not hManager then
        return
    end

    local tCRepresentID = player.GetRepresentID()
    local tFace = tOutfit[COINSHOP_BOX_INDEX.FACE]
    if not tFace then
        return
    end
    local nCurrentFaceID = tCRepresentID[EQUIPMENT_REPRESENT.FACE_STYLE]
    local bCurrentUse = player.bEquipLiftedFace
    if tFace.bUseLiftedFace then
        local nIndex = tFace.nIndex
        local nCurrentIndex = hManager.GetEquipedIndex()
        if not bCurrentUse or nIndex ~= nCurrentIndex then
            local tItem = {}
            tItem.bLiftedFace = true
            tItem.nIndex = tFace.dwID
            tItem.nState = ACCOUNT_ITEM_STATUS.NORMAL
            tItem.eGoodsType = COIN_SHOP_GOODS_TYPE.FACE
            tItem.tPriceInfo = CoinShop_GetFaceLiftPriceInfo(0)
            tItem.bHave = true
            table.insert(tChangeList, tItem)
        end
    else
        local nFaceID = tFace.dwID
        if bCurrentUse or nFaceID ~= nCurrentFaceID then
            local tItem = {}
            tItem.dwGoodsID = nFaceID
            tItem.nState = ACCOUNT_ITEM_STATUS.NORMAL
            tItem.eGoodsType = COIN_SHOP_GOODS_TYPE.FACE
            tItem.tPriceInfo = HairShop_GetPriceInfo(HAIR_STYLE.FACE, nFaceID, COIN_SHOP_GOODS_TYPE.FACE)
            tItem.szTime = HairShop_GetTime(HAIR_STYLE.FACE, nFaceID)
            local nOwnType = COIN_SHOP_OWN_TYPE.INVALID
            if tItem.dwGoodsID ~= 0 then
                nOwnType = GetCoinShopClient().CheckAlreadyHave(tItem.eGoodsType, tItem.dwGoodsID)
            end
            tItem.bHave = nOwnType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE
            table.insert(tChangeList, tItem)
        end
    end
end

local function GetChangeBody(tOutfit, tChangeList)
    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

    local hManager = GetFaceLiftManager()
    if not hManager then
        return
    end

    local tBody = tOutfit[COINSHOP_BOX_INDEX.BODY]
    if not tBody then
        return
    end
    local nBody = tBody.dwID
    local nCurrentBody, nIndex = hManager.GetEquipedIndex()
    if nBody ~= nCurrentBody then
        local tItem = {}
        tItem.bBody = true
        tItem.nIndex = nBody
        tItem.nState = ACCOUNT_ITEM_STATUS.NORMAL
        --tItem.eGoodsType = COIN_SHOP_GOODS_TYPE.FACE
        --tItem.tPriceInfo = CoinShop_GetFaceLiftPriceInfo(0)
        tItem.bHave = true
        table.insert(tChangeList, tItem)
    end
end

local function GetChangeNewFace(tOutfit, tChangeList)
    local hManager = GetFaceLiftManager()
    if not hManager then
        return
    end

    local tFace = tOutfit[COINSHOP_BOX_INDEX.NEW_FACE]
    if not tFace then
        return
    end
    local nFaceID = tFace.dwID
    local nCurrentFaceID = hManager.GetEquipedIndex()
    if nFaceID ~= nCurrentFaceID then
        local tItem = {}
        tItem.bNewFace = true
        tItem.nIndex = nFaceID
        tItem.nState = ACCOUNT_ITEM_STATUS.NORMAL
        tItem.bHave = true
        table.insert(tChangeList, tItem)
    end
end

local function GetChangePendant(tOutfit, tChangeList)
    local hRewardsShop = GetRewardsShop()
    if not hRewardsShop then
        return
    end

    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end
    local dwTabType = ITEM_TABLE_TYPE.CUST_TRINKET
    local tItemList = {}
    for nPendantType = 0, PENDENT_SELECTED_POS.TOTAL - 1 do
        local nIndex = CoinShop_PendantTypeToBoxIndex(nPendantType)
        if nIndex then
            local dwCurrentIndex = player.GetSelectPendent(nPendantType)
            local tData = tOutfit[nIndex]
            local dwIndex = 0
            local bChange = true
            if tData then
                dwIndex = tData.dwID
                local tRItem = {}
                tRItem.dwIndex = dwIndex
                tRItem.tColorID = tData.tColorID
                bChange = CoinShopPreview.IsPendantChange(tRItem, nPendantType)
            else
                bChange = dwCurrentIndex ~= 0
            end
            if bChange then
                local tItem = {}
                local dwLogicID = Table_GetRewardsGoodID(ITEM_TABLE_TYPE.CUST_TRINKET, dwIndex)
                tItem.dwGoodsID = dwLogicID or 0
                tItem.nState = ACCOUNT_ITEM_STATUS.NORMAL
                tItem.eGoodsType = COIN_SHOP_GOODS_TYPE.ITEM
                local bHave = true
                if dwLogicID and dwLogicID > 0 then
                    local nHaveType = GetCoinShopClient().CheckAlreadyHave(COIN_SHOP_GOODS_TYPE.ITEM, dwLogicID)
                    bHave = nHaveType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE
                elseif dwIndex > 0 then
                    bHave = player.IsPendentExist(dwIndex)
                end

                tItem.bHave = bHave
                if dwLogicID and dwLogicID > 0 then
                    tItem.tPriceInfo = CoinShop_GetRewardsPriceInfo(dwLogicID)
                    tItem.szTime = CoinShop_GetRewardsTime(dwLogicID)
                    tInfo = hRewardsShop.GetRewardsShopInfo(dwLogicID)
                    tItem.bCanBuyMultiple = tInfo.bCanBuyMultiple
                    tItem.bLimitItem = tInfo.nGlobalCounterID > 0
                    tItem.bForbiddPeerPay = tInfo.bForbiddPeerPay
                    tItem.bForbidDisCoupon = tInfo.bForbidDisCoupon
                    tItem.bRel = tInfo.bIsReal
                end
                if dwIndex > 0 then
                    tItem.dwTabType = dwTabType
                    tItem.dwTabIndex = dwIndex
                end
                tItem.nSubType = CoinShop_PendantPosToSub(nPendantType)
                tItem.nSelectedPos = nPendantType
                table.insert(tChangeList, tItem)
            end
        end
    end
end

local function GetChangePendantPet(tOutfit, tChangeList)
    local hRewardsShop = GetRewardsShop()
    if not hRewardsShop then
        return
    end

    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end
    local dwTabType = ITEM_TABLE_TYPE.CUST_TRINKET
    local tItemList = {}
    local nIndex = COINSHOP_BOX_INDEX.PENDANT_PET
    local tData = tOutfit[nIndex]
    local dwIndex = 0
    local bChange = true
    if tData then
        dwIndex = tData.dwID
        bChange = dwCurrentIndex ~= dwIndex
    else
        bChange = dwCurrentIndex ~= 0
    end
    if bChange then
        local tItem = {}
        local dwLogicID = Table_GetRewardsGoodID(ITEM_TABLE_TYPE.CUST_TRINKET, dwIndex)
        tItem.dwGoodsID = dwLogicID or 0
        tItem.nState = ACCOUNT_ITEM_STATUS.NORMAL
        tItem.eGoodsType = COIN_SHOP_GOODS_TYPE.ITEM
        local bHave = true
        if dwLogicID and dwLogicID > 0 then
            local nHaveType = GetCoinShopClient().CheckAlreadyHave(COIN_SHOP_GOODS_TYPE.ITEM, dwLogicID)
            bHave = nHaveType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE
        elseif dwIndex > 0 then
            bHave = player.IsHavePendentPet(dwIndex)
        end

        tItem.bHave = bHave
        if tData then
            local tPendantPet = player.GetPendentPet(tData.dwID)
            tItem.nPos = tPendantPet.nPos
        end
        tItem.bPendantPet = true
        local tRItem = {}
        tRItem.dwTabType = dwTabType
        tRItem.dwIndex = dwIndex
        tRItem.dwLogicID = dwLogicID
        CoinShop_GetRewardItemInfo(tItem, tRItem)
        tItem.nSubType = Exterior_BoxIndexToSub(nIndex)
        table.insert(tChangeList, tItem)
    end
end

local function GetChangeWeapon(tOutfit, tChangeList)
    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

    local nCurrentSetID = player.GetCurrentSetID()
    local tWeaponExterior = player.GetWeaponExteriorSet(nCurrentSetID)
    local tWeaponBox = CoinShop_GetWeaponIndexArray()
    local tWeaponList = {}
    for i, nWeaponSub in pairs(tWeaponBox) do
        local tData = tOutfit[i]
        local dwWeaponID = 0
        if tData then
            dwWeaponID = tData.dwID
        end
        local dwCurrent = tWeaponExterior[nWeaponSub]
        if dwWeaponID and dwWeaponID ~= dwCurrent then
            local tItem = {}
            tItem.dwGoodsID = dwWeaponID
            tItem.eGoodsType = COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR
            tItem.nEquipPos = nWeaponSub
            local nHaveType = GetCoinShopClient().CheckAlreadyHave(COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR, dwWeaponID)
            local bHave = nHaveType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE
            tItem.bHave = bHave

            if dwWeaponID > 0 then
                local tInfo = CoinShop_GetWeaponExteriorInfo(dwWeaponID)
                tItem.tPriceInfo = CoinShop_GetWeaponPriceInfo(dwWeaponID)
                tItem.szTime = CoinShop_GetWeaponTime(dwWeaponID)
                tItem.bForbiddPeerPay = tInfo.bForbiddPeerPay
                tItem.bForbidDisCoupon = tInfo.bForbidDisCoupon
            end
            table.insert(tChangeList, tItem)
        end
    end
end

local function GetCurrentChange(tOutfit)
    local tChangeList = {}
    GetChangeExterior(tOutfit, tChangeList)
    GetChangeHair(tOutfit, tChangeList)
    GetChangeFaceLift(tOutfit, tChangeList)
    GetChangePendant(tOutfit, tChangeList)
    GetChangeWeapon(tOutfit, tChangeList)
    GetChangePendantPet(tOutfit, tChangeList)
    GetChangeBody(tOutfit, tChangeList)
    GetChangeNewFace(tOutfit, tChangeList)
    return tChangeList
end

function UICharacterPendantExteriorPage:UpdateBuyItemState(tBuy, bSave)
	local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

	local hCoinShopClient = GetCoinShopClient()
	if not hCoinShopClient then
		return
	end
	self.tFaceLift = nil
	self.tOtherSave = {}
	local bAllHave = true
	for i, tBuyItem in ipairs(tBuy) do
		if not tBuyItem.ePayType then
			tBuyItem.ePayType = COIN_SHOP_PAY_TYPE.INVALID
		end
		local nState =  ACCOUNT_ITEM_STATUS.NORMAL
		local nOwnType
		if tBuyItem.bBody then
			nState = ACCOUNT_ITEM_STATUS.NORMAL
			self.tBody = tBuyItem
			if not tBuyItem.bHave then
				bAllHave = false
			end
		elseif tBuyItem.bNewFace then
			nState = ACCOUNT_ITEM_STATUS.NORMAL
			self.tFaceLift = tBuyItem
			if not tBuyItem.bHave then
				bAllHave = false
			end
		elseif tBuyItem.bLiftedFace then
			nState = ACCOUNT_ITEM_STATUS.NORMAL
			self.tFaceLift = tBuyItem
			if not tBuyItem.bHave then
				bAllHave = false
			end
		elseif tBuyItem.bPendantPet then
			if tBuyItem.bHave then
				if tBuyItem.dwTabIndex then
					nState = ACCOUNT_ITEM_STATUS.HAVE
					nOwnType = COIN_SHOP_OWN_TYPE.EQUIP
					tBuyItem.bOtherSave = true
					table.insert(self.tOtherSave, tBuyItem)
				end

				if tBuyItem.dwTabIndex <= 0 then
					nState = ACCOUNT_ITEM_STATUS.OFF
				end
			else
				bAllHave = false
			end
		elseif tBuyItem.dwGoodsID <= 0 then
			if tBuyItem.dwTabType and tBuyItem.dwTabIndex then
				nState = ACCOUNT_ITEM_STATUS.HAVE
				nOwnType = COIN_SHOP_OWN_TYPE.EQUIP
				tBuyItem.bOtherSave = true
				table.insert(self.tOtherSave, tBuyItem)
			else
				nState =  ACCOUNT_ITEM_STATUS.OFF
			end
		else
			nOwnType = GetCoinShopClient().CheckAlreadyHave(tBuyItem.eGoodsType, tBuyItem.dwGoodsID)
			if nOwnType ~= COIN_SHOP_OWN_TYPE.EQUIP and
				nOwnType ~=  COIN_SHOP_OWN_TYPE.PACKAGE and
				nOwnType ~= COIN_SHOP_OWN_TYPE.FREE_TRY_ON
			then
				bAllHave = false
			end
			if nOwnType == COIN_SHOP_OWN_TYPE.NOT_HAVE  then
				nState = ACCOUNT_ITEM_STATUS.NORMAL
			elseif nOwnType == COIN_SHOP_OWN_TYPE.EQUIP or
				nOwnType ==  COIN_SHOP_OWN_TYPE.PACKAGE or
				nOwnType == COIN_SHOP_OWN_TYPE.FREE_TRY_ON
			then
				if bSave then
					nState = ACCOUNT_ITEM_STATUS.HAVE
				else
					nState =  ACCOUNT_ITEM_STATUS.NORMAL
				end
			else
				nState = ACCOUNT_ITEM_STATUS.CAN_NOT_SAVE
			end
		end
		tBuyItem.nState = nState
		tBuyItem.nOwnType = nOwnType
	end

	return bAllHave
end

function UICharacterPendantExteriorPage:DealBodySave()
	if not self.tBody then
		return
	end

	local tBody = self.tBody
	if tBody.bHave then
		CoinShopData.EquipBody(tBody.nIndex)
	elseif tBody.nIndex then
		return CoinShopData.ReplaceBody(tBody.nIndex, tBody.tBody)
	else
		return CoinShopData.BuyBody(tBody.tBody)
	end
	CoinShopData.tBody = nil
end

function UICharacterPendantExteriorPage:DealFaceLift()
	if not self.tFaceLift then
		return
	end

	local tFaceLift = self.tFaceLift
	if tFaceLift.bHave then
		CoinShopData.EquipLiftedFace(tFaceLift.nIndex, tFaceLift.bNewFace)
	else
		CoinShopData.BuyFaceLift(tFaceLift.tFaceData, tFaceLift.nIndex, tFaceLift.nPrice)
	end
	CoinShopData.tFaceLift = nil
end

function UICharacterPendantExteriorPage:DecalOtherSave()
	local tOtherSave = self.tOtherSave
	if not tOtherSave or #tOtherSave <= 0 then
		return
	end

	local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

	for _, tBuyItem in ipairs(tOtherSave) do
		local hItemInfo = GetItemInfo(tBuyItem.dwTabType, tBuyItem.dwTabIndex)
		if tBuyItem.bPendantPet then
			hPlayer.EquipPendentPet(tBuyItem.dwTabIndex)
			if tBuyItem.dwTabIndex > 0 then
				hPlayer.ChangePendentPetPos(tBuyItem.dwTabIndex, tBuyItem.nPos)
			end
		elseif hItemInfo.nGenre == ITEM_GENRE.EQUIPMENT then
            if IsPendantItem(hItemInfo) then
	        	local tColorID = tBuyItem.tColorID
		        if tColorID and (tColorID[1]~= 0 or tColorID[1]~= 0 or tColorID[2]~= 0) then
		        	hPlayer.SelectColorPendent(hItemInfo.nSub, tBuyItem.dwTabIndex, tColorID[1], tColorID[2], tColorID[3])
                elseif tBuyItem.nSelectedPos then
					hPlayer.SelectPendent(hItemInfo.nSub, tBuyItem.dwTabIndex, tBuyItem.nSelectedPos)
		        else
		        	hPlayer.SelectPendent(hItemInfo.nSub, tBuyItem.dwTabIndex)
		        end
                local nRepresentSub = Exterior_SubToRepresentSub(hItemInfo.nSub)
                local nRepresentID = hItemInfo.nRepresentID
                if tBuyItem.nSelectedPos then
				 	nRepresentSub = CoinShop_PendantTypeToRepresentSub(tBuyItem.nSelectedPos)
				end
                CoinShopData.CustomPendantSetLocalDataToPlayer(nRepresentSub, nRepresentID)
	        end
        end
	end
end

function UICharacterPendantExteriorPage:Apply()
    local tSet = self:GetCurSelectSet()
    local tOutfit = GetOutfit(tSet)
    local tbBuySaveList = GetCurrentChange(tOutfit)

    local bAllHave = self:UpdateBuyItemState(tbBuySaveList, true)
    if not bAllHave then
        return
    end

    local bEnd = self:DealBodySave()
	if bEnd then
		return
	end
	self:DealFaceLift()
	self:DecalOtherSave()

    local tbSave = {}
    for _, tBuyItem in ipairs(tbBuySaveList) do
        if not tBuyItem.bLiftedFace and not tBuyItem.bOtherSave and not tBuyItem.bBody and not tBuyItem.bNewFace then
			table.insert(tbSave, tBuyItem)
		end
    end
    if #tbSave > 0 then
        local nRetCode = GetCoinShopClient().Save(tbSave)
        if nRetCode == COIN_SHOP_ERROR_CODE.SUCCESS then
            for _, tbInfo in ipairs(tbSave) do
                if tbInfo.eGoodsType == 1 then
                    -- 发型需要隐藏帽子
                    PlayerData.HideHat(true)
                end
            end
            --应用本地的挂件自定义数据
            for _, tbItem in pairs(tbSave) do
                if tbItem.bHave and tbItem.dwTabType == ITEM_TABLE_TYPE.CUST_TRINKET then
                    local nType = Exterior_SubToRepresentSub(tbItem.nSubType)
                    if nType and IsCustomPendantType(nType) then
                        local hItemInfo = GetItemInfo(tbItem.dwTabType, tbItem.dwTabIndex)
                        if hItemInfo then
                            local nRepresentID = hItemInfo.nRepresentID
                            if tbItem.nSelectedPos then
						        nType = CoinShop_PendantTypeToRepresentSub(tbItem.nSelectedPos)
					        end
                            CoinShopData.CustomPendantSetLocalDataToPlayer(nType, nRepresentID)
                        end
                    end
                end
            end
            TipsHelper.ShowNormalTip(g_tStrings.tCoinShopNotify[nRetCode])
        elseif nRetCode == COIN_SHOP_ERROR_CODE.NOT_HAVE_PREORDER_COUPON then
            -- CoinShopData.OnPerorderError(tbSave)
        else
            TipsHelper.ShowNormalTip(g_tStrings.tCoinShopNotify[nRetCode])
        end
    end
end

function UICharacterPendantExteriorPage:GetCurSelectSet()
    local tbSet = self.tbList[self.nCurSelectIndex]
    return tbSet
end

function UICharacterPendantExteriorPage:UpdateCellStorageState(tSet)
    for _, script in ipairs(self.tbScriptCell) do
        if script.tbInfo == tSet then
            script:UpdateOutfitStorageState()
            break
        end
    end
end

return UICharacterPendantExteriorPage