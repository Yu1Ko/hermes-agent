-- ---------------------------------------------------------------------------------
-- Author: luwenhao
-- Name: ArenaTowerData
-- Date: 2026-01-29 17:20:50
-- Desc: 扬刀大会 JJC肉鸽爬塔玩法
-- https://365.kdocs.cn/l/clfQU3tr7iS1
-- https://365.kdocs.cn/l/cmf2wrJPofBp
-- ---------------------------------------------------------------------------------

ArenaTowerData = ArenaTowerData or {className = "ArenaTowerData"}
local self = ArenaTowerData

ArenaTowerDiffMode =
{
    Practice = 0, -- 练习模式
    Challenge = 1, -- 挑战模式
}

ArenaTowerLevelState =
{
    Incomplete = 1, -- 未完成
    PracticeCompleted = 2, -- 已完成练习模式关卡
    ChallengeCompleted = 3, -- 已完成挑战（和练习）模式关卡
}

ArenaTowerBattleState =
{
    Rest = 0, -- 休息
    Matching = 1, -- 匹配中
    Prepare = 2, -- 战斗准备
    Battle = 3, -- 战斗
    Settle = 4, -- 结算
}

ArenaTowerSettleResult =
{
    Victory = 1,
    Defeat = 2,
    DefeatAndLevelDown = 3,
    AllClear = 4,
}

-- 顺序不可修改，与预制遍历顺序有关
BlessElementType =
{
    Jin = 1,
    Mu = 2,
    Shui = 3,
    Huo = 4,
    Tu = 5,
}

BlessCardTagType =
{
    Damage = 1,    -- 伤害
    Heal = 2,      -- 治疗
    Burst = 3,     -- 爆发
    Survive = 4,   -- 生存
    Buff = 5,      -- 增益
    Debuff = 6,    -- 减益
    Resource = 7,  -- 资源
    Special = 8,   -- 特殊
}

BlessCardSpecialTagType =
{
    GoldState = 1,  --锋芒
    WaterState = 2, --涌动
    EarthState = 3, --蓄势
}

BlessCardState =
{
    Normal = 0, -- 常规
    Burning = 1, -- 燃烧
    Ash = 2, -- 灰烬
    Revive = 3, -- 涅槃
}

BlessShopItemType =
{
    Bless = 1, -- 祝福
    ElementPoint = 2, -- 元素点
    AttritubeUp = 3, -- 属性提升
}

BlessCardAniEvent =
{
    OnFire = 1, -- 火卡点燃
    OnAsh = 2, -- 火卡灰烬
    OnRevive = 3, -- 火卡涅槃
    OnGrowWood = 4, -- 木卡满能量获得
    OnEnhanced = 5, -- 强化
    OnGetCard = 6, -- 获得卡牌
}

ArenaTowerData.BATTLE_PLAYER_COUNT = 3 -- 单局玩家数量
ArenaTowerData.TEAM_DPS_REQUIRE = 2 -- 队伍输出要求
ArenaTowerData.TEAM_HEAL_REQUIRE = 1 -- 队伍治疗要求

ArenaTowerData.MAX_LEVEL_COUNT = 12 -- 最大关卡数量
ArenaTowerData.MAX_MAIN_SKILL_COUNT = 2 -- 最大主动技能数量
ArenaTowerData.MAX_BLESS_STAR = 4 -- 祝福最高星级

ArenaTowerData.SHOP_REFRESH_PRICE = 3 -- 商店刷新消耗易卦点
ArenaTowerData.BONUS_REFRESH_PRICE = 1 -- 祝福选择刷新消耗易卦点

ArenaTowerData.EXTEND_ACTION_BAR_INDEX = 22 -- ui/Scheme/Case/ExtendActionBarData.tab
ArenaTowerData.REFRESH_ITEM_ID = {5, 85958} -- 刷新道具 易卦盘
ArenaTowerData.REFRESH_ITEM_ICON_PATH = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_YiGuaPan"

-- 元素排序优先级（数值越小优先级越高）
-- 金>金水>水>水木>木>木火>火>火土>土>土金
local tElementPriority = {
    [BlessElementType.Jin]                                  = 1,
    [BlessElementType.Jin  .. "_" .. BlessElementType.Shui] = 2,
    [BlessElementType.Shui]                                 = 3,
    [BlessElementType.Shui .. "_" .. BlessElementType.Mu]   = 4,
    [BlessElementType.Mu]                                   = 5,
    [BlessElementType.Mu   .. "_" .. BlessElementType.Huo]  = 6,
    [BlessElementType.Huo]                                  = 7,
    [BlessElementType.Huo  .. "_" .. BlessElementType.Tu]   = 8,
    [BlessElementType.Tu]                                   = 9,
    [BlessElementType.Tu   .. "_" .. BlessElementType.Jin]  = 10,
}

local function GetElementOrder(tCardData)
    if tCardData.nElementType2 and tCardData.nElementType2 ~= 0 then
        local szKey = tCardData.nElementType1 .. "_" .. tCardData.nElementType2
        return tElementPriority[szKey] or 99
    end
    return tElementPriority[tCardData.nElementType1] or 99
end

local tNewCardWaitViewIDs = {
    VIEW_ID.PanelBlessConfirm,
    VIEW_ID.PanelBlessChoose,
    VIEW_ID.PanelYangDaoSettlement,
    VIEW_ID.PanelYangDaoSettleData,
    VIEW_ID.PanelBattlePersonalCardSettle,
}

ArenaTowerData.nSelDiffMode = ArenaTowerDiffMode.Practice -- 当前选中难度
ArenaTowerData.bShowBlessDetailDesc = false -- 显示祝福卡片详细描述
ArenaTowerData.bDisableSwitchConfirm = false -- 切换难度确认-本次登录不再提醒
ArenaTowerData.bArenaTowerViewFold = false -- 右下角界面折叠状态

local function Log(szFormat, ...)
    LOG.INFO(szFormat, ...)
end

ArenaTowerData.bDebug = true
local function DebugLog(szFormat, ...)
    if ArenaTowerData.bDebug then
        LOG.INFO("[Debug]" .. szFormat, ...)
    end
end

function ArenaTowerData.Init()
    self.RegEvent()
    self.tBattleInfo = {}
end

function ArenaTowerData.UnInit()
    Event.UnRegAll(self)
    Timer.DelAllTimer(self)

    self.tBattleInfo = {}
    self.nSelDiffMode = ArenaTowerDiffMode.Practice
    self.bShowBlessDetailDesc = false
    self.bDisableSwitchConfirm = false
    self.bArenaTowerViewFold = false
end

