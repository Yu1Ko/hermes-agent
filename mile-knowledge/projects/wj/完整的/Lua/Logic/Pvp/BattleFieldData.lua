BattleFieldData = BattleFieldData or {className = "BattleFieldData"}
local self = BattleFieldData

BattleFieldData.MAX_BATTLE_FIELD_SIDE_COUNT = 4
BattleFieldData.OB_BATTLE_FIELD_SIDE = 2

BattleFieldData.NEW_PLAYER_BF_MAP_ID = 293 --拭剑园战场

local m_nNowCamera_ID = nil
local MATCH_CD        = 1000


---@class BattleFieldInfo 战场数据
---@field bBattleFieldEnd boolean 是否已结束
---@field tStatistics table<number, BattleFieldStatistics> 玩家ID => 战场统计数据
---@field nClientPlayerSide number 玩家的局内阵营
---@field nRewardMoney number 奖励金钱
---@field nRewardExp number 奖励经验
---@field bUpdateRecord boolean 是否刷新了记录
---@field bWin boolean 是否胜利
---
---@field nBanishTime number 自动传出战场的时间
---
---@field tExcellentData table<number, number> 玩家ID => 优秀表现ID（EXCELLENT_ID）
---@field tPraiseList table<number, number> 玩家ID => 是否可以点赞，>0表示可以点赞
---@field tAddPraiseList table<number, number> 玩家ID => 点赞次数，>0表示已点赞
---@field tNewRoleData table 战场角色数据
---@field dwMapID number 战场的地图ID
---
---@field dwLeaderID number 团长ID
---@field bBattleFieldStart boolean 是否已开始（吃鸡）
---@field bOpenWinOrDefect boolean 是否需要打开胜利/失败界面
---@field tMyData BattleFieldStatistics 当前玩家的战场统计数据
---@field szPlayerCount string 玩家数目


---@class BattleFieldStatistics 战场统计数据
---@field Name string 玩家名称
---@field ForceID number 玩家门派
---@field BattleFieldSide number 局内阵营（0-3）
---@field ClientVersionType number 玩家客户端类型
---@field GlobalID string 玩家全局ID
---@field PQ_STATISTICS_INDEX_0_24 number 这个类可以通过0-24为索引获取对应的统计数据，如 tData[0]，这个假装的字段只是用来说明
---
---@field dwPlayerID number 玩家ID
---@field nBattleFieldSide number 局内阵营（1-4）


---@type BattleFieldInfo
local tBattleFieldInfo = {}
local tBFRoleData = {}
---@type string[] 当前地图的战场中不同阵营（1-4）的名称
local tGroupInfo = {}
local tExcellentInfo = {}
local tBattleFieldRecordInfo = {}

local tDelay = {}
local tPlayerKungfuID = {}

local m_tSubMapID = {}
local m_nMatchTime = nil

local m_nMobaOpenTime = nil
local m_nMobaGameTime = 0

function BattleFieldData.Init()
    self.RegEvent()
    RemoteFunction.RegisterUIGlobalFunction("OpenNewcomerBF", self.OnNewPlayerBFEnd)
end

function BattleFieldData.UnInit()
    Event.UnRegAll(self)
    Timer.DelAllTimer(self)
    RemoteFunction.UnRegisterUIGlobalFunction("OpenNewcomerBF")
end

