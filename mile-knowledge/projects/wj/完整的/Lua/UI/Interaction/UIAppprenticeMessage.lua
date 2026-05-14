-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIAppprenticeMessage
-- Date: 2024-03-26 10:47:44
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIAppprenticeMessage = class("UIAppprenticeMessage")

local BUFF_ID_OF_GRADUATION_CD = 15743
local QUEST_ID 	= {13470, 13469}
local TASK_ING = 1
local TASK_FINISH_NOT_HAND_IN = 2
local TASK_FINISH_AND_HAND_IN = 3

function UIAppprenticeMessage:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    UIMgr.Close(VIEW_ID.PanelChatSocial)
end

function UIAppprenticeMessage:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAppprenticeMessage:BindUIEvent()
    -- UIHelper.BindUIEvent(self.BtnZhaoqing, EventType.OnClick)

    UIHelper.BindUIEvent(self.BtnZhaoqing, EventType.OnClick, function ()
        self:Call()
    end)

    UIHelper.BindUIEvent(self.BtnZhuangbei, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelOtherPlayer, self.tbPlayerInfo.dwID)
    end)

    UIHelper.BindUIEvent(self.BtnHudong, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelInteractActivityPop, UIHelper.GBKToUTF8(self.tbPlayerInfo.szName), self.nRelationType, self.tbPlayerInfo.dwID, self.tbPlayerInfo, self.tSocialInfo.MiniAvatarID)
    end)

    UIHelper.BindUIEvent(self.BtnTeam, EventType.OnClick, function ()
        TeamData.InviteJoinTeam(self.tbPlayerInfo.szName)
    end)

    UIHelper.BindUIEvent(self.BtnChat, EventType.OnClick, function ()
        local szName = UIHelper.GBKToUTF8(self.tbPlayerInfo.szName)
        local dwTalkerID = self.tbPlayerInfo.dwID
        local dwForceID = self.tbPlayerInfo.nForceID
        local dwMiniAvatarID = self.tSocialInfo.MiniAvatarID
        local nRoleType = self.tbPlayerInfo.nRoleType
        local nLevel = self.tbPlayerInfo.nLevel
        local dwForceID = self.tbPlayerInfo.dwForceID
        local tbData = {szName = szName, dwTalkerID = dwTalkerID, dwForceID = dwForceID, dwMiniAvatarID = dwMiniAvatarID, nRoleType = nRoleType, nLevel = nLevel}

        ChatHelper.WhisperTo(szName, tbData)
    end)

    UIHelper.BindUIEvent(self.BtnDuan, EventType.OnClick, function ()
        if self.bCancelBreak then
            self:CancleStopRelation()
        else
            self:StopRelation()
        end
    end)

    UIHelper.BindUIEvent(self.BtnDuan2, EventType.OnClick, function ()
        if self.bCancelBreak then
            self:CancleStopRelation()
        else
            self:StopRelation()
        end
    end)

    UIHelper.BindUIEvent(self.BtnChu, EventType.OnClick, function ()
        if self.bGraduation then
            --出师中
            TipsHelper.ShowNormalTip(g_tStrings.STR_QUESTING_TIP)
        else
            local buffIsInGraduationCD = Player_GetBuff(BUFF_ID_OF_GRADUATION_CD)
            if buffIsInGraduationCD then
                TipsHelper.ShowNormalTip(g_tStrings.MENTOR_MSG.ON_GRADUATED_CDLIMIT)
            end
            if g_pClientPlayer.nLevel >= g_pClientPlayer.nMaxLevel then --出师活动
                UIHelper.ShowConfirm(g_tStrings.STR_NORNAL_MENTOR_BREAK_FULL_LEVEL,function ()
                    g_pClientPlayer.AcceptQuest(TARGET.NO_TARGET, 0, QUEST_ID[1])
                    TipsHelper.ShowNormalTip("出师任务已接取，请查看完成！")

                    self.bGraduation = true
                    if self.bGraduation then
                        UIHelper.SetString(self.LableChu, "出师中")
                    end
                end)
            else
                TipsHelper.ShowNormalTip("侠士尚未满级，不可出师")
            end
        end
    end)
end

function UIAppprenticeMessage:RegEvent()
    Event.Reg(self, "ON_SYNC_LEFT_EVOKE_NUM", function ()
        self:UpdateCallTime()
    end)
end

