-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: TravellingBagData
-- Date: 2023-04-17 17:12:15
-- Desc: ?
-- ---------------------------------------------------------------------------------

TravellingBagData = TravellingBagData or {className = "TravellingBagData"}
local self = TravellingBagData
-------------------------------- 消息定义 --------------------------------
TravellingBagData.Event = {}
TravellingBagData.Event.XXX = "TravellingBagData.Msg.XXX"

function TravellingBagData.Init()
    TravellingBagData.RegEvent()
end

function TravellingBagData.UnInit()

end

function TravellingBagData.OnLogin()

end

function TravellingBagData.OnFirstLoadEnd()

end


--是否在浪客行地图
function TravellingBagData.IsInTravelingMap()
    local hPlayer = g_pClientPlayer
    if hPlayer then
        local hScene = hPlayer.GetScene()
        local dwMapID = hScene and hScene.dwMapID
        if table.contain_value(LKX_MAP_IDS, dwMapID) then
            return true
        end
    end
    return false
end

function TravellingBagData.GetTravellingBagItems()
    local tbItemList = ItemData.GetItemList(ItemData.BoxSet.TravellingBag)
    return tbItemList
end

function TravellingBagData.GetAllItemStackNum()
    local pPlayer = g_pClientPlayer
	local tList = {}
	if pPlayer then
        local dwSize = pPlayer.GetBoxSize(INVENTORY_INDEX.LIMITED_PACKAGE)
        for dwX = 0, dwSize - 1, 1 do
            local pItem = pPlayer.GetItem(INVENTORY_INDEX.LIMITED_PACKAGE, dwX)
            if pItem then
                tList[pItem.dwTabType] = tList[pItem.dwTabType] or {}
                local tTypeSub = tList[pItem.dwTabType]
                tTypeSub[pItem.dwIndex] = tTypeSub[pItem.dwIndex] or 0
                tTypeSub[pItem.dwIndex] = tTypeSub[pItem.dwIndex] + pItem.nStackNum
            end
        end
	end
	return tList
end

local function _getXunbaoPriority(item)
    -- 优先级规则：
    -- 1. 剩余全部类型道具（包括nAucGenre≠26和nAucGenre=26的其他类型）
    -- 2. nAucGenre=26且为MEDICINE
    -- 3. nAucGenre=26且为INVISIBILITY
    -- 4. 相同类别内按品质 > 堆叠数

    local priority = 0
    -- 计算类别优先级（1=最高，3=最低）
    if item.nAucGenre ~= AUC_GENRE.DESERT then
        priority = 1  -- 剩余全部类型道具
    elseif ExtractWareHouseData.GetItemSubType(item.nAucSub) == ExtractItemSub.MEDICINE then
        priority = 2  -- MEDICINE
    elseif ExtractWareHouseData.GetItemSubType(item.nAucSub) == ExtractItemSub.INVISIBILITY then
        priority = 3  -- INVISIBILITY
    else
        priority = 1  -- nAucGenre=26的其他道具也归为剩余全部类型
    end

    -- 将类别优先级作为高4位
    local sortKey = priority * 100000000
    -- 品质（99-94，高品质优先）
    sortKey = sortKey + (99 - item.nQuality) * 1000000
    -- 堆叠数
    sortKey = sortKey + (9999 - item.nStackNum) * 100
    return sortKey
end

