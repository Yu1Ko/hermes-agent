-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetPageDetail
-- Date: 2026-03-02 10:47:47
-- Desc: 扬刀大会-挑战进度分页-关卡详情 UIWidgetPageDetail (PanelYangDaoOverview/WidgetPageProgress)
-- ---------------------------------------------------------------------------------

local UIWidgetPageDetail = class("UIWidgetPageDetail")

function UIWidgetPageDetail:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self:InitWidgetEnemy()
    end
end

function UIWidgetPageDetail:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetPageDetail:OnInit(tLevelList)
    local _, nLevelProgress, _, _ = ArenaTowerData.GetBaseInfo()
    self.nLevelProgress = nLevelProgress
    self.tLevelList = tLevelList
    self:UpdateInfo()
end

function UIWidgetPageDetail:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnReset, EventType.OnClick, function()
        --实际是每周首通奖励的问号按钮
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.BtnReset, TipsLayoutDir.BOTTOM_LEFT, g_tStrings.ARENA_TOWER_REWARD_TIPS)
    end)
    UIHelper.BindUIEvent(self.BtnRule, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelBattleFieldRulesNew, BATTLE_FIELD_MAP_ID.QING_XIAO_SHAN)
    end)
end

function UIWidgetPageDetail:RegEvent()
    Event.Reg(self, EventType.OnArenaTowerDiffProgressUpdate, function()
        local _, nLevelProgress, _, _ = ArenaTowerData.GetBaseInfo()
        self.nLevelProgress = nLevelProgress
        self:UpdateInfo()
    end)
    Event.Reg(self, EventType.OnArenaTowerOverviewLevelDetail, function(nLevelIndex, bMapFlag)
        self.nLevelIndex = nLevelIndex
        self:UpdateDetail(bMapFlag)
        if nLevelIndex and bMapFlag then
            -- 从总览地图点过来的才调ScrollToIndex
            UIHelper.ScrollToIndex(self.ScrollViewLevelLIst, nLevelIndex - 1)
        end
    end)
    Event.Reg(self, EventType.HideAllHoverTips, function()
        if self.scriptIcon then
            self.scriptIcon:RawSetSelected(false)
            self.scriptIcon = nil
        end
    end)
end

function UIWidgetPageDetail:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetPageDetail:InitWidgetEnemy()
    self.tWidgetEnemy = {}

    local nIndex = 1
    local node = UIHelper.GetChildByName(self.LayoutEnemy, string.format("WidgetEnemy%02d", nIndex))
    while node do
        local tWidgetNode = {
            widgetEnemy = node,
            imgSchool = UIHelper.GetChildByPath(node, string.format("WidgetHead%02d/ImgSchool%02d", nIndex, nIndex)),
            ImgKungfuIcon = UIHelper.GetChildByName(node, string.format("ImgXinFaIcon%02d", nIndex)),
            labelEnemyName = UIHelper.GetChildByName(node, string.format("LabelEnemyName%02d", nIndex)),
        }
        table.insert(self.tWidgetEnemy, tWidgetNode)
        nIndex = nIndex + 1
        node = UIHelper.GetChildByName(self.LayoutEnemy, string.format("WidgetEnemy%02d", nIndex))
    end
end

function UIWidgetPageDetail:UpdateInfo()
    UIHelper.RemoveAllChildren(self.ScrollViewLevelLIst)

    for _, tLevelData in ipairs(self.tLevelList or {}) do
        local nLevelIndex = tLevelData and tLevelData.nLevelIndex or 0
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetYangDaoLevelListCell, self.ScrollViewLevelLIst, nLevelIndex)
        local bCurrent = nLevelIndex == self.nLevelProgress
        local bSpecial = tLevelData and tLevelData.bSpecial or false
        local nLevelState = tLevelData and tLevelData.nLevelState or nil
        script:SetProgressState(nLevelIndex < self.nLevelProgress + 1, nLevelIndex == self.nLevelProgress + 1)
        script:SetLevelState(nLevelState)
        script:SetCurrent(bCurrent)
        script:SetSpecial(bSpecial)
        if nLevelIndex == self.nLevelProgress + 1 then
            script:SetUnlock(true)
        end
        script:SetSelected(self.nLevelIndex == nLevelIndex)
        script:SetSelectedCallback(function()
            Event.Dispatch(EventType.OnArenaTowerOverviewLevelDetail, nLevelIndex)
        end)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewLevelLIst)
end

