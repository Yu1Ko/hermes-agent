-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITeamMainCityRaidPanel
-- Date: 2023-08-14 10:17:54
-- Desc: ?
-- Prefab: WidgetTaskTeam -> LayoutTeamMoreContent
-- ---------------------------------------------------------------------------------

-----------------------------DataModel------------------------------
local DataModel = {}

function DataModel.Init()
    DataModel.bSceneReady = true
    DataModel.tPlayerPos = {}
    DataModel.tPlayerMap = {}
    DataModel.tOfflinePlayerMap = {}
    DataModel.tInRaidPlayerMap = {}
    DataModel.bUpdateAll = true
    DataModel.dwLastClickTrack = 0
    DataModel.tGlobalRecruit = Table_GetGlobalTeamRecruit()
end

function DataModel.ApplyRoomBaseInfo()
    GetGlobalRoomClient().ApplyBaseInfo()
end

function DataModel.UpdateRoomInfo(bInit)
    local tRoomInfo = GetGlobalRoomClient().GetGlobalRoomInfo()

    DataModel.eRoomState = tRoomInfo.eRoomState
    DataModel.dwTargetMapID = tRoomInfo.nTargetMapID
    DataModel.tRoomInfo = tRoomInfo

    local tPlayerMap = {}
    local tPlayerPos = {}
    for _, v in pairs(tRoomInfo) do
        if type(v) == "table" and v.szGlobalID then
            tPlayerPos[v.nMemberIndex] = v.szGlobalID
            tPlayerMap[v.szGlobalID] = v
        end
    end

    DataModel.bUpdateAll = bInit or (not IsTableEqual(tPlayerPos, DataModel.tPlayerPos)) or DataModel.szOwnerID ~= tRoomInfo.szOwnerID
    DataModel.szOwnerID = tRoomInfo.szOwnerID
    DataModel.tPlayerPos = tPlayerPos
    DataModel.tPlayerMap = tPlayerMap
end

function DataModel.GetMaxGroupNum()
    local nMaxIndex = 0
    for k, v in pairs(DataModel.tPlayerPos) do
        nMaxIndex = math.max(nMaxIndex, k)
    end
    return math.floor((nMaxIndex - 1)/ 5) + 1
end

function DataModel.UpdateOfflinePlayerMap()
    local tOfflineList = GetGlobalRoomClient().GetOfflineMemberList()
    local tOfflinePlayerMap = {}
    for _, szGlobalID in ipairs(tOfflineList) do
        tOfflinePlayerMap[szGlobalID] = true
    end

    DataModel.tOfflinePlayerMap = tOfflinePlayerMap
end

local function IsPlayerInRaid(szGlobalID)
    local player = GetClientPlayer()
    local hTeam = GetClientTeam()
    if player and player.IsInParty() then
        local tMemberInfo = hTeam.GetMemberInfoByGlobalID(szGlobalID)
        if tMemberInfo then
            return true
        end
    end
end

local UITeamMainCityRaidPanel = class("UITeamMainCityRaidPanel")

function UITeamMainCityRaidPanel:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        UIHelper.SetCombinedBatchEnabled(self.LayoutTeamMore, true)

        -- 记录位置
        self.tbWidgetPosX = {}
        for k, v in ipairs(self.tWidgetTeamMore) do
            table.insert(self.tbWidgetPosX, UIHelper.GetPositionX(v))
        end
    end
    self.bInSetState = false
    local bRaid, bRoom = self:CheckUpdatePartyMode()
    if bRaid then
        self:UpdateInfo()
    elseif bRoom then
        -- DataModel.ApplyRoomBaseInfo()
        DataModel.Init()
        DataModel.UpdateRoomInfo(true)
        self:UpdateRoomInfo()
    end

    self.bSyncOffline = false
    self.dwSyncOfflineTime = 0
    self.bSyncInRaid = false
    self.dwSyncInRaidTime = 0

    Timer.DelTimer(self, self.nTimerID)
    self.nTimerID = Timer.AddCycle(self, 0.5, function()
        if self.bCustom then
            return
        end

        local bRaid, bRoom = self:CheckUpdatePartyMode(false)
        if bRaid then
            self:UpdateMicSetting()
            self:UpdateMemberBuff()
        end

        local bRefresh = false
        local nTime = GetTickCount()
        if self.dwSyncOfflineTime ~= 0 and nTime - self.dwSyncOfflineTime > 60000 then --在线统计
            self.bSyncOffline = false
            self.dwSyncOfflineTime = 0
            bRefresh = true
        end
        if self.dwSyncInRaidTime ~= 0 and nTime - self.dwSyncInRaidTime > 60000 then --进本统计
            self.bSyncInRaid = false
            self.dwSyncInRaidTime = 0
            bRefresh = true
        end

        if bRoom and bRefresh then
            self:RefreshRoomPlayerList()
        end
    end)
end

