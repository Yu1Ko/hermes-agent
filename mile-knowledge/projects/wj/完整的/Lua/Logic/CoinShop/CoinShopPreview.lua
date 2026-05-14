-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: CoinShopPreview
-- Date: 2023-02-24 10:01:05
-- Desc: 主要放一些界面相关辅助函数，如果是逻辑相关的最好放在CoinShopData
-- ---------------------------------------------------------------------------------

CoinShopPreview = CoinShopPreview or {}
local self = CoinShopPreview
-------------------------------- 消息定义 --------------------------------
CoinShopPreview.Event = {}
CoinShopPreview.Event.XXX = "CoinShopPreview.Msg.XXX"

CoinShopPreview.tRoleBoxIcon = {
    -- [COINSHOP_BOX_INDEX.FACE]
    [COINSHOP_BOX_INDEX.HAIR]               = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_hair.png",

    [COINSHOP_BOX_INDEX.BACK_CLOAK_EXTEND]  = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_Cloak.png",
    [COINSHOP_BOX_INDEX.CHEST]              = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_equip_topwear.png",
    [COINSHOP_BOX_INDEX.HELM]               = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_equip_hat.png",
    [COINSHOP_BOX_INDEX.WAIST]              = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_equip_belt.png",
    [COINSHOP_BOX_INDEX.BANGLE]             = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_equip_wristguard.png",
    [COINSHOP_BOX_INDEX.BOOTS]              = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_equip_shoes.png",

    [COINSHOP_BOX_INDEX.PENDANT_PET]        = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_PetHanging.png",
    [COINSHOP_BOX_INDEX.BAG_EXTEND]         = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_BagHanging.png",
    [COINSHOP_BOX_INDEX.FACE_EXTEND]        = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_Face.png",
    [COINSHOP_BOX_INDEX.GLASSES_EXTEND]     = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_eye.png",
    [COINSHOP_BOX_INDEX.WAIST_EXTEND]       = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_WaistHanging.png",
    [COINSHOP_BOX_INDEX.BACK_EXTEND]        = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_BackHanging.png",
    [COINSHOP_BOX_INDEX.L_SHOULDER_EXTEND]  = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_ShoulderLeft.png",
    [COINSHOP_BOX_INDEX.R_SHOULDER_EXTEND]  = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_ShoulderRight.png",
    [COINSHOP_BOX_INDEX.L_GLOVE_EXTEND]     = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_HandLeft.png",
    [COINSHOP_BOX_INDEX.R_GLOVE_EXTEND]     = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_HandRight.png",
    [COINSHOP_BOX_INDEX.HEAD_EXTEND]        = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_Head.png",
    [COINSHOP_BOX_INDEX.IDLE_ACTION]        = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_pose.png",

    [COINSHOP_BOX_INDEX.WEAPON]             = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_equip_weapon_primary.png",
    [COINSHOP_BOX_INDEX.BIG_SWORD]          = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_equip_weapon_secondary.png",
    [COINSHOP_BOX_INDEX.ITEM]               = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_item.png",
    [COINSHOP_BOX_INDEX.EFFECT_SFX]         = {
        [1] = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_equip_SEffectFoot.png",
        [2] = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_equip_SEffectRound.png",
        [3] = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_equip_SEffectRHand.png",
        [4] = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_equip_SEffectLHand.png",
    }
}

CoinShopPreview.szFurnitureBoxIcon = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_home.png"
CoinShopPreview.szPetBoxIcon = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_pet.png"

CoinShopPreview.tRideBoxIcon = {
    [COINSHOP_RIDE_BOX_INDEX.HORSE]                 = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_horse.png",
    [COINSHOP_RIDE_BOX_INDEX.HEAD_HORSE_EQUIP]      = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_Horse_Head.png",
    [COINSHOP_RIDE_BOX_INDEX.CHEST_HORSE_EQUIP]     = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_Horse_Back.png",
    [COINSHOP_RIDE_BOX_INDEX.FOOT_HORSE_EQUIP]      = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_Horse_Foot.png",
    [COINSHOP_RIDE_BOX_INDEX.HANG_ITEM_HORSE_EQUIP] = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_Horse_.png",
    --[COINSHOP_RIDE_BOX_INDEX.ITEM]
}

function CoinShopPreview.Init()

end

function CoinShopPreview.UnInit()

end

function CoinShopPreview.OnLogin()

end

function CoinShopPreview.OnFirstLoadEnd()

end

function CoinShopPreview.GetBuySaveListExceptBody(bNewFace, bNewBody)
    local tbList = CoinShopPreview.GetBuySaveList(bNewFace, bNewBody)
    local i = #tbList
    while tbList[i] do
        local tItem = tbList[i]
        if tItem.bBody then
            table.remove(tbList, i)
        end
        i = i - 1
    end

    return tbList
end

function CoinShopPreview.GetBuySaveList(bNewFace, bNewBody)
    local tChangeList = self.GetRoleChangeList(bNewFace, bNewBody)
    local fnIsOverdue = function (tInfo)
        if not tInfo.bHave and tInfo.eGoodsType == COIN_SHOP_GOODS_TYPE.ITEM and tInfo.dwGoodsID > 0 then
            local tLine = Table_GetRewardsItem(tInfo.dwGoodsID)
            local bShow = CoinShop_RewardsShow(tLine.dwLogicID, tLine.nClass)
            if not bShow and tLine.bOverdueShow then
                return true
            end
        end
        return false
    end
    -- -- 不能买的不要加进购物车了
    -- local fnCanBuy = function (tInfo)
    --     if not tInfo.bHave and tInfo.eGoodsType == COIN_SHOP_GOODS_TYPE.ITEM and tInfo.dwGoodsID > 0 then
    --         return CoinShop_RewardsCanBuy(tInfo.dwGoodsID)
    --     end
    --     return true
    -- end

    local tList = {}
    for _, tItem in ipairs(tChangeList) do
        if not fnIsOverdue(tItem) then
            table.insert(tList, tItem)
        end
    end
    return tList
