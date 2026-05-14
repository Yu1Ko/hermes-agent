-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIGMBallView
-- Date: 2022-11-07 20:11:52
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelCombatStatistics = class("UIPanelCombatStatistics")

local MAX_TOTAL_NUM = 10

local INDEX2SOR_TYPE = {
    STAT_TYPE.DAMAGE,
    STAT_TYPE.THERAPY,
    STAT_TYPE.BE_DAMAGE,
    STAT_TYPE.BE_THERAPY,
}

function UIPanelCombatStatistics:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self.nSortType = STAT_TYPE.DAMAGE
        self.nHistoryIndex = 1
        self.bHasData = false
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)

    self:InitSortFilter()
    self:UpdateHistory(true)
end

function UIPanelCombatStatistics:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelCombatStatistics:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.SetSwallowTouches(self.BtnSortMask, false)
    UIHelper.BindUIEvent(self.BtnSortMask, EventType.OnClick, function()
        UIHelper.SetSelected(self.TogSort, false)
    end)

    UIHelper.SetSwallowTouches(self.BtnHistoryMask, false)
    UIHelper.BindUIEvent(self.BtnHistoryMask, EventType.OnClick, function()
        UIHelper.SetSelected(self.TogCombatData, false)
    end)

    for index, toggle in ipairs(self.sortToggles) do
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupSort, toggle)
        UIHelper.BindUIEvent(toggle, EventType.OnSelectChanged, function(_, bSelected)
            if bSelected then
                self.nSortType = INDEX2SOR_TYPE[index]
                self:UpdateHistoryDetailInfo()
            end
        end)
    end

    UIHelper.BindUIEvent(self.BtnFriendlySend, EventType.OnClick, function()
        self:SendTotalData(false)
    end)

    UIHelper.BindUIEvent(self.BtnHostilitySend, EventType.OnClick, function()
        self:SendTotalData(true)
    end)
end

function UIPanelCombatStatistics:RegEvent()
    Event.Reg(self, EventType.OnFightHistoryUpdate, function()
        self:UpdateHistory()
        if not self.bHasData then
            self:SelectHistory(self.nHistoryIndex)
        end
    end)
end

function UIPanelCombatStatistics:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelCombatStatistics:InitSortFilter()
    self.scriptFilter = UIHelper.GetBindScript(self.WidgetAnchorSortTips)
    self.scriptFilter:Init(HURT_STAT_TYPE.PANEL)

    local tbToggles = self.scriptFilter:GetMainOptions()
    for nIndex, tog in ipairs(tbToggles) do
        UIHelper.SetSelected(tog, self.nSortType == INDEX2SOR_TYPE[nIndex], false)
    end

    self.scriptFilter:BindMainOptionsCallBack(function(nIndex, bSelected)
        if bSelected then
            self.nSortType = INDEX2SOR_TYPE[nIndex]
            self:UpdateHistoryDetailInfo()
        end
    end)
end

function UIPanelCombatStatistics:IsShowParnterData(tParner)
	local npc = GetNpc(tParner.dwID)
	if not npc or npc.dwEmployer == 0 then
		return false
	end

	if Storage.HurtStatisticSettings.ShowParnterType == PARTNER_FIGHT_LOG_TYPE.ALL then
		return true
	end

	local bSelf = npc.dwEmployer == UI_GetClientPlayerID()
	if bSelf and Storage.HurtStatisticSettings.ShowParnterType == PARTNER_FIGHT_LOG_TYPE.SELF then
		return true
	end

	return false
end

function UIPanelCombatStatistics:GetStatData(eDataType, nStatType)
    local nIntensity = 0
    local open_npc = false
    if nStatType == STAT_TYPE2ID[STAT_TYPE.DAMAGE] then
       nIntensity = 2
       open_npc = self.StatBoss
    else
       open_npc = (self.StatNpc or self.StatBoss)
    end

    local bShowPartner = Storage.HurtStatisticSettings.IsSeparatePartnerData
    local tResult = QueryPlayerStatData(1, eDataType, nStatType, 0) -- player

    if bShowPartner then
		local tPartnerRes = QueryPlayerStatData(1, eDataType, nStatType, nIntensity, true) -- 侠客
		for k, v in pairs(tPartnerRes) do
			if self:IsShowParnterData(v) then
				v.bPartner = true
				table.insert(tResult, v)
			end
		end
	end

    if open_npc then
       local tNpcRes = QueryPlayerStatData(1, eDataType, nStatType, nIntensity) -- npc
       for k, v in pairs(tNpcRes) do
           if v.nValue > 0 and (nIntensity == 0 or (v.nIntensity == 2 or v.nIntensity == 6)) then
               table.insert(tResult, v)
           end
       end
    end
    return tResult

end

