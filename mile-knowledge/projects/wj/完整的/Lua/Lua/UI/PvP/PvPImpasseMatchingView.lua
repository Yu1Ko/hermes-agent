-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: PvPImpasseMatchingView
-- Date: 2023-05-05 14:09:25
-- Desc: ?
-- ---------------------------------------------------------------------------------

local PvPImpasseMatchingView = class("PvPImpasseMatchingView")

local nPersonalScoreIndex = BF_MAP_ROLE_INFO_TYPE.MATCH_LEVEL
--最佳数据 --获取为历史总数据
local tBestPersonInfoItem =
{
    BF_MAP_ROLE_INFO_TYPE.KILL_COUNT,		--最佳击伤
    BF_MAP_ROLE_INFO_TYPE.TOTAL_DAMAGE,		--最佳伤害
    BF_MAP_ROLE_INFO_TYPE.ASSIST_KILL_COUNT,	--最佳协杀
	BF_MAP_ROLE_INFO_TYPE.BEST_ASSIST_KILL_COUNT,	--最佳助攻
	BF_MAP_ROLE_INFO_TYPE.BEST_EQUIP_SCORE, 	--"最高死亡装备分"
}
--历史数据	--区分上周和本周数据
local tPastPersonInfoItem =
{
    BF_MAP_ROLE_INFO_TYPE.BATTLE_ROUNDS,	--总场次
    BF_MAP_ROLE_INFO_TYPE.SUM_LIVE_COUNT,	--平均存活场次
    BF_MAP_ROLE_INFO_TYPE.SUM_KILL_COUNT,	--总击伤
    BF_MAP_ROLE_INFO_TYPE.SUM_ASSIST_KILL_COUNT,	--总协杀
	BF_MAP_ROLE_INFO_TYPE.TOP_COUNT,	--夺冠次数
	BF_MAP_ROLE_INFO_TYPE.AVRG_EQUIP_SCORE,	 -- "平均死亡装备分"
	BF_MAP_ROLE_INFO_TYPE.AVRG_LIVE_TIME,	-- "平均存活时长"
}
local tDataType =
{
	["History"] = BF_ROLE_DATA_TYPE.HISTORY,
	["This_Week"] = BF_ROLE_DATA_TYPE.THIS_WEEK,
	["Last_Week"] = BF_ROLE_DATA_TYPE.LAST_WEEK,
}
local tAllMapIDs = {296, 645, 676, 709, 715}
local tTog2MapID = {
    [1] = 296,
    [2] = 296,
    [3] = 296,
    [4] = 296,
    [5] = 645,
    [6] = 676,
    [8] = 709,
}
local tTog2Activity = {
    [5] = 947,
    [6] = 937,
    [8] = 993,
}
local tTog2DataType =
{
	[1] = "History",
	[2] = "This_Week",
	[3] = "Last_Week",
}
local tMode2MapID =
{
	[1] = 709,
	[2] = 715,
}
local m_tSumPersonalInfo = nil
local m_tLastPersonalInfo = nil
local m_tThisPersonalInfo = nil

function PvPImpasseMatchingView:OnEnter(nNpcID, nType)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        UIHelper.AddPrefab(PREFAB_ID.WidgetSkillConfiguration, self.WidgetSkillConfiguration)
    end

    self.nType = 1
    self.dwNpcID = nNpcID
    self.dwMapID = 296
    self.nDataType = tDataType.History
    -- self.bOnlyShowData = (not nNpcID) and true or false
    self.bOnlyShowData = false

    if nType then
        local pActivityMgr = GetActivityMgrClient()
        if tTog2Activity[nType] and pActivityMgr.IsActivityOn(tTog2Activity[nType]) then
            self.nType = nType
        elseif not tTog2Activity[nType] then
            self.nType = nType
        end
    end

    local skinDetail = UIHelper.GetBindScript(self.WidgetAnchorSkillImg)
    local skinPage = UIHelper.GetBindScript(self.WidgetSkillList)
    skinPage:SetSkinDetailScript(skinDetail)

    UIHelper.SetCanSelect(self.tbTogTabList[7], false, "万物互联端暂不开放", true)

    self:UpdateInfo()
    self:UpdateCurrencyInfo()
    Timer.AddCycle(self, 0.5, function()
        self:OnUpdateTime()
    end)

    UIHelper.SetVisible(self.ImgBg, false)

    if nType and nType ~= 1 then
        self.dwMapID = tTog2MapID[nType]
        self:UpdateTogView()
        UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupTab, self.tbTogTabList[self.nType])
    end
end

function PvPImpasseMatchingView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer:DelAllTimer()
end

