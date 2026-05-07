-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBenefitsView
-- Date: 2024-01-17 14:50:53
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIBenefitsView = class("UIBenefitsView")
local nTabType = 5
local nTabIndex = HuaELouData.WEEK_CHIPS_ITEM_INDEX

function UIBenefitsView:OnEnter(nIndex, bTask)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        UIMgr.Open(VIEW_ID.PanelUID)
        self.bInit = true
    end

    self.bSelToggleBP = nIndex == 2
    self.bTask = bTask

    self:InitPageInfo()
    self:UpdateExpLevelInfo()
    self:UpdateInfo()
end

function UIBenefitsView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Global.SetShowRewardListEnable(VIEW_ID.PanelBenefits, false)
    Global.SetShowLeftRewardTipsEnable(VIEW_ID.PanelBenefits, true)
    Timer.DelAllTimer(self)
    UIMgr.Close(VIEW_ID.PanelUID)
end

function UIBenefitsView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnShenbing, EventType.OnClick, function ()
        if not UIMgr.GetView(VIEW_ID.PanelShenBingUpgrade) then
            UIMgr.Open(VIEW_ID.PanelShenBingUpgrade)
        else
            UIHelper.SetVisible(self._rootNode, false)
        end
    end)

    UIHelper.BindUIEvent(self.BtnIcon, EventType.OnClick, function ()
        local bVisible = UIHelper.GetVisible(self.WidgetRewardTip)
        UIHelper.SetVisible(self.WidgetRewardTip, not bVisible)
        local nHeight = UIHelper.GetHeight(self.WidgetRewardTip)
        UIHelper.SetHeight(self.BtnTipMask, nHeight)
    end)

    UIHelper.BindUIEvent(self.BtnRewardTip, EventType.OnClick, function ()
        TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips, self.BtnRewardTip, g_tStrings.STR_BATTLEPASS_ACCOUNT_LEVEL_RULE)
    end)

    UIHelper.BindUIEvent(self.BtnTipMask, EventType.OnClick, function ()
        TipsHelper.DeleteAllHoverTips(false)
    end)

    UIHelper.BindUIEvent(self.BtnUnlockAccountLevel, EventType.OnClick, function ()
        local nDetailViewID = VIEW_ID.PanelBenefitBPRewardDetail

        if g_pClientPlayer.bHideHat then
            --- 如果设置了隐藏帽子，在这里先暂时取消，等界面关闭时再打开
            PlayerData.HideHat(false)


            Event.Reg(self, EventType.OnViewClose, function(nViewID)
                if nViewID == nDetailViewID then
                    Event.UnReg(self, EventType.OnViewClose)

                    PlayerData.HideHat(true)
                end
            end)
        end

        ---@see UIBenefitBPRewardDetailView
        UIMgr.Open(nDetailViewID)
    end)

    UIHelper.BindUIEvent(self.WidgetBenefitBP, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected and not self.bSelToggleBP then
            self.bSelToggleBP = true
            self:UpdateInfo()
        end
    end)

    UIHelper.BindUIEvent(self.WidgetBenefitFirstPurchase, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected and self.bSelToggleBP then
            self.bSelToggleBP = false
            UIHelper.SetSelected(self.TogReward, true)
            self:UpdateInfo()
        end
    end)

    UIHelper.BindUIEvent(self.WidgetBenefitFirstPurchase, EventType.OnClick, function ()
        local szKey = Table_GetOperActyDes(OPERACT_ID.REAL_FIRST_CHARGE)
        if not APIHelper.IsDid(szKey) then
            APIHelper.Do(szKey)
            UIHelper.SetVisible(self.ImgRedPointNew, false)
            Event.Dispatch(EventType.OnUpdateBenefitsRedPoint)
        end
    end)

    UIHelper.BindUIEvent(self.TogTask, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            Event.Dispatch(EventType.OnEnterBattlePassQuestPanel)
        end
    end)

    UIHelper.BindUIEvent(self.TogReward, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            Event.Dispatch(EventType.OnExitBattlePassQuestPanel)
        end
    end)

    UIHelper.BindUIEvent(self.TogFushi, EventType.OnClick, function (_, bSelected)
        TipsHelper.ShowItemTips(self.TogFushi, nTabType, nTabIndex)
    end)
end

