-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIArenaBattleDataView
-- Date: 2022-12-14 21:18:11
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIArenaBattleDataView = class("UIArenaBattleDataView")

function UIArenaBattleDataView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIArenaBattleDataView:OnExit()
    self.bInit = false
end

function UIArenaBattleDataView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIArenaBattleDataView:RegEvent()
    Event.Reg(self, "SCENE_BEGIN_LOAD", function()
        UIMgr.Close(self)
    end)
end

function UIArenaBattleDataView:UpdateInfo()
    -- LOG.TABLE(ArenaData.tbArenaBattleData)
    self:UpdateSelfInfo()
    self:UpdateEnemyInfo()
    self:UpdateTimerInfo()
end

function UIArenaBattleDataView:UpdateSelfInfo()
    local tbData = self:GetData(false)
    UIHelper.SetString(self.LabelTeam1, tbData.szTeamName)
    UIHelper.SetString(self.LabelNum1, tbData.nScore)

    local layout = self.LayoutTeamPlayer
    if tbData.nSide == 0 then
        layout = self.LayoutEnemyPlayer
    end
    UIHelper.RemoveAllChildren(layout)
    for i, tbInfo in ipairs(tbData.tbTeamInfo) do
        local cellScript = UIHelper.AddPrefab(PREFAB_ID.WidgetPVPPlayer, layout)
        cellScript:OnEnter(tbInfo, false)
    end
end

function UIArenaBattleDataView:UpdateEnemyInfo()
    local tbData = self:GetData(true)

    UIHelper.SetString(self.LabelTeam2, tbData.szTeamName)
    UIHelper.SetString(self.LabelNum2, tbData.nScore)

    local layout = self.LayoutTeamPlayer
    if tbData.nSide == 0 then
        layout = self.LayoutEnemyPlayer
    end
    UIHelper.RemoveAllChildren(layout)
    for i, tbInfo in ipairs(tbData.tbTeamInfo) do
        local cellScript = UIHelper.AddPrefab(PREFAB_ID.WidgetPVPPlayer, layout)
        cellScript:OnEnter(tbInfo, true)
    end
end

function UIArenaBattleDataView:UpdateTimerInfo()
    local nArenaType = ArenaData.GetBattleArenaType()
    if ArenaData.nBattleStartTime and ArenaData.nBattleStartTime > 0 then
        local nBattleStartTime = ArenaData.nBattleStartTime
        local nEndTime = nBattleStartTime + ArenaData.MATCH_TIME2
        if nArenaType and nArenaType ~= ARENA_UI_TYPE.ARENA_2V2 then
            nEndTime = nBattleStartTime + ArenaData.MATCH_TIME
        end

        self:Clear()
        self.m_nLeftTimer = nEndTime - GetCurrentTime()
        self:UpdateTimeView()

        --倒计时
        Timer.AddCountDown(self, self.m_nLeftTimer, function()
            self.m_nLeftTimer = self.m_nLeftTimer - 1
            self:UpdateTimeView()
        end)
    else
        local nEndTime = ArenaData.MATCH_TIME2
        if nArenaType and nArenaType ~= ARENA_UI_TYPE.ARENA_2V2 then
            nEndTime = ArenaData.MATCH_TIME
        end

        self:Clear()
        self.m_nLeftTimer = nEndTime
        self:UpdateTimeView()
    end
end

function UIArenaBattleDataView:Clear()
    Timer.DelAllTimer(self)
end

function UIArenaBattleDataView:UpdateTimeView()
    local szFormatTime = self:GetFormatTime(self.m_nLeftTimer)
    UIHelper.SetString(self.LabelTime, szFormatTime)
end

function UIArenaBattleDataView:GetFormatTime(nTime)
	local nM = math.floor(nTime / 60)
	local nS = math.floor(nTime % 60)
	local szTimeText = ""

	if nM ~= 0 then
		szTimeText= szTimeText..nM..":"
	end

	if nS < 10 and nM ~= 0 then
		szTimeText = szTimeText.."0"
	end

	szTimeText= szTimeText..nS

	return szTimeText
end

function UIArenaBattleDataView:GetData(bEnemy)
    local tbData = {
        szTeamName = "",
        nScore = 0,
        tbTeamInfo = {}
    }

    local player = PlayerData.GetClientPlayer()
    local nSelfSide = player.nBattleFieldSide
    local nEnemySide  = 0
    if nSelfSide == 0 then
        nEnemySide = 1
    end

    if bEnemy then
        tbData.nSide = nEnemySide
    else
        tbData.nSide = nSelfSide
    end

    if ArenaData.tbBattleData then
        if bEnemy then
            tbData.nScore = ArenaData.tbBattleData[nEnemySide] or 0
        else
            tbData.nScore = ArenaData.tbBattleData[nSelfSide] or 0
        end
    end

    local tbBattlePlayerInfo = ArenaData.GetBattlePlayerData(bEnemy)
    for i, tbInfo in ipairs(tbBattlePlayerInfo) do
        local player = PlayerData.GetPlayer(tbInfo.dwID)
        table.insert(tbData.tbTeamInfo, {
            dwID = tbInfo.dwID,
            szName = tbInfo.szName,
            dwMountKungfuID = tbInfo.dwMountKungfuID,
        })
    end

    return tbData
end


return UIArenaBattleDataView