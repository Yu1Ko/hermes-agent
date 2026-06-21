-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: OutFitPreviewData
-- Date: 2024-03-01 16:48:36
-- Desc: ?
-- ---------------------------------------------------------------------------------

OutFitPreviewData = OutFitPreviewData or {className = "OutFitPreviewData"}
local self = OutFitPreviewData


self.nCurrentOtherPlayerID = nil
self.tbCurPreview = {}
self.tbOtherPlayerOutFit = {}

self.tbCurBagPreviewItem = {}

self.PreviewType = {
	--Item = 1,
	--Exterior = 2,
	--Weapon = 3
    Pandent = 1,        --饰品
    ExteriorEquip = 2,  --外装装备
    ExteriorWeapon = 3, --外装武器
    Equip = 4,          --普通装备
    EquipWeapon = 5,     --武器
    ExteriorHair = 6    --发型
}

self.ItemType = {
    Pandent = 1,        --饰品
    ExteriorEquip = 2,  --外装装备
    ExteriorWeapon = 3, --外装武器
    Equip = 4,          --普通装备
    EquipWeapon = 5     --武器
}

self.PandentItemType = {
    --挂件
    [1] = {
        [PENDENT_SELECTED_POS.LSHOULDER] = 1,--3
        [PENDENT_SELECTED_POS.RSHOULDER] = 2,--4
        [PENDENT_SELECTED_POS.FACE] = 3,--1
        [PENDENT_SELECTED_POS.LGLOVE] = 4,--8
        [PENDENT_SELECTED_POS.RGLOVE] = 5,--9
        [PENDENT_SELECTED_POS.GLASSES] = 6,--7
        [PENDENT_SELECTED_POS.BACKCLOAK] = 7,--5
        [PENDENT_SELECTED_POS.BAG] = 9,--6
        [PENDENT_SELECTED_POS.BACK] = 10,--1
        [PENDENT_SELECTED_POS.WAIST] = 11,--0
        [PENDENT_SELECTED_POS.HEAD] = 20,--2
        [PENDENT_SELECTED_POS.HEAD1] = 21,--3
        [PENDENT_SELECTED_POS.HEAD2] = 22,--4
    },

    --外观
    [2] = {
        [EXTERIOR_INDEX_TYPE.HELM] = 13,--1
        [EXTERIOR_INDEX_TYPE.CHEST] = 14,--0
        [EXTERIOR_INDEX_TYPE.WAIST] = 15,--2
        [EXTERIOR_INDEX_TYPE.BANGLE] = 16,--4
        [EXTERIOR_INDEX_TYPE.BOOTS] = 17,--3
    },

    --装备
    [3] = {
        [EQUIPMENT_INVENTORY.HELM] = 13,--4
        [EQUIPMENT_INVENTORY.CHEST] = 14,--3
        [EQUIPMENT_INVENTORY.WAIST] = 15,--8
        [EQUIPMENT_INVENTORY.BANGLE] = 16,--12
        [EQUIPMENT_INVENTORY.BOOTS] = 17,--11
        [EQUIPMENT_INVENTORY.MELEE_WEAPON] = 12,--0
        [EQUIPMENT_INVENTORY.BIG_SWORD] = 18--1
    },
    --宠物挂件
    [4] = {
        [0] = 8
    },
    --外观装备
    [5] = {
        [WEAPON_EXTERIOR_BOX_INDEX_TYPE.MELEE_WEAPON] = 12,--0
        [WEAPON_EXTERIOR_BOX_INDEX_TYPE.BIG_SWORD] = 18,--1
    },
    --发型
    [6] = {
        [EQUIPMENT_REPRESENT.HAIR_STYLE] = 19
    }

}

self.PreviewItemType = {
    LeftShoulder = 1,
    RightShoulder = 2,
    Face = 3,
    LeftHand = 4,
    RightHand = 5,
    Eye = 6,
    Cape = 7,
    PendantPet = 8,
    Pasha = 9,
    Back = 10,
    Waist = 11,
    WeaponPrimary = 12,
    WeaponSecondary = 18,
    Hat = 13,
    Clothing = 14,
    Belt = 15,
    Bracers = 16,
    Shoes = 17
}

function OutFitPreviewData.Init()
	OutFitPreviewData.RegEvent()