function UIBenefitsView:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function ()
        UIHelper.SetVisible(self.WidgetRewardTip, false)
    end)

    Event.Reg(self, "REMOTE_BATTLEPASS", function ()
        HuaELouData.UpdateExp()
        HuaELouData.UpdateAccountExp()
        self:UpdateExpLevelInfo()
        --GetClientPlayer().ApplySetCollection()
    end)

    Event.Reg(self, "SYNC_NEW_EXT_POINT_END", function ()
        HuaELouData.UpdateExp()
        HuaELouData.UpdateAccountExp()
        self:UpdateExpLevelInfo()
    end)

    Event.Reg(self, "CHANGE_NEW_EXT_POINT_NOTIFY", function ()
        HuaELouData.UpdateExp()
        HuaELouData.UpdateAccountExp()
        self:UpdateExpLevelInfo()
    end)

    Event.Reg(self, EventType.OnViewClose, function (nViewID)
        if nViewID == VIEW_ID.PanelShenBingUpgrade then
            UIHelper.SetVisible(self._rootNode, true)
        end
    end)

    -- 李树钦定，任何自定义进度条弹出都会关闭江湖行记界面
    Event.Reg(self, "DO_CUSTOM_OTACTION_PROGRESS", function()
        UIMgr.Close(self)
    end)
end

function UIBenefitsView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIBenefitsView:InitPageInfo()
    HuaELouData.UpdateExp()
    HuaELouData.UpdateAccountExp()
    Global.SetShowRewardListEnable(VIEW_ID.PanelBenefits, true)
    Global.SetShowLeftRewardTipsEnable(VIEW_ID.PanelBenefits, false)
    local bResult = HuaELouData.GetOperatActRedPoint(OPERACT_ID.REAL_FIRST_CHARGE)
    if not bResult then
        local szKey = Table_GetOperActyDes(OPERACT_ID.REAL_FIRST_CHARGE)
        bResult = not APIHelper.IsDid(szKey)
        UIHelper.SetVisible(self.ImgRedPointNew, bResult)
    end

    if not self.bSelToggleBP then
        UIHelper.SetSelected(self.WidgetBenefitFirstPurchase, true)
        UIHelper.SetSelected(self.WidgetBenefitBP, false)
    else
        if self.bTask then
            UIHelper.SetSelected(self.TogTask, true)
            UIHelper.SetSelected(self.TogReward, false)
        end
    end

    if HuaELouData.bFirstChargeRewardCanDo == false or AppReviewMgr.IsReview() then
        UIHelper.SetVisible(self.WidgetFP, false)
        self.bSelToggleBP = true
    end
end

function UIBenefitsView:UpdateInfo()
    UIHelper.SetVisible(self.WidgetAnchotBPLeftTop, self.bSelToggleBP)
    UIHelper.SetVisible(self.WidgetAnchorBPRightTop, self.bSelToggleBP)
    UIHelper.SetVisible(self.WidgetLevelInfo, self.bSelToggleBP)

    UIHelper.RemoveAllChildren(self.WidgetBPContent)
    if self.bSelToggleBP then
        UIHelper.AddPrefab(PREFAB_ID.WidgetBenefitBPRewardPage, self.WidgetBPContent, self.bTask)
        self.bTask = false
    else
        UIHelper.AddPrefab(PREFAB_ID.WidgetBenefitFirstPurchasePage, self.WidgetBPContent)
    end

    UIHelper.SetVisible(self.LayoutTimeBP, self.bSelToggleBP)
    UIHelper.SetVisible(self.LayoutTimeFirstPurcahase, not self.bSelToggleBP)

    -- BP
    local bIsSystemOpen = SystemOpen.IsSystemOpen(SystemOpenDef.JiangHuXingJiBP)
    local szDesc = SystemOpen.GetSystemOpenDesc(SystemOpenDef.JiangHuXingJiBP)
    local szTitle = SystemOpen.GetSystemOpenTitle(SystemOpenDef.JiangHuXingJiBP)
    UIHelper.SetVisible(self.ImgBPLock, not bIsSystemOpen)
    UIHelper.SetString(self.LabelBPLock, szTitle)
    UIHelper.SetCanSelect(self.WidgetBenefitBP, bIsSystemOpen, szDesc, false)

    if not CommonDef.Activity.UNTIL_SEASON_END then
        local tEndTime = DateToTime(
            CommonDef.Activity.SEASON_END_TIME.nYear, CommonDef.Activity.SEASON_END_TIME.nMonth,
            CommonDef.Activity.SEASON_END_TIME.nDay, CommonDef.Activity.SEASON_END_TIME.nHour,
            CommonDef.Activity.SEASON_END_TIME.nMinute, CommonDef.Activity.SEASON_END_TIME.nSecond)
        local nRemainTime = tEndTime - GetCurrentTime()
        local szRemainTime = UIHelper.GetHeightestTwoTimeText(nRemainTime)
        UIHelper.SetString(self.LabelSeasonEndTime, szRemainTime)
    end
