DungeonData = DungeonData or {className = "DungeonData"}

DungeonData.tDungeonMapDataBuffer1 = nil
DungeonData.tDungeonMapDataBuffer2 = nil
local szArabNum2CNNum = {
    ["2"] = "两人",
    ["5"] = "五人",
    ["10"] = "十人",
    ["25"] = "二十五人",
}
local BUFF_ENTERUI = 27901--是否进入单人模式的标记buff
local BUFF_UI = 27896--单人模式标识
local STAR_ITEM_MAX_NUM = 3

DungeonData.MAX_WISH_ITEM_RETRY_COUNT = 3
DungeonData.MAX_WISH_ITEM_RETRY_COUNT_OLD_VERSION = 20

function DungeonData.Init()
	DungeonData.tCheckCanTrackingMap = {}
    DungeonData.tBalanceShipInfo = {}
	for k, v in pairs(UIWorldMapZoningTab) do
        local tbChildCopyMaps = loadstring("return" .. v.szChildCopyMaps)
		local tChildCopyMaps = tbChildCopyMaps()
		for _, dwMapID in ipairs(tChildCopyMaps) do
			DungeonData.tCheckCanTrackingMap[dwMapID] = true
		end
    end
end

function DungeonData.UnInit()
    Timer.DelAllTimer(DungeonData)
    Event.UnRegAll(DungeonData)
end

function DungeonData.OnShowBalanceShip(bShow)
    if bShow then

    else
        GeneralProgressBarData.DeleteProgressBar("BalanceShip")
    end
end

function DungeonData.OnSetShipState(nWaterProgress, bShowWeight, nLeftWeight, nRightWeight, nOverWeightSide)
    GeneralProgressBarData.DeleteProgressBar("BalanceShip")

    DungeonData.tBalanceShipInfo.nLeftWeight = nLeftWeight or DungeonData.tBalanceShipInfo.nLeftWeight
    DungeonData.tBalanceShipInfo.nRightWeight = nRightWeight or DungeonData.tBalanceShipInfo.nRightWeight
    DungeonData.tBalanceShipInfo.nOverWeightSide = nOverWeightSide or DungeonData.tBalanceShipInfo.nOverWeightSide
    DungeonData.tBalanceShipInfo.nWaterProgress = nWaterProgress or DungeonData.tBalanceShipInfo.nWaterProgress

    local szTitle = ""
    if bShowWeight then
        if DungeonData.tBalanceShipInfo.nOverWeightSide == 0 then
            szTitle = "平衡"
        elseif DungeonData.tBalanceShipInfo.nOverWeightSide == 1 then
            szTitle = "不平衡(左)"
        elseif DungeonData.tBalanceShipInfo.nOverWeightSide == 2 then
            szTitle = "不平衡(右)"
        end
    end

    if not DungeonData.tBalanceShipInfo.nLeftWeight or not DungeonData.tBalanceShipInfo.nRightWeight then
        return
    end

    local szDescribe = string.format(" 左:%d 右:%d", DungeonData.tBalanceShipInfo.nLeftWeight, DungeonData.tBalanceShipInfo.nRightWeight)
    szTitle = szTitle .. szDescribe
    GeneralProgressBarData.AddProgressBar("BalanceShip", 0, UIHelper.UTF8ToGBK(szTitle), "", DungeonData.tBalanceShipInfo.nWaterProgress, 100, 1)
end

function DungeonData.GetEnableMapIDList(dwWindowID)
	local player = GetClientPlayer()
    local nMapIDList = Table_GetDungeonMapIDListWithWindowID(dwWindowID)
    local nEnableMapIDList = {}
    for _,dwMapID in ipairs(nMapIDList) do
        local tSwitchMapInfo = Table_GetSwitchMapInfo(dwMapID, dwWindowID)
        local bMinLevelLimit = tSwitchMapInfo.nMinLevelLimit > 0 and tSwitchMapInfo.nMinLevelLimit > player.nLevel
        if not bMinLevelLimit then
            table.insert(nEnableMapIDList, dwMapID)
        end
    end
    return nEnableMapIDList
end

function DungeonData.GetChineseNumText(szText)
	local splitList = string.split(szText, "人")
    if #splitList > 1 then
        local szNum = szArabNum2CNNum[splitList[1]]
        if szNum then
            szText = szNum..splitList[2]
        end
    end
	return szText
end

