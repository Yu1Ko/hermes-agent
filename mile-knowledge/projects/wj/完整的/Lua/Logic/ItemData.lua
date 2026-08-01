local MAP_LIMIT_COUNT = 3
local nBanUseRemoteCD = 100
local nBanUseTick = 0

ItemData = ItemData or { className = "ItemData" }

ItemData.BoxSet = {
    Bag = { INVENTORY_INDEX.PACKAGE, INVENTORY_INDEX.PACKAGE1, INVENTORY_INDEX.PACKAGE2, INVENTORY_INDEX.PACKAGE3, INVENTORY_INDEX.PACKAGE4, INVENTORY_INDEX.PACKAGE_MIBAO },
    BagExceptMiBao = { INVENTORY_INDEX.PACKAGE, INVENTORY_INDEX.PACKAGE1, INVENTORY_INDEX.PACKAGE2, INVENTORY_INDEX.PACKAGE3, INVENTORY_INDEX.PACKAGE4 },
    BagSlot = { INVENTORY_INDEX.EQUIP },
    EquipableBag = { INVENTORY_INDEX.PACKAGE1, INVENTORY_INDEX.PACKAGE2, INVENTORY_INDEX.PACKAGE3, INVENTORY_INDEX.PACKAGE4, INVENTORY_INDEX.PACKAGE_MIBAO },
    Equip = { INVENTORY_INDEX.EQUIP },
    Bank = { INVENTORY_INDEX.BANK, INVENTORY_INDEX.BANK_PACKAGE1, INVENTORY_INDEX.BANK_PACKAGE2, INVENTORY_INDEX.BANK_PACKAGE3, INVENTORY_INDEX.BANK_PACKAGE4, INVENTORY_INDEX.BANK_PACKAGE5 },
    TravellingBag = { INVENTORY_INDEX.LIMITED_PACKAGE }--浪客行行囊
}

ItemData.OrderedBox = {
    INVENTORY_INDEX.EQUIP,
    INVENTORY_INDEX.PACKAGE, INVENTORY_INDEX.PACKAGE1, INVENTORY_INDEX.PACKAGE2, INVENTORY_INDEX.PACKAGE3, INVENTORY_INDEX.PACKAGE4,
    INVENTORY_INDEX.PACKAGE_MIBAO,
    INVENTORY_INDEX.LIMITED_PACKAGE,
    INVENTORY_INDEX.BANK, INVENTORY_INDEX.BANK_PACKAGE1, INVENTORY_INDEX.BANK_PACKAGE2, INVENTORY_INDEX.BANK_PACKAGE3, INVENTORY_INDEX.BANK_PACKAGE4, INVENTORY_INDEX.BANK_PACKAGE5
}

ItemData.SlotSet = {
    BagSlot = { EQUIPMENT_INVENTORY.PACKAGE1, EQUIPMENT_INVENTORY.PACKAGE2, EQUIPMENT_INVENTORY.PACKAGE3, EQUIPMENT_INVENTORY.PACKAGE4, EQUIPMENT_INVENTORY.PACKAGE_MIBAO }
}

local lc_tAdvanceBox = {
    [1] = { true, true, true, true },
    [2] = { true, true, true, true },
    [3] = { true, true, true, true },
    [4] = { true, true, true, true },
    [5] = { true, true, true, true },
}

local function IsImmediacyOpenBox(dwBoxTemplateID)
    if (not lc_tAdvanceBox[dwBoxTemplateID]) then
        return true;
    end
    return false
end

function ItemData.Init()
    ItemData.GetAllBookInfo()

    Event.Reg(ItemData, EventType.OnRoleLogin, function()
        ItemData.OpenQuestItem = nil
    end)

    Event.Reg(ItemData, "LOADING_END", function()
        local nPlayerID = PlayerData.GetPlayerID()
        if not IsRemotePlayer(nPlayerID) and not ItemData.GetQiXiInscriptionInfo(nPlayerID) then
            RemoteCallToServer("OnInscriptionRequest", nPlayerID)
        end
    end)

    Event.Reg(ItemData, EventType.OnItemTipSwitchRing, function(nBox, nIndex)
        ItemData.nExchangeRingIndex = nIndex or nil
    end)

    Event.Reg(ItemData, EventType.OnRichTextOpenUrl, function(szUrl, node)
        szUrl = UrlDecode(szUrl)

        if szUrl then
            local tbLinkData = JsonDecode(szUrl)
            if not tbLinkData or not tbLinkData.type == "iteminfolink" then return end
            local nTabType = tonumber(tbLinkData.nTabtype)
            local nIndex = tonumber(tbLinkData.nIndex)

            if nTabType and nIndex then
                local _, script = TipsHelper.ShowItemTips(node, nTabType, nIndex, false, TipsLayoutDir.AUTO)
                Event.Dispatch(EventType.OnShowIteminfoLinkTips, script)
            end
        end
    end)
end

function ItemData.UnInit()
    if ItemData.ItemPrefabPool then ItemData.ItemPrefabPool:Dispose() end
    if ItemData.BagCellPrefabPool then ItemData.BagCellPrefabPool:Dispose() end
    ItemData.ItemPrefabPool = nil
    ItemData.BagCellPrefabPool = nil
end

function ItemData.GetBagSize(tbBoxSet)
    local player = PlayerData.GetClientPlayer()
    if not player then
        return 0
    end

    local nBagSize = 0
    for _, nBox in ipairs(tbBoxSet) do
        nBagSize = nBagSize + player.GetBoxSize(nBox)
    end
    return nBagSize
end

function ItemData.GetBoxSize(nBox)
    if not g_pClientPlayer then
        return 0
    end

    return g_pClientPlayer.GetBoxSize(nBox)
end

function ItemData.GetBagUsedSize(tbBoxSet)
    local player = PlayerData.GetClientPlayer()
    if not player then
        return 0
    end

    local nBagUsedSize = 0
    for _, nBox in ipairs(tbBoxSet) do
        local nBoxSize = player.GetBoxSize(nBox)
        if nBoxSize and nBoxSize ~= 0 then
            nBagUsedSize = nBagUsedSize + nBoxSize - player.GetBoxFreeRoomSize(nBox)
        end
    end
    return nBagUsedSize
end

function ItemData.GetItemList(tbBoxSet)
    local tbItemList = {}
    local player = PlayerData.GetClientPlayer()
    if not player then
        return tbItemList
    end

    for _, nBox in ipairs(tbBoxSet) do
        for index = 0, player.GetBoxSize(nBox) - 1 do
            local hItem = player.GetItem(nBox, index)
            table.insert(tbItemList, { nBox = nBox, nIndex = index, hItem = hItem })
        end
    end

    return tbItemList
end

function ItemData.GetBoxItem(nBox)
    local tbItemList = {}
    local player = PlayerData.GetClientPlayer()
    if not player then
        return tbItemList
    end

    for index = 0, player.GetBoxSize(nBox) - 1 do
        local hItem = player.GetItem(nBox, index)
        table.insert(tbItemList, { nBox = nBox, nIndex = index, hItem = hItem })
    end

    return tbItemList
end

function ItemData.GetItemStackNum(item)
    if not item then
        return 0
    end
    if not item.bCanStack then
        return 1
    end
    return item.nStackNum
end

function ItemData.GetItemHouseBagStackNum(item, bItem)
    if not item then return end

    local player = GetClientPlayer()
    if not player then return end

    local tHouseBagLine
    if bItem then
        tHouseBagLine = Table_GetHomelandLockerInfoByItem(item.dwIndex)
    else
        tHouseBagLine = Table_GetHomelandLockerInfoByItem(item.dwID)
    end

    if not tHouseBagLine then return end

    local tFilter = HomelandMiniGameData.tFilterCheck[tHouseBagLine.dwClassType]
    local nCount = player.GetRemoteArrayUInt(tFilter.DATAMANAGE, tFilter.ITEMSTART + (tHouseBagLine.dwDataIndex - 1) * tFilter.BYTE_NUM, tFilter.BYTE_NUM)

    return nCount
end

function ItemData.GetItemBaiZhanStackNum(item, bItem)
    local BAIZHAN_DATA_LEN = 2
    local BAIZHAN_DATA_INDEX = 1146
    local BAIZHAN_START_INDEX = 0
    local BAIZHAN_END_INDEX = 99
    local nCount
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return nCount
    end

    if not hPlayer.RemoteDataAutodownFinish() then
        return nCount
    end

    local nIndex
    if bItem then
        nIndex = item and item.dwIndex
    else
        nIndex = item and item.dwID
    end

    if nIndex == 0 or not nIndex then
        return nCount
    end

    local tBaiZhanItemList = Table_GetMonsterLockerItem()
    for i = BAIZHAN_START_INDEX, BAIZHAN_END_INDEX, BAIZHAN_DATA_LEN do
        local dwID = hPlayer.GetRemoteArrayUInt(BAIZHAN_DATA_INDEX, i, BAIZHAN_DATA_LEN)
        local tInfo = tBaiZhanItemList[dwID]
        if tInfo and tInfo.dwItemID and tInfo.dwItemID == nIndex then
            nCount = nCount or 0
            nCount = nCount + 1
        end
    end

    return nCount
end

function ItemData.GetItemAllStackNum(item, bItem)
    local nTotalNum = 0
    local nBagNum = 0
    local nBankNum = 0
    local nHomelandNum
    local nBaiZhanNum

    local player = PlayerData.GetClientPlayer()
    if not player then
        return nTotalNum, nBagNum, nBankNum, nHomelandNum
    end

    local tbBag = ItemData.GetCurrentBag()
    for _, nBox in ipairs(tbBag) do
        for nIndex = 0, player.GetBoxSize(nBox) - 1 do
            local hItem = player.GetItem(nBox, nIndex)
            if hItem and ((bItem and hItem.dwIndex == item.dwIndex and hItem.dwTabType == item.dwTabType) or (not bItem and hItem.dwIndex == item.dwID and hItem.nGenre == item.nGenre)) then
                nBagNum = ItemData.GetItemStackNum(hItem) + nBagNum
            end
        end
    end

    for _, nBox in ipairs(ItemData.BoxSet.Bank) do
        for nIndex = 0, player.GetBoxSize(nBox) - 1 do
            local hItem = player.GetItem(nBox, nIndex)
            if hItem and ((bItem and hItem.dwIndex == item.dwIndex and hItem.dwTabType == item.dwTabType) or (not bItem and hItem.dwIndex == item.dwID and hItem.nGenre == item.nGenre)) then
                nBankNum = ItemData.GetItemStackNum(hItem) + nBankNum
            end
        end
    end

    local dwMapID = player.GetMapID()
    if HomelandData.IsHomelandMap(dwMapID) or TongData.IsInDemesne() then
        nHomelandNum = ItemData.GetItemHouseBagStackNum(item, bItem)
    end

    if MonsterBookData.IsInBaiZhanMap() then
        nBaiZhanNum = ItemData.GetItemBaiZhanStackNum(item, bItem)
    end

    if nHomelandNum then
        nTotalNum = nBagNum + nBankNum + nHomelandNum
    elseif nBaiZhanNum then
        nTotalNum = nBagNum + nBankNum + nBaiZhanNum
    else
        nTotalNum = nBagNum + nBankNum
    end

    return nTotalNum, nBagNum, nBankNum, nHomelandNum, nBaiZhanNum
end

function ItemData.GetBookAllStackNum(item, bItem)
    local nTotalNum = 0
    local nBagNum = 0
    local nBankNum = 0
    local nHomelandNum

    local player = PlayerData.GetClientPlayer()
    if not player then
        return nTotalNum, nBagNum, nBankNum, nHomelandNum
    end

    local tbBag = ItemData.GetCurrentBag()
    for _, nBox in ipairs(tbBag) do
        for nIndex = 0, player.GetBoxSize(nBox) - 1 do
            local hItem = player.GetItem(nBox, nIndex)
            if hItem and ((bItem and hItem.dwIndex == item.dwIndex and hItem.dwTabType == item.dwTabType) or (not bItem and hItem.dwIndex == item.dwID and hItem.nGenre == item.nGenre)) then
                if hItem.nBookID == item.nBookID then
                    nBagNum = ItemData.GetItemStackNum(hItem) + nBagNum
                end
            end
        end
    end

    for _, nBox in ipairs(ItemData.BoxSet.Bank) do
        for nIndex = 0, player.GetBoxSize(nBox) - 1 do
            local hItem = player.GetItem(nBox, nIndex)
            if hItem and ((bItem and hItem.dwIndex == item.dwIndex and hItem.dwTabType == item.dwTabType) or (not bItem and hItem.dwIndex == item.dwID and hItem.nGenre == item.nGenre)) then
                if hItem.nBookID == item.nBookID then
                    nBankNum = ItemData.GetItemStackNum(hItem) + nBankNum
                end
            end
        end
    end

    -- local dwMapID = player.GetMapID()
    -- if HomelandData.IsHomelandMap(dwMapID) then
    --     nHomelandNum = ItemData.GetItemHouseBagStackNum(item, bItem)
    -- end

    -- if nHomelandNum then
    --     nTotalNum = nBagNum + nBankNum + nHomelandNum
    -- else
    --     nTotalNum = nBagNum + nBankNum
    -- end

    nTotalNum = nBagNum + nBankNum

    return nTotalNum, nBagNum, nBankNum --, nHomelandNum
end

function ItemData.GetItemMaxStackNum(item)
    if not item then
        return 0
    end
    if not item.bCanStack then
        return 1
    end
    return item.nMaxDurability
end

function ItemData.GetBoxSlotItemList(nBox, tbSlotSet)
    local tbItemList = {}
    local player = PlayerData.GetClientPlayer()
    if not player then
        return tbItemList
    end

    for _, nIndex in ipairs(tbSlotSet) do
        local hItem = player.GetItem(nBox, nIndex)
        table.insert(tbItemList, { nBox = nBox, nIndex = nIndex, hItem = hItem })
    end

    return tbItemList
end

---@return KGItem, number, number
function ItemData.GetItem(dwItemID)
    local nBox, nIndex = ItemData.GetItemPos(dwItemID)
    return ItemData.GetItemByPos(nBox, nIndex), nBox, nIndex
end


--[[
    获取道具所在位置

    如果 1 个参数 则: return player.GetItemPos(dwItemID)
    如果 2 个参数 则: return player.GetItemPos(dwTabType, dwIndex)
    如果 4 个参数 则: return player.GetItemPos(dwTabType, dwIndex, bIncludeBank, bIncludeCubPackage)
]]
function ItemData.GetItemPos(...)
    local tbArg = { ... }
    if not tbArg then
        return
    end

    local nLen = #tbArg
    if nLen == 0 then
        return
    end

    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

    if nLen == 1 then
        local dwItemID = tbArg[1]
        return player.GetItemPos(dwItemID)
    elseif nLen == 2 then
        local dwTabType = tbArg[1]
        local dwIndex = tbArg[2]
        return player.GetItemPos(dwTabType, dwIndex)
    elseif nLen == 4 then
        local dwTabType = tbArg[1]
        local dwIndex = tbArg[2]
        local bIncludeBank = tbArg[3]
        local bIncludeCubPackage = tbArg[4]
        return player.GetItemPos(dwTabType, dwIndex, bIncludeBank, bIncludeCubPackage)
    end

    return nil
end

---@class KGItem 道具信息，仅列出常用的字段，需要补充更多可参考 KGLuaItem.cpp 最后面具体导出的字段名称
---@field dwID number ID
---@field szName string 名称
---@field nLevel number 等级
---@field dwTabType number 配置表的TabType
---@field dwIndex number 配置表的Index
---@field nStackNum number 堆叠数
---@field nBookID number 书籍ID（与堆叠数是同一个值）

---@return KGItem
function ItemData.GetItemByPos(nBox, nIndex)
    if not nBox or not nIndex then
        return
    end
    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end
    return player.GetItem(nBox, nIndex)
end

function ItemData.GetItemInfo(nTabType, nIndex)
    local itemInfo = GetItemInfo(nTabType, nIndex)

    return itemInfo
end

function ItemData.GetBagAllEquipWithType(nType)
    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

    local tbAllEquipInfo = {}
    local tbBag = ItemData.GetCurrentBag()
    for _, nBox in ipairs(tbBag) do
        for nIndex = 0, player.GetBoxSize(nBox) - 1 do
            local hItem = player.GetItem(nBox, nIndex)

            if hItem and hItem.nGenre == ITEM_GENRE.EQUIPMENT then
                local _, nPos = ItemData.GetEquipItemEquiped(player, hItem.nSub, hItem.nDetail)
                if nPos == nType then
                    table.insert(tbAllEquipInfo, {
                        item = hItem,
                        nBox = nBox,
                        nIndex = nIndex,
                    })
                elseif nPos == EQUIPMENT_INVENTORY.LEFT_RING or nPos == EQUIPMENT_INVENTORY.RIGHT_RING then
                    if EQUIPMENT_INVENTORY.RIGHT_RING == nType or EQUIPMENT_INVENTORY.LEFT_RING == nType then
                        table.insert(tbAllEquipInfo, {
                            item = hItem,
                            nBox = nBox,
                            nIndex = nIndex,
                        })
                    end
                end
            end
        end
    end

    return tbAllEquipInfo
end

-- UseItem()换成UseItemWrapper是为了兼容道具使用的回调
function ItemData.UseItem(nBox, nIndex)
    if PropsSort.IsBagInSort() then
        TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
        return
    end

    return ItemData.UseItemWrapper(nBox, nIndex)
end

function ItemData.UseItemWithMode(nBox, nIndex, mode)
    if PropsSort.IsBagInSort() then
        TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
        return
    end
    return ItemData.UseItemWrapper(nBox, nIndex, mode)
end

function ItemData.UseSkillSkin(nBox, nIndex)
    if PropsSort.IsBagInSort() then
        TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
        return
    end

    local player = GetClientPlayer()
    if not player then
        return
    end
    local item = ItemData.GetItemByPos(nBox, nIndex)
    local nNewSkinID = item.nDetail
    local tSkinInfo = Table_GetSkillSkinInfo(nNewSkinID) or {}
    local dwGroupID = Table_GetSkillSkinGroup(tSkinInfo.dwSkillID)
    local dwCurSkinID = player.GetActiveSkillSkinByGroupID(dwGroupID)
    ItemData.UseItem(nBox, nIndex)
end

function ItemData.UseBoxItem(nBox, nIndex)
    if PropsSort.IsBagInSort() then
        TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
        return
    end

    local player = GetClientPlayer()
    local itemBox = player.GetItem(nBox, nIndex)

    if not itemBox then
        return
    end

    if itemBox.nSub == BOX_SUB_TYPE.ADVANCE then
        local itemBoxInfo = GetItemInfo(itemBox.dwTabType, itemBox.dwIndex)
        if IsImmediacyOpenBox(itemBoxInfo.dwBoxTemplateID) then
            OpenBox(nBox, nIndex, 0)
            return
        end
        Event.Dispatch(EventType.OnUseBoxItemToOpenBox, nBox, nIndex)
    else
        OpenBox(nBox, nIndex, 0)
    end


end

function ItemData.OpenBox(bResult, dwBoxIndex, dwPos)
    if PropsSort.IsBagInSort() then
        TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
        return
    end

    if not bResult then
        return
    end
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local hBox = hPlayer.GetItem(dwBoxIndex, dwPos)
    if not hBox then
        return
    end

    local hBoxInfo = GetItemInfo(hBox.dwTabType, hBox.dwIndex)
    if not hBoxInfo then
        return
    end
    hPlayer.ClientOpenBox(dwBoxIndex, dwPos)
    RemoteCallToServer("OnLootBoxItem", dwBoxIndex, dwPos)
end

function ItemData.UseItemToPoint(nBox, nIndex, eCastMode, nX, nY, nZ)
    if PropsSort.IsBagInSort() then
        TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
        return
    end

    return ItemData.UseItemWrapper(nBox, nIndex, eCastMode, nX, nY, nZ)
end

function ItemData.UseItemToItem(nBox, nIndex, dwTargetBox, dwTargetIndex, nParam)
    if PropsSort.IsBagInSort() then
        TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
        return
    end

    nParam = nParam or -1
    return ItemData.UseItemWrapper(nBox, nIndex, SKILL_CAST_MODE.ITEM, dwTargetBox, dwTargetIndex, nParam)
end

function ItemData.DestroyItem(nBox, nIndex, dwSplitAmount)
    if PropsSort.IsBagInSort() then
        TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DESTROY_IN_SORT)
        return
    end

    do
        local item = ItemData.GetItemByPos(nBox, nIndex)
        if item.nQuality > 0 then
            local bItemLocked = false
            do
                local dwBoxType = g_pClientPlayer.GetBoxType(nBox)
                if dwBoxType == INVENTORY_TYPE.BANK then
                    bItemLocked = BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.BANK)
                end
            end
            if not bItemLocked then
                bItemLocked = BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP, "destroy")
            end
            if bItemLocked then
                return
            end
        end
    end

    local bTreasureBF = BattleFieldData.IsInTreasureBattleFieldMap()
    if bTreasureBF then
        RemoteCallToServer("On_Item_Drop", nBox, nIndex)
        return
    end
    return DestroyItem(nBox, nIndex, dwSplitAmount)
end

