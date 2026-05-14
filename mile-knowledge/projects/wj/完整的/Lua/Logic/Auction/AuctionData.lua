AuctionData = AuctionData or {className = "AuctionData"}

AuctionData.AUCTION_BID_TIME_LIMIT = GetBidTimeLimit() -- 结算倒计时消耗秒数,tBidInfo.nStartTime实际上是结算结束时间

AuctionType = {
    ROLL = 1,
}

AuctionState = {
    NeedRoll        = 0,    -- 待分配
    WaitAuction     = 1,    -- 待拍卖
    OnAuction       = 2,    -- 出价中
    WaitPay         = 3,    -- 待支付
    PriceLocked     = 4,    -- 已锁价
    CountDown       = 5,    -- 结算中
    CountFinished   = 6,    -- 已结算
}

AuctionQuickDistributeType = {
    Material = 1,
    SanJian = 2,
    General = 3,
}

AuctionStateConfig = {
    [AuctionState.NeedRoll] = {
        szName = "",
        szDesc = "",
    },
    [AuctionState.WaitAuction] = {
        szName = "待拍卖",
        szDesc = "暂无起拍价",
    },
    [AuctionState.OnAuction] = {
        szName = "出价中",
        szDesc = "出价-",
    },
    [AuctionState.CountDown] = {
        szName = "结算中",
        szDesc = "出价-",
    },
    [AuctionState.CountFinished] = {
        szName = "已结算",
        szDesc = "出价-",
    },
    [AuctionState.WaitPay] = {
        szName = "待支付",
        szDesc = "待付-",
    },
    [AuctionState.PriceLocked] = {
        szName = "已锁价",
        szDesc = "待付-",
    },
}

require("Lua/Logic/Auction/GoldTeam_Base.lua")

local DOODAD_TREASURE_TEMPLATE = 1392 --副本BOSS Doodad的模板ID都为此

-- 副本观战制作后需求，策划希望能够在队伍里有主播时同步发送到弹幕里
local function _DuplicateToBulletScreen(player, tText)
    local scene = GetClientScene()
    if not scene then return end
    if not player or not tText then return end
    if not IsRemotePlayer(player.dwID) then return end
    if not OBDungeonData.IsOBMap(scene.dwMapID) then return end

	if RoomVoiceData and RoomVoiceData.GetLiveStreamMapRoleList then
		local tList = RoomVoiceData.GetLiveStreamMapRoleList(LIVE_STREAM_MEMBER_TYPE.STREAMER) or {}
		if #tList > 0 then
			Player_Talk(player, PLAYER_TALK_CHANNEL.DUNGEON_BULLET_SCREEN, "", tText)
		end
	end
end

local function _DoApplyLiveStreamer()
    local player = GetClientPlayer()
    local scene = GetClientScene()
    if not scene then return end
    if not player then return end
    if not IsRemotePlayer(player.dwID) then return end
    if not OBDungeonData.IsOBMap(scene.dwMapID) then return end

    RoomVoiceData.ApplyLiveStreamMapRoleList(LIVE_STREAM_MEMBER_TYPE.STREAMER)
end

AuctionData.MAX_PRESET_COUNT = 9 -- 预设数量上限,1个官方预设+8个自定义预设

AuctionData.PRESET_TYPE_NAME = {
    [1] = "小铁",
    [2] = "小附魔",
    [3] = "大附魔",
    [4] = "藏剑武器盒",
    [5] = "普通武器盒",
    [6] = "水特效武器",
    [7] = "普通武器",
    [8] = "精简",
    [9] = "散件",
    [10] = "牌子",
}

function AuctionData.Init()
    AuctionData.bIsDirty = false
    AuctionData.bFilterForce = true
    AuctionData.nPickDoodadCount = 0
    AuctionData.tPickedDoodads = {}
    AuctionData.tPickDooodadSortIndex = {}
    AuctionData.tBiddingRecordMap = {}
    AuctionData.tBiddingTimeMap = {}
    AuctionData.tMemberTagIDMap = {}
    AuctionData.tStartBiddingRequestMap = {}
    AuctionData.tLastEndBiddingInfoList = {}
    AuctionData.ResetData()
    AuctionData._MAX_TAG_NUM = 8

    AuctionData.tCustomData = Storage.Auction

    AuctionData.tPresetTypeList = GDAPI_GetDefaulType() or {}
end

function AuctionData.BuildDoodadInfo(nDoodadID)
    local player = GetClientPlayer()
    if not player then
        return
    end

    local scene = player.GetScene()
    if not scene then
        return
    end

    local clientTeam = GetClientTeam()
    if not clientTeam then
        return
    end

    local tDoodadInfo =  {
        nDoodadID = nDoodadID,
        nLootMode = PARTY_LOOT_MODE.FREE_FOR_ALL,
        tLootItemInfoList = {},
        tLootItemInfoMap = {}
    }

    local tOldDoodadInfo = AuctionData.tPickedDoodads[nDoodadID]

    local tAllLootItemInfo = scene.GetLootList(nDoodadID)
    if not tAllLootItemInfo then return end
    
    local nMoney = scene.GetLootMoney(nDoodadID)
    if nMoney and nMoney > 0 then
        local tLootInfo = {}
        tLootInfo.dwDoodadID = nDoodadID
        tLootInfo.dwItemID = 0
        tLootInfo.nMoney = nMoney
        tLootInfo.nItemLootIndex = 0
        tLootInfo.nIndex = 0
        tLootInfo.bCanFreeLoot = true
        tLootInfo.dwStartFrame = 0
        tLootInfo.nLeftFrame = 0
        tLootInfo.nRollFrame = 0
        tLootInfo.eState = AuctionState.WaitAuction
        tLootInfo.tKungfuMap = {}
        tLootInfo.bAbstainMap = {}
        tLootInfo.bVisible = true
        table.insert(tDoodadInfo.tLootItemInfoList, tLootInfo)
    end

	for i = 0, tAllLootItemInfo.nItemCount - 1 do
        local tLootItem = tAllLootItemInfo[i]
        if tLootItem then
            local item, bNeedRoll, bNeedDistribute, bNeedBidding =
            tLootItem.Item,
            tLootItem.LootType == LOOT_ITEM_TYPE.NEED_ROLL,
            tLootItem.LootType == LOOT_ITEM_TYPE.NEED_DISTRIBUTE,
            tLootItem.LootType == LOOT_ITEM_TYPE.NEED_BIDDING
            if item and not bNeedRoll then -- Roll点改为和端游一致单独创建
                local tLootInfo = {}
                tLootInfo.dwDoodadID = nDoodadID
                tLootInfo.dwItemID = item.dwID
                tLootInfo.dwItemTabType = item.dwTabType
                tLootInfo.dwItemIndex = item.dwIndex                
                tLootInfo.nItemLootIndex = i
                tLootInfo.nIndex = #tDoodadInfo.tLootItemInfoList + 1
                tLootInfo.bNeedRoll = bNeedRoll
                tLootInfo.bNeedDistribute = bNeedDistribute
                tLootInfo.bNeedBidding = bNeedBidding
                tLootInfo.bCanFreeLoot = not bNeedRoll and not bNeedDistribute and not bNeedBidding
                tLootInfo.nLootType = tLootItem.LootType
                tLootInfo.dwStartFrame = 0
                tLootInfo.nLeftFrame = 0
                tLootInfo.nRollFrame = 0
                tLootInfo.eState = AuctionState.WaitAuction
                tLootInfo.tKungfuMap = {}
                tLootInfo.bAbstainMap = {}
                tLootInfo.bVisible = true

                local tOldLootInfo = tOldDoodadInfo and tOldDoodadInfo.tLootItemInfoMap[tLootInfo.dwItemID]

                local itemInfo = ItemData.GetItemInfo(item.dwTabType, item.dwIndex)
                if itemInfo.nRecommendID then
                    if not tOldLootInfo then
                        local tRecommend = TabHelper.GetEquipRecommend(itemInfo.nRecommendID)
                        if tRecommend then
                            for _, v in ipairs(string.split(tRecommend.kungfu_ids, "|")) do
                                local dwKungfuID = tonumber(v)
                                if dwKungfuID then
                                    tLootInfo.tKungfuMap[dwKungfuID] = true
                                end
                            end
                        end
                    else
                        tLootInfo.tKungfuMap = tOldLootInfo.tKungfuMap
                    end
                end

                if itemInfo.nGenre == ITEM_GENRE.BOOK then
                    tLootInfo.nBookID = item.nBookID
                end

                local tBidInfo = AuctionData.GetBiddingInfo(tLootInfo.dwDoodadID, tLootInfo.nItemLootIndex)
                if tBidInfo and tLootInfo.bNeedBidding then
                    if tBidInfo.nState == BIDDING_INFO_STATE.WAIT_PAYMENT then
                        tLootInfo.eState = AuctionState.WaitPay
                        tLootInfo.dwBidderID = tBidInfo.dwDestPlayerID
                    elseif tBidInfo.nState == BIDDING_INFO_STATE.BIDDING then
                        tLootInfo.eState = AuctionState.OnAuction
                        tLootInfo.dwBidderID = tBidInfo.dwDestPlayerID
                    elseif tBidInfo.nState == BIDDING_INFO_STATE.COUNT_DOWN then
                        tLootInfo.eState = AuctionState.CountDown
                        if tBidInfo.nStartTime < GetGSCurrentTime() then
                            tLootInfo.eState = AuctionState.CountFinished
                        end
                    end
                end

                table.insert(tDoodadInfo.tLootItemInfoList, tLootInfo)
                tDoodadInfo.tLootItemInfoMap[tLootInfo.dwItemID] = tLootInfo
            end

            if tDoodadInfo.nLootMode == PARTY_LOOT_MODE.FREE_FOR_ALL then
                if bNeedRoll then
                    tDoodadInfo.nLootMode = PARTY_LOOT_MODE.GROUP_LOOT
                elseif bNeedDistribute then
                    tDoodadInfo.nLootMode = PARTY_LOOT_MODE.DISTRIBUTE
                elseif bNeedBidding then
                    tDoodadInfo.nLootMode = PARTY_LOOT_MODE.BIDDING
                end
            end
        end
    end

    return tDoodadInfo
end

function AuctionData.OnOpenDoodad(nDoodadID)
    local scene = GetClientScene()
    if not scene then return end

    if not AuctionData.CanOpenDoodad(nDoodadID) then return end

    local tDoodadInfo = AuctionData.tPickedDoodads[nDoodadID]
    if tDoodadInfo then
        AuctionData.dwCurMapID = scene.dwMapID
        AuctionData.nLastestDoodadID = nDoodadID
        AuctionData.nLastestLootMode = tDoodadInfo.nLootMode
        return
    end

    tDoodadInfo = AuctionData.BuildDoodadInfo(nDoodadID)
    if not tDoodadInfo or #tDoodadInfo.tLootItemInfoList == 0 or not tDoodadInfo.nLootMode then
        return
    end
    if not DungeonData.IsLooter(nDoodadID, UI_GetClientPlayerID()) then
        return
    end

    AuctionData.dwCurMapID = scene.dwMapID

    AuctionData.tPickedDoodads[nDoodadID] = tDoodadInfo
    AuctionData.nPickDoodadCount = AuctionData.nPickDoodadCount + 1
    AuctionData.tPickDooodadSortIndex[nDoodadID] = AuctionData.nPickDoodadCount
    AuctionData.SetDirty(true)
    AuctionData.SetNeedRefresh(true)
    AuctionData.PushBubbleMsg()

    AuctionData.nTimerID = AuctionData.nTimerID or Timer.AddCycle(AuctionData, 1, function ()
        if not AuctionData.bHasBubbleMsg then
            return
        end
        AuctionData.CheckDoodadTimeOut()
    end)

    _DoApplyLiveStreamer() -- 副本观战需求
end

function AuctionData.CanOpenDoodad(dwDoodadID)
    local player = GetClientPlayer()
    if not player.IsInParty() and not AuctionData.NeedResidentLootList() then return false end

    local scene = GetClientScene()
    if not scene then return false end

    local tLootList = scene.GetLootList(dwDoodadID)
    if not tLootList then return false end

    local bBossDoodad = tLootList.dwTemplateID == DOODAD_TREASURE_TEMPLATE
    local bMatchTeam = false
    local clientTeam = GetClientTeam()
    if not bBossDoodad and clientTeam then
        local nQuality = clientTeam.nRollQuality
        for i = 0, tLootList.nItemCount - 1 do
            local tLootItem = tLootList[i]
            if tLootItem then
                local item, bNeedDistribute, bNeedBidding =
                tLootItem.Item,
                tLootItem.LootType == LOOT_ITEM_TYPE.NEED_DISTRIBUTE,
                tLootItem.LootType == LOOT_ITEM_TYPE.NEED_BIDDING
                local bMatchItem = item and item.nQuality >= nQuality
                bMatchItem = bMatchItem and (bNeedDistribute or bNeedBidding)
                if bMatchItem then
                    bMatchTeam = bMatchItem
                    break
                end
            end
        end
    end
    if not bBossDoodad and not bMatchTeam then return false end
    
    return true
end

