-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPlayerMessageTog
-- Date: 2022-11-22 21:39:01
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPlayerMessageTog = class("UIPlayerMessageTog")

local BUFF_ID_OF_GRADUATION_CD = 15743
local QUEST_ID 	= {13470, 13469}
local TASK_ING = 1
local TASK_FINISH_NOT_HAND_IN = 2
local TASK_FINISH_AND_HAND_IN = 3

function UIPlayerMessageTog:OnEnter(nIndex, tbPlayerCell, WidgetPlayerPop)
    if not tbPlayerCell then
        return
    end

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.WidgetPlayerPop = WidgetPlayerPop
    self:InitPlayerData(tbPlayerCell)

    self.bCancelBreak = false -- 是不是断绝关系状态
    self.tbMenuConfigSet = self:SetupMenuConfigSet()
    self:UpdateInfo()
end

function UIPlayerMessageTog:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIPlayerMessageTog:BindUIEvent()
    -- 选中toggle  (WidgetPlayerMessageTog用)
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnSelectChanged, function (_, bSelected)
        if self.nRelationType == FellowshipData.tbRelationType.nRecent then
            UIHelper.SetVisible(self.tbWidgetRecentContacts[1], true)
            UIHelper.SetVisible(self.tbWidgetRecentContacts[2], true)
            if bSelected then
                local viewScript = UIMgr.OpenSingle(false, VIEW_ID.PanelChatSocial, 1, UI_Chat_Channel.Whisper)
                if viewScript then
                    local bDelete = self.tbRoleEntryInfo.szName == ""
                    local szName = bDelete and UIHelper.GBKToUTF8(self.tbPlayerInfo.szName) or UIHelper.GBKToUTF8(self.tbRoleEntryInfo.szName)
                    local dwTalkerID = self.tbRoleEntryInfo.dwPlayerID
                    local dwForceID = self.tbRoleEntryInfo.nForceID
                    local dwMiniAvatarID = self.tbRoleEntryInfo.dwMiniAvatarID
                    local nRoleType = self.tbRoleEntryInfo.nRoleType
                    local nLevel = self.tbRoleEntryInfo.nLevel
                    local szGlobalID = self.tbPlayerInfo.id
                    local dwCenterID = self.tbRoleEntryInfo.dwCenterID
                    local tbData = {szName = szName, dwTalkerID = dwTalkerID, dwForceID = dwForceID, dwMiniAvatarID = dwMiniAvatarID, nRoleType = nRoleType, nLevel = nLevel, szGlobalID = szGlobalID, dwCenterID = dwCenterID}

                    ChatHelper.WhisperTo(szName, tbData, true)

                end
            end
        else
            if bSelected and self.tbPlayerInfo.id ~= UI_GetClientPlayerGlobalID() then
                Timer.AddFrame(self, 1, function ()
                    UIHelper.RemoveAllChildren(self.WidgetPlayerPop)
                    self:OnClickOther()
                    self:OnClickFriendOrArround()
                    if UIMgr.GetView(VIEW_ID.PanelSystemMenu) then
                        UIMgr.Close(VIEW_ID.PanelSystemMenu)
                    end
                    FellowshipData.nVisiblePlayerPop = 1
                end)
            end
        end
    end)

    UIHelper.BindUIEvent(self.BtnMore, EventType.OnClick, function ()
        UIHelper.RemoveAllChildren(self.WidgetPlayerPop)

        local tbMenuConfig = self:GenerateMenuConfig()

        local tips, script = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPlayerPop, self.BtnMore, self.tbPlayerInfo.id, tbMenuConfig, self.tbRoleEntryInfo)

    end)
end

function UIPlayerMessageTog:RegEvent()
    Event.Reg(self,"FELLOWSHIP_ROLE_ENTRY_UPDATE",function (szGlobalID)
        local szID = self.tbPlayerInfo.id
        if self.nRelationType == FellowshipData.tbRelationType.nAroundPlayer then
            local targetPlayer = GetPlayer(self.tbPlayerInfo.dwID)
            szID = targetPlayer.GetGlobalID()
        end

        if szGlobalID == szID then
            self.tbRoleEntryInfo = FellowshipData.GetRoleEntryInfo(szID) or {}
            self:UpdateInfo()
        end
    end)

    Event.Reg(self,EventType.OnClearSelectedState,function ()
        if UIHelper.GetSelected(self.ToggleSelect) then
            UIHelper.SetSelected(self.ToggleSelect,false)
        end
    end)

    Event.Reg(self,"ON_PLAYER_AFK_STATE_UPDATE",function (szGlobalID)
        if self.tbPlayerInfo and self.tbPlayerInfo.id and self.tbPlayerInfo.id == szGlobalID then
            self.bRecruit = true
        end
    end)

    Event.Reg(self,"UPDATE_FRIEND_INVITE",function (dwRoleID)
        if self.tbPlayerInfo and self.tbPlayerInfo.id and self.tbPlayerInfo.id == dwRoleID then
            self.bRecruit = nil
        end
    end)

    Event.Reg(self, "APPLY_ROLE_ONLINE_FLAG_RESPOND", function ()
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnChatRecentWhisperUnreadAdd, function (szGlobal)
        if self.nRelationType == FellowshipData.tbRelationType.nRecent and szGlobal == self.tbPlayerInfo.id then
            local nNewMsgCount = ChatRecentMgr.GetNewMsgCount(self.tbPlayerInfo.id)
            self.tbPlayerInfo.nNewMsgCount = nNewMsgCount
            self:UpdateRecentInfo()
        end
    end)

    Event.Reg(self, EventType.OnChatRecentWhisperUnreadRemove, function (szGlobal)
        if self.nRelationType == FellowshipData.tbRelationType.nRecent and szGlobal == self.tbPlayerInfo.id then
            local nNewMsgCount = ChatRecentMgr.GetNewMsgCount(self.tbPlayerInfo.id)
            self.tbPlayerInfo.nNewMsgCount = nNewMsgCount
            self:UpdateRecentInfo()
        end
    end)
end

function UIPlayerMessageTog:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPlayerMessageTog:InitPlayerData(tbPlayerCell)
    local dwID = g_pClientPlayer.dwID or 0

    self.nRelationType = tbPlayerCell.nRelationType
    self.nDisplayMode = tbPlayerCell.nDisplayMode or Storage.Fellowship.NameDisplayMode
    self.tbPlayerInfo = tbPlayerCell.tbPlayerInfo
    self.tbRoleEntryInfo = self:UpdateMentorRoleEntryInfo(tbPlayerCell) or {}

    if self.tbPlayerInfo and self.tbPlayerInfo.id and self.nRelationType ~= FellowshipData.tbRelationType.nRecent then
        self.bRemoteFriend = FellowshipData.IsRemoteFriend(self.tbPlayerInfo.id)
        self.bInRemoteState = IsRemotePlayer(dwID)
        self.bOnLine, self.bAppOnline = FellowshipData.IsOnline(self.tbPlayerInfo.id)
    end

    if self.tbPlayerInfo and self.tbPlayerInfo.id then
        GetRoleAFKState(self.tbPlayerInfo.id)
    end

    self.tMyMemberInfo = (dwID > 0) and GetTongClient().GetMemberInfo(dwID) or {}
end

function UIPlayerMessageTog:UpdateInfo()
    if not self.tbPlayerInfo then
        UIHelper.SetVisible(self._rootNode, false)
        return
    else
        UIHelper.SetVisible(self._rootNode, true)
    end

    self:UpdateHead()
    self:UpdateName()
    self:UpdateMood()
    self:UpdateMentorInfo()
    self:UpdateRecentInfo()

    local tLine = UINameCardTab[self.tbRoleEntryInfo.nSkinID]
    if tLine then
        UIHelper.SetTexture(self.ImgBgNameCard, tLine.szVisitCardPath, false)
        UIHelper.UpdateMask(self.MaskImgNameCard)
    end

    UIHelper.SetNodeSwallowTouches(self.ToggleSelect, false, true)
end

