-- ---------------------------------------------------------------------------------
-- Author: KSG
-- Name: OBDungeonData
-- Date: 2026-03-24
-- Desc: 副本观战数据模块
-- ---------------------------------------------------------------------------------
OBDungeonData = OBDungeonData or { className = "OBDungeonData" }
local self = OBDungeonData

self.tPlayerPos = {}

-- 踢出操作冷却
local nLastKickoutTime = 0
local KICKOUT_CD = 2000
-- SetPlayerView 超时：10秒内持续重试
local SET_PLAYER_TIME = 10 * 1000

-- OpenLiveNotify 自动开播状态
local nAutoLiveMapID = nil
local nAutoLiveRoomID = nil
local nAutoLiveTimeoutTimer = nil

local function StartAutoLiveTimeout()
    if nAutoLiveTimeoutTimer then
        Timer.DelTimer(OBDungeonData, nAutoLiveTimeoutTimer)
    end
    nAutoLiveTimeoutTimer = Timer.Add(OBDungeonData, 10, function()
        nAutoLiveTimeoutTimer = nil
        OBDungeonData.CleanupAutoLive()
    end)
end

local function StopAutoLiveTimeout()
    if nAutoLiveTimeoutTimer then
        Timer.DelTimer(OBDungeonData, nAutoLiveTimeoutTimer)
        nAutoLiveTimeoutTimer = nil
    end
end