-- 刷新非Roll点的Doodad道具状况，Roll点还是靠CheckDoodadTimeOut
function AuctionData.OnRefreshDoodad(dwDoodadID)
    local tOldDoodadInfo = AuctionData.tPickedDoodads[dwDoodadID]
    if not tOldDoodadInfo then
        return
    end

    if tOldDoodadInfo.nLootMode ~= PARTY_LOOT_MODE.GROUP_LOOT then
        local tNewDoodadInfo = AuctionData.BuildDoodadInfo(dwDoodadID)
        if not tNewDoodadInfo then
            tOldDoodadInfo.tLootItemInfoList = {}
            AuctionData.TryHandleDoodad(dwDoodadID)
            return
        end

        AuctionData.tPickedDoodads[dwDoodadID] = tNewDoodadInfo

        AuctionData.PushBubbleMsg()
    else
        local tDelList = {}
        for _, tLootInfo in ipairs(tOldDoodadInfo.tLootItemInfoList) do
            if tLootInfo.bHasDistributed then table.insert(tDelList, tLootInfo) end
        end
        for _, tLootInfo in ipairs(tDelList) do
            table.remove_value(tOldDoodadInfo.tLootItemInfoList, tLootInfo)
        end
    end

    AuctionData.TryHandleDoodad(dwDoodadID)
end

function AuctionData.TryCleanDoodad()
    local tDelDoodadList = {}
    for dwDoodadID, tDoodadInfo in pairs(AuctionData.tPickedDoodads) do
        local tDelList = {}
        for _, tLootInfo in ipairs(tDoodadInfo.tLootItemInfoList) do
            if tLootInfo.bHasDistributed then table.insert(tDelList, tLootInfo) end
        end
        for _, tLootInfo in ipairs(tDelList) do
            table.remove_value(tDoodadInfo.tLootItemInfoList, tLootInfo)
        end
        if #tDoodadInfo.tLootItemInfoList == 0 then table.insert(tDelDoodadList, dwDoodadID) end
    end

    for _, dwDoodadID in ipairs(tDelDoodadList) do
        AuctionData.TryHandleDoodad(dwDoodadID)
    end
end

function AuctionData.OnRollCreate(dwStartFrame, dwDoodadID, dwItemID, nLeftFrame)
    local player = g_pClientPlayer
    if not player then return end

    local scene = player.GetScene()
    if not scene then return end
    AuctionData.dwCurMapID = scene.dwMapID

    local tDoodadInfo = AuctionData.tPickedDoodads[dwDoodadID]
    if not tDoodadInfo then
        tDoodadInfo = {
            nDoodadID = dwDoodadID,
            tLootItemInfoList = {},
            nLootMode = PARTY_LOOT_MODE.GROUP_LOOT
        }
    end

    if not DungeonData.IsLooter(dwDoodadID, UI_GetClientPlayerID()) then
        return
    end

    local tLootItem, nLootItemIndex = DungeonData.GetLootItem(dwDoodadID, dwItemID)
    if tLootItem and tLootItem.Item then -- Roll点改为和端游一致单独创建
        local item = tLootItem.Item
        local tLootInfo = {}
        tLootInfo.dwDoodadID = dwDoodadID
        tLootInfo.dwItemID = item.dwID
        tLootInfo.dwItemTabType = item.dwTabType
        tLootInfo.dwItemIndex = item.dwIndex
        tLootInfo.nItemLootIndex = nLootItemIndex
        tLootInfo.nIndex = #tDoodadInfo.tLootItemInfoList + 1
        tLootInfo.bNeedRoll = true
        tLootInfo.bNeedDistribute = false
        tLootInfo.bNeedBidding = false
        tLootInfo.dwStartFrame = dwStartFrame
        tLootInfo.nLeftFrame = nLeftFrame
        tLootInfo.nRollFrame = scene.GetRollFrame()
        tLootInfo.eState = AuctionState.WaitAuction
        tLootInfo.tKungfuMap = {}
        tLootInfo.bAbstainMap = {}
        tLootInfo.bVisible = true

        local itemInfo = ItemData.GetItemInfo(item.dwTabType, item.dwIndex)
        if itemInfo.nRecommendID then
            local tRecommend = TabHelper.GetEquipRecommend(itemInfo.nRecommendID)
            if tRecommend then
                for _, v in ipairs(string.split(tRecommend.kungfu_ids, "|")) do
                    local dwKungfuID = tonumber(v)
                    if dwKungfuID then
                        tLootInfo.tKungfuMap[dwKungfuID] = true
                    end
                end
            end
        end

        if itemInfo.nGenre == ITEM_GENRE.BOOK then
            tLootInfo.nBookID = item.nBookID
        end

        local tBidInfo = AuctionData.GetBiddingInfo(tLootInfo.dwDoodadID, tLootInfo.nItemLootIndex)
        if tBidInfo and tBidInfo.nState == BIDDING_INFO_STATE.WAIT_PAYMENT then
            tLootInfo.eState = AuctionState.WaitPay
            tLootInfo.dwBidderID = tBidInfo.dwDestPlayerID
        end

        table.insert(tDoodadInfo.tLootItemInfoList, tLootInfo)
        AuctionData.tPickedDoodads[dwDoodadID] = tDoodadInfo
        AuctionData.nLastestLootMode = tDoodadInfo.nLootMode
        AuctionData.nLastestDoodadID = tDoodadInfo.nDoodadID
        AuctionData.SetNeedRefresh(true)
        AuctionData.PushBubbleMsg()
    end
end

function AuctionData.ApplyFilter(tbQualityFilter, tbTypeFilter)
    for dwDoodadID, tDoodadInfo in pairs(AuctionData.tPickedDoodads) do
        for _, tLootInfo in ipairs(tDoodadInfo.tLootItemInfoList) do
            local item = AuctionData.GetItem(tLootInfo.dwDoodadID, tLootInfo.nItemLootIndex)
            if item then
                -- 品质筛选
                local bQualityPass = #tbQualityFilter == 0
                for _, nQuality in ipairs(tbQualityFilter) do
                    nQuality = nQuality - 1
                    bQualityPass = bQualityPass or item.nQuality == nQuality
                end
                -- 类型筛选
                local bTypePass = #tbTypeFilter == 0
                for _, nType in ipairs(tbTypeFilter) do
                    bTypePass = bTypePass or (nType == 1 and item.nGenre == ITEM_GENRE.EQUIPMENT)
                    bTypePass = bTypePass or (nType == 2 and item.nGenre ~= ITEM_GENRE.EQUIPMENT)
                end
                tLootInfo.bVisible = bQualityPass and bTypePass
            end
        end
    end
    AuctionData.SetNeedRefresh(true)
end

function AuctionData.SetDirty(bIsDirty)
    AuctionData.bIsDirty = bIsDirty
end

function AuctionData.SetNeedRefresh(bNeedRefresh)
    AuctionData.bNeedRefresh = bNeedRefresh
end

function AuctionData.SortedPickedDoodads()
    AuctionData.CheckDoodadTimeOut()
    local SortedPickedDoodads = {}
    local player = GetClientPlayer()
    local dwMainKungfuID = player.GetActualKungfuMountID()
    local dwForceType = Kungfu_GetType(dwMainKungfuID)

    for dwDoodadID, tDoodadInfo in pairs(AuctionData.tPickedDoodads) do
        local tSortedDoodadInfo = {
            nDoodadID = dwDoodadID,
            dwNpcTemplateID = tDoodadInfo.dwNpcTemplateID,
            nLootMode = tDoodadInfo.nLootMode,
            tLootItemInfoList = {}
        }
        for _, tLootInfo in ipairs(tDoodadInfo.tLootItemInfoList) do
            if tLootInfo.bVisible then
                table.insert(tSortedDoodadInfo.tLootItemInfoList, tLootInfo)
            end
        end
        --当前心法能穿的>本门派另一个心法能穿的>其他
        if #tSortedDoodadInfo.tLootItemInfoList > 0 then
            table.sort(tSortedDoodadInfo.tLootItemInfoList, function(tLeft, tRight)
                local nLeftValue = 0
                local nRightValue = 0
                if table.GetCount(tLeft.tKungfuMap) == 0 then
                    return false
                elseif table.GetCount(tRight.tKungfuMap) == 0 then
                    return true
                end
                local bMatchKungfu = tLeft.tKungfuMap[0] or tLeft.tKungfuMap[dwMainKungfuID]
                if bMatchKungfu then nLeftValue = nLeftValue + 1000 end
                bMatchKungfu = tRight.tKungfuMap[0] or tRight.tKungfuMap[dwMainKungfuID]
                if bMatchKungfu then nRightValue = nRightValue + 1000 end

                for _, dwKungfuID in pairs(tLeft.tKungfuMap) do
                    if Kungfu_GetType(dwKungfuID) == dwForceType then nLeftValue = nLeftValue + 10 end
                end
                for _, dwKungfuID in pairs(tRight.tKungfuMap) do
                    if Kungfu_GetType(dwKungfuID) == dwForceType then nRightValue = nRightValue + 10 end
                end
                return nLeftValue > nRightValue
            end)
            SortedPickedDoodads[dwDoodadID] = tSortedDoodadInfo
        end
    end

    return SortedPickedDoodads
end

function AuctionData.GetDefaultPriceInfo(item)
    local tInfo = Table_GetGoldTeamAddPrice()
    local nPrice = 0
    local nAddPrice = tInfo[1].nPrice
    local tPriceInfo = GDAPI_GetDefaultPrice(g_pClientPlayer.GetMapID())
    for i = 1, #tPriceInfo do
        local fnFilter = tPriceInfo[i].fnFilter
        if fnFilter(item) then
            nPrice = tPriceInfo[i].nPrice
            nAddPrice = tPriceInfo[i].nAddPrice
            break
        end
    end

    if Storage.Auction.nPricePresetID ~= 1 then
        local tPreset = Storage.Auction.tPricePreset[Storage.Auction.nPricePresetID]
        if tPreset then
            local nType = GDAPI_GetDefaulItem(item) or 0
            local nTypeIndex = 0
            for nIndex, nPType in ipairs(AuctionData.tPresetTypeList) do
                if nType == nPType then
                    nTypeIndex = nIndex
                    break
                end
            end
            local tCellInfo = tPreset[nTypeIndex]
            if tCellInfo then
                nPrice, nAddPrice = tCellInfo.nStartPrice, tCellInfo.nStepPrice
            end
        end
    end

    return nPrice, nAddPrice
end

-- 检查各类掉落和Doodad是否过期
function AuctionData.CheckDoodadTimeOut()
    local player = GetClientPlayer()
    local nCurLogicFrame = GetLogicFrameCount()
    local tHandleLootInfoList = {}
    local nTimeNow = GetGSCurrentTime()
    local pScene = GetClientScene()
    if not pScene then return end

    for dwDoodadID, tDoodadInfo in pairs(AuctionData.tPickedDoodads) do
        local tLootList = pScene.GetLootList(dwDoodadID)
        if not tLootList then
            tDoodadInfo.tLootItemInfoList = {}
            AuctionData.TryHandleDoodad(dwDoodadID)
            AuctionData.SetNeedRefresh(true)
        else
            for _, tLootInfo in ipairs(tDoodadInfo.tLootItemInfoList) do
                if not tLootInfo.bHasDistributed then
                    -- 检查Roll点是否超时
                    local nOldLootType = tLootInfo.nLootType
                    local bTimeOut = false
                    if tLootInfo.dwItemID > 0 then
                        local tLootItem = DungeonData.GetLootItem(tLootInfo.dwDoodadID, tLootInfo.dwItemID)
                        bTimeOut = not tLootItem
                        if tLootItem then
                            tLootInfo.nLootType = tLootItem.LootType
                            tLootInfo.bNeedRoll = tLootItem.LootType == LOOT_ITEM_TYPE.NEED_ROLL
                            tLootInfo.bNeedDistribute = tLootItem.LootType == LOOT_ITEM_TYPE.NEED_DISTRIBUTE
                            tLootInfo.bNeedBidding = tLootItem.LootType == LOOT_ITEM_TYPE.NEED_BIDDING
                            tLootInfo.bCanFreeLoot = not tLootInfo.bNeedRoll and not tLootInfo.bNeedDistribute and not tLootInfo.bNeedBidding
                            if tLootInfo.bCanFreeLoot then
                                tLootInfo.dwStartFrame = 0
                                tLootInfo.nLeftFrame = -1
                                tLootInfo.nRollFrame = 0
                            end
                        end
                    else
                        local nCurMoney = DungeonData.GetLootMoney(dwDoodadID)
                        if nCurMoney <= 0 then bTimeOut = true end
                    end
                    if tLootInfo.nLootType ~= nOldLootType then Event.Dispatch(EventType.OnLootInfoChanged, tLootInfo) end
                    if bTimeOut then
                        table.insert(tHandleLootInfoList, tLootInfo)
                    end
                end
                if tLootInfo.eState == AuctionState.CountDown then
                    local tBidInfo = AuctionData.GetBiddingInfo(tLootInfo.dwDoodadID, tLootInfo.nItemLootIndex)
                    if tBidInfo and tBidInfo.nStartTime <= nTimeNow then
                        tLootInfo.eState = AuctionState.CountFinished
                        AuctionData.OnLootItemCountFinished(tLootInfo, tBidInfo)
                        Event.Dispatch(EventType.OnLootInfoChanged, tLootInfo)
                    end
                end
            end
        end

    end

    for _, tLootInfo in ipairs(tHandleLootInfoList) do
        AuctionData.OnItemHandleOver(tLootInfo)
    end
