-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITeamMainCityMemberListView
-- Date: 2022-11-21 15:26:46
-- Desc: ?
-- Prefab: WidgetTaskTeam -> LayoutTeamOperations
-- ---------------------------------------------------------------------------------

local UITeamMainCityMemberListView = class("UITeamMainCityMemberListView")

function UITeamMainCityMemberListView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.bInSetState = false
    self.tbMemberCells = {}
    self.tbEmptyCells = {}

    if self:CheckUpdatePartyMode() then
        self:UpdateInfo(true)
    end

    Timer.AddCycle(self, 0.1, function()
        if self:CheckUpdatePartyMode() then
            self:UpdateMicSetting()
            self:UpdateMemberBuff()
        end
    end)
end

function UITeamMainCityMemberListView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITeamMainCityMemberListView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnTeamRecruit, EventType.OnClick, function ()
        Event.Dispatch(EventType.OnTeachButtonClick, VIEW_ID.PanelMainCity, UIHelper.GetName(self.BtnTeamRecruit))
        UIMgr.Open(VIEW_ID.PanelTeam)
    end)

    UIHelper.BindUIEvent(self.BtnExitTeam, EventType.OnClick, function()
        TeamData.RequestLeaveTeam()
    end)

    UIHelper.BindUIEvent(self.TogVoice, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetVoiceTips, self.TogVoice)
    end)

    UIHelper.BindUIEvent(self.BtnSwitchRoom, EventType.OnClick, function()
        RoomData.SetMainCityRoom(true)
    end)

    UIHelper.BindUIEvent(self.BtnCallTeam, EventType.OnClick, function()
        TeamData.EnvokeAllTeammates()
    end)

    UIHelper.BindUIEvent(self.BtnMore, EventType.OnClick, function()
        local hPlayer = GetClientPlayer()
        if not hPlayer then
            return
        end
        local hTeam = GetClientTeam()
        local bDistribute = hTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE) == hPlayer.dwID
        local hTeam = GetClientTeam()

        local readyConfirmBtn
        if not TeamData.IsStartReadyConfirm() then
            readyConfirmBtn = {
                szName = "就位确认",
                bDisabled = not TeamData.IsTeamLeader() or hPlayer.bFightState,
                OnClick = function()
                    local fnConfrim = function()
                        TeamData.StartReadyConfirm()
                    end
                    UIHelper.ShowConfirm(g_tStrings.STR_RAID_MSG_START_READY_CONFIRM, fnConfrim, nil, false)
                    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
                end
            }
        else
            readyConfirmBtn = {
                szName = "就位重置",
                bDisabled = not TeamData.IsTeamLeader(),
                OnClick = function()
                    TeamData.ResetReadyConfirm()
                    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
                end
            }
        end

        local tbBtnInfo = {{
            szName = "退出队伍",
            bDisabled = hTeam.bSystem,
            OnClick = function()
                TeamData.RequestLeaveTeam()
                TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
            end
        }, {
            szName = "分配模式",
            bDisabled = not bDistribute,
            OnClick = function()
                UIMgr.Open(VIEW_ID.PanelTeamSetUp)
                TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
            end
        }, {
            szName = "分配记录",
            bDisabled = false,
            OnClick = function()
                if GetClientTeam().nLootMode ~= PARTY_LOOT_MODE.BIDDING then
                    TipsHelper.ShowImportantYellowTip(g_tStrings.GOLD_TEAM_CAN_ONLY_OPEN_IN_BIDDING_MODE)
                    return
                end
                UIMgr.Open(VIEW_ID.PanelAuctionRecord)
                TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
            end
        }, {
            szName = "击伤进度",
            bDisabled = false,
            OnClick = function()
                local scene = hPlayer.GetScene()
                if not scene then return end
                local _, _, _, _, _, _, _, bDungeonRoleProgressMap = GetMapParams(scene.dwMapID)
                if not bDungeonRoleProgressMap then
                    TipsHelper.ShowImportantYellowTip("当前场景没有击伤进度")
                    return
                end
                UIMgr.Open(VIEW_ID.PanelBossKillProgressPop)
                TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
            end
        }, {
            szName = "权限管理",
            bDisabled = not TeamData.IsTeamLeader(),
            OnClick = function()
               UIMgr.Open(VIEW_ID.PanelTeam)
               TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
            end
        }, readyConfirmBtn, {
            szName = "招募信息",
            bDisabled = IsRemotePlayer(UI_GetClientPlayerID()),
            OnClick = function()
                TeamData.RequestRecruitInfo()
            end
        }}

        if TeamData.IsInRaid() and TeamData.IsTeamLeader() then
            table.insert(tbBtnInfo, {
                szName = g_tStrings.STR_RAID_COUNTDOWN,
                OnClick = function()
                    UIMgr.Open(VIEW_ID.PanelCountDownSetting, Storage.Team.nRaidCountDown, function(nCountDown)
                        TeamData.StartRaidCountDown(nCountDown)
                    end)
                end,
            })
        end

        if TeamData.IsInRaid() then
            table.insert(tbBtnInfo, {
                szName = g_tStrings.STR_TEAM_NOTICE,
                OnClick = function()
                    if TeamData.IsTeamLeader() then
                        UIMgr.Open(VIEW_ID.PanelTeamNoticeEditPop, false)
                    else
                        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TALK, "player talk") then
                            return
                        end

                        SendBgMsg(PLAYER_TALK_CHANNEL.RAID, "RAID_NOTICE_APPLY", UI_GetClientPlayerGlobalID())
                        TipsHelper.ShowNormalTip(g_tStrings.STR_TEAM_NOTICE_APPLY)
                    end
                    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
                end
            })
        end

        local nX,nY = UIHelper.GetWorldPosition(self.BtnMore)
		local nSizeW,nSizeH = UIHelper.GetContentSize(self.BtnMore)
        local _, scriptTips = TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetTipMoreOper,nX,nY+nSizeH-60*(#tbBtnInfo-3))
        scriptTips:OnEnter(tbBtnInfo)
    end)
