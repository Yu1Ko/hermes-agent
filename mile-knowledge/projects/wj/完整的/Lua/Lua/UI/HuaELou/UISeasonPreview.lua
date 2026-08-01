-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UISeasonPreview
-- Date: 2023-06-15 11:10:46
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UISeasonPreview = class("UISeasonPreview")

local MAX_SCORE = 150
local REWARD_COUNT = 9
local TARGET_COUNT = 13
local SHOW_LEFT_DAY = 15
local STATE =
{
    CANGET = 0,
    DONE   = 1,
}
local tRewardType =
{
    [1]          = "Pvx",
    [2]          = "Homeland",
    ["Pvx"]      = 1,
    ["Homeland"] = 2,
}
local tAwardLevel = {5, 15, 25, 40, 60, 80, 100, 120, 150}--一共9档

function UISeasonPreview:OnEnter(dwOperatActID, _, nType)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.bPower = true
    if nType and nType == 2 then
        self.bPower = false
    end

    local tLine = Table_GetOperActyInfo(dwOperatActID)
    if tLine and tLine.szTitle then
        UIHelper.SetString(self.LabelNormalName1, UIHelper.GBKToUTF8(tLine.szTitle))
    end

    self:InitSeasonData()
    self:UpdateInfo()
end

function UISeasonPreview:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISeasonPreview:BindUIEvent()
    UIHelper.BindUIEvent(self.TogPower, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            self.bPower = true
            self:UpdatePower()
        end
    end)

    UIHelper.BindUIEvent(self.TogHome, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            self.bPower = false
            self:UpdateHome()
        end
    end)

    UIHelper.BindUIEvent(self.BtnGetAll, EventType.OnClick, function ()
        local bIsRemote = CheckPlayerIsRemote()
        if bIsRemote then return end

        local tRewardState = self.bPower and self.tPvxData.tRewardState or self.tHomelandData.tRewardState
        for nIndex = 1, REWARD_COUNT do
            if tRewardState[nIndex] == STATE.CANGET then
                RemoteCallToServer("On_SeasonDistance_Award", self.bPower and 1 or 2, nIndex)
            end
        end
    end)
end

function UISeasonPreview:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "ON_RECVSEASON_REWARD", function (nType, nIndex, bSuccess)
        if not bSuccess then return end
        if (self.bPower and nType ~= 1) or ((not self.bPower) and nType ~= 2) then return end
        local tRewardState = self.bPower and self.tPvxData.tRewardState or self.tHomelandData.tRewardState
        tRewardState[nIndex] = STATE.DONE
        local RewardCellScript = self.tbRewardCellScript[nIndex]
        if RewardCellScript then
            UIHelper.SetVisible(RewardCellScript.ImgMask, tRewardState[nIndex] == STATE.DONE)
            UIHelper.SetVisible(RewardCellScript.ImgCheck, tRewardState[nIndex] == STATE.DONE)
            UIHelper.SetVisible(RewardCellScript.ImgAvailable, tRewardState[nIndex] == STATE.CANGET)
        end
        local bReward = false
        for k, v in ipairs(tRewardState) do
            if v == STATE.CANGET then
                bReward = true
                break
            end
        end

        UIHelper.SetButtonState(self.BtnGetAll, bReward and BTN_STATE.Normal or BTN_STATE.Disable)
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        if self.SelectToggle and UIHelper.GetSelected(self.SelectToggle) then
            UIHelper.SetSelected(self.SelectToggle, false)
        end
    end)
end

function UISeasonPreview:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UISeasonPreview:InitSeasonData()
    local tData = GDAPI_GetSeasonDistanceInfo()
    self.tPvxData = tData.tPvx
    self.tHomelandData = tData.tHomeland
    self.nPvxScore = 0
    self.nHomelandScore = 0
    local tQuestInfo = Table_GetSeasonDistanceQuestInfo()
    self.tPvxQuestInfo = {}
    self.tHomelandQuestInfo = {}

    for i, v in ipairs(tQuestInfo) do
        if v.nType == 1 then
            table.insert(self.tPvxQuestInfo, v)
        else
            table.insert(self.tHomelandQuestInfo, v)
        end
    end
end

function UISeasonPreview:UpdateInfo()
    self:UpdatePower()
    self:UpdateQuestCount()
end

