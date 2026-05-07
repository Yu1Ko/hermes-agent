-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIRaidView
-- Date: 2022-11-22 16:26:34
-- Desc: ?
-- ---------------------------------------------------------------------------------

local MAX_RAID_GROUP_COUNT = 5
local MAX_RAID_GROUP_MEMBER_COUNT = 5

local LOOT_MODE_STR = {
    [1] = "自由拾取",
    [2] = "分配者分配",
    [3] = "队伍拾取",
    [4] = "拍团分配",
}

local ROLL_QUALITY_STR = {
    [1] = "白色",
    [2] = "绿色",
    [3] = "蓝色",
    [4] = "紫色",
    [5] = "橙色",
}

local UIRaidView = class("UIRaidView")

function UIRaidView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbRaidCells = {}

    for nGroup = 0, MAX_RAID_GROUP_COUNT-1 do
        local widgetTeamSortName = "WidgetTeamSort"
        if nGroup ~= 0 then
            widgetTeamSortName = widgetTeamSortName .. nGroup
        end
        self.tbRaidCells[nGroup] = {}
        local widgetTeamSort = self.WidgetAnchorRight:getChildByName(widgetTeamSortName)
        for nIndex = 0, MAX_RAID_GROUP_MEMBER_COUNT-1 do
            local imgMemberMessageName = "ImgMemberMassage"
            if nIndex ~= 0 then
                imgMemberMessageName = imgMemberMessageName .. nIndex
            end
            local imgMemberMessage = widgetTeamSort:getChildByName(imgMemberMessageName)
            imgMemberMessage:removeAllChildren()
            local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetMemberMassage, imgMemberMessage)
            cell:OnEnter(false, nGroup, nIndex)
            self.tbRaidCells[nGroup][nIndex] = cell
        end
    end

    self.bStateMove = false
    self.bStateMark = false
    self.movingCell = nil

    local scriptChat = UIHelper.GetBindScript(self.BtnChat)
    if scriptChat then
        scriptChat:OnEnter(UI_Chat_Channel.Team)
    end
    self:UpdateInfo()

    Timer.AddCycle(self, 5.0, function ()
		self:UpdateDistanceInfo()
	end)
end

function UIRaidView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
    UIMgr.Close(VIEW_ID.PanelTeamSetUp)
end

function UIRaidView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSetUp, EventType.OnClick, function (btn)
        UIMgr.Open(VIEW_ID.PanelTeamSetUp)
    end)

    UIHelper.BindUIEvent(self.BtnDistributionRecord, EventType.OnClick, function (btn)
        if GetClientTeam().nLootMode ~= PARTY_LOOT_MODE.BIDDING then
            TipsHelper.ShowImportantYellowTip(g_tStrings.GOLD_TEAM_CAN_ONLY_OPEN_IN_BIDDING_MODE)
            return
        end
        UIMgr.Open(VIEW_ID.PanelAuctionRecord)
    end)

    UIHelper.BindUIEvent(self.BtnReturn, EventType.OnClick, function (btn)
        TeamData.RequestLeaveTeam()
    end)

    UIHelper.BindUIEvent(self.tbBtnUnder[1], EventType.OnClick, function (btn)
        local tbBtnCfg = self:GetUnderButtonConfig()
        if not tbBtnCfg[1] then
            return
        end
        tbBtnCfg[1].fnAction()
    end)

    UIHelper.BindUIEvent(self.tbBtnUnder[2], EventType.OnClick, function (btn)
        local tbBtnCfg = self:GetUnderButtonConfig()
        if not tbBtnCfg[2] then
            return
        end
        tbBtnCfg[2].fnAction()
    end)

    UIHelper.BindUIEvent(self.tbBtnUnder[3], EventType.OnClick, function (btn)
        local tbBtnCfg = self:GetUnderButtonConfig()
        if not tbBtnCfg[3] then
            return
        end
        tbBtnCfg[3].fnAction()
    end)

    UIHelper.BindUIEvent(self.TogVoice, EventType.OnSelectChanged, function(btn, bSelected)
        if bSelected then
            UIHelper.SetSelected(self.TogMicSpeaker, GVoiceMgr.IsOpenSpeakerAndMic())
            UIHelper.SetSelected(self.TogSpeaker, GVoiceMgr.IsOpenSpeakerCloseMic())
            UIHelper.SetSelected(self.TogClose, GVoiceMgr.IsCloseSpeakerAndMic())
        end
    end)

    UIHelper.BindUIEvent(self.TogMicSpeaker, EventType.OnSelectChanged, function(btn, bSelected)
        if bSelected then
            GVoiceMgr.OpenSpeakerAndMic()
            self:UpdateMic()
        end
    end)

    UIHelper.BindUIEvent(self.TogSpeaker, EventType.OnSelectChanged, function(btn, bSelected)
        if bSelected then
            GVoiceMgr.OpenSpeakerCloseMic()
            self:UpdateMic()
        end
    end)

    UIHelper.BindUIEvent(self.TogClose, EventType.OnSelectChanged, function(btn, bSelected)
        if bSelected then
            GVoiceMgr.CloseSpeakerAndMic()
            self:UpdateMic()
        end
    end)

    UIHelper.BindUIEvent(self.BtnInviteRoom, EventType.OnClick, function()
        UIHelper.ShowConfirm(g_tStrings.STR_ROOM_SYNC_TEAMMATE_JOIN_ROOM, function()
            GetGlobalRoomClient().InviteTeamMemberJoinGlobalRoom()
        end)
    end)
