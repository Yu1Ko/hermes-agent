-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIPVPCampView
-- Date: 2023-02-23 19:59:40
-- Desc: PanelPVPCamp 已弃用，改为UIWidgetCamp
-- ---------------------------------------------------------------------------------

local UIPVPCampView = class("UIPVPCampView")

--战阶图标
local function GetCampTitleImgPath(nCamp, nTitle)
    if nCamp == CAMP.GOOD then
        return string.format("UIAtlas2_Pvp_HaoQi_icon_Badge_%02d.png", nTitle)
    elseif nCamp == CAMP.EVIL then
        return string.format("UIAtlas2_Pvp_ERen_icon_Badge_%02d.png", nTitle)
    end
end

local tImgCampBg = {
    [CAMP.GOOD] = "UIAtlas2_Pvp_PVPCamp2_bg_justice.png",
    [CAMP.EVIL] = "UIAtlas2_Pvp_PVPCamp2_bg_evil.png"
}

local tImgFlagBg = {
    [CAMP.GOOD] = "UIAtlas2_Pvp_PVPCamp2_flag_justice.png",
    [CAMP.EVIL] = "UIAtlas2_Pvp_PVPCamp2_flag_evil.png"
}

local tImgCampFlagBg = {
    [CAMP.GOOD] = "UIAtlas2_Pvp_PVPCamp2_img_JusticeBg.png",
    [CAMP.EVIL] = "UIAtlas2_Pvp_PVPCamp2_img_EvilBg.png"
}

local REWARD_MAX_COUNT = 500 -- 奖励的最大人数
local REWARD_MIN_POINT = 5000 -->=5000，才有战阶奖励

local RICHTEXT_COLOR = "#ffd778"

function UIPVPCampView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:InitUI()
    self:UpdateInfo()
    self:CloseTips()

    Timer.AddFrameCycle(self, 1, function()
        self:OnUpdate()
    end)
end

function UIPVPCampView:OnExit()
    self.bInit = false
    self:UnRegEvent()

    self:CloseTips()
    UIMgr.Close(VIEW_ID.PanelPvPCampMorale)
    UIMgr.Close(VIEW_ID.PanelPvPCampReward)
    UIMgr.Close(VIEW_ID.PanelPvPCampJoin)
    UIMgr.Close(VIEW_ID.PanelPvPCampRankReward)
    UIMgr.Close(VIEW_ID.PanelCampMap)
end

function UIPVPCampView:OnUpdate()
    local nCurrentTime = GetCurrentTime()
    local tData = TimeToDate(nCurrentTime)
    if tData.weekday == 6 or tData.weekday == 0 then
        local szText, szTime = CampData.GetActiveTimeText()
        if szText and szTime then
            UIHelper.SetString(self.LabelWordTime, szText)
            UIHelper.SetString(self.LabelWordTimeData, szTime)
        end

        UIHelper.SetVisible(self.LabelWordTime, true)
        UIHelper.SetVisible(self.LabelWordTimeData, true)
    else
        UIHelper.SetVisible(self.LabelWordTime, false)
        UIHelper.SetVisible(self.LabelWordTimeData, false)
    end
end

function UIPVPCampView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
    UIHelper.BindUIEvent(self.BtnStageReward, EventType.OnClick, function()
        self:CloseTips()
        UIMgr.Open(VIEW_ID.PanelPvPCampReward)
    end)
    UIHelper.BindUIEvent(self.BtnStageStore, EventType.OnClick, function()
        self:CloseTips()
        UIHelper.SetVisible(self.WidgetAnchorLeaveFor, true)
    end)
    UIHelper.BindUIEvent(self.BtnLastDataReward, EventType.OnClick, function()
        self:CloseTips()

        if self.tRewardInfo then
            UIMgr.Open(VIEW_ID.PanelPvPCampRankReward, self.tRewardInfo)
        end
    end)
    UIHelper.BindUIEvent(self.BtnPrestige, EventType.OnClick, function()
        self:CloseTips()
        UIHelper.SetVisible(self.WidgetPrestigeTip, true)
    end)
    UIHelper.BindUIEvent(self.BtnPrestigeExtra, EventType.OnClick, function()
        self:CloseTips()
        UIHelper.SetVisible(self.WidgetPrestigeExtraTip, true)
    end)
    UIHelper.BindUIEvent(self.BtnCampMorale, EventType.OnClick, function()
        self:CloseTips()
        UIMgr.Open(VIEW_ID.PanelPvPCampMorale)
    end)
    UIHelper.BindUIEvent(self.WidgetStageIcon ,EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelHelpPop, 4)
    end)
    UIHelper.BindUIEvent(self.LayoutMoney, EventType.OnClick, function()
        CurrencyData.ShowCurrencyHoverTipsInDir(self.LayoutMoney, TipsLayoutDir.BOTTOM_CENTER, CurrencyType.TitlePoint)
    end)
    UIHelper.SetTouchEnabled(self.LayoutMoney, true)