end

function CoinShopPreview.GetRoleChangeList(bNewFace, bNewBody)
    local fnInsert = function (tTarget, tSonList)
        for _, tSon in ipairs(tSonList) do
            if tSon.bLimitItem then
                table.insert(tTarget, 1, tSon)
            else
                table.insert(tTarget, tSon)
            end
        end
    end

    local tChangeList = {}
    if ExteriorCharacter.IsNewFace() then
        local tFaceList = self.GetChangeNewFace(bNewFace)
        fnInsert(tChangeList, tFaceList)
    else
        local tHairList = self.GetChangeFaceLift(bNewFace)
        fnInsert(tChangeList, tHairList)
    end
    local tHairList = self.GetChangeHair()
    fnInsert(tChangeList, tHairList)
    local tExteriorList = self.GetChangeExterior()
    fnInsert(tChangeList, tExteriorList)
    local tWeaponList = self.GetChangeWeapon()
    fnInsert(tChangeList, tWeaponList)
    local tPendantList = self.GetChangePendant()
    fnInsert(tChangeList, tPendantList)
    local tPendantPet = self.GetChangePendantPet()
    fnInsert(tChangeList, tPendantPet)
    local tItemList = self.GetChangeRoleItem()
    fnInsert(tChangeList, tItemList)
    local tBodyList = self.GetChangeBody(bNewBody)
    fnInsert(tChangeList, tBodyList)
    local tActionList = self.GetChangeAction()
    fnInsert(tChangeList, tActionList)
    -- local tEffectList = self.GetChangeEffect()
    -- fnInsert(tChangeList, tEffectList)
    return tChangeList
end

function CoinShopPreview.GetChangeHair()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local tCRepresentID = hPlayer.GetRepresentID()

    local tHair = ExteriorCharacter.GetPreviewHair()
    if not tHair then
        return {}
    end
    local nHairID = tHair.nHairID

    local nCurrentHairID = tCRepresentID[EQUIPMENT_REPRESENT.HAIR_STYLE]
    local bCurrentUse = hPlayer.bEquipLiftedFace

    local tHairItem = {}
    local tLimitItem = tHair.tItem
    local nIndex = hPlayer.GetEquippedHairCustomDyeingIndex(nCurrentHairID)
    local _, nHairDyeingIndex = ExteriorCharacter.GetHairDyeingIndex()
    if tLimitItem then
        local tItem = {}
        tItem.bHave = false
        CoinShop_GetRewardItemInfo(tItem, tLimitItem)
        table.insert(tHairItem, tItem)
    elseif (nHairID ~= nCurrentHairID and not tHair.bMultiPreview) or (nIndex ~= nHairDyeingIndex) then
        local tItem = {}
        tItem.dwGoodsID = nHairID
        tItem.nState = ACCOUNT_ITEM_STATUS.NORMAL
        tItem.eGoodsType = COIN_SHOP_GOODS_TYPE.HAIR
        tItem.tPriceInfo = HairShop_GetPriceInfo(HAIR_STYLE.HAIR, nHairID, COIN_SHOP_GOODS_TYPE.HAIR)
        tItem.szTime = HairShop_GetTime(HAIR_STYLE.HAIR, nHairID)
        local nOwnType = GetCoinShopClient().CheckAlreadyHave(tItem.eGoodsType, tItem.dwGoodsID)
        tItem.bHave = nOwnType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE
        tItem.nHairDyeingIndex = nHairDyeingIndex
        table.insert(tHairItem, tItem)
    end

    return tHairItem
end

function CoinShopPreview.GetChangeFaceLift(bNewFace)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local hManager = GetFaceLiftManager()
    if not hManager then
        return
    end

    local  hCoinShopClient = GetCoinShopClient()
    if not hCoinShopClient then
        return
    end

    if ExteriorCharacter.IsNewFace() then
        return {}
    end

    local tCRepresentID = hPlayer.GetRepresentID()
    local tFace = ExteriorCharacter.GetPreviewFace()
    if not tFace then
        return {}
    end
    local nFaceID = tFace.nFaceID
    local bUseLiftedFace = tFace.bUseLiftedFace

    local nCurrentFaceID = tCRepresentID[EQUIPMENT_REPRESENT.FACE_STYLE]
    local bCurrentUse = hPlayer.bEquipLiftedFace
    local tFaceItem = {}
    if bUseLiftedFace then
        local UserData = tFace.UserData
        local nNowIndex = UserData.nIndex
        local nCurrentIndex = hManager.GetEquipedIndex()
        UserData.tFaceData.tDecoration = nil
        local bHave, nIndex = hManager.IsAlreadyHave(UserData.tFaceData)
        if not bHave or nIndex ~= nCurrentIndex then
            local tItem = {}
            tItem.bLiftedFace = true
            if bNewFace then
                tItem.nIndex = nil
            else
                tItem.nIndex = nNowIndex
            end
            tItem.nState = ACCOUNT_ITEM_STATUS.NORMAL
            tItem.eGoodsType = COIN_SHOP_GOODS_TYPE.FACE
            local tPrice
            if bNewFace or (not nNowIndex) then
                tPrice = hManager.GetFacePrice(UserData.tFaceData)
            else
                tPrice = hManager.GetFacePrice(UserData.tFaceData, nNowIndex)
            end

            tItem.bHave = bHave
            local nTotalPrice = tPrice and tPrice.nTotalPrice or 0
            if bHave then
                nTotalPrice = 0
            end
            tItem.tPriceInfo = CoinShop_GetFaceLiftPriceInfo(nTotalPrice)
            tItem.tFaceData = UserData.tFaceData
            table.insert(tFaceItem, tItem)
        end
    else
        if nFaceID and (bCurrentUse or nFaceID ~= nCurrentFaceID) then
            local tItem = {}
            tItem.dwGoodsID = nFaceID
            tItem.nState = ACCOUNT_ITEM_STATUS.NORMAL
            tItem.eGoodsType = COIN_SHOP_GOODS_TYPE.FACE
            tItem.tPriceInfo = HairShop_GetPriceInfo(HAIR_STYLE.FACE, nFaceID, COIN_SHOP_GOODS_TYPE.FACE)
            tItem.szTime = HairShop_GetTime(HAIR_STYLE.FACE, nFaceID)
            local nOwnType = GetCoinShopClient().CheckAlreadyHave(tItem.eGoodsType, tItem.dwGoodsID)
            tItem.bHave = nOwnType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE
            table.insert(tFaceItem, tItem)
        end
    end
    return tFaceItem
