-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: CoinShopExterior
-- Date: 2023-02-27 11:35:28
-- Desc: ?
-- ---------------------------------------------------------------------------------

CoinShopExterior = CoinShopExterior or {}
local self = CoinShopExterior
-------------------------------- 消息定义 --------------------------------
CoinShopExterior.Event = {}
CoinShopExterior.Event.XXX = "CoinShopExterior.Msg.XXX"

CoinShopExterior.FILTER_ALL = 0
CoinShopExterior.FILTER_SHOW = 1
CoinShopExterior.FILTER_HIDE = 2

CoinShopExterior.tFilterType =
{
    CoinShopExterior.FILTER_ALL,
    EQUIPMENT_SUB.HELM,
    EQUIPMENT_SUB.CHEST,
    EQUIPMENT_SUB.BANGLE,
    EQUIPMENT_SUB.WAIST,
    EQUIPMENT_SUB.BOOTS,
}

CoinShopExterior.tFilterHide =
{
    CoinShopExterior.FILTER_SHOW,
    CoinShopExterior.FILTER_HIDE,
}

CoinShopExterior.tSubStatus =
{
    CoinShopExterior.FILTER_ALL,
    GET_STATUS.COLLECTED,
    GET_STATUS.NOT_COLLECTED,
}

function CoinShopExterior.Init()

end

function CoinShopExterior.UnInit()

end

function CoinShopExterior.OnLogin()

end

function CoinShopExterior.OnFirstLoadEnd()

end

function CoinShopExterior.GetSubStatus(dwID)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return GET_STATUS.INVALID
    end
    local nStatus = GET_STATUS.INVALID
    local tInfo = GetExterior().GetExteriorInfo(dwID)
    local bCollect = hPlayer.IsExteriorCollected(dwID)
    if tInfo.bIsInShop then
        nStatus = GET_STATUS.SHOP
    else
        if bCollect then
            nStatus = GET_STATUS.COLLECTED
        else
            nStatus = GET_STATUS.NOT_COLLECTED
        end
    end
    return nStatus
end

function CoinShopExterior.SubFilterByType(dwID, nFilterType)
    if nFilterType == CoinShopExterior.FILTER_ALL then
        return true
    end
    local hExterior = GetExterior()
    if not hExterior then
        return false
    end

    local tInfo = hExterior.GetExteriorInfo(dwID)
    if tInfo.nSubType == nFilterType then
        return true
    end
    return false
end

function CoinShopExterior.SubFilterByGenre(dwID, nFilterGenre)
    if nFilterGenre == CoinShopExterior.FILTER_ALL then
        return true
    end
    local hExterior = GetExterior()
    if not hExterior then
        return false
    end

    local tInfo = hExterior.GetExteriorInfo(dwID)
    if tInfo.nGenre == nFilterGenre then
        return true
    end
    return false
end

function CoinShopExterior.SubFilterByStatus(dwID, nFilterStatus)
    if nFilterStatus == CoinShopExterior.FILTER_ALL then
        return true
    end
    local hExterior = GetExterior()
    if not hExterior then
        return false
    end

    local nStatus = self.GetSubStatus(dwID)
    if nStatus == nFilterStatus then
        return true
    end

    return false
end

function CoinShopExterior.SubFilterByShow(dwID, nHideFilter)
    if nHideFilter == CoinShopExterior.FILTER_ALL then
        return true
    end

    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return false
    end

    local nFlag = hPlayer.GetExteriorHideFlag(dwID)
    if ((nFlag == EXTERIOR_HIDE_TYPE.NOT_HIDE and nHideFilter == CoinShopExterior.FILTER_SHOW ) or (nFlag == EXTERIOR_HIDE_TYPE.HIDE and nHideFilter == CoinShopExterior.FILTER_HIDE)) then
        return true
    end
    return false
end