function DungeonData.ExtractChineseNumText(szText)
	local splitList = string.split(szText, "人")
    if #splitList > 1 then
        local szNum = szArabNum2CNNum[splitList[1]]
        if szNum then
            szText = szNum
        end
    end
	return szText
end

-- 当前场景类型是否是副本类型，可能是副本/百战/试炼之地/临时活动场景
function DungeonData.IsInDungeon()
	local player = GetClientPlayer()
	if player then
		local dwMapID = player.GetMapID()
		local _, nMapType = GetMapParams(dwMapID)

		return nMapType == 1
	end
	return false
end

-- 当前场景是否是普通副本，即秘境大全中显示的副本
function DungeonData.IsInNormalDungeon()
	local player = GetClientPlayer()
	if player then
		local dwMapID = player.GetMapID()
		local tDungeonInfo = Table_GetDungeonInfo(dwMapID)
        return tDungeonInfo ~= nil
	end
	return false
end

function DungeonData.IsKillAllBoss(nMapID)

    if not g_pClientPlayer then return end

    local aProgressIDs = {}
    local aBossProcessInfoList = Table_GetCDProcessBoss(nMapID)
    for i = 1, #aBossProcessInfoList do
        table.insert(aProgressIDs, aBossProcessInfoList[i].dwProgressID)
    end

    local nKillBossCount = 0
    for i = 1, #aProgressIDs do
		local nProgressID = aProgressIDs[i]
		local bHasKilled = GetDungeonRoleProgress(nMapID, g_pClientPlayer.dwID, nProgressID)
        nKillBossCount = nKillBossCount + (bHasKilled and 1 or 0)
    end

    return nKillBossCount == #aProgressIDs
end

function DungeonData.CloseDungeonProgressBar(szName)
	if not DungeonData.DungeonProgressInfoMap then
		return
	end

	DungeonData.DungeonProgressInfoMap[szName] = nil
end

function DungeonData.RequestResetMap(dwMapID, fCancel)
    local szName = UIHelper.GBKToUTF8(Table_GetMapName(dwMapID))

    local msg
    local bIsItemReset, nItemType, nItemID, nItemCount = CanResetMap(dwMapID)
    local hPlayer = GetClientPlayer()
    local bResetAward = false
    local tDungeonInfo = Table_GetDungeonInfo(dwMapID)
    if tDungeonInfo then
        local bRaid = tDungeonInfo.dwClassID ~= 1
        bResetAward = not bRaid or bIsItemReset
    end

    if hPlayer.GetScene().dwMapID == dwMapID then
        TipsHelper.ShowNormalTip("请离开当前秘境再重置该秘境", false)
        return
    end
    if not bIsItemReset then
        local _, _, _, _, _, nCostVigor = GetMapParams(dwMapID)
		if not hPlayer.IsVigorAndStaminaEnough(nCostVigor) then
            local szTips = g_tStrings.Dungeon.CYCLOPAEDIA_DUNGEON_RESET_FAILED_VIGOR..tostring(nCostVigor)..g_tStrings.Dungeon.STR_TYPE_POINT
			TipsHelper.ShowNormalTip(szTips, false)
			return
		end

        msg = string.format("重置%s，需要消耗%d精力，是否确认重置？该操作仅能重置自己的秘境进度。", szName, nCostVigor)
    elseif nItemType > 0 and nItemID > 0 then
        local itemInfo = ItemData.GetItemInfo(nItemType, nItemID)
        local szItemName = ItemData.GetItemNameByItemInfo(itemInfo)
        szItemName = UIHelper.GBKToUTF8(szItemName)
        local nDiamondR, nDiamondG, nDiamondB = GetItemFontColorByQuality(itemInfo.nQuality)
        szItemName = GetFormatText(szItemName, nil, nDiamondR, nDiamondG, nDiamondB)
        msg = string.format("重置%s秘境，需要消耗%d个道具%s ，是否确认重置？该操作仅能重置自己的秘境进度。", szName, nItemCount, szItemName)
    end
    if bResetAward then
        msg = msg .. "（重置后重新进入场景，秘境进度及首领会重新生成，再次击败后可以继续获得奖励）"
    else
        msg = msg .. "（重置后重新进入场景，秘境进度及首领会重新生成，但是已经击败过的首领不会再产生掉落，可在秘境大全-领奖记录查看）"
    end

    UIHelper.ShowConfirm(msg, function ()
        RemoteCallToServer("OnResetMapRequest", dwMapID)
        OnCheckAddAchievement(982, "Dungeon_First_Refresh")
        Timer.AddFrame(DungeonData, 5, function ()
            ApplyDungeonRoleProgress(dwMapID, UI_GetClientPlayerID())
        end)
    end, fCancel, true)
	OnCheckAddAchievement(982, "Dungeon_First_Refresh")
