-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: CampData
-- Date: 2023-02-22 09:43:37
-- Desc: 阵营
-- ---------------------------------------------------------------------------------

CampData = CampData or { className = "CampData", nCount = 1, }
local self = CampData

CampData.bIsTracing = false
CampData.tTraceInfo = nil
CampData.YINSHAN_MAP = 216

CampData.CAMP_MAP_ID = {
    [CAMP.GOOD] = 25, --浩气盟
    [CAMP.EVIL] = 27, --恶人谷
}

CampData.GOOD_ACTIVITY_ID = 706 --周六浩气盟阵营攻防战ID
CampData.EVIL_ACTIVITY_ID = 707 --周日恶人谷阵营攻防战ID

CampData.CAMP_ACTIVITY_TIP_ID = 44 --阵营攻防动态信息Tip ID

CampData.dwEndCastleID = nil
CampData.bShowOpenRankEntrance = false

CampData.GoodMoraleBossIndex =
{
	[7827] = 5,
	[7828] = 6,
	[7826] = 7,
}
CampData.EvilMoraleBossIndex =
{
	[7823] = 5,
	[7824] = 6,
	[7825] = 7,
}

CampData.WeatherSunImagePath = {
    Normal = "UIAtlas2_CampMap_Weather_Sun1",
    Disable = "UIAtlas2_CampMap_Weather_Sun2"
}

-- client\ui\Config\Default\CharacterPanel.lua
-- 进入排名的奖励
CampData.TITLE_POINT_RANK_REWARD = {
	{s= 1, e= 10, tReward = {{5, 10032, 3}, {5, 41168, 5}, {5, 85495, 300}, {5, 11640, 6}}},
	{s= 11, e= 50, tReward = {{5, 10032, 2}, {5, 41168, 5}, {5, 85495, 300}, {5, 11640, 5}}},
	{s= 51, e= 100, tReward = {{5, 10032, 1}, {5, 41168, 5}, {5, 85495, 250}, {5, 11640, 4}}},
	{s= 101, e= 200, tReward = {{5, 10031, 3}, {5, 41168, 3}, {5, 85495, 200}, {5, 11640, 3}}},
	{s= 201, e= 350, tReward = {{5, 10031, 2}, {5, 41168, 3}, {5, 85495, 150}, {5, 11640, 2}}},
	{s= 351, e= 500, tReward = {{5, 10031, 1}, {5, 41168, 3}, {5, 85495, 100}, {5, 11640, 1}}},
}
--本周战阶实时发放的牌子数量，邮件发送，每档发一次，所有档次可以累计，共享给同阵营共账号角色
CampData.TITLE_POINT_REAL_SEND = {
	{nMinPoint = 65000, nMaxPoint = 9000000, tReward = {{5, 85494, 200}, }},
	{nMinPoint = 55000, nMaxPoint = 65000, tReward = {{5, 85494, 200}, }},
	{nMinPoint = 45000, nMaxPoint = 55000, tReward = {{5, 85494, 100}, }},
	{nMinPoint = 35000, nMaxPoint = 45000, tReward = {{5, 85494, 50}, }},
	{nMinPoint = 25000, nMaxPoint = 35000, tReward = {{5, 85494, 20}, }},
	{nMinPoint = 15000, nMaxPoint = 25000, tReward = {{5, 85494, 20}, }},
	{nMinPoint = 5000, nMaxPoint = 15000, tReward = {{5, 85494, 10}, }},
}
--未进入排名，根据积分的奖励
CampData.TITLE_POINT_COUNT_REWARD = {
	{s = 65000, e = 9000000, tReward = {{5, 6255, 5}, {5, 6254, 5},  {5, 24446, 1}, }},
	{s = 55000, e = 65000, tReward = {{5, 6255, 5}, {5, 6254, 5}, {5, 24446, 1}, }},
	{s = 45000, e = 55000, tReward = {{5, 6255, 5}, {5, 6254, 5}, {5, 24446, 1}, }},
	{s = 35000, e = 45000, tReward = {{5, 6255, 5}, {5, 6254, 5}, {5, 24446, 1}, }},
	{s = 25000, e = 35000, tReward = {{5, 6255, 4}, {5, 6254, 4}, {5, 24445, 3}}},
	{s = 15000, e = 25000, tReward = {{5, 6255, 3}, {5, 6254, 3}, {5, 24445, 2}}},
	{s = 5000, e = 15000, tReward = {{5, 6255, 2}, {5, 6254, 2},  {5, 24445, 1}}},
}

--小攻防活动开始/结束时间
CampData.ACTIVITY_START_TIME = 20
CampData.ACTIVITY_END_TIME = 22

--大攻防活动开始/结束时间
CampData.ACTIVITY_CAMP_START_TIME_1 = 13
CampData.ACTIVITY_CAMP_END_TIME_1 = 15
CampData.ACTIVITY_CAMP_START_TIME_2 = 19
CampData.ACTIVITY_CAMP_END_TIME_2 = 21

--client\ui\Config\Default\CampActiveTime.lua
local tStepTime = {
    [1] = { nCycleTime = 39600 }, --休息时间			（11小时,2:00~13:00）
    [2] = { nCycleTime = 7200 }, --第一场战斗时间	（2小时,13:00~15:00）
    [3] = { nCycleTime = 14400 }, --休息时间			（4小时,15:00~19:00）
    [4] = { nCycleTime = 7200 }, --第二场战斗时间	（2小时,19:00~21:00）
    [5] = { nCycleTime = 18000 }, --休息时间			（5小时,21:00~02:00）
}