end

function UITeamMainCityMemberListView:RegEvent()
    Event.Reg(self, "LOADING_END", function ()
        if not self:CheckUpdatePartyMode() then
            return
        end
        self:UpdateInfo(true)
    end)

    Event.Reg(self, "SYNC_ROLE_DATA_END", function ()
        if not self:CheckUpdatePartyMode() then
            return
        end
        self:UpdateInfo(true)
    end)

    Event.Reg(self, "PARTY_UPDATE_BASE_INFO", function ()
        if not self:CheckUpdatePartyMode() then
            return
        end
        self:UpdateInfo()
    end)

    Event.Reg(self, "PARTY_UPDATE_MEMBER_INFO", function (_, dwMemberID)
        if not self:CheckUpdatePartyMode() then
            return
        end
        if self.tbMemberCells[dwMemberID] then
            self.tbMemberCells[dwMemberID]:UpdateInfo()
        end
    end)

    Event.Reg(self, "PARTY_SYNC_MEMBER_DATA", function (_, dwMemberID)
        if not self:CheckUpdatePartyMode() then
            return
        end
        self:UpdateInfo()
    end)

    Event.Reg(self, "PARTY_ADD_MEMBER", function (_, dwMemberID)
        if not self:CheckUpdatePartyMode() then
            return
        end
        self:UpdateInfo()
    end)

    Event.Reg(self, "PARTY_DELETE_MEMBER", function (_, dwMemberID, _, nGroupIndex)
        if not self:CheckUpdatePartyMode() then
            return
        end
        self:UpdateInfo()
    end)

    Event.Reg(self, "PARTY_DISBAND", function ()
        if not self:CheckUpdatePartyMode() then
            return
        end
        self:UpdateInfo()
    end)

    Event.Reg(self, "TEAM_AUTHORITY_CHANGED", function (_, _, dwOldAuthorityID, dwNewAuthorityID)
        if not self:CheckUpdatePartyMode() then
            return
        end
        self:UpdateInfo()
    end)

    Event.Reg(self, "PARTY_UPDATE_MEMBER_LMR", function (_, dwMemberID)
        if not self:CheckUpdatePartyMode() then
            return
        end
        if self.tbMemberCells[dwMemberID] then
            self.tbMemberCells[dwMemberID]:UpdateLMRInfo()
        end
    end)

    Event.Reg(self, "TEAM_CHANGE_MEMBER_GROUP", function (_, nSrcGroupIndex, nDstGroupIndex)
        if not self:CheckUpdatePartyMode() then
            return
        end
        local hPlayer = GetClientPlayer()
        if not hPlayer then
            return
        end
		local hTeam = GetClientTeam()
		local nGroup = hTeam.GetMemberGroupIndex(hPlayer.dwID)
        if nGroup == nSrcGroupIndex or nGroup == nDstGroupIndex then
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, "PARTY_SET_MEMBER_ONLINE_FLAG", function (_, dwMemberID)
        if not self:CheckUpdatePartyMode() then
            return
        end
        if self.tbMemberCells[dwMemberID] then
            self.tbMemberCells[dwMemberID]:UpdateInfo()
        end
    end)

    Event.Reg(self, "CLIENT_ON_MEMEBER_VOICE", function()
        if not self:CheckUpdatePartyMode() then
            return
        end
        self:UpdateMic()
    end)

    -- 侠客相关
    Event.Reg(self, "NPC_ENTER_SCENE", function(dwNpcID)
        if not PartnerData.IsPartnerNpc(dwNpcID) then return end

        PartnerData.UpdateNpcList(dwNpcID, true)

        if not self:CheckUpdatePartyMode() then
            return
        end

        if g_pClientPlayer and not TeamData.IsInParty() then
            -- 未组队时，自己加上自己召唤的侠客，人数在2-5人时，模拟组队界面，先把自己尝试加进去
            local nCountSelfAndPartners = 1 + #PartnerData.GetCurrentTeamPartnerNpcList()
            if nCountSelfAndPartners >= 2 and nCountSelfAndPartners <= 5 then
                self:AddPartyMember(g_pClientPlayer.dwID, true)
            end
        end
        self:AddPartnerNpc(dwNpcID)
    end)

    Event.Reg(self, "NPC_LEAVE_SCENE", function(dwNpcID)
        if not PartnerData.IsPartnerNpc(dwNpcID) then return end

        PartnerData.UpdateNpcList(dwNpcID, false)

        if not self:CheckUpdatePartyMode() then
            return
        end

        if g_pClientPlayer then
            if not TeamData.IsInParty() then
                local tMyPartnerList = PartnerData.GetCurrentTeamPartnerNpcList()
                local nCountSelfAndPartners = 1 + #tMyPartnerList

                local bJustSwitchFromRaid = nCountSelfAndPartners == 5

                -- 如果刚好降为5个
                if bJustSwitchFromRaid then
                    -- 先清空
                    self:ClearPartyList()

                    -- 尝试把自己加进去
                    self:AddPartyMember(g_pClientPlayer.dwID, true)

                    -- 把现有的侠客也一起加进去
                    for _, tNpcInfo in ipairs(tMyPartnerList) do
                        if tNpcInfo.dwNpcID ~= dwNpcID then
                            self:AddPartnerNpc(tNpcInfo.dwNpcID)
                        end
                    end
                end
            elseif not TeamData.IsInRaid() and #PartnerData.GetCurrentTeamPartnerNpcList() == 0 then
                -- 逻辑的小队组队模式下，如果侠客都清除了，此时会从团队界面切换回组队界面，需要重新把玩家尝试添加一次
                self:AddPartyMember(g_pClientPlayer.dwID, true)

                -- 队友
                local hTeam = GetClientTeam()
                local nGroupID = hTeam.GetMemberGroupIndex(g_pClientPlayer.dwID)
                if nGroupID then
                    local tbGroupInfo = hTeam.GetGroupInfo(nGroupID)
                    for _, dwMemberID in pairs(tbGroupInfo.MemberList) do
                        self:AddPartyMember(dwMemberID, false)
                    end
                end
            end

            local bShowTeamInfo = g_pClientPlayer.IsInParty() or #PartnerData.GetCurrentTeamPartnerNpcList() > 0
            if not bShowTeamInfo then
                self:DeletePartyMember(g_pClientPlayer.dwID)
            end
        end

        self:DeletePartnerNpc(dwNpcID)
    end)


    Event.Reg(self, "NPC_STATE_UPDATE", function(dwNpcID)
        if not PartnerData.IsPartnerNpc(dwNpcID) then return end

        PartnerData.UpdateNpcInfo(dwNpcID)

        if not self:CheckUpdatePartyMode() then
            return
        end

        if self.tbMemberCells[dwNpcID] then
            self.tbMemberCells[dwNpcID]:UpdateLMRInfo()
        end
    end)

    Event.Reg(self, "PARTY_LEVEL_UP_RAID", function ()
        if not self:CheckUpdatePartyMode() then
            return
        end
    end)

    Event.Reg(self, "BUFF_UPDATE", function ()
        local dwMemberID = arg0
        if not self.tbMemberCells[dwMemberID] then
            return
        end

        self.tbBuffUpdateList = self.tbBuffUpdateList or {}
        if not table.contain_value(self.tbBuffUpdateList, dwMemberID) then
            table.insert(self.tbBuffUpdateList, dwMemberID)
        end
    end)

    Event.Reg(self, EventType.OnEnableMainCityRaidMode, function ()
        if not self:CheckUpdatePartyMode() then
            return
        end
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnEnableMainCityTeamMode, function ()
        if not self:CheckUpdatePartyMode() then
            return
        end
        self:UpdateInfo()
    end)

    Event.Reg(self, "ON_SHOW_FAKE_TEAMINFO", function (bSelect)
        if self.bCustom then
            self.bInSetState = true
            if not self:CheckUpdatePartyMode() then
                return
            end
        end
    end)

    Event.Reg(self, "ON_END_LAYOUT_SETTING", function ()
        if self.bCustom then
            self.bInSetState = false
            if not self:CheckUpdatePartyMode() then
                return
            end
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, "GLOBAL_ROOM_NOTIFY", function()
        local bRaid, bRoom = self:CheckUpdatePartyMode()
        if not bRoom then
            return
        end
        DataModel.UpdateRoomInfo()
        self:UpdateRoomInfo()
    end)

    Event.Reg(self, "GLOBAL_ROOM_BASE_INFO", function()
        self:CheckUpdatePartyMode()
    end)

    Event.Reg(self, "GLOBAL_ROOM_DETAIL_INFO", function()
        self:CheckUpdatePartyMode()
    end)

    Event.Reg(self, "GLOBAL_ROOM_MEMBER_CHANGE", function()
        self:CheckUpdatePartyMode()
    end)

    Event.Reg(self, "GLOBAL_ROOM_MEMBER_ONLINE_FLAG", function()
        -- self.bSyncOffline = true
        -- self.dwSyncOfflineTime = GetTickCount()
        -- self.bSyncInRaid = false
        -- self.dwSyncInRaidTime = 0
        -- DataModel.UpdateOfflinePlayerMap()
        -- RoomData.SyncRoomOnlineFlag()
        -- self:UpdateAllGroup()
        -- TipsHelper.OutputMessage("MSG_SYS", g_tStrings.STR_ROOM_TAG_TIP)
    end)

    Event.Reg(self, EventType.OnSetMainCityRoom, function(bRoom)
        if not self:CheckUpdatePartyMode() then
            return
        end
        self:UpdateInfo()
    end)

    Event.Reg(self, "ON_CHAT_EVENT_NOTIFY", function (dwCode, dwReason, nParam1, nParam2, szParam, cszParam4)
        if dwCode == CHAT_SERVER_NOTIFY_EVENT_CODE_TYPE.TEAM then
            if dwReason == CHAT_SERVER_NOTIFY_EVENT_REASON_TYPE.BAN_JOIN_TEAM_VOICE_ROOM then
                self:UpdateMicSetting()
            end
        end
    end)

    Event.Reg(self, EventType.OnRemoteBanInfoUpdate, function()
        self:UpdateMicSetting()
    end)

    Event.Reg(self, EventType.OnOpenMicButBaned, function()
        self:UpdateMicSetting()
    end)
