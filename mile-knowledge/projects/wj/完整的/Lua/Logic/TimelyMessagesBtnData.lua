TimelyMessagesBtnData = TimelyMessagesBtnData or {className = "TimelyMessagesBtnData"}
local self = TimelyMessagesBtnData

TimelyMessagesType = {
    --队伍
    Team = 1,
    Room = 2,
    Friend = 3,
    AssistNewbie = 4,
}

function TimelyMessagesBtnData.Init()
    self.tbMessageBtnInfos = {}
    self.RegEvent()
    self.nUpdateTimerID = Timer.AddCycle(self, 1, self.OnUpdate)
end

function TimelyMessagesBtnData.UnInit()
    self.tbMessageBtnInfos = {}

end

function TimelyMessagesBtnData.OnUpdate()
    for nType, tbInfos in pairs(self.tbMessageBtnInfos) do
        local i = #tbInfos
        while i > 0 do
            local tbInfo = tbInfos[i]
            if self.CheckTimeOut(tbInfo) then
                self.RemoveBtnInfo(nType, tbInfo, true)
            end
            i = i - 1
        end
    end

end

function TimelyMessagesBtnData.RegEvent()
    Event.Reg(self, "PARTY_INVITE_REQUEST", function(...)
        if not IsRegisterEvent("PARTY_INVITE_REQUEST") then
            --FireUIEvent("FILTER_PARTY_INVITE_REQUEST", arg0, arg1, arg2, arg3, arg4, arg5)
            return
        end

        local szSrc = arg0
        if IsFilterOperate("PARTY_INVITE_REQUEST") then
            TeamData.RespondTeamInvite(szSrc, 0)
            return
        end

        local tbParams = {...}
        local nType = tbParams[5] -- arg4
        if nType == 2 then -- 招募的邀请不走这里
            return
        end

        if nType == 3 then
            TeamData.RespondTeamInvite(szSrc, 1)
            RemoteCallToServer("On_Identity_AutoJoinResponse", GetPlayerByName(szSrc).dwID)
            return
        end

        if FellowshipData.IsInBlackListByPlayerID(tbParams[12]) then--在黑名单
            -- TeamData.RespondTeamInvite(szSrc, 0)
            return
        end

        TimelyMessagesBtnData.AddBtnInfo(TimelyMessagesType.Team, {
            szTitle         = "邀请组队列表",
            nTotalTime 	    = 60,
            funcClickBtn    = function()
                UIMgr.Open(VIEW_ID.PanelInvitationMessagePop, TimelyMessagesType.Team)
            end,
            funcConfirm     = function ()
                local szInviteSrc, dwSrcCamp, dwSrcForceID, dwSrcLevel, nType, nParam = table.unpack(tbParams)
                TeamData.RespondTeamInvite(szInviteSrc, 1)
            end,
            funcCancel      = function ()
                local szInviteSrc, dwSrcCamp, dwSrcForceID, dwSrcLevel, nType, nParam = table.unpack(tbParams)
                TeamData.RespondTeamInvite(szInviteSrc, 0)
            end,
            tbParams = tbParams,
        })
    end)

    Event.Reg(self, "PARTY_APPLY_REQUEST", function(...)
        if not IsRegisterEvent("PARTY_APPLY_REQUEST") then
            return
        end
        if IsFilterOperate("PARTY_APPLY_REQUEST") then
            GetClientTeam().RespondTeamApply(arg0, 0)
            return
        end

        local tbParams = {...}
        if FellowshipData.IsInBlackListByPlayerID(tbParams[12]) then--在黑名单
            -- GetClientTeam().RespondTeamApply(arg0, 0)
            return
        end 
        TimelyMessagesBtnData.AddBtnInfo(TimelyMessagesType.Team, {
            szTitle         = "申请组队列表",
            nTotalTime 	    = 60,
            funcClickBtn    = function ()
                UIMgr.Open(VIEW_ID.PanelInvitationMessagePop, TimelyMessagesType.Team)
            end,
            funcConfirm     = function ()
                local szSrc = table.unpack(tbParams)
		        GetClientTeam().RespondTeamApply(szSrc, 1)
            end,
            funcCancel      = function ()
                local szSrc = table.unpack(tbParams)
		        GetClientTeam().RespondTeamApply(szSrc, 0)
            end,
            tbParams = tbParams,
        })
    end)

    Event.Reg(self, "GLOBAL_ROOM_JOIN_REQUEST", function(...)
        if not IsRegisterEvent("GLOBAL_ROOM_JOIN_REQUEST") then
            -- FireUIEvent("FILTER_GLOBAL_ROOM_JOIN_REQUEST", arg0, arg1, arg2, arg3, arg4, arg5)
            return
        end

        local tbParams = {...}
        local nJoinType, szSrcName, szGlobalID, szRoomID, dwCenterID = table.unpack(tbParams)
        if FellowshipData.IsInBlackList(szGlobalID) then
            if nJoinType == GLOBAL_ROOM_JOIN_TYPE.INVITE then
				GetGlobalRoomClient().RespondInviteJoinGlobalRoom(arg2, false)
			elseif nJoinType == GLOBAL_ROOM_JOIN_TYPE.APPLY_BY_GLOBAL_ID or nJoinType == GLOBAL_ROOM_JOIN_TYPE.APPLY_BY_ROOM_ID then
				GetGlobalRoomClient().RespondApplyJoinGlobalRoom(arg2, false)
			end
            return 
        end
        if nJoinType == GLOBAL_ROOM_JOIN_TYPE.INVITE then
            TimelyMessagesBtnData.AddBtnInfo(TimelyMessagesType.Room, {
                szTitle         = "邀请房间列表",
                nTotalTime 	    = 60,
                funcClickBtn    = function ()
                    UIMgr.Open(VIEW_ID.PanelInvitationMessagePop, TimelyMessagesType.Room)
                end,
                funcConfirm     = function ()
                    GetGlobalRoomClient().RespondInviteJoinGlobalRoom(szGlobalID, true)
                end,
                funcCancel      = function ()
                    GetGlobalRoomClient().RespondInviteJoinGlobalRoom(szGlobalID, false)
                end,
                tbParams = tbParams,
            })
        elseif nJoinType == GLOBAL_ROOM_JOIN_TYPE.APPLY_BY_GLOBAL_ID or nJoinType == GLOBAL_ROOM_JOIN_TYPE.APPLY_BY_ROOM_ID then
            TimelyMessagesBtnData.AddBtnInfo(TimelyMessagesType.Room, {
                szTitle         = "申请房间列表",
                nTotalTime 	    = 60,
                funcClickBtn    = function ()
                    UIMgr.Open(VIEW_ID.PanelInvitationMessagePop, TimelyMessagesType.Room)
                end,
                funcConfirm     = function ()
                    GetGlobalRoomClient().RespondApplyJoinGlobalRoom(szGlobalID, true)
                end,
                funcCancel      = function ()
                    GetGlobalRoomClient().RespondApplyJoinGlobalRoom(szGlobalID, false)
                end,
                tbParams = tbParams,
            })
        end
    end)

    Event.Reg(self, "PLAYER_LEAVE_GAME", function()
        self.tbMessageBtnInfos = {}
    end)

    Event.Reg(self, EventType.OnUpdateMessageBtnInfo, function (nType)
        if nType == TimelyMessagesType.Team then
            TipsHelper.ShowTeamTip()
        elseif nType == TimelyMessagesType.AssistNewbie then
            TipsHelper.ShowAssistNewbieInviteTip()
        elseif nType == TimelyMessagesType.Room then
            TipsHelper.ShowRoomTip()
        end
    end)
