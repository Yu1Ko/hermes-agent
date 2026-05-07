PropsSort = PropsSort or {className = "PropsSort"}

local m_tParam = {}
local m_register = {}
local m_tbSotring = {}


local GetPlayerItem = ItemData.GetPlayerItem
local ONCE_SORT_COUNT = 20
local DELAY_GS_CALL = 0.05
local COMMON_FILTER_CLASS = 6 --无法分到任何分类里的道具默认分到通用-其他分类
local COMMON_FILTER_SUB = 5

local function GetSortCount(key)
    return key == "bank_warehouse" and 1 or ONCE_SORT_COUNT
end

function PropsSort.Event(key)
    if key == "bag" then
        Event.Dispatch("BAG_SORT", true)
    end
end

function PropsSort.UnEvent(key)
    if key == "bag" then
        Event.Dispatch("BAG_SORT", false)
    end
end

function PropsSort.Register(key)
    m_register[key] = m_register[key] or {}

    local tbEventTab = m_register[key]
------------------Reg -------------------------
    if key == "bag" then
        -- Event.Reg(tbEventTab,"BAG_ITEM_UPDATE",function()
        --     PropsSort.OnBagItemAdded(key)
        -- end)
        Event.Reg(tbEventTab,"PLAYER_DEATH",function()
            PropsSort.EndSort(key)
        end)
    elseif key == "bank" then
        -- Event.Reg(tbEventTab,"BAG_ITEM_UPDATE",function()
        --     PropsSort.OnBagItemAdded(key)
        -- end)
        Event.Reg(tbEventTab,"PLAYER_DEATH",function()
            PropsSort.EndSort(key)
        end)
    end
end

function PropsSort.UnRegister(key)
    m_tbSotring[key] = false
    Event.UnRegAll(m_register[key])
    m_register[key] = {}
end