function ItemData.CanExchangeItem(nSrcBox, nSrcIndex, nDestBox, nDestIndex)
    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

    local nResult = player.CanExchange(nSrcBox, nSrcIndex, nDestBox, nDestIndex)
    return nResult == ITEM_RESULT_CODE.SUCCESS, nResult
end

function ItemData.ExchangeItem(nSrcBox, nSrcIndex, nDestBox, nDestIndex, bEnableStack)
    if bEnableStack == nil then
        bEnableStack = true
    end
    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

    local nRetCode = player.ExchangeItem(nSrcBox, nSrcIndex, nDestBox, nDestIndex, 0, bEnableStack)
    local bSuccess = nRetCode == ITEM_RESULT_CODE.SUCCESS

    if bSuccess then
        APIHelper.SetCanShowEquipScore(true)
    end

    return bSuccess
end

function ItemData.ExchangeItemByNum(nSrcBox, nSrcIndex, nDestBox, nDestIndex, nSplitNum)
    if PropsSort.IsBagInSort() then
        TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
        return
    end

    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

    return player.ExchangeItem(nSrcBox, nSrcIndex, nDestBox, nDestIndex, nSplitNum) == ITEM_RESULT_CODE.SUCCESS
end

function ItemData.OnExchangeItem(dwBox1, dwX1, dwBox2, dwX2, nCount, bEnableStack)
    local player = GetClientPlayer()
    if bEnableStack == nil then
        bEnableStack = true
    end
    if dwBox1 == INVENTORY_GUILD_BANK then
        if nCount then
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_GUILD_BANK_ERROR_NO_SPLIT)
            return false
        end
        if dwBox2 == INVENTORY_GUILD_BANK then
            local item1 = ItemData.GetPlayerItem(player, dwBox1, dwX1)
            local item2 = ItemData.GetPlayerItem(player, dwBox2, dwX2)
            local nPage1, nIndex1 = GetGuildBankPagePos(dwBox1, dwX1)
            local nPage2, nIndex2 = GetGuildBankPagePos(dwBox2, dwX2)

            if item1 and item2 and nPage1 == nPage2 and
                    item1.dwTabType == item2.dwTabType and item1.dwIndex == item2.dwIndex and
                    item2.bCanStack and item2.nStackNum < item2.nMaxStackNum then
                if not nCount then
                    nCount = item1.nStackNum
                end
                if nCount + item2.nStackNum > item2.nMaxStackNum then
                    nCount = item2.nMaxStackNum - item2.nStackNum
                end

                GetTongClient().StackItemInRepertory(nPage1, nIndex1, nIndex2, nCount)
                return true
            else
                GetTongClient().ExchangeRepertoryItemPos(nPage1, nIndex1, nPage2, nIndex2)
                return true
            end
        else
            if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TONG_REPERTORY, "帮会仓库") then
                return
            end

            local item1 = ItemData.GetPlayerItem(player, dwBox1, dwX1)
            local item2 = ItemData.GetPlayerItem(player, dwBox2, dwX2)
            if item1 then
                if item2 then
                    if item1.dwTabType == item2.dwTabType and item1.dwIndex == item2.dwIndex and item1.bCanStack then
                        if item1.nStackNum + item2.nStackNum <= item1.nMaxStackNum then
                            local nPage1, nIndex1 = GetGuildBankPagePos(dwBox1, dwX1)
                            GetTongClient().TakeRepertoryItem(nPage1, nIndex1, dwBox2, dwX2)
                            return true
                        else
                            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_GUILD_BANK_ERROR_OVER_MAX_STACK_NUM)
                            return false
                        end
                    else
                        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_GUILD_BANK_ERROR_NO_EXCHANGE)
                        return false
                    end
                else
                    local nPage1, nIndex1 = GetGuildBankPagePos(dwBox1, dwX1)
                    GetTongClient().TakeRepertoryItem(nPage1, nIndex1, dwBox2, dwX2)
                end
                return true
            elseif item2 then
                if item2.nGenre == ITEM_GENRE.TASK_ITEM then
                    OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.GUILD_BANK_CAN_NOT_PUT_TASK_ITME)
                    return false
                end

                if item2.bBind then
                    OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.GUILD_BANK_CAN_NOT_PUT_BIND_ITME)
                    return false
                end

                local itemInfo = GetItemInfo(item2.dwTabType, item2.dwIndex)
                if itemInfo.nExistType ~= ITEM_EXIST_TYPE.PERMANENT then
                    OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.ERROR_GUILD_NOT_TIME_LIMIT)
                    return false
                end

                local nPage1, nIndex1 = GetGuildBankPagePos(dwBox1, dwX1)
                GetTongClient().PutItemToRepertory(dwBox2, dwX2, nPage1, nIndex1)
                return true
            end
            return true
        end
    elseif dwBox2 == INVENTORY_GUILD_BANK then
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TONG_REPERTORY, "帮会仓库") then
            return
        end

        local item1 = ItemData.GetPlayerItem(player, dwBox1, dwX1)
        local item2 = ItemData.GetPlayerItem(player, dwBox2, dwX2)
        if item1 and item2 then
            local nPage2, nIndex2 = GetGuildBankPagePos(dwBox2, dwX2)
            if item1.dwTabType == item2.dwTabType and item1.dwIndex == item2.dwIndex and item1.bCanStack then
                if item2.nStackNum == item2.nMaxStackNum then
                    OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_GUILD_BANK_ERROR_NO_EXCHANGE)
                    return false
                end

                if not nCount then
                    nCount = item1.nStackNum
                end
                if nCount + item2.nStackNum > item2.nMaxStackNum then
                    nCount = item2.nMaxStackNum - item2.nStackNum
                end

                GetTongClient().StackRepertoryItem(dwBox1, dwX1, nPage2, nIndex2, nCount)
                return true
            end
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_GUILD_BANK_ERROR_NO_EXCHANGE)
            return false
        elseif item1 then
            if item1.nGenre == ITEM_GENRE.TASK_ITEM then
                OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.GUILD_BANK_CAN_NOT_PUT_TASK_ITME)
                return false
            end

            local itemInfo = ItemData.GetItemInfo(item1.dwTabType, item1.dwIndex)
            if item1.bBind and (not itemInfo.IsTongBind()) then
                OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.GUILD_BANK_CAN_NOT_PUT_BIND_ITME)
                return false
            end

            if itemInfo.nExistType ~= ITEM_EXIST_TYPE.PERMANENT then
                OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.ERROR_GUILD_NOT_TIME_LIMIT)
                return false
            end

            local nPage2, nIndex2 = GetGuildBankPagePos(dwBox2, dwX2)
            if nCount then
                OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_GUILD_BANK_ERROR_NO_SPLIT_1)
                --GetTongClient().StackRepertoryItem(dwBox1, dwX1, nPage2, nIndex2, nCount)
            else
                GetTongClient().PutItemToRepertory(dwBox1, dwX1, nPage2, nIndex2)
                return true
            end
        elseif item2 then
            if nCount then
                OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_GUILD_BANK_ERROR_NO_SPLIT)
                return false
            end

            local nPage2, nIndex2 = GetGuildBankPagePos(dwBox2, dwX2)
            GetTongClient().TakeRepertoryItem(nPage2, nIndex2, dwBox1, dwX1)
            return true
        end
        return true
    end

    if not dwBox1 or not dwX1 or not dwBox2 or not dwX2 then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.SRT_ERROR_CANCEL_CURSOR_STATE)
        return false
    end

    if INVENTORY_INDEX.CUB_PACKAGE == dwBox2 then
        local item = ItemData.GetPlayerItem(player, dwBox1, dwX1)
        if item and not ((item.nGenre == ITEM_GENRE.CUB and item.nSub == DOMESTICATE_CUB_SUB_TYPE.FOAL) or
                (item.nGenre == ITEM_GENRE.EQUIPMENT and item.nSub == EQUIPMENT_SUB.HORSE)) then
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_ERROR_HORSE_STABLE_IONLY_CUB_HORSE)
            return false
        end
    end

    local nCanExchange = player.CanExchange(dwBox1, dwX1, dwBox2, dwX2)
    if nCanExchange == ITEM_RESULT_CODE.SUCCESS then
        local item = nil
        local dwEqBox = INVENTORY_INDEX.EQUIP
        local dwEqPos = nil
        if dwBox1 == INVENTORY_INDEX.EQUIP then
            item = ItemData.GetPlayerItem(player, dwBox2, dwX2)
            dwEqPos = dwX1
        elseif dwBox2 == INVENTORY_INDEX.EQUIP then
            item = ItemData.GetPlayerItem(player, dwBox1, dwX1)
            dwEqPos = dwX2
        elseif IsHorsePackage(dwBox1) then
            item = ItemData.GetPlayerItem(player, dwBox2, dwX2)
            dwEqBox = dwBox1
            dwEqPos = dwX1
        elseif IsHorsePackage(dwBox2) then
            item = ItemData.GetPlayerItem(player, dwBox1, dwX1)
            dwEqBox = dwBox2
            dwEqPos = dwX2
        end
        if item and item.nBindType == ITEM_BIND.BIND_ON_EQUIPPED and not item.bBind and dwEqPos and
                ((dwEqBox == INVENTORY_INDEX.EQUIP and (dwEqPos < EQUIPMENT_INVENTORY.PACKAGE1 or dwEqPos > EQUIPMENT_INVENTORY.BANK_PACKAGE5)) or
                        (item.nGenre == ITEM_GENRE.EQUIPMENT and item.nSub == EQUIPMENT_SUB.PACKAGE) or IsHorsePackage(dwEqBox)) then

            local szMessage = FormatString(g_tStrings.STR_MSG_EQUIP_BIND_ITEM_SURE, UIHelper.GBKToUTF8(item.szName))
            UIHelper.ShowConfirm(szMessage, function()
                player.ExchangeItem(dwBox1, dwX1, dwBox2, dwX2, nCount, bEnableStack)
                --PlayItemSound(nUiId)
            end)
        else
            local nRetCode, bTimeExistItem, nLeftExistTime, bEqualTime = player.CanStackTimeExistItem(dwBox1, dwX1, dwBox2, dwX2)
            if nRetCode == ITEM_RESULT_CODE.SUCCESS and bTimeExistItem and not bEqualTime and bEnableStack then
                local szTime = UIHelper.GetTimeTextWithDay(nLeftExistTime)
                local szText = FormatString(g_tStrings.STACK_TIME_EXIST_ITEM_TIP, szTime)
                UIHelper.ShowConfirm(szText, function()
                    player.ExchangeItem(dwBox1, dwX1, dwBox2, dwX2, nCount, bEnableStack)
                end)
            else
                player.ExchangeItem(dwBox1, dwX1, dwBox2, dwX2, nCount, bEnableStack)
            end
        end
        return true
    else
        if nCanExchange == ITEM_RESULT_CODE.BANK_PASSWORD_EXIST and BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.BANK) then
            return
        end
        Global.OnItemRespond(nCanExchange)
    end
    return false
end

function ItemData.CheckEquipIndexHadEquipedWithItem(player, item)
    player = player or PlayerData.GetClientPlayer()
    local bRet = false

    if not item then
        return bRet
    end

    local nBox, nIndex = ItemData.GetEquipItemEquiped(player, item.nSub, item.nDetail)
    local item = ItemData.GetItemByPos(nBox, nIndex)
    if item then
        bRet = true
    end

    return bRet
end

local tbCanBeEquipKind = {
    "MELEE_WEAPON",
    "RANGE_WEAPON",
    "CHEST",
    "HELM",
    "AMULET",
    "RING",
    "WAIST",
    "PENDANT",
    "PANTS",
    "BOOTS",
    "BANGLE",
}
function ItemData.IsItemCanBeEquip(nGenre, nSub)
    if nGenre ~= ITEM_GENRE.EQUIPMENT then
        return false
    end
    local bSubKind = false
    for _, v in ipairs(tbCanBeEquipKind) do
        if nSub == EQUIPMENT_SUB[v] then
            bSubKind = true
            break
        end
    end
    return bSubKind
end

function ItemData.EquipItem(nSrcBox, nSrcIndex)
    if PropsSort.IsBagInSort() then
        TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
        return
    end

    local nRet = false

    local player = PlayerData.GetClientPlayer()
    if not player then
        return nRet
    end

    local item = ItemData.GetItemByPos(nSrcBox, nSrcIndex)
    if not item or item.nGenre ~= ITEM_GENRE.EQUIPMENT then
        return nRet
    end

    if ItemData.IsBanUseItem(item) then
		ItemData.OnUseBanItem(nSrcBox, nSrcIndex)
        return
    end

    local doEquip = function()
        local nDestBox, nDestIndex = ItemData.GetEquipItemEquiped(player, item.nSub, item.nDetail)
        if ItemData.nExchangeRingIndex and item.nSub == EQUIPMENT_SUB.RING then
            nDestIndex = ItemData.nExchangeRingIndex
        end

        if nDestBox and nDestIndex then
            local bExchange, nResult = ItemData.CanExchangeItem(nSrcBox, nSrcIndex, nDestBox, nDestIndex)
            if bExchange then
                ItemData.ExchangeItem(nSrcBox, nSrcIndex, nDestBox, nDestIndex)
                nRet = true
            else
                OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.tItem_Msg[nResult])
            end
        end
    end

    if item.nBindType == ITEM_BIND.BIND_ON_EQUIPPED and not item.bBind then
        local szShowMessage = g_tStrings.STR_MSG_EQUIP_BIND_ITEM_SURE
        local szConfirmContain = string.format(szShowMessage, UIHelper.GBKToUTF8(item.szName))
        UIHelper.ShowConfirm(szConfirmContain, function()
            doEquip()
        end)
    else
        doEquip()
    end

    return nRet
end

function ItemData.EquipAllItem(tbEquipItem)

    local player = g_pClientPlayer
    if not player then
        return
    end

    local leftItem = ItemData.GetItemByPos(INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.LEFT_RING)
    local rightItem = ItemData.GetItemByPos(INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.RIGHT_RING)

    local tbEquipedRing = {}
    tbEquipedRing[EQUIPMENT_INVENTORY.LEFT_RING] = leftItem
    tbEquipedRing[EQUIPMENT_INVENTORY.RIGHT_RING] = rightItem

    for nIndex, tbData in ipairs(tbEquipItem) do
        local dwBox, dwX = tbData.dwBox, tbData.dwX
        local item = PlayerData.GetPlayerItem(player, dwBox, dwX)
        if item then
            local doEquip = function()
                if item.nSub == EQUIPMENT_SUB.RING then

                    local leftItem = tbEquipedRing[EQUIPMENT_INVENTORY.LEFT_RING]
                    local rightItem = tbEquipedRing[EQUIPMENT_INVENTORY.RIGHT_RING]
                    local leftLevel = leftItem and leftItem.nLevel or 0
                    local rightLevel = rightItem and rightItem.nLevel or 0
                    local nPos = leftLevel > rightLevel and EQUIPMENT_INVENTORY.RIGHT_RING or EQUIPMENT_INVENTORY.LEFT_RING

                    ItemData.ExchangeItem(dwBox, dwX, INVENTORY_INDEX.EQUIP, nPos)
                    tbEquipedRing[nPos] = item

                else
                    local nDestBox, nDestIndex = ItemData.GetEquipItemEquiped(player, item.nSub, item.nDetail)
                    ItemData.ExchangeItem(dwBox, dwX, nDestBox, nDestIndex)
                end
            end
            if item.nBindType == ITEM_BIND.BIND_ON_EQUIPPED and not item.bBind then
                local szShowMessage = g_tStrings.STR_MSG_EQUIP_BIND_ITEM_SURE
                local szConfirmContain = string.format(szShowMessage, UIHelper.GBKToUTF8(item.szName))
                UIHelper.ShowConfirm(szConfirmContain, function()
                    doEquip()
                end)
            else
                doEquip()
            end
        end
    end

end

local tbRingExchangeCfg = {
    [1] = EQUIPMENT_INVENTORY.LEFT_RING,
    [2] = EQUIPMENT_INVENTORY.RIGHT_RING
}

function ItemData.EquipHorseOrHorseEquip(nSrcBox, nSrcIndex)
    local nRet = false

    local player = PlayerData.GetClientPlayer()
    if not player then
        return nRet
    end

    local item = ItemData.GetItemByPos(nSrcBox, nSrcIndex)
    if not item or (item.nSub ~= EQUIPMENT_SUB.HORSE and item.nSub ~= EQUIPMENT_SUB.HORSE_EQUIP) then
        return nRet
    end

    local doEquip = function()
        if item.IsRareHorse() then
            local eRetCode, nDestBox, nDestX = g_pClientPlayer.GetEquipPosEx(nSrcBox, nSrcIndex)
            if eRetCode == ITEM_RESULT_CODE.SUCCESS then
                player.ExchangeItem(nSrcBox, nSrcIndex, nDestBox, nDestX)
            else
                if eRetCode == ITEM_RESULT_CODE.BANK_PASSWORD_EXIST and BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.BANK) then
                    return
                end
                OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tItem_Msg[eRetCode])
            end
        elseif item.nSub == EQUIPMENT_SUB.HORSE_EQUIP then
            ItemData.OnUseHorseEquipItem(nSrcBox, nSrcIndex)
        else
            local nDestBox = INVENTORY_INDEX.HORSE
            for i = 0, GLOBAL.HORSE_PACKAGE_SIZE - 1, 1 do
                local item = ItemData.GetPlayerItem(g_pClientPlayer, nDestBox, i)
                if not item then
                    ItemData.ExchangeItem(nSrcBox, nSrcIndex, nDestBox, i)
                    nRet = true
                    break
                end
            end
            if not nRet then
                TipsHelper.ShowNormalTip("当前没有空置坐骑槽位，请卸下现有坐骑后重试")
                if not UIMgr.GetView(VIEW_ID.PanelSaddleHorse) then
                    local script = UIMgr.Open(VIEW_ID.PanelSaddleHorse)
                    Timer.Add(self, 1, function ()
                        UIHelper.SetSelected(script.TogNormal, true)
                    end)
                end
            end
        end
    end

    if item.nBindType == ITEM_BIND.BIND_ON_EQUIPPED and not item.bBind then
        local szShowMessage = g_tStrings.STR_MSG_EQUIP_BIND_ITEM_SURE
        local szConfirmContain = string.format(szShowMessage, UIHelper.GBKToUTF8(item.szName))
        UIHelper.ShowConfirm(szConfirmContain, function()
            doEquip()
        end)
    else
        doEquip()
    end

    return nRet
end

function ItemData.OnUseHorseEquipItem(nSrcBox, nSrcIndex)
    if PropsSort.IsBagInSort() then
        TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
        return
    end

    local nRet = false

    local player = PlayerData.GetClientPlayer()
    if not player then
        return nRet
    end

    if player.nMoveState == MOVE_STATE.ON_DEATH then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.HORSE_EQUIP_CANNOT_CHANGE_WHEN_DIE)
        return
    end

    local item = ItemData.GetItemByPos(nSrcBox, nSrcIndex)
    if not item or item.nGenre ~= ITEM_GENRE.EQUIPMENT or item.nSub ~= EQUIPMENT_SUB.HORSE_EQUIP then
        return nRet
    end

    local nRetCode = player.CheckEquipRequire(nSrcBox, nSrcIndex)
    if nRetCode == ITEM_RESULT_CODE.BANK_PASSWORD_EXIST and BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.BANK) then
        return nRet
    elseif nRetCode ~= ITEM_RESULT_CODE.SUCCESS then
        Global.OnItemRespond(nRetCode)
        return nRet
    end

    if player.IsHorseEquipExist(item.dwIndex) then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.HORSE_EQUIP_ALEADY_HAVE)
        return nRet
    end
    local nSize = player.GetHorseEquipBoxSize() or 0
    local nCount = player.GetHorseEquipCount() or 0
    if nCount >= nSize then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.HORSE_EQUIP_NOT_ENOUGH_SIZE)
        return nRet
    end

    local name = UIHelper.GBKToUTF8(ItemData.GetItemNameByItem(item))
    local szContent = "你确定要将 " .. name .. " 放入马具包吗？放入后，它将无法拆卸和交易。"
    UIHelper.ShowConfirm(szContent, function()
        RemoteCallToServer("OnUseHorseEquipItem", nSrcBox, nSrcIndex)
    end, nil, false)
    nRet = true

    return nRet
end

function ItemData.OnUseMiniAvatarItem(nSrcBox, nSrcIndex)
    if PropsSort.IsBagInSort() then
        TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
        return
    end

    local nRet = false
    local player = PlayerData.GetClientPlayer()
    if player.nMoveState == MOVE_STATE.ON_DEATH then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_AVATAR_WARNING2)
        return nRet
    end

    local item = ItemData.GetItemByPos(nSrcBox, nSrcIndex)
    if not item or item.nGenre ~= ITEM_GENRE.EQUIPMENT or item.nSub ~= EQUIPMENT_SUB.MINI_AVATAR then
        return nRet
    end

    local nRetCode = player.CheckEquipRequire(nSrcBox, nSrcIndex)
    if nRetCode == ITEM_RESULT_CODE.BANK_PASSWORD_EXIST and BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.BANK) then
        return nRet
    elseif nRetCode ~= ITEM_RESULT_CODE.SUCCESS then
        Global.OnItemRespond(nRetCode)
        return nRet
    end

    if player.GetMiniAvatarMgr().IsMiniAvatarAcquired(item.nRepresentID) then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_AVATAR_WARNING1)
        return nRet
    end

    local name = UIHelper.GBKToUTF8(ItemData.GetItemNameByItem(item))
    local szContent = "你确定要将 " .. name .. " 放入头像列表吗？放入后，它将无法拆卸和交易。"
    UIHelper.ShowConfirm(szContent, function()
        RemoteCallToServer("OnUseMiniAvatarItem", nSrcBox, nSrcIndex)
    end, nil, false)
    nRet = true

    return nRet