end

function OutFitPreviewData.UnInit()

end
function OutFitPreviewData.RegEvent()
end

function OutFitPreviewData.GetOtherPlayerOutFit()

end

function OutFitPreviewData.CanPreview(nTabType, nIndex)
	local hItemInfo = GetItemInfo(nTabType, nIndex)

    if hItemInfo == nil then
        return
    end
    if hItemInfo.nGenre ~= ITEM_GENRE.EQUIPMENT and
        hItemInfo.nGenre ~= ITEM_GENRE.COIN_SHOP_QUANTITY_LIMIT_ITEM
    then
        return false
    end

    if hItemInfo.nGenre == ITEM_GENRE.EQUIPMENT and hItemInfo.nSub == EQUIPMENT_SUB.HORSE_EQUIP then
        return false
    end

    if hItemInfo.nGenre == ITEM_GENRE.EQUIPMENT and hItemInfo.nSub == EQUIPMENT_SUB.HORSE then
        return HorseMgr.IsShowHorse(nTabType, nIndex)
    end

    if hItemInfo.nGenre == ITEM_GENRE.EQUIPMENT and hItemInfo.nSub == EQUIPMENT_SUB.PET then
        local nPetIndex = GetFellowPetIndexByItemIndex(nTabType, nIndex)
        local tPet = Table_GetFellowPet(nPetIndex)
        if nPetIndex and tPet then
            local bHave = g_pClientPlayer.IsFellowPetAcquired(nPetIndex)
            if bHave or not tPet.bOnlyHaveShow then
                return true
            end
        end

        return false
    end

    if hItemInfo.nGenre == ITEM_GENRE.COIN_SHOP_QUANTITY_LIMIT_ITEM then
        if hItemInfo.nSub ~= QUANTITY_LIMIT_ITEM_SUB_TYPE.EXTERIOR and
            hItemInfo.nSub ~= QUANTITY_LIMIT_ITEM_SUB_TYPE.HAIR and
			hItemInfo.nSub ~= QUANTITY_LIMIT_ITEM_SUB_TYPE.PENDENT
        then
            return false
        end
    else
        local nRepresentSub = ExteriorView_GetRepresentSub(hItemInfo.nSub, hItemInfo.nDetail)
        if not nRepresentSub then
            return false
        end
    end
    return true
end

local m_tEquipSubToInventory = {
    [EQUIPMENT_SUB.HELM] = EQUIPMENT_INVENTORY.HELM,
    [EQUIPMENT_SUB.CHEST] = EQUIPMENT_INVENTORY.CHEST,
    [EQUIPMENT_SUB.WAIST] = EQUIPMENT_INVENTORY.WAIST,
    [EQUIPMENT_SUB.BANGLE] = EQUIPMENT_INVENTORY.BANGLE,
    [EQUIPMENT_SUB.BOOTS] = EQUIPMENT_INVENTORY.BOOTS,
    [EQUIPMENT_SUB.MELEE_WEAPON] = EQUIPMENT_INVENTORY.MELEE_WEAPON, -- EQUIPMENT_INVENTORY.BIG_SWORD特殊处理
}

function OutFitPreviewData.GetEquipTypeByEquipSub(nSub, nDetail)
    local nEquipInv = m_tEquipSubToInventory[nSub]
    if nDetail and nDetail == WEAPON_DETAIL.BIG_SWORD and nSub == EQUIPMENT_SUB.MELEE_WEAPON then
        nEquipInv = EQUIPMENT_INVENTORY.BIG_SWORD
    end
    return nEquipInv
end

local m_tExteriorSubToInventory = {
    [EQUIPMENT_REPRESENT.HELM_STYLE] = 13,
    [EQUIPMENT_REPRESENT.CHEST_STYLE] = 14,
    [EQUIPMENT_REPRESENT.BANGLE_STYLE] = 16,
    [EQUIPMENT_REPRESENT.WAIST_STYLE] = 15,
    [EQUIPMENT_REPRESENT.BOOTS_STYLE] = 17,
    [EQUIPMENT_REPRESENT.WEAPON_STYLE] = 12,
    [EQUIPMENT_REPRESENT.BIG_SWORD_STYLE] = 18,
}

