-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIBattleFieldInformationView
-- Date: 2022-12-20 14:29:37
-- Desc: 战场选关匹配界面 PanelBattleFieldInformation
-- ---------------------------------------------------------------------------------

local UIBattleFieldInformationView = class("UIBattleFieldInformationView")

local COUNT_PER_REWARD = 7500
local REWARD_INDEX = 86027

local MATCH_CD = 5

--匹配的战场类型添加
local tOpenBattleFileType = { 0, 2, 4, 5, 6, 7, 9 }

local tWeekName = --g_tStrings.tWeek
{
    [0] = "周日",
    [1] = "周一",
    [2] = "周二",
    [3] = "周三",
    [4] = "周四",
    [5] = "周五",
    [6] = "周六",
}

--战场名称
local tMapIDToNameImgPath = {
    [BATTLE_FIELD_MAP_ID.JIU_GONG_QI_GU]        = "UIAtlas2_Pvp_PvpEntrance_LabelJiuGong.png", --九宫棋谷
    [BATTLE_FIELD_MAP_ID.SHEN_NONG_YIN]         = "UIAtlas2_Pvp_PvpEntrance_LabelShenLong.png", --神农洇
    [BATTLE_FIELD_MAP_ID.SAN_GUO_GU_ZHAN_CHANG] = "UIAtlas2_Pvp_PvpEntrance_LabelSanGuo.png", --三国古战场
    [BATTLE_FIELD_MAP_ID.FU_XIANG_QIU]          = "UIAtlas2_Pvp_PvpEntrance_LabelXiangQiu.png", --浮香丘
    [BATTLE_FIELD_MAP_ID.XI_FENG_GU_DAO]        = "UIAtlas2_Pvp_PvpEntrance_LabelXiFeng.png", --西风古道
    [BATTLE_FIELD_MAP_ID.YUN_HU_TIAN_DI]        = "UIAtlas2_Pvp_PvpEntrance_LabelYunHu.png", --云湖天池
    [BATTLE_FIELD_MAP_ID.XUE_YU_GUAN_CHENG]     = "UIAtlas2_Pvp_PvpEntrance_LabelXueYu.png", --雪域关城
}

--地图人数
local tMapIDToPlayerNum = {
    [BATTLE_FIELD_MAP_ID.JIU_GONG_QI_GU]        = "25对25", --九宫棋谷
    [BATTLE_FIELD_MAP_ID.SHEN_NONG_YIN]         = "15对15", --神农洇
    [BATTLE_FIELD_MAP_ID.SAN_GUO_GU_ZHAN_CHANG] = "15对15", --三国古战场
    [BATTLE_FIELD_MAP_ID.FU_XIANG_QIU]          = "15对15", --浮香丘
    [BATTLE_FIELD_MAP_ID.XI_FENG_GU_DAO]        = "25对25", --西风古道
    [BATTLE_FIELD_MAP_ID.YUN_HU_TIAN_DI]        = "10对10", --云湖天池
    [BATTLE_FIELD_MAP_ID.XUE_YU_GUAN_CHENG]     = "10对10", --雪域关城
}

--地图背景
local tMapIDToBgPath = {
    [BATTLE_FIELD_MAP_ID.JIU_GONG_QI_GU]        = "Texture/PvpBg/img_bg6.png", --九宫棋谷
    [BATTLE_FIELD_MAP_ID.SHEN_NONG_YIN]         = "Texture/PvpBg/img_bg1.png", --神农洇
    [BATTLE_FIELD_MAP_ID.SAN_GUO_GU_ZHAN_CHANG] = "Texture/PvpBg/img_bg2.png", --三国古战场
    [BATTLE_FIELD_MAP_ID.FU_XIANG_QIU]          = "Texture/PvpBg/img_bg5.png", --浮香丘
    [BATTLE_FIELD_MAP_ID.XI_FENG_GU_DAO]        = "Texture/PvpBg/img_bg4.png", --西风古道
    [BATTLE_FIELD_MAP_ID.YUN_HU_TIAN_DI]        = "Texture/PvpBg/img_bg3.png", --云湖天池
    [BATTLE_FIELD_MAP_ID.XUE_YU_GUAN_CHENG]     = "Texture/PvpBg/img_bg7.png", --雪域关城
}

local m_tBattleListInfo = {}
local m_tBattleOpen = {}
local m_tBattleItemInfo = {}

local m_nMatchStartTime = nil
local m_nBlackEndTime = nil
local m_bUpdateMatchTime = false
local m_bUpdateBlackTime = false


function UIBattleFieldInformationView:OnEnter(dwNpcID)
    self.dwNpcID = dwNpcID

    if not self.bInit then
        self:InitUI()

        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        Timer.AddFrameCycle(self, 1, function()
            self:OnUpdate()
        end)

        UIHelper.AddPrefab(PREFAB_ID.WidgetCoin, self.WidgetPVPMoney, CurrencyType.Prestige)
        UIHelper.AddPrefab(PREFAB_ID.WidgetCoin, self.WidgetPVPMoney, CurrencyType.TitlePoint)

        UIHelper.AddPrefab(PREFAB_ID.WidgetSkillConfiguration, self.WidgetSkillConfiguration)
    end

    self:InitBattleFieldMapInfo()
    self:InitBlackStateTime()

    --按缓存的地图ID先设置背景图等信息，避免闪烁
    if BattleFieldData.nTodayBattleFieldMapID then
        self:SetMapInfo(BattleFieldData.nTodayBattleFieldMapID)
    end

    self:UpdateInfo()
