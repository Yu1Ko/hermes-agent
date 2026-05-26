BagViewData = BagViewData or { className = "BagViewData" }

ITEM_SCREEN = {
    ALL = 1,
    ACCOUNT = 2,
    NOTBIND = 3,
    TIME = 4
}

ITEM_FILTER_TYPE = {
    [ITEM_SCREEN.ALL] = 1,
    [ITEM_SCREEN.ACCOUNT] = 111,
    [ITEM_SCREEN.NOTBIND] = 109,
    [ITEM_SCREEN.TIME] = 110
}

ADDITIONAL_FILTER_TABLE = {
    [1] = { bShowEmptyCell = true, szName = "背包", filterFunc = function(item)
        return true
    end }, -- 全部
    [109] = { bShowEmptyCell = false, filterFunc = function(item)
        if not item then
            return false
        end
        return not item.bBind
    end }, -- 非绑定
    [110] = { bShowEmptyCell = false, filterFunc = function(item)
        if not item then
            return false
        end
        return GetItemInfo(item.dwTabType, item.dwIndex).nExistType ~= ITEM_EXIST_TYPE.PERMANENT
    end }, -- 限时
    [111] = { bShowEmptyCell = false, filterFunc = function(item)
        if not item then
            return false
        end
        return item.bCanShared
    end }, -- 账号共享
    ---- 限时
    --[9] = {
    --    szType = "KItemInfo",
    --    szName = "限时",
    --    tCondition = {
    --        [1] = { nExistType = { 1, 2, 3, 4 } },
    --    }
    --},
    ---- 可交易
    --[10] = {
    --    szType = "KItem",
    --    szName = "可交易",
    --    tCondition = {
    --        [1] = { bBind = false },
    --    }
    --},
}

PVP_FILTER_TABLE = {
    [1] = { filterFunc = function(item)
        return true
    end, bShowEmptyCell = true },
    [2] = { szName = "PVP", filterFunc = function(item)
        if not item then
            return false
        end
        local bCanShowPVP = item.nGenre == ITEM_GENRE.EQUIPMENT and (item.nSub >= EQUIPMENT_SUB.MELEE_WEAPON and item.nSub <= EQUIPMENT_SUB.BANGLE)
        return bCanShowPVP and (item.nEquipUsage == 0 or item.nEquipUsage == 3)
    end },
    [3] = { szName = "PVE", filterFunc = function(item)
        if not item then
            return false
        end
        local bCanShowPVP = item.nGenre == ITEM_GENRE.EQUIPMENT and (item.nSub >= EQUIPMENT_SUB.MELEE_WEAPON and item.nSub <= EQUIPMENT_SUB.BANGLE)
        return bCanShowPVP and (item.nEquipUsage == 1 or item.nEquipUsage == 3)
    end },
    [4] = { szName = "PVX", filterFunc = function(item)
        if not item then
            return false
        end
        local bCanShowPVP = item.nGenre == ITEM_GENRE.EQUIPMENT and (item.nSub >= EQUIPMENT_SUB.MELEE_WEAPON and item.nSub <= EQUIPMENT_SUB.BANGLE)
        return bCanShowPVP and (item.nEquipUsage == 2 or item.nEquipUsage == 3)
    end }
}

BAG_FILTER_ORDER = { 0, 12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }

ITEM_FILTER_ICON_NAME = {
    ["全部"] = "All",
    
    ["武器"] = "WuQi",
    ["防具"] = "FangJu",
    ["首饰"] = "ShiPin",
    ["其他"] = "QiTa",
    
    --["外观"] = "WaiGuan",
    --["货币"] = "WaiGuan",
    ["药食"] = "YaoShi",
    ["帮会"] = "BangHui",
    ["活动"] = "HuoDong",
    ["家园"] = "JiaYuan",

    ["宝箱"] = "BaoXiang",
    ["强化"] = "QiangHua",
    ["材料"] = "CaiLiao",
    ["书籍"] = "ShuJi",
    
    ["百战"] = "BaiZhan",
    ["名望"] = "MinWang",
    ["任务"] = "RenWu",
}

