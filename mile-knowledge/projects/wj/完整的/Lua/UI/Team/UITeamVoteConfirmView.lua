-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITeamVoteConfirmView
-- Date: 2024-04-20 09:53:57
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UITeamVoteConfirmView = class("UITeamVoteConfirmView")

function UITeamVoteConfirmView:OnEnter(nVoteType, nLeftTime, dwPlayerId, szGlobalID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nVoteType = nVoteType
    self.nLeftTime = nLeftTime
    self.dwPlayerId = dwPlayerId
    self.szGlobalID = szGlobalID
    self.dwStartTime = GetCurrentTime()
    self:UpdateInfo()
    Timer.AddCycle(self, 0.3, function()
        self:UpdateTime()
    end)
end

function UITeamVoteConfirmView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITeamVoteConfirmView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCalloff, EventType.OnClick, function()
        local hTeam = GetClientTeam()
        hTeam.Vote(self.nVoteType, 0)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnOk, EventType.OnClick, function()
        local hTeam = GetClientTeam()
        hTeam.Vote(self.nVoteType, 1)
        UIMgr.Close(self)
    end)
end

function UITeamVoteConfirmView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITeamVoteConfirmView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITeamVoteConfirmView:UpdateInfo()
    if self.nVoteType == 0 then
		local hTeam = GetClientTeam()
		local tMemberInfo = hTeam.GetMemberInfo(self.dwPlayerId)
		local szName = UIHelper.GBKToUTF8(tMemberInfo.szName)
		local sztip = FormatString(g_tStrings.GOLD_TEAM_DELETE_MEMBER_VOTE, szName)
		UIHelper.SetString(self.LabelHintNormal, sztip)
	elseif self.nVoteType == 1 then
		UIHelper.SetString(self.LabelHintNormal, g_tStrings.GOLD_TEAM_SEND_MONEY_VOTE)
	elseif self.nVoteType == 2 then
		local tMemberInfo = RoomData.GetRoomMemberInfo(self.szGlobalID)
		local szName = UIHelper.GBKToUTF8(RoomData.GetGlobalName(tMemberInfo.szName, tMemberInfo.dwCenterID))
		local sztip = FormatString(g_tStrings.GOLD_TEAM_DELETE_ROOM_MEMBER_VOTE, szName)
		UIHelper.SetString(self.LabelHintNormal, sztip)
	elseif self.nVoteType == 3 then
		UIHelper.SetString(self.LabelHintNormal, g_tStrings.GOLD_TEAM_SEND_ROOM_MONEY_VOTE)
	end
    UIHelper.LayoutDoLayout(self.LayoutHintNormal)
    self:UpdateTime()
end

function UITeamVoteConfirmView:UpdateTime()
    if not self.dwStartTime then
		return
	end
    local dwCurrentTime = GetCurrentTime()
	local nLeft = dwCurrentTime - self.dwStartTime
    nLeft = self.nLeftTime - nLeft
    if nLeft < 0 then
        UIMgr.Close(self)
        return
    end
    UIHelper.SetString(self.LabelCountDownTime, nLeft)
    UIHelper.LayoutDoLayout(self.LayoutCountDown)
end


return UITeamVoteConfirmView