end

function UIBattleFieldInformationView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIBattleFieldInformationView:OnUpdate()
    self:UpdateMatchTime()
    self:UpdateBlackStateTime()
    --self:UpdateNPCCanDialog() --2023.12.22 【玩法-对抗】战场新增：可以直接在界面进行匹配，不用去到NPC处
end

function UIBattleFieldInformationView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
    UIHelper.BindUIEvent(self.BtnDetail, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelBattleFieldRulesNew, self.dwMapID)
    end)
    UIHelper.BindUIEvent(self.BtnPersonal, EventType.OnClick, function()
        local tMapIDList = {self.dwMapID, BattleFieldQueueData.GetExtraMapID(self.dwMapID)}
        if not PakDownloadMgr.UserCheckDownloadMapRes(tMapIDList, nil, nil, nil, "战场") then
            return
        end

        if self.nNextMatchTime and GetCurrentTime() < self.nNextMatchTime then
            TipsHelper.ShowNormalTip("操作频繁，请稍后重试")
            return
        end

        UIHelper.SetButtonState(self.BtnPersonal, BTN_STATE.Disable)
        local bInQueue = BattleFieldQueueData.IsInBattleFieldQueue(self.dwMapID)
        if not bInQueue then
            if not BattleFieldQueueData.EnterBattleFieldQueue(self.dwMapID, self.nType, false) then
                UIHelper.SetButtonState(self.BtnPersonal, BTN_STATE.Normal)
            end
        end
    end)
    UIHelper.BindUIEvent(self.BtnTeam, EventType.OnClick, function()
        local tMapIDList = {self.dwMapID, BattleFieldQueueData.GetExtraMapID(self.dwMapID)}
        if not PakDownloadMgr.UserCheckDownloadMapRes(tMapIDList, nil, nil, nil, "战场") then
            return
        end

        if self.nNextMatchTime and GetCurrentTime() < self.nNextMatchTime then
            TipsHelper.ShowNormalTip("操作频繁，请稍后重试")
            return
        end

        local player = GetClientPlayer()
        if not player then
            return
        end

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

        UIHelper.SetButtonState(self.BtnTeam, BTN_STATE.Disable)
        local bInQueue = BattleFieldQueueData.IsInBattleFieldQueue(self.dwMapID)
        if not bInQueue then
            if not BattleFieldQueueData.EnterBattleFieldQueue(self.dwMapID, self.nType, true) then
                UIHelper.SetButtonState(self.BtnTeam, BTN_STATE.Normal)
            end
        end
    end)
    UIHelper.BindUIEvent(self.BtnRoom, EventType.OnClick, function()
        local tMapIDList = {self.dwMapID, BattleFieldQueueData.GetExtraMapID(self.dwMapID)}
        if not PakDownloadMgr.UserCheckDownloadMapRes(tMapIDList, nil, nil, nil, "战场") then
            return
        end

        if self.nNextMatchTime and GetCurrentTime() < self.nNextMatchTime then
            TipsHelper.ShowNormalTip("操作频繁，请稍后重试")
            return
        end

        UIHelper.SetButtonState(self.BtnRoom, BTN_STATE.Disable)
        local bInQueue = BattleFieldQueueData.IsInBattleFieldQueue(self.dwMapID)
        if not bInQueue then
            if not BattleFieldQueueData.EnterBattleFieldQueue(self.dwMapID, self.nType, false, true) then
                UIHelper.SetButtonState(self.BtnRoom, BTN_STATE.Normal)
            end
        end
    end)
    UIHelper.BindUIEvent(self.BtnMatching, EventType.OnClick, function()
        UIHelper.SetButtonState(self.BtnMatching, BTN_STATE.Disable)
        if BattleFieldQueueData.IsInBattleFieldQueue(self.dwMapID) then
            self.nNextMatchTime = GetCurrentTime() + MATCH_CD
            BattleFieldQueueData.DoLeaveBattleFieldQueue(self.dwMapID)
        end
    end)

    UIHelper.BindUIEvent(self.BtnStageStore, EventType.OnClick, function()
        ShopData.OpenSystemShopGroup(1, 918)
    end)

    UIHelper.BindUIEvent(self.BtnTeamup, EventType.OnClick, function()
        if self.dwMapID then
            local tRecruitInfo = Table_GetTeamInfoByMapID(self.dwMapID)
            if tRecruitInfo then
                UIMgr.Open(VIEW_ID.PanelTeam, 1, nil, tRecruitInfo.dwID)
            end
        end
    end)

    UIHelper.SetTouchEnabled(self.WidgetDetail, true)
    UIHelper.BindUIEvent(self.WidgetDetail, EventType.OnClick, function()
        local tLine = g_tTable.StringArenaCorpsPanel:Search("STR_DS_BF2TIPS")
        local szContent = tLine and UIHelper.GBKToUTF8(tLine.szString)
        if not string.is_nil(szContent) then
            szContent = string.gsub(szContent, "\\n", "\n")
            TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.WidgetDetail, TipsLayoutDir.RIGHT_CENTER, szContent)
        end
    end)

    UIHelper.BindUIEvent(self.WidgetRewardTip2, EventType.OnClick, function()
        local tLine = g_tTable.StringArenaCorpsPanel:Search("STR_SHUANGBEIWEIM")
        local szContent = tLine and UIHelper.GBKToUTF8(tLine.szString)
        if not string.is_nil(szContent) then
            szContent = string.gsub(szContent, "\\n", "\n")
            TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.WidgetRewardTip2, TipsLayoutDir.BOTTOM_RIGHT, szContent)
        end
    end)

    UIHelper.BindUIEvent(self.BtnDetail2, EventType.OnClick, function()
        local tLine = g_tTable.StringArenaCorpsPanel:Search("STR_KUAFURULE")
        local szContent = tLine and UIHelper.GBKToUTF8(tLine.szString)
        if not string.is_nil(szContent) then
            szContent = string.gsub(szContent, "\\\\n", "\n")
            szContent = ParseTextHelper.ParseNormalText(szContent)
            TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.BtnDetail2, TipsLayoutDir.TOP_LEFT, szContent)
        end
    end)

    UIHelper.BindUIEvent(self.BtnReputation, EventType.OnClick, function()
        if not self.tbReputationInfo then
            return
        end

        UIMgr.Open(VIEW_ID.PanelPlayerReputationPop, self.tbReputationInfo)
    end)
