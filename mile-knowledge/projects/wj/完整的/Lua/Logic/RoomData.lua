-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: RoomData
-- Date: 2024-02-18 15:40:48
-- Desc: 从端游RoomBase拷过来的
-- ---------------------------------------------------------------------------------

RoomData = RoomData or {className = "RoomData"}
local self = RoomData
-------------------------------- 消息定义 --------------------------------
RoomData.Event = {}
RoomData.Event.XXX = "RoomData.Msg.XXX"

RoomData.bMainCityRoom = false

function RoomData.Init()

end

function RoomData.UnInit()

end

function RoomData.OnLogin()

end

function RoomData.OnFirstLoadEnd()

end


-- GLOBAL_ROOM_STATE_CODE = {
-- 	ROOM_INVALID	房间还没准备好
-- 	ROOM_INIT	房间初始化了
-- 	ROOM_PREPARE_MAP	房间在准备地图环境
-- 	ROOM_WAIT_ENTER	房间在等待玩家进入
-- 	ROOM_CHANGE_TARGET_MAP	房间正在重置地图流程中
-- 	ROOM_UNINIT	房间在销毁流程中
-- }
local MAX_ROOM_NUM = 25
local GROUP_SIZE = 5

function RoomData.SetMainCityRoom(bRoom)
    if RoomData.bMainCityRoom == bRoom  then
        return
    end
    RoomData.bMainCityRoom = bRoom
    Event.Dispatch(EventType.OnSetMainCityRoom, bRoom)
end

function RoomData.IsMainCityRoom()
    return RoomData.bMainCityRoom or false
end

function RoomData.IsHaveRoom()
    local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end
	local szGlobalRoomID = hPlayer.GetGlobalRoomID()
    if not szGlobalRoomID then
        return false
    end
    return true
end

function RoomData.CreateRoom()
    local hRoom = GetGlobalRoomClient()
	if not hRoom then
		return
	end
	local nRecode = hRoom.CreateGlobalRoom()
    if not nRecode then
        TipsHelper.OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_CREATE_ROOM_ERROR)
        return
    end
end

function RoomData.IsRoomOwner()
    local hRoom = GetGlobalRoomClient()
    if hRoom then
        local dwGlobalID = UI_GetClientPlayerGlobalID()
        local szOwnerID = hRoom.GetGlobalRoomOwnerID()
        if szOwnerID and dwGlobalID == szOwnerID then
            return true
        end
    end
    return false
end

function RoomData.GetRoomOwner()
    local hRoom = GetGlobalRoomClient()
    if hRoom then
        local szOwnerID = hRoom.GetGlobalRoomOwnerID()
        return szOwnerID
    end
end

function RoomData.GetRoomState()
    local tRoomInfo = GetGlobalRoomClient().GetGlobalRoomInfo()
    if tRoomInfo then
        return tRoomInfo.eRoomState
    end
end

--- 是否在跨服副本地图中
function RoomData.IsInGlobalRoomDungeon()
    return GetGlobalRoomClient().IsInGlobalRoomDungeon()
end

function RoomData.GetRoomMemberInfo(szGlobalID)
    local tRoomInfo = GetGlobalRoomClient().GetGlobalRoomInfo()
    for i = 1, MAX_ROOM_NUM do
        if tRoomInfo[i] and tRoomInfo[i].szGlobalID then
            if szGlobalID == tRoomInfo[i].szGlobalID then
                return tRoomInfo[i]
            end
        end
    end
end

function RoomData.GetSize()
    local nRoomSize = 0
    local tRoomInfo = GetGlobalRoomClient().GetGlobalRoomInfo()

    for i = 1, MAX_ROOM_NUM do
        if tRoomInfo[i] and tRoomInfo[i].szGlobalID then
            nRoomSize = nRoomSize + 1
        end
    end
    return nRoomSize
end

function RoomData.RoomBase_GetGroupList(nGroupID)
    local tMemberList = {}
    local tRoomInfo = GetGlobalRoomClient().GetGlobalRoomInfo()

    local dwStart = nGroupID * GROUP_SIZE + 1
    for i = dwStart, dwStart + 4 do
        if tRoomInfo[i] and tRoomInfo[i].szGlobalID then
            table.insert(tMemberList, tRoomInfo[i].szGlobalID)
        end
    end
    return tMemberList
end