function OutFitPreviewData.GetExteriorTypeByEquipSub(nRepresentSub)
    local nExteriorInv = m_tExteriorSubToInventory[nRepresentSub]
    --if nDetail and nDetail == WEAPON_DETAIL.BIG_SWORD and nSub == EQUIPMENT_SUB.MELEE_WEAPON then
    --    nExteriorInv = WEAPON_EXTERIOR_BOX_INDEX_TYPE.BIG_SWORD
    --end
    return nExteriorInv
end


function OutFitPreviewData.GetItemPreviewTypeInfo(item)
    local nType1, nType2 = 0, 0
    if ItemData.IsPendantItem(item) then    --挂件
        nType1 = self.PandentItemType[1][ItemData.GetPendantTypeByEquipSub(item.nSub)]
        nType2 = self.PreviewType.Pandent
    elseif ItemData.IsPendantPetSub(item.nSub) then --挂宠
        nType1 = self.PandentItemType[4][0]
        nType2 = self.PreviewType.Pandent
    elseif item.dwTabType == 6 or item.dwTabType == 7 then  --装备与武器
        local nEquipInv = self.GetEquipTypeByEquipSub(item.nSub, item.nDetail)
        nType1 = self.PandentItemType[3][nEquipInv]
        if nEquipInv == EQUIPMENT_INVENTORY.MELEE_WEAPON or nEquipInv == EQUIPMENT_INVENTORY.BIG_SWORD then
            nType2 = self.PreviewType.EquipWeapon
        else
            nType2 = self.PreviewType.Equip
        end
    elseif item.dwTabType == 5 then   --外装
        local hItemInfo = GetItemInfo(item.dwTabType, item.dwIndex)
        local dwExteriorID = hItemInfo.nDetail
        local tExteriorInfo = GetExterior().GetExteriorInfo(dwExteriorID)
        local nRepresentSub = ExteriorView_GetRepresentSub(tExteriorInfo.nSubType)
        nType1 = self.GetExteriorTypeByEquipSub(nRepresentSub)
        nType2 = self.PreviewType.ExteriorEquip
    end
    return nType1, nType2
end

local tRepresentSubToIndex =
{
    [EQUIPMENT_REPRESENT.HELM_STYLE] = 13,
    [EQUIPMENT_REPRESENT.CHEST_STYLE] = 14,
    [EQUIPMENT_REPRESENT.BANGLE_STYLE] = 16,
    [EQUIPMENT_REPRESENT.WAIST_STYLE] = 15,
    [EQUIPMENT_REPRESENT.BOOTS_STYLE] = 17,
    [EQUIPMENT_REPRESENT.WEAPON_STYLE] = 12,
    [EQUIPMENT_REPRESENT.BIG_SWORD_STYLE] = 18,
    [EQUIPMENT_REPRESENT.L_SHOULDER_EXTEND] = 1,
    [EQUIPMENT_REPRESENT.R_SHOULDER_EXTEND] = 2,
    [EQUIPMENT_REPRESENT.FACE_EXTEND] = 3,
    [EQUIPMENT_REPRESENT.L_GLOVE_EXTEND] = 4,
    [EQUIPMENT_REPRESENT.R_GLOVE_EXTEND] = 5,
    [EQUIPMENT_REPRESENT.GLASSES_EXTEND] = 6,
    [EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND] = 7,
    [EQUIPMENT_REPRESENT.PENDENT_PET_STYLE] = 8,
    [EQUIPMENT_REPRESENT.BAG_EXTEND] = 9,
    [EQUIPMENT_REPRESENT.BACK_EXTEND] = 10,
    [EQUIPMENT_REPRESENT.WAIST_EXTEND] = 11,
    [EQUIPMENT_REPRESENT.HAIR_STYLE] = 19,
    [EQUIPMENT_REPRESENT.HEAD_EXTEND] = 20
}