end

function CoinShopPreview.GetChangeBody(bNewBody)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local hManager = GetBodyReshapingManager()
    if not hManager then
        return
    end

    local tBodyItem = {}
    local tData, nBody = ExteriorCharacter.GetPreviewBody()
    if not tData then
        return tBodyItem
    end
    local bHave, nIndex = hManager.IsAlreadyHave(tData)
    if bHave then
        local nEquippedIndex = hPlayer.GetEquippedBodyBoneIndex()
        if nEquippedIndex ~= nIndex then
            local tItem = {}
            tItem.bBody = true
            tItem.nIndex = nIndex
            tItem.bHave = bHave
            table.insert(tBodyItem, tItem)
        end
    else
        local tItem = {}
        tItem.bBody = true
        tItem.bHave = bHave
        if bNewBody then
            tItem.nIndex = nil
        else
            tItem.nIndex = nBody
        end
        tItem.tBody = tData
        table.insert(tBodyItem, tItem)
    end
    return tBodyItem
end

function CoinShopPreview.GetChangeAction()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local tActionItem = {}
    local nLogicAniID, bMultiPreview = ExteriorCharacter.GetPreviewAniID()
    if not nLogicAniID then
        return tActionItem
    end
    local bHave = nLogicAniID == 0 or hPlayer.IsHaveIdleAction(nLogicAniID)
    if bHave and CoinShopData.IsInCoinShopWardrobe() then
        local nNowAniID = hPlayer.GetDisplayIdleAction(PLAYER_IDLE_ACTION_DISPLAY_TYPE.COIN_SHOP)
        if nNowAniID ~= nLogicAniID then
            local tItem = {}
            tItem.dwGoodsID = nLogicAniID
            tItem.eGoodsType = COIN_SHOP_GOODS_TYPE.IDLE_ACTION
            tItem.bHave = true
            table.insert(tActionItem, tItem)
        end
    elseif bMultiPreview then
    else
    end
    return tActionItem
end

local function InsertEffectSfx(tItemList, hPlayer, nNowEffectID, nType)
    local tItem         = {}
    local bHave         = hPlayer.IsSFXAcquired(nNowEffectID)
    tItem.bHave         = bHave
    tItem.bEffectSfx    = true
    tItem.nEffectID     = nNowEffectID
    tItem.nType         = nType
    table.insert(tItemList, tItem)
end

function CoinShopPreview.GetChangeEffect()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local tItemList = {}
    for nType = 0, PLAYER_SFX_REPRESENT.COUNT - 1 do
        local nCurrentEquipID       = hPlayer.GetEquipSFXID(nType)
        local tPreviewSfxInfo       = ExteriorCharacter.GetPreviewEffect(nType)
        if tPreviewSfxInfo then
            local tRItem            = tPreviewSfxInfo.tItem
            local nNowEffectID      = tPreviewSfxInfo.nEffectID
            local bChange           = nCurrentEquipID ~= nNowEffectID
            if tRItem then
                local tItem         = {}
                local dwLogicID     = tRItem.dwLogicID
                tItem.bHave         = false
                CoinShop_GetRewardItemInfo(tItem, tRItem)
                table.insert(tItemList, tItem)
            elseif bChange then
                InsertEffectSfx(tItemList, hPlayer, nNowEffectID, nType)
            end
        elseif nCurrentEquipID ~= 0 then
            InsertEffectSfx(tItemList, hPlayer, nCurrentEquipID, nType)
        end
    end

    return tItemList
end

function CoinShopPreview.GetChangeNewFace(bNewFace)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local hManager = GetFaceLiftManager()
    if not hManager then
        return
    end
    local tFaceItem = {}
    local tData, nFaceIndex = ExteriorCharacter.GetPreviewNewFace()
    if not tData or IsTableEmpty(tData) then
        return tFaceItem
    end
    local bHave, nIndex = hManager.IsAlreadyHave(tData)
    if bHave then
        local nEquippedIndex = hManager.GetEquipedIndex()
        if nEquippedIndex ~= nIndex then
            local tItem = {}
            tItem.bNewFace = true
            tItem.nIndex = nIndex
            tItem.bHave = bHave
            table.insert(tFaceItem, tItem)
        end
    else
        local tItem = {}
        tItem.bNewFace = true
        tItem.bHave = bHave
        if bNewFace then
            tItem.nIndex = nil
        else
            tItem.nIndex = nFaceIndex
        end
        tItem.tFaceData = tData
        local tPrice
        if bNewFace then
            tPrice = hManager.GetFacePrice(tData)
        elseif nFaceIndex then
            tPrice = hManager.GetFacePrice(tData, nFaceIndex)
        end
        if tPrice then
            tItem.tPriceInfo = CoinShop_GetNewFacePriceInfo(tPrice.nTotalPrice)
            tItem.nPrice = tPrice.nTotalPrice
        end
        table.insert(tFaceItem, tItem)
    end
    return tFaceItem