ITEM_FILTER_SETTING = --优先按UI表分类，逻辑道具属性仅作为没有填UI表分类时补充用
{
    [0] = {
        szName = "全部",
    },
    [1] = {
        szType = "KItem",
        szName = "任务",
        tCondition = {
            [1] = { nGenre = 2 }
        }
    },
    -- 装备
    [2] = {
        szName = "装备",
        tChildTab = {
            -- 武器
            [1] = {
                szType = "KItem",
                tCondition = {
                    [1] = { nGenre = 0, nSub = { 0, 1, 13 } }
                }
            },
            -- 防具
            [2] = {
                szType = "KItem",
                tCondition = {
                    [1] = { nGenre = 0, nSub = { 2, 3, 6, 8, 9, 10 } }
                }
            },
            -- 首饰
            [3] = {
                szType = "KItem",
                tCondition = {
                    [1] = { nGenre = 0, nSub = { 4, 5, 7 } }
                }
            },
            -- 其他
            [4] = {
                szType = "KItem",
                tCondition = {
                    [1] = { nGenre = 0, nSub = { 11, 12, 14 } }
                }
            },
        },
    },
    -- 外观
    [3] = {
        szType = "KItem",
        szName = "外观",
        tCondition = {
            [1] = { nGenre = { 18, 19, 21, 22, 27 } },
            [2] = { nGenre = 0, nSub = { 15, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30 } },
            [3] = { nAucGenre = 4, nAucSub = 4 },
            [4] = { nGenre = { 5, 12 } },
        }
    },
    -- 货币
    [4] = {
        szName = "货币",
        szType = "FilterTag"
    },
    -- 消耗品
    [5] = {
        szName = "消耗品",
        tChildTab = {
            -- 药食
            [1] = {
                szType = "KItem",
                tCondition = {
                    [1] = { nGenre = 1 },
                    [2] = { nGenre = 14, nSub = { 1, 2, 3, 6 } },
                }
            },
            -- 帮会
            [2] = {
                szType = "KItem",
                tCondition = {
                    [1] = { nAucGenre = 14 },
                }
            },
            -- 家园
            [3] = {
                szType = "KItem",
                tCondition = {
                    [1] = { nGenre = 14, nSub = 4 },
                }
            },
            -- 活动
            [4] = {
                szType = "FilterTag"
            },
            -- 其他
            [5] = {
                szType = "KItem",
                tCondition = {
                    [1] = { nAucGenre = 22, nAucSub = 12 },
                    [2] = { nGenre = 24 },
                    [3] = { dwTabType = 5, dwIndex = 52765 },
                }
            },
        },
    },
    -- 通用
    [6] = {
        szName = "通用",
        tChildTab = {
            -- 宝箱
            [1] = {
                szType = "KItem",
                tCondition = {
                    [1] = { nGenre = 8 },
                }
            },
            -- 强化
            [2] = {
                szType = "KItem",
                tCondition = {
                    [1] = { nGenre = { 10, 11, 7 } },
                    [2] = { nAucGenre = 13 },
                }
            },
            -- 材料
            [3] = {
                szType = "KItem",
                tCondition = {
                    [1] = { nAucGenre = 10 }
                }
            },
            -- 书籍
            [4] = {
                szType = "KItem",
                tCondition = {
                    [1] = { nGenre = 4 },
                }
            },
            -- 其他
            [5] = {
                szType = "FilterTag"
            },
        },
    },
    ---- 家园
    [7] = {
        szName = "家园",
        szType = "KItem",
        tCondition = {
            [1] = { nGenre = 20 },
        }
    },
    -- 玩法
    [8] = {
        szName = "玩法",
        tChildTab = {
            [1] = { szType = "FilterTag" }, -- 百战
            [2] = { szType = "FilterTag" }, -- 名望
            [3] = { szType = "FilterTag" }, -- 节日活动
        }
    },
    ---- 新获得
    --[11] = {
    --    szName = "新获得",
    --    szType = "New"
    --},
    [12] = {
        szName = "临期",
        szType = "TimeLimited"
    },
}

COMMON_FILTER_CLASS = 6 --无法分到任何分类里的道具默认分到通用-其他分类
COMMON_FILTER_SUB = 5

function BagViewData.Init()
    Event.UnRegAll(BagViewData)
    Event.Reg(BagViewData, EventType.OnRoleLogin, function()
        BagViewData.ClearNewItem()
        BagViewData.tbCommonItem = {}
    end)

    Event.Reg(BagViewData, "SYNC_USER_PREFERENCES_END", function()
        BagViewData.LoadLockBoxData()
    end)

    Event.Reg(BagViewData, "BAG_ITEM_UPDATE", function(nBox, nIndex, bNewAdd)
        local item = ItemData.GetItemByPos(nBox, nIndex)
        local szPos = nBox .. "_" .. nIndex
        if ItemData.GetCurrentBag() == ItemData.BoxSet.Bag then
            if item and bNewAdd then
                BagViewData.RecordNewItem(szPos, item.dwID, true)
            elseif not item and not bNewAdd then
                BagViewData.RecordNewItem(szPos, nil, false)
            end
        end
    end)

    BagViewData.tbCommonItem = {}
    BagViewData.ClearNewItem()