end

function DungeonData.CheckDungeonCondition(tParam)
    if not tParam then
        return true
    end
    if not tParam.dwTargetMapID then
        return true
    end
    local tRecord = Table_GetDungeonInfo(tParam.dwTargetMapID)
    if not tRecord then
        return false
    end
    if tRecord.bHideDetail then
        return false
    end

    return true
end


function DungeonData.IsStoryMode()
    return DungeonData.bStoryMode
end

function DungeonData.GetQuestIDByActivityID(dwActivityID)
    local tActivity = Table_GetCalenderActivity(dwActivityID)
    local tQuestID  = SplitString(tActivity.szQuestID, ";")
    if tonumber(tQuestID[1]) == -1 then
        return
    end
    tQuestID = ActivityData.GetShowQuestID(tQuestID, true)

    return tQuestID
end


function DungeonData.GetLootMoney(dwDoodadID)
    local scene = GetClientPlayer().GetScene()
    if not scene then
        return 0
    end

    return scene.GetLootMoney(dwDoodadID)
end

function DungeonData.GetLootItem(dwDoodadID, dwItemID)
    local scene = GetClientPlayer().GetScene()
    if not scene then
        return nil, 0
    end
    local tLootInfoList = scene.GetLootList(dwDoodadID)
    if not tLootInfoList or not tLootInfoList.nItemCount then
        return nil, 0
    end

    for i = 0, tLootInfoList.nItemCount - 1 do
		local tLootItem = tLootInfoList[i]
        if tLootItem and tLootItem.Item.dwID == dwItemID then
            return tLootItem, i
        end
    end

    return nil, 0
end

function DungeonData.GetLootItemByIndex(dwDoodadID, nLootItemIndex)
    local scene = GetClientPlayer().GetScene()
    if not scene then
        return nil
    end
    local tLootInfoList = scene.GetLootList(dwDoodadID)
    if not tLootInfoList or not tLootInfoList.nItemCount then
        return nil
    end

    return tLootInfoList[nLootItemIndex]
end

function DungeonData.DoodadGetLootItem(dwDoodadID, nLootItemIndex)
    local tLootItem = DungeonData.GetLootItemByIndex(dwDoodadID, nLootItemIndex)
    if not tLootItem then
        return nil, false, false, false
    end
    return tLootItem.Item,
        tLootItem.LootType == LOOT_ITEM_TYPE.NEED_ROLL,
        tLootItem.LootType == LOOT_ITEM_TYPE.NEED_DISTRIBUTE,
        tLootItem.LootType == LOOT_ITEM_TYPE.NEED_BIDDING
end

function DungeonData.IsLooter(dwDoodadID, dwPlayerID)
    local scene = GetClientPlayer().GetScene()
    if not scene then
        return false
    end
    local tLooterList = scene.GetLooterList(dwDoodadID) or {}
    if #tLooterList == 0 then
        return true
    end

    for _, tLooter in ipairs(tLooterList) do
        if tLooter.dwID == dwPlayerID then
            return true
        end
    end

    return false
end

function DungeonData.CanMobileLoot(dwDoodadID, dwItemID)
    local player = g_pClientPlayer
    if player.nMoveState == MOVE_STATE.ON_STAND and 0 ~= dwItemID then
        return false
    end
    if not DungeonData.IsLooter(dwDoodadID, UI_GetClientPlayerID()) then
        return false
    end

    if dwItemID == 0 then
        return true
    end

    local tLootItem = DungeonData.GetLootItem(dwDoodadID, dwItemID)
    if not tLootItem then
        return false
    end

    return tLootItem.LootType ~= LOOT_ITEM_TYPE.NEED_ROLL and
        tLootItem.LootType ~= LOOT_ITEM_TYPE.NEED_DISTRIBUTE and
        tLootItem.LootType ~= LOOT_ITEM_TYPE.NEED_BIDDING
end

