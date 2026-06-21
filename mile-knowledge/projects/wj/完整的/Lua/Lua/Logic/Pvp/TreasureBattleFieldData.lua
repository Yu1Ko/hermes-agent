-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: TreasureBattleFieldData
-- Date: 2023-05-24 10:36:32
-- Desc: ?
-- ---------------------------------------------------------------------------------

TreasureBattleFieldData = TreasureBattleFieldData or {className = "TreasureBattleFieldData"}
local self = TreasureBattleFieldData

TreasureBattleFieldData.nDropColor = 3
TreasureBattleFieldData.nXunbaoItemColor = 3
TreasureBattleFieldData.nLootColor = 3
TreasureBattleFieldData.bIncludeHorse = true
TreasureBattleFieldData.bAutoFeedHorse = false
TreasureBattleFieldData.tCircle = {}
TreasureBattleFieldData.tActionBarIDList = {
    -- 吃鸡的
    9, 11, 13, 17, 19, 16,

    -- 李渡鬼域的
    10,

    -- 寻宝模式的
    21,

    -- raid副本boss
    23,
}
TreasureBattleFieldData.dwSingleMatchMapID = 645

TreasureBattleFieldData.tHorseFood = {--地图对应的马草道具ID
    [296] = 29414,
    [297] = 29414,
    [410] = 32675,
    [512] = 29414,
    [532] = 29414,
    [645] = 29414,
    [677] = 29414,
    [676] = 29414,
    [709] = 29414,
}

TreasureBattleFieldData.tWeaponBox = {
    [29101] = {},
    [29102] = {},
    [29103] = {},
    [29542] = {},
}


TreasureBattleFieldData.tSafeMapCircle = {--地图对应的蓝圈ID
    [296] = 2,
    [297] = 2,
    [410] = 6,
    [512] = 8,
    [532] = 10,
    [645] = 8,
    [677] = 2,
    [676] = 2,
}

TreasureBattleFieldData.tSafeCircleRadius = { -- 每个安全圈的半径点数
    59520,
    35712,
    20713,
    11600,
    6264,
    3320,
    1727,
    898,
}

TreasureBattleFieldData.tMiniMapCircleColor = {--ui/Scheme/Case/MapCircle.tab
    [1] = cc.c4f(1, 1, 0, 1), -- 龙门毒圈
    [2] = cc.c4f(0, 0, 1, 1), -- 龙门蓝圈
    [3] = cc.c4f(1, 0, 0, 1), -- 红色轰炸圈
    [4] = cc.c4f(1, 1, 0, 1), -- 绿色毒圈
    [5] = cc.c4f(1, 1, 0, 1), -- 海岛毒圈
    [6] = cc.c4f(0, 0, 1, 1), -- 海岛蓝圈
    [7] = cc.c4f(1, 1, 0, 1), -- 白龙毒圈
    [8] = cc.c4f(0, 0, 1, 1), -- 白龙蓝圈
    [9] = cc.c4f(1, 1, 0, 1), -- 天原毒圈
    [10] = cc.c4f(0, 0, 1, 1), -- 天原蓝圈
    [11] = cc.c4f(1, 1, 0, 1), -- 黑山毒圈
    [12] = cc.c4f(0, 0, 1, 1), -- 黑山蓝圈
}

TreasureBattleFieldData.ROOM_TYPE = {
	NORMAL = 1,  --五人吃鸡
	SINGLE = 2,  --单人吃鸡
	SKILL  = 3,  --真传模式
}

TreasureBattleFieldData.ROOM_MODE = {
    NONE   = 1, --未创建
    OWNER  = 2, --房主
    PLAYER = 3, --玩家
}

TreasureBattleFieldData.tCurRoomInfo = nil

-------------------------------- 消息定义 --------------------------------
TreasureBattleFieldData.Event = {}
TreasureBattleFieldData.Event.XXX = "TreasureBattleFieldData.Msg.XXX"

