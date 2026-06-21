-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: TeamNotice
-- Date: 2024-05-07 17:57:05
-- Desc: ?
-- ---------------------------------------------------------------------------------

TeamNotice = TeamNotice or {className = "TeamNotice"}
local self = TeamNotice
-------------------------------- 消息定义 --------------------------------
TeamNotice.Event = {}
TeamNotice.Event.XXX = "TeamNotice.Msg.XXX"

function TeamNotice.Init()
    TeamNotice.szTitle = ""
    TeamNotice.szContent = ""

    Event.Reg(self, "ON_BG_CHANNEL_MSG", function (szKey, nChannel, dwTalkerID, szName, aParam)
        if szKey == "RAID_NOTICE" and nChannel == PLAYER_TALK_CHANNEL.RAID then
            if aParam then   -- {{szTitle, szContent}, szGlobalID}
                if aParam[2] == "" or aParam[2] == UI_GetClientPlayerGlobalID() then
                    TeamNotice.szTitle = UIHelper.GBKToUTF8(aParam[1][1])
                    TeamNotice.szContent = UIHelper.GBKToUTF8(aParam[1][2])

                    if dwTalkerID == UI_GetClientPlayerID() and aParam[2] == "" then
                        TipsHelper.ShowNormalTip(g_tStrings.STR_TEAM_NOTICE_SUCCESS)
                    end
                end
            end
        elseif szKey == "RAID_NOTICE_APPLY" and nChannel == PLAYER_TALK_CHANNEL.RAID then
            if aParam then -- {szGlobalID}
                if g_pClientPlayer.IsPartyLeader() and (TeamNotice.szTitle ~= "" or TeamNotice.szContent ~= "") then
                    local szTitle = UIHelper.UTF8ToGBK(TeamNotice.szTitle)
                    local szContent = UIHelper.UTF8ToGBK(TeamNotice.szContent)

                    SendBgMsg(PLAYER_TALK_CHANNEL.RAID, "RAID_NOTICE", {szTitle, szContent}, aParam[1])
                end
            end
        end
    end)

    Event.Reg(self, EventType.OnRoleLogin, function()
        Event.Reg(self, "LOADING_END", function()
            TeamNotice.szTitle = ""
            TeamNotice.szContent = ""
        end, true)
    end)

    -- 上线过图的时候收不到聊天
    -- Event.Reg(self, "PARTY_SET_MEMBER_ONLINE_FLAG", function (_, dwMemberID, bOnlineFlag)
    --     if bOnlineFlag == 1 then
    --         if TeamData.IsInRaid() and g_pClientPlayer.IsPartyLeader() and (TeamNotice.szTitle ~= "" or TeamNotice.szContent ~= "") then
    --             local szTitle = UIHelper.UTF8ToGBK(TeamNotice.szTitle)
    --             local szContent = UIHelper.UTF8ToGBK(TeamNotice.szContent)
    --             local tMemberInfo = GetClientTeam().GetMemberInfo(dwMemberID)

    --             SendBgMsg(PLAYER_TALK_CHANNEL.RAID, "RAID_NOTICE", {szTitle, szContent}, tMemberInfo.szGlobalID)
    --         end
    --     end
    -- end)

    Event.Reg(self, "PARTY_ADD_MEMBER", function (_, dwMemberID, nGroupIndex)
        if g_pClientPlayer and TeamData.IsInRaid() and g_pClientPlayer.IsPartyLeader() and (TeamNotice.szTitle ~= "" or TeamNotice.szContent ~= "") then
            local szTitle = UIHelper.UTF8ToGBK(TeamNotice.szTitle)
            local szContent = UIHelper.UTF8ToGBK(TeamNotice.szContent)
            local tMemberInfo = GetClientTeam().GetMemberInfo(dwMemberID)
            SendBgMsg(PLAYER_TALK_CHANNEL.RAID, "RAID_NOTICE", {szTitle, szContent}, tMemberInfo.szGlobalID)
        end
    end)

    Event.Reg(self, "PARTY_DELETE_MEMBER", function (_, dwMemberID, _, nGroupIndex)
        if dwMemberID == UI_GetClientPlayerID() then
            TeamNotice.szTitle = ""
            TeamNotice.szContent = ""
        end
    end)

    Event.Reg(self, "PARTY_DISBAND", function ()
        TeamNotice.szTitle = ""
        TeamNotice.szContent = ""
    end)
end

function TeamNotice.UnInit()

end

function TeamNotice.OnLogin()

end

function TeamNotice.OnFirstLoadEnd()

end