function PvPImpasseMatchingView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose,EventType.OnClick,function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnHelp,EventType.OnClick,function ()
        UIMgr.Open(VIEW_ID.PanelBattleFieldRulesNew, self.dwMapID, true)
    end)

    UIHelper.BindUIEvent(self.BtnHelp2,EventType.OnClick,function ()
        UIMgr.Open(VIEW_ID.PanelBattleFieldRulesNew, self.dwMapID, true)
    end)

    UIHelper.BindUIEvent(self.BtnMore,EventType.OnClick,function ()
        UIHelper.SetVisible(self.WidgetShowMore, true)
    end)

    for k,v in ipairs(self.tbTogTabList) do
        UIHelper.BindUIEvent(v,EventType.OnSelectChanged,function (_, bSelected)
            if not bSelected then
                return
            end
            self.nType = k
            self.dwMapID = tTog2MapID[k]
            self:UpdateTogView()
        end)
    end

    for k,v in ipairs(self.tbTogMartial) do
        UIHelper.BindUIEvent(v,EventType.OnClick,function ()
            self.nDataType = tDataType[tTog2DataType[k]]
            self:FlushRoleData(self.nDataType, self.dwMapID)
            self:UpdateLastPersonalInfo()
        end)
    end

    for k,v in ipairs(self.tbTogModeSelection) do
        UIHelper.SetToggleGroupIndex(v, ToggleGroupIndex.ExtractPVPMode)
        UIHelper.BindUIEvent(v,EventType.OnClick,function ()
            self.dwMapID = tMode2MapID[k]
            self:UpdateMatchMapInfo()
        end)
    end
    --个人匹配
    UIHelper.BindUIEvent(self.BtnPersonal,EventType.OnClick,function ()
        local tMapIDList = TreasureBattleFieldData.GetDownloadMapIDList()
        if not PakDownloadMgr.UserCheckDownloadMapRes(tMapIDList, nil, nil, nil, "绝境战场") then
            return
        end
        local bInQueue = BattleFieldQueueData.IsInBattleFieldQueue(self.dwMapID)
        if not bInQueue then
            if not BattleFieldQueueData.EnterBattleFieldQueue(self.dwMapID, BATTLEFIELD_MAP_TYPE.TREASUREBATTLE, false) then
                UIHelper.SetButtonState(self.BtnPersonal, BTN_STATE.Normal)
            end
        end
    end)

    --组队匹配
    UIHelper.BindUIEvent(self.BtnTeam,EventType.OnClick,function ()
        -- local tMapIDList = Table_GetAllTreasureBattleFieldMapID()
        -- if not PakDownloadMgr.UserCheckDownloadMapRes(tMapIDList, nil, nil, nil, "绝境战场") then
        --     return
        -- end
        if not TeamData.IsInParty() then
            local tRecruitInfo = Table_GetTeamInfoByMapID(self.dwMapID)
            if tRecruitInfo then
                UIMgr.Open(VIEW_ID.PanelTeam, 1, nil, tRecruitInfo.dwID)
            end
            return
        end
        if not TeamData.IsTeamLeader() then
            TipsHelper.ShowNormalTip("只有队长才能进行匹配")
            return
        end

        local nTeamMember = 0
        local bExtractMatchMap = TreasureBattleFieldData.IsExtractMatchMap(self.dwMapID)
        TeamData.Generator(function(dwID, tMemberInfo)
            nTeamMember = nTeamMember + 1
        end)
        if bExtractMatchMap and nTeamMember ~= 3 then
            TipsHelper.ShowNormalTip("队伍人数不符合奇境寻宝人数要求，无法参与奇境寻宝")
            return
        end

        -- UIHelper.SetButtonState(self.BtnTeam, BTN_STATE.Disable)
        local bInQueue = BattleFieldQueueData.IsInBattleFieldQueue(self.dwMapID)
        if not bInQueue then
            if not BattleFieldQueueData.EnterBattleFieldQueue(self.dwMapID, BATTLEFIELD_MAP_TYPE.TREASUREBATTLE, true) then
                UIHelper.SetButtonState(self.BtnTeam, BTN_STATE.Normal)
            end
        end
    end)

    --跨服匹配
    UIHelper.BindUIEvent(self.BtnRoom, EventType.OnClick, function()
        local bHaveRoom = RoomData.IsHaveRoom()
        if not bHaveRoom then
            local tRecruitInfo = Table_GetTeamInfoByMapID(self.dwMapID)
            if tRecruitInfo then
                UIMgr.Open(VIEW_ID.PanelTeam, 1, nil, tRecruitInfo.dwID)
            end
            return
        end

        local bIsRoomOwner = RoomData.IsRoomOwner()
        local bInBlackList = BattleFieldQueueData.IsInBattleFieldBlackList()
        local bCanOperateMatch = not bInBlackList
        local bCanJoinRoom = bCanOperateMatch and bIsRoomOwner
        local szRoomTip = "只有跨服房间房主才可进行跨服匹配"
        if not bCanJoinRoom then
            TipsHelper.ShowNormalTip(szRoomTip)
            return
        end

        local nRoomMember = RoomData.GetSize()
        local bExtractMatchMap = TreasureBattleFieldData.IsExtractMatchMap(self.dwMapID)
        if bExtractMatchMap and nRoomMember ~= 3 then
            TipsHelper.ShowNormalTip("房间人数不符合奇境寻宝人数要求，无法参与奇境寻宝")
            return
        end

        local bInQueue = BattleFieldQueueData.IsInBattleFieldQueue(self.dwMapID)
        if not bInQueue then
            if not BattleFieldQueueData.EnterBattleFieldQueue(self.dwMapID, BATTLEFIELD_MAP_TYPE.TREASUREBATTLE, false, true) then
                UIHelper.SetButtonState(self.BtnRoom, BTN_STATE.Normal)
            end
        end
    end)

    --取消匹配
    UIHelper.BindUIEvent(self.BtnMatching,EventType.OnClick,function ()
        -- UIHelper.SetButtonState(self.BtnMatching, BTN_STATE.Disable)
        if BattleFieldQueueData.IsInBattleFieldQueue(self.dwMapID) then
            BattleFieldQueueData.DoLeaveBattleFieldQueue(self.dwMapID)
        end
    end)

    --飞沙令商店
    UIHelper.BindUIEvent(self.BtnStageStore,EventType.OnClick,function ()
        if TreasureBattleFieldData.IsExtractMatchMap(self.dwMapID) then
            ShopData.OpenSystemShopGroup(27, 1536)
            return
        end

        ShopData.OpenSystemShopGroup(1, 1134)
    end)

    UIHelper.BindUIEvent(self.BtnTeamup, EventType.OnClick, function ()
        local tRecruitInfo = Table_GetTeamInfoByMapID(self.dwMapID)
        if tRecruitInfo then
            UIMgr.Open(VIEW_ID.PanelTeam, 1, nil, tRecruitInfo.dwID)
        end
    end)

    UIHelper.BindUIEvent(self.BtnSkills, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelXunBaoEquipSkillPop)
    end)

    UIHelper.BindUIEvent(self.BtnReputation, EventType.OnClick, function()
        if not self.tbReputationInfo then
            return
        end

        UIMgr.Open(VIEW_ID.PanelPlayerReputationPop, self.tbReputationInfo)
    end)

    UIHelper.BindUIEvent(self.BtnWarehouse, EventType.OnClick, function()
        ExtractWareHouseData.OpenExtractPersetPanel()
    end)

    UIHelper.BindUIEvent(self.BtnBalanceBuff, EventType.OnClick, function()
        local szText = ParseTextHelper.ParseNormalText(UIHelper.GetBuffTip(self.dwBuffID, self.dwBuffLevel))
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.BtnBalanceBuff, TipsLayoutDir.TOP_CENTER, szText)
    end)
