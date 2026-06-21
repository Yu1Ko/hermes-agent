-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIArenaModeSelectView
-- Date: 2022-12-06 14:39:21
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIArenaModeSelectView = class("UIArenaModeSelectView")

local ARENA_MODE_TYPE = {
    ARENA_2V2           = 1,
    ARENA_3V3           = 2,
    ARENA_5V5           = 3,
    ARENA_PRACTICE      = 4,
    ARENA_MASTER_3V3    = 5,
    ARENA_1V1           = 6,
}

local ARENA_TYPE_2ID = {
    [0] = 229,
    [1] = 230,
    [2] = 231,
}

local tArenaRecruit = {
	[ARENA_UI_TYPE.ARENA_2V2] = 1,
	[ARENA_UI_TYPE.ARENA_3V3] = 2,
	[ARENA_UI_TYPE.ARENA_5V5] = 3,
	[ARENA_UI_TYPE.ARENA_MASTER_3V3] = 4,
}

local ARENA_MASTER_NPC_LINK_ID = 2731
local ARENA_MASTER_ACTIVITY_ID = 395
local ARENA_MASTER_WEEKLYCOUNT_BUFFID = 12868

local ARENA_SOLO_ACTIVITY_ID = 980

function UIArenaModeSelectView:OnEnter(nNpcID, nCurSelectMode, bLockMode)
    self.nNpcID = nNpcID
    self.nCurSelectMode = self:CheckCurQueueType() or nCurSelectMode or ARENA_MODE_TYPE.ARENA_2V2
    if ArenaData.GetUISelectIndex() and not bLockMode then
        self.nCurSelectMode = ArenaData.GetUISelectIndex()
    end
    self:CheckSelectModeVaild()

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        UIHelper.AddPrefab(PREFAB_ID.WidgetSkillConfiguration, self.WidgetSkillConfiguration)
        UIHelper.AddPrefab(PREFAB_ID.WidgetSkillConfiguration, self.WidgetSkillConfigurationDss)
    end

    local nSelfPlayerID = PlayerData.GetPlayerID()
    ArenaData.SetPlayerIDByPeek(nSelfPlayerID)
    SyncCorpsList(nSelfPlayerID)
    ArenaData.SyncAllCorpsBaseInfo()
    ArenaData.GetLevelAwardInfo()
    ArenaData.GetMasterBuffCustomValue()

    self:UpdateInfo()
    self:UpdateCurrencyInfo()
    self:UpdateWinRewardInfo()
    self:UpdateRewardInfo()
    self:UpdateMasterRewardInfo()
    self:UpdateModeToggleState()

    UIHelper.SetToggleGroupSelected(self.ToggleGroupTab, self.nCurSelectMode - 1)

    --资源下载Widget
    local tMapIDList = ArenaData.GetMapList()
    local tPackIDList = {}
    for _, nMapID in ipairs(tMapIDList) do
        local nPackID = PakDownloadMgr.GetMapResPackID(nMapID)
        table.insert(tPackIDList, nPackID)
    end

    local scriptDownload = UIHelper.GetBindScript(self.WidgetDownload)
    scriptDownload:OnInitWithPackIDList(tPackIDList)

    RemoteCallToServer("On_XinYu_GetInfo", g_pClientPlayer.dwID)
end

function UIArenaModeSelectView:OnExit()
    self.bInit = false
end

