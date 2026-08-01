-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: ExtractWareHouseData
-- Date: 2025-03-24 15:26:06
-- Desc: ?
-- ---------------------------------------------------------------------------------
local REMOTE_DATA_ID = 1183
local MAX_WAREHOUSE_ZONE = 128
local MAX_PERSET_ZONE = 60
local EQUIPMENT_SUB_TO_SLOT = {
    [EQUIPMENT_SUB.MELEE_WEAPON] = 1,
    [EQUIPMENT_SUB.RANGE_WEAPON] = 2,
    [EQUIPMENT_SUB.CHEST] = 3,
    [EQUIPMENT_SUB.HELM] = 4,
    [EQUIPMENT_SUB.AMULET] = 5,
    [EQUIPMENT_SUB.RING] = 6,
    [EQUIPMENT_SUB.WAIST] = 8,
    [EQUIPMENT_SUB.PENDANT] = 9,
    [EQUIPMENT_SUB.PANTS] = 10,
    [EQUIPMENT_SUB.BOOTS] = 11,
    [EQUIPMENT_SUB.BANGLE] = 12,
}
local SUB_TYPE_START_END = {
    [ExtractItemSub.MEDICINE] = {1, 2},
    [ExtractItemSub.WENPOS] = {3, 4},
    [ExtractItemSub.ARMOR] = {5, 10},
    [ExtractItemSub.ACCESSORIES] = {11, 13},
    [ExtractItemSub.INVISIBILITY] = {14, 14},
    [ExtractItemSub.OTHER] = {15, 15},
}
ExtractWareHouseData = ExtractWareHouseData or {className = "ExtractWareHouseData"}
local self = ExtractWareHouseData

-- 主干屏蔽
local nXunBaoActivityID = 993
function ExtractWareHouseData.IsDisable()
    local bDisable = true
    local bTestMode = IsDebugClient()
    local bExp = Version.IsEXP()
    if IsActivityOn(nXunBaoActivityID) and (bTestMode or bExp) then
        bDisable = false
    end
    return bDisable
end

local tbIgnoreViewIDs = {
    VIEW_ID.PanelConstructionMain,
}
function ExtractWareHouseData.OpenExtractPersetPanel(nType, dwDoodadID)
	local nPageLen = UIMgr.GetLayerStackLength(UILayer.Page, tbIgnoreViewIDs)
	local nPopLen = UIMgr.GetLayerStackLength(UILayer.Popup)
	local nMsgBoxLen = UIMgr.GetLayerStackLength(UILayer.MessageBox)

	if UIMgr.IsViewOpened(VIEW_ID.PanelBattleFieldXunBao) then
		return
	elseif nPageLen > 0 or nPopLen > 0 or nMsgBoxLen > 0 then
        if UIMgr.IsViewOpened(VIEW_ID.PanelImpasseMatching) then
            Event.Reg(self, EventType.OnViewClose, function (nViewID)
                if nViewID == VIEW_ID.PanelBattleFieldXunBao then
                    Event.UnReg(self, EventType.OnViewClose)
                    UIHelper.ShowConfirm(g_tStrings.STR_ON_XUNBAO_RETURN_TO_MATCH, function ()
                        UIMgr.Open(VIEW_ID.PanelImpasseMatching, nil, 8)
                    end)
                end
            end)
        end
		UIMgr.CloseAllInLayer(UILayer.Page)
		UIMgr.CloseAllInLayer(UILayer.Popup)
		UIMgr.CloseAllInLayer(UILayer.MessageBox)
	end
	UIMgr.Open(VIEW_ID.PanelBattleFieldXunBao, nType, dwDoodadID)
end

