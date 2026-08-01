-- ---------------------------------------------------------------------------------
-- Author: liu yu min
-- Name: ServiceReportInfo
-- Date: 2023-07-25 11:36:33
-- Desc: 举报不良信息
-- ---------------------------------------------------------------------------------

local ServiceReportInfo = class("ServiceReportInfo")
local ToggleType =
{
    MaiJin = 6,
    ShuaPing = 2,
    MaRen = 4,
    DaiDa = 1,
    Hong = 3,
	QiPian = 5,
	DuBo = 8,
	Other = 7
}
function ServiceReportInfo:OnEnter()
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end
	self:UpdateInfo()
end

function ServiceReportInfo:OnExit()
	self.bInit = false
	self:UnRegEvent()
end

function ServiceReportInfo:BindUIEvent()

	for i, v in ipairs(self.tbToggleType) do
        UIHelper.BindUIEvent(v , EventType.OnClick , function ()
            UIHelper.SetSelected(self.tbToggleType[self.nCurSelectType] , false)
            self.nCurSelectType = i
            UIHelper.SetSelected(self.tbToggleType[self.nCurSelectType] , true)
        end)
    end

	UIHelper.BindUIEvent(self.BtnConfirm , EventType.OnClick , function ()
        self:OnSubmit()
    end)

	UIHelper.BindUIEvent(self.BtnClose , EventType.OnClick , function ()
        UIMgr.Close(self)
    end)

	UIHelper.BindUIEvent(self.BtnCancel , EventType.OnClick , function ()
        UIMgr.Close(self)
    end)
end

function ServiceReportInfo:RegEvent()
	--Event.Reg(self, EventType.XXX, func)
end

function ServiceReportInfo:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function ServiceReportInfo:UpdateInfo()
	self.nCurSelectType = 1
	UIHelper.SetSelected(self.tbToggleType[self.nCurSelectType] , true)
	UIHelper.ScrollViewDoLayoutAndToTop(self.ScollViewReportContent)
	UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
	UIHelper.SetScrollViewCombinedBatchEnabled(self.ScollViewReportContent, false)
	UIHelper.SetNodeSwallowTouches(self.ScrollViewContent, true, false)
end

function ServiceReportInfo:GetMsgTime(nTime)
	if not nTime or nTime <= 0 then
		return ""
	end

	local tTime = TimeToDate(nTime)
	local szHour = tTime and string.format("%02d", tTime.hour) or ""
	local szMinute = tTime and string.format("%02d", tTime.minute) or ""
	local szSecond = tTime and string.format("%02d", tTime.second) or ""
	-- local szText = tTime and FormatString(g_tStrings.STR_TIME_16, tTime.year, tTime.month, tTime.day, szHour, szMinute) or ""
	-- szText = FormatString(g_tStrings.CYCLOPAEDIA_LINK_FORMAT, szText)
	local szText = tTime and string.format("[%d/%02d/%02d][%s:%s:%s]", tTime.year, tTime.month, tTime.day, szHour, szMinute, szSecond) or ""

	return szText
end

function ServiceReportInfo:UpdateReportInfo(szRoleName, szContent, dwTalkerID, nChatID, szAccountID, dwGlobalID, nMsgTime)
	if szAccountID and szAccountID ~= "" then
		szRoleName = szRoleName .. '(' .. szAccountID .. ')'
	end
	szContent = string.format("%s%s", self:GetMsgTime(nMsgTime), szContent)
	UIHelper.SetString(self.LabelContent, szContent)
	UIHelper.SetString(self.LaberReportName  , szRoleName)
	self.tbReportInfo = {}
	self.tbReportInfo.bCanSubmit = true
	self.tbReportInfo.dwTalkerID = dwTalkerID
	self.tbReportInfo.nChatID = nChatID
	self.tbReportInfo.dwGlobalID = dwGlobalID
	self.szRoleName = szRoleName
	self.szContent = szContent
	UIHelper.ScrollViewDoLayoutAndToTop(self.ScollViewReportContent)
	UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
end

function ServiceReportInfo:OnSubmit()
	local szRoleName = self.szRoleName
	local szContent = self.szContent
	local szType = g_tStrings.tReportType[self.nCurSelectType]
	local confirmView
	if szType == "" then
		confirmView = UIHelper.ShowConfirm(g_tStrings.REPORT_SELECT_TYPE)
	else
		szContent = "(" .. szType .. ")" .. szContent
		local szPlatform = "vkWin"
		local szCustom = self:GetReportCustomMessage()
		if Platform.IsAndroid() then
			szPlatform = "Android"
		elseif Platform.IsIos() then
			szPlatform = "Ios"
		end
		RemoteCallToServer("OnReportTrick", UIHelper.UTF8ToGBK(szRoleName), UIHelper.UTF8ToGBK(szContent), UIHelper.UTF8ToGBK(szCustom), self.tbReportInfo.dwGlobalID, szPlatform)
		confirmView = UIHelper.ShowConfirm(self:GetReportTipMessage() ,function ()
			TipsHelper.ShowNormalTip("举报成功")
		end)
		UIMgr.Close(self)

		if self.tbReportInfo.dwTalkerID and IsSpamID(self.tbReportInfo.dwTalkerID) then
            ReportSpamID(self.tbReportInfo.dwTalkerID)
			OutputMessage("MSG_SYS", g_tStrings.REPORT_SUCCESS)
        end
	end
end

function ServiceReportInfo:GetReportCustomMessage()
	local szComment = "ChatPanel"
	-- if self.nCurSelectType == REPORT_FROM_WHERE.TEAM_BUILDING then
	-- 	local tInfo = GetTeamPushInfoSingle(self.tbReportInfo.dwTalkerID)
	-- 	if tInfo then
	-- 		szComment = tInfo.dwPushID
	-- 	end
	-- elseif self.nCurSelectType == REPORT_FROM_WHERE.MENTOR_PANEL_FIND_MENTOR then
	-- 	szComment = false
	-- elseif self.nCurSelectType == REPORT_FROM_WHERE.MENTOR_PANEL_FIND_APPRENTICE then
	-- 	szComment = true
	-- end
	-- szComment = tostring(szComment)

	return szComment
end

function ServiceReportInfo:GetReportTipMessage()
	local szMsg = g_tStrings.REPORT_INFO_NOT_FORBID
	if self.tbReportInfo.dwTalkerID and IsSpamID(self.tbReportInfo.dwTalkerID) then
		szMsg = g_tStrings.REPORT_INFO
	end
	return szMsg
end

return ServiceReportInfo