function UIArenaModeSelectView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnEstablish, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelSetUpPractise)
    end)

    UIHelper.BindUIEvent(self.BtnJoin, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelJoinPractice)
    end)

    UIHelper.BindUIEvent(self.BtnRankReward, EventType.OnClick, function()
        local nArenaType = self:GetCurArenaType()
        UIMgr.Open(VIEW_ID.PanelPvPArenaReward, nArenaType)
    end)

    UIHelper.BindUIEvent(self.BtnPersonageMatching, EventType.OnClick, function()
        local _, _, nQueueArenaType = ArenaData.GetQueueTime()
        if nQueueArenaType then
            TipsHelper.ShowNormalTip("正在名剑大会排队中,不能加入名剑大会等待队列。")
            return
        end

        local nArenaType = self:GetCurArenaType()
        ArenaData.JoinArenaQueue(nArenaType, true, ARENA_GAME_TYPE.NORMAL)
    end)

    UIHelper.BindUIEvent(self.BtnTeamMatching, EventType.OnClick, function()
        local _, _, nQueueArenaType = ArenaData.GetQueueTime()
        if nQueueArenaType then
            TipsHelper.ShowNormalTip("正在名剑大会排队中,不能加入名剑大会等待队列。")
            return
        end

        local nArenaType = self:GetCurArenaType()
        local player = PlayerData.GetClientPlayer()
        if not player.IsInParty() then
            UIHelper.SimulateClick(self.BtnTeamup)
            return
        end

        ArenaData.JoinArenaQueue(nArenaType, false, ARENA_GAME_TYPE.NORMAL)
    end)

    UIHelper.BindUIEvent(self.BtnRoomMatching, EventType.OnClick, function()
        local _, _, nQueueArenaType = ArenaData.GetQueueTime()
        if nQueueArenaType then
            TipsHelper.ShowNormalTip("正在名剑大会排队中,不能加入名剑大会等待队列。")
            return
        end

        local nArenaType = self:GetCurArenaType()
        ArenaData.JoinRoomArena(nArenaType)
    end)


    UIHelper.BindUIEvent(self.BtnAwait, EventType.OnClick, function()
        local nArenaType = self:GetCurArenaType()
        local bInQueue, bSingle = ArenaData.IsInArenaQueue(nArenaType)
        if not bInQueue then
            return
        end

        ArenaData.LeaveArenaQueue()
        -- PvpEnterConfirmationData.OpenView(
        --     PlayEnterConfirmationType.InQueue,
        --     PlayType.Arena,
        --     {
        --         szTitle = "名剑大会排队中",
        --         onClickCancelQueue = function ()
        --             ArenaData.LeaveArenaQueue()
        --         end
        --     })
    end)

    UIHelper.BindUIEvent(self.BtnQuitRoom, EventType.OnClick, function()
        ArenaData.LeaveArenaQueue()
    end)

    UIHelper.BindUIEvent(self.BtnUpperLimit, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelPvPArenaIntegralPop)
    end)

    UIHelper.BindUIEvent(self.BtnDrill, EventType.OnClick, function(btn)
        UIMgr.Open(VIEW_ID.PanelCreateMartial)
    end)

    UIHelper.BindUIEvent(self.BtnDrillQuit, EventType.OnClick, function(btn)
        ArenaData.LeaveArenaQueue()
    end)

    UIHelper.BindUIEvent(self.BtnCopy, EventType.OnClick, function()
        local nRoomKey = ArenaData.GetCacheData("nRoomKey")
        ChatHelper.AppendToChat(string.format("名剑大会练习房-房间号：%d，快来人啦！", nRoomKey), false)
    end)

    for i, tog in ipairs(self.tbTogMode) do
        UIHelper.SetClickInterval(tog, 0)
        UIHelper.BindUIEvent(tog, EventType.OnClick, function()
            self.nCurSelectMode = i
            self:CheckSelectModeVaild()
            UIHelper.SetToggleGroupSelected(self.ToggleGroupTab, self.nCurSelectMode - 1)
            self:UpdateInfo()

            if self.tbWinRewardItem then
                for _, cell in ipairs(self.tbWinRewardItem) do
                    cell:SetSelected(false)
                end
            end

            if self.scriptWinRewardItemTip then
                self.scriptWinRewardItemTip:OnInitWithTabID()
            end

            ArenaData.SetUISelectIndex(self.nCurSelectMode)
        end)

        UIHelper.ToggleGroupAddToggle(self.ToggleGroupTab, tog)
    end
    UIHelper.BindUIEvent(self.LayoutMoney, EventType.OnClick, function()
        CurrencyData.ShowCurrencyHoverTips(self.LayoutMoney, CurrencyType.Prestige)
    end)
    UIHelper.SetTouchEnabled(self.LayoutMoney, true)

    UIHelper.BindUIEvent(self.BtnStageStore, EventType.OnClick, function()
        if self.nCurSelectMode == ARENA_MODE_TYPE.ARENA_MASTER_3V3 then
            ShopData.OpenSystemShopGroup(1, 1474)
        else
            ShopData.OpenSystemShopGroup(1, 918)
        end
    end)

    UIHelper.BindUIEvent(self.BtnRank, EventType.OnClick, function()
        if self.nCurSelectMode == ARENA_MODE_TYPE.ARENA_MASTER_3V3 then
            UIMgr.Open(VIEW_ID.PanelFengYunLu, FengYunLuCategory.ArenaMaster, 1)
        elseif self.nCurSelectMode == ARENA_MODE_TYPE.ARENA_1V1 then
            UIMgr.Open(VIEW_ID.PanelFengYunLu, FengYunLuCategory.School1V1, 1)
        end
    end)

    UIHelper.BindUIEvent(self.BtnTeamup, EventType.OnClick, function()
        local nArenaType = self:GetCurArenaType()
        local dwID = tArenaRecruit[nArenaType]
		local tInfo = Table_GetQuickTeamRecruit(dwID)
        if tInfo then
            UIMgr.Open(VIEW_ID.PanelTeam, 1, nil, tInfo.nRecruit)
        end
    end)

    UIHelper.BindUIEvent(self.BtnMoreData, EventType.OnClick, function()
        self.bShowCorps = true
        self:UpdateShowCorps(true)
    end)

    UIHelper.BindUIEvent(self.BtnPutData, EventType.OnClick, function()
        self.bShowCorps = false
        self:UpdateShowCorps(true)
    end)

    UIHelper.BindUIEvent(self.BtnShowRankRewardTips, EventType.OnClick, function()
        local bShow = not UIHelper.GetVisible(self.LayoutRankRewardInfo)
        UIHelper.SetVisible(self.LayoutRankRewardInfo, bShow)
    end)

    UIHelper.BindUIEvent(self.BtnHelpRule, EventType.OnClick, function(btn)
        local nPlayerID = PlayerData.GetPlayerID()
        local nArenaType = self:GetCurArenaType()
        local tbArenaInfo = ArenaData.GetCorpsRoleInfo(nPlayerID, nArenaType)
        local nScore = tbArenaInfo.nMatchLevel or 1000
        local nPrestigeExtRemain = ArenaData.GetPrestigeExtRemain(nArenaType, nScore)

        UIMgr.Open(VIEW_ID.PanelPvPArenaIntegralPop, nPrestigeExtRemain)
    end)

    UIHelper.BindUIEvent(self.BtnReputation, EventType.OnClick, function()
        if not self.tbReputationInfo then
            return
        end

        UIMgr.Open(VIEW_ID.PanelPlayerReputationPop, self.tbReputationInfo)
    end)

    UIHelper.BindUIEvent(self.TogHelp3, EventType.OnClick, function()
        UIHelper.SetSelected(self.TogHelp4, false)
    end)

    UIHelper.BindUIEvent(self.TogHelp4, EventType.OnClick, function()
        UIHelper.SetSelected(self.TogHelp3, false)
    end)

    UIHelper.BindUIEvent(self.BtnDssEquipmentSetting, EventType.OnClick, function()
        local hPlayer = GetClientPlayer()
        if not hPlayer then
            return
        end

        --拭剑园不能从非NPC途径打开界面
        local dwMapID = hPlayer.GetMapID()
        if IsMasterEquipMap(dwMapID) then
            UIMgr.Open(VIEW_ID.PanelDssCustomizedSet)
        else
            local tbInfo = clone(Table_GetCareerGuideAllLink(ARENA_MASTER_NPC_LINK_ID))
            tbInfo = tbInfo and tbInfo[1]

            local tbPoint = tbInfo.tPoint or { tbInfo.fX, tbInfo.fY, tbInfo.fZ }
            MapMgr.SetTracePoint(UIHelper.GBKToUTF8(tbInfo.szNpcName), tbInfo.dwMapID, tbPoint)
            UIMgr.CloseAllInLayer("UIPageLayer")
            UIMgr.CloseAllInLayer("UIPopupLayer")
            Timer.Add(ArenaEquipDIYData, 1, function ()
                RemoteCallToServer("On_JJC_GoToEquip")
            end)
            return
        end
    end)

    UIHelper.BindUIEvent(self.BtnCreateDssTeam, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelPvPArenaTeamNamePop, self:GetCurArenaType())
    end)

    UIHelper.BindUIEvent(self.BtnDssTeamMatching, EventType.OnClick, function()
        local hPlayer = GetClientPlayer()
        if not hPlayer then
            return
        end

        --拭剑园不能从非NPC途径打开界面
        local dwMapID = hPlayer.GetMapID()
        if not IsMasterEquipMap(dwMapID) then
            local tbInfo = clone(Table_GetCareerGuideAllLink(ARENA_MASTER_NPC_LINK_ID))
            tbInfo = tbInfo and tbInfo[1]

            local tbPoint = tbInfo.tPoint or { tbInfo.fX, tbInfo.fY, tbInfo.fZ }
            MapMgr.SetTracePoint(UIHelper.GBKToUTF8(tbInfo.szNpcName), tbInfo.dwMapID, tbPoint)
            UIMgr.CloseAllInLayer("UIPageLayer")
            UIMgr.CloseAllInLayer("UIPopupLayer")
            Timer.Add(ArenaEquipDIYData, 1, function ()
                RemoteCallToServer("On_JJC_GoToEquip")
            end)
            return
        end

        local _, _, nQueueArenaType = ArenaData.GetQueueTime()
        if nQueueArenaType then
            TipsHelper.ShowNormalTip("正在名剑大会排队中,不能加入名剑大会等待队列。")
            return
        end

        local nArenaType = self:GetCurArenaType()
        local player = PlayerData.GetClientPlayer()
        if not player.IsInParty() then
            UIHelper.SimulateClick(self.BtnTeamup)
            TipsHelper.ShowNormalTip("请先与同一战队成员组队")
            return
        end

        ArenaData.JoinArenaQueue(nArenaType, false, ARENA_GAME_TYPE.NORMAL)
    end)

    UIHelper.BindUIEvent(self.BtnDssTeamMatchCancel, EventType.OnClick, function()
        local nArenaType = self:GetCurArenaType()
        local bInQueue, bSingle = ArenaData.IsInArenaQueue(nArenaType)
        if not bInQueue then
            return
        end

        ArenaData.LeaveArenaQueue()
    end)

    for i, btn in ipairs(self.tbBtnGrade) do
        UIHelper.BindUIEvent(btn, EventType.OnClick, function()
            self.bShowCorps = not self.bShowCorps
            self:UpdateShowCorps(true)
        end)
    end