function UITeamMainCityRaidPanel:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITeamMainCityRaidPanel:BindUIEvent()
    UIHelper.BindUIEvent(self.TogTeamTab1, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            for index, widget in ipairs(self.tWidgetTeamMore) do
                UIHelper.SetVisible(widget, index <= 15)
            end
            UIHelper.LayoutDoLayout(self._rootNode)
        end
    end)

    UIHelper.BindUIEvent(self.TogTeamTab2, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            for index, widget in ipairs(self.tWidgetTeamMore) do
                local bVisible = index > 15
                UIHelper.SetVisible(widget, bVisible)
                if bVisible then
                    local nPosX = self.tbWidgetPosX[index - 15]
                    if nPosX then
                        UIHelper.SetPositionX(widget, nPosX)
                    end
                end
            end
            UIHelper.LayoutDoLayout(self._rootNode)
        end
    end)

    UIHelper.BindUIEvent(self.TogTeamTab3, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            for index, widget in ipairs(self.tWidgetTeamMore) do
                UIHelper.SetVisible(widget, true)

                if index > 15 then
                    local nPosX = self.tbWidgetPosX[index]
                    if nPosX then
                        UIHelper.SetPositionX(widget, nPosX)
                    end
                end
            end
            UIHelper.LayoutDoLayout(self._rootNode)
        end
    end)

    UIHelper.BindUIEvent(self.BtnExitTeam2, EventType.OnClick, function()
        TeamData.RequestLeaveTeam()
    end)

    UIHelper.BindUIEvent(self.TogVoice2, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetVoiceTips, self.TogVoice2)
    end)

    UIHelper.BindUIEvent(self.BtnSwitchRoom, EventType.OnClick, function()
        RoomData.SetMainCityRoom(true)
    end)

    UIHelper.BindUIEvent(self.BtnSwitchTeam, EventType.OnClick, function()
        RoomData.SetMainCityRoom(false)
    end)

    UIHelper.BindUIEvent(self.BtnExitTeam3, EventType.OnClick, function()
        RoomData.ConfirmQuitGlobalRoom()
    end)

    UIHelper.BindUIEvent(self.BtnRoomTarget, EventType.OnClick, function()
        local tList = {}
        local tDefault = {}
        for i = 1, #DataModel.tGlobalRecruit do
            local tRecruit = DataModel.tGlobalRecruit[i]
            table.insert(tList, UIHelper.GBKToUTF8(tRecruit.szName))
            if tRecruit.dwMapID == DataModel.dwTargetMapID then
                table.insert(tDefault, i)
            end
        end
        FilterDef.RoomTarget[1].tbList = tList
        FilterDef.RoomTarget[1].tbDefault = tDefault
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnRoomTarget, TipsLayoutDir.AUTO, FilterDef.RoomTarget)
    end)

    UIHelper.BindUIEvent(self.BtnMore2, EventType.OnClick, function()
        local hPlayer = GetClientPlayer()
        if not hPlayer then
            return
        end
        local hTeam = GetClientTeam()
        local bDistribute = hTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE) == hPlayer.dwID

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
            bDisabled = hTeam.bSystem or not TeamData.IsInParty(),  -- 系统队伍，或者单人模式召唤>=5个侠客时模拟的团队面板
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
        },{
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
                    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
                end,
            })
        end

        if TeamData.IsInRaid() then
            local bTeamNoticeOpen, bRoomNoticeOpen = TeamData.GetTeamAndRoomNoticeState()
            if not bTeamNoticeOpen then
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
            else
                table.insert(tbBtnInfo, {
                    szName = "关闭团队公告",
                    OnClick = function()
                        Event.Dispatch("On_Close_TeamNotice")
                        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
                    end
                })
            end
            
        end

        local nX,nY = UIHelper.GetWorldPosition(self.BtnMore2)
		local nSizeW,nSizeH = UIHelper.GetContentSize(self.BtnMore2)
        local _, scriptTips = TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetTipMoreOper,nX,nY+nSizeH-60*(#tbBtnInfo-3))
        scriptTips:OnEnter(tbBtnInfo)
    end)

    UIHelper.BindUIEvent(self.BtnMore3, EventType.OnClick, function()
        local bTrack = (RoomData.IsRoomOwner() or self:IsRoomRaidWait()) and not IsRemotePlayer(UI_GetClientPlayerID())
        bTrack = bTrack and DataModel.dwTargetMapID and DataModel.dwTargetMapID ~= 0
        local tbBtnInfo = {{
            szName = "退出房间",
            OnClick = function()
                RoomData.ConfirmQuitGlobalRoom()
                TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
            end
        }, {
            szName = "顺序同步团队",
            bDisabled = not RoomData.IsRoomOwner(),
            OnClick = function()
                RoomData.SyncRoomQueueToTeam()
                TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
            end
        }, {
            szName = g_tStrings.STR_ROOM_INVITE_TEAM,
            bDisabled = not self:IsRoomRaidWait() or not RoomData.IsRoomOwner(),
            OnClick = function()
                UIHelper.ShowConfirm(g_tStrings.STR_ROOM_REQUEST_INVITE_JOIN_MAP, function()
                    GetGlobalRoomClient().InviteAllJoinScene()
                end)
                TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
            end
        }, {
            szName = g_tStrings.STR_ROOM_LOOKUP_INRAID,
            bDisabled = not RoomData.IsRoomOwner() or not RoomData.IsInGlobalRoomDungeon(),
            OnClick = function()
                self.dwSyncInRaidTime = GetTickCount()
                self.dwSyncOfflineTime = 0
                self.bSyncInRaid = true
                self.bSyncOffline = false
                self:UpdateRoomInRaidPlayerMap()
                self:RefreshRoomPlayerList()
                TipsHelper.OutputMessage("MSG_SYS", g_tStrings.STR_ROOM_TAG_TIP)
                TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
            end
        }, {
            szName = g_tStrings.STR_ROOM_LOOKUP_PROCESS,
            OnClick = function ()
                MonsterBookData.CheckRemoteRoommateProgress(DataModel.dwTargetMapID)
            end
        }, {
            szName = g_tStrings.STR_ROOM_LOOKUP_ONLINE,
            OnClick = function ()
                GetGlobalRoomClient().ApplyRoleOnlineFlag()
                TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
            end
        }, {
            szName = g_tStrings.STR_ROOM_SHARE,
            OnClick = function()
                RoomData.ShareRoomToChat()
                TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
            end
        }, {
            szName = "前往秘境",
            bDisabled = not bTrack,
            OnClick = function()
                local dwNowTime = GetTickCount()
                if dwNowTime - DataModel.dwLastClickTrack > 10000 then
                    MapMgr.BeforeTeleport()
                    RemoteCallToServer("On_Team_RoomToEnterScene")
                    DataModel.dwLastClickTrack = GetTickCount()
                else
                    OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_ROOM_HAVE_APPLY_SCENE)
                end
                TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
            end
        }}

        local bTeamNoticeOpen, bRoomNoticeOpen = TeamData.GetTeamAndRoomNoticeState()
        if not bRoomNoticeOpen then
            table.insert(tbBtnInfo, {
                szName = g_tStrings.STR_ROOM_NOTICE,
                OnClick = function()
                    if RoomData.GetRoomOwner() == UI_GetClientPlayerGlobalID() then
                        UIMgr.Open(VIEW_ID.PanelTeamNoticeEditPop, true)
                    else
                        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TALK, "player talk") then
                            return
                        end
                    
                        SendBgMsg(PLAYER_TALK_CHANNEL.ROOM, "ROOM_NOTICE_APPLY", UI_GetClientPlayerGlobalID())
                        TipsHelper.ShowNormalTip(g_tStrings.STR_ROOM_NOTICE_APPLY)
                    end
                
                    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
                end
            })
        else
            table.insert(tbBtnInfo, {
                szName = "关闭房间公告",
                OnClick = function()
                    Event.Dispatch("On_Close_RoomNotice")
                    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
                end
            })
        end

        local nX,nY = UIHelper.GetWorldPosition(self.BtnMore3)
		local nSizeW,nSizeH = UIHelper.GetContentSize(self.BtnMore3)
        local _, scriptTips = TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetTipMoreOper,nX,nY+nSizeH-60*(#tbBtnInfo-3))
        scriptTips:OnEnter(tbBtnInfo)
    end)

    UIHelper.BindUIEvent(self.BtnCallTeam2, EventType.OnClick, function()
        TeamData.EnvokeAllTeammates()
    end)