function UIAppprenticeMessage:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAppprenticeMessage:SetAppprenticeMessageInfo(Info, nRelationType)
    self.nRelationType = nRelationType
    self.tbPlayerInfo = Info
    self.tSocialInfo = FellowshipData.tApplySocialList[self.tbPlayerInfo.dwID] or FellowshipData.GetSocialInfo(self.tbPlayerInfo.dwID) or {}

    UIHelper.RemoveAllChildren(self.WidgetMasterHead03)
    local scriptHead = UIHelper.AddPrefab(PREFAB_ID.WidgetHead_108, self.WidgetMasterHead03)
    if scriptHead then
        scriptHead:SetHeadInfo(self.tbPlayerInfo.dwID, self.tSocialInfo.MiniAvatarID or 0, self.tbPlayerInfo.nRoleType, self.tbPlayerInfo.dwForceID)
        scriptHead:SetTouchEnabled(false)
    end

    local szTongName = self.tbPlayerInfo.szTongName ~= "" and UIHelper.GBKToUTF8(self.tbPlayerInfo.szTongName) or "无"

    if not self.tbPlayerInfo.bDelete then
        UIHelper.SetString(self.LableName, UIHelper.GBKToUTF8(self.tbPlayerInfo.szName))
    else
        UIHelper.SetString(self.LableName, self.tbPlayerInfo.szName)
    end

    _, szTongName = UIHelper.TruncateString(szTongName, 8, "...")
    UIHelper.SetRichText(self.RichTextMessage01, "<c/><color=#AED9E0>所属帮会：</color><color=#ffffff>".. szTongName .."<c/>")

    self:UpdateTextInfo()
    self:UpdateRecordState()
    self:UpdateButtonState()
    self:UpdateCallTime()

    UIHelper.LayoutDoLayout(self.WidgetHeadMeassage)
    UIHelper.SetVisible(self.WidgetBtnList, self.tbPlayerInfo.dwID ~= UI_GetClientPlayerID())
    UIHelper.SetVisible(self.ImgLeftLine, true)
    UIHelper.SetVisible(self.ImgRightBg, true)
end

function UIAppprenticeMessage:UpdateCallTime()
    if 3 - g_pClientPlayer.nEvokeMentorCount > 0 then
        UIHelper.SetString(self.LableZhaoqing, "召请 (" .. 3 - g_pClientPlayer.nEvokeMentorCount .. ")")
    else
        UIHelper.SetString(self.LableZhaoqing, "召请")
    end
end

function UIAppprenticeMessage:UpdateTextInfo()
    --拜师时间
    local t = TimeToDate(self.tbPlayerInfo.nCreateTime)
	local szText = FormatString(g_tStrings.STR_TIME_1, t.year - 2000, t.month, t.day)
    UIHelper.SetRichText(self.RichTextMessage02, "<c/><color=#AED9E0>拜师时间：</color><color=#ffffff>".. szText .."<c/>")

    --上次登录时间
    local szTime = ""
    if self.tbPlayerInfo.bOnLine then
        szTime = g_tStrings.STR_GUILD_ONLINE
    else
        if self.tbPlayerInfo.nOfflineTime < 0 then self.tbPlayerInfo.nOfflineTime = 0 end
        local nYear = math.floor(self.tbPlayerInfo.nOfflineTime / (3600 * 24 * 365))
        if self.tbPlayerInfo.bDelete then
            szTime = g_tStrings.STR_NO_TIME
        elseif nYear > 0 then
            szTime = FormatString(g_tStrings.STR_GUILD_TIME_YEAR_BEFORE, nYear)
        else
            local nD = math.floor(self.tbPlayerInfo.nOfflineTime / (3600 * 24))
            if nD > 0 then
                szTime = FormatString(g_tStrings.STR_GUILD_TIME_DAY_BEFORE, nD)
            else
                local nH = math.floor(self.tbPlayerInfo.nOfflineTime / 3600)
                if nH > 0 then
                    szTime = FormatString(g_tStrings.STR_GUILD_TIME_HOUR_BEFORE, nH)
                else
                    szTime = g_tStrings.STR_GUILD_TIME_IN_ONE_HOUR
                end
            end
        end
        szTime = szTime .. "登录"
    end

    UIHelper.SetRichText(self.RichTextMessage03, "<c/><color=#AED9E0>最后登录：</color><color=#ffffff>".. szTime .."<c/>")

    if self.tbPlayerInfo.nMentorValue and self.tbPlayerInfo.bDirectM ~= false then
        UIHelper.SetRichText(self.RichTextMessage04, "<c/><color=#AED9E0>师  徒  值：</color><color=#ffffff>".. self.tbPlayerInfo.nMentorValue .."<c/>")
    else
        UIHelper.SetRichText(self.RichTextMessage04, "")
    end
end

function UIAppprenticeMessage:UpdateRecordState()
    local szTip = ""
    local nEndTime = self.tbPlayerInfo.nEndTime - GetCurrentTime() - 120
    if nEndTime < 0 then
        nEndTime = 0
    end

    self.bCancelBreak = false

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

    if self.bCancelBreak then
        UIHelper.SetString(self.LableDuan, "取消断绝")
        UIHelper.SetString(self.LableDuan2, "取消断绝")
    else
        UIHelper.SetString(self.LableDuan, "断绝关系")
        UIHelper.SetString(self.LableDuan2, "断绝关系")
    end

    UIHelper.SetString(self.LableDuanTime, szTip)

    self.bGraduation = false
    for k,v in pairs(QUEST_ID) do
        local nTraceInfo = g_pClientPlayer.GetQuestPhase(v)
        if nTraceInfo == TASK_ING or nTraceInfo == TASK_FINISH_NOT_HAND_IN or nTraceInfo == TASK_FINISH_AND_HAND_IN then
            self.bGraduation = true
        end
    end

    if self.bGraduation then
        UIHelper.SetString(self.LableChu, "出师中")
    end