end

function BagViewData.IsHaveNewItem_Main(nFilterMainClass)
    return BagViewData.tbNewItemFilterMain[nFilterMainClass] ~= nil and BagViewData.tbNewItemFilterMain[nFilterMainClass] > 0
end

function BagViewData.IsHaveNewItem_Sub(nFilterMainClass, nFilterSubClass)
    return BagViewData.tbNewItemFilterSubList[nFilterMainClass] ~= nil and BagViewData.tbNewItemFilterSubList[nFilterMainClass][nFilterSubClass] ~= nil
            and BagViewData.tbNewItemFilterSubList[nFilterMainClass][nFilterSubClass] > 0
end

function BagViewData.IsMatchCommon(hItem, nTargetMainClass, nTargetSubClass)
    local bIsCommon = nTargetMainClass == COMMON_FILTER_CLASS and
            (nTargetSubClass == COMMON_FILTER_SUB or nTargetSubClass == 0) and
            BagViewData.IsCommonItem(hItem)
    return bIsCommon
end

function BagViewData.RecordNewItem(szPos, dwIndex, bNew)
    local tData = BagViewData.tbNewItemIndex[szPos]

    if not tData and bNew then
        tData = {}
        local hItem = ItemData.GetItem(dwIndex)
        if hItem then
            for _, nFilterMainClass in ipairs(BAG_FILTER_ORDER) do
                local bMatch = BagViewData.IsMatchFilter(hItem, nFilterMainClass) or BagViewData.IsMatchCommon(hItem, nFilterMainClass, 0)
                if bMatch then
                    --print("Record main", dwIndex, nFilterMainClass)
                    BagViewData.tbNewItemFilterMain[nFilterMainClass] = BagViewData.tbNewItemFilterMain[nFilterMainClass] or 0
                    BagViewData.tbNewItemFilterMain[nFilterMainClass] = BagViewData.tbNewItemFilterMain[nFilterMainClass] + 1 -- 统计主类下的新获得数量

                    table.insert(tData, { nMain = nFilterMainClass, nSub = 0 })

                    BagViewData.tbNewItemFilterSubList[nFilterMainClass] = BagViewData.tbNewItemFilterSubList[nFilterMainClass] or {}
                    local tSubRecord = BagViewData.tbNewItemFilterSubList[nFilterMainClass]
                    local tSubList = Table_GetBigBagSubFilter(nFilterMainClass) --全部子类
                    for _, tSub in ipairs(tSubList) do
                        local nFilterSub = tSub.nSub
                        local bChildMatch = BagViewData.IsMatchFilter(hItem, nFilterMainClass, nFilterSub)
                                or BagViewData.IsMatchCommon(hItem, nFilterMainClass, nFilterSub)
                        if bChildMatch then
                            tSubRecord[nFilterSub] = tSubRecord[nFilterSub] or 0
                            tSubRecord[nFilterSub] = tSubRecord[nFilterSub] + 1 -- 统计子类下的新获得数量

                            table.insert(tData, { nMain = nFilterMainClass, nSub = nFilterSub })
                            --print("Record sub", dwIndex, nFilterMainClass, nFilterSub)
                        end
                    end
                end
            end
        end
    elseif tData and not bNew then
        for _, tFilterInfo in ipairs(tData) do
            if tFilterInfo.nSub == 0 then
                BagViewData.tbNewItemFilterMain[tFilterInfo.nMain] = BagViewData.tbNewItemFilterMain[tFilterInfo.nMain] - 1
            else
                BagViewData.tbNewItemFilterSubList[tFilterInfo.nMain][tFilterInfo.nSub] = BagViewData.tbNewItemFilterSubList[tFilterInfo.nMain][tFilterInfo.nSub] - 1
            end
        end
    end

    BagViewData.tbNewItemIndex[szPos] = bNew and tData or nil
end