end

function UIBattleFieldInformationView:RegEvent()
    Event.Reg(self, EventType.OnClientPlayerLeave, function(nPlayerID)
        UIMgr.Close(self)
    end)
    Event.Reg(self, EventType.OnSendSystemAnnounce, function(szAnnounce, szColor)
        --操作过于频繁
        self:UpdateButtonState()
    end)
    Event.Reg(self, "JOIN_BATTLE_FIELD_QUEUE", function(dwMapID, nCode, dwRoleID, szRoleName)
        --若加入队列失败，则更新按钮状态
        if nCode ~= BATTLE_FIELD_RESULT_CODE.SUCCESS then
            self:UpdateButtonState()
        else
            --开始排队后关闭界面
            --UIMgr.Close(self)
        end
    end)

    --剩余双倍声望
    Event.Reg(self, "ON_BATTLEFIELD_DOUBLE_PRESTIGE_DATA", function(nWeekReveived, nWeekLimit)
        BattleFieldQueueData.Log("ON_BATTLEFIELD_DOUBLE_PRESTIGE_DATA", nWeekReveived, nWeekLimit)
        local nRemainDoublePrestige = nWeekLimit - nWeekReveived
        UIHelper.SetString(self.LabelExtraNum, nRemainDoublePrestige)

        UIHelper.SetRichText(self.RichTextDoublePrestige, string.format("·周双倍威名点：<color=#FFE26E>%d</color>/%d", nWeekReveived, nWeekLimit))
        local nProgress = nWeekLimit > 0 and nWeekReveived / nWeekLimit or 0
        UIHelper.SetProgressBarPercent(self.ProgressBarGradeProgress, nProgress * 100)

        --道具奖励
        UIHelper.RemoveAllChildren(self.WidgetRewardTip1)
        local nCurCount = math.floor(nWeekReveived / COUNT_PER_REWARD)
        local nTotalCount = math.floor(nWeekLimit / COUNT_PER_REWARD)
        local bCompleted = nCurCount == nTotalCount and nTotalCount ~= 0

        UIHelper.SetString(self.LabelRewardNum, nCurCount .. "/" .. nTotalCount)
        UIHelper.SetVisible(self.ImgShareRewardGetBg, bCompleted)
        UIHelper.SetVisible(self.ImgShareRewardGet, bCompleted)

        local dwTabType, dwID = 5, REWARD_INDEX
        local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_44, self.WidgetRewardTip1)
        itemScript:OnInitWithTabID(dwTabType, dwID)
        itemScript:SetSelectChangeCallback(function(nItemID, bSelected, nTabType, nTabID)
            if bSelected then
                local tips, scriptTip = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, self.WidgetRewardTip1, TipsLayoutDir.RIGHT_CENTER)
                scriptTip:OnInitWithTabID(dwTabType, dwID)
                self.scriptIcon = itemScript
            else
                self.scriptIcon = nil
            end
        end)
    end)

    --战场状态更新（匹配状态等）
    Event.Reg(self, "BATTLE_FIELD_STATE_UPDATE", function()
        --BattleFieldQueueData.Log("BATTLE_FIELD_STATE_UPDATE", "StackTrace: " .. string.split(debug.traceback(),"\n")[6])
        self:UpdateButtonState()
    end)

    --匹配时间
    Event.Reg(self, "BATTLE_FIELD_UPDATE_TIME", function()
        --BattleFieldQueueData.Log("[Obsolete] BATTLE_FIELD_UPDATE_TIME")
        --空
    end)

    --今日战场类型
    Event.Reg(self, "GET_TODAY_ZHANCHANG_RESPOND", function(tBattleOpen)
        BattleFieldQueueData.Log("GET_TODAY_ZHANCHANG_RESPOND")
        --LOG.TABLE(tBattleOpen)
        m_tBattleOpen = tBattleOpen
        self:InitBattleFieldActivity()
        self:UpdateButtonState()
    end)

    --同步角色战场数据
    Event.Reg(self, "ON_SYNC_BF_ROLE_DATA", function(dwPlayerID, dwMapID, bUpdate, eType)
        BattleFieldQueueData.Log("ON_SYNC_BF_ROLE_DATA", dwPlayerID, dwMapID, bUpdate, eType)
        self:OnSyncBFRoleDate(dwPlayerID, dwMapID, bUpdate, eType)
    end)

    ---------------- 周常奖励相关 ----------------

    --奖励
    Event.Reg(self, "ON_BATTLEFIELD_REWARD_DATA", function(nEnterTime, tReward, dwMapID)
        tReward = tReward or {}
        self:UpdateNormalRewardInfo(tReward.win)
        BattleFieldQueueData.Log("[Obsolete] ON_BATTLEFIELD_REWARD_DATA", nEnterTime, tReward, dwMapID)
        --现在奖励都是一样的，先不用处理了
    end)

    Event.Reg(self, "ON_BATTLE_ZHOU_CHANG_NOTIFY", function(dwMapID, bFinished, nValue, nMaxValue, tReward)
        BattleFieldQueueData.Log("[Obsolete] ON_BATTLE_ZHOU_CHANG_NOTIFY", dwMapID, bFinished, nValue, nMaxValue, tReward)
        --现在奖励都是一样的，先不用处理了
    end)

    ---------------- 非阵营战场相关 ----------------

    --TODO 这是啥
    Event.Reg(self, "UPDATE_BF_REMAIN_QQC", function(dwWeekNumber, dwHaveNumber)
        BattleFieldQueueData.Log("[TODO] UPDATE_BF_REMAIN_QQC", dwWeekNumber, dwHaveNumber)
    end)

    ---------------- 匹配队伍相关 ----------------

    --添加成员
    Event.Reg(self, "PARTY_ADD_MEMBER", function()
        -- BattleFieldQueueData.Log("PARTY_ADD_MEMBER")
        self:UpdateButtonState()
    end)
    --删除成员
    Event.Reg(self, "PARTY_DELETE_MEMBER", function()
        -- BattleFieldQueueData.Log("PARTY_DELETE_MEMBER")
        self:UpdateButtonState()
    end)
    --队长变更
    Event.Reg(self, "TEAM_AUTHORITY_CHANGED", function()
        -- BattleFieldQueueData.Log("TEAM_AUTHORITY_CHANGED")
        self:UpdateButtonState()
    end)
    --解散
    Event.Reg(self, "PARTY_DISBAND", function()
        -- BattleFieldQueueData.Log("PARTY_DISBAND")
        self:UpdateButtonState()
    end)
    Event.Reg(self, "CREATE_GLOBAL_ROOM", function()
        self:UpdateButtonState()
    end)
    Event.Reg(self, "JOIN_GLOBAL_ROOM", function()
        self:UpdateButtonState()
    end)
    Event.Reg(self, "GLOBAL_ROOM_MEMBER_CHANGE", function()
        self:UpdateButtonState()
    end)
    Event.Reg(self, "LEAVE_GLOBAL_ROOM", function()
        self:UpdateButtonState()
    end)
    Event.Reg(self, "GLOBAL_ROOM_BASE_INFO", function()
        self:UpdateButtonState()
    end)
    Event.Reg(self, "GLOBAL_ROOM_DETAIL_INFO", function()
        self:UpdateButtonState()
    end)

    Event.Reg(self, "SCENE_BEGIN_LOAD", function()
        UIMgr.Close(self)
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        if self.scriptIcon then
            self.scriptIcon:RawSetSelected(false)
            self.scriptIcon = nil
        end
    end)

    --信誉分
    Event.Reg(self, EventType.OnGetPrestigeInfoRespond, function(dwPlayerID, tbInfo)
        if dwPlayerID == g_pClientPlayer.dwID then
            self.tbReputationInfo = tbInfo
        end
    end)
