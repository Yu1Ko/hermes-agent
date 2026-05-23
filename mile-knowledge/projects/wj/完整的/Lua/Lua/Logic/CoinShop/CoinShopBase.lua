g_tCoinShopData =
{
    -- bPreviewMatchHair = false,
    dwPackageIndex = 0,
    bAutoShowPendantPos = true,
    tPackageIndex = {nVersion = 1.0},
    tUseLifeFaceName = {},
    tFaceName = {},
}
local SM_OUTFIT_MAX_COUNT = 16
--RegisterCustomData("g_tCoinShopData.bPreviewMatchHair")
--RegisterCustomData("g_tCoinShopData.dwPackageIndex") 改成tPackageIndex了
-- RegisterCustomData("g_tCoinShopData.tPackageIndex")
-- RegisterCustomData("g_tCoinShopData.bAutoShowPendantPos")
-- RegisterCustomData("g_tCoinShopData.tUseLifeFaceName")
-- RegisterCustomData("g_tCoinShopData.tFaceName")

local tSubToBoxIndex =
{
    [EQUIPMENT_SUB.HELM]              = COINSHOP_BOX_INDEX.HELM,                -- 头部
    [EQUIPMENT_SUB.CHEST]             = COINSHOP_BOX_INDEX.CHEST,               -- 上衣
    [EQUIPMENT_SUB.BANGLE]            = COINSHOP_BOX_INDEX.BANGLE,              -- 护手
    [EQUIPMENT_SUB.WAIST]             = COINSHOP_BOX_INDEX.WAIST,               -- 腰带
    [EQUIPMENT_SUB.BOOTS]             = COINSHOP_BOX_INDEX.BOOTS,               -- 鞋子
    [EQUIPMENT_SUB.FACE_EXTEND]       = COINSHOP_BOX_INDEX.FACE_EXTEND,         -- 面部挂件
    [EQUIPMENT_SUB.BACK_EXTEND]       = COINSHOP_BOX_INDEX.BACK_EXTEND,         -- 背部挂件
    [EQUIPMENT_SUB.WAIST_EXTEND]      = COINSHOP_BOX_INDEX.WAIST_EXTEND,        -- 腰部挂件
    [EQUIPMENT_SUB.L_SHOULDER_EXTEND] = COINSHOP_BOX_INDEX.L_SHOULDER_EXTEND,   -- 左肩饰
    [EQUIPMENT_SUB.R_SHOULDER_EXTEND] = COINSHOP_BOX_INDEX.R_SHOULDER_EXTEND,   -- 右肩饰
    [EQUIPMENT_SUB.BACK_CLOAK_EXTEND] = COINSHOP_BOX_INDEX.BACK_CLOAK_EXTEND,   -- 披风
    [EQUIPMENT_SUB.BAG_EXTEND]        = COINSHOP_BOX_INDEX.BAG_EXTEND,          -- 包饰
    [EQUIPMENT_SUB.PENDENT_PET]       = COINSHOP_BOX_INDEX.PENDANT_PET,         -- 挂宠
    [EQUIPMENT_SUB.GLASSES_EXTEND]    = COINSHOP_BOX_INDEX.GLASSES_EXTEND,      -- 眼饰
    [EQUIPMENT_SUB.L_GLOVE_EXTEND]    = COINSHOP_BOX_INDEX.L_GLOVE_EXTEND,      -- 左手饰
    [EQUIPMENT_SUB.R_GLOVE_EXTEND]    = COINSHOP_BOX_INDEX.R_GLOVE_EXTEND,      -- 右手饰
    [EQUIPMENT_SUB.HEAD_EXTEND]       = COINSHOP_BOX_INDEX.HEAD_EXTEND,         -- 头饰
}

local tSubToBoxIndexEX =
{
    [EQUIPMENT_SUB.CHEST]             = COINSHOP_BOX_INDEX.CHEST_EX, -- 上衣
    [EQUIPMENT_SUB.BOOTS]             = COINSHOP_BOX_INDEX.BOOTS_EX, -- 鞋子
    [EQUIPMENT_SUB.PANTS]             = COINSHOP_BOX_INDEX.PANTS_EX, -- 裤子
}


local tRepresentSubToBoxIndex =
{
    [EQUIPMENT_REPRESENT.HELM_STYLE]        = COINSHOP_BOX_INDEX.HELM,              -- 头部 2
    [EQUIPMENT_REPRESENT.CHEST_STYLE]       = COINSHOP_BOX_INDEX.CHEST,             -- 上衣 5
    [EQUIPMENT_REPRESENT.BANGLE_STYLE]      = COINSHOP_BOX_INDEX.BANGLE,            -- 护手 11
    [EQUIPMENT_REPRESENT.WAIST_STYLE]       = COINSHOP_BOX_INDEX.WAIST,             -- 腰带 8
    [EQUIPMENT_REPRESENT.BOOTS_STYLE]       = COINSHOP_BOX_INDEX.BOOTS,             -- 鞋子 14
    [EQUIPMENT_REPRESENT.FACE_EXTEND]       = COINSHOP_BOX_INDEX.FACE_EXTEND,       -- 面部挂件
    [EQUIPMENT_REPRESENT.BACK_EXTEND]       = COINSHOP_BOX_INDEX.BACK_EXTEND,       -- 背部挂件
    [EQUIPMENT_REPRESENT.WAIST_EXTEND]      = COINSHOP_BOX_INDEX.WAIST_EXTEND,      -- 腰部挂件
    [EQUIPMENT_REPRESENT.WEAPON_STYLE]      = COINSHOP_BOX_INDEX.WEAPON,            -- 武器
    [EQUIPMENT_REPRESENT.BIG_SWORD_STYLE]   = COINSHOP_BOX_INDEX.BIG_SWORD,         --重剑
    [EQUIPMENT_REPRESENT.L_SHOULDER_EXTEND] = COINSHOP_BOX_INDEX.L_SHOULDER_EXTEND, --左肩挂件
    [EQUIPMENT_REPRESENT.R_SHOULDER_EXTEND] = COINSHOP_BOX_INDEX.R_SHOULDER_EXTEND, --右肩挂件
    [EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND] = COINSHOP_BOX_INDEX.BACK_CLOAK_EXTEND, --披风
    [EQUIPMENT_REPRESENT.BAG_EXTEND]        = COINSHOP_BOX_INDEX.BAG_EXTEND,        --包饰
    [EQUIPMENT_REPRESENT.PENDENT_PET_STYLE] = COINSHOP_BOX_INDEX.PENDANT_PET,       --挂宠
    [EQUIPMENT_REPRESENT.GLASSES_EXTEND]    = COINSHOP_BOX_INDEX.GLASSES_EXTEND,    --眼饰
    [EQUIPMENT_REPRESENT.L_GLOVE_EXTEND]    = COINSHOP_BOX_INDEX.L_GLOVE_EXTEND,    --左手饰
    [EQUIPMENT_REPRESENT.R_GLOVE_EXTEND]    = COINSHOP_BOX_INDEX.R_GLOVE_EXTEND,    --右手饰
    [EQUIPMENT_REPRESENT.HAIR_STYLE]        = COINSHOP_BOX_INDEX.HAIR,
    [EQUIPMENT_REPRESENT.HEAD_EXTEND]       = COINSHOP_BOX_INDEX.HEAD_EXTEND,       --头饰
    [EQUIPMENT_REPRESENT.HEAD_EXTEND1]      = COINSHOP_BOX_INDEX.HEAD_EXTEND1,      --头饰
    [EQUIPMENT_REPRESENT.HEAD_EXTEND2]      = COINSHOP_BOX_INDEX.HEAD_EXTEND2,      --头饰
}

local tRepresentSubToBoxIndexEX =
{
    [EQUIPMENT_REPRESENT.CHEST_STYLE]       = COINSHOP_BOX_INDEX.CHEST_EX, -- 上衣 5
    [EQUIPMENT_REPRESENT.BOOTS_STYLE]       = COINSHOP_BOX_INDEX.BOOTS_EX, -- 鞋子 14
    [EQUIPMENT_REPRESENT.PANTS_STYLE]       = COINSHOP_BOX_INDEX.PANTS_EX, -- 裤子
}


local tBoxIndexToExteriorSub =
{
    [COINSHOP_BOX_INDEX.HELM]        = EXTERIOR_INDEX_TYPE.HELM,
    [COINSHOP_BOX_INDEX.CHEST]       = EXTERIOR_INDEX_TYPE.CHEST,
    [COINSHOP_BOX_INDEX.BANGLE]      = EXTERIOR_INDEX_TYPE.BANGLE,
    [COINSHOP_BOX_INDEX.WAIST]       = EXTERIOR_INDEX_TYPE.WAIST,
    [COINSHOP_BOX_INDEX.BOOTS]       = EXTERIOR_INDEX_TYPE.BOOTS,
    [COINSHOP_BOX_INDEX.CHEST_EX]    = EXTERIOR_INDEX_TYPE.CHEST,
    [COINSHOP_BOX_INDEX.BOOTS_EX]    = EXTERIOR_INDEX_TYPE.BOOTS,
    [COINSHOP_BOX_INDEX.PANTS_EX]    = EXTERIOR_INDEX_TYPE.PANTS,
}

local tRepresentSubToColor =
{
    [EQUIPMENT_REPRESENT.HELM_STYLE]  = EQUIPMENT_REPRESENT.HELM_COLOR,
    [EQUIPMENT_REPRESENT.CHEST_STYLE] = EQUIPMENT_REPRESENT.CHEST_COLOR,
    [EQUIPMENT_REPRESENT.BANGLE_STYLE] = EQUIPMENT_REPRESENT.BANGLE_COLOR,
    [EQUIPMENT_REPRESENT.WAIST_STYLE] = EQUIPMENT_REPRESENT.WAIST_COLOR,
    [EQUIPMENT_REPRESENT.BOOTS_STYLE] = EQUIPMENT_REPRESENT.BOOTS_COLOR,
    [EQUIPMENT_REPRESENT.WEAPON_STYLE] = EQUIPMENT_REPRESENT.WEAPON_COLOR,
    [EQUIPMENT_REPRESENT.BIG_SWORD_STYLE] = EQUIPMENT_REPRESENT.BIG_SWORD_COLOR,
    [EQUIPMENT_REPRESENT.PANTS_STYLE] = EQUIPMENT_REPRESENT.PANTS_COLOR,
}

local tRepresentSubToDyeing = {
    [EQUIPMENT_REPRESENT.HELM_STYLE] = EQUIPMENT_REPRESENT.HEAD_DYEING,
}

local tRepresentSubToEquipInventory =
{
    [EQUIPMENT_REPRESENT.HELM_STYLE]  = EQUIPMENT_INVENTORY.HELM,
    [EQUIPMENT_REPRESENT.CHEST_STYLE] = EQUIPMENT_INVENTORY.CHEST,
    [EQUIPMENT_REPRESENT.BANGLE_STYLE] = EQUIPMENT_INVENTORY.BANGLE,
    [EQUIPMENT_REPRESENT.WAIST_STYLE] = EQUIPMENT_INVENTORY.WAIST,
    [EQUIPMENT_REPRESENT.BOOTS_STYLE] = EQUIPMENT_INVENTORY.BOOTS,
    [EQUIPMENT_REPRESENT.WEAPON_STYLE] = EQUIPMENT_INVENTORY.MELEE_WEAPON,
    [EQUIPMENT_REPRESENT.BIG_SWORD_STYLE] = EQUIPMENT_INVENTORY.BIG_SWORD,
}

local tHairBoxIndex =
{
    [HAIR_STYLE.HAIR] = COINSHOP_BOX_INDEX.HAIR,
    [HAIR_STYLE.FACE] = COINSHOP_BOX_INDEX.FACE,
}

local tWeaponEnchant =
{
    [COINSHOP_BOX_INDEX.WEAPON] = {EQUIPMENT_REPRESENT.WEAPON_ENCHANT1, EQUIPMENT_REPRESENT.WEAPON_ENCHANT2},
    [COINSHOP_BOX_INDEX.BIG_SWORD] = {EQUIPMENT_REPRESENT.BIG_SWORD_ENCHANT1, EQUIPMENT_REPRESENT.BIG_SWORD_ENCHANT2},
}

local tWeaponBox =
{
    [COINSHOP_BOX_INDEX.WEAPON] = WEAPON_EXTERIOR_BOX_INDEX_TYPE.MELEE_WEAPON,
    [COINSHOP_BOX_INDEX.BIG_SWORD] = WEAPON_EXTERIOR_BOX_INDEX_TYPE.BIG_SWORD,
}

local tRideIndex =
{
    [EQUIPMENT_REPRESENT.HORSE_ADORNMENT1] = COINSHOP_RIDE_BOX_INDEX.HEAD_HORSE_EQUIP,
    [EQUIPMENT_REPRESENT.HORSE_ADORNMENT2] = COINSHOP_RIDE_BOX_INDEX.CHEST_HORSE_EQUIP,
    [EQUIPMENT_REPRESENT.HORSE_ADORNMENT3] = COINSHOP_RIDE_BOX_INDEX.FOOT_HORSE_EQUIP,
    [EQUIPMENT_REPRESENT.HORSE_ADORNMENT4] = COINSHOP_RIDE_BOX_INDEX.HANG_ITEM_HORSE_EQUIP,
    [EQUIPMENT_REPRESENT.HORSE_STYLE] = COINSHOP_RIDE_BOX_INDEX.HORSE,
}

local tRideIndexToEquip =
{
    EQUIPMENT_INVENTORY.HEAD_HORSE_EQUIP,
    EQUIPMENT_INVENTORY.CHEST_HORSE_EQUIP,
    EQUIPMENT_INVENTORY.FOOT_HORSE_EQUIP,
    EQUIPMENT_INVENTORY.HANG_ITEM_HORSE_EQUIP,
}

local tHomeTypeToGoods =
{
    [HOME_TYPE.HAIR] = COIN_SHOP_GOODS_TYPE.HAIR,
    [HOME_TYPE.FACE] = COIN_SHOP_GOODS_TYPE.FACE,
    [HOME_TYPE.EXTERIOR] = COIN_SHOP_GOODS_TYPE.EXTERIOR,
    [HOME_TYPE.REWARDS] = COIN_SHOP_GOODS_TYPE.ITEM,
    [HOME_TYPE.EXTERIOR_SET] = COIN_SHOP_GOODS_TYPE.EXTERIOR,
    [HOME_TYPE.EXTERIOR_WEAPON] = COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR,
    [HOME_TYPE.EFFECT_SFX] = COIN_SHOP_GOODS_TYPE.ITEM,
}

local tRewardsClassToSub =
{
    [REWARDS_CLASS.CLOTH_PENDANT_CLOAK] = EQUIPMENT_SUB.BACK_CLOAK_EXTEND,
    [REWARDS_CLASS.PENDANT_FACE] = EQUIPMENT_SUB.FACE_EXTEND,
    [REWARDS_CLASS.PENDANT_BACK] = EQUIPMENT_SUB.BACK_EXTEND,
    [REWARDS_CLASS.PENDANT_WAIST] = EQUIPMENT_SUB.WAIST_EXTEND,
    [REWARDS_CLASS.CLOTH_PENDANT_LSHOULDER] = EQUIPMENT_SUB.L_SHOULDER_EXTEND,
    [REWARDS_CLASS.CLOTH_PENDANT_RSHOULDER] = EQUIPMENT_SUB.R_SHOULDER_EXTEND,
    [REWARDS_CLASS.CLOTH_PENDANT_BAG] = EQUIPMENT_SUB.BAG_EXTEND,
    [REWARDS_CLASS.GLASSES] = EQUIPMENT_SUB.GLASSES_EXTEND,
    [REWARDS_CLASS.LHAND] = EQUIPMENT_SUB.L_GLOVE_EXTEND,
    [REWARDS_CLASS.RHAND] = EQUIPMENT_SUB.R_GLOVE_EXTEND,
    [REWARDS_CLASS.HEAD_EXTEND] = EQUIPMENT_SUB.HEAD_EXTEND,
}

local ICON_FACE = 10776
local ICON_HAIR = 10775

CoinShopBase = CoinShopBase or {className = "CoinShopBase"}

function CoinShop_HomeTypeToGoods(nType)
    return tHomeTypeToGoods[nType]
end

function Exterior_SubToBoxIndex(nSub)
    return tSubToBoxIndex[nSub]
end

function Exterior_RepresentToBoxIndex(nSub)
    return tRepresentSubToBoxIndex[nSub]
end

function Exterior_BoxIndexToRepresentSub(nIndex)
    for nSub, nBoxIndex in pairs(tRepresentSubToBoxIndex) do
        if nIndex == nBoxIndex then
            return nSub
        end
    end
    for nSub, nBoxIndex in pairs(tRepresentSubToBoxIndexEX) do
        if nIndex == nBoxIndex then
            return nSub
        end
    end
end

function Exterior_BoxIndexToExteriorSub(nIndex)
    return tBoxIndexToExteriorSub[nIndex]
end

function Exterior_BoxIndexToSub(nIndex)
    for nSub, nBoxIndex in pairs(tSubToBoxIndex) do
        if nIndex == nBoxIndex then
            return nSub
        end
    end

    for nSub, nBoxIndex in pairs(tSubToBoxIndexEX) do
        if nIndex == nBoxIndex then
            return nSub
        end
    end
end

function Exterior_SubToRepresentSub(nSub)
    local nBoxIndex = Exterior_SubToBoxIndex(nSub)
    return Exterior_BoxIndexToRepresentSub(nBoxIndex)
end

function Exterior_RepresentSubToColor(nSub)
    return tRepresentSubToColor[nSub]
end

function Exterior_RepresentSubToDyeing(nSub)
    return tRepresentSubToDyeing[nSub]
end

function Exterior_RepresentSubToEquipSub(nSub)
    return tRepresentSubToEquipInventory[nSub]
end

function CoinShop_GetHairBoxIndex(nType)
    return tHairBoxIndex[nType]
end

function CoinShop_GetWeaponIndex(dwWeaponID)
    local tExteriorInfo = CoinShop_GetWeaponExteriorInfo(dwWeaponID)
    local nIndex = 12
    if tExteriorInfo.nDetailType == WEAPON_DETAIL.BIG_SWORD then
        nIndex = 13
    end
    return nIndex
end

function Exterior_GetSubIndex(dwID)
    local tInfo = GetExterior().GetExteriorInfo(dwID)
    local nIndex = Exterior_SubToBoxIndex(tInfo.nSubType)
    return nIndex
end

function Exterior_GetPerdentIndex(dwTabType, dwIndex)
    local hItemInfo = GetItemInfo(dwTabType, dwIndex)
    local nRepresentSub = ExteriorView_GetRepresentSub(hItemInfo.nSub, hItemInfo.nDetail)
    local nIndex = Exterior_RepresentToBoxIndex(nRepresentSub)
    return nIndex
end

function Exterior_GetHouseEquipIndex(dwTabType, dwIndex)
	local hItemInfo = GetItemInfo(dwTabType, dwIndex)
    local nRepresentSub = ExteriorView_GetRepresentSub(hItemInfo.nSub, hItemInfo.nDetail)
    local nIndex = CoinShop_GetRideIndex(nRepresentSub)
    return nIndex
end