function TreasureBattleFieldData.Init()
    Event.Reg(self, "LOADING_END", function()
        if self.nTickTimerID then
            Timer.DelTimer(self, self.nTickTimerID)
            self.nTickTimerID = nil
        end
		if BattleFieldData.IsInTreasureBattleFieldMap() then
            self.nTickTimerID = Timer.AddCycle(self, 1, self.Tick)
        end
    end)

    Event.Reg(self, "UPDATE_MIDDLE_MAP_CIRCLE", function ()
        local circle = {}
        circle.fStartDistance = arg1
        circle.fEndtDistance = arg2
        circle.nStartX = arg3
        circle.nStartY = arg4
        circle.nEndX = arg5
        circle.nEndY = arg6
        circle.nStartFrame = GetLogicFrameCount()
        circle.nTotalFrame= arg7 * GLOBAL.GAME_FPS
        circle.tInfo = self.GetCircleInfo(arg0, arg1)
        self.tCircle[arg0] = circle
    end)

    Event.Reg(self, "HIDE_MIDDLE_MAP_CIRCLE", function ()
        self.tCircle[arg0] = nil
    end)

    Event.Reg(self, "CLEAR_MIDDLE_MAP_CIRCLE", function ()
        self.tCircle = {}
    end)

	Event.Reg(self, "UPDATE_MIDDLE_MAP_LINE", function ()
        self.tLine = arg0
        local map = self.GetMapScript()
        if map then
		    map:UpdateFlyLine(arg0)
        end
        Event.Dispatch(EventType.ON_UPDATE_MIDDLE_MAP_LINE)
        LOG.INFO("[TreasureBattle] update Line=%d", arg0 and arg0[1] or -1)
	end)

    Event.Reg(self, "ON_BATTLE_FIELD_MAKR_DATA_NOTIFY", function(tData)
        self.tMarkData = tData
        local map = self.GetMapScript()
        if map then
            map:UpdateMarkNodes()
        end
    end)

    Event.Reg(self, "ON_BATTLE_FIELD_GAIN_DATA_NOTIFY", function(tData)
        self.tGainData = tData
        local map = self.GetMapScript()
        if map then
            map:UpdateGainNodes()
        end
    end)

    Event.Reg(self, EventType.OnClientPlayerLeave, function ()
        self.tCircle = {}
        self.tLine = {}
	end)

    Event.Reg(self, EventType.OnOpenActionBar, function (tbInfo)
        local dwIndex = tbInfo.dwIndex
        for _, dwID in ipairs(TreasureBattleFieldData.tActionBarIDList) do
            if dwID == dwIndex then
                if TreasureBattleFieldSkillData.InSkillMap() then
                    table.insert(tbInfo.tbParams, {{5, 37746}})
                end
                self.tbActionBarInfo = tbInfo
                Event.Dispatch(EventType.UpdateTreasureBattleFieldActionBar, true, true)
                break
            end
        end
    end)

    Event.Reg(self, EventType.OnCloseActionBar, function (dwIndex)
        for _, dwID in ipairs(TreasureBattleFieldData.tActionBarIDList) do
            if dwID == dwIndex and (self.tbActionBarInfo and self.tbActionBarInfo.dwIndex == dwIndex) then
                self.tbActionBarInfo = nil
                Event.Dispatch(EventType.UpdateTreasureBattleFieldActionBar, false, true)
                break
            end
        end
    end)

    Event.Reg(self, "TREASURE_HUNT_BATTLE_FIELD_END", function ()
        ActionBarData.CloseActionBar(21) -- 寻宝模式道具栏
    end)

    Event.Reg(self, EventType.OnRoleLogin, function()
        TreasureBattleFieldData.tCurRoomInfo = nil
        TreasureBattleFieldData.nRoomNotifyMapID = nil
    end)
end

function TreasureBattleFieldData.UnInit()
    Event.UnRegAll(self)
end

function TreasureBattleFieldData.OnLogin()

end

function TreasureBattleFieldData.OnFirstLoadEnd()

end

function TreasureBattleFieldData.GetCircleInfo(nIndex, fDistance)
	local tInfo = nil
	local fMinDistance = 100000
	local nCount = g_tTable.MapCircle:GetRowCount()
	for i = 2, nCount do
		local tLine =  g_tTable.MapCircle:GetRow(i)
		if tLine.nIndex == nIndex then
			local fDis = math.abs(fDistance - tLine.fDistance)
			if not tInfo or fDis <= fMinDistance then
				fMinDistance = fDis
				tInfo = tLine
			end
		end
	end
	return tInfo
end

function TreasureBattleFieldData.CheckAutoLoot(item, tItemIDList)
    if not item then
        return false
    end
    if not g_pClientPlayer then
        return false
    end
    if BattleFieldData.AllowMatchPlayer() then
        return false
    end
    JX_LootPlus.SetChickenQuality(TreasureBattleFieldData.nLootColor)
    return JX_LootPlus.ShouldLoot(g_pClientPlayer, item, tItemIDList)
end