function RoomData.InviteRoomorApplyRoom(dwGlobalID, szName, dwCenterID)
    if not dwCenterID then
        dwCenterID = GetRemoteChatSenderCenterID(szName)
    end

    local player = GetClientPlayer()
	if player.GetGlobalRoomID() then
        if RoomData.IsRoomOwner() then
            GetGlobalRoomClient().InviteJoinGlobalRoom(dwGlobalID, dwCenterID)
            local szTip = FormatString(g_tStrings.STR_ROOM_SEND_INVITE_JOIN, "\"" .. UIHelper.GBKToUTF8(szName) .. "\"")
            TipsHelper.OutputMessage("MSG_SYS", szTip)
        else
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_ROOM_ALREADY_ROOM)
            OutputMessage("MSG_SYS", g_tStrings.STR_ROOM_ALREADY_ROOM)
		end
	else
        if CheckPlayerIsRemote() then
            return
        end
        GetGlobalRoomClient().JoinGlobalRoom(dwGlobalID, dwCenterID)
        local szTip = FormatString(g_tStrings.STR_ROOM_SEND_INVITE_JOIN, "\"" .. UIHelper.GBKToUTF8(szName) .. "\"")
        TipsHelper.OutputMessage("MSG_SYS", szTip)
	end
end

function RoomData.ConfirmQuitGlobalRoom()
    local szMessage = GetFormatText(g_tStrings.STR_ROOM_QUIT_CONFIRM_MSG)
    local tRoomInfo = GetGlobalRoomClient().GetGlobalRoomInfo()
    if tRoomInfo.bBiddingMode then
        szMessage = GetFormatText(g_tStrings.STR_ROOM_LEAVE_BIDDING_TIP, 219, 255, 0, 0)
    end

    UIHelper.ShowConfirm(szMessage, function()
        GetGlobalRoomClient().LeaveGlobalRoom()
    end, nil, true)
end

function RoomData.ConfirmLeaveRoomScene()
    local function LeaveScene()
        local tRoomInfo = GetGlobalRoomClient().GetGlobalRoomInfo()
        if tRoomInfo.bBiddingMode then
            local nTeamSize = GetClientTeam().GetTeamSize() or 0
            if nTeamSize <= 5 then
                local player = GetClientPlayer()
                local tText = {{type = "text", text = UIHelper.UTF8ToGBK(g_tStrings.STR_ROOM_LEAVE_DUNGEON_MAP_MESSAGE)}}
                Player_Talk(player, PLAYER_TALK_CHANNEL.ROOM, "", tText)
            end
        end
        GetGlobalRoomClient().LeaveScene()
    end

    --local msg =
    --{
    --    szMessage = g_tStrings.STR_ROOM_LEAVE_DUNGEON_MAP_CONFIRM,
    --    szName = "QuitRoomSceneConfirm",
    --    {szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() LeaveScene() end},
    --    {szOption = g_tStrings.STR_HOTKEY_CANCEL, fnAction = function()  end}
    --}
    --MessageBox(msg)
    local confirmDialog = UIHelper.ShowConfirm(g_tStrings.STR_ROOM_LEAVE_DUNGEON_MAP_CONFIRM, function()
        LeaveScene()
    end, nil)
    confirmDialog:SetButtonContent("Confirm", g_tStrings.STR_HOTKEY_SURE)
end

