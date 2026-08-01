-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetCamp
-- Date: 2023-12-15 16:11:11
-- Desc: ?
-- ---------------------------------------------------------------------------------
local FuncList = {
    [1] = function()
        if CheckPlayerIsRemote() then
            return
        end

        local player = GetClientPlayer()
        if not player then
            return
        end

        if player.nCamp == CAMP.NEUTRAL then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_OPEN_CAMPMAPS_LIMIT)
            return
        end

        UIMgr.Open(VIEW_ID.PanelCampMap)
    end,
    [2] = function()
        UIMgr.Open(VIEW_ID.PanelQianLiFaZhu)
    end,
    [3] = function()
        UIMgr.Open(VIEW_ID.PanelFengYunLu, FengYunLuCategory.Normal, 5) --打开风云录界面，并选中个人排名-阵营英雄五十强
    end,
    [4] = function()
        UIMgr.Open(VIEW_ID.PanelPVPCampCampaign)
    end,
}

local function GetCampTitleImgPath(nCamp, nTitle)
    if nCamp == CAMP.GOOD then
        return string.format("UIAtlas2_Pvp_HaoQi_icon_Badge_%02d.png", nTitle)
    elseif nCamp == CAMP.EVIL then
        return string.format("UIAtlas2_Pvp_ERen_icon_Badge_%02d.png", nTitle)
    end
end

local RICHTEXT_COLOR = "#ffd778"
local REWARD_MAX_COUNT = 500 -- 奖励的最大人数
local REWARD_MIN_POINT = 5000 -->=5000，才有战阶奖励

local UIWidgetCamp = class("UIWidgetCamp")

function UIWidgetCamp:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.bOpen = false
end

function UIWidgetCamp:Open()
    if not self.bOpen then
        self.bOpen = true
        self:Init()
        if self.FuncLink then self.FuncLink() end
        self.nTimer = Timer.AddFrameCycle(self, 2, function()
            self:UpdateArrow()
            self:UpdateTime()
        end)
    end
end

function UIWidgetCamp:OnExit()
    self.bInit = false
    self:UnRegEvent()
    if self.nTimer then
        Timer.DelTimer(self, self.nTimer)
    end
end

function UIWidgetCamp:BindUIEvent()
    for nIndex, btn in ipairs(self.tbBtnList) do
        UIHelper.BindUIEvent(btn, EventType.OnClick, function()
            local func = FuncList[nIndex]
            func()
        end)
    end

    UIHelper.BindUIEvent(self.BtnCampMorale, EventType.OnClick, function()
        self:CloseTips()
        UIMgr.Open(VIEW_ID.PanelPvPCampMorale)
    end)

    UIHelper.BindUIEvent(self.BtnStageReward, EventType.OnClick, function()
        self:CloseTips()
        UIMgr.Open(VIEW_ID.PanelPvPCampReward)
    end)

    UIHelper.BindUIEvent(self.BtnLastDataReward, EventType.OnClick, function()
        self:CloseTips()
        local tRewardInfo = CampData.GetTitlePointRankRewardInfo()
        if tRewardInfo then
            UIMgr.Open(VIEW_ID.PanelPvPCampRankReward, tRewardInfo)
        end
    end)

    UIHelper.BindUIEvent(self.WidgetStageIcon, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelHelpPop, 4)
    end)

    UIHelper.BindUIEvent(self.BtnData, EventType.OnClick, function()
        local szName, szType = CampData.GetDesignationInfo()--当前佩戴的
        local szTitle = self:GetTitle()
        if szTitle == szName then
            TipsHelper.ShowNormalTip("已佩戴当前称号")
        else
            CollectionData.ApplyDesignation()
        end
    end)

    UIHelper.BindUIEvent(self.BtnProfileLeader, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelCollectionDungeon)
    end)

    UIHelper.BindUIEvent(self.BtnPageUp, EventType.OnClick, function()
        UIHelper.ScrollToLeft(self.ScrollViewCamp)
    end)

    UIHelper.BindUIEvent(self.BtnPageDown, EventType.OnClick, function()
        UIHelper.ScrollToRight(self.ScrollViewCamp)
    end)

    UIHelper.BindUIEvent(self.BtnSeasonChallage, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelSeasonChallenge, HONOR_CHALLENGE_PAGE.ATHLETICS)
    end)
end

function UIWidgetCamp:RegEvent()
    Event.Reg(self, EventType.OnTouchViewBackGround, function()
        self:CloseTips()
    end)

    Event.Reg(self, "On_CAMP_GETTITLEPOINTRANKINFO", function()
        self:OnGetTitlePointRankInfo()
    end)
    Event.Reg(self, "On_CAMP_GETTITLEPOINTRANKREWARD", function()
        self:UpdateRewardState()
    end)
    Event.Reg(self, "UPDATE_CAMP_INFO", function()
        self:UpdateInfo()
    end)
    Event.Reg(self, "UPDATE_PRESTIGE", function()
        self:UpdateInfo()
    end)

    Event.Reg(self, "SET_CURRENT_DESIGNATION", function(dwPlayerID, nPrefix, nPostfix, bBynameDisplay)
        if dwPlayerID == g_pClientPlayer.dwID then
            local szTitle = self:GetTitle()
            local szTip = "佩戴".. szTitle .."成功"
            TipsHelper.ShowNormalTip(szTip)
        end
    end)