function UIPlayerMessageTog:UpdateHead()
    local bShowOnline = self.bOnLine
    local bShowCardDecoration = false

    local bIsFriend = self.nRelationType == FellowshipData.tbRelationType.nFriend
    local bIsNpc = self.nRelationType == FellowshipData.tbRelationType.nNpc

    if bIsFriend then
        bShowOnline = bShowOnline or self.bAppOnline
        bShowCardDecoration = true
    end

    if self.tbPlayerInfo then
        self.headScript = self.headScript or UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.WidgetHead)
        UIHelper.SetTouchEnabled(self.headScript.BtnHead, false)
        self.headScript2 = self.headScript2 or  UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.WidgetHead2)
        UIHelper.SetTouchEnabled(self.headScript2.BtnHead, false)
        if self.headScript and self.headScript2 then
            if self.tbRoleEntryInfo then
                if bIsNpc then
                    self.headScript:SetHeadWithTex(self.tbPlayerInfo.szSmallAvatarImg)
                    self.headScript2:SetHeadWithTex(self.tbPlayerInfo.szSmallAvatarImg)
                else
                    self.headScript:SetHeadInfo(self.tbRoleEntryInfo.dwPlayerID, self.tbRoleEntryInfo.dwMiniAvatarID or 0, self.tbRoleEntryInfo.nRoleType or nil, self.tbRoleEntryInfo.nForceID)
                    self.headScript2:SetHeadInfo(self.tbRoleEntryInfo.dwPlayerID, self.tbRoleEntryInfo.dwMiniAvatarID or 0, self.tbRoleEntryInfo.nRoleType or nil, self.tbRoleEntryInfo.nForceID)
                    if bShowCardDecoration then
                        local tData = Table_GetPersonalCardInfo(2, self.tbRoleEntryInfo.ShowCardDecorationFrameID)
                        local szFrame = tData and tData.dwDecorationID ~= 0 and tData.szVKSmallPath or ""
                        self.headScript:SetPersonalFrame(szFrame)
                        self.headScript2:SetPersonalFrame(szFrame)
                    end
                end
            end

            self.headScript:SetOfflineState(bShowOnline == false)
            self.headScript2:SetOfflineState(bShowOnline == false)
        end
    end

    if bIsNpc then
        UIHelper.SetTabVisible(self.tbImgOnline, false)
        UIHelper.SetTabVisible(self.tbImgTuiLanOnline, false)
    else
        for i = 1, 2, 1 do
            UIHelper.SetVisible(self.tbImgOnline[i], self.nRelationType ~= FellowshipData.tbRelationType.nRecent)
            if bShowOnline then
                UIHelper.SetSpriteFrame(self.tbImgOnline[i], FRIEND_ONLINE_STATE[1])
            else
                UIHelper.SetSpriteFrame(self.tbImgOnline[i], FRIEND_ONLINE_STATE[0])
            end
        end

        for i = 1, 2, 1 do
            local bShowTuilan = self.nRelationType == FellowshipData.tbRelationType.nFriend and not self.bOnLine and self.bAppOnline
            UIHelper.SetVisible(self.tbImgTuiLanOnline[i], bShowTuilan)
        end
    end
end

function UIPlayerMessageTog:UpdateName()
    local szUtf8Name = self.tbRoleEntryInfo.szName
    if self.tbPlayerInfo and self.tbPlayerInfo.bDelete then
        szUtf8Name = self.tbRoleEntryInfo.szName
    else
        szUtf8Name = UIHelper.GBKToUTF8(self.tbRoleEntryInfo.szName)
    end
    szUtf8Name = szUtf8Name == "" and g_tStrings.MENTOR_DELETE_ROLE or szUtf8Name

    local szUtf8Remark = self.tbPlayerInfo.remark and UIHelper.GBKToUTF8(self.tbPlayerInfo.remark) or ""
    local szDisplayName = szUtf8Name

    if self.nRelationType == FellowshipData.tbRelationType.nFriend or
    self.nRelationType == FellowshipData.tbRelationType.nFoe or
    self.nRelationType == FellowshipData.tbRelationType.nBlack then
        if self.nDisplayMode == SOCIALPANEL_NAME_DISPLAY.NICKNAME then
            szDisplayName = szUtf8Name
        elseif self.nDisplayMode == SOCIALPANEL_NAME_DISPLAY.REMARK then
            szDisplayName = szUtf8Remark == "" and szUtf8Name or szUtf8Remark
        elseif self.nDisplayMode == SOCIALPANEL_NAME_DISPLAY.NICKNAME_AND_REMARK then
            szDisplayName = szUtf8Remark == "" and szUtf8Name or string.format("%s(%s)", szUtf8Name, szUtf8Remark)
        elseif self.nDisplayMode == SOCIALPANEL_NAME_DISPLAY.REMARK_AND_NICKNAME then
            szDisplayName = szUtf8Remark == "" and szUtf8Name or string.format("%s(%s)", szUtf8Remark, szUtf8Name)
        else
            szDisplayName = szUtf8Name
        end
    end


    local bShowOnline = self.bOnLine
    if self.nRelationType == FellowshipData.tbRelationType.nFriend then
        bShowOnline = bShowOnline or self.bAppOnline
    end
    for i = 1,2 do
        UIHelper.SetString(self.tbLabelName[i], szDisplayName, 8)
        UIHelper.SetColor(self.tbLabelName[i], bShowOnline == false and cc.c3b(134, 174, 180) or cc.c3b(255, 255, 255))

        if self.nRelationType ~= FellowshipData.tbRelationType.nRecent and FellowshipData.IsRemoteFriend(self.tbPlayerInfo.id) then
            local szCenterName = GetCenterNameByCenterID(self.tbRoleEntryInfo.dwCenterID)
            UIHelper.SetString(self.tbLabelSignature[i], UIHelper.GBKToUTF8(szCenterName))
        else
            if self.tbRoleEntryInfo.szSignature and self.tbRoleEntryInfo.szSignature ~= "" then
                local nCount, str = UIHelper.TruncateString(UIHelper.GBKToUTF8(self.tbRoleEntryInfo.szSignature), 14, "...")
                UIHelper.SetString(self.tbLabelSignature[i], str)
            else
                UIHelper.SetString(self.tbLabelSignature[i], self.tbRoleEntryInfo.szSignature)
            end
        end

        if self.nRelationType == FellowshipData.tbRelationType.nTong then
            local szMapName = UIHelper.GBKToUTF8(Table_GetMapName(self.tbRoleEntryInfo.dwMapID))
            UIHelper.SetString(self.tbLabelSignature[i], szMapName ~= "" and szMapName or "离线")
        elseif self.nRelationType == FellowshipData.tbRelationType.nAroundPlayer then
            CampData.SetUICampImg(self.tbImgCamp[i], self.tbRoleEntryInfo.nCamp, nil, true)
        end

        UIHelper.SetString(self.tbLabelLevel[i], self.tbRoleEntryInfo.nLevel)
        UIHelper.SetNodeGray(self.tbLabelLevel[i], bShowOnline == false)
        UIHelper.SetSpriteFrame(self.tbImgForceID[i], PlayerForceID2SchoolImg2[self.tbRoleEntryInfo.nForceID])
        UIHelper.SetVisible(self.tbImgForceID[i], self.tbRoleEntryInfo.nForceID ~= 0)
        UIHelper.SetNodeGray(self.tbImgForceID[i], bShowOnline == false)
        UIHelper.SetVisible(self.tbImgForceID[i], self.nRelationType ~= FellowshipData.tbRelationType.nTong)
        UIHelper.SetVisible(self.tbImgCamp[i], self.nRelationType == FellowshipData.tbRelationType.nAroundPlayer)
    end
end

function UIPlayerMessageTog:UpdateMood()
    if self.nRelationType ~= FellowshipData.tbRelationType.nNpc then
        UIHelper.SetTabVisible(self.tbImgMood, false)
        return
    end

    UIHelper.SetTabVisible(self.tbImgMood, ChatAINpcMgr.IsShowMood())

    UIHelper.SetString(self.tbLabelMood[1], string.format(g_tStrings.STR_NPC_MOOD, self.tbPlayerInfo.nMood or 0))
    UIHelper.SetString(self.tbLabelMood[2], string.format(g_tStrings.STR_NPC_MOOD, self.tbPlayerInfo.nMood or 0))
end

function UIPlayerMessageTog:UpdateMentorInfo()
    if self.nRelationType == FellowshipData.tbRelationType.nMaster or
    self.nRelationType == FellowshipData.tbRelationType.nApprentice or
    self.nRelationType == FellowshipData.tbRelationType.nSameApp then
        for i = 1,2 do
            UIHelper.SetString(self.tbLabelSignature[i], self.tbPlayerInfo.szRelation)
            UIHelper.SetVisible(self.tbImgStudentTip[i],self.tbPlayerInfo.bDirectA)
            self:UpdateRecordState()
        end
    elseif self.nRelationType == FellowshipData.tbRelationType.nFriend then
        for i = 1,2 do
            UIHelper.SetVisible(self.tbImgServerTip[i],self.bRemoteFriend)
        end
    elseif self.nRelationType == FellowshipData.tbRelationType.nTong then
        local tong  = GetTongClient()
        for i = 1,2 do
            UIHelper.SetVisible(self.tbImgTongTip[i], self.tbRoleEntryInfo.dwPlayerID == tong.dwMaster)
            -- UIHelper.SetString(self.tbLabelSignature[i], self.bOnLine and UIHelper.GBKToUTF8(Table_GetMapName(self.tbRoleEntryInfo.dwMapID)) or g_tStrings.STR_GUILD_OFFLINE)
        end
    end