end

function UITeamMainCityRaidPanel:RegEvent()
    Event.Reg(self, "LOADING_END", function ()
        local bRaid, bRoom = self:CheckUpdatePartyMode()
        if bRaid then
            self:UpdateInfo()
        elseif bRoom then
            -- DataModel.ApplyRoomBaseInfo()
            DataModel.Init()
            DataModel.UpdateRoomInfo(true)
            self:UpdateRoomInfo()
        end
    end)

    Event.Reg(self, "SYNC_ROLE_DATA_END", function ()
        local bRaid, bRoom = self:CheckUpdatePartyMode()
        if not bRaid then
            return
        end
        self:UpdateInfo()
    end)

    Event.Reg(self, "PARTY_UPDATE_BASE_INFO", function ()
        local bRaid, bRoom = self:CheckUpdatePartyMode()
        if not bRaid then
            return
        end
        self:UpdateInfo()
    end)

    Event.Reg(self, "PARTY_UPDATE_MEMBER_INFO", function (_, dwMemberID)
        local bRaid, bRoom = self:CheckUpdatePartyMode()
        if not bRaid then
            return
        end
        local cell = self:GetMemberScript(dwMemberID)
        if cell then
            cell:UpdateInfo()
        end
    end)

    Event.Reg(self, "PARTY_SYNC_MEMBER_DATA", function (_, dwMemberID, nGroup)
        local bRaid, bRoom = self:CheckUpdatePartyMode()
        if not bRaid then
            return
        end
        self:AddMember(dwMemberID, nGroup)
    end)

    Event.Reg(self, "PARTY_ADD_MEMBER", function (_, dwMemberID, nGroup)
        local bRaid, bRoom = self:CheckUpdatePartyMode()
        if not bRaid then
            return
        end

        -- 如果有侠客的话，则先清空侠客的位置，将新的队友添加好后，再重新把侠客塞进去。否则可能单个队伍显示超过5个
        self:RemoveAllPartner()

        self:AddMember(dwMemberID, nGroup)

        self:AddAllPartner()
    end)

    Event.Reg(self, "PARTY_DELETE_MEMBER", function (_, dwMemberID, _, nGroup)
        local bRaid, bRoom = self:CheckUpdatePartyMode()
        if not bRaid then
            return
        end
        local hPlayer = GetClientPlayer()
        if not hPlayer then
            return
        end
        if hPlayer.dwID == dwMemberID then
            self:UpdateInfo()
        else
            self:RemoveMember(dwMemberID, nGroup)

            -- 如果有侠客的话，则先清空侠客的位置，再重新把侠客塞进去,避免漏空
            self:ResetAllPartner()
        end
    end)

    Event.Reg(self, "PARTY_DISBAND", function ()
        local bRaid, bRoom = self:CheckUpdatePartyMode()
        if not bRaid then
            return
        end
        self:UpdateInfo()
    end)

    Event.Reg(self, "TEAM_AUTHORITY_CHANGED", function (_, _, dwOldAuthorityID, dwNewAuthorityID)
        local bRaid, bRoom = self:CheckUpdatePartyMode()
        if not bRaid then
            return
        end
        local oldAuthorityScript = self:GetMemberScript(dwOldAuthorityID)
        if oldAuthorityScript then
            oldAuthorityScript:UpdateInfo()
        end
        local newAuthorityScript = self:GetMemberScript(dwNewAuthorityID)
        if newAuthorityScript then
            newAuthorityScript:UpdateInfo()
        end
    end)

    Event.Reg(self, "PARTY_UPDATE_MEMBER_LMR", function (_, dwMemberID)
        local bRaid, bRoom = self:CheckUpdatePartyMode()
        if not bRaid then
            return
        end
        local script = self:GetMemberScript(dwMemberID)
        if script then
            script:UpdateLMRInfo()
        end
    end)

    Event.Reg(self, "TEAM_CHANGE_MEMBER_GROUP", function (_, nSrcGroupIndex, nDstGroupIndex)
        local bRaid, bRoom = self:CheckUpdatePartyMode()
        if not bRaid then
            return
        end
        self:UpdateInfo()
    end)

    Event.Reg(self, "PARTY_SET_MEMBER_ONLINE_FLAG", function (_, dwMemberID)
        local bRaid, bRoom = self:CheckUpdatePartyMode()
        if not bRaid then
            return
        end
        local script = self:GetMemberScript(dwMemberID)
        if script then
            script:UpdateInfo()
        end
    end)

    Event.Reg(self, "CLIENT_ON_MEMEBER_VOICE", function()
        local bRaid, bRoom = self:CheckUpdatePartyMode()
        if not bRaid then
            return
        end
        self:UpdateMic()
    end)

    -- 侠客相关
    Event.Reg(self, "NPC_ENTER_SCENE", function(dwNpcID)
        if not PartnerData.IsPartnerNpc(dwNpcID) then return end

        PartnerData.UpdateNpcList(dwNpcID, true)

        local bRaid, bRoom = self:CheckUpdatePartyMode()
        if not bRaid then
            return
        end

        if g_pClientPlayer then
            if not TeamData.IsInParty() then
                local tMyPartnerList = PartnerData.GetCurrentTeamPartnerNpcList()
                local nCountSelfAndPartners = 1 + #tMyPartnerList

                local bJustSwitchFromTeam = nCountSelfAndPartners == 6

                -- 如果刚好增加超过5个，先清空
                if bJustSwitchFromTeam then
                    self:Clear()
                end

                -- 尝试把自己加进去
                self:AddMember(g_pClientPlayer.dwID, 0)

                -- 如果刚好超过5个，这时候需要把现有的侠客也一起加进去
                if bJustSwitchFromTeam then
                    for _, tNpcInfo in ipairs(tMyPartnerList) do
                        if tNpcInfo.dwNpcID ~= dwNpcID then
                            self:AddPartnerNpc(tNpcInfo.dwNpcID)
                        end
                    end
                end
            elseif not TeamData.IsInRaid() and #PartnerData.GetCurrentTeamPartnerNpcList() == 1  then
                -- 逻辑的小队组队模式下，如果刚召唤第一个侠客，此时会从组队界面切换到团队界面，需要重新把玩家尝试添加一次
                local hTeam = GetClientTeam()
                for nGroupID = 0, hTeam.nGroupNum -1 do
                    local tGroupInfo = hTeam.GetGroupInfo(nGroupID)
                    for _, dwMemberID in pairs(tGroupInfo.MemberList) do
                        self:AddMember(dwMemberID, nGroupID)
                    end
                end
            end
        end
        self:AddPartnerNpc(dwNpcID)
    end)

    Event.Reg(self, "NPC_LEAVE_SCENE", function(dwNpcID)
        if not PartnerData.IsPartnerNpc(dwNpcID) then return end

        PartnerData.UpdateNpcList(dwNpcID, false)

        local bRaid, bRoom = self:CheckUpdatePartyMode()
        if not bRaid then
            return
        end

        if g_pClientPlayer then
            local bShowTeamInfo = g_pClientPlayer.IsInParty() or #PartnerData.GetCurrentTeamPartnerNpcList() > 0
            if not bShowTeamInfo then
                self:RemoveMember(g_pClientPlayer.dwID, 0)
            end
        end

        self:RemovePartnerNpc(dwNpcID)

        -- 重新刷新一遍侠客，避免留出空位
        self:ResetAllPartner()
    end)

    Event.Reg(self, "NPC_STATE_UPDATE", function(dwNpcID)
        if not PartnerData.IsPartnerNpc(dwNpcID) then return end

        PartnerData.UpdateNpcInfo(dwNpcID)

        local bRaid, bRoom = self:CheckUpdatePartyMode()
        if not bRaid then
            return
        end

        local script = self:GetMemberScript(dwNpcID)
        if script then
            script:UpdateLMRInfo()
        end
    end)

    Event.Reg(self, "PARTY_LEVEL_UP_RAID", function ()
        local bRaid, bRoom = self:CheckUpdatePartyMode()
        if not bRaid then
            return
        end
        self:UpdateInfo()
    end)

    Event.Reg(self, "BUFF_UPDATE", function ()
        if self.bCustom then
            return
        end
        local bRaid, bRoom = self:CheckUpdatePartyMode()
        if not bRaid then
            return
        end
        local dwMemberID = arg0
        local cell = self:GetMemberScript(dwMemberID)
        if cell then
            self.tbBuffUpdateList = self.tbBuffUpdateList or {}
            if not table.contain_value(self.tbBuffUpdateList, dwMemberID) then
                table.insert(self.tbBuffUpdateList, dwMemberID)
            end
        end
    end)

    Event.Reg(self, EventType.OnEnableMainCityRaidMode, function ()
        local bRaid, bRoom = self:CheckUpdatePartyMode()
        if not bRaid then
            return
        end
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnEnableMainCityTeamMode, function ()
        local bRaid, bRoom = self:CheckUpdatePartyMode()
        if not bRaid then
            return
        end
        self:UpdateInfo()
    end)

    Event.Reg(self, "ON_SHOW_FAKE_TEAMINFO", function (bSelect)
        if self.bCustom then
            self:ShowFakeTeamInfo()
        end
    end)

    Event.Reg(self, "ON_END_LAYOUT_SETTING", function ()
        if self.bCustom then
            self:EndTeamLayoutSetting()
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
        local bRaid, bRoom = self:CheckUpdatePartyMode()
        if not bRoom then
            return
        end
        local szRoomID, bMemberChange, bInit = arg0, arg1, arg2
        DataModel.UpdateRoomInfo(bInit or bMemberChange)
        self:UpdateRoomInfo()
    end)

    Event.Reg(self, "GLOBAL_ROOM_DETAIL_INFO", function()
        local bRaid, bRoom = self:CheckUpdatePartyMode()
        if not bRoom then
            return
        end
        local szRoomID, bMemberChange, bInit = arg0, arg1, arg2
        DataModel.UpdateRoomInfo(bInit or bMemberChange)
        self:UpdateRoomInfo()
    end)

    Event.Reg(self, "GLOBAL_ROOM_MEMBER_CHANGE", function()
        local bRaid, bRoom = self:CheckUpdatePartyMode()
        if not bRoom then
            return
        end
        DataModel.UpdateRoomInfo()
        self:UpdateRoomInfo()
    end)

    Event.Reg(self, "GLOBAL_ROOM_MEMBER_ONLINE_FLAG", function()
        self.bSyncOffline = true
        self.dwSyncOfflineTime = GetTickCount()
        self.bSyncInRaid = false
        self.dwSyncInRaidTime = 0
        local bRaid, bRoom = self:CheckUpdatePartyMode()
        if not bRoom then
            return
        end
        DataModel.UpdateOfflinePlayerMap()
        self:RefreshRoomPlayerList()
    end)

    Event.Reg(self, EventType.OnSetMainCityRoom, function(bRoom)
        local bRaid, bRoom = self:CheckUpdatePartyMode()
        if bRaid then
            self:UpdateInfo()
        elseif bRoom then
            -- DataModel.ApplyRoomBaseInfo()
            DataModel.Init()
            DataModel.UpdateRoomInfo(true)
            self:UpdateRoomInfo()
        end
    end)

    Event.Reg(self, EventType.OnFilter, function(szKey, tbSelected)
        if szKey == FilterDef.RoomTarget.Key then
            local nIndex = tbSelected[1][1]
            local tRecruit = DataModel.tGlobalRecruit[nIndex]
            if not tRecruit then
                return
            end
            if tRecruit.dwMapID and tRecruit.dwMapID ~= DataModel.dwTargetMapID then
                GetGlobalRoomClient().UpdateRoomTarget(tRecruit.dwMapID)
            end
        end
    end)