end

function UIWidgetCamp:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetCamp:GetTitle()
    local nTitle = g_pClientPlayer.nTitle
    local szTitleLevel, szTitle = CampData.GetPlayerTitleDesc(nTitle)
    return szTitle
end

function UIWidgetCamp:UpdateArrow()
    local nPercent = UIHelper.GetScrollPercent(self.ScrollViewCamp)
    local bShowLeft = nPercent >= 10
    local bShowRight = nPercent <= 90

    local nWidth = UIHelper.GetWidth(self.ScrollViewCamp)
    local tbSize = self.ScrollViewCamp:getInnerContainerSize()
    UIHelper.SetVisible(self.WidgetArrowLeft, bShowLeft and tbSize.width > nWidth)
    UIHelper.SetVisible(self.WidgetArrowRight, bShowRight and tbSize.width > nWidth)
end

function UIWidgetCamp:Init()

    self:InitData()

    self:UpdateInfo()
    self:UpdateCardList()
    self:UpdateSeasonLevelInfo()
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetCamp:UpdateTime()
    local nCurrentTime = GetCurrentTime()
    local tData = TimeToDate(nCurrentTime)
    if tData.weekday == 6 or tData.weekday == 0 then
        local szText, szTime = CampData.GetActiveTimeText()
        if szText and szTime then
            UIHelper.SetString(self.LabelWordTime, szText)
            UIHelper.SetString(self.LabelWordTimeData, szTime)
        end
        UIHelper.SetVisible(self.WidgetCampWarTime, true)
    else
        UIHelper.SetVisible(self.WidgetCampWarTime, false)
    end
end

function UIWidgetCamp:UpdateInfo()
    local player = g_pClientPlayer
    if not player then
        return
    end

    local nCamp = player.nCamp
    local fPointPercentage = player.GetRankPointPercentage()
    if fPointPercentage < 0 then
        fPointPercentage = 0
    end
    if fPointPercentage > 100 then
        fPointPercentage = 100
    end


    local nTitle = player.nTitle -- 当前战阶
    local szTitleLevel, szTitle, szTitleBuff = CampData.GetPlayerTitleDesc(nTitle)
    if nTitle > 0 then
        UIHelper.SetString(self.LabelCampStage, szTitleLevel .. "·" .. szTitle)
    else
        UIHelper.SetString(self.LabelCampStage, "当前战阶   无")
    end

    UIHelper.SetString(self.LabelPercentage, fPointPercentage .. "%")
    UIHelper.SetVisible(self.LabelPercentage, nTitle ~= 14)--满战阶隐藏百分比

    UIHelper.SetSpriteFrame(self.ImgGradeIcon, GetCampTitleImgPath(nCamp, nTitle))

    local szTitleLevel, szTitle = CampData.GetPlayerTitleDesc(nTitle)
    UIHelper.SetString(self.LabelTitle, szTitle)


    --世界战阶
    local nWorldTitleLevel = On_CampGetWorldTitleLv() --"scripts/Include/UIscript/UIscript_Camp.lua"
    if nWorldTitleLevel then
        local szText = FormatString(g_tStrings.CAMP_TITLE_LEVEL, nWorldTitleLevel)
        UIHelper.SetString(self.LabelWordStageData, szText)
    else
        UIHelper.SetString(self.LabelWordStageData, "无")
    end

    local nKillCount = player.dwKillCount -- 伤敌人数
    local nBestAssistKilledCount = player.dwBestAssistKilledCount --最佳助攻
    UIHelper.SetString(self.LabelKillData, tostring(nKillCount))
    UIHelper.SetString(self.LabelHelpData, tostring(nBestAssistKilledCount))


    UIHelper.SetString(self.LabelNowData, tostring(player.nTitlePoint))


    --士气条
    local nGoodCampScore, nEvilCampScore, fPercentage = CampData.GetMoraleInfo()
    UIHelper.SetProgressBarPercent(self.ProgressBarMoraleProgress, 100 * fPercentage)
    UIHelper.SetString(self.LabelJusticeNum, tostring(nGoodCampScore))
    UIHelper.SetString(self.LabelEvilNum, tostring(nEvilCampScore))

    local nWidth, _ = UIHelper.GetContentSize(self.ProgressBarMoraleProgress)

    local nLeft, nRight = -nWidth / 2 + 9.5, nWidth / 2 + 2.5
    local nPosX = nLeft + (nRight - nLeft) * fPercentage
    UIHelper.SetPositionX(self.ImgBarBg02, nPosX)

    local szTitleLevel, szTitle = CampData.GetPlayerTitleDesc(nTitle)



    self:OnGetTitlePointRankInfo()

    local nCurrentPrestige = player.nCurrentPrestige
