-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UILieXingView
-- Date: 2023-08-02 19:51:59
-- Desc: 列星虚境报名
-- Prefab: PanelLieXing
-- ---------------------------------------------------------------------------------

local UILieXingView       = class("UILieXingView")

local nPersonalScoreIndex = BF_MAP_ROLE_INFO_TYPE.MATCH_LEVEL
local m_tSumPersonalInfo  = {}

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UILieXingView:_LuaBindList()
    self.BtnClose             = self.BtnClose --- 关闭界面
    self.BtnHelp              = self.BtnHelp --- 显示规则
    self.LabelExtraNum        = self.LabelExtraNum --- 本周可额外获得乐游币数目
    self.BtnTeam              = self.BtnTeam --- 组队匹配按钮
    self.BtnPersonal          = self.BtnPersonal --- 个人匹配按钮
    self.BtnMatching          = self.BtnMatching --- 匹配中按钮
    --self.LayoutText           = self.LayoutText --- 右侧文本上层layout
    self.LabelMatchingTimeNum = self.LabelMatchingTimeNum --- 匹配时长
    self.LabelMatchingTime    = self.LabelMatchingTime --- 匹配描述
    --self.WidgetPVPMoney       = self.WidgetPVPMoney --- 右上角pvp货币锚点
    self.LabelNum             = self.LabelNum --- 个人评分
    --self.LabelTime            = self.LabelTime --- 不良记录禁止参战剩余时间

    --self.LabelTitle           = self.LabelTitle --- 左上角标题
    --self.LabelInfoTitle       = self.LabelInfoTitle --- 右方信息的标题

    self.LayoutMatchingTime   = self.LayoutMatchingTime --- 匹配时长的layout

    self.BtnPrePurchasePlan   = self.BtnPrePurchasePlan --- 出装设置按钮

    self.WidgetPVPMoney       = self.WidgetPVPMoney --- 货币组件
end

function UILieXingView:OnEnter(dwNpcID, dwMapID, dwBattlefieldMapType)
    -- 地图ID
    self.dwMapID              = dwMapID
    -- 排队NPC实例ID（非模板ID）
    self.dwNpcID              = dwNpcID
    -- 战场地图类型
    self.dwBattlefieldMapType = dwBattlefieldMapType

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        UIHelper.AddPrefab(PREFAB_ID.WidgetCoin, self.WidgetPVPMoney, CurrencyType.LeYouBi)
        UIHelper.CascadeDoLayoutDoWidget(UIHelper.GetParent(self.WidgetPVPMoney), true, true)
    end

    self:UpdateInfo()

    Timer.AddCycle(self, 0.5, function()
        self:OnUpdateTime()
    end)
end

function UILieXingView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UILieXingView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnHelp, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelBattleFieldRulesLittle, self.dwMapID)
    end)

    --个人匹配
    UIHelper.BindUIEvent(self.BtnPersonal, EventType.OnClick, function()
        if not PakDownloadMgr.UserCheckDownloadMapRes(self.dwMapID, nil, nil, nil, "列星虚境") then
            return
        end

        --UIHelper.SetButtonState(self.BtnPersonal, BTN_STATE.Disable)
        local bInQueue = BattleFieldQueueData.IsInBattleFieldQueue(self.dwMapID)
        if not bInQueue then
            if not BattleFieldQueueData.EnterBattleFieldQueue(self.dwMapID, self.dwBattlefieldMapType, false) then
                UIHelper.SetButtonState(self.BtnPersonal, BTN_STATE.Normal)
            end
        end
    end)

    --组队匹配
    UIHelper.BindUIEvent(self.BtnTeam, EventType.OnClick, function()
        if not PakDownloadMgr.UserCheckDownloadMapRes(self.dwMapID, nil, nil, nil, "列星虚境") then
            return
        end

        local hPlayer = GetClientPlayer()
        if not hPlayer.IsInParty() then
            -- 跳转到招募界面
            if self.dwMapID then
                local tRecruitInfo = Table_GetTeamInfoByMapID(self.dwMapID)
                if tRecruitInfo then
                    UIMgr.Open(VIEW_ID.PanelTeam, 1, nil, tRecruitInfo.dwID)
                end
            end
            return
        end
        if not TeamData.IsTeamLeader() then
            TipsHelper.ShowNormalTip("只有队长才能进行匹配")
            return
        end

        --UIHelper.SetButtonState(self.BtnTeam, BTN_STATE.Disable)
        local bInQueue = BattleFieldQueueData.IsInBattleFieldQueue(self.dwMapID)
        if not bInQueue then
            if not BattleFieldQueueData.EnterBattleFieldQueue(self.dwMapID, self.dwBattlefieldMapType, true) then
                UIHelper.SetButtonState(self.BtnTeam, BTN_STATE.Normal)
            end
        end
    end)

    --取消匹配
    UIHelper.BindUIEvent(self.BtnMatching, EventType.OnClick, function()
        --UIHelper.SetButtonState(self.BtnMatching, BTN_STATE.Disable)
        if BattleFieldQueueData.IsInBattleFieldQueue(self.dwMapID) then
            BattleFieldQueueData.DoLeaveBattleFieldQueue(self.dwMapID)
        end
    end)

    UIHelper.BindUIEvent(self.BtnPrePurchasePlan, EventType.OnClick, function()
        ---@type UIEquipSetView
        UIMgr.Open(VIEW_ID.PanelEquipSet, false)
    end)