end

function UIRaidView:RegEvent()
    Event.Reg(self, "PARTY_UPDATE_BASE_INFO", function ()
        self:UpdateInfo()
    end)

    Event.Reg(self, "PARTY_UPDATE_MEMBER_INFO", function (_, dwMemberID)
        self:enumRaidCells(function (cell)
            if cell.dwID == dwMemberID then
                cell:UpdateInfo(true)
                return false
            end
            return true
        end)
    end)

    Event.Reg(self, "PARTY_ADD_MEMBER", function (_, dwMemberID, nGroupIndex)
        local tbGroupInfo = TeamData.GetGroupInfo(nGroupIndex)
        self:UpdateGroupInfo(tbGroupInfo, nGroupIndex)
    end)

    Event.Reg(self, "PARTY_SYNC_MEMBER_DATA", function (_, _, nGroupIndex)
        local tbGroupInfo = TeamData.GetGroupInfo(nGroupIndex)
        self:UpdateGroupInfo(tbGroupInfo, nGroupIndex)
    end)

    Event.Reg(self, "PARTY_DELETE_MEMBER", function (_, dwMemberID, _, nGroupIndex)
        local hPlayer = GetClientPlayer()
		if hPlayer.dwID == dwMemberID then
            UIMgr.Close(VIEW_ID.PanelTeamSetUp)
            self:UpdateInfo()
			return
		end
        local tbGroupInfo = TeamData.GetGroupInfo(nGroupIndex)
        self:UpdateGroupInfo(tbGroupInfo, nGroupIndex)
    end)

    Event.Reg(self, "PARTY_DISBAND", function ()
        UIMgr.Close(VIEW_ID.PanelTeamSetUp)
        self:UpdateInfo()
    end)

    Event.Reg(self, "TEAM_AUTHORITY_CHANGED", function (nAuthorityType, dwTeamID, dwOldAuthorityID, dwNewAuthorityID)
        self:UpdateAuthorityInfo()

        self:enumRaidCells(function (cell)
            cell:UpdateInfo(true)
            return true
        end)
    end)

    Event.Reg(self, "PARTY_LOOT_MODE_CHANGED", function ()
        self:UpdateLootInfo()
	end)

    Event.Reg(self, "PARTY_ROLL_QUALITY_CHANGED", function ()
        self:UpdateLootInfo()
    end)

    Event.Reg(self, "TEAM_CHANGE_MEMBER_GROUP", function ()
        local hTeam = GetClientTeam()
        self:UpdateGroupInfo(TeamData.GetGroupInfo(arg1, hTeam), arg1)
        self:UpdateGroupInfo(TeamData.GetGroupInfo(arg2, hTeam), arg2)
    end)

    Event.Reg(self, "PARTY_SET_FORMATION_LEADER", function (dwFormationLeader)
        local hTeam = GetClientTeam()
	    local nGroup = hTeam.GetMemberGroupIndex(dwFormationLeader)
        self:UpdateGroupInfo(TeamData.GetGroupInfo(nGroup, hTeam), nGroup)
    end)

    Event.Reg(self, "PARTY_SET_MEMBER_ONLINE_FLAG", function ()
        self:enumRaidCells(function(cell)
            if cell.dwID == arg1 then
                cell:UpdateInfo(true)
                return false
            end
            return true
        end)
    end)

    Event.Reg(self, "PARTY_UPDATE_MEMBER_POSITION", function()
        self:enumRaidCells(function(cell)
            if cell.dwID == arg1 then
                cell:UpdatePositionInfo()
                return false
            end
            return true
        end)
    end)

    Event.Reg(self, "PARTY_UPDATE_MEMBER_LMR", function (_, dwMemberID)
        self:enumRaidCells(function(cell)
            if cell.dwID == arg1 then
                cell:UpdateLMRInfo()
                return false
            end
            return true
        end)
    end)

    Event.Reg(self, EventType.OnRaidCellTouchMoved, function (dwMemberID, nX, nY)
        if not self.bStateMove then
            return
        end
        if not self.movingCell then
            self.movingCell = UIHelper.AddPrefab(PREFAB_ID.WidgetMemberMassage, self.WidgetAnchorRight)
            self.movingCell:OnEnter(true, -1, -1)
            self.movingCell:SetID(dwMemberID, RAID_READY_CONFIRM_STATE.Init)
            UIHelper.SetAnchorPoint(self.movingCell._rootNode, 0.5, 0.5)
        end

        local nLocalX, nLocalY = UIHelper.ConvertToNodeSpace(self.WidgetAnchorRight, nX, nY)
        UIHelper.SetPosition(self.movingCell._rootNode, nLocalX, nLocalY, self.WidgetAnchorRight)

        local dstCell = self:CheckMovingCellPos()
        if dstCell then
            Event.Dispatch(EventType.OnRaidCellToggleSelectedByPos, dstCell.nGroup, dstCell.nIndex)
        end
    end)

    Event.Reg(self, EventType.OnRaidCellTouchEnded, function ()
        if self.movingCell then
            local dstCell = self:CheckMovingCellPos()
            if dstCell then
                local hTeam = GetClientTeam()
                local nSrcGroup = hTeam.GetMemberGroupIndex(self.movingCell.dwID)
                if nSrcGroup == dstCell.nGroup then
                    OutputMessage("MSG_SYS", g_tStrings.STR_MSG_CHANGE_PARTY_MEMBER_OTHER_GROUP)
                else
                    if dstCell.dwID ~= 0 then
                        hTeam.ChangeMemberGroup(self.movingCell.dwID, dstCell.nGroup, dstCell.dwID)
                    else
                        hTeam.ChangeMemberGroup(self.movingCell.dwID, dstCell.nGroup)
                    end
                end
            end

            self.movingCell._rootNode:removeFromParent(true)
            self.movingCell = nil

            Event.Dispatch(EventType.OnRaidCellToggleSelectedByPos, -1, -1)
        end
    end)

    Event.Reg(self, EventType.OnRaidCellTouchCanceled, function ()
        if self.movingCell then
            self.movingCell._rootNode:removeFromParent(true)
            self.movingCell = nil

            Event.Dispatch(EventType.OnRaidCellToggleSelectedByPos, -1, -1)
        end
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function ()
        self:ClearSelect()
    end)

    Event.Reg(self, "GLOBAL_ROOM_NOTIFY", function()
        self:UpdateRoomButton()
    end)

    Event.Reg(self, "GLOBAL_ROOM_BASE_INFO", function()
        self:UpdateRoomButton()
    end)

    Event.Reg(self, "GLOBAL_ROOM_DETAIL_INFO", function()
        self:UpdateRoomButton()
    end)

    Event.Reg(self, EventType.OnViewOpen, function(nViewID)
        if nViewID == VIEW_ID.PanelTeamSetUp then
            UIHelper.PlayAni(self, self.AniAll, "AniBottomHide")
        end
    end)

    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        if nViewID == VIEW_ID.PanelTeamSetUp then
            UIHelper.PlayAni(self, self.AniAll, "AniBottomShow")
        end
    end)

    Event.Reg(self, EventType.UpdateStartReadyConfirm, function()
        self:UpdateAuthorityInfo()
    end)

    Event.Reg(self, "FIGHT_HINT", function(bFight)
        self:UpdateAuthorityInfo()
    end)