local tNextCampBattleDay = { -- 离下次攻防战间隔的天数，现在是星期6，7有攻防战
    [0] = 0,
    [1] = 5,
    [2] = 4,
    [3] = 3,
    [4] = 2,
    [5] = 1,
    [6] = 0,
}

function CampData.Init()
    self.RegEvent()

    self.bIsTracing = false
    self.tTraceInfo = nil

    self._refreshActiveTime()
    Timer.AddFrameCycle(self, 1, function()
        self.OnUpdate()
    end)
end

function CampData.UnInit()
    self.bIsTracing = false
    self.tTraceInfo = nil

    Timer.DelAllTimer(self)
    Event.UnRegAll(self)
end

function CampData.OnUpdate()
    local nCurrentTime = GetCurrentTime()
    self.nNextStepTime = self.nEndTime - nCurrentTime

    if self.nCount > 4800 then
        self._refreshActiveTime()
        self.nCount = 1
    end
    if self.nNextStepTime < 30 then
        self._refreshActiveTime()
        self.nCount = 1
    end
    self.nCount = self.nCount + 1
end

--标题栏
--g_tStrings.STR_CAMP_TITLE[hPlayer.nCamp]

--RemoteCallToServer("TongCampReverse", hFrame.nCamp) --帮会阵营转换
--CHANGE_CAMP、CHANGE_CAMP_FLAG -> UpdateCampButton(), UpdateCampPage() --CharacterPanel.lua: 822


function CampData.RegEvent()
    Event.Reg(self, "CAMP_RESULT", function(nResult)
        print("[Camp] CAMP_RESULT", nResult)
        self.OnCampResult(nResult)
    end)
    Event.Reg(self, EventType.OnClientPlayerEnter, function()
        --print("[Camp] OnClientPlayerEnter", dwPlayerID)
        if g_pClientPlayer then
            self.OnUpdateCampPanel(g_pClientPlayer.dwID)
        end

        self.CheckShowTrace()

        local bIsInActivityTime = self.IsInActivity()
        local bOpen = bIsInActivityTime or ActivityTipData.GetActivityTip(self.CAMP_ACTIVITY_TIP_ID) ~= nil
        Event.Dispatch(EventType.OnCampWarStateChanged, bOpen)

        self.bShowOpenRankEntrance = false
        Event.Dispatch(EventType.OnUpdateRankEntrance)
    end)
    Event.Reg(self, "CHANGE_CAMP", function(dwPlayerID)
        print("[Camp] CHANGE_CAMP", dwPlayerID)
        self.OnUpdateCampPanel(dwPlayerID)

        if g_pClientPlayer and dwPlayerID == g_pClientPlayer.dwID then
            OnCheckAddAchievement(979, "CAMP|JOIN")
        end
    end)
    Event.Reg(self, "ON_CHANGE_SCENE_CAMP_TYPE", function(dwPlayerID)
        print("[Camp] ON_CHANGE_SCENE_CAMP_TYPE", dwPlayerID)
        self.OnUpdateCampPanel(dwPlayerID)
    end)
    Event.Reg(self, "CHANGE_CAMP_FLAG", function(dwPlayerID)
        print("[Camp] CHANGE_CAMP_FLAG", dwPlayerID)
        self.OnChangeCampFlag(dwPlayerID)
    end)
    Event.Reg(self, "UPDATE_CAMP_INFO", function()
        print("[Camp] UPDATE_CAMP_INFO")
        self._refreshActiveTime()
        self.UpdateCampBossInfo()
        Event.Dispatch(EventType.OnCameInfoUpdate)
    end)
    Event.Reg(self, "ON_CASTLE_END_ACTIVITY", function(tWarInfo)
        print("[Camp] ON_CASTLE_END_ACTIVITY")
        self._refreshActiveTime()
        self.OnCastleEndActivity(tWarInfo)

        --隐藏排名/据点归属界面按钮
        self.bShowOpenRankEntrance = false
        Event.Dispatch(EventType.OnUpdateRankEntrance)
    end)
    Event.Reg(self, "ON_CASTLE_CHANGE_OWNER", function(dwCastleID)
        print("[Camp] ON_CASTLE_CHANGE_OWNER")
        self.OnCastleChangeOwner(dwCastleID)
    end)
    Event.Reg(self, "ON_CASTLE_OPEN_RANK_ENTRANCE", function()
        print("[Camp] ON_CASTLE_OPEN_RANK_ENTRANCE")
        if ActivityTipData.GetActivityTip(26) or ActivityTipData.GetActivityTip(27) then --只有在据点争夺的活动才显示
            --显示排名/据点归属界面按钮
            self.bShowOpenRankEntrance = true
            Event.Dispatch(EventType.OnUpdateRankEntrance)
        end
    end)
    Event.Reg(self, EventType.OnTogActivityTip, function(bOpen, dwActivityID)
        if not bOpen and (dwActivityID == 26 or dwActivityID == 27) then
            self.bShowOpenRankEntrance = false
            Event.Dispatch(EventType.OnUpdateRankEntrance)
        end
    end)

    Event.Reg(self, "LOADING_END", function()
        self.bShowTip = true
        RemoteCallToServer("On_Camp_GetTitlePointRequest")

        local player = GetClientPlayer()
        if player and player.nCamp ~= CAMP.NEUTRAL then
            RemoteCallToServer("On_Camp_CastleFightMapList")
        end
    end)
    Event.Reg(self, "SCENE_BEGIN_LOAD", function(dwMapID)
        self.UpdateSFXFlexibleBodyEnable(dwMapID)
    end)

    Event.Reg(self, EventType.OnPlayerMove, function()
        if self.bShowTip then
            if g_pClientPlayer and g_pClientPlayer.bCampFlag then
                TipsHelper.ShowNormalTip("当前已开启阵营模式，可被攻击！")
            end
            self.bShowTip = false
        end
    end)

    Event.Reg(self, "On_Camp_CastleFightMapList", function(tFightMap)
        self.tFightMap = tFightMap
        self.UpdateSFXFlexibleBodyEnable()
    end)

    --QUEST_ACCEPTED -> (nQuestIndex, nQuestID) UpdateQuest(nQuestID)
    --QUEST_DATA_UPDATE -> (nQuestIndex, eEventType, nValue1, nValue2, nValue3) nQuestID = player.GetQuestID(nQuestIndex), UpdateQuest(nQuestID)
    --QUEST_FAILED -> RemoveQuest()
    --QUEST_CANCELED or (SET_QUEST_STATE and arg1 == 0, (dwQuestID, byQuestState)) -> (nQuestID) questTrace = player.GetQuestTraceInfo(nQuestID) if not questTrace.fail then RemoveQuest() end
    --QUEST_FINISHED or (SET_QUEST_STATE and arg1 == 1, (dwQuestID, byQuestState)) -> RemoveQuest()