---------------------调试接口-----------------------
function ExtractWareHouseData.OpenSettlementPanel(nTime, nMatchResult)
    Timer.AddCountDown(self, nTime or 5, function (nRemain)
        UIGlobalFunction["GeneralCounterSFX.RefleshCounter"](2, nRemain)
    end, function ()
        Event.Dispatch(EventType.ShowExtractSettlement, {
            nTotalPrice = 88888, --总价钱
            nBPAddExp = 50, --这把BP加了多少经验
            nLeaveTime = GetCurrentTime() + 30,
            nMatchResult = nMatchResult or 1,
            tSoldItems = {
                {dwTabType = 5, dwIndex = 25500, nCount = 10, nPrice = 128},
                {dwTabType = 5, dwIndex = 25500, nCount = 10, nPrice = 128},
            },
            tStoredItems = {--进入仓库的物品（塞个飞沙令）
            {dwTabType = 5, dwIndex = 25500, nCount = 10},
            {dwTabType = 5, dwIndex = 25500, nCount = 10},
        }})
    end)
end

function ExtractWareHouseData.ShowRescueTime(nTime)
    nTime = nTime or 60

    local hTeam = GetClientTeam()
	local nGroupNum = hTeam.nGroupNum
	for i = 0, nGroupNum - 1 do
		local tGroupInfo = hTeam.GetGroupInfo(i)
		if tGroupInfo and tGroupInfo.MemberList then
			for _, dwID in pairs(tGroupInfo.MemberList) do
				Event.Dispatch("ON_UPDATE_RESCUE_TIME", dwID, nTime + GetCurrentTime())
			end
		end
	end

    UIGlobalFunction["Navigator.AddTemporaryPoint"](g_pClientPlayer.GetMapID(), {fX = g_pClientPlayer.nX, fY = g_pClientPlayer.nY, fZ = g_pClientPlayer.nZ}, "Re" .. g_pClientPlayer.dwID, 1,g_pClientPlayer.szName)
end

function ExtractWareHouseData.ShowExtractCounter(nCount)
    nCount = nCount or 20
    Timer.AddCountDown(self, nCount, function (nRemain)
        UIGlobalFunction["GeneralCounterSFX.RefleshCounter"](2, nRemain)
    end)
end

function ExtractWareHouseData.ShowRemainingTime(nSecond)
    nSecond = nSecond or 120
    UIGlobalFunction["RemainingTimeNotify.Open"](nSecond)
end

function ExtractWareHouseData.ShowMapEvent(nIndex)
    nIndex = nIndex or 43
    UIGlobalFunction["InterludePanel.Open"](nIndex)
end

---------------------调试接口-----------------------

function ExtractWareHouseData.GetExtractViewType()
    local nType = ExtractViewType.PersetAndWareHouse
    if BattleFieldData.IsInXunBaoBattleFieldMap() then
        nType = ExtractViewType.BagAndLoot
    end

    return nType
end
-------------------------------- 消息定义 --------------------------------
function ExtractWareHouseData.Init()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    ExtractWareHouseData.bInitData = false
    ExtractWareHouseData.szSearch = ""
    ExtractWareHouseData.tWare = {}
    ExtractWareHouseData.tEquip = {}
    ExtractWareHouseData.tPerset = {}
    ExtractWareHouseData.nCoin = 0
    ExtractWareHouseData.nWareUnlock = 0
    ExtractWareHouseData.nPersetUnlock = 0
    ExtractWareHouseData.nPersetSafe = 0
    ExtractWareHouseData.RegEvent()

    if not pPlayer.HaveRemoteData(REMOTE_DATA_ID) then
        pPlayer.ApplyRemoteData(REMOTE_DATA_ID, REMOTE_DATA_APPLY_EVENT_TYPE.CLIENT_APPLY_SERVER_CALL_BACK)
    else
        ExtractWareHouseData.Update(true)
    end
end

function ExtractWareHouseData.RegEvent()
    Event.Reg(self, EventType.OnTBFUpdateAllView, function ()
        ExtractWareHouseData.Update(true)
        Event.Dispatch(EventType.UpdateTBFWareHouse)
    end)
end