end

function UIArenaModeSelectView:RegEvent()
    Event.Reg(self, EventType.OnUpdateArenaSeasonHighestRankScore, function (nPlayerID, tbInfo)
        self.tbSeasonHighestRankScore = tbInfo
        self:UpdateArenaInfo()
    end)

    Event.Reg(self, "SYNC_CORPS_LIST", function (nPeekID)
        self:UpdateInfo()
	end)

    Event.Reg(self, "ARENA_STATE_UPDATE", function()
        self:UpdateInfo()
    end)

    Event.Reg(self, "ARENA_UPDATE_TIME", function()
        self:UpdateInfo()
    end)

    Event.Reg(self, "ON_ARENA_WEEKLY_INFO_UPDATE", function()
        self:UpdateInfo()
    end)

    Event.Reg(self, "JOIN_ARENA_QUEUE", function(nErrorCode, dwErrorRoleID, szErrorRoleName)
        local nArenaType = self:GetCurArenaType()
        if nErrorCode == ARENA_RESULT_CODE.SUCCESS then
            self:OnEnter(self.nNpcID, self.nCurSelectMode)
        else
            local szTip = g_tStrings.tArenaResult[nErrorCode]
            if szTip then
                local szName = szErrorRoleName
                local player = PlayerData.GetClientPlayer()

                if not string.is_nil(szName) and szName ~= player.szName then
                    szTip = FormatString(szTip, g_tStrings.STR_BATTLE_JION_QUEUE_TIP1.."["..UIHelper.GBKToUTF8(szName).."]")
                else
                    szTip = FormatString(szTip, g_tStrings.STR_BATTLE_JION_QUEUE_TIP)
                end

                TipsHelper.ShowNormalTip(szTip)
            end
        end
    end)

    Event.Reg(self, "LEAVE_ARENA_QUEUE", function(nErrorCode)
        if self.bInRobotQueue then
            self.bInRobotQueue = false
			self:UpdateRobotPracticeBtn()
            TipsHelper.ShowNormalTip(g_tStrings.STR_ARENA_LEAVE_QUEUE)
        end
        self:UpdateInfo()
    end)

    Event.Reg(self, "CREATE_GLOBAL_ROOM", function()
        self:UpdateInfo()
    end)
    Event.Reg(self, "JOIN_GLOBAL_ROOM", function()
        self:UpdateInfo()
    end)
    Event.Reg(self, "GLOBAL_ROOM_MEMBER_CHANGE", function()
        self:UpdateInfo()
    end)
    Event.Reg(self, "LEAVE_GLOBAL_ROOM", function()
        self:UpdateInfo()
    end)
    Event.Reg(self, "GLOBAL_ROOM_BASE_INFO", function()
        self:UpdateInfo()
    end)
    Event.Reg(self, "GLOBAL_ROOM_DETAIL_INFO", function()
        self:UpdateInfo()
    end)

    Event.Reg(self, "SCENE_BEGIN_LOAD", function()
        UIMgr.Close(self)
    end)

    Event.Reg(self, "ARENA_NOTIFY", function()
        local eGameType = arg13
		local nType = arg0
		if eGameType ~= ARENA_GAME_TYPE.NORMAL and nType == ARENA_NOTIFY_TYPE.ARENA_QUEUE_INFO and not self.bInRobotQueue then
			self.bInRobotQueue = true
			self:UpdateRobotPracticeBtn()
		end
    end)

    Event.Reg(self, "ON_JJC_LEVEL_AWARD_UPDATE", function(tbInfo, nGotLevel)
		self.tbRewardInfo = tbInfo
		self.nGotLevel = nGotLevel or 0
        self:UpdateRankLevelRewardInfo()
    end)

    Event.Reg(self, "ON_JJC_GET_BUFF_CUSTOM_VALUE", function(nCustomValue)
        self.nMasterBuffCustomValue = nCustomValue or 0
        self:UpdateMasterRewardInfo()
    end)

    Event.Reg(self, EventType.OnTouchViewBackGround, function()
        if self.tbWinRewardItem then
            for _, cell in ipairs(self.tbWinRewardItem) do
                cell:SetSelected(false)
            end
        end
        if self.scriptWinRewardItemTip then
            self.scriptWinRewardItemTip:OnInitWithTabID()
        end

        UIHelper.SetSelected(self.TogHelp3, false)
        UIHelper.SetSelected(self.TogHelp4, false)

        UIHelper.SetVisible(self.LayoutRankRewardInfo, false)
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        UIHelper.SetVisible(self.WidgetAnchorLeaveFor, false)
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function (szName)
        Timer.Add(self, 0.1, function ()
            self:UpdateShowCorps(true)
        end)
    end)

    --信誉分
    Event.Reg(self, EventType.OnGetPrestigeInfoRespond, function(dwPlayerID, tbInfo)
        if dwPlayerID == g_pClientPlayer.dwID then
            self.tbReputationInfo = tbInfo
        end
    end)

    self.scriptShare = self.scriptShare or UIHelper.GetBindScript(self.WidgetShare)
    self.scriptShare:OnEnter(nil, true)