end

function PvPImpasseMatchingView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    --个人战绩
    Event.Reg(self,"ON_SYNC_BF_ROLE_DATA",function (dwPlayerID,dwMapID,bUpdate,eType)
        self:UpdateBFRoleDate(dwPlayerID,dwMapID,bUpdate,eType)
        self:OnSyncBFRoleDate(dwPlayerID,dwMapID,bUpdate,eType)
        self:UpdateSumPersonalInfo()
        self:UpdateLastPersonalInfo()
    end)

    --飞沙令
    Event.Reg(self, "UPDATE_FEISHAWAND", function()
        self:UpdateFeiShaWandNumber()
    end)

    Event.Reg(self, "OnGetTreasureHuntReward", function()
        self:UpdateWeeklyGift()
    end)

    Event.Reg(self, EventType.OnTBFUpdateAllView, function()
        self:UpdateWeeklyGift()
    end)

    --战场状态更新（匹配状态等）
    Event.Reg(self, "BATTLE_FIELD_STATE_UPDATE", function()
        self:UpdateBtnState()
    end)

    Event.Reg(self, "JOIN_BATTLE_FIELD_QUEUE", function(dwMapID, nCode, dwRoleID, szRoleName)
        --若加入队列失败，则更新按钮状态
        if nCode ~= BATTLE_FIELD_RESULT_CODE.SUCCESS then
            self:UpdateBtnState()
        end
    end)

    --添加成员
    Event.Reg(self, "PARTY_ADD_MEMBER", function()
        self:UpdateBtnState()
    end)

    --删除成员
    Event.Reg(self, "PARTY_DELETE_MEMBER", function()
        self:UpdateBtnState()
    end)

    --队长变更
    Event.Reg(self, "TEAM_AUTHORITY_CHANGED", function()
        self:UpdateBtnState()
    end)

    --解散
    Event.Reg(self, "PARTY_DISBAND", function()
        self:UpdateBtnState()
    end)

    Event.Reg(self, "CREATE_GLOBAL_ROOM", function()
        self:UpdateBtnState()
    end)

    Event.Reg(self, "JOIN_GLOBAL_ROOM", function()
        self:UpdateBtnState()
    end)

    Event.Reg(self, "LEAVE_GLOBAL_ROOM", function()
        self:UpdateBtnState()
    end)

    Event.Reg(self, "GLOBAL_ROOM_BASE_INFO", function()
        self:UpdateBtnState()
    end)

    Event.Reg(self, "GLOBAL_ROOM_MEMBER_CHANGE", function()
        self:UpdateBtnState()
    end)

    Event.Reg(self, "GLOBAL_ROOM_DETAIL_INFO", function()
        self:UpdateBtnState()
    end)

    Event.Reg(self, EventType.OnClientPlayerLeave, function (nPlayerID)
        UIMgr.Close(self)
    end)

    Event.Reg(self, "BATTLE_FIELD_UPDATE_TIME", function ()
        self:UpdateMatchTime()
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function ()
        UIHelper.SetVisible(self.WidgetShowMore, false)
    end)

    --信誉分
    Event.Reg(self, EventType.OnGetPrestigeInfoRespond, function(dwPlayerID, tbInfo)
        if dwPlayerID == g_pClientPlayer.dwID then
            self.tbReputationInfo = tbInfo
        end
    end)

    Event.Reg(self, EventType.UpdateTreasureBattleFieldRoomInfo, function()
        if self.nType == 7 then
            self:UpdateRoomInfo()
        end
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function ()
        Timer.AddFrame(self, 1, function ()
            UIHelper.LayoutDoLayout(self.LayoutLeftBottom)
        end)
    end)