function TreasureBattleFieldData.GetMapScript()
    local view = UIMgr.GetView(VIEW_ID.PanelBattleFieldPubgMapRightPop)
    local scriptView = view and view.scriptView
    return scriptView
end

function TreasureBattleFieldData.Tick()
    local player = g_pClientPlayer
    if not player then
        return
    end
    local horse = player.GetEquippedHorse()
    if horse then
        local nCurrM = horse.GetHorseFullMeasure()
        local nMaxM = horse.GetHorseMaxFullMeasure()
        local dwMapID = player.GetMapID()
        if self.bAutoFeedHorse and nCurrM < nMaxM and nMaxM < 10 and not player.GetBuff(6121, 0) then -- 排除任驰骋期间自动回复
            if TreasureBattleFieldData.tHorseFood[dwMapID] and player.GetItemAmount(5, TreasureBattleFieldData.tHorseFood[dwMapID]) > 0 then
                local dwBox, dwX = player.GetItemPos(5, TreasureBattleFieldData.tHorseFood[dwMapID])
                if dwBox and dwX then
                    ItemData.UseItem(dwBox, dwX)
                end
            end
            if not TreasureBattleFieldData.tHorseFood[dwMapID] and player.GetItemAmount(5,  TreasureBattleFieldData.tHorseFood[296]) > 0 then
                local dwBox, dwX = player.GetItemPos(5, TreasureBattleFieldData.tHorseFood[296])
                if dwBox and dwX then
                    ItemData.UseItem(dwBox, dwX)
                end
            end
        end
    end
end

function TreasureBattleFieldData.IsSingleMatchMap(dwMapID)
    return dwMapID == TreasureBattleFieldData.dwSingleMatchMapID
end

function TreasureBattleFieldData.IsSkillMatchMap(dwMapID)
    return TreasureBattleFieldSkillData.IsSkillMap(dwMapID)
end

function TreasureBattleFieldData.IsExtractMatchMap(dwMapID)
    return dwMapID == 709 or dwMapID == 715
end

function TreasureBattleFieldData.GetDownloadMapIDList()
    local tPackIDList = PakDownloadMgr.GetPackIDListInPackTree(PACKTREE_ID.TreasureBF)
    local tMapIDList = {}
    for _, nPackID in ipairs(tPackIDList) do
        local _, nMapID = PakDownloadMgr.IsMapRes(nPackID)
        if nMapID and not table.contain_value(tMapIDList, nMapID) then
            table.insert(tMapIDList, nMapID)
        end
    end
    return tMapIDList
end

function TreasureBattleFieldData.GetQuickEquipInfo(item)
    if BattleFieldData.IsInTreasureBattleFieldMap() then
        if item.nGenre == ITEM_GENRE.EQUIPMENT and item.nSub == EQUIPMENT_SUB.HORSE then
            return true, "获得新坐骑", "立即装备"
        elseif item.dwTabType == 5 and TreasureBattleFieldData.tWeaponBox[item.dwIndex] then
            return true, "获得新武器", "立即使用"
        end
    end
    return false
end

function TreasureBattleFieldData.QuickEquip(item, dwBox, dwX)
    if BattleFieldData.IsInTreasureBattleFieldMap() then
        if item.nGenre == ITEM_GENRE.EQUIPMENT and item.nSub == EQUIPMENT_SUB.HORSE then
            ItemData.EquipHorseOrHorseEquip(dwBox, dwX)
        elseif item.dwTabType == 5 and TreasureBattleFieldData.tWeaponBox[item.dwIndex] then
            ItemData.UseItem(dwBox, dwX)
        end
    end
end

function TreasureBattleFieldData.UpdateRoomInfo(tInfo)
    TreasureBattleFieldData.tCurRoomInfo = tInfo
    Event.Dispatch(EventType.UpdateTreasureBattleFieldRoomInfo)

    if tInfo and tInfo.dwMapID == TreasureBattleFieldData.nRoomNotifyMapID then
        TreasureBattleFieldData.nRoomNotifyMapID = nil
        PakDownloadMgr.UserCheckDownloadMapRes(tInfo.dwMapID, nil, nil, true, nil, nil, nil, {
            szName = "退出房间",
            callback = function()
                BattleFieldQueueData.DoLeaveBattleFieldQueue(tInfo.dwFatherMapID)
            end,
        })
    end
end

function TreasureBattleFieldData.UpdateRoomNotify(dwMapID)
    TreasureBattleFieldData.nRoomNotifyMapID = dwMapID
end