end

function UIBattleFieldInformationView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIBattleFieldInformationView:InitUI()
    for i = 1, 7 do
        local widgetTabList = self.WidgetTabList:getChildByName("WidgetTabList" .. i)

        local widgetNormal = widgetTabList:getChildByName("WidgetNormal0" .. i)
        local widgetSelect = widgetTabList:getChildByName("WidgetSelect0" .. i)
        local labelNormal  = widgetNormal and widgetNormal:getChildByName("LabelNormalAll0" .. i)
        local labelSelect  = widgetSelect and widgetSelect:getChildByName("LabelUpAll0" .. i)

        local szWidgetNormalName = "ImgNormalAll"    .. i
        local szWidgetSelectName = "ImgUpAll"        .. i
        local szLabelNormalName  = "LabelNormalAll"  .. i
        local szLabelSelectName  = "LabelUpAll"      .. i

        self[szWidgetNormalName] = widgetNormal     --ImgNormalAll1     ~ ImgNormalAll7
        self[szWidgetSelectName] = widgetSelect     --ImgUpAll1         ~ ImgUpAll7
        self[szLabelNormalName]  = labelNormal      --LabelNormalAll1   ~ LabelNormalAll7
        self[szLabelSelectName]  = labelSelect      --LabelUpAll1       ~ LabelUpAll7

        UIHelper.SetVisible(widgetNormal, true)
        UIHelper.SetVisible(widgetSelect, false)
        UIHelper.SetString(labelNormal, "")
        UIHelper.SetString(labelSelect, "")
    end

    --开UI前先把原来UI预制里的数据清一下，因为要等服务器回数据才能显示，防止把一些怪东西显示出来
    UIHelper.SetString(self.LabelNum, "")
    UIHelper.SetString(self.LabelExtraNum, "")
    UIHelper.SetString(self.LabelRemainExtraNum, "")
    UIHelper.SetString(self.LabelReward, "")
    UIHelper.SetString(self.LabelFieldText, "")
    UIHelper.SetString(self.LabelBattleText, "")
    UIHelper.SetVisible(self.LabelTime, false)
    UIHelper.SetVisible(self.LabelMatchingTime, false)

    UIHelper.LayoutDoLayout(self.WidgetGrade)
    UIHelper.LayoutDoLayout(self.LayoutText)
