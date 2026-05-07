-- ---------------------------------------------------------------------------------
-- Author: jiayuran
-- Name: EnchantData
-- Date: 2024-4-23 11:24:31
-- Desc: 附魔相关逻辑
-- ---------------------------------------------------------------------------------

EnchantData = EnchantData or { className = "EnchantData" }
local self = EnchantData

local tEnchantTypeList = {
    [1] = {
        [8] = 1,
        [11] = 1,
        [13] = 1,
        [26] = 1,
        [31] = 1,
    },
    [2] = {
        [9] = 1,
        [15] = 1,
        [17] = 1,
        [21] = 1,
        [33] = 1,
        [41] = 1,
    },
}

local tShijianyuanMap = {    --拭剑园不能用附魔
    [276] = 1,
    [278] = 1,
    [279] = 1,
    [280] = 1,
    [281] = 1,
}
local ITEM_TAP_TYPE = 5

function EnchantData.CanUseEnchantSimple(player, item, dwTargetBox, dwTargetSlot, nEnchantCategory)
    local dwItemIndex = item.dwIndex
    local EnchantInfo = CraftData.g_EnchantInfo[dwItemIndex]
    if not EnchantInfo then
        return false
    end

    local g_LevelToEquip = CraftData.g_LevelToEquip
    local itemTarget = player.GetItem(dwTargetBox, dwTargetSlot)
    if not itemTarget then
        return false
    end

    --local scene = player.GetScene()
    --if not scene then
    --    return false, false
    --end
    --if tShijianyuanMap[scene.dwMapID] or scene.bIsArenaMap then
    --    return false, false
    --end

    local nEquipUsage = itemTarget.nEquipUsage
    local bTargetBind = itemTarget.bBind
    local nItemBindType = GetItemInfo(item.dwTabType, item.dwIndex).nBindType
    local nRequireLevel = EnchantInfo.RequireLevel

    if itemTarget.nGenre ~= 0 then
        return false
    elseif itemTarget.nSub > 10 then
        return false
    end

    --绑定附魔不能对未绑定装备使用
    if nItemBindType == 3 and not bTargetBind then
        return false
    end

    if nEnchantCategory and EnchantInfo.EnchantType ~= nEnchantCategory then
        return false --不是想要的附魔类型
    end

    if EnchantInfo.KungfuID and scene.nType ~= MAP_TYPE.DUNGEON and scene.nType ~= MAP_TYPE.TONG_DUNGEON then
        return false
    end
    if EnchantInfo.ForceID and player.dwForceID ~= EnchantInfo.ForceID then
        return false
    end

    if EnchantInfo.KungfuID and player.GetKungfuMount().dwSkillID ~= EnchantInfo.KungfuID then
        return false
    end

    if EnchantInfo.EquipmentType ~= nil and nEquipUsage ~= EnchantInfo.EquipmentType then
        return false -- 判断装备类型与附魔类型是否匹配
    end

    local tRange = g_LevelToEquip[nRequireLevel] --等级不满足
    if tRange and (itemTarget.nLevel < tRange.min or itemTarget.nLevel > tRange.max) then
        return false --等级不满足
    end
    local nRecomID = GetItemInfo(itemTarget.dwTabType, itemTarget.dwIndex).nRecommendID
    if not nRecomID then
        return false, false
    end

    local tRange = g_LevelToEquip[nRequireLevel]
    if tRange and (itemTarget.nLevel < tRange.min or itemTarget.nLevel > tRange.max) then
        return false
    end

    if EnchantInfo.EnchantType == 2 then
        if nEquipUsage == EQUIPMENT_USAGE_TYPE.IS_PVE_EQUIP then
            if tEnchantTypeList[EnchantInfo.Type] then
                --T奶
                local tTypeList = tEnchantTypeList[EnchantInfo.Type]
                if not tTypeList[nRecomID] then
                    return false, false
                end
            else
                --DPS
                local tTypeList1 = tEnchantTypeList[1]
                local tTypeList2 = tEnchantTypeList[2]
                if tTypeList1[nRecomID] or tTypeList2[nRecomID] then
                    return false, false
                end
            end
        end
    end

    local nRequireSubType = player.GetEnchantDestItemSubType(EnchantInfo.EnchantID)
    if itemTarget.nSub == nRequireSubType and itemTarget.dwTabType ~= ITEM_TABLE_TYPE.OTHER then
        return true, true
    end
