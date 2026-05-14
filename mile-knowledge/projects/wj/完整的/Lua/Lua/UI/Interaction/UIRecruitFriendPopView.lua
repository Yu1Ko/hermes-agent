-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIRecruitFriendPopView
-- Date: 2023-05-29 16:39:57
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIRecruitFriendPopView = class("UIRecruitFriendPopView")

function UIRecruitFriendPopView:OnEnter(dwFriendID, tFriendInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.dwFriendID  = dwFriendID
    self.tFriendInfo = tFriendInfo
    self:InitFriendBackInfo()
end

function UIRecruitFriendPopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
	Timer.DelAllTimer(self)
end

function UIRecruitFriendPopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnReward, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelOperationCenter,11)
		UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCopy, EventType.OnClick, function ()
        local szUrl = "http://jx3.xoyo.com/zt/2015/02/06/friend/index.html?param="
        SetClipboard(szUrl)

		TipsHelper.ShowNormalTip("复制成功。")
    end)

    UIHelper.BindUIEvent(self.BtnSend, EventType.OnClick, function ()
        if self.tFriendInfo.szName then
			RemoteCallToServer("OnSendFriendsInviteEmail", self.tFriendInfo.szName, "", "", self.szContent)
			self:UpdateBtnInfo()
			Event.Dispatch("UPDATE_FRIEND_INVITE",self.dwFriendID)
		end
    end)
end

function UIRecruitFriendPopView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIRecruitFriendPopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIRecruitFriendPopView:InitFriendBackInfo()
    self:UpdateFriendInfo()
    self:UpdateSentence()
end

function UIRecruitFriendPopView:UpdateFriendInfo()
    local tFriendInfo = self.tFriendInfo
    UIHelper.SetSpriteFrame(self.ImgSchool, PlayerForceID2SchoolImg[tFriendInfo.dwForceID])
    UIHelper.SetString(self.LabelPlayerName, UIHelper.GBKToUTF8(tFriendInfo.szName))
end