-- 无法分到任何分类里的道具默认分到通用-其他分类
function BagViewData.IsCommonItem(hItem)
    if not hItem or not hItem.dwIndex then
        return false
    end

    if BagViewData.tbCommonItem[hItem.dwIndex] ~= nil then
        return BagViewData.tbCommonItem[hItem.dwIndex]
    end

    for _, nFilterMainClass in ipairs(BAG_FILTER_ORDER) do
        if nFilterMainClass ~= 0 then
            local bMatch = BagViewData.IsMatchFilter(hItem, nFilterMainClass) -- 忽略全部分类
            if bMatch then
                BagViewData.tbCommonItem[hItem.dwIndex] = false
                return false
            end
        end
    end

    BagViewData.tbCommonItem[hItem.dwIndex] = true
    return true
end

function BagViewData.ClearNewItem()
    BagViewData.tbNewItemFilterMain = {}
    BagViewData.tbNewItemFilterSubList = {}
    BagViewData.tbNewItemIndex = {}
end

function BagViewData.IsNewItem(nBox, nIndex)
    if BagViewData.tbNewItemIndex and nBox and nIndex then
        local szPos = nBox .. "_" .. nIndex
        return BagViewData.tbNewItemIndex[szPos] ~= nil
    end
    return false
end

function BagViewData.IsConditionMatch(item, tFilterData)
    if not tFilterData or not tFilterData.szType then
        return
    end

    local szType = tFilterData.szType
    local tCondition = tFilterData.tCondition
    if szType == "KItem" or szType == "KItemInfo" then
        if szType == "KItemInfo" then
            item = GetItemInfo(item.dwTabType, item.dwIndex)
        end

        if tCondition and item then
            for _, tSubCondition in ipairs(tCondition) do
                local bMatchSubCondition = true
                for szKey, value in pairs(tSubCondition) do
                    local nItemValue = item[szKey]
                    if type(value) == "boolean" or type(value) == "number" then
                        if nItemValue ~= value then
                            bMatchSubCondition = false
                        end
                    elseif type(value) == "table" then
                        if not table.contain_value(value, nItemValue) then
                            bMatchSubCondition = false
                        end
                    end
                end
                if bMatchSubCondition then
                    return true
                end
            end
            return false -- 一个条件都没有满足 返回false
        end
    elseif szType == "TimeLimited" then
        local tItemInfo = GetItemInfo(item.dwTabType, item.dwIndex) --单独处理临期分类
        return ItemData.IsItemExpiring(tItemInfo, item)
    end
    return false
end

local IsInTable = table.contain_value
function BagViewData.IsMatchFilter(item, nFilterClass, nFilterSub, nFilterTag)
    if nFilterClass == 0 then
        return true -- nFilterClass为0时 代表全部分类
    end

    if not item or not nFilterClass or not ITEM_FILTER_SETTING[nFilterClass] then
        return false
    end

    local tFilterData = ITEM_FILTER_SETTING[nFilterClass]
    local tItemFilterTag = {}
    local nUiId = item.nUiId
    if nUiId then
        local tUiInfo = Table_GetItemInfo(nUiId)
        if tUiInfo then
            tItemFilterTag = StringParse_PointList(tUiInfo.szFilterTag)
        end
    end

    local nFilterClass = nFilterClass or 0
    local nFilterSub = nFilterSub or 0
    local nFilterTag = nFilterTag or Table_GetBigBagFilterTag(nFilterClass, nFilterSub)
    local bSameFilterTag = nFilterTag ~= 0 and IsInTable(tItemFilterTag, nFilterTag)
    if bSameFilterTag then
        return true
    end

    local szType = tFilterData.szType
    if not szType then
        if nFilterSub == 0 then
            --全部子类
            local tSubList = Table_GetBigBagSubFilter(nFilterClass)
            if #tSubList == 0 then
                return
            end

            local bSubFilter = false
            for _, tSub in ipairs(tSubList) do
                local nSubFilterTag = tSub.nFilterTag
                local bSameSubFilterTag = nSubFilterTag ~= 0 and IsInTable(tItemFilterTag, nSubFilterTag)

                local tSubFilterData = tFilterData.tChildTab[tSub.nSub]
                if bSameSubFilterTag or BagViewData.IsConditionMatch(item, tSubFilterData) then
                    bSubFilter = true
                    break
                end
            end
            return bSubFilter
        else
            tFilterData = tFilterData.tChildTab[nFilterSub]
        end
    end
    return BagViewData.IsConditionMatch(item, tFilterData)
end

function BagViewData.OnReload()
    BagViewData.Init()
end 

function BagViewData.GetLockBoxMap()
    return BagViewData.tbLockBoxMap
end