end

function PvPImpasseMatchingView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function PvPImpasseMatchingView:UpdateInfo()
    RemoteCallToServer("On_XinYu_GetInfo", g_pClientPlayer.dwID)

    for k,v in ipairs(self.tbTogTabList) do
        if self.bOnlyShowData and k~=1 then
            UIHelper.ToggleGroupAddToggle(self.ToggleGroupTab,v)
        elseif not self.bOnlyShowData then
            UIHelper.ToggleGroupAddToggle(self.ToggleGroupTab,v)
        end
    end

    self:InitPersonalInfoTog()
    for k,v in ipairs(self.tbTogMartial) do
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupStandings,v)
    end

    self:InitBlackStateTime()

    if self.bOnlyShowData then
        UIHelper.SetVisible(self.TogTabList, not self.bOnlyShowData)
        -- UIHelper.SetSelected(self.TogTabList01,true)
        self.nType = 2
    end
    self:UpdateTogView()

    RemoteCallToServer("On_Zhanchang_Remain")
    self:FlushRoleData(tDataType.This_Week, self.dwMapID)
    self:FlushRoleData(tDataType.Last_Week, self.dwMapID)

    local pActivityMgr = GetActivityMgrClient()
    for nTogID, tog in ipairs(self.tbTogTabList) do
        if tTog2Activity[nTogID] then
            UIHelper.SetVisible(tog, pActivityMgr.IsActivityOn(tTog2Activity[nTogID]))
        else
            UIHelper.SetVisible(tog, true)
        end
    end
    UIHelper.LayoutDoLayout(self.WidgetLeftList1)
end

--更新匹配/惩罚时间
function PvPImpasseMatchingView:OnUpdateTime()
    local player = g_pClientPlayer
    if self.dwNpcID then
        local npc = GetNpc(self.dwNpcID)
        if not npc or not npc.CanDialog(player) then
            UIMgr.Close(self)
        end
    end
    self:UpdateMatchTime()
    self:UpdateBlackStateTime()
end

--匹配时间
function PvPImpasseMatchingView:InitMatchTime(dwMapID)
    self.m_bUpdateMatchTime = true
    local nTime = BattleFieldQueueData.GetJoinBattleQueueTime(dwMapID)
    local nCurrentTime = GetCurrentTime()
    if nTime then
        self.m_nMatchStartTime = nCurrentTime - nTime
    else
        self.m_nMatchStartTime = nil
    end
    self.m_bUpdateMatchTime = false
end

--界面上更新匹配时间
function PvPImpasseMatchingView:UpdateMatchTime()
    if self.m_nMatchStartTime and not self.m_bUpdateMatchTime then
        local nTime = GetCurrentTime()
        local nShowTime = nTime - self.m_nMatchStartTime

        local dwMapID = self.dwMapID
        local bInQueue = BattleFieldQueueData.IsInBattleFieldQueue(dwMapID)

        if not bInQueue then
            return
        end

        local szTime = BattleFieldQueueData.FormatBattleFieldTime(nShowTime)

        local nPassTime, nAvgQueueTime = BattleFieldQueueData.GetQueueTime()
        szTime = "已匹配 " .. szTime .. "  预计排队 ".. BattleFieldQueueData.FormatBattleFieldTime(nAvgQueueTime)

        UIHelper.SetString(self.LabelMatchingTime, szTime)
    end
end

--惩罚时间
function PvPImpasseMatchingView:InitBlackStateTime()
    self.m_bUpdateBlackTime = true
    local nTime = BattleFieldQueueData.GetBattleFieldBlackCoolTime()
    local nCurrentTime = GetCurrentTime()
    if nTime then
        self.m_nBlackEndTime = nTime + nCurrentTime
    else
        self.m_nBlackEndTime = nil
    end
    self.m_bUpdateBlackTime = false
end

--惩罚时间更新
function PvPImpasseMatchingView:UpdateBlackStateTime()
    if self.m_nBlackEndTime and not self.m_bUpdateBlackTime then
        local nTime = GetCurrentTime()
        local nShowTime = self.m_nBlackEndTime - nTime
        if nShowTime < 0 then
            nShowTime = 0
        end

        if not BattleFieldQueueData.IsInBattleFieldBlackList() then
            return
        end

        local szTime = "<color=#FFE4A3>" .. BattleFieldQueueData.NumberBattleFieldTime(nShowTime) .. "</color>"
        UIHelper.SetRichText(self.LabelTime, FormatString(g_tStrings.STR_BATTLEFIELD_BLACK_LIST, szTime))
    end
end