function BattleFieldData.RegEvent()
    Event.Reg(self, "FIRST_LOADING_END", function()
        RemoteCallToServer("On_Zhanchang_GetTodayZhanchang") --获取今日战场，返回GET_TODAY_ZHANCHANG_RESPOND
    end)
    Event.Reg(self, "LOADING_END", function()
        if self.IsInBattleField() then
            local dwMapID = MapHelper.GetMapID()
            self._initBattleFieldInfo(dwMapID)
            self._initBattleFieldRule(dwMapID)
            self._initExcellentInfo()
            m_nMatchTime = nil

            if not BahuangData.IsInBaHuangMap() and not ArenaTowerData.IsInArenaTowerMap() then --八荒/扬刀大会不切队伍
                Event.Dispatch(EventType.OnSelectedTaskTeamViewToggle, true)
            end
        end

        if self.IsInMobaBattleFieldMap() then
            RemoteCallToServer("On_Moba_GetOpenTime")

            -- 开局时上传预购信息，用于推荐出装
            LieXingXuJingData.InitPrePurchase(true)
            local tPlans = LieXingXuJingData.GetPrePurchase()
            RemoteCallToServer("On_Moba_EquipShopPlanSet",
                               tPlans.nEquipmentLocalID1,
                               tPlans.nEquipmentLocalID2,
                               tPlans.nEquipmentLocalID3,
                               tPlans.nEquipmentLocalID4,
                               tPlans.nEquipmentLocalID5,
                               tPlans.nEquipmentLocalID6
            )

            --- moba禁用焦点功能
            if JX_TargetList.IsShow() then
                JX_TargetList.SetVisible(false)
                Event.Dispatch(EventType.SwitchFocusVisibility, true)
            end
        end
    end)

    --若在战场中收到了切换场景的事件，则将进度条停止
    Event.Reg(self, "SCENE_BEGIN_LOAD", function(dwMapID, szPath)
        if MapHelper.IsInBattleField(tBattleFieldInfo.dwMapID) then
            TipsHelper.StopProgressBar()
        end
    end)

    Event.Reg(self, "Update_FriendPraiseList", function(nType, tList)
        self.Log("Update_FriendPraiseList", nType, tList)
        if nType ~= PRAISE_TYPE.BATTLE_FIELD then
            return
        end
        self.OnUpdatePraiseList(tList)
    end)

    Event.Reg(self, "Add_FriendPraiseShow", function (nType, dwPlayerID)
        self.Log("Add_FriendPraiseShow", nType, dwPlayerID)
        if nType ~= PRAISE_TYPE.BATTLE_FIELD then
            return
        end
        self.OnAddPraise(dwPlayerID)
    end)

    Event.Reg(self, "On_Get_BF_Leader", function(dwLeaderID)
        self.Log("On_Get_BF_Leader", dwLeaderID)
        tBattleFieldInfo.dwLeaderID = dwLeaderID
    end)

    Event.Reg(self, "On_Get_BF_Result", function(bWin)
        self.Log("On_Get_BF_Result", bWin)
        tBattleFieldInfo.bWin = bWin
    end)

    Event.Reg(self, "BATTLE_FIELD_END", function()
        self.Log("BATTLE_FIELD_END")
        self.OnBattleFieldEnd()
    end)

    Event.Reg(self, "BATTLE_FIELD_SYNC_STATISTICS", function()
        self.Log("BATTLE_FIELD_SYNC_STATISTICS")
        self.OnSyncStatistics()
    end)

    Event.Reg(self, "SYS_MSG", function(szMsg, nBanishCode, nBanishTime)
        if szMsg == "UI_OME_BANISH_PLAYER" then
            if not self.IsInBattleField() then
                return
            end

            self.Log("SYS_MSG", nBanishCode, nBanishTime)
            if nBanishCode == BANISH_CODE.MAP_REFRESH or nBanishCode == BANISH_CODE.NOT_IN_MAP_OWNER_PARTY then
                tBattleFieldInfo.nBanishTime = GetCurrentTime() + nBanishTime
            elseif nBanishCode == BANISH_CODE.CANCEL_BANISH then
                tBattleFieldInfo.nBanishTime = nil
            end
        end
    end)

    Event.Reg(self,"TREASURE_BATTLE_FIELD_END", function ()
        local bTreasureBattle = self.IsInTreasureBattleFieldMap()
        if not bTreasureBattle then
            return
        end
        local hPlayer = GetClientPlayer()
        if not hPlayer or hPlayer.nBattleFieldSide == BattleFieldData.OB_BATTLE_FIELD_SIDE then --OB不弹结算
            return
        end
        local tInfo = arg0
        local nBanishTime = (tInfo.nLeaveTime - GetCurrentTime()) * 1000 + GetTickCount()
        local nTeamCount = tInfo.nTeamCount
        tBattleFieldInfo.bBattleFieldEnd = true

        UIMgr.Close(VIEW_ID.PanelBattleFieldRulesLittle)
        if not UIMgr.GetView(VIEW_ID.PanelBattlePersonalCardSettle) then
            ApplyBattleFieldStatistics()
            PSMMgr.ExitPSMMode()
            UIMgr.Open(VIEW_ID.PanelBattlePersonalCardSettle, nil, nil, nBanishTime, function ()
                if not UIMgr.GetView(VIEW_ID.PanelEndSettlement) then
                    UIMgr.Open(VIEW_ID.PanelEndSettlement, nBanishTime, nTeamCount, nil, function ()
                        local scriptView = UIMgr.Open(VIEW_ID.PanelBattlePersonalCardSettle, nil, nil, nBanishTime, function ()
                            UIMgr.Close(VIEW_ID.PanelBattlePersonalCardSettle)
                        end, true)
                        scriptView:UpdateTreasureBattleFieldInfo()
                    end)
                end
            end, true)
        end
    end)

    Event.Reg(self,"TREASURE_BATTLE_FIELD_START", function ()
        tBattleFieldInfo.bBattleFieldStart = true
        BattleFieldData.ApplyTreasureBFTeamMemberCard()
    end)

    Event.Reg(self, "TREASURE_HUNT_BATTLE_FIELD_END", function ()
        local hPlayer = GetClientPlayer()
        if not hPlayer or hPlayer.nBattleFieldSide == BattleFieldData.OB_BATTLE_FIELD_SIDE then --OB不弹结算
            return
        end
        local tInfo = arg0
        tInfo.nBanishTime = (tInfo.nLeaveTime - GetCurrentTime()) * 1000 + GetTickCount()
        tBattleFieldInfo.bBattleFieldEnd = true
        Event.Dispatch(EventType.ShowExtractSettlement, tInfo)
    end)

    Event.Reg(self, "ON_SYNC_BF_ROLE_DATA", function(dwPlayerID, dwMapID, bUpdate, eType)
        self.OnGetBFRoleData(dwPlayerID, dwMapID, bUpdate, eType)
    end)

    Event.Reg(self, "UPDATE_DSWANDERNUMBER", function(dwRemainNumber, dwProcessNumber)
        BattleFieldData.dwFeishaRemainNum = dwRemainNumber
        BattleFieldData.dwFeishaProcessNum = dwProcessNumber
        FireUIEvent("UPDATE_FEISHAWAND")
    end)

    Event.Reg(self, "GET_TODAY_ZHANCHANG_RESPOND", function(tBattleOpen)
        for dwMapID, bOpen in pairs(tBattleOpen) do
            if bOpen then
                self.nTodayBattleFieldMapID = dwMapID
                return
            end
        end
    end)

    Event.Reg(self, "PLAYER_ENTER_SCENE", function(dwPlayerID)
        if not self.IsInBattleField() then
            return
        end
        tDelay[dwPlayerID] = nil
        self.OnPlayerEnterScene(dwPlayerID)
    end)
end

function BattleFieldData.ApplyTreasureBFTeamMemberCard()
    local hTeam = GetClientTeam()
    if not hTeam then
        return
    end

    local tMembers = {}
    hTeam.GetTeamMemberList(tMembers)
    local tGlobal = {}
    for k, dwID in ipairs(tMembers) do
        local pPlayer = GetPlayer(dwID)
        local dwGlobalID = pPlayer and pPlayer.GetGlobalID()
        if dwGlobalID then
            table.insert(tGlobal, dwGlobalID)
        end
    end
    PersonalCardData.ApplyTableShowCardData(tGlobal)
end

function BattleFieldData.CheckEnterNewPlayerBF()

    if g_pClientPlayer.nLevel < 108 then
        TipsHelper.ShowNormalTip("侠士达到108级后方可参与历程战场")
        return
    end

    -- 地图资源下载检测拦截
    if not PakDownloadMgr.UserCheckDownloadMapRes(self.NEW_PLAYER_BF_MAP_ID, nil, nil, true) then
        return
    end

    UIHelper.ShowConfirm("是否前往拭剑战场？", function()
        RemoteCallToServer("On_JJC_NewerRobotFight")
        UIMgr.Close(VIEW_ID.PanelRoadCollection)
        UIMgr.Close(VIEW_ID.PanelSystemMenu)
    end)
end