end

function UIArenaModeSelectView:UpdateInfo()
    self:UpdateArenaInfo()
    self:UpdateCorpsInfo()
    self:UpdateShowCorps()
    self:UpdateBtnState()
    self:UpdatePracticeInfo()
    self:UpdateRankLevelRewardInfo()
    self:UpdateRankRewardTipsInfo()
end

function UIArenaModeSelectView:UpdateRewardInfo()
    UIHelper.RemoveAllChildren(self.WidgetPvPReward)
    UIHelper.AddPrefab(PREFAB_ID.WidgetCoin, self.WidgetPvPReward, CurrencyType.Prestige, nil, '3600')
    UIHelper.AddPrefab(PREFAB_ID.WidgetCoin, self.WidgetPvPReward, CurrencyType.PersonAthScore, nil, "50")
    UIHelper.LayoutDoLayout(self.WidgetPvPReward)
end

function UIArenaModeSelectView:UpdateWinRewardInfo()
    local tbRewardItems = GDAPI_JJC5WinItem() --dwTabType, dwIndex, nCount

    UIHelper.HideAllChildren(self.WidgetWinRewardFinished)
    if not tbRewardItems then
        return
    end

    self.tbWinRewardItem = self.tbWinRewardItem or {}
    for i, tbItemInfo in ipairs(tbRewardItems) do
        if not self.tbWinRewardItem[i] then
            self.tbWinRewardItem[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_44, self.LayoutWinReward)
            UIHelper.SetAnchorPoint(self.tbWinRewardItem[i]._rootNode, 0, 0)
        end

        self.tbWinRewardItem[i]:OnInitWithTabID(tbItemInfo[1], tbItemInfo[2])
        self.tbWinRewardItem[i]:SetClickNotSelected(true)
        self.tbWinRewardItem[i]:SetClickCallback(function(nTabType, nTabID)
            if not self.scriptWinRewardItemTip then
                self.scriptWinRewardItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemTip)
            end
            self.scriptWinRewardItemTip:OnInitWithTabID(nTabType, nTabID)
            local tbBtnInfo = {}
            local nBoxID = TreasureBoxData.GetBoxIDByTab(nTabType, nTabID)
            if nBoxID then
                local tBoxInfo = Tabel_GetTreasureBoxListByID(nBoxID)
                if tBoxInfo and tBoxInfo.nGroupID and tBoxInfo.nGroupID == 1 then
                    table.insert(tbBtnInfo, {
                        szName = "查看奖励",
                        OnClick = function ()
                            UIMgr.Open(VIEW_ID.PanelRandomTreasureBox, nBoxID)
                        end
                    })
                end
            end
            self.scriptWinRewardItemTip:SetBtnState(tbBtnInfo)
        end)
        self.tbWinRewardItem[i]:SetLabelCount(tbItemInfo[3])

        UIHelper.SetVisible(self.tbWidgetWinRewardFinished[i], true)
    end

    UIHelper.LayoutDoLayout(self.LayoutWinReward)
end

function UIArenaModeSelectView:UpdateMasterRewardInfo()
    for _, parent in ipairs(self.tbMasterRewardList) do
        UIHelper.RemoveAllChildren(parent)
    end

    local tRewardInfo = Table_GetArenaCropRewardInfo()
	for nIndex, tLine in ipairs(tRewardInfo) do
		for k, tItem in ipairs(tLine.tItem) do
            local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_44, self.tbMasterRewardList[nIndex])
            cell:SetClickNotSelected(true)
            cell:OnInitWithTabID(tItem.dwTabType, tItem.dwIndex)
            cell:SetLabelCount(tItem.nCount)

            cell:SetClickCallback(function(nTabType, nTabID)
                if not self.scriptWinRewardItemTip then
                    self.scriptWinRewardItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemTip)
                end
                self.scriptWinRewardItemTip:OnInitWithTabID(nTabType, nTabID)
                local tbBtnInfo = {}
                local nBoxID = TreasureBoxData.GetBoxIDByTab(nTabType, nTabID)
                if nBoxID then
                    local tBoxInfo = Tabel_GetTreasureBoxListByID(nBoxID)
                    if tBoxInfo and tBoxInfo.nGroupID and tBoxInfo.nGroupID == 1 then
                        table.insert(tbBtnInfo, {
                            szName = "查看奖励",
                            OnClick = function ()
                                UIMgr.Open(VIEW_ID.PanelRandomTreasureBox, nBoxID)
                            end
                        })
                    end
                end
                self.scriptWinRewardItemTip:SetBtnState(tbBtnInfo)
            end)

            self.nMasterBuffCustomValue = self.nMasterBuffCustomValue or 0
            local bReceived = math.floor((self.nMasterBuffCustomValue + 1) / 2) >= nIndex
            cell:SetItemReceived(bReceived)
        end

        UIHelper.LayoutDoLayout(self.tbMasterRewardList[nIndex])
	end
end