end

function UIBattleFieldInformationView:UpdateInfo()
    RemoteCallToServer("On_XinYu_GetInfo", g_pClientPlayer.dwID)

    self:UpdateButtonState()

    -- local hNpc = GetNpc(self.dwNpcID)
    -- local dwMapID = ShowDesertStormPage(hNpc.dwTemplateID)
    local dwMapID = 52 --阵营战场

    BattleFieldData.RequestBFRoleData(dwMapID) --角色数据，返回ON_SYNC_BF_ROLE_DATA
    --注意C++那边请求角色战场数据有CD，可能无法立刻拿到数据；为防止当前无法请求到数据，先尝试用上一轮的临时数据显示
    if BattleFieldQueueData.szTempPersonalScore then
        UIHelper.SetString(self.LabelNum, BattleFieldQueueData.szTempPersonalScore)
        UIHelper.LayoutDoLayout(self.WidgetGrade)
    end

    self:RemoteCallToServerInternal("On_Zhanchang_DoublePrestige") --双倍声望，返回ON_BATTLEFIELD_DOUBLE_PRESTIGE_DATA
    self:RemoteCallToServerInternal("On_Zhanchang_GetTodayZhanchang") --今日战场，返回GET_TODAY_ZHANCHANG_RESPOND
    self:RemoteCallToServerInternal("On_Zhanchang_QQC") --这是啥？返回UPDATE_BF_REMAIN_QQC

    if self.nType == 0 then
        self:RemoteCallToServerInternal("On_Zhanchang_Count", self.dwMapID) --ON_BATTLEFIELD_REWARD_DATA
    end
    self:RemoteCallToServerInternal("On_Zhanchang_LYB", self.dwMapID) --周常？返回ON_BATTLE_ZHOU_CHANG_NOTIFY

    if g_pClientPlayer then
        local nRemainNum = g_pClientPlayer.GetPrestigeRemainSpace()
        UIHelper.SetString(self.LabelRemainExtraNum, nRemainNum)
    end
end

function UIBattleFieldInformationView:InitBattleFieldMapInfo()
    if self.bIsInitBFMapInfo then return end

    local nRow = g_tTable.BattleField:GetRowCount()
    for i = 2, nRow, 1 do
        local tLine = g_tTable.BattleField:GetRow(i)
        if CheckIsInTable(tOpenBattleFileType, tLine.nType) then
            local tBFMapInfo = {
                dwMapID = tLine.dwMapID,
                szMapName = UIHelper.GBKToUTF8(tLine.szName),
                nType = tLine.nType,
                szActivityID = tLine.szActivityID,
                szTimeTip = UIHelper.GBKToUTF8(tLine.szTimeTip)
            }
            m_tBattleListInfo[tLine.dwMapID] = tBFMapInfo
        end
    end

    self.bIsInitBFMapInfo = true
end

--初始化左边活动列表
function UIBattleFieldInformationView:InitBattleFieldActivity()
    local nTime = GetCurrentTime()
    local tNowTime = TimeToDate(nTime)
    local nCurrWeek = tNowTime.weekday

    local nTodayWeekIndex
    for dwMapID, tInfo in pairs(m_tBattleListInfo) do
        if MapHelper.GetBattleFieldType(dwMapID) == BATTLEFIELD_MAP_TYPE.BATTLEFIELD then
            local tWeek = self:GetCurrAcivityWeek(tInfo.szActivityID, dwMapID)
            if not IsEmpty(tWeek) then
                for _, tWeekDay in pairs(tWeek) do
                    if tWeekDay.nWeek then
                        local szWeek = tWeekDay.szWeek
                        local nWeekIndex = (tWeekDay.nWeek - nCurrWeek + 1) % 7
                        if nWeekIndex == 0 then
                            nWeekIndex = 7
                        end

                        local bToday = string.find(szWeek, g_tStrings.STR_TODAY_TIME) ~= nil

                        m_tBattleItemInfo[nWeekIndex] = {
                            nWeekIndex = nWeekIndex,
                            szWeek = szWeek,
                            dwMapID = dwMapID,
                            bToday = bToday
                        }

                        if bToday then
                            szWeek = szWeek
                        end

                        local szItemName = szWeek .. " " .. tInfo.szMapName

                        -- 2024.4.18 名称已改表处理
                        -- local nExtraMapID = BattleFieldQueueData.GetExtraMapID(dwMapID)
                        -- local tExtraMapInfo = nExtraMapID and m_tBattleListInfo[nExtraMapID]
                        -- if tExtraMapInfo and not string.is_nil(tExtraMapInfo.szMapName) then
                        --     szItemName = szItemName .. "/" .. tExtraMapInfo.szMapName
                        -- end
                        UIHelper.SetString(self["LabelNormalAll" .. nWeekIndex], szItemName)
                        UIHelper.SetString(self["LabelUpAll" .. nWeekIndex], szItemName)

                        if bToday then
                            nTodayWeekIndex = nWeekIndex
                        end
                    end
                end
            end
        end
    end

    if nTodayWeekIndex then
        self:SelectBattleMap(nTodayWeekIndex)
    end