--拭剑园战场结束
function BattleFieldData.OnNewPlayerBFEnd(tStatistics, nBanishTime, tExcellentData, bWin)
    self.Log("OnNewPlayerBFEnd", nBanishTime, bWin)
    -- LOG.TABLE(tStatistics)
    -- LOG.TABLE(tExcellentData)

    local player = GetClientPlayer()
    if not player then
        return
    end

    UIMgr.Close(VIEW_ID.PanelMiddleMap)

    local dwMapID = MapHelper.GetMapID()
    self._initBattleFieldInfo(dwMapID)

    tBattleFieldInfo.bBattleFieldEnd = true
    tBattleFieldInfo.bWin            = bWin
    tBattleFieldInfo.nBanishTime = nBanishTime
    tBattleFieldInfo.tExcellentData = {}
    tBattleFieldInfo.tExcellentData[player.dwID] = tExcellentData

    self._dealwithStatisticsData(tStatistics)

    --右上角倒计时
    self.SetRightTopCountDown(nBanishTime)

    --打开胜利失败界面
    UIMgr.Open(VIEW_ID.PanelPvPSettlement, tBattleFieldInfo.bWin, function()
        UIMgr.Open(VIEW_ID.PanelPVPTopOne, tBattleFieldInfo.tExcellentData[player.dwID], tBattleFieldInfo.nBanishTime)
    end)
end

function BattleFieldData.OnBattleFieldEnd()
    UIMgr.Close(VIEW_ID.PanelMiddleMap)
    UIMgr.Close(VIEW_ID.PanelPvPSettlement)
    UIMgr.Close(VIEW_ID.PanelPVPTopOne)
    UIMgr.Close(VIEW_ID.PanelBattlePersonalCardSettle)
    UIMgr.Close(VIEW_ID.PanelBattleMvpSettle)
    UIMgr.Close(VIEW_ID.PanelPVPFieldSettleData)
    UIMgr.Close(VIEW_ID.PanelLieXingData)
    UIMgr.Close(VIEW_ID.PanelChampionshipSettleData)
    UIMgr.Close(VIEW_ID.PanelYangDaoSettlement)
    UIMgr.Close(VIEW_ID.PanelYangDaoSettleData)

    if BattleFieldData.IsInMobaBattleFieldMap() then
        RemoteCallToServer("On_Moba_GetEquip")
        m_nMobaGameTime = GetCurrentTime() - m_nMobaOpenTime
    end

    tBattleFieldInfo.bBattleFieldEnd = true

    tBattleFieldInfo.bOpenWinOrDefect = true
    ApplyBattleFieldStatistics() --返回BATTLE_FIELD_SYNC_STATISTICS

    RemoteCallToServer("On_Zhanchang_GetLeader") --返回On_Get_BF_Leader
end

function BattleFieldData.OnSyncStatistics()
    local player = GetClientPlayer()
    if not player then
        return
    end

    local bTreasureBattle = self.IsInTreasureBattleFieldMap()
    if bTreasureBattle then
        return
    end

    if self.IsInZombieBattleFieldMap() then
        local tStatistics = GetBattleFieldStatistics()
        local tPlayerStat = tStatistics[g_pClientPlayer.dwID]

        UIMgr.Open(VIEW_ID.PanelZombieSettleData, tPlayerStat)
        return
    end

    if not (
            tBattleFieldInfo.bBattleFieldEnd or
                    UIMgr.IsViewOpened(VIEW_ID.PanelPVPFieldSettleData) or
                    UIMgr.IsViewOpened(VIEW_ID.PanelLieXingData) or
                    UIMgr.IsViewOpened(VIEW_ID.PanelChampionshipSettleData) or
                    UIMgr.IsViewOpened(VIEW_ID.PanelBattleFieldXunBaoSettlement)
    ) then --只有结算界面打开或者结束的时候需要处理这个数据
        return
    end

    local bArenaTower = ArenaTowerData.IsInArenaTowerMap()
    if bArenaTower then
        -- 避免被回到休息状态后清空的数据覆盖
        if UIMgr.IsViewOpened(VIEW_ID.PanelYangDaoSettlement) or
           UIMgr.IsViewOpened(VIEW_ID.PanelYangDaoSettleData) or 
           UIMgr.IsViewOpened(VIEW_ID.PanelBattlePersonalCardSettle)
         then
            return
        end
    end

    local tStatistics = GetBattleFieldStatistics()
    if not tStatistics then
        return
    end

    tBattleFieldInfo.tStatistics = {} --处在CD中就使用保存的数据
    self._dealwithStatisticsData(tStatistics)

    if tBattleFieldInfo.bBattleFieldEnd then
        self._getMapExcellentInfo()
        for k, v in pairs(tBattleFieldInfo.tStatistics) do
            local dwPlayerID = v.dwPlayerID
            if dwPlayerID then
                local nCount = 0
                if tBattleFieldInfo.tExcellentData[dwPlayerID] then
                    nCount = #tBattleFieldInfo.tExcellentData[dwPlayerID]
                end
                v.nExcellentCount = nCount
            end
        end

        local tList = {}
        for k, v in pairs(tBattleFieldInfo.tStatistics) do
            table.insert(tList, v.dwPlayerID)
        end
        RemoteCallToServer("On_FriendPraise_PraiseList", PRAISE_TYPE.BATTLE_FIELD, tList) --返回Update_FriendPraiseList
    end

    local nSettleViewID = self.GetSettleViewID()
    local uiView = UIMgr.GetView(nSettleViewID)
    local scriptView = uiView and uiView.scriptView
    if not scriptView and tBattleFieldInfo.bBattleFieldEnd and tBattleFieldInfo.bOpenWinOrDefect then
        PSMMgr.ExitPSMMode()

        tBattleFieldInfo.bOpenWinOrDefect = false
        self.SetRightTopCountDown(tBattleFieldInfo.nBanishTime) --右上角倒计时

        if self.IsInTongWarFieldMap() or self.IsInFBBattleFieldMap() then
            UIMgr.Open(VIEW_ID.PanelPvPSettlement, tBattleFieldInfo.bWin, function()
                self.OpenBattleFieldSettle()
            end)
            return
        end

        -- print_table("[BattleField] tBattleFieldInfo", tBattleFieldInfo)

        --预加载，提前拉取名片
        local nTimerID = Timer.AddFrame(self, 5, function()
            local scriptCard = UIMgr.Open(VIEW_ID.PanelBattlePersonalCardSettle, tBattleFieldInfo.tExcellentData, tBattleFieldInfo.nClientPlayerSide, tBattleFieldInfo.nBanishTime)
            scriptCard:SetVisible(false)
        end)

        local function fnCallback()
            -- if not tBattleFieldInfo.tExcellentData[player.dwID] or IsTableEmpty(tBattleFieldInfo.tExcellentData[player.dwID]) then
            --     self.OpenBattleFieldSettle()
            -- else
            --     UIMgr.Open(VIEW_ID.PanelPVPTopOne, tBattleFieldInfo.tExcellentData[player.dwID], tBattleFieldInfo.nBanishTime)
            -- end

            Timer.DelTimer(self, nTimerID)
            local scriptCard = UIMgr.GetViewScript(VIEW_ID.PanelBattlePersonalCardSettle)
            if scriptCard then
                scriptCard:SetVisible(true)
            else
                UIMgr.Open(VIEW_ID.PanelBattlePersonalCardSettle, tBattleFieldInfo.tExcellentData, tBattleFieldInfo.nClientPlayerSide, tBattleFieldInfo.nBanishTime)
            end
        end

        if bArenaTower then
            local nResult
            if tBattleFieldInfo.bWin then
                nResult = ArenaTowerSettleResult.Victory
            else
                local tData = tStatistics[player.dwID]
                local bLevelDown = tData and (tData[PQ_STATISTICS_INDEX.SPECIAL_OP_7] == 1)
                nResult = bLevelDown and ArenaTowerSettleResult.DefeatAndLevelDown or ArenaTowerSettleResult.Defeat
            end
            UIMgr.Open(VIEW_ID.PanelYangDaoSettlement, nResult, fnCallback)
            return
        end

        --打开胜利失败界面
        UIMgr.Open(VIEW_ID.PanelPvPSettlement, tBattleFieldInfo.bWin, fnCallback)
    elseif scriptView and scriptView.Update then
        ---@see UIPVPFieldSettleDataView#Update
        ---@see UIChampionshipSettleDataView#Update
        scriptView:Update(tBattleFieldInfo)
    end