function CoinShop_GetWeaponIndexArray()
    return tWeaponBox
end

function CoinShop_GetWeaponEnchantArray()
    return tWeaponEnchant
end

function CoinShop_GetRideIndex(nRepresentID)
    return tRideIndex[nRepresentID]
end

function CoinShop_GetRideIndexArray()
    return tRideIndex
end

function CoinShop_GetRideEquipIndex(nIndex)
    return tRideIndexToEquip[nIndex]
end

local tPendentPosToBoxIndex =
{
    [PENDENT_SELECTED_POS.FACE]       = COINSHOP_BOX_INDEX.FACE_EXTEND,         -- 面部挂件
    [PENDENT_SELECTED_POS.BACK]       = COINSHOP_BOX_INDEX.BACK_EXTEND,         -- 背部挂件
    [PENDENT_SELECTED_POS.WAIST]      = COINSHOP_BOX_INDEX.WAIST_EXTEND,        -- 腰部挂件
    [PENDENT_SELECTED_POS.LSHOULDER]       = COINSHOP_BOX_INDEX.L_SHOULDER_EXTEND,   -- 左肩饰
    [PENDENT_SELECTED_POS.RSHOULDER]   = COINSHOP_BOX_INDEX.R_SHOULDER_EXTEND,   -- 右肩饰
    [PENDENT_SELECTED_POS.BACKCLOAK] = COINSHOP_BOX_INDEX.BACK_CLOAK_EXTEND,   -- 披风
    [PENDENT_SELECTED_POS.BAG]        = COINSHOP_BOX_INDEX.BAG_EXTEND,          -- 包饰
    [PENDENT_SELECTED_POS.GLASSES]    = COINSHOP_BOX_INDEX.GLASSES_EXTEND,      -- 眼饰
    [PENDENT_SELECTED_POS.LGLOVE]    = COINSHOP_BOX_INDEX.L_GLOVE_EXTEND,      -- 左手饰
    [PENDENT_SELECTED_POS.RGLOVE]    = COINSHOP_BOX_INDEX.R_GLOVE_EXTEND,      -- 右手饰
    [PENDENT_SELECTED_POS.HEAD]       = COINSHOP_BOX_INDEX.HEAD_EXTEND,         -- 头饰
    [PENDENT_SELECTED_POS.HEAD1]      = COINSHOP_BOX_INDEX.HEAD_EXTEND1,        --头饰
    [PENDENT_SELECTED_POS.HEAD2]      = COINSHOP_BOX_INDEX.HEAD_EXTEND2,        --头饰
}

function CoinShop_PendantTypeToBoxIndex(nPendantPos)
    -- local nSub = GetEquipSubByPendantType(nPendantType)
    -- return Exterior_SubToBoxIndex(nSub)
    return tPendentPosToBoxIndex[nPendantPos]
end

function CoinShop_PendantTypeToRepresentSub(nPendantPos)
    local nIndex = CoinShop_PendantTypeToBoxIndex(nPendantPos)
    if nIndex then
        return Exterior_BoxIndexToRepresentSub(nIndex)
    end
end

function CoinShop_RepresentSubToPendantType(nType)
    local nIndex = Exterior_RepresentToBoxIndex(nType)
    if nIndex then
        return CoinShop_BoxIndexToPendantType(nIndex)
    end
end

function CoinShop_RepresentSubToPendantPos(nSub)
    for nPendantType, nIndex in pairs(tPendentPosToBoxIndex) do
        local nRepresentSub = Exterior_BoxIndexToRepresentSub(nIndex)
        if nRepresentSub == nSub then
            return nPendantType
        end
    end
end

function CoinShop_BoxIndexToPendantType(nBoxIndex)
    for nPendantType, nIndex in pairs(tPendentPosToBoxIndex) do
        if nIndex == nBoxIndex then
            return nPendantType
        end
    end
end

function CoinShop_PendantPosToSub(nPendantPos)
    nPendantPos = DealwithPendantPosToShow(nPendantPos)
    local nIndex = CoinShop_PendantTypeToBoxIndex(nPendantPos)
    local nSub = Exterior_BoxIndexToSub(nIndex)
    return nSub
end

function CoinShop_RewardsClassToSub(nClass)
    return tRewardsClassToSub[nClass]
end

function CoinShop_SubToRewardsClass(nSub)
    for nClass, nEquipSub in pairs(tRewardsClassToSub) do
        if nEquipSub == nSub then
            return nClass
        end
    end
end

g_tExteriorPayTypeImg =
{
    [COIN_SHOP_PAY_TYPE.COIN] =  "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_TongBao.png",
    [COIN_SHOP_PAY_TYPE.MONEY] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Jin.png",
    [COIN_SHOP_PAY_TYPE.REWARDS] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_JiFen.png",
}

local tRMBPayFrame = {"ui/Image/Common/Money.UITex", 28}

g_tExteriorTimeType = {COIN_SHOP_TIME_LIMIT_TYPE.SEVEN_DAYS_LIMIT, COIN_SHOP_TIME_LIMIT_TYPE.PERMANENT, COIN_SHOP_TIME_LIMIT_TYPE.DEAD_LINE}
g_tExteriorPayType = {COIN_SHOP_PAY_TYPE.MONEY, COIN_SHOP_PAY_TYPE.REWARDS, COIN_SHOP_PAY_TYPE.COIN}

tRoleFileSuffix =
{
    [ROLE_TYPE.STANDARD_MALE]   = "m2",
    [ROLE_TYPE.STANDARD_FEMALE] = "f2",
    [ROLE_TYPE.LITTLE_BOY]      = "m1",
    [ROLE_TYPE.LITTLE_GIRL]     = "f1",
}

ACCOUNT_ITEM_STATUS =
{
    NORMAL = 1,
    HAVE = 2,
    DELETE = 3,
    SHOPPING_CAR = 4,
    SAVE = 5,
    CAN_NOT_SAVE = 6,
    OFF = 7,
    TIME_OPERATE = 8,
    SAVE_ONLY = 9, -- just vip or super vip can renew
    NOT_AUTHORITY = 10, -- just vip or super vip can buy
    OTHER_SAVE = 11,
}

local WEAPON_EXTERIOR_SRC_MAX_COUNT = 6

local tRewardsArray = {}

local tWeaponArray = {}
local tWeaponSrc = {}
local tExteriorSrc = {}
local tReHairIndex = {}
local tMixList = {}

local function LoadRewardsShop()
    tRewardsArray = {}
    local nCount = g_tTable.RewardsShop:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.RewardsShop:GetRow(i)

        table.insert(tRewardsArray, tLine)
    end
end

local function RegisterRewardsShopTable()
    local hPlayer = g_pClientPlayer
    if not hPlayer then
        return
    end

    if not IsUITableRegister("RewardsShop") then
        RegisterUITable("RewardsShop", g_tRewardsShop.Path, g_tRewardsShop.Title)
    end

    if not IsUITableRegister("RewardsCamera") then
        RegisterUITable("RewardsCamera", g_tRewardsCamera.Path, g_tRewardsCamera.Title, g_tRewardsCamera.KeyNum)
    end

    LoadRewardsShop()
end
--Event.Reg(CoinShopBase, "FIRST_LOADING_END", RegisterRewardsShopTable)

function CoinShop_GeRewardsShopArray()
    return tRewardsArray
end

function CoinShop_ParseRewardInfo(tLine)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local tRewardCamera = TabHelper.GetUIRewardsCameraTab(tLine.nCameraID, hPlayer.nRoleType)
    --local tRewardCamera = g_tTable.RewardsCamera:Search(tLine.nCameraID, hPlayer.nRoleType)
    CoinShop_ParseCameraInfo(tRewardCamera, tLine)
    local szKey = "szAnimation" .. tRoleFileSuffix[hPlayer.nRoleType]
    tLine.szAnimation = tLine[szKey]
    tLine.szInitPosition = tRewardCamera.szInitPosition
end

function CoinShop_ParseCameraPoint(tLine, tInfo, szXYZ)
    tInfo = tInfo or {}
    local tPoint = StringParse_PointList(tLine[szXYZ] or "0;0;0")
    for _, nPoint in ipairs(tPoint) do
        table.insert(tInfo, nPoint)
    end
    return tInfo
end

function CoinShop_ParseCameraInfo(tLine, tResult)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    tResult = tResult or tLine
    local tCameraInfo = {}

    tCameraInfo.szType = tLine.szCameraType
    tCameraInfo.tbIDs = {}
    tCameraInfo.tbIDs[hPlayer.nRoleType] = tLine.nCameraIndex
    tCameraInfo.tbOffset = {}
    tCameraInfo.tbOffset = CoinShop_ParseCameraPoint(tLine, tCameraInfo.tbOffset, "szOffset")

    tCameraInfo.fRoleYaw = tLine.fYaw

    tResult.tCameraInfo = tCameraInfo
    tResult.szInitPosition = tLine.szInitPosition
end

function Table_GetRewardsItem(dwLogicID)
	local tLine = g_tTable.RewardsShop:LinearSearch({dwLogicID = dwLogicID})
    if tLine then
        CoinShop_ParseRewardInfo(tLine)
        return tLine
	end
end

function Table_GetRewardsGoodID(dwTabType, dwIndex)
	local tLine = g_tTable.RewardsShop:LinearSearch({dwTabType = dwTabType, dwIndex = dwIndex})
	if tLine then
		return tLine.dwLogicID
	end
end

function Table_GetRewardsPetGoodID(nPetIndex)
	local tLine = g_tTable.RewardsShop:LinearSearch({nPetIndex = nPetIndex})
	if tLine then
		return tLine.dwLogicID
	end
end

function Table_GetRewardsGoodItem(dwTabType, dwIndex)
	local tLine = g_tTable.RewardsShop:LinearSearch({dwTabType = dwTabType, dwIndex = dwIndex})
	if tLine then
		return tLine
	end
end

function Table_GetWeaponJump()
    local dwKungFuID = Kungfu_GetPlayerMountType()
    if not dwKungFuID then
        return
    end
    local tLine = g_tTable.KungfuWeaponJump:Search(dwKungFuID)
	if tLine then
    	return tLine.nWeaponID
	end
end

local function LoadReHeadIndex()
    tReHairIndex = {}
    local nCount = g_tTable.ReHeadIndex:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.ReHeadIndex:GetRow(i)

        table.insert(tReHairIndex, tLine)
    end
end

function CoinShop_GetReHairIndex()
    return tReHairIndex
end

local function RegisterHairShopTable()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    -- 头发是根据客户端角色类型来的
    local szHairPath = g_tHairTable.Path .. "hairshop_" .. tRoleFileSuffix[hPlayer.nRoleType] ..  ".txt"
    ReplaceUITable("Hair", szHairPath, g_tHairTable.Title)

    if not IsUITableRegister("HeadHair") then
        RegisterUITable("HeadHair", g_tHeadHairTable.Path, g_tHeadHairTable.Title)
        RegisterUITable("ReHeadIndex", g_tReHeadIndex.Path, g_tReHeadIndex.Title, g_tReHeadIndex.KeyNum)
    end

    LoadReHeadIndex()
end
--Event.Reg(CoinShopBase, "FIRST_LOADING_END", RegisterHairShopTable)

local function RegisterCoinshopTitleTable()
    if not IsUITableRegister("CoinShop_Title") then
        RegisterUITable("CoinShop_Title", g_tCoinShop_Title.Path, g_tCoinShop_Title.Title)
    end
end
--Event.Reg(CoinShopBase, "FIRST_LOADING_END", RegisterCoinshopTitleTable)

function CoinShop_GetTitleInfo(nType, nClass)
    if not nClass then
        nClass = 0
    end
    local tLine = g_tTable.CoinShop_Title:LinearSearch({nType = nType, nRewardsClass = nClass})
    return tLine
end

local function LoadWeapon()
    tWeaponArray = {}
    local nCount = g_tTable.CoinShop_Weapon:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.CoinShop_Weapon:GetRow(i)

        table.insert(tWeaponArray, tLine)
    end
end

function CoinShop_GetWeaponInfo(dwID)
    local tLine = g_tTable.CoinShop_Weapon:Search(dwID)
    return tLine
end

function CoinShop_GetWeaponArray()
    return tWeaponArray
end

local function RegisterCoinshopWeaponTable()
    if not IsUITableRegister("CoinShop_Weapon") then
        RegisterUITable("CoinShop_Weapon", g_tCoinShop_Weapon.Path, g_tCoinShop_Weapon.Title)
    end

    LoadWeapon()
end
--Event.Reg(CoinShopBase, "FIRST_LOADING_END", RegisterCoinshopWeaponTable)



local function LoadWeaponSrc()
    tWeaponSrc = {}
    local nCount = g_tTable.CoinShop_WeaponSrc:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.CoinShop_WeaponSrc:GetRow(i)
        if not tWeaponSrc[tLine.dwWeaponID] then
            tWeaponSrc[tLine.dwWeaponID] = {}
        end
        local tSrc = tWeaponSrc[tLine.dwWeaponID]
        if #tSrc < WEAPON_EXTERIOR_SRC_MAX_COUNT then
            table.insert(tSrc, tLine)
        end
    end
end

local function RegisterCoinshopWeaponSrc()
    if not IsUITableRegister("CoinShop_WeaponSrc") then
        RegisterUITable("CoinShop_WeaponSrc", g_tCoinShop_WeaponSrc.Path, g_tCoinShop_WeaponSrc.Title)
    end

    LoadWeaponSrc()
end

function CoinShop_GetWeaponScr(dwWeaponID)
    local tSrc =  tWeaponSrc[dwWeaponID] or {}
    return tSrc
end

--Event.Reg(CoinShopBase, "FIRST_LOADING_END", RegisterCoinshopWeaponSrc)

local function LoadExteriorSrc()
    tExteriorSrc = {}
    local nCount = g_tTable.CoinShop_ExteriorSrc:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.CoinShop_ExteriorSrc:GetRow(i)
        if not tExteriorSrc[tLine.dwExteriorID] then
            tExteriorSrc[tLine.dwExteriorID] = {}
        end
        local tSrc = tExteriorSrc[tLine.dwExteriorID]
        if #tSrc < WEAPON_EXTERIOR_SRC_MAX_COUNT then
            table.insert(tSrc, tLine)
        end
    end
end

local function RegisterCoinshopExteriorSrc()
    if not IsUITableRegister("CoinShop_ExteriorSrc") then
        RegisterUITable("CoinShop_ExteriorSrc", g_tCoinShop_ExteriorSrc.Path, g_tCoinShop_ExteriorSrc.Title)
    end
    LoadExteriorSrc()
end

function CoinShop_GetExteriorScr(dwExteriorID)
    local tSrc =  tExteriorSrc[dwExteriorID] or {}
    return tSrc
end

--Event.Reg(CoinShopBase, "FIRST_LOADING_END", RegisterCoinshopExteriorSrc)
--Event.Reg(CoinShopBase, "FIRST_LOADING_END", LoadExteriorMap)



--只获取预览的
local function CoinShop_GetRewardsLimitView(nID)
    local tItems = {}
    local nCount = g_tTable.Rewards_LimitView:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.Rewards_LimitView:GetRow(i)
        if tLine.nID == nID and tLine.bPreview then
            table.insert(tItems, tLine)
        end
    end

    return tItems
end

function CoinShop_GetLimitView(nID) --先看看是不是多选一的,再看普通盒子的
    return CoinShop_GetLimitViewPack(nID) or CoinShop_GetRewardsLimitView(nID)
end

function CoinShop_GetAllLimitViewPack(nID)
    local tItems = {}
    local nCount = g_tTable.Rewards_LimitItemViewPack:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.Rewards_LimitItemViewPack:GetRow(i)
        if tLine.nID == nID then
            table.insert(tItems, tLine)
        end
    end

    return tItems
end

--只获取多选一预览的
function CoinShop_GetLimitViewPack(nID)
    local nCount = g_tTable.Rewards_LimitItemViewPack:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.Rewards_LimitItemViewPack:GetRow(i)
        if tLine.nID == nID and tLine.bPreview then
            local hItemInfo = GetItemInfo(ITEM_TABLE_TYPE.OTHER, tLine.dwIndex)
            return CoinShop_GetRewardsLimitView(hItemInfo.nDetail)
        end
    end

    return nil
end

--获取盒子里所有的
function CoinShop_GetAllLimitView(nID)
    local tItems = {}
    local nCount = g_tTable.Rewards_LimitView:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.Rewards_LimitView:GetRow(i)
        if tLine.nID == nID then
            table.insert(tItems, tLine)
        end
    end

    return tItems
end

function CoinShop_IsInViewPack(nLogicID)
    local tItem = ExteriorCharacter.GetViewItemPreview()
    if tItem then
        local tItemInfo = GetItemInfo(tItem.dwTabType, tItem.dwIndex)
         local nID = tItemInfo.nDetail
        return CoinShop_IsInLimitView(nID, nLogicID) or CoinShop_IsInLimitViewPack(nID, nLogicID)
    end
end

--判断某个商品是否在盒子里
function CoinShop_IsInLimitView(nID, nLogicID)
    local tItems = {}
    local nCount = g_tTable.Rewards_LimitView:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.Rewards_LimitView:GetRow(i)
        if tLine.nID == nID and nLogicID == tLine.dwLogicID then
            return true
        end
    end

    return false
end

--判断某个商品是否在多选一盒子里
function CoinShop_IsInLimitViewPack(nID, nLogicID)
    local tItems = {}
    local nCount = g_tTable.Rewards_LimitItemViewPack:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.Rewards_LimitItemViewPack:GetRow(i)
        if tLine.nID == nID then
            local hItemInfo = GetItemInfo(ITEM_TABLE_TYPE.OTHER, tLine.dwIndex)
            local bIn = CoinShop_IsInLimitView(hItemInfo.nDetail, nLogicID)
            if bIn then
                return true
            end
        end
    end

    return false
end

--获取限量商品的所有视频
function CoinShop_GetAllLimitVideo(dwGoodsID)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local tItems = {}
    local nCount = g_tTable.Rewards_LimitVideo:GetRowCount()
    local nRoleType = hPlayer.nRoleType
    for i = 2, nCount do
        local tLine = g_tTable.Rewards_LimitVideo:GetRow(i)
        if tLine.dwGoodsID == dwGoodsID and (tLine.nRoleType == 0 or tLine.nRoleType == nRoleType) then --nRoleType0表示所有体型通用
            table.insert(tItems, tLine)
        end
    end

    return tItems
end

--获取限量商品的协议动画
function CoinShop_GetLimitItemStoryDisplay(dwGoodsID)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local nCount = g_tTable.Rewards_LimitVideo:GetRowCount()
    local nRoleType = hPlayer.nRoleType
    for i = 2, nCount do
        local tLine = g_tTable.Rewards_LimitVideo:GetRow(i)
        if tLine.dwGoodsID == dwGoodsID and (tLine.nRoleType == 0 or tLine.nRoleType == nRoleType) and tLine.nStoryID ~= 0 then --nRoleType0表示所有体型通用
            return tLine
        end
    end
end