function CoinShopExterior.FilterSubList(tList, nFilterGenre, nFilterType, nFilterStatus)
    local tFilterList = {}
    for _, tSub in ipairs(tList) do
        local dwID = tSub[1]
        local bFilter = self.SubFilterByGenre(dwID, nFilterGenre) and self.SubFilterByType(dwID, nFilterType) and self.SubFilterByStatus(dwID, nFilterStatus)
        if bFilter then
            table.insert(tFilterList, tSub)
        end
    end

    if nFilterStatus == GET_STATUS.COLLECTED then
        local hPlayer = GetClientPlayer()
        local fnSort = function(tLeft, tRight)
            local nLeftTime = hPlayer.GetExteriorCollectTime(tLeft[1])
            local nRightTime = hPlayer.GetExteriorCollectTime(tRight[1])
            return nLeftTime > nRightTime
        end
        table.sort(tFilterList, fnSort)
    end

    return tFilterList
end

function CoinShopExterior.GetSetDyeingInfo(tSub)
    local hExteriorClient = GetExterior()
    if not hExteriorClient then
        return
    end
    for _, dwID in ipairs(tSub) do
        local tExteriorInfo = hExteriorClient.GetExteriorInfo(dwID)
        if tExteriorInfo.nDyeingIDUpperLimit > 0 then
            return true, dwID, tExteriorInfo.nDyeingIDUpperLimit
        end
    end
    return false
end

function CoinShopExterior.GetSetStatus(tSub)
    local nStatus = GET_STATUS.INVALID
    local _, _, bShop, nCollected = self.GetSetInfo(tSub)
    local nCount = #tSub
    if bShop then
        nStatus = GET_STATUS.SHOP
    else
        if nCollected == nCount then
            nStatus = GET_STATUS.COLLECTED
        -- elseif nCollected <= 0 then
        --     nStatus = GET_STATUS.NOT_COLLECTED
        -- else
        --     nStatus = GET_STATUS.COLLECTING
        else
            nStatus = GET_STATUS.NOT_COLLECTED
        end
    end
    return nStatus
end

function CoinShopExterior.GetSetInfo(tSub)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local hExteriorClient = GetExterior()
    if not hExteriorClient then
        return
    end
    local hCoinShopClient = GetCoinShopClient()
    if not hCoinShopClient then
        return
    end

    local nCoin = 0
    local nOriginalCoin = 0
    local nHave = 0
    local bShop = true
    local nCollected = 0
    local nDelete = 0
    local bStorage = false
    for _, dwID in ipairs(tSub) do
        local tExteriorInfo = hExteriorClient.GetExteriorInfo(dwID)
        tExteriorInfo.eGoodsType = COIN_SHOP_GOODS_TYPE.EXTERIOR
        local bHave = hPlayer.IsExistExterior(dwID)
        if bHave then
            nHave = nHave + 1
        else
            local nPrice, nOriginalPrice = CoinShop_GetShowPrice(tExteriorInfo)
            if nPrice > 0 then
                nCoin = nCoin + nPrice
                nOriginalCoin = nOriginalCoin + nOriginalPrice
            end
        end
        local bCollect = hPlayer.IsExteriorCollected(dwID)
        bShop = tExteriorInfo.bIsInShop
        if not bShop and bCollect then
            nCollected = nCollected + 1
        end

        local nFlag = hPlayer.GetExteriorHideFlag(dwID)
        if nFlag == EXTERIOR_HIDE_TYPE.DELETE then
            nDelete = nDelete + 1
        end
        local nHaveType = hCoinShopClient.CheckAlreadyHave(COIN_SHOP_GOODS_TYPE.EXTERIOR, dwID)
        if nHaveType == COIN_SHOP_OWN_TYPE.STORAGE then
            bStorage = true
        end
    end
    return nHave, nCoin, bShop, nCollected, nOriginalCoin, nDelete, bStorage
end

function CoinShopExterior.SetFilterByGenre(tSet, nFilterGenre)
    if nFilterGenre == CoinShopExterior.FILTER_ALL then
        return true
    end
    local hExterior = GetExterior()
    if not hExterior then
        return false
    end

    if tSet.nGenre == nFilterGenre then
        return true
    end
    return false
end

function CoinShopExterior.SetFilterByStatus(tSet, nFilterStatus)
    if nFilterStatus == CoinShopExterior.FILTER_ALL then
        return true
    end
    local hExterior = GetExterior()
    if not hExterior then
        return false
    end

    local nStatus = self.GetSetStatus(tSet.tSub)
    if nStatus == nFilterStatus then
        return true
    end

    return false
