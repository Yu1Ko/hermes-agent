local function DealWithClassString(tTitle)
    if not tTitle or tTitle.tMyExteriorClass then
        return
    end
    if tTitle.szMyExteriorClass and tTitle.szMyExteriorClass ~= "" then
        local tVar = SplitString(tTitle.szMyExteriorClass, ";")
        tTitle.tMyExteriorClass = tVar
    end
end

local function IsClassMatch(tTitle, nClass)
    if not tTitle then
        return true
    end
    if tTitle.tMyExteriorClass then
        for _, v in pairs(tTitle.tMyExteriorClass) do
            if tonumber(v) == nClass then
                return true
            end
        end
        return false
    end
    return nClass == tTitle.nRewardsClass
end

CoinShopData = CoinShopData or {className = "CoinShopData"}
local self = CoinShopData

CoinShopData.tViewClear =
{
    EQUIPMENT_REPRESENT.HELM_STYLE,
    EQUIPMENT_REPRESENT.CHEST_STYLE,
    EQUIPMENT_REPRESENT.BANGLE_STYLE,
    EQUIPMENT_REPRESENT.WAIST_STYLE,
    EQUIPMENT_REPRESENT.BOOTS_STYLE,
    EQUIPMENT_REPRESENT.FACE_EXTEND,
    EQUIPMENT_REPRESENT.BACK_EXTEND,
    EQUIPMENT_REPRESENT.WAIST_EXTEND,
    EQUIPMENT_REPRESENT.WEAPON_STYLE,
    EQUIPMENT_REPRESENT.BIG_SWORD_STYLE,
    EQUIPMENT_REPRESENT.GLASSES_EXTEND,
    EQUIPMENT_REPRESENT.L_GLOVE_EXTEND,
    EQUIPMENT_REPRESENT.R_GLOVE_EXTEND,
    EQUIPMENT_REPRESENT.HEAD_EXTEND,
    EQUIPMENT_REPRESENT.HEAD_EXTEND1,
    EQUIPMENT_REPRESENT.HEAD_EXTEND2,
}

CoinShopData.bClickActivity = false

function CoinShopData.GetSubRepresent(dwID)
    if not g_pClientPlayer then
        return
    end

    local hExterior = GetExterior()
    if not hExterior then
        return
    end

    local tRepresentID = Role_GetRepresentID(g_pClientPlayer)
    for _, nRepresentSub in ipairs(CoinShopData.tViewClear) do
        tRepresentID[nRepresentSub] = 0
    end

    local tExteriorInfo = hExterior.GetExteriorInfo(dwID)
    local nRepresentSub = Exterior_SubToRepresentSub(tExteriorInfo.nSubType)
    local nRepresentColor = Exterior_RepresentSubToColor(nRepresentSub)
    local nRepresentDyeing = Exterior_RepresentSubToDyeing(nRepresentSub)
    tRepresentID[nRepresentSub] = tExteriorInfo.nRepresentID
    tRepresentID[nRepresentColor] = tExteriorInfo.nColorID
    if nRepresentDyeing then
        local nDyeingID = g_pClientPlayer.GetExteriorDyeingID(dwID)
        tRepresentID[nRepresentDyeing] = nDyeingID
    end

    return tRepresentID
end

function CoinShopData.GetSetRepresent(tSub)
    if not g_pClientPlayer then
        return
    end

    local hExterior = GetExterior()
    if not hExterior then
        return
    end
    local tRepresentID = g_pClientPlayer.GetRepresentID()
    local bUseLiftedFace = g_pClientPlayer.bEquipLiftedFace
    local tFaceData = g_pClientPlayer.GetEquipLiftedFaceData()
    tRepresentID.bUseLiftedFace = bUseLiftedFace
    tRepresentID.tFaceData = tFaceData
    local bShowFlag = GetFaceLiftManager().GetDecorationShowFlag()
    if not bShowFlag and tFaceData then
        tFaceData.nDecorationID = 0
    end

    for _, nRepresentSub in ipairs(CoinShopData.tViewClear) do
        tRepresentID[nRepresentSub] = 0
    end

    for _, dwID in ipairs(tSub) do
        local tExteriorInfo = hExterior.GetExteriorInfo(dwID)
        local nRepresentSub = Exterior_SubToRepresentSub(tExteriorInfo.nSubType)
        local nRepresentColor = Exterior_RepresentSubToColor(nRepresentSub)
        local nRepresentDyeing = Exterior_RepresentSubToDyeing(nRepresentSub)
        tRepresentID[nRepresentSub] = tExteriorInfo.nRepresentID
        tRepresentID[nRepresentColor] = tExteriorInfo.nColorID
        if nRepresentDyeing then
            local nDyeingID = g_pClientPlayer.GetExteriorDyeingID(dwID)
            tRepresentID[nRepresentDyeing] = nDyeingID
        end
    end
    local bPreviewHair = Storage.CoinShop.bPreviewMatchHair
    if bPreviewHair then
        local dwID = tSub[1]
        local nMatchHair = CoinShop_GetMatchHair(dwID)
        if nMatchHair then
            tRepresentID[EQUIPMENT_REPRESENT.HAIR_STYLE] = nMatchHair
        end
    end
    return tRepresentID
end

local tRepresentSub =
{
    EQUIPMENT_REPRESENT.HELM_STYLE,
    EQUIPMENT_REPRESENT.CHEST_STYLE,
    EQUIPMENT_REPRESENT.BANGLE_STYLE,
    EQUIPMENT_REPRESENT.WAIST_STYLE,
    EQUIPMENT_REPRESENT.BOOTS_STYLE,
    EQUIPMENT_REPRESENT.FACE_EXTEND,
    EQUIPMENT_REPRESENT.BACK_EXTEND,
    EQUIPMENT_REPRESENT.WAIST_EXTEND,
    EQUIPMENT_REPRESENT.L_SHOULDER_EXTEND,
    EQUIPMENT_REPRESENT.R_SHOULDER_EXTEND,
    EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND,
    EQUIPMENT_REPRESENT.BAG_EXTEND,
    EQUIPMENT_REPRESENT.WEAPON_STYLE,
    EQUIPMENT_REPRESENT.BIG_SWORD_STYLE,
    EQUIPMENT_REPRESENT.PENDENT_PET_STYLE,
    EQUIPMENT_REPRESENT.PENDENT_PET_POS,
    EQUIPMENT_REPRESENT.GLASSES_EXTEND,
    EQUIPMENT_REPRESENT.L_GLOVE_EXTEND,
    EQUIPMENT_REPRESENT.R_GLOVE_EXTEND,
    EQUIPMENT_REPRESENT.HEAD_EXTEND,
    EQUIPMENT_REPRESENT.HEAD_EXTEND1,
    EQUIPMENT_REPRESENT.HEAD_EXTEND2,

}

function CoinShopData.ClearView(tRepresentID)
    for _, nRepresentSub in ipairs(tRepresentSub) do
        tRepresentID[nRepresentSub] = 0
    end
end

function CoinShopData.GetOutfitRepresent(tSet)
    if not g_pClientPlayer then
        return
    end

    local tRepresentID = Role_GetRepresentID(g_pClientPlayer)
    CoinShopData.ClearView(tRepresentID)
    local tWeaponBox = CoinShop_GetWeaponIndexArray()
    local bHideHat = tSet.bHideHat
    for _, tData in ipairs(tSet.tData) do
        local dwID = tData.dwID
        local nIndex = tData.nIndex
        local nSub = Exterior_BoxIndexToExteriorSub(nIndex)

        if dwID and dwID > 0 then
            if nSub then
                CoinShopData.UpdateExterior(tRepresentID, dwID, bHideHat)
            --elseif nIndex == COINSHOP_BOX_INDEX.ITEM then -- item did not save
            elseif nIndex == COINSHOP_BOX_INDEX.HAIR then
                CoinShopData.UpdateHair(tRepresentID, dwID)
            elseif nIndex == COINSHOP_BOX_INDEX.FACE then
                if tData.bUseLiftedFace then
                    CoinShopData.UpdateLiftedFace(tRepresentID, dwID)
                else
                    CoinShopData.UpdateFace(tRepresentID, dwID)
                end
            elseif nIndex == COINSHOP_BOX_INDEX.PENDANT_PET then
                CoinShopData.UpdatePendantPet(tRepresentID, dwID)
            elseif nIndex == COINSHOP_BOX_INDEX.BODY then
                CoinShopData.UpdateBody(tRepresentID, dwID)
            elseif CoinShop_BoxIndexToPendantType(nIndex) then
                CoinShopData.UpdatePendant(tRepresentID, dwID, tData.tColorID, nIndex)
            elseif tWeaponBox[nIndex] then
                CoinShopData.UpdateWeapon(tRepresentID, dwID)
            elseif nIndex == COINSHOP_BOX_INDEX.NEW_FACE then
                CoinShopData.UpdateNewFace(tRepresentID, dwID)
            end
        end
    end

    return tRepresentID
end

function CoinShopData.UpdateHair(tRepresentID, nHair)
	tRepresentID[EQUIPMENT_REPRESENT.HAIR_STYLE] = nHair
end

function CoinShopData.UpdateFace(tRepresentID, nFace)
	tRepresentID[EQUIPMENT_REPRESENT.FACE_STYLE] = nFace
    tRepresentID.bUseLiftedFace = false
    tRepresentID.tFaceData = nil
    tRepresentID.nEquipIndex = nil
end

function CoinShopData.GetLiftedFaceData(nIndex)
	if not g_pClientPlayer then
		return
	end

	local tFaceData = g_pClientPlayer.GetLiftedFaceDataByIndex(nIndex)
	return tFaceData
end

function CoinShopData.GetNewFaceData(nIndex)
	if not g_pClientPlayer then
		return
	end

	local tFaceData = g_pClientPlayer.GetLiftedFaceDataByIndex(nIndex)
	return tFaceData
end

function CoinShopData.UpdateLiftedFace(tRepresentID, nIndex, FaceData)
    local tFaceData = FaceData
    if not tFaceData then
	   tFaceData = CoinShopData.GetLiftedFaceData(nIndex)
    end
	if not tFaceData then
		return
	end

	local bShowFlag = GetFaceLiftManager().GetDecorationShowFlag()
    if not bShowFlag and tFaceData then
        tFaceData.nDecorationID = 0
    end

	tRepresentID.bUseLiftedFace = true
    tRepresentID.tFaceData = tFaceData
end

function CoinShopData.UpdateNewFace(tRepresentID, nIndex, FaceData)
    local tFaceData = FaceData
    if not tFaceData then
	   tFaceData = CoinShopData.GetNewFaceData(nIndex)
    end
	if not tFaceData then
		return
	end

	local bShowFlag = GetFaceLiftManager().GetDecorationShowFlag()
    if not bShowFlag and tFaceData then
        tFaceData.tDecoration = {
            [FACE_LIFT_DECORATION_TYPE.MOUTH] = {
                nShowID = 0,
                nColorID = 0,
            },
            [FACE_LIFT_DECORATION_TYPE.NOSE] = {
                nShowID = 0,
                nColorID = 0,
            },
        }
    end

	tRepresentID.bUseLiftedFace = true
    tRepresentID.tFaceData = tFaceData
end

function CoinShopData.UpdateExterior(tRepresentID, dwExteriorID, bHideHat)
	if dwExteriorID <= 0 then
		return
	end
	local tExteriorInfo = GetExterior().GetExteriorInfo(dwExteriorID)
    local nSubType = tExteriorInfo.nSubType
    if nSubType == EQUIPMENT_SUB.HELM and bHideHat then
        return
    end

    local nRepresentSub = Exterior_SubToRepresentSub(nSubType)
    local nRepresentColor = Exterior_RepresentSubToColor(nRepresentSub)
    tRepresentID[nRepresentSub] = tExteriorInfo.nRepresentID
    tRepresentID[nRepresentColor] = tExteriorInfo.nColorID
end

function CoinShopData.UpdatePendant(tRepresentID, dwIndex, tColorID, nIndex)
	if dwIndex <= 0 then
		return
	end
	local hPendant = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, dwIndex)
    local nRepresentSub
    if nIndex then
        nRepresentSub = Exterior_BoxIndexToRepresentSub(nIndex)
    else
        nRepresentSub = ExteriorView_GetRepresentSub(hPendant.nSub, hPendant.nDetail)
    end
    tRepresentID[nRepresentSub] = hPendant.nRepresentID
    if nRepresentSub == EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND and tColorID then
        tRepresentID[EQUIPMENT_REPRESENT.BACK_CLOAK_COLOR1] = tColorID[1]
        tRepresentID[EQUIPMENT_REPRESENT.BACK_CLOAK_COLOR2] = tColorID[2]
        tRepresentID[EQUIPMENT_REPRESENT.BACK_CLOAK_COLOR3] = tColorID[3]
    end
end

function CoinShopData.UpdatePendantPet(tRepresentID, dwIndex)
   if dwIndex <= 0 then
        return
    end
    local hPendantPet = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, dwIndex)
    local nRepresentSub = ExteriorView_GetRepresentSub(hPendantPet.nSub, hPendantPet.nDetail)
    tRepresentID[nRepresentSub] = hPendantPet.nRepresentID
    tRepresentID[EQUIPMENT_REPRESENT.PENDENT_PET_POS] = 0
end

function CoinShopData.GetPlayerBodyIndexData(dwIndex)
    if not g_pClientPlayer then
		return
	end

    local tList = g_pClientPlayer.GetBodyBoneList()
    for nIndex, tBody in pairs(tList) do
        if nIndex == dwIndex then
            return tBody
        end
    end
end

function CoinShopData.UpdateBody(tRepresentID, dwIndex)
    if dwIndex <= 0 then
         return
     end
    local tData = CoinShopData.GetPlayerBodyIndexData(dwIndex)
    tRepresentID.tBody = tData
 end

function CoinShopData.UpdateWeapon(tRepresentID, dwWeaponID)
	if dwWeaponID <= 0 then
		return
	end
	local hPlayer = GetClientPlayer()
	local nIndex = CoinShop_GetWeaponIndex(dwWeaponID)
    local tExteriorInfo = CoinShop_GetWeaponExteriorInfo(dwWeaponID)

    local nRepresentSub = Exterior_BoxIndexToRepresentSub(nIndex)
    local nSubType = Exterior_BoxIndexToSub(nIndex)
    local nRepresentColor = Exterior_RepresentSubToColor(nRepresentSub)
    local tWeaponEnchant = CoinShop_GetWeaponEnchantArray()

    local nEquipSub = Exterior_RepresentSubToEquipSub(nRepresentSub)
    local nEnchant1, nEnchant2 = unpack(tWeaponEnchant[nIndex])
    local hItem = ItemData.GetPlayerItem(hPlayer, INVENTORY_INDEX.EQUIP, nEquipSub)
    local bHideBigSword = nRepresentSub == EQUIPMENT_REPRESENT.BIG_SWORD_STYLE and
            hPlayer.dwForceID ~= FORCE_TYPE.CANG_JIAN and hPlayer.dwForceID ~= 0
    if not hItem or dwWeaponID > 0 or bHideBigSword then
        tRepresentID[nRepresentSub] = tExteriorInfo.nRepresentID
        tRepresentID[nRepresentColor] = tExteriorInfo.nColorID
        tRepresentID[nEnchant1] = tExteriorInfo.nEnchantRepresentID1
        tRepresentID[nEnchant2] = tExteriorInfo.nEnchantRepresentID2
        return
    end

    local tEnchant = hItem.GetEnchantRepresentID()
    tRepresentID[nRepresentSub] = hItem.nRepresentID
    tRepresentID[nRepresentColor] = hItem.nColorID
    tRepresentID[nEnchant1] = tEnchant[1]
    tRepresentID[nEnchant2] = tEnchant[2]
end

function CoinShopData.UpdateFromItem(tRepresentID, dwTabType, dwTabIndex, tColor, bHideHat)
    local hItemInfo = GetItemInfo(dwTabType, dwTabIndex)
    if not hItemInfo then
        return
    end
    if hItemInfo.nGenre == ITEM_GENRE.EQUIPMENT and IsPendantItem(hItemInfo) then
        CoinShopData.UpdatePendant(tRepresentID, dwTabIndex, tColor)
    elseif hItemInfo.nGenre == ITEM_GENRE.EQUIPMENT and IsPendantPetItem(hItemInfo) then
        CoinShopData.UpdatePendantPet(tRepresentID, dwTabIndex)
    elseif hItemInfo.nGenre == ITEM_GENRE.COIN_SHOP_QUANTITY_LIMIT_ITEM then
        CoinShopData.UpdateFromLimitItem(tRepresentID, hItemInfo, tItem, tColor, bHideHat)
    end
end

function CoinShopData.UpdateFromLimitItem(tRepresentID, hItemInfo, tItem, tColor, bHideHat)
    if hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.PENDENT then
        CoinShopData.UpdatePendant(tRepresentID, hItemInfo.nDetail, tColor)
    elseif hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.PENDENT_PET then
        CoinShopData.UpdatePendantPet(tRepresentID, hItemInfo.nDetail)
    elseif hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.EXTERIOR then
        CoinShopData.UpdateExterior(tRepresentID, hItemInfo.nDetail, bHideHat)
    elseif hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.HAIR then
        CoinShopData.UpdateHair(tRepresentID, hItemInfo.nDetail)
    elseif hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.PACK then
        CoinShopData.UpdateFromMultiItem(tRepresentID, hItemInfo.nDetail, bHideHat)
    end
end

function CoinShopData.UpdateFromMultiItem(tRepresentID, nID, bHideHat)
    local tMultiItem = CoinShop_GetLimitView(nID)
    for _, tViewItem in ipairs(tMultiItem) do
        if tViewItem.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.PENDENT then
            CoinShopData.UpdatePendant(tRepresentID, tViewItem.dwLogicID)
        elseif tViewItem.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.PENDENT_PET then
            CoinShopData.UpdatePendantPet(tRepresentID, tViewItem.dwLogicID)
        elseif tViewItem.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.EXTERIOR then
            CoinShopData.UpdateExterior(tRepresentID, tViewItem.dwLogicID, bHideHat)
        elseif tViewItem.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.HAIR then
            CoinShopData.UpdateHair(tRepresentID, tViewItem.dwLogicID)
        end
    end
