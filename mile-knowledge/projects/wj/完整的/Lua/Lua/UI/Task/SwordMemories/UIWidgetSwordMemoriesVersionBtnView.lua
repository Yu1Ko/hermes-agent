-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSwordMemoriesVersionBtnView
-- Date: 2024-09-18 15:06:18
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetSwordMemoriesVersionBtnView = class("UIWidgetSwordMemoriesVersionBtnView")

function UIWidgetSwordMemoriesVersionBtnView:OnEnter(nSeasonID, swordMemoriesView)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nSeasonID = nSeasonID
    self.swordMemoriesView = swordMemoriesView
    self:UpdateInfo()
end

function UIWidgetSwordMemoriesVersionBtnView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetSwordMemoriesVersionBtnView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnAll, EventType.OnClick, function()
        self.swordMemoriesView:SetCurSeason(self.nSeasonID, false)
    end)

    UIHelper.BindUIEvent(self.BtnReward, EventType.OnClick, function()
        if SwordMemoriesData.CanGetReward(self.nSeasonID) then
            RemoteCallToServer("On_Quest_GetMainStoryReward", self.nSeasonID)
        else
            local tbAwardList = SwordMemoriesData.GetSeasonRewardList(self.nSeasonID)
            TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetRewardPreview, self.BtnReward, TipsLayoutDir.TOP_CENTER, tbAwardList, PREFAB_ID.WidgetAward)
        end
    end)
end

function UIWidgetSwordMemoriesVersionBtnView:RegEvent()
    Event.Reg(self, EventType.UpdateMainStoryReward, function()
        self:UpdateRewardState()
    end)
end

function UIWidgetSwordMemoriesVersionBtnView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetSwordMemoriesVersionBtnView:UpdateInfo()
    local szImagePath = SwordMemoriesVersionBg[self.nSeasonID]
    UIHelper.SetSpriteFrame(self.ImgCard, szImagePath)

    local szImageFinishedPath = SwordMemoriesVersionFinishedBg[self.nSeasonID]
    UIHelper.SetSpriteFrame(self.ImgCardFinished, szImageFinishedPath)

    local szTitle = SwordMemoriesData.GetSeasonName(self.nSeasonID)
    UIHelper.SetString(self.LabelTitle, szTitle)

    UIHelper.SetSwallowTouches(self.BtnReward, true)

    local nCount, nTotal = SwordMemoriesData.GetSeasonProgress(self.nSeasonID)
    UIHelper.SetVisible(self.ImgCard, nCount ~= nTotal)
    UIHelper.SetVisible(self.ImgCardFinished, nCount == nTotal)
    UIHelper.SetString(self.LabelProgressNum, tostring(nCount) .. "/" .. tostring(nTotal))

    local bHasReward = SwordMemoriesData.HasRewardList(self.nSeasonID)
    UIHelper.SetVisible(self.WidgetComingSoon, not bHasReward)
    UIHelper.SetVisible(self.WidgetOngoing, bHasReward)
    UIHelper.SetTouchEnabled(self.BtnReward, bHasReward)

    self:UpdateRewardState()
end

function UIWidgetSwordMemoriesVersionBtnView:UpdateRewardState()
    UIHelper.SetVisible(self.ImgAvailable, SwordMemoriesData.CanGetReward(self.nSeasonID))
    UIHelper.SetVisible(self.ImgGotten, SwordMemoriesData.HasGetReward(self.nSeasonID) and SwordMemoriesData.IsSeasonFinished(self.nSeasonID))
end


return UIWidgetSwordMemoriesVersionBtnView