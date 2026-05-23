local UIWidgetMonsterBookSEIntroductionCell = class("UIWidgetMonsterBookSEIntroductionCell")

function UIWidgetMonsterBookSEIntroductionCell:OnEnter(tSEInfo, fCallBack)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.fCallBack = fCallBack
    self:UpdateInfo(tSEInfo)
end

function UIWidgetMonsterBookSEIntroductionCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMonsterBookSEIntroductionCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogCell, EventType.OnSelectChanged, function (_, bSelected)
        UIHelper.SetVisible(self.WidgetUpgrade, self.nMinLevel < MonsterBookData.MAX_CMP_LEVEL)
        UIHelper.SetVisible(self.WidgetDetail, bSelected)
        UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
        self.fCallBack(self, bSelected)
        UIHelper.SetHeight(self.TogCell, 60)
    end)

    UIHelper.BindUIEvent(self.BtnUpgrade, EventType.OnClick, function ()
        self:UpgradeAllSkill()
    end)
end

function UIWidgetMonsterBookSEIntroductionCell:RegEvent()
    -- Event.Reg(self, "ON_UPDATE_SKILL_COLLECTION", function ()
    --     self:UpdateInfo(self.tSEInfo)
    -- end)

    -- Event.Reg(self, "REMOTE_IMPARTSKILL_EVENT", function ()
    --     self:UpdateInfo(self.tSEInfo)
    -- end)
end

function UIWidgetMonsterBookSEIntroductionCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetMonsterBookSEIntroductionCell:UpdateInfo(tSEInfo)
    self.tSEInfo = tSEInfo
    self.dwBossID = tSEInfo.dwBossID
    self.nMinLevel = tSEInfo.nMinLevel
    local nDstLevel = tSEInfo.nMinLevel + 1
    if nDstLevel > MonsterBookData.MAX_SKILL_LEVEL then nDstLevel = MonsterBookData.MAX_SKILL_LEVEL end
    
    local nCurProgress = 0
    UIHelper.RemoveAllChildren(self.WidgetContent)
    for _, tSkillInfo in ipairs(tSEInfo.tCollectSkill) do
        UIHelper.AddPrefab(PREFAB_ID.WidgetJingNaiBossSkillCell, self.WidgetContent, tSkillInfo.dwSkillID, tSkillInfo.nLevel)
        if tSkillInfo.nLevel == 0 then nDstLevel = 1 end
    end

    for _, tSkillInfo in ipairs(tSEInfo.tCollectSkill) do
        if tSkillInfo.nLevel >= nDstLevel then nCurProgress = nCurProgress + 1 end
    end

    local szLevel = MonsterBookData.GetLevelText(nDstLevel)
    local szProgress = string.format("%d/%d", nCurProgress, tSEInfo.nTotalProgress)
    local szSpirit = string.format("+%d", tSEInfo.nExtraSpiritValue)
    local szEndurance = string.format("+%d", tSEInfo.nExtraEnduranceValue)

    UIHelper.SetString(self.LabelBossName, tSEInfo.szBossName)
    UIHelper.SetString(self.LabelMinLevel, szLevel)
    UIHelper.SetString(self.LabelBossLevel, szLevel)
    UIHelper.SetString(self.LabelRewardProgress, szProgress)
    UIHelper.SetString(self.LabelJingshen, szSpirit)
    UIHelper.SetString(self.LabelNaili, szEndurance)

    UIHelper.SetVisible(self.WidgetUpgrade, self.nMinLevel < MonsterBookData.MAX_CMP_LEVEL)
end

function UIWidgetMonsterBookSEIntroductionCell:UpgradeAllSkill()
    local nDstLevel = self.nMinLevel + 1
    local szTextNum, szBookName = MonsterBookData.GetActiveBookCost(nDstLevel)
    local szMessage = string.format("是否确定使用%s将该首领的招式全收集进度提高一重？", szBookName)
    UIHelper.ShowConfirm(szMessage, function ()
        RemoteCallToServer("On_MonsterBook_BossSkillLevelUp", self.dwBossID)
        UIMgr.Close(VIEW_ID.PanelJingShenNaiLiDetailPop)
    end)
end

return UIWidgetMonsterBookSEIntroductionCell