end

function CoinShopPreview.GetChangeExterior()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local hCoinShopClient = GetCoinShopClient()
    if not hCoinShopClient then
        return
    end

    local nCurrentSetID = hPlayer.GetCurrentSetID()
    local tExteriorSet = hPlayer.GetExteriorSet(nCurrentSetID)

    local tRoleData = ExteriorCharacter.GetRoleData()
    local tExteriorList = {}
    for i = 1, EXTERIOR_SUB_NUMBER do
        local tData = tRoleData[i]
        local dwExteriorID = tData and tData.dwID
        local tLimitItem = tData and tData.tItem

        local nExteriorSub  = Exterior_BoxIndexToExteriorSub(i)
        local dwCurrentExteriorID = tExteriorSet[nExteriorSub]
        if tLimitItem then
            local tItem = {}
            tItem.bHave = false
            CoinShop_GetRewardItemInfo(tItem, tLimitItem)
            table.insert(tExteriorList, tItem)
        elseif dwExteriorID and dwExteriorID ~= dwCurrentExteriorID then
            local tItem = {}
            tItem.dwGoodsID = dwExteriorID
            tItem.eGoodsType = COIN_SHOP_GOODS_TYPE.EXTERIOR
            tItem.bHave = true

            if tItem.dwGoodsID and tItem.dwGoodsID > 0 then
                local nOwnType = GetCoinShopClient().CheckAlreadyHave(tItem.eGoodsType, tItem.dwGoodsID)
                tItem.bHave = nOwnType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE
            end

            local nTimeType, nTime = hPlayer.GetExteriorTimeLimitInfo(dwExteriorID)
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
            table.insert(tExteriorList, tItem)
        end
    end
    return tExteriorList
end

function CoinShopPreview.GetChangeWeapon()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local hCoinShopClient = GetCoinShopClient()
    if not hCoinShopClient then
        return
    end

    local nCurrentSetID = hPlayer.GetCurrentSetID()
    local tWeaponExterior = hPlayer.GetWeaponExteriorSet(nCurrentSetID)
    local tWeaponBox = CoinShop_GetWeaponIndexArray()
    local tRoleData = ExteriorCharacter.GetRoleData()
    --local tRepresentID = CoinShopView.GetRoleRes()
    local tWeaponList = {}
    for i, nWeaponSub in pairs(tWeaponBox) do
        local tData = tRoleData[i]
        local dwWeaponID = tData and tData.dwID
        local dwCurrent = tWeaponExterior[nWeaponSub]
        if dwWeaponID and dwWeaponID ~= dwCurrent then
            local tItem = {}
            tItem.dwGoodsID = dwWeaponID
            tItem.eGoodsType = COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR
            tItem.nEquipPos = nWeaponSub
            tItem.bHave = dwWeaponID == 0

            if dwWeaponID > 0 then
                local nHaveType = hCoinShopClient.CheckAlreadyHave(COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR, dwWeaponID)
                local bHave = nHaveType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE
                local tInfo = CoinShop_GetWeaponExteriorInfo(dwWeaponID)
                tItem.bHave = bHave
                tItem.tPriceInfo = CoinShop_GetWeaponPriceInfo(dwWeaponID)
                tItem.szTime = CoinShop_GetWeaponTime(dwWeaponID)
                tItem.bForbiddPeerPay = tInfo.bForbiddPeerPay
                tItem.bForbidDisCoupon = tInfo.bForbidDisCoupon
            end
            table.insert(tWeaponList, tItem)
        end
    end
    return tWeaponList
end

function CoinShopPreview.IsPendantChange(tRItem, nPendantType)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return false
    end
    local dwCurrentIndex = hPlayer.GetSelectPendent(nPendantType)
    if tRItem and dwCurrentIndex ~= tRItem.dwIndex then
        return true
    end

    if tRItem.dwIndex == 0 and dwCurrentIndex == 0 then
        return false
    end
    local hItemInfo = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, dwCurrentIndex)
    if not hItemInfo then
        return false
    end

    if hItemInfo.nSub ~= EQUIPMENT_SUB.BACK_CLOAK_EXTEND then
        return false
    end

    if not tRItem.tColorID then
        return true
    end
    local tColorID = GetPendantColor(ITEM_TABLE_TYPE.CUST_TRINKET, dwCurrentIndex)

    for i, nColor in ipairs(tRItem.tColorID) do
        if nColor ~= tColorID[i] then
            return true
        end
    end

    return false
end

function CoinShopPreview.GetChangePendant()
    local hRewardsShop = GetRewardsShop()
    if not hRewardsShop then
        return
    end

    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local hCoinShopClient = GetCoinShopClient()
    if not hCoinShopClient then
        return
    end

    local tItemList = {}
    local tRoleData = ExteriorCharacter.GetRoleData()
    for nPendantPos = 0, PENDENT_SELECTED_POS.TOTAL - 1 do
        local nIndex = CoinShop_PendantTypeToBoxIndex(nPendantPos)
        if nIndex then
            local tData = tRoleData[nIndex]
            if tData then
                local tRItem = tData.tItem
                if tRItem then
                    local bChange = self.IsPendantChange(tRItem, nPendantPos)
                    if bChange then
                        local tItem = {}
                        local dwLogicID = tRItem.dwLogicID
                        tItem.dwGoodsID = dwLogicID or 0
                        tItem.nState = ACCOUNT_ITEM_STATUS.NORMAL
                        tItem.eGoodsType = COIN_SHOP_GOODS_TYPE.ITEM
                        local bHave = false
                        if tRItem.bLimitItem then
                            bHave = false
                        else
                            bHave = true
                            if dwLogicID and dwLogicID > 0 then
                                local nHaveType = hCoinShopClient.CheckAlreadyHave(COIN_SHOP_GOODS_TYPE.ITEM, dwLogicID)
                                bHave = nHaveType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE
                            elseif tRItem.tColorID then
                                bHave = hPlayer.IsColorPendentExist(tRItem.dwIndex, tRItem.tColorID[1], tRItem.tColorID[2], tRItem.tColorID[3])
                            elseif tRItem and tRItem.dwIndex > 0 then
                                bHave = hPlayer.IsPendentExist(tRItem.dwIndex)
                            end
                        end
                        if bHave and IsPendantHeadType(nPendantPos) then
                            tItem.nSelectedPos = nPendantPos
                        end
                        tItem.bHave = bHave
                        tItem.tColorID = tRItem.tColorID
                        CoinShop_GetRewardItemInfo(tItem, tRItem)
                        if not tRItem.bLimitItem then
                            tItem.nSubType = CoinShop_PendantPosToSub(nPendantPos)
                        end

                        table.insert(tItemList, tItem)
                    end
                end
            end
        end
    end
    return tItemList
