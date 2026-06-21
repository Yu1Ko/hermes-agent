local UIMonopolyMatchView = class("UIMonopolyMatchView")

local QUEUE_MODE =
{
    NONE = 0,
    SINGLE = 1,
    TEAM = 2,
    ROOM = 3,
}

local function FormatMatchCostText(nSeconds)
    nSeconds = math.max(0, math.floor(nSeconds or 0))
    return string.format("%d秒", nSeconds)
end

local function GetQueueGroupID(tInfo, hPlayer, nQueueMode)
    if nQueueMode == QUEUE_MODE.ROOM then
        if Table_IsMonopolyBattleFieldMap(tInfo.dwMapID) then
            return 0
        end
        return Random(GetTickCount()) % 2
    end

    if tInfo.nType == 0 and hPlayer and hPlayer.nCamp ~= CAMP.GOOD then
        return 1
    end
    return 0
end

local function GetCurrentBattleFieldQueueState(dwMapID)
    local bInQueue, bSingle, bGlobalRoom = BattleFieldQueueData.IsInBattleFieldQueue(dwMapID)
    if not bInQueue then
        return false, QUEUE_MODE.NONE, nil
    end

    local nQueueMode = QUEUE_MODE.TEAM
    if bGlobalRoom then
        nQueueMode = QUEUE_MODE.ROOM
    elseif bSingle then
        nQueueMode = QUEUE_MODE.SINGLE
    end

    return true, nQueueMode, BattleFieldQueueData.GetJoinBattleQueueTime(dwMapID)
end

function UIMonopolyMatchView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:InitData()

    self:InitCurrencyInfo()
    self:UpdateInfo()

    self.nTimerID = self.nTimerID or Timer.AddFrameCycle(self, 15, function ()
        self:OnFrameBreathe()
    end)
end

function UIMonopolyMatchView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIMonopolyMatchView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnSingleMatching, EventType.OnClick, function ()
        self:OperateSingleQueue()
    end)

    UIHelper.BindUIEvent(self.BtnTeamMatching, EventType.OnClick, function ()
        self:OperateTeamQueue()
    end)

    UIHelper.BindUIEvent(self.BtnRoomMatching, EventType.OnClick, function ()
        self:OperateRoomQueue()
    end)

    UIHelper.BindUIEvent(self.BtnCancelMatching, EventType.OnClick, function ()
        self:LeaveMonopolyQueue()
    end)

    UIHelper.BindUIEvent(self.BtnMatchingRule, EventType.OnClick, function ()
        self:OpenQueuePlayRule()
    end)

    UIHelper.BindUIEvent(self.BtnRecruit, EventType.OnClick, function ()
        local tRecruitInfo = Table_GetTeamInfoByMapID(self.nSelectMapID)
        if tRecruitInfo then
            UIMgr.Open(VIEW_ID.PanelTeam, 1, nil, tRecruitInfo.dwID)
        end
    end)
end

function UIMonopolyMatchView:RegEvent()
    local fnOnPartyInfoChanged = function()
        self:ApplyPartyChanged()
        self:ApplyQueueChanged()
        self:UpdateQueueButtons()
    end

    local fnOnRoomInfoChanged = function()
        self:ApplyRoomChanged()
        self:ApplyQueueChanged()
        self:UpdateQueueButtons()
    end

    Event.Reg(self, "PARTY_ADD_MEMBER", fnOnPartyInfoChanged)
    Event.Reg(self, "PARTY_DELETE_MEMBER", fnOnPartyInfoChanged)
    Event.Reg(self, "TEAM_AUTHORITY_CHANGED", fnOnPartyInfoChanged)
    Event.Reg(self, "PARTY_DISBAND", fnOnPartyInfoChanged)

    Event.Reg(self, "CREATE_GLOBAL_ROOM", fnOnRoomInfoChanged)
    Event.Reg(self, "JOIN_GLOBAL_ROOM", fnOnRoomInfoChanged)
    Event.Reg(self, "LEAVE_GLOBAL_ROOM", fnOnRoomInfoChanged)
    Event.Reg(self, "GLOBAL_ROOM_BASE_INFO", fnOnRoomInfoChanged)
    Event.Reg(self, "GLOBAL_ROOM_DETAIL_INFO", fnOnRoomInfoChanged)
    Event.Reg(self, "GLOBAL_ROOM_MEMBER_CHANGE", fnOnRoomInfoChanged)

    Event.Reg(self, "BATTLE_FIELD_STATE_UPDATE", function ()
        self:ApplyQueueChanged()
        self:UpdateBackStateTime()
        self:UpdateQueueButtons()
        self:UpdateBackStateTime()
    end)

    Event.Reg(self, EventType.OnViewClose, function (nViewID)
        if nViewID ~= VIEW_ID.PanelLoading then return end

        UIMgr.Close(self)
    end)