function PvPImpasseMatchingView:UpdateMatchMapInfo()
    self.tApplyDataRecord = self.tApplyDataRecord or {}
    if not self.tApplyDataRecord[self.dwMapID] then
        BattleFieldData.RequestBFRoleData(self.dwMapID)
        self.tApplyDataRecord[self.dwMapID] = true
    end
    local nScore = BattleFieldQueueData.tTempPersonalScore and BattleFieldQueueData.tTempPersonalScore[self.dwMapID]
    if nScore then
        UIHelper.SetString(self.LabelNum, nScore)
        if self.dwMapID == 296 then
            UIHelper.SetString(self.LabelArenaGrade, nScore)
        end
    end
    local bSingleMatchMap = TreasureBattleFieldData.IsSingleMatchMap(self.dwMapID)
    local bSkillMatchMap = TreasureBattleFieldData.IsSkillMatchMap(self.dwMapID)
    local bExtractMatchMap = TreasureBattleFieldData.IsExtractMatchMap(self.dwMapID)
    local szDesc = ""
    if bSingleMatchMap then
        szDesc = g_tStrings.STR_SINGLE_TREASURE_BATTLE_FIELD_DESC
    elseif bSkillMatchMap then
        szDesc = g_tStrings.STR_SKILL_TREASURE_BATTLE_FIELD_DESC
    elseif bExtractMatchMap then
        szDesc = self.dwMapID == tMode2MapID[1] and g_tStrings.STR_NORMALSDC_TREASURE_BATTLE_FIELD_DESC or g_tStrings.STR_HARDLSDC_TREASURE_BATTLE_FIELD_DESC
    else
        szDesc = g_tStrings.STR_NORMAL_TREASURE_BATTLE_FIELD_DESC
    end
    UIHelper.SetString(self.LabelReward, szDesc)
    UIHelper.LayoutDoLayout(self.LayoutLabelBg)
    UIHelper.LayoutDoLayout(self.LayoutText)
    UIHelper.SetVisible(self.BtnTeamup, not bSingleMatchMap)
    UIHelper.SetVisible(self.BtnSkills, bSkillMatchMap)
    UIHelper.SetVisible(self.WidgetReward, bExtractMatchMap)
    UIHelper.SetVisible(self.BtnWarehouse, bExtractMatchMap)
    UIHelper.LayoutDoLayout(self.WidgetBtnPlus)
    self:UpdateBtnState()
    self:UpdateWeeklyGift()
end

local function fnExtractMatchCheck(bExtractMatchMap)
    if not bExtractMatchMap then
        return true, true
    end

    if IsDebugClient() then
        return true, true
    end

    local nSingleActID = ACTIVITY_ID.TREASURE_HUNT_SINGLE
    local nTeamActID = ACTIVITY_ID.TREASURE_HUNT_TEAM
    local bPersonalActivity = false
    local bTeamActivity = false

    -- local pActivityMgr = GetActivityMgrClient()
    bPersonalActivity = IsActivityOn(nSingleActID)
    bTeamActivity = IsActivityOn(nTeamActID)

    return bPersonalActivity, bTeamActivity
end

function PvPImpasseMatchingView:UpdateBtnState()
    local bSingleMatchMap = TreasureBattleFieldData.IsSingleMatchMap(self.dwMapID)
    local bExtractMatchMap = TreasureBattleFieldData.IsExtractMatchMap(self.dwMapID)
    local bSkillMap = TreasureBattleFieldData.IsSkillMatchMap(self.dwMapID)
    local bInQueue, bSingle, bGlobalRoom = BattleFieldQueueData.IsInBattleFieldQueue(self.dwMapID)
    local bInBlackList = BattleFieldQueueData.IsInBattleFieldBlackList()

    local bExtractActivity_Personal, bExtractActivity_Team = fnExtractMatchCheck(bExtractMatchMap)

    local bCanOperateMatch = not bInBlackList
    local szMatchTips_Single = nil
    local szMatchTips_Team = nil
    if bExtractMatchMap and bCanOperateMatch then
        szMatchTips_Single = not bExtractActivity_Personal and g_tStrings.STR_XUNBAO_MATCH_TIME_SINGLE or nil
        szMatchTips_Team = not bExtractActivity_Team and g_tStrings.STR_XUNBAO_MATCH_TIME_TEAM or nil
    end

    UIHelper.SetVisible(self.LabelTime, bInBlackList)
    UIHelper.SetVisible(self.LabelMatchingTime, bInQueue)
    UIHelper.SetVisible(self.BtnPersonal, not bInQueue)
    UIHelper.SetVisible(self.BtnMatching, bInQueue)
    UIHelper.SetVisible(self.BtnTeam, not bInQueue and not bSingleMatchMap)
    UIHelper.SetVisible(self.BtnRoom, not bInQueue and not bSingleMatchMap)
    UIHelper.SetVisible(self.WidgetBtnList, not bInQueue and not bSingleMatchMap)
    UIHelper.SetVisible(self.WidgetModeSelection, false) -- 关闭纷争场直接隐藏了就好，不然单独留一个很难看
    UIHelper.SetVisible(self.WidgetSkillConfiguration, not bExtractMatchMap and not bSkillMap)
    UIHelper.SetVisible(self.BtnDetail2, false)

    UIHelper.SetButtonState(self.BtnPersonal, (bCanOperateMatch and bExtractActivity_Personal) and BTN_STATE.Normal or BTN_STATE.Disable, szMatchTips_Single)
    UIHelper.SetButtonState(self.BtnTeam, (bCanOperateMatch and bExtractActivity_Team) and BTN_STATE.Normal or BTN_STATE.Disable, szMatchTips_Team)
    UIHelper.SetButtonState(self.BtnMatching, bInQueue and BTN_STATE.Normal or BTN_STATE.Disable)
    UIHelper.SetButtonState(self.BtnRoom, (bCanOperateMatch and bExtractActivity_Team) and BTN_STATE.Normal or BTN_STATE.Disable, szMatchTips_Team)

    if bInQueue then
        self:InitMatchTime(self.dwMapID)
    elseif bInBlackList then
        self:InitBlackStateTime()
    end

    UIHelper.LayoutDoLayout(self.LayoutText)
