-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITreasureBattleFieldSettleView
-- Date: 2023-05-16 17:44:24
-- Desc: ?
-- ---------------------------------------------------------------------------------

local RANK_INFO = {
    [1] = {
        MinRank = 1,
        TitleColor = cc.c3b(255, 136, 41),
        TitlePath = "UIAtlas2_Pvp_PvpMainCity2_CompetePvp1",
        RankTexture = {
            [1] = "UIAtlas2_Pvp_PvpMainCity2_CompetePvp9",
        },
        DescPath = "UIAtlas2_Pvp_PvpMainCity2_CompetePvp4",
        AniName = "AniGolden",
    },
    [2] = {
        MinRank = 2,
        TitleColor = cc.c3b(35, 134, 169),
        TitlePath = "UIAtlas2_Pvp_PvpMainCity2_CompetePvp2",
        RankTexture = {
            [2] = "UIAtlas2_Pvp_PvpMainCity2_CompetePvp10",
            [3] = "UIAtlas2_Pvp_PvpMainCity2_CompetePvp11",
        },
        DescPath = "UIAtlas2_Pvp_PvpMainCity2_CompetePvp5",
        AniName = "AniGreen",
    },
    [3] = {
        MinRank = 5,
        TitleColor = cc.c3b(139, 232, 222),
        TitlePath = "UIAtlas2_Pvp_PvpMainCity2_CompetePvp3",
        DescPath = "UIAtlas2_Pvp_PvpMainCity2_CompetePvp6",
        AniName = "AniBlue",
    }
}

local function GetRankInfo(nRank)
    local ret = nil
    for _, info in ipairs(RANK_INFO) do
        if info.MinRank > nRank then
            return ret
        end
        ret = info
    end
    return ret
end

local UITreasureBattleFieldSettleView = class("UITreasureBattleFieldSettleView")

function UITreasureBattleFieldSettleView:OnEnter(nBanishTime, nTeamCount, bTest, funcClickBackMvpCallback)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nBanishTime = nBanishTime
    self.nTeamCount = nTeamCount
    self.bTest = bTest
    self.funcClickBackMvpCallback = funcClickBackMvpCallback
    -- ApplyBattleFieldStatistics()

    Timer.AddCycle(self, 1, function ()
        local nCurTime = GetTickCount()
        if self.nBanishTime and self.nBanishTime > nCurTime  then
            local nTime = math.floor((self.nBanishTime - nCurTime) / 1000)
            UIHelper.SetString(self.LabelTime, string.format("%d秒后传出战场", nTime))
            UIHelper.SetVisible(self.LabelTime, true)
        else
            self.nBanishTime = nil
            UIHelper.SetVisible(self.LabelTime, false)
        end
    end)

    -- if self.bTest then
        self:UpdateInfo()
    -- end
end

function UITreasureBattleFieldSettleView:OnExit()
    -- 关界面自动退出
    if not self.bHasLeave then
        BattleFieldData.LeaveBattleField()
    end

    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UITreasureBattleFieldSettleView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnLeave, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnBack2, EventType.OnClick, function ()
        if self.funcClickBackMvpCallback then
            self.funcClickBackMvpCallback()
        end
    end)
end

function UITreasureBattleFieldSettleView:RegEvent()
    Event.Reg(self, "BATTLE_FIELD_SYNC_STATISTICS", function ()
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnClientPlayerLeave, function ()
        self.bHasLeave = true
        UIMgr.Close(self)
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        UIHelper.SetVisible(self.WidgetPersonalCard1, false)
    end)
end