end

function AuctionData.OnLootItemCountFinished(tLootInfo, tBidInfo)
    local clientTeam = GetClientTeam()
    local dwDistributerID = clientTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE)
    local bDistributer = dwDistributerID == UI_GetClientPlayerID()
    if not bDistributer then return end

    local tData = {
        nBrick = math.floor(tBidInfo.nPrice / 10000),
        nGold = math.floor(tBidInfo.nPrice % 10000),
        szComment = "",
        dwPlayerID = tBidInfo.dwDestPlayerID,
    }
    local szMoney, szItemName, szPlayerName = AuctionData.GetStartBiddingConfirmContent(tBidInfo.dwItemID, tData)
    local szContent = string.format("你确认以%s将[%s]分配给[%s]吗？", szMoney, szItemName, szPlayerName)
    UIHelper.ShowConfirm(szContent, function ()
        AuctionData.StartBidding(tLootInfo, tData.nBrick, tData.nGold, tData.szComment, tData.dwPlayerID)
    end, nil, true)
end

function AuctionData.GetBiddingInfo(dwDoodadID, nLootItemIndex)
    local teamBidMgr = GetTeamBiddingMgr()
    local tAllBidInfo = teamBidMgr.GetAllBiddingInfo()
    for _, tBidInfo in ipairs(tAllBidInfo) do
        if tBidInfo.dwDoodadID == dwDoodadID and tBidInfo.nLootItemIndex == nLootItemIndex and tBidInfo.nState ~= BIDDING_INFO_STATE.INVALID then
            return tBidInfo
        end
    end

    return nil
end

function AuctionData.GetLootInfo(dwDoodadID, nLootItemIndex)
    local dwDoodadID = dwDoodadID
    local tDoodadInfo = AuctionData.tPickedDoodads[dwDoodadID]
    if tDoodadInfo then
        for _, tLootInfo in ipairs(tDoodadInfo.tLootItemInfoList) do
            if tLootInfo.nItemLootIndex == nLootItemIndex then
                return tLootInfo
            end
        end
    end

    return nil
end

function AuctionData.SetLootInfo(tLootInfo)
    local dwDoodadID = tLootInfo.dwDoodadID
    local tDoodadInfo = AuctionData.tPickedDoodads[dwDoodadID]
    if tDoodadInfo then
        for i, info in ipairs(tDoodadInfo.tLootItemInfoList) do
            if info.nItemLootIndex == tLootInfo.nLootItemIndex then
                tDoodadInfo.tLootItemInfoList[i] = tLootInfo
            end
        end
        AuctionData.tPickedDoodads[dwDoodadID] = tDoodadInfo
    end
end

function AuctionData.SetPlayerTagID(dwPlayerID, nTagID)
    AuctionData.tMemberTagIDMap[dwPlayerID] = nTagID
end

function AuctionData.GetPlayerTag(dwPlayerID)
    local nTagID = AuctionData.tMemberTagIDMap[dwPlayerID]
    return AuctionData.tCustomData.TagNameList[nTagID]
end

function AuctionData.MakeItemLink(szName, szFont, dwID)
	local szLink = "<text>text="..UIHelper.EncodeComponentsString(szName)..
		szFont.."name=\"itemlink\" eventid=513 userdata="..dwID.."</text>"
	return szLink
end

function AuctionData.OnPlayerDistributeItem(arg0, arg1, arg2)
    local player = GetPlayer(arg0)
    local item = GetItem(arg1)
    if not (player and item) then
        return Log('[DISTRIBUTE_ITEM] Warning: cannot get player-' .. arg0 .. ' and item-' .. arg1)
    end
    local szItemLink = ChatHelper.MakeLink_item(arg1)

    local playerName = ""
    if GetClientPlayer().dwID == player.dwID then
        playerName = g_tStrings.STR_NAME_YOU
    else
        playerName = UIHelper.GBKToUTF8(player.szName)
    end
    local szItemName = ItemData.GetItemNameByItem(item)
    szItemName = UIHelper.GBKToUTF8(szItemName)
    local szColor = item and ItemQualityColor[item.nQuality + 1] or "#FFFFFF"
    szItemLink = string.format("<href=%s><color=%s>[%s]</color></href>", szItemLink, szColor, szItemName)
    local szMsg = string.format(g_tStrings.Auction.STR_DISTRIBUTE_ITEM, szItemLink, playerName)
    ChatData.Append(szMsg, 0, PLAYER_TALK_CHANNEL.LOCAL_SYS, false, "")
end

function AuctionData.OnPlayerRollItem(dwPlayerID, dwItemID, szChoice, szRollPoint)
    local tLootInfo = AuctionData.GetLootInfoByItemID(dwItemID)
    dwItemID = tLootInfo.dwItemID
    local item = GetItem(dwItemID)
    if not item then
        return Log('[ROLL_ITEM] Warning: cannot get player-' .. dwPlayerID .. ' and item-' .. dwItemID)
    end
    local playerName
    local szItemName = ItemData.GetItemNameByItem(item)
    local bSelf = GetClientPlayer().dwID == dwPlayerID
    if bSelf then
        playerName = g_tStrings.STR_NAME_YOU
    else
        playerName = TeamData.GetTeammateName(dwPlayerID)
        playerName = UIHelper.GBKToUTF8(playerName)
    end
    szItemName = UIHelper.GBKToUTF8(szItemName)
    szRollPoint = UIHelper.GBKToUTF8(szRollPoint)
    local szMsg = string.format(g_tStrings.Auction.STR_PLAYER_ROLL_POINTS_RICH, playerName, szItemName, szRollPoint)
    TipsHelper.ShowNormalTip(szMsg, false)

    if bSelf then
        tLootInfo.szRollPoint = szRollPoint
    end

    AuctionData.CheckAbstainMap(dwPlayerID, dwItemID)
    Event.Dispatch(EventType.OnLootInfoChanged, tLootInfo)
    -- 输出系统消息
    local szMode = g_tStrings.LOOT_MODE_NEED
    if arg2 == ROLL_ITEM_CHOICE.GREED then
        szMode = g_tStrings.LOOT_MODE_GREED
    end
    local szItemLink = ChatHelper.MakeLink_item(dwItemID)
    local szColor = item and ItemQualityColor[item.nQuality + 1] or "#FFFFFF"
    szItemLink = string.format("<href=%s><color=%s>[%s]</color></href>", szItemLink, szColor, szItemName)
    szItemLink = szItemLink .. string.format("（%s）", szMode)
    local szMsg = string.format(g_tStrings.Auction.STR_PLAYER_ROLL_POINTS_RICH, playerName, szItemLink, szRollPoint)
    ChatData.Append(szMsg, 0, PLAYER_TALK_CHANNEL.LOCAL_SYS, false, "")
end

function AuctionData.OnPlayerCancelRollItem(...)
    local dwPlayerID = arg0
    local dwItemID = arg1
    local tLootInfo = AuctionData.GetLootInfoByItemID(dwItemID)
    dwItemID = tLootInfo.dwItemID
    local item = GetItem(dwItemID)
    if not item then
        return Log('[CANCEL_ROLL_ITEM] Warning: cannot get player-' .. dwPlayerID .. ' and item-' .. dwItemID)
    end
    local playerName
    local szItemName = ItemData.GetItemNameByItem(item)
    szItemName = UIHelper.GBKToUTF8(szItemName)

    local bSelf = GetClientPlayer().dwID == dwPlayerID
    if bSelf then
        playerName = g_tStrings.STR_NAME_YOU
    else
        playerName = TeamData.GetTeammateName(dwPlayerID)
        playerName = UIHelper.GBKToUTF8(playerName)
    end
    local szMsg = string.format(g_tStrings.Auction.STR_PLAYER_CANCEL_ROLL_RICH, playerName, szItemName)
    TipsHelper.ShowNormalTip(szMsg, false)

    -- 设置放弃标记
    tLootInfo.bAbstainMap[dwPlayerID] = true
    if bSelf then
        --AuctionData.OnItemHandleOver(tLootInfo)
    end
    AuctionData.CheckAbstainMap(dwPlayerID, dwItemID)

    local szItemLink = ChatHelper.MakeLink_item(dwItemID)
    local szColor = item and ItemQualityColor[item.nQuality + 1] or "#FFFFFF"
    szItemLink = string.format("<href=%s><color=%s>[%s]</color></href>", szItemLink, szColor, szItemName)
    local szMsg = string.format(g_tStrings.Auction.STR_PLAYER_CANCEL_ROLL_RICH, playerName, szItemLink)
    ChatData.Append(szMsg, 0, PLAYER_TALK_CHANNEL.LOCAL_SYS, false, "")
end

-- 检查选择情况
function AuctionData.CheckAbstainMap(dwPlayerID, dwItemID)
    local player = GetClientPlayer()
    if not player then return end

    local scene = player.GetScene()
    if not scene then return end

    for dwDoodadID, tDoodadInfo in pairs(AuctionData.tPickedDoodads) do
        local aPartyMember = scene.GetLooterList(dwDoodadID)
        if aPartyMember then
            for _, tLootInfo in ipairs(tDoodadInfo.tLootItemInfoList) do
                if tLootInfo.dwItemID == dwItemID then
                    tLootInfo.bAbstainMap[dwPlayerID] = true
                end
                local bAllAbstain = true
                for _, mbr in ipairs(aPartyMember) do
                    bAllAbstain = bAllAbstain and tLootInfo.bAbstainMap[mbr.dwID]
                end
                if bAllAbstain then -- 所有人都做出了选择就销毁
                    --AuctionData.OnItemHandleOver(tLootInfo)
                end
            end
        end
    end
end

function AuctionData.OnPlayerLootItem(...)
    local dwPlayerID = arg0
	local dwItemID = arg1
	local nCount = arg2 or 1

    local item = GetItem(dwItemID)

    local playerName
    local szItemName = ItemData.GetItemNameByItem(item)
    szItemName = UIHelper.GBKToUTF8(szItemName)
    if GetClientPlayer().dwID == dwPlayerID then
        playerName = g_tStrings.STR_NAME_YOU
    else
        playerName = UIHelper.GBKToUTF8(TeamData.GetTeammateName(dwPlayerID))
    end

    local szMsg
    if nCount > 1 then
        szMsg = string.format(g_tStrings.Auction.STR_LOOT_ITEM_RICH, tostring(playerName), tostring(szItemName), tostring(nCount))
    else
        szMsg = string.format(g_tStrings.Auction.STR_LOOT_ITEM_RICH_ONE, tostring(playerName), tostring(szItemName))
    end
    -- TipsHelper.ShowNormalTip(szMsg, false)

    AuctionData.CheckDoodadTimeOut()    
end

function AuctionData.OnItemHandleOver(tLootInfo)
    if not tLootInfo then
        return
    end

    AuctionData.tBiddingRecordMap[tLootInfo.dwDoodadID] = AuctionData.tBiddingRecordMap[tLootInfo.dwDoodadID] or {}
    AuctionData.tBiddingRecordMap[tLootInfo.dwDoodadID][tLootInfo.nItemLootIndex] = nil

    tLootInfo.bHasDistributed = true
    RedpointHelper.AuctionLootList_Clear(tLootInfo.dwDoodadID, tLootInfo.nItemLootIndex)

    Event.Dispatch(EventType.OnLootInfoTimeOut, tLootInfo)
    Event.Dispatch(EventType.OnLootInfoChanged, tLootInfo)
end

function AuctionData.TryHandleDoodad(dwDoodadID)
    local tDoodadInfo = AuctionData.tPickedDoodads[dwDoodadID]
    if not tDoodadInfo then return end

    if #tDoodadInfo.tLootItemInfoList <= 0 then
        AuctionData.tPickedDoodads[tDoodadInfo.nDoodadID] = nil
        AuctionData.tPickDooodadSortIndex[tDoodadInfo.nDoodadID] = nil
        RedpointHelper.AuctionLootList_Clear(tDoodadInfo.nDoodadID)
        AuctionData.SetDirty(true)
    end
    local nSize = table.GetCount(AuctionData.tPickedDoodads)
    if nSize <= 0 and not AuctionData.NeedResidentLootList() then
        BubbleMsgData.RemoveMsg("AuctionOpening")
        AuctionData.bHasBubbleMsg = false
        AuctionData.SetDirty(true)
    end
end

function AuctionData.TryOpenAuctionView()
    if BattleFieldData.IsInXunBaoBattleFieldMap() then
        return
    end
    AuctionData.CheckDoodadTimeOut()

    local bAuctionMode = GetClientTeam().nLootMode == PARTY_LOOT_MODE.BIDDING
    local nSize = table.GetCount(AuctionData.tPickedDoodads)
    if nSize <= 0 and not AuctionData.NeedResidentLootList() then
        return
    end

    for dwDoodadID, _ in pairs(AuctionData.tPickedDoodads) do
        AuctionData.OnRefreshDoodad(dwDoodadID)
    end

    local tSortedDoodadInfo = AuctionData.SortedPickedDoodads()
    if table.GetCount(tSortedDoodadInfo) == 0 and not AuctionData.NeedResidentLootList() then return end

	if not UIMgr.IsViewOpened(VIEW_ID.PanelTeamAuction, true) then
        -- 打开界面时默认打开对应聊天频道
        if bAuctionMode then
            ChatHelper.Chat(AuctionData.GetUIChannel())
        end
		UIMgr.Open(VIEW_ID.PanelTeamAuction)
	end