function UIArenaModeSelectView:UpdateArenaInfo()
    local nPlayerID = PlayerData.GetPlayerID()
    local nArenaType = self:GetCurArenaType()

    if not nArenaType or nArenaType >= ARENA_UI_TYPE.ARENA_END then
        return
    end

    local nPassTime, nAvgQueueTime, nQueueArenaType = ArenaData.GetQueueTime()
    if nQueueArenaType ~= ARENA_UI_TYPE.ARENA_PRACTICE then
        if self.nMatchingTimerID then
            Timer.DelTimer(self, self.nMatchingTimerID)
            self.nMatchingTimerID = nil
        end
        self.nMatchingTimerID = Timer.AddCycle(self, 0.5, function()
            local nPassTime, nAvgQueueTime, nQueueArenaType = ArenaData.GetQueueTime()
            if nQueueArenaType ~= ARENA_UI_TYPE.ARENA_1V1 and
                nQueueArenaType ~= ARENA_UI_TYPE.ARENA_2V2 and
                nQueueArenaType ~= ARENA_UI_TYPE.ARENA_3V3 and
                nQueueArenaType ~= ARENA_UI_TYPE.ARENA_5V5 and
                nQueueArenaType ~= ARENA_UI_TYPE.ARENA_MASTER_3V3 then
                if self.nMatchingTimerID then
                    UIHelper.SetString(self.LabelMatchingTime, "已匹配 0秒  预计排队 0秒")
                    UIHelper.SetString(self.LabelMatchingTime2, "已匹配 0秒  预计排队 0秒")
                    UIHelper.SetVisible(self.LabelMatchingTime, false)
                    UIHelper.SetVisible(self.LabelMatchingTime2, false)

                    Timer.DelTimer(self, self.nMatchingTimerID)
                    self.nMatchingTimerID = nil
                end
                return
            end
            UIHelper.SetString(self.LabelMatchingTime, string.format("已匹配 %s  预计排队 %s", ArenaData.FormatArenaTime(nPassTime), ArenaData.FormatArenaTime(nAvgQueueTime)))
            UIHelper.SetString(self.LabelMatchingTime2, string.format("已匹配 %s  预计排队 %s", ArenaData.FormatArenaTime(nPassTime), ArenaData.FormatArenaTime(nAvgQueueTime)))
        end)
    end

    UIHelper.SetString(self.LabelOpenTime, "每日12:00至次日凌晨1:00开放")
    UIHelper.SetVisible(self.BtnTeamup, nArenaType ~= ARENA_UI_TYPE.ARENA_1V1)
    UIHelper.LayoutDoLayout(self.WidgetBtnPlus)

    if nArenaType == ARENA_UI_TYPE.ARENA_MASTER_3V3 then
        self.scriptMasterInfo = self.scriptMasterInfo or UIHelper.GetBindScript(self.WigdetDssInfo)
        self.scriptMasterInfo:OnEnter(nPlayerID, nArenaType)

        local nCorpsID = ArenaData.GetCorpsID(nArenaType, nPlayerID)
        local bEmpty = not nCorpsID or nCorpsID <= 0
        UIHelper.SetVisible(self.LabelDssCreateTeamHint, bEmpty)
        UIHelper.SetVisible(self.BtnCreateDssTeam, bEmpty)
        UIHelper.LayoutDoLayout(self.LayoutBottomBtn2)
        return
    elseif nArenaType == ARENA_UI_TYPE.ARENA_1V1 then
        self.scriptSoloInfo = self.scriptMasterInfo or UIHelper.GetBindScript(self.WidgetSoloKing)
        self.scriptSoloInfo:OnEnter(nPlayerID, nArenaType)
        UIHelper.SetString(self.LabelOpenTime, "每周五-周日，12:00至次日凌晨1:00开放")
        return
    end

    local nArenaLevel = ArenaData.GetArenaLevel(nPlayerID, nArenaType)
    local tbArenaInfo = ArenaData.GetCorpsRoleInfo(nPlayerID, nArenaType)
    local nTeamScore = ArenaData.GetCorpsLevel(nPlayerID, nArenaType)
    local nLeftDoubleCount, nMaxDoubleCount = ArenaData.GetDoubleRewardInfo(nArenaType)
    local nScore = tbArenaInfo.nMatchLevel or 1000

    local _, _, nPrestigeRemainSpace = CurrencyData.GetCurCurrencyLimit(CurrencyType.Prestige)

    UIHelper.SetString(self.LabelPersonageScore, nScore)
    if self.tbSeasonHighestRankScore and self.tbSeasonHighestRankScore[nArenaType] then
        UIHelper.SetString(self.LabelSeasonScore, self.tbSeasonHighestRankScore[nArenaType])
    else
        UIHelper.SetString(self.LabelSeasonScore, nScore)
    end
    UIHelper.SetString(self.LabelTeamScore, nTeamScore)
    UIHelper.SetString(self.LabelUpperLimitScore, string.format("%d", nPrestigeRemainSpace))
    UIHelper.LayoutDoLayout(self.LayoutWeiMingLimit)

    local nCorpsID = ArenaData.GetCorpsID(nArenaType, nPlayerID)
    local bEmpty = not nCorpsID or nCorpsID <= 0
    UIHelper.SetVisible(self.BtnWidgetGrade3, not bEmpty)
    UIHelper.LayoutDoLayout(self.WidgetScore)

    local bIsInWarning = self:IsInWarning(nScore, (tbArenaInfo.dwWeekTotalCount or 0))
    UIHelper.SetVisible(self.TogHelp3, bIsInWarning)
    UIHelper.SetVisible(self.WidgetMasterInfo1, nScore >= 2400 and nScore < 2500)
    UIHelper.SetVisible(self.WidgetMasterInfo2, nScore >= 2500)

    local tbTeamData = ArenaData.tbCorpsInfo[nArenaType] or {}
    local bIsTeamInWarning = self:IsInWarning(nTeamScore, (tbTeamData.dwWeekTotalCount or 0))
    UIHelper.SetVisible(self.TogHelp4, bIsTeamInWarning)
    UIHelper.SetVisible(self.WidgetMasterInfo3, nTeamScore >= 2400 and nTeamScore < 2500)
    UIHelper.SetVisible(self.WidgetMasterInfo4, nTeamScore >= 2500)
    UIHelper.CascadeDoLayoutDoWidget(self.WidgetScore, true, true)

    self:UpdateWeekTotalInfo(self.tbImgDoubleSchedule1, (tbArenaInfo.dwWeekTotalCount or 0))
    self:UpdateWeekTotalInfo(self.tbImgDoubleSchedule2, (tbArenaInfo.dwWeekTotalCount or 0))
    self:UpdateWeekTotalInfo(self.tbImgDoubleSchedule3, (tbTeamData.dwWeekTotalCount or 0))
    self:UpdateWeekTotalInfo(self.tbImgDoubleSchedule4, (tbTeamData.dwWeekTotalCount or 0))

    local tbUIConfig = TabHelper.GetUIArenaRankLevelTab(nArenaLevel)
    if tbUIConfig then
        UIHelper.SetSpriteFrame(self.ImgClassIcon, tbUIConfig.szBigIcon)
    end

    UIHelper.SetVisible(self.WidgetWinRewardFinished, nMaxDoubleCount == nLeftDoubleCount)
    nLeftDoubleCount = nMaxDoubleCount - nLeftDoubleCount
    for i, img in ipairs(self.tbImgSchedule) do
        if nLeftDoubleCount > 0 then
            UIHelper.SetVisible(img, true)
        else
            UIHelper.SetVisible(img, false)
        end
        nLeftDoubleCount = nLeftDoubleCount - 1
    end

    local tbArenaLevelConfig = ArenaData.GetLevelInfo(nArenaLevel)
    local tbArenaNextLevelConfig = ArenaData.GetLevelInfo(nArenaLevel + 1) or tbArenaLevelConfig
	local szLevel = Conversion2ChineseNumber(nArenaLevel)

    if not tbArenaLevelConfig then return end
    UIHelper.SetProgressBarPercent(self.ProgressBar, math.min(100 - (tbArenaNextLevelConfig.score - nScore), 100))
    UIHelper.SetString(self.LabelNum, string.format("%d/%d", nScore, tbArenaNextLevelConfig.score))
    UIHelper.SetString(self.LabelAcquire, string.format("%s%s%s%s", szLevel, g_tStrings.STR_DUAN, g_tStrings.STR_CONNECT, UIHelper.GBKToUTF8(tbArenaLevelConfig.title)))