end

function ItemData.OnUseFollowPetItem(nSrcBox, nSrcIndex)
    if PropsSort.IsBagInSort() then
        TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
        return
    end

    local nRet = false
    local player = PlayerData.GetClientPlayer()
    if player.nMoveState == MOVE_STATE.ON_DEATH then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_AVATAR_WARNING2)
        return nRet
    end

    local item = ItemData.GetItemByPos(nSrcBox, nSrcIndex)
    if not item or item.nGenre ~= ITEM_GENRE.EQUIPMENT or item.nSub ~= EQUIPMENT_SUB.PET then
        return nRet
    end

    local nRetCode = player.CheckEquipRequire(nSrcBox, nSrcIndex)
    if nRetCode == ITEM_RESULT_CODE.BANK_PASSWORD_EXIST and BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.BANK) then
        return nRet
    elseif nRetCode ~= ITEM_RESULT_CODE.SUCCESS then
        Global.OnItemRespond(nRetCode)
        return
    end

    RemoteCallToServer("OnUseFollowPetItem", nSrcBox, nSrcIndex)
end

function ItemData.OnUseFurnitureItem(dwBox, dwX)
    if PropsSort.IsBagInSort() then
        TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
        return
    end

    local player = PlayerData.GetClientPlayer()
    -- local dwMapID = UI_GetCurrentMapID()
    -- if not IsHomelandCommunityMap(dwMapID) then
    --     OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_FURNITURE_USE_ERROR)
    --     return
    -- end
    local item = PlayerData.GetPlayerItem(player, dwBox, dwX)
    local szName = UIHelper.GBKToUTF8(item.szName)
    local szContent = string.format("你确定将【%s】放入园宅物件仓库吗？放入后,它将无法再变回道具或交易。", szName)

    UIHelper.ShowConfirm(szContent, function()
        ItemData.UseItem(dwBox, dwX)
    end, nil, false)
end

function ItemData.OnUseNameCardSkinItem(nSrcBox, nSrcIndex)
    if PropsSort.IsBagInSort() then
        TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
        return
    end

    local nRet = false
    local player = PlayerData.GetClientPlayer()
    if player.nMoveState == MOVE_STATE.ON_DEATH then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_AVATAR_WARNING2)
        return nRet
    end

    local item = ItemData.GetItemByPos(nSrcBox, nSrcIndex)
    if not item or item.nGenre ~= ITEM_GENRE.EQUIPMENT or item.nSub ~= EQUIPMENT_SUB.NAME_CARD_SKIN then
        return nRet
    end

    local nRetCode = player.CheckEquipRequire(nSrcBox, nSrcIndex)
    if nRetCode == ITEM_RESULT_CODE.BANK_PASSWORD_EXIST and BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.BANK) then
        return nRet
    elseif nRetCode ~= ITEM_RESULT_CODE.SUCCESS then
        Global.OnItemRespond(nRetCode)
        return
    end

    local name = UIHelper.GBKToUTF8(ItemData.GetItemNameByItem(item))
    UIHelper.ShowConfirm("你确定要将" .. name .. "放入纸笺列表吗？放入后，它将无法拆卸和交易。", function()
        RemoteCallToServer("OnUseNameCardItem", nSrcBox, nSrcIndex)
    end)
end

function ItemData.UnEquipItem(nSrcBox, nSrcIndex)
    if PropsSort.IsBagInSort() then
        TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
        return
    end

    local player = PlayerData.GetClientPlayer()
    if not player then
        return false
    end

    local srcItem = ItemData.GetItemByPos(nSrcBox, nSrcIndex)
    if not srcItem then
        return false
    end

    local tbBag = ItemData.GetCurrentBag()
    for _, nBox in ipairs(tbBag) do
        local nIndex = player.GetFreeRoom(nBox)
        if nIndex then
            if player.CanExchange(nSrcBox, nSrcIndex, nBox, nIndex) then
                if ItemData.ExchangeItem(nSrcBox, nSrcIndex, nBox, nIndex) then
                    return true
                end
            end
        end
    end

    TipsHelper.ShowNormalTip("背包已满")
    return false
end

function ItemData.BreakEquip(nSrcBox, nSrcIndex)
    if PropsSort.IsBagInSort() then
        TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
        return
    end

    RemoteCallToServer("OnBreakEquip", nSrcBox, nSrcIndex)
end

function ItemData.BatchBreakEquip(tSelectBreakEquip)
    local player = PlayerData.GetClientPlayer()
    if not player then
        return false
    end

    local nRet = player.CanBatchBreakEquip(tSelectBreakEquip)
	if nRet ~= BREAK_EQUIP_RESULT_CODE.SUCCESS then
		TipsHelper.ShowNormalTip(g_tStrings.BREAK_EQUIP_RESULT[nRet])
		return
	end
    RemoteCallToServer("OnBatchBreakEquip", tSelectBreakEquip)
end

local function GetPureEnchantDesc(dwID)
    local szDesc = UIHelper.GBKToUTF8(Table_GetCommonEnchantDesc(dwID))
    if szDesc then
        szDesc = string.pure_text(szDesc)
    else
        local aAttr, dwTime, nSubType = GetEnchantAttribute(dwID)
        if not aAttr or #aAttr == 0 then
            return ""
        end
        szDesc = ""
        local bFirst = true
        for k, v in pairs(aAttr) do
            EquipData.FormatAttributeValue(v)
            local szText = FormatString(Table_GetMagicAttributeInfo(v.nID, true), v.nValue1, v.nValue2, MAGIC_ATTRI_DEF, MAGIC_ATTRI_DEF)
            local szPText = ParseTextHelper.ParseNormalText(szText)
            szPText = UIHelper.GBKToUTF8(szPText)
            if szPText ~= "" then
                if bFirst then
                    bFirst = false
                else
                    szPText = "\n" .. szPText
                end
            end
            szDesc = szDesc .. szPText
        end
        if dwTime == 0 then
            --szDesc = szDesc .. g_tStrings.STR_FULL_STOP
        else
            local tEnchantTipShow = Table_GetEnchantTipShow()
            local tShow = tEnchantTipShow[nSubType]
            local bSurvival = tShow and tShow.bSurvivalEnchant
            if not bSurvival then
                szDesc = szDesc .. g_tStrings.STR_COMMA .. g_tStrings.STR_TIME_DURATION .. UIHelper.GetTimeText(dwTime)
            end
        end
    end

    return  UIHelper.AttachTextColor(szDesc, UI_SUCCESS_COLOR)
end

function ItemData.GetEnchantDesc(dwID)
    local aAttr, dwTime, nSubType = GetEnchantAttribute(dwID)
    if not aAttr or #aAttr == 0 then
        return ""
    end
    local szDesc = g_tStrings.tEquipTypeNameTable[nSubType]
    local bFirst = true
    for k, v in pairs(aAttr) do
        EquipData.FormatAttributeValue(v)
        local szText = FormatString(Table_GetMagicAttributeInfo(v.nID, true), v.nValue1, v.nValue2, MAGIC_ATTRI_DEF, MAGIC_ATTRI_DEF)
        szText = UIHelper.GBKToUTF8(szText)
        local szPText = string.pure_text(szText)
        if szPText ~= "" then
            if bFirst then
                bFirst = false
            else
                szPText = "\n" .. szPText
            end
        end
        szDesc = szDesc .. szPText
    end
    if dwTime == 0 then
        szDesc = szDesc .. g_tStrings.STR_FULL_STOP
    else
        local tEnchantTipShow = Table_GetEnchantTipShow()
        local tShow = tEnchantTipShow[nSubType]
        local bSurvival = tShow and tShow.bSurvivalEnchant
        szDesc = szDesc
        if not bSurvival then
            szDesc = szDesc .. g_tStrings.STR_COMMA .. g_tStrings.STR_TIME_DURATION .. TimeLib.GetTimeText(dwTime) .. g_tStrings.STR_FULL_STOP
        end

    end

    return szDesc
end

function ItemData.GetSpiStoneDesc(dwID)
    local aAttr = GetFEAInfoByEnchantID(dwID)
    if not aAttr or #aAttr == 0 then
        return ""
    end

    local szDesc = "\"</text>"
    local szTmp = ""
    local bFirst = true

    for k, v in pairs(aAttr) do
        if not bFirst then
            szDesc = szDesc .. "<text>text=\"\\\n\"</text>"
        end
        if bFirst then
            bFirst = false
        end

        EquipData.FormatAttributeValue(v)

        local szText = FormatString(g_tStrings.tActivation.COLOR_ATTRIBUTE, k)

        if v.nID == ATTRIBUTE_TYPE.SKILL_EVENT_HANDLER then
            local skillEvent = g_tTable.SkillEvent:Search(v.nValue1)
            if skillEvent then
                szTmp = FormatString(skillEvent.szDesc, v.nValue1, v.nValue2)
            else
                szTmp = "<text>text=\"unknown skill event id:" .. v.nValue1 .. "\"</text>"
            end
        else
            szTmp = FormatString(Table_GetMagicAttributeInfo(v.nID, true), v.nValue1, v.nValue2, MAGIC_ATTRI_DEF, MAGIC_ATTRI_DEF)
        end

        local szPText = szText .. UIHelper.GBKToUTF8(string.pure_text(szTmp))
        szDesc = szDesc .. "<Text>text=\"" .. szPText .. "\n\\" .. "\" font=100 </text>"
        szText = FormatString(g_tStrings.tActivation.COLOR_CONDITION, k)

        local szName = g_tStrings.STR_DIAMOND
        szTmp = FormatString(g_tStrings.tActivation.COLOR_CONDITION1, szName, g_tStrings.tActivation.COLOR_COMPARE[v.nCompare], v.nDiamondCount)
        szText = szText .. szTmp .. "\n\\"

        szTmp = FormatString(g_tStrings.tActivation.COLOR_CONDITION2, szName, v.nDiamondIntensity)
        szText = szText .. szTmp
        szDesc = szDesc .. "<Text>text=\"" .. szText .. "\" font=177 </text>"

    end
    szDesc = szDesc .. "<Text>text=\""
    return szDesc
end

function ItemData.GetItemDesc(nUiId)
    local szDesc = Table_GetItemDesc(nUiId)

    szDesc = string.gsub(szDesc, "<SKILL (%d+) (%d+)>", function(dwID, dwLevel)
        return GetSubSkillDesc(dwID, dwLevel)
    end)
    szDesc = string.gsub(szDesc, "<BUFF (%d+) (%d+) (%w+)>", function(dwID, nLevel, szKey)
        if szKey == "name" then
            return BuffMgr.GetBuffName(dwID, nLevel, true)
        elseif szKey == "time" then
            return UTF8ToGBK(BuffMgr.GetBuffTime(dwID, nLevel))
        elseif szKey == "count" then
            return UTF8ToGBK(BuffMgr.GetBuffCount(dwID, nLevel))
        elseif szKey == "interval" then
            return UTF8ToGBK(BuffMgr.GetInterval(dwID, nLevel))
        elseif szKey == "desc" then
            return BuffMgr.GetBuffDesc(dwID, nLevel, true)
        end
    end)
    szDesc = UIHelper.GBKToUTF8(szDesc)
    szDesc = string.gsub(szDesc, "<ENCHANT (%d+)>", function(dwID)
        return ItemData.GetEnchantDesc(dwID)
    end)
    szDesc = string.gsub(szDesc, "<SpiStone (%d+)>", function(dwID)
        return ItemData.GetSpiStoneDesc(dwID)
    end)

    return szDesc
end

function ItemData.GetTitleTips(itemInfo)
    local szTip = ""
    local player = GetClientPlayer()
    if not player then
        return
    end
    if itemInfo.nPrefix ~= 0 then
        local dwForceID = player and player.dwForceID or 0
		local aPrefix = Table_GetDesignationPrefixByID(itemInfo.nPrefix, dwForceID)
		if aPrefix then
            local szTitle = UIHelper.GBKToUTF8(aPrefix.szName)
			local szFinish = "("..g_tStrings.DESGNATION_POSTFIX_UNGET..")"
			if player.IsDesignationPrefixAcquired(itemInfo.nPrefix) then
				szFinish = "<color=#FF4040>".."("..g_tStrings.DESGNATION_POSTFIX_HAS_GET..")".."</c>"
			end

			local t = GetDesignationPrefixInfo(itemInfo.nPrefix)
			if t and t.nType == DESIGNATION_PREFIX_TYPE.WORLD_DESIGNATION then
				szTip = FormatString(g_tStrings.USE_TO_GET_DESGNATION_WORLD1, szTitle, szFinish)
			elseif t and t.nType == DESIGNATION_PREFIX_TYPE.MILITARY_RANK_DESIGNATION then
				szTip = FormatString(g_tStrings.USE_TO_GET_DESGNATION_MILITARY1, szTitle, szFinish)
			else
				szTip = FormatString(g_tStrings.USE_TO_GET_DESGNATION_PREFIX1, szTitle, szFinish)
			end
		end
	end

	if itemInfo.nPostfix ~= 0 then
		local aPostfix = g_tTable.Designation_Postfix:Search(itemInfo.nPostfix)
		if aPostfix then
            local szTitle = UIHelper.GBKToUTF8(aPostfix.szName)
			local szFinish = "("..g_tStrings.DESGNATION_POSTFIX_UNGET..")"
			if player.IsDesignationPostfixAcquired(itemInfo.nPostfix) then
				szFinish = "<color=#FF4040>".."("..g_tStrings.DESGNATION_POSTFIX_HAS_GET..")".."</c>"
			end
			szTip = FormatString(g_tStrings.USE_TO_GET_DESGNATION_POSTFIX1, szTitle, szFinish)
		end
	end
    return szTip
end

function ItemData.UseEnchantItem(dwBox, dwX, dwTargetBox, dwTargetX, nMode)
    if PropsSort.IsBagInSort() then
        TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
        return
    end

    local player = GetClientPlayer()
    local item = ItemData.GetPlayerItem(player, dwBox, dwX)
    local itemTarget = ItemData.GetPlayerItem(player, dwTargetBox, dwTargetX)
    local szTimeTip = GetTimeOperateItemTip(itemTarget)
    if not nMode then
        if item.dwSkillID and item.dwSkillID ~= 0 then
            local skill = GetSkill(item.dwSkillID, item.dwSkillLevel)
            if skill then
                nMode = skill.nCastMode
            end
        end
    end

    local fnAction = function()
        ItemData.UseItemWrapper(dwBox, dwX, nMode, dwTargetBox, dwTargetX)
    end

    --local szDesc = UIHelper.GBKToUTF8(Table_GetItemDesc(item.nUiId))
    local dwEnchantID = CraftData.g_EnchantInfo[item.dwIndex].EnchantID
    --szDesc = string.gsub(szDesc, "<ENCHANT (%d+)>", function(dwID)
    --    dwEnchantID = dwID
    --    return ""
    --end)

    if ItemData.IsEnchantItem(item) then
        if IsTempEnchantAttribute(CraftData.g_EnchantInfo[item.dwIndex].EnchantID) then
            -- 是否为临时附魔属性
            if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP) then
                return
            end
            local tEnchantTipShow = Table_GetEnchantTipShow()
            local tShow = tEnchantTipShow[itemTarget.nSub]
            local bSurvival = tShow and tShow.bSurvivalEnchant

            local szMsg
            if itemTarget.dwTemporaryEnchantID ~= 0 and not szMsg then
                szMsg = UIHelper.GBKToUTF8(Table_GetCommonEnchantDesc(itemTarget.dwTemporaryEnchantID))
                if szMsg then
                    szMsg = string.pure_text(szMsg)
                    if szMsg ~= "" and not bSurvival then
                        if itemTarget.nSub == EQUIPMENT_SUB.MELEE_WEAPON or itemTarget.nSub == EQUIPMENT_SUB.PANTS then
                            local szTime = FormatString(g_tStrings.STR_ITEM_TEMP_ECHANT_LEFT_TIME, UIHelper.GetTimeText(itemTarget.GetTemporaryEnchantLeftSeconds()))
                            --desc = desc .. string.format("<color=#FF4040>%s</c>", szTime)
                            szMsg = szMsg .. szTime
                        end
                    end
                else
                    local tempEnchantAttrib = GetItemEnchantAttrib(itemTarget.dwTemporaryEnchantID)
                    if tempEnchantAttrib then
                        local szAttr = ""
                        for k, v in pairs(tempEnchantAttrib) do
                            EquipData.FormatAttributeValue(v)
                            local szInfo = FormatString(Table_GetMagicAttributeInfo(v.nID, true), v.nValue1, v.nValue2, MAGIC_ATTRI_DEF, MAGIC_ATTRI_DEF)
                            local szFont = "font=113"
                            if bSurvival then
                                szFont = "font=101"
                            end
                            szInfo = string.gsub(szInfo, "font=%d+", szFont)
                            if szInfo ~= "" then
                                szInfo = szInfo .. "\n"
                            end
                            szAttr = szAttr .. szInfo
                            szAttr = ParseTextHelper.ParseNormalText(UIHelper.GBKToUTF8(szAttr))
                        end
                        szMsg = szAttr
                    end
                end
            end

            if szMsg and szMsg ~= "" then
                local szRes = FormatString(g_tStrings.MSG_ON_USE_ITEM3, UIHelper.GBKToUTF8(item.szName),
                        UIHelper.GBKToUTF8(itemTarget.szName), UIHelper.AttachTextColor(szMsg, UI_SUCCESS_COLOR) , GetPureEnchantDesc(dwEnchantID))
                UIHelper.ShowConfirm(szRes, fnAction, nil, true)
                return
            end
        else
            local enchantAttrib = GetItemEnchantAttrib(itemTarget.dwPermanentEnchantID)
            if enchantAttrib then
                if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP) then
                    return
                end

                local szAttr = ""
                for k, v in pairs(enchantAttrib) do
                    EquipData.FormatAttributeValue(v)
                    local szInfo = FormatString(Table_GetMagicAttributeInfo(v.nID, true), v.nValue1, v.nValue2, MAGIC_ATTRI_DEF, MAGIC_ATTRI_DEF)
                    szInfo = string.gsub(szInfo, "font=%d+", "font=113")
                    szAttr = szAttr .. szInfo
                    szAttr = ParseTextHelper.ParseNormalText(UIHelper.GBKToUTF8(szAttr))
                end

                local szMsg = FormatString(g_tStrings.MSG_ON_USE_ITEM3, UIHelper.GBKToUTF8(item.szName),
                        UIHelper.GBKToUTF8(itemTarget.szName), UIHelper.AttachTextColor(szAttr, UI_SUCCESS_COLOR), GetPureEnchantDesc(dwEnchantID))

                UIHelper.ShowConfirm(szMsg, fnAction, nil, true)
                return
            end
        end
    end

    local szNewMsg
    if IsCanTimeReturnItem(itemTarget) then
        szNewMsg = GetFormatText(g_tStrings.TIME_RETURN_MSG)
    elseif IsCanTimeTradeItem(itemTarget) then
        szNewMsg = FormatString(g_tStrings.STR_TRADE_BIND, 0)
    end

    if item.nGenre ~= ITEM_GENRE.TASK_ITEM and BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP) then
        return
    end
    if szNewMsg and szNewMsg ~= "" then
        local msg = szNewMsg .. GetFormatText("\n" .. g_tStrings.MSG_SURE_QO_ON)
        UIHelper.ShowConfirm(ParseTextHelper.ParseNormalText(msg), fnAction, nil, true)
        return
    end

    --物品上没有任何附魔时
    local szMsg = FormatString(g_tStrings.MSG_ON_USE_ITEM4, UIHelper.GBKToUTF8(item.szName),
            UIHelper.GBKToUTF8(itemTarget.szName), GetPureEnchantDesc(dwEnchantID))
    UIHelper.ShowConfirm(szMsg, fnAction, nil, true)
    return
end

function ItemData.GetItemCanEquipPos(nBox, nIndex)
    local player = PlayerData.GetClientPlayer()
    if not player then
        return tbItemList
    end

    return player.GetEquipPos(nBox, nIndex)
end

function ItemData.GetItemCDProgressByPos(nBox, nIndex)
    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

    return player.GetItemCDProgress(nBox, nIndex)
end

function ItemData.GetItemCDProgress(dwItemID)
    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

    return player.GetItemCDProgress(dwItemID)
end

function ItemData.GetItemCDProgressByTab(dwTabType, dwIndex)
    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

    if not dwTabType and not dwIndex then
        return
    end

    return player.GetItemCDProgress(0, dwTabType, dwIndex)
end

