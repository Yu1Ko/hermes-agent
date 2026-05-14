DungeonSettleCardData = DungeonSettleCardData or {className = "DungeonSettleCardData"}
local self = DungeonSettleCardData

local BUBBLE_LIFE_TIME = 30 -- 气泡栏显示时间30秒
local MIN_DUNGEON_PLAYER = 5 -- 副本名片显示最小人数
local bIsDebug = false

local tDungeonInfo = {
    tPlayerData  = {},
    tExcellentData = {},
    bPassDungeon = false,
    dwMapID = nil,
}

local function _CheckDungeonSence()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return false
    end

    local dwMapID = pPlayer.GetMapID()
    local _, nMapType, nMaxPlayerCount = GetMapParams(dwMapID)
    if nMapType ~= MAP_TYPE.DUNGEON then -- 副本场景
        return false
    end

    local nRefreshCycle = GetMapRefreshInfo(dwMapID)
    if nRefreshCycle <= 0 or nMaxPlayerCount <= 5 then -- 10人/25人团队副本
        return false
    end

    return true
end


function DungeonSettleCardData.Init()
    DungeonSettleCardData.Reg()
end

function DungeonSettleCardData.Reg()
    -- Event.Reg(self, "UPDATE_DUNGEON_ROLE_PROGRESS", function ()
    --     DungeonSettleCardData.UpdateExcellentCard()
    -- end)

    Event.Reg(self, EventType.UILoadingFinish, function ()
        local hPlayer = GetClientPlayer()
        if not hPlayer then
            return
        end

        if not _CheckDungeonSence() then
            return
        end

        local hScene = hPlayer.GetScene()
        local dwMapID = hScene.dwMapID
        if dwMapID then
            tDungeonInfo = {
                tPlayerData    = {},
                tExcellentData = {},
                dwMapID        = dwMapID,
            }
        end

        DungeonSettleCardData.ApplyDungeonTeamMemberCard()
    end)

    Event.Reg(self, "PARTY_ADD_MEMBER", function ()
        if not _CheckDungeonSence() then
            return
        end

        local dwMemberID = arg1
        if not tDungeonInfo.tPlayerData then
            local tMemberInfo = DungeonSettleCardData.GetDungeonPlayerInfo(dwMemberID) or {}
            local szGlobalID = tMemberInfo.szGlobalID

            if szGlobalID then
                PersonalCardData.ApplyShowCardData(szGlobalID)
            end
        end
    end)

    Event.Reg(self, "PLAYER_LEAVE_SCENE", function ()
        local dwPlayerID = arg0
        local hPlayer = GetClientPlayer()
        if hPlayer and hPlayer.dwID == dwPlayerID then
            local hScene = hPlayer.GetScene()
            if hScene.nType == MAP_TYPE.DUNGEON and tDungeonInfo.dwMapID and hScene.dwMapID == tDungeonInfo.dwMapID then
                tDungeonInfo.dwMapID = nil
                BubbleMsgData.RemoveMsg("ShowDungeonExcellentCard")
                Timer.DelAllTimer(self)
            end
        end
    end)
end

function DungeonSettleCardData.GetDungeonPlayerInfo(dwPlayerID)
    local tMemberInfo = GetClientTeam().GetMemberInfo(dwPlayerID)
    if tMemberInfo and not table_is_empty(tMemberInfo) then
        tDungeonInfo.tPlayerData[dwPlayerID] = tMemberInfo
    end

    return clone(tDungeonInfo.tPlayerData[dwPlayerID])
end

function DungeonSettleCardData.GetDungeonExcellentInfo(nExcellentID)
    local tInfo = g_tTable.DungeonExcellent:Search(nExcellentID)

    return clone(tInfo)
end

function DungeonSettleCardData.GetExcellentMemberInfo(tFightData, nExcellentID, fnKungFuFilter)
    if not tFightData then
        return
    end
    local dwPlayer, tPlayerInfo
    local tExcellentInfo = DungeonSettleCardData.GetDungeonExcellentInfo(nExcellentID)
    for _, v in ipairs(tFightData) do
        local tMemberInfo = DungeonSettleCardData.GetDungeonPlayerInfo(v.dwID)
        if tMemberInfo and not table_is_empty(tMemberInfo) then
            if not dwPlayer then
                dwPlayer = v.dwID
                tPlayerInfo = tMemberInfo
            end
            if fnKungFuFilter(tMemberInfo.dwMountKungfuID) and v.nValuePer > 0 then
                dwPlayer = v.dwID
                tPlayerInfo = tMemberInfo
                break
            end
        end
    end

    if not tPlayerInfo then
        return
    end

    local tInfo = tExcellentInfo
    tInfo.dwPlayerID = dwPlayer
    tInfo.szGlobalID = tPlayerInfo.szGlobalID
    tInfo.tPlayerInfo = tPlayerInfo
    return tInfo