end

function BattleFieldData.GetSettleViewID()
    local nViewID = VIEW_ID.PanelPVPFieldSettleData
    if self.IsInTongWarFieldMap() then
        --- 帮会联赛使用单独的结算界面
        nViewID = VIEW_ID.PanelChampionshipSettleData
    elseif ArenaTowerData.IsInArenaTowerMap() then
        nViewID = VIEW_ID.PanelYangDaoSettleData
    end

    return nViewID
end

function BattleFieldData.SetRightTopCountDown(nBanishTime)
    --右上角倒计时
    local mainCityView = UIMgr.GetView(VIEW_ID.PanelMainCity)
    local widgetPvpRightTop = mainCityView.scriptView.scriptPvpRightTop

    if widgetPvpRightTop then
        widgetPvpRightTop:SetCountDown(nBanishTime)
    end
end

function BattleFieldData.OnUpdatePraiseList(tList)
    local player = GetClientPlayer()
    if not player then
        return
    end

    for k, v in pairs(tList) do
        if v ~= player.dwID then
            tBattleFieldInfo.tPraiseList[v] = 1
        end
    end
end

function BattleFieldData.OpenBattleFieldSettle(bApply)
    if bApply then
        tBattleFieldInfo.bOpenWinOrDefect = false
        ApplyBattleFieldStatistics() --返回BATTLE_FIELD_SYNC_STATISTICS
    end

    if not tGroupInfo or IsTableEmpty(tGroupInfo) or tBattleFieldInfo.dwMapID ~= tGroupInfo.dwMapID then
        tGroupInfo = Table_GetBattleFieldGroupInfo(tBattleFieldInfo.dwMapID)
        if tGroupInfo then
            tGroupInfo.dwMapID = tBattleFieldInfo.dwMapID
        end
    end

    local nBFMapType = MapHelper.GetBattleFieldType()
    local bMoba = nBFMapType == BATTLEFIELD_MAP_TYPE.MOBABATTLE
    local bArenaTower = nBFMapType == BATTLEFIELD_MAP_TYPE.ARENA_TOWER
    if bMoba then
        -- moba玩法使用单独的结算界面流程，特殊处理下
        if BattleFieldData.BattleField_IsEnd() then
            UIMgr.Open(VIEW_ID.PanelLieXingSettle)
        else
            UIMgr.Open(VIEW_ID.PanelLieXingData)
        end
    elseif bArenaTower then
        UIMgr.Close(VIEW_ID.PanelBattlePersonalCardSettle)
        UIMgr.Open(VIEW_ID.PanelYangDaoSettleData, tBattleFieldInfo, function()
            UIMgr.Open(VIEW_ID.PanelBattlePersonalCardSettle, tBattleFieldInfo.tExcellentData, tBattleFieldInfo.nClientPlayerSide, tBattleFieldInfo.nBanishTime, function()
                UIMgr.Close(VIEW_ID.PanelBattlePersonalCardSettle)
            end)
        end)
    else
        --- todo: dx的帮会联赛有个判断申请数据cd的流程，后面看看是否需要加上 IsInTongLeagueApplyPQCDID
        local nSettleViewID = self.GetSettleViewID()
        UIMgr.Open(nSettleViewID, tBattleFieldInfo.bBattleFieldEnd, tBattleFieldInfo, tGroupInfo)
    end
end

function BattleFieldData.LeaveBattleField()
    UIMgr.Close(VIEW_ID.PanelPVPTopOne)
    UIMgr.Close(VIEW_ID.PanelBattlePersonalCardSettle)
    UIMgr.Close(VIEW_ID.PanelPVPFieldSettleData)
    UIMgr.Close(VIEW_ID.PanelBattleMvpSettle)
    UIMgr.Close(VIEW_ID.PanelLieXingSettle)
    UIMgr.Close(VIEW_ID.PanelChampionshipSettleData)
    UIMgr.Close(VIEW_ID.PanelBattleFieldXunBaoSettlement)
    UIMgr.Close(VIEW_ID.PanelYangDaoSettlement)
    UIMgr.Close(VIEW_ID.PanelYangDaoSettleData)

    local nBFType = MapHelper.GetBattleFieldType()
    if nBFType == BATTLEFIELD_MAP_TYPE.NEWCOMERBATTLE then
        RemoteCallToServer("On_Zhanchang_NewBeeKickOut") --离开新手战场
    elseif nBFType == BATTLEFIELD_MAP_TYPE.TONGBATTLE then
        LeaveTongBattleField()
    else
        LeaveBattleField()
    end
end

function BattleFieldData.OpenMyRecord()
    UIMgr.Open(VIEW_ID.PanelBattleMvpSettle, tBattleFieldInfo.tMyData, tBFRoleData[tBattleFieldInfo.dwMapID], tBattleFieldInfo.nBanishTime)