function DungeonData.TryEnterDungeon(dwMapID, bStoryMode, bEntrance, nWindowID)
    if not dwMapID then
        return
    end
    if CheckPlayerIsRemote() then
        return
    end
    MapMgr.BeforeTeleport()

    local tSwtichMapInfo
    if nWindowID then tSwtichMapInfo = Table_GetSwitchMapInfo(dwMapID, nWindowID) end
    tSwtichMapInfo = tSwtichMapInfo or Table_GetDungeonSwitchMapInfo(dwMapID)

    local tDungeonInfo = Table_GetDungeonInfo(dwMapID)
    if tSwtichMapInfo then
        local szDifficulty = UIHelper.GBKToUTF8(tDungeonInfo.szLayer3Name)
        local szMapName = UIHelper.GBKToUTF8(tDungeonInfo.szOtherName)
        local szMode = "普通"
        local szExtra = ""
        if bStoryMode then
            szMode = "单人"
            if tDungeonInfo.dwClassID == 1 or tDungeonInfo.dwClassID == 2 then
                szExtra = g_tStrings.Dungeon.STR_TEAM_ENTER_STORY_MODE_EXTRA_TIP
            elseif tDungeonInfo.dwClassID == 3 then
                szExtra = g_tStrings.Dungeon.STR_RAID_ENTER_STORY_MODE_EXTRA_TIP
            end
        end

        --地图资源下载检测拦截
        if not PakDownloadMgr.UserCheckDownloadMapRes(dwMapID, function()
            DungeonData.TryEnterDungeon(dwMapID, bStoryMode, bEntrance, nWindowID)
        end, "秘境地图资源文件下载完成，是否前往[" .. szDifficulty..szMapName .. "]？") then
            return
        end

        local szContent = string.format("当前正在以%s模式进入%s，是否立即传入？%s", szMode, szDifficulty..szMapName, szExtra)
        if not bEntrance then
            local fOnSure = function ()
                if not bStoryMode then
                    RemoteCallToServer("On_Hero_DungeonStoryMode", tSwtichMapInfo.dwID, 1)
                else
                    RemoteCallToServer("On_Hero_DungeonStoryMode", tSwtichMapInfo.dwID, 2)
                end

                UIMgr.Close(VIEW_ID.PanelDungeonEntrance)
                UIMgr.Close(VIEW_ID.PanelRoadCollection)
                UIMgr.Close(VIEW_ID.PanelGongZhanSide)
                UIMgr.Close(VIEW_ID.PanelOperationCenter)
                UIMgr.Close(VIEW_ID.PanelSystemMenu)
                UIMgr.Close(VIEW_ID.PanelBenefits)
            end
            MapMgr.CheckTransferCDExecute(function()
                if bStoryMode then
                    UIHelper.ShowConfirm(szContent, function ()
                        fOnSure()
                    end)
                else
                    fOnSure()
                end
            end)
        else
            local fOnSure = function ()
                if not bStoryMode then
                    SelectSwitchMapWindow(tSwtichMapInfo.dwID)
                else
                    RemoteCallToServer("On_Hero_EnterDungeonByGate", tSwtichMapInfo.dwID)
                end

                UIMgr.Close(VIEW_ID.PanelDungeonEntrance)
                UIMgr.Close(VIEW_ID.PanelRoadCollection)
                UIMgr.Close(VIEW_ID.PanelSystemMenu)
                UIMgr.Close(VIEW_ID.PanelBenefits)
            end
            if bStoryMode then
                UIHelper.ShowConfirm(szContent, function ()
                    fOnSure()
                end)
            else
                fOnSure()
            end
        end

    end
end

function DungeonData.IsLeader()
	local hTeam   = GetClientTeam()
	local hPlayer = GetClientPlayer()

	if not hTeam or not hPlayer then
		return
	end

	if hTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER) == hPlayer.dwID then
		return true
	end

	return false
end