end

-- 获取积分回馈
function CoinShopData.GetRewards()
    if not g_pClientPlayer then return 0 end
    return g_pClientPlayer.GetRewards()
end

function CoinShopData.GetVouchers()
    return GetFaceLiftManager().GetVouchers()
end

function CoinShopData.GetCurrentCoinShopVoucher()
    return GetCurrentCoinShopVoucher()  -- nil or {dwVoucherID =11, nCount = 10, nCreateTime = 111, nExistDuration = 2, nBeginTime = 111, nEndTime = 112}
end

----------------------------------------------UI辅助接口----------------------------------------------
local m_nRefreshTime = nil
local m_bDataChanged = false
local m_tShopCache =
{
    Virtal = {},
    Entity = {},
    Pet = {},
    Horse = {},
    Exterior = {},
    CollectExterior = {},
    Rewards = {},
    Hair = {},
    Face = {},
    Weapon = {},
}

local m_tHairList = nil
local m_tFaceList = nil
local m_tHairShopMap = nil
local m_tHairLabel = nil
local m_nFaceLabel = nil
local m_tHairShopLabels = {}
local m_tGenreList = {}
local m_tMyGenreList = {}
local m_tWeaponFilterType
local m_tAdornmentSet = {}
local m_tRewardSet = {}

local m_bIsBuying = false

function CoinShopData.ChangeRefreshTimeByInfo(tInfo)
    local nDisStartTime, nDisEndTime = CoinShop_GetPriceDisTime(tInfo)
    local nSecondDisStartTime, nSecondDisEndTime = CoinShop_GetSecondDisTime(tInfo)
    if tInfo.nGameWorldStartDuration > 0 then
        local nStartTime = CoinShop_GetStartTime(tInfo)
        self.ChangeRefreshTime(nStartTime)
    end
    self.ChangeRefreshTime(tInfo.nStartTime)
    self.ChangeRefreshTime(tInfo.nEndTime)
    self.ChangeRefreshTime(nDisStartTime)
    self.ChangeRefreshTime(nDisEndTime)
    self.ChangeRefreshTime(nSecondDisStartTime)
    self.ChangeRefreshTime(nSecondDisEndTime)
end

function CoinShopData.ChangeRefreshTime(nChangeTime)
    if nChangeTime < 0 then
        return
    end
    local nTime = GetGSCurrentTime()
    if nChangeTime > nTime then
        if m_nRefreshTime then
            m_nRefreshTime = math.min(m_nRefreshTime, nChangeTime)
        else
            m_nRefreshTime = nChangeTime
        end
    end
end

function CoinShopData.IsNeedRefresh()
    local nTime = GetGSCurrentTime()
    if (m_nRefreshTime and nTime > m_nRefreshTime) or m_bDataChanged then
        return true
    end

    return false
end

function CoinShopData.CheckRefresh()
    local bRefresh = self.IsNeedRefresh()
    if bRefresh then
        m_tShopCache.Entity = {}
        m_tShopCache.Virtal = {}
        m_tShopCache.Pet = {}
        m_tShopCache.Horse = {}
        m_tShopCache.Exterior = {}
        m_tShopCache.Rewards = {}
        m_tShopCache.Hair = {}
        m_tShopCache.Face = {}
        m_tShopCache.Weapon = {}
        m_bDataChanged = false
        m_nRefreshTime = nil
        m_tHairLabel = nil
        m_nFaceLabel = nil
        m_tHairShopLabels = {}
        m_tRewardSet = {}
        LOG.INFO("CoinShopCache.Refresh()")
    end
end

function CoinShopData.IsRewardsTabTitle(nType, nClass)
    -- 遗失的美好和小玩意儿单独拎出来
    if nType == COIN_SHOP_GOODS_TYPE.ITEM and (nClass == 7 or nClass == 10 or nClass == REWARDS_CLASS.EFFECT) then
        return true
    else
        return false
    end
end

function CoinShopData.IsHomeLimitTitle(nType, nClass)
    return nType == COIN_SHOP_GOODS_TYPE.ITEM and nClass == 2
end

function CoinShopData.IsHomeTitle(nType, nClass)
    if nType == 0 and nClass == 0 then
        return true
    elseif nType == COIN_SHOP_GOODS_TYPE.ITEM and (nClass == 1 or nClass == 2 or nClass == 14) then
        return true
    else
        return false
    end
end

function CoinShopData.IsFilterTitle(nType, nClass, bShop)
    if bShop == nil then
        bShop = true
    end
    if nType == COIN_SHOP_GOODS_TYPE.ITEM and (nClass >= 101 and nClass <= 106) then
        return true
    end
    if bShop and (nType == COIN_SHOP_GOODS_TYPE.HAIR or  nType == COIN_SHOP_GOODS_TYPE.FACE) then
        return true
    end
    -- if bShop and nType == COIN_SHOP_GOODS_TYPE.EXTERIOR and nClass == 6 then
    --     return true
    -- end
    return false
end

function CoinShopData.GetHomeList()
    local tShopList = {}
    local tFlag = {}
    local nTitleCount = g_tTable.CoinShop_Title:GetRowCount()
    for i = 2, nTitleCount, 1 do
        local tLine = g_tTable.CoinShop_Title:GetRow(i)
        if not tFlag[tLine.nTitleClass] then
            tFlag[tLine.nTitleClass] = tLine
            tLine.tList = {}
            table.insert(tShopList, tLine)
        else
            local tList = tFlag[tLine.nTitleClass].tList
            local bShow = self.IsHomeTitle(tLine.nType, tLine.nRewardsClass)
            if bShow then
                if tLine.bHideWhenNoItem then
                    if tLine.nType == COIN_SHOP_GOODS_TYPE.ITEM then
                        local tList = self.GetRewardsList(tLine.nRewardsClass, tLine.bRewardSet)
                        bShow = #tList > 0
                    end
                end
            end
            if bShow then
                table.insert(tList, tLine)
            end
        end
    end

    local nCount = #tShopList
    for i = nCount, 1, -1 do
        local tClass = tShopList[i]
        if #tClass.tList == 0 then
            table.remove(tShopList, i)
        end
    end
    return tShopList
end

function CoinShopData.GetList()
    local hPlayer = GetClientPlayer()
    local tShopList = {}
    local bShowWeapon = hPlayer and hPlayer.dwForceID ~= 0
    local tFlag = {}
    local nTitleCount = g_tTable.CoinShop_Title:GetRowCount()
    for i = 2, nTitleCount, 1 do
        local tLine = g_tTable.CoinShop_Title:GetRow(i)
        if self.IsRewardsTabTitle(tLine.nType, tLine.nRewardsClass) then
            local tList = self.GetRewardsList(tLine.nRewardsClass)
            local bShow = #tList > 0
            if bShow then
                tLine.tList = {}
                tLine.bRewardsTab = true
                table.insert(tShopList, tLine)
                for _, tTab in ipairs(tList) do
                    local nLabel = 0
                    for _, tRewardsItem in ipairs(tTab) do
                        if tRewardsItem.nLabel and tRewardsItem.nLabel == EXTERIOR_LABEL.NEW then
                            nLabel = EXTERIOR_LABEL.NEW
                            break
                        end
                    end
                    table.insert(tLine.tList, {
                        szName = tTab.szName,
                        nType = tLine.nType,
                        nRewardsClass = tLine.nRewardsClass,
                        nSubClass = tTab.nSubClass,
                        nLabel = nLabel,
                    })
                end
            end
        elseif not tFlag[tLine.nTitleClass] then
            tFlag[tLine.nTitleClass] = tLine
            tLine.tList = {}
            table.insert(tShopList, tLine)
        else
            local tList = tFlag[tLine.nTitleClass].tList
            local bShow = not self.IsFilterTitle(tLine.nType, tLine.nRewardsClass, true) and not self.IsHomeTitle(tLine.nType, tLine.nRewardsClass)
            if bShow then
                if tLine.nType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
                    bShow = bShowWeapon
                elseif tLine.nType == COIN_SHOP_GOODS_TYPE.HAIR then
                    bShow = true
                    tLine.bDisable = not CoinShop_CanChangeHair()
                elseif tLine.nType == COIN_SHOP_GOODS_TYPE.HAIR or tLine.nType == 0 then
                    bShow = false
                end
            end
            if bShow then
                if tLine.bHideWhenNoItem then
                    if tLine.nType == COIN_SHOP_GOODS_TYPE.ITEM then
                        local tList = self.GetRewardsList(tLine.nRewardsClass, tLine.bRewardSet)
                        bShow = #tList > 0
                    elseif tLine.nType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
                        local tList = self.GetExteriorList(tLine.nRewardsClass)
                        bShow = #tList.tSetList > 0
                    elseif tLine.nType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
                        local tList = self.GetShopWeapon()
                        bShow = #tList > 0
                    elseif tLine.nType == COIN_SHOP_GOODS_TYPE.IDLE_ACTION then
                        bShow = false
                    end
                end
            end
            if bShow then
                table.insert(tList, tLine)
            end
        end
    end

    local nCount = #tShopList
    for i = nCount, 1, -1 do
        local tClass = tShopList[i]
        if #tClass.tList == 0 then
            table.remove(tShopList, i)
        end
    end

    CoinShopData.CheckAddHairTitle(tShopList)

    return tShopList
end

local tSubHairTitle = {
    [HAIR_SHOW_TYPE.ALL]     	= "全部",
    [HAIR_SHOW_TYPE.BLACK]      = "黑发",
    [HAIR_SHOW_TYPE.WHITE]   	= "白发",
    [HAIR_SHOW_TYPE.GOLD]    	= "金发",
    -- [HAIR_SHOW_TYPE.GIFT]		= "福袋发",
    -- "套发",
    -- "红发",
    -- "异色发",
}
function CoinShopData.CheckAddHairTitle(tbList)
    local tTitleInfo = CoinShop_GetTitleInfo(COIN_SHOP_GOODS_TYPE.HAIR, 0)
    local tHairTitle = Lib.copyTab(tTitleInfo)
    tHairTitle.szTitleName = tHairTitle.szName
    tHairTitle.bDisable = not CoinShop_CanChangeHair()

    tHairTitle.tList = {}
    local tHairMap = CoinShopData.GetShopHairList()
    for i, szTitle in pairs(tSubHairTitle) do
        if tHairMap[i] then
            local tTitleInfo = Lib.copyTab(tTitleInfo)
            tTitleInfo.szName = UIHelper.UTF8ToGBK(szTitle)
            tTitleInfo.nSubClass = i
            table.insert(tHairTitle.tList, tTitleInfo)
        end
    end

    table.sort(tHairTitle.tList, function(a, b)
        return a.nSubClass < b.nSubClass
    end)

    if BuildHairData.bPrice then
        for i = 1, #tHairTitle.tList, 1 do
            local tListInfo = tHairTitle.tList[i]
            local tbConfig = BuildHairData.GetHairConfigWithClassIndex(i, 1)

            tListInfo.nLabel = 0
            for _, tbInfo in ipairs(tbConfig) do
                local nHairID = BuildHairData.GetHairStyleByClassIndexValue(tbInfo.nClassIndex, tbInfo.nID)
                local szLeftTime = CoinShopHair.GetCountDownInfo(HAIR_STYLE.HAIR, nHairID)

                if not string.is_nil(szLeftTime) then
                    tListInfo.nLabel = math.max(tListInfo.nLabel, EXTERIOR_LABEL.TIME_LIMIT)
                end

                local hPlayer = GetClientPlayer()
                if hPlayer then
                    local tInfo = GetHairShop().GetHairPrice(hPlayer.nRoleType, HAIR_STYLE.HAIR, nHairID)
                    if tInfo then
                        local bDis = CoinShop_IsPriceDis(tInfo)
                        if bDis then
                            tListInfo.nLabel = math.max(tListInfo.nLabel, EXTERIOR_LABEL.DISCOUNT)
                        end
                    end
                end
            end
        end
    end

    for i, tTitleInfo in ipairs(tbList) do
        if tTitleInfo.nTitleClass == 8 then
            table.insert(tbList, i + 1, tHairTitle)
            return
        end
    end

    table.insert(tbList, tHairTitle)
end


function CoinShopData.GetMyRoleList()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return {}
    end
    local tMyList = {}
    local bShowWeapon = hPlayer and hPlayer.dwForceID ~= 0
    local tFlag = {}
    local nTitleCount = g_tTable.CoinShop_Title:GetRowCount()
    for i = 2, nTitleCount, 1 do
        local tLine = g_tTable.CoinShop_Title:GetRow(i)
        if not tFlag[tLine.nTitleClass] then
            tFlag[tLine.nTitleClass] = tLine
            tLine.tList = {}
            table.insert(tMyList, tLine)
        else
            local tList = tFlag[tLine.nTitleClass].tList
            local bShow = false
            if tLine.bMyExterior then
                if tLine.nType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
                    bShow = bShowWeapon
                elseif tLine.nType == COIN_SHOP_GOODS_TYPE.HAIR then
                    bShow = true
                    tLine.bDisable = not CoinShop_CanChangeHair()
                elseif tLine.nType == COIN_SHOP_GOODS_TYPE.IDLE_ACTION then
                    bShow = IsDebugClient() or UI_IsActivityOn(ACTIVITY_ID.ACTION)
                else
                    bShow = true
                end
            end
            if bShow and not self.IsFilterTitle(tLine.nType, tLine.nRewardsClass, false) then
                table.insert(tList, tLine)
            end
        end
    end

    local nCount = #tMyList
    for i = nCount, 1, -1 do
        local tClass = tMyList[i]
        if #tClass.tList == 0 then
            table.remove(tMyList, i)
        end
    end

    table.insert(tMyList, 1, {bOutfit = true})
    return tMyList
end

function CoinShopData.IsMyTitleHasNew(nType, nClass)
    if nType and nClass then
        if nType == COIN_SHOP_GOODS_TYPE.ITEM then
            local nEquipSub = CoinShop_RewardsClassToSub(nClass)
            local nPendantType = CharacterPendantData.GetRedPointPendantType(nEquipSub)
            if nPendantType then
                return RedpointHelper.Pendant_HasNewByType(nPendantType)
            elseif nClass == REWARDS_CLASS.CLOTH_PENDANT_PET then
                return RedpointHelper.PendantPet_HasRedpoint()
            end
        elseif nType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
            local tTitle = CoinShop_GetTitleInfo(nType, nClass)
            DealWithClassString(tTitle)
            if tTitle.tMyExteriorClass then
                for _, v in pairs(tTitle.tMyExteriorClass) do
                    if RedpointHelper.Exterior_HasNewByType(tonumber(v)) then
                        return true
                    end
                end
            else
                return RedpointHelper.Exterior_HasNewByType(nClass)
            end
        elseif nType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
            return RedpointHelper.WeaponExterior_HasRedpoint()
        elseif nType == COIN_SHOP_GOODS_TYPE.HAIR then
            return RedpointHelper.Hair_HasRedpoint()
        elseif nType == COIN_SHOP_GOODS_TYPE.FACE then
            return RedpointHelper.Face_HasNewByType(false)
        elseif CoinShop_IsNewFaceType(nType, nClass) then
            return RedpointHelper.Face_HasNewByType(true)
        elseif CoinShop_IsBodyType(nType, nClass) then
            return RedpointHelper.Body_HasRedpoint()
        elseif nType == COIN_SHOP_GOODS_TYPE.IDLE_ACTION then
            return RedpointHelper.IdleAction_HasRedpoint()
        end
    end
    return false
end

function CoinShopData.ClearMyTitleNew(nType, nClass)
    if nType and nClass then
        if nType == COIN_SHOP_GOODS_TYPE.ITEM then
            local nEquipSub = CoinShop_RewardsClassToSub(nClass)
            local nPendantType = CharacterPendantData.GetRedPointPendantType(nEquipSub)
            if nPendantType then
                RedpointHelper.Pendant_ClearByType(nPendantType)
            elseif nClass == REWARDS_CLASS.CLOTH_PENDANT_PET then
                RedpointHelper.PendantPet_ClearNew()
            end
        elseif nType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
            local tTitle = CoinShop_GetTitleInfo(nType, nClass)
            DealWithClassString(tTitle)
            if tTitle.tMyExteriorClass then
                for _, v in pairs(tTitle.tMyExteriorClass) do
                    RedpointHelper.Exterior_ClearByType(tonumber(v))
                end
            else
                RedpointHelper.Exterior_ClearByType(nClass)
            end
        elseif nType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
            RedpointHelper.WeaponExterior_ClearNew()
        elseif nType == COIN_SHOP_GOODS_TYPE.IDLE_ACTION then
            RedpointHelper.IdleAction_ClearAll()
        elseif nType ==  COIN_SHOP_GOODS_TYPE.HAIR then
            RedpointHelper.Hair_ClearNew()
        elseif nType ==  COIN_SHOP_GOODS_TYPE.FACE then
            RedpointHelper.Face_ClearNewByType(false)
        elseif CoinShop_IsNewFaceType(nType, nClass) then
            RedpointHelper.Face_ClearNewByType(true)
        elseif CoinShop_IsBodyType(nType, nClass) then
            RedpointHelper.Body_ClearNew()
        end
    end
end

function CoinShopData.IsShowTitleLabel(tbTitle)
    local bShowTime = false
    local nTime = GetGSCurrentTime()
    local nLabelStart
    local nLabelEnd
    if tbTitle.nLabelStart and tbTitle.nLabelStart ~= 0 then
        nLabelStart = Time_AddZone(tbTitle.nLabelStart)
    end
    if tbTitle.nLabelEnd and tbTitle.nLabelEnd ~= 0 then
        nLabelEnd = Time_AddZone(tbTitle.nLabelEnd)
    end
    if (nLabelStart == nil and nLabelEnd == nil) or --不写时间表示一直显示
        (nLabelStart == 0 and nLabelEnd == 0) or --写时间0表示一直显示
        (nTime >= nLabelStart and nTime <= nLabelEnd) then
        bShowTime = true
    end
    return bShowTime