end

function EnchantData.GetEnchantCost(nItemIndex)
    local tEnchantInfo = CraftData.g_EnchantInfo[nItemIndex]
    local nCostItemIndex = tEnchantInfo.ItemID or 0
    local nCostNum = tEnchantInfo.Num or 0
    local nHaveAmount = tEnchantInfo.Num or 0

    if nCostNum > 0 and nCostItemIndex > 0 and g_pClientPlayer then
        nHaveAmount = g_pClientPlayer.GetItemAmount(ITEM_TAP_TYPE, nCostItemIndex)
    end

    return tEnchantInfo.Num or 0, nHaveAmount, nCostItemIndex
end

function EnchantData.GetEnchantCategory(nItemIndex)
    local tEnchantInfo = CraftData.g_EnchantInfo[nItemIndex]
    return tEnchantInfo.EnchantType
end

local tRecommendDict = {
    --[kungfuID] = {[nSub] = {itemIndex}}
}
function EnchantData.LoadTab()
    local nCount = g_tTable.RecommendEnchant:GetRowCount()
    for i = 1, nCount do
        local tLine = g_tTable.RecommendEnchant:GetRow(i)
        local ItemIndex = tLine.ItemIndex
        local dwRecommendWay = tLine.dwRecommendWay
        local kungfuIDArr = tLine.kungfuID
        local tkungFuIds = string.split(kungfuIDArr, ';')
        for nIndex, szKungFuID in ipairs(tkungFuIds) do
            local nKungFuID = tonumber(szKungFuID)
            if nKungFuID then
                local lst = tRecommendDict[nKungFuID] or {}
                local subList = lst[dwRecommendWay] or {}

                table.insert(subList, ItemIndex)

                lst[dwRecommendWay] = subList
                tRecommendDict[nKungFuID] = lst
            end
        end
    end
end

-- 1--PVE  2--PVP   4--PVX  8--通用
local EquipUsage2RecommendWayType = {
    [EQUIPMENT_USAGE_TYPE.IS_PVP_EQUIP] = 2,
    [EQUIPMENT_USAGE_TYPE.IS_PVE_EQUIP] = 1,
    [EQUIPMENT_USAGE_TYPE.IS_PVX_EQUIP] = 4,
    [3] = 8,
}

local function GetRecommendEnchant(nSub, nLevel, nEnchantCategory, nKungFuID, nEquipUsage, nRecomID)
    local g_EnchantInfo = CraftData.g_EnchantInfo
    local tRes = {}
    if not nSub or not nLevel or not nKungFuID then
        return tRes
    end

    if nEnchantCategory ~= EnchantCategory.Season then
        if nKungFuID then
            local tToParse = {}
            if tRecommendDict[nKungFuID] then
                for dwRecommendWay, subList in pairs(tRecommendDict[nKungFuID]) do
                    local nRecommendWayType = EquipUsage2RecommendWayType[nEquipUsage]
                    if dwRecommendWay == 8 or bit._and(dwRecommendWay, nRecommendWayType) == nRecommendWayType then
                        table.insert_tab(tToParse, subList)
                    end
                end
            end

            for _, ItemIndex in ipairs(tToParse) do
                local EnchantInfo = g_EnchantInfo[ItemIndex]
                if EnchantInfo.EQUIPMENT_SUB == nSub and nEnchantCategory == EnchantInfo.EnchantType then
                    tRes[ItemIndex] = 1
                end
            end
        end
        return tRes
    end

    local tReqLevel = {}
    for nLev, tRange in pairs(CraftData.g_LevelToEquip) do
        if nLevel >= tRange.min and nLevel <= tRange.max then
            table.insert(tReqLevel, nLev)
        end
    end
    if #tReqLevel == 0 then
        return tRes
    end

    for nItemIndex, tEnchantInfo in pairs(g_EnchantInfo) do
        if tEnchantInfo.EQUIPMENT_SUB == nSub and nEnchantCategory == tEnchantInfo.EnchantType then
            -- 大附魔
            local bMatchLevel = tEnchantInfo.RequireLevel and table.contain_value(tReqLevel, tEnchantInfo.RequireLevel)
            local bMatchUsage = tEnchantInfo.EquipmentType == nEquipUsage
            local bIsNew = tEnchantInfo.bNew
            if bMatchLevel and bMatchUsage and bIsNew then
                if nEquipUsage == EQUIPMENT_USAGE_TYPE.IS_PVE_EQUIP then
                    if nRecomID then
                        if tEnchantTypeList[tEnchantInfo.Type] then
                            local tTypeList = tEnchantTypeList[tEnchantInfo.Type] --T奶
                            if tTypeList[nRecomID] then
                                tRes[nItemIndex] = 1
                            end
                        else
                            local tTypeList1 = tEnchantTypeList[1]  --DPS
                            local tTypeList2 = tEnchantTypeList[2]
                            if not (tTypeList1[nRecomID] or tTypeList2[nRecomID]) then
                                tRes[nItemIndex] = 1
                            end
                        end
                    end
                end

                if nEquipUsage == EQUIPMENT_USAGE_TYPE.IS_PVP_EQUIP then
                    tRes[nItemIndex] = 1
                end
            end
        end
    end
    return tRes