local function RegisterCoinshopLimitTable()
    if not IsUITableRegister("Rewards_LimitView") then
        RegisterUITable("Rewards_LimitView", g_tRewardsLimitView.Path, g_tRewardsLimitView.Title)
    end

    if not IsUITableRegister("Rewards_LimitItemViewPack") then
        RegisterUITable("Rewards_LimitItemViewPack", g_tRewardsLimitItemViewPack.Path, g_tRewardsLimitItemViewPack.Title)
    end

    if not IsUITableRegister("Rewards_LimitVideo") then
        RegisterUITable("Rewards_LimitVideo", g_tRewardsLimitVideo.Path, g_tRewardsLimitVideo.Title)
    end
end

--Event.Reg(CoinShopBase, "FIRST_LOADING_END", RegisterCoinshopLimitTable)



function CoinShop_CloakColor(dwItemType, dwItemIndex)
    local tColorList = {}
    local nCount = g_tTable.CloakColorChange:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.CloakColorChange:GetRow(i)
        if tLine.dwItemType == dwItemType and tLine.dwItemIndex == dwItemIndex then
            if not tColorList[tLine.nBlock] then
                tColorList[tLine.nBlock] = {}
            end
            table.insert(tColorList[tLine.nBlock], {tLine.nA, tLine.nR, tLine.nG, tLine.nB})
        end
    end

    return tColorList
end

function CoinShop_GetCloakColorByPendantID(dwPendantID)
    local tColorList = {}
    local nCount = g_tTable.CloakColorChange:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.CloakColorChange:GetRow(i)
        if tLine.dwPendantID == dwPendantID then
            if not tColorList[tLine.nBlock] then
                tColorList[tLine.nBlock] = {}
            end
            table.insert(tColorList[tLine.nBlock], {tLine.nA, tLine.nR, tLine.nG, tLine.nB})
        end
    end

    return tColorList
end

local function RegisterCloakColorChangeTable()
    if not IsUITableRegister("CloakColorChange") then
        RegisterUITable("CloakColorChange", g_tCloakColorChange.Path, g_tCloakColorChange.Title)
    end
end
--Event.Reg(CoinShopBase, "FIRST_LOADING_END", RegisterCloakColorChangeTable)


local function IsTimeOk(nStartTime, nEndTime)
    local nTime = GetGSCurrentTime()
    return (nStartTime == -1 or nTime >= nStartTime) and
            (nEndTime == -1 or nTime <= nEndTime)
end

local function AddTimeZone(tLine)
    local nTimezone = GetTimezone()
    if tLine.nStartTime ~= -1 then
        tLine.nStartTime = tLine.nStartTime + nTimezone
    end

    if tLine.nEndTime ~= -1 then
        tLine.nEndTime = tLine.nEndTime + nTimezone
    end

    if tLine.nEndActiveOpenTime and tLine.nEndActiveOpenTime ~= -1 then
        tLine.nEndActiveOpenTime = tLine.nEndActiveOpenTime + nTimezone
    end
end


function CoinShop_GetHomeList(nMax)
    local tList = {}

    local nCount = g_tTable.CoinShop_Home:GetRowCount()
    if nMax and nMax > 0 then
        nCount = math.min(nCount, nMax)
    end
    for i = 2, nCount do
        local tLine = g_tTable.CoinShop_Home:GetRow(i)
        if tLine.dwForceID == 0 or tLine.dwForceID == g_pClientPlayer.dwForceID then
            local dwGoodsID = tLine.dwGoodsID
            local eGoodsType = tLine.eGoodsType
            local bCanBuy = CoinShop_GoodsShow(eGoodsType, dwGoodsID)
            if bCanBuy then
                table.insert(tList, tLine)
            end
        end
    end
    return tList
end

local function GetHomeItem(eGoodsType, dwGoodsID)
    local nCount = g_tTable.CoinShop_Home:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.CoinShop_Home:GetRow(i)
        if tLine.eGoodsType == eGoodsType and tLine.dwGoodsID == dwGoodsID then
            return tLine
        end
    end
end

function CoinShop_GetGoodsBG(tGoods)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local szKey = "szBg" .. tRoleFileSuffix[hPlayer.nRoleType]
    local tInfo = tGoods
    if not tGoods[szKey] then

        tInfo = GetHomeItem(tGoods.eGoodsType, tGoods.dwGoodsID)
        if not tInfo then
            UILog("在\\UI\\Scheme\\Case\\CoinShopHome\\CoinShop_Home.tab 表里没有找到 ID = " .. tGoods.dwGoodsID .. "的图！请联系中迪或者二黄！")
            return ""
        end
    end
    local szBgPath = tInfo[szKey]
    if szBgPath == "" then
        szBgPath = tInfo.szBgPath
    end
    return szBgPath
end

local function RegisterCoinShopHomeTable()
    if not IsUITableRegister("CoinShop_Home") then
        RegisterUITable("CoinShop_Home", g_tCoinShopHome.Path, g_tCoinShopHome.Title)
    end
end
--Event.Reg(CoinShopBase, "FIRST_LOADING_END", RegisterCoinShopHomeTable)




function CoinShop_GetMix(nMixID)
    return tMixList[nMixID]
end

