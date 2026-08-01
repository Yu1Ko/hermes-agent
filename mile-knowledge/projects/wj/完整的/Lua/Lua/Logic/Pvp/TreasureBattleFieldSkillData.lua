-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: TreasureBattleFieldSkillData
-- Date: 2024-07-17 17:05:38
-- Desc: ?
-- ---------------------------------------------------------------------------------

local MAP_ID = 676
local DROP_REMOTE_CALL = "On_JueJing_DropSkill"
local DEFALUT_SKILL_CONF = {
    [1] = {
        nSkillID = 37687,
        nSkillLevel = 5,
    },
    [2] = {
        nSkillID = 101937,
        nSkillLevel = 1,
    },
    [3] = {
        nSkillID = 38381,
        nSkillLevel = 1,
    },
    [4] = {
        nSkillID = 38382,
        nSkillLevel = 1,
    },
}

local DEFALUT_SKILL_CONF_XUN_BAO = {
    [2] = {
        nSkillID = 101937,
        nSkillLevel = 1,
    },
    [3] = {
        nSkillID = 41281,
        nSkillLevel = 11,
    },
    [4] = {
        nSkillID = 41282,
        nSkillLevel = 4,
    },
}


local tBuff2SkillMap = {}
local tDynamicBoxInfo = {}
local nDynamicSkillCount = 6
local nDynamicSkillCount_Xunbao = 7
local tDefaultSkill = {}
local nDefaultSkillCount = 4
local tDefaultSkill_Xunbao = {}
local nDefaultSkillCount_Xunbao = 3
local tWaitAddSkill = nil

TreasureBattleFieldSkillData = TreasureBattleFieldSkillData or {className = "TreasureBattleFieldSkillData"}
local self = TreasureBattleFieldSkillData
-------------------------------- 消息定义 --------------------------------
TreasureBattleFieldSkillData.Event = {}
TreasureBattleFieldSkillData.Event.XXX = "TreasureBattleFieldSkillData.Msg.XXX"

function TreasureBattleFieldSkillData.Init()
    local tBuffItemList = GetToolBuffItemList()
    local tSkillItemList = GetToolSkillItemList()
    local tWeaponSkillList, _, tWeapon2ID = Table_GetDesertWeaponSkill()
    self.tbXunBaoSkillList = clone(tWeaponSkillList)
    self.tbWeapon2GroupID = clone(tWeapon2ID)

    for k, v in pairs(tBuffItemList) do
        tBuff2SkillMap[v] = tSkillItemList[k]
    end

    self.InitSkillList()
    for i = 1, nDefaultSkillCount do
        local conf = DEFALUT_SKILL_CONF[i]
        tDefaultSkill[i] = {
            nSkillID = conf.nSkillID,
            nSkillLevel = conf.nSkillLevel,
        }
    end

    for i = 1, nDefaultSkillCount_Xunbao, 1 do
        local conf = DEFALUT_SKILL_CONF_XUN_BAO[i + 1]
        tDefaultSkill_Xunbao[i + 1] = {
            nSkillID = conf.nSkillID,
            nSkillLevel = conf.nSkillLevel,
        }
    end
end

function TreasureBattleFieldSkillData.UnInit()

end

function TreasureBattleFieldSkillData.OnLogin()

end

function TreasureBattleFieldSkillData.OnFirstLoadEnd()

end

function TreasureBattleFieldSkillData.InitSkillList(bDragSkill)
    for i = 1, nDynamicSkillCount do
        tDynamicBoxInfo[i] = {bFree = true}
    end
    tWaitAddSkill = nil
end