function OutFitPreviewData.SetPreviewBtn(dwTabType, dwIndex)
    local hItemInfo = GetItemInfo(dwTabType, dwIndex)
    local tbOtherPlayerOutFit = {}
    local tbBtnInfo = {}
    if hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.EXTERIOR and hItemInfo.nGenre == ITEM_GENRE.COIN_SHOP_QUANTITY_LIMIT_ITEM then --外观
        local dwExteriorID = hItemInfo.nDetail
        local tExteriorInfo = GetExterior().GetExteriorInfo(dwExteriorID)
        local nRepresentSub = ExteriorView_GetRepresentSub(tExteriorInfo.nSubType)
        local nIndex = tRepresentSubToIndex[nRepresentSub]
        if nRepresentSub == EQUIPMENT_REPRESENT.WEAPON_STYLE or nRepresentSub ==  EQUIPMENT_REPRESENT.BIG_SWORD_STYLE then  --外观武器
            table.insert(tbBtnInfo, { szName = "试穿", bNormalBtn = true, OnClick = function()
                if PropsSort.IsBagInSort() then
                    TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
                    return
                end
                local dwWeaponID = CoinShop_GetWeaponIDByItemInfo(hItemInfo)
                table.insert(tbOtherPlayerOutFit, nIndex, {["nType"] = OutFitPreviewData.PreviewType.ExteriorWeapon, ["dwWeaponID"] = dwWeaponID})
                Event.Dispatch("ON_HIDEMINISCENE_UNTILNEWVIEWCLOSE")
                UIMgr.CloseAllInLayer("UIPopupLayer")
                UIMgr.Open(VIEW_ID.PanelOutfitPreview, nil, tbOtherPlayerOutFit)
            end })
        else    --普通外观
            table.insert(tbBtnInfo, { szName = "试穿", bNormalBtn = true, OnClick = function()
                if PropsSort.IsBagInSort() then
                    TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
                    return
                end
                local dwExteriorID = hItemInfo.nDetail
                table.insert(tbOtherPlayerOutFit, nIndex, {["nType"] = OutFitPreviewData.PreviewType.ExteriorEquip, ["dwExteriorID"] = dwExteriorID})
                Event.Dispatch("ON_HIDEMINISCENE_UNTILNEWVIEWCLOSE")
                UIMgr.CloseAllInLayer("UIPopupLayer")
                UIMgr.Open(VIEW_ID.PanelOutfitPreview, nil, tbOtherPlayerOutFit)
            end })
        end
    elseif ItemData.IsPendantItem(hItemInfo) or hItemInfo.nSub == EQUIPMENT_SUB.PENDENT_PET or hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.PENDENT then   --挂件
        table.insert(tbBtnInfo, { szName = "试穿", bNormalBtn = true, OnClick = function()
            if PropsSort.IsBagInSort() then
                TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
                return
            end
            local hPendant
            if hItemInfo.nDetail and hItemInfo.nDetail > 0 then
                hPendant = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, hItemInfo.nDetail)
            else
                hPendant = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, dwIndex)
            end
            local nRepresentSub, nRepresentColor = ExteriorView_GetRepresentSub(hPendant.nSub, hPendant.nDetail)--14,0
            local nIndex = tRepresentSubToIndex[nRepresentSub]

            table.insert(tbOtherPlayerOutFit, nIndex, {["nType"] = OutFitPreviewData.PreviewType.Pandent, ["nTabType"] = dwTabType, ["dwIndex"] = dwIndex})
            Event.Dispatch("ON_HIDEMINISCENE_UNTILNEWVIEWCLOSE")
            UIMgr.CloseAllInLayer("UIPopupLayer")
            UIMgr.Open(VIEW_ID.PanelOutfitPreview, nil, tbOtherPlayerOutFit)
        end })
    elseif hItemInfo.nGenre == ITEM_GENRE.EQUIPMENT and hItemInfo.nSub == EQUIPMENT_SUB.MELEE_WEAPON then   --装备武器
        table.insert(tbBtnInfo, { szName = "试穿", bNormalBtn = true, OnClick = function()
            if PropsSort.IsBagInSort() then
                TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
                return
            end
            local dwWeaponID = CoinShop_GetWeaponIDByItemInfo(hItemInfo)
            local nRepresentSub = ExteriorView_GetRepresentSub(hItemInfo.nSub, hItemInfo.nDetail)
            local nIndex = tRepresentSubToIndex[nRepresentSub]
            table.insert(tbOtherPlayerOutFit ,nIndex, {["nType"] = OutFitPreviewData.PreviewType.EquipWeapon, ["nTabType"] = dwTabType, ["dwIndex"] = dwIndex})
            Event.Dispatch("ON_HIDEMINISCENE_UNTILNEWVIEWCLOSE")
            UIMgr.CloseAllInLayer("UIPopupLayer")
            UIMgr.Open(VIEW_ID.PanelOutfitPreview, nil, tbOtherPlayerOutFit)
        end })
    elseif hItemInfo.nGenre == ITEM_GENRE.COIN_SHOP_QUANTITY_LIMIT_ITEM and  hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.HAIR then   --发型
        table.insert(tbBtnInfo, {
            szName = "试穿", bNormalBtn = true, OnClick = function()
                if PropsSort.IsBagInSort() then
                    TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
                    return
                end
                table.insert(tbOtherPlayerOutFit, tRepresentSubToIndex[EQUIPMENT_REPRESENT.HAIR_STYLE], {["nType"] = OutFitPreviewData.PreviewType.ExteriorHair, ["nTabType"] = dwTabType, ["dwIndex"] = dwIndex, ["nHairID"] = hItemInfo.nDetail})
                Event.Dispatch("ON_HIDEMINISCENE_UNTILNEWVIEWCLOSE")
                UIMgr.CloseAllInLayer("UIPopupLayer")
                UIMgr.Open(VIEW_ID.PanelOutfitPreview, nil, tbOtherPlayerOutFit)
            end
        })
    elseif hItemInfo.nGenre == ITEM_GENRE.EQUIPMENT and hItemInfo.nSub == EQUIPMENT_SUB.HORSE then
        table.insert(tbBtnInfo, {
            szName = "预览", bNormalBtn = true,
            OnClick = function()
                if PropsSort.IsBagInSort() then
                    TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
                    return
                end
                if UIMgr.GetView(VIEW_ID.PanelSaddleHorse) then
                    UIMgr.Close(VIEW_ID.PanelSaddleHorse)
                end
                UIMgr.Open(VIEW_ID.PanelSaddleHorse, dwTabType, dwIndex)
        end })
    elseif hItemInfo.nGenre == ITEM_GENRE.EQUIPMENT and hItemInfo.nSub == EQUIPMENT_SUB.PET then
        table.insert(tbBtnInfo, {
            szName = "预览", bNormalBtn = true,
            OnClick = function()
                if PropsSort.IsBagInSort() then
                    TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
                    return
                end
                if UIMgr.GetView(VIEW_ID.PanelPetMap) then
                    UIMgr.Close(VIEW_ID.PanelPetMap)
                end
                Timer.Add(self, 0.5, function ()
                    Event.Dispatch("ON_HIDEMINISCENE_UNTILNEWPETVIEWCLOSE")
                    UIMgr.Open(VIEW_ID.PanelPetMap, nil, nil, dwTabType, dwIndex)
                end)
        end })
    else
        table.insert(tbBtnInfo, { szName = "试穿", bNormalBtn = true, OnClick = function()
            if PropsSort.IsBagInSort() then
                TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
                return
            end
            local nRepresentSub = ExteriorView_GetRepresentSub(hItemInfo.nSub)
            local nIndex = tRepresentSubToIndex[nRepresentSub]
            table.insert(tbOtherPlayerOutFit, nIndex, {["nType"] = OutFitPreviewData.PreviewType.Equip, ["nTabType"] = dwTabType, ["dwIndex"] = dwIndex})
            Event.Dispatch("ON_HIDEMINISCENE_UNTILNEWVIEWCLOSE")
            UIMgr.CloseAllInLayer("UIPopupLayer")
            UIMgr.Open(VIEW_ID.PanelOutfitPreview, nil, tbOtherPlayerOutFit)
        end })
    end
    return tbBtnInfo