end

------------------------ Public ------------------------

function CampData_OnClickEntrance()
    if not g_pClientPlayer then return end
    if g_pClientPlayer.nCamp == CAMP.NEUTRAL then
        return VIEW_ID.PanelPvPCampJoin
    else
        return VIEW_ID.PanelRoadCollection, 4
    end
end

function CampData.OnClickCampMap()
    if not g_pClientPlayer then return end
    if g_pClientPlayer.nCamp == CAMP.NEUTRAL then
        UIMgr.Open(VIEW_ID.PanelPvPCampJoin)
    else
        UIMgr.Open(VIEW_ID.PanelCampMap)
    end
end

function CampData.OnClickCampPVPField()
    -- if not g_pClientPlayer then return end
    -- if g_pClientPlayer.nCamp == CAMP.NEUTRAL then
    --     UIMgr.Open(VIEW_ID.PanelPvPCampJoin)
    -- else
        UIMgr.Open(VIEW_ID.PanelQianLiFaZhu)
    -- end
end

function CampData.TryEnterCampPVPField()
    if not g_pClientPlayer then return end
    if g_pClientPlayer.nCamp == CAMP.NEUTRAL then
        UIMgr.Open(VIEW_ID.PanelPvPCampJoin)
    else
        UIMgr.Open(VIEW_ID.PanelQianLiFaZhu)
    end
end

--阵营结算
function CampData.OnCastleEndActivity(tInfo)
    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelCompete)
    if not scriptView then
        UIMgr.Open(VIEW_ID.PanelCompete, tInfo)
    else
        scriptView:OnEnter(tInfo)
    end
end

function CampData.OnCastleChangeOwner(dwCastleID)
    self.dwEndCastleID = dwCastleID
    --TODO Open CityBelong

    --同时更新沙盘地图的信息
    if UIMgr.IsViewOpened(VIEW_ID.PanelCampMap) then
        RemoteCallToServer("On_Castle_GetCastleTipsRequest")
    end
end

--bCampFlag: 是否阵营模式
--bShowNeutral：是否显示中立图标
function CampData.SetUICampImg(imgNode, nCamp, bCampFlag, bShowNeutral)
    if not imgNode then
        return
    end

    local szImgPath = self.GetCampImgPath(nCamp, bCampFlag, bShowNeutral)
    if szImgPath then
        UIHelper.SetSpriteFrame(imgNode, szImgPath)
        UIHelper.SetVisible(imgNode, true)
    else
        UIHelper.SetVisible(imgNode, false)
    end
end

--bCampFlag: 是否检测玩家处于阵营模式
--bShowNeutral：是否显示中立图标
function CampData.SetUICampImgByPlayer(imgNode, player, bCheckCampFlag, bShowNeutral)
    player = player or GetClientPlayer()
    local bCampFlag = bCheckCampFlag and player.bCampFlag
    self.SetUICampImg(imgNode, player.nCamp, bCampFlag, bShowNeutral)
end

--bCampFlag: 是否阵营模式
--bShowNeutral：是否能够获取中立图标
function CampData.GetCampImgPath(nCamp, bCampFlag, bCanGetNeutral)
    local szImgPath
    if nCamp == CAMP.GOOD then
        if bCampFlag then
            szImgPath = "UIAtlas2_Public_PublicSchool_PublicSchool_ImgHaoqi1.png"
        else
            szImgPath = "UIAtlas2_Public_PublicSchool_PublicSchool_img_haoqimeng.png"
        end
    elseif nCamp == CAMP.EVIL then
        if bCampFlag then
            szImgPath = "UIAtlas2_Public_PublicSchool_PublicSchool_ImgEren1.png"
        else
            szImgPath = "UIAtlas2_Public_PublicSchool_PublicSchool_img_erengu.png"
        end
    elseif bCanGetNeutral then
        --CAMP.NEUTRAL
        szImgPath = "UIAtlas2_Public_PublicSchool_PublicSchool_img_zhongli.png"
    end
    return szImgPath
end

------------------------ ------------------------

