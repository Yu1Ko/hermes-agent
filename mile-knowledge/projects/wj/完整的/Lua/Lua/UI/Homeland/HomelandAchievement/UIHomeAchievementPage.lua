-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomeAchievementPage
-- Date: 2023-07-19 19:18:17
-- Desc: ?
-- ---------------------------------------------------------------------------------
local FURNITURE_SUIT_BEGIN_COUNT = {
    [1] = 1,
    [2] = 5
}
local FURNITURE_SUIT_END_COUNT = {
    [1] = 4,
    [2] = 8
}
local FURNITURE_TOTAL_SUIT_INDEX = 9
local UIHomeAchievementPage = class("UIHomeAchievementPage")

function UIHomeAchievementPage:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        HomelandAchievement.Init()
        self.bInit = true
    end
    local cc_spriteFrameCache = cc.SpriteFrameCache:getInstance()
    cc_spriteFrameCache:addSpriteFramesWithJson("Resource/JYPlay/SeasonFurniture.json")
    UIHelper.PlayAni(self, self.WidgetAniAll, "Ani_L_R_Show")
    self.nListIndex = 1
    UIHelper.SetTouchDownHideTips(self.BtnHomeAchievement, false)
    self:UpdateInfo()
end

function UIHomeAchievementPage:OnExit()
    self.bInit = false
    HomelandAchievement.UnInit()

    UIHelper.PlayAni(self, self.WidgetAniAll, "Ani_L_R_Hide")
end

function UIHomeAchievementPage:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSwitchRight, EventType.OnClick, function()
        -- self.nListIndex = self.nListIndex + 1
        UIHelper.ScrollToPage(self.PageViewCont, 1)
        self:SwitchIndexLimt()
        -- self:UpdateRightListInfo()
    end)

    UIHelper.BindUIEvent(self.BtnSwitchLeft, EventType.OnClick, function()
        -- self.nListIndex = self.nListIndex - 1
        UIHelper.ScrollToPage(self.PageViewCont, 0)
        self:SwitchIndexLimt()
        -- self:UpdateRightListInfo()
    end)

    UIHelper.BindUIEvent(self.BtnHomeAchievement, EventType.OnClick, function()
        if self.bAllCollectToAward then
            Event.Dispatch(EventType.OnHomeAchievementToAward, FURNITURE_TOTAL_SUIT_INDEX)
            self.bAllCollectToAward = false
        else
            if UIMgr.GetView(VIEW_ID.PanelHomeAchievementRightPop) then
                Event.Dispatch(EventType.OnHomeAchievementRightPopOpen, FURNITURE_TOTAL_SUIT_INDEX, HomelandAchievement.nFullCollected, FURNITURE_SUIT_END_COUNT[2])
            else
                UIMgr.Open(VIEW_ID.PanelHomeAchievementRightPop, FURNITURE_TOTAL_SUIT_INDEX, HomelandAchievement.nFullCollected, FURNITURE_SUIT_END_COUNT[2])
            end
        end
    end)

    UIHelper.BindUIEvent(self.PageViewCont, EventType.OnTurningPageView, function ()
        self:SwitchIndexLimt(true)
    end)

    UIHelper.SetSwallowTouches(self.PageViewCont, true)
    UIHelper.SetTouchDownHideTips(self.PageViewCont, false)
end

function UIHomeAchievementPage:RegEvent()
    Event.Reg(self, EventType.OnHomeAchievementInput, function ()
        self:UpdateInfo()
    end)

    Event.Reg(self, "ON_SYNC_SET_COLLECTION", function ()
        self:UpdateInfo()
    end)

    Event.Reg(self, "HOME_GET_SEASON_POINTS", function ()
        HomelandAchievement.nFurnitureScore = arg0
        self:UpdateLeftWidgetInfo()
    end)

    Event.Reg(self, EventType.OnHomeAchievementToAward, function (nIndex)
        HomelandAchievement.GetFurnitureSetID()
        local pPlayer = GetClientPlayer()
        local tUSetID = HomelandAchievement.tUSetID
        pPlayer.ApplySetCollectionAward(tUSetID[nIndex])
        self:UpdateInfo()
    end)