end

function UIPlayerMessageTog:UpdateRecordState()
    local szTip = ""
    local nEndTime = self.tbPlayerInfo.nEndTime - GetCurrentTime() - 120
    if nEndTime < 0 then
        nEndTime = 0
    end
    if self.tbPlayerInfo.bDirectA ~= nil then
        if self.tbPlayerInfo.bDirectA then
			if self.tbPlayerInfo.nState == DIRECT_MENTOR_RECORD_STATE.GRADUATE_BY_MENTOR then
				self.bCancelBreak = true
				szTip = FormatString(g_tStrings.MENTOR_BREAK_0, UIHelper.GetHeightestCeilTimeText(nEndTime))
			elseif self.tbPlayerInfo.nState == DIRECT_MENTOR_RECORD_STATE.GRADUATE_BY_APPRENTICE then
				szTip = FormatString(g_tStrings.MENTOR_BREAK_1, UIHelper.GetHeightestCeilTimeText(nEndTime))
			elseif self.tbPlayerInfo.nState == DIRECT_MENTOR_RECORD_STATE.GRADUATE_SUCCEED then
				szTip = g_tStrings.MENTOR_BREAK_3
			end
        else
			if self.tbPlayerInfo.nState == MENTOR_RECORD_STATE.MENTOR_BREAK then
				self.bCancelBreak = true
				szTip = FormatString(g_tStrings.MENTOR_BREAK_0, UIHelper.GetHeightestCeilTimeText(nEndTime))
			elseif self.tbPlayerInfo.nState == MENTOR_RECORD_STATE.APPRENTICE_BREAK then
				szTip = FormatString(g_tStrings.MENTOR_BREAK_1, UIHelper.GetHeightestCeilTimeText(nEndTime))
			elseif self.tbPlayerInfo.nState == MENTOR_RECORD_STATE.BROKEN then
				szTip = FormatString(g_tStrings.MENTOR_BREAK_2, UIHelper.GetHeightestCeilTimeText(nEndTime))
			elseif self.tbPlayerInfo.nState == MENTOR_RECORD_STATE.GRADUATED then
				szTip = FormatString(g_tStrings.MENTOR_BREAK_3, UIHelper.GetHeightestCeilTimeText(nEndTime))
                szTip = g_tStrings.MENTOR_BREAK_3
			else
				szTip = ""
			end
        end
    else
        if self.tbPlayerInfo.bDirectM then
            if self.tbPlayerInfo.nState == DIRECT_MENTOR_RECORD_STATE.GRADUATE_BY_MENTOR then
                szTip = FormatString(g_tStrings.MENTOR_BREAK_1, UIHelper.GetHeightestCeilTimeText(nEndTime))
            elseif self.tbPlayerInfo.nState == DIRECT_MENTOR_RECORD_STATE.GRADUATE_BY_APPRENTICE then
                self.bCancelBreak = true
                szTip = FormatString(g_tStrings.MENTOR_BREAK_0, UIHelper.GetHeightestCeilTimeText(nEndTime))
            elseif self.tbPlayerInfo.nState == DIRECT_MENTOR_RECORD_STATE.GRADUATE_SUCCEED then
                szTip = g_tStrings.MENTOR_BREAK_3
            else
                szTip = ""
            end
        else
			if self.tbPlayerInfo.nState == MENTOR_RECORD_STATE.MENTOR_BREAK then
                szTip = FormatString(g_tStrings.MENTOR_BREAK_1, UIHelper.GetHeightestCeilTimeText(nEndTime))
			elseif self.tbPlayerInfo.nState == MENTOR_RECORD_STATE.APPRENTICE_BREAK then
				self.bCancelBreak = true
                szTip = FormatString(g_tStrings.MENTOR_BREAK_0, UIHelper.GetHeightestCeilTimeText(nEndTime))
            elseif self.tbPlayerInfo.nState == MENTOR_RECORD_STATE.BROKEN then
                szTip = g_tStrings.MENTOR_BREAK_2
			elseif self.tbPlayerInfo.nState == MENTOR_RECORD_STATE.GRADUATED then
                szTip = g_tStrings.MENTOR_BREAK_3
			else
				szTip = ""
			end
        end
    end

    for i = 1, 2 do
        UIHelper.SetString(self.tbLabelAdd[i], szTip)
    end
end

function UIPlayerMessageTog:UpdateMentorRoleEntryInfo(tbPlayerCell)
    if self.nRelationType == FellowshipData.tbRelationType.nFriend or
    self.nRelationType == FellowshipData.tbRelationType.nFoe or
    self.nRelationType == FellowshipData.tbRelationType.nFeud or
    self.nRelationType == FellowshipData.tbRelationType.nBlack
    then
        local tbRoleEntryInfo = tbPlayerCell.tbRoleEntryInfo or FellowshipData.GetRoleEntryInfo(self.tbPlayerInfo.id)
        if not tbRoleEntryInfo or table_is_empty(tbRoleEntryInfo) then
            FellowshipData.ApplyRoleEntryInfo({self.tbPlayerInfo.id})
        end
        return tbRoleEntryInfo
    elseif self.nRelationType == FellowshipData.tbRelationType.nMaster or
    self.nRelationType == FellowshipData.tbRelationType.nApprentice or
    self.nRelationType == FellowshipData.tbRelationType.nSameApp then
        local tSocialInfo = FellowshipData.tApplySocialList[self.tbPlayerInfo.dwID] or FellowshipData.GetSocialInfo(self.tbPlayerInfo.dwID) or {}
        local tRoleEntryInfo = {}
        self.bOnLine = self.tbPlayerInfo.bOnLine
        tRoleEntryInfo.dwMiniAvatarID = tSocialInfo.MiniAvatarID
        tRoleEntryInfo.nForceID = self.tbPlayerInfo.dwForceID
        tRoleEntryInfo.dwPlayerID = self.tbPlayerInfo.dwID
        tRoleEntryInfo.Praiseinfo = tSocialInfo.Praiseinfo
        tRoleEntryInfo.szName = self.tbPlayerInfo.szName
        tRoleEntryInfo.nLevel = self.tbPlayerInfo.nLevel
        tRoleEntryInfo.nRoleType = self.tbPlayerInfo.nRoleType
        tRoleEntryInfo.szTongName = self.tbPlayerInfo.szTongName
        return tRoleEntryInfo
    elseif self.nRelationType == FellowshipData.tbRelationType.nAroundPlayer then
        local targetPlayer = GetPlayer(tbPlayerCell.tbPlayerInfo.dwID)
        local tRoleEntryInfo = {}

        self.bOnLine = true
        tRoleEntryInfo.dwMiniAvatarID = targetPlayer.dwMiniAvatarID
        tRoleEntryInfo.nForceID = targetPlayer.dwForceID
        tRoleEntryInfo.dwPlayerID = tbPlayerCell.tbPlayerInfo.dwID
        tRoleEntryInfo.szName = targetPlayer.szName
        tRoleEntryInfo.nLevel = targetPlayer.nLevel
        tRoleEntryInfo.nRoleType = targetPlayer.nRoleType
        tRoleEntryInfo.nCamp = targetPlayer.nCamp

        return tRoleEntryInfo
    elseif self.nRelationType == FellowshipData.tbRelationType.nTong then
        local tRoleEntryInfo = {}
        local tbPlayerInfo = tbPlayerCell.tbPlayerInfo

        self.bOnLine = tbPlayerInfo.bIsOnline
        tRoleEntryInfo.dwMiniAvatarID = 0
        tRoleEntryInfo.nForceID = tbPlayerInfo.nForceID
        tRoleEntryInfo.dwPlayerID = tbPlayerInfo.dwID
        tRoleEntryInfo.szName = tbPlayerInfo.szName
        tRoleEntryInfo.nLevel = tbPlayerInfo.nLevel
        tRoleEntryInfo.dwMapID = tbPlayerInfo.dwMapID
        tRoleEntryInfo.nEquipScore = tbPlayerInfo.nEquipScore

        return tRoleEntryInfo
    elseif self.nRelationType == FellowshipData.tbRelationType.nRecent then
        local tbPlayerInfo = tbPlayerCell.tbPlayerInfo
        local tRoleEntryInfo = FellowshipData.GetRoleEntryInfo(tbPlayerInfo.id) or {}
        self.bOnLine = true

        if (not tRoleEntryInfo) or table.is_empty(tRoleEntryInfo) or (not FellowshipData.IsFriend(tbPlayerInfo.id)) then
            tRoleEntryInfo.nRoleType = tbPlayerInfo.byRoleType
            tRoleEntryInfo.nLevel = tbPlayerInfo.byLevel
            tRoleEntryInfo.nForceID = tbPlayerInfo.byForceID
            tRoleEntryInfo.nCamp = tbPlayerInfo.byCamp
            tRoleEntryInfo.dwMiniAvatarID = tbPlayerInfo.dwMiniAvatarID
            tRoleEntryInfo.szName = tbPlayerInfo.szName
            tRoleEntryInfo.dwCenterID = tbPlayerInfo.dwCenterID
        end

        return tRoleEntryInfo
    elseif self.nRelationType == FellowshipData.tbRelationType.nNpc then
        local tRoleEntryInfo = {}

        self.bOnLine = true
        tRoleEntryInfo.dwMiniAvatarID = self.tbPlayerInfo.dwMiniAvatarID
        tRoleEntryInfo.nForceID = self.tbPlayerInfo.dwForceID
        tRoleEntryInfo.dwPlayerID = self.tbPlayerInfo.dwID
        tRoleEntryInfo.szName = self.tbPlayerInfo.szName
        tRoleEntryInfo.nLevel = self.tbPlayerInfo.nLevel
        tRoleEntryInfo.nCamp = self.tbPlayerInfo.nCamp
        tRoleEntryInfo.bIsAINpc = true
        tRoleEntryInfo.szSmallAvatarImg = self.tbPlayerInfo.szSmallAvatarImg

        return tRoleEntryInfo
    end