function TreasureBattleFieldSkillData.UpdateSkill(nSkillID, nSkillLevel, bAdd)
    if bAdd then
        for i = 1, #tDynamicBoxInfo do
            local tInfo = tDynamicBoxInfo[i]
            if tInfo.nSkillID == nSkillID and tInfo.nSkillLevel == nSkillLevel then
                return
            end
        end
        local nArrayIndex
        if tWaitAddSkill then
            nArrayIndex = self.GetDynamicSkillArrayIndexByIndex(tWaitAddSkill.nIndex)
        else
            for i = 1, #tDynamicBoxInfo do
                local tInfo = tDynamicBoxInfo[i]
                if IsTableEmpty(tInfo) or tInfo.bFree then
                    nArrayIndex = i
                    break
                end
            end
        end
        tDynamicBoxInfo[nArrayIndex].nSkillID = nSkillID
        tDynamicBoxInfo[nArrayIndex].nSkillLevel = nSkillLevel
        tDynamicBoxInfo[nArrayIndex].bFree = not nSkillID or nSkillID <= 0
        tWaitAddSkill = nil
        Event.Dispatch(EventType.OnUpdateTreasureBattleFieldSkill, true, self.GetDynamicSkillIndexByArrayIndex(nArrayIndex))
        Event.Dispatch(EventType.OnUpdateTreasureBattleFieldSkill, false)
    else
        local nArrayIndex
        for i = 1, #tDynamicBoxInfo do
            local tInfo = tDynamicBoxInfo[i]
            if tInfo.nSkillID == nSkillID and tInfo.nSkillLevel == nSkillLevel then
                tDynamicBoxInfo[i] = {}
                nArrayIndex = i
                break
            end
        end
        Event.Dispatch(EventType.OnUpdateTreasureBattleFieldSkill, true, self.GetDynamicSkillIndexByArrayIndex(nArrayIndex))
        Event.Dispatch(EventType.OnUpdateTreasureBattleFieldSkill, false)
        if tWaitAddSkill then
            local dwDoodadID = tWaitAddSkill.dwDoodadID
            local tSkillItem = tWaitAddSkill.tSkillItem
            LootItem(dwDoodadID, tSkillItem.id)
        end
    end
end

function TreasureBattleFieldSkillData.UpdateSkillList(tSkill, bDragSkill, nKey)
    local tPosInfo = {}
    if self.bIsXunbao then
        self.nCurSkillGroup = nKey
        self.LoadXunbaoCustomData(nKey, tPosInfo)
    else
        tPosInfo = clone(tDynamicBoxInfo)
    end

    self.InitSkillList(bDragSkill)
    local nCount = self.bIsXunbao and nDynamicSkillCount_Xunbao or table.get_len(tPosInfo)

    for k, v in pairs(tPosInfo) do
        if k <= nCount then
            local tInfo = v
            local bHave = false
            for kk, vv in pairs(tSkill) do
                if vv.nSkillID == tInfo.nSkillID and vv.nSkillLevel == tInfo.nSkillLevel then
                    bHave = true
                    tSkill[kk] = nil
                    break
                end
            end
            if bHave then
                tDynamicBoxInfo[k].nSkillID = v.nSkillID
                tDynamicBoxInfo[k].nSkillLevel = v.nSkillLevel
                if v.nSkillID == 0 and v.nSkillLevel == 0 then
                    tDynamicBoxInfo[k].bFree = true
                else
                    tDynamicBoxInfo[k].bFree = false
                end
            end
        end
    end

    for k, v in pairs(tSkill) do
        for i = 1, nCount do
            if tDynamicBoxInfo[i].bFree then
                tDynamicBoxInfo[i].bFree = false
                tDynamicBoxInfo[i].nSkillID = v.nSkillID
                tDynamicBoxInfo[i].nSkillLevel = v.nSkillLevel
                break
            end
        end
    end

    Event.Dispatch(EventType.OnUpdateTreasureBattleFieldSkill, false)
end

function TreasureBattleFieldSkillData.SwitchSkillList(tNewSkill)
    for k, v in pairs(tNewSkill) do
        tDynamicBoxInfo[k] = tDynamicBoxInfo[k] or {}

        local tInfo = tDynamicBoxInfo[k]
        if v.nSkillID == 0 and v.nSkillLevel == 0 then
            tInfo.bFree = true
        else
            tInfo.bFree = false
            tInfo.nSkillID = v.nSkillID
            tInfo.nSkillLevel = v.nSkillLevel
        end
    end

    Event.Dispatch(EventType.OnUpdateTreasureBattleFieldSkill, false)
