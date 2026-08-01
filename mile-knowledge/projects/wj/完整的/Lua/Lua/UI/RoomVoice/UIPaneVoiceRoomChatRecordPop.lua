-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPaneVoiceRoomChatRecordPop
-- Date: 2025-06-05 10:50:47
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPaneVoiceRoomChatRecordPop = class("UIPaneVoiceRoomChatRecordPop")

function UIPaneVoiceRoomChatRecordPop:OnEnter(szRoomID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.szRoomID = szRoomID
    self:UpdateInfo()
end

function UIPaneVoiceRoomChatRecordPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPaneVoiceRoomChatRecordPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIPaneVoiceRoomChatRecordPop:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPaneVoiceRoomChatRecordPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPaneVoiceRoomChatRecordPop:UpdateInfo()
    local szRoomID = self.szRoomID
    local tbInfo = RoomVoiceData.GetVoiceRoomInfo(szRoomID)
    local szDescription = tbInfo.szDescription ~= "" and UIHelper.GBKToUTF8(tbInfo.szDescription) or "暂无公告"
    UIHelper.SetString(self.LabelAnnouncement, szDescription)
    self:UpdateRecordList()
    UIHelper.LayoutDoLayout(self.LayoutAnnouncement)
    UIHelper.LayoutDoLayout(self.LayoutMainContent)
end

function UIPaneVoiceRoomChatRecordPop:UpdateRecordList()
    UIHelper.RemoveAllChildren(self.ScrollViewRoomChatRecordList)
    local tbRecord = RoomVoiceData.GetRecord(self.szRoomID)
    local tbGlobalIDList = {}
    for nIndex, tbInfo in ipairs(tbRecord) do
        local tbMember = RoomVoiceData.GetVoiceRoomMemberSocialInfo(tbInfo.szGlobalID)
        if not tbMember then
            table.insert(tbGlobalIDList, tbInfo.szGlobalID)
        end
        UIHelper.AddPrefab(PREFAB_ID.WidgetRoomChatRecordCell, self.ScrollViewRoomChatRecordList, tbInfo)
    end
    if #tbGlobalIDList > 0 then
        RoomVoiceData.ApplyVoiceMemberSocialInfo(tbGlobalIDList)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewRoomChatRecordList)
end


return UIPaneVoiceRoomChatRecordPop