end

function CoinShopExterior.SetFilterByShow(tSet, nHideFilter)
    if nHideFilter == CoinShopExterior.FILTER_ALL then
        return true
    end

    local nFlag = self.GetShowBySet(tSet.tSub)
    if ((nFlag == EXTERIOR_HIDE_TYPE.NOT_HIDE and nHideFilter == CoinShopExterior.FILTER_SHOW) or (nFlag == EXTERIOR_HIDE_TYPE.HIDE and nHideFilter == CoinShopExterior.FILTER_HIDE)) then
        return true
    end

    return false
end

function CoinShopExterior.GetShowBySet(tSub)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return false
    end
    for k, dwID in ipairs(tSub) do
        local nFlag = hPlayer.GetExteriorHideFlag(dwID)
        if nFlag == EXTERIOR_HIDE_TYPE.HIDE then
            return nFlag
        end
    end
    return EXTERIOR_HIDE_TYPE.NOT_HIDE
end

function CoinShopExterior.GetSetCollectTime(tSub)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local nCollectTime = 0
    for _, dwID in ipairs(tSub) do
        local bCollect = hPlayer.IsExteriorCollected(dwID)
        if bCollect then
            local nTime = hPlayer.GetExteriorCollectTime(dwID)
            nCollectTime = math.max(nCollectTime, nTime)
        end
    end
    return nCollectTime
end

function CoinShopExterior.FilterSetList(tList, nFilterGenre, nFilterStatus, nFilterHide, bSimpleMode)
    local tFilterList = {}
    local tSubGenreMap = {}
    for _, tSet in ipairs(tList) do
        local bFilter = self.SetFilterByGenre(tSet, nFilterGenre) and self.SetFilterByStatus(tSet, nFilterStatus) and self.SetFilterByShow(tSet, nFilterHide)
        if bFilter then
            if not bSimpleMode then
                table.insert(tFilterList, tSet)
            else
                if not tSubGenreMap[tSet.nSubGenre] then
                    table.insert(tFilterList, tSet)
                    tSubGenreMap[tSet.nSubGenre] = {tSet}
                else
                    table.insert(tSubGenreMap[tSet.nSubGenre], tSet)
                end
            end
        end
    end

    if nFilterStatus == GET_STATUS.COLLECTED then
        local fnSort = function(tLeft, tRight)
            local nLeftTime = CoinShopExterior.GetSetCollectTime(tLeft.tSub)
            local nRightTime = CoinShopExterior.GetSetCollectTime(tRight.tSub)
            return nLeftTime > nRightTime
        end
        table.sort(tFilterList, fnSort)
    end

    for nSubGenre, tSubGenre in pairs(tSubGenreMap) do
        tSubGenreMap[nSubGenre] = Lib.ReverseTable(tSubGenre)
    end
    return tFilterList, tSubGenreMap
end

function CoinShopExterior.GetChangeColorList(dwExteriorID)
	local hPlayer = GetClientPlayer()
    local hExterior = GetExterior()
    if not hExterior then
        return {}
    end

	local hCoinShopClient = GetCoinShopClient()
    local tExteriorInfo = hExterior.GetExteriorInfo(dwExteriorID)
    local tExteriroList = hExterior.GetExteriorSubSuitInfo(tExteriorInfo.nSubSetID)
    local tList = {}
    for nIndex, dwID in ipairs(tExteriroList) do
		local nHaveType = hCoinShopClient.CheckAlreadyHave(COIN_SHOP_GOODS_TYPE.EXTERIOR, dwID)

		if nHaveType == COIN_SHOP_OWN_TYPE.EQUIP then
			local nTimeType = hPlayer.GetExteriorTimeLimitInfo(dwID)
			if nTimeType == EXTERIOR_TIME_TYPE.LIMIT then
				table.insert(tList, {dwID})
			end

		elseif nHaveType == COIN_SHOP_OWN_TYPE.NOT_HAVE or nHaveType == COIN_SHOP_OWN_TYPE.FREE_TRY_ON then
            table.insert(tList, {dwID})
        end
    end
    return tList
