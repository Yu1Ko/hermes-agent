-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: ShareExteriorData
-- Date: 2025-09-25 15:28:47
-- Desc: ?
-- ---------------------------------------------------------------------------------
local nVersion = 1

local DEFAULT_CUSTOM_DATA = {
    fScale = 1,
    nOffsetX = 0, nOffsetY = 0, nOffsetZ = 0,
    fRotationX = 0, fRotationY = 0, fRotationZ = 0,
}

-- 同一部位存在多个位置的挂件
local tMultiPosPendantKey = {
    EQUIPMENT_REPRESENT.HEAD_EXTEND,       -- 1号头饰
    EQUIPMENT_REPRESENT.HEAD_EXTEND1,      -- 2号头饰
    EQUIPMENT_REPRESENT.HEAD_EXTEND2,      -- 3号头饰
}

local tRoleName =
{
    [1] = "StandardMale",
    [2] = "StandardFemale",
    [5] = "LittleBoy",
    [6] = "LittleGirl",
}

local tShareFilterFlag_Color = {
    ["Color1"]       = {EQUIPMENT_REPRESENT.HAIR_STYLE},     -- 发型染色标记
    ["Color3"]       = {EQUIPMENT_REPRESENT.HELM_STYLE},     -- 外装收集-帽子染色标记
    ["Color5"]       = {EQUIPMENT_REPRESENT.CHEST_STYLE},     -- 成衣染色标记
}

local tShareFilterFlag_Custom = {
    ["CustomHead"]   = {EQUIPMENT_REPRESENT.HEAD_EXTEND, EQUIPMENT_REPRESENT.HEAD_EXTEND1, EQUIPMENT_REPRESENT.HEAD_EXTEND2}, -- 头部挂件自定义标记
    ["Custom24"]     = {EQUIPMENT_REPRESENT.BACK_EXTEND},   -- 背部挂件自定义标记
    ["Custom25"]     = {EQUIPMENT_REPRESENT.WAIST_EXTEND},   -- 腰部挂件自定义标记
    ["Custom31"]     = {EQUIPMENT_REPRESENT.FACE_EXTEND},   -- 面部挂件自定义标记
    ["Custom34"]     = {EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND},   -- 披风挂件自定义标记
    ["Custom40"]     = {EQUIPMENT_REPRESENT.BAG_EXTEND},   -- 佩囊挂件自定义标记
    ["Custom43"]     = {EQUIPMENT_REPRESENT.GLASSES_EXTEND},   -- 眼饰挂件自定义标记
}

local function AdjustDataPath(szPath)
    local szAdjust = szPath .. ".dat"
    if Platform.IsWindows() then
        if not Lib.IsFileExist(UIHelper.UTF8ToGBK(szAdjust), false) then
            return szAdjust
        end
    else
        if not Lib.IsFileExist(szAdjust, false) then
            return szAdjust
        end
	end
    
    for i = 1, 100 do
        local szAdjust = szPath .. "(" .. i.. ")" .. ".dat"
        if not Lib.IsFileExist(szAdjust, false) then
            return szAdjust
        end
    end
    local nTickCount = GetTickCount()
    local szAdjust = szPath .. "(" .. nTickCount.. ")" .. ".dat"
    return szAdjust
end

local tPendantType = {
	[1] = {szType = "Head"},
	[2] = {szType = "Face"},
	[3] = {szType = "Glasses"},
	[4] = {szType = "BackCloak"},
    [5] = {szType = "PendantPet"},
	[7] = {szType = "LShoulder"},
	[8] = {szType = "RShoulder"},
	[9] = {szType = "LHand"},
	[10] = {szType = "RHand"},
	[11] = {szType = "Back"},
	[12] = {szType = "Waist"},
}

-- 缓存限时成衣列表（对应 UI 端的 m_aAllLimitChest）
local m_aAllLimitChest

ShareExteriorData = ShareExteriorData or {className = "ShareExteriorData"}
local self = ShareExteriorData

function ShareExteriorData.Init()
    ShareExteriorData.tList = {}
    local nCount = g_tTable.PendantNew:GetRowCount()
	local tRes = {}
	for i = 2, nCount do
		local tLine = g_tTable.PendantNew:GetRow(i)
		if tLine.szType then
			tRes[tLine.szType] = tRes[tLine.szType] or {}
            table.insert(tRes[tLine.szType], tLine)
		end
	end
    ShareExteriorData.tList = tRes
end

function ShareExteriorData.UnInit()
    ShareExteriorData.tList = nil
    ShareExteriorData.tEffectFilterList = nil
    ShareExteriorData.tEffectSubList = nil
    -- 清理缓存
    m_aAllLimitChest = nil
end

function ShareExteriorData.SaveExteriorData(tExterior, nRoleType)
    local tData = {}

    tData.nVersion = nVersion
    tData.tExterior = clone(tExterior)
    tData.nRoleType = nRoleType

    local szShareStationDir = GetFullPath("ShareStationDataDir")
    if SM_IsEnable() then
        local szRegion, szServer = select(5, GetUserServer())
        local szAccount = GetUserAccount()
        szShareStationDir = "userdata".."/"..szAccount.."/"..szRegion.."/"..szServer.."/".."ShareStationDataDir"
        CPath.MakeDir(szShareStationDir)
    end

    local szSuffix = tRoleName[nRoleType]
    local nTime = GetCurrentTime()

    local time = TimeToDate(nTime)
    local szTime = string.format("%d%02d%02d-%02d%02d%02d", time.year, time.month, time.day, time.hour, time.minute, time.second)
    local szFileName = "Exterior_" .. szSuffix .."_" .. szTime

    local szPath = szShareStationDir .. "/" .. szFileName
    szPath = AdjustDataPath(szPath)
    SaveLUAData(szPath, tData)

    return szPath, nVersion
end

function ShareExteriorData.LoadExteriorData(szFile)
    local tData = LoadLUAData(szFile, false, true, nil, true)
    if not tData or not tData.tExterior then
        return
    end

    local tExterior = tData.tExterior
    if not tExterior.tExteriorID or not tExterior.tDetail then
        return
    end

    if not tData.nVersion then
        return
    end

    return tData
end

local function MatchRepresentKey(tRepresentID, tReplaceKeyList)
    for _, tKey in ipairs(tReplaceKeyList) do
        if tRepresentID[tKey[1]] ~= tKey[2] then
            return false
        end
    end
    return true
end