function ItemData.GetEquipTypeName(item)
    if item.nGenre == ITEM_GENRE.EQUIPMENT then
        return g_tStrings.tEquipTypeNameTable[item.nSub]
    elseif item.nGenre == ITEM_GENRE.POTION then
        return g_tStrings.POISON_TYPE[item.nSub]
    elseif item.nGenre == ITEM_GENRE.TASK_ITEM then
        return g_tStrings.STR_ITEM_H_QUEST_ITEM
    elseif item.nGenre == ITEM_GENRE.MATERIAL then
        return g_tStrings.CRAFT_ITEM
    elseif item.nGenre == ITEM_GENRE.DESIGNATION then
        return g_tStrings.DESGNATION_ITEM
    elseif item.nGenre == ITEM_GENRE.BOX then
        return g_tStrings.ITEM_TREASURE_BOX_KEY
    elseif item.nGenre == ITEM_GENRE.BOX_KEY then
        return g_tStrings.ITEM_TREASURE_BOX_KEY
    elseif item.nGenre == ITEM_GENRE.DIAMOND then
        return g_tStrings.STR_DIAMOND
    elseif item.nGenre == ITEM_GENRE.COLOR_DIAMOND then
        return g_tStrings.STR_COLOR_DIAMOND
    end
end

function ItemData.GetEquipItemEquiped(player, nEqSubType, nDetailType)
    local player = player or PlayerData.GetClientPlayer()

    local nBox = INVENTORY_INDEX.EQUIP
    local nPos = -1
    if nEqSubType == EQUIPMENT_SUB.MELEE_WEAPON then
        nPos = EQUIPMENT_INVENTORY.MELEE_WEAPON
        if nDetailType == WEAPON_DETAIL.BIG_SWORD then
            nPos = EQUIPMENT_INVENTORY.BIG_SWORD
        end
    elseif nEqSubType == EQUIPMENT_SUB.RANGE_WEAPON then
        nPos = EQUIPMENT_INVENTORY.RANGE_WEAPON
    elseif nEqSubType == EQUIPMENT_SUB.ARROW then
        nPos = EQUIPMENT_INVENTORY.ARROW
    elseif nEqSubType == EQUIPMENT_SUB.CHEST then
        nPos = EQUIPMENT_INVENTORY.CHEST
    elseif nEqSubType == EQUIPMENT_SUB.HELM then
        nPos = EQUIPMENT_INVENTORY.HELM
    elseif nEqSubType == EQUIPMENT_SUB.AMULET then
        nPos = EQUIPMENT_INVENTORY.AMULET
    elseif nEqSubType == EQUIPMENT_SUB.RING then
        local leftItem = ItemData.GetItemByPos(nBox, EQUIPMENT_INVENTORY.LEFT_RING)
        local rightItem = ItemData.GetItemByPos(nBox, EQUIPMENT_INVENTORY.RIGHT_RING)
        local leftLevel = leftItem and leftItem.nLevel or 0
        local rightLevel = rightItem and rightItem.nLevel or 0

        nPos = leftLevel > rightLevel and EQUIPMENT_INVENTORY.RIGHT_RING or EQUIPMENT_INVENTORY.LEFT_RING
    elseif nEqSubType == EQUIPMENT_SUB.WAIST then
        nPos = EQUIPMENT_INVENTORY.WAIST
    elseif nEqSubType == EQUIPMENT_SUB.PENDANT then
        nPos = EQUIPMENT_INVENTORY.PENDANT
    elseif nEqSubType == EQUIPMENT_SUB.PANTS then
        nPos = EQUIPMENT_INVENTORY.PANTS
    elseif nEqSubType == EQUIPMENT_SUB.BOOTS then
        nPos = EQUIPMENT_INVENTORY.BOOTS
    elseif nEqSubType == EQUIPMENT_SUB.BANGLE then
        nPos = EQUIPMENT_INVENTORY.BANGLE
        -- elseif nEqSubType == EQUIPMENT_SUB.WAIST_EXTEND then
        -- 	nPos = EQUIPMENT_INVENTORY.WAIST_EXTEND
        -- elseif nEqSubType == EQUIPMENT_SUB.BACK_EXTEND then
        -- 	nPos = EQUIPMENT_INVENTORY.BACK_EXTEND
        -- elseif nEqSubType == EQUIPMENT_SUB.FACE_EXTEND then
        -- 	nPos = EQUIPMENT_SUB.FACE_EXTEND
    elseif nEqSubType == EQUIPMENT_SUB.HORSE then
        nBox, nPos = player.GetEquippedHorsePos()
    end

    return nBox, nPos
end

function ItemData.GetMoney()
    local player = PlayerData.GetClientPlayer()
    if not player then
        return { nBullion = 0, nGold = 0, nSilver = 0, nCopper = 0 }
    end

    local tbMoney = player.GetMoney()
    if tbMoney then
        tbMoney.nBullion = math.floor(tbMoney.nGold / 10000)
        tbMoney.nGold = tbMoney.nGold % 10000
    end

    return tbMoney
end

function ItemData.GetOriginalMoney()
    local player = PlayerData.GetClientPlayer()
    if not player then
        return { nGold = 0, nSilver = 0, nCopper = 0 }
    end
    local tbMoney = player.GetMoney()
    return tbMoney
end

function ItemData.GetCoin()
    local player = PlayerData.GetClientPlayer()
    if not player then
        return 0
    end

    return player.nCoin
end

function ItemData.GetStrengthQualityLevel(nStrengthQuality, nStrengthLevel)
    return tonumber(("%.0f"):format(nStrengthQuality * nStrengthLevel * (0.007 + nStrengthLevel * 0.003) / 2))
end

local function ParseSource(szSource)
    local tSource = {}
    local tTemp = SplitString(szSource, ";")
    for _, v in ipairs(tTemp) do
        local t = SplitString(v, "-")
        local dwParam1 = tonumber(t[1] or "")
        local dwParam2 = tonumber(t[2] or "")
        table.insert(tSource, { dwParam1, dwParam2 })
    end
    return tSource
end

function ItemData.GetAllBookInfo()
    if not ItemData.tBooks then
        ItemData.tBooks = {}

        for i = 2, g_tTable.BookSegment:GetRowCount() do
            local row = g_tTable.BookSegment:GetRow(i)
            if row then
                local dwRecipeID = BookID2GlobelRecipeID(row.dwBookID, row.dwSegmentID)

                local tSourceMap = SplitString(row.szSourceMap, ";")
                local tAchievement = SplitString(row.szAchievement, ";")
                local tDoodad = ParseSource(row.szSourceDoodad)
                local tNpc = ParseSource(row.szSourceNpc)
                local tBoss = ParseSource(row.szSourceBoss)
                local tQuests = SplitString(row.szSourceQuest, ";")

                ItemData.tBooks[dwRecipeID] = {
                    tQuests = tQuests,
                    tSourceNpc = tNpc,
                    tSourceMap = tSourceMap,
                    tDoodad = tDoodad,
                    tBoss = tBoss,
                    tAchievement = tAchievement,
                    bSourceTrade = row.bSourceTrade,
                }
                ItemData.tBooks[UIHelper.GBKToUTF8(row.szSegmentName)] = ItemData.tBooks[dwRecipeID]
            end
        end
    end

    return ItemData.tBooks
end

function ItemData.GetItemNameByItem(item)
    if item.nGenre == ITEM_GENRE.BOOK then
        local nBookID, nSegID = GlobelRecipeID2BookID(item.nBookID)
        return Table_GetSegmentName(nBookID, nSegID) or g_tStrings.BOOK
    else
        return Table_GetItemName(item.nUiId)
    end
end

function ItemData.GetItemNameByItemInfo(itemInfo, nBookInfo)
    if not itemInfo then
        return ""
    end

    if itemInfo.nGenre == ITEM_GENRE.BOOK then
        if nBookInfo and nBookInfo ~= -1 then
            local nBookID, nSegID = GlobelRecipeID2BookID(nBookInfo)
            return Table_GetSegmentName(nBookID, nSegID) or g_tStrings.BOOK
        else
            return Table_GetItemName(itemInfo.nUiId)
        end
    else
        return Table_GetItemName(itemInfo.nUiId)
    end
end

function ItemData.GetItemNameByItemInfoIndex(nTabType, nIndex)
	local hItemInfo = GetItemInfo(nTabType, nIndex)
	if not hItemInfo then
		return
	end
	return ItemData.GetItemNameByItemInfo(hItemInfo)
end

function ItemData.GetToyCollectTip(dwItemIndex)
    local szTip = ""
    local hPlayer = GetClientPlayer()
    if not hPlayer or not hPlayer.RemoteDataAutodownFinish() then
        return szTip
    end

    local tToy = Table_GetToyBoxByItem(dwItemIndex)
    if not tToy then
        return szTip
    end

    -- szTip = GetFormatText("\t")

    local nStatus = GET_STATUS.NOT_COLLECTED

    if GDAPI_IsToyHave(hPlayer, tToy.dwID, tToy.nCountDataIndex) then
        nStatus = GET_STATUS.COLLECTED
    end
    szTip = g_tStrings.tCoinshopGet[nStatus]
    return szTip
end

function ItemData.GetPetCollectTip(dwItemIndex)
    local szTip = ""
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return szTip
    end

    local nPetIndex = GetFellowPetIndexByItemIndex(ITEM_TABLE_TYPE.CUST_TRINKET, dwItemIndex)
    local bHave = hPlayer.IsFellowPetAcquired(nPetIndex)
    local nStatus = GET_STATUS.NOT_COLLECTED
    if bHave then
        nStatus = GET_STATUS.COLLECTED
    end
    szTip = g_tStrings.tCoinshopGet[nStatus]
    return szTip
end

function ItemData.GetPendantPetCollectTip(dwItemIndex)
    local szTip = ""
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return szTip
    end

    local bExit = hPlayer.IsHavePendentPet(dwItemIndex)
    local nStatus = GET_STATUS.NOT_COLLECTED
    if bExit then
        nStatus = GET_STATUS.COLLECTED
    end
    szTip = g_tStrings.tCoinshopGet[nStatus]
    return szTip
end

function ItemData.GetPendantOwnInfo(item, bItem)
    local player = GetClientPlayer()
    local szTips = ""
    if not item or not player then
        return szTips
    end
    local bOwn = player.IsPendentOwn(bItem and item.dwIndex or item)
    szTips = bOwn and "已收集" or "未收集"
    return szTips
end

function ItemData.IsItemCollected(dwTabType, dwIndex, nBookInfo)
    local bCollected = false
    local item = ItemData.GetItemInfo(dwTabType, dwIndex)
    if ItemData.IsPendantItem(item) then
        --挂件
        bCollected = g_pClientPlayer.IsPendentOwn(dwIndex)
    elseif item.nGenre == ITEM_GENRE.EQUIPMENT and ItemData.IsPendantPetItem(item) then
        -- 挂宠
        bCollected = g_pClientPlayer.IsHavePendentPet(dwIndex)
    elseif item.nGenre == ITEM_GENRE.TOY then
        -- 玩具
        local tToy = Table_GetToyBoxByItem(dwIndex)
        if tToy then
            bCollected = GDAPI_IsToyHave(g_pClientPlayer, tToy.dwID, tToy.nCountDataIndex)
        end
    elseif item.nGenre == ITEM_GENRE.EQUIPMENT and item.nSub == EQUIPMENT_SUB.PET then
        -- 宠物
        local nPetIndex = GetFellowPetIndexByItemIndex(ITEM_TABLE_TYPE.CUST_TRINKET, dwIndex)
        bCollected      = g_pClientPlayer.IsFellowPetAcquired(nPetIndex)
    elseif item.nGenre == ITEM_GENRE.HOMELAND then
        --家具
        bCollected = HomelandEventHandler.IsFurnitureCollected(item.dwFurnitureID)
    elseif item.nGenre == ITEM_GENRE.BOOK then
        --书籍
        local nBookID, nSegmentID = GlobelRecipeID2BookID(nBookInfo)
        bCollected = g_pClientPlayer.IsBookMemorized(nBookID, nSegmentID)
    elseif item.nSub == EQUIPMENT_SUB.HORSE_EQUIP then
        -- 马具
        local tList = g_pClientPlayer.GetAllHorseEquip()
        for _, tItem in ipairs(tList) do
            if tItem.dwItemIndex == dwIndex then
                bCollected = true
                break
            end
        end
    end

    return bCollected
end

local function IsQiquHorseHave(dwItemIndex)
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end

	local tQiqu = GetRareHorseInfoList()
	if not tQiqu then
		return
	end

	local bHave   = false
	local bIsQiqu = false
	for k, v in pairs(tQiqu) do
		if v.dwItemTabIndex == dwItemIndex then
			if GetPlayerItem(hPlayer, v.dwBox, v.dwX) then
				bHave = true
			end
			bIsQiqu = true
			break
		end
	end
	return bIsQiqu, bHave
end

function ItemData.GetGeneralItemCollectState(dwTabType, dwIndex, nBookCount, nPendentID)
	-- nBookCount是判书籍用的
	-- nPendentID是nPendentID和dwIndex不一样的物品需要传的，或者自己脚本里处理
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end
	local bCollect = false
	local ItemInfo = GetItemInfo(dwTabType, dwIndex)
	if not ItemInfo then
		return
	end
    if dwTabType and dwIndex and ItemInfo.nGenre ~= ITEM_GENRE.BOOK then  -- （放所有包里的）道具、 坐骑, 所有书籍共用一个dwIndex                     -- （放所有包里的）道具、 坐骑
        local nAllBag = hPlayer.GetItemAmountInAllPackages(dwTabType, dwIndex)
        if nAllBag and nAllBag ~= 0 then
            bCollect = true
        end
    end

	if ItemInfo.nGenre == ITEM_GENRE.EQUIPMENT then
		if IsPendantItem(ItemInfo) then
			local nPendentID = dwIndex
			if hPlayer.IsPendentExist(nPendentID) then            -- 正常挂件
				bCollect = true
			end
		elseif ItemInfo.nSub == EQUIPMENT_SUB.PET then            -- 宠物
			local nPetIndex = GetFellowPetIndexByItemIndex(ITEM_TABLE_TYPE.CUST_TRINKET, dwIndex)
			if hPlayer.IsFellowPetAcquired(nPetIndex) then
				bCollect = true
			end
		elseif IsPendantPetItem(ItemInfo) then                    -- 挂宠
			if hPlayer.IsHavePendentPet(dwIndex) then
				bCollect = true
			end
		elseif ItemInfo.nSub == EQUIPMENT_SUB.MINI_AVATAR then    -- 头像
			local dwAvatarID = ItemInfo.nRepresentID
			if hPlayer.GetMiniAvatarMgr().IsMiniAvatarAcquired(dwAvatarID) then
				bCollect = true
			end
		elseif ItemInfo.nSub == EQUIPMENT_SUB.HORSE_EQUIP then   -- 马具
			local tList = hPlayer.GetAllHorseEquip()
			for _, tItem in ipairs(tList) do
				if tItem.dwItemIndex == dwIndex then
					bCollect = true
					break
				end
			end
		end
	elseif nPendentID and nPendentID ~= 0 then                   -- nPendentID与dwIndex不一致时的挂件
		if hPlayer.IsPendentExist(nPendentID) then
			bCollect = true
		end
	elseif ItemInfo.nGenre == ITEM_GENRE.TOY then                 -- 玩具
		if not hPlayer.RemoteDataAutodownFinish() then
            return
        end
        local tToy = Table_GetToyBoxByItem(dwIndex)
        if not tToy then
            return
        end
        if GDAPI_IsToyHave(hPlayer, tToy.dwID, tToy.nCountDataIndex) then
            bCollect = true
        end
	elseif ItemInfo.nGenre == ITEM_GENRE.HOMELAND and dwTabType == ITEM_TABLE_TYPE.HOMELAND then        --家具
        local nFurnitureType = ItemInfo.nFurnitureType or HS_FURNITURE_TYPE.FURNITURE
		local dwFurnitureID = ItemInfo.dwFurnitureID
        if nFurnitureType == HS_FURNITURE_TYPE.FURNITURE and HomelandEventHandler.IsFurnitureCollected(dwFurnitureID) then
            bCollect = true
        end
    elseif ItemInfo.nGenre == ITEM_GENRE.BOOK then            --书籍
        local dwRecipeID = nBookCount
        local nBookID, nSegmentID = GlobelRecipeID2BookID(dwRecipeID)
        if hPlayer.IsBookMemorized(nBookID, nSegmentID) then
			bCollect = true
        end
	elseif ItemInfo.nGenre == ITEM_GENRE.DESIGNATION then     -- 称号
		if ItemInfo.nPrefix and ItemInfo.nPrefix ~= 0 then    --前缀、世界
			if hPlayer.IsDesignationPrefixAcquired(ItemInfo.nPrefix) then
				bCollect = true
			end
		end
		if ItemInfo.nPostfix and ItemInfo.nPostfix ~= 0 then  -- 后缀
			if hPlayer.IsDesignationPostfixAcquired(ItemInfo.nPostfix) then
				bCollect = true
			end
		end
	end

	-- elseif ItemInfo.nGenre == ITEM_GENRE.COIN_SHOP_QUANTITY_LIMIT_ITEM then  -- 外观（？
	-- 	local dwExteriorID = CoinShop_GetExteriorIDByItemInfo(ItemInfo)
	-- 	if hPlayer.IsHaveExterior(dwExteriorID) or CheckNPCIsHaveExterior(hPlayer, ItemInfo, dwExteriorID) then
	-- 		bCollect = true
	-- 	end

	return bCollect
end

function ItemData.GetBindInfo(item, bItem, szSource)
    if not item then
        return
    end

    local szTips = g_tStrings.STR_ITEM_H_NOT_BIND
    if not szSource then
        if bItem and item.bBind then
            szTips = g_tStrings.STR_ITEM_H_HAS_BEEN_BIND
        else
            local itemInfo = bItem and ItemData.GetItemInfo(item.dwTabType, item.dwIndex) or item
            if item.nAucGenre == AUC_GENRE.CAN_NOT_AUC then
                szTips = g_tStrings.STR_ITEM_H_CAN_TRADE_CAN_NOT_AUC
            end
            if itemInfo.nGenre == ITEM_GENRE.DESIGNATION then
                szTips = g_tStrings.DESGNATION_ITEM
            end
            if itemInfo.nGenre == ITEM_GENRE.TASK_ITEM then
                szTips = g_tStrings.STR_ITEM_H_QUEST_ITEM
            elseif itemInfo.nBindType == ITEM_BIND.INVALID then
            elseif itemInfo.nBindType == ITEM_BIND.NEVER_BIND then
            elseif itemInfo.nBindType == ITEM_BIND.BIND_ON_EQUIPPED then
                szTips = g_tStrings.STR_ITEM_H_BIND_AFTER_EQUIP
            elseif itemInfo.nBindType == ITEM_BIND.BIND_ON_PICKED then
                szTips = g_tStrings.STR_ITEM_H_BIND_AFTER_PICK
            elseif itemInfo.nBindType == ITEM_BIND.BIND_ON_TIME_LIMITATION then
                szTips = g_tStrings.STR_ITEM_H_BIND_TIME_LIMITATION1
            end
        end
    else
        if szSource == "shop" then
            szTips = ""
            if item.nBindType == ITEM_BIND.BIND_ON_PICKED then
                szTips = g_tStrings.STR_ITEM_H_BIND_AFTER_BUY
            end
        else
            szTips = g_tStrings.STR_ITEM_H_BIND_AFTER_PICK
        end
    end

    return szTips
end

function ItemData.GetItemTypeInfoDesc(item, bItem)
    if not item then
        return ""
    end

    if item.nGenre == ITEM_GENRE.HOMELAND then
        local nFurnitureType, dwFurnitureID = FurnitureData.GetTypeAndIDWithItem(item, bItem)
        local tFurnitureConfig = FurnitureData.GetFurnitureConfig(nFurnitureType, dwFurnitureID)
        local tUIInfo = FurnitureData.GetFurnInfoByTypeAndID(nFurnitureType, dwFurnitureID)
        local tCatg1UIInfo = FurnitureData.GetCatg1Info(tUIInfo.nCatg1Index)
        local tCatg2UIInfo = FurnitureData.GetCatg2Info(tUIInfo.nCatg1Index, tUIInfo.nCatg2Index)

        return string.format("%s-%s-%s", UIHelper.UTF8ToGBK(g_tStrings.STR_FURNITURE_TIP_NAME), tCatg1UIInfo.szName,
                tCatg2UIInfo.szName)
    else
        local szType = ItemData.GetItemTypeInfo(item, bItem)
        return UIHelper.UTF8ToGBK(szType)
    end
end