end

function UIPlayerMessageTog:SetupMenuConfigSet()
    return {
        Chat = {{ szName = "密聊", bCloseOnClick = true, callback = function()
            local bDelete = self.tbRoleEntryInfo.szName == ""
            local szName = bDelete and UIHelper.GBKToUTF8(self.tbPlayerInfo.szName) or UIHelper.GBKToUTF8(self.tbRoleEntryInfo.szName)
            local dwTalkerID = self.tbRoleEntryInfo.dwPlayerID
            local bIsFriend = self.nRelationType == FellowshipData.tbRelationType.nFriend
            local dwForceID = self.tbRoleEntryInfo.nForceID
            local dwMiniAvatarID = self.tbRoleEntryInfo.dwMiniAvatarID
            local nRoleType = self.tbRoleEntryInfo.nRoleType
            local nLevel = self.tbRoleEntryInfo.nLevel
            local szGlobalID = self.tbPlayerInfo.id
            local dwCenterID = self.tbRoleEntryInfo.dwCenterID
            local tbData = {szName = szName, dwTalkerID = dwTalkerID, dwForceID = dwForceID, dwMiniAvatarID = dwMiniAvatarID, nRoleType = nRoleType, nLevel = nLevel, szGlobalID = szGlobalID, dwCenterID = dwCenterID}

            ChatHelper.WhisperTo(szName, tbData)
            UIHelper.SetSelected(self.ToggleSelect, false)
        end , fnDisable = function()
            return false--not bOnLine
        end}},
        Call = {{szName = "召请", bCloseOnClick = true, fnDisable = function ()
            return not self.bOnLine
        end, callback = function ()
            if self.tbRoleEntryInfo.nLevel < 110 then
                TipsHelper.ShowNormalTip("对方等级低于110级，不能召请")
                return
            end
            local szName = UIHelper.GBKToUTF8(self.tbRoleEntryInfo.szName)
            if self.bOnLine == false then
                TipsHelper.ShowNormalTip(g_tStrings.tTalkError[PLAYER_TALK_ERROR.PLAYER_OFFLINE])
                return
            end
            local dwTalkerID = self.tbPlayerInfo.id or self.tbPlayerInfo.dwID
            local nCount = 3 - g_pClientPlayer.nEvokeMentorCount

            local szText = ""
            if nCount > 0 then
                if self.nRelationType == FellowshipData.tbRelationType.nMaster then
                    szText = FormatString(g_tStrings.MENTOR_CALL_SURE, szName, 3, nCount)
                elseif self.nRelationType == FellowshipData.tbRelationType.nApprentice then
                    szText = FormatString(g_tStrings.MENTOR_CALL_APPRENTICE_SURE, szName, 3, nCount)
                end
                UIHelper.ShowConfirm(szText,function ()
                    RemoteCallToServer("OnApplyEvoke", dwTalkerID)
                end)
            else
                if self.nRelationType == FellowshipData.tbRelationType.nMaster then
                    szText = g_tStrings.MENTOR_CALL_MASTER_PAY
                elseif self.nRelationType == FellowshipData.tbRelationType.nApprentice then
                    szText = g_tStrings.MENTOR_CALL_APPRENTICE_PAY
                end
                local szScript = UIHelper.ShowSwitchMapConfirm(szText, function ()
                    RemoteCallToServer("OnApplyEvoke", dwTalkerID)
                end)
                if szScript then
                    szScript:UpdateMentor()
                end
            end

            UIHelper.SetSelected(self.ToggleSelect, false)
        end
        }},
        Group = {{ szName = "组队", callback = function()
            TeamData.InviteJoinTeam(self.tbRoleEntryInfo.szName)
        end,fnDisable = function()
            local bOnLine = self.bOnLine
            return not bOnLine or not TeamData.CanMakeParty()
        end }},
        Friend = {
            {
                szName = "删除好友", bCloseOnClick = true,
                fnCheckShow = function () return FellowshipData.IsFriend(self.tbPlayerInfo.id) end,
                callback = function()
                    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.FELLOWSHIP, "del friend") then
                        return
                    end

                    UIHelper.ShowConfirm(g_tStrings.STR_CONFIRM_DEL_FRIEND, function ()
                        FellowshipData.DelFellowship(self.tbPlayerInfo.id)

                        Event.Dispatch(EventType.OnUpdateFellowShip)
                    end)
                    UIHelper.SetSelected(self.ToggleSelect, false)
                end
            },
            {
                szName = "添加好友", bCloseOnClick = true,
                fnCheckShow = function () return self.tbRoleEntryInfo.dwPlayerID ~= PlayerData.GetPlayerID() and not FellowshipData.IsFriend(self.tbPlayerInfo.id) end,
                callback = function()
                    FellowshipData.AddFellowship(self.tbRoleEntryInfo.szName)
                    UIHelper.SetSelected(self.ToggleSelect, false)
                end
            }},
        Remark = {{ szName = "修改备注", bCloseOnClick = true, callback = function()
            local editBox = UIMgr.Open(VIEW_ID.PanelPromptPop, UIHelper.GBKToUTF8(self.tbPlayerInfo.remark), g_tStrings.STR_SET_REMARK_TIP_CONTENT, function (szText)
                FellowshipData.SetFellowshipRemark(self.tbPlayerInfo.id, UIHelper.UTF8ToGBK(szText))
            end)
            editBox:SetTitle(g_tStrings.STR_FRIEND_REMARK)

            UIHelper.SetSelected(self.ToggleSelect, false)
        end }},
        FriendBack = {{ szName = "召回好友", bCloseOnClick = true, callback = function()
            RemoteCallToServer("On_Recharge_GetFriendInfo", self.tbPlayerInfo.id)
            UIHelper.SetSelected(self.ToggleSelect, false)
        end }},
        Tong = {{ szName = "邀请入帮", callback = function()
            if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TONG_OPERATE, "Tong") then
                return
            end

            TongData.InvitePlayerJoinTong(self.tbRoleEntryInfo.szName)
        end,fnDisable = function()
            local bGuildDisable = ((IsNumber(self.tbRoleEntryInfo.nLevel) and self.tbRoleEntryInfo.nLevel < 20) or g_pClientPlayer.dwTongID == 0)
            if g_pClientPlayer.IsPlayerInMyParty(self.tbRoleEntryInfo.dwPlayerID) then
                local hTeam = GetClientTeam()
                local tMemberInfo = hTeam.GetMemberInfo(self.tbRoleEntryInfo.dwPlayerID)
                if not tMemberInfo.bIsOnLine then
                    bGuildDisable = true
                end
            end
            bGuildDisable = bGuildDisable and g_pClientPlayer.nLevel > 1
            return bGuildDisable
        end}},
        PeekEquip = {{ szName = "查看装备", bCloseOnClick = true, callback = function()
            UIMgr.Open(VIEW_ID.PanelOtherPlayer, self.tbRoleEntryInfo.dwPlayerID, self.tbRoleEntryInfo.dwCenterID, self.tbPlayerInfo.id)
            TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetPlayerPop)
            UIHelper.SetSelected(self.ToggleSelect, false)
        end,fnDisable = function()
            return not self.bOnLine
        end }},
        MoreInfo = {{szName = "师徒互动", bCloseOnClick = true, callback = function()
            if self.bOnLine == false then
                TipsHelper.ShowNormalTip(g_tStrings.tTalkError[PLAYER_TALK_ERROR.PLAYER_OFFLINE])
                return
            end
            UIMgr.Open(VIEW_ID.PanelInteractActivityPop,UIHelper.GBKToUTF8(self.tbPlayerInfo.szName),self.nRelationType,self.tbPlayerInfo.dwID)
            UIHelper.SetSelected(self.ToggleSelect, false)
        end}},
        StopRelation = {{
            szName = "断绝关系", bCloseOnClick = true, callback = function()
                local szText
                local funcConfirm
                if self.tbPlayerInfo.bDirectM == true then
                    szText = g_tStrings.MENTOR_BREAK_SURE_4
                    funcConfirm = function ()
                        if g_pClientPlayer.nLevel >= g_pClientPlayer.nMaxLevel then
                            RemoteCallToServer("OnGraduateByDirectApprentice", self.tbPlayerInfo.dwID)
                        else
                            RemoteCallToServer("OnBreakDirectMentor", self.tbPlayerInfo.dwID)
                        end
                    end
                elseif self.tbPlayerInfo.bDirectM == false then
                    szText = g_tStrings.MENTOR_BREAK_SURE_2
                    funcConfirm = function ()
                        RemoteCallToServer("OnBreakMentor", self.tbPlayerInfo.dwID)
                    end
                elseif self.tbPlayerInfo.bDirectA == true then
                    szText = g_tStrings.MENTOR_BREAK_SURE_3
                    funcConfirm = function ()
                        if g_pClientPlayer.nLevel >= g_pClientPlayer.nMaxLevel then
                            RemoteCallToServer("OnGraduateByDirectMentor", self.tbPlayerInfo.dwID)
                        else
                            RemoteCallToServer("OnBreakDirectApprentice", self.tbPlayerInfo.dwID)
                        end
                    end
                elseif self.tbPlayerInfo.bDirectA == false then
                    szText = g_tStrings.MENTOR_BREAK_SURE_1
                    funcConfirm = function ()
                        RemoteCallToServer("OnBreakApprentice", self.tbPlayerInfo.dwID)
                    end
                end
                UIHelper.ShowConfirm(FormatString(szText, UIHelper.GBKToUTF8(self.tbRoleEntryInfo.szName)),funcConfirm)
                UIHelper.SetSelected(self.ToggleSelect, false)
            end
        }},
        CancleStopRelation = {
            {szName = "取消断绝", bCloseOnClick = true, callback = function()
                if self.tbPlayerInfo.bDirectM == true then
                    RemoteCallToServer("OnCancelGraduateByApprentice", self.tbPlayerInfo.dwID) -- 跟亲传师父取消断绝
                elseif self.tbPlayerInfo.bDirectM == false then
                    RemoteCallToServer("OnCancelBreakMentor", self.tbPlayerInfo.dwID) -- 跟普通师父取消断绝
                elseif self.tbPlayerInfo.bDirectA == true then
                    RemoteCallToServer("OnCancelGraduateByMentor", self.tbPlayerInfo.dwID)
                elseif self.tbPlayerInfo.bDirectA == false then
                    RemoteCallToServer("OnCancelBreakApprentice", self.tbPlayerInfo.dwID)
                end
                UIHelper.SetSelected(self.ToggleSelect, false)
            end},
        },
        Graduation = {{szName = "出师", bCloseOnClick = true, callback = function()
            local buffIsInGraduationCD = Player_GetBuff(BUFF_ID_OF_GRADUATION_CD)
            if buffIsInGraduationCD then
                TipsHelper.ShowNormalTip(g_tStrings.MENTOR_MSG.ON_GRADUATED_CDLIMIT)
            end
            if g_pClientPlayer.nLevel >= g_pClientPlayer.nMaxLevel then --出师活动
                UIHelper.ShowConfirm(g_tStrings.STR_NORNAL_MENTOR_BREAK_FULL_LEVEL,function ()
                    g_pClientPlayer.AcceptQuest(TARGET.NO_TARGET, 0, QUEST_ID[1])
                end)
            else
                TipsHelper.ShowNormalTip("侠士尚未满级，不可出师")
            end
            UIHelper.SetSelected(self.ToggleSelect, false)
        end}},
        GraduationState = {{szName = "出师中", callback = function()
            TipsHelper.ShowNormalTip(g_tStrings.STR_QUESTING_TIP)
            UIHelper.SetSelected(self.ToggleSelect, false)
        end}},
        Black = {
            {
                szName = "屏蔽发言", bCloseOnClick = true,
                fnCheckShow = function () return not FellowshipData.IsInBlackList(self.tbPlayerInfo.id) end,
                callback = function()
                    FellowshipData.AddRemoteBlack(self.tbPlayerInfo.id, self.tbRoleEntryInfo.szName)
                end
            },
            {
                szName = "取消禁言", bCloseOnClick = true,
                fnCheckShow = function () return FellowshipData.IsInBlackList(self.tbPlayerInfo.id) end,
                callback = function()
                    local nResultCode = FellowshipData.DelBlackList(self.tbPlayerInfo.id)
                    if nResultCode ~= PLAYER_FELLOWSHIP_RESPOND.SUCCESS then
                        Global.OnFellowshipMessage(nResultCode)
                    end
                end
            }},

        Foe = {{ szName = "加为劲敌", bNesting = true, tbSubMenus = { {
                szName = "加为敌对", bCloseOnClick = true,fnDisable = function ()
                    return not FellowshipData.CanAddFoe()
                end,
                callback = function()
                    local szFormat = FellowshipData.IsFriend(self.tbPlayerInfo.id) and g_tStrings.STR_ADD_FRIEND_TO_ENEMY_SURE or g_tStrings.STR_ADD_TO_ENEMY_SURE
                    local szContent = string.format(szFormat, UIHelper.GBKToUTF8(self.tbRoleEntryInfo.szName))
                    UIHelper.ShowConfirm(szContent, function ()
                        FellowshipData.PrepareAddFoe(self.tbRoleEntryInfo.szName)
                    end, nil, false)
                    UIHelper.SetSelected(self.ToggleSelect, false)
                end
            }, { szName = "加为宿敌", bCloseOnClick = true,
            callback = function()
                local szFormat = FellowshipData.IsFriend(self.tbPlayerInfo.id) and g_tStrings.STR_ADD_FRIEND_TO_FEUD_SURE or g_tStrings.STR_ADD_TO_FEUD_SURE
                local szContent = string.format(szFormat, UIHelper.GBKToUTF8(self.tbRoleEntryInfo.szName))

                UIHelper.ShowConfirm(szContent, function ()
                    FellowshipData.AddFeudComfirm(FellowshipData.PrepareAddFeud, self.tbPlayerInfo.id)
                end, nil, false)
                UIHelper.SetSelected(self.ToggleSelect, false)
            end }
        }
            }},
        DelFoe = {{ szName = "删除敌对", bCloseOnClick = true, callback = function()
                local bResult = FellowshipData.DelFoe(self.tbPlayerInfo.id)
                if bResult then
                    Event.Dispatch("PLAYER_DEL_BEGIN", 5)
                end
                UIHelper.SetSelected(self.ToggleSelect, false)
                UIHelper.RemoveAllChildren(self.WidgetPlayerPop)
            end }},
        DelFeud = {{ szName = "删除宿敌", bCloseOnClick = true, callback = function()
            FellowshipData.DelFeud(self.tbPlayerInfo.id, self.tbRoleEntryInfo.szName)
            UIHelper.SetSelected(self.ToggleSelect, false)
            UIHelper.RemoveAllChildren(self.WidgetPlayerPop)
        end }},
        SetFellowshipGroup = {{ szName = "移动分组", bCloseOnClick = true, fnDisable = function()
            local tbPlayerGroupList = FellowshipData.GetFellowshipGroupInfo() or {}
            return #tbPlayerGroupList == 1
        end, callback = function()
            local szTipContent = string.format(g_tStrings.STR_SET_FRIEND_GROUP_TIP_CONTENT, UIHelper.GBKToUTF8(self.tbRoleEntryInfo.szName))
            local tbItems = {}
            local tbPlayerGroupList = FellowshipData.GetFellowshipGroupInfo() or {}
            for _, tbPlayerGroup in ipairs(tbPlayerGroupList) do
                if self.bRemoteFriend and tbPlayerGroup.id == 0 then
                    table.insert(tbItems, { nKey = tbPlayerGroup.id, szText = "跨服好友" })
                else
                    table.insert(tbItems, { nKey = tbPlayerGroup.id, szText = UIHelper.GBKToUTF8(tbPlayerGroup.name) })
                end
            end

            UIMgr.Open(VIEW_ID.PanelFriendChangeListPop, g_tStrings.STR_SET_FRIEND_GROUP_TITLE, szTipContent, tbItems, self.tbPlayerInfo.groupid, function (nKey)
                if self.tbPlayerInfo.groupid ~= nKey then
                    local nResultCode = FellowshipData.SetFellowshipGroup(self.tbPlayerInfo.id, self.tbPlayerInfo.groupid, nKey)
                    if nResultCode ~= PLAYER_FELLOWSHIP_RESPOND.SUCCESS then
                        Global.OnFellowshipMessage(nResultCode)
                    end
                end

                Event.Dispatch(EventType.OnUpdateFellowShip)
            end)

            UIHelper.SetSelected(self.ToggleSelect, false)
        end }},
        SetDisplayMode = {{ szName = "名称显示", bCloseOnClick = true, callback = function()
            local nDefaultDisplayMode = Storage.Fellowship.NameDisplayMode
            local tbItems = {
                { nKey = SOCIALPANEL_NAME_DISPLAY.NICKNAME, szText = g_tStrings.STR_FRIEND_LIST_DISPLAY_MODE_NAME },
                { nKey = SOCIALPANEL_NAME_DISPLAY.REMARK, szText = g_tStrings.STR_FRIEND_LIST_DISPLAY_MODE_REMARK },
                { nKey = SOCIALPANEL_NAME_DISPLAY.NICKNAME_AND_REMARK, szText = g_tStrings.STR_FRIEND_LIST_DISPLAY_MODE_NAME_REMARK },
                { nKey = SOCIALPANEL_NAME_DISPLAY.REMARK_AND_NICKNAME, szText = g_tStrings.STR_FRIEND_LIST_DISPLAY_MODE_REMARK_NAME },
            }

            UIMgr.Open(VIEW_ID.PanelFriendChangeListPop, g_tStrings.STR_SET_FRIEND_LIST_DISPALY_MODE_TITLE, g_tStrings.STR_SET_FRIEND_LIST_DISPALY_MODE_TIP_CONTENT, tbItems, nDefaultDisplayMode, function (nKey)
                if nDefaultDisplayMode ~= nKey then
                    Storage.Fellowship.NameDisplayMode = nKey
                    Storage.Fellowship.Dirty()
                end

                Event.Dispatch(EventType.OnUpdateFellowShip)
            end)

            UIHelper.SetSelected(self.ToggleSelect, false)
        end }},
        MoreBtn = { { szName = "查看更多", bNesting = true, tbSubMenus = {
            { szName = "查看名帖", callback = function()
                TipsHelper.DeleteAllHoverTips()
                UIMgr.Open(VIEW_ID.PanelNameCard, self.tbPlayerInfo.id, self.tbRoleEntryInfo, self.tbPlayerInfo.attraction)
            end },
            { szName = "查看侠客", callback = function()
                TipsHelper.DeleteAllHoverTips()
                UIMgr.Open(VIEW_ID.PanelPartner, self.tbRoleEntryInfo.dwPlayerID)
            end, fnDisable = function()
                return not GetPlayer(self.tbRoleEntryInfo.dwPlayerID)
            end
            },}
        }},

        GuildRomoveMember = {{ szName = g_tStrings.STR_GUILD_ROMOVE_MEMBER, bCloseOnClick = true,
            fnCheckShow = function ()
                return self.tbPlayerInfo.dwID ~= GetTongClient().dwNextMaster and
                GetTongClient().CheckAdvanceOperationGroup(self.tMyMemberInfo.nGroupID, self.tbPlayerInfo.nGroupID, 0)
            end,
            callback = function()
                if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TONG_OPERATE, "Tong") then
                    return
                end

                UIHelper.ShowConfirm(FormatString(g_tStrings.STR_GUILD_KICK_SURE, "[" .. UIHelper.GBKToUTF8(self.tbPlayerInfo.szName) .. "]"), function ()
                    GetTongClient().ApplyKickOutMember(self.tbPlayerInfo.dwID)
                end)
            end
        }},

        GuildChangeMaster = {
            {
                szName = g_tStrings.STR_GUILD_CHANGE_MASTER_1, bCloseOnClick = true,
                fnCheckShow = function ()
                    return g_pClientPlayer.dwID == GetTongClient().dwMaster and GetTongClient().dwNextMaster == 0
                end,
                callback = function ()
                    UIMgr.Open(VIEW_ID.PanelFactionTransferPop, self.tbPlayerInfo)
                end
            },
            {
                szName = g_tStrings.STR_GUILD_CANCLE_CHANGE_MASTER, bCloseOnClick = true,
                fnCheckShow = function ()
                    return GetTongClient().dwNextMaster == self.tbPlayerInfo.dwID and g_pClientPlayer.dwID == GetTongClient().dwMaster
                end,
                callback = function ()
                    UIHelper.ShowConfirm(g_tStrings.STR_GUILD_CANCLE_CHANGE_MASTER_SURE, function ()
                        GetTongClient().CancelChangeMaster()
                    end)
                end
            },
        },

        GuildChangeGroup = {{
                szName = g_tStrings.STR_GUILD_MOVE_TO_GROUP, bCloseOnClick = true, bNesting = true,
                fnCheckShow = function ()
                    return self.tbPlayerInfo.dwID ~= GetTongClient().dwNextMaster and
                    GetTongClient().CheckAdvanceOperationGroup(self.tMyMemberInfo.nGroupID, self.tbPlayerInfo.nGroupID, 0)
                end,
                tbSubMenus = self:GetCanAddMemberGroupList()
        },},

        Room = {{
            szName = "房间",
            callback = function()
                local dwFriendID = self.tbPlayerInfo.id
                local szFriendName = self.tbRoleEntryInfo.szName
                local nCenterID    = self.tbRoleEntryInfo.dwCenterID
                RoomData.InviteRoomorApplyRoom(dwFriendID, szFriendName, nCenterID)
            end
        }},

        MasterOrApprentice = {{
            szName = "拜师收徒", bNesting = true, tbSubMenus =
            {
                { szName = "收徒", bCloseOnClick = true, callback = function()
                    RemoteCallToServer("OnApplyApprentice", self.tbRoleEntryInfo.szName)
                end },
                { szName = "拜师", bCloseOnClick = true, callback = function()
                    RemoteCallToServer("OnApplyMentor", self.tbRoleEntryInfo.szName)
                end },
                { szName = "拜亲传师父", bCloseOnClick = true, callback = function()
                    RemoteCallToServer("OnApplyDirectMentor", self.tbRoleEntryInfo.szName)
                end },
            }
        }},
        Arena = {{
            szName = "加入名剑队", bNesting = true, tbSubMenus = {
                { szName = "2对2", fnDisable = function()
                    SyncCorpsList(GetClientPlayer().dwID)
                    ArenaData.SyncAllCorpsBaseInfo()
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_2V2, GetClientPlayer().dwID)
                    if nCorpsID and nCorpsID > 0 then
                        return false
                    end
                    return CrossMgr.IsCrossing(nil,false)
                end,
                callback = function()
                    TipsHelper.ShowNormalTip("已成功发出邀请")
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_2V2, GetClientPlayer().dwID)
                    InvitationJoinCorps(self.tbRoleEntryInfo.szName, nCorpsID)
                end },
                { szName = "3对3", fnDisable = function()
                    SyncCorpsList(GetClientPlayer().dwID)
                    ArenaData.SyncAllCorpsBaseInfo()
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_3V3, GetClientPlayer().dwID)
                    if nCorpsID and nCorpsID > 0 then
                        return false
                    end
                    return CrossMgr.IsCrossing(nil,false)
                end,callback = function()
                    TipsHelper.ShowNormalTip("已成功发出邀请")
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_3V3, GetClientPlayer().dwID)
                    InvitationJoinCorps(self.tbRoleEntryInfo.szName, nCorpsID)
                end },
                { szName = "5对5", fnDisable = function()
                    ArenaData.SyncAllCorpsBaseInfo()
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_5V5, GetClientPlayer().dwID)
                    if nCorpsID and nCorpsID > 0 then
                        return false
                    end
                    return CrossMgr.IsCrossing(nil,false)
                end,callback = function()
                    TipsHelper.ShowNormalTip("已成功发出邀请")
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_5V5, GetClientPlayer().dwID)
                    InvitationJoinCorps(self.tbRoleEntryInfo.szName, nCorpsID)
                end },
                { szName = "海选赛", fnDisable = function()
                    ArenaData.SyncAllCorpsBaseInfo()
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_MASTER_3V3, GetClientPlayer().dwID)
                    if nCorpsID and nCorpsID > 0 then
                        return false
                    end
                    return CrossMgr.IsCrossing(nil,false)
                end,callback = function()
                    TipsHelper.ShowNormalTip("已成功发出邀请")
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_MASTER_3V3, GetClientPlayer().dwID)
                    InvitationJoinCorps(self.tbRoleEntryInfo.szName, nCorpsID)
                end },
                { szName = "名剑训练赛", fnDisable = function()
                    ArenaData.SyncAllCorpsBaseInfo()
                    if nCorpsID and nCorpsID > 0 then
                        return false
                    end
                    return CrossMgr.IsCrossing(nil,false)
                end,callback = function()
                    TipsHelper.ShowNormalTip("已成功发出邀请")
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_PRACTICE, GetClientPlayer().dwID)
                    InvitationJoinCorps(self.tbRoleEntryInfo.szName, nCorpsID)
                end },
            }
        }},
        ReportRabot = {{
            szName = "举报外挂", bCloseOnClick = true,
            callback = function()
                local szName = self.tbRoleEntryInfo.szName

                local hScene = nil
                local tbSelectInfo =
                {
                    szName = szName,
                    szMapName = nil,
                }
                UIMgr.Open(VIEW_ID.PanelTutorialCollection, ServiceCenterData.TabModleType.InformScript, tbSelectInfo, 1)
            end
        }},
        FeedBack = {{
            szName = "反馈问题",
            bCloseOnClick = true,
            callback = function()
                local tbSelectInfo =
                {
                    nSelectIndex = 1,
                    tbParams = {}
                }
                local tbScript = UIMgr.Open(VIEW_ID.PanelTutorialCollection, ServiceCenterData.TabModleType.FeeBug, tbSelectInfo , 1)
                TipsHelper.DeleteAllHoverTips()
            end
        }},
        DeleteChatHistory = {{
            szName = "删除记录",
            bCloseOnClick = true,
            callback = function()
                local szPlayerName = UIHelper.GBKToUTF8(self.tbPlayerInfo.szName)
                if szPlayerName then
                    local szTips = string.format("是否删除联系人【%s】的聊天记录？", szPlayerName)
                    local confirm = UIHelper.ShowConfirm(szTips, function()
                        ChatRecentMgr.DelChatHistory(self.tbPlayerInfo.szGlobalID, szPlayerName)
                    end)
                end
            end
        }},

        AINpcChat = {{ szName = "对话", bCloseOnClick = true, callback = function()
            local bDelete = self.tbRoleEntryInfo.szName == ""
            local szName = bDelete and UIHelper.GBKToUTF8(self.tbPlayerInfo.szName) or UIHelper.GBKToUTF8(self.tbRoleEntryInfo.szName)
            local dwTalkerID = self.tbRoleEntryInfo.dwPlayerID
            local bIsFriend = self.nRelationType == FellowshipData.tbRelationType.nFriend
            local dwForceID = self.tbRoleEntryInfo.nForceID
            local dwMiniAvatarID = self.tbRoleEntryInfo.dwMiniAvatarID
            local nRoleType = self.tbRoleEntryInfo.nRoleType
            local nLevel = self.tbRoleEntryInfo.nLevel
            local szGlobalID = self.tbPlayerInfo.id
            local dwCenterID = self.tbRoleEntryInfo.dwCenterID
            local tbData = {szName = szName, dwTalkerID = dwTalkerID, dwForceID = dwForceID, dwMiniAvatarID = dwMiniAvatarID, nRoleType = nRoleType, nLevel = nLevel, szGlobalID = szGlobalID, dwCenterID = dwCenterID}

            ChatHelper.ChatAINpcTo(self.tbPlayerInfo.dwID)
            UIHelper.SetSelected(self.ToggleSelect, false)
        end , fnDisable = function()
            return false--not bOnLine
        end}},

        AINpcDetail = {{ szName = "详情", bCloseOnClick = true, callback = function()
            local script = UIMgr.GetViewScript(VIEW_ID.PanelPartner)
            if script then
                local scriptPartnerCard = script.scriptPartnerCard
                if scriptPartnerCard then
                    local dwPartnerID = self.tbPlayerInfo.dwID
                    local tbPartnerIDLis = scriptPartnerCard.tPartnerIDList
                    scriptPartnerCard:OpenPartnerDetailPage(dwPartnerID, tbPartnerIDLis)
                end
            else
                UIMgr.Open(VIEW_ID.PanelPartner, nil, PartnerViewOpenType.Default)
                Event.Reg(self, EventType.OnViewOpen, function (nViewID)
                    if nViewID == VIEW_ID.PanelPartner then
                        Event.UnReg(self, EventType.OnViewOpen)

                        local script = UIMgr.GetViewScript(VIEW_ID.PanelPartner)
                        if script then
                            local scriptPartnerCard = script.scriptPartnerCard
                            if scriptPartnerCard then
                                local dwPartnerID = self.tbPlayerInfo.dwID
                                local tbPartnerIDLis = scriptPartnerCard.tPartnerIDList
                                scriptPartnerCard:OpenPartnerDetailPage(dwPartnerID, tbPartnerIDLis)
                            end
                        end

                        UIMgr.Close(VIEW_ID.PanelChatSocial)
                    end
                end)
            end

        end , fnDisable = function()
            return false--not bOnLine
        end}},

    }