end

function CoinShopData.GetOutfitList()
    local tList = self.GetOutfitListS()
    local tListL = CoinShop_GetOutfitList()
    for nLocalIndex, tData in ipairs(tListL) do
        local t = clone(tData)
        t.nLocalIndex = nLocalIndex
        table.insert(tList, t)
    end
    return tList
end

function CoinShopData.GetOutfitListS()
    local hPlayer = GetClientPlayer()
    if not hPlayer or not hPlayer.GetAllCoinShopPresetData then
        return {}
    end

    local tListS = {}
    local tList = hPlayer.GetAllCoinShopPresetData()
    local nCount = #tList
    for i = nCount, 1, -1 do
        local tPreset = tList[i]
        local tOutfit = {}
        local tOuftifData = self.GetOutfitListSDate(tPreset)
        tOutfit.tData = tOuftifData
        tOutfit.szName = UIHelper.GBKToUTF8(tPreset.szName)
        tOutfit.dwIndex = tPreset.dwIndex
        tOutfit.bHideHat = tPreset.bHideHat
        tOutfit.bServer = true
        table.insert(tListS, tOutfit)
    end

    return tListS
end

local function GetOutfitListPendantSIndex(nIndex, tPendantPos)
    if nIndex ~= COINSHOP_BOX_INDEX.HEAD_EXTEND then
        return nIndex
    end
    for i, bPos in pairs(tPendantPos) do
        if not bPos then
            tPendantPos[i] = true
            return i
        end
    end

    return nIndex
end

function CoinShopData.GetOutfitListSDate(tPreset)
    local tOuftifData = {}
    local tWeaponBox = CoinShop_GetWeaponIndexArray()
    local tPendantPos = {
        [COINSHOP_BOX_INDEX.HEAD_EXTEND] = false,
        [COINSHOP_BOX_INDEX.HEAD_EXTEND1] = false,
        [COINSHOP_BOX_INDEX.HEAD_EXTEND2] = false,
    }
    for _, tData in ipairs(tPreset) do
        local nSource = tData.nSource
        local dwType = tData.dwType
        local nIndex
        if nSource == COIN_SHOP_GOODS_SOURCE.COIN_SHOP then
            if dwType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
                nIndex = Exterior_GetSubIndex(tData.dwID)
                if tData.dwID > 0 then
                    table.insert(tOuftifData, {nIndex = nIndex, dwID = tData.dwID})
                end
            elseif dwType == COIN_SHOP_GOODS_TYPE.HAIR then
                nIndex = COINSHOP_BOX_INDEX.HAIR
                table.insert(tOuftifData, {nIndex = nIndex, dwID = tData.dwID, tColorID = {tData.nColor1, tData.nColor2, tData.nColor3}})
            elseif dwType == COIN_SHOP_GOODS_TYPE.FACE then
                nIndex = COINSHOP_BOX_INDEX.FACE
                table.insert(tOuftifData, {nIndex = nIndex, dwID = tData.dwID, bUseLiftedFace = false})
            elseif dwType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
                nIndex = CoinShop_GetWeaponIndex(tData.dwID)
                if tData.dwID > 0 then
                    table.insert(tOuftifData, {nIndex = nIndex, dwID = tData.dwID})
                end
            end
        elseif nSource == COIN_SHOP_GOODS_SOURCE.FACE_LIFT then
            local hManager = GetFaceLiftManager()
            if not hManager then
                return
            end
            local bNewFace = hManager.CheckNewFace(tData.dwID)
            if bNewFace then
                nIndex = COINSHOP_BOX_INDEX.NEW_FACE
            else
                nIndex = COINSHOP_BOX_INDEX.FACE
            end
            table.insert(tOuftifData, {nIndex = nIndex, dwID = tData.dwID, bUseLiftedFace = true})
        elseif nSource == COIN_SHOP_GOODS_SOURCE.ITEM_TAB then
            nIndex = Exterior_GetPerdentIndex(ITEM_TABLE_TYPE.CUST_TRINKET, tData.dwID)
            nIndex = GetOutfitListPendantSIndex(nIndex, tPendantPos)
            if tData.dwID > 0 then
                table.insert(tOuftifData, {nIndex = nIndex, dwID = tData.dwID, tColorID = {tData.nColor1, tData.nColor2, tData.nColor3}})
            end
        elseif nSource == COIN_SHOP_GOODS_SOURCE.BODY_RESHAPING then
            nIndex = COINSHOP_BOX_INDEX.BODY
            if tData.dwID > 0 then
                table.insert(tOuftifData, {nIndex = nIndex, dwID = tData.dwID})
            end
        end
    end
    local fnSortByIndex = function(tLeft, tRight)
        return tLeft.nIndex < tRight.nIndex
    end
    table.sort(tOuftifData, fnSortByIndex)
    return tOuftifData
end

function CoinShopData.DataToServer(tData)
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

function CoinShopData.GetExteriorList(nClass)
    self.CheckRefresh()
    local tList = m_tShopCache.Exterior

    local szKey = nClass
    if not tList[szKey] then
        local tExterior = self.RelGetExteriorList(nClass)
        tList[szKey] = tExterior
    end

    return tList[szKey]
end

function CoinShopData.GetMyExterior(bShop, bNotShowHide, tTitle)
    local hExterior = GetExterior()
    if not hExterior then
        return
    end

    local tAllExterior = GetPlayerAllExterior(bNotShowHide)

    local nTime = GetGSCurrentTime()
    local tSubList = {}
    local tSetList = {}
    local tSetMap = {}
    local tGenreList = {}
    local tGenreMap = {}
    DealWithClassString(tTitle)
    for _, tExterior in ipairs(tAllExterior) do
        local dwExteriorID = tExterior.dwExteriorID
        local tInfo = hExterior.GetExteriorInfo(dwExteriorID)
        local tLine = Table_GetExteriorSet(tInfo.nSet)

        local bShow = bShop == tInfo.bIsInShop and IsClassMatch(tTitle, tLine.nClass)
        if bShow then
            local tPrice = tInfo.tPrice
            local bDis = CoinShop_IsPriceDis(tInfo)
            local szTime = CoinShop_GetExteriorTime(dwExteriorID)
            local bTimeLimit = szTime ~= ""
            local bFreeTryOn = CoinShop_CanFreeTryOn(tInfo)
            local nLabel = tLine.nLabel
            if bFreeTryOn then
                nLabel = math.max(nLabel, EXTERIOR_LABEL.FREE_TRY_ON)
            elseif bTimeLimit then
                nLabel = math.max(nLabel, EXTERIOR_LABEL.TIME_LIMIT)
            elseif bDis then
                nLabel = math.max(nLabel, EXTERIOR_LABEL.DISCOUNT)
            end

            if not tSetMap[tInfo.nSet] then
                local tSet = {}
                tSet.nGenre = tLine.nGenre
                tSet.nSubGenre = tLine.nSubGenre
                tSet.nSet = tLine.nSet
                tSet.tSub = {}
                tSet.nLabel = nLabel
                tSet.nCount = #tLine.tSub
                table.insert(tSetList, tSet)

                tSetMap[tInfo.nSet] = #tSetList
            end
            local nIndex = tSetMap[tInfo.nSet]
            local tSet = tSetList[nIndex]
            tSet.nLabel = math.max(nLabel, tSet.nLabel)
            local tSub = tSet.tSub

            table.insert(tSub, dwExteriorID)
            table.insert(tSubList, {dwExteriorID})

            if not tGenreMap[tLine.nGenre] then
                table.insert(tGenreList, tLine.nGenre)
                tGenreMap[tLine.nGenre] = true
            end
        end
    end
    local tList = {}
    -- local tReSetList = {}
    -- for _, tSet in ipairs(tSetList) do
    --     if tSet.nCount == #tSet.tSub then
    --         table.insert(tReSetList, tSet)
    --     end
    -- end
    tList.tSetList = tSetList
    tList.tSubList = tSubList

    table.insert(tGenreList, 1, 0)

    if tTitle and tTitle.nRewardsClass then
        m_tMyGenreList[tTitle.nRewardsClass] = tGenreList
    end

    return tList
end

function CoinShopData.ParseExteriorSet(tClass, tLine, nFilterLabel)
    local nTime = GetGSCurrentTime()

    local hExteriorClient = GetExterior()
    if not hExteriorClient then
        return
    end


    local tSetList = tClass.tSetList
    local tList = tClass.tSubList

    local nSetLabel = tLine.nLabel
    local tSub = {}
    for i = 1, 5 do
        local dwExteriorID = tLine["nSub" .. i]
        if dwExteriorID > 0 then
            local tPriceInfo = hExteriorClient.GetExteriorInfo(dwExteriorID)
            if tPriceInfo then
                local bIsInShop = tPriceInfo.bIsInShop
                local nStartTime = tPriceInfo.nStartTime
                local nEndTime = tPriceInfo.nEndTime
                self.ChangeRefreshTimeByInfo(tPriceInfo)
                local bCanBuy = (nStartTime == -1 or nTime >= nStartTime) and (nEndTime == -1 or nTime <= nEndTime)

                if bCanBuy then
                    local tPrice = tPriceInfo.tPrice
                    local bDis = CoinShop_IsPriceDis(tPriceInfo)
                    local szTime = CoinShop_GetExteriorTime(dwExteriorID)
                    local bTimeLimit = szTime ~= ""
                    local bFreeTryOn = CoinShop_CanFreeTryOn(tPriceInfo)
                    local nLabel = tLine.nLabel
                    if bFreeTryOn then
                        nLabel = math.max(nLabel, EXTERIOR_LABEL.FREE_TRY_ON)
                    elseif bTimeLimit then
                        nLabel = math.max(nLabel, EXTERIOR_LABEL.TIME_LIMIT)
                    elseif bDis then
                        nLabel = math.max(nLabel, EXTERIOR_LABEL.DISCOUNT)
                    end

                    nSetLabel = math.max(nSetLabel, nLabel)
                    if not nFilterLabel or
                        nFilterLabel == nLabel or
                        nFilterLabel == tLine.nLabel
                    then

                        table.insert(tSub, dwExteriorID)
                        table.insert(tList, 1, {dwExteriorID, nLabel})
                    end
                end
            end
        end
    end

    if #tSub > 0 then
        local tSet = {}
        tSet.nGenre = tLine.nGenre
        tSet.nSubGenre = tLine.nSubGenre
        tSet.nSet = tLine.nSet
        tSet.tSub = tSub
        tSet.nLabel = nSetLabel
        table.insert(tSetList, 1, tSet)
    end
end

function CoinShopData.RelGetExteriorList(nClass)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local tShopClass = {
        tSetList = {},
        tSubList = {},
    }
    tShopClass.tSetList = tShopClass.tSetList or {}
    tShopClass.tSubList = tShopClass.tSubList or {}
    local tGenreList = {}
    local tGenreMap = {}
    local tExteriorArray = Table_GetExteriorArray()
    for _, tLine in ipairs(tExteriorArray) do
        if ((tLine.nGenre ~= EXTERIOR_GENRE.SCHOOL or hPlayer.dwForceID == tLine.nForce) and
            tLine.nClass == nClass
        )
        then
            if not tGenreMap[tLine.nGenre] then
                table.insert(tGenreList, tLine.nGenre)
                tGenreMap[tLine.nGenre] = true
            end

            self.ParseExteriorSet(tShopClass, tLine)
        end
    end

    table.insert(tGenreList, 1, 0)

    if nClass then
        m_tGenreList[nClass] = tGenreList
    end

    return tShopClass--, tGenreList
end

function CoinShopData.GetGenreList(nClass)
    return m_tGenreList[nClass] or {}
end

function CoinShopData.GetMyGenreList(nClass)
    return m_tMyGenreList[nClass] or {}
end

