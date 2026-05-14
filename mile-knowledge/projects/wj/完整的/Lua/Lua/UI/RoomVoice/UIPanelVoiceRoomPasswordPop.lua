-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelVoiceRoomPasswordPop
-- Date: 2025-06-25 16:11:28
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelVoiceRoomPasswordPop = class("UIPanelVoiceRoomPasswordPop")

function UIPanelVoiceRoomPasswordPop:OnEnter(szRoomID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.szRoomID = szRoomID
end

function UIPanelVoiceRoomPasswordPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelVoiceRoomPasswordPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        local szText = UIHelper.GetText(self.EditBoxFactionSearch)
        if string.is_nil(szText) then
            TipsHelper.ShowImportantRedTip("房间密码不能为空。")
            return
        end

        RoomVoiceData.ApplyJoinVoiceRoom(self.szRoomID, szText)
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIPanelVoiceRoomPasswordPop:RegEvent()
    Event.Reg(self, EventType.ON_JOIN_VOICE_ROOM, function(szRoomID, szSignature, bCreateRoom, bIsTeamRoom)
        if szRoomID == self.szRoomID then
            UIMgr.Close(self)
        end
    end)

    Event.Reg(self, "VOICE_ROOM_ERROR", function(nCode)
        LOG.INFO("VOICE_ROOM_ERROR nCode = %d", nCode)

        if nCode == VOICE_ROOM_NOTIFY_CODE.SUCCESS then
            UIMgr.Close(self)
            return
        end

        if nCode == 9 then-- VOICE_ROOM_NOTIFY_CODE.ERROR_ROOM_PASSSWORD then
            TipsHelper.ShowImportantRedTip("请输入正确的房间密码。")
        else
            TipsHelper.ShowImportantRedTip(string.format("加入语音房间失败，错误码：%s", tostring(nCode)))
        end
    end)
end

function UIPanelVoiceRoomPasswordPop:UnRegEvent()

end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelVoiceRoomPasswordPop:UpdateInfo()

end


return UIPanelVoiceRoomPasswordPop