local function LoadMixList()
    local tList = {}
    local tMap = {}
    local nCount = g_tTable.CoinShop_Mix:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.CoinShop_Mix:GetRow(i)
        if not tMap[tLine.nID] then
            table.insert(tList, {szName = tLine.szName, tSet = {}})
            tMap[tLine.nID] = tList[#tList]
        end
        local tClass = tMap[tLine.nID]
        table.insert(tClass.tSet, tLine)
    end
    tMixList = tList
end

local function RegisterCoinShopMixTable()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local szPath = g_tCoinShopMix.Path .. "_" .. tRoleFileSuffix[hPlayer.nRoleType] ..  ".tab"
    if not IsUITableRegister("CoinShop_Mix") then
        RegisterUITable("CoinShop_Mix", szPath, g_tCoinShopMix.Title)
    end

    LoadMixList()
end
--Event.Reg(CoinShopBase, "FIRST_LOADING_END", RegisterCoinShopMixTable)




-- function CoinShop_GetTopics(nID)
--     local tTopics = {}
--     local nCount = g_tTable.CoinShop_Topics:GetRowCount()
--     for i = 2, nCount do
--         local tLine = g_tTable.CoinShop_Topics:GetRow(i)
--         if nID == tLine.nID then
--             if tLine.nSubID == 0 then
--                 tTopics = {szName = tLine.szName, szBgPath = tLine.szBgPath, tList = {}}
--             else
--                 AddTimeZone(tLine)
--                 if IsTimeOk(tLine.nStartTime, tLine.nEndTime) then
--                     table.insert(tTopics.tList, tLine)
--                 end
--             end
--         end
--     end

--     return tTopics
-- end

-- local function RegisterCoinShopTopicsTable()
--     if not IsUITableRegister("CoinShop_Topics") then
--         RegisterUITable("CoinShop_Topics", g_tCoinShopTopics.Path, g_tCoinShopTopics.Title)
--     end
-- end
--Event.Reg(CoinShopBase, "FIRST_LOADING_END", RegisterCoinShopTopicsTable)



function CoinShop_GetRankList()
    local tRankList = {}
    local tClassMap = {}
    local nCount = g_tTable.CoinShop_Rank:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.CoinShop_Rank:GetRow(i)
        if not tClassMap[tLine.nClass] then
            table.insert(tRankList, {szName = tLine.szName, szBgPath = tLine.szBgPath, tList = {}})
            tClassMap[tLine.nClass] = tRankList[#tRankList]
        else
            local tClass = tClassMap[tLine.nClass]
            AddTimeZone(tLine)
            if IsTimeOk(tLine.nStartTime, tLine.nEndTime) then
                table.insert(tClass.tList, tLine)
            end
        end
    end

    return tRankList
end

local function RegisterCoinShopRankTable()
    if not IsUITableRegister("CoinShop_Rank") then
        RegisterUITable("CoinShop_Rank", g_tCoinShopRank.Path, g_tCoinShopRank.Title)
    end
end
--Event.Reg(CoinShopBase, "FIRST_LOADING_END", RegisterCoinShopRankTable)



function CoinShop_GetFaceLiftFile(nID)
    local tLine = g_tTable.CoinShop_FaceLiftIndex:Search(nID)
    if not tLine then
        return
    end
    return tLine.szFile
end

local function RegisterCoinShopFaceLiftIndexTable()
    if not IsUITableRegister("CoinShop_FaceLiftIndex") then
        RegisterUITable("CoinShop_FaceLiftIndex", g_tFaceLiftIndex.Path, g_tFaceLiftIndex.Title)
    end
end
--Event.Reg(CoinShopBase, "FIRST_LOADING_END", RegisterCoinShopFaceLiftIndexTable)


local tAdornmentMap = {}
local tAdornmentArray = {}



function CoinShop_GetAdornmentSetID(dwItemIndex)
    return tAdornmentMap[dwItemIndex]
end

function CoinShop_GetAdornmentSetName(nSetID)
    local szName =  ""
    if tAdornmentArray[nSetID] then
        szName = tAdornmentArray[nSetID].szName
    end

    return szName
end

function CoinShop_GetAdornmentSet(nSetID)
    return tAdornmentArray[nSetID]
end

function CoinShop_GetAllAdornmentSet()
    return tAdornmentArray
end

local function LoadHorseAdornment()
    tAdornmentArray = {}
    tAdornmentMap = {}
    local nCount = g_tTable.CoinShop_HorseAdornment:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.CoinShop_HorseAdornment:GetRow(i)
        if not tAdornmentArray[tLine.nSetID] then
            tAdornmentArray[tLine.nSetID] = {szName = tLine.szSetName, tList = {}}
        end
        local tSet = tAdornmentArray[tLine.nSetID]
        table.insert(tSet.tList, tLine)
        tAdornmentMap[tLine.dwItemIndex] = tLine.nSetID
    end
end

local function RegisterHorseAdornmentIndexTable()
    if not IsUITableRegister("CoinShop_HorseAdornment") then
        RegisterUITable("CoinShop_HorseAdornment", g_tHorseAdornment.Path, g_tHorseAdornment.Title)
    end
    LoadHorseAdornment()
end
--Event.Reg(CoinShopBase, "FIRST_LOADING_END", RegisterHorseAdornmentIndexTable)

function CoinShop_GetRewardSetID(nClass, dwItemIndex)
    local tLine = g_tTable.CoinShop_RewardSet:Search(nClass, dwItemIndex)
    return tLine
end

function CoinShop_GetViewLight(szType)
    local tLightList = {}
    local nCount = g_tTable.CoinShop_ViewLight:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.CoinShop_ViewLight:GetRow(i)
        if szType == tLine.szType then
            table.insert(tLightList, tLine)
        end
    end

    return tLightList
end

function CoinShop_GetViewLightByID(dwID)
    local tLine = g_tTable.CoinShop_ViewLight:Search(dwID)
    return tLine
end

local function RegisterViewLightTable()
    if not IsUITableRegister("CoinShop_ViewLight") then
        RegisterUITable("CoinShop_ViewLight", g_tViewLight.Path, g_tViewLight.Title)
    end
end

--Event.Reg(CoinShopBase, "FIRST_LOADING_END", RegisterViewLightTable)



function CoinShop_GetPreOrder(dwPreOrderID)
    local tLine = g_tTable.CoinShop_PreOrder:Search(dwPreOrderID)

    return tLine
end

local function RegisterPreOrderTable()
    if not IsUITableRegister("CoinShop_PreOrder") then
        RegisterUITable("CoinShop_PreOrder", g_tPreOrder.Path, g_tPreOrder.Title)
    end
end

--Event.Reg(CoinShopBase, "FIRST_LOADING_END", RegisterPreOrderTable)



function CoinShop_GetPendantPetCamera(dwID)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local tLine = g_tTable.CoinShop_PendantPetCamera:Search(dwID, hPlayer.nRoleType)
    return tLine
end

function CoinShop_GetPendantPetByItem(dwIndex)
    -- local hItemInfo = GetItemInfo(dwTabType, dwIndex)
    -- local dwID = dwIndex
    -- if not IsPendantPetItem(hItemInfo) then
    --     dwID = hItemInfo.nDetail
    -- end
    return CoinShop_GetPendantPetInfo(dwIndex)
end

function CoinShop_GetPendantPetInfo(dwID)
    local tInfo = {}
    local nCount = g_tTable.CoinShop_PendantPetPos:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.CoinShop_PendantPetPos:GetRow(i)
        if tLine.dwItemIndex == dwID then
            local tParam = CoinShop_GetPendantPetCamera(tLine.dwCameraparam)
            CoinShop_ParseCameraInfo(tParam, tLine)
            table.insert(tInfo, tLine)
        end
    end

    local tAttr = {}
    local nCount = g_tTable.CoinShop_PendantPetAttr:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.CoinShop_PendantPetAttr:GetRow(i)
        if tLine.dwItemIndex == dwID then
            table.insert(tAttr, tLine)
        end
    end

    return tInfo, tAttr
end

local function RegisterPendantPetTable()
    if not IsUITableRegister("CoinShop_PendantPetPos") then
        RegisterUITable("CoinShop_PendantPetPos", g_tPendantPetPos.Path, g_tPendantPetPos.Title)
    end

    if not IsUITableRegister("CoinShop_PendantPetCamera") then
        RegisterUITable("CoinShop_PendantPetCamera", g_tPendantPetCamera.Path, g_tPendantPetCamera.Title)
    end

     if not IsUITableRegister("CoinShop_PendantPetAttr") then
        RegisterUITable("CoinShop_PendantPetAttr", g_tPendantPetAttrubute.Path, g_tPendantPetAttrubute.Title)
    end
end

--Event.Reg(CoinShopBase, "FIRST_LOADING_END", RegisterPendantPetTable)



local function RegisterFurnitureShopInfo()
    if not IsUITableRegister("FurnitureShopInfo") then
        RegisterUITable("FurnitureShopInfo", g_tFurnitureShopInfo.Path, g_tFurnitureShopInfo.Title)
    end
    if not IsUITableRegister("RewardFurnitureCatg") then
        RegisterUITable("RewardFurnitureCatg", g_tRewardFurnitureCatg.Path, g_tRewardFurnitureCatg.Title)
    end
end

--Event.Reg(CoinShopBase, "FIRST_LOADING_END", RegisterFurnitureShopInfo)




local function RegisterCoinShopNewsTable()
    if not IsUITableRegister("CoinShop_News") then
        RegisterUITable("CoinShop_News", g_tCoinShopNews.Path, g_tCoinShopNews.Title)
    end
end
--Event.Reg(CoinShopBase, "FIRST_LOADING_END", RegisterCoinShopNewsTable)

function CoinShop_GetNewsList()
    local tList = {}
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local nRoleType = hPlayer.nRoleType
    local nCount = g_tTable.CoinShop_News:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.CoinShop_News:GetRow(i)
        if tLine.nRoleType == 0 or tLine.nRoleType == nRoleType then
            AddTimeZone(tLine)
            if IsTimeOk(tLine.nStartTime, tLine.nEndTime) then
                table.insert(tList, tLine)
            end
        end
    end
    return tList
end

function CoinShop_IsActiveOpenNews()
    local tList = {}

    local nCount = g_tTable.CoinShop_News:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.CoinShop_News:GetRow(i)
        AddTimeZone(tLine)
        if IsTimeOk(tLine.nStartTime, tLine.nEndTime) and IsTimeOk(-1, tLine.nEndActiveOpenTime) then
            return true
        end
    end
    return false
end

local function RegisterCoinShopHomeSetTable()
    if not IsUITableRegister("CoinShopHome_Fold") then
        local tCoinShopSet = g_tCoinShopHome_Fold
        RegisterUITable("CoinShopHome_Fold", tCoinShopSet.Path, tCoinShopSet.Title)
    end
end

function CoinShop_GetHomeFoldInfoByID(nFoldID)
    local tLine = g_tTable.CoinShopHome_Fold:Search(nFoldID)
    return tLine
end

function CoinShop_GetHomeFoldInfoByGoods(eGoodsType, dwGoodsID)
    local nCount = g_tTable.CoinShop_Home:GetRowCount()
    local nFoldID
    for i = 2, nCount do
        local tLine = g_tTable.CoinShop_Home:GetRow(i)
        if tLine.eGoodsType == eGoodsType and tLine.dwGoodsID == dwGoodsID then
            nFoldID = tLine.nFoldID
        end
    end
    if not nFoldID or nFoldID == 0 then
        return
    end
    return CoinShop_GetHomeFoldInfoByID(nFoldID)
end

function CoinShop_GetFurnitureShopInfo(dwID)
    local tLine = g_tTable.FurnitureShopInfo:Search(dwID)

    return tLine
end

function CoinShop_GetSrc(eGoodsType, dwGoodsID)
    if eGoodsType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
        return CoinShop_GetWeaponScr(dwGoodsID)
    else
        return CoinShop_GetExteriorScr(dwGoodsID)
    end
end


local function RegisterCoinShopHairSubsetTable()
    if not IsUITableRegister("CoinShopHair_Subset") then
        local tCoinShopSet = g_tCoinShopHair_Subset
        RegisterUITable("CoinShopHair_Subset", tCoinShopSet.Path, tCoinShopSet.Title)
    end
end
RegisterEvent("FIRST_LOADING_END", RegisterCoinShopHairSubsetTable)

local function RegisterCoinShopExteriorSubsetTable()
    if not IsUITableRegister("CoinShopExterior_Subset") then
        local tCoinShopSet = g_tCoinShopExterior_Subset
        RegisterUITable("CoinShopExterior_Subset", tCoinShopSet.Path, tCoinShopSet.Title)
    end
end
RegisterEvent("FIRST_LOADING_END", RegisterCoinShopExteriorSubsetTable)

function CoinShop_GetHairSubsetInfo(nCount)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local nRoleType = Player_GetRoleType(hPlayer)

    local tLine = g_tTable.CoinShopHair_Subset:Search(nRoleType, nCount)
    if not tLine then
        return g_tTable.CoinShopHair_Subset:Search(0, 0)
    end

    return tLine
end

function CoinShop_GetExteriorSubsetInfo(nCount)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local nRoleType = Player_GetRoleType(hPlayer)

    local tLine = g_tTable.CoinShopExterior_Subset:Search(nRoleType, nCount)
    if not tLine then
        return g_tTable.CoinShopExterior_Subset:Search(0, 0)
    end

    return tLine
end

--只获取预览的
local function CoinShop_GetRewardsLimitView(nID)
    local tItems = {}
    local nCount = g_tTable.Rewards_LimitView:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.Rewards_LimitView:GetRow(i)
        if tLine.nID == nID and tLine.bPreview then
            table.insert(tItems, tLine)
        end
    end

    return tItems
end

local function CalculateDiscount(nDiscount, bSecondDis, nSecondDiscount)
    if bSecondDis then
        nDiscount = math.ceil(nSecondDiscount * nDiscount / 100)
    end

    return nDiscount
end

local function IsDis(nDiscount, nDisStartTime, nDisEndTime)
    local nCurrentTime = GetGSCurrentTime()
    if nDiscount >= GLOBAL.COIN_PRICE_DISCOUNT_BASE then
        return false
    end
    local bDis = (nDisStartTime == -1 or nCurrentTime >= nDisStartTime) and
                (nDisEndTime == -1 or nCurrentTime <= nDisEndTime)
    return bDis
end

local function IsSecondDis(tInfo, eGoodsType, dwGoodsID)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return false
    end

    if not tInfo.nSecondDiscount or tInfo.nSecondDiscount >= GLOBAL.COIN_PRICE_DISCOUNT_BASE or not eGoodsType or not dwGoodsID then
        return false
    end

    local bDis = hPlayer.CanDiscountForSecondRewardsGoods(dwGoodsID)
    return bDis
end

local function IsShowSecondDis(tInfo, eGoodsType, dwGoodsID)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return false
    end
    if not tInfo.nSecondDiscount or not eGoodsType or not dwGoodsID then
        return false
    end
    local nBuyCount = 0
    if tInfo.dwSecondDisFatherID ~= 0 then
        nBuyCount = hPlayer.GetCoinShopBuyCount(eGoodsType, tInfo.dwSecondDisFatherID)
    else
        nBuyCount = hPlayer.GetCoinShopBuyCount(eGoodsType, dwGoodsID)
    end
    if nBuyCount >= 2 then
        return false
    end

    local bDis = IsDis(tInfo.nSecondDiscount, -1, tInfo.nSecondDisEndTime)
    return bDis
end

local function GetPriceInfo(tExteriorInfo, eGoodsType, dwGoodsID)
    eGoodsType = tExteriorInfo.eGoodsType or eGoodsType
    dwGoodsID = tExteriorInfo.dwID or dwGoodsID
    local tPriceInfo = {}
    for _, nTimeType in ipairs(g_tExteriorTimeType) do
        for _, nPayType in ipairs(g_tExteriorPayType) do
            local tThePrice = tExteriorInfo.tPrice[nPayType][nTimeType]
            local nPrice = tThePrice.nPrice
            if nPrice >= 0 then
                local tOnePrice = {}
                local szText = ""
                if nTimeType == COIN_SHOP_TIME_LIMIT_TYPE.DEAD_LINE then
                    local nEndTime = tExteriorInfo.nLimitTime
                    local nTime = GetGSCurrentTime()
                    local nLeftTime = BigIntSub(nEndTime, nTime)
                    if nLeftTime < 0 then
                        nLeftTime = 0
                    end
                    szText = GetTimeText(nLeftTime, nil, true)
                    tOnePrice.nLeftTime = nLeftTime

                    local tTime = TimeToDate(nEndTime)
                    local szTimeTip = string.format("%d.%2d.%2d", tTime.year, tTime.month, tTime.day)
                    tOnePrice.szTimeTip = szTimeTip
                else
                    szText = g_tStrings.tExteriorTimeType[nTimeType]
                end


                tOnePrice.nPrice = nPrice
                tOnePrice.szImagePath = g_tExteriorPayTypeImg[nPayType]
               -- tOnePrice.nFrame = g_tExteriorPayTypeImg[nPayType][2]
                tOnePrice.szPriceDesc = szText
                tOnePrice.nTimeType = nTimeType
                tOnePrice.nPayType = nPayType
                tOnePrice.nDisStartTime = tThePrice.nDisStartTime
                tOnePrice.nDisEndTime = tThePrice.nDisEndTime
                tOnePrice.nDiscount = GLOBAL.COIN_PRICE_DISCOUNT_BASE

                local bDis, bSecondDis = CoinShop_IsDis(tThePrice, eGoodsType, dwGoodsID)
                tOnePrice.bDis = bDis
                tOnePrice.nDisPrice = nPrice
                tOnePrice.bSecondDis = bSecondDis
                tOnePrice.nAskPayPrice = nPrice
                if bDis then
                    local nDiscount = CalculateDiscount(tThePrice.nDiscount, bSecondDis, tThePrice.nSecondDiscount)
                    tOnePrice.nDiscount = nDiscount
                    local nDisPrice = CoinShop_GetDisPrice(nPrice, nDiscount)
                    tOnePrice.nDisPrice = nDisPrice
                    local bDis1 = IsDis(tThePrice.nDiscount, tThePrice.nDisStartTime, tThePrice.nDisEndTime)
                    if bDis1 then
                        tOnePrice.nAskPayPrice = CoinShop_GetDisPrice(nPrice, tThePrice.nDiscount)
                    end
                end
                if tExteriorInfo.bIsReal then
                    tOnePrice.nShowPrice = math.floor(nPrice / 100)
                    tOnePrice.nShowDisPrice = math.floor(tOnePrice.nDisPrice / 100)
                    tOnePrice.szImagePath = tRMBPayFrame[1]
                    tOnePrice.nFrame = tRMBPayFrame[2]
                end
                table.insert(tPriceInfo, tOnePrice)
            end
        end
    end

    local bHave = false
    if eGoodsType and dwGoodsID then
        nOwnType = GetCoinShopClient().CheckAlreadyHave(eGoodsType, dwGoodsID)
        if nOwnType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE and
            nOwnType ~= COIN_SHOP_OWN_TYPE.INVALID
        then
            bHave = true
        end
    end

    local bFreeTryOn = CoinShop_CanFreeTryOn(tExteriorInfo)
    if bFreeTryOn and not bHave then
        local tFreePrice = {}
        tFreePrice.nPrice = 0
        tFreePrice.szPriceDesc = g_tStrings.EXTERIOR_FREE_TRY_ON
        tFreePrice.nTimeType = COIN_SHOP_TIME_LIMIT_TYPE.FREE_TRY_ON
        tFreePrice.nPayType = COIN_SHOP_PAY_TYPE.FREE_TRY_ON
        tFreePrice.bDis = false
        tFreePrice.nDisPrice = 0
        tFreePrice.nDiscount = GLOBAL.COIN_PRICE_DISCOUNT_BASE
        if #tPriceInfo == 1 then
            table.insert(tPriceInfo, 1, tFreePrice)
        else
            tPriceInfo[1] = tFreePrice
        end
    end
    return tPriceInfo
end

function CoinShop_CanFreeTryOn(tInfo)
    local bPlayerFreeTryOn = CoinShop_PlayerCanFreeTryOn()
    return bPlayerFreeTryOn and tInfo.bCanFreeTryOn
end

function CoinShop_PlayerCanFreeTryOn()
    local hCoinShopClient = GetCoinShopClient()
    if not hCoinShopClient then
        return
    end

    local nFreeTryOnEndTime = hCoinShopClient.GetFreeTryOnEndTime()
    local nCurrentTime = GetGSCurrentTime()
    return nCurrentTime < nFreeTryOnEndTime
end

function CoinShop_GetFreeTryOnTime()
    local hCoinShopClient = GetCoinShopClient()
    if not hCoinShopClient then
        return
    end

    local nFreeTryOnEndTime = hCoinShopClient.GetFreeTryOnEndTime()
    local nCurrentTime = GetGSCurrentTime()
    local nTime = math.max(nFreeTryOnEndTime - nCurrentTime, 0)
    local szTime = GetTimeText(nTime, false, true, false, false, nil, true)
    return szTime
end

function HairShop_GetPriceInfo(nType, nID, eGoodsType)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local hHairShopClient = GetHairShop()
    if not hHairShopClient then
        return
    end

    local tHairPrice = hHairShopClient.GetHairPrice(hPlayer.nRoleType, nType, nID)
    return GetPriceInfo(tHairPrice, eGoodsType, nID)
end

function HairShop_GetTime(nType, nID)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local hHairShopClient = GetHairShop()
    if not hHairShopClient then
        return
    end

    local tHairPrice = hHairShopClient.GetHairPrice(hPlayer.nRoleType, nType, nID)
    return CoinShop_GetTime(tHairPrice)
end

function CoinShop_GetRewardsPriceInfo(dwID)
    local hRewardsShop = GetRewardsShop()
    if not hRewardsShop then
        return
    end

    tExteriorInfo = hRewardsShop.GetRewardsShopInfo(dwID)

    return GetPriceInfo(tExteriorInfo, COIN_SHOP_GOODS_TYPE.ITEM, dwID)
end

function CoinShop_GetExteriorPriceInfo(dwID)
    local hExteriorClient = GetExterior()
    if not hExteriorClient then
        return
    end

    local tExteriorInfo = hExteriorClient.GetExteriorInfo(dwID)

    return GetPriceInfo(tExteriorInfo, COIN_SHOP_GOODS_TYPE.EXTERIOR, dwID)
end

function CoinShop_GetWeaponPriceInfo(dwID)
    local hExteriorClient = GetExterior()
    if not hExteriorClient then
        return
    end

    local tExteriorInfo = CoinShop_GetWeaponExteriorInfo(dwID, hExteriorClient)

    return GetPriceInfo(tExteriorInfo, COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR, dwID)
end

function CoinShop_GetWeaponExteriorInfo(dwID, hExteriorClient)
    if not hExteriorClient then
        hExteriorClient = GetExterior()
    end

    if not hExteriorClient then
        return
    end

    local hPlayer = GetClientPlayer()
    if hPlayer.dwForceID == FORCE_TYPE.CANG_JIAN then
        return hExteriorClient.GetWeaponExteriorInfoForCangjian(dwID)
    else
        return hExteriorClient.GetWeaponExteriorInfo(dwID)
    end
end

function CoinShop_GetExteriorTime(dwID)
    local hExteriorClient = GetExterior()
    if not hExteriorClient then
        return
    end

    local szTime = ""
    local tInfo = hExteriorClient.GetExteriorInfo(dwID)

    return CoinShop_GetTime(tInfo)
end

function CoinShop_GetRewardsTime(dwLogicID, bHeightest)
    local hRewardsShop = GetRewardsShop()
    if not hRewardsShop then
        return ""
    end
    local tInfo = hRewardsShop.GetRewardsShopInfo(dwLogicID)

    return CoinShop_GetTime(tInfo, bHeightest)
end

function CoinShop_GetWeaponTime(dwID)
    local hExteriorClient = GetExterior()
    if not hExteriorClient then
        return
    end

    local szTime = ""
    local tInfo = CoinShop_GetWeaponExteriorInfo(dwID, hExteriorClient)

    return CoinShop_GetTime(tInfo)
end

function CoinShop_GetTime(tInfo, bHeightest)
    local nTime = GetGSCurrentTime()
    local szTime = ""
    if tInfo.nEndTime ~= -1 and nTime <= tInfo.nEndTime then
        nTime = math.max(tInfo.nEndTime - nTime, 0)
        if bHeightest then
            szTime = UIHelper.GetHeightestTimeText(nTime)
        else
            szTime = TimeLib.GetTimeText(nTime, false, true, false, false, nil, true)
        end
    end
    return szTime
end

function CoinShop_IsTimeEnd(tInfo)
    local nTime = GetGSCurrentTime()
    local szTime = ""
    if tInfo.nEndTime ~= -1 and nTime > tInfo.nEndTime then
        return true
    end
    return false
end

function CoinShop_GetExteriorName(dwExteriorID)
    local hExteriorClient = GetExterior()
    if not hExteriorClient then
        return
    end

    local tExteriorInfo = hExteriorClient.GetExteriorInfo(dwExteriorID)
    local szGenre = Table_GetExteriorGenreName(tExteriorInfo.nGenre)
    local szName = Table_GetExteriorSetName(tExteriorInfo.nGenre, tExteriorInfo.nSet)
    szName = szName .. g_tStrings.STR_CONNECT_GBK .. g_tStrings.tExteriorSubNameGBK[tExteriorInfo.nSubType]
    return szGenre, szName
end

function CoinShop_GetDisText(tPrice, bSecondDis)
    local  nTime = GetGSCurrentTime()
    local szDisCount = ""
    local nDiscount = tPrice.nDiscount
    local nDisEndTime = tPrice.nDisEndTime
    if tPrice.nSecondDiscount and tPrice.nSecondDiscount < GLOBAL.COIN_PRICE_DISCOUNT_BASE and bSecondDis then
        nDiscount = CalculateDiscount(tPrice.nDiscount, bSecondDis, tPrice.nSecondDiscount)
        nDisEndTime = tPrice.nSecondDisEndTime
    end
    local fDis = KeepOneByteFloat(nDiscount / 10)
    szDisCount = szDisCount .. FormatString(g_tStrings.REWARDS_SHOP_DISCOUNT, fDis)
    local szDisTime = ""
    if nDisEndTime ~= -1 then
        nTime = nDisEndTime - nTime
        nTime = math.max(nTime, 0)
        local szTime = UIHelper.GetTimeText(nTime, false, true)
        szDisTime = FormatString(g_tStrings.REWARDS_SHOP_DISCOUNT_TIME, szTime)
    end

    szDisCount = szDisCount .. szDisTime
    return szDisCount
end

function CoinShop_GetOneDisInfo(tPrice, bSecondDis, bDetail)
    local  nTime = GetGSCurrentTime()
    local nDiscount = tPrice.nDiscount
    local nDisEndTime = tPrice.nDisEndTime
    if tPrice.nSecondDiscount and tPrice.nSecondDiscount < GLOBAL.COIN_PRICE_DISCOUNT_BASE and bSecondDis then
        nDiscount = CalculateDiscount(tPrice.nDiscount, bSecondDis, tPrice.nSecondDiscount)
        nDisEndTime = tPrice.nSecondDisEndTime
    end
    local szDisCount = ""
    local fDis = KeepOneByteFloat(nDiscount / 10)
    szDisCount = szDisCount .. FormatString(g_tStrings.REWARDS_SHOP_DISCOUNT, fDis)
    local szDisTime = ""
    if nDisEndTime ~= -1 then
        nTime = nDisEndTime - nTime
        nTime = math.max(nTime, 0)
        local szTime = UIHelper.GetHeightestTimeText(nTime, false)
        if bDetail and nTime < 24*3600 then
            szTime = UIHelper.GetTimeText(nTime, false)
        end
        szDisTime = FormatString(g_tStrings.COIN_SHOP_TIME_LEFT, szTime)
    end

    return szDisCount, szDisTime, nDiscount
end

function  CoinShop_IsDis(tInfo, eGoodsType, dwGoodsID)
    local nCurrentTime = GetGSCurrentTime()
    local bDisByRole = true
    local bDis = false
    local  hPlayer = GetClientPlayer()
    local dwDisRoleTypeMask = tInfo.dwDisRoleTypeMask
    if dwDisRoleTypeMask and hPlayer then
        bDisByRole = GetNumberBit(dwDisRoleTypeMask, hPlayer.nRoleType)
    end

    if bDisByRole then
        bDis = IsSecondDis(tInfo, eGoodsType, dwGoodsID)

        if bDis then
            return true, true
        end
        bDis = IsDis(tInfo.nDiscount, tInfo.nDisStartTime, tInfo.nDisEndTime)
    end
    return bDis, false
end

function CoinShop_IsPriceDis(tExteriorInfo)
    local tPrinceInfo = GetPriceInfo(tExteriorInfo)
    local bDis = false
    for _, tPrice in ipairs(tPrinceInfo) do
        if tPrice.bDis then
            return true
        end
    end
    return bDis
end

function CoinShop_IsSecondDis(tExteriorInfo)
    local eGoodsType = tExteriorInfo.eGoodsType
    local dwGoodsID = tExteriorInfo.dwID

    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return false
    end

    for _, nTimeType in ipairs(g_tExteriorTimeType) do
        for _, nPayType in ipairs(g_tExteriorPayType) do
            local tThePrice = tExteriorInfo.tPrice[nPayType][nTimeType]
            if tThePrice.nPrice >= 0 and tThePrice.nSecondDiscount and tThePrice.nSecondDiscount < GLOBAL.COIN_PRICE_DISCOUNT_BASE then
                local bDis = IsShowSecondDis(tThePrice, eGoodsType, dwGoodsID)
                if bDis then
                    return true
                end
            end
        end
    end
    return false
end

function CoinShop_GetSecondDis(tExteriorInfo)
    for _, nTimeType in ipairs(g_tExteriorTimeType) do
        for _, nPayType in ipairs(g_tExteriorPayType) do
            local tThePrice = tExteriorInfo.tPrice[nPayType][nTimeType]
            if tThePrice.nPrice >= 0 and tThePrice.nSecondDiscount and tThePrice.nSecondDiscount < GLOBAL.COIN_PRICE_DISCOUNT_BASE then
                local szDisCount = CoinShop_GetOneDisInfo(tThePrice, true)
                return szDisCount
            end
        end
    end
    return ""
end

function CoinShop_GetDisPrice(nPrice, nDiscount)
    nPrice = math.ceil(nPrice * nDiscount / GLOBAL.COIN_PRICE_DISCOUNT_BASE)
    return nPrice
end

function CoinShop_GetDisInfo(tExteriorInfo)
    local tPrinceInfo = GetPriceInfo(tExteriorInfo)
    local bDis = false
    local szDisCount = ""
    local szDisTime = ""
    local nDisCount = 100
    for _, tPrice in ipairs(tPrinceInfo) do
        if tPrice.bDis then
            szDisCount, szDisTime, nDisCount = CoinShop_GetOneDisInfo(tPrice, tPrice.bSecondDis)
            bDis = true
            break
        end
    end
    return bDis, szDisCount, szDisTime, nDisCount
end

function CoinShop_GetGoodsName(eGoodsType, dwGoodsID)
    local szName, r, g, b = "", 255, 255, 255
    if eGoodsType == COIN_SHOP_GOODS_TYPE.HAIR then
        local szHairText = CoinShopHair.GetHairText(dwGoodsID)
        szName = UIHelper.UTF8ToGBK(g_tStrings.HAIR_SHOP_HAIR)
        if szHairText then
            szName = szName .. UIHelper.UTF8ToGBK(g_tStrings.STR_COLON) .. szHairText
        end
    elseif eGoodsType == COIN_SHOP_GOODS_TYPE.FACE then
        if dwGoodsID then
            local nFaceUIID = CoinShopHair.GetHairUIID("Face", dwGoodsID)
            szName = UIHelper.UTF8ToGBK(g_tStrings.HAIR_SHOP_FACE)
            if nFaceUIID then
                szName = szName.. UIHelper.UTF8ToGBK(g_tStrings.STR_COLON) .. nFaceUIID
            end
        else
            szName = UIHelper.UTF8ToGBK(g_tStrings.FACE_LIFT_TITLE)
        end
    elseif eGoodsType == COIN_SHOP_GOODS_TYPE.ITEM then
        local tRewardsItem = Table_GetRewardsItem(dwGoodsID)
        if not tRewardsItem then
            return
        end
        local hItemInfo = GetItemInfo(tRewardsItem.dwTabType, tRewardsItem.dwIndex)
        if not hItemInfo then
            return
        end
        szName = ItemData.GetItemNameByItemInfo(hItemInfo)
        r, g, b = GetItemFontColorByQuality(hItemInfo.nQuality)
    elseif eGoodsType == COIN_SHOP_GOODS_TYPE.EXTERIOR or
         eGoodsType == COIN_SHOP_GOODS_TYPE.RENEW or
        eGoodsType == COIN_SHOP_GOODS_TYPE.RUBBING
    then
        _, szName = CoinShop_GetExteriorName(dwGoodsID)
    elseif eGoodsType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
        local tWeaponInfo = g_tTable.CoinShop_Weapon:Search(dwGoodsID)
        if tWeaponInfo then
            szName = tWeaponInfo.szName
        end
    elseif eGoodsType == COIN_SHOP_GOODS_TYPE.SHOW_CARD_DECORATION then
        local tInfo = Table_GetPersonalCardInfoByID(dwGoodsID)
        if tInfo then
            szName = tInfo.szName
        end
    end
    return szName, r, g, b
end

function CoinShop_UpdateBox(box, item)
    local eGoodsType = item.eGoodsType
    local dwGoodsID  = item.dwGoodsID

    if eGoodsType == COIN_SHOP_GOODS_TYPE.FACE then
		box:SetObjectIcon(ICON_FACE)
	elseif eGoodsType == COIN_SHOP_GOODS_TYPE.HAIR then
		box:SetObjectIcon(ICON_HAIR)
    elseif eGoodsType == COIN_SHOP_GOODS_TYPE.ITEM then
        local nCount = item.nBuyCount or 1

        if not dwGoodsID then
            dwGoodsID = GetItemGoodID(item.dwTabType, item.dwTabIndex)
        end

        if not item.dwTabType or not item.dwTabIndex then
            local tRewardsItem = Table_GetRewardsItem(dwGoodsID)
            item.dwTabType, item.dwTabIndex = tRewardsItem.dwTabType, tRewardsItem.dwIndex
        end
        UpdataItemInfoBoxObject(box, dwGoodsID, item.dwTabType, item.dwTabIndex, nCount)

    elseif eGoodsType == COIN_SHOP_GOODS_TYPE.EXTERIOR or
        eGoodsType == COIN_SHOP_GOODS_TYPE.RENEW or
        eGoodsType == COIN_SHOP_GOODS_TYPE.RUBBING
    then
        UpdateExteriorBoxObject(box, dwGoodsID)
    elseif eGoodsType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
        UpdateExteriorWeaponBox(box, dwGoodsID)
    end
end

function CoinShop_GetPriceInfo(dwGoodsID, eGoodsType)
    local info
    if eGoodsType == COIN_SHOP_GOODS_TYPE.HAIR then
        info = GetHairShop().GetHairPrice(GetClientPlayer().nRoleType, HAIR_STYLE.HAIR, dwGoodsID)
    elseif eGoodsType == COIN_SHOP_GOODS_TYPE.FACE then
        info = GetHairShop().GetHairPrice(GetClientPlayer().nRoleType, HAIR_STYLE.FACE, dwGoodsID)
    elseif eGoodsType == COIN_SHOP_GOODS_TYPE.EXTERIOR or eGoodsType == COIN_SHOP_GOODS_TYPE.RENEW then
        info = GetExterior().GetExteriorInfo(dwGoodsID)
    elseif eGoodsType == COIN_SHOP_GOODS_TYPE.ITEM then
        info = GetRewardsShop().GetRewardsShopInfo(dwGoodsID)
    elseif eGoodsType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
        info = CoinShop_GetWeaponExteriorInfo(dwGoodsID)
    elseif eGoodsType == COIN_SHOP_GOODS_TYPE.FURNITURE then
        info = GetFurnitureShopInfo(dwGoodsID)
    end
    if info then
        info.eGoodsType = eGoodsType
    end

    return info
end

function CoinShop_GetCheckOutPriceInfo(dwGoodsID, eGoodsType)
    local info = CoinShop_GetPriceInfo(dwGoodsID, eGoodsType)

    return GetPriceInfo(info, eGoodsType, dwGoodsID)
end

function CoinShop_GetPriceByType(dwGoodsID, eGoodsType, ePayType, eTimeLimitType)
    local info = CoinShop_GetPriceInfo(dwGoodsID, eGoodsType)
    if not info then
        return
    end

    if not ePayType then
        return info.tPrice
    end

    return info.tPrice[ePayType][eTimeLimitType]
end

function CoinShop_GetPrice(dwGoodsID, eGoodsType)
    local tInfo = CoinShop_GetPriceInfo(dwGoodsID, eGoodsType)
    tInfo.eGoodsType = eGoodsType
    tInfo.dwID = dwGoodsID
    local nPrice, nOriginalPrice = CoinShop_GetShowPrice(tInfo)
    return nPrice, nOriginalPrice
end

function CoinShop_GetFaceLiftPriceInfo(nPrice)
    local tPriceInfo = {}
    local tOnePrice = {}

    local nVouchars = GetFaceLiftManager().GetVouchers()

    local nTimeType = COIN_SHOP_TIME_LIMIT_TYPE.PERMANENT
    local nPayType = COIN_SHOP_PAY_TYPE.COIN

    tOnePrice.nPrice = nPrice
    tOnePrice.szPriceDesc = g_tStrings.tExteriorTimeType[nTimeType]
    tOnePrice.szImagePath = g_tExteriorPayTypeImg[nPayType]
    --tOnePrice.nFrame = g_tExteriorPayTypeImg[nPayType][2]
    tOnePrice.nTimeType = nTimeType
    tOnePrice.nPayType = nPayType

    tOnePrice.nDisStartTime = -1
    tOnePrice.nDisEndTime = -1
    tOnePrice.nDiscount = GLOBAL.COIN_PRICE_DISCOUNT_BASE

    tOnePrice.bDis = false
    tOnePrice.nDisPrice = nPrice
    local bCanUseVouchers =  GetFaceLiftManager().CanUseVouchers()
    if nPrice > 0 and nVouchars > 0 and bCanUseVouchers then
        tOnePrice.nVouchars = math.min(nVouchars, nPrice)
    end
    table.insert(tPriceInfo, tOnePrice)

    return tPriceInfo
end

function CoinShop_GetNewFacePriceInfo(nPrice)
    local tPriceInfo = {}
    local tOnePrice = {}

    local nTimeType = COIN_SHOP_TIME_LIMIT_TYPE.PERMANENT
    local nPayType = COIN_SHOP_PAY_TYPE.COIN

    tOnePrice.nPrice = nPrice
    tOnePrice.szPriceDesc = g_tStrings.tExteriorTimeType[nTimeType]
    tOnePrice.szImagePath = g_tExteriorPayTypeImg[nPayType]
    -- tOnePrice.nFrame = g_tExteriorPayTypeFrame[nPayType][2]
    tOnePrice.nTimeType = nTimeType
    tOnePrice.nPayType = nPayType

    tOnePrice.nDisStartTime = -1
    tOnePrice.nDisEndTime = -1
    tOnePrice.nDiscount = GLOBAL.COIN_PRICE_DISCOUNT_BASE

    tOnePrice.bDis = false
    tOnePrice.nDisPrice = nPrice
    table.insert(tPriceInfo, tOnePrice)
    return tPriceInfo
end

function CoinShop_ShowBeforeTime(eGoodsType, nClass)
    local tTitleInfo = CoinShop_GetTitleInfo(eGoodsType, nClass)
    if tTitleInfo and tTitleInfo.bShowBeforeTime then
        return true
    end
    return false
end

function CoinShop_GetEndTime(tInfo)
    if tInfo.nGameWorldStartInDuration > 0 then
        local nEndTime = GetGameWorldStartTime() + tInfo.nGameWorldStartInDuration
        if tInfo.nEndTime == -1 then
            return nEndTime
        end
        return math.min(tInfo.nEndTime, nEndTime)
    end

    return tInfo.nEndTime
end

function CoinShop_GetStartTime(tInfo)
    if tInfo.nGameWorldStartDuration > 0 then
        local nStartTime = GetGameWorldStartTime() + tInfo.nGameWorldStartDuration
        if tInfo.nStartTime == -1 then
            return nStartTime
        end
        return math.max(tInfo.nStartTime, nStartTime)
    end

    return tInfo.nStartTime
end

function CoinShop_CheckRewardsTime(dwLogicID, nClass)
    local hRewardsShop = GetRewardsShop()
    if not hRewardsShop then
        return
    end
    local tInfo = hRewardsShop.GetRewardsShopInfo(dwLogicID)
    if not tInfo then
        return
    end

    local nStartTime = CoinShop_GetStartTime(tInfo)
    local nEndTime = CoinShop_GetEndTime(tInfo)
    local bShow = IsTimeOk(nStartTime, nEndTime)

    return bShow
end

function CoinShop_RewardsShow(dwLogicID, nClass)
    local hRewardsShop = GetRewardsShop()
    if not hRewardsShop then
        return
    end
    local tInfo = hRewardsShop.GetRewardsShopInfo(dwLogicID)
    if not tInfo then
        return
    end
    local nTime = GetGSCurrentTime()
    local bCanBuy = false
    local nCounterID = tInfo.nGlobalCounterID
    local bShowBeforeTime = CoinShop_ShowBeforeTime(COIN_SHOP_GOODS_TYPE.ITEM, nClass)
    local nEndTime = CoinShop_GetEndTime(tInfo)

    if nCounterID > 0 then
        local nCount = GetCoinShopClient().GetGlobalCounterValue(nCounterID)
        bCanBuy = (nEndTime == -1 or nTime <= nEndTime) and nCount > 0

        return bCanBuy
    end

    if bShowBeforeTime then
        bCanBuy = nEndTime == -1 or nTime <= nEndTime
        return bCanBuy
    end

    local nStartTime = CoinShop_GetStartTime(tInfo)
    bCanBuy = IsTimeOk(nStartTime, nEndTime)
    return bCanBuy
end

function CoinShop_RewardsShowLimit3(dwLogicID)
    local hRewardsShop = GetRewardsShop()
    if not hRewardsShop then
        return
    end
    local tInfo = hRewardsShop.GetRewardsShopInfo(dwLogicID)
    if not tInfo then
        return
    end
    local nCounterID = tInfo.nGlobalCounterID
    if nCounterID > 0 then
        return false
    end

    local nStartTime = CoinShop_GetStartTime(tInfo)
    local nEndTime = CoinShop_GetEndTime(tInfo)
    if nStartTime == - 1 or nEndTime == -1 then
        return false
    end

    if nEndTime - nStartTime == 3 * 60 then
        return true
    end

    return false
end

function IsHavePreOrder(eGoodsType, dwGoodsID)
    local dwPreOrderID = GetCoinShopClient().GetNeedPreOrderID(eGoodsType, dwGoodsID)
    if dwPreOrderID <= 0 then
        return true
    end
    local nCount = GetClientPlayer().GetCoinShopPreOrderCount(dwPreOrderID)
    return nCount > 0
end

function CoinShop_RewardsCanBuy(dwLogicID)
    local hRewardsShop = GetRewardsShop()
    if not hRewardsShop then
        return
    end
    local tInfo = hRewardsShop.GetRewardsShopInfo(dwLogicID)
    if tInfo == nil then
        return
    end

    local nCounterID = tInfo.nGlobalCounterID
    local bLimitItem = nCounterID > 0
    local nEndTime = CoinShop_GetEndTime(tInfo)
    if not bLimitItem and not IsTimeOk(tInfo.nStartTime, nEndTime) then
        return false
    end
    --local bCanBuy = IsTimeOk(tInfo.nStartTime, nEndTime)
    if bLimitItem then
        local nCount = GetCoinShopClient().GetGlobalCounterValue(nCounterID)
        if nCount <= 0 then
            return false
        end
    end
    if not IsHavePreOrder(COIN_SHOP_GOODS_TYPE.ITEM, dwLogicID) then
        return false
    end
    return true
end

function CoinShop_IsRewardsTimeOk(dwLogicID)
    local hRewardsShop = GetRewardsShop()
    if not hRewardsShop then
        return
    end
    local tInfo = hRewardsShop.GetRewardsShopInfo(dwLogicID)
    local nStartTime = CoinShop_GetStartTime(tInfo)
    local nEndTime = CoinShop_GetEndTime(tInfo)
    return IsTimeOk(nStartTime, nEndTime)
end

function CoinShop_WeaponCanBuy(dwID)
    local hExterior = GetExterior()
    if not hExterior then
        return
    end
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    if hPlayer.dwBitOPForceID == 0 then
        return false
    end

    local tInfo = CoinShop_GetWeaponExteriorInfo(dwID, hExterior)
    local nForceMask = tInfo and tInfo.nForceMask or 0
    if nForceMask > 0 then
        --local bCanBuyForForce = GetNumberBit(nForceMask, hPlayer.dwForceID + 1)
        local bCanBuyForForce = GetNumberBit(nForceMask, hPlayer.dwBitOPForceID + 1)
        if not bCanBuyForForce then
            return false
        end
    end

    local bCanBuy = IsTimeOk(tInfo.nStartTime, tInfo.nEndTime)
    return bCanBuy
end

function CoinShop_ExteriorCanBuy(dwID)
    local hExterior = GetExterior()
    if not hExterior then
        return
    end
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return false
    end

    local tInfo = hExterior.GetExteriorInfo(dwID)
    if tInfo.nGenre == EXTERIOR_GENRE.SCHOOL and
        tInfo.nForceID ~= hPlayer.dwForceID
    then
        return false
    end

    local bCanBuy = IsTimeOk(tInfo.nStartTime, tInfo.nEndTime)
    return bCanBuy
end

function CoinShop_CanBuy(eGoodsType, dwGoodsID)
    if eGoodsType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
        return CoinShop_ExteriorCanBuy(dwGoodsID)
    elseif eGoodsType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
        return CoinShop_WeaponCanBuy(dwGoodsID)
    elseif eGoodsType == COIN_SHOP_GOODS_TYPE.ITEM then
        return CoinShop_RewardsCanBuy(dwGoodsID)
    end

    return true
end

function CoinShop_GoodsShow(eGoodsType, dwGoodsID)
    if eGoodsType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
        return CoinShop_ExteriorCanBuy(dwGoodsID)
    elseif eGoodsType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
        return CoinShop_WeaponCanBuy(dwGoodsID)
    elseif eGoodsType == COIN_SHOP_GOODS_TYPE.ITEM then
        local tLine = Table_GetRewardsItem(dwGoodsID)
        if not tLine then return false end
        return CoinShop_RewardsShow(dwGoodsID, nClass)
    end

    return true
end

function CoinShop_GetCollectInfo(eGoodsType, dwGoodsID)
    local hPlayer = GetClientPlayer()
    local hExterior = GetExterior()
    if not hExterior then
        return
    end
    if eGoodsType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
        local tExteriorInfo = hExterior.GetExteriorInfo(dwGoodsID)
        local bIsInShop = tExteriorInfo.bIsInShop
        if not bIsInShop then
            local bCollect = hPlayer.IsExteriorCollected(dwGoodsID)
            return bCollect, tExteriorInfo.nCollectionNeedMoney
        end
    elseif eGoodsType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
        local tExteriorInfo = CoinShop_GetWeaponExteriorInfo(dwGoodsID, hExterior)
        local bCollect = hPlayer.IsWeaponExteriorCollected(dwGoodsID)
        return bCollect, tExteriorInfo.nCollectionNeedMoney
    end

    return true
end

function CoinShop_GetExteriorID(nTabType, nIndex)
    local hItemInfo = GetItemInfo(nTabType, nIndex)
    if not hItemInfo then
        return
    end

    local dwExteriorID = CoinShop_GetExteriorIDByItemInfo(hItemInfo)
    return dwExteriorID
end

function CoinShop_GetExteriorIDByItemInfo(hItemInfo)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local hExterior = GetExterior()
    if not hExterior then
        return
    end

    if hItemInfo.nGenre ~= ITEM_GENRE.EQUIPMENT then
        return
    end

    local nRepresentSub = Exterior_SubToRepresentSub(hItemInfo.nSub)
    if not nRepresentSub then
        return
    end

    local tColorID = hItemInfo.GetColorID()
    local dwExteriorID = hExterior.GetExteriorIndex(hItemInfo.nSub, hItemInfo.nRepresentID, tColorID[1], hPlayer.dwForceID)
    return dwExteriorID
end

function CoinShop_GetWeaponIDByItemInfo(hItemInfo)
    local hExterior = GetExterior()
    if not hExterior then
        return
    end

    if hItemInfo.nGenre ~= ITEM_GENRE.EQUIPMENT then
        return
    end

    local tColorID = hItemInfo.GetColorID()
    local tEnchant = hItemInfo.GetEnchantRepresentID()
    local dwWeaponEnchant1 = tEnchant[1]
    local dwWeaponEnchant2 = tEnchant[2]
    local dwWeaponID = hExterior.GetWeaponExteriorIndex(
        hItemInfo.nDetail, hItemInfo.nRepresentID, tColorID[1],
        dwWeaponEnchant1, dwWeaponEnchant2
    )

    return dwWeaponID
end

function CoinShop_IsFaceliftModifyDis()
    local tPriceInfo = GetFaceLiftManager().GetChangeTaxPriceInfo()
    local bDis = CoinShop_IsDis(tPriceInfo)
    return bDis
end

local _aCameraData
function GetCameraData()
    if _aCameraData then
        return _aCameraData
    end
    _aCameraData = g_tRoleView
    return _aCameraData
end


function CoinShop_GetShowPrice(tInfo)
    local eGoodsType = tInfo.eGoodsType
    local dwGoodsID = tInfo.dwID
    local ePayType = COIN_SHOP_PAY_TYPE.COIN
    local eTimeLimitType = COIN_SHOP_TIME_LIMIT_TYPE.PERMANENT
    local tThePrice = tInfo.tPrice[ePayType][eTimeLimitType]
    local nOriginalPrice = tThePrice.nPrice
    local nPrice = nOriginalPrice

    if nPrice < 0 then
        local tPrinceInfo = GetPriceInfo(tInfo)
        local tPrice = tPrinceInfo[1]
        return tPrice.nPrice, tPrice.nPrice, tPrice.szImagePath, tPrice.nFrame
    end

    if nPrice > 0 then

        local bDis, bSecondDis = CoinShop_IsDis(tThePrice, eGoodsType, dwGoodsID)

        local nDiscount = CalculateDiscount(tThePrice.nDiscount, bSecondDis, tThePrice.nSecondDiscount)

        if bDis then
            nPrice = CoinShop_GetDisPrice(nPrice, nDiscount)
        end

        if tInfo.bIsReal then
            nPrice = math.floor(nPrice / 100)
            nOriginalPrice = math.floor(nOriginalPrice / 100)
        end
    end

    return nPrice, nOriginalPrice
end

function CoinShop_GetPriceDisTime(tInfo)
    local ePayType = COIN_SHOP_PAY_TYPE.COIN
    local eTimeLimitType = COIN_SHOP_TIME_LIMIT_TYPE.PERMANENT
    local tThePrice = tInfo.tPrice[ePayType][eTimeLimitType]
    local nPrice = tThePrice.nPrice


    if nPrice > 0 then
        return tThePrice.nDisStartTime, tThePrice.nDisEndTime
    end

    return -1, -1
end

function CoinShop_GetSecondDisTime(tInfo)
    local ePayType = COIN_SHOP_PAY_TYPE.COIN
    local eTimeLimitType = COIN_SHOP_TIME_LIMIT_TYPE.PERMANENT
    local tThePrice = tInfo.tPrice[ePayType][eTimeLimitType]
    local nPrice = tThePrice.nPrice


    if nPrice > 0 and tThePrice.nSecondDiscount and tThePrice.nSecondDiscount ~= GLOBAL.COIN_PRICE_DISCOUNT_BASE then
        return tThePrice.nSecondDisStartTime, tThePrice.nSecondDisEndTime
    end

    return -1, -1
end

function CheckHaveUnPayOrder()
    --local tOrder = CoinShop_TradeCenter.GetUnPayOrder()
    --if tOrder then
    --    CoinShop_UnPayRel.Open(tOrder)
    --    return true
    --end

    return false
end

function CoinShop_GetMatchHair(dwID)
    local tInfo = GetExterior().GetExteriorInfo(dwID)
    local tSetInfo = Table_GetExteriorSet(tInfo.nSet)
    if tSetInfo.nMatchHair <= 0 then
        return
    end

    return tSetInfo.nMatchHair
end

--local tItemList = {{dwGoodsID = 3329, eGoodsType = 6,nBuyCount = 1},{dwGoodsID = 3330, eGoodsType = 6, nBuyCount = 2}}
function CoinShop_BuyItemList(tItemList, nPayType, dwDisCouponID, fnIsOpened, fnChooseNewDisCoupon, fnFailed)
    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.COIN, "COIN") then
        return
    end
    local nAllPrice = 0
    local tBuy = {}
    for k, v in pairs(tItemList) do
        local tItem = {}
        tItem.dwGoodsID = v.dwGoodsID
        tItem.eGoodsType = v.eGoodsType
        tItem.bHave = false
        tItem.nBuyCount = v.nBuyCount
        tItem.ePayType = nPayType or COIN_SHOP_PAY_TYPE.COIN
        tItem.eTimeLimitType = COIN_SHOP_TIME_LIMIT_TYPE.PERMANENT
        local tPrice = CoinShop_GetPriceByType(tItem.dwGoodsID, tItem.eGoodsType, tItem.ePayType, tItem.eTimeLimitType)
        tItem.nPrice = tPrice.nPrice
        tItem.nDiscount = GLOBAL.COIN_PRICE_DISCOUNT_BASE
        local bDis = CoinShop_IsDis(tPrice)
        if bDis then
            tItem.nDiscount = tPrice.nDiscount
        end
        local nPrice = CoinShop_GetDisPrice(tItem.nPrice, tItem.nDiscount) * v.nBuyCount
        nAllPrice = nAllPrice + nPrice
        table.insert(tBuy, tItem)
    end

    local fnBuyEX = function()
        if dwDisCouponID then
            local nDiscount = CoinShopData.GetDisCouponPrice(tBuy, dwDisCouponID) or 0
            nAllPrice = nAllPrice - nDiscount
        end

        local hPlayer = GetClientPlayer()
        if not hPlayer then
            return
        end

        local fnBuy = function()
            local nRetCode = GetCoinShopClient().Buy(tBuy, false, dwDisCouponID)
            if nRetCode ~= COIN_SHOP_ERROR_CODE.SUCCESS then
                OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tCoinShopNotify[nRetCode])
                OutputMessage("MSG_SYS", g_tStrings.tCoinShopNotify[nRetCode])
                if fnFailed then
                    fnFailed()
                end
            end
        end

        if dwDisCouponID and nAllPrice > 0 then
            local tDisCoupon = CoinShopData.GetWelfare(dwDisCouponID)
            local nDiscount = CoinShopData.GetDisCouponPrice(tBuy, dwDisCouponID) or 0
            local szMsg = FormatString(g_tStrings.DIS_COUPON_USE_MESSAGE, tDisCoupon.szMenuOption, nDiscount)
            UIHelper.ShowConfirm(szMsg, function () fnBuy() end, nil, true)
        else
            fnBuy()
        end
    end

    CoinShopData.DisJudge(tBuy, false, dwDisCouponID, fnBuyEX, fnChooseNewDisCoupon)
