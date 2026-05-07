-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: UIChatWhisperCell
-- Date: 2022-12-27 19:44:34
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIChatWhisperCell = class("UIChatWhisperCell")

function UIChatWhisperCell:OnEnter(szCurWhisper, bSelected, bIsAINpc)
    self.szCurWhisper = szCurWhisper
    self.bSelected = bSelected
    self.bIsAINpc = bIsAINpc
    self.dwID = self.szCurWhisper

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIChatWhisperCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIChatWhisperCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogWhisperPlayer, EventType.OnSelectChanged, function(btn, bSelected)
        if bSelected then
            if self.bIsAINpc then
                Event.Dispatch(EventType.OnChatAINpcSelected, self.dwID)
                return
            end

            local tbData = ChatData.GetWhisperPlayerData(self.szCurWhisper)
            ChatRecentMgr.TryLoadLocalChatData(tbData.szGlobalID)
            Event.Dispatch(EventType.OnChatWhisperSelected, self.szCurWhisper)
        end
    end)

    UIHelper.BindUIEvent(self.BtnDelPlayer, EventType.OnClick, function()
        if self.bIsAINpc then
            ChatAINpcMgr.RemoveFromRecentList(self.dwID)
            Event.Dispatch(EventType.OnChatAINpcDeleted, self.dwID)
            return
        end

        ChatData.RemoveWhisper(self.szCurWhisper)
        ChatRecentMgr.RemoveWhisperPlayer(self.szCurWhisper)
        Event.Dispatch(EventType.OnChatWhisperDeleted, self.szCurWhisper)
    end)
end

function UIChatWhisperCell:RegEvent()
    --Event.Reg(self, EventType.OnChatWhisperUnreadAdd, function()
    --    self:UpdateInfo_Redpoint()
    --end)

    --Event.Reg(self, EventType.OnChatWhisperUnreadRemove, function()
    --    self:UpdateInfo_Redpoint()
    --end)

    Event.Reg(self, EventType.OnChatRecentWhisperUnreadRemove, function()
        self:UpdateInfo_Redpoint()
    end)

    Event.Reg(self, EventType.OnChatRecentWhisperUnreadAdd, function()
        self:UpdateInfo_Redpoint()
    end)

    Event.Reg(self, EventType.OnChatAINpcUnReadChange, function()
        self:UpdateInfo_Redpoint()
    end)
end

function UIChatWhisperCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChatWhisperCell:UpdateInfo()
    if self.bIsAINpc then
        self:UpdateInfo_AINpc()
    else
        self:UpdateInfo_Whisper()
    end
end

function UIChatWhisperCell:UpdateInfo_AINpc()
    UIHelper.SetVisible(self.imgRedPoint, false)
    UIHelper.SetVisible(self.imgIDFriend, false)


    local tbInfo = ChatAINpcMgr.GetNpcInfo(self.dwID)
    if not tbInfo then return end

    UIHelper.SetString(self.LabelPlayerName, GBKToUTF8(tbInfo.szName), 4)

    UIHelper.RemoveAllChildren(self.WidgetHead)
    local scriptHead = UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.WidgetHead, tbInfo.dwNpcId)
    Timer.AddFrame(self, 1, function()
        scriptHead:SetHeadWithTex(tbInfo.szSmallAvatarImg)
    end)

    UIHelper.SetNodeSwallowTouches(self.WidgetHead, false, true)

    UIHelper.SetSpriteFrame(self.ImgRecentContacts, "UIAtlas2_Chat_Chat1_Mark5.png", false)

     if self.bSelected then
        UIHelper.SetSelected(self.TogWhisperPlayer, true)
    end

    if self.bSelected then
        UIHelper.SetSelected(self.TogWhisperPlayer, true)
    end
end

function UIChatWhisperCell:UpdateInfo_Whisper()
    local tbData = ChatData.GetWhisperPlayerData(self.szCurWhisper)
    if not tbData then return end

    local nDisplayMode = Storage.Fellowship.NameDisplayMode
    local szName = tbData.szName
    local dwTalkerID = tbData.dwTalkerID
    local dwMiniAvatarID = tbData.dwMiniAvatarID
    local nRoleType = tbData.nRoleType
    local dwForceID = tbData.dwForceID
    local bFriend = FellowshipData.IsFriend(tbData.szGlobalID) or ChatRecentMgr.IsFriendByName(szName)
    if bFriend then
        local tbPlayerInfo = FellowshipData.GetRoleEntryInfo(tbData.szGlobalID)
        if tbPlayerInfo then
            if tbPlayerInfo.szName == "" then
                szName = g_tStrings.MENTOR_DELETE_ROLE
                dwTalkerID = nil
                dwMiniAvatarID = 0
                nRoleType = 0
                dwForceID = 0
            else
                szName = ChatRecentMgr.GetPlayerRemarkNameByGlobalID(UIHelper.GBKToUTF8(tbPlayerInfo.szName), tbData.szGlobalID, nDisplayMode)
                dwMiniAvatarID = tbPlayerInfo.dwMiniAvatarID
                nRoleType = tbPlayerInfo.nRoleType
                dwForceID = tbPlayerInfo.nForceID
            end
        end
    end
    UIHelper.SetVisible(self.imgRedPoint, false)

    UIHelper.SetVisible(self.imgIDFriend, false)

    UIHelper.SetString(self.LabelPlayerName, szName, 4)

    UIHelper.RemoveAllChildren(self.WidgetHead)
    local scriptHead = UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.WidgetHead, tbData.dwTalkerID)

    Timer.AddFrame(self, 1, function()
        scriptHead:SetHeadInfo(dwTalkerID, dwMiniAvatarID, nRoleType, dwForceID or 0)
    end)

    -- TODO 如果tbData只有名字，没有dwTalkerID，dwMiniAvatarID，nRoleType，dwForceID等其他信息，那么就用默认头像

    UIHelper.SetNodeSwallowTouches(self.WidgetHead, false, true)

    if bFriend then
        UIHelper.SetSpriteFrame(self.ImgRecentContacts, "UIAtlas2_Chat_Chat1_Mark3.png", false)
    else
        UIHelper.SetSpriteFrame(self.ImgRecentContacts, "UIAtlas2_Chat_Chat1_Mark2.png", false)
    end

    if self.bSelected then
        UIHelper.SetSelected(self.TogWhisperPlayer, true)
    end

    self:UpdateInfo_Redpoint()
end

function UIChatWhisperCell:UpdateInfo_Redpoint()
    if self.bIsAINpc then
        UIHelper.SetVisible(self.imgRedPoint, ChatAINpcMgr.HasUnRead(self.dwID))
        return
    end
    --UIHelper.SetVisible(self.imgRedPoint, ChatData.HasWhisperUnread(self.szCurWhisper))

    local tbData = ChatData.GetWhisperPlayerData(self.szCurWhisper)
    if not tbData then return end
    local nOffLineMsgCount = ChatRecentMgr.GetOffLineMsgCount(tbData.szGlobalID)
    UIHelper.SetVisible(self.imgRedPoint, ChatRecentMgr.HasWhisperUnread(tbData.szGlobalID) or nOffLineMsgCount > 0)
end


return UIChatWhisperCell