end

function UIBattleFieldInformationView:SelectBattleMap(nWeekIndex)

    local tBattleInfo = m_tBattleItemInfo[nWeekIndex]
    if tBattleInfo then
        local dwMapID = tBattleInfo.dwMapID

        local tMap = m_tBattleListInfo[dwMapID]
        self.dwMapID = tMap.dwMapID
        self.nType = tMap.nType
        self.szMapName = tMap.szMapName
        self.szActivityID = tMap.szActivityID
        self.szTimeTip = tMap.szTimeTip

        local szTimeTip = "·" .. FormatString(tMap.szTimeTip, tBattleInfo.szWeek)
        UIHelper.SetString(self.LabelReward, szTimeTip)
        UIHelper.LayoutDoLayout(self.LayoutText)

        if self.nType == 0 then
            self:RemoteCallToServerInternal("On_Zhanchang_Count", self.dwMapID) --ON_BATTLEFIELD_REWARD_DATA
        end
    else
        UIHelper.SetString(self.LabelReward, "")
    end

    for i = 1, 7 do
        UIHelper.SetVisible(self["ImgNormalAll" .. i], i ~= nWeekIndex)
        UIHelper.SetVisible(self["ImgUpAll" .. i], i == nWeekIndex)
    end

    self:SetMapInfo(self.dwMapID)

    --资源下载Widget
    local scriptDownload = UIHelper.GetBindScript(self.WidgetDownload)
    local nPackID = PakDownloadMgr.GetMapResPackID(self.dwMapID)
    local nExtraMapID = BattleFieldQueueData.GetExtraMapID(self.dwMapID)
    local nExtraPackID = nExtraMapID and PakDownloadMgr.GetMapResPackID(nExtraMapID)
    local tPackIDList = {nPackID, nExtraPackID}
    scriptDownload:OnInitWithPackIDList(tPackIDList)
end

function UIBattleFieldInformationView:SetMapInfo(dwMapID)
    local tMap = m_tBattleListInfo[dwMapID]
    local szMapName = tMap and tMap.szMapName or UIHelper.GBKToUTF8(Table_GetMapName(dwMapID))

    --Title
    UIHelper.SetString(self.LabelFieldText, szMapName)

    --Title图片
    UIHelper.SetSpriteFrame(self.ImgBattleName, tMapIDToNameImgPath[dwMapID], false)

    --人数
    UIHelper.SetString(self.LabelBattleText, tMapIDToPlayerNum[dwMapID])

    --背景图
    UIHelper.SetTexture(self.ImgBg2, tMapIDToBgPath[dwMapID])

    UIHelper.LayoutDoLayout(self.WidgetFieldText)
end