end

-------------------------------- Private --------------------------------

function BattleFieldData._initBattleFieldRule(dwMapID)
    if not Storage.BattleField.tbEnterState[dwMapID] then
        if not BahuangData.IsInBaHuangMap() then--八荒不显示此面板
            UIMgr.Open(VIEW_ID.PanelBattleFieldRulesLittle, dwMapID)
        else
            -- UIMgr.Open(VIEW_ID.PanelBahuangRulesLittle)
            TeachBoxData.OpenTutorialPanel(63, 64, 65)
        end
        Storage.BattleField.tbEnterState[dwMapID] = true
        Storage.BattleField.Dirty()
    end
end

function BattleFieldData._initBattleFieldInfo(dwMapID)
    tBattleFieldInfo = {
        bBattleFieldEnd = false,
        tStatistics = {},
        nClientPlayerSide = nil,
        nTongScore = 0,
		nTongCurrency = 0,
        nRewardMoney = 0,
        nRewardExp = 0,
        bUpdateRecord = false,
        bWin = false,

        tExcellentData = {},
        tPraiseList = {},
        tAddPraiseList = {},
        tNewRoleData = nil,
        dwMapID = dwMapID,
    }
end

function BattleFieldData.OnPlayerEnterScene(dwPlayerID)
    local hPlayer = GetPlayer(dwPlayerID)
    local bSuccess = false
    if not hPlayer then
        return
    end
    if hPlayer.GetKungfuMountID() then
        tPlayerKungfuID[dwPlayerID] = hPlayer.GetKungfuMountID()
        bSuccess = true
    end
    if not bSuccess then
        local nNowTime = GetTickCount()
        if not tDelay[dwPlayerID] then
            tDelay[dwPlayerID] = nNowTime
        end
        if nNowTime - tDelay[dwPlayerID] > 1000 * 60 then
            tDelay[dwPlayerID] = nil
            return
        end
        Timer.Add(self, 0.5, function() self.OnPlayerEnterScene(dwPlayerID) end)
    end
end

function BattleFieldData.GetPlayerKungfuID(dwPlayerID)
    if not tPlayerKungfuID[dwPlayerID] then
        local hPlayer = GetPlayer(dwPlayerID)
        if hPlayer then
            tPlayerKungfuID[dwPlayerID] = hPlayer.GetKungfuMountID()
        end
    end

    return tPlayerKungfuID[dwPlayerID] or 0
end

function BattleFieldData._dealwithStatisticsData(tStatistics)
    local tSideTable = {}
    tBattleFieldInfo.tStatistics = {}
    local hPlayer          = GetClientPlayer()
    local bTongBattleField = self.IsInTongWarFieldMap()
    local bArenaTower = ArenaTowerData.IsInArenaTowerMap()
    for dwPlayerID, tData in pairs(tStatistics) do
        local bTongBattleFieldGM = bTongBattleField and tData[PQ_STATISTICS_INDEX.SPECIAL_OP_1] == 3
        local player = (hPlayer.dwID == dwPlayerID) and hPlayer or PlayerData.GetPlayer(dwPlayerID)
        if tData.Name and tData.BattleFieldSide >= 0  then
            tData.dwPlayerID = dwPlayerID
            tData.dwMountKungfuID = self.GetPlayerKungfuID(dwPlayerID)
            tData.nBattleFieldSide = tData.BattleFieldSide + 1
            if not bTongBattleFieldGM then
                table.insert(tBattleFieldInfo.tStatistics, tData)
            end

            if tData.nBattleFieldSide then
                if tSideTable[tData.nBattleFieldSide] then
                    tSideTable[tData.nBattleFieldSide] = tSideTable[tData.nBattleFieldSide] + 1
                else
                    tSideTable[tData.nBattleFieldSide] = 1
                end

                if tSideTable[0] then
                    tSideTable[0] = tSideTable[0] + 1
                else
                    tSideTable[0] = 1
                end
            end

            if hPlayer.dwID == dwPlayerID then
                tBattleFieldInfo.nClientPlayerSide = tData.nBattleFieldSide
                if bTongBattleField then
                    tBattleFieldInfo.nTongScore    = tData[PQ_STATISTICS_INDEX.SPECIAL_OP_5]  -- 帮会排行榜积分
                    tBattleFieldInfo.nTongCurrency = tData[PQ_STATISTICS_INDEX.AWARD_MONEY]   -- 帮会代币
				end
                tBattleFieldInfo.nRewardMoney = tData[PQ_STATISTICS_INDEX.AWARD_MONEY]
                tBattleFieldInfo.nRewardExp = tData[PQ_STATISTICS_INDEX.AWARD_EXP]
                tBattleFieldInfo.tMyData = tData
            end

            -- 扬刀大会特殊处理，机器人名字强制显示为武意残影
            if bArenaTower and tData.BattleFieldSide ~= (hPlayer and hPlayer.nBattleFieldSide or 0) then
                tData.Name = UIHelper.UTF8ToGBK(g_tStrings.ARENA_TOWER_ROBOT_NAME)
            end
        end
    end

    if not tGroupInfo or IsTableEmpty(tGroupInfo) or tBattleFieldInfo.dwMapID ~= tBattleFieldInfo.dwMapID then
        tGroupInfo = Table_GetBattleFieldGroupInfo(tBattleFieldInfo.dwMapID)
        tGroupInfo.dwMapID = tBattleFieldInfo.dwMapID
    end

    local szPlayerCount = nil
    for i = 1, self.MAX_BATTLE_FIELD_SIDE_COUNT do
        if tGroupInfo[i] and tSideTable[i] then
            if not szPlayerCount then
                szPlayerCount = g_tStrings.STR_BATTLEFIELD_PLAYER_COUNT .. "  "
            else
                szPlayerCount = szPlayerCount .. "  /  "
            end
            szPlayerCount = szPlayerCount .. tGroupInfo[i] .. " " .. tSideTable[i]
        end
    end
    if szPlayerCount then
        tBattleFieldInfo.szPlayerCount = szPlayerCount
    end
end

