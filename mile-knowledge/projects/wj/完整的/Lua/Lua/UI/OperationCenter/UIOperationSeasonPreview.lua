-- ---------------------------------------------------------------------------------
-- Author: wangying9
-- Name: UIOperationSeasonPreview
-- Date: 2026-04-03 15:30:00
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOperationSeasonPreview = class("UIOperationSeasonPreview")

local SEASON_PREVIEW_TYPE = {
    _Equip = 1,
    Home = 2,
}

local STATE =
{
    CANGET = 0,
    DONE   = 1,
}

local tAwardLevel = {5, 15, 25, 40, 60, 80, 100, 120, 150}
local REWARD_COUNT = #tAwardLevel
local MAX_SCORE = tAwardLevel[#tAwardLevel]

function UIOperationSeasonPreview:OnEnter(dwOperatActID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    if not self.scriptTitle then
        self.scriptTitle = UIHelper.AddPrefab(PREFAB_ID.WidgetLayOutWidgetPublicTitle, self.WidgetTitle, dwOperatActID, 0)
    end

    self:InitSeasonData()
    self:UpdateInfo()
end

function UIOperationSeasonPreview:OnExit()
    self.bInit = false
    self.tbItemScript = {}
    self:UnRegEvent()
end

function UIOperationSeasonPreview:BindUIEvent()
    UIHelper.BindUIEvent(self.ScrollViewRewardCell, EventType.OnScrollingScrollView, function(_, eventType)
        local nPercent = UIHelper.GetScrollPercent(self.ScrollViewRewardCell)
        print("nPercent", nPercent)
        UIHelper.SetVisible(self.WidgetArrow, nPercent < 99)
    end)
end

function UIOperationSeasonPreview:RegEvent()
    Event.Reg(self, "ON_RECVSEASON_REWARD", function (nType, nIndex, bSuccess)
        if not bSuccess then return end
        if nType ~= SEASON_PREVIEW_TYPE.Home then return end
        local tRewardState = self.tHomelandData.tRewardState
        tRewardState[nIndex] = STATE.DONE
        local RewardCellScript = self.tbRewardCellScript[nIndex]
        if RewardCellScript then
            UIHelper.SetVisible(RewardCellScript.ImgArrowhead, tRewardState[nIndex] == STATE.CANGET or tRewardState[nIndex] == STATE.DONE)
        end
        local itemScript = self.tbItemScript[nIndex]
        if itemScript then
            itemScript:SetItemReceived(tRewardState[nIndex] == STATE.DONE)
        end
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        if self.SelectToggle and UIHelper.GetSelected(self.SelectToggle) then
            UIHelper.SetSelected(self.SelectToggle, false)
        end
    end)
end

function UIOperationSeasonPreview:UnRegEvent()
end

function UIOperationSeasonPreview:InitSeasonData()
    local tData = GDAPI_GetSeasonDistanceInfo()
    self.tHomelandData = tData.tHomeland
    local tQuestInfo = Table_GetSeasonDistanceQuestInfo()
    self.tHomelandQuestInfo = {}
    self.tbUIRewardTab = {}
    for i, v in ipairs(UISeasonRewardTab) do
        if v.nAwardType == SEASON_PREVIEW_TYPE.Home then
            table.insert(self.tbUIRewardTab, v)
        end
    end

    for i, v in ipairs(tQuestInfo) do
        if v.nType == SEASON_PREVIEW_TYPE.Home then
            table.insert(self.tHomelandQuestInfo, v)
        end
    end
end

function UIOperationSeasonPreview:UpdateInfo()
    self:UpdateHome()
    self:UpdateQuestCount()
end

function UIOperationSeasonPreview:UpdateHome()
    local nCompleteNum, nScore, nTotalNum = self:UpdateQuestCell()
    local nHomeScore = string.gsub(self.tHomelandQuestInfo[#self.tHomelandQuestInfo].szQuestDesc, "%D+", "")
    UIHelper.SetString(self.LabelNum, nHomeScore)

    self.nCompleteNum = nCompleteNum
    self.nTotalNum = nTotalNum
    self:UpdatePrize(nScore)
end

function UIOperationSeasonPreview:UpdateQuestCount()
    local nHorseCompleteNum = 0
    for i, v in ipairs(self.tHomelandData.tQuestState) do
        if self.tHomelandData.tQuestState[i] then
            nHorseCompleteNum = nHorseCompleteNum + 1
        end
    end

    UIHelper.SetString(self.LabelHome, FormatString(g_tStrings.STR_SEASON_HORSE_PAGE_TITLE, self.nCompleteNum, self.nTotalNum))
end

function UIOperationSeasonPreview:UpdateQuestCell()
    local nScore       = 0
    local nCompleteNum = 0
    local tQuestInfo = self.tHomelandQuestInfo
    local tQuestState = self.tHomelandData.tQuestState
    local nTotalNum = #tQuestInfo

    UIHelper.RemoveAllChildren(self.ScrollViewRewardCell)

    for i, v in ipairs(tQuestInfo) do
        if tQuestState[i] then
            nScore = nScore + v.nScore
            nCompleteNum = nCompleteNum + 1
        end

        if i == #tQuestInfo then
            UIHelper.SetString(self.LabelIntegral, v.nScore)
            UIHelper.SetVisible(self.ImgTaskListBgFinish, tQuestState[i])
        else
            local qusetScript = UIHelper.AddPrefab(PREFAB_ID.WidgetSeasonRewardCell, self.ScrollViewRewardCell)
            if qusetScript then
                UIHelper.SetString(qusetScript.LabelNormalInfo, UIHelper.GBKToUTF8(v.szQuestDesc))
                UIHelper.SetString(qusetScript.LabelNormalIntegralNum, v.nScore)
                UIHelper.SetVisible(qusetScript.ImgTaskListBgFinish, tQuestState[i])

                UIHelper.SetSpriteFrame(qusetScript.ImgIcon, v.szSpriteFrame)
            end
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewRewardCell)

    return nCompleteNum, nScore, nTotalNum
end

function UIOperationSeasonPreview:UpdatePrize(nScore)
    local tRewardState = self.tHomelandData.tRewardState
    local tbSubPreviewReward = UIHelper.GetChildren(self.WidgetActive)
    self.tbItemScript = {}
    self.tbRewardCellScript = {}

    UIHelper.SetString(self.LabelVersionsCount, nScore)

    for i = 1, REWARD_COUNT do
        if tbSubPreviewReward and tbSubPreviewReward[i] then
            local RewardCellScript = UIHelper.AddPrefab(PREFAB_ID.WidgetSeasonPreviewReward, tbSubPreviewReward[i])
            if RewardCellScript and self.tbUIRewardTab[i] then
                local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, RewardCellScript.WidgetItem)
                if itemScript then
                    itemScript:OnInitWithTabID(self.tbUIRewardTab[i].nTabType, self.tbUIRewardTab[i].dwTabIndex, self.tbUIRewardTab[i].nCount)
                    itemScript:SetItemReceived(tRewardState[i] == STATE.DONE)
                    self:BindItemClickEvent(itemScript, i)
                    table.insert(self.tbItemScript, itemScript)
                end

                UIHelper.SetVisible(RewardCellScript.ImgArrowhead, tRewardState[i] == STATE.CANGET or tRewardState[i] == STATE.DONE)
                UIHelper.SetString(RewardCellScript.LabelActiveValue, tAwardLevel[i])
                table.insert(self.tbRewardCellScript, RewardCellScript)
            end
        end
    end

    self:UpdateProgressBarBySpatialPosition(nScore)
end

function UIOperationSeasonPreview:UpdateProgressBarBySpatialPosition(nScore)
    if not self.ProgressBarVersionsCount or #self.tbRewardCellScript == 0 then
        return
    end

    local nWidgetActiveWidth = UIHelper.GetWidth(self.WidgetActive)
    if nWidgetActiveWidth <= 0 then
        return
    end

    local nProgressStartPosX = UIHelper.GetWorldPositionX(self.ProgressBarVersionsCount)
    local GetRewardCenterX = function(nIndex)
        if nIndex == 0 then
            return 0
        end
        local RewardCellScript = self.tbRewardCellScript[nIndex]
        if RewardCellScript and RewardCellScript._rootNode then
            local nRewardPosX = UIHelper.GetWorldPositionX(RewardCellScript._rootNode)
            local nRewardWidth = UIHelper.GetWidth(RewardCellScript._rootNode)
            return nRewardPosX + nRewardWidth / 2 - nProgressStartPosX
        end
        return nil
    end

    local nProgressPercent = 0
    local nTargetIndex = 0
    for i = 1, REWARD_COUNT do
        if nScore >= tAwardLevel[i] then
            nTargetIndex = i
        else
            break
        end
    end

    local nCurrCenterX = GetRewardCenterX(nTargetIndex)
    local nNextCenterX = GetRewardCenterX(nTargetIndex + 1)
    if nCurrCenterX and nNextCenterX then
        local nCurrScore = nTargetIndex == 0 and 0 or tAwardLevel[nTargetIndex]
        local nNextScore = tAwardLevel[nTargetIndex + 1]
        local nSegmentProgress = (nScore - nCurrScore) / (nNextScore - nCurrScore)
        nProgressPercent = nCurrCenterX / nWidgetActiveWidth * 100 + (nNextCenterX - nCurrCenterX) / nWidgetActiveWidth * 100 * nSegmentProgress
        if nProgressPercent < 0 then nProgressPercent = 0 end
    else
        nProgressPercent = nScore / MAX_SCORE * 100
    end

    if nScore >= MAX_SCORE then
        nProgressPercent = 100
    end

    UIHelper.SetProgressBarPercent(self.ProgressBarVersionsCount, nProgressPercent)
end

function UIOperationSeasonPreview:BindItemClickEvent(itemScript, i)
    itemScript:SetClickCallback(function (nTabType, nTabID)
        self.SelectToggle = itemScript.ToggleSelect
        for k, v in ipairs(self.tbItemScript) do
            if v.ToggleSelect and UIHelper.GetSelected(v.ToggleSelect) and k ~= i then
                UIHelper.SetSelected(v.ToggleSelect,false)
            end
        end
        TipsHelper.ShowItemTips(itemScript._rootNode, nTabType, nTabID)

        local bIsRemote = CheckPlayerIsRemote()
        if bIsRemote then return end
        for nIndex = 1, REWARD_COUNT do
            if self.tHomelandData.tRewardState[nIndex] == STATE.CANGET then
                RemoteCallToServer("On_SeasonDistance_Award", SEASON_PREVIEW_TYPE.Home, nIndex)
            end
        end
    end)
end

return UIOperationSeasonPreview