function RoomData.InsertRoommateMenu(dwGlobalID)
    local tMenu = {}
    local tMemberInfo = RoomData.GetRoomMemberInfo(dwGlobalID)

    local function ChangeRoomOwner(dwGlobalID, szName)
        local szMsg = FormatString(g_tStrings.STR_ROOM_CHANGE_OWNER_TIP, UIHelper.GBKToUTF8(szName))
        UIHelper.ShowConfirm(szMsg, function()
            GetGlobalRoomClient().ChangeGlobalRoomOwner(dwGlobalID)
        end)
    end

    if RoomData.IsRoomOwner() then
        if dwGlobalID ~= UI_GetClientPlayerGlobalID() then
            -- 开除队友
	        table.insert(tMenu, {
		        szName = g_tStrings.STR_ROOM_KICK_PLAYER,
                bCloseOnClick = true,
		        callback = function()
                    GetGlobalRoomClient().KickGlobalRoomMember(dwGlobalID)
                end
            })
            --移交房主
	        table.insert(tMenu, {
		        szName = g_tStrings.STR_ROOM_CHANGE_OWNER,
                bCloseOnClick = true,
		        callback = function()
                    ChangeRoomOwner(dwGlobalID, RoomData.GetGlobalName(tMemberInfo.szName, tMemberInfo.dwCenterID))
                end,
            })
        end
    end

    if dwGlobalID ~= UI_GetClientPlayerGlobalID() then
        -- 密聊
        table.insert(tMenu, {
	        szName = g_tStrings.STR_SAY_SECRET,
            bCloseOnClick = true,
		    callback = function()

                local dwTalkerID = tMemberInfo.dwTalkerID
                local szName = GBKToUTF8(tMemberInfo.szName)
                local dwMiniAvatarID = tMemberInfo.dwMiniAvatarID
                local dwForceID = tMemberInfo.dwForceID
                local nLevel = tMemberInfo.nLevel
                local nCamp = tMemberInfo.nCamp
                local nRoleType = tMemberInfo.nRoleType
                local szGlobalID = tMemberInfo.szGlobalID
                local dwCenterID = tMemberInfo.dwCenterID

                local tbData = {szName = szName, dwTalkerID = dwTalkerID, dwForceID = dwForceID, dwMiniAvatarID = dwMiniAvatarID, nRoleType = nRoleType, nLevel = nLevel, szGlobalID = szGlobalID, dwCenterID = dwCenterID}
                ChatHelper.WhisperTo(szName, tbData)
                -- EditBox_TalkToSomebody(RoomData.GetGlobalName(tMemberInfo.szName, tMemberInfo.dwCenterID))
            end,
	    })
	    -- 好友
        table.insert(tMenu, {
		    szName = g_tStrings.STR_MAKE_FRIEND,
            bCloseOnClick = true,
		    callback = function()
                if IsRemotePlayer(UI_GetClientPlayerID()) then
                    GetSocialManagerClient().AddFellowship(RoomData.GetGlobalName(tMemberInfo.szName, tMemberInfo.dwCenterID, true))
                else
                    GetSocialManagerClient().AddFellowship(RoomData.GetGlobalName(tMemberInfo.szName, tMemberInfo.dwCenterID))
                end
            end
        })
        -- 查看装备
        table.insert(tMenu, {
            szName = g_tStrings.STR_LOOKUP,
            bCloseOnClick = true,
            callback = function()
                UIMgr.Open(VIEW_ID.PanelOtherPlayer, nil, tMemberInfo.dwCenterID, tMemberInfo.szGlobalID)
            end
        })
    else
        table.insert(tMenu, {
            szName = g_tStrings.STR_ROOM_QUIT,
            bCloseOnClick = true,
            callback = function()
                RoomData.ConfirmQuitGlobalRoom()
            end})
    end
    return tMenu
end

--- 是否是跨服副本地图
function RoomData.IsSwicthServerDungeon(dwMapID)
    if not dwMapID then
        return false
    end

    local tGlobalRecruit = Table_GetGlobalTeamRecruit()
    for _, v in ipairs(tGlobalRecruit) do
        if v.dwMapID and v.dwMapID == dwMapID then
            return true
        end
    end
    return false
end

function RoomData.ApplyGlobalDungeon(dwMapID)
    local hPlayer = GetClientPlayer()
    if not hPlayer or not hPlayer.GetGlobalRoomID() then
        TipsHelper.OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_ROOM_NEED_IN_ROOM)
        return
    end

    local tRoomInfo = GetGlobalRoomClient().GetGlobalRoomInfo()
    if tRoomInfo.nTargetMapID and tRoomInfo.nTargetMapID ~= 0 then
        if tRoomInfo.nTargetMapID == dwMapID then
            MapMgr.BeforeTeleport()
            RemoteCallToServer("On_Team_RoomToEnterScene")
        else
            TipsHelper.OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_ROOM_ERROR_TARGET)
        end
    else
        TipsHelper.OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_ROOM_NEED_SET_MAPID)
    end
end

function RoomData.IsApplyGlobalDungeon(dwMapID)
    local hPlayer = GetClientPlayer()
    if not hPlayer or not hPlayer.GetGlobalRoomID() then
        return
    end

    local tRoomInfo = GetGlobalRoomClient().GetGlobalRoomInfo()
    if tRoomInfo.nTargetMapID and tRoomInfo.nTargetMapID ~= 0 then
        if tRoomInfo.nTargetMapID == dwMapID then
            return true
        end
    end