end

function CoinShop_BuyItem(dwGoodsID, eGoodsType, nCount, nPayType)
    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.COIN, "COIN") then
        return
    end
    local tItem = {}
    tItem.dwGoodsID = dwGoodsID
    tItem.eGoodsType = eGoodsType
    tItem.bHave = false
    tItem.nBuyCount = nCount
    tItem.ePayType = nPayType or COIN_SHOP_PAY_TYPE.COIN
    tItem.eTimeLimitType = COIN_SHOP_TIME_LIMIT_TYPE.PERMANENT
    local tPrice = CoinShop_GetPriceByType(tItem.dwGoodsID, tItem.eGoodsType, tItem.ePayType, tItem.eTimeLimitType)
    tItem.nPrice = tPrice.nPrice
    tItem.nDiscount = GLOBAL.COIN_PRICE_DISCOUNT_BASE
    local bDis = CoinShop_IsDis(tPrice)
    if bDis then
        tItem.nDiscount = tPrice.nDiscount
    end
    local tBuy = {}
    table.insert(tBuy, tItem)

	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end

    -- fixme: 下面这段代码似乎是从端游抄过来的，目前 Web_QRCodeRecharge 在手游端是没有的，先暂时屏蔽掉，后面需要的话再处理
    --local nPrice = CoinShop_GetDisPrice(tItem.nPrice, tItem.nDiscount) * nCount
    --if nPrice > 0 and nPrice > hPlayer.nCoin then
    --    if Web_QRCodeRecharge.JudgeEX(nPrice - hPlayer.nCoin) then
    --        return
    --    end
	--end

    local nRetCode = GetCoinShopClient().Buy(tBuy, false)

    if nRetCode ~= COIN_SHOP_ERROR_CODE.SUCCESS then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tCoinShopNotify[nRetCode])
        OutputMessage("MSG_SYS", g_tStrings.tCoinShopNotify[nRetCode])
    end
    return nRetCode
