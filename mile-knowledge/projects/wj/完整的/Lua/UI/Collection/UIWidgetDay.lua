-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetDay
-- Date: 2024-03-04 09:46:43
-- Desc: ?
-- ---------------------------------------------------------------------------------
local RANK_COUNT = 3
local CLASS_MODE = {
	DAILY    = 1, --日课
	WEEK     = 2, --周课
}

local UIWidgetDay = class("UIWidgetDay")

function UIWidgetDay:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.bOpen = false
    self:InitData()
end

function UIWidgetDay:Open()
    if not self.bOpen then
        self.bOpen = true
        self:InitData()
        self:UpdateInfo()
        if self.FuncLink then self.FuncLink() end
    end

end

function UIWidgetDay:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetDay:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnJH, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelBenefits, 2)
    end)

    UIHelper.BindUIEvent(self.BtnSJ, EventType.OnClick, function()
        UIMgr.OpenSingle(true, VIEW_ID.PanelSeasonChallenge)
    end)

    UIHelper.BindUIEvent(self.BtnPray, EventType.OnClick, function ()
        UIMgr.OpenSingle(true, VIEW_ID.PanelPrayerPlatform)
    end)

    local function SwitchRewardWidget(nIndex)
        if self.nCurrentRewardIndex == nIndex then
            return
        end
        self.nCurrentRewardIndex = nIndex
        UIHelper.SetVisible(self.WidgetSelectDay, nIndex == 1)
        UIHelper.SetVisible(self.WidgetSelectWeek, nIndex == 2)
        UIHelper.SetVisible(self.WidgetSelectNextWeek, nIndex == 3)
        UIHelper.LayoutDoLayout(self.LayOutReward)
    end

    UIHelper.BindUIEvent(self.BtnDayRewardSwitch, EventType.OnClick, function ()
        SwitchRewardWidget(1)
    end)

    UIHelper.BindUIEvent(self.BtnWeekRewardSwitch, EventType.OnClick, function ()
        SwitchRewardWidget(2)
    end)

    UIHelper.BindUIEvent(self.BtnnNextWeekRewardSwitch, EventType.OnClick, function ()
        local nId, nType = CollectionDailyData.GetNextWeekRewardItem()
        local tip, scriptItemTip = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, self.BtnnNextWeekRewardSwitch, TipsLayoutDir.TOP_CENTER)
        scriptItemTip:OnInitWithTabID(nType, nId)
        scriptItemTip:SetBtnState({})
    end)
end

function UIWidgetDay:RegEvent()
    Event.Reg(self, EventType.On_Get_Daily_Allinfo, function(tbQuestList, nGetRewardLv, nReachLv)
        self:UpdateInfo()
        self.bFresh = false
    end)

    Event.Reg(self, EventType.On_GameGuide_RefreshDailyInfo, function(nCardPos, tbCardInfo, nGetRewardLv, nReachLv)
        self:UpdateOneCard(nCardPos, tbCardInfo)
        self:UpdateDayRewardInfo()
    end)

    Event.Reg(self, EventType.On_GameGuide_UpdateWeeklyInfo, function(nPoint, nGetRewardLv)
        self:UpdateWeekRewardInfo()
    end)

    Event.Reg(self, EventType.On_GameGuide_NxWkLoginInfo, function(nCan, nClaimed)
        self:UpdateNextWeekState()
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        self:CloseTip()
    end)

    Event.Reg(self, "ON_COLLECTION_CARD_FRESH", function()
        self.bFresh = true
    end)

    Event.Reg(self, "CB_SH_TaskRewardGranted", function(szKey)
        self:UpdateChallengeRedDotState()
    end)

    Event.Reg(self, "CB_SH_SetPersonReward", function()
        self:UpdateChallengeRedDotState()
    end)

    Event.Reg(self, "CB_SH_ExchangeMount", function()
        self:UpdateChallengeRedDotState()
    end)

    Event.Reg(self, "ChallengeHorseRedDotChange", function()
        self:UpdateChallengeRedDotState()
    end)

    Event.Reg(self, "UPDATE_WISH_ITEM", function()
        self:UpdateWishItemInfo()
    end)
end

function UIWidgetDay:UnRegEvent()
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIWidgetDay:InitData()
    self.tbQuestScript = self.tbQuestScript or {}
    self.tbRewardScript = self.tbRewardScript or {}
    self.tbWeekRewardScript = self.tbWeekRewardScript or {}
    self.tbNextWeekRewardScript = self.tbNextWeekRewardScript or {}
end