end

function UIMonopolyMatchView:UnRegEvent()
    Event.UnRegAll(self)
end

function UIMonopolyMatchView:OnFrameBreathe()
    self:UpdateCountDown()

    if self.bInQueue then
        self:UpdateMatchTime()
    end

    if self.nBackEndTime then
        self:UpdateBackStateTime()
    end
end

------------------------数据处理------------------------------------

function UIMonopolyMatchView:InitData()
    self.nQueueMode = QUEUE_MODE.NONE
    self.bInQueue = false
    self.nJoinStartTime = nil
    self.bCanTeamQueue = false
    self.bCanRoomQueue = false
    self.nBackEndTime = nil

    self.tQueuePlayInfoList = {}
    self.tQueuePlayInfoMap = {}
    self.tCurrentQueuePlayInfo = nil
    self.tCurrentActivityInfo = nil
    self.nSelectMapID = 0

    self:InitQueuePlayInfo()
    self:InitDefaultSelectMapID()
    self:ApplyPartyChanged()
    self:ApplyRoomChanged()
    self:ApplyQueueChanged()
    self:UpdateBackStateTime()
end

function UIMonopolyMatchView:InitQueuePlayInfo()
    self.tQueuePlayInfoList = {}
    self.tQueuePlayInfoMap = {}

    for dwRootMapID, tConfig in pairs(MonopolyData.tQueuePlayConfig) do
        local tInfo = Table_GetBattleFieldInfo(dwRootMapID)
        if tInfo then
            tInfo.nPriority = tConfig.nPriority or 99
            tInfo.bEnableSingle = tConfig.bEnableSingle == true
            tInfo.bEnableTeam = tConfig.bEnableTeam == true
            tInfo.bEnableRoom = tConfig.bEnableRoom == true

            table.insert(self.tQueuePlayInfoList, tInfo)
            self.tQueuePlayInfoMap[dwRootMapID] = tInfo
        end
    end

    table.sort(self.tQueuePlayInfoList, function(left, right)
        if left.nPriority ~= right.nPriority then
            return left.nPriority < right.nPriority
        end
        return left.dwMapID < right.dwMapID
    end)
end

function UIMonopolyMatchView:InitDefaultSelectMapID()
    local tFirst = self.tQueuePlayInfoList[1]
    if not tFirst then
        return
    end

    self:SetSelectMapID(tFirst.dwMapID)
end

function UIMonopolyMatchView:UpdateCurrentActivityInfo()
    local tInfo = self.tCurrentQueuePlayInfo
    self.tCurrentActivityInfo = nil
    if tInfo and tInfo.dwActivityID and tInfo.dwActivityID ~= 0 then
        self.tCurrentActivityInfo = GetActivityMgrClient().GetActivity(tInfo.dwActivityID)
    end
end

function UIMonopolyMatchView:SetSelectMapID(dwMapID)
    local tInfo = self.tQueuePlayInfoMap and self.tQueuePlayInfoMap[dwMapID]
    if not tInfo then
        return false
    end

    self.nSelectMapID = dwMapID
    self.tCurrentQueuePlayInfo = tInfo
    self:UpdateCurrentActivityInfo()
    self:ApplyRoomChanged()
    self:ApplyQueueChanged()
    return true
end