function OBDungeonData.Init()
    self.tCompetitorMap = {}
    self.tPlayerPos = {}
    self.dwSelectPlayerID = nil
    self.nSetViewTime = nil
    self.nSetViewRetryTimer = nil

    Event.Reg(self, "ON_DUNGEON_OB_COMPETITOR_VARIABLE_INFO_UPDATE", function(tCompetitorList)
        OBDungeonData.OnCompetitorUpdate(tCompetitorList)
    end)

    Event.Reg(self, "ON_TEAM_DUNGEON_OB_SET_MARK", function()
        Event.Dispatch(EventType.ON_TEAM_DUNGEON_OB_SET_MARK_UI)
    end)

    Event.Reg(self, "ON_TEAM_DUNGEON_OB_AUTHORITY_CHANGED", function(nType, dwOldAuthorityID, dwNewAuthorityID)
        Event.Dispatch(EventType.ON_TEAM_DUNGEON_OB_AUTHORITY_CHANGED_UI, nType, dwOldAuthorityID, dwNewAuthorityID)
    end)

    Event.Reg(self, "ON_DUNGEON_OB_PLAYERS_POS_INFO_UPDATE", function()
        Event.Dispatch(EventType.ON_DUNGEON_OB_PLAYERS_POS_INFO_UPDATE_UI)
    end)

    Event.Reg(self, "LOADING_END", function()
        OBDungeonData.ClearCompetitorCache()

        local player = GetClientPlayer()
        if player and player.bOBFlag then
            UIMgr.Open(VIEW_ID.PanelFBShow)
        end

        OBDungeonData.UpdateDungeonLiveBubble()
        OBDungeonData.UpdateOpenLiveNotifyBubble()
    end)

    Event.Reg(self, "TEAM_AUTHORITY_CHANGED", function(nAuthorityType)
        if nAuthorityType == TEAM_AUTHORITY_TYPE.LEADER then
            OBDungeonData.UpdateDungeonLiveBubble()
            OBDungeonData.UpdateOpenLiveNotifyBubble()
        end
    end)

    Event.Reg(self, EventType.ON_OB_SET_VIEW, function(dwPlayerID)
        if not UIMgr.GetViewScript(VIEW_ID.PanelFBShow) then
            Event.Reg(self, EventType.OnViewOpen, function(nViewID)
                if nViewID == VIEW_ID.PanelFBShow then
                    Timer.Add(self, 0.5, function()
                        OBDungeonData.OnSetView(dwPlayerID)
                    end)
                    Event.UnReg(self, EventType.OnViewOpen)
                end
            end)
            return
        end
        OBDungeonData.OnSetView(dwPlayerID)
    end)

    -- 观战操作结果通知（错误码）
    Event.Reg(self, "ON_DUNGEON_OB_RESULT_NOTIFY", function(nResultCode)
        if nResultCode and g_tStrings.tOBDungeonErrorResult and g_tStrings.tOBDungeonErrorResult[nResultCode] then
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.tOBDungeonErrorResult[nResultCode])
            OutputMessage("MSG_SYS", g_tStrings.tOBDungeonErrorResult[nResultCode])
        end
    end)

    -- OpenLiveNotify 自动开播：拦截直播面板确认按钮，确保先入房再开播
    Event.Reg(self, EventType.OnViewOpen, function(nViewID)
        if nViewID ~= VIEW_ID.PanelLiveBroadcastPop then return end
        if not nAutoLiveMapID then return end
        local pScript = UIMgr.GetViewScript(VIEW_ID.PanelLiveBroadcastPop)
        if not pScript then return end
        UIHelper.UnBindUIEvent(pScript.BtnClose, EventType.OnClick)
        UIHelper.UnBindUIEvent(pScript.BtnConfirm, EventType.OnClick)
        UIHelper.BindUIEvent(pScript.BtnClose, EventType.OnClick, function()
            OBDungeonData.CleanupAutoLive()
            UIMgr.Close(VIEW_ID.PanelLiveBroadcastPop)
        end)

        UIHelper.BindUIEvent(pScript.BtnConfirm, EventType.OnClick, function()
            local nMapID = pScript.nSelectMapID
            nAutoLiveMapID = nil
            UIMgr.Close(VIEW_ID.PanelLiveBroadcastPop)
            if nMapID and nMapID > 0 then
                local szMyRoomID, szRoomID = RoomVoiceData.GetRoleVoiceRoomList()
                if szMyRoomID and szRoomID and szRoomID == szMyRoomID then
                    nAutoLiveMapID = nMapID
                    OBDungeonData.StartLiveStream()
                else
                    local szMyRoomID = select(1, RoomVoiceData.GetRoleVoiceRoomList())
                    if szMyRoomID and szMyRoomID ~= '0' then
                        nAutoLiveMapID = nMapID
                        nAutoLiveRoomID = szMyRoomID
                        local tbRoomInfo = RoomVoiceData.GetVoiceRoomInfo(szMyRoomID)
                        if not tbRoomInfo then
                            RoomVoiceData.ApplyVoiceRoomInfo(szMyRoomID)
                        else
                            local bPwdRequired = tbRoomInfo and tbRoomInfo.bPwdRequired or false
                            RoomVoiceData.TryJoinRoom(szMyRoomID, bPwdRequired, function()
                                OBDungeonData.CleanupAutoLive()
                            end)
                        end
                        StartAutoLiveTimeout()
                    end
                end
            end
        end)
    end)

    Event.Reg(self, EventType.ON_JOIN_VOICE_ROOM, function(szRoomID, _, bCreateRoom)
        if not nAutoLiveMapID then return end
        StopAutoLiveTimeout()
        nAutoLiveRoomID = szRoomID
        OBDungeonData.StartLiveStream()
    end)

    Event.Reg(self, EventType.ON_SYNC_VOICE_ROOM_INFO, function(szRoomID)
        if not nAutoLiveMapID or not nAutoLiveRoomID then return end
        if szRoomID == nAutoLiveRoomID then
            local tbRoomInfo = RoomVoiceData.GetVoiceRoomInfo(nAutoLiveRoomID)
            local bPwdRequired = tbRoomInfo and tbRoomInfo.bPwdRequired or false
            RoomVoiceData.TryJoinRoom(nAutoLiveRoomID, bPwdRequired, function()
                OBDungeonData.CleanupAutoLive()
            end)
            StartAutoLiveTimeout()
        end
    end)
end

function OBDungeonData.UnInit()
    Event.UnRegAll(self)
    Timer.DelAllTimer(self)
    BubbleMsgData.RemoveMsg("DungeonLive")
    BubbleMsgData.RemoveMsg("OpenLiveNotify")
    nAutoLiveMapID = nil
    nAutoLiveRoomID = nil
    self.tCompetitorMap = {}
    self.tPlayerPos = {}
    self.dwSelectPlayerID = nil
    self.nSetViewTime = nil
    self.nSetViewRetryTimer = nil