end

function AuctionData.PushBubbleMsg()
    local nSize = table.GetCount(AuctionData.tPickedDoodads)
    if AuctionData.bHasBubbleMsg or (nSize <= 0 and not AuctionData.NeedResidentLootList()) then
        return
    end

    -- 观战状态下只有拍团模式才推送气泡
    if OBDungeonData.IsPlayerInOBDungeon() then
        local hTeam = GetClientTeam()
        if not hTeam or hTeam.nLootMode ~= PARTY_LOOT_MODE.BIDDING then
            BubbleMsgData.RemoveMsg("AuctionOpening")
            return
        end
    end

    AuctionData.bHasBubbleMsg = true

    BubbleMsgData.PushMsgWithType("AuctionOpening", {
        szType = "AuctionOpening", 		-- 类型(用于排重)
        nBarTime = 0, 							-- 显示在气泡栏的时长, 单位为秒
        szContent = function ()
            local szContent = "你的队伍正在进行掉落分配，点击查看掉落列表"
            return szContent, 0.5
        end,
        szAction = function ()
            AuctionData.SetDirty(true)
            AuctionData.TryOpenAuctionView()
        end,
    })
end

function AuctionData.GetAllOnlineTeamMemberInfo()
    local clientTeam = GetClientTeam()
    local tMemberInfoList = {}
    for i = 1, AuctionData.GetTeamGroupNum() do
		local thisMemberList = AuctionData.GetTeamGroupList(i - 1)
		for j = 1, #thisMemberList do
			local dwGID = thisMemberList[j]
			local tMemberInfo = AuctionData.GetPlayerInfo(dwGID)
            tMemberInfo.dwPlayerID = dwGID
            if RoomData.IsInGlobalRoomDungeon() then
                tMemberInfo.dwPlayerID = RoomData.GetTeamPlayerIDByGlobalID(dwGID)
                table.insert(tMemberInfoList, tMemberInfo)
            elseif tMemberInfo.bIsOnLine then
				table.insert(tMemberInfoList, tMemberInfo)
			end
		end
	end

    return tMemberInfoList
end

function AuctionData.GetDropItemSourceName(tDoodadInfo, szDefault)
    local szDoodadName = ""

    if tDoodadInfo.szDoodadName then return tDoodadInfo.szDoodadName end

    local dwNpcTemplateID = tDoodadInfo.dwNpcTemplateID
    local scene = g_pClientPlayer.GetScene()
    if scene then
        local tLootList = scene.GetLootList(tDoodadInfo.nDoodadID)
        if tLootList then dwNpcTemplateID = tLootList.dwNpcTemplateID end
    end

    if not dwNpcTemplateID and #tDoodadInfo.tLootItemInfoList > 0 then
        local tLootInfo = tDoodadInfo.tLootItemInfoList[1]
        local tBidInfo = AuctionData.GetBiddingInfo(tLootInfo.dwDoodadID, tLootInfo.nItemLootIndex)
        if tBidInfo then dwNpcTemplateID = tBidInfo.dwNpcTemplateID end
    end
    if dwNpcTemplateID then
        szDoodadName = Table_GetNpcTemplateName(dwNpcTemplateID)
        szDoodadName = UIHelper.GBKToUTF8(szDoodadName)
    end
    if szDoodadName == "" then
        local doodad = AuctionData.GetDoodad(tDoodadInfo.nDoodadID)
        if doodad then
            szDoodadName = Table_GetDoodadName(doodad.dwTemplateID, doodad.dwNpcTemplateID)
            szDoodadName = UIHelper.GBKToUTF8(szDoodadName)
        end
    end

    if szDoodadName == "" then
        szDoodadName = szDefault
    end

    return szDoodadName
end

function AuctionData.GetStartBiddingConfirmContent(dwItemID, tData)
    local szMoney = ""
    if tData.nBrick then
        szMoney = szMoney .. string.format("%d<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Zhuan' width='30' height='30'/>", tData.nBrick)
    end
    if tData.nGold then
        szMoney = szMoney .. string.format("%d<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Jin' width='30' height='30'/>", tData.nGold)
    end

    local item = GetItem(dwItemID)
    local szItemName = "目标物品"
    if item then
        szItemName = ShopData.GetItemNameWithColor(dwItemID)
    end

    local szPlayerName = UIHelper.GBKToUTF8(TeamData.GetTeammateName(tData.dwPlayerID))

    return szMoney, szItemName, szPlayerName
end

function AuctionData.GetLootItemConfirmContent(dwDoodadID, nItemLootIndex, tData)
    local szMoney = ""
    if tData.nBrick then
        szMoney = szMoney .. string.format("%d<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Zhuan' width='30' height='30'/>", tData.nBrick)
    end
    if tData.nGold then
        szMoney = szMoney .. string.format("%d<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Jin' width='30' height='30'/>", tData.nGold)
    end

    local item = AuctionData.GetItem(dwDoodadID, nItemLootIndex)
    local szItemName = "目标物品"
    if item then
        szItemName = ShopData.GetItemNameWithColor(nil, item.dwTabType, item.dwIndex)
    end

    local szPlayerName = UIHelper.GBKToUTF8(TeamData.GetTeammateName(tData.dwPlayerID))

    return szMoney, szItemName, szPlayerName
end

function AuctionData.GetAllDistributableAndUnpaidMoney()
	local nDistribSum, nUnpaidSum = 0, 0
	local teamBidMgr = GetTeamBiddingMgr()
    local aBidInfoList = teamBidMgr.GetAllBiddingInfo()
    if not aBidInfoList then
        return nDistribSum, nUnpaidSum
    end
    for _, tBidInfo in ipairs(aBidInfoList) do
        local nState = tBidInfo.nState
        local nPrice = tBidInfo.nPrice
        if nState == BIDDING_INFO_STATE.PAID then
            nDistribSum = nDistribSum + nPrice
        elseif nState == BIDDING_INFO_STATE.WAIT_PAYMENT then
            nUnpaidSum = nUnpaidSum + nPrice
        end
    end

    AuctionData.nTotalSubsidies = AuctionData.GetTotalSubsidies()
	nDistribSum = GetClientTeam().nInComeMoney - AuctionData.nTotalSubsidies
	return nDistribSum, nUnpaidSum
end

function AuctionData.GetStatisticMsg_Pay()
	local tText = {}
	local szData = string.rep("*", 15) .. g_tStrings.GOLD_BID_RPAY_STATIC_TITLE .. string.rep("*", 15)
	table.insert(tText, {{type="text", text=szData}})

	local nTotalRaidMoney, nTotalSubsidies, nTotalBasicMoney, nSelect, nBasicMoneyPerMember = AuctionData.GetAllMoneyInfo()
	szData = FormatString(g_tStrings.GOLD_BID_PAY_STATIC_TEAM, nTotalRaidMoney, nTotalSubsidies, nTotalBasicMoney, nSelect, nBasicMoneyPerMember)
	table.insert(tText, {{type="text", text=szData}})

	table.insert(tText, {{type="text", text = g_tStrings.GOLD_BID_PAY_MORE}})
	table.insert(tText, {{type="text", text=string.rep("*", 41)}})

    for _, textInfo in ipairs(tText) do
        textInfo[1].text = UIHelper.UTF8ToGBK(textInfo[1].text)
    end
	return tText
end

function AuctionData.GetTotalSubsidies()
	local nMoney = 0
    if not AuctionData.tSubsidies then
        return nMoney
    end
	for i, v in pairs(AuctionData.tSubsidies) do
		if v.nMoney then
			nMoney = nMoney + v.nMoney
		end
	end
	return nMoney
end

function AuctionData.GetAllMoneyInfo()
	local nTotalRaidMoney = GetClientTeam().nInComeMoney
	AuctionData.nTotalSubsidies = AuctionData.GetTotalSubsidies()
	local nTotalBasicMoney = nTotalRaidMoney - AuctionData.nTotalSubsidies
	local nSelect = GetTableCount(AuctionData.tCheckTeamers)

	local nBasicMoneyPerMember = 0
	if nSelect ~= 0 then
		nBasicMoneyPerMember = math.floor(nTotalBasicMoney / nSelect)
		if nBasicMoneyPerMember < 0 then
			nBasicMoneyPerMember = 0
		end
	end

	return nTotalRaidMoney, AuctionData.nTotalSubsidies, nTotalBasicMoney, nSelect, nBasicMoneyPerMember
end

function AuctionData.GetAllPlayerConsumeData()
	local tPlayerConsume = {}
	local aBidInfoList = GoldTeamBase_GetAllBiddingInfos()
	for i, tBidInfo in ipairs(aBidInfoList) do
		---local nType = tBidInfo.nType
		local nState = tBidInfo.nState
		---local nPrice = tBidInfo.nPrice
		---local nPaidMoney = tBidInfo.nPaidMoney
		---local dwDestPlayerID = tBidInfo.dwDestPlayerID
		local dwPayerID = tBidInfo.dwPayerID

		if nState == BIDDING_INFO_STATE.PAID then --- IMPORTANT  确认要不要去掉这个判断
			tPlayerConsume[dwPayerID] = (tPlayerConsume[dwPayerID] or 0) + GoldTeamBase_GetPaidGold(tBidInfo)
		end
	end

	return tPlayerConsume
end

function AuctionData.InitCheckAllMembers()
    if not AuctionData.tCheckTeamers then
        AuctionData.tCheckTeamers = {}
    end

    if not RoomData.IsInGlobalRoomDungeon() then
        for k,_ in pairs(AuctionData.tCheckTeamers) do
            if type(k) == "string" then
                AuctionData.tCheckTeamers = {}
                break
            end
        end
    end

	if table.GetCount(AuctionData.tCheckTeamers) > 0 then --- 说明已初始化
		return
	end

	local nGroupNum = AuctionData.GetTeamGroupNum()
	for nGroupID = 0, nGroupNum - 1 do
        local tMemberInfoList = AuctionData.GetTeamGroupList(nGroupID)
		for i, dwID in ipairs(tMemberInfoList) do
            AuctionData.tCheckTeamers[dwID] = true
        end
	end
end

function AuctionData.ResetData()
    AuctionData.nTotalSubsidies = 0
    AuctionData.tCheckTeamers = {}
    AuctionData.tSubsidies = {}
end

function AuctionData.OnChangeTeamDistributor()
	AuctionData.tCheckTeamers = {}
	AuctionData.tSubsidies = {}

	local nGroupNum = AuctionData.GetTeamGroupNum()
	for nGroupID = 0, nGroupNum - 1 do
        local tMemberInfoList = AuctionData.GetTeamGroupList(nGroupID)
		for i, dwID in ipairs(tMemberInfoList) do
            AuctionData.tCheckTeamers[dwID] = true
            if not AuctionData.tSubsidies[dwID] then
                AuctionData.tSubsidies[dwID] = {["nMoney"] = 0}
            end
        end
	end
end

function AuctionData.UpdateTeamExPays(dwGID, nMoney, szReason)
	local t = AuctionData.tSubsidies
	if not t[dwGID] then
		t[dwGID] = {}
	end
	t[dwGID].nMoney = nMoney
	t[dwGID].szReason = UIHelper.UTF8ToGBK(szReason)
    AuctionData.tCheckTeamers[dwGID] = true
	AuctionData.nTotalSubsidies = AuctionData.GetTotalSubsidies()
    Event.Dispatch(EventType.OnSalaryDataChanged)
end

function AuctionData.CheckAllTeamer(bCheck)
	local nGroupNum = AuctionData.GetTeamGroupNum()
	for nGroupID = 0, nGroupNum - 1 do
		local tMemberInfoList = AuctionData.GetTeamGroupList(nGroupID)
		for i, dwID in ipairs(tMemberInfoList) do
			if bCheck then
				AuctionData.tCheckTeamers[dwID] = true
				if not AuctionData.tSubsidies[dwID] then
					AuctionData.tSubsidies[dwID] = {["nMoney"] = 0}
				end
			else
				AuctionData.tCheckTeamers[dwID] = nil
				if AuctionData.tSubsidies[dwID] then
					AuctionData.tSubsidies[dwID] = nil
				end
			end
		end
	end
end

-- 目前发现有些情况下会有脏数据，但不清楚复现方式，暂时做个脏数据的校验修复
function AuctionData.FixTeamerData()
    local tMbrIDMap = {}
	local nGroupNum = AuctionData.GetTeamGroupNum()
	for nGroupID = 0, nGroupNum - 1 do
		local tMemberInfoList = AuctionData.GetTeamGroupList(nGroupID)
		for i, dwID in ipairs(tMemberInfoList) do
			tMbrIDMap[dwID] = true
		end
	end

    local tDeleteList = {}
    for dwID, bExist in pairs(AuctionData.tCheckTeamers) do
        if not tMbrIDMap[dwID] then
            table.insert(tDeleteList, dwID)
            LOG.ERROR(string.format("AuctionData.FixTeamerData find dirty memberID=%s", tostring(dwID)))
        end
    end

    for _, dwID in ipairs(tDeleteList) do
        AuctionData.tCheckTeamers[dwID] = nil
        AuctionData.tSubsidies[dwID] = nil
    end