function UIMonopolyMatchView:GetCurrentQueuePlayInfo()
    return self.tCurrentQueuePlayInfo
end

-- 本服队伍状态同步（这里只维护组队排队开关）
function UIMonopolyMatchView:ApplyPartyChanged()
    local hPlayer = GetClientPlayer()
    self.bCanTeamQueue = hPlayer and hPlayer.IsInParty() and hPlayer.IsPartyLeader() or false
end

-- 跨服房间状态同步（这里只维护房间排队开关）
function UIMonopolyMatchView:ApplyRoomChanged()
    local tQueuePlayInfo = self:GetCurrentQueuePlayInfo()
    local nMinRoomMember = 2
    if tQueuePlayInfo and Table_IsTreasureHuntMap and Table_IsTreasureHuntMap(tQueuePlayInfo.dwMapID) then
        nMinRoomMember = 3
    end

    local bInGlobalRoom = RoomData.IsHaveRoom()
    local bIsRoomOwner = bInGlobalRoom and RoomData.IsRoomOwner()
    local nRoomMemberCount = bInGlobalRoom and RoomData.GetSize() or 0
    self.bCanRoomQueue = bIsRoomOwner and nRoomMemberCount >= nMinRoomMember
end

-- 排队状态同步（是否在队列里、排队模式、排队时间）
function UIMonopolyMatchView:ApplyQueueChanged()
    local tQueuePlayInfo = self:GetCurrentQueuePlayInfo()
    local dwMapID = tQueuePlayInfo and tQueuePlayInfo.dwMapID
    if not dwMapID then
        self.bInQueue = false
        self.nQueueMode = self.QUEUE_MODE.NONE
        self.nJoinStartTime = nil
        return
    end

    local nPrevQueueMode = self.nQueueMode
    local bInQueue, nQueueMode, nPassTime = GetCurrentBattleFieldQueueState(dwMapID)
    self.bInQueue = bInQueue
    self.nQueueMode = nQueueMode

    if not bInQueue then
        self.nJoinStartTime = nil
        return
    end

    if nPassTime ~= nil then
        self.nJoinStartTime = GetCurrentTime() - nPassTime
    elseif not self.nJoinStartTime or nPrevQueueMode ~= nQueueMode then
        self.nJoinStartTime = GetCurrentTime()
    end
end

function UIMonopolyMatchView:GetQueuePlayCountDownText(tInfo)
    if not tInfo or not tInfo.dwActivityID or tInfo.dwActivityID == 0 then
        return ""
    end

    local tActivityInfo = self.tCurrentActivityInfo
    if not tActivityInfo then
        return g_tStrings.STR_COMING_SOON
    end

    local nStartTime = tActivityInfo.nLastStartTime
    if not nStartTime or nStartTime == 0 then
        return g_tStrings.STR_COMING_SOON
    end

    local nLeftTime = nStartTime + tActivityInfo.nDuration - GetCurrentTime()
    if nLeftTime <= 0 then
        return g_tStrings.STR_FB_STORY_MODE_DIABLE
    end

    local szLeftTime = TimeLib.GetTimeText(nLeftTime, nil, nil, nil, nil, "Diable Second")
    return FormatString(g_tStrings.STR_MONOPOLY_QUEUE_LEFT_OPEN_TIME, szLeftTime)
end

function UIMonopolyMatchView:OpenQueuePlayRule()
    UIMgr.Open(VIEW_ID.PanelTutorialLite, 60)

    --[[
    local tInfo = self:GetCurrentQueuePlayInfo()
    if not tInfo or not tInfo.szHelpText or tInfo.szHelpText == "" then
        return
    end

    MessageBox(
    {
        szName = "MonopolyQueueRule",
        szTitle = tInfo.szName,
        szMessage = tInfo.szHelpText,
        bRichText = true,
        bShowClose = true,
        { szOption = g_tStrings.STR_HOTKEY_SURE },
    })
    ]]
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIMonopolyMatchView:UpdateInfo()
    self:UpdateQueueButtons()
    self:UpdateBackStateTime()
    self:UpdateCountDown()
end