function DungeonData.GetMapInfoListByWindowID(nWindowID)
    local tMapInfoList = {}

    local tSwitchMapInfoList = SwitchMapList[nWindowID]
    for _, tSwitchMapInfo in pairs(tSwitchMapInfoList) do
        local szMapName = UIHelper.GBKToUTF8(tSwitchMapInfo.Name)
        local szImagePath = ""
        if tSwitchMapInfo.CardImagePath and tSwitchMapInfo.CardImagePath ~= "" then
            szImagePath = tSwitchMapInfo.CardImagePath
            szImagePath = string.gsub(szImagePath, "ui\\Image\\WorldMap\\SwitchMap\\", "Resource/MapCard/")
            szImagePath = string.gsub(szImagePath, ".UITex", string.format("_%d.png", tSwitchMapInfo.CardImageFrame))
        else
            szImagePath = tSwitchMapInfo.FBImagePath
            szImagePath = string.gsub(szImagePath, "ui\\Image\\Dungeon\\DungeonImage\\", "Resource/MapCard/")
            szImagePath = string.gsub(szImagePath, ".UITex", ".png")
        end
        local tMapInfo = {
            szMapName = szMapName,
            szImagePath = szImagePath,
            nMapType = 1,
            tMapIDList = {},
        }
        if tSwitchMapInfo.MapID then
            tMapInfo.nMapType = 2
            table.insert(tMapInfo.tMapIDList, tSwitchMapInfo.MapID)
        end
        for _, tInfo in ipairs(tSwitchMapInfo.child or {}) do
            table.insert(tMapInfo.tMapIDList, tInfo.MapID)
        end
        table.insert(tMapInfoList, tMapInfo)
    end

    -- table.sort(tMapInfoList, function (tInfo1, tInfo2)
    --     return tInfo1.nSortIndex < tInfo2.nSortIndex
    -- end)

	return tMapInfoList
end

function DungeonData.GetDungeonDifficultyID(szLayer3Name)
    local nStart = string.find(szLayer3Name, "挑战")
    if nStart and nStart > 0 then return 2 end
    nStart = string.find(szLayer3Name, "英雄")
    if nStart and nStart > 0 then return 3 end

    return 1
end

function DungeonData.UpdateSceneProgress(dwMapID, nMapCopyIndex, tbProgress)
    if not DungeonData.tbProgress then
        DungeonData.tbProgress = {}
    end

    if not DungeonData.tbProgress[dwMapID] then
        DungeonData.tbProgress[dwMapID] = {}
    end

    DungeonData.tbProgress[dwMapID] = tbProgress
    Event.Dispatch("OnUpdateSceneProgress")
end

function DungeonData.GetBossProgress(nMapID, nProgressID)
    local bKill = false
    if DungeonData.tbProgress and DungeonData.tbProgress[nMapID] and DungeonData.tbProgress[nMapID][nProgressID] then
        bKill = true
    end
    return bKill
end

function DungeonData.GetBossListByMapID(nMapID)
    if not DungeonData.tbBossList then
        DungeonData.InitBossList()
    end
    return DungeonData.tbBossList[nMapID]
end

function DungeonData.InitBossList()
    DungeonData.tbBossList = {}
    for nIndex, tbBossInfo in ipairs(MiddlemapDungeonBossTab) do
        local nMapID = tbBossInfo.nMapID
        if not DungeonData.tbBossList[nMapID] then
            DungeonData.tbBossList[nMapID] = {}
        end
        table.insert(DungeonData.tbBossList[nMapID], tbBossInfo)
    end
end

function DungeonData.GetBossKillProgress(nMapID)
    local nCount = 0
    local tbBossList = DungeonData.GetBossListByMapID(nMapID) or {}
    for nIndex, tbBossInfo in ipairs(tbBossList) do
        local bHasKilled = DungeonData.GetBossProgress(nMapID, tbBossInfo.nProgress)
        if bHasKilled then
            nCount = nCount + 1
        end
    end
    return nCount, #tbBossList
end

function DungeonData.GetCurrentMapBossProgress()
    local player = g_pClientPlayer
	if player then
		local dwMapID = player.GetMapID()
		local nKillCount, nTotalCount = DungeonData.GetBossKillProgress(dwMapID)
        return nKillCount, nTotalCount
	end
    return 0, 0
end