end

function CoinShop_GetTimeText(nShowTime, nNotCountDown)
    local nTime = GetGSCurrentTime()
    local nLeftTime = nShowTime - nTime
    local szTime = ""
    local bCountDown = false
    if nLeftTime < 3600 and not nNotCountDown then
        szTime = UIHelper.GetTimeText(nLeftTime)
        bCountDown = true
    else
        local tTime = TimeToDate(nShowTime)
        szTime = FormatString(g_tStrings.STR_TIME_9, tTime.month, tTime.day, tTime.hour,  string.format("%02d", tTime.minute))
        bCountDown = false
    end
    return szTime, bCountDown
end

function CoinShop_GetCountDownInfo(tInfo)
    local nTime = GetGSCurrentTime()
    local nEndTime = CoinShop_GetEndTime(tInfo)
    local bLimitItem = tInfo.nGlobalCounterID and tInfo.nGlobalCounterID > 0
    local szText = ""
    local nFont = 276
    if IsMobileStreamingEnable() then
        nFont = 303
    end

    if tInfo.nStartTime ~= -1 and nTime <= tInfo.nStartTime then
        local szTime = CoinShop_GetTimeText(tInfo.nStartTime)
        if szTime ~= "" then
            if IsMobileStreamingEnable() then
                szText = FormatString(g_tStrings.COINSHOP_ITEM_COUNT_DOWN_MOBILE_SM, szTime)
            else
                szText = FormatString(g_tStrings.COINSHOP_ITEM_COUNT_DOWN, szTime)
            end
        end
    elseif nEndTime ~= -1 and nTime <= nEndTime then
        local szTime = CoinShop_GetTimeText(nEndTime)
        if szTime ~= "" then
            if IsMobileStreamingEnable() then
                szText = FormatString(g_tStrings.COINSHOP_ITEM_COUNT_DOWN_END_MOBILE_SM, szTime)
            else
                szText = FormatString(g_tStrings.COINSHOP_ITEM_COUNT_DOWN_END, szTime)
            end
        end
    elseif nEndTime ~=-1 and nTime > nEndTime then
        szText = GetFormatText(g_tStrings.COINSHOP_SELL_OUT_BUY_TIME, nFont)
    end
    if bLimitItem then
        local nCounterID = tInfo.nGlobalCounterID
        if nCounterID > 0 then
            local nCount = GetCoinShopClient().GetGlobalCounterValue(nCounterID)
            if nCount <= 0 then
                szText = GetFormatText(g_tStrings.COINSHOP_SELL_OUT, nFont)
            end
        end
    end
    return szText
end

function CoinShop_GetGoodsType(tItem)
    if tItem.eGoodsType == COIN_SHOP_GOODS_TYPE.ITEM then
        return CoinShop_GetRewardsType({dwTabType = tItem.dwTabType, dwIndex = tItem.dwTabIndex})
    elseif tItem.eGoodsType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
        local tbInfo = CoinShop_GetWeaponExteriorInfo(tItem.dwGoodsID)
        local nDetail = tbInfo.nDetailType
        return g_tStrings.WeapenDetail[nDetail]
    else
        return CoinShop_GetSubType(tItem.dwGoodsID, tItem.eGoodsType)
    end
end

function CoinShop_GetRewardsType(tItem)
    local szType = ""
    local hItemInfo = GetItemInfo(tItem.dwTabType, tItem.dwIndex)
    if hItemInfo.nGenre == ITEM_GENRE.EQUIPMENT and
        hItemInfo.nSub == EQUIPMENT_SUB.HORSE
    then
        szType = g_tStrings.ITEM_HORSE
    elseif hItemInfo.nGenre == ITEM_GENRE.EQUIPMENT and
        hItemInfo.nSub == EQUIPMENT_SUB.HORSE_EQUIP
    then
        szType = g_tStrings.tHorseEnchantType[hItemInfo.nDetail]
    elseif hItemInfo.nGenre == ITEM_GENRE.EQUIPMENT and
        hItemInfo.nSub == EQUIPMENT_SUB.PET
    then
        szType = g_tStrings.REWARDS_SHOP_PET
    elseif hItemInfo.nGenre == ITEM_GENRE.EQUIPMENT and IsPendantItem(hItemInfo) then
        szType = g_tStrings.tEquipTypeNameTable[hItemInfo.nSub]
    else
        szType = g_tStrings.REWARDS_SHOP_ITEM
    end
    return szType
end

local tFrameList = {}
local bModuleFrameShow = true
function RegisterCoinShopModuleFrame(szFrame, szFramePath, fnIsOpened, fnShow)
    if not tFrameList[szFrame] then
        local tFrame = {fnIsOpened = fnIsOpened, fnShow = fnShow, szFramePath = szFramePath}
        tFrameList[szFrame] = tFrame
    end
end

function UnRegisterCoinShopModuleFrame(szFrame)
    tFrameList[szFrame] = nil
end

function CoinShop_ModuleFrameShow(bShow)
    if bModuleFrameShow == bShow then
        return
    end
    for szFrame, tFrame in pairs(tFrameList) do
        if tFrame.fnIsOpened and tFrame.fnShow then
            if tFrame.fnIsOpened() then
                tFrame.fnShow(bShow)
            end
        elseif tFrame.szFramePath then
            local hFrame = Station.Lookup(tFrame.szFramePath)
            if hFrame then
                hFrame:Show(bShow)
            end
        end
    end
    bModuleFrameShow = bShow
    CoinShop_Main.OnModuleFrameShow(bShow)
    FireUIEvent("COINSHOP_MODULE_FRAME_SHOW", bShow)
end

function CoinShop_IsModuleFrameShow()
    return bModuleFrameShow
end

function CoinShop_SaveOutfitData()
    Storage.CoinShop.Flush()
end

local function CheckOutfitData()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local hCoinShopClient = GetCoinShopClient()
	if not hCoinShopClient then
		return
	end
    local bChanged = false
    for _, tSet in ipairs(Storage.CoinShop.tbOutfitList) do
        for i = #tSet.tData, 1, -1 do
            local tData = tSet.tData[i]
            if not tData then
                break
            end
            local dwID = tData.dwID
            local nIndex = tData.nIndex
            local bHave = true
            if nIndex ~= COINSHOP_BOX_INDEX.FACE and nIndex ~= COINSHOP_BOX_INDEX.NEW_FACE and nIndex ~= COINSHOP_BOX_INDEX.BODY then
                local dwType
                if nIndex == COINSHOP_BOX_INDEX.PENDANT_PET then
                    bHave = hPlayer.IsHavePendentPet(dwID)
                elseif CoinShop_BoxIndexToPendantType(nIndex) then
                    bHave = hPlayer.IsPendentExist(dwID)
                else
                    local nSub = Exterior_BoxIndexToExteriorSub(nIndex)
                    if nSub then
                        dwType = COIN_SHOP_GOODS_TYPE.EXTERIOR
                    elseif nIndex == COINSHOP_BOX_INDEX.HAIR then
                        dwType = COIN_SHOP_GOODS_TYPE.HAIR
                    elseif tWeaponBox[nIndex] then
                        dwType = COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR
                    end
                    local nHaveType = hCoinShopClient.CheckAlreadyHave(dwType, dwID)
                    bHave = nHaveType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE
                end
            end
            if not bHave then
                bChanged = true
                table.remove(tSet.tData, i)
            end
        end
    end
    if bChanged then
        CoinShop_SaveOutfitData()
    end
end

function CoinShop_GetOutfitList()
    CheckOutfitData()
    return Storage.CoinShop.tbOutfitList
end

function CoinShop_SaveOutfitList(tOutfit, bUpdate)
    tOutfit.bNew = true
    table.insert(Storage.CoinShop.tbOutfitList, 1, tOutfit)
    Storage.CoinShop.Dirty()
    if bUpdate then
        FireUIEvent("SAVE_OUTFIT_SUCCESS")
    end
end

function CoinShop_ReplaceOutfitList(tOutfit, nIndex, bUpdate)
    tOutfit.bNew = true
    local tOldfit = Storage.CoinShop.tbOutfitList[nIndex]
    local szName = tOldfit.szName
    tOutfit.szName = szName
    Storage.CoinShop.tbOutfitList[nIndex] = tOutfit
    Storage.CoinShop.Dirty()
    if bUpdate then
        FireUIEvent("REPLACE_OUTFIT_SUCCESS")
    end
end

function CoinShop_OutfitClearNew()
    for _, tOutfit in ipairs(Storage.CoinShop.tbOutfitList) do
        if tOutfit.bNew then
            tOutfit.bNew = nil
        end
    end
    Storage.CoinShop.Dirty()
end

function CoinShop_DeleteOutfitList(nIndex, bUpdate)
    table.remove(Storage.CoinShop.tbOutfitList, nIndex)
    Storage.CoinShop.Dirty()
    if bUpdate then
        FireUIEvent("DELETE_OUTFIT_SUCCESS")
    end
end

function CoinShop_OutfitNameRepeat(szName)
    for _, tOutfit in ipairs(Storage.CoinShop.tbOutfitList) do
        if tOutfit.szName == szName then
            return true
        end
    end

    return false
end

function CoinShop_OutfitCheckRepeat(tCheckOutfit)
    local tAllOutfit = Storage.CoinShop.tbOutfitList
    for nIndex, tOutfit in ipairs(tAllOutfit) do
        local bSame = CoinShop_IsOutfitSame(tCheckOutfit, tOutfit)
        if bSame then
            return true, nIndex
        end
    end
    return false
end

function CoinShop_GetOutfitByIndex(nIndex)
    return Storage.CoinShop.tbOutfitList[nIndex]
end

function CoinShop_IsOutfitSame(tOutfit1, tOutfit2)
    if #tOutfit1.tData ~= #tOutfit2.tData then
        return false
    end

    if tOutfit1.bHideHat ~= tOutfit2.bHideHat then
        return false
    end
    for i, tData1 in ipairs(tOutfit1.tData) do
        tData2 = tOutfit2.tData[i]
        if tData1.nIndex ~= tData2.nIndex or tData1.dwID ~= tData2.dwID then
            return false
        end

        if tData1.nIndex == COINSHOP_BOX_INDEX.FACE then
            if tData1.bUseLiftedFace ~= tData2.bUseLiftedFace then
                return false
            end
        end

        if tData1.tColorID or tData2.tColorID then
            local tColorID1 = tData1.tColorID or {0, 0, 0}
            local tColorID2 = tData2.tColorID or {0, 0, 0}
            for i, nColor1 in ipairs(tColorID1) do
                local nColor2 = tColorID2[i]
                if nColor1 ~= nColor2 then
                    return false
                end
            end
        end
    end

    return true
end

function CoinShop_IsCountLimit()
    -- if not SM_IsEnable() then
    --     return false
    -- end
    return #Storage.CoinShop.tbOutfitList >= SM_OUTFIT_MAX_COUNT
end

function CoinShop_OpenInternetExplorer(szAddr, bDisableSound)
    local hWebPage = OpenInternetExplorer(tUrl.Recharge, true)
    if hWebPage then
        local hFrame = hWebPage:GetRoot()
        hFrame:ShowWhenUIHide()
    end
end

function CoinShop_IsInCoinShop()
    local bInShop = CoinShop_Main and CoinShop_Main.IsOpened()
    return bInShop
end

function CoinShop_OpenReCharge()
    CoinShop_OpenInternetExplorer(tUrl.Recharge, true)
end

function CoinShop_CartNameRepeat(szName)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return false
    end
    local tList = hPlayer.GetAllCoinShopCartData()
    for _, tData in ipairs(tList) do
        if szName == tData.szName then
            return true
        end
    end

    return false
end

_bCartNew = false

function CoinShop_SetCartNew(bNew)
    _bCartNew = bNew
end

function CoinShop_GetCartNew()
    return _bCartNew
end

function CoinShop_GetWelfare(dwID)
    tLine = g_tTable.CoinShop_Welfare:Search(dwID)
    return tLine
end

local _tNoticeTitleMap = {}
function CoinShop_GetNoticeTitleMap()
    local tNoticeMap = {}
    local tList = CoinShopData.GetDisCouponList()
    for i, welfare in ipairs(tList) do
        local tInfo = CoinShop_GetWelfare(welfare.dwDisCouponID)
        if tInfo.bNotice then
            local szKey = string.format("%d_%d", tInfo.nNoticeTitleClass, tInfo.nNoticeTitleSub)
            tNoticeMap[szKey] = true
        end
	end
    return tNoticeMap
end

function CoinShop_UpdateNoticeTitleMap()
    _tNoticeTitleMap = CoinShop_GetNoticeTitleMap()
end

function CoinShop_IsNoticeTitle(nTitleClass, nTitleSub)
    local szKey = string.format("%d_%d", nTitleClass, nTitleSub)
    if _tNoticeTitleMap[szKey] then
        return true
    end

    return false
end

function CoinShop_GetRewardItemInfo(tItem, tRItem)
    local hRewardsShop = GetRewardsShop()
    if not hRewardsShop then
        return
    end

    tItem.nState = ACCOUNT_ITEM_STATUS.NORMAL
    tItem.eGoodsType = COIN_SHOP_GOODS_TYPE.ITEM
    local dwLogicID = 0
    if tRItem then
        dwLogicID = tRItem.dwLogicID
        tItem.dwGoodsID = dwLogicID or 0
        tItem.dwTabType = tRItem.dwTabType
        tItem.dwTabIndex = tRItem.dwIndex
    elseif tItem.dwGoodsID and tItem.dwGoodsID > 0 then
        dwLogicID = tItem.dwGoodsID
    end

    if dwLogicID and dwLogicID > 0 then
        tItem.tPriceInfo = CoinShop_GetRewardsPriceInfo(dwLogicID)
        tItem.szTime = CoinShop_GetRewardsTime(dwLogicID)
        local tInfo = hRewardsShop.GetRewardsShopInfo(dwLogicID)
        tItem.bCanBuyMultiple = tInfo.bCanBuyMultiple
        tItem.bLimitItem = tInfo.nGlobalCounterID > 0
        tItem.bForbiddPeerPay = tInfo.bForbiddPeerPay
        tItem.bForbidDisCoupon = tInfo.bForbidDisCoupon
        tItem.bRel = tInfo.bIsReal
        tInfo.eGoodsType = COIN_SHOP_GOODS_TYPE.ITEM
        tItem.bSecondDis = CoinShop_IsSecondDis(tInfo)
        tItem.szSecondDis = CoinShop_GetSecondDis(tInfo)
        tItem.dwTabType = tInfo.dwItemTabType
        tItem.dwTabIndex = tInfo.dwItemTabIndex
    end
