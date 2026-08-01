JX_LootPlus = {className = "JX_LootPlus"}
local _JX_LootPlus = {}

JX_LootPlus.bLootPlus = true
JX_LootPlus.bAutoLoot = false
JX_LootPlus.bLootInfo = true
JX_LootPlus.bFilterGreen = true
JX_LootPlus.bFilterBlue = false
JX_LootPlus.tOtherList = {}
local tOtherItemID = {
    --效果类
	[29037] = {stack = 12, class = 1}, --麻布绷带
    [29036] = {stack = 8 , class = 1}, --金疮药
	[29407] = {stack = 8 , class = 1}, --行气散
    [29873] = {stack = 8 , class = 1}, --回蓝道具
	[32057] = {stack = 5 , class = 1}, --[觅踪窥影烟]
	[32265] = {stack = 4 , class = 1}, --[月影沙]
	[41178] = {stack = 10, class = 1}, --[燧石]
	[41179] = {stack = 5 , class = 1}, --[火把]
	[41045] = {stack = 10, class = 1}, --[风筝]
	[41791] = {stack = 10, class = 1}, --[天原玄冰]驱散
	[37391] = {stack = 4 , class = 1}, --[狩猎装束]增加移速
	--[32658] = {stack = 12, class = 1}, --麻布绷带
	[32641] = {stack = 4 , class = 1}, --[凌波草]水上行走
    --特殊道具
    [32675] = {stack = 20, class = 2}, --沐霖果·喂养
    [29414] = {stack = 20, class = 2}, --鬼黄藤·喂养
    [29881] = {stack = 1 , class = 2}, --黑莲花
    [32636] = {stack = 1 , class = 2}, --[九转还魂草]
    --伪装类
	[29155] = {stack = 4 , class = 3}, --砂石
	[29156] = {stack = 4 , class = 3}, --灌木
	[29157] = {stack = 4 , class = 3}, --瓦罐
	[32647] = {stack = 4 , class = 3}, --沧溟石
	[32649] = {stack = 4 , class = 3}, --珊瑚
	[32648] = {stack = 4 , class = 3}, --水缸
	[32654] = {stack = 4 , class = 3}, --宽叶草
	[37388] = {stack = 4 , class = 3}, --[木桶伪装]
	[37389] = {stack = 4 , class = 3}, --[山石伪装]
	[37390] = {stack = 4 , class = 3}, --[灌木伪装]
	[41559] = {stack = 4 , class = 3}, --[人参]
	[41560] = {stack = 4 , class = 3}, --[木箱]
	[41561] = {stack = 4 , class = 3}, --[雪堆]
    --装备类，不让玩家设置了
	-- [29101] = {stack = 1 , class = 5}, --一阶武器（盒子）
	-- [29102] = {stack = 1 , class = 5}, --二阶武器（盒子）
	-- [29103] = {stack = 1 , class = 5}, --三阶武器（盒子）
	-- [29542] = {stack = 1 , class = 5}, --四阶武器（盒子）
    --坐骑类
    [29941] = {stack = 1 , class = 4}, --驼铃
}
local tDesertHorse = {
    [22496] = {stack = 1 , class = 4},
    [22497] = {stack = 1 , class = 4},
    [22622] = {stack = 1 , class = 4}, --骆驼
    [22623] = {stack = 1 , class = 4}, --飞艇
	[24885] = {stack = 1 , class = 4},
	[24886] = {stack = 1 , class = 4},
	[24887] = {stack = 1 , class = 4}, --陆行鸟
	[24888] = {stack = 1 , class = 4}, --乌龟
}
local tTwins = {
    [32658] = 29037,--绷带有两种，转成同一个
}
for k, _ in pairs(tOtherItemID) do
    JX_LootPlus.tOtherList[k] = - 1
end
for k, _ in pairs(tDesertHorse) do
    JX_LootPlus.tOtherList[k] = - 1
end

local EQUIPMENT_SUB, EQUIPMENT_INVENTORY, INVENTORY_INDEX = EQUIPMENT_SUB, EQUIPMENT_INVENTORY, INVENTORY_INDEX
-- local tItemClass = {
--     [1] = _L['effectclass'] , -- '效果类',
--     [2] = _L['specialclass'] , -- '特殊道具',
--     [3] = _L['simulateclass'] , -- '伪装类',
--     [4] = _L['houseclass'] , -- '坐骑类',
--     --[5] = _L['equipclass'] , -- '装备类',
-- }
-- local tQuality = { -- 暂时无用
--     [1] = {name = _L['white equip'],  rgb = {255, 255, 255}, filter = true},
--     [2] = {name = _L['green equip'],  rgb = {50, 205, 50},   filter = true},
--     [3] = {name = _L['blue equip'],   rgb = {30, 144, 255},  filter = true},
--     [4] = {name = _L['purple equip'], rgb = {255, 0, 255},   filter = true},
--     [5] = {name = _L['gloden equip'], rgb = {255, 215, 0},   filter = true},
--     [6] = {name = _L['other equip'],  rgb = {128, 128, 128}, filter = true},
-- }
-- local tChickenQuality = {
--     [2] = {name = _L['filter green equip'], rgb = {50, 205, 50},  filter = true},
--     [3] = {name = _L['filter blue equip'],  rgb = {30, 144, 255}, filter = false},
-- }
local _tChickenQuality = {}