function DungeonData.GetFirstUnKillBoss(dwMapID)
    local tbBossList = DungeonData.GetBossListByMapID(dwMapID)
    if not tbBossList then return end
    for nIndex, tbBossInfo in ipairs(tbBossList) do
        local bHasKilled = DungeonData.GetBossProgress(dwMapID, tbBossInfo.nProgress)
        if not bHasKilled then
            return tbBossInfo
        end
    end
    return tbBossList[#tbBossList]--都杀死了返回最后一个Boss信息
end

function DungeonData.RemoteGetSceneProgress()
    local player = g_pClientPlayer
	if player then
		local dwMapID = player.GetMapID()
        local tbBossList = DungeonData.GetBossListByMapID(dwMapID)
        if not tbBossList then return end
        local tbPogressID = {}
        for nIndex, tbBossInfo in ipairs(tbBossList) do
            table.insert(tbPogressID, tbBossInfo.nProgress)
        end

        local player  = g_pClientPlayer
        local hScene  = player.GetScene()
        RemoteCallToServer("OnGetSceneProgress", dwMapID, hScene.nCopyIndex, tbPogressID)
    end
end

function DungeonData.IsHeadMatchFlag(tHeadInfo, nFlag)
    for _, tRecord in ipairs(tHeadInfo.tRecordList) do
        if DungeonData.tbFlagMap[tRecord.dwMapID] == nFlag then return true end
    end

    return false
end

function DungeonData.IsHeadMatchWishItem(tHeadInfo)
    for _, tRecord in ipairs(tHeadInfo.tRecordList) do
        if DungeonData.tWishItemSource[tRecord.dwMapID] then return true end
    end

    return false
end

function DungeonData.CheckSpecialOtherOrItem(tItem)
    if IsTableEmpty(tItem) then
        return
    end
    local bCollt = false
    for k, v in ipairs(tItem) do
        local tTemp = {dwIndex = v[2], dwTabType = v[1],}
        bCollt = DungeonData.GetItemCollectState(tTemp)
        if bCollt then
            return true
        end
    end
    return bCollt
end

function DungeonData.CheckSpecialAllAndItem(tItem)
    if IsTableEmpty(tItem) then
        return
    end
    local bCollt = true
    for k, v in ipairs(tItem) do
        local tTemp = {dwIndex = v[2], dwTabType = v[1],}
        bCollt = DungeonData.GetItemCollectState(tTemp) or false
        if not bCollt then
            return false
        end
    end
    return bCollt
end

function DungeonData.GetItemCollectState(tItem)

    return ItemData.GetGeneralItemCollectState(tItem.dwTabType, tItem.dwIndex)
end

function DungeonData.GetWishItemCollectState(tWishItem)
    local bCollect
    if tWishItem.tOrItem and not IsTableEmpty(tWishItem.tOrItem) then
        bCollect = DungeonData.CheckSpecialOtherOrItem(tWishItem.tOrItem)
    elseif tWishItem.tAndItem and not IsTableEmpty(tWishItem.tAndItem) then
        bCollect = DungeonData.CheckSpecialAllAndItem(tWishItem.tAndItem)
    else
        bCollect = DungeonData.GetItemCollectState(tWishItem)
    end

    return bCollect
end

function DungeonData.GetWishItemListByCategory(nCategory, nCanWishFlag)
    nCanWishFlag = nCanWishFlag or 0
    local tRes = {}
    local tAllItemInfo = DungeonData.tAllItemInfo or Table_GetWishItemInfoList()
    if nCategory and nCategory > 0 then tAllItemInfo = DungeonData.tMapItemList[nCategory] end

    for _, tWishItem in pairs(tAllItemInfo) do
        local bCanWish = DungeonData.CanWishItem(tWishItem)
        local bMatchCanWishFlag = nCanWishFlag == 0 or (nCanWishFlag == 1 and bCanWish) or (nCanWishFlag == 2 and not bCanWish)
        if bMatchCanWishFlag then table.insert(tRes, tWishItem) end
    end

    return tRes
end

function DungeonData.CanWishItem(tWishItem)
    if DungeonData.tWishInfo == nil then return false end

    if DungeonData.tWishInfo.nWishCoin < tWishItem.nCostWish then return false end
    if DungeonData.GetWishItemCollectState(tWishItem) then return false end

    return true
end

function DungeonData.GetWishItemSourceList()
    local tWishInfo = GDAPI_GetSpecialWishInfo()
    if not tWishInfo or IsTableEmpty(tWishInfo) or tWishInfo.nWishIndex == 0 then
        return {}
    end
	local tItem = Table_GetWishItemInfoByID(tWishInfo.nWishIndex)
	if not tItem then
		return {}
	end
	local tSource = ItemData.GetItemSourceList(tItem.dwTabType, tItem.dwIndex).tBoss
    return tSource
end

function DungeonData.IsWishItem(nIndex)
    if DungeonData.tWishInfo == nil then return false end

    return DungeonData.tWishInfo.nWishIndex == nIndex
end

function DungeonData.IsWishItemByItemInfo(dwTabType, dwIndex)
    if DungeonData.tWishInfo == nil then return false end

    local tItem = Table_GetWishItemInfoByID(DungeonData.tWishInfo.nWishIndex)
    if not tItem then return false end

    local tOther = tItem.tAndItem or tItem.tOrItem
    if tOther then
		for k, v in ipairs(tOther) do
			local dwOtherType, dwOtherIndex = v[1], v[2]
            if dwOtherType == dwTabType and dwOtherIndex == dwIndex then
                return true
            end
		end
    end

    return tItem.dwTabType == dwTabType and tItem.dwIndex == dwIndex
end

function DungeonData.CanWishItemFlash()
    if DungeonData.tWishInfo == nil or DungeonData.tWishInfo.nWishIndex > 0 then return false end

    local tItemList = DungeonData.GetWishItemListByCategory(0, 1) or {}
    return #tItemList > 0
end

function DungeonData.DoCollectItem(dwID, bCollect)
    local tCollectList = GDAPI_GetSpecialWishCollectList()
    if bCollect and #tCollectList >= STAR_ITEM_MAX_NUM then
        TipsHelper.ShowNormalTip("祈愿物品最多可收藏三个")
        return
    end
    if bCollect and #tCollectList < STAR_ITEM_MAX_NUM and not table.contain_value(tCollectList, dwID) then
        table.insert(tCollectList, dwID)
        RemoteCallToServer("On_SpecialWish_ChangeCollect", tCollectList)
    elseif not bCollect and #tCollectList > 0 and table.contain_value(tCollectList, dwID) then
        table.remove_value(tCollectList, dwID)
        RemoteCallToServer("On_SpecialWish_ChangeCollect", tCollectList)
    end
end

local function OnMapProgressNotify(dwMapID, nCopyIndex, tpbyProgress)
    if not dwMapID or not nCopyIndex or not tpbyProgress then return end

    local tbProgress = {}
    for nIndex, nValue in ipairs(tpbyProgress) do
        tbProgress[nValue] = true
    end
    DungeonData.UpdateSceneProgress(dwMapID, nCopyIndex, tbProgress)
end

Event.Reg(DungeonData, EventType.OnViewClose, function (nViewID)
    if nViewID == VIEW_ID.PanelLoading then
        local player = g_pClientPlayer
        DungeonData.tBalanceShipInfo = {}
        if DungeonData.bStoryMode then
            BubbleMsgData.PushMsgWithType("DungeonStoryMode", {
                szType = "DungeonStoryMode", 		-- 类型(用于排重)
                nBarTime = 0, 							-- 显示在气泡栏的时长, 单位为秒
                szContent = function ()
                    local szContent = ""
                    return szContent, 0.5
                end,
                szAction = function ()
                    local script = UIMgr.GetViewScript(VIEW_ID.PanelMainCity)
                    if script then
                        TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips, script.scriptRightTopInfo._rootNode, g_tStrings.Dungeon.STR_STORY_MODE_TIP)
                    end
                end,
            })
        end

        local scene = player and player.GetScene()
        if scene then
            local tRecord = Table_GetDungeonInfo(scene.dwMapID)
            if tRecord then
                local bIsOpen = UIMgr.IsViewOpened(VIEW_ID.PanelPassage)
                if not bIsOpen and DungeonData.bStoryMode then
                    UIMgr.Open(VIEW_ID.PanelPassage)
                end
            end
        end
    end
end)