function UIWidgetDay:UpdateInfo()
    self:CloseTip()
    local tbQuestList = CollectionDailyData.GetQuestList()
    for nIndex, tbQuestID in ipairs(tbQuestList) do
        local scriptView = self.tbQuestScript[nIndex]
        if not scriptView then
            scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetRoafCardCell, self.LayOutDayTask, tbQuestID, nIndex)
            -- scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetDayTaskList, self.LayOutDayTask, tbQuestID, nIndex)
            table.insert(self.tbQuestScript, scriptView)
        else
            scriptView:OnEnter(tbQuestID, nIndex)
        end
    end

    if not self.bFresh then
        UIHelper.LayoutDoLayout(self.LayOutDayTask)
    end

    self:UpdateRank()
    self:UpdateWishItemInfo()
    self:UpdateWeekRewardInfo()
    self:UpdateDayRewardInfo()
    self:UpdateChallengeRedDotState()
    self:UpdateNextWeekState()
end

function UIWidgetDay:UpdateWishItemInfo()
    local tInfo = GDAPI_GetSpecialWishInfo()
    DungeonData.tWishInfo = tInfo
    
    local nPercent = tInfo.nWishCoin/tInfo.nMaxWishCoinLimit
    local szText = tostring(tInfo.nWishCoin)
    if tInfo.nWishIndex ~= 0 then
        nPercent = (DungeonData.MAX_WISH_ITEM_RETRY_COUNT - tInfo.nRemainTryCount) / DungeonData.MAX_WISH_ITEM_RETRY_COUNT
        szText = string.format("%d次内必出", tInfo.nRemainTryCount)
    end
    UIHelper.SetProgressBarPercent(self.ImgSliderWishCoin, nPercent * 100)
    UIHelper.SetString(self.LabelWishCoin, szText)
    UIHelper.SetVisible(self.ImgPrayRedDot, tInfo.nWishIndex == 0 and tInfo.nWishCoin == tInfo.nMaxWishCoinLimit)
    UIHelper.SetVisible(self.ImgPrayUp, tInfo.nWishIndex ~= 0 and tInfo.nRemainTryCount == 1)
    UIHelper.SetVisible(self.WidgetPrayEff, DungeonData.CanWishItemFlash())
end

function UIWidgetDay:UpdateDayRewardInfo()
    local tReachLv = CollectionDailyData.GetReachLv()
    local nReachLv = tReachLv[CLASS_MODE.DAILY]
    local tGetRewardLv = CollectionDailyData.GetGetRewardLv()
    local nGetRewardLv = tGetRewardLv[CLASS_MODE.DAILY]

    UIHelper.SetString(self.LabeDayNum, nReachLv * 20)
    UIHelper.SetProgressBarPercent(self.ProgressDayBar, nReachLv * 20)

    for nIndex, parent in ipairs(self.tbWidgetItem) do
        local szReward     = CollectionDailyData.GetDailyQuestReward(nIndex)
        local t = string.split(szReward, "_")
        local dwTabType    = tonumber(t[1])
		local dwIndex      = tonumber(t[2])
		local nCount       = tonumber(t[3])
        local tbInfo = {nTabType = dwTabType, nTabID = dwIndex, nStackNum = nCount}
        self:UpdateAwardItem(parent, tbInfo, nIndex, nIndex, self.tbRewardScript)
    end
    

    for nIndex, img in ipairs(self.tbImageAvailable) do
        UIHelper.SetVisible(img, nGetRewardLv < nIndex and nReachLv >= nIndex)
    end

    for nIndex, widgetGet in ipairs(self.tbWidgetGet) do
        UIHelper.SetVisible(widgetGet, nGetRewardLv >= nIndex)
    end
end



function UIWidgetDay:UpdateWeekRewardInfo()
    local tReachLv = CollectionDailyData.GetReachLv()
    local nReachLv = tReachLv[CLASS_MODE.WEEK]
    local tGetRewardLv = CollectionDailyData.GetGetRewardLv()
    local nGetRewardLv = tGetRewardLv[CLASS_MODE.WEEK]
    UIHelper.SetString(self.LabeWeekNum, string.format("%d/5", nReachLv))
    UIHelper.SetProgressBarPercent(self.ProgressWeekBar, (nReachLv / 5) * 100)

    for nIndex, parent in ipairs(self.tbWidgetWeekItem) do
        local tReward     = CollectionDailyData.GetWeekQuestReward(nIndex)
        local t = tReward.tItem
        local dwTabType    = tonumber(t[1])
		local dwIndex      = tonumber(t[2])
		local nCount       = tonumber(t[3])
        local tbInfo = {nTabType = dwTabType, nTabID = dwIndex, nStackNum = nCount}
        self:UpdateAwardItem(parent, tbInfo, nIndex, nIndex, self.tbWeekRewardScript, true)
    end

    for nIndex, img in ipairs(self.tbImageWeekAvailable) do
        UIHelper.SetVisible(img, nGetRewardLv < nIndex and nReachLv >= nIndex)
    end

    for nIndex, widgetGet in ipairs(self.tbWidgetWeekGet) do
        UIHelper.SetVisible(widgetGet, nGetRewardLv >= nIndex)
    end
end