end

function UIPVPCampView:RegEvent()
    Event.Reg(self, "On_CAMP_GETTITLEPOINTRANKINFO", function(tInfo)
        print("[Camp] On_CAMP_GETTITLEPOINTRANKINFO")
        self:OnGetTitlePointRankInfo(tInfo)
    end)
    Event.Reg(self, "On_CAMP_GETTITLEPOINTRANKREWARD", function()
        print("[Camp] On_CAMP_GETTITLEPOINTRANKREWARD")
        if self.tRewardInfo then
            self.tRewardInfo.bCanReceive = false
        end
        self:UpdateRewardState()
    end)
    Event.Reg(self, "UPDATE_CAMP_INFO", function()
        print("[Camp] UPDATE_CAMP_INFO")
        self:UpdateInfo()
    end)
    Event.Reg(self, EventType.OnTouchViewBackGround, function()
        self:CloseTips()
    end)
    Event.Reg(self, EventType.OnWindowsSizeChanged, function (szName)
        UIHelper.ScrollViewDoLayout(self.ScrollViewCampActivity)
        UIHelper.ScrollToTop(self.ScrollViewCampActivity, 0)
    end)
end

function UIPVPCampView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIPVPCampView:InitUI()
    UIHelper.RemoveAllChildren(self.WidgetPvPCampActivityList)

    UIMgr.AddPrefab(PREFAB_ID.WidgetPvPCampActivityList, self.ScrollViewCampActivity, CampFuncType.Activity, self)          --活动日历
    UIMgr.AddPrefab(PREFAB_ID.WidgetPvPCampActivityList, self.ScrollViewCampActivity, CampFuncType.CampMaps, self)          --战争沙盘
    UIMgr.AddPrefab(PREFAB_ID.WidgetPvPCampActivityList, self.ScrollViewCampActivity, CampFuncType.SwitchServerPK, self)    --千里伐逐
    UIMgr.AddPrefab(PREFAB_ID.WidgetPvPCampActivityList, self.ScrollViewCampActivity, CampFuncType.RankList, self)          --阵营英雄五十强
    UIMgr.AddPrefab(PREFAB_ID.WidgetPvPCampActivityList, self.ScrollViewCampActivity, CampFuncType.BigThing, self)          --阵营大事记

    UIHelper.CascadeDoLayoutDoWidget(self.LayoutCampActivityToggle, true, true)
    UIHelper.ScrollViewDoLayout(self.ScrollViewCampActivity)
    UIHelper.ScrollToTop(self.ScrollViewCampActivity, 0)

    --适配中上两个按钮的大小和位置
    local parent = UIHelper.GetParent(self.BtnPrestige)
    local nParentWidth, _ = UIHelper.GetContentSize(parent)
    local _, nHeight = UIHelper.GetContentSize(self.BtnPrestige)
    local nWidth = nParentWidth / 2
    local nX = nParentWidth / 4

    UIHelper.SetContentSize(self.BtnPrestigeExtra, nWidth, nHeight)
    UIHelper.SetContentSize(self.BtnPrestige, nWidth, nHeight)
    UIHelper.SetPositionX(self.BtnPrestigeExtra, -nX)
    UIHelper.SetPositionX(self.BtnPrestige, nX)
    UIHelper.WidgetFoceDoAlign(self)
end