end

function EnchantData.GetRecommendEnchant(dwTargetBox, dwTargetSlot, nEnchantCategory)
    local itemTarget = g_pClientPlayer.GetItem(dwTargetBox, dwTargetSlot)
    if not itemTarget or not g_pClientPlayer then
        return {}
    end
    local nSub = itemTarget.nSub
    local nEquipUsage = itemTarget.nEquipUsage
    local nLevel = itemTarget.nLevel
    local nRecomID = GetItemInfo(itemTarget.dwTabType, itemTarget.dwIndex).nRecommendID
    local nKungFuID = EquipData.GetItemMatchKungfu(itemTarget)
    return GetRecommendEnchant(nSub, nLevel, nEnchantCategory, nKungFuID, nEquipUsage, nRecomID)
end

function EnchantData.GetRecommendEnchantWithItemInfo(itemInfo, nEnchantCategory, nKungFuID, nEquipUsage)
    if not itemInfo or not nKungFuID then
        return {}
    end
    local nSub = itemInfo.nSub
    local nLevel = itemInfo.nLevel
    local nRecomID = itemInfo.nRecommendID
    nEquipUsage = nEquipUsage or itemInfo.nEquipUsage
    return GetRecommendEnchant(nSub, nLevel, nEnchantCategory, nKungFuID, nEquipUsage, nRecomID)
end

function EnchantData.GetEnchantInfo(nItemIndex)
    return CraftData.g_EnchantInfo[nItemIndex]
end

function EnchantData.GetItemIndexWithEnchantID(nEnchantID)
    local nItemIndex
    for nIndex, tInfo in pairs(CraftData.g_EnchantInfo) do
        if tInfo.EnchantID == nEnchantID then
            nItemIndex = nIndex
            break
        end
    end
    return nItemIndex
end

function EnchantData.GetItemWithEnchantID(nEnchantID)
    local nItemIndex = EnchantData.GetItemIndexWithEnchantID(nEnchantID)
    if nItemIndex then
        return 5, nItemIndex
    end
    return nil
end

function EnchantData.GetRemovableEnchantTip(bPermanent)
    local szRemovableEnchantTip = ""
    if not EnchantData.g_CanRemoveEnchant or not EnchantData.g_CanRemoveEnchant2 then
        local szPath = "ui/Script/common/common_def.lua"
        LoadScriptFile(szPath, EnchantData)
    end

    local tEnchantName = bPermanent and EnchantData.g_CanRemoveEnchant2 or EnchantData.g_CanRemoveEnchant
    if tEnchantName then
        local szTip = "当前版本，"
        for _, szName in ipairs(tEnchantName) do
            szTip = szTip .. UIHelper.GBKToUTF8(szName)
            if _ ~= #tEnchantName then
                szTip = szTip .. "、"
            end
        end
        szTip = szTip .. "系列附魔可剥离"
        szRemovableEnchantTip = szTip
    end
    return szRemovableEnchantTip
end

function EnchantData.CanStripEnchant(dwEnchantID)
    if not dwEnchantID or dwEnchantID <= 0 then
        return false
    end
    local tEnchantInfo = CraftData.g_EnchantInfo_Inverse[dwEnchantID]
    if tEnchantInfo then
        return tEnchantInfo.EquipmentType ~= nil and tEnchantInfo.bNew
    end
    return false
end

Event.Reg(EnchantData, "FIRST_LOADING_END", EnchantData.LoadTab)