end

function UITeamMainCityRaidPanel:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITeamMainCityRaidPanel:UpdateInfo()
    self:Clear()

    local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end

    local bIsInParty = hPlayer.IsInParty()

    -- 组队，或召唤了侠客的情况下，显示队伍信息
    local tNpcList = PartnerData.GetCurrentTeamPartnerNpcList()
    local bShowRaidInfo = bIsInParty or table.get_len(tNpcList) > 0

    if not bShowRaidInfo then
        return
    end

    if bIsInParty then
        local hTeam = GetClientTeam()
        for nGroupID = 0, hTeam.nGroupNum -1 do
            local tGroupInfo = hTeam.GetGroupInfo(nGroupID)
            for _, dwMemberID in pairs(tGroupInfo.MemberList) do
                self:AddMember(dwMemberID, nGroupID)
            end
        end
    end

    -- 特殊处理下单人情况下的自己
    if not bIsInParty and table.get_len(tNpcList) > 0 then
        self:AddMember(hPlayer.dwID, 0)
    end

    -- 助战侠客
    for _, tNpc in ipairs(tNpcList) do
        self:AddPartnerNpc(tNpc.dwNpcID)
    end

    self:UpdateTab()
    self:UpdateMicSetting()
end

function UITeamMainCityRaidPanel:GetMemberScript(dwMemberID)
    for _, tGroupCells in pairs(self.tRaidCells) do
        for _, cell in ipairs(tGroupCells) do
            if cell.dwID == dwMemberID then
                return cell
            end
        end
    end
    return nil