end


function UITeamMainCityMemberListView:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITeamMainCityMemberListView:UpdateInfo(bInit)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    self:UpdateTeamRecruitBtn()
    UIHelper.SetVisible(self.WidgetNoTeammate, false)
    UIHelper.SetVisible(self.WidgetTitle, hPlayer.IsInParty())
    self:UpdatePartyList(bInit)
    self:UpdateMicSetting()
end

function UITeamMainCityMemberListView:UpdateTeamRecruitBtn()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local bShowTeamRecruit = not hPlayer.IsInParty()
    if bShowTeamRecruit then
        --- 单人模式、侠客+自己的人数>5时，隐藏这个按钮
        local BUFF_UI    = 27896--剧情模式标识
        local bStoryMode = hPlayer.IsHaveBuff(BUFF_UI, 1)

        local tMyPartnerList = PartnerData.GetCurrentTeamPartnerNpcList()
        local nCountSelfAndPartners = 1 + #tMyPartnerList

        if bStoryMode or nCountSelfAndPartners >= 5 then
            bShowTeamRecruit = false
        end
    end

    UIHelper.SetVisible(self.BtnTeamRecruit, bShowTeamRecruit)
end

function UITeamMainCityMemberListView:UpdatePartyList(bInit)
    self:ClearPartyList()

    local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end

    local bIsInParty = hPlayer.IsInParty()
    if bIsInParty ~= self.bIsInParty and not bInit then
        self.bIsInParty = bIsInParty
        if bIsInParty then
            --教学 组队
            FireHelpEvent("OnMakeParty")
        end
    end

    -- 组队，或召唤了侠客的情况下，显示队伍信息
    local tNpcList = PartnerData.GetCurrentTeamPartnerNpcList()
    local bShowTeamInfo = bIsInParty or table.get_len(tNpcList) > 0

    if not bShowTeamInfo then
        return
    end

    self:AddPartyMember(hPlayer.dwID, true)

    local nIndex = 1

    -- 队友
    local hTeam = GetClientTeam()
    local nGroupID = hTeam.GetMemberGroupIndex(hPlayer.dwID)
    if nGroupID then
        local tbGroupInfo = hTeam.GetGroupInfo(nGroupID)
        for _, dwMemberID in pairs(tbGroupInfo.MemberList) do
            if self:AddPartyMember(dwMemberID, false) then
                nIndex = nIndex + 1
            end
        end
    end

    -- 助战侠客
    if not table.is_empty(tNpcList) then
        for _, tNpc in ipairs(tNpcList) do
            if self:AddPartnerNpc(tNpc.dwNpcID) then
                nIndex = nIndex + 1
            end
        end
    end

    if TeamData.IsTeamLeader() then
        if nIndex <= 4 then
            local emptyCell = UIHelper.AddPrefab(PREFAB_ID.WidgetTeamPlayerEmpty, self._rootNode)
            table.insert(self.tbEmptyCells, emptyCell)
        end
    end
    UIHelper.LayoutDoLayout(self._rootNode)