end

function UIPlayerMessageTog:GetCanAddMemberGroupList()
    local tbSubMenus = {}
    if self.nRelationType == FellowshipData.tbRelationType.nTong then
        local tbGroupList = TongData.GetCanAddMemberGroupList(self.tbPlayerInfo.nGroupID)
        for _, tbInfo in ipairs(tbGroupList) do
            local tbGroup = {
                szName = UIHelper.GBKToUTF8(tbInfo.szName),
                callback = function()
                    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TONG_OPERATE) then
                        return
                    end

                    TongData.ChangeMemberGroup(self.tbPlayerInfo.dwID, tbInfo.nGroupIndex)
                end,
            }
            table.insert(tbSubMenus, tbGroup)
        end
    end

    return tbSubMenus
end

function UIPlayerMessageTog:GenerateMenuConfig()
    local tbMenuConfig = {}
    local tbMenuConfigSet = {}
    if self.nRelationType == FellowshipData.tbRelationType.nFriend then
        if self.bRemoteFriend or self.bInRemoteState then
            tbMenuConfigSet = {
                self.tbMenuConfigSet.Chat, self.tbMenuConfigSet.Group, self.tbMenuConfigSet.Room,
                self.tbMenuConfigSet.Friend, self.tbMenuConfigSet.MoreBtn, self.tbMenuConfigSet.PeekEquip,
                self.tbMenuConfigSet.Remark, self.tbMenuConfigSet.Black,
                self.tbMenuConfigSet.SetFellowshipGroup, self.tbMenuConfigSet.SetDisplayMode,
                self.bRecruit and self.tbMenuConfigSet.FriendBack or nil,
            }
        else
            tbMenuConfigSet = {
                self.tbMenuConfigSet.Chat, self.tbMenuConfigSet.Group,
                self.tbMenuConfigSet.Room,self.tbMenuConfigSet.Tong,
                self.tbMenuConfigSet.MoreBtn, self.tbMenuConfigSet.PeekEquip,
                self.tbMenuConfigSet.Foe,self.tbMenuConfigSet.Remark,
                self.tbMenuConfigSet.MasterOrApprentice,
                self.tbMenuConfigSet.Black,self.tbMenuConfigSet.SetDisplayMode,
                self.tbMenuConfigSet.Friend,self.tbMenuConfigSet.SetFellowshipGroup,
                self.bRecruit and self.tbMenuConfigSet.FriendBack or nil,
            }
        end

    elseif self.nRelationType == FellowshipData.tbRelationType.nBlack then
        tbMenuConfigSet = { self.tbMenuConfigSet.Black }
    elseif self.nRelationType == FellowshipData.tbRelationType.nFoe then
        tbMenuConfigSet = { self.tbMenuConfigSet.DelFoe }
    elseif self.nRelationType == FellowshipData.tbRelationType.nFeud then
        tbMenuConfigSet = { self.tbMenuConfigSet.DelFeud }
    elseif self.nRelationType == FellowshipData.tbRelationType.nMaster then
        local bIng = false
        for k,v in pairs(QUEST_ID) do
            local nTraceInfo = g_pClientPlayer.GetQuestPhase(v)
            if nTraceInfo == TASK_ING or nTraceInfo == TASK_FINISH_NOT_HAND_IN or nTraceInfo == TASK_FINISH_AND_HAND_IN then
                bIng = true
            end
        end
        tbMenuConfigSet = {
            self.tbMenuConfigSet.Call, self.tbMenuConfigSet.Group, self.tbMenuConfigSet.Chat,
            self.tbMenuConfigSet.PeekEquip,self.tbMenuConfigSet.MoreInfo,
            self.bCancelBreak and self.tbMenuConfigSet.CancleStopRelation or self.tbMenuConfigSet.StopRelation,
            -- (not self.tbPlayerInfo.bDirectM) and (bIng and self.tbMenuConfigSet.GraduationState or self.tbMenuConfigSet.Graduation) or nil,
            (bIng and self.tbMenuConfigSet.GraduationState or self.tbMenuConfigSet.Graduation)
        }
    elseif self.nRelationType == FellowshipData.tbRelationType.nApprentice then
        tbMenuConfigSet = { self.tbMenuConfigSet.Call, self.tbMenuConfigSet.Group, self.tbMenuConfigSet.Chat,
            self.tbMenuConfigSet.PeekEquip,self.tbMenuConfigSet.MoreInfo,
            self.bCancelBreak and self.tbMenuConfigSet.CancleStopRelation or self.tbMenuConfigSet.StopRelation,
        }
    elseif self.nRelationType == FellowshipData.tbRelationType.nSameApp then
        if self.tbPlayerInfo.bSelf then
            tbMenuConfigSet = {}
        else
            tbMenuConfigSet = {
                self.tbMenuConfigSet.Group, self.tbMenuConfigSet.Chat,
                self.tbMenuConfigSet.PeekEquip,self.tbMenuConfigSet.MoreInfo,
            }
        end
    elseif self.nRelationType == FellowshipData.tbRelationType.nTong then
        tbMenuConfigSet = {
            self.tbMenuConfigSet.Chat, self.tbMenuConfigSet.Group, self.tbMenuConfigSet.PeekEquip,
            self.tbMenuConfigSet.GuildRomoveMember, self.tbMenuConfigSet.GuildChangeMaster, self.tbMenuConfigSet.GuildChangeGroup,
        }
    elseif self.nRelationType == FellowshipData.tbRelationType.nAroundPlayer then
        tbMenuConfig = {}
    elseif self.nRelationType == FellowshipData.tbRelationType.nRecent then
        tbMenuConfigSet = {
            self.tbMenuConfigSet.Chat, self.tbMenuConfigSet.Group,
            self.tbMenuConfigSet.Room,self.tbMenuConfigSet.Friend,
            self.tbMenuConfigSet.MasterOrApprentice,
            self.tbMenuConfigSet.Tong, self.tbMenuConfigSet.Arena,
            self.tbMenuConfigSet.ReportRabot, self.tbMenuConfigSet.FeedBack,
            self.tbMenuConfigSet.Black, self.tbMenuConfigSet.DeleteChatHistory
        }
    elseif self.nRelationType == FellowshipData.tbRelationType.nNpc then
        tbMenuConfigSet = {
            self.tbMenuConfigSet.AINpcChat, self.tbMenuConfigSet.AINpcDetail
        }
    end

    for _, ConfigSet in ipairs(tbMenuConfigSet) do
        for _, Config in ipairs(ConfigSet) do
            table.insert(tbMenuConfig, Config)
        end
    end

    return tbMenuConfig
