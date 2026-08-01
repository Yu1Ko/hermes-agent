-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITreasureBattleFieldPopView
-- Date: 2023-05-16 17:44:07
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UITreasureBattleFieldPopView = class("UITreasureBattleFieldPopView")

function UITreasureBattleFieldPopView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    ApplyBattleFieldStatistics()

    Timer.AddCycle(self, 1, function ()
        self:Tick()
    end)
end

function UITreasureBattleFieldPopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UITreasureBattleFieldPopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnLeave, EventType.OnClick, function ()
        if not BattleFieldData.BattleField_IsEnd() then
            local szTips = g_tStrings.STR_SURE_LEAVE_TREASURE_BATTLE
            if BattleFieldData.IsInXunBaoBattleFieldMap() then
                szTips = g_tStrings.STR_SURE_LEAVE_XUNBAO_BATTLE
            end
            UIHelper.ShowConfirm(szTips, function ()
                UIMgr.Close(self)
                RemoteCallToServer("On_Zhanchang_Leave")
            end)
        else
            UIMgr.Close(self)
            BattleFieldData.LeaveBattleField()
        end
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)
end

function UITreasureBattleFieldPopView:RegEvent()
    Event.Reg(self, "BATTLE_FIELD_SYNC_STATISTICS", function ()
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnClientPlayerLeave, function (nPlayerID)
        UIMgr.Close(self)
    end)
end

function UITreasureBattleFieldPopView:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITreasureBattleFieldPopView:UpdateInfo()
    local tStatistics 	= GetBattleFieldStatistics()
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

    for k, v in pairs(tStatistics) do
        if v[PQ_STATISTICS_INDEX.SPECIAL_OP_2] == dwMyTeamID then
            UIHelper.AddPrefab(PREFAB_ID.WidgetSettlementListCell, self.ScrollViewMainContent, v)
        end
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewMainContent)

    self:UpdateTime()
end

function UITreasureBattleFieldPopView:UpdateTime()
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
		UIHelper.SetString(self.LabelTime, szTime) --已用时间
	end
end

function UITreasureBattleFieldPopView:Tick()
    self:UpdateTime()
end

return UITreasureBattleFieldPopView