end

function UITeamMainCityMemberListView:ClearPartyList()
    for _, cell in pairs(self.tbMemberCells) do
        self._rootNode:removeChild(cell._rootNode, true)
    end
    self.tbMemberCells = {}
    for _, cell in ipairs(self.tbEmptyCells) do
        self._rootNode:removeChild(cell._rootNode, true)
    end
    self.tbEmptyCells = {}
    UIHelper.LayoutDoLayout(self._rootNode)
end

function UITeamMainCityMemberListView:AddPartyMember(dwMemberID, bAllowMyself)
    local hPlayer = GetClientPlayer()
    if not hPlayer or (hPlayer.dwID == dwMemberID and not bAllowMyself) then
		return false
	end

    if TeamData.IsInParty() then
        if not TeamData.IsInMyGroup(dwMemberID) then
            return false
        end
    end

    local memberCell = self.tbMemberCells[dwMemberID]
    if not memberCell then
        memberCell = UIHelper.AddPrefab(PREFAB_ID.WidgetTeamPlayer, self._rootNode, dwMemberID)
        self.tbMemberCells[dwMemberID] = memberCell
        UIHelper.LayoutDoLayout(self._rootNode)
    end

    return true
end

function UITeamMainCityMemberListView:DeletePartyMember(dwMemberID)
    local memberCell = self.tbMemberCells[dwMemberID]
    if memberCell then
        self._rootNode:removeChild(memberCell._rootNode, true)
        UIHelper.LayoutDoLayout(self._rootNode)
        self.tbMemberCells[dwMemberID] = nil
    end
