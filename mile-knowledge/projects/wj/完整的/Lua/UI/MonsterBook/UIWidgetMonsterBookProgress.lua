local UIWidgetMonsterBookProgress = class("UIWidgetMonsterBookProgress")
local MONSTER_ACTIVITY = 818
local AWARD_TYPE =
{
	[1]  = "ID",
	[2]  = "exitem1",
	[3]  = "exitem2",
	[4]  = "exitem3",
	[5]  = "exitem4",
	[6]  = "exdoubleitem",
	[7]  = "exteriorpiece",
	[8]  = "prestigelimit",
	[9]  = "justicelimit",
	[10] = "experience",
	[11] = "justice",
	[12] = "prestige",
	[13] = "titlepoint",
	[14] = "train",
	[15] = "vigor",
	[16] = "tongfund",
	[17] = "tongresource",
	[18] = "personalhighlevel",
	[19] = "teamhighlevel",
	[20] = "contribution",
	[21] = "money",
}

function UIWidgetMonsterBookProgress:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()

    --资源下载Widget
    local scriptDownload = UIHelper.GetBindScript(self.WidgetDownload)
    local nPackID = PakDownloadMgr.GetMapResPackID(MonsterBookData.PLAY_MAP_ID)
    scriptDownload:OnInitWithPackID(nPackID)
end

function UIWidgetMonsterBookProgress:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMonsterBookProgress:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSendToChat, EventType.OnClick, function ()
        local szName = g_tStrings.MONSTER_BOOK_TITLE
        ChatHelper.SendEventLinkToChat(szName, "PanelLink/FBlistMonster")
    end)

    UIHelper.BindUIEvent(self.BtnReset, EventType.OnClick, function ()
        DungeonData.RequestResetMap(MonsterBookData.PLAY_MAP_ID, function ()

        end)
    end)

    UIHelper.BindUIEvent(self.BtnQuickTeam, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelTeam, 1, nil, {220,221,222})
    end)

    UIHelper.BindUIEvent(self.BtnHelp, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelTutorialLite, 43)
    end)

    UIHelper.BindUIEvent(self.BtnEnter, EventType.OnClick, function ()
        -- 地图资源下载检测拦截
        if not PakDownloadMgr.UserCheckDownloadMapRes(MonsterBookData.PLAY_MAP_ID, nil, nil, true) then
            return
        end

        MapMgr.BeforeTeleport()
        RemoteCallToServer("On_MonsterBook_AskIn")
        UIMgr.Close(VIEW_ID.PanelBaizhanMain)
        UIMgr.Close(VIEW_ID.PanelRoadCollection)
        UIMgr.Close(VIEW_ID.PanelSystemMenu)
    end)

    UIHelper.BindUIEvent(self.BtnAchievements, EventType.OnClick, function()
        self:LinkToAchievements()
	end)
end

function UIWidgetMonsterBookProgress:RegEvent()
    Event.Reg(self, "REMOTE_MOSTER_REPLACE_EVENT", function()
        self:UpdateMonsterReplace()
    end)
end

function UIWidgetMonsterBookProgress:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetMonsterBookProgress:UpdateInfo()
    self:UpdateBossInfoList()

    if DungeonData.IsInDungeon() then
        UIHelper.SetButtonState(self.BtnEnter, BTN_STATE.Disable, "当前场景无法前往百战异闻录")
    end

    local nTotalCount, nFinishCount = self:FindAchievementCount()
    UIHelper.SetString(self.LabelAchievements, string.format("成就(%d/%d)", nFinishCount, nTotalCount))
    UIHelper.LayoutDoLayout(UIHelper.GetParent(self.LabelAchievements))

    self:UpdateMonsterReplace()
end