end

function CoinShopPreview.GetChangePendantPet()
    local hRewardsShop = GetRewardsShop()
    if not hRewardsShop then
        return
    end

    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local hCoinShopClient = GetCoinShopClient()
    if not hCoinShopClient then
        return
    end

    local dwCrrent, nCurrentPos = hPlayer.GetEquippedPendentPet()
    local tItemList = {}
    local tRItem = ExteriorCharacter.GetPreviewPendantPet()
    if not tRItem then
        return tItemList
    end

    local dwItemIndex = tRItem.dwIndex
    local nPos = tRItem.nPos or 0
    local bChange = dwCrrent ~= dwItemIndex or nCurrentPos ~= nPos
    if bChange then
        local tItem = {}
        local dwLogicID = tRItem.dwLogicID
        local bHave = false
        if tRItem.bLimitItem then
            bHave = false
        else
            bHave = true
            if dwLogicID and dwLogicID > 0 then
                local nHaveType = hCoinShopClient.CheckAlreadyHave(COIN_SHOP_GOODS_TYPE.ITEM, dwLogicID)
                bHave = nHaveType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE
            elseif dwItemIndex > 0 then
                bHave =  hPlayer.IsHavePendentPet(dwItemIndex)
            end
        end
        tItem.bHave = bHave
        tItem.nPos = tRItem.nPos
        tItem.bPendantPet = true
        CoinShop_GetRewardItemInfo(tItem, tRItem)
        if not tRItem.bLimitItem then
            tItem.nSubType = Exterior_BoxIndexToSub(COINSHOP_BOX_INDEX.PENDANT_PET)
        end

        table.insert(tItemList, tItem)
    end
    return tItemList
end

function CoinShopPreview.GetChangeRoleItem()
    local hRewardsShop = GetRewardsShop()
    if not hRewardsShop then
        return
    end
    local hCoinShopClient = GetCoinShopClient()
    if not hCoinShopClient then
        return
    end

    local tRoleData = ExteriorCharacter.GetRoleData()
    local tItemList = {}
    local nIndex = COINSHOP_BOX_INDEX.ITEM
    local tData = tRoleData[nIndex]
    local tRItem = tData and tData.tItem
    if tRItem and tRItem.dwLogicID and tRItem.dwLogicID > 0 then
        local tItem = {}
        local dwLogicID = tRItem.dwLogicID
        local nHaveType = hCoinShopClient.CheckAlreadyHave(COIN_SHOP_GOODS_TYPE.ITEM, dwLogicID)
        local bHave = nHaveType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE
        if not bHave then
            tItem.bHave = false
            CoinShop_GetRewardItemInfo(tItem, tRItem)
            table.insert(tItemList, tItem)
        end
    end

    return tItemList
end

function CoinShopPreview.GetChangeRideItem()
    local hRewardsShop = GetRewardsShop()
    if not hRewardsShop then
        return
    end
    local hCoinShopClient = GetCoinShopClient()
    if not hCoinShopClient then
        return
    end

    local tItemList = {}
    local tRideData = ExteriorCharacter.GetRideData()
    local tRideIndex = CoinShop_GetRideIndexArray()
    local bAllHave = true

    for nIndex = 1, RIDE_BOX_COUNT do
        local tData = tRideData[nIndex]
        local tRItem = tData.tItem
        if tRItem then
            local dwLogicID = tRItem.dwLogicID
            local tItem = {}
            local bHave = true
            if dwLogicID and dwLogicID > 0 then
                local nHaveType = hCoinShopClient.CheckAlreadyHave(COIN_SHOP_GOODS_TYPE.ITEM, dwLogicID)
                bHave = nHaveType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE
            end

            if not bHave then
                tItem.bHave = false
                CoinShop_GetRewardItemInfo(tItem, tRItem)
                table.insert(tItemList, tItem)
            end
        end
    end
    return tItemList
end

function CoinShopPreview.GetChangePetItem()
    local hRewardsShop = GetRewardsShop()
    if not hRewardsShop then
        return
    end
    local hCoinShopClient = GetCoinShopClient()
    if not hCoinShopClient then
        return
    end
    local tItemList = {}
    local tData = ExteriorCharacter.GetPetData()
    local tRItem = tData.tItem
    if tRItem and tRItem.dwLogicID and tRItem.dwLogicID > 0 then
        local tItem = {}
        local dwLogicID = tRItem.dwLogicID
        local nHaveType = hCoinShopClient.CheckAlreadyHave(COIN_SHOP_GOODS_TYPE.ITEM, dwLogicID)
        local bHave = nHaveType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE
        if not bHave then
            tItem.bHave = false
            CoinShop_GetRewardItemInfo(tItem, tRItem)
            table.insert(tItemList, tItem)
        end
    end
    return tItemList
end