end

function UIPlayerMessageTog:SetToggleGroup(ToggleGroupPlayer)
    UIHelper.ToggleGroupAddToggle(ToggleGroupPlayer, self.ToggleSelect)
end

function UIPlayerMessageTog:OnClickOther()
    local scriptPop
    if self.nRelationType ~= FellowshipData.tbRelationType.nAroundPlayer and
    self.nRelationType ~= FellowshipData.tbRelationType.nFriend then
        if self.tbPlayerInfo and self.tbPlayerInfo.bDelete then
            TipsHelper.ShowNormalTip("该角色已删除")
            -- scriptPop = UIHelper.AddPrefab(PREFAB_ID.WidgetPlayerPop, self.WidgetPlayerPop, self.tbPlayerInfo.dwID, {}, self.tbPlayerInfo, false)
        else
            scriptPop = UIHelper.AddPrefab(PREFAB_ID.WidgetPlayerPop, self.WidgetPlayerPop, self.tbPlayerInfo.id or self.tbPlayerInfo.dwID, self:GenerateMenuConfig(), self.tbRoleEntryInfo, false)
        end
        if scriptPop then
            scriptPop:SetbOpenPanelClose()
        end
    end

    if self.nRelationType == FellowshipData.tbRelationType.nMaster or
    self.nRelationType == FellowshipData.tbRelationType.nApprentice or
    self.nRelationType == FellowshipData.tbRelationType.nSameApp then
        scriptPop:ShowMentorInfo(self.tbPlayerInfo, self.tbRoleEntryInfo)
    end