end

function UIHomeAchievementPage:UpdateInfo()
    HomelandAchievement.GetSeasonCollectData()
    HomelandAchievement.GetTransitionData()

    self:UpdateTopInfo()
    self:UpdateLeftWidgetInfo()
    self:UpdatePageViewInfo()
    UIHelper.WidgetFoceDoAlign(self.WidgetHomeAchievement)
end

function UIHomeAchievementPage:UpdateTopInfo()
    local szMoneyNum = tostring(HomelandAchievement.nCommonChip)
    local szSeasonTime = g_tStrings.STR_SEASON_FURNITURE_START_TIME .. g_tStrings.STR_SEASON_FURNITURE_CONNECT_TIME .. g_tStrings.STR_SEASON_FURNITURE_END_TIME
    local szSeasonTime01 = g_tStrings.STR_SEASON_FURNITURE_TRANSITION_TIME
    szSeasonTime01 = string.gsub(szSeasonTime01, "过渡期：", "")

    UIHelper.RemoveAllChildren(self.WidgetMoney)
    local scriptCurrency = UIHelper.AddPrefab(PREFAB_ID.WidgetOtherCurrency, self.WidgetMoney)
    scriptCurrency:SetLableCount(szMoneyNum)
    scriptCurrency:SetCurrencyType(CurrencyType.NormalFragment)
    UIHelper.SetString(self.LabelSeasonTime, szSeasonTime)
    UIHelper.SetString(self.LabelSeasonTime01, szSeasonTime01)
end

function UIHomeAchievementPage:UpdateLeftWidgetInfo()
    local pPlayer = GetClientPlayer()
    local tUSetID = HomelandAchievement.tUSetID
    self.nAllCollectType = pPlayer.GetSetCollection(tUSetID[9]).eType
    local szFurnitureScore = HomelandAchievement.nFurnitureScore
    local szMainCollection = g_tStrings.STR_SEASON_FURNITURE_TOTAL_COLLECT_PROGRESS ..HomelandAchievement.nFullCollected .. "/" .. FURNITURE_SUIT_END_COUNT[2]
    -- UIHelper.SetNodeGray(self.BtnHomeAchievement, true, true)
    UIHelper.SetVisible(self.ImgRedDot, false)
    if self.nAllCollectType == SET_COLLECTION_STATE_TYPE.COLLECTED then
        self.bAllCollected = true
        -- UIHelper.SetNodeGray(self.BtnHomeAchievement, false, true)
    else
        if self.nAllCollectType == SET_COLLECTION_STATE_TYPE.TO_AWARD then
            self.bAllCollectToAward = true
            UIHelper.SetVisible(self.ImgRedDot, true)
            -- UIHelper.SetNodeGray(self.BtnHomeAchievement, false, true)
        end
        self.bAllCollected = false
    end
    for index, imgSchedule in ipairs(self.tbScheduleImg) do
        UIHelper.SetVisible(imgSchedule, index <= HomelandAchievement.nFullCollected)
        -- if index > HomelandAchievement.nFullCollected then
        --     UIHelper.SetOpacity(imgSchedule, 80)
        -- else
        --     UIHelper.SetOpacity(imgSchedule, 255)
        -- end
    end
    UIHelper.SetVisible(self.ImgGain, self.bAllCollected)
    UIHelper.SetString(self.LabelGradeNum, szFurnitureScore)
    UIHelper.SetSpriteFrame(self.ImgHomeAchievementIcon, HomeLandAchievementCellCenterImg[9])
    UIHelper.SetString(self.LabelHomeAchievementProgress, szMainCollection)
end