end

local function OnSyncTeamersPay()
	AuctionData.tSubsidies = arg0
	AuctionData.tCheckTeamers = {}
	for i, v in pairs (AuctionData.tSubsidies) do
		AuctionData.tCheckTeamers[i] = true
	end
    Event.Dispatch(EventType.OnSalaryDataChanged)
    -- AuctionData.ShowIncomeDistributeComfirm()
end

local function OnSendTeamMoney()
	AuctionData.tSubsidies = arg0
	AuctionData.tCheckTeamers = {}
	for i, v in pairs (AuctionData.tSubsidies) do
		AuctionData.tCheckTeamers[i] = true
	end
    Event.Dispatch(EventType.OnSalaryDataChanged)
end

local function OnTeamMoneyChange()
	local nTotalRaidMoney = GetClientTeam().nInComeMoney
	if nTotalRaidMoney == 0 then
		AuctionData.tSubsidies = {}
		AuctionData.tCheckTeamers = {}
		AuctionData.nTotalSubsidies = 0

		OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.GOLD_MONEY_CLEAR)
	end
    Event.Dispatch(EventType.OnSalaryDataChanged)
end

local function OnPartyAddMember()
    AuctionData.InitCheckAllMembers()
	if AuctionData.IsDistributeMan() and not RoomData.IsInGlobalRoomDungeon() then
		local nQuality = GetClientTeam().nRollQuality
		---RemoteCallToServer("On_Team_SyncNewMember", arg1, {nQuality, GoldTeam.tBidRule}) --- IMPORTANT 这个要处理吗？

		AuctionData.tCheckTeamers[arg1] = true
		if not AuctionData.tSubsidies[arg1] then
			AuctionData.tSubsidies[arg1] = {["nMoney"] = 0}
		end
	end

    Event.Dispatch(EventType.OnSalaryDataChanged)
end

local function OnPartyDeleteMember()
	AuctionData.tCheckTeamers[arg1] = nil
	AuctionData.tSubsidies[arg1] = nil

    if UI_GetClientPlayerID() == arg1 then
        AuctionData.Init()
        AuctionData.tSubsidies = {}
		AuctionData.tLastEndBiddingInfoList = {}
	end

    Event.Dispatch(EventType.OnSalaryDataChanged)
end

local function OnRoomMemberChange()
	if arg2 then
		if AuctionData.IsDistributeMan() and RoomData.IsInGlobalRoomDungeon() then
			AuctionData.tCheckTeamers[arg1] = true
			if not AuctionData.tSubsidies[arg1] then
				AuctionData.tSubsidies[arg1] = {["nMoney"] = 0}
			end
		end
	else
		AuctionData.tCheckTeamers[arg1] = nil
		AuctionData.tSubsidies[arg1] = nil
	end
end

local function OnPartyDisband()
    BubbleMsgData.RemoveMsg("AuctionOpening")
    AuctionData.bHasBubbleMsg = false
    AuctionData.SetDirty(true)
	AuctionData.Init()
end

function AuctionData.StartBidding(tLootInfo, nBrick, nGold, szComment, dwDestPlayerID)
    local teamBidMgr = GetTeamBiddingMgr()
    local dwDoodadID = tLootInfo.dwDoodadID
    nGold = nBrick * 10000 + nGold
	--local aBidInfoList = teamBidMgr.GetAllBiddingInfo()
	--aBidInfoList = GoldTeam.GetSortedBidInfoList(aBidInfoList)
    local eRetCode = teamBidMgr.CanFinishBidding(dwDoodadID, tLootInfo.nItemLootIndex, nGold, dwDestPlayerID)
    if eRetCode == TEAM_BIDDING_START_RESULT.SUCCESS then
        szComment = UIHelper.UTF8ToGBK(szComment)
        teamBidMgr.FinishBidding(dwDoodadID, dwDestPlayerID, nGold, tLootInfo.nItemLootIndex, szComment)
        tLootInfo.dwBidderID = dwDestPlayerID
    else
        GoldTeamBase_OnBiddingStartError(eRetCode)
    end
end

-- 重新拍卖需要先EndBidding，只有这里会触发EndBiding，所以在Endbiding成功之后需要再发起请求。
function AuctionData.Rebidding(tBidInfo, nBrick, nGold, szComment, dwDestPlayerID)
    local teamBidMgr = GetTeamBiddingMgr()
    local eRetCode = teamBidMgr.CanEndBidding(tBidInfo.nBiddingInfoIndex)
    if eRetCode == TEAM_BIDDING_START_RESULT.SUCCESS then
        local tBidInfo = teamBidMgr.GetBiddingInfo(tBidInfo.nBiddingInfoIndex)
        teamBidMgr.EndBidding(tBidInfo.nBiddingInfoIndex)

        AuctionData.tStartBiddingRequestMap[tBidInfo.nBiddingInfoIndex] = {
            fStart = function ()
                local teamBidMgr = GetTeamBiddingMgr()
                local dwDoodadID = tBidInfo.dwDoodadID
                nGold = nBrick * 10000 + nGold
                --local aBidInfoList = GoldTeamBase_GetAllBiddingInfos()
                --aBidInfoList = GoldTeam.GetSortedBidInfoList(aBidInfoList)
                if tBidInfo.nType == BIDDING_INFO_TYPE.ITEM then
                    local eRetCode = teamBidMgr.CanFinishBidding(dwDoodadID, tBidInfo.nLootItemIndex, nGold, dwDestPlayerID)
                    if eRetCode == TEAM_BIDDING_START_RESULT.SUCCESS then
                        szComment = UIHelper.UTF8ToGBK(szComment)
                        teamBidMgr.FinishBidding(dwDoodadID, dwDestPlayerID, nGold, tBidInfo.nLootItemIndex, szComment)
                        tBidInfo.dwBidderID = dwDestPlayerID
                    else
                        GoldTeamBase_OnBiddingStartError(eRetCode)
                    end
                else
                    --- 对应于罚款
					eRetCode = teamBidMgr.CanAddPenaltyRecord(nGold, dwDestPlayerID)
					if eRetCode == TEAM_BIDDING_START_RESULT.SUCCESS then
						teamBidMgr.AddPenaltyRecord(dwDestPlayerID, nGold, szComment)
					else
						GoldTeamBase_OnBiddingStartError(eRetCode)
					end
                end
            end
        }
    else
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.GOLD_END_BID_FAIL)
        return
    end
end

function AuctionData.TryPay(tBidInfo)
    if not tBidInfo then
        return
    end
    local teamBidMgr = GetTeamBiddingMgr()
	local nBidInfoIndex = tBidInfo.nBiddingInfoIndex
	local nPrice = tBidInfo.nPrice
	local nPaidMoney = tBidInfo.nPaidMoney
	local player = GetClientPlayer()
	local tMoney = player.GetMoney()
	local nGold, nSilver, nCopper = UnpackMoney(tMoney)
	local nRequiredGold = nPrice - nPaidMoney

	if nRequiredGold > 0 and BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TRADE) then
		return
	end

    if nGold >= nRequiredGold then
		local nRetCode = teamBidMgr.CanRiseMoney(nBidInfoIndex, nRequiredGold)
		if nRetCode == TEAM_BIDDING_START_RESULT.SUCCESS then
			teamBidMgr.RiseMoney(nBidInfoIndex, nRequiredGold)
		else
            TipsHelper.ShowNormalTip(g_tStrings.GOLD_TEAM_BID_ITEM_FAIL, false)
		end
	else
		local nPlayerMoneyLimit = player.GetMoneyLimitByGold()

		if nRequiredGold < nPlayerMoneyLimit then
            TipsHelper.ShowNormalTip(g_tStrings.GOLD_TEAM_MUST_PAY_ALL_AMOUNT_2, false)
		else
			-- 弹出部分付款界面
            UIMgr.Open(VIEW_ID.PanelPayByStagePop, {
                nTotalGold = nRequiredGold,
                nBidInfoIndex = nBidInfoIndex
            })
		end
	end
end

function AuctionData.AddPenaltyRecord(dwPlayerID, nMoneyInGolds, szComment)
    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TRADE) then
        return
    end

    if nMoneyInGolds == 0 then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.PARTY_GOLD_TEAM_CANNOT_ZERO_CONTRIBUTION)
        return
    end

    local teamBidMgr = GetTeamBiddingMgr()
    local player = GetClientPlayer()
    local tMoney = player.GetMoney()
    -- local nPlayerGold, nPlayerSilver, nPlayerCopper = UnpackMoney(tMoney)

    -- if nPlayerGold < nMoneyInGolds then
    --     OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.PARTY_GOLD_TEAM_CANNOT_AFFORD_CONTRIBUTION)
    --     return
    -- end

    local eRetCode = teamBidMgr.CanAddPenaltyRecord(nMoneyInGolds, dwPlayerID)
    if eRetCode == TEAM_BIDDING_START_RESULT.SUCCESS then
        szComment = UIHelper.UTF8ToGBK(szComment)
        teamBidMgr.AddPenaltyRecord(dwPlayerID, nMoneyInGolds, szComment)
    else
        local szErrString = g_tStrings.tTeamBiddingStartError[eRetCode]
        if szErrString then
            OutputMessage("MSG_ANNOUNCE_NORMAL", szErrString)
        else
            UILog("Unrecognized Bidding Start Error Code: " .. tostring(eRetCode))
        end
    end
end

function AuctionData.TryBidCountDown(dwDoodadID, nLootItemIndex)
    local teamBiding = GetTeamBiddingMgr()
    local nCode = teamBiding.CanBidCountDown(dwDoodadID, nLootItemIndex)
    if nCode ~= TEAM_BIDDING_START_RESULT.SUCCESS then
        TipsHelper.ShowImportantYellowTip(g_tStrings.tTeamBiddingStartError[nCode])
        return
    end

    teamBiding.BidCountDown(dwDoodadID, nLootItemIndex)
end

function AuctionData.SaveEditedBiddingInfo(tBidInfo)
	local dwDoodadID = tBidInfo.dwDoodadID
	local dwItemID = tBidInfo.dwItemID
	local nPrice = tBidInfo.nPrice
	local dwDestPlayerID = tBidInfo.dwDestPlayerID
	local szComment = tBidInfo.szComment

	for nIndex, tInfo in ipairs(AuctionData.tLastEndBiddingInfoList) do --- 一山不容二虎
		if tInfo.dwDoodadID == dwDoodadID and tInfo.dwItemID == dwItemID then
			table.remove(AuctionData.tLastEndBiddingInfoList, nIndex)
			break
		end
	end

	table.insert(AuctionData.tLastEndBiddingInfoList, {
        dwDoodadID  =   dwDoodadID,
        dwItemID    =   dwItemID,
        dwDestPlayerID  =   dwDestPlayerID,
        nPrice      =   nPrice,
        szComment   =   szComment})
end

function AuctionData.IsDistributeMan()
	local player = GetClientPlayer()
	local team = GetClientTeam()
	if player and team then
		local dwDistributeMan = team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE)
		if dwDistributeMan == player.dwID then
			return true
		end
	end
	return false
end

function AuctionData.NeedResidentLootList()
    return DungeonData.IsInNormalDungeon() or MonsterBookData.IsInBaiZhanMap()
end

function AuctionData.GetDoodad(dwDoodadID)
    local doodad = GetDoodad(dwDoodadID)

    return doodad
end

function AuctionData.GetItem(dwDoodadID, nLootIndex)
    local pScene = GetClientScene()
    if not pScene then
        return
    end
    local tLootList = pScene.GetLootList(dwDoodadID)
    if not tLootList then return end

    local tIemInfo = tLootList[nLootIndex]
    if not tIemInfo then return end
    return tIemInfo.Item
end

function AuctionData.GetLootInfoByItemID(dwItemID)
    for _, tDoodadInfo in pairs(AuctionData.tPickedDoodads) do
        for _, tLootInfo in ipairs(tDoodadInfo.tLootItemInfoList) do
            if tLootInfo.dwItemID == dwItemID then
                return tLootInfo
            end
        end
    end
end

function AuctionData.NeedOpenAuctionView(dwDoodadID, dwItemID)
    local tLootItem = DungeonData.GetLootItem(dwDoodadID, dwItemID)
    if not tLootItem then
        return false
    end

    return tLootItem.LootType == LOOT_ITEM_TYPE.NEED_ROLL or
        tLootItem.LootType == LOOT_ITEM_TYPE.NEED_DISTRIBUTE or
        tLootItem.LootType == LOOT_ITEM_TYPE.NEED_BIDDING
end

function AuctionData.HasBidItem(dwDoodadID, nItemLootIndex)
    local tBidInfo = AuctionData.GetBiddingInfo(dwDoodadID, nItemLootIndex)
    if not tBidInfo then return false end

    return tBidInfo.bWant
end

