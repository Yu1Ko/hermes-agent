-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSalaryPayPage
-- Date: 2023-02-14 20:15:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetSalaryPayPage = class("UIWidgetSalaryPayPage")

local VOTE_LIMIT_TIME = 30
function UIWidgetSalaryPayPage:OnEnter(tData)
    if not tData then
         return
    end
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    AuctionData.InitCheckAllMembers()
    self:UpdateInfo()
    Timer.AddCycle(self, 1, function ()
        self:OnFrameBreathe()
    end)
end

function UIWidgetSalaryPayPage:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIWidgetSalaryPayPage:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnPublishSolution, EventType.OnClick, function ()
        if not self:CheckSeletTeamers() then
            return
        end
        for dwGID, bCheck in pairs(AuctionData.tCheckTeamers) do
            if not AuctionData.tSubsidies[dwGID] then
                AuctionData.tSubsidies[dwGID] = {nMoney = 0}
            end
        end
        RemoteCallToServer("On_Team_SyncTeamersPay", AuctionData.SetCenterID(AuctionData.tSubsidies))
        if AuctionData.IsDistributeMan() then
            local player = GetClientPlayer()
            local aTextList = AuctionData.GetStatisticMsg_Pay()
            for k, tText in ipairs(aTextList) do
                Player_Talk(player, AuctionData.GetChannel(), "", tText)
            end
        end
        AuctionData.nPublishSolutionLeftTime = GetTickCount() + 30 * 1000
        self:UpdatePublishSolutionLeftTime()
    end)

    UIHelper.BindUIEvent(self.BtnPublishSalary, EventType.OnClick, function ()
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TRADE) then
            return
        end
        if not self:CheckSeletTeamers() then
            return
        end
        UIHelper.ShowConfirm(g_tStrings.PARTY_GOLD_TEAM_DISTRIBUTE_CONFIRM, function ()
            for dwGID, bCheck in pairs(AuctionData.tCheckTeamers) do
                if not AuctionData.tSubsidies[dwGID] then
                    AuctionData.tSubsidies[dwGID] = {nMoney = 0}
                end
            end
            local tSubsidies = AuctionData.SetCenterID(AuctionData.tSubsidies)
            LOG.TABLE({"On_Team_SendTeamMoney1", tSubsidies})
			RemoteCallToServer("On_Team_SendTeamMoney", tSubsidies)
        end)
    end)

    UIHelper.BindUIEvent(self.BtnAgree, EventType.OnClick, function ()
        local team = GetClientTeam()
        team.Vote(AuctionData.nVoteType, 1)
        AuctionData.dwDistributeStartTime = nil
        AuctionData.dwVoteStartTime = nil
        UIHelper.SetVisible(self.WidgetAnchorVote, false)
    end)

    UIHelper.BindUIEvent(self.BtnRefuse, EventType.OnClick, function ()
        local team = GetClientTeam()
        team.Vote(AuctionData.nVoteType, 0)
        AuctionData.dwDistributeStartTime = nil
        AuctionData.dwVoteStartTime = nil
        UIHelper.SetVisible(self.WidgetAnchorVote, false)
    end)

    UIHelper.BindUIEvent(self.TogMultiTotal, EventType.OnSelectChanged, function (_, bSelected)
        for _, scriptGroup in pairs(self.tScriptGroupList) do
            UIHelper.SetSelected(scriptGroup.TogMulti, bSelected, false)
            scriptGroup:SelelctAll(bSelected)
        end
    end)

    UIHelper.BindUIEvent(self.BtnHint, EventType.OnClick, function ()
        local szContent = "【发放收入】：必须有超过50%的成员同意，才能发放收入。\n"
        szContent = szContent .. "【发布记录】：点击后可以把收入分配信息同步给所有团员，以便团员了解最新收入信息。"
        TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips, self.BtnHint, szContent)
    end)
end

function UIWidgetSalaryPayPage:RegEvent()
    Event.Reg(self, EventType.OnWindowsSizeChanged, function ()
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewList)
    end)

    Event.Reg(self, EventType.OnSalaryDispatched, function ()
        self.bNeedRefresh = true
    end)

    Event.Reg(self, EventType.OnSalaryDataChanged, function ()
        self.bNeedRefresh = true
    end)

    Event.Reg(self, "PARTY_ADD_MEMBER", function ()
        self.bNeedRefresh = true
    end)

    Event.Reg(self, "PARTY_DISBAND", function ()
        self.bNeedRefresh = true
    end)

    Event.Reg(self, "PARTY_DELETE_MEMBER", function ()
        self.bNeedRefresh = true
    end)

    Event.Reg(self, "GLOBAL_ROOM_MEMBER_CHANGE", function ()
        self.bNeedRefresh = true
    end)

    Event.Reg(self, "TEAM_AUTHORITY_CHANGED", function (nAuthorityType)
        if nAuthorityType == TEAM_AUTHORITY_TYPE.DISTRIBUTE then
            local bSelfDistributer = AuctionData.IsDistributeMan()
            UIHelper.SetVisible(self.WidgetDistributerButtons, bSelfDistributer)
            --UIHelper.SetVisible(self.WidgetNormalButtons, not bSelfDistributer)
            UIHelper.SetVisible(self.TogMultiTotal, bSelfDistributer)
            self:OnFrameBreathe()
        end
    end)