local function GetHorseGetAdornment(tList)
    m_tAdornmentSet = {}
    local tAdornmentSetMap = {}
    for i, tTab in ipairs(tList) do
        for j, tItem in ipairs(tTab) do
            local nSetID = CoinShop_GetAdornmentSetID(tItem.dwIndex)
            if nSetID then
                if not tAdornmentSetMap[nSetID] then
                    table.insert(m_tAdornmentSet, {nSetID = nSetID, tList = {}})
                    tAdornmentSetMap[nSetID] = m_tAdornmentSet[#m_tAdornmentSet]
                end
                table.insert(tAdornmentSetMap[nSetID].tList, tItem)
            end
        end
    end
end

local function GetRewardSet(tList, nClass)
    m_tRewardSet[nClass] = {}
    local tSetMap = {}
    for i, tTab in ipairs(tList) do
        for j, tItem in ipairs(tTab) do
            local tInfo = CoinShop_GetRewardSetID(nClass, tItem.dwIndex)
            if tInfo then
                local nSetID = tInfo.nSetID
                if not tSetMap[nSetID] then
                    table.insert(m_tRewardSet[nClass], {nSetID = nSetID, szSetName = UIHelper.GBKToUTF8(tInfo.szSetName)})
                    tSetMap[nSetID] = true
                end
            end
        end
    end
end

function CoinShopData.GetShopAdornmentSet()
    return m_tAdornmentSet
end

function CoinShopData.GetShopRewardSet(nClass)
    return m_tRewardSet[nClass]
end

function CoinShopData.GetRewardsList(nClass, bRewardSet)
    -- if bEntity then
    --     return RelGetRewards(nClass)
    -- end

    self.CheckRefresh()
    if not m_tShopCache.Rewards[nClass] or not  m_tShopCache.Rewards[nClass] then
        local tRewardsList = self.RelGetRewards(nClass)
        if nClass == REWARDS_CLASS.HORSE_ADORNMENT then
            GetHorseGetAdornment(tRewardsList)
        end

        if bRewardSet then
            GetRewardSet(tRewardsList, nClass)
        end

        m_tShopCache.Rewards[nClass]= tRewardsList
    end

    return m_tShopCache.Rewards[nClass]
end

function CoinShopData.RelGetRewards(nClass)
    local hRewardsShop = GetRewardsShop()
    if not hRewardsShop then
        return
    end

    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local tList = {}
    local tRewardsArray = CoinShop_GeRewardsShopArray()
    for _, tLine in ipairs(tRewardsArray) do
        if nClass == tLine.nClass then
            local nSubClass = tLine.nSubClass
            tList[nSubClass] = tList[nSubClass] or {}
            local tSubClass = tList[nSubClass]
            local bShow = CoinShop_RewardsShow(tLine.dwLogicID, nClass)
            local bForce = tLine.dwForceID == 0 or tLine.dwForceID == hPlayer.dwForceID
            local nLabel = tLine.nLabel
            local tInfo = hRewardsShop.GetRewardsShopInfo(tLine.dwLogicID)

            self.ChangeRefreshTimeByInfo(tInfo)
            tLine.bOverdue = not bShow and tLine.bOverdueShow
            if bForce and (bShow or tLine.bOverdueShow) then
                local bDis = CoinShop_IsPriceDis(tInfo)
                local szTime = CoinShop_GetRewardsTime(tLine.dwLogicID)
                local bTimeLimit = szTime ~= ""
                local bFreeTryOn = CoinShop_CanFreeTryOn(tInfo)
                if bFreeTryOn then
                    nLabel = math.max(nLabel, EXTERIOR_LABEL.FREE_TRY_ON)
                elseif bTimeLimit then
                    nLabel = math.max(nLabel, EXTERIOR_LABEL.TIME_LIMIT)
                elseif bDis then
                    nLabel = math.max(nLabel, EXTERIOR_LABEL.DISCOUNT)
                elseif tInfo.nGameWorldStartInDuration > 0 then
                    nLabel = math.max(nLabel, EXTERIOR_LABEL.GAME_WORLD_START)
                end

                local nSubClassLabel = tSubClass.nLabel or 0
                tSubClass.nLabel = math.max(nSubClassLabel, nLabel)
                CoinShop_ParseRewardInfo(tLine)
                table.insert(tSubClass, tLine)

                if tLine.nClass == REWARDS_CLASS.LIMIT_TIME or tLine.nClass == REWARDS_CLASS.ARENA_WEAPON then
                    local tFoldInfo = CoinShop_GetHomeFoldInfoByGoods(COIN_SHOP_GOODS_TYPE.ITEM, tLine.dwLogicID)
                    if tFoldInfo and tFoldInfo.nFoldID > 0 then
                        tLine.nFoldID = tFoldInfo.nFoldID
                    end
                end
            end

            tSubClass.nSubClass = nSubClass
            if tLine.szSubClassName ~= "" then
                tSubClass.szName = tLine.szSubClassName
            end
        end
    end

    local fnSortBySubClass = function(tLeft, tRight)
        return tLeft.nSubClass < tRight.nSubClass
    end

    local tShopList = {}

    for nSubClass, tSubClass in pairs(tList) do
        if #tSubClass > 0 then
            table.insert(tShopList, tSubClass)
        end
    end

    table.sort(tShopList, fnSortBySubClass)
    return tShopList
end

function CoinShopData.GetShopWeapon(nFilterLabel)
    self.CheckRefresh()
    local szKey = nFilterLabel or "default"
    if not m_tShopCache.Weapon[szKey] then
        m_tShopCache.Weapon[szKey] = self.GetWeapon(nFilterLabel)
    end

    return m_tShopCache.Weapon[szKey]
end

function CoinShopData.GetWeaponFilter()
    self.GetShopWeapon()
    return m_tWeaponFilterType
end

function CoinShopData.GetWeapon(nFilterLabel)
    local tList = {}
    local tWeaponArray = CoinShop_GetWeaponArray()
    m_tWeaponFilterType = {}
    table.insert(m_tWeaponFilterType, -1)
    local tFilterMap = {}
    for _, tLine in ipairs(tWeaponArray) do
        local dwID = tLine.dwID
        local bCanBuy = CoinShop_WeaponCanBuy(dwID)
        local tInfo = CoinShop_GetWeaponExteriorInfo(dwID)
        if tInfo then
            self.ChangeRefreshTimeByInfo(tInfo)
        end
        if bCanBuy then
            local nType = tInfo.nDetailType
            if not tFilterMap[nType] then
                tFilterMap[nType] = true
                table.insert(m_tWeaponFilterType, nType)
            end
            local bDis = CoinShop_IsPriceDis(tInfo)
            local nLabel = -1
            if bDis then
                nLabel = math.max(nLabel, EXTERIOR_LABEL.DISCOUNT)
            end
            if not nFilterLabel or nFilterLabel == nLabel then
                tList[tLine.nSubType] = tList[tLine.nSubType] or {}
                table.insert(tList[tLine.nSubType], tLine)
            end
        end
    end

    return tList
end

function CoinShopData.GetMyWeaponList()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return {}
    end
    local tWeaponList = hPlayer.GetAllWeaponExterior()
    local tList = {}
    for _, tWeapon in ipairs(tWeaponList) do
        table.insert(tList, tWeapon.dwWeaponExteriorID)
    end
    return tList
end

local tHairIndex =
{
    [0] = "Hair",
    [1] = "Plait",
    [2] = "Bang",
    [3] = "Face",
}

local function TableInsert(tList, key, value)
    if not tList[key] then
        tList[key] = {}
    end
    table.insert(tList[key], value)
end

function CoinShopData.GetHairIndex()
    return tHairIndex
end

function CoinShopData.GetHeadState(nHeadID)
    local tLine = g_tTable.HeadHair:Search(nHeadID)
    if not tLine then
        return
    end

    return tLine.bPlait, tLine.bBang
end

local function GetHairIndexLabel(szType, nRepresentID)
    if nRepresentID == 0 then
        return 0
    end

    local tHairMap = CoinShopData.GetHairMap()
    local nLabel = tHairMap["re" .. szType][nRepresentID][2]
    return nLabel
end


function CoinShopData.GetHairUILabel(nHair)
    local nHeadID, nBangID, nPlaitID = GetHairShop().GetHairIndex(nHair)

    local nHeadLabel = GetHairIndexLabel("Hair", nHeadID)
    local nBangLabel = GetHairIndexLabel("Bang", nBangID)
    local nPlaitLabel = GetHairIndexLabel("Plait", nPlaitID)
    local nLabel = math.max(nHeadLabel, nBangLabel)
    nLabel = math.max(nLabel, nPlaitLabel)

    return nLabel
end

function CoinShopData.InsertHair(tBang, nHeadID, nBangID, nPlaitID)
    local tLine = g_tTable.ReHeadIndex:Search(nHeadID, nBangID, nPlaitID)
    local nHeadLabel = GetHairIndexLabel("Hair", nHeadID)
    local nBangLabel = GetHairIndexLabel("Bang", nBangID)
    local nPlaitLabel = GetHairIndexLabel("Plait", nPlaitID)
    local nLabel = math.max(nHeadLabel, nBangLabel)
    nLabel = math.max(nLabel, nPlaitLabel)
    table.insert(tBang, {tLine.nHairID, nLabel})
end

function CoinShopData.GetHairID(nHeadID, nBangID, nPlaitID)
    local tLine = g_tTable.ReHeadIndex:Search(nHeadID, nBangID, nPlaitID)
    return tLine.nHairID
end

function CoinShopData.GetHairMap()
    if not m_tHairShopMap then
        self.GetAllHairList()
    end
    return m_tHairShopMap
end

function CoinShopData.GetAllHairList()
    if m_tHairList then
        return m_tHairList, m_tFaceList
    end
    local nCount = g_tTable.Hair:GetRowCount()
    local tList = {}
    local tHairShopMap = {}
    for i = 2, nCount do
        local tLine = g_tTable.Hair:GetRow(i)
        local nIndex = math.floor(tLine.nID / 10000)
        local nID = math.floor(tLine.nID % 10000)
        local szHairType = tHairIndex[nIndex]
        local nShowType
        if not tList[szHairType] then
            tList[szHairType] = {}
        end
        if szHairType == "Face" then
            table.insert(tList[szHairType], {tLine.nRepresentID, tLine.nLabel, tLine.szHairName})
        elseif szHairType == "Hair" then
            nShowType = tLine.nShowType
            if nShowType ~= 0 then
                TableInsert(tList[szHairType], nShowType, tLine.nRepresentID)
            end
            if nShowType ~= HAIR_SHOW_TYPE.GROUP then
                TableInsert(tList[szHairType], HAIR_SHOW_TYPE.ALL, tLine.nRepresentID)
            end
        else
            table.insert(tList[szHairType], tLine.nRepresentID)
        end

        if not tHairShopMap["re" .. szHairType] then
            tHairShopMap["re" .. szHairType] = {}
        end
        tHairShopMap["re" .. szHairType][tLine.nRepresentID] = {nID, tLine.nLabel, tLine.szHairName, nShowType}
    end
    table.insert(tList["Bang"], 1, 0)
    tHairShopMap["reBang"][0] = {0, 0, g_tStrings.STR_NAME_HAIR_BASE}
    m_tHairShopMap = tHairShopMap

    local tFace = tList["Face"]
    m_tFaceList = tFace

    local tHair = {}
    for nShowType, t in pairs(tList["Hair"]) do
        local nHeadCount = #t
        tHair[nShowType] = {}
        for i = nHeadCount, 1, -1 do
            local nHeadID = t[i]
            local bPlait, bBang = self.GetHeadState(nHeadID)
            local nBangID = 0
            local nPlaitID = 0
            local tHead = {}
            if bBang then
                local nBangCount = #tList["Bang"]
                for j = nBangCount, 1, -1 do
                    local tBang = {}
                    nBangID = tList["Bang"][j]
                    if bPlait then
                        local nPlaitCount = #tList["Plait"]
                        for k = nPlaitCount, 1, -1 do
                            nPlaitID = tList["Plait"][k]
                            self.InsertHair(tBang, nHeadID, nBangID, nPlaitID)
                        end
                    else
                        nPlaitID = 0
                        self.InsertHair(tBang, nHeadID, nBangID, nPlaitID)
                    end

                    if #tBang > 0 then
                        table.insert(tHead, tBang)
                    end
                end
            else
                local tBang = {}
                self.InsertHair(tBang, nHeadID, nBangID, nPlaitID)
                table.insert(tHead, tBang)
            end
            if #tHead > 0 then
                table.insert(tHair[nShowType], tHead)
            end
        end
    end

    m_tHairList = tHair
    return tHair, tFace
end

function CoinShopData.GetHairByTime(tList)
    local hPlayer = GetClientPlayer()
    local tHairLabel = {}
    local tRetHair = {}
    local nTime = GetGSCurrentTime()
    for nShowType, t in pairs(tList) do
        tRetHair[nShowType] = {}
        tHairLabel[nShowType] = 0
        for nHairIndex, tHead in ipairs(t) do
            local tRetHead = {}
            for nBangIndex, tBang in ipairs(tHead) do
                local tRetBang = {}
                for nPlaitIndex, tOneHair in ipairs(tBang) do
                    local nHair = tOneHair[1]
                    local tInfo = GetHairShop().GetHairPrice(hPlayer.nRoleType, HAIR_STYLE.HAIR, nHair)
                    if tInfo then
                        local nStartTime = tInfo.nStartTime
                        local nEndTime = tInfo.nEndTime
                        self.ChangeRefreshTimeByInfo(tInfo)
                        local bCanBuy = (nStartTime == -1 or nTime >= nStartTime) and
                                    (nEndTime == -1 or nTime <= nEndTime)
                        if bCanBuy then
                            local nLabel = tOneHair[2]
                            local szTime = HairShop_GetTime(HAIR_STYLE.HAIR, nHair)
                            local bTimeLimit = szTime ~= ""
                            local bDis = CoinShop_IsPriceDis(tInfo)
                            local bFreeTryOn = CoinShop_CanFreeTryOn(tInfo)
                            m_tHairShopLabels[nLabel] = true
                            if bFreeTryOn then
                                nLabel = math.max(nLabel, EXTERIOR_LABEL.FREE_TRY_ON)
                                m_tHairShopLabels[EXTERIOR_LABEL.FREE_TRY_ON] = true
                            elseif bTimeLimit then
                                nLabel = math.max(nLabel, EXTERIOR_LABEL.TIME_LIMIT)
                                m_tHairShopLabels[EXTERIOR_LABEL.TIME_LIMIT] = true
                            elseif bDis then
                                nLabel = math.max(nLabel, EXTERIOR_LABEL.DISCOUNT)
                                m_tHairShopLabels[EXTERIOR_LABEL.DISCOUNT] = true
                            end
                            tHairLabel[nShowType] = math.max(nLabel, tHairLabel[nShowType])
                            table.insert(tRetBang, tOneHair)
                        end
                    else
                        LOG.ERROR("GetHairByTime GetHair error RoleType = " .. hPlayer.nRoleType .. " HairID = " .. nHair)
                    end
                end
                if #tRetBang > 0 then
                    table.insert(tRetHead, tRetBang)
                end
            end
            if #tRetHead > 0 then
                local tBang = tRetHead[1]
                local nBangCount = #tRetHead
                if nBangCount == 1 then
                    tRetHead["BangNum"] = 0
                else
                    tRetHead["BangNum"] = nBangCount
                end

                local nPlaitCount = #tBang
                if nPlaitCount == 1 then
                    tRetHead["PlaitNum"] = 0
                else
                    tRetHead["PlaitNum"] = nPlaitCount
                end
                table.insert(tRetHair[nShowType], tRetHead)
            end
        end
    end
    m_tHairLabel = tHairLabel
    return tRetHair
end

function CoinShopData.GetShopHairList()
    CoinShopData.CheckRefresh()
    if not m_tShopCache.Hair["default"] then
        local tHairList = CoinShopData.GetAllHairList()
        m_tShopCache.Hair["default"] = CoinShopData.GetHairByTime(tHairList)
    end

    return m_tShopCache.Hair["default"]
end

function CoinShopData.GetFaceByTime(tList)
    local hPlayer = GetClientPlayer()
    local nFaceLabel = 0
    local tResult = {}
    local nTime = GetGSCurrentTime()
    for _, tOneFace in ipairs(tList) do
        local dwID = tOneFace[1]
        local tInfo = GetHairShop().GetHairPrice(hPlayer.nRoleType, HAIR_STYLE.FACE, dwID)
        if not tInfo then
            Log("GetFaceByTime GetFace error RoleType = " .. hPlayer.nRoleType .. " FaceID = " .. dwID)
        end

        local nStartTime = tInfo.nStartTime
        local nEndTime = tInfo.nEndTime
        CoinShopData.ChangeRefreshTimeByInfo(tInfo)

        local bCanBuy = (nStartTime == -1 or nTime >= nStartTime) and
                    (nEndTime == -1 or nTime <= nEndTime)

        if bCanBuy then
            local nLabel = tOneFace[2]
            local szTime = HairShop_GetTime(HAIR_STYLE.FACE, dwID)
            local bTimeLimit = szTime ~= ""
            local bDis = CoinShop_IsPriceDis(tInfo)
            local bFreeTryOn = CoinShop_CanFreeTryOn(tInfo)
            m_tHairShopLabels[nLabel] = true
            if bFreeTryOn then
                nLabel = math.max(nLabel, EXTERIOR_LABEL.FREE_TRY_ON)
                m_tHairShopLabels[EXTERIOR_LABEL.FREE_TRY_ON] = true
            elseif bTimeLimit then
                nLabel = math.max(nLabel, EXTERIOR_LABEL.TIME_LIMIT)
                m_tHairShopLabels[EXTERIOR_LABEL.TIME_LIMIT] = true
            elseif bDis then
                nLabel = math.max(nLabel, EXTERIOR_LABEL.DISCOUNT)
                m_tHairShopLabels[EXTERIOR_LABEL.DISCOUNT] = true
            end
            --tOneFace[2] = nLabel
            nFaceLabel = math.max(nLabel, nFaceLabel)

            table.insert(tResult, tOneFace)
        end
    end
    m_nFaceLabel = nFaceLabel
    return tResult
end

function CoinShopData.GetShopFaceList()
    CoinShopData.CheckRefresh()

    if not m_tShopCache.Face["default"] then
        local _, tFaceList = CoinShopData.GetAllHairList()
        m_tShopCache.Face["default"] = CoinShopData.GetFaceByTime(tFaceList)
    end

    return m_tShopCache.Face["default"]
end

function CoinShopData.GetHairLabel()
    CoinShopData.GetShopHairList()
    return m_tHairLabel
end

function CoinShopData.GetFaceLabel()
    CoinShopData.GetShopFaceList()
    return m_nFaceLabel
end

function CoinShopData.GetHairShopLabels()
    CoinShopData.GetShopHairList()
    CoinShopData.GetShopFaceList()
    return m_tHairShopLabels
end

function CoinShopData.GetBuyItemName(tBuyItem)
	local szName = ""
	if tBuyItem.eGoodsType and ((tBuyItem.dwGoodsID and tBuyItem.dwGoodsID > 0 or tBuyItem.eGoodsType == COIN_SHOP_GOODS_TYPE.FACE)) then
        if tBuyItem.eGoodsType == COIN_SHOP_GOODS_TYPE.IDLE_ACTION then
            szName = UIHelper.UTF8ToGBK(g_tStrings.STR_PLAYER_IDLE_ACTION_CHECK_OUT_NAME)
        else
            szName = CoinShop_GetGoodsName(tBuyItem.eGoodsType, tBuyItem.dwGoodsID)
        end
	elseif tBuyItem.bEffectSfx then
		local tInfo = Table_GetPendantEffectInfo(tBuyItem.nEffectID)
		if tInfo then
			szName = tInfo.szName
		end
	else
		local itemInfo = GetItemInfo(tBuyItem.dwTabType, tBuyItem.dwTabIndex)
		if itemInfo then
			szName = ItemData.GetItemNameByItemInfo(itemInfo)
		end
	end
	return szName
end

function CoinShopData.GetBuyItemIcon(tBuyItem)
    if tBuyItem.eGoodsType == COIN_SHOP_GOODS_TYPE.ITEM then
        local nCount = tBuyItem.nBuyCount or 1
        local KItemInfo = GetItemInfo(tBuyItem.dwTabType, tBuyItem.dwTabIndex)
        if KItemInfo then
            return Table_GetItemIconID(KItemInfo.nUiId)
        end
    elseif tBuyItem.eGoodsType == COIN_SHOP_GOODS_TYPE.EXTERIOR or tBuyItem.eGoodsType == COIN_SHOP_GOODS_TYPE.RENEW then
        return GetExterior().GetExteriorInfo(tBuyItem.dwGoodsID).nIconID
    elseif tBuyItem.eGoodsType == COIN_SHOP_GOODS_TYPE.FACE or tBuyItem.eGoodsType == COIN_SHOP_GOODS_TYPE.HAIR then
        return 0 -- TODO : 易容图标
    elseif tBuyItem.eGoodsType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
        local tWeaponInfo = g_tTable.CoinShop_Weapon:Search(tBuyItem.dwGoodsID)
        if tWeaponInfo then
            return tWeaponInfo.dwIconID
        end
    end

    return 0
end

function CoinShopData.UpdateBuyItemState(tBuy, bSave)
	if not g_pClientPlayer then
		return
	end
	local  hCoinShopClient = GetCoinShopClient()
	if not hCoinShopClient then
		return
	end
	CoinShopData.tBody = nil
	CoinShopData.tFaceLift = nil
	CoinShopData.tOtherSave = {}
	local bAllHave = true
    local bChooseLimit = false
	for _, tBuyItem in ipairs(tBuy) do
		if not tBuyItem.ePayType then
			tBuyItem.ePayType = COIN_SHOP_PAY_TYPE.INVALID
		end
		local nState =  ACCOUNT_ITEM_STATUS.NORMAL
		local nOwnType
		if tBuyItem.bBody then
			nState = ACCOUNT_ITEM_STATUS.NORMAL
			CoinShopData.tBody = tBuyItem
			if not tBuyItem.bHave then
				bAllHave = false
			end
		elseif tBuyItem.bNewFace then
			nState = ACCOUNT_ITEM_STATUS.NORMAL
			CoinShopData.tFaceLift = tBuyItem
			if not tBuyItem.bHave then
				bAllHave = false
			end
		elseif tBuyItem.bLiftedFace then
			nState = ACCOUNT_ITEM_STATUS.NORMAL
			CoinShopData.tFaceLift = tBuyItem
			if not tBuyItem.bHave then
				bAllHave = false
			end
		elseif tBuyItem.bPendantPet then
			if tBuyItem.bHave then
				if tBuyItem.dwTabIndex then
					nState = ACCOUNT_ITEM_STATUS.HAVE
					nOwnType = COIN_SHOP_OWN_TYPE.EQUIP
					tBuyItem.bOtherSave = true
					table.insert(CoinShopData.tOtherSave, tBuyItem)
				end

				if tBuyItem.dwTabIndex <= 0 then
					nState = ACCOUNT_ITEM_STATUS.OFF
				end
			else
				bAllHave = false
			end
        elseif tBuyItem.bEffectSfx then
			if tBuyItem.bHave then
				nState = ACCOUNT_ITEM_STATUS.HAVE
				nOwnType = COIN_SHOP_OWN_TYPE.EQUIP
				tBuyItem.bOtherSave = true
				table.insert(CoinShopData.tOtherSave, tBuyItem)
			else
				bAllHave = false
			end
		elseif tBuyItem.dwGoodsID <= 0 then
			if tBuyItem.dwTabType and tBuyItem.dwTabIndex then
				nState = ACCOUNT_ITEM_STATUS.HAVE
				nOwnType = COIN_SHOP_OWN_TYPE.EQUIP
				tBuyItem.bOtherSave = true
				table.insert(CoinShopData.tOtherSave, tBuyItem)
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
					nState = ACCOUNT_ITEM_STATUS.NORMAL
				end
			else
				nState = ACCOUNT_ITEM_STATUS.CAN_NOT_SAVE
			end
		end
		tBuyItem.nState = nState
		tBuyItem.nOwnType = nOwnType

        if tBuyItem.nState ~= ACCOUNT_ITEM_STATUS.OFF then
            local bCheckEnable = not tBuyItem.bRel
            local bChoose = not tBuyItem.bRel
            -- 限量只能选一件
            bChoose = bChoose and (not tBuyItem.bLimitItem or not bChooseLimit)
            -- 未收集的不能选
            local bCollect, nGold = CoinShop_GetCollectInfo(tBuyItem.eGoodsType, tBuyItem.dwGoodsID)
            bCheckEnable = bCheckEnable and (bCollect or nGold >= 0)
            bChoose = bChoose and (bCollect or nGold >= 0)

            if tBuyItem.eGoodsType == COIN_SHOP_GOODS_TYPE.ITEM and tBuyItem.dwGoodsID and tBuyItem.dwGoodsID > 0 then
                local bCanBuy = CoinShop_RewardsCanBuy(tBuyItem.dwGoodsID)
                bCheckEnable = bCheckEnable and (bCanBuy or tBuyItem.bLimitItem)
                bChoose = bChoose and (bCanBuy or tBuyItem.bLimitItem)
            end

            tBuyItem.bCheckEnable = bCheckEnable
            tBuyItem.bChoose = bChoose
            if tBuyItem.bLimitItem and tBuyItem.bChoose then
                bChooseLimit = true
            end
        end
	end

	return bAllHave
end

function CoinShopData.CalcBill(tbGoods, tbDisCoupon)
    local tbBill = {
        nCoin = 0,
        nGold = 0,
        nRewards = 0,
        nLeftVouchars = 0,
        nUseVouchars = 0,
        dwVoucharsID = 0,
        nForbidDisCouponCoin = 0,
        nBuyCount = 0,
        nDisCouponCoin = 0,

        tbDisCoupon = tbDisCoupon,
    }

    local tbCurrentVouchars = GetCurrentCoinShopVoucher()
    if tbCurrentVouchars then
        tbBill.nLeftVouchars = tbCurrentVouchars.nCount
    end

    local hManager = GetFaceLiftManager()
    if not hManager then
        return
    end

    local nFaceVouchars = 0
    local bCanUseFaceVouchers = hManager.CanUseVouchers()
    if bCanUseFaceVouchers then
        nFaceVouchars = hManager.GetVouchers()
    end

    local hCoinShopClient = GetCoinShopClient()
    for _, tbGoodsInfo in ipairs(tbGoods) do
        if tbGoodsInfo.bChoose then
            CoinShopData.UpdateDiscoupon(tbGoodsInfo, tbDisCoupon)
            local bCollect, nGold = CoinShop_GetCollectInfo(tbGoodsInfo.eGoodsType, tbGoodsInfo.dwGoodsID)
            if tbGoodsInfo.bBody then
                tbBill.nBuyCount = tbBill.nBuyCount + 1
            elseif tbGoodsInfo.bNewFace then


                local bFreeChance = CoinShopData.GetFreeChance(tbGoodsInfo.bNewFace)
                if bFreeChance then

                else
                    local tNewPrice
                    if tbGoodsInfo.nIndex then
                        tNewPrice = hManager.GetFacePrice(tbGoodsInfo.tFaceData, tbGoodsInfo.nIndex)
                    else
                        tNewPrice = hManager.GetFacePrice(tbGoodsInfo.tFaceData)
                    end
                    tbGoodsInfo.ePayType = COIN_SHOP_PAY_TYPE.COIN
                    tbGoodsInfo.nPrice = tNewPrice.nTotalPrice
                    tbGoodsInfo.nDiscount = 1
                    bSureEnable = true
                    local nCoinPrice = math.max(0, tbGoodsInfo.nPrice - nFaceVouchars)
                    tbBill.nCoin = tbBill.nCoin + nCoinPrice
                    tbBill.nForbidDisCouponCoin = tbBill.nForbidDisCouponCoin + nCoinPrice

                    if nFaceVouchars > 0 then
                        tbGoodsInfo.tbBill = {}
                        tbGoodsInfo.tbBill.bUseFaceVouchars = true
                        tbGoodsInfo.tbBill.nUseVouchars = math.min(tbGoodsInfo.nPrice, nFaceVouchars)
                        tbGoodsInfo.tbBill.nCoin = tbBill.nCoin
                        tbGoodsInfo.tbBill.nOriginalCoin = tbGoodsInfo.nPrice
                    end
                end
                tbBill.nBuyCount = tbBill.nBuyCount + 1

            elseif tbGoodsInfo.nState == ACCOUNT_ITEM_STATUS.NORMAL and (bCollect or nGold >= 0) then
                if not tbGoodsInfo.tbPrice then
                    local nSelectPriceIndex = nil
                    for i, tbPriceInfo in ipairs(tbGoodsInfo.tPriceInfo) do
                        if tbGoodsInfo.ePayType == tbPriceInfo.nPayType and tbGoodsInfo.eTimeLimitType == tbPriceInfo.nTimeType then
                            nSelectPriceIndex = i
                        end
                    end
                    if not nSelectPriceIndex then
                        nSelectPriceIndex = #tbGoodsInfo.tPriceInfo
                    end

                    tbGoodsInfo.tbPrice = tbGoodsInfo.tPriceInfo[nSelectPriceIndex]
                end

                tbGoodsInfo.nBuyCount = tbGoodsInfo.nBuyCount or 1

                if tbGoodsInfo.tbPrice.nPayType == COIN_SHOP_PAY_TYPE.MONEY then
                    tbBill.nGold = tbBill.nGold + tbGoodsInfo.tbPrice.nPrice * tbGoodsInfo.nBuyCount
                elseif tbGoodsInfo.tbPrice.nPayType == COIN_SHOP_PAY_TYPE.COIN then
                    local bFreeChance = CoinShopData.GetFreeChance(tbGoodsInfo.bNewFace)
                    if tbGoodsInfo.bLiftedFace and bFreeChance then
                       -- UpdateFaceFreeText(hWndItem, true)
                    else
                        local nCoinPrice = tbGoodsInfo.tbPrice.nPrice
                        if tbGoodsInfo.tbPrice.bDis then
                            nCoinPrice = tbGoodsInfo.tbPrice.nDisPrice
                        end

                        if tbGoodsInfo.tbPrice.nVouchars and tbGoodsInfo.tbPrice.nVouchars > 0 then
                            nCoinPrice = nCoinPrice - tbGoodsInfo.tbPrice.nVouchars
                        end

                        tbBill.nCoin = tbBill.nCoin + nCoinPrice * tbGoodsInfo.nBuyCount
                        if tbCurrentVouchars then
                            local bResult = hCoinShopClient.CheckCanUseVoucher(tbCurrentVouchars.dwVoucherID, tbGoodsInfo.eGoodsType, tbGoodsInfo.dwGoodsID)
                            if bResult then
                                tbGoodsInfo.tbBill = {}
                                tbGoodsInfo.tbBill.dwUseVoucherID = tbCurrentVouchars.dwVoucherID
                                tbGoodsInfo.tbBill.nUseVouchars = math.min(nCoinPrice * tbGoodsInfo.nBuyCount, tbBill.nLeftVouchars)
                                tbGoodsInfo.tbBill.nCoin = nCoinPrice * tbGoodsInfo.nBuyCount - tbGoodsInfo.tbBill.nUseVouchars
                                tbGoodsInfo.tbBill.nOriginalCoin = nCoinPrice * tbGoodsInfo.nBuyCount

                                tbBill.nUseVouchars = math.min(nCoinPrice * tbGoodsInfo.nBuyCount + tbBill.nUseVouchars, tbCurrentVouchars.nCount)
                                tbBill.nLeftVouchars = tbCurrentVouchars.nCount - tbBill.nUseVouchars
                                tbBill.dwUseVoucherID = tbCurrentVouchars.dwVoucherID
                            end
                        end

                        if tbGoodsInfo.bLiftedFace and nFaceVouchars > 0 then
                            tbGoodsInfo.tbBill = {}
                            tbGoodsInfo.tbBill.bUseFaceVouchars = true
                            tbGoodsInfo.tbBill.nUseVouchars = math.min(tbGoodsInfo.tbPrice.nPrice, nFaceVouchars)
                            tbGoodsInfo.tbBill.nCoin = tbBill.nCoin
                            tbGoodsInfo.tbBill.nOriginalCoin = tbGoodsInfo.tbPrice.nPrice
                        end

                        if tbGoodsInfo.bLiftedFace or tbGoodsInfo.bForbidDisCoupon or not tbGoodsInfo.bDisCoupon then
                            tbBill.nForbidDisCouponCoin = tbBill.nForbidDisCouponCoin + nCoinPrice * tbGoodsInfo.nBuyCount
                        end
                    end
                elseif tbGoodsInfo.tbPrice.nPayType == COIN_SHOP_PAY_TYPE.REWARDS then
                    tbBill.nRewards = tbBill.nRewards + tbGoodsInfo.tbPrice.nPrice * tbGoodsInfo.nBuyCount
                end
                tbBill.nBuyCount = tbBill.nBuyCount + 1

                tbGoodsInfo.ePayType = tbGoodsInfo.tbPrice.nPayType
                tbGoodsInfo.eTimeLimitType = tbGoodsInfo.tbPrice.nTimeType
                tbGoodsInfo.nPrice = tbGoodsInfo.tbPrice.nPrice
                tbGoodsInfo.nDiscount = tbGoodsInfo.tbPrice.nDiscount
                tbGoodsInfo.nAskPayPrice = tbGoodsInfo.tbPrice.nAskPayPrice
            elseif bSave and tbGoodsInfo.nState == ACCOUNT_ITEM_STATUS.HAVE then
                -- TODO：remove this case
            end
        else
            CoinShopData.UpdateDiscoupon(tbGoodsInfo,  { dwDisCouponID = 0, nType = 0 })
        end
    end

    if tbBill.tbDisCoupon then
        local nDisCouponCoin = tbBill.nCoin - tbBill.nForbidDisCouponCoin
        if tbBill.tbDisCoupon.nType == COIN_SHOP_DISCOUNT_TYPE.DISCOUNT then
            nDisCouponCoin = CoinShop_GetDisPrice(nDisCouponCoin, tbBill.tbDisCoupon.nDiscount)
        elseif tbBill.tbDisCoupon.nType == COIN_SHOP_DISCOUNT_TYPE.FULL_CUT then
            if nDisCouponCoin >= tbBill.tbDisCoupon.nFull then
                nDisCouponCoin = nDisCouponCoin - tbBill.tbDisCoupon.nCut
            end
        end
        tbBill.nDisCouponCoin = nDisCouponCoin + tbBill.nForbidDisCouponCoin - tbBill.nUseVouchars      -- 无折扣时候就不用代币了吗？？？
        tbBill.nDisCouponSaveCoin = tbBill.nCoin - tbBill.nDisCouponCoin - tbBill.nUseVouchars
    end

    return tbBill
end

function CoinShopData.UpdateDiscoupon(tBuyItem, tbDisCoupon)
    tBuyItem.bDisCoupon = false
    tBuyItem.bFullcut = false
    if tBuyItem.nState == ACCOUNT_ITEM_STATUS.NORMAL and tBuyItem.tbPrice then
        local tPrice = tBuyItem.tbPrice
        if tPrice.nPayType == COIN_SHOP_PAY_TYPE.COIN then
            if tbDisCoupon and not tBuyItem.bLimitItem and not tBuyItem.bForbidDisCoupon
            and g_pClientPlayer.CheckCanUseDisCouponForGoods(
                tbDisCoupon.dwDisCouponID, tBuyItem.eGoodsType, tBuyItem.dwGoodsID
            ) then
                if tbDisCoupon.nType == COIN_SHOP_DISCOUNT_TYPE.FULL_CUT then
                    tPrice.bDisCoupon = false
                    tPrice.nDisCoupon = 100
                    tBuyItem.bDisCoupon = true
                    tBuyItem.bFullcut = true
                elseif tbDisCoupon.nType == COIN_SHOP_DISCOUNT_TYPE.DISCOUNT then
                    tPrice.bDisCoupon = true
                    tPrice.nDisCoupon = tbDisCoupon.nDiscount
                    tBuyItem.bDisCoupon = true
                    tBuyItem.bFullcut = false
                end
            else
                tPrice.bDisCoupon = false
                tPrice.nDisCoupon = 100
            end
        end
	end
end

function CoinShopData.IntelligentSelectDisCoupon(tBuy)
    local dwDisCouponID = 0
	local nMaxDiscount = 0
    local bIsAccountLevel = false
    for _, tDisCoupon in ipairs(CoinShopData.GetWelfares()) do
		local nDiscount = CoinShopData.GetDisCouponPrice(tBuy, dwDisCouponID, tDisCoupon, true)
		if (nDiscount > nMaxDiscount) or (nDiscount == nMaxDiscount and bIsAccountLevel and not tDisCoupon.bIsAccountLevel) then
			nMaxDiscount = nDiscount
			dwDisCouponID = tDisCoupon.dwDisCouponID
            bIsAccountLevel = tDisCoupon.bIsAccountLevel
		end
	end
	return dwDisCouponID
end

function CoinShopData.GetDisCouponPrice(tBuy, dwDisCouponID, tDisCoupon, bChoose)
	if not tDisCoupon then
		tDisCoupon = CoinShopData.GetWelfare(dwDisCouponID)
	end
	local nDiscount = 0
	local nPrice = 0
	local bDis = false
	if not g_pClientPlayer then
		return
	end
	for _, tBuyItem in ipairs(tBuy) do
		if (not bChoose or tBuyItem.bChoose) and tBuyItem.ePayType == COIN_SHOP_PAY_TYPE.COIN
		and CoinShop_GetCollectInfo(tBuyItem.eGoodsType, tBuyItem.dwGoodsID)
		and g_pClientPlayer.CheckDisCouponValid(tDisCoupon.dwDisCouponID)
		and g_pClientPlayer.CheckCanUseDisCouponForGoods(tDisCoupon.dwDisCouponID, tBuyItem.eGoodsType, tBuyItem.dwGoodsID)
		and not tBuyItem.bForbidDisCoupon and not tBuyItem.bHave
		then
			local nItemPrice = CoinShop_GetPrice(tBuyItem.dwGoodsID, tBuyItem.eGoodsType)
			if tDisCoupon.nType == COIN_SHOP_DISCOUNT_TYPE.FULL_CUT then
				nPrice = nPrice + nItemPrice * (tBuyItem.nBuyCount or 1)
				bDis = true
			elseif tDisCoupon.nType == COIN_SHOP_DISCOUNT_TYPE.DISCOUNT then
				nDiscount = nDiscount + nItemPrice * (100 - tDisCoupon.nDiscount) / 100 * (tBuyItem.nBuyCount or 1)
			end
		end
	end

	if tDisCoupon.nType == COIN_SHOP_DISCOUNT_TYPE.FULL_CUT and bDis then
		if nPrice >= tDisCoupon.nFull then
			nDiscount = tDisCoupon.nCut
		end
	end
	return nDiscount
end

function CoinShopData.ExtractLink(szLink)
    local szType, szID = szLink:match("(%w+)/(%w+)")
    local nType = tonumber(szType)
    local dwID = tonumber(szID)
    return nType, dwID
end

function CoinShopData.ExtractLinkTitle(szLink)
    local szType, szClassID = szLink:match("(%w+)/(%w+)")
    local nType = tonumber(szType)
    local nClass = tonumber(szClassID)
    return nType, nClass
end

function CoinShopData.LinkGoods(szLink, bShop)
    local fnLink = function ()
        Event.Dispatch(EventType.OnCoinShopLink, szLink, bShop)
    end
    if not UIMgr.GetView(VIEW_ID.PanelExteriorMain) then
        UIMgr.Open(VIEW_ID.PanelExteriorMain, fnLink)
    else
        fnLink()
    end
end

function CoinShopData.LinkTitle(szLink, bShop)
    local fnLink = function ()
        Event.Dispatch(EventType.OnCoinShopLinkTitle, szLink, bShop)
    end
    if not UIMgr.GetView(VIEW_ID.PanelExteriorMain) then
        UIMgr.Open(VIEW_ID.PanelExteriorMain, fnLink)
    else
        fnLink()
    end
end

function CoinShopData.LinkFace(szLink)
    local fnLink = function ()
        Timer.Add(self, 0.5, function ()
            Event.Dispatch(EventType.OnCoinShopLinkFace, szLink)
        end)
    end
    if not UIMgr.GetView(VIEW_ID.PanelExteriorMain) then
        UIMgr.Open(VIEW_ID.PanelExteriorMain, fnLink)
    else
        fnLink()
    end
end


function CoinShopData.LinkHair(szLink)
    local fnLink = function ()
        Event.Dispatch(EventType.OnCoinShopLinkHair, szLink)
    end
    if not UIMgr.GetView(VIEW_ID.PanelExteriorMain) then
        UIMgr.Open(VIEW_ID.PanelExteriorMain, fnLink)
    else
        fnLink()
    end
end

function CoinShopData.LinkPendant(szLink, bOpenCustom)
    local fnLink = function ()
        Event.Dispatch(EventType.OnCoinShopLinkPendant, szLink, bOpenCustom)
    end
    if not UIMgr.GetView(VIEW_ID.PanelExteriorMain) then
        UIMgr.Open(VIEW_ID.PanelExteriorMain, fnLink)
    else
        fnLink()
    end
end

function CoinShopData.IsStartTimeOK(nStartTime, nTime)
    return nStartTime == -1 or nTime >= Time_AddZone(nStartTime)
end

local nTestTimer
function CoinShopData.TestLink()
    local ids = {10035, 9474, 9004, 8135, 7683, 7638, 7605, 6804, 6803}
    local nIndex = 1
    Timer.DelTimer(CoinShopData, nTestTimer)
    nTestTimer = Timer.AddCycle(self, 0.75, function()
        if nIndex < #ids then
            CoinShopData.LinkGoods(3 .. "/" .. ids[nIndex], true)
            nIndex = nIndex + 1
        else
            Timer.DelTimer(CoinShopData, nTestTimer)
        end
    end)
end


--------------CoinShopData--------------------------
function CoinShopData.IsBuying()
    return m_bIsBuying
end

function CoinShopData.SetIsBuying(bIsBuying)
    m_bIsBuying = bIsBuying
end

function CoinShopData.Buy(tbGoods, tbBill, bSave)
	if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EXTERIOR, "CoinShop") then
		return
	end

	if CheckHaveUnPayOrder() then
		return
	end

	if not g_pClientPlayer then
		return
	end

    if CheckPlayerIsRemote(g_pClientPlayer.dwID, g_tStrings.tExteriorBuyRespond[EXTERIOR_BUY_RESPOND_CODE.SELF_REMOTE]) then
		return
	end

	CoinShopData.tFaceLift = nil
	CoinShopData.tBody = nil
	CoinShopData.tOtherSave = {}
	local tBuyList = {}
	for _, tBuyItem in ipairs(tbGoods) do
		local nState = tBuyItem.nState
		local bCollect = CoinShop_GetCollectInfo(tBuyItem.eGoodsType, tBuyItem.dwGoodsID)
		if nState == ACCOUNT_ITEM_STATUS.OFF or (tBuyItem.bChoose and bCollect) then
            if tBuyItem.bNewFace then
                CoinShopData.tFaceLift = tBuyItem
            elseif tBuyItem.bLiftedFace then
                CoinShopData.tFaceLift = tBuyItem
            elseif tBuyItem.bOtherSave then
                table.insert(CoinShopData.tOtherSave, tBuyItem)
            elseif tBuyItem.bBody then
                CoinShopData.tBody = tBuyItem
			else
				if nState == ACCOUNT_ITEM_STATUS.NORMAL then
					table.insert(tBuyList, tBuyItem)
				elseif bSave and
					(
						nState == ACCOUNT_ITEM_STATUS.HAVE or
						nState == ACCOUNT_ITEM_STATUS.OFF
					)
				then
					tBuyItem.ePayType = COIN_SHOP_PAY_TYPE.INVALID
					table.insert(tBuyList, tBuyItem)
				end
			end
		end
	end

    local dwDisCouponID = tbBill.tbDisCoupon and tbBill.tbDisCoupon.dwDisCouponID or 0
	local fnBuyEX = function()
        local fnAction = function() CoinShopData._Buy(tBuyList, tbBill, bSave, dwDisCouponID, function ()
            -- EVENT
        end)  end
        local bInSurpriseFree = CoinShopData.IsInSurpriseFree()
        local nFreeCoin = tbBill.nDisCouponCoin
        if CoinShopData.tFaceLift then
            nFreeCoin = tbBill.nDisCouponCoin - (CoinShopData.tFaceLift.nPrice or 0)
        end

        if bInSurpriseFree and nFreeCoin > 0 then
            CoinShopData.ConfirmSurpriseFree(tbBill, nFreeCoin, fnAction)
        else
            fnAction()
        end
    end

	if #tBuyList > 0 then
		CoinShopData.DisJudge(tBuyList, bSave, dwDisCouponID, fnBuyEX, ChooseNewDisCoupon)
	else --捏脸不走折扣券判断
		fnBuyEX()
	end