function ExtractWareHouseData.Update(bUpdateAll)
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    ExtractWareHouseData.tbData = GDAPI_TbfWareAllInfo()
    ExtractWareHouseData.nPersetValue = GDAPI_TbfWarePreValue()
    ExtractWareHouseData.nBagValue = GDAPI_TbfWareGetPackageValue()
    ExtractWareHouseData.nEquipValue = GDAPI_TbfWareGetCurEquipValue()
    ExtractWareHouseData.nCoin = pPlayer.nExamPrint

    if bUpdateAll then
        ExtractWareHouseData.UpdateWareData()
        ExtractWareHouseData.UpdateEquipData()
        ExtractWareHouseData.UpdatePersetData()
    end
    ExtractWareHouseData.bInitData = true
end

function ExtractWareHouseData.UpdateWareData()
    local tInfo = ExtractWareHouseData.tbData
    if not tInfo then
        return
    end

    local tWare = tInfo.tWare
    ExtractWareHouseData.tWare = {}
    for i = 1, #tWare do
        local tItem = tWare[i]
        local dwTabType, dwItemIndex, nNum = tItem[1], tItem[2], tItem[3]
        local tInsert = {nType = dwTabType, dwIndex = dwItemIndex, nNum = nNum}
        ExtractWareHouseData.tWare[i] = tInsert
    end
    ExtractWareHouseData.nWareUnlock = tInfo.nWareUnlock
end

function ExtractWareHouseData.UpdateEquipData()
    local tInfo = ExtractWareHouseData.tbData
    if not tInfo then
        return
    end

    local tEquip = tInfo.tEquip or {}
    ExtractWareHouseData.tEquip = {}
    for i = 1, #tEquip do
        local tItem = tEquip[i]
        local dwTabType, dwItemIndex, nNum = tItem[1], tItem[2], tItem[3]
        local tInsert = {dwTabType = dwTabType, dwIndex = dwItemIndex, nNum = nNum}
        ExtractWareHouseData.tEquip[i] = tInsert
    end
end

function ExtractWareHouseData.UpdatePersetData()
    local tInfo = ExtractWareHouseData.tbData
    if not tInfo then
        return
    end

    local tPerset = tInfo.tBag
    ExtractWareHouseData.tPerset = {}
    for i = 1, #tPerset do
        local tItem = tPerset[i]
        local dwTabType, dwItemIndex, nNum = tItem[1], tItem[2], tItem[3]
        local tInsert = {nType = dwTabType, dwIndex = dwItemIndex, nNum = nNum}
        ExtractWareHouseData.tPerset[i] = tInsert
    end
    ExtractWareHouseData.nPersetUnlock = tInfo.nBagUnlock
    ExtractWareHouseData.nPersetSafe = tInfo.nBagSafe
end

function ExtractWareHouseData.SetSearchText(szText)
    ExtractWareHouseData.szSearch = szText
end

function ExtractWareHouseData.UnInit()
    ExtractWareHouseData.bInitData = nil
    ExtractWareHouseData.szSearch = nil
    ExtractWareHouseData.tWare = nil
    ExtractWareHouseData.tEquip = nil
    ExtractWareHouseData.tPerset = nil
    ExtractWareHouseData.nWareUnlock = nil
    ExtractWareHouseData.nPersetUnlock = nil
    ExtractWareHouseData.nPersetSafe = nil
end

function ExtractWareHouseData.GetBoxInfo(nWareType, nSlot)
    local nItemType, nItemIndex, nItemNum = 0, 0, 0
    nItemType, nItemIndex, nItemNum = GDAPI_TbfWareGetItemInfoBySlot(nWareType, nSlot)
    return nItemType, nItemIndex, nItemNum
end

local function fnGetFirstEmptySlot(tbInfo)
    local _, key = table.find_if(tbInfo, function (v)
        return v.nType == 0 and v.dwIndex == 0
    end)

    return key
end

