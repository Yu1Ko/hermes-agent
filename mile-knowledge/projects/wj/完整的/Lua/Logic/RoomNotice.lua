-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: RoomNotice
-- Date: 2024-05-08 11:06:58
-- Desc: ?
-- ---------------------------------------------------------------------------------

RoomNotice = RoomNotice or {className = "RoomNotice"}
local self = RoomNotice
-------------------------------- 消息定义 --------------------------------
RoomNotice.Event = {}
RoomNotice.Event.XXX = "RoomNotice.Msg.XXX"

function RoomNotice.Init()
    RoomNotice.szTitle = ""
    RoomNotice.szContent = ""

    Event.Reg(self, "ON_BG_CHANNEL_MSG", function (szKey, nChannel, dwTalkerID, szName, aParam)
        if szKey == "ROOM_NOTICE" and nChannel == PLAYER_TALK_CHANNEL.ROOM then
            if aParam then  -- {{szTitle, szContent}, szGlobalID}
                if  aParam[2] == "" or aParam[2] == UI_GetClientPlayerGlobalID() then
                    RoomNotice.szTitle = UIHelper.GBKToUTF8(aParam[1][1])
                    RoomNotice.szContent = UIHelper.GBKToUTF8(aParam[1][2])

                    if dwTalkerID == UI_GetClientPlayerID() and aParam[2] == "" then
                        TipsHelper.ShowNormalTip(g_tStrings.STR_ROOM_NOTICE_SUCCESS)
                    end
                end
            end
        elseif szKey == "ROOM_NOTICE_APPLY" and nChannel == PLAYER_TALK_CHANNEL.ROOM then
            if aParam then -- {szGlobalID}
                if RoomData.GetRoomOwner() == UI_GetClientPlayerGlobalID() and (RoomNotice.szTitle ~= "" or RoomNotice.szContent ~= "") then
                    local szTitle = UIHelper.UTF8ToGBK(RoomNotice.szTitle)
                    local szContent = UIHelper.UTF8ToGBK(RoomNotice.szContent)

                    SendBgMsg(PLAYER_TALK_CHANNEL.ROOM, "ROOM_NOTICE", {szTitle, szContent}, aParam[1])
                end
            end
        end
    end)

    Event.Reg(self, EventType.OnRoleLogin, function()
        Event.Reg(self, "LOADING_END", function()
            RoomNotice.szTitle = ""
            RoomNotice.szContent = ""
        end, true)
    end)

    Event.Reg(self, "LEAVE_GLOBAL_ROOM", function()
        RoomNotice.szTitle = ""
        RoomNotice.szContent = ""
    end)

    Event.Reg(self, "GLOBAL_ROOM_MEMBER_CHANGE", function(_, szGlobalID, bJoinOrLeave)
        if bJoinOrLeave then
            if RoomData.GetRoomOwner() == UI_GetClientPlayerGlobalID() and (RoomNotice.szTitle ~= "" or RoomNotice.szContent ~= "") then
                local szTitle = UIHelper.UTF8ToGBK(RoomNotice.szTitle)
                local szContent = UIHelper.UTF8ToGBK(RoomNotice.szContent)

                SendBgMsg(PLAYER_TALK_CHANNEL.ROOM, "ROOM_NOTICE", {szTitle, szContent}, szGlobalID)
            end
        end
    end)
end

function RoomNotice.UnInit()

end

function RoomNotice.OnLogin()

end

function RoomNotice.OnFirstLoadEnd()

end