function CoinShopPreview.GetChangeFurnitureItem()
    local hRewardsShop = GetRewardsShop()
    if not hRewardsShop then
        return
    end
    local hCoinShopClient = GetCoinShopClient()
    if not hCoinShopClient then
        return
    end
    local tItemList = {}
    local tData = ExteriorCharacter.GetFurnitureData()
    local tRItem = tData.tItem
    if tRItem and tRItem.dwLogicID and tRItem.dwLogicID > 0 then
        local tItem = {}
        local dwLogicID = tRItem.dwLogicID
        local nHaveType = hCoinShopClient.CheckAlreadyHave(COIN_SHOP_GOODS_TYPE.ITEM, dwLogicID)
        local bHave = nHaveType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE
        if not bHave then
            tItem.bHave = false
            CoinShop_GetRewardItemInfo(tItem, tRItem)
            table.insert(tItemList, tItem)
        end
    end
    return tItemList
end

function CoinShopPreview.CanSaveOutfit()
    -- if not self.IsFaceHave() then
    --     return false
    -- end
    if not self.IsHairHave() then
        return false
    end
    if not self.IsExteriorHave() then
        return false
    end
    if not self.IsPendantHave() then
        return false
    end

    if not self.IsPendantPetHave() then
        return false
    end

    if not self.IsWeaponHave() then
        return false
    end

    return true
end

function CoinShopPreview.IsFaceHave()
    local tFace = ExteriorCharacter.GetPreviewFace()
    local nFaceID = tFace.nFaceID
    local bUseLiftedFace = tFace.bUseLiftedFace
    if bUseLiftedFace then
        local UserData = tFace.UserData
        if UserData.nIndex then
            local bHave, nRetIndex = GetFaceLiftManager().IsAlreadyHave(UserData.tFaceData)
            if bHave and nRetIndex == UserData.nIndex then
                return true
            end
        end
    else
        local nOwnType = GetCoinShopClient().CheckAlreadyHave(COIN_SHOP_GOODS_TYPE.FACE, nFaceID)
        return nOwnType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE
    end

    return false
end

function CoinShopPreview.IsHairHave()
    local tHair = ExteriorCharacter.GetPreviewHair()
    if not tHair then
        return false
    end

    local nHairID = tHair.nHairID
    local nOwnType = GetCoinShopClient().CheckAlreadyHave(COIN_SHOP_GOODS_TYPE.HAIR, nHairID)
    return nOwnType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE
end

function CoinShopPreview.IsExteriorHave()
    local tRoleData = ExteriorCharacter.GetRoleData()
    local tExteriorList = {}
    for i = 1, EXTERIOR_SUB_NUMBER do
        local tData = tRoleData[i]

        if tData and tData.tItem then
            return false
        end

        local dwGoodsID = tData and tData.dwID
        local eGoodsType = COIN_SHOP_GOODS_TYPE.EXTERIOR

        if dwGoodsID > 0 then
            local nOwnType = GetCoinShopClient().CheckAlreadyHave(eGoodsType, dwGoodsID)
            local bHave = nOwnType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE
            if not bHave then
                return false
            end
        end
    end
    return true
end

function CoinShopPreview.IsThePendantHave(tRItem)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    if tRItem.bLimitItem then
        return false
    end

    local bHave = true
    local dwLogicID = tRItem.dwLogicID
    if tRItem.dwIndex > 0 then
        if tRItem.tColorID then
            local tColorID = tRItem.tColorID
            bHave = hPlayer.IsColorPendentExist(tRItem.dwIndex, tColorID[1], tColorID[2], tColorID[3])
        else
            bHave = hPlayer.IsPendentExist(tRItem.dwIndex)
        end
    elseif dwLogicID and dwLogicID > 0 then
        local nHaveType = GetCoinShopClient().CheckAlreadyHave(COIN_SHOP_GOODS_TYPE.ITEM, dwLogicID)
        bHave = nHaveType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE
    end

    return bHave
end

function CoinShopPreview.IsPendantHave()

    local tItemList = {}
    local tSaveList = {}
    local tRoleData = ExteriorCharacter.GetRoleData()
    for i = 0, PENDENT_SELECTED_POS.TOTAL - 1 do
        local nIndex = CoinShop_PendantTypeToBoxIndex(i)
        if nIndex then
            local tData = tRoleData[nIndex]
            if tData then
                local tRItem = tData.tItem
                local bHave = self.IsThePendantHave(tRItem)
                if not bHave then
                    return false
                end
            end
        end
    end
    return true
end

function CoinShopPreview.IsPendantPetHave()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local dwCrrent, nCurrentPos = hPlayer.GetEquippedPendentPet()
    local tRItem = ExteriorCharacter.GetPreviewPendantPet()
    local dwItemIndex = tRItem.dwIndex
    local dwLogicID = tRItem.dwLogicID
    if tRItem.bLimitItem then
       return false
    end
    local bHave = true
    if dwLogicID and dwLogicID > 0 then
        local nHaveType = GetCoinShopClient().CheckAlreadyHave(COIN_SHOP_GOODS_TYPE.ITEM, dwLogicID)
        bHave = nHaveType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE
    elseif dwItemIndex > 0 then
        bHave =  hPlayer.IsHavePendentPet(dwItemIndex)
    end

    return bHave
end

function CoinShopPreview.IsWeaponHave()
    local tWeaponBox = CoinShop_GetWeaponIndexArray()
    local tRoleData = ExteriorCharacter.GetRoleData()
    local tWeaponList = {}
    for i, nWeaponSub in pairs(tWeaponBox) do
        local tData = tRoleData[i]
        local dwWeaponID = tData and tData.dwID
        if dwWeaponID and dwWeaponID > 0 then
            local nHaveType = GetCoinShopClient().CheckAlreadyHave(COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR, dwWeaponID)
            local bHave = nHaveType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE
            if not bHave then
                return false
            end
        end
    end

    return true