function UIMonopolyMatchView:UpdateQueueButtons()
    local tInfo = self:GetCurrentQueuePlayInfo()
    if not tInfo then
        return
    end

    -- 这里集中处理三个匹配入口的界面状态：
    -- 1. 根据玩法开关决定是否显示单人/组队/跨服房间入口
    -- 2. 取消匹配按钮要附带“匹配中…（xx秒）”文案
    -- 3. 跨服房间规则按钮是否显示，只跟 `bEnableRoom` 开关保持一致
    local bSingleQueueing = self.bInQueue and self.nQueueMode == QUEUE_MODE.SINGLE
    local bTeamQueueing = self.bInQueue and self.nQueueMode == QUEUE_MODE.TEAM
    local bRoomQueueing = self.bInQueue and self.nQueueMode == QUEUE_MODE.ROOM
    local bCanSingleQueue = tInfo.bEnableSingle and (not self.bInQueue or bSingleQueueing)
    local bCanTeamQueue = tInfo.bEnableTeam and self.bCanTeamQueue and (not self.bInQueue or bTeamQueueing)
    local bCanRoomQueue = tInfo.bEnableRoom and self.bCanRoomQueue and (not self.bInQueue or bRoomQueueing)

    UIHelper.SetVisible(self.BtnSingleMatching, tInfo.bEnableSingle)
    UIHelper.SetButtonState(self.BtnSingleMatching, BTN_STATE.Normal)
    if not bCanSingleQueue then UIHelper.SetButtonState(self.BtnSingleMatching, BTN_STATE.Disable, "暂不满足匹配条件", true) end

    UIHelper.SetVisible(self.BtnTeamMatching, tInfo.bEnableSingle)
    UIHelper.SetButtonState(self.BtnTeamMatching, BTN_STATE.Normal)
    if not bCanTeamQueue then UIHelper.SetButtonState(self.BtnTeamMatching, BTN_STATE.Disable, "暂不满足匹配条件", true) end

    UIHelper.SetVisible(self.BtnRoomMatching, tInfo.bEnableSingle)
    UIHelper.SetButtonState(self.BtnRoomMatching, BTN_STATE.Normal)
    if not bCanRoomQueue then UIHelper.SetButtonState(self.BtnRoomMatching, BTN_STATE.Disable, "暂不满足匹配条件", true) end

    local nodeWidgetRule = UIHelper.GetParent(self.BtnMatchingRule)
    UIHelper.SetVisible(nodeWidgetRule, tInfo.bEnableRoom)

    UIHelper.SetVisible(self.WidgetContentNormal, not self.bInQueue)
    UIHelper.SetVisible(self.BtnCancelMatching, self.bInQueue)

    local nodeParent = UIHelper.GetParent(self.WidgetContentNormal)
    UIHelper.LayoutDoLayout(nodeParent)

    self:UpdateMatchTime()
end

function UIMonopolyMatchView:UpdateMatchTime()
    if not self.nJoinStartTime then
        return
    end

    local nCost = GetCurrentTime() - self.nJoinStartTime
    local szMatchText = string.format("匹配中…（%s）", FormatMatchCostText(nCost))
    UIHelper.SetString(self.LabelCancelMatching, szMatchText)
end

function UIMonopolyMatchView:UpdateBackStateTime()
    local nTime = BattleFieldQueueData.GetBattleFieldBlackCoolTime()
    if nTime and nTime > 0 then
        self.nBackEndTime = GetCurrentTime() + nTime
    else
        self.nBackEndTime = nil
    end

    local nLeftTime = self.nBackEndTime or 0
    nLeftTime = math.max(0, nLeftTime - GetCurrentTime())

    local szLeftTime = FormatString(g_tStrings.STR_BACKTIME, BattleFieldQueueData.NumberBattleFieldTime(nLeftTime))

    UIHelper.SetString(self.LabelTitle, "再次点击取消匹配")
    if nLeftTime > 0 then
        UIHelper.SetString(self.LabelTitle, szLeftTime)
    end
end