function UISeasonPreview:UpdatePower()
    local nCompleteNum, nScore = self:UpdateQuestCell()
    UIHelper.SetString(self.LabelTitle, g_tStrings.STR_SEASON_EQUIP_TARGET)
    UIHelper.SetString(self.LabelInfo, g_tStrings.STR_SEASON_EQUIP_TARGET_NUM)
    local nEquipScore = string.gsub(self.tPvxQuestInfo[#self.tPvxQuestInfo].szQuestDesc, "%D+", "")
    UIHelper.SetString(self.LabelNum, nEquipScore)

    if self.tPvxData and self.tPvxData.nLeftDay <= SHOW_LEFT_DAY then
        UIHelper.SetVisible(self.WidgetPowerDaysLeft, true)
        UIHelper.SetString(self.LabelPowerDaysLeft, FormatString(g_tStrings.STR_LEFT_DAY, self.tPvxData.nLeftDay))
    end
    if self.tHomelandData and self.tHomelandData.nLeftDay <= SHOW_LEFT_DAY then
        UIHelper.SetVisible(self.WidgetHomeDaysLeft, true)
        UIHelper.SetString(self.LabelHomeDaysLeft,FormatString(g_tStrings.STR_LEFT_DAY, self.tHomelandData.nLeftDay))
    end

    self:UpdatePrize(nScore)
end

function UISeasonPreview:UpdateHome()
    local nCompleteNum, nScore = self:UpdateQuestCell()
    UIHelper.SetString(self.LabelTitle, g_tStrings.STR_SEASON_HORSE_TARGET)
    UIHelper.SetString(self.LabelInfo, g_tStrings.STR_SEASON_HORSE_TARGET_NUM)
    local nHomeScore = string.gsub(self.tHomelandQuestInfo[#self.tHomelandQuestInfo].szQuestDesc, "%D+", "")
    UIHelper.SetString(self.LabelNum, nHomeScore)

    self:UpdatePrize(nScore)
end

function UISeasonPreview:UpdateQuestCount()
    local nEquipCompleteNum = 0
    for i, v in ipairs(self.tPvxData.tQuestState) do
        if self.tPvxData.tQuestState[i] then
            nEquipCompleteNum = nEquipCompleteNum + 1
        end
    end
    local nHorseCompleteNum = 0
    for i, v in ipairs(self.tHomelandData.tQuestState) do
        if self.tHomelandData.tQuestState[i] then
            nHorseCompleteNum = nHorseCompleteNum + 1
        end
    end

    for i = 1,2 do
        UIHelper.SetString(self.tbLabelPower[i], FormatString(g_tStrings.STR_SEASON_EQUIP_PAGE_TITLE, nEquipCompleteNum, TARGET_COUNT))
        UIHelper.SetString(self.tbLabelHome[i], FormatString(g_tStrings.STR_SEASON_HORSE_PAGE_TITLE,nHorseCompleteNum,TARGET_COUNT))
    end
end

function UISeasonPreview:UpdateQuestCell()
    local nScore       = 0
    local nCompleteNum = 0
    local tQuestInfo = self.bPower and self.tPvxQuestInfo or self.tHomelandQuestInfo
    local tQuestState = self.bPower and self.tPvxData.tQuestState or self.tHomelandData.tQuestState

    UIHelper.RemoveAllChildren(self.ScrollViewRewardCell)
    local tbQuestScript = {}

    for i, v in ipairs(tQuestInfo) do
        if tQuestState[i] then
            nScore = nScore + v.nScore
            nCompleteNum = nCompleteNum + 1
        end

        if i == #tQuestInfo then
            UIHelper.SetVisible(self.LabelFinished, tQuestState[i])
            UIHelper.SetVisible(self.LabelUndone, not tQuestState[i])
            UIHelper.SetString(self.LabelIntegral, FormatString(g_tStrings.STR_SEASON_TASK_REWARD_DES, v.nScore))
        else
            local qusetScript = UIHelper.AddPrefab(PREFAB_ID.WidgetSeasonRewardCell, self.ScrollViewRewardCell)
            if qusetScript then
                for k = 1, 2 do
                    UIHelper.SetString(qusetScript.tbQuestInfo[k], UIHelper.GBKToUTF8(v.szQuestDesc))
                    UIHelper.SetString(qusetScript.tbscore[k], v.nScore)
                    UIHelper.SetVisible(qusetScript.tbQuestState[k], not tQuestState[i])
                    UIHelper.SetVisible(qusetScript.tbQuestStateDone[k], tQuestState[i])
                end
                UIHelper.SetSpriteFrame(qusetScript.ImgIcon, v.szSpriteFrame)

                UIHelper.BindUIEvent(qusetScript.TogRewardCell, EventType.OnSelectChanged, function (_, bSelected)
                    if bSelected then
                        if self.SelectToggle and UIHelper.GetSelected(self.SelectToggle) then
                            UIHelper.SetSelected(self.SelectToggle, false)
                        end
                        TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips, qusetScript.TogRewardCell, ParseTextHelper.ParseNormalText(UIHelper.GBKToUTF8(v.szTip),true))
                    end
                end)

                table.insert(tbQuestScript, qusetScript)
            end
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewRewardCell)

    return nCompleteNum, nScore
end

function UISeasonPreview:UpdatePrize(nScore)
    local tRewardState = self.bPower and self.tPvxData.tRewardState or self.tHomelandData.tRewardState
    local k = self.bPower and 1 or 10
    local nSizeW = UIHelper.GetWidth(self.WidgetActive)

    UIHelper.RemoveAllChildren(self.WidgetActive)
    local tbItemScript = {}
    self.tbRewardCellScript = {}
    local bReward = false

    local nProgress = 100
    UIHelper.SetString(self.LabelVersionsCount, nScore)
    UIHelper.SetProgressBarPercent(self.ProgressBarVersionsCount, nScore * nProgress / MAX_SCORE)

    for i = 1, REWARD_COUNT do
        local nState = tRewardState[i]
        local RewardCellScript = UIHelper.AddPrefab(PREFAB_ID.WidgetActiveRewardCell, self.WidgetActive)
        if RewardCellScript and UISeasonRewardTab[k] then
            local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, RewardCellScript.WidgetItem)
            if itemScript then
                itemScript:OnInitWithTabID(UISeasonRewardTab[k].nTabType, UISeasonRewardTab[k].dwTabIndex, UISeasonRewardTab[k].nCount)
                self:BindItemEvent(itemScript, tbItemScript, tRewardState, i)
                table.insert(tbItemScript, itemScript)
            end

            UIHelper.SetVisible(RewardCellScript.ImgAvailable, nState == STATE.CANGET)
            UIHelper.SetVisible(RewardCellScript.ImgMask, nState == STATE.DONE)
            UIHelper.SetVisible(RewardCellScript.ImgCheck, nState == STATE.DONE)
            UIHelper.SetVisible(RewardCellScript.ImgArrowhead, nState == STATE.CANGET or nState == STATE.DONE)
            UIHelper.SetString(RewardCellScript.LabelActiveValue, tAwardLevel[i])
            local nCellSizeW = UIHelper.GetWidth(RewardCellScript._rootNode)
            UIHelper.SetPositionX(RewardCellScript._rootNode, tAwardLevel[i] * nSizeW / MAX_SCORE - nCellSizeW / 2)
            table.insert(self.tbRewardCellScript, RewardCellScript)

            if nState == STATE.CANGET then
                bReward = true
            end
        end
        k = k + 1
    end

    UIHelper.SetButtonState(self.BtnGetAll, bReward and BTN_STATE.Normal or BTN_STATE.Disable)
end

function UISeasonPreview:BindItemEvent(itemScript, tbItemScript, tRewardState, i)
    itemScript:SetClickCallback(function (nTabType, nTabID)
        self.SelectToggle = itemScript.ToggleSelect
        for k, v in ipairs(tbItemScript) do
            if v.ToggleSelect and UIHelper.GetSelected(v.ToggleSelect) and k ~= i then
                UIHelper.SetSelected(v.ToggleSelect,false)
            end
        end
        TipsHelper.ShowItemTips(itemScript._rootNode, nTabType, nTabID)
        local bIsRemote = CheckPlayerIsRemote()
        if bIsRemote or tRewardState[i] ~= STATE.CANGET then return end
        -- for nIndex = 1, REWARD_COUNT do
            if tRewardState[i] == STATE.CANGET then
                RemoteCallToServer("On_SeasonDistance_Award", self.bPower and 1 or 2, i)
            end
        -- end
    end)
end

return UISeasonPreview