function BagViewData.GetHomelandLockData()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    local tbLockBoxMap = BagViewData.tbLockBoxMap or {}
    local tLockData
    for dwBox, tLockMap in pairs(tbLockBoxMap) do
        for dwX, bLock in pairs(tLockMap) do
            local item = pPlayer.GetItem(dwBox, dwX)
            if bLock and item and item.dwTabType == ITEM_TABLE_TYPE.OTHER then
                if Table_GetHomelandLockerInfoByItem(item.dwIndex) then
                    if not tLockData then
                        tLockData = {}
                    end
                    tLockData[dwBox] = tLockData[dwBox] or {}
                    tLockData[dwBox][dwX] = true
                end
            end
        end
    end
    return tLockData
end

function BagViewData.UpdateLockBoxData()
    if not g_pClientPlayer then return end
    local tbLockBoxMap = BagViewData.tbLockBoxMap
    if tbLockBoxMap then
        for nBox, tbList in pairs(tbLockBoxMap) do
            local nSize = g_pClientPlayer.GetBoxSize(nBox)
            for nIndex, bLock in pairs(tbList) do
                if bLock and nIndex >= nSize then
                    BagViewData.StorageUnLock(nBox, nIndex)
                end
            end
        end
    end
end

function BagViewData.StorageLock(nBox, nBoxIndex)
    if not BagViewData.tbLockBox then return false end
    if BagViewData.IsLockBox(nBox, nBoxIndex) then return false end
    local bSuccess = false
    for nIndex, tbLock in ipairs(BagViewData.tbLockBox) do
        if tbLock.nBox == 0 and tbLock.nBoxIndex == 0 then
            if not BagViewData.tbLockBoxMap[nBox] then BagViewData.tbLockBoxMap[nBox] = {} end
            BagViewData.tbLockBoxMap[nBox][nBoxIndex] = true
            BagViewData.tbLockBox[nIndex] = {nBox = nBox, nBoxIndex = nBoxIndex}
            Storage_Server.SetData("BagBoxLock", nIndex, nBox, nBoxIndex)
            bSuccess = true
            Event.Dispatch(EventType.OnBoxLockChanged)
            break
        end
    end
    return bSuccess
end

function BagViewData.StorageUnLock(nBox, nBoxIndex)
    if not BagViewData.tbLockBox then return false end
    if not BagViewData.IsLockBox(nBox, nBoxIndex) then return false end
    local bSuccess = false
    for nIndex, tbLock in ipairs(BagViewData.tbLockBox) do
        if tbLock.nBox == nBox and tbLock.nBoxIndex == nBoxIndex then
            BagViewData.tbLockBoxMap[nBox][nBoxIndex] = false
            BagViewData.tbLockBox[nIndex] = {nBox = 0, nBoxIndex = 0}
            Storage_Server.SetData("BagBoxLock", nIndex, 0, 0)
            bSuccess = true
            Event.Dispatch(EventType.OnBoxLockChanged)
            break
        end
    end
    return bSuccess
end

function BagViewData.IsLockBox(nBox, nIndex)
    return BagViewData.tbLockBoxMap and BagViewData.tbLockBoxMap[nBox] and BagViewData.tbLockBoxMap[nBox][nIndex]
end

function BagViewData.GetLockBoxNum()
    if not BagViewData.tbLockBox then return 0 end
    local nLen = 0
    for _, tbLock in ipairs(BagViewData.tbLockBox) do
        if not (tbLock.nBox == 0 and tbLock.nBoxIndex == 0) then
            nLen = nLen + 1
        end
    end
    return nLen
end

function BagViewData.LoadLockBoxData()
    BagViewData.tbLockBoxMap = {}
    BagViewData.tbLockBox = {}
    for nIndex = 1, MAX_BLOCK_BOX_COUNT do
        local nServeBox, nServeBoxIndex = Storage_Server.GetData("BagBoxLock", nIndex)
        local bExist = false
        local nBox, nBoxIndex = 0, 0
        if not (nServeBox == 0 and nServeBoxIndex == 0) then
            nBox, nBoxIndex = nServeBox, nServeBoxIndex
        end
        if not BagViewData.tbLockBoxMap[nBox] then BagViewData.tbLockBoxMap[nBox] = {} end
        BagViewData.tbLockBoxMap[nBox][nBoxIndex] = not (nBox == 0 and nBoxIndex == 0)
        table.insert(BagViewData.tbLockBox, {nBox = nBox, nBoxIndex = nBoxIndex})
    end
end