end

function PvPImpasseMatchingView:UpdateTogView()
    UIHelper.SetVisible(self.WidgetAnchorRight1,self.nType == 1 or self.nType == 5 or self.nType == 6 or self.nType == 8)
    UIHelper.SetVisible(self.WidgetAnchorRight2,self.nType == 2 or self.nType == 3)
    UIHelper.SetVisible(self.WIdgetScore,self.nType == 2 or self.nType == 3)
    UIHelper.SetVisible(self.WidgetMvp,self.nType == 2)
    UIHelper.SetVisible(self.WidgetStatistics,self.nType == 3)
    --UIHelper.SetVisible(self.ImgBg1,self.nType == 2 or self.nType == 3)
    --UIHelper.SetVisible(self.ImgBg2,self.nType == 2 or self.nType == 3)
    UIHelper.SetVisible(self.WidgetSkillList, self.nType == 4)
    UIHelper.SetVisible(self.WidgetAnchorRigh3, self.nType == 4)
    UIHelper.SetVisible(self.WidgetRoomNumber, self.nType == 7)
    UIHelper.SetVisible(self.WidgetRoomMessage, self.nType == 7)
    UIHelper.SetVisible(self.WidgetAnchorRight4, self.nType == 7)
    UIHelper.SetVisible(self.WidgetAnchorRight5, self.nType == 7)
    UIHelper.SetVisible(self.WidgetGrade, self.nType == 1 or self.nType == 5 or self.nType == 6)
    UIHelper.SetVisible(self.WidgetFavorabilitySlider, self.nType == 8)
    UIHelper.SetVisible(self.WidgetRemainDetail, self.nType ~= 8)
    UIHelper.SetVisible(self.BtnHelp2, self.nType == 8)
    UIHelper.SetSelected(self.tbTogModeSelection[1], self.nType == 8)
    UIHelper.SetSelected(self.tbTogModeSelection[2], false)
    UIHelper.LayoutDoLayout(self.LayoutLeftBottom)

    if self.nType == 1 or self.nType == 5 or self.nType == 6 or self.nType == 8 then
        self:UpdateMatchMapInfo()
    elseif self.nType == 2 then
        self:UpdateSumPersonalInfo()
    elseif self.nType == 3 then
        self:UpdateLastPersonalInfo()
    elseif self.nType == 7 then
        self:UpdateRoomInfo()
    end
    self:UpdateBanlanceBuff()
    self:UpdateCurrencyInfo()

    --资源下载Widget
    local scriptDownload = UIHelper.GetBindScript(self.WidgetDownload)
    local tPackIDList = PakDownloadMgr.GetPackIDListInPackTree(PACKTREE_ID.TreasureBF)
    scriptDownload:OnInitWithPackIDList(tPackIDList)

    -- 寻宝模式教学
    if self.nType == 8 and TeachEvent.CheckCondition(47) then
        Timer.Add(self, 0.5, function ()
            TeachEvent.TeachStart(47)
        end)
    end
end

function PvPImpasseMatchingView:UpdateBanlanceBuff()
    local bShow = false
    local dwMkungfuID = UI_GetPlayerMountKungfuID()
    local tBanlanceBuff = Table_GetTreasureBalanceBuff(dwMkungfuID)
    if not tBanlanceBuff then
        UIHelper.SetVisible(self.BtnBalanceBuff, false)
        return
    end

    local tMapInfo = Table_GetBFCustomRoomMapInfo(self.dwMapID)
    if not tMapInfo then
         UIHelper.SetVisible(self.BtnBalanceBuff, false)
        return
    end

    local nRoomType   = tMapInfo.nRoomType
    local szBuff      = tBanlanceBuff["szBuff"..nRoomType] or ""
    local t           = SplitString(szBuff, "_")
    local dwBuffID    = tonumber(t[1])
    local dwBuffLevel = tonumber(t[2]) or 0

    if not dwBuffID or dwBuffID == 0 then
        UIHelper.SetVisible(self.BtnBalanceBuff, false)
        return
    end
    self.dwBuffID = dwBuffID
    self.dwBuffLevel = dwBuffLevel
    UIHelper.SetVisible(self.BtnBalanceBuff, true)

    local nIconID = Table_GetBuffIconID(dwBuffID, dwBuffLevel)
    local szPath = UIHelper.GetIconPathByIconID(nIconID)
    UIHelper.SetTexture(self.ImgBalanceBuff, szPath, true)

end