end

function UIArenaModeSelectView:UpdateCorpsInfo()
    if not self.scriptCorpsInfoPage then
        self.scriptCorpsInfoPage = UIHelper.GetBindScript(self.WidgetAnchorRight)
    end

    self.scriptCorpsInfoPage:OnEnter(self.nCurSelectMode)
end

function UIArenaModeSelectView:UpdateBtnState()
    local nArenaType = self:GetCurArenaType()
    local bInQueue, bSingle = ArenaData.IsInArenaQueue(nArenaType)
    UIHelper.SetVisible(self.WidgetMatchingBtnList, nArenaType ~= ARENA_UI_TYPE.ARENA_1V1)
    UIHelper.SetVisible(self.BtnRank, nArenaType == ARENA_UI_TYPE.ARENA_MASTER_3V3 or nArenaType == ARENA_UI_TYPE.ARENA_1V1)
    UIHelper.SetVisible(self.BtnPersonageMatching, not bInQueue)
    UIHelper.SetVisible(self.BtnTeamMatching, not bInQueue)
    UIHelper.SetVisible(self.BtnRoomMatching, not bInQueue)
    UIHelper.SetVisible(self.BtnAwait, bInQueue)
    UIHelper.SetVisible(self.LabelMatchingTime, bInQueue)
    UIHelper.SetVisible(self.tbEffMatching[1], bInQueue)
    if nArenaType == ARENA_UI_TYPE.ARENA_2V2 then
        UIHelper.SetVisible(self.tbEffMatching[2], bInQueue)
    elseif nArenaType == ARENA_UI_TYPE.ARENA_3V3 then
        UIHelper.SetVisible(self.tbEffMatching[3], bInQueue)
    elseif nArenaType == ARENA_UI_TYPE.ARENA_5V5 then
        UIHelper.SetVisible(self.tbEffMatching[4], bInQueue)
    elseif nArenaType == ARENA_UI_TYPE.ARENA_MASTER_3V3 then
        local nPlayerID = PlayerData.GetPlayerID()
        local nCorpsID = ArenaData.GetCorpsID(nArenaType, nPlayerID)
        local bEmpty = not nCorpsID or nCorpsID <= 0
        UIHelper.SetVisible(self.BtnDssTeamMatching, not bEmpty and not bInQueue)
        UIHelper.SetVisible(self.BtnDssTeamMatchCancel, not bEmpty and bInQueue)
        UIHelper.LayoutDoLayout(self.LayoutBottomBtn2)
    end

    local szRoomTip
    local bCanJoinRoom = false
    local bRoomOwner = RoomData.IsRoomOwner()
    local nRoomSize = RoomData.GetSize()
    if bRoomOwner and nRoomSize > 1 then
        bCanJoinRoom = true
    elseif not bRoomOwner then
        szRoomTip = "只有跨服房间房主才可进行跨服匹配"
    elseif nRoomSize <= 1 then
        szRoomTip = "跨服房间中至少有两名成员才可进行跨服匹配"
    end

    UIHelper.SetButtonState(self.BtnRoomMatching, bCanJoinRoom and BTN_STATE.Normal or BTN_STATE.Disable, szRoomTip)
    UIHelper.LayoutDoLayout(self.LayoutBottomBtn)
    UIHelper.LayoutDoLayout(self.WIdgetRightTop)
end