end

function DungeonSettleCardData.GetDungeonFightData(nType)
    local fnFightDataSort = function(L, R)
        return L.nValuePer > R.nValuePer
    end

    local tFightData = QueryPlayerStatData(0, DATA_TYPE.ONCE, nType, 0) -- player
    table.sort(tFightData, fnFightDataSort)

    return tFightData
end

function DungeonSettleCardData.GetTeamLeaderInfo()
    local dwLeaderID = GetClientTeam().GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER)
    local tLeaderInfo = DungeonSettleCardData.GetDungeonPlayerInfo(dwLeaderID)

    return dwLeaderID, tLeaderInfo 
end

local function _GetKungfuTypeByKungfu(dwMountKungfuID)
    if not dwMountKungfuID then
        return
    end

    local nKungfuType = GetKungfuTypeByKungfuID(dwMountKungfuID)
    return nKungfuType
end

function DungeonSettleCardData.GetExcellentMemberInfoList()
    local tExcellentData = {}

    -- 最佳治疗
    local tTherapyData = DungeonSettleCardData.GetDungeonFightData(DUNGEON_FIGHT_DATA.THERAPY)
    local nExcellentHpsID = DUNGEON_EXCELLENT_ID.THERAPY
    local fnHpsFilter = function (dwMountKungfuID)
        return _GetKungfuTypeByKungfu(dwMountKungfuID) == JX_KUNGFU_TYPE.HPS
    end
    local tHpsInfo = DungeonSettleCardData.GetExcellentMemberInfo(tTherapyData, nExcellentHpsID, fnHpsFilter)
    table.insert(tExcellentData, tHpsInfo)

    -- 通关显示优秀团长
    local dwLeaderID, tLeaderInfo = DungeonSettleCardData.GetTeamLeaderInfo()
    if tDungeonInfo.bPassDungeon then
        local tInfo = DungeonSettleCardData.GetDungeonExcellentInfo(DUNGEON_EXCELLENT_ID.GREAT_LEADER)
        if dwLeaderID and tLeaderInfo then
            tInfo.szGlobalID = tLeaderInfo.szGlobalID
            tInfo.dwPlayerID = dwLeaderID
            table.insert(tExcellentData, tInfo)
        end
    end

    -- 最佳DPS
    local tDamageData = DungeonSettleCardData.GetDungeonFightData(DUNGEON_FIGHT_DATA.DAMAGE)
    local nExcellentDpsID = tDungeonInfo.bPassDungeon and DUNGEON_EXCELLENT_ID.DAMAGE or DUNGEON_EXCELLENT_ID.GREAT_DAMAGE
    local fnDpsFilter = function (dwMountKungfuID)
        return _GetKungfuTypeByKungfu(dwMountKungfuID) == JX_KUNGFU_TYPE.DPS
    end    
    local tDpsInfo = DungeonSettleCardData.GetExcellentMemberInfo(tDamageData, nExcellentDpsID, fnDpsFilter)
    table.insert(tExcellentData, tDpsInfo)

    -- 最佳承伤
    local tTankData = DungeonSettleCardData.GetDungeonFightData(DUNGEON_FIGHT_DATA.BE_DAMAGE)
    local nExcellentTankID = DUNGEON_EXCELLENT_ID.BE_DAMAGE
    local fnTankFilter = function (dwMountKungfuID)
        return _GetKungfuTypeByKungfu(dwMountKungfuID) == JX_KUNGFU_TYPE.TANK
    end
    local tTankInfo = DungeonSettleCardData.GetExcellentMemberInfo(tTankData, nExcellentTankID, fnTankFilter)
    table.insert(tExcellentData, tTankInfo)

    tDungeonInfo.tExcellentData = clone(tExcellentData)