function ItemData.GetItemTypeInfo(item, bItem, szSource, nItemBookID)
    local szType1, szType2, szType3 = "", "", ""
    if item.nGenre == ITEM_GENRE.EQUIPMENT then
        szType1 = g_tStrings.tEquipTypeNameTable[item.nSub]
        if item.nSub == EQUIPMENT_SUB.MELEE_WEAPON or
                item.nSub == EQUIPMENT_SUB.RANGE_WEAPON or
                item.nSub == EQUIPMENT_SUB.ARROW then
            szType2 = g_tStrings.WeapenDetail[item.nDetail]
        elseif item.nSub == EQUIPMENT_SUB.AMULET or
                item.nSub == EQUIPMENT_SUB.RING then
            --饰品
        elseif item.nSub == EQUIPMENT_SUB.PENDANT then
            --挂件
        elseif item.nSub == EQUIPMENT_SUB.PACKAGE then
            --包裹
        elseif item.nSub == EQUIPMENT_SUB.BULLET then
            szType2 = g_tStrings.BulletDetailName[item.nDetail]
        else
            --防具
        end
    elseif item.nGenre == ITEM_GENRE.BOOK then
        local nBookID, nSegmentID = GlobelRecipeID2BookID(bItem and item.nBookID or nItemBookID)
        local nSort = Table_GetBookSort(nBookID, nSegmentID)
        local szSortName = g_tStrings.STR_CRAFT_READ_BOOK_SORT_NAME_TABLE[nSort]
        szType1 = "书籍"
        szType2 = szSortName
    elseif item.nGenre == ITEM_GENRE.POTION then
        szType1 = g_tStrings.PoisonTypeName[item.nSub] or "药品"
    elseif item.nGenre == ITEM_GENRE.FOOD then
        szType1 = g_tStrings.FoodTypeName[item.nSub] or "食品"
    elseif item.nGenre == ITEM_GENRE.TASK_ITEM then
        szType1 = "任务物品"
    elseif item.nGenre == ITEM_GENRE.BOX then
        szType1 = "宝箱"
    elseif item.nGenre == ITEM_GENRE.BOX_KEY then
        szType1 = "宝箱钥匙"
    elseif item.nGenre == ITEM_GENRE.MATERIAL then
        szType1 = "材料"
        if item.nSub == ITEM_SUBTYPE_RECIPE then
            szType2 = "秘笈"
        elseif item.nSub == ITEM_SUBTYPE_SKILL_RECIPE then
            szType2 = "秘笈"
        end
    elseif item.nGenre == ITEM_GENRE.DESIGNATION then
        szType1 = "称号"
    elseif item.nGenre == ITEM_GENRE.TOY then
        szType1 = "玩具"
    elseif item.nGenre == ITEM_GENRE.ENCHANT_ITEM then
        szType1 = "附魔道具"
    elseif item.nGenre == ITEM_GENRE.MOUNT_ITEM then
        szType1 = "镶嵌道具"
    elseif item.nGenre == ITEM_GENRE.COLOR_DIAMOND then
        szType1 = "五彩石"
    elseif item.nGenre == ITEM_GENRE.DIAMOND then
        szType1 = "五行石"
    end

    szType3 = ItemData.GetBindInfo(item, bItem, szSource) or ""
    return szType1, szType2, szType3
end

function ItemData.IsCanTimeReturnItem(item)
    if not item then
        return false
    end

    local player = GetClientPlayer()
    local nLeftTime = player.GetTimeLimitReturnItemLeftTime(item.dwID)
    return (nLeftTime > 0)
end

function ItemData.GetReturnItemLeftTime(item)
    if not item then
        return 0
    end

    local player = GetClientPlayer()
    local nLeftTime = player.GetTimeLimitReturnItemLeftTime(item.dwID)
    return nLeftTime
end

function ItemData.IsPriceNeedRemind(nNpcID, nShopID, nIndex, nCount)
    local tPrice = GetShopItemBuyPrice(nShopID, nIndex) or {nGold=0, nSilver=0, nCopper=0}
    local tTotalPrice =  MoneyOptMult(tPrice, nCount)
    local REMIND_GOLD = 10000
	if tTotalPrice.nGold >= REMIND_GOLD then
		return true
	end

    return false
end

function ItemData.IsDelayTradeItem(dwItemID)
    return IsDelayTradeItem(dwItemID)
end

------物品来源

function ItemData.GetItemSourceList(dwTabType, dwIndex)
    if not dwTabType or not dwIndex then
		return
	end

    local szTabName = "ItemSourceList_" .. dwTabType
    if not IsUITableRegister(szTabName) then
		RegisterUITable(szTabName, g_tItemSourceList.Path .. dwTabType .. ".txt", g_tItemSourceList.Title)
	end

    return Table_GetItemSourceList(szTabName, dwTabType, dwIndex)
end

function ItemData.SortSource(tSource)
    local dwCurrentMapID = UI_GetCurrentMapID()
    local tResult = {}
    for k, v in ipairs(tSource) do
        local dwMapID
        if type(v) == "table" then
            dwMapID = tonumber(v[1])
        else
            dwMapID = tonumber(v)
        end
        local nSort = 1
        if dwMapID == dwCurrentMapID then
            nSort = 2
        end
        table.insert(tResult, { nIndex = k, nSort = nSort, Value = v })
    end
    local fnSort = function(a, b)
        if a.nSort == b.nSort then
            return a.nIndex < b.nIndex
        end

        return a.nSort > b.nSort
    end
    table.sort(tResult, fnSort)

    return tResult
end

function ItemData.GetSourceNpcTip(tSourceNpc, szTitle, tbInfo, nMapLimitCount)
    if #tSourceNpc <= 0 then
        return
    end
    nMapLimitCount = nMapLimitCount or MAP_LIMIT_COUNT
    local tResult = ItemData.SortSource(tSourceNpc)

    for k, v in ipairs(tResult) do
        if k > nMapLimitCount then
            break
        end
        local Value = v.Value
        local dwMapID = Value[1]
        local dwTemplateID = Value[2]
        local szMapName = UIHelper.GBKToUTF8(Table_GetMapName(dwMapID))
        local szNpcName = UIHelper.GBKToUTF8(Table_GetNpcTemplateName(dwTemplateID))
        local szLinkInfo = string.format("CraftMarkNpc/%d/%d", dwMapID, dwTemplateID)
        local szText = UIHelper.AttachTextColor(szTitle, FontColorID.ValueChange_Yellow)
        szText = szText .. string.format("<color=#95FF95> [%s] (%s)</c>", szNpcName, szMapName)
        table.insert(tbInfo[1], { szText = szText, szLinkInfo = szLinkInfo })
    end
end

function ItemData.GetSourceAuctionTip(tbInfo, nTabType, nIndex)
    local szText = UIHelper.AttachTextColor(g_tStrings.ITEM_TIP_SOURCE_TRADE, FontColorID.ValueChange_Yellow)
    local szLinkInfo = string.format("auctionlink/%d/%d", nTabType, nIndex)
    table.insert(tbInfo[1], { szText = szText, szLinkInfo = szLinkInfo })
end

function ItemData.GetSourceTradeTip(bSourceTrade, tbInfo, dwItemType, dwItemIndex)
    if not bSourceTrade then
        return
    end

    local szText = UIHelper.AttachTextColor(g_tStrings.ITEM_TIP_SOURCE_TRADE, FontColorID.ValueChange_Yellow)
    local szLinkInfo = string.format("SourceTrade/%d/%d", dwItemType, dwItemIndex)
    table.insert(tbInfo[1], { szText = szText, szLinkInfo = szLinkInfo })
end

function ItemData.GetBookSourceTradeTip(bSourceTrade, tbInfo, dwRecipeID)
    if not bSourceTrade then
        return
    end

    if not dwRecipeID then
        return
    end

    local nBookID, nSegmentID = GlobelRecipeID2BookID(dwRecipeID)

    local szText = UIHelper.AttachTextColor(g_tStrings.ITEM_TIP_SOURCE_TRADE, FontColorID.ValueChange_Yellow)

    local szLinkInfo = string.format("SourceTradeWithName/%s", UIHelper.GBKToUTF8(Table_GetSegmentName(nBookID, nSegmentID)))
    table.insert(tbInfo[1], { szText = szText, szLinkInfo = szLinkInfo })
end

function ItemData.GetSourceQuestTip(tQuests, tbInfo, player, nMapLimitCount)
    -- 任务
    if #tQuests <= 0 then
        return
    end

    nMapLimitCount = nMapLimitCount or MAP_LIMIT_COUNT

    for k, v in ipairs(tQuests) do
        if k > nMapLimitCount then
            break
        end
        local szAdd = player.GetQuestPhase(v) == 3 and g_tStrings.STR_BOOK_TIP_FINISHED or ""
        -- local nR, nG, nB = GetQuestTipIconAndFont(v, player)
        local szText = "<color=#FFFAA3>" .. g_tStrings.STR_QUEST .. "</color>"
        szText = szText .. string.format("<href=%s><color=#95FF95>[%s]%s</c></href>", v, UIHelper.GBKToUTF8(Table_GetQuestStringInfo(v).szName), szAdd)
        local szLinkInfo = string.format("QuestTip/%s/1", v)
        table.insert(tbInfo[1], { szText = szText, szLinkInfo = szLinkInfo })
    end
end

function ItemData.GetSourceBossTip(tBoss, tbInfo, nMapLimitCount)
    if #tBoss <= 0 then
        return
    end
    nMapLimitCount = nMapLimitCount or MAP_LIMIT_COUNT

    local tResult = ItemData.SortSource(tBoss)
    for k, v in ipairs(tResult) do
        if k > nMapLimitCount then
            break
        end
        local Value = v.Value
        local dwMapID = Value[1]
        local dwBossIndex = Value[2]
        local tBossInfo = Table_GetDungeonBossByBossIndex(dwBossIndex)
        local szMapName = UIHelper.GBKToUTF8(Table_GetMapName(dwMapID))
        local szBossName = UIHelper.GBKToUTF8(tBossInfo.szName)
        --local szText = "<color=#FFFAA3>" .. g_tStrings.STR_BOOK_TIP_BOSS .. "</color>"
        local szText = UIHelper.AttachTextColor("秘境", FontColorID.ValueChange_Yellow)
        szText = string.format("%s<color=#95FF95> [%s] (%s)</c>", szText, szBossName, szMapName)
        local szLinkInfo = string.format("FBlist/%d/%d", dwMapID, dwBossIndex)
        table.insert(tbInfo[1], { szText = szText, szLinkInfo = szLinkInfo })
    end
end

function ItemData.GetSourceProduceTip(tProduce, tbInfo, nMapLimitCount)
    if #tProduce <= 0 then
        return
    end

    nMapLimitCount = nMapLimitCount or MAP_LIMIT_COUNT

    local dwCraftID = tProduce.dwCraftID
    local szName = Table_GetCraftName(dwCraftID)

    for k, dwRecipeID in ipairs(tProduce) do
        if k > nMapLimitCount then
            break
        end
        local szRecipeName = Table_GetRecipeName(dwCraftID, dwRecipeID)
        local szText = "<color=#FFFAA3>" .. szName .. "</color>"
        szText = szText .. string.format("<color=#95FF95> [%s]</c>", szRecipeName)
        local szLinkInfo = string.format("Craft/%d/%d", dwCraftID, dwRecipeID)
        table.insert(tbInfo[1], { szText = szText, szLinkInfo = szLinkInfo })
    end
end

function ItemData.GetSourceFromItemTip(tItemSouce, tbInfo, nMapLimitCount)
    if #tItemSouce <= 0 then
        return
    end

    nMapLimitCount = nMapLimitCount or MAP_LIMIT_COUNT

    for k, v in ipairs(tItemSouce) do
        if k > nMapLimitCount then
            break
        end
        local nTabType = v[1]
        local nIndex = v[2]
        local itemInfo = GetItemInfo(nTabType, nIndex)
        if itemInfo then
            local szLabel = "<color=#FFFAA3>" .. "物品" .. "</color>"
            local szItemName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(itemInfo))
            local r, g, b = GetItemFontColorByQuality(itemInfo.nQuality)
            szItemName = GetFormatText(string.format(" [%s]", szItemName), nil, r, g, b)
            szLabel = szLabel .. szItemName
            -- local szText = MakeItemInfoLink("["..szItemName.."]\n", "font=164 ".. szColor, 0, nTabType, nIndex)
            -- table.insert(xml, szText)
            local szLinkInfo = string.format("ShowItemInfo/%d/%d", nTabType, nIndex)
            table.insert(tbInfo[1], { szText = szLabel, szLinkInfo = szLinkInfo })

        end
    end
end

function ItemData.GetItemSourceCoinShop(tItemSouce, tbInfo, nMapLimitCount)
    if #tItemSouce <= 0 then
        return
    end

    nMapLimitCount = nMapLimitCount or MAP_LIMIT_COUNT

    for k, v in ipairs(tItemSouce) do
        if k > nMapLimitCount then
            break
        end
        local dwLogicID = v
        local szName = g_tStrings.STR_TIP_SOURCE_TITLE_COINSHOP
        local szLevelText = UIHelper.AttachTextColor(szName, FontColorID.ValueChange_Yellow)
        local szLinkInfo = string.format("Exterior/%d/%d", HOME_TYPE.REWARDS, dwLogicID)
        table.insert(tbInfo[1], { szText = szLevelText, szLinkInfo = szLinkInfo })
    end
end

function ItemData.GetItemSourceReputation(tItemSouce, tbInfo, nMapLimitCount)
    if #tItemSouce <= 0 then
        return
    end

    nMapLimitCount = nMapLimitCount or MAP_LIMIT_COUNT

    for k, v in ipairs(tItemSouce) do
        if k > nMapLimitCount then
            break
        end
        local dwReputationID = v
        local tInfo = Table_GetReputationForceInfo(dwReputationID)
        local szName = UIHelper.GBKToUTF8(tInfo.szName)
        local szLevelText = string.format("%s<color=#95FF95> [%s]</color>",
                UIHelper.AttachTextColor("声望", FontColorID.ValueChange_Yellow), szName)
        local szLinkInfo = string.format("Reputation/%d", dwReputationID)
        table.insert(tbInfo[1], { szText = szLevelText, szLinkInfo = szLinkInfo })
    end
end

function ItemData.GetItemSourceAchievement(tItemSouce, tbInfo, nMapLimitCount)
    if #tItemSouce <= 0 then
        return
    end

    nMapLimitCount = nMapLimitCount or MAP_LIMIT_COUNT

    for k, v in ipairs(tItemSouce) do
        if k > nMapLimitCount then
            break
        end
        local dwAchievement = v
        local szName = UIHelper.GBKToUTF8(Table_GetAchievementName(dwAchievement))
        local szLevelText = string.format("<color=#FFFAA3>成就</color><color=#95FF95> [%s]</color>", szName)
        local szLinkInfo = string.format("Achievement/%d", dwAchievement)
        table.insert(tbInfo[1], { szText = szLevelText, szLinkInfo = szLinkInfo })
    end
end

function ItemData.GetItemSourceAdventure(tItemSouce, tbInfo, nMapLimitCount)
    if #tItemSouce <= 0 then
        return
    end

    nMapLimitCount = nMapLimitCount or MAP_LIMIT_COUNT

    for k, v in ipairs(tItemSouce) do
        if k > nMapLimitCount then
            break
        end
        local szAdvID = v
        local szName = UIHelper.GBKToUTF8(Table_GetAdventureName(szAdvID))
        local szLevelText = string.format("<color=#FFFAA3>奇遇</color><color=#95FF95>[%s]</color>", szName)
        local szLinkInfo = string.format("LuckyMeeting/%d", szAdvID)
        table.insert(tbInfo[1], { szText = szLevelText, szLinkInfo = szLinkInfo })
    end
end

function ItemData.GetSourceCollectD(tSourceCollectD, tbInfo, nMapLimitCount)
    if #tSourceCollectD <= 0 then
        return
    end

    nMapLimitCount = nMapLimitCount or MAP_LIMIT_COUNT

    local szName = Table_GetCraftName(tSourceCollectD.dwCraftID)

    for k, v in ipairs(tSourceCollectD) do
        local dwTemplateID = v
        local tMapList = ItemData.GetGuideDoodadMa(dwTemplateID)

        local tResult = ItemData.SortSource(tMapList)
        for k1, v1 in ipairs(tResult) do
            if k1 > nMapLimitCount then
                break
            end
            local dwMapID = v1.Value
            local szMapName = UIHelper.GBKToUTF8(Table_GetMapName(dwMapID))
            local szText = "<color=#FFFAA3>" .. szName .. "</color>"
            szText = szText .. string.format("<color=#95FF95> [%s]</c>", szMapName)
            local szLinkInfo = string.format("CraftMarkCollectD/%d/%d", dwMapID, dwTemplateID)
            table.insert(tbInfo[1], { szText = szText, szLinkInfo = szLinkInfo })
        end
    end
end

function ItemData.GetSourceCollectN(tSourceCollectN, tbInfo, nMapLimitCount)
    if #tSourceCollectN <= 0 then
        return
    end

    nMapLimitCount = nMapLimitCount or MAP_LIMIT_COUNT

    local szName = Table_GetCraftName(tSourceCollectN.dwCraftID)

    local tResult = ItemData.SortSource(tSourceCollectN)
    for k, v in ipairs(tResult) do
        if k > nMapLimitCount then
            break
        end
        local Value = v.Value
        local dwMapID = Value[1]
        local dwTemplateID = Value[2]
        local szNpcName = UIHelper.GBKToUTF8(Table_GetNpcTemplateName(dwTemplateID))
        local szMapName = UIHelper.GBKToUTF8(Table_GetMapName(dwMapID))
        local szText = "<color=#FFFAA3>" .. szName .. "</color>"
        szText = szText .. string.format("<color=#95FF95> [%s] (%s)</c>", szNpcName, szMapName)
        local szLinkInfo = string.format("CraftMarkCollectN/%d/%d", dwMapID, dwTemplateID)
        table.insert(tbInfo[1], { szText = szText, szLinkInfo = szLinkInfo })
    end
end

function ItemData.GetItemSourceActivity(tSource, tbInfo, nMapLimitCount)
    if #tSource <= 0 then
        return
    end

    nMapLimitCount = nMapLimitCount or MAP_LIMIT_COUNT

    for k, v in ipairs(tSource) do
        if k > nMapLimitCount then
            break
        end
        local dwActivityID = v
        local szName = UIHelper.GBKToUTF8(Table_GetCalenderActivityName(dwActivityID))
        local szText = "<color=#FFFAA3>" .. g_tStrings.CYCLOPAEDIA_ACTIVE .. "</color>"
        szText = szText .. string.format("<color=#95FF95> [%s]</c>", szName)
        local szLinkInfo = string.format("LinkActivity/%d", dwActivityID)
        table.insert(tbInfo[1], { szText = szText, szLinkInfo = szLinkInfo })
    end
end

function ItemData.GetItemSourceShop(tSource, tbInfo, dwItemType, dwItemIndex, nNeedCount)
    if not tSource or not tSource[1] then
        return
    end
    for _, tChildSource in ipairs(tSource) do
        local Value = tChildSource
        local t = SplitString(Value, "-")

        local dwGroupID = tonumber(t[1])
        local dwShopTemplateID = tonumber(t[2])
        if dwGroupID and dwShopTemplateID then
            local tShop = Table_GetSystemShopByID(dwGroupID, dwShopTemplateID)
            if tShop then
                local szShopName = UIHelper.GBKToUTF8(tShop.szShopName)
                local szLabel = UIHelper.AttachTextColor(g_tStrings.STR_BOOK_TIP_SHOP_NPC, FontColorID.ValueChange_Yellow)
                local szText = g_tStrings.STR_BOOK_TIP_SHOP_NPC_UI
                if szShopName then
                    szText = szLabel .. string.format(" [%s] (%s)", szText, szShopName)
                end
                szText = UIHelper.AttachTextColor(szText, "#95FF95")

                local szLinkInfo = string.format("SourceShop/%d/%d/%d/%d", dwGroupID, dwShopTemplateID, dwItemType, dwItemIndex)
                if nNeedCount then
                    szLinkInfo = szLinkInfo .. string.format("/%d", nNeedCount)
                end

                table.insert(tbInfo[1], { szText = szText, szLinkInfo = szLinkInfo })
            end
        end
    end
end

function ItemData.GetSourceDoodadTip(tDoodad, tbInfo, nMapLimitCount)
    -- 碑铭
    if #tDoodad <= 0 then
        return
    end

    nMapLimitCount = nMapLimitCount or MAP_LIMIT_COUNT
    local tResult = ItemData.SortSource(tDoodad)
    for k, v in ipairs(tResult) do
        if k > nMapLimitCount then
            break
        end
        local Value = v.Value
        local dwMapID = Value[1]
        local dwTemplateID = Value[2]
        local szMapName = UIHelper.GBKToUTF8(Table_GetMapName(dwMapID))
        local szDoodadName = UIHelper.GBKToUTF8(Table_GetDoodadName(dwTemplateID, 0))
        local szText = "<color=#FFFAA3>" .. g_tStrings.STR_BOOK_TIP_INSCRIPTIONS .. "</color>"
        szText = szText .. string.format("<color=#95FF95> [%s] (%s)</c>", szDoodadName, szMapName)
        local szLinkInfo = string.format("CraftMarkDoodad/%s/%s", dwMapID, dwTemplateID)
        table.insert(tbInfo[1], { szText = szText, szLinkInfo = szLinkInfo })
    end
end

function ItemData.GetSourceMapTip(tSourceMap, tbInfo, nMapLimitCount)
    --推荐地图
    if #tSourceMap <= 0 then
        return
    end

    nMapLimitCount = nMapLimitCount or MAP_LIMIT_COUNT
    local tResult = ItemData.SortSource(tSourceMap)
    for k, v in ipairs(tResult) do
        if k > nMapLimitCount then
            break
        end
        local Value = v.Value

        local dwMapID = Value
        local szMapName = UIHelper.GBKToUTF8(Table_GetMapName(dwMapID))
        local szText = "<color=#FFFAA3>" .. g_tStrings.STR_BOOK_TIP_MAP .. "</color>"
        szText = szText .. string.format("<color=#95FF95> [%s]</c>", szMapName)
        local szLinkInfo = string.format("MiddleMap/%s/0", dwMapID)
        table.insert(tbInfo[1], { szText = szText, szLinkInfo = szLinkInfo })
    end