function CampData.OnCampResult(nResult)
    local szMsg = nil
    local szChanel = "MSG_ANNOUNCE_NORMAL"
    if nResult == CAMP_RESULT_CODE.FAILD then
        szMsg = g_tStrings.STR_CAMP_RESULT_FAILD
    elseif nResult == CAMP_RESULT_CODE.SUCCEED then
        local hPlayer = GetClientPlayer()
        szMsg = FormatString(g_tStrings.STR_CAMP_RESULT_SUCCEED, g_tStrings.STR_CAMP_TITLE[hPlayer.nCamp])
        szChanel = "MSG_ANNOUNCE_NORMAL"
    elseif nResult == CAMP_RESULT_CODE.TONG_CONFLICT then
        szMsg = g_tStrings.STR_CAMP_RESULT_TONG
    elseif nResult == CAMP_RESULT_CODE.IN_PARTY then
        szMsg = g_tStrings.STR_CAMP_RESULT_PARTY
    end

    if szMsg then
        OutputMessage("MSG_SYS", szMsg)
        OutputMessage(szChanel, szMsg)
    end
end

--刷新阵营界面显示
function CampData.OnUpdateCampPanel(dwPlayerID)
    local hPlayer = GetClientPlayer()
    if hPlayer and hPlayer.dwID == dwPlayerID then
        if hPlayer.nCamp ~= CAMP.NEUTRAL then
            local bIsInActivityTime = self.IsInActivity()
            local bOpen = bIsInActivityTime or ActivityTipData.GetActivityTip(self.CAMP_ACTIVITY_TIP_ID) ~= nil
            Event.Dispatch(EventType.OnCampWarStateChanged, bOpen)
        end

        local nCurServerType = GetServerType()
        if hPlayer.nCamp == CAMP.NEUTRAL and nCurServerType == SERVER_TYPE.NORMAL then
            UIMgr.Close(VIEW_ID.PanelPVPCamp)
            return
        end

        local hScene = hPlayer.GetScene()
        if (hScene.nType == MAP_TYPE.BIRTH_MAP and nCurServerType == SERVER_TYPE.NORMAL) or hScene.nType == MAP_TYPE.BATTLE_FIELD or Table_IsInForbidMap("CampPanel", hScene.dwMapID) then
            UIMgr.Close(VIEW_ID.PanelPVPCamp)
        else
            self.UpdateCampBossInfo()
            local view = UIMgr.GetView(VIEW_ID.PanelPVPCamp)
            local scriptView = view and view.scriptView
            if scriptView then
                scriptView:UpdateInfo()
            end
            Event.Dispatch(EventType.OnCameInfoUpdate)
        end
    end
end

function CampData.OnChangeCampFlag(dwPlayerID)
    local hClientPlayer = GetClientPlayer()
    if not hClientPlayer then
        return
    end

    if hClientPlayer.dwID == dwPlayerID then
        if hClientPlayer.bCampFlag then
            --OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_SYS_MSG_OPEN_CAMP_FALG, g_tStrings.STR_NAME_YOU))
            local szMsg = FormatString(g_tStrings.STR_SYS_MSG_OPEN_CAMP_FALG, g_tStrings.STR_NAME_YOU)
            OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
            ChatData.Append(szMsg, 0, PLAYER_TALK_CHANNEL.GM_ANNOUNCE, false, "")
        else
            --OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_SYS_MSG_CLOSE_CAMP_FALG, g_tStrings.STR_NAME_YOU))
            local szMsg = FormatString(g_tStrings.STR_SYS_MSG_CLOSE_CAMP_FALG, g_tStrings.STR_NAME_YOU)
            OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
            ChatData.Append(szMsg, 0, PLAYER_TALK_CHANNEL.GM_ANNOUNCE, false, "")
        end
    else
        -- local hPlayer = GetPlayer(dwPlayerID)
        -- if hPlayer.bCampFlag then
        --     OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_SYS_MSG_OPEN_CAMP_FALG, UIHelper.GBKToUTF8(hPlayer.szName)))
        -- else
        --     OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_SYS_MSG_CLOSE_CAMP_FALG, UIHelper.GBKToUTF8(hPlayer.szName)))
        -- end
    end
end

function CampData.UpdateCampBossInfo()
    local tNPCInfo = GetCampNpcInfo()
    local tEvilCampBoss = {}
    local tGoodCampBoss = {}
    local tEvilMoraleBoss = {}
    local tGoodMoraleBoss = {}

    for _, NpcInfo in ipairs(tNPCInfo) do
        if NpcInfo.nType == CAMP_NPC_TYPE.EVIL_CAMP_BOSS then
            table.insert(tEvilCampBoss, NpcInfo)
        elseif NpcInfo.nType == CAMP_NPC_TYPE.GOOD_CAMP_BOSS then
            table.insert(tGoodCampBoss, NpcInfo)
        elseif NpcInfo.nType == CAMP_NPC_TYPE.EVIL_CAMP_SCORE_LEVEL_BOSS then
            table.insert(tEvilMoraleBoss, NpcInfo)
        elseif NpcInfo.nType == CAMP_NPC_TYPE.GOOD_CAMP_SCORE_LEVEL_BOSS then
            table.insert(tGoodMoraleBoss, NpcInfo)
        end
    end

    self._sortBoss(tEvilCampBoss)
    self._sortBoss(tGoodCampBoss)
    self._sortBoss(tEvilMoraleBoss)
    self._sortBoss(tGoodMoraleBoss)

    self.tCampBossInfo = {
        tEvilCampBoss = tEvilCampBoss,
        tGoodCampBoss = tGoodCampBoss,
        tEvilMoraleBoss = tEvilMoraleBoss,
        tGoodMoraleBoss = tGoodMoraleBoss,
    }