-- QueryPlayerStatData无法获取敌对玩家DPS，因此采用自己计算的DPS
local function GetDpsValue_EnemyPlayer(tHistoryData, nStatType, dwID)
    if tHistoryData and nStatType and dwID then
        local tStatisticList = FightSkillLog.GetDetailFromHistory(tHistoryData, nStatType)
        local nTime = tHistoryData.nTimeSecond <= 0 and 1 or tHistoryData.nTimeSecond
        if tStatisticList and tStatisticList[dwID] then
            local tList = tStatisticList[dwID].tList
            local nTotalNum = 0
            for _, data in pairs(tList) do
                nTotalNum = nTotalNum + data.nTotalDamage
            end
            return math.floor(nTotalNum / nTime)
        end
    end
    return 0
end

local function GetDpsValue(tHistoryData, nStatType, dwID)
    local tSummary = FightSkillLog.GetSummaryFromHistory(tHistoryData, nStatType)
    if tSummary then
        for _, tInfo in ipairs(tSummary) do
            if dwID == tInfo.dwID then
                return tInfo.nValuePer
            end
        end
    end
    return 0
end

function UIPanelCombatStatistics:UpdateHistory(bFirstEnter)
    self.tHistoryToggles = {}
    UIHelper.RemoveAllChildren(self.ScrollViewUnfold)
    local lst = FightSkillLog.GetHistoryNameList()
    for index, szName in ipairs(lst) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetCombatStatisticsTipsCell, self.ScrollViewUnfold)
        UIHelper.SetString(script.LabelName, szName)
        UIHelper.BindUIEvent(script.ToggleTips, EventType.OnSelectChanged, function(tog, bSelected)
            if bSelected then
                UIHelper.SetSelected(self.TogCombatData, false)
                self:SelectHistory(index)
            end
        end)
        table.insert(self.tHistoryToggles, script.ImgSelect)

        if bFirstEnter and index == 1 then
            UIHelper.SetSelected(script.ToggleTips, true)
        end
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewUnfold)

    self.bHasData = #lst > 0
    UIHelper.SetNodeGray(self.TogCombatData, not self.bHasData, true)
    UIHelper.SetEnable(self.TogCombatData, self.bHasData)
end

function UIPanelCombatStatistics:SelectHistory(nIndex)
    UIHelper.RemoveAllChildren(self.WidgetHistorySlot)
    self.nHistoryIndex = nIndex
    self:UpdateHistoryDetailInfo()
end

local nRankToRankIcon = {
    [1] = "UIAtlas2_FengYunLu_Rank_icon_ranking01.png",
    [2] = "UIAtlas2_FengYunLu_Rank_icon_ranking02.png",
    [3] = "UIAtlas2_FengYunLu_Rank_icon_ranking03.png",
}

function UIPanelCombatStatistics:UpdateHistoryDetailInfo()
    local nStatType = STAT_TYPE.DAMAGE
    local tHistoryData = FightSkillLog.GetHistoryByIndex(self.nHistoryIndex)
    if not tHistoryData or not tHistoryData.tData then
        return
    end

    UIHelper.SetString(self.LabelHistory, tHistoryData.szTime)

    local nSortType = self.nSortType
    local sortFunc = function(a, b)
        return a[nSortType] > b[nSortType]
    end

    self.tCharacterDataList = {}
    local tCharacterDatas = FightSkillLog.GetAllCharacterSimpleInfo(tHistoryData)
    for _, tData in pairs(tCharacterDatas) do
        local dwID = tData.dwID
        local tInfo = FightSkillLog.GetCharacterInfoFromHistory(tHistoryData, dwID)
        local bIsEnemyPlayer = tData.bIsEnemy and tInfo and tInfo.bIsPlayer
        local fnDPSFunc = bIsEnemyPlayer and GetDpsValue_EnemyPlayer or GetDpsValue
        local tDpsData = {
            ["dwID"] = dwID,
            ["bIsEnemy"] = tData.bIsEnemy,
            ["tInfo"] = tInfo,
            [STAT_TYPE.DAMAGE] = fnDPSFunc(tHistoryData, STAT_TYPE.DAMAGE, dwID),
            [STAT_TYPE.THERAPY] = fnDPSFunc(tHistoryData, STAT_TYPE.THERAPY, dwID),
            [STAT_TYPE.BE_DAMAGE] = fnDPSFunc(tHistoryData, STAT_TYPE.BE_DAMAGE, dwID),
            [STAT_TYPE.BE_THERAPY] = fnDPSFunc(tHistoryData, STAT_TYPE.BE_THERAPY, dwID),
        }
        table.insert(self.tCharacterDataList, tDpsData)
    end

    UIHelper.RemoveAllChildren(self.ScrollViewFriendly)
    UIHelper.RemoveAllChildren(self.ScrollViewHostility)

    local nEnemy, nAlly = 0, 0
    table.sort(self.tCharacterDataList, sortFunc)
    for _, data in ipairs(self.tCharacterDataList) do
        local parent = data.bIsEnemy and self.ScrollViewHostility or self.ScrollViewFriendly
        local nRankIndex
        if data.bIsEnemy then
            nEnemy = nEnemy + 1
            nRankIndex = nEnemy
        else
            nAlly = nAlly + 1
            nRankIndex = nAlly
        end

        local tInfo = data.tInfo
        if tInfo then
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetCombatStatisticsListCell, parent)
            local szKungFuImgPath = PlayerKungfuImg[tInfo.dwMountKungfuID]

            UIHelper.SetString(script.LabelName, UIHelper.LimitUtf8Len(tInfo.szName, 8))
            UIHelper.SetString(script.LabelHarm, string.format("%.0f", data[STAT_TYPE.DAMAGE]))
            UIHelper.SetString(script.LabelCure, string.format("%.0f", data[STAT_TYPE.THERAPY]))
            UIHelper.SetString(script.LabelBearHarm, string.format("%.0f", data[STAT_TYPE.BE_DAMAGE]))
            UIHelper.SetString(script.LabelBearCure, string.format("%.0f", data[STAT_TYPE.BE_THERAPY]))

            if szKungFuImgPath then
                UIHelper.SetSpriteFrame(script.ImgXinfa, szKungFuImgPath)
            end
            UIHelper.SetVisible(script.ImgXinfa, szKungFuImgPath ~= nil)

            if nRankIndex <= 3 then
                UIHelper.SetVisible(script.ImgRankNum, false)
                UIHelper.SetVisible(script.ImgRankIcon, true)
                UIHelper.SetSpriteFrame(script.ImgRankIcon, nRankToRankIcon[nRankIndex])
            else
                UIHelper.SetVisible(script.ImgRankNum, true)
                UIHelper.SetVisible(script.ImgRankIcon, false)
                UIHelper.SetString(script.ImgRankNum, nRankIndex)
            end
            UIHelper.CascadeDoLayoutDoWidget(script._rootNode, true, true)

            UIHelper.BindUIEvent(script.BtnInfo, EventType.OnClick, function()
                UIMgr.Open(VIEW_ID.PanelCombatData, tInfo.szName, data.dwID, nStatType, tHistoryData)
            end)

            UIHelper.BindUIEvent(script.BtnTransfer, EventType.OnClick, function()
                self:SendSingleData(tInfo.szName, data)
            end)
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewFriendly)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewHostility)
end