end

function UIRaidView:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

-- function UIRaidView:SetVisible(bVisible)
--     if bVisible then
--         if not self.bInit then
--             self:OnEnter()
--         end
--     end
--     UIHelper.SetVisible(self._rootNode, bVisible)
-- end

function UIRaidView:UpdateInfo()
    self.bStateMove = false
    self.bStateMark = false
    if self.movingCell then
        self.movingCell._rootNode:removeFromParent(true)
        self.movingCell = nil
    end
    self.movingCell = nil
    self:ClearRaidInfo()

    local hPlayer = GetClientPlayer()
    if not hPlayer.IsInParty() then
        return
    end

    self:UpdateMic()
    self:UpdateRaidInfo()
    self:UpdateAuthorityInfo()
    self:UpdateLootInfo()
end

function UIRaidView:UpdateMic()
    UIHelper.SetSelected(self.TogVoice, false)

    if GVoiceMgr.IsOpenSpeakerAndMic() then
        UIHelper.SetSpriteFrame(self.ImgVoice, "UIAtlas2_Public_PublicButton_PublicButton1_img_voice")
        UIHelper.SetString(self.LableVoice, "开麦")
    elseif GVoiceMgr.IsOpenSpeakerCloseMic() then
        UIHelper.SetSpriteFrame(self.ImgVoice, "UIAtlas2_Public_PublicButton_PublicButton1_img_voice01")
        UIHelper.SetString(self.LableVoice, "收听")
    else
        UIHelper.SetSpriteFrame(self.ImgVoice, "UIAtlas2_Public_PublicButton_PublicButton1_img_voice_close")
        UIHelper.SetString(self.LableVoice, "拒听")
    end