function ArenaTowerData.RegEvent()
    Event.Reg(self, "LOADING_END", function()
        RemoteCallToServer("On_ArenaTower_GetRobotList") -- 回调On_ArenaTower_GetRobotList_Res

        local player = GetClientPlayer()
        if player and not player.HaveRemoteData(REMOTE_ARENATOWER_INFO) then
            Log("[ArenaTower] GetClientPlayer().ApplyRemoteData(REMOTE_ARENATOWER_INFO)")
            player.ApplyRemoteData(REMOTE_ARENATOWER_INFO, REMOTE_DATA_APPLY_EVENT_TYPE.CLIENT_APPLY_SERVER_CALL_BACK) -- 回调REMOTE_ARENA_TOWER_EVENT
        end

        if not self.IsInArenaTowerMap() then
            return
        end

        Event.Dispatch("On_ArenaTower_UpdateRoundState", ArenaTowerBattleState.Rest) -- 初始化数据
        Event.Dispatch(EventType.OnTogArenaTowerElementInfo, true) -- 进图显示元素点
    end)
    Event.Reg(self, "PLAYER_ENTER_SCENE", function(dwPlayerID)
        DebugLog("[ArenaTower] PLAYER_ENTER_SCENE %s", tostring(dwPlayerID))
        if self.IsInArenaTowerMap() then
            TopBuffData.UpdateTopBuff(true, dwPlayerID)
            Event.Dispatch(EventType.OnArenaTowerPlayerUpdate)
        end
    end)
    Event.Reg(self, "PLAYER_LEAVE_SCENE", function(dwPlayerID)
        DebugLog("[ArenaTower] PLAYER_LEAVE_SCENE %s", tostring(dwPlayerID))
        local player = GetClientPlayer()
        if not player or dwPlayerID == player.dwID then
            self.tBattleInfo = {}
            Event.Dispatch(EventType.OnTogArenaTowerElementInfo, false)
            Event.Dispatch(EventType.UpdateArenaTowerActionBar, false)
        end
        if self.IsInArenaTowerMap() then
            TopBuffData.UpdateTopBuff(false, dwPlayerID)
            Event.Dispatch(EventType.OnArenaTowerPlayerUpdate)
        end
    end)

    Event.Reg(self, "On_ArenaTower_GetRobotList_Res", function(tRoundRobotList)
        Log("[ArenaTower] On_ArenaTower_GetRobotList_Res")
        self.tRoundRobotList = tRoundRobotList
    end)
    Event.Reg(self, "On_ArenaTower_ShopBuy_Respond", function()
        -- 购买成功
        Log("[ArenaTower] On_ArenaTower_ShopBuy_Respond")
        Event.Dispatch(EventType.OnArenaTowerDataUpdate)
    end)
    Event.Reg(self, "On_ArenaTower_ApplyEnhanced_Res", function()
        -- 强化成功
        Log("[ArenaTower] On_ArenaTower_ApplyEnhanced_Res")
        Event.Dispatch(EventType.OnArenaTowerDataUpdate)
    end)
    Event.Reg(self, "On_ArenaTower_ChooseBonus_Res", function()
        -- 选择成功
        Log("[ArenaTower] On_ArenaTower_ChooseBonus_Res")
        self.bArenaTowerViewFold = false
        Event.Dispatch(EventType.OnArenaTowerDataUpdate)
    end)
    Event.Reg(self, "On_ArenaTower_UpdateProgress", function()
        -- 通知更新关卡难度&进度
        Log("[ArenaTower] On_ArenaTower_UpdateProgress")
        Event.Dispatch(EventType.OnArenaTowerDiffProgressUpdate)
    end)
    Event.Reg(self, "On_ArenaTower_UpdateRoundState", function(nBattleState)
        -- 局内数据 SPECIAL_OP_3/SPECIAL_OP_4 更新（关卡状态/准备状态）
        DebugLog("[ArenaTower] On_ArenaTower_UpdateRoundState %s", tostring(nBattleState))
        if not self.tBattleInfo then return end
        self.tBattleInfo.bUpdateRoundState = true
        ApplyBattleFieldStatistics() -- 回调BATTLE_FIELD_SYNC_STATISTICS
        if nBattleState == ArenaTowerBattleState.Matching then
            self.ClearData()
        end
    end)
    -- Event.Reg(self, "On_ArenaTower_ButtonShow", function()
    --     DebugLog("[ArenaTower] On_ArenaTower_ButtonShow")
    -- end)
    -- Event.Reg(self, "On_ArenaTower_UpdateCoinInGame", function()
    --     DebugLog("[ArenaTower] On_ArenaTower_UpdateCoinInGame")
    -- end)
    Event.Reg(self, "On_ArenaTower_CardEvent", function(szEvent, nCardID, ...)
        DebugLog("[ArenaTower] On_ArenaTower_CardEvent %s %s", tostring(szEvent), tostring(nCardID))
        self.OnCardEvent(szEvent, nCardID, ...)
    end)
    Event.Reg(self, "On_ArenaTower_CardNew", function(tCardList)
        Log("[ArenaTower] On_ArenaTower_CardNew")
        self.OnGetNewCard(tCardList)
    end)
    Event.Reg(self, "On_ArenaTower_EventNotify", function(szEvent, ...)
        if not self.IsInArenaTowerMap() then
            return
        end
        DebugLog("[ArenaTower] On_ArenaTower_EventNotify %s", tostring(szEvent))
        local tParams = {...}
        if szEvent == "PLAYER_UPDATE" then
            print("PLAYER_UPDATE", tParams[1] and tParams[1][0] or "nil", tParams[1] and tParams[1][1] or "nil", tParams[2])
            if self.tBattleInfo then
                self.tBattleInfo.tBattlePlayerData = tParams[1] -- 主界面上面显示 几对几 的双方存活数据
                self.tBattleInfo.nBattleStartTime = tParams[2] -- 战斗开始时间，用于显示右上角倒计时和结算时显示总战斗时长
                Event.Dispatch(EventType.OnArenaTowerUpdateRoundState)
            end
        elseif szEvent == "START_COUNT_DOWN" then
            -- print("START_COUNT_DOWN", tParams[1] or "nil")
            local nCountDown = tParams[1]
            TipsHelper.UpdateCountDown(nCountDown)
        end
    end)

    Event.Reg(self, "BATTLE_FIELD_END", function()
        if not self.IsInArenaTowerMap() then
            return
        end
        UIMgr.CloseAllInLayer(UILayer.Page, {VIEW_ID.PanelBlessConfirm}) -- 现在新祝福界面已经改为延迟打开，不过这里还是做个保底
        UIMgr.CloseAllInLayer(UILayer.Popup)
    end)
    Event.Reg(self, "BATTLE_FIELD_SYNC_STATISTICS", function()
        if not self.IsInArenaTowerMap() or not self.tBattleInfo then
            return
        end

        local tStatistics = GetBattleFieldStatistics()
        if not tStatistics then
            return
        end

        -- print_table("[ArenaTower] BATTLE_FIELD_SYNC_STATISTICS", tStatistics)

        self.tBattleInfo.tStatistics = tStatistics
        if self.tBattleInfo.bUpdateRoundState then
            -- On_ArenaTower_UpdateRoundState请求ApplyBattleFieldStatistics的回调
            self.tBattleInfo.bUpdateRoundState = false
            self.OnUpdateRoundState()
        end
    end)
    Event.Reg(self, "REMOTE_ARENA_TOWER_EVENT", function(dwPlayerID, nType)
        local player = GetClientPlayer()
        if not player then
            return
        end

        if nType == REMOTE_ARENATOWER_INFO then
            Log("[ArenaTower] REMOTE_ARENA_TOWER_EVENT %s", tostring(dwPlayerID))
            if dwPlayerID == player.dwID then
                local nDiffMode, _, _, _ = self.GetBaseInfo()
                self.SetSelDiffMode(nDiffMode)
                Event.Dispatch(EventType.OnArenaTowerDataUpdate)
            else
                self.tMemberRemoteDataResult[dwPlayerID] = true
                local bAllSuccess = true
                for dwPlayerID, bResult in pairs(self.tMemberRemoteDataResult) do
                    if not bResult then
                        bAllSuccess = false
                        break
                    end
                end
                if bAllSuccess then
                    Event.Dispatch(EventType.OnArenaTowerApplyMemberRemoteData)
                end
            end
        end
    end)
    Event.Reg(self, "ON_UPDATE_TALENT", function(dwPlayerID, nType)
        if not nType == QIXUE_TYPE.PVP_SHOW or not self.IsInArenaTowerMap() or not self.tBattleInfo then
            return
        end

        local bUpdate = false
        local player = GetPlayer(dwPlayerID)
        local dwMountKungfuID = player and player.GetActualKungfuMountID()
        DebugLog("[ArenaTower] ON_UPDATE_TALENT %s %s", tostring(dwPlayerID), tostring(dwMountKungfuID))
        if dwMountKungfuID then
            self.tBattleInfo.tPlayerKungfuID = self.tBattleInfo.tPlayerKungfuID or {}
            if self.tBattleInfo.tPlayerKungfuID[dwPlayerID] ~= dwMountKungfuID then
                bUpdate = true
                self.tBattleInfo.tPlayerKungfuID[dwPlayerID] = dwMountKungfuID
            end
        end
        if bUpdate then
            Event.Dispatch(EventType.OnArenaTowerPlayerUpdate)
        end
    end)
    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        if table.contain_value(tNewCardWaitViewIDs or {}, nViewID) then
            -- 延迟0.5秒，避免关闭胜利/失败界面后，又打开结算界面；关闭结算界面后，又打开祝福选择界面
            Timer.DelTimer(self, self.nNewCardTimerID)
            self.nNewCardTimerID = Timer.Add(self, 0.5, function()
                self.CheckShowNextNewCardList()
            end)
        end
    end)

    Event.Reg(self, EventType.OnOpenActionBar, function(tbInfo)
        if not self.IsInArenaTowerMap() then
            return
        end

        local player = GetClientPlayer()
        if not player then
            return
        end

        self.tBattleInfo.tActionBarInfo = tbInfo
        self.tBattleInfo.tActionBarSkillInfo = {}

        local dwIndex = tbInfo.dwIndex
        if dwIndex == self.EXTEND_ACTION_BAR_INDEX then
            Log("[ArenaTower] OnOpenActionBar")
            local tbParams = tbInfo.tbParams
            for _, tbList in ipairs(tbParams) do
                local tSkillInfo = {}
                for _, tbParam in ipairs(tbList) do
                    if tbParam[1] == UI_OBJECT.SKILL then
                        local nSkillID = tbParam[2]
                        local nSkillLevel = math.max(1, player.GetSkillLevel(nSkillID))
                        tSkillInfo = {
                            nOriginSkillID = nSkillID,
                            nSkillID = nSkillID,
                            nSkillLevel = nSkillLevel
                        }
                        break
                    end
                end

                if not table_is_empty(tSkillInfo) then
                    table.insert(self.tBattleInfo.tActionBarSkillInfo, tSkillInfo)
                end
            end
            Event.Dispatch(EventType.UpdateArenaTowerActionBar, true)
        end
    end)
    Event.Reg(self, EventType.OnCloseActionBar, function(dwIndex)
        if not self.tBattleInfo then
            return
        end

        if dwIndex == self.EXTEND_ACTION_BAR_INDEX then
            Log("[ArenaTower] OnCloseActionBar")
            self.tBattleInfo.tActionBarInfo = nil
            self.tBattleInfo.tActionBarSkillInfo = nil
            Event.Dispatch(EventType.UpdateArenaTowerActionBar, false)
        end
    end)
    Event.Reg(self, "ON_SKILL_REPLACE", function (dwOldSkillID, dwNewSkillID, nNewSkillLevel, dwOrgSkillID)
        if not self.IsInArenaTowerMap() then
            return
        end

        if not self.tBattleInfo then
            return
        end

        for _, tInfo in ipairs(self.tBattleInfo.tActionBarSkillInfo or {}) do
            if tInfo.nOriginSkillID == dwOldSkillID or tInfo.nSkillID == dwOldSkillID then
                tInfo.nSkillID = dwNewSkillID
                tInfo.nSkillLevel = nNewSkillLevel
                Event.Dispatch(EventType.UpdateArenaTowerActionBar, true)
            end
        end
    end)