end

function ItemData.GetSourceShopNpcTip(tSourceNpc, tbInfo, nMapLimitCount)
    return ItemData.GetSourceNpcTip(tSourceNpc, "NPC" .. g_tStrings.STR_BOOK_TIP_SHOP_NPC, tbInfo, nMapLimitCount)
end

function ItemData.GetSourceOpenPanelTip(tFunction, tEventLink, tbInfo, nMapLimitCount)
    if #tFunction <= 0 and #tEventLink <= 0 then
		return
	end

	nMapLimitCount = nMapLimitCount or MAP_LIMIT_COUNT
    for k, v in ipairs(tFunction) do
        local t = SplitString(v, ";")
		local szName = t[1]
		local szFunction = t[2]

        if szFunction ~= "" then
			local szFunc, szArg = string.match(szFunction, "(%w+)/(.*)")
			local szSeparatedFunction = szFunc or szFunction
			if szArg and szArg ~= "" then
				szArg = ", " .. szArg
			else
				szArg = ""
			end
            local szLinkInfo = string.format("CollectionFunc/%s", szSeparatedFunction)
            if szFunc == "PanelLink" or szFunc == "GameGuidePanel" then
                szLinkInfo = szFunction -- 走EVENT_LINK_NOTIFY
            end
            
            local szText = "<color=#FFFAA3>" .. g_tStrings.ITEM_TIP_SOURCE_GUIDE .. "</color>"
            szText = szText .. string.format("<color=#95FF95> [%s]</c>", UIHelper.GBKToUTF8(szName))
            table.insert(tbInfo[1], { szText = szText, szLinkInfo = szLinkInfo })
		end
    end

    for k, v in pairs(tEventLink) do
		local t = SplitString(v, ";")
		local szName = t[1]
		local szLink = t[2]
		if szLink ~= "" then
			local szLinkInfo = string.format("%s", szLink)
            local szText = "<color=#FFFAA3>" .. g_tStrings.ITEM_TIP_SOURCE_GUIDE .. "</color>"
            szText = szText .. string.format("<color=#95FF95> [%s]</c>", UIHelper.GBKToUTF8(szName))
            table.insert(tbInfo[1], { szText = szText, szLinkInfo = szLinkInfo })
		end
	end
end

function ItemData.GetSourceTradeNpcTip(tSourceNpc, tbInfo, nMapLimitCount)
    return ItemData.GetSourceNpcTip(tSourceNpc, g_tStrings.ITEM_TIP_SOURCE_TRADE, tbInfo, nMapLimitCount)
end

function ItemData.GetCurrencySourceShop(tSource)
    if not tSource then
        return
    end

    local tRes = {}
    for _, tChildSource in ipairs(tSource) do
        local dwGroupID = tChildSource.dwGroupID
        local dwShopTemplateID = tChildSource.dwDefault
        --local szShopName = tChildSource.szShopName
        if dwGroupID and dwShopTemplateID then
            local tShop = Table_GetSystemShopByID(dwGroupID, dwShopTemplateID)
            if tShop then
                local szShopName = UIHelper.GBKToUTF8(tShop.szShopName)
                local szLabel = UIHelper.AttachTextColor(g_tStrings.STR_BOOK_TIP_SHOP_NPC, FontColorID.ValueChange_Yellow)
                local szText = g_tStrings.STR_BOOK_TIP_SHOP_NPC_UI
                if szShopName then
                    szText = szLabel .. string.format(" [%s] (%s)", szText, szShopName)
                end
                szText = UIHelper.AttachTextColor(szText, "#95FF95")

                local szLinkInfo = string.format("SourceShop/%d/%d/0/0", dwGroupID, dwShopTemplateID)
                table.insert(tRes, { szText = szText, szLinkInfo = szLinkInfo })
            end
        end
    end
    return tRes
end

-----------------------------------------------------------------------------------------
-------------------------------------挂件相关---------------------------------------------
-----------------------------------------------------------------------------------------

function ItemData.IsPendantSub(nSub)
    if ItemData.GetPendantTypeByEquipSub(nSub) then
        return true
    end

    return false
end

function ItemData.IsPendantItem(item)
    return ItemData.IsPendantSub(item.nSub)
end

function ItemData.IsPendantPetSub(nSub)
    if nSub == EQUIPMENT_SUB.PENDENT_PET then
        return true
    end

    return false
end

function ItemData.UsePendantItem(dwBox, dwX)
    if PropsSort.IsBagInSort() then
        TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
        return
    end

    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

    if player.bFightState then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.CANNOT_CHANGE_PENDENT_IN_FIGHT)
        return
    end

    if player.nMoveState == MOVE_STATE.ON_DEATH then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_ERROR_CANNOT_EQUIP_PENDANT_WHEN_DIE)
        return
    end

    local item = PlayerData.GetPlayerItem(player, dwBox, dwX)
    if not item or item.nGenre ~= ITEM_GENRE.EQUIPMENT then
        return
    end

    if not ItemData.IsPendantItem(item) then
        return
    end

    local nRetCode = player.CheckEquipRequire(dwBox, dwX)
    if nRetCode == ITEM_RESULT_CODE.BANK_PASSWORD_EXIST and BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.BANK) then
        return
    elseif nRetCode ~= ITEM_RESULT_CODE.SUCCESS then
        Global.OnItemRespond(nRetCode)
        return
    end

    if player.IsPendentOwn(item.dwIndex) then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_ERROR_ALEADY_GOT_PENDANT)
        return
    end

    if not player.IsPendentTryOn(item.dwIndex) then
        local nPendantType = ItemData.GetPendantTypeByEquipSub(item.nSub)
        if nPendantType then
            local nCount = player.GetPendentCount(nPendantType) or 0
            if nCount >= player.GetPendentBoxSize(nPendantType) then
                local szType = ItemData.GetEquipTypeName(item)
                local szMsg = FormatString(g_tStrings.STR_ERROR_NOT_ENOUGH_PENDANT_SIZE, szType, szType)
                OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
                return
            end
        end
    end

    local nUiId = item.nUiId
    local szShowMessage = nil
    if item.nSub == EQUIPMENT_SUB.BACK_EXTEND or item.nSub == EQUIPMENT_SUB.WAIST_EXTEND or
            item.nSub == EQUIPMENT_SUB.FACE_EXTEND or item.nSub == EQUIPMENT_SUB.GLASSES_EXTEND then
        szShowMessage = g_tStrings.STR_MSG_EQUIP_BIND_PENDANT_SURE
    elseif item.nSub == EQUIPMENT_SUB.L_GLOVE_EXTEND or item.nSub == EQUIPMENT_SUB.R_GLOVE_EXTEND then
        szShowMessage = g_tStrings.STR_MSG_EQUIP_BIND_LAND_PENDANT_SURE
    else
        szShowMessage = g_tStrings.STR_MSG_EQUIP_BIND_CLOTHING_PENDANT_SURE
    end

    -- local szItemName = string.format("<color=%s>%s</c>", ItemQualityColor[item.nQuality + 1], UIHelper.GBKToUTF8(item.szName))
    local szConfirmContain = string.format(szShowMessage, UIHelper.GBKToUTF8(item.szName))
    UIHelper.ShowConfirm(szConfirmContain, function()
        RemoteCallToServer("OnUsePendentItem", dwBox, dwX)
    end)
end

function ItemData.UsePendantPetItem(dwBox, dwX)
    if PropsSort.IsBagInSort() then
        TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
        return
    end

    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

    if player.bFightState then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.CANNOT_CHANGE_PENDENT_IN_FIGHT)
        return
    end

    if player.nMoveState == MOVE_STATE.ON_DEATH then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_ERROR_CANNOT_EQUIP_PENDANT_WHEN_DIE)
        return
    end

    local item = PlayerData.GetPlayerItem(player, dwBox, dwX)
    if not item or item.nGenre ~= ITEM_GENRE.EQUIPMENT then
        return
    end

    if not ItemData.IsPendantPetItem(item) then
        return
    end

    local nRetCode = player.CheckEquipRequire(dwBox, dwX)
    if nRetCode == ITEM_RESULT_CODE.BANK_PASSWORD_EXIST and BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.BANK) then
        return
    elseif nRetCode ~= ITEM_RESULT_CODE.SUCCESS then
        Global.OnItemRespond(nRetCode)
        return
    end

    if player.IsHavePendentPet and player.IsHavePendentPet(item.dwIndex) then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_ERROR_ALEADY_GOT_PENDANT_PET)
        return
    end

    if item.nSub == EQUIPMENT_SUB.PENDENT_PET then
        local nCount = player.GetPendentPetCount() or 0
        if nCount >= player.GetPendentPetBoxSize() then
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_ERROR_NOT_ENOUGH_PENDANT_PET_SIZE)
            return
        end
    end

    local nUiId = item.nUiId
    local szShowMessage = g_tStrings.STR_MSG_EQUIP_BIND_PENDANT_PET_SURE
    local szName = ItemData.GetItemNameByItem(item)

    local szConfirmContain = string.format(szShowMessage, UIHelper.GBKToUTF8(szName))
    UIHelper.ShowConfirm(szConfirmContain, function()
        RemoteCallToServer("On_PendentPetItem_Use", dwBox, dwX)
        -- PlayItemSound(nUiId)
    end)
end

function ItemData.IsPendantPetItem(item)
    return ItemData.IsPendantPetSub(item.nSub)
end

function ItemData.IsPendantPetItemByIndex(dwTabType, nIndex)
    local hItemInfo = GetItemInfo(dwTabType, nIndex)
    return ItemData.IsPendantPetItem(hItemInfo)
end

function ItemData.GetPendantColor(dwTabType, nIndex)
    local hItemInfo = GetItemInfo(dwTabType, nIndex)
    local player = GetClientPlayer()
    if not player then
        return
    end
    local nType = ItemData.GetPendantTypeByEquipSub(hItemInfo.nSub)
    local tColorID = player.GetSelectedPendentColor(nType)
    return tColorID
end

local _tEquipToPendantType = {
    [EQUIPMENT_SUB.FACE_EXTEND] = KPENDENT_TYPE.FACE,
    [EQUIPMENT_SUB.BACK_EXTEND] = KPENDENT_TYPE.BACK,
    [EQUIPMENT_SUB.WAIST_EXTEND] = KPENDENT_TYPE.WAIST,
    [EQUIPMENT_SUB.BACK_CLOAK_EXTEND] = KPENDENT_TYPE.BACKCLOAK,
    [EQUIPMENT_SUB.L_SHOULDER_EXTEND] = KPENDENT_TYPE.LSHOULDER,
    [EQUIPMENT_SUB.R_SHOULDER_EXTEND] = KPENDENT_TYPE.RSHOULDER,
    [EQUIPMENT_SUB.BAG_EXTEND] = KPENDENT_TYPE.BAG,
    [EQUIPMENT_SUB.GLASSES_EXTEND] = KPENDENT_TYPE.GLASSES,
    [EQUIPMENT_SUB.L_GLOVE_EXTEND] = KPENDENT_TYPE.LGLOVE,
    [EQUIPMENT_SUB.R_GLOVE_EXTEND] = KPENDENT_TYPE.RGLOVE,
    [EQUIPMENT_SUB.HEAD_EXTEND] = KPENDENT_TYPE.HEAD,
}

function ItemData.GetPendantTypeByEquipSub(nSubType)
    return _tEquipToPendantType[nSubType]
end

function ItemData.GetEquipSubByPendantType(nPendantType)
    for nSub, nType in pairs(_tEquipToPendantType) do
        if nPendantType == nType then
            return nSub
        end
    end
end

function ItemData.GoldSilverAndCopperFromMoney(nMoney)
    local nBrics = math.floor(nMoney / 100000000)
    nMoney = nMoney - nBrics * 100000000
    local nGold = math.floor(nMoney / 10000)
    nMoney = nMoney - nGold * 10000
    local nSilver = math.floor(nMoney / 100)
    local nCopper = nMoney - nSilver * 100

    return nBrics, nGold, nSilver, nCopper
end

function ItemData.GoldSilverAndCopperFromtMoney(tMoney)
    local nBrics = math.floor(tMoney.nGold / 10000)
    local nGold = tMoney.nGold % 10000

    local nSilver = tMoney.nSilver
    local nCopper = tMoney.nCopper

    return nBrics, nGold, nSilver, nCopper
end

function ItemData.MoneyFromGoldSilverAndCopper(nBullion, nGold, nSilver, nCopper)
    local nMoney = nBullion * 100000000 + nGold * 10000 + nSilver * 100 + nCopper

    return nMoney
end

function GetGuildBankPagePos(dwBox, dwX)
    return math.floor(dwX / INVENTORY_GUILD_PAGE_SIZE), dwX % INVENTORY_GUILD_PAGE_SIZE
end

function ItemData.GetPlayerItem(player, dwBox, dwX, szPackageType, dwASPSource)
    if not player or not dwBox or not dwX then
        return
    end

    if szPackageType == UI_BOX_TYPE.SHAREPACKAGE then
        dwASPSource = dwASPSource or ACCOUNT_SHARED_PACKAGE_SOURCE.CURRENT
        return player.GetItemInAccountSharedPackage(dwASPSource, dwBox, dwX)
    elseif dwBox == INVENTORY_GUILD_BANK then
        return GetTongClient().GetRepertoryItem(GetGuildBankPagePos(dwBox, dwX))
    else
        return player.GetItem(dwBox, dwX)
    end
end

function ItemData.FormatAttributeValue(v)
    if v.nID == ATTRIBUTE_TYPE.DAMAGE_TO_LIFE_FOR_SELF or v.nID == ATTRIBUTE_TYPE.DAMAGE_TO_MANA_FOR_SELF then
        if v.nValue1 then
            v.nValue1 = KeepTwoByteFloat(v.nValue1 * 100 / 1024)
            v.nValue2 = KeepTwoByteFloat(v.nValue2 * 100 / 1024)
        end
        if v.Param0 then
            v.Param0 = KeepTwoByteFloat(v.Param0 * 100 / 1024)
            v.Param1 = KeepTwoByteFloat(v.Param1 * 100 / 1024)
            v.Param2 = KeepTwoByteFloat(v.Param2 * 100 / 1024)
            v.Param3 = KeepTwoByteFloat(v.Param3 * 100 / 1024)
        end

    end
end

--尝试将物品堆叠至其他槽位
function ItemData.StackItem(dwBox, dwX)
    if dwBox and dwX then
        local player = g_pClientPlayer
        local toStackItem = ItemData.GetItemByPos(dwBox, dwX)
        if toStackItem then
            local nStack = ItemData.GetItemStackNum(toStackItem)
            for _, nBox in ipairs(ItemData.BoxSet.Bag) do
                for index = 0, player.GetBoxSize(nBox) - 1 do
                    local hItem = player.GetItem(nBox, index)
                    if hItem and hItem.dwIndex == toStackItem.dwIndex and
                            ItemData.GetItemMaxStackNum(hItem) >= ItemData.GetItemStackNum(hItem) + nStack then
                        ItemData.ExchangeItemByNum(dwBox, dwX, nBox, index, nStack)
                        return
                    end
                end
            end
        end
    end

end

function ItemData.GetUseItemTargetItemList(dwBox, dwX)
    local hSrcItem = ItemData.GetItemByPos(dwBox, dwX)
    if not hSrcItem then
        return
    end

    local iterUseItem = Table_GetUseItemTargetItemListIter(hSrcItem.dwTabType, hSrcItem.dwIndex) or {}
    local tbTargetCfg = {}
    local bLevelImproveItem = false
    for tbCfg in iterUseItem do
        local dwTab = tbCfg.nTargetItemTab
        local dwIndex = tbCfg.nTargetItemIndex
        if dwTab > 0 and dwIndex > 0 then
            if tbCfg.bLevelImproveItem and not bLevelImproveItem then
                bLevelImproveItem = tbCfg.bLevelImproveItem --提品道具标记
            end
            tbTargetCfg[dwTab] = tbTargetCfg[dwTab] or {}
            tbTargetCfg[dwTab][dwIndex] = true
        else
            LOG.ERROR("Table_GetUseItemTargetItemListIter failed to decode dwTab:%s, dwIndex:%s", tostring(dwTab), tostring(dwIndex))
        end
    end

    local bShowAllTaskItem = false
    if table.GetCount(tbTargetCfg) == 0 and hSrcItem.nGenre == ITEM_GENRE.TASK_ITEM then
        -- 任务道具的使用目标如果没有配置，就显示所有任务道具
        bShowAllTaskItem = true
    end

    local tbTargetItemList = {}
    if hSrcItem.nGenre == ITEM_GENRE.TASK_ITEM then -- 任务物品会直接获取所有可使用的道具
        for dwTabType, tbItemIndex in pairs(tbTargetCfg) do
            for dwIndex, _ in pairs(tbItemIndex) do
                local nBox, nX = ItemData.GetItemPos(dwTabType, dwIndex)
                local tbItemInfo = ItemData.GetItemInfo(dwTabType, dwIndex)
                if tbItemInfo then
                    table.insert(tbTargetItemList, {nBox = nBox, nIndex = nX, hItem = tbItemInfo,
                                    dwTabType = dwTabType, dwIndex = dwIndex})
                end
            end
        end
    else
        for _, tbItemInfo in ipairs(ItemData.GetItemList(ItemData.BoxSet.Bag)) do
            if tbItemInfo.hItem then
                if tbItemInfo.hItem.nGenre == ITEM_GENRE.TASK_ITEM and bShowAllTaskItem then
                    table.insert(tbTargetItemList, tbItemInfo)
                elseif tbTargetCfg[tbItemInfo.hItem.dwTabType] and tbTargetCfg[tbItemInfo.hItem.dwTabType][tbItemInfo.hItem.dwIndex] then
                    table.insert(tbTargetItemList, tbItemInfo)
                end
            end
        end

        if bLevelImproveItem then
            local tEquipType = {
                INVENTORY_INDEX.EQUIP,
                INVENTORY_INDEX.EQUIP_BACKUP1,
                INVENTORY_INDEX.EQUIP_BACKUP2,
                INVENTORY_INDEX.EQUIP_BACKUP3,
            }

            local tEquipIndex = {
                -- 头部
                EQUIPMENT_INVENTORY.HELM,
                -- 上衣
                EQUIPMENT_INVENTORY.CHEST,
                -- 腰带
                EQUIPMENT_INVENTORY.WAIST,
                -- 下装
                EQUIPMENT_INVENTORY.PANTS,
                -- 鞋子
                EQUIPMENT_INVENTORY.BOOTS,
                -- 护腕
                EQUIPMENT_INVENTORY.BANGLE,
                -- 项链
                EQUIPMENT_INVENTORY.AMULET,
                -- 腰坠
                EQUIPMENT_INVENTORY.PENDANT,
                -- 戒指
                EQUIPMENT_INVENTORY.LEFT_RING,
                -- 戒指
                EQUIPMENT_INVENTORY.RIGHT_RING,
                -- 普通近战武器
                EQUIPMENT_INVENTORY.MELEE_WEAPON,
                -- 重剑
                EQUIPMENT_INVENTORY.BIG_SWORD,
                -- 远程武器
                EQUIPMENT_INVENTORY.RANGE_WEAPON,
                -- 暗器
                EQUIPMENT_INVENTORY.ARROW,
            }

            -- for _, nBox in ipairs(tEquipType) do
            -- 备用三套暂不显示
                local nBox = INVENTORY_INDEX.EQUIP
                for _, nIndex in ipairs(tEquipIndex) do
                    local itemEquip = ItemData.GetPlayerItem(g_pClientPlayer, nBox, nIndex)
                    if itemEquip then
                        local dwEquipType = itemEquip.dwTabType
                        local dwEquipIndex = itemEquip.dwIndex
                        if dwEquipType and dwEquipIndex and tbTargetCfg[dwEquipType] and tbTargetCfg[dwEquipType][dwEquipIndex] then
                            table.insert(tbTargetItemList, {nBox = nBox, nIndex = nIndex})
                        end
                    end
                end
            -- end
        end
    end

    return tbTargetItemList, bLevelImproveItem
end

function ItemData.CanUseMibaoPackage()
    if not g_pClientPlayer then
        return false
    end
    return g_pClientPlayer.CanUseMibaoPackage()
end

local function GetQuickUseEmptyPos(tbItemTypeList, nIndex)
    local nPos = not tbItemTypeList[nIndex] and nIndex or nil
    if not nIndex then
        for i = 1, Storage.QuickUse.nMaxSlotCount, 1 do
            local tbItemInfo = tbItemTypeList[i]
            if not tbItemInfo then
                nPos = i
                break
            end
        end
    end

    return nPos
end

function ItemData.AddToyQuickUseList(dwID, nIndex)
    if ItemData.IsToyInQuickUseList(dwID) then
        return
    end
    local tbItemTypeList = TravellingBagData.IsInTravelingMap() and Storage.QuickUse.tbItemTypeListInLKX or Storage.QuickUse.tbItemTypeList
    if table.get_len(tbItemTypeList) >= Storage.QuickUse.nMaxSlotCount then
        return
    end

    local nPos = GetQuickUseEmptyPos(tbItemTypeList, nIndex)

    if nPos then
        tbItemTypeList[nPos] = { dwID = dwID, bToy = true }
        Storage.QuickUse.Dirty()

        Event.Dispatch(EventType.OnQuickUseListChanged, false, nPos)
    end