end

function UIAppprenticeMessage:UpdateButtonState()
    UIHelper.SetButtonState(self.BtnZhaoqing, self.tbPlayerInfo.bOnLine and BTN_STATE.Normal or BTN_STATE.Disable)
    UIHelper.SetVisible(self.BtnZhaoqing, self.nRelationType ~= FellowshipData.tbRelationType.nSameApp)
    UIHelper.SetButtonState(self.BtnHudong, self.tbPlayerInfo.bOnLine and BTN_STATE.Normal or BTN_STATE.Disable)
    UIHelper.SetButtonState(self.BtnZhuangbei, self.tbPlayerInfo.bOnLine and BTN_STATE.Normal or BTN_STATE.Disable)
    UIHelper.SetButtonState(self.BtnTeam, (self.tbPlayerInfo.bOnLine and TeamData.CanMakeParty()) and BTN_STATE.Normal or BTN_STATE.Disable)
    UIHelper.SetButtonState(self.BtnChat, self.tbPlayerInfo.bDelete and BTN_STATE.Disable or BTN_STATE.Normal)

    UIHelper.SetVisible(self.ImgLine, self.nRelationType == FellowshipData.tbRelationType.nMaster)
    -- UIHelper.SetButtonState(self.BtnDuan, self.tbPlayerInfo.bOnLine and BTN_STATE.Normal or BTN_STATE.Disable)
    UIHelper.SetVisible(self.BtnDuan, self.nRelationType == FellowshipData.tbRelationType.nMaster)
    UIHelper.SetVisible(self.BtnChu, self.nRelationType == FellowshipData.tbRelationType.nMaster)
    UIHelper.SetVisible(self.BtnDuan2, self.nRelationType == FellowshipData.tbRelationType.nApprentice)

    UIHelper.SetButtonState(self.BtnChu, (self.tbPlayerInfo.bDelete or self.tbPlayerInfo.bDirectM) and BTN_STATE.Disable or BTN_STATE.Normal)
end

function UIAppprenticeMessage:StopRelation()
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

    if not self.tbPlayerInfo.bDelete then
        UIHelper.ShowConfirm(FormatString(szText, UIHelper.GBKToUTF8(self.tbPlayerInfo.szName)),funcConfirm)
    else
        UIHelper.ShowConfirm(FormatString(szText, self.tbPlayerInfo.szName),funcConfirm)
    end
end

function UIAppprenticeMessage:CancleStopRelation()
    --取消断绝
    if self.tbPlayerInfo.bDirectM == true then
        RemoteCallToServer("OnCancelGraduateByApprentice", self.tbPlayerInfo.dwID) -- 跟亲传师父取消断绝
    elseif self.tbPlayerInfo.bDirectM == false then
        RemoteCallToServer("OnCancelBreakMentor", self.tbPlayerInfo.dwID) -- 跟普通师父取消断绝
    elseif self.tbPlayerInfo.bDirectA == true then
        RemoteCallToServer("OnCancelGraduateByMentor", self.tbPlayerInfo.dwID)
    elseif self.tbPlayerInfo.bDirectA == false then
        RemoteCallToServer("OnCancelBreakApprentice", self.tbPlayerInfo.dwID)
    end
end

function UIAppprenticeMessage:Call()
    if self.tbPlayerInfo.nLevel < 110 then
        TipsHelper.ShowNormalTip("对方等级低于110级，不能召请")
        return
    end

    local szName = UIHelper.GBKToUTF8(self.tbPlayerInfo.szName)
    local nCount = 3 - g_pClientPlayer.nEvokeMentorCount

    local szText = ""
    if nCount > 0 then
        if self.nRelationType == FellowshipData.tbRelationType.nMaster then
            szText = FormatString(g_tStrings.MENTOR_CALL_SURE, szName, 3, nCount)
        elseif self.nRelationType == FellowshipData.tbRelationType.nApprentice then
            szText = FormatString(g_tStrings.MENTOR_CALL_APPRENTICE_SURE, szName, 3, nCount)
        end
        UIHelper.ShowConfirm(szText,function ()
            RemoteCallToServer("OnApplyEvoke", self.tbPlayerInfo.dwID)
        end)
    else
        if self.nRelationType == FellowshipData.tbRelationType.nMaster then
            szText = g_tStrings.MENTOR_CALL_MASTER_PAY
        elseif self.nRelationType == FellowshipData.tbRelationType.nApprentice then
            szText = g_tStrings.MENTOR_CALL_APPRENTICE_PAY
        end
        local szScript = UIHelper.ShowSwitchMapConfirm(szText, function ()
            RemoteCallToServer("OnApplyEvoke", self.tbPlayerInfo.dwID)
        end)
        if szScript then
            szScript:UpdateMentor()
        end
    end
end

return UIAppprenticeMessage