end

function UITeamMainCityRaidPanel:AddMember(dwMemberID, nGroup)
    local hTeam = GetClientTeam()
	if nGroup < 0 or nGroup >= hTeam.nGroupNum then
        return
    end

    local nGroupID = nGroup + 1
    if not self.tRaidCells[nGroupID] then
        self.tRaidCells[nGroupID] = {}
    end

    for _, cell in ipairs(self.tRaidCells[nGroupID]) do
        if cell.dwID == dwMemberID then
            cell:UpdateInfo()
            return
        end
    end

    local nCellID = #self.tRaidCells[nGroupID] + 1
    local nIndex = (nGroupID - 1) * 5 + nCellID

    local widget = self.tWidgetTeamMore[nIndex]
    local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetTeamMoreBlood, widget, dwMemberID)
    table.insert(self.tRaidCells[nGroupID], cell)
    UIHelper.LayoutDoLayout(self._rootNode)
    self:UpdateTab()
end

function UITeamMainCityRaidPanel:RemoveMember(dwMemberID, nGroup)
    local nGroupID = nGroup + 1
    if not self.tRaidCells[nGroupID] then
        return
    end

    local nRemoveIdx = nil
    local removeCell = nil
    for index, cell in ipairs(self.tRaidCells[nGroupID]) do
        if cell.dwID == dwMemberID then
            removeCell = cell
            nRemoveIdx = index
            break
        end
    end

    -- 删除以后要手动排版，往上顶，避免出现空位
    if nRemoveIdx then
        local nLen = #self.tRaidCells[nGroupID]
        for i = nRemoveIdx + 1, nLen do
            local nIndex = (nGroupID - 1) * 5 + i
            local widget = self.tWidgetTeamMore[nIndex]
            local widgetPrev = self.tWidgetTeamMore[nIndex - 1]
            local cell = self.tRaidCells[nGroupID][i]
            if widget and widgetPrev and cell and cell._rootNode then
                UIHelper.SetParent(cell._rootNode, widgetPrev)
            end
        end

        -- 最后再做移除
        if removeCell then
            UIHelper.RemoveFromParent(removeCell._rootNode, true)
            table.remove(self.tRaidCells[nGroupID], nRemoveIdx)
        end
    end

    UIHelper.LayoutDoLayout(self._rootNode)
    self:UpdateTab()