function UIWidgetDay:UpdateAwardItem(parent, tbInfo, nScriptIndex, nLogic, tbScript, isWeek)
    local scriptView = tbScript[nScriptIndex]
    if not scriptView then
        scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, parent)
        table.insert(tbScript, scriptView)
    end
    local nTabType, nTabID, nStackNum = tonumber(tbInfo.nTabType or 0), tonumber(tbInfo.nTabID or 0), tonumber(tbInfo.nStackNum or 0)
    local tReachLv = CollectionDailyData.GetReachLv()
    local nReachLv = isWeek and tReachLv[CLASS_MODE.WEEK] or tReachLv[CLASS_MODE.DAILY]
    local tGetRewardLv = CollectionDailyData.GetGetRewardLv()
    local nGetRewardLv = isWeek and tGetRewardLv[CLASS_MODE.WEEK] or tGetRewardLv[CLASS_MODE.DAILY]

    scriptView:OnInitWithTabID(tonumber(nTabType), tonumber(nTabID), tonumber(nStackNum))
    scriptView:SetClickCallback(function(nClickTabType, nClickTabID)
        local bCanGet = nGetRewardLv < nScriptIndex and nReachLv >= nLogic
        if bCanGet then
            if isWeek then
                RemoteCallToServer("On_Daily_WeeklyGetReward", nScriptIndex)
            else
                RemoteCallToServer("On_Daily_GetRewardLevel", nScriptIndex)
            end
        else
            self:OpenTip(scriptView, nClickTabType, nClickTabID)
        end
    end)
    if tonumber(nStackNum) == 1 then
        scriptView:SetLabelCount()
    end
end

function UIWidgetDay:UpdateOneCard(nCardPos, tbCardInfo)
    local scriptView = self.tbQuestScript[nCardPos]
    if scriptView then
        scriptView:OnEnter(tbCardInfo, nCardPos)
    end
end

function UIWidgetDay:OpenTip(scriptView, nTabType, nTabID)
    self:CloseTip()
    local tip, scriptItemTip = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, scriptView._rootNode, TipsLayoutDir.TOP_CENTER)
    scriptItemTip:OnInitWithTabID(nTabType, nTabID)
    scriptItemTip:SetBtnState({})
    self.scriptIcon = scriptView
end

function UIWidgetDay:CloseTip()
    if self.scriptIcon then
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
        self.scriptIcon:RawSetSelected(false)
        self.scriptIcon = nil
    end
end

function UIWidgetDay:GetIndexByID(nID)
    local tbQuestList = CollectionDailyData.GetQuestList()
    for nIndex, tbQuestID in ipairs(tbQuestList) do
        if tbQuestID[1] == nID then
            return nIndex
        end
    end
    return nil
end

function UIWidgetDay:GetTotalCount()
    local tbQuestList = CollectionDailyData.GetQuestList()
    return tbQuestList and #tbQuestList or 0
end

function UIWidgetDay:GetPageType()
    return 0
end

function UIWidgetDay:LinkToCard(nPageType, nID)
    -- local func = function()
    --     local nIndex = self:GetIndexByID(nID)
    --     local nTotal = self:GetTotalCount()
    --     if nIndex then
    --         local nPercent = Lib.SafeDivision(nIndex, nTotal) * 100
    --         Timer.DelTimer(self, self.nScrollTimerID)
    --         self.nScrollTimerID = Timer.AddFrame(self, 3, function()
    --             UIHelper.ScrollToPercent(self.ScrollViewDay, nPercent)
    --         end)
    --     end
    -- end

    -- if self.bInit then
    --     func()
    -- else
    --     self.FuncLink = func
    -- end
end

function UIWidgetDay:UpdateRank()
    UIHelper.RemoveAllChildren(self.LayOutSeasonLevel)
    local tRankList = CollectionDailyData.GetRankList()
    
    for i = 1, RANK_COUNT do
        local tRank = tRankList[i]
		if not tRank then
			return
		end

        local nClass = tRank.nClass
        local tRankInfo = Table_GetRankInfoByLevel(tRank.nRankLv)
        local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetSeasonLevelTitle, self.LayOutSeasonLevel,nClass, tRankInfo, nil, true)
    end
    UIHelper.SetPositionY(self.LayOutSeasonLevel, 0)
    UIHelper.LayoutDoLayout(self.LayOutSeasonLevel)
end

function UIWidgetDay:UpdateChallengeRedDotState()
    local bShowRedDot = CollectionData.AllTaskHasCanGet() or CollectionData.AllChallengeRewardHasCanGet() or CollectionData.CheckAllChallengeHorseRedDot()
    UIHelper.SetVisible(self.ImgRedDot, bShowRedDot)
end

function UIWidgetDay:UpdateNextWeekState()
    local bCan, bClaimed = CollectionDailyData.GetNextWeekState()
    local bCanGet = bCan and not bClaimed 
    UIHelper.SetVisible(self.ImgBgIcon, bCanGet)
    UIHelper.SetVisible(self.ImgBgIconUnfinish, not bCanGet)
end

return UIWidgetDay