function PvPImpasseMatchingView:OnSyncBFRoleDate(dwPlayerID,dwMapID,bUpdate,eType)
    if eType ~= BF_ROLE_DATA_TYPE.HISTORY then
		return
	end
	if dwPlayerID ~= UI_GetClientPlayerID() then
		return
	end
    if not FindTableValue(tAllMapIDs, dwMapID) then
		return
	end
    local tPersonalInfo = GetBFRoleData(dwPlayerID, dwMapID, eType)
    local nScore = tPersonalInfo[nPersonalScoreIndex]
    BattleFieldQueueData.tTempPersonalScore = BattleFieldQueueData.tTempPersonalScore or {}
    BattleFieldQueueData.tTempPersonalScore[dwMapID] = tostring(nScore)
    if self.dwMapID == dwMapID then
        UIHelper.SetString(self.LabelNum, nScore)
        if dwMapID == 296 then
            UIHelper.SetString(self.LabelArenaGrade, nScore)
        end
    end
    RemoteCallToServer("On_Zhanchang_Remain")
end

function PvPImpasseMatchingView:UpdateFeiShaWandNumber()
    if not m_tSumPersonalInfo then
		return
	end

    local dwRemainNumber = BattleFieldData.dwFeishaRemainNum
    local dwProcessNumber = BattleFieldData.dwFeishaProcessNum

    local nStageWandMax = 1010 --周上限改成了固定值 参见这个STR_FEISHA_TIP
	local nAcquireNum = nStageWandMax - dwRemainNumber
	if nAcquireNum < 0 then
		nAcquireNum = 0
	end

    self.coinScript = self.coinScript or UIHelper.AddPrefab(PREFAB_ID.WidgetCoin, self.WidgetPVPMoney, CurrencyType.FeiShaWand)

    UIHelper.SetString(self.LabelExtraNum,nAcquireNum)
    UIHelper.SetString(self.LabelWeekNum,nAcquireNum)
    UIHelper.SetString(self.LabelTotalNum,dwProcessNumber)

    UIHelper.LayoutDoLayout(self.WIdgetRightTop)
end

function PvPImpasseMatchingView:InitPersonalInfoTog()
    self.StatisticsDatescript = {}
    for k,dwDataIndex in ipairs(tPastPersonInfoItem) do
        local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetPlayerNum,self.ScrollViewStatistics)
        UIHelper.SetString(scriptCell.LabelPlayerNum,g_tStrings.tDesertStorm[dwDataIndex])
        table.insert(self.StatisticsDatescript,scriptCell)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewMvp)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewStatistics)
end

function PvPImpasseMatchingView:UpdateBFRoleDate(dwPlayerID,dwMapID,bUpdate,eType)
    if dwPlayerID ~= UI_GetClientPlayerID() then
        return
    end
    if not FindTableValue(tAllMapIDs, dwMapID) then
		return
	end
    if dwMapID ~= 296 then
        return
    end
    if eType == tDataType.History then
		m_tSumPersonalInfo = GetBFRoleData(dwPlayerID, dwMapID, eType)
		RemoteCallToServer("On_Zhanchang_Remain")
	elseif eType == tDataType.Last_Week then
		m_tLastPersonalInfo = GetBFRoleData(dwPlayerID, dwMapID, eType)
	elseif eType == tDataType.This_Week then
		m_tThisPersonalInfo = GetBFRoleData(dwPlayerID, dwMapID, eType)
	end
end

--个人数据
function PvPImpasseMatchingView:UpdateSumPersonalInfo()
    if not m_tSumPersonalInfo then
        return
    end

    for k,dwDataIndex in ipairs(tBestPersonInfoItem) do
        UIHelper.SetString(self.tbLabelMvpNum[k] ,m_tSumPersonalInfo[dwDataIndex])
    end
end

--历史数据
function PvPImpasseMatchingView:UpdateLastPersonalInfo()
    local eType = self.nDataType
    local tFlushData
    if eType == tDataType.History then
		tFlushData = m_tSumPersonalInfo
	elseif eType == tDataType.Last_Week then
		tFlushData = m_tLastPersonalInfo
	elseif  eType == tDataType.This_Week then
		tFlushData = m_tThisPersonalInfo
	end

    if not tFlushData then
		return
	end

    for k, dwDataIndex in pairs(tPastPersonInfoItem) do
        if dwDataIndex ~= BF_MAP_ROLE_INFO_TYPE.SUM_LIVE_COUNT then
            UIHelper.SetString(self.StatisticsDatescript[k].LabelPlayerNumTitle, tFlushData[dwDataIndex])
        else
            local dwSourceNum
			if tFlushData[BF_MAP_ROLE_INFO_TYPE.BATTLE_ROUNDS] ~= 0 then
				dwSourceNum = math.floor(tFlushData[dwDataIndex] / tFlushData[BF_MAP_ROLE_INFO_TYPE.BATTLE_ROUNDS])
			else
				dwSourceNum = 0
			end
            UIHelper.SetString(self.StatisticsDatescript[k].LabelPlayerNumTitle, dwSourceNum)
        end
        UIHelper.SetSpriteFrame(self.StatisticsDatescript[k].IconPlayerNum, tPvpImpasseImg[k])
    end
end