end

function UITeamMainCityMemberListView:AddPartnerNpc(dwNpcID)
    if not PartnerData.IsPartnerNpcInMyTeam(dwNpcID) then
        return false
    end

    local memberCell = self.tbMemberCells[dwNpcID]
    if not memberCell then
        -- todo: 该预制临时新增一个参数，表明传入的是一个npc，从而在内部可以使用不同的接口来获取相关数据
        ---@see UITeamMainCityMemberListCell#OnEnter
        memberCell = UIHelper.AddPrefab(PREFAB_ID.WidgetTeamPlayer, self._rootNode, dwNpcID, true)
        self.tbMemberCells[dwNpcID] = memberCell

        self:UpdateTeamRecruitBtn()

        UIHelper.LayoutDoLayout(self._rootNode)
    end

    return true
end

function UITeamMainCityMemberListView:DeletePartnerNpc(dwNpcID)
    local memberCell = self.tbMemberCells[dwNpcID]
    if memberCell then
        self._rootNode:removeChild(memberCell._rootNode, true)

        self:UpdateTeamRecruitBtn()

        UIHelper.LayoutDoLayout(self._rootNode)
        self.tbMemberCells[dwNpcID] = nil
    end
end

function UITeamMainCityMemberListView:UpdateMic()
    for _, memberCell in pairs(self.tbMemberCells) do
        memberCell:UpdateMic()
    end