function UIPVPCampView:UpdateInfo()
    local hPlayer = GetClientPlayer()
    if not hPlayer then return end

    local nCamp = hPlayer.nCamp

    if nCamp == CAMP.NEUTRAL then
        UIMgr.Open(VIEW_ID.PanelPvPCampJoin)
        return
    end

    --阵营 变色
    local szCampImg = tImgCampBg[nCamp]
    UIHelper.SetSpriteFrame(self.ImgCamp, szCampImg)

    local szImgFlagBg = tImgFlagBg[nCamp]
    UIHelper.SetSpriteFrame(self.ImgFlagBg, szImgFlagBg)

    local szImgCampFlagBg = tImgCampFlagBg[nCamp]
    UIHelper.SetSpriteFrame(self.ImgCampFlagBg, szImgCampFlagBg)

    UIHelper.SetVisible(self.ImgSliderExperienceGood, nCamp == CAMP.GOOD)
    UIHelper.SetVisible(self.ImgSliderExperienceEvil, nCamp == CAMP.EVIL)
    
    --威名点
    local nLimit = hPlayer.GetPrestigeRemainSpace() --本周还可获得威名点
    local nCurrentPrestige = hPlayer.nCurrentPrestige --当前威名点
    local nTotal = nCurrentPrestige + nLimit --本周可获得最大威名点
    local nMaxPrestige = hPlayer.GetMaxPrestige() --最大威名点
    nTotal = math.min(nTotal, nMaxPrestige)

    UIHelper.SetRichText(self.LabelNum, string.format("<color=%s>%d</color>/%d", RICHTEXT_COLOR, nCurrentPrestige, nMaxPrestige))
    UIHelper.SetString(self.LabelPrestigeRange, g_tStrings.STR_CURRENCY_REMAIN_GET .. nLimit)
    UIHelper.SetProgressBarPercent(self.ProgressBarGradeProgress, 100 * hPlayer.nCurrentPrestige / nMaxPrestige)
    UIHelper.SetProgressBarPercent(self.ProgressBarGradeExtraProgress, 100 * nTotal /  nMaxPrestige)

    UIHelper.SetString(self.LabelNum1, tostring(hPlayer.nTitlePoint)) --战阶积分

    --威名点周上限
    local nMaxExtSpace = hPlayer.GetInitPrestigeMaxExtSpace() --最大周上限
    local nExtSpace = hPlayer.GetPrestigeMaxExtSpace() --可获得周上限
    local nNowExtSpace = nMaxExtSpace - hPlayer.GetPrestigeMaxExtSpace() --当前周上限
    UIHelper.SetRichText(self.LabelExtraNum, string.format("<color=%s>%d</color>/%d", RICHTEXT_COLOR, nNowExtSpace, nMaxExtSpace))
    UIHelper.SetString(self.LabelPrestigeExtraRange, g_tStrings.STR_CURRENCY_REMAIN_GET .. nExtSpace)
    UIHelper.SetProgressBarPercent(self.ProgressBarExtraProgress, 100 * nNowExtSpace / nMaxExtSpace)

    local nKillCount = hPlayer.dwKillCount -- 伤敌人数
    local nBestAssistKilledCount = hPlayer.dwBestAssistKilledCount --最佳助攻
    UIHelper.SetString(self.LabelKillData, tostring(nKillCount))
    UIHelper.SetString(self.LabelHelpData, tostring(nBestAssistKilledCount))

    --On_CAMP_GETTITLEPOINTRANKINFO，显示奖励和上周分数、排名等
    UIHelper.SetString(self.LabelLastData, "")
    UIHelper.SetString(self.LabelRank, "")
    UIHelper.SetNodeGray(self.BtnLastDataReward, true, true)
    UIHelper.SetVisible(self.ImgRedPoint, false)
    RemoteCallToServer("On_Camp_GetTitlePointRequest")

    local nTitle = hPlayer.nTitle -- 当前战阶
    local szTitleLevel, szTitle, szTitleBuff = CampData.GetPlayerTitleDesc(nTitle)
    --local nNextTitle = nTitle + 1
    --local szNextTitleLevel, szNextTitle, szNextTitleBuff = CampData.GetPlayerTitleDesc(nNextTitle)
    local szNeedTitlePoint, szNeedPointRank = "", ""
    if nTitle < 7 then
        local nNeedPoint = Table_GetNextTitleRankPoint(nTitle)
        szNeedTitlePoint, szNeedPointRank = tostring(nNeedPoint), g_tStrings.STR_NONE
    else
        local nNeedPoint = GetNextTitleNeedPoint(nTitle)
        szNeedTitlePoint, szNeedPointRank = g_tStrings.STR_NONE, tostring(nNeedPoint)
    end
    local fPointPercentage = hPlayer.GetRankPointPercentage()
    if fPointPercentage < 0 then
        fPointPercentage = 0
    end
    if fPointPercentage > 100 then
        fPointPercentage = 100
    end
    --local szTip = string.pure_text(UIHelper.GBKToUTF8(Table_GetTitleRankTip(nTitle)))
    --local szNextTip = string.pure_text(UIHelper.GBKToUTF8(Table_GetTitleRankTip(nNextTitle)))

    UIHelper.SetString(self.LabelPercentage, fPointPercentage .. "%")
    UIHelper.SetProgressBarPercent(self.ImgSliderExperienceGood, fPointPercentage)
    UIHelper.SetProgressBarPercent(self.ImgSliderExperienceEvil, fPointPercentage)
    UIHelper.SetSpriteFrame(self.ImgGradeIcon, GetCampTitleImgPath(nCamp, nTitle))
    if nTitle > 0 then
        UIHelper.SetString(self.LabelCampStage, szTitleLevel .. "·" .. szTitle)
    else
        UIHelper.SetString(self.LabelCampStage, "当前战阶   无")
    end

    --世界战阶
    local nWorldTitleLevel = On_CampGetWorldTitleLv() --"scripts/Include/UIscript/UIscript_Camp.lua"
    if nWorldTitleLevel then
        local szText = FormatString(g_tStrings.CAMP_TITLE_LEVEL, nWorldTitleLevel)
        UIHelper.SetString(self.LabelWordStageData, szText)
    else
        UIHelper.SetString(self.LabelWordStageData, "无")
    end

    local nLinkID = nil
    if nCamp == CAMP.GOOD then
        nLinkID = 2331
    elseif nCamp == CAMP.EVIL then
        nLinkID = 2330
    end
    if nLinkID then
        local tTargetList = clone(Table_GetCareerGuideAllLink(nLinkID))
        local scriptView = UIHelper.GetBindScript(self.WidgetAnchorLeaveFor)
        if scriptView then
            scriptView:OnEnter(tTargetList)
        end
    end

    --士气条
    local nGoodCampScore, nEvilCampScore, fPercentage = CampData.GetMoraleInfo()
    UIHelper.SetProgressBarPercent(self.ProgressBarMoraleProgress, 100 * fPercentage)
    UIHelper.SetString(self.LabelJusticeNum, tostring(nGoodCampScore))
    UIHelper.SetString(self.LabelEvilNum, tostring(nEvilCampScore))

    local nWidth, _ = UIHelper.GetContentSize(self.ProgressBarMoraleProgress)

    local nLeft, nRight = -nWidth / 2 + 9.5, nWidth / 2 + 2.5
    local nPosX = nLeft + (nRight - nLeft) * fPercentage
    UIHelper.SetPositionX(self.ImgBarBg02, nPosX)

    --TODO 上周胜者
    local hCampInfo = GetCampInfo()
    local nLastWinCamp = hCampInfo.nLastWinCamp
    local szWinner = g_tStrings.tCampMapsWinner[nLastWinCamp]