end

function CoinShopData.ConfirmSurpriseFree(tbBill, nFreeCoin, fnAction)
	if not g_pClientPlayer then
		return false
	end

    local bNextFree = UIscript_SurpriseFree_ActUI(g_pClientPlayer)
	local szSure = g_tStrings.STR_HOTKEY_SURE
	local szCancel = g_tStrings.STR_HOTKEY_CANCEL
	local szMsg = ""
	if bNextFree then
		szMsg = GetFormatText(g_tStrings.SURPRISE_FREE_MSG2)
	else
		local fP, nNextCoin, fNextP = UIscript_SurpriseFree_CheckFreeRate(g_pClientPlayer, nFreeCoin)
		local szCoin = GetFormatText(nFreeCoin, 31)
		local szPercent = GetFormatText(fP .. "%", 31)
		szMsg = string.format(g_tStrings.SURPRISE_FREE_MSG, szCoin, szPercent)

		if nNextCoin and fNextP then
			local szNextCoin = GetFormatText(nNextCoin, 31)
			local szNextPercent = GetFormatText(fNextP .. "%", 31)
			szMsg = szMsg .. string.format(g_tStrings.SURPRISE_FREE_MSG1, szNextCoin, szNextPercent)
			szSure = g_tStrings.SURPRISE_FREE_SURE
			szCancel = g_tStrings.SURPRISE_FREE_CANCEL
		end
	end

    local Dialog = UIHelper.ShowConfirm(szMsg, function ()
        fnAction()
    end)
    Dialog:SetButtonContent("Confirm", szSure)
    Dialog:SetButtonContent("Cancel", szCancel)

    return true