end

function CoinShopPreview.BuySubExterior(dwExteriorID)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local hExterior = GetExterior()
    if not hExterior then
        return
    end

    local hCoinShopClient = GetCoinShopClient()
    if not hCoinShopClient then
        return
    end

    local tItem = {}
    tItem.dwGoodsID = dwExteriorID
    tItem.eGoodsType = COIN_SHOP_GOODS_TYPE.EXTERIOR
    local nTimeType, nTime = hPlayer.GetExteriorTimeLimitInfo(dwExteriorID)
    if nTimeType == COIN_SHOP_TIME_LIMIT_TYPE.SEVEN_DAYS_LIMIT or
        nTimeType == COIN_SHOP_TIME_LIMIT_TYPE.FREE_TRY_ON
    then
        tItem.eGoodsType = COIN_SHOP_GOODS_TYPE.RENEW
        tItem.nRenewTime = nTime
    end

    if dwExteriorID > 0 then
        tItem.tPriceInfo = CoinShop_GetExteriorPriceInfo(dwExteriorID)
        tItem.szTime = CoinShop_GetExteriorTime(dwExteriorID)
    end
    local tInfo = hExterior.GetExteriorInfo(dwExteriorID)
    tItem.nSubType = tInfo.nSubType
    local tList = {}
    table.insert(tList, tItem)
    UIMgr.Open(VIEW_ID.PanelSettleAccounts, tList, false)
end

function CoinShopPreview.RecordPreviewPakResource(nRoleType, tRepresentID)
    local tEquipList, tEquipSfxList = PakEquipResData.GetRepresentPakResource(nRoleType, tRepresentID.nHatStyle, tRepresentID)
    local tMyEquipList, tMyEquipSfxList = PakEquipResData.FilterMyPakResource(tEquipList, tEquipSfxList)
    ResCleanData.RecordLoadEquipRes(nRoleType, tMyEquipList, tMyEquipList, tMyEquipSfxList)
end

function CoinShopPreview.LocatePreviewItem(scrollView, node)
    local layout = scrollView:getInnerContainer()
    local nPosX, nPosY = UIHelper.GetWorldPosition(node)
    local nSizeX, nSizeY = UIHelper.GetContentSize(node)
    local nAnchX, nAnchY = UIHelper.GetAnchorPoint(node)
    local nXMin = nPosX - nSizeX * nAnchX
    local nXMax = nPosX + nSizeX * (1 - nAnchX)
    local nYMin = nPosY - nSizeY * nAnchY
    local nYMax = nPosY + nSizeY * (1 - nAnchY)

    local nCenterX = (nXMin+nXMax)/2
    local nCenterY = (nYMin+nYMax)/2
    local nSpaceX, nSpaceY = UIHelper.ConvertToNodeSpace(layout, nCenterX, nCenterY)

    local _, nLayoutHeight = UIHelper.GetContentSize(layout)
    local _, nScreenHeight = UIHelper.GetContentSize(scrollView)
    local nPos = (nLayoutHeight - nSpaceY) - nScreenHeight/2
    local nLen = nLayoutHeight - nScreenHeight
    if nLen <= 0 then
        nLen = 1
    end
    local nPercent = nPos * 100 / nLen
    if nPercent <= 0 then
        nPercent = 0
    end
    if nPercent >= 100 then
        nPercent = 100
    end
    UIHelper.ScrollToPercent(scrollView,  nPercent, 0)
end

function CoinShopPreview.InitItemIcon(iconScript, tbGoods, tipsScript, fnClickCallback)
    if tbGoods.eGoodsType == COIN_SHOP_GOODS_TYPE.EXTERIOR or tbGoods.eGoodsType == COIN_SHOP_GOODS_TYPE.RENEW then
        iconScript:OnInitWithTabID("EquipExterior", tbGoods.dwGoodsID)
        iconScript:SetClickCallback(function(nParam1, nParam2)
            local bSelected = nParam1 and nParam2
            if bSelected then
                self.InitItemTips(tbGoods, tipsScript, iconScript._rootNode)
            end
            if fnClickCallback then
                fnClickCallback(bSelected)
            end
        end)
    elseif tbGoods.eGoodsType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
        iconScript:OnInitWithTabID("WeaponExterior", tbGoods.dwGoodsID)
        iconScript:SetClickCallback(function(nParam1, nParam2)
            local bSelected = nParam1 and nParam2
            if bSelected then
                self.InitItemTips(tbGoods, tipsScript, iconScript._rootNode)
            end
            if fnClickCallback then
                fnClickCallback(bSelected)
            end
        end)
    elseif tbGoods.eGoodsType == COIN_SHOP_GOODS_TYPE.ITEM then
        iconScript:OnInitWithTabID(tbGoods.dwTabType, tbGoods.dwTabIndex)
        iconScript:SetClickCallback(function(nParam1, nParam2)
            local bSelected = nParam1 and nParam2
            if bSelected then
                self.InitItemTips(tbGoods, tipsScript, iconScript._rootNode)
            end
            if fnClickCallback then
                fnClickCallback(bSelected)
            end
        end)
    elseif tbGoods.eGoodsType == COIN_SHOP_GOODS_TYPE.HAIR then
        iconScript:OnInitWithIconID(10775, 2, 1)
        iconScript:SetSelectChangeCallback(function(_, bSelected)
            if bSelected then
                self.InitItemTips(tbGoods, tipsScript, iconScript._rootNode)
            end
            if fnClickCallback then
                fnClickCallback(bSelected)
            end
        end)
    elseif tbGoods.eGoodsType == COIN_SHOP_GOODS_TYPE.SHOW_CARD_DECORATION then
        iconScript:OnInitWithIconID(nil, 5, 1)
        UIHelper.SetVisible(iconScript.Eff_Orange, false)
        iconScript:SetIconByTexture("Resource/icon/home/Furniture/item_sc_bj.png")
        iconScript:SetSelectChangeCallback(function(_, bSelected)
            if bSelected then
                self.InitItemTips(tbGoods, tipsScript, iconScript._rootNode)
            end
            if fnClickCallback then
                fnClickCallback(bSelected)
            end
        end)
    end