local tWeaponBox = {}

local tSub2Pos = {
    [EQUIPMENT_SUB.MELEE_WEAPON] = {EQUIPMENT_INVENTORY.MELEE_WEAPON, EQUIPMENT_INVENTORY.BIG_SWORD}, -- "近身武器"
    [EQUIPMENT_SUB.RANGE_WEAPON] = EQUIPMENT_INVENTORY.RANGE_WEAPON,                                  -- "远程武器"
    [EQUIPMENT_SUB.CHEST] = EQUIPMENT_INVENTORY.CHEST,                                                -- "上衣"
    [EQUIPMENT_SUB.HELM] = EQUIPMENT_INVENTORY.HELM,                                                  -- "帽子"
    [EQUIPMENT_SUB.AMULET] = EQUIPMENT_INVENTORY.AMULET,                                              -- "项链"
    [EQUIPMENT_SUB.RING] = {EQUIPMENT_INVENTORY.LEFT_RING, EQUIPMENT_INVENTORY.RIGHT_RING},           -- "戒指"
    [EQUIPMENT_SUB.WAIST] = EQUIPMENT_INVENTORY.WAIST,                                                -- "腰带"
    [EQUIPMENT_SUB.PENDANT] = EQUIPMENT_INVENTORY.PENDANT,                                            -- "腰坠"
    [EQUIPMENT_SUB.PANTS] = EQUIPMENT_INVENTORY.PANTS,                                                -- "下装"
    [EQUIPMENT_SUB.BOOTS] = EQUIPMENT_INVENTORY.BOOTS,                                                -- "鞋子"
    [EQUIPMENT_SUB.BANGLE] = EQUIPMENT_INVENTORY.BANGLE,                                              -- "护腕"
}

-- 获取装备的需求门派
local GetRequireAttrib = function(_item)
    if not _item then
        return
    end
    local tRequireAttrib = _item.GetRequireAttrib()
    for _, v in pairs(tRequireAttrib) do
        if v and v.nID == 6 then -- 需求门派
            return v.nValue1
        end
    end
end
-- 获取装备的分数
local GetItemScore = function(_item)
    local newScore = 0
    if _item.dwTabType == 5 and tWeaponBox[_item.dwIndex] then
        newScore = tWeaponBox[_item.dwIndex].nBaseScore -- 装备分数
    else
        newScore = _item.nBaseScore
    end
    return newScore
end

-- 判断该装备是不是拾取列表+背包里同部位最好的
function _JX_LootPlus.IsBestItem(player, item, tItemIDList)
    if tItemIDList then
        for _, dwID in ipairs(tItemIDList) do
            local _item = GetItem(dwID)
            local nRequireForce = GetRequireAttrib(_item)
            if _item and _item.nSub == item.nSub and _item.dwID ~= item.dwID then
                if not nRequireForce or nRequireForce and nRequireForce == player.dwForceID then
                    if _item.nBaseScore > item.nBaseScore then
                        return false
                    end
                end
            end
        end
    end

    if item.dwTabType ~= 5 then -- 武器盒子不检查
        for i = 0, 31 do
            local _item = player.GetItem(INVENTORY_INDEX.LIMITED_PACKAGE, i)
            if _item and _item.nSub == item.nSub and _item.nBaseScore >= item.nBaseScore
                and (_item.nSub ~= EQUIPMENT_SUB.MELEE_WEAPON or _item.nSub == EQUIPMENT_SUB.MELEE_WEAPON and _item.nDetail == item.nDetail)
            then
                return false
            end
        end
    end
    return true
end

