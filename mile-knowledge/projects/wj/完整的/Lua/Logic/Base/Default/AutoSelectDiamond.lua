local MILLION_NUMBER   = 1048576 		--百分率基数
local NORMAL_CAPACITY  = 16				--最多放16个五行石
local SPECIAL_CAPACITY = 128			--精7、8级最多放16个五行石
local CAPACITY         = 16				--实际计算用的五行石容量
local STRENGTH_FULL    = 6				--一般装备栏满级
local STRENGTH_MAX     = 8				--装备栏最大等级
local DIAMOND_COUNT    = 6				--五行石种类
local MAX_RATE         = 100.0
local STRENGTH_WEAPON_EXPAND_LEVEL = 5	--武器装备栏5级时，精6也用128格子
local fMinCost         = math.huge		--最小价格
local tResult          = {}				--最优方案
local tTempResult      = {}				--存储临时方案
local tStone = {						--每种五行石具体数量、价格、价值（成功率）
    {count = 0, cost = 0, value = 0},
    {count = 0, cost = 0, value = 0},
    {count = 0, cost = 0, value = 0},
    {count = 0, cost = 0, value = 0},
    {count = 0, cost = 0, value = 0},
    {count = 0, cost = 0, value = 0},
    {count = 0, cost = 0, value = 0},
    {count = 0, cost = 0, value = 0},
}

local tPlayerDiamond = {}            --玩家背包五行石情况

local function BagIndexToInventoryIndex(nIndex)
    return INVENTORY_INDEX.PACKAGE + nIndex - 1
end

AutoSelectDiamond = {}
--[[
五行石消耗规则：
先消耗绑定的；
若皆为绑定，先消耗堆叠数小的；
若堆叠数一样，先消耗排列在前的。
]]
local function SortDiamond(tLeft, tRight)
    if tLeft.bBind == tRight.bBind then
        if tLeft.nStackNum == tRight.nStackNum then
            if tLeft.dwBox == tRight.dwBox then
                return tLeft.dwX < tRight.dwX
            end
            return tLeft.dwBox < tRight.dwBox
        end
        return tLeft.nStackNum < tRight.nStackNum
    end
    return tLeft.bBind and not tRight.bBind
end

local --获取单个五行石概率
function GetSingleDiamondValue(nEquipIndex, nLevel)
    local tMaterial = {}
    local tDiamond  = tPlayerDiamond[nLevel]

    for _, v in pairs(tDiamond) do
        for j = 1, v.nStackNum do
            table.insert(tMaterial, {v.dwBox, v.dwX})
            if #tMaterial >= CAPACITY then
                break
            end
        end
        if #tMaterial >= CAPACITY then
            break
        end
    end

    local _, _, nSuccessRate, _, _, nDiscountSuccessRate, bDiscount = GetStrengthEquipBoxInfo(nEquipIndex, tMaterial)
    local nRealRate = bDiscount and nDiscountSuccessRate or nSuccessRate

    while nRealRate == MILLION_NUMBER and #tMaterial > 1 do
        table.remove(tMaterial)
        _, _, nSuccessRate, _, _, nDiscountSuccessRate, bDiscount = GetStrengthEquipBoxInfo(nEquipIndex, tMaterial)
        nRealRate = bDiscount and nDiscountSuccessRate or nSuccessRate
    end
    local nTotalNum = #tMaterial
    nRealRate = nRealRate / nTotalNum * 100 / MILLION_NUMBER
    return nRealRate
end

--获取背包中五行石情况
local function FindDiamondInBag()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    --初始化
    fMinCost = math.huge
    for i = 1, DIAMOND_COUNT do
        tStone[i]         = {}
        tStone[i].count   = 0
        tStone[i].cost    = 0
        tStone[i].value   = 0
        tResult[i]        = 0
        tTempResult[i]    = 0
        tPlayerDiamond[i] = {}
    end

    local dwMapID = hPlayer.GetMapID()
    local nCount = 6

    if BattleFieldData.IsInTreasureBattleFieldMap() or UIscript_IsBoxLimitMap(dwMapID) then
        nCount = 1
    end

    --遍历背包找五行石
    for i = 1, nCount, 1 do
        local dwBox = BagIndexToInventoryIndex(i)
        local dwSize = hPlayer.GetBoxSize(dwBox)

        for dwX = 0, dwSize - 1 do
            local tItem = ItemData.GetPlayerItem(hPlayer, dwBox, dwX)
            if tItem and tItem.nGenre == ITEM_GENRE.DIAMOND and tItem.nDetail > 0 and tItem.nDetail <= DIAMOND_COUNT then	--五行石
                DataModel.AddItem(tItem)

                local bBind     = tItem.bBind
                local nLevel    = tItem.nDetail
                local nStackNum = tItem.nStackNum
                -- UILog(dwBox, dwX, nLevel, nStackNum)
                table.insert(tPlayerDiamond[nLevel], {dwBox = dwBox, dwX = dwX, nStackNum = nStackNum, bBind = bBind})
            end
        end
    end
    -- UILog(tPlayerDiamond)