end

function RoomData.GetTeamPlayerIDByGlobalID(szGlobalID)
	local hTeam = GetClientTeam()
    if hTeam then
        local tMemberInfo = hTeam.GetMemberInfoByGlobalID(szGlobalID)
        if tMemberInfo then
            return tMemberInfo.dwMemberID
        end
    end
end

local bEditRaid = false
local nOptCount = 1
local tPlayerPos = {}
--- 一键同步房间顺序到系统队（只能从队伍里取globalid做）
function RoomData.SyncRoomQueueToTeam(tPos)
    if not RoomData.IsRoomOwner() then
        OutputMessage("MSG_SYS", g_tStrings.STR_ROOM_ONLY_OWNER)
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_ROOM_ONLY_OWNER)
        return
    end

    local player = GetClientPlayer()
    if player and player.IsInParty() and TeamData.IsTeamLeader() then
        if bEditRaid then
            return
        end

        bEditRaid = true
        nOptCount = 1

        if type(tPos) == "table" then
            tPlayerPos = clone(tPos)
        else
            tPlayerPos = {}
            local tRoomInfo = GetGlobalRoomClient().GetGlobalRoomInfo()
            for _, v in pairs(tRoomInfo) do
                if type(v) == "table" and v.szGlobalID then
                    tPlayerPos[v.nMemberIndex] = v.szGlobalID
                end
            end
        end

        RoomData.OnMemberChangeGroup()

        Timer.Add(RoomData, 5, function() --5s应该可以调完25人队
            bEditRaid = false
            nOptCount = 1
            tPlayerPos = {}
        end)
    else
        OutputMessage("MSG_SYS", g_tStrings.STR_ROOM_TEAM_LEADER_SAME)
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_ROOM_TEAM_LEADER_SAME)
    end
end

function RoomData.OnMemberChangeGroup()
    if not bEditRaid then
        return
    end

    if nOptCount > MAX_ROOM_NUM then
        bEditRaid = false
        nOptCount = 1
        tPlayerPos = {}
        return
    end

    local function IsRightTeam(gID, nGroupID)
        if not gID then
            return false
        end

        local dwStart = nGroupID * GROUP_SIZE + 1
        for i = dwStart, dwStart + 4 do
            if tPlayerPos[i] and tPlayerPos[i] == gID then
                return true
            end
        end
        return false
    end

    local player = GetClientPlayer()
    local hTeam = GetClientTeam()
    local bDelay = false
    if player and player.IsInParty() and TeamData.IsTeamLeader() then
        if tPlayerPos[nOptCount] then
            local szGlobalID = tPlayerPos[nOptCount]
            local tMemberInfo = hTeam.GetMemberInfoByGlobalID(szGlobalID)
            if tMemberInfo then
                local bChange = false
                local nGroupIndex = math.floor((nOptCount - 1) / 5)
                local tGroupInfo = hTeam.GetGroupInfo(nGroupIndex)
                if tGroupInfo and tGroupInfo.MemberList then
                    for _, dwID in ipairs(tGroupInfo.MemberList) do
                        local tInfo = hTeam.GetMemberInfo(dwID)
                        if tInfo then
                            if dwID == tMemberInfo.dwMemberID then
                                bChange = true
                                break
                            end

                            if not IsRightTeam(tInfo.szGlobalID, nGroupIndex) then
                                hTeam.ChangeMemberGroup(tMemberInfo.dwMemberID, nGroupIndex, dwID)
                                bDelay = true
                                bChange = true
                                break
                            end
                        end
                    end

                    if not bChange then
                        hTeam.ChangeMemberGroup(tMemberInfo.dwMemberID, nGroupIndex)
                        bDelay = true
                    end
                end
            end
        end
    end

    nOptCount = nOptCount + 1
    if bDelay then
        Timer.Add(self, 0.1, function()
            RoomData.OnMemberChangeGroup()
        end)
    else
        RoomData.OnMemberChangeGroup()
    end
end

--- 一键查询房间在线情况
function RoomData.SyncRoomOnlineFlag()
    local tOfflineList = GetGlobalRoomClient().GetOfflineMemberList()
    local nOffline = #tOfflineList
    local nTotalCount = RoomData.GetSize()
    local szMsg = string.format("%s\n%s", g_tStrings.STR_ROOM_ONLINE_FLAG_TITLE, FormatString(g_tStrings.STR_ROOM_ONLINE_FLAG_TOTAL, nTotalCount, nTotalCount - nOffline, nOffline))
    local scriptView = UIHelper.ShowConfirm(szMsg)
    scriptView:HideButton("Cancel")
