-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPlotDialogueOldQuest
-- Date: 2022-11-23 20:53:39
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPlotDialogueOldQuest = class("UIPlotDialogueOldQuest")

function UIPlotDialogueOldQuest:OnEnter(dwQuestID, tbDialogueData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if dwQuestID and tbDialogueData then
        self:Init(dwQuestID, tbDialogueData)
        self:UpdateInfo()
    end
end

function UIPlotDialogueOldQuest:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPlotDialogueOldQuest:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnOperation, EventType.OnClick, function()
        if self.dwQuestID  and self.tbDialogueData then
            if QuestData.CanAcceptQuest(self.dwQuestID, self.tbDialogueData.dwTargetType, self.tbDialogueData.dwTargetID) then
                QuestData.AcceptQuest(self.tbDialogueData.dwTargetType, self.tbDialogueData.dwTargetID, self.dwQuestID)
            else
                if self:HasAward() then
                    TipsHelper.ShowNormalTip(g_tStrings.STR_MSG_SELECT_HOR)
                    return 
                end
                local nSelect1, nSelect2 = 0, 4
                if self.tbAwardInfoList then
                    nSelect1, nSelect2 = self.tbAwardInfoList[1] or 0, self.tbAwardInfoList[2] or 4
                end
                QuestData.TryFinishQuest(self.dwQuestID, self.tbDialogueData.dwTargetType, self.tbDialogueData.dwTargetID, nSelect1, nSelect2)
            end
        end
    end)
end

function UIPlotDialogueOldQuest:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, EventType.OnWindowsSizeChanged, function ()
        self.nScrollViewDetailHeight = UIHelper.GetHeight(self.ScrollViewDetail)
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnSelectAward, function(nTabType, nTabID , nCount, scriptView, tbAward)
        if tbAward.bCanSelect and QuestData.CanFinishQuest(self.dwQuestID, self.tbDialogueData.dwTargetType, self.tbDialogueData.dwTargetID) then
            if not self.tbAwardInfoList then self.tbAwardInfoList = {} end
            self.tbAwardInfoList[tbAward.selectgroup] = tbAward.selectindex
            Event.Dispatch(EventType.SelectAwardSuccess, self.tbAwardInfoList)
        end
    end)
end

function UIPlotDialogueOldQuest:HasAward()
    local bHave, tbAwardGorup = QuestData.HaveChooseItem(self.dwQuestID)
    if bHave then
        if not self.tbAwardInfoList then return true end
        for nIndex, value in ipairs(tbAwardGorup) do
            if not self.tbAwardInfoList[nIndex] then 
                return true
            end
        end
    end
    return false
end

function UIPlotDialogueOldQuest:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIPlotDialogueOldQuest:Init(dwQuestID, tbDialogueData)
    UIHelper.SetClickInterval(self.BtnOperation, 1)
    self.dwQuestID = dwQuestID
    self.tbDialogueData = tbDialogueData
    self.nScrollViewDetailHeight = self.nScrollViewDetailHeight or UIHelper.GetHeight(self.ScrollViewDetail)
    self.tbQuestConfig = QuestData.GetQuestConfig(dwQuestID)
end




-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

--------------------------------------------------------------------更新UI-----------------------------------------------------------


function UIPlotDialogueOldQuest:UpdateInfo()
    self:UpdateQuestMessage()
    self:UpdateQuestDesc()
    self:UpdateQuestTarget()
    self:UpdateQuestAward()
    self:UpdateLabelOperation()
    self:UpdateBtnState()

    local tbAwardList = self.tbQuestConfig and QuestData.GetCurQuestAwardList(self.tbQuestConfig.nID) or {}
    local bNotHasAward = #tbAwardList == 0
    local nWidgetRewardHeight = UIHelper.GetHeight(self.WidgetReward)

    UIHelper.SetHeight(self.ScrollViewDetail, self.nScrollViewDetailHeight + (bNotHasAward and nWidgetRewardHeight or 0))

    UIHelper.ScrollViewDoLayout(self.ScrollViewDetail)
    UIHelper.ScrollToTop(self.ScrollViewDetail, 0)


    if self.WidgetArrow and self.WidgetArrowReward then
        if bNotHasAward then
            UIHelper.ScrollViewSetupArrow(self.ScrollViewDetail, self.WidgetArrow)
        else
            UIHelper.ScrollViewSetupArrow(self.ScrollViewDetail, self.WidgetArrowReward)
        end
        UIHelper.SetVisible(self.WidgetArrow, bNotHasAward)
        UIHelper.SetVisible(self.WidgetArrowReward, not bNotHasAward)
    end
end



function UIPlotDialogueOldQuest:UpdateQuestTarget()
    local scriptView = UIHelper.GetBindScript(self.LayoutTarget)
    scriptView:OnEnter(self.tbQuestConfig, true)
end


function UIPlotDialogueOldQuest:UpdateQuestDesc()
    -- local scriptView = UIHelper.GetBindScript(self.LayoutDetail)
    -- scriptView:OnEnter(self.tbQuestConfig)
    UIHelper.SetVisible(self.LayoutDetail, false)
end


function UIPlotDialogueOldQuest:UpdateQuestAward()
    local scriptView = UIHelper.GetBindScript(self.WidgetReward)
    local tbAwardList = self.tbQuestConfig and QuestData.GetCurQuestAwardList(self.tbQuestConfig.nID, true) or {}
    scriptView:OnEnter(tbAwardList, PREFAB_ID.WidgetAwardItem1, true)
end



function UIPlotDialogueOldQuest:UpdateQuestMessage()

    local dwTargetType = self.tbDialogueData.dwTargetType
    local dwTargetID = self.tbDialogueData.dwTargetID
    local bCanAccept = QuestData.CanAcceptQuest(self.dwQuestID, dwTargetType, dwTargetID)
    local bCanFinish = QuestData.CanFinishQuest(self.dwQuestID, dwTargetType, dwTargetID)

    local szMessage = ""
    if bCanAccept then
        szMessage = ParseTextHelper.ParseQuestDesc(self.tbQuestConfig.szDescription)
    elseif bCanFinish then 
        szMessage = ParseTextHelper.ParseQuestDesc(self.tbQuestConfig.szFinishedDialogue)
    else
        szMessage = ParseTextHelper.ParseQuestDesc(self.tbQuestConfig.szUnfinishedDialogue)
    end
    UIHelper.SetRichText(self.RichTextMessage, szMessage)
    UIHelper.LayoutDoLayout(self.LayoutMessage)
end

function UIPlotDialogueOldQuest:UpdateLabelOperation()
    if QuestData.CanAcceptQuest(self.dwQuestID, self.tbDialogueData.dwTargetType, self.tbDialogueData.dwTargetID) then
        UIHelper.SetString(self.LabelOperation, g_tStrings.STR_QUEST_ACCEPT_QUEST)
    else
        UIHelper.SetString(self.LabelOperation, g_tStrings.STR_QUEST_FINSISH_QUEST)
    end
end

function UIPlotDialogueOldQuest:UpdateBtnState()
    local dwTargetType = self.tbDialogueData.dwTargetType
    local dwTargetID = self.tbDialogueData.dwTargetID
    local bCanAccept = QuestData.CanAcceptQuest(self.dwQuestID, dwTargetType, dwTargetID)
    local bCanFinish = QuestData.CanFinishQuest(self.dwQuestID, dwTargetType, dwTargetID)
    UIHelper.SetVisible(self.BtnOperation, bCanAccept or bCanFinish)
end

return UIPlotDialogueOldQuest