function ExtractWareHouseData.SaveAllToWare()
    local tClass = {}

    local function IsBagCanStoreAll()
        local bCanStore = false
        local bWareHouseEmpty = not not fnGetFirstEmptySlot(ExtractWareHouseData.tWare or {})
        if not bWareHouseEmpty then
            return bCanStore
        end

        for _, tbItemInfo in ipairs(ItemData.GetItemList(ItemData.BoxSet.Bag)) do
            local item = ItemData.GetItemByPos(tbItemInfo.nBox, tbItemInfo.nIndex)
            if item and item.nAucGenre == AUC_GENRE.DESERT then
                bCanStore = true
                break
            end
        end
        return bCanStore
    end

    if not IsBagCanStoreAll() then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_LOCKER_CANSTORE_ALL_EXTRACT)
        return
    end

    RemoteCallToServer("On_JueJing_SaveAllItemB2W")
    OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_LOCKER_TRY_STORE)
end

function ExtractWareHouseData.SaveToWareHouse(bFromBag, nType, nIndex, nTargetPos, nNum)
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    local nCount = 1
    if bFromBag then
        local item = ItemData.GetPlayerItem(pPlayer, nType, nIndex)
        if item.bCanStack then
            nCount = nNum or item.nStackNum
        end
        RemoteCallToServer("On_JueJing_SaveItemB2W", item.dwTabType, item.dwIndex, nCount, ExtractItemType.WareHouse, nTargetPos)
    else
        nTargetPos = nTargetPos or fnGetFirstEmptySlot(ExtractWareHouseData.tWare)
        RemoteCallToServer("On_JueJing_MoveItem", nType, nIndex, ExtractItemType.WareHouse, nTargetPos, nNum)
    end
end

function ExtractWareHouseData.SaveToPerset(nType, nIndex, nTargetPos, nNum)
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    if nType == ExtractItemType.Perset then
        return
    end

    local nItemType, nItemIndex = ExtractWareHouseData.GetBoxInfo(nType, nIndex)
    if nItemType <= 0 or nItemIndex <= 0 then
        return
    end

    nTargetPos = nTargetPos or fnGetFirstEmptySlot(ExtractWareHouseData.tPerset)
    RemoteCallToServer("On_JueJing_MoveItem", nType, nIndex, ExtractItemType.Perset, nTargetPos, nNum)
end

local function _GetRingSlot()
    local nTargetPos = EQUIPMENT_SUB_TO_SLOT[EQUIPMENT_SUB.RING]

    local tbRings = {}
    for i = 1, 2 do
        local nRingPos = EQUIPMENT_SUB_TO_SLOT[EQUIPMENT_SUB.RING] + i - 1
        local nItemType, nItemIndex = ExtractWareHouseData.GetBoxInfo(ExtractItemType.Equip, nRingPos)
        if nItemType > 0 and nItemIndex > 0 then
            tbRings[nRingPos] = {nItemType = nItemType, nItemIndex = nItemIndex}
        elseif nItemType <= 0 and nItemIndex <= 0 then
            nTargetPos = nRingPos
            break
        end
    end

    local tbWorseRing
    for nPos, value in pairs(tbRings) do
        local itemInfo = GetItemInfo(value.nItemType, value.nItemIndex)
        if not tbWorseRing then
            tbWorseRing = itemInfo
        elseif tbWorseRing.nQuality > itemInfo.nQuality then
            nTargetPos = nPos
        end
    end

    return nTargetPos
end

function ExtractWareHouseData.SaveToEquip(nType, nIndex)
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    local nItemType, nItemIndex = ExtractWareHouseData.GetBoxInfo(nType, nIndex)
    if nItemType <= 0 or nItemIndex <= 0 then
        return
    end

    local itemInfo = GetItemInfo(nItemType, nItemIndex)
    local nTargetPos = EQUIPMENT_SUB_TO_SLOT[itemInfo.nSub]
    if itemInfo.nSub == EQUIPMENT_SUB.RING then
        nTargetPos = _GetRingSlot(itemInfo.nSub)
    end

    RemoteCallToServer("On_JueJing_MoveItem", nType, nIndex, ExtractItemType.Equip, nTargetPos)