Event.Reg(DungeonData, "On_Update_StoryMode", function ()
    local player = g_pClientPlayer
    local bStoryMode = player and player.IsHaveBuff(BUFF_UI, 1)
    DungeonData.bStoryMode = bStoryMode
    if not DungeonData.bStoryMode then
        BubbleMsgData.RemoveMsg("DungeonStoryMode")
    end
end)

Event.Reg(DungeonData, "On_FB_UseStoryMode", function (dwMapID)
    if DungeonData.dwWaitingEnterWindowID then
        SelectSwitchMapWindow(DungeonData.dwWaitingEnterWindowID)
        DungeonData.dwWaitingEnterWindowID = nil
    end
end)

Event.Reg(DungeonData, EventType.OnResetMapRespond, function (tData)
    local tResetFailMapID = tData or {}
    for dwMapID, nRetCode in pairs(tResetFailMapID) do
        local _, nMapType = GetMapParams(dwMapID)
        if nMapType and nMapType == MAP_TYPE.DUNGEON then
            local szMsg = g_tStrings.Dungeon.tResetResult[nRetCode]
            TipsHelper.ShowNormalTip(szMsg, false)
        end
    end
end)

Event.Reg(DungeonData, EventType.OnClientPlayerEnter, function ()
    if DungeonData.IsInDungeon() then
        Event.Dispatch(EventType.OnSelectedTaskTeamViewToggle, false)
    end
end)

