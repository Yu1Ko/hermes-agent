-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelSentTaskDetailsView
-- Date: 2023-10-19 14:50:04
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelSentTaskDetailsView = class("UIPanelSentTaskDetailsView")

function UIPanelSentTaskDetailsView:OnEnter(nQuestID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nQuestID = nQuestID
    self.nScrollViewHeight = UIHelper.GetHeight(self.ScrollViewContent)
    self.nWidgetAnchorRewardHeight = UIHelper.GetHeight(self.WidgetAnchorReward)
    self:UpdateInfo()
end

function UIPanelSentTaskDetailsView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelSentTaskDetailsView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCloseRight, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnStartPoint, EventType.OnClick, function()
        local nQuestID = self.nQuestID
        local nMapId, tbPoints = QuestData.GetQuestMarkPoints(nQuestID, "accept", 0)
        QuestData.OpenQuestMap(nQuestID, nMapId, tbPoints)
    end)

    UIHelper.BindUIEvent(self.BtnEndPoint, EventType.OnClick, function()
        local nQuestID = self.nQuestID
        local nMapId, tbPoints = QuestData.GetQuestMarkPoints(nQuestID, "finish", 0)
        QuestData.OpenQuestMap(nQuestID, nMapId, tbPoints)
    end)
end

function UIPanelSentTaskDetailsView:RegEvent()
    Event.Reg(self, EventType.OnWindowsSizeChanged, function ()
        self.nScrollViewHeight = UIHelper.GetHeight(self.ScrollViewContent)
        self.nWidgetAnchorRewardHeight = UIHelper.GetHeight(self.WidgetAnchorReward)
        self:DelayUpdateInfo()
    end)
end

function UIPanelSentTaskDetailsView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIPanelSentTaskDetailsView:DelayUpdateInfo()
    if self.nUpdateTimer then 
        Timer.DelTimer(self, self.nUpdateTimer)
    end
    self.nUpdateTimer = Timer.AddFrame(self, 2, function ()
        self:UpdateInfo()
        self.nUpdateTimer = nil
    end)
end




-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelSentTaskDetailsView:UpdateInfo()
    self:UpdateQuestName()
    self:UpdateQuestLocationAndState()
    self:UpdateQuestStartLevel()
    self:UpdatePreQuestName()
    self:UpdateQuestStartInfo()
    self:UpdateQuestEndInfo()
    self:UpdateFinishTime()
    self:UpdateQuestTarget()
    self:UpdateQuestAward()
    UIHelper.LayoutDoLayout(self.WidgetTarget)
    UIHelper.LayoutDoLayout(self.WidgetMain)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
    UIHelper.ScrollViewSetupArrow(self.ScrollViewContent, self.WidgetArrow)
end

function UIPanelSentTaskDetailsView:UpdateQuestName()
    local nQuestID = self.nQuestID
    local szName = QuestData.GetQuestName(nQuestID)
    UIHelper.SetString(self.LabelTaskName, szName)
end

function UIPanelSentTaskDetailsView:UpdateQuestLocationAndState()
    local nQuestID = self.nQuestID
    local tbQuestInfo = QuestData.GetQuestInfo(nQuestID)
    local szMapName = Table_GetQuestClass(tbQuestInfo.dwQuestClassID)
    UIHelper.SetString(self.LabelLocation, UIHelper.GBKToUTF8(szMapName))

    local bFinished = QuestData.IsFinished(nQuestID)
    local szState = bFinished and g_tStrings.STR_QUEST_FINISHED or g_tStrings.STR_QUEST_UNFINISHED
    UIHelper.SetString(self.LabelStateNotStarted, szState)

    UIHelper.LayoutDoLayout(self.LayoutLine01)
end

function UIPanelSentTaskDetailsView:UpdateQuestStartLevel()
    local nQuestID = self.nQuestID
    local szLevel = QuestData.GetQuestMinLevel(nQuestID)
    UIHelper.SetString(self.LabelStartLevelNum, szLevel)

    UIHelper.LayoutDoLayout(self.LayoutLine02)
end

function UIPanelSentTaskDetailsView:UpdatePreQuestName()
    local nQuestID = self.nQuestID
    local szTitle, szName = QuestData.GetPreQuestNameAndTitle(nQuestID)
    UIHelper.SetRichText(self.RichTextPresetTask, szTitle..szName)

    UIHelper.LayoutDoLayout(self.LayoutLine03)
end

function UIPanelSentTaskDetailsView:UpdateQuestStartInfo()
    local nQuestID = self.nQuestID
    local szName = QuestData.GetQuestStartNpcOrItemName(nQuestID)
    UIHelper.SetString(self.LabelStartPointName, UIHelper.GBKToUTF8(szName))
end

function UIPanelSentTaskDetailsView:UpdateQuestEndInfo()
    local nQuestID = self.nQuestID
    local szName = QuestData.GetQuestEndNpcOrItemName(nQuestID)
    UIHelper.SetString(self.LabelEndPointName, UIHelper.GBKToUTF8(szName))
end

function UIPanelSentTaskDetailsView:UpdateFinishTime()

end

function UIPanelSentTaskDetailsView:UpdateQuestTarget()
    local nQuestID = self.nQuestID
    local tbQuestStringInfo = QuestData.GetQuestConfig(nQuestID)
    UIHelper.SetRichText(self.RichTextTarget, ParseTextHelper.ParseQuestDesc(tbQuestStringInfo.szObjective))

    UIHelper.RemoveAllChildren(self.LayoutSingleTargetList)
    local tbTargetList = QuestData.GetDetailTargetList(nQuestID)
    for nIndex, tbInfo in ipairs(tbTargetList) do
        UIMgr.AddPrefab(PREFAB_ID.WidgetSentTaskTargetCell, self.LayoutSingleTargetList, tbInfo)
    end

    UIHelper.LayoutDoLayout(self.LayoutSingleTargetList)
    UIHelper.LayoutDoLayout(self.LayoutTargetContent)
end

function UIPanelSentTaskDetailsView:UpdateQuestAward()
    local nQuestID = self.nQuestID
    local tbAwardList = QuestData.GetCurQuestAwardList(nQuestID)
    local scriptView = UIHelper.GetBindScript(self.WidgetReward)
    scriptView:OnEnter(tbAwardList, PREFAB_ID.WidgetAwardItem1)

    local nHeight = (tbAwardList and #tbAwardList ~= 0) and self.nScrollViewHeight or (self.nScrollViewHeight + self.nWidgetAnchorRewardHeight + 20)
    UIHelper.SetHeight(self.ScrollViewContent, nHeight)
end


return UIPanelSentTaskDetailsView