--优秀表现
function BattleFieldData._getMapExcellentInfo()
    if not tBattleFieldInfo.dwMapID then
        return
    end

    if not tExcellentInfo or IsTableEmpty(tExcellentInfo)  then
        self._initExcellentInfo()
    end

    local tInfo = tExcellentInfo[tBattleFieldInfo.dwMapID]
    for k, v in ipairs(tInfo) do
        local tFirst
        local tSecond
        local fnSort = function(tLeft, tRight)
            if v.szOneValue ~= "" then
                if v.bAscending then
                    return tLeft[PQ_STATISTICS_INDEX[v.szOneValue]] > tRight[PQ_STATISTICS_INDEX[v.szOneValue]]
                else
                    return tLeft[PQ_STATISTICS_INDEX[v.szOneValue]] < tRight[PQ_STATISTICS_INDEX[v.szOneValue]]
                end
            else
                local nValueLeft = tonumber(FormatString(v.szFormula, tLeft[PQ_STATISTICS_INDEX[v.szValue1]], tLeft[PQ_STATISTICS_INDEX[v.szValue2]], tLeft[PQ_STATISTICS_INDEX[v.szValue3]]))
                local nValueRight = tonumber(FormatString(v.szFormula, tRight[PQ_STATISTICS_INDEX[v.szValue1]], tRight[PQ_STATISTICS_INDEX[v.szValue2]], tRight[PQ_STATISTICS_INDEX[v.szValue3]]))
                if v.bAscending then
                    return nValueLeft > nValueRight
                else
                    return nValueLeft < nValueRight
                end
            end
        end
        if v.dwID == EXCELLENT_ID.BEST_COURSE then
            for _, v2 in ipairs(tBattleFieldInfo.tStatistics) do
                if v2.nBattleFieldSide == 1 then
                    if not tFirst or fnSort(v2, tFirst) then
                        tFirst = v2
                    end
                end
                if v2.nBattleFieldSide == 2 then
                    if not tSecond or fnSort(v2, tSecond) then
                        tSecond = v2
                    end
                end
            end
        elseif v.dwID == EXCELLENT_ID.ARENA_TOWER_MVP then
            -- 扬刀大会 无MVP时默认显示胜利方第一个
            local bWin = tBattleFieldInfo.bWin or false
            local nClientPlayerSide = tBattleFieldInfo.nClientPlayerSide
            tFirst = tBattleFieldInfo.tStatistics[1]
            for _, v2 in ipairs(tBattleFieldInfo.tStatistics) do
                if (v2.nBattleFieldSide == nClientPlayerSide) == bWin then
                    tFirst = v2
                    break
                end
            end
            for _, v2 in ipairs(tBattleFieldInfo.tStatistics) do
                if fnSort(v2, tFirst) then
                    tFirst = v2
                end
            end
        else
            tFirst = tBattleFieldInfo.tStatistics[1]
            for _, v2 in ipairs(tBattleFieldInfo.tStatistics) do
                if fnSort(v2, tFirst) then
                    tFirst = v2
                end
            end
        end

        local function InsertData(tData)
            if not tBattleFieldInfo.tExcellentData[tData.dwPlayerID] then
                tBattleFieldInfo.tExcellentData[tData.dwPlayerID] = {}
            end
            table.insert(tBattleFieldInfo.tExcellentData[tData.dwPlayerID], v.dwID)
        end

        if tFirst then
            InsertData(tFirst)
        end

        if tSecond then
            InsertData(tSecond)
        end
    end
end

function BattleFieldData._initExcellentInfo()
    tExcellentInfo = {}
    local nCount = g_tTable.BFArenaEvent:GetRowCount()
    for i = 2, nCount do
        local tEvent = g_tTable.BFArenaEvent:GetRow(i)
        local tTabs = SplitString(tEvent.szTabsID, ";")
        tExcellentInfo[tEvent.dwMapID] = {}
        for k, v in pairs(tTabs) do
            local tLine = g_tTable.BFArenaExcellent:Search(tonumber(v))
            table.insert(tExcellentInfo[tEvent.dwMapID], tLine)
        end
    end
end

function BattleFieldData.Log(...)
    local len = select('#', ...)
    local tbMsg = {...}
    local str = ""
    for i = 1, len do
        local msg = tbMsg[i]
        if msg ~= nil then
            str = str .. tostring(msg)
        else
            str = str .. "nil"
        end
        if i ~= len then
            str = str .. "\t"
        end
    end

    LOG.INFO("[BattleFieldData] %s", str)
end

-------------------------------- Public --------------------------------

function BattleFieldData.RequestBFRoleData(dwMapID)
    local player = GetClientPlayer()
    if not player then return end
    local nPlayerID = player.dwID

    --ApplyBFRoleData有个CD，防止频繁调用
    Timer.DelTimer(self, self.nRqstTimerID)
    if CanApplyBFRoleData(BF_ROLE_DATA_TYPE.HISTORY, dwMapID) then
        self.Log("ApplyBFRoleData", nPlayerID, dwMapID)
        ApplyBFRoleData(nPlayerID, dwMapID, false, BF_ROLE_DATA_TYPE.HISTORY)
    else
        self.Log("Delay RequestRoleData")
        self.nRqstTimerID = Timer.Add(self, 0.5, function()
            self.RequestBFRoleData(dwMapID)
        end)
    end
end

function BattleFieldData.OnGetBFRoleData(dwPlayerID, dwMapID, bUpdate)
    dwMapID = self.GetBattleFieldFatherID(dwMapID)
    if dwPlayerID ~= UI_GetClientPlayerID() then
        return
    end

    local tData = GetBFRoleData(dwPlayerID, dwMapID, BF_ROLE_DATA_TYPE.HISTORY)
    if bUpdate ~= 0 then
        tBattleFieldInfo.tNewRoleData = tData

        if IsTableEmpty(tBattleFieldRecordInfo) then
            local nCount = g_tTable.BattleFieldRecord:GetRowCount()
            for i = 2, nCount do
                local tLine = g_tTable.BattleFieldRecord:GetRow(i)
                table.insert(tBattleFieldRecordInfo, tLine)
            end
        end

        local hPlayer           = GetClientPlayer()
        local dwKungfuMountID   = hPlayer.GetKungfuMountID()
        if not dwKungfuMountID then
            return
        end
        local bDPS              = KungfuMount_IsDPS(dwKungfuMountID)
        tBFRoleData[dwMapID]    = tBFRoleData[dwMapID] or {0,0,0,0,0,0,0,0,[0] = 0,}
        local tLastData         = tBFRoleData[dwMapID]
        for k, v in ipairs(tBattleFieldRecordInfo) do
            if (bDPS and v.bDPS) or
                (not bDPS and not v.bDPS) then
                if tData[BF_MAP_ROLE_INFO_TYPE[v.szRoleKey]] > tLastData[BF_MAP_ROLE_INFO_TYPE[v.szRoleKey]] then
                    tBattleFieldInfo.bUpdateRecord = true
                    break
                end
            end
        end
    else
        tBFRoleData[dwMapID] = tData
    end