end

function CoinShopPreview.InitItemTips(tbGoods, tipsScript, clickNode, tbCleanBtnInfo)
    local hExteriorClient = GetExterior()
    if not hExteriorClient then
        return
    end
    local hCoinShopClient = GetCoinShopClient()
    if not hCoinShopClient then
        return
    end

    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local scriptItemTip

    if tbGoods.eGoodsType == COIN_SHOP_GOODS_TYPE.EXTERIOR or tbGoods.eGoodsType == COIN_SHOP_GOODS_TYPE.RENEW then
        local tExteriorInfo = GetExterior().GetExteriorInfo(tbGoods.dwGoodsID)
        local bIsInShop = tExteriorInfo.bIsInShop
        local bCollect, nGold = CoinShop_GetCollectInfo(COIN_SHOP_GOODS_TYPE.EXTERIOR, tbGoods.dwGoodsID)
        local nTimeType, nTime = hPlayer.GetExteriorTimeLimitInfo(tbGoods.dwGoodsID)
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
        end
        local showTipsScript = tipsScript
        local tips
        if not showTipsScript then
           tips, showTipsScript = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, clickNode)
        end
        local tbBtnInfo = {}
        if not bIsInShop and not bCollect and nGold >= 0 then
            table.insert(tbBtnInfo, {
                szName = "收集",
                OnClick = function ()
                    CoinShopExterior.Collect(tbGoods.dwGoodsID)
                    if tips then
                        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
                    end
                end
            })
        end
        if szHaveTime ~= "" and not UIMgr.IsViewOpened(VIEW_ID.PanelSettleAccounts) then
            table.insert(tbBtnInfo, {
                szName = "续费",
                OnClick = function ()
                    CoinShopPreview.BuySubExterior(tbGoods.dwGoodsID)
                    if tips then
                        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
                    end
                end
            })
        end
        if tbCleanBtnInfo then
            table.insert(tbBtnInfo, tbCleanBtnInfo)
        end
        showTipsScript:HidePreviewBtn(true)
        showTipsScript:SetBtnState(tbBtnInfo)
        showTipsScript:OnInitWithCoinShopGoods(tbGoods)
        scriptItemTip = showTipsScript
    elseif tbGoods.eGoodsType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
        local bCollect, nGold = CoinShop_GetCollectInfo(COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR, tbGoods.dwGoodsID)
        local showTipsScript = tipsScript
        local tips
        if not showTipsScript then
           tips, showTipsScript = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, clickNode)
        end
        local tbBtnInfo = {}
        if not bCollect and nGold >= 0 then
            table.insert(tbBtnInfo, {
                szName = "收集",
                OnClick = function ()
                    CoinShopWeapon.Collect(tbGoods.dwGoodsID)
                    if tips then
                        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
                    end
                end
            })
        end
        showTipsScript:SetBtnState(tbBtnInfo)
        showTipsScript:OnInitWithCoinShopGoods(tbGoods)
        UIHelper.SetTouchDownHideTips(showTipsScript.BtnFeature, false)
        scriptItemTip = showTipsScript
    elseif tbGoods.eGoodsType == COIN_SHOP_GOODS_TYPE.ITEM then
        local showTipsScript = tipsScript
        if not showTipsScript then
            _, showTipsScript = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, clickNode)
        end
        if not tbGoods.dwGoodsID then
            tbGoods.dwGoodsID = Table_GetRewardsGoodID(tbGoods.dwTabType, tbGoods.dwTabIndex)
        end
        showTipsScript:OnInitWithCoinShopGoods(tbGoods)
        showTipsScript:SetBtnState({})
        scriptItemTip = showTipsScript
    elseif tbGoods.eGoodsType == COIN_SHOP_GOODS_TYPE.HAIR then
        local showTipsScript = tipsScript
        if not showTipsScript then
            _, showTipsScript = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, clickNode)
        end
        showTipsScript:OnInitWithCoinShopGoods(tbGoods)
        showTipsScript:SetBtnState({})
        scriptItemTip = showTipsScript
    elseif tbGoods.eGoodsType == COIN_SHOP_GOODS_TYPE.SHOW_CARD_DECORATION then
        local showTipsScript = tipsScript
        if not showTipsScript then
            _, showTipsScript = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, clickNode)
        end
        showTipsScript:OnInitWithCoinShopGoods(tbGoods)
        showTipsScript:SetBtnState({})
        scriptItemTip = showTipsScript
    elseif tbGoods.dwTabType and tbGoods.dwTabIndex then
        local showTipsScript = tipsScript
        if not showTipsScript then
            _, showTipsScript = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, clickNode)
        end
        showTipsScript:OnInitWithTabID(tbGoods.dwTabType, tbGoods.dwTabIndex)
        showTipsScript:SetBtnState({})
        scriptItemTip = showTipsScript
    end
    return scriptItemTip
end

function CoinShopPreview.UpdateSimpleDownloadBtn(script, nDownloadDynamicID, bRemoteNotExist, tConfig)
    if nDownloadDynamicID then
        script:OnInitWithPackID(nDownloadDynamicID, tConfig)
        UIHelper.SetVisible(script._rootNode, true)
    elseif bRemoteNotExist then
        script:OnInitWithHint(tConfig)
        UIHelper.SetVisible(script._rootNode, true)
    else
        UIHelper.SetVisible(script._rootNode, false)
    end
end