--更新匹配状态
function UIBattleFieldInformationView:UpdateButtonState()
    local dwMapID = self.dwMapID

    if not dwMapID then
        LOG.INFO("[BattleFieldQueue] dwMapID is nil")
        UIHelper.SetVisible(self.LabelTime, false)
        UIHelper.SetVisible(self.LabelMatchingTime, false)
        UIHelper.SetVisible(self.BtnPersonal, true)
        -- UIHelper.SetVisible(self.BtnTeam, true)
        -- UIHelper.SetVisible(self.BtnRoom, true)
        UIHelper.SetVisible(self.WidgetBtnList, true)
        UIHelper.SetVisible(self.BtnMatching, false)
        UIHelper.LayoutDoLayout(self.WidgetAnchorButton)

        UIHelper.SetButtonState(self.BtnPersonal, BTN_STATE.Normal)
        UIHelper.SetButtonState(self.BtnTeam, BTN_STATE.Normal)
        UIHelper.SetButtonState(self.BtnRoom, BTN_STATE.Normal)
        UIHelper.SetButtonState(self.BtnMatching, BTN_STATE.Normal)

        UIHelper.LayoutDoLayout(self.LayoutText)
        return
    end

    local bInQueue, bSingle, bGlobalRoom = BattleFieldQueueData.IsInBattleFieldQueue(dwMapID)
    local bCanOperateMatch = not BattleFieldQueueData.IsInBattleFieldBlackList() and m_tBattleOpen[dwMapID]
    local bCanJoinTeam = false
    local bCanJoinRoom = false

    local tbNotify = BattleFieldQueueData.GetBattleFieldNotify(dwMapID)
    local bMatchSuccess = tbNotify and tbNotify.nNotifyType == BATTLE_FIELD_NOTIFY_TYPE.JOIN_BATTLE_FIELD
    local bCanJoin = not bInQueue and not bMatchSuccess

    local player = GetClientPlayer()
    if player and player.IsInParty() and player.IsPartyLeader() then
        bCanJoinTeam = true
    end

    local szRoomTip
    local bRoomOwner = RoomData.IsRoomOwner()
    local nRoomSize = RoomData.GetSize()
    if bRoomOwner and nRoomSize > 1 then
        bCanJoinRoom = true
    elseif not bRoomOwner then
        szRoomTip = "只有跨服房间房主才可进行跨服匹配"
    elseif nRoomSize <= 1 then
        szRoomTip = "跨服房间中至少有两名成员才可进行跨服匹配"
    end

    LOG.INFO("[BattleFieldQueue] UpdateButtonState, dwMapID: %d, bInQueue: %s, bCanOperateMatch: %s, bCanJoinTeam: %s, bCanJoinRoom: %s",
    dwMapID, tostring(bInQueue), tostring(bCanOperateMatch), tostring(bCanJoinTeam), tostring(bCanJoinRoom))

    UIHelper.SetVisible(self.LabelTime, not bCanOperateMatch)
    UIHelper.SetVisible(self.LabelMatchingTime, bInQueue)
    UIHelper.SetVisible(self.BtnPersonal, bCanJoin)
    -- UIHelper.SetVisible(self.BtnTeam, bCanJoin)
    -- UIHelper.SetVisible(self.BtnRoom, bCanJoin)
    UIHelper.SetVisible(self.WidgetBtnList, bCanJoin)
    UIHelper.SetVisible(self.BtnMatching, not bCanJoin)
    UIHelper.LayoutDoLayout(self.WidgetAnchorButton)

    UIHelper.SetButtonState(self.BtnPersonal, bCanOperateMatch and BTN_STATE.Normal or BTN_STATE.Disable)
    UIHelper.SetButtonState(self.BtnTeam, bCanOperateMatch and BTN_STATE.Normal or BTN_STATE.Disable) --bCanJoinTeam为false时也可点击组队按钮弹出组队界面
    UIHelper.SetButtonState(self.BtnRoom, (bCanOperateMatch and bCanJoinRoom) and BTN_STATE.Normal or BTN_STATE.Disable, szRoomTip)
    UIHelper.SetButtonState(self.BtnMatching, (not bMatchSuccess and (bSingle or bCanJoinTeam or bCanJoinRoom)) and BTN_STATE.Normal or BTN_STATE.Disable) --队长才能取消

    if bCanOperateMatch and bInQueue then
        self:InitMatchTime(dwMapID)
    else
        self:InitBlackStateTime()
    end

    UIHelper.LayoutDoLayout(self.LayoutText)
end

function UIBattleFieldInformationView:UpdateNormalRewardInfo(tWin)
    -- local img1 = "<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_WeiMingDian' width='40' height='40'/>+" .. twin.nWeiWang
    -- local img2 = "<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_ZhanJieJiFen' width='40' height='40'/>+" .. twin.nTitlePoint
    -- local img3 = "<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_ShengWang' width='40' height='40'/>+" .. twin.tItem[3]
    -- local s = "·奖励：" .. img1 .. img2 .. img3
    -- UIHelper.SetRichText(self.RichTextContent, s)
    UIHelper.RemoveAllChildren(self.WidgetPvPReward)
    UIHelper.AddPrefab(PREFAB_ID.WidgetCoin, self.WidgetPvPReward, CurrencyType.Prestige, nil, tWin.nWeiWang)
    UIHelper.AddPrefab(PREFAB_ID.WidgetCoin, self.WidgetPvPReward, CurrencyType.TitlePoint, nil, tWin.nTitlePoint)
    UIHelper.AddPrefab(PREFAB_ID.WidgetCoin, self.WidgetPvPReward, CurrencyType.WinItem, nil, tWin.tItem[3])
    UIHelper.LayoutDoLayout(self.WidgetPvPReward)
end

function UIBattleFieldInformationView:InitBlackStateTime()
    m_bUpdateBlackTime = true
    local nTime = BattleFieldQueueData.GetBattleFieldBlackCoolTime()
    local nCurrentTime = GetCurrentTime()
    if nTime then
        m_nBlackEndTime = nTime + nCurrentTime
    else
        m_nBlackEndTime = nil
    end
    m_bUpdateBlackTime = false
end

function UIBattleFieldInformationView:InitMatchTime(dwMapID)
    m_bUpdateMatchTime = true
    local nTime = BattleFieldQueueData.GetJoinBattleQueueTime(dwMapID)
    local nCurrentTime = GetCurrentTime()
    if nTime then
        m_nMatchStartTime = nCurrentTime - nTime
    else
        m_nMatchStartTime = nil
    end
    m_bUpdateMatchTime = false
end

function UIBattleFieldInformationView:UpdateNPCCanDialog()
    local player = GetClientPlayer()
    if self.dwNpcID then
        local npc = GetNpc(self.dwNpcID)
        if not npc or not npc.CanDialog(player) then
            UIMgr.Close(self)
        end
    end
end