-- 获取明教兜帽状态
function ShareExteriorData.GetMingJiaoHatState()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    
    if pPlayer.dwForceID == FORCE_TYPE.MING_JIAO then
        return pPlayer.IsSecondRepresent(INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.CHEST)
    end
    return false
end

-- 门派ID参数的上传规则：如果玩家身上穿了校服类的外装收集，不论穿的是哪个门派的，都默认上传玩家自己的门派ID。
function ShareExteriorData.GetForceID(tExteriorData)
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return 0
    end
    
    local hExterior = GetExterior()
    if not hExterior then
        return 0
    end
    
    local tExteriorID = tExteriorData.tExteriorID
    for nSub, nExteriorID in pairs(tExteriorID) do
        if Exterior_RepresentSubToEquipSub(nSub) then
            if nExteriorID == -1 then --穿着别的门派的装备，取不到外观ID
                return pPlayer.dwForceID
            elseif nExteriorID > 0 and nSub ~= EQUIPMENT_REPRESENT.WEAPON_STYLE and nSub ~= EQUIPMENT_REPRESENT.BIG_SWORD_STYLE then
                local tInfo = hExterior.GetExteriorInfo(nExteriorID)
                if tInfo.nGenre == EXTERIOR_GENRE.SCHOOL and tInfo.nForceID ~= 0 then --穿着自己门派的校服
                    return pPlayer.dwForceID
                end
            end
        end
    end
    return 0
end



---------------设计站搭配数据相关----------------

local tNormalPendantKey = {
    EQUIPMENT_REPRESENT.BACK_EXTEND,       -- 背部挂件
    EQUIPMENT_REPRESENT.WAIST_EXTEND,      -- 腰部挂件
    EQUIPMENT_REPRESENT.FACE_EXTEND,       -- 面部挂件
    EQUIPMENT_REPRESENT.L_SHOULDER_EXTEND, -- 左肩饰
    EQUIPMENT_REPRESENT.R_SHOULDER_EXTEND, -- 右肩饰
    EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND, -- 披风
    EQUIPMENT_REPRESENT.BAG_EXTEND,        -- 佩囊
    EQUIPMENT_REPRESENT.GLASSES_EXTEND,    -- 眼饰
    EQUIPMENT_REPRESENT.L_GLOVE_EXTEND,    -- 左手饰
    EQUIPMENT_REPRESENT.R_GLOVE_EXTEND,    -- 右手饰
    EQUIPMENT_REPRESENT.HEAD_EXTEND,       -- 1号头饰
    EQUIPMENT_REPRESENT.HEAD_EXTEND1,      -- 2号头饰
    EQUIPMENT_REPRESENT.HEAD_EXTEND2,      -- 3号头饰
}

-- 获取包身状态
function ShareExteriorData.GetViewReplaceState(tRepresentID)
    local bCanReplace = false
    local bViewReplace = false
    local tViewReplace = Table_ViewReplace()
    for _, tLine in ipairs(tViewReplace) do
        if MatchRepresentKey(tRepresentID, tLine.tKey) then
            bCanReplace = true
            break
        elseif MatchRepresentKey(tRepresentID, tLine.tReplace) then
            bViewReplace = true
            break
        end
    end
    return bCanReplace, bViewReplace
end

-- 获取所有和外观道具相关联的礼盒道具
function ShareExteriorData.GetAllRelateItemPack(nItemType, dwItemIndex)
    local tVisited = {}
    local tResult = {}
    local Queue = {}

    local function make_item_key(nType, dwIndex)
        return string.format("%d_%d", nType, dwIndex)
    end
    
    -- 初始节点
    local StartItem = {nItemType, dwItemIndex}
    table.insert(Queue, StartItem)
    tVisited[make_item_key(nItemType, dwItemIndex)] = true
    
    --道具并不一定只包一层，存在包多层的情况，比如可选色盒子。因此使用广度优先搜索找到所有和道具相关联的礼盒道具
    local nPos = 0
    while #Queue > 0 do
        local Current = table.remove(Queue, 1) -- 从队列头部取出

        local nCurItemType = Current[1]
        local dwCurItemIndex = Current[2]
        local itemInfo = GetItemInfo(nCurItemType, dwCurItemIndex)
        if itemInfo then
            nPos = nPos + 1
            table.insert(tResult, {nPos = nPos, nType = nCurItemType, dwIndex = dwCurItemIndex, nBindType = itemInfo.nBindType})

            local tRelations = Table_GetItemToItemPackList(nCurItemType, dwCurItemIndex) or {}
            
            -- 处理所有关联道具
            for _, item in ipairs(tRelations) do
                local szItemKey = make_item_key(item[1], item[2])
                
                if not tVisited[szItemKey] then
                    tVisited[szItemKey] = true
                    table.insert(Queue, {item[1], item[2]})
                end
            end
        else
            UILog(string.format("ShareStation ItemToItemPack InValid Item:%d, %d", nCurItemType, dwCurItemIndex))
        end
    end
    
    return tResult
end

function ShareExteriorData.IsPendantExist(dwIndex, tSubDetail)
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    local tColorID = tSubDetail and tSubDetail.tColorID
    if tColorID then
        return pPlayer.IsColorPendentExist(dwIndex, tColorID[1], tColorID[2], tColorID[3])
    else
        return pPlayer.IsPendentExist(dwIndex)
    end
end

function ShareExteriorData.GetInBagItemSort(nType, dwIndex)
    if not nType or not dwIndex or nType <= 0 or dwIndex <= 0 then
        return SHARE_EXTERIOR_SHOP_STATE.OTHER
    end

    local iteminfo = GetItemInfo(nType, dwIndex)
    if iteminfo then
        local nBindType = iteminfo.nBindType
        if nBindType == ITEM_BIND.BIND_ON_PICKED then
            return SHARE_EXTERIOR_SHOP_STATE.IN_BAG_BIND
        elseif nBindType == ITEM_BIND.BIND_ON_EQUIPPED then
            return SHARE_EXTERIOR_SHOP_STATE.IN_BAG_UNBIND
        end
    end
    return SHARE_EXTERIOR_SHOP_STATE.OTHER
end

-- 获取称号特效默认的自定义参数
function ShareExteriorData.GetDefaultSFXCustomData(dwEffectID)
    local tEffect = Table_GetPendantEffectInfo(dwEffectID)
    if tEffect and tEffect.szType == "CircleBody" then --只有环身特效才能自定义
        return DEFAULT_CUSTOM_DATA
    end
end