function UIPanelCombatStatistics:SendSingleData(szName, data)
    if g_pClientPlayer.IsInParty() then
        local szText = FormatString(g_tStrings.HURT_STATISTIC_SINGLE_CHAT, szName,
                data[STAT_TYPE.DAMAGE], data[STAT_TYPE.THERAPY], data[STAT_TYPE.BE_DAMAGE], data[STAT_TYPE.BE_THERAPY])
        local tbMsg = { { type = "text", text = UIHelper.UTF8ToGBK(szText .. "\n") } }
        Player_Talk(g_pClientPlayer, PLAYER_TALK_CHANNEL.TEAM, "", tbMsg)
    else
        OutputMessage("MSG_ANNOUNCE_NORMAL", "暂时没有队伍，无法分享")
    end

end

function UIPanelCombatStatistics:SendTotalData(bIsEnemy)
    if g_pClientPlayer.IsInParty() then
        local szTitleDict = {
            [STAT_TYPE.DAMAGE] = g_tStrings.STR_DAMAGE_SINGLE,
            [STAT_TYPE.THERAPY] = g_tStrings.STR_THERAPY_SINGLE,
            [STAT_TYPE.BE_DAMAGE] = g_tStrings.STR_BE_DAMAGE_SINGLE,
            [STAT_TYPE.BE_THERAPY] = g_tStrings.STR_BE_THERAPY_SINGLE,
        }

        local tHistoryData = FightSkillLog.GetHistoryByIndex(self.nHistoryIndex)
        if not tHistoryData or not tHistoryData.tData then
            return
        end

        local szTotalText = string.format("%s统计：", szTitleDict[self.nSortType])
        local nCount = 0
        for index, data in pairs(self.tCharacterDataList) do
            if bIsEnemy == data.bIsEnemy then
                if nCount ~= 0 then
                    szTotalText = szTotalText .. "，\n"
                end

                local tInfo = FightSkillLog.GetCharacterInfoFromHistory(tHistoryData, data.dwID)
                if tInfo then
                    local szMain = g_tStrings.HURT_STATISTIC_TOTAL_CHAT[self.nSortType]
                    local szText = FormatString(szMain, tInfo.szName, data[self.nSortType])
                    szTotalText = szTotalText .. szText

                    --LOG.WARN(szText)
                    nCount = nCount + 1
                    if nCount >= MAX_TOTAL_NUM then
                        break
                    end
                end
            end
        end

        local szConfirmText = string.format("是否发送前十名的%s信息到队伍聊天", szTitleDict[self.nSortType])
        UIHelper.ShowConfirm(szConfirmText, function()
            local tbMsg = { { type = "text", text = UIHelper.UTF8ToGBK(szTotalText .. "\n") } }
            Player_Talk(g_pClientPlayer, PLAYER_TALK_CHANNEL.TEAM, "", tbMsg)
        end)
    else
        OutputMessage("MSG_ANNOUNCE_NORMAL", "暂时没有队伍，无法分享")
    end
end

return UIPanelCombatStatistics