end

function ItemData.AddQuickUseList(dwTabType, dwIndex, bHeadPos, nIndex)
    if ItemData.IsInQuickUseList(dwTabType, dwIndex) then
        return
    end
    local tbItemTypeList = TravellingBagData.IsInTravelingMap() and Storage.QuickUse.tbItemTypeListInLKX or Storage.QuickUse.tbItemTypeList
    if not bHeadPos and table.get_len(tbItemTypeList) >= Storage.QuickUse.nMaxSlotCount then
        return
    end

    local nPos = GetQuickUseEmptyPos(tbItemTypeList, nIndex)

    if nPos then
        tbItemTypeList[nPos] = { dwTabType = dwTabType, dwIndex = dwIndex }
        Storage.QuickUse.Dirty()

        Event.Dispatch(EventType.OnQuickUseListChanged, false, nPos)
    end

    --table.insert(tbItemTypeList, bHeadPos and 1 or (#tbItemTypeList + 1), { dwTabType = dwTabType, dwIndex = dwIndex })
    --while #tbItemTypeList > Storage.QuickUse.nMaxSlotCount do
    --    table.remove(tbItemTypeList, #tbItemTypeList)
    --end
--
    --Storage.QuickUse.Dirty()
--
    --Event.Dispatch(EventType.OnQuickUseListChanged)
end

function ItemData.RemoveQuickUseList(dwTabType, dwIndex)
    local tbItemTypeList = TravellingBagData.IsInTravelingMap() and Storage.QuickUse.tbItemTypeListInLKX or Storage.QuickUse.tbItemTypeList
    local _, resIdx = table.find_if(tbItemTypeList, function(v)
        return v.dwTabType == dwTabType and v.dwIndex == dwIndex
    end)

    if resIdx then
        --table.remove(tbItemTypeList, resIdx)
        tbItemTypeList[resIdx] = nil
        Storage.QuickUse.Dirty()

        Event.Dispatch(EventType.OnQuickUseListChanged, true, resIdx)
    end

    ItemData.RemoveQuickUseSlotType(dwTabType, dwIndex)
end


function ItemData.RemoveQuickUseToyList(dwID)
    local tbItemTypeList = TravellingBagData.IsInTravelingMap() and Storage.QuickUse.tbItemTypeListInLKX or Storage.QuickUse.tbItemTypeList
    local _, resIdx = table.find_if(tbItemTypeList, function(v)
        return v.dwID == dwID
    end)

    if resIdx then
        tbItemTypeList[resIdx] = nil
        Storage.QuickUse.Dirty()

        Event.Dispatch(EventType.OnQuickUseListChanged, true, resIdx)
    end
end

function ItemData.IsInQuickUseList(dwTabType, dwIndex)
    local tbItemTypeList = TravellingBagData.IsInTravelingMap() and Storage.QuickUse.tbItemTypeListInLKX or Storage.QuickUse.tbItemTypeList
    return table.find_if(tbItemTypeList, function(v)
        return v.dwTabType == dwTabType and v.dwIndex == dwIndex
    end) ~= nil
end

function ItemData.IsToyInQuickUseList(dwID)
    local tbItemTypeList = TravellingBagData.IsInTravelingMap() and Storage.QuickUse.tbItemTypeListInLKX or Storage.QuickUse.tbItemTypeList
    return table.find_if(tbItemTypeList, function(v)
        return v.dwID == dwID
    end) ~= nil
end

function ItemData.GetItemAmount(dwTabType, dwIndex)
    if not g_pClientPlayer then
        return 0
    end

    return g_pClientPlayer.GetItemAmount(dwTabType, dwIndex)
end

function ItemData.GetItemCanUseAmount(dwTabType, dwIndex)
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return 0
	end

    local nCount = 0
    for _, tbBox in pairs(ItemData.BoxSet) do
        for _, dwBox in pairs(tbBox) do
            local dwSize = hPlayer.GetBoxSize(dwBox)
            if hPlayer.CheckBoxCanUse(dwBox) then
                for dwX = 0, dwSize - 1, 1 do
                    local tItem = GetPlayerItem(hPlayer, dwBox, dwX)
                    if tItem and tItem.dwTabType == dwTabType and tItem.dwIndex == dwIndex then
                        local nStackNum = 1
                        if tItem.bCanStack then
                            nStackNum = tItem.nStackNum
                        end
                        nCount = nCount + nStackNum
                    end
                end
            end
        end
    end
    return nCount
end

function ItemData.GetItemAmountInPackage(dwTabType, dwIndex)
    if not g_pClientPlayer then
        return 0
    end

    return g_pClientPlayer.GetItemAmountInPackage(dwTabType, dwIndex)
end

function ItemData.HasItemInBox(nBoxID, dwTabType, dwIndex)
    if not g_pClientPlayer then
        return 0
    end

    return g_pClientPlayer.HasItemInBox(nBoxID, dwTabType, dwIndex)
end

function ItemData.GetCanUseItemPos(dwTabType, dwIndex)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    for _, dwBox in ipairs(ItemData.OrderedBox) do
        local dwSize = hPlayer.GetBoxSize(dwBox)
        if hPlayer.CheckBoxCanUse(dwBox) then
            for dwX = 0, dwSize - 1, 1 do
                local tItem = GetPlayerItem(hPlayer, dwBox, dwX)
                if tItem and tItem.dwTabType == dwTabType and tItem.dwIndex == dwIndex then
                    return dwBox, dwX
                end
            end
        end
    end
end

function ItemData.QuickUseItem(dwTabType, dwIndex, tbParam)
    local dwBox, dwX = ItemData.GetCanUseItemPos(dwTabType, dwIndex)
    if dwBox and dwX then
        local useItem = ItemData.GetItemByPos(dwBox, dwX)
        local skill = useItem.dwSkillID ~= 0 and GetSkill(useItem.dwSkillID, useItem.dwSkillLevel) or nil
        if skill then
            local nMode = skill.nCastMode
            if nMode == SKILL_CAST_MODE.POINT_AREA or nMode == SKILL_CAST_MODE.POINT then
                return ItemData.UseItemToPoint(dwBox, dwX, nMode, tbParam.nX, tbParam.nY, tbParam.nZ)
            elseif nMode == SKILL_CAST_MODE.ITEM then
                local tbTargetItemList = ItemData.GetUseItemTargetItemList(dwBox, dwX) or {}
                if #tbTargetItemList == 0 then
                    TipsHelper.ShowNormalTip(g_tStrings.USE_ITEM_NO_TARGET_ITEM)
                    -- return USE_ITEM_RESULT_CODE.FAILED
                end
                UIMgr.Open(VIEW_ID.PanelUseItemToItem, dwBox, dwX, function(dwTargetBox, dwTargetX)
                    return ItemData.UseItemToItem(dwBox, dwX, dwTargetBox, dwTargetX)
                end)
                return USE_ITEM_RESULT_CODE.SUCCESS
            elseif nMode == SKILL_CAST_MODE.CASTER_SINGLE then
                ---参考 端游 function OnUseItem(dwBox, dwX, box) 958
                if useItem.nGenre ~= ITEM_GENRE.EQUIPMENT and
                        useItem.nGenre ~= ITEM_GENRE.TASK_ITEM and
                        BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP, "useitem")
                then
                    return
                end
                return ItemData.UseItem(dwBox, dwX)
            else
                return ItemData.UseItemWithMode(dwBox, dwX, nMode)
            end
        end

        ---参考 端游 function OnUseItem(dwBox, dwX, box) 985
        if useItem.nGenre ~= ITEM_GENRE.BOX and
                useItem.nGenre ~= ITEM_GENRE.EQUIPMENT and
                useItem.nGenre ~= ITEM_GENRE.TASK_ITEM and
                BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP, "useitem")
        then
            return
        end

        if ItemData.CanMultiUse(useItem) then
            ItemData.MultiUse(dwBox, dwX, 1)
            return USE_ITEM_RESULT_CODE.SUCCESS
        else
            return ItemData.UseItem(dwBox, dwX)
        end
    end

    return USE_ITEM_RESULT_CODE.ITEM_NOT_EXIST
end

function ItemData.CanMultiUse(item)
    local player = g_pClientPlayer
    if not item or not player then
        return false
    end
    local nItemCount = player.GetItemAmount(item.dwTabType, item.dwIndex)
    if nItemCount <= 1 then
        return false
    end
    return Table_GetItemCanMutiUse(item.nUiId)
end

function ItemData.MultiUse(dwBox, dwX, dwUseNum)
    if not dwBox or not dwX then
        return
    end
    UseMutiItem(dwBox, dwX, dwUseNum)
end

function ItemData.CanQuickUse(tbItemInfo)
    local item = tbItemInfo.hItem
    if not item then
        return false
    end

    if TravellingBagData.IsInTravelingMap() then
        return true
    end

    if tbItemInfo.nBox == INVENTORY_INDEX.EQUIP and item.nGenre == ITEM_GENRE.EQUIPMENT then
        if item.dwSkillID and item.dwSkillID ~= 0 then
            return true
        end
    end

    if (not item.dwSkillID or item.dwSkillID == 0) and not item.HasScript() then
        return false
    end

    -- 药品 或者 宴席 或者 指定寄卖主类的可使用材料
    local tbUseableAucGenreList_material = { [9] = {}, [10] = {}, [14] = {}, [20] = {2}, [22] = { 12 }, [13] = {7} } -- 寄卖主类是 消耗品、材料、帮会产物    寄卖主类外观（子类小玩意儿）
    local tbUseableAucGenreList_enchant = { [13] = {7} } -- 寄卖主类是 物品强化 子类是武器
    local nFoodExceptSub = 5 -- 除了材料
    local filterAucType = function(tbGenreList, item)
        return tbGenreList[item.nAucGenre] and #tbGenreList[item.nAucGenre] == 0 or table.contain_value(tbGenreList[item.nAucGenre], item.nAucSub)
    end

    if item.nGenre == ITEM_GENRE.POTION or
            item.nGenre == ITEM_GENRE.TASK_ITEM or
            (item.nGenre == ITEM_GENRE.FOOD and item.nSub ~= nFoodExceptSub) or
            (item.nGenre == ITEM_GENRE.MATERIAL and filterAucType(tbUseableAucGenreList_material, item)) or
            (item.nGenre == ITEM_GENRE.ENCHANT_ITEM and filterAucType(tbUseableAucGenreList_enchant, item)) then
        return true
    end

    return false
end

ItemData.QuickUseOperateType = {
    TrackQuest = 1,
    QuickUseTip = 2,
    RemoteOpenQuestItem = 3,
}
---comment
---@param dwTabType any
---@param dwIndex any
---@param itemType any
function ItemData.AddQuickUseSlotType(dwTabType, dwIndex, nOperateType)
    local tbSkillSlotTypeList = TravellingBagData.IsInTravelingMap() and Storage.QuickUse.tbSkillSlotTypeListInLKX or Storage.QuickUse.tbSkillSlotTypeList
    if BattleFieldData.IsInTreasureBattleFieldMap() then
        tbSkillSlotTypeList = Storage.QuickUse.tbSkillSlotTypeListInTreasureBF
    end
    local resV, resIdx = table.find_if(tbSkillSlotTypeList, function(v)
        return v.dwTabType == dwTabType and v.dwIndex == dwIndex
    end)

    if resIdx == 1 and resV.nOpType == nOperateType then
        return
    elseif resIdx then
        table.remove(tbSkillSlotTypeList, resIdx)
    end

    local _, opIdx = table.find_if(tbSkillSlotTypeList, function(v)
        return v.nOpType == nOperateType
    end)

    if opIdx then
        table.remove(tbSkillSlotTypeList, opIdx)
    end

    table.insert(tbSkillSlotTypeList, 1, { dwTabType = dwTabType, dwIndex = dwIndex, nOpType = nOperateType })
    Storage.QuickUse.Dirty()

    Event.Dispatch(EventType.OnSkillSlotQuickUseChange)
end

function ItemData.RemoveQuickUseSlotType(dwTabType, dwIndex)
    local tbSkillSlotTypeList = TravellingBagData.IsInTravelingMap() and Storage.QuickUse.tbSkillSlotTypeListInLKX or Storage.QuickUse.tbSkillSlotTypeList
    if BattleFieldData.IsInTreasureBattleFieldMap() then
        tbSkillSlotTypeList = Storage.QuickUse.tbSkillSlotTypeListInTreasureBF
    end
    local _, resIdx = table.find_if(tbSkillSlotTypeList, function(v)
        return v.dwTabType == dwTabType and v.dwIndex == dwIndex
    end)

    if resIdx then
        table.remove(tbSkillSlotTypeList, resIdx)
        Storage.QuickUse.Dirty()

        Event.Dispatch(EventType.OnSkillSlotQuickUseChange)
    end
end

function ItemData.RemoveQuickUseSlotTypeByOperateType(nOperateType)
    local tbSkillSlotTypeList = TravellingBagData.IsInTravelingMap() and Storage.QuickUse.tbSkillSlotTypeListInLKX or Storage.QuickUse.tbSkillSlotTypeList
    if BattleFieldData.IsInTreasureBattleFieldMap() then
        tbSkillSlotTypeList = Storage.QuickUse.tbSkillSlotTypeListInTreasureBF
    end
    local _, resIdx = table.find_if(tbSkillSlotTypeList, function(v)
        return v.nOpType == nOperateType
    end)

    if resIdx then
        table.remove(tbSkillSlotTypeList, resIdx)
        Storage.QuickUse.Dirty()

        Event.Dispatch(EventType.OnSkillSlotQuickUseChange)
    end
end

function ItemData.CanQuickUseOnSkillSlot(dwTabType, dwIndex, nOperateType)
    if not dwTabType or not dwIndex then
        return false
    end

    local tbItemInfo = ItemData.GetItemInfo(dwTabType, dwIndex)
    if not tbItemInfo or tbItemInfo.dwSkillID == 0 then
        return false
    end

    local skill = GetSkill(tbItemInfo.dwSkillID, tbItemInfo.dwSkillLevel)
    if not skill then
        return false
    end

    local nMode = skill.nCastMode
    if nOperateType == ItemData.QuickUseOperateType.QuickUseTip then
        if tbItemInfo.nGenre == ITEM_GENRE.EQUIPMENT then
            return true
        else
            return nMode ~= SKILL_CAST_MODE.CASTER_SINGLE or tbItemInfo.EQUIPMENT
        end
    elseif nOperateType == ItemData.QuickUseOperateType.TrackQuest then
        return nMode == SKILL_CAST_MODE.POINT_AREA or nMode == SKILL_CAST_MODE.POINT
    end
    return false
end

function ItemData.GetQuickUseSlotInfo()
    if ItemData.OpenQuestItem then
        --- moba玩法中不显示这种类型的快捷使用道具，比如 68236 雾海寻龙 满级装备包
        local bInMoba = BattleFieldData.IsInMobaBattleFieldMap()
        if not bInMoba then
            return ItemData.OpenQuestItem
        end
    end

    local tbSkillSlotTypeList = TravellingBagData.IsInTravelingMap() and Storage.QuickUse.tbSkillSlotTypeListInLKX or Storage.QuickUse.tbSkillSlotTypeList
    if BattleFieldData.IsInTreasureBattleFieldMap() then
        tbSkillSlotTypeList = Storage.QuickUse.tbSkillSlotTypeListInTreasureBF
    end
    return #tbSkillSlotTypeList > 0 and tbSkillSlotTypeList[1] or nil
end

function ItemData.IsEnchantItem(pItem)
    return pItem and pItem.dwTabType == ITEM_TABLE_TYPE.OTHER and CraftData.g_EnchantInfo[pItem.dwIndex]
end

function ItemData.ShowSharePackageRecodeTip(nCode)
    if nCode == ASP_RESULT_CODE.INVALID then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.ASP_INVALID)
        -- elseif nCode == ASP_RESULT_CODE.SUCCEED then
        -- 	OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.ASP_SUCCEED)
    elseif nCode == ASP_RESULT_CODE.FAILED then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.ASP_FAILED)
    elseif nCode == ASP_RESULT_CODE.TOO_FAR_AWAY then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.ASP_TOO_FAR_AWAY)
    elseif nCode == ASP_RESULT_CODE.ITEM_NOT_EXIST then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.ASP_ITEM_NOT_EXIST)
    elseif nCode == ASP_RESULT_CODE.TIME_LIMIT_ITEM_BE_DENIED then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.ASP_TIME_LIMIT_ITEM_BE_DENIED)
    elseif nCode == ASP_RESULT_CODE.CANNOT_PUT_TO_THAT_PLACE then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.ASP_CANNOT_PUT_TO_THAT_PLACE)
    elseif nCode == ASP_RESULT_CODE.NOT_ENOUGH_DURABILITY then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.ASP_NOT_ENOUGH_DURABILITY)
    elseif nCode == ASP_RESULT_CODE.PLAYER_IS_DEAD then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.ASP_PLAYER_IS_DEAD)
    elseif nCode == ASP_RESULT_CODE.NOT_ENOUGH_FREE_ROOM then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.ASP_NOT_ENOUGH_FREE_ROOM)
    elseif nCode == ASP_RESULT_CODE.CLOSED then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.ASP_CLOSE_SHAREPACKGE)
    end
end

--后两个参数可以不填，不填则是放置入第一个空位
function ItemData.TakeItemFromAccountSharedPackage(dwASPSource, dwASPBox, dwASPPos, dwDstBox, dwDstPos, nAmount)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.SHOP) then
        return
    end
    if not hPlayer.bAccountShared then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.ASP_NOT_BIND)  --权限检测
        return
    end
    local nRetCode = hPlayer.TakeItemFromAccountSharedPackage(-1, dwASPSource, dwASPBox, dwASPPos, dwDstBox, dwDstPos, nAmount)
    ItemData.ShowSharePackageRecodeTip(nRetCode, true)
    return nRetCode
end

--后两个参数可以不填，不填则是放置入第一个空位
local function fnSurePutItemToAccountSharedPackage(dwNpcID, dwSrcBox, dwSrcPos, dwASPBox, dwASPPos, nAmount)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.SHOP) then
        return
    end
    if not hPlayer.bAccountShared then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.ASP_NOT_BIND)  --权限检测
        return
    end
    local nRetCode = hPlayer.PutItemToAccountSharedPackage(dwNpcID, dwSrcBox, dwSrcPos, dwASPBox, dwASPPos, nAmount)
    ItemData.ShowSharePackageRecodeTip(nRetCode, false)
    return nRetCode
end

function ItemData.PutItemToAccountSharedPackage(dwSrcBox, dwSrcPos, dwASPBox, dwASPPos, nAmount)
    local item = GetClientPlayer().GetItem(dwSrcBox, dwSrcPos)
    if not item then
        return
    end

    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.SHOP) then
        return
    end

    if not hPlayer.bAccountShared then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.ASP_NOT_BIND)  --权限检测
        return
    end

    local nRetCode = hPlayer.PutItemToAccountSharedPackage(-1, dwSrcBox, dwSrcPos, dwASPBox, dwASPPos, nAmount)
    ItemData.ShowSharePackageRecodeTip(nRetCode, false)
    return nRetCode
end

function ItemData.RedirectForceToRenownView(szLinkArg)
    local dwRewardForceID = tonumber(szLinkArg)

    if not UIMgr.IsViewOpened(VIEW_ID.PanelRenownList, true) then
        local scriptView = UIMgr.Open(VIEW_ID.PanelRenownList)
        scriptView:RedirectForceView(dwRewardForceID)
    else
        UIMgr.CloseWithCallBack(VIEW_ID.PanelRenownList, function ()
            local scriptView = UIMgr.Open(VIEW_ID.PanelRenownList)
            scriptView:RedirectForceView(dwRewardForceID)
        end)
    end
end

function ItemData.RedirectForceToAchievement(szLinkArg)
    local dwAchievementID = tonumber(szLinkArg)
    local aAchievement = Table_GetAchievement(dwAchievementID)

    if not aAchievement then return end --没有该成就，传了错误的成就ID
    if not dwAchievementID then -- 没传成就ID，直接打开成就界面
        UIMgr.OpenSingle(false, VIEW_ID.PanelAchievementMian)
        return
    end

    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelAchievementContent)
    if not scriptView then
        UIMgr.Open(VIEW_ID.PanelAchievementContent, aAchievement.dwGeneral, aAchievement.dwSub, aAchievement.dwDetail, aAchievement.dwID, g_pClientPlayer.dwID)
    else
        scriptView:OnEnter(aAchievement.dwGeneral, aAchievement.dwSub, aAchievement.dwDetail, aAchievement.dwID, g_pClientPlayer.dwID)
    end
end

function ItemData.RedirectForceToDLCPanel(szLinkArg)
    local szDLCID, szShowRewards = szLinkArg:match("(%w+)/(%w+)")
    local nOpenDLC = tonumber(szDLCID)
    local nShowRewards = tonumber(szShowRewards)
    local bShowDetailReward = nShowRewards and nShowRewards == 1

    WulintongjianDate.SetCurDLCID(nOpenDLC)
    local scriptView = UIMgr.OpenSingle(false, VIEW_ID.PanelWuLinTongJian)
    if bShowDetailReward and scriptView then
        WulintongjianDate.UpdateDLCInfo(nOpenDLC)
        scriptView:OpenRewardView(nOpenDLC)
    end