end

function ArenaTowerData.IsInArenaTowerMap()
    local player = GetClientPlayer()
    if player then
        local dwMapID = player.GetMapID()
        return dwMapID == BATTLE_FIELD_MAP_ID.QING_XIAO_SHAN
    end
    return false
end

function ArenaTowerData.ShowBlessDetailDesc(bShow)
    self.bShowBlessDetailDesc = bShow
    Event.Dispatch(EventType.OnShowBlessDetailDesc, bShow)
end

function ArenaTowerData.OpenArenaTowerAwardShop()
    ShopData.OpenSystemShopGroup(1, 1569)
end

function ArenaTowerData.PlayerHaveRemoteData()
    local player = GetClientPlayer()
    return player and player.HaveRemoteData(REMOTE_ARENATOWER_INFO) or false
end

--OnArenaTowerApplyMemberRemoteData
function ArenaTowerData.ApplyMemberRemoteData()
    local player = GetClientPlayer()
    if not player then
        return
    end

    -- 只取队友，不取自己

    local nMemberCount = 0 -- 只取3个，人太多反正进不去没必要全取
    local tMemberRemoteDataResult = {}
    if TeamData.IsInParty() then
        TeamData.Generator(function(dwID, tMemberInfo)
            if nMemberCount >= self.BATTLE_PLAYER_COUNT then
                return
            end
            local dwPlayerID = tMemberInfo.dwMemberID
            if dwPlayerID ~= player.dwID then
                tMemberRemoteDataResult[dwPlayerID] = false
            end
            nMemberCount = nMemberCount + 1
        end)
    elseif RoomData.IsHaveRoom() then
        local hRoom = GetGlobalRoomClient()
        local tRoomInfo = hRoom and hRoom.GetGlobalRoomInfo()
        local nMemberCount = 0
        for _, tMemberInfo in pairs(tRoomInfo or {}) do
            if nMemberCount >= self.BATTLE_PLAYER_COUNT then
                break
            end
            if type(tMemberInfo) == "table" and tMemberInfo.szGlobalID then
                local dwPlayerID = RoomData.GetTeamPlayerIDByGlobalID(tMemberInfo.szGlobalID) -- TODO 跨服获取不到
                if dwPlayerID then
                    if dwPlayerID ~= player.dwID then
                        tMemberRemoteDataResult[dwPlayerID] = false
                    end
                else
                    -- TODO
                end
                nMemberCount = nMemberCount + 1
            end
        end
    end

    self.tMemberRemoteDataResult = tMemberRemoteDataResult
    for dwPlayerID, bResult in pairs(tMemberRemoteDataResult) do
        Log("[ArenaTower] PeekPlayerRemoteData %s", tostring(dwPlayerID))
        PeekPlayerRemoteData(dwPlayerID, REMOTE_ARENATOWER_INFO) -- 回调REMOTE_ARENA_TOWER_EVENT
    end
end

-- 跨服不行
function ArenaTowerData.GetMemberBaseInfo(dwPlayerID)
    if not dwPlayerID then
        return
    end

    local player = GetClientPlayer()
    if not player then
        return
    end

    if dwPlayerID ~= player.dwID then
        if not self.tMemberRemoteDataResult or not self.tMemberRemoteDataResult[dwPlayerID] then
            LOG.ERROR("[ArenaTower] GetMemberBaseInfo %s Error, please ApplyMemberRemoteData before.", tostring(dwPlayerID))
            return
        end

        -- GetOtherPlayerRemoteArrayUInt的dwPlayerID不能为ClientPlayer
        local nMode = GetOtherPlayerRemoteArrayUInt(dwPlayerID, REMOTE_ARENATOWER_INFO, tArenaTowerRemoteData.Mode[1], 1)
        local nProgressLx = GetOtherPlayerRemoteArrayUInt(dwPlayerID, REMOTE_ARENATOWER_INFO, tArenaTowerRemoteData.ProgressLx[1], 1)
        local nProgressTz = GetOtherPlayerRemoteArrayUInt(dwPlayerID, REMOTE_ARENATOWER_INFO, tArenaTowerRemoteData.ProgressTz[1], 1)

        local nDiffMode, nLevelProgress
        if nMode == 0 then
            nDiffMode = ArenaTowerDiffMode.Practice
            nLevelProgress = nProgressLx
        elseif nMode == 1 then
            nDiffMode = ArenaTowerDiffMode.Challenge
            nLevelProgress = nProgressTz
        end

        return nDiffMode, nLevelProgress
    else
        local nDiffMode, nLevelProgress, _, _ = self.GetBaseInfo()
        return nDiffMode, nLevelProgress
    end
end