function JX_LootPlus.ShouldLoot(player, item, tItemIDList)
    if not item then
        return false
    end

    if BattleFieldData.IsInXunBaoBattleFieldMap() then
        -- 吃鸡的寻宝模式只看品质
        if _tChickenQuality[item.nQuality] and _tChickenQuality[item.nQuality].filter then
            return false
        end
        return true
    end

    -- 普通道具，只检查是否达到玩家设置的拾取上限
    if item.dwTabType == 5 and not tWeaponBox[item.dwIndex] then
        local dwIndex = tTwins[item.dwIndex] or item.dwIndex
        if tOtherItemID[dwIndex] then
            if not JX_LootPlus.tOtherList[dwIndex] or JX_LootPlus.tOtherList[dwIndex] == -1 then
                return true
            elseif JX_LootPlus.tOtherList[dwIndex] == 0 then
                return false
            elseif JX_LootPlus.tOtherList[dwIndex] == 1 then
                if player.GetItemAmount(5, item.dwIndex) >= tOtherItemID[dwIndex].stack then
                    return false
                else
                    return true
                end
            end
        end
        return true
    end
    -- 坐骑，只检查是否达到玩家设置的拾取上限
    if item.dwTabType == 8 and tDesertHorse[item.dwIndex] then
        local dwIndex = item.dwIndex
        if not JX_LootPlus.tOtherList[dwIndex] or JX_LootPlus.tOtherList[dwIndex] == -1 then
            return true
        elseif JX_LootPlus.tOtherList[dwIndex] == 0 then
            return false
        elseif JX_LootPlus.tOtherList[dwIndex] == 1 then
            if player.GetItemAmount(8, dwIndex) >= tDesertHorse[dwIndex].stack then
                return false
            else
                for i = 0, 9 do
                    local _horse = player.GetItem(INVENTORY_INDEX.HORSE, i)
                    if _horse and _horse.dwIndex == dwIndex then
                        return false
                    end
                end
                return true
            end
        end
        return true
    end
    -- 装备类
    local itemOld
    local bPromote = false
    if item.dwTabType == 5 then -- 武器盒子
        itemOld = player.GetItem(INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.MELEE_WEAPON)
    elseif item.nSub == EQUIPMENT_SUB.MELEE_WEAPON then -- 该门派的武器
        local nRequireForce = GetRequireAttrib(item)
        if nRequireForce and nRequireForce == player.dwForceID then
            if item.nDetail == 9 then -- 重剑
                itemOld = player.GetItem(INVENTORY_INDEX.EQUIP, tSub2Pos[item.nSub][2])
            else
                itemOld = player.GetItem(INVENTORY_INDEX.EQUIP, tSub2Pos[item.nSub][1])
            end
        end
    elseif item.nSub == EQUIPMENT_SUB.RING then -- 戒指，俩部位取最低品
        local itemOld1 = player.GetItem(INVENTORY_INDEX.EQUIP, tSub2Pos[item.nSub][1])
        local itemOld2 = player.GetItem(INVENTORY_INDEX.EQUIP, tSub2Pos[item.nSub][2])
        if itemOld1 and itemOld2 then
            itemOld = itemOld1.nBaseScore < itemOld2.nBaseScore and itemOld1 or itemOld2
        else
            itemOld = nil
        end
    else
        itemOld = player.GetItem(INVENTORY_INDEX.EQUIP, tSub2Pos[item.nSub])
    end
    if not itemOld or itemOld.nBaseScore < GetItemScore(item) then
        bPromote = true
    end
    --已经是拾取列表最好装备且比已穿戴的好，则直接返回；戒指可能需要俩，所以不做判断
    if bPromote and (item.nSub == EQUIPMENT_SUB.RING or _JX_LootPlus.IsBestItem(player, item, tItemIDList)) then
        if item.dwTabType == 5 then -- 武器盒子加个提示
            -- OutputWarningMessage("MSG_WARNING_YELLOW", _L('you get better weapon(%s)', item.szName))
        end
        return true
    end

    --最后才做装备的品质过滤，走到这里说明玩家身上已经有更好装备了，只检查品质是否过滤
    if _tChickenQuality[item.nQuality] and _tChickenQuality[item.nQuality].filter then
        return false
    end
    return true
end

function JX_LootPlus.SetChickenQuality(nLootColor)
    _tChickenQuality = {}
    for i = 1, nLootColor-1 do
        _tChickenQuality[i] = {filter = true}
    end
end

Event.Reg(JX_LootPlus, "FIRST_LOADING_END", function()
    tWeaponBox = {
        [29101] = {nSub = EQUIPMENT_SUB.MELEE_WEAPON, nBaseScore = GetItemInfo(6, 17223).nBaseScore}, -- 拿和尚的武器来算分数，免得数值组又瞎改装分
        [29102] = {nSub = EQUIPMENT_SUB.MELEE_WEAPON, nBaseScore = GetItemInfo(6, 17238).nBaseScore},
        [29103] = {nSub = EQUIPMENT_SUB.MELEE_WEAPON, nBaseScore = GetItemInfo(6, 17255).nBaseScore},
        [29542] = {nSub = EQUIPMENT_SUB.MELEE_WEAPON, nBaseScore = GetItemInfo(6, 17411).nBaseScore},
    }
end)