-- --个人数据的消息获取手段
-- if CanApplyBFRoleData() then
--     ApplyBFRoleData(UI_GetClientPlayerID(), dwMapID, false)
-- else
--     DelayCall(500, OnPlayerEnterScene)
-- end
-- local tData = GetBFRoleData(dwPlayerID, dwMapID)
-- BF_MAP_ROLE_INFO_TYPE.KILL_COUNT -- 个人最佳击伤
-- TOTAL_DAMAGE -- 最佳伤害量
-- ASSIST_KILL_COUNT --最佳协杀
-- BATTLE_ROUNDS -- 总场次
-- SUM_LIVE_COUNT -- 每场名次总和
-- SUM_KILL_COUNT --  总击伤
-- SUM_ASSIST_KILL_COUNT--总协杀
-- TOP_COUNT --夺冠次数、
-- MATCH_LEVEL-- -- 隐藏分
--eType 值类
-- HISTORY      总积分数据
-- THIS_WEEK    当周的积分数据
-- LAST_WEEK    上周的积分数据
function PvPImpasseMatchingView:FlushRoleData(eType, dwMapID)
    if CanApplyBFRoleData(eType, dwMapID) then
        ApplyBFRoleData(UI_GetClientPlayerID(), dwMapID, false, eType)
    else
        Timer.Add(self,1,function ()
            self:FlushRoleData(eType, dwMapID)
        end)
    end
end

function PvPImpasseMatchingView:UpdateRoomInfo()
    if not TreasureBattleFieldData.tCurRoomInfo then
        local script = UIHelper.GetBindScript(self.WidgetRoomNumber)
        script:UpdateInfo()
    else
        local script = UIHelper.GetBindScript(self.WidgetRoomMessage)
        script:UpdateInfo()
    end
    UIHelper.SetVisible(self.WidgetRoomNumber, TreasureBattleFieldData.tCurRoomInfo == nil)
    UIHelper.SetVisible(self.WidgetRoomMessage, TreasureBattleFieldData.tCurRoomInfo ~= nil)
    UIHelper.SetVisible(self.WidgetAnchorRight4, TreasureBattleFieldData.tCurRoomInfo ~= nil)
end

function PvPImpasseMatchingView:UpdateCurrencyInfo()
    if not self.scriptExamPrint then
        self.scriptExamPrint = UIHelper.AddPrefab(PREFAB_ID.WidgetOtherCurrency, self.WidgetPVPMoney)
        self.scriptExamPrint:SetCurrencyType(CurrencyType.ExamPrint)
        self.scriptExamPrint:HandleEvent()
    end

    UIHelper.SetVisible(self.scriptExamPrint._rootNode, self.nType == 8)
    if self.coinScript then
        UIHelper.SetVisible(self.coinScript._rootNode, self.nType ~= 8)
    end
    UIHelper.LayoutDoLayout(self.WidgetPVPMoney)
end

function PvPImpasseMatchingView:UpdateWeeklyGift()
    local bExtractMatchMap = TreasureBattleFieldData.IsExtractMatchMap(self.dwMapID)
    if not bExtractMatchMap then
        return
    end

    local tList = {}
    local bCanGet, szRewrd = GDAPI_TbfWeeklyReward()
    local tItems = SplitString(szRewrd, ";")
    for nIndex, szItem in ipairs(tItems) do
        local tItem = SplitString(szItem, "_")
        if tItem then
            local nTabType = tItem[1]
            local nTabIndex = tItem[2]
            local nCount = tItem[3]
            table.insert(tList, {nTabType, nTabIndex, nCount})
        end
    end
    UIHelper.SetVisible(self.BtnMore, #tList > #self.tbRewardWidget)

    local _fnInitItem = function(scriptIcon, tItem)
        local nTabType = tonumber(tItem[1])
        local nTabIndex = tonumber(tItem[2])
        local nCount = tonumber(tItem[3])
        local bCurrency = tItem[1] == "COIN"
        local tbLine = Table_GetCalenderActivityAwardIconByID(tonumber(tItem[2])) or {}
        local szCurrencyType = tbLine.szName
        if bCurrency then
            scriptIcon:OnInitWithCurrencyType(szCurrencyType)
        else
            scriptIcon:OnInitWithTabID(nTabType, nTabIndex)
        end
        scriptIcon:SetLabelCount(nCount)
        scriptIcon:SetItemReceived(not bCanGet)
        scriptIcon:SetClickCallback(function ()
            if bCanGet then
                RemoteCallToServer("On_JueJing_GetWeekReward")
                return
            end
            local nType = bCurrency and "CurrencyType" or nTabType
            local nIndex = bCurrency and CurrencyNameToType[szCurrencyType] or nTabIndex
            TipsHelper.ShowItemTips(scriptIcon._rootNode, nType, nIndex, false)
        end)
    end

    for index, widget in ipairs(self.tbRewardWidget) do
        local tItem = tList[index]
        local script = UIHelper.GetBindScript(widget)
        UIHelper.SetVisible(script.ImgAvailable20, bCanGet)
        UIHelper.RemoveAllChildren(script.WidgetItem)
        if tItem then
            local scriptIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, script.WidgetItem)
            scriptIcon:SetClearSeletedOnCloseAllHoverTips(true)
            _fnInitItem(scriptIcon, tItem)
        else
            UIHelper.SetVisible(script._rootNode, false)
        end
    end

    for nIndex, tItem in ipairs(tList) do
        if nIndex > #self.tbRewardWidget then
            local scriptIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.LayoutRewardItem44)
            scriptIcon:SetClearSeletedOnCloseAllHoverTips(true)
            _fnInitItem(scriptIcon, tItem)
        end
        UIHelper.LayoutDoLayout(self.LayoutRewardItem44)
    end
end

return PvPImpasseMatchingView