function ArenaTowerData.GetBaseInfo()
    -- 当前关卡模式 (0练习，1挑战)|练习模式进度|挑战模式进度|练习模式领奖进度 {1, 1, 1,...}|挑战模式领奖进度 {1, 1, 0,...}
    local nMode, nProgressLx, nProgressTz, tRewardLx, tRewardTz = GDAPI_GetArenaTowerBaseInfo()
    local nDiffMode, nLevelProgress -- nLevelProgress是已通关关卡，要挑战的关卡是nLevelProgress + 1
    if nMode == 0 then
        nDiffMode = ArenaTowerDiffMode.Practice
        nLevelProgress = nProgressLx
    elseif nMode == 1 then
        nDiffMode = ArenaTowerDiffMode.Challenge
        nLevelProgress = nProgressTz
    end
    local tLevelState = {}
    for i = 1, self.MAX_LEVEL_COUNT do
        local nLevelState
        if tRewardTz[i] == 1 then
            nLevelState = ArenaTowerLevelState.ChallengeCompleted
        elseif tRewardLx[i] == 1 then
            nLevelState = ArenaTowerLevelState.PracticeCompleted
        else
            nLevelState = ArenaTowerLevelState.Incomplete
        end
        table.insert(tLevelState, nLevelState)
    end
    return nDiffMode, nLevelProgress, tLevelState
end

function ArenaTowerData.GetCoinInGameInfo()
    -- 局内代币数，局内代币上限
    local nCoinInGame, nMaxCoinInGame = GDAPI_GetArenaTowerCoinInGame()
    return nCoinInGame, nMaxCoinInGame
end

function ArenaTowerData.GetElementPointInfo()
    -- 金水木火土元素点，格式{0, 0, 0, 0, 0}|木属性生机值，生机值进度条上限，格式{0, 6}
    local tWuXing, tGrowWood = GDAPI_GetArenaTowerWuXingInfo()
    local tElementPoint = {
        [BlessElementType.Jin] = tWuXing[1],
        [BlessElementType.Shui] = tWuXing[2], -- 先水后木，按相生顺序
        [BlessElementType.Mu] = tWuXing[3],
        [BlessElementType.Huo] = tWuXing[4],
        [BlessElementType.Tu] = tWuXing[5],
    }
    local nGrowWoodPoint = tGrowWood[1]
    local nMaxGrowWoodPoint = tGrowWood[2]
    return tElementPoint, nGrowWoodPoint, nMaxGrowWoodPoint
end

function ArenaTowerData.GetRefreshCountInfo()
    -- 剩余免费刷新点数，已使用刷新点数，刷新点数使用上限
    local nFreeRefreshCount, nUseRefreshCount, nMaxRefreshCount = GDAPI_GetArenaTowerRefreshInfo()

    -- 易卦盘
    local player = GetClientPlayer()
    local dwTabType = self.REFRESH_ITEM_ID[1]
    local dwIndex = self.REFRESH_ITEM_ID[2]
    local nRefreshItemCount = player and player.GetItemAmountInPackage(dwTabType, dwIndex) or 0

    return nFreeRefreshCount, nUseRefreshCount, nMaxRefreshCount, nRefreshItemCount
end

function ArenaTowerData.GetStatsInfo()
    -- 总时长（秒）|总伤害（万）|总治疗（万）
    local nTotalTime, nTotalDamage, nTotalTherapy =  GDAPI_GetArenaTowerSummary()
    return nTotalTime, nTotalDamage, nTotalTherapy
end

function ArenaTowerData.GetCardListInfo()
    -- {{卡牌Index, 燃烧状态, 燃烧剩余回合数, 强化状态,自增长计数}, {},...}
    local tCardList = GDAPI_GetArenaTowerCardListInfo()

    local tBlessCardList = {}
    for _, tCard in ipairs(tCardList) do
        local tCardData = self.GetBaseCardDataByCardID(tCard[1])
        if tCardData then
            tCardData.nState = tCard[2] -- 与BlessCardState对应
            tCardData.nLeftBurnRound = tCard[3]
            tCardData.bEnhanced = tCard[4] == 1
            -- tCardData.nCustomValue = tCard[5]
            self.UpdateCardDataSkillInfo(tCardData)
            table.insert(tBlessCardList, tCardData)
        end
    end
    Global.SortStably(tBlessCardList, function(a, b)
        -- 1. 主动技能在前
        if a.bMainSkill ~= b.bMainSkill then
            return a.bMainSkill
        end
        -- 2. 星级高的在前
        if a.nStar ~= b.nStar then
            return a.nStar > b.nStar
        end
        -- 3. 元素优先级排序
        local nOrderA = GetElementOrder(a)
        local nOrderB = GetElementOrder(b)
        if nOrderA ~= nOrderB then
            return nOrderA < nOrderB
        end
        -- 4. 保底按卡牌序号从高到低
        return a.nCardID > b.nCardID
    end)
    return tBlessCardList
end

function ArenaTowerData.GetShopListInfo()
    -- {{商品类型, 商品/卡牌Index, 剩余数量, 局内代币售价}, {},...}
    local tCardList = GDAPI_GetArenaTowerShopListInfo()

    local tShopCardList = {}
    for _, tCard in ipairs(tCardList) do
        local tCardData
        if tCard[1] == 1 then
            tCardData = self.GetBaseCardDataByCardID(tCard[2])
            if tCardData then
                tCardData.nShopItemType = BlessShopItemType.Bless
            end
        elseif tCard[1] == 2 then
            tCardData = self.GetBaseCardDataByCardID(tCard[2], true)
            if tCardData then
                tCardData.nShopItemType = BlessShopItemType.ElementPoint
            end
        elseif tCard[1] == 3 then
            tCardData = self.GetBaseCardDataByCardID(tCard[2], true)
            if tCardData then
                tCardData.nShopItemType = BlessShopItemType.AttritubeUp
            end
        end

        if tCardData then
            tCardData.nLeftBuyCount = tCard[3]
            tCardData.nPrice = tCard[4]
            table.insert(tShopCardList, tCardData)
        end
    end

    return tShopCardList
end

function ArenaTowerData.GetRandListInfo()
    -- {{卡牌Index}, {卡牌Index},...}
    local tCardList = GDAPI_GetArenaTowerRandListInfo()

    local tBlessCardList = {}
    for _, tCard in ipairs(tCardList) do
        local tCardData = self.GetBaseCardDataByCardID(tCard[1])
        if tCardData then
            table.insert(tBlessCardList, tCardData)
        end
    end
    return tBlessCardList
end