end

function RoomData.ShareRoomToChat()
    local szRoomID = GetGlobalRoomClient().GetGlobalRoomID()
    if szRoomID then
        local szGlobalID =  RoomData.GetRoomOwner()
        local tMemberInfo = RoomData.GetRoomMemberInfo(szGlobalID)
        local szRoomID = GetGlobalRoomClient().GetGlobalRoomID()
        local szOwnerName = UIHelper.GBKToUTF8(RoomData.GetGlobalName(tMemberInfo.szName, tMemberInfo.dwCenterID, true))
        local szEditLink = FormatString(g_tStrings.STR_ROOM_SHARE_TITLE, szOwnerName)
        ChatHelper.SendEventLinkToChat(szEditLink, "GlobalRoom/" .. szRoomID)
    end
end

function RoomData.ApplyGlobalRoomByRoomID(szRoomID)
    if szRoomID then
        UIHelper.ShowConfirm(g_tStrings.STR_ROOM_APPLY_TO_JOIN_MSG, function()
            GetGlobalRoomClient().ApplyJoinGlobalRoomByRoomID(szRoomID)
        end)
    end
end

function RoomData.InsertRoomInviteMenu(tbMenus, szGlobalID)
    table.insert(tbMenus, {
        szName = "房间",
        bCloseOnClick = true,
        callback = function()
            if RoomData.IsRoomOwner() then
                if szGlobalID then
                    GetGlobalRoomClient().InviteJoinGlobalRoom(szGlobalID)
                end
            else
                if szGlobalID then
                    GetGlobalRoomClient().JoinGlobalRoom(szGlobalID)
                end
            end
        end,
        fnDisable = function()
            return CheckPlayerIsRemote("")
        end
    })
    return tbMenus
end

function RoomData.GetGlobalName(szName, nCenterID, bRemote) --bRemote 同服也带后缀
	if nCenterID and (nCenterID ~= UI_GetClientPlayerCenterID() or bRemote) then
		local szCenterName = GetCenterNameByCenterID(nCenterID)
		if szCenterName and szCenterName ~= "" then
			szName = szName .. UIHelper.UTF8ToGBK("·") .. szCenterName
		end
	end
	return szName
end

-- local function OnCreateGlobalRoom()
--     if not RoomPanel.IsOpened() then
--         RoomPanel.Open()
--     end
-- end

-- local function OnLeaveGlobalRoom()
--     RoomPanel.Close()
-- end

-- Event.Reg(RoomData, "LEAVE_GLOBAL_ROOM", OnLeaveGlobalRoom)

-- local function OnCheckCreate()
--     local hRoom = GetGlobalRoomClient()
--     if hRoom then
--         if hRoom.GetGlobalRoomID()then
--             GetGlobalRoomClient().ApplyBaseInfo()
--             if not RoomPanel.IsOpened() then
--                 RoomPanel.Open()
--             end
--         end
--     end
-- end

Event.Reg(RoomData, "LOADING_END", function()
    if self.bGlobalRoomClientBaseInfo then
        return
    end

    local hRoom = GetGlobalRoomClient()
    if hRoom then
        if hRoom.GetGlobalRoomID() then
            GetGlobalRoomClient().ApplyBaseInfo()
        end
    end

    self.bGlobalRoomClientBaseInfo = true
end)

Event.Reg(self, EventType.OnAccountLogout, function()
    self.bGlobalRoomClientBaseInfo = false
end)

-- local function OnLoadingEnd()
--     Event.UnReg(RoomData, "FIRST_LOADING_END")
--     -- TeamSwitchBtn.Open()
-- end

-- Event.Reg(RoomData, "FIRST_LOADING_END", OnLoadingEnd)
Event.Reg(RoomData, "TEAM_CHANGE_MEMBER_GROUP", RoomData.OnMemberChangeGroup)
-- Event.Reg(RoomData, "CREATE_GLOBAL_ROOM", OnCreateGlobalRoom)
-- Event.Reg(RoomData, "JOIN_GLOBAL_ROOM", OnCreateGlobalRoom)
-- Event.Reg(RoomData, "GLOBAL_ROOM_BASE_INFO", OnCreateGlobalRoom)