end

function UITeamMainCityMemberListView:UpdateMicSetting()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    if not hPlayer.IsInParty() then
        return
    end
    if GVoiceMgr.IsOpenSpeakerAndMic() then
        UIHelper.SetSpriteFrame(self.ImgVoice, "UIAtlas2_Public_PublicButton_PublicButton1_img_voice")
    elseif GVoiceMgr.IsOpenSpeakerCloseMic() then
        UIHelper.SetSpriteFrame(self.ImgVoice, "UIAtlas2_Public_PublicButton_PublicButton1_img_voice01")
    else
        UIHelper.SetSpriteFrame(self.ImgVoice, "UIAtlas2_Public_PublicButton_PublicButton1_img_voice_close")
    end
end

function UITeamMainCityMemberListView:UpdateMemberBuff()
    if not self.tbBuffUpdateList or #self.tbBuffUpdateList == 0 then
        return
    end

    local nStepUpdateCount = 2
    while #self.tbBuffUpdateList > 0 and nStepUpdateCount > 0 do
        local dwMemberID = self.tbBuffUpdateList[1]
        if self.tbMemberCells[dwMemberID] then
            self.tbMemberCells[dwMemberID]:UpdateDispelMark()
            self.tbMemberCells[dwMemberID]:UpdateBuffInfo()
        end

        table.remove(self.tbBuffUpdateList, 1)
        nStepUpdateCount = nStepUpdateCount - 1
    end
end



function UITeamMainCityMemberListView:CheckUpdatePartyMode()
    local bRoom = RoomData.IsHaveRoom() and RoomData.IsMainCityRoom()

    local bTeam = false
    if TeamData.IsInParty() then
        if TeamData.IsInRaid() then
            bTeam = Storage.Team.bEnableMainCityTeamMode
        else
            bTeam = not Storage.Team.bEnableMainCityRaidMode
        end

        if #PartnerData.GetCurrentTeamPartnerNpcList() > 0 then
            --- 若组队时召唤了侠客，则强制以团队模式显示
            bTeam = false
        end
    else
        bTeam = true
    end
    bTeam = bTeam and not self.bInSetState and not RoomData.IsMainCityRoom()

    -- 特殊处理下单人模式带一群侠客的情况，加上自己，总人数5人及以下认为是队伍，超出认为是团队
    if not TeamData.IsInParty() and not bRoom then
        local nCount = 1 + #PartnerData.GetCurrentTeamPartnerNpcList()
        bTeam = nCount <= 5
    end

    UIHelper.SetActiveAndCache(self, self._rootNode, bTeam)
    if not bTeam then
        self.tbBuffUpdateList = {}
        UIHelper.SetVisible(self.WidgetNoTeammate, false)
        self:ClearPartyList()
    end
    UIHelper.SetVisible(self.BtnSwitchRoom, RoomData.IsHaveRoom())
    UIHelper.SetVisible(self.BtnExitTeam, not RoomData.IsHaveRoom())
    UIHelper.SetVisible(self.BtnCallTeam, TeamData.IsTeamLeader())
    UIHelper.SetVisible(self.BtnMore, true)
    UIHelper.DelayFrameLayoutDoLayout(self, self.LayoutBtnTeam)
    return bTeam
end

function UITeamMainCityMemberListView:SetCustomState(bCustom)
    self.bCustom = bCustom
end

return UITeamMainCityMemberListView