-- 获取挂件默认的自定义参数
function ShareExteriorData.GetDefaultPendantCustomData(nSub, dwPendantID)
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    local tCustomData
    local iteminfo = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, dwPendantID)
    if iteminfo and IsCustomPendantRepresentID(nSub, iteminfo.nRepresentID, pPlayer.nRoleType) then
        tCustomData = DEFAULT_CUSTOM_DATA
    end
    return tCustomData
end

-- 获取发型染色数据
function ShareExteriorData.GetHairDyeingData(nHairID, nHairDyeingIndex)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local tHairDyeingData = {}
    if nHairDyeingIndex then
        local tList = hPlayer.GetHairCustomDyeingList(nHairID)
        if not tList or not tList[nHairDyeingIndex] then
            return
        end

        tHairDyeingData = tList[nHairDyeingIndex]
    else
        tHairDyeingData = hPlayer.GetEquippedHairCustomDyeingData(nHairID)
    end

    return tHairDyeingData
end

-- 切换发型染色方案
function ShareExteriorData.ChangeHairDyeingIndex(nHairID, nIndex)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local hHairCustomDyeingManager = GetHairCustomDyeingManager()
    if not hHairCustomDyeingManager then
        return
    end
    local nCode = hHairCustomDyeingManager.Equip(nHairID, nIndex)
    if nCode ~= HAIR_CUSTOM_DYEING_ERROR_CODE.SUCCESS then
        local szChannel = "MSG_ANNOUNCE_RED"
        local szMsg = g_tStrings.tHairDyeingEquipNotify[nCode]
        OutputMessage(szChannel, szMsg)
        OutputMessage("MSG_SYS", szMsg)
        return
    end
end

-- 检查捏脸数据是否包含面部装饰物，有的话打开显示开关
function ShareExteriorData.SetFaceDecalShowFlagByData(tPreviewData)
    local pPlayer = GetClientPlayer()
    if not pPlayer or not tPreviewData then
        return
    end

    local bDecoration = false
    if tPreviewData.bNewFace then
        local tDecoration = tPreviewData.tDecoration
        if tDecoration then
            for k, v in pairs(tDecoration) do
                if v.nShowID and v.nShowID ~= 0 then
                    bDecoration = true
                    break
                end
            end
        end
    else
        local nDecorationID = tPreviewData.nDecorationID
        bDecoration = nDecorationID and nDecorationID ~= 0
    end

    local bShowFlag = pPlayer.GetFaceDecorationShowFlag()
    if not bShowFlag and bDecoration then
        GetFaceLiftManager().SetDecorationShowFlag(true)
    end
end

--是否为礼盒类外观道具
function ShareExteriorData.IsPackExteriorItem(nItemType, dwItemIndex)
    local hItemInfo = GetItemInfo(nItemType, dwItemIndex)
    if hItemInfo and hItemInfo.nGenre == ITEM_GENRE.COIN_SHOP_QUANTITY_LIMIT_ITEM and
        hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.PACK then
        return true
    end
    return false
end

--获取所有头饰对应的表现Sub
function ShareExteriorData.GetHeadPendantResSub()
    return tMultiPosPendantKey
end

function ShareExteriorData.SyncUploadFaceDecoration(tPreviewData)
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    
    local bDecoration = false
    if tPreviewData.bNewFace then
        local tDecoration = tPreviewData.tDecoration
        if tDecoration then
            for k, v in pairs(tDecoration) do
                if v.nShowID and v.nShowID ~= 0 then
                    bDecoration = true
                    break
                end
            end
        end
    else
        local nDecorationID = tPreviewData.nDecorationID
        bDecoration = nDecorationID and nDecorationID ~= 0
    end
    
    local bShowFlag = pPlayer.GetFaceDecorationShowFlag()
    if not bShowFlag and bDecoration then
        if tPreviewData.bNewFace then
            tPreviewData.tDecoration = {
                [FACE_LIFT_DECORATION_TYPE.NOSE] = {
                    nShowID = 0,
                    nColorID = 0
                },
                [FACE_LIFT_DECORATION_TYPE.MOUTH] = {
                    nShowID = 0,
                    nColorID = 0
                }
                -- 这两条顺序不一样会导致校验规则不一定能过，已告知网页有bug，等网页修复后注意回测一下
            }
        else
            tPreviewData.nDecorationID = 0
        end
    end
end

function ShareExteriorData.GetItemSortState(nType, dwIndex, nSub, tDetail)
    local pPlayer = GetClientPlayer()
    if not pPlayer then
    return SHARE_EXTERIOR_SHOP_STATE.OTHER
    end

    local tGoods = Table_GetRewardsGoodItem(nType, dwIndex)
    local nGoodsSort
    if tGoods then -- 商城售卖道具
        nGoodsSort = ShareExteriorData.GetCoinShopSortState(COIN_SHOP_GOODS_TYPE.ITEM, tGoods.dwLogicID) --这里取到的分类并不准确，如果是可多次购买的外观，就算在包里已有，CheckAlreadyHave接口也会判未拥有

        --补充判断道具本身是否在包里
        if nGoodsSort > SHARE_EXTERIOR_SHOP_STATE.IN_BAG_BIND and pPlayer.GetItemAmountInAllPackages(nType, dwIndex) > 0 then
            local tGoodsInfo = GetRewardsShop().GetRewardsShopInfo(tGoods.dwLogicID)
            if tGoodsInfo.bCanBuyMultiple then
                nGoodsSort = SHARE_EXTERIOR_SHOP_STATE.IN_BAG_UNBIND
            else
                nGoodsSort = SHARE_EXTERIOR_SHOP_STATE.IN_BAG_BIND
            end
        end
        return nGoodsSort
    end
    
    --不在商城售卖的道具
    if nSub and nSub == EQUIPMENT_REPRESENT.PENDENT_PET_STYLE then -- 挂宠
        if pPlayer.IsHavePendentPet(dwIndex) then
            return SHARE_EXTERIOR_SHOP_STATE.HAVE
        elseif pPlayer.GetItemAmountInAllPackages(nType, dwIndex) > 0 then
            return ShareExteriorData.GetInBagItemSort(nType, dwIndex)
        else
            return SHARE_EXTERIOR_SHOP_STATE.OTHER
        end
    elseif nSub and table.contain_value(tNormalPendantKey, nSub) then -- 普通挂件
        if ShareExteriorData.IsPendantExist(dwIndex, tDetail and tDetail[nSub]) then
            return SHARE_EXTERIOR_SHOP_STATE.HAVE
        elseif pPlayer.GetItemAmountInAllPackages(nType, dwIndex) > 0 then
            return ShareExteriorData.GetInBagItemSort(nType, dwIndex)
        else
            return SHARE_EXTERIOR_SHOP_STATE.OTHER
        end
    else -- 其他道具，不存在已拥有的情况
        if pPlayer.GetItemAmountInAllPackages(nType, dwIndex) > 0 then
            return ShareExteriorData.GetInBagItemSort(nType, dwIndex)
        else
            return SHARE_EXTERIOR_SHOP_STATE.OTHER
        end
    end