end

function UILieXingView:RegEvent()
    --个人战绩
    Event.Reg(self, "ON_SYNC_BF_ROLE_DATA", function(dwPlayerID, dwMapID, bUpdate, eType)
        self:OnSyncBFRoleDate(dwPlayerID, dwMapID, bUpdate, eType)
    end)

    -- 乐游币
    Event.Reg(self, "UPDATE_BF_REMAIN_LYJ", function(nHaveCount, nMaxCount)
        self:UpdateBF_LYJ(nHaveCount, nMaxCount)
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

    Event.Reg(self, EventType.OnClientPlayerLeave, function()
        UIMgr.Close(self)
    end)
end

function UILieXingView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UILieXingView:UpdateInfo()
    self:UpdateTextInfo()
    self:InitBlackStateTime()
    self:UpdateBtnState()

    BattleFieldData.RequestBFRoleData(self.dwMapID)
    if BattleFieldQueueData.szTempPersonalScore ~= "nil" then
        UIHelper.SetString(self.LabelNum, BattleFieldQueueData.szTempPersonalScore)
    end

    RemoteCallToServer("On_Zhanchang_LYJ", self.dwMapID)

    --资源下载Widget
    local scriptDownload = UIHelper.GetBindScript(self.WidgetDownload)
    local nPackID        = PakDownloadMgr.GetMapResPackID(412)
    scriptDownload:OnInitWithPackID(nPackID)
end

function UILieXingView:UpdateTextInfo()
    local szTitle

    if self.dwBattlefieldMapType == BATTLEFIELD_MAP_TYPE.FBBATTLE then
        szTitle = g_tStrings.STR_BATTLE_TITLE_BOMB
    elseif self.dwBattlefieldMapType == BATTLEFIELD_MAP_TYPE.ZOMBIEBATTLE then
        szTitle = g_tStrings.STR_ZOMBIE_TITLE
    end

    --UIHelper.SetString(self.LabelTitle, szTitle)
    --UIHelper.SetString(self.LabelInfoTitle, szTitle)
end

--更新匹配/惩罚时间
function UILieXingView:OnUpdateTime()
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
function UILieXingView:InitMatchTime(dwMapID)
    self.m_bUpdateMatchTime = true
    local nTime             = BattleFieldQueueData.GetJoinBattleQueueTime(dwMapID)
    local nCurrentTime      = GetCurrentTime()
    if nTime then
        self.m_nMatchStartTime = nCurrentTime - nTime
    else
        self.m_nMatchStartTime = nil
    end
    self.m_bUpdateMatchTime = false
end

--界面上更新匹配时间
function UILieXingView:UpdateMatchTime()
    if self.m_nMatchStartTime and not self.m_bUpdateMatchTime then
        local nTime     = GetCurrentTime()
        local nShowTime = nTime - self.m_nMatchStartTime

        local dwMapID   = self.dwMapID
        local bInQueue  = BattleFieldQueueData.IsInBattleFieldQueue(dwMapID)

        if not bInQueue then
            return
        end

        local szTime = BattleFieldQueueData.FormatBattleFieldTime(nShowTime)
        UIHelper.SetString(self.LabelMatchingTimeNum, szTime)
    end
end

--惩罚时间
function UILieXingView:InitBlackStateTime()
    self.m_bUpdateBlackTime = true
    local nTime             = BattleFieldQueueData.GetBattleFieldBlackCoolTime()
    local nCurrentTime      = GetCurrentTime()
    if nTime then
        self.m_nBlackEndTime = nTime + nCurrentTime
    else
        self.m_nBlackEndTime = nil
    end
    self.m_bUpdateBlackTime = false
end

--惩罚时间更新
function UILieXingView:UpdateBlackStateTime()
    if self.m_nBlackEndTime and not self.m_bUpdateBlackTime then
        local nTime     = GetCurrentTime()
        local nShowTime = self.m_nBlackEndTime - nTime
        if nShowTime < 0 then
            nShowTime = 0
        end

        if not BattleFieldQueueData.IsInBattleFieldBlackList() then
            return
        end

        local szTime = "<color=#FFE4A3>" .. BattleFieldQueueData.NumberBattleFieldTime(nShowTime) .. "</color>"
        --UIHelper.SetRichText(self.LabelTime, FormatString(g_tStrings.STR_BATTLEFIELD_BLACK_LIST, szTime))
    end
end

function UILieXingView:UpdateBtnState()
    local bInQueue         = BattleFieldQueueData.IsInBattleFieldQueue(self.dwMapID)
    local bCanOperateMatch = not BattleFieldQueueData.IsInBattleFieldBlackList()

    local tbNotify         = BattleFieldQueueData.GetBattleFieldNotify(self.dwMapID)
    local bMatchSuccess    = tbNotify and tbNotify.nNotifyType == BATTLE_FIELD_NOTIFY_TYPE.JOIN_BATTLE_FIELD_QUEUE

    --UIHelper.SetVisible(self.LabelTime, not bCanOperateMatch)
    UIHelper.SetVisible(self.LayoutMatchingTime, bInQueue)
    UIHelper.SetVisible(self.BtnPersonal, not bInQueue and not bMatchSuccess)
    UIHelper.SetVisible(self.BtnTeam, not bInQueue and not bMatchSuccess)
    UIHelper.SetVisible(self.BtnMatching, bInQueue or bMatchSuccess)

    UIHelper.SetButtonState(self.BtnPersonal, bCanOperateMatch and BTN_STATE.Normal or BTN_STATE.Disable)
    UIHelper.SetButtonState(self.BtnMatching, not bMatchSuccess and BTN_STATE.Normal or BTN_STATE.Disable)

    if bCanOperateMatch and bInQueue then
        self:InitMatchTime(self.dwMapID)
    else
        self:InitBlackStateTime()
    end

    --UIHelper.LayoutDoLayout(self.LayoutText)
end

function UILieXingView:OnSyncBFRoleDate(dwPlayerID, dwMapID, bUpdate, eType)
    if eType ~= BF_ROLE_DATA_TYPE.HISTORY then
        return
    end
    if dwPlayerID ~= UI_GetClientPlayerID() then
        return
    end
    if dwMapID ~= self.dwMapID then
        return
    end

    m_tSumPersonalInfo                       = GetBFRoleData(dwPlayerID, dwMapID, eType)
    local nScore                             = m_tSumPersonalInfo[nPersonalScoreIndex] or 0
    BattleFieldQueueData.szTempPersonalScore = tostring(nScore)

    UIHelper.SetString(self.LabelNum, nScore)
end

function UILieXingView:UpdateBF_LYJ(nHaveCount, nMaxCount)
    local nAcquireNum = nMaxCount - nHaveCount
    if nAcquireNum < 0 then
        nAcquireNum = 0
    end

    ---- todo: 这个暂时用飞沙令的，后续添加了乐游币的再调整
    --self.coinScript = self.coinScript or UIHelper.AddPrefab(PREFAB_ID.WidgetCoin, self.WidgetPVPMoney, CurrencyType.FeiShaWand)
    --self.coinScript:SetCurrencyCount(nHaveCount)

    UIHelper.SetString(self.LabelExtraNum, nAcquireNum)
end

return UILieXingView