end

function CampData.GetCampBossInfo()
    return self.tCampBossInfo or {}
end

--士气条百分比 0~1
function CampData.GetMoraleInfo()
    local hCampInfo = GetCampInfo()
    local nGoodCampScore = hCampInfo.GetNewCampFightValue(NEW_CAMP_FIGHT_VALUE_TYPE.CAMP_SCORE, CAMP.GOOD)
    local nEvilCampScore = hCampInfo.GetNewCampFightValue(NEW_CAMP_FIGHT_VALUE_TYPE.CAMP_SCORE, CAMP.EVIL)
    local fPercentage = 0.5
    if nGoodCampScore + nEvilCampScore > 0 then
        fPercentage = nGoodCampScore / (nGoodCampScore + nEvilCampScore)
    end
    return nGoodCampScore, nEvilCampScore, fPercentage
end

function CampData.GetPlayerTitleDesc(nTitle)
    if not nTitle or nTitle <= 0 or nTitle > 14 then
        return g_tStrings.STR_NONE, g_tStrings.STR_NONE, g_tStrings.STR_NONE
    end

    local szTitleLevel = FormatString(g_tStrings.CAMP_TITLE_LEVEL, nTitle)
    local player = GetClientPlayer()
    local szTitle, szTitleBuff = g_tStrings.STR_NONE, g_tStrings.STR_NONE
    local dwID = GetDesignationIDByTitleAndCamp(nTitle, player.nCamp)
    local t = Table_GetDesignationPrefixByID(dwID, UI_GetPlayerForceID())
    if t then
        szTitle = UIHelper.GBKToUTF8(t.szName)
    end

    if nTitle > 7 then
        local aInfo = GetDesignationPrefixInfo(dwID)
        if aInfo then
            szTitleBuff = BuffMgr.GetBuffDesc(aInfo.dwBuffID, aInfo.nBuffLevel)
        end
    end

    return szTitleLevel, szTitle, szTitleBuff
end

function CampData.GetNowReward(nRank, nLastPoint)
    for _, tReward in ipairs(self.TITLE_POINT_RANK_REWARD) do
        if nRank >= tReward.s and nRank <= tReward.e then
            return tReward
        end
    end

    for _, tPointReward in pairs(self.TITLE_POINT_COUNT_REWARD) do
        if nLastPoint >= tPointReward.s and nLastPoint < tPointReward.e then
            return tPointReward
        end
    end
end

function CampData.GetActiveTime()
    if not self.nNextStepTime then
        return
    end

    if self.nNextStepTime < 0 then
        self.nNextStepTime = 0
    end

    local tTime = TimeToDate(self.nNextStepTime)
    local nHour, nMinute, nSecond = tTime.hour - 8, tTime.minute, tTime.second

    if tTime.day > 1 then
        nHour = nHour + 24 * (tTime.day - 1)
    end

    return nHour, nMinute, nSecond
end

function CampData.GetActiveTimeText()
    if not self.nNextStepTime then
        return
    end

    local nHour, nMinute, nSecond = self.GetActiveTime()

    local szHour, szMinute, szSecond
    szHour = (nHour >= 10) and tostring(nHour) or "0" .. nHour
    szMinute = (nMinute >= 10) and tostring(nMinute) or "0" .. nMinute
    szSecond = (nSecond >= 10) and tostring(nSecond) or "0" .. nSecond

    local szTime = szHour .. ":" .. szMinute .. ":" .. szSecond
    local bIsInActivityTime = self.IsInActivity()
    if bIsInActivityTime then
        return g_tStrings.CAMPACTIVE_END_LEFT_TIME, szTime, self.nWeekday
    else
        return g_tStrings.CAMPACTIVE_BEGIN_LEFT_TIME, szTime, self.nWeekday
    end
end

--是否攻防战期间
function CampData.IsInActivity()
    local dwMapID = MapHelper.GetMapID()
    local bIsInActivityTime = self.nStep % 2 == 0
    local bIsInActivityMap = table.contain_value(self.CAMP_MAP_ID, dwMapID)
    return bIsInActivityTime, bIsInActivityMap
end

function CampData.IsInCastleActivity()
    local nCurrentTime = GetCurrentTime()
    local tTime = TimeToDate(nCurrentTime)

    if tTime.weekday == 2 or tTime.weekday == 4 then
        local bOn = ActivityData.IsActivityOn(ACTIVITY_ID.CASTLE) or UI_IsActivityOn(ACTIVITY_ID.CASTLE)
        local bQueueTime = tTime.hour >= self.ACTIVITY_START_TIME - 1 and tTime.hour <= self.ACTIVITY_START_TIME --攻防活动开启前一小时算排队和排队准备时间
        return bOn, bQueueTime
    end
    return false, false
end

function CampData.IsInCampActivity()
    local nCurrentTime = GetCurrentTime()
    local tTime = TimeToDate(nCurrentTime)

    if tTime.weekday == 6 or tTime.weekday == 0 then
        local bOn = self.IsInActivity()

        --攻防活动开启前一小时算排队和排队准备时间
        local bQueueTime = (tTime.hour >= self.ACTIVITY_CAMP_START_TIME_1 - 1 and tTime.hour <= self.ACTIVITY_CAMP_START_TIME_1)
                            or (tTime.hour >= self.ACTIVITY_CAMP_START_TIME_2 - 1 and tTime.hour <= self.ACTIVITY_CAMP_START_TIME_2)

        return bOn, bQueueTime
    end
    return false, false