end

function ShareExteriorData.GetCoinShopSortState(eGoodsType, dwID)
    local nOwnType = GetCoinShopClient().CheckAlreadyHave(eGoodsType, dwID)
    if nOwnType == COIN_SHOP_OWN_TYPE.EQUIP or nOwnType == COIN_SHOP_OWN_TYPE.FREE_TRY_ON then
        return SHARE_EXTERIOR_SHOP_STATE.HAVE
    elseif nOwnType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE and nOwnType ~= COIN_SHOP_OWN_TYPE.INVALID then
        --！！！注意：对ITEM类的商品，这里取到的分类并不准确，如果是可多次购买的可交易外观，就算在包里已有，CheckAlreadyHave接口也会判未拥有，所以这里判已拥有的一定是不可交易外观
        return SHARE_EXTERIOR_SHOP_STATE.IN_BAG_BIND
    else
        local bCanBuy
        if eGoodsType == COIN_SHOP_GOODS_TYPE.HAIR then
            bCanBuy = OutFitPreviewData.HairCanBuy(HAIR_STYLE.HAIR, dwID)
        else
            bCanBuy = CoinShop_GoodsShow(eGoodsType, dwID) --外装/武器/道具通用接口
        end
        return bCanBuy and SHARE_EXTERIOR_SHOP_STATE.GOODS_SALE or SHARE_EXTERIOR_SHOP_STATE.OTHER
    end
end

function ShareExteriorData.SortItemList(tList)
    local function fnSortExteriorItemList(t1, t2)
        if t1.nSort ~= t2.nSort then
            return t1.nSort < t2.nSort
        else
            return t1.nPos < t2.nPos
        end
    end
    table.sort(tList, fnSortExteriorItemList)
end

-- 根据外观ID获取相关联的所有道具及其分类状态
function ShareExteriorData.GetExteriorToItemList(dwID, bEffect, eGoodsType)
    local tItemList = {}
    if bEffect then
        tItemList = Table_GetEffectToItemList(dwID)
    elseif eGoodsType then
        tItemList = Table_GetExteriorToItemList(dwID, eGoodsType)
    end

    for i, v in ipairs(tItemList) do
        -- 初始化排序相关参数
        local nItemType, dwItemIndex = v[1], v[2]
        v.nPos = i
        v.nSort = SHARE_EXTERIOR_SHOP_STATE.OTHER

        -- 获取所有和道具相关联的礼盒道具列表（包括道具本身），如果有比目前分类更靠前的，做替换处理。如果存在可购买的道具，最终会显示最先读到的那个
        local tItemPackList = ShareExteriorData.GetAllRelateItemPack(nItemType, dwItemIndex)
        for _, tPackItem in ipairs(tItemPackList) do
            local nPackItemType, dwPackItemIndex = tPackItem.nType, tPackItem.dwIndex
            local nPackItemSort = SHARE_EXTERIOR_SHOP_STATE.OTHER

            nPackItemSort = ShareExteriorData.GetItemSortState(nPackItemType, dwPackItemIndex)
            tPackItem.nSort = nPackItemSort
            if nPackItemSort < v.nSort then
                v[1] = nPackItemType
                v[2] = dwPackItemIndex
                v.nSort = nPackItemSort
            end
        end

        -- 道具相关联的所有物品都不可购买的情况下，检查是否存在道具本身绑定，但礼盒不绑定的情况，需要优先显示最先读到的不绑定道具
        if v.nSort == SHARE_EXTERIOR_SHOP_STATE.OTHER then
            local itemInfo = GetItemInfo(nItemType, dwItemIndex)
            if itemInfo and itemInfo.nBindType ~= ITEM_BIND.BIND_ON_EQUIPPED then
                for _, tPackItem in ipairs(tItemPackList) do
                    local nPackItemType, dwPackItemIndex = tPackItem.nType, tPackItem.dwIndex
                    if tPackItem.nBindType and tPackItem.nBindType == ITEM_BIND.BIND_ON_EQUIPPED then
                        v[1] = nPackItemType
                        v[2] = dwPackItemIndex
                        v.nSort = tPackItem.nSort
                        break
                    end
                end
            end
        end
    end

    ShareExteriorData.SortItemList(tItemList)
    return tItemList
end