function UIHomeAchievementPage:SwitchIndexLimt(bForbidScroll)
    local nPage = UIHelper.GetPageIndex(self.PageViewCont)
    if nPage == -1 then return end
    self.nListIndex = nPage == 0 and 1 or 2
    if self.nListIndex >= 2 then
        self.nListIndex = 2
        UIHelper.SetVisible(self.BtnSwitchLeft, true)
		UIHelper.SetVisible(self.BtnSwitchRight, false)

        UIHelper.SetVisible(self.ImgTogItemUp1, false)
        UIHelper.SetVisible(self.ImgTogItemUp2, true)
    elseif self.nListIndex <= 1 then
        self.nListIndex = 1
        UIHelper.SetVisible(self.BtnSwitchRight, true)
		UIHelper.SetVisible(self.BtnSwitchLeft, false)

        UIHelper.SetVisible(self.ImgTogItemUp1, true)
        UIHelper.SetVisible(self.ImgTogItemUp2, false)
    end
    if not bForbidScroll then
        UIHelper.ScrollToPage(self.PageViewCont, self.nListIndex - 1)
    end
    self:CheckNextPageCellToAward()
end

function UIHomeAchievementPage:CheckNextPageCellToAward()
    local pPlayer = GetClientPlayer()
    local tUSetID = HomelandAchievement.tUSetID
    local nStartIndex = self.nListIndex == 1 and FURNITURE_SUIT_BEGIN_COUNT[2] or FURNITURE_SUIT_BEGIN_COUNT[1]
    local nEndIndex = self.nListIndex == 1 and FURNITURE_SUIT_END_COUNT[2] or FURNITURE_SUIT_END_COUNT[1]
    local nRedDotIndex = self.nListIndex == 1 and 2 or 1

    UIHelper.SetVisible(self["ImgRedDot0"..self.nListIndex], false)
    for i = nStartIndex, nEndIndex, 1 do
        local nCollectType = pPlayer.GetSetCollection(tUSetID[i]).eType
        if nCollectType == SET_COLLECTION_STATE_TYPE.TO_AWARD then
            UIHelper.SetVisible(self["ImgRedDot0"..nRedDotIndex], false)
            UIHelper.SetVisible(self["ImgRedDot0"..self.nListIndex], true)
        end
    end
end

function UIHomeAchievementPage:UpdatePageViewInfo()
    local pPlayer = GetClientPlayer()
    for i = 1, 2, 1 do
        self["Page_"..i] = self["Page_"..i] or UIHelper.PageViewAddPage(self.PageViewCont, PREFAB_ID.WidgetHomeAchievementPageCell)
        UIHelper.RemoveAllChildren(self["Page_"..i].LayoutHomeAchievementList)
        for nIndex = FURNITURE_SUIT_BEGIN_COUNT[i], FURNITURE_SUIT_END_COUNT[i] do
            local nCollected = HomelandAchievement.tCollectProgress[nIndex]
            local nMaxCollect = HomelandAchievement.aMaxSeasonFurnitureProgress[nIndex]
            local nTransitionData = HomelandAchievement.tTransitionData[nIndex]
            local bShowInterim = HomelandAchievement.bTimeInterim and nTransitionData == 1
            local tUSetID = HomelandAchievement.tUSetID
            local nCollectType = pPlayer.GetSetCollection(tUSetID[nIndex]).eType
            local szMoneyNum = tostring(HomelandAchievement.nCommonChip)
            if nCollectType == SET_COLLECTION_STATE_TYPE.COLLECTED then
                HomelandAchievement.bCollected = true
            else
                HomelandAchievement.bCollected = false
                if nIndex ~= FURNITURE_TOTAL_SUIT_INDEX then
                    HomelandAchievement.bAllCollected = false
                end
            end
            local bAward = nCollectType == SET_COLLECTION_STATE_TYPE.TO_AWARD
            local bCollected = HomelandAchievement.bCollected
            local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetHomeAchievementListCell, self["Page_"..i].LayoutHomeAchievementList)

            scriptCell:OnEnter(nIndex, nCollected, nMaxCollect, bShowInterim, bCollected, bAward, szMoneyNum, self.WidgetRightPop)
        end
    end
    UIHelper.SetPageIndex(self.PageViewCont, (self.nListIndex - 1) or 0)
    self:SwitchIndexLimt()
end


return UIHomeAchievementPage