end

function OutFitPreviewData.GetPlayerBagItemList()
    local tbPendantList = {}
    local tbExteriorList = {}
    local tbEquipList = {}
    local tbBoxSet = ItemData.BoxSet.Bag
    for i, nBox in ipairs(tbBoxSet) do
        for k, tbItemInfo in ipairs(ItemData.GetBoxItem(nBox)) do
            local item = ItemData.GetItemByPos(tbItemInfo.nBox, tbItemInfo.nIndex)
            if item and self.CanPreview(item.dwTabType, item.dwIndex) then
                local hItemInfo = GetItemInfo(item.dwTabType, item.dwIndex)
                if hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.EXTERIOR and hItemInfo.nGenre == ITEM_GENRE.COIN_SHOP_QUANTITY_LIMIT_ITEM then --外观
                    local dwExteriorID = hItemInfo.nDetail
                    local tExteriorInfo = GetExterior().GetExteriorInfo(dwExteriorID)
                    local nRepresentSub = ExteriorView_GetRepresentSub(tExteriorInfo.nSubType)
                    local nIndex = tRepresentSubToIndex[nRepresentSub]
                    if nRepresentSub == EQUIPMENT_REPRESENT.WEAPON_STYLE or nRepresentSub ==  EQUIPMENT_REPRESENT.BIG_SWORD_STYLE then  --外观武器
                        local dwWeaponID = CoinShop_GetWeaponIDByItemInfo(hItemInfo)
                        table.insert(tbExteriorList, {
                            ["nType"] = OutFitPreviewData.PreviewType.ExteriorWeapon,
                            ["dwWeaponID"] = dwWeaponID,
                            ["nPosition"] = nIndex
                        })
                    else    --普通外观
                        table.insert(tbExteriorList, {
                            ["nType"] = OutFitPreviewData.PreviewType.ExteriorEquip,
                            ["dwExteriorID"] = dwExteriorID,
                            ["nPosition"] = nIndex
                        })
                    end
                elseif ItemData.IsPendantItem(hItemInfo) or hItemInfo.nSub == EQUIPMENT_SUB.PENDENT_PET or hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.PENDENT then   --挂件
                    local hPendant = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, hItemInfo.nDetail)
                    if not hPendant then
                        hPendant = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, item.dwIndex)
                    end
                    local nRepresentSub, nRepresentColor = ExteriorView_GetRepresentSub(hPendant.nSub, hPendant.nDetail)
                    local nIndex = tRepresentSubToIndex[nRepresentSub]
                    table.insert(tbPendantList, {
                        ["nType"] = OutFitPreviewData.PreviewType.Pandent,
                        ["nTabType"] = item.dwTabType,
                        ["dwIndex"] = item.dwIndex,
                        ["nPosition"] = nIndex
                    })
                elseif hItemInfo.nGenre == ITEM_GENRE.EQUIPMENT and hItemInfo.nSub == EQUIPMENT_SUB.MELEE_WEAPON then   --装备武器
                    local dwWeaponID = CoinShop_GetWeaponIDByItemInfo(hItemInfo)
                    local nRepresentSub = ExteriorView_GetRepresentSub(hItemInfo.nSub, hItemInfo.nDetail)
                    local nIndex = tRepresentSubToIndex[nRepresentSub]
                    table.insert(tbEquipList, {
                        ["nType"] = OutFitPreviewData.PreviewType.EquipWeapon,
                        ["nTabType"] = item.dwTabType,
                        ["dwIndex"] = item.dwIndex,
                        ["nPosition"] = nIndex
                    })
                elseif hItemInfo.nGenre == ITEM_GENRE.COIN_SHOP_QUANTITY_LIMIT_ITEM and hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.HAIR then
                    local nHairID = hItemInfo.nDetail
                    local nRepresentSub = ExteriorView_GetRepresentSub(hItemInfo.nSub, hItemInfo.nDetail)
                    local nIndex = tRepresentSubToIndex[EQUIPMENT_REPRESENT.HAIR_STYLE]
                    table.insert(tbExteriorList, {
                        ["nType"] = OutFitPreviewData.PreviewType.ExteriorHair,
                        ["nTabType"] = item.dwTabType,
                        ["dwIndex"] = item.dwIndex,
                        ["nHairID"] = nHairID,
                        ["nPosition"] = nIndex
                    })
                else
                    local nRepresentSub = ExteriorView_GetRepresentSub(hItemInfo.nSub)
                    local nIndex = tRepresentSubToIndex[nRepresentSub]
                    table.insert(tbEquipList, {
                        ["nType"] = OutFitPreviewData.PreviewType.Equip,
                        ["nTabType"] = item.dwTabType,
                        ["dwIndex"] = item.dwIndex,
                        ["nPosition"] = nIndex
                    })
                end
            end
        end
    end
    return tbPendantList, tbExteriorList, tbEquipList
