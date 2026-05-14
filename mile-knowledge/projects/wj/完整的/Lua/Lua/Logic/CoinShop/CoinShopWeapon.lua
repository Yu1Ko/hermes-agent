-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: CoinShopWeapon
-- Date: 2023-02-27 11:38:46
-- Desc: ?
-- ---------------------------------------------------------------------------------

CoinShopWeapon = CoinShopWeapon or {}
local self = CoinShopWeapon
-------------------------------- 消息定义 --------------------------------
CoinShopWeapon.Event = {}
CoinShopWeapon.Event.XXX = "CoinShopWeapon.Msg.XXX"

CoinShopWeapon.FILTER_ALL = -1

CoinShopWeapon.tStatus =
{
    CoinShopWeapon.FILTER_ALL,
    GET_STATUS.COLLECTED,
    GET_STATUS.NOT_COLLECTED,
}

function CoinShopWeapon.Init()

end

function CoinShopWeapon.UnInit()

end

function CoinShopWeapon.OnLogin()

end

function CoinShopWeapon.OnFirstLoadEnd()

end

function CoinShopWeapon.GetStatus(dwID)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return GET_STATUS.INVALID
    end
    local nStatus = GET_STATUS.INVALID
    local bCollect = hPlayer.IsWeaponExteriorCollected(dwID)
    if bCollect then
        nStatus = GET_STATUS.COLLECTED
    else
        nStatus = GET_STATUS.NOT_COLLECTED
    end
    return nStatus
end

function CoinShopWeapon.FilterList(tList, bShop, nFilterStatus, nFilterType)
    local tFilterList = {}
    tFilterList = self.FilterByStatus(tList, bShop, nFilterStatus)
    tFilterList = self.FilterByType(tFilterList, bShop, nFilterType)
    return tFilterList

    -- for _, dwID in ipairs(tList) do
    --     local bFilter = self.FilterByStatus(dwID, nFilterStatus) and self.FilterByType(dwID, nFilterType)
    --     if bFilter then
    --         table.insert(tFilterList, dwID)
    --     end
    -- end
    -- if nFilterStatus == GET_STATUS.COLLECTED then
    --     local hPlayer = GetClientPlayer()
    --     local fnSort = function(dwLeft, dwRight)
    --         local nLeftTime = hPlayer.GetWeaponExteriorCollectTime(dwLeft)
    --         local nRightTime = hPlayer.GetWeaponExteriorCollectTime(dwRight)
    --         return nLeftTime > nRightTime
    --     end
    --     table.sort(tFilterList, fnSort)
    -- end
    -- return tFilterList
end

local function fnSortByID(tLeft, tRight)
    return tLeft.dwSortID > tRight.dwSortID
end

function CoinShopWeapon.FilterByStatus(tList, bShop, nFilterStatus)
    if nFilterStatus == CoinShopWeapon.FILTER_ALL then
        if bShop then
            table.sort(tList, fnSortByID)
        end
        return tList
    end

    local tFilterList = {}
    for _, t in ipairs(tList) do
        local dwID = t
        if bShop then
            dwID = t.dwID
        end
        local nStatus = self.GetStatus(dwID)
        if nStatus == nFilterStatus then
             table.insert(tFilterList, t)
        end
    end
    if bShop then
        table.sort(tFilterList, fnSortByID)
    end
    return tFilterList
end

function CoinShopWeapon.FilterByType(tList, bShop, nFilterType)
    if nFilterType == CoinShopWeapon.FILTER_ALL then
        return tList
    end
    local hExterior = GetExterior()
    local tFilterList = {}
    for _, t in ipairs(tList) do
        local dwID = t
        if bShop then
            dwID = t.dwID
        end
        local tInfo = CoinShop_GetWeaponExteriorInfo(dwID, hExterior)
        if tInfo.nDetailType == nFilterType then
            table.insert(tFilterList, t)
        end
    end
    return tFilterList
end

function CoinShopWeapon.Collect(dwID)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local _, nGold = CoinShop_GetCollectInfo(COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR, dwID)
    local tMoney = hPlayer.GetMoney()
    local nMyGold = UnpackMoney(tMoney)
    if nGold > nMyGold then
        local szMsg = g_tStrings.COLLECT_LESS_MONEY
        UIHelper.ShowConfirm(szMsg)
        --OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg .. "\n")
        return
    end

    local fnSureAction = function()
        local nRetCode = hPlayer.CollectWeaponExterior(dwID)
        if nRetCode ~= EXTERIOR_COLLECT_RESULT_CODE.SUCCESS then
            local szMsg = g_tStrings.tCollectRespond[nRetCode]
            OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
            OutputMessage("MSG_SYS", szMsg .. "\n")
        end
    end

    local szWeaponName = CoinShop_GetGoodsName(COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR, dwID)

    local szMessage = string.format(g_tStrings.COLLECT_SURE1, nGold, UIHelper.GBKToUTF8(szWeaponName))
    UIHelper.ShowConfirm(szMessage, fnSureAction, nil, true)
end

function CoinShopWeapon.GetHaveInfo(tList)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local nHave = 0
	for _, dwID in ipairs(tList) do
		local nHaveType = GetCoinShopClient().CheckAlreadyHave(COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR, dwID)
        local bHave = nHaveType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE
		if bHave then
			nHave = nHave + 1
		end
	end
	local nCount = #tList
	return nHave, nCount
end

function CoinShopWeapon.IsOnFilter(nStatus, nType)
    return nStatus ~= CoinShopWeapon.FILTER_ALL or nType ~= CoinShopWeapon.FILTER_ALL
end

function CoinShopWeapon.GetTypeFilterString(nFilterType)
    local szText = g_tStrings.STR_GUILD_ALL
    if nFilterType ~= CoinShopWeapon.FILTER_ALL then
        szText = g_tStrings.WeapenDetail[nFilterType]
    end
    return szText
end

Event.Reg(CoinShopExterior, "ADD_WEAPON_EXTERIOR", function (dwID)
    RedpointHelper.WeaponExterior_SetNew(dwID, true)
end)