-- NOTE: 若未来存在重复卡片，可新增nListIndex字段作唯一标识
function ArenaTowerData.GetBaseCardDataByCardID(nCardID, bOtherCard)
    local tCardConfig = self.GetCardConfig(nCardID, bOtherCard)
    if not tCardConfig then
        return
    end

    local nElementType1, nElementType2
    local function SetElementType(nElementType, bConfigValue)
        if bConfigValue then
            if not nElementType1 then
                nElementType1 = nElementType
            elseif not nElementType2 then
                nElementType2 = nElementType
            else
                LOG.ERROR("[ArenaTower] Card [%d] already has two elements.", nCardID)
            end
        end
    end

    -- 这里会保证nElementType1和nElementType2按[金水木火土循环]优先级排
    SetElementType(BlessElementType.Jin, tCardConfig.bGold)
    SetElementType(BlessElementType.Shui, tCardConfig.bWater) -- 先水后木，按相生顺序
    SetElementType(BlessElementType.Mu, tCardConfig.bWood)
    SetElementType(BlessElementType.Huo, tCardConfig.bFire)
    SetElementType(BlessElementType.Tu, tCardConfig.bEarth)
    if nElementType1 == BlessElementType.Jin and nElementType2 == BlessElementType.Tu then
        nElementType1 = BlessElementType.Tu -- 按金水木火土循环，土和金先土后金
        nElementType2 = BlessElementType.Jin
    end

    local nAddElementPoint = 1
    local tElementPointType = {}

    if not bOtherCard then
        if string.is_nil(tCardConfig.szSpecialWuXing) then
            if nElementType1 then
                table.insert(tElementPointType, nElementType1)
            end
            if nElementType2 then
                table.insert(tElementPointType, nElementType2)
            end
        else
            local tElementPointInfo = string.split(tCardConfig.szSpecialWuXing, ";")
            nAddElementPoint = tElementPointInfo and tonumber(tElementPointInfo[1]) or 0
            local tElementTypeInfo = tElementPointInfo and string.split(tElementPointInfo[2], ":")
            for _, szElementType in pairs(tElementTypeInfo or {}) do
                if szElementType == "Gold" then
                    table.insert(tElementPointType, BlessElementType.Jin)
                elseif szElementType == "Wood" then
                    table.insert(tElementPointType, BlessElementType.Mu)
                elseif szElementType == "Water" then
                    table.insert(tElementPointType, BlessElementType.Shui)
                elseif szElementType == "Fire" then
                    table.insert(tElementPointType, BlessElementType.Huo)
                elseif szElementType == "Earth" then
                    table.insert(tElementPointType, BlessElementType.Tu)
                end
            end
        end

        local function GetSkillInfo(nSkillID, nSkillLevel)
            local tSkillConfig = Table_GetSkill(nSkillID, nSkillLevel)
            if not tSkillConfig then
                LOG.WARN("[ArenaTower] Skill Invalid: %d, %d", nSkillID, nSkillLevel)
                return
            end

            SkillData.ClearSpecialNoun()
            local szDesc = GetSkillDesc(nSkillID, nSkillLevel)
            local szShortDesc = GetSkillDesc(nSkillID, nSkillLevel, nil, nil, true)

            -- 根据卡牌技能ID+卡牌技能等级获取技能名称、图标、描述、主/被动技能、CD等信息
            local tSkillInfo = {
                bMainSkill = not SkillData.IsPassiveSkill(nSkillID, nSkillLevel),
                szIconPath = UIHelper.GetIconPathByIconID(tSkillConfig.dwIconID),
                szName = UIHelper.GBKToUTF8(tSkillConfig.szName),
                szDesc = UIHelper.GBKToUTF8(szDesc), -- UIHelper.GBKToUTF8(tSkillConfig.szDesc),
                szShortDesc = UIHelper.GBKToUTF8(szShortDesc), -- UIHelper.GBKToUTF8(tSkillConfig.szShortDesc),
            }
            return tSkillInfo
        end

        local tSkillInfo = GetSkillInfo(tCardConfig.nSkillID, tCardConfig.nSkillLevel)
        if not tSkillInfo then
            LOG.ERROR("[ArenaTower] Card [%d] Skill Invalid: %d, %d", nCardID, tCardConfig.nSkillID, tCardConfig.nSkillLevel)
            return
        end

        local tCardData = {
            nCardID = nCardID,
            szCardName = UIHelper.GBKToUTF8(tCardConfig.szName),
            nElementType1 = nElementType1,
            nElementType2 = nElementType2,
            nStar = tCardConfig.nStar,
            nTag = tCardConfig.nTag,
            nSpecialTag = tCardConfig.nSpecialTag,
            nAddElementPoint = nAddElementPoint,
            tElementPointType = tElementPointType,
            bCanEnhanced = tCardConfig.bCanEnhanced,
            tSkillInfo = tSkillInfo,
            tEnhancedSkillInfo = tCardConfig.bCanEnhanced and GetSkillInfo(tCardConfig.nEnhancedSkillID, tCardConfig.nEnhancedSkillLevel) or nil,
            tFireSkillInfo = tCardConfig.bCanFire and GetSkillInfo(tCardConfig.nFireSkillID, tCardConfig.nFireSkillLevel) or nil,
            tEnhancedFireSkillInfo = tCardConfig.bCanEnhanced and tCardConfig.bCanFire and GetSkillInfo(tCardConfig.nEnhancedFireSkillID, tCardConfig.nEnhancedFireSkillLevel) or nil,
        }
        self.UpdateCardDataSkillInfo(tCardData)
        return tCardData
    else
        if nElementType1 then
            table.insert(tElementPointType, nElementType1)
        end
        if nElementType2 then
            table.insert(tElementPointType, nElementType2)
        end

        local szIconPath = UIHelper.GetIconPathByIconID(tCardConfig.nIconID)
        local szName = UIHelper.GBKToUTF8(tCardConfig.szName)
        local szDesc = UIHelper.GBKToUTF8(tCardConfig.szDescribe)

        local tCardData = {
            nCardID = nCardID,
            szCardName = szName,
            nElementType1 = nElementType1,
            nElementType2 = nElementType2,
            nAddElementPoint = nAddElementPoint,
            tElementPointType = tElementPointType,
            szIconPath = szIconPath,
            szName = szName,
            szDesc = szDesc,
            szShortDesc = szDesc,
        }
        return tCardData
    end
end

function ArenaTowerData.UpdateCardDataSkillInfo(tCardData)
    if not tCardData then
        return
    end

    local function ApplySkillInfo(tSkillInfo)
        if not tSkillInfo then return end
        tCardData.bMainSkill = tSkillInfo.bMainSkill
        tCardData.szIconPath = tSkillInfo.szIconPath
        tCardData.szName = tSkillInfo.szName
        tCardData.szDesc = tSkillInfo.szDesc
        tCardData.szShortDesc = tSkillInfo.szShortDesc
    end

    local bEnhanced = tCardData.bEnhanced or false
    local nState = tCardData.nState or BlessCardState.Normal
    if bEnhanced and nState ~= BlessCardState.Burning and tCardData.tEnhancedSkillInfo then
        ApplySkillInfo(tCardData.tEnhancedSkillInfo)
    elseif not bEnhanced and nState == BlessCardState.Burning and tCardData.tFireSkillInfo then
        ApplySkillInfo(tCardData.tFireSkillInfo)
    elseif bEnhanced and nState == BlessCardState.Burning and tCardData.tEnhancedFireSkillInfo then
        ApplySkillInfo(tCardData.tEnhancedFireSkillInfo)
    else
        ApplySkillInfo(tCardData.tSkillInfo)
    end
end

function ArenaTowerData.GetLevelListInfo()
    local _, _, tLevelState, _ = self.GetBaseInfo()
    local tLevelList = {}
    for nLevelIndex = 1, self.MAX_LEVEL_COUNT do
        local tLevelConfig = self.GetLevelConfig(nLevelIndex)
        if tLevelConfig then
            local tLevelData = {
                nLevelIndex = nLevelIndex,
                bSpecial = tLevelConfig.bShopRound,
                nLevelState = tLevelState[nLevelIndex],
                tRewardInfo = self.GetLevelRewardInfo(tLevelConfig),
                tEnemyInfo = self.GetLevelEnemyInfo(nLevelIndex),
            }
            table.insert(tLevelList, tLevelData)
        end
    end
    return tLevelList
end