function AuctionData.ShowIncomeDistributeComfirm()
    if not AuctionData.dwDistributeStartTime then
        return
    end
    local nTotalMoney, nTotalSubsidies, nTotalBasicMoney, nSelect, nBasicMoneyPerMember = AuctionData.GetAllMoneyInfo()

    local dwGID = UI_GetClientPlayerID()
    if RoomData.IsInGlobalRoomDungeon() then dwGID = UI_GetClientPlayerGlobalID() end
    local tSubsidy = AuctionData.tSubsidies[dwGID]
    local nMoney = 0
    if tSubsidy then
        nMoney = tSubsidy.nMoney
    end
    nMoney = nMoney + nBasicMoneyPerMember
    local szTotalMoney = ShopData.GetPriceRichText(math.floor(nTotalMoney/10000), math.floor(nTotalMoney%10000), 0, 0)
    local szMoney = ShopData.GetPriceRichText(math.floor(nMoney/10000), math.floor(nMoney%10000), 0, 0)
    local szRichText = string.format("团长正在发起收入分配确认，总收入%s，自己可分配%s，是否同意？", szTotalMoney, szMoney)
    local scriptView = UIMgr.Open(VIEW_ID.PanelSalaryPayConfirmationPop)
    local tData = {
        szRichText = szRichText,
        fOnRefuse = function ()
            local team = GetClientTeam()
            team.Vote(1, 0)
            AuctionData.dwDistributeStartTime = nil
            UIMgr.Close(VIEW_ID.PanelSalaryPayConfirmationPop)
        end,
        fOnDetail = function ()
            UIMgr.Close(VIEW_ID.PanelSalaryPayConfirmationPop)
            local scriptRecrodView = UIMgr.GetViewScript(VIEW_ID.PanelAuctionRecord)
            if not scriptRecrodView then
                scriptRecrodView = UIMgr.Open(VIEW_ID.PanelAuctionRecord)
            end
            Timer.AddFrame(AuctionData, 1, function ()
                scriptRecrodView:Redirect(2) -- 跳转到收入分配界面
            end)
        end,
        fOnAccept = function ()
            local team = GetClientTeam()
            team.Vote(1, 1)
            AuctionData.dwDistributeStartTime = nil
            UIMgr.Close(VIEW_ID.PanelSalaryPayConfirmationPop)
        end,
    }
    scriptView:OnEnter(tData)
end

function AuctionData.GetPlayerInfo(dwID)
	if RoomData.IsInGlobalRoomDungeon() then
		return RoomData.GetRoomMemberInfo(dwID)
	else
		return GetClientTeam().GetMemberInfo(dwID)
	end
end

--- 获取成员人数
function AuctionData.GetTeamSize()
	if RoomData.IsInGlobalRoomDungeon() then
		return RoomData.GetSize()
	else
		return GetClientTeam().GetTeamSize()
	end
end

--- 获取成员分组
function AuctionData.GetTeamGroupNum()
	if RoomData.IsInGlobalRoomDungeon() then
		return 5
	else
		return GetClientTeam().nGroupNum
	end
end

--- 获取分组里的成员
function AuctionData.GetTeamGroupList(nGroupID)
	if RoomData.IsInGlobalRoomDungeon() then
		return RoomData.RoomBase_GetGroupList(nGroupID)
	else
		local tGroupInfo = GetClientTeam().GetGroupInfo(nGroupID) or {}
		return tGroupInfo.MemberList
	end
end

--- 附加centerid
function AuctionData.SetCenterID(tSubsidies)
	for id, tPay in pairs(tSubsidies) do
		if RoomData.IsInGlobalRoomDungeon() then
			local tMember = RoomData.GetRoomMemberInfo(id) or {dwCenterID = 0}
            if not tMember.dwCenterID then
                LOG.TABLE({"SetCenterID dwCenterID nil"})
            end
			tPay.dwCenterID = tMember.dwCenterID
		else
			tPay.dwCenterID = 0
		end
	end
	return tSubsidies
end

--- 输出频道
function AuctionData.GetChannel()
	if RoomData.IsInGlobalRoomDungeon() then
		return PLAYER_TALK_CHANNEL.ROOM
    elseif TeamData.IsInRaid() then
		return PLAYER_TALK_CHANNEL.RAID
    else
        return PLAYER_TALK_CHANNEL.TEAM
	end
end

function AuctionData.GetUIChannel()
	if RoomData.IsInGlobalRoomDungeon() then
		return UI_Chat_Channel.Room
    elseif TeamData.IsInRaid() then
		return UI_Chat_Channel.Party
    else
        return UI_Chat_Channel.Team
	end
end

function GetItemAttr(item, attr)
    local nValue1 = 0
	local nValue2 = 0
	if not item then
		return nValue1, nValue2
	end

    local magiclist = item.GetMagicAttrib()

    for v, k in ipairs(magiclist) do
        if k.nID == attr then
            nValue1 = nValue1 + k.nValue1
            nValue2 = nValue2 + k.nValue2
        end
    end
    local magiclist = item.GetBaseAttrib()

    for v, k in ipairs(magiclist) do
        if k.nID == attr then
            nValue1 = nValue1 + k.nValue1
            nValue2 = nValue2 + k.nValue2
        end
    end

    return nValue1, nValue2
end

local function GetTalkTextsFromString(szMsg, ...)
	local tText = {}
	local nFirst, nLast, szIndex = string.find(szMsg, "<D(.-)>")
	while nFirst do
		local szPrev = string.sub(szMsg, 1, nFirst - 1)
		if szPrev and szPrev ~= "" then
			table.insert(tText, {type="text", text = szPrev})
		end
		if szIndex and szIndex ~= "" then
			local nIndex = tonumber(szIndex) + 1
			local tArg = select(nIndex, ...)
			if tArg then
				local szType = tArg.type
			local args = tArg.args
				if szType == "text" then
					table.insert(tText, {type="text", text=args[1]})
				elseif szType == "name" then
					table.insert(tText, {type="name", text="[".. args[1] .."]", name=args[1]})
				elseif szType == "item" then
					table.insert(tText, {type = "item", text=args[1], item=args[2]})
				elseif szType == "iteminfo" then
					table.insert(tText, {type = "iteminfo", text=args[1], version=args[2], tabtype=args[3], index=args[4]})
				end
			end
		end

		szMsg = string.sub(szMsg, nLast + 1, -1)
		nFirst, nLast, szIndex = string.find(szMsg, "<D(.-)>")
	end
	if szMsg and szMsg ~= "" then
		table.insert(tText, {type="text", text=szMsg})
	end
	return tText
end

--- 辅助函数
local function _GetGoldText(nTotalGolds, bUseBrackets, bUseShortName)
	local nGBricks , nGolds = ConvertGoldToGBrick(nTotalGolds)
	local szText = ""
	if nGBricks > 0 then
		szText = szText .. nGBricks .. (bUseShortName and UIHelper.UTF8ToGBK(g_tStrings.STR_GOLD_BRICK_SHORT) or UIHelper.UTF8ToGBK(g_tStrings.STR_GOLD_BRICK))
	end
	if szText == "" or nGolds > 0 then
		szText = szText .. nGolds .. UIHelper.UTF8ToGBK(g_tStrings.STR_GOLD)
	end
	if bUseBrackets then
		szText = "[" .. szText .. "]"
	end
	return szText
end

local function _ShowRebiddingTips(dwOperatorPlayerID, tBidInfo)
    local tData = {
        nBrick = math.floor(tBidInfo.nPrice / 10000),
        nGold  = tBidInfo.nPrice % 10000,
        dwPlayerID = tBidInfo.dwDestPlayerID,
    }
    local szMoney, szItemName, szDestPlayerName = AuctionData.GetStartBiddingConfirmContent(tBidInfo.dwItemID, tData)
    local szOperatePlayerName = UIHelper.GBKToUTF8(TeamData.GetTeammateName(dwOperatorPlayerID))
    local szMsg = string.format("%s将[%s]以%s重新分配给了%s", szOperatePlayerName, szItemName, szMoney, szDestPlayerName)
    if not tBidInfo.dwItemID or tBidInfo.dwItemID <= 0 then
        szMsg = string.format("%s将追加收入修改为%s", szOperatePlayerName, szMoney)
    end
    TipsHelper.ShowNormalTip(szMsg, true)
end

local function _ShowStartBiddingTips(tBidInfo)
    local tData = {
        nBrick = math.floor(tBidInfo.nPrice / 10000),
        nGold  = tBidInfo.nPrice % 10000,
        dwPlayerID = tBidInfo.dwDestPlayerID,
    }
    local szMoney, szItemName, szDestPlayerName = AuctionData.GetStartBiddingConfirmContent(tBidInfo.dwItemID, tData)
    local szMsg = ""
    if tData.nBrick == 0 and tData.nGold == 0 then
        szMsg = string.format("你确认获取[%s]吗？", szItemName)
    elseif tBidInfo.dwItemID and tBidInfo.dwItemID > 0 then
        szMsg = string.format("你确认以%s购买[%s]吗？", szMoney, szItemName)
    else
        szMsg = string.format("你确认缴纳[%s]吗？", szMoney)
    end
    if tBidInfo.dwDestPlayerID ~= UI_GetClientPlayerID() then
        if tBidInfo.dwItemID and tBidInfo.dwItemID > 0 then
            szMsg = string.format("你确认以%s为[%s]购买[%s]吗？", szMoney, szDestPlayerName, szItemName)
        else
            szMsg = string.format("你确认为[%s]缴纳[%s]吗？", szDestPlayerName, szMoney)
        end
    end
    UIHelper.ShowConfirm(szMsg, function ()
        AuctionData.TryPay(tBidInfo)
    end, nil, true, true)
end

local function _CompareBidInfoAfterEditing(tCurBidInfo, dwOperatorPlayerID)
    local player = GetClientPlayer()
	local bHasPrevVersion = false
	local dwDoodadID = tCurBidInfo.dwDoodadID
	local dwItemID = tCurBidInfo.dwItemID
	local nPrice = tCurBidInfo.nPrice
	local dwDestPlayerID = tCurBidInfo.dwDestPlayerID
	local szComment = tCurBidInfo.szComment

	local tLastBidInfo
	for nIndex, tInfo in ipairs(AuctionData.tLastEndBiddingInfoList) do
		if tInfo.dwDoodadID == dwDoodadID and tInfo.dwItemID == dwItemID then
			tLastBidInfo = clone(tInfo)
			table.remove(AuctionData.tLastEndBiddingInfoList, nIndex)
			break
		end
	end

    local tText
    local nChannel = AuctionData.GetChannel()
	if tLastBidInfo then
        local szOperatorName = UIHelper.GBKToUTF8(TeamData.GetTeammateName(dwOperatorPlayerID))
        local szLastDestName = UIHelper.GBKToUTF8(tCurBidInfo.szDestPlayerName)
        local szItemName,_,_,_,bCanGetItem = ShopData.GetItemNameWithColor(tCurBidInfo.dwItemID, tCurBidInfo.dwItemTabType, tCurBidInfo.dwItemTabIndex, "目标物品")
		if tLastBidInfo.dwDestPlayerID ~= dwDestPlayerID then -- 重新分配
            _ShowRebiddingTips(dwOperatorPlayerID, tCurBidInfo)
            local tTextItem
			if bCanGetItem then
				tTextItem = {type="item", args={szItemName, tCurBidInfo.dwItemID}}
			else
				tTextItem = {type="iteminfo", args={szItemName, 0, tCurBidInfo.dwItemTabType, tCurBidInfo.dwItemTabIndex}}
			end

			tText = GetTalkTextsFromString(UIHelper.UTF8ToGBK(g_tStrings.PARTY_GOLD_TEAM_CHANGE_DISTRIBUTE_DEST_SUCCESS_MSG),
					{type="name", args={player.szName}}, tTextItem,
					{type="text", args={_GetGoldText(tCurBidInfo.nPrice, true)}},
					{type="name", args={tCurBidInfo.szDestPlayerName}})
			if AuctionData.IsDistributeMan() then Player_Talk(player, nChannel, "", tText) _DuplicateToBulletScreen(player, tText) end
		else
			local bPriceChange = tLastBidInfo.nPrice ~= nPrice
			local bCommentChange = tLastBidInfo.szComment ~= szComment
            local bDestPlayer = dwDestPlayerID == player.dwID
			if bPriceChange or bCommentChange then
                local tTextItem
				if bCanGetItem then
					tTextItem = {type="item", args={szItemName, dwItemID}}
				else
					tTextItem = {type="iteminfo", args={szItemName, 0, tCurBidInfo.dwItemTabType, tCurBidInfo.dwItemTabIndex}}
				end
				if bPriceChange then
                    local szOldPrice = ShopData.GetPriceRichText(math.floor(tLastBidInfo.nPrice/10000), tLastBidInfo.nPrice%10000, 0, 0)
                    local szNewPrice = ShopData.GetPriceRichText(math.floor(tCurBidInfo.nPrice/10000), tCurBidInfo.nPrice%10000, 0, 0)
                    local szMsg = string.format("%s把分配给%s的[%s]的售价由%s改为了%s", szOperatorName, szLastDestName, szItemName, szOldPrice, szNewPrice)
                    TipsHelper.ShowNormalTip(szMsg, true)

                    tText = GetTalkTextsFromString(UIHelper.UTF8ToGBK(g_tStrings.PARTY_GOLD_TEAM_CHANGE_DISTRIBUTE_PRICE_SUCCESS_MSG),
                        {type="name", args={player.szName}},
                        {type="name", args={tCurBidInfo.szDestPlayerName}},
                        tTextItem,
                        {type="text", args={_GetGoldText(tLastBidInfo.nPrice, true)}},
                        {type="text", args={_GetGoldText(tCurBidInfo.nPrice, true)}})
                        if AuctionData.IsDistributeMan() then Player_Talk(player, nChannel, "", tText) _DuplicateToBulletScreen(player, tText) end
				end
				if bCommentChange then
                    local szMsg = string.format("%s修改了[%s]的备注，请前往查看", szOperatorName, szItemName)
                    TipsHelper.ShowNormalTip(szMsg, true)

                    tText = GetTalkTextsFromString(UIHelper.UTF8ToGBK(g_tStrings.PARTY_GOLD_TEAM_CHANGE_DISTRIBUTE_COMMENT_SUCCESS_MSG),
                        {type="name", args={player.szName}},
                        {type="name", args={tCurBidInfo.szDestPlayerName}},
                        tTextItem,
                        {type="text", args={"[" .. tLastBidInfo.szComment .. "]"}},
                        {type="text", args={"[" .. szComment .. "]"}})
                        if AuctionData.IsDistributeMan() then Player_Talk(player, nChannel, "", tText) _DuplicateToBulletScreen(player, tText) end
				end
			end
		end

		bHasPrevVersion = true
	end

	return bHasPrevVersion