function UIWidgetPageDetail:UpdateDetail(bMapFlag)
    if not self.nLevelIndex or not self.tLevelList then
        return
    end

    local szBgPath = string.format("Texture\\YangDao\\LevelSceneImgs\\Bg_Level%02d.png", self.nLevelIndex)
    UIHelper.SetTexture(self.ImgPicBg, szBgPath, not bMapFlag)

    local szTitleBgPath = string.format("UIAtlas2_YangDao_YangDaoLevelTitles_Img_%02d", self.nLevelIndex)
    UIHelper.SetSpriteFrame(self.ImgTitleBg, szTitleBgPath)

    local tLevelData = self.tLevelList[self.nLevelIndex] or {}
    local tEnemyInfo = tLevelData.tEnemyInfo
    for i, tWidgetNode in ipairs(self.tWidgetEnemy or {}) do
        local tInfo = tEnemyInfo and tEnemyInfo[i]
        if tInfo then
            UIHelper.SetVisible(tWidgetNode.widgetEnemy, true)
            UIHelper.SetSpriteFrame(tWidgetNode.imgSchool, PlayerForceID2SchoolImg2[tInfo.dwForceID])
            UIHelper.SetSpriteFrame(tWidgetNode.ImgKungfuIcon, PlayerKungfuImg[tInfo.dwKungfuID])
            UIHelper.SetString(tWidgetNode.labelEnemyName, tInfo.szName)
        else
            UIHelper.SetVisible(tWidgetNode.widgetEnemy, false)
        end
    end
    UIHelper.LayoutDoLayout(self.LayoutEnemy)

    local bSpecial = tLevelData.bSpecial or false
    UIHelper.SetVisible(self.WidgetSpecialEvent, bSpecial)

    local nLevelState = tLevelData.nLevelState
    UIHelper.SetVisible(self.LabelPractice_Unfinished, nLevelState == ArenaTowerLevelState.Incomplete)
    UIHelper.SetVisible(self.LabelPractice_Finished, nLevelState ~= ArenaTowerLevelState.Incomplete)
    UIHelper.SetVisible(self.LabelChallenge_Unfinished, nLevelState ~= ArenaTowerLevelState.ChallengeCompleted)
    UIHelper.SetVisible(self.LabelChallenge_Finished, nLevelState == ArenaTowerLevelState.ChallengeCompleted)

    local szPracticeIconPath, szChallengeIconPath = ArenaTowerData.GetDiffIcon(nLevelState)
    UIHelper.SetSpriteFrame(self.ImgIconPractice, szPracticeIconPath)
    UIHelper.SetSpriteFrame(self.ImgIconChallenge, szChallengeIconPath)

    UIHelper.RemoveAllChildren(self.WidgetRewardListPractice)
    UIHelper.RemoveAllChildren(self.WidgetRewardListChallenge)

    local tRewardInfo = tLevelData.tRewardInfo
    local tPracticeRewardInfo = tRewardInfo and tRewardInfo[ArenaTowerDiffMode.Practice] or {}
    local tChallengeRewardInfo = tRewardInfo and tRewardInfo[ArenaTowerDiffMode.Challenge] or {}
    self:UpdateRewardItem(self.WidgetRewardListPractice, tPracticeRewardInfo, nLevelState ~= ArenaTowerLevelState.Incomplete)
    self:UpdateRewardItem(self.WidgetRewardListChallenge, tChallengeRewardInfo, nLevelState == ArenaTowerLevelState.ChallengeCompleted)

    local bHasPracticeReward = #tPracticeRewardInfo > 0
    local bHasChallengeReward = #tChallengeRewardInfo > 0
    UIHelper.SetVisible(self.WidgetRewardPractice, bHasPracticeReward)
    UIHelper.SetVisible(self.WidgetRewardChallenge, bHasChallengeReward)
    UIHelper.SetVisible(self.WidgetWeeklyReward, bHasPracticeReward or bHasChallengeReward)

    UIHelper.LayoutDoLayout(self.LayoutContent)
end

function UIWidgetPageDetail:UpdateRewardItem(parent, tRewardInfo, bItemReceived)
    if not parent then
        return
    end

    UIHelper.RemoveAllChildren(parent)
    tRewardInfo = tRewardInfo or {}
    for _, tItem in ipairs(tRewardInfo) do
        local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, parent)
        if tItem[1] == "COIN" then
            local szCurrencyType = tItem[2]
            local nCount = tItem[3]
            itemScript:OnInitCurrency(szCurrencyType, nCount)
            itemScript:SetLabelCount(nCount)
            itemScript:SetSelectChangeCallback(function(nItemID, bSelected, nTabType, nTabID)
                if bSelected then
                    local tips, scriptTip = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, itemScript._rootNode, TipsLayoutDir.LEFT_CENTER)
                    scriptTip:OnInitCurrency(szCurrencyType, nCount)
                    self.scriptIcon = itemScript
                else
                    self.scriptIcon = nil
                end
            end)
        else
            local dwTabType = tItem[1]
            local dwIndex = tItem[2]
            local nCount = tItem[3]
            itemScript:OnInitWithTabID(dwTabType, dwIndex)
            itemScript:SetLabelCount(nCount)
            itemScript:ShowNowIcon(true)
            itemScript:SetNowDesc("概率")
            itemScript:SetSelectChangeCallback(function(nItemID, bSelected, nTabType, nTabID)
                if bSelected then
                    local tips, scriptTip = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, itemScript._rootNode, TipsLayoutDir.LEFT_CENTER)
                    scriptTip:OnInitWithTabID(dwTabType, dwIndex)
                    self.scriptIcon = itemScript
                else
                    self.scriptIcon = nil
                end
            end)
        end

        itemScript:SetEnable(true)
        itemScript:SetItemReceived(bItemReceived)
    end
    UIHelper.LayoutDoLayout(parent)
end

return UIWidgetPageDetail