end

function TreasureBattleFieldSkillData.SwitchSkill(nOldSkillID, nOldSkillLevel, nNewSkillID, nNewSkillLevel)
    local nSlot
    for i = 1, #tDynamicBoxInfo do
        local tInfo = tDynamicBoxInfo[i]
        if tInfo.nSkillID == nOldSkillID and tInfo.nSkillLevel == nOldSkillLevel and (not tInfo.bFree) then
            nSlot = i
            tInfo.nSkillID = nNewSkillID
            tInfo.nSkillLevel = nNewSkillLevel
            break
        end
    end

    if nSlot then
        Event.Dispatch(EventType.OnUpdateTreasureBattleFieldSkill, true, nSlot)
    end
end

function TreasureBattleFieldSkillData.GetSkillInfoByIndex(nIndex)
    if self.IsDynamicSkillIndex(nIndex) then
        local nArrayIndex = self.GetDynamicSkillArrayIndexByIndex(nIndex)
        return self.GetDynamicSkill(nArrayIndex)
    elseif self.IsDefaultSkillIndex(nIndex) then
        local nArrayIndex = self.GetDefaultSkillArrayIndexByIndex(nIndex)
        return self.GetDefaultSkill(nArrayIndex)
    end
    return nil
end

function TreasureBattleFieldSkillData.IsDynamicSkillIndex(nIndex)
    if self.bIsXunbao then
        return nIndex >= 1 and nIndex <= 7
    end

    return nIndex > 1 and nIndex <= 7
end

function TreasureBattleFieldSkillData.GetDynamicSkillArrayIndexByIndex(nIndex)
    if self.bIsXunbao then
        return nIndex
    end

    return nIndex - 1
end

function TreasureBattleFieldSkillData.GetDynamicSkillIndexByArrayIndex(nArrayIndex)
    for i = 1, nDefaultSkillCount + nDynamicSkillCount do
        if self.GetDynamicSkillArrayIndexByIndex(i) == nArrayIndex then
            return i
        end
    end
end

function TreasureBattleFieldSkillData.IsDefaultSkillIndex(nIndex)
    return nIndex == 1 or nIndex > 7 and nIndex <= 10
end

function TreasureBattleFieldSkillData.GetDefaultSkillArrayIndexByIndex(nIndex)
    if nIndex == 1 then
        return 1
    elseif nIndex > 7 and nIndex <= 10 then
        return nIndex - 6
    end
end

function TreasureBattleFieldSkillData.GetDefaultSkillIndexByArrayIndex(nArrayIndex)
    for i = 1, nDefaultSkillCount + nDynamicSkillCount do
        if self.GetDefaultSkillArrayIndexByIndex(i) == nArrayIndex then
            return i
        end
    end
end

function TreasureBattleFieldSkillData.GetDynamicSkill(nIndex)
    local info = tDynamicBoxInfo[nIndex]
    if info and not IsTableEmpty(info) and not info.bFree and info.nSkillID ~= 0 then
        return info
    end
    return nil
end

function TreasureBattleFieldSkillData.GetDynamicSkillCount()
    local nHaveCount = 0
    for i = 1, nDynamicSkillCount do
        if not IsTableEmpty(tDynamicBoxInfo[i]) then
            nHaveCount = nHaveCount + 1
        end
    end
    return nHaveCount, nDynamicSkillCount
end

function TreasureBattleFieldSkillData.GetDefaultSkill(nIndex)
    local tDefaultSkill = self.bIsXunbao and tDefaultSkill_Xunbao or tDefaultSkill
    local info = tDefaultSkill[nIndex]
    if info and not IsTableEmpty(info) then
        return info
    end
    return nil
end

function TreasureBattleFieldSkillData.EnterDynamic(bIsXunbao)
    self.bInDynamic = true
    self.bIsXunbao = bIsXunbao

    local fnEnter = function()
        Timer.Add(self, 0.1, function ()
            SprintData.SetViewState(false, true)
            Event.Dispatch(EventType.OnEnterTreasureBattleFieldDynamic)
        end)
    end

    Event.Reg(self, "LOADING_END", function ()
        fnEnter()
    end, true)
    fnEnter()