end

function CampData.UpdateSFXFlexibleBodyEnable(dwMapID)
    dwMapID = dwMapID or MapHelper.GetMapID()
    local bIsInCastleFightMap = false
    local bInActivity, bQueueTime = self.IsInCastleActivity() --周二周四小攻防
    local bIsInCampActivity, bCampQueueTime = self.IsInCampActivity() --周六周日大攻防

    -- 跨服河西瀚漠（全天）
    if dwMapID == 697 then
        bIsInCastleFightMap = true
    end

    -- 小攻防地图/阴山大草原（排队/活动期间）
    if not bIsInCastleFightMap and (bInActivity or bQueueTime) then
        if dwMapID == self.YINSHAN_MAP then
            bIsInCastleFightMap = true
        elseif self.tFightMap then
            if self.tFightMap[dwMapID] and self.tFightMap[dwMapID] ~= 0 then
                bIsInCastleFightMap = true
            end
        end
    end

    -- 大攻防 浩气盟/恶人谷（排队/活动期间）
    if not bIsInCastleFightMap and (bIsInCampActivity or bCampQueueTime) then
        if table.contain_value(self.CAMP_MAP_ID, dwMapID) then
            bIsInCastleFightMap = true
        end
    end

    local bEnable = not bIsInCastleFightMap
    print("[CampData] SetSFXFlexibleBodyEnable", bEnable)
    KG3DEngine.SetSFXFlexibleBodyEnable(bEnable)
end

function CampData.RegisterTracing()
    self.bIsTracing = true
    self.tTraceInfo = {
        MapMgr.szName, MapMgr.nMapID, MapMgr.tbPoint[1], MapMgr.tbPoint[2], MapMgr.tbPoint[3]
    }

    Event.Reg(self, EventType.OnMapUpdateNpcTrace, function(bNearAutoClear)
        if not self.tTraceInfo then
            self.bIsTracing = false
            Event.UnReg(self, EventType.OnMapUpdateNpcTrace)
            return
        end

        local bChanged = false
        local tNewTraceInfo = {
            MapMgr.szName, MapMgr.nMapID, MapMgr.tbPoint[1], MapMgr.tbPoint[2], MapMgr.tbPoint[3]
        }
        for i, v in ipairs(tNewTraceInfo) do
            if v ~= self.tTraceInfo[i] then
                bChanged = true
                break
            end
        end

        if not bChanged then
            return
        end

        if not bNearAutoClear then
            self.bIsTracing = false
        end
        self.tTraceInfo = nil
        Event.UnReg(self, EventType.OnMapUpdateNpcTrace)

    end)
end

function CampData.CheckJoinCamp(nCampType)
    if not nCampType or nCampType == CAMP.NEUTRAL then
        return
    end

    local bIsInActivityTime = self.IsInActivity()
    if bIsInActivityTime then
        TipsHelper.ShowNormalTip("阵营攻防战期间，暂时无法加入阵营")
        return
    end

    --若当前已在目标场景，则直接调并指引寻路
    local dwMapID = self.CAMP_MAP_ID[nCampType]
    local nCurMapID = MapHelper.GetMapID()
    if nCurMapID == dwMapID then
        self.bIsTracing = true
        self.CheckShowTrace()
        RemoteCallToServer("On_Vote_JoinCamp", nCampType)
        UIMgr.Close(VIEW_ID.PanelPvPCampJoin)
        UIMgr.Close(VIEW_ID.PanelSystemMenu)
        return
    end

    -- 地图资源下载检测拦截
    if not PakDownloadMgr.UserCheckDownloadMapRes(dwMapID, function()
        self.CheckJoinCamp(nCampType)
     end, "阵营地图资源文件下载完成，是否前往[" .. g_tStrings.STR_CAMP_TITLE[nCampType] .. "]？") then
        return
    end

    MapMgr.CheckTransferCDExecute(function()
        self.bIsTracing = true
        RemoteCallToServer("On_Vote_JoinCamp", nCampType)
        UIMgr.Close(VIEW_ID.PanelPvPCampJoin)
        UIMgr.Close(VIEW_ID.PanelSystemMenu)
    end, dwMapID)
end

function CampData.CheckShowTrace(bForce)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    if not self.bIsTracing and not bForce then
        return
    end

    if hPlayer.nCamp ~= CAMP.NEUTRAL then
        return
    end

    local dwMapID = MapHelper.GetMapID()
    if not table.contain_value(self.CAMP_MAP_ID, dwMapID) then
        --浩气盟 or 恶人谷
        return
    end

    local szTraceName
    if dwMapID == self.CAMP_MAP_ID[CAMP.GOOD] then
        szTraceName = "谢渊"
    elseif dwMapID == self.CAMP_MAP_ID[CAMP.EVIL] then
        szTraceName = "王遗风"
    end
    local dwQuestID = 20921
    self.SetTraceNpcByQuest(dwQuestID, dwMapID, szTraceName)
end