end

function CoinShopExterior.Collect(dwID)
    if not g_pClientPlayer then
        return
    end
    local _, nGold = CoinShop_GetCollectInfo(COIN_SHOP_GOODS_TYPE.EXTERIOR, dwID)
    local tMoney = g_pClientPlayer.GetMoney()
    local nMyGold = UnpackMoney(tMoney)
    if nGold > nMyGold then
        UIHelper.ShowConfirm(g_tStrings.COLLECT_LESS_MONEY)
        return
    end

    local fnSureAction = function()
        local nRetCode = g_pClientPlayer.CollectExterior(dwID)
        if nRetCode ~= EXTERIOR_COLLECT_RESULT_CODE.SUCCESS then
            local szMsg = g_tStrings.tCollectRespond[nRetCode]
            OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
            OutputMessage("MSG_SYS", szMsg .. "\n")
        end
    end

    local szExteriorName = CoinShop_GetGoodsName(COIN_SHOP_GOODS_TYPE.EXTERIOR, dwID)
    local szMessage = string.format(g_tStrings.COLLECT_SURE1, nGold, UIHelper.GBKToUTF8(szExteriorName))
    UIHelper.ShowConfirm(szMessage, fnSureAction, nil, true)
end

function CoinShopExterior.IsSubInCurrectList(dwID, bCollect)
    local tInfo = GetExterior().GetExteriorInfo(dwID)
    return bCollect ~= tInfo.bIsInShop
end

function CoinShopExterior.GetSetHaveInfo(bCollect)
    local tAllExterior = GetPlayerAllExterior()
    local fnIsHave = function(dwID, tInfo)
        local bCurrent = self.IsSubInCurrectList(dwID, bCollect)
        if not bCurrent then
            return
        end
        local tSet = Table_GetExteriorSet(tInfo.nSet)
        local tSub = tSet.tSub
        local nCount = #tSub
        local nSetHave = self.GetSetInfo(tSub)

        if nSetHave == nCount then
            return true
        end

        return false
    end
    local nHave = 0
    local tSetMap = {}
    for _, tExterior in ipairs(tAllExterior) do
        local dwID = tExterior.dwExteriorID
        local tInfo = GetExterior().GetExteriorInfo(dwID)
        if not tSetMap[tInfo.nSet] then
            if fnIsHave(dwID, tInfo) then
                nHave = nHave + 1
            end
            tSetMap[tInfo.nSet] = true
        end
    end
    return nHave
end

function CoinShopExterior.GetSubHaveInfo(bCollect)
    local tAllExterior = GetPlayerAllExterior()
    local nHave = 0

    for _, tExterior in ipairs(tAllExterior) do
        local dwID = tExterior.dwExteriorID
        if self.IsSubInCurrectList(dwID, bCollect) then
            nHave = nHave + 1
        end
    end

    return nHave
end

function CoinShopExterior.IsOnSetFilter(nGenre, nStatus, nHide)
    return nGenre ~= CoinShopExterior.FILTER_ALL or nStatus ~= CoinShopExterior.FILTER_ALL or nHide ~= CoinShopExterior.FILTER_ALL
end

function CoinShopExterior.IsOnSubFilter(nGenre, nType, nStatus)
    return nGenre ~= CoinShopExterior.FILTER_ALL or nType ~= CoinShopExterior.FILTER_ALL or nStatus ~= CoinShopExterior.FILTER_ALL
end

local t0YuanGouInfo = {
    [11634] = 181
}
function CoinShopExterior.SubShow0YuanGou(dwID)
    return dwID and t0YuanGouInfo[dwID] and CoinShopData.GetWelfare(t0YuanGouInfo[dwID])
end

function CoinShopExterior.SetShow0YuanGou(tSub)
    for _, dwID in ipairs(tSub) do
        if CoinShopExterior.SubShow0YuanGou(dwID) then
            return true
        end
    end
    return false
end

Event.Reg(CoinShopExterior, "ADD_EXTERIOR", function (dwID)
    RedpointHelper.Exterior_SetNew(dwID, true)
end)