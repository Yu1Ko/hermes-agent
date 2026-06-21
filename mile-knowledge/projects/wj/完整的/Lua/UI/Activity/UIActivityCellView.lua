-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIActivityCellView
-- Date: 2022-12-05 19:07:30
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIActivityCellView = class("UIActivityCellView")

function UIActivityCellView:OnEnter(nIndex, tbActiveInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if tbActiveInfo then
        self.nIndex = nIndex
        self.tbActiveInfo = tbActiveInfo
        self:UpdateInfo()
    end
end

function UIActivityCellView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIActivityCellView:BindUIEvent()
    UIHelper.BindUIEvent(self.TogActivitySelect, EventType.OnClick, function()
        Event.Dispatch(EventType.OnActivitySelect, self.nIndex)
        ActivityData.SetActivityRedDotVersion(self.tbActiveInfo.dwID, self.tbActiveInfo.nRedDotVersion)
        self:UpdateRedPoint()
        Event.Dispatch("OnUpdateActivityRedPoint")
    end)
end

function UIActivityCellView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIActivityCellView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIActivityCellView:UpdateInfo()
    UIHelper.SetString(self.LabelSelectedActivityName, UIHelper.GBKToUTF8(self.tbActiveInfo.szName))
    UIHelper.SetString(self.LabelNormalActivityName, UIHelper.GBKToUTF8(self.tbActiveInfo.szName))
    
    if self.tbActiveInfo.szTime then
        UIHelper.SetString(self.LabelNormalOpenTime, self.tbActiveInfo.szTime)
        UIHelper.SetString(self.LabelSelectedOpenTime, self.tbActiveInfo.szTime)
    else
        UIHelper.SetVisible(self.LabelNormalOpenTime, false)
        UIHelper.SetVisible(self.LabelSelectedOpenTime, false)
    end

    local hPlayer = g_pClientPlayer
    local nQuestFinishAmount = ActivityData.GetActivityQuestFinishAmount(self.tbActiveInfo)
    local nQuestTotalCount = ActivityData.GetActivityQuestTotalCount(self.tbActiveInfo)
    local szContent = nQuestTotalCount ~= 0 and string.format("%s/%s", nQuestFinishAmount, nQuestTotalCount) or ""
    if hPlayer and self.tbActiveInfo.nLevel > hPlayer.nLevel then
        szContent = UIHelper.GBKToUTF8(self.tbActiveInfo.nLevel)..g_tStrings.STR_LEVEL
        UIHelper.SetColor(self.LabelOpenState, cc.c3b(255, 118, 118))--红
    elseif self.tbActiveInfo.szTime ~= g_tStrings.CALENDER_ALL_DAY then
        local nCurrentTime = GetCurrentTime()
        if self.tbActiveInfo.nEvent == CALENDER_EVENT_DYNAMIC or (nCurrentTime >= self.tbActiveInfo.nStartTime and nCurrentTime <= self.tbActiveInfo.nEndTime) then
            if not string.is_nil(szContent) then szContent = "("..szContent..")" end
            szContent = g_tStrings.tActiveState[1]..szContent
            UIHelper.SetColor(self.LabelOpenState, cc.c3b(255, 226, 110))--黄
        end
    end

    if string.is_nil(szContent) then
        self.bShowCountDown = true
    end

    UIHelper.SetString(self.LabelOpenState, szContent)


    local nStar = self.tbActiveInfo.nStar or 0
    for nIndex, star in ipairs(self.tbStarList) do
        UIHelper.SetVisible(star, nIndex <= nStar)
    end
    local szIconPath = UIActiveCalendarIconTab[self.tbActiveInfo.nIconFrame] and UIActiveCalendarIconTab[self.tbActiveInfo.nIconFrame].IconPath or "UIAtlas2_ActivityCalendar_ActivityCalendarIcon_ChaHuaJiangHu.png"
    UIHelper.SetSpriteFrame(self.ImgIcon, szIconPath)


    local nState = ActivityData.GetActivityState(self.tbActiveInfo)
    UIHelper.SetVisible(self.ImgFinish, nState == PLAYER_ACTIVITY_STATE.FINISH)
    UIHelper.SetVisible(self.LabelOpenState, (not string.is_nil(szContent) or self.tbActiveInfo.bShowCountdown) 
    and (nState ~= PLAYER_ACTIVITY_STATE.FINISH))

    UIHelper.SetVisible(self.ImgRecommendIcon, self.tbActiveInfo.nLabel == 1)
    self:UpdateRedPoint()

    if self.bShowCountDown and self.tbActiveInfo.bShowCountdown then
        self:StartCountDown()
    end

end

function UIActivityCellView:UpdateCountDown()
    local szTime = ActivityData.GetCountdownTimeText(self.tbActiveInfo)
    UIHelper.SetString(self.LabelOpenState, szTime)
end

function UIActivityCellView:SetSelected(bSelected)
    UIHelper.SetSelected(self.TogActivitySelect, bSelected)
end

function UIActivityCellView:UpdateRedPoint()
    local bVisited = ActivityData.IsActivityVisited(self.tbActiveInfo.dwID, self.tbActiveInfo.nRedDotVersion)
    UIHelper.SetVisible(self.ImgRedDot, not bVisited)
end

function UIActivityCellView:StartCountDown()
    self:StopCountDown()
    self.nTimer = Timer.AddCycle(self, 1, function()
        self:UpdateCountDown()
    end)
end

function UIActivityCellView:StopCountDown()
    if self.nTimer then
        Timer.DelTimer(self, self.nTimer)
        self.nTimer = nil
    end
end

return UIActivityCellView