end

function UIPlayerMessageTog:OnClickFriendOrArround()
    local scriptPop
    if self.nRelationType == FellowshipData.tbRelationType.nFriend or
    self.nRelationType == FellowshipData.tbRelationType.nAroundPlayer or self.nRelationType == FellowshipData.tbRelationType.nRecent then
        if self.nRelationType == FellowshipData.tbRelationType.nFriend then
            scriptPop = UIHelper.AddPrefab(PREFAB_ID.WidgetPlayerPop, self.WidgetPlayerPop, self.tbPlayerInfo.id, self:GenerateMenuConfig(), self.tbRoleEntryInfo, true)
            if scriptPop then
                scriptPop:ShowFellowshipInfo(self.tbPlayerInfo)
            end
        else
            scriptPop = UIHelper.AddPrefab(PREFAB_ID.WidgetPlayerPop, self.WidgetPlayerPop, self.tbPlayerInfo.dwID)
        end

        local szGlobalID = self.tbPlayerInfo.id or GetPlayer(self.tbPlayerInfo.dwID).GetGlobalID()
        if scriptPop then
            scriptPop:SetPersonalVisible()
            local personalCardScript
            if self.nRelationType == FellowshipData.tbRelationType.nFriend then
                personalCardScript = UIHelper.AddPrefab(PREFAB_ID.WidgetPersonalCard, scriptPop.WidgetPersonalCardTips, szGlobalID, nil, self.tbRoleEntryInfo)
            else
                personalCardScript = UIHelper.AddPrefab(PREFAB_ID.WidgetPersonalCard, scriptPop.WidgetPersonalCardTips, szGlobalID)
            end

            if personalCardScript then
                personalCardScript:SetPlayerId(self.tbPlayerInfo.dwID)
                local fnOnClickMore = function ()
                    scriptPop:SetPersonalVisible(false)
                end
                personalCardScript:UpdateOtherPlayerBtn(fnOnClickMore, self.tbRoleEntryInfo, self.tbPlayerInfo.dwID)
            end
        end
    end