end

function CoinShopData.IsInSurpriseFree()
	if not g_pClientPlayer then
		return false
	end
	local bNextFree, _, bAlreadyUsed = UIscript_SurpriseFree_ActUI(g_pClientPlayer)
	if bAlreadyUsed then
		return false
	end
	local bInSurpriseFree = ActivityData.IsActivityOn(ACTIVITY_ID.COINSHOP_SURPRISE_FREE)
	return bInSurpriseFree
end

function CoinShopData.DisJudge(tBuy, bSave, dwDisCouponID, fnBuy, fnChoose)
	local hCoinShopClient = GetCoinShopClient()
	local nRetCode, dwSuggestDisCouponID, dwGoodsID, nDisCouponSaveCoin = hCoinShopClient.GetBestDisCoupon(tBuy)
	local eGoodsType = COIN_SHOP_GOODS_TYPE.ITEM
	if nRetCode ~= COIN_SHOP_ERROR_CODE.SUCCESS then
		OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tCoinShopNotify[nRetCode])
        OutputMessage("MSG_SYS", g_tStrings.tCoinShopNotify[nRetCode])
		return
	end
	if dwSuggestDisCouponID and dwSuggestDisCouponID ~= 0 then
		if dwSuggestDisCouponID == dwDisCouponID then --当前用的优惠券和推荐的一样
			fnBuy()
		else
			if dwGoodsID == 0 then --是否选择优惠券
				fnBuy()
			else --是否购买优惠券
				-- local tDisCoupon 	= g_tTable.CoinShop_Welfare:Search(dwSuggestDisCouponID)
				-- local fX, fY 		= GetMsgPos(hFrame)
				-- local szMsg 		= string.format(g_tStrings.EXTERIOR_BUY_DISCOUNT, tDisCoupon.szMenuOption, nDisCouponSaveCoin)
				-- local tMsg 			= {
				-- 	x = fX,
				-- 	y = fY,
				-- 	bModal = true,
				-- 	bVisibleWhenHideUI = true,
				-- 	bRichText = true,
				-- 	szName = "exterior_buy_dis",
				-- 	fnAutoClose = function() return not IsOpened() end,
				-- }
				-- local szStr
				-- local tPriceInfo = CoinShop_GetRewardsPriceInfo(dwGoodsID)
				-- local tPrice = tPriceInfo[1]
				-- if tPrice then
				-- 	if tPrice.nPayType == COIN_SHOP_PAY_TYPE.COIN then
				-- 		table.insert(tMsg, {
				-- 			szOption = string.format(g_tStrings.EXTERIOR_BUY_BY_COIN, tPrice.nPrice),
				-- 			fnAction = function()
				-- 				local nRetCode = CoinShop_BuyItem(dwGoodsID, eGoodsType, 1, COIN_SHOP_PAY_TYPE.COIN)
				-- 				if nRetCode == COIN_SHOP_ERROR_CODE.SUCCESS then
				-- 					if fnChoose then
				-- 						SetSelectDisAndBuyValue(dwSuggestDisCouponID, fnChoose)
				-- 						UnRegisterEvent("COIN_SHOP_BUY_RESPOND", SelectDisAndBuy)
				-- 						RegisterEvent("COIN_SHOP_BUY_RESPOND", SelectDisAndBuy)
				-- 					end
				-- 				end
				-- 			end
				-- 		})
				-- 		szStr = string.format(g_tStrings.EXTERIOR_BUY_DISCOUNT_TIP[2], tPrice.nPrice)
				-- 	else
				-- 		local nRewards = tPrice.nPrice
				-- 		table.insert(tMsg, 	{
				-- 			szOption = string.format(g_tStrings.EXTERIOR_BUY_BY_REWARDS, nRewards),
				-- 			fnAction = function()
				-- 				local hPlayer = GetClientPlayer()
				-- 				if not hPlayer then
				-- 					return
				-- 				end
				-- 				local nPlayerRewards = hPlayer.GetRewards()
				-- 				if nRewards > nPlayerRewards then --���ֲ���
				-- 					local szMsg = g_tStrings.EXTERIOR_ERROR_BUY_LESS_MONEY
				-- 					local fX, fY = GetMsgPos(hFrame)
				-- 					local tMsg =
				-- 					{
				-- 						x = fX,
				-- 						y = fY,
				-- 						bModal = true,
				-- 						bVisibleWhenHideUI = true,
				-- 						szName = "exterior_dis_less_money",
				-- 						fnAutoClose = function() return not IsOpened() end,
				-- 						szMessage = szMsg,
				-- 						{szOption = g_tStrings.STR_HOTKEY_SURE},
				-- 					}
				-- 					MessageBox(tMsg)
				-- 					return
				-- 				end
				-- 				local nRetCode = CoinShop_BuyItem(dwGoodsID, eGoodsType, 1, COIN_SHOP_PAY_TYPE.REWARDS)
				-- 				if nRetCode == COIN_SHOP_ERROR_CODE.SUCCESS then
				-- 					if fnChoose then
				-- 						SetSelectDisAndBuyValue(dwSuggestDisCouponID, fnChoose)
				-- 						UnRegisterEvent("COIN_SHOP_BUY_RESPOND", SelectDisAndBuy)
				-- 						RegisterEvent("COIN_SHOP_BUY_RESPOND", SelectDisAndBuy)
				-- 					end
				-- 				end
				-- 			end
				-- 		})
				-- 		szStr = string.format(g_tStrings.EXTERIOR_BUY_DISCOUNT_TIP[1], nRewards)
				-- 	end
				-- end
				-- table.insert(tMsg, {
				-- 	szOption = g_tStrings.EXTERIOR_BUY_DIRECT,
				-- 	fnAction = function()
				-- 		fnBuy()
				-- 	end}
				-- )
				-- local szMsg = string.format(g_tStrings.EXTERIOR_BUY_DISCOUNT, tDisCoupon.szMenuOption, nDisCouponSaveCoin, szStr)
				-- tMsg.szMessage = szMsg
				-- MessageBox(tMsg)
			end
		end
	else --没有推荐优惠券
		fnBuy()
	end
end

local function BuyBodyCountItem()
	local tLine = CoinShopData.GetBuyBodyCountItem()
	if tLine then
		local tInfo = CoinShop_GetPriceInfo(tLine.dwGoodsID, COIN_SHOP_GOODS_TYPE.ITEM)
		local bDis, szDisCount = CoinShop_GetDisInfo(tInfo)
		local nPrice, nOriginalPrice = CoinShop_GetShowPrice(tInfo)
		local szName = CoinShop_GetGoodsName(eGoodsType, dwGoodsID)
		local szMsg = FormatString(g_tStrings.COINSHOP_BODY_ERROR_LESS_COUNT, nPrice, szName, tLine.nCount)

        szMsg = string.pure_text(szMsg)
        UIHelper.ShowConfirm(szMsg, function ()
            CoinShop_BuyItem(tLine.dwGoodsID, COIN_SHOP_GOODS_TYPE.ITEM, 1)
        end)

		return true
	else
		OutputMessage("MSG_SYS",g_tStrings.STR_BODY_SHOP_COIN_SHOP_COUNT_ERROR)
		OutputMessage("MSG_ANNOUNCE_NORMAL",g_tStrings.STR_BODY_SHOP_COIN_SHOP_COUNT_ERROR)
	end
end

function CoinShopData.DealBodySave()
	if not CoinShopData.tBody then
		return
	end

	local tBody = CoinShopData.tBody
	if tBody.bHave then
		CoinShopData.EquipBody(tBody.nIndex)
	elseif tBody.nIndex then
		return CoinShopData.ReplaceBody(tBody.nIndex, tBody.tBody)
	else
		return CoinShopData.BuyBody(tBody.tBody)
	end
	CoinShopData.tBody = nil
end

function CoinShopData.EquipBody(nIndex)
	local hManager = GetBodyReshapingManager()
	if not hManager then
		return
	end

	local nRetCode = hManager.Equip(nIndex)
	if nRetCode == BODY_RESHAPING_ERROR_CODE.SUCCESS then
		-- local hFrame = GetFrame()
		-- if hFrame then
		-- 	hFrame.bBuyNormal = true
		-- 	UpdateAllBuyBtnState(hFrame)
		-- end
        Timer.Add(CoinShopData, 0.5, function ()
            FireUIEvent("COINSHOP_UPDATE_ROLE")
        end)
	else
		OutputMessage("MSG_SYS",g_tStrings.tBodyEquipNotify[nRetCode])
		OutputMessage("MSG_ANNOUNCE_NORMAL",g_tStrings.tBodyEquipNotify[nRetCode])
	end
end

function CoinShopData.ReplaceBody(nIndex, tBody)
	local hManager = GetBodyReshapingManager()
	if not hManager then
		return
	end

	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end
	local nFreeCount, nTimeLimitFreeChance = hPlayer.GetBodyReshapingFreeChance()
	if nFreeCount + nTimeLimitFreeChance == 0 then
		return BuyBodyCountItem()
	end
	local nRetCode = hManager.Replace(nIndex, tBody)
	if nRetCode == BODY_RESHAPING_ERROR_CODE.SUCCESS then
		-- local hFrame = GetFrame()
		-- if hFrame then
		-- 	hFrame.bBuyNormal = true
		-- 	UpdateAllBuyBtnState(hFrame)
		-- end
        Timer.Add(CoinShopData, 0.5, function ()
            FireUIEvent("COINSHOP_UPDATE_ROLE")
        end)
	else
		OutputMessage("MSG_SYS",g_tStrings.tBodyReplaceNotify[nRetCode])
		OutputMessage("MSG_ANNOUNCE_NORMAL",g_tStrings.tBodyReplaceNotify[nRetCode])
	end
end

function CoinShopData.EquipLiftedFace(nIndex, bNewFace)
	local hManager = GetFaceLiftManager()
	if not hManager then
		return
	end

	local nRetCode = hManager.Equip(nIndex)
	if nRetCode == FACE_LIFT_ERROR_CODE.SUCCESS then
		-- local hFrame = GetFrame()
		-- if hFrame then
		-- 	hFrame.bBuyNormal = true
		-- 	UpdateAllBuyBtnState(hFrame)
		-- end
        Timer.Add(CoinShopData, 0.5, function ()
            FireUIEvent("COINSHOP_UPDATE_ROLE")
        end)
	else
		if bNewFace then
			TipsHelper.ShowNormalTip(g_tStrings.tNewFaceLiftNotify[nRetCode])
		else
			TipsHelper.ShowNormalTip(g_tStrings.tFaceLiftNotify[nRetCode])
		end
	end
end

function CoinShopData.GetLiftedFaceTruePrice(bNewFace)
	local bFreeChance = CoinShopData.GetFreeChance(bNewFace)
    if bFreeChance then
        return 0, 0
    end
end

function CoinShopData.BuyFaceLift(tFaceData, nFaceIndex, nPrice)
	local hManager = GetFaceLiftManager()
	if not hManager then
		return
	end
	nFaceIndex = nFaceIndex or 0
	local nLogicPrice, nTruePrice = CoinShopData.GetLiftedFaceTruePrice(tFaceData.bNewFace)
	nLogicPrice = nLogicPrice or nPrice
	nTruePrice = nTruePrice or nPrice
	-- if Web_QRCodeRecharge.Judge(nTruePrice) then
	-- 	return
	-- end
	local nRetCode = hManager.Buy(COIN_SHOP_PAY_TYPE.COIN, tFaceData, nFaceIndex, nLogicPrice)
	if nRetCode == FACE_LIFT_ERROR_CODE.SUCCESS then
		-- local hFrame = GetFrame()
		-- if hFrame then
		-- 	hFrame.bBuyNormal = true
		-- 	UpdateAllBuyBtnState(hFrame)
		-- end
        Timer.Add(CoinShopData, 0.5, function ()
            FireUIEvent("COINSHOP_UPDATE_ROLE")
        end)
	else
		if tFaceData.bNewFace then
			OutputMessage("MSG_SYS",g_tStrings.tNewFaceLiftNotify[nRetCode])
			OutputMessage("MSG_ANNOUNCE_NORMAL",g_tStrings.tNewFaceLiftNotify[nRetCode])
		else
			OutputMessage("MSG_SYS",g_tStrings.tNewFaceLiftNotify[nRetCode])
			OutputMessage("MSG_ANNOUNCE_NORMAL",g_tStrings.tNewFaceLiftNotify[nRetCode])
		end
	end
end

function CoinShopData.DealFaceLift()
	if not CoinShopData.tFaceLift then
		return
	end

	local tFaceLift = CoinShopData.tFaceLift
	if tFaceLift.bHave then
		CoinShopData.EquipLiftedFace(tFaceLift.nIndex, tFaceLift.bNewFace)
	else
		CoinShopData.BuyFaceLift(tFaceLift.tFaceData, tFaceLift.nIndex, tFaceLift.nPrice)
	end
	CoinShopData.tFaceLift = nil
end

function CoinShopData.DecalHairDyeingIndex()
    local hManager = GetHairCustomDyeingManager()
    if not hManager then
        return
    end
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local tbBuySaveList = CoinShopPreview.GetBuySaveList()
	for _, tBuyItem in ipairs(tbBuySaveList) do
		if tBuyItem.bHave and tBuyItem.eGoodsType == COIN_SHOP_GOODS_TYPE.HAIR then
			local nEquipIndex = hPlayer.GetEquippedHairCustomDyeingIndex(tBuyItem.dwGoodsID)
			if nEquipIndex ~= tBuyItem.nHairDyeingIndex then
				local nCode = hManager.Equip(tBuyItem.dwGoodsID, tBuyItem.nHairDyeingIndex)
				if nCode ~= HAIR_CUSTOM_DYEING_ERROR_CODE.SUCCESS then
					local szChannel = "MSG_ANNOUNCE_RED"
					local szMsg = g_tStrings.tHairDyeingEquipNotify[nCode]
					OutputMessage(szChannel, szMsg)
					OutputMessage("MSG_SYS", szMsg)
				end
				return
			end
		end
	end