function UIMonopolyMatchView:UpdateCountDown()
    local tInfo = self:GetCurrentQueuePlayInfo()
    if not tInfo then
        return
    end
    local szCountDownText = self:GetQueuePlayCountDownText(tInfo)
    UIHelper.SetString(self.LabelOpenTime, szCountDownText)
end

function UIMonopolyMatchView:InitCurrencyInfo()
    UIHelper.RemoveAllChildren(self.LayoutCoins)
    UIHelper.AddPrefab(PREFAB_ID.WidgetCoin, self.LayoutCoins, CurrencyType.MonopolyCoin)
    UIHelper.CascadeDoLayoutDoWidget(UIHelper.GetParent(self.LayoutCoins), true, true)
end

function UIMonopolyMatchView:OperateSingleQueue()
    if self.bInQueue and self.nQueueMode == QUEUE_MODE.SINGLE then
        self:LeaveMonopolyQueue()
        return
    end
    self:EnterMonopolyQueue(QUEUE_MODE.SINGLE)
end

function UIMonopolyMatchView:OperateTeamQueue()
    if self.bInQueue and self.nQueueMode == QUEUE_MODE.TEAM then
        self:LeaveMonopolyQueue()
        return
    end
    self:EnterMonopolyQueue(QUEUE_MODE.TEAM)
end

function UIMonopolyMatchView:OperateRoomQueue()
    if self.bInQueue and self.nQueueMode == QUEUE_MODE.ROOM then
        self:LeaveMonopolyQueue()
        return
    end
    self:EnterMonopolyQueue(QUEUE_MODE.ROOM)
end

function UIMonopolyMatchView:EnterMonopolyQueue(nQueueMode)
    -- 统一排队入口，当前阶段逻辑如下：
    -- 1. 先确认玩家对象与当前选中玩法有效
    -- 2. 复用现有战场排队/跨服房间协议入口发起请求
    -- 3. 排队状态统一通过 `BATTLE_FIELD_STATE_UPDATE` 等事件回写到 self
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local tQueuePlayInfo = self:GetCurrentQueuePlayInfo()
    if not tQueuePlayInfo then
        return
    end

    if nQueueMode ~= QUEUE_MODE.SINGLE and nQueueMode ~= QUEUE_MODE.TEAM and nQueueMode ~= QUEUE_MODE.ROOM then
        return
    end

    self:ApplyPartyChanged()
    self:ApplyRoomChanged()
    self:UpdateBackStateTime()

    if tQueuePlayInfo.nType == 0 and hPlayer.nCamp == CAMP.NEUTRAL then
        OutputMessage("MSG_SYS", g_tStrings.STR_BATTLEFIELD_NETURAL_NOT_ENTER)
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_BATTLEFIELD_NETURAL_NOT_ENTER)
        return
    end

    local dwMapID = tQueuePlayInfo.dwMapID
    local nGroupID = GetQueueGroupID(tQueuePlayInfo, hPlayer, nQueueMode)
    if nQueueMode == QUEUE_MODE.ROOM then
        if not self.bCanRoomQueue then
            return
        end
        RemoteCallToServer("On_Zhanchang_RoomBattlefield", dwMapID, nGroupID, false)
    else
        if nQueueMode == QUEUE_MODE.TEAM and not self.bCanTeamQueue then
            local bInParty = hPlayer.IsInParty()
            local szTip = bInParty and g_tStrings.STR_JJC_GO_TO_NOT_TEAM_LEADER or g_tStrings.STR_JJC_GO_TO_NOT_TEAM
            OutputMessage("MSG_SYS", szTip)
            OutputMessage("MSG_ANNOUNCE_RED", szTip)
            return
        end
        JoinBattleFieldQueue(dwMapID, nGroupID, nQueueMode == QUEUE_MODE.TEAM)
    end
end

function UIMonopolyMatchView:LeaveMonopolyQueue()
    local tQueuePlayInfo = self:GetCurrentQueuePlayInfo()
    if not tQueuePlayInfo then
        return
    end

    BattleFieldQueueData.DoLeaveBattleFieldQueue(tQueuePlayInfo.dwMapID)
end

return UIMonopolyMatchView