end

function UITeamMainCityRaidPanel:AddPartnerNpc(dwNpcID)
    if not PartnerData.IsPartnerNpcInMyTeam(dwNpcID) then
        return
    end

    local nGroup = 0
    for idx = 0, 4 do
        if table.get_len(self.tRaidCells[idx+1]) < 5 then
            nGroup = idx
            break
        end
    end

    local nGroupID = nGroup + 1
    if not self.tRaidCells[nGroupID] then
        self.tRaidCells[nGroupID] = {}
    end

    for _, cell in ipairs(self.tRaidCells[nGroupID]) do
        if cell.dwID == dwNpcID then
            cell:UpdateInfo()
            return
        end
    end

    local nCellID = #self.tRaidCells[nGroupID] + 1
    local nIndex = (nGroupID - 1) * 5 + nCellID

    local widget = self.tWidgetTeamMore[nIndex]
    ---@type UITeamMainCityRaidCell
    local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetTeamMoreBlood, widget, dwNpcID, true)
    table.insert(self.tRaidCells[nGroupID], cell)
    UIHelper.LayoutDoLayout(self._rootNode)
    self:UpdateTab()
end

function UITeamMainCityRaidPanel:RemovePartnerNpc(dwNpcID)
    local bFind = false
    local nRemoveGroupID = nil
    local nRemoveIdx = nil
    local removeCell = nil
    for nGroup = 0, 4 do
        local nGroupID = nGroup + 1
        for index, cell in ipairs(self.tRaidCells[nGroupID]) do
            if cell.dwID == dwNpcID and cell.bIsNpc then
                bFind = true
                nRemoveIdx = index
                nRemoveGroupID = nGroupID
                removeCell = cell
                break
            end
        end

        if bFind then
            break
        end
    end

    -- 删除以后要手动排版，往上顶，避免出现空位
    if nRemoveIdx and nRemoveGroupID then
        local nLen = #self.tRaidCells[nRemoveGroupID]
        for i = nRemoveIdx + 1, nLen do
            local nIndex = (nRemoveGroupID - 1) * 5 + i
            local widget = self.tWidgetTeamMore[nIndex]
            local widgetPrev = self.tWidgetTeamMore[nIndex - 1]
            local cell = self.tRaidCells[nRemoveGroupID][i]
            if widget and widgetPrev and cell and cell._rootNode then
                UIHelper.SetParent(cell._rootNode, widgetPrev)
            end
        end

        -- 最后再做移除
        if removeCell then
            UIHelper.RemoveFromParent(removeCell._rootNode, true)
            table.remove(self.tRaidCells[nRemoveGroupID], nRemoveIdx)
        end
    end

    UIHelper.LayoutDoLayout(self._rootNode)
    self:UpdateTab()
end

function UITeamMainCityRaidPanel:UpdateTab()
    if not g_pClientPlayer then
        return
    end
    local hTeam = GetClientTeam()
    local bTabCheck = true
    -- for nGroupID = 0, hTeam.nGroupNum - 1 do
    --     local tGroupInfo = hTeam.GetGroupInfo(nGroupID)
    --     if nGroupID >= 2 and #tGroupInfo.MemberList > 0 then
    --         bTabCheck = true
    --         break
    --     end
    -- end

    self.bLastTabCheck = self.bLastTabCheck or false
    UIHelper.SetVisible(self.LayoutTeamMoreTab, bTabCheck)
    UIHelper.SetVisible(self.LayoutBtnRoom, false)
    UIHelper.SetVisible(self.LayoutBtnTeam, true)
    UIHelper.SetVisible(self.TogTeamTab1, bTabCheck)
    UIHelper.SetVisible(self.TogTeamTab2, bTabCheck)
    UIHelper.SetVisible(self.TogTeamTab3, bTabCheck)
    UIHelper.SetVisible(self.WidgetRoom, false)
    UIHelper.LayoutDoLayout(self._rootNode)

    if not self.bLastTabCheck and bTabCheck then
        -- Tab出现的时候根据小队id自动选一次
        local nGroup = hTeam.GetMemberGroupIndex(g_pClientPlayer.dwID)
        if nGroup then
            if nGroup < 2 then
                UIHelper.SetSelected(self.TogTeamTab1, true)
            else
                UIHelper.SetSelected(self.TogTeamTab2, true)
            end
        end
    elseif not bTabCheck then
        UIHelper.SetSelected(self.TogTeamTab1, true)
    end
    self.bLastTabCheck = bTabCheck
