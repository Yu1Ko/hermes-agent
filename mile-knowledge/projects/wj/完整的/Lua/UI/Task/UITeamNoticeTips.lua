-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITeamNoticeTips
-- Date: 2024-05-07 10:38:10
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UITeamNoticeTips = class("UITeamNoticeTips")

function UITeamNoticeTips:OnEnter(bRoomNotice, tbBallScript)
    self.tbBallScript = tbBallScript
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.bRoomNotice = bRoomNotice
    if self.bRoomNotice then
        UIHelper.SetRichText(self.LabelInfoTitle, g_tStrings.STR_ROOM_NOTICE)
    else
        UIHelper.SetRichText(self.LabelInfoTitle, g_tStrings.STR_TEAM_NOTICE)
    end
end

function UITeamNoticeTips:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITeamNoticeTips:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIHelper.SetVisible(self.WidgetTeamNoticeTips, false)
        self.tbBallScript:UpdateVisible()
    end)

    UIHelper.BindUIEvent(self.BtnSent, EventType.OnClick, function ()
        local szUIChannel = "UI_Channel_Party"
        local szTitle = TeamNotice.szTitle
        if self.bRoomNotice then
            szUIChannel = "UI_Channel_Room"
            szTitle = RoomNotice.szTitle
        end

        local szContent = self.szContent or ""

        self:Send(g_tStrings.STR_SEND_NOTICE_TITLE .. tostring(szTitle) .. ":" .. tostring(szContent), szUIChannel)
    end)

    UIHelper.BindUIEvent(self.BtnCopy, EventType.OnClick, function ()
        local szTitle
        if self.bRoomNotice then
            szTitle = RoomNotice.szTitle
        else
            szTitle = TeamNotice.szTitle
        end

        local msg = szTitle
        if Platform.IsWindows() then
            msg = UIHelper.UTF8ToGBK(szTitle)
        end
        SetClipboard(msg)

        TipsHelper.ShowNormalTip("复制成功。")
    end)

    UIHelper.BindUIEvent(self.BtnEdit, EventType.OnClick, function ()
        if self.bRoomNotice then
            if RoomData.GetRoomOwner() == UI_GetClientPlayerGlobalID() then
                UIMgr.Open(VIEW_ID.PanelTeamNoticeEditPop, true)
            else
                if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TALK, "player talk") then
                    return
                end

                SendBgMsg(PLAYER_TALK_CHANNEL.ROOM, "ROOM_NOTICE_APPLY", UI_GetClientPlayerGlobalID())
                TipsHelper.ShowNormalTip(g_tStrings.STR_ROOM_NOTICE_APPLY)
            end
        else
            if TeamData.IsTeamLeader() then
                UIMgr.Open(VIEW_ID.PanelTeamNoticeEditPop, false)
            else
                if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TALK, "player talk") then
                    return
                end

                SendBgMsg(PLAYER_TALK_CHANNEL.RAID, "RAID_NOTICE_APPLY", UI_GetClientPlayerGlobalID())
                TipsHelper.ShowNormalTip(g_tStrings.STR_TEAM_NOTICE_APPLY)
            end
        end
    end)
end

function UITeamNoticeTips:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "TEAM_AUTHORITY_CHANGED", function ()
        local bLeader
        if self.bRoomNotice then
            bLeader = RoomData.GetRoomOwner() == UI_GetClientPlayerGlobalID()
        else
            bLeader = g_pClientPlayer.IsPartyLeader()
        end

        UIHelper.SetVisible(self.BtnSent, bLeader)
        UIHelper.SetVisible(self.BtnCopy, not bLeader)
    end)

    Event.Reg(self, "GLOBAL_ROOM_DETAIL_INFO", function()
        local bLeader
        if self.bRoomNotice then
            bLeader = RoomData.GetRoomOwner() == UI_GetClientPlayerGlobalID()
        else
            bLeader = g_pClientPlayer.IsPartyLeader()
        end

        UIHelper.SetVisible(self.BtnSent, bLeader)
        UIHelper.SetVisible(self.BtnCopy, not bLeader)
    end)
end

function UITeamNoticeTips:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITeamNoticeTips:SetTeamNotice(szTitle, szContent)
    self.szContent = szContent

    local szTeamTitle = "<color=ffffff>" .. "标题：" ..szTitle .. "</c>"
    local szTeamContent = "<color=AED9E0>" .. szContent .. "</c>"
    UIHelper.SetRichText(self.LabelInfo, szTeamTitle .. "\n" .. szTeamContent)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewOther)

    local bLeader
    if self.bRoomNotice then
        bLeader = RoomData.GetRoomOwner() == UI_GetClientPlayerGlobalID()
    else
        bLeader = g_pClientPlayer.IsPartyLeader()
    end

    UIHelper.SetVisible(self.BtnSent, bLeader)
    UIHelper.SetVisible(self.BtnCopy, not bLeader)
end

function UITeamNoticeTips:Send(szTitle, szUIChannel)
    local nChannelID = self.bRoomNotice and PLAYER_TALK_CHANNEL.ROOM or PLAYER_TALK_CHANNEL.RAID
    local nCDTime = ChatData.GetChannelSendCDTime(nChannelID)
    if nCDTime > 0 then
        TipsHelper.ShowNormalTip(g_tStrings.tTalkError[PLAYER_TALK_ERROR.SCENE_CD])
        return
    end

    local tbMsg = ChatParser.Parse(szTitle)

    local bResult = ChatData.Send(nChannelID, nil, tbMsg, nil)

    if bResult then
        ChatData.RecordSendTime(nChannelID)
    end
end

return UITeamNoticeTips