function ArenaTowerData.GetLevelRewardInfo(tLevelConfig)
    if not tLevelConfig then
        return
    end

    local tRewardInfo = {
        [ArenaTowerDiffMode.Practice] = {},
        [ArenaTowerDiffMode.Challenge] = {},
    }
    local function InsertCurrencyReward(nDiffMode, szCurrencyType, nCount)
        if not szCurrencyType or szCurrencyType == "" or nCount <= 0 then
            return
        end
        local tInfo = {"COIN", szCurrencyType, nCount}
        table.insert(tRewardInfo[nDiffMode], tInfo)
    end
    local function InsertItemReward(nDiffMode, szReward)
        if not szReward or szReward == "" then
            return
        end
        local tReward = string.split(szReward, ";")
        local nNum = #tReward
        for nIndex = 1, nNum do
            if tReward[nIndex] ~= "" then
                local tInfo = string.split(tReward[nIndex], "_")
                table.insert(tRewardInfo[nDiffMode], tInfo)
            end
        end
    end

    InsertCurrencyReward(ArenaTowerDiffMode.Practice, CurrencyType.Prestige, tLevelConfig.nAddPrestigeLx)
    InsertCurrencyReward(ArenaTowerDiffMode.Practice, CurrencyType.TitlePoint, tLevelConfig.nAddTitlePointLx)
    InsertCurrencyReward(ArenaTowerDiffMode.Practice, CurrencyType.ArenaTowerAward, tLevelConfig.nAddArenaTowerAwardLx)
    InsertItemReward(ArenaTowerDiffMode.Practice, tLevelConfig.szAddItemLx)
    InsertCurrencyReward(ArenaTowerDiffMode.Challenge, CurrencyType.Prestige, tLevelConfig.nAddPrestigeTz)
    InsertCurrencyReward(ArenaTowerDiffMode.Challenge, CurrencyType.TitlePoint, tLevelConfig.nAddTitlePointTz)
    InsertCurrencyReward(ArenaTowerDiffMode.Challenge, CurrencyType.ArenaTowerAward, tLevelConfig.nAddArenaTowerAwardTz)
    InsertItemReward(ArenaTowerDiffMode.Challenge, tLevelConfig.szAddItemTz)
    return tRewardInfo
end

function ArenaTowerData.GetLevelEnemyInfo(nLevelIndex)
    -- {[关卡序号] = {机器人心法1, 机器人心法2, 机器人心法3}, [关卡序号] = {机器人心法1, 机器人心法2, 机器人心法3},...}
    local tRoundList = self.tRoundRobotList or {}
    local tEnemyInfo = {}
    for i, dwKungfuID in ipairs(tRoundList[nLevelIndex] or {}) do
        local nHDKungFuID = TabHelper.GetHDKungfuID(dwKungfuID)
        local tKungfu = GetSkill(nHDKungFuID, 1)
        local dwMountType = tKungfu and tKungfu.dwMountType
        local dwSchoolType = dwMountType and MountTypeToSchoolType[dwMountType]
        local dwForceID = dwSchoolType and SchoolTypeToForceID[dwSchoolType]
        local tEnemy = {
            szName = PlayerKungfuChineseName[nHDKungFuID],
            dwForceID = dwForceID,
            dwKungfuID = nHDKungFuID,
        }
        table.insert(tEnemyInfo, tEnemy)
    end
    return tEnemyInfo
end

local tPlayerKungfuID = {}
function ArenaTowerData.GetBattlePlayerData(bEnemy)
    if not self.tBattleInfo then
        return
    end

    local me = GetClientPlayer()
    if not me then
        return
    end

    self.tBattleInfo.tPlayerKungfuID = self.tBattleInfo.tPlayerKungfuID or {}

    local tData = {}
    local tAllPlayer = PlayerData.GetAllPlayer()
    for dwPlayerID, player in pairs(tAllPlayer or {}) do
        local dwMountKungfuID = player.GetActualKungfuMountID() -- 要调PeekOtherPlayerTalent拉取玩家数据才能取到
        if not dwMountKungfuID then
            dwMountKungfuID = self.tBattleInfo.tPlayerKungfuID[dwPlayerID]
            if dwPlayerID ~= me.dwID then
                DebugLog("[ArenaTower] PeekOtherPlayerTalent %s", tostring(dwPlayerID))
                PeekOtherPlayerTalent(dwPlayerID, QIXUE_TYPE.PVP_SHOW) --回调ON_UPDATE_TALENT
            end
        else
            self.tBattleInfo.tPlayerKungfuID[dwPlayerID] = dwMountKungfuID
        end

        local function InserPlayerInfo()
            local tInfo = {
                dwID = player.dwID,
                szName = player.szName,
                dwForceID = player.dwForceID,
                dwMountKungfuID = dwMountKungfuID,
                nBattleFieldSide = player.nBattleFieldSide,
                nCurrentLife = player.nCurrentLife,
                nMaxLife = player.nMaxLife,
            }
            table.insert(tData, tInfo)
        end

        if player.nBattleFieldSide == 0 or player.nBattleFieldSide == 1 then
            if bEnemy and player.nBattleFieldSide ~= me.nBattleFieldSide then
                InserPlayerInfo()
            elseif not bEnemy and player.nBattleFieldSide == me.nBattleFieldSide then
                InserPlayerInfo()
            end
        end
    end

    return tData
end

function ArenaTowerData.GetLevelConfig(nLevelIndex)
    return nLevelIndex and Table_GetArenaTowerRound(nLevelIndex)
end

function ArenaTowerData.GetCardConfig(nCardID, bOtherCard)
    if not nCardID then
        return
    end
    if bOtherCard then
        local tCardConfig = Table_GetArenaTowerOtherCard(nCardID)
        if not tCardConfig then
            LOG.ERROR("[ArenaTower] Table_GetArenaTowerOtherCard Error, CardID: %s", tostring(nCardID))
        end
        return tCardConfig
    else
        local tCardConfig = Table_GetArenaTowerCard(nCardID)
        if not tCardConfig then
            LOG.ERROR("[ArenaTower] Table_GetArenaTowerCard Error, CardID: %s", tostring(nCardID))
        end
        return tCardConfig
    end
end

local szPracticeIncompleteIcon = "UIAtlas2_YangDao_YangDaoPanel01_ImgReward_Pra01"
local szPracticeCompleteIcon = "UIAtlas2_YangDao_YangDaoPanel01_ImgReward_Pra02"
local szChallengeIncompleteIcon = "UIAtlas2_YangDao_YangDaoPanel01_ImgReward_Cha01"
local szChallengeCompleteIcon = "UIAtlas2_YangDao_YangDaoPanel01_ImgReward_Cha02"
function ArenaTowerData.GetDiffIcon(nLevelState)
    if nLevelState == ArenaTowerLevelState.Incomplete then
        return szPracticeIncompleteIcon, szChallengeIncompleteIcon
    elseif nLevelState == ArenaTowerLevelState.PracticeCompleted then
        return szPracticeCompleteIcon, szChallengeIncompleteIcon
    elseif nLevelState == ArenaTowerLevelState.ChallengeCompleted then
        -- 完成挑战模式即相当于同时完成练习模式和挑战模式
        return szPracticeCompleteIcon, szChallengeCompleteIcon
    end
end

function ArenaTowerData.CardHasElement(tCardData, nElementType)
    return tCardData and (tCardData.nElementType1 == nElementType or tCardData.nElementType2 == nElementType) or false
end

function ArenaTowerData.CardHasShortDesc(tCardData)
    if not tCardData then return false end
    return not string.is_nil(tCardData.szShortDesc) and tCardData.szShortDesc ~= tCardData.szDesc
end

function ArenaTowerData.SetSelDiffMode(nDiffMode)
    if self.nSelDiffMode == nDiffMode then
        return
    end

    self.nSelDiffMode = nDiffMode
    Event.Dispatch(EventType.OnArenaTowerDiffProgressUpdate)
end

function ArenaTowerData.GetSelDiffMode()
    return self.nSelDiffMode
end

function ArenaTowerData.DifficultyDown()
    -- 关卡难度降级
    Log("[ArenaTower] ModeDown")
    RemoteCallToServer("On_ArenaTower_ModeDown") -- 回调On_ArenaTower_UpdateProgress
end

function ArenaTowerData.ResetProgress()
    -- 重置关卡进度
    Log("[ArenaTower] ResetProgress")
    RemoteCallToServer("On_ArenaTower_ResetProgress") -- 回调On_ArenaTower_UpdateProgress
end

function ArenaTowerData.LeaveArenaTower()
    -- 退出关卡
    BattleFieldData.LeaveBattleField()
end

