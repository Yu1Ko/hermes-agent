-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIQuestToggleView
-- Date: 2022-11-14 19:34:25
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIQuestToggleView = class("UIQuestToggleView")

function UIQuestToggleView:OnEnter(tbQuestInfo, tbChooseInfo)
    self.tbQuestInfo = tbQuestInfo
    self.bSelected = tbChooseInfo == tbQuestInfo
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIQuestToggleView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIQuestToggleView:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleTask, EventType.OnClick, function()
        -- if not bSelected then return end
        Event.Dispatch(EventType.OnChooseQuestEvent, self.tbQuestInfo)
    end)

    UIHelper.BindUIEvent(self.BtnRewardPlus, EventType.OnClick, function()
        local szText = QuestData.GetDoubleExpQuestTip(self.tbQuestInfo.nID)
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self._rootNode, TipsLayoutDir.RIGHT_CENTER, szText)
    end)
end

function UIQuestToggleView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, EventType.OnQuestTracingTargetChanged, function(nQuestID)
        self:UpdateTraceInfo()
    end)
end

function UIQuestToggleView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end





-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIQuestToggleView:UpdateInfo()
    UIHelper.SetSelected(self.ToggleTask, self.bSelected)
    local szQuestName = self.tbQuestInfo.szName
    UIHelper.SetString(self.NormalLabel01,  UIHelper.GBKToUTF8(szQuestName))
    UIHelper.SetString(self.UpLabel01,  UIHelper.GBKToUTF8(szQuestName))

    local nDistance = QuestData.GetQuestDistance(self.tbQuestInfo.nID)
    UIHelper.SetVisible(self.Label02, nDistance ~= nil)
    UIHelper.SetVisible(self.Label02_Up, nDistance ~= nil)
    UIHelper.SetVisible(self.ImgTransfer, not nDistance)
    UIHelper.SetVisible(self.ImgTransfer_Up, not nDistance)

    UIHelper.SetString(self.Label02, tostring(nDistance)..g_tStrings.STR_METER)
    UIHelper.SetString(self.Label02_Up, tostring(nDistance)..g_tStrings.STR_METER)

    local nMapId, tbPoints = QuestData.GetQuestMapIDAndPoints(self.tbQuestInfo.nID)
    local szMapName = nMapId and Table_GetMapName(nMapId) or UIHelper.UTF8ToGBK("暂无指引")
    UIHelper.SetString(self.Label03, UIHelper.GBKToUTF8(szMapName))
    UIHelper.SetString(self.Label03_Up, UIHelper.GBKToUTF8(szMapName))

    if not nMapId then
        UIHelper.SetSpriteFrame(self.ImgTransfer, "UIAtlas2_Public_PublicIcon_PublicIcon1_img_NoGuideTask")
        UIHelper.SetSpriteFrame(self.ImgTransfer_Up, "UIAtlas2_Public_PublicIcon_PublicIcon1_img_NoGuideTask")

    end

    local nQuestType = QuestData.GetQuestNewType(self.tbQuestInfo.nID)
    local tbSprintFrame
    if nQuestType == QuestType.Branch then
        local tbQuestInfo = QuestData.GetQuestInfo(self.tbQuestInfo.nID)
        local nLevel = tbQuestInfo and tbQuestInfo.nLevel or 1
        if nLevel < 5 then
            tbSprintFrame = QuestTypeImg[nQuestType][1]
        elseif nLevel >= 5 and nLevel <= 10 then
            tbSprintFrame = QuestTypeImg[nQuestType][2]
        else
            tbSprintFrame = QuestTypeImg[nQuestType][3]
        end
    else
        tbSprintFrame = QuestTypeImg[nQuestType]
    end

    if tbSprintFrame then
        local szSprintFrame = QuestData.IsFinished(self.tbQuestInfo.nID) and tbSprintFrame[2] or tbSprintFrame[1]
        UIHelper.SetSpriteFrame(self.Img_Icon, szSprintFrame)
        UIHelper.SetSpriteFrame(self.Img_Icon_Up, szSprintFrame)
    end

    local szTime = QuestData.GetQuestTime(self.tbQuestInfo.nID)
    UIHelper.SetVisible(self.ImgTimeLimited, not string.is_nil(szTime))

    local bFailed = QuestData.IsFailed(self.tbQuestInfo.nID)
    local bCompleted = QuestData.IsDone(self.tbQuestInfo.nID) and not bFailed
    UIHelper.SetVisible(self.WidgetDone, bCompleted)

    UIHelper.SetVisible(self.WidgetFailed, bFailed)

    UIHelper.SetVisible(self.BtnRewardPlus, QuestData.IsDoubleExpQuest(self.tbQuestInfo.nID))

    self:UpdateTraceInfo()
end

function UIQuestToggleView:UpdateTraceInfo()
    local bTrace = QuestData.IsTracingQuestID(self.tbQuestInfo.nID)
    UIHelper.SetVisible(self.Eff_UITaskTracking, bTrace)
end

function UIQuestToggleView:IsSelected()
    return self.bSelected
end


return UIQuestToggleView