end

-- 切换观看目标
-- dwPlayerID 非零时锁定观看指定玩家；0/nil 时切回自由视角
function OBDungeonData.OnSetView(dwPlayerID)
    if self.nSetViewRetryTimer then
        Timer.DelTimer(self, self.nSetViewRetryTimer)
        self.nSetViewRetryTimer = nil
    end

    if dwPlayerID and dwPlayerID ~= 0 then
        self.nSetViewTime = GetTickCount()
        OBDungeonData.SetPlayerView(dwPlayerID)
    else
        -- 清空选中玩家，取消 CD 同步
        self.dwSelectPlayerID = nil
        local player = GetClientPlayer()
        if player then
            player.CancelSyncDungeonCompetitorSkillCDState()
        end

        local scale, yaw, _, SceneX, SceneY, SceneZ= Camera_GetRTParams()
        local x, y, z = Scene_ScenePositionToGameWorldPosition(SceneX , SceneY, SceneZ)
        CameraMgr.Status_Set({
            scale = math.max(0.80, scale),
            pitch = -math.pi / 8,
            yaw     = yaw,
            --tick     = 0,
            mode    = "god camera",
            x       = x,
            y       = y,
            z       = z,
            dis_ctrl= 1,
            Limit   = 1,
            limitx  = 1000,
            limity  = 1000,
            limitz  = 1000,
        })
        Event.Dispatch(EventType.ON_OB_SELECT_PLAYER_CHANGED, nil)
    end
end

function OBDungeonData.SetPlayerView(dwPlayerID)
    local hViewPlayer = GetPlayer(dwPlayerID)
    if not hViewPlayer then
        -- 玩家对象尚未加载，在超时内每 0.5秒重试
        if self.nSetViewTime and GetTickCount() - self.nSetViewTime < SET_PLAYER_TIME then
            self.nSetViewRetryTimer = Timer.Add(self, 0.5, function()
                self.nSetViewRetryTimer = nil
                OBDungeonData.SetPlayerView(dwPlayerID)
            end)
        end
        return
    end

    self.dwSelectPlayerID = dwPlayerID
    OBDungeonData.GetSkillCDRequest(dwPlayerID)
    local player = GetClientPlayer()
    if player then
        TargetMgr.ManualSelect(TARGET.PLAYER, dwPlayerID)

        player.CancelSyncDungeonCompetitorSkillCDState()
        player.SyncDungeonCompetitorSkillCDStateRequest(dwPlayerID)
        CameraMgr.Status_Set({
            scale = 1,
            yaw = 2 * math.pi - (hViewPlayer.nFaceDirection / 255 * math.pi * 2 - math.pi / 2),
            pitch = -math.pi / 10,
            --tick = 0,
            mode    = "remote camera",  -- 镜头模式 跟随视角
            remoteid = dwPlayerID,
            dis_ctrl = false,
        })
    end
    Event.Dispatch(EventType.ON_OB_SELECT_PLAYER_CHANGED, dwPlayerID)
end


-- 处理参战成员数据更新
-- @param tCompetitorList: C++ 推送的完整参战成员表（见字段说明）
--   每条记录格式：
--     dwPlayerID      (number)  玩家ID
--     szPlayerName    (string)  玩家名（GBK，UI层需转UTF8）
--     nCurrentLife    (number)  当前血量
--     nMaxLife        (number)  最大血量
--     nEquipScore     (number)  装备评分
--     dwKungfuID      (number)  心法ID
--     nMemberIndex    (number)  团队槽位(1‥25)
function OBDungeonData.OnCompetitorUpdate()
    local pScene = GetClientScene()
	if not pScene then
		return
	end

    -- 用 GetDungeonPlayersPosInfo 获取参战玩家 ID 列表，
    -- 再用 GetDungeonCompetitor(dwPlayerID) 单接口逐个获取信息
    local tPosInfo = pScene.GetDungeonPlayersPosInfo() or {}
    self.tCompetitorMap = {}
    self.tPlayerPos = {}
    for dwPlayerID, _ in pairs(tPosInfo) do
        local _, szPlayerName, nCurrentLife, nMaxLife, nEquipScore, dwKungfuID, nMemberIndex, dwCenterID
            = pScene.GetDungeonCompetitor(dwPlayerID)
        if szPlayerName then
            self.tCompetitorMap[dwPlayerID] = {
                dwPlayerID       = dwPlayerID,
                szPlayerName     = szPlayerName or "",
                nCurrentLife     = nCurrentLife or 0,
                nMaxLife         = nMaxLife or 0,
                nEquipScore      = nEquipScore or 0,
                dwKungfuID       = dwKungfuID or 0,
                nMemberIndex     = nMemberIndex or 0,
                dwCenterID       = dwCenterID or 0,
            }
            if nMemberIndex and nMemberIndex > 0 then
                self.tPlayerPos[nMemberIndex] = dwPlayerID
            end
        end
    end
    Event.Dispatch(EventType.ON_DUNGEON_OB_COMPETITOR_VARIABLE_INFO_UPDATE_UI)