end

local function IsTimeOk(nStartTime, nEndTime)
    local nTime = GetCurrentTime()
    return (nStartTime == -1 or nTime >= nStartTime) and
            (nEndTime == -1 or nTime <= nEndTime)
end

function OutFitPreviewData.HairCanBuy(nType, nHairID)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local hHairShopClient = GetHairShop()
    if not hHairShopClient then
        return
    end

    local tHairPrice = hHairShopClient.GetHairPrice(hPlayer.nRoleType, nType, nHairID)
    if not tHairPrice then
        return
    end

    local bCanBuy = IsTimeOk(tHairPrice.nStartTime, tHairPrice.nEndTime)
    return bCanBuy
end

local tTypeChange = {
    [QUANTITY_LIMIT_ITEM_SUB_TYPE.EXTERIOR] = NPC_EXTERIOR_TYPE.CHEST,
    [QUANTITY_LIMIT_ITEM_SUB_TYPE.HAIR] = NPC_EXTERIOR_TYPE.HAIR,
}
--侠客预览
function OutFitPreviewData.CanPreviewToNpc(nTabType, nIndex)
    local hItemInfo = GetItemInfo(nTabType, nIndex)
    if hItemInfo and hItemInfo.nGenre == ITEM_GENRE.COIN_SHOP_QUANTITY_LIMIT_ITEM then
        if hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.EXTERIOR or
        hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.HAIR then
            local dwExteriorID = hItemInfo.nDetail
            local nType = tTypeChange[hItemInfo.nSub]
            local bCanDressToNpc = Partner_IsExteriorCanDressToNpc(nType, dwExteriorID)
            if bCanDressToNpc then
               return true
            end
        end
    end
    return false