end

function UIBenefitsView:UpdateExpLevelInfo()
    -- 更新账号共享等级
    local nAccountExp         = HuaELouData.nAccountExp
	local nAccountLevel       = HuaELouData.nAccountLevel
	local nAccountPercent     = nAccountExp / HuaELouData.ACCOUNT_EXP_PER_LEVEL * 100
    UIHelper.SetString(self.LabelAccountLevel, string.format("%d/%d", nAccountLevel, HuaELouData.TravelNotes_GetUpperLimitLV()))
	UIHelper.SetProgressBarPercent(self.ProgressBarAccountProgress, nAccountPercent)
    -- 更新历练等级信息
    local nLevel = HuaELouData.GetLevel()
    UIHelper.SetString(self.LabslGradeNum, tostring(nLevel))

    local nExp = HuaELouData.nExpNow
    local nExpLimit = HuaELouData.GetMaxExpLimit()
    local szExpTips = string.format("%d/%d", nExp, nExpLimit)
    UIHelper.SetString(self.LabelExperienceNum, szExpTips)

    local nProgress = nExp/nExpLimit*100
    UIHelper.SetProgressBarPercent(self.ProgressBarGradeProgress, nProgress)

    local szUnlock = string.format("%d/%d", HuaELouData.TravelNotes_GetUpperLimitLV(), HuaELouData.GetMaxLevel())
    UIHelper.SetString(self.LabslUnlockLevel, szUnlock)

    local szWeekChips = string.format("%d/%d", HuaELouData.nWeekChipsNow, HuaELouData.WEEK_CHIPS_LIMIT)
    UIHelper.SetString(self.LabelFushiNum, szWeekChips)
    UIHelper.SetVisible(self.TogFushi, HuaELouData.WEEK_CHIPS_LIMIT_VISIBLE)
    UIHelper.SetVisible(self.BtnShenbing, HuaELouData.WEEK_CHIPS_LIMIT_VISIBLE)
    -- 更新解锁等级共享后可领取的奖励
    UIHelper.SetTouchEnabled(self.BtnIcon, not HuaELouData.IsGrandRewardUnlock())
    UIHelper.SetVisible(self.ImgShareLevelLockBg, not HuaELouData.IsGrandRewardUnlock())
    UIHelper.SetVisible(self.WidgetCharged, HuaELouData.IsGrandRewardUnlock())
    if not HuaELouData.IsGrandRewardUnlock() then
        local nLevel = HuaELouData.nAccountLevel or 0
        local tRewardList = {}
        for i = 0, nLevel do
            local tReward = HuaELouData.tRewardList[i]
            local tRewardDetail = HuaELouData.GetRewardDetatil(tReward.dwSetID2)
            if tRewardDetail and tRewardDetail.AwardItem then
                for nIndex, tItemInfo in pairs(tRewardDetail.AwardItem) do
                    table.insert(tRewardList, {
                        dwTabType = tItemInfo.dwItemType,
                        dwIndex = tItemInfo.dwItemID,
                        nItemAmount = tItemInfo.nItemAmount
                    })
                end
            end
        end
        local nodeParent = self.LayoutRewardListShort
        local bTooMany = #tRewardList > 8
        if bTooMany then
            nodeParent = self.ScrollViewRewardList
        end
        UIHelper.SetVisible(self.LayoutRewardListShort, not bTooMany)
        UIHelper.SetVisible(self.ScrollViewRewardList, bTooMany)
        UIHelper.RemoveAllChildren(self.LayoutRewardListShort)
        UIHelper.RemoveAllChildren(self.ScrollViewRewardList)
        for _, tItemInfo in ipairs(tRewardList) do
            local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetAwardItemSmall, nodeParent, tItemInfo.dwTabType, tItemInfo.dwIndex, tItemInfo.nAmount)
        end
        UIHelper.LayoutDoLayout(self.LayoutRewardListShort)
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewRewardList)
        UIHelper.SetTouchDownHideTips(self.ScrollViewRewardList, false)
    end
    UIHelper.SetTouchDownHideTips(self.BtnTipMask, false)
end

return UIBenefitsView