end

function UIPVPCampView:UpdateRewardState()
    local bCanReceive = self.tRewardInfo and self.tRewardInfo.bCanReceive or false
    local nRank = self.tRewardInfo and self.tRewardInfo.nRank or 501
    local nLastPoint = self.tRewardInfo and self.tRewardInfo.nLastPoint or 0

    UIHelper.SetNodeGray(self.BtnLastDataReward, not bCanReceive, true)
    UIHelper.SetVisible(self.ImgRedPoint, bCanReceive)

    local szText
    if bCanReceive then
        szText = string.format("<color=%s>%s</color>", RICHTEXT_COLOR, "未领取")
    elseif nRank and nLastPoint then
        if nRank <= REWARD_MAX_COUNT or nLastPoint >= REWARD_MIN_POINT then
            szText = string.format("<color=%s>%s</color>", RICHTEXT_COLOR, "已领取")
        elseif nRank > REWARD_MAX_COUNT and nLastPoint < REWARD_MIN_POINT then
            szText = "未达到领取标准"
        end
    end
    szText = szText or ""
    UIHelper.SetRichText(self.LabelRewardState, "奖励详情：" .. szText)
end

function UIPVPCampView:OnGetTitlePointRankInfo(tInfo)
    if not tInfo then return end

    print("[Camp] OnGetTitlePointRankInfo", tInfo.TitlePoint, tInfo.Receive, tInfo.Rank)

    self.tRewardInfo = tInfo

    UIHelper.SetString(self.LabelLastData, tInfo.TitlePoint)
    if tInfo.Rank > REWARD_MAX_COUNT then
        UIHelper.SetString(self.LabelRank, "(" .. REWARD_MAX_COUNT .. g_tStrings.RANK_DISPLAY .. ")")
    else
        UIHelper.SetString(self.LabelRank, "(第" .. tInfo.Rank .. "名)")
    end

    self:UpdateRewardState()
end

function UIPVPCampView:CloseTips()
    UIHelper.SetVisible(self.WidgetPrestigeTip, false)
    UIHelper.SetVisible(self.WidgetPrestigeExtraTip, false)
    UIHelper.SetVisible(self.WidgetAnchorLeaveFor, false)
    UIHelper.SetVisible(self.WidgetLastDataRewardTip, false)
    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
end

return UIPVPCampView