end

-- 清空参战成员缓存（地图切换时调用）
function OBDungeonData.ClearCompetitorCache()
    self.tCompetitorMap = {}
    self.tPlayerPos = {}
end

-- ──── 数据查询 ────────────────────────────────────────────────────────────────

-- 获取指定玩家的参战成员信息
-- @return dwPlayerID, szPlayerName, nCurrentLife, nMaxLife,
--         nEquipScore, dwKungfuID, nMemberIndex, dwCenterID
function OBDungeonData.GetDungeonCompetitor(dwPlayerID)
    local t = self.tCompetitorMap[dwPlayerID]
    if not t then
        return nil
    end
    return dwPlayerID, t.szPlayerName, t.nCurrentLife, t.nMaxLife,
           t.nEquipScore, t.dwKungfuID, t.nMemberIndex, t.dwCenterID
end

-- @return { [dwPlayerID] = {szPlayerName, nCurrentLife, nMaxLife,
--                           nEquipScore, dwKungfuID, nMemberIndex, dwCenterID} }
function OBDungeonData.GetDungeonCompetitorsList()
    -- 直接返回缓存（由 OnCompetitorUpdate 维护）
    local tResult = {}
    for dwID, t in pairs(self.tCompetitorMap) do
        tResult[dwID] = {
            szPlayerName = t.szPlayerName,
            nCurrentLife = t.nCurrentLife,
            nMaxLife     = t.nMaxLife,
            nEquipScore  = t.nEquipScore,
            dwKungfuID   = t.dwKungfuID,
            nMemberIndex = t.nMemberIndex,
            dwCenterID   = t.dwCenterID,
        }
    end
    return tResult
end

-- 获取当前副本中所有观战玩家列表
function OBDungeonData.GetAllDungeonOBPlayer()
    if RoomVoiceData and RoomVoiceData.GetLiveStreamMapRoleList then
        return RoomVoiceData.GetLiveStreamMapRoleList(LIVE_STREAM_MEMBER_TYPE.OBSERVER) or {}
    end
    return {}
end

-- 获取 OBDungeon 副本列表（来自配置表 OBDungeon）
function OBDungeonData.GetOBDungeonList()
    if not g_tTable or not g_tTable.OBDungeon then
        return {}
    end
    local nCount = g_tTable.OBDungeon:GetRowCount()
    local tRes = {}
    for i = 2, nCount do
        local tLine = g_tTable.OBDungeon:GetRow(i)
        if tLine then
            table.insert(tRes, tLine)
        end
    end
    return tRes
end

function OBDungeonData.GetOBRoomNameByMapID(dwMapID)
    if not g_tTable or not g_tTable.OBDungeon then
        return ""
    end
    local nCount = g_tTable.OBDungeon:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.OBDungeon:GetRow(i)
        if tLine and tLine.nMapID == dwMapID then
            return tLine.szVoiceName or tLine.szName or ""
        end
    end
    return ""
end

-- ──── 状态查询 ────────────────────────────────────────────────────────────────

function OBDungeonData.IsOBMap(dwMapID)
    if not g_tTable or not g_tTable.OBDungeon then
        return false
    end
    local nCount = g_tTable.OBDungeon:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.OBDungeon:GetRow(i)
        if tLine and tLine.nMapID == dwMapID then
            return true
        end
    end
    return false
