-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: PakEquipResData
-- Date: 2025-03-05 10:22:01
-- Desc: ?
-- ---------------------------------------------------------------------------------

PakEquipResData = PakEquipResData or {className = "PakEquipResData"}
local self = PakEquipResData
-------------------------------- 消息定义 --------------------------------
PakEquipResData.Event = {}
PakEquipResData.Event.XXX = "PakEquipResData.Msg.XXX"

local m_tMyAllPakResMap = {}

function PakEquipResData.Init()
end

function PakEquipResData.UnInit()
end

function PakEquipResData.OnLogin()
end

function PakEquipResData.OnFirstLoadEnd()
end

function PakEquipResData.GetMyAllPakResource()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    m_tMyAllPakResMap = { tEquipMap = {}, tEquipSfxMap = {}}

    local fnInsert = function(tEquipList, tEquipSfxList)
        for _, tEquip in ipairs(tEquipList) do
            local szKey = PakEquipResData.MakeEquipPakResourceKey(tEquip)
            m_tMyAllPakResMap.tEquipMap[szKey] = 1
        end
        for _, tEquipSfx in ipairs(tEquipSfxList) do
            local szKey = PakEquipResData.MakeEquipSfxPakResourceKey(tEquipSfx)
            m_tMyAllPakResMap.tEquipSfxMap[szKey] = 1
        end
    end

    -- 发型
    local tHairList = hPlayer.GetAllHair(HAIR_STYLE.HAIR)
    for _, tHair in ipairs(tHairList) do
        local tInfo = {
            nSource = COIN_SHOP_GOODS_SOURCE.COIN_SHOP,
            dwType = COIN_SHOP_GOODS_TYPE.HAIR,
            dwID = tHair.dwID,
        }
        local tEquipList, tEquipSfxList = PakEquipResData.GetPakResource(hPlayer.nRoleType, {tInfo})
        fnInsert(tEquipList, tEquipSfxList)
    end
    -- 外装
    local tAllExterior = GetPlayerAllExterior()
    for _, tExterior in ipairs(tAllExterior) do
        local tInfo = {
            nSource = COIN_SHOP_GOODS_SOURCE.COIN_SHOP,
            dwType = COIN_SHOP_GOODS_TYPE.EXTERIOR,
            dwID = tExterior.dwExteriorID,
        }
        local tEquipList, tEquipSfxList = PakEquipResData.GetPakResource(hPlayer.nRoleType, {tInfo})
        fnInsert(tEquipList, tEquipSfxList)
    end
    -- 武器
    local tWeaponList = hPlayer.GetAllWeaponExterior()
    for _, tWeapon in ipairs(tWeaponList) do
        local tInfo = {
            nSource = COIN_SHOP_GOODS_SOURCE.COIN_SHOP,
            dwType = COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR,
            dwID = tWeapon.dwWeaponExteriorID,
        }
        local tEquipList, tEquipSfxList = PakEquipResData.GetPakResource(hPlayer.nRoleType, {tInfo})
        fnInsert(tEquipList, tEquipSfxList)
    end
    -- 挂件
    for i = 0, PENDENT_SELECTED_POS.TOTAL - 1 do
        local tList = hPlayer.GetAllPendent(i)
        for _, tItem in ipairs(tList) do
            local tInfo = {
                nSource = COIN_SHOP_GOODS_SOURCE.ITEM_TAB,
                dwID = tItem.dwItemIndex,
                tColor = {tItem.nColorID1, tItem.nColorID2, tItem.nColorID3},
            }
            local tEquipList, tEquipSfxList = PakEquipResData.GetPakResource(hPlayer.nRoleType, {tInfo})
            fnInsert(tEquipList, tEquipSfxList)
        end
    end
end

function PakEquipResData.MakeEquipPakResourceKey(tEquip)
    return string.format("%d_%d", tEquip.nFileType, tEquip.dwRepresentID)
end

function PakEquipResData.MakeEquipApexPakResourceKey(tEquip)
    return string.format("%d_%d", tEquip.nFileType, tEquip.dwRepresentID)
end

function PakEquipResData.MakeEquipSfxPakResourceKey(tEquipSfx)
    return string.format("%d_%d_%d", tEquipSfx.nFileType, tEquipSfx.dwRepresentID, tEquipSfx.dwEnchantID)
end

function PakEquipResData.IsMyEquipPakResource(tEquip)
    if not m_tMyAllPakResMap or not m_tMyAllPakResMap.tEquipMap then
        PakEquipResData.GetMyAllPakResource()
    end
    local tEquipMap = m_tMyAllPakResMap and m_tMyAllPakResMap.tEquipMap or {}
    local szKey = PakEquipResData.MakeEquipPakResourceKey(tEquip)
    return tEquipMap[szKey] ~= nil
end

