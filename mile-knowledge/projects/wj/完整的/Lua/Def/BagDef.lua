BagDef = {}

BagDef.CommonCatogory = {
    [1] = { bShowEmptyCell = true, szTitle = "背包", szName = "全部", filterFunc = function(item)
        return true
    end }, -- 全部
    [2] = { bShowEmptyCell = false, szTitle = "任务", szName = "任务", type = ITEM_GENRE.TASK_ITEM, filterFunc = function(item)
        return item.nGenre == ITEM_GENRE.TASK_ITEM
    end }, -- 任务
    [3] = { bShowEmptyCell = false, szTitle = "装备", szName = "装备", type = ITEM_GENRE.EQUIPMENT, filterFunc = function(item)
        return item.nGenre == ITEM_GENRE.EQUIPMENT
    end }, -- 装备
    [4] = { bShowEmptyCell = false, szTitle = "药品", szName = "药品", type = ITEM_GENRE.POTION, filterFunc = function(item)
        return item.nGenre == ITEM_GENRE.POTION or item.nGenre == ITEM_GENRE.FOOD
    end }, -- 药品
    [5] = { bShowEmptyCell = false, szTitle = "材料", szName = "材料", type = ITEM_GENRE.MATERIAL, filterFunc = function(item)
        return item.nGenre == ITEM_GENRE.MATERIAL
    end }, -- 材料
    [6] = { bShowEmptyCell = false, szTitle = "书籍", szName = "书籍", type = ITEM_GENRE.BOOK, filterFunc = function(item)
        return item.nGenre == ITEM_GENRE.BOOK
    end }, -- 书籍
    [7] = { bShowEmptyCell = false, szTitle = "家具", szName = "家具", type = ITEM_GENRE.HOMELAND, filterFunc = function(item)
        return item.nGenre == ITEM_GENRE.HOMELAND
    end }, -- 家具
    [8] = { bShowEmptyCell = false, szTitle = "其他", szName = "其他", type = ITEM_GENRE.HOMELAND, filterFunc = function(item)
        return not (item.nGenre == ITEM_GENRE.TASK_ITEM or item.nGenre == ITEM_GENRE.EQUIPMENT or item.nGenre == ITEM_GENRE.POTION or item.nGenre == ITEM_GENRE.FOOD
                or item.nGenre == ITEM_GENRE.MATERIAL or item.nGenre == ITEM_GENRE.BOOK or item.nGenre == ITEM_GENRE.HOMELAND)
    end }, -- 其他
}

BagDef.CommonFilter = {
    {
        function(_) return true end,
        function(item) return item.bCanShared end, --账号共享
        function(item) return not item.bBind end, --非绑定
        function(item) return ItemData.GetItemInfo(item.dwTabType, item.dwIndex).nExistType ~= ITEM_EXIST_TYPE.PERMANENT end, --限时
    },
    {
        function(_) return true end,
        function(item) return item.nGenre == ITEM_GENRE.EQUIPMENT and (item.nSub >= EQUIPMENT_SUB.MELEE_WEAPON and item.nSub <= EQUIPMENT_SUB.BANGLE) and item.nEquipUsage == 0 or item.nEquipUsage == 3 end, --PVP
        function(item) return item.nGenre == ITEM_GENRE.EQUIPMENT and (item.nSub >= EQUIPMENT_SUB.MELEE_WEAPON and item.nSub <= EQUIPMENT_SUB.BANGLE) and item.nEquipUsage == 1 or item.nEquipUsage == 3 end, --PVE
        function(item) return item.nGenre == ITEM_GENRE.EQUIPMENT and (item.nSub >= EQUIPMENT_SUB.MELEE_WEAPON and item.nSub <= EQUIPMENT_SUB.BANGLE) and item.nEquipUsage == 2 or item.nEquipUsage == 3 end, --PVX
    },
}