function ShareExteriorData.GetSortDataByExteriorData(tExterior)
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    local tID = tExterior.tExteriorID
    local tDetail = tExterior.tDetail

    local tSortData = {}
    for _, nSort in pairs (SHARE_EXTERIOR_SHOP_STATE) do
        tSortData[nSort] = {}
    end

    for key, dwID in pairs(tID) do
        if dwID > 0 then
            local nExteriorSort, tExteriorBox
            local nEffectType = CharacterEffectData.GetLogicTypeByEffectType(key)
            if nEffectType then --称号特效
                if pPlayer.IsSFXAcquired(dwID) then
                    nExteriorSort = SHARE_EXTERIOR_SHOP_STATE.HAVE
                else
                    nExteriorSort = SHARE_EXTERIOR_SHOP_STATE.OTHER
                end
                tExteriorBox = {nSub = key, bEffect = true, dwID = dwID}
            elseif key == EQUIPMENT_REPRESENT.HAIR_STYLE then -- 发型
                nExteriorSort = ShareExteriorData.GetCoinShopSortState(COIN_SHOP_GOODS_TYPE.HAIR, dwID)
                tExteriorBox = {nSub = key, eGoodsType = COIN_SHOP_GOODS_TYPE.HAIR, dwID = dwID}
            elseif key == EQUIPMENT_REPRESENT.CHEST_STYLE -- 【成衣】或【外装收集-上衣】
            or key == EQUIPMENT_REPRESENT.HELM_STYLE -- 外装收集-帽子
            or key == EQUIPMENT_REPRESENT.WAIST_STYLE -- 外装收集-腰带
            or key == EQUIPMENT_REPRESENT.BANGLE_STYLE -- 外装收集-护腕
            or key == EQUIPMENT_REPRESENT.BOOTS_STYLE -- 外装收集-鞋子
            then
                nExteriorSort = ShareExteriorData.GetCoinShopSortState(COIN_SHOP_GOODS_TYPE.EXTERIOR, dwID)
                tExteriorBox = {nSub = key, eGoodsType = COIN_SHOP_GOODS_TYPE.EXTERIOR, dwID = dwID}
            elseif key == EQUIPMENT_REPRESENT.WEAPON_STYLE or key == EQUIPMENT_REPRESENT.BIG_SWORD_STYLE then -- 武器
                nExteriorSort = ShareExteriorData.GetCoinShopSortState(COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR, dwID)
                tExteriorBox = {nSub = key, eGoodsType = COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR, dwID = dwID}
            elseif key == EQUIPMENT_REPRESENT.PENDENT_PET_STYLE or table.contain_value(tNormalPendantKey, key) then -- 挂宠或普通挂件
                nExteriorSort = ShareExteriorData.GetItemSortState(ITEM_TABLE_TYPE.CUST_TRINKET, dwID, key, tDetail)
                tExteriorBox = {nSub = key, eGoodsType = COIN_SHOP_GOODS_TYPE.ITEM, nItemType = ITEM_TABLE_TYPE.CUST_TRINKET, dwItemIndex = dwID}
            end

            if nExteriorSort == SHARE_EXTERIOR_SHOP_STATE.HAVE or nExteriorSort == SHARE_EXTERIOR_SHOP_STATE.IN_BAG_BIND or nExteriorSort == SHARE_EXTERIOR_SHOP_STATE.IN_BAG_UNBIND
                or key == EQUIPMENT_REPRESENT.WEAPON_STYLE or key == EQUIPMENT_REPRESENT.BIG_SWORD_STYLE then -- 武器暂时没有指引到道具的处理
                table.insert(tSortData[nExteriorSort], tExteriorBox)
            else
                local eGoodsType = tExteriorBox and tExteriorBox.eGoodsType
                local tItemList = ShareExteriorData.GetExteriorToItemList(dwID, bEffect, eGoodsType)
                if #tItemList > 0 then
                    local tMinSortItem = tItemList[1]
                    local nItemSort = tMinSortItem and tMinSortItem.nSort
                    if nItemSort < nExteriorSort then
                        -- 存在分类更靠前的道具
                        table.insert(tSortData[nItemSort], {nSub = key, eGoodsType = COIN_SHOP_GOODS_TYPE.ITEM, nItemType = tMinSortItem[1], dwItemIndex = tMinSortItem[2]})
                    else
                        if nExteriorSort == SHARE_EXTERIOR_SHOP_STATE.GOODS_SALE then
                            --外观本身未拥有但可购买
                            table.insert(tSortData[nExteriorSort], tExteriorBox)
                        else
                            --不存在任何购买途径，从道具Tip查看获取渠道
                            table.insert(tSortData[nItemSort], {nSub = key, eGoodsType = COIN_SHOP_GOODS_TYPE.ITEM, nItemType = tMinSortItem[1], dwItemIndex = tMinSortItem[2]})
                        end
                    end
                else
                    table.insert(tSortData[nExteriorSort], tExteriorBox)
                end
            end
        end
    end
    return tSortData
end

function ShareExteriorData.ParseCustomFilterFlag(tExteriorID, tDetail)
    if not tExteriorID or not tDetail then
        return
    end

    for key, tFlag in pairs(tShareFilterFlag_Color) do
        local bContinue = false
        for _, nSub in ipairs(tFlag) do
            if not bContinue then
                local tSubDetail = tDetail[nSub] or {}
                local bHaveColor = tSubDetail.nNowDyeingID and tSubDetail.nNowDyeingID > 0
                local bHaveHairDye = tSubDetail.tDyeingData and not table.is_empty(tSubDetail.tDyeingData)
                -- local bHaveChestDye = tSubDetail.tDyeingData and not table.is_empty(tSubDetail.tDyeingData)
                if bHaveColor or bHaveHairDye then
                    tExteriorID[key] = 1
                    bContinue = true
                else
                    tExteriorID[key] = 0
                end
            end
        end
    end

    for key, tFlag in pairs(tShareFilterFlag_Custom) do
        local bContinue = false
        for _, nSub in ipairs(tFlag) do
            if not bContinue then
                local tSubDetail = tDetail[nSub] or {}
                local tCustomData = tSubDetail.tCustomData
                local bIsCustomized = tCustomData and not IsTableEqual(tCustomData, DEFAULT_CUSTOM_DATA)
                if bIsCustomized then
                    tExteriorID[key] = 1
                    bContinue = true
                else
                    tExteriorID[key] = 0
                end
            end
        end
    end
end

function ShareExteriorData.IsFilterFlagKey(szKey)
    if tShareFilterFlag_Color[szKey] or tShareFilterFlag_Custom[szKey] then
        return true
    end

    return false
end

---------------设计站搭配数据相关----------------

---------------外观筛选相关----------------
---Exterior_SubToRepresentSub

local MAX_RUBBING_FILTER_NUM = 1
local tFilterSubMap = {
    [1]  = {EQUIPMENT_REPRESENT.CHEST_STYLE},
    [2]  = {EQUIPMENT_REPRESENT.HAIR_STYLE},
    [3]  = {EQUIPMENT_REPRESENT.CHEST_STYLE, EQUIPMENT_REPRESENT.HELM_STYLE, EQUIPMENT_REPRESENT.BANGLE_STYLE, EQUIPMENT_REPRESENT.WAIST_STYLE, EQUIPMENT_REPRESENT.BOOTS_STYLE},
    [4]  = {EQUIPMENT_REPRESENT.WEAPON_STYLE},
    [5]  = {EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND},
    [6]  = {EQUIPMENT_REPRESENT.FACE_EXTEND},
    [7]  = {EQUIPMENT_REPRESENT.BACK_EXTEND},
    [8]  = {EQUIPMENT_REPRESENT.WAIST_EXTEND},
    [9]  = {EQUIPMENT_REPRESENT.L_SHOULDER_EXTEND},
    [10] = {EQUIPMENT_REPRESENT.R_SHOULDER_EXTEND},
    [11] = {EQUIPMENT_REPRESENT.HEAD_EXTEND},
    [12] = {EQUIPMENT_REPRESENT.BAG_EXTEND},
    [13] = {EQUIPMENT_REPRESENT.GLASSES_EXTEND},
    [14] = {EQUIPMENT_REPRESENT.L_GLOVE_EXTEND},
    [15] = {EQUIPMENT_REPRESENT.R_GLOVE_EXTEND},
    [16] = {EQUIPMENT_REPRESENT.PENDENT_PET_STYLE},
    [17] = {"Footprint", "CircleBody", "LHand", "RHand"},
}