end

function ItemData.RedirectForceToAdventure(szLinkArg)
	local dwAdvID = tonumber(szLinkArg)

    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelQiYu)
    if not scriptView then
        UIMgr.Open(VIEW_ID.PanelQiYu, nil, dwAdvID)
    else
        scriptView:OnEnter(nil, dwAdvID)
    end
end

function ItemData.GetMaxAddNumToBag(item)
    if item then
        local currentNum = ItemData.GetItemStackNum(item)
        local nMaxExistAmount = item.nMaxExistAmount
        if nMaxExistAmount > 0 then
            local nBagNum = 0
            local player = PlayerData.GetClientPlayer()

            for _, nBox in ipairs(ItemData.BoxSet.Bag) do
                for nIndex = 0, player.GetBoxSize(nBox) - 1 do
                    local hItem = player.GetItem(nBox, nIndex)
                    if hItem and (item and hItem.dwIndex == item.dwIndex) then
                        nBagNum = ItemData.GetItemStackNum(hItem) + nBagNum
                    end
                end
            end

            local res = math.min(nMaxExistAmount - nBagNum, currentNum)
            return res
        end
        return currentNum
    end
    return 0
end

function ItemData.GetGuideDoodadMa(dwTemplateID)
    local tMapList = {}
    local tInfo = Table_GetCraftDoodadInfo(dwTemplateID)
    if tInfo then
        for i = 1, 3 do
            local szKey = "dwMapID" .. i
            if tInfo[szKey] > 0 then
                table.insert(tMapList, tInfo[szKey])
            end
        end
    end
    return tMapList
end

function ItemData.GetItemPrefabPool()
    ItemData.ItemPrefabPool = ItemData.ItemPrefabPool or PrefabPool.New(PREFAB_ID.WidgetItem_100, 200)
    return ItemData.ItemPrefabPool
end

function ItemData.GetBagCellPrefabPool()
    ItemData.BagCellPrefabPool = ItemData.BagCellPrefabPool or PrefabPool.New(PREFAB_ID.WidgetBagBottom, 200)
    return ItemData.BagCellPrefabPool
end

function ItemData.SplitItem(nBox, nIndex, nPreGroupNum, nGroupCount)
    if PropsSort.IsBagInSort() then
        TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_SPLIT_ITEM_INSORT)
        return
    end

    local item = ItemData.GetItemByPos(nBox, nIndex)
    if not item then
        return
    end

    local tbPos = {}
    local tbLockPos = {}
    if nPreGroupNum * nGroupCount == ItemData.GetItemStackNum(item) then
        table.insert(tbPos, { nBox, nIndex })
    end

    local tbBag = ItemData.GetCurrentBag()
    for _, dwBox in ipairs(tbBag) do
        local dwSize = g_pClientPlayer.GetBoxSize(dwBox)
        if dwBox ~= INVENTORY_INDEX.PACKAGE_MIBAO or (dwBox == INVENTORY_INDEX.PACKAGE_MIBAO and g_pClientPlayer.CanUseMibaoPackage()) then
            for dwX = 0, dwSize - 1, 1 do
                if not ItemData.GetItemByPos(dwBox, dwX) then
                    if BagViewData.IsLockBox(dwBox, dwX) then
                        table.insert(tbLockPos, { dwBox, dwX })
                    else
                        table.insert(tbPos, { dwBox, dwX })
                    end
                end
            end
        end
    end

    local function DoSplit(tbPos)
        for _, v in ipairs(tbPos) do
            local dwTarBox, dwTarX = v[1], v[2]
            local nCanExchange = g_pClientPlayer.CanExchange(nBox, nIndex, dwTarBox, dwTarX)
            if nCanExchange == ITEM_RESULT_CODE.SUCCESS then
                g_pClientPlayer.ExchangeItem(nBox, nIndex, dwTarBox, dwTarX, nPreGroupNum)
                nGroupCount = nGroupCount - 1
                if nGroupCount == 0 then
                    return
                end
            end
        end
    end

    DoSplit(tbPos)
    if nGroupCount > 0 then
        DoSplit(tbLockPos)
    end

end

function ItemData.OnReload()
end

function ItemData.GetEnchantItemDesc(dwEnchantID)
	local szEnchant = ""
	if dwEnchantID > 0 then
		local dwTabType, dwIndex = EnchantData.GetItemWithEnchantID(dwEnchantID)
		if dwTabType and dwIndex then
			local tItemInfo = ItemData.GetItemInfo(dwTabType, dwIndex)
			if tItemInfo then
                local nDiamondR, nDiamondG, nDiamondB = GetItemFontColorByQuality(tItemInfo.nQuality)
                local itemName = ItemData.GetItemNameByItemInfo(tItemInfo)

                itemName = UIHelper.GBKToUTF8(itemName)
                local itemName = FormatString(g_tStrings.CYCLOPAEDIA_LINK_FORMAT, itemName)
                szEnchant = GetFormatText(itemName, nil, nDiamondR, nDiamondG, nDiamondB)
			end
		end
	end
	return szEnchant
end

function ItemData.GetItemEnchantDesc(item)
    local szEnchant = ""
    local dwTemporaryEnchantID = item.dwTemporaryEnchantID or 0
    local dwPermanentEnchantID = item.dwPermanentEnchantID or 0
    if dwTemporaryEnchantID > 0 or dwPermanentEnchantID > 0 then
        szEnchant = ItemData.GetEnchantItemDesc(dwTemporaryEnchantID)
        if dwPermanentEnchantID > 0 then
            if szEnchant ~= "" then
                szEnchant = szEnchant .. g_tStrings.STR_PAUSE
            end
            szEnchant = szEnchant ..ItemData.GetEnchantItemDesc(dwPermanentEnchantID)
        end
    end

    return szEnchant
end

function ItemData.SellOutItem(item, dwItemID, nSellCount)
    if PropsSort.IsBagInSort() then
        TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_TRADE_ITEM_INSORT)
        return
    end

    OpenShopRequest(1232, 0)
    local szSellPriceTip = "当前出售价格为：%s，"
    local szConfirmTip = "你确定要出售[%s]吗？"
    local nDiamondR, nDiamondG, nDiamondB = GetItemFontColorByQuality(item.nQuality)
    local nBox, nIndex = ItemData.GetItemPos(dwItemID)
    local itemName = ItemData.GetItemNameByItem(item)
    --local nStackNum = ItemData.GetItemStackNum(item)

    itemName = UIHelper.GBKToUTF8(itemName)
    itemName = GetFormatText(itemName, nil, nDiamondR, nDiamondG, nDiamondB)
    szConfirmTip = string.format(szConfirmTip, itemName)

    local nMaxCount = 1
    if item.bCanStack and item.nStackNum and item.nStackNum > 0 then
        nMaxCount = item.nStackNum
    end
    local nPrice = (GetShopItemSellPrice(1232, nBox, nIndex) / nMaxCount) * nSellCount
    local szMoneyText = UIHelper.GetMoneyText(nPrice)
    if nPrice == 0 then
        szMoneyText = string.format("%d<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Tong' width='%d' height='%d' />", 0, 26*1.5, 26*1.5)
    end

    local bLimitGold = BubbleMsgData.GetGoldLimitState()
    if bLimitGold then
        local nLimit = 0
        local szMoneyLimit = string.format("%d<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Tong' width='%d' height='%d' />", 0, 26*1.5, 26*1.5)
        szMoneyText = szMoneyText .. "（风控" .. szMoneyLimit .. "）"
    end
    szSellPriceTip = string.format(szSellPriceTip, szMoneyText)
    local szConfirmContain = szSellPriceTip..szConfirmTip
    local bTimeReturn = ItemData.IsCanTimeReturnItem(item)
    local bCountDown = false
    if bTimeReturn then
        local szEnchant = ItemData.GetItemEnchantDesc(item)
        if szEnchant and szEnchant ~= "" then
            szConfirmContain = string.format(g_tStrings.Shop.STR_SELL_RETURN_ENCHANT_ITEM_TIPS, itemName, szEnchant)
            bCountDown = true
        else
            szConfirmContain = string.format(g_tStrings.Shop.STR_SELL_RETURN_ITEM_TIPS, itemName)
        end
    end
    local confirmDialog = UIHelper.ShowConfirm(szConfirmContain, function()
        SellItem(0, 1232, nBox, nIndex, nSellCount)
    end, nil, true)

    if bCountDown then
        confirmDialog:SetButtonCountDown(5)
    end
end

function ItemData.GetBagFreeCellSize()
    local nCount = 0
    local tbBag = ItemData.BoxSet.Bag
    for _, nBox in ipairs(tbBag) do
        for nIndex = 0, g_pClientPlayer.GetBoxSize(nBox) - 1 do
            local hItem = g_pClientPlayer.GetItem(nBox, nIndex)
            if not hItem then nCount = nCount + 1 end
        end
    end
    return nCount
end

function ItemData.OpenBag()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local dwMapID = hPlayer.GetMapID()

    local nViewID
    if TravellingBagData.IsInTravelingMap() or UIscript_IsBoxLimitMap(dwMapID) then
        nViewID = VIEW_ID.PanelTravellingBag
    elseif BattleFieldData.IsInXunBaoBattleFieldMap() then
        nViewID = VIEW_ID.PanelBattleFieldXunBao
    elseif BattleFieldData.IsInTreasureBattleFieldMap() then
        nViewID = VIEW_ID.PanelBattleFieldPubgEquipBagRightPop
    else
        nViewID = VIEW_ID.PanelHalfBag
    end
    UIMgr.Open(nViewID)
end

function ItemData.GetCurrentBag()
    if TravellingBagData.IsInTravelingMap() then
        return ItemData.BoxSet.TravellingBag
    elseif BattleFieldData.IsInTreasureBattleFieldMap() then
        return ItemData.BoxSet.TravellingBag
    elseif ArenaTowerData.IsInArenaTowerMap() then
        return ItemData.BoxSet.TravellingBag
    else
        return ItemData.BoxSet.Bag
    end
end

function ItemData.IsItemExpiring(tItemInfo, hItem)
    if tItemInfo and hItem and tItemInfo.nExistType ~= ITEM_EXIST_TYPE.PERMANENT then
        local nLeftTime = hItem.GetLeftExistTime()
        local nLeftHour = math.floor(nLeftTime / 3600)
        return nLeftHour <= Const.ITEM_LEFT_HOUR and nLeftTime > 0
    end
    return false
end

function ItemData.IsBagContainExpiringItem()
    for i, nBox in ipairs(ItemData.BoxSet.Bag) do
        for k, tbItemInfo in ipairs(ItemData.GetBoxItem(nBox)) do
            local hItem = tbItemInfo.hItem
            if hItem then
                local tItemInfo = GetItemInfo(hItem.dwTabType, hItem.dwIndex)
                if ItemData.IsItemExpiring(tItemInfo, hItem) then
                   return true
                end
            end
        end
    end
    return false
end

function ItemData.IsRoleWareHouseContainExpiringItem()
    local function BankIndexToInventoryIndex(nIndex)
        return INVENTORY_INDEX.BANK + nIndex - 1
    end

    local player = g_pClientPlayer
    if not player then
        return
    end
    local nWareHouseBagCount = 6
    for i = 1, nWareHouseBagCount, 1 do
        local dwBox = BankIndexToInventoryIndex(i)
        local dwSize = player.GetBoxSize(dwBox)
        dwSize = dwSize - 1
        for dwX = 0, dwSize, 1 do
            local hItem = ItemData.GetPlayerItem(player, dwBox, dwX)
            if hItem then
                local tItemInfo = GetItemInfo(hItem.dwTabType, hItem.dwIndex)
                if ItemData.IsItemExpiring(tItemInfo, hItem) then
                    return true
                end
            end
        end
    end

    return false
end

function ItemData.IsBagExpiringBubbleShowing()
   return ItemData.bBagExpiringBubbleShowing
end

function ItemData.SetBagExpiringBubbleShowing(bState)
    ItemData.bBagExpiringBubbleShowing = bState
end

function ItemData.UseItemWrapper(dwBox, dwX, nMode, x, y, z)
	local player = GetClientPlayer()
	if not player then
		return
	end
	local item = player.GetItem(dwBox, dwX)
	local pScene = player.GetScene()
	if BitwiseAnd(pScene.dwBanUseItemMask, item.dwMapBanUseItemMask) > 0 then
		ItemData.OnUseBanItem(dwBox, dwX, nMode, x, y, z)
	else
		UseItem(dwBox, dwX, nMode, x, y, z)
	end
end


function ItemData.IsBanUseItem(item)
    local bBan = false
	local player = GetClientPlayer()
	if not player or not item then
		return bBan
	end
	local pScene = player.GetScene()
	if BitwiseAnd(pScene.dwBanUseItemMask, item.dwMapBanUseItemMask) > 0 then
        bBan = true
	end

    return bBan
end

function ItemData.OnUseBanItem(dwBox, dwX, nMode, x, y, z)
    local nCurTime = GetTickCount()
    if nBanUseTick < nCurTime then
        RemoteCallToServer("On_Item_BanUse", dwBox, dwX, nMode, x, y, z)
        nBanUseTick = nCurTime + nBanUseRemoteCD
    end
end
-------七夕------
--七夕戒指信息处理
function ItemData.SetQixiRingOwnerID(nID)
	ItemData.nQixiRingOwnerID = nID
end

function ItemData.GetQixiRingOwnerID()
	return ItemData.nQixiRingOwnerID
end

ItemData.tInscriptionList = {}
function ItemData.InsertQiXiInscriptionInfo(nPlayerID, index, tInfo)
	ItemData.tInscriptionList[nPlayerID] = ItemData.tInscriptionList[nPlayerID] or {}
	ItemData.tInscriptionList[nPlayerID][index] = tInfo
end

function ItemData.GetQiXiInscriptionInfo(nPlayerID)
	if nPlayerID then
		return ItemData.tInscriptionList[nPlayerID]
	end
end
--获取铭刻名字的Tip的通用函数，有特殊需求可以另外写
function ItemData.GetCustomNameTip(pPlayer, nDataPos, szTipGroupName)
	local szTip = ""
	local nQixiRingOwnerID = ItemData.GetQixiRingOwnerID()
	local tInscriptionInfo = ItemData.GetQiXiInscriptionInfo(nQixiRingOwnerID)
	if nQixiRingOwnerID and tInscriptionInfo and not IsRemotePlayer(pPlayer.dwID) and not IsRemotePlayer(nQixiRingOwnerID) then
		if tInscriptionInfo[1] and tInscriptionInfo[1].szName and tInscriptionInfo[nDataPos] and tInscriptionInfo[nDataPos].szName then
            szTip = g_tStrings[szTipGroupName].TITLE..g_tStrings[szTipGroupName].MARK[1].."<color=#DBBBFF>%s</c>"..g_tStrings[szTipGroupName].AND.."<color=#DBBBFF>%s</c>"..g_tStrings[szTipGroupName].TAIL
			--szTip = szTip:format(tInscriptionInfo[1].szName, tInscriptionInfo[nDataPos].szName)
            if nDataPos == 11 then  -- 师徒武器特殊处理
				szTip = szTip:format(UIHelper.GBKToUTF8(tInscriptionInfo[nDataPos].szName), UIHelper.GBKToUTF8(tInscriptionInfo[1].szName))
			else
				szTip = szTip:format(UIHelper.GBKToUTF8(tInscriptionInfo[1].szName), UIHelper.GBKToUTF8(tInscriptionInfo[nDataPos].szName))
			end
		end
	end
	return szTip
end

function ItemData.IsBookRead(nDoodadID)
    local player = g_pClientPlayer
    local bRead = false
    local dwRecipeID = player.GetRecipeIDByDoodadTemplateID(8, nDoodadID)
    if dwRecipeID then
        local nBookID, nSegmentID = GlobelRecipeID2BookID(dwRecipeID)
        if player.IsBookMemorized(nBookID, nSegmentID) then
            bRead = true
        end
    end
    return bRead
end

function ItemData.GetBagScript()
    return UIMgr.GetViewScript(VIEW_ID.PanelHalfBag) or UIMgr.GetViewScript(VIEW_ID.PanelHalfBag2)
end

-------对比背包功能--------

local common_item = {}

local function GetKey(item)
    if item and item.dwTabType and item.dwIndex then
        return item.dwTabType .. " " .. item.dwIndex
    end
    return " "
end

function ItemData.UpdateCommonItemBetweenBagAndBank()
    local bag_item = {}
    common_item = {}

    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

    local tbBag = ItemData.GetCurrentBag()
    for _, nBox in ipairs(tbBag) do
        for nIndex = 0, player.GetBoxSize(nBox) - 1 do
            local hItem = player.GetItem(nBox, nIndex)
            if hItem then
                bag_item[GetKey(hItem)] = 1
            end
        end
    end

    for _, nBox in ipairs(ItemData.BoxSet.Bank) do
        for nIndex = 0, player.GetBoxSize(nBox) - 1 do
            local hItem = player.GetItem(nBox, nIndex)
            local szKey = GetKey(hItem)
            if hItem and bag_item[szKey] == 1 then
                common_item[szKey] = 1
            end
        end
    end

    Event.Dispatch(EventType.OnBankBagCompareUpdate)
end

function ItemData.IsCommonItemBetweenBagAndBank(item)
    return common_item[GetKey(item)] ~= nil
end

function ItemData.OnReload()

end

local PERFUME_SLOT = 7
local TEMPORARY_ENCHANT_SLOT = 10

local CJ_KUNG_FU = {
    100725,
}

function ItemData.FastEnchanting(data, dwKungfuSkillID)
    local bMelee = true
    local bHeavy = nil
    if dwKungfuSkillID and table.contain_value(CJ_KUNG_FU, dwKungfuSkillID) then
        bMelee = data.bMelee
        bHeavy = data.bHeavy
    end
    local tSpecial = {}
    for nSlot, tItem in pairs(data) do
        if type(tItem) == "table" then
            if nSlot == PERFUME_SLOT and tItem.dwTabType and tItem.dwIndex then
                table.insert(tSpecial, {tItem.dwTabType, tItem.dwIndex, 3})
            elseif nSlot == TEMPORARY_ENCHANT_SLOT and tItem.dwTabType and tItem.dwIndex then
                table.insert(tSpecial, {tItem.dwTabType, tItem.dwIndex, 5})
            else
                ItemData.QuickUseItem(tItem.dwTabType, tItem.dwIndex)
            end
        end
    end

    if not IsTableEmpty(tSpecial) then
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP, "useitem") then
            return
        end
        RemoteCallToServer("On_Craft_TakePills", tSpecial, bMelee, bHeavy)
    end
end

function ItemData.GetTangMenBulletCount()
    local nArrow = 0
    local nJiGuan = 0
    local player = GetClientPlayer()
    local nBoxSize = player.GetBoxSize(INVENTORY_INDEX.BULLET_PACKAGE)
    for i = 1, nBoxSize, 1 do
        local item = GetPlayerItem(player, INVENTORY_INDEX.BULLET_PACKAGE, i - 1)
        if item then
            if item.dwIndex == 4000 then
                nArrow = nArrow + item.nStackNum
            else
                nJiGuan = nJiGuan + item.nStackNum
            end
        end
    end
    return nArrow, nJiGuan
end

function ItemData.CanWeaponBagOpen()
    local player = GetClientPlayer()
    local Kungfu = player.GetKungfuMount()
    local item = GetPlayerItem(player, INVENTORY_INDEX.EQUIP, EQUIPMENT_SUB.MELEE_WEAPON)
    local bMatchKungFu = Kungfu and Kungfu.dwMountType == 10
    if item then
        return bMatchKungFu and item.nGenre == ITEM_GENRE.EQUIPMENT and item.nDetail == WEAPON_DETAIL.BOW
    end
    return false
end

function ItemData.IsTangMenBullet(item)
    return item and (item.dwIndex == 4000 or item.dwIndex == 4014)
end

function ItemData.StoreTangMenBullet(dwBox, dwX, nAmount)
    if PropsSort.IsBagInSort() or PropsSort.IsBankInSort() then
        TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
        return
    end

    local player = GetClientPlayer()
    if not player then
        return
    end
    local dwTargetBox, dwTargetX
    local dwBoxType = player.GetBoxType(dwBox);

    if dwBoxType == INVENTORY_TYPE.PACKAGE then
        dwTargetBox, dwTargetX = ItemData.WeaponBag_GetFreeBox()
        if not (dwTargetBox and dwTargetX) then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_ERROR_BANK_IS_FULL)
            return false
        end
    end

    ItemData.OnExchangeItem(dwBox, dwX, dwTargetBox, dwTargetX, nAmount)
    return true
end

function ItemData.WeaponBag_GetFreeBox()
    local player = GetClientPlayer()
    local nBoxSize = player.GetBoxFreeRoomSize(INVENTORY_INDEX.BULLET_PACKAGE)
    if nBoxSize and nBoxSize ~= 0 then
        local dwX = player.GetFreeRoom(INVENTORY_INDEX.BULLET_PACKAGE, ITEM_GENRE.EQUIPMENT, EQUIPMENT_SUB.BULLET)
        if dwX then
            return INVENTORY_INDEX.BULLET_PACKAGE, dwX
        end
    end
end