--匹配时间更新
function UIBattleFieldInformationView:UpdateMatchTime()
    if m_nMatchStartTime and not m_bUpdateMatchTime then
        local nTime = GetCurrentTime()
        local nShowTime = nTime - m_nMatchStartTime

        local dwMapID = self.dwMapID
        local bInQueue = BattleFieldQueueData.IsInBattleFieldQueue(dwMapID)

        if not bInQueue then
            return
        end

        --已匹配
        local szMatchTime = BattleFieldQueueData.FormatBattleFieldTime(nShowTime)

        --预计匹配
        local _, nAvgQueueTime = BattleFieldQueueData.GetQueueTime()
        local szAvgQueueTime = BattleFieldQueueData.FormatBattleFieldTime(nAvgQueueTime)

        local szTime = string.format("已匹配 %s   预计排队 %s", szMatchTime, szAvgQueueTime)
        UIHelper.SetString(self.LabelMatchingTime, szTime)
    end
end

--惩罚时间更新
function UIBattleFieldInformationView:UpdateBlackStateTime()
    if m_nBlackEndTime and not m_bUpdateBlackTime then
        local nTime = GetCurrentTime()
        local nShowTime = m_nBlackEndTime - nTime
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

function UIBattleFieldInformationView:GetCurrAcivityWeek(szActivityID, dwMapID)
    if not szActivityID then
        return
    end

    local tActiveID = {}
    for s in string.gmatch(szActivityID, "%d+") do
        local dwActID = tonumber(s)
        if dwActID then
            table.insert(tActiveID, dwActID)
        end
    end

    local nTime = GetCurrentTime()
    local tNowTime = TimeToDate(nTime)
    local nDayStartTime = DateToTime(tNowTime.year, tNowTime.month, tNowTime.day, 12, 0, 0)
    local nLangYingdianStartTime = DateToTime(tNowTime.year, tNowTime.month, tNowTime.day, 15, 0, 0)
    local nCircle = 6
    local nTimeCircle = 24 * 3600
    local nCurrWeek = tNowTime.weekday
    local nWeek = nil
    local szRes = ""

    if nCurrWeek == 0 then
        nCurrWeek = 7
    end
    local tWeek = {}
    if m_tBattleOpen[dwMapID] then
        table.insert(tWeek, {nWeek = nCurrWeek, szWeek = szRes .. g_tStrings.STR_TODAY_TIME})
    end

    for i = 1, nCircle, 1 do
        local nNewTime = nDayStartTime + nTimeCircle * i
        local nSpcialTime = nLangYingdianStartTime + nTimeCircle * i
        szRes = ""
        nWeek = nil
        for k, nActID in pairs(tActiveID) do
            if nActID == 206 then
                local bSpecCanAccept = ActivityData.IsActivityOn(nActID, nSpcialTime)
                if bSpecCanAccept then
                    nWeek = TimeToDate(nNewTime).weekday
                    szRes = szRes .. tWeekName[6] .. g_tStrings.STR_PAUSE .. tWeekName[0]
                    break
                end
            else
                local bCanAccept = ActivityData.IsActivityOn(nActID, nNewTime)
                if bCanAccept then
                    nWeek = TimeToDate(nNewTime).weekday
                    if nWeek == 0 then
                        nWeek = 7
                    end

                    -- if nWeek < nCurrWeek then
                    --     szRes = szRes .. g_tStrings.STR_ARENA_NEXT_WEEK
                    -- end
                    szRes = szRes .. tWeekName[nWeek % 7]
                    break
                end
            end
        end
        if nWeek and szRes ~= "" then
            table.insert(tWeek, {nWeek = nWeek, szWeek = szRes})
        end
    end

    --[[
    if not nWeek then
        Log("==== 函数 NewBattleFieldQueue.GetCurrAcivityWeek()的返回值无效！参数是：" .. szActivityID .. "," .. dwMapID)
    end
    --]]

    return tWeek
end

function UIBattleFieldInformationView:OnSyncBFRoleDate(dwPlayerID, dwMapID, bUpdate, eType)
    if eType ~= BF_ROLE_DATA_TYPE.HISTORY then
        return
    end

    local player = GetClientPlayer()
    if not player then return end
    if dwPlayerID ~= player.dwID then
        return
    end

    local tPersonalInfo = GetBFRoleData(dwPlayerID, dwMapID, eType)
    local nPersonalScoreIndex = BF_MAP_ROLE_INFO_TYPE.MATCH_LEVEL
    local szPersonalScore = tostring(tPersonalInfo[nPersonalScoreIndex])
    BattleFieldQueueData.szTempPersonalScore = szPersonalScore
    UIHelper.SetString(self.LabelNum, szPersonalScore)
    UIHelper.LayoutDoLayout(self.WidgetGrade)

    self:RemoteCallToServerInternal("On_Zhanchang_Remain") --返回ON_BATTLEFIELD_REWARD_DATA
end

--RemoteCallToServer, 封多一层用来加个打印
function UIBattleFieldInformationView:RemoteCallToServerInternal(szFunction, ...)
    if not szFunction then return end
    BattleFieldQueueData.Log("RemoteCallToServer: " .. szFunction, ...)
    RemoteCallToServer(szFunction, ...)
end

return UIBattleFieldInformationView