end

function TreasureBattleFieldSkillData.ExitDynamic()
    self.bInDynamic = false
    self.bIsXunbao = false
    self.nCurSkillGroup = nil

    local fnExit = function()
        Timer.AddFrame(self, 2, function ()
            if not QTEMgr.IsInDynamicSkillState() then
                SprintData.SetViewState(true, true)
                Event.Dispatch(EventType.OnLeaveTreasureBattleFieldDynamic)
            end
        end)
    end

    Event.Reg(self, "LOADING_END", function ()
        fnExit()
    end, true)
    fnExit()
end

function TreasureBattleFieldSkillData.IsInDynamic()
    if not self.bInDynamic then return false end
    return self.bInDynamic
end

function TreasureBattleFieldSkillData.IsInXunbao()
    if not self.bIsXunbao then return false end
    return self.bIsXunbao
end

function TreasureBattleFieldSkillData.GetDoodadSkillItemList(dwDoodadID)
    local doodad = GetDoodad(dwDoodadID)
    if not doodad then return end
	local player = GetClientPlayer()
	if not player then return end
	local scene = player.GetScene()
	if not scene then return end

    local tSkillItemList = GetToolSkillItemList()
	local tAllLootItemInfo = scene.GetLootList(doodad.dwID)
    local tResult = {}
    for i = 0, tAllLootItemInfo.nItemCount - 1 do
		if tAllLootItemInfo[i] then
			local item = tAllLootItemInfo[i].Item
            local dwIndex = item.dwIndex
            local nSkillID = tSkillItemList[dwIndex]
            if nSkillID then
                local bFound = false
                for j = 1, nDynamicSkillCount do
                    local tDynamicSkill = self.GetDynamicSkill(j)
                    if tDynamicSkill and tDynamicSkill.nSkillID == nSkillID then
                        bFound = true
                        break
                    end
                end
                if not bFound then
                    table.insert(tResult, {
                        id = item.dwID,
                        dwIndex = item.dwIndex,
                        dwTabType = item.dwTabType,
                        nSkillID = nSkillID,
                    })
                end
            end
		end
	end
    return tResult
end

function TreasureBattleFieldSkillData.ExchangeSkill(nIndex1, nIndex2)
    if nIndex1 == nIndex2 then
        return
    end

    if self.IsDynamicSkillIndex(nIndex1) and self.IsDynamicSkillIndex(nIndex2) then
        local nArrayIndex1 = self.GetDynamicSkillArrayIndexByIndex(nIndex1)
        local nArrayIndex2 = self.GetDynamicSkillArrayIndexByIndex(nIndex2)
        local tTemp = tDynamicBoxInfo[nArrayIndex1]
        tDynamicBoxInfo[nArrayIndex1] = tDynamicBoxInfo[nArrayIndex2]
        tDynamicBoxInfo[nArrayIndex2] = tTemp
        Event.Dispatch(EventType.OnUpdateTreasureBattleFieldSkill, false)

        if self.IsInXunbao() then
            TreasureBattleFieldSkillData.SaveXunbaoCustomData()
        end
        return
    end
    if self.IsDefaultSkillIndex(nIndex1) and self.IsDefaultSkillIndex(nIndex2) then
        local nArrayIndex1 = self.GetDefaultSkillArrayIndexByIndex(nIndex1)
        local nArrayIndex2 = self.GetDefaultSkillArrayIndexByIndex(nIndex2)
        local tTemp = tDefaultSkill[nArrayIndex1]
        tDefaultSkill[nArrayIndex1] = tDefaultSkill[nArrayIndex2]
        tDefaultSkill[nArrayIndex2] = tTemp
        Event.Dispatch(EventType.OnUpdateTreasureBattleFieldSkill, false)
        return
    end
end