Event.Reg(DungeonData, EventType.On_Update_GeneralProgressBar, function(tbInfo)
    if ActivityData.IsHotSpringActivity() then
        DungeonData.tDungeonProgressInfoMap = DungeonData.tDungeonProgressInfoMap or {}
        DungeonData.tDungeonProgressInfoMap[tbInfo.szName] = tbInfo
        tbInfo.nPercent = 100
        if tbInfo.nDenominator then
            tbInfo.nPercent = tbInfo.nMolecular / tbInfo.nDenominator*100
        end
    end
end)

Event.Reg(DungeonData, EventType.On_Delete_GeneralProgressBar, function(szName)
    if ActivityData.IsHotSpringActivity() then
        DungeonData.tDungeonProgressInfoMap = DungeonData.tDungeonProgressInfoMap or {}
        DungeonData.tDungeonProgressInfoMap[szName] = nil
    end
end)

Event.Reg(DungeonData, "ON_FORCE_SYNC_PLAYER_MAP_PROGRESS", function(dwMapID, nCopyIndex, nLeftTime, tpbyProgress)
    OnMapProgressNotify(dwMapID, nCopyIndex, tpbyProgress)
end)

Event.Reg(DungeonData, "ON_MAP_PROGRESS_NOTIFY", function(dwMapID, nCopyIndex, tpbyProgress)
    OnMapProgressNotify(dwMapID, nCopyIndex, tpbyProgress)
end)

Event.Reg(DungeonData, "DIFFERENT_MAP_COPY_NOTIFY", function(dwMapID)
    local hPlayer = GetClientPlayer()
    if not hPlayer then return end

    local bIsItemReset, nItemType, nItemID, nItemCount = CanResetMap(dwMapID)
    local bResetAward = false
    local tDungeonInfo = Table_GetDungeonInfo(dwMapID)
    if tDungeonInfo then
        local bRaid = tDungeonInfo.dwClassID ~= 1
        bResetAward = not bRaid or bIsItemReset
    end

    local msg = ""
    if not bIsItemReset then
        local _, _, _, _, _, nCostVigor = GetMapParams(dwMapID)
		if not hPlayer.IsVigorAndStaminaEnough(nCostVigor) then
            local szTips = g_tStrings.Dungeon.CYCLOPAEDIA_DUNGEON_RESET_FAILED_VIGOR..tostring(nCostVigor)..g_tStrings.Dungeon.STR_TYPE_POINT
			TipsHelper.ShowNormalTip(szTips, false)
			return
		end

        msg = string.format(g_tStrings.Dungeon.DIFFERENT_MAP_COPY_NOTIFY_COST_VIGOR, nCostVigor)
    elseif nItemType > 0 and nItemID > 0 then
        local itemInfo = ItemData.GetItemInfo(nItemType, nItemID)
        local szItemName = ItemData.GetItemNameByItemInfo(itemInfo)
        szItemName = UIHelper.GBKToUTF8(szItemName)
        local nDiamondR, nDiamondG, nDiamondB = GetItemFontColorByQuality(itemInfo.nQuality)
        szItemName = GetFormatText(szItemName, nil, nDiamondR, nDiamondG, nDiamondB)
        msg = string.format(g_tStrings.Dungeon.DIFFERENT_MAP_COPY_NOTIFY_COST_ITEM, nItemCount, szItemName)
    end
    if bResetAward then
        msg = msg .. "（重置后重新进入场景，秘境进度及首领会重新生成，再次击败后可以继续获得奖励）"
    else
        msg = msg .. "（重置后重新进入场景，秘境进度及首领会重新生成，但是已经击败过的首领不会再产生掉落，可在秘境大全-领奖记录查看）"
    end

    UIHelper.ShowConfirm(msg, function ()
        RemoteCallToServer("OnResetMapRequest", dwMapID)
    end, nil, true)
end)