end

local function _AnnounceOnDistributing(tBidInfo, dwOperatorPlayerID)
    local player = GetClientPlayer()
	local szItemName, _, _, _, bCanGetItem = ShopData.GetItemNameWithColor(tBidInfo.dwItemID, tBidInfo.dwItemTabType, tBidInfo.dwItemTabIndex, "目标物品")
    local szOperatorName = UIHelper.GBKToUTF8(TeamData.GetTeammateName(dwOperatorPlayerID))
    local szDestPlayerName = UIHelper.GBKToUTF8(TeamData.GetTeammateName(tBidInfo.dwDestPlayerID))
    local szMoney = ShopData.GetPriceRichText(math.floor(tBidInfo.nPrice/10000), tBidInfo.nPrice%10000, 0, 0)
	local szMsg = string.format("%s将[%s]以%s记录给了%s", szOperatorName, szItemName, szMoney, szDestPlayerName)
    local bDestPlayer = tBidInfo.dwDestPlayerID == player.dwID
    if bDestPlayer then
        TipsHelper.ShowNormalTip(szMsg, true)
    else
        TipsHelper.ShowNormalTip(szMsg, true)
    end

    local tTextItem
	if bCanGetItem then
		tTextItem = {type="item", args={szItemName, tBidInfo.dwItemID}}
	else
		tTextItem = {type="iteminfo", args={szItemName, 0, tBidInfo.dwItemTabType, tBidInfo.dwItemTabIndex}}
	end
    local nChannel = AuctionData.GetChannel()
	local tText = GetTalkTextsFromString(UIHelper.UTF8ToGBK(g_tStrings.PARTY_GOLD_TEAM_DISTRIBUTE_ITEM_SUCCESS_MSG),
			{type="name", args={player.szName}}, tTextItem,
			{type="text", args={_GetGoldText(tBidInfo.nPrice, true)}},
			{type="name", args={tBidInfo.szDestPlayerName}})
            if AuctionData.IsDistributeMan() then Player_Talk(player, nChannel, "", tText) _DuplicateToBulletScreen(player, tText) end
end

local function _OnTeamAuthorityChange()
	if arg0 == TEAM_AUTHORITY_TYPE.DISTRIBUTE then
        AuctionData.tSubsidies = {}
		AuctionData.tLastEndBiddingInfoList = {}
        AuctionData.OnChangeTeamDistributor()
        Event.Dispatch(EventType.OnSalaryDataChanged)
	end
end

local function _OnPartyDisband()
    AuctionData.tSubsidies = {}
	AuctionData.tLastEndBiddingInfoList = {}
end

local function _OnTeamVoteRequest()
    if arg0 == 1 then
		if AuctionData.IsDistributeMan() then
		end
        -- AuctionData.dwDistributeStartTime = GetTickCount()
	end
end

local function _OnTeamVoteRespond(nVoteType, dwID, nResult)
    if nVoteType == 1 then
        if nResult == 1 then
            --AuctionData.CheckAllTeamer(false)
            --Event.Dispatch(EventType.OnSalaryDispatched)
        end
    end
end

local function OnPartyMessageNotify()
    if arg0 == PARTY_NOTIFY_CODE.PNC_PARTY_JOINED or arg0 == PARTY_NOTIFY_CODE.PNC_PARTY_CREATED then
		AuctionData.Init()
		OutputMessage("MSG_SYS", g_tStrings.GOLD_TEAM_CLEAR_ALL)
	end
end

local function _OnBiddingOperation(nBidInfoIndex)
	local teamBidMgr = GetTeamBiddingMgr()
	local tBidInfo = teamBidMgr.GetBiddingInfo(nBidInfoIndex)
	local pPlayer = GetClientPlayer()
	if pPlayer and tBidInfo and tBidInfo.nState == BIDDING_INFO_STATE.BIDDING then
		local tText = {}
		local szGolds = _GetGoldText(tBidInfo.nPrice, true)
        local szStepGolds = _GetGoldText(tBidInfo.nStepPrice, true)
		local szItemName, _, _, _, bCanGetItem = GoldTeam_GetItemNameAndColor(tBidInfo.dwItemID, tBidInfo.dwItemTabType, tBidInfo.dwItemTabIndex, true)
		local tTextItem
		if bCanGetItem then
			tTextItem = {type="item", args={szItemName, tBidInfo.dwItemID}}
		else
			tTextItem = {type="iteminfo", args={szItemName, 0, tBidInfo.dwItemTabType, tBidInfo.dwItemTabIndex}}
		end
		if tBidInfo.szDestPlayerName == "" and AuctionData.IsDistributeMan() then
            szGolds = _GetGoldText(tBidInfo.nPrice + tBidInfo.nStepPrice, true)
			tText = GetTalkTextsFromString(UIHelper.UTF8ToGBK(g_tStrings.PARTY_GOLD_TEAM_BIDDING_START),
			tTextItem,
            {type="text", args={szGolds}},
            {type="text", args={szStepGolds}})
		elseif tBidInfo.dwDestPlayerID == pPlayer.dwID then
			tText = GetTalkTextsFromString(UIHelper.UTF8ToGBK(g_tStrings.PARTY_GOLD_TEAM_BIDDING_CALL),
			{type="name", args={pPlayer.szName}},
			{type="text", args={szGolds}},
			tTextItem)
		end
		local nChannel = AuctionData.GetChannel()
		Player_Talk(pPlayer, nChannel, "", tText)
		_DuplicateToBulletScreen(pPlayer, tText)
	end
end

local function _AnnounceOnAddingPenalty(tBidInfo, player)
	local szGolds = _GetGoldText(tBidInfo.nPrice, true)
	--OutputMessage("MSG_ANNOUNCE_YELLOW", FormatString(g_tStrings.PARTY_GOLD_TEAM_ADD_PENALTY_SUCCESS_MSG, szGolds))

	local nChannel = AuctionData.GetChannel()
	local tText = GetTalkTextsFromString(UIHelper.UTF8ToGBK(g_tStrings.PARTY_GOLD_TEAM_ADD_PENALTY_SUCCESS_CHAT_MSG),
			{type="name", args={player.szName}},
			{type="name", args={tBidInfo.szDestPlayerName}},
			{type="text", args={szGolds}})
            if AuctionData.IsDistributeMan() then Player_Talk(player, nChannel, "", tText) _DuplicateToBulletScreen(player, tText) end
end

local function _AnnounceOnBoughtItem(tBidInfo, player)
	local szGolds = _GetGoldText(tBidInfo.nPrice, true)
	local szItemName, _, _, _, bCanGetItem = GoldTeam_GetItemNameAndColor(tBidInfo.dwItemID, tBidInfo.dwItemTabType, tBidInfo.dwItemTabIndex, true)

	local tTextItem
	if bCanGetItem then
		tTextItem = {type="item", args={szItemName, tBidInfo.dwItemID}}
	else
		tTextItem = {type="iteminfo", args={szItemName, 0, tBidInfo.dwItemTabType, tBidInfo.dwItemTabIndex}}
	end

	local nChannel = AuctionData.GetChannel()
	local tText = GetTalkTextsFromString(UIHelper.UTF8ToGBK(g_tStrings.PARTY_GOLD_TEAM_BUY_ITEM_SUCCESS_CHAT_MSG),
			{type="name", args={tBidInfo.szPayerName}},
			{type="text", args={szGolds}},
			tTextItem)
    Player_Talk(player, nChannel, "", tText)
	_DuplicateToBulletScreen(player, tText)

	--OutputMessage("MSG_SYS", FormatString(g_tStrings.PARTY_GOLD_TEAM_BUY_ITEM_SUCCESS_MSG, szGolds, szItemName)) --- IMPORTANT  以后考虑也做成支持链接功能（但是不能用Player_Talk()机制）
end

local function _AnnounceOnBoughtItemForHim(tBidInfo, playerPayer)
	local szGolds = _GetGoldText(tBidInfo.nPrice, true)
	local szItemName, _, _, _, bCanGetItem = GoldTeam_GetItemNameAndColor(tBidInfo.dwItemID, tBidInfo.dwItemTabType, tBidInfo.dwItemTabIndex, true)

	local tTextItem
	if bCanGetItem then
		tTextItem = {type="item", args={szItemName, tBidInfo.dwItemID}}
	else
		tTextItem = {type="iteminfo", args={szItemName, 0, tBidInfo.dwItemTabType, tBidInfo.dwItemTabIndex}}
	end

	local nChannel = AuctionData.GetChannel()
	local tText = GetTalkTextsFromString(UIHelper.UTF8ToGBK(g_tStrings.PARTY_GOLD_TEAM_BUY_ITEM_FOR_HIM_SUCCESS_CHAT_MSG),
			{type="name", args={tBidInfo.szPayerName}},
			{type="text", args={szGolds}},
			{type="name", args={tBidInfo.szDestPlayerName}},
			tTextItem)
    Player_Talk(playerPayer, nChannel, "", tText)
	_DuplicateToBulletScreen(playerPayer, tText)
end

local function _AnnounceOnBoughtItemForMe(tBidInfo)
	local szGolds = _GetGoldText(tBidInfo.nPrice, true)
	local szItemName, _, _, _, bCanGetItem = GoldTeam_GetItemNameAndColor(tBidInfo.dwItemID, tBidInfo.dwItemTabType, tBidInfo.dwItemTabIndex, true)
	local szMsg = FormatString(g_tStrings.PARTY_GOLD_TEAM_BUY_ITEM_FOR_ME_SUCCESS_MSG, "[" .. tBidInfo.szPayerName .. "]",
			szGolds, szItemName)
	--OutputMessage("MSG_SYS", szMsg) --- IMPORTANT  以后考虑也做成支持链接功能（但是不能用Player_Talk()机制）
end

local function _AnnounceOnContributionSuccess(tBidInfo, player, bIsDestPlayerSelf)
	local szMsg = FormatString(g_tStrings.PARTY_GOLD_TEAM_MAKE_CONTRIBUTION_SUCCESS_MSG, "[" .. tBidInfo.szPayerName .. "]")
	--OutputMessage("MSG_ANNOUNCE_YELLOW", szMsg)

	if bIsDestPlayerSelf then
		local scene = GetClientScene()
		local szMapName = scene and Table_GetMapName(scene.dwMapID) or g_tStrings.STR_QUESTION_M
		local nChannel = AuctionData.GetChannel()

		local tText = GetTalkTextsFromString(UIHelper.UTF8ToGBK(g_tStrings.PARTY_GOLD_TEAM_MAKE_CONTRIBUTION_SUCCESS_CHAT_MSG),
				{type="name", args={player.szName}},
				{type="text", args={szMapName}},
				{type="text", args={_GetGoldText(tBidInfo.nPrice, true)}},
				{type="text", args={szMapName}})
        Player_Talk(player, nChannel, "", tText)
		_DuplicateToBulletScreen(player, tText)
	end
end

local function _TryShowStartAuctionTips(tBidInfo)
    local item = GetItem(tBidInfo.dwItemID)
    if not item then return end

    local szItemName = ItemData.GetItemNameByItem(item)
    szItemName = UIHelper.GBKToUTF8(szItemName)
    local szColor = item and ItemQualityColor[item.nQuality + 1] or "#FFFFFF"
    local nCurPrice = tBidInfo.nPrice + tBidInfo.nStepPrice

    local szPrice = ShopData.GetPriceRichText(math.floor(nCurPrice/10000), math.floor(nCurPrice%10000), 0, 0)
    local szStepPrice = ShopData.GetPriceRichText(math.floor(tBidInfo.nStepPrice/10000), math.floor(tBidInfo.nStepPrice%10000), 0, 0)
    local szContent = string.format("[<color=%s>%s</c>]开始拍卖，起步价为%s，单次最少加价为%s", szColor, szItemName, szPrice, szStepPrice)
    TipsHelper.ShowNormalTip(szContent, true)
end