Event.Reg(RoomData, "ON_GLOBAL_ROOM_MESSAGE_NOTIFY", function()
    local nResultCode, szName, szRoomID = arg0, arg1, arg2
    if g_tStrings.tGlobalRoomErrorResult[nResultCode] then
        OutputMessage("MSG_SYS", g_tStrings.tGlobalRoomErrorResult[nResultCode])
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.tGlobalRoomErrorResult[nResultCode])
    end

    if nResultCode == GLOBAL_ROOM_RESULT_CODE.INVITE_ALL_JOIN_SCENE then --房主一键邀请成员回调
        if not IsRemotePlayer(UI_GetClientPlayerID()) then
            UIHelper.ShowConfirm(g_tStrings.STR_ROOM_INVITE_JOIN_MAP, function()
                MapMgr.BeforeTeleport()
                RemoteCallToServer("On_Team_RoomToEnterScene")
            end)
        end
    elseif nResultCode == GLOBAL_ROOM_RESULT_CODE.POS_CHANGE_SUCCESS then
        RoomData.bDelaySyncToTeam = Storage.Team.bEnableRoomAutoSyncToTeam
        TipsHelper.OutputMessage("MSG_SYS", g_tStrings.tGlobalRoomMsgResult[nResultCode])
    end
end)

Event.Reg(RoomData, "GLOBAL_ROOM_CONFIRM_ENTER_SCENE_NOTIFY", function()
    local dwMapID, nCopyIndex, nCenterIndex = arg0, arg1, arg2
    local nCountTime 	= 30
    local Dialog = UIHelper.ShowConfirm(g_tStrings.STR_ROOM_OWNER_JOINMAP_CONFIRM, function()
        GetGlobalRoomClient().ConfirmEnterScene(true, dwMapID, nCopyIndex, nCenterIndex)
    end)
    Dialog:SetConfirmNormalCountDownWithCallback(nCountTime, function()
        GetGlobalRoomClient().ConfirmEnterScene(true, dwMapID, nCopyIndex, nCenterIndex)
    end)
end)

Event.Reg(RoomData, "GLOBAL_ROOM_APPLY_ENTER_SCENE", function()
    local nResultCode = arg0
    if g_tStrings.tGlobalRoomErrorResult[nResultCode] then
        TipsHelper.OutputMessage("MSG_SYS", g_tStrings.tGlobalRoomErrorResult[nResultCode])
    end
end)

Event.Reg(RoomData, "GLOBAL_ROOM_CONFIRM_ENTER_SCENE_RESPOND", function()
    local nResultCode = arg0
    if g_tStrings.tGlobalRoomErrorResult[nResultCode] then
        TipsHelper.OutputMessage("MSG_SYS", g_tStrings.tGlobalRoomErrorResult[nResultCode])
    end
end)

Event.Reg(self, "GLOBAL_ROOM_CREATE", function()
    local nResultCode, szRoomID = arg0, arg1
    if nResultCode == GLOBAL_ROOM_RESULT_CODE.SUCCESS then
        TipsHelper.OutputMessage("MSG_SYS", g_tStrings.STR_ROOM_CREATE_SUCCESS)
        FireUIEvent("CREATE_GLOBAL_ROOM")

        --队长，建房同步给成员
        local player = GetClientPlayer()
        if player and player.IsInParty() and player.IsPartyLeader() then
            UIHelper.ShowConfirm(g_tStrings.STR_ROOM_SYNC_TEAMMATE_JOIN_ROOM, function()
                GetGlobalRoomClient().InviteTeamMemberJoinGlobalRoom()
            end)
        end
    else
        if g_tStrings.tGlobalRoomErrorResult[nResultCode] then
            TipsHelper.OutputMessage("MSG_SYS", g_tStrings.tGlobalRoomErrorResult[nResultCode])
        end
    end
end)

Event.Reg(self, "GLOBAL_ROOM_DESTROY", function()
    local nResultCode = arg0
    if nResultCode == GLOBAL_ROOM_RESULT_CODE.SUCCESS then
        TipsHelper.OutputMessage("MSG_SYS", g_tStrings.STR_ROOM_DESTROY_SUCCESS)
        FireUIEvent("LEAVE_GLOBAL_ROOM")
    else
        if g_tStrings.tGlobalRoomErrorResult[nResultCode] then
            TipsHelper.OutputMessage("MSG_SYS", g_tStrings.tGlobalRoomErrorResult[nResultCode])
        end
    end
end)