function ArenaTowerData.PlayerReady(bReady)
    -- 玩家准备1/取消准备0
    local nReady = bReady and 1 or 0
    Log("[ArenaTower] PressReady %s", tostring(nReady))
    RemoteCallToServer("On_ArenaTower_PressReady", nReady) --回调On_ArenaTower_UpdateRoundState（其他玩家也会收到）
end

function ArenaTowerData.PlayerRest()
    -- 前往驿站 可购买/强化祝福
    Log("[ArenaTower] PlayerRest")
    RemoteCallToServer("On_ArenaTower_PlayerRest")
end

function ArenaTowerData.CanChooseBless()
    return not IsTableEmpty(GDAPI_GetArenaTowerRandListInfo())
end

function ArenaTowerData.ChooseBless(nCardID, nReplacedCardID)
    if not nCardID then
        return
    end

    -- 选择/替换祝福 nCardID, nReplacedCardID；nReplacedCardID可为空
    Log("[ArenaTower] ChooseBonus %s %s", tostring(nCardID), tostring(nReplacedCardID))
    RemoteCallToServer("On_ArenaTower_ChooseBonus", nCardID, nReplacedCardID) -- 回调On_ArenaTower_ChooseBonus_Res
end

function ArenaTowerData.BuyCard(nCardID, nCardType)
    if not nCardID then
        return
    end

    -- 局内祝福购买 nCardID, nBuyNum, nCardType
    Log("[ArenaTower] ShopBuy %s", tostring(nCardID))
    RemoteCallToServer("On_ArenaTower_ShopBuy", nCardID, 1, nCardType) -- 回调On_ArenaTower_ShopBuy_Respond
end

function ArenaTowerData.EnhanceBless(nCardID)
    if not nCardID then
        return
    end

    -- 强化祝福 nCardID
    Log("[ArenaTower] ApplyEnhanced %s", tostring(nCardID))
    RemoteCallToServer("On_ArenaTower_ApplyEnhanced", nCardID) -- 回调On_ArenaTower_ApplyEnhanced_Res
end

function ArenaTowerData.RefreshShop()
    Log("[ArenaTower] RefreshShop") -- 回调On_ArenaTower_RefreshShop_Res
    RemoteCallToServer("On_ArenaTower_RefreshShop")
end

function ArenaTowerData.RefreshBonus()
    Log("[ArenaTower] RefreshBonus") -- 回调On_ArenaTower_RefreshBonus_Res
    RemoteCallToServer("On_ArenaTower_RefreshBonus")
end

-- 0 PQ_STATISTICS_INDEX.KILL_COUNT 协伤
-- 1 PQ_STATISTICS_INDEX.DECAPITATE_COUNT 击伤
-- 2 PQ_STATISTICS_INDEX.SOLO_COUNT 单挑
-- 3 PQ_STATISTICS_INDEX.HARM_OUTPUT 伤害量
-- 4 PQ_STATISTICS_INDEX.TREAT_OUTPUT 治疗
-- 5 PQ_STATISTICS_INDEX.INJURY 承伤
-- 6 PQ_STATISTICS_INDEX.DEATH_COUNT 受重伤
-- 7 PQ_STATISTICS_INDEX.THREAT_OUTPUT
-- 8 PQ_STATISTICS_INDEX.SKILL_MARK
-- 9 PQ_STATISTICS_INDEX.BEST_ASSIST_KILL_COUNT 助攻
-- 10 PQ_STATISTICS_INDEX.SPECIAL_OP_1 当前模式：0练习 1挑战
-- 11 PQ_STATISTICS_INDEX.SPECIAL_OP_2 当前关卡进度：1~12（和角色远程数据的进度有区别，远程数据上是玩家已通关的进度；这里是即将/正在挑战的关卡）
-- 12 PQ_STATISTICS_INDEX.SPECIAL_OP_3 关卡状态（离线重登时和场景变量的关卡状态做校验）：0休息中，1匹配中，2战斗准备中，3战斗中，4结算中
-- 13 PQ_STATISTICS_INDEX.SPECIAL_OP_4 准备状态：0未准备 1准备中
-- 14 PQ_STATISTICS_INDEX.SPECIAL_OP_5
-- 15 PQ_STATISTICS_INDEX.SPECIAL_OP_6
-- 16 PQ_STATISTICS_INDEX.SPECIAL_OP_7 是否被降级：0/1（挑战模式下失败，模式会被降级为练习，结算时需要展示特殊动画和提示内容）
-- 17 PQ_STATISTICS_INDEX.SPECIAL_OP_8 是否全场最佳：0/1
-- 18 PQ_STATISTICS_INDEX.FINAL_MARK
-- 19 PQ_STATISTICS_INDEX.AWARD_MONEY
-- 20 PQ_STATISTICS_INDEX.AWARD_EXP
-- 21 PQ_STATISTICS_INDEX.AWARD_1  结算奖励鸣铮玉（扬刀大会专属代币，用于系统商店购买）
-- 22 PQ_STATISTICS_INDEX.AWARD_2  结算奖励威名点
-- 23 PQ_STATISTICS_INDEX.AWARD_3  结算奖励战阶
-- 24 PQ_STATISTICS_INDEX.AWARD_4  结算奖励天机筹（局内代币，用于局内玩法消耗）
function ArenaTowerData.GetPQStatisticsData(dwPlayerID, nPQStatisticsIndex)
    if not dwPlayerID or not nPQStatisticsIndex then
        return
    end

    local tStatistics = self.tBattleInfo and self.tBattleInfo.tStatistics or GetBattleFieldStatistics()
    local tData = tStatistics and tStatistics[dwPlayerID]
    if not tData then
        return
    end

    return tData[nPQStatisticsIndex]
end

function ArenaTowerData.GetBattleStateInfo()
    local player = GetClientPlayer()
    if not player then
        return
    end

    -- local nMode = self.GetPQStatisticsData(player.dwID, PQ_STATISTICS_INDEX.SPECIAL_OP_1)
    -- local nLevelIndex = self.GetPQStatisticsData(player.dwID, PQ_STATISTICS_INDEX.SPECIAL_OP_2)
    local nBattleState = self.GetPQStatisticsData(player.dwID, PQ_STATISTICS_INDEX.SPECIAL_OP_3) -- ArenaTowerBattleState
    local bReady = self.GetPQStatisticsData(player.dwID, PQ_STATISTICS_INDEX.SPECIAL_OP_4) == 1
    return nBattleState, bReady
end

function ArenaTowerData.CanGetBattleFieldInfo()
    local tStatistics = self.tBattleInfo and self.tBattleInfo.tStatistics or GetBattleFieldStatistics()
    if not tStatistics then
        return false
    end
    return true
end

function ArenaTowerData.GetTitleInfo()
    if not self.tBattleInfo then
        return
    end
    return self.tBattleInfo.tBattlePlayerData, self.tBattleInfo.nBattleStartTime, self.tBattleInfo.nBattleEndTime
end

function ArenaTowerData.GetMatchInfo()
    if not self.tBattleInfo then
        return
    end
    return self.tBattleInfo.nMatchStartTime
end

function ArenaTowerData.GetActionBarSkillInfo()
    if not self.tBattleInfo then
        return
    end
    return self.tBattleInfo.tActionBarSkillInfo
end

function ArenaTowerData.CheckShowNextNewCardList()
    if not self.tBattleInfo or not self.tBattleInfo.tNewCardListQueue or #self.tBattleInfo.tNewCardListQueue <= 0 then
        return
    end

    for _, nViewID in ipairs(tNewCardWaitViewIDs or {}) do
        if UIMgr.IsViewOpened(nViewID) then
            return
        end
    end

    local tNewCardList = self.tBattleInfo.tNewCardListQueue[1]
    table.remove(self.tBattleInfo.tNewCardListQueue, 1)
    UIMgr.Open(VIEW_ID.PanelBlessConfirm, tNewCardList)
end