end

function BattleFieldData.IsInBattleField()
    return MapHelper.IsInBattleField()
end

function BattleFieldData.GetBattleFieldFatherID(dwCheckMapID)
    if not m_tSubMapID or IsTableEmpty(m_tSubMapID) then
        m_tSubMapID = Table_GetBattleFieldSubMapID()
    end
    return m_tSubMapID[dwCheckMapID]
end

function BattleFieldData.CanAddPraise(dwPlayerID)
    if not dwPlayerID then
        return false
    end

    if dwPlayerID == UI_GetClientPlayerID() then
        return false
    end

    if tBattleFieldInfo.tPraiseList and tBattleFieldInfo.tPraiseList[dwPlayerID] then
        return true
    end
    return false
end

function BattleFieldData.OnAddPraise(dwPlayerID)
    if not tBattleFieldInfo.tAddPraiseList then
        tBattleFieldInfo.tAddPraiseList = {}
    end
    tBattleFieldInfo.tAddPraiseList[dwPlayerID] = (tBattleFieldInfo.tAddPraiseList[dwPlayerID] or 0) + 1
    Event.Dispatch(EventType.BF_WidgetPlayerUpdatePraiseInfo)
end

function BattleFieldData.IsAddPraise(dwPlayerID)
    local bResult = false
    if tBattleFieldInfo.tAddPraiseList and tBattleFieldInfo.tAddPraiseList[dwPlayerID] then
        bResult = true
    end
    return bResult
end

function BattleFieldData.GetPraiseCount(dwPlayerID)
    local nCount = 0
    if tBattleFieldInfo.tAddPraiseList and tBattleFieldInfo.tAddPraiseList[dwPlayerID] then
        nCount = tBattleFieldInfo.tAddPraiseList[dwPlayerID]
    end
    return nCount
end

function BattleFieldData.ReqPraise(dwPlayerID)
    local player = GetClientPlayer()
    if not player then
        return
    end

    if self.CanAddPraise(dwPlayerID) and not tBattleFieldInfo.tAddPraiseList[dwPlayerID] then
        RemoteCallToServer("On_FriendPraise_AddRequest", player.dwID, dwPlayerID, PRAISE_TYPE.BATTLE_FIELD)
    end
end

function BattleFieldData.ReqPraiseAll()
    local player = GetClientPlayer()
    if not player then
        return
    end

    local tPlayerID = self.GetPraisePlayerTable()
    if not table.is_empty(tPlayerID) then
        RemoteCallToServer("On_FriendPraise_AddRequestAll", player.dwID, tPlayerID, PRAISE_TYPE.BATTLE_FIELD)
    end
end

function BattleFieldData.GetPraisePlayerTable()
    local tExcellData = tBattleFieldInfo.tExcellentData
    local tPlayer = {}
    for dwPlayerID, tItem in pairs(tExcellData) do
        local bExcellent = tExcellData[dwPlayerID] and not IsTableEmpty(tExcellData[dwPlayerID])
        if self.CanAddPraise(dwPlayerID) and not tBattleFieldInfo.tAddPraiseList[dwPlayerID] and bExcellent then
            table.insert(tPlayer, dwPlayerID)
        end
    end
    return tPlayer
end

function BattleFieldData.GetPlayerStatisticData(dwPlayerID)
    for _, tData in ipairs(tBattleFieldInfo.tStatistics or {}) do
        if tData.dwPlayerID == dwPlayerID then
            return tData
        end
    end
end

function BattleFieldData.BattleField_IsEnd()
    return tBattleFieldInfo.bBattleFieldEnd
end

function BattleFieldData.IsInTreasureBattleFieldMap(bWithTips)
    local hPlayer = GetClientPlayer()
    local bResult = false
    if hPlayer then
        local dwMapID = hPlayer.GetMapID()
        bResult = Table_IsTreasureBattleFieldMap(dwMapID)
    end
    if bResult then
        if bWithTips then
            TipsHelper.ShowNormalTip("当前场景禁止使用")
        end
    end
    return bResult
end

function BattleFieldData.IsInSkillTreasureBattleFieldMap()
    local hPlayer = GetClientPlayer()
    local bResult = false
    if hPlayer then
        local dwMapID = hPlayer.GetMapID()
        bResult = dwMapID == 676
    end

    return bResult
end

function BattleFieldData.IsInFBBattleFieldMap()
    local hPlayer = GetClientPlayer()
    if hPlayer then
        local dwMapID = hPlayer.GetMapID()
        return Table_IsFBBattleFieldMap(dwMapID)
    end
end

function BattleFieldData.IsInTongWarFieldMap()
    local hPlayer = GetClientPlayer()
    if hPlayer then
        local dwMapID = hPlayer.GetMapID()
        return Table_IsTongWarFieldMap(dwMapID)
    end
end

function BattleFieldData.IsInZombieBattleFieldMap()
    local hPlayer = GetClientPlayer()
    if hPlayer then
        local dwMapID = hPlayer.GetMapID()
        return Table_IsZombieBattleFieldMap(dwMapID)
    end
end

function BattleFieldData.IsInMobaBattleFieldMap()
    local hPlayer = GetClientPlayer()
    if hPlayer then
        local dwMapID = hPlayer.GetMapID()
        return Table_IsMobaBattleFieldMap(dwMapID)
    end
end

-- 寻宝模式
function BattleFieldData.IsInXunBaoBattleFieldMap()
    local hPlayer = GetClientPlayer()
    if hPlayer then
        local dwMapID = hPlayer.GetMapID()
        local dwMapID = GetBattleFieldFatherID(dwMapID)
        if not dwMapID then
            return
        end
        return Table_IsTreasureHuntMap(dwMapID)
    end
end

