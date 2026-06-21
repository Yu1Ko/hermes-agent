-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: WidgetRoomChatRecordCell
-- Date: 2025-09-10 16:19:19
-- Desc: ?
-- ---------------------------------------------------------------------------------

local WidgetRoomChatRecordCell = class("WidgetRoomChatRecordCell")

function WidgetRoomChatRecordCell:OnEnter(tbInfo, nWidth)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if nWidth then
        UIHelper.SetWidth(self._rootNode, nWidth)
        UIHelper.SetWidth(self.RichTextRoomChatRecord, nWidth)
    end
    self.tbInfo = tbInfo
    self:UpdateInfo()
end

function WidgetRoomChatRecordCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function WidgetRoomChatRecordCell:BindUIEvent()

end

function WidgetRoomChatRecordCell:RegEvent()
    Event.Reg(self, "SYNC_VOICE_MEMBER_SOCIAL_INFO", function(tbGlobalID)
        if table.contain_value(tbGlobalID, self.tbInfo.szGlobalID) then
            self:UpdateInfo()
        end
    end)
end

function WidgetRoomChatRecordCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function WidgetRoomChatRecordCell:UpdateInfo()
    local tbInfo = self.tbInfo
    if not tbInfo then
        return
    end

    local tbMemberInfo = RoomVoiceData.GetVoiceRoomMemberSocialInfo(tbInfo.szGlobalID)
    if not tbMemberInfo then
        return
    end
    local tNowTime = TimeToDate(tbInfo.nTime)
    local szTime = FormatString(g_tStrings.STR_TIME_2, tNowTime.year, tNowTime.month, tNowTime.day, tNowTime.hour, tNowTime.minute, tNowTime.second)
    local szAction = tbInfo.bIn and "加入" or "离开"
    local szContent = UIHelper.GBKToUTF8(tbMemberInfo.szName) .. "于" .. szTime .. szAction .. "了语音聊天室"
    UIHelper.SetRichText(self.RichTextRoomChatRecord, "<color=#AED6E0>"..szContent.."</color>")
    UIHelper.LayoutDoLayout(self._rootNode)
    self:DoAlign()
end

function WidgetRoomChatRecordCell:DoAlign()
    if self.nTimer then
        Timer.DelTimer(self, self.nTimer)
    end
    self.nTimer = Timer.AddFrame(self, 1, function()
        UIHelper.WidgetFoceDoAlign(self)
        self.nTimer = nil
    end)
end


return WidgetRoomChatRecordCell