function ArenaTowerData.OpenTransitionView(nDiffMode, nLevelIndex)
    DebugLog("ArenaTower On_ArenaTower_TransScreen %s %s" , tostring(nDiffMode), tostring(nLevelIndex))
    local tLevelConfig = self.GetLevelConfig(nLevelIndex)
    if not tLevelConfig then
        return
    end

    local szNextLevel
    local szLevelName = UIHelper.GBKToUTF8(tLevelConfig.szName)
    if nLevelIndex > 0 then
        if nDiffMode == ArenaTowerDiffMode.Practice then
            szNextLevel = string.format("正在前往\n普通模式 - 第 %s 关 - %s", tostring(nLevelIndex), szLevelName)
        elseif nDiffMode == ArenaTowerDiffMode.Challenge then
            szNextLevel = string.format("正在前往\n挑战模式 - 第 %s 关 - %s", tostring(nLevelIndex), szLevelName)
        else
            szNextLevel = string.format("正在前往\n第 %s 关 - %s", tostring(nLevelIndex), szLevelName)
        end
    else
        szNextLevel = string.format("正在前往\n%s", szLevelName)
    end

    local tInfo = {szText = szNextLevel, szContent = nil, szAnimName = "AniForwardShow"}
    UIMgr.Open(VIEW_ID.PanelInterlude, nil, tInfo)
end

function ArenaTowerData.IsRobotByName(szPlayerName)
    if TeamData.IsInParty() then
        local bIsRobot = true
        TeamData.Generator(function(dwID, tMemberInfo)
            if tMemberInfo.szName == szPlayerName then
                bIsRobot = false
                return
            end
        end)
        return bIsRobot
    elseif RoomData.IsHaveRoom() then
        local hRoom = GetGlobalRoomClient()
        local tRoomInfo = hRoom and hRoom.GetGlobalRoomInfo()
        local nMemberCount = 0
        for _, tMemberInfo in pairs(tRoomInfo or {}) do
            if tMemberInfo.szName == szPlayerName then
                return false
            end
        end
    else
        return false
    end

    return true

    -- if not self.IsInArenaTowerMap() then
    --     return false
    -- end

    -- local player = GetClientPlayer()
    -- if not player then
    --     return false
    -- end

    -- local hTeam = GetClientTeam()
    -- if not hTeam then
    --     return false
    -- end

    -- local nGroupID = hTeam.GetMemberGroupIndex(player.dwID)
    -- local tGroupInfo = hTeam.GetGroupInfo(nGroupID)
    -- local tMemberList = tGroupInfo and tGroupInfo.MemberList
    -- for _, dwMemberID in pairs(tMemberList or {}) do
    --     local tMemberInfo = hTeam.GetMemberInfo(dwMemberID)
    --     if tMemberInfo.szName == szPlayerName then
    --         return false
    --     end
    -- end

    -- return true
end

function ArenaTowerData.ClearData()
    -- 准备开始新的一回合 清理缓存的结算数据
    BattleFieldData._initBattleFieldInfo(BATTLE_FIELD_MAP_ID.QING_XIAO_SHAN)
    self.tBattleInfo.tBattlePlayerData = nil
    self.tBattleInfo.nBattleStartTime = nil
    self.tBattleInfo.nBattleEndTime = nil
end

function ArenaTowerData.OnUpdateRoundState()
    if not self.tBattleInfo then
        return
    end

    local nBattleState, _ = self.GetBattleStateInfo()
    local nLastBattleState = self.tBattleInfo.nBattleState
    if nLastBattleState ~= nBattleState then
        local nDiffMode, nLevelProgress, _, _ = self.GetBaseInfo()
        Log("[ArenaTower] OnUpdateRoundState nBattleState: %s, nLevelProgress: %s", tostring(nBattleState), tostring(nLevelProgress))
        if nBattleState == ArenaTowerBattleState.Rest then
            Event.Dispatch(EventType.OnArenaTowerUpdateLevelInfo)
            if not nLastBattleState then
                self.bArenaTowerViewFold = self.CanChooseBless() -- 初始化准备面板打开状态
            end
        elseif nBattleState == ArenaTowerBattleState.Matching then
            self.tBattleInfo.nMatchStartTime = GetCurrentTime()
            -- OnUpdateRoundState要等ApplyBattleFieldStatistics返回，可能会导致Matching阶段被跳过
            -- 清理数据逻辑放在On_ArenaTower_UpdateRoundState回调后
        elseif nBattleState == ArenaTowerBattleState.Prepare then
            self.bArenaTowerViewFold = true
        elseif nBattleState == ArenaTowerBattleState.Battle then
            self.bArenaTowerViewFold = true
            -- 进战切到队伍
            Event.Dispatch(EventType.OnSelectedTaskTeamViewToggle, true)
        elseif nBattleState == ArenaTowerBattleState.Settle then
            self.bArenaTowerViewFold = true
            self.tBattleInfo.nBattleEndTime = GetGSCurrentTime()
            -- 结算切回元素点（强制刷新）
            Event.Dispatch(EventType.OnTogArenaTowerElementInfo, false)
            Event.Dispatch(EventType.OnTogArenaTowerElementInfo, true)
        end
    end

    self.tBattleInfo.nBattleState = nBattleState
    Event.Dispatch(EventType.OnArenaTowerUpdateRoundState)
end

function ArenaTowerData.OnCardEvent(szEvent, nCardID, ...)
    -- local tParams = {...}
    if szEvent == "Fire" then
        -- local nLeftBurnRound = tParams[1] -- 剩余回合数
        -- local bEnhanced = tParams[2] == 1 -- 强化状态
        UIMgr.Open(VIEW_ID.PanelYangDaoMainCityCardShow, BlessCardAniEvent.OnFire, nCardID)
    elseif szEvent == "Ashes" then
        -- local bEnhanced = tParams[1] == 1 -- 强化状态
        UIMgr.Open(VIEW_ID.PanelYangDaoMainCityCardShow, BlessCardAniEvent.OnAsh, nCardID)
    elseif szEvent == "Revive" then
        -- local bEnhanced = tParams[1] == 1 -- 强化状态
        UIMgr.Open(VIEW_ID.PanelYangDaoMainCityCardShow, BlessCardAniEvent.OnRevive, nCardID)
    elseif szEvent == "Grow" then
        -- local nOverflowGrowWoodPoint = tParams[1] -- 溢出生机点
        self.OnGetNewCard({{nCardID, 0, 0, 0}}, true)
        -- TODO 萌芽图标动画事件
    end
end

function ArenaTowerData.OnGetNewCard(tCardList, bGrowWood)
    if not self.tBattleInfo then
        return
    end

    -- {{新增卡牌ID, 燃烧状态, 燃烧剩余回合数, 强化状态}, {},...})
    if not tCardList or #tCardList <= 0 then
        return
    end

    local tBlessCardList = {}
    for _, tCard in ipairs(tCardList) do
        local tCardData = self.GetBaseCardDataByCardID(tCard[1])
        if tCardData then
            tCardData.nState = tCard[2] -- 与BlessCardState对应
            tCardData.nLeftBurnRound = tCard[3]
            tCardData.bEnhanced = tCard[4] == 1
            -- tCardData.nCustomValue = tCard[5]
            tCardData.nAniEvent = bGrowWood and BlessCardAniEvent.OnGrowWood or BlessCardAniEvent.OnGetCard
            self.UpdateCardDataSkillInfo(tCardData)
            table.insert(tBlessCardList, tCardData)
        end
    end

    self.tBattleInfo.tNewCardListQueue = self.tBattleInfo.tNewCardListQueue or {}
    table.insert(self.tBattleInfo.tNewCardListQueue, tBlessCardList)

    Timer.DelTimer(self, self.nNewCardTimerID)
    if bGrowWood then
        self.nNewCardTimerID = Timer.Add(self, 0.5, function()
            self.CheckShowNextNewCardList()
        end)
    else
        self.CheckShowNextNewCardList()
    end
end