end

function UITeamMainCityRaidPanel:Clear()
    UIHelper.SetVisible(self.LayoutTeamMoreTab, false)
    for _, widget in ipairs(self.tWidgetTeamMore) do
        UIHelper.RemoveAllChildren(widget)
    end
    self.tbBuffUpdateList = {}
    self.tRaidCells = {}
    self.tRoomCells = {}
    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true)
end

function UITeamMainCityRaidPanel:UpdateMic()
    for _, tGroupCells in pairs(self.tRaidCells) do
        for _, cell in ipairs(tGroupCells) do
            cell:UpdateMic()
        end
    end
end

function UITeamMainCityRaidPanel:UpdateMicSetting()
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

function UITeamMainCityRaidPanel:UpdateMemberBuff()
    if not self.tbBuffUpdateList or #self.tbBuffUpdateList == 0 then
        return
    end

    local nStepUpdateCount = 5
    while #self.tbBuffUpdateList > 0 and nStepUpdateCount > 0 do
        local dwMemberID = self.tbBuffUpdateList[1]
        local cell = self:GetMemberScript(dwMemberID)
        if cell then
            cell:UpdateDispelMark()
            cell:UpdateBuffInfo()
            cell:UpdateGroupRide()
        end
        table.remove(self.tbBuffUpdateList, 1)
        nStepUpdateCount = nStepUpdateCount - 1
    end
end

function UITeamMainCityRaidPanel:CheckUpdatePartyMode(bUpdateUI)
    local bRoom = RoomData.IsHaveRoom() and RoomData.IsMainCityRoom()

    local bRaid = false
    if TeamData.IsInParty() then
        if TeamData.IsInRaid() then
            bRaid = not Storage.Team.bEnableMainCityTeamMode
        else
            bRaid = Storage.Team.bEnableMainCityRaidMode
        end

        if #PartnerData.GetCurrentTeamPartnerNpcList() > 0 then
            --- 若组队时召唤了侠客，则强制以团队模式显示
            bRaid = true
        end
    end
    bRaid = (bRaid or self.bInSetState) and not RoomData.IsMainCityRoom()

    -- 特殊处理下单人模式带一群侠客的情况，加上自己，总人数5人及以下认为是队伍，超出认为是团队
    if not TeamData.IsInParty() and not bRoom then
        local nCount = 1 + #PartnerData.GetCurrentTeamPartnerNpcList()
        bRaid = nCount > 5
    end

    if bUpdateUI == nil or bUpdateUI == true then
        UIHelper.SetActiveAndCache(self, self._rootNode, bRaid or bRoom)
        if not bRaid and not bRoom then
            self.bLastTabCheck = false
            self:Clear()
        end
        UIHelper.SetVisible(self.BtnSwitchRoom, RoomData.IsHaveRoom())
        UIHelper.SetVisible(self.BtnExitTeam2, not RoomData.IsHaveRoom())
        UIHelper.SetVisible(self.BtnSwitchTeam, TeamData.IsInParty())
        UIHelper.SetVisible(self.BtnCallTeam2, TeamData.IsTeamLeader())
        UIHelper.DelayFrameLayoutDoLayout(self, self.LayoutBtnRoom)
        UIHelper.SetVisible(self.BtnMore2, true)

        -- 单人模式山寨的情况下，隐藏一些按钮
        if not TeamData.IsInParty() then
            UIHelper.SetVisible(self.TogVoice2, false)
            UIHelper.SetVisible(self.BtnExitTeam2, false)
            UIHelper.SetVisible(self.BtnMore2, false)
            UIHelper.SetVisible(self.BtnCallTeam2, false)
        else
            UIHelper.SetVisible(self.TogVoice2, true)
        end

        UIHelper.DelayFrameLayoutDoLayout(self, self.LayoutBtnTeam)
    end

    return bRaid, bRoom
end

function UITeamMainCityRaidPanel:ShowFakeTeamInfo()
    self.bInSetState = true
    UIHelper.SetActiveAndCache(self, self._rootNode, true)
    UIHelper.RemoveAllChildren(self.LayoutTeamMoreSetting)
    UIHelper.SetVisible(self.LayoutTeamMoreSetting, true)
    UIHelper.SetVisible(self.LayoutTeamMore, false)
    for i = 1, 25 do
        local tbScript = UIHelper.AddPrefab(PREFAB_ID.WidgetTeamMoreBlood, self.LayoutTeamMoreSetting)
        tbScript:UpdateFakeInfo(i)
    end
    UIHelper.LayoutDoLayout(self.LayoutTeamMoreSetting)
    UIHelper.LayoutDoLayout(self._rootNode)
end

function UITeamMainCityRaidPanel:EndTeamLayoutSetting()
    self.bInSetState = false
    UIHelper.SetVisible(self.LayoutTeamMore, true)
    UIHelper.RemoveAllChildren(self.LayoutTeamMoreSetting)
    UIHelper.SetVisible(self.LayoutTeamMoreSetting, false)
    UIHelper.LayoutDoLayout(self._rootNode)

    local bRaid, bRoom = self:CheckUpdatePartyMode()
    if bRaid then
        self:UpdateInfo()
    elseif bRoom then
        self:UpdateRoomInfo()
    end