function TreasureBattleFieldSkillData.ReplaceDynamicSkill(nIndex, dwDoodadID, tSkillItem)
    if not self.IsDynamicSkillIndex(nIndex) then
        return
    end
    local nArrayIndex = self.GetDynamicSkillArrayIndexByIndex(nIndex)
    local tSkill = self.GetDynamicSkill(nArrayIndex)
    if not tSkill then
        return
    end
    tWaitAddSkill = {
        dwDoodadID = dwDoodadID,
        tSkillItem = tSkillItem,
        nIndex = nIndex,
    }
    RemoteCallToServer(DROP_REMOTE_CALL, tSkill.nSkillID, tSkill.nSkillLevel)
end

function TreasureBattleFieldSkillData.InSkillMap()
    local player = GetClientPlayer()
	if player then
		local dwMapID = player.GetMapID()
		return dwMapID == MAP_ID
    end
    return false
end

function TreasureBattleFieldSkillData.IsSkillMap(dwMapID)
    return dwMapID == MAP_ID
end

function TreasureBattleFieldSkillData.GetSkillBuffList(player)
    local tSkillBuffs = BuffMgr.GetSkillBuff(player)
    local tResult = {}
    for _, tBuff in ipairs(tSkillBuffs) do
        local nSkillID = self.GetBuffSkillID(tBuff.dwID)
        if nSkillID then
            table.insert(tResult, tBuff)
            if #tResult >= 6 then
                break
            end
        end
    end
    return tResult
end

function TreasureBattleFieldSkillData.GetBuffSkillID(dwID)
    return tBuff2SkillMap[dwID]
end

function TreasureBattleFieldSkillData.GetCurWeaponGroup()
    local nWeaponGroup = 0
    nWeaponGroup = self.nCurSkillGroup or 0
    -- local player = GetClientPlayer()
    -- if not player then
    --     return nWeaponGroup
    -- end

    -- if not self.tbWeapon2GroupID then
    --     local tWeapon2ID = select(3, Table_GetDesertWeaponSkill())
    --     self.tbWeapon2GroupID = clone(tWeapon2ID)
    -- end

    -- local hCurWeapon = GetPlayerItem(player, INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.MELEE_WEAPON)
    -- if hCurWeapon then
    --     local dwIndex = hCurWeapon.dwIndex or 0
    --     nWeaponGroup = self.tbWeapon2GroupID[tostring(dwIndex)]
    -- end
    return nWeaponGroup
end

function TreasureBattleFieldSkillData.SaveXunbaoCustomData()
    local tbStorage = Storage.XunBaoSkillSlotInfo
    local nWeaponGroup = self.GetCurWeaponGroup()
    if not nWeaponGroup then
        return
    end

    tbStorage[nWeaponGroup] = tbStorage[nWeaponGroup] or {}
    for nIndex = 1, 5, 1 do
        local tSkill = tDynamicBoxInfo[nIndex]
        if not tSkill.bFree then
            tbStorage[nWeaponGroup][nIndex] = tSkill
        end
    end
    tbStorage.Dirty()
end

function TreasureBattleFieldSkillData.LoadXunbaoCustomData(nWeaponGroup, tDynamicBoxInfo)
    local tbCustomSkill = Storage.XunBaoSkillSlotInfo[nWeaponGroup]
    if not tbCustomSkill then
        return
    end
    for nIndex, tSkill in pairs(tbCustomSkill) do
        tDynamicBoxInfo[nIndex] = clone(tSkill)
    end
end

function TreasureBattleFieldSkillData.GetKongfuByWeapon(dwPlayerID)
    local dwMountID = 0
    local hPlayer = GetPlayer(dwPlayerID)
	if not hPlayer then
		return
	end

	local tCurWeapon = hPlayer.GetItem(INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.MELEE_WEAPON)
	if not tCurWeapon then
		return dwMountID
	end

    local nIndex = tCurWeapon.dwIndex or 0
	local dwID = self.tbWeapon2GroupID[tostring(nIndex)]
	local tInfo = nil
	for k, v in pairs(self.tbXunBaoSkillList) do
		if v.dwID == dwID then
			tInfo = v
			break
		end
	end
    dwMountID = tInfo and tInfo.dwMountID or dwMountID
    return dwMountID
end