function UIArenaModeSelectView:UpdatePracticeInfo()
    local bInQueue, bSingle = ArenaData.IsInArenaQueue(ARENA_UI_TYPE.ARENA_PRACTICE)

    UIHelper.SetVisible(self.WidgetNormal, not bInQueue)
    UIHelper.SetVisible(self.WidgetMatching, bInQueue)
    UIHelper.SetVisible(self.LabelMatching, false)
    UIHelper.SetVisible(self.ImgBgRoomKey, false)
    UIHelper.SetVisible(self.LabelRoomCD, false)

    local nPassTime, nAvgQueueTime, nQueueArenaType = ArenaData.GetQueueTime()
    if nQueueArenaType == ARENA_UI_TYPE.ARENA_PRACTICE then
        UIHelper.SetString(self.LabelMatching, string.format("匹配中..%d秒", nPassTime))
        UIHelper.SetVisible(self.LabelMatching, true)
        if self.nPracticeMatchingTimerID then
            Timer.DelTimer(self, self.nPracticeMatchingTimerID)
            self.nPracticeMatchingTimerID = nil
        end
        self.nPracticeMatchingTimerID = Timer.AddCycle(self, 0.5, function()
            local nPassTime, nAvgQueueTime, nQueueArenaType = ArenaData.GetQueueTime()
            if nQueueArenaType ~= ARENA_UI_TYPE.ARENA_PRACTICE then
                if self.nPracticeMatchingTimerID then
                    UIHelper.SetVisible(self.LabelMatching, false)
                    Timer.DelTimer(self, self.nPracticeMatchingTimerID)
                    self.nPracticeMatchingTimerID = nil
                end
                return
            end
            UIHelper.SetString(self.LabelMatching, string.format("匹配中..%d秒", nPassTime))
        end)
    end

    local nRoomKey = ArenaData.GetCacheData("nRoomKey")
    if nRoomKey then
        UIHelper.SetVisible(self.ImgBgRoomKey, true)
        UIHelper.SetString(self.LabelRoomNum, string.format("房间号：%d", nRoomKey))
    end

    local nCreateArenaRoomTime = ArenaData.GetCacheData("nCreateArenaRoomTime")
    if nCreateArenaRoomTime and math.floor((GetTickCount() - nCreateArenaRoomTime) / 1000) < ArenaData.RoomNextCreateTime then
        UIHelper.SetVisible(self.LabelRoomCD, true)
        local nLeftTime = ArenaData.RoomNextCreateTime - math.floor((GetTickCount() - nCreateArenaRoomTime) / 1000)
        UIHelper.SetRichText(self.LabelRoomCD, string.format("<color=#ff857d>%d秒</c><color=#cee1f9>后可再次创建</color>", nLeftTime))
        if self.nCreateArenaRoomCDTimerID then
            Timer.DelTimer(self, self.nCreateArenaRoomCDTimerID)
            self.nCreateArenaRoomCDTimerID = nil
        end
        self.nCreateArenaRoomCDTimerID = Timer.AddCycle(self, 0.5, function()
            nLeftTime =  ArenaData.RoomNextCreateTime - math.floor((GetTickCount() - nCreateArenaRoomTime) / 1000)
            nLeftTime = math.max(0, nLeftTime)
            UIHelper.SetRichText(self.LabelRoomCD, string.format("<color=#ff857d>%d秒</c><color=#cee1f9>后可再次创建</color>", nLeftTime))

            if nLeftTime == 0 then
                self:UpdatePracticeInfo()
            end
        end)

        UIHelper.SetButtonState(self.BtnEstablish, BTN_STATE.Disable)
    else
        UIHelper.SetButtonState(self.BtnEstablish, BTN_STATE.Normal)
    end
end

function UIArenaModeSelectView:UpdateRankLevelRewardInfo()
    if not self.tbRewardInfo then return end

    local nArenaType = self:GetCurArenaType()
    local bHadRewarCanGet = not not self.tbRewardInfo[nArenaType]

    UIHelper.SetVisible(self.ImgRewardPoint, bHadRewarCanGet)
    UIHelper.SetVisible(self.Eff_SquareRing, bHadRewarCanGet)
end

function UIArenaModeSelectView:UpdateRankRewardTipsInfo()
    local nPlayerID = PlayerData.GetPlayerID()
    local nArenaType = self:GetCurArenaType()

    if not nArenaType or nArenaType >= ARENA_UI_TYPE.ARENA_END then
        return
    end

    local nArenaLevel = ArenaData.GetArenaLevel(nPlayerID, nArenaType)
    local tbRankRewardConfig = TabHelper.GetUIArenaRankLevelTab(nArenaLevel)

    if not tbRankRewardConfig then
        return
    end

    local tbRewards = {}

    local i = 1
    while tbRankRewardConfig["nAwardType"..i] and tbRankRewardConfig["nAwardID"..i] and tbRankRewardConfig["nAwardCount"..i] do
        if tbRankRewardConfig["nAwardType"..i] > 0 and
            tbRankRewardConfig["nAwardID"..i] > 0 and
            tbRankRewardConfig["nAwardCount"..i] > 0 then
            table.insert(tbRewards, {
                nType = tbRankRewardConfig["nAwardType"..i],
                nID = tbRankRewardConfig["nAwardID"..i],
                nCount = tbRankRewardConfig["nAwardCount"..i],
            })
        end
        i = i + 1
    end

    for i, widget in ipairs(self.tbWidgetRankReward) do
        local tbReward = tbRewards[i]
        if tbReward then
            UIHelper.SetVisible(widget, true)
            local script = UIHelper.GetBindScript(widget)
            if not script.scriptItem then
                script.scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_44, script.WidgetWinReward1)
                UIHelper.SetTouchEnabled(script.scriptItem.ToggleSelect, false)
            end
            script.scriptItem:OnInitWithTabID(tbReward.nType, tbReward.nID, tbReward.nCount)
            local itemInfo = ItemData.GetItemInfo(tbReward.nType, tbReward.nID)
            UIHelper.SetString(script.LabelScoreExplain1, UIHelper.GBKToUTF8(ItemData.GetItemNameByItem(itemInfo)))
        else
            UIHelper.SetVisible(widget, false)
        end
    end

    local bEmptyReward = #tbRewards == 0
    UIHelper.SetVisible(self.LabelRankRewardTitle, not bEmptyReward)
    UIHelper.SetVisible(self.LabelRankRewardTipDesc, not bEmptyReward)
    UIHelper.SetVisible(self.LabelRankRewardTipDescNone, bEmptyReward)
    UIHelper.LayoutDoLayout(self.LayoutRankRewardInfo)
end

function UIArenaModeSelectView:UpdateCurrencyInfo()
    UIHelper.RemoveAllChildren(self.WidgetPVPMoney)
    UIHelper.AddPrefab(PREFAB_ID.WidgetCoin, self.WidgetPVPMoney, CurrencyType.Prestige)
    UIHelper.AddPrefab(PREFAB_ID.WidgetCoin, self.WidgetPVPMoney, CurrencyType.TitlePoint)

    UIHelper.LayoutDoLayout(self.WidgetPVPMoney)
end