Event.Reg(self, "GLOBAL_ROOM_NOTIFY", function()
    local nResultCode, szRoomID = arg0, arg1
    if nResultCode == GLOBAL_ROOM_RESULT_CODE.SUCCESS then
        local player = GetClientPlayer()
        if player.GetGlobalRoomID() then
            TipsHelper.OutputMessage("MSG_SYS", g_tStrings.STR_ROOM_JOIN_MSG)
            FireUIEvent("JOIN_GLOBAL_ROOM")
        else
            TipsHelper.OutputMessage("MSG_SYS", g_tStrings.STR_ROOM_LEAVE_MSG)
            FireUIEvent("LEAVE_GLOBAL_ROOM")
        end
    elseif nResultCode == GLOBAL_ROOM_RESULT_CODE.APPLY_JOIN_REJECT or nResultCode == GLOBAL_ROOM_RESULT_CODE.INVIT_JOIN_REJECT then
        local szName = arg2 or ""
        local szTip = "\"" .. UIHelper.GBKToUTF8(szName).. "\"" .. g_tStrings.tGlobalRoomMsgResult[nResultCode]
        TipsHelper.OutputMessage("MSG_SYS", szTip)
    else
        if g_tStrings.tGlobalRoomErrorResult[nResultCode] then
            OutputMessage("MSG_SYS", g_tStrings.tGlobalRoomErrorResult[nResultCode])
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.tGlobalRoomErrorResult[nResultCode])
        end
    end
end)

Event.Reg(self, "GLOBAL_ROOM_MEMBER_CHANGE", function()
    local dwRoomID, dwGlobalID, bJoinOrLeave, pcszName, dwCenterID = arg0, arg1, arg2, arg3, arg4
    local szNameLink = RoomData.GetGlobalName(pcszName, dwCenterID, true)
    if bJoinOrLeave then
        TipsHelper.OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_ROOM_JOIN_NOTIFY, UIHelper.GBKToUTF8(szNameLink)))
    else
        TipsHelper.OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_ROOM_LEAVE_NOTIFY, UIHelper.GBKToUTF8(szNameLink)))
    end
end)

Event.Reg(self, "GLOBAL_ROOM_JOIN_REQUEST", function()
    -- if not IsRegisterEvent("GLOBAL_ROOM_JOIN_REQUEST") then
    --     FireUIEvent("FILTER_GLOBAL_ROOM_JOIN_REQUEST", arg0, arg1, arg2, arg3, arg4, arg5)
    --     return
    -- end

    -- local nJoinType, szSrcName, szGlobalID, szRoomID, dwCenterID = arg0, arg1, arg2, arg3, arg4
    -- local szName = RoomData.GetGlobalName(szSrcName, dwCenterID, true)
    -- if nJoinType == GLOBAL_ROOM_JOIN_TYPE.INVITE then
    --     UIHelper.ShowConfirm(FormatString(g_tStrings.STR_ROOM_BE_INVITE_JOIN_MSG, UIHelper.GBKToUTF8(szName)), function()
    --         GetGlobalRoomClient().RespondInviteJoinGlobalRoom(szGlobalID, true)
    --     end, function()
    --         GetGlobalRoomClient().RespondInviteJoinGlobalRoom(szGlobalID, false)
    --     end)
    -- elseif nJoinType == GLOBAL_ROOM_JOIN_TYPE.APPLY_BY_GLOBAL_ID or nJoinType == GLOBAL_ROOM_JOIN_TYPE.APPLY_BY_ROOM_ID then
    --     UIHelper.ShowConfirm(FormatString(g_tStrings.STR_ROOM_APPLY_JOIN_MSG, UIHelper.GBKToUTF8(szName)), function()
    --         GetGlobalRoomClient().RespondApplyJoinGlobalRoom(szGlobalID, true)
    --     end, function()
    --         GetGlobalRoomClient().RespondApplyJoinGlobalRoom(szGlobalID, false)
    --     end)
    -- end
end)

Event.Reg(self, "GLOBAL_ROOM_MEMBER_ONLINE_FLAG", function()
    RoomData.SyncRoomOnlineFlag()
    TipsHelper.OutputMessage("MSG_SYS", g_tStrings.STR_ROOM_TAG_TIP)
end)