end

function TimelyMessagesBtnData.AddBtnInfo(nType, tbInfo)
    if not tbInfo then return end
    tbInfo.nType = nType
    tbInfo.nTimestamp = GetTickCount()

    self.tbMessageBtnInfos[nType] = self.tbMessageBtnInfos[nType] or {}

    if self.CheckIsInList(nType, tbInfo) then
        return
    end

    table.insert(self.tbMessageBtnInfos[nType], tbInfo)

    Event.Dispatch(EventType.OnUpdateMessageBtnInfo, nType)
    SoundMgr.PlaySound(SOUND.UI_SOUND, g_sound.Friend)


    --LOG.ERROR("--------------TimelyMessagesBtnData.AddBtnInfo nType:"..tostring(nType).."    count:"..tostring(#self.tbMessageBtnInfos[nType]))
end

function TimelyMessagesBtnData.RemoveBtnInfo(nType, tbInfo, bCallCancelFunc)
    if not tbInfo or not nType or not self.tbMessageBtnInfos[nType] then return end
    local tbInfos = self.tbMessageBtnInfos[nType]

    local i = #tbInfos
    while i > 0 do
        if tbInfos[i] == tbInfo then
            if bCallCancelFunc and tbInfo.funcCancel then
                tbInfo.funcCancel(tbInfo)
            end
            table.remove(tbInfos, i)
            Event.Dispatch(EventType.OnUpdateMessageBtnInfo, nType)
            return
        end
        i = i - 1
    end
    --LOG.ERROR("--------------TimelyMessagesBtnData.RemoveBtnInfo nType:"..tostring(nType).."    count:"..tostring(#self.tbMessageBtnInfos[nType]))
end

function TimelyMessagesBtnData.RemoveAllBtnInfo(nType, bCallCancelFunc)
    if not tbInfo or not nType or not self.tbMessageBtnInfos[nType] then return end
    local tbInfos = self.tbMessageBtnInfos[nType]

    local i = #tbInfos
    while i > 0 do
        if bCallCancelFunc and tbInfo.funcCancel then
            tbInfo.funcCancel(tbInfo)
        end
        i = i - 1
    end

    self.tbMessageBtnInfos[nType] = {}
    Event.Dispatch(EventType.OnUpdateMessageBtnInfo, nType)
end

function TimelyMessagesBtnData.GetBtnInfos(nType)
    if not nType then return end

    return self.tbMessageBtnInfos[nType] or {}
end

function TimelyMessagesBtnData.OnClickBtn(nType)
    if not nType or not self.tbMessageBtnInfos[nType] then return end
    local tbInfos = self.tbMessageBtnInfos[nType]

    local i = #tbInfos
    while i > 0 do
        local tbInfo = tbInfos[i]
        if tbInfo.funcClickBtn then
            tbInfo.funcClickBtn(nType)
            return
        end
        i = i - 1
    end
end

function TimelyMessagesBtnData.CheckTimeOut(tbInfo)
    if tbInfo.nTotalTime and tbInfo.nTotalTime > 0 then
        if GetTickCount() - tbInfo.nTimestamp >= tbInfo.nTotalTime * 1000 then
            return true
        end
    end

    return false
end

function TimelyMessagesBtnData.CheckIsInList(nType, tbInfo)
    for i, tb in ipairs(self.tbMessageBtnInfos[nType]) do
        if nType == TimelyMessagesType.Team then
            local szInviteSrc1 = table.unpack(tb.tbParams)
            local szInviteSrc2 = table.unpack(tbInfo.tbParams)
            if szInviteSrc1 == szInviteSrc2 then
                return true
            end
        end
        if nType == TimelyMessagesType.Room then
            local _, _, szGlobalID1 = table.unpack(tb.tbParams)
            local _, _, szGlobalID2 = table.unpack(tbInfo.tbParams)
            if szGlobalID1 == szGlobalID2 then
                return true
            end
        end
    end

    return false
end

function TimelyMessagesBtnData.GetMaxLeftTime(nType)
    local nLeftTime = 0
    local nTotalTime = 0
    local tbInfos = TimelyMessagesBtnData.GetBtnInfos(nType)
    for i, tbInfo in ipairs(tbInfos) do
        local nTempLeftTime = (tbInfo.nTotalTime - (GetTickCount() - tbInfo.nTimestamp) / 1000)
        if nTempLeftTime > nLeftTime then
            nLeftTime = nTempLeftTime
            nTotalTime = tbInfo.nTotalTime
        end
    end
    return nLeftTime, nTotalTime
end