end

function UIPlayerMessageTog:UpdateRecentInfo()
    if not (self.nRelationType == FellowshipData.tbRelationType.nRecent) then
        return
    end

    UIHelper.SetVisible(self.BtnMore, self.nRelationType == FellowshipData.tbRelationType.nRecent)
    UIHelper.SetSwallowTouches(self.BtnMore, true)

    local bFrined = FellowshipData.IsFriend(self.tbPlayerInfo.id)

    local tbFriendList = FellowshipData.GetFellowshipInfoList() or {}

    local szUtf8Name = self.tbRoleEntryInfo.szName
    if szUtf8Name ~= "" then
        szUtf8Name = UIHelper.GBKToUTF8(self.tbRoleEntryInfo.szName)
    else
        szUtf8Name = g_tStrings.MENTOR_DELETE_ROLE
    end

    local szDisplayName = ChatRecentMgr.GetPlayerRemarkNameByGlobalID(szUtf8Name, self.tbPlayerInfo.id, self.nDisplayMode)

    for i = 1, 2, 1 do
        UIHelper.SetString(self.tbLabelName[i], szDisplayName, 8)
        UIHelper.SetVisible(self.tbWidgetRecentContacts[i], self.nRelationType == FellowshipData.tbRelationType.nRecent)
        UIHelper.SetVisible(self.tbImgRecentContacts[i], self.tbPlayerInfo.nNewMsgCount > 0)
        UIHelper.SetVisible(self.tbImgFriend[i], bFrined)
        UIHelper.SetVisible(self.tbImgNotFriend[i], not bFrined)

    end

    UIHelper.SetString(self.LabelRecentContactsInfo, string.format("有%d条新消息", self.tbPlayerInfo.nNewMsgCount))
    UIHelper.SetString(self.LabelSelectedRecentContactsInfo, string.format("有%d条新消息", self.tbPlayerInfo.nNewMsgCount))

end

return UIPlayerMessageTog