--- 战场内点空格切换下一个队友的视角
function BattleFieldData.Match(bNext, bSecond)
    local hTeam         = GetClientTeam()
    local nTime         = GetTime()
    local tMembers      = {}

    local hPlayer = GetClientPlayer()
    if not hPlayer or hPlayer.nBattleFieldSide == BattleFieldData.OB_BATTLE_FIELD_SIDE then
        return
    end
    hTeam.GetTeamMemberList(tMembers)
    for _, dwMemberID in pairs(tMembers) do
        if not bNext then
            local tMemberInfo = hTeam.GetMemberInfo(dwMemberID)
            if (not tMemberInfo.bDeathFlag) and dwMemberID ~= UI_GetClientPlayerID() then
                --调用切视角的
                if m_nMatchTime and nTime - m_nMatchTime <= MATCH_CD then
                    OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_TREASURE_MATCH_CD)
                    return
                end
                m_nMatchTime = nTime
                m_nNowCamera_ID = dwMemberID
                --OutputMessage("MSG_ANNOUNCE_YELLOW", FormatString(g_tStrings.STR_TREASURE_MATCH1, tMemberInfo.szName))
                RemoteCallToServer("On_Camera_ChangeTarget", dwMemberID)
                return
            end
        end
        if m_nNowCamera_ID == dwMemberID and bNext then
            bNext = nil
        end
    end

    if not bSecond then
        --再遍历一边
        BattleFieldData.Match(nil, true)
    else--切回自己
        local hPlayer = GetClientPlayer()
        if hPlayer then
            if m_nNowCamera_ID then --之前镜头在别人身上才提示
                OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_TREASURE_MATCH2)
            end
            --BattleField_SetView(UI_GetClientPlayerID())
            CameraCommon.SetView(UI_GetClientPlayerID())
        end
        m_nNowCamera_ID = nil
    end

end

function BattleFieldData.AllowMatchPlayer()
    local hPlayer = GetClientPlayer()
    return hPlayer and hPlayer.nMoveState == MOVE_STATE.ON_DEATH and (
            (self.IsInTreasureBattleFieldMap() or self.IsInMobaBattleFieldMap())
                    and hPlayer.nBattleFieldSide ~= BattleFieldData.OB_BATTLE_FIELD_SIDE
    )
end

--- 点头像切视角
function BattleFieldData.MatchPlayer(dwTargetID)
    if self.AllowMatchPlayer() then
        local hTeam         = GetClientTeam()
        local nTime         = GetTime()

        local tMemberInfo = hTeam.GetMemberInfo(dwTargetID)
        if not tMemberInfo then
            return
        end
        if not tMemberInfo.bDeathFlag then
            if m_nMatchTime and nTime - m_nMatchTime <= MATCH_CD then
                OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_TREASURE_MATCH_CD)
                return
            end
            m_nMatchTime = nTime
            RemoteCallToServer("On_Camera_ChangeTarget", dwTargetID)
        end
    end
end

local tMobaEquipList = {}
function BattleFieldData.SetMobaEquipList(tList)
    tMobaEquipList = tList
    FireUIEvent("MOBA_EQUIP_UPDATE")
end

function BattleFieldData.GetMobaEquip()
    return tMobaEquipList
end

function BattleFieldData.SetMobaOpenTime(nTime)
    m_nMobaOpenTime = nTime

    FireUIEvent("LUA_ON_MOBA_OPEN", nTime)
end

function BattleFieldData.GetMobaOpenTime()
    return m_nMobaOpenTime
end

function BattleFieldData.GetMobaGameTime()
    return m_nMobaGameTime
end

function BattleFieldData.GetBattleFieldInfo()
    return tBattleFieldInfo
end

function BattleFieldData.LocalTest_ReplaceBattleFieldInfo(tInfo)
    tBattleFieldInfo = tInfo
end

function BattleFieldData.GetMobaShowPassTime()
    local nOpenTime = BattleFieldData.GetMobaOpenTime()
    local nGameTime = BattleFieldData.GetMobaGameTime()
    local nNowTime  = GetCurrentTime()

    local bEnd = BattleFieldData.BattleField_IsEnd()

    local szPassTime
    if bEnd then
        szPassTime = BattleFieldQueueData.NumberBattleFieldTime(nGameTime)
    elseif nNowTime >= nOpenTime and nOpenTime ~= 0 then
        local nPassTime = math.max(0, nNowTime - nOpenTime)
        szPassTime      = BattleFieldQueueData.NumberBattleFieldTime(nPassTime)
    else
        szPassTime = g_tStrings.STR_MOBA_NOT_OPEN_TIME
    end

    return szPassTime
end

function BattleFieldData.IsCanReportPlayer(szRoleName)
    if not self.IsInBattleField() then
        return
    end

    local player = GetClientPlayer()
    if not player then
        return
    end

    local bIsInParty = player.IsInParty()
    if not bIsInParty then
        return
    end

    local hTeam = GetClientTeam()
    if not hTeam then
        return
    end

    local tMembers = {}
    hTeam.GetTeamMemberList(tMembers)
    for _, dwMemberID in pairs(tMembers) do
        local tMemberInfo = hTeam.GetMemberInfo(dwMemberID)
        if tMemberInfo and dwMemberID ~= player.dwID and
            tMemberInfo.szName == szRoleName then
            return dwMemberID
        end
    end
end

function BattleFieldData.IsMobaInjury()
    local player = PlayerData.GetClientPlayer()
    if not player then
        return false
    end
    if not self.IsInMobaBattleFieldMap() then
        return false
    end
    if player.nMoveState == MOVE_STATE.ON_DEATH then
        return true
    end
    return false
end

---@return table<number, TongFightInfo> | TongFightGlobalInfo
function BattleFieldData.GetTongFight2024Info()
    return GDAPI_TongFight2024Info()
end

local tMapLevelToName              = {
    [0] = "巅峰场",
    [1] = "大师场",
    [2] = "精英场",
}

function BattleFieldData.GetTongFightMapLevel()
    local tTongFightInfo = BattleFieldData.GetTongFight2024Info()
    local szLevelName    = tMapLevelToName[tTongFightInfo.nMapLevel]

    return szLevelName
end

---@return number, number, number, number
---dwPQID, dwPQTemplateID, nBeginTime, nEndTime
function BattleFieldData.GetBattleFieldPQInfo()
    return GetBattleFieldPQInfo()
end

function BattleFieldData.OpenTongWarGuessing()
    WebUrl.OpenByID(WEBURL_ID.TONG_WAR_GUESSING)

    APIHelper.Do(HuaELouData.szDidKeyTongWarGuessing)

    Event.Dispatch("OnUpdateHuaELouRedPoint")
end