end

function UIRaidView:UpdateRaidInfo()
    self:ClearRaidInfo()

    local hTeam = GetClientTeam()
	if hTeam.nGroupNum > 1 then
		for nGroupID = 0, hTeam.nGroupNum - 1 do
			local tbGroupInfo = TeamData.GetGroupInfo(nGroupID, hTeam)
			self:UpdateGroupInfo(tbGroupInfo, nGroupID)
		end
	else
		local hPlayer = GetClientPlayer()
		local nGroupID = hTeam.GetMemberGroupIndex(hPlayer.dwID)
		local tbGroupInfo = TeamData.GetGroupInfo(nGroupID)
		self:UpdateGroupInfo(tbGroupInfo, nGroupID)
	end
end

function UIRaidView:ClearRaidInfo()
    self:enumRaidCells(function (cell)
        cell:Clear()
        return true
    end)
end

function UIRaidView:UpdateGroupInfo(tbGroupInfo, nGroup)
    local nIndex = 0
    for _, dwMemberID in ipairs(tbGroupInfo.MemberList) do
        self.tbRaidCells[nGroup][nIndex]:SetID(dwMemberID)
        nIndex = nIndex + 1
    end
    for i = nIndex, MAX_RAID_GROUP_MEMBER_COUNT-1 do
        self.tbRaidCells[nGroup][i]:Clear()
    end
end

function UIRaidView:UpdateAuthorityInfo()
    UIHelper.SetVisible(self.BtnSetUp, true)
    self:UpdateRoomButton()

    local tbBtnCfg = self:GetUnderButtonConfig()
    for i, btn in ipairs(self.tbBtnUnder) do
        if tbBtnCfg[i] then
            UIHelper.SetString(self.tbLableUnder[i], tbBtnCfg[i].szName)
            UIHelper.SetVisible(btn, true)
            UIHelper.SetButtonState(btn, tbBtnCfg[i].bDisable and BTN_STATE.Disable or BTN_STATE.Normal)
        else
            UIHelper.SetVisible(btn, false)
        end
    end

    UIHelper.LayoutDoLayout(self.WidgetAnchorButton)
end

function UIRaidView:UpdateLootInfo()
    local hTeam = GetClientTeam()

    UIHelper.SetString(self.LabelColor, ROLL_QUALITY_STR[hTeam.nRollQuality])
    UIHelper.SetString(self.LabelType, LOOT_MODE_STR[hTeam.nLootMode])
end

function UIRaidView:CheckMovingCellPos()
    if not self.movingCell then
        return nil
    end

    local dstCell = nil
    local nMinDist = 2^30
    local nX, nY = UIHelper.GetPosition(self.movingCell._rootNode)
    local nW, nH = UIHelper.GetContentSize(self.movingCell._rootNode)
    nX = nX - 0.5 * nW
    nY = nY - 0.5 * nH
    local rect1 = cc.rect(nX, nY, nW, nH)
    self:enumRaidCells(function (cell)
        local nX2, nY2 = UIHelper.GetWorldPosition(cell._rootNode)
        nX2, nY2 = UIHelper.ConvertToNodeSpace(self.WidgetAnchorRight, nX2, nY2)
        local rect2 = cc.rect(nX2, nY2, rect1.width, rect1.height)
        if cc.rectIntersectsRect(rect1, rect2) then
            local nCurDist = math.sqrt(math.abs(rect1.x - rect2.x)^2+math.abs(rect1.y-rect2.y)^2)
            if nCurDist < nMinDist then
                nMinDist = nCurDist
                dstCell = cell
            end
        end
        return true
    end)
    return dstCell