function UIWidgetMonsterBookProgress:UpdateBossInfoList()
    local dwPlayerID = UI_GetClientPlayerID()
    ApplyDungeonRoleProgress(MonsterBookData.PLAY_MAP_ID, dwPlayerID)
    local tBossInfoMap = Table_GetMonsterBossByIndex()
    local tRewardList = Table_GetCalenderActivityAward(MONSTER_ACTIVITY)
    local tScriptRow
    UIHelper.RemoveAllChildren(self.LayoutBossList)
    for dwBossIndex, tMonsterBossList in ipairs(tBossInfoMap) do
        if not tScriptRow then
            tScriptRow = UIHelper.AddPrefab(PREFAB_ID.WidgetBaizhanBossListDoubleCell, self.ScrollViewBossList)
            tScriptRow:ResetData()
        end
        local bHasEmptyCell = tScriptRow:PushData(dwBossIndex, tMonsterBossList)
        if not bHasEmptyCell then
            tScriptRow = nil
        end
    end
    local tRewardInfoList = {}
    for i = 1, #AWARD_TYPE do
		local k = AWARD_TYPE[i]
		local v = tRewardList[k]
		if type(v) == "string" and v ~= "" then	--道具类奖励
			local tInfo     = SplitString(v, ";") or {}
			local dwTabType = tonumber(tInfo[1])
			local dwIndex   = tonumber(tInfo[2])
			local nStackNum = tonumber(tInfo[3])
            table.insert(tRewardInfoList, {
                dwTabType = dwTabType,
                dwIndex = dwIndex,
                nStackNum = nStackNum,
            })
		end
	end
    UIHelper.RemoveAllChildren(self.LayoutReward)
    for _, tAwardInfo in ipairs(tRewardInfoList) do
        local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.LayoutReward)
        if scriptItem then
            scriptItem:OnInitWithTabID(tAwardInfo.dwTabType, tAwardInfo.dwIndex)
            scriptItem:SetLabelCount(tAwardInfo.nStackNum)
            scriptItem:SetClickCallback(function(dwTabType, dwIndex)
                if dwTabType and dwIndex then
                    local tips, tipsView = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, scriptItem._rootNode)
                    tipsView:SetFunctionButtons({})
                    tipsView:OnInitWithTabID(dwTabType, dwIndex)
                end
            end)
            UIHelper.SetToggleGroupIndex(scriptItem.ToggleSelect, ToggleGroupIndex.ReputationRewardItem)
        end
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewBossList)
end

function UIWidgetMonsterBookProgress:FindAchievementCount()
    local nTotalCount, nFinishCount = 0,0

    local fnCustomFilterDataCallback = function()
        AchievementData.SetFilterData_m_dwASceneID_And_m_dwASceneName(MonsterBookData.PLAY_MAP_ID)
    end

    AchievementData.TraverseTree(
        ACHIEVEMENT_PANEL_TYPE.ACHIEVEMENT,
        function(dwGeneral, nAllCount, nAllFinish)

        end,
        function(dwGeneral, tCategory, tCategoryAchievementIDList, nCategoryCount, nCategoryFinish)

        end,
        function(dwGeneral, tCategory, tSubCategory, tSubCategoryAchievementIDList, nSubCategoryCount, nSubCategoryFinish)
            if dwGeneral == ACHIEVEMENT_PANEL_TYPE.ACHIEVEMENT then
                nTotalCount = nTotalCount + nSubCategoryCount
                nFinishCount = nFinishCount + nSubCategoryFinish
            end
        end,
        UI_GetClientPlayerID(),
        fnCustomFilterDataCallback
    )

    return nTotalCount, nFinishCount
end

function UIWidgetMonsterBookProgress:LinkToAchievements()
    local fnCustomFilterDataCallback = function()
        AchievementData.SetFilterData_m_dwASceneID_And_m_dwASceneName(MonsterBookData.PLAY_MAP_ID)
    end

    if UIMgr.IsViewOpened(VIEW_ID.PanelAchievementList, true) then
        UIMgr.CloseWithCallBack(VIEW_ID.PanelAchievementList, function ()
            UIMgr.Open(VIEW_ID.PanelAchievementList, g_pClientPlayer.dwID, fnCustomFilterDataCallback)
        end)
    else
        UIMgr.Open(VIEW_ID.PanelAchievementList, g_pClientPlayer.dwID, fnCustomFilterDataCallback)
    end
end

function UIWidgetMonsterBookProgress:UpdateMonsterReplace()
	local nReplaceRemain = MonsterBookData.GetReplaceRemain()
	local nReplaceTotal  = MonsterBookData.GetReplaceTotal()
	local szText         = FormatString(g_tStrings.STR_MONSTER_SWITCH_BOSS_TIMES, nReplaceRemain, nReplaceTotal)
    UIHelper.SetString(self.LabelGetTips, szText)
end

return UIWidgetMonsterBookProgress