function UITreasureBattleFieldSettleView:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITreasureBattleFieldSettleView:UpdateInfo()
    local tStatistics 	= GetBattleFieldStatistics()

    if self.bTest then
        tStatistics = {}
        tStatistics[UI_GetClientPlayerID()] = {
            ["Name"] = UIHelper.UTF8ToGBK("测试"),
            ["ForceID"] = 1,
            [PQ_STATISTICS_INDEX.SPECIAL_OP_2] = 1,
            [PQ_STATISTICS_INDEX.SPECIAL_OP_1] = 6,
            [PQ_STATISTICS_INDEX.DECAPITATE_COUNT] = 1,
            [PQ_STATISTICS_INDEX.KILL_COUNT] = 1,
            [PQ_STATISTICS_INDEX.BEST_ASSIST_KILL_COUNT] = 1,
            [PQ_STATISTICS_INDEX.HARM_OUTPUT] = 1,
            [PQ_STATISTICS_INDEX.SPECIAL_OP_3] = 1,
            [PQ_STATISTICS_INDEX.SPECIAL_OP_6] = 1,
        }
        -- tStatistics[2] = {
        --     ["Name"] = UIHelper.UTF8ToGBK("测试2"),
        --     ["ForceID"] = 1,
        --     [PQ_STATISTICS_INDEX.SPECIAL_OP_2] = 1,
        --     [PQ_STATISTICS_INDEX.SPECIAL_OP_1] = 1,
        --     [PQ_STATISTICS_INDEX.DECAPITATE_COUNT] = 1,
        --     [PQ_STATISTICS_INDEX.KILL_COUNT] = 1,
        --     [PQ_STATISTICS_INDEX.BEST_ASSIST_KILL_COUNT] = 1,
        --     [PQ_STATISTICS_INDEX.HARM_OUTPUT] = 1,
        --     [PQ_STATISTICS_INDEX.SPECIAL_OP_3] = 4,
        --     [PQ_STATISTICS_INDEX.SPECIAL_OP_6] = 1,
        -- }
        -- tStatistics[3] = {
        --     ["Name"] = UIHelper.UTF8ToGBK("测试3"),
        --     ["ForceID"] = 1,
        --     [PQ_STATISTICS_INDEX.SPECIAL_OP_2] = 2,
        --     [PQ_STATISTICS_INDEX.SPECIAL_OP_1] = 1,
        --     [PQ_STATISTICS_INDEX.DECAPITATE_COUNT] = 1,
        --     [PQ_STATISTICS_INDEX.KILL_COUNT] = 1,
        --     [PQ_STATISTICS_INDEX.BEST_ASSIST_KILL_COUNT] = 1,
        --     [PQ_STATISTICS_INDEX.HARM_OUTPUT] = 1,
        --     [PQ_STATISTICS_INDEX.SPECIAL_OP_3] = 4,
        --     [PQ_STATISTICS_INDEX.SPECIAL_OP_6] = 1,
        -- }
        -- tStatistics[4] = {
        --     ["Name"] = UIHelper.UTF8ToGBK("测试3"),
        --     ["ForceID"] = 1,
        --     [PQ_STATISTICS_INDEX.SPECIAL_OP_2] = 1,
        --     [PQ_STATISTICS_INDEX.SPECIAL_OP_1] = 1,
        --     [PQ_STATISTICS_INDEX.DECAPITATE_COUNT] = 1,
        --     [PQ_STATISTICS_INDEX.KILL_COUNT] = 1,
        --     [PQ_STATISTICS_INDEX.BEST_ASSIST_KILL_COUNT] = 1,
        --     [PQ_STATISTICS_INDEX.HARM_OUTPUT] = 1,
        --     [PQ_STATISTICS_INDEX.SPECIAL_OP_3] = 2,
        --     [PQ_STATISTICS_INDEX.SPECIAL_OP_6] = 1,
        -- }
    end
    -- LOG.ERROR("------------------BattleFieldStatistics------------------")
    -- LOG.TABLE(tStatistics)
    -- LOG.ERROR("------------------BattleFieldStatistics------------------")
    local dwMyID 		= UI_GetClientPlayerID()
	local hPlayer 		= GetClientPlayer()
    local dwMyTeamID 	= nil
	local nMyRanking 	= nil

    local tInfo 		= tStatistics[dwMyID] or {}
	dwMyTeamID 			= tInfo[PQ_STATISTICS_INDEX.SPECIAL_OP_2]
	nMyRanking 			= tInfo[PQ_STATISTICS_INDEX.SPECIAL_OP_1]

    UIHelper.SetString(self.LabelRanking, string.format("队伍排名：%d/%d", nMyRanking, self.nTeamCount))
    local tRankInfo = GetRankInfo(nMyRanking)
    if tRankInfo.RankTexture and tRankInfo.RankTexture[nMyRanking] then
        UIHelper.SetVisible(self.ImgRank1, true)
        UIHelper.SetVisible(self.ImgRank2, false)
        UIHelper.SetVisible(self.LabelRank, false)
        UIHelper.SetSpriteFrame(self.ImgRank1, tRankInfo.RankTexture[nMyRanking])
    else
        UIHelper.SetVisible(self.ImgRank1, false)
        UIHelper.SetVisible(self.ImgRank2, true)
        UIHelper.SetVisible(self.LabelRank, true)
        UIHelper.SetString(self.LabelRank, nMyRanking)
    end
    UIHelper.SetColor(self.ImgCompeteTitleBg, tRankInfo.TitleColor)
    UIHelper.SetSpriteFrame(self.ImgCompeteMiddleTitle, tRankInfo.TitlePath)
    UIHelper.SetSpriteFrame(self.ImgLeftTitle, tRankInfo.DescPath)
    UIHelper.PlayAni(self, self.AniAll, tRankInfo.AniName)

    local tList = {}
    for k, v in pairs(tStatistics) do
        if v[PQ_STATISTICS_INDEX.SPECIAL_OP_2] == dwMyTeamID then
            table.insert(tList, v)
        end
    end
    table.sort(tList, function (a, b)
        return a[PQ_STATISTICS_INDEX.SPECIAL_OP_3] > b[PQ_STATISTICS_INDEX.SPECIAL_OP_3]
    end)
    for _, v in ipairs(tList) do
        local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetEndSettlementListCell, self.ScrollViewSettlementList, v)
        scriptCell:SetWidgetPersonalCard(self.WidgetPersonalCard1)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSettlementList)

    local _, _, nBeginTime, nEndTime = GetBattleFieldPQInfo()
	local nCurrentTime = GetCurrentTime()
    if nBeginTime and nBeginTime > 0 then
		local nTime = 0
		if nEndTime ~= 0 and nCurrentTime > nEndTime then
			nTime = nEndTime - nBeginTime
		else
			nTime = nCurrentTime - nBeginTime
		end
		local szTime = string.format("%02d:%02d", math.floor(nTime / 60), math.floor(nTime % 60))
		UIHelper.SetString(self.LabelPastTime, szTime) --已用时间
	end
end


return UITreasureBattleFieldSettleView