end

-- 当前角色是否处于观战状态
function OBDungeonData.IsPlayerInOBDungeon()
    local player = GetClientPlayer()
    return player and player.bOBFlag == true
end

-- 当前角色是否为副本房主（队长）
function OBDungeonData.IsPlayerDungeonOwner()
    local hTeam = GetClientTeam()
    local hMe = GetClientPlayer()
    if not hTeam or not hMe then
        return false
    end
    local nLeaderID = hTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER)
    local nMyID = hMe.dwID
    return nLeaderID ~= nil and nLeaderID == nMyID
end


-- 切换观看目标
function OBDungeonData.WatchPlayer(dwTargetID)
    RemoteCallToServer("On_Dungeon_WatchPlayer", dwTargetID)
end

-- 切换全局自由视角并取消技能CD同步
function OBDungeonData.WatchAll()
    RemoteCallToServer("On_Dungeon_WatchAll")
    local player = GetClientPlayer()
    if player then
        player.CancelSyncDungeonCompetitorSkillCDState()
    end
end

-- 退出观战状态
function OBDungeonData.LeaveOB()
    RemoteCallToServer("On_Dungeon_LeaveOB")
end

-- 获取参战成员总人数
function OBDungeonData.GetPlayerNum()
    local nCount = 0
    for _ in pairs(self.tCompetitorMap) do
        nCount = nCount + 1
    end
    return nCount
end

-- 踢出观战玩家（2 秒 CD 保护）
-- @param szGlobalID: 目标玩家的 GlobalID（字符串）
function OBDungeonData.KickOutOB(szGlobalID)
    if GetTickCount() - nLastKickoutTime < KICKOUT_CD then
        TipsHelper.ShowNormalTip(g_tStrings.STR_OBDUNGEON_KICKOUT_OB_TIP)
        return
    end
    nLastKickoutTime = GetTickCount()
    RemoteCallToServer("On_Dungeon_KickOutOB", szGlobalID)
end

-- 请求指定玩家的技能 CD 状态（一次性拉取）
function OBDungeonData.GetSkillCDRequest(dwPlayerID)
    RemoteCallToServer("On_Dungeon_GetSkillCDRequest", dwPlayerID)
end

-- 获取场景内某个player
function OBDungeonData.GetCompetitor(dwPlayerID)
	local pScene = GetClientScene()
	if not pScene then
		return {}
	end
	return {pScene.GetDungeonCompetitor(dwPlayerID)}
end

-- ──── 气泡消息管理 ────────────────────────────────────────────────────────────

-- 更新"副本观战观众管理"气泡消息状态
function OBDungeonData.UpdateDungeonLiveBubble()
    local player = GetClientPlayer()
    if not player then
        return
    end

    local pScene = player.GetScene()
    local dwMapID = pScene.dwMapID
    if not pScene or not dwMapID then
        return
    end

    local bInOBMap = OBDungeonData.IsOBMap(dwMapID)

    if not bInOBMap then
        BubbleMsgData.RemoveMsg("DungeonLive")
        return
    end

    if IsRemotePlayer(UI_GetClientPlayerID()) then
        RoomVoiceData.ApplyLiveStreamMapRoleList(LIVE_STREAM_MEMBER_TYPE.STREAMER)
        if OBDungeonData.IsPlayerDungeonOwner() then
            RoomVoiceData.ApplyLiveStreamMapRoleList(LIVE_STREAM_MEMBER_TYPE.OBSERVER)
            BubbleMsgData.PushMsgWithType("DungeonLive", {
                szAction = function()
                    UIMgr.Open(VIEW_ID.PanelAudienceList)
                end
            })
        else
            BubbleMsgData.RemoveMsg("DungeonLive")
            UIMgr.Close(VIEW_ID.PanelAudienceList)
        end
    else
        BubbleMsgData.RemoveMsg("DungeonLive")
        UIMgr.Close(VIEW_ID.PanelAudienceList)
    end
end