end

function CoinShop_GetBuyIndexTip(nBuyIndex)
	local szText = ""
	if nBuyIndex > 0 then
        szText = CoinShop_GetBuyIndexText(nBuyIndex)
        szText = GetFormatText("\n" .. szText, 0)
	end

	return szText
end

-- 商城铭牌现在是32位（0-31），现在需要把第30位解析出来，即：nBuyIndex & (1 << 30)，如果值是0代表电信区，1代表双线区。
-- 铭牌的值要把第30位抹掉，即nBuyIndex & (~(1 << 30))
function CoinShop_GetBuyIndexText(nBuyIndex)
    local szText = ""
    local bDianXin = false
	if nBuyIndex > 0 then
        local szArena = g_tStrings.WANG_TONG
        bDianXin = GetNumberBit(nBuyIndex, 31) == 0 -- lua下标从1开始
        nBuyIndex = SetNumberBit(nBuyIndex, 31, false)
		if bDianXin then
			szArena = g_tStrings.DIAN_XIN
		end
		szText = FormatString(g_tStrings.COINSHOP_BUYINDEX_TIP, szArena, nBuyIndex)
	end

	return szText
end

local function GetFaceLiftData(nID)
	local szFile = CoinShop_GetFaceLiftFile(nID)
	if not szFile then
		return
	end
    local tBoneParams, tDecals, nDecorationID = KG3DEngine.GetFaceDefinitionFromINIFile(szFile)
    local tData = {}
    tData.tBone = tBoneParams
    tData.tDecal = tDecals
    tData.nDecorationID = nDecorationID
    local ViewData = {}
	ViewData.tFaceData = tData

	return ViewData
end

function CoinShop_PreviewGoods(eGoodsType, dwGoodsID, bUpdate)
    if eGoodsType == COIN_SHOP_GOODS_TYPE.ITEM then
        FireUIEvent("PREVIEW_REWARDS", dwGoodsID)
    elseif eGoodsType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
        FireUIEvent("PREVIEW_SUB", dwGoodsID, nil, bUpdate, false)
    elseif eGoodsType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
        FireUIEvent("PREVIEW_WEAPON", dwGoodsID, bUpdate)
    elseif eGoodsType == COIN_SHOP_GOODS_TYPE.HAIR then
        FireUIEvent("PREVIEW_HAIR", dwGoodsID, nil, bUpdate, false, false)
    elseif eGoodsType == COIN_SHOP_GOODS_TYPE.FACE then
        if dwGoodsID >= FACELIFT_INDEX_START then
            local UserData = GetFaceLiftData(dwGoodsID)
            FireUIEvent("PREVIEW_FACE", nil, true, UserData, false, bUpdate)
        else
            FireUIEvent("PREVIEW_FACE", dwGoodsID, nil, nil, false, bUpdate)
        end
    end
end

function CoinShop_CancelPreviewGoods(eGoodsType, dwGoodsID, bUpdate)
    if eGoodsType == COIN_SHOP_GOODS_TYPE.ITEM then
        FireUIEvent("CANCEL_PREVIEW_REWARDS", dwGoodsID)
    elseif eGoodsType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
        FireUIEvent("CANCEL_PREVIEW_SUB", dwGoodsID, bUpdate, nil, false)
    elseif eGoodsType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
        FireUIEvent("CANCEL_PREVIEW_WEAPON", dwGoodsID, bUpdate)
    elseif eGoodsType == COIN_SHOP_GOODS_TYPE.HAIR then
        FireUIEvent("RESET_HAIR")
    elseif eGoodsType == COIN_SHOP_GOODS_TYPE.FACE then
        FireUIEvent("RESET_FACE")
    end
end

function CoinShop_IsGoodsPreview(eGoodsType, dwGoodsID)
    if eGoodsType == COIN_SHOP_GOODS_TYPE.ITEM then
        local tItem = Table_GetRewardsItem(dwGoodsID)
        return ExteriorCharacter.IsRewardsPreview(tItem)
    elseif eGoodsType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
        return ExteriorCharacter.IsSubPreview(dwGoodsID)
    elseif eGoodsType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
        return ExteriorCharacter.IsWeaponPreview(dwGoodsID)
    elseif eGoodsType == COIN_SHOP_GOODS_TYPE.HAIR then
        return ExteriorCharacter.IsHairPreview(dwGoodsID)
    elseif eGoodsType == COIN_SHOP_GOODS_TYPE.FACE then
        return ExteriorCharacter.IsFacePreview(dwGoodsID)
    end
end

function CoinShop_CanChangeHair()
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end

	if hPlayer.dwForceID == 1 and hPlayer.GetQuestState(7440) ~= QUEST_STATE.FINISHED then
		return false
	end
	return true
end


----------------------------CoinShop Log--------------------------------------------------------
local tLogTime = {}
local tCurLog = {}

function CoinShop_LogHomeTime()
    CoinShop_StartLogTime("A0", 1)
end

function CoinShop_LogOutfit()
    CoinShop_StartLogTime("T2", 1)
end

function CoinShop_LogCart()
    CoinShop_StartLogTime("T1", 1)
end

function CoinShop_LogVideo(dwGoodsID)
    CoinShop_StartLogTime("V", dwGoodsID)
end

function CoinShop_LogShopTime(szShopType, nType, nClass)
    if not nType or not nClass then
        return
    end
    local tLogType =
    {
        --[HOME_TYPE.EXTERIOR] = {"B1", 1}, --由于商城结构的更改，改成所有外装商店的log改成B3-nClass
        --[HOME_TYPE.EXTERIOR_COLLECT] = {"B1", 2},
        ["Shop"] = "A",
        ["MyExterior"] = "B",
    }

    local szType = tLogType[szShopType] .. nType
    CoinShop_StartLogTime(szType, nClass)
end

local function CoinShop_EndTheLogTime(szType, nID, tNewCurLog)
    tNewCurLog = tNewCurLog or tCurLog
    local szType = szType or tNewCurLog.szType
    local nID = nID or tNewCurLog.nID
    if not szType or not nID then
        return
    end
    local nCurTime = GetTickCount()
    if not tLogTime[szType] then
        tLogTime[szType] = {}
    end

    if not tLogTime[szType][nID] then
        tLogTime[szType][nID] = 0
    end

    local nTime = nCurTime - tNewCurLog.nStartTime
    if tNewCurLog.nPauseTime then
        nTime = nTime - tNewCurLog.nPauseTime
    end

    tLogTime[szType][nID] = tLogTime[szType][nID] + nTime
    tNewCurLog = {}
end

local szLastType, nLastID
function CoinShop_StartLogTime(szType, nID)
    if szType == tCurLog.szType and nID == tCurLog.nID then
        return
    end
    if tCurLog.szType and tCurLog.nID then
        CoinShop_EndLogTime()
    end
    local nTime = GetTickCount()
    tCurLog.nStartTime = nTime
    tCurLog.szType = szType
    tCurLog.nID = nID
end

function CoinShop_EndLogTimeAndStartLast()
    if not tCurLog.szType or not tCurLog.nID then
        return
    end
    CoinShop_EndTheLogTime()
    if szLastType and nLastID then
        CoinShop_StartLogTime(szLastType, nLastID)
        szLastType = nil
        nLastID = nil
    end
end

function CoinShop_EndLogTime()
    if not tCurLog.szType or not tCurLog.nID then
        return
    end
    szLastType = tCurLog.szType
    nLastID = tCurLog.nID
    CoinShop_EndTheLogTime()
end

--[[
    新品速递
    时间："N"+0+time
    次数："N"+nID+Count
]]

local tIndependCurLog = {}
function CoinShop_StartIndependLogTime(szType, nID)
    if tIndependCurLog[szType] and tIndependCurLog[szType][nID] then
        return
    end
    local nTime = GetTickCount()
    tIndependCurLog[szType] = tIndependCurLog[szType] or {}
    tIndependCurLog[szType][nID] = {}
    tIndependCurLog[szType][nID].nStartTime = nTime
end

function CoinShop_EndIndependLogTime(szType, nID)
    if not tIndependCurLog[szType] or not tIndependCurLog[szType][nID] then
        return
    end
    CoinShop_EndTheLogTime(szType, nID, tIndependCurLog[szType][nID])
end

local tCountLog = {}
function CoinShop_AddLogCount(szType, nID)
    tCountLog[szType] = tCountLog[szType] or {}
    tCountLog[szType][nID] = tCountLog[szType][nID] or 0
    tCountLog[szType][nID] = tCountLog[szType][nID] + 1
end

function CoinShop_LogToServer()
    for szType, tTime in pairs(tLogTime) do
        for nID, nTime in pairs(tTime) do
            nTime = math.floor(nTime / 1000 + 0.5)
            if nTime > 0 then
                GetCoinShopClient().LogBrowseCoinShop(szType, nID, nTime)
            end
        end
    end

    for szType, tLog in pairs(tCountLog) do
        for nID, nCount in pairs(tLog) do
            GetCoinShopClient().LogBrowseCoinShop(szType, nID, nCount)
        end
    end
    tLogTime = {}
    tCurLog = {}
    tIndependCurLog = {}
    tCountLog = {}
end

function CoinShop_OutputLogTime()
    Output("LogTime", tLogTime)
end

--获取商品类型
function CoinShop_GetSubType(dwGoodsID, eGoodsType)
	local hExteriorClient = GetExterior()
    if not hExteriorClient then
        return
    end

	local szSub = ""
	if eGoodsType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
		local tExteriorInfo = hExteriorClient.GetExteriorInfo(dwGoodsID)
		szSub = g_tStrings.tExteriorSub[tExteriorInfo.nSubType]
	elseif eGoodsType == COIN_SHOP_GOODS_TYPE.ITEM then
		local tItem = {
			dwTabType = eGoodsType,
			dwIndex = dwGoodsID,
		}
		szSub = CoinShop_GetRewardsType(tItem)
	else
		szSub = g_tStrings.tGoodsType[eGoodsType]
	end
	return szSub
end

local tCoinShopTypePendentHead =
{
    COINSHOP_BOX_INDEX.HEAD_EXTEND,       --头饰
    COINSHOP_BOX_INDEX.HEAD_EXTEND1,      --头饰
    COINSHOP_BOX_INDEX.HEAD_EXTEND2,      --头饰
}

function CoinShop_PendentHeadType()
    return tCoinShopTypePendentHead
end

--------------------------------Groupon--------------------------------
--是否有团购活动
function _G.CoinShop_IsHaveGrouponActivity()
	local tTemplateInfo = GetCoinShopGrouponClient().GetTemplateInfoTable()
	local nTime = GetGSCurrentTime()
	for k, tInfo in ipairs(tTemplateInfo) do
		if (tInfo.nBeginTime <= nTime or tInfo.nBeginTime == -1 ) and (tInfo.nEndTime >= nTime or tInfo.nEndTime == -1) then
			return true
		end
	end
	return false
end

--我是否在拼团中
function _G.CoinShop_IsInGroupon(eGoodsType, dwGoodsID)
	local bIn = false
    if eGoodsType and dwGoodsID then
        local nOwnType = GetCoinShopClient().CheckAlreadyHave(eGoodsType, dwGoodsID)
        if nOwnType == COIN_SHOP_OWN_TYPE.GROUPON then
           return true
        end
        -- if eGoodsType == COIN_SHOP_GOODS_TYPE.EXTERIOR then --7天外观的特殊处理
        --     local nOwnType = GetCoinShopClient().CheckAlreadyHave(COIN_SHOP_GOODS_TYPE.RENEW, dwGoodsID)
        --     if nOwnType == COIN_SHOP_OWN_TYPE.GROUPON then
        --         return true
        --     end
        -- end
	end
	return bIn
end

--获取模板信息
function _G.CoinShop_GetTemplateInfo(dwTemplateID)
	local tTemplateInfo 	= GetCoinShopGrouponClient().GetTemplateInfoTable()
	for _, tInfo in ipairs(tTemplateInfo) do
		if tInfo.dwTemplateID == dwTemplateID then
			return tInfo
		end
	end
end

--宠物是否在商城中售卖
function _G.CoinShop_PetIsInShop(nPetIndex)
	 local dwLogicID = Table_GetRewardsPetGoodID(nPetIndex)
     if dwLogicID then
        return CoinShop_CanBuy(COIN_SHOP_GOODS_TYPE.ITEM, dwLogicID), dwLogicID
     end
     return false
end

--坐骑是否在商城中售卖
function _G.CoinShop_HorseIsInShop(dwTabType, dwIndex)
    local dwLogicID = Table_GetRewardsGoodID(dwTabType, dwIndex)
    if dwLogicID then
       return CoinShop_CanBuy(COIN_SHOP_GOODS_TYPE.ITEM, dwLogicID), dwLogicID
    end
    return false
end

--获取当前代币
function _G.GetCurrentCoinShopVoucher()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    --中迪保证过当前最多只有一种代币
    local aList = hPlayer.GetAllCoinShopVoucher()
    local tFristVoucher
    for i, tVoucher in ipairs(aList) do
        if not tFristVoucher then
            tFristVoucher = tVoucher
        elseif tFristVoucher.dwVoucherID == tVoucher.dwVoucherID then
            tFristVoucher.nCount = tFristVoucher.nCount + tVoucher.nCount
        end
    end
    return tFristVoucher
end

--获取当前代币ID
function _G.GetCurrentCoinShopVoucherID()
    local tVoucher = GetCurrentCoinShopVoucher()
    if tVoucher then
        return tVoucher.dwVoucherID
    end
end

--获取玩家所有外观，除去已删除的
function _G.GetPlayerAllExterior()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return 0
    end

    local tAllExterior = hPlayer.GetAllExterior()
    local tNewExterior = {}
    for _, tExterior in ipairs(tAllExterior) do
        if tExterior.nHideFlag ~= EXTERIOR_HIDE_TYPE.DELETE then
            table.insert(tNewExterior, tExterior)
        end
    end
    return tNewExterior
end

--是否是体型类型
function _G.CoinShop_IsBodyType(nType, nClass)
    return nType == UI_COIN_SHOP_GOODS_TYPE_OTHER and nClass == UI_COIN_SHOP_OTHER_CLASS.BODY
end

--是否是新脸型类型
function _G.CoinShop_IsNewFaceType(nType, nClass)
    return nType == UI_COIN_SHOP_GOODS_TYPE_OTHER and nClass == UI_COIN_SHOP_OTHER_CLASS.NEW_FACE
end

--获得待机动作的表现ID
function _G.GetActionRepresentID(dwActionID, dwRepresentID, hIdleActionSettings)
    if not dwRepresentID then
        if dwActionID == 0 then
            dwRepresentID = 0
        else
            if not hIdleActionSettings then
                hIdleActionSettings = GetPlayerIdleActionSettings()
            end
            local tInfo = hIdleActionSettings.GetPriceInfo(dwActionID)
            if not tInfo then
                return
            end
            dwRepresentID = tInfo.dwRepresentID
        end
    end
    return dwRepresentID
end

--处理不勾选显示面部装饰物的情况
function _G.DealWithDecorationShowFlag(tFaceData)
    local bShowFlag = GetFaceLiftManager().GetDecorationShowFlag()
    if not bShowFlag and tFaceData then
        if tFaceData.tDecoration then
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
        if tFaceData.nDecorationID then
            tFaceData.nDecorationID = 0
        end
    end
end
----------------------------CoinShop Log--------------------------------------------------------

