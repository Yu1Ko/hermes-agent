-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: ShenBingUpgradeMgr
-- Date: 2024-06-27 16:43:56
-- Desc: ?
-- ---------------------------------------------------------------------------------

ShenBingUpgradeMgr = ShenBingUpgradeMgr or {className = "ShenBingUpgradeMgr"}
local self = ShenBingUpgradeMgr
-------------------------------- 消息定义 --------------------------------
ShenBingUpgradeMgr.Event = {}
ShenBingUpgradeMgr.Event.XXX = "ShenBingUpgradeMgr.Msg.XXX"

ShenBingUpgradeMgr.DEFAULT_LEVEL = 130

function ShenBingUpgradeMgr.Init()

end

function ShenBingUpgradeMgr.UnInit()

end

function ShenBingUpgradeMgr.CheckUpgrade()
    if g_pClientPlayer.nLevel < 120 then
        return false
    end

    local tKungFuList = SkillData.GetKungFuList() or {}
    local dwSelMKungFuID, nStage = nil, -1
    for k, v in ipairs(tKungFuList) do
        local dwMKungFuID = v[1]
        local nCurStage = ShenBingUpgradeMgr.GetCurWeapon(dwMKungFuID)
        if nCurStage >= nStage then
            nStage = nCurStage
            dwSelMKungFuID = dwMKungFuID
        end
    end

    local nCurStage, tWeaponList, bLock = ShenBingUpgradeMgr.GetCurWeapon(dwSelMKungFuID)
    local tWeaponInfo = tWeaponList and tWeaponList[1] or nil
    local nCost = tWeaponInfo and tWeaponInfo.nStoneCost or 0
    local nMaxStage = tWeaponInfo and tWeaponInfo.nMaxStage or 0
    local dwIndex = ShenBingUpgradeMgr.GetUpgradeIndex()
    local nCount = g_pClientPlayer.GetItemAmountInAllPackages(ITEM_TABLE_TYPE.OTHER, dwIndex)

    local bCanUpgrade = not bLock and nCount >= nCost and nCurStage ~= nMaxStage
    local bHasObtain = ShenBingUpgradeMgr.CheckShenBing(dwSelMKungFuID)

    if bCanUpgrade and bHasObtain then
        return true
    end

    return false
end

function ShenBingUpgradeMgr.CheckShenBing(dwMKungFuID)
    local bHasObtain = false
    local bShowFind  = false

    local nCurStage, tWeaponList, bLock = ShenBingUpgradeMgr.GetCurWeapon(dwMKungFuID)
    for _, v in pairs(tWeaponList) do
        local dwItemIndex = v.dwWeaponIndex
        local nQuestState = g_pClientPlayer.GetQuestPhase(v.dwQuestID)
        local bFinish = nQuestState == QUEST_PHASE.FINISH
        local nItemCount = g_pClientPlayer.GetItemAmountInAllPackages(ITEM_TABLE_TYPE.CUST_WEAPON, dwItemIndex)
        local bExist = nItemCount > 0
        bHasObtain = bHasObtain or bFinish
        if bFinish and not bExist then
            bShowFind = true
            break
        end
    end

    return not bShowFind and bHasObtain
end

--当前心法当前等级的所有橙武
function ShenBingUpgradeMgr.GetCurWeaponList(dwMKungFuID)
    local nLevel = ShenBingUpgradeMgr.DEFAULT_LEVEL
    local dwMKungFuID = dwMKungFuID
    local tAllWeaponList = Table_GetOrangeWeaponInfoByForceID(g_pClientPlayer.dwForceID)

    local tRes = {}
    for _, v in pairs(tAllWeaponList) do
        if v.dwMobileMKungFuID == dwMKungFuID and v.nLevel == nLevel then
            table.insert(tRes, v)
        end
    end

    table.sort(tRes, function (a, b)
        if a.nStage ~= b.nStage then
            return a.nStage < b.nStage
        end
        return a.dwID < b.dwID
    end)

    return tRes
end

--当前心法当前阶段的武器列表
function ShenBingUpgradeMgr.GetCurWeapon(dwMKungFuID)
    local bLock       = false
    local nStage      = 0
    local tWeaponInfo = nil
    local tList       = {}
    local tCurList    = ShenBingUpgradeMgr.GetCurWeaponList(dwMKungFuID)

    for i = 1, #tCurList do
        local tInfo = tCurList[i]
        local dwQuestID = tInfo.dwQuestID
        local nQuestState = g_pClientPlayer.GetQuestPhase(dwQuestID)
        if nQuestState == QUEST_PHASE.FINISH then
            if nStage ~= tInfo.nStage then
                tList = {}
            end
            nStage = tInfo.nStage
            table.insert(tList, tInfo)
        end
    end

    if IsTableEmpty(tList) then
        bLock = true
        nStage = 1
        for i = 1, #tCurList do
            local tInfo = tCurList[i]
            if tInfo.nStage == nStage then
                table.insert(tList, tInfo)
            end
        end
    end

    return nStage, tList, bLock
end

function ShenBingUpgradeMgr.GetUpgradeIndex()
    local nLevel = ShenBingUpgradeMgr.DEFAULT_LEVEL

    local tAllWeaponList = Table_GetOrangeWeaponInfoByForceID(g_pClientPlayer.dwForceID)
    local tState = {}
    local tLevel = {}

    for _, v in pairs(tAllWeaponList) do
        if not tState[v.nLevel] then
            tState[v.nLevel] = true
            table.insert(tLevel, {nLevel = v.nLevel, dwItemIndex = v.dwItemIndex})
        end
    end

    table.sort(tLevel, function (a, b)
        return a.nLevel < b.nLevel
    end)

    for _, v in pairs(tLevel) do
        if v.nLevel == nLevel then
            return v.dwItemIndex
        end
    end
end

function ShenBingUpgradeMgr.OnFirstLoadEnd()

end