local tShowFilterTitle = nil
local function LoadFilterTitle()
    if tShowFilterTitle then
        return tShowFilterTitle
    end
    tShowFilterTitle = {}
    local nCount = g_tTable.ExteriorFilterTitle:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.ExteriorFilterTitle:GetRow(i)
        if tLine then
            -- 解析 szTypeClass，格式如 "3_1;3_3;3_7"、"6_3"
            -- 每段 "nType_nClass"，多个 Class 用分号分隔，无 Class 时写 0
            local nType = 0
            local tRewardsClassList = {}
            for segment in string.gmatch(tLine.szTypeClass, "[^;]+") do
                local szType, szClass = string.match(segment, "^(%d+)_?(%d*)$")
                if szType then
                    local nSegType = tonumber(szType)
                    local nSegClass = tonumber(szClass)
                    if nType == 0 then
                        nType = nSegType
                    end
                    if nSegClass and nSegClass ~= 0 then
                        table.insert(tRewardsClassList, nSegClass)
                    end
                end
            end
            table.insert(tShowFilterTitle, {
                nIndex = tLine.nIndex,
                szName = tLine.szName,
                nType = nType,
                tRewardsClassList = tRewardsClassList,
                nMaxFilterNum = tLine.nMaxFilterNum,
                tSub = tFilterSubMap[tLine.nIndex] or {},
            })
        end
    end
    return tShowFilterTitle
end

-- 对应ExteriorBox中的nSub1-5
local tResToSetIndex = {
    [EQUIPMENT_REPRESENT.HELM_STYLE] = 1,
    [EQUIPMENT_REPRESENT.CHEST_STYLE] = 2,
    [EQUIPMENT_REPRESENT.BANGLE_STYLE] = 3,
    [EQUIPMENT_REPRESENT.WAIST_STYLE] = 4,
    [EQUIPMENT_REPRESENT.BOOTS_STYLE] = 5,
}


-- 挂件索引转换
local tPendantType = {
    [65] = { szType = "Head", nPendantType = KPENDENT_TYPE.HEAD },           -- 头饰
    [4]  = { szType = "Face", nPendantType = KPENDENT_TYPE.FACE },           -- 面部挂件
    [62] = { szType = "Glasses", nPendantType = KPENDENT_TYPE.GLASSES },     -- 眼饰
    [8]  = { szType = "LShoulder", nPendantType = KPENDENT_TYPE.LSHOULDER }, -- 左肩饰
    [9]  = { szType = "RShoulder", nPendantType = KPENDENT_TYPE.RSHOULDER }, -- 右肩饰
    [63] = { szType = "LHand", nPendantType = KPENDENT_TYPE.LGLOVE },        -- 左手饰
    [64] = { szType = "RHand", nPendantType = KPENDENT_TYPE.RGLOVE },        -- 右手饰
    [5]  = { szType = "Back", nPendantType = KPENDENT_TYPE.BACK },           -- 背部挂件
    [3]  = { szType = "BackCloak", nPendantType = KPENDENT_TYPE.BACKCLOAK }, -- 披风
    [6]  = { szType = "Waist", nPendantType = KPENDENT_TYPE.WAIST },         -- 腰部挂件
    [60] = { szType = "PendantPet" },                                        -- 挂宠
    [12] = { szType = "Bag", nPendantType = KPENDENT_TYPE.BAG },             -- 佩囊
}

-- 从 ExteriorFilterTitle 表中获取成衣分类对应的所有 RewardsClass
function ShareExteriorData.GetChestClassList()
    local tFilterTitle = LoadFilterTitle()
    for _, v in ipairs(tFilterTitle) do
        if v.nType == COIN_SHOP_GOODS_TYPE.EXTERIOR and v.tRewardsClassList[1] == REWARDS_CLASS.LIMIT_TIME then
            return v.tRewardsClassList
        end
    end
    return {REWARDS_CLASS.LIMIT_TIME}
end

-- 判断某外观 Class 是否属于成衣类
function ShareExteriorData.IsChestClass(nClass)
    return table.contain_value(ShareExteriorData.GetChestClassList(), nClass)
end

function ShareExteriorData.GetFilterTitle()
    local tFilterTitle = LoadFilterTitle()
    local tbTitleList = {}
    for _, v in ipairs(tFilterTitle) do
        local tTitle = clone(v)
        tTitle.tTitleInfo = {szName = v.szName}
        table.insert(tbTitleList, tTitle)
    end
    return tbTitleList
end

local tEffectTypeList = {
    {nSub = PLAYER_SFX_REPRESENT.FOOTPRINT, szType = "Footprint"},
    {nSub = PLAYER_SFX_REPRESENT.SURROUND_BODY, szType = "CircleBody"},
    {nSub = PLAYER_SFX_REPRESENT.LEFT_HAND, szType = "LHand"},
    {nSub = PLAYER_SFX_REPRESENT.RIGHT_HAND, szType = "RHand"},
}

function ShareExteriorData.GetFilterSubTitle(nType, nClass)
    local tSubTitleList = {}
    if not nType then
        return tSubTitleList
    end

    if nType == COIN_SHOP_GOODS_TYPE.HAIR then
        for nShowType, szName in ipairs(g_tStrings.STR_ALL_HAIR_TYPE) do
            if nShowType ~= HAIR_SHOW_TYPE.GROUP then
                szName = UIHelper.UTF8ToGBK(szName)
                table.insert(tSubTitleList, {nShowType = nShowType, tTitleInfo = {szName = szName}})
            end
        end
    elseif nType == COIN_SHOP_GOODS_TYPE.EXTERIOR then -- 拓印子选项
        local tFilterTitle = LoadFilterTitle()
        local tExteriorSub = tFilterTitle[3] and tFilterTitle[3].tSub or {}
        for _, nShowType in ipairs(tExteriorSub) do
            local nEquipSub = Exterior_RepresentSubToEquipSub(nShowType)
            local szName = g_tStrings.tInventoryNameTable[nEquipSub]
            szName = UIHelper.UTF8ToGBK(szName)
            table.insert(tSubTitleList, {nShowType = nShowType, tTitleInfo = {szName = szName},
                            nMaxFilterNum = MAX_RUBBING_FILTER_NUM, tSub = {nShowType}})
        end
    elseif nType == COIN_SHOP_GOODS_TYPE.ITEM and nClass == REWARDS_CLASS.EFFECT then -- 特效子类型
        local tEffectSubNames = {
            ["Footprint"]   = "脚印",
            ["CircleBody"]  = "环身",
            ["LHand"]       = "左手",
            ["RHand"]       = "右手",
        }
        for _, v in ipairs(tEffectTypeList) do
            local szName = UIHelper.UTF8ToGBK(tEffectSubNames[v.szType] or v.szType)
            table.insert(tSubTitleList, {
                nShowType = v.szType,
                tTitleInfo = {szName = szName},
                tRewardsClassList = {REWARDS_CLASS.EFFECT},
                nMaxFilterNum = MAX_RUBBING_FILTER_NUM,
                tSub = {v.szType},
            })
        end
    end

    return tSubTitleList