end

function CoinShopData.DecalOtherSave()
	local tOtherSave = CoinShopData.tOtherSave
	if not tOtherSave or #tOtherSave <= 0 then
		return
	end

	local hPlayer = GetClientPlayer()

	for _, tBuyItem in ipairs(tOtherSave) do
		local hItemInfo = GetItemInfo(tBuyItem.dwTabType, tBuyItem.dwTabIndex)
		if tBuyItem.bPendantPet then
			hPlayer.EquipPendentPet(tBuyItem.dwTabIndex)
			if tBuyItem.dwTabIndex > 0 then
				hPlayer.ChangePendentPetPos(tBuyItem.dwTabIndex, tBuyItem.nPos)
			end
        elseif tBuyItem.bEffectSfx then
			hPlayer.SetCurrentSFX(tBuyItem.nEffectID)
			if tBuyItem.nType == PLAYER_SFX_REPRESENT.SURROUND_BODY then
				CoinShopData.CustomPendantSetLocalDataToPlayer(PLAYER_SFX_REPRESENT.SURROUND_BODY, tBuyItem.nEffectID)
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

local function RegisterBuyBodyCountItem()
    if not IsUITableRegister("BuyBodyCountItem") then
        RegisterUITable("BuyBodyCountItem", g_tBuyBodyCountItem.Path, g_tBuyBodyCountItem.Title)
    end
end

function CoinShopData.GetBuyBodyCountItem()
	RegisterBuyBodyCountItem()
	local nCount = g_tTable.BuyBodyCountItem:GetRowCount()
	for i = 2, nCount do
		local tInfo = g_tTable.BuyBodyCountItem:GetRow(i)
		local tLine = Table_GetRewardsItem(tInfo.dwGoodsID)
		if not tLine then
			return
		end
        local bShow = CoinShop_RewardsShow(tLine.dwLogicID, tLine.nClass)
		if bShow then
			return tInfo
		end
	end
end

function CoinShopData.BuyBody(tBody)
	local hManager = GetBodyReshapingManager()
	if not hManager then
		return
	end

	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end

	local nBoxCount = hPlayer.GetBodyBoneBoxSize()
	local nCount = hPlayer.GetBodyBoneCount()
	if nCount == nBoxCount then
		OutputMessage("MSG_SYS",g_tStrings.STR_CHECKOUT_BODY_ERROR_BOX_SIZE_LIMIT)
		OutputMessage("MSG_ANNOUNCE_NORMAL",g_tStrings.STR_CHECKOUT_BODY_ERROR_BOX_SIZE_LIMIT)
		return
	end
	local nFreeCount, nTimeLimitFreeChance = hPlayer.GetBodyReshapingFreeChance()
	if nFreeCount + nTimeLimitFreeChance == 0 then
		return BuyBodyCountItem()
	end
	local nRetCode = hManager.Add(tBody)
	if nRetCode == BODY_RESHAPING_ERROR_CODE.SUCCESS then
		-- local hFrame = GetFrame()
		-- if hFrame then
		-- 	hFrame.bBuyNormal = true
		-- 	UpdateAllBuyBtnState(hFrame)
		-- end
        Timer.Add(CoinShopData, 0.5, function ()
            FireUIEvent("COINSHOP_UPDATE_ROLE")
        end)
	else
		OutputMessage("MSG_SYS",g_tStrings.tBodyBuyNotify[nRetCode])
		OutputMessage("MSG_ANNOUNCE_NORMAL",g_tStrings.tBodyBuyNotify[nRetCode])
	end
end

function CoinShopData._Buy(tBuy, tbBill, bSave, dwDisCouponID, fnAction)

    local hCoinShopClient = GetCoinShopClient()
	local bEnd = CoinShopData.DealBodySave()
	if bEnd then
		return
	end
	CoinShopData.DealFaceLift()
	CoinShopData.DecalOtherSave()

	if #tBuy <= 0 then
		return
	end
	local nRetCode = hCoinShopClient.Buy(tBuy, bSave, dwDisCouponID, tbBill.dwUseVoucherID)
	if nRetCode == COIN_SHOP_ERROR_CODE.SUCCESS then
		if fnAction then
			fnAction()
		end
        CoinShopData.SetIsBuying(true)
	--	hFrame.bBuyNormal = true
	--	UpdateAllBuyBtnState(hFrame)
	elseif nRetCode == COIN_SHOP_ERROR_CODE.NOT_HAVE_PREORDER_COUPON and CoinShopData.OnPerorderError(tBuy) then
		-- CoinShopData.OnPerorderError(tBuy)
	else
		OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tCoinShopNotify[nRetCode])
		OutputMessage("MSG_SYS", g_tStrings.tCoinShopNotify[nRetCode])
	end
end

function CoinShopData.GetPreOrderID(tBuy)
	local hCoinShopClient = GetCoinShopClient()
	if not hCoinShopClient then
		return
	end
	for _, tItem in ipairs(tBuy) do
		local dwPreOrderID = hCoinShopClient.GetNeedPreOrderID(tItem.eGoodsType, tItem.dwGoodsID)
		if dwPreOrderID > 0 then
			return dwPreOrderID
		end
	end
end

function CoinShopData.OnPerorderError(tBuy)
	local dwPreOrderID = CoinShopData.GetPreOrderID(tBuy)
	if dwPreOrderID then
		local tLine = CoinShop_GetPreOrder(dwPreOrderID)
        if tLine then
            OutputMessage("MSG_ANNOUNCE_NORMAL", tLine.szErrorMsg)
            OutputMessage("MSG_SYS", tLine.szErrorMsg .. "\n")
            return true
        end
	end
    return false
end

function CoinShopData.IsLessMoney(tbBill)
	if not g_pClientPlayer then
		return
	end

	local nCoin = tbBill.nDisCouponCoin
    local nUseVouchars = tbBill.nUseVouchars



	local bLessMoney = false
	local nLessMoney
	if tbBill.nDisCouponCoin > 0 and tbBill.nDisCouponCoin > g_pClientPlayer.nCoin then
		bLessMoney = true
		nLessMoney = tbBill.nDisCouponCoin - g_pClientPlayer.nCoin
	end

    local nRewards = tbBill.nRewards
    local nLessRewards
	if tbBill.nRewards > CoinShopData.GetRewards() then
		bLessMoney = true
        nLessRewards = CoinShopData.GetRewards() - tbBill.nRewards
	end
	return bLessMoney, nCoin, nLessMoney, nRewards, nLessRewards
end

function CoinShopData.CheckCanUseDisCouponForGoods(dwDisCouponID, tBuy)
	if not g_pClientPlayer.CheckDisCouponValid(dwDisCouponID) then
		return false
	end
	local tDisCoupon = CoinShopData.GetWelfare(dwDisCouponID)
	local nPrice = 0
	local bDis = false
	for _, tBuyItem in ipairs(tBuy) do
		if tBuyItem.bChoose and not tBuyItem.bHave
		and not tBuyItem.bForbidDisCoupon
		and CoinShop_GetCollectInfo(tBuyItem.eGoodsType, tBuyItem.dwGoodsID)
		and g_pClientPlayer.CheckCanUseDisCouponForGoods(dwDisCouponID, tBuyItem.eGoodsType, tBuyItem.dwGoodsID) then
			if tDisCoupon.nType == COIN_SHOP_DISCOUNT_TYPE.DISCOUNT then
				return true
			elseif tDisCoupon.nType == COIN_SHOP_DISCOUNT_TYPE.FULL_CUT then
				local nItemPrice = CoinShop_GetPrice(tBuyItem.dwGoodsID, tBuyItem.eGoodsType)
				nPrice = nPrice + nItemPrice * (tBuyItem.nBuyCount or 1)
				bDis = true
			end
		end
	end

	if bDis and tDisCoupon.nType == COIN_SHOP_DISCOUNT_TYPE.FULL_CUT then
		if nPrice >= tDisCoupon.nFull then
			return true
		end
	end

	return false
end

function CoinShopData.CheckDisCouponUsable(tbGoods, tbBill)
	if tbBill and tbBill.tbDisCoupon and tbBill.tbDisCoupon.dwDisCouponID and tbBill.tbDisCoupon.dwDisCouponID ~= 0 and not CoinShopData.CheckCanUseDisCouponForGoods(tbBill.tbDisCoupon.dwDisCouponID, tbGoods) then
		return false
	end
	return true
end

function CoinShopData.GetUsableDisCouponList(tbGoods)
	local tList = CoinShopData.GetWelfares()
	local tHash = {}
	for i, card in ipairs_r(tList) do
		if tHash[card.dwDisCouponID]
		or not CoinShopData.CheckCanUseDisCouponForGoods(card.dwDisCouponID, tbGoods)
		then
			table.remove(tList, i)
		else
			tHash[card.dwDisCouponID] = true
		end
	end
	return tList
end

function CoinShopData.GetWelfares(bFurniture)
	local hCoinShopClient = GetCoinShopClient()
	if not hCoinShopClient then
		return
	end
	local tList = {}
	bFurniture = bFurniture or false
	for i, welfare in ipairs(CoinShopData.GetDisCouponList()) do
		local bF = hCoinShopClient.CheckCouponCanUseForFurniture(welfare.dwDisCouponID)
		if bFurniture == bF then
			local tLine = CoinShopData._FullWelfareInfo(welfare)
			if tLine then
				table.insert(tList, tLine)
			end
		end
	end
	CoinShopData._SortWelfares(tList)
	return tList
end

function CoinShopData.GetNewWelfares(bFurniture)
    local hCoinShopClient = GetCoinShopClient()
	if not hCoinShopClient then
		return
	end
	local tList = {}
	bFurniture = bFurniture or false
	for i, welfare in ipairs(self.GetDisCouponList()) do
		local bF = hCoinShopClient.CheckCouponCanUseForFurniture(welfare.dwDisCouponID)
		if bFurniture == bF then
			local tLine = self._FullWelfareInfo(welfare)
			if not Storage.CoinShop.tVisitedWelfare[tLine.dwDisCouponID .. "|" .. tLine.nDisappearTime] -- 新的没有点过的打折券
			or ( -- 快要过期的打折券
				tLine.nDisappearTime > 0 and tLine.nDisappearTime < GetGSCurrentTime() + self.ALERT_VALID_SEC
				and Storage.CoinShop.tVisitedWelfare[tLine.dwDisCouponID .. "|" .. tLine.nDisappearTime] < tLine.nDisappearTime - self.ALERT_VALID_SEC
			) then
				table.insert(tList, tLine)
			end
		end
	end
	self._SortWelfares(tList)
	return tList
end

function CoinShopData.VisitWelfare(welfare)
    if not welfare then
        return
    end
    Storage.CoinShop.tVisitedWelfare[welfare.dwDisCouponID .. "|" .. welfare.nDisappearTime] = GetGSCurrentTime()
    Storage.CoinShop.Dirty()
    Event.Dispatch("COINSHOP_PUSHINFO_UPDATE")
end

function CoinShopData.IsNewWelfare(welfare)
    if not welfare then
        return false
    end
    return not Storage.CoinShop.tVisitedWelfare[welfare.dwDisCouponID .. "|" .. welfare.nDisappearTime]
end

function CoinShopData.GetWelfare(dwID)
	for i, welfare in ipairs(CoinShopData.GetDisCouponList()) do
		if welfare.dwDisCouponID == dwID then
			return CoinShopData._FullWelfareInfo(welfare)
		end
	end
end

function CoinShopData.GetDisCouponList()
	local aList, tList = GetCoinShopClient().GetDisCouponList(), {}
	for i, welfare in ipairs(aList) do
		local bExpired
		local szKey = welfare.dwDisCouponID
		if welfare.nExistDuration > 0 then
			bExpired = welfare.nCreateTime + welfare.nExistDuration < GetGSCurrentTime()
			szKey = szKey .. "|" .. (welfare.nCreateTime + welfare.nExistDuration)
		elseif welfare.nEndTime > 0 then
			bExpired = welfare.nEndTime < GetGSCurrentTime()
			szKey = szKey .. "|" .. welfare.nEndTime
		end
		local tLine = tList[szKey]
		if bExpired then
			-- 理论上应该过期的就不要显示了 逻辑10秒才检查一次 可能有延迟 防止功能BUG
		elseif tLine then
			tLine.nCount = tLine.nCount + welfare.nCount
		else
			tList[szKey] = welfare
		end
	end
	aList = {}
	for k, welfare in pairs(tList) do
		table.insert(aList, welfare)
	end
	return aList
end

function CoinShopData._FullWelfareInfo(welfare)
    CoinShopData.tbWelfareCache = CoinShopData.tbWelfareCache or {}

	local tLine = CoinShopData.tbWelfareCache[welfare.dwDisCouponID]
	if tLine == nil then
		tLine = g_tTable.CoinShop_Welfare:Search(welfare.dwDisCouponID) or false
		CoinShopData.tbWelfareCache[welfare.dwDisCouponID] = tLine
	end
	if tLine then
		for k, v in pairs(tLine) do
			welfare[k] = v
		end
		if welfare.nEndTime > 0 then
			welfare.nDisappearTime = welfare.nEndTime
		elseif welfare.nExistDuration > 0 then
			welfare.nDisappearTime = welfare.nCreateTime + welfare.nExistDuration
		else
			welfare.nDisappearTime = -1
		end
		return welfare
	end
end

CoinShopData.ALERT_VALID_SEC = 3600 * 24
function CoinShopData._SortWelfares(tList)
	table.sort(tList, function(c1, c2)
		local nAlertTime = CoinShopData.ALERT_VALID_SEC + GetGSCurrentTime()
		if c1.nDisappearTime > 0 and c1.nDisappearTime < nAlertTime
		and c2.nDisappearTime > 0 and c2.nDisappearTime < nAlertTime then
			return c1.nDisappearTime < c2.nDisappearTime
		elseif c1.nDisappearTime > 0 and c1.nDisappearTime < nAlertTime then
			return true
		elseif c2.nDisappearTime > 0 and c2.nDisappearTime < nAlertTime then
			return false
		else
			return c1.nCreateTime > c2.nCreateTime
		end
	end)
end

--------------CoinShopData end--------------------------
function CoinShopData.StorageCount()
    local tGoodsList = self.GetStorageGoodsList() or {}
    local nCount = #tGoodsList

    return nCount
end

function CoinShopData.GetStorageGoodsList()
    local hCoinShopClient = GetCoinShopClient()
    local tStorageList = hCoinShopClient.GetStorageGoodsList() or {}
    local tCoinShopStorageList = {}
    for _, dwStorageID in ipairs(tStorageList) do
        local tStorage = hCoinShopClient.GetStorageGoodsInfo(dwStorageID)
        if tStorage.eGoodsType ~= COIN_SHOP_GOODS_TYPE.FURNITURE then
            table.insert(tCoinShopStorageList, dwStorageID)
        end
    end
    return tCoinShopStorageList
end

function CoinShopData.GetFreeChance(bNewFace)
	local hPlayer = GetClientPlayer()
	if bNewFace then
		local nCount, nLimitCount, nFreeChanceEndTime = hPlayer.GetFaceLiftFreeChanceV2()
		local bFree = nCount + nLimitCount > 0
		return bFree
	else
		local nCount, nLimitCount, nFreeChanceEndTime = hPlayer.GetFaceLiftFreeChance()
		local bFree = nCount + nLimitCount > 0
		return bFree
	end
end

function CoinShopData.GetPendantRepresentIDByIndex(nRepresentIndex)
    local hPlayer       = GetClientPlayer()
    if not hPlayer then
        return
    end
    local nEquipSub     = CoinShop_RepresentSubToPendantType(nRepresentIndex)
    local dwIndex       = hPlayer.GetSelectPendent(nEquipSub)
    if not dwIndex or dwIndex <= 0 then
        return
    end
    local hItemInfo     = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, dwIndex)
    if not hItemInfo then
        return
    end
    return hItemInfo.nRepresentID
end

function CoinShopData.GetCustomPendantType(nType)
    --把头饰位置数据都存在第一个头饰nType上
    if nType == EQUIPMENT_REPRESENT.HEAD_EXTEND1 or nType == EQUIPMENT_REPRESENT.HEAD_EXTEND2 then
        return EQUIPMENT_REPRESENT.HEAD_EXTEND
    end
    return nType
end

function CoinShopData.GetLocalCustomPendantData(nType, nRepresentID)
    local nType = CoinShopData.GetCustomPendantType(nType)
    if not Storage.CoinShop.CustomPendantInfo[nType] then
        return
    end
    return Storage.CoinShop.CustomPendantInfo[nType][nRepresentID]
end


function CoinShopData.CustomPendantOnSaveToLocal(nType, nRepresentID, tData)
    local nType = CoinShopData.GetCustomPendantType(nType)
    if not Storage.CoinShop.CustomPendantInfo[nType] then
        Storage.CoinShop.CustomPendantInfo[nType] = {}
    end
    Storage.CoinShop.CustomPendantInfo[nType][nRepresentID] = clone(tData)
    Storage.CoinShop.Flush()
end

function CoinShopData.CustomPendantSetLocalDataToPlayer(nType, nRepresentID)
    local tData = CoinShopData.GetLocalCustomPendantData(nType, nRepresentID)
    if tData then
        local hPlayer = GetClientPlayer()
        if not hPlayer then
            return
        end
        LOG.INFO("[CoinShopData]CustomPendantSetLocalDataToPlayer=%d %d", nType, nRepresentID)
        LOG.TABLE(tData)
        local nRetCode = hPlayer.SetEquipCustomRepresentData(nType, nRepresentID, tData)
    end
end