function CampData.SetTraceNpcByQuest(dwQuestID, dwMapID, szTraceName)
    local tData = TableQuest_GetPoint(dwQuestID, "quest_state", 0, dwMapID, 0)
    local tPoint = tData[1][1]

    MapMgr.SetTracePoint(szTraceName, dwMapID, { tPoint[1], tPoint[2], tPoint[3] })
    UIMgr.Close(VIEW_ID.PanelPvPCampJoin)
    if dwMapID ~= MapHelper.GetMapID() then
        UIMgr.Open(VIEW_ID.PanelMiddleMap, dwMapID, 0)
    end

    -- if UIMgr.GetView(VIEW_ID.PanelPvPCampJoin) then
    --     UIMgr.HideView(VIEW_ID.PanelPvPCampJoin)
    --     Event.Reg(self, EventType.OnViewClose, function(nViewID)
    --         if nViewID == VIEW_ID.PanelMiddleMap then
    --             UIMgr.ShowView(VIEW_ID.PanelPvPCampJoin)
    --             Event.UnReg(self, EventType.OnViewClose)
    --         end
    --     end)
    -- end

end

function CampData._sortBoss(tBoss)
    if tBoss then
        local fnSort = function(BossInfo1, BossInfo2)
            return BossInfo1.nLifePercent < BossInfo2.nLifePercent
        end
        table.sort(tBoss, fnSort)
    end
end

function CampData._getActiveTimeInfo()
    local nCurrentTime = GetCurrentTime()
    local tData = TimeToDate(nCurrentTime)
    nCurrentTime = DateToTime(tData.year, tData.month, tData.day, tData.hour, tData.minute, tData.second)
    local nStartTime = DateToTime(tData.year, tData.month, tData.day, 2, 0, 0)
    local nWeekday = tData.weekday

    if nCurrentTime < nStartTime then
        nWeekday = nWeekday - 1
        if nWeekday < 0 then
            nWeekday = 6
        end

        nStartTime = nStartTime - 24 * 3600
    end
    if tNextCampBattleDay[nWeekday] > 0 then
        return nWeekday, 1, nStartTime + tStepTime[1].nCycleTime + tNextCampBattleDay[nWeekday] * 24 * 3600
    end

    local nUsedTime = nCurrentTime - nStartTime
    local nStep = 0 --当前时间处于第几个阶段
    local nEndTime = nStartTime --当前阶段截止时间

    for nIndex = 1, #tStepTime do
        if tStepTime[nIndex].nCycleTime > nUsedTime then
            nStep = nIndex
            nEndTime = nEndTime + tStepTime[nIndex].nCycleTime
            break
        end

        nUsedTime = nUsedTime - tStepTime[nIndex].nCycleTime
        nEndTime = nEndTime + tStepTime[nIndex].nCycleTime
    end

    if nStep == 5 then
        nEndTime = nEndTime + tStepTime[1].nCycleTime
    end
    return nWeekday, nStep, nEndTime
end

function CampData._refreshActiveTime()
    local nStep = self.nStep
    self.nWeekday, self.nStep, self.nEndTime = self._getActiveTimeInfo()
    if nStep ~= self.nStep then
        local bIsInActivityTime = self.IsInActivity()
        Event.Dispatch(EventType.OnCampWarStateChanged, bIsInActivityTime)
    end

    local bInActivity, bQueueTime = self.IsInCastleActivity() --周二周四小攻防
    local bIsInCampActivity, bCampQueueTime = self.IsInCampActivity() --周六周日大攻防
    local bIsInFightActivity = bInActivity or bQueueTime or bIsInCampActivity or bCampQueueTime
    if bIsInFightActivity ~= self.bIsInFightActivity then
        self.bIsInFightActivity = bIsInFightActivity
        self.UpdateSFXFlexibleBodyEnable()
    end
end

local nEndTime = 0
local COUNTDOWN_TIME = { 60 * 5, 60 * 4, 60 * 3, 60 * 2, 60, 30 }
local nLastCountdownIndex = nil
local function CloseCampCountdown()
    local nCurTime = GetCurrentTime()
    if nCurTime >= nEndTime then
        Timer.DelTimer(CampData, self.closeCampCountdownTimerID)
        nEndTime = 0
        return
    end

    local nLeftTime = nEndTime - nCurTime
    for nIndex, nTime in ipairs(COUNTDOWN_TIME) do
        if nLeftTime <= nTime and COUNTDOWN_TIME[nIndex + 1] and nLeftTime > COUNTDOWN_TIME[nIndex + 1] then
            if nLastCountdownIndex ~= nIndex then
                local szTime = UIHelper.GetHeightestTimeText(nTime)
                OutputMessage("MSG_ANNOUNCE_NORMAL", FormatString(g_tStrings.STR_SYS_MSG_WAIT_CLOSE_CAMP_FLAG, szTime))
                nLastCountdownIndex = nIndex
            end
            break
        end
    end
end

function CampData.WaitCloseCampFlag(bResult, nLeftSeconds)
    if nLeftSeconds == 0 or not bResult then
        Timer.DelTimer(CampData, self.closeCampCountdownTimerID)
        nEndTime = 0
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_SYS_MSG_CLOSE_CAMP_FALG_FAIL)
        return
    end

    nEndTime = GetCurrentTime() + nLeftSeconds
    self.closeCampCountdownTimerID = Timer.AddFrameCycle(CampData, 1, CloseCampCountdown)
end

function CampData.IsActivityPresetOn(dwMapID)
    local tPresetInfo = Table_GetActivityFilterPresetList(dwMapID)
    local bActivityOn = false
    local tOnPreset
    for _, tInfo in ipairs(tPresetInfo) do
        local dwActivityID = tInfo.dwActivityID
        if ActivityData.IsActivityOn(dwActivityID) or UI_IsActivityOn(dwActivityID) then
            bActivityOn = true
            tOnPreset = tInfo
            break
        end
    end
    return bActivityOn, tOnPreset