end

function ShareExteriorData.GetPendantTypeByClass(nRewardsClass)
    return tPendantType[nRewardsClass]
end

function ShareExteriorData.GetEffectTypeList()
    return tEffectTypeList
end

function ShareExteriorData.GetEffectTypeBySub(nSub)
    for _, v in ipairs(tEffectTypeList) do
        if v.nSub == nSub then
            return v.szType
        end
    end
end

function ShareExteriorData.GetPendantTypeByEquipSub(nEquipSub)
    local nRepresentSub = Exterior_SubToRepresentSub(nEquipSub)
    if nRepresentSub then
        for nClass, tInfo in pairs(tPendantType) do
            if tInfo.nPendantType and Exterior_RepresentSubToEquipSub(nRepresentSub) == nEquipSub then
                return tInfo
            end
        end
    end
end

function ShareExteriorData.GetHairListByShowType(nShowType)
    if not self.tbHairList then
        self.tbHairList = {}
        -- 这个其实还是当前体型的hairshop_(bodyType)表，如果没有该发型那就没法判发色颜色了
        local tHairMap = CoinShopData.GetHairMap()
        local tReHairIndex = CoinShop_GetReHairIndex()
        for i, v in pairs(tReHairIndex) do
            local nHairID = v.nHairID
            local nHeadID = v.nHeadID
            local bGroup = v.nBangID > 0 or v.nPlaitID > 0 -- 套发不显示
            local tHairInfo = tHairMap["reHair"] and tHairMap["reHair"][nHeadID]
            local nHairShowType = tHairInfo and tHairInfo[4]
            -- nHairShowType是用来建立索引的，真正判套发的还是bGroup
            if not bGroup and nHairShowType then
                if nHairShowType ~= HAIR_SHOW_TYPE.ALL then
                    self.tbHairList[nHairShowType] = self.tbHairList[nHairShowType] or {}
                    table.insert(self.tbHairList[nHairShowType], {nHairID = nHairID, nHeadID = nHeadID})
                end
                self.tbHairList[HAIR_SHOW_TYPE.ALL] = self.tbHairList[HAIR_SHOW_TYPE.ALL] or {}
                table.insert(self.tbHairList[HAIR_SHOW_TYPE.ALL], {nHairID = nHairID, nHeadID = nHeadID})
            end
        end
    end

    return self.tbHairList[nShowType]
end

--- ShareExteriorData.GetFilterList 获取对应分类的列表
-- @param nType tTitleInfo.nType
-- @param nSubType tTitleInfo.tRewardsClassList[1]/nShowType
function ShareExteriorData.GetFilterList(nType, nSubType)
    if not nType then
        return
    end

    if nType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
        if ShareExteriorData.IsChestClass(nSubType) then --合并成衣所有Class
            if not m_aAllLimitChest then
                m_aAllLimitChest = {}
                local tClassList = ShareExteriorData.GetChestClassList()
                for _, nClass in ipairs(tClassList) do
                    local tExteriors = Table_GetExteriorClass(nClass) or {}
                    for _, v in ipairs(tExteriors) do
                        table.insert(m_aAllLimitChest, v)
                    end
                end
            end
            return m_aAllLimitChest
        else
            return Table_GetExteriorClass(nSubType)
        end
    elseif nType == COIN_SHOP_GOODS_TYPE.HAIR then
        return ShareExteriorData.GetHairListByShowType(nSubType)
    elseif nType == COIN_SHOP_GOODS_TYPE.ITEM then
        if nSubType == REWARDS_CLASS.EFFECT then
            -- 特效筛选：按特效子类型聚合返回
            local pPlayer = GetClientPlayer()
            if not pPlayer then
                return {}
            end
            ShareExteriorData.tEffectFilterList = ShareExteriorData.tEffectFilterList or {}
            if not table.is_empty(ShareExteriorData.tEffectFilterList) then
                return ShareExteriorData.tEffectFilterList
            end
            for _, v in ipairs(tEffectTypeList) do
                local tList = Table_GetPendantEffectListByType(v.szType, pPlayer.nRoleType) or {}
                for _, tLine in ipairs(tList) do
                    tLine.szEffectType = v.szType
                    tLine.nEffectSub = v.nSub
                    table.insert(ShareExteriorData.tEffectFilterList, tLine)
                end
            end
            return ShareExteriorData.tEffectFilterList
        end
        -- 特效子类型筛选（单个效果类型，来自二级标题导航）
        if type(nSubType) == "string" then
            local pPlayer = GetClientPlayer()
            if not pPlayer then return {} end
            ShareExteriorData.tEffectSubList = ShareExteriorData.tEffectSubList or {}
            if not ShareExteriorData.tEffectSubList[nSubType] then
                local tList = Table_GetPendantEffectListByType(nSubType, pPlayer.nRoleType) or {}
                for _, tLine in ipairs(tList) do
                    tLine.szEffectType = nSubType
                    tLine.nEffectSub = nSubType
                end
                ShareExteriorData.tEffectSubList[nSubType] = tList
            end
            return ShareExteriorData.tEffectSubList[nSubType]
        end
        -- 挂件/挂宠筛选
        local tTypeInfo = ShareExteriorData.GetPendantTypeByClass(nSubType)
        if tTypeInfo then
            if ShareExteriorData.tList and ShareExteriorData.tList[tTypeInfo.szType] then
                return ShareExteriorData.tList[tTypeInfo.szType]
            end

            ShareExteriorData.tList = ShareExteriorData.tList or {}
            ShareExteriorData.tList[tTypeInfo.szType] = Table_GetPendantListByType(tTypeInfo.szType)
            return ShareExteriorData.tList[tTypeInfo.szType]
        end
    elseif nType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
        return ShareExteriorData.GetShareStationWeaponList()
    end