end

function DungeonSettleCardData.CheckShowFBExcellentCard()
    -- if Storage.DungeonExcellent.bForbidShowCard then
    --     return false
    -- end

    if bIsDebug and IsDebugClient() then
        return true
    end

    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return false
    end

    local hTeamClient = GetClientTeam()
    if not hTeamClient then
        return false
    end

    if not _CheckDungeonSence() then
        return false
    end

    local nPlayerNum = hTeamClient.GetTeamSize() -- 真实玩家人数（单人模式不能组队，团队人数是0）
    if nPlayerNum < MIN_DUNGEON_PLAYER then
        return false
    end

    return true
end

function DungeonSettleCardData.UpdateExcellentCard(bPassDungeon, nDelayTime)
    if not DungeonSettleCardData.CheckShowFBExcellentCard() then
        return
    end

    BubbleMsgData.RemoveMsg("ShowDungeonExcellentCard")
    Timer.DelAllTimer(self)

    tDungeonInfo.bPassDungeon = bPassDungeon
    DungeonSettleCardData.GetExcellentMemberInfoList()
    local tExcellentList = tDungeonInfo.tExcellentData
    if not tExcellentList or table.is_empty(tExcellentList) then
        return
    end

    local _fnOpenView = function (tbData)
        local scriptView = UIMgr.OpenSingle(false, VIEW_ID.PanelDungeonPersonalCardSettle)
        scriptView:UpdateInfo(tbData)
    end

    local nLifeTime = not bPassDungeon and BUBBLE_LIFE_TIME -- 气泡栏显示时间30秒
    local tbMgr = {
        nBarTime    = nLifeTime, -- 显示在气泡栏的时长, 单位为秒
        nLeftTime = nLifeTime,
        nTotalTime = nLifeTime,
        szAction    = function ()
            _fnOpenView(tDungeonInfo.tExcellentData)
        end,
        fnAutoClose = function ()
            if not tDungeonInfo.tExcellentData or table_is_empty(tDungeonInfo.tExcellentData) then
                return true
            end
        end,
    }
    BubbleMsgData.PushMsgWithType("ShowDungeonExcellentCard", tbMgr)

    if bPassDungeon then
        if nDelayTime and nDelayTime > 0 then
            Timer.Add(self, nDelayTime, function()
                local tExcellentList = tDungeonInfo.tExcellentData
                _fnOpenView(tExcellentList)
            end)
        else
            local tExcellentList = tDungeonInfo.tExcellentData
            _fnOpenView(tExcellentList)
        end
    end
end

function DungeonSettleCardData.ApplyDungeonTeamMemberCard()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    local tGlobal = {}
    if RoomData.IsInGlobalRoomDungeon() then
        local tRoomInfo = GetGlobalRoomClient().GetGlobalRoomInfo()
        for _, v in pairs(tRoomInfo) do
            if type(v) == "table" and v.szGlobalID then
                table.insert(tGlobal, v.szGlobalID)
            end
        end
    else
        local tMembers = GetClientTeam().GetTeamMemberList() or {}
        for _, dwMemberID in ipairs(tMembers) do
            local tMemberInfo = DungeonSettleCardData.GetDungeonPlayerInfo(dwMemberID)
            if tMemberInfo and tMemberInfo.szGlobalID then
                table.insert(tGlobal, tMemberInfo.szGlobalID)
            end
        end
    end

    PersonalCardData.ApplyTableShowCardData(tGlobal)
end

function DungeonSettleCardData.IsShowFriendPraise(nType)
    if nType ~= PRAISE_TYPE.TEAM_LEADER and nType ~= PRAISE_TYPE.GREAT_LEADER then
        return true
    end

    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    local dwMapID = pPlayer.GetMapID()
    local _, nMapType = GetMapParams(dwMapID)
    if nMapType == MAP_TYPE.DUNGEON and UIMgr.GetView(VIEW_ID.PanelDungeonPersonalCardSettle) then
        return false
    end

    return true
end

function DungeonSettleCardData.CheckShowLootBtn()
    local bShow = false
    local pPlayer = GetClientPlayer()
    local hTeam = GetClientTeam()
    if not pPlayer or not hTeam then
        return bShow
    end

    bShow = hTeam.nLootMode == PARTY_LOOT_MODE.BIDDING
    return bShow
end