end

function UIWidgetSalaryPayPage:UnRegEvent()

end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetSalaryPayPage:UpdateInfo()
    self.bNeedRefresh = false
	local team = GetClientTeam()
	local nGroupNum = AuctionData.GetTeamGroupNum()
    UIHelper.RemoveAllChildren(self.LayoutList)
    self.tScriptGroupList = {}
    local bSelectTotal = true
	for nGroupID = 0, nGroupNum - 1 do
        local tMemberInfoList = AuctionData.GetTeamGroupList(nGroupID)
        if tMemberInfoList and table.GetCount(tMemberInfoList) > 0 then
            local scriptGroup = UIHelper.AddPrefab(PREFAB_ID.WidgetSalaryPayTeamShell, self.ScrollViewList)
            scriptGroup:OnEnter(nGroupID)
            self.tScriptGroupList[nGroupID] = scriptGroup
            bSelectTotal = bSelectTotal and scriptGroup.bAllSelected
        end
	end
    UIHelper.SetSelected(self.TogMultiTotal, bSelectTotal, false)
    UIHelper.SetVisible(self.TogMultiTotal, AuctionData.IsDistributeMan())
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewList)

    local bSelfDistributer = AuctionData.IsDistributeMan()
    UIHelper.SetVisible(self.WidgetDistributerButtons, bSelfDistributer)
    --UIHelper.SetVisible(self.WidgetNormalButtons, not bSelfDistributer)
end

function UIWidgetSalaryPayPage:OnFrameBreathe()
    if self.bNeedRefresh then self:UpdateInfo() end
    
    self:UpdateSalaryPayLeftTime()
    self:UpdatePublishSolutionLeftTime()
    self:UpdateVoteLeftTime()
end

function UIWidgetSalaryPayPage:UpdateSalaryPayLeftTime()
    local bStartDistribute = AuctionData.dwDistributeStartTime and AuctionData.dwDistributeStartTime > 0
    UIHelper.SetVisible(self.WidgetNormalButtons, false)
    if not bStartDistribute then
        return
    end
    local nLeftTime = (AuctionData.dwDistributeStartTime + VOTE_LIMIT_TIME*1000 - GetTickCount()) / 1000
    if nLeftTime < 0 then
        AuctionData.dwDistributeStartTime = nil
        return
    end

    local szLeftTime = UIHelper.GetDeltaTimeText(nLeftTime)
    szLeftTime = string.format("发放收入中，剩余时间 %s", szLeftTime)
    UIHelper.SetString(self.LabelDispatchCountDown, szLeftTime)
end

function UIWidgetSalaryPayPage:UpdatePublishSolutionLeftTime()
    if not AuctionData.nPublishSolutionLeftTime then return end
    local nLeftTime = (AuctionData.nPublishSolutionLeftTime - GetTickCount()) / 1000
    local bEnable = nLeftTime < 0
    if bEnable then
        AuctionData.nPublishSolutionLeftTime = nil
        UIHelper.SetString(self.LabelPublishSolution, "发布记录")
        UIHelper.SetButtonState(self.BtnPublishSolution, BTN_STATE.Normal)
    else
        UIHelper.SetString(self.LabelPublishSolution, string.format("发布记录(%d)", nLeftTime))
        UIHelper.SetButtonState(self.BtnPublishSolution, BTN_STATE.Disable, "发布记录冷却中", true)
    end
end

function UIWidgetSalaryPayPage:UpdateVoteLeftTime()
    if not AuctionData.dwVoteStartTime then
		return
	end
    local dwCurrentTime = GetCurrentTime()
	local nLeft = dwCurrentTime - AuctionData.dwVoteStartTime
    nLeft = AuctionData.nVoteLeftTime - nLeft
    if nLeft < 0 then
        AuctionData.dwVoteStartTime = nil
    end
    UIHelper.SetString(self.LabelVoteLeftTime, nLeft)
    UIHelper.LayoutDoLayout(UIHelper.GetParent(self.LabelVoteLeftTime))
    UIHelper.SetVisible(self.WidgetAnchorVote, AuctionData.dwVoteStartTime ~= nil)
end

function UIWidgetSalaryPayPage:OnVote(tVoteInfo)
    AuctionData.dwVoteStartTime = GetCurrentTime()
    AuctionData.nVoteType = tVoteInfo.nVoteType
    AuctionData.nVoteLeftTime = tVoteInfo.nLeftTime
    UIHelper.SetVisible(self.WidgetAnchorVote, AuctionData.dwVoteStartTime ~= nil)
    self:UpdateVoteLeftTime()
end

function UIWidgetSalaryPayPage:CheckSeletTeamers()
	local nSelect = GetTableCount(AuctionData.tCheckTeamers)
	local team = GetClientTeam()
	local nSum = team.GetTeamSize()
	if nSelect > nSum * 0.6 then
		return true
	else
		OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.GOLD_PAY_SYNC)
		return false
	end
end

return UIWidgetSalaryPayPage