end

------------------------------Room------------------------------
function UITeamMainCityRaidPanel:UpdateRoomInfo()
    if DataModel.bUpdateAll or (not self.tRoomCells or #self.tRoomCells == 0) then
        self:Clear()
        self:UpdateRoomAllGroup()
        DataModel.bUpdateAll = false
    else
        self:RefreshRoomPlayerList()
    end
    self:UpdateRoomTarget()
    self:UpdateRoomBtnState()
    self:UpdateRoomTab()

    if RoomData.bDelaySyncToTeam then
        RoomData.SyncRoomQueueToTeam()
        RoomData.bDelaySyncToTeam = false
    end
end

function UITeamMainCityRaidPanel:UpdateRoomAllGroup()
    self.tRoomCells = {}
    for nGroupID = 1, 5, 1 do
        local nStart = nGroupID * 5 - 4
        self.tRoomCells[nGroupID] = {}
        for i = nStart, nStart + 4 do
            widget = self.tWidgetTeamMore[i]
            local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetTeamMoreBlood, widget)
            self.tRoomCells[nGroupID][i] = cell
            if DataModel.tPlayerPos[i] then
                local dwGlobalID = DataModel.tPlayerPos[i]
                local bOffline = self.bSyncOffline and DataModel.tOfflinePlayerMap[dwGlobalID]
                local bNotInRaid = self.bSyncInRaid and not DataModel.tInRaidPlayerMap[dwGlobalID]
                cell:UpdateRoomInfo(DataModel.tPlayerMap[dwGlobalID], bOffline, bNotInRaid)
            else
                UIHelper.HideAllChildren(cell._rootNode)
            end
        end
    end
end

function UITeamMainCityRaidPanel:RefreshRoomPlayerList()
    for nGroupID = 1, 5, 1 do
        local nStart = nGroupID * 5 - 4
        for i = nStart, nStart + 4 do
            local dwGlobalID = DataModel.tPlayerPos[i]
            if self.tRoomCells[nGroupID][i] and dwGlobalID then
                local bOffline = self.bSyncOffline and DataModel.tOfflinePlayerMap[dwGlobalID]
                local bNotInRaid = self.bSyncInRaid and not DataModel.tInRaidPlayerMap[dwGlobalID]
                self.tRoomCells[nGroupID][i]:UpdateRoomInfo(DataModel.tPlayerMap[dwGlobalID], bOffline, bNotInRaid)
            end
        end
    end
end

function UITeamMainCityRaidPanel:UpdateRoomTab()
    UIHelper.SetVisible(self.LayoutTeamMoreTab, true)
    UIHelper.SetVisible(self.LayoutBtnRoom, true)
    UIHelper.SetVisible(self.LayoutBtnTeam, false)
    UIHelper.SetVisible(self.TogTeamTab1, false)
    UIHelper.SetVisible(self.TogTeamTab2, false)
    UIHelper.SetVisible(self.TogTeamTab3, false)
    UIHelper.SetVisible(self.WidgetRoom, true)
    UIHelper.LayoutDoLayout(self._rootNode)
    UIHelper.SetSelected(self.TogTeamTab3, true)
    self.bLastTabCheck = false
end

function UITeamMainCityRaidPanel:UpdateRoomBtnState()
    UIHelper.SetEnable(self.BtnRoomTarget, RoomData.IsRoomOwner())
end

function UITeamMainCityRaidPanel:UpdateRoomTarget()
    if DataModel.dwTargetMapID and DataModel.dwTargetMapID ~= 0 then
        UIHelper.SetString(self.LabelRoomTarget, UIHelper.GBKToUTF8(Table_GetMapName(DataModel.dwTargetMapID)))
    else
        UIHelper.SetString(self.LabelRoomTarget, "请房主设置目标")
    end
    UIHelper.LayoutDoLayout(self.LayoutTargetContent)
end

function UITeamMainCityRaidPanel:IsRoomRaidWait()
    return DataModel.eRoomState == GLOBAL_ROOM_STATE_CODE.ROOM_WAIT_ENTER
end

function UITeamMainCityRaidPanel:UpdateRoomInRaidPlayerMap()
    if not RoomData.IsRoomOwner() then
        self.bSyncInRaid = false
        return
    end

    if not RoomData.IsInGlobalRoomDungeon() then
        self.bSyncInRaid = false
        return
    end

    for szGlobalID, tPlayer in pairs(DataModel.tPlayerMap) do
        local bInRaid = IsPlayerInRaid(szGlobalID)
        DataModel.tInRaidPlayerMap[szGlobalID] = bInRaid
    end
end

function UITeamMainCityRaidPanel:SetCustomState(bCustom)
    self.bCustom = bCustom
end

function UITeamMainCityRaidPanel:RemoveAllPartner()
    local tNpcList = PartnerData.GetCurrentTeamPartnerNpcList()
    if #tNpcList > 0 then
        for _, tNpc in ipairs(tNpcList) do
            self:RemovePartnerNpc(tNpc.dwNpcID)
        end
    end
end

function UITeamMainCityRaidPanel:AddAllPartner()
    local tNpcList = PartnerData.GetCurrentTeamPartnerNpcList()
    if #tNpcList > 0 then
        for _, tNpc in ipairs(tNpcList) do
            self:AddPartnerNpc(tNpc.dwNpcID)
        end
    end
end

function UITeamMainCityRaidPanel:ResetAllPartner()
    self:RemoveAllPartner()
    self:AddAllPartner()
end


return UITeamMainCityRaidPanel