function UIRecruitFriendPopView:UpdateSentence()
    local tFriendInfo = self.tFriendInfo
    local tTime = TimeToDate(tFriendInfo.nCreateTime)
    local szTime1 = tTime.year .. "." .. tTime.month .. "." ..tTime.day
    local tLastTime = TimeToDate(tFriendInfo.nLastSaveTime)
	local nYearDiff = tLastTime.year - tTime.year
	local nMonthDiff = tLastTime.month - tTime.month
	local nDiffTime = tFriendInfo.nLastSaveTime - tFriendInfo.nCreateTime
	local nDay = math.floor(nDiffTime / 3600 / 24)
	local nLeaveDay = math.floor((GetCurrentTime() - tFriendInfo.nLastSaveTime) / 3600 / 24)
	local szTime2 = ""
	local szTypeInfo = ""
	local szHeOrShe = ""
	local tList = {}

    if nYearDiff > 0 then
		if nMonthDiff > 0 then
			szTime2 = FormatString(g_tStrings.STR_YEAR_MONTH, nYearDiff, nMonthDiff)
		elseif nMonthDiff == 0 then
			szTime2 = nYearDiff .. g_tStrings.STR_YEAR
		else
			nMonthDiff = 12 - tTime.month + tLastTime.month
			nYearDiff = nYearDiff - 1
			szTime2 = FormatString(g_tStrings.STR_YEAR_MONTH, nYearDiff, nMonthDiff)
		end
	elseif nYearDiff == 0 then
		if nMonthDiff > 0 then
			szTime2 = nMonthDiff .. g_tStrings.STR_MONTH
		else
			szTime2 = nDay .. g_tStrings.STR_BUFF_H_TIME_D_SHORT
		end
	end

	if tFriendInfo.nLevel >= g_pClientPlayer.nMaxLevel then
		if nDay >= 90 then
			szTypeInfo = g_tStrings.tFirstListThreePre[1] .. g_tStrings.tFirstListThreeLast1[math.random(1,2)]
		else
			szTypeInfo = g_tStrings.tFirstListThreePre[2] .. g_tStrings.tFirstListThreeLast2[math.random(1,2)]
		end
	else
		if nDay >= 90 then
			szTypeInfo = g_tStrings.tFirstListThreePre[3] .. g_tStrings.tFirstListThreeLast3[math.random(1,2)]
		else
			szTypeInfo = g_tStrings.tFirstListThreePre[4] .. g_tStrings.tFirstListThreeLast4[math.random(1,2)]
		end
	end

	if tFriendInfo.nType == ROLE_TYPE.STRONG_MALE or tFriendInfo.nType == ROLE_TYPE.STANDARD_MALE or tFriendInfo.nType == ROLE_TYPE.LITTLE_BOY then
		szHeOrShe = g_tStrings.STR_HE
	else
		szHeOrShe = g_tStrings.STR_SHE
	end

	local nFriendLevel = tFriendInfo.nAttractionLevel
	if nFriendLevel == 0 then
		nFriendLevel = 1
	end

	local szFirstSentence1 = g_tStrings.tFirstListOne[math.random(1,3)]
	local szFirstSentence3 = g_tStrings.tFirstListTwo[math.random(1,5)]
	local szFirstSentence6 = g_tStrings.tFirstListFour[math.random(1,3)]

	local szFSentence1 = FormatString(g_tStrings.STR_FRIEND_INVITE_INFO[1], szTime1, szFirstSentence1)
	table.insert(tList, szFSentence1)
	local szFSentence2 = FormatString(g_tStrings.STR_FRIEND_INVITE_INFO[2], szTime2)
	table.insert(tList, szFSentence2)
	local szFSentence3 = FormatString(g_tStrings.STR_FRIEND_INVITE_INFO[3], szFirstSentence3)
	table.insert(tList, szFSentence3)
	local szFSentence4 = FormatString(g_tStrings.STR_FRIEND_INVITE_INFO[4], g_tStrings.tFirstListCamp[tFriendInfo.nCamp])
	table.insert(tList, szFSentence4)
	local szFSentence5 = FormatString(g_tStrings.STR_FRIEND_INVITE_INFO[5], szTypeInfo)
	table.insert(tList, szFSentence5)
	local szFSentence6 = FormatString(g_tStrings.STR_FRIEND_INVITE_INFO[6], szFirstSentence6, nLeaveDay)
	table.insert(tList, szFSentence6)
	local szFSentence7 = FormatString(g_tStrings.STR_FRIEND_INVITE_INFO[7], g_tStrings.tAttractionLevel[nFriendLevel])
	table.insert(tList, szFSentence7)
	local szFSentence8 = FormatString(g_tStrings.STR_FRIEND_INVITE_INFO[8], szHeOrShe)
	table.insert(tList, szFSentence8)
	local szFSentence9 = FormatString(g_tStrings.STR_FRIEND_INVITE_INFO[9], szHeOrShe)
	table.insert(tList, szFSentence9)

	self.szContent = "" .. FormatString(g_tStrings.STR_FRIEND_INVITE_PART, szTime1, szFirstSentence1, szTime2, szFirstSentence3, g_tStrings.tFirstListCamp[tFriendInfo.nCamp], szTypeInfo, szFirstSentence6, nLeaveDay)

    local szContent = ""
    for k,v in ipairs(tList) do
        szContent = szContent .. v
    end
    UIHelper.SetRichText(self.RichTextPlayerStory, szContent)
end


function UIRecruitFriendPopView:UpdateBtnInfo()
	UIHelper.SetString(self.LabelSend,g_tStrings.STR_SENDING)
	UIHelper.SetButtonState(self.BtnSend,BTN_STATE.Disable)

	Timer.Add(self,2,function ()
		UIHelper.SetString(self.LabelSend,g_tStrings.STR_SENDMAIL_SUCESS)
		UIHelper.SetButtonState(self.BtnSend,BTN_STATE.Normal)
		OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_SENDMAIL_SUCESSED)
		UIMgr.Close(self)
	end)
end

return UIRecruitFriendPopView