function CoinShop_OnEvent(szEvent)
    if szEvent == "COIN_SHOP_BUY_RESPOND" or
    szEvent == "COIN_SHOP_SAVE_RESPOND" or
    szEvent == "COIN_SHOP_PACK_NOTIFY" or
    szEvent == "COIN_SHOP_REPLACE_NOTIFY"
    then
        local szChannel = "MSG_ANNOUNCE_NORMAL"
        if arg0 == COIN_SHOP_ERROR_CODE.SUCCESS or
            arg0 == COIN_SHOP_ERROR_CODE.TAKE_BOX_GOODS_SUCCESS then
            szChannel = "MSG_ANNOUNCE_NORMAL"
        end
        local  szMsg = ""
        if szEvent == "COIN_SHOP_BUY_RESPOND" then
            szMsg = g_tStrings.tCoinShopBuyNotify[arg0]
        elseif szEvent == "COIN_SHOP_SAVE_RESPOND" then
            szMsg = g_tStrings.tCoinShopSaveNotify[arg0]
        elseif szEvent == "COIN_SHOP_PACK_NOTIFY" then
            szMsg = g_tStrings.tCoinShopPackNotify[arg0]
        elseif szEvent == "COIN_SHOP_REPLACE_NOTIFY" then
            szMsg = g_tStrings.tCoinShopReplaceNotify[arg0]
        end
        OutputMessage(szChannel, szMsg)
        if arg0 ~= COIN_SHOP_ERROR_CODE.SUCCESS then
            --Event.UnReg(CoinShopBase, "COIN_SHOP_BUY_RESPOND", CoinShop_CheckOut.SelectDisAndBuy)
        end
    elseif szEvent == "EQUIP_LIFTED_FACE" then
        local hPlayer = GetClientPlayer()
        if hPlayer and hPlayer.dwID == arg0 then
            local szMsg = g_tStrings.EQUIP_LIFTED_SUCCESS
            OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
        end
    elseif szEvent == "EXTERIOR_COLLECT_RESULT" or szEvent == "WEAPON_EXTERIOR_COLLECT_RESULT" then
        local szMsg = g_tStrings.tCollectRespond[arg1]
        if arg1 ~= EXTERIOR_COLLECT_RESULT_CODE.SUCCESS then
            OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
        end
    elseif szEvent == "ADD_EXTERIOR_COLLECTION" then
        local szName = CoinShop_GetGoodsName(COIN_SHOP_GOODS_TYPE.EXTERIOR, arg0)
        local szMsg = FormatString(g_tStrings.COLLECT_SUCCESS, GBKToUTF8(szName))
        -- OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
        TipsHelper.ShowNormalTip(szMsg)--策划要求用Normal
    elseif szEvent == "ADD_WEAPON_EXTERIOR_COLLECTION" then
        local szName = CoinShop_GetGoodsName(COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR, arg0)
        local szMsg = FormatString(g_tStrings.COLLECT_SUCCESS, GBKToUTF8(szName))
        -- OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
        TipsHelper.ShowNormalTip(szMsg)--策划要求用Normal
    elseif szEvent == "FACE_LIFT_NOTIFY" then
        local nRetCode = arg0
        local szChannel = ""
        if nRetCode == FACE_LIFT_ERROR_CODE.BUY_SUCCESS then
            szChannel = "MSG_ANNOUNCE_NORMAL"
        else
            szChannel = "MSG_ANNOUNCE_NORMAL"
        end
        local szMsg = g_tStrings.tFaceLiftNotify[nRetCode]
        OutputMessage(szChannel, szMsg)
    elseif szEvent == "LIFTED_FACE_ADD" or szEvent == "LIFTED_FACE_CHANGE" then
        nRetCode = GetFaceLiftManager().Equip(arg0)
        if nRetCode ~= FACE_LIFT_ERROR_CODE.SUCCESS then
            OutputMessage("MSG_ANNOUNCE_NORMAL",g_tStrings.tFaceLiftNotify[nRetCode])
        end
    elseif szEvent == "ON_BUY_ITEM_ORDER_MESSAGE_NOTIFY" then
        if arg0 == BUY_ITEM_ORDER_NOTIFY_CODE.ORDER_IS_OVERDUE or
            arg0 == BUY_ITEM_ORDER_NOTIFY_CODE.ORDER_IS_DELETED
        then
            local szMsg = g_tStrings.tCoinshopOrderNotify[arg0]
            local tMsg =
            {
                bModal = true,
                szName = "coinsho_order_overdue_pay",
                szMessage = szMsg,
                {szOption = g_tStrings.STR_HOTKEY_SURE},
            }
            MessageBox(tMsg)
        end
    elseif szEvent == "COIN_SHOP_PRESET_INFO_CHANGED" then
        local nMode = arg2
        local szMsg = ""
        if nMode == COIN_SHOP_PRESET_NOTIFY_MODE.ADD then
            szMsg = g_tStrings.tCoinShopPresetNotify[COIN_SHOP_PRESET_ERROR_CODE.SUCCESS]
        elseif nMode == COIN_SHOP_PRESET_NOTIFY_MODE.DELETE then
            szMsg = g_tStrings.COIN_SHOP_PRESET_DELETE
        elseif nMode == COIN_SHOP_PRESET_NOTIFY_MODE.REPLACE then
            szMsg = g_tStrings.COIN_SHOP_PRESET_REPLACE
        end
        OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
    elseif szEvent == "COIN_SHOP_CART_INFO_CHANGED" then
        local bAdd = arg2
        local szMsg = ""
        if bAdd then
            szMsg = g_tStrings.tCoinShopCartNotify[COIN_SHOP_PRESET_ERROR_CODE.SUCCESS]
        else
            szMsg = g_tStrings.COIN_SHOP_CART_DELETE
        end
        OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
    elseif szEvent == "COIN_SHOP_BUY_PRE_ORDER_GOODS_RESPOND" then
        local nErrorCode = arg1
        local dwPreOrderID = arg4
        if nErrorCode == COIN_SHOP_ERROR_CODE.NOT_HAVE_PREORDER_COUPON then
            local tLine = CoinShop_GetPreOrder(dwPreOrderID)
            if tLine then
                OutputMessage("MSG_ANNOUNCE_NORMAL", tLine.szErrorMsg)
            end
        end
    elseif szEvent == "ON_COIN_SHOP_RECOMMENDATION_NOTIFY" then
        if arg0 ~= COIN_SHOP_RECOMMENDATION_ERROR_CODE.SUCCESS then
            OutputMessage("MSG_ANNOUNCE_NORMAL",g_tStrings.tCoinShopRecommendationNotify[arg0])
            CoinShop_Recommend.Close()
        end

    elseif szEvent == "ON_COIN_SHOP_GROUPON_CODE_NOTIFY" then
        local szMsg = g_tStrings.tCoinShopGrouponNotify[arg0]
        local szMsgWarn = g_tStrings.tCoinShopGrouponWarn[arg0]
        if szMsg then
            OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
        elseif szMsgWarn then
            OutputMessage("MSG_ANNOUNCE_NORMAL", szMsgWarn)
        end
    elseif szEvent == "ON_CHANGE_BODY_BONE_NOTIFY" then
        local szChannel = "MSG_ANNOUNCE_NORMAL"
        local szMsg = ""
        local nMethod = arg1
        local nCode = BODY_RESHAPING_ERROR_CODE.SUCCESS
        if nMethod == BODY_RESHAPING_OPERATE_METHOD.ADD then
            szMsg = g_tStrings.tBodyBuyNotify[nCode]
        elseif nMethod == BODY_RESHAPING_OPERATE_METHOD.REPLACE then
            szMsg = g_tStrings.tBodyReplaceNotify[nCode]
        -- elseif nMethod == BODY_RESHAPING_OPERATE_METHOD.DELETE then
        end
        OutputMessage(szChannel, szMsg)
        OutputMessage("MSG_SYS", szMsg)

        local hManager = GetBodyReshapingManager()
        if not hManager then
            return
        end
        if nMethod == BODY_RESHAPING_OPERATE_METHOD.ADD or
            nMethod == BODY_RESHAPING_OPERATE_METHOD.REPLACE then
            local nRetCode = hManager.Equip(arg0)
            if nRetCode ~= BODY_RESHAPING_ERROR_CODE.SUCCESS then
                OutputMessage("MSG_SYS",g_tStrings.tBodyEquipNotify[nRetCode])
                OutputMessage("MSG_ANNOUNCE_NORMAL",g_tStrings.tBodyEquipNotify[nRetCode])
            end
        end
    elseif szEvent == "ON_EQUIP_BODY_BONE_NOTIFY" then
        local szChannel = "MSG_ANNOUNCE_NORMAL"
        local nCode = BODY_RESHAPING_ERROR_CODE.SUCCESS
        local szMsg = g_tStrings.tBodyEquipNotify[nCode]
        OutputMessage(szChannel, szMsg)
        OutputMessage("MSG_SYS", szMsg)
    elseif szEvent == "LIFTED_FACE_ADD_V2" or szEvent == "LIFTED_FACE_CHANGE_V2" then
        local nRetCode = GetFaceLiftManager().Equip(arg0)
        if nRetCode ~= FACE_LIFT_ERROR_CODE.SUCCESS then
            OutputMessage("MSG_SYS",g_tStrings.tNewFaceLiftNotify[nRetCode])
            OutputMessage("MSG_ANNOUNCE_NORMAL",g_tStrings.tNewFaceLiftNotify[nRetCode])
        end
    elseif szEvent == "ON_CHANGE_HAIR_CUSTOM_DYEING_NOTIFY" then
        local szChannel = "MSG_ANNOUNCE_YELLOW"
        local szMsg = ""
        local dwHairID = arg0
        local nIndex = arg1
        local nMethod = arg2
        local nCode = HAIR_CUSTOM_DYEING_ERROR_CODE.SUCCESS
        if nMethod == HAIR_CUSTOM_DYEING_OPERATE_METHOD.ADD then
            szMsg = g_tStrings.tHairDyeingBuyNotify[nCode]
        elseif nMethod == HAIR_CUSTOM_DYEING_OPERATE_METHOD.REPLACE then
            szMsg = g_tStrings.tHairDyeingReplaceNotify[nCode]
        -- elseif nMethod == HAIR_CUSTOM_DYEING_OPERATE_METHOD.DELETE then
        end
        OutputMessage(szChannel, szMsg)
        OutputMessage("MSG_SYS", szMsg)

        local hManager = GetHairCustomDyeingManager()
        if not hManager then
            return
        end
        if nMethod == HAIR_CUSTOM_DYEING_OPERATE_METHOD.ADD or
            nMethod == HAIR_CUSTOM_DYEING_OPERATE_METHOD.REPLACE then
                local nRetCode = hManager.Equip(dwHairID, nIndex)
                if nRetCode ~= HAIR_CUSTOM_DYEING_ERROR_CODE.SUCCESS then
                    OutputMessage("MSG_SYS",g_tStrings.tHairDyeingEquipNotify[nRetCode])
                    OutputMessage("MSG_ANNOUNCE_RED",g_tStrings.tHairDyeingEquipNotify[nRetCode])
                end
        end
    elseif szEvent == "ON_EQUIP_HAIR_CUSTOM_DYEING_NOTIFY" then
        local szChannel = "MSG_ANNOUNCE_YELLOW"
        local nCode = HAIR_CUSTOM_DYEING_ERROR_CODE.SUCCESS
        local dwPlayerID = arg0
        local dwHairID = arg1
        local nIndex = arg2
        if dwPlayerID == UI_GetClientPlayerID() then
            local szMsg = g_tStrings.tHairDyeingEquipNotify[nCode]
            OutputMessage(szChannel, szMsg)
            OutputMessage("MSG_SYS", szMsg)
        end
    elseif szEvent == "ON_HAIR_CUSTOM_DYEING_ERROR_CODE_NOTIFY" then
        local szChannel = "MSG_ANNOUNCE_RED"
        local nCode = arg0
        if nCode ~= HAIR_CUSTOM_DYEING_ERROR_CODE.SUCCESS then
            local szMsg = g_tStrings.tHairDyeingBuyNotify[nCode]
            OutputMessage(szChannel, szMsg)
            OutputMessage("MSG_SYS", szMsg)
        end
    end
end

Event.Reg(CoinShopBase, "COIN_SHOP_BUY_RESPOND", function() CoinShop_OnEvent("COIN_SHOP_BUY_RESPOND") end)
Event.Reg(CoinShopBase, "COIN_SHOP_SAVE_RESPOND", function() CoinShop_OnEvent("COIN_SHOP_SAVE_RESPOND") end)
Event.Reg(CoinShopBase, "EQUIP_LIFTED_FACE", function() CoinShop_OnEvent("EQUIP_LIFTED_FACE") end)
Event.Reg(CoinShopBase, "EXTERIOR_COLLECT_RESULT", function() CoinShop_OnEvent("EXTERIOR_COLLECT_RESULT") end)
Event.Reg(CoinShopBase, "WEAPON_EXTERIOR_COLLECT_RESULT", function() CoinShop_OnEvent("WEAPON_EXTERIOR_COLLECT_RESULT") end)
Event.Reg(CoinShopBase, "ADD_EXTERIOR_COLLECTION", function() CoinShop_OnEvent("ADD_EXTERIOR_COLLECTION") end)
Event.Reg(CoinShopBase, "ADD_WEAPON_EXTERIOR_COLLECTION", function() CoinShop_OnEvent("ADD_WEAPON_EXTERIOR_COLLECTION") end)
Event.Reg(CoinShopBase, "FACE_LIFT_NOTIFY", function() CoinShop_OnEvent("FACE_LIFT_NOTIFY") end)
Event.Reg(CoinShopBase, "LIFTED_FACE_ADD", function() CoinShop_OnEvent("LIFTED_FACE_ADD") end)
Event.Reg(CoinShopBase, "LIFTED_FACE_CHANGE", function() CoinShop_OnEvent("LIFTED_FACE_CHANGE") end)
Event.Reg(CoinShopBase, "COIN_SHOP_PACK_NOTIFY", function() CoinShop_OnEvent("COIN_SHOP_PACK_NOTIFY") end)
Event.Reg(CoinShopBase, "COIN_SHOP_REPLACE_NOTIFY", function() CoinShop_OnEvent("COIN_SHOP_REPLACE_NOTIFY") end)
Event.Reg(CoinShopBase, "ON_BUY_ITEM_ORDER_MESSAGE_NOTIFY", function() CoinShop_OnEvent("ON_BUY_ITEM_ORDER_MESSAGE_NOTIFY") end)
Event.Reg(CoinShopBase, "COIN_SHOP_PRESET_INFO_CHANGED", function() CoinShop_OnEvent("COIN_SHOP_PRESET_INFO_CHANGED") end)
Event.Reg(CoinShopBase, "COIN_SHOP_CART_INFO_CHANGED", function() CoinShop_OnEvent("COIN_SHOP_CART_INFO_CHANGED") end)
Event.Reg(CoinShopBase, "COIN_SHOP_BUY_PRE_ORDER_GOODS_RESPOND", function() CoinShop_OnEvent("COIN_SHOP_BUY_PRE_ORDER_GOODS_RESPOND") end)
Event.Reg(CoinShopBase, "ON_COIN_SHOP_RECOMMENDATION_NOTIFY", function() CoinShop_OnEvent("ON_COIN_SHOP_RECOMMENDATION_NOTIFY") end)
Event.Reg(CoinShopBase, "ON_COIN_SHOP_GROUPON_CODE_NOTIFY", function() CoinShop_OnEvent("ON_COIN_SHOP_GROUPON_CODE_NOTIFY") end)
Event.Reg(CoinShopBase, "ON_CHANGE_BODY_BONE_NOTIFY", function(szEvent) CoinShop_OnEvent("ON_CHANGE_BODY_BONE_NOTIFY") end)
Event.Reg(CoinShopBase, "ON_EQUIP_BODY_BONE_NOTIFY", function(szEvent) CoinShop_OnEvent("ON_EQUIP_BODY_BONE_NOTIFY") end)
Event.Reg(CoinShopBase, "LIFTED_FACE_ADD_V2", function(szEvent) CoinShop_OnEvent("LIFTED_FACE_ADD_V2") end)
Event.Reg(CoinShopBase, "LIFTED_FACE_CHANGE_V2", function(szEvent) CoinShop_OnEvent("LIFTED_FACE_CHANGE_V2") end)
Event.Reg(CoinShopBase, "ON_CHANGE_HAIR_CUSTOM_DYEING_NOTIFY", function(szEvent) CoinShop_OnEvent("ON_CHANGE_HAIR_CUSTOM_DYEING_NOTIFY") end)
Event.Reg(CoinShopBase, "ON_EQUIP_HAIR_CUSTOM_DYEING_NOTIFY", function(szEvent) CoinShop_OnEvent("ON_EQUIP_HAIR_CUSTOM_DYEING_NOTIFY") end)
Event.Reg(CoinShopBase, "ON_HAIR_CUSTOM_DYEING_ERROR_CODE_NOTIFY", function(szEvent) CoinShop_OnEvent("ON_HAIR_CUSTOM_DYEING_ERROR_CODE_NOTIFY") end)

local function OnClientPlayerEnter()
    RegisterHairShopTable()
    RegisterRewardsShopTable()
    RegisterCoinshopTitleTable()
    RegisterCoinshopWeaponTable()
    RegisterCoinshopWeaponSrc()
    RegisterCoinshopExteriorSrc()
    LoadExteriorMap()
    RegisterCoinshopLimitTable()
    RegisterCloakColorChangeTable()
    RegisterCoinShopHomeTable()
    RegisterCoinShopMixTable()
    -- RegisterCoinShopTopicsTable()
    RegisterCoinShopRankTable()
    RegisterCoinShopFaceLiftIndexTable()
    RegisterHorseAdornmentIndexTable()
    RegisterViewLightTable()
    RegisterPreOrderTable()
    RegisterPendantPetTable()
    RegisterFurnitureShopInfo()
    RegisterCoinShopNewsTable()
    RegisterCoinShopHomeSetTable()
    RegisterCoinShopHairSubsetTable()
    RegisterCoinShopExteriorSubsetTable()
    CoinShop_GetNowWeaponID()

    CoinShopData.GetShopWeapon()
    CoinShopData.GetList()
    CoinShopData.GetExteriorList(1)
end

local function OnLoadingEnd()
    RegisterHairShopTable()
end

Event.Reg(CoinShopBase, EventType.OnClientPlayerEnter, OnClientPlayerEnter)
Event.Reg(CoinShopBase, "LOADING_END", OnLoadingEnd)
Event.Reg(CoinShopBase, "GAME_EXIT", CoinShop_SaveOutfitData)
Event.Reg(CoinShopBase, "UI_LUA_RESET", CoinShop_SaveOutfitData)

local function OnLoadCustomData()
    if arg0 == "Role" then
        if not g_tCoinShopData.tPackageIndex.nVersion then
            g_tCoinShopData.tPackageIndex = {nVersion = 1.0}
        end
    end
end
Event.Reg(CoinShopBase, "CUSTOM_DATA_LOADED", OnLoadCustomData)

local function GetNowWeaponType()
	local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local hItem = hPlayer.GetItem(INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.MELEE_WEAPON)
    if hItem then
        return hItem.nDetail
    end
end

local function GetNowWeaponExterior()
	local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local nCurrentSetID = hPlayer.GetCurrentSetID()
    local tWeaponExterior = hPlayer.GetWeaponExteriorSet(nCurrentSetID)
    return tWeaponExterior[WEAPON_EXTERIOR_BOX_INDEX_TYPE.MELEE_WEAPON]
end

function CoinShop_GetNowWeaponID()
    local dwWeaponID = GetNowWeaponExterior()
    local nWeaponType = GetNowWeaponType()
    if nWeaponType then
        Storage.Character.tWeaponExterior[nWeaponType] = dwWeaponID
    end
end

function CoinShop_ChangeWeaponExterior()
    if arg1 ~= EQUIPMENT_INVENTORY.MELEE_WEAPON then
        return
	end
	local nWeaponType = GetNowWeaponType()
	if not nWeaponType then
		return
	end
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
	if Storage.Character.tWeaponExterior[nWeaponType] then
        local dwWeaponID = GetNowWeaponExterior()
        local dwNewWeaponID = Storage.Character.tWeaponExterior[nWeaponType]
        if dwWeaponID ~= dwNewWeaponID then
            local bHave = hPlayer.IsHaveWeaponExterior(dwNewWeaponID)
            if not bHave then
                return
            end
            local tOutfit = {
                eGoodsType = COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR,
                dwGoodsID = dwNewWeaponID,
                ePayType = COIN_SHOP_PAY_TYPE.INVALID,
            }
            local tChangeList = {}
            table.insert(tChangeList, tOutfit)
            GetCoinShopClient().Save(tChangeList)
        end
	end
end
Event.Reg(CoinShopBase, "COIN_SHOP_SAVE_RESPOND", CoinShop_GetNowWeaponID)
Event.Reg(CoinShopBase, "EQUIP_ITEM_UPDATE", CoinShop_ChangeWeaponExterior)

function GetEquippedHairCustomDyeingIndex(nHair)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local nNowDyeingIndex = hPlayer.GetEquippedHairCustomDyeingIndex(nHair)
    if nNowDyeingIndex == -1 then
        nNowDyeingIndex = 0
    end
    return nNowDyeingIndex
end

function CoinShop_CheckHaveDisCouponForGoodList(tList)
    local tWelfareList = CoinShopData.GetWelfares()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local tHash = {}
    for _, tGoods in ipairs(tList) do
       if CoinShop_CheckHaveDisCouponForGoods(tGoods.eGoodsType, tGoods.dwGoodsID, tWelfareList) then
            return true
        end
    end
end

function CoinShop_CheckHaveDisCouponForGoods(eGoodsType, dwGoodsID, tWelfareList)
    if not tWelfareList then
        tWelfareList = CoinShopData.GetWelfares()
    end
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local tHash = {}
    for i, card in ipairs_r(tWelfareList) do
        local dwDisCouponID = card.dwDisCouponID
        local tInfo = CoinShop_GetPriceInfo(dwGoodsID, eGoodsType)
        if hPlayer.CheckCanUseDisCouponForGoods(dwDisCouponID, eGoodsType, dwGoodsID) and not tInfo.bForbidDisCoupon then
            -- local tDisCoupon = CoinShopData.GetWelfare(dwDisCouponID)
            -- if card.nType == COIN_SHOP_DISCOUNT_TYPE.DISCOUNT or card.nType == COIN_SHOP_DISCOUNT_TYPE.FULL_CUT then
				return true
			-- end
        end
    end
end