end

--五行石排序并统计个数，价值，价格
local function GetDiamondInfo(nEquipIndex)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local tDiamonCostInfo              = Table_GetDiamondCost()
    local nBoxLevel, nBoxQuality       = hPlayer.GetEquipBoxStrength(nEquipIndex)
    local nBoxMaxLevel, nBoxMaxQuality = GetEquipBoxMaxStrengthInfo(nEquipIndex)

    if (nBoxLevel >= STRENGTH_FULL or (nEquipIndex == EQUIPMENT_SUB.MELEE_WEAPON and nBoxLevel == STRENGTH_WEAPON_EXPAND_LEVEL)) and nBoxMaxLevel == STRENGTH_MAX then
        CAPACITY = SPECIAL_CAPACITY
    else
        CAPACITY = NORMAL_CAPACITY
    end

    for i = 1, DIAMOND_COUNT do
        table.sort(tPlayerDiamond[i], SortDiamond)
        for k, v in pairs(tPlayerDiamond[i]) do
            tStone[i].count = tStone[i].count + v.nStackNum
        end
        if tStone[i].count > 0 then
            tStone[i].value = GetSingleDiamondValue(nEquipIndex, i)
        end
        tStone[i].cost = tDiamonCostInfo[i]
    end
end

--获取成功率超过100，价格最少的五行石放入方案
local function DFS(nCount, nID, fSumCost, fSumValue)
    if fSumCost > fMinCost or nCount > CAPACITY then
        return
    end

    if fSumValue >= MAX_RATE and fSumCost < fMinCost then
        fMinCost = fSumCost
        for i = 1, DIAMOND_COUNT do
            tResult[i] = tTempResult[i]
        end
        return
    end

    if nID == 0 then
        return
    end

    if tStone[nID].count ~= 0 and fSumValue + (CAPACITY - nCount) * tStone[nID].value < MAX_RATE then
        return
    end

    for i = 0, math.min(CAPACITY - nCount, tStone[nID].count) do
        tTempResult[nID] = i
        DFS(nCount + i, nID - 1, fSumCost + tStone[nID].cost * i, fSumValue + tStone[nID].value * i)
    end
    tTempResult[nID] = 0
end

--检查是否存在可行方案
local function CheckValuable()
    local nCount   = CAPACITY
    local fSumRate = 0
    local bResult  = false
    for i = DIAMOND_COUNT, 1, -1 do
        if tStone[i].count < nCount then
            fSumRate = fSumRate + tStone[i].count * tStone[i].value
            nCount = nCount - tStone[i].count
            tResult[i] = tStone[i].count
        else
            fSumRate = fSumRate + nCount * tStone[i].value
            tResult[i] = nCount
            nCount = 0
            break
        end
    end
    bResult = fSumRate >= MAX_RATE
    if bResult then
        tResult = {}
    end
    return bResult
end

function AutoSelectDiamond.Start(nEquipIndex)
    DataModel.ClearMaterial()

    local tMaterial = {}
    local bFailed = false
    FindDiamondInBag()
    GetDiamondInfo(nEquipIndex)

    if CheckValuable() then
        DFS(0, DIAMOND_COUNT, 0, 0)
    else
        bFailed = true
    end

    for i = DIAMOND_COUNT, 1, -1 do
        local nCount = tResult[i]
        while(nCount > 0)
        do
            for k, v in pairs(tPlayerDiamond[i]) do
                if nCount > v.nStackNum then
                    table.insert(tMaterial, {dwBox = v.dwBox, dwX = v.dwX, nStackNum = v.nStackNum})
                    nCount = nCount - v.nStackNum
                else
                    table.insert(tMaterial, {dwBox = v.dwBox, dwX = v.dwX, nStackNum = nCount})
                    nCount = 0
                    break
                end
            end
        end
    end
    return tMaterial, bFailed
end

function AutoSelectDiamond.UnInit()
    tResult     = {}
    tStone      = {}
    tTempResult = {}
    tPlayerDiamond = {}
end