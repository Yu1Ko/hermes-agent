-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: CoinShopRewards
-- Date: 2023-03-27 15:59:27
-- Desc: ?
-- ---------------------------------------------------------------------------------

CoinShopRewards = CoinShopRewards or {}
local self = CoinShopRewards
-------------------------------- 消息定义 --------------------------------
CoinShopRewards.Event = {}
CoinShopRewards.Event.XXX = "CoinShopRewards.Msg.XXX"

CoinShopRewards.FILTER_ALL = -1

CoinShopRewards.tAdornmentFilter =
{
    CoinShopRewards.FILTER_ALL,
    HORSE_ENCHANT_DETAIL_TYPE.HEAD,
    HORSE_ENCHANT_DETAIL_TYPE.CHEST,
    HORSE_ENCHANT_DETAIL_TYPE.FOOT,
    HORSE_ENCHANT_DETAIL_TYPE.HANT_ITEM,
}

function CoinShopRewards.Init()

end

function CoinShopRewards.UnInit()

end

function CoinShopRewards.OnLogin()

end

function CoinShopRewards.OnFirstLoadEnd()

end

function CoinShopRewards.Table_GetHomelandFurnitureInfoEx(nType1, nType2, dwFurnitureID)
    local tLine
    if nType2 ~= 0 then
        tLine = g_tTable.HomelandFurnitureInfo:LinearSearch({nCatg1Index = nType1, nCatg2Index = nType2, dwFurnitureID = dwFurnitureID})
    else
	    tLine = g_tTable.HomelandFurnitureInfo:LinearSearch({nCatg1Index = nType1, dwFurnitureID = dwFurnitureID})
    end
	return tLine
end

function CoinShopRewards.FilterFurnitureByType(dwFurnitureID, nFurnitureType1, nFurnitureType2)
    local tLine = self.Table_GetHomelandFurnitureInfoEx(nFurnitureType1, nFurnitureType2, dwFurnitureID)
    if tLine then
        return true
    else
        return false
    end
end

function CoinShopRewards.FilterFurnitureList(tList, nFurnitureType1, nFurnitureType2)
    if nFurnitureType1 == 0 then
        return tList
    end
    local tFilterList = {}
    for _, tItem in ipairs(tList) do
        local tItemInfo = tItem.tItemInfo or GetItemInfo(tItem.dwTabType, tItem.dwIndex)
        if self.FilterFurnitureByType(tItemInfo.dwFurnitureID, nFurnitureType1, nFurnitureType2) then
            table.insert(tFilterList, tItem)
        end
    end
    return tFilterList
end

function CoinShopRewards.FilterHorseAdornmentList(tList, nType)
    if nType == CoinShopRewards.FILTER_ALL then
        return tList
    end
    local tFilterList = {}
    for _, tItem in ipairs(tList) do
        local tItemInfo = tItem.tItemInfo or GetItemInfo(tItem.dwTabType, tItem.dwIndex)
        if tItemInfo.nDetail == nType then
            table.insert(tFilterList, tItem)
        end
    end
    return tFilterList
end

function CoinShopRewards.FilterItemList(tList, nClass, nType)
    if nType == CoinShopRewards.FILTER_ALL then
        return tList
    end
    local tFilterList = {}
    for _, tItem in ipairs(tList) do
        local tInfo = CoinShop_GetRewardSetID(nClass, tItem.dwIndex)
        if tInfo and tInfo.nSetID == nType then
            table.insert(tFilterList, tItem)
        end
    end
    return tFilterList
end

function CoinShopRewards.GetRewardsTabList(tList, nSubClass)
    for _, tTab in ipairs(tList) do
        if tTab.nSubClass == nSubClass then
            return tTab
        end
    end
end

function CoinShopRewards.FilterTimeRewardsList(tList)
    local tFilterList = {}
    local tFilterUntimelyList = {}
    local nTime = GetGSCurrentTime()
    for _, tItem in ipairs(tList) do
        local tLine = Table_GetRewardsItem(tItem.dwLogicID)
        if CoinShopData.IsStartTimeOK(tLine.nStartTime, nTime) then
            table.insert(tFilterList, tItem)
        else
            table.insert(tFilterUntimelyList, tLine)
        end
    end
    return tFilterList, tFilterUntimelyList
end

function CoinShopRewards.GetAdornmentSetInfo(tSet)
    local hRewardsShop = GetRewardsShop()
    if not hRewardsShop then
        return
    end

    local hCoinShopClient = GetCoinShopClient()
    if not hCoinShopClient then
        return
    end

    local nCoin = 0
    local nOriginalCoin = 0
    local nHave = 0
    local bStorage = false
    for _, tItem in ipairs(tSet.tList) do
        local tInfo = hRewardsShop.GetRewardsShopInfo(tItem.dwLogicID)
        local nHaveType = hCoinShopClient.CheckAlreadyHave(COIN_SHOP_GOODS_TYPE.ITEM, tItem.dwLogicID)
        local bHave = nHaveType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE
        if nHaveType == COIN_SHOP_OWN_TYPE.STORAGE then
            bStorage = COIN_SHOP_OWN_TYPE.STORAG
        end
        if bHave then
            nHave = nHave + 1
        else
            local nPrice, nOriginalPrice = CoinShop_GetShowPrice(tInfo)
            if nPrice > 0 then
                nCoin = nCoin + nPrice
                nOriginalCoin = nOriginalCoin + nOriginalPrice
            end
        end
    end
    return nHave, nCoin, nOriginalCoin, bStorage
end

function CoinShopRewards.IsOnFurnitureFilter(nCatg1Index, nCatg2Index)
    return nCatg1Index ~= 0
end

function CoinShopRewards.IsOnHorseAdornmentFilter(nType)
    return nType ~= CoinShopRewards.FILTER_ALL
end

function CoinShopRewards.IsOnItemFilter(nType)
    return nType ~= CoinShopRewards.FILTER_ALL
end

Event.Reg(CoinShopRewards, "ON_PENDENT_PET_CHANGED", function(dwItemIndex)
    if not g_pClientPlayer then
        return
    end
    if g_pClientPlayer.GetPendentPet(dwItemIndex) then
        RedpointHelper.PendantPet_SetNew(dwItemIndex, true)
    end
end)