function PakEquipResData.IsMyEquipSfxPakResource(tEquipSfx)
    if not m_tMyAllPakResMap or not m_tMyAllPakResMap.tEquipSfxMap then
        PakEquipResData.GetMyAllPakResource()
    end
    local tEquipMapSfx = m_tMyAllPakResMap and m_tMyAllPakResMap.tEquipSfxMap or {}
    local szKey = PakEquipResData.MakeEquipSfxPakResourceKey(tEquipSfx)
    return tEquipMapSfx[szKey] ~= nil
end

function PakEquipResData.FilterMyPakResource(tEquipList, tEquipSfxList)
    local tMyEquipList, tMyEquipSfxList = {}, {}
    for _, tEquip in ipairs(tEquipList) do
        if PakEquipResData.IsMyEquipPakResource(tEquip) then
            table.insert(tMyEquipList, tEquip)
        end
    end
    for _, tEquipSfx in ipairs(tEquipSfxList) do
        if PakEquipResData.IsMyEquipSfxPakResource(tEquipSfx) then
            table.insert(tMyEquipSfxList, tEquipSfx)
        end
    end
    return tMyEquipList, tMyEquipSfxList
end

function PakEquipResData.RecordRolePakResource(hPlayer)
    if not hPlayer then
        return
    end
    local tRepresentID = hPlayer.GetRepresentID()
    local tEquipList, tEquipSfxList = PakEquipResData.GetRepresentPakResource(hPlayer.nRoleType, tRepresentID.nHatStyle, tRepresentID)
    local tMyEquipList, tMyEquipSfxList = PakEquipResData.FilterMyPakResource(tEquipList, tEquipSfxList)
    ResCleanData.RecordLoadEquipRes(hPlayer.nRoleType, tMyEquipList, tMyEquipList, tMyEquipSfxList)
end

function PakEquipResData.GetPakResource(nRoleType, tList)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local hRewardsShop = GetRewardsShop()
    if not hRewardsShop then
        return
    end

    local tRepresentID = {}
    for i = 0, EQUIPMENT_REPRESENT.TOTAL-1 do
        tRepresentID[i] = 0
    end

    for _, tData in ipairs(tList) do
        local nSource = tData.nSource
        local dwType = tData.dwType
        local dwID = tData.dwID
        if nSource ==  COIN_SHOP_GOODS_SOURCE.COIN_SHOP then
            if dwType == COIN_SHOP_GOODS_TYPE.ITEM then
                local tInfo = hRewardsShop.GetRewardsShopInfo(dwID)
                CoinShopData.UpdateFromItem(tRepresentID, tInfo.dwItemTabType, tInfo.dwItemTabIndex, nil, false)
            elseif dwType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
                CoinShopData.UpdateExterior(tRepresentID, dwID, false)
            elseif dwType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
                CoinShopData.UpdateWeapon(tRepresentID, dwID)
            elseif dwType == COIN_SHOP_GOODS_TYPE.HAIR then
                CoinShopData.UpdateHair(tRepresentID, dwID)
            elseif dwType == COIN_SHOP_GOODS_TYPE.FACE then
                CoinShopData.UpdateFace(tRepresentID, dwID)
            end
        elseif nSource == COIN_SHOP_GOODS_SOURCE.ITEM_TAB then
            CoinShopData.UpdateFromItem(tRepresentID, ITEM_TABLE_TYPE.CUST_TRINKET, dwID, tData.tColorID, false)
        end
    end

    return PakEquipResData.GetRepresentPakResource(nRoleType, 0, tRepresentID)
end

function PakEquipResData.GetRepresentPakResource(nRoleType, nHatStype, tRepresentID)
    local tEquipList, tEquipSfxList = Player_GetPakEquipResource(nRoleType, nHatStype, tRepresentID)
    for i = #tEquipList, 1, -1 do
        if tRepresentID[tEquipList[i].nRepresentSub] == 0 then
            table.remove(tEquipList, i)
        end
    end
    for i = #tEquipSfxList, 1, -1 do
        if tRepresentID[tEquipSfxList[i].nRepresentSub] == 0 then
            table.remove(tEquipSfxList, i)
        end
    end
    return tEquipList, tEquipSfxList
end

Event.Reg(self, "ON_ADD_PENDANT", function()
    PakEquipResData.GetMyAllPakResource()
end)

Event.Reg(self, "ADD_EXTERIOR", function()
    PakEquipResData.GetMyAllPakResource()
end)

Event.Reg(self, "ADD_WEAPON_EXTERIOR", function()
    PakEquipResData.GetMyAllPakResource()
end)

Event.Reg(self, "ADD_HAIR", function()
    PakEquipResData.GetMyAllPakResource()
end)

Event.Reg(self, "PLAYER_LEAVE_GAME", function (nPlayerID)
    m_tMyAllPakResMap = {}
end)

Event.Reg(self, "PLAYER_DISPLAY_DATA_UPDATE", function()
    if g_pClientPlayer and g_pClientPlayer.dwID == arg0 then
        PakEquipResData.RecordRolePakResource(g_pClientPlayer)
    end
end)