end

function UIRaidView:GetUnderButtonConfig()
    local hTeam = GetClientTeam()
    local hPlayer = GetClientPlayer()

    local tbAllBtn = {
        {
            szName = "换位",
            fnCondition=function()
                return hTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER) == hPlayer.dwID and TeamData.IsInRaid(hTeam) and not self.bStateMove
            end,
            fnAction=function ()
                self.bStateMove = true
                self:UpdateAuthorityInfo()
                TipsHelper.OutputMessage("MSG_SYS", g_tStrings.STR_MSG_CHANGE_PARTY_MEMBER_OTHER_GROUP)
            end,
        },

        {
            szName = "确定",
            bInterrupt = true,
            fnCondition=function()
                return hTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER) == hPlayer.dwID and TeamData.IsInRaid(hTeam) and self.bStateMove
            end,
            fnAction=function ()
                self.bStateMove = false
                self:UpdateAuthorityInfo()
            end,
        },

        {
            szName = "转为团队",
            fnCondition=function()
                return hTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER) == hPlayer.dwID and not TeamData.IsInRaid(hTeam)
            end,
            fnAction=function()
                local fnConfirm = function()
                    GetClientTeam().LevelUpRaid()
                end
                UIHelper.ShowConfirm(g_tStrings.STR_MSG_RAID_CONFIRM, fnConfirm, nil, false)
            end,
        },

        {
            szName = "就位确认",
            fnCondition=function()
                return hTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER) == hPlayer.dwID and not TeamData.IsStartReadyConfirm()
            end,
            bDisable = hPlayer.bFightState,
            fnAction=function()
                local fnConfrim = function()
                   TeamData.StartReadyConfirm()
                end
                UIHelper.ShowConfirm(g_tStrings.STR_RAID_MSG_START_READY_CONFIRM, fnConfrim, nil, false)
            end,
        },

        {
            szName = "就位重置",
            fnCondition=function()
                return hTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER) == hPlayer.dwID and TeamData.IsStartReadyConfirm()
            end,
            fnAction=function()
               TeamData.ResetReadyConfirm()
            end,
        },

        -- {
        --     szName = "标记",
        --     fnCondition=function()
        --         return hTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK) == hPlayer.dwID and not self.bStateMark
        --     end,
        --     fnAction=function()
        --         self.bStateMark = true
        --         self:UpdateAuthorityInfo()
        --     end,
        -- },
    }

    local tbEffectBtn = {}
    for _, btn in ipairs(tbAllBtn)  do
        if btn.fnCondition and btn.fnCondition() then
            table.insert(tbEffectBtn, btn)
            if btn.bInterrupt then
                break
            end
        end
    end

    return tbEffectBtn
end

function UIRaidView:UpdateDistanceInfo()
    self:enumRaidCells(function(cell)
        if cell.dwID ~= 0 then
            cell:UpdateDistanceInfo()
        end
        return true
    end)
end

function UIRaidView:enumRaidCells(fnAction)
    for nGroup = 0, MAX_RAID_GROUP_COUNT-1 do
        if not self:enumGroupCells(nGroup, fnAction) then
            return false
        end
    end
    return true
end

function UIRaidView:enumGroupCells(nGroup, fnAction)
    for nIndex = 0, MAX_RAID_GROUP_MEMBER_COUNT-1 do
        if not fnAction(self.tbRaidCells[nGroup][nIndex]) then
            return false
        end
    end
    return true
end

function UIRaidView:ClearSelect()
    self:enumRaidCells(function (cell)
        UIHelper.SetSelected(cell.TogSelect, false, false)
        return true
    end)
    UIHelper.SetSelected(self.TogVoice, false)
end

function UIRaidView:UpdateRoomButton()
    UIHelper.SetVisible(self.BtnInviteRoom, TeamData.IsTeamLeader() and RoomData.IsHaveRoom())
    UIHelper.LayoutDoLayout(self.WidgetAnchorRightTop)
end

return UIRaidView