end

function UIWidgetCamp:OnGetTitlePointRankInfo()
    local tInfo = CampData.GetTitlePointRankRewardInfo()
    if not tInfo then return end

    LOG.INFO("[Camp] OnGetTitlePointRankInfo %s %s %s", tostring(tInfo.TitlePoint), tostring(tInfo.Receive), tostring(tInfo.Rank))


    UIHelper.SetString(self.LabelLastData, tInfo.TitlePoint)
    if tInfo.Rank > REWARD_MAX_COUNT then
        UIHelper.SetString(self.LabelRank, "(" .. REWARD_MAX_COUNT .. g_tStrings.RANK_DISPLAY .. ")")
    else
        UIHelper.SetString(self.LabelRank, "(第" .. tInfo.Rank .. "名)")
    end
    UIHelper.LayoutDoLayout(self.LayoutDate)
    self:UpdateRewardState()
end

function UIWidgetCamp:UpdateRewardState()
    local tRewardInfo = CampData.GetTitlePointRankRewardInfo()
    local bCanReceive = tRewardInfo and tRewardInfo.Receive or false
    local nRank = tRewardInfo and tRewardInfo.nRank or 501
    local nLastPoint = tRewardInfo and tRewardInfo.nLastPoint or 0

    -- UIHelper.SetNodeGray(self.BtnLastDataReward, not bCanReceive, true)
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


function UIWidgetCamp:CloseTips()
    -- UIHelper.SetVisible(self.WidgetAnchorLeaveFor, false)
    UIHelper.SetVisible(self.WidgetLastDataRewardTip, false)
    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
end

function UIWidgetCamp:UpdateCardList()
    local tbCardList = self.tbCardList
    if tbCardList and #tbCardList then
        UIHelper.RemoveAllChildren(self.ScrollViewCamp)
    end

    for nIndex, tbcardInfo in ipairs(tbCardList) do
        UIHelper.AddPrefab(PREFAB_ID.WidgetRoafCardCell, self.ScrollViewCamp, tbcardInfo)
    end
    UIHelper.ScrollViewDoLayout(self.ScrollViewCamp)
    UIHelper.ScrollToLeft(self.ScrollViewCamp)
end


function UIWidgetCamp:InitData()
    self.tbCardList = {}
    local tbNormalList = CollectionData.GetInfoList(CLASS_MODE.CAMP, CLASS_TYPE.NORMAL)
    local tbSpecialList = CollectionData.GetInfoList(CLASS_MODE.CAMP, CLASS_TYPE.SPECIAL)
    for i, v in ipairs(tbNormalList) do
        table.insert(self.tbCardList, v)
    end

    for i, v in ipairs(tbSpecialList) do
        table.insert(self.tbCardList, v)
    end
end

function UIWidgetCamp:GetIndexByID(nID)
    local tbCardList = self.tbCardList
    for nIndex, tbInfo in ipairs(tbCardList) do
        if tbInfo.dwID == nID then
            return nIndex
        end
    end
    return nil
end

function UIWidgetCamp:GetTotalCount()
    local tbCardList = self.tbCardList
    return tbCardList and #tbCardList or 0
end

function UIWidgetCamp:LinkToCard(nPageType, nID)
    local func = function()
        if not nID then return end
        local nIndex = self:GetIndexByID(nID)
        local nTotal = self:GetTotalCount()
        if nIndex then
            local nPercent = Lib.SafeDivision(nIndex, nTotal) * 100
            Timer.DelTimer(self, self.nScrollTimerID)
            self.nScrollTimerID = Timer.AddFrame(self, 3, function()
                UIHelper.ScrollToPercent(self.ScrollViewCamp, nPercent)
            end)
        end
    end

    if self.bInit then
        func()
    else
        self.FuncLink = func
    end
end

function UIWidgetCamp:GetPageType()
    return 0
end

function UIWidgetCamp:UpdateSeasonLevelInfo()
    local nClass = CLASS_MODE.CAMP
    local nRankLv, _, _, _, nTotalScores = GDAPI_SA_GetRankBaseInfo(nClass)
    local tRankInfo = Table_GetRankInfoByLevel(nRankLv)
    if not self.tbLevelScript then
        self.tbLevelScript = UIHelper.AddPrefab(PREFAB_ID.WidgetSeasonLevelTitle, self.WidgetAnchorSeasonLevelTitle, nClass, tRankInfo, nTotalScores)
    else
        self.tbLevelScript:OnEnter(nClass, tRankInfo, nTotalScores)
    end

end

return UIWidgetCamp