function UIArenaModeSelectView:UpdateShowCorps(bFixPos)
    if self.nCurSelectMode == ARENA_MODE_TYPE.ARENA_PRACTICE then
        UIHelper.SetVisible(self.WidgetAnchorRight, false)
        UIHelper.SetVisible(self.WidgetBottomBtn, false)
    else
        if self.bShowCorps then
            UIHelper.SetVisible(self.WidgetAnchorRight, true)
            UIHelper.SetVisible(self.WidgetBottomBtn, false)
            UIHelper.SetVisible(self.BtnMoreData, false)
            UIHelper.SetVisible(self.BtnPutData, true)
            if bFixPos then
                UIHelper.PlayAni(self, self.AniAll, "AniMiddleLeftMove")
            end
        else
            UIHelper.SetVisible(self.WidgetAnchorRight, false)
            UIHelper.SetVisible(self.WidgetBottomBtn, true)
            UIHelper.SetVisible(self.BtnMoreData, true)
            UIHelper.SetVisible(self.BtnPutData, false)
            if bFixPos then
                UIHelper.PlayAni(self, self.AniAll, "AniMiddleRightMove")
            end
        end
    end
end

function UIArenaModeSelectView:GetCurArenaType()
    return ArenaData.tbCorpsList[self.nCurSelectMode]
end

function UIArenaModeSelectView:CheckCurQueueType()
    for _, nArenaType in pairs(ArenaData.tbCorpsList) do
        local bInQueue, bSingle = ArenaData.IsInArenaQueue(nArenaType)
        if bInQueue then
            return table.get_key(ArenaData.tbCorpsList, nArenaType)
        end
    end
end

function UIArenaModeSelectView:UpdateRobotPracticeBtn()
    UIHelper.SetVisible(self.BtnDrill, not self.bInRobotQueue)
    UIHelper.SetVisible(self.BtnDrillQuit, self.bInRobotQueue)
end

function UIArenaModeSelectView:UpdateWeekTotalInfo(tbImg, nTotalCount)
    for i, img in ipairs(tbImg) do
        if i <= (nTotalCount or 0) then
            UIHelper.SetSpriteFrame(img, "UIAtlas2_Pvp_PvpEntrance_Img_Double1.png")
        else
            UIHelper.SetSpriteFrame(img, "UIAtlas2_Pvp_PvpEntrance_Img_Double2.png")
        end
    end
end

function UIArenaModeSelectView:IsInWarning(nScore, nCount)
	if nScore >= 2400 and nScore <2500 and nCount < 5 then --分数高于2400，本周场次小于5
		return true, 5
	end

	if nScore >= 2500 and nCount < 10 then --分数高于2500，本周场次小于10
		return true, 10
	end

	return false
end

function UIArenaModeSelectView:UpdateModeToggleState()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local dwMapID = hPlayer.GetMapID()
    local bIsMasterEquipMap = IsMasterEquipMap(dwMapID)
    local bIsMasterOpen = ActivityData.IsActivityOn(ARENA_MASTER_ACTIVITY_ID)
    local bIsSoloOpen = ActivityData.IsActivityOn(ARENA_SOLO_ACTIVITY_ID)
    for i, tog in ipairs(self.tbTogMode) do
        UIHelper.SetVisible(tog, true)
        UIHelper.SetVisible(self.tbImgTogLline[i - 1], true)
        if bIsMasterEquipMap then
            if i == ARENA_MODE_TYPE.ARENA_MASTER_3V3 then
                UIHelper.SetButtonState(tog, BTN_STATE.Normal)
            else
                UIHelper.SetButtonState(tog, BTN_STATE.Disable, function ()
                    TipsHelper.ShowNormalTip("当前地图只允许参与群英赛")
                    UIHelper.SetToggleGroupSelected(self.ToggleGroupTab, self.nCurSelectMode - 1)
                end)
            end
        elseif not bIsMasterOpen or not bIsSoloOpen then
            if not bIsMasterOpen and i == ARENA_MODE_TYPE.ARENA_MASTER_3V3 then
                UIHelper.SetButtonState(tog, BTN_STATE.Disable, function ()
                    TipsHelper.ShowNormalTip("活动未开放")
                    UIHelper.SetToggleGroupSelected(self.ToggleGroupTab, self.nCurSelectMode - 1)
                end)
                UIHelper.SetVisible(tog, false)
                UIHelper.SetVisible(self.tbImgTogLline[i - 1], false)
            elseif not bIsSoloOpen and i == ARENA_MODE_TYPE.ARENA_1V1 then
                UIHelper.SetButtonState(tog, BTN_STATE.Disable, function ()
                    TipsHelper.ShowNormalTip("活动未开放")
                    UIHelper.SetToggleGroupSelected(self.ToggleGroupTab, self.nCurSelectMode - 1)
                end)
                UIHelper.SetVisible(tog, false)
                UIHelper.SetVisible(self.tbImgTogLline[i - 1], false)
            else
                UIHelper.SetButtonState(tog, BTN_STATE.Normal)
            end
        else
            UIHelper.SetButtonState(tog, BTN_STATE.Normal)
        end
    end
end

function UIArenaModeSelectView:CheckSelectModeVaild()
    local player = GetClientPlayer()
    if player then
        local dwMapID = player.GetMapID()
        local bIsMasterEquipMap = IsMasterEquipMap(dwMapID)
        local bIsMasterOpen = ActivityData.IsActivityOn(ARENA_MASTER_ACTIVITY_ID)
        local bIsSoloOpen = ActivityData.IsActivityOn(ARENA_SOLO_ACTIVITY_ID)

        if bIsMasterEquipMap then
            if self.nCurSelectMode ~= ARENA_MODE_TYPE.ARENA_MASTER_3V3 then
                self.nCurSelectMode = ARENA_MODE_TYPE.ARENA_MASTER_3V3
            end
        elseif not bIsMasterOpen or not bIsSoloOpen then
            if (not bIsMasterOpen and self.nCurSelectMode == ARENA_MODE_TYPE.ARENA_MASTER_3V3) or (self.nCurSelectMode == ARENA_MODE_TYPE.ARENA_1V1 and not bIsSoloOpen) then
                self.nCurSelectMode = ARENA_MODE_TYPE.ARENA_2V2
            end
        end
    end
end

return UIArenaModeSelectView