function CoinShopData.CustomPendantPlayerDataToLocal(nRepresentIndex)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    if nRepresentIndex == EQUIPMENT_REPRESENT.FACE_EXTEND and hPlayer.bHideFacePendent then
        return
    end
    local nEquipSub  = CoinShop_RepresentSubToPendantType(nRepresentIndex)
    local dwIndex = hPlayer.GetSelectPendent(nEquipSub)
    if not dwIndex or dwIndex <= 0 then
        return
    end
    local tCustomData = hPlayer.GetEquipCustomRepresentData(nRepresentIndex)
    local hItemInfo = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, dwIndex)
    if not hItemInfo then
        return
    end
    CoinShopData.CustomPendantOnSaveToLocal(nRepresentIndex, hItemInfo.nRepresentID, tCustomData)
end

function CoinShopData.FormatGood(dwGoodsID, eGoodsType, good)
    good = good or {}
	good.dwGoodsID = dwGoodsID
	good.eGoodsType = eGoodsType
	good.nState = ACCOUNT_ITEM_STATUS.NORMAL

	if eGoodsType == COIN_SHOP_GOODS_TYPE.HAIR then
		good.tPriceInfo = HairShop_GetPriceInfo(HAIR_STYLE.HAIR, dwGoodsID)
		good.szTime = HairShop_GetTime(HAIR_STYLE.HAIR, dwGoodsID)

	-- elseif eGoodsType == COIN_SHOP_GOODS_TYPE.FACE then
	-- 	good.tPriceInfo = HairShop_GetPriceInfo(HAIR_STYLE.FACE, dwGoodsID)
	-- 	good.szTime = HairShop_GetTime(HAIR_STYLE.FACE, dwGoodsID)

	elseif eGoodsType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
		local player = GetClientPlayer()
		local nTimeType, nTime = player.IsHaveExterior(dwGoodsID)
		if nTimeType == COIN_SHOP_TIME_LIMIT_TYPE.SEVEN_DAYS_LIMIT then
			good.eGoodsType = COIN_SHOP_GOODS_TYPE.RENEW
			good.nRenewTime = nTime
		end

		good.tPriceInfo = CoinShop_GetExteriorPriceInfo(dwGoodsID)
		good.szTime = CoinShop_GetExteriorTime(dwGoodsID)

	elseif eGoodsType == COIN_SHOP_GOODS_TYPE.ITEM then
		local iteminfo = Table_GetRewardsItem(dwGoodsID)
		good.dwTabType = iteminfo.dwTabType
		good.dwTabIndex = iteminfo.dwIndex

		good.tPriceInfo = CoinShop_GetRewardsPriceInfo(dwGoodsID)
		good.szTime = CoinShop_GetRewardsTime(dwGoodsID)

		local shop = GetRewardsShop()
		local exinfo = shop.GetRewardsShopInfo(dwGoodsID)
		good.bCanBuyMultiple = exinfo.bCanBuyMultiple
	elseif eGoodsType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
		good.tPriceInfo = CoinShop_GetWeaponPriceInfo(dwGoodsID)
		good.szTime = CoinShop_GetWeaponTime(dwGoodsID)
	end
	return good
end

-- ----------------------------------------------------------------------
function CoinShopData.GetSchoolLeftChance()
    -- 当前可领取
    local nChance = 0
    local hPlayer = GetClientPlayer()
	if not hPlayer then
		return 0
	end
	local nBuffStack = Buffer_GetStackNum(28501)
	if nBuffStack < 2 and hPlayer.nLevel >= 120 then
		nChance = 1
	end

	local nValue = hPlayer.GetExtPoint(744)
    if nValue and nValue ~= 0 then
        for nPos = 1, nValue do
            local nState = hPlayer.GetExtPointByBits(745, nPos, 1)
            if nState ~= 1 then
                nChance = nChance + 1
            end
        end
    end
    return nChance
end

function CoinShopData.GetSchoolCanGetChance()
    -- 4 - 已领取
    local hPlayer = GetClientPlayer()
	if not hPlayer then
		return 0
	end

    local nGot = 0
	for i = 1, 3 do
		local nValue = hPlayer.GetExtPointByBits(745, i, 1)
		if nValue and nValue ~= 0 then
			nGot = nGot + 1
		end
	end

    local nBuffStack = Buffer_GetStackNum(28501)
	if nBuffStack >= 2 then
		nGot = nGot + 1
	end

    return 4 - nGot
end

function CoinShopData.SetClickSchoolActivityState(bState)
    if bState then
        APIHelper.DoToday("SchoolActivity")
    end
    -- CoinShopData.bClickActivity = bState
end

function CoinShopData.GetClickSchoolActivityState()
    return APIHelper.IsDidToday("SchoolActivity")
end

function CoinShopData.IsDrawPoolOnTime(nIndex)
    local tPoolInfo = Table_GetPointsDrawPoolInfo(nIndex)
    if not tPoolInfo then
        return
    end
    local tDrawSettings = GetCoinShopDraw().GetDrawSettings(nIndex)
    local nStartTime = tDrawSettings.nStartTime
    local nEndTime = tDrawSettings.nEndTime
    local nTime = GetGSCurrentTime()
    local bOnTime
    if nStartTime and nEndTime then
        bOnTime = (nStartTime == -1 or nTime >= nStartTime) and (nEndTime == -1 or nTime <= nEndTime)
    end
    return bOnTime
end

function CoinShopData.IsInCoinShopWardrobe()
    local script = UIMgr.GetViewScript(VIEW_ID.PanelExteriorMain)
    if script then
        return script.nCoinShopType == UI_COINSHOP_GENERAL.MY_ROLE
    end
    return false
end


function CoinShopData.GetChestList(nExterior)
    local tbList = {}
    local hExterior     = GetExterior()
    if not hExterior then
        return tbList
    end
    local nCanHideCount = hExterior.GetSubsetCanHideCount(nExterior)
    if nCanHideCount <= 0 then
        return tbList
    end

    if nCanHideCount > 1 then
        local tbInfo = CoinShop_GetExteriorSubsetInfo(nExterior)
        for i = 1, nCanHideCount do
            tbList[i] = UIHelper.GBKToUTF8(tbInfo["szSubSetName" .. i])
        end
    else
        tbList[1] = "全部"
    end

    return tbList
end

function CoinShopData.GetChestSelectList(nExterior)
    local tbList = {}
    local hExterior     = GetExterior()
    if not hExterior then
        return tbList
    end
    local nCanHideCount = hExterior.GetSubsetCanHideCount(nExterior)
    if nCanHideCount <= 0 then
        return tbList
    end

    local tbRepresentID = ExteriorCharacter.GetRoleRes()
    local nHideFlag = tbRepresentID[EQUIPMENT_REPRESENT.CHEST_SUBSET_HIDE_MASK]
    for i = 1, nCanHideCount do
        if not kmath.is_bit1(nHideFlag, i) then
            table.insert(tbList, i)
        end
    end

    return tbList
end

function CoinShopData.GetHairtList(nExterior)
    local tbList = {}
    local hHairShop     = GetHairShop()
    if not hHairShop then
        return tbList
    end
    if not g_pClientPlayer then
        return tbList
    end
    local nRoleType = Player_GetRoleType(g_pClientPlayer)
    local nCanHideCount = hHairShop.GetSubsetCanHideCount(nRoleType, nExterior)
    if nCanHideCount <= 0 then
        return tbList
    end

    if nCanHideCount > 1 then
        local tbInfo = CoinShop_GetHairSubsetInfo(nExterior)
        for i = 1, nCanHideCount do
            tbList[i] = UIHelper.GBKToUTF8(tbInfo["szSubSetName" .. i])
        end
    else
        tbList[1] = "全部"
    end

    return tbList
end

function CoinShopData.GetHairSelectList(nExterior)
    local tbList = {}
    local hHairShop     = GetHairShop()
    if not hHairShop then
        return tbList
    end
    if not g_pClientPlayer then
        return tbList
    end
    local nRoleType = Player_GetRoleType(g_pClientPlayer)
    local nCanHideCount = hHairShop.GetSubsetCanHideCount(nRoleType, nExterior)
    if nCanHideCount <= 0 then
        return tbList
    end

    local tbRepresentID = ExteriorCharacter.GetRoleRes()
    local nHideFlag = tbRepresentID[EQUIPMENT_REPRESENT.HAIR_SUBSET_HIDE_MASK]
    for i = 1, nCanHideCount do
        if not kmath.is_bit1(nHideFlag, i) then
            table.insert(tbList, i)
        end
    end

    return tbList
end

function CoinShopData.GetCanReplace()
    local tRepresentID = ExteriorCharacter.GetRoleRes()
    -- local tReplace = {}
    local tReplace = GetPlayerViewReplace(tRepresentID)
    local bViewReplace = tReplace and not IsTableEmpty(tReplace)
    return bViewReplace
end

function CoinShopData.InitChestSubSet()
    local tbData = ExteriorCharacter.GetSubPreviewData(COINSHOP_BOX_INDEX.CHEST)
    local nExterior = tbData.nExterior
    local tbList = CoinShopData.GetChestList(nExterior)
    FilterDef.CoinShopSubSet[2].tbList = tbList
end

function CoinShopData.IniHairSubSet()
    local tbData = ExteriorCharacter.GetSubPreviewData(COINSHOP_BOX_INDEX.HAIR)
    local nHairID = tbData.nExterior
    local tbList = CoinShopData.GetHairtList(nHairID)
    FilterDef.CoinShopSubSet[3].tbList = tbList
end

function CoinShopData.InitSelect()
    local tbRunTime = {}
    tbRunTime[1] = ExteriorCharacter.GetRepresentReplace() and {1} or {2}

    local tbData = ExteriorCharacter.GetSubPreviewData(COINSHOP_BOX_INDEX.CHEST)
    local nExterior = tbData.nExterior
    tbRunTime[2] = CoinShopData.GetChestSelectList(nExterior)

    tbData = ExteriorCharacter.GetSubPreviewData(COINSHOP_BOX_INDEX.HAIR)
    nExterior = tbData.nExterior
    tbRunTime[3] = CoinShopData.GetHairSelectList(nExterior)

    FilterDef.CoinShopSubSet.SetRunTime(tbRunTime)
end

function CoinShopData.UpdateExteriorHideFlag()
    local tbData = ExteriorCharacter.GetSubPreviewData(COINSHOP_BOX_INDEX.CHEST)
    local nExterior = tbData.nExterior
    self.nExteriorHideFlag = g_pClientPlayer.GetExteriorSubsetHideFlag(nExterior)
end

function CoinShopData.UpdateHairHideFlag()
    local tbData = ExteriorCharacter.GetSubPreviewData(COINSHOP_BOX_INDEX.HAIR)
    local nHairID = tbData.nExterior
    self.nHairHideFlag = g_pClientPlayer.GetHairSubsetHideFlag(nHairID)
end

function CoinShopData.UpdateHaveChest()
    local tbData = ExteriorCharacter.GetSubPreviewData(COINSHOP_BOX_INDEX.CHEST)
    local nExterior = tbData.nExterior
    self.bHaveChest = g_pClientPlayer.IsHaveExterior(nExterior)
    FilterDef.CoinShopSubSet[2].szSubTitle = self.bHaveChest and "" or "（仅预览）"
end

function CoinShopData.UpdateHaveHair()
    local tbData = ExteriorCharacter.GetSubPreviewData(COINSHOP_BOX_INDEX.HAIR)
    local nHairID = tbData.nExterior
    self.bHaveHair = g_pClientPlayer.IsHaveHair(HAIR_STYLE.HAIR, nHairID)
    FilterDef.CoinShopSubSet[3].szSubTitle = self.bHaveHair and "" or "（仅预览）"
end

function CoinShopData.UpdateCanShowALL()
    local hExterior = GetExterior()
    if not hExterior then
        return
    end
    local tbData = ExteriorCharacter.GetSubPreviewData(COINSHOP_BOX_INDEX.CHEST)
    local nExterior = tbData.nExterior
    local nCanHideCount = hExterior.GetSubsetCanHideCount(nExterior)
    FilterDef.CoinShopSubSet[2].bCanSelectAll = nCanHideCount > 1

    local hHairShop = GetHairShop()
    if not hHairShop or not g_pClientPlayer then
        return
    end
    tbData = ExteriorCharacter.GetSubPreviewData(COINSHOP_BOX_INDEX.HAIR)
    nExterior = tbData.nExterior
    local nRoleType = Player_GetRoleType(g_pClientPlayer)
    nCanHideCount = hHairShop.GetSubsetCanHideCount(nRoleType, nExterior)
    FilterDef.CoinShopSubSet[3].bCanSelectAll = nCanHideCount > 1

end

function CoinShopData.InitCoinShopSubSetData()
    CoinShopData.InitChestSubSet()
    CoinShopData.IniHairSubSet()
    CoinShopData.InitSelect()
    CoinShopData.UpdateExteriorHideFlag()
    CoinShopData.UpdateHairHideFlag()
    CoinShopData.UpdateHaveChest()
    CoinShopData.UpdateHaveHair()
    CoinShopData.UpdateCanShowALL()
end


function CoinShopData.IsHairDataChange(nHairHideFlag)
    return self.nHairHideFlag ~= nHairHideFlag
end

function CoinShopData.IsChestDataChange(nExteriorHideFlag)
    return self.nExteriorHideFlag ~= nExteriorHideFlag
end

function CoinShopData.IsHaveChest()
    return self.bHaveChest
end

function CoinShopData.IsHaveHair()
    return self.bHaveHair
end

function CoinShopData.GetSubSetFlag(tbInfo, nCount)
    local nFlag = 0
    if tbInfo then
        for nIndex = 1, nCount do
            if not table.contain_value(tbInfo, nIndex) then
                nFlag = kmath.add_bit(nFlag, nIndex)
            end
        end
    end
    return nFlag
end

function CoinShopData.SaveSubSetFlag(nChestFlag, nHairFlag)
    local bHaveHair = CoinShopData.IsHaveHair()
    local bHaveChest = CoinShopData.IsHaveChest()
    local bCanHideChest, bCanHideHair = ExteriorCharacter.GetCanHideSubsetFlag()
    local nRetCode, nRetCode1 = true, true
    if bCanHideChest and bHaveChest then
        local tbData = ExteriorCharacter.GetSubPreviewData(COINSHOP_BOX_INDEX.CHEST)
        local nChestExterior = tbData.dwID
        nRetCode = g_pClientPlayer.SetExteriorSubsetHideFlag(nChestExterior, nChestFlag)
    end

    if bCanHideHair and bHaveHair then
        local tbData = ExteriorCharacter.GetSubPreviewData(COINSHOP_BOX_INDEX.HAIR)
        local nHairExterior = tbData.nHairID
        nRetCode1 = g_pClientPlayer.SetHairSubsetHideFlag(nHairExterior, nHairFlag)
    end

    if not nRetCode or not nRetCode1 then
        OutputMessage("MSG_SYS", g_tStrings.STR_EXTERIOR_SUBSET_HIDE_F)
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_EXTERIOR_SUBSET_HIDE_F)
    end
end

function CoinShopData.Open(fnOpenLink)
    MovieMgr.PlayCoinShopFadeInVideo()
    UIMgr.Open(VIEW_ID.PanelExteriorMain, fnOpenLink)
end

-- ----------------------------------------------------------------------

Event.Reg(self, "UI_LUA_RESET", function ()
    m_bDataChanged = true
end)

Event.Reg(self, EventType.OnRoleLogin, function()
    CoinShopData.nLastOpenBannerTime = nil
    CoinShopData.bSyncCustomPendantData = false
end)

Event.Reg(self, "CURRENT_PLAYER_FORCE_CHANGED", function ()
    m_bDataChanged = true
end)

Event.Reg(self, "DIS_COUPON_CHANGED", function ()
    local welfare = self.GetWelfare(arg0)
    if welfare then
        Storage.CoinShop.tVisitedWelfare[welfare.dwDisCouponID .. "|" .. welfare.nDisappearTime] = nil
        Storage.CoinShop.Dirty()
    end
    Event.Dispatch("COINSHOP_PUSHINFO_UPDATE")
end)

Event.Reg(self, EventType.OnClientPlayerEnter, function()
    if CoinShopData.bSyncCustomPendantData then
        return
    end
    local tType = GetAllCustomPendantType()
    for k, v in pairs(tType) do
        CoinShopData.CustomPendantPlayerDataToLocal(k)
    end
    CoinShopData.bSyncCustomPendantData = true
end)

Event.Reg(self, "ON_CUSTOM_REPRESENT_DATA_CHANGE", function()
    CoinShopData.CustomPendantPlayerDataToLocal(arg0)
    Event.Dispatch(EventType.OnCoinShopCustomPendantDataChanged)
end)

Event.Reg(self, "ON_APPLY_CUSTOM_REPRESENT_DATA", function()
    local nRepresentIndex = arg0
    local nRepresentID  = arg1
    if nRepresentID ~= CoinShopData.GetPendantRepresentIDByIndex(nRepresentIndex) then
        return
    end

    CoinShopData.CustomPendantSetLocalDataToPlayer(nRepresentIndex, nRepresentID)
end)

Event.Reg(self, "UPDATE_HIDE_FACE_PENDENT", function()
    local bHideFlag = arg0
    if bHideFlag == 1 then
        return
    end
    local nRepresentIndex = EQUIPMENT_REPRESENT.FACE_EXTEND
    local nRepresentID = CoinShopData.GetPendantRepresentIDByIndex(nRepresentIndex)
    if nRepresentID and nRepresentID ~= 0 then
        CoinShopData.CustomPendantSetLocalDataToPlayer(nRepresentIndex, nRepresentID)
    end
end)

Event.Reg(self, "COIN_SHOP_BUY_RESPOND", function()
    CoinShopData.SetIsBuying(false)
end)

Event.Reg(self, "COIN_SHOP_SAVE_RESPOND", function()
    CoinShopData.SetIsBuying(false)
end)

Event.Reg(self, "ON_UPDATE_BUY_ITEM_ORDER_SN", function()
    local newAdd = arg1
    if newAdd then
       CoinShopData.SetIsBuying(false)
    end
end)

Event.Reg(self, EventType.OnAccountLogout, function (nPlayerID)
    m_tHairList = nil
    m_tFaceList = nil
    m_tHairShopMap = nil
end)