local function _TrySetRedPoint(tBidInfo)
    local dwDoodadID = tBidInfo.dwDoodadID
    local tLootInfo = AuctionData.GetLootInfo(dwDoodadID, tBidInfo.nLootItemIndex)
    if not tLootInfo then return end
    local dwOldBidderID = tLootInfo.dwBidderID or -1
    tLootInfo.dwBidderID = tBidInfo.dwDestPlayerID
    if dwOldBidderID == tBidInfo.dwDestPlayerID or dwOldBidderID ~= UI_GetClientPlayerID() then
        RedpointHelper.AuctionLootList_Clear(dwDoodadID, tBidInfo.nLootItemIndex)
        return
    end
    RedpointHelper.AuctionLootList_SetNew(dwDoodadID, tBidInfo.nLootItemIndex)
end

local function _TryOpenBidPopView(tBidInfo)
    local dwDoodadID = tBidInfo.dwDoodadID
    local tLootInfo = AuctionData.GetLootInfo(dwDoodadID, tBidInfo.nLootItemIndex)
    if not tLootInfo then return end

    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelAuctionBidPop)
    if not scriptView then
        scriptView = UIMgr.Open(VIEW_ID.PanelAuctionBidPop)
        scriptView:OnEnter(tLootInfo)
    else
        scriptView:OnLootItemCountDown(tLootInfo)
    end
end

Event.Reg(AuctionData, "ON_SYNC_TEAMERS_PAY", OnSyncTeamersPay) --工资同步
Event.Reg(AuctionData, "ON_SEND_TEAM_MONEY", OnSendTeamMoney)   --工资发放
Event.Reg(AuctionData, "TEAM_INCOMEMONEY_CHANGE_NOTIFY", OnTeamMoneyChange)
Event.Reg(AuctionData, "TEAM_AUTHORITY_CHANGED", _OnTeamAuthorityChange)
Event.Reg(AuctionData, "PARTY_ADD_MEMBER", OnPartyAddMember)
Event.Reg(AuctionData, "PARTY_DISBAND", OnPartyDisband)
Event.Reg(AuctionData, "PARTY_DELETE_MEMBER", OnPartyDeleteMember)
Event.Reg(AuctionData, "PARTY_MESSAGE_NOTIFY", OnPartyMessageNotify)
Event.Reg(AuctionData, "PARTY_DISBAND", _OnPartyDisband)
Event.Reg(AuctionData, "TEAM_VOTE_REQUEST", _OnTeamVoteRequest)
Event.Reg(AuctionData, "TEAM_VOTE_RESPOND", _OnTeamVoteRespond)
Event.Reg(AuctionData, "GLOBAL_ROOM_MEMBER_CHANGE", OnRoomMemberChange)

Event.Reg(AuctionData, EventType.OnRollItemTimeOut, function (tLootInfo)
    AuctionData.CheckDoodadTimeOut()
end)

Event.Reg(AuctionData, "BIDDING_OPERATION", function (eBidOperationType, dwOperatorPlayerID, nBidInfoIndex, nOperationTimestamp)
    local player = GetClientPlayer()
    local teamBidMgr = GetTeamBiddingMgr()
    local tBidInfo = teamBidMgr.GetBiddingInfo(nBidInfoIndex)
    if tBidInfo then
        local dwDoodadID = tBidInfo.dwDoodadID
        local tLootInfo = AuctionData.GetLootInfo(dwDoodadID, tBidInfo.nLootItemIndex)
        if tLootInfo then
            if tBidInfo.nState == BIDDING_INFO_STATE.WAIT_PAYMENT then
                tLootInfo.eState = AuctionState.WaitPay
                Event.Dispatch(EventType.OnLootInfoChanged, tLootInfo)
                -- AuctionData.SetDirty(true)
            elseif tBidInfo.nState == BIDDING_INFO_STATE.PAID then
                Event.Dispatch(EventType.OnLootInfoChanged, tLootInfo)
                -- AuctionData.SetDirty(true)
            elseif tBidInfo.nState == BIDDING_INFO_STATE.INVALID then
                tLootInfo.eState = AuctionState.WaitAuction
                Event.Dispatch(EventType.OnLootInfoChanged, tLootInfo)
            elseif tBidInfo.nState == BIDDING_INFO_STATE.BIDDING then
                tLootInfo.eState = AuctionState.OnAuction
                Event.Dispatch(EventType.OnLootInfoChanged, tLootInfo)
                -- AuctionData.SetDirty(true)
            elseif tBidInfo.nState == BIDDING_INFO_STATE.COUNT_DOWN then
                tLootInfo.eState = AuctionState.CountDown
                if tBidInfo.nStartTime < GetGSCurrentTime() then
                    tLootInfo.eState = AuctionState.CountFinished
                elseif tBidInfo.bWant then
                    _TryOpenBidPopView(tBidInfo)
                end
                Event.Dispatch(EventType.OnLootInfoChanged, tLootInfo)
            end
            if tLootInfo.eState ~= AuctionState.OnAuction then
                RedpointHelper.AuctionLootList_Clear(tLootInfo.dwDoodadID, tLootInfo.nItemLootIndex)
            end
        end
    end

    _OnBiddingOperation(nBidInfoIndex)
    local bIsDestPlayerSelf = tBidInfo.dwDestPlayerID == UI_GetClientPlayerID()
	local bIsPayerSelf = tBidInfo.dwPayerID == UI_GetClientPlayerID()

    if eBidOperationType == BIDDING_OPERATION_TYPE.END then
        if tBidInfo.nType == BIDDING_INFO_TYPE.ITEM then
            AuctionData.SaveEditedBiddingInfo(tBidInfo)
        end
        local tRequest = AuctionData.tStartBiddingRequestMap[nBidInfoIndex]
        if tRequest then
            tRequest.fStart()
            AuctionData.tStartBiddingRequestMap[nBidInfoIndex] = nil
        end
        Event.Dispatch(EventType.OnSalaryDataChanged)
        AuctionData.bIsDirty = true
    elseif eBidOperationType == BIDDING_OPERATION_TYPE.FINISH and tBidInfo then
        if player.dwID == tBidInfo.dwDestPlayerID then
            _ShowStartBiddingTips(tBidInfo)
        end
        if tBidInfo.nType == BIDDING_INFO_TYPE.ITEM then
            if not _CompareBidInfoAfterEditing(tBidInfo, dwOperatorPlayerID) then
                _AnnounceOnDistributing(tBidInfo, dwOperatorPlayerID)
            end
        else
            _AnnounceOnAddingPenalty(tBidInfo, player)
        end
    elseif eBidOperationType == BIDDING_OPERATION_TYPE.RISE_MONEY and tBidInfo and tBidInfo.nState == BIDDING_INFO_STATE.PAID then
        local szMoney = ShopData.GetPriceRichText(math.floor(tBidInfo.nPrice / 10000), tBidInfo.nPrice % 10000, 0, 0)
        local szOperatorName = UIHelper.GBKToUTF8(TeamData.GetTeammateName(dwOperatorPlayerID))
        local szDestPlayerName = UIHelper.GBKToUTF8(tBidInfo.szDestPlayerName)
        local szPayerName = UIHelper.GBKToUTF8(tBidInfo.szPayerName)
        local szMsg = ""
        if tBidInfo.nType == BIDDING_INFO_TYPE.ITEM then
            local szItemName = ShopData.GetItemNameWithColor(tBidInfo.dwItemID, tBidInfo.dwItemTabType, tBidInfo.dwItemTabIndex, "目标物品")
            szMsg = string.format("以%s将[%s]分配给[%s]", szMoney, szItemName, szDestPlayerName)

            if tBidInfo.dwDestPlayerID == tBidInfo.dwPayerID then
                if bIsPayerSelf then --- 自己给自己支付
                    _AnnounceOnBoughtItem(tBidInfo, player)
                end
            else
                if bIsPayerSelf then -- 自己给别人代付
                    _AnnounceOnBoughtItemForHim(tBidInfo, player)
                elseif bIsDestPlayerSelf then
                    _AnnounceOnBoughtItemForMe(tBidInfo)
                end
            end
        else
            szMsg = string.format("[%s]追加资金%s", szPayerName, szMoney)
            if tBidInfo.dwDestPlayerID == tBidInfo.dwPayerID then --- 说明是捐款（也可能就是普通的罚款，现在不予区分）
				_AnnounceOnContributionSuccess(tBidInfo, player, bIsDestPlayerSelf)
			end
        end
        local dwForceID = 0
        local tMemberInfo = TeamData.GetMemberInfo(dwOperatorPlayerID)
        if tMemberInfo then
            dwForceID = tMemberInfo.dwForceID
        end

        local tRecord = {
            szOperatorName = szOperatorName,
            szMsg = szMsg,
            nFinishTime = os.time(),
            dwForceID = dwForceID,
        }
        if #AuctionData.tCustomData.tDistributeRecords >= 100 then -- 策划暂定记录上限为100
            table.remove(AuctionData.tCustomData.tDistributeRecords, 1)
        end
        table.insert(AuctionData.tCustomData.tDistributeRecords, tRecord)
        AuctionData.bOperRecordDirty = true
    elseif eBidOperationType == BIDDING_OPERATION_TYPE.BEGIN then
        AuctionData.bForbidAutoOpenBidView = false
        _TryShowStartAuctionTips(tBidInfo)
        local dwDoodadID = tBidInfo.dwDoodadID
        local tLootInfo = AuctionData.GetLootInfo(dwDoodadID, tBidInfo.nLootItemIndex)
        if tLootInfo then
            RedpointHelper.AuctionLootList_Clear(tLootInfo.dwDoodadID, tLootInfo.nItemLootIndex)
        end        
    elseif eBidOperationType == BIDDING_OPERATION_TYPE.BID then
        if not AuctionData.bForbidAutoOpenBidView then _TrySetRedPoint(tBidInfo) end
    end
end)

Event.Reg(AuctionData, "SYNC_LOOT_LIST", function(dwDoodadID)
    AuctionData.OnOpenDoodad(dwDoodadID)
end)

Event.Reg(AuctionData, "OPEN_DOODAD", function(dwDoodadID)
    local clientTeam = GetClientTeam()
    local player = GetClientPlayer()
    if clientTeam and player then
        if AuctionData.CanOpenDoodad(dwDoodadID) then
            AuctionData.OnOpenDoodad(dwDoodadID)
            if arg1 == UI_GetClientPlayerID() then
                if not UIMgr.IsViewOpened(VIEW_ID.PanelTeamAuction) then
                    AuctionData.TryOpenAuctionView()
                end
            end
        end
    end
end)

Event.Reg(AuctionData, "MONEY_UPDATE", function(bAll, nBidInfoIndex)
    local scene = g_pClientPlayer.GetScene()
    if not scene then return end

    local bNeedCheckTime = false
    for dwDoodadID, tDoodadInfo in pairs(AuctionData.tPickedDoodads) do
        for _, tLootInfo in ipairs(tDoodadInfo.tLootItemInfoList or {}) do
            if tLootInfo.dwItemID and tLootInfo.dwItemID == 0 then
                bNeedCheckTime = true
            end
        end
    end

    if bNeedCheckTime then AuctionData.CheckDoodadTimeOut() end
end)

Event.Reg(AuctionData, "UPDATE_MANUAL_DROP_INFO", function(nDropID)
    if UIMgr.IsViewOpened(VIEW_ID.PanelSpecialDropList, true) then
        UIMgr.CloseWithCallBack(VIEW_ID.PanelSpecialDropList, function ()
            UIMgr.Open(VIEW_ID.PanelSpecialDropList, nDropID)
        end)
    else
        UIMgr.Open(VIEW_ID.PanelSpecialDropList, nDropID)
    end
end)

Event.Reg(AuctionData, EventType.OnViewClose, function(nViewID)
    -- 关闭界面时就强刷数据
    if nViewID == VIEW_ID.PanelTeamAuction then
        AuctionData.TryCleanDoodad()
        for dwDoodadID, _ in pairs(AuctionData.tPickedDoodads) do
            AuctionData.OnRefreshDoodad(dwDoodadID)
        end
    end
    -- 出场景气泡
    if nViewID ~= VIEW_ID.PanelLoading then return end
    if not g_pClientPlayer then return end

    local scene = g_pClientPlayer.GetScene()
    if not scene then return end

    AuctionData.bHasBubbleMsg = false
    AuctionData.PushBubbleMsg()

    if AuctionData.dwCurMapID == scene.dwMapID then
        return
    end

    if not AuctionData.NeedResidentLootList() then
        AuctionData.tPickedDoodads = {}
        RedpointHelper.AuctionLootList_ClearAll()
        BubbleMsgData.RemoveMsg("AuctionOpening")
        AuctionData.bHasBubbleMsg = false
    end
end)

Event.Reg(AuctionData, "FIGHT_HINT", function(bInFight)
    if not AuctionData.bInFight and bInFight and UIMgr.IsViewOpened(VIEW_ID.PanelTeamAuction, true) then
        UIMgr.Close(VIEW_ID.PanelChatSocial)
        UIMgr.Close(VIEW_ID.PanelTeamAuction)
    end
    AuctionData.bInFight = bInFight
end)

function AuctionData.MarkStartTime()
    AuctionData.dwLogStartTime = os.clock()
end

function AuctionData.MarkEndTime(szText)
    AuctionData.dwLogEndTime = os.clock()
    Log(string.format("AuctionDataMarkTime[%s]=%s", szText, tostring(AuctionData.dwLogEndTime - AuctionData.dwLogStartTime)))
    AuctionData.dwLogStartTime = AuctionData.dwLogEndTime
end