end
-------------------工具函数------------------------

function ExtractWareHouseData.IsWeaponBox(dwTabType, dwIndex)
    local itemInfo = GetItemInfo(dwTabType, dwIndex)
    if not itemInfo then
        return false
    end
    return itemInfo.nAucGenre == AUC_GENRE.DESERT and ExtractWareHouseData.GetItemSubType(itemInfo.nAucSub) == ExtractItemSub.WENPOS
end

function ExtractWareHouseData.EquipIsHave(dwTabType, dwIndex)
    local bHave = false
    local nWareType, nWareSlot
    local nBox, nIndex

    nWareType = ExtractItemType.WareHouse
    nWareSlot = select(2, table.find_if(ExtractWareHouseData.tWare, function (tbInfo)
        return tbInfo.nType == dwTabType and tbInfo.dwIndex == dwIndex
    end)) or nil

    if not nWareSlot then
        nWareType = ExtractItemType.Perset
        nWareSlot = select(2, table.find_if(ExtractWareHouseData.tPerset, function (tbInfo)
            return tbInfo.nType == dwTabType and tbInfo.dwIndex == dwIndex
        end)) or nil
    end

    nBox, nIndex = ItemData.GetItemPos(dwTabType, dwIndex)
    if nBox == 27 then
        -- 装备在吃鸡背包内，清掉
        nBox, nIndex = nil, nil
    end

    bHave = ((not not nWareSlot) or (nBox ~= nil and nIndex ~= nil)) or false
    return bHave, nWareType, nWareSlot, nBox, nIndex
end

function ExtractWareHouseData.IsEquiped(nEquipType, dwTabType, dwIndex)
    local bEquiped = false
    local tEquip = ExtractWareHouseData.tEquip[nEquipType]
    if not tEquip then
        return
    end

    bEquiped = tEquip.dwTabType == dwTabType and tEquip.dwIndex == dwIndex
    return bEquiped
end

function ExtractWareHouseData.GetItemList(nType)
    if nType == ExtractItemType.WareHouse then
        return ExtractWareHouseData.tWare
    elseif nType == ExtractItemType.Equip then
        return ExtractWareHouseData.tEquip
    elseif nType == ExtractItemType.Perset then
        return ExtractWareHouseData.tPerset
    end
end

function ExtractWareHouseData.GetMaxZone(nType)
    if nType == ExtractItemType.WareHouse then
        return MAX_WAREHOUSE_ZONE
    elseif nType == ExtractItemType.Perset then
        return MAX_PERSET_ZONE
    end
end

function ExtractWareHouseData.GetUnlockZone(nType)
    if nType == ExtractItemType.WareHouse then
        return ExtractWareHouseData.nWareUnlock
    elseif nType == ExtractItemType.Perset then
        return ExtractWareHouseData.nPersetUnlock
    end
end

function ExtractWareHouseData.GetPersetSafeZone()
    return ExtractWareHouseData.nPersetSafe
end

function ExtractWareHouseData.GetPersetValue()
    return ExtractWareHouseData.nPersetValue, ExtractWareHouseData.nBagValue, ExtractWareHouseData.nEquipValue
end

function ExtractWareHouseData.GetItemSubType(nAucSub)
    local nType
    for key, value in pairs(SUB_TYPE_START_END) do
        local nStart, nEnd = unpack(value)
        if nAucSub >= nStart and nAucSub <= nEnd then
            nType = key
            break
        end
    end

    return nType
end

function ExtractWareHouseData.GetItemValue(nType, nSlot, nNum)
    local nItemType, nItemIndex, nItemNum = ExtractWareHouseData.GetBoxInfo(nType, nSlot)
    local nValue = GDAPI_TbfWareSoldItemPrice(nItemType, nItemIndex, nNum) or 0

    return nValue
end