-- 更新"开播通知"气泡消息状态（显示条件与 DungeonLive 一致）
function OBDungeonData.UpdateOpenLiveNotifyBubble()
    local player = GetClientPlayer()
    if not player then
        return
    end

    local pScene = player.GetScene()
    local dwMapID = pScene.dwMapID
    if not pScene or not dwMapID then
        return
    end

    local bInOBMap = OBDungeonData.IsOBMap(dwMapID)

    if not bInOBMap then
        BubbleMsgData.RemoveMsg("OpenLiveNotify")
        return
    end

    if IsRemotePlayer(UI_GetClientPlayerID()) then
        if OBDungeonData.IsPlayerDungeonOwner() then
            BubbleMsgData.PushMsgWithType("OpenLiveNotify", {
                szAction = function()
                    OBDungeonData.OnOpenLiveNotifyClick()
                end
            })
        else
            BubbleMsgData.RemoveMsg("OpenLiveNotify")
        end
    else
        BubbleMsgData.RemoveMsg("OpenLiveNotify")
    end
end

-- ──── OpenLiveNotify 自动开播流程 ─────────────────────────────────────────────

-- 点击"开播通知"气泡
function OBDungeonData.OnOpenLiveNotifyClick()
    nAutoLiveMapID = nil
    nAutoLiveRoomID = nil
    local player = GetClientPlayer()
    if not player then return end
    local pScene = player.GetScene()
    if not pScene then return end
    local dwMapID = pScene.dwMapID
    if not dwMapID then return end

    local szCurRoomID = RoomVoiceData.GetCurVoiceRoomID()
    if szCurRoomID then
        local szMyRoomID = select(1, RoomVoiceData.GetRoleVoiceRoomList())
        if szCurRoomID == szMyRoomID then
            -- 自己房间
            if RoomVoiceData.IsLiveStreamActive() then
                RoomVoiceData.JumpToRoomVoice(false, false)
                return
            end
            OBDungeonData.OpenLivePanel(dwMapID)
        else
            -- 别人房间：提示退出
            UIHelper.ShowConfirm("当前已在其他语音房间中，是否退出并开播？", function()
                local player = GetClientPlayer()
                if not player then
                    return
                end
                local szGlobalID = player.GetGlobalID()
                RoomVoiceData.KickOutVoiceRoomMember(szCurRoomID, szGlobalID)
                RoomVoiceData.fnExitRoomCallBack = function(szRoomID, szMemberID)
                    local nGLobalID = g_pClientPlayer.GetGlobalID()
                    if szRoomID == szCurRoomID then
                        if nGLobalID == szMemberID then--自己退出房间
                            OBDungeonData.OpenLivePanel(dwMapID)
                            RoomVoiceData.fnExitRoomCallBack = nil
                        end
                    end
                end
            end)
        end
    else
        -- 不在房间
        OBDungeonData.OpenLivePanel(dwMapID)
    end
end

-- 根据是否有自己的房间，打开对应面板
function OBDungeonData.OpenLivePanel(dwMapID)
    nAutoLiveMapID = dwMapID
    if RoomVoiceData.HasMyOwnRoom() then
        -- 有房间：打开直播设置，预选当前地图
        UIMgr.Open(VIEW_ID.PanelLiveBroadcastPop, dwMapID)
    else
        -- 无房间：打开新建房间，房间名默认为地图名
        local szMapName = UIHelper.GBKToUTF8(OBDungeonData.GetOBRoomNameByMapID(dwMapID))
        UIMgr.Open(VIEW_ID.PanelCreateVoiceRoomPop, nil, nil, szMapName)
    end
end

-- 启动直播流
function OBDungeonData.StartLiveStream()
    if not nAutoLiveMapID then return end
    RoomVoiceData.SetLiveStreamMap(nAutoLiveMapID)
    OBDungeonData.CleanupAutoLive()

    if not UIMgr.IsViewOpened(VIEW_ID.PanelChatSocial, true) then
        RoomVoiceData.JumpToRoomVoice()
    end
end

-- 清理自动开播状态
function OBDungeonData.CleanupAutoLive()
    StopAutoLiveTimeout()
    nAutoLiveMapID = nil
    nAutoLiveRoomID = nil
end