end

function CampData.On_Camp_GetTitlePointRankInfo(tInfo)
    self.tRewardInfo = tInfo
    FireUIEvent("On_CAMP_GETTITLEPOINTRANKINFO", tInfo)
end

function CampData.On_Camp_GetTitlePointRankReward(bSuccess)
    if self.tRewardInfo then
        self.tRewardInfo.Receive = false
    end
    FireUIEvent("On_CAMP_GETTITLEPOINTRANKREWARD", bSuccess)
end

function CampData.GetTitlePointRankRewardInfo()
    return self.tRewardInfo
end

function CampData.GetBossInfoByID(nBossID)
    if not self.tbBossInfo then
        self.tbBossInfo = Table_GetCampBossInfo()
    end
    return self.tbBossInfo[nBossID]
end

function CampData.CampTransfer(dwMapID, nCopyIndex)
    if not dwMapID then
        return
    end

    local function _closeUI()
        UIMgr.Close(VIEW_ID.PanelYinshanLine)
        UIMgr.Close(VIEW_ID.PanelLineSelectPop)
        UIMgr.Close(VIEW_ID.PanelCampMap)
        UIMgr.Close(VIEW_ID.PanelRoadCollection)
        UIMgr.Close(VIEW_ID.PanelSystemMenu)
    end

    nCopyIndex = nCopyIndex or 1
    if dwMapID == CampData.YINSHAN_MAP then
        MapMgr.CheckTransferCDExecute(function()
            RemoteCallToServer("On_Camp_GFFenLiuMapSwitch", nCopyIndex)
            _closeUI()
        end, dwMapID)
    else
        MapMgr.CheckTransferCDExecute(function()
            RemoteCallToServer("On_Camp_SandTableTransferToMap", dwMapID, nCopyIndex)
            _closeUI()
        end, dwMapID)
    end
end

function CampData.GetPlayerCurrentDesignation()
    local pPlayer = g_pClientPlayer
    if not pPlayer then
        return
    end

    local nCurrentPrefixID   = pPlayer.GetCurrentDesignationPrefix()
    local nCurrentPostfixID  = pPlayer.GetCurrentDesignationPostfix()
    local nCurrentCourtesyID = pPlayer.GetDesignationBynameDisplayFlag() and pPlayer.GetDesignationGeneration() or 0

    return nCurrentPrefixID, nCurrentPostfixID, nCurrentCourtesyID
end

function CampData.GetGenerationDesignation()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    local tGen = g_tTable.Designation_Generation:Search(pPlayer.dwForceID, pPlayer.GetDesignationGeneration())
    if tGen then
        tGen.bHave = true
        if tGen.szCharacter and tGen.szCharacter ~= "" and not tGen.bSetNewName then
            local tCharacter = g_tTable[tGen.szCharacter]:Search(pPlayer.GetDesignationByname())
            if tCharacter then
                tGen.szName = tGen.szName .. tCharacter.szName
                tGen.bSetNewName = true
            end
        end
    end
    return tGen
end

--根据ID获取战阶名字和类型
function CampData.GetDesignationInfo()
    local nPrefixID, nPostfixID, nCourtesyID = self.GetPlayerCurrentDesignation()
    local szName, szType

    local tPrefixInfo = nPrefixID and nPrefixID ~= 0 and GetDesignationPrefixInfo(nPrefixID)
    if tPrefixInfo and tPrefixInfo.nType ~= DESIGNATION_PREFIX_TYPE.NORMAL_PREFIX then
        local t = Table_GetDesignationPrefixByID(nPrefixID, UI_GetPlayerForceID())
        szName = t and UIHelper.GBKToUTF8(t.szName) or ""
        if tPrefixInfo.nType == DESIGNATION_PREFIX_TYPE.WORLD_DESIGNATION then
            szType = "世界称号"
        elseif tPrefixInfo.nType == DESIGNATION_PREFIX_TYPE.MILITARY_RANK_DESIGNATION then
            szType = "战阶称号"
        end
    else
        local szPrefixName    = ""
        local szPostfixName   = ""
        local szCourtesyName  = ""
        if nPrefixID and nPrefixID ~= 0 then
            if tPrefixInfo.nType == DESIGNATION_PREFIX_TYPE.NORMAL_PREFIX then
                local t = Table_GetDesignationPrefixByID(nPrefixID, UI_GetPlayerForceID())
                szPrefixName = t and t.szName or ""
            end
        end
        if nPostfixID and nPostfixID ~= 0 then
            szPostfixName = g_tTable.Designation_Postfix:Search(nPostfixID).szName
        end
        local tGen = self.GetGenerationDesignation()
        if nCourtesyID and nCourtesyID ~= 0 then
            szCourtesyName = tGen.szName
        end
        szName = UIHelper.GBKToUTF8(szPrefixName .. szPostfixName .. szCourtesyName)
        szType = "组合称号"
    end
    return szName, szType
end

function CampData.OnUseCampWeeklyItem()
    -- VK特判使用千里伐逐挖矿奖励道具跳转橙色戒指系统商店
    local tbCampToShopID = {
        [0] = 1411,
        [1] = 1412,
        [2] = 1411,
    }
    local player = GetClientPlayer()
    if not player then
        return
    end
    local nShopID = tbCampToShopID[player.nCamp]
    ShopData.OpenSystemShopGroup(1, nShopID)
end