function TravellingBagData.BeginSort()
    if TravellingBagData.tbSorting then
        LOG.ERROR("already sorting!")
        return
    end

    local player = GetClientPlayer()
    if not player then return end

	local aGenre =
	{
		[ITEM_GENRE.TASK_ITEM] = 1,  --ITEM_GENRE.TASK_ITEM
		[ITEM_GENRE.EQUIPMENT] = 2,  --ITEM_GENRE.EQUIPMENT
		[ITEM_GENRE.BOOK] = 3,       --ITEM_GENRE.BOOK
		[ITEM_GENRE.POTION] = 4,     --ITEM_GENRE.POTION
		[ITEM_GENRE.MATERIAL] = 5    --ITEM_GENRE.MATERIAL
	}

    local aSub =
	{
		[EQUIPMENT_SUB.HORSE] = 1,         --
		[EQUIPMENT_SUB.PACKAGE] = 2,       --
		[EQUIPMENT_SUB.MELEE_WEAPON] = 3,  --
		[EQUIPMENT_SUB.RANGE_WEAPON] = 4,  --
	}

    local tbItemList = {}
    local tbNormalSlotList = {}

    local tbResult = {}
    local tbItemInfoList = ItemData.GetItemList(ItemData.BoxSet.TravellingBag)

    local tbContainBox = {}
    local tbBoxTypeKey = {}
    local bIsInXunbao = BattleFieldData.IsInXunBaoBattleFieldMap()
    for _, dwBox in ipairs(ItemData.BoxSet.TravellingBag) do
        local nCtGenre, nCtSub = player.GetContainType(dwBox)
        if nCtGenre ~= -1 then
            local szTypeKey = string.format("%d_%d", nCtGenre, nCtSub)
            tbContainBox[szTypeKey] = tbContainBox[szTypeKey] or {}
            tbBoxTypeKey[dwBox] = szTypeKey
            --print("dwBox:", dwBox, nCtGenre, nCtSub, szTypeKey)
        end
    end

    for _, tbItemInfo in ipairs(tbItemInfoList) do
        if tbItemInfo.hItem then
            table.insert(tbItemList, tbItemInfo)
        end

        if tbBoxTypeKey[tbItemInfo.nBox] then
            table.insert(tbContainBox[tbBoxTypeKey[tbItemInfo.nBox]], { dwBox = tbItemInfo.nBox, dwIndex = tbItemInfo.nIndex })
        else
            table.insert(tbNormalSlotList, { dwBox = tbItemInfo.nBox, dwIndex = tbItemInfo.nIndex })
        end
    end

    table.sort(tbItemList, function (x, y)
        local xItem, yItem = x.hItem, y.hItem
        if bIsInXunbao then
            local xPriority = _getXunbaoPriority(xItem)
            local yPriority = _getXunbaoPriority(yItem)
            if xPriority ~= yPriority then
                return xPriority < yPriority
            else
                return x.nIndex < y.nIndex
            end
        end

        local xG, yG = aGenre[xItem.nGenre] or (100 + xItem.nGenre), aGenre[yItem.nGenre] or (100 + yItem.nGenre)
        if xG ~= yG then
            return xG < yG
        end

        local xS, yS = aSub[xItem.nSub] or (100 + xItem.nSub), aSub[yItem.nSub] or (100 + yItem.nSub)
        if xS ~= yS then
            return xS < yS
        end

        if xItem.nDetail ~= yItem.nDetail then
            return xItem.nDetail < yItem.nDetail
        end

        if xItem.nCurrentDurability ~= yItem.nCurrentDurability then
            return xItem.nCurrentDurability > yItem.nCurrentDurability
        end

        if xItem.nQuality ~= yItem.nQuality then
            return xItem.nQuality > yItem.nQuality
        end

        if xItem.dwTabType ~= yItem.dwTabType then
            return xItem.dwTabType < yItem.dwTabType
        end

        if xItem.dwIndex ~= yItem.dwIndex then
            return xItem.dwIndex < yItem.dwIndex
        end

        if xItem.nGenre == ITEM_GENRE.BOOK then
            return xItem.nBookID < yItem.nBookID
        else
            return xItem.nStackNum > yItem.nStackNum
        end
    end)

    --for _, itemInfo in ipairs(tbItemList) do
        --local item = itemInfo.hItem
        --print(item.nQuality, item.szName, "nGenre:", item.nGenre, item.nSub, item.nStackNum, item.nBookID)
    --end
    --print("+++++++++++++++++++++++++++++++++++++++++++++++")
    for _, itemInfo in ipairs(tbItemList) do
        local item = itemInfo.hItem
        local szTypeKey = string.format("%d_%d", item.nGenre, item.nSub)
        local szTypeKey2 = string.format("%d_%d", item.nGenre, -1)
        --print(szTypeKey, szTypeKey2)
        if tbContainBox[szTypeKey] and #tbContainBox[szTypeKey] > 0 then
            local tbTargetSlot = tbContainBox[szTypeKey][1]
            table.insert(tbResult, { dwItemID = item.dwID, szName = item.szName, dwBox = tbTargetSlot.dwBox, dwIndex = tbTargetSlot.dwIndex, bSpecialContainBox = true })
            table.remove(tbContainBox[szTypeKey], 1)

            --print(item.szName, tbTargetSlot.dwBox, tbTargetSlot.dwIndex, true, szTypeKey)
        elseif tbContainBox[szTypeKey2] and #tbContainBox[szTypeKey2] > 0 then
            local tbTargetSlot = tbContainBox[szTypeKey2][1]
            table.insert(tbResult, { dwItemID = item.dwID, szName = item.szName, dwBox = tbTargetSlot.dwBox, dwIndex = tbTargetSlot.dwIndex, bSpecialContainBox = true })
            table.remove(tbContainBox[szTypeKey2], 1)

            --print(item.szName, tbTargetSlot.dwBox, tbTargetSlot.dwIndex, true, szTypeKey2)
        elseif #tbNormalSlotList > 0 then
            local tbTargetSlot = tbNormalSlotList[1]
            table.insert(tbResult, { dwItemID = item.dwID, szName = item.szName, dwBox = tbTargetSlot.dwBox, dwIndex = tbTargetSlot.dwIndex, bSpecialContainBox = false })
            table.remove(tbNormalSlotList, 1)

            --print(item.szName, tbTargetSlot.dwBox, tbTargetSlot.dwIndex, false)
        else
            LOG.ERROR("bag sort: slot not enough!")
            return
        end
    end
    --print("----------------------------------------------------")
    --for _, tbItemOrder in ipairs(tbResult) do
        --print(tbItemOrder.szName, tbItemOrder.dwItemID, tbItemOrder.dwBox, tbItemOrder.dwIndex)
    --end

    --print("+++++++++++++++++++++++++++++++++++++++++++++++")
    table.sort(tbResult, function(x, y)
        return x.bSpecialContainBox and not y.bSpecialContainBox
    end)

    --for _, tbItemOrder in ipairs(tbResult) do
        --print(tbItemOrder.szName, tbItemOrder.dwItemID, tbItemOrder.dwBox, tbItemOrder.dwIndex)
    --end

    TravellingBagData.tbSorting =  tbResult
    Event.Reg(TravellingBagData, "EXCHANGE_ITEM", function ()
        TravellingBagData.DoSortStep()
    end)
    TravellingBagData.DoSortStep()
end

function TravellingBagData.DoSortStep()
    if #TravellingBagData.tbSorting > 0 then
        --print("#TravellingBagData.tbSorting", #TravellingBagData.tbSorting)
        local tbTravellingBagDataInfo = TravellingBagData.tbSorting[1]
        table.remove(TravellingBagData.tbSorting, 1)

        local dwBox, dwIndex = ItemData.GetItemPos(tbTravellingBagDataInfo.dwItemID)
        if dwBox and dwBox ~= tbTravellingBagDataInfo.dwBox or dwIndex ~= tbTravellingBagDataInfo.dwIndex then
            --print("EXCHANGE", tbTravellingBagDataInfo.dwItemID, dwBox, dwIndex, tbTravellingBagDataInfo.dwBox, tbTravellingBagDataInfo.dwIndex)
            local bExchangeRet = ItemData.ExchangeItem(dwBox, dwIndex, tbTravellingBagDataInfo.dwBox, tbTravellingBagDataInfo.dwIndex)
            if not bExchangeRet then
                TravellingBagData.DoSortStep()
            end
        else
            --print("EXCHANGE SKIPPED", tbTravellingBagDataInfo.dwItemID, dwBox, dwIndex)
            TravellingBagData.DoSortStep()
        end
    else
        TravellingBagData.EndSort()
    end
end

function TravellingBagData.EndSort()
    TravellingBagData.tbSorting = nil
    Event.UnReg(TravellingBagData, "EXCHANGE_ITEM")
    --print("bag sort end")
end

--提笔注疏技能更新
function TravellingBagData.OnTBSKillUpdate(nSKillID, nSkillLevel)
    if not self.tbTBSkillInfo or self.tbTBSkillInfo.id ~= nSKillID then
        self.tbTBSkillInfo = {id = nSKillID, level = nSkillLevel}
        Event.Dispatch(EventType.UpdateTreasureBattleFieldActionBar)
    end
end

function TravellingBagData.GetTBSKill()
    if TravellingBagData.IsInTravelingMap() then
        return self.tbTBSkillInfo
    end
    return nil
end

function TravellingBagData.RegEvent()
    Event.Reg(TravellingBagData, "LOADING_END", function()
        if TravellingBagData.IsInTravelingMap() then
            RemoteCallToServer("On_LangKeXing_GetSQSkillID")
        end
    end)
    Event.Reg(TravellingBagData, EventType.OnClientPlayerLeave, function()
        self.tbTBSkillInfo = nil
    end)
end

function TravellingBagData.UnRegEvent()
    -- Event.UnReg(TravellingBagData, "EXCHANGE_ITEM")
end


function TravellingBagData.OpenBag()
    local nViewID = TravellingBagData.IsInTravelingMap() and VIEW_ID.PanelTravellingBag or VIEW_ID.PanelHalfBag
    UIMgr.Open(nViewID)
end

function TravellingBagData.On_LangKeXing_UiAskIn()
    RemoteCallToServer("On_LangKeXing_UiAskIn")
end

function TravellingBagData.CheckIsFull()
    local bFull = true
    local pPlayer = g_pClientPlayer
	if pPlayer then
        local dwSize = pPlayer.GetBoxSize(INVENTORY_INDEX.LIMITED_PACKAGE)
        for dwX = 0, dwSize - 1, 1 do
            local pItem = pPlayer.GetItem(INVENTORY_INDEX.LIMITED_PACKAGE, dwX)
            if not pItem then
                bFull = false
                break
            end
        end
	end
    return bFull
end

function TravellingBagData.QuickEquipAll()
    local player = g_pClientPlayer
    if not player then return end
    local tbEquipList = {}

    -- 取当前装备，方便对比
    local tbEquipItem = {}
    for _, tbEquip in ipairs(ItemData.GetItemList(ItemData.BoxSet.BagSlot)) do
        tbEquipItem[tbEquip.nIndex] = tbEquip
    end

    local tbItemInfoList = ItemData.GetItemList(ItemData.BoxSet.TravellingBag)
    for _, tbInfo in ipairs(tbItemInfoList) do
        local hItem = tbInfo.hItem
        if hItem and hItem.nGenre == ITEM_GENRE.EQUIPMENT then
            local _, nDestIndex = ItemData.GetEquipItemEquiped(player, hItem.nSub, hItem.nDetail)
            local _, nIndex = table.find_if(tbEquipItem, function(v)
                local hCurEquip = v.hItem
                if hCurEquip then
                    return v.nIndex == nDestIndex and hCurEquip.nQuality < hItem.nQuality
                else
                    return v.nIndex == nDestIndex
                end
            end)

            if nIndex then
                tbEquipItem[nIndex] = tbInfo
            end
        end
    end

    for _, tbInfo in pairs(tbEquipItem) do
        if tbInfo and tbInfo.hItem and table.contain_value(ItemData.BoxSet.TravellingBag, tbInfo.nBox) then
            table.insert(tbEquipList, {dwBox = tbInfo.nBox, dwX = tbInfo.nIndex})
        end
    end
    ItemData.EquipAllItem(tbEquipList)
end