end

local tIndexChange = {
    [1] = NPC_EXTERIOR_TYPE.HAIR,
    [2] = NPC_EXTERIOR_TYPE.CHEST,
}

function OutFitPreviewData.CanToNpc(nIndex, dwExteriorID)
    local nType = tIndexChange[nIndex]
    local bCanDressToNpc = Partner_IsExteriorCanDressToNpc(nType, dwExteriorID)
    if bCanDressToNpc then
        return true
    end
end

function OutFitPreviewData.SetNpcPreviewBtn(dwTabType, dwIndex)
    local tTable = {}
    local hItemInfo = GetItemInfo(dwTabType, dwIndex)

    local dwExteriorID = hItemInfo.nDetail
    local tbNpcOutFit = {}
    local tbBtnInfo = {}

    local tExteriorInfo = GetExterior().GetExteriorInfo(dwExteriorID)
    local nRepresentSub = ExteriorView_GetRepresentSub(tExteriorInfo.nSubType)
    local nIndex = tRepresentSubToIndex[nRepresentSub]

    table.insert(tbBtnInfo, {
        szName = "侠客试穿",
        bNormalBtn = true,
        OnClick = function()
            table.insert(tbNpcOutFit, nIndex, {["nType"] = OutFitPreviewData.PreviewType.ExteriorEquip, ["dwExteriorID"] = dwExteriorID})
            Event.Dispatch("ON_HIDEMINISCENE_UNTILNEWVIEWCLOSE")
            UIMgr.Open(VIEW_ID.PanelOutfitPreview, nil, tbNpcOutFit, true)
        end
    })

    return tbBtnInfo
end

local tbPartnerType = {
    [1] = {1, 4, 8, 10, 13, 14, 16, 17, 21},
    [2] = {3, 5, 7, 12, 15, 19},
    [5] = {9},
    [6] = {2, 6, 11, 18, 20}
}

function OutFitPreviewData.GetPartnerRoleType(dwPartnerID)
    for i, v in ipairs(tbPartnerType) do
        if table.contain_value(v, dwPartnerID) then
            return i
        end
    end
    return 1
end

function OutFitPreviewData.GetPandentItemPos(nType)
    for i, v in ipairs(self.PandentItemType[1]) do
        if v == nType then
            return i
        end
    end
end

function OutFitPreviewData.GetPendantSub(nIndex)
   	local nPendantPos = OutFitPreviewData.GetPandentItemPos(nIndex)
    local nBoxIndex = CoinShop_PendantTypeToBoxIndex(nPendantPos)
    local nRepresentSub = Exterior_BoxIndexToRepresentSub(nBoxIndex)
	return nRepresentSub
end