function PropsSort.BeginSort(tList, tAllBoxList, key)
    m_tbSotring[key] = true --bSorting

    local tSortPosList, tPos2IdList = PropsSort.UpdateBigBagSort(tList, tAllBoxList)

    --- tSortPosList{
    --- nBox，nx物品当前位置
    --- TnBox，TnID 物品需要交换的位置
    --- 0/1 是否已进行交换
    --- }
    --- 
    --- tPos2IdList 
    --- 记录tSortPosList中nBox，nx对应tSortPosList的位置
    --- 
    --- nToSortNum 需要交换的次数
    m_tParam[key] = { tSortPosList = tSortPosList, tPos2IdList = tPos2IdList, nToSortNum = #tSortPosList}

    PropsSort.Event(key)
    PropsSort.Register(key)
    PropsSort.Sorting(key)
end

function PropsSort.EndSort(key)
    TipsHelper.ShowNormalTip("整理结束")
    PropsSort.UnEvent(key)
    PropsSort.UnRegister(key)
end

function PropsSort.Sorting(key)
    --- 
    --- nInSortCount 当前交换的个数
    --- 
    --- tInSortingList 记录当前在交换的位置

    local nMaxSortCount = GetSortCount(key)
    local function ParallelSwap(key)

        if m_tParam[key].nToSortNum <= 0 then
        --- 只有当收到回调时才结束sort
            PropsSort.EndSort(key)
            return
        end

        local tInSortingList = {}
        local nInSortCount = 0

        for i, tbInfo in ipairs(m_tParam[key].tSortPosList) do
            if tbInfo[5] == 0 then
                local dwBox = tbInfo[1]
                local dwX = tbInfo[2]
                local dwTBox = tbInfo[3]
                local dwTX = tbInfo[4]
                if dwBox == dwTBox and dwX == dwTX then
                    m_tParam[key].nToSortNum = m_tParam[key].nToSortNum - 1
                    m_tParam[key].tSortPosList[i][5] = 1
                else
                    local item = GetPlayerItem(g_pClientPlayer, dwBox, dwX)
                    if item then
                        if (not tInSortingList[dwBox] or not tInSortingList[dwBox][dwX]) and 
                            (not tInSortingList[dwTBox] or not tInSortingList[dwTBox][dwTX]) then

                            if not tInSortingList[dwBox] then
                                tInSortingList[dwBox] = {}
                            end
                            tInSortingList[dwBox][dwX] = true

                            if not tInSortingList[dwTBox] then
                                tInSortingList[dwTBox] = {}
                            end
                            tInSortingList[dwTBox][dwTX] = true

                            local bResult = ItemData.OnExchangeItem(dwBox, dwX, dwTBox, dwTX, nil, false)
                            if not bResult then
                                -- 交换失败时不做其他处理
                            else
                                if m_tParam[key].tPos2IdList[dwTBox] and m_tParam[key].tPos2IdList[dwTBox][dwTX] then
                                    local nTIndex = m_tParam[key].tPos2IdList[dwTBox][dwTX]
                                    m_tParam[key].tSortPosList[nTIndex][1] = dwBox
                                    m_tParam[key].tSortPosList[nTIndex][2] = dwX
                                    m_tParam[key].tPos2IdList[dwBox][dwX] = nTIndex
                                    m_tParam[key].tPos2IdList[dwTBox][dwTX] = nil
                                end
                            end
                            nInSortCount = nInSortCount + 1
                            m_tParam[key].nToSortNum = m_tParam[key].nToSortNum - 1
                            m_tParam[key].tSortPosList[i][5] = 1

                            -- 超过ONCE_SORT_COUNT个的等下再交换，防止协议发送过多掉线
                            if m_tParam[key].nToSortNum <= 0 or nInSortCount >= nMaxSortCount then
                                Timer.AddWaitGSResponse(PropsSort, function () ParallelSwap(key) end, DELAY_GS_CALL)
                                return
                            end
                        end
                    else
                        m_tParam[key].nToSortNum = m_tParam[key].nToSortNum - 1
                        m_tParam[key].tSortPosList[i][5] = 1
                    end
                end
            end
        end

        if nInSortCount < nMaxSortCount then
            Timer.AddWaitGSResponse(PropsSort, function () ParallelSwap(key) end)
            return
        end
	end

    ParallelSwap(key)
end

function PropsSort.GetItemFilterClass(item)
    local nFilterClass, nFilterSub
    for nClass, tData in ipairs(ITEM_FILTER_SETTING) do
        if nClass >= 1 and nClass <= 8 then
            if tData.tChildTab then --存在二级分类
                for nSub, _ in ipairs(tData.tChildTab) do
                    local nTag = Table_GetBigBagFilterTag(nClass, nSub)
                    if BagViewData.IsMatchFilter(item, nClass, nSub, nTag) then
                        nFilterClass = nClass
                        nFilterSub = nSub
                        return nFilterClass, nFilterSub
                    end
                end
            else
                local nTag = Table_GetBigBagFilterTag(nClass)
                if BagViewData.IsMatchFilter(item, nClass, 0, nTag) then
                    nFilterClass = nClass
                    nFilterSub = 0
                    return nFilterClass, nFilterSub
                end
            end
        end
    end

    --全部筛选完后检查一遍是否有道具不属于任何分类，默认放入其他
    if not nFilterClass or not nFilterSub then
        nFilterClass = COMMON_FILTER_CLASS
        nFilterSub = COMMON_FILTER_SUB
    end

    return nFilterClass, nFilterSub
end

function PropsSort.UpdateBigBagSort(tList, tAllBoxList)
    local aGenre = {
        [ITEM_GENRE.TASK_ITEM] = 1, --ITEM_GENRE.TASK_ITEM,任务道具
        [ITEM_GENRE.EQUIPMENT] = 2, --ITEM_GENRE.EQUIPMENT 装备
        [ITEM_GENRE.BOOK] = 3, --ITEM_GENRE.BOOK 书籍
        [ITEM_GENRE.POTION] = 4, --ITEM_GENRE.POTION 药品
        [ITEM_GENRE.MATERIAL] = 5    --ITEM_GENRE.MATERIAL 材料
    }
    local aSub = {
        [EQUIPMENT_SUB.HORSE] = 1, --坐骑
        [EQUIPMENT_SUB.PACKAGE] = 2, --包裹
        [EQUIPMENT_SUB.MELEE_WEAPON] = 3, --近战武器
        [EQUIPMENT_SUB.RANGE_WEAPON] = 4, --远程武器
    }
    
    --- 对背包内的物品进行排序
    local player = g_pClientPlayer
    for k, v in pairs(tList) do
        local item = GetPlayerItem(player, v[1], v[2])
        table.insert(tList[k], item)
        local nFilterClass, nFilterSub = PropsSort.GetItemFilterClass(item)
        table.insert(tList[k], nFilterClass)
        table.insert(tList[k], nFilterSub)
    end

    local function fnDegree(tA, tB)
        local item = tA[3]
        local itemT = tB[3]

        -- 比较筛选分类
        local nClass1 = tA[4]
        local nClass2 = tB[4]
        local nSub1   = tA[5]
        local nSub2   = tB[5]
        if nClass1 and nClass2 and nSub1 and nSub2 then
            if nClass1 ~= nClass2 then
                return nClass1 < nClass2
            elseif nSub1 ~= nSub2 then
                return nSub1 < nSub2
            end
        end

        -- 比较物品类型
        local nG, nGT = aGenre[item.nGenre] or (100 + item.nGenre), aGenre[itemT.nGenre] or (100 + itemT.nGenre)
        if nG ~= nGT then
            return nG < nGT
        end

        -- 如果是装备，比较装备子类型
        if itemT.nGenre == ITEM_GENRE.EQUIPMENT then
            local nS, nST = aSub[item.nSub] or (100 + item.nSub), aSub[itemT.nSub] or (100 + itemT.nSub)
            if nS ~= nST then
                return nS < nST
            end

            -- 近战或远程武器，比较详细属性
            if itemT.nSub == EQUIPMENT_SUB.MELEE_WEAPON or itemT.nSub == EQUIPMENT_SUB.RANGE_WEAPON then
                if item.nDetail ~= itemT.nDetail then
                    return item.nDetail < itemT.nDetail
                end
            -- 包裹，比较当前耐久度
            elseif itemT.nSub == EQUIPMENT_SUB.PACKAGE then
                if item.nCurrentDurability ~= itemT.nCurrentDurability then
                    return item.nCurrentDurability > itemT.nCurrentDurability
                end
            end
        end
        

        -- 比较道具品质
        local nQuality1 = item.nQuality
        local nQuality2 = itemT.nQuality
        if nQuality1 ~= nQuality2 then
            return nQuality1 > nQuality2
        end

        -- 比较道具类型
        local nTabType1 = item.dwTabType
        local nTabType2 = itemT.dwTabType
        if nTabType1 ~= nTabType2 then
            return nTabType1 < nTabType2
        end

        -- 比较道具Index
        local nIndex1 = item.dwIndex
        local nIndex2 = itemT.dwIndex
        if nIndex1 ~= nIndex2 then
            return nIndex1 < nIndex2
        end

        -- 比较道具剩余时间
        local nLeftTime1 = item.GetLeftExistTime()
        local nLeftTime2 = itemT.GetLeftExistTime()
        if nLeftTime1 ~= 0 and nLeftTime2 == 0 then return true end
        if nLeftTime1 == 0 and nLeftTime2 ~= 0 then return false end
        if nLeftTime1 ~= 0 and nLeftTime2 ~= 0 and nLeftTime1 ~= nLeftTime2 then
            return nLeftTime1 < nLeftTime2
        end

        -- 比较道具堆叠数量
        local nStackNum1 = item.nStackNum
        local nStackNum2 = itemT.nStackNum
        if nStackNum1 ~= nStackNum2 then
            return nStackNum1 > nStackNum2
        end

        return item.dwID < itemT.dwID
    end

    table.sort(tList, fnDegree)

    --- 获取映射表
    
    local tResult = {}
    local tResult2 = {}

    local function GetBagContainType(dwBox)
        if dwBox == INVENTORY_GUILD_BANK  then
            return 0 --帮会仓库没有特殊背包
        end

        local dwGener, dwSub = player.GetContainType(dwBox)
        if dwGener == ITEM_GENRE.BOOK then
            return 4
        end
        if dwGener == ITEM_GENRE.MATERIAL then
            return dwSub
        end
        return 0
    end

    local function GetSpecialBoxPos(tABList)
        local tNormalList = {}
        local tSpecialBag  = {
            [BAG_CONTAIN_TYPE.CASTING] = {},	--石矿包
            [BAG_CONTAIN_TYPE.MEDICAL] = {},	--草药包
            [BAG_CONTAIN_TYPE.BOOK]    = {},	--书包
        }
        for _, v in pairs(tABList) do
            local cType = GetBagContainType(v[1])
            if cType and tSpecialBag[cType] then
                table.insert(tSpecialBag[cType], { v[1], v[2] })
            else
                table.insert(tNormalList, { v[1], v[2] })
            end
        end
        return tSpecialBag, tNormalList
    end
    local tSpecialBag, tNormalList = GetSpecialBoxPos(tAllBoxList)

    local dwTBox = 0
    local dwTX = 0
    local nPsCount = 0
    local nBkCount = 0 --书
	local nCtCount = 0 --石矿
	local nMeCount = 0 --草药
    local nSortPos = 0
    for _, v in pairs(tList) do
        local item = v[3]
        if item and item.nGenre == ITEM_GENRE.BOOK and nBkCount < #tSpecialBag[BAG_CONTAIN_TYPE.BOOK] then
            nBkCount = nBkCount + 1
            dwTBox = tSpecialBag[BAG_CONTAIN_TYPE.BOOK][nBkCount][1]
            dwTX = tSpecialBag[BAG_CONTAIN_TYPE.BOOK][nBkCount][2]
        elseif item and item.nGenre == ITEM_GENRE.MATERIAL and item.nSub == BAG_CONTAIN_TYPE.CASTING and nCtCount < #tSpecialBag[BAG_CONTAIN_TYPE.CASTING] then
            nCtCount = nCtCount + 1
            dwTBox = tSpecialBag[BAG_CONTAIN_TYPE.CASTING][nCtCount][1]
            dwTX = tSpecialBag[BAG_CONTAIN_TYPE.CASTING][nCtCount][2]
        elseif item and item.nGenre == ITEM_GENRE.MATERIAL and item.nSub == BAG_CONTAIN_TYPE.MEDICAL and nMeCount < #tSpecialBag[BAG_CONTAIN_TYPE.MEDICAL] then
            nMeCount = nMeCount + 1
            dwTBox = tSpecialBag[BAG_CONTAIN_TYPE.MEDICAL][nMeCount][1]
            dwTX = tSpecialBag[BAG_CONTAIN_TYPE.MEDICAL][nMeCount][2]
        else
            nPsCount = nPsCount + 1
            dwTBox = tNormalList[nPsCount][1]
            dwTX = tNormalList[nPsCount][2]
        end

        if v[1] ~= dwTBox or v[2] ~= dwTX then
            nSortPos = nSortPos + 1
            table.insert(tResult, {v[1], v[2], dwTBox, dwTX, 0})
            if not tResult2[v[1]] then
                tResult2[v[1]] = {}
            end
            tResult2[v[1]][v[2]] = nSortPos
        end
    end
    return tResult, tResult2
end

function PropsSort.IsItemSorting(key)
    return m_tbSotring[key]
end

function PropsSort.IsBagInSort()
    return PropsSort.IsItemSorting("bag")
end

function PropsSort.IsBankInSort()
    return PropsSort.IsItemSorting("bank") or PropsSort.IsItemSorting("bank_warehouse")
end

function PropsSort.Reset()
    for key, bSorting in pairs(m_tbSotring) do
        if bSorting then
            PropsSort.EndSort(key)
        end
    end
end