end

-- 设计站武器筛选用: 合并商城武器表，按 nSubType 降序（特殊武器 nSubType 较大，排在前）
function ShareExteriorData.GetShareStationWeaponList()
    local tBySub = CoinShopData.GetShopWeapon()
    if not tBySub then
        return {}
    end
    local tSubTypes = {}
    for nSubType, _ in pairs(tBySub) do
        table.insert(tSubTypes, nSubType)
    end
    table.sort(tSubTypes, function(a, b) return a > b end)
    local tRes = {}
    for _, nSubType in ipairs(tSubTypes) do
        local tTab = tBySub[nSubType]
        if tTab then
            for _, tLine in ipairs(tTab) do
                table.insert(tRes, tLine)
            end
        end
    end
    return tRes
end

function ShareExteriorData.GetExteriorSubIndex(nRes)
    return tResToSetIndex[nRes]
end

function ShareExteriorData.GetExteriorClass(dwExteriorID)
    local hExteriorClient = GetExterior()
    if not hExteriorClient then
        return
    end

    local tExteriorInfo = hExteriorClient.GetExteriorInfo(dwExteriorID)
    if not tExteriorInfo then
        return
    end

    local tSetInfo = Table_GetExteriorSet(tExteriorInfo.nSet)
    if not tSetInfo then
        return
    end

    return tSetInfo.nClass
end


---------------外观筛选相关（礼包展开）----------------

--- 合并两个 tExteriorList，去重
local function MergeExteriorSubMap(tDst, tSrc)
    if not tSrc then
        return
    end
    local function addOne(nSub, dwID)
        if not nSub or not dwID or dwID <= 0 then
            return
        end
        local tIds = tDst[nSub]
        if not tIds then
            tDst[nSub] = { dwID }
            return
        end
        if table.contain_value(tIds, dwID) then
            return
        end
        table.insert(tIds, dwID)
    end
    for nSub, v in pairs(tSrc) do
        if type(v) == "table" then
            for _, dwID in ipairs(v) do
                addOne(nSub, dwID)
            end
        elseif type(v) == "number" and v > 0 then
            addOne(nSub, v)
        end
    end
end

--- 从 LimitView 列表中收集所有外观，返回推荐/筛选用的 tExteriorList
-- 返回格式：{ [部位nSub] = { dwID, ... }, ... }
function ShareExteriorData.CollectPackExteriors(tMultiItem)
    local tExteriorList = {}
    if not tMultiItem then
        return tExteriorList
    end

    local function AddSubId(nSub, dwID)
        if not nSub or not dwID or dwID <= 0 then
            return
        end
        local tIds = tExteriorList[nSub]
        if not tIds then
            tExteriorList[nSub] = { dwID }
            return
        end
        if table.contain_value(tIds, dwID) then
            return
        end
        table.insert(tIds, dwID)
    end

    for _, tViewItem in ipairs(tMultiItem) do
        if tViewItem.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.EXTERIOR then
            local dwExteriorID = tViewItem.dwLogicID
            if dwExteriorID and dwExteriorID > 0 then
                local nIndex = Exterior_GetSubIndex(dwExteriorID)
                if nIndex then
                    local nRepresentSub = Exterior_BoxIndexToRepresentSub(nIndex)
                    if nRepresentSub then
                        AddSubId(nRepresentSub, dwExteriorID)
                    end
                end
            end
        elseif tViewItem.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.HAIR then
            local dwHairID = tViewItem.dwLogicID
            if dwHairID and dwHairID > 0 then
                AddSubId(EQUIPMENT_REPRESENT.HAIR_STYLE, dwHairID)
            end
        elseif tViewItem.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.PENDENT then
            local dwIdx = tViewItem.dwLogicID
            if dwIdx and dwIdx > 0 then
                local hPendant = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, dwIdx)
                if hPendant then
                    local nRepresentSub = ExteriorView_GetRepresentSub(hPendant.nSub, hPendant.nDetail)
                    if nRepresentSub then
                        AddSubId(nRepresentSub, dwIdx)
                    end
                end
            end
        elseif tViewItem.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.PENDENT_PET then
            local dwPetIdx = tViewItem.dwLogicID
            if dwPetIdx and dwPetIdx > 0 then
                AddSubId(EQUIPMENT_REPRESENT.PENDENT_PET_STYLE, dwPetIdx)
            end
        end
    end

    return tExteriorList
end

--- 礼包外观：展开礼包（含嵌套礼包），返回 tExteriorList
function ShareExteriorData.BuildPackExteriorList(nDetail)
    local tExteriorList = {}
    local tPack = CoinShop_GetAllLimitViewPack(nDetail)
    if not IsTableEmpty(tPack) then
        for _, tBoxInfo in ipairs(tPack) do
            local hBoxInfo = GetItemInfo(ITEM_TABLE_TYPE.OTHER, tBoxInfo.dwIndex)
            if hBoxInfo then
                MergeExteriorSubMap(tExteriorList, ShareExteriorData.CollectPackExteriors(CoinShop_GetAllLimitView(hBoxInfo.nDetail)))
            end
        end
    else
        tExteriorList = ShareExteriorData.CollectPackExteriors(CoinShop_GetAllLimitView(nDetail))
    end
    return tExteriorList
end

function ShareExteriorData.GetExteriorName(nGoodsType, dwID)
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    local nRoleType = pPlayer.nRoleType
    if nGoodsType == COIN_SHOP_GOODS_TYPE.HAIR then
        return CoinShopHair.GetHairText(dwID, nRoleType)
    elseif nGoodsType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
        local hExteriorClient = GetExterior()
        if not hExteriorClient then
            return
        end

        if dwID and dwID > 0 then
            local tExteriorInfo = hExteriorClient.GetExteriorInfo(dwID)
            local szName = Table_GetExteriorSetName(tExteriorInfo.nGenre, tExteriorInfo.nSet)
            return szName
        end
    elseif nGoodsType == COIN_SHOP_GOODS_TYPE.ITEM then -- 挂件/挂宠
            return ItemData.GetItemNameByItemInfoIndex(ITEM_TABLE_TYPE.CUST_TRINKET, dwID)
    